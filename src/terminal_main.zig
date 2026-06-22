const std = @import("std");
const builtin = @import("builtin");
const zig_nes_emu = @import("zig_nes_emu");
const blip = @import("blip");
const rl = @import("raylib");
const mibu = @import("mibu");

const Color = zig_nes_emu.Color;

const sample_rate = 44100;
const chunk_frames = 1024;

const default_input_device = "/dev/input/event0";

const Button = struct {
    const a: u8 = 0x80;
    const b: u8 = 0x40;
    const select: u8 = 0x20;
    const start: u8 = 0x10;
    const up: u8 = 0x08;
    const down: u8 = 0x04;
    const left: u8 = 0x02;
    const right: u8 = 0x01;
};

const max_frame_bytes: usize = blk: {
    const rows = 240 / 2;
    const cols = 256;
    const per_cell = 19 + 19 + 3;
    const per_row = 6;
    break :blk 3 + rows * (cols * per_cell + per_row);
};

const Args = struct {
    rom_path: []const u8 = "",
    region: zig_nes_emu.Region = .ntsc,
    block_size: u32 = 4,
    mute: bool = false,
    input_device: []const u8 = default_input_device,
};

const ArgError = error{
    ShowHelp,
    MissingValue,
    BadRegion,
    BadBlockSize,
    UnknownFlag,
    NoRom,
};

fn eqlAny(arg: []const u8, options: []const []const u8) bool {
    for (options) |opt| {
        if (std.mem.eql(u8, arg, opt)) return true;
    }
    return false;
}

fn parseArgs(argv: []const [:0]const u8) ArgError!Args {
    var args = Args{};
    var i: usize = 1;
    while (i < argv.len) : (i += 1) {
        const a = argv[i];
        if (eqlAny(a, &.{ "-r", "--region" })) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            args.region = std.meta.stringToEnum(zig_nes_emu.Region, argv[i]) orelse return error.BadRegion;
        } else if (eqlAny(a, &.{ "-b", "--block-size", "--block_size" })) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            args.block_size = std.fmt.parseInt(u32, argv[i], 10) catch return error.BadBlockSize;
            if (args.block_size == 0) return error.BadBlockSize;
        } else if (eqlAny(a, &.{ "-i", "--input" })) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            args.input_device = argv[i];
        } else if (eqlAny(a, &.{ "-m", "--mute" })) {
            args.mute = true;
        } else if (eqlAny(a, &.{ "-h", "--help" })) {
            return error.ShowHelp;
        } else if (a.len > 0 and a[0] == '-') {
            return error.UnknownFlag;
        } else {
            args.rom_path = a;
        }
    }
    if (args.rom_path.len == 0) return error.NoRom;
    return args;
}

fn printUsage() void {
    const usage =
        \\
        \\USAGE:
        \\    terminal_nes_emu [OPTIONS] <ROM>
        \\
        \\ARGS:
        \\    <ROM>    Path to an iNES (.nes) ROM file
        \\
        \\OPTIONS:
        \\    -r, --region <ntsc|pal>    Console region             [default: ntsc]
        \\    -b, --block-size <N>       Integer pixel block size   [default: 4]
        \\    -i, --input <PATH>         Linux evdev input device   [default: /dev/input/event0]
        \\    -m, --mute                 Disable audio
        \\    -h, --help                 Print this help and exit
        \\
        \\CONTROLS:
        \\    D-pad  Arrow keys      A  X      B  Z
        \\    Select Shift           Start  Enter      Quit  Esc
        \\
        \\EXAMPLES:
        \\    terminal_nes_emu zelda.nes
        \\    terminal_nes_emu -r pal -b 3 castlevania.nes
        \\    terminal_nes_emu --mute smb.nes
        \\
        \\NOTE:
        \\    On Linux, reading keyboard state via evdev typically requires running as
        \\    root (or being in the 'input' group), and the keyboard may not be at
        \\    /dev/input/event0. Use --input to point at the correct device.
        \\
    ;
    std.debug.print("{s}", .{usage});
}

fn colorEq(a: Color, b: Color) bool {
    return a.r == b.r and a.g == b.g and a.b == b.b;
}

extern "kernel32" fn SetConsoleOutputCP(wCodePageID: c_uint) callconv(.c) c_int;
extern "user32" fn GetAsyncKeyState(vKey: c_int) callconv(.c) c_short;

fn winKeyDown(vk: c_int) bool {
    return (GetAsyncKeyState(vk) & @as(c_short, @bitCast(@as(u16, 0x8000)))) != 0;
}

const CGKeyCode = u16;
extern "ApplicationServices" fn CGEventSourceKeyState(state: c_int, key: CGKeyCode) callconv(.c) bool;
const kCGEventSourceStateHIDSystemState: c_int = 1;

fn macKeyDown(key: CGKeyCode) bool {
    return CGEventSourceKeyState(kCGEventSourceStateHIDSystemState, key);
}

const LinuxKeyboard = struct {
    fd: std.posix.fd_t,
    keys: [256]bool = @splat(false),

    const InputEvent = extern struct {
        time_sec: c_long,
        time_usec: c_long,
        type: u16,
        code: u16,
        value: i32,
    };
    const EV_KEY: u16 = 0x01;

    pub fn open(path: []const u8) !LinuxKeyboard {
        const fd = try std.posix.open(path, .{ .ACCMODE = .RDONLY, .NONBLOCK = true }, 0);
        return .{ .fd = fd };
    }

    pub fn deinit(self: *LinuxKeyboard) void {
        std.posix.close(self.fd);
    }

    pub fn update(self: *LinuxKeyboard) void {
        var ev: InputEvent = undefined;
        while (true) {
            const n = std.posix.read(self.fd, std.mem.asBytes(&ev)) catch break;
            if (n < @sizeOf(InputEvent)) break;
            if (ev.type == EV_KEY and ev.code < 256) {
                self.keys[ev.code] = ev.value != 0;
            }
        }
    }

    pub fn isDown(self: *LinuxKeyboard, code: u16) bool {
        return if (code < 256) self.keys[code] else false;
    }
};

pub fn pollController(linux_kb: *?LinuxKeyboard) u8 {
    var c: u8 = 0;
    switch (builtin.target.os.tag) {
        .windows => {
            const binds = [_]struct { vk: c_int, btn: u8 }{
                .{ .vk = 'X', .btn = Button.a },
                .{ .vk = 'Z', .btn = Button.b },
                .{ .vk = 0x10, .btn = Button.select },
                .{ .vk = 0x0D, .btn = Button.start },
                .{ .vk = 0x26, .btn = Button.up },
                .{ .vk = 0x28, .btn = Button.down },
                .{ .vk = 0x25, .btn = Button.left },
                .{ .vk = 0x27, .btn = Button.right },
            };
            for (binds) |k| if (winKeyDown(k.vk)) {
                c |= k.btn;
            };
        },
        .macos => {
            const binds = [_]struct { key: CGKeyCode, btn: u8 }{
                .{ .key = 7, .btn = Button.a },
                .{ .key = 6, .btn = Button.b },
                .{ .key = 56, .btn = Button.select },
                .{ .key = 36, .btn = Button.start },
                .{ .key = 126, .btn = Button.up },
                .{ .key = 125, .btn = Button.down },
                .{ .key = 123, .btn = Button.left },
                .{ .key = 124, .btn = Button.right },
            };
            for (binds) |k| if (macKeyDown(k.key)) {
                c |= k.btn;
            };
        },
        .linux => {
            if (linux_kb.* == null) return 0;
            const kb = &(linux_kb.*.?);
            kb.update();
            const binds = [_]struct { code: u16, btn: u8 }{
                .{ .code = 45, .btn = Button.a },
                .{ .code = 44, .btn = Button.b },
                .{ .code = 42, .btn = Button.select },
                .{ .code = 28, .btn = Button.start },
                .{ .code = 103, .btn = Button.up },
                .{ .code = 108, .btn = Button.down },
                .{ .code = 105, .btn = Button.left },
                .{ .code = 106, .btn = Button.right },
            };
            for (binds) |k| if (kb.isDown(k.code)) {
                c |= k.btn;
            };
        },
        else => {},
    }
    return c;
}

extern "kernel32" fn FlushConsoleInputBuffer(hConsoleInput: std.os.windows.HANDLE) callconv(.c) c_int;
extern "winmm" fn timeBeginPeriod(uPeriod: c_uint) callconv(.c) c_uint;
extern "winmm" fn timeEndPeriod(uPeriod: c_uint) callconv(.c) c_uint;

const TerminalWriter = struct {
    stdout_file: std.Io.File,
    stdout_writer: std.Io.File.Writer,
    stdin: std.Io.File,
    raw_term: mibu.term.RawTerm,
    io: std.Io,

    pub fn init(io: std.Io, buffer: []u8) !@This() {
        const stdin = std.Io.File.stdin();
        const stdout_file = std.Io.File.stdout();
        if (!try stdin.isTty(io)) return error.InvalidStdout;
        if (builtin.target.os.tag == .windows) {
            try mibu.enableWindowsVTS(stdout_file.handle);
            _ = SetConsoleOutputCP(65001);
        }
        const raw_term = try mibu.term.enableRawMode(stdin.handle);
        var w = @This(){
            .stdout_file = stdout_file,
            .stdout_writer = stdout_file.writer(io, buffer),
            .stdin = stdin,
            .raw_term = raw_term,
            .io = io,
        };
        var out = w.writer();
        try out.writeAll("\x1b[?1049h");
        try out.writeAll("\x1b[?7l");
        try mibu.cursor.hide(out);
        try mibu.clear.all(out);
        try out.flush();
        return w;
    }

    fn writer(self: *@This()) *std.Io.Writer {
        return &self.stdout_writer.interface;
    }

    pub fn deinit(self: *@This()) void {
        self.raw_term.disableRawMode() catch {};
        var out = self.writer();
        out.writeAll("\x1b[?1049l") catch {};
        out.writeAll("\x1b[?7h") catch {};
        mibu.cursor.show(out) catch {};
        out.flush() catch {};
        self.drainInput();
    }

    pub fn getEvent(self: *@This()) !mibu.events.Event {
        return try mibu.events.nextWithTimeout(self.io, self.stdin, 0);
    }

    fn drainInput(self: *@This()) void {
        switch (builtin.target.os.tag) {
            .windows => _ = FlushConsoleInputBuffer(self.stdin.handle),
            else => while ((self.getEvent() catch return) != .timeout) {},
        }
    }

    fn averageBlock(framebuffer: *const [256 * 240]Color, x0: usize, y0: usize, block_size: usize) Color {
        const width = 256;
        const height = 240;
        var r: u32 = 0;
        var g: u32 = 0;
        var b: u32 = 0;
        var count: u32 = 0;
        var dy: usize = 0;
        while (dy < block_size) : (dy += 1) {
            const y = y0 + dy;
            if (y >= height) break;
            var dx: usize = 0;
            while (dx < block_size) : (dx += 1) {
                const x = x0 + dx;
                if (x >= width) break;
                const px = framebuffer[y * width + x];
                r += px.r;
                g += px.g;
                b += px.b;
                count += 1;
            }
        }
        if (count == 0) return Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
        return Color{
            .r = @intCast(r / count),
            .g = @intCast(g / count),
            .b = @intCast(b / count),
            .a = 255,
        };
    }

    fn putByte(buf: []u8, i: *usize, b: u8) void {
        buf[i.*] = b;
        i.* += 1;
    }

    fn putU8(buf: []u8, i: *usize, v: u8) void {
        if (v >= 100) {
            putByte(buf, i, '0' + v / 100);
            putByte(buf, i, '0' + v / 10 % 10);
            putByte(buf, i, '0' + v % 10);
        } else if (v >= 10) {
            putByte(buf, i, '0' + v / 10);
            putByte(buf, i, '0' + v % 10);
        } else {
            putByte(buf, i, '0' + v);
        }
    }

    fn putStr(buf: []u8, i: *usize, s: []const u8) void {
        @memcpy(buf[i.*..][0..s.len], s);
        i.* += s.len;
    }

    pub fn writeFrame(self: *@This(), scratch: []u8, framebuffer: *const [256 * 240]Color, block_size: u32) !void {
        const bs: usize = @max(1, block_size);
        const row_stride = bs * 2;
        var i: usize = 0;

        putStr(scratch, &i, "\x1b[H");

        var y: usize = 0;
        while (y + row_stride <= 240) : (y += row_stride) {
            var last_top: ?Color = null;
            var last_bot: ?Color = null;
            var x: usize = 0;
            while (x + bs <= 256) : (x += bs) {
                const top = averageBlock(framebuffer, x, y, bs);
                const bot = averageBlock(framebuffer, x, y + bs, bs);

                if (last_top == null or !colorEq(top, last_top.?)) {
                    putStr(scratch, &i, "\x1b[38;2;");
                    putU8(scratch, &i, top.r);
                    putByte(scratch, &i, ';');
                    putU8(scratch, &i, top.g);
                    putByte(scratch, &i, ';');
                    putU8(scratch, &i, top.b);
                    putByte(scratch, &i, 'm');
                    last_top = top;
                }
                if (last_bot == null or !colorEq(bot, last_bot.?)) {
                    putStr(scratch, &i, "\x1b[48;2;");
                    putU8(scratch, &i, bot.r);
                    putByte(scratch, &i, ';');
                    putU8(scratch, &i, bot.g);
                    putByte(scratch, &i, ';');
                    putU8(scratch, &i, bot.b);
                    putByte(scratch, &i, 'm');
                    last_bot = bot;
                }
                putStr(scratch, &i, "\xe2\x96\x80");
            }
            putStr(scratch, &i, "\x1b[0m\r\n");
        }

        std.debug.assert(i <= scratch.len);

        const out = self.writer();
        try out.writeAll(scratch[0..i]);
        try out.flush();
    }
};

fn shouldQuit(tw: *TerminalWriter) !bool {
    if (builtin.target.os.tag == .windows) {
        return winKeyDown(0x1B);
    }
    const ev = try tw.getEvent();
    if (ev == .key and ev.key.code == .esc) return true;
    if (ev == .key) switch (ev.key.code) {
        .char => |ch| if (ev.key.mods.ctrl and ch == 'c') return true,
        else => {},
    };
    return false;
}

pub fn main(init: std.process.Init) !void {
    const argv = try init.minimal.args.toSlice(init.arena.allocator());
    const args = parseArgs(argv) catch |err| {
        if (err == error.ShowHelp) {
            printUsage();
            return;
        }
        switch (err) {
            error.MissingValue => std.log.err("missing value for an argument", .{}),
            error.BadRegion => std.log.err("invalid region (expected 'ntsc' or 'pal')", .{}),
            error.BadBlockSize => std.log.err("block size must be a positive integer", .{}),
            error.UnknownFlag => std.log.err("unknown flag", .{}),
            error.NoRom => std.log.err("no ROM file provided", .{}),
            else => std.log.err("failed to parse arguments: {s}", .{@errorName(err)}),
        }
        printUsage();
        std.process.exit(2);
    };

    rl.setTraceLogLevel(.warning);

    const term_buf = try init.gpa.alloc(u8, 64 * 1024);
    defer init.gpa.free(term_buf);
    const scratch = try init.gpa.alloc(u8, max_frame_bytes);
    defer init.gpa.free(scratch);

    var terminal_writer = try TerminalWriter.init(init.io, term_buf);
    defer terminal_writer.deinit();

    if (builtin.target.os.tag == .windows) _ = timeBeginPeriod(1);
    defer if (builtin.target.os.tag == .windows) {
        _ = timeEndPeriod(1);
    };

    var cart = try zig_nes_emu.Cartridge.initAlloc(init.gpa, init.io, args.rom_path);
    defer cart.deinit();

    var bus = zig_nes_emu.Bus.init(args.region, args.mute);
    bus.cpu.connectBus(&bus);
    bus.loadCartridge(&cart);
    bus.reset();
    bus.initAudio(sample_rate);
    defer bus.deinitAudio();

    const fps: u16 = switch (args.region) {
        .ntsc => 60,
        .pal => 50,
    };
    const frame_ns: u64 = @intFromFloat(@as(f64, std.time.ns_per_s) / @as(f64, @floatFromInt(fps)));

    var stream: ?rl.AudioStream = null;
    var audio_active = false;
    if (!args.mute) {
        rl.initAudioDevice();
        if (!rl.isAudioDeviceReady()) {
            std.log.warn("no audio device available; running without sound", .{});
            rl.closeAudioDevice();
        } else {
            rl.setAudioStreamBufferSizeDefault(chunk_frames);
            if (rl.loadAudioStream(sample_rate, 16, 1)) |s| {
                stream = s;
                rl.playAudioStream(s);
                audio_active = true;
            } else |err| {
                std.log.warn("failed to load audio stream ({s}); running without sound", .{@errorName(err)});
                rl.closeAudioDevice();
            }
        }
    }
    defer if (audio_active) {
        rl.unloadAudioStream(stream.?);
        rl.closeAudioDevice();
    };

    var linux_kb: ?LinuxKeyboard = null;
    if (builtin.target.os.tag == .linux) {
        linux_kb = LinuxKeyboard.open(args.input_device) catch |err| blk: {
            std.log.warn("could not open input device '{s}': {s} (keyboard input disabled)", .{ args.input_device, @errorName(err) });
            break :blk null;
        };
    }
    defer if (builtin.target.os.tag == .linux) {
        if (linux_kb) |*kb| kb.deinit();
    };

    main_loop: while (true) {
        const frame_start = std.Io.Clock.awake.now(init.io);

        bus.controller[0] = pollController(&linux_kb);
        if (try shouldQuit(&terminal_writer)) break :main_loop;

        while (!bus.ppu.frame_complete) bus.clock();
        bus.ppu.frame_complete = false;
        bus.endAudioFrame();

        if (audio_active) {
            while (blip.blip_samples_avail(bus.blip_buf) >= chunk_frames and rl.isAudioStreamProcessed(stream.?)) {
                var chunk: [chunk_frames]i16 = undefined;
                const n = blip.blip_read_samples(bus.blip_buf, &chunk, chunk_frames, 0);
                rl.updateAudioStream(stream.?, &chunk, n);
            }
        }

        try terminal_writer.writeFrame(scratch, &bus.ppu.framebuffer, args.block_size);

        const elapsed = frame_start.untilNow(init.io, .awake);
        if (elapsed.nanoseconds < frame_ns) {
            try init.io.sleep(.fromNanoseconds(frame_ns - @as(u64, @intCast(elapsed.nanoseconds))), .awake);
        }
    }
}

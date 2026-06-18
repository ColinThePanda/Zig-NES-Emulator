const std = @import("std");
const zig_nes_emu = @import("zig_nes_emu");
const blip = @import("blip");
const rl = @import("raylib");

const sample_rate = 44100;
const chunk_frames = 1024;

const Args = struct {
    rom_path: []const u8 = "",
    region: zig_nes_emu.Region = .ntsc,
    scale: u32 = 4,
    mute: bool = false,
};

fn parseArgs(argv: []const [:0]const u8) !Args {
    var args = Args{};
    var i: usize = 1; // skip exe name
    while (i < argv.len) : (i += 1) {
        const a = argv[i];
        if (std.mem.eql(u8, a, "-r") or std.mem.eql(u8, a, "--region")) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            args.region = std.meta.stringToEnum(zig_nes_emu.Region, argv[i]) orelse return error.BadRegion;
        } else if (std.mem.eql(u8, a, "-s") or std.mem.eql(u8, a, "--scale")) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            args.scale = try std.fmt.parseInt(u32, argv[i], 10);
        } else if (std.mem.eql(u8, a, "-m") or std.mem.eql(u8, a, "--mute")) {
            args.mute = true;
        } else if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            return error.ShowHelp;
        } else if (a.len > 0 and a[0] == '-') {
            return error.UnknownFlag;
        } else {
            args.rom_path = a; // positional = ROM
        }
    }
    if (args.rom_path.len == 0) return error.NoRom;
    return args;
}

fn printUsage() void {
    const usage =
        \\
        \\USAGE:
        \\    window_nes_emu [OPTIONS] <ROM>
        \\
        \\ARGS:
        \\    <ROM>    Path to an iNES (.nes) ROM file
        \\
        \\OPTIONS:
        \\    -r, --region <ntsc|pal>    Console region          [default: ntsc]
        \\    -s, --scale <N>            Integer window scale     [default: 4]
        \\    -m, --mute                 Disable audio
        \\    -h, --help                 Print this help and exit
        \\
        \\EXAMPLES:
        \\    window_nes_emu zelda.nes
        \\    window_nes_emu -r pal -s 3 castlevania.nes
        \\    window_nes_emu --mute smb.nes
        \\
    ;
    std.debug.print("{s}", .{usage});
}

pub fn main(init: std.process.Init) !void {
    const argv = try init.minimal.args.toSlice(init.arena.allocator());
    const args = parseArgs(argv) catch |err| {
        switch (err) {
            error.ShowHelp => {},
            error.MissingValue => std.log.err("Missing value for an argument", .{}),
            error.BadRegion => std.log.err("Invalid region", .{}),
            error.UnknownFlag => std.log.err("Invalid flag", .{}),
            error.NoRom => std.log.err("Must provide a rom", .{}),
            else => unreachable,
        }
        printUsage();
        return;
    };

    var cart = try zig_nes_emu.Cartridge.init(init.gpa, init.io, args.rom_path);
    defer cart.deinit();

    var bus = zig_nes_emu.Bus.init(args.region, args.mute);
    bus.cpu.connectBus(&bus);
    bus.loadCartridge(&cart);
    bus.reset();
    bus.initAudio(sample_rate);
    defer bus.deinitAudio();

    rl.initWindow(@as(i32, @intCast(256 * args.scale)), @as(i32, @intCast(240 * args.scale)), "zig NES emulator");
    defer rl.closeWindow();
    rl.setTargetFPS(switch (args.region) {
        .ntsc => 60,
        .pal => 50,
    });

    var stream: ?rl.AudioStream = null;
    if (!args.mute) {
        rl.initAudioDevice();
        rl.setAudioStreamBufferSizeDefault(chunk_frames);
        stream = try rl.loadAudioStream(sample_rate, 16, 1);
        rl.playAudioStream(stream.?);
    }
    defer if (!args.mute) {
        rl.unloadAudioStream(stream.?);
        rl.closeAudioDevice();
    };

    // Create a 256x240 RGBA texture to stream the PPU framebuffer into each frame.
    // (Previously this came from bus.ppu.sprite_screen, which now lives outside the core.)
    const blank = rl.genImageColor(256, 240, rl.Color.black);
    const screen_texture = try rl.loadTextureFromImage(blank);
    rl.unloadImage(blank);
    defer rl.unloadTexture(screen_texture);

    while (!rl.windowShouldClose()) {
        bus.controller[0] = 0x00;
        if (rl.isKeyDown(.x)) bus.controller[0] |= 0x80; // A
        if (rl.isKeyDown(.z)) bus.controller[0] |= 0x40; // B
        if (rl.isKeyDown(.left_shift) or rl.isKeyDown(.right_shift)) bus.controller[0] |= 0x20; // Select
        if (rl.isKeyDown(.enter)) bus.controller[0] |= 0x10; // Start
        if (rl.isKeyDown(.up)) bus.controller[0] |= 0x08; // Up
        if (rl.isKeyDown(.down)) bus.controller[0] |= 0x04; // Down
        if (rl.isKeyDown(.left)) bus.controller[0] |= 0x02; // Left
        if (rl.isKeyDown(.right)) bus.controller[0] |= 0x01; // Right

        while (!bus.ppu.frame_complete) bus.clock();
        bus.ppu.frame_complete = false;
        bus.endAudioFrame();

        if (!args.mute) {
            while (blip.blip_samples_avail(bus.blip_buf) >= chunk_frames and rl.isAudioStreamProcessed(stream.?)) {
                var chunk: [chunk_frames]i16 = undefined;
                const n = blip.blip_read_samples(bus.blip_buf, &chunk, chunk_frames, 0);
                rl.updateAudioStream(stream.?, &chunk, n);
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        rl.updateTexture(screen_texture, &bus.ppu.framebuffer);
        rl.drawTextureEx(screen_texture, .{ .x = 0, .y = 0 }, 0.0, @as(f32, @floatFromInt(args.scale)), rl.Color.white);
    }
}

const std = @import("std");
const zig_nes_emu = @import("zig_nes_emu");
const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    var cart = try zig_nes_emu.Cartridge.init(init.gpa, init.io, "super-mario-bros.nes");
    defer cart.deinit();

    var bus = zig_nes_emu.Bus.init();
    bus.cpu.connectBus(&bus);
    bus.loadCartridge(&cart);
    bus.reset();

    const scale = 4;

    rl.initWindow(256 * scale, 240 * scale, "zig NES emulator");
    defer rl.closeWindow();

    const screen_texture = try rl.loadTextureFromImage(bus.ppu.sprite_screen);
    defer rl.unloadTexture(screen_texture);

    const target_ns: i128 = @intFromFloat(1e9 / 60.0988);
    var frame_start = std.Io.Clock.awake.now(init.io);
    while (!rl.windowShouldClose()) {
        bus.controller[0] = 0x00;
        if (rl.isKeyDown(.x)) bus.controller[0] |= 0x80; // A
        if (rl.isKeyDown(.z)) bus.controller[0] |= 0x40; // B
        if (rl.isKeyDown(.left_shift) or rl.isKeyDown(.right_shift)) bus.controller[0] |= 0x20; // Select
        if (rl.isKeyDown(.enter)) bus.controller[0] |= 0x10; // Start
        if (rl.isKeyDown(.up)) bus.controller[0] |= 0x08;
        if (rl.isKeyDown(.down)) bus.controller[0] |= 0x04;
        if (rl.isKeyDown(.left)) bus.controller[0] |= 0x02;
        if (rl.isKeyDown(.right)) bus.controller[0] |= 0x01;

        while (!bus.ppu.frame_complete) bus.clock();
        bus.ppu.frame_complete = false;

        rl.updateTexture(screen_texture, bus.ppu.sprite_screen.data);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        rl.drawTextureEx(screen_texture, .{ .x = 0, .y = 0 }, 0.0, scale, rl.Color.white);
        rl.drawFPS(10, 10);

        while (frame_start.untilNow(init.io, .awake).toNanoseconds() < target_ns) {
            // busy wait
        }
        frame_start = std.Io.Clock.awake.now(init.io);
    }
}

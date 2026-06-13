const std = @import("std");
const zig_nes_emu = @import("zig_nes_emu");
const blip = @import("blip");
const rl = @import("raylib");

const sample_rate = 44100;
const chunk_frames = 1024;

pub fn main(init: std.process.Init) !void {
    var cart = try zig_nes_emu.Cartridge.init(init.gpa, init.io, "legend-of-zelda.nes");
    defer cart.deinit();

    var bus = zig_nes_emu.Bus.init();
    bus.cpu.connectBus(&bus);
    bus.loadCartridge(&cart);
    bus.reset();
    bus.initAudio(sample_rate);
    defer bus.deinitAudio();

    const scale = 4;

    rl.initWindow(256 * scale, 240 * scale, "zig NES emulator");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    rl.initAudioDevice();
    defer rl.closeAudioDevice();
    rl.setAudioStreamBufferSizeDefault(chunk_frames);
    const stream = try rl.loadAudioStream(sample_rate, 16, 1);
    defer rl.unloadAudioStream(stream);
    rl.playAudioStream(stream);

    const screen_texture = try rl.loadTextureFromImage(bus.ppu.sprite_screen);
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

        while (blip.blip_samples_avail(bus.blip_buf) >= chunk_frames and rl.isAudioStreamProcessed(stream)) {
            var chunk: [chunk_frames]i16 = undefined;
            _ = blip.blip_read_samples(bus.blip_buf, &chunk, chunk_frames, 0);
            rl.updateAudioStream(stream, &chunk, chunk_frames);
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        rl.updateTexture(screen_texture, &bus.ppu.framebuffer);
        rl.drawTextureEx(screen_texture, .{ .x = 0, .y = 0 }, 0.0, scale, rl.Color.white);
        rl.drawFPS(10, 10);
    }
}

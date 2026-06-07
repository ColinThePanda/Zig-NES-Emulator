const std = @import("std");
const zig_nes_emu = @import("zig_nes_emu");

pub fn main(init: std.process.Init) !void {
    var bus = zig_nes_emu.Bus.init();
    bus.cpu.connectBus(&bus);

    var cart = try zig_nes_emu.Cartridge.init(init.gpa, init.io, "nestest.nes");
    defer cart.deinit();
    bus.loadCartridge(&cart);
    bus.reset();

    for (0..1000) |_| {
        bus.clock();
    }

    std.debug.print("Result: 0x{X:0>2}\n", .{bus.cpuRam[0x0002]});
    std.debug.print("Error code: 0x{X:0>2}\n", .{bus.cpuRam[0x0003]});
    std.debug.print("PC: 0x{X:0>4}\n", .{bus.cpu.pc});
    std.debug.print("Clocks: {}\n", .{bus.cpu.clock_count});
}

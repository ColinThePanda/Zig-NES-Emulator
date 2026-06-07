const std = @import("std");
const Cartridge = @import("cartridge.zig").Cartridge;

pub const olc2C02 = struct {
    cartridge: *Cartridge = undefined,
    nameTable: [2][1024]u8 = @splat(@as([1024]u8, @splat(0))),
    paletteTable: [32]u8 = @splat(0),
    patternTable: [2][4096]u8 = @splat(@as([4096]u8, @splat(0))),

    pub fn init() @This() {
        return @This(){};
    }

    pub fn cpuRead(self: *@This(), addr: u16, read_only: bool) u8 {
        _ = self;
        _ = addr;
        _ = read_only;
        return 0;
    }

    pub fn cpuWrite(self: *@This(), addr: u16, data: u8) void {
        _ = self;
        _ = addr;
        _ = data;
    }

    pub fn ppuRead(self: *@This(), addr: u16, read_only: bool) u8 {
        _ = read_only;
        var data: u8 = 0;
        if (self.cartridge.ppuRead(addr, &data)) {}
        return 0;
    }

    pub fn ppuWrite(self: *@This(), addr: u16, data: u8) void {
        if (self.cartridge.ppuWrite(addr, data)) {}
    }

    pub fn connectCartridge(self: *@This(), cartridge: *Cartridge) void {
        self.cartridge = cartridge;
    }

    pub fn clock(self: *@This()) void {
        _ = self;
    }
};

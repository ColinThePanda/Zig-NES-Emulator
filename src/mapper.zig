const std = @import("std");

pub const Mapper = union(enum) {
    mapper000: Mapper000,

    pub fn init(mapper_id: u8, program_banks: u8, char_banks: u8) !@This() {
        return switch (mapper_id) {
            0 => .{ .mapper000 = .init(program_banks, char_banks) },
            else => error.UnsupportedMapper,
        };
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        return switch (self.*) {
            .mapper000 => |*m| m.cpuMapRead(addr, mapped_addr),
        };
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        return switch (self.*) {
            .mapper000 => |*m| m.cpuMapWrite(addr, mapped_addr),
        };
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        return switch (self.*) {
            .mapper000 => |*m| m.ppuMapRead(addr, mapped_addr),
        };
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        return switch (self.*) {
            .mapper000 => |*m| m.ppuMapWrite(addr, mapped_addr),
        };
    }
};

pub const Mapper000 = struct {
    program_banks: u8,
    char_banks: u8,

    pub fn init(program_banks: u8, char_banks: u8) @This() {
        return .{
            .program_banks = program_banks,
            .char_banks = char_banks,
        };
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr >= 0x8000 and addr <= 0xFFFF) {
            mapped_addr.* = addr & if (self.program_banks > 1) @as(u16, 0x7FFF) else @as(u16, 0x3FFF);
            return true;
        }

        return false;
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr >= 0x8000 and addr <= 0xFFFF) {
            mapped_addr.* = addr & if (self.program_banks > 1) @as(u16, 0x7FFF) else @as(u16, 0x3FFF);
            return true;
        }

        return false;
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        _ = self;

        if (addr >= 0x0000 and addr <= 0x1FFF) {
            mapped_addr.* = addr;
            return true;
        }

        return false;
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        _ = self;

        if (addr >= 0x0000 and addr <= 0x1FFF) {
            mapped_addr.* = addr;
            return true;
        }

        return false;
    }
};

const std = @import("std");
const Mapper = @import("mapper.zig").Mapper;

const inesHeader = extern struct { // extern so fields are placed in memory in this exact order
    name: [4]u8,
    program_rom_chunks: u8,
    char_rom_chunks: u8,
    mapper1: u8,
    mapper2: u8,
    program_ram_size: u8,
    tv_system1: u8,
    tv_system2: u8,
    unused: [5]u8,
};

pub const Mirror = enum { horizontal, vertical, onescreen_lo, onescreen_hi };

pub const Cartridge = struct {
    allocator: std.mem.Allocator,

    image_valid: bool = true,
    mapper_id: u8 = 0,
    program_banks: u8 = 0,
    char_banks: u8 = 0,

    program_memory: []u8,
    char_memory: []u8,

    mapper: Mapper,

    mirror: Mirror = .horizontal,

    pub fn initAlloc(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !@This() {
        const file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);

        var buf: [4096]u8 = undefined;
        var reader = file.reader(io, &buf);

        var header: inesHeader = undefined;
        _ = try reader.interface.readSliceAll(std.mem.asBytes(&header));

        if (header.mapper1 & 0x04 != 0) {
            var trainer_buf: [512]u8 = undefined;
            _ = try reader.interface.readSliceAll(&trainer_buf);
        }

        const mapper_id = ((header.mapper2 >> 4) << 4) | (header.mapper1 >> 4);
        const filetype: u8 = 1;

        var cartridge = @This(){
            .allocator = allocator,
            .mapper_id = mapper_id,
            .program_memory = undefined,
            .char_memory = undefined,
            .mapper = undefined,
            .mirror = if (header.mapper1 & 0x01 != 0) .vertical else .horizontal,
        };

        switch (filetype) {
            0 => {},
            1 => {
                const program_banks = header.program_rom_chunks;
                const char_banks = header.char_rom_chunks;
                const program_memory = try allocator.alloc(u8, @as(usize, program_banks) * 16384);
                const char_memory = try allocator.alloc(u8, if (char_banks == 0) 8192 else @as(usize, char_banks) * 8192);
                _ = try reader.interface.readSliceAll(program_memory);
                if (char_banks > 0) _ = try reader.interface.readSliceAll(char_memory);

                cartridge.program_banks = program_banks;
                cartridge.char_banks = char_banks;
                cartridge.program_memory = program_memory;
                cartridge.char_memory = char_memory;
            },
            2 => {},
            else => {},
        }

        switch (mapper_id) {
            0, 1, 2, 3, 4, 66 => {
                cartridge.mapper = try Mapper.init(mapper_id, cartridge.program_banks, cartridge.char_banks);
            },
            else => return error.UnsupportedMapper,
        }

        return cartridge;
    }

    pub fn initBytes(allocator: std.mem.Allocator, rom: []const u8) !@This() {
        var pos: usize = 0;

        if (rom.len < @sizeOf(inesHeader)) return error.InvalidRom;
        var header: inesHeader = undefined;
        @memcpy(std.mem.asBytes(&header), rom[pos..][0..@sizeOf(inesHeader)]);
        pos += @sizeOf(inesHeader);

        if (header.mapper1 & 0x04 != 0) pos += 512; // skip trainer

        const mapper_id = ((header.mapper2 >> 4) << 4) | (header.mapper1 >> 4);

        var cartridge = @This(){
            .allocator = allocator,
            .mapper_id = mapper_id,
            .program_memory = undefined,
            .char_memory = undefined,
            .mapper = undefined,
            .mirror = if (header.mapper1 & 0x01 != 0) .vertical else .horizontal,
        };

        const program_banks = header.program_rom_chunks;
        const char_banks = header.char_rom_chunks;
        const program_size = @as(usize, program_banks) * 16384;
        const char_size: usize = if (char_banks == 0) 8192 else @as(usize, char_banks) * 8192;

        if (pos + program_size > rom.len) return error.InvalidRom;
        const program_memory = try allocator.alloc(u8, program_size);
        @memcpy(program_memory, rom[pos..][0..program_size]);
        pos += program_size;

        const char_memory = try allocator.alloc(u8, char_size);
        if (char_banks > 0) {
            if (pos + char_size > rom.len) return error.InvalidRom;
            @memcpy(char_memory, rom[pos..][0..char_size]);
        }

        cartridge.program_banks = program_banks;
        cartridge.char_banks = char_banks;
        cartridge.program_memory = program_memory;
        cartridge.char_memory = char_memory;

        switch (mapper_id) {
            0, 1, 2, 3, 4, 66 => {
                cartridge.mapper = try Mapper.init(mapper_id, cartridge.program_banks, cartridge.char_banks);
            },
            else => return error.UnsupportedMapper,
        }

        return cartridge;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.program_memory);
        self.allocator.free(self.char_memory);
    }

    pub fn cpuRead(self: *@This(), addr: u16, data: *u8) bool {
        var mapped_addr: u32 = 0;
        if (self.mapper.cpuMapRead(addr, &mapped_addr, data)) {
            if (mapped_addr == 0xFFFFFFFF) return true;
            data.* = self.program_memory[mapped_addr];
            return true;
        }
        return false;
    }

    pub fn cpuWrite(self: *@This(), addr: u16, data: u8) bool {
        var mapped_addr: u32 = 0;
        if (self.mapper.cpuMapWrite(addr, &mapped_addr, data)) {
            if (mapped_addr == 0xFFFFFFFF) return true;
            self.program_memory[mapped_addr] = data;
            return true;
        }
        return false;
    }

    pub fn ppuRead(self: *@This(), addr: u16, data: *u8) bool {
        var mapped_addr: u32 = undefined;
        if (self.mapper.ppuMapRead(addr, &mapped_addr)) {
            data.* = self.char_memory[mapped_addr];
            return true;
        }
        return false;
    }

    pub fn ppuWrite(self: *@This(), addr: u16, data: u8) bool {
        var mapped_addr: u32 = undefined;
        if (self.mapper.ppuMapWrite(addr, &mapped_addr)) {
            self.char_memory[mapped_addr] = data;
            return true;
        }
        return false;
    }

    pub fn currentMirror(self: *@This()) Mirror {
        return self.mapper.mirror() orelse self.mirror;
    }
};

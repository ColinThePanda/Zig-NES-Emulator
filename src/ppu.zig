const std = @import("std");
const Cartridge = @import("cartridge.zig").Cartridge;
const rl = @import("raylib");

const Status2C02 = packed struct {
    unused: u5 = 0,
    sprite_overflow: u1 = 0,
    sprite_zero_hit: u1 = 0,
    vertical_blank: u1 = 0,
};

const Mask2C02 = packed struct {
    grayscale: u1 = 0,
    render_background_left: u1 = 0,
    render_sprites_left: u1 = 0,
    render_background: u1 = 0,
    render_sprites: u1 = 0,
    enhance_red: u1 = 0,
    enhance_green: u1 = 0,
    enhance_blue: u1 = 0,
};

const Ctrl2C02 = packed struct {
    nametable_x: u1 = 0,
    nametable_y: u1 = 0,
    increment_mode: u1 = 0,
    pattern_sprite: u1 = 0,
    pattern_background: u1 = 0,
    sprite_size: u1 = 0,
    slave_mode: u1 = 0,
    enable_nmi: u1 = 0,
};

const LoopyRegister = packed struct {
    coarse_x: u5 = 0,
    coarse_y: u5 = 0,
    nametable_x: u1 = 0,
    nametable_y: u1 = 0,
    fine_y: u3 = 0,
    unused: u1 = 0,
};

const ObjectAttributeEntry = extern struct {
    y: u8 = 0,
    id: u8 = 0,
    attribute: u8 = 0,
    x: u8 = 0,
};

pub const nes_system_palette: [0x40]rl.Color = .{
    .{ .r = 84, .g = 84, .b = 84, .a = 255 },
    .{ .r = 0, .g = 30, .b = 116, .a = 255 },
    .{ .r = 8, .g = 16, .b = 144, .a = 255 },
    .{ .r = 48, .g = 0, .b = 136, .a = 255 },
    .{ .r = 68, .g = 0, .b = 100, .a = 255 },
    .{ .r = 92, .g = 0, .b = 48, .a = 255 },
    .{ .r = 84, .g = 4, .b = 0, .a = 255 },
    .{ .r = 60, .g = 24, .b = 0, .a = 255 },
    .{ .r = 32, .g = 42, .b = 0, .a = 255 },
    .{ .r = 8, .g = 58, .b = 0, .a = 255 },
    .{ .r = 0, .g = 64, .b = 0, .a = 255 },
    .{ .r = 0, .g = 60, .b = 0, .a = 255 },
    .{ .r = 0, .g = 50, .b = 60, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 152, .g = 150, .b = 152, .a = 255 },
    .{ .r = 8, .g = 76, .b = 196, .a = 255 },
    .{ .r = 48, .g = 50, .b = 236, .a = 255 },
    .{ .r = 92, .g = 30, .b = 228, .a = 255 },
    .{ .r = 136, .g = 20, .b = 176, .a = 255 },
    .{ .r = 160, .g = 20, .b = 100, .a = 255 },
    .{ .r = 152, .g = 34, .b = 32, .a = 255 },
    .{ .r = 120, .g = 60, .b = 0, .a = 255 },
    .{ .r = 84, .g = 90, .b = 0, .a = 255 },
    .{ .r = 40, .g = 114, .b = 0, .a = 255 },
    .{ .r = 8, .g = 124, .b = 0, .a = 255 },
    .{ .r = 0, .g = 118, .b = 40, .a = 255 },
    .{ .r = 0, .g = 102, .b = 120, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 236, .g = 238, .b = 236, .a = 255 },
    .{ .r = 76, .g = 154, .b = 236, .a = 255 },
    .{ .r = 120, .g = 124, .b = 236, .a = 255 },
    .{ .r = 176, .g = 98, .b = 236, .a = 255 },
    .{ .r = 228, .g = 84, .b = 236, .a = 255 },
    .{ .r = 236, .g = 88, .b = 180, .a = 255 },
    .{ .r = 236, .g = 106, .b = 100, .a = 255 },
    .{ .r = 212, .g = 136, .b = 32, .a = 255 },
    .{ .r = 160, .g = 170, .b = 0, .a = 255 },
    .{ .r = 116, .g = 196, .b = 0, .a = 255 },
    .{ .r = 76, .g = 208, .b = 32, .a = 255 },
    .{ .r = 56, .g = 204, .b = 108, .a = 255 },
    .{ .r = 56, .g = 180, .b = 204, .a = 255 },
    .{ .r = 60, .g = 60, .b = 60, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 236, .g = 238, .b = 236, .a = 255 },
    .{ .r = 168, .g = 204, .b = 236, .a = 255 },
    .{ .r = 188, .g = 188, .b = 236, .a = 255 },
    .{ .r = 212, .g = 178, .b = 236, .a = 255 },
    .{ .r = 236, .g = 174, .b = 236, .a = 255 },
    .{ .r = 236, .g = 174, .b = 212, .a = 255 },
    .{ .r = 236, .g = 180, .b = 176, .a = 255 },
    .{ .r = 228, .g = 196, .b = 144, .a = 255 },
    .{ .r = 204, .g = 210, .b = 120, .a = 255 },
    .{ .r = 180, .g = 222, .b = 120, .a = 255 },
    .{ .r = 168, .g = 226, .b = 144, .a = 255 },
    .{ .r = 152, .g = 226, .b = 180, .a = 255 },
    .{ .r = 160, .g = 214, .b = 228, .a = 255 },
    .{ .r = 160, .g = 162, .b = 160, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    .{ .r = 0, .g = 0, .b = 0, .a = 255 },
};

pub const olc2C02 = struct {
    cartridge: *Cartridge = undefined,

    name_table: [2][1024]u8 = @splat(@as([1024]u8, @splat(0))),
    palette_table: [32]u8 = @splat(0),
    pattern_table: [2][4096]u8 = @splat(@as([4096]u8, @splat(0))),

    palette_screen: [0x40]rl.Color,
    sprite_screen: rl.Image,
    sprite_name_table: [2]rl.Image,
    sprite_pattern_table: [2]rl.Image,

    vram_addr: LoopyRegister = .{},
    tram_addr: LoopyRegister = .{},

    status: Status2C02 = .{},
    mask: Mask2C02 = .{},
    control: Ctrl2C02 = .{},

    fine_x: u8 = 0x00,

    address_latch: u8 = 0,
    ppu_data_buffer: u8 = 0x00,

    scanline: i16 = 0,
    cycle: i16 = 0,

    bg_next_tile_id: u8 = 0x00,
    bg_next_tile_attrib: u8 = 0x00,
    bg_next_tile_lsb: u8 = 0x00,
    bg_next_tile_msb: u8 = 0x00,
    bg_shifter_pattern_lo: u16 = 0x0000,
    bg_shifter_pattern_hi: u16 = 0x0000,
    bg_shifter_attrib_lo: u16 = 0x0000,
    bg_shifter_attrib_hi: u16 = 0x0000,

    nmi: bool = false,

    frame_complete: bool = false,

    oam: [64]ObjectAttributeEntry = @splat(.{}),
    oam_addr: u8 = 0x00,
    sprite_scanline: [8]ObjectAttributeEntry = @splat(.{}),
    sprite_count: u8 = 0,
    sprite_shifter_pattern_lo: [8]u8 = @splat(0),
    sprite_shifter_pattern_hi: [8]u8 = @splat(0),
    sprite_zero_hit_possible: bool = false,
    sprite_zero_being_rendered: bool = false,

    nmi_count: u32 = 0,
    frame_count: u32 = 0,

    pub fn init() @This() {
        return @This(){
            .palette_screen = nes_system_palette,
            .sprite_screen = rl.genImageColor(256, 240, rl.Color.black),
            .sprite_name_table = .{ rl.genImageColor(256, 240, rl.Color.black), rl.genImageColor(256, 240, rl.Color.black) },
            .sprite_pattern_table = .{ rl.genImageColor(128, 128, rl.Color.black), rl.genImageColor(128, 128, rl.Color.black) },
        };
    }

    pub fn deinit(self: *@This()) void {
        rl.unloadImage(self.sprite_screen);
        for (self.sprite_name_table) |img| rl.unloadImage(img);
        for (self.sprite_pattern_table) |img| rl.unloadImage(img);
    }

    pub fn oamBytes(self: *@This()) []u8 {
        return std.mem.sliceAsBytes(self.oam[0..]);
    }

    pub fn cpuRead(self: *@This(), addr: u16, read_only: bool) u8 {
        if (read_only) {
            switch (addr) {
                0x0000 => return @bitCast(self.control),
                0x0001 => return @bitCast(self.mask),
                0x0002 => return @bitCast(self.status),
                0x0003 => return 0,
                0x0004 => return 0,
                0x0005 => return 0,
                0x0006 => return 0,
                0x0007 => return 0,
                else => return 0,
            }
        } else {
            switch (addr) {
                0x0000 => return 0,
                0x0001 => return 0,
                0x0002 => {
                    const data = (@as(u8, @bitCast(self.status)) & 0xE0) | (self.ppu_data_buffer & 0x1F);
                    self.status.vertical_blank = 0;
                    self.address_latch = 0;
                    return data;
                },
                0x0003 => return 0,
                0x0004 => return self.oamBytes()[self.oam_addr],
                0x0005 => return 0,
                0x0006 => return 0,
                0x0007 => {
                    const vram: u16 = @bitCast(self.vram_addr);
                    var data = self.ppu_data_buffer;
                    self.ppu_data_buffer = self.ppuRead(vram, false);
                    if (@as(u16, vram) >= 0x3F00) data = self.ppu_data_buffer;
                    self.vram_addr = @bitCast(vram +% (if (self.control.increment_mode == 1) @as(u16, 32) else @as(u16, 1)));
                    return data;
                },
                else => return 0,
            }
        }
    }

    pub fn cpuWrite(self: *@This(), addr: u16, data: u8) void {
        switch (addr) {
            0x0000 => {
                self.control = @bitCast(data);
                self.tram_addr.nametable_x = self.control.nametable_x;
                self.tram_addr.nametable_y = self.control.nametable_y;
            },
            0x0001 => self.mask = @bitCast(data),
            0x0002 => {},
            0x0003 => self.oam_addr = data,
            0x0004 => self.oamBytes()[self.oam_addr] = data,
            0x0005 => {
                if (self.address_latch == 0) {
                    self.fine_x = data & 0x07;
                    self.tram_addr.coarse_x = @truncate(data >> 3);
                    self.address_latch = 1;
                } else {
                    self.tram_addr.fine_y = @truncate(data);
                    self.tram_addr.coarse_y = @truncate(data >> 3);
                    self.address_latch = 0;
                }
            },
            0x0006 => {
                if (self.address_latch == 0) {
                    self.tram_addr = @bitCast((@as(u16, data & 0x3F) << 8) | (@as(u16, @bitCast(self.tram_addr)) & 0x00FF));
                    self.address_latch = 1;
                } else {
                    self.tram_addr = @bitCast((@as(u16, @bitCast(self.tram_addr)) & 0xFF00) | data);
                    self.vram_addr = self.tram_addr;
                    self.address_latch = 0;
                }
            },
            0x0007 => {
                self.ppuWrite(@bitCast(self.vram_addr), data);
                self.vram_addr = @bitCast(@as(u16, @bitCast(self.vram_addr)) +% (if (self.control.increment_mode == 1) @as(u16, 32) else @as(u16, 1)));
            },
            else => {},
        }
    }

    pub fn ppuRead(self: *@This(), addr: u16, read_only: bool) u8 {
        _ = read_only;

        var data: u8 = 0x00;
        var address = addr & 0x3FFF;

        if (self.cartridge.ppuRead(address, &data)) {
            return data;
        } else if (address >= 0x0000 and address <= 0x1FFF) {
            _ = self.cartridge.ppuRead(address, &data);
            return data;
        } else if (address >= 0x2000 and address <= 0x3EFF) {
            address &= 0x0FFF;

            if (self.cartridge.mirror == .vertical) {
                if (address >= 0x0000 and address <= 0x03FF)
                    return self.name_table[0][address & 0x03FF];
                if (address >= 0x0400 and address <= 0x07FF)
                    return self.name_table[1][address & 0x03FF];
                if (address >= 0x0800 and address <= 0x0BFF)
                    return self.name_table[0][address & 0x03FF];
                if (address >= 0x0C00 and address <= 0x0FFF)
                    return self.name_table[1][address & 0x03FF];
            } else if (self.cartridge.mirror == .horizontal) {
                if (address >= 0x0000 and address <= 0x03FF)
                    return self.name_table[0][address & 0x03FF];
                if (address >= 0x0400 and address <= 0x07FF)
                    return self.name_table[0][address & 0x03FF];
                if (address >= 0x0800 and address <= 0x0BFF)
                    return self.name_table[1][address & 0x03FF];
                if (address >= 0x0C00 and address <= 0x0FFF)
                    return self.name_table[1][address & 0x03FF];
            }
        } else if (address >= 0x3F00 and address <= 0x3FFF) {
            address &= 0x001F;
            if (address == 0x0010) address = 0x0000;
            if (address == 0x0014) address = 0x0004;
            if (address == 0x0018) address = 0x0008;
            if (address == 0x001C) address = 0x000C;
            return self.palette_table[address] & if (self.mask.grayscale != 0) @as(u8, 0x30) else @as(u8, 0x3F);
        }

        return 0;
    }

    pub fn ppuWrite(self: *@This(), addr: u16, data: u8) void {
        var address = addr & 0x3FFF;

        if (self.cartridge.ppuWrite(address, data)) {
            // nothing
        } else if (address >= 0x0000 and address <= 0x1FFF) {
            _ = self.cartridge.ppuWrite(address, data);
        } else if (address >= 0x2000 and address <= 0x3EFF) {
            address &= 0x0FFF;

            if (self.cartridge.mirror == .vertical) {
                if (address >= 0x0000 and address <= 0x03FF)
                    self.name_table[0][address & 0x03FF] = data;
                if (address >= 0x0400 and address <= 0x07FF)
                    self.name_table[1][address & 0x03FF] = data;
                if (address >= 0x0800 and address <= 0x0BFF)
                    self.name_table[0][address & 0x03FF] = data;
                if (address >= 0x0C00 and address <= 0x0FFF)
                    self.name_table[1][address & 0x03FF] = data;
            } else if (self.cartridge.mirror == .horizontal) {
                if (address >= 0x0000 and address <= 0x03FF)
                    self.name_table[0][address & 0x03FF] = data;
                if (address >= 0x0400 and address <= 0x07FF)
                    self.name_table[0][address & 0x03FF] = data;
                if (address >= 0x0800 and address <= 0x0BFF)
                    self.name_table[1][address & 0x03FF] = data;
                if (address >= 0x0C00 and address <= 0x0FFF)
                    self.name_table[1][address & 0x03FF] = data;
            }
        } else if (address >= 0x3F00 and address <= 0x3FFF) {
            address &= 0x001F;
            if (address == 0x0010) address = 0x0000;
            if (address == 0x0014) address = 0x0004;
            if (address == 0x0018) address = 0x0008;
            if (address == 0x001C) address = 0x000C;
            self.palette_table[address] = data;
        }
    }

    pub fn connectCartridge(self: *@This(), cartridge: *Cartridge) void {
        self.cartridge = cartridge;
    }

    pub fn reset(self: *@This()) void {
        self.fine_x = 0x00;
        self.address_latch = 0x00;
        self.ppu_data_buffer = 0x00;
        self.scanline = 0;
        self.cycle = 0;
        self.bg_next_tile_id = 0x00;
        self.bg_next_tile_attrib = 0x00;
        self.bg_next_tile_lsb = 0x00;
        self.bg_next_tile_msb = 0x00;
        self.bg_shifter_pattern_lo = 0x0000;
        self.bg_shifter_pattern_hi = 0x0000;
        self.bg_shifter_attrib_lo = 0x0000;
        self.bg_shifter_attrib_hi = 0x0000;
        self.status = @bitCast(@as(u8, 0x00));
        self.mask = @bitCast(@as(u8, 0x00));
        self.control = @bitCast(@as(u8, 0x00));
        self.vram_addr = @bitCast(@as(u16, 0x0000));
        self.tram_addr = @bitCast(@as(u16, 0x0000));
    }

    pub fn getPatternTable(self: *@This(), i: u8, palette: u8) rl.Image {
        for (0..16) |tile_y_usize| {
            const tile_y = @as(u16, @intCast(tile_y_usize));
            for (0..16) |tile_x_usize| {
                const tile_x = @as(u16, @intCast(tile_x_usize));
                const offset: u16 = tile_y * 256 + tile_x * 16;

                for (0..8) |row_usize| {
                    const row = @as(u16, @intCast(row_usize));
                    var tile_lsb: u8 = self.ppuRead(@as(u16, i) * 0x1000 + offset + row, false);
                    var tile_msb: u8 = self.ppuRead(@as(u16, i) * 0x1000 + offset + row + 8, false);

                    for (0..8) |col| {
                        const pixel: u8 = (tile_lsb & 0x01) + (tile_msb & 0x01);

                        tile_lsb >>= 1;
                        tile_msb >>= 1;
                        rl.imageDrawPixel(&self.sprite_pattern_table[i], @as(i32, tile_x) * 8 + (7 - @as(i32, @intCast(col))), @as(i32, tile_y) * 8 + @as(i32, row), self.getColourFromPaletteRam(palette, pixel));
                    }
                }
            }
        }

        return self.sprite_pattern_table[i];
    }

    pub fn getColourFromPaletteRam(self: *@This(), palette: u8, pixel: u8) rl.Color {
        return self.palette_screen[self.ppuRead(0x3F00 + (@as(u16, palette) << 2) + pixel, false) & 0x3F];
    }

    fn incrementScrollX(self: *@This()) void {
        if ((self.mask.render_background != 0) or (self.mask.render_sprites != 0)) {
            if (self.vram_addr.coarse_x == 31) {
                self.vram_addr.coarse_x = 0;
                self.vram_addr.nametable_x = ~self.vram_addr.nametable_x;
            } else {
                self.vram_addr.coarse_x += 1;
            }
        }
    }

    fn incrementScrollY(self: *@This()) void {
        if ((self.mask.render_background != 0) or (self.mask.render_sprites != 0)) {
            if (self.vram_addr.fine_y < 7) {
                self.vram_addr.fine_y += 1;
            } else {
                self.vram_addr.fine_y = 0;

                if (self.vram_addr.coarse_y == 29) {
                    self.vram_addr.coarse_y = 0;
                    self.vram_addr.nametable_y = ~self.vram_addr.nametable_y;
                } else if (self.vram_addr.coarse_y == 31) {
                    self.vram_addr.coarse_y = 0;
                } else {
                    self.vram_addr.coarse_y += 1;
                }
            }
        }
    }

    fn transferAddressX(self: *@This()) void {
        if ((self.mask.render_background != 0) or (self.mask.render_sprites != 0)) {
            self.vram_addr.nametable_x = self.tram_addr.nametable_x;
            self.vram_addr.coarse_x = self.tram_addr.coarse_x;
        }
    }

    fn transferAddressY(self: *@This()) void {
        if ((self.mask.render_background != 0) or (self.mask.render_sprites != 0)) {
            self.vram_addr.fine_y = self.tram_addr.fine_y;
            self.vram_addr.nametable_y = self.tram_addr.nametable_y;
            self.vram_addr.coarse_y = self.tram_addr.coarse_y;
        }
    }

    fn loadBackgroundShifters(self: *@This()) void {
        self.bg_shifter_pattern_lo = (self.bg_shifter_pattern_lo & 0xFF00) | self.bg_next_tile_lsb;
        self.bg_shifter_pattern_hi = (self.bg_shifter_pattern_hi & 0xFF00) | self.bg_next_tile_msb;
        self.bg_shifter_attrib_lo = (self.bg_shifter_attrib_lo & 0xFF00) | if (self.bg_next_tile_attrib & 0b01 != 0) @as(u8, 0xFF) else @as(u8, 0x00);
        self.bg_shifter_attrib_hi = (self.bg_shifter_attrib_hi & 0xFF00) | if (self.bg_next_tile_attrib & 0b10 != 0) @as(u8, 0xFF) else @as(u8, 0x00);
    }

    fn updateShifters(self: *@This()) void {
        if (self.mask.render_background != 0) {
            self.bg_shifter_pattern_lo <<= 1;
            self.bg_shifter_pattern_hi <<= 1;

            self.bg_shifter_attrib_lo <<= 1;
            self.bg_shifter_attrib_hi <<= 1;
        }

        if (self.mask.render_sprites != 0 and self.cycle >= 1 and self.cycle < 258) {
            for (self.sprite_scanline, 0..) |sprite, i| {
                if (sprite.x > 0) {
                    self.sprite_scanline[i].x -= 1;
                } else {
                    self.sprite_shifter_pattern_lo[i] <<= 1;
                    self.sprite_shifter_pattern_hi[i] <<= 1;
                }
            }
        }
    }

    pub fn clock(self: *@This()) void {
        if (self.scanline >= -1 and self.scanline < 240) {
            if (self.scanline == 0 and self.cycle == 0) {
                self.cycle = 1;
            }

            if (self.scanline == -1 and self.cycle == 1) {
                self.status.vertical_blank = 0;
                self.status.sprite_overflow = 0;
                self.status.sprite_zero_hit = 0;
                for (0..8) |i| {
                    self.sprite_shifter_pattern_lo[i] = 0;
                    self.sprite_shifter_pattern_hi[i] = 0;
                }
            }

            if ((self.cycle >= 2 and self.cycle < 258) or (self.cycle >= 321 and self.cycle < 338)) {
                self.updateShifters();

                switch (@as(u16, @intCast(self.cycle - 1)) % @as(u16, 8)) {
                    0 => {
                        self.loadBackgroundShifters();
                        self.bg_next_tile_id = self.ppuRead(0x2000 | (@as(u16, @bitCast(self.vram_addr)) & 0x0FFF), false);
                    },
                    2 => {
                        self.bg_next_tile_attrib = self.ppuRead(0x23C0 | (@as(u16, self.vram_addr.nametable_y) << 11) | (@as(u16, self.vram_addr.nametable_x) << 10) | ((@as(u16, self.vram_addr.coarse_y) >> 2) << 3) | (@as(u16, self.vram_addr.coarse_x) >> 2), false);
                        if (self.vram_addr.coarse_y & 0x02 != 0) self.bg_next_tile_attrib >>= 4;
                        if (self.vram_addr.coarse_x & 0x02 != 0) self.bg_next_tile_attrib >>= 2;
                        self.bg_next_tile_attrib &= 0x03;
                    },
                    4 => self.bg_next_tile_lsb = self.ppuRead((@as(u16, self.control.pattern_background) << 12) + (@as(u16, self.bg_next_tile_id) << 4) + @as(u16, self.vram_addr.fine_y), false),
                    6 => self.bg_next_tile_msb = self.ppuRead((@as(u16, self.control.pattern_background) << 12) + (@as(u16, self.bg_next_tile_id) << 4) + @as(u16, self.vram_addr.fine_y) + 8, false),
                    7 => self.incrementScrollX(),
                    else => {},
                }
            }

            if (self.cycle == 256) {
                self.incrementScrollY();
            }

            if (self.cycle == 257) {
                self.loadBackgroundShifters();
                self.transferAddressX();
            }

            if (self.cycle == 338 or self.cycle == 340) {
                self.bg_next_tile_id = self.ppuRead(0x2000 | (@as(u16, @bitCast(self.vram_addr)) & 0x0FFF), false);
            }

            if (self.scanline == -1 and self.cycle >= 280 and self.cycle < 305) {
                self.transferAddressY();
            }

            // foreground
            if (self.cycle == 257 and self.scanline >= 0) {
                @memset(std.mem.sliceAsBytes(self.sprite_scanline[0..]), 0xFF);
                self.sprite_count = 0;
                for (0..8) |i| {
                    self.sprite_shifter_pattern_lo[i] = 0;
                    self.sprite_shifter_pattern_hi[i] = 0;
                }

                var oam_entry: u8 = 0;
                while (oam_entry < 64 and self.sprite_count < 9) : (oam_entry += 1) {
                    const diff: i16 = @as(i16, @intCast(self.scanline)) - @as(i16, @intCast(self.oam[oam_entry].y));
                    if (diff >= 0 and (diff < if (self.control.sprite_size != 0) @as(u8, 16) else @as(u8, 8)) and self.sprite_count < 8) {
                        if (oam_entry == 0) {
                            self.sprite_zero_hit_possible = true;
                        }

                        self.sprite_scanline[self.sprite_count] = self.oam[oam_entry];
                        self.sprite_count += 1;
                    }
                }

                self.status.sprite_overflow = if (self.sprite_count > 8) 1 else 0;
            }
        }

        if (self.cycle == 340) {
            for (self.sprite_scanline[0..self.sprite_count], 0..) |sprite, i| {
                var sprite_pattern_bits_lo: u8 = undefined;
                var sprite_pattern_bits_hi: u8 = undefined;
                var sprite_pattern_addr_lo: u16 = undefined;
                var sprite_pattern_addr_hi: u16 = undefined;

                const flip_v = sprite.attribute & 0x80 != 0;

                const raw_row: i16 = self.scanline -% @as(i16, sprite.y);
                const row: u16 = blk: {
                    const r = @as(u16, @bitCast(raw_row)) & 0x07;
                    break :blk if (flip_v) (7 - r) else r;
                };

                if (self.control.sprite_size == 0) {
                    sprite_pattern_addr_lo =
                        (@as(u16, self.control.pattern_sprite) << 12) |
                        (@as(u16, sprite.id) << 4) |
                        row;
                } else {
                    const top_half = (@as(u16, @bitCast(raw_row)) & 0x08) == 0;
                    const use_top = top_half != flip_v;
                    const tile: u16 = if (use_top) @as(u16, sprite.id & 0xFE) else @as(u16, sprite.id & 0xFE) + 1;

                    sprite_pattern_addr_lo =
                        (@as(u16, sprite.id & 0x01) << 12) |
                        (tile << 4) |
                        row;
                }

                sprite_pattern_addr_hi = sprite_pattern_addr_lo + 8;
                sprite_pattern_bits_lo = self.ppuRead(sprite_pattern_addr_lo, false);
                sprite_pattern_bits_hi = self.ppuRead(sprite_pattern_addr_hi, false);

                if (sprite.attribute & 0x40 != 0) {
                    sprite_pattern_bits_lo = @bitReverse(sprite_pattern_bits_lo);
                    sprite_pattern_bits_hi = @bitReverse(sprite_pattern_bits_hi);
                }

                self.sprite_shifter_pattern_lo[i] = sprite_pattern_bits_lo;
                self.sprite_shifter_pattern_hi[i] = sprite_pattern_bits_hi;
            }
        }

        if (self.scanline == 240) {
            // post render scanline - nothing
        }

        if (self.scanline >= 241 and self.scanline < 261) {
            if (self.scanline == 241 and self.cycle == 1) {
                self.status.vertical_blank = 1;
                if (self.control.enable_nmi != 0) {
                    self.nmi = true;
                    self.nmi_count += 1;
                }
            }
        }

        var bg_pixel: u8 = 0x00;
        var bg_palette: u8 = 0x00;

        if (self.mask.render_background != 0) {
            const bit_mux: u16 = @as(u16, 0x8000) >> @as(u3, @truncate(self.fine_x));

            const p0_pixel: u8 = if ((self.bg_shifter_pattern_lo & bit_mux) > 0) @as(u8, 1) else @as(u8, 0);
            const p1_pixel: u8 = if ((self.bg_shifter_pattern_hi & bit_mux) > 0) @as(u8, 1) else @as(u8, 0);
            bg_pixel = (p1_pixel << 1) | p0_pixel;

            const bg_pal0: u8 = if ((self.bg_shifter_attrib_lo & bit_mux) > 0) @as(u8, 1) else @as(u8, 0);
            const bg_pal1: u8 = if ((self.bg_shifter_attrib_hi & bit_mux) > 0) @as(u8, 1) else @as(u8, 0);
            bg_palette = (bg_pal1 << 1) | bg_pal0;
        }

        var fg_pixel: u8 = 0x00;
        var fg_palette: u8 = 0x00;
        var fg_priority: bool = false;

        if (self.mask.render_sprites != 0) {
            self.sprite_zero_being_rendered = false;
            for (self.sprite_scanline, 0..) |sprite, i| {
                if (sprite.x == 0) {
                    const fg_pixel_lo: u8 = if ((self.sprite_shifter_pattern_lo[i] & 0x80) > 0) 1 else 0;
                    const fg_pixel_hi: u8 = if ((self.sprite_shifter_pattern_hi[i] & 0x80) > 0) 1 else 0;
                    fg_pixel = (fg_pixel_hi << 1) | fg_pixel_lo;
                    fg_palette = (sprite.attribute & 0x03) + 0x04;
                    fg_priority = (sprite.attribute & 0x20) == 0;
                    if (fg_pixel != 0) {
                        if (i == 0) {
                            self.sprite_zero_being_rendered = true;
                        }
                        break;
                    }
                }
            }
        }

        var pixel: u8 = 0x00;
        var palette: u8 = 0x00;

        if (bg_pixel == 0 and fg_pixel == 0) {
            pixel = 0x00;
            palette = 0x00;
        } else if (bg_pixel == 0 and fg_pixel > 0) {
            pixel = fg_pixel;
            palette = fg_palette;
        } else if (bg_pixel > 0 and fg_pixel == 0) {
            pixel = bg_pixel;
            palette = bg_palette;
        } else if (bg_pixel > 0 and fg_pixel > 0) {
            if (fg_priority) {
                pixel = fg_pixel;
                palette = fg_palette;
            } else {
                pixel = bg_pixel;
                palette = bg_palette;
            }

            if (self.sprite_zero_hit_possible and self.sprite_zero_being_rendered) {
                if (self.mask.render_background & self.mask.render_sprites != 0) {
                    if (self.mask.render_background_left | self.mask.render_sprites_left == 0) {
                        if (self.cycle >= 9 and self.cycle < 258) {
                            self.status.sprite_zero_hit = 1;
                        }
                    } else {
                        if (self.cycle >= 1 and self.cycle < 258) {
                            self.status.sprite_zero_hit = 1;
                        }
                    }
                }
            }
        }

        rl.imageDrawPixel(&self.sprite_screen, self.cycle - 1, self.scanline, self.getColourFromPaletteRam(palette, pixel));

        self.cycle += 1;
        if (self.cycle >= 341) {
            self.cycle = 0;
            self.scanline += 1;
            if (self.scanline >= 261) {
                self.scanline = -1;
                self.frame_complete = true;
                self.frame_count += 1;
            }
        }
    }
};

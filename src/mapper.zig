const Mirror = @import("cartridge.zig").Mirror;

pub const Mapper = union(enum) {
    mapper000: Mapper000,
    mapper001: Mapper001,
    mapper002: Mapper002,
    mapper003: Mapper003,
    mapper004: Mapper004,
    mapper066: Mapper066,

    pub fn init(mapper_id: u8, program_banks: u8, char_banks: u8) !@This() {
        return switch (mapper_id) {
            0 => .{ .mapper000 = Mapper000.init(program_banks, char_banks) },
            1 => .{ .mapper001 = Mapper001.init(program_banks, char_banks) },
            2 => .{ .mapper002 = Mapper002.init(program_banks, char_banks) },
            3 => .{ .mapper003 = Mapper003.init(program_banks, char_banks) },
            4 => .{ .mapper004 = Mapper004.init(program_banks, char_banks) },
            66 => .{ .mapper066 = Mapper066.init(program_banks, char_banks) },
            else => error.UnsupportedMapper,
        };
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32, data: *u8) bool {
        return switch (self.*) {
            inline else => |*m| m.cpuMapRead(addr, mapped_addr, data),
        };
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32, data: u8) bool {
        return switch (self.*) {
            inline else => |*m| m.cpuMapWrite(addr, mapped_addr, data),
        };
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        return switch (self.*) {
            inline else => |*m| m.ppuMapRead(addr, mapped_addr),
        };
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        return switch (self.*) {
            inline else => |*m| m.ppuMapWrite(addr, mapped_addr),
        };
    }

    pub fn reset(self: *@This()) void {
        switch (self.*) {
            inline else => |*m| if (comptime @hasDecl(@TypeOf(m.*), "reset")) m.reset(),
        }
    }

    pub fn mirror(self: *@This()) ?Mirror {
        return switch (self.*) {
            inline else => |*m| if (comptime @hasDecl(@TypeOf(m.*), "mirror")) m.mirror() else null,
        };
    }

    pub fn irqState(self: *@This()) bool {
        return switch (self.*) {
            inline else => |*m| if (comptime @hasDecl(@TypeOf(m.*), "irqState")) m.irqState() else false,
        };
    }

    pub fn irqClear(self: *@This()) void {
        switch (self.*) {
            inline else => |*m| if (comptime @hasDecl(@TypeOf(m.*), "irqClear")) m.irqClear(),
        }
    }

    pub fn scanline(self: *@This()) void {
        switch (self.*) {
            inline else => |*m| if (comptime @hasDecl(@TypeOf(m.*), "scanline")) m.scanline(),
        }
    }
};

pub const Mapper000 = struct {
    program_banks: u8,
    char_banks: u8,

    pub fn init(program_banks: u8, char_banks: u8) @This() {
        return .{ .program_banks = program_banks, .char_banks = char_banks };
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32, data: *u8) bool {
        _ = data;
        if (addr >= 0x8000) {
            mapped_addr.* = addr & if (self.program_banks > 1) @as(u16, 0x7FFF) else @as(u16, 0x3FFF);
            return true;
        }
        return false;
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32, data: u8) bool {
        _ = data;
        if (addr >= 0x8000) {
            mapped_addr.* = addr & if (self.program_banks > 1) @as(u16, 0x7FFF) else @as(u16, 0x3FFF);
            return true;
        }
        return false;
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        _ = self;
        if (addr <= 0x1FFF) {
            mapped_addr.* = addr;
            return true;
        }
        return false;
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF and self.char_banks == 0) {
            mapped_addr.* = addr;
            return true;
        }
        return false;
    }
};

pub const Mapper001 = struct {
    program_banks: u8,
    char_banks: u8,
    chr_bank_4lo: u8 = 0,
    chr_bank_4hi: u8 = 0,
    chr_bank_8: u8 = 0,
    prg_bank_16lo: u8 = 0,
    prg_bank_16hi: u8 = 0,
    prg_bank_32: u8 = 0,
    load_register: u8 = 0,
    load_count: u8 = 0,
    control_register: u8 = 0x1C,
    mirror_mode: Mirror = .horizontal,
    ram: [32 * 1024]u8 = @splat(0),

    pub fn init(program_banks: u8, char_banks: u8) @This() {
        var m = @This(){ .program_banks = program_banks, .char_banks = char_banks };
        m.prg_bank_16hi = program_banks - 1;
        return m;
    }

    pub fn reset(self: *@This()) void {
        self.control_register = 0x1C;
        self.load_register = 0;
        self.load_count = 0;
        self.chr_bank_4lo = 0;
        self.chr_bank_4hi = 0;
        self.chr_bank_8 = 0;
        self.prg_bank_32 = 0;
        self.prg_bank_16lo = 0;
        self.prg_bank_16hi = self.program_banks - 1;
    }

    pub fn mirror(self: *@This()) ?Mirror {
        return self.mirror_mode;
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32, data: *u8) bool {
        if (addr >= 0x6000 and addr <= 0x7FFF) {
            mapped_addr.* = 0xFFFFFFFF;
            data.* = self.ram[addr & 0x1FFF];
            return true;
        }
        if (addr >= 0x8000) {
            if (self.control_register & 0b01000 != 0) {
                if (addr <= 0xBFFF) {
                    mapped_addr.* = @as(u32, self.prg_bank_16lo) * 0x4000 + (addr & 0x3FFF);
                } else {
                    mapped_addr.* = @as(u32, self.prg_bank_16hi) * 0x4000 + (addr & 0x3FFF);
                }
            } else {
                mapped_addr.* = @as(u32, self.prg_bank_32) * 0x8000 + (addr & 0x7FFF);
            }
            return true;
        }
        return false;
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32, data: u8) bool {
        if (addr >= 0x6000 and addr <= 0x7FFF) {
            mapped_addr.* = 0xFFFFFFFF;
            self.ram[addr & 0x1FFF] = data;
            return true;
        }
        if (addr >= 0x8000) {
            if (data & 0x80 != 0) {
                self.load_register = 0;
                self.load_count = 0;
                self.control_register |= 0x0C;
            } else {
                self.load_register >>= 1;
                self.load_register |= (data & 0x01) << 4;
                self.load_count += 1;

                if (self.load_count == 5) {
                    const target: u8 = @intCast((addr >> 13) & 0x03);
                    switch (target) {
                        0 => {
                            self.control_register = self.load_register & 0x1F;
                            self.mirror_mode = switch (self.control_register & 0x03) {
                                0 => .onescreen_lo,
                                1 => .onescreen_hi,
                                2 => .vertical,
                                else => .horizontal,
                            };
                        },
                        1 => {
                            if (self.control_register & 0b10000 != 0) {
                                self.chr_bank_4lo = self.load_register & 0x1F;
                            } else {
                                self.chr_bank_8 = self.load_register & 0x1E;
                            }
                        },
                        2 => {
                            if (self.control_register & 0b10000 != 0) {
                                self.chr_bank_4hi = self.load_register & 0x1F;
                            }
                        },
                        else => {
                            const prg_mode = (self.control_register >> 2) & 0x03;
                            switch (prg_mode) {
                                0, 1 => self.prg_bank_32 = (self.load_register & 0x0E) >> 1,
                                2 => {
                                    self.prg_bank_16lo = 0;
                                    self.prg_bank_16hi = self.load_register & 0x0F;
                                },
                                else => {
                                    self.prg_bank_16lo = self.load_register & 0x0F;
                                    self.prg_bank_16hi = self.program_banks - 1;
                                },
                            }
                        },
                    }
                    self.load_register = 0;
                    self.load_count = 0;
                }
            }
        }
        return false;
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF) {
            if (self.char_banks == 0) {
                mapped_addr.* = addr;
                return true;
            }
            if (self.control_register & 0b10000 != 0) {
                if (addr <= 0x0FFF) {
                    mapped_addr.* = @as(u32, self.chr_bank_4lo) * 0x1000 + (addr & 0x0FFF);
                } else {
                    mapped_addr.* = @as(u32, self.chr_bank_4hi) * 0x1000 + (addr & 0x0FFF);
                }
            } else {
                mapped_addr.* = @as(u32, self.chr_bank_8) * 0x1000 + (addr & 0x1FFF);
            }
            return true;
        }
        return false;
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF and self.char_banks == 0) {
            mapped_addr.* = addr;
            return true;
        }
        return false;
    }
};

pub const Mapper002 = struct {
    program_banks: u8,
    char_banks: u8,
    prg_bank_lo: u8 = 0,

    pub fn init(program_banks: u8, char_banks: u8) @This() {
        return .{ .program_banks = program_banks, .char_banks = char_banks };
    }

    pub fn reset(self: *@This()) void {
        self.prg_bank_lo = 0;
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32, data: *u8) bool {
        _ = data;
        if (addr >= 0x8000 and addr <= 0xBFFF) {
            mapped_addr.* = @as(u32, self.prg_bank_lo) * 0x4000 + (addr & 0x3FFF);
            return true;
        }
        if (addr >= 0xC000) {
            mapped_addr.* = @as(u32, self.program_banks - 1) * 0x4000 + (addr & 0x3FFF);
            return true;
        }
        return false;
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32, data: u8) bool {
        _ = mapped_addr;
        if (addr >= 0x8000) {
            self.prg_bank_lo = data & 0x0F;
        }
        return false;
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        _ = self;
        if (addr <= 0x1FFF) {
            mapped_addr.* = addr;
            return true;
        }
        return false;
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF and self.char_banks == 0) {
            mapped_addr.* = addr;
            return true;
        }
        return false;
    }
};

pub const Mapper003 = struct {
    program_banks: u8,
    char_banks: u8,
    chr_bank: u8 = 0,

    pub fn init(program_banks: u8, char_banks: u8) @This() {
        return .{ .program_banks = program_banks, .char_banks = char_banks };
    }

    pub fn reset(self: *@This()) void {
        self.chr_bank = 0;
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32, data: *u8) bool {
        _ = data;
        if (addr >= 0x8000) {
            mapped_addr.* = addr & if (self.program_banks > 1) @as(u16, 0x7FFF) else @as(u16, 0x3FFF);
            return true;
        }
        return false;
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32, data: u8) bool {
        _ = mapped_addr;
        if (addr >= 0x8000) {
            self.chr_bank = data & 0x03;
        }
        return false;
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF) {
            mapped_addr.* = @as(u32, self.chr_bank) * 0x2000 + addr;
            return true;
        }
        return false;
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        _ = self;
        _ = addr;
        _ = mapped_addr;
        return false;
    }
};

pub const Mapper004 = struct {
    program_banks: u8,
    char_banks: u8,
    target_register: u8 = 0,
    prg_bank_mode: bool = false,
    chr_inversion: bool = false,
    mirror_mode: Mirror = .horizontal,
    register: [8]u32 = @splat(0),
    chr_bank: [8]u32 = @splat(0),
    prg_bank: [4]u32 = @splat(0),
    irq_active: bool = false,
    irq_enable: bool = false,
    irq_counter: u16 = 0,
    irq_reload: u16 = 0,
    ram: [8 * 1024]u8 = @splat(0),

    pub fn init(program_banks: u8, char_banks: u8) @This() {
        var m = @This(){ .program_banks = program_banks, .char_banks = char_banks };
        m.reset();
        return m;
    }

    pub fn reset(self: *@This()) void {
        self.target_register = 0;
        self.prg_bank_mode = false;
        self.chr_inversion = false;
        self.mirror_mode = .horizontal;
        self.irq_active = false;
        self.irq_enable = false;
        self.irq_counter = 0;
        self.irq_reload = 0;
        self.register = @splat(0);
        self.chr_bank = @splat(0);
        self.prg_bank[0] = 0;
        self.prg_bank[1] = 0x2000;
        self.prg_bank[2] = (@as(u32, self.program_banks) * 2 - 2) * 0x2000;
        self.prg_bank[3] = (@as(u32, self.program_banks) * 2 - 1) * 0x2000;
    }

    pub fn mirror(self: *@This()) ?Mirror {
        return self.mirror_mode;
    }

    pub fn irqState(self: *@This()) bool {
        return self.irq_active;
    }

    pub fn irqClear(self: *@This()) void {
        self.irq_active = false;
    }

    pub fn scanline(self: *@This()) void {
        if (self.irq_counter == 0) {
            self.irq_counter = self.irq_reload;
        } else {
            self.irq_counter -= 1;
        }
        if (self.irq_counter == 0 and self.irq_enable) {
            self.irq_active = true;
        }
    }

    fn updateBanks(self: *@This()) void {
        if (self.chr_inversion) {
            self.chr_bank[0] = self.register[2] * 0x0400;
            self.chr_bank[1] = self.register[3] * 0x0400;
            self.chr_bank[2] = self.register[4] * 0x0400;
            self.chr_bank[3] = self.register[5] * 0x0400;
            self.chr_bank[4] = (self.register[0] & 0xFE) * 0x0400;
            self.chr_bank[5] = (self.register[0] | 0x01) * 0x0400;
            self.chr_bank[6] = (self.register[1] & 0xFE) * 0x0400;
            self.chr_bank[7] = (self.register[1] | 0x01) * 0x0400;
        } else {
            self.chr_bank[0] = (self.register[0] & 0xFE) * 0x0400;
            self.chr_bank[1] = (self.register[0] | 0x01) * 0x0400;
            self.chr_bank[2] = (self.register[1] & 0xFE) * 0x0400;
            self.chr_bank[3] = (self.register[1] | 0x01) * 0x0400;
            self.chr_bank[4] = self.register[2] * 0x0400;
            self.chr_bank[5] = self.register[3] * 0x0400;
            self.chr_bank[6] = self.register[4] * 0x0400;
            self.chr_bank[7] = self.register[5] * 0x0400;
        }

        if (self.prg_bank_mode) {
            self.prg_bank[2] = (self.register[6] & 0x3F) * 0x2000;
            self.prg_bank[0] = (@as(u32, self.program_banks) * 2 - 2) * 0x2000;
        } else {
            self.prg_bank[0] = (self.register[6] & 0x3F) * 0x2000;
            self.prg_bank[2] = (@as(u32, self.program_banks) * 2 - 2) * 0x2000;
        }
        self.prg_bank[1] = (self.register[7] & 0x3F) * 0x2000;
        self.prg_bank[3] = (@as(u32, self.program_banks) * 2 - 1) * 0x2000;
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32, data: *u8) bool {
        if (addr >= 0x6000 and addr <= 0x7FFF) {
            mapped_addr.* = 0xFFFFFFFF;
            data.* = self.ram[addr & 0x1FFF];
            return true;
        }
        if (addr >= 0x8000) {
            const bank = (addr - 0x8000) / 0x2000;
            mapped_addr.* = self.prg_bank[bank] + (addr & 0x1FFF);
            return true;
        }
        return false;
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32, data: u8) bool {
        if (addr >= 0x6000 and addr <= 0x7FFF) {
            mapped_addr.* = 0xFFFFFFFF;
            self.ram[addr & 0x1FFF] = data;
            return true;
        }
        if (addr >= 0x8000 and addr <= 0x9FFF) {
            if (addr & 0x0001 == 0) {
                self.target_register = data & 0x07;
                self.prg_bank_mode = data & 0x40 != 0;
                self.chr_inversion = data & 0x80 != 0;
            } else {
                self.register[self.target_register] = data;
                self.updateBanks();
            }
        } else if (addr >= 0xA000 and addr <= 0xBFFF) {
            if (addr & 0x0001 == 0) {
                self.mirror_mode = if (data & 0x01 != 0) .horizontal else .vertical;
            }
        } else if (addr >= 0xC000 and addr <= 0xDFFF) {
            if (addr & 0x0001 == 0) {
                self.irq_reload = data;
            } else {
                self.irq_counter = 0;
            }
        } else if (addr >= 0xE000) {
            if (addr & 0x0001 == 0) {
                self.irq_enable = false;
                self.irq_active = false;
            } else {
                self.irq_enable = true;
            }
        }
        return false;
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF) {
            mapped_addr.* = self.chr_bank[addr / 0x0400] + (addr & 0x03FF);
            return true;
        }
        return false;
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF and self.char_banks == 0) {
            mapped_addr.* = addr;
            return true;
        }
        return false;
    }
};

pub const Mapper066 = struct {
    program_banks: u8,
    char_banks: u8,
    prg_bank: u8 = 0,
    chr_bank: u8 = 0,

    pub fn init(program_banks: u8, char_banks: u8) @This() {
        return .{ .program_banks = program_banks, .char_banks = char_banks };
    }

    pub fn reset(self: *@This()) void {
        self.prg_bank = 0;
        self.chr_bank = 0;
    }

    pub fn cpuMapRead(self: *@This(), addr: u16, mapped_addr: *u32, data: *u8) bool {
        _ = data;
        if (addr >= 0x8000) {
            mapped_addr.* = @as(u32, self.prg_bank) * 0x8000 + (addr & 0x7FFF);
            return true;
        }
        return false;
    }

    pub fn cpuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32, data: u8) bool {
        _ = mapped_addr;
        if (addr >= 0x8000) {
            self.chr_bank = data & 0x03;
            self.prg_bank = (data & 0x30) >> 4;
        }
        return false;
    }

    pub fn ppuMapRead(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        if (addr <= 0x1FFF) {
            mapped_addr.* = @as(u32, self.chr_bank) * 0x2000 + addr;
            return true;
        }
        return false;
    }

    pub fn ppuMapWrite(self: *@This(), addr: u16, mapped_addr: *u32) bool {
        _ = self;
        _ = addr;
        _ = mapped_addr;
        return false;
    }
};

const olc6502 = @import("cpu.zig").olc6502;
const olc2C02 = @import("ppu.zig").olc2C02;
const olc2A03 = @import("apu.zig").olc2A03;
const Cartridge = @import("cartridge.zig").Cartridge;
const blip = @import("blip");

pub const Region = enum {
    ntsc,
    pal,

    pub fn cpuClockHz(self: Region) f64 {
        return switch (self) {
            .ntsc => 1789773.0,
            .pal => 1662607.0,
        };
    }
    pub fn cpuDivider(self: Region) u32 {
        return switch (self) {
            .ntsc => 12,
            .pal => 16,
        };
    }
    pub fn ppuDivider(self: Region) u32 {
        return switch (self) {
            .ntsc => 4,
            .pal => 5,
        };
    }
    pub fn scanlinesPerFrame(self: Region) i16 {
        return switch (self) {
            .ntsc => 261,
            .pal => 311,
        };
    }
    pub fn frameSeq(self: Region) [4]u32 {
        return switch (self) {
            .ntsc => .{ 3729, 7457, 11186, 14915 },
            .pal => .{ 4156, 8313, 12469, 16627 },
        };
    }
    pub fn noisePeriods(self: Region) [16]u16 {
        return switch (self) {
            .ntsc => .{ 4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068 },
            .pal => .{ 4, 8, 14, 30, 60, 88, 118, 148, 188, 236, 354, 472, 708, 944, 1890, 3778 },
        };
    }
    pub fn fps(self: Region) u32 {
        return switch (self) {
            .ntsc => 60,
            .pal => 50,
        };
    }
};

pub const Bus = struct {
    cpu: olc6502,
    ppu: olc2C02,
    apu: ?olc2A03,
    cpuRam: [2 * 1024]u8 = @splat(0),
    cartridge: *Cartridge = undefined,

    controller: [2]u8 = .{ 0, 0 },
    controller_state: [2]u8 = .{ 0, 0 },

    dma_page: u8 = 0x00,
    dma_addr: u8 = 0x00,
    dma_data: u8 = 0x00,

    dma_dummy: bool = true,
    dma_transfer: bool = false,

    blip_buf: ?*blip.blip_t = null,
    last_amp: i32 = 0,
    apu_clock: u32 = 0,

    region: Region,
    master_clock: u32 = 0,

    pub fn init(region: Region, mute: bool) @This() {
        return @This(){
            .cpu = olc6502.init(),
            .ppu = olc2C02.init(region),
            .apu = if (mute) null else olc2A03.init(region),
            .region = region,
        };
    }

    pub fn initAudio(self: *@This(), out_rate: u32) void {
        self.blip_buf = blip.blip_new(@intCast(out_rate));
        blip.blip_set_rates(self.blip_buf, self.region.cpuClockHz(), @floatFromInt(out_rate));
    }

    pub fn deinitAudio(self: *@This()) void {
        blip.blip_delete(self.blip_buf);
        self.blip_buf = null;
    }

    pub fn cpuWrite(self: *@This(), addr: u16, data: u8) void {
        if (self.cartridge.cpuWrite(addr, data)) {} else if (addr >= 0x0000 and addr <= 0x1FFF) {
            self.cpuRam[addr & 0x07FF] = data;
        } else if (addr >= 0x2000 and addr <= 0x3FFF) {
            self.ppu.cpuWrite(addr & 0x0007, data);
        } else if (((addr >= 0x4000 and addr <= 0x4013) or addr == 0x4015 or addr == 0x4017) and self.apu != null) {
            self.apu.?.cpuWrite(addr, data);
        } else if (addr == 0x4014) {
            self.dma_page = data;
            self.dma_addr = 0x00;
            self.dma_transfer = true;
        } else if (addr >= 0x4016 and addr <= 0x4017) {
            self.controller_state[addr - 0x4016] = self.controller[addr - 0x4016];
        }
    }

    pub fn cpuRead(self: *@This(), addr: u16, read_only: bool) u8 {
        var data: u8 = 0x00;

        if (self.cartridge.cpuRead(addr, &data)) {} else if (addr >= 0x0000 and addr <= 0x1FFF) {
            return self.cpuRam[addr & 0x07FF];
        } else if (addr >= 0x2000 and addr <= 0x3FFF) {
            return self.ppu.cpuRead(addr & 0x0007, read_only);
        } else if (addr == 0x4015 and self.apu != null) {
            return self.apu.?.cpuRead(addr);
        } else if (addr >= 0x4016 and addr <= 0x4017) {
            data = if (self.controller_state[addr - 0x4016] & 0x80 != 0) 1 else 0;
            self.controller_state[addr - 0x4016] <<= 1;
        }

        return data;
    }

    pub fn loadCartridge(self: *@This(), cartridge: *Cartridge) void {
        self.cartridge = cartridge;
        self.ppu.connectCartridge(cartridge);
    }

    pub fn reset(self: *@This()) void {
        self.cpu.reset();
        self.ppu.reset();
        self.master_clock = 0;
    }

    pub fn clock(self: *@This()) void {
        @setRuntimeSafety(false);
        const cpu_div = self.region.cpuDivider();
        const ppu_div = self.region.ppuDivider();

        if (self.master_clock % ppu_div == 0) self.ppu.clock();

        if (self.master_clock % cpu_div == 0) {
            if (self.apu != null) self.apu.?.clock();

            if (self.dma_transfer) {
                if (self.dma_dummy) {
                    if (self.master_clock / cpu_div % 2 == 1) {
                        self.dma_dummy = false;
                    }
                } else {
                    if (self.master_clock / cpu_div % 2 == 0) {
                        self.dma_data = self.cpuRead(@as(u16, self.dma_page) << 8 | self.dma_addr, false);
                    } else {
                        self.ppu.oamBytes()[self.dma_addr] = self.dma_data;
                        self.dma_addr +%= 1;
                        if (self.dma_addr == 0x00) {
                            self.dma_transfer = false;
                            self.dma_dummy = true;
                        }
                    }
                }
            } else {
                self.cpu.clock();
            }

            if (self.ppu.nmi and self.cpu.cycles == 0) {
                self.ppu.nmi = false;
                self.cpu.nmi();
            }

            if (self.cartridge.mapper.irqState() and self.cpu.cycles == 0 and self.cpu.getFlag(.I) == 0) {
                self.cartridge.mapper.irqClear();
                self.cpu.irq();
            }

            if (self.apu != null) {
                const amp = self.apu.?.outputLevel();
                if (amp != self.last_amp) {
                    blip.blip_add_delta(self.blip_buf, self.apu_clock, amp - self.last_amp);
                    self.last_amp = amp;
                }
                self.apu_clock += 1;
            }
        }

        self.master_clock +%= 1;
        if (self.master_clock % (cpu_div * ppu_div) == 0) self.master_clock = 0;
    }

    pub fn endAudioFrame(self: *@This()) void {
        if (self.apu != null) {
            blip.blip_end_frame(self.blip_buf, self.apu_clock);
            self.apu_clock = 0;
        }
    }
};

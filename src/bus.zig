const olc6502 = @import("cpu.zig").olc6502;
const olc2C02 = @import("ppu.zig").olc2C02;
const Cartridge = @import("cartridge.zig").Cartridge;

pub const Bus = struct {
    cpu: olc6502,
    ppu: olc2C02,
    cpuRam: [2 * 1024]u8 = @splat(0),
    cartridge: *Cartridge = undefined,

    controller: [2]u8 = .{ 0, 0 },
    controller_state: [2]u8 = .{ 0, 0 },

    system_clock_counter: u32 = 0,

    dma_page: u8 = 0x00,
    dma_addr: u8 = 0x00,
    dma_data: u8 = 0x00,

    dma_dummy: bool = true,
    dma_transfer: bool = false,

    pub fn init() @This() {
        return @This(){
            .cpu = olc6502.init(),
            .ppu = olc2C02.init(),
        };
    }

    pub fn cpuWrite(self: *@This(), addr: u16, data: u8) void {
        if (self.cartridge.cpuWrite(addr, data)) {
            // Nothing just veto
        } else if (addr >= 0x0000 and addr <= 0x1FFF) {
            self.cpuRam[addr & 0x07FF] = data;
        } else if (addr >= 0x2000 and addr <= 0x3FFF) {
            self.ppu.cpuWrite(addr & 0x0007, data);
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

        if (self.cartridge.cpuRead(addr, &data)) {
            // Nothing just veto
        } else if (addr >= 0x0000 and addr <= 0x1FFF) {
            return self.cpuRam[addr & 0x07FF];
        } else if (addr >= 0x2000 and addr <= 0x3FFF) {
            return self.ppu.cpuRead(addr & 0x0007, read_only);
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
        self.system_clock_counter = 0;
    }

    pub fn clock(self: *@This()) void {
        self.ppu.clock();
        if (self.system_clock_counter % 3 == 0) {
            if (self.dma_transfer) {
                if (self.dma_dummy) {
                    if (self.system_clock_counter % 2 == 1) {
                        self.dma_dummy = false;
                    }
                } else {
                    if (self.system_clock_counter % 2 == 0) {
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
        }
        self.system_clock_counter += 1;
    }
};

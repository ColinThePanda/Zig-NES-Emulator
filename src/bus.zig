const olc6502 = @import("cpu.zig").olc6502;
const olc2C02 = @import("ppu.zig").olc2C02;
const Cartridge = @import("cartridge.zig").Cartridge;

pub const Bus = struct {
    cpu: olc6502,
    ppu: olc2C02,
    cpuRam: [2 * 1024]u8 = @splat(0),
    cartridge: *Cartridge = undefined,

    system_clock_counter: u32 = 0,

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
            self.cpuRam[addr] = data;
        } else if (addr >= 0x2000 and addr <= 0x3FFF) {
            self.ppu.cpuWrite(addr & 0x0007, data);
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
        }

        return data;
    }

    pub fn loadCartridge(self: *@This(), cartridge: *Cartridge) void {
        self.cartridge = cartridge;
        self.ppu.connectCartridge(cartridge);
    }

    pub fn reset(self: *@This()) void {
        self.system_clock_counter = 0;
        self.cpu.reset();
    }

    pub fn clock(self: *@This()) void {
        self.ppu.clock();
        if (self.system_clock_counter % 3 == 0) {
            self.cpu.clock();
        }
        self.system_clock_counter += 1;
    }
};

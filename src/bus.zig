const olc6502 = @import("cpu.zig").olc6502;

pub const Bus = struct {
    cpu: olc6502,
    ram: [64 * 1024]u8 = @splat(0),

    pub fn init() @This() {
        return @This(){
            .cpu = olc6502.init(),
        };
    }

    pub fn write(self: *@This(), addr: u16, data: u8) void {
        if (addr >= 0x0000 and addr <= 0xFFFF)
            self.ram[addr] = data;
    }

    pub fn read(self: *@This(), addr: u16, read_only: bool) u8 {
        _ = read_only;
        if (addr >= 0x0000 and addr <= 0xFFFF)
            return self.ram[addr];

        return 0;
    }
};

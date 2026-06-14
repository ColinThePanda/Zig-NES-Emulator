const std = @import("std");
const Region = @import("bus.zig").Region;

const length_table_2A03 = [32]u8{
    10, 254, 20, 2,  40, 4,  80, 6,  160, 8,  60, 10, 14, 12, 26, 14,
    12, 16,  24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30,
};

const noise_period_table = [16]u16{ 4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068 };

const duty_table = [4][8]u1{
    .{ 0, 1, 0, 0, 0, 0, 0, 0 },
    .{ 0, 1, 1, 0, 0, 0, 0, 0 },
    .{ 0, 1, 1, 1, 1, 0, 0, 0 },
    .{ 1, 0, 0, 1, 1, 1, 1, 1 },
};

const tri_sequence = [32]u8{
    15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5,  4,  3,  2,  1,  0,
    0,  1,  2,  3,  4,  5,  6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
};

const LengthCounter = struct {
    counter: u8 = 0x00,

    fn clock(self: *LengthCounter, enable: bool, halt: bool) void {
        if (!enable) {
            self.counter = 0;
        } else if (self.counter > 0 and !halt) {
            self.counter -= 1;
        }
    }
};

const Envelope = struct {
    start: bool = false,
    disable: bool = false,
    divider_count: u16 = 0,
    volume: u16 = 0,
    output: u16 = 0,
    decay_count: u16 = 0,

    fn clock(self: *Envelope, loop: bool) void {
        if (!self.start) {
            if (self.divider_count == 0) {
                self.divider_count = self.volume + 1;
                if (self.decay_count == 0) {
                    if (loop) self.decay_count = 15;
                } else {
                    self.decay_count -= 1;
                }
            } else {
                self.divider_count -= 1;
            }
        } else {
            self.start = false;
            self.decay_count = 15;
            self.divider_count = self.volume + 1;
        }

        self.output = if (self.disable) self.volume else self.decay_count;
    }
};

const Pulse = struct {
    enable: bool = false,
    halt: bool = false,
    duty: u2 = 0,
    step: u3 = 0,
    timer: u16 = 0,
    reload: u16 = 0,
    env: Envelope = .{},
    lc: LengthCounter = .{},
    sweep_enabled: bool = false,
    sweep_negate: bool = false,
    sweep_reload: bool = false,
    sweep_shift: u3 = 0,
    sweep_period: u8 = 0,
    sweep_divider: u8 = 0,

    fn sweepTarget(self: *Pulse, ones_complement: bool) i32 {
        const change: i32 = self.reload >> self.sweep_shift;
        if (self.sweep_negate) return @as(i32, self.reload) - change - @intFromBool(ones_complement);
        return @as(i32, self.reload) + change;
    }

    fn muted(self: *Pulse, ones_complement: bool) bool {
        return self.reload < 8 or self.sweepTarget(ones_complement) > 0x7FF;
    }

    fn clockTimer(self: *Pulse) void {
        if (self.timer == 0) {
            self.timer = self.reload;
            self.step +%= 1;
        } else {
            self.timer -= 1;
        }
    }

    fn clockSweep(self: *Pulse, ones_complement: bool) void {
        if (self.sweep_divider == 0 and self.sweep_enabled and self.sweep_shift > 0 and !self.muted(ones_complement)) {
            const t = self.sweepTarget(ones_complement);
            if (t >= 0) self.reload = @intCast(t);
        }
        if (self.sweep_divider == 0 or self.sweep_reload) {
            self.sweep_divider = self.sweep_period;
            self.sweep_reload = false;
        } else {
            self.sweep_divider -= 1;
        }
    }

    fn output(self: *Pulse, ones_complement: bool) u32 {
        if (!self.enable or self.lc.counter == 0 or self.muted(ones_complement)) return 0;
        if (duty_table[self.duty][self.step] == 0) return 0;
        return self.env.output;
    }
};

const Noise = struct {
    enable: bool = false,
    halt: bool = false,
    mode: bool = false,
    timer: u16 = 0,
    reload: u16 = 0,
    shift: u16 = 1,
    env: Envelope = .{},
    lc: LengthCounter = .{},

    fn clockTimer(self: *Noise) void {
        if (self.timer == 0) {
            self.timer = self.reload;
            const tap: u16 = if (self.mode) (self.shift >> 6) & 1 else (self.shift >> 1) & 1;
            const feedback: u16 = (self.shift & 1) ^ tap;
            self.shift = (self.shift >> 1) | (feedback << 14);
        } else {
            self.timer -= 1;
        }
    }

    fn output(self: *Noise) u32 {
        if (!self.enable or self.lc.counter == 0 or (self.shift & 1) != 0) return 0;
        return self.env.output;
    }
};

pub const olc2A03 = struct {
    frame_clock_counter: u32 = 0,
    clock_counter: u32 = 0,

    pulse1: Pulse = .{},
    pulse2: Pulse = .{},
    noise: Noise = .{},

    tri_enable: bool = false,
    tri_control: bool = false,
    tri_timer: u16 = 0,
    tri_reload: u16 = 0,
    tri_step: u5 = 0,
    tri_linear_counter: u8 = 0,
    tri_linear_reload: u8 = 0,
    tri_linear_reload_flag: bool = false,
    tri_lc: LengthCounter = .{},

    five_step: bool = false,

    region: Region,

    pub fn init(region: Region) @This() {
        return @This(){
            .region = region,
        };
    }

    fn clockQuarter(self: *@This()) void {
        self.pulse1.env.clock(self.pulse1.halt);
        self.pulse2.env.clock(self.pulse2.halt);
        self.noise.env.clock(self.noise.halt);
        if (self.tri_linear_reload_flag) {
            self.tri_linear_counter = self.tri_linear_reload;
        } else if (self.tri_linear_counter > 0) {
            self.tri_linear_counter -= 1;
        }
        if (!self.tri_control) self.tri_linear_reload_flag = false;
    }

    fn clockHalf(self: *@This()) void {
        self.pulse1.lc.clock(self.pulse1.enable, self.pulse1.halt);
        self.pulse2.lc.clock(self.pulse2.enable, self.pulse2.halt);
        self.noise.lc.clock(self.noise.enable, self.noise.halt);
        self.tri_lc.clock(self.tri_enable, self.tri_control);
        self.pulse1.clockSweep(true);
        self.pulse2.clockSweep(false);
    }

    pub fn cpuWrite(self: *@This(), addr: u16, data: u8) void {
        switch (addr) {
            0x4000 => {
                self.pulse1.duty = @truncate((data & 0xC0) >> 6);
                self.pulse1.halt = data & 0x20 != 0;
                self.pulse1.env.volume = data & 0x0F;
                self.pulse1.env.disable = data & 0x10 != 0;
            },
            0x4001 => {
                self.pulse1.sweep_enabled = data & 0x80 != 0;
                self.pulse1.sweep_period = (data & 0x70) >> 4;
                self.pulse1.sweep_negate = data & 0x08 != 0;
                self.pulse1.sweep_shift = @truncate(data & 0x07);
                self.pulse1.sweep_reload = true;
            },
            0x4002 => self.pulse1.reload = (self.pulse1.reload & 0xFF00) | data,
            0x4003 => {
                self.pulse1.reload = @as(u16, data & 0x07) << 8 | (self.pulse1.reload & 0x00FF);
                self.pulse1.lc.counter = length_table_2A03[(data & 0xF8) >> 3];
                self.pulse1.step = 0;
                self.pulse1.env.start = true;
            },
            0x4004 => {
                self.pulse2.duty = @truncate((data & 0xC0) >> 6);
                self.pulse2.halt = data & 0x20 != 0;
                self.pulse2.env.volume = data & 0x0F;
                self.pulse2.env.disable = data & 0x10 != 0;
            },
            0x4005 => {
                self.pulse2.sweep_enabled = data & 0x80 != 0;
                self.pulse2.sweep_period = (data & 0x70) >> 4;
                self.pulse2.sweep_negate = data & 0x08 != 0;
                self.pulse2.sweep_shift = @truncate(data & 0x07);
                self.pulse2.sweep_reload = true;
            },
            0x4006 => self.pulse2.reload = (self.pulse2.reload & 0xFF00) | data,
            0x4007 => {
                self.pulse2.reload = @as(u16, data & 0x07) << 8 | (self.pulse2.reload & 0x00FF);
                self.pulse2.lc.counter = length_table_2A03[(data & 0xF8) >> 3];
                self.pulse2.step = 0;
                self.pulse2.env.start = true;
            },
            0x4008 => {
                self.tri_control = data & 0x80 != 0;
                self.tri_linear_reload = data & 0x7F;
            },
            0x400A => self.tri_reload = (self.tri_reload & 0xFF00) | data,
            0x400B => {
                self.tri_reload = @as(u16, data & 0x07) << 8 | (self.tri_reload & 0x00FF);
                self.tri_timer = self.tri_reload;
                self.tri_lc.counter = length_table_2A03[(data & 0xF8) >> 3];
                self.tri_linear_reload_flag = true;
            },
            0x400C => {
                self.noise.env.volume = data & 0x0F;
                self.noise.env.disable = data & 0x10 != 0;
                self.noise.halt = data & 0x20 != 0;
            },
            0x400E => {
                self.noise.mode = data & 0x80 != 0;
                self.noise.reload = self.region.noisePeriods()[data & 0x0F];
            },
            0x400F => {
                self.noise.env.start = true;
                self.noise.lc.counter = length_table_2A03[(data & 0xF8) >> 3];
            },
            0x4015 => {
                self.pulse1.enable = data & 0x01 != 0;
                self.pulse2.enable = data & 0x02 != 0;
                self.tri_enable = data & 0x04 != 0;
                self.noise.enable = data & 0x08 != 0;
                if (!self.pulse1.enable) self.pulse1.lc.counter = 0;
                if (!self.pulse2.enable) self.pulse2.lc.counter = 0;
                if (!self.tri_enable) self.tri_lc.counter = 0;
                if (!self.noise.enable) self.noise.lc.counter = 0;
            },
            0x4017 => {
                self.five_step = data & 0x80 != 0;
                self.frame_clock_counter = 0;
                if (self.five_step) {
                    self.clockQuarter();
                    self.clockHalf();
                }
            },
            else => {},
        }
    }

    pub fn cpuRead(self: *@This(), addr: u16) u8 {
        var data: u8 = 0x00;
        if (addr == 0x4015) {
            if (self.pulse1.lc.counter > 0) data |= 0x01;
            if (self.pulse2.lc.counter > 0) data |= 0x02;
            if (self.tri_lc.counter > 0) data |= 0x04;
            if (self.noise.lc.counter > 0) data |= 0x08;
        }
        return data;
    }

    pub fn clock(self: *@This()) void {
        var quarter_frame_clock = false;
        var half_frame_clock = false;

        if (self.clock_counter % 2 == 0) {
            self.frame_clock_counter += 1;

            if (!self.five_step) {
                const seq = self.region.frameSeq();
                if (self.frame_clock_counter == seq[0] or self.frame_clock_counter == seq[2]) quarter_frame_clock = true;
                if (self.frame_clock_counter == seq[1]) {
                    quarter_frame_clock = true;
                    half_frame_clock = true;
                }
                if (self.frame_clock_counter == seq[3]) {
                    quarter_frame_clock = true;
                    half_frame_clock = true;
                    self.frame_clock_counter = 0;
                }
            } else {
                if (self.frame_clock_counter == 3729 or self.frame_clock_counter == 11186) quarter_frame_clock = true;
                if (self.frame_clock_counter == 7457) {
                    quarter_frame_clock = true;
                    half_frame_clock = true;
                }
                if (self.frame_clock_counter == 18641) {
                    quarter_frame_clock = true;
                    half_frame_clock = true;
                    self.frame_clock_counter = 0;
                }
            }

            if (quarter_frame_clock) self.clockQuarter();
            if (half_frame_clock) self.clockHalf();

            self.pulse1.clockTimer();
            self.pulse2.clockTimer();
        }

        if (self.tri_linear_counter > 0 and self.tri_lc.counter > 0 and self.tri_reload >= 2) {
            self.tri_timer -%= 1;
            if (self.tri_timer == 0xFFFF) {
                self.tri_timer = self.tri_reload;
                self.tri_step +%= 1;
            }
        }
        self.noise.clockTimer();

        self.clock_counter += 1;
    }

    pub fn outputLevel(self: *@This()) i32 {
        const p1: f64 = @floatFromInt(self.pulse1.output(true));
        const p2: f64 = @floatFromInt(self.pulse2.output(false));
        const tri: f64 = @floatFromInt(tri_sequence[self.tri_step]);
        const noi: f64 = @floatFromInt(self.noise.output());
        const pulse_in = p1 + p2;
        const pulse_out: f64 = if (pulse_in > 0) 95.88 / (8128.0 / pulse_in + 100.0) else 0;
        const tnd_in = tri / 8227.0 + noi / 12241.0;
        const tnd_out: f64 = if (tnd_in > 0) 159.79 / (1.0 / tnd_in + 100.0) else 0;
        return @intFromFloat((pulse_out + tnd_out) * 30000.0);
    }
};

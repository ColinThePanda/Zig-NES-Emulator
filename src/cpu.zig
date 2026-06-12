const std = @import("std");
const Bus = @import("bus.zig").Bus;

pub const Flags6502 = enum(u8) {
    C = 1 << 0,
    Z = 1 << 1,
    I = 1 << 2,
    D = 1 << 3,
    B = 1 << 4,
    U = 1 << 5,
    V = 1 << 6,
    N = 1 << 7,
};

pub const AddressMode6502 = enum {
    IMP,
    IMM,
    ZP0,
    ZPX,
    ZPY,
    REL,
    ABS,
    ABX,
    ABY,
    IND,
    IZX,
    IZY,
};

pub const Opcode6502 = enum {
    ADC,
    AND,
    ASL,
    BCC,
    BCS,
    BEQ,
    BIT,
    BMI,
    BNE,
    BPL,
    BRK,
    BVC,
    BVS,
    CLC,
    CLD,
    CLI,
    CLV,
    CMP,
    CPX,
    CPY,
    DEC,
    DEX,
    DEY,
    EOR,
    INC,
    INX,
    INY,
    JMP,
    JSR,
    LDA,
    LDX,
    LDY,
    LSR,
    NOP,
    ORA,
    PHA,
    PHP,
    PLA,
    PLP,
    ROL,
    ROR,
    RTI,
    RTS,
    SBC,
    SEC,
    SED,
    SEI,
    STA,
    STX,
    STY,
    TAX,
    TAY,
    TSX,
    TXA,
    TXS,
    TYA,
    XXX,
};

pub fn addressModePtr(mode: AddressMode6502) *const fn (*olc6502) u8 {
    return switch (mode) {
        .IMP => &olc6502.IMP,
        .IMM => &olc6502.IMM,
        .ZP0 => &olc6502.ZP0,
        .ZPX => &olc6502.ZPX,
        .ZPY => &olc6502.ZPY,
        .REL => &olc6502.REL,
        .ABS => &olc6502.ABS,
        .ABX => &olc6502.ABX,
        .ABY => &olc6502.ABY,
        .IND => &olc6502.IND,
        .IZX => &olc6502.IZX,
        .IZY => &olc6502.IZY,
    };
}

pub fn opcodePtr(op: Opcode6502) *const fn (*olc6502) u8 {
    return switch (op) {
        .ADC => &olc6502.ADC,
        .AND => &olc6502.AND,
        .ASL => &olc6502.ASL,
        .BCC => &olc6502.BCC,
        .BCS => &olc6502.BCS,
        .BEQ => &olc6502.BEQ,
        .BIT => &olc6502.BIT,
        .BMI => &olc6502.BMI,
        .BNE => &olc6502.BNE,
        .BPL => &olc6502.BPL,
        .BRK => &olc6502.BRK,
        .BVC => &olc6502.BVC,
        .BVS => &olc6502.BVS,
        .CLC => &olc6502.CLC,
        .CLD => &olc6502.CLD,
        .CLI => &olc6502.CLI,
        .CLV => &olc6502.CLV,
        .CMP => &olc6502.CMP,
        .CPX => &olc6502.CPX,
        .CPY => &olc6502.CPY,
        .DEC => &olc6502.DEC,
        .DEX => &olc6502.DEX,
        .DEY => &olc6502.DEY,
        .EOR => &olc6502.EOR,
        .INC => &olc6502.INC,
        .INX => &olc6502.INX,
        .INY => &olc6502.INY,
        .JMP => &olc6502.JMP,
        .JSR => &olc6502.JSR,
        .LDA => &olc6502.LDA,
        .LDX => &olc6502.LDX,
        .LDY => &olc6502.LDY,
        .LSR => &olc6502.LSR,
        .NOP => &olc6502.NOP,
        .ORA => &olc6502.ORA,
        .PHA => &olc6502.PHA,
        .PHP => &olc6502.PHP,
        .PLA => &olc6502.PLA,
        .PLP => &olc6502.PLP,
        .ROL => &olc6502.ROL,
        .ROR => &olc6502.ROR,
        .RTI => &olc6502.RTI,
        .RTS => &olc6502.RTS,
        .SBC => &olc6502.SBC,
        .SEC => &olc6502.SEC,
        .SED => &olc6502.SED,
        .SEI => &olc6502.SEI,
        .STA => &olc6502.STA,
        .STX => &olc6502.STX,
        .STY => &olc6502.STY,
        .TAX => &olc6502.TAX,
        .TAY => &olc6502.TAY,
        .TSX => &olc6502.TSX,
        .TXA => &olc6502.TXA,
        .TXS => &olc6502.TXS,
        .TYA => &olc6502.TYA,
        .XXX => &olc6502.XXX,
    };
}

pub const Instruction = struct { opcode: Opcode6502, address_mode: AddressMode6502, cycles: u8 };

pub const opcode_lookup6502: [256]Instruction = .{
    .{ .opcode = Opcode6502.BRK, .address_mode = AddressMode6502.IMM, .cycles = 7 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 3 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.ASL, .address_mode = AddressMode6502.ZP0, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.PHP, .address_mode = AddressMode6502.IMP, .cycles = 3 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.ASL, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.ASL, .address_mode = AddressMode6502.ABS, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 },
    .{ .opcode = Opcode6502.BPL, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.IZY, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.ASL, .address_mode = AddressMode6502.ZPX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.CLC, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.ORA, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.ASL, .address_mode = AddressMode6502.ABX, .cycles = 7 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 },
    .{ .opcode = Opcode6502.JSR, .address_mode = AddressMode6502.ABS, .cycles = 6 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.BIT, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.ROL, .address_mode = AddressMode6502.ZP0, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.PLP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.ROL, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.BIT, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.ROL, .address_mode = AddressMode6502.ABS, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 },
    .{ .opcode = Opcode6502.BMI, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.IZY, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.ROL, .address_mode = AddressMode6502.ZPX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.SEC, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.AND, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.ROL, .address_mode = AddressMode6502.ABX, .cycles = 7 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 },
    .{ .opcode = Opcode6502.RTI, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 3 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.LSR, .address_mode = AddressMode6502.ZP0, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.PHA, .address_mode = AddressMode6502.IMP, .cycles = 3 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.LSR, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.JMP, .address_mode = AddressMode6502.ABS, .cycles = 3 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.LSR, .address_mode = AddressMode6502.ABS, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 },
    .{ .opcode = Opcode6502.BVC, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.IZY, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.LSR, .address_mode = AddressMode6502.ZPX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.CLI, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.EOR, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.LSR, .address_mode = AddressMode6502.ABX, .cycles = 7 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 },
    .{ .opcode = Opcode6502.RTS, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 3 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.ROR, .address_mode = AddressMode6502.ZP0, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.PLA, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.ROR, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.JMP, .address_mode = AddressMode6502.IND, .cycles = 5 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.ROR, .address_mode = AddressMode6502.ABS, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 },
    .{ .opcode = Opcode6502.BVS, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.IZY, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.ROR, .address_mode = AddressMode6502.ZPX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.SEI, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.ADC, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.ROR, .address_mode = AddressMode6502.ABX, .cycles = 7 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 },
    .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.STA, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.STY, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.STA, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.STX, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 3 }, .{ .opcode = Opcode6502.DEY, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.TXA, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.STY, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.STA, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.STX, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 4 },
    .{ .opcode = Opcode6502.BCC, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.STA, .address_mode = AddressMode6502.IZY, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.STY, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.STA, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.STX, .address_mode = AddressMode6502.ZPY, .cycles = 4 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.TYA, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.STA, .address_mode = AddressMode6502.ABY, .cycles = 5 }, .{ .opcode = Opcode6502.TXS, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.STA, .address_mode = AddressMode6502.ABX, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 },
    .{ .opcode = Opcode6502.LDY, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.LDX, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.LDY, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.LDX, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 3 }, .{ .opcode = Opcode6502.TAY, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.TAX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.LDY, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.LDX, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 4 },
    .{ .opcode = Opcode6502.BCS, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.IZY, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.LDY, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.LDX, .address_mode = AddressMode6502.ZPY, .cycles = 4 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.CLV, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.TSX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.LDY, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.LDA, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.LDX, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 4 },
    .{ .opcode = Opcode6502.CPY, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.CPY, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.DEC, .address_mode = AddressMode6502.ZP0, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.INY, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.DEX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.CPY, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.DEC, .address_mode = AddressMode6502.ABS, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 },
    .{ .opcode = Opcode6502.BNE, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.IZY, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.DEC, .address_mode = AddressMode6502.ZPX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.CLD, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.CMP, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.DEC, .address_mode = AddressMode6502.ABX, .cycles = 7 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 },
    .{ .opcode = Opcode6502.CPX, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.IZX, .cycles = 6 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.CPX, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.ZP0, .cycles = 3 }, .{ .opcode = Opcode6502.INC, .address_mode = AddressMode6502.ZP0, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 5 }, .{ .opcode = Opcode6502.INX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.IMM, .cycles = 2 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.CPX, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.ABS, .cycles = 4 }, .{ .opcode = Opcode6502.INC, .address_mode = AddressMode6502.ABS, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 },
    .{ .opcode = Opcode6502.BEQ, .address_mode = AddressMode6502.REL, .cycles = 2 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.IZY, .cycles = 5 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 8 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.ZPX, .cycles = 4 }, .{ .opcode = Opcode6502.INC, .address_mode = AddressMode6502.ZPX, .cycles = 6 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 6 }, .{ .opcode = Opcode6502.SED, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.ABY, .cycles = 4 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 2 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 }, .{ .opcode = Opcode6502.NOP, .address_mode = AddressMode6502.IMP, .cycles = 4 }, .{ .opcode = Opcode6502.SBC, .address_mode = AddressMode6502.ABX, .cycles = 4 }, .{ .opcode = Opcode6502.INC, .address_mode = AddressMode6502.ABX, .cycles = 7 }, .{ .opcode = Opcode6502.XXX, .address_mode = AddressMode6502.IMP, .cycles = 7 },
};

pub const olc6502 = struct {
    bus: *Bus = undefined,
    a: u8 = 0x00,
    x: u8 = 0x00,
    y: u8 = 0x00,
    sp: u8 = 0x00,
    pc: u16 = 0x0000,
    status: u8 = 0x00,

    fetched: u8 = 0x00, // Represents the working input value to the ALU
    temp: u16 = 0x0000, // A convenience variable used everywhere
    addr_abs: u16 = 0x0000, // All used memory addresses end up in here
    addr_rel: u16 = 0x00, // Represents absolute address following a branch
    opcode: u8 = 0x00, // Is the instruction byte
    cycles: u8 = 0, // Counts how many cycles the instruction has remaining
    clock_count: u32 = 0, // A global accumulation of the number of clocks

    pub fn init() @This() {
        return @This(){};
    }

    pub fn connectBus(self: *@This(), bus: *Bus) void {
        self.bus = bus;
    }

    pub fn read(self: *@This(), a: u16) u8 {
        return self.bus.cpuRead(a, false);
    }

    pub fn write(self: *@This(), a: u16, d: u8) void {
        self.bus.cpuWrite(a, d);
    }

    pub fn getFlag(self: *@This(), flag: Flags6502) u8 {
        return if ((self.status & @intFromEnum(flag)) > 0) 1 else 0;
    }

    pub fn setFlag(self: *@This(), flag: Flags6502, value: bool) void {
        if (value) self.status |= @intFromEnum(flag) else self.status &= ~@intFromEnum(flag);
    }

    pub fn reset(self: *@This()) void {
        const addr_abs = 0xFFFC;
        const lo: u16 = self.read(addr_abs + 0);
        const hi: u16 = self.read(addr_abs + 1);
        self.pc = (hi << 8) | lo;

        self.a = 0;
        self.x = 0;
        self.y = 0;
        self.sp = 0xFD;
        self.status = 0x00 | @intFromEnum(Flags6502.U);
        self.addr_rel = 0x0000;
        self.addr_abs = 0x0000;
        self.fetched = 0x00;
        self.cycles = 8;
    }

    pub fn irq(self: *@This()) void {
        if (self.getFlag(.I) == 0) {
            self.write(0x0100 + @as(u16, self.sp), @truncate((self.pc >> 8) & 0x00FF));
            self.sp -= 1;
            self.write(0x0100 + @as(u16, self.sp), @truncate(self.pc & 0x00FF));
            self.sp -= 1;

            self.setFlag(.B, false);
            self.setFlag(.U, true);
            self.setFlag(.I, true);
            self.write(0x0100 + @as(u16, self.sp), self.status);
            self.sp -= 1;

            const addr_abs = 0xFFFE;
            const lo: u16 = self.read(addr_abs + 0);
            const hi: u16 = self.read(addr_abs + 1);
            self.pc = (hi << 8) | lo;

            self.cycles = 7;
        }
    }

    pub fn nmi(self: *@This()) void {
        self.write(0x0100 + @as(u16, self.sp), @truncate((self.pc >> 8) & 0x00FF));
        self.sp -= 1;
        self.write(0x0100 + @as(u16, self.sp), @truncate(self.pc & 0x00FF));
        self.sp -= 1;

        self.setFlag(.B, false);
        self.setFlag(.U, true);
        self.setFlag(.I, true);
        self.write(0x0100 + @as(u16, self.sp), self.status);
        self.sp -= 1;

        const addr_abs = 0xFFFA;
        const lo: u16 = self.read(addr_abs + 0);
        const hi: u16 = self.read(addr_abs + 1);
        self.pc = (hi << 8) | lo;

        self.cycles = 8;
    }

    pub fn clock(self: *@This()) void {
        if (self.cycles == 0) {
            self.opcode = self.read(self.pc);

            self.setFlag(.U, true);
            self.pc +%= 1;

            const instruction = opcode_lookup6502[self.opcode];
            self.cycles = instruction.cycles;
            const additional_cycle1: u8 = addressModePtr(instruction.address_mode)(self);
            const additional_cycle2: u8 = opcodePtr(instruction.opcode)(self);
            self.cycles +%= (additional_cycle1 & additional_cycle2);
            self.setFlag(.U, true);
        }

        self.clock_count += 1;
        self.cycles -%= 1;
    }

    pub fn fetch(self: *@This()) u8 {
        if (opcode_lookup6502[self.opcode].address_mode != AddressMode6502.IMP)
            self.fetched = self.read(self.addr_abs);
        return self.fetched;
    }

    // Addressing Modes
    pub fn IMP(self: *@This()) u8 {
        self.fetched = self.a;
        return 0;
    }

    pub fn IMM(self: *@This()) u8 {
        self.addr_abs = self.pc;
        self.pc +%= 1;
        return 0;
    }

    pub fn ZP0(self: *@This()) u8 {
        self.addr_abs = self.read(self.pc);
        self.pc +%= 1;
        self.addr_abs &= 0x00FF;
        return 0;
    }

    pub fn ZPX(self: *@This()) u8 {
        self.addr_abs = self.read(self.pc) +% self.x;
        self.pc +%= 1;
        self.addr_abs &= 0x00FF;
        return 0;
    }

    pub fn ZPY(self: *@This()) u8 {
        self.addr_abs = self.read(self.pc) +% self.y;
        self.pc +%= 1;
        self.addr_abs &= 0x00FF;
        return 0;
    }

    pub fn REL(self: *@This()) u8 {
        self.addr_rel = self.read(self.pc);
        self.pc +%= 1;
        if (self.addr_rel & 0x80 != 0) self.addr_rel |= 0xFF00;
        return 0;
    }

    pub fn ABS(self: *@This()) u8 {
        const lo: u16 = self.read(self.pc);
        self.pc +%= 1;
        const hi: u16 = self.read(self.pc);
        self.pc +%= 1;
        self.addr_abs = (hi << 8) | lo;
        return 0;
    }

    pub fn ABX(self: *@This()) u8 {
        const lo: u16 = self.read(self.pc);
        self.pc +%= 1;
        const hi: u16 = self.read(self.pc);
        self.pc +%= 1;
        self.addr_abs = ((hi << 8) | lo) +% self.x;
        if ((self.addr_abs & 0xFF00) != (hi << 8))
            return 1;
        return 0;
    }

    pub fn ABY(self: *@This()) u8 {
        const lo: u16 = self.read(self.pc);
        self.pc +%= 1;
        const hi: u16 = self.read(self.pc);
        self.pc +%= 1;
        self.addr_abs = ((hi << 8) | lo) +% self.y;
        if ((self.addr_abs & 0xFF00) != (hi << 8))
            return 1;
        return 0;
    }

    pub fn IND(self: *@This()) u8 {
        const lo: u16 = self.read(self.pc);
        self.pc +%= 1;
        const hi: u16 = self.read(self.pc);
        self.pc +%= 1;
        const ptr: u16 = (hi << 8) | lo;

        if (lo == 0x00FF) // Simulate page boundry hardware bug
            self.addr_abs = (@as(u16, self.read(ptr & 0xFF00)) << 8) | @as(u16, self.read(ptr))
        else // Behave normally
            self.addr_abs = (@as(u16, self.read(ptr + 1)) << 8) | @as(u16, self.read(ptr));

        return 0;
    }

    pub fn IZX(self: *@This()) u8 {
        const t: u16 = self.read(self.pc);
        self.pc +%= 1;

        const lo: u16 = self.read((t + @as(u16, self.x)) & 0x00FF);
        const hi: u16 = self.read((t + @as(u16, self.x) + 1) & 0x00FF);
        self.addr_abs = (hi << 8) | lo;
        return 0;
    }

    pub fn IZY(self: *@This()) u8 {
        const t: u16 = self.read(self.pc);
        self.pc +%= 1;

        const lo: u16 = self.read(t & 0x00FF);
        const hi: u16 = self.read((t + 1) & 0x00FF);
        self.addr_abs = ((hi << 8) | lo) +% self.y;
        if ((self.addr_abs & 0xFF00) != (hi << 8))
            return 1;
        return 0;
    }

    // Opcodes
    pub fn ADC(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = @as(u16, self.a) + @as(u16, self.fetched) + @as(u16, self.getFlag(.C));
        self.setFlag(.C, self.temp > 255);
        self.setFlag(.Z, self.temp & 0x00FF == 0);
        self.setFlag(.V, (~(@as(u16, self.a) ^ @as(u16, self.fetched)) & (@as(u16, self.a) ^ self.temp)) & 0x0080 != 0);
        self.setFlag(.N, self.temp & 0x80 != 0);
        self.a = @truncate(self.temp & 0x00FF);
        return 1;
    }

    pub fn AND(self: *@This()) u8 {
        _ = self.fetch();
        self.a &= self.fetched;
        self.setFlag(.Z, self.a == 0x00);
        self.setFlag(.N, self.a & 0x80 != 0);
        return 1;
    }

    pub fn ASL(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = @as(u16, self.fetched) << 1;
        self.setFlag(.C, self.temp & 0xFF00 > 0);
        self.setFlag(.Z, self.temp & 0x00FF == 0x00);
        self.setFlag(.N, self.temp & 0x80 != 0);
        if (opcode_lookup6502[self.opcode].address_mode == AddressMode6502.IMP)
            self.a = @truncate(self.temp & 0x00FF)
        else
            self.write(self.addr_abs, @truncate(self.temp & 0x00FF));
        return 0;
    }

    pub fn BCC(self: *@This()) u8 {
        if (self.getFlag(.C) == 0) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn BCS(self: *@This()) u8 {
        if (self.getFlag(.C) == 1) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn BEQ(self: *@This()) u8 {
        if (self.getFlag(.Z) == 1) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn BIT(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = self.a & self.fetched;
        self.setFlag(.Z, self.temp & 0x00FF == 0x00);
        self.setFlag(.N, self.fetched & (1 << 7) != 0);
        self.setFlag(.V, self.fetched & (1 << 6) != 0);
        return 0;
    }

    pub fn BMI(self: *@This()) u8 {
        if (self.getFlag(.N) == 1) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn BNE(self: *@This()) u8 {
        if (self.getFlag(.Z) == 0) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn BPL(self: *@This()) u8 {
        if (self.getFlag(.N) == 0) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn BRK(self: *@This()) u8 {
        self.pc +%= 1;
        self.setFlag(.I, true);
        self.write(0x0100 + @as(u16, self.sp), @truncate((self.pc >> 8) & 0x00FF));
        self.sp -%= 1;
        self.write(0x0100 + @as(u16, self.sp), @truncate(self.pc & 0x00FF));
        self.sp -%= 1;
        self.setFlag(.B, true);
        self.write(0x0100 + @as(u16, self.sp), self.status);
        self.sp -%= 1;
        self.setFlag(.B, false);
        self.pc = @as(u16, self.read(0xFFFE)) | (@as(u16, self.read(0xFFFF)) << 8);
        return 0;
    }

    pub fn BVC(self: *@This()) u8 {
        if (self.getFlag(.V) == 0) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn BVS(self: *@This()) u8 {
        if (self.getFlag(.V) == 1) {
            self.cycles +%= 1;
            self.addr_abs = self.pc +% self.addr_rel;
            if ((self.addr_abs & 0xFF00) != (self.pc & 0xFF00))
                self.cycles +%= 1;
            self.pc = self.addr_abs;
        }
        return 0;
    }

    pub fn CLC(self: *@This()) u8 {
        self.setFlag(.C, false);
        return 0;
    }

    pub fn CLD(self: *@This()) u8 {
        self.setFlag(.D, false);
        return 0;
    }

    pub fn CLI(self: *@This()) u8 {
        self.setFlag(.I, false);
        return 0;
    }

    pub fn CLV(self: *@This()) u8 {
        self.setFlag(.V, false);
        return 0;
    }

    pub fn CMP(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = @as(u16, self.a) -% @as(u16, self.fetched);
        self.setFlag(.C, self.a >= self.fetched);
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        return 1;
    }

    pub fn CPX(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = @as(u16, self.x) -% @as(u16, self.fetched);
        self.setFlag(.C, self.x >= self.fetched);
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        return 0;
    }

    pub fn CPY(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = @as(u16, self.y) -% @as(u16, self.fetched);
        self.setFlag(.C, self.y >= self.fetched);
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        return 0;
    }

    pub fn DEC(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = self.fetched -% 1;
        self.write(self.addr_abs, @truncate(self.temp & 0x00FF));
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        return 0;
    }

    pub fn DEX(self: *@This()) u8 {
        self.x -%= 1;
        self.setFlag(.Z, self.x == 0x00);
        self.setFlag(.N, self.x & 0x80 != 0);
        return 0;
    }

    pub fn DEY(self: *@This()) u8 {
        self.y -%= 1;
        self.setFlag(.Z, self.y == 0x00);
        self.setFlag(.N, self.y & 0x80 != 0);
        return 0;
    }

    pub fn EOR(self: *@This()) u8 {
        _ = self.fetch();
        self.a ^= self.fetched;
        self.setFlag(.Z, self.a == 0x00);
        self.setFlag(.N, self.a & 0x80 != 0);
        return 0;
    }

    pub fn INC(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = self.fetched +% 1;
        self.write(self.addr_abs, @truncate(self.temp & 0x00FF));
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        return 0;
    }

    pub fn INX(self: *@This()) u8 {
        self.x +%= 1;
        self.setFlag(.Z, self.x == 0x00);
        self.setFlag(.N, self.x & 0x80 != 0);
        return 0;
    }

    pub fn INY(self: *@This()) u8 {
        self.y +%= 1;
        self.setFlag(.Z, self.y == 0x00);
        self.setFlag(.N, self.y & 0x80 != 0);
        return 0;
    }

    pub fn JMP(self: *@This()) u8 {
        self.pc = self.addr_abs;
        return 0;
    }

    pub fn JSR(self: *@This()) u8 {
        self.pc -%= 1;
        self.write(0x0100 + @as(u16, self.sp), @truncate((self.pc >> 8) & 0x00FF));
        self.sp -%= 1;
        self.write(0x0100 + @as(u16, self.sp), @truncate(self.pc & 0x00FF));
        self.sp -%= 1;
        self.pc = self.addr_abs;
        return 0;
    }

    pub fn LDA(self: *@This()) u8 {
        _ = self.fetch();
        self.a = self.fetched;
        self.setFlag(.Z, self.a == 0x00);
        self.setFlag(.N, self.a & 0x80 != 0);
        return 1;
    }

    pub fn LDX(self: *@This()) u8 {
        _ = self.fetch();
        self.x = self.fetched;
        self.setFlag(.Z, self.x == 0x00);
        self.setFlag(.N, self.x & 0x80 != 0);
        return 0;
    }

    pub fn LDY(self: *@This()) u8 {
        _ = self.fetch();
        self.y = self.fetched;
        self.setFlag(.Z, self.y == 0x00);
        self.setFlag(.N, self.y & 0x80 != 0);
        return 0;
    }

    pub fn LSR(self: *@This()) u8 {
        _ = self.fetch();
        self.setFlag(.C, self.fetched & 0x0001 != 0);
        self.temp = @intCast(self.fetched >> 1);
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        if (opcode_lookup6502[self.opcode].address_mode == AddressMode6502.IMP)
            self.a = @truncate(self.temp & 0x00FF)
        else
            self.write(self.addr_abs, @truncate(self.temp & 0x00FF));
        return 0;
    }

    pub fn NOP(self: *@This()) u8 {
        switch (self.opcode) {
            0x1C, 0x3C, 0x5C, 0x7C, 0xDC, 0xFC => return 1,
            else => return 0,
        }
    }

    pub fn ORA(self: *@This()) u8 {
        _ = self.fetch();
        self.a |= self.fetched;
        self.setFlag(.Z, self.a == 0x00);
        self.setFlag(.N, self.a & 0x80 != 0);
        return 1;
    }

    pub fn PHA(self: *@This()) u8 {
        self.write(0x0100 + @as(u16, self.sp), self.a);
        self.sp -%= 1;
        return 0;
    }

    pub fn PHP(self: *@This()) u8 {
        self.write(0x0100 + @as(u16, self.sp), self.status | @intFromEnum(Flags6502.B) | @intFromEnum(Flags6502.U));
        self.setFlag(.B, false);
        self.setFlag(.U, false);
        self.sp -%= 1;
        return 0;
    }

    pub fn PLA(self: *@This()) u8 {
        self.sp +%= 1;
        self.a = self.read(0x0100 + @as(u16, self.sp));
        self.setFlag(.Z, self.a == 0x00);
        self.setFlag(.N, self.a & 0x80 != 0);
        return 0;
    }

    pub fn PLP(self: *@This()) u8 {
        self.sp +%= 1;
        self.status = self.read(0x0100 + @as(u16, self.sp));
        self.setFlag(.U, true);
        return 0;
    }

    pub fn ROL(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = (@as(u16, self.fetched) << 1) | @as(u16, self.getFlag(.C));
        self.setFlag(.C, self.temp & 0xFF00 != 0);
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        if (opcode_lookup6502[self.opcode].address_mode == AddressMode6502.IMP)
            self.a = @truncate(self.temp & 0x00FF)
        else
            self.write(self.addr_abs, @truncate(self.temp & 0x00FF));
        return 0;
    }

    pub fn ROR(self: *@This()) u8 {
        _ = self.fetch();
        self.temp = @as(u16, self.getFlag(.C) << 7) | (self.fetched >> 1);
        self.setFlag(.C, self.fetched & 0x01 != 0);
        self.setFlag(.Z, self.temp & 0x00FF == 0x0000);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        if (opcode_lookup6502[self.opcode].address_mode == AddressMode6502.IMP)
            self.a = @truncate(self.temp & 0x00FF)
        else
            self.write(self.addr_abs, @truncate(self.temp & 0x00FF));
        return 0;
    }

    pub fn RTI(self: *@This()) u8 {
        self.sp +%= 1;
        self.status = self.read(0x0100 + @as(u16, self.sp));
        self.status &= ~@intFromEnum(Flags6502.B);
        self.status &= ~@intFromEnum(Flags6502.U);
        self.sp +%= 1;
        self.pc = @intCast(self.read(0x0100 + @as(u16, self.sp)));
        self.sp +%= 1;
        self.pc |= @as(u16, self.read(0x0100 + @as(u16, self.sp))) << 8;
        return 0;
    }

    pub fn RTS(self: *@This()) u8 {
        self.sp +%= 1;
        self.pc = @intCast(self.read(0x0100 + @as(u16, self.sp)));
        self.sp +%= 1;
        self.pc |= @as(u16, self.read(0x0100 + @as(u16, self.sp))) << 8;
        self.pc +%= 1;
        return 0;
    }

    pub fn SBC(self: *@This()) u8 {
        _ = self.fetch();
        const value = @as(u16, self.fetched) ^ 0x00FF;
        self.temp = @as(u16, self.a) + value + @as(u16, self.getFlag(.C));
        self.setFlag(.C, self.temp & 0xFF00 != 0);
        self.setFlag(.Z, ((self.temp & 0x00FF) == 0));
        self.setFlag(.V, (self.temp ^ @as(u16, self.a)) & (self.temp ^ value) & 0x0080 != 0);
        self.setFlag(.N, self.temp & 0x0080 != 0);
        self.a = @truncate(self.temp & 0x00FF);
        return 1;
    }

    pub fn SEC(self: *@This()) u8 {
        self.setFlag(.C, true);
        return 0;
    }

    pub fn SED(self: *@This()) u8 {
        self.setFlag(.D, true);
        return 0;
    }

    pub fn SEI(self: *@This()) u8 {
        self.setFlag(.I, true);
        return 0;
    }

    pub fn STA(self: *@This()) u8 {
        self.write(self.addr_abs, self.a);
        return 0;
    }

    pub fn STX(self: *@This()) u8 {
        self.write(self.addr_abs, self.x);
        return 0;
    }

    pub fn STY(self: *@This()) u8 {
        self.write(self.addr_abs, self.y);
        return 0;
    }

    pub fn TAX(self: *@This()) u8 {
        self.x = self.a;
        self.setFlag(.Z, self.x == 0x00);
        self.setFlag(.N, self.x & 0x80 != 0);
        return 0;
    }

    pub fn TAY(self: *@This()) u8 {
        self.y = self.a;
        self.setFlag(.Z, self.y == 0x00);
        self.setFlag(.N, self.y & 0x80 != 0);
        return 0;
    }

    pub fn TSX(self: *@This()) u8 {
        self.x = self.sp;
        self.setFlag(.Z, self.x == 0x00);
        self.setFlag(.N, self.x & 0x80 != 0);
        return 0;
    }

    pub fn TXA(self: *@This()) u8 {
        self.a = self.x;
        self.setFlag(.Z, self.a == 0x00);
        self.setFlag(.N, self.a & 0x80 != 0);
        return 0;
    }

    pub fn TXS(self: *@This()) u8 {
        self.sp = self.x;
        return 0;
    }

    pub fn TYA(self: *@This()) u8 {
        self.a = self.y;
        self.setFlag(.Z, self.a == 0x00);
        self.setFlag(.N, self.a & 0x80 != 0);
        return 0;
    }

    pub fn XXX(self: *@This()) u8 {
        _ = self;
        return 0;
    }

    pub fn complete(self: *@This()) bool {
        return self.cycles == 0;
    }
};

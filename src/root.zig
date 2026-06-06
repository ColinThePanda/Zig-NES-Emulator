pub const cpu = @import("cpu.zig");
pub const olc6502 = cpu.olc6502;
pub const Flags6502 = cpu.Flags6502;
pub const AddressMode6502 = cpu.AddressMode6502;
pub const Opcode6502 = cpu.Opcode6502;
pub const addressModePtr = cpu.addressModePtr;
pub const opcodePtr = cpu.opcodePtr;
pub const Instruction = cpu.Instruction;
pub const opcode_lookup6502: [16 * 16]Instruction = cpu.opcode_lookup6502;

pub const bus = @import("bus.zig");
pub const Bus = bus.Bus;

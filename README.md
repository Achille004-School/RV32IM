# RISC-V Microarchitecture Implementation

A 5-stage pipelined RISC-V processor supporting RV32IM instruction set with hazard detection, forwarding, and multiply/divide operations.

## 📋 Table of Contents

- [RISC-V Microarchitecture Implementation](#risc-v-microarchitecture-implementation)
  - [📋 Table of Contents](#-table-of-contents)
  - [🏗️ Architecture](#️-architecture)
  - [📚 Supported Instructions](#-supported-instructions)
    - [RV32I Base Instructions](#rv32i-base-instructions)
    - [RV32M Extension](#rv32m-extension)
  - [🚀 Getting Started](#-getting-started)
  - [🧪 Testing](#-testing)
  - [⚙️ Running](#️-running)
  - [🔍 Technical Details](#-technical-details)
  - [🤝 Contributing](#-contributing)
  - [📄 License](#-license)

## 🏗️ Architecture

Classic 5-stage pipeline with hazard handling:

```
[IF] → [ID] → [EX] → [MEM] → [WB]
 ↓      ↓      ↓       ↓       ↓
 PC    Ctrl   ALU    Memory   RegFile
 Reg   Unit          Access   Write
```

**Key Features:**

- Data forwarding (EX-EX, MEM-EX) to minimize stalls
- Load-use hazard detection with automatic stalls
- Branch/jump support with flush mechanisms
- Byte, half-word, and word memory operations

## 📚 Supported Instructions

### RV32I Base Instructions

- **Arithmetic/Logic**: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`
- **Immediates**: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU`
- **Memory**: `LB/LH/LW/LBU/LHU` (loads), `SB/SH/SW` (stores)
- **Control**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `JAL`, `JALR`
- **Upper**: `LUI`, `AUIPC`

### RV32M Extension

- **Multiply**: `MUL`, `MULH`, `MULHSU`, `MULHU`
- **Divide**: `DIV`, `DIVU`, `REM`, `REMU`

## 🚀 Getting Started

**Prerequisites:** Verilog simulator, RISC-V toolchain, Python 3.x

In all my examples I'll be using Icarus Verilog and the ucrt64 toolchain.

To install the toolchain, run in the ucrt64 CLI (as admin):

```bash
pacman -S mingw-w64-ucrt-x86_64-riscv64-unknown-elf-toolchain
```

## 🧪 Testing

All unit tests can be found in the `test/` folder.
Here's how to run one:

```bash
iverilog -o test_sim src/data_memory.v test/data_memory_tb.v
vvp test_sim
```

## ⚙️ Running

1. Extract instructions and data:

```bash
riscv64-unknown-elf-as -o example/program.o example/program.s
riscv64-unknown-elf-ld -o example/program.elf example/program.o
riscv64-unknown-elf-objcopy -O verilog example/program.elf instructions.mem --verilog-data-width 4 --only-section=.text
riscv64-unknown-elf-objcopy -O verilog example/program.elf data.mem --verilog-data-width 1 --only-section=.data
```

Then remove the first line in both `instructions.mem` and `data.mem`, which should start with @.  
*(The simulation does not need a start address, keeping it will just bug everything.)*  

2. Run the simulation

```bash
iverilog -o processor_sim src/processor.v example/run_example.v
vvp processor_sim
gtkwave run_example.vcd
```

## 🔍 Technical Details

**Hazard Handling:**

- Data forwarding (EX-EX, MEM-EX) with automatic source selection
- Load-use stall detection and bubble insertion
- Branch/jump flush with PC target calculation

**Memory System:**

- Instruction memory: Read-only, word-aligned
- Data memory: Byte/half-word/word access, little-endian
- 32-bit address space

## 🤝 Contributing

This is a learning project. For everyone.  
Contributions and teamwork are welcome!  

## 📄 License

MIT License - see `LICENSE.md` for details.

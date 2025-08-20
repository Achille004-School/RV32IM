# RISC-V RV32IM Test Program
# Tests all supported instructions except ecall, ebreak, and fence
# Author: GitHub Copilot
# Date: August 20, 2025

.text
.globl _start

_start:
    # Initialize test data
    li x1, 10          # x1 = 10 (using ADDI pseudoinstruction)
    li x2, 5           # x2 = 5
    li x3, -3          # x3 = -3
    li x4, 0xFFFFFFFF  # x4 = -1 (all 1s)
    li x5, 0x12345678  # x5 = test pattern
    
    # Test R-type instructions (Register-Register operations)
test_r_type:
    add x6, x1, x2     # x6 = 10 + 5 = 15
    sub x7, x1, x2     # x7 = 10 - 5 = 5
    sll x8, x1, x2     # x8 = 10 << 5 = 320
    slt x9, x2, x1     # x9 = (5 < 10) = 1
    slt x10, x1, x2    # x10 = (10 < 5) = 0
    sltu x11, x3, x1   # x11 = (-3 < 10 unsigned) = 0 (since -3 is large positive)
    xor x12, x1, x2    # x12 = 10 ^ 5 = 15
    srl x13, x4, x2    # x13 = 0xFFFFFFFF >> 5 = 0x07FFFFFF
    sra x14, x4, x2    # x14 = 0xFFFFFFFF >> 5 (arithmetic) = 0xFFFFFFFF
    or x15, x1, x2     # x15 = 10 | 5 = 15
    and x16, x1, x2    # x16 = 10 & 5 = 0

    # Test I-type instructions (Immediate operations)
test_i_type:
    addi x17, x1, 100  # x17 = 10 + 100 = 110
    slti x18, x1, 20   # x18 = (10 < 20) = 1
    slti x19, x1, 5    # x19 = (10 < 5) = 0
    sltiu x20, x3, 5   # x20 = (-3 < 5 unsigned) = 0
    xori x21, x1, 7    # x21 = 10 ^ 7 = 13
    ori x22, x1, 7     # x22 = 10 | 7 = 15
    andi x23, x5, 0xFF # x23 = 0x12345678 & 0xFF = 0x78
    slli x24, x1, 3    # x24 = 10 << 3 = 80
    srli x25, x4, 4    # x25 = 0xFFFFFFFF >> 4 = 0x0FFFFFFF
    srai x26, x4, 4    # x26 = 0xFFFFFFFF >> 4 (arithmetic) = 0xFFFFFFFF

    # Test U-type instructions (Upper immediate)
test_u_type:
    lui x27, 0x12345   # x27 = 0x12345000
    auipc x28, 0x1000  # x28 = PC + 0x1000000

    # Test multiplication instructions (M extension)
test_m_extension:
    mul x29, x1, x2    # x29 = 10 * 5 = 50
    mulh x30, x3, x1   # x30 = high 32 bits of (-3 * 10)
    mulhu x31, x4, x1  # x31 = high 32 bits of (0xFFFFFFFF * 10) unsigned
    
    # Test division instructions
    li x6, 20          # Reload x6 with 20
    div x7, x6, x2     # x7 = 20 / 5 = 4
    divu x8, x4, x1    # x8 = 0xFFFFFFFF / 10 (unsigned)
    rem x9, x6, x1     # x9 = 20 % 10 = 0
    remu x10, x4, x1   # x10 = 0xFFFFFFFF % 10 (unsigned)

    # Test memory operations (Load/Store)
test_memory:
    # Set up base address for memory operations
    li x11, 0x1000     # Base address for data
    
    # Store operations
    sw x1, 0(x11)      # Store word: mem[0x1000] = 10
    sh x2, 4(x11)      # Store halfword: mem[0x1004] = 5
    sb x3, 6(x11)      # Store byte: mem[0x1006] = -3
    
    # Load operations
    lw x12, 0(x11)     # Load word: x12 = mem[0x1000] = 10
    lh x13, 4(x11)     # Load halfword (signed): x13 = mem[0x1004] = 5
    lhu x14, 4(x11)    # Load halfword (unsigned): x14 = mem[0x1004] = 5
    lb x15, 6(x11)     # Load byte (signed): x15 = mem[0x1006] = -3
    lbu x16, 6(x11)    # Load byte (unsigned): x16 = mem[0x1006] = 253

    # Test branch instructions
test_branches:
    li x17, 10         # x17 = 10
    li x18, 10         # x18 = 10
    li x19, 5          # x19 = 5
    li x20, -1         # x20 = -1
    
    # BEQ test
    beq x17, x18, branch_eq_taken    # Should branch (10 == 10)
    li x21, 0          # Should not execute
    j branch_eq_end
branch_eq_taken:
    li x21, 1          # Mark that branch was taken
branch_eq_end:

    # BNE test
    bne x17, x19, branch_ne_taken    # Should branch (10 != 5)
    li x22, 0          # Should not execute
    j branch_ne_end
branch_ne_taken:
    li x22, 1          # Mark that branch was taken
branch_ne_end:

    # BLT test (signed)
    blt x19, x17, branch_lt_taken    # Should branch (5 < 10)
    li x23, 0          # Should not execute
    j branch_lt_end
branch_lt_taken:
    li x23, 1          # Mark that branch was taken
branch_lt_end:

    # BGE test (signed)
    bge x17, x19, branch_ge_taken    # Should branch (10 >= 5)
    li x24, 0          # Should not execute
    j branch_ge_end
branch_ge_taken:
    li x24, 1          # Mark that branch was taken
branch_ge_end:

    # BLTU test (unsigned)
    bltu x19, x17, branch_ltu_taken  # Should branch (5 < 10 unsigned)
    li x25, 0          # Should not execute
    j branch_ltu_end
branch_ltu_taken:
    li x25, 1          # Mark that branch was taken
branch_ltu_end:

    # BGEU test (unsigned)
    bgeu x20, x19, branch_geu_taken  # Should branch (-1 >= 5 unsigned, since -1 is 0xFFFFFFFF)
    li x26, 0          # Should not execute
    j branch_geu_end
branch_geu_taken:
    li x26, 1          # Mark that branch was taken
branch_geu_end:

    # Test jump instructions
test_jumps:
    jal x27, jump_target             # Jump and link: x27 = return address
    li x28, 0                        # Should not execute
    j jump_end
jump_target:
    li x28, 1                        # Mark that jump was taken
    jalr x0, x27, 0                  # Return using jalr (x0 discards return addr)
jump_end:

    # Test pseudoinstructions that translate to supported instructions
test_pseudoinstructions:
    nop                # Translates to: addi x0, x0, 0
    mv x29, x1         # Translates to: addi x29, x1, 0 (x29 = x1)
    not x30, x1        # Translates to: xori x30, x1, -1
    neg x31, x1        # Translates to: sub x31, x0, x1
    
    # Load immediate variants
    li x1, 0x7FFFFFFF  # Load large positive number
    li x2, 0x80000000  # Load large negative number (sign bit set)
    
    # Branch pseudoinstructions
    bnez x1, nonzero_branch    # Translates to: bne x1, x0, target
    j nonzero_end
nonzero_branch:
    li x3, 0xDEADBEEF         # Marker value
nonzero_end:

    beqz x0, zero_branch       # Translates to: beq x0, x0, target
    li x4, 0                   # Should not execute
    j zero_end
zero_branch:
    li x4, 0xCAFEBABE         # Marker value
zero_end:

# Test completion marker
test_complete:
    # If we reach here, all tests have been executed
    li x31, 0xDEADBEEF        # Success marker
    
# Infinite loop to halt execution (since no ecall/ebreak)
halt:
    j halt                    # Infinite loop

# Data section for testing loads/stores
.data
test_data:
    .word 0xDEADBEEF, 0xCAFEBABE, 0x12345678, 0x9ABCDEF0
    .half 0x1234, 0x5678, 0x9ABC, 0xDEF0
    .byte 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0
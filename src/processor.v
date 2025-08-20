`include "../src/adder.v"
`include "../src/alu.v"
`include "../src/control_unit.v"
`include "../src/data_memory.v"
`include "../src/extend.v"
`include "../src/hazard_unit.v"
`include "../src/instruction_memory.v"
`include "../src/multiplexer_2.v"
`include "../src/multiplexer_3.v"
`include "../src/register_file.v"
`include "../src/register.v"

module processor (
    input wire clk,
    output reg [31:0] DEBUG_INSTRUCTION,
    output reg [31:0] DEBUG_PC,
    output reg [31:0] DEBUG_RESULT
);

    // FETCH
    wire [31:0] pc_f_1, pc_f, pc_plus_4_f, instr_f;
    multiplexer_2 pc_f_mux (pc_plus_4_f, pc_target_e, pc_src_e, pc_f_1);
    register #(32) pc_f_reg (pc_f_1, clk, ~stall_f, 1'b0, pc_f);
    instruction_memory INSTRUCTION_MEMORY (pc_f, instr_f);
    adder pc_plus_4_adder (pc_f, 32'h4, pc_plus_4_f);

    // DECODE
    // Data signals
    wire [31:0] instr_d, pc_d, pc_plus_4_d;
    register #(32) instr_d_reg (instr_f, clk, ~stall_d, flush_d, instr_d);
    register #(32) pc_d_reg (pc_f, clk, ~stall_d, flush_d, pc_d);
    register #(32) pc_plus_4_d_reg (pc_plus_4_f, clk, ~stall_d, flush_d, pc_plus_4_d);

    // Control signals
    wire reg_write_d;
    wire [1:0] result_src_d, data_size_d;
    wire data_unsigned_d, mem_write_d, jump_d, branch_d;
    wire [4:0] alu_control_d;
    wire alu_src_d;
    wire [2:0] imm_src_d;

    wire [31:0] rd1_d, rd2_d;
    register_file REGISTER_FILE (instr_d[19:15], instr_d[24:20], rd_w, result_w, reg_write_w, ~clk, rd1_d, rd2_d);

    wire [4:0] rs1_d = instr_d[19:15];
    wire [4:0] rs2_d = instr_d[24:20];
    wire [4:0] rd_d = instr_d[11:7];

    wire [31:0] imm_ext_d;
    extend EXTEND(instr_d[31:7], imm_src_d, imm_ext_d);

    // EXECUTE
    // Control signals
    wire reg_write_e;
    register  #(1) reg_write_e_reg (reg_write_d, clk, 1'b1, flush_e, reg_write_e);
    wire [1:0] result_src_e, data_size_e;
    register #(2) result_src_e_reg (result_src_d, clk, 1'b1, flush_e, result_src_e);
    register #(2) data_size_e_reg (data_size_d, clk, 1'b1, flush_e, data_size_e);
    wire data_unsigned_e, mem_write_e, jump_e, branch_e;
    register #(1) data_unsigned_e_reg (data_unsigned_d, clk, 1'b1, flush_e, data_unsigned_e);
    register #(1) mem_write_e_reg (mem_write_d, clk, 1'b1, flush_e, mem_write_e);
    register #(1) jump_e_reg (jump_d, clk, 1'b1, flush_e, jump_e);
    register #(1) branch_e_reg (branch_d, clk, 1'b1, flush_e, branch_e);
    wire [4:0] alu_control_e;
    register #(5) alu_control_e_reg (alu_control_d, clk, 1'b1, flush_e, alu_control_e);
    wire alu_src_e;
    register #(1) alu_src_e_reg (alu_src_d, clk, 1'b1, flush_e, alu_src_e);

    // Data signals
    wire [31:0] rd1_e, rd2_e, pc_e;
    register #(32) rd1_e_reg (rd1_d, clk, 1'b1, flush_e, rd1_e);
    register #(32) rd2_e_reg (rd2_d, clk, 1'b1, flush_e, rd2_e);
    register #(32) pc_e_reg (pc_d, clk, 1'b1, flush_e, pc_e);
    wire [4:0] rs1_e, rs2_e, rd_e;
    register #(5) rs1_e_reg (rs1_d, clk, 1'b1, flush_e, rs1_e);
    register #(5) rs2_e_reg (rs2_d, clk, 1'b1, flush_e, rs2_e);
    register #(5) rd_e_reg (rd_d, clk, 1'b1, flush_e, rd_e);
    wire [31:0] imm_ext_e, pc_plus_4_e;
    register #(32) imm_ext_e_reg (imm_ext_d, clk, 1'b1, flush_e, imm_ext_e);
    register #(32) pc_plus_4_e_reg (pc_plus_4_d, clk, 1'b1, flush_e, pc_plus_4_e);

    wire [31:0] src_a_e, write_data_e, src_b_e;
    multiplexer_3 src_a_e_mux (rd1_e, result_w, alu_result_m, foward_a_e, src_a_e);
    multiplexer_3 src_b_e_mux (rd2_e, result_w, alu_result_m, foward_b_e, write_data_e);
    multiplexer_2 src_b_e_mux_final (write_data_e, imm_ext_e, alu_src_e, src_b_e);

    wire [31:0] alu_result_e;
    wire zero_e;
    alu ALU(src_a_e, src_b_e, alu_control_e, alu_result_e, zero_e);

    wire [31:0] pc_target_e;
    adder pc_target_adder (pc_e, imm_ext_e, pc_target_e);

    wire branch_taken_e, pc_src_e;
    and(branch_taken_e, branch_e, zero_e);
    or(pc_src_e, jump_e, branch_taken_e);

    // MEMORY
    // Control signals
    wire [1:0] data_size_m;
    register #(2) data_size_m_reg (data_size_e, clk, 1'b1, 1'b0, data_size_m);
    wire data_unsigned_m, reg_write_m;
    register #(1) data_unsigned_m_reg (data_unsigned_e, clk, 1'b1, 1'b0, data_unsigned_m);
    register #(1) reg_write_m_reg (reg_write_e, clk, 1'b1, 1'b0, reg_write_m);
    wire [1:0] result_src_m;
    register #(2) result_src_m_reg (result_src_e, clk, 1'b1, 1'b0, result_src_m);
    wire mem_write_m;
    register #(1) mem_write_m_reg (mem_write_e, clk, 1'b1, 1'b0, mem_write_m);

    // Data signals
    wire [31:0] alu_result_m, write_data_m;
    register #(32) alu_result_m_reg (alu_result_e, clk, 1'b1, 1'b0, alu_result_m);
    register #(32) write_data_m_reg (write_data_e, clk, 1'b1, 1'b0, write_data_m);
    wire [4:0] rd_m;
    register #(5) rd_m_reg (rd_e, clk, 1'b1, 1'b0, rd_m);
    wire [31:0] pc_plus_4_m;
    register #(32) pc_plus_4_m_reg (pc_plus_4_e, clk, 1'b1, 1'b0, pc_plus_4_m);

    wire [31:0] read_data_m;
    data_memory DATA_MEMORY (alu_result_m, write_data_m, data_size_m, data_unsigned_m, mem_write_m, clk, read_data_m);

    // WRITE BACK
    // Control signals
    wire reg_write_w;
    register #(1) reg_write_w_reg (reg_write_m, clk, 1'b1, 1'b0, reg_write_w);
    wire [1:0] result_src_w;
    register #(2) result_src_w_reg (result_src_m, clk, 1'b1, 1'b0, result_src_w);

    // Data signals
    wire [31:0] alu_result_w, read_data_w;
    register #(32) alu_result_w_reg (alu_result_m, clk, 1'b1, 1'b0, alu_result_w);
    register #(32) read_data_w_reg (read_data_m, clk, 1'b1, 1'b0, read_data_w);
    wire [4:0] rd_w;
    register #(5) rd_w_reg (rd_m, clk, 1'b1, 1'b0, rd_w);
    wire [31:0] pc_plus_4_w;
    register #(32) pc_plus_4_w_reg (pc_plus_4_m, clk, 1'b1, 1'b0, pc_plus_4_w);

    wire [31:0] result_w;
    multiplexer_3 result_w_mux (alu_result_w, read_data_w, pc_plus_4_w, result_src_w, result_w);

    // CONTROL UNIT AND HAZARD UNIT
    control_unit CONTROL_UNIT (instr_d[6:0], instr_d[14:12], instr_d[31:25], 
        reg_write_d, result_src_d, data_size_d, data_unsigned_d, mem_write_d,
        jump_d, branch_d, alu_control_d, alu_src_d, imm_src_d
    );

    wire stall_f, stall_d, flush_d, flush_e;
    wire [1:0] foward_a_e, foward_b_e;
    hazard_unit HAZARD_UNIT (rs1_d, rs2_d, rs1_e, rs2_e, rd_e, 
        pc_src_e, result_src_e, reg_write_m, rd_m, reg_write_w, rd_w,
        stall_f, stall_d, flush_d, flush_e, foward_a_e, foward_b_e
    );

    // DEBUG OUTPUT
    always @(posedge clk) begin
        DEBUG_INSTRUCTION <= instr_d;
        DEBUG_PC <= pc_d;
        DEBUG_RESULT <= result_w;
    end

endmodule
`include "../src/static/alu_control.vh"
`include "../src/static/immediate_sources.vh"
`include "../src/static/opcodes.vh"
`include "../src/static/result_src.vh"

module control_unit (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    output reg reg_write,
    output reg [1:0] result_src,
    output wire [1:0] data_size,
    output wire data_unsigned,
    output reg mem_write,
    output reg jump,
    output reg branch,
    output reg [4:0] alu_control,
    output reg alu_src,
    output reg [2:0] imm_src
);

    assign data_size = funct3[1:0]; // 00: byte, 01: half-word, 10: word
    assign data_unsigned = funct3[2]; // byte or half-word unsigned

    always @* begin
        // By default don't enable any control signals
        reg_write   = 0;
        result_src  = `RESULT_SRC_UNDEFINED;
        mem_write   = 0;
        jump        = 0;
        branch      = 0;
        alu_control = `ALU_UNDEFINED;
        alu_src     = `ALU_SRC_B_UNDEFINED;
        imm_src     = `IMM_UNDEFINED;

        casex (opcode)
            // R-type arithmetic / logic (OP & OP with M extension)
            `OPCODE_OP: begin
                reg_write  = 1;
                result_src = `RESULT_SRC_ALU;
                alu_src    = `ALU_SRC_B_MUX;
                casex ({funct7,funct3})
                    {7'b0000000,3'b000}: alu_control = `ALU_ADD;
                    {7'b0100000,3'b000}: alu_control = `ALU_SUB;
                    {7'b0000000,3'b001}: alu_control = `ALU_SLL;
                    {7'b0000000,3'b010}: alu_control = `ALU_SLT;
                    {7'b0000000,3'b011}: alu_control = `ALU_SLTU;
                    {7'b0000000,3'b100}: alu_control = `ALU_XOR;
                    {7'b0000000,3'b101}: alu_control = `ALU_SRL;
                    {7'b0100000,3'b101}: alu_control = `ALU_SRA;
                    {7'b0000000,3'b110}: alu_control = `ALU_OR; 
                    {7'b0000000,3'b111}: alu_control = `ALU_AND;
                
                    {7'b0000001,3'b000}: alu_control = `ALU_MUL;  
                    {7'b0000001,3'b001}: alu_control = `ALU_MULH; 
                    {7'b0000001,3'b010}: alu_control = `ALU_MULHSU;
                    {7'b0000001,3'b011}: alu_control = `ALU_MULHU;
                    {7'b0000001,3'b100}: alu_control = `ALU_DIV;  
                    {7'b0000001,3'b101}: alu_control = `ALU_DIVU; 
                    {7'b0000001,3'b110}: alu_control = `ALU_REM;  
                    {7'b0000001,3'b111}: alu_control = `ALU_REMU;

                    default: ;
                endcase
            end

            // I-type arithmetic immediate
            `OPCODE_OP_IMM: begin
                reg_write  = 1;
                result_src = `RESULT_SRC_ALU;
                imm_src    = `IMM_I;
                alu_src    = `ALU_SRC_B_IMMEDIATE;
                casex (funct3)
                    3'b000: alu_control = `ALU_ADD;
                    3'b010: alu_control = `ALU_SLT;
                    3'b011: alu_control = `ALU_SLTU;
                    3'b100: alu_control = `ALU_XOR;
                    3'b110: alu_control = `ALU_OR; 
                    3'b111: alu_control = `ALU_AND;
                    3'b001: alu_control = `ALU_SLL;
                    3'b101: alu_control = (funct7 == 7'b0100000) ? `ALU_SRA : `ALU_SRL;
                    default: ;
                endcase
            end

            // Loads
            `OPCODE_LOAD: begin
                reg_write   = 1; // write to register
                result_src  = `RESULT_SRC_LOAD; 
                imm_src     = `IMM_I;
                alu_src     = `ALU_SRC_B_IMMEDIATE;
                alu_control = `ALU_ADD; // address calculation (rs1 content + immediate)
            end

            // Stores
            `OPCODE_STORE: begin
                mem_write  = 1; // write to memory
                imm_src    = `IMM_S;
                alu_src    = `ALU_SRC_B_IMMEDIATE;
                alu_control= `ALU_ADD; // address calculation (rs1 content + immediate)
            end

            // Branches
            `OPCODE_BRANCH: begin
                branch     = 1;
                imm_src    = `IMM_B;
                alu_src    = `ALU_SRC_B_MUX;
                casex (funct3)
                    3'b000: alu_control = `ALU_XOR;
                    3'b001: alu_control = `ALU_SNE;
                    3'b100: alu_control = `ALU_SLT;
                    3'b101: alu_control = `ALU_SGE;
                    3'b110: alu_control = `ALU_SLTU;
                    3'b111: alu_control = `ALU_SGEU;
                    default: ;
                endcase
            end

            // JAL
            `OPCODE_JAL: begin
                jump        = 1;
                reg_write   = 1;
                result_src  = `RESULT_SRC_PC4; // writes return address
                imm_src     = `IMM_J;
                alu_src     = `ALU_SRC_B_IMMEDIATE;
                alu_control = `ALU_ADD;
            end

            // JALR
            `OPCODE_JALR: begin
                jump        = 1;
                reg_write   = 1;
                result_src  = `RESULT_SRC_PC4; // writes return address
                imm_src     = `IMM_I;
                alu_src     = `ALU_SRC_B_IMMEDIATE;
                alu_control = `ALU_ADD;
            end

            // LUI
            `OPCODE_LUI: begin
                reg_write   = 1;
                result_src  = `RESULT_SRC_ALU;
                imm_src     = `IMM_U;
                alu_src     = `ALU_SRC_B_IMMEDIATE;
                alu_control = `ALU_COPYB; // pass immediate (assuming ALU B input = imm)
            end

            // AUIPC
            `OPCODE_AUIPC: begin
                reg_write  = 1;
                result_src = `RESULT_SRC_ALU;
                imm_src    = `IMM_U;
                alu_src    = `ALU_SRC_B_IMMEDIATE;
                alu_control= `ALU_ADD;
            end

            default: ;
        endcase
    end

endmodule
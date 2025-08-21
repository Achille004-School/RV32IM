`include "../src/static/alu_control.vh"

module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [4:0] alu_control,
    output reg [31:0] result,
    output wire zero
);

    assign zero = (result == 32'b0);

    always @* begin
        casex (alu_control)
            `ALU_ADD: result = a + b;
            `ALU_SUB: result = a - b;
            `ALU_AND: result = a & b;
            `ALU_OR: result = a | b;
            `ALU_XOR: result = a ^ b;
            `ALU_SLL: result = a << b[4:0];
            `ALU_SRL: result = a >> b[4:0];
            `ALU_SRA: result = $signed(a) >>> b[4:0]; // >>> is signed right shift

            `ALU_SLT: result = (a < b) ? 1 : 0;
            `ALU_SLTU: result = ($unsigned(a) < $unsigned(b)) ? 1 : 0;
            `ALU_SGE: result = (a >= b) ? 1 : 0;
            `ALU_SGEU: result = ($unsigned(a) >= $unsigned(b)) ? 1 : 0;
            `ALU_SNE: result = (a != b) ? 1 : 0;

            `ALU_COPYB: result = b;

            `ALU_MUL: result = a * b;
            `ALU_MULH: result = (a * b) >> 32;
            `ALU_MULHSU: result = ($signed(a) * $unsigned(b)) >> 32;
            `ALU_MULHU: result = ($unsigned(a) * $unsigned(b)) >> 32;
            `ALU_DIV: result = a / b;
            `ALU_DIVU: result = $unsigned(a) / $unsigned(b);
            `ALU_REM: result = a % b;
            `ALU_REMU: result = $unsigned(a) % $unsigned(b);

            default: result = 32'bx; // Undefined operation
        endcase
    end
endmodule
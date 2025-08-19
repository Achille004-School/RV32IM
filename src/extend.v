`include "static/immediate_sources.vh"

module extend (
    input  		[24:0] imm,
    input  		[2:0]  imm_src,
    output reg 	[31:0] imm_ext
);

    always @ (*) begin
        case (ImmSrcD)
            IMM_I:  imm_ext = {{20{Imm[24]}}, Imm[24:13]};                            // I-type
            IMM_S:  imm_ext = {{20{Imm[24]}}, Imm[24:18], Imm[4:0]};                  // S-type
            IMM_B:  imm_ext = {{20{Imm[24]}}, Imm[0],  Imm[23:18], Imm[4:1], 1'b0};   // B-type
            IMM_J:  imm_ext = {{12{Imm[24]}}, Imm[12:5],  Imm[13], Imm[23:14], 1'b0}; // J-type
            IMM_U:  imm_ext = {Imm[24:5], 12'b0};                                     // U_type
            default: imm_ext = 32'dx;                                                 // undefined
        endcase
    end
endmodule
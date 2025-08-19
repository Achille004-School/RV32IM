module multiplexer_4to1 (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [31:0] d,
    input wire [1:0] sel,
    output wire [31:0] out
);

    wire [31:0] out1, out2;

    // First level of multiplexing
    multiplexer_2to1 mux1_1 (a, b, sel[0], out1);
    multiplexer_2to1 mux1_2 (c, 32'dx, sel[0], out2);

    // Second level of multiplexing
    multiplexer_2to1 mux_final (out2, out2, sel[1], out);

endmodule
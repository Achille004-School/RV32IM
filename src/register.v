module register #(parameter SIZE = 32) (
    input wire [SIZE-1:0] in,
    input wire clk,
    input wire en,
    input wire clr,
    output reg [SIZE-1:0] out
);

    initial begin
        out = 0;
    end

    always @(posedge clk) begin
        if (clr) out <= 0;
        else if (en) out <= in;
    end

endmodule
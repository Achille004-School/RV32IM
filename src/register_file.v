module register_file(
    input wire [31:0] address_1,
    input wire [31:0] address_2,
    input wire [31:0] address_3,
    input wire [31:0] write_data,
    input wire write_enable,
    input wire clk,
    output wire [31:0] read_data_1,
    output wire [31:0] read_data_2,
);

    reg [31:0] registers [0:31];

    initial begin
        for (integer i = 0; i < 32; i = i + 1) registers[i] = 32'b0;
    end

    assign read_data_1 = registers[address_1];
    assign read_data_2 = registers[address_2];

    always @(posedge clk) begin
        if (write_enable and address_3 != 32'b0) registers[address_3] <= write_data;
    end

endmodule
// High-level behavioral memory implementation using a large array.
// Not a hardware-accurate model of multiplexed memory chips.
module data_memory (
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [1:0] data_size,    // 00: byte, 01: half-word, 10: word
    input wire clk,
    input wire write_enable,
    input wire data_unsigned,
    output reg [31:0] read_data
);

    // 1 Mi-bytes -> 256 Ki-words
    localparam SIZE = 1048576;
    localparam ADDRESS_BITS = 20;
    
    // Declare variables
    integer i, byte_count; 

    reg [7:0] memory [0:SIZE-1];
    wire [ADDRESS_BITS-1:0] CUR_ADDR = address[ADDRESS_BITS-1:0];

    initial $readmemh("data.hex", memory);

    always @(posedge clk) begin
        if ($unsigned(data_size) != 3) begin 
            byte_count = 1 << $unsigned(data_size);

            if (write_enable) begin
                for (i = 0; i < byte_count; i = i + 1)
                    memory[CUR_ADDR + i] = write_data[i*8 +: 8];
            end

            // Read data
            for (i = 0; i < byte_count; i = i + 1)
                read_data[i*8 +: 8] = memory[CUR_ADDR + i];

            // Sign extend the upper bytes
            for (i = byte_count; i < 4; i = i + 1)
                read_data[i*8 +: 8] = data_unsigned ? 8'b0 : {8{read_data[byte_count*8 - 1]}};
        end else begin
            read_data <= 32'bx; // Undefined operation
        end
    end

endmodule
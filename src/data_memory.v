// High-level behavioral memory implementation using a large array.
// Not a hardware-accurate model of multiplexed memory chips.
module data_memory (
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [1:0] data_size,    // 00: byte, 01: half-word, 10: word
    input wire data_unsigned,
    input wire write_enable,
    input wire clk,
    output reg [31:0] read_data
);

    // 1 Mi-bytes -> 256 Ki-words
    localparam SIZE = 1048576;
    localparam ADDRESS_BITS = 20;
    
    // Declare variables
    integer i, byte_count; 

    reg [7:0] memory [0:SIZE-1];
    wire [ADDRESS_BITS-1:0] CUR_ADDR = address[ADDRESS_BITS-1:0];
    reg data_changed = 0;

    initial $readmemh("data.mem", memory);

    always @(posedge clk) begin
        if (write_enable && $unsigned(data_size) != 3) begin 
            byte_count = 1 << $unsigned(data_size);
            for (i = 0; i < byte_count; i = i + 1)
                memory[CUR_ADDR + i] = write_data[i*8 +: 8];
            data_changed = 1;
        end
    end

    always @(posedge ~clk) data_changed = 0;

    always @(CUR_ADDR, data_size, data_unsigned, posedge data_changed) begin
        if ($unsigned(data_size) != 3) begin
            read_data = 32'b0;
            byte_count = 1 << $unsigned(data_size);
            
            // Read bytes
            for (i = 0; i < byte_count; i = i + 1)
                read_data[i*8 +: 8] = memory[CUR_ADDR + i];
            
            // Sign extend if needed
            if (!data_unsigned && byte_count < 4)
                for (i = byte_count; i < 4; i = i + 1)
                    read_data[i*8 +: 8] = {8{read_data[byte_count*8 - 1]}};
        end else begin
            read_data = 32'bx;
        end
    end

endmodule
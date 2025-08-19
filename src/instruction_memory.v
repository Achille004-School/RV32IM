// High-level behavioral memory implementation using a large array.
// Not a hardware-accurate model of multiplexed memory chips.
module instruction_memory (
    input wire [31:0] address,
    output reg [31:0] instruction
);

    // 64 Ki-instructions
    localparam SIZE = 65536;
    localparam ADDRESS_BITS = 16;

    reg [31:0] memory [0:SIZE-1];

    initial $readmemh("instructions.hex", memory);

    assign instruction = memory[address[ADDRESS_BITS-1:0]];

endmodule
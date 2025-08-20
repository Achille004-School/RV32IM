`include "../src/processor.v"

`timescale 1ns / 1ps

module run_example;

    // Inputs
    reg clk;
    wire [31:0] DEBUG_INSTRUCTION, DEBUG_PC, DEBUG_RESULT;

    // Instantiate the processor module
    processor dut (clk, DEBUG_INSTRUCTION, DEBUG_PC, DEBUG_RESULT);

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset the processor
    initial begin
        $dumpfile("run_example.vcd");
        $dumpvars(0, run_example);

        $finish(1000); // Stop simulation after 1000 time units
    end

endmodule
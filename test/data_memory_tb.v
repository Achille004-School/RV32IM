`timescale 1ns / 1ps

module data_memory_tb;
    // Inputs
    reg [31:0] wd;
    reg [31:0] a;
    reg [1:0] data_size; // 00: byte, 01: half-word, 10: word
    reg clk;
    reg we;
    reg data_unsigned; // 0: signed, 1: unsigned

    // Output
    wire [31:0] rd;

    // Instantiate the memory module with named ports
    data_memory dut (a, wd, data_size, data_unsigned, we, clk, rd);

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Simple check task
    task check_eq;
        input [31:0] expected;
        input [31:0] actual;
        input [511:0] name;
        begin
            if (expected === actual)
                $display("[PASS] %s: expected=0x%08h, got=0x%08h", name, expected, actual);
            else begin
                $display("[FAIL] %s: expected=0x%08h, got=0x%08h", name, expected, actual);
            end
        end
    endtask

    // Test sequence
    initial begin
        $dumpfile("data_memory_tb.vcd");
        $dumpvars(0, data_memory_tb);

        // Initialize signals
        a = 0;
        wd = 0;
        data_size = 2'b10; // default to word
        we = 0;
        data_unsigned = 0; // default to signed

        // Wait a couple cycles for simulator
        #1;
        @(posedge ~clk);
        @(posedge ~clk);

        // Test 1: Word write/read at address 0
        a = 32'h0000_0000;
        wd = 32'hDEAD_BEEF;
        data_size = 2'b10; // word
        we = 1;
        @(posedge ~clk); // perform write+read on posedge
        check_eq(32'hDEAD_BEEF, rd, "Word write/read @0");

        // Turn off write enable and read back
        we = 0;
        @(posedge ~clk);
        check_eq(32'hDEAD_BEEF, rd, "Word read back @0 (no write)");

        // Test 2: Byte write/read at address 4
        a = 32'h0000_0004;
        wd = 32'h0000_00A5; // only low byte is written
        data_size = 2'b00; // byte
        we = 1;
        @(posedge ~clk);
        check_eq(32'hFFFFFFA5, rd, "Byte write/read @4 (signed)");

        we = 0;
        data_unsigned = 1;
        @(posedge ~clk);
        check_eq(32'h000000A5, rd, "Byte read back @4 (no write, unsigned)");

        // Test 3: Half-word write/read at address 8
        a = 32'h0000_0008;
        wd = 32'h0000_8001; // low 16 bits = 0x8001
        data_size = 2'b01; // half-word
        we = 1;
        data_unsigned = 0;
        @(posedge ~clk);
        check_eq(32'hFFFF8001, rd, "Half write/read @8 (signed)");

        we = 0;
        data_unsigned = 1;
        @(posedge ~clk);
        check_eq(32'h00008001, rd, "Half read back @8 (no write, unsigned)");

        $display("All tests completed.");
        $finish;
    end
endmodule

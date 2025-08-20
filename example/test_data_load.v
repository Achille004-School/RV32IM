`include "../src/data_memory.v"

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

    // Override the memory initialization for testing
    initial begin
        // Load test data manually since we want specific hex values
        // .word data (little-endian):
        dut.memory[0] = 8'hEF; dut.memory[1] = 8'hBE; dut.memory[2] = 8'hAD; dut.memory[3] = 8'hDE; // 0xDEADBEEF
        dut.memory[4] = 8'hBE; dut.memory[5] = 8'hBA; dut.memory[6] = 8'hFE; dut.memory[7] = 8'hCA; // 0xCAFEBABE
        dut.memory[8] = 8'h78; dut.memory[9] = 8'h56; dut.memory[10] = 8'h34; dut.memory[11] = 8'h12; // 0x12345678
        dut.memory[12] = 8'hF0; dut.memory[13] = 8'hDE; dut.memory[14] = 8'hBC; dut.memory[15] = 8'h9A; // 0x9ABCDEF0
        
        // .half data (little-endian):
        dut.memory[16] = 8'h34; dut.memory[17] = 8'h12; // 0x1234
        dut.memory[18] = 8'h78; dut.memory[19] = 8'h56; // 0x5678
        dut.memory[20] = 8'hBC; dut.memory[21] = 8'h9A; // 0x9ABC
        dut.memory[22] = 8'hF0; dut.memory[23] = 8'hDE; // 0xDEF0
        
        // .byte data:
        dut.memory[24] = 8'h12;
        dut.memory[25] = 8'h34;
        dut.memory[26] = 8'h56;
        dut.memory[27] = 8'h78;
        dut.memory[28] = 8'h9A;
        dut.memory[29] = 8'hBC;
        dut.memory[30] = 8'hDE;
        dut.memory[31] = 8'hF0;
    end

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
        $dumpfile("test_data_load.vcd");
        $dumpvars(0, data_memory_tb);

        we = 0;
        data_unsigned = 1;

        // Test reading .word values (32-bit)
        // Data layout (little-endian):
        // Address 0x00: 0xDEADBEEF -> EF BE AD DE
        // Address 0x04: 0xCAFEBABE -> BE BA FE CA  
        // Address 0x08: 0x12345678 -> 78 56 34 12
        // Address 0x0C: 0x9ABCDEF0 -> F0 DE BC 9A
        
        $display("Testing .word data (32-bit reads):");
        
        // Test word at address 0x00 (0xDEADBEEF)
        a = 32'h00000000;
        data_size = 2'b10; // word
        #10;
        check_eq(32'hDEADBEEF, rd, "Word read at 0x00");
        
        // Test word at address 0x04 (0xCAFEBABE)
        a = 32'h00000004;
        data_size = 2'b10; // word
        #10;
        check_eq(32'hCAFEBABE, rd, "Word read at 0x04");
        
        // Test word at address 0x08 (0x12345678)
        a = 32'h00000008;
        data_size = 2'b10; // word
        #10;
        check_eq(32'h12345678, rd, "Word read at 0x08");
        
        // Test word at address 0x0C (0x9ABCDEF0)
        a = 32'h0000000C;
        data_size = 2'b10; // word
        #10;
        check_eq(32'h9ABCDEF0, rd, "Word read at 0x0C");
        
        // Test reading .half values (16-bit)
        // Data layout (little-endian, starting at 0x10):
        // Address 0x10: 0x1234 -> 34 12
        // Address 0x12: 0x5678 -> 78 56
        // Address 0x14: 0x9ABC -> BC 9A
        // Address 0x16: 0xDEF0 -> F0 DE
        
        $display("Testing .half data (16-bit reads):");
        
        // Test signed half-words
        data_unsigned = 0; // signed
        
        // Test half at address 0x10 (0x1234)
        a = 32'h00000010;
        data_size = 2'b01; // half-word
        #10;
        check_eq(32'h00001234, rd, "Signed half read at 0x10");
        
        // Test half at address 0x12 (0x5678)
        a = 32'h00000012;
        data_size = 2'b01; // half-word
        #10;
        check_eq(32'h00005678, rd, "Signed half read at 0x12");
        
        // Test half at address 0x14 (0x9ABC) - should sign extend
        a = 32'h00000014;
        data_size = 2'b01; // half-word
        #10;
        check_eq(32'hFFFF9ABC, rd, "Signed half read at 0x14 (sign extended)");
        
        // Test half at address 0x16 (0xDEF0) - should sign extend
        a = 32'h00000016;
        data_size = 2'b01; // half-word
        #10;
        check_eq(32'hFFFFDEF0, rd, "Signed half read at 0x16 (sign extended)");
        
        // Test unsigned half-words
        data_unsigned = 1; // unsigned
        
        // Test half at address 0x14 (0x9ABC) - should zero extend
        a = 32'h00000014;
        data_size = 2'b01; // half-word
        #10;
        check_eq(32'h00009ABC, rd, "Unsigned half read at 0x14 (zero extended)");
        
        // Test half at address 0x16 (0xDEF0) - should zero extend
        a = 32'h00000016;
        data_size = 2'b01; // half-word
        #10;
        check_eq(32'h0000DEF0, rd, "Unsigned half read at 0x16 (zero extended)");
        
        // Test reading .byte values (8-bit)
        // Data layout (starting at 0x18):
        // Address 0x18: 0x12
        // Address 0x19: 0x34
        // Address 0x1A: 0x56
        // Address 0x1B: 0x78
        // Address 0x1C: 0x9A
        // Address 0x1D: 0xBC
        // Address 0x1E: 0xDE
        // Address 0x1F: 0xF0
        
        $display("Testing .byte data (8-bit reads):");
        
        // Test signed bytes
        data_unsigned = 0; // signed
        
        // Test byte at address 0x18 (0x12)
        a = 32'h00000018;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h00000012, rd, "Signed byte read at 0x18");
        
        // Test byte at address 0x19 (0x34)
        a = 32'h00000019;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h00000034, rd, "Signed byte read at 0x19");
        
        // Test byte at address 0x1A (0x56)
        a = 32'h0000001A;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h00000056, rd, "Signed byte read at 0x1A");
        
        // Test byte at address 0x1B (0x78)
        a = 32'h0000001B;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h00000078, rd, "Signed byte read at 0x1B");
        
        // Test byte at address 0x1C (0x9A) - should sign extend
        a = 32'h0000001C;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'hFFFFFF9A, rd, "Signed byte read at 0x1C (sign extended)");
        
        // Test byte at address 0x1D (0xBC) - should sign extend
        a = 32'h0000001D;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'hFFFFFFBC, rd, "Signed byte read at 0x1D (sign extended)");
        
        // Test byte at address 0x1E (0xDE) - should sign extend
        a = 32'h0000001E;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'hFFFFFFDE, rd, "Signed byte read at 0x1E (sign extended)");
        
        // Test byte at address 0x1F (0xF0) - should sign extend
        a = 32'h0000001F;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'hFFFFFFF0, rd, "Signed byte read at 0x1F (sign extended)");
        
        // Test unsigned bytes
        data_unsigned = 1; // unsigned
        
        // Test byte at address 0x1C (0x9A) - should zero extend
        a = 32'h0000001C;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h0000009A, rd, "Unsigned byte read at 0x1C (zero extended)");
        
        // Test byte at address 0x1D (0xBC) - should zero extend
        a = 32'h0000001D;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h000000BC, rd, "Unsigned byte read at 0x1D (zero extended)");
        
        // Test byte at address 0x1E (0xDE) - should zero extend
        a = 32'h0000001E;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h000000DE, rd, "Unsigned byte read at 0x1E (zero extended)");
        
        // Test byte at address 0x1F (0xF0) - should zero extend
        a = 32'h0000001F;
        data_size = 2'b00; // byte
        #10;
        check_eq(32'h000000F0, rd, "Unsigned byte read at 0x1F (zero extended)");
        
        // Test unaligned access scenarios
        $display("Testing unaligned access:");
        
        // Test word read at unaligned address (should read from aligned boundary)
        a = 32'h00000001;
        data_size = 2'b10; // word
        #10;
        // This should read the word that includes bytes at 0x01, 0x02, 0x03, 0x04
        // Based on little-endian: bytes BE AD DE BE -> 0xCADEADBE
        check_eq(32'hBEDEADBE, rd, "Word read at unaligned 0x01");
        
        // Test half-word read at unaligned address
        a = 32'h00000001;
        data_size = 2'b01; // half-word
        data_unsigned = 1; // unsigned
        #10;
        // This should read bytes at 0x01, 0x02: BE AD -> 0xADBE
        check_eq(32'h0000ADBE, rd, "Half read at unaligned 0x01");

        $display("All tests completed.");
        $finish;
    end
endmodule

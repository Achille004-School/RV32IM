module hazard_unit (
    input wire [4:0] rs1_d,
    input wire [4:0] rs2_d,
    input wire [4:0] rs1_e,
    input wire [4:0] rs2_e,
    input wire [4:0] rd_e,
    input wire pc_src_e,
    input wire [1:0] result_src_e,
    input wire reg_write_m,
    input wire [4:0] rd_m,
    input wire reg_write_w,
    input wire [4:0] rd_w,

    output reg stall_f,
    output reg stall_d,
    output reg flush_d,
    output reg flush_e,
    output reg [1:0] foward_a_e,
    output reg [1:0] foward_b_e
);

    ///// FOWARD HAZARD DETECTION /////
    // This detects if the instruction in the execute stage is trying to read from
    // a register which contents are not yet written back to the register file.

    // Foward A logic
    // 00 - rd1_e
    // 01 - result_w
    // 10 - alu_result_m
    always @(*) begin
        if (rs1_e == 5'b0)
            foward_a_e = 2'b00; // x0 is always zero, so DO NOT read its "future value" (will be discarded)
        else if (rs1_e == rd_m && reg_write_m) 
            foward_a_e = 2'b10; // Forward from memory stage
        else if (rs1_e == rd_w && reg_write_w) 
            foward_a_e = 2'b01; // Forward from writeback stage
        else 
            foward_a_e = 2'b00; // Default to register 1 data
    end

    // Foward B logic
    // 00 - rd2_e
    // 01 - result_w
    // 10 - alu_result_m
    always @(*) begin
        if (rs2_e == 5'b0)
            foward_b_e = 2'b00; // x0 is always zero, so DO NOT read its "future value" (will be discarded)
        else if (rs2_e == rd_m && reg_write_m) 
            foward_b_e = 2'b10; // Forward from memory stage
        else if (rs2_e == rd_w && reg_write_w) 
            foward_b_e = 2'b01; // Forward from writeback stage
        else 
            foward_b_e = 2'b00; // Default to register 1 data
    end

    ///// MEMORY HAZARD DETECTION /////
    // This detects if a stall and/or a flush is needed due to a memory hazard.

    integer load_dependency;
    always @(*) begin
        // Stall pipeline when decode stage instruction depends on a load instruction in execute stage
        // This prevents data hazards by ensuring the load completes before dependent instructions proceed
        load_dependency = (result_src_e == 2'b01 && (rs1_d == rd_e || rs2_d == rd_e));

        stall_f = load_dependency;
        stall_d = load_dependency;
        flush_d = pc_src_e; // Flush decode stage if we are branching
        flush_e = load_dependency || pc_src_e; // Flush if we are branching or if we have a stall condition (will be reloaded)
    end

endmodule
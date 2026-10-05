module writeback_unit (
    input  logic [31:0] alu_result,
    input  logic [31:0] memory_data,
    input  logic [31:0] pc_plus_4,
    input  logic        mem_to_reg,
    input  logic        jump,
    output logic [31:0] write_data
);

always_comb begin

    if (jump)
        write_data = pc_plus_4;
    else if (mem_to_reg)
        write_data = memory_data;
    else
        write_data = alu_result;

end

endmodule

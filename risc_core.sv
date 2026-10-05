import riscv_pkg::*;

module riscv_core (
    input logic clk,
    input logic rst
);

logic [31:0] pc;
logic [31:0] next_pc;

logic [31:0] instruction;

logic [6:0] opcode;
logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;
logic [2:0] funct3;
logic [6:0] funct7;

logic [31:0] immediate;

logic [31:0] read_data1;
logic [31:0] read_data2;

logic [31:0] alu_input_a;
logic [31:0] alu_input_b;
logic [31:0] alu_result;

logic [3:0] alu_op;

logic zero;
logic negative;
logic carry;
logic overflow;

logic reg_write;
logic mem_read;
logic mem_write;
logic mem_to_reg;
logic alu_src;
logic branch;
logic jump;
logic jalr;
logic lui;
logic auipc;

logic branch_taken;
logic [31:0] branch_target;

logic [31:0] memory_data;
logic [31:0] writeback_data;

logic [31:0] jump_target;

pc pc_unit (
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc(pc)
);

instruction_memory instruction_memory_unit (
    .address(pc),
    .instruction(instruction)
);

decoder decoder_unit (
    .instruction(instruction),
    .opcode(opcode),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .funct3(funct3),
    .funct7(funct7)
);

immediate_generator immediate_generator_unit (
    .instruction(instruction),
    .opcode(opcode),
    .immediate(immediate)
);

register_file register_file_unit (
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(writeback_data),
    .reg_write(reg_write),
    .read_data1(read_data1),
    .read_data2(read_data2)
);

control_unit control_unit_unit (
    .opcode(opcode),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_src(alu_src),
    .branch(branch),
    .jump(jump),
    .jalr(jalr),
    .lui(lui),
    .auipc(auipc)
);

alu_control alu_control_unit (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_op(alu_op)
);

always_comb begin
    if (auipc)
        alu_input_a = pc;
    else
        alu_input_a = read_data1;
end

always_comb begin
    if (alu_src)
        alu_input_b = immediate;
    else
        alu_input_b = read_data2;
end

alu alu_unit (
    .a(alu_input_a),
    .b(alu_input_b),
    .alu_op(alu_op),
    .result(alu_result),
    .zero(zero),
    .negative(negative),
    .carry(carry),
    .overflow(overflow)
);

data_memory data_memory_unit (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .address(alu_result),
    .write_data(read_data2),
    .read_data(memory_data)
);

writeback_unit writeback_unit_unit (
    .alu_result(alu_result),
    .memory_data(memory_data),
    .pc_plus_4(pc + 32'd4),
    .mem_to_reg(mem_to_reg),
    .jump(jump),
    .write_data(writeback_data)
);

branch_unit branch_unit_unit (
    .pc(pc),
    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .immediate(immediate),
    .funct3(funct3),
    .branch(branch),
    .branch_taken(branch_taken),
    .branch_target(branch_target)
);

always_comb begin

    if (jalr)
        jump_target = (read_data1 + immediate) & 32'hFFFFFFFE;
    else
        jump_target = pc + immediate;

end

always_comb begin

    next_pc = pc + 32'd4;

    if (branch && branch_taken)
        next_pc = branch_target;

    if (jump)
        next_pc = jump_target;

end

endmodule

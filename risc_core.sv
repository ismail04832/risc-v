import riscv_pkg::*;

module riscv_core (
    input logic clk,
    input logic rst
);

// Signaux de contrôle et d'états
logic        reg_write, mem_read, mem_write, mem_to_reg;
logic        alu_src_a, branch, jump, jalr, lui, auipc;
logic [1:0]  alu_src_b;
logic        ir_write, pc_write, pc_write_cond, i_ord;

logic [31:0] pc, next_pc, mem_addr;
logic [31:0] instruction;
logic [6:0]  opcode;
logic [4:0]  rd, rs1, rs2;
logic [2:0]  funct3;
logic [6:0]  funct7;

logic [31:0] immediate;
logic [31:0] reg_rdata1, reg_rdata2;
logic [31:0] alu_input_a, alu_input_b, alu_result;
logic [3:0]  alu_op;
logic        zero, negative, carry, overflow;

logic [31:0] memory_data;
logic [31:0] writeback_data;
logic [31:0] branch_target, jump_target;
logic        branch_taken;

// Registres intermédiaires (Multi-Cycle)
logic [31:0] ir_reg;
logic [31:0] a_reg, b_reg;
logic [31:0] alu_out_reg;
logic [31:0] mdr_reg;

// 1. Gestion du PC
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        pc <= 32'b0;
    else if (pc_write || (pc_write_cond && branch_taken))
        pc <= alu_result; // Le PC est mis à jour depuis l'ALU
end

// 2. Sélection de l'adresse mémoire (i_ord)
assign mem_addr = i_ord ? alu_out_reg : pc;

// 3. Mémoire Unifiée
memory memory_unit (
    .clk(clk),
    .we(mem_write),
    .oe(mem_read),
    .addr(mem_addr),
    .write_data(b_reg),
    .read_data(memory_data)
);

// 4. Registre IR (Instruction Register)
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        ir_reg <= 32'b0;
    else if (ir_write)
        ir_reg <= memory_data;
end

assign instruction = ir_reg;

// 5. Décodeur
decoder decoder_unit (
    .instruction(instruction),
    .opcode(opcode),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .funct3(funct3),
    .funct7(funct7)
);

// 6. Générateur d'immédiats
immediate_generator immediate_generator_unit (
    .instruction(instruction),
    .opcode(opcode),
    .immediate(immediate)
);

// 7. Banc de registres
register_file register_file_unit (
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(writeback_data),
    .reg_write(reg_write),
    .read_data1(reg_rdata1),
    .read_data2(reg_rdata2)
);

// Sauvegarde dans les registres A et B
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        a_reg <= 32'b0;
        b_reg <= 32'b0;
    end else begin
        a_reg <= reg_rdata1;
        b_reg <= reg_rdata2;
    end
end

// 8. Unité de Contrôle (FSM)
control_unit control_unit_unit (
    .clk(clk),
    .rst(rst),
    .opcode(opcode),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_src_a(alu_src_a),
    .alu_src_b(alu_src_b),
    .branch(branch),
    .jump(jump),
    .jalr(jalr),
    .lui(lui),
    .auipc(auipc),
    .ir_write(ir_write),
    .pc_write(pc_write),
    .pc_write_cond(pc_write_cond),
    .i_ord(i_ord)
);

// 9. Contrôle ALU
alu_control alu_control_unit (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_op(alu_op)
);

// 10. Mux entrées ALU (Partagée)
always_comb begin
    if (alu_src_a)
        alu_input_a = a_reg;
    else
        alu_input_a = pc; // Utilisé pendant le fetch pour PC + 4
end

always_comb begin
    case (alu_src_b)
        2'b00: alu_input_b = b_reg;
        2'b01: alu_input_b = immediate;
        2'b10: alu_input_b = 32'd4; // Incrémentation PC
        default: alu_input_b = b_reg;
    endcase
end

// 11. ALU principale
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

// Enregistrement du résultat ALU dans ALUOut
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        alu_out_reg <= 32'b0;
    else
        alu_out_reg <= alu_result;
end

// 12. Registre MDR (Memory Data Register)
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        mdr_reg <= 32'b0;
    else
        mdr_reg <= memory_data;
end

// 13. Unité Write-Back
writeback_unit writeback_unit_unit (
    .alu_result(alu_out_reg),
    .memory_data(mdr_reg),
    .pc_plus_4(alu_out_reg),
    .mem_to_reg(mem_to_reg),
    .jump(jump),
    .write_data(writeback_data)
);

// 14. Unité de branchement
branch_unit branch_unit_unit (
    .pc(pc),
    .rs1_data(a_reg),
    .rs2_data(b_reg),
    .immediate(immediate),
    .funct3(funct3),
    .branch(branch),
    .branch_taken(branch_taken),
    .branch_target(branch_target)
);

endmodule
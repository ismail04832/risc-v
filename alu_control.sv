import riscv_pkg::*;

module alu_control (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_op
);

always_comb begin
    alu_op = ALU_ADD;

    case (opcode)

        OP_R: begin
            case (funct3)

                3'b000: begin
                    if (funct7 == FUNCT7_ALT)
                        alu_op = ALU_SUB;
                    else
                        alu_op = ALU_ADD;
                end

                3'b001: alu_op = ALU_SLL;
                3'b010: alu_op = ALU_SLT;
                3'b011: alu_op = ALU_SLTU;
                3'b100: alu_op = ALU_XOR;

                3'b101: begin
                    if (funct7 == FUNCT7_ALT)
                        alu_op = ALU_SRA;
                    else
                        alu_op = ALU_SRL;
                end

                3'b110: alu_op = ALU_OR;
                3'b111: alu_op = ALU_AND;

                default: alu_op = ALU_ADD;

            endcase
        end

        OP_IMM: begin
            case (funct3)

                3'b000: alu_op = ALU_ADD;
                3'b010: alu_op = ALU_SLT;
                3'b011: alu_op = ALU_SLTU;
                3'b100: alu_op = ALU_XOR;
                3'b110: alu_op = ALU_OR;
                3'b111: alu_op = ALU_AND;
                3'b001: alu_op = ALU_SLL;

                3'b101: begin
                    if (funct7 == FUNCT7_ALT)
                        alu_op = ALU_SRA;
                    else
                        alu_op = ALU_SRL;
                end

                default: alu_op = ALU_ADD;

            endcase
        end

        OP_LOAD:  alu_op = ALU_ADD;
        OP_STORE: alu_op = ALU_ADD;
        OP_BRANCH: alu_op = ALU_SUB;
        OP_JALR:  alu_op = ALU_ADD;
        OP_AUIPC: alu_op = ALU_ADD;

        default: alu_op = ALU_ADD;

    endcase
end

endmodule

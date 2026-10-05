import riscv_pkg::*;

module control_unit (
    input  logic [6:0] opcode,
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src,
    output logic       branch,
    output logic       jump,
    output logic       jalr,
    output logic       lui,
    output logic       auipc
);

always_comb begin

    reg_write  = 1'b0;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    mem_to_reg = 1'b0;
    alu_src    = 1'b0;
    branch     = 1'b0;
    jump       = 1'b0;
    jalr       = 1'b0;
    lui        = 1'b0;
    auipc      = 1'b0;

    case (opcode)

        OP_R: begin
            reg_write = 1'b1;
        end

        OP_IMM: begin
            reg_write = 1'b1;
            alu_src   = 1'b1;
        end

        OP_LOAD: begin
            reg_write  = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
            alu_src    = 1'b1;
        end

        OP_STORE: begin
            mem_write = 1'b1;
            alu_src   = 1'b1;
        end

        OP_BRANCH: begin
            branch = 1'b1;
        end

        OP_JAL: begin
            jump      = 1'b1;
            reg_write = 1'b1;
        end

        OP_JALR: begin
            jump      = 1'b1;
            jalr      = 1'b1;
            reg_write = 1'b1;
            alu_src   = 1'b1;
        end

        OP_LUI: begin
            reg_write = 1'b1;
            lui       = 1'b1;
            alu_src   = 1'b1;
        end

        OP_AUIPC: begin
            reg_write = 1'b1;
            auipc     = 1'b1;
            alu_src   = 1'b1;
        end

        default: begin
            reg_write = 1'b0;
        end

    endcase

end

endmodule

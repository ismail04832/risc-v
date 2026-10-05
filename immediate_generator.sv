import riscv_pkg::*;

module immediate_generator (
    input  logic [31:0] instruction,
    input  logic [6:0]  opcode,
    output logic [31:0] immediate
);

always_comb begin

    case (opcode)

        OP_IMM,
        OP_LOAD,
        OP_JALR: begin
            immediate = {{20{instruction[31]}},
                         instruction[31:20]};
        end

        OP_STORE: begin
            immediate = {{20{instruction[31]}},
                         instruction[31:25],
                         instruction[11:7]};
        end

        OP_BRANCH: begin
            immediate = {{19{instruction[31]}},
                         instruction[31],
                         instruction[7],
                         instruction[30:25],
                         instruction[11:8],
                         1'b0};
        end

        OP_LUI,
        OP_AUIPC: begin
            immediate = {instruction[31:12], 12'b0};
        end

        OP_JAL: begin
            immediate = {{11{instruction[31]}},
                         instruction[31],
                         instruction[19:12],
                         instruction[20],
                         instruction[30:21],
                         1'b0};
        end

        default: begin
            immediate = 32'b0;
        end

    endcase

end

endmodule

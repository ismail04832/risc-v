import riscv_pkg::*;

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_op,
    output logic [31:0] result,
    output logic        zero,
    output logic        negative,
    output logic        carry,
    output logic        overflow
);

logic [32:0] temp;

always_comb begin
    result   = 32'b0;
    carry    = 1'b0;
    overflow = 1'b0;
    temp     = 33'b0;

    case (alu_op)

        ALU_ADD: begin
            temp = {1'b0, a} + {1'b0, b};
            result = temp[31:0];
            carry = temp[32];
            overflow = (~(a[31] ^ b[31])) & (result[31] ^ a[31]);
        end

        ALU_SUB: begin
            temp = {1'b0, a} - {1'b0, b};
            result = temp[31:0];
            carry = temp[32];
            overflow = (a[31] ^ b[31]) & (result[31] ^ a[31]);
        end

        ALU_AND:  result = a & b;
        ALU_OR:   result = a | b;
        ALU_XOR:  result = a ^ b;
        ALU_SLL:  result = a << b[4:0];
        ALU_SRL:  result = a >> b[4:0];
        ALU_SRA:  result = $signed(a) >>> b[4:0];
        ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
        ALU_SLTU: result = (a < b) ? 32'b1 : 32'b0;

        default: result = 32'b0;

    endcase
end

always_comb begin
    zero     = (result == 32'b0);
    negative = result[31];
end

endmodule

module branch_unit (
    input  logic [31:0] pc,
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] immediate,
    input  logic [2:0]  funct3,
    input  logic        branch,
    output logic        branch_taken,
    output logic [31:0] branch_target
);

always_comb begin

    branch_taken  = 1'b0;
    branch_target = pc + immediate;

    if (branch) begin
        case (funct3)

            3'b000: branch_taken = (rs1_data == rs2_data);
            3'b001: branch_taken = (rs1_data != rs2_data);
            3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));
            3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
            3'b110: branch_taken = (rs1_data < rs2_data);
            3'b111: branch_taken = (rs1_data >= rs2_data);

            default: branch_taken = 1'b0;

        endcase
    end

end

endmodule

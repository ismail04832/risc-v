module register_file (
    input  logic        clk,
    input  logic        rst,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    input  logic        reg_write,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

logic [31:0] registers [0:31];

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 32; i++)
            registers[i] <= 32'b0;
    end
    else if (reg_write && (rd != 5'b0)) begin
        registers[rd] <= write_data;
    end
end

always_comb begin
    if (rs1 == 5'b0)
        read_data1 = 32'b0;
    else
        read_data1 = registers[rs1];

    if (rs2 == 5'b0)
        read_data2 = 32'b0;
    else
        read_data2 = registers[rs2];
end

endmodule

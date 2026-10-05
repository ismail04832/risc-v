module instruction_memory #(
    parameter DEPTH = 8
)(
    input  logic [31:0] address,
    output logic [31:0] instruction
);

logic [31:0] ROM [0:DEPTH-1];

always_comb begin
    instruction = ROM[address[31:2]];
end

endmodule

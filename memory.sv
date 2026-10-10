module memory #(
    parameter DEPTH = 256
)(
    input  logic        clk,
    input  logic        we,          // mem_write
    input  logic        oe,          // mem_read
    input  logic [31:0] addr,        // PC ou ALUOut
    input  logic [31:0] write_data,  // Reg B
    output logic [31:0] read_data    // Vers IR ou MDR
);

    logic [31:0] ram [0:DEPTH-1];

    // Lecture combinatoire asynchrone
    assign read_data = ram[addr[31:2]];

    // Écriture synchrone
    always_ff @(posedge clk) begin
        if (we) begin
            ram[addr[31:2]] <= write_data;
        end
    end

endmodule
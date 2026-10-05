package riscv_pkg;

localparam logic [6:0] OP_R      = 7'b0110011;
localparam logic [6:0] OP_IMM    = 7'b0010011;
localparam logic [6:0] OP_LOAD   = 7'b0000011;
localparam logic [6:0] OP_STORE  = 7'b0100011;
localparam logic [6:0] OP_BRANCH = 7'b1100011;
localparam logic [6:0] OP_JALR   = 7'b1100111;
localparam logic [6:0] OP_JAL    = 7'b1101111;
localparam logic [6:0] OP_LUI    = 7'b0110111;
localparam logic [6:0] OP_AUIPC  = 7'b0010111;

localparam logic [3:0] ALU_ADD  = 4'b0000;
localparam logic [3:0] ALU_SUB  = 4'b0001;
localparam logic [3:0] ALU_AND  = 4'b0010;
localparam logic [3:0] ALU_OR   = 4'b0011;
localparam logic [3:0] ALU_XOR  = 4'b0100;
localparam logic [3:0] ALU_SLL  = 4'b0101;
localparam logic [3:0] ALU_SRL  = 4'b0110;
localparam logic [3:0] ALU_SRA  = 4'b0111;
localparam logic [3:0] ALU_SLT  = 4'b1000;
localparam logic [3:0] ALU_SLTU = 4'b1001;

localparam logic [6:0] FUNCT7_BASE = 7'b0000000;
localparam logic [6:0] FUNCT7_ALT  = 7'b0100000;

endpackage


module tb_riscv_core;

logic clk;
logic rst;

riscv_core dut (
    .clk(clk),
    .rst(rst)
);

always #5 clk = ~clk;

function automatic [31:0] r_type(
    input [6:0] funct7,
    input [4:0] rs2,
    input [4:0] rs1,
    input [2:0] funct3,
    input [4:0] rd
);
begin
    r_type = {funct7, rs2, rs1, funct3, rd, 7'b0110011};
end
endfunction

function automatic [31:0] i_type(
    input [11:0] imm,
    input [4:0] rs1,
    input [2:0] funct3,
    input [4:0] rd
);
begin
    i_type = {imm, rs1, funct3, rd, 7'b0010011};
end
endfunction

function automatic [31:0] shift_i(
    input [6:0] funct7,
    input [4:0] shamt,
    input [4:0] rs1,
    input [2:0] funct3,
    input [4:0] rd
);
begin
    shift_i = {funct7, shamt, rs1, funct3, rd, 7'b0010011};
end
endfunction

function automatic [31:0] load_inst(
    input [11:0] imm,
    input [4:0] rs1,
    input [4:0] rd
);
begin
    load_inst = {imm, rs1, 3'b010, rd, 7'b0000011};
end
endfunction

function automatic [31:0] store_inst(
    input [11:0] imm,
    input [4:0] rs1,
    input [4:0] rs2
);
begin
    store_inst = {
        imm[11:5],
        rs2,
        rs1,
        3'b010,
        imm[4:0],
        7'b0100011
    };
end
endfunction

function automatic [31:0] branch_inst(
    input signed [12:0] imm,
    input [4:0] rs1,
    input [4:0] rs2,
    input [2:0] funct3
);
reg [12:0] bimm;
begin
    bimm = imm;

    branch_inst = {
        bimm[12],
        bimm[10:5],
        rs2,
        rs1,
        funct3,
        bimm[4:1],
        bimm[11],
      
        7'b1100011
    };
end
endfunction

function automatic [31:0] lui_inst(
    input [19:0] imm,
    input [4:0] rd
);
begin
    lui_inst = {imm, rd, 7'b0110111};
end
endfunction

function automatic [31:0] auipc_inst(
    input [19:0] imm,
    input [4:0] rd
);
begin
    auipc_inst = {imm, rd, 7'b0010111};
end
endfunction

function automatic [31:0] jal_inst(
    input signed [20:0] imm,
    input [4:0] rd
);
reg [20:0] jimm;
begin
    jimm = imm;

    jal_inst = {
        jimm[20],
        jimm[10:1],
        jimm[11],
        jimm[19:12],
        rd,
        7'b1101111
    };
end
endfunction

function automatic [31:0] jalr_inst(
    input [11:0] imm,
    input [4:0] rs1,
    input [4:0] rd
);
begin
    jalr_inst = {
        imm,
        rs1,
        3'b000,
        rd,
        7'b1100111
    };
end
endfunction

task automatic reset_cpu;
begin
    rst = 1'b1;

    @(posedge clk);
    @(posedge clk);

    rst = 1'b0;

    @(negedge clk);

    for (int i = 0; i < 256; i = i + 1)
        dut.instruction_memory_unit.ROM[i] = 32'h00000013;

    for (int i = 0; i < 32; i = i + 1)
        dut.register_file_unit.registers[i] = 32'b0;

    for (int i = 0; i < 256; i = i + 1)
        dut.data_memory_unit.memory[i] = 32'b0;

    dut.pc_unit.pc = 32'b0;

    #1;
end
endtask

task automatic check_reg(
    input integer reg_num,
    input [31:0] expected,
    input string test_name
);
begin
    if (dut.register_file_unit.registers[reg_num] === expected)
        $display("PASS: %s", test_name);
    else
        $display(
            "FAIL: %s | expected = %h | actual = %h",
            test_name,
            expected,
            dut.register_file_unit.registers[reg_num]
        );
end
endtask

task automatic run_one;
begin
    #1;
    @(posedge clk);
    #1;
end
endtask

task automatic check_branch(
    input [31:0] instruction,
    input [31:0] expected_pc,
    input string test_name
);
begin
    reset_cpu();

    dut.instruction_memory_unit.ROM[0] = instruction;

    #1;

    $display("========================================");
    $display("%s BEFORE", test_name);
    $display("PC          = %h", dut.pc);
    $display("INSTRUCTION = %h", dut.instruction);
    $display("OPCODE      = %b", dut.opcode);
    $display("FUNCT3      = %b", dut.funct3);
    $display("RS1         = %h", dut.read_data1);
    $display("RS2         = %h", dut.read_data2);
    $display("IMMEDIATE   = %h", dut.immediate);
    $display("BRANCH      = %b", dut.branch);
    $display("TAKEN       = %b", dut.branch_taken);
    $display("TARGET      = %h", dut.branch_target);
    $display("NEXT_PC     = %h", dut.next_pc);
    $display("========================================");

    @(posedge clk);
    #1;

    if (dut.pc === expected_pc)
        $display("PASS: %s", test_name);
    else
        $display(
            "FAIL: %s | expected PC = %h | actual PC = %h",
            test_name,
            expected_pc,
            dut.pc
        );
end
endtask

initial begin

    clk = 1'b0;
    rst = 1'b0;

    $display("========================================");
    $display("       RISC-V RV32I CPU TEST");
    $display("========================================");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd10;
    dut.register_file_unit.registers[2] = 32'd20;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3);
    run_one();
    check_reg(3, 32'd30, "ADD");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd30;
    dut.register_file_unit.registers[2] = 32'd10;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3);
    run_one();
    check_reg(3, 32'd20, "SUB");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFF00FF00;
    dut.register_file_unit.registers[2] = 32'h0F0F0F0F;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd3);
    run_one();
    check_reg(3, 32'h0F000F00, "AND");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFF00FF00;
    dut.register_file_unit.registers[2] = 32'h0F0F0F0F;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd3);
    run_one();
    check_reg(3, 32'hFF0FFF0F, "OR");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFF00FF00;
    dut.register_file_unit.registers[2] = 32'h0F0F0F0F;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd3);
    run_one();
    check_reg(3, 32'hF00FF00F, "XOR");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd3;
    dut.register_file_unit.registers[2] = 32'd2;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b001, 5'd3);
    run_one();
    check_reg(3, 32'd12, "SLL");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd16;
    dut.register_file_unit.registers[2] = 32'd2;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b101, 5'd3);
    run_one();
    check_reg(3, 32'd4, "SRL");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFFFFFFF0;
    dut.register_file_unit.registers[2] = 32'd2;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0100000, 5'd2, 5'd1, 3'b101, 5'd3);
    run_one();
    check_reg(3, 32'hFFFFFFFC, "SRA");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFFFFFFF0;
    dut.register_file_unit.registers[2] = 32'd5;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b010, 5'd3);
    run_one();
    check_reg(3, 32'd1, "SLT");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFFFFFFF0;
    dut.register_file_unit.registers[2] = 32'd5;
    dut.instruction_memory_unit.ROM[0] =
        r_type(7'b0000000, 5'd2, 5'd1, 3'b011, 5'd3);
    run_one();
    check_reg(3, 32'd0, "SLTU");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd10;
    dut.instruction_memory_unit.ROM[0] =
        i_type(12'd25, 5'd1, 3'b000, 5'd3);
    run_one();
    check_reg(3, 32'd35, "ADDI");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFF00FF00;
    dut.instruction_memory_unit.ROM[0] =
        i_type(12'h0F0, 5'd1, 3'b111, 5'd3);
    run_one();
    check_reg(3, 32'h00000000, "ANDI");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hF0000000;
    dut.instruction_memory_unit.ROM[0] =
        i_type(12'h0FF, 5'd1, 3'b110, 5'd3);
    run_one();
    check_reg(3, 32'hF00000FF, "ORI");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hAAAAAAAA;
    dut.instruction_memory_unit.ROM[0] =
        i_type(12'h0FF, 5'd1, 3'b100, 5'd3);
    run_one();
    check_reg(3, 32'hAAAAAA55, "XORI");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd3;
    dut.instruction_memory_unit.ROM[0] =
        shift_i(7'b0000000, 5'd2, 5'd1, 3'b001, 5'd3);
    run_one();
    check_reg(3, 32'd12, "SLLI");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd16;
    dut.instruction_memory_unit.ROM[0] =
        shift_i(7'b0000000, 5'd2, 5'd1, 3'b101, 5'd3);
    run_one();
    check_reg(3, 32'd4, "SRLI");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'hFFFFFFF0;
    dut.instruction_memory_unit.ROM[0] =
        shift_i(7'b0100000, 5'd2, 5'd1, 3'b101, 5'd3);
    run_one();
    check_reg(3, 32'hFFFFFFFC, "SRAI");

    reset_cpu();
    dut.data_memory_unit.memory[4] = 32'h12345678;
    dut.register_file_unit.registers[1] = 32'd16;
    dut.instruction_memory_unit.ROM[0] =
        load_inst(12'd0, 5'd1, 5'd3);
    run_one();
    check_reg(3, 32'h12345678, "LW");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd16;
    dut.register_file_unit.registers[2] = 32'hDEADBEEF;
    dut.instruction_memory_unit.ROM[0] =
        store_inst(12'd0, 5'd1, 5'd2);
    run_one();

    if (dut.data_memory_unit.memory[4] === 32'hDEADBEEF)
        $display("PASS: SW");
    else
        $display("FAIL: SW");

    reset_cpu();

    dut.register_file_unit.registers[1] = 32'd10;
    dut.register_file_unit.registers[2] = 32'd10;

    dut.instruction_memory_unit.ROM[0] =
        branch_inst(13'sd8, 5'd1, 5'd2, 3'b000);

    #1;

    $display("========================================");
    $display("BEQ BEFORE");
    $display("PC          = %h", dut.pc);
    $display("INSTRUCTION = %h", dut.instruction);
    $display("OPCODE      = %b", dut.opcode);
    $display("FUNCT3      = %b", dut.funct3);
    $display("RS1         = %h", dut.read_data1);
    $display("RS2         = %h", dut.read_data2);
    $display("IMMEDIATE   = %h", dut.immediate);
    $display("BRANCH      = %b", dut.branch);
    $display("TAKEN       = %b", dut.branch_taken);
    $display("TARGET      = %h", dut.branch_target);
    $display("NEXT_PC     = %h", dut.next_pc);
    $display("========================================");

    @(posedge clk);
    #1;

    if (dut.pc === 32'd8)
        $display("PASS: BEQ");
    else
        $display("FAIL: BEQ | PC = %h", dut.pc);

    reset_cpu();

    dut.register_file_unit.registers[1] = 32'd10;
    dut.register_file_unit.registers[2] = 32'd20;

    dut.instruction_memory_unit.ROM[0] =
        branch_inst(13'sd8, 5'd1, 5'd2, 3'b001);

    #1;

    $display("========================================");
    $display("BNE BEFORE");
    $display("PC          = %h", dut.pc);
    $display("INSTRUCTION = %h", dut.instruction);
    $display("OPCODE      = %b", dut.opcode);
    $display("FUNCT3      = %b", dut.funct3);
    $display("RS1         = %h", dut.read_data1);
    $display("RS2         = %h", dut.read_data2);
    $display("IMMEDIATE   = %h", dut.immediate);
    $display("BRANCH      = %b", dut.branch);
    $display("TAKEN       = %b", dut.branch_taken);
    $display("TARGET      = %h", dut.branch_target);
    $display("NEXT_PC     = %h", dut.next_pc);
    $display("========================================");

    @(posedge clk);
    #1;

    if (dut.pc === 32'd8)
        $display("PASS: BNE");
    else
        $display("FAIL: BNE | PC = %h", dut.pc);

    reset_cpu();

    dut.register_file_unit.registers[1] = 32'd5;
    dut.register_file_unit.registers[2] = 32'd10;

    dut.instruction_memory_unit.ROM[0] =
        branch_inst(13'sd8, 5'd1, 5'd2, 3'b100);

    #1;

    $display("========================================");
    $display("BLT BEFORE");
    $display("PC          = %h", dut.pc);
    $display("INSTRUCTION = %h", dut.instruction);
    $display("OPCODE      = %b", dut.opcode);
    $display("FUNCT3      = %b", dut.funct3);
    $display("RS1         = %h", dut.read_data1);
    $display("RS2         = %h", dut.read_data2);
    $display("IMMEDIATE   = %h", dut.immediate);
    $display("BRANCH      = %b", dut.branch);
    $display("TAKEN       = %b", dut.branch_taken);
    $display("TARGET      = %h", dut.branch_target);
    $display("NEXT_PC     = %h", dut.next_pc);
    $display("========================================");

    @(posedge clk);
    #1;

    if (dut.pc === 32'd8)
        $display("PASS: BLT");
    else
        $display("FAIL: BLT | PC = %h", dut.pc);

    reset_cpu();

    dut.register_file_unit.registers[1] = 32'd10;
    dut.register_file_unit.registers[2] = 32'd5;

    dut.instruction_memory_unit.ROM[0] =
        branch_inst(13'sd8, 5'd1, 5'd2, 3'b101);

    #1;

    $display("========================================");
    $display("BGE BEFORE");
    $display("PC          = %h", dut.pc);
    $display("INSTRUCTION = %h", dut.instruction);
    $display("OPCODE      = %b", dut.opcode);
    $display("FUNCT3      = %b", dut.funct3);
    $display("RS1         = %h", dut.read_data1);
    $display("RS2         = %h", dut.read_data2);
    $display("IMMEDIATE   = %h", dut.immediate);
    $display("BRANCH      = %b", dut.branch);
    $display("TAKEN       = %b", dut.branch_taken);
    $display("TARGET      = %h", dut.branch_target);
    $display("NEXT_PC     = %h", dut.next_pc);
    $display("========================================");

    @(posedge clk);
    #1;

    if (dut.pc === 32'd8)
        $display("PASS: BGE");
    else
        $display("FAIL: BGE | PC = %h", dut.pc);

    reset_cpu();

    dut.register_file_unit.registers[1] = 32'd5;
    dut.register_file_unit.registers[2] = 32'd10;

    dut.instruction_memory_unit.ROM[0] =
        branch_inst(13'sd8, 5'd1, 5'd2, 3'b110);

    #1;

    $display("========================================");
    $display("BLTU BEFORE");
    $display("PC          = %h", dut.pc);
    $display("INSTRUCTION = %h", dut.instruction);
    $display("OPCODE      = %b", dut.opcode);
    $display("FUNCT3      = %b", dut.funct3);
    $display("RS1         = %h", dut.read_data1);
    $display("RS2         = %h", dut.read_data2);
    $display("IMMEDIATE   = %h", dut.immediate);
    $display("BRANCH      = %b", dut.branch);
    $display("TAKEN       = %b", dut.branch_taken);
    $display("TARGET      = %h", dut.branch_target);
    $display("NEXT_PC     = %h", dut.next_pc);
    $display("========================================");

    @(posedge clk);
    #1;

    if (dut.pc === 32'd8)
        $display("PASS: BLTU");
    else
        $display("FAIL: BLTU | PC = %h", dut.pc);

    reset_cpu();

    dut.register_file_unit.registers[1] = 32'd10;
    dut.register_file_unit.registers[2] = 32'd5;

    dut.instruction_memory_unit.ROM[0] =
        branch_inst(13'sd8, 5'd1, 5'd2, 3'b111);

    #1;

    $display("========================================");
    $display("BGEU BEFORE");
    $display("PC          = %h", dut.pc);
    $display("INSTRUCTION = %h", dut.instruction);
    $display("OPCODE      = %b", dut.opcode);
    $display("FUNCT3      = %b", dut.funct3);
    $display("RS1         = %h", dut.read_data1);
    $display("RS2         = %h", dut.read_data2);
    $display("IMMEDIATE   = %h", dut.immediate);
    $display("BRANCH      = %b", dut.branch);
    $display("TAKEN       = %b", dut.branch_taken);
    $display("TARGET      = %h", dut.branch_target);
    $display("NEXT_PC     = %h", dut.next_pc);
    $display("========================================");

    @(posedge clk);
    #1;

    if (dut.pc === 32'd8)
        $display("PASS: BGEU");
    else
        $display("FAIL: BGEU | PC = %h", dut.pc);

    reset_cpu();

    dut.instruction_memory_unit.ROM[0] =
        lui_inst(20'h12345, 5'd3);
    run_one();
    check_reg(3, 32'h12345000, "LUI");

    reset_cpu();

    dut.instruction_memory_unit.ROM[0] =
        auipc_inst(20'h12345, 5'd3);
    run_one();
    check_reg(3, 32'h12345000, "AUIPC");

    reset_cpu();

    dut.instruction_memory_unit.ROM[0] =
        jal_inst(21'sd8, 5'd3);
    run_one();

    if (dut.pc === 32'd8)
        $display("PASS: JAL PC");
    else
        $display("FAIL: JAL PC | PC = %h", dut.pc);

    check_reg(3, 32'd4, "JAL rd");

    reset_cpu();

    dut.register_file_unit.registers[1] = 32'd16;

    dut.instruction_memory_unit.ROM[0] =
        jalr_inst(12'd4, 5'd1, 5'd3);

    run_one();

    if (dut.pc === 32'd20)
        $display("PASS: JALR PC");
    else
        $display("FAIL: JALR PC | PC = %h", dut.pc);

    check_reg(3, 32'd4, "JALR rd");

    $display("========================================");
    $display("              TEST DONE");
    $display("========================================");

    $finish;

end

endmodule




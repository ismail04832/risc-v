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
    jalr_inst = {imm, rs1, 3'b000, rd, 7'b1100111};
end
endfunction

task automatic reset_cpu;
begin
    rst = 1'b1;
    @(posedge clk);
    @(posedge clk);
    rst = 1'b0;
    @(negedge clk);

    // Initialisation de la mémoire unifiée (RAM)
    for (int i = 0; i < 256; i = i + 1)
        dut.memory_unit.ram[i] = 32'h00000013; // NOP

    for (int i = 0; i < 32; i = i + 1)
        dut.register_file_unit.registers[i] = 32'b0;

    // Suppression de l'accès direct erroné à pc_unit (le reset s'en charge)
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

// Exécute 5 cycles d'horloge pour s'assurer qu'une instruction multi-cycle se termine
task automatic run_instruction;
begin
    repeat (5) begin
        @(posedge clk);
        #1;
    end
end
endtask

initial begin
    clk = 1'b0;
    rst = 1'b0;

    $display("========================================");
    $display("    RISC-V RV32I MULTI-CYCLE CPU TEST");
    $display("========================================");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd10;
    dut.register_file_unit.registers[2] = 32'd20;
    dut.memory_unit.ram[0] = r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3);
    run_instruction();
    check_reg(3, 32'd30, "ADD");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd30;
    dut.register_file_unit.registers[2] = 32'd10;
    dut.memory_unit.ram[0] = r_type(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3);
    run_instruction();
    check_reg(3, 32'd20, "SUB");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd10;
    dut.memory_unit.ram[0] = i_type(12'd25, 5'd1, 3'b000, 5'd3);
    run_instruction();
    check_reg(3, 32'd35, "ADDI");

    reset_cpu();
    dut.memory_unit.ram[4] = 32'h12345678; // Adresse 16 / 4 = index 4
    dut.register_file_unit.registers[1] = 32'd16;
    dut.memory_unit.ram[0] = load_inst(12'd0, 5'd1, 5'd3);
    run_instruction();
    check_reg(3, 32'h12345678, "LW");

    reset_cpu();
    dut.register_file_unit.registers[1] = 32'd16;
    dut.register_file_unit.registers[2] = 32'hDEADBEEF;
    dut.memory_unit.ram[0] = store_inst(12'd0, 5'd1, 5'd2);
    run_instruction();

    if (dut.memory_unit.ram[4] === 32'hDEADBEEF)
        $display("PASS: SW");
    else
        $display("FAIL: SW");

    $display("========================================");
    $display("              TEST DONE");
    $display("========================================");
    $finish;
end

endmodule
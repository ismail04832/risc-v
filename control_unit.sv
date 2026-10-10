import riscv_pkg::*;

module control_unit (
    input  logic        clk,
    input  logic        rst,
    input  logic [6:0]  opcode,
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        mem_to_reg,
    output logic        alu_src_a,
    output logic [1:0]  alu_src_b,
    output logic        branch,
    output logic        jump,
    output logic        jalr,
    output logic        lui,
    output logic        auipc,
    // Signaux de contrôle multi-cycle
    output logic        ir_write,
    output logic        pc_write,
    output logic        pc_write_cond,
    output logic        i_ord
);

    logic [2:0] current_state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S_FETCH;
        else
            current_state <= next_state;
    end

    always_comb begin
        next_state    = S_FETCH;
        reg_write     = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        mem_to_reg    = 1'b0;
        alu_src_a     = 1'b0;
        alu_src_b     = 2'b00;
        branch        = 1'b0;
        jump          = 1'b0;
        jalr          = 1'b0;
        lui           = 1'b0;
        auipc         = 1'b0;
        ir_write      = 1'b0;
        pc_write      = 1'b0;
        pc_write_cond = 1'b0;
        i_ord         = 1'b0; // 0 = PC, 1 = ALUOut

        case (current_state)

            S_FETCH: begin
                mem_read  = 1'b1;
                i_ord     = 1'b0; // Adresse = PC
                ir_write  = 1'b1; // Sauvegarde dans IR
                alu_src_a = 1'b0; // PC
                alu_src_b = 2'b10; // +4 (ou constante)
                pc_write  = 1'b1;
                next_state = S_DECODE;
            end

            S_DECODE: begin
                case (opcode)
                    OP_R, OP_IMM, OP_LOAD, OP_STORE, OP_JALR, OP_LUI, OP_AUIPC:
                        next_state = S_EXEC;
                    OP_BRANCH:
                        next_state = S_BRANCH;
                    OP_JAL: begin
                        jump = 1'b1;
                        reg_write = 1'b1;
                        next_state = S_FETCH;
                    end
                    default: next_state = S_FETCH;
                endcase
            end

            S_EXEC: begin
                case (opcode)
                    OP_R: begin
                        alu_src_a = 1'b1; // Reg A
                        alu_src_b = 2'b00; // Reg B
                        next_state = S_WB;
                    end
                    OP_IMM, OP_JALR, OP_LUI, OP_AUIPC: begin
                        alu_src_a = 1'b1; // Reg A
                        alu_src_b = 2'b01; // Imm
                        if (opcode == OP_JALR) jalr = 1'b1;
                        if (opcode == OP_LUI)  lui  = 1'b1;
                        if (opcode == OP_AUIPC) auipc = 1'b1;
                        next_state = S_WB;
                    end
                    OP_LOAD, OP_STORE: begin
                        alu_src_a = 1'b1;
                        alu_src_b = 2'b01; // Base + Imm
                        next_state = S_MEM;
                    end
                    default: next_state = S_FETCH;
                endcase
            end

            S_MEM: begin
                if (opcode == OP_LOAD) begin
                    mem_read = 1'b1;
                    i_ord    = 1'b1; // Adresse = ALUOut
                    next_state = S_WB;
                end else if (opcode == OP_STORE) begin
                    mem_write = 1'b1;
                    i_ord     = 1'b1; // Adresse = ALUOut
                    next_state = S_FETCH;
                end
            end

            S_BRANCH: begin
                branch = 1'b1;
                pc_write_cond = 1'b1;
                next_state = S_FETCH;
            end

            S_WB: begin
                reg_write = 1'b1;
                if (opcode == OP_LOAD)
                    mem_to_reg = 1'b1;
                else
                    mem_to_reg = 1'b0;
                next_state = S_FETCH;
            end

            default: next_state = S_FETCH;

        endcase
    end

endmodule
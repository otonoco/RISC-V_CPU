import rv32i_types::*;


module stage_latch(
    input clk,
    input rst,

    input load,
    input logic valid_i,
    input logic BTB_hit_i,
    input logic [1:0] predicted_branch_outcome_i,
    input logic [1:0] predicted_branch_outcome_sel_i,
    input logic [1:0] predicted_branch_outcome_global_i,
    input logic [1:0] predicted_branch_outcome_local_i,
    input logic misprediction_i,
    input rv32i_control ctrl_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    input rv32i_opcode opcode_i,
    input rv32i_word pc_out_i,
    input rv32i_word pcmux_out_i,
    input rv32i_word predicted_pcmux_out_i,
    input rv32i_word instruction_i,
    input logic [4:0] rs1_i,
    input logic [4:0] rs2_i,
    input logic [4:0] rd_i,
    input rv32i_word rs1_out_i,
    input rv32i_word rs2_out_i,
    input rv32i_word alu_out_i,
    input rv32i_word m_out_i,
    input logic br_en_i,
    input rv32i_word dcache_rdata_i,
    input rv32i_word dcache_wdata_i,
    input logic [3:0] dcache_mem_byte_enable_i,
    input logic [31:0] i_imm_i,
    input logic [31:0] s_imm_i,
    input logic [31:0] b_imm_i,
    input logic [31:0] u_imm_i,
    input logic [31:0] j_imm_i,

    output logic valid_o,
    output logic BTB_hit_o,
    output logic [1:0] predicted_branch_outcome_o,
    output logic [1:0] predicted_branch_outcome_sel_o,
    output logic [1:0] predicted_branch_outcome_global_o,
    output logic [1:0] predicted_branch_outcome_local_o,
    output logic misprediction_o,
    output rv32i_control ctrl_o,
    output logic [2:0] funct3_o,
    output logic [6:0] funct7_o,
    output rv32i_opcode opcode_o,
    output rv32i_word pc_out_o,
    output rv32i_word pcmux_out_o,
    output rv32i_word predicted_pcmux_out_o,
    output rv32i_word instruction_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [4:0] rd_o,
    output rv32i_word rs1_out_o,
    output rv32i_word rs2_out_o,
    output rv32i_word alu_out_o,
    output rv32i_word m_out_o,
    output logic br_en_o,
    output rv32i_word dcache_rdata_o,
    output rv32i_word dcache_wdata_o,
    output logic [3:0] dcache_mem_byte_enable_o,
    output logic [31:0] i_imm_o,
    output logic [31:0] s_imm_o,
    output logic [31:0] b_imm_o,
    output logic [31:0] u_imm_o,
    output logic [31:0] j_imm_o
);


    always_ff @(posedge clk) begin
        if (rst) 
            begin
                valid_o <= 0; 
                BTB_hit_o <= 0; 
                predicted_branch_outcome_o <= 2'b01;
                predicted_branch_outcome_sel_o <= 2'b01;
                predicted_branch_outcome_local_o <= 2'b01;
                predicted_branch_outcome_global_o <= 2'b01;
                misprediction_o <= 0;
                ctrl_o <= '0;
                funct3_o <= '0;
                funct7_o <= '0;
                opcode_o <= rv32i_opcode'(7'b0);
                pc_out_o <= '0;
                pcmux_out_o <= '0;
                predicted_pcmux_out_o <= '0;
                instruction_o <= '0; 
                rs1_o <= '0;
                rs2_o <= '0;
                rd_o <= '0;
                rs1_out_o <= '0;
                rs2_out_o <= '0;
                alu_out_o <= '0;
                m_out_o <= '0;
                br_en_o <= 0;
                dcache_rdata_o <= '0;
                dcache_wdata_o <= '0; 
                dcache_mem_byte_enable_o <= '0; 
                i_imm_o <= '0;
                s_imm_o <= '0;
                b_imm_o <= '0;
                u_imm_o <= '0;
                j_imm_o <= '0;
            end
        else if (load) 
            begin
                valid_o <= valid_i; 
                BTB_hit_o <= BTB_hit_i; 
                predicted_branch_outcome_o <= predicted_branch_outcome_i;
                predicted_branch_outcome_sel_o <= predicted_branch_outcome_sel_i;
                predicted_branch_outcome_local_o <= predicted_branch_outcome_local_i;
                predicted_branch_outcome_global_o <= predicted_branch_outcome_global_i;
                misprediction_o <= misprediction_i;
                ctrl_o <= ctrl_i;
                funct3_o <= funct3_i;
                funct7_o <= funct7_i;
                opcode_o <= opcode_i;
                pc_out_o <= pc_out_i;
                pcmux_out_o <= pcmux_out_i;
                predicted_pcmux_out_o <= predicted_pcmux_out_i;
                instruction_o <= instruction_i; 
                rs1_o <= rs1_i;
                rs2_o <= rs2_i;
                rd_o <= rd_i;
                rs1_out_o <= rs1_out_i;
                rs2_out_o <= rs2_out_i;
                alu_out_o <= alu_out_i;
                m_out_o <= m_out_i;
                br_en_o <= br_en_i;
                dcache_rdata_o <= dcache_rdata_i;
                dcache_wdata_o <= dcache_wdata_i; 
                dcache_mem_byte_enable_o <= dcache_mem_byte_enable_i; 
                i_imm_o <= i_imm_i;
                s_imm_o <= s_imm_i;
                b_imm_o <= b_imm_i;
                u_imm_o <= u_imm_i;
                j_imm_o <= j_imm_i;
            end
        else 
            begin
                valid_o <= valid_o; 
                BTB_hit_o <= BTB_hit_o; 
                predicted_branch_outcome_o <= predicted_branch_outcome_o;
                predicted_branch_outcome_sel_o <= predicted_branch_outcome_sel_o;
                predicted_branch_outcome_local_o <= predicted_branch_outcome_local_o;
                predicted_branch_outcome_global_o <= predicted_branch_outcome_global_o;
                misprediction_o <= misprediction_o;
                ctrl_o <= ctrl_o;
                funct3_o <= funct3_o;
                funct7_o <= funct7_o;
                opcode_o <= opcode_o;
                pc_out_o <= pc_out_o;
                pcmux_out_o <= pcmux_out_o;
                predicted_pcmux_out_o <= predicted_pcmux_out_o;
                instruction_o <= instruction_o; 
                rs1_o <= rs1_o;
                rs2_o <= rs2_o;
                rd_o <= rd_o;
                rs1_out_o <= rs1_out_o;
                rs2_out_o <= rs2_out_o;
                alu_out_o <= alu_out_o;
                m_out_o <= m_out_o;
                br_en_o <= br_en_o;
                dcache_rdata_o <= dcache_rdata_o;
                dcache_wdata_o <= dcache_wdata_o; 
                dcache_mem_byte_enable_o <= dcache_mem_byte_enable_o; 
                i_imm_o <= i_imm_o;
                s_imm_o <= s_imm_o;
                b_imm_o <= b_imm_o;
                u_imm_o <= u_imm_o;
                j_imm_o <= j_imm_o;
            end
    end
endmodule : stage_latch

`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath (
    input clk,
    input rst,
    input rv32i_control ctrl,
    input rv32i_word if_icache_rdata,
    input rv32i_word mem_dcache_rdata,
    input logic if_icache_mem_resp,
    input logic mem_dcache_mem_resp,
    output rv32i_word mem_dcache_wdata,
    output rv32i_word mem_dcache_address,
    output rv32i_opcode id_opcode,
    output logic [2:0] id_funct3,
    output logic [6:0] id_funct7,
    output logic mem_dcache_read, mem_dcache_write, if_icache_read,
    output logic [3:0] dcache_mem_byte_enable,
    output rv32i_word icache_address,
    output logic [1:0] mem_mem_remainder, wb_mem_remainder
);

    /******************************** Signals ************************************/
    /*****************************************************************************/

    // All signals not input from outside should be initiated here
    // Please follow a naming convention & comment the use of signals initiated

    //IF stage signal
    rv32i_word if_pcmux_out, if_pc_out, if_predicted_pcmux_out;
    rv32i_opcode if_opcode;
    logic [1:0] if_predicted_branch_outcome, if_predicted_branch_outcome_sel, if_predicted_branch_outcome_local, if_predicted_branch_outcome_global;
    logic [31:0] if_i_imm, if_s_imm, if_b_imm, if_u_imm, if_j_imm;
    logic [4:0] if_rd, if_rs1, if_rs2;
    logic if_BTB_hit;
    logic [2:0] if_funct3;
    logic [6:0] if_funct7;

    //ID stage signal
    rv32i_word id_pc_out, id_predicted_pcmux_out;
    rv32i_word id_rs1_out, id_rs2_out, id_pcmux_out, id_icache_rdata;
    logic [31:0] id_i_imm, id_s_imm, id_b_imm, id_u_imm, id_j_imm;
    logic [4:0] id_rd, id_rs1, id_rs2; 
    logic id_BTB_hit;
    logic [1:0] id_predicted_branch_outcome, id_predicted_branch_outcome_sel, id_predicted_branch_outcome_local, id_predicted_branch_outcome_global;
       
    //EXE stage signal
    rv32i_word ex_pc_out, ex_predicted_pcmux_out, ex_rs1_out, ex_rs2_out, ex_alu_out, ex_pcmux_out, ex_icache_rdata;
    rv32i_opcode ex_opcode;
    rv32i_word ex_rs1_fwdmux_out, ex_rs2_fwdmux_out, ex_alumux1_data, ex_alumux2_data, ex_cmpmux_out;
    rv32i_control EXE;
    logic ex_br_en;
    logic [31:0] ex_i_imm, ex_s_imm, ex_b_imm, ex_u_imm, ex_j_imm;
    logic [4:0] ex_rd, ex_rs1, ex_rs2;
    logic ex_m_resp;
    logic [31:0] ex_m_out;

    logic [1:0] ex_predicted_branch_outcome, ex_predicted_branch_outcome_sel, ex_predicted_branch_outcome_local, ex_predicted_branch_outcome_global;   

    //logic ex_actual_branch_outcome;
    logic ex_BTB_hit;
    logic ex_misprediction;
    logic [2:0] ex_funct3;
    logic [6:0] ex_funct7; 

    //MEM stage signal
    rv32i_word mem_pc_out, mem_alu_out, mem_rs1_fwdmux_out, mem_rs2_fwdmux_out, mem_pcmux_out, mem_icache_rdata, mem_predicted_pcmux_out;
    rv32i_opcode mem_opcode;
    rv32i_control MEM;
    logic mem_br_en;
    logic [31:0] mem_i_imm, mem_u_imm;
    logic mem_actual_branch_outcome;
    logic mem_BTB_hit;
    logic [1:0] mem_predicted_branch_outcome,mem_predicted_branch_outcome_sel, mem_predicted_branch_outcome_local, mem_predicted_branch_outcome_global;  
    logic [4:0] mem_rd, mem_rs1, mem_rs2;
    logic mem_m_resp;
    logic [31:0] mem_m_out;
    logic mem_misprediction;
    logic [2:0] mem_funct3;
    logic [6:0] mem_funct7;

    //WB stage signal
    rv32i_word wb_pc_out, wb_predicted_pcmux_out, wb_alu_out, wb_dcache_rdata, wb_address_buffer, wb_rs1_fwdmux_out, wb_rs2_fwdmux_out, wb_pcmux_out, wb_icache_rdata, wb_dcache_wdata;
    rv32i_opcode wb_opcode;
    rv32i_word lbs_in,lu_in,lhs_in,lhu_in,lbu_in, wb_regfilemux_out;
    rv32i_control WBK;
    logic wb_br_en;
    logic [31:0] wb_i_imm, wb_u_imm;
    logic wb_BTB_hit;
    logic [1:0] wb_predicted_branch_outcome; 
    logic [4:0] wb_rd, wb_rs1, wb_rs2;
    logic wb_m_resp;
    logic [31:0] wb_m_out;
    logic [3:0] wb_dcache_mem_byte_enable;
    logic wb_misprediction;
    logic [2:0] wb_funct3;
    logic [6:0] wb_funct7;

    //forwarding logic signal
    logic data_hazard_rs1, data_hazard_rs2; // A forwarding is needed
    logic [1:0] rs1_fwdmux_sel, rs2_fwdmux_sel; // Forward mux sel

    //other signals
    logic if_id_valid, id_ex_valid, ex_mem_valid, mem_wb_valid;
    logic flushing, bubble, dcache_load_stall, dcache_stall;
    logic load_PC, load_IF_ID_latch, load_ID_EX_latch, load_EX_MEM_latch, load_MEM_WB_latch;
    /*****************************************************************************/


    /**********************************Forwarding Logic **************************/
    /*****************************************************************************/
    always_comb begin
    //rs1 forwawrd mux
        if (mem_rd == ex_rs1 && mem_rd && MEM.load_regfile == 1'b1) 
            begin
                rs1_fwdmux_sel = 2'b01;//mem_ex hazard
                data_hazard_rs1 = 1'b0;
                if (MEM.opcode == op_load) 
                    begin
                        data_hazard_rs1 = 1'b1;  
                    end
                if (MEM.opcode == op_lui) 
                    begin
                        rs1_fwdmux_sel = 2'b11;
                    end                                             
            end
        else if (wb_rd == ex_rs1 && wb_rd && WBK.load_regfile == 1'b1) 
            begin
                rs1_fwdmux_sel = 2'b10; //wb_ex hazard
                data_hazard_rs1 = 1'b0;
            end
        else 
            begin
                rs1_fwdmux_sel = 2'b00;
                data_hazard_rs1 = 1'b0;
            end

    //ex hazard rs2
        if (mem_rd == ex_rs2 && mem_rd != '0 && MEM.load_regfile == 1'b1) 
            begin
                rs2_fwdmux_sel = 2'b01;//mem_ex hazard
                data_hazard_rs2 = 1'b0;
                if (MEM.opcode == op_load) 
                    begin
                        data_hazard_rs2 = 1'b1;
                    end
                if (MEM.opcode == op_lui) 
                    begin
                        rs2_fwdmux_sel = 2'b11;
                    end
            end
        else if (wb_rd == ex_rs2 && wb_rd != '0 && WBK.load_regfile == 1'b1) 
            begin
                rs2_fwdmux_sel = 2'b10;//wb_ex hazard
                data_hazard_rs2 = 1'b0;
            end
        else 
            begin
                rs2_fwdmux_sel = 2'b00;
                data_hazard_rs2 = 1'b0;
            end
     end

    assign bubble = (data_hazard_rs1 | data_hazard_rs2) && (!dcache_load_stall); //need to wait for the loaded data first, otherwise the load just turns to bubble
    /*****************************************************************************/


    /**************************** Misprediction Flushing *************************/
    /*****************************************************************************/
    //static-not-taken branch
    always_comb begin
        mem_actual_branch_outcome = 1'b0;
        flushing = 1'b0;
        
        if (MEM.jalr_enable  || MEM.jal_enable || mem_br_en && MEM.branch_enable) 
            begin
                mem_actual_branch_outcome = 1'b1;  //taken_branch
            end

        if (mem_misprediction) 
            begin
                flushing = 1'b1;
            end           
    end
    /*****************************************************************************/


    /**************************** Pipeline Stalling*******************************/
    /*****************************************************************************/
    always_comb 
    begin
        load_PC = 1'b1;
        load_IF_ID_latch = 1'b1;
        load_ID_EX_latch = 1'b1;
        load_EX_MEM_latch = 1'b1;
        load_MEM_WB_latch = 1'b1;
        dcache_load_stall = 1'b0;
        dcache_stall = 1'b0;


        if ((mem_dcache_read || mem_dcache_write) && !mem_dcache_mem_resp) 
            begin
                load_PC = 1'b0;
                load_IF_ID_latch = 1'b0;
                load_ID_EX_latch = 1'b0;
                load_EX_MEM_latch = 1'b0;
                load_MEM_WB_latch = 1'b0;
                dcache_load_stall = 1'b0;
                dcache_stall = 1'b1;
                if (mem_dcache_read && !mem_dcache_mem_resp) 
                    begin
                        dcache_load_stall = 1'b1;
                    end
            end
        
        else if (EXE.m_enable && !ex_m_resp && !flushing) 
            begin
                load_PC = 1'b0;
                load_IF_ID_latch = 1'b0;
                load_ID_EX_latch = 1'b0;
                load_EX_MEM_latch = 1'b0;
                load_MEM_WB_latch = 1'b0;
            end
        else if (if_icache_read && !if_icache_mem_resp && !flushing) 
            begin
                load_PC = 1'b0;
                load_IF_ID_latch = 1'b0;
                load_ID_EX_latch = 1'b0;
                load_EX_MEM_latch = 1'b0;
                load_MEM_WB_latch = 1'b0;
            end
    end
    
    /*****************************************************************************/


    /**************************** Cache Signals***********************************/
    /*****************************************************************************/
    always_comb 
    begin
        mem_dcache_read = 1'b0;
        mem_dcache_write = 1'b0;
        if (MEM.dcache_read & ex_mem_valid) 
            begin
                mem_dcache_read = 1'b1;
            end
        if (MEM.dcache_write & ex_mem_valid) 
            begin
                mem_dcache_write = 1'b1;
            end
    end
    
    assign if_icache_read = 1'b1;
    /*****************************************************************************/


    /********************************** Modules **********************************/
    /*****************************************************************************/

    // If you need to instance any module, do it below
    //used temperarely without dcache
    alu ALU (
        .aluop(EXE.aluop),
        .a(ex_alumux1_data),
        .b(ex_alumux2_data),
	    .f(ex_alu_out)
    );

    cmp CMP (
        .cmpop(EXE.cmpop),
        .rs1_out(ex_rs1_fwdmux_out),  //need to change to forwarding logic
        .cmpmux_out(ex_cmpmux_out),
        .br_en(ex_br_en)
    );

    regfile regfile (
        .clk(clk),
        .rst(rst),
        .load(WBK.load_regfile),
        .in(wb_regfilemux_out), ///you mean regfilemux_out?????
        .src_a(id_rs1),
        .src_b(id_rs2),
        .dest(wb_rd),
        .reg_a(id_rs1_out),
        .reg_b(id_rs2_out)
    );

    pc_register PC (
        .clk(clk),
        .rst(rst),
        .load(load_PC && !bubble), 
        .in(if_pcmux_out),
        .out(if_pc_out)
    );
   
    decoder DECODER(.*);

    branch_prediction #(.s_index(8), .n_previous_branches(2)) BRANCH(.*);

    m_extension M_EXTENSION (
        .clk(clk),
        .rst(rst || flushing),
        .a(ex_alumux1_data),
        .b(ex_alumux2_data),
        .EXE(EXE),
        .f(ex_m_out),
        .m_resp(ex_m_resp)
     );
    /*****************************************************************************/


    /********************************* Latches ***********************************/
    /*****************************************************************************/

    // Latches between stages
    stage_latch IF_ID (
        .clk,
        .rst(flushing | rst),
        .load(load_IF_ID_latch && !bubble), // need to change when stalling
        .pc_out_i(if_pc_out),
        .pc_out_o(id_pc_out),
        .pcmux_out_i(if_pcmux_out),
        .pcmux_out_o(id_pcmux_out),        
        .instruction_i(if_icache_rdata),
        .instruction_o(id_icache_rdata),
        .ctrl_i('0),
        .ctrl_o(),
        .funct3_i(if_funct3),
        .funct3_o(id_funct3),
        .funct7_i(if_funct7),
        .funct7_o(id_funct7),
        .opcode_i(if_opcode),
        .opcode_o(id_opcode),
        .i_imm_i(if_i_imm),
        .s_imm_i(if_s_imm),
        .b_imm_i(if_b_imm),
        .u_imm_i(if_u_imm),
        .j_imm_i(if_j_imm),
	    .i_imm_o(id_i_imm),
        .s_imm_o(id_s_imm),
        .b_imm_o(id_b_imm),
        .u_imm_o(id_u_imm),
        .j_imm_o(id_j_imm),
        .rs1_i(if_rs1),
        .rs1_o(id_rs1),
        .rs2_i(if_rs2),
        .rs2_o(id_rs2),
        .rd_i(if_rd),
        .rd_o(id_rd),
        .rs1_out_i(),
        .rs1_out_o(),
        .rs2_out_i(),
        .rs2_out_o(),
        .alu_out_i(),
        .alu_out_o(),
        .m_out_i(),
        .m_out_o(),
        .br_en_i(),
        .br_en_o(),
        .dcache_rdata_i(),
        .dcache_rdata_o(),
        .dcache_wdata_i(),
        .dcache_wdata_o(),
        .dcache_mem_byte_enable_i(),
        .dcache_mem_byte_enable_o(),
        .BTB_hit_i(if_BTB_hit),
        .BTB_hit_o(id_BTB_hit),
        .predicted_pcmux_out_i(if_predicted_pcmux_out),
        .predicted_pcmux_out_o(id_predicted_pcmux_out),
        .predicted_branch_outcome_i(if_predicted_branch_outcome),
        .predicted_branch_outcome_o(id_predicted_branch_outcome),
        .predicted_branch_outcome_sel_i(if_predicted_branch_outcome_sel),
        .predicted_branch_outcome_sel_o(id_predicted_branch_outcome_sel),
        .predicted_branch_outcome_local_i(if_predicted_branch_outcome_local),
        .predicted_branch_outcome_local_o(id_predicted_branch_outcome_local),
        .predicted_branch_outcome_global_i(if_predicted_branch_outcome_global),
        .predicted_branch_outcome_global_o(id_predicted_branch_outcome_global),
        .misprediction_i(),
        .misprediction_o(),
        .valid_i(load_PC),
        .valid_o(if_id_valid)
    );

    stage_latch ID_EX (
        .clk,
        .rst((flushing | rst) & ~dcache_stall),//wait for the dcache first, otherwise the br at ex_stage just become zero, can not propagate to the mem to check the value
        .load(load_ID_EX_latch && !bubble), // need to change when stalling
        .pc_out_i(id_pc_out),
        .pc_out_o(ex_pc_out),
        .pcmux_out_i(id_pcmux_out),
        .pcmux_out_o(ex_pcmux_out),
        .instruction_i(id_icache_rdata),
        .instruction_o(ex_icache_rdata),
        .ctrl_i(ctrl),
        .ctrl_o(EXE),
        .funct3_i(id_funct3),
        .funct3_o(ex_funct3),
        .funct7_i(id_funct7),
        .funct7_o(ex_funct7),
        .opcode_i(id_opcode),
        .opcode_o(ex_opcode),
        .i_imm_i(id_i_imm),
        .s_imm_i(id_s_imm),
        .b_imm_i(id_b_imm),
        .u_imm_i(id_u_imm),
        .j_imm_i(id_j_imm),
        .i_imm_o(ex_i_imm),
        .s_imm_o(ex_s_imm),
        .b_imm_o(ex_b_imm),
        .u_imm_o(ex_u_imm),
        .j_imm_o(ex_j_imm),
        .rs1_i(id_rs1),
        .rs1_o(ex_rs1),
        .rs2_i(id_rs2),
        .rs2_o(ex_rs2),
        .rd_i(id_rd),
        .rd_o(ex_rd),
        .rs1_out_i(id_rs1_out),
        .rs1_out_o(ex_rs1_out),
        .rs2_out_i(id_rs2_out),
        .rs2_out_o(ex_rs2_out),
        .alu_out_i(),
        .alu_out_o(),
        .m_out_i(),
        .m_out_o(),
        .br_en_i(),
        .br_en_o(),
        .dcache_rdata_i(),
        .dcache_rdata_o(),
        .dcache_wdata_i(),
        .dcache_wdata_o(),
        .dcache_mem_byte_enable_i(),
        .dcache_mem_byte_enable_o(),
        .BTB_hit_i(id_BTB_hit),
        .BTB_hit_o(ex_BTB_hit),
        .predicted_pcmux_out_i(id_predicted_pcmux_out),
        .predicted_pcmux_out_o(ex_predicted_pcmux_out),
        .predicted_branch_outcome_i(id_predicted_branch_outcome),
        .predicted_branch_outcome_o(ex_predicted_branch_outcome),
        .predicted_branch_outcome_sel_i(id_predicted_branch_outcome_sel),
        .predicted_branch_outcome_sel_o(ex_predicted_branch_outcome_sel),
        .predicted_branch_outcome_local_i(id_predicted_branch_outcome_local),
        .predicted_branch_outcome_local_o(ex_predicted_branch_outcome_local),
        .predicted_branch_outcome_global_i(id_predicted_branch_outcome_global),
        .predicted_branch_outcome_global_o(ex_predicted_branch_outcome_global),
        .misprediction_i(),
        .misprediction_o(),
        .valid_i(if_id_valid),
        .valid_o(id_ex_valid)
    );

    stage_latch EX_MEM (
        .clk,
        .rst(flushing || rst || (bubble && load_EX_MEM_latch)),
        .load(load_EX_MEM_latch), // need to change when stalling
        .pc_out_i(ex_pc_out),
        .pc_out_o(mem_pc_out),
        .pcmux_out_i(ex_pcmux_out),
        .pcmux_out_o(mem_pcmux_out),
        .instruction_i(ex_icache_rdata),
        .instruction_o(mem_icache_rdata),
        .ctrl_i(EXE),
        .ctrl_o(MEM),
        .funct3_i(ex_funct3),
        .funct3_o(mem_funct3),
        .funct7_i(ex_funct7),
        .funct7_o(mem_funct7),
        .opcode_i(ex_opcode),
        .opcode_o(mem_opcode),
        .i_imm_i(),
        .s_imm_i(),
        .b_imm_i(),
        .u_imm_i(ex_u_imm),
        .j_imm_i(),
        .i_imm_o(),
        .s_imm_o(),
        .b_imm_o(),
        .u_imm_o(mem_u_imm),
        .j_imm_o(),
        .rs1_i(ex_rs1),
        .rs1_o(mem_rs1),
        .rs2_i(ex_rs2),
        .rs2_o(mem_rs2),
	    .rd_i(ex_rd),
        .rd_o(mem_rd),
        .rs1_out_i(ex_rs1_fwdmux_out),
        .rs1_out_o(mem_rs1_fwdmux_out),
        .rs2_out_i(ex_rs2_fwdmux_out),
        .rs2_out_o(mem_rs2_fwdmux_out),
        .alu_out_i(ex_alu_out),
        .alu_out_o(mem_alu_out),
        .m_out_i(ex_m_out),
        .m_out_o(mem_m_out),
        .br_en_i(ex_br_en),
        .br_en_o(mem_br_en),
        .dcache_rdata_i(),
        .dcache_rdata_o(),
        .dcache_wdata_i(),
        .dcache_wdata_o(),
        .dcache_mem_byte_enable_i(),
        .dcache_mem_byte_enable_o(),
        .BTB_hit_i(ex_BTB_hit),
        .BTB_hit_o(mem_BTB_hit),
        .predicted_pcmux_out_i(ex_predicted_pcmux_out),
        .predicted_pcmux_out_o(mem_predicted_pcmux_out),
        .predicted_branch_outcome_i(ex_predicted_branch_outcome),
        .predicted_branch_outcome_o(mem_predicted_branch_outcome),
        .predicted_branch_outcome_sel_i(ex_predicted_branch_outcome_sel),
        .predicted_branch_outcome_sel_o(mem_predicted_branch_outcome_sel),
        .predicted_branch_outcome_local_i(ex_predicted_branch_outcome_local),
        .predicted_branch_outcome_local_o(mem_predicted_branch_outcome_local),
        .predicted_branch_outcome_global_i(ex_predicted_branch_outcome_global),
        .predicted_branch_outcome_global_o(mem_predicted_branch_outcome_global),
        .misprediction_i(),
        .misprediction_o(),
        .valid_i(id_ex_valid),
        .valid_o(ex_mem_valid) //if it has data_hazard, the value passed would be invalid
    );

    stage_latch MEM_WB (
        .clk,
        .rst,
        .load(load_MEM_WB_latch && ex_mem_valid), // need to change when stalling
        .pc_out_i(mem_pc_out),
        .pc_out_o(wb_pc_out),
        .pcmux_out_i(mem_pcmux_out),
        .pcmux_out_o(wb_pcmux_out),
        .instruction_i(mem_icache_rdata),
        .instruction_o(wb_icache_rdata),
        .ctrl_i(MEM),
        .ctrl_o(WBK),
        .funct3_i(mem_funct3),
        .funct3_o(wb_funct3),
        .funct7_i(mem_funct7),
        .funct7_o(wb_funct7),
        .opcode_i(mem_opcode),
        .opcode_o(wb_opcode),
        .i_imm_i(),
        .s_imm_i(),
        .b_imm_i(),
        .u_imm_i(mem_u_imm),
        .j_imm_i(),
        .i_imm_o(),
        .s_imm_o(),
        .b_imm_o(),
        .u_imm_o(wb_u_imm),
        .j_imm_o(),
        .rs1_i(mem_rs1),
        .rs1_o(wb_rs1),
        .rs2_i(mem_rs2),
        .rs2_o(wb_rs2),
        .rd_i(mem_rd),
        .rd_o(wb_rd),
        .rs1_out_i(mem_rs1_fwdmux_out),
        .rs1_out_o(wb_rs1_fwdmux_out),
        .rs2_out_i(mem_rs2_fwdmux_out),
        .rs2_out_o(wb_rs2_fwdmux_out),
        .alu_out_i(mem_alu_out),
        .alu_out_o(wb_alu_out),
        .m_out_i(mem_m_out),
        .m_out_o(wb_m_out),
        .br_en_i(mem_br_en),
        .br_en_o(wb_br_en),
        .dcache_rdata_i(mem_dcache_rdata),
        .dcache_rdata_o(wb_dcache_rdata),
        .dcache_mem_byte_enable_i(dcache_mem_byte_enable),
        .dcache_mem_byte_enable_o(wb_dcache_mem_byte_enable),
        .dcache_wdata_i(mem_dcache_wdata),
        .dcache_wdata_o(wb_dcache_wdata),
        .BTB_hit_i(mem_BTB_hit),
        .BTB_hit_o(wb_BTB_hit),
        .predicted_pcmux_out_i(mem_predicted_pcmux_out),
        .predicted_pcmux_out_o(wb_predicted_pcmux_out),
        .predicted_branch_outcome_i(mem_predicted_branch_outcome),
        .predicted_branch_outcome_o(wb_predicted_branch_outcome),
        .predicted_branch_outcome_sel_i(),
        .predicted_branch_outcome_sel_o(),
        .predicted_branch_outcome_local_i(),
        .predicted_branch_outcome_local_o(),
        .predicted_branch_outcome_global_i(),
        .predicted_branch_outcome_global_o(),
        .misprediction_i(mem_misprediction),
        .misprediction_o(wb_misprediction),
        .valid_i(ex_mem_valid),
        .valid_o(mem_wb_valid)
    );
    /*****************************************************************************/


    /***************************load & store shift logic**************************/
    /*****************************************************************************/
    assign icache_address = {if_pc_out[31:2], 2'b0};
    assign mem_dcache_address = {mem_alu_out[31:2], 2'b0};
    assign mem_mem_remainder = mem_alu_out % 3'b100;
    assign wb_address_buffer = {wb_alu_out[31:2], 2'b0};
    assign wb_mem_remainder = wb_alu_out % 3'b100;

    always_comb begin
    ////load
        unique case (wb_mem_remainder)
            2'd0: 
                begin
                    lbs_in = {{24{wb_dcache_rdata[7]}},  wb_dcache_rdata[7:0]};
                    lbu_in = {24'b0, wb_dcache_rdata[7:0]};
                    lhs_in = {{16{wb_dcache_rdata[15]}}, wb_dcache_rdata[15:0]};
                    lhu_in = {16'b0, wb_dcache_rdata[15:0]};
                end

            2'd1: 
                begin
                    lbs_in = {{24{wb_dcache_rdata[15]}}, wb_dcache_rdata[15:8]};
                    lbu_in = {24'b0, wb_dcache_rdata[15:8]};
                    lhs_in = {{16{wb_dcache_rdata[15]}}, wb_dcache_rdata[15:0]};
                    lhu_in = {16'b0, wb_dcache_rdata[15:0]};
                end

            2'd2: 
                begin
                    lbs_in = {{24{wb_dcache_rdata[23]}}, wb_dcache_rdata[23:16]};
                    lbu_in = {24'b0, wb_dcache_rdata[23:16]};
                    lhs_in = {{16{wb_dcache_rdata[31]}}, wb_dcache_rdata[31:16]};
                    lhu_in = {16'b0, wb_dcache_rdata[31:16]};
                end

            2'd3: 
                begin
                    lbs_in = {{24{wb_dcache_rdata[31]}}, wb_dcache_rdata[31:24]};
                    lbu_in = {24'b0, wb_dcache_rdata[31:24]};
                    lhs_in = {{16{wb_dcache_rdata[31]}}, wb_dcache_rdata[31:16]};
                    lhu_in = {16'b0, wb_dcache_rdata[31:16]};
                end
        endcase

    ///store
        unique case (MEM.funct3)
            3'b000: 
            begin
                unique case (mem_mem_remainder)
                    2'b00: 
                        begin
                            mem_dcache_wdata = {24'b0, mem_rs2_fwdmux_out[7:0]};
                            dcache_mem_byte_enable = 4'b0001;
                        end

                    2'b01: 
                        begin
                            mem_dcache_wdata = {16'b0, mem_rs2_fwdmux_out[7:0], 8'b0};
                            dcache_mem_byte_enable = 4'b0010;
                        end

                    2'b10: 
                        begin
                            mem_dcache_wdata = {8'b0, mem_rs2_fwdmux_out[7:0], 16'b0};
                            dcache_mem_byte_enable = 4'b0100;
                        end

                    2'b11: 
                        begin
                            mem_dcache_wdata = {mem_rs2_fwdmux_out[7:0], 24'b0};
                            dcache_mem_byte_enable = 4'b1000;
                        end
                endcase
            end

            3'b001: 
            begin
                unique case (mem_mem_remainder)
                    2'b00: 
                        begin
                            mem_dcache_wdata = {16'b0, mem_rs2_fwdmux_out[15:0]}; //SH
                            dcache_mem_byte_enable = 4'b0011;
                        end

                    2'b10: 
                        begin
                            mem_dcache_wdata = {mem_rs2_fwdmux_out[15:0], 16'b0}; //SH
                            dcache_mem_byte_enable = 4'b1100;
                        end
                endcase
            end

            3'b010: 
            begin
                mem_dcache_wdata = mem_rs2_fwdmux_out;
                dcache_mem_byte_enable = 4'b1111;
            end

            /*default: begin
                    mem_dcache_wdata = '0;
                    dcache_mem_byte_enable = 4'b0000;
                    end*/
        endcase
    end
    /*****************************************************************************/


    /*********************************** MUXES ***********************************/
    /*****************************************************************************/

    // Muxes: six muxes totally
    always_comb begin : MUXES

        ex_alumux2_data = ex_i_imm;
        wb_regfilemux_out = wb_alu_out;

        unique case (EXE.cmpmux_sel)
            cmpmux::rs2_out: ex_cmpmux_out = ex_rs2_fwdmux_out;
            cmpmux::i_imm: ex_cmpmux_out = ex_i_imm;
            default: `BAD_MUX_SEL;
        endcase

        unique case (EXE.alumux1_sel)
            alumux::rs1_out: ex_alumux1_data = ex_rs1_fwdmux_out;
            alumux::pc_out: ex_alumux1_data = ex_pc_out;
            default: `BAD_MUX_SEL;
        endcase

        unique case (EXE.alumux2_sel)
            alumux::i_imm: ex_alumux2_data = ex_i_imm;
            alumux::u_imm: ex_alumux2_data = ex_u_imm;
            alumux::b_imm: ex_alumux2_data = ex_b_imm;
            alumux::s_imm: ex_alumux2_data = ex_s_imm;
            alumux::j_imm: ex_alumux2_data = ex_j_imm;
            alumux::rs2_out: ex_alumux2_data = ex_rs2_fwdmux_out;
            default: `BAD_MUX_SEL;
        endcase

        unique case (WBK.regfilemux_sel)
            regfilemux::alu_out:  wb_regfilemux_out = WBK.m_enable ? wb_m_out : wb_alu_out;
            regfilemux::br_en:    wb_regfilemux_out = {31'b0, wb_br_en};
            regfilemux::u_imm:    wb_regfilemux_out = wb_u_imm;
            regfilemux::lw:       wb_regfilemux_out = wb_dcache_rdata;
            regfilemux::pc_plus4: wb_regfilemux_out = wb_pc_out + 4;
            regfilemux::lb:       wb_regfilemux_out = lbs_in;
            regfilemux::lbu:      wb_regfilemux_out = lbu_in;
            regfilemux::lh:       wb_regfilemux_out = lhs_in;
            regfilemux::lhu:      wb_regfilemux_out = lhu_in; //shifts
            default: `BAD_MUX_SEL;
        endcase

    end
    
    always_comb begin : FORWARDING_MUXES
        unique case (rs1_fwdmux_sel)
            2'b00:  ex_rs1_fwdmux_out = ex_rs1_out;
            2'b01:  begin
                        ex_rs1_fwdmux_out = mem_alu_out;
                        if (MEM.m_enable) 
                            begin
                                ex_rs1_fwdmux_out = mem_m_out;
                            end
                        else if (MEM.forward_cmp) 
                            begin
                                ex_rs1_fwdmux_out = mem_br_en;
                            end
                    end
            2'b10:  ex_rs1_fwdmux_out = wb_regfilemux_out;
            2'b11:  ex_rs1_fwdmux_out = mem_u_imm;
            //default: `BAD_MUX_SEL;
        endcase

        unique case (rs2_fwdmux_sel)
            2'b00:  ex_rs2_fwdmux_out = ex_rs2_out;
            2'b01:  begin
                        ex_rs2_fwdmux_out = mem_alu_out;
                        if (MEM.m_enable) 
                            begin
                                ex_rs2_fwdmux_out = mem_m_out;
                            end
                        else if (MEM.forward_cmp) 
                            begin
                                ex_rs2_fwdmux_out = mem_br_en;
                            end
                        //if (MEM.m_enable) ex_rs2_fwdmux_out = mem_m_out;
                    end
            2'b10:  ex_rs2_fwdmux_out = wb_regfilemux_out;
            2'b11:  ex_rs2_fwdmux_out = mem_u_imm;
            //default: `BAD_MUX_SEL;
        endcase
    end

    /*****************************************************************************/
endmodule


import rv32i_types::*;

module branch_prediction_datapath #(parameter s_index = 10,
                                              n_previous_branches = 4)

(
    input clk,
    input rst,

    input logic [31:0] if_pc_out,
    input logic [31:0] mem_pc_out,
    input logic [31:0] mem_predicted_pcmux_out,
    input logic [1:0] mem_updated_prediction,//from control
    input logic mem_BTB_hit,
    input logic [31:0] mem_alu_out, 
    input rv32i_control MEM,
    input logic mem_actual_branch_outcome,
    input logic [1:0] mem_predicted_branch_outcome, mem_predicted_branch_outcome_sel,
    input logic [1:0] mem_predicted_branch_outcome_global, mem_predicted_branch_outcome_local,
    input logic mem_br_en,
    
    output logic load_prediction,
    output logic [31:0] if_pcmux_out,
    output logic [31:0] if_predicted_pcmux_out,
    output logic [1:0] if_predicted_branch_outcome, if_predicted_branch_outcome_sel,
    output logic [1:0] if_predicted_branch_outcome_global, if_predicted_branch_outcome_local,
    output logic if_BTB_hit,
    output logic mem_misprediction
);

    /**************************** Internal Signals********************************/
    /*****************************************************************************/

    logic [29-s_index : 0] address_tag, if_tag_out, mem_tag_in;
    logic [s_index-1 : 0]  read_index, write_index;
    logic load_tag, load_address;
    logic is_branch;
    logic [31:0] mem_updated_address;
    logic [2**n_previous_branches-1:0][1:0] if_PHT_outcome; 
    logic [2**n_previous_branches-1:0] load_PHT;
    logic [n_previous_branches-1:0] BHR_history;
    logic [1:0] mem_updated_prediction_tournament;
    //logic [1:0] if_predicted_branch_outcome_global, if_predicted_branch_outcome_local;
    /**************************** Predict the Next PC*****************************/
    /*****************************************************************************/
    always_comb begin :IF_STATE
        if_pcmux_out = if_pc_out + 4;
        address_tag = if_pc_out[31 : s_index+2];
        read_index = if_pc_out[s_index+1 : 2];
        if_BTB_hit = (if_tag_out === address_tag);
        if (mem_BTB_hit) begin
                        if (MEM.branch_enable && mem_misprediction) begin
                                                                   if (mem_br_en) if_pcmux_out = {mem_alu_out[31:2], 2'b00};
                                                                   else if_pcmux_out = mem_pc_out + 4;
                                                                   end

                        else if (MEM.jal_enable && mem_misprediction) if_pcmux_out = {mem_alu_out[31:2], 2'b00};
                        else if (MEM.jalr_enable && mem_misprediction) if_pcmux_out = {mem_alu_out[31:1], 1'b0};
                        else if (if_BTB_hit && if_predicted_branch_outcome[1]) if_pcmux_out = if_predicted_pcmux_out;
                        end
        else begin
             if (MEM.branch_enable && mem_br_en) if_pcmux_out = {mem_alu_out[31:2], 2'b00};  
             else if (MEM.jal_enable) if_pcmux_out = {mem_alu_out[31:2], 2'b00};
             else if (MEM.jalr_enable) if_pcmux_out = {mem_alu_out[31:1], 1'b0};
             else if (if_BTB_hit && if_predicted_branch_outcome[1]) if_pcmux_out = if_predicted_pcmux_out;//predicted taken branch
             end                                      
    end

    /**************************** BTB & Prediction Update *************************/
    /*****************************************************************************/
    always_comb begin :MEM_STATE
        mem_tag_in = mem_pc_out[31 : s_index+2];
        write_index = mem_pc_out[s_index+1 : 2];  
        is_branch = 1'b0;
        mem_misprediction = 1'b0;
        load_tag = 1'b0;
        load_address = 1'b0;
        load_prediction = 1'b0;
        mem_updated_address = '0;

        if (MEM.jal_enable || MEM.jalr_enable || MEM.branch_enable) is_branch = 1'b1;
        if (MEM.jal_enable || MEM.branch_enable) mem_updated_address = {mem_alu_out[31:2], 2'b00};
        if (MEM.jalr_enable) mem_updated_address = {mem_alu_out[31:1], 1'b0};

        if (~mem_BTB_hit && is_branch) begin     //entry not found in the BTB but a branch
                                      if (mem_actual_branch_outcome) mem_misprediction = 1'b1;
                                      load_tag = 1'b1;
                                      load_address = 1'b1; 
                                      load_prediction = 1'b1;
                                      end

        if (mem_BTB_hit) begin  //entry found in the BTB 
                        load_prediction = 1'b1;    
                        if (mem_actual_branch_outcome !== mem_predicted_branch_outcome[1]) mem_misprediction = 1'b1; //but mispredicted
                        else begin
                            if (mem_actual_branch_outcome && (mem_predicted_pcmux_out !== mem_updated_address)) begin
                               load_address = 1'b1;
                               mem_misprediction = 1'b1;
                            end
                        end
                        end
   end

    /**************************** Array Initialization ***************************/
    /*****************************************************************************/
    branch_history_register #(.width(n_previous_branches)) BHR (
    .clk,
    .rst,
    .load(is_branch),
    .in(mem_actual_branch_outcome),
    .out(BHR_history)
    );

    pattern_history_table #(.s_index(s_index), .width(2)) PHT[2**n_previous_branches-1:0] (
    .clk,
    .rst,
    .load(load_PHT),
    .rindex(read_index),
    .windex(write_index),
    .datain(mem_updated_prediction),
    .dataout(if_PHT_outcome)
    );

    prediction_array #(.s_index(s_index), .width(2)) local_predictor (
    .clk, 
    .rst, 
    .load(load_prediction), 
    .rindex(read_index), 
    .windex(write_index), 
    .datain(mem_updated_prediction), 
    .dataout(if_predicted_branch_outcome_local)
    );

    prediction_array #(.s_index(s_index), .width(2)) tournament_predictor (
    .clk, 
    .rst, 
    .load(load_prediction), 
    .rindex(read_index), 
    .windex(write_index), 
    .datain(mem_updated_prediction_tournament), 
    .dataout(if_predicted_branch_outcome_sel)
    );

     tournament_fsm tournament_fsm(
    .clk,
    .rst,
    .load_prediction,
    .mem_actual_branch_outcome,
    .mem_predicted_branch_outcome_sel,
    .mem_predicted_branch_outcome_local,  
    .mem_predicted_branch_outcome_global,
    .mem_updated_prediction_tournament
    );

    branch_array #(.s_index(s_index), .width(30-s_index)) tag_array (clk, rst, load_tag, read_index, write_index, mem_tag_in, if_tag_out);
    branch_array #(.s_index(s_index), .width(32)) address_array (clk, rst, load_address, read_index, write_index, mem_updated_address, if_predicted_pcmux_out);
    /**************************** MUX and decoder ********************************/
    /*****************************************************************************/
    always_comb begin    
    load_PHT = '0;
    if (load_prediction) begin
                         if (MEM.jal_enable || MEM.jalr_enable) load_PHT = '1;
                         else load_PHT[BHR_history] = 1'b1;
    end
    end

    assign if_predicted_branch_outcome_global = if_PHT_outcome[BHR_history]; 

    always_comb begin
    unique case (if_predicted_branch_outcome_sel)
    2'b00 : if_predicted_branch_outcome = if_predicted_branch_outcome_local;
    2'b01 : if_predicted_branch_outcome = if_predicted_branch_outcome_local;
    2'b10 : if_predicted_branch_outcome = if_predicted_branch_outcome_global;
    2'b11 : if_predicted_branch_outcome = if_predicted_branch_outcome_global;
    endcase
    end

endmodule : branch_prediction_datapath

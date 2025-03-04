import rv32i_types::*;

module branch_prediction #(parameter s_index = 10)

(
    input clk,
    input rst,

    input logic [31:0] if_pc_out,
    input logic [31:0] mem_pc_out,
    input logic [31:0] mem_alu_out, 
    input logic [31:0] mem_predicted_pcmux_out,
    input logic mem_BTB_hit,
    input logic mem_br_en,
    input rv32i_control MEM,
    input logic mem_actual_branch_outcome,
    input logic [1:0] mem_predicted_branch_outcome,

    output logic  [31:0]  if_predicted_pcmux_out,//the address of the predicted taken branch
    output logic [31:0] if_pcmux_out,
    output logic [1:0] if_predicted_branch_outcome,
    output logic if_BTB_hit,
    output logic mem_misprediction
);
  
  /************************* Internal Logic *******************************/
   logic [1:0] mem_updated_prediction;
   logic load_prediction;
  /***********************************************************************/

    branch_prediction_control branch_prediction_control
    (
        .clk,
        .rst,
        .mem_actual_branch_outcome(mem_actual_branch_outcome),
        .mem_predicted_branch_outcome(mem_predicted_branch_outcome),
        .load_prediction(load_prediction),
        .mem_updated_prediction(mem_updated_prediction)
    );

    branch_prediction_datapath #(.s_index(s_index)) branch_prediction_datapath
    (
        .clk,
        .rst,
        .if_pc_out(if_pc_out),
        .mem_pc_out(mem_pc_out),
        .mem_predicted_pcmux_out(mem_predicted_pcmux_out),
        .mem_updated_prediction(mem_updated_prediction),
        .mem_BTB_hit(mem_BTB_hit),
        .mem_alu_out(mem_alu_out),
        .MEM(MEM),
        .mem_actual_branch_outcome(mem_actual_branch_outcome),
        .mem_predicted_branch_outcome(mem_predicted_branch_outcome),
        .mem_br_en(mem_br_en),
        .if_pcmux_out(if_pcmux_out),
        .if_predicted_pcmux_out(if_predicted_pcmux_out),
        .if_predicted_branch_outcome(if_predicted_branch_outcome),
        .if_BTB_hit(if_BTB_hit),
        .load_prediction(load_prediction),
        .mem_misprediction(mem_misprediction)
    );

endmodule : branch_prediction

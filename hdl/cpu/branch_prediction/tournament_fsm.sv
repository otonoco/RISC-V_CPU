module tournament_fsm (
    input clk,
    input rst,
    input logic load_prediction,
    input logic mem_actual_branch_outcome, 
    input logic [1:0] mem_predicted_branch_outcome_sel,
    input logic [1:0] mem_predicted_branch_outcome_local,
    input logic [1:0] mem_predicted_branch_outcome_global,

    output logic [1:0] mem_updated_prediction_tournament
);

/* State Enumeration */
typedef enum logic [1:0] {
    /* List of states */
    SL = 2'b00, //strong local 
    WL = 2'b01, //weak local
    WG = 2'b10, //weak global
    SG = 2'b11	//strong global
} state_definition;

state_definition state, next_state;


/* Next State Logic */
always_comb begin : next_state_logic
    /* Default state transition */
    next_state = state;
    mem_updated_prediction_tournament = 2'b01;
    unique case(state_definition'(mem_predicted_branch_outcome_sel))
    SL: if (load_prediction) begin
                             mem_updated_prediction_tournament = 2'b00;
                             priority case(mem_actual_branch_outcome)
                             mem_predicted_branch_outcome_local[1]: begin
                                                                   next_state =  SL; 
                                                                   mem_updated_prediction_tournament = 2'b00;
                                                                   end

                             mem_predicted_branch_outcome_global[1]: begin
                                                                   next_state =  WL; 
                                                                   mem_updated_prediction_tournament = 2'b01;
                                                                   end
                             endcase
                             end

    WL: if (load_prediction) begin
                             mem_updated_prediction_tournament = 2'b01;
                             priority case(mem_actual_branch_outcome)
                             mem_predicted_branch_outcome_local[1]: begin
                                                                   next_state =  SL; 
                                                                   mem_updated_prediction_tournament = 2'b00;
                                                                   end

                             mem_predicted_branch_outcome_global[1]: begin
                                                                   next_state =  WG; 
                                                                   mem_updated_prediction_tournament = 2'b10;
                                                                   end
                             endcase
                             end

    WG: if (load_prediction) begin
                             mem_updated_prediction_tournament = 2'b10;
                             priority case(mem_actual_branch_outcome)
                             mem_predicted_branch_outcome_global[1]: begin
                                                                    next_state =  SG; 
                                                                    mem_updated_prediction_tournament = 2'b11;
                                                                   end

                             mem_predicted_branch_outcome_local[1]: begin
                                                                   next_state =  WL; 
                                                                   mem_updated_prediction_tournament = 2'b01;
                                                                   end
                             endcase
                             end

    SG: if (load_prediction) begin
                             mem_updated_prediction_tournament = 2'b11;
                             priority case(mem_actual_branch_outcome)
                             mem_predicted_branch_outcome_global[1]: begin
                                                                    next_state =  SG; 
                                                                    mem_updated_prediction_tournament = 2'b11;
                                                                   end

                             mem_predicted_branch_outcome_local[1]: begin
                                                                   next_state =  WG; 
                                                                   mem_updated_prediction_tournament = 2'b10;
                                                                   end
                             endcase
                             end
    endcase
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
     if (rst) state <= WL;
     else state <= next_state;
end

endmodule : tournament_fsm

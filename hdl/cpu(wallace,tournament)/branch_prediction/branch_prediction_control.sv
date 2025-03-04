module branch_prediction_control (
    input clk,
    input rst,
    input logic mem_actual_branch_outcome, 
    input logic [1:0] mem_predicted_branch_outcome,

    input logic load_prediction,
    output logic [1:0] mem_updated_prediction
);

    /* State Enumeration */
    typedef enum logic [1:0] {
        /* List of states */
        SN = 2'b00, 
        WN = 2'b01, 
        WT = 2'b10,
        ST = 2'b11	
    } state_definition;

    state_definition state, next_state;
    //assign state = state_definition'(ex_predicted_branch_outcome);

    /* State Output Signals */
    /*always_comb begin : state_actions    
        load_prediction = 1'b0;
        unique case(state)
            SN: begin 
                load_prediction = 1'b1;
                ex_updated_prediction = 2'b00;
                end

            WN: begin
                load_prediction = 1'b1;
                ex_updated_prediction = 2'b01;
                end

            WT: begin
                load_prediction = 1'b1;
                ex_updated_prediction = 2'b10;
                end

            ST: begin
                load_prediction = 1'b1;
                ex_updated_prediction = 2'b11;
                end
        endcase
    end*/

    /* Next State Logic */
    always_comb begin : next_state_logic
        /* Default state transition */
        next_state = state;
        mem_updated_prediction = 2'b01;
        unique case (state_definition'(mem_predicted_branch_outcome))
        SN: 
            if (load_prediction) 
                begin
                    next_state = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? SN : WN; //predicted to be not taken
                    mem_updated_prediction = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? 2'b00 : 2'b01;
                end
            else 
                begin
                    next_state = SN;
                    mem_updated_prediction = 2'b00;
                end

        WN: 
            if (load_prediction) 
                begin
                    next_state = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? SN : WT; //predicted to be not taken
                    mem_updated_prediction = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? 2'b00 : 2'b10;
                end
            else
                begin
                    next_state = WN;
                    mem_updated_prediction = 2'b01;
                end

        WT: 
            if (load_prediction) 
                begin
                    next_state = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? ST : WN; //predicted to be taken
                    mem_updated_prediction = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? 2'b11 : 2'b01;
                end
            else 
                begin
                    next_state = WT;
                    mem_updated_prediction = 2'b10;
                end

        ST: 
            if (load_prediction) 
                begin
                    next_state = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? ST : WT; //predicted to be taken
                    mem_updated_prediction = (mem_actual_branch_outcome == mem_predicted_branch_outcome[1]) ? 2'b11 : 2'b10;
                end
            else 
                begin
                    next_state = ST;
                    mem_updated_prediction = 2'b11;
                end
        endcase
    end

    /* Next State Assignment */
    always_ff @(posedge clk) begin: next_state_assignment
        if (rst) 
            begin
                state <= WN;
            end
        else 
            begin
                state <= next_state;
            end
    end

endmodule : branch_prediction_control

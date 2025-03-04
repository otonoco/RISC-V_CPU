//import rv32i_types::*;

module Wallace_controller(
    input clk,
    input rst,
    input mul_enable,

    output logic mul_add, mul_resp
);
    enum logic [1:0] {IDLE, MUL, DONE} state, next_state;

    always_comb 
    begin
        mul_resp = 1'b0;
        mul_add = 1'b0;
        unique case(state)
            IDLE: ;
            MUL: mul_add = 1'b1;
            DONE: mul_resp = 1'b1 ;
        endcase
    end

    always_comb 
    begin
        next_state = state;
        unique case (state)
            IDLE: 
                if (mul_enable)
                    begin
                        next_state = MUL;
                    end
                else 
                    begin
                        next_state = IDLE;
                    end
        
            MUL:   next_state = DONE;

            DONE:  next_state = IDLE;
            
        endcase
    end

    always_ff @ (posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
   end

endmodule: Wallace_controller

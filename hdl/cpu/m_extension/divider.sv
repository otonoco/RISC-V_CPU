
import rv32i_types::*;

module divider(
    input clk,
    input rst,
    input rv32i_control EXE,
    input div_enable,
    input [31:0] a,b, 
    output logic [31:0] f,
    output logic div_resp
);

    logic valid, valid2;
    logic sign_a, sign_b, sign_r;
    logic [31:0] modified_a, modified_b;
    logic [31:0] buffer_a, buffer_b, buffer_r, buffer_r2;
    logic [32:0] interm;
    logic [5:0] counter;


    assign sign_a = a[31];
    assign sign_b = b[31];
    assign interm = sign_r ? ({buffer_r, buffer_a[31]} + {1'b0, buffer_b}) : ({buffer_r, buffer_a[31]} - {1'b0, buffer_b});
    assign buffer_r2 = sign_r ? (buffer_r + buffer_b) : buffer_r;
    assign div_resp = ~valid && valid2;

    always_comb begin
        modified_a = '0;
        modified_b = '0;
        unique case (EXE.funct3)
            div, rem: begin
                        modified_a = sign_a ? (~a+1'b1) : a;
                        modified_b = sign_b ? (~b+1'b1) : b;
                        end
                
            divu, remu: begin
                          modified_a = a;
                          modified_b = b;
                          end
        endcase
     end
/*    always_ff @(posedge clk) begin
        if (rst || ~mul_enable || mul_resp) begin
           valid <= 1'b0;
        end
        else valid <= 1'b1;
    end  


     always_ff @(posedge clk) begin
     if (valid) begin
         buffer_a <= (buffer_a << 1'b1);
         buffer_b <= (buffer_b >> 1'b1);
         temp_f <= temp_f + (buffer_b[0] ? buffer_a : 64'd0);         
     end
     else if (mul_enable) begin
         buffer_a <= {32'b0, modified_a}; 
         buffer_b <= modified_b;
         temp_f <= '0;
         end
     end  
*/
    always_ff @(posedge clk) begin
        if (rst) begin
         counter <= '0;
         valid2 <= 1'b0;
         valid <= 1'b0;
        end
        else begin
         valid2 <= valid;
         if (div_enable && ~valid && ~valid2) begin
             buffer_r <= 32'b0;
             sign_r <= 1'b0;
             buffer_a <= modified_a;
             buffer_b <= modified_b;
             counter <= '0;
             valid <= 1'b1;    
         end
         else if (valid) begin
             buffer_r <= interm[31:0];
             sign_r <= interm[32];
             buffer_a <= {buffer_a[30:0], ~interm[32]};
             counter <= counter + 1'b1;
             if (counter == 31)     valid <= 1'b0;
         end
         end
     end
                          
    always_comb begin
        f = '0;
        unique case (EXE.funct3)
            div:    f = (sign_a ^ sign_b)? (~buffer_a + 1'b1) : buffer_a;
            rem:    f = sign_a ? (~buffer_r2 + 1'b1) : buffer_r2;
            divu:   f = buffer_a;
            remu:   f = buffer_r2;
        endcase
     end
endmodule

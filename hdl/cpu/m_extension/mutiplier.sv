
import rv32i_types::*;

module multiplier(
    input clk,
    input rst,
    input rv32i_control EXE,
    input mul_enable,
    input [31:0] a,b, 
    output logic [31:0] f,
    output logic mul_resp
);

    logic valid;
    logic sign_a, sign_b, sign_f;
    logic [31:0] modified_a, modified_b, buffer_b;
    logic [63:0] buffer_a;
    logic [63:0] buffer_f, buffer_fsu, temp_f;

    assign sign_a = a[31];
    assign sign_b = b[31];
    assign sign_f = sign_a ^ sign_b;
    assign mul_resp = valid && (buffer_b == '0);
     
    always_comb begin
        modified_a = '0;
        modified_b = '0;
        unique case (EXE.funct3)
            mul, mulh: begin
                       modified_a = a[31] ? (~a+1'b1) : a;
                       modified_b = b[31] ? (~b+1'b1) : b;
                       end
                
            mulhsu: begin
                    modified_a = a[31] ? (~a+1'b1) : a;
                    modified_b = b;
                    end

            mulhu:  begin
                    modified_a = a;
                    modified_b = b;
                    end
        endcase
     end

    always_ff @(posedge clk) begin
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
    
     assign buffer_f = sign_f ? (~temp_f+1'b1) : temp_f; 
     assign buffer_fsu = sign_a ? (~temp_f+1'b1) : temp_f;         
                                 
     always_comb begin
         f = '0;
         unique case (EXE.funct3)
             mul:     f = buffer_f[31:0];
             mulh:    f = buffer_f[63:32];
             mulhsu:  f = buffer_fsu[63:32];
             mulhu:   f = temp_f[63:32];
         endcase
     end
endmodule

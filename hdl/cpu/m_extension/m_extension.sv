
import rv32i_types::*;

module m_extension(
    input clk,
    input rst,
    input rv32i_control EXE,
    input [31:0] a,b, 
    output logic [31:0] f,
    output logic m_resp
);

    logic mul_enable, div_enable, mul_resp, div_resp;
    logic [31:0] mul_f, div_f;
     
    always_comb begin
        mul_enable = 1'b0;
        div_enable = 1'b0;
        m_resp = 1'b0;
        f = '0;
        if (EXE.m_enable) begin
            unique case (EXE.funct3)
                mul, mulh, mulhsu, mulhu: begin
                                          mul_enable = 1'b1;
                                          m_resp = mul_resp;
                                          f = mul_f;   
                                          end  

                div, divu, rem, remu: begin
                                          div_enable = 1'b1;
                                          m_resp = div_resp;
                                          f = div_f;   
                                          end
            endcase 
        end                                
    end
    multiplier MUL (.*, .f(mul_f));
    divider DIV (.*, .f(div_f));
endmodule

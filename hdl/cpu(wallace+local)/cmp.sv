import rv32i_types::*;

module cmp (input branch_funct3_t cmpop,    
            input rv32i_word rs1_out,
            input rv32i_word cmpmux_out,
            output logic br_en
);
    always_comb 
    begin
        unique case(cmpop)
            beq:
                begin
                    if (rs1_out == cmpmux_out)
                        begin
                            br_en = 1'b1;
                        end
                    else
                        begin
                            br_en = 1'b0;
                        end
                end
            bne:
                begin
                    if (rs1_out != cmpmux_out)
                        begin
                            br_en = 1'b1;
                        end
                    else
                        begin
                            br_en = 1'b0;
                        end
                end
            blt:
                begin
                    if ($signed(rs1_out) < $signed(cmpmux_out))
                        begin
                            br_en = 1'b1;
                        end
                    else
                        begin
                            br_en = 1'b0;
                        end
                end
            bge:
                begin
                    if ($signed(rs1_out) >= $signed(cmpmux_out))
                        begin
                            br_en = 1'b1;
                        end
                    else
                        begin
                            br_en = 1'b0;
                        end
                end
            bltu:
                begin
                    if (rs1_out < cmpmux_out)
                        begin
                            br_en = 1'b1;
                        end
                    else
                        begin
                            br_en = 1'b0;
                        end
                end
            bgeu:
                begin
                    if (rs1_out >= cmpmux_out)
                        begin
                            br_en = 1'b1;
                        end
                    else
                        br_en = 1'b0;
                end
            default: br_en = 1'b0;
        endcase
    end
endmodule : cmp
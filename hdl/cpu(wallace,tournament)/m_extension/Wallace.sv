
import rv32i_types::*;

module Wallace(
    input clk,
    input rst,
    input [31:0] a,b, 
    input rv32i_control EXE,
    input mul_enable,
    input mul_add,
    output logic [31:0] f
);


    logic [63:0] pp_temp0, pp_temp1, pp_temp2, pp_temp3, pp_temp4, pp_temp5, pp_temp6, pp_temp7, pp_temp8, pp_temp9, pp_temp10, pp_temp11, pp_temp12, pp_temp13, pp_temp14, pp_temp15, pp_temp16;
    logic [63:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15, pp16;
    logic [63:0] modified_a;
    logic [34:0] modified_b;

    always_comb begin
        modified_a = '0;
        modified_b = '0;
        if (mul_enable) 
            begin
                unique case (EXE.funct3)
                    mul, mulh: 
                        begin
                            modified_a = {{32{a[31]}}, a};
                            modified_b = {{2{b[31]}}, b, 1'b0};
                        end
                        
                    mulhsu: 
                        begin
                            modified_a = {{32{a[31]}}, a};
                            modified_b = {2'b0, b, 1'b0};
                        end

                    mulhu:
                        begin
                            modified_a = {32'b0, a};
                            modified_b = {2'b0, b, 1'b0};
                        end
                endcase
            end
    end

    booth_encoder BE1 (modified_a, modified_b[2:0], pp_temp0);
    booth_encoder BE2 (modified_a, modified_b[4:2], pp_temp1);
    booth_encoder BE3 (modified_a, modified_b[6:4], pp_temp2);
    booth_encoder BE4 (modified_a, modified_b[8:6], pp_temp3);
    booth_encoder BE5 (modified_a, modified_b[10:8], pp_temp4);
    booth_encoder BE6 (modified_a, modified_b[12:10], pp_temp5);
    booth_encoder BE7 (modified_a, modified_b[14:12], pp_temp6);
    booth_encoder BE8 (modified_a, modified_b[16:14], pp_temp7);
    booth_encoder BE9 (modified_a, modified_b[18:16], pp_temp8);
    booth_encoder BE10 (modified_a, modified_b[20:18], pp_temp9);
    booth_encoder BE11 (modified_a, modified_b[22:20], pp_temp10);
    booth_encoder BE12 (modified_a, modified_b[24:22], pp_temp11);
    booth_encoder BE13 (modified_a, modified_b[26:24], pp_temp12);
    booth_encoder BE14 (modified_a, modified_b[28:26], pp_temp13);
    booth_encoder BE15 (modified_a, modified_b[30:28], pp_temp14);
    booth_encoder BE16 (modified_a, modified_b[32:30], pp_temp15);
    booth_encoder BE17 (modified_a, modified_b[34:32], pp_temp16);

    logic gclk;

    assign gclk = mul_enable && clk;

    always_ff @(posedge gclk) begin
        if (rst) 
            begin
            pp0 <= '0;
            pp1 <= '0;
            pp2 <= '0;
            pp3 <= '0;
            pp4 <= '0;
            pp5 <= '0;
            pp6 <= '0;
            pp7 <= '0;
            pp8 <= '0;
            pp9 <= '0;
            pp10 <= '0;
            pp11 <= '0;
            pp12 <= '0;
            pp13 <= '0;
            pp14 <= '0;
            pp15 <= '0;
            pp16 <= '0;
            end
        else 
            begin  
                pp0 <= pp_temp0;
                pp1 <= (pp_temp1 << 2);
                pp2 <= (pp_temp2 << 4);
                pp3 <= (pp_temp3 << 6);
                pp4 <= (pp_temp4 << 8);
                pp5 <= (pp_temp5 << 10);
                pp6 <= (pp_temp6 << 12);
                pp7 <= (pp_temp7 << 14);
                pp8 <= (pp_temp8 << 16);
                pp9 <= (pp_temp9 << 18);
                pp10 <= (pp_temp10 << 20);
                pp11 <= (pp_temp11 << 22);
                pp12 <= (pp_temp12 << 24);
                pp13 <= (pp_temp13 << 26);
                pp14 <= (pp_temp14 << 28);
                pp15 <= (pp_temp15 << 30);
                pp16 <= (pp_temp16 << 32);
            end
    end


    logic [63:0] S1_1, S1_2, S1_3, S1_4, S2_1, S2_2, S3, S4, S4_temp, S;
    logic [63:0] C1_1, C1_2, C1_3, C1_4, C2_1, C2_2, C3, C4, C4_temp;

    compress42_64_bit cp1_1 (.P0(pp0), .P1(pp1), .P2(pp2), .P3(pp3), .Cin(1'b0), .Cout(), .C(C1_1), .S(S1_1));
    compress42_64_bit cp1_2 (.P0(pp4), .P1(pp5), .P2(pp6), .P3(pp7), .Cin(1'b0), .Cout(), .C(C1_2), .S(S1_2));
    compress42_64_bit cp1_3 (.P0(pp8), .P1(pp9), .P2(pp10), .P3(pp11), .Cin(1'b0), .Cout(), .C(C1_3), .S(S1_3));
    compress42_64_bit cp1_4 (.P0(pp12), .P1(pp13), .P2(pp14), .P3(pp15), .Cin(1'b0), .Cout(), .C(C1_4), .S(S1_4));
    compress42_64_bit cp2_1 (.P0(S1_1), .P1(C1_1<<1'b1), .P2(S1_2), .P3(C1_2<<1'b1), .Cin(1'b0), .Cout(), .C(C2_1), .S(S2_1));  
    compress42_64_bit cp2_2 (.P0(S1_3), .P1(C1_3<<1'b1), .P2(S1_4), .P3(C1_4<<1'b1), .Cin(1'b0), .Cout(), .C(C2_2), .S(S2_2)); 
    compress42_64_bit cp3_1 (.P0(S2_1), .P1(C2_1<<1'b1), .P2(S2_2), .P3(C2_2<<1'b1), .Cin(1'b0), .Cout(), .C(C3), .S(S3));      
    compress42_64_bit cp4_1 (.P0(S3), .P1(C3<<1'b1), .P2(pp16), .P3('0), .Cin(1'b0), .Cout(), .C(C4_temp), .S(S4_temp)); 

    register #(.width(64)) R1(
        .clk,
        .rst,
        .load(mul_add),
        .in(C4_temp),
        .out(C4)
    );

    register #(.width(64)) R2 (
        .clk,
        .rst,
        .load(mul_add),
        .in(S4_temp),
        .out(S4)
    );
    
    CLA_64_bit cla (.a(S4), .b(C4 << 1'b1),.S(S));

    always_comb 
    begin
        f = '0;
        unique case (EXE.funct3)
            mul:     f = S[31:0];
            mulh:    f = S[63:32];
            mulhsu:  f = S[63:32];
            mulhu:   f = S[63:32];
        endcase
    end
endmodule : Wallace

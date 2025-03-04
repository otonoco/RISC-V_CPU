

module compress42_32_bit(
    input [31:0] P0, P1, P2, P3, 
    input logic Cin,
    output logic Cout,
    output logic [31:0] C, S
);
     logic Cout_temp;

     compress42_16_bit cp1 (.P0(P0[15:0]), .P1(P1[15:0]), .P2(P2[15:0]), .P3(P3[15:0]), .Cin(Cin), .Cout(Cout_temp), .C(C[15:0]), .S(S[15:0]));
     compress42_16_bit cp2 (.P0(P0[31:16]), .P1(P1[31:16]), .P2(P2[31:16]), .P3(P3[31:16]), .Cin(Cout_temp), .Cout(Cout), .C(C[31:16]), .S(S[31:16]));


endmodule : compress42_32_bit

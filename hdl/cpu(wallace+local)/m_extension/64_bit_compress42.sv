

module compress42_64_bit(
    input [63:0] P0, P1, P2, P3, 
    input logic Cin,
    output logic Cout,
    output logic [63:0] C, S
);
     logic Cout_temp;

     compress42_32_bit cp1 (.P0(P0[31:0]), .P1(P1[31:0]), .P2(P2[31:0]), .P3(P3[31:0]), .Cin(Cin), .Cout(Cout_temp), .C(C[31:0]), .S(S[31:0]));
     compress42_32_bit cp2 (.P0(P0[63:32]), .P1(P1[63:32]), .P2(P2[63:32]), .P3(P3[63:32]), .Cin(Cout_temp), .Cout(Cout), .C(C[63:32]), .S(S[63:32]));


endmodule : compress42_64_bit

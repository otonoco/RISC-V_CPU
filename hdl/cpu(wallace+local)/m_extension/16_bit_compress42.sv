

module compress42_16_bit(
    input [15:0] P0, P1, P2, P3, 
    input logic Cin,
    output logic Cout,
    output logic [15:0] C, S
);
     logic Cout_temp;

     compress42_8_bit cp1 (.P0(P0[7:0]), .P1(P1[7:0]), .P2(P2[7:0]), .P3(P3[7:0]), .Cin(Cin), .Cout(Cout_temp), .C(C[7:0]), .S(S[7:0]));
     compress42_8_bit cp2 (.P0(P0[15:8]), .P1(P1[15:8]), .P2(P2[15:8]), .P3(P3[15:8]), .Cin(Cout_temp), .Cout(Cout), .C(C[15:8]), .S(S[15:8]));


endmodule : compress42_16_bit

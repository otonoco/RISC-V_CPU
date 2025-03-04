

module compress42_8_bit(
    input [7:0] P0, P1, P2, P3, 
    input logic  Cin,
    output logic Cout,
    output logic [7:0] C, S
);

     logic [7:0] Cout_temp;

     assign Cout = Cout_temp[7];

     compress42 cp1_1 (.P0(P0[0]), .P1(P1[0]), .P2(P2[0]), .P3(P3[0]), .Cin(Cin), .Cout(Cout_temp[0]), .C(C[0]), .S(S[0]));
     compress42 cp1_2 (.P0(P0[1]), .P1(P1[1]), .P2(P2[1]), .P3(P3[1]), .Cin(Cout_temp[0]), .Cout(Cout_temp[1]), .C(C[1]), .S(S[1]));
     compress42 cp1_3 (.P0(P0[2]), .P1(P1[2]), .P2(P2[2]), .P3(P3[2]), .Cin(Cout_temp[1]), .Cout(Cout_temp[2]), .C(C[2]), .S(S[2]));
     compress42 cp1_4 (.P0(P0[3]), .P1(P1[3]), .P2(P2[3]), .P3(P3[3]), .Cin(Cout_temp[2]), .Cout(Cout_temp[3]), .C(C[3]), .S(S[3]));
     compress42 cp1_5 (.P0(P0[4]), .P1(P1[4]), .P2(P2[4]), .P3(P3[4]), .Cin(Cout_temp[3]), .Cout(Cout_temp[4]), .C(C[4]), .S(S[4]));
     compress42 cp1_6 (.P0(P0[5]), .P1(P1[5]), .P2(P2[5]), .P3(P3[5]), .Cin(Cout_temp[4]), .Cout(Cout_temp[5]), .C(C[5]), .S(S[5]));
     compress42 cp1_7 (.P0(P0[6]), .P1(P1[6]), .P2(P2[6]), .P3(P3[6]), .Cin(Cout_temp[5]), .Cout(Cout_temp[6]), .C(C[6]), .S(S[6]));
     compress42 cp1_8 (.P0(P0[7]), .P1(P1[7]), .P2(P2[7]), .P3(P3[7]), .Cin(Cout_temp[6]), .Cout(Cout_temp[7]), .C(C[7]), .S(S[7]));

endmodule : compress42_8_bit



module compress42(
    input  P0, P1, P2, P3, Cin,
    output logic Cout,
    output logic S,
    output logic C
);

    logic inter;
    
    assign inter = P0 ^ P1 ^ P2;
    assign Cout = P0 & P1 | P1 & P2 | P2 & P0;
    assign S = P3 ^ Cin ^ inter;
    assign C = inter & P3 | P3 & Cin | Cin & inter;

endmodule : compress42

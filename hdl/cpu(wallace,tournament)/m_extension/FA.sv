module FA (
    input logic a, b, cin,

    output logic sum,  
    output logic cout
);

    assign sum = (a ^ b) ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule : FA    

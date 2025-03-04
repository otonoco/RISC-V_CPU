
module booth_encoder(
    input [63:0] a,
    input [2:0] b, 
    output logic [63:0] pp_temp
);

    logic [63:0] p_2a, n_2a;

    assign p_2a = a << 1'b1;
    assign n_2a = ~p_2a + 1'b1;

    always_comb begin
    pp_temp = '0;
    unique case (b)
    3'b000 : pp_temp = '0;  //0
    3'b001 : pp_temp = a;   //+X
    3'b010 : pp_temp = a;   //+X
    3'b011 : pp_temp = p_2a ; //+2X
    3'b100 : pp_temp = n_2a; //-2X
    3'b101 : pp_temp = ~a + 1'b1; //-X
    3'b110 : pp_temp = ~a + 1'b1; //-X
    3'b111 : pp_temp = '0;        //0
    endcase
    end

endmodule : booth_encoder

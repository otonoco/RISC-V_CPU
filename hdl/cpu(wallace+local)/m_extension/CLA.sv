module CLA_64_bit(
    input [63:0] a, b, 
    output logic [63:0] S
);
     logic [64:0] c;
     logic [63:0] g, p, sum;

     assign c[0] = 1'b0;
 
     genvar  i;
     generate
         for (i=0; i<64; i++) begin : generate_block1
              FA FA (
                 .a(a[i]),
                 .b(b[i]),
                 .cin(c[i]),
                 .sum(sum[i]),
                 .cout()
               );
          end
     endgenerate

     genvar  j;
     generate 
         for (j=0; j<64; j++) begin : generate_block2
            assign g[j] = a[j] & b[j];
            assign p[j] = a[j] | b[j];
            assign c[j+1] = g[j] | (p[j] & c[j]);
         end
     endgenerate

assign S = sum;

endmodule : CLA_64_bit

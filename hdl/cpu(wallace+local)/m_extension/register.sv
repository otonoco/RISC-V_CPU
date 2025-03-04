/* DO NOT MODIFY. WILL BE OVERRIDDEN BY THE AUTOGRADER. */

module register #(parameter width = 32)
(
    input clk,
    input rst,
    input load,
    input [width-1:0] in,
    output logic [width-1:0] out
);

logic [width-1:0] data = '0;

logic gclk;

assign gclk = load && clk;

always_ff @(posedge gclk) begin
    if (rst) data <= '0;
    else data <= in;
end 

always_comb
begin
    out = data;
end

endmodule : register

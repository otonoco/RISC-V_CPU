
module branch_array #(
    parameter s_index = 10,
    parameter width = 32
   // parameter default_value = 2'b01
)
(
  input clk,
  input rst,
  input logic load,
  input logic [s_index-1:0] rindex,
  input logic [s_index-1:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

//logic [width-1:0] data [2:0] = '{default: '0};
logic [width-1:0] data [2**s_index];


always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < 2**s_index; ++i)
            data[i] <= 'x;
    end
    else if(load)
        data[windex] <= datain;
end

endmodule : branch_array

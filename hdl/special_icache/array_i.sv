
module array_i #(parameter width = 1)
(
  input clk,
  input logic load,
  input logic [5:0] rindex,
  input logic [5:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

//logic [width-1:0] data [2:0] = '{default: '0};
logic [width-1:0] data [64];
initial begin
  data[0] = 0;
  data[1] = 0;
  data[2] = 0;
  data[3] = 0;
  data[4] = 0;
  data[5] = 0;
  data[6] = 0;
  data[7] = 0;
  data[8] = 0;
  data[9] = 0;
  data[10] = 0;
  data[11] = 0;
  data[12] = 0;
  data[13] = 0;
  data[14] = 0;
  data[15] = 0;
  data[16] = 0;
  data[17] = 0;
  data[18] = 0;
  data[19] = 0;
  data[20] = 0;
  data[21] = 0;
  data[22] = 0;
  data[23] = 0;
  data[24] = 0;
  data[25] = 0;
  data[26] = 0;
  data[27] = 0;
  data[28] = 0;
  data[29] = 0;
  data[30] = 0;
  data[31] = 0;
  data[32] = 0;
  data[33] = 0;
  data[34] = 0;
  data[35] = 0;
  data[36] = 0;
  data[37] = 0;
  data[38] = 0;
  data[39] = 0;
  data[40] = 0;
  data[41] = 0;
  data[42] = 0;
  data[43] = 0;
  data[44] = 0;
  data[45] = 0;
  data[46] = 0;
  data[47] = 0;
  data[48] = 0;
  data[49] = 0;
  data[50] = 0;
  data[51] = 0;
  data[52] = 0;
  data[53] = 0;
  data[54] = 0;
  data[55] = 0;
  data[56] = 0;
  data[57] = 0;
  data[58] = 0;
  data[59] = 0;
  data[60] = 0;
  data[61] = 0;
  data[62] = 0;
  data[63] = 0;
end

always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
    if(load)
        data[windex] <= datain;
end

endmodule : array_i

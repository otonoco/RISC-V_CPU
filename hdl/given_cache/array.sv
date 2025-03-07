
module array #(parameter width = 1, parameter num_index = 4)
(
  input clk,
  input logic load,
  input logic [num_index-1:0] rindex,
  input logic [num_index-1:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

//logic [width-1:0] data [2:0] = '{default: '0};
logic [width-1:0] data [2**num_index] = '{default: '0};
// initial begin
//   data[0] = 0;
//   data[1] = 0;
//   data[2] = 0;
//   data[3] = 0;
//   data[4] = 0;
//   data[5] = 0;
//   data[6] = 0;
//   data[7] = 0;
//   data[8] = 0;
//   data[9] = 0;
//   data[10] = 0;
//   data[11] = 0;
//   data[12] = 0;
//   data[13] = 0;
//   data[14] = 0;
//   data[15] = 0;
//   // data[16] = 0;
//   // data[17] = 0;
//   // data[18] = 0;
//   // data[19] = 0;
//   // data[20] = 0;
//   // data[21] = 0;
//   // data[22] = 0;
//   // data[23] = 0;
//   // data[24] = 0;
//   // data[25] = 0;
//   // data[26] = 0;
//   // data[27] = 0;
//   // data[28] = 0;
//   // data[29] = 0;
//   // data[30] = 0;
//   // data[31] = 0;
// end

always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
    if (load)
    begin
    data[windex] <= datain;
    end
end

endmodule : array

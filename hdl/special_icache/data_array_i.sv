module data_array_i (
  input clk,
  input logic [31:0] write_en,
  input logic [5:0] rindex,
  input logic [5:0] windex,
  input logic [255:0] datain,
  output logic [255:0] dataout
);

logic [255:0] data [64] = '{default: '0};

always_comb begin
  for (int i = 0; i < 32; i++) begin
      dataout[8*i +: 8] = (write_en[i] & (rindex == windex)) ? datain[8*i +: 8] : data[rindex][8*i +: 8];
  end
end

always_ff @(posedge clk) begin
    for (int i = 0; i < 32; i++) begin
		  data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[windex][8*i +: 8];
    end
end

endmodule : data_array_i

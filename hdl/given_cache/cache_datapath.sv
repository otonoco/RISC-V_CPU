module cache_datapath #(
  parameter num_index = 4
)
(
  input clk,

  /* CPU memory data signals */
  input logic  [31:0]  mem_byte_enable,
  input logic  [31:0]  mem_address,
  input logic  [255:0] mem_wdata,
  output logic [255:0] mem_rdata,

  /* Physical memory data signals */
  input  logic [255:0] pmem_rdata,
  output logic [255:0] pmem_wdata,
  output logic [31:0]  pmem_address,

  /* Control signals */
  input logic tag_load,
  input logic valid_load,
  input logic dirty_load,
  input logic dirty_in,
  output logic dirty_out,

  output logic hit,
  input logic [1:0] writing
);

logic [255:0] line_in, line_out;
logic [22:0] address_tag, tag_out;
logic [num_index - 1:0]  index;
logic [31:0] mask;
logic valid_out;

always_comb begin
  address_tag = mem_address[31:5 + num_index];
  index = mem_address[5 + num_index - 1:5];
  hit = valid_out && (tag_out == address_tag);
  pmem_address = (dirty_out) ? {tag_out, mem_address[5 + num_index - 1:0]} : mem_address;
  mem_rdata = line_out;
  pmem_wdata = line_out;

  case(writing)
    2'b00: begin // load from memory
      mask = 32'hFFFFFFFF;
      line_in = pmem_rdata;
    end
    2'b01: begin // write from cpu
      mask = mem_byte_enable;
      line_in = mem_wdata;
    end
    default: begin // don't change data
      mask = 32'b0;
      line_in = mem_wdata;
    end
	endcase
end

data_array #(num_index) DM_cache (clk, mask, index, index, line_in, line_out);
array #(32 - 5 - num_index, num_index) tag (clk, tag_load, index, index, address_tag, tag_out);
array #(1, num_index) valid (clk, valid_load, index, index, 1'b1, valid_out);
array #(1, num_index) dirty (clk, dirty_load, index, index, dirty_in, dirty_out);

endmodule : cache_datapath

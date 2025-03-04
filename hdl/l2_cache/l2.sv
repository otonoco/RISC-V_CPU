module l2_cache #(
    parameter num_ways = 8,
    parameter num_offset = 5,
    parameter num_index = 3
)
(
    input clk,
    input rst,

    // Interaction with CPU //
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata,
    output logic mem_resp,
    output logic [255:0] mem_rdata,

    // Interaction with Memory //
    input logic pmem_resp,
    input logic [255:0] pmem_rdata,
    output logic [31:0] pmem_address,
    output logic [255:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write
);

    logic tag_load, valid_load, dirty_load, lru_load;
    logic dirty_in;
    logic dirty;
    logic cache_write;
    logic addr_sel;

    logic hitt;
    logic writing;

    l2_control control (
        .clk(clk), 

        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_resp(mem_resp),

        .hitt(hitt),
        .dirty(dirty),
        .tag_load(tag_load),
        .lru_load(lru_load),
        .valid_load(valid_load),
        .dirty_load(dirty_load),
        .dirty_in(dirty_in),
        .cache_write(cache_write),
        .addr_sel(addr_sel),
        .writing(writing),

        .pmem_resp(pmem_resp),
        .pmem_read(pmem_read),
        .pmem_write(pmem_write)
    );

    l2_datapath #(num_ways, num_offset, num_index) datapath (
        .clk(clk),

        .mem_address(mem_address),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),

        .pmem_rdata(pmem_rdata),
        .pmem_wdata(pmem_wdata),
        .pmem_address(pmem_address),

        .tag_load(tag_load),
        .lru_load(lru_load),
        .valid_load(valid_load),
        .cache_write(cache_write),
        .dirty_load(dirty_load),
        .dirty_in(dirty_in),
        .addr_sel(addr_sel),
        .writing(writing),
        .dirty(dirty),
        .hitt(hitt)
    );

endmodule : l2_cache
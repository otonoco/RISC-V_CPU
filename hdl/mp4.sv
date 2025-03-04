import rv32i_types::*;
//it contains cpu and cache, with input/output ports for physical memory
module mp4
(
    input clk,
    input rst,
    input mem_resp,
    input [63:0] mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [31:0] mem_address,
    output [63:0] mem_wdata
);

    //*************************** Declare Logic ***************************//

    // CPU - ICache Logic
    logic icache_mem_resp_cache, icache_mem_read_cache;
    logic [31:0] icache_address_cache;
    rv32i_word icache_rdata_cache;

    // CPU - DCache Logic
    logic dcache_mem_resp_cache, dcache_mem_read_cache, dcache_mem_write_cache;
    logic [31:0] dcache_address_cache;
    rv32i_word dcache_rdata_cache, dcache_wdata_cache;
    logic [3:0] dcache_mem_byte_enable_cache;

    // ICache - Arbiter Logic
    logic icache_mem_resp_arb, icache_mem_read_arb;
    logic [31:0] icache_address_arb;
    logic [255:0] icache_rdata_arb;

    // DCache - Arbiter Logic
    logic dcache_mem_resp_arb, dcache_mem_read_arb, dcache_mem_write_arb;
    logic [31:0] dcache_address_arb;
    logic [255:0] dcache_rdata_arb, dcache_wdata_arb;

    // Arbiter - L2 Cache Logic
    logic l2_resp, l2_read, l2_write;
    logic [31:0] l2_address;
    logic [255:0] l2_rdata, l2_wdata;

    // L2 Cache - EWB Logic
    logic ewb_resp, ewb_read, ewb_write;
    logic [31:0] ewb_address;
    logic [255:0] ewb_rdata, ewb_wdata;

    // EWB - Cacheline Adaptor Logic
    logic pmem_resp, pmem_read, pmem_write;
    logic [31:0] pmem_address;
    logic [255:0] pmem_rdata, pmem_wdata;

    //*********************************************************************//


    //************************* Instance Modules **************************//

    cpu cpu (
        .clk(clk),
        .rst(rst),

        .icache_mem_resp(icache_mem_resp_cache),
        .icache_rdata(icache_rdata_cache),
        .icache_mem_read(icache_mem_read_cache),
        .icache_address(icache_address_cache),

        .dcache_mem_resp(dcache_mem_resp_cache),
        .dcache_rdata(dcache_rdata_cache),
        .dcache_mem_read(dcache_mem_read_cache),
        .dcache_mem_write(dcache_mem_write_cache),
        .dcache_wdata(dcache_wdata_cache),
        .dcache_address(dcache_address_cache),

        .dcache_mem_byte_enable(dcache_mem_byte_enable_cache)
    );


    cache #(5) ICache (
        .clk(clk),

        .pmem_resp(icache_mem_resp_arb),
        .pmem_rdata(icache_rdata_arb),
        .pmem_address(icache_address_arb),
        .pmem_wdata(),
        .pmem_read(icache_mem_read_arb),
        .pmem_write(),

        .mem_read(icache_mem_read_cache),
        .mem_write('0),
        .mem_byte_enable_cpu('0),
        .mem_address(icache_address_cache),
        .mem_wdata_cpu('0),
        .mem_resp(icache_mem_resp_cache),
        .mem_rdata_cpu(icache_rdata_cache)
    );

    cache #(4) DCache (
        .clk,

        .pmem_resp(dcache_mem_resp_arb),
        .pmem_rdata(dcache_rdata_arb),
        .pmem_address(dcache_address_arb),
        .pmem_wdata(dcache_wdata_arb),
        .pmem_read(dcache_mem_read_arb),
        .pmem_write(dcache_mem_write_arb),
        
        .mem_read(dcache_mem_read_cache),
        .mem_write(dcache_mem_write_cache),
        .mem_byte_enable_cpu(dcache_mem_byte_enable_cache),
        .mem_address(dcache_address_cache),
        .mem_wdata_cpu(dcache_wdata_cache),
        .mem_resp(dcache_mem_resp_cache),
        .mem_rdata_cpu(dcache_rdata_cache)
    );

    arbiter arbiter (
        .clk(clk),
        .rst(rst),

        .icache_address(icache_address_arb),
        .icache_mem_read(icache_mem_read_arb),
        .icache_mem_resp(icache_mem_resp_arb),
        .icache_rdata(icache_rdata_arb),

        .dcache_address(dcache_address_arb),
        .dcache_mem_read(dcache_mem_read_arb),
        .dcache_mem_write(dcache_mem_write_arb),
        .dcache_mem_resp(dcache_mem_resp_arb),
        .dcache_wdata(dcache_wdata_arb),
        .dcache_rdata(dcache_rdata_arb),

        .pmem_resp(l2_resp),
        .pmem_rdata(l2_rdata),
        .pmem_address(l2_address),
        .pmem_wdata(l2_wdata),
        .pmem_read(l2_read),
        .pmem_write(l2_write)
    );

    l2_cache #(4, 5, 3) l2 (
        .clk(clk),
        .rst(rst),

        .mem_address(l2_address),
        .mem_read(l2_read),
        .mem_write(l2_write),
        .mem_resp(l2_resp),
        .mem_rdata(l2_rdata),
        .mem_wdata(l2_wdata),
                
        .pmem_resp(ewb_resp),
        .pmem_read(ewb_read),
        .pmem_write(ewb_write),
        .pmem_rdata(ewb_rdata),
        .pmem_wdata(ewb_wdata),
        .pmem_address(ewb_address)
    );

    ewb eviction_buffer (
        .clk(clk),
        .rst(rst),

        .cache_resp(ewb_resp),
        .cache_rdata(ewb_rdata),
        .cache_wdata(ewb_wdata),
        .cache_address(ewb_address),
        .cache_read(ewb_read),
        .cache_write(ewb_write),

        .pmem_wdata(pmem_wdata),
        .pmem_rdata(pmem_rdata),
        .pmem_read(pmem_read),
        .pmem_write(pmem_write),
        .pmem_address(pmem_address),
        .pmem_resp(pmem_resp)
    );

    cacheline_adaptor cd (
        .clk(clk),
        .reset_n(~rst),

        .line_i(pmem_wdata),
        .line_o(pmem_rdata),
        .address_i(pmem_address),
        .read_i(pmem_read),
        .write_i(pmem_write),
        .resp_o(pmem_resp),

        .burst_i(mem_rdata),
        .burst_o(mem_wdata),
        .address_o(mem_address),
        .read_o(mem_read),
        .write_o(mem_write),
        .resp_i(mem_resp)
    );
endmodule : mp4

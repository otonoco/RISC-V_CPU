import rv32i_types::*;

module cpu
(
    input clk,
    input rst,
    input rv32i_word icache_rdata,
    input rv32i_word dcache_rdata,
    input logic icache_mem_resp,
    input logic dcache_mem_resp,
    output logic icache_mem_read,
    output logic dcache_mem_read,
    output logic dcache_mem_write,
    output rv32i_word dcache_wdata,
    output rv32i_word dcache_address,
    output rv32i_word icache_address,
    output logic [3:0] dcache_mem_byte_enable
);

  /************************* Internal Logic *******************************/
    rv32i_control ctrl, MEM;
    rv32i_opcode opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    rv32i_word if_icache_rdata, mem_dcache_rdata;
    rv32i_word mem_dcache_address;
    rv32i_word mem_dcache_wdata;
    logic [1:0] mem_mem_remainder, wb_mem_remainder;

  /************************* Assign values *******************************/
    assign dcache_wdata = mem_dcache_wdata;
    assign dcache_address = mem_dcache_address;

    control_rom control (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .ctrl(ctrl)
    );

    datapath datapath (
        .clk(clk),
        .rst(rst),
        .ctrl(ctrl),
        .if_icache_rdata(icache_rdata),
        .mem_dcache_rdata(dcache_rdata),
        .if_icache_mem_resp(icache_mem_resp),
        .mem_dcache_mem_resp(dcache_mem_resp),
        .mem_dcache_wdata(mem_dcache_wdata),
        .mem_dcache_address(mem_dcache_address),
        .icache_address(icache_address),
        .id_opcode(opcode),
        .id_funct3(funct3),
        .id_funct7(funct7),
        .mem_dcache_read(dcache_mem_read),
        .mem_dcache_write(dcache_mem_write),
        .if_icache_read(icache_mem_read),
        .dcache_mem_byte_enable(dcache_mem_byte_enable),
        .mem_mem_remainder(mem_mem_remainder),
        .wb_mem_remainder(wb_mem_remainder)
    );

endmodule : cpu

import rv32i_types::*;

module decoder
(
    input [31:0] if_icache_rdata,
    output [2:0] if_funct3,
    output [6:0] if_funct7,
    output rv32i_opcode if_opcode,
    output [31:0] if_i_imm,
    output [31:0] if_s_imm,
    output [31:0] if_b_imm,
    output [31:0] if_u_imm,
    output [31:0] if_j_imm,
    output [4:0] if_rs1,
    output [4:0] if_rs2,
    output [4:0] if_rd
);


    assign if_funct3 = if_icache_rdata[14:12];
    assign if_funct7 = if_icache_rdata[31:25];
    assign if_opcode = rv32i_opcode'(if_icache_rdata[6:0]);
    assign if_i_imm = {{21{if_icache_rdata[31]}}, if_icache_rdata[30:20]};
    assign if_s_imm = {{21{if_icache_rdata[31]}}, if_icache_rdata[30:25], if_icache_rdata[11:7]};
    assign if_b_imm = {{20{if_icache_rdata[31]}}, if_icache_rdata[7], if_icache_rdata[30:25], if_icache_rdata[11:8], 1'b0};
    assign if_u_imm = {if_icache_rdata[31:12], 12'h000};
    assign if_j_imm = {{12{if_icache_rdata[31]}}, if_icache_rdata[19:12], if_icache_rdata[20], if_icache_rdata[30:21], 1'b0};
    assign if_rs1 = if_icache_rdata[19:15];
    assign if_rs2 = if_icache_rdata[24:20];
    assign if_rd = if_icache_rdata[11:7];

endmodule : decoder

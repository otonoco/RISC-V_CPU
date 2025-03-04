import rv32i_types::*;
module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.halt = dut.cpu.datapath.PC.load  && (dut.cpu.datapath.mem_pc_out == dut.cpu.datapath.wb_pc_out) && (dut.cpu.datapath.mem_pc_out !== '0);
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

//branch address logic
logic [31:0] addr;
always_comb begin
        if (dut.cpu.datapath.wb_BTB_hit) begin
                        if (dut.cpu.datapath.WBK.branch_enable && dut.cpu.datapath.wb_misprediction) begin
                                                                   if (dut.cpu.datapath.wb_br_en) addr = {dut.cpu.datapath.wb_alu_out[31:2], 2'b00};
                                                                   else addr = dut.cpu.datapath.wb_pc_out + 4;
                                                                   end

                        else if (dut.cpu.datapath.WBK.jal_enable && dut.cpu.datapath.wb_misprediction) addr = {dut.cpu.datapath.wb_alu_out[31:2], 2'b00};
                        else if (dut.cpu.datapath.WBK.jalr_enable && dut.cpu.datapath.wb_misprediction) addr = {dut.cpu.datapath.wb_alu_out[31:1], 1'b0};
                        else if (dut.cpu.datapath.wb_BTB_hit && dut.cpu.datapath.wb_predicted_branch_outcome[1]) addr = dut.cpu.datapath.wb_predicted_pcmux_out;
                        else addr = dut.cpu.datapath.wb_pcmux_out;
                        end
        else begin
             if (dut.cpu.datapath.WBK.branch_enable && dut.cpu.datapath.wb_br_en) addr = {dut.cpu.datapath.wb_alu_out[31:2], 2'b00}; 
             else if (dut.cpu.datapath.WBK.jal_enable) addr = {dut.cpu.datapath.wb_alu_out[31:2], 2'b00};
             else if (dut.cpu.datapath.WBK.jalr_enable) addr = {dut.cpu.datapath.wb_alu_out[31:1], 1'b0};
             else if (dut.cpu.datapath.wb_BTB_hit && dut.cpu.datapath.wb_predicted_branch_outcome[1]) addr = dut.cpu.datapath.wb_predicted_pcmux_out;//predicted taken branch       
             else addr = dut.cpu.datapath.wb_pcmux_out;
             end                                     
end    

//performance counter
int branch_misprediction, n_branch;
real correctness;
initial begin
    branch_misprediction = 0;
    n_branch = 0;
end

int pmem_access, mem_access;
real pmem_call_ratio;
initial begin
    pmem_access = 0;
    mem_access = 0;
end

always @(posedge itf.clk) begin
    if (dut.cpu.datapath.EX_MEM.load) begin
        if (dut.cpu.datapath.flushing)
            branch_misprediction <= branch_misprediction + 1;
        if (dut.cpu.datapath.MEM.jal_enable ||  dut.cpu.datapath.MEM.jalr_enable || dut.cpu.datapath.MEM.branch_enable)
            n_branch <= n_branch + 1;
    end
    if (dut.cpu.icache_mem_read || dut.cpu.dcache_mem_read || dut.cpu.dcache_mem_write)
        begin
            mem_access <= mem_access + 1;
        end
    if (dut.pmem_read || dut.pmem_read)
        begin
            pmem_access <= pmem_access + 1;
        end
end


always_comb begin
if (rvfi.halt) begin
correctness = ((n_branch - branch_misprediction)*100 / n_branch);
$display ("number of branches/jmps: %0d, branch_misprediction: %0d, correctness: %0d percent", n_branch, branch_misprediction, correctness);
end
end

always_comb begin
    if (rvfi.halt) begin
        pmem_call_ratio = ((mem_access-pmem_access)*100 / mem_access);
        $display ("number of memory call from cpu:  %0d, number of pmem access:  %0d, hit ratio:  %0d percent", mem_access, pmem_access, pmem_call_ratio);
    end
end

assign rvfi.commit = dut.cpu.datapath.load_MEM_WB_latch && dut.cpu.datapath.ex_mem_valid;// commit everytime the MEM_WB latch passes a new instruction

logic trap;
logic [3:0] rmask, wmask;
logic [4:0] wb_rd;
branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(dut.cpu.datapath.WBK.funct3);
assign branch_funct3 = branch_funct3_t'(dut.cpu.datapath.WBK.funct3);
assign load_funct3 = load_funct3_t'(dut.cpu.datapath.WBK.funct3);
assign store_funct3 = store_funct3_t'(dut.cpu.datapath.WBK.funct3);
assign wb_rd = dut.cpu.datapath.wb_rd;
always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (dut.cpu.datapath.WBK.opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = (dut.cpu.datapath.wb_mem_remainder == 2'b10) ? 4'b1100 : 4'b0011 /* Modify for MP1 Final */ ;
                lb, lbu: begin
                         unique case (dut.cpu.datapath.wb_mem_remainder)
                         2'b00: rmask = 4'b0001 /* Modify for MP1 Final */ ;
 	                 2'b01: rmask = 4'b0010;
	                 2'b10: rmask = 4'b0100;
                         2'b11: rmask = 4'b1000;
	                 endcase
                         end
                default: trap = 1;
            endcase
        end

        op_store: wmask =  dut.cpu.datapath.wb_dcache_mem_byte_enable;

        default: trap = 1;
    endcase
end


//The following signals need to be set:
//Instruction and trap:
assign    rvfi.inst = dut.cpu.datapath.wb_icache_rdata;
assign    rvfi.trap = trap;

//Regfile:
assign    rvfi.rs1_addr = dut.cpu.datapath.wb_rs1;
assign    rvfi.rs2_addr = dut.cpu.datapath.wb_rs2;
assign    rvfi.rs1_rdata = dut.cpu.datapath.wb_rs1_fwdmux_out;  
assign    rvfi.rs2_rdata = dut.cpu.datapath.wb_rs2_fwdmux_out;
assign    rvfi.load_regfile = dut.cpu.datapath.WBK.load_regfile;
assign    rvfi.rd_addr = dut.cpu.datapath.wb_rd;
assign    rvfi.rd_wdata = rvfi.rd_addr ? dut.cpu.datapath.wb_regfilemux_out : '0;

//PC:
assign    rvfi.pc_rdata = dut.cpu.datapath.wb_pc_out;
assign    rvfi.pc_wdata = addr;

//Memory:
assign    rvfi.mem_addr = {dut.cpu.datapath.wb_alu_out[31:2], 2'b00};
assign    rvfi.mem_rmask = rmask;
assign    rvfi.mem_wmask = wmask;
assign    rvfi.mem_rdata = dut.cpu.datapath.wb_dcache_rdata;
assign    rvfi.mem_wdata = dut.cpu.datapath.wb_dcache_wdata;

//Please refer to rvfi_itf.sv for more information.


/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2

//The following signals need to be set:
//icache signals:
assign    itf.inst_read = dut.cpu.icache_mem_read;
assign    itf.inst_addr = dut.cpu.icache_address;
assign    itf.inst_resp = dut.cpu.icache_mem_resp;
assign    itf.inst_rdata = dut.cpu.icache_rdata;

//dcache signals:
assign    itf.data_read = dut.cpu.dcache_mem_read;
assign    itf.data_write = dut.cpu.dcache_mem_write;
assign    itf.data_mbe = dut.cpu.dcache_mem_byte_enable;
assign    itf.data_addr = dut.cpu.dcache_address;
assign    itf.data_wdata = dut.cpu.dcache_wdata;
assign    itf.data_resp = dut.cpu.dcache_mem_resp;
assign    itf.data_rdata = dut.cpu.dcache_rdata;

//Please refer to tb_itf.sv for more information.


/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.cpu.datapath.regfile.data;
// Stop simulation on timeout (stall detection), halt
int timeout = 100000000;
always @(posedge itf.clk) begin
    if (rvfi.halt)
        $finish;
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end
/*********************** Instantiate your design here ************************/

//The following signals need to be connected to your top level:

mp4 dut(
    .clk                    (itf.clk),
    .rst                    (itf.rst),
    .mem_resp               (itf.mem_resp),
    .mem_rdata              (itf.mem_rdata),
    .mem_read               (itf.mem_read),
    .mem_write              (itf.mem_write),
    .mem_address            (itf.mem_addr),
    .mem_wdata              (itf.mem_wdata)
);
//Please refer to tb_itf.sv for more information.
/***************************** End Instantiation *****************************/

initial begin
    $dumpfile("vcdfile.vcd");
    $dumpvars();
end

endmodule

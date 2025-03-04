module arbiter (
    input clk,
    input rst,
    // ICache 
    input logic [31:0] icache_address,
    input logic icache_mem_read,
    output logic icache_mem_resp,
    output logic [255:0] icache_rdata,
    // DCache 
    input logic [31:0] dcache_address,
    input logic [255:0] dcache_wdata,
    input logic dcache_mem_read,
    input logic dcache_mem_write,
    output logic dcache_mem_resp,
    output logic [255:0] dcache_rdata,
    // Cacheline Adaptor
    input logic pmem_resp,
    input logic [255:0] pmem_rdata,
    output logic [31:0] pmem_address,
    output logic [255:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write
);

    //*************************** Declare Logic ***************************//

    logic load_reader;
    logic [255:0] reader;

    //*********************************************************************//

    enum int unsigned {
                       IDLE, 
                       i_read, 
                       d_read, 
                       d_write, 
                       i_read_resp, 
                       d_read_resp, 
                       d_wrte_resp } STATE, NEXT_STATE;

    always_comb
    begin
        NEXT_STATE = STATE;
        icache_mem_resp = '0;
        icache_rdata = '0;
        dcache_mem_resp = '0;
        dcache_rdata = '0;
        pmem_address = '0;
        pmem_wdata = dcache_wdata;
        pmem_read = '0;
        pmem_write = '0;
        load_reader = '0;
        unique case (STATE)
            IDLE: 
                begin
                    if (dcache_mem_read)
                        NEXT_STATE = d_read;
                    else if (icache_mem_read)
                        NEXT_STATE = i_read;
                    else if (dcache_mem_write)
                        NEXT_STATE = d_write;
                end

            d_write: 
                begin
                    if (pmem_resp)
                        begin
                            NEXT_STATE = d_wrte_resp;
                        end
                    else
                        begin
                            NEXT_STATE = d_write;
                        end
                end

            d_read:
                begin
                    if (pmem_resp)
                        begin
                            NEXT_STATE = d_read_resp;
                        end
                    else
                        begin
                            NEXT_STATE = d_read;
                        end
                end

            i_read:
                begin
                    if (pmem_resp)
                        begin
                            NEXT_STATE = i_read_resp;
                        end
                    else
                        begin
                            NEXT_STATE = i_read;
                        end
                end
            
            i_read_resp, d_read_resp, d_wrte_resp: 
                begin
                    NEXT_STATE = IDLE;
                end
        endcase


        unique case(STATE)
            IDLE: ;
            i_read: 
                begin
                    pmem_address =icache_address;
                    pmem_read = 1'b1;
                    load_reader = 1'b1;
                end

            d_read: 
                begin
                    pmem_address = dcache_address;
                    pmem_read = 1'b1;
                    load_reader = 1'b1;
                end

            d_write: 
                begin
                    pmem_address = dcache_address;
                    pmem_write = 1'b1;
                    pmem_wdata = dcache_wdata;
                end
            
            i_read_resp: 
                begin
                    icache_mem_resp = 1'b1;
                    icache_rdata = reader;
                end
            
            d_read_resp:
                begin
                    dcache_mem_resp = 1'b1;
                    dcache_rdata = reader;
                end

            d_wrte_resp: 
                begin
                    dcache_mem_resp = 1'b1;
                end
            default:;
        endcase
    end

    always_ff @(posedge clk)
    begin
        if (rst)
            begin
                STATE <= IDLE;
            end
        else
            begin
                STATE <= NEXT_STATE;
            end
        if (load_reader)
            begin
                reader <= pmem_rdata;
            end
        else
            begin
                reader <= reader;
            end
    end

endmodule: arbiter
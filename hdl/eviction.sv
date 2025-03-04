module ewb (
    input clk,
    input rst,

    // Interaction with Cache
    input logic [255:0] cache_wdata,
    input logic [31:0] cache_address,
    input logic cache_read, 
    input logic cache_write,
    output logic cache_resp,
    output logic [255:0] cache_rdata,

    // Interaction with adaptor
    input logic [255:0] pmem_rdata,
    input logic pmem_resp,
    output logic [255:0] pmem_wdata,
    output logic [31:0] pmem_address,
    output logic pmem_write,
    output logic pmem_read
);
    logic store;
    logic [31:0] dirty_addr, temp_addr;
    logic [255:0] dirty_data;

    enum logic [4:0] {
                      IDLE,
                      R_READ,
                      W_RESP,
                      W_READ,
                      W_WRTE} STATE, NEXT_STATE;

    assign temp_addr = cache_address;
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
        
        if (rst)
            begin
                dirty_data <= '0;
                dirty_addr <= '0;
            end
        else if (store) 
            begin
                dirty_data <= cache_wdata;
                dirty_addr <= cache_address;
            end
    end

    always_comb 
    begin
        NEXT_STATE = STATE;

        store = '0;
        cache_resp = '0;
        cache_rdata = pmem_rdata;
        pmem_read = '0;
        pmem_write = '0;
        pmem_wdata = dirty_data;
        pmem_address = temp_addr;

        unique case (STATE)
            IDLE: 
                begin
                    if (cache_read)
                        NEXT_STATE = R_READ;
                    else if (cache_write)
                        NEXT_STATE = W_RESP;
                end

            W_RESP:
                begin
                    NEXT_STATE = W_READ;
                end

            W_READ:
                begin
                    if (pmem_resp)
                        begin
                            NEXT_STATE = W_WRTE; 
                        end
                    else
                        begin
                            NEXT_STATE = W_READ;
                        end
                end

            W_WRTE: 
                begin
                    if (pmem_resp)
                        begin
                            NEXT_STATE = IDLE;
                        end
                    else
                        begin
                            NEXT_STATE = W_WRTE;
                        end
                end
                
            R_READ:
                if (pmem_resp)
                    begin
                        NEXT_STATE = IDLE;
                    end
                else
                    begin
                        NEXT_STATE = R_READ;
                    end
            default:;
        endcase

        unique case (STATE)
            W_RESP: 
                begin
                    store = 1'b1;
                    cache_resp = 1'b1;
                end

            W_READ: 
                begin
                    pmem_read = 1'b1;
                    cache_resp = pmem_resp;
                end

            W_WRTE: 
                begin
                    pmem_write = 1'b1;
                    pmem_address = dirty_addr;
                end

            R_READ:
                begin
                    pmem_read = 1'b1;
                    cache_resp = pmem_resp;
                end

            default:;
        endcase
    end

endmodule : ewb
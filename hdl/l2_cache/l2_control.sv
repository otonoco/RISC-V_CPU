module l2_control (
    input clk, 

    // CPU to Control //
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,

    // Control to Datapath //
    input logic hitt,
    input logic dirty,
    output logic tag_load,
    output logic lru_load,
    output logic valid_load,
    output logic dirty_load,
    output logic dirty_in,
    output logic cache_write,
    output logic addr_sel,
    output logic writing,

    // Control to Adapter //
    input pmem_resp,
    output logic pmem_read,
    output logic pmem_write
);

    logic working;
    assign working = mem_read|mem_write;

    enum int unsigned {
                       START, 
                       WB, 
                       MS, 
                       HIT} STATE, NEXT_STATE;

    always_comb
    begin
        pmem_read = 1'b0;
        pmem_write = 1'b0;

        mem_resp = 1'b0;

        dirty_load = 1'b0;
        tag_load = 1'b0;
        valid_load = 1'b0;
        lru_load = 1'b0;
        dirty_in = 1'b0;
        writing = 1'b0;
        cache_write = 1'b0;
        addr_sel = 1'b0;
        case (STATE)
            WB: 
                begin
                    addr_sel = 1'b1;
                    dirty_load = 1'b1;
                    valid_load = 1'b1;
                    pmem_write = 1'b1;
                    writing = 1'b1;
                end

            MS: 
                begin
                    pmem_read = 1'b1;
                    valid_load = 1'b1;
                    tag_load = 1'b1;
                    cache_write = 1'b1;
                end

            HIT: 
                begin
                    lru_load = 1'b1;
                    mem_resp = 1'b1;
                    if (mem_write) 
                        begin
                            writing = 1'b1;
                            cache_write = 1'b1;
                            dirty_load = 1'b1;
                            valid_load = 1'b1;
                            dirty_in = 1'b1;
                        end
                    else
                        begin
                            cache_write = 1'b0;
                            dirty_load = 1'b0;
                            valid_load = 1'b0;
                        end

                end
            default:;
        endcase
    end

    always_comb
    begin
        NEXT_STATE = STATE;
        unique case (STATE)
            START: 
                begin
                    if (working)
                        begin
                            if (hitt)
                                begin
                                    NEXT_STATE = HIT;
                                end
                            else
                                begin
                                    if (dirty)
                                        begin
                                            NEXT_STATE = WB;
                                        end
                                    else
                                        begin
                                            NEXT_STATE = MS;
                                        end
                                end
                        end
                    else
                        begin
                            NEXT_STATE = START;
                        end
                end
            WB:
                begin
                    if (pmem_resp)
                        NEXT_STATE = MS;
                end
            MS:
                begin
                    if (pmem_resp)
                        NEXT_STATE = HIT;
                end
            HIT:
                begin
                    NEXT_STATE = START;
                end
            default:;
        endcase
    end

    always_ff @(posedge clk)
    begin
        STATE <= NEXT_STATE;
    end

endmodule : l2_control

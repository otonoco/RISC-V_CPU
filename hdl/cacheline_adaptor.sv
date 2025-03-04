module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memoryc
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
); 
    enum logic [10:0] {BEGN, 
                       ADDR, 
                       RD_1, 
                       RD_2, 
                       RD_3, 
                       RD_4, 
                       WR_1, 
                       WR_2, 
                       WR_3, 
                       WR_4, 
                       HOLD, 
                       DONE} STATE, NEXT_STATE;
    
    logic [31:0] addr, next_addr;
    logic [63:0] d1, d2, d3, d4, n1, n2, n3, n4;
    logic [255:0] in, out;

    assign n1 = in[63:0];
    assign n2 = in[127:64];
    assign n3 = in[191:128];
    assign n4 = in[255:192];

    assign out[63:0] = d1;
    assign out[127:64] = d2;
    assign out[191:128] = d3;
    assign out[255:192] = d4;

    assign address_o = addr;

    assign line_o = out;


    always_ff @(posedge clk) 
    begin
        if (~reset_n) 
            begin
                STATE <= BEGN;
                addr <= 32'b0;
                d1 <= 64'b0;
                d2 <= 64'b0;
                d3 <= 64'b0;
                d4 <= 64'b0;
            end
        else 
            begin
                STATE <= NEXT_STATE;
                addr <= next_addr;
                d1 <= n1;
                d2 <= n2;
                d3 <= n3;
                d4 <= n4;
            end        
    end

    always_comb 
    begin
        NEXT_STATE = STATE;
        read_o = 1'b0;
        write_o = 1'b0;
        resp_o = 1'b0;

        next_addr = addr;
        in = {d4, d3, d2, d1};
        burst_o = 64'b0;
        unique case (STATE)
            BEGN:
                begin
                    if (read_i | write_i)
                        begin
                            NEXT_STATE = ADDR;
                        end
                    else
                        begin
                            NEXT_STATE = BEGN;
                        end
                end
            ADDR:
                begin
                    if (read_i)
                        begin
                            NEXT_STATE = RD_1;
                        end
                    else
                        begin
                            NEXT_STATE = HOLD;
                        end
                end
            HOLD:
                begin
                    NEXT_STATE = WR_1;
                end
            RD_1:
                begin
                    if (resp_i)
                        begin
                            NEXT_STATE = RD_2;
                        end
                    else
                        begin
                            NEXT_STATE = RD_1;
                        end
                end
            RD_2:
                begin
                    if (resp_i)
                        begin
                            NEXT_STATE = RD_3;
                        end
                    else
                        begin
                            NEXT_STATE = RD_2;
                        end
                end
            RD_3:
                begin
                    if (resp_i)
                        begin
                            NEXT_STATE = RD_4;
                        end
                    else
                        begin
                            NEXT_STATE = RD_3;
                        end
                end
            RD_4:
                begin
                    NEXT_STATE = DONE;
                end
            WR_1:
                begin
                    if (resp_i)
                        begin
                            NEXT_STATE = WR_2;
                        end
                    else
                        begin
                            NEXT_STATE = WR_1;
                        end
                end
            WR_2:
                begin
                    if (resp_i)
                        begin
                            NEXT_STATE = WR_3;
                        end
                    else
                        begin
                            NEXT_STATE = WR_2;
                        end
                end
            WR_3:
                begin
                    if (resp_i) 
                        begin
                            NEXT_STATE = WR_4;
                        end
                    else
                        begin
                            NEXT_STATE = WR_3;
                        end
                end
            WR_4:
                begin
                    NEXT_STATE = DONE;
                end
            DONE:
                begin
                    NEXT_STATE = BEGN;
                end
            default:;
        endcase

        case (STATE)
            BEGN:;
            ADDR:
                next_addr = address_i;
            RD_1:
                begin
                    read_o = 1'b1;
                    in[63:0] = burst_i;
                end
            RD_2:
                begin
                    read_o = 1'b1;
                    in[127:64] = burst_i;
                end
            RD_3:
                begin
                    read_o = 1'b1;
                    in[191:128] = burst_i;
                end
            RD_4:
                begin
                    read_o = 1'b1;
                    in[255:192] = burst_i;
                end
            WR_1:
                begin
                    write_o = 1'b1;
                    burst_o = d1;
                end
            WR_2:
                begin
                    write_o = 1'b1;
                    burst_o = d2;
                end
            WR_3:
                begin
                    write_o = 1'b1;
                    burst_o = d3;
                end
            WR_4:
                begin
                    write_o = 1'b1;
                    burst_o = d4;
                end
            HOLD:
                begin
                    in = line_i;
                end
            DONE:
                begin
                    resp_o = 1'b1;
                end
        endcase
    end

endmodule : cacheline_adaptor

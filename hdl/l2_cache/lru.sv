module para_lru_tree #(
    parameter num_ways = 8
)
(
    input clk,
    input logic [num_ways - 1:0] hit_way,
    input logic load,
    output logic [num_ways - 1:0] lru_way
);

    logic [num_ways - 2 : 0] lru_array = '{default : '0};
    logic [num_ways - 2 : 0] lry_array_in;
    logic [num_ways - 1 : 0] lru;

    assign lru_way = lru;

    always_comb 
    begin
        lry_array_in = lru_array;
        if (load)
            begin
                if (num_ways == 4)
                    begin
                        if (hit_way[3:2] == '0)
                            begin
                                lry_array_in[2] = 1'b1;
                                if (hit_way[1] == '0)
                                    begin
                                        lry_array_in[0] = 1'b1;
                                    end
                                else
                                    begin
                                        lry_array_in[0] = 1'b0;
                                    end
                            end
                        else
                            begin
                                lry_array_in[2] = 1'b0;
                                if (hit_way[3] == '0)
                                    begin
                                        lry_array_in[1] = 1'b1;
                                    end
                                else
                                    begin
                                        lry_array_in[1] = 1'b0;
                                    end
                            end
                    end
                else
                    begin
                        if (hit_way[7:4] == '0)
                            begin
                                lry_array_in[6] = 1'b1;
                                if (hit_way[3:2] == '0)
                                    begin
                                        lry_array_in[4] = 1'b1;
                                        if (hit_way[1] == '0)
                                            begin
                                                lry_array_in[0] = 1'b1;
                                            end
                                        else
                                            begin
                                                lry_array_in[0] = 1'b0;
                                            end
                                    end
                                else
                                    begin
                                        lry_array_in[4] = 1'b0;
                                        if (hit_way[2] == 1'b1)
                                            begin
                                                lry_array_in[1] = 1'b1;
                                            end
                                        else
                                            begin
                                                lry_array_in[1] = 1'b0;
                                            end
                                    end
                            end
                        else
                            begin
                                begin
                                    lry_array_in[6] = 1'b0;
                                    if (hit_way[7:6] == '0)
                                        begin
                                            lry_array_in[5] = 1'b1;
                                            if (hit_way[5] == '0)
                                                begin
                                                    lry_array_in[2] = 1'b1;
                                                end
                                            else
                                                begin
                                                    lry_array_in[2] = 1'b0;
                                                end
                                        end
                                    else
                                        begin
                                            lry_array_in[5] = 1'b0;
                                            if (hit_way[6] == 1'b1)
                                                begin
                                                    lry_array_in[3] = 1'b1;
                                                end
                                            else
                                                begin
                                                    lry_array_in[3] = 1'b0;
                                                end
                                        end
                                end
                            end
                    end
            end
    end

    always_comb 
    begin
        if (num_ways == 4)
            begin
                if (lry_array_in[2])
                    begin
                        if (lry_array_in[1])
                            begin
                                lru = 4'b1000;
                            end
                        else
                            begin
                                lru = 4'b0100;
                            end
                    end
                else
                    begin
                        if (lry_array_in[0])
                            begin
                                lru = 4'b0010;
                            end
                        else
                            begin
                                lru = 4'b0001;
                            end
                    end
            end
        else
            begin
                if (lry_array_in[6])
                    begin
                        if (lry_array_in[5])
                            begin
                                if (lry_array_in[3])
                                    begin
                                        lru = 8'b10000000;
                                    end
                                else
                                    begin
                                        lru = 8'b01000000;
                                    end
                            end
                        else
                            begin
                                if (lry_array_in[2])
                                    begin
                                        lru = 8'b00100000;
                                    end
                                else
                                    begin
                                        lru = 8'b00010000;
                                    end
                            end
                    end
                else
                    begin
                        if (lry_array_in[4])
                            begin
                                if (lry_array_in[1])
                                    begin
                                        lru = 8'b00001000;
                                    end
                                else
                                    begin
                                        lru = 8'b00000100;
                                    end
                            end
                        else
                            begin
                                if (lry_array_in[0])
                                    begin
                                        lru = 8'b00000010;
                                    end
                                else
                                    begin
                                        lru = 8'b00000001;
                                    end
                            end
                    end
            end
    end

    always_ff @(posedge clk) 
    begin
        if (clk)
            lru_array <= lry_array_in;
    end

endmodule : para_lru_tree
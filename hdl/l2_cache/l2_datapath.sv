module l2_datapath #(
    parameter num_ways = 8,
    parameter num_offset = 5,
    parameter num_index = 3,
    parameter num_tag = 32 - num_offset - num_index,
    parameter num_mask = 2**num_offset,
    parameter num_line = 8*num_mask,
    parameter num_sets = 2**num_index
)
(
    input clk,

    // Interaction with CPU //
    input logic  [31 : 0]  mem_address,
    input logic  [num_line - 1 : 0] mem_wdata,
    output logic [num_line - 1 : 0] mem_rdata,

    // Interaction with Memory //
    input  logic [num_line - 1 : 0] pmem_rdata,
    output logic [num_line - 1 : 0] pmem_wdata,
    output logic [31 : 0]  pmem_address,

    // Interaction with Control //
    input logic tag_load,
    input logic lru_load,
    input logic valid_load,
    input logic cache_write,
    input logic dirty_load,
    input logic dirty_in,
    input logic addr_sel,
    input logic writing,
    output logic dirty,
    output logic hitt
);

    logic [num_ways - 1 : 0] val_in, tag_in, dir_in, val_out, dir_out;
    logic [num_ways - 1 : 0] hit_way, lru_way, load_way, write_cache, dirty_loaded;
    logic [num_tag - 1 : 0] tag, tag_out[num_ways], tag_final_out, tag_loaded[num_ways];
    logic [num_index - 1 : 0] set;
    logic [num_line - 1 : 0] line_out[num_ways], line_input, line_final_out, line_loaded[num_ways];

    assign set = mem_address[num_offset + num_index -1 : num_offset];
    assign tag = mem_address[31 : num_offset + num_index];

    assign mem_rdata = line_final_out;
    assign pmem_wdata = line_final_out;

    assign val_in = load_way & {num_ways{valid_load}};
    assign dir_in = load_way & {num_ways{dirty_load}};
    assign tag_in = load_way & {num_ways{tag_load}};
    assign write_cache = load_way & {num_ways{cache_write}};

    always_comb 
    begin
        if (num_ways == 4)
            begin
                dirty = dirty_loaded[0]|dirty_loaded[1]|dirty_loaded[2]|dirty_loaded[3];
                hitt = hit_way[0]|hit_way[1]|hit_way[2]|hit_way[3];
                line_final_out = line_loaded[0]|line_loaded[1]|line_loaded[2]|line_loaded[3];
                tag_final_out = tag_loaded[0]|tag_loaded[1]|tag_loaded[2]|tag_loaded[3];
            end
        else
            begin
                dirty = dirty_loaded[0]|dirty_loaded[1]|dirty_loaded[2]|dirty_loaded[3]|dirty_loaded[4]|dirty_loaded[5]|dirty_loaded[6]|dirty_loaded[7];
                hitt = hit_way[0]|hit_way[1]|hit_way[2]|hit_way[3]|hit_way[4]|hit_way[5]|hit_way[6]|hit_way[7];
                line_final_out = line_loaded[0]|line_loaded[1]|line_loaded[2]|line_loaded[3]|line_loaded[4]|line_loaded[5]|line_loaded[6]|line_loaded[7];
                tag_final_out = tag_loaded[0]|tag_loaded[1]|tag_loaded[2]|tag_loaded[3]|tag_loaded[4]|tag_loaded[5]|tag_loaded[6]|tag_loaded[7];
            end  
    end

    always_ff @(posedge clk)
    begin
        load_way <= (hitt == '1) ? hit_way : lru_way;
    end

    always_comb 
    begin
        for (int i = 0; i < num_ways; i++)
        begin
            tag_loaded[i] = tag_out[i] & {num_tag{load_way[i]}};
            line_loaded[i] = line_out[i] & {num_line{load_way[i]}};
            dirty_loaded[i] = dir_out[i] & load_way[i];
            hit_way[i] = ((tag == tag_out[i]) && val_out[i]) ? 1'b1 : 1'b0;
        end
    end

    para_lru_tree #(num_ways) lru_array (
        .clk(clk),
        .load(lru_load),
        .hit_way(hit_way),
        .lru_way(lru_way)
    );

    genvar i;
    generate
        for (i = 0; i < num_ways; i++) begin: generation
            bram_array #(256, num_index) data_array (
                .clock(clk),
                .address(set),
                .data(line_input),
                .wren(write_cache[i]),
                .q(line_out[i])
            );

            // bram_array #(1, num_index) valid_array (
            //     .clock(clk),
            //     .address(set),
            //     .data(1'b1),
            //     .wren(val_in[i]),
            //     .q(val_out[i])
            // );

            // bram_array #(1, num_index) dirty_array (
            //     .clock(clk),
            //     .address(set),
            //     .data(dirty_in),
            //     .wren(dir_in[i]),
            //     .q(dir_out[i])
            // );


            // bram_array #(num_tag, num_index) tag_array (
            //     .clock(clk),
            //     .address(set),
            //     .data(tag),
            //     .wren(tag_in[i]),
            //     .q(tag_out[i])
            // );

            parameterized_array #(1, num_index) valid_array (
                .clk,
                .load(val_in[i]),
                .rindex(set),
                .windex(set),
                .datain(1'b1),
                .dataout(val_out[i])
            );

            parameterized_array #(1, num_index) dirty_array (
                .clk,
                .load(dir_in[i]),
                .rindex(set),
                .windex(set),
                .datain(dirty_in),
                .dataout(dir_out[i])
            );

            parameterized_array #(num_tag, num_index) tag_array (
                .clk,
                .load(tag_in[i]),
                .rindex(set),
                .windex(set),
                .datain(tag),
                .dataout(tag_out[i])
            );

        end
    endgenerate

     always_comb begin : MUX
        unique case (writing)
            1'b0: line_input = pmem_rdata;
            1'b1: line_input = mem_wdata;
            default: line_input = mem_wdata;
        endcase

        unique case (addr_sel)
            1'b0: pmem_address = mem_address;
            1'b1: pmem_address = {tag_final_out, set, {5'b0}};
            default: pmem_address = '0;
        endcase
     end

endmodule : l2_datapath
module parameterized_array #(
    parameter width = 1,
    parameter index = 3
)
(
    input clk,
    input logic load,
    input logic [index - 1 : 0] rindex,
    input logic [index - 1 : 0] windex,
    input logic [width - 1 : 0] datain,
    output logic [width - 1 : 0] dataout
);

    localparam set_num = 2**index;
    logic [width - 1:0] data [set_num] = '{default: '0};
    // logic gclk;

    always_comb 
    begin
        dataout = (load  & (rindex == windex)) ? datain : data[rindex];
    end

    // assign glck = clk && load;
    always_ff @(posedge clk)
    begin
        if (load)
        begin
        data[windex] <= datain;
        end
    end

endmodule : parameterized_array

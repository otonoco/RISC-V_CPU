/* DO NOT MODIFY. WILL BE OVERRIDDEN BY THE AUTOGRADER. */

module branch_history_register #(parameter width = 4) //number of
 (
    input clk,
    input rst,
    input load,
    input in,
    output logic [width-1:0] out
);

    logic [width-1:0] data;


    always_ff @(posedge clk)
    begin
        if (rst)
            begin
                data <= '0;
            end
        else if (load)
            begin
                data <= {data<<1, in};
            end
        else
            begin
                data <= data;
            end
    end

    assign out = data; //{data[width-2:0], in};

endmodule : branch_history_register

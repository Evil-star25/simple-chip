module serial_to_parallel (
    input wire clk,
    input wire rst,
    input wire serial_in,
    output reg [7:0] parallel_out
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            parallel_out <= 8'b0;
        else
            parallel_out <= {parallel_out[6:0], serial_in};
    end

endmodule

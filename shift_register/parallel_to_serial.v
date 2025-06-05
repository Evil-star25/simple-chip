module parallel_to_serial (
    input wire clk,
    input wire rst,
    input wire load,               // Load control signal
    input wire [7:0] parallel_in,  // Data to load
    output reg serial_out
);

    reg [7:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            shift_reg <= 8'b0;
        else if (load)
            shift_reg <= parallel_in;
        else
            shift_reg <= {shift_reg[6:0], 1'b0}; // Shift left with 0 fill
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            serial_out <= 1'b0;
        else
            serial_out <= shift_reg[7]; // MSB first
    end

endmodule

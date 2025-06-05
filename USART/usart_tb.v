`timescale 1ns / 1ps

module usart_tb;

    reg clk = 0;
    reg rst = 1;

    // USART I/O
    reg [7:0] tx_data_in;
    reg tx_write_en;
    wire tx_full;
    wire tx_serial_out;

    wire rx_serial_in;
    wire [7:0] rx_data_out;
    reg rx_read_en;
    wire rx_empty;

    // Clock Generation
    always #5 clk = ~clk;  // 100MHz clock

    // Serial line emulation
    assign rx_serial_in = tx_serial_out;

    // Instantiate USART
    usart uut (
        .clk(clk),
        .rst(rst),
        .tx_data_in(tx_data_in),
        .tx_write_en(tx_write_en),
        .tx_full(tx_full),
        .tx_serial_out(tx_serial_out),
        .rx_serial_in(rx_serial_in),
        .rx_data_out(rx_data_out),
        .rx_read_en(rx_read_en),
        .rx_empty(rx_empty)
    );

    // Stimulus
    integer i;
    reg [7:0] test_data [0:3];
    initial begin
        // Initialize test data
        test_data[0] = 8'hA5;
        test_data[1] = 8'h3C;
        test_data[2] = 8'hF0;
        test_data[3] = 8'h99;

        // Reset
        #20 rst = 0;

        // Write test bytes to TX FIFO
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            tx_data_in <= test_data[i];
            tx_write_en <= 1;
            @(posedge clk);
            tx_write_en <= 0;
        end

        // Wait for serial transmission to complete (approx 8 cycles per byte * 4)
        #(8 * 4 * 10);

        // Read received bytes
        for (i = 0; i < 4; i = i + 1) begin
            wait (!rx_empty);
            @(posedge clk);
            rx_read_en <= 1;
            @(posedge clk);
            rx_read_en <= 0;
            @(posedge clk);
            $display("Received Byte %0d: %02X", i, rx_data_out);
        end

        $display("USART Test Complete.");
        $stop;
    end

endmodule

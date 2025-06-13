`timescale 1ns / 1ps

module spi_slave_tb;

    reg clk;
    reg rst;

    // SPI lines
    reg sclk;
    reg cs;
    reg mosi;
    wire miso;

    // Slave FIFO interface
    reg [7:0] tx_data;
    reg tx_wr_en;
    wire tx_full;

    wire [7:0] rx_data;
    reg rx_rd_en;
    wire rx_empty;

    // Instantiate SPI slave
    spi_slave uut (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .tx_data(tx_data),
        .tx_wr_en(tx_wr_en),
        .tx_full(tx_full),
        .rx_data(rx_data),
        .rx_rd_en(rx_rd_en),
        .rx_empty(rx_empty)
    );

    // Clock generation (system clock = 50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    // SPI SCLK (1 MHz simulated)
    task spi_clock_cycle;
        begin
            #100 sclk = 0;
            #100 sclk = 1;
        end
    endtask

    // Send byte over SPI MOSI (MSB first)
    task spi_send_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                mosi = data[i];
                spi_clock_cycle();
            end
        end
    endtask

    // Receive byte from SPI MISO (MSB first)
    reg [7:0] received_byte;
    task spi_receive_byte;
        integer i;
        begin
            received_byte = 8'h00;
            for (i = 7; i >= 0; i = i - 1) begin
                spi_clock_cycle();
                received_byte[i] = miso;
            end
        end
    endtask

    // Main simulation
    initial begin
        // Initialize
        rst = 1;
        sclk = 0;
        cs = 1;
        mosi = 0;
        tx_data = 0;
        tx_wr_en = 0;
        rx_rd_en = 0;

        #100;
        rst = 0;

        // Load byte to transmit into slave's TX FIFO
        tx_data = 8'h3C;
        tx_wr_en = 1;
        #20;
        tx_wr_en = 0;

        #100;

        // SPI transaction: send 0xA5 from master to slave
        cs = 0;         // Activate chip select
        spi_send_byte(8'hA5);
        cs = 1;         // Deactivate chip select

        #200;

        // Read from RX FIFO (data received from MOSI)
        rx_rd_en = 1;
        #20;
        rx_rd_en = 0;

        // SPI transaction: receive 0x3C from slave's TX FIFO
        cs = 0;
        spi_receive_byte(); // will store in received_byte
        cs = 1;

        #100;

        $display("Received from master (MOSI): %h", rx_data);
        $display("Received from slave (MISO): %h", received_byte);

        #100;
        $finish;
    end

endmodule

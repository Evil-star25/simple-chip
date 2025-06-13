module spi_slave (
    input wire clk,         // system clock
    input wire rst,         // async reset
    input wire sclk,        // SPI clock from master
    input wire cs,          // chip select (active low)
    input wire mosi,        // master out, slave in
    output wire miso,       // master in, slave out

    // FIFO interface
    input wire [7:0] tx_data,
    input wire tx_wr_en,
    output wire tx_full,

    output wire [7:0] rx_data,
    input wire rx_rd_en,
    output wire rx_empty
);

    // Synchronize sclk and cs to system clock
    reg [1:0] sclk_sync, cs_sync;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_sync <= 2'b00;
            cs_sync <= 2'b11;
        end else begin
            sclk_sync <= {sclk_sync[0], sclk};
            cs_sync   <= {cs_sync[0], cs};
        end
    end

    wire sclk_rising_edge  = (sclk_sync[1:0] == 2'b01);
    wire sclk_falling_edge = (sclk_sync[1:0] == 2'b10);
    wire cs_active = ~cs_sync[1];

    // --------------------------
    // RX (Receiving Data)
    // --------------------------
    wire [7:0] rx_parallel_out;
    reg rx_sample_en;
    reg rx_byte_ready;

    serial_to_parallel rx_shift_reg (
        .clk(sclk_rising_edge),  // sample on rising edge
        .rst(rst | ~cs_active),
        .serial_in(mosi),
        .parallel_out(rx_parallel_out)
    );

    // Edge counter to detect when 8 bits received
    reg [2:0] bit_cnt_rx;
    always @(posedge clk or posedge rst) begin
        if (rst || ~cs_active) begin
            bit_cnt_rx <= 3'd0;
            rx_byte_ready <= 1'b0;
        end else if (sclk_rising_edge) begin
            bit_cnt_rx <= bit_cnt_rx + 1;
            rx_byte_ready <= (bit_cnt_rx == 3'd7);
        end else begin
            rx_byte_ready <= 1'b0;
        end
    end

    // RX FIFO
    wire rx_fifo_full;
    fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(16)) rx_fifo (
        .clk(clk),
        .reset(rst),
        .wr_en(rx_byte_ready && !rx_fifo_full),
        .rd_en(rx_rd_en),
        .data_in(rx_parallel_out),
        .data_out(rx_data),
        .full(rx_fifo_full),
        .empty(rx_empty)
    );

    // --------------------------
    // TX (Transmitting Data)
    // --------------------------
    wire [7:0] tx_fifo_data_out;
    reg tx_load;
    reg [2:0] bit_cnt_tx;

    wire tx_fifo_empty;
    fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(16)) tx_fifo (
        .clk(clk),
        .reset(rst),
        .wr_en(tx_wr_en),
        .rd_en(tx_load),
        .data_in(tx_data),
        .data_out(tx_fifo_data_out),
        .full(tx_full),
        .empty(tx_fifo_empty)
    );

    wire serial_out;

    parallel_to_serial tx_shift_reg (
        .clk(sclk_falling_edge),   // shift out on falling edge
        .rst(rst | ~cs_active),
        .load(tx_load),
        .parallel_in(tx_fifo_data_out),
        .serial_out(serial_out)
    );

    // Load new byte on first bit or after every 8 bits
    always @(posedge clk or posedge rst) begin
        if (rst || ~cs_active) begin
            tx_load <= 1'b0;
            bit_cnt_tx <= 3'd0;
        end else if (sclk_rising_edge && !tx_fifo_empty) begin
            if (bit_cnt_tx == 3'd0) begin
                tx_load <= 1'b1;
            end else begin
                tx_load <= 1'b0;
            end
            bit_cnt_tx <= bit_cnt_tx + 1;
        end else begin
            tx_load <= 1'b0;
        end
    end

    // Drive MISO output
    assign miso = cs_active ? serial_out : 1'bz;

endmodule

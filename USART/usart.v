module usart (
    input wire clk,
    input wire rst,

    // TX side
    input wire [7:0] tx_data_in,
    input wire tx_write_en,
    output wire tx_full,
    output wire tx_serial_out,

    // RX side
    input wire rx_serial_in,
    output wire [7:0] rx_data_out,
    input wire rx_read_en,
    output wire rx_empty
);

    wire [7:0] tx_fifo_out;
    wire tx_fifo_empty;
    reg tx_rd_en;
    reg load_shift_reg;

    // TX FIFO Instance
    fifo #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(16)
    ) tx_fifo (
        .clk(clk),
        .reset(rst),
        .wr_en(tx_write_en),
        .rd_en(tx_rd_en),
        .data_in(tx_data_in),
        .data_out(tx_fifo_out),
        .full(tx_full),
        .empty(tx_fifo_empty)
    );

    // Parallel-to-Serial (Transmitter)
    wire tx_clk_en = !tx_fifo_empty;

    parallel_to_serial tx_shifter (
        .clk(clk),
        .rst(rst),
        .load(load_shift_reg),
        .parallel_in(tx_fifo_out),
        .serial_out(tx_serial_out)
    );

    // TX controller FSM
    reg [3:0] tx_bit_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_rd_en <= 0;
            load_shift_reg <= 0;
            tx_bit_cnt <= 0;
        end else begin
            if (!tx_fifo_empty) begin
                if (tx_bit_cnt == 0) begin
                    tx_rd_en <= 1;
                    load_shift_reg <= 1;
                    tx_bit_cnt <= 8;
                end else begin
                    tx_rd_en <= 0;
                    load_shift_reg <= 0;
                    tx_bit_cnt <= tx_bit_cnt - 1;
                end
            end else begin
                tx_rd_en <= 0;
                load_shift_reg <= 0;
            end
        end
    end

    // RX Serial-to-Parallel Receiver
    wire [7:0] rx_parallel_data;
    reg [2:0] rx_bit_cnt;
    reg rx_byte_ready;

    serial_to_parallel rx_shifter (
        .clk(clk),
        .rst(rst),
        .serial_in(rx_serial_in),
        .parallel_out(rx_parallel_data)
    );

    // RX FIFO
    reg rx_wr_en;
    fifo #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(16)
    ) rx_fifo (
        .clk(clk),
        .reset(rst),
        .wr_en(rx_wr_en),
        .rd_en(rx_read_en),
        .data_in(rx_parallel_data),
        .data_out(rx_data_out),
        .full(), // Not used
        .empty(rx_empty)
    );

    // RX controller
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_bit_cnt <= 0;
            rx_wr_en <= 0;
        end else begin
            rx_bit_cnt <= rx_bit_cnt + 1;
            if (rx_bit_cnt == 7) begin
                rx_wr_en <= 1;
            end else begin
                rx_wr_en <= 0;
            end
        end
    end

endmodule

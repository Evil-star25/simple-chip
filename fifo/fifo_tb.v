`timescale 1ns/1ps
`include "fifo.v"


module fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;
   
    // ----------- ceiling log2 FUNCTION -----------
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    parameter ptr_width = clog2(FIFO_DEPTH); 

    reg clk;
    reg reset;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire full;
    wire empty;


    // Instantiate FIFO
    fifo  uut (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        reset = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;

        // Release reset after some time
        #20;
        reset = 0;

        $display(" \nWrite some data into FIFO\n");
        repeat (FIFO_DEPTH) begin
            @(posedge clk);
            if (!full) begin
                wr_en = 1;
                data_in = data_in + 1;
            end else begin
                wr_en = 0;
            end
        end
        wr_en = 0;

        // Wait a few cycles
        repeat (5) @(posedge clk);

        $display("\nRead all data out\n");
        while (!empty) begin
            @(posedge clk);
            rd_en = 1;
        end
        rd_en = 0;

        // Wait a few cycles
        repeat (5) @(posedge clk);

       $display("\nTest simultaneous read and write\n");
        wr_en = 1;
        rd_en = 1;
        data_in = 8'hAA;
        @(posedge clk);
        wr_en = 0;
        rd_en = 0;

        // Final wait and end simulation
        #20;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | reset=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | full=%b | empty=%b | write_ptr=%d | read_ptr=%d | count=%d",
                $time, reset, wr_en, rd_en, data_in, data_out, full, empty, uut.write_pointer, uut.read_pointer, uut.count);
    end

endmodule

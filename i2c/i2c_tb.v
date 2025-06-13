`timescale 1ns/1ps

module tb_i2c_master;

  reg clk;
  reg rst;
  reg start;
  reg [6:0] addr;
  reg rw;
  reg [7:0] data_wr;
  wire [7:0] data_rd;
  wire busy;
  wire ack_error;
  wire sda;
  wire scl;

  // Instantiate the I2C master
  i2c_master uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .addr(addr),
    .rw(rw),
    .data_wr(data_wr),
    .data_rd(data_rd),
    .busy(busy),
    .ack_error(ack_error),
    .sda(sda),
    .scl(scl)
  );

  // Emulate SDA line with open-drain behavior
  reg sda_line;
  assign sda = (uut.sda_dir) ? uut.sda_out : 1'bz; // tristate driven by master
  // To test properly, we'd need a slave model to drive SDA low for ACK
  // For now, just monitor signals

  // Clock generation: 50 MHz clock (20 ns period)
  initial clk = 0;
  always #10 clk = ~clk;

  initial begin
    // Initialize inputs
    rst = 1;
    start = 0;
    addr = 7'h50;     // example slave address
    rw = 0;           // write
    data_wr = 8'hA5;  // example data byte to write

    // Reset
    #50;
    rst = 0;

    // Wait a bit then start transaction
    #50;
    start = 1;
    #20;
    start = 0;

    // Wait for transaction to complete
    wait (!busy);

    #100;

    // End simulation
    $stop;
  end

  // Monitor signals
  initial begin
    $dumpfile("i2c_master_tb.vcd");
    $dumpvars(0, tb_i2c_master);

    $display("Time\tclk\trst\tstart\tbusy\tack_err\tsda\tscl");
    $monitor("%0t\t%b\t%b\t%b\t%b\t%b\t%b\t%b",
              $time, clk, rst, start, busy, ack_error, sda, scl);
  end

endmodule

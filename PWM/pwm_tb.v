`timescale 1ns / 1ps
`include "pwm.v"

module pwm_tb;

    reg clk = 0;
    reg reset = 1;
    reg [7:0] duty_cycle;
    wire pwm_out;
    integer file;

    // Instantiate the PWM module
    pwm uut (
        .clk(clk),
        .duty_cycle(duty_cycle),
        .reset(reset),
        .pwm_out(pwm_out)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        // Open file for writing
        file = $fopen("pwm_output.txt", "w");
        if (file == 0) begin
            $display("Failed to open file!");
            $finish;
        end

        // Write header line to file
        $fwrite(file, "Time\tClk\tPWM_out\n");

        duty_cycle = 8'd64;  // 50% duty cycle

        // Display header
        $display("Time\tClk\tCounter\tPWM_out");

        // Hold reset for 20 ns
        reset = 1;
        #20 reset = 0;

        // Run for 300 clock cycles
        repeat (600) @(posedge clk) begin
            $fwrite(file, "%0t\t%b\t%b\n", $time, clk , pwm_out);
        end

        $finish;
    end

    // Print signals on every positive clock edge
    always @(posedge clk) begin
        $display("%0dns\t%b\t%d\t%b", $time, clk, uut.counter, pwm_out);
    end

endmodule

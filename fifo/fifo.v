module fifo (
    input wire clk,
    input wire reset,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty
);
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // Internal memory
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

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
    
    parameter ptr_width = clog2(FIFO_DEPTH +1); //the +1 s for the wrap-around;

    reg [ptr_width-1:0] wr_ptr = 0;
    reg [ptr_width-1:0] rd_ptr = 0;

    // Counter for number of stored elements
    reg [ptr_width:0] count = 0;

    // Write logic
    always @(posedge clk) begin
        if (reset) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic
    always @(posedge clk) begin
        if (reset) begin
            rd_ptr <= 0;
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Counter logic
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1; // write only
                2'b01: count <= count - 1; // read only
                default: count <= count;   // no op or simultaneous write/read
            endcase
        end
    end

    // Full and empty flags
    assign full  = (count == FIFO_DEPTH);
    assign empty = (count == 0);

endmodule
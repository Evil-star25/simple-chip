module fifo (
    input wire clk,
    input wire reset,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
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
    
    parameter ptr_width = clog2(FIFO_DEPTH); 

    reg [ptr_width-1:0] write_pointer = {ptr_width{1'b0}};
    reg [ptr_width-1:0] read_pointer = {ptr_width{1'b0}};
    reg [ptr_width:0] count;
 

    // --- Full and empty flags --//-
    assign full = (count == FIFO_DEPTH) ;
    assign empty = (count == 0) ;
   

    //--- Write logic ---------
    always @(posedge clk) begin
        if (reset) begin
            write_pointer <= {ptr_width{1'b0}};
        end else if (wr_en && !full) begin
            mem[write_pointer] <= data_in;
            write_pointer <= (write_pointer == FIFO_DEPTH - 1) ? {ptr_width{1'b0}} : write_pointer + 1;
        end
    end

    //--- Read logic ---
    
    always @(posedge clk) begin
        if (reset) begin
            read_pointer <= {ptr_width{1'b0}};
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (rd_en && !empty) begin
            data_out <= mem[read_pointer]; 
            read_pointer <= (read_pointer == FIFO_DEPTH - 1) ? {ptr_width{1'b0}} : read_pointer + 1;
 
        end 
    end



    //---Tracking the Counter ---
    always @(posedge clk) begin
        if (reset) begin
            count <= {(ptr_width+1){1'b0}};
        end else begin
            case ({wr_en, rd_en})
                2'b10: count <= count + 1; // Write only
                2'b01: count <= count - 1; // Read only
                default: count <= count;   // No change or simultaneous read/write
            endcase
        end
    end

    

endmodule

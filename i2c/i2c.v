module i2c_master (
    input wire clk,         // System clock
    input wire rst,         // Reset (active high)
    input wire start,       // Start transaction trigger
    input wire [6:0] addr,  // 7-bit slave address
    input wire rw,          // 0 = write, 1 = read
    input wire [7:0] data_wr,   // Data to write
    output reg [7:0] data_rd,   // Data read
    output reg busy,            // Transaction busy flag
    output reg ack_error,       // ACK error flag
    inout wire sda,             // I2C data line (open-drain)
    output reg scl              // I2C clock line
);

    // I2C states
    typedef enum logic [3:0] {
        IDLE = 0,
        START_COND,
        ADDR,
        ADDR_ACK,
        WRITE_BYTE,
        WRITE_ACK,
        READ_BYTE,
        SEND_ACK,
        STOP_COND
    } state_t;

    state_t state, next_state;

    reg [3:0] bit_cnt;
    reg sda_out;       // SDA output driver
    reg sda_dir;       // SDA direction: 1=output, 0=input (tri-state)

    // Assign SDA as tri-state (open-drain emulation)
    assign sda = sda_dir ? sda_out : 1'bz;

    // Clock generation: For simplicity, scl toggled every few clk cycles
    // Here we assume clk is fast enough and manually toggle scl in state machine

    // Simple state machine for I2C master
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            scl <= 1;
            busy <= 0;
            ack_error <= 0;
            sda_out <= 1;
            sda_dir <= 1;
            bit_cnt <= 0;
            data_rd <= 0;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        // Default assignments
        next_state = state;
        busy = (state != IDLE);
        ack_error = 0;
        sda_dir = 1;  // Drive SDA by default
        sda_out = 1;
        scl = 1;

        case (state)
            IDLE: begin
                busy = 0;
                sda_out = 1;
                sda_dir = 1;
                scl = 1;
                if (start)
                    next_state = START_COND;
            end

            START_COND: begin
                // Generate start condition: SDA goes low while SCL high
                scl = 1;
                sda_out = 0;
                next_state = ADDR;
                bit_cnt = 7;
            end

            ADDR: begin
                // Send 7-bit address + RW bit
                scl = 0; // Clock low for data change
                sda_out = addr[bit_cnt];
                if (bit_cnt == 0)
                    next_state = ADDR_ACK;
                else
                    bit_cnt = bit_cnt - 1;
            end

            ADDR_ACK: begin
                // Release SDA for ACK bit from slave
                sda_dir = 0; // input
                scl = 1; // Clock high to sample ACK
                if (sda == 1) // NACK
                    ack_error = 1;
                next_state = (rw) ? READ_BYTE : WRITE_BYTE;
                bit_cnt = 7;
            end

            WRITE_BYTE: begin
                scl = 0;
                sda_out = data_wr[bit_cnt];
                if (bit_cnt == 0)
                    next_state = WRITE_ACK;
                else
                    bit_cnt = bit_cnt - 1;
            end

            WRITE_ACK: begin
                sda_dir = 0; // input for ACK
                scl = 1;
                if (sda == 1) // NACK
                    ack_error = 1;
                next_state = STOP_COND;
            end

            READ_BYTE: begin
                sda_dir = 0; // input SDA
                scl = 1;
                data_rd[bit_cnt] = sda;
                if (bit_cnt == 0)
                    next_state = SEND_ACK;
                else
                    bit_cnt = bit_cnt - 1;
            end

            SEND_ACK: begin
                sda_dir = 1;
                sda_out = 0; // ACK to slave
                scl = 0;
                next_state = STOP_COND;
            end

            STOP_COND: begin
                // Stop condition: SDA goes high while SCL high
                scl = 1;
                sda_out = 0;
                sda_dir = 1;
                // After a delay, release SDA to 1
                sda_out = 1;
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule

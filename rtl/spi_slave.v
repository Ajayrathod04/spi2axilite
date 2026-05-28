// ============================================================================
// Module Name: spi_slave
// Description: Simple SPI Slave physical layer.
//              Supports SPI Mode 0 (CPOL=0, CPHA=0).
//              Synchronizes sclk, cs_n, and mosi to clk to prevent metastability.
// ============================================================================
module spi_slave (
    input clk,          // Fast system clock
    input rst_n,        // Active-low asynchronous reset
    input mosi,         // Master Out Slave In
    output miso,        // Master In Slave Out
    input sclk,         // SPI Clock
    input cs_n,         // Chip Select (active low)
    output reg [7:0] data_out, // Received byte
    output reg done,    // High for 1 clk cycle when a byte is received
    input [7:0] tx_data, // Byte to transmit (read response)
    input tx_load       // Load tx_data on next sclk_negedge (no shift)
);

    // Double-synchronizer registers
    reg [2:0] sclk_sync;
    reg [2:0] cs_n_sync;
    reg [1:0] mosi_sync;

    // Synchronize external inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            cs_n_sync <= 3'b111;
            mosi_sync <= 2'b00;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_n_sync <= {cs_n_sync[1:0], cs_n};
            mosi_sync <= {mosi_sync[0], mosi};
        end
    end

    // Edge detectors
    wire sclk_posedge = (sclk_sync[2:1] == 2'b01);
    wire sclk_negedge = (sclk_sync[2:1] == 2'b10);
    wire cs_n_active  = ~cs_n_sync[1];
    wire cs_n_rising  = (cs_n_sync[2:1] == 2'b01);

    // SPI Receiver logic
    reg [2:0] bit_cnt;
    reg [7:0] rx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 3'b000;
            rx_shift <= 8'h00;
            data_out <= 8'h00;
            done <= 1'b0;
        end else if (!cs_n_active) begin
            bit_cnt <= 3'b000;
            rx_shift <= 8'h00;
            done <= 1'b0;
        end else begin
            done <= 1'b0; // Default pulse
            if (sclk_posedge) begin
                rx_shift <= {rx_shift[6:0], mosi_sync[1]};
                bit_cnt <= bit_cnt + 1'b1;
                if (bit_cnt == 3'd7) begin
                    data_out <= {rx_shift[6:0], mosi_sync[1]};
                    done <= 1'b1;
                end
            end
        end
    end

    // SPI Transmitter logic (MISO)
    reg [7:0] tx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= 8'h00;
        end else if (!cs_n_active) begin
            tx_shift <= 8'h00;
        end else begin
            if (tx_load) begin
                tx_shift <= tx_data;
            end else if (sclk_negedge) begin
                tx_shift <= {tx_shift[6:0], 1'b0};
            end
        end
    end

    // MISO Output Driver (tri-state when CS_N is inactive)
    assign miso = cs_n_active ? tx_shift[7] : 1'bz;

endmodule

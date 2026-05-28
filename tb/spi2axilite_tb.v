// ============================================================================
// Module Name: spi2axilite_tb
// Description: Comprehensive testbench for the SPI to AXI4-Lite Bridge.
//              Tests Reset, SPI Write, SPI Read, and Invalid Command Handling.
// ============================================================================
`timescale 1ns / 1ps

module spi2axilite_tb;

    // Simulation Constants
    parameter CLK_PERIOD = 10; // 100 MHz System Clock

    // Testbench Signals
    reg clk;
    reg rst_n;
    reg mosi;
    reg sclk;
    reg cs_n;
    wire miso;

    // Output variables for tasks
    reg [7:0] rxt_cmd;
    reg [7:0] rxt_addr;
    reg [7:0] rxt_data;

    // Instantiate Design Under Test (DUT)
    spi2axilite dut (
        .clk(clk),
        .rst_n(rst_n),
        .mosi(mosi),
        .miso(miso),
        .sclk(sclk),
        .cs_n(cs_n)
    );

    // Clock Generator (100 MHz)
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ========================================================================
    // SPI Driver Tasks
    // ========================================================================

    // Task to transmit/receive a single byte over SPI (Mode 0)
    task send_spi_byte;
        input [7:0] byte_to_send;
        output [7:0] byte_received;
        integer i;
        begin
            byte_received = 8'h00;
            for (i = 7; i >= 0; i = i - 1) begin
                // Drive MOSI
                mosi = byte_to_send[i];
                
                // Wait for half of SPI clock period (50ns total SPI clk period => 20MHz SPI Clock)
                #(CLK_PERIOD * 5);
                
                // Rising edge of sclk (Data is sampled here)
                sclk = 1'b1;
                byte_received[i] = miso;
                
                // Wait for half of SPI clock period
                #(CLK_PERIOD * 5);
                
                // Falling edge of sclk (Data is shifted out here)
                sclk = 1'b0;
            end
        end
    endtask

    // Task to run a complete SPI 24-bit transaction [CMD][ADDR][DATA]
    task spi_transaction;
        input [7:0] cmd;
        input [7:0] addr;
        input [7:0] data_in;
        output [7:0] rx_cmd;
        output [7:0] rx_addr;
        output [7:0] rx_data;
        begin
            // Select the slave
            cs_n = 1'b0;
            sclk = 1'b0;
            mosi = 1'b0;
            #(CLK_PERIOD * 2);

            // 1. Send CMD Byte
            $display("[SPI TB] Transmitting CMD: 8'h%h", cmd);
            send_spi_byte(cmd, rx_cmd);
            #(CLK_PERIOD * 2);

            // 2. Send ADDR Byte
            $display("[SPI TB] Transmitting ADDR: 8'h%h", addr);
            send_spi_byte(addr, rx_addr);
            #(CLK_PERIOD * 2);

            // 3. Send DATA Byte
            $display("[SPI TB] Transmitting DATA: 8'h%h", data_in);
            send_spi_byte(data_in, rx_data);
            #(CLK_PERIOD * 2);

            // Deselect the slave
            cs_n = 1'b1;
            mosi = 1'b0;
            #(CLK_PERIOD * 10); // Wait for the FSM and AXI to settle back to IDLE
        end
    endtask

    // ========================================================================
    // Main Test Stimulus
    // ========================================================================
    initial begin
        // Initialize Signals
        clk   = 1'b0;
        rst_n = 1'b1;
        mosi  = 1'b0;
        sclk  = 1'b0;
        cs_n  = 1'b1;

        $display("==========================================================");
        $display("   STARTING SPI TO AXI4-LITE BRIDGE SIMULATION TESTBENCH  ");
        $display("==========================================================");

        // 1. Reset Test
        $display("\n--- TEST CASE 1: System Reset ---");
        #(CLK_PERIOD * 2);
        rst_n = 1'b0; // Apply active-low reset
        #(CLK_PERIOD * 5);
        rst_n = 1'b1; // Release reset
        #(CLK_PERIOD * 5);
        
        // Check reset values of the AXI Register Bank via hierarchical paths
        if (dut.u_reg_bank.reg_control == 32'h00000000 &&
            dut.u_reg_bank.reg_data0   == 32'h00000000 &&
            dut.u_reg_bank.reg_data1   == 32'h00000000 &&
            dut.u_reg_bank.reg_status  == 32'h00000001) begin
            $display("[PASS] Reset values of registers are correct.");
        end else begin
            $display("[FAIL] Reset values of registers are incorrect!");
            $finish;
        end

        // 2. SPI Write Transaction Test
        $display("\n--- TEST CASE 2: SPI Write to DATA0 (Addr 0x08) ---");
        // CMD = 0x01 (WRITE), ADDR = 0x08 (DATA0), DATA = 0xAA
        spi_transaction(8'h01, 8'h08, 8'hAA, rxt_cmd, rxt_addr, rxt_data);
        
        // Verify register updated correctly
        if (dut.u_reg_bank.reg_data0 == 32'h000000AA) begin
            $display("[PASS] DATA0 register successfully written with value 8'hAA.");
        end else begin
            $display("[FAIL] DATA0 register holds: 32'h%h, expected: 32'hAA!", dut.u_reg_bank.reg_data0);
            $finish;
        end

        // 3. SPI Read Transaction Test
        $display("\n--- TEST CASE 3: SPI Read from DATA0 (Addr 0x08) ---");
        // CMD = 0x02 (READ), ADDR = 0x08 (DATA0), DATA = 0x00 (Dummy)
        spi_transaction(8'h02, 8'h08, 8'h00, rxt_cmd, rxt_addr, rxt_data);
        
        // Verify received data matches written data
        if (rxt_data == 8'hAA) begin
            $display("[PASS] SPI Read successfully returned 8'hAA on MISO.");
        end else begin
            $display("[FAIL] SPI Read returned: 8'h%h, expected: 8'hAA!", rxt_data);
            $finish;
        end

        // 4. SPI Write to CONTROL and Read Status
        $display("\n--- TEST CASE 4: Write to CONTROL (Addr 0x00) & Read STATUS (Addr 0x04) ---");
        // Write 0x55 to CONTROL
        spi_transaction(8'h01, 8'h00, 8'h55, rxt_cmd, rxt_addr, rxt_data);
        if (dut.u_reg_bank.reg_control == 32'h00000055) begin
            $display("[PASS] CONTROL register successfully written with 8'h55.");
        end else begin
            $display("[FAIL] CONTROL register holds: 32'h%h, expected: 32'h55!", dut.u_reg_bank.reg_control);
            $finish;
        end

        // Read STATUS register
        spi_transaction(8'h02, 8'h04, 8'h00, rxt_cmd, rxt_addr, rxt_data);
        if (rxt_data == 8'h01) begin
            $display("[PASS] SPI Read of STATUS returned 8'h01 (Active).");
        end else begin
            $display("[FAIL] SPI Read of STATUS returned: 8'h%h, expected: 8'h01!", rxt_data);
            $finish;
        end

        // 5. Invalid Command Handling Test
        $display("\n--- TEST CASE 5: Invalid Command Handling ---");
        // CMD = 0xFF (Invalid), ADDR = 0x0C (DATA1), DATA = 0x99
        spi_transaction(8'hFF, 8'h0C, 8'h99, rxt_cmd, rxt_addr, rxt_data);
        
        // Verify register DATA1 is NOT written (should remain 0x00)
        if (dut.u_reg_bank.reg_data1 == 32'h00000000) begin
            $display("[PASS] Invalid command ignored; DATA1 register remains unchanged.");
        end else begin
            $display("[FAIL] DATA1 register written on invalid command! Holds: 32'h%h", dut.u_reg_bank.reg_data1);
            $finish;
        end

        $display("\n==========================================================");
        $display("      ALL SIMULATION TEST CASES COMPLETED SUCCESSFULLY    ");
        $display("==========================================================");
        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule

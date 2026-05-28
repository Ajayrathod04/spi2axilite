// ============================================================================
// Module Name: spi_fsm
// Description: Main Control Finite State Machine for SPI to AXI4-Lite Bridge.
//              Orchestrates packet reception, command decoding, AXI transactions,
//              and read response shifting.
// ============================================================================
module spi_fsm (
    input clk,
    input rst_n,

    // SPI Chip Select and SCLK Edge Detector (from SPI Slave)
    input cs_n,
    input sclk_negedge,

    // SPI Slave status
    input done,
    input [7:0] data_out,

    // SPI Command Decoder Interface
    output [7:0] cmd_byte,
    input write_en,
    input read_en,
    input invalid_cmd,

    // AXI Master Interface
    output reg write_req,
    output [31:0] write_addr,
    output [31:0] write_data,
    input write_done,

    output reg read_req,
    output [31:0] read_addr,
    input read_done,
    input [31:0] read_data_out,

    // SPI Slave Tx control
    output [7:0] tx_data,
    output tx_load
);

    // FSM States
    localparam IDLE      = 3'd0;
    localparam GET_CMD   = 3'd1;
    localparam GET_ADDR  = 3'd2;
    localparam GET_DATA  = 3'd3;
    localparam AXI_WRITE = 3'd4;
    localparam AXI_READ  = 3'd5;
    localparam SEND_RESP = 3'd6;

    reg [2:0] state;

    // ASCII State Name for easy waveform debugging
    reg [79:0] state_name;
    always @(*) begin
        case (state)
            IDLE:      state_name = "IDLE";
            GET_CMD:   state_name = "GET_CMD";
            GET_ADDR:  state_name = "GET_ADDR";
            GET_DATA:  state_name = "GET_DATA";
            AXI_WRITE: state_name = "AXI_WRITE";
            AXI_READ:  state_name = "AXI_READ";
            SEND_RESP: state_name = "SEND_RESP";
            default:   state_name = "UNKNOWN";
        endcase
    end

    // Registers to capture SPI inputs
    reg [7:0] cmd_reg;
    reg [7:0] addr_reg;
    reg [7:0] data_reg;
    reg [7:0] read_data_reg;

    // Command byte mapping to Decoder
    assign cmd_byte = cmd_reg;

    // AXI Address & Data Mapping (SPI Address maps directly to lower bits of 32-bit AXI Address)
    assign write_addr = {24'h000000, addr_reg};
    assign write_data = {24'h000000, data_reg};
    assign read_addr  = {24'h000000, addr_reg};

    // Double-synchronized CS_N for FSM transitions
    reg [1:0] cs_n_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs_n_sync <= 2'b11;
        end else begin
            cs_n_sync <= {cs_n_sync[0], cs_n};
        end
    end
    wire cs_n_active = ~cs_n_sync[1];

    // State machine sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            cmd_reg       <= 8'h00;
            addr_reg      <= 8'h00;
            data_reg      <= 8'h00;
            read_data_reg <= 8'h00;
            write_req     <= 1'b0;
            read_req      <= 1'b0;
        end else if (!cs_n_active) begin
            if (state != IDLE) begin
                $display("[RTL FSM] CS_N went high. Resetting FSM back to IDLE at time %0t ns", $time);
            end
            state         <= IDLE;
            cmd_reg       <= 8'h00;
            addr_reg      <= 8'h00;
            data_reg      <= 8'h00;
            write_req     <= 1'b0;
            read_req      <= 1'b0;
        end else begin
            // Default req clearing
            if (write_done) write_req <= 1'b0;
            if (read_done)  read_req  <= 1'b0;

            case (state)
                IDLE: begin
                    cmd_reg  <= 8'h00;
                    addr_reg <= 8'h00;
                    data_reg <= 8'h00;
                    $display("[RTL FSM] CS_N went active. Transitioning to GET_CMD at time %0t ns", $time);
                    state    <= GET_CMD;
                end

                GET_CMD: begin
                    if (done) begin
                        cmd_reg <= data_out;
                        $display("[RTL FSM] Received CMD: 8'h%h at time %0t ns", data_out, $time);
                        state   <= GET_ADDR;
                    end
                end

                GET_ADDR: begin
                    if (done) begin
                        addr_reg <= data_out;
                        $display("[RTL FSM] Received ADDR: 8'h%h at time %0t ns", data_out, $time);
                        // Determine next state from decoded cmd_reg (routed through decoder)
                        if (write_en) begin
                            $display("[RTL FSM] Decoded WRITE command. Transitioning to GET_DATA at time %0t ns", $time);
                            state <= GET_DATA;
                        end else if (read_en) begin
                            $display("[RTL FSM] Decoded READ command. Transitioning to AXI_READ at time %0t ns", $time);
                            state <= AXI_READ;
                        end else begin
                            $display("[RTL FSM] Decoded INVALID command. Resetting to IDLE at time %0t ns", $time);
                            state <= IDLE;
                        end
                    end
                end

                GET_DATA: begin
                    if (done) begin
                        data_reg <= data_out;
                        $display("[RTL FSM] Received DATA: 8'h%h. Transitioning to AXI_WRITE at time %0t ns", data_out, $time);
                        state    <= AXI_WRITE;
                    end
                end

                AXI_WRITE: begin
                    // Trigger AXI Master Write
                    if (!write_req && !write_done) begin
                        $display("[RTL FSM] Triggering AXI WRITE: Address = 32'h%h, Data = 32'h%h at time %0t ns", write_addr, write_data, $time);
                        write_req <= 1'b1;
                    end else if (write_done) begin
                        $display("[RTL FSM] AXI WRITE Completed successfully at time %0t ns", $time);
                        write_req <= 1'b0;
                        state     <= IDLE; // Transaction complete
                    end
                end

                AXI_READ: begin
                    // Trigger AXI Master Read
                    if (!read_req && !read_done) begin
                        $display("[RTL FSM] Triggering AXI READ: Address = 32'h%h at time %0t ns", read_addr, $time);
                        read_req <= 1'b1;
                    end else if (read_done) begin
                        $display("[RTL FSM] AXI READ Completed. Read Value = 32'h%h at time %0t ns", read_data_out, $time);
                        read_req      <= 1'b0;
                        read_data_reg <= read_data_out[7:0]; // Capture 8-bit read data
                        state         <= SEND_RESP;
                    end
                end

                SEND_RESP: begin
                    // In SEND_RESP, SPI Slave will clock out read_data_reg on MISO.
                    // We stay in this state until CS_N goes high (handled by the top level CS_N block)
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Load read response to SPI Shift Register exactly once upon entering SEND_RESP state
    reg loaded;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            loaded <= 1'b0;
        end else if (state != SEND_RESP) begin
            loaded <= 1'b0;
        end else if (tx_load) begin
            loaded <= 1'b1;
        end
    end

    assign tx_load = (state == SEND_RESP) && !loaded;
    assign tx_data = read_data_reg;

endmodule

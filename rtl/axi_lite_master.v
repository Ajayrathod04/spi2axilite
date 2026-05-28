// ============================================================================
// Module Name: axi_lite_master
// Description: Simple AXI4-Lite Master interface.
//              Handles write and read transfers to/from AXI registers.
//              Complies with AXI4-Lite handshaking guidelines.
// ============================================================================
module axi_lite_master (
    input clk,
    input rst_n,

    // Interface to FSM
    input write_req,
    input [31:0] write_addr,
    input [31:0] write_data,
    output reg write_done,

    input read_req,
    input [31:0] read_addr,
    output reg [31:0] read_data_out,
    output reg read_done,

    // AXI4-Lite Write Address Channel
    output [31:0] m_axi_awaddr,
    output m_axi_awvalid,
    input m_axi_awready,

    // AXI4-Lite Write Data Channel
    output [31:0] m_axi_wdata,
    output [3:0] m_axi_wstrb,
    output m_axi_wvalid,
    input m_axi_wready,

    // AXI4-Lite Write Response Channel
    input [1:0] m_axi_bresp,
    input m_axi_bvalid,
    output m_axi_bready,

    // AXI4-Lite Read Address Channel
    output [31:0] m_axi_araddr,
    output m_axi_arvalid,
    input m_axi_arready,

    // AXI4-Lite Read Data Channel
    input [31:0] m_axi_rdata,
    input [1:0] m_axi_rresp,
    input m_axi_rvalid,
    output m_axi_rready
);

    // FSM States
    localparam AXI_IDLE            = 3'd0;
    localparam AXI_WRITE_STATE     = 3'd1;
    localparam AXI_WRESP_STATE     = 3'd2;
    localparam AXI_READ_ADDR_STATE = 3'd3;
    localparam AXI_READ_DATA_STATE = 3'd4;
    localparam AXI_DONE_STATE      = 3'd5;

    reg [2:0] state;

    // ASCII AXI State Name for easy waveform debugging
    reg [127:0] axi_state_name;
    always @(*) begin
        case (state)
            AXI_IDLE:            axi_state_name = "AXI_IDLE";
            AXI_WRITE_STATE:     axi_state_name = "AXI_WRITE_STATE";
            AXI_WRESP_STATE:     axi_state_name = "AXI_WRESP_STATE";
            AXI_READ_ADDR_STATE: axi_state_name = "AXI_READ_ADDR_STATE";
            AXI_READ_DATA_STATE: axi_state_name = "AXI_READ_DATA_STATE";
            AXI_DONE_STATE:      axi_state_name = "AXI_DONE_STATE";
            default:             axi_state_name = "UNKNOWN";
        endcase
    end

    // Registers to store target address and data
    reg [31:0] reg_waddr;
    reg [31:0] reg_wdata;
    reg [31:0] reg_raddr;
    reg req_type_write; // 1 = write, 0 = read

    // Track write handshake completion
    reg aw_done;
    reg w_done;

    // AXI Port Assignments
    assign m_axi_awaddr  = reg_waddr;
    assign m_axi_awvalid = (state == AXI_WRITE_STATE) && !aw_done;

    assign m_axi_wdata   = reg_wdata;
    assign m_axi_wstrb   = 4'hF; // Write all 4 bytes
    assign m_axi_wvalid  = (state == AXI_WRITE_STATE) && !w_done;

    assign m_axi_bready  = (state == AXI_WRESP_STATE);

    assign m_axi_araddr  = reg_raddr;
    assign m_axi_arvalid = (state == AXI_READ_ADDR_STATE);

    assign m_axi_rready  = (state == AXI_READ_DATA_STATE);

    // State Machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= AXI_IDLE;
            reg_waddr       <= 32'h0;
            reg_wdata       <= 32'h0;
            reg_raddr       <= 32'h0;
            req_type_write  <= 1'b0;
            aw_done         <= 1'b0;
            w_done          <= 1'b0;
            read_data_out   <= 32'h0;
            write_done      <= 1'b0;
            read_done       <= 1'b0;
        end else begin
            write_done <= 1'b0; // Default pulse
            read_done  <= 1'b0; // Default pulse

            case (state)
                AXI_IDLE: begin
                    aw_done <= 1'b0;
                    w_done  <= 1'b0;
                    if (write_req) begin
                        reg_waddr      <= write_addr;
                        reg_wdata      <= write_data;
                        req_type_write <= 1'b1;
                        state          <= AXI_WRITE_STATE;
                    end else if (read_req) begin
                        reg_raddr      <= read_addr;
                        req_type_write <= 1'b0;
                        state          <= AXI_READ_ADDR_STATE;
                    end
                end

                AXI_WRITE_STATE: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        aw_done <= 1'b1;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        w_done <= 1'b1;
                    end

                    // Check if both address and data are accepted
                    if ((aw_done || (m_axi_awvalid && m_axi_awready)) && 
                        (w_done  || (m_axi_wvalid  && m_axi_wready))) begin
                        state <= AXI_WRESP_STATE;
                    end
                end

                AXI_WRESP_STATE: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        state <= AXI_DONE_STATE;
                    end
                end

                AXI_READ_ADDR_STATE: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        state <= AXI_READ_DATA_STATE;
                    end
                end

                AXI_READ_DATA_STATE: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        read_data_out <= m_axi_rdata;
                        state         <= AXI_DONE_STATE;
                    end
                end

                AXI_DONE_STATE: begin
                    if (req_type_write) begin
                        write_done <= 1'b1;
                    end else begin
                        read_done  <= 1'b1;
                    end
                    state <= AXI_IDLE;
                end

                default: state <= AXI_IDLE;
            endcase
        end
    end

endmodule

// ============================================================================
// Module Name: axi_register_bank
// Description: AXI4-Lite Slave Register Bank.
//              Contains four 32-bit registers:
//              0x00 -> CONTROL (Read/Write)
//              0x04 -> STATUS (Read-Only)
//              0x08 -> DATA0 (Read/Write)
//              0x0C -> DATA1 (Read/Write)
// ============================================================================
module axi_register_bank (
    input clk,
    input rst_n,

    // AXI4-Lite Write Address Channel
    input [31:0] s_axi_awaddr,
    input s_axi_awvalid,
    output s_axi_awready,

    // AXI4-Lite Write Data Channel
    input [31:0] s_axi_wdata,
    input [3:0] s_axi_wstrb,
    input s_axi_wvalid,
    output s_axi_wready,

    // AXI4-Lite Write Response Channel
    output [1:0] s_axi_bresp,
    output s_axi_bvalid,
    input s_axi_bready,

    // AXI4-Lite Read Address Channel
    input [31:0] s_axi_araddr,
    input s_axi_arvalid,
    output s_axi_arready,

    // AXI4-Lite Read Data Channel
    output [31:0] s_axi_rdata,
    output [1:0] s_axi_rresp,
    output s_axi_rvalid,
    input s_axi_rready,

    // Register outputs for top-level visibility
    output reg [31:0] reg_control,
    output reg [31:0] reg_status,
    output reg [31:0] reg_data0,
    output reg [31:0] reg_data1
);

    reg awready_reg;
    reg wready_reg;
    reg bvalid_reg;
    reg arready_reg;
    reg rvalid_reg;
    reg [31:0] rdata_reg;

    // AXI4-Lite Channel Assignments
    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = 2'b00; // OKAY

    assign s_axi_arready = arready_reg;
    assign s_axi_rvalid  = rvalid_reg;
    assign s_axi_rdata   = rdata_reg;
    assign s_axi_rresp   = 2'b00; // OKAY

    // 1. Write Handshake Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
            bvalid_reg  <= 1'b0;
        end else begin
            if (s_axi_awvalid && s_axi_wvalid && !awready_reg) begin
                awready_reg <= 1'b1;
                wready_reg  <= 1'b1;
                bvalid_reg  <= 1'b1;
            end else begin
                awready_reg <= 1'b0;
                wready_reg  <= 1'b0;
                if (s_axi_bready && bvalid_reg) begin
                    bvalid_reg <= 1'b0;
                end
            end
        end
    end

    // 2. Write Registers Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_control <= 32'h00000000;
            reg_status  <= 32'h00000001; // Default status is active/good
            reg_data0   <= 32'h00000000;
            reg_data1   <= 32'h00000000;
        end else begin
            // Read-Only Status register updates (can be extended)
            reg_status <= 32'h00000001;

            if (s_axi_awvalid && s_axi_wvalid && !awready_reg) begin
                case (s_axi_awaddr[7:0])
                    8'h00: reg_control <= s_axi_wdata;
                    8'h04: ; // STATUS register is read-only
                    8'h08: reg_data0   <= s_axi_wdata;
                    8'h0C: reg_data1   <= s_axi_wdata;
                    default: ;
                endcase
            end
        end
    end

    // 3. Read Handshake & Data Multiplexing Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready_reg <= 1'b0;
            rvalid_reg  <= 1'b0;
            rdata_reg   <= 32'h0;
        end else begin
            if (s_axi_arvalid && !arready_reg) begin
                arready_reg <= 1'b1;
                rvalid_reg  <= 1'b1;
                case (s_axi_araddr[7:0])
                    8'h00: rdata_reg <= reg_control;
                    8'h04: rdata_reg <= reg_status;
                    8'h08: rdata_reg <= reg_data0;
                    8'h0C: rdata_reg <= reg_data1;
                    default: rdata_reg <= 32'hDEADBEEF; // Return DEADBEEF for invalid addresses
                endcase
            end else begin
                arready_reg <= 1'b0;
                if (s_axi_rready && rvalid_reg) begin
                    rvalid_reg <= 1'b0;
                end
            end
        end
    end

endmodule

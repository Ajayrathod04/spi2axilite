// ============================================================================
// Module Name: spi2axilite
// Description: Top-level module for the SPI to AXI4-Lite Bridge.
//              Instantiates and connects all submodules.
// ============================================================================
module spi2axilite (
    input clk,          // Fast system clock
    input rst_n,        // Active-low asynchronous reset
    input mosi,         // Master Out Slave In
    output miso,        // Master In Slave Out
    input sclk,         // SPI Clock
    input cs_n          // Chip Select (active low)
);

    // ========================================================================
    // Internal Wires & Synchronizers
    // ========================================================================
    
    // SCLK edge detection for FSM
    reg [2:0] sclk_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
        end
    end
    wire sclk_negedge = (sclk_sync[2:1] == 2'b10);

    // SPI Slave <=> FSM / Decoder Connections
    wire [7:0] spi_data_out;
    wire spi_done;
    wire [7:0] spi_tx_data;
    wire spi_tx_load;

    // Command Decoder Connections
    wire [7:0] cmd_byte;
    wire write_en;
    wire read_en;
    wire invalid_cmd;

    // FSM <=> AXI Master Connections
    wire write_req;
    wire [31:0] write_addr;
    wire [31:0] write_data;
    wire write_done;

    wire read_req;
    wire [31:0] read_addr;
    wire read_done;
    wire [31:0] read_data_out;

    // AXI Master <=> AXI Register Bank (AXI4-Lite Bus Wires)
    wire [31:0] axi_awaddr;
    wire axi_awvalid;
    wire axi_awready;

    wire [31:0] axi_wdata;
    wire [3:0] axi_wstrb;
    wire axi_wvalid;
    wire axi_wready;

    wire [1:0] axi_bresp;
    wire axi_bvalid;
    wire axi_bready;

    wire [31:0] axi_araddr;
    wire axi_arvalid;
    wire axi_arready;

    wire [31:0] axi_rdata;
    wire [1:0] axi_rresp;
    wire axi_rvalid;
    wire axi_rready;

    // Register outputs (probed during simulation)
    wire [31:0] reg_control;
    wire [31:0] reg_status;
    wire [31:0] reg_data0;
    wire [31:0] reg_data1;

    // ========================================================================
    // Submodule Instantiations
    // ========================================================================

    // 1. SPI Slave Physical Interface
    spi_slave u_spi_slave (
        .clk(clk),
        .rst_n(rst_n),
        .mosi(mosi),
        .miso(miso),
        .sclk(sclk),
        .cs_n(cs_n),
        .data_out(spi_data_out),
        .done(spi_done),
        .tx_data(spi_tx_data),
        .tx_load(spi_tx_load)
    );

    // 2. SPI Command Decoder
    spi_cmd_decoder u_cmd_decoder (
        .cmd_byte(cmd_byte),
        .write_en(write_en),
        .read_en(read_en),
        .invalid_cmd(invalid_cmd)
    );

    // 3. SPI State Machine (Orchestrator)
    spi_fsm u_spi_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .cs_n(cs_n),
        .sclk_negedge(sclk_negedge),
        .done(spi_done),
        .data_out(spi_data_out),
        .cmd_byte(cmd_byte),
        .write_en(write_en),
        .read_en(read_en),
        .invalid_cmd(invalid_cmd),
        .write_req(write_req),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_done(write_done),
        .read_req(read_req),
        .read_addr(read_addr),
        .read_done(read_done),
        .read_data_out(read_data_out),
        .tx_data(spi_tx_data),
        .tx_load(spi_tx_load)
    );

    // 4. AXI4-Lite Master Interface
    axi_lite_master u_axi_master (
        .clk(clk),
        .rst_n(rst_n),
        .write_req(write_req),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_done(write_done),
        .read_req(read_req),
        .read_addr(read_addr),
        .read_data_out(read_data_out),
        .read_done(read_done),
        .m_axi_awaddr(axi_awaddr),
        .m_axi_awvalid(axi_awvalid),
        .m_axi_awready(axi_awready),
        .m_axi_wdata(axi_wdata),
        .m_axi_wstrb(axi_wstrb),
        .m_axi_wvalid(axi_wvalid),
        .m_axi_wready(axi_wready),
        .m_axi_bresp(axi_bresp),
        .m_axi_bvalid(axi_bvalid),
        .m_axi_bready(axi_bready),
        .m_axi_araddr(axi_araddr),
        .m_axi_arvalid(axi_arvalid),
        .m_axi_arready(axi_arready),
        .m_axi_rdata(axi_rdata),
        .m_axi_rresp(axi_rresp),
        .m_axi_rvalid(axi_rvalid),
        .m_axi_rready(axi_rready)
    );

    // 5. AXI Register Bank (AXI4-Lite Slave)
    axi_register_bank u_reg_bank (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_awaddr(axi_awaddr),
        .s_axi_awvalid(axi_awvalid),
        .s_axi_awready(axi_awready),
        .s_axi_wdata(axi_wdata),
        .s_axi_wstrb(axi_wstrb),
        .s_axi_wvalid(axi_wvalid),
        .s_axi_wready(axi_wready),
        .s_axi_bresp(axi_bresp),
        .s_axi_bvalid(axi_bvalid),
        .s_axi_bready(axi_bready),
        .s_axi_araddr(axi_araddr),
        .s_axi_arvalid(axi_arvalid),
        .s_axi_arready(axi_arready),
        .s_axi_rdata(axi_rdata),
        .s_axi_rresp(axi_rresp),
        .s_axi_rvalid(axi_rvalid),
        .s_axi_rready(axi_rready),
        .reg_control(reg_control),
        .reg_status(reg_status),
        .reg_data0(reg_data0),
        .reg_data1(reg_data1)
    );

endmodule

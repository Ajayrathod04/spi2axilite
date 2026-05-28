# ============================================================================
# ModelSim Simulation Run Script
# File Name: run.do
# Description: Starts simulation, adds waveforms, and runs testbench.
# ============================================================================

# 1. Initialize simulation on testbench
vsim -voptargs="+acc" work.spi2axilite_tb

# 2. Add Waveforms
add wave -noupdate -divider -height 32 "SPI HARDWARE INTERFACE"
add wave -noupdate -hex /spi2axilite_tb/clk
add wave -noupdate -hex /spi2axilite_tb/rst_n
add wave -noupdate -hex /spi2axilite_tb/cs_n
add wave -noupdate -hex /spi2axilite_tb/sclk
add wave -noupdate -hex /spi2axilite_tb/mosi
add wave -noupdate -hex /spi2axilite_tb/miso

add wave -noupdate -divider -height 32 "BRIDGE CONTROL FSM"
add wave -noupdate -color {Light Blue} -radix ascii /spi2axilite_tb/dut/u_spi_fsm/state_name
add wave -noupdate -color {Light Blue} -radix decimal /spi2axilite_tb/dut/u_spi_fsm/state
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/done
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/cmd_reg
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/addr_reg
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/data_reg
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/read_data_reg

add wave -noupdate -divider -height 32 "AXI4-LITE WRITE CHANNEL"
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_awaddr
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_awvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_awready
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_wdata
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_wstrb
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_wvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_wready
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_bresp
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_bvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_bready

add wave -noupdate -divider -height 32 "AXI4-LITE READ CHANNEL"
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_araddr
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_arvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_arready
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_rdata
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_rresp
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_rvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_rready

add wave -noupdate -divider -height 32 "AXI MASTER CONTROL FSM"
add wave -noupdate -color Orange -radix ascii /spi2axilite_tb/dut/u_axi_master/axi_state_name
add wave -noupdate -color Orange -radix decimal /spi2axilite_tb/dut/u_axi_master/state

add wave -noupdate -divider -height 32 "AXI REGISTER BANK (SLAVE)"
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_control
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_status
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_data0
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_data1

# 3. Waveform viewer configurations
configure wave -namecolwidth 260
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10

# 4. Run the simulation fully
run -all

# 5. Zoom to fit
wave zoom full

# ============================================================================
# ModelSim Presentation Waveform Script
# File Name: run_presentation.do
# Description: Starts simulation and prepares highly organized, presentation-ready
#              waveforms with custom dividers and explicit hexadecimal radixes.
# ============================================================================

# 1. Initialize simulation on testbench
vsim -voptargs="+acc" work.spi2axilite_tb

# 2. Add Organized Waveforms

# ====================
# SPI SIGNALS
# ====================
add wave -noupdate -divider "===================="
add wave -noupdate -divider "SPI SIGNALS"
add wave -noupdate -divider "===================="
add wave -noupdate -color {Gold} /spi2axilite_tb/clk
add wave -noupdate -color {Orange} /spi2axilite_tb/rst_n
add wave -noupdate -color {Cyan} /spi2axilite_tb/cs_n
add wave -noupdate -color {Cyan} /spi2axilite_tb/sclk
add wave -noupdate -color {Yellow} /spi2axilite_tb/mosi
add wave -noupdate -color {Yellow} /spi2axilite_tb/miso
add wave -noupdate -hex -color {Lime Green} /spi2axilite_tb/rxt_cmd
add wave -noupdate -hex -color {Lime Green} /spi2axilite_tb/rxt_addr
add wave -noupdate -hex -color {Lime Green} /spi2axilite_tb/rxt_data

# ====================
# FSM SIGNALS
# ====================
add wave -noupdate -divider "===================="
add wave -noupdate -divider "FSM SIGNALS"
add wave -noupdate -divider "===================="
add wave -noupdate -color {Light Blue} -radix ascii /spi2axilite_tb/dut/u_spi_fsm/state_name
add wave -noupdate -color {Light Blue} -radix decimal /spi2axilite_tb/dut/u_spi_fsm/state
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/cmd_reg
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/addr_reg
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/data_reg
add wave -noupdate -hex /spi2axilite_tb/dut/u_spi_fsm/read_data_reg

# ====================
# AXI SIGNALS
# ====================
add wave -noupdate -divider "===================="
add wave -noupdate -divider "AXI SIGNALS"
add wave -noupdate -divider "===================="
add wave -noupdate -color {Pink} -radix ascii /spi2axilite_tb/dut/u_axi_master/axi_state_name
add wave -noupdate -color {Pink} -radix decimal /spi2axilite_tb/dut/u_axi_master/state
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_awaddr
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_awvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_awready
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_wdata
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_wvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_wready
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_bvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_bready
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_araddr
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_arvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_arready
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_rdata
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_rvalid
add wave -noupdate -hex /spi2axilite_tb/dut/u_axi_master/m_axi_rready

# ====================
# REGISTER BANK
# ====================
add wave -noupdate -divider "===================="
add wave -noupdate -divider "REGISTER BANK"
add wave -noupdate -divider "===================="
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_control
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_status
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_data0
add wave -noupdate -color Violet -hex /spi2axilite_tb/dut/u_reg_bank/reg_data1

# ====================
# DEBUG SIGNALS
# ====================
add wave -noupdate -divider "===================="
add wave -noupdate -divider "DEBUG SIGNALS"
add wave -noupdate -divider "===================="
add wave -noupdate -color {Dark Gray} -hex /spi2axilite_tb/dut/u_spi_slave/sclk_sync
add wave -noupdate -color {Dark Gray} -hex /spi2axilite_tb/dut/u_spi_slave/cs_n_sync
add wave -noupdate -color {Dark Gray} /spi2axilite_tb/dut/u_spi_slave/sclk_posedge
add wave -noupdate -color {Dark Gray} /spi2axilite_tb/dut/u_spi_slave/sclk_negedge
add wave -noupdate -color {Dark Gray} /spi2axilite_tb/dut/u_spi_slave/cs_n_active
add wave -noupdate -color {Dark Gray} /spi2axilite_tb/dut/u_spi_slave/done
add wave -noupdate -color {Dark Gray} /spi2axilite_tb/dut/u_spi_fsm/tx_load
add wave -noupdate -color {Dark Gray} /spi2axilite_tb/dut/u_spi_fsm/write_req
add wave -noupdate -color {Dark Gray} /spi2axilite_tb/dut/u_spi_fsm/read_req

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

# Architecture Block Diagram

This document presents the high-level structural block diagram of the synthesizable **Write HDL Code for SPI(master) to AXI4-Lite** design.

---

## 1. System Block Diagram

This diagram outlines the sequential hardware translation hierarchy, showing the data path from the external SPI Host (Testbench) to the internal register space.

```mermaid
graph TD
    SPI_TB["<b>SPI MASTER (Testbench)</b> <br> (spi2axilite_tb)"]
    SPI_SL["<b>spi_slave</b> <br> (SPI Shift & Sync Interface)"]
    CMD_DEC["<b>spi_cmd_decoder</b> <br> (Combinatorial Command Decoder)"]
    SPI_FSM["<b>spi_fsm</b> <br> (7-State Bridge Control FSM)"]
    AXI_MST["<b>axi_lite_master</b> <br> (AXI4-Lite Master Interface)"]
    REG_BANK["<b>axi_register_bank</b> <br> (AXI4-Lite Slave Registers)"]

    SPI_TB ==> SPI_SL
    SPI_SL ==> CMD_DEC
    CMD_DEC ==> SPI_FSM
    SPI_FSM ==> AXI_MST
    AXI_MST ==> REG_BANK
```

---

## 2. Hardware Submodules Overview

The entire bridge design is implemented using a modular, clean Verilog architecture. Each block performs a dedicated, specialized hardware role:

### 1. `spi_slave`
The physical interface receiver that samples the serial `mosi` line on the rising edge of `sclk`, shifts in bits, and outputs complete 8-bit parallel bytes. It also synchronizes incoming asynchronous control lines.

### 2. `spi_cmd_decoder`
A combinatorial decoder block that parses the received command byte to detect write (`8'h01`), read (`8'h02`), or invalid operations, outputting immediate command flag indicators.

### 3. `spi_fsm`
The sequential controller containing the 7-state finite state machine. It manages the byte-boundary transitions and coordinates when to trigger the internal AXI transaction.

### 4. `axi_lite_master`
The parallel bus driver that initiates standard AXI4-Lite address and data write/read handshake sequences with the slave storage bank.

### 5. `axi_register_bank`
The standard register storage space mapped inside the SoC, holding the four primary registers (CONTROL, STATUS, DATA0, DATA1) and processing writes/reads over internal bus channels.

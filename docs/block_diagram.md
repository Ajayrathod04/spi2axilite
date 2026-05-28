# Architecture Block Diagram

This document describes the structural block diagram of the **SPI to AXI4-Lite Bridge**. It shows how the top-level module (`spi2axilite`) encapsulates and connects the modular submodules.

## System Architecture

```mermaid
graph TD
    %% Define external ports
    CLK((clk))
    RST_N((rst_n))
    MOSI([mosi])
    MISO([miso])
    SCLK([sclk])
    CS_N([cs_n])

    %% Top Level Block
    subgraph spi2axilite [spi2axilite Top Module]
        
        %% Submodules
        SLAVE[spi_slave]
        DECODER[spi_cmd_decoder]
        FSM[spi_fsm]
        MASTER[axi_lite_master]
        BANK[axi_register_bank]

        %% Interconnects - SPI Slave
        CLK --> SLAVE
        RST_N --> SLAVE
        MOSI --> SLAVE
        SLAVE --> MISO
        SCLK --> SLAVE
        CS_N --> SLAVE

        %% Interconnects - SPI FSM
        CLK --> FSM
        RST_N --> FSM
        CS_N --> FSM
        SLAVE -- done / data_out --> FSM
        SLAVE -- sclk_negedge --> FSM
        FSM -- tx_data / tx_load --> SLAVE

        %% Interconnects - Cmd Decoder
        FSM -- cmd_byte --> DECODER
        DECODER -- write_en / read_en / invalid_cmd --> FSM

        %% Interconnects - AXI Master
        CLK --> MASTER
        RST_N --> MASTER
        FSM -- write_req / write_addr / write_data --> MASTER
        FSM -- read_req / read_addr --> MASTER
        MASTER -- write_done / read_done / read_data_out --> FSM

        %% AXI4-Lite Bus Interconnects
        CLK --> BANK
        RST_N --> BANK
        MASTER -- AXI4-Lite Write Channels <br> awaddr/awvalid/wdata/wvalid/bready --> BANK
        BANK -- AXI4-Lite Write Channels <br> awready/wready/bresp/bvalid --> MASTER
        MASTER -- AXI4-Lite Read Channels <br> araddr/arvalid/rready --> BANK
        BANK -- AXI4-Lite Read Channels <br> arready/rdata/rresp/rvalid --> MASTER

    end

    %% Styles
    style spi2axilite fill:#f9f9f9,stroke:#333,stroke-width:2px;
    style SLAVE fill:#d1e7dd,stroke:#0f5132,stroke-width:1px;
    style DECODER fill:#fff3cd,stroke:#664d03,stroke-width:1px;
    style FSM fill:#cfe2ff,stroke:#084298,stroke-width:1px;
    style MASTER fill:#f8d7da,stroke:#842029,stroke-width:1px;
    style BANK fill:#e2d9f3,stroke:#4527a0,stroke-width:1px;
```

## Submodule Descriptions

### 1. `spi_slave`
Handles physical level SPI byte transfer. It double-synchronizes external lines (`mosi`, `sclk`, `cs_n`) to prevent metastability, counts bit boundaries, shift-stores incoming bytes, and drives the `miso` line on `sclk` falling edges.

### 2. `spi_cmd_decoder`
Decodes the first byte received in a transaction to determine if the operation is a Write (`8'h01`), Read (`8'h02`), or an invalid operation.

### 3. `spi_fsm`
The core state machine. It orchestrates the flow of reading bytes from the SPI physical interface, decoding commands, invoking the AXI master for register access, and setting up read responses.

### 4. `axi_lite_master`
Translates internal read/write request signals into compliant, standard-conforming AXI4-Lite transactions. It utilizes a separate dedicated state machine to prevent deadlocks and ensure correct handshaking.

### 5. `axi_register_bank`
A standard AXI4-Lite slave IP block containing four registers: Control, Status, Data0, and Data1. It reads or writes data based on standard AXI address channels and issues responses.

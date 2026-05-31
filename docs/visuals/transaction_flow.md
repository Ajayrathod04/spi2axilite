# Detailed Signal & Transaction Flow Diagram

This document presents the detailed signal routing connections and operational transaction flows of the SPI to AXI4-Lite Bridge.

---

## 1. Hardware Signal Connection Flow

The block diagram below maps the internal wire connections and physical port mappings between the submodules.

```mermaid
graph TD
    %% Base styling
    classDef default fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000,font-weight:bold,font-size:16px;

    %% Interface Wires
    MOSI["MOSI Line (Input)"]
    MISO["MISO Line (Output)"]
    SCLK["SCLK Line (Input)"]
    CS_N["CS_N Line (Input)"]

    %% Modules
    SLAVE["SPI SLAVE<br>(spi_slave.v)"]
    DECODER["CMD DECODER<br>(spi_cmd_decoder.v)"]
    FSM["SPI FSM<br>(spi_fsm.v)"]
    MASTER["AXI4-Lite MASTER<br>(axi_lite_master.v)"]
    BANK["REGISTER BANK<br>(axi_register_bank.v)"]

    %% SPI Connections
    MOSI ==> SLAVE
    SCLK ==> SLAVE
    CS_N ==> SLAVE
    SLAVE ==> MISO

    %% Slave to FSM
    SLAVE == "spi_rx_byte [7:0]<br>packet_done" ==> FSM
    FSM == "spi_tx_byte [7:0]<br>tx_load" ==> SLAVE

    %% FSM to Decoder
    FSM == "cmd_byte [7:0]" ==> DECODER
    DECODER == "write_en<br>read_en<br>invalid_cmd" ==> FSM

    %% FSM to AXI Master
    FSM == "spi_write_req<br>write_addr [31:0]<br>write_data [31:0]<br>spi_read_req<br>read_addr [31:0]" ==> MASTER
    MASTER == "write_done<br>read_done<br>read_data_out [31:0]" ==> FSM

    %% AXI Master to Register Bank
    MASTER == "awaddr, awvalid, awready<br>wdata, wvalid, wready<br>bresp, bvalid, bready" ==> BANK
    MASTER == "araddr, arvalid, arready<br>rdata, rvalid, rready" ==> BANK
```

---

## 2. SPI Transaction Stage Flow

### 🔴 SPI Write Flow Sequence
This sequence outlines the data path for a write operation, such as writing `8'hAA` to register address `8'h08` (DATA0).

```mermaid
graph LR
    classDef default fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000,font-weight:bold,font-size:16px;

    CMD["CMD (8'h01)"] ==> ADDR["ADDR (8'h08)"] ==> DATA["DATA (8'hAA)"] ==> DEC["FSM Decode"] ==> AXI["AXI Write"] ==> REG["DATA0 Updated"]
```

* **Step 1:** Host shifts `8'h01` (Write command) onto `mosi`.
* **Step 2:** Host shifts `8'h08` (DATA0 register address index) onto `mosi`.
* **Step 3:** Host shifts `8'hAA` (payload byte) onto `mosi`.
* **Step 4:** FSM decodes the write request and captures address and data.
* **Step 5:** Master starts internal AXI Write handshakes on the register bank.
* **Step 6:** AXI register bank registers `32'h000000AA` into DATA0.

---

### 🔵 SPI Read Flow Sequence
This sequence outlines the data path for a read operation, such as reading back register `8'h08` (DATA0).

```mermaid
graph LR
    classDef default fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000,font-weight:bold,font-size:16px;

    CMD["CMD (8'h02)"] ==> ADDR["ADDR (8'h08)"] ==> AXI["AXI Read"] ==> RET["Data Returned"] ==> MISO["MISO Output"]
```

* **Step 1:** Host shifts `8'h02` (Read command) onto `mosi`.
* **Step 2:** Host shifts `8'h08` (DATA0 register address index) onto `mosi`.
* **Step 3:** FSM triggers internal AXI Read on the target register.
* **Step 4:** Register bank drives data `32'h000000AA` onto parallel bus; Master captures it.
* **Step 5:** FSM loads the byte into the SPI transmitter, and the slave serially shifts out `8'hAA` on MISO.

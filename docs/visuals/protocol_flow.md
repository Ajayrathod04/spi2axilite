# Protocol Flow & Sequence Diagrams

This document visualizes the exact sequence of events during **SPI Write** and **SPI Read** transactions, mapping the serial bits to their parallel AXI handshakes.

---

## 1. SPI Write Transaction Sequence (Write `0xAA` to DATA0 `0x08`)

The diagram below shows the chronologically ordered sequence of operations, from the first serial bit shifting in to the final AXI confirmation.

```mermaid
sequenceDiagram
    autonumber
    participant Host as SPI Master (Testbench)
    participant Slave as spi_slave.v
    participant FSM as spi_fsm.v
    participant Master as axi_lite_master.v
    participant Bank as axi_register_bank.v

    Note over Host, Slave: TRANSACTION START (cs_n goes active low)
    Host->>Slave: Shift in CMD Byte (8'h01 = WRITE) via MOSI
    Slave-->>FSM: done = 1, data_out = 8'h01
    FSM->>FSM: cmd_reg <= 8'h01 (Transition to GET_ADDR)

    Host->>Slave: Shift in ADDR Byte (8'h08 = DATA0) via MOSI
    Slave-->>FSM: done = 1, data_out = 8'h08
    FSM->>FSM: addr_reg <= 8'h08 (Transition to GET_DATA)

    Host->>Slave: Shift in DATA Byte (8'hAA) via MOSI
    Slave-->>FSM: done = 1, data_out = 8'hAA
    FSM->>FSM: data_reg <= 8'hAA (Transition to AXI_WRITE)

    Note over FSM, Bank: AXI WRITE HANDSHAKE TRANSLATION
    FSM->>Master: write_req = 1, addr = 32'h08, data = 32'hAA
    Master->>Bank: m_axi_awaddr = 32'h08, m_axi_awvalid = 1
    Master->>Bank: m_axi_wdata = 32'hAA, m_axi_wvalid = 1
    Bank-->>Master: s_axi_awready = 1, s_axi_wready = 1
    Note over Master, Bank: Address & Data Accepted
    Bank->>Bank: reg_data0 <= 32'hAA
    Bank-->>Master: s_axi_bvalid = 1 (Write Response Confirmation)
    Master->>Bank: m_axi_bready = 1
    Master-->>FSM: write_done = 1
    FSM->>FSM: Clear request (Transition to IDLE)
    
    Note over Host, Slave: TRANSACTION END (cs_n goes inactive high)
```

---

## 2. SPI Read Transaction Sequence (Read DATA0 `0x08` returning `0xAA` on MISO)

The diagram below shows the read sequence. Notice how high-speed AXI reads are performed in the middle of the SPI cycle, making data ready for MISO in real-time.

```mermaid
sequenceDiagram
    autonumber
    participant Host as SPI Master (Testbench)
    participant Slave as spi_slave.v
    participant FSM as spi_fsm.v
    participant Master as axi_lite_master.v
    participant Bank as axi_register_bank.v

    Note over Host, Slave: TRANSACTION START (cs_n goes active low)
    Host->>Slave: Shift in CMD Byte (8'h02 = READ) via MOSI
    Slave-->>FSM: done = 1, data_out = 8'h02
    FSM->>FSM: cmd_reg <= 8'h02 (Transition to GET_ADDR)

    Host->>Slave: Shift in ADDR Byte (8'h08 = DATA0) via MOSI
    Slave-->>FSM: done = 1, data_out = 8'h08
    FSM->>FSM: addr_reg <= 8'h08 (Transition to AXI_READ)

    Note over FSM, Bank: INSTANTANEOUS HIGH-SPEED AXI READ
    FSM->>Master: read_req = 1, addr = 32'h08
    Master->>Bank: m_axi_araddr = 32'h08, m_axi_arvalid = 1
    Bank-->>Master: s_axi_arready = 1
    Master->>Bank: m_axi_rready = 1
    Bank-->>Master: s_axi_rvalid = 1, s_axi_rdata = 32'hAA
    Master-->>FSM: read_done = 1, read_data_out = 32'hAA
    FSM->>FSM: read_data_reg <= 8'hAA (Transition to SEND_RESP)

    Note over FSM, Slave: MISO PRELOAD
    FSM->>Slave: tx_load = 1, tx_data = 8'hAA
    Slave->>Slave: tx_shift <= 8'hAA (miso immediately drives MSB '1')

    Note over Host, Slave: SERIAL RESPONSE SHIFTING (Byte 3)
    Host->>Slave: Clock 8 sclk cycles (Host sends dummy 8'h00)
    Slave-->>Host: MISO shifts out 8'hAA (Sampled on sclk rising edges)
    
    Note over Host, Slave: TRANSACTION END (cs_n goes inactive high)
```

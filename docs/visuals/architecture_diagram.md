# Hardware Architecture Block Diagram

This document contains a presentation-ready, high-resolution visual mapping of the **SPI to AXI4-Lite Bridge** hardware architecture. It illustrates signal boundaries, module interfaces, and clock domains.

---

## 1. System Block Diagram

```mermaid
graph TB
    %% Clock Domains and Clusters
    subgraph Testbench [SPI MASTER SIDE — TESTBENCH]
        MASTER[SPI Master Driver <br> <i>Testbench Module</i>]
    end

    subgraph Bridge [SPI TO AXI4-LITE BRIDGE — DUT BOUNDARY]
        
        %% Synchronizers
        subgraph Sync [Asynchronous Input Synchronizers]
            CS_SYNC[2-Stage CS_N Sync]
            CLK_SYNC[2-Stage SCLK Sync]
            MOSI_SYNC[2-Stage MOSI Sync]
        end
        
        %% Submodules
        SLAVE[spi_slave.v <br> <i>Physical Shifter</i>]
        DECODER[spi_cmd_decoder.v <br> <i>Combinatorial Parser</i>]
        FSM[spi_fsm.v <br> <i>Bridge Controller</i>]
        AXI_MST[axi_lite_master.v <br> <i>Bus Master IP</i>]

    end

    subgraph Memory [AXI SLAVE BOUNDARY]
        REG_BANK[axi_register_bank.v <br> <i>AXI Register Bank</i>]
    end

    %% External Interface Lines
    MASTER == cs_n ==> CS_SYNC
    MASTER == sclk ==> CLK_SYNC
    MASTER == mosi ==> MOSI_SYNC
    SLAVE == miso ==> MASTER

    %% Synchronized Internals
    CS_SYNC --> |cs_n_active| SLAVE
    CS_SYNC --> |cs_n_active| FSM
    CLK_SYNC --> |sclk_edges| SLAVE
    CLK_SYNC --> |sclk_negedge| FSM
    MOSI_SYNC --> |mosi_sync| SLAVE

    %% Bridge Internal Data Paths
    SLAVE -- 8-bit done / data_out --> FSM
    FSM -- cmd_byte --> DECODER
    DECODER -- write_en / read_en --> FSM
    DECODER -- invalid_cmd --> FSM
    FSM -- tx_data / tx_load --> SLAVE

    %% FSM to AXI Master control
    FSM == write_req / read_req ==> AXI_MST
    FSM == write_addr / write_data ==> AXI_MST
    FSM == read_addr ==> AXI_MST
    AXI_MST -- write_done / read_done --> FSM
    AXI_MST -- 32-bit read_data_out --> FSM

    %% AXI4-Lite Internal Bus Channels
    AXI_MST == awaddr / awvalid / wdata / wvalid / bready ==> REG_BANK
    REG_BANK -- awready / wready / bvalid / bresp --> AXI_MST
    
    AXI_MST == araddr / arvalid / rready ==> REG_BANK
    REG_BANK -- arready / rdata / rvalid / rresp --> AXI_MST

    %% Styling
    style MASTER fill:#e8f0fe,stroke:#4285f4,stroke-width:2px;
    style CS_SYNC fill:#f1f3f4,stroke:#dadce0,stroke-dasharray: 5, 5;
    style CLK_SYNC fill:#f1f3f4,stroke:#dadce0,stroke-dasharray: 5, 5;
    style MOSI_SYNC fill:#f1f3f4,stroke:#dadce0,stroke-dasharray: 5, 5;
    style SLAVE fill:#e6f4ea,stroke:#34a853,stroke-width:2px;
    style DECODER fill:#fef7e0,stroke:#fbbc05,stroke-width:2px;
    style FSM fill:#e8f0fe,stroke:#1a73e8,stroke-width:2.5px;
    style AXI_MST fill:#fce8e6,stroke:#ea4335,stroke-width:2px;
    style REG_BANK fill:#f3e8fd,stroke:#ab47bc,stroke-width:2px;
    
    classDef domain fill:#ffffff,stroke:#5f6368,stroke-width:1px,stroke-dasharray: 3, 3;
    class Testbench,Bridge,Memory domain;
```

---

## 2. Key Architectural Dividers

### 🟢 SPI Slave (Physical Domain)
- **Metastability Mitigation**: Contains double flip-flop synchronizers for incoming pins.
- **Bit Shifter**: Dynamically counts clock cycles and aggregates 8-bit registers from `mosi`.

### 🟡 Command Decoder (Logic Domain)
- **Zero-Latency parsing**: Evaluates commands combinatorially to determine Write (`8'h01`), Read (`8'h02`), or Error state instantly.

### 🔵 FSM Controller (Orchestrator)
- **Synchronous System Controller**: Handles clock boundaries and triggers sub-buses synchronously to `clk`.

### 🔴 AXI4-Lite Master (Bus Domain)
- **Stateful Bus Generator**: Safely translates single-cycle FSM triggers into fully compliant 5-channel AXI handshake sequences.

### 🟣 Register Bank (Storage Domain)
- **Register Map**: Direct register-mapped address space (`CONTROL`, `STATUS`, `DATA0`, `DATA1`) returning active handshakes.

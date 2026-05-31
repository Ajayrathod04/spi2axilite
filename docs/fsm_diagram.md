# Finite State Machine (FSM) Diagram

This document presents the detailed Finite State Machine (FSM) controller transitions implemented inside `spi_fsm.v`.

---

## 1. FSM State Transition Chart

This state transition diagram uses high-contrast styling with thick borders, bold text, and clean paths to make the controller steps easy to trace.

```mermaid
stateDiagram-v2
    %% Base styling
    classDef default fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000,font-weight:bold,font-size:16px;

    state "IDLE\n(Wait for CS_N low)" as IDLE
    state "GET_CMD\n(Shift in command)" as GET_CMD
    state "GET_ADDR\n(Shift in register index)" as GET_ADDR
    state "GET_DATA\n(Shift in write payload)" as GET_DATA
    state "AXI_WRITE\n(Run AXI write handshakes)" as AXI_WRITE
    state "AXI_READ\n(Run AXI read handshakes)" as AXI_READ
    state "SEND_RESP\n(Shift read byte to MISO)" as SEND_RESP

    [*] --> IDLE : rst_n == 0
    
    IDLE --> GET_CMD : cs_n_active == 1
    
    GET_CMD --> GET_ADDR : done == 1
    GET_CMD --> IDLE : cs_n_active == 0 (Abort)
    
    GET_ADDR --> GET_DATA : done == 1 & write_en == 1
    GET_ADDR --> AXI_READ : done == 1 & read_en == 1
    GET_ADDR --> IDLE : done == 1 & invalid_cmd == 1
    GET_ADDR --> IDLE : cs_n_active == 0 (Abort)
    
    GET_DATA --> AXI_WRITE : done == 1
    GET_DATA --> IDLE : cs_n_active == 0 (Abort)
    
    AXI_WRITE --> IDLE : write_done == 1
    AXI_WRITE --> IDLE : cs_n_active == 0 (Abort)
    
    AXI_READ --> SEND_RESP : read_done == 1
    AXI_READ --> IDLE : cs_n_active == 0 (Abort)
    
    SEND_RESP --> IDLE : cs_n_active == 0 (Done)

    %% Node styling
    style IDLE fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000;
    style GET_CMD fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000;
    style GET_ADDR fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000;
    style GET_DATA fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000;
    style AXI_WRITE fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000;
    style AXI_READ fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000;
    style SEND_RESP fill:#FFFFFF,stroke:#000000,stroke-width:4px,color:#000000;
```

---

## 2. Detailed State Operational Rules

### 1. `IDLE` (3'd0)
* **Description:** The bridge core is waiting for a transaction.
* **Transition:** When `cs_n` is pulled low (detected synchronously via double synchronizers as `cs_n_active == 1`), the FSM immediately transitions to `GET_CMD` to start capturing the first byte.

### 2. `GET_CMD` (3'd1)
* **Description:** The SPI slave is shifting in the first 8-bit command byte.
* **Transition:** Once `done` pulses high (indicating 8 bits have been successfully sampled on `sclk` rising edges), the FSM captures `data_out` into the internal command register `cmd_reg` and transitions to `GET_ADDR`. If `cs_n` goes high, the cycle is aborted and the FSM immediately returns to `IDLE`.

### 3. `GET_ADDR` (3'd2)
* **Description:** The SPI slave is shifting in the second 8-bit byte containing the target register address.
* **Transition:** Once `done` pulses high, the FSM captures `data_out` into `addr_reg` and immediately evaluates the command decoder flags:
  * **Write Command (`8'h01`):** Decoded as `write_en == 1`, transitions to `GET_DATA`.
  * **Read Command (`8'h02`):** Decoded as `read_en == 1`, transitions to `AXI_READ` (skipping get data).
  * **Invalid Command:** Decoded as `invalid_cmd == 1`, transitions immediately back to `IDLE` without triggering any bus transactions.
  * If `cs_n` goes high during this state, the FSM returns to `IDLE`.

### 4. `GET_DATA` (3'd3)
* **Description:** The SPI slave is shifting in the third 8-bit byte containing the write data payload.
* **Transition:** Once `done` pulses high, the FSM captures `data_out` into `data_reg` and transitions to `AXI_WRITE`. If `cs_n` goes high, the FSM returns to `IDLE`.

### 5. `AXI_WRITE` (3'd4)
* **Description:** The FSM asserts `write_req` high to trigger the `axi_lite_master` to execute standard AMBA AXI4-Lite write transactions on the register space.
* **Transition:** The FSM remains in this state until `write_done` pulses high from the AXI master, confirming that both address and data handshakes completed and the write response (`bvalid`/`bready`) was acknowledged. The FSM then returns to `IDLE`. If `cs_n` goes high, the FSM returns to `IDLE`.

### 6. `AXI_READ` (3'd5)
* **Description:** The FSM asserts `read_req` high to trigger the `axi_lite_master` to execute standard AMBA AXI4-Lite read transactions from the register space.
* **Transition:** The FSM remains in this state until `read_done` pulses high from the AXI master, capturing the target register byte in `read_data_reg`. The FSM then transitions to `SEND_RESP`. If `cs_n` goes high, the FSM returns to `IDLE`.

### 7. `SEND_RESP` (3'd6)
* **Description:** The FSM asserts `tx_load` to load the captured read byte into the SPI slave shift register. The SPI slave shifts the byte out onto the `miso` line.
* **Transition:** The FSM remains in this state as the host clocks out the response byte on MISO. The transaction officially terminates when the host deasserts chip select (`cs_n` goes high), resetting the FSM back to `IDLE`.

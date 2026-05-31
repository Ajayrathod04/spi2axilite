# Finite State Machine (FSM) Diagram

This document presents the Finite State Machine (FSM) controller transitions implemented inside `spi_fsm.v`.

---

## FSM State Transition Flowchart

The flowchart below shows all valid transitions and operations of the 7-state controller.

```mermaid
graph TD
    IDLE(["IDLE <br> (Wait for CS_N low)"])
    GET_CMD(["GET_CMD <br> (Shift in 8-bit command)"])
    GET_ADDR(["GET_ADDR <br> (Shift in 8-bit register index)"])
    GET_DATA(["GET_DATA <br> (Shift in 8-bit write payload)"])
    AXI_WRITE(["AXI_WRITE <br> (Run internal AXI write handshakes)"])
    AXI_READ(["AXI_READ <br> (Run internal AXI read handshakes)"])
    SEND_RESP(["SEND_RESP <br> (Shift read register byte to MISO)"])

    IDLE -->|cs_n active low| GET_CMD
    GET_CMD -->|byte done| GET_ADDR
    
    GET_ADDR -->|write opcode| GET_DATA
    GET_ADDR -->|read opcode| AXI_READ
    GET_ADDR -->|invalid opcode| IDLE
    
    GET_DATA -->|byte done| AXI_WRITE
    AXI_WRITE -->|write done| IDLE
    
    AXI_READ -->|read done| SEND_RESP
    SEND_RESP -->|cs_n deasserted high| IDLE
```

---

## State Operational Summary

* **IDLE:** Waits for Chip Select (`cs_n`) to be pulled low by the external master.
* **GET_CMD:** Shifts in the first 8 serial bits on MOSI to capture the instruction byte.
* **GET_ADDR:** Shifts in the second 8 serial bits to capture the target register address. Decodes write or read request.
* **GET_DATA:** Shifts in the third 8 serial bits (write payload).
* **AXI_WRITE:** Initiates parallel `awvalid`/`awready` and `wvalid`/`wready` handshakes to write data to the target register.
* **AXI_READ:** Initiates parallel `arvalid`/`arready` and `rvalid`/`rready` handshakes to read data from the target register.
* **SEND_RESP:** Loads the read data into the SPI shift register, serially driving MISO back to the external master.
* **CS_N Guard:** If `cs_n` goes high in any active state, the FSM instantly resets to **IDLE** in exactly one system clock cycle.

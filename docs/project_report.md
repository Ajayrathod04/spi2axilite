# Technical Project Report

**Project Title:** SPI to AXI4-Lite Bridge using Verilog HDL  
**Course/Evaluation:** SETU by Zoho Electronics Project  
**Author:** FPGA Design Engineer  

---

## 1. Project Overview

Modern System-on-Chip (SoC) architectures commonly use high-speed AMBA buses, such as AXI4, for internal communications, while using low-pin-count serial protocols like SPI for external host communication and chip configuration. 

This project implements a highly structured, synthesizable **SPI to AXI4-Lite Bridge** in Verilog HDL. The bridge functions as an SPI Slave on the external pins and an AXI4-Lite Master on the internal bus, translating serial read/write transactions directly into parallel register-mapped accesses.

---

## 2. Technical Architecture & Modular Design

The design is decomposed into five dedicated modules to ensure clean decoupling, synthesizability, and high readability for beginners.

```
+-------------------------------------------------------------+
|                         spi2axilite                         |
|  (Contains synchronizers, clock edge detectors, and wiring) |
|                                                             |
|   +-------------+       +-------------+       +----------+  |
|   |  spi_slave  | ----> |   spi_fsm   | ----> | axi_lite |  |
|   |   (Shift)   | <---- | (Controller)| <---- |  master  |  |
|   +-------------+       +-------------+       +----------+  |
|                                |                   |        |
|                                v                   v        |
|                         +-------------+       +----------+  |
|                         |   spi_cmd   |       |   axi_   |  |
|                         |   decoder   |       | register |  |
|                         +-------------+       |   bank   |  |
|                                               +----------+  |
+-------------------------------------------------------------+
```

### Module Specifications:
1. **`spi_slave.v`**: Handles bit-level shifting. Features a double-synchronizer to prevent metastability. Flags `done` after 8 rising edges of `sclk`. Drives `miso` on falling edges.
2. **`spi_cmd_decoder.v`**: Simple combinatorial block decoding the command byte (`8'h01` -> WRITE, `8'h02` -> READ).
3. **`spi_fsm.v`**: System controller tracking the 24-bit transaction sequence (`CMD` -> `ADDR` -> `DATA`). Orchestrates the AXI Master state based on the decoded instruction.
4. **`axi_lite_master.v`**: Sequence generator for AXI4-Lite. It manages address/data validity and wait-state ready signals on all five channels synchronously.
5. **`axi_register_bank.v`**: The target AXI4-Lite Slave IP core. It exposes 4 registers: CONTROL (`0x00`), STATUS (`0x04`), DATA0 (`0x08`), and DATA1 (`0x0C`).

---

## 3. SPI Command Packet Structure

A full transaction requires exactly three 8-bit bytes (24 bits) transferred under active-low `cs_n`:

$$\text{Packet} = \text{[CMD (8-bit)]} \rightarrow \text{[ADDR (8-bit)]} \rightarrow \text{[DATA (8-bit)]}$$

### A. SPI Write Flow (e.g. Write `0xAA` to DATA0 `0x08`)
1. **CMD**: Host sends `8'h01`. Decoder identifies a Write.
2. **ADDR**: Host sends `8'h08`. Address register stores `8'h08`.
3. **DATA**: Host sends `8'hAA`. Data register stores `8'hAA`.
4. **AXI Interface**: FSM triggers `write_req`. AXI Master writes `0xAA` to register address `32'h00000008`.

### B. SPI Read Flow (e.g. Read from DATA0 `0x08`)
1. **CMD**: Host sends `8'h02`. Decoder identifies a Read.
2. **ADDR**: Host sends `8'h08`. Address register stores `8'h08`.
3. **AXI Interface**: FSM halts the SPI byte reception, triggers `read_req`, performs a high-speed AXI read, and returns the register contents (`8'hAA`) within a few system clock cycles.
4. **DATA**: Host clocks the 3rd byte. Simultaneously, the bridge preloads the read data into the SPI shift register. The slave shifts out `8'hAA` on MISO.

---

## 4. Verification Results & Testbench Simulation

The design was verified using a comprehensive self-checking testbench (`spi2axilite_tb.v`). Five core test cases were executed to validate protocol correctness and recovery robustness:

### Test Execution Log:
```
==========================================================
   STARTING SPI TO AXI4-LITE BRIDGE SIMULATION TESTBENCH  
==========================================================

--- TEST CASE 1: System Reset ---
[PASS] Reset values of registers are correct.

--- TEST CASE 2: SPI Write to DATA0 (Addr 0x08) ---
[SPI TB] Transmitting CMD: 8'h01
[SPI TB] Transmitting ADDR: 8'h08
[SPI TB] Transmitting DATA: 8'haa
[PASS] DATA0 register successfully written with value 8'hAA.

--- TEST CASE 3: SPI Read from DATA0 (Addr 0x08) ---
[SPI TB] Transmitting CMD: 8'h02
[SPI TB] Transmitting ADDR: 8'h08
[SPI TB] Transmitting DATA: 8'h00
[PASS] SPI Read successfully returned 8'hAA on MISO.

--- TEST CASE 4: Write to CONTROL (Addr 0x00) & Read STATUS (Addr 0x04) ---
[SPI TB] Transmitting CMD: 8'h01
[SPI TB] Transmitting ADDR: 8'h00
[SPI TB] Transmitting DATA: 8'h55
[PASS] CONTROL register successfully written with 8'h55.
[SPI TB] Transmitting CMD: 8'h02
[SPI TB] Transmitting ADDR: 8'h04
[SPI TB] Transmitting DATA: 8'h00
[PASS] SPI Read of STATUS returned 8'h01 (Active).

--- TEST CASE 5: Invalid Command Handling ---
[SPI TB] Transmitting CMD: 8'hff
[SPI TB] Transmitting ADDR: 8'h0c
[SPI TB] Transmitting DATA: 8'h99
[PASS] Invalid command ignored; DATA1 register remains unchanged.

==========================================================
      ALL SIMULATION TEST CASES COMPLETED SUCCESSFULLY    
==========================================================
```

### Key Technical Achievements:
- **ZeroCDC Design**: Sampling asynchronous inputs with double synchronizers and synchronous edge detection eliminated metastable events and multi-clock timing errors.
- **AXI Compliance**: Handshaking signals (`valid`/`ready`) follow standard protocols, confirming the design's synthesizability and porting readiness.
- **ModelSim Portability**: The project features native, complete `.do` files, allowing seamless single-click simulation runs.

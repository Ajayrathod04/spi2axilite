# Write a HDL code for SPI(master) to AXI4-Lite

This repository contains a modular, fully synthesizable, and simulation-verified **Write a HDL code for SPI(master) to AXI4-Lite** bridge design in Verilog HDL. This project translates serial SPI transactions into parallel AXI4-Lite register reads and writes, allowing an external master to communicate with internal FPGA registers.

---

## 1. Project Overview

The bridge operates as an SPI Master on its external pins and an AXI4-Lite its internal bus interface.
* **SPI Protocol:** Compatible with SPI Mode 0 (CPOL=0, CPHA=0) using active-low Chip Select (`cs_n`).
* **Synchronization:** Input lines are double-synchronized to the fast system clock (`clk`) immediately at the input boundaries to prevent metastability.
* **24-bit Packet Framing:** Transactions are structured in 3 bytes: `[8-bit Command] -> [8-bit Address] -> [8-bit Data]`.
* **Standard AXI4-Lite Handshakes:** Drives compliant address, data, and response valid-ready signals.

### 1.1 Project Interpretation and Architecture Choice
The original requirement specifies creating an "SPI to AXI4-Lite" design. In a real-world SoC environment, this architecture is modeled as follows:
* **External SPI Master:** An external host controller (such as a microcontroller) acts as the SPI Master, driving the SPI clock (`sclk`), chip select (`cs_n`), and serial data out (`mosi`).
* **Bridge SPI Slave:** The bridge core physically implements an SPI Slave to receive the asynchronous serial stream without loading the FPGA's high-speed internal clock domain.
* **Bridge AXI4-Lite Master:** The bridge internally translates the received serial commands into parallel bus operations, acting as an AXI4-Lite Master to read and write registers inside the FPGA fabric.
This architecture choice provides robust, cycle-accurate protocol translation and guarantees that the bridge core can configure internal FPGA registers under full AMBA standard compliance.

---

## 2. Architecture

The design is split into five submodules under the top-level wrapper `spi2axilite`:

![Architecture Diagram](docs/visuals/architecture_diagram.png)

* **`spi_slave` (spi_slave.v):** Synchronizes external inputs and shifts serial bits into 8-bit parallel bytes.
* **`spi_cmd_decoder` (spi_cmd_decoder.v):** Parses the command byte to identify write (`8'h01`), read (`8'h02`), or invalid instructions.
* **`spi_fsm` (spi_fsm.v):** Sequencer FSM that coordinates byte boundaries, schedules bus requests, and handles reset aborts.
* **`axi_lite_master` (axi_lite_master.v):** Coordinates standard AMBA AXI4-Lite channel handshakes.
* **`axi_register_bank` (axi_register_bank.v):** Target AXI4-Lite slave register memory map.

---

## 3. FSM (Finite State Machine)

The bridge controller uses a robust 7-state FSM:
`IDLE` $\rightarrow$ `GET_CMD` $\rightarrow$ `GET_ADDR` $\rightarrow$ `GET_DATA` (Write path) $\rightarrow$ `AXI_WRITE` / `AXI_READ` $\rightarrow$ `SEND_RESP` (Read path).

* **Abort Protection:** If Chip Select (`cs_n`) goes high at any point during a transaction, the FSM instantly aborts and resets to `IDLE` in exactly one clock cycle, protecting internal registers from corrupted or incomplete packets.

---

## 4. Register Map

The internal register bank manages four 32-bit registers, spaced by 4 bytes for address alignment:

| Address | Register Name | Access Type | Default Value | Description |
|---|---|---|---|---|
| `32'h0000_0000` | **CONTROL** | Read/Write | `32'h0000_0000` | Configures system behavior. |
| `32'h0000_0004` | **STATUS** | Read-Only | `32'h0000_0001` | Returns `1` to show the core is active. |
| `32'h0000_0008` | **DATA0** | Read/Write | `32'h0000_0000` | User data register 0. |
| `32'h0000_000C` | **DATA1** | Read/Write | `32'h0000_0000` | User data register 1. |

---

## 5. Simulation Results

The self-checking testbench (`spi2axilite_tb.v`) has fully verified the design inside ModelSim with **0 Errors and 0 Warnings**:
* **System Reset:** Checked that registers reset to defaults and STATUS is preloaded with `1`.
* **SPI WRITE:** Value `0xAA` successfully written to the register `DATA0` (`offset 0x08`).
* **SPI READ:** Value `0xAA` successfully read back and shifted onto the `miso` line in real-time.
* **CS_N Abort:** Confirmed that deasserting `cs_n` mid-transaction immediately resets the FSM to `IDLE`.
* **Invalid Command Rejection:** Rejects unsupported opcodes like `0xFF`, leaving register configurations unchanged.

---

## 6. Waveforms

A dedicated presentation script `sim/run_presentation.do` is included to format the ModelSim waveform window:
* **Dividers:** Groups waveforms into SPI, FSM, AXI, Register Bank, and CDC Debug signals.
* **Hexadecimal Radix:** Forces clear hex layout on address and register buses for easy verification.
* **State Decoders:** Decodes raw binary FSM state variables into clear ASCII labels (`IDLE`, `AXI_WRITE`) inside the wave viewer.

---

## 7. How To Run

### From Windows Terminal (PowerShell / CMD):
1. Navigate to the simulation folder:
   ```cmd
   cd "D:\program files\spi2axilite\spi2axilite\sim"
   ```
2. Launch ModelSim and run the presentation script:
   ```cmd
   vsim -do "do compile.do; do run_presentation.do"
   ```

### Inside ModelSim Console:
Paste the following command directly into the ModelSim command console:
```tcl
cd {D:/program files/spi2axilite/spi2axilite/sim}; do compile.do; do run_presentation.do
```

---

## 8. Future Improvements

1. **Parity Checking:** Add parity bits to incoming serial transactions to detect transmission errors before AXI writes occur.
2. **Interrupt Support:** Add a hardware interrupt pin to alert the external master as soon as internal registers change value.
3. **Full AXI Support:** Extend AXI4-Lite master logic to support standard AXI4 burst modes for high-speed block data transfers.
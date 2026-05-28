# SPI to AXI4-Lite Bridge (Verilog HDL)

This repository contains a modular, fully synthesizable, and simulation-verified **SPI to AXI4-Lite Bridge** designed in standard Verilog HDL. This project serves as a comprehensive submission for the **SETU by Zoho Electronics Project** evaluation.

---

## Project Features

- **Standard SPI Slave Interface**: Matches **SPI Mode 0** (CPOL=0, CPHA=0). Double-synchronizes inputs to mitigate metastability.
- **AMBA AXI4-Lite compliance**: Features compliant address, data, and response handshake channels (`valid` and `ready` signals).
- **Decoupled Modular Architecture**: Implemented using cleanly structured submodules rather than an overly complex monolithic design.
- **Flexible 32-bit Register Map**: Supports CONTROL (`0x00`), STATUS (`0x04`), DATA0 (`0x08`), and DATA1 (`0x0C`) registers.
- **ModelSim Ready**: Includes compilation and automated run scripts (`compile.do`, `run.do`) for quick waveform generation.

---

## Directory Structure

```
spi2axilite/
├── rtl/                        # Synthesizable RTL Submodules
│   ├── spi2axilite.v           # Top-level module
│   ├── spi_slave.v             # SPI shift registers and synchronizers
│   ├── spi_cmd_decoder.v       # Decodes write/read commands
│   ├── spi_fsm.v               # Core controller FSM
│   ├── axi_lite_master.v       # Compliant AXI4-Lite Master
│   └── axi_register_bank.v     # AXI4-Lite Slave Register Map
├── tb/                         # Simulation Testbench
│   └── spi2axilite_tb.v        # Self-checking stimulus generator
├── sim/                        # ModelSim Simulation Scripts
│   ├── compile.do              # Clean & Compile design
│   ├── run.do                  # Launch simulation & add waves
│   └── expected_waveform.txt   # Simulation timing reference sheet
├── docs/                       # Technical Documentation
│   ├── block_diagram.md        # Mermaid architecture block diagram
│   ├── fsm_diagram.md          # State machine diagram
│   ├── protocol_notes.md       # Detailed SPI Mode 0 and AXI specs
│   └── project_report.md       # Final technical evaluation report
└── README.md                   # This overview file
```

---

## SPI Command Protocol

The bridge decodes **24-bit packets** driven under active-low chip select (`cs_n`):

$$\text{Packet Format} = \text{[8-bit CMD]} \rightarrow \text{[8-bit ADDR]} \rightarrow \text{[8-bit DATA]}$$

### 1. WRITE Command (`8'h01`)
Writes the 8-bit DATA byte into the AXI address matching `ADDR`.
- **Example**: `01 08 AA`
- **Result**: Writes `8'hAA` into the lower byte of register `DATA0` (`address 32'h00000008`).

### 2. READ Command (`8'h02`)
Reads the contents of the AXI register matching `ADDR` and shifts it out on the `miso` line during the 3rd byte window.
- **Example**: `02 08 00` (last byte is dummy from master)
- **Result**: Reads `DATA0` register and drives `8'hAA` onto `miso`.

---

## Simulation Guide

This project is configured for **ModelSim**. Follow these steps to compile and run:

1. Open **ModelSim**.
2. Change the directory to the `sim/` folder:
   ```tcl
   cd {/your/path/to/spi2axilite/spi2axilite/sim}
   ```
3. Run the compiler:
   ```tcl
   do compile.do
   ```
4. Run the simulation and open waveforms:
   ```tcl
   do run.do
   ```

---

## Verification Waveform Overview

When running the simulation, the wave viewer displays four organized signal groups:
1. **SPI Interface**: Shows `cs_n` asserting, `sclk` toggling, and data shifting sequentially over `mosi` and `miso`.
2. **Bridge Control FSM**: Visualizes transition through states:
   - `IDLE` (0) $\rightarrow$ `GET_CMD` (1) $\rightarrow$ `GET_ADDR` (2) $\rightarrow$ `GET_DATA` (3) $\rightarrow$ `AXI_WRITE` (4) / `AXI_READ` (5) $\rightarrow$ `SEND_RESP` (6).
3. **AXI4-Lite Master**: Tracks valid-ready handshake assertions on address, write, and read lines.
4. **AXI Register Bank (Slave)**: Observes immediate parallel updates of `reg_control`, `reg_status`, `reg_data0`, and `reg_data1`.

For a step-by-step description of signal timing transitions, refer to the [Expected Waveform Reference Sheet](file:///d:/program%20files/spi2axilite/spi2axilite/sim/expected_waveform.txt).
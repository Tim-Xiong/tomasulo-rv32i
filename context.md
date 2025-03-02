# Tomasulo Out-of-Order CPU Design - Context

## Project Overview
This is a SystemVerilog implementation of a Tomasulo-based out-of-order RISC-V processor that implements the RV32I instruction set (excluding FENCE*, ECALL, EBREAK, and CSRR instructions) and a subset of the M extension.

## Key Components

### Pipeline Structure
- **Fetch**: `fetch.sv` - Fetches instructions from memory
- **Decode**: `decode.sv` - Decodes instructions and allocates reservation stations
- **Execute**: Various execution units in `calculation_units/` directory
- **Commit**: `commit.sv` - Commits instructions in-order from the ROB

### Core Microarchitecture
- **Reorder Buffer (ROB)**: `rob.sv` - Ensures in-order commitment
- **Reservation Stations**: `reservation_stations/` - Hold instructions waiting for operands
- **Common Data Bus (CDB)**: `cdb.sv` - Broadcasts results to waiting reservation stations
- **Register File**: `register.sv` - Implements register renaming
- **Branch Predictor**: `bp.sv` - Predicts branch outcomes

### Memory System
- **Cache**: `cache.sv` - Cache implementation
- **Memory Port**: `mem_port.sv` - Interface to memory

## Implementation Notes
- Uses Tomasulo's algorithm for dynamic instruction scheduling
- Implements register renaming to eliminate false dependencies
- Provides precise exceptions through the reorder buffer
- Includes branch prediction for speculative execution

## Directory Structure
- `/hdl`: SystemVerilog implementation files
- `/docs`: Documentation and design specifications
- `/testcode`: Test programs
- `/sim`: Simulation files
- `/hvl`: Hardware verification language files 
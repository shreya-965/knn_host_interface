# KNN SoC Configuration
# Central configuration file for memory layout and build settings

# =============================================================================
# Memory Configuration
# =============================================================================

# Bootrom memory region (read-only code)
BOOTROM_START_ADDR := 0x00000000
BOOTROM_SIZE       := 16384          # 16KB (0x4000 bytes)

# RAM memory region (firmware loads here)
RAM_START_ADDR     := 0x00004000
RAM_SIZE           := 16384          # 16KB (0x4000 bytes)

# =============================================================================
# Firmware Header Configuration
# =============================================================================

FW_MAGIC           := 0xB007B007
FW_LOAD_ADDR       := $(RAM_START_ADDR)

# =============================================================================
# Toolchain Configuration
# =============================================================================

# RISC-V toolchain prefix (can be overridden)
RISCV_PREFIX       ?= $(HOME)/riscv/toolchain/bin/riscv32-unknown-elf

# Architecture and ABI
ARCH               := rv32im
ABI                := ilp32

# =============================================================================
# Build Configuration
# =============================================================================

# Optimization level
OPT_LEVEL          := -Os

# Additional compiler flags
EXTRA_CFLAGS       := -ffreestanding -nostdlib -Wall

# RTL version
RTL_VERSION        := 1.1

# SIM or FPGA (in caps)
RUN_TARGET		   := SIM
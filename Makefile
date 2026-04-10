# Top-level Makefile for KNN SoC
# Builds both bootrom and firmware

# Include project configuration
include config.mk

CC      := $(if $(wildcard $(RISCV_PREFIX)-gcc),$(RISCV_PREFIX)-gcc,riscv32-unknown-elf-gcc)
OBJDUMP := $(patsubst %gcc,%objdump,$(CC))

.PHONY: all bootrom firmware uart-path clean clean-bootrom clean-firmware help config

# Default target builds everything
all: bootrom firmware

# Build bootrom
bootrom: config.mk
	@echo "Building bootrom for RTLv$(RTL_VERSION), $(RUN_TARGET) target..."
	$(MAKE) -C bootrom

# Build firmware
firmware: config.mk
	@echo "Building firmware for $(RUN_TARGET) target..."
	$(MAKE) -C firmware

# UART path: bootrom without flash loading + firmware combined into single binary
uart-path: config.mk
	@echo "Building bootrom for UART path (no flash loading)..."
	$(MAKE) -C bootrom BUILD_MODE=UART_PATH
	@echo "Building firmware (no header)..."
	$(MAKE) -C firmware build/firmware.elf build/firmware.dis build/firmware.bin build/firmware.hex
	@echo "Combining bootrom and firmware into UART binary..."
	python3 scripts/combine_binaries.py \
		-o bootrom/build/uart_combined.bin \
		bootrom/build/bootrom_UART_PATH.bin \
		firmware/build/firmware.bin
	@echo "Generating output formats for combined binary..."
	python3 scripts/makehex.py bootrom/build/uart_combined.bin > bootrom/build/uart_combined.hex
	python3 scripts/bin2dis.py bootrom/build/uart_combined.bin bootrom/build/uart_combined.dis $(OBJDUMP) riscv:rv32
	@echo ""
	@echo "UART path build complete:"
	@echo "  Combined binary: bootrom/build/uart_combined.bin"
	@echo "  Hex format:      bootrom/build/uart_combined.hex"
	@echo "  Disassembly:     bootrom/build/uart_combined.dis"

# Clean everything
clean: clean-bootrom clean-firmware
	@echo "Clean complete"

# Clean bootrom
clean-bootrom:
	@echo "Cleaning bootrom..."
	$(MAKE) -C bootrom clean

# Clean firmware
clean-firmware:
	@echo "Cleaning firmware..."
	$(MAKE) -C firmware clean

# Help target
help:
	@echo "KNN SoC Build System"
	@echo "===================="
	@echo ""
	@echo "Targets:"
	@echo "  all            - Build both bootrom and firmware (default)"
	@echo "  bootrom        - Build bootrom for flash path"
	@echo "  firmware       - Build firmware"
	@echo "  uart-path      - Build combined UART binary (bootrom without flash + firmware)"
	@echo "  clean          - Clean all build artifacts"
	@echo "  clean-bootrom  - Clean bootrom build artifacts"
	@echo "  clean-firmware - Clean firmware build artifacts"
	@echo "  config         - Show current configuration"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "Configuration (edit config.mk to change):"
	@echo "  Bootrom: $(BOOTROM_START_ADDR) - $(shell printf '0x%08X' $$(($(BOOTROM_START_ADDR) + $(BOOTROM_SIZE)))) ($(BOOTROM_SIZE) bytes)"
	@echo "  RAM:     $(RAM_START_ADDR) - $(shell printf '0x%08X' $$(($(RAM_START_ADDR) + $(RAM_SIZE)))) ($(RAM_SIZE) bytes)"
	@echo ""
	@echo "Override examples:"
	@echo "  make BOOTROM_SIZE=8192        - Use 8KB bootrom"
	@echo "  make RAM_SIZE=32768           - Use 32KB RAM"

# Configuration display
config:
	@echo "Current Configuration"
	@echo "====================="
	@echo ""
	@echo "Memory Layout:"
	@echo "  BOOTROM_START_ADDR = $(BOOTROM_START_ADDR)"
	@echo "  BOOTROM_SIZE       = $(BOOTROM_SIZE) bytes ($(shell echo $$(($(BOOTROM_SIZE) / 1024)))KB)"
	@echo "  RAM_START_ADDR     = $(RAM_START_ADDR)"
	@echo "  RAM_SIZE           = $(RAM_SIZE) bytes ($(shell echo $$(($(RAM_SIZE) / 1024)))KB)"
	@echo ""
	@echo "Firmware Header:"
	@echo "  FW_MAGIC           = $(FW_MAGIC)"
	@echo "  FW_LOAD_ADDR       = $(FW_LOAD_ADDR)"
	@echo ""
	@echo "Toolchain:"
	@echo "  RISCV_PREFIX       = $(RISCV_PREFIX)"
	@echo "  ARCH               = $(ARCH)"
	@echo "  ABI                = $(ABI)"
	@echo "  OPT_LEVEL          = $(OPT_LEVEL)"

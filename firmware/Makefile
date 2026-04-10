# Include project configuration
include ../config.mk

CC      := $(if $(wildcard $(RISCV_PREFIX)-gcc),$(RISCV_PREFIX)-gcc,riscv32-unknown-elf-gcc)
OBJDUMP := $(patsubst %gcc,%objdump,$(CC))
OBJCOPY := $(patsubst %gcc,%objcopy,$(CC))

SRC_DIR     := src
BUILD_DIR   := build
SCRIPT_DIR  := ../scripts

CFLAGS  := -Iinclude $(OPT_LEVEL) -march=$(ARCH) -mabi=$(ABI) $(EXTRA_CFLAGS)
LDFLAGS := -T$(BUILD_DIR)/firmware.lds -nostdlib -lgcc

# Linker script preprocessor flags
LD_DEFINES := -DRAM_START_ADDR=$(RAM_START_ADDR) \
              -DRAM_SIZE=$(RAM_SIZE)


CFLAGS += -DTARGET_$(RUN_TARGET)

TARGET_NAME := firmware
TARGET      := $(BUILD_DIR)/$(TARGET_NAME)

C_SRCS   := $(wildcard $(SRC_DIR)/*.c)
ASM_SRCS := $(wildcard $(SRC_DIR)/*.S)

OBJS := \
	$(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS)) \
	$(patsubst $(SRC_DIR)/%.S,$(BUILD_DIR)/%.o,$(ASM_SRCS))

# Default target
all: $(TARGET).elf $(TARGET).dis $(TARGET).bin $(TARGET).hex $(TARGET).coe $(TARGET).mem \
	$(TARGET).memh \
	$(TARGET)_with_header.bin $(TARGET)_with_header.hex $(TARGET)_with_header.coe $(TARGET)_with_header.mem \
	$(TARGET)_with_header.memh

# Ensure build folder exists
$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c ../config.mk | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S ../config.mk | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Preprocess linker script
$(BUILD_DIR)/firmware.lds: firmware.lds ../config.mk | $(BUILD_DIR)
	$(CC) -E -P -x c $(LD_DEFINES) $< -o $@

$(TARGET).elf: $(OBJS) $(BUILD_DIR)/firmware.lds
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

# Output binaries
%.dis: %.elf
	$(OBJDUMP) -d $< > $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.hex: %.bin $(SCRIPT_DIR)/makehex.py
	python3 $(SCRIPT_DIR)/makehex.py $< > $@

%.coe: %.bin $(SCRIPT_DIR)/bin2coe.py
	python3 $(SCRIPT_DIR)/bin2coe.py $< $@

%.mem: %.bin $(SCRIPT_DIR)/bin2mem.py
	python3 $(SCRIPT_DIR)/bin2mem.py $< $@ $(RAM_START_ADDR)

%.memh: %.bin $(SCRIPT_DIR)/bin2memh.py
	python3 $(SCRIPT_DIR)/bin2memh.py $< $@ $(RAM_SIZE) 0xff 16

# Firmware with header
$(TARGET)_with_header.bin: $(TARGET).bin $(SCRIPT_DIR)/append_firmware_header.py
	python3 $(SCRIPT_DIR)/append_firmware_header.py $< $@ $(FW_MAGIC) $(FW_LOAD_ADDR)

$(TARGET)_with_header.hex: $(TARGET)_with_header.bin $(SCRIPT_DIR)/makehex.py
	python3 $(SCRIPT_DIR)/makehex.py $< > $@

$(TARGET)_with_header.coe: $(TARGET)_with_header.bin $(SCRIPT_DIR)/bin2coe.py
	python3 $(SCRIPT_DIR)/bin2coe.py $< $@

$(TARGET)_with_header.mem: $(TARGET)_with_header.bin $(SCRIPT_DIR)/bin2mem.py
	python3 $(SCRIPT_DIR)/bin2mem.py $< $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean

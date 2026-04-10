# RTL 0.1 platform map and protocol constants
.equ SRAM_BASE,            0x00004000
.equ FLASH_IF_BASE,        0x20000000
.equ UART_BASE,            0x20020000
.equ GPIO_BASE,            0x05000000

.equ GPIO_DIR_OFFSET,      0x4
.equ UART_TX_OFFSET,       0x4

.equ SPI_SR_OFFSET,        0x64
.equ SPI_TX_FIFO_OFFSET,   0x68
.equ SPI_RX_FIFO_OFFSET,   0x6C
.equ SPI_SSR_OFFSET,       0x70

.equ TX_EMPTY_MASK,        0x4
.equ RX_NOT_EMPTY_MASK,    0x1
.equ WIP_BIT_MASK,         0x1

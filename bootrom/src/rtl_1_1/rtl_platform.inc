# RTL 1.1 platform map and protocol constants
.equ SRAM_BASE,                 0x06000000
.equ FLASH_IF_BASE,             0x01000000
.equ UART_BASE,                 0x03000000
.equ GPIO_BASE,                 0x05000000
.equ SRAM_CSR_BASE,             0x00200000

.equ UART_RBR_THR_DLL_OFFSET,   0x0
.equ UART_DLM_IER_OFFSET,       0x1
.equ UART_FCR_IIR_OFFSET,       0x2
.equ UART_LCR_OFFSET,           0x3
.equ UART_LSR_OFFSET,           0xC
.equ UART_LSR_THRE_MASK,        0x20

.equ FLASH_INIT_DELAY_LOOPS,    4000

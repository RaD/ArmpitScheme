/*------------------------------------------------------------------------------
@
@  ARMPIT SCHEME Version 060
@
@  ARMPIT SCHEME is distributed under The MIT License.

@  Copyright (c) 2006-2013 Hubert Montas

@ Permission is hereby granted, free of charge, to any person obtaining
@ a copy of this software and associated documentation files (the "Software"),
@ to deal in the Software without restriction, including without limitation
@ the rights to use, copy, modify, merge, publish, distribute, sublicense,
@ and/or sell copies of the Software, and to permit persons to whom the
@ Software is furnished to do so, subject to the following conditions:
@
@ The above copyright notice and this permission notice shall be included
@ in all copies or substantial portions of the Software.
@
@ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
@ OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
@ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
@ THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
@ OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
@ ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
@ OTHER DEALINGS IN THE SOFTWARE.
@
@-----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*\
|										|
|			1. Device Family Constants				|
|										|
|			(followed by device family macros)			|
|										|
\*----------------------------------------------------------------------------*/

@ family
AT91_SAM3U	= 1			@ ATMEL AT91SAM3U family MCU

@ architecture
cortex		= 1
.cpu		cortex-m3

@ writing to on-chip flash (done from RAM, reserve space for flsRAM of initio.s)
EXTRA_FILE_RAM	= 0x60

@ interrupts
num_interrupts	= 32
uart0_int_num	=  8			@ UART
uart1_int_num	=  8			@ UART
timer0_int_num	= 22			@ TC0
timer1_int_num	= 23			@ TC1
i2c0_int_num	= 18			@ TWI0
i2c1_int_num	= 19			@ TWI1
usb_int_num	= 29			@ UDPHS

int_base	= 0xe000e300		@ interrupt status base address
int_statu1	= 0x00			@ for interrupts  0 to 31
@int_statu2	= 0x04			@ for interrupts 32 to 63
int_status	= int_statu1		@ where to find the timer interrupts
int_en_base	= 0xe000e100
int_enabl1	= 0x00
@int_enabl2	= 0x04
int_disab1	= 0x80
@int_disab2	= 0x84

uart0_int	= 1 << uart0_int_num	@ bit  8
uart1_int	= 1 << uart1_int_num	@ bit  8
timer0_int	= 1 << timer0_int_num	@ bit 22
timer1_int	= 1 << timer1_int_num	@ bit 23
i2c0_int	= 1 << i2c0_int_num	@ bit 18
i2c1_int	= 1 << i2c1_int_num	@ bit 19
usb_int		= 1 << usb_int_num	@ bit 29

scheme_ints_en1	= timer0_int|timer1_int|i2c0_int|i2c1_int|uart0_int|uart1_int|usb_int
@scheme_ints_en2	= 0

@ Cortex-M3 SysTick Timer
systick_base	= 0xe000e000
tick_ctrl	= 0x10
tick_load	= 0x14
tick_val	= 0x18

@ mpu
mpu_base	= 0xE000ED90		@ MPU_TYPE register

@ gpio
pioa_base	= 0x400E0C00		@ PIOA_PER  -- PIO Enable Reg
piob_base	= 0x400E0E00		@ PIOB_PER  -- PIO Enable Reg
pioc_base	= 0x400E1000		@ PIOC_PER  -- PIO Enable Reg
io_dir		= 0x10			@ PIOA_OER  -- Output Enable Reg
io_set		= 0x30			@ PIOA_SODR -- Set Output Data Reg
io_clear	= 0x34			@ PIOA_CODR -- Clear Output Data Reg
io_pdsr 	= 0x3C			@ PIOA_PDSR -- Pin Data Status Reg
io_state 	= 0x3C			@ PIOA_PDSR -- Pin Data Status Reg (alt)

@ uarts
uart0_base	= 0x400E0600		@ UART_CR
uart1_base	= 0x400E0600		@ UART_CR
uart_istat	= 0x10			@ offset of UART_IMR
uart_status	= 0x14			@ offset of UART_CSR - uart status reg.
uart_rhr	= 0x18			@ offset to uart rhr register
uart_thr	= 0x1C			@ offset to uart thr register
uart_txrdy	= 0x02			@ bit indicating uart THR empty
uart_pid	= 8			@ UART PID (peripheral ID)

@ timers
timer0_base	= 0x40080000		@ TC0_CCR
timer1_base	= 0x40080040		@ TC1_CCR
timer_istat	= 0x20			@ offset of TC_SR
timer_iset	= 0x24			@ offset of TC_IER
timer_ctrl	= 0x00			@ offset of TC_CCR

@ i2c
i2c0_base	= 0x40084000		@ TWI0_CR
i2c1_base	= 0x40088000		@ TWI1_CR
i2c_ctrl	= 0x00			@ TWI_CR
i2c_mode	= 0x04			@ TWI_MMR
i2c_address	= 0x08			@ TWI_SMR
i2c_status	= 0x20			@ TWI_SR
i2c_ienable	= 0x24			@ TWI_IER
i2c_iclear	= 0x28			@ TWI_IDR
@i2c_cclear	= i2c_iclear	@ needs to be updated
i2c_imask	= 0x2C			@ TWI_IMR
i2c_rhr		= 0x30			@ TWI_RHR
i2c_thr		= 0x34			@ TWI_THR
@TWI_IADR	= i2c0_base + 0x0C	@ R/W
i2c_iadr	= 0x0C			@ TWI_IADR -- internal address bytes
i2c_irm_rcv	= 0x02
i2c_irs_rcv	= 0x02

@ adc
adc0_base	= 0x400AC000

@ pwm
pwm0_base	= 0x4008C000

@ SPI
spi0_base	= 0x40008000
spi_rhr		= 0x08
spi_thr		= 0x0c
spi_status	= 0x10
spi_rxrdy	= 0x01
spi_txrdy	= 0x02

@ usb -- NOT YET IMPLEMENTED (060)

usb_base	= 0x400A4000		@ UDPHS_CTRL

/*
usb_base	= 0x40034000		@ UDP_NUM
usb_glbstate	= 0x04			@ UDP_GLBSTATE -- Global State Reg
usb_faddr	= 0x08			@ UDP_FADDR    -- Function Address Reg
usb_ier		= 0x10			@ UDP_IER      -- Interrupt Enable Reg
usb_istat_dv	= 0x1C			@ UDP_ISR      -- Interrupt Status Reg
usb_istat_ep	= 0x1C			@ UDP_ISR      -- Interrupt Status Reg
usb_iclear_dv	= 0x20			@ UDP_ICR      -- Interrupt Clear  Reg
usb_iclear_ep	= 0x20			@ UDP_ICR      -- Interrupt Clear  Reg
usb_csr0	= 0x30			@ UDP_CSR0    -- EP Control/Status Reg
usb_csr1	= 0x34			@ UDP_CSR1    -- EP Control/Status Reg
usb_csr2	= 0x38			@ UDP_CSR2    -- EP Control/Status Reg
usb_ibulkin	= 0x3C			@ UDP_CSR3 ctrl/stat of EP 3 (Bulk IN)
usb_fdr0	= 0x50			@ UDP_FDR0   -- Endpoint FIFO Data Reg
usb_fdr3	= 0x5C			@ UDP_FDR3   -- Endpoint FIFO Data Reg
usb_iep_mask	= 0x000F		@ mask for enpoint interrupt
usb_idv_mask	= 0xFF00		@ mask for device status interrupt
usb_busreset	= 0x1000		@ bus reset bit
usb_suspend	= 0x0100		@ suspend bit
usb_txrdy	= 0x10			@ Tx ready bit in usb_iBulk_IN
usb_itxendp	= 0x80			@ Tx end of packet interrupt bit
UsbControlOutEP	= 0x00			@ Control OUT Endpoint
UsbControlInEP	= 0x00			@ Control IN  Endpoint (same as ctl out)
UsbBulkOutEP	= 0x02			@ Bulk OUT EP
UsbBulkInEP	= 0x03			@ Bulk IN  EP
usbBulkINDescr	= 0x83			@ Bulk IN is EP 3 (for desc at end file)
usbCO_ibit	= 0x01			@ bit indic int for Control OUT Endpoint
usbCI_ibit	= 0x02			@ bit indic int for Control IN  Endpoint
usbBO_ibit	= 0x04			@ bit indic int for Bulk    OUT Endpoint
usbBI_ibit	= 0x08			@ bit indic int for Bulk    IN  Endpoint
usbCO_setupbit	= 0x04			@ EP stat bit if last tfer was SETUP pkt
*/

@ Other Constants
EEFC_base    	= 0x400E0800		@ EEFC0 Flash Controller
MC_FCR    	= 0x400E0804		@ EEFC0 Flash Command Register
MC_FSR    	= 0x400E0808		@ EEFC0 Flash Status Register
PMC_base	= 0x400E0400		@ PMC   (power management controller)


/*----------------------------------------------------------------------------*\
|										|
|			2. Device Family Macros					|
|										|
\*----------------------------------------------------------------------------*/


.macro	enable_VIC_IRQ
	@ enable interrupts
	swi	run_normal		@ Thread mode, unprivileged, with IRQ
.endm


.macro	enterisr
	@ interrupt service routine entry
	@ on exit:	rvb <- interrupt number (of interrupt to process)
	@ on exit:	sp  <- process stack
	mrs	rvb, psp		@ rvb <- psp stack
	set	sp,  rvb		@ sp  <- psp_stack
	@ *** Workaround for Cortex-M3 errata bug #382859, 
	@ *** Category 2, present in r0p0, fixed in r1p0
	@ *** affects LM3S1968 (needed for multitasking)
	ldr	rvb, [sp, #28]		@ rvb <- saved xPSR
	ldr	rva, =0x0600000c	@ rva <- mask to id int inst as ldm/stm
	tst	rvb, rva		@ was interrupted instruction ldm/stm?
	itT	eq
	biceq	rvb, rvb, #0xf0		@	if so,  rvb <- xPSR to restart
	streq	rvb, [sp, #28]		@	if so,  store xPSR back on stack
	@ *** end of workaround
	ldr	rvc, =0xe000ed00
	ldr	rvb, [rvc, #4]		@ rvb <- interrupt number
	set	rvc, #0xff		@ rvc <- mask
	orr	rvc, rvc, #0x0100	@ rvc <- updated mask
	and	rvb, rvb, rvc		@ rvb <- masked interrupt number
	sub	rvb, rvb, #16		@ rvb <- adjusted interrupt number
.endm


.macro	clearUartInt	
	@ clear interrupt in uart with base address in rva
	ldr	cnt, [rva, #uart_istat]	@ cnt <- int status (clears UART int)
.endm


.macro	clearTimerInt	
	@ clear interrupt in timer peripheral block with base address in rva
	ldr	rvc, [rva, #timer_istat]@ at91sam7
	str	rvc, [rva, #timer_iset]	@ lpc2000
	set	rvc, #0			@ rvc <- 0
	str	rvc, [rva, #timer_iset]	@ str711, STM32
.endm


.macro	clearVicInt	
	@ clear interrupt in interrupt vector (if needed)
	@ nothing to do on cortex-m3
.endm


.macro	exitisr
	@ return from interrupt
	ldr	pc,  =0xfffffffd	@ return to thread mode, process stack
.endm


.macro	isrexit
	@ return from interrupt
	ldr	pc,  =0xfffffffd	@ return to thread mode, process stack
.endm




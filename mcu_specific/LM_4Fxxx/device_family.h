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
LM_4Fxxx	= 1			@ LM4Fxxx family of MCUs

@ architecture
cortex		= 1
.cpu		cortex-m4
.fpu		fpv4-sp-d16

@ type of gpio set/clear
has_combined_set_clear	= 1		@ MCU has combined GPIO SET / CLEAR reg

@ interrupts
num_interrupts	= 139
uart0_int_num	= 5
uart1_int_num	= 6
timer0_int_num	= 19			@ also int 20, not treated
timer1_int_num	= 21			@ also int 22, not treated
i2c0_int_num	= 8
i2c1_int_num	= 37
usb_int_num	= 44			@ USB-0
int_base	= 0xe000e300		@ interrupt status base address
int_statu1	= 0x00			@ ints  0-31 -- TMR0,1,I2C0,UART0,1
int_statu2	= 0x04			@ ints 32-63 -- I2C1
int_status	= int_statu1		@ where to find the timer interrupts
timer0_int	= 0x00180000		@ bit 19-20 = Timer0 on statu1
timer1_int	= 0x00600000		@ bit 21-22 = Timer1 on statu1
i2c0_int	= 0x00000100		@ bit  8 = I2C0 from statu1 (INT 8)
i2c1_int	= 0x20			@ bit  5 = I2C1 from statu2 (INT 37)
uart0_int	= 0x20			@ bit  5 = UART0 from statu1 (INT 5)
uart1_int	= 0x40			@ bit  6 = UART1 from statu1 (INT 6)
usb_int		= 1 << (usb_int_num-32)	@ bit 44 minus 32 (ints_en2/statu2)
int_en_base	= 0xe000e100
int_enabl1	= 0x00
int_enabl2	= 0x04
int_enabl3	= 0x08
int_enabl4	= 0x0C
int_enabl5	= 0x10
int_disab1	= 0x80
int_disab2	= 0x84
int_disab3	= 0x88
int_disab4	= 0x8C
int_disab5	= 0x90
scheme_ints_en1	= timer0_int + timer1_int + i2c0_int + uart0_int + uart1_int
scheme_ints_en2	= i2c1_int | usb_int
scheme_ints_en3	= 0
scheme_ints_en4	= 0
scheme_ints_en5	= 0

@ Cortex-M3 SysTick Timer
systick_base	= 0xe000e000
tick_ctrl	= 0x10
tick_load	= 0x14
tick_val	= 0x18

@ gpio
ioporta_base	= 0x40004000		@ I/O Port A base address -- APB
ioportb_base	= 0x40005000		@ I/O Port B base address -- APB
ioportc_base	= 0x40006000		@ I/O Port C base address -- APB
ioportd_base	= 0x40007000		@ I/O Port D base address -- APB
ioporte_base	= 0x40024000		@ I/O Port E base address -- APB
ioportf_base	= 0x40025000		@ I/O Port F base address -- APB
ioportg_base	= 0x40026000		@ I/O Port G base address -- APB
ioporth_base	= 0x40027000		@ I/O Port H base address -- APB

ioportj_base	= 0x40060000		@ I/O Port J base address -- AHB
ioportk_base	= 0x40061000		@ I/O Port K base address -- AHB
ioportl_base	= 0x40062000		@ I/O Port L base address -- AHB
ioportm_base	= 0x40063000		@ I/O Port M base address -- AHB
ioportn_base	= 0x40064000		@ I/O Port N base address -- AHB
ioportp_base	= 0x40065000		@ I/O Port P base address -- AHB

io_set		= 0x03fc		@ all bits count (read-modify-write mode)
io_clear	= 0x03fc		@ all bits count (read-modify-write mode)
io_state	= 0x03fc		@ all bits count (read-modify-write mode)

@ uarts	
uart0_base	= 0x4000C000		@ UART0
uart1_base	= 0x4000D000		@ UART1
uart_rhr	= 0x00			@ UARTDR
uart_thr	= 0x00			@ UARTDR
uart_status	= 0x18			@ UARTFR
uart_txrdy	= 0x80			@ Tx FIFO Empty
uart_istat	= 0x40			@ UARTMIS <- int may clr in uart too

@ spi
ssi0_base	= 0x40008000
ssi1_base	= 0x40009000
spi_rhr		= 0x08
spi_thr		= 0x08
spi_status	= 0x0c
spi_rxrdy	= 0x04
spi_txrdy	= 0x02

@ adc
adc0_base	= 0x40038000

@ pwm
pwm0_base	= 0x40028000

@ i2c -- NOT DONE !!!	
i2c0_base	= 0x40020000		@ I2C0 Master
i2c1_base	= 0x40021000		@ I2C1 Master
i2c_address	= 0x0800		@ Slave-Own-Address offset from Master
i2c_rhr		= 0
i2c_thr		= 0
i2c_irm_rcv	= 0
i2c_irs_rcv	= 0

@ timers
timer0_base	= 0x40030000		@ TIMER 0
timer1_base	= 0x40031000		@ TIMER 1
timer2_base	= 0x40032000		@ TIMER 2
timer3_base	= 0x40033000		@ TIMER 3
timer_ctrl	= 0x0C			@ GPTMCTL, GPTM Control
timer_istat	= 0x20			@ GPTMMIS, GPTM Masked Interrupt Status
timer_iset	= 0x24			@ GPTMICR, GPTM Interrupt Clear

@ power
sys_base	= 0x400FE000		@ System Control -- RCC base address
rcc_base	= 0x400FE000		@ System Control -- RCC base address
rcc		= 0x60
rcc2		= 0x70
rcgc_base	= rcc_base + 0x0600	@ Peripheral Specific RCGC register base
pr_base		= rcc_base + 0x0a00	@ Peripheral Specific PR   Periph-Ready

@ mpu
mpu_base	= 0xE000ED90		@ MPU_TYPE register

@ flash	
flashcr_base	= 0x400FD000		@ FLASH control registers base

usb_base	= 0x40050000		@ base address
usb_busreset 	= 0x04			@ bit 2 in USBIS
usb_suspend  	= 0x00
usb_ibulkout	= 0x126			@ status of Bulk OUT EP -- USBTXCSRL2
usb_ibulkin	= 0x132			@ status of Bulk IN  EP -- USBTXCSRL3
usb_txrdy	= 1			@ Tx ready bit in usb_iBulk_IN
usb_istat_dv 	= 0x00			@ USBFADDR w/USBTXIS in upper half-word
usb_istat_dv2 	= 0x0a			@ USBIS
usb_idv_mask 	= 0x07
usb_ctl_stat  	= 0x0102		@ USBCSRL0
usb_iep_mask 	= 0x1f
usbCO_ibit	= 0x01			@ 
usbCI_ibit	= 0x02			@ 
usbBO_ibit	= 0x04			@ 
usbBI_ibit	= 0x08			@ 
usbCO_setupbit	= 0x10			@ bit 4 (SETUP_END) in USBCSRL0
usb_daddr 	= 0x00
UsbControlOutEP	= 0			@ 
UsbControlInEP	= 0			@ 
UsbBulkOutEP	= 2			@ 
UsbBulkInEP	= 3			@ 
usbBulkINDescr	= 0x83			@ Bulk IN is EP 3 (for desc at end file)


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
	@ nothing to do on this MCU
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
	@ nothing to do on cortex-m3/m4
.endm

.macro	exitisr
	@ return from interrupt
	ldr	pc,  =0xfffffffd	@ return to thread mode, process stack
.endm

.macro	isrexit
	@ return from interrupt
	ldr	pc,  =0xfffffffd	@ return to thread mode, process stack
.endm

.macro	usbldr dest, src, ofst
	ldrb	\dest, [\src, #\ofst]
.endm

.macro	usbstr dest, src, ofst
	strb	\dest, [\src, #\ofst]
.endm

.macro	usbstrne dest, src, ofst
	strbne	\dest, [\src, #\ofst]
.endm







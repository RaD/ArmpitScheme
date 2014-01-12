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
LPC_17xx	= 1			@ NXP LPC17xx family MCU

@ architecture
cortex		= 1
.cpu		cortex-m3

@ interrupts
num_interrupts	= 64
uart0_int_num	= 5
uart1_int_num	= 6
timer0_int_num	= 1			@ 
timer1_int_num	= 2			@ 
i2c0_int_num	= 10
i2c1_int_num	= 11
usb_int_num	= 24			@ also: 33 = usb activity
int_base	= 0xe000e300		@ interrupt status base address
int_statu1	= 0x00			@ ints  0-31 TMR0/1,I2C0/1,UART0/1,USB
int_statu2	= 0x04			@ ints 32-63
int_status	= int_statu1		@ where to find the timer interrupts
timer0_int	= 1 << timer0_int_num  	@ bit  1 = Timer0 from statu1 (INT  1)
timer1_int	= 1 << timer1_int_num  	@ bit  2 = Timer1 from statu1 (INT  2)
i2c0_int	= 1 << i2c0_int_num    	@ bit 10 =   I2C0 from statu1 (INT 10)
i2c1_int	= 1 << i2c1_int_num	@ bit 11 =   I2C1 from statu1 (INT 11)
uart0_int	= 1 << uart0_int_num	@ bit  5 =  UART0 from statu1 (INT  5)
uart1_int	= 1 << uart1_int_num   	@ bit  6 =  UART1 from statu1 (INT  6)
usb_int		= 1 << usb_int_num   	@ bit 24 =    USB from statu1 (INT 24)
int_en_base	= 0xe000e100
int_enabl1	= 0x00
int_enabl2	= 0x04
int_disab1	= 0x80
int_disab2	= 0x84
scheme_ints_en1	= timer0_int|timer1_int|i2c0_int|i2c1_int|uart0_int|uart1_int|usb_int
scheme_ints_en2	= 0x00

@ Cortex-M3 SysTick Timer
systick_base	= 0xe000e000
tick_ctrl	= 0x10
tick_load	= 0x14
tick_val	= 0x18

@ mpu
mpu_base	= 0xe000ed90		@ MPU_TYPE register

@ gpio
io0_base 	= 0x2009C000 		@ gpio0
io1_base 	= 0x2009C020 		@ gpio1
io2_base 	= 0x2009C040 		@ gpio2
io3_base 	= 0x2009C060 		@ gpio3
io4_base 	= 0x2009C080 		@ gpio4
io_set		= 0x18			@ FIOSET
io_dir		= 0x00			@ FIODIR
io_clear	= 0x1c			@ FIOCLR
io_state	= 0x14			@ FIOPIN

@ pin configuration
PINSEL0		= 0x4002C000		@ pin function select  0, UM10360 p.106
PINSEL1		= 0x4002C004		@ pin function select  1, UM10360 p.106
PINSEL2		= 0x4002C008		@ pin function select  2, UM10360 p.106
PINSEL3		= 0x4002C00C		@ pin function select  3, UM10360 p.106
PINSEL4		= 0x4002C010		@ pin function select  4, UM10360 p.106
PINSEL5		= 0x4002C014		@ pin function select  5, UM10360 p.106
PINSEL6		= 0x4002C018		@ pin function select  6, UM10360 p.106
PINSEL7		= 0x4002C01C		@ pin function select  7, UM10360 p.106
PINSEL8		= 0x4002C020		@ pin function select  8, UM10360 p.106
PINSEL9		= 0x4002C024		@ pin function select  9, UM10360 p.106
PINSEL10       	= 0x4002C028		@ pin function select 10, UM10360 p.106
PINMODE0	= 0x4002C040 		@ pull-up/down/repeater mode bits -- 0
PINMODE1	= 0x4002C044 		@ pull-up/down/repeater mode bits -- 1
PINMODE2	= 0x4002C048 		@ pull-up/down/repeater mode bits -- 2
PINMODE3	= 0x4002C04C 		@ pull-up/down/repeater mode bits -- 3
PINMODE4	= 0x4002C050 		@ pull-up/down/repeater mode bits -- 4
PINMODE5	= 0x4002C054 		@ pull-up/down/repeater mode bits -- 5
PINMODE6	= 0x4002C058 		@ pull-up/down/repeater mode bits -- 6
PINMODE7	= 0x4002C05C		@ pull-up/down/repeater mode bits -- 7
PINMODE8	= 0x4002C060 		@ pull-up/down/repeater mode bits -- 8
PINMODE9	= 0x4002C064 		@ pull-up/down/repeater mode bits -- 9
PINMODE_OD0	= 0x4002C068 		@ open-drain mode bit -- 0
PINMODE_OD1	= 0x4002C06C 		@ open-drain mode bit -- 1
PINMODE_OD2	= 0x4002C070 		@ open-drain mode bit -- 2
PINMODE_OD3	= 0x4002C074 		@ open-drain mode bit -- 3
PINMODE_OD4	= 0x4002C078 		@ open-drain mode bit -- 4

@ uarts	
uart0_base	= 0x4000C000		@ UART0
uart1_base	= 0x40010000		@ UART1
uart_rhr	= 0x00			@ RBR
uart_thr	= 0x00			@ THR
uart_ier	= 0x04			@ IER
uart_istat	= 0x08
uart_status	= 0x14			@ offset to uart status register
uart_txrdy	= 0x20			@ bit indicating uart THR empty

@ i2c -- NOT DONE !!!	
i2c_fastmodplus	= 0x4002C07C  		@ I2C fast mode plus config register
i2c0_base	= 0x4001C000		@ I2C0
i2c1_base	= 0x4005C000		@ I2C1
i2c_cset	= 0x00
i2c_status	= 0x04
i2c_rhr		= 0x08
i2c_thr		= 0x08
i2c_data	= 0x08
i2c_address	= 0x0C
i2c_cclear	= 0x18
i2c_irm_rcv	= 0x50			@ is this ok on cortex? (from LPC2000)
i2c_irs_rcv	= 0x80			@ is this ok on cortex? (from LPC2000)

@ SPI
spi0_base	= 0x40020000		@ SPI0 (legacy SPI)
spi1_base	= 0x40030000		@ SSPI1
spi_rhr		= 0x08
spi_thr		= 0x08
spi_status	= 0x04
spi_rxrdy	= 0x80

@ timers
timer0_base	= 0x40004000		@ TIMER 0
timer1_base	= 0x40008000		@ TIMER 1
timer_istat	= 0x00			@ is this ok on cortex? (from LPC2000)
timer_iset	= 0x00			@ is this ok on cortex? (from LPC2000)
timer_ctrl	= 0x04			@ is this ok on cortex? (from LPC2000)

@ rtc
rtc0_base	= 0x40024000

@ adc
adc0_base	= 0x40034000

@ pwm
pwm1_base	= 0x40018000


@ usb
usb_base	= 0x5000C200	       	@ USB base
usb_istat_dv	= 0x00			@ USBDevIntSt
usb_iclear_dv	= 0x08			@ USBDevIntClr
usb_cmd_code	= 0x10			@ USBCmdCode  -- USB Command Code
usb_cmd_data	= 0x14			@ USBCmdData  -- USB Command Data
usb_rxdata	= 0x18			@ USBRxData   -- USB Receive Data
usb_txdata	= 0x1C			@ USBTxData   -- USB Transmit Data
usb_rxplen	= 0x20			@ USBRxPLen   -- USB Receive  Packet Len
usb_txplen	= 0x24			@ USBTxPLen   -- USB Transmit Packet Len
usb_ctrl	= 0x28			@ USBCtrl     -- USB Control
usb_istat_ep	= 0x30			@ USBEpIntSt
usb_iclear_ep	= 0x38			@ USBEpIntClr
usb_iset_dv	= 0x3c			@ USBEPIntSet
usb_reep	= 0x44			@ USBReEp     -- USB Realize Endpoint
usb_epind	= 0x48			@ USBEpInd    -- USB Endpoint Index
usb_maxpsize	= 0x4C			@ USBMaxPSize -- USB MaxPacketSize
usb_ibulkin	= 0x00			@ Where to find status of Bulk IN EP
usb_iep_mask	= 0x04			@ mask for endpoint interrupt
usb_idv_mask	= 0x08			@ mask for device status interrupt
usb_busreset	= 0x10			@ bus reset bit
usb_suspend	= 0x08			@ suspend bit
usb_txrdy	= 0x80			@ Tx ready bit in usb_iBulk_IN
usb_itxendp	= 0x80			@ Tx end of packet interrupt bit
usb_icd_full	= 0x20	       	      	@ mask in USBDevIntSt for CD_FULL
usb_icc_empty	= 0x10	              	@ mask in USBDevIntSt for CC_EMPTY
UsbControlOutEP	= 0x00			@ Control IN Endpoint (phys 0, log 0)
UsbControlInEP	= 0x80			@ Control IN Endpoint (phys 1, log 0)
UsbBulkOutEP	= 0x02			@ Bulk OUT EP (phys = 4, log = 2)
UsbBulkInEP	= 0x82			@ Bulk IN  EP (phys = 5, log = 2)
usbBulkINDescr	= 0x82			@ Bulk IN is EP 2 (for desc at end file)
usbCO_ibit	= 0x01			@ bit indic int for Control OUT Endpoint
usbCI_ibit	= 0x02			@ bit indic int for Control IN  Endpoint
usbBO_ibit	= 0x10			@ bit indic int for Bulk    OUT Endpoint
usbBI_ibit	= 0x20			@ bit indic int for Bulk    IN  Endpoint
usbCO_setupbit	= 0x04			@ EP stat bit indic last tfer was SETUP
USBIntSt	= 0x400FC1C0		@ USB Device Int Stat R/W 0x8000 0000

@ power
sys_ctrl       	= 0x400FC000		@ SCS base
PLOCK_bit	= 0x04000000		@ bit 26 = PLL LOCK bit in PLLSTAT

@ flash
IAP_ENTRY	= 0x1FFF1FF1		@ IAP routine entry point in boot sector


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
	ldr	cnt, [rva, #uart_istat]	@ cnt <- interrupt status (clears UART)
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






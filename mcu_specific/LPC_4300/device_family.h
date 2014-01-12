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
LPC_4300	= 1			@ NXP LPC4300 family MCU

@ architecture
cortex		= 1
.cpu		cortex-m4
.fpu		fpv4-sp-d16

@ interrupts
num_interrupts	= 53
uart0_int_num	= 24
uart1_int_num	= 25
timer0_int_num	= 12			@ 
timer1_int_num	= 13			@ 
i2c0_int_num	= 18
i2c1_int_num	= 19
usb_int_num	=  8			@ USB-0
int_base	= 0xe000e300		@ interrupt status base address
int_statu1	= 0x00			@ for interrupts  0 to 31
int_statu2	= 0x04			@ for interrupts 32 to 63
int_status	= int_statu1		@ where to find the timer interrupts
timer0_int	= 1 << timer0_int_num  	@ bit
timer1_int	= 1 << timer1_int_num  	@ bit
i2c0_int	= 1 << i2c0_int_num    	@ bit
i2c1_int	= 1 << i2c1_int_num	@ bit
uart0_int	= 1 << uart0_int_num	@ bit
uart1_int	= 1 << uart1_int_num   	@ bit
usb_int		= 1 << usb_int_num   	@ bit
int_en_base	= 0xe000e100
int_enabl1	= 0x00
int_enabl2	= 0x04
int_disab1	= 0x80
int_disab2	= 0x84
scheme_ints_en1	= timer0_int | timer1_int | i2c0_int | i2c1_int | uart0_int | uart1_int | usb_int
scheme_ints_en2	= 0x00

@ Cortex-M3 SysTick Timer
systick_base	= 0xe000e000
tick_ctrl	= 0x10
tick_load	= 0x14
tick_val	= 0x18

@ mpu
mpu_base	= 0xe000ed90		@ MPU_TYPE register

@ gpio
io0_base 	= 0x400F6000 		@ gpio0 dir
io1_base 	= 0x400F6004 		@ gpio1 dir
io2_base 	= 0x400F6008 		@ gpio2 dir
io3_base 	= 0x400F600C 		@ gpio3 dir
io4_base 	= 0x400F6010 		@ gpio4 dir
io5_base 	= 0x400F6014 		@ gpio5 dir
io6_base 	= 0x400F6018 		@ gpio6 dir
io7_base 	= 0x400F601C 		@ gpio7 dir
io_set		= 0x0200		@ SET
io_dir		= 0x0000		@ DIR
io_clear	= 0x0280		@ CLR
io_state	= 0x0100		@ PIN -- read state of INPUT  pin
@io_state	= 0x0200		@ SET -- use this to read state of OUTPUT pin (without input buffer?)
io_toggle	= 0x0300		@ NOT

@ pin configuration
SCU_SFSP0_n	= 0x40086000		@ SFSP0_0 to SFSP0_1  base address
SCU_SFSP1_n	= 0x40086080		@ SFSP1_0 to SFSP1_20 base address
SCU_SFSP2_n	= 0x40086100		@ SFSP2_0 to SFSP2_13 base address
SCU_SFSP3_n	= 0x40086180		@ SFSP3_0 to SFSP3_8  base address
SCU_SFSP4_n	= 0x40086200		@ SFSP4_0 to SFSP4_10 base address
SCU_SFSP5_n	= 0x40086280		@ SFSP5_0 to SFSP5_7  base address
SCU_SFSP6_n	= 0x40086300		@ SFSP6_0 to SFSP6_12 base address
SCU_SFSP7_n	= 0x40086380		@ SFSP7_0 to SFSP7_7  base address
SCU_SFSP8_n	= 0x40086400		@ SFSP8_0 to SFSP8_8  base address
SCU_SFSP9_n	= 0x40086480		@ SFSP9_0 to SFSP9_6  base address
SCU_SFSPA_n	= 0x40086500		@ SFSPA_0 to SFSPA_4  base address
SCU_SFSPB_n	= 0x40086580		@ SFSPB_0 to SFSPB_6  base address
SCU_SFSPC_n	= 0x40086600		@ SFSPC_0 to SFSPC_14 base address
SCU_SFSPD_n	= 0x40086680		@ SFSPD_0 to SFSPD_16 base address
SCU_SFSPE_n	= 0x40086700		@ SFSPE_0 to SFSPE_15 base address
SCU_SFSPF_n	= 0x40086780		@ SFSPF_0 to SFSPF_11 base address
SCU_SFSCLKn	= 0x40086C00		@ SFSCLK0 to SFSCLK3  base address

@ uarts	
uart0_base	= 0x40081000		@ UART0
uart1_base	= 0x40082000		@ UART1
uart_rhr	= 0x00			@ RBR
uart_thr	= 0x00			@ THR
uart_ier	= 0x04			@ IER
uart_istat	= 0x08
uart_status	= 0x14			@ offset to uart status register
uart_txrdy	= 0x20			@ bit indicating uart THR empty

@ i2c -- NOT YET IMPLEMENTED!!!	
i2c0_base	= 0x400A1000		@ I2C0
i2c1_base	= 0x400E0000		@ I2C1
i2c_cset	= 0x00
i2c_status	= 0x04
i2c_rhr		= 0x08
i2c_thr		= 0x08
i2c_data	= 0x08
i2c_address	= 0x0C
i2c_cclear	= 0x18
i2c_irm_rcv	= 0x50			@ ok on cortex? (this is from LPC2000)
i2c_irs_rcv	= 0x80			@ ok on cortex? (this is from LPC2000)

@ SPIFI
spifi_base	= 0x40003000		@ SPIFI (Ch.16, 18 May 2011 User Manual)
spifi_ctrl	= 0x00			@ SPIFICTRL
spifi_cmd	= 0x04			@ SPIFICMD
spifi_addr	= 0x08			@ SPIFIADDR
spifi_idat	= 0x0c			@ SPIFIDATINTM
spifi_adid	= 0x10			@ SPIFIADDRINTM
spifi_dat	= 0x14			@ SPIFIDAT
spifi_mcmd	= 0x18			@ SPIFIMEMCMD
spifi_stat	= 0x1c			@ SPIFISTAT

@ SPI
spi0_base	= 0x40100000		@ SPI0 (legacy SPI)
spi1_base	= spi0_base		@ aliased
spi_cr		= 0x00
spi_ccr		= 0x10
spi_rhr		= 0x08
spi_thr		= 0x08
spi_status	= 0x04
spi_rxrdy	= 0x80
spi_cs_gpio	= io5_base
spi_cs_pin	= 1 << 11

@ timers
timer0_base	= 0x40084000		@ TIMER 0
timer1_base	= 0x40085000		@ TIMER 1
timer_istat	= 0x00			@ ok on cortex? (this is from LPC2000)
timer_iset	= 0x00			@ ok on cortex? (this is from LPC2000)
timer_ctrl	= 0x04			@ ok on cortex? (this is from LPC2000)

@ SD/MMC
mmc_base	= 0x40004000
mmc_arg		= 0x28
mmc_cmd		= 0x2c

@ rtc
rtc0_base	= 0x40046000

@ adc
adc0_base	= 0x400E3000
adc1_base	= 0x400E4000

@ pwm
pwm1_base	= 0x400A0000

@ usb
usb_base	= 0x40006100		@ USB-0 base
@has_HS_USB	= 1			@ <- KEEP COMMENTED (HS not functional)
USB_FSHS_MODE   = usb_queue_heads+0x38	@ where to store HS/FS state
					@ (in-between 64-byte-aligned 48-byte queue heads)
usb_istat_dv	= 0x44			@ USBDevIntSt
usb_iep_mask	= 0x01			@ mask for endpoint interrupt
usb_iclear_dv	= usb_istat_dv		@ USBDevIntClr
usb_idv_mask	= (1 << 6)		@ mask for device status interrupt
usb_busreset	= (1 << 6)		@ bus reset bit
usb_itxendp	= 0			@ Tx end of packet interrupt bit
usb_suspend	= 0			@ suspend bit
usb_istat_ep	= 0xbc			@ USBEpIntSt
usb_iclear_ep	= usb_istat_ep		@ USBEpIntClr
usbCO_ibit	= (1 <<  0)		@ bit indic int for Control OUT Endpoint
usbCI_ibit	= (1 << 16)		@ bit indic int for Control IN  Endpoint
usbBO_ibit	= (1 <<  2)		@ bit indic int for Bulk    OUT Endpoint
usbBI_ibit	= (1 << 18)		@ bit indic int for Bulk    IN  Endpoint
usbBulkINDescr	= 0x82			@ Bulk IN is EP 2 (for desc at end file)
usbCO_setupbit	= (1 << 0)		@ EP stat bit indic last tfer was SETUP
UsbControlOutEP	= 0x00			@ Control IN Endpoint (phys 0, log 0)
UsbControlInEP	= 0x01			@ Control IN Endpoint (phys 1, log 0)
UsbBulkOutEP	= 0x04			@ Bulk OUT EP (phys = 4, log = 2)
UsbBulkInEP	= 0x05			@ Bulk IN  EP (phys = 5, log = 2)
usb_ibulkin	= 0xb8			@ to find status of Bulk IN EP (primed?)
usb_txrdy	= (1 << 18)		@ Tx rdy bit in Bulk_IN (EP Tx primed)

@ system
sys_config	= 0x40043000		@ CREG (M4-M0 mem remap, ETB RAM cfg,..)

@ clocks
CGU_base	= 0x40050000


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







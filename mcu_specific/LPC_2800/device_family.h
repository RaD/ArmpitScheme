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
LPC_2800	= 1			@ NXP LPC2880 family MCU
include_startup = 1			@ device startup in startup.s file

@ architecture
.cpu		arm7tdmi

@ code addresses
_boot_section_address_	= 0x10400000	@ where startup code will run from
_text_section_address_	= _boot_section_address_ + 0x0400 @ cod strt for cpy2RAM

@ interrupts
irq_direct_branch	= 1		@ branch to genisr diectly on int
num_interrupts	= 32	
uart0_int_num	= 12
uart1_int_num	= 12
timer0_int_num	= 5
timer1_int_num	= 6
i2c0_int_num	= 13
i2c1_int_num	= 13
int_base	= 0x80300000		@ INT_PRIOMASK0
int_status	= 0x0200		@ INT_PENDING
int_clear_vals	= 0x010000		@ base address of IRQ IVT 64kb in SDRAM
int_clear	= 0x0100		@ INT_VECTOR0
uart0_int	= 0x1000		@ bit 12
uart1_int	= 0x0000		@ NA
timer0_int	= 0x0020		@ bit 5
timer1_int	= 0x0040		@ bit 6
i2c0_int	= 0x2000		@ bit 13
i2c1_int	= 0x0000		@ NA
scheme_ints_enb	= timer0_int + timer1_int + i2c0_int + i2c1_int
int_enable	= 0x00			@ offset to nothing (unused?)
int_disable	= 0x00			@ offset to nothing (unused)

@ gpio
io0_base	= 0x80003000		@ PINS_0
io1_base	= 0x80003040		@ PINS_1
io2_base	= 0x80003080		@ PINS_2
io3_base	= 0x800030c0		@ PINS_3
io4_base	= 0x80003100		@ PINS_4
io5_base	= 0x80003140		@ PINS_5
io6_base	= 0x80003180		@ PINS_6
io7_base	= 0x800031c0		@ PINS_7
io_set		= 0x14			@ Mode0S_n
io_clear	= 0x18			@ Mode0C_n
io_state	= 0x00			@ PINS_n

@ uarts
uart0_base	= 0x80101000
uart1_base	= 0x80101000
uart_thr	= 0x00
uart_rhr	= 0x00
uart_ier	= 0x04			@ IER
uart_istat	= 0x08			@ IIR
uart_status	= 0x14			@ LSR
uart_txrdy	= 0x20			@ bit 5 of LSR == THRE (empty THR)	

@ rtc
rtc0_base	= 0X80002000		@ rtc

@ mci
mci_base	= 0X80100000		@ mci

@ lcd
lcd_base	= 0X80103000		@ lcd

@ adc
adc0_base	= 0X80002400		@ adc

@ dma
gdma_base	= 0X80103800

@ timers
timer0_base	= 0X80020000		@ T0Load
timer1_base	= 0X80020400		@ T1Load
timer_istat	= 0x0C			@ TnClear
timer_iset	= 0x0C			@ TnClear
timer_ctrl	= 0x08			@ TnControl

@ i2c  -- NOT COMPLETE
i2c0_base	= 0x80020800		@ I2RX/I2TX
i2c1_base	= i2c0_base
i2c_rhr		= 0x00
i2c_thr		= 0x00
i2c_data	= 0x00
i2c_address	= 0x14			@ offset to I2ADR
i2c_status	= 0x04
i2c_cset	= 0x00
i2c_cclear	= 0x18
i2c_irm_rcv	= 0x50
i2c_irs_rcv	= 0x80

@ usb
has_HS_USB      = 1			@ controller supports High-Speed op
USB_FSHS_MODE   = 0x80041078            @ USBScratch stor HS/FS stat 16 low bits
usb_clken	= 0x80005050		@ USBClckEN
usb_base	= 0x80041000		@ USBDevAdr
usb_dev_adr	= 0x00			@ USBDevAdr
usb_istat_dv	= 0x94			@ USBIntStat
usb_iclear_dv	= 0xAC			@ USBIntClr
usb_istat_ep	= 0x98			@ USBEIntStat
usb_iclear_ep	= 0xA0			@ USBEIntClr
usb_iset_ep	= 0xA4			@ USBEIntSet
usb_iep_mask	= 0x80			@ mask for endpoint interrupt EP0SETUP
usb_busreset	= 0x01			@ bus reset bit
usb_suspend	= 0x38			@ suspend/resume, change to HS bits
usb_idv_mask	= 0x39			@ mask for device status interrupt
usb_maxpsize	= 0x04			@ USBMaxPSize -- USB MaxPacketSize
usb_txplen	= 0x1C			@ USBDCnt     -- USB Transmit Packet Len
usb_rxplen	= 0x1C			@ USBDCnt     -- USB Receive Packet Len
usb_rxdata	= 0x20			@ USBData     -- USB Receive Data
usb_txdata	= 0x20			@ USBData     -- USB Transmit Data
usbCO_ibit	= 0x01			@ bit indic int for Control OUT Endpoint
usbCI_ibit	= 0x02			@ bit indic int for Control IN  Endpoint
usbBO_ibit	= 0x10			@ bit indic int for Bulk    OUT Endpoint
usbBI_ibit	= 0x20			@ bit indic int for Bulk    IN  Endpoint
usb_epind	= 0x2C			@ USBEIDX    -- USB Endpoint Index
usb_reep	= 0x08			@ USBEType   -- USB Realize EP / EP type
UsbControlOutEP	= 0x00			@ Control OUT Endpoint (phys 0, log 0)
UsbControlInEP	= 0x01			@ Control IN Endpoint (phys 1, log 0)
UsbBulkOutEP	= 0x04			@ Bulk OUT EP (phys = 4, log = 2)
UsbBulkInEP	= 0x05			@ Bulk IN  EP (phys = 5, log = 2)
usbBulkINDescr	= 0x82			@ Bulk IN is EP 2 (for desc at end file)
usb_itxendp	= 0x00			@ Tx end pckt int bit - not used on this
@usbCO_setupbit	= 0x00			@ EP stat bit last tfer = SETUP-not used
usbCO_setupbit	= 0x01			@ EP stat bit last tfer = SETUP-dummy
usb_ctrl	= 0x28			@ USBECtrl    -- USB Endpoint Control
usb_txrdy	= 0x20			@ Tx ready bit in usb_iBulk_IN

@ system control -- few power offsets, eg. USBClkEN (see above)
sys_ctrl	= 0x80005000


/*----------------------------------------------------------------------------*\
|										|
|			2. Device Family Macros					|
|										|
\*----------------------------------------------------------------------------*/


.macro	enable_VIC_IRQ
	@ enable interrupts
	ldr	rva, =0x80300400	@ rva <- Int Request Regs base address
	ldr	rvb, =0x1C010001	@ rvb <- interrupt enable
	str	rvb, [rva, #0x14]	@ INT_REQ5  <- Timer 0 zero cnt int enab
	str	rvb, [rva, #0x18]	@ INT_REQ6  <- Timer 1 zero cnt int enab
	str	rvb, [rva, #0x34]	@ INT_REQ13 <- I2C int enabled as IRQ
.endm

.macro	enterisr
	@ interrupt service routine entry
	@ on exit:	rvb <- interrupt number (of interrupt to process)
	@ on exit:	sp  <- fre, cnt, rva, rvb, rvc, lnk_usr, pc_usr, spsr
	sub	lnk, lnk, #4		@ Adjust lnk to point to return 
	stmdb	sp!, {lnk}		@ store lnk_irq (pc_usr) on irq stack
	mrs	lnk, spsr		@ lnk  <- spsr
	tst	lnk, #IRQ_disable	@ were interrupts disabled?
	ldmiane	sp!, {pc}^		@ If so, just return immediately
	@ save some registers on stack
	stmib	sp,  {lnk}		@ store spsr on irq stack (above pc_usr)
	stmdb	sp,  {fre, cnt, rva, rvb, rvc, lnk}^ @ 5 regs+lnk_usr on stack
	sub	sp,  sp, #24		@ sp  <- adj stack ptr (next free cell)
	ldr	rvb, =int_base		@ rvb <- address of VIC IRQ Status reg
	@ LPC-2800
	ldr	rvc, [rvb]		@ rvc <- [int_priomask0]
	ldr	rvc, [rvb, #0x0100]	@ rvc <- [int_vector0]
	ldr	rvb, [rvb, #int_status]	@ rvb <- asserted interrupts
	lsr	rvb, rvc, #3		@ rvb <- interrupt number + address bits
	and	rvb, rvb, #0x1f		@ rvb <- interrupt number
.endm

	
.macro	clearUartInt
	@ clear interrupt in uart with base address in rva
	ldr	cnt, [rva, #uart_istat]	@ cnt <- interrupt status (clears UART)
.endm

.macro	clearTimerInt
	@ clear interrupt in timer peripheral block with base address in rva
	set	rvc, #0			@ rvc <- 0
	str	rvc, [rva, #timer_ctrl]	@ stop the timer
	str	rvc, [rva]		@ clear the load value
	str	rvc, [rva, #timer_iset]	@ clear the interrupt
.endm

.macro	clearVicInt
	@ clear interrupt in interrupt vector (if needed)
	@ modifies:	rva, rvc
	ldr	rva, =int_base		@ 
	ldr	rvc, =int_clear_vals
	str	rvc, [rva, #int_clear]	@ clear interrupt
.endm
	
.macro	exitisr
	@ exitisr for non-cortex
	ldr	rvc, [sp,  #28]
	msr	spsr_cxsf, rvc		@ restore spsr
	ldmia	sp, {fre, cnt, rva, rvb, rvc, lnk}^	@ Restore registers
	add	sp, sp, #24
	ldmia	sp!, {lnk}
	movs	pc,  lnk		@ Return
.endm

.macro	isrexit
	@ second version - different from exitisr for STR7 and AT91SAM7 only
	exitisr
.endm





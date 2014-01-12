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
LPC_2000	= 1			@ NXP LPC2000 family MCU

@ architecture
.cpu		arm7tdmi

@ stack size
stack_size	= 288			@ stack space needed by IAP on LPC-2000

@ interrupts
irq_direct_branch	= 1		@ branch to genisr diectly on interrupt
num_interrupts	= 32
uart0_int_num	= 6
uart1_int_num	= 7
timer0_int_num	= 4
timer1_int_num	= 5
i2c0_int_num	= 9
i2c1_int_num	= 19
usb_int_num     = 22
.ifndef LPC2478_STK
  int_voffset	= -0x0FF0		@ offset to VicVectAddress
  int_clear	= 0x30			@ offset to VICVectAddress
.else
  int_voffset	= -0x0120		@ offset to VicAddress
  int_clear	= 0x0F00		@ offset to VicAddress
.endif
int_base	= 0xFFFFF000		@ VICIRQStatus
int_status	= 0x00			@ offset to VICIRQStatus
int_enable	= 0x10			@ offset to VicIntEnable
int_disable	= 0x14			@ offset to VicIntEnClear
int_clear_vals	= 0x00
uart0_int	= 1 << uart0_int_num	@ bit  6
uart1_int	= 1 << uart1_int_num	@ bit  7
timer0_int	= 1 << timer0_int_num	@ bit  4
timer1_int	= 1 << timer1_int_num	@ bit  5
i2c0_int	= 1 << i2c0_int_num	@ bit  9
i2c1_int	= 1 << i2c1_int_num	@ bit 19
usb_int		= 1 << usb_int_num	@ bit 22
scheme_ints_enb	= timer0_int|timer1_int|i2c0_int|i2c1_int|uart0_int|uart1_int|usb_int

@ pin connect block -- A/VPB Peripheral #11
PINSEL0        	= 0xE002C000
PINSEL1		= 0xE002C004		@
.ifndef LPC2478_STK
  PINSEL2	= 0xE002C014		@ LPC 213X LEDs
.else
  PINSEL2	= 0xE002C008		@ LPC 2478
.endif
PINSEL3		= 0xE002C00C		@ LPC 2478

@ gpio -- A/VPB Peripheral #10
io0_base	= 0xE0028000		@ IO0PIN
io1_base	= 0xE0028010		@ IO1PIN
io_set		= 0x04
io_dir		= 0x08
io_clear	= 0x0C
io_state	= 0x00

@ uarts -- A/VPB Peripheral #3
uart0_base	= 0xE000C000		@ U0RBR
uart1_base	= 0xE0010000		@ U1RBR
uart_rhr	= 0x00			@ offset to uart rhr register
uart_thr	= 0x00			@ offset to uart thr register
uart_ier	= 0x04			@ IER
uart_istat	= 0x08
uart_status	= 0x14			@ offset to uart status register
uart_txrdy	= 0x20			@ bit indicating uart THR empty

@ spi
spi0_base	= 0xE0020000
spi1_base	= 0xE0068000
spi_rhr		= 0x08
spi_thr		= 0x08
spi_status	= 0x04
spi_rxrdy	= 0x80

@ pwm
pwm0_base	= 0xE0014000
.ifdef LPC2478_STK
pwm1_base	= 0xE0018000
.endif

@ rtc
rtc0_base	= 0xE0024000

@ adc
adc0_base	= 0xE0034000
.ifndef LPC2478_STK
adc1_base	= 0xE0060000
.endif

@ mci, gpdma
.ifdef LPC2478_STK
pmod0_base	= 0xE002c040  		@ pinmod0
mci_base	= 0xE008c000
gdma_base	= 0xffe04000  		@ GPDMA peripheral
bdma_base	= 0x7fd00000  		@ dma 512 byte buffer adddress
.endif

@ timers
timer0_base	= 0XE0004000		@ T0IR
timer1_base	= 0XE0008000		@ T1IR
timer_istat	= 0x00
timer_iset	= 0x00
timer_ctrl	= 0x04

@ i2c -- A/VPB Peripheral #7
i2c0_base	= 0xE001C000		@ I2C0CONSET
i2c1_base	= 0xE005C000		@ I2C1CONSET
i2c_cset	= 0x00
i2c_status	= 0x04
i2c_rhr		= 0x08
i2c_thr		= 0x08
i2c_data	= 0x08
i2c_address	= 0x0C
i2c_cclear	= 0x18
i2c_irm_rcv	= 0x50
i2c_irs_rcv	= 0x80

@ usb -- A/VPB Peripheral #36 (LPC 214x, 215x)
.ifndef LPC2478_STK
  usb_base	= 0xE0090000		@ USBDevIntSt
.else
  usb_base	= 0xFFE0C200		@ USBDevIntSt
.endif
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
USBIntSt	= 0xE01FC1C0		@ USB Dev Interrupt Stat R/W 0x80000000

@ System Control -- Peripheral #127
sys_ctrl	= 0xE01FC000
.ifndef LPC2478_STK
  PLOCK_bit	= 0x0400		@ PLOCK bit in PLLSTAT
.else
  PLOCK_bit	= 0x04000000		@ LPC 2478 PLOCK bit in PLLSTAT
.endif

@ flash
IAP_ENTRY	= 0x7FFFFFF1		@ IAP routine entry point in boot sector


/*----------------------------------------------------------------------------*\
|										|
|			2. Device Family Macros					|
|										|
\*----------------------------------------------------------------------------*/


.macro	enable_VIC_IRQ
	@ enable interrupts
	ldr	rva, =int_base		@ rva <- address of interrupt enable reg
	ldr	rvb, =scheme_ints_enb	@ rvb <- scheme interrupts
	str	rvb, [rva, #int_enable]	@ enable scheme interrupts
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
	stmdb	sp,  {fre, cnt, rva, rvb, rvc, lnk}^ @ 5 regs + lnk_usr on stack
	sub	sp,  sp, #24		@ sp  <- adj. stack ptr (next free cell)
	ldr	rvb, =int_base		@ rvb <- address of VIC IRQ Status reg
	ldr	rvc, [rvb, #int_status]	@ rvb <- asserted interrupts
	set	rvb, #0
	lsrs	rva, rvc, #16
	addne	rvb, rvb, #16
	setne	rvc, rva
	lsrs	rva, rvc, #8
	addne	rvb, rvb, #8
	setne	rvc, rva
	lsrs	rva, rvc, #4
	addne	rvb, rvb, #4
	setne	rvc, rva
	lsrs	rva, rvc, #2
	addne	rvb, rvb, #2
	setne	rvc, rva
	add	rvb, rvb, rvc, lsr #1
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




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
EP_93xx		= 1			@ CIRRUS EP93xx family MCU
include_startup = 1			@ device startup in startup.s file

@ architecture
.cpu		ep9312
FPU_is_maverick = 1			@ FPU is Maverick Crunch not default VFP

@ code addresses
_boot_section_address_	= 0x60000000	@ where startup code will run from
_text_section_address_	= _boot_section_address_ + 0x0400 @ cod strt for cpy2RAM

@ type of gpio set/clear
has_combined_set_clear	= 1		@ MCU has combined GPIO SET & CLEAR regs

@ interrupts
irq_direct_branch	= 1		@ branch to genisr diectly on interrupt
num_interrupts	= 64
uart0_int_num	= 23
uart1_int_num	= 25
timer0_int_num	= 4
timer1_int_num	= 5
i2c0_int_num	= 63			@ no I2C, use unused slot
i2c1_int_num	= 63			@ no I2C, use unused slot
int_base	= 0x800b0000		@ VIC1 base address
int_base2	= 0x800c0000		@ VIC2 base address
int_status	= 0x00			@ offset to VICIRQStatus
int_enable	= 0x10			@ offset to VicIntEnable
int_disable	= 0x14			@ offset to VicIntEnClear
int_clear_vals	= 0x00
int_clear	= 0x30			@ offset to VICVectAddr
timer0_int	= 0x000010		@ bit 4  = TC1UI
timer1_int	= 0x000020		@ bit 5  = TC2UI
scheme_ints_enb	= timer0_int + timer1_int

@ gpio
ioA_base	= 0x80840000		@ PADR
ioB_base	= 0x80840004		@ PBDR <- if scheme int, aliases to ioA
ioC_base	= 0x80840008		@ PCDR <- if scheme int, aliases to ioA
ioD_base	= 0x8084000C		@ PDDR <- if scheme int, aliases to ioA
ioE_base	= 0x80840020		@ PEDR
ioF_base	= 0x80840030		@ PFDR
ioG_base	= 0x80840038		@ PGDR <- if scheme int, aliases to ioF
ioH_base	= 0x80840040		@ PHDR
io0_base	= ioA_base		@ PADR
io1_base	= ioB_base		@ PBDR
io_dir		= 0x10			@ for PA to PD only (0x04 for PE to PH)
io_dir_high	= 0x04			@ for PE to PH only
io_set		= 0x00
io_clear	= 0x00	
io_state	= 0x00	

@ uarts
uart0_base	= 0x808c0000
uart1_base	= 0x808d0000
uart_rhr	= 0x00
uart_thr	= 0x00
uart_istat	= 0x1c			@ UARTn IntIDIntClr
uart_status	= 0x18			@ UARTnFlag
uart_txrdy	= 0x80			@ Tx FIFO Empty

@ timers
timer0_base	= 0X80810000		@ Timer1Load
timer1_base	= 0X80810020		@ Timer2Load
timer_istat	= 0x0C			@ TimernClear
timer_iset	= 0x0C			@ TimernClear
timer_ctrl	= 0x08			@ TimernControl

@ rtc
rtc0_base	= 0X80920000		@ 

@ adc
adc0_base	= 0X80900000		@ 

@ pwm
pwm0_base	= 0X80910000		@ 
pwm1_base	= 0X80910020		@ 

@ spi
spi0_base	= 0x808a0000
spi_rhr		= 0x08
spi_thr		= 0x08
spi_status	= 0x0c
spi_rxrdy	= 0x04
spi_txrdy	= 0x01

@ i2c --  NOT DONE !!!!!!
@ (it does not look like this MCU has I2C on it. It has I2S though)
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

@ usb --  (MCU has USB host but not USB device)
usb_base	= 0x00			@ NOT DONE !!!!!

@ system control
sys_ctrl	= 0x80930000		@ syscon base address



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
	stmdb	sp,  {fre, cnt, rva, rvb, rvc, lnk}^	@ 5regs+lnk_usr on stack
	sub	sp,  sp, #24		@ sp  <- adj stack ptr (next free cell)
	ldr	rvb, =int_base		@ rvb <- address of VIC IRQ Status reg
	@ dual 32-int VICs
	ldr	rvc, [rvb, #int_status]	@ rvc <- asserted interrupts (1-32)
	set	rvb, #0
	eq	rvc, #0
	ldreq	rvb, =int_base2
	ldreq	rvc, [rvb, #int_status]	@ rvc <- asserted interrupts (33-64)
	seteq	rvb, #32
	ldr	rva, =0xffff		@ rva <- initial mask
	tst	rvc, rva		@ is int num between 0 and 15?
	addeq	rvb, rvb, #16		@	if not, rvb <- int num + 16
	lsreq	rvc, rvc, #16		@	if not, rvc <- ints, shifted
	tst	rvc, #0xff		@ is int in 0-7 or 16-23?
	addeq	rvb, rvb, #8		@	if not, rvb <- int num + 8
	lsreq	rvc, rvc, #8		@	if not, rvc <- ints, shifted
	tst	rvc, #0x0f		@ is int in 0-3, 8-11, 16-19 or 24-27?
	addeq	rvb, rvb, #4		@	if not, rvb <- int num + 4
	lsreq	rvc, rvc, #4		@	if not, rvc <- ints, shifted
	tst	rvc, #0x03		@ 0-1,4-5,8-9,12-13,16-17,20-21,24-25,.?
	addeq	rvb, rvb, #2		@	if not, rvb <- int num + 2
	lsreq	rvc, rvc, #2		@	if not, rvc <- ints, shifted
	tst	rvc, #0x01		@ is int even?
	addeq	rvb, rvb, #1		@	if not, rvb <- updtd int number
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
	@ isr exit
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











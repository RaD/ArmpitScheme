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
| Contributions:								|
|										|
|     This file includes contributions by Robbie Dinn, marked <RDC>		|
|										|
\*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*\
|										|
|			1. Device Family Constants				|
|										|
|			(followed by device family macros)			|
|										|
\*----------------------------------------------------------------------------*/

@ family
AT91_SAM7	= 1			@ ATMEL AT91SAM7 family MCU

@ architecture
.cpu		arm7tdmi

@ writing to on-chip flash (done from RAM, reserve space for flsRAM of initio.s)
EXTRA_FILE_RAM	= 0x60

@ interrupts
irq_direct_branch	= 1		@ branch to genisr diectly on interrupt
num_interrupts	= 32
uart0_int_num	= 6
uart1_int_num	= 7
timer0_int_num	= 12
timer1_int_num	= 13
i2c0_int_num	= 9
i2c1_int_num	= 9
usb_int_num	= 11
int_voffset	= -0x0F20
int_base	= 0xFFFFF100		@ AIC_IVR
int_status	= 0x0C			@ AIC_IPR
int_enable	= 0x20			@ AIC_IECR
int_disable	= 0x24			@ AIC_IDCR
int_clear_vals	= 0x00
int_clear	= 0x30			@ AIC_EOICR
int_iccr  	= 0x28			@ AIC_ICCR - Interrupt Clear Command Reg
uart0_int	= 1 << uart0_int_num	@ bit  6
uart1_int	= 1 << uart1_int_num	@ bit  7
timer0_int	= 1 << timer0_int_num	@ bit 12
timer1_int	= 1 << timer1_int_num	@ bit 13
i2c0_int	= 1 << i2c0_int_num	@ bit  9
i2c1_int	= 1 << i2c1_int_num	@ bit  9
usb_int		= 1 << usb_int_num	@ bit 11
scheme_ints_enb	= timer0_int|timer1_int|i2c0_int|i2c1_int|uart0_int|uart1_int|usb_int

@ gpio -- APB Peripheral #2 -- Constants for PIOA
pioa_base	= 0xFFFFF400		@ PIOA_PER  -- PIO A Enable Reg
piob_base	= 0xFFFFF600		@ PIOB_PER  -- PIO B Enable Reg (SAM7X) <RDC>
io_dir		= 0x10			@ PIOA_OER  -- Output Enable Reg
io_set		= 0x30			@ PIOA_SODR -- Set Output Data Reg
io_clear	= 0x34			@ PIOA_CODR -- Clear Output Data Reg
io_pdsr 	= 0x3C			@ PIOA_PDSR -- Pin Data Status Reg
io_state 	= 0x3C			@ PIOA_PDSR -- Pin Data Status Reg (alt)

@ uarts -- APB Peripheral #6 
uart0_base	= 0xFFFC0000		@ US0_CR
uart1_base	= 0xFFFC4000		@ US1_CR
uart_istat	= 0x10			@ offset of US_IMR
uart_status	= 0x14			@ offset of US_CSR - uart status reg
uart_rhr	= 0x18			@ offset to uart rhr register
uart_thr	= 0x1C			@ offset to uart thr register
uart_txrdy	= 0x02			@ bit indicating uart THR empty

@ timers
timer0_base	= 0xFFFA0000		@ TC0_CCR
timer1_base	= 0xFFFA0040		@ TC1_CCR
timer_istat	= 0x20			@ offset of TC_SR
timer_iset	= 0x24			@ offset of TC_IER
timer_ctrl	= 0x00			@ offset of TC_CCR

@ i2c
i2c0_base	= 0xFFFB8000		@ TWI_CR
i2c1_base	= i2c0_base
i2c_ctrl	= 0x00			@ TWI_CR
i2c_mode	= 0x04			@ TWI_MMR
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
adc0_base	= 0xfffd8000

@ pwm
pwm0_base	= 0xfffcc000

@ SPI
spi0_base	= 0xfffe0000
spi_rhr		= 0x08
spi_thr		= 0x0c
spi_status	= 0x10
spi_rxrdy	= 0x01
spi_txrdy	= 0x02

@ usb -- APB Peripheral #11
usb_base	= 0xFFFB0000		@ UDP_NUM
usb_glbstate	= 0x04			@ UDP_GLBSTATE -- Global State Reg
usb_faddr	= 0x08			@ UDP_FADDR    -- Function Address Reg
usb_ier		= 0x10			@ UDP_IER      -- Interrupt Enable Reg
usb_istat_dv	= 0x1C			@ UDP_ISR
usb_istat_ep	= 0x1C			@ UDP_ISR
usb_iclear_dv	= 0x20			@ UDP_ICR
usb_iclear_ep	= 0x20			@ UDP_ICR
usb_csr0	= 0x30			@ UDP_CSR0     -- EP Control/Status Reg
usb_csr1	= 0x34			@ UDP_CSR1     -- EP Control/Status Reg
usb_csr2	= 0x38			@ UDP_CSR2     -- EP Control/Status Reg
usb_ibulkin	= 0x3C			@ UDP_CSR3 ctrl/stat of EP 3 (Bulk IN)
usb_fdr0	= 0x50			@ UDP_FDR0     -- Endpoint FIFO Data Reg
usb_fdr3	= 0x5C			@ UDP_FDR3     -- Endpoint FIFO Data Reg
usb_iep_mask	= 0x000F		@ mask for enpoint interrupt
usb_idv_mask	= 0xFF00		@ mask for device status interrupt
usb_busreset	= 0x1000		@ bus reset bit
usb_suspend	= 0x0100		@ suspend bit
usb_txrdy	= 0x10			@ Tx ready bit in usb_iBulk_IN
usb_itxendp	= 0x80			@ Tx end of packet interrupt bit
UsbControlOutEP	= 0x00			@ Control OUT Endpoint
UsbControlInEP	= 0x00			@ Control IN  Endpoint (id control out)
UsbBulkOutEP	= 0x02			@ Bulk OUT EP
UsbBulkInEP	= 0x03			@ Bulk IN  EP
usbBulkINDescr	= 0x83			@ Bulk IN is EP 3 (for desc at end file)
usbCO_ibit	= 0x01			@ bit indic int for Control OUT Endpoint
usbCI_ibit	= 0x02			@ bit indic int for Control IN  Endpoint
usbBO_ibit	= 0x04			@ bit indic int for Bulk    OUT Endpoint
usbBI_ibit	= 0x08			@ bit indic int for Bulk    IN  Endpoint
usbCO_setupbit	= 0x04			@ EP stat bit indic last tfer was SETUP

@ APB Peripheral #0 -- Constants for AIC 
AIC_SMR   	= 0xFFFFF000		@ (AIC) Source Mode Register
AIC_SVR0	= 0xFFFFF080		@ (AIC) Source Vector Register
AIC_SVR1	= 0xFFFFF084		@ (AIC) Source Vector Register
AIC_SVR6	= 0xFFFFF098		@ (AIC) Source Vector Register
AIC_SVR7	= 0xFFFFF09C		@ (AIC) Source Vector Register
AIC_SVR9	= 0xFFFFF0A4		@ (AIC) Source Vector Register
AIC_SVR11	= 0xFFFFF0AC		@ (AIC) Source Vector Register
AIC_SVR12	= 0xFFFFF0B0		@ (AIC) Source Vector Register
AIC_SVR13	= 0xFFFFF0B4		@ (AIC) Source Vector Register
AIC_IVR   	= 0xFFFFF100		@ (AIC) IRQ Vector Register
AIC_FVR   	= 0xFFFFF104		@ (AIC) FIQ Vector Register
AIC_ISR   	= 0xFFFFF108		@ (AIC) Interrupt Status Register
AIC_IPR   	= 0xFFFFF10C		@ (AIC) Interrupt Pending Register
AIC_IMR   	= 0xFFFFF110		@ (AIC) Interrupt Mask Register
AIC_CISR  	= 0xFFFFF114		@ (AIC) Core Interrupt Status Register
AIC_IECR  	= 0xFFFFF120		@ (AIC) Interrupt Enable Command Reg
AIC_IDCR  	= 0xFFFFF124		@ (AIC) Interrupt Disable Command Reg
AIC_ICCR  	= 0xFFFFF128		@ (AIC) Interrupt Clear Command Reg
AIC_ISCR  	= 0xFFFFF12C		@ (AIC) Interrupt Set Command Register
AIC_EOICR 	= 0xFFFFF130		@ (AIC) End of Interrupt Command Reg
AIC_SPU   	= 0xFFFFF134		@ (AIC) Spurious Vector Register
AIC_DCR   	= 0xFFFFF138		@ (AIC) Debug Control Register (Protect)
AIC_FFER  	= 0xFFFFF140		@ (AIC) Fast Forcing Enable Register
AIC_FFDR  	= 0xFFFFF144		@ (AIC) Fast Forcing Disable Register
AIC_FFSR  	= 0xFFFFF148		@ (AIC) Fast Forcing Status Register

@ Constants for MC 
MC_FCR    	= 0xFFFFFF64		@ (MC) MC Flash Command Register
MC_FSR    	= 0xFFFFFF68		@ (MC) MC Flash Status Register
PMC_base	= 0xFFFFFC00



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
	stmib	sp,  {lnk}		@ spsr on irq stack (above pc_usr)
	stmdb	sp,  {fre, cnt, rva, rvb, rvc, lnk}^	@ 5 reg+lnk_usr to stack
	sub	sp,  sp, #24		@ sp  <- adj stack ptr (nxt free cell)
	ldr	rvb, =int_base		@ rvb <- address of VIC IRQ Status reg
	ldr	rvc, [rvb, #0x00]	@ rvc <- AIC_IVR (start of int prcssng)
	ldr	rvb, [rvb, #8]		@ rvb <- asserted interrupt, AIC_ISR
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
	ldmia	sp!, {fre, cnt, rva, rvb, rvc, lnk, pc}^ @ Restore regs (USB)
.endm


.macro	isrexit
	@ second version - different from exitisr for STR7 and AT91SAM7 only
	@ isr exit
	ldr	rvc, [sp,  #28]
	msr	spsr_cxsf, rvc		@ restore spsr
	ldmia	sp, {fre, cnt, rva, rvb, rvc, lnk}^	@ Restore registers
	add	sp, sp, #24
	ldmia	sp!, {lnk}
	movs	pc,  lnk		@ Return
.endm




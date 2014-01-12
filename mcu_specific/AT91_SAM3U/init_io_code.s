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


hwinit:	@ pre-set common values
	set	r0,  #0
	set	r1,  #1
	set	r2,  #2
	set	r3,  #3
	set	r4,  #4

	@ initialization of wait states, oscillator, PLL and main clock
	ldr	r6,  =EEFC_base
	set	r7,  #0x0300		@ FWS       <- 4 wait states R/W, 96MHz
	str	r7,  [r6]		@ EEFC_FMR  <- set flash wait states
	ldr	r6,  =0x400E1254
	set	r7,  #0x8000
	str	r7,  [r6]		@ WDTC_MR   <- disable watchdog timer
	ldr	r6,  =PMC_base
	ldr	r7,  =0x0137FF01	@ r7        <- main oscillator enable
	str	r7,  [r6,  #0x20]	@ PMC_MOR   <- enable main oscillator
pllwt0:	ldr	r7,  [r6,  #0x68]
	tst	r7,  #0x01
	beq	pllwt0			@ PMC_SR    -- wait for PMC_MOSCS
	ldr	r7,  =PLL_parmsA
	str	r7,  [r6,  #0x28]	@ PMC_PLLAR <- 192 MHz

@	ldr	r7,  =PLL_parmsB
@	str	r7,  [r6,  #0x2c]	@ PMC_PLLBR <-  96 MHz

	set	r7,  #0xf10000
	str	r7,  [r6,  #0x1c]	@ CKGR_UCKR <-  enable UPLL for USB

pllwt1:	ldr	r7,  [r6,  #0x68]	@ r7        <- PMC_SR

@	tst	r7,  #0x04
	tst	r7,  #0x40
	it	ne
	tstne	r7,  #0x02


/* 44 */
@@	tst	r7,  #0x02		@ LOCKA bit set?

	beq	pllwt1			@ 	if not, jump back to wait
/* 44 */
/* 99
@	ldr	r7,  =0x3000
	set	r7,  #0x10
@	set	r7,  #0x20
	str	r7,  [r6,  #0x30]	@ PMC_MCKR  <- PRES: clock = source/2
pllwt2:	ldr	r7,  [r6,  #0x68]	@ r7        <- PMC_SR
	tst	r7,  #0x08		@ MCKRDY bit set?
@77	beq	pllwt2			@ 	if not, jump back to wait
99 */
@	set	r7,  #0x12
@@	set	r7,  #0x22
	set	r7,  #0x02
	str	r7,  [r6,  #0x30]	@ PMC_MCKR  <- PRES-CSS: sys clk=PLLA/2
pllwt3:	ldr	r7,  [r6,  #0x68]	@ r7        <- PMC_SR
	tst	r7,  #0x08		@ MCKRDY bit set?
@66	
	beq	pllwt3			@ 	if not, jump back to wait
/* 44 */
@	ldr	r7,  =0x3002
@	str	r7,  [r6,  #0x30]	@ PMC_MCKR  -- system clock to PLLA/2
@pllwt3:	ldr	r7,  [r6,  #0x68]
@	tst	r7,  #0x08
@	beq	pllwt3			@ PMC_SR    -- wait for PMC_MCKRDY
	ldr	r6,  =0x400E1208
	ldr	r7,  =0xA5000401
	str	r7,  [r6]		@ RSTC_MR  <- enab reset btn, 1ms pulse
/* 44 */


	@ initialize Cortex-M3 SysTick Timer
	swi	run_prvlgd		@ Thread mode, privileged, no IRQ
	ldr	r6,  =systick_base
	ldr	r7,  =SYSTICK_RELOAD
	str	r7,  [r6, #tick_load]	@ SYSTICK-RELOAD  <- 10ms timing
	str	r0,  [r6, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	r5,  [r6, #tick_ctrl]	@ SYSTICK-CONTROL <- enab,no int,clk=cpu
	swi	run_no_irq		@ Thread mode, unprivileged, no IRQ

	@ initialization of gpio pins
	ldr	r6,  =PMC_base
	set	r7,  #((1 << LED_PIO_ID) | (1 << BUT_PIO_ID))
	str	r7,  [r6,  #0x10]	@ PMC_PCER0 <- Enab clk/pwr for LED/BUTN
	ldr	r6,  =LEDPINSEL
	ldr	r7,  =ALLLED
	str	r7,  [r6]		@ set gpio function for led
	ldr	r6,  =LEDIO
	str	r7,  [r6,  #io_dir]	@ set led as outputs


@	set	r9,  lnk
@	bl	rldon
@	bl	gldoff
@	set	lnk, r9

@zigzag:	nop
@	nop
@	b	zigzag

	@ initialization of UART baud rate and 8N1 mode
	ldr	r6,  =pioa_base
	set	r7,  #(3 << 11)		@ r7 <- uart pins PA11(Rx), PA12(Tx)
	str	r7,  [r6,  #0x04]	@ PIOA_PDR <- Disab GPIO on uart pins
	ldr	r8,  [r6,  #0x70]	@ r8 <- PIOA_ABCDSR1
	bic	r8,  r8,  r7
	str	r8,  [r6,  #0x70]	@ PIOA_ABCDSR1 <- uart func for pins
	ldr	r8,  [r6,  #0x74]	@ r8 <- PIOA_ABCDSR2
	bic	r8,  r8,  r7
	str	r0,  [r6,  #0x74]	@ PIOA_ABCDSR2 <- uart func for pins
	ldr	r6,  =PMC_base
	set	r7,  #(1 << uart_pid)	@ r7 <- bit at periph ID of default uart
	str	r7,  [r6,  #0x10]	@ PMC_PCER0 <- Enab clk/pwr for uart
	ldr	r6,  =uart0_base
	ldr	r7,  =UART0_DIV
	str	r7,  [r6,  #0x20]	@ US0_BRGR <- Set Baud Rate CLK/DIVx16
@	str	r0,  [r6,  #0x28]	@ US0_TTGR <- disable time guard
	ldr	r7,  =0x0800
	str	r7,  [r6,  #0x04]	@ US0_MR   <- Set mode to 8N1
	str	r1,  [r6,  #0x08]	@ US0_IER  <- Enable RxRDY interrupt
	set	r7,  #0x50
	str	r7,  [r6]		@ US0_CR   <- Enab uart for RX/TX

	@ initialization of mcu-id for variables (I2c address if slave enabled)
	ldr	r6,  =I2C0ADR		@ r6  <- I2C0 mcu-address address
	set	r7,  #mcu_id
	str	r7,  [r6]		@ I2C0ADR <- set mcu address (var id)
	lsl	r7,  r7,  #15
	ldr	r6,  =i2c0_base
	str	r7,  [r6,  #i2c_address] @ set mcu's i2c address (for i2c)

	@ global USB configuration
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB_CONF <- USB device is not yet cfgd

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

	@ configure pins and SPI0 for SD-card
	@ clock (power-up) the SPI peripheral
	ldr	r6,  =PMC_base
@	set	r7,  #(1 << 21)
	set	r7,  #(1 << 20)
	str	r7,  [r6, #0x10]
	@ PIOA_OER  <- set SD CS pin as GPIO output
    .ifdef sd_cs
	ldr	r6,  =sd_cs_gpio
	set	r7,  #sd_cs
	str	r7,  [r6, #0x10]	@ set CS pin as output
	str	r7,  [r6, #0x30]	@ PIOA_SODR <- CS pin high (deselect SD)
    .endif
	@ PIOA_PDR <- disable GPIO function (PA.11,12,13,14)
	ldr	r6,  =sd_spi_gpio
	set	r7,  #(0xf << 11)
	str	r7,  [r6, #0x04]
	@ PIOA_ASR <-enable Peripheral A function (SPI) (PA.11,12,13,14)
	set	r8,  r7
	ldr	r7,  [r6, #0x70]
	bic	r7,  r7,  r8
	str	r7,  [r6, #0x70]
	ldr	r7,  [r6, #0x74]
	bic	r7,  r7,  r8
	str	r7,  [r6, #0x74]
	@ low-speed (approx 400 KHz)
	ldr	r6,  =sd_spi
	set	r7,  #0x81
	str	r7,  [r6, #0x00]	@ SPI_CR <- reset SPI
	set	r7,  #0x01
	str	r7,  [r6, #0x00]	@ SPI_CR <- enable SPI
	set	r7,  #0x01
	str	r7,  [r6, #0x04]	@ SPI_MR <- enable master mode
	set	r7,  #0xa000
	orr	r7,  r7, #0x02
	str	r7,  [r6, #0x30]	@ SPI_CSR0 <- 48MHz/120=400KHz,POL/PHA=0

  .endif @ sd_is_on_spi

.endif	@ onboard_SDFT
	
	@ copy FLASH writing code to RAM
	ldr	r6,  =flsRAM		@ sv1 <- start address of flashing code
	ldr	r7,  =flsRND		@ sv5 <- end address of flashing code
	ldr	r9,  =heaptop1		@ sv3 <- RAM target address
	add	r9,  r9, #4
hwiwt6:	ldr	r10, [r6]		@ rva <- next flashing code instruction
	str	r10, [r9]		@ store it in free RAM
	cmp	r6,  r7			@ done copying the flashing code?
	itT	mi
	addmi	r6,  r6,  #4		@	if not, sv1 <- next source adrs
	addmi	r9,  r9,  #4		@	if not, sv1 <- next target adrs
	bmi	hwiwt6			@	if not, keep copying code to RAM

.ifdef	native_usb

	@ initialization of USB device controller
	ldr	r6,  =USB_LineCoding
	ldr	r7,  =115200
	str	r7,  [r6]
	set	r7,  #0x00080000
	str	r7,  [r6,  #0x04]
	ldr	r6,  =USB_CHUNK
	str	r0,  [r6]
	ldr	r6,  =USB_ZERO
	str	r0,  [r6]
	ldr	r6,  =USB_CONF
	str	r0,  [r6]
	ldr	r6,  =PMC_base	
@?	set	r7,  #0x01
@?	str	r7,  [r6, #0x38]	@ PMC_USB   <- choose PLLB as USB clock
@?	set	r7,  #0x0080
@?	str	r7,  [r6]		@ PMC_SCER  <- enable USB clock

@	set	r7,  #0x04
@	str	r7,  [r6,  #0x0100]	@ PMC_PCER1 <- enab USB perph 34 = bit 2
	set	r7,  #(1 << 29)
	str	r7,  [r6,  #0x10]	@ PMC_PCER  <- enab USB perph 29

	ldr	r6,  =usb_base
	ldr	r7,  =0xffff
	str	r7,  [r6,  #0x20]	@ UDP_ICR   <- clear USB interrupts
	@ configure control endpoint
	ldr	r6,  =usb_base
	set	r7,  #0x8000
	str	r7,  [r6,  #0x30]	@ UDP_CSR0  <- enab Control endpoint
	set	r7,  #0x0100
	str	r7,  [r6,  #0x08]	@ UDP_FADDR <- enab transfers, adrs 0
	ldr	r7,  =0xFF0F
	str	r7,  [r6,  #0x10]	@ UDP_IER   <- enab USB interrupts
	set	r7,  #0x200
	str	r7,  [r6,  #0x74]	@ UDP_TXVC  <- enab trnscvr, 1.5K intrnl

.endif	@ native_usb

	set	r9,  lnk
@	bl	rldon
	bl	gldon
	set	lnk, r9

	@ end of the hardware initialization
	set	pc,  lnk

	
@-------------------------------------------------------------------------------
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@
@-------------------------------------------------------------------------------

_func_
FlashInitCheck: @ return status of boot override pin (PA25 = TP4) in rva
	ldr	rva, =BOOTOVERRID_PRT
	ldr	rvb, [rva, #io_pdsr]
	and	rvb, rvb, #(1 << BOOTOVERRID_BUT)
	set	rva, rvb		@ rva <- status of PA25
	set	pc,  lnk

	
_func_
wrtfla:	@ write to flash, sv4=r7 is file descriptor, sv2=r5 is page address
_func_
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	set	rvc, sv3		@ rvc <- sv3, saved
	ldr	rva, =EEFC_base
	set	rvb, #0x0600
	str	rvb, [rva]		@ EEFC_FMR  <- flsh wait stats=6 for wrt (errata)
	@ copy buffer data from file descriptor (sv4) (RAM) to AT91SAM7 FLASH buffer (sv2)
	vcrfi	sv3, sv4, 3		@ rvb <- file data source buffer
	set	rvb, #F_PAGE_SIZE	@ rvb <- last source offset
wrtfl0:	
@	ldr	rva, [sv3, rvb]		@ rva <- word from data buffer
@	subs	rvb, rvb, #4		@ last word to copy?
	subs	rvb, rvb, #4		@ last word to copy?
	ldr	rva, [sv3, rvb]		@ rva <- word from data buffer
	str	rva, [sv2, rvb]		@ store word into flash buffer
	bne	wrtfl0			@	if not, jump to keep copying data to flash buffer
	@ commit buffer to FLASH using code in RAM
	lsr	rvb, sv2, #8		@ sv1 <- target FLASH page (256 bytes page size)
	ldr	rva, =0x5A000001	@ rva <- flash write command (page zero)
	orr	rva, rva, rvb, LSL #8	@ rva <- flash write command for page in sv1
	ldr	rvb, =heaptop1
	add	rvb, rvb, #4
	adr	lnk, wrtfxt		@ lnk <- return address for after FLASH command
	set	pc,  rvb		@ jump to FLASH write routine in RAM
	
_func_
wrtfxt:	@ finish up
	ldr	rva, =EEFC_base
	set	rvb, #0x0300
	str	rvb, [rva]		@ EEFC_FMR  <- flash wait states = 3, normal op
	set	sv3, rvc		@ sv3 <- restored
	ldmfd	sp!, {rva, rvb, rvc, lnk} @ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return


_func_
ersfla:	@ erase flash sector that contains page address in sv2
_func_
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	@ copy #xffffffff to AT91SAM7 FLASH buffer (sv2)
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	ldr	rva, =EEFC_base
	set	rvb, #0x0600
	str	rvb, [rva]		@ EEFC_FMR  <- flsh wait stats=6 for wrt (errata)
	set	rvc, sv2		@ rvc <- sv2, saved
	bl	pgsctr			@ rva <- sector num (raw int), of flash page in sv2
	ldr	rvb, =flashsectors	@ rvb <- address of flash sector table
	ldr	sv2, [rvb, rva, LSL #2]	@ sv2 <- start address of flash sector
ersfl1:	set	rva, #0			@ sv3 <- 0 = start offset
	mvn	rvb, rva		@ sv4 <- erase flash data = 0xFFFFFFFF
ersfl0:	cmp	rva, #F_PAGE_SIZE	@ done writing to flash buffer?
	itT	mi
	strmi	rvb, [sv2, rva]		@	if not, store next word into flash buffer
	addmi	rva, rva, #4		@	if not, sv3 <- next word offset
	bmi	ersfl0			@	if not, keep copying data to flash buffer
	@ commit buffer to FLASH using code in RAM
	lsr	rvb, sv2, #8		@ sv1 <- target FLASH page (256 bytes page size)
	ldr	rva, =0x5A000003	@ rva <- flash erase then write command (page zero)
	orr	rva, rva, rvb, LSL #8	@ rva <- flash write command for page in sv1
	ldr	rvb, =heaptop1
	add	rvb, rvb, #4
	adr	lnk, ersfxt		@ lnk <- return address for after FLASH command
	set	pc,  rvb		@ jump to FLASH write routine in RAM
_func_
ersfxt:	@ finish up or jump to erase next page of sector
	add	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- next page address
	ldr	rvb, =0x0FFF
	ands	rvb, rvb, sv2		@ done erasing sector? (4kb = 16 pages of 256 bytes)
	bne	ersfl1			@	if not, jump back to erase more pages
	@ exit
	set	sv2, rvc		@ sv2 <- restored
	ldr	rva, =EEFC_base
	set	rvb, #0x0300
	str	rvb, [rva]		@ EEFC_FMR  <- flash wait states = 3 normal op
	ldmfd	sp!, {rva, rvb, rvc, lnk} @ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return


.ltorg	@ dump literal constants here => up to 4K of code before and after this point

@-------------------------------------------------------------------------------
@
@ 2- SD card low-level interface
@
@-------------------------------------------------------------------------------

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

_func_	
sd_cfg:	@ configure spi speed (high), phase, polarity
	@ modifies:	rva, rvb
	ldr	rva, =sd_spi
	set	rvb, #0x81
	str	rvb, [rva, #0x00]	@ SPI_CR <- reset SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x00]	@ SPI_CR <- enable SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x04]	@ SPI_MR <- enable master mode
	set	rvb, #0x0400
	orr	rvb, rvb, #0x02
	str	rvb, [rva, #0x30]	@ SPI_CSR0 <- 48 MHz / 3 = 16 MHz, POL/PHA=0
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	@ modifies:	rva, rvb
	ldr	rva, =sd_spi
	set	rvb, #0x81
	str	rvb, [rva, #0x00]	@ SPI_CR <- reset SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x00]	@ SPI_CR <- enable SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x04]	@ SPI_MR <- enable master mode
	set	rvb, #0xa000
	orr	rvb, rvb, #0x02
	str	rvb, [rva, #0x30]	@ SPI_CSR0 <- 48 MHz / 120 = 400 KHz, POL/PHA=0
	set	pc,  lnk

_func_	
sd_sel:	@ select SD-card subroutine
	@ modifies:	rva, rvb
.ifdef	sd_cs
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_clear]	@ clear CS pin
.endif
	set	pc,  lnk
	
_func_	
sd_dsl:	@ de-select SD-card subroutine
	@ modifies:	rva, rvb
.ifdef	sd_cs
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_set]	@ set CS pin
.endif
	set	pc,  lnk
	
_func_	
sd_get:	@ sd-spi get sub-routine
	@ modifies:	rva, rvb
	set	rvb, #0xff
_func_	
sd_put:	@ sd-spi put sub-routine
	@ modifies:	rva, rvb
	ldr	rva, =sd_spi
	ldr	rva, [rva, #spi_status]	@ ssta
	tst	rva, #spi_txrdy
	beq	sd_put
	ldr	rva, =sd_spi
	and	rvb, rvb, #0xff
	str	rvb, [rva, #spi_thr]	@ sdtx (sdat)
sd_gpw:	@ wait
	ldr	rvb, [rva, #spi_status]	@ ssta
	tst	rvb, #spi_rxrdy		@ sdrr
	beq	sd_gpw
	ldr	rvb, [rva, #spi_rhr]	@ sdrx (sdat)
	and	rvb, rvb, #0xff
	set	pc, lnk

  .endif @ sd_is_on_spi

.endif	@ 	onboard_SDFT
	
@
@ 2- I2C hardware and Interrupt routines
@

.ifdef	include_i2c

_func_	
hwi2cr:	@ write-out additional address registers, if needed
	@ modify interupts, as needed
	@ on entry:	sv5 <- i2c[0/1]buffer
	@ on entry:	rva <- i2c[0/1] base address (also I2CONSET)
	@ interrupts are disabled throughout
	set	pc,  lnk
	
_func_	
hwi2ni:	@ initiate i2c read/write, as master
	@ on entry:	rva <- i2c base address
	ldr	rvb, =0x107		@ rvb <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [rva, #i2c_iclear]	@ disable all TWI interrupts
	set	rvb, #0x05		@ rvb <- TXRDY and TXCOMP
	str	rvb, [rva, #i2c_ienable] @ enable TXRDY and TXCOMP interrupts
	set	rvb, #4			@ rvb <- TWI enable bit
	str	rvb, [rva, #i2c_ctrl]	@ start transfer
	set	pc,  lnk

_func_	
hwi2st:	@ get i2c interrupt status and base address
	@ on exit:	rva <- i2c[0/1] base address
	@ on exit:	rvb <- i2c interrupt status
	ldr	rvb, [rva, #i2c_status]	@ rvb <- current status of TWI interface
	ldr	rva, [rva, #i2c_imask]	@ rva <- TWI enabled Interrupt Mask
	and	rvb, rvb, rva		@ rvb <- asserted TWI ins (without spurious bits)
	ldr	rva, =i2c0_base		@ rva <- address of Status Register (restored)
	set	pc,  lnk

_func_	
hwi2cs:	@ clear SI
	set	pc,  lnk

_func_	
i2c_hw_branch:	@ process interrupt
	eq	rvb, #0x05		@ Wrt or Rd as Master -- bus mstrd (txrdy & txcomp)
	beq	i2c_hw_mst_bus
	tst	rvb, #0x0100		@ Wrt or Rd as Master -- NAK rcvd, resend byte
	bne	i2cnak
	tst	rvb, #0x04		@ Wrt as Master -- slave ok to rcv data (txrdy set)
	bne	i2c_wm_put
	tst	rvb, #0x02		@ Reading as Master -- new byte received (rxrdy set)
	bne	i2c_rm_get
	tst	rvb, #0x01		@ Wrt or Rd as Master - trnsmssn complete (txcomp)
	bne	i2c_mst_end
	set	pc,  lnk

_func_	
i2c_hw_mst_bus:	@ Reading or Writing as Master -- bus now mastered
	@ on entry:	sv1 <- i2c[0/1] data offset in glv
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	set	rvb, #0			@ rvb <- 0, number of bytes sent/received so far
	tbsti	rvb, sv2, 4		@ store number of bytes sent/received in i2c buffer
	@ store internal address bytes in TWI_IADR 
	set	rva, #i2c_iadr		@ rva <- 0, offset to internal address in TWI_IADR
	tbrfi	sv4, sv2, 1		@ sv4 <- number of internal adrs bytes (scheme int)
	add	sv4, sv4, #0x20		@ sv4 <- additional number of adrs bytes (scheme int)
i2str0:	eq	sv4, #0x21		@ are we done writing additional address bytes?
	itTTT	ne
	subne	sv4, sv4, #4		@	if not, sv4 <- adrs byt offset in i2cbfr[8]
	lsrne	rvb, sv4, #2
	ldrbne	rvb, [sv2, rvb]		@	if not, rvb <- adrs byte from i2cbfr[8+ofst]
	strbne	rvb, [sv3, rva]		@ 	if not, str nxt intrnl adrs byt in TWO_IADR
	it	ne
	addne	rva, rva,#1		@	if not, rva <- ofst nxt intrnl adrs TWI_IADR
	bne	i2str0			@	if not, jump to store next intrnl adrs byte
	@ set TWI_MMR to write/read to/from i2c adrs with num of internal address bytes
	tbrfi	rvb, sv2, 0		@ r7  <- adrs of mcu to wrt/rd dat to/from int/flt
	tst	rvb, #0x02		@ is this a write operation?
	itE	eq
	seteq	rva, #0x0000		@	if so,  rva <- TWI r/w bit set to wrt
	setne	rva, #0x1000		@	if not, rva <- TWI r/w bit set to rd
	lsr	rvb, rvb, #2		@
	orr	rva, rva, rvb, LSL #16	@
	tbrfi	rvb, sv2, 1		@ rvb <- number of internal adrs bytes (scheme int)
	lsr	rvb, rvb, #2		@ rvb <- number of internal address bytes (raw int)
	orr	rva, rva, rvb, LSL #8	@ rva <- r/w and #internal address bytes
	str	rva, [sv3, #i2c_mode]	@ set r/w bit, #intrnl adrs byts & trgt adrs TWI MMR
	ldr	rvb, =0x107		@ rvb <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ deactivate interrupts
	beq	i2strw			@	if so,  jump to start a write
	@ start an i2c read
	tbrfi	rva, sv2,  3		@ rva <- number of bytes to read
	cmp	rva, #2			@ are we reading just 1 byte?
	itE	mi
	setmi	rvb, #1			@	if so,  rvb <- TXCOMP bit
	setpl	rvb, #2			@	if not, rvb <- TWI RXRDY bit
	str	rvb, [sv3, #i2c_ienable] @ enable TWI RXRDY interrupt
	tbrfi	rva, sv2,  3		@ rva <- number of bytes to send/read
	cmp	rva, #2			@ are we reading just 1 byte?
	itE	mi
	setmi	rvb, #3			@	if so,  rvb <- stop and start bits
	setpl	rvb, #1			@	if not, rvb <- start bit
	str	rvb, [sv3, #i2c_ctrl]	@ start transfer
	bl	gldon			@ turn led on
	b	i2cxit			@ exit
i2strw:	@ start an i2c write
	tbrfi	rva, sv2,  3		@ rva <- number of bytes to send
	cmp	rva, #2			@ are we sending just 1 byte?
	itEE	mi
	setmi	rvb, #1			@	if so,  rvb <- TWI TXCOMP bit
	setpl	rvb, #4			@	if not, rvb <- TWI TXRDY bit
	orrpl	rvb, rvb, #0x0100	@	if not, rvb <- TXRDY and NAK bits
	str	rvb, [sv3, #i2c_ienable] @ enable TWI TXCOMP OR TXRDY interrupt
	bl	i2putc			@ jump to write 1st byte
	tbrfi	rva, sv2,  3		@ rva <- number of bytes to send
	cmp	rva, #2			@ are we sending just 1 byte?
	itT	mi
	setmi	rvb, #3			@	if so,  rvb <- stop and start bits
	strmi	rvb, [sv3, #i2c_ctrl]	@	if so,  start transfer
	bl	gldon			@ turn led on
	b	i2cxit
	
_func_	
i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer or r12
	set	pc,  lr

_func_	
i2pute:	@ Epilogue:	set completion status if needed
	tbrfi	rva, sv2, 3		@ rva <- number of data bytes to send (raw int)
	tbrfi	rvb, sv2, 4		@ rvb <- number of data bytes sent (raw int)
	eq	rva, rvb		@ done sending?
	beq	i2cstp			@	if so,  jump to end transfer
	set	pc,  lnk

i2cnak:	@ re-send last byte
	tbrfi	rvb, sv2, 4		@ rvb <- number of data bytes sent (raw int)
	sub	rvb, rvb, #1
	tbsti	rvb, sv2, 4		@ rvb <- number of data bytes sent (raw int)
	b	i2c_wm_put
	
_func_	
i2cstp:	@ NAK received or just 1 byte left to read, set stop bit
	@ note how this is also the bottom of i2pute, above
	ldr	rvb, =0x107		@ rvb <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	rvb, #1			@ rvb <- TXCOMP bit
	str	rvb, [sv3, #i2c_ienable] @ enable TWI TXCOMP interrupt
	set	rvb, #2			@ rvb <- stop bit
	str	rvb, [sv3, #i2c_ctrl]	@ set stop transfer
	set	pc,  lnk

_func_	
i2c_mst_end:	@ txcomp received
	tbrfi	rvb, sv2, 0		@ rvb <- adrs of mcu to wrt/rd dat to/from int/flt
	tst	rvb, #0x02		@ is this a write operation?
	beq	i2c_wm_end
	b	i2c_rm_end

_func_	
hwi2we:	@ set busy status/stop bit at end of write as master
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	@ on entry:	rvb <- #f
	tbsti	rvb, sv2, 0		@ set busy status to #f (transfer done)
	ldr	rvb, =0x107		@ rvb <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	pc,  lnk
	
_func_	
hwi2re:	@ set stop bit if needed at end of read-as-master
	@ on entry:	sv3 <- i2c[0/1] base address
	ldr	rvb, =0x107		@ rvb <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	pc,  lnk

.endif

.ltorg






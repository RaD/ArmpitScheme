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

/*------------------------------------------------------------------------------
@
@ Contributions:
@
@     This file includes contributions by Robbie Dinn, marked <RDC>
@
@-----------------------------------------------------------------------------*/



hwinit:	@ pre-set common values
	set	r0,  #0
	set	r1,  #1
	set	r2,  #2
	set	r3,  #3
	set	r4,  #4
	@ initialization of wait states, oscillator, PLL and main clock
	ldr	r6,  =0xFFFFFF60
	ldr	r7,  =0x480100
	str	r7,  [r6]		@ MC_FMR flash wait states=1,Rd-2,Wrt-3
	ldr	r6,  =0xFFFFFD44
	ldr	r7,  =0x8000
	str	r7,  [r6]		@ WDTC_WDMR -- disable watchdog timer
	ldr	r6,  =PMC_base
	ldr	r7,  =0xFF01
	str	r7,  [r6,  #0x20]	@ PMC_MOR 0x0601=StrtCnt=6[*8]1.5ms,enab
pllwt0:	ldr	r7,  [r6,  #0x68]
	tst	r7,  #0x01
	beq	pllwt0			@ PMC_SR    -- wait for PMC_MOSCS
	ldr	r7,  =PLL_parms
	str	r7,  [r6,  #0x2c]	@ PMC_PLLR  -- 96 MHz
pllwt1:	ldr	r7,  [r6,  #0x68]
	tst	r7,  #0x04
	beq	pllwt1			@ PMC_SR    -- wait for PMC_LOCK
	str	r4,  [r6,  #0x30]	@ PMC_MCKR  -- sys clck prescaler=1/2
pllwt2:	ldr	r7,  [r6,  #0x68]
	tst	r7,  #0x08
	beq	pllwt2			@ PMC_SR    -- wait for PMC_MCKRDY
	set	r7,  #0x07
	str	r7,  [r6,  #0x30]	@ PMC_MCKR  -- sys clck<-PLL/2
pllwt3:	ldr	r7,  [r6,  #0x68]
	tst	r7,  #0x08
	beq	pllwt3			@ PMC_SR    -- wait for PMC_MCKRDY
	ldr	r6,  =0xFFFFFD08
	ldr	r7,  =0xA5000401
	str	r7,  [r6]		@ RSTC_RMR  -- enable reset button (1ms)
	@ initialization of gpio pins
.ifndef	AT91SAM7X @ AT91SAM7S
	ldr	r6,  =PMC_base
	str	r4,  [r6,  #0x10]	@ PMC_PCER Enab clck/pwr for gpio PIOA
.else @ AT91SAM7X
	ldr	r6,  =PMC_base		@					<RDC>
	ldr	r7,  =0x0C		@					<RDC>
	str	r7,  [r6,  #0x10]	@ PMC_PCER Enab clck/pwr for gpio PIOAB	<RDC>
.endif
	ldr	r6,  =LEDPINSEL
	ldr	r7,  =ALLLED
	str	r7,  [r6]		@ set gpio function for led
	ldr	r6,  =LEDIO
	str	r7,  [r6,  #io_dir]	@ set led as outputs
	@ initialization of UART0 for 9600 8N1 operation
	ldr	r6,  =uart0_gpio	@					<RDC>
	set	r7,  #uart0_pins	@					<RDC>
	str	r7,  [r6,  #0x04]	@ PIOA_PDR -- Disab uart0 pins bits 5,6
	str	r7,  [r6,  #0x70]	@ PIOA_ASR -- Sel uart0 func Periph A
	str	r0,  [r6,  #0x74]	@ PIOA_BSR -- Desel periph B functions
	ldr	r6,  =PMC_base
	set	r7,  #0x40
	str	r7,  [r6,  #0x10]	@ PMC_PCER -- Enab clck/pwr for uart0
	ldr	r6,  =uart0_base
	ldr	r7,  =UART0_DIV
	str	r7,  [r6,  #0x20]	@ US0_BRGR -- Set Baud Rate to 9600
	str	r0,  [r6,  #0x28]	@ US0_TTGR -- disable time guard
	ldr	r7,  =0x08C0
	str	r7,  [r6,  #0x04]	@ US0_MR   -- Set mode to 8N1, 16xovrsmp
	ldr	r7,  =0x0202
	str	r7,  [r6,  #0x0120]	@ US0_PTCR -- Disable DMA transfers
	str	r1,  [r6,  #0x08]	@ US0_IER  -- Enable RxRDY interrupt
	set	r7,  #0x50
	str	r7,  [r6]		@ US0_CR   -- Enab uart0 RX and TX
	@ initialization of interrupts vector for UART0,1, twi (i2c), timer0,1
	ldr	r6,  =AIC_SPU
	ldr	r7,  =spuisr
	str	r7,  [r6]		@ AIC_SPU   <- spuisr spurious int hndlr
	ldr	r6,  =AIC_SVR0
	str	r7,  [r6]		@ AIC_SVR0  <- spuisr as fiq handler
	str	r7,  [r6,  #0x04]	@ AIC_SVR1  <- spuisr as sys irq handler
	ldr	r7,  =genisr
	str	r7,  [r6,  #0x18]	@ AIC_SVR6  <- set genisr as uart0  isr
	str	r7,  [r6,  #0x1c]	@ AIC_SVR7  <- set genisr as uart1  isr
	str	r7,  [r6,  #0x24]	@ AIC_SVR9  <- set genisr as twi    isr
	str	r7,  [r6,  #0x30]	@ AIC_SVR12 <- set genisr as timer0 isr
	str	r7,  [r6,  #0x34]	@ AIC_SVR13 <- set genisr as timer1 isr
	@ initialization of mcu-id for variables (normally I2c adrs if slv enab)
	ldr	r6,  =I2C0ADR		@ r6  <- I2C0 mcu-address address
	set	r7,  #mcu_id
	str	r7,  [r6]		@ I2C0ADR <- set mcu address
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB_CONF <- USB device is not yet cfg

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

	@ configure pins and SPI0 for SD-card
	@ clock (power-up) the SPI peripheral
	ldr	r6, =PMC_base
	set	r7, #(1 << 5)
	str	r7, [r6, #0x10]
	@ PIOA_OER  <- set SD CS pin as GPIO output
	ldr	r6, =sd_cs_gpio
	set	r7, #sd_cs
	str	r7, [r6, #0x10]		@ set CS pin as output
	@ PIOA_SODR <- de-select SD (set CS high)
	str	r7, [r6, #0x30]		@ set CS pin
	@ PIOA_PDR <- disable GPIO function (PA.11,12,13,14)
	ldr	r6, =sd_spi_gpio
	set	r7, #(0xf << 11)
	str	r7, [r6, #0x04]
	@ PIOA_ASR <-enable Peripheral A function (SPI) (PA.11,12,13,14)
	str	r7, [r6, #0x70]
	@ low-speed (approx 400 KHz)
	ldr	r6, =sd_spi
	set	r7, #0x81
	str	r7, [r6, #0x00]		@ SPI_CR <- reset SPI
	set	r7, #0x01
	str	r7, [r6, #0x00]		@ SPI_CR <- enable SPI
	set	r7, #0x01
	str	r7, [r6, #0x04]		@ SPI_MR <- enable master mode
	set	r7, #0x7800
	orr	r7, r7, #0x02
	str	r7, [r6, #0x30]		@ SPI_CSR0 <- 48MHz/120=400KHz,POL/PHA=0

  .endif @ sd_is_on_spi

.endif	@ onboard_SDFT
	
	@ copy FLASH writing code to RAM
	ldr	r6,  =flsRAM		@ sv1 <- start address of flashing code
	ldr	r7,  =flsRND		@ sv5 <- end address of flashing code
	ldr	r9,  =heaptop1		@ sv3 <- RAM target address
	add	r9,  r9, #4
hwiwt6:	ldr	r10, [r6]		@ rva <- next flashing code instruction
	str	r10, [r9]		@ store it in free RAM
	eq	r6,  r7			@ done copying the flashing code?
	addne	r6,  r6,  #4		@	if not, sv1 <- nxt cod src  adrs
	addne	r9,  r9,  #4		@	if not, sv1 <- nxt cod trgt adrs
	bne	hwiwt6			@	if not, keep copying code to RAM

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
	ldr	r6,  =AIC_SVR11
	ldr	r7,  =genisr
	str	r7,  [r6]		@ set usbisr as USB isr
	ldr	r6,  =PMC_base
	set	r7,  #0x0080
	str	r7,  [r6]		@ PMC_SCER  -- enable USB clock
	set	r7,  #0x0800
	str	r7,  [r6,  #0x10]	@ PMC_PCER  -- enab USB periph 11=bit 11
	ldr	r6,  =usb_base
	ldr	r7,  =0xffff
	str	r7,  [r6,  #0x20]	@ UDP_ICR   -- clear USB interrupts
	@ configure control endpoint
	ldr	r6,  =usb_base
	set	r7,  #0x8000
	str	r7,  [r6,  #0x30]	@ UDP_CSR0  -- r7  <- enab Control EP
	set	r7,  #0x0100
	str	r7,  [r6,  #0x08]	@ UDP_FADDR -- enab tfer on address 0
	ldr	r7,  =0xFF0F
	str	r7,  [r6,  #0x10]	@ UDP_IER   -- enable USB ints (0-3)
	str	r0,  [r6,  #0x74]	@ UDP_TXVC  -- enable transceiver

  .ifdef SAM7_P256
  
	@ OLIMEX SAM_P256 requires USB pullups to be set under software control.
	ldr	r6,  =pioa_base		@					<RDC>
	ldr	r7,  =0x10100		@ PA16 and PA8				<RDC>
	str	r7,  [r6,  #0x00]	@ PIO_PER				<RDC>
	str	r7,  [r6,  #0x10]	@ PIO_OER				<RDC>
	str	r7,  [r6,  #0x64]	@ PIO_PUDR				<RDC>
	str	r7,  [r6,  #0x30]	@ PIO_SODR				<RDC>
	set	r7,  #0x10000		@ PA16					<RDC>
	str	r7,  [r6,  #0x34]	@ PIO_CODR				<RDC>

  .endif @ SAM7_P256

.endif	@ native_usb

	@ end of the hardware initialization
	set	pc,  lnk

	
@-------------------------------------------------------------------------------
@ AT91_SAM7
@
@	 0- Spurius interrupt handler (if needed)
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-------------------------------------------------------------------------------

@
@ 0- Spurius interrupt handler (if needed)
@

spuisr:	@ spurious interrupt handler
	sub	lnk, lnk, #4		@ Adjust lnk to point to return 
	stmdb	sp!, {rva, rvb, lnk}	@ store lnk_irq on irq stack
	ldr	rva, =int_base
	ldr	rvb, [rva,  #int_status]
	str	rvb, [rva,  #int_iccr]
	set	rvb, #0
	str	rvb, [rva,  #int_clear]	
	ldmia	sp!, {rva, rvb, pc}^	@ return
	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

FlashInitCheck: @ return stat of  boot override gpio pin (PA3) in rva
	ldr	rva, =flash_int_gpio	@					<RDC>
	ldr	rvb, [rva, #io_pdsr]
	and	rvb, rvb, #flash_init_pin @ rvb <- stat of boot ovrrd pin	<RDC>
	set	rva, rvb		@ rva <- stat of boot ovrrd pin
	set	pc,  lnk

	
wrtfla:	@ write to flash, sv4=r7 is file descriptor, sv2=r5 is page address
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	set	rvc, sv3		@ rvc <- sv3, saved
	@ copy data from file desc (sv4) (RAM) to AT91SAM7 FLASH buffer (sv2)
	vcrfi	sv3, sv4, 3		@ rvb <- file data source buffer
	set	rvb, #F_PAGE_SIZE	@ rvb <- last source offset
wrtfl0:	subs	rvb, rvb, #4
	ldr	rva, [sv3, rvb]		@ rva <- word from data buffer
	str	rva, [sv2, rvb]		@ store word into flash buffer
	bne	wrtfl0			@	if not, jump to keep copying dat
	@ disconnect AIC
	ldr	rva, =int_base
	set	rvb, #2
	str	rvb, [rva, #0x38]
	@ commit buffer to FLASH using code in RAM
	lsr	rvb, sv2, #8		@ sv1 <- target FLASH page (256 bytes)
	ldr	rva, =0x5A000001	@ rva <- flash write command (page zero)
	orr	rva, rva, rvb, LSL #8	@ rva <- flash write cmnd for page sv1
	ldr	rvb, =heaptop1
	add	rvb, rvb, #4
	swi	isr_no_irq
	adr	lnk, wrtfxt		@ lnk <- return address after FLASH cmnd
	set	pc,  rvb		@ jump to FLASH write routine in RAM
wrtfxt:	@ finish up
	swi	run_normal		@ enable interrupts (user mode)
	@ reconnect AIC
	ldr	rva, =int_base
	set	rvb, #0
	str	rvb, [rva, #0x38]
	set	sv3, rvc		@ sv3 <- restored
	@ wait a bit (recovery?)
	set	rva, #0x6000		@ rva <- wait, approx 1 ms
wrtfwt:	subs	rva, rva, #1
	bne	wrtfwt
	@ check for errors (it that's possible)
	set	rvb, #0
	mvn	rvb, rvb
	bic	rvb, rvb, #0xff
	ldr	rva, [rvb, #0x68]	@ rva <- status
	tst	rva, #0x01		@ FRDY?
	beq	wrterr
	set	pc,  lnk		@ return

wrterr:	@ write error other than 1/0
	raw2int	sv1, rva
	ldmfd	sp!, {rva, rvb, sv3, rvc, lnk}	@ restore scheme regs from stack
	ldr	sv4, =flash_
	b	error4


	
ersfla:	@ erase flash sector that contains page address in sv2
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	@ copy #xffffffff to AT91SAM7 FLASH buffer (sv2)
	set	rvc, lnk		@ rvc <- lnk, saved
	bl	pgsctr			@ rva <- sectr num (raw int) of page sv2
	set	lnk, rvc		@ lnk <- restored
	set	rvc, sv2		@ rvc <- sv2, saved
	ldr	rvb, =flashsectors	@ rvb <- address of flash sector table
	ldr	sv2, [rvb, rva, LSL #2]	@ sv2 <- start address of flash sector
ersfl1:	set	rva, #0			@ sv3 <- 0 = start offset
	mvn	rvb, rva		@ sv4 <- erase flash data = 0xFFFFFFFF
ersfl0:	cmp	rva, #F_PAGE_SIZE	@ done writing to flash buffer?
	strmi	rvb, [sv2, rva]		@	if not, store next word in buffr
	addmi	rva, rva, #4		@	if not, sv3 <- next word offset
	bmi	ersfl0			@	if not, jump to keep copying dat
	@ commit buffer to FLASH using code in RAM
	lsr	rvb, sv2, #8		@ sv1 <- target FLASH page (256 bytes)
	ldr	rva, =0x5A000001	@ rva <- flash write command (page zero)
	orr	rva, rva, rvb, LSL #8	@ rva <- flash write cmnd for page sv1
	ldr	rvb, =heaptop1
	add	rvb, rvb, #4
	swi	isr_no_irq
	adr	lnk, ersfxt		@ lnk <- return address for FLASH cmnd
	set	pc,  rvb		@ jump to FLASH write routine in RAM
ersfxt:	@ finish up or jump to erase next page of sector
	swi	run_normal		@ enable interrupts (user mode)
	add	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- next page address
	ldr	rvb, =0x0FFF
	ands	rvb, rvb, sv2		@ done erasing sector? (4kb=16x256bytes)
	bne	ersfl1
	set	sv2, rvc		@ sv2 <- restored
	set	pc,  lnk		@ return

.ltorg	@ dump literal constants here => up to 4K of code before and after this


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
	set	rvb, #0x0300
	orr	rvb, rvb, #0x02
	str	rvb, [rva, #0x30]	@ SPI_CSR0 <- 48MHz/3=16MHz,POL/PHA=0
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
	set	rvb, #0x7800
	orr	rvb, rvb, #0x02
	str	rvb, [rva, #0x30]	@ SPI_CSR0 <- 48MHz/120=400KHz,POL/PHA=0
	set	pc,  lnk

_func_	
sd_sel:	@ select SD-card subroutine
	@ modifies:	rva, rvb
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_clear]	@ clear CS pin
	set	pc,  lnk
	
_func_	
sd_dsl:	@ de-select SD-card subroutine
	@ modifies:	rva, rvb
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_set]	@ set CS pin
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

hwi2cr:	@ write-out additional address registers, if needed
	@ modify interupts, as needed
	@ on entry:	sv5 <- i2c[0/1]buffer
	@ on entry:	r6  <- i2c[0/1] base address (also I2CONSET)
	@ interrupts are disabled throughout
	set	pc,  lnk
	
hwi2ni:	@ initiate i2c read/write, as master
	@ on entry:	r6  <- i2c base address
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [rva, #i2c_iclear]	@ disable all TWI interrupts
	set	rvb, #0x05		@ r7  <- TXRDY and TXCOMP
	str	rvb, [rva, #i2c_ienable] @ enable TXRDY and TXCOMP interrupts
	set	rvb, #4			@ r7  <- TWI enable bit
	str	rvb, [rva, #i2c_ctrl]	@ start transfer
	set	pc,  lnk

hwi2st:	@ get i2c interrupt status and base address
	@ on exit:	r6 <- i2c[0/1] base address
	@ on exit:	r7 <- i2c interrupt status
	ldr	rvb, [rva, #i2c_status]	@ r7  <- current status of TWI interface
	ldr	rva, [rva, #i2c_imask]	@ r6  <- TWI enabled Interrupt Mask
	and	rvb, rvb, rva		@ r7  <- TWI ints (w/o spurious bits)
	ldr	rva, =i2c0_base		@ r6  <- address of Stat Reg (restored)
	set	pc,  lnk

hwi2cs:	@ clear SI
	set	pc,  lnk

i2c_hw_branch:	@ process interrupt
	eq	rvb, #0x05		@ Wrt or Rd as Mstr, bus mstrd txrdy+cmp
	beq	i2c_hw_mst_bus
	tst	rvb, #0x0100		@ Wrt or Rd as Mstr, NAK rcvd resnd byte
	bne	i2cnak
	tst	rvb, #0x04		@ Wrt as Mstr, slv ok to rcv dat, txrdy
	bne	i2c_wm_put
	tst	rvb, #0x02		@ Rd as Mstr -- new byte rcvd (rxrdy set)
	bne	i2c_rm_get
	tst	rvb, #0x01		@ Wrt or Rd as Mstr, tx cmplt txcomp set
	bne	i2c_mst_end
	set	pc,  lnk

i2c_hw_mst_bus:	@ Reading or Writing as Master -- bus now mastered
	@ on entry:	sv1 <- i2c[0/1] data offset in glv
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	set	rvb, #0			@ r7  <- 0, num bytes sent/rcvd so far
	tbsti	rvb, sv2, 4		@ store num bytes sent/rcvd in i2c bfr
	@ store internal address bytes in TWI_IADR 
	set	rva, #i2c_iadr		@ r6  <- 0, ofst to intrnl adrs TWI_IADR
	tbrfi	sv4, sv2, 1		@ sv4 <- num intrnl adrs byts (schm int)
	add	sv4, sv4, #0x20		@ sv4 <- addtnl num adrs byts (schm int)
i2str0:	eq	sv4, #0x21		@ done writing additional address bytes?
	subne	sv4, sv4, #4		@	if not, sv4 <- adrs ofst in bfr
	ldrbne	rvb, [sv2, sv4, LSR #2]	@	if not, r7  <- adrs frm i2cbfr
	strbne	rvb, [sv3, rva]		@ 	if not, str nxt intrnl adrs IADR
	addne	rva, rva,#1		@	if not, r6  <- ofst to nxt adrs
	bne	i2str0			@	if not, jmp to str nxt adrs byte
	@ set TWI_MMR to write/read to/from i2c address
	@ with appropriate number of internal address bytes
	tbrfi	rvb, sv2, 0		@ r7  <- mcu adrs to wrt/rd dat, int/flt
	tst	rvb, #0x02		@ is this a write operation?
	seteq	rva, #0x0000		@	if so,  r6  <- TWI wrt+trgt adrs
	setne	rva, #0x1000		@	if not, r6  <- TWI  rd+trgt adrs
	lsr	rvb, rvb, #2		@
	orr	rva, rva, rvb, LSL #16	@
	tbrfi	rvb, sv2, 1		@ r7  <- num intrnl adrs bytes (sch int)
	lsr	rvb, rvb, #2		@ r7  <- num intrnl adrs bytes (raw int)
	orr	rva, rva, rvb, LSL #8	@ r6  <- r/w and #internal address bytes
	str	rva, [sv3, #i2c_mode]	@ TWI_MMR <- r/w bit,#adrs byt,trgt adrs
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ deactivate interrupts
	beq	i2strw			@	if so,  jump to start a write
	@ start an i2c read
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to read
	cmp	rva, #2			@ are we reading just 1 byte?
	setmi	rvb, #1			@	if so,  r7  <- TXCOMP bit
	setpl	rvb, #2			@	if not, r7  <- TWI RXRDY bit
	str	rvb, [sv3, #i2c_ienable] @ enable TWI RXRDY interrupt
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to send/read
	cmp	rva, #2			@ are we reading just 1 byte?
	setmi	rvb, #3			@	if so,  r7  <- stop + start bits
	setpl	rvb, #1			@	if not, r7  <- start bit
	str	rvb, [sv3, #i2c_ctrl]	@ start transfer
	bl	gldon			@ turn led on
	b	i2cxit			@ exit
i2strw:	@ start an i2c write
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to send
	cmp	rva, #2			@ are we sending just 1 byte?
	setmi	rvb, #1			@	if so,  r7  <- TWI TXCOMP bit
	setpl	rvb, #4			@	if not, r7  <- TWI TXRDY bit
	orrpl	rvb, rvb, #0x0100	@	if not, r7  <- TXRDY + NAK bits
	str	rvb, [sv3, #i2c_ienable] @ enable TWI TXCOMP OR TXRDY interrupt
	bl	i2putc			@ jump to write 1st byte
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to send
	cmp	rva, #2			@ are we sending just 1 byte?
	setmi	rvb, #3			@	if so,  r7  <- stop + start bits
	strmi	rvb, [sv3, #i2c_ctrl]	@	if so,  start transfer
	bl	gldon			@ turn led on
	b	i2cxit
	
i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer/r12
	set	pc,  lr

i2pute:	@ Epilogue:	set completion status if needed
	tbrfi	rva, sv2, 3		@ r6  <- num dat bytes to send (raw int)
	tbrfi	rvb, sv2, 4		@ r7  <- num dat bytes sent (raw int)
	eq	rva, rvb		@ done sending?
	beq	i2cstp			@	if so,  jump to end transfer
	set	pc,  lnk

i2cnak:	@ re-send last byte
	tbrfi	rvb, sv2, 4		@ r7  <- num data bytes sent (raw int)
	sub	rvb, rvb, #1
	tbsti	rvb, sv2, 4		@ r7  <- num data bytes sent (raw int)
	b	i2c_wm_put
	
i2cstp:	@ NAK received or just 1 byte left to read, set stop bit
	@ note how this is also the bottom of i2pute, above
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	rvb, #1			@ r7  <- TXCOMP bit
	str	rvb, [sv3, #i2c_ienable] @ enable TWI TXCOMP interrupt
	set	rvb, #2			@ r7  <- stop bit
	str	rvb, [sv3, #i2c_ctrl]	@ set stop transfer
	set	pc,  lnk

i2c_mst_end:	@ txcomp received
	tbrfi	rvb, sv2, 0		@ rvb <- mcu adrs to wrt/rd (int/flt)
	tst	rvb, #0x02		@ is this a write operation?
	beq	i2c_wm_end
	b	i2c_rm_end

hwi2we:	@ set busy status/stop bit at end of write as master
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	@ on entry:	r7  <- #f
	tbsti	rvb, sv2, 0		@ set busy status to #f (transfer done)
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	pc,  lnk
	
hwi2re:	@ set stop bit if needed at end of read-as-master
	@ on entry:	sv3 <- i2c[0/1] base address
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	pc,  lnk

.endif

.ltorg





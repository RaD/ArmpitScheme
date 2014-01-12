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


_func_	
hwinit:
	@ pre-set common values
	set	r0,  #0
	set	r1,  #1
	set	r2,  #2
	set	r3,  #3
	set	r4,  #4
	set	r5,  #5

.ifndef TI_EvalBot

	@ initialization of clocks
	ldr	r6,  =sys_base
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x03C0
	orr	r7,  r7, #0x0380
	str	r7,  [r6,  #rcc]	@ RCC      <- XTAL = 0xE for 8 MHz crystal
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x01
	str	r7,  [r6,  #rcc]	@ RCC      <- MOSCDIS = 0, enable main oscillator
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x07800000
	orr	r7,  r7, #0x01800000
	str	r7,  [r6,  #rcc]	@ RCC      <- SYSDIV = 0x3, divide by 4 (later on, PLL output = 50MHz)
	ldr	r7,  [r6,  #rcc]
	orr	r7,  r7, #0x00400000
	str	r7,  [r6,  #rcc]	@ RCC      <- USESYSDIV = 1, enable freq division by 4
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x30
	str	r7,  [r6,  #rcc]	@ RCC      <- OSCSRC = 0, choose main oscillator as clock
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x2000
	str	r7,  [r6,  #rcc]	@ RCC      <- PWRDN = 0, power up PLL
hwiwt0:	ldr	r7,  [r6,  #0x50]
	tst	r7,  #0x40		@ RIS      <- wait for PLL Tready  bit
	beq	hwiwt0
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x0800
	str	r7,  [r6,  #rcc]	@ RCC      <- BYPASS = 0, connect PLL

.else	@ TI_EvalBot

	@ initialization of clocks
	ldr	r6,  =sys_base
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x07C0
	orr	r7,  r7, #0x0540
	str	r7,  [r6,  #rcc]	@ RCC      <- XTAL = 0x15 for 16 MHz crystal
	ldr	r7,  [r6,  #rcc]
	bic	r7,  r7, #0x01
	str	r7,  [r6,  #rcc]	@ RCC      <- MOSCDIS = 0, enable main oscillator
	ldr	r7,  [r6,  #rcc2]
	bic	r7,  r7, #0x1fc00000
	orr	r7,  r7, #0xc1000000
	str	r7,  [r6,  #rcc2]	@ RCC2     <- USE SYSDIV2 = 0x5 with LSB2, divide by 5 (80MHz)
	ldr	r7,  [r6,  #rcc]
	orr	r7,  r7, #0x00400000
	str	r7,  [r6,  #rcc]	@ RCC      <- USESYSDIV = 1, enable freq division
	ldr	r7,  [r6,  #rcc2]
	bic	r7,  r7, #0x70
	str	r7,  [r6,  #rcc2]	@ RCC2     <- OSCSRC2 = 0, choose main oscillator as clock
	ldr	r7,  [r6,  #rcc2]
	bic	r7,  r7, #0x6000
	str	r7,  [r6,  #rcc2]	@ RCC2     <- PWRDN2 = 0, power up PLL and USB PLL
hwiwt0:	ldr	r7,  [r6,  #0x50]
	tst	r7,  #0x40		@ RIS      <- wait for PLL Tready  bit
	it	ne
	tstne	r7,  #0x80		@ RIS      <- wait for USB PLL Tready  bit
	beq	hwiwt0
	ldr	r7,  [r6,  #rcc2]
	bic	r7,  r7, #0x0800
	str	r7,  [r6,  #rcc2]	@ RCC2     <- BYPASS2 = 0, connect PLL

.endif

	@ initialization of USB configuration
	ldr	r7,  =USB_CONF
	str	r0,  [r7]		@ USB_CONF <- USB device is not yet configured

	@ initialize Cortex-M3 SysTick Timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	r6,  =systick_base
	ldr	r7,  =SYSTICK_RELOAD
	str	r7,  [r6, #tick_load]	@ SYSTICK-RELOAD  <- value for 10ms timing at 50 or 80 MHz
	str	r0,  [r6, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	r5,  [r6, #tick_ctrl]	@ SYSTICK-CONTROL <- 5 = enabled, no interrupt, run from cpu clock
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ initialization of LED gpio pins
	ldr	r6,  =sys_base
	add	r6,  r6, #0x0100
	ldr	r7,  [r6,  #0x08]
	orr	r7,  r7, #ENABLE_PORTS	@ set bit(s) for LED and Button ports' clocks to enable
	str	r7,  [r6,  #0x08]	@ RCGC2    <- enable clock for LED Port
	ldr	r7,  =ALLLED
	ldr	r8,  =LEDPINSEL
	str	r7,  [r8, #0x0400]	@ GPIODIR  <- all led directions set to output
	add	r8,  r8, #0x0500
	str	r7,  [r8, #0x08]	@ GPIODR8R <- all led have 8 mA drive
	str	r7,  [r8, #0x1c]	@ GPIODEN  <- all led pins active (non tri-state)

	@ initialization of boot-override button
	ldr	r8,  =BOOTOVERRID_PRT+0x500
	ldr	r7,  [r8,  #0x1c]
	orr	r7,  r7, #(1 << BOOTOVERRID_BUT)
	str	r7,  [r8,  #0x1c]	@ GPIODEN  <- set button as digital in (for boot bypass)
	set	r7,  #(1 << BOOTOVERRID_BUT)
	str	r7,  [r8,  #0x10]	@ GPIOPUR  <- add weak pull-up to button
	@ initialization of UART0 for 9600 8N1 operation
	ldr	r7,  [r6,  #0x08]
	orr	r7,  r7, #0x01
	str	r7,  [r6,  #0x08]	@ RCGC2    <- 0x01, bit 0, enab clk for Port A, UART0=PA0(Rx),PA1(Tx)
	ldr	r8,  =ioporta_base+0x500
	ldr	r9,  =ioporta_base+0x400
	ldr	r7,  =0x1ACCE551
	str	r7,  [r8,  #0x20]	@ GPIOLOCK <- PORT A, unlock AFSEL
	str	r3,  [r9,  #0x20]	@ GPIOAFSEL<- UART0 function selected for pins, (GPIO Chapt. p.169)
	str	r3,  [r8,  #0x1c]	@ GPIODEN  <- UART0 pins active (non tri-state), (GPIO Chapt. p.169)
	ldr	r8,  =0x035003
	ldr	r7,  [r6,  #0x04]
	orr	r7,  r7, r8
	str	r7,  [r6,  #0x04]	@ RCGC1    <- enable clock for UART0,1, I2C0,1, Timer0,1
	nop
	nop
	nop
	nop
	ldr	r8,  =uart0_base
	ldr	r7,  [r8,  #0x30]
	bic	r7,  r7, #0x01
	str	r7,  [r8,  #0x30]	@ UARTCTL  <- disable UART0
	ldr	r7,  =UART0_IDIV
	str	r7,  [r8,  #0x24]	@ UARTIBRD
	ldr	r7,  =UART0_FDIV
	str	r7,  [r8,  #0x28]	@ UARTFBRD
	set	r7,  #0x60
	str	r7,  [r8,  #0x2c]	@ UARTLCRH <- 8,N,1, no fifo
	set	r7,  #0x10
	str	r7,  [r8,  #0x38]	@ UARTIM   <- allow Rx interrupt to vic
	ldr	r9,  =0x0301
	ldr	r7,  [r8,  #0x30]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x30]	@ UARTCTL  <- enable UART0, Tx, Rx
	
	@ initialization of SD card pins

.ifdef	onboard_SDFT

	@ either:	
	@   SSI0:
	@     SSI pins on gpio A: PA.2,4,5 (port A is unlocked above, in UART initialization)
	@     CS  pin  on gpio A or D (eg. PD0 on EVB_LM3S6965)
	@ or:
	@   SSI1:
	@     SSI pins on gpio E: PE.0,2,3
	@     CS  pin  on gpio E (eg. PE1 on IDM_LM3S1958)
	ldr	r7,  =sd_spi
	ldr	r8,  =ssi0_base
	eq	r7,  r8			@ SSI is SSI0?
	ldr	r7,  [r6,  #0x04]	@ r7       <- RCGC1
	itE	eq
	orreq	r7,  r7, #0x10		@	if so,  r7 <- bit 4, for SSI0 clock enable
	orrne	r7,  r7, #0x20		@	if not, r7 <- bit 5, for SSI1 clock enable
	str	r7,  [r6, #0x04]	@ RCGC1    <- enable clock for SSI0 or SSI1
	ldr	r7,  [r6, #0x08]	@ r7       <- RCGC2
	itE	eq
	orreq	r7,  r7, #0x09		@	if so,  r7 <- bit 0 & 3, for ports A (SSI0) & D clock enable
	orrne	r7,  r7, #0x10		@	if not, r7 <- bit 4, for port E clock enable (SSI1)
	str	r7,  [r6, #0x08]	@ RCGC2    <- enable clock for Port(s)
	@ set SSI interface to low speed
	ldr	r8,  =sd_spi
	str	r0,  [r8,  #4]
  .ifndef TI_EvalBot
	set	r7,  #0x4000
  .else
	set	r7,  #0x6400
  .endif
	orr	r7,  r7, #0x07
	str	r7,  [r8, #0]
	str	r2,  [r8, #0x10]
	str	r2,  [r8, #0x04]
	@ configure chip-select pin and de-select card
	ldr	r8,  =sd_cs_gpio 
	ldr	r7,  [r8, #0x0400]
	orr	r7,  r7,  #(sd_cs >> 2)
	str	r7,  [r8, #0x0400]	@ GPIODIR  <- PA3 | PE1 is output
	add	r8,  r8,  #0x500
	ldr	r7,  [r8,  #0x1c]
	orr	r7,  r7,  #(sd_cs >> 2)
	str	r7,  [r8, #0x1c]	@ GPIODEN  <- PA3 | PE1 is digital
	ldr	r7,  [r8,  #0x10]
	orr	r7,  r7,  #(sd_cs >> 2)
	str	r7,  [r8,  #0x10]	@ GPIOPUR  <- PA3 | PE1 has weak pull-up
	ldr	r8,  =sd_cs_gpio
	set	r7,  #0xff
	str	r7,  [r8, #sd_cs]	@ de-select SD card (set PE1 high)
	@ configure SSI pins
	itE	eq
	seteq	r9,  #0x34		@	if so,  r9 <- PA2,4,5 are cfg as SSI for SSI0
	setne	r9,  #0x0d		@	if not, r9 <- PE0,2,3 are cfg as SSI for SSI1
	ldr	r8,  =sd_spi_gpio + 0x0500
	ldr	r7,  [r8,  #0x1c]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x1c]	@ GPIODEN  <- PA2,4,5 | PE0,2,3 are digital
	ldr	r7,  [r8,  #0x10]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x10]	@ GPIOPUR  <- PA2,4,5 | PE0,2,3 have weak pull-up
	sub	r8,  r8, #0x0100
	ldr	r7,  [r8,  #0x20]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x20]	@ GPIOAFSEL <- PA2,4,5 | PE0,2,3 are SSI
	
.endif	@  onboard_SDFT

	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	r8,  =i2c0_base		@ r8  <- I2C0 base address
	set	r7,  #0x30
	str	r7,  [r8,  #0x20]	@ I2C0MCR     <- enable master and slave units
	set	r7,  #mcu_id
	str	r7,  [r8, #i2c_address]	@ I2C0ADR <- set mcu address
	@ I2C pin initialization is missing here *****************************


.ifdef	native_usb

	ldr	r8,  =USB_LineCoding
	ldr	r7,  =115200
	str	r7,  [r8]		@ 115200 bauds
	set	r7,  #0x00080000
	str	r7,  [r8, #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	r8,  =USB_CHUNK
	str	r0,  [r8]		@ zero bytes remaining to send at startup
	ldr	r8,  =USB_ZERO
	str	r0,  [r8]		@ alternate interface and device/interface status = 0
	ldr	r8,  =USB_CONF
	str	r0,  [r8]		@ USB device is not yet configured
	ldr	r7,  [r6,  #0x08]	@ r7       <-contents of RCGC2
	orr	r7,  r7, #(1 << 16)	@ r7       <- bit 16, for USB0
	orr	r7,  r7, #(1 << 1)	@ r7       <- bit  1, for port B, (USB ID/VBUS on PB0/1)
	str	r7,  [r6,  #0x08]	@ RCGC2    <- enable clock for selected port(s)
	ldr	r9,  =ioportb_base+0x500
	ldr	r7,  [r9,  #0x1c]	@ r7 <- GPIODEN
	orr	r7,  r7, #1
	str	r7,  [r9,  #0x1c]	@ GPIODEN  <- analog function for USB pin PB1, digital for PB0
	ldr	r7,  [r9,  #0x28]	@ r7 <- GPIOAMSEL
	orr	r7,  r7, #2
	str	r7,  [r9,  #0x28]	@ GPIOAMSEL  <- analog function for USB pins PB0,1
	sub	r9,  r9, #0x100
	set	r7,  #1
	str	r7,  [r9]		@ GPIODIR  <- set PB0 to output (USB0ID)
	sub	r9,  r9, #0x400
	set	r7,  #0xff
	str	r7,  [r9, #(1<<(0+2))]	@ set PB0 high (device mode)
	@ configure peripheral
	ldr	r8,  =usb_base
	@ default on reset is device mode
	add	r9,  r8, #0x0400
	str	r3,  [r9, #0x1c]	@ USBGPCS  <- set device mode
	str	r2,  [r8, #0x0e]	@ USBEPIDX       <- select EP2
	strb	r3,  [r8, #0x63]	@ USB_Rx_FIFOSZ  <- 64 bytes for EP2 Rx
	set	r7,  #8
	strh	r7,  [r8, #0x66]	@ USB_Rx_FIFOADD <- EP2 Rx FIFO address start = 64
	str	r3,  [r8, #0x0e]	@ USBEPIDX       <- select EP3
	set	r7,  #3
	strb	r7,  [r8, #0x62]	@ USB_Tx_FIFOSZ  <- 64 bytes for EP3 Tx
	set	r7,  #16
	strh	r7,  [r8, #0x64]	@ USB_Tx_FIFOADD <- EP3 Tx FIFO address start = 128
	set	r7,  #0xff
	strh	r7,  [r8, #0x06]	@ USBTXIE  <- enable EP0-15 transmit interrupts
	set	r7,  #0xfe
	strh	r7,  [r8, #0x08]	@ USBRXIE  <- enable EP1-15 receive  interrupts
	@ reset and resume enabled by default on reset
	ldrb	r7,  [r8, #0x01]	@ r7       <- USBPOWER
	orr	r7,  r7, #0x40
	strb	r7,  [r8, #0x01]	@ USBPOWER <- set softcon

.endif

	@ enf of the hardware initialization
	set	pc,  lnk


/*------------------------------------------------------------------------------
@  LM_3S1000
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/
	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

_func_	
FlashInitCheck: @ return status of flash init enable/override gpio pin
		@ (eg. PG.3, PF.1 or PD.6 -- Up, Select or SW1 button) in rva (inverted)
	ldr	rva, =BOOTOVERRID_PRT		@ rva <- GPIO port where button is located
	add	rva, rva, #(1 << (BOOTOVERRID_BUT + 2))
	ldr	rva, [rva]			@ rva <- status of button input pin
	set	pc,  lnk			@ return

_func_	
wrtfla:	@ write to flash, sv2 = page address, sv4 = file descriptor
_func_	
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, sv3, sv5}	@ store scheme registers onto stack
	ldr	rva, =flashcr_base		@ rva <- flash registers base address
	vcrfi	sv3, sv4, 3			@ sv3 <- buffer address from file descriptor
	set	sv5, #0				@ sv5 <- 0, start offset for read/write
wrtfl0:	@ write #F_PAGE_SIZE bytes to flash
	ldr	rvb, [sv3, sv5]			@ rvb <- word to write, from buffer
	str	rvb, [rva, #0x04]		@ write word to flash data buffer (FMD)
	add	rvb, sv2, sv5			@ rvb <- destination address in FLASH
	str	rvb, [rva, #0x00]		@ write destination address to flash register (FMA)
	ldr	rvb, =0xA4420001		@ rvb <- flash write key with write bit
	str	rvb, [rva, #0x08]		@ initiate write via FMC (Flash Control)	
wrtfl1:	ldr	rvb, [rva, #0x08]		@ rvb <- FLASH status
	tst	rvb, #0x01			@ is write bit still asserted?
	bne	wrtfl1				@	if so,  jump to keep waiting
	add	sv5, sv5, #4			@ sv5 <- offset of next word
	eq	sv5, #F_PAGE_SIZE		@ done?
	bne	wrtfl0				@	if not, jump to keep writing
	@ exit
	ldmfd	sp!, {rva, rvb, sv3, sv5}	@ restore scheme registers from stack
	swi	run_normal			@ enable interrupts (user mode)
	set	pc,  lnk			@ return

_func_	
ersfla:	@ erase flash sector that contains page address in sv2
_func_	
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb}			@ store scheme registers onto stack
	ldr	rva, =flashcr_base		@ rva <- flash registers base address
	str	sv2, [rva, #0x00]		@ set page to erase in FMA register (Flash address)
	ldr	rvb, =0xA4420002		@ rvb <- flash write key with erase bit
	str	rvb, [rva, #0x08]		@ start erasure via FMC (Flash Control)
ersfl0:	ldr	rvb, [rva, #0x08]		@ rvb <- FLASH status
	tst	rvb, #0x02			@ is erase bit still asserted?
	bne	ersfl0				@	if so,  jump to keep waiting
	ldmfd	sp!, {rva, rvb}			@ restore scheme registers from stack
	swi	run_normal			@ enable interrupts (user mode)
.ifdef TI_EValBot
	add	sv2, sv2, #0x0400		@ sv2 <- start of next page in 4KB block
	tst	sv2, #0x0c00			@ done erasing 4 x 1KB pages?
	bne	ersfla				@	if not, jump to erase next 1KB page
	sub	sv2, sv2, #0x1000		@ sv2 <- restore original start page address
.endif
	set	pc,  lnk			@ return


	
/*------------------------------------------------------------------------------
@
@ 2- SD card low-level interface
@
@-----------------------------------------------------------------------------*/

.ifdef	onboard_SDFT

_func_	
sd_cfg:	@ configure spi speed (high), phase, polarity
	ldr	rva, =sd_spi
	set	rvb, #0
	str	rvb, [rva, #0x04]	@ SSI0CR1  <- disable SSI1
  .ifndef TI_EvalBot
	set	rvb, #0x0300
  .else
	set	rvb, #0x0500
  .endif
	orr	rvb, rvb, #0x07
	str	rvb, [rva]		@ SSI0CR0  <- PHA 0, POL 0, SPI mode, SCR 3
	set	rvb, #2
	str	rvb, [rva, #0x10]	@ SSI0CPSR <- set prescale to 2
	str	rvb, [rva, #0x04]	@ SSI0CR1  <- enable SSI1
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	ldr	rva, =sd_spi
	set	rvb, #0
	str	rvb, [rva, #0x04]	@ SSI0CR1  <- disable SSI1
  .ifndef TI_EvalBot
	set	rvb, #0x4000
  .else
	set	rvb, #0x6400
  .endif
	orr	rvb, rvb, #0x07
	str	rvb, [rva]		@ SSI0CR0  <- PHA 0, POL 0, SPI mode, SCR 3
	set	rvb, #2
	str	rvb, [rva, #0x10]	@ SSI0CPSR <- set prescale to 2
	str	rvb, [rva, #0x04]	@ SSI0CR1  <- enable SSI1
	set	pc,  lnk

_func_	
sd_sel:	@ select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	set	rvb, #0
	str	rvb, [rva, #sd_cs]	@ clear-pin
	set	pc,  lnk

_func_	
sd_dsl:	@ de-select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	set	rvb, #0xff
	str	rvb, [rva, #sd_cs]	@ set-pin
	set	pc,  lnk

_func_	
sd_get:	@ _sgb get sub-routine
	set	rvb, #0xff
_func_	
sd_put:	@ _sgb put sub-routine
	ldr	rva, =sd_spi
	ldr	rva, [rva, #spi_status]	@ ssta
	tst	rva, #spi_txrdy		@ sdtr
	beq	sd_put
	ldr	rva, =sd_spi
	and	rvb, rvb, #0xff
	str	rvb, [rva, #spi_thr]	@ sdtx (sdat)
sd_gpw:	@ wait
	ldr	rvb, [rva, #spi_status]	@ ssta
	tst	rvb, #spi_rxrdy		@ sdrr
	beq	sd_gpw
	ldr	rvb, [rva, #spi_rhr]	@ sdrx (sdat)
	set	pc, lnk

.endif	@ onboard_SDFT

.ltorg


/*------------------------------------------------------------------------------
@
@ 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/

_func_	
hwi2cr:	@ write-out additional address registers, if needed
_func_	
hwi2ni:	@ initiate i2c read/write, as master
_func_	
hwi2st:	@ get i2c interrupt status and base address
_func_	
i2c_hw_branch:	@ process interrupt
_func_	
hwi2we:	@ set busy status/stop bit at end of write as master
_func_	
hwi2re:	@ set stop bit if needed at end of read-as-master
_func_	
hwi2cs:	@ clear SI
_func_	
i2cstp:	@ prepare to end Read as Master transfer
_func_	
i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer or r12 (prologue)
_func_	
i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	set	pc,  lnk







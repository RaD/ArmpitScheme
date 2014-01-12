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

	@ allow 4-byte stack alignment (clear STKALIGN in CCR)
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	r10, =0xe000ed14
	str	r0,  [r10]
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

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

	@ initialization of USB configuration
	ldr	r7,  =USB_CONF
	str	r0,  [r7]		@ USB_CONF <- USB device is not yet configured

	@ initialize Cortex-M3/M4 SysTick Timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	r6,  =systick_base
	ldr	r7,  =SYSTICK_RELOAD
	str	r7,  [r6, #tick_load]	@ SYSTICK-RELOAD  <- value for 10ms timing at 50 or 80 MHz
	str	r0,  [r6, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	r5,  [r6, #tick_ctrl]	@ SYSTICK-CONTROL <- 5 = enabled, no interrupt, run from cpu clock
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ initialization of LED gpio pins
	ldr	r6,  =rcgc_base		@ r6       <- peripheral RCGC base adrs
	ldr	r10, =pr_base		@ r10      <- Periph. Ready base adrs
	ldr	r7,  [r6,  #0x08]	@ r7       <-contents of RCGCGPIO
	orr	r7,  r7, #ENABLE_PORTS	@ r7       <- bits for LED & Btn ports
	str	r7,  [r6,  #0x08]	@ RCGCGPIO <- enab clk for selec port(s)
hwprw0:	ldr	r8,  [r10, #0x08]	@ r8       <-contents of PR_GPIO
	eors	r8, r7, r8		@ all clocked peripherals ready?
	bne	hwprw0			@	if not, jump to keep waiting
	ldr	r8,  =LEDPINSEL
	ldr	r7,  =ALLLED
	str	r7,  [r8, #0x0400]	@ GPIODIR  <- all led directions set to output
	add	r8,  r8, #0x0500
	str	r7,  [r8, #0x08]	@ GPIODR8R <- all led have 8 mA drive
	str	r7,  [r8, #0x1c]	@ GPIODEN  <- all led pins active (non tri-state)
	
	@ initialization of boot-override button
	ldr	r8,  =BOOTOVERRID_PRT+0x500
	ldr	r7,  [r8,  #0x1c]
	orr	r7,  r7, #(1 << BOOTOVERRID_BUT)
	str	r7,  [r8,  #0x1c]	@ GPIODEN  <- set SELECT-button (PM4) as digital in (for boot bypass)
	set	r7,  #(1 << BOOTOVERRID_BUT)
	str	r7,  [r8,  #0x10]	@ GPIOPUR  <- add weak pull-up to SELECT-button (PM4)

	@ initialization of UART0 for 9600 8N1 operation
	ldr	r7,  [r6,  #0x08]	@ r7       <-contents of RCGCGPIO
	orr	r7,  r7, #(1 << 0)	@ r7       <- bit 0, for port A, (UART on PA0-Rx, PA1-Tx)
	str	r7,  [r6,  #0x08]	@ RCGCGPIO <- enable clock for selected port(s)
hwprw2:	ldr	r8,  [r10, #0x08]	@ r8       <-contents of PR_GPIO
	eors	r8, r7, r8		@ all clocked peripherals ready?
	bne	hwprw2			@	if not, jump to keep waiting
	ldr	r8,  =ioporta_base+0x500
	ldr	r9,  =ioporta_base+0x400
	ldr	r7,  =0x4C4F434B
	str	r7,  [r8,  #0x20]	@ GPIOLOCK <- PORT A, unlock AFSEL
	str	r3,  [r9,  #0x20]	@ GPIOAFSEL<- UART0 function selected for pins, (GPIO Chapt. p.169)
	str	r3,  [r8,  #0x1c]	@ GPIODEN  <- UART0 pins active (non tri-state), (GPIO Chapt. p.169)
	set	r7,  #0x03		@ r7       <- bits 0 and 1, for UART 0 and 1
	str	r7,  [r6,  #0x18]	@ RCGCUART <- enable clock for selected uart(s)
hwprw3:	ldr	r8,  [r10, #0x18]	@ r8       <-contents of PR_UART
	eors	r8, r7, r8		@ all clocked peripherals ready?
	bne	hwprw3			@	if not, jump to keep waiting
	ldr	r8,  =uart0_base
	ldr	r7,  [r8,  #0x30]
	bic	r7,  r7, #0x01
	str	r7,  [r8,  #0x30]	@ UARTCTL  <- disable UART0
	ldr	r7,  =UART0_IDIV
	str	r7,  [r8,  #0x24]	@ UARTIBRD <- set baud rate (integer)
	ldr	r7,  =UART0_FDIV
	str	r7,  [r8,  #0x28]	@ UARTFBRD <- set baud rate (fractional)
	set	r7,  #0x60
	str	r7,  [r8,  #0x2c]	@ UARTLCRH <- 8,N,1, no fifo
	set	r7,  #0x10
	str	r7,  [r8,  #0x38]	@ UARTIM   <- allow Rx interrupt to vic
	ldr	r9,  =0x0301
	ldr	r7,  [r8,  #0x30]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x30]	@ UARTCTL  <- enable UART0, Tx, Rx
	
	@ power-up timer0 and timer1
	set	r7,  #0x03		@ r7        <- bits 0 and 1, for Timer 0 and 1
	str	r7,  [r6,  #0x04]	@ RCGCTIMER <- enable clock for selected Timer(s)
	
	@ initialization of SD card pins

.ifdef	onboard_SDFT

	@     SSI pins on gpio A: PA.2,4,5 (port A is unlocked and powered above, in UART init)
	@     CS  pin  on gpio A
	set	r7,  #0x01		@ r7       <- bits 0 for SSI 0
	str	r7,  [r6,  #0x1c]	@ RCGCSSI  <- enable clock for selected SSI(s)
hwprw4:	ldr	r8,  [r10, #0x1c]	@ r8       <-contents of PR_SSI
	eors	r8, r7, r8		@ all clocked peripherals ready?
	bne	hwprw4			@	if not, jump to keep waiting
	@ set SSI interface to low speed
	ldr	r8,  =sd_spi
	str	r0,  [r8,  #4]
	set	r7,  #0x6400
	orr	r7,  r7, #0x07
	str	r7,  [r8, #0]
	str	r2,  [r8, #0x10]
	str	r2,  [r8, #0x04]
	@ configure chip-select pin and de-select card
	ldr	r8,  =sd_cs_gpio 
	ldr	r7,  [r8, #0x0400]
	orr	r7,  r7,  #(sd_cs >> 2)
	str	r7,  [r8, #0x0400]	@ GPIODIR  <- PA3 is output
	add	r8,  r8,  #0x500
	ldr	r7,  [r8,  #0x1c]
	orr	r7,  r7,  #(sd_cs >> 2)
	str	r7,  [r8, #0x1c]	@ GPIODEN  <- PA3 is digital
	ldr	r7,  [r8,  #0x10]
	orr	r7,  r7,  #(sd_cs >> 2)
	str	r7,  [r8,  #0x10]	@ GPIOPUR  <- PA3 has weak pull-up
	ldr	r8,  =sd_cs_gpio
	set	r7,  #0xff
	str	r7,  [r8, #sd_cs]	@ de-select SD card (set PA3 high)
	@ configure SSI pins
	set	r9,  #0x34		@ r9       <- PA2,4,5 are cfg as SSI for SSI0
	ldr	r8,  =sd_spi_gpio + 0x0500
	ldr	r7,  [r8,  #0x1c]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x1c]	@ GPIODEN  <- PA2,4,5 are digital
	ldr	r7,  [r8,  #0x10]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x10]	@ GPIOPUR  <- PA2,4,5 have weak pull-up
	sub	r8,  r8, #0x0100
	ldr	r7,  [r8,  #0x20]
	orr	r7,  r7,  r9
	str	r7,  [r8,  #0x20]	@ GPIOAFSEL <- PA2,4,5 are SSI
	
.endif	@  onboard_SDFT

	@ power-up i2c0, i2c1
	set	r7,  #0x03		@ r7       <- bits 0 and 1, for I2C 0 and 1
	str	r7,  [r6,  #0x20]	@ RCGCI2C  <- enable clock for selected I2C(s)
hwprw5:	ldr	r8,  [r10, #0x20]	@ r8       <-contents of PR_I2C
	eors	r8, r7, r8		@ all clocked peripherals ready?
	bne	hwprw5			@	if not, jump to keep waiting
	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	r8,  =i2c0_base		@ r6      <- I2C0 base address
	set	r7,  #0x30
	str	r7,  [r8,  #0x20]	@ I2C0MCR <- enable master and slave units
	set	r7,  #mcu_id
	str	r7,  [r8, #i2c_address]	@ I2C0ADR <- set mcu address
	@ I2C pin initialization is missing here *****************************

.ifdef	native_usb

	@
	@ interface bears similarity to OMAP35xx
	@
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

.ifdef EK_LM4F232

	ldr	r7,  [r6,  #0x08]	@ r7       <-contents of RCGCGPIO
	orr	r7,  r7, #(1 << 10)	@ r7       <- bit 10, for port L, (USB DP/DM on PL6/7)
	orr	r7,  r7, #(1 << 1)	@ r7       <- bit  1, for port B, (USB ID/VBUS on PB0/1)
	str	r7,  [r6,  #0x08]	@ RCGCGPIO <- enable clock for selected port(s)
hwprw6:	ldr	r8,  [r10, #0x08]	@ r8       <-contents of PR_GPIO
	eors	r8, r7, r8		@ all clocked peripherals ready?
	bne	hwprw6			@	if not, jump to keep waiting
	ldr	r9,  =ioportb_base+0x500
	ldr	r7,  [r9,  #0x28]	@ r7 <- GPIOAMSEL
	orr	r7,  r7, #3
	str	r7,  [r9,  #0x28]	@ GPIOAMSEL  <- analog function for USB pins PB0,1
	ldr	r9,  =ioportl_base+0x500
	ldr	r7,  [r9,  #0x28]	@ r7 <- GPIOAMSEL
	orr	r7,  r7, #(3 << 6)
	str	r7,  [r9,  #0x28]	@ GPIOAMSEL  <- analog function for USB pins PL6,7

.endif @ EK_LM4F232

.ifdef EK_LM4F120

	ldr	r7,  [r6,  #0x08]	@ r7       <-contents of RCGCGPIO
	orr	r7,  r7, #(1 << 3)	@ r7       <- bit  3, for port D, (DM,DP,VBUS on PD4,5,7)
	str	r7,  [r6,  #0x08]	@ RCGCGPIO <- enable clock for selected port(s)
hwprw6:	ldr	r8,  [r10, #0x08]	@ r8       <-contents of PR_GPIO
	eors	r8, r7, r8		@ all clocked peripherals ready?
	bne	hwprw6			@	if not, jump to keep waiting
	ldr	r9,  =ioportd_base+0x500
	ldr	r7,  [r9,  #0x28]	@ r7 <- GPIOAMSEL
	orr	r7,  r7, #(3 << 4)
	str	r7,  [r9,  #0x28]	@ GPIOAMSEL  <- analog function for USB pins PD4,5

.endif @ EK_LM4F120

	str	r1,  [r6,  #0x28]	@ RCGCUSB  <- enable clock for USB
hwprw7:	ldr	r8,  [r10, #0x28]	@ r8       <-contents of PR_USB
	eors	r8, r1, r8		@ all clocked peripherals ready?
	bne	hwprw7			@	if not, jump to keep waiting
	@ configure peripheral
	ldr	r8,  =usb_base
	@ default on reset is device mode
	add	r9,  r8, #0x0400
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
		@ (eg. PM4/Select or PF4/SW1 button) in rva (inverted)
	ldr	rva, =BOOTOVERRID_PRT	@ rva <- GPIO port of override button
	add	rva, rva, #(1 << (BOOTOVERRID_BUT + 2))
	ldr	rva, [rva]		@ rva <- status of boot override button
	set	pc,  lnk		@ return

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
	@ erase a second 1KB page (to take care of Rev. A1 vs A2 silicon errata)
	add	sv2, sv2, #0x0400		@ sv2 <- start of next page in 2KB block
	tst	sv2, #0x0400			@ done erasing 2 x 1KB pages?
	bne	ersfla				@	if not, jump to erase next 1KB page
	sub	sv2, sv2, #0x0800		@ sv2 <- restore original start page address
	@ return
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
	set	rvb, #0x0500
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
	set	rvb, #0x6400
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


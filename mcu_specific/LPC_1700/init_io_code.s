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
	set	fre,  #0
	set	sv1,  #1
	set	sv2,  #2
	set	sv3,  #3
	set	sv4,  #4
	set	sv5,  #5

	@ set FLASHCFG (formerly MAMTIM)
	ldr	rva,  =sys_ctrl
	ldr	rvb,  =0x403A			@ 5 clocks for flash read (up to 100MHz)
	str	rvb, [rva]
	add	rvb, rva, #0x0100

	@ enable the main oscillator
	set	rvc, #0x20
	str	rvc, [rvb, #0xa0]		@ SCS <- #x20 = enable main osc. 12MHz Xtal
moswt0:	@ wait for main oscillator to be ready
	ldr	rvc, [rvb, #0xa0]		@ rvc <- main osc. status
	tst	rvc, #0x40			@ is main osc. stable?
	beq	moswt0				@	if not, jump to keep waiting

	@ select clocks and dividers
	set	sv4, #0xaa
	set	rvc, #0x55
	str	sv1, [rva,  #0x80]	@ PLLCON  <-    1 == enable but disconnect PLL
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	rvc, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
	str	fre, [rva,  #0x80]	@ PLLCON  <-    0 == disable the disconnected PLL
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	rvc, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
	str	sv1, [rvb, #0x0c]	@ CLKSRCSEL <- 1, select Main Osc
	str	sv2, [rvb, #0x04]	@ CCLKCFG <- 2, CPU = 288 MHz/3 = 96 MHz
	str	sv5, [rvb, #0x08]	@ USBCLKCFG <- 5, USB = 288 MHz/6 = 48 MHz
	ldr	rvc, =0xaaaaaaaa
	str	rvc, [rvb, #0xa8]	@ PCLKSEL1 <- peripherals operate at 48 MHz (CPU/2)
	str	rvc, [rvb, #0xac]	@ PCLKSEL2 <- peripherals operate at 48 MHz (CPU/2)

	@ configure the PLL
	ldr	rvb, =PLL_PM_parms
	str	rvb, [rva,  #0x84]	@ PLLCFG  <- PLL_PM_parms
	str	sv1, [rva,  #0x80]	@ PLLCON  <-    1 == enable PLL
	set	sv4, #0xaa
	set	rvc, #0x55
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	rvc, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
pllwt0:	ldr	rvb, [rva,  #0x88]	@ rvb <- PLL status
	tst	rvb, #PLOCK_bit		@ is PLL locked?
	beq	pllwt0			@	if not, jump to keep waiting
	str	sv3, [rva,  #0x80]	@ PLLCON  <-    3 == connect PLL
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	rvc, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
	@ re-set modified common values
	set	sv4,  #4

	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	rva,  =i2c0_base		@ rva  <- I2C0 base address
	set	rvb,  #mcu_id
	str	rvb,  [rva, #i2c_address]	@ I2C0ADR <- set mcu address

	@ initialize Cortex-M3 SysTick Timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	ldr	rvb, =959999
	str	rvb, [rva, #tick_load]	@ SYSTICK-RELOAD  <- value for 10ms timing at 96 MHz
	str	fre, [rva, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	sv5, [rva, #tick_ctrl]	@ SYSTICK-CONTROL <- 5 = enabled, no interrupt, run from cpu clock
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ initialization of gpio pins
	ldr	rva, =LEDPINSEL
	str	fre, [rva]		@ LEDs are on P1.21-23 (213X) or P0.23-25 (2106) GPIO function
	ldr	rva, =LEDIO
	ldr	rvb, =ALLLED
	str	rvb, [rva,  #io_dir]	@ make all LED pins an output

	@ initialization of UART0 for 9600 8N1 operation
	ldr	rva,  =PINSEL0		@ rva  <- PINSEL0
	ldr	rvb, [rva, #0x40]
	bic	rvb, rvb, #0xF0
	orr	rvb, rvb, #0xA0
	str	rvb, [rva, #0x40]	@ PINMODE0     <- disable pull-up/down resistors on uart0 pins
	ldr	rvb, [rva]
	bic	rvb, rvb, #0xF0
	orr	rvb, rvb, #0x50
	str	rvb, [rva]		@ PINSEL0      <- Enable UART0 pins (P0.2 and P0.3)
	ldr	rva, =uart0_base
	str	sv1, [rva, #0x08]	@ U0FCR        <- Enable UART0, Rx trigger-level = 1 char
	set	rvb, #0x80
	str	rvb, [rva, #0x0c]	@ U0LCR        <- Enable UART0 divisor latch
	ldr	rvb, =UART0_DIV_L
	str	rvb, [rva]		@ U0DLL        <- UART0 lower byte of divisor for 9600 baud
	ldr	rvb, =UART0_DIV_H
	str	rvb, [rva, #0x04]	@ U0DLM        <- UART0 upper byte of divisor for 9600 baud
	str	sv3, [rva, #0x0c]	@ U0LCR        <- Disable UART0 divisor latch and set 8N1 parms
	str	sv1, [rva, #0x04]	@ U0IER        <- Enable UART0 RDA interrupt

	@ initialization of SD card pins

.ifdef	onboard_SDFT

  .ifdef sd_is_on_spi
	
	@ SPI0 interface pins P0.15, P0.17, P0.18 used for SCK0, MISO0, MOSI0
	@ sd_cs (gpio) used for CS (eg. P0.16)

	@ configure chip-select pin as gpio out, and de-select sd card
	ldr	rva, =sd_cs_gpio
	ldr	rvb, [rva, #io_dir]
	orr	rvb, rvb, #sd_cs
	str	rvb, [rva, #io_dir]	@ sd_cs_gpio, IODIR <- sd_cs pin set as output
	set	rvb, #sd_cs
	str	rvb, [rva, #io_set]	@ set sd_cs pin to de-select sd card
	@ configure other spi pins: P0.15,17,18 configured via pinsel0/1 as SPI legacy (cfg = #b11)
	ldr	rva, =PINSEL0
	ldr	rvb, [rva]
	bic	rvb, rvb, #0xC0000000
	orr	rvb, rvb, #0xC0000000	@ P0.15 <- #b11 for sck
	str	rvb, [rva]
	ldr	rva, =PINSEL1
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x003C
	orr	rvb, rvb, #0x003C	@ P0.17,18 <- #b11 (each) for miso, mosi
	str	rvb, [rva]
	@ configure spi mode for card initialization
	ldr	rva, =sd_spi
	set	rvb, #120
	str	rvb, [rva, #0x0c]	@ s0spccr clk <- 48 MHz/120 = 400 KHz
	set	rvb, #0x20
	str	rvb, [rva, #0x00]	@ s0spcr (control) #x00 master, 8-bit, POL=PHA=0
	
  .endif @ sd_is_on_spi

.endif	@ onboard_SDFT

	@ USB
	ldr	rva,  =USB_CONF
	str	fre,  [rva]		@ USB_CONF <- USB device is not yet configured
	@  Turn on USB PCLK in PCONP register (to power up USB subsystem)
	ldr	rva,  =sys_ctrl		@ rva  <- system ctrl for peripherals
	ldr	rvb,  [rva, #0xc4]	@ rvb <- value from PCONP
	orr	rvb,  rvb, #0x80000000
	str	rvb,  [rva, #0xc4]	@ PCONP <- power the USB RAM and clock, etc...

.ifdef	native_usb
	@ 10. initialization of USB device controller
	ldr	rva,  =USB_LineCoding
	ldr	rvb,  =115200
	str	rvb,  [rva]		@ 115200 bauds
	set	rvb,  #0x00080000
	str	rvb,  [rva,  #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	rva,  =USB_CHUNK
	str	fre,  [rva]		@ zero bytes remaining to send at startup
	ldr	rva,  =USB_ZERO
	str	fre,  [rva]		@ alternate interface and device/interface status = 0
	ldr	rva,  =USB_CONF
	str	fre,  [rva]		@ USB device is not yet configured
	@ see if USB is plugged in (if not, exit USB setup)
	@
	@  Vbus is P1.30 (not P0.14) on LPC17xx  ************************************
	@
	ldr	rva,  =PINSEL3
	ldr	rvb,  [rva, #0x40]
	bic	rvb,  rvb, #0x30000000
	orr	rvb,  rvb, #0x30000000	@ pull-down (otherwise, senses high?? because of 100nF Cap on board)
	str	rvb,  [rva, #0x40]	@ PINMODE3     <- disable pull-up/down resistor on P1.30/VBUS
	ldr	rvb,  [rva]
	bic	rvb,  rvb,  #0x30000000
	str	rvb,  [rva]		@ set P1.30 (VBUS) as GPIO
	@ wait for capacitor to discharge (default pull-up presumably charged it before pull-down)
	set	rvb, #0x800000
capwat:	subs	rvb, rvb, #1
	bne	capwat
	@ keep going
	ldr	rva, =io1_base
	ldr	rvb,  [rva, #io_state]
	tst	rvb,  #0x40000000	@ branch to resetC if P1.30 (VBUS) is not high
	@ temporary removal (if testing with uart, comment-out these 2 lines)
	it	eq
	seteq	pc,  lnk		@ i.e. exit hardare initialization if VBUS is not on
	@  3. Turn on USB device clock (see 9-2-1)  (4. we're using port1 for device = default)
	ldr	rva, =0x5000CFF4	@ rva <- USBClkCtrl
	set	rvb, #0x12		@ rvb <- DEV_CLK_EN, AHB_CLK_EN
	str	rvb, [rva]		@ enable USB clock and AHB clock
usbwt0:	ldr	rvb, [rva, #4]
	and	rvb, rvb, #0x12
	eq	rvb, #0x12
	bne	usbwt0
	@  4. Disable all USB interrupts.
	ldr	rva,  =USBIntSt
	str	fre,  [rva]
	ldr	rva,  =usb_base
	str	fre,  [rva,  #0x04]	@ USBDevIntEn
	str	fre,  [rva,  #0x34]	@ USBEpIntEn
	@  5. Configure pins
	@ enable USB D-, D+, USB_UP_LED1, USB-Connect (GPIO)
	ldr	rva, =PINSEL1
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x3C000000
	orr	rvb, rvb, #0x14000000
	str	rvb, [rva]		@ set P0.29, P0.30 to USB1(device) D-, D+
	@
	@  USB_CONNECT is P2.9 (not P1.19) on LPC17xx   *************************
	@
	ldr	rva, =PINSEL3
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x30
	orr	rvb, rvb, #0x10
	str	rvb, [rva]		@ set P1.18 to USB_UP_LED   @@@@@, P1.19 GPIO (USB_CONNECT)
	ldr	rvb,  [rva, #0x40]
	bic	rvb,  rvb, #0xF0
	orr	rvb,  rvb, #0x20
	str	rvb,  [rva, #0x40]	@ PINMODE3     <- disable pull-up/down on P1.18 (USB_UP_LED)
	@ configure USB_CONNECT P2.9 as GPIO out
	ldr	rva, =PINSEL4
	ldr	rvb,  [rva, #0x40]
	bic	rvb,  rvb, #0x0C0000
	orr	rvb,  rvb, #0x080000
	str	rvb,  [rva, #0x40]	@ PINMODE4     <- disable pull-up/down on P2.9 (USB CONNECT)
	ldr	rva, =io2_base
	ldr	rvb, [rva,  #io_dir]
	orr	rvb, rvb, #0x00000200
	str	rvb, [rva,  #io_dir]	@ config P2.9 as output gpio (for USB pseudo-connect function)
	@  6. Set Endpoint index and MaxPacketSize registers for EP0 and EP1, and wait until the
	@  EP_RLZED bit in the Device interrupt status register is set so that EP0/1 are realized.
	ldr	rva,  =usb_base
	str	fre,  [rva,  #0x48]	@ USBEpInd     - USBEpIndEP_INDEX <- 0
	set	sv4,  #0x08
	str	sv4,  [rva,  #0x4c]	@ USBMaxPSize  - MAXPACKET_SIZE <- 8
	set	sv5, #0x0100
usbwt1:	ldr	rvb,  [rva]		@ USBDevIntSt  - wait for dev_int_stat to have EP_RLZED_INT (= 0x100)
	tst	rvb,  sv5
	beq	usbwt1
	str	sv5, [rva, #0x08]	@ USBDevIntClr - clear EP_RLZD_INT
	str	sv1, [rva, #0x48]	@ USBEpInd     - EP_INDEX <- 1
	str	sv4, [rva, #0x4c]	@ USBMaxPSize  - MAXPACKET_SIZE <-8
usbwt2:	ldr	rvb, [rva]		@ USBDevIntSt  - wait for dev_int_stat to have EP_RLZED_INT (= 0x100)
	tst	rvb, sv5
	beq	usbwt2
	str	sv5, [rva, #0x08]	@ USBDevIntClr -- clear EP_RLZD_INT
	@  7. Clear, then Enable, all Endpoint interrupts
	ldr	sv4, =0xFFFFFFFF
	str	sv4, [rva,  #0x38]	@ USBEpIntClr  -- EP_INT_CLR = 0xFFFFFFFF;
	str	sv4, [rva,  #0x34]	@ USBEpIntEn   -- EP_INT_EN  = 0xFFFFFFFF;
	@  8. Clear Device Interrupts, then Enable DEV_STAT, EP_SLOW, EP_FAST, FRAME
	str	sv4, [rva,  #0x08]	@ USBDevIntClr -- DEV_INT_CLR = 0xFFFFFFFF;
	set	rvb,  #0x0c
	str	rvb,  [rva,  #0x04]	@ USBDevIntEn  -- rvb  <- 0x08 (DEV_STAT_INT) + 0x04 (EP_SLOW_INT)
	@ 10. Set default USB address to 0 and send Set Address cmd to the protoc engin (twice, see manual).
	set	rvc, lnk		@ r12 <- lnk, saved against wrtcmd
	ldr	rvb,  =0xD00500
	bl	wrtcmd			@ execute set-address command (0x0500 = write command)
	ldr	rvb,  =0x800100
	bl	wrtcmd			@ execute device enable on address zero (0x80) (0x0100 = write data)
	ldr	rvb,  =0xD00500
	bl	wrtcmd			@ execute set-address command (0x0500 = write command)
	ldr	rvb,  =0x800100
	bl	wrtcmd			@ execute device enable on address zero (0x80) (0x0100 = write data)
	@ 11. Set CON bit to 1 to make SoftConnect_N active (send Set Device Status cmd to protocol engine)
	ldr	rvb,  =0xFE0500
	bl	wrtcmd			@ execute get/set device status command
	ldr	rvb,  =0x010100
	bl	wrtcmd			@ execute set device status to connected (0x01)
	@ 12. Set AP_Clk high so that USB clock does not disconnect on suspend
	ldr	rvb,  =0xF30500	
	bl	wrtcmd			@ execute get/set mode command
	ldr	rvb,  =0x010100
	bl	wrtcmd			@ execute set mode to "no suspend" (0x01) (around p. 197, 225)
	@ exit once connected
	ldr	rva,  =USBIntSt
	set	rvb,  #0x80000000
	str	rvb,  [rva]		@ activate USB interupts (connect to VIC)
	set	lnk, rvc		@ lnk <- restored

.endif	@ native_usb
	@ end of the hardware initialization
	set	pc,  lnk


@------------------------------------------------------------------------------------------------
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@------------------------------------------------------------------------------------------------
	
@---------------------------------------------------------------------------------------
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@
@---------------------------------------------------------------------------------------

.ifdef Blueboard_1768
_func_
FlashInitCheck: @ return status of flash init enable/override gpio pin (P3.26) in rva
		@ pin low = boot override
	ldr	rva, =io3_base		@ rva <- address of gpio 3 base register
	ldr	rva, [rva, #io_state]	@ rva <- values of all P3.X
	and	rva, rva, #0x04000000	@ rva <- status of P3.26 only (return value)
	set	pc,  lnk
.endif

	
@---------------------------------------------------------------------------------------
@
@    FLASH I/O:	Internal Flash
@
@---------------------------------------------------------------------------------------


_func_
wrtfla:	@ write to file flash
_func_
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	@ on entry:	sv2 <- target flash page address
	@ on entry:	sv4 <- file descriptor with data to write
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	set	rvb, #20		@ rvb <- 20 = space for 5 IAP arguments (words)
	bl	zmaloc			@ rva <- address of free memory
	bic	fre, fre, #0x03		@ fre <- address of free cell for IAP arguments
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
    .ifdef LPC2478_STK
	ldr	fre, =0x4000F000	@ fre <- address for IAP arguments (60KB into on-chip RAM)
    .endif
	@ prepare flash sector for write
	bl	pgsctr			@ r2  <- sector number (raw int), from page address in r5 {sv2}
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	r0,  {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ copy RAM flash to FLASH
	ldmfd	sp,  {r0, r1, r4-r7}	@ restore r5 {sv2} = page address and r7 {sv4} = fil dscrptr frm stack
    .ifdef LPC2478_STK
	ldr	r0,  =0x4000F000	@ r0  <- address for IAP arguments (60KB into on-chip RAM)
    .endif
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)	
	set	r2,  #51		@ r2  <- IAP command 51 -- copy RAM to FLASH
	set	r3,  r5			@ r3  <- page address
	vcrfi	r4,  r7,  3		@ r4  <- address of buffer
    .ifdef LPC2478_STK
	add	r5,  r0, #24
	set	r6,  #F_PAGE_SIZE
wrtflp:	subs	r6,  r6, #4
	ldr	r7,  [r4, r6]
	str	r7,  [r5, r6]
	bne	wrtflp
	set	r4,  r5
    .endif
	set	r5,  #F_PAGE_SIZE	@ r5  <- number of bytes to write
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	r0,  {r2-r6}		@ store IAP arguments (command, page, source, numbytes, freq)
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	orr	fre, fre, #0x02		@ fre <- fre-ptr de-reserved
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

_func_
ersfla:	@ erase flash sector that contains page address in sv2
_func_
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	@ on entry:	sv2 <- target flash page address (whole sector erased)
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	set	rvb, #16		@ rvb <- 16 = space for 4 IAP arguments (words)
	bl	zmaloc			@ rva <- address of free memory
	bic	fre, fre, #0x03		@ fre <- address of free cell for IAP arguments
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
    .ifdef LPC2478_STK
	ldr	fre, =0x4000F000	@ fre <- address for IAP arguments (63KB into on-chip RAM)
    .endif
	@ prepare flash sector for write
	bl	pgsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	fre, {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ erase flash sector
	ldmfd	sp,  {fre, cnt, sv1-sv2}	@ restore page address in sv2 {r5} from stack
    .ifdef LPC2478_STK
	ldr	r0,  =0x4000F000	@ r0  <- address for IAP arguments (63KB into on-chip RAM)
    .endif
	bl	pgsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #52		@ r3  <- IAP command 52 -- erase FLASH sector(s)
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	fre, {r3-r6}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	orr	fre, fre, #0x02		@ fre <- fre-ptr de-reserved
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

go_iap:	ldr	r12, =IAP_ENTRY		@ r12 <- address of IAP routine
	bx	r12			@ jump to perform IAP


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
	ldr	rva, =sd_spi
	set	rvb, #8
	str	rvb, [rva, #0x0c]	@ s0spccr clk <- 48 MHz/8 = 6 MHz
	set	rvb, #0x20
	str	rvb, [rva, #0x00]	@ s0spcr (control) #x00 master, 8-bit, POL=PHA=0
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	ldr	rva, =sd_spi
	set	rvb, #120
	str	rvb, [rva, #0x0c]	@ s0spccr clk <- 48 MHz/120 = 400 KHz
	set	rvb, #0x20
	str	rvb, [rva, #0x00]	@ s0spcr (control) #x00 master, 8-bit, POL=PHA=0
	set	pc,  lnk

_func_	
sd_sel:	@ select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_clear]	@ clear-pin
	set	pc,  lnk
	
_func_	
sd_dsl:	@ de-select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_set]	@ set-pin
	set	pc,  lnk
	
_func_	
sd_get:	@ _sgb get sub-routine
	set	rvb, #0xff
_func_	
sd_put:	@ _sgb put sub-routine
	ldr	rva, =sd_spi
	and	rvb, rvb, #0xff
	str	rvb, [rva, #spi_thr]	@ sdtx (sdat)
sd_gpw:	@ wait
	ldr	rvb, [rva, #spi_status]	@ ssta
	tst	rvb, #spi_rxrdy		@ sdrr
	beq	sd_gpw
	ldr	rvb, [rva, #spi_rhr]	@ sdrx (sdat)
	set	pc, lnk

  .endif @ sd_is_on_spi

.endif	@ onboard_SDFT

@-------------------------------------------------------------------------------
@
@ 2- I2C Interrupt routine
@
@-------------------------------------------------------------------------------

.ifdef	include_i2c

_func_
hwi2cr:	@ write-out additional address registers, if needed
	@ modify interupts, as needed
	@ on entry:	sv5 <- i2c[0/1]buffer
	@ on entry:	rva <- i2c[0/1] base address (also I2CONSET)
	@ interrupts are disabled throughout
	set	rvb, #0			@ rvb <- 0 bytes to send (scheme int)
	tbsti	rvb, sv5, 3		@ store number of bytes to send in i2c buffer[12]
	@ initiate i2c read/write, as master
	swi	run_normal		@ re-enable interrupts
	set	rvb, #0x20		@ rvb <- i2c START command
	strb	rvb, [rva, #i2c_cset]	@ initiate bus mastering (write start to i2c[0/1]conset)
hwi2r0:	@ wait for mcu address and registers to have been transmitted
	swi	run_no_irq		@ disable interrupts
	tbrfi	rvb, sv5, 1		@ rvb <- data ready status from i2cbuffer[4]
	eq	rvb, #f			@ is i2c data ready = #f (i.e. addresses have been transmitted)
	it	eq
	seteq	pc,  lnk		@	if so, jump to continue
	swi	run_normal		@ re-enable interrupts
	b	hwi2r0			@ jump to keep waiting

_func_
hwi2ni:	@ initiate i2c read/write, as master
	@ on entry:	rva <- i2c[0/1] base address (also I2CONSET)
	set	rvb, #0x20		@ rvb <- i2c START command
	strb	rvb, [rva, #i2c_cset]	@ initiate bus mastering (write start to i2c[0/1]conset)
	set	pc,  lnk

_func_
hwi2st:	@ get i2c interrupt status and base address
	@ on exit:	rva <- i2c[0/1] base address
	@ on exit:	rvb <- i2c interrupt status
	ldrb	rvb, [rva, #i2c_status]	@ r7  <- I2C Status
	set	pc,  lnk

_func_
i2c_hw_branch:	@ process interrupt
	eq	rvb, #0x08		@ Master Read/Write -- bus now mastered		(I2STAT = 0x08)
	beq	i2c_hw_mst_bus
	eq	rvb, #0x18		@ Master Write -- slave has acknowledged adress	(I2STAT = 0x18)
	beq	i2c_wm_ini
	eq	rvb, #0x28		@ Master Write -- slave ok to receive data	(I2STAT = 0x28)
	beq	i2c_wm_put
	eq	rvb, #0x40		@ Master Read  -- slave ackn. adress (set nak?)	(I2STAT = 0x40)
	beq	i2c_rm_ini
	eq	rvb, #i2c_irm_rcv	@ Master Read  -- new byte received (set nak?)	(I2STAT = 0x50)
	beq	i2c_rm_get
	eq	rvb, #0x58		@ Master Read  -- last byte received		(I2STAT = 0x58)
	beq	i2c_rm_end
	eq	rvb, #0x60		@ Slave Read   -- address recognized as mine	(I2STAT = 0x60)
	beq	i2c_rs_ini
	eq	rvb, #i2c_irs_rcv	@ Slave Read   -- new data received		(I2STAT = 0x80)
	beq	i2c_rs_get
	eq	rvb, #0xA0		@ Slave Read   -- STOP or re-START received	(I2STAT = 0xA0)
	beq	i2c_rs_end
	eq	rvb, #0xA8		@ Slave Write  -- address recognized as mine	(I2STAT = 0xA8)
	beq	i2c_ws_ini
	eq	rvb, #0xB8		@ Slave Write  -- master requests byte		(I2STAT = 0xB8)
	beq	i2c_ws_put
	eq	rvb, #0xC0		@ Slave Write  -- NAK received from master/done	(I2STAT = 0xC0)
	beq	i2c_ws_end
	set	pc,  lnk

_func_
i2c_hw_mst_bus:	@ Reading or Writing as Master -- bus now mastered (I2STAT = 0x08)
	tbrfi	rva, sv2, 0		@ rva <- address of mcu to send data to (scheme int)
	lsr	rva, rva, #1		@ rva <- mcu-id as int -- note: ends with 0 (i.e. divide by 2)
	strb	rva, [sv3, #i2c_thr]	@ set address of mcu to send data to
	set	rva, #0x20		@ rva <- bit 5
	strb	rva, [sv3, #i2c_cclear]	@ clear START bit to enable Tx of target address
	b	i2cxit

_func_
hwi2we:	@ set busy status/stop bit at end of write as master
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	@ on entry:	rvb <- #f
	tbrfi	rva, sv2, 3		@ rva <- number of data bytes to send (raw int)
	eq	rva, #0			@ were we sendng 0 byts (i.e. rdng as mastr, done writng addrss byts)?
	itTT	ne
	tbstine rvb, sv2, 0		@	if not, set busy status to #f (transfer done)
	setne	rva, #0x10		@	if not, rva <-  STOP bit used to stop i2c transfer
	strbne	rva, [sv3, #i2c_cset]	@	if not, set  STOP bit to stop i2c transfer
	set	pc,  lnk
	
_func_
hwi2re:	@ set stop bit if needed at end of read-as-master
	set	rva, #0x014		@ rva <- bit4 | bit 2
	strb	rva, [sv3, #i2c_cset]	@ set STOP bit and reset AA to AK
	set	pc,  lnk
	
_func_
hwi2cs:	@ clear SI
	set	rva, #0x08		@ clear SI
	strb	rva, [sv3, #i2c_cclear]
	set	pc,  lnk

_func_
i2cstp:	@ prepare to end Read as Master transfer
	set	rva, #0x04		@ rva <- bit 2
	strb	rva, [sv3, #i2c_cclear]	@ set AA to NAK
	set	pc,  lnk
		
_func_
i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer or r12 (prologue)
	tbrfi	rva, sv2, 1		@ rva <- number of additional address bytes to send (scheme int)
	eq	rva, #i0		@ no more address bytes to send?
	itTT	eq
	tbrfieq rva, sv2, 3		@	if so,  rva <- number of data bytes to send (raw int)
	tbrfieq rvb, sv2, 4		@	if so,  rvb <- number of data bytes sent (raw int)
	eqeq	rva, rvb		@	if so,  are we done sending data?
	beq	i2c_wm_end		@		if so, jump to stop or restart x-fer and exit
	tbrfi	rvb, sv2,  1		@ r7  <- number of address bytes remaining to send (scheme int)
	eq	rvb, #i0		@ done sending address bytes?
	itTTT	ne
	subne	rvb, rvb, #4		@	if not, rvb <- updated num of addrss byts to snd (scheme int)
	tbstine rvb, sv2, 1		@	if not, store updatd num of addrss byts to snd in i2cbuffer[4]
	addne	rva, sv2, #8		@	if not, rva <- address of additional address byts in i2cbuffer
	lsrne	rvb, rvb, #2
	itTTT	ne
	ldrbne	rva, [rva, rvb]		@	if not, rva <- next address byte to send
	strbne	rva, [sv3, #i2c_thr]	@ put next data byte in I2C data register
	lslne	rvb, rvb, #2
	orrne	rvb, rvb, #i0
	bne	i2cxit
	set	pc,  lnk

_func_
i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	set	pc,  lnk

.endif

.ltorg	@ dump literal constants here => up to 4K of code before and after this point






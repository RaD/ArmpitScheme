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
hwinit:	@ hardware initialization

.ifdef run_in_bank2

	@ check if code is running from RAM bank 2 (option says it should)
	ldr	rva, =sys_config
	ldr	rvb, [rva, #0x0100]	@ rvb <- M4MEMMAP
	ldr	rvc, =RAMBOTTOM
	eq	rvb, rvc		@ is code running from heap RAM?
	bne	cdcskp			@	if not, jump to skip code copy and remap
	@ copy code to RAM bank 2
	ldr	rva, =0x10080000
	set	rvc, #0
cdclop:	@ code copy loop (64KB)
	ldr	rvb, [rvc]
	str	rvb, [rva, rvc]
	add	rvc, rvc, #4
	eq	rvc, #0x010000
	bne	cdclop
	@ remap bank 2 to address 0x00000000
	ldr	rva, =sys_config
	ldr	rvb, =0x10080000
	str	rvb, [rva, #0x0100]	@ M4MEMMAP <- 0x10080000 (RAM bank 2 remapped to 0x00)
cdcskp:	@ keep going

.endif

	@ pre-set common values
	set	fre,  #0
	set	sv1,  #1
	set	sv2,  #2
	set	sv3,  #3
	set	sv4,  #4
	set	sv5,  #5

	@ allow 4-byte stack (clear STKALIGN in CCR)
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	r10, =0xE000ED14
	str	r0,  [r10]
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ enable the XTal (12 MHz)
	ldr	rva, =CGU_base
	str	fre, [rva, #0x18]	@ XTAL_OSC_CTRL <- enable 12MHz Xtal

	@ enable PLL1 (bypass) and connect clocks
	ldr	rvb, =((6 << 24) | (16 << 16) | (0 << 8) | (1 << 7) | (0 << 6) | (0 << 1))
	str	rvb, [rva, #0x44]	@ PLL1_CTRL     <- pwrup PLL1, 17*12MHz=204MHz/2(pst) bypss
pllwt0:	ldr	rvb, [rva, #0x40]	@ rvb <- PLL1 status
	tst	rvb, #1			@ is PLL1 locked?
	beq	pllwt0			@	if not, jump to keep waiting
	@ connect M4_CLK to PLL1
	set	rvb, #(9 << 24)
	str	rvb, [rva, #0x6c]	@ BASE_M4_CLK    <- PLL1 (204 MHz)
	@ connect UART0_CLK to PLL1
	set	rvb, #(9 << 24)
	str	rvb, [rva, #0x9c]	@ BASE_UART0_CLK <- PLL1 (204 MHz)
	@ connect IDIVA to PLL1
	ldr	rvb, =((9 << 24) | (1 << 11) | (3 << 2))
	str	rvb, [rva, #0x48]	@ IDIVA_CTRL     <- src=PLL1, out=PLL1/4 = 51 MHz, autoblk
	@ connect IDIVB to PLL1
	ldr	rvb, =((9 << 24) | (1 << 11) | (4 << 2))
	str	rvb, [rva, #0x4c]	@ IDIVB_CTRL     <- src=PLL1, out=PLL1/5 = 40.8 MHz, autoblk
	@ connect SPIFI_CLK to IDIVB
	ldr	rvb, =((0x0d << 24) | (1 << 11))
	str	rvb, [rva, #0x70]	@ BASE_SPIFI_CLK <- IDIVB (40.8 MHz), autoblock
	@ connect IDIVE to IDIVA for SD-card
	ldr	rvb, =((0x0c << 24) | (1 << 11) | (1 << 2))
	str	rvb, [rva, #0x58]	@ IDIVE_CTRL     <- src=IDIVA, out=IDIVA/2 = 25.5 MHz, autoblk
	@ connect SDIO_CLK to IDIVE
	ldr	rvb, =((0x10 << 24) | (1 << 11))
	str	rvb, [rva, #0x90]	@ BASE_SDIO_CLK <- IDIVE (25.5 MHz or 400KHz), autoblock

	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	rva,  =i2c0_base		@ rva  <- I2C0 base address
	set	rvb,  #mcu_id
	str	rvb,  [rva, #i2c_address]	@ I2C0ADR <- set mcu address
	
	@ initialize Cortex-M3 SysTick Timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	ldr	rvb, =SYSTICK_RELOAD
	str	rvb, [rva, #tick_load]	@ SYSTICK-RELOAD  <- value for 10ms timing at 204 MHz
	str	fre, [rva, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	sv5, [rva, #tick_ctrl]	@ SYSTICK-CONTROL <- 5 = enabled, no intrpt, use cpu clock
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ initialization of LED gpio pins
	ldr	rva, =LEDPINSEL
	set	rvb, #0x10
	str	rvb, [rva, #0x2c]	@ set LED pin P2_11(A9) to GPIO1[11] function, no pull-up/down
	str	rvb, [rva, #0x30]	@ set LED pin P2_12(B9) to GPIO1[12] function, no pull-up/down
	ldr	rva, =LEDIO
	ldr	rvb, =ALLLED
	str	rvb, [rva,  #io_dir]	@ make all LED pins have output direction
	
	@ initialization of button gpio pins
	ldr	rva, =SCU_SFSP2_n	@ button is on P2_7(C10)->GPIO0[7]
	set	rvb, #0x50
	str	rvb, [rva, #0x1c]	@ button pin <- GPIO, no pull-up/down, with input buffer
	
	@ initialization of UART0 for 9600 8N1 operation
	ldr	rva, =SCU_SFSP2_n	@ uart0 (as used by ISP and DFU) is on P2_0(G10) and P2_1(G7)
	str	fre, [rva, #0x00]	@ disconnect uart0 from P2_0 (if needed)
	str	fre, [rva, #0x04]	@ disconnect uart0 from P2_1 (if needed)
	ldr	rva, =SCU_SFSP6_n	@ uart0 header pins on Xplorer: P6_4(F6)->TXD, P6_5(F9)->RXD
	set	rvb, #0x12
	str	rvb, [rva, #0x10]	@ set P6_4 pin to uart0 TXD func, no pull-up/down
	set	rvb, #0x52
	str	rvb, [rva, #0x14]	@ set P6_5 pin to uart0 RXD func, no pull-up/down, input buff
	ldr	rva, =uart0_base
	str	sv1, [rva, #0x08]	@ U0FCR        <- Enable UART0, Rx trigger-level = 1 char
	set	rvb, #0x80
	str	rvb, [rva, #0x0c]	@ U0LCR        <- Enable UART0 divisor latch
	ldr	rvb, =UART0_DIV_L
	str	rvb, [rva]		@ U0DLL        <- UART0 lower byte of div for sel. baud rate
	ldr	rvb, =UART0_DIV_H
	str	rvb, [rva, #0x04]	@ U0DLM        <- UART0 upper byte of div for sel. baud rate
	str	sv3, [rva, #0x0c]	@ U0LCR        <- Disable UART0 div latch and set 8N1 parms
	str	sv1, [rva, #0x04]	@ U0IER        <- Enable UART0 RDA interrupt

	@ initialize SPIFI, exit read mode (if needed)
	ldr	rva, =SCU_SFSP3_n	@ SPIFI is on P3_3-P3_8 (mode=3)
	set	rvb, #0xe3
	str	rvb, [rva, #0x20]	@ set pin P3_8 to SPIFI CS,    pull-up, fast, input buff
	set	rvb, #0xf3
	str	rvb, [rva, #0x0c]	@ set pin P3_3 to SPIFI SCK,   no pull-u/d, fast, input buff
	str	rvb, [rva, #0x10]	@ set pin P3_4 to SPIFI SIO3,  no pull-u/d, fast, input buff
	str	rvb, [rva, #0x14]	@ set pin P3_5 to SPIFI SIO2,  no pull-u/d, fast, input buff
	str	rvb, [rva, #0x18]	@ set pin P3_6 to SPIFI MISO/SIO1, no pull-u/d, fast, in. buff
	str	rvb, [rva, #0x1c]	@ set pin P3_7 to SPIFI MOSI/SIO0, no pull-u/d, fast, in. buff
	ldr	rva, =spifi_base
	ldr	rvb, =0x001fff15
	str	rvb, [rva, #spifi_ctrl]	@ SPIFICTRL    <- set FLASH size to 4MB (32Mbit)

.ifdef	upload_via_DFU

	set	sv5, lnk
	ldr	rva, =upload_flag	@ rva <- address of code upload flag
	ldr	rvb, [rva]		@ rvb <- flag value
	eq	rvb, #0			@ is this the initial upload
	it	eq
	bleq	cp2spf			@	if so,  jump to copy code to SPIFI
	set	lnk, sv5
	set	sv5, #5

.endif

	@ initialize SPIFI -- initiate read mode
	set	sv3, lnk
	ldr	rva, =spifi_base
	bl	spfrdm
	set	lnk, sv3
	set	sv3, #3			@ sv3 <- restore pre-set common value

	@ initialization of SD card pins

.ifdef	onboard_SDFT

  .ifdef sd_is_on_mci

	@ SD_MMC pins:	P1_6 (SD_CMD, mode=7), P1_9 to P1_12 (SD_D0 to SD_D3, mode=7)
	@ 		CLK2 (SD_CLK, mode=4)
	ldr	rva, =SCU_SFSP1_n	@ SD-MMC is on P1_n (mostly)
	set	rvb, #0xf7		@ rvb <- no pull-up/down, fast, input buffer, mode 7
	str	rvb, [rva, #0x18]	@ set pin P1_6  to SD_CMD,	no pull-u/d, fast, input buff
	str	rvb, [rva, #0x24]	@ set pin P1_9  to SD_D0,	no pull-u/d, fast, input buff
	str	rvb, [rva, #0x28]	@ set pin P1_10 to SD_D1,	no pull-u/d, fast, input buff
	str	rvb, [rva, #0x2c]	@ set pin P1_11 to SD_D2,	no pull-u/d, fast, input buff
	str	rvb, [rva, #0x30]	@ set pin P1_12 to SD_D3,	no pull-u/d, fast, input buff
	ldr	rva, =SCU_SFSCLKn	@ rva <- CLK0-3 base address
	set	rvb, #0xb4		@ rvb <- no pull-up/down, fast, mode 4
	str	rvb, [rva, #0x08]	@ set pin CLK2 to SD_CLK,       no pull-u/d, fast
	@ set SD clock parameters into peripheral
	ldr	rva, =sd_mci
	set	rvb, #0
	str	rvb, [rva, #0x08]	@ CLKDIV0 <- 0 (apparently the only setting available)
	str	rvb, [rva, #0x10]	@ CLKSRC  <- clock source is DIV0 (id.)
	set	rvb, #1			@ <- NOTE: sd-init hangs if this bit is not set
	str	rvb, [rva, #0x10]	@ CLKENA  <- enable clock with low power mode (off when idle)
	set	rvb, #(1 << 21)		@ rvb     <- update clock only bit
	orr	rvb, rvb, #(1 << 31)	@ rvb     <- cmd start bit
	str	rvb, [rva, #0x2c]	@ CMD     <- update clock
hwisd0:	@ wait for CUI to load command
	ldr	rvb, [rva, #0x2c]	@ rvb <- CMD
	tst	rvb, #(1 << 31)		@ cmd loaded?
	bne	hwisd0
	
  .endif @ sd_is_on_mci
  
.endif	@ onboard_SDFT

	@ USB initialization
	ldr	rva,  =USB_CONF
	str	fre,  [rva]		@ USB_CONF <- USB device is not yet configured

.ifdef	native_usb

	@ enable PLL0USB
	ldr	rva, =CGU_base
	ldr	rvb, =0x07000800
	str	rvb, [rva, #0x60]	@ BASE_USB0_CLK  <- set clock to autoblock, source = PLL0USB
	ldr	rvb, [rva, #0x20]	@ rvb            <- PLL0USB_CTRL
	orr	rvb, rvb, #0x03
	bic	rvb, rvb, #0x10
	str	rvb, [rva, #0x20]	@ PLL0USB_CTRL   <- PLL0USB disabled
	ldr	rvb, =0x06167ffa
	str	rvb, [rva, #0x24]	@ PLL0USB_MDIV   <- values for 480 MHz from XTal
	ldr	rvb, =0x00302062
	str	rvb, [rva, #0x28]	@ PLL0USB_NP_DIV <- values for 480 MHz from XTal
	ldr	rvb, =0x06000808
	str	rvb, [rva, #0x20]	@ PLL0USB_CTRL   <- PLL0USB enabled, XTal source, autoblock
pll0wt:	@ wait for PLL0USB to lock
	ldr	rvb, [rva, #0x1c]	@ rvb            <- PLL0USB_STAT
	tst	rvb, #1			@ is PLL0USB locked?
	beq	pll0wt			@	if not, jump to keep waiting
	ldr	rvb, [rva, #0x20]	@ rvb <- PLL0USB_CTRL
	orr	rvb, rvb, #0x10
	str	rvb, [rva, #0x20]	@ PLL0USB_CTRL   <- PLL0USB connect output clock
	@ power-up the PHY
	ldr	rva, =sys_config
	ldr	rvb, [rva, #0x04]	@ rvb   <- CREG0
	bic	rvb, rvb, #(1 << 5)
	str	rvb, [rva, #0x04]	@ CREG0 <- USB0 PHY enabled
	@ initialization of USB variables
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
	@ reset
	ldr	rva, =usb_base
	set	rvb, #0x02
	str	rvb, [rva, #0x40]	@ USB_CMD  <- reset
usrswt:	ldr	rvb, [rva, #0x40]
	tst	rvb, #2
	bne	usrswt
	ldr	rva, =usb_base
  .ifndef has_HS_USB
	set	rvb, #(1<<24)
	str	rvb, [rva, #0x84]	@ USB_PORTSC1 <- run at full-speed only (no High-speed)
  .else
	ldr	rvc, =USB_FSHS_MODE
	set	rvb, #0
	str	rvb, [rvc]		@ indicate that USB starts in FS mode
  .endif
	set	rvb, #0x08
	str	rvb, [rva, #0xa4]	@ OTGSC  <- device mode pull-down
	set	rvb, #0x02
	str	rvb, [rva, #0xa8]	@ USBMODE  <- device mode
	@ initialization of USB device controller
	ldr	rva, =usb_base
	ldr	rvb, =usb_queue_heads
	str	rvb, [rva, #0x58]	@ EPLISTADDRESS <- set adddress for Queue Heads
	set	rvb, #0x02
	str	rvb, [rva, #0xa8]	@ USBMODE  <- set mode to Device, with lockouts
	ldr	rvb, =0x00800080
	str	rvb, [rva, #0xc0]	@ EPCTRL0  <- enable EP 0 Rx, Tx, as control EP
	ldr	rvc, =usb_queue_heads	@ rvc <- Queue Heads start address
	ldr	rvb, =0x20088000	@ rvb <- no ZLT, 8-byte max packet, interrupt on SETUP
	str	rvb, [rvc, #0x00]	@ QH0 OUT <- set capabilities
	str	rvb, [rvc, #0x40]	@ QH0 IN  <- set capabilities
	set	rvb, #0
	str	rvb, [rvc, #0x04]	@ QH0 OUT <- set current dTD
	str	rvb, [rvc, #0x44]	@ QH0 IN  <- set current dTD
	set	rvb, #1
	str	rvb, [rvc, #0x08]	@ QH0 OUT <- set tail
	str	rvb, [rvc, #0x48]	@ QH0 IN  <- set tail
  .ifdef debug_usb
	@ DEBUG RAM SPACE
	set	rvc, #0x20000000
	set	rvb, #4
	str	rvb, [rvc]
  .endif
	set	rvb, #0x41
	str	rvb, [rva, #0x48]	@ USB_INTR <- enable usb interrupt, reset int
	set	rvb, #0x01
	str	rvb, [rva, #0x40]	@ USB_CMD  <- enable usb (run)
	
.endif	@ native_usb

	@ end of the hardware initialization
	set	pc,  lnk


/*------------------------------------------------------------------------------
@
@ code to copy initial upload from RAM into SPIFI
@
@-----------------------------------------------------------------------------*/

.ifdef	upload_via_DFU

.balign	4
upload_flag:
	.word	0x00000000		@ initial code upload flag

_func_	
cp2spf:	@ copy code from RAM to SPIFI (also update intial-upload flag and add boot header)
	@ image header will be: #x1a, #x3f, #x7f, #x00, 8 * #x00, 4 * #xff
	@ 64 KB will be written to SPIFI (16-byte header + 64KB-16bytes code)
	@ connection to SPIFI is via SSP0 interface (regular SPI, not QUAD)
	@ FLASH chip is Spansion: S25FL032P
	@ on entry:	rva <- address of code upload flag (RAM)
	@ on entry:	rvb <- 0x00000000 = initial code upload flag
	mvn	rvb, rvb		@ rvb <- inverted initial upload flag (for future boots)
	str	rvb, [rva]		@ store inverted flag in code-RAM (for copy)
	set	sv4, lnk
	bl	gldon
	@ erase 64KB sector at 0x000000
	set	sv2, #0
	bl	ersfla
	@ copy the header and code
	ldr	rva, =spifi_base
	bl	spfcmm			@ enter SPIFI command mode	
	set	sv2, #0			@ sv5 <- destination page address
cp2spl:	@ loop over addresses
	ldr	rva, =LEDIO
	set	rvb, #REDLED
	str     rvb, [rva, #io_toggle]	@ toggle blue  LED
	@ issue Page Program (PP) command
	ldr	rva, =spifi_base
	bl	spfwre			@ write-enable the SPIFI
	str	sv2, [rva, #spifi_addr]	@ SPFIADDR     <- set destination address
	ldr	rvb, =0x02808100
	str	rvb, [rva, #spifi_cmd]	@ SPFICMD      <- command to write 256 bytes to dest (PP)
	@ check if header needs inserting here (page 0)
	eq	sv2, #0
	bne	cp2spr
	@ copy the header
	ldr	rvb, =0x007f3f1a
	str	rvb, [rva, #spifi_dat]
	set	rvb, #0
	str	rvb, [rva, #spifi_dat]
	str	rvb, [rva, #spifi_dat]
	mvn	rvb, rvb
	str	rvb, [rva, #spifi_dat]
	set	sv2, #16
cp2spr:	@ loop over bytes in page
	sub	rvc, sv2, #16
	ldr	rvb, [rvc]
	str	rvb, [rva, #spifi_dat]
	add	sv2, sv2, #4
	tst	sv2, #0xff
	bne	cp2spr
	bl	spfcwt			@ wait for completion (i.e. command sent)
	ldr	rvb, =0x5204000
	bl	spfcmd			@ SPFICMD      <- read flash status (CMD=rvb=#x05) until WIP=0
	ldrb	rvb, [rva, #spifi_dat]
	@ page is done, check if whole code+header is copied
	eq	sv2, #0x010000
	bne	cp2spl
	@ done -- turn green LED on, blue LED off, and return
	bl	gldoff
	bl	rldon
	set	lnk, sv4
	set	sv2, #2
	set	sv3, #3
	set	sv4, #4
	set	pc,  lnk

.endif

/*------------------------------------------------------------------------------
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/
	
/*------------------------------------------------------------------------------
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@
@-----------------------------------------------------------------------------*/

.ifdef LPC4330_Xplorer
_func_
FlashInitCheck: @ return status of flash init enable/override gpio pin (P2_7 == GPIO0[7]) in rva
		@ pin low = boot override
	ldr	rva, =io0_base		@ rva <- address of GPIO0[n] base register
	ldr	rva, [rva, #io_state]	@ rva <- values of all GPIO0[n] pins
	and	rva, rva, #(1 << 7)	@ rva <- status of GPIO0[7] only (return value)
	set	pc,  lnk
.endif

	
/*------------------------------------------------------------------------------
@
@    FLASH I/O:	Internal Flash
@
@-----------------------------------------------------------------------------*/


_func_
wrtfla:	@ write to file flash
.ifdef	SHARED_LIB_FILE
_func_
libwrt:	@ write to on-chip lib flash (if lib shares on-chip file flash)
.endif
	@ on entry:	sv2 <- target flash page address
	@ on entry:	sv4 <- file descriptor with data to write
	@ preserves:	all
	stmfd	sp!, {rva, rvb, sv2, rvc, lnk} @ store scheme registers onto stack
	ldr	rva, =spifi_base
	bl	spfcmm			@ enter SPIFI command mode	
	bl	spfwre			@ write-enable the SPIFI
	bic	sv2, sv2, #0xff
	str	sv2, [rva, #spifi_addr]	@ SPFIADDR     <- set destination address
	ldr	rvb, =0x02808100
	str	rvb, [rva, #spifi_cmd]	@ SPFICMD      <- command to write 256 bytes to dest (PP)
	vcrfi	sv2, sv4, 3		@ sv2 <- address of buffer
	set	rvc, #0
wrtflp:	@ loop
	ldr	rvb, [sv2, rvc]
	str	rvb, [rva, #spifi_dat]
	add	rvc, rvc, #4
	eq	rvc, #F_PAGE_SIZE
	bne	wrtflp
	bl	spfcwt			@ wait for completion (i.e. command sent)
	ldr	rvb, =0x5204000
	bl	spfcmd			@ SPFICMD      <- read flash status (CMD=rvb=#x05) until WIP=0
	ldrb	rvb, [rva, #spifi_dat]
	bl	spfrdm			@ return to SPIFI read mode
	ldmfd	sp!, {rva, rvb, sv2, rvc, lnk}	@ restore scheme registers from stack
	set	pc,  lnk		@ return

_func_
ersfla:	@ erase flash sector that contains page address in sv2
.ifdef	SHARED_LIB_FILE
_func_
libers:	@ erase on-chip lib flash sector (if lib shares on-chip file flash)
.endif
	@ on entry:	sv2 <- target flash page address (whole sector erased)
	@ preserves:	all
	stmfd	sp!, {rva, rvb, sv2, rvc, lnk} @ store scheme registers onto stack
	ldr	rva, =spifi_base
	bl	spfcmm			@ enter SPIFI command mode
	bl	spfwre			@ write-enable the SPIFI
	bic	sv2, sv2, #0x00ff
	bic	sv2, sv2, #0xff00
	str	sv2, [rva, #spifi_addr]	@ SPFIADDR     <- set destination sector address
	ldr	rvb, =0xd8800000
	bl	spfcmd			@ SPFICMD      <- command to erase full sector (SE)
	ldr	rvb, =0x5204000
	bl	spfcmd			@ SPFICMD      <- read flash status (CMD=rvb=#x05) until WIP=0
	ldrb	rvb, [rva, #spifi_dat]
	bl	spfrdm			@ return SPIFI to read mode
	ldmfd	sp!, {rva, rvb, sv2, rvc, lnk}		@ restore scheme registers from stack
	set	pc,  lnk		@ return


_func_
spfcmm:	@ enter SPIFI command mode
	@ on entry:	rva <- SPIFI_base
	@ modifies:	rvb, rvc
	set	rvc, lnk
	set	rvb, #0x10000
spfcw3:	@ wait for CS
	subs	rvb, rvb, #1
	bne	spfcw3
	ldr	rvb, =0x5204000
	bl	spfcmd			@ SPIFICMD      <- read status (CMD=rvb=#x05) until WIP=0
	ldrb	rvb, [rva, #spifi_dat]
	set	lnk, rvc
	set	pc,  lnk		@ return
	
_func_
spfrdm:	@ enter SPIFI read mode
	@ on entry:	rva <- SPIFI_base
	@ modifies:	rvb, rvc
	set	rvc, lnk
	set	rvb, #0
	str	rvb, [rva, #spifi_addr]	@ SPIFIADDR     <- set address to 0
	ldr	rvb, =0xa5a5a5a5
	str	rvb, [rva, #spifi_idat]	@ SPIFIDATINTM  <- set read mode around CS# assertions
	ldr	rvb, =0xeb133fff
	str	rvb, [rva, #spifi_mcmd]	@ SPIFIDATINTM  <- set read mode
	set	lnk, rvc
	set	pc,  lnk

_func_
spfwre:	@ write-enable the SPIFI
	@ on entry:	rva <- SPIFI_base
	@ modifies:	rvb, rvc
	set	rvc, lnk
	ldr	rvb, =0x06200000
	bl	spfcmd			@ SPIFICMD      <- write enable (CMD=rvb=#x06)
	ldr	rvb, =0x05204009
	bl	spfcmd			@ SPIFICMD      <- read status (CMD=rvb=#x05) until WREN=1
	ldrb	rvb, [rva, #spifi_dat]
	set	lnk, rvc
	set	pc,  lnk

_func_
spfcmd:	@ perform a SPIFI command, wait for completion
	@ on entry:	rva <- SPIFI_base
	@ on entry:	rvb <- command to execute
	@ modifies:	rvb
	str	rvb, [rva, #spifi_cmd]	@ SPIFICMD      <- command
_func_
spfcwt:	@ wait on command complete
	@ [internal entry] (also)
	ldr	rvb, [rva, #spifi_stat]
	tst	rvb, #2
	bne	spfcwt
	set	pc,  lnk


.ltorg	@ dump literal constants here => up to 4K of code before and after this point


/*------------------------------------------------------------------------------
@
@ 2- SD card low-level interface
@
@-----------------------------------------------------------------------------*/

.ifdef	onboard_SDFT

  .ifdef sd_is_on_mci

_func_
_sgb:	@ [internal only]
	@ sd-get-block internal func
	@ on entry:  rvc <- block number to be read (scheme int)
	@ on entry:  sv3 <- buffer in which to store block data (scheme bytevector)
	@ on exit:   sv3 <- updated buffer
	@ modifies:  sv3, sv5, rva, rvb, rvc
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
_func_
sgb_sr:	@ start/restart transfer
	@ prepare for read-block
	bl	sd_pre			@ prepare mci (clear stat bits, set byte count)
	set	rvb, rvc		@ rvb <- block number to read
	bl	sd_arg			@ set arg (block number) in CMDARG
	@ send cmd 17 (read single block)
	set	rvb, #17		@ rvb <- read single block command
	orr	rvb, rvb, #(1 << 9)	@ rvb <- data expected, read single block mode
	bl	sd_cmd			@ set command
	@ check for error, if so, restart
	eq	rva, #0			@ command set successfully?
	itT	ne
	ldrne	rvc, [rva, #0x28]	@ 	if not, rvc <- CMDARG (block address)
	lsrne	rvc, rvc, #7		@	if not, rvc <- block address shifted for retry
	bne	sgb_sr			@	if not, jmp to retry
	@ get and save data
	ldr	rva, =sd_mci		@ rva <- mci address
	set	rvc, #0			@ rvc <- initial buffer offset/data count
	adr	lnk, sgb_sr		@ lnk <- address for retry (via sd_cm1)
sgb_gd:	@ get-data loop
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	bic	rvb, rvb, #0x3c		@ rvb <- status with cleared non-error bits
	bic	rvb, rvb, #(1 << 10)	@ rvb <- status with cleared HTO (starvation) bit
	bic	rvb, rvb, #(1 << 14)	@ rvb <- status with cleared acmd done bit
	eq	rvb, #0			@ any non-expected errors?
	itT	ne
	ldrne	rvc, [rva, #0x28]	@	if so,  rvc <- CMDARG (block address)
	lsrne	rvc, rvc, #7		@	if so,  rvc <- bloack address shifted for restart
	bne	sd_cm1			@	if so,  jump to restart
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	bic	rvb, rvb, #0x08		@ rvb <- status with DTO bit cleared
	str	rvb, [rva, #0x44]	@ clear set status bits, except DTO
	tst	rvb, #0x0420		@ is data available?
	bne	sgb_g0			@	if so,  jump to read it
	ldr	rvb, [rva, #0x48]	@ rvb <- STATUS
	lsr	rvb, rvb, #17		@ rvb <- status shifted
	and	rvb, rvb, #0x3f		@ rvb <- number of words in FIFO
	eq	rvb, #0			@ FIFO empty?
	beq	sgb_gd			@	if so,  jump to keep waiting
sgb_g0:	@ read a data word and update count
	ldr	rvb, [rva, #0x0100]	@ rvb <- word from FIFO
	str	rvb, [sv3, rvc]		@ store word in buffer
	add	rvc, rvc, #4		@	if not, rvc <- updated count
	eq	rvc, #512		@ done reading data?
	bne	sgb_gd			@	if not, jump to read next word
sgb_g1:	@ wait for DTO bit (otherwise next transfer hangs on STATUS read)
	ldr	rvb, [rva, #0x44]	@ rvb     <- RINTSTS
	tst	rvb, #0x08		@ is DTO (transfer done) bit set?
	beq	sgb_g1			@	if not, jump to wait for it
	set	rvb, #0x08		@ rvb     <- DTO bit
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear DTO bit
	@ return
	orr	lnk, sv5, #lnkbit0
	set	pc,  lnk

	
	@ 4-bit bus interface
_func_
_spb:	@ [internal only]
	@ sd-put-block internal func
	@ on entry:  rvc <- block number to be written (scheme int)
	@ on entry:  sv3 <- buffer with block data to write to sd (scheme bytevector)
	@ modifies:  sv5, rva, rvb, rvc
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
_func_
spb_sr:	@ start/restart transfer
	@ prepare for write-block
	bl	sd_pre			@ prepare mci (clear stat bits, set byte count)
	set	rvb, rvc		@ rvb <- block number to write
	bl	sd_arg			@ set arg (block number) in CMDARG
	@ pre-load the FIFO, if needed (32 words)
	ldr	rva, =sd_mci		@ rva <- mci address
	ldr	rvb, [rva, #0x48]	@ rvb <- STATUS
	lsr	rvb, rvb, #17		@ rvb <- status shifted
	and	rvb, rvb, #0x3f		@ rvb <- number of words in FIFO
	lsl	rvc, rvb, #2		@ rvc <- number of bytes in FIFO
spb_w0:	@ loop
	cmp	rvc, #128
	itTT	mi
	ldrmi	rvb, [sv3, rvc]
	strmi	rvb, [rva, #0x0100]
	addmi	rvc, rvc, #4
	bmi	spb_w0
	@ send cmd 24 (write single block)
	set	rvb, #24		@ rvb <- write single block command
	orr	rvb, rvb, #(3 << 9)	@ rvb <- data expected, write single block mode
	bl	sd_cmd
	@ check for error, if so, restart
	eq	rva, #0			@ command set successfully?
	itT	ne
	ldrne	rvc, [rva, #0x28]	@ 	if not, rvc <- CMDARG (block address)
	lsrne	rvc, rvc, #7		@	if not, rvc <- block address shifted for retry
	bne	spb_sr			@	if not, jmp to retry
	@ write data
	ldr	rva, =sd_mci		@ rva <- mci address
	set	rvc, #128		@ rvc <- initial buffer offset/data count (after pre-load)
	adr	lnk, spb_sr		@ lnk <- address for retry (via sd_cm1)
spb_wd:	@ write-data loop
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	bic	rvb, rvb, #0x3c		@ rvb <- status with cleared non-error bits
	bic	rvb, rvb, #(1 << 10)	@ rvb <- status with cleared HTO (starvation) bit
	bic	rvb, rvb, #(1 << 14)	@ rvb <- status with cleared acmd done bit
	eq	rvb, #0			@ any non-expected errors?
	itT	ne
	ldrne	rvc, [rva, #0x28]	@	if so,  rvc <- CMDARG (block address)
	lsrne	rvc, rvc, #7		@	if so,  rvc <- bloack address shifted for restart
	bne	sd_cm1			@	if so,  jump to restart
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	bic	rvb, rvb, #0x08		@ rvb <- status with DTO bit cleared
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear set status bits except DTO
	tst	rvb, #0x0410		@ is FIFO TxRdy or data starved?
	beq	spb_wd			@	if not, jump to keep waiting
	ldr	rvb, [sv3, rvc]		@ rvb <- data word from buffer
	str	rvb, [rva, #0x0100]	@ write data word to FIFO
	add	rvc, rvc, #4		@ rvc <- updated offset/count
	eq	rvc, #512		@ done writing data?
	bne	spb_wd			@	if not, jump to keep writing data
spb_w1:	@ wait for DTO bit (otherwise next transfer hangs on STATUS read)
	ldr	rvb, [rva, #0x44]	@ rvb     <- RINTSTS
	tst	rvb, #0x08		@ is DTO (transfer done) bit set?
	beq	spb_w1			@	if not, jump to wait for it
	set	rvb, #0x08		@ rvb     <- DTO bit
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear DTO bit
	ldr	rvc, [rva, #0x30]	@ rvc <- response0
spb_ts:	@ wait for card in ready-tran state
	bl	sd_pre			@ prepare mci (clear stat bits, set byte count)
	set	rvb, #0			@ rvb <- command argument
	bl	sd_arg			@ set arg CMDARG
	set	rvb, #13		@ rvb <- 13 (command to read status)
	bl	sd_cmd			@ set command
	eq	rva, #0			@ command set properly?
	it	ne
	eqne	rvb, #9			@	if not, is card in ready-tran state?
	bne	spb_ts			@	if not, jump to keep waiting
	@ return
	@ wait approx. 50ms
	set	rvb, #0x4e0000
spb_w5:	subs	rvb, rvb, #1
	bne	spb_w5
	orr	lnk, sv5, #lnkbit0
	set	pc,  lnk

_func_	
sd_pre:	@ mci-prep subroutine
	ldr	rva, =sd_mci
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear set status bits
	set	rvb, #512
	str	rvb, [rva, #0x20]	@ set BYTCNT to 512
	set	pc,  lnk

_func_
sd_arg:	@ mci-arg subroutine (set arg)
	@ on entry: rvb <- arg (0 as raw int, or block number as scheme int)
	ldr	rva, =sd_mci
	bic	rvb, rvb, #3		@ rvb <- block number * 4
	lsl	rvb, rvb, #7		@ rvb <- block number * 256
	str	rvb, [rva, #0x28]	@ CMDARG <- arg (block number to read/write)
	set	pc,  lnk

_func_
sd_cmd:	@ mci-cmd subroutine (put cmd)
	@ on entry: rvb <- cmd
	ldr	rva, =sd_mci		@ rva <- mci address	
	orr	rvb, rvb, #(1 << 31)	@ rvb <- bit to start command
	orr	rvb, rvb, #0x40		@ rvb <- bit to wait for response
	str	rvb, [rva, #0x2c]	@ CMD <- cmd
sd_cm0:	@ wait for cmd to be loaded (or HLE error)
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	tst	rvb, #(1 << 12)		@ hardware lock error (HLE)?
	bne	sd_cm1			@ 	if so,  jump to wait and restart (via lnk)
	ldr	rvb, [rva, #0x2c]	@ rvb <- CMD
	tst	rvb, #(1 << 31)		@ cmd loaded?
	bne	sd_cm0			@	if not, jump to keep waiting
	set	rva, #0x01000000
sd_cm3:	@ wait for cmd done or error
	subs	rva, rva, #1
	beq	sd_cm1
	ldr	rvb, =sd_mci		@ rva <- mci address	
	ldr	rvb, [rvb, #0x44]	@ rvb <- RINTSTS
	tst	rvb, #(1 << 2)		@ cmd done?
	it	eq
	tsteq	rvb, #(1 << 12)		@ 	if not, hardware lock error (HLE)?
	it	eq
	tsteq	rvb, #(1 << 14)		@ 	if not, acmd done?
	beq	sd_cm3			@	if not, jump to keep waiting
	ldr	rva, =sd_mci		@ rva <- mci address	
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear set status bits
	@ get response
	ldr	rvb, [rva, #0x30]	@ rvb <- response0
	lsr	rvb, rvb, #8		@ rvb <- response0 shifted
	and	rvb, rvb, #0x0f		@ rvb <- card status from response0
	eq	rvb, #9			@ was cmd received while card ready and in tran state?
	itT	eq
	seteq	rva, #0			@	if so,  rva <- 0, i.e. everything good
	seteq	pc,  lnk		@	if so,  return
sd_cm1:	@ wait then restart transfer
	@ [also: internal entry]
	set	rvb, #(1 << 18)		@ rvb <- countdown
sd_cm2:	@ wait loop
	subs	rvb, rvb, #1		@ rvb <- updated countdown, is it zero?
	bne	sd_cm2			@	if not, jump to keep waiting
	ldr	rva, =sd_mci		@ rva <- mmc base address
	ldr	rvb, [rva, #0x30]	@ rvb <- response0
	lsr	rvb, rvb, #8		@ rvb <- response0 shifted
	and	rvb, rvb, #0x0f		@ rvb <- card status from response0
	set	pc,  lnk		@ jump back to restart (based on lnk)

_func_	
sd_slo:	@ configure mci speed to low = 400 KHz, 1-bit bus, clock enabled
	@ set IDIVE output to IDIVA/128 = 400KHz
	ldr	rva, =CGU_base
	ldr	rvb, =((0x0c << 24) | (1 << 11) | (127 << 2))
	str	rvb, [rva, #0x58]	@ IDIVE_CTRL     <- output = IDIVA/128 = 400 KHz, autoblock
	@ clear status bits
	ldr	rva, =sd_mci
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear set status bits
	@ set bus to 1-bit
	set	rvb, #0
	str	rvb, [rva, #0x18]	@ CTYPE   <- 1-bit bus
	@ send card initialization stream
	set	rvb, #(1 << 15)		@ rvb     <- initialization 80-clk stream bit
	orr	rvb, rvb, #(1 << 31)	@ rvb     <- cmd start bit
	str	rvb, [rva, #0x2c]	@ CMD     <- initialize card
sdslo1:	@ wait for CUI to load command
	ldr	rvb, [rva, #0x2c]	@ rvb <- CMD
	tst	rvb, #(1 << 31)		@ cmd loaded?
	bne	sdslo1			@	if not, jump to keep waiting	
	set	pc,  lnk

_func_	
sd_fst:	@ configure mci speed to high, wide bus, clock enabled
	@ set IDIVE output to IDIVA/2 = 25.5 MHz
	ldr	rva, =CGU_base
	ldr	rvb, =((0x0c << 24) | (1 << 11) | (1 << 2))
	str	rvb, [rva, #0x58]	@ IDIVE_CTRL     <- output = IDIVA/2 = 25.5 MHz, autoblock
	@ clear status bits
	ldr	rva, =sd_mci
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear set status bits
	@ set bus to 4-bits
	set	rvb, #1
	str	rvb, [rva, #0x18]	@ CTYPE   <- 4-bit bus
	@ set block size for data transfers
	set	rvb, #0x0200
	str	rvb, [rva, #0x1c]	@ BLKSIZ <- 512 bytes per data block
	@ set FIFO thresholds for data transfers
	set	rvb, #16
	orr	rvb, rvb, #(3 << 16)
	str	rvb, [rva, #0x4c]	@ FIFOTH <- 16-byte Tx, 3-byte Rx
	set	pc,  lnk

_func_	
sdpcmd:	@ function to write a command to SD/MMC card
	@ on entry:	sv4 <- cmd (scheme int)
	@ on entry:	rvc <- arg (raw int)
	@ on exit:	rvb <- response0
	@ modifies:	rva, rvb
	ldr	rva, =sd_mci
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	str	rvb, [rva, #0x44]	@ RINTSTS <- clear set status bits
	str	rvc, [rva, #0x28]	@ CMDARG <- arg
	int2raw	rvb, sv4		@ rvb <- CMD (raw int)
	and	rvb, rvb, #0xff		@ rvb <- CMD (8 bits)
	orr	rvb, rvb, #(1 << 31)	@ rvb <- CMD with bit to start command
	eq	sv4, #i0		@ is it CMD0?
	it	ne
	orrne	rvb, rvb, #0x40		@ 	if not, rvb <- CMD with bit to wait for response
	tst	sv4, #0x10000000	@ long response?
	it	ne
	orrne	rvb, rvb, #0x80		@ 	if so,  rvb <- CMD with bit for long (vs short) response
	str	rvb, [rva, #0x2c]	@ CMD <- cmd
sdpcma:	@ wait for cmd to be loaded
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	tst	rvb, #(1 << 12)		@ hardware lock error (HLE)?
	bne	sdpcme			@	if so,  jump to exit
	ldr	rvb, [rva, #0x2c]	@ rvb <- CMD
	tst	rvb, #(1 << 31)		@ cmd loaded?
	bne	sdpcma			@	if not, jump to keep waiting
sdpcmb:	@ wait for cmd done or error
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	tst	rvb, #(1 << 2)		@ cmd done?
	it	eq
	tsteq	rvb, #(1 << 12)		@ 	if not, hardware lock error (HLE)?
	it	eq
	tsteq	rvb, #(1 << 14)		@ 	if not, acmd done?
	beq	sdpcmb			@	if not, jump to keep waiting
sdpcme:	@ keep going (branched from HLE detected)
	set	rvb, #0x100000		@ rvb <- wait countdown
sdpcmw:	@ wait a bit more (some cards seem to need this)
	subs	rvb, rvb, #1		@ rvb <- updated countdown, is it zero?
	bne	sdpcmw			@	if not, jump to keep waiting
	ldr	rvb, [rva, #0x44]	@ rvb <- RINTSTS
	@ if CMD3 (get address), check status and exit with indicator if bad
	eq	sv4, #((3 << 2) | i0)	@ was this a CMD3?
	bne	sdpcmc			@	if not, jump to normal exit
	bic	rvb, rvb, #0x3c		@ rvb <- status with cleared non-error bits
	bic	rvb, rvb, #(1 << 14)	@ rvb <- status with cleared acmd done bit
	eq	rvb, #0			@ any non-expected errors?
	itT	ne
	setne	rvb, #0			@	if so,  rvb <- 0 (i.e. not succesful)
	setne	pc,  lnk		@	if so,  return
sdpcmc:	@ normal exit
	ldr	rvb, [rva, #0x30]	@ rvb <- response0
	set	pc,  lnk
		
  .endif @ sd_is_on_mci

.endif	@ onboard_SDFT

/*------------------------------------------------------------------------------
@
@ 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/

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






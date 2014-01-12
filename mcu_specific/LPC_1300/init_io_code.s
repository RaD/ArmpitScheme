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
hwinit:	@ pre-set common values
	set	fre, #0
	set	sv1, #1
	set	sv2, #2
	set	sv3, #3
	set	sv4, #4
	set	sv5, #5
	ldr	rva, =sys_ctrl

	@ set FLASHCFG (formerly MAMTIM)
	ldr	rvc, =flash_tim
	ldr	rvb, [rvc]
	bic	rvb, rvb, #0x03
	orr	rvb, rvb, #0x02		@ 3 clocks for flash read (up to 72 MHz)
	str	rvb, [rvc]

	@ enable the main oscillator
	ldr	rvb, [rva, #0x0238]	@ rvb <- contents of PDRUNCFG
	bic	rvb, rvb, #0x20
	str	rvb, [rva, #0x0238]	@ PDRUNCFG     <- ~#x20 = power up system osc. 12MHz Xtal

	@ configure and enable the PLL
	str	sv1, [rva, #0x40]	@ SYSPLLCLKSEL <- set system osc as input to PLL
	str	fre, [rva, #0x44]	@ SYSPLLCLKUEN <- enable clock selection update
	str	sv1, [rva, #0x44]	@ SYSPLLCLKUEN <- perform clock selection update
	set	rvb, #PLL_PM_parms	@ UM10375 Rev.2 07/21010 p. 49
	str	rvb, [rva, #0x08]	@ SYSPLLCTRL   <- set PLL for 288MHz / 2*2 = 72 MHz / (5+1) = xtal
	ldr	rvb, [rva, #0x0238]
	bic	rvb, rvb, #0x80
	str	rvb, [rva, #0x0238]	@ PDRUNCFG     <- ~#x80 = power up PLL
pllwt0:	ldr	rvb, [rva,  #0x0c]	@ rvb <- PLL status
	tst	rvb, #PLOCK_bit		@ is PLL locked?
	beq	pllwt0			@	if not, jump to keep waiting

	@ set main clock to PLL output (72 MHz)
	str	sv3, [rva, #0x70]	@ MAINCLKSEL   <- set system pll as main clock
	str	fre, [rva, #0x74]	@ MAINCLKUEN   <- enable clock selection update
	str	sv1, [rva, #0x74]	@ MAINCLKUEN   <- perform clock selection update

	@ initialize Cortex-M3 SysTick Timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rvc, =systick_base
	ldr	rvb, =719999
	str	rvb, [rvc, #tick_load]	@ SYSTICK-RELOAD  <- value for 10ms timing at 72MHz
	str	fre, [rvc, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	sv5, [rvc, #tick_ctrl]	@ SYSTICK-CONTROL <- 5 = enabled, no interrupt, run from cpu clock
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	rvb, [rva, #0x80]
	orr	rvb, rvb, #0x20
	str	rvb, [rva, #0x80]	@ SYSAHBCLKCTRL <- power up I2C
	str	sv2, [rva, #0x04]	@ PRESETCTRL    <- de-assert I2C reset
	ldr	rvc, =i2c0_base		@ rvc <- I2C0 base address
	set	rvb, #mcu_id
	str	rvb, [rvc, #i2c_address] @ I2C0ADR <- set mcu address

	@ initialization of gpio pins for LEDs
	ldr	rvb, [rva, #0x80]	@ rvb <- contents of SYSAHBCLKCTRL
	orr	rvb, rvb, #0x10000
	str	rvb, [rva, #0x80]	@ SYSAHBCLKCTRL <- power up IOCON
	ldr	rvc, =iocon_pio		@ rvc <- IOCON_PIOn
	str	fre, [rvc, #0x84]	@ disable pullup on P3.0
	str	fre, [rvc, #0x88]	@ disable pullup on P3.1
	str	fre, [rvc, #0x9c]	@ disable pullup on P3.2
	ldr	rvc, =LEDIO		@ GPIO 3 port address (LEDs on P3.0, P3.1, P3.2)
	ldr	rvb, =0x8000		@ GPIO_DIR offset
	add	rvc, rvc, rvb
	ldr	rvb, =ALLLED
	str	rvb, [rvc]		@ make all LED pins output pins (P3.0-2)

	@ initialization of UART0 for 9600 8N1 operation
	ldr	rvc, =iocon_pio		@ rvc <- IOCON_PIOn
	str	sv1, [rvc, #0xa4]	@ set UART_RXD function on P1.6 (no pull-up/down)
	str	sv1, [rvc, #0xa8]	@ set UART_TXD function on P1.7 (no pull-up/down)
	ldr	rvb, [rva, #0x80]	@ rvb <- contents of SYSAHBCLKCTRL
	orr	rvb, rvb, #0x01000
	str	rvb, [rva, #0x80]	@ SYSAHBCLKCTRL <-  power up UART0
	str	sv1, [rva, #0x98]	@ UARTCLKDIV    <- power up UART0 Clock (divisor = 1)
	ldr	rvc, =uart0_base
	str	sv1, [rvc, #0x08]	@ U0FCR         <- Enable UART0, Rx trigger-level = 1 char
	set	rvb, #0x80
	str	rvb, [rvc, #0x0c]	@ U0LCR         <- Enable UART0 divisor latch
	ldr	rvb, =UART0_DIV_L
	str	rvb, [rvc]		@ U0DLL         <- UART0 lower byte of divisor for 9600 baud
	ldr	rvb, =UART0_DIV_H
	str	rvb, [rvc, #0x04]	@ U0DLM         <- UART0 upper byte of divisor for 9600 baud
	str	sv3, [rvc, #0x0c]	@ U0LCR         <- Disable UART0 divisor latch and set 8N1 parms
	str	sv1, [rvc, #0x04]	@ U0IER         <- Enable UART0 RDA interrupt

.ifdef	native_usb
	@ 10. initialization of USB device controller
	ldr	rvc,  =USB_LineCoding
	ldr	rvb,  =115200
	str	rvb,  [rvc]		@ 115200 bauds
	set	rvb,  #0x00080000
	str	rvb,  [rvc,  #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	rvc,  =USB_CHUNK
	str	fre,  [rvc]		@ zero bytes remaining to send at startup
	ldr	rvc,  =USB_ZERO
	str	fre,  [rvc]		@ alternate interface and device/interface status = 0
	ldr	rvc,  =USB_CONF
	str	fre,  [rvc]		@ USB device is not yet configured
	@ see if USB is plugged in (if not, exit USB setup)
	ldr	rvc, =iocon_pio		@ rvc <- IOCON_PIOn
	str	fre, [rvc, #0x2c]	@ disable pullup on P0.3 / VBUS
	ldr	rvc, =io0_base
	ldr	rvb, [rvc, #0x20]	@ rvb <- status of P0.3
	eq	rvb, #0			@ is VBUS high?
	it	eq
	seteq	pc,  lnk		@	if not, exit hardare initialization (VBUS is not on)
	@ configure and enable the USB PLL and USB clock
	str	sv1, [rva, #0x48]	@ USBPLLCLKSEL <- set system osc as input to PLL
	str	fre, [rva, #0x4C]	@ USBPLLCLKUEN <- enable clock selection update
	str	sv1, [rva, #0x4C]	@ USBPLLCLKUEN <- perform clock selection update
	set	rvb, #0x23		@ UM10375 Rev.2 07/21010 p. 16
	str	rvb, [rva, #0x10]	@ USBPLLCTRL   <- set USB PLL for 192MHz / 2*2 = 48 MHz/(3+1)=xtal
	ldr	rvb, [rva, #0x0238]
	bic	rvb, rvb, #0x0100
	str	rvb, [rva, #0x0238]	@ PDRUNCFG     <- ~#x0100 = power up USB PLL
pllwt1:	ldr	rvb, [rva, #0x14]	@ rvb <- USB PLL status
	tst	rvb, #PLOCK_bit		@ is USB PLL locked?
	beq	pllwt1			@	if not, jump to keep waiting
	str	fre, [rva, #0xC0]	@ USBCLKSEL <- set USB PLL as input to USB clock
	str	fre, [rva, #0xC4]	@ USBCLKUEN <- enable clock selection update
	str	sv1, [rva, #0xC4]	@ USBCLKUEN <- perform clock selection update
	@ power up the USB subsystem
	ldr	rvb, [rva, #0x0238]
	bic	rvb, rvb, #0x0400
	str	rvb, [rva, #0x0238]	@ PDRUNCFG     <- ~#x0400 = power up USB PAD/PHY
	ldr	rvb, [rva, #0x80]
	orr	rvb, rvb, #0x4000
	str	rvb, [rva, #0x80]	@ SYSAHBCLKCTRL <- power up USB REG
	str	sv1, [rva, #0xC8]	@ USBCLKDIV <- enable USB clock, divisor = 1
	@  4. Disable all USB interrupts.
	ldr	rvc, =usb_base
	set	rvb, #0x00ff
	orr	rvb, rvb, #0x0100
	str	rvb, [rvc, #usb_iclear_dv]
	str	fre, [rvc, #0x04]	@ disable control 0,1 and EP 4,5 interrupts
	@  5. Configure pins
	ldr	rvc, =iocon_pio		@ rvc <- IOCON_PIOn
	str	sv1, [rvc, #0x2c]	@ P0.3 <- VBUS function
	str	sv1, [rvc, #0x4c]	@ P0.6 <- CONNECT function
	@ 10. Set default USB address to 0 and send Set Addrss cmd to the protoc engin (twice, see manual).
	set	rvc, lnk		@ r12 <- lnk, saved against wrtcmd
	ldr	rvb,  =0xD00500
	bl	wrtcmd			@ execute set-address command (0x0500 = write command)
	ldr	rvb,  =0x800100
	bl	wrtcmd			@ execute device enable on address zero (0x80) (0x0100 = write dat)
	ldr	rvb,  =0xD00500
	bl	wrtcmd			@ execute set-address command (0x0500 = write command)
	ldr	rvb,  =0x800100
	bl	wrtcmd			@ execute device enable on address zero (0x80) (0x0100 = write dat)
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
	set	lnk, rvc		@ lnk <- restored
	@ enable USB interrupts
	ldr	rvc, =usb_base
	set	rvb, #0x0066
	orr	rvb, rvb, #0x200
	str	rvb, [rvc, #0x04]	@ enable control 0,1 and EP 4,5 interrupts

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

.ifdef LPC_P1343
_func_
FlashInitCheck: @ return status of flash init enable/override gpio pin Button1 (P2.9) in rva
		@ pin low = boot override
	ldr	rva, =io2_base		@ rva <- address of gpio 2 base register
	ldr	rva, [rva, #io_state]	@ rva <- values of all P2.X
	and	rva, rva, #(1 << 9)	@ rva <- status of P2.9 only (return value)
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
	@ prepare flash sector for write
	bl	pgsctr			@ r2  <- sector number (raw int), from page address in r5 {sv2}
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	r0,  {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ copy RAM flash to FLASH
	ldmfd	sp,  {r0, r1, r4-r7}	@ restore r5 {sv2} = page addrss and r7{sv4}= fil dscrptr frm stack
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)	
	set	r2,  #51		@ r2  <- IAP command 51 -- copy RAM to FLASH
	set	r3,  r5			@ r3  <- page address
	vcrfi	r4,  r7,  3		@ r4  <- address of buffer
	add	r4,  r4,  #4		@ r4  <- RAM start address for data in buffer
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


@---------------------------------------------------------------------------------------------
@
@ 2- I2C Interrupt routine
@
@---------------------------------------------------------------------------------------------

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
	eq	rva, #0			@ were we sendng 0 byts (i.e. readng as mstr, done wrtng adr byts)?
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
	subne	rvb, rvb, #4		@	if not, rvb <- updtd num of addrss byts to snd (scheme int)
	tbstine rvb, sv2, 1		@	if not, str updtd num of addrss byts to snd in i2cbuffer[4]
	addne	rva, sv2, #8		@	if not, rva <- addrss of additionl addrss byts in i2cbuffer
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

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~
.ltorg






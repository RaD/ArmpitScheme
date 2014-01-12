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
	@ set LED port pin to output and turn LED on
	ldr	r6,  =LEDIO
	set	r7,  #0x02
	str	r7,  [r6,  #0x24]	@ Port 2 Mode1S_2 Set Reg dir P2.1 out
	@ initialize interrupts
	ldr	r6,  =int_base
	add	r6,  r6, #0x0400
	ldr	r7,  =0x1C010001
	str	r7,  [r6,  #0x14]	@ INT_REQ5  <- Tmr 0 zr Cnt int enab IRQ
	str	r7,  [r6,  #0x18]	@ INT_REQ6  <- Tmr 1 zr Cnt int enab IRQ
	str	r7,  [r6,  #0x30]	@ INT_REQ12 <- UART int enabled as IRQ
	str	r7,  [r6,  #0x34]	@ INT_REQ13 <- i2C  int enabled as IRQ
	@ initialize uart
	ldr	r6,  =uart0_base
	str	r1,  [r6,  #0x08]	@ U0FCR     <- Enab UART0,Rx trig=1chr
	set	r7,  #0x80
	str	r7,  [r6,  #0x0c]	@ U0LCR     <- Enab UART0 div latch
	ldr	r7,  =UART0_DIV_L
	str	r7,  [r6]		@ U0DLL     <- UART0 low byt div 9600 bd
	ldr	r7,  =UART0_DIV_H
	str	r7,  [r6,  #0x04]	@ U0DLM     <- UART0 upr byt div 9600 bd
	str	r3,  [r6,  #0x0c]	@ U0LCR     <- Disab UART0 latch,set 8N1
	str	r1,  [r6,  #0x04]	@ U0IER     <- Enab UART0 RDA interrupt
	@ initialization of mcu-id for variables (I2c address if slave enabled)
	ldr	r6,  =I2C0ADR
	set	r7,  #mcu_id
	str	r7,  [r6]		@ I2CADR <- set mcu address
	@ unlock the FLASH
	set	r12, lnk
	bl	unlok
	set	lnk, r12
	ldr	r6,  =USB_CONF
	str	r0,  [r6]

.ifdef	native_usb

	@ USB initialization
	ldr	r8,  =usb_clken
	str	r0, [r8]		@ disable USB Clock
	str	r1, [r8]		@ enable USB Clock
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
	str	r0,  [r6]		@ indicate that USB not yet configured
	@ see if USB is plugged in (if not, exit USB setup)
	ldr	r6,  =0x800031C0
	ldr	r6,  [r6]
	tst	r6,  #0x01
	seteq	pc,  lnk
	ldr	r6,  =usb_base
	str	r0,  [r6]		@ USB Device Address <- 0
	set	r7,  #0xfc
	str	r7,  [r6,  #0x10]	@ USB Int cfg <- ACK,STALL NYET,some NAK
	str	r1,  [r8]		@ enable USB Clock
	set	r7,  #0x20
	str	r7,  [r6,  #usb_epind]	@ USB EP  INDEX <- select EP 0 SETUP
	set	r7,  #0xff
	str	r7,  [r6,  #0xac]	@ USB Dev Inter clear <- clear dev ints
	ldr	r7,  =0xffff
	str	r7,  [r6,  #0xa0]	@ USB EP Int clr  <- clr EP ints, Tx/Rx
	str	r7,  [r6,  #0x90]	@ USB EP Int enab <- enab bus reset int
	ldr	r7,  =0xaa37
	str	r7,  [r6,  #0x7c]	@ unlock USB registers
	set	r7,  #0xa1
	str	r7,  [r6,  #0x8c]	@ USB Dev Int enab <- enab bus reset int
	ldr	r6,  =USB_FSHS_MODE
	str	r0,  [r6]		@ indicate USB is not yet in HS mode
	ldr	r6,  =usb_base
	ldr	r8,  =int_base
	add	r8,  r8, #0x0400
	ldr	r7,  =0x1C010001
	str	r7,  [r8,  #0x68]	@ INT_REQ26 <- USB int enab IRQ, prior=1
	str	r7,  [r8,  #0x6c]	@ INT_REQ27 <- USB int enab IRQ, prior=1
	str	r7,  [r8,  #0x70]	@ INT_REQ28 <- USB int enab IRQ, prior=1
	str	r7,  [r8,  #0x74]	@ INT_REQ29 <- USB int enab IRQ, prior=1
	set	r7,  #0x80
	str	r7,  [r6]		@ USB Device Address <- 0, enabled
	set	r7,  #0x89
	str	r7,  [r6,  #0x0c]	@ Mode <- clk alws on,ints enab,softconn

.endif	@ native_usb
	
	set	pc,  lnk	


@-------------------------------------------------------------------------------
@ lpc28xx
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-------------------------------------------------------------------------------
	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

FlashInitCheck: @ return stat of boot override gpio pin (P2.0) in r6
	ldr	rvb, =io2_base		@ rvb <- PINS_2
	ldr	rva, [rvb]		@ rva <- values of all PINS_2
	and	rva, rva, #1		@ rva <- status of P2.0 only
	eor	rva, rva, #1		@ rva <- status of P2.0 inverted
	set	pc,  lnk

wrtfla:	@ write to flash, sv2 = page address, sv4 = file descriptor
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ str schm regs on stack
	@ copy buffer data from file descriptor{sv4} (RAM) to FLASH buffer {sv2}
	vcrfi	sv3, sv4, 3		@ sv3 <- buffer address	
	add	sv5, sv2, #F_PAGE_SIZE	@ sv5 <- end target address
wrtfl0:	bl	pgsctr			@ rva <- sctr num raw, frm pg adrs sv2
	ldr	rvb, =flashsectors	@ rvb <- address of flash address table
	ldr	rvb, [rvb, rva,LSL #2]	@ rvb <- start adrs of target flash blk
	@ write lower 2 bytes of word
	ldrh	rvc, [sv3]		@ rvc <- lower half of word to write
	set	rva, #0x40		@ rva <- CFI word program command code
	strh	rva, [sv2]		@ start half word write
	strh	rvc, [sv2]		@ confirm half word write
flwrw1:	@ wait for FLASH device to be ready
	ldrh	rva, [rvb]		@ rva <- FLASH device status
	tst	rva, #0x80		@ is FLASH ready?
	beq	flwrw1			@	if not, jump to keep waiting
	@ write upper two bytes of word
	ldrh	rvc, [sv3, #2]		@ rvc <- upper half word to write
	set	rva, #0x40		@ rva <- CFI word program command code
	strh	rva, [sv2, #2]		@ start half word write
	strh	rvc, [sv2, #2]		@ confirm half word write
flwrw2:	@ wait for FLASH device to be ready
	ldrh	rva, [rvb]		@ rva <- FLASH device status
	tst	rva, #0x80		@ is FLASH ready?
	beq	flwrw2			@	if not, jump to keep waiting
	@ jump to keep writing or finish up
	add	sv3, sv3, #4		@ sv3 <- address of next source word
	add	sv2, sv2, #4		@ sv2 <- target address of next word
	cmp	sv2, sv5		@ done writing page?
	bmi	wrtfl0			@	if not, jump to keep writing
	@ Return to FLASH Read Array mode
	set	rva, #0x00ff		@ rva <- CFI Read Array command code
	strh	rva, [rvb]		@ set FLASH to read array mode
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ rstr schm regs frm stk
	ldmfd	sp!, {rva, rvb, rvc, lnk} @ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

ersfla:	@ erase flash sector that contains page address in sv2
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ stor schm regs to stk
	@ prepare flash sector for write
	bl	pgsctr			@ rva <- sctr num, from pg adrs sv2
	ldr	rvb, =flashsectors	@ rvb <- address of flash sector table
	ldr	rvb, [rvb, rva, LSL #2]	@ rvb <- address of flash block start
	@ erase block whose address starts at sv2
	set	rva, #0x0020		@ rva <- CFI erase block command code
	strh	rva, [rvb]		@ initiate erase block
	set	rva, #0x00d0		@ rva <- CFI confirm erase command code
	strh	rva, [rvb]		@ confirm erase block
	@ wait for FLASH device to be ready
	ldr	rvb, =flashsectors	@ rvb <- address of flash sector table
	ldr	rvb, [rvb]		@ rvb <- FLASH start address
flrdwt:	ldrh	rva, [rvb]		@ rva <- FLASH device status
	tst	rva, #0x80		@ is FLASH ready?
	beq	flrdwt			@	if not, jump to keep waiting
	@ Return to FLASH Read Array mode
	set	rva, #0x00ff		@ rva <- CFI Read Array command code
	strh	rva, [rvb]		@ set FLASH to read array mode
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ rstr schm regs frm stk
	ldmfd	sp!, {rva, rvb, rvc, lnk} @ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

unlok:	@ unlock all file flash -- called by hwinit
	set	r6,  lr			@ r6  <- lnk, saved
	ldr	r5,  =F_START_PAGE	@ r5  <- start address of file flash
	bl	pgsctr			@ r2  <- sector num, from pg adrs in r5
	ldr	r3,  =F_END_PAGE	@ r3  <- end address of file flash
	ldr	r9,  =flashsectors	@ r9  <- address of flash sector table
unlok0:	@ loop over flash blocks to be unlocked
	ldr	r5,  [r9,  r2,  LSL #2]	@ r5  <- start address of flash sector
	@ unlock block that starts at sv2
	ldr	r0,  [r9]		@ r0  <- FLASH start address
	set	r4,  #0x0060		@ r4  <- CFI unlock block command code
	strh	r4,  [r5]		@ initiate block unlock
	set	r4,  #0x00d0		@ r4  <- CFI confirm unlock command code
	strh	r4,  [r5]		@ confirm block unlock
	@ wait for FLASH device to be ready
	set	r4,  #0x0090		@ r4  <- CFI read device ID command code
	strh	r4,  [r0]		@ initiate ID and status read
unlok1:	ldrh	r4,  [r5,  #4]		@ r4  <- block status
	tst	r4,  #0x03		@ is block unlocked?
	bne	unlok1			@	if not, jump to keep waiting
	cmp	r5,  r3			@ done unlocking?
	addmi	r2,  r2, #1		@	if not, r2  <- next sector num
	bmi	unlok0			@	if not, jump to unlok nxt sctr
	@ Return to FLASH Read Array mode and exit
	set	r4,  #0x00ff		@ r4  <- CFI Read Array command code
	strh	r4,  [r0]		@ set FLASH to read array mode
	set	pc,  r6			@ return


.ltorg

@
@	2- I2C Interrupt routine
@

hwi2cr:	@ write-out additional address registers, if needed
hwi2ni:	@ initiate i2c read/write, as master
hwi2st:	@ get i2c interrupt status and base address
i2c_hw_branch:	@ process interrupt
hwi2we:	@ set busy status/stop bit at end of write as master
hwi2re:	@ set stop bit if needed at end of read-as-master
hwi2cs:	@ clear SI
i2cstp:	@ prepare to end Read as Master transfer
i2putp:	@ Prologue:	write addit'l adrs byts to i2c, frm bfr/r12 (prologue)
i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	set	pc,  lnk






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

	@ configure interrupts
	ldr	r7,  =genisr
	ldr	r10, =int_base
	str	r0,  [r10, #0x0c]	@ VIC1IntSelect <- all interrupts are IRQ
	str	r7,  [r10, #0x34]	@ VIC1VectDefAddr <- default ISR
	add	r11, r10, #0x010000
	str	r0,  [r11, #0x0c]	@ VIC2IntSelect <- all interrupts are IRQ
	str	r7,  [r11, #0x34]	@ VIC2VectDefAddr <- default ISR

	@ initialization of UART0 for 9600 8N1 operation
	ldr	r6,  =0x80930000
	set	r7,  #0xaa
	str	r7,  [r6,  #0xc0]	@ sysSWLock <- unlock DeviceCfg register
	set	r7,  #0x00040000	@ enable UART0 (aka uart1)
	orr	r7,  r7, #0x00000800	@ GPIO H pins are GPIO (not IDE) -- for FlashInitCheck Button

.ifdef	hardware_FPU
	@ power-up the Maverick Crunch co-processor
	orr	r7, r7, #0x00800000
.endif	
	str	r7,  [r6,  #0x80]	@ DeviceCfg enable/power-up UART1 (and FPU, if needed)
	ldr	r6,  =uart0_base
	ldr	r7,  =UART0_DIV_L
	str	r7,  [r6,  #0x10]	@ Uart1LinCtrlLow <- 47 (low divisor for 9600 baud)
	ldr	r7,  =UART0_DIV_H
	str	r7,  [r6,  #0x0c]	@ Uart1LinCtrlMid <- 0  (high divisor for 9600 baud)
	set	r7,  #0x60
	str	r7,  [r6,  #0x08]	@ Uart1LinCtrlHigh <- 8, N, 1, no FIFO
	str	r0,  [r6,  #0x1c]	@ Uart1IntIDIntClr <- clear those clearable UART interrupts
	set	r7,  #0x11
	str	r7,  [r6,  #0x14]	@ Uart1Ctrl <- enable uart1 and Rx interrupt
	set	r7,  #0x00800000
	str	r7,  [r10, #0x10]	@ VIC1IntEnable <- bit 23 = UART1 RXINTR1
	set	r7,  #0x00100000
	str	r7,  [r11, #0x10]	@ VIC2IntEnable <- bit 52 overall = INT_UART1

	@ initialization of SD card pins
.ifdef	onboard_SDFT	
  .ifdef sd_is_on_spi
	@ configure spi speed (low), phase, polarity
	ldr	r6,  =sd_spi
	set	r7,  #0x10
	str	r7,  [r6, #0x04]	@ SSPCR1  <- enable SPI
	set	r7,  #40
	str	r7,  [r6, #0x10]	@ SSPCPSR <- 1st prescaler = 40
	set	r7,  #7
	str	r7,  [r6, #0x00]	@ SSPCR0  <- 7.4 MHz/40 = 185KHz, 8-bit, PH/POL=0
	set	r7,  #0x00
	str	r7,  [r6, #0x04]	@ SSPCR1  <- disable SPI
	set	r7,  #0x10
	str	r7,  [r6, #0x04]	@ SSPCR1  <- enable SPI
	@ configure chip-select pin as gpio out, and de-select sd card
	ldr	r6,  =sd_cs_gpio
	and	r7,  r6, #0xff
	cmp	r7,  #0x10
	ldrmi	r7,  [r6, #io_dir]
	ldrpl	r7,  [r6, #io_dir_high]
	orr	r7,  r7, #sd_cs
	strmi	r7,  [r6, #io_dir]	@ sd CS pin set as gpio out
	strpl	r7,  [r6, #io_dir_high]	@ sd CS pin set as gpio out
	ldr	r7,  [r6, #io_state]
	orr	r7,  r7, #sd_cs
	str	r7,  [r6, #io_state]	@ set sd_cs pin to de-select sd card
  .endif  @ sd_is_on_spi
.endif	@ onboard_SDFT
	@ I2C and USB
	ldr	r6,  =I2C0ADR		@ r6  <- I2C0ADR
	set	r7,  #mcu_id
	str	r7,  [r6]		@ I2C0ADR <- set mcu address
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB_CONF <- USB device is not yet configured

.ifdef	hardware_FPU
	@ set default rounding mode to truncate
	cfmv32sc mvdx0, dspsc		@ mvdx0 <- rounding mode from DSPSC
	cfmvr64l rvb, mvdx0		@ rvb   <- rounding mode
	bic	rvb, rvb, #0x0c00	@ clear rounding mode
	orr	rvb, rvb, #0x0400	@ rounding mode = towards zero (i.e. truncate = default)
	cfmv64lr mvdx0, rvb		@ mvdx0 <- new rounding mode
	cfmvsc32 dspsc, mvdx0		@ set rounding mode in DSPSC
.endif	
	@ end of the hardware initialization
	set	pc,  lnk


/*------------------------------------------------------------------------------
@  EP_93xx
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/
	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

FlashInitCheck: @ return status of flash init enable/override gpio pin GPIO H pin 4 = BUT button in rva
	ldr	rvb, =ioH_base			@ rvb <- port address
	ldr	rva, [rvb, #io_state]		@ rva <- state of GPIO H pins
	and	rva, rva, #(1 << 4)
	set	pc,  lnk			@ return
	
wrtfla:	@ write to flash, sv2 is page address, sv4 is file descriptor
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5,  env, dts, glv} @ store scheme registers onto stack
	@ copy buffer data from file descriptor (sv4) (RAM) to FLASH buffer (sv2)
	vcrfi	sv3, sv4, 3			@ sv3 <- buffer address	
	add	sv4, sv2, #F_PAGE_SIZE		@ sv4 <- end target address
wrtfl0:	bl	pgsctr				@ rva <- sector number (raw int), from page address in r5
	ldr	rvb, =flashsectors		@ rvb <- address of flash sector table
	ldr	sv1, [rvb, rva, LSL #2]		@ sv1 <- address of flash page block start
	@ initiate write-buffer to FLASH
flwrw1:	set	rva, #0xe8			@ rva <- CFI write-buffer command code
	strh	rva, [sv1]			@ initiate write-buffer
	ldrh	rva, [sv1]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	beq	flwrw1				@	if not, jump to keep waiting
	@ set count and transfer data to FLASH write-buffer
	set	rva, #0x1f			@ rva <- 32 bytes to write
	strh	rva, [sv1]			@ set number of bytes to write in CFI controller
	ldmib	sv3!, {fre,cnt,rva,rvb,sv5,env,dts,glv}	@ get next eight source data words
	stmia	sv2,  {fre,cnt,rva,rvb,sv5,env,dts,glv}	@ store data words in FLASH write-buffer
	stmia	sv2!, {fre,cnt,rva,rvb,sv5,env,dts,glv}	@ store data AGAIN (cfi seems to expect 16x2 writes)
	@ commit write-buffer to FLASH
	set	rva, #0xd0			@ rva <- CFI confirm write-buffer command code
	strh	rva, [sv1]			@ confirm write-buffer command
flwrw2:	ldrh	rva, [sv1]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	beq	flwrw2				@	if not, jump to keep waiting
	set	rva, #0x50			@ rva <- CFI Clear Status Register command code
	strh	rva, [sv1]			@ clear the status register
	cmp	sv2, sv4			@ done writing?
	bmi	wrtfl0				@	if not, jump to keep writing data to flash
	set	rva, #0xff			@ rva <- CFI Read Array command code
	strh	rva, [sv1]			@ set FLASH to read array mode
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}	@ restore scheme registers from stack
	orr	fre, fre, #0x02			@ fre <- fre-ptr de-reserved
	swi	run_normal			@ enable interrupts (user mode)
	set	pc,  lnk			@ return

ersfla:	@ erase flash sector that contains page address in sv2
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5,  env, dts, glv} @ store scheme registers onto stack
	@ prepare flash sector for write
	bl	pgsctr				@ rva <- sector number (raw int), from page address in sv2
	ldr	rvb, =flashsectors		@ rvb <- address of flash sector table
	ldr	sv1, [rvb]			@ sv1 <- start address of whole FLASH (controller)
	ldr	sv2, [rvb, rva, LSL #2]		@ sv2 <- address of flash block start
	@ unlock block to be erased (unlocks all blocks really it seems)
	set	rva, #0x60			@ rva <- CFI unlock block command code
	strh	rva, [sv1]			@ initiate block unlock
	set	rva, #0xd0			@ rva <- CFI confirm unlock command code
	strh	rva, [sv1]			@ confirm block unlock
flrdw0:	ldrh	rva, [sv1]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	beq	flrdw0				@	if not, jump to keep waiting
	set	rva, #0x50			@ rva <- CFI Clear Status Register command code
	strh	rva, [sv1]			@ clear the status register
	@ erase block whose address starts at sv2
	set	rva, #0x20			@ rva <- CFI erase block command code
	strh	rva, [sv2]			@ initiate erase block
	set	rva, #0xd0			@ rva <- CFI confirm erase command code
	strh	rva, [sv2]			@ confirm erase block
flrdwt:	ldrh	rva, [sv1]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	beq	flrdwt				@	if not, jump to keep waiting
	set	rva, #0x50			@ rva <- CFI Clear Status Register command code
	strh	rva, [sv1]			@ clear the status register
	set	rva, #0xff			@ rva <- CFI Read Array command code
	strh	rva, [sv1]			@ set FLASH to read array mode
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}	@ restore scheme registers from stack
	orr	fre, fre, #0x02			@ fre <- fre-ptr de-reserved
	swi	run_normal			@ enable interrupts (user mode)
	set	pc,  lnk			@ return

	
/*------------------------------------------------------------------------------
@
@ 2- SD card low-level interface
@
@-----------------------------------------------------------------------------*/

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

_func_	
sd_cfg:	@ configure spi speed (high), phase, polarity
	ldr	rva, =sd_spi
	ldr	rvb, [rva, #0x00]
	eq	rvb, #7
	ldreq	rvb, [rva, #0x10]
	eqeq	rvb, #2
	ldreq	rvb, [rva, #0x04]
	eqeq	rvb, #0x10
	setne	rvb, #0x10
	strne	rvb, [rva, #0x04]	@ SSPCR1  <- enable SPI
	setne	rvb, #2
	strne	rvb, [rva, #0x10]	@ SSPCPSR <- 1st prescaler = 2
	setne	rvb, #7
	strne	rvb, [rva, #0x00]	@ SSPCR0  <- 7.4 MHz/2, 8-bit, PH/POL=0
	setne	rvb, #0x00
	strne	rvb, [rva, #0x04]	@ SSPCR1  <- disable SPI
	setne	rvb, #0x10
	strne	rvb, [rva, #0x04]	@ SSPCR1  <- enable SPI
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	ldr	rva, =sd_spi
	ldr	rvb, [rva, #0x00]
	eq	rvb, #7
	ldreq	rvb, [rva, #0x10]
	eqeq	rvb, #40
	ldreq	rvb, [rva, #0x04]
	eqeq	rvb, #0x10
	setne	rvb, #0x10
	strne	rvb, [rva, #0x04]	@ SSPCR1  <- enable SPI
	setne	rvb, #40
	strne	rvb, [rva, #0x10]	@ SSPCPSR <- 1st prescaler = 40
	setne	rvb, #7
	strne	rvb, [rva, #0x00]	@ SSPCR0  <- 7.4 MHz/40 = 185KHz, 8-bit, PH/POL=0
	setne	rvb, #0x00
	strne	rvb, [rva, #0x04]	@ SSPCR1  <- disable SPI
	setne	rvb, #0x10
	strne	rvb, [rva, #0x04]	@ SSPCR1  <- enable SPI
	set	pc,  lnk

_func_	
sd_sel:	@ select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	ldr	rvb, [rva, #io_state]
	bic	rvb, rvb, #sd_cs
	str	rvb, [rva, #io_state]	@ clear-pin
	set	pc,  lnk
	
_func_	
sd_dsl:	@ de-select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	ldr	rvb, [rva, #io_state]
	orr	rvb, rvb, #sd_cs
	str	rvb, [rva, #io_state]	@ set-pin
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

  .endif @ sd_is_on_spi


.endif	@ onboard_SDFT

	
/*------------------------------------------------------------------------------
@  EP_93xx
@
@ 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/

hwi2cr:	@ write-out additional address registers, if needed
hwi2ni:	@ initiate i2c read/write, as master
hwi2st:	@ get i2c interrupt status and base address
i2c_hw_branch:	@ process interrupt
hwi2we:	@ set busy status/stop bit at end of write as master
hwi2re:	@ set stop bit if needed at end of read-as-master
hwi2cs:	@ clear SI
i2cstp:	@ prepare to end Read as Master transfer
i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer or r12 (prologue)
i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	set	pc,  lnk







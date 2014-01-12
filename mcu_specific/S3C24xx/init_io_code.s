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


hwinit:	@ configure LED
	ldr	rvb, = io0_base
	set	rva, #0x01
	str	rva, [rvb, #0x08]	@ disable pull-up on GPIO F, pin 0, GPF0
	str	rva, [rvb]		@ set output dir for GPIO F, pin 0, GPF0

	@ initialization of UART0 for 9600 8N1 operation
	ldr	rva, = 0x56000070	@ rva <- GPHCON (uart0 on Port H)
	set	rvb, #0x0c
	str	rvb, [rva, #0x08]	@ disable pull-up on pins GPH 2, 3
	set	rvb, #0xa0
	str	rvb, [rva, #0x00]	@ enable uart0 Tx Rx for pins GPH 2,3
	ldr	rva, =uart0_base
	set	rvb, #0x03
	str	rvb, [rva, #0x00]	@ ULCON0 <- 8, N, 1
	set	rvb, #0x00
	str	rvb, [rva, #0x08]	@ UFCON0 <- no FIFO
	ldr	rvb, =UART0_DIV
	str	rvb, [rva, #0x28]	@ UBRDIV0 <- 329 (divisor for 9600 baud)
	set	rvb, #0x45
	str	rvb, [rva, #0x04]	@ UCON0 <- enable Tx, Rx, error int

	@ initialization of SD card pins
.ifdef	onboard_SDFT	
  .ifdef sd_is_on_spi
	@ configure spi speed (low), phase, polarity
	ldr	rva, =sd_spi
	set	rvb, #63
	str	rvb, [rva, #0x0c]	@ sppre <- 60MHz/2/(63+1) ~= 400KHz
	set	rvb, #0x18
	str	rvb, [rva, #0x00]	@ spcon (ctrl) <- CLKen,master,POL=PHA=0
	@ configure chip-select pin as gpio out, and de-select sd card
	ldr	rva, =sd_cs_gpio
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x0c
	orr	rvb, rvb, #0x04
	str	rvb, [rva]		@ gpio_H <- sd_cs pin config as gpio out
	ldr	rvb, [rva, #io_state]
	orr	rvb, rvb, #sd_cs
	str	rvb, [rva, #io_state]	@ set sd_cs pin to de-select sd card
	@ configure other spi pins: gpio_G.5,6,7 as SPI (cfg = #b11)
	ldr	rva, =sd_spi_gpio
	ldr	rvb, [rva]
	orr	rvb, rvb, #0xfc00
	str	rvb, [rva]		@ gpio_G <- pins 5,6,7 configured as SPI
  .endif  @ sd_is_on_spi
.endif	@ onboard_SDFT
	@ I2C and USB
	ldr	rva, =I2C0ADR		@ r6  <- I2C0ADR
	set	rvb, #mcu_id
	str	rvb, [rva]		@ I2C0ADR <- set mcu address
	ldr	rva, =USB_CONF
	set	rvb, #0x00
	str	rvb, [rva]		@ USB_CONF <- USB dev not yet configured
	@ initialize interrupts
	ldr	rva, =int_base
	ldr	rvb, =0x07ff
	str	rvb, [rva, #0x18]	@ clear sub-src-pndng ints in SUBSRCPND
	set	rvb, #0x00
	mvn	rvb, rvb
	str	rvb, [rva, #0x00]	@ clear source-pending ints in SRCPND
	ldr	rvb, [rva, #0x10]	@ rvb <- asserted interrupts
	str	rvb, [rva, #0x10]	@ clear asserted interrupts in INTPND
	set	rvb, #0x00
	str	rvb, [rva, #0x04]	@ set all interrupts to IRQ in INTMOD
	ldr	rvb, =0x07ba
	str	rvb, [rva, #0x1c]	@ enab UART 0,2 Rx ints in INTSUBMSK

.ifdef	native_usb
	@ initialization of USB device controller
	ldr	rva, =0x31000000
	set	rvb, #0
	str	rvb, [rva]
	str	rvb, [rva, #4]
	set	fre, #0
	ldr	rva, =USB_LineCoding
	ldr	rvb, =115200
	str	rvb, [rva]		@ 115200 bauds
	set	rvb, #0x00080000
	str	rvb, [rva,  #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	rva, =USB_CHUNK
	str	fre, [rva]		@ 0 bytes remaining to send at startup
	ldr	rva, =USB_ZERO
	str	fre, [rva]		@ alt interface and dev/interface stat=0
	ldr	rva, =USB_CONF
	str	fre, [rva]		@ USB device is not yet configured
	@ signal to host that USB device is attached (set GPC15 low)
	ldr	rva, =0x56000020	@ rva <- GPCCON
	set	rvb, #0x8000
	str	rvb, [rva, #0x08]	@ disab pull-up on GPIO C, pin 15, GPC15
	set	rvb, #0x40000000
	str	rvb, [rva]		@ output dir for GPIO C, pin 15, GPC15
	ldr	rvb, [rva, #0x04]
	bic	rvb, rvb, #0x8000
	str	rvb, [rva, #0x04]	@ set GPC15 low
	
.endif	@ native_usb
	
	@ end of the hardware initialization
	set	pc,  lnk
	


/*------------------------------------------------------------------------------
@  S3C24xx
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/
	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

FlashInitCheck: @ return stat of boot override pin (GPG3, EINT11, nSS1) in rva
	ldr	rvb, =ioG_base		@ rvb <- adrs of pin direction control
	ldr	rva, [rvb, #io_state]	@ rva <- status of all pins
	and	rva, rva, #(1 << 3)	@ rva <- status of GPG3 only=return val
	set	pc,  lnk		@ return
	
wrtfla:	@ write to flash, sv2 is page address, sv4 is file descriptor
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5,  env, dts, glv} @ scheme regs to stack
	@ copy write-flash-code to boot SRAM
	ldr	sv1, =wflRAM		@ sv1 <- start address of flashing code
	ldr	sv5, =wflEND		@ sv5 <- end address of flashing code
	set	sv3, #0x40000000	@ sv3 <- target adrs for flashing code
	bl	cpflcd
	@ prepare to copy bfr dat from file desc (sv4) (RAM) to FLASH bfr (sv2)
	vcrfi	sv3, sv4, 3		@ sv3 <- buffer address	
	add	sv4, sv2, #F_PAGE_SIZE	@ sv4 <- end target address
wrtfl0:	bl	pgsctr			@ rva <- sctr num raw int, frm pag in r5
	ldr	rvb, =flashsectors	@ rvb <- address of flash sector table
	ldr	sv1, [rvb, rva, LSL #2]	@ sv1 <- adrs of flash page block start
	@ jump to SRAM code
	set	lnk, pc			@ lnk <- return address
	set	pc,  #0x40000000	@ jump to SRAM
	@ more data to write?
	cmp	sv2, sv4		@ done writing?
	bmi	wrtfl0			@	if not, jump to wrt dat to flash
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ rstr schm regs frm stk
	ldmfd	sp!, {rva, rvb, rvc, lnk} @ restore scheme registers from stack
	orr	fre, fre, #0x02		@ fre <- fre-ptr de-reserved
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

ersfla:	@ erase flash sector that contains page address in sv2
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme regs onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5,  env, dts, glv} @ scheme regs to stack
	@ copy erase-flash-code to boot SRAM
	ldr	sv1, =rflRAM		@ sv1 <- start address of flashing code
	ldr	sv5, =rflEND		@ sv5 <- end address of flashing code
	set	sv3, #0x40000000	@ sv3 <- boot SRAM start target address
	bl	cpflcd
	@ prepare flash sector for write
	bl	pgsctr			@ rva <- sctr num raw int, frm pag adrs
	ldr	rvb, =flashsectors	@ rvb <- address of flash sector table
	ldr	sv1, [rvb]		@ sv1 <- start address of whole flash
	ldr	sv2, [rvb, rva, LSL #2]	@ sv2 <- address of flash block start
	@ jump to SRAM code
	set	lnk, pc			@ lnk <- return address
	set	pc,  #0x40000000	@ jump to SRAM
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ rstr schm regs frm stk
	ldmfd	sp!, {rva, rvb, rvc, lnk} @ restore scheme registers from stack
	orr	fre, fre, #0x02		@ fre <- fre-ptr de-reserved
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return


cpflcd:	@ copy FLASH code to RAM
	ldr	rva, [sv1]		@ rva <- next flashing code instruction
	str	rva, [sv3]		@ store it in free RAM
	eq	sv1, sv5		@ done copying the flashing code?
	addne	sv1, sv1, #4		@	if not, sv1 <- next source adrs
	addne	sv3, sv3, #4		@	if not, sv1 <- next target adrs
	bne	cpflcd			@	if not, jump to keep copying
	set	pc,  lnk		@ return

	
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
	set	rvb, #3
	str	rvb, [rva, #0x0c]	@ sppre <- 60MHz/2/(3+1) ~= 6.3MHz
	set	rvb, #0x18
	str	rvb, [rva, #0x00]	@ spcon (ctrl) <- CLKen,master,POL=PHA=0
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	ldr	rva, =sd_spi
	set	rvb, #63
	str	rvb, [rva, #0x0c]	@ sppre <- 60MHz/2/(63+1) ~= 400KHz
	set	rvb, #0x18
	str	rvb, [rva, #0x00]	@ spcon (ctrl) <- CLKen,master,POL=PHA=0
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
@  S3C24xx
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
i2putp:	@ Prologue:	write addt'l adrs byts to i2c, from bfr or r12 (prlg)
i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	set	pc,  lnk






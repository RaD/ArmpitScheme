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
@  utility functions
@-----------------------------------------------------------------------------*/

pcfpwr:	@ (config-power bit val)
	@ sets/clears bit in PCU_BOOTCR (only BSPI0 and ADC are in there)
	@ on entry:	sv1 <- bit position	(scheme int)
	@ on entry:	sv2 <- val (1 or 0)	(scheme int)
	@ on exit:	sv1 <- npo
	set	sv3, sv1
	set	sv4, sv2
	ldr	rva, =rcc_base
	set	rvb, #0x50
	b	rcpbit
	
	
pcfgpn:	@ (config-pin main sub cfg)
	@ main:		0/1,  port
	@ sub:		0-15, pin on port
	@ cfg:		3-bit value for PC2, PC1, PC0,
	@		#b000 = analog input,	#b001  = TTL input
	@		#b010 = CMOS input,	#b011  = input with pull-up/dn
	@		#b100 = open-drain out,	#b101 = push-pull output
	@		#b110 = AF open-drain,	#b111 = AF push-pull
	@ on entry:	sv1 <- main (0 or 1)		(scheme int)
	@ on entry:	sv2 <- sub  (0 to 15)		(scheme int)
	@ on entry:	sv3 <- cfg  (eg. #b001)		(scheme int)
	@ on exit:	sv1 <- npo
	intgrp	sv3
	bne	corerr
	ldr	rva, =ioport1_base
	eq	sv1, #i0
	ldreq	rva, =ioport0_base
	eqne	sv1, #i1
	bne	corerr
	int2raw	rvb, sv2
	set	rvc, #1
	lsl	rvc, rvc, rvb
	@ configure PC0
	ldr	rvb, [rva, #0x00]
	tst	sv3, #0x04
	biceq	rvb, rvb, rvc
	orrne	rvb, rvb, rvc
	str	rvb, [rva, #0x00]
	@ configure PC1
	ldr	rvb, [rva, #0x04]
	tst	sv3, #0x08
	biceq	rvb, rvb, rvc
	orrne	rvb, rvb, rvc
	str	rvb, [rva, #0x04]
	@ configure PC2
	ldr	rvb, [rva, #0x08]
	tst	sv3, #0x10
	biceq	rvb, rvb, rvc
	orrne	rvb, rvb, rvc
	str	rvb, [rva, #0x08]
	b	npofxt

	
	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	swi	run_no_irq
	ldr	rvb, [rva, #io_state]	@ rvb <- pin statuses
	orr	rvb, rvb, rvc
	str	rvb, [rva, #io_state]	@ set pin
	swi	run_normal
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	swi	run_no_irq
	ldr	rvb, [rva, #io_state]	@ rvb <- pin statuses
	bic	rvb, rvb, rvc
	str	rvb, [rva, #io_state]	@ clear pin
	swi	run_normal
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva, #io_state]
	tst	rvb, rvc
	b	notfxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstop:	@ (stop tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
	set	rvb, #0
	str	rvb, [rva, #0x14]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstrt:	@ (restart tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
	set	rvb, #0x8000
	str	rvb, [rva, #0x14]
	set	rvb, #0
	str	rvb, [rva, #0x10]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
	lsl	rvb, rvb, #8
psppt0:	ldr	rvc, [rva, #spi_status]	@ ssta
	tst	rvc, #spi_txrdy
	beq	psppt0
	str	rvb, [rva, #spi_thr]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
pspget:	@ (spi-get port)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on exit:	sv1 <- data from spi		(scheme int)
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
pspgt0:	ldr	rvb, [rva, #spi_status]
	tst	rvb, #spi_rxrdy
	beq	pspgt0
	ldr	rvb, [rva, #spi_rhr]
	lsr	rvb, rvb, #8
	raw2int	sv1, rvb
	set	pc,  cnt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg





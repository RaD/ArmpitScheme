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
	@ sets/clears bit in SCU_PCGR1
	@ asserts/de-asserts reset in SCU_PRR1
	@ on entry:	sv1 <- bit position	(scheme int)
	@ on entry:	sv2 <- val (1 or 0)	(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rva, =sys_ctrl
	int2raw	rvb, sv1
	set	rvc, #1
	lsl	rvc, rvc, rvb
	@ set/clear power bit
	ldr	rvb, [rva, #0x18]
	eq	sv2, #i1
	orreq	rvb, rvb, rvc
	bicne	rvb, rvb, rvc
	str	rvb, [rva, #0x18]	@ SCU_PCGR1 <- updated power state
	@ set/clear reset bit
	ldr	rvb, [rva, #0x20]
	eq	sv2, #i1
	orreq	rvb, rvb, rvc
	bicne	rvb, rvb, rvc
	str	rvb, [rva, #0x20]	@ SCU_PRR1 <- updated reset state
	b	npofxt


pcfgpn:	@ (config-pin main sub . <ocfg> <afin> <otyp> <ana>)
	@ main:		0-7, port
	@ sub:		0-7, pin on port
	@ ocfg:		0-3, #b00=input, #b01=alt output 1, #b10=alt out 2, #b11=alt out 3
	@ afin:		0/1, alternate input 1
	@ otyp:		0/1, 0 = push-pull, 1 = open collector (gpio output only)
	@ ana:		0/1, 1 = analog in (gpio4 only)
	@ on entry:	sv1 <- main (0 or 7)			(scheme int)
	@ on entry:	sv2 <- sub  (0 to 7)			(scheme int)
	@ on entry:	sv3 <- (<ocfg> <afin> <otyp> <ana>)	(list)
	@ on exit:	sv1 <- npo
	set	sv4, sv1
	int2raw	rvb, sv1
	ldr	rvc, =sys_ctrl
	add	rvc, rvc, rvb, lsl #2
	@ configure output mode
	pntrp	sv3
	bne	npofxt
	snoc	sv1, sv3, sv3
	ldr	rva, [rvc, #0x44]
	orr	sv5, rvc, #i0
	int2raw	rvc, sv2
	and	rvc, rvc, #0x07
	lsl	rvc, rvc, #1
	set	rvb, #0x03
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb
	int2raw	rvb, sv1
	and	rvb, rvb, #0x03
	lsl	rvb, rvb, rvc
	orr	rva, rva, rvb
	bic	rvc, sv5, #i0
	str	rva, [rvc, #0x44]
	@ set single bit mask
	int2raw	rva, sv2
	set	rvb, #1
	lsl	rvb, rvb, rva
	@ configure input mode
	ldr	rva, [rvc, #0x64]
	bl	pcfgph
	str	rva, [rvc, #0x64]
	@ configure output type
	ldr	rva, [rvc, #0x84]
	bl	pcfgph
	str	rva, [rvc, #0x84]
	@ configure analog input
	eq	sv4, #((4 << 2) | i0)
	bne	npofxt
	ldr	rvc, =sys_ctrl
	ldr	rva, [rvc, #0xbc]
	bl	pcfgph
	str	rva, [rvc, #0xbc]
	b	npofxt
	
pcfgph:	@ pin configuration helper
	pntrp	sv3
	bne	npofxt
	snoc	sv1, sv3, sv3
	eq	sv1, #i1
	orreq	rva, rva, rvb
	bicne	rva, rva, rvb
	set	pc,  lnk


	EPFUNC	null, oregent, 3	@ primitive, init-sv4 = none, fentry = regent, narg = 3
ppstdr:	@ (pin-set-dir port pin dir)
	@ on entry:	sv1 <- port (gio0 to gio7)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on entry:	sv3 <- dir  (0=input, 1=output)	(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0-7 as full address (from sv1, through regent)
	set	rvb, #io_dir		@ rvb <- 0x08 = offset to pin dir reg in gio0/1
	set	sv4, sv3
	set	sv3, sv2
	b	rcpbit


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio0-7)		(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0-7 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #4
	lsl	rvc, rvc, rvb
	set	rvb, #0xff
	str	rvb, [rva, rvc]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio0-7)		(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0-7 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #4
	lsl	rvc, rvc, rvb
	set	rvb, #0x00
	str	rvb, [rva, rvc]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gio0-7)		(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	@ rva <- gio0-7 as full address (from sv1, through regent)
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
	set	rvb, #0
	str	rvb, [rva, #0x14]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstrt:	@ (restart tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	set	rvb, #0x8000
	str	rvb, [rva, #0x14]
	set	rvb, #0
	str	rvb, [rva, #0x10]	@ Note:	this may be read-only
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
psppt0:	ldr	rvc, [rva, #spi_status]	@ ssta
	tst	rvc, #spi_txrdy
	beq	psppt0
	str	rvb, [rva, #spi_thr]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
pspget:	@ (spi-get port)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on exit:	sv1 <- data from spi		(scheme int)
pspgt0:	ldr	rvb, [rva, #spi_status]
	tst	rvb, #spi_rxrdy
	beq	pspgt0
	ldr	rvb, [rva, #spi_rhr]
	raw2int	sv1, rvb
	set	pc,  cnt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg






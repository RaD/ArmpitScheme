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


pcfpwr:	@ (config-power rgc bit val)
	@ on entry:	sv1 <- rgc 			(scheme int)
	@		(eg. 1, 2 for RCGC1, RCGC2, or 4, 8, 12 ... for RCGCTIMER, RCGCGPIO, ...)
	@ on entry:	sv2 <- bit position		(scheme int)
	@ on entry:	sv3 <- val (1 or 0)		(scheme int)
	@ on exit:	sv1 <- npo
	set	sv4, sv3
	set	sv3, sv2
	ldr	rva, =rcc_base
	tst	sv1, #0x0c
	itTEE	eq
	lsreq	rvb, sv1, #2
	orreq	rvb, rvb, #0x600
	bicne	rvb, sv1, #0x03
	orrne	rvb, rvb, #0x100
	b	rcpbit
	
	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
pcfgpn:	@ (config-pin port pin den odr pur pdr dir dr2r dr8r afun)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin  (0 to 7)		(scheme int)
	@ on entry:	sv3 <- (den odr pur pdr dir dr2r dr8r afun)
	@ on exit:	sv1 <- npo
	@ rva <- gioa-h as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	add	rva, rva, #0x0500
	set	rvc, #1
	lsl	rvc, rvc, rvb
	add	rva, rva, #0x001c	@ rva <- port + #x51c, for den
	bl	pcfghl
	sub	rva, rva, #0x0010	@ rva <- port + #x50c, for odr
	bl	pcfghl
	add	rva, rva, #0x0004	@ rva <- port + #x510, for pur
	bl	pcfghl
	add	rva, rva, #0x0004	@ rva <- port + #x514, for pdr
	bl	pcfghl
	sub	rva, rva, #0x0014
	sub	rva, rva, #0x0100	@ rva <- port + #x400, for dir
	bl	pcfghl
	add	rva, rva, #0x0100	@ rva <- port + #x500, for dr2r
	bl	pcfgdr
	add	rva, rva, #0x0008	@ rva <- port + #x508, for dr8r
	bl	pcfgdr
	sub	rva, rva, #0x0100
	add	rva, rva, #0x0018	@ rva <- port + #x420, for afun
	bl	pcfghl
	b	npofxt

pcfgdr:	@ helper entry for dr2r and dr8r
	nullp	sv3
	beq	npofxt
	car	sv2, sv3
	eq	sv2, #i0
	itT	eq
	cdreq	sv3, sv3
	seteq	pc,  lnk
pcfghl:	@ helper function, general entry
	nullp	sv3
	beq	npofxt
	snoc	sv2, sv3, sv3
	ldr	rvb, [rva]
	eq	sv2, #i0
	itE	eq
	biceq	rvb, rvb, rvc
	orrne	rvb, rvb, rvc
	str	rvb, [rva]
	set	pc,  lnk
	
	
	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gioa-h as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #4
	lsl	rvc, rvc, rvb
	set	rvb, #0xff
	str	rvb, [rva, rvc]
	b	npofxt
		
	
	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gioa-h as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #4
	lsl	rvc, rvc, rvb
	set	rvb, #0x00
	str	rvb, [rva, rvc]
	b	npofxt

	
	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	@ rva <- gioa-h as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva, #io_state]
	tst	rvb, rvc
	b	notfxt


ptstop:	@ (tic-stop)
	@ stop the systick timer
	@ on exit:	sv1 <- npo
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	set	rvb, #0
	str	rvb, [rva, #tick_ctrl]
	swi	run_normal		@ set Thread mode, unprivileged, with IRQ (user)
	b	npofxt


ptstrt:	@ (tic-start bool)
	@ start the systick timer (without interrupt generation if bool = #f)
	@ on entry:	sv1 <- #f (no interrupts) or anything else, including null (interrupts)
	@ on exit:	sv1 <- npo
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	set	rvb, #0
	str	rvb, [rva, #tick_ctrl]
	str	rvb, [rva, #tick_val]
	eq	sv1, #f
	itE	eq
	seteq	rvb, #0x05
	setne	rvb, #0x07
	str	rvb, [rva, #tick_ctrl]
	swi	run_normal		@ set Thread mode, unprivileged, with IRQ (user)
	b	npofxt


ptkred:	@ (tic-read)
	@ read current value of the systick timer
	@ on exit:	sv1 <- value from systick timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	ldr	rvb, [rva, #tick_val]
	raw2int	sv1, rvb
	swi	run_normal		@ set Thread mode, unprivileged, with IRQ (user)
	set	pc,  cnt

	
	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
	ldr	rvc, [rva, #spi_status]
	tst	rvc, #spi_txrdy
	beq	pspput
	str	rvb, [rva, #spi_thr]
	b	npofxt

	
	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
pspget:	@ (spi-get port)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on exit:	sv1 <- data from spi		(scheme int)
	ldr	rvb, [rva, #spi_status]
	tst	rvb, #spi_rxrdy
	beq	pspget
	ldr	rvb, [rva, #spi_rhr]
	raw2int	sv1, rvb
	set	pc,  cnt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg




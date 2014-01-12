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


@-------------------------------------------------------------------------------
@  utility functions
@-------------------------------------------------------------------------------

	
pcfpwr:	@ (config-power bit val)
	@ on entry:	sv1 <- bit position	(scheme int)
	@ on entry:	sv2 <- val (1 or 0)	(scheme int)
	@ on exit:	sv1 <- npo
	set	sv3, sv1
	set	sv4, sv2
	ldr	rva, =sys_ctrl
	set	rvb, #0xc4
	b	rcpbit
	
	
pcfgpn:	@ (config-pin main sub cfg <mod>)
	@ on entry:	sv1 <- main (0 or 1)		(scheme int)
	@ on entry:	sv2 <- sub  (0 to 31)		(scheme int)
	@ on entry:	sv3 <- cfg (eg. #b01)		(scheme int)
	@ on entry:	sv4 <- mod or null (eg. #b11)	(scheme int or no arg)
	@ on exit:	sv1 <- npo
	int2raw	rvc, sv1
	lsl	rvc, rvc, #3
	cmp	sv2, #65
	addpl	rvc, rvc, #4
	raw2int	sv5, rvc
	ldr	rvb, =PINSEL0
	ldr	rva, [rvb, rvc]
	int2raw	rvc, sv2
	and	rvc, rvc, #0x0f
	lsl	rvc, rvc, #1
	set	rvb, #0x03
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb
	int2raw	rvb, sv3
	lsl	rvb, rvb, rvc
	orr	rva, rva, rvb
	int2raw	rvc, sv5
	ldr	rvb, =PINSEL0
	str	rva, [rvb, rvc]
.ifdef LPC2478_STK
	int2raw	rvc, sv5
	ldr	rvb, =pmod0_base
	ldr	rva, [rvb, rvc]
	int2raw	rvc, sv2
	and	rvc, rvc, #0x0f
	lsl	rvc, rvc, #1
	set	rvb, #0x03
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb
	int2raw	rvb, sv4
	lsl	rvb, rvb, rvc
	orr	rva, rva, rvb
	int2raw	rvc, sv5
	ldr	rvb, =pmod0_base
	str	rva, [rvb, rvc]
.endif
	b	npofxt


	EPFUNC	null, oregent, 3	@ primitive, init-sv4 = none, fentry = regent, narg = 3
ppstdr:	@ (pin-set-dir port pin dir)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on entry:	sv3 <- dir  (0=input, 1=output)	(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0/1 as full address (from sv1, through regent)
	set	rvb, #io_dir		@ rvb <- 0x08 = offset to pin dir reg in gio0/1
	set	sv4, sv3
	set	sv3, sv2
	b	rcpbit


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_set]
	b	npofxt
		

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_clear]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
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
	set	rvb, #0
	str	rvb, [rva, #0x04]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstrt:	@ (restart tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	set	rvb, #2
	str	rvb, [rva, #0x04]
	set	rvb, #1
	str	rvb, [rva, #0x04]
	b	npofxt

.ifndef LPC2478_STK

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
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

.endif	@ .ifndef LPC2478_STK

	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg







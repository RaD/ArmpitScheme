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


pcfgpn:	@ (config-pin main sub m0 m1)
	@ m0 m1:	0 0 -> GP input,	0 1 -> GP output low
	@		1 0 -> peripheral func,	1 1 -> GP output high
	@ on entry:	sv1 <- main (0 to  7)		(scheme int)
	@ on entry:	sv2 <- sub  (0 to 31)		(scheme int)
	@ on entry:	sv3 <- m0   (0 or  1)		(scheme int)
	@ on entry:	sv4 <- m1   (0 or  1)		(scheme int)
	@ on exit:	sv1 <- npo
	@ calculate address
	int2raw	rvc, sv1
	set	rvb, #0x40
	mul	rvb, rvc, rvb
	ldr	rva, =io0_base
	add	rva, rva, rvb
	@ position update bit
	int2raw	rvc, sv2
	set	rvb, #1
	lsl	rvb, rvb, rvc
	@ set MODE 0
	eq	sv3, #i1
	streq	rvb, [rva, #0x14]
	strne	rvb, [rva, #0x18]
	@ set MODE 1
	eq	sv4, #i1
	streq	rvb, [rva, #0x24]
	strne	rvb, [rva, #0x28]
	@ return
	b	npofxt

	EPFUNC	0, oregent, 2		@ primitive,in-sv4=no,fent=regent,narg=2
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

	EPFUNC	0, oregent, 2		@ primitive,in-sv4=no,fent=regent,narg=2
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

	EPFUNC	0, oregent, 2		@ primitive,in-sv4=no,fent=regent,narg=2
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

	EPFUNC	0, oregent, 1		@ primitive,in-sv4=no,fent=regent,narg=1
ptstop:	@ (stop tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	set	rvb, #0
	str	rvb, [rva, #0x08]
	b	npofxt

	EPFUNC	0, oregent, 1		@ primitive,in-sv4=no,fent=regent,narg=1
ptstrt:	@ (restart tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rvb, =2344
	str	rvb, [rva, #0x00]
	set	rvb, #0xc8
	str	rvb, [rva, #0x08]
	b	npofxt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg




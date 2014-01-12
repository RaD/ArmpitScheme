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


	EPFUNC	null, oregent, 3		@ primitive,in-sv4=no,fent=regent,narg=3
ppin:	@ (pin port pin <set/clear>)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on entry:	sv3 <- <set/clear>		(scheme boolean)
	@ on exit:	sv1 <- pin-status		(scheme boolean)
	@ rva <- gioa-h as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	nullp	sv3
	beq	ppinxt
	set	rvc, #4
	lsl	rvc, rvc, rvb
	eq	sv3, #f
	itE	eq
	seteq	rvb, #0x00
	setne	rvb, #0xff
	str	rvb, [rva, rvc]
	b	npofxt
ppinxt:	@ read pin status and return
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva, #io_state]
	tst	rvb, rvc
	b	notfxt


	PFUNC	2			@ primitive function, two input args
ptic:	@ (tic <on/off> <int>)
	@ with 0 args:		read  value of systick timer (also w/on/off=())
	@ with on/off = #f:	stop  systick timer
	@ else:			start systick timer w/ints if int is not #f
	@ on entry:	sv1 <- <on/off>
	@ on entry:	sv2 <- <int>
	@ on exit:	sv1 <- value from systick timer or npo
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ
	ldr	rva, =systick_base
	nullp	sv1
	beq	pticxt
	set	rvb, #0
	str	rvb, [rva, #tick_ctrl]
	eq	sv1, #f
	beq	pticxt
	str	rvb, [rva, #tick_val]
	eq	sv2, #f
	itE	eq
	seteq	rvb, #0x05
	setne	rvb, #0x07
	str	rvb, [rva, #tick_ctrl]
pticxt:	@ return
	ldr	rvb, [rva, #tick_val]
	raw2int sv1, rvb
	swi	run_normal		@ set Thread mode, unprivileged, w/IRQ
	set	pc,  cnt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg






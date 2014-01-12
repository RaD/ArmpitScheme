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

/*----------------------------------------------------------------------------*\
|
|  0.G.	  ASSEMBLER MACROS for SCHEME
|
\*----------------------------------------------------------------------------*/

.macro _func_
  .ifdef cortex
	.thumb_func
  .endif
.endm

.macro	SYMSIZE n
	.balign	8
	.word	(\n << 8) | symbol_tag
.endm

.macro	VECSIZE n
	.balign	8
	.word	((\n) << 8) | vector_tag
.endm

.macro	VU8SIZE n
	.balign	8
	.word	((\n) << 8) | bytevector_tag
.endm

.macro	DSYNTAX fname, target, narg
	.word	\fname
	.hword	(1 << 12) | (1 << 11) | (\narg << 8) | bltn
	.hword	(\target - start_of_code) | lnkbit0
.endm

.macro	DESYNTAX fname, initsv4, fentry, narg
	.word	\fname
	.word	((\initsv4)<<16)|(\fentry<<24)|(3<<12)|(1<<11)|(\narg<<8)|bltn
.endm

.macro	PFUNC narg
	.balign	8
	.word	(\narg << 8) | proc
.endm

.macro	EPFUNC initsv4, fentry, narg
	.balign	8
	.word	((\initsv4) << 16)|(\fentry << 24)|(3 << 12)|(\narg << 8)|proc
.endm

.macro	DPFUNC fname, target, narg
	.word	\fname
	.hword	(1 << 12) | (\narg << 8) | bltn
	.hword	(\target - start_of_code) | lnkbit0
.endm

.macro	DEPFUNC fname, initsv4, fentry, narg
	.word	\fname
	.word	((\initsv4) << 16)|(\fentry << 24)|(3 << 12)|(\narg << 8)|bltn
.endm

.macro	UPFUNC target, narg
	.hword	(1 << 12) | (\narg << 8) | bltn
	.hword	(\target - start_of_code) | lnkbit0
.endm

.macro	MACRO
	.balign	8
	.word	(1 << 11) | proc
.endm

.macro	r2i rawint
	((\rawint << 2) | i0)
.endm

/*------------------------------------------------------------------------------
	4.1.6. Assignments
------------------------------------------------------------------------------*/

.macro set var, expr
	mov	\var,  \expr
.endm

.macro seteq var, expr
	moveq	\var,  \expr
.endm

.macro setne var, expr
	movne	\var,  \expr
.endm

.macro setmi var, expr
	movmi	\var,  \expr
.endm

.macro setpl var, expr
	movpl	\var,  \expr
.endm

.macro setls var, expr
	movls	\var,  \expr
.endm

.macro sethi var, expr
	movhi	\var,  \expr
.endm

/*------------------------------------------------------------------------------
	6.1. Equivalence predicates
------------------------------------------------------------------------------*/

.macro eq obj1, obj2
	teq	\obj1,  \obj2
.endm

.macro eqeq obj1, obj2
	teqeq	\obj1,  \obj2
.endm

.macro eqne obj1, obj2
	teqne	\obj1,  \obj2
.endm

/*------------------------------------------------------------------------------
	6.2.5. Numerical operations (including addendum)
------------------------------------------------------------------------------*/

.macro incr dest, source
	add	\dest,  \source, #4
.endm

.macro increq dest, source
	addeq	\dest,  \source, #4
.endm

.macro incrne dest, source
	addne	\dest,  \source, #4
.endm

.macro decr dest, source
	sub	\dest,  \source, #4
.endm

.macro decrne dest, source
	subne	\dest,  \source, #4
.endm

.macro intgrp obj
	@ raise eq flag if obj is an integer
	@ uses rva
	and	rva, \obj,  #0x03	@ rva <- two-bit tag of object in num
	eq	rva, #int_tag		@ is object an integer?
.endm

.macro intgrpeq obj
	@ raise eq flag if obj is an integer
	@ uses rva
	itT	eq
	andeq	rva, \obj,  #0x03	@ rva <- two-bit tag of object in num
	eqeq	rva, #int_tag		@ is object an integer?
.endm

.macro intgrpne obj
	@ raise eq flag if obj is an integer
	@ modifies:	rva
	itT	ne
	andne	rva, \obj,  #0x03	@ rva <- two-bit tag of object in num
	eqne	rva, #int_tag		@ is object an integer?
.endm

.macro floatp obj
	@ raise eq flag if obj is a float
	@ modifies:	rva
	and	rva, \obj,  #0x03	@ rva <- two-bit tag of object in num
	eq	rva, #float_tag		@ is object a float?
.endm

.macro ratiop obj
	@ raise eq flag if obj is a rational
	@ modifies:	rva
	and	rva, \obj, #0x07
	eq	rva, #0x04
	itTT	eq
	ldreq	rva, [\obj, #-4]
	andeq	rva, rva,  #0x0F	@ rva <- four-bit tag of object
	eqeq	rva, #rational_tag	@ is object a rational?
.endm

.macro cmplxp obj
	@ raise eq flag if obj is a complex
	@ modifies:	rva
	and	rva, \obj, #0x07
	eq	rva, #0x04
	itTT	eq
	ldreq	rva, [\obj, #-4]
	andeq	rva, rva,  #0x0F	@ rva <- four-bit tag of object
	eqeq	rva, #complex_tag	@ is object a complex?
.endm

.macro zero obj
	eq	\obj, #i0
	it	ne
	eqne	\obj, #f0
.endm

.macro zerop obj
	eq	\obj, #i0
	it	ne
	eqne	\obj, #f0
.endm

.macro zeropne obj
	eqne	\obj, #i0
	it	ne
	eqne	\obj, #f0
.endm

.macro anyzro obj1, obj2
	eq	\obj1, #i0
	it	ne
	eqne	\obj1, #f0
	it	ne
	eqne	\obj2, #i0
	it	ne
	eqne	\obj2, #f0
.endm

.macro isnan obj
	ldr	rva, =scheme_nan	@ rva <- nan
	eq	\obj, rva		@ is obj = nan ?
.endm
	
.macro anynan obj1, obj2
	ldr	rvc, =scheme_nan	@ rvc <- nan
	eq	\obj1, rvc		@ is obj1 = nan ?
	it	ne
	eqne	\obj2, rvc		@	if not, is obj2 = nan ?
.endm

.macro isinf obj
	ldr	rva, =scheme_inf	@ rva <- inf
	fabs	rvb, \obj		@ rvb <- obj without sign
	eq	rvb, rva		@ is x1 = +/-inf ?
.endm
	
.macro anyinf obj1, obj2
	ldr	rva, =scheme_inf	@ rva <- inf
	bic	rvb, \obj1, #0x80000000	@ rvb <- x1 without sign
	eq	rvb, rva		@ is x1 = +/-inf ?
	itT	ne
	bicne	rvb, \obj2, #0x80000000	@ rvb <- x1 without sign
	eqne	rvb, rva		@ is x1 = +/-inf ?
.endm
	
.macro plus dest, val1, val2
	add	\dest, \val1, \val2
	eor	\dest, #0x03
.endm

.macro plusne dest, val1, val2
	addne	\dest, \val1, \val2
	it	ne
	eorne	\dest, #0x03
.endm

.macro ngflt dest, val
	eor	\dest, \val, #0x80000000	@ dest <- -val
.endm

.macro ngflteq dest, val
	eoreq	\dest, \val, #0x80000000	@ dest <- -val
.endm

.macro ngfltne dest, val
	eorne	\dest, \val, #0x80000000	@ dest <- -val
.endm

.macro ngfltmi dest, val
	eormi	\dest, \val, #0x80000000	@ dest <- -val
.endm

.macro ngint dest, val
	mvn	\dest, \val
	add	\dest, \dest, #3
.endm

.macro nginteq dest, val
	mvneq	\dest, \val
	it	eq
	addeq	\dest, \dest, #3
.endm

.macro ngintne dest, val
	mvnne	\dest, \val
	it	ne
	addne	\dest, \dest, #3
.endm

.macro ngintmi dest, val
	mvnmi	\dest, \val
	it	mi
	addmi	\dest, \dest, #3
.endm

.macro postv num
	tst	\num, #0x80000000
.endm

.macro postveq num
	tsteq	\num, #0x80000000
.endm

.macro postvne num
	tstne	\num, #0x80000000
.endm

.macro iabs dest, val
	postv	\val
	itEE	eq
	seteq	\dest, \val
	mvnne	\dest, \val
	addne	\dest, \dest, #3
.endm

.macro fabs dest, val
	bic	\dest, \val, #0x80000000	@ \dest <- unsigned \val (scheme float)	
.endm

.macro rawsplt wrd1, wrd2, ratcpx
	@ returns the two parts (raw) of a  rat/cpx
	@ wrd1 and wrd2 registers should be ascending
  .ifndef cortex
	ldmda	\ratcpx, {\wrd1, \wrd2}		@ <- this may be backwards (wrd1 vs wrd2)
  .else
	ldr	\wrd1, [\ratcpx, #-4]
	ldr	\wrd2, [\ratcpx]
  .endif
.endm
	
.macro rwspleq wrd1, wrd2, ratcpx
	@ returns the two parts (raw) of a  rat/cpx
	@ wrd1 and wrd2 registers should be ascending
  .ifndef cortex
	ldmdaeq	\ratcpx, {\wrd1, \wrd2}		@ <- this may be backwards (wrd1 vs wrd2)
  .else
	ldreq	\wrd1, [\ratcpx, #-4]
	it	eq
	ldreq	\wrd2, [\ratcpx]
  .endif
.endm
	
.macro numerat dest, rat
	@ returns the numerator (scheme int) of a rational
	@ modifies:	rva, rvb
	rawsplt	rva, rvb, \rat
	lsr	rva, rva, #2
	orr	rva, rva, rvb, lsl #30
	orr	\dest, rva, #int_tag
.endm
	
.macro nmrtreq dest, rat
	@ returns the numerator (scheme int) of a rational
	@ modifies:	rva, rvb
	rwspleq rva, rvb, \rat
	itTT	eq
	lsreq	rva, rva, #2
	orreq	rva, rva, rvb, lsl #30
	orreq	\dest, rva, #int_tag
.endm
	
.macro denom dest, rat
	@ returns the denominator (scheme int) of a rational
	@ modifies:	rva
	ldr	rva, [\rat]
	bic	rva, rva, #3
	orr	\dest, rva, #int_tag
.endm

.macro spltrat nmr, dnm, rat
	@ returns the numerator (scheme int) and denominator (scheme int) of a rational
	@ modifies:	rva, rvb
	rawsplt	rva, rvb, \rat
	lsr	rva, rva, #2
	orr	rva, rva, rvb, lsl #30	
	bic	rvb, rvb, #3
	orr	\nmr, rva, #int_tag
	orr	\dnm, rvb, #int_tag
.endm

.macro real dest, cpx
	@ returns the real part (scheme float) of a complex
	@ modifies:	rva, rvb
	rawsplt	rva, rvb, \cpx
	lsr	rva, rva, #2
	orr	\dest, rva, rvb, lsl #30
.endm

.macro imag dest, cpx
	@ returns the imaginary (scheme float) of a complex
	@ modifies:	rva
	ldr	rva, [\cpx]
	bic	rva, rva, #3
	orr	\dest, rva, #float_tag
.endm

.macro spltcpx real, imag, cpx
	@ returns the real part (scheme float) and imaginary part (scheme float) of a complex
	@ modifies:	rva, rvb
	rawsplt	rva, rvb, \cpx
	lsr	rva, rva, #2
	orr	\real, rva, rvb, lsl #30
	bic	rvb, rvb, #3
	orr	\imag, rvb, #float_tag
.endm
	
.macro ngnum dest, num
	tst	\num, #int_tag		@ is val a integer?
	itE	eq
	ngflteq	\dest, \num
	ngintne	\dest, \num
.endm

.macro fltmte exp, num
	@ convert float to 'in-place' mantissa and biased exponent
	@ on entry:	num <- float (scheme float)
	@ on exit:	num <- signed 'in-place' mantissa of input num (scheme int)
	@ on exit:	exp <- biased exponent of input num (raw int)
	@ modifies:	num, exp
	lsr	\exp, \num, #23			@ \exp  <- exponent and sign (raw)
	bic	\num, \num, \exp, lsl #23	@ \num <- mantis of \num (pseudo scheme float)
	eor	\num, \num, #0x03		@ \num <- mantissa of \num (scheme int)
	tst	\exp, #0xff			@ is exponent zero ?
	itEE	ne
	orrne	\num, \num, #0x00800000		@	if not, \num <- mantissa with 1. of normalization
	lsleq	\num, \num, #1			@	if so,  \num <- mantis shftd lft (psd scheme float)
	eoreq	\num, \num, #0x03		@	if so,  \num <- mantissa shifted left (scheme int)
	tst	\exp, #0x0100			@ is number positive?
	itTT	ne
	bicne	\exp, \exp, #0x0100		@	if not, \exp <- expon without sign of num (raw int)
	mvnne	\num, \num			@	if not, negate mantissa
	addne	\num, \num, #3			@	if not, negate mantissa
.endm

/*------------------------------------------------------------------------------
	6.3.2. Pairs and lists
------------------------------------------------------------------------------*/


.macro memsetlnk
  .ifndef cortex
	sub	lnk, pc,  #4		@ lnk <- memory transaction return adrs
  .else
	set	lnk, pc
	nop
	orr	lnk, lnk,  #lnkbit0	@ lnk <- mem trnsct ret adrs Thumb2 mode
  .endif
.endm

.macro memfrchk8
	eor	fre, fre, #0x03		@ fre <- ...bbb01	(reserv level 1)
	vcrfi	rva, glv, 1		@ rva <- heaptop -- from global vector
	cmp	rva, fre		@ is a 16-byte cell available?
.endm

.macro memfrck bytes
	eor	fre, fre, #0x03		@ fre <- ...bbb01	(reserv level 1)
	vcrfi	rva, glv, 1		@ rva <- heaptop -- from global vector
	sub	rva, rva, #(\bytes - 8)	@ rva <- comparison address
	cmp	rva, fre		@ is a 16-byte cell available?
.endm

.macro cons1 upd, dest, car, cdr
	@ upd is rva without MPU or fre with MPU
	bic	\upd, fre, #0x03	@ upd  <- free cell address and, with MPU, (reservation level 2)
	stmia	\upd!, {\car, \cdr}	@ upd  <- address of next free cell, and store car, cdr in free cell
	sub	\dest, \upd, #8		@ dest <- address of save cell, [*commit save destination*]
	orr	fre, \upd, #0x02	@ de-reserve free-pointer, [*restart critical instruction*]
.endm

.macro icons dest, car, cdr
	@ inlined cons or cons with MPU enabled
	@ dest <- (car . cdr)
  .ifdef enable_MPU
  	cons1	fre, \dest, \car, \cdr	@ reserve, store, commit and de-reserve
  .else
	memsetlnk			@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrchk8			@ reserve memory, sufficient space available?
	bls	alogc8			@	if not,  jump to perform gc
  	cons1	rva, \dest, \car, \cdr	@ store, commit and de-reserve
  .endif
.endm

.macro cons dest, car, cdr
	@ generic cons
	@ dest <- (car . cdr)
  .ifdef enable_MPU
	icons	\dest, \car, \cdr
  .else
    .ifdef inline_cons
	icons	\dest, \car, \cdr
    .else
	bl	cons			@ rva <- addr of fre cel (gc if ndd), rvb <- 8, fre-ptr rsrvd lvl 1
	stmia	rva!, {\car, \cdr}	@ rva <- addr of next free cell, + store car-cdr in prior free cell
	sub	\dest, rva, #8		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .endif
  .endif
.endm

.macro list1 upd, dest, obj
	bic	\upd, fre, #0x03	@ upd <- address of allocated memory
	set	rvc, #null
	stmia	\upd!, {\obj, rvc}	@ upd <- addr of next free cell, + store car-cdr in prior free cell
	sub	\dest, \upd, #8		@ \dest <- address of cons cell, [*commit list destination*]
	orr	fre, \upd, #0x02	@ de-reserve free-pointer, [*restart critical instruction*]
.endm

.macro ilist dest, obj
	@ inlined list or list with MPU
	@ dest <- (obj)  -- i.e. obj consed with #null
	@ modifies:	rvc
  .ifdef enable_MPU
  	list1	fre, \dest, \obj	@ reserve, store, commit and de-reserve
  .else
	memsetlnk			@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrchk8			@ reserve memory, sufficient space available?
	bls	alogc8			@	if not,  jump to perform gc
  	list1	rva, \dest, \obj	@ store, commit and de-reserve
  .endif
.endm

.macro list dest, obj
	@ generic list
	@ dest <- (obj)  -- i.e. obj consed with #null
  .ifdef enable_MPU
	ilist	\dest, \obj
  .else
    .ifdef inline_cons
	ilist	\dest, \obj
    .else
	bl	cons			@ rva <- addr of fre cel (gc if ndd), rvb <- 8, fre-ptr rsrvd lvl 1
	stmia	rva!, {\obj, rvc}	@ rva <- addr of next free cell, + store car-cdr in prior free cell
	sub	\dest, rva, #8		@ \dest <- address of cons cell, [*commit list destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .endif
  .endif
.endm


.macro bcons1 upd, dest, bcar, bcdr, rest
	@ upd is rva without MPU or fre with MPU
	bic	\upd, fre, #0x03	@ rva <- address of allocated memory
	set	rvc, \upd
 	stmia	\upd!, {\bcar,\bcdr,rvc}
	stmia	\upd!, {\rest}
	sub	\dest, \upd, #8		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, \upd, #0x02	@ de-reserve free-pointer, [*restart critical instruction*]
.endm

.macro ibcons dest, bcar, bcdr, rest
  .ifdef enable_MPU
  	bcons1	fre, \dest, \bcar, \bcdr, \rest	@ reserve, store, commit and de-reserve
  .else
	memsetlnk				@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrck	16				@ reserve memory, sufficient space available?
	bls	algc16				@	if not,  jump to perform gc
  	bcons1	rva, \dest, \bcar, \bcdr, \rest	@ store, commit and de-reserve
  .endif
.endm

.macro bcons dest, bcar, bcdr, rest
	@ generic cons-binding
	@ dest <- ((bcar . bcdr) . rest)
  .ifdef enable_MPU
	ibcons	\dest, \bcar, \bcdr, \rest
  .else
    .ifdef inline_cons
	ibcons	\dest, \bcar, \bcdr, \rest
    .else
	bl	cons2
	stmia	rva!, {\bcar,\bcdr,rvc}
	stmia	rva!, {\rest}
	sub	\dest, rva, #8		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .endif
  .endif
.endm

.macro cons2 upd, dest, car, cdr, cddr
	bic	\upd, fre, #0x03		@ rva <- address of allocated memory
	set	rvc, \upd
 	stmia	\upd!, {\cdr,\cddr}
	stmia	\upd!, {\car,rvc}
	sub	\dest, \upd, #8		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, \upd, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
.endm

.macro lcons dest, car, cdr, cddr
	@ generic lcons: cons 2 items onto cddr
	@ dest <- (car . (cdr . cddr))
  .ifdef enable_MPU
	cons2	fre, \dest, \car, \cdr, \cddr
  .else
    .ifdef inline_cons
	memsetlnk				@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrck	16				@ reserve memory, sufficient space available?
	bls	algc16				@	if not,  jump to perform gc
	cons2	rva, \dest, \car, \cdr, \cddr
    .else
	bl	cons2
	stmia	rva!, {\cdr,\cddr}
	stmia	rva!, {\car,rvc}
	sub	\dest, rva, #8		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .endif
  .endif
.endm

.macro cons3 upd, dest, car, cdr, cddr, cdddr
	@ dest <- (car . (cdr . (cddr . cdddr)))
	bic	\upd, fre, #0x03	@ rva <- address of allocated memory
	set	rvc, \upd
	stmia	\upd!, {\cddr, \cdddr}
	stmia	\upd!, {\cdr, rvc}
	sub	rvc, \upd, #8
	stmia	\upd!, {\car, rvc}
	sub	\dest, \upd, #8		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, \upd, #0x02	@ de-reserve free-pointer, [*restart critical instruction*]
.endm

.macro illcons dest, car, cdr, cddr, cdddr
	@ llcons with inline cons or enable_MPU
	@ dest <- (car . (cdr . (cddr . cdddr)))
  .ifdef enable_MPU
	cons3	fre, \dest, \car, \cdr, \cddr, \cdddr	@ reserve, store, commit and de-reserve
  .else
	memsetlnk					@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrck	24					@ reserve memory, sufficient space available?
	bls	algc24					@	if not,  jump to perform gc
	cons3	rva, \dest, \car, \cdr, \cddr, \cdddr	@ store, commit and de-reserve
  .endif
.endm

.macro llcons dest, car, cdr, cddr, cdddr
	@ generic llcons: cons 3 items onto cdddr
	@ dest <- (car . (cdr . (cddr . cdddr)))
  .ifdef enable_MPU
	illcons	\dest, \car, \cdr, \cddr, \cdddr
  .else
    .ifdef inline_cons
	illcons	\dest, \car, \cdr, \cddr, \cdddr
    .else
	bl	cons3
	stmia	rva!, {\cddr,\cdddr}
	stmia	rva!, {\cdr}
	stmia	rva!, {rvb,\car,rvc}
	sub	\dest, rva, #8		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .endif
  .endif
.endm

.macro isave reg
	@ inlined save or save with MPU
	@ dts <- (reg . dts)
  .ifdef enable_MPU
  	cons1	fre, dts, \reg, dts
  .else
	memsetlnk
	memfrchk8
	bls	alogc8			@	if not,  jump to perform gc
  	cons1	rva, dts, \reg, dts
  .endif
.endm

.macro save reg
	@ generic save
	@ dts <- (reg . dts)
  .ifdef enable_MPU
	isave	\reg
  .else
    .ifdef inline_cons
	isave	\reg
    .else
	bl	save			@ dts <- updated scheme stack with free car or 1st cell
	setcar	dts, \reg		@ update car of the updated dts
    .endif
  .endif
.endm


.macro save2 reg1, reg2
	lcons	dts, \reg1, \reg2, dts
.endm

.macro save3 reg1, reg2, reg3
	llcons	dts, \reg1, \reg2, \reg3, dts
.endm

.macro restor reg
	ldmia	dts, {\reg, dts}
.endm

.macro restoreq reg
	ldmiaeq	dts, {\reg, dts}
.endm

.macro restorne reg
	ldmiane	dts, {\reg, dts}
.endm

.macro restorpl reg
	ldmiapl	dts, {\reg, dts}
.endm

.macro restormi reg
	ldmiami	dts, {\reg, dts}
.endm

.macro restor2 reg1, reg2
	ldmia	dts, {\reg1, dts}
	ldmia	dts, {\reg2, dts}
.endm

.macro restor2ne reg1, reg2
	ldmiane	dts, {\reg1, dts}
	ldmiane	dts, {\reg2, dts}
.endm

.macro restor3 reg1, reg2, reg3
	ldmia	dts, {\reg1, dts}
	ldmia	dts, {\reg2, dts}
	ldmia	dts, {\reg3, dts}
.endm


.macro tagwenv dest, tag, obj1, obj2
	@ dest <- [tag obj1 obj2 env]
  .ifdef enable_MPU
	bic	fre, fre, #0x03		@ rva <- address of allocated memory
  	set	rva, \tag		@ rva <- tag
	stmia	fre!, {rva, \obj1}
	stmia	fre!, {\obj2, env}
	sub	\dest, fre, #12		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, fre, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .else
	memsetlnk				@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrck	16				@ reserve memory, sufficient space available?
	bls	algc16				@	if not,  jump to perform gc
	bic	rva, fre, #0x03		@ rva <- address of allocated memory
	stmia	rva!, {\tag}
	stmia	rva!, {\obj1, \obj2, env}
	sub	\dest, rva, #12		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .endif
.endm

.macro tagwnul dest, tag, obj1, obj2
	@ dest <- [tag obj1 obj2 ()]
  .ifdef enable_MPU
	bic	fre, fre, #0x03		@ rva <- address of allocated memory
  	set	rva, \tag		@ rva <- tag
	stmia	fre!, {rva, \obj1}
	set	rvc, #null
	stmia	fre!, {\obj2, rvc}
	sub	\dest, fre, #12		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, fre, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .else
	memsetlnk				@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrck	16				@ reserve memory, sufficient space available?
	bls	algc16				@	if not,  jump to perform gc
	bic	rva, fre, #0x03		@ rva <- address of allocated memory
	stmia	rva!, {\tag}
	set	rvc, #null
	stmia	rva!, {\obj1, \obj2, rvc}
	sub	\dest, rva, #12		@ \dest <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .endif
.endm


.macro sav__c
	@ dts <- (cnt . dts)
  .ifdef enable_MPU
	bic	fre, fre, #0x03		@ rva <- address of allocated memory
	stmia	fre!, {cnt, dts}
	sub	dts, fre, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, fre, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .else
    .ifdef inline_cons
	memsetlnk			@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrchk8			@ reserve memory, sufficient space available?
	bls	alogc8			@	if not,  jump to perform gc
	bic	rva, fre, #0x03		@ rva <- address of allocated memory
	stmia	rva!, {cnt, dts}
	sub	dts, rva, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .else
	bl	sav__c
    .endif
  .endif
.endm

.macro isav_ec
	@ inlined version of sav_ec (below)
	@ dts <- (env cnt . dts)
  .ifdef enable_MPU
	bic	fre, fre, #0x03		@ rva <- address of allocated memory
	set	rvc, fre
	stmia	fre!, {cnt, dts}
	stmia	fre!, {env, rvc}
	sub	dts, fre, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, fre, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .else
	memsetlnk			@ lnk <- memory transaction return address, (adjustd for T2 mode)
	memfrck	16			@ fre <- ...bbb01 (level 1 reserved) and set ls flags if gc is needed
	bls	algc16			@	if not,  jump to perform gc
	bic	rva, fre, #0x03		@ rva <- address of allocated memory
	set	rvc, rva
	set	rvb, dts
	stmia	rva!, {cnt, rvb, env, rvc}
	sub	dts, rva, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .endif
.endm

.macro sav_ec
	@ dts <- (env cnt . dts)
  .ifdef enable_MPU
	isav_ec
  .else
    .ifdef inline_cons
	isav_ec
    .else
	bl	sav_ec
    .endif
  .endif
.endm

.macro sav_rc reg
	@ dts <- (reg cnt . dts)
  .ifdef enable_MPU
	bic	fre, fre, #0x03		@ rva <- address of allocated memory
	set	rvc, fre
	stmia	fre!, {cnt, dts}
	stmia	fre!, {\reg, rvc}
	sub	dts, fre, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, fre, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .else
    .ifdef inline_cons
	memsetlnk			@ lnk <- memory transaction return address, (adjustd for T2 mode)
	memfrck	16			@ fre <- ...bbb01 (level 1 reserved) and set ls flags if gc is needed
	bls	algc16			@	if not,  jump to perform gc
	bic	rva, fre, #0x03		@ rva <- address of allocated memory
	set	rvc, rva
	stmia	rva!, {cnt, dts}
	stmia	rva!, {\reg, rvc}
	sub	dts, rva, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .else
	bl	sav_rc
	setcar	dts, \reg
    .endif
  .endif
.endm

.macro savrec reg
	@ dts <- (reg env cnt . dts)
  .ifdef enable_MPU
	bic	fre, fre, #0x03		@ rva <- address of allocated memory
	set	rvc, fre
	stmia	fre!, {cnt, dts}
	stmia	fre!, {env, rvc}
	sub	rvc, fre, #8
	stmia	fre!, {\reg, rvc}
	sub	dts, fre, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, fre, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .else
    .ifdef inline_cons
	memsetlnk			@ lnk <- memory transaction return address, (adjustd for T2 mode)
	memfrck	24			@ fre <- ...bbb01 (level 1 reserved) and set ls flags if gc is needed
	bls	algc24			@	if not,  jump to perform gc
	bic	rva, fre, #0x03		@ rva <- address of allocated memory
	set	rvc, rva
	set	rvb, dts
	stmia	rva!, {cnt, rvb, env, rvc}
	sub	rvc, rva, #8
	stmia	rva!, {\reg, rvc}
	sub	dts, rva, #8		@ dts <- address of cons cell, [*commit cons destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
    .else
	bl	savrec
	setcar	dts, \reg
    .endif
  .endif
.endm

.macro vctrcr4 dest, reg1, reg2, reg3, reg4
	@ dest <- #(cnt reg1 reg2 reg3 reg4)
  .ifdef enable_MPU
	bic	fre, fre, #0x03		@ fre <- ...bbb00			(reservation level 2)
	set	rva, #vector_tag
	orr	rva, rva, #0x500
	set	rvb, cnt
	stmia	fre!, {rva,rvb,\reg1,\reg2,\reg3,\reg4}	@ rva <- address of next free cell, and store reg, dts in free cell
	sub	\dest, fre, #20		@ dts <- address of save cell, [*commit save destination*]
	orr	fre, fre, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
  .else
	memsetlnk			@ lnk <- memory transaction return address, (adjustd for T2 mode)
	memfrck	24			@ fre <- ...bbb01 (level 1 reserved) and set ls flags if gc is needed
	bls	algc24			@	if not,  jump to perform gc
	bic	rva, fre, #0x03		@ rva <- free cell address
	set	rvc, #vector_tag
	orr	rvc, rvc, #0x500
	stmia	rva!, {rvc}
	stmia	rva!, {cnt,\reg1,\reg2,\reg3,\reg4}	@ rva <- address of next free cell, and store reg, dts in free cell
	sub	\dest, rva, #20		@ dts <- address of save cell, [*commit save destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]

  .endif
.endm


.macro car dest, pair
	ldr	\dest,  [\pair]
.endm

.macro careq dest, pair
	ldreq	\dest,  [\pair]
.endm

.macro carne dest, pair
	ldrne	\dest,  [\pair]
.endm

.macro carmi dest, pair
	ldrmi	\dest,  [\pair]
.endm

.macro carpl dest, pair
	ldrpl	\dest,  [\pair]
.endm

.macro cdr dest, pair
	ldr	\dest,  [\pair, #4]
.endm

.macro cdreq dest, pair
	ldreq	\dest,  [\pair, #4]
.endm

.macro cdrne dest, pair
	ldrne	\dest,  [\pair, #4]
.endm

.macro cdrmi dest, pair
	ldrmi	\dest,  [\pair, #4]
.endm

.macro cdrhi dest, pair
	ldrhi	\dest,  [\pair, #4]
.endm

.macro cdrpl dest, pair
	ldrpl	\dest,  [\pair, #4]
.endm

.macro setcar pair, obj
	str	\obj,  [\pair]
.endm

.macro setcareq pair, obj
	streq	\obj,  [\pair]
.endm

.macro setcarne pair, obj
	strne	\obj,  [\pair]
.endm

.macro setcarmi pair, obj
	strmi	\obj,  [\pair]
.endm

.macro setcdr pair, obj
	str	\obj,  [\pair, #4]
.endm

.macro setcdreq pair, obj
	streq	\obj,  [\pair, #4]
.endm

.macro setcdrne pair, obj
	strne	\obj,  [\pair, #4]
.endm

.macro setcdrhi pair, obj
	strhi	\obj,  [\pair, #4]
.endm

.macro setcdrpl pair, obj
	strpl	\obj,  [\pair, #4]
.endm

.macro caar dest, pair
	car	\dest,  \pair
	car	\dest,  \dest
.endm

.macro caareq dest, pair
	careq	\dest,  \pair
	careq	\dest,  \dest
.endm

.macro caarne dest, pair
	carne	\dest,  \pair
	carne	\dest,  \dest
.endm

.macro cadr dest, pair
	cdr	\dest,  \pair
	car	\dest,  \dest
.endm

.macro cadrne dest, pair
	cdrne	\dest,  \pair
	it	ne
	carne	\dest,  \dest
.endm

.macro cdar dest, pair
	car	\dest,  \pair
	cdr	\dest,  \dest
.endm

.macro cdarne dest, pair
	carne	\dest,  \pair
	it	ne
	cdrne	\dest,  \dest
.endm

.macro cdarpl dest, pair
	carpl	\dest,  \pair
	cdrpl	\dest,  \dest
.endm

.macro cddr dest, pair
	cdr	\dest,  \pair
	cdr	\dest,  \dest
.endm

.macro caaar dest, pair
	car	\dest,  \pair
	car	\dest,  \dest
	car	\dest,  \dest
.endm

.macro cadar dest, pair
	car	\dest,  \pair
	cdr	\dest,  \dest
	car	\dest,  \dest
.endm

.macro cadarne dest, pair
	carne	\dest,  \pair
	itT	ne
	cdrne	\dest,  \dest
	carne	\dest,  \dest
.endm

.macro caddr dest, pair
	cdr	\dest,  \pair
	cdr	\dest,  \dest
	car	\dest,  \dest
.endm

.macro caddrne dest, pair
	cdrne	\dest,  \pair
	itT	ne
	cdrne	\dest,  \dest
	carne	\dest,  \dest
.endm

.macro cdaar dest, pair
	car	\dest,  \pair
	car	\dest,  \dest
	cdr	\dest,  \dest
.endm

.macro cdddr dest, pair
	cdr	\dest,  \pair
	cdr	\dest,  \dest
	cdr	\dest,  \dest
.endm

/*------------------------------------------------------------------------------
	6.3.5. Strings
------------------------------------------------------------------------------*/

.macro straloc dest, size
	@ dest <- (make-string size)
	@ dest and size must be different registers and not rva, rvb
	int2raw	rvb, \size		@ rvb <- #bytes to allocate for data
	@ allocate the aligned object
	bl	zmaloc			@ rva <- addr of object (symbol-taggd), fre <- addr (rsrvd level 1)
	add	rva, rva, rvb		@ rva <- address of next free cell
	sub	\dest, rva, rvb		@ \dest <- address of string (symbl), [*commit string destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	@ update the object's tag for actual size and type (string)
	lsl	rva, \size, #6
	orr	rva, rva, #string_tag
	str	rva, [\dest, #-4]	@ update string tag
.endm

.macro strlen dest, string
	ldr	rvb, [\string, #-4]
	lsr	\dest, rvb, #6
.endm

.macro strref char, string, position
	@ modifies:	rva
  .ifndef	cortex
	ldrb	rva, [\string,  \position, ASR #2]
  .else
	asr	rva, \position, #2
	ldrb	rva, [\string, rva]
  .endif
	lsl	rva, rva, #8
	orr	\char, rva, #char_tag
.endm


.macro strset string, position, char
	@ modifies:	rva, rvc (rvc on cortex only)
	chr2raw	rva, \char
  .ifndef cortex
	strb	rva, [\string, \position, ASR #2]
  .else
	asr	rvc, \position, #2
	strb	rva, [\string, rvc]
  .endif
.endm

/*------------------------------------------------------------------------------
	6.3.6. Vectors
------------------------------------------------------------------------------*/

.macro veclen dest, vector
	ldr	rvb, [\vector, #-4]
	lsr	\dest, rvb, #6
.endm

.macro vecleneq dest, vector
	ldreq	rvb, [\vector, #-4]
	it	eq
	lsreq	\dest, rvb, #6
.endm

.macro veclenne dest, vector
	ldrne	rvb, [\vector, #-4]
	it	ne
	lsrne	\dest, rvb, #6
.endm

.macro	vecref res, vec, pos
	@ output:	res (reg) <- item from vector
	@ input:	vec (reg) <- vector 	(scheme vector)
	@ input:	pos (reg) <- position 	(scheme int)
	@ modifies:	rva
	bic	rva, \pos, #0x03
	ldr	\res, [\vec, rva]
.endm
	
.macro	vecset vec, pos, val
	@ input:	vec (reg) <- vector 	(scheme vector)
	@ input:	pos (reg) <- position 	(scheme int)
	@ input:	val (reg) <- item to store in vector
	@ modifies rva
	bic	rva, \pos, #0x03
	str	\val, [\vec, rva]
.endm
	
.macro vcrfi dest, vector, position
	ldr	\dest,  [\vector,  #4*\position]
.endm

.macro vcrfieq dest, vector, position
	ldreq	\dest,  [\vector,  #4*\position]
.endm

.macro vcrfine dest, vector, position
	ldrne	\dest,  [\vector,  #4*\position]
.endm

.macro vcrfimi dest, vector, position
	ldrmi	\dest,  [\vector,  #4*\position]
.endm

.macro vcrfipl dest, vector, position
	ldrpl	\dest,  [\vector,  #4*\position]
.endm

.macro vcrfihi dest, vector, position
	ldrhi	\dest,  [\vector,  #4*\position]
.endm

.macro vcsti vector, position, obj
	str	\obj,  [\vector,  #4*\position]
.endm

.macro vcstieq vector, position, obj
	streq	\obj,  [\vector,  #4*\position]
.endm

.macro vcstine vector, position, obj
	strne	\obj,  [\vector,  #4*\position]
.endm

.macro vcstipl vector, position, obj
	strpl	\obj,  [\vector,  #4*\position]
.endm

.macro vcstihi vector, position, obj
	strhi	\obj,  [\vector,  #4*\position]
.endm

.macro vcstimi vector, position, obj
	strmi	\obj,  [\vector,  #4*\position]
.endm

/*------------------------------------------------------------------------------
	bytevectors
------------------------------------------------------------------------------*/

.macro	mkvu841 upd, dest
	@ dest <- #vu8(space-for-4-items)
	bic	\upd, fre, #0x03	@ upd <- reserve memory
	set	rvc, #0x0400
	orr	rvc, rvc, #bytevector_tag
	stmia	\upd!, {rvc, lnk}	@ fre <- addr of next free cell
	sub	\dest, \upd, #4		@ \dest <- address of cons cell, [*commit destination*]
	orr	fre, \upd, #0x02	@ de-reserve memory, [*restart critical instruction*]
.endm

.macro	mkvu84 dest
	@ dest <- #vu8(space-for-4-items)
  .ifdef enable_MPU
  	mkvu841	fre, \dest		@ reserve, store, commit and de-reserve
  .else
	memsetlnk			@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrchk8			@ reserve memory, sufficient space available?
	bls	alogc8			@	if not,  jump to perform gc
  	mkvu841	rva, \dest		@ store, commit and de-reserve
  .endif
.endm


.macro vu8aloc dest, size
	@
	@ dest <- (make-bytevector size)
	@
	@ dest and size must be different registers and not rva, rvb
	@
	@ align the number of bytes to allocate
	int2raw	rvb, \size		@ rvb <- #bytes to allocate for data
	@ allocate the aligned object
	bl	zmaloc			@ rva <- addr of object (symbol-taggd), fre <- addr (rsrvd level 1)
	add	rva, rva, rvb		@ rva <- address of next free cell
	sub	\dest, rva, rvb		@ \dest <- address of string (symbl), [*commit string destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	@ update the object's tag for actual size and type (bytevector)
	lsl	rva, \size, #6
	orr	rva, rva, #bytevector_tag
	str	rva, [\dest, #-4]	@ update tag
.endm

.macro vu8len dest, vu8
	@ on entry:	vu8  (reg) <- bytevector
	@ on exit:	dest (reg) <- bytevector length (scheme int)
	@ modifies:	rvb
	ldr	rvb, [\vu8, #-4]
	lsr	\dest, rvb, #6
.endm

.macro vu8ref octet, vu8, position
	@ on entry:	vu8      (reg) <- bytevector
	@ on entry:	position (reg) <- index (scheme int)
	@ on exit:	octet    (reg) <- item from bytevector (scheme int)
	@ modifies:	rva
.ifndef	cortex
	ldrb	rva, [\vu8,  \position, ASR #2]
.else
	asr	rva, \position, #2
	ldrb	rva, [\vu8, rva]
.endif
	lsl	rva, rva, #2
	orr	\octet, rva, #i0
.endm

.macro vu8set vu8, position, octet
	@ on entry:	vu8      (reg) <- bytevector
	@ on entry:	position (reg) <- index (scheme int)
	@ on entry:	octet    (reg) <- item to store in bytevector (scheme int)
	@ modifies rva, rvc
	int2raw	rva, \octet
  .ifndef cortex
	strb	rva, [\vu8, \position, ASR #2]
  .else
	int2raw	rvc, \position
	strb	rva, [\vu8, rvc]
  .endif
.endm

/*------------------------------------------------------------------------------
	word (table) and byte references
------------------------------------------------------------------------------*/

.macro tbrfi reg, table, position
	ldr	\reg,  [\table,  #4*\position]	
.endm

.macro tbrfieq reg, table, position
	ldreq	\reg,  [\table,  #4*\position]	
.endm

.macro tbrfine reg, table, position
	ldrne	\reg,  [\table,  #4*\position]	
.endm

.macro tbrfimi reg, table, position
	ldrmi	\reg,  [\table,  #4*\position]	
.endm

.macro tbsti reg, table, position
	str	\reg,  [\table,  #4*\position]	
.endm

.macro tbstieq reg, table, position
	streq	\reg,  [\table,  #4*\position]	
.endm

.macro tbstine reg, table, position
	strne	\reg,  [\table,  #4*\position]	
.endm

.macro bytref reg, array, position	@ the 3 registers should be different
.ifndef	cortex
	ldrb	\reg,  [\array,  \position, ASR #2 ]
.else
	asr	\reg, \position, #2
	ldrb	\reg,  [\array, \reg]
.endif
.endm

.macro bytrefeq reg, array, position	@ the 3 registers should be different
.ifndef	cortex
	ldrbeq	\reg,  [\array,  \position, ASR #2 ]
.else
	asreq	\reg, \position, #2
	it	eq
	ldrbeq	\reg,  [\array, \reg]
.endif
.endm

.macro bytrefne reg, array, position	@ the 3 registers should be different
.ifndef	cortex
	ldrbne	\reg,  [\array,  \position, ASR #2 ]
.else
	asrne	\reg, \position, #2
	it	ne
	ldrbne	\reg,  [\array, \reg]
.endif
.endm

.macro bytrefmi reg, array, position	@ the 3 registers should be different
.ifndef	cortex
	ldrbmi	\reg,  [\array,  \position, ASR #2 ]
.else
	asrmi	\reg, \position, #2
	it	mi
	ldrbmi	\reg,  [\array, \reg]
.endif
.endm

.macro bytset array, position, reg	@ the 3 registers should be different
	@ modifies rvc on cortex-m3
  .ifndef cortex
	strb	\reg,  [\array,  \position, ASR #2 ]
  .else
	asr	rvc, \position, #2
	strb	\reg, [\array, rvc]
  .endif
.endm

.macro bytseteq array, position, reg	@ the 3 registers should be different
	@ modifies rvc on cortex-m3
  .ifndef cortex
	strbeq	\reg,  [\array,  \position, ASR #2 ]
  .else
	asreq	rvc, \position, #2
	it	eq
	strbeq	\reg, [\array, rvc]
  .endif
.endm

.macro bytsetne array, position, reg	@ the 3 registers should be different
	@ modifies rvc on cortex-m3
  .ifndef cortex
	strbne	\reg,  [\array,  \position, ASR #2 ]
  .else
	asrne	rvc, \position, #2
	it	ne
	strbne	\reg, [\array, rvc]
  .endif
.endm

.macro bytsetmi array, position, reg	@ the 3 registers should be different
	@ modifies rvc on cortex-m3
  .ifndef cortex
	strbmi	\reg,  [\array,  \position, ASR #2 ]
  .else
	asrmi	rvc, \position, #2
	it	mi
	strbmi	\reg, [\array, rvc]
  .endif
.endm

.macro bytsetu array, position, reg	@ the 3 registers should be different
	@ used only within irq-disabled code zones
	@ or if position is in rva-rvc
	@ (does not disable/enable interrupts on cortex)
.ifndef	cortex
	strb	\reg,  [\array,  \position, ASR #2 ]
.else
	asr	\position, \position, #2	@ - not gc safe !!!! (needs no irq or pos in rva-rvc)
	strb	\reg,  [\array, \position]	@ - not gc safe !!!! (needs no irq or pos in rva-rvc)
	lsl	\position, \position, #2	@ - not gc safe !!!! (needs no irq or pos in rva-rvc)
	orr	\position, \position, #int_tag	@ - not gc safe !!!! (needs no irq or pos in rva-rvc)
.endif
.endm

.macro wrdref reg, array, position	
	@ the 3 registers should be different
	@ reg (first reg) should be rva-rvc (raw value obtained)
  .ifndef cortex
	ldr	\reg,  [\array,  \position, ASR #2 ]
  .else
	asr	\reg, \position, #2	@ reg could be not gc safe here (if not rva or rvb)
	ldr	\reg,  [\array, \reg]
  .endif
.endm

.macro wrdst array, position, reg
	@ array and position should be different registers,
	@ array should not be rvc
	@ modifies rvc on cortex-m3
  .ifndef cortex
	str	\reg,  [\array,  \position, ASR #2 ]
  .else
	asr	rvc, \position, #2
	str	\reg,  [\array, rvc]
  .endif
.endm


/*------------------------------------------------------------------------------
	Addendum: Pair splitting
------------------------------------------------------------------------------*/

.macro snoc car, cdr, pair
	ldmia	\pair, {\car, \cdr}
.endm

.macro snoceq car, cdr, pair
	ldmiaeq	\pair, {\car, \cdr}
.endm

.macro snocne car, cdr, pair
	ldmiane	\pair, {\car, \cdr}
.endm

.macro snocpl car, cdr, pair
	ldmiapl	\pair, {\car, \cdr}
.endm

/*------------------------------------------------------------------------------
	Addendum: Type analysis
------------------------------------------------------------------------------*/

.macro fl2cp1 upd, cpx, real, imag
	@ modifies:	sv3, fre, rva, rvb, rvc
	bic	\upd, fre, #0x03	@ fre <- reserve memory
	bic	rvc, \imag, #3
	orr	rvc, rvc, \real, lsr #30
	bic	rvb, \real, #3
	lsl	rvb, rvb, #2
	orr	rvb, rvb, #complex_tag
	stmia	\upd!, {rvb, rvc}
	sub	\cpx, \upd, #4		@ cpx <- address of rational, [*commit destination*]
	orr	fre, \upd, #0x02	@ de-reserve free-pointer, [*restart critical instruction*]
.endm

.macro flt2cpx cpx, real, imag
	@ modifies:	sv3, fre, rva, rvb, rvc
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
  .ifdef enable_MPU
  	fl2cp1	fre, \cpx, \real, \imag	@ reserve, store, commit and de-reserve
  .else
	memsetlnk			@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrchk8			@ reserve memory, sufficient space available?
	bls	alogc8			@	if not,  jump to perform gc
  	fl2cp1	rva, \cpx, \real, \imag	@ store, commit and de-reserve
  .endif
	orr	lnk, sv3, #lnkbit0
.endm

.macro in2ra1 upd, rat, num, den
	@ modifies:	fre, rva, rvb, rvc
	bic	\upd, fre, #0x03	@ fre <- reserve memory
	bic	rvc, \den, #3
	orr	rvc, rvc, \num, lsr #30
	bic	rvb, \num, #3
	lsl	rvb, rvb, #2
	orr	rvb, rvb, #rational_tag
	stmia	\upd!, {rvb, rvc}
	sub	\rat, \upd, #4		@ rat <- address of rational, [*commit destination*]
	orr	fre, \upd, #0x02	@ de-reserve free-pointer, [*restart critical instruction*]
.endm

.macro int2rat rat, num, den
	@ modifies:	fre, rva, rvb, rvc
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
  .ifdef enable_MPU
  	in2ra1	fre, \rat, \num, \den	@ reserve, store, commit and de-reserve
  .else
	memsetlnk			@ lnk <- memory transaction return address (adjustd for T2 mode)
	memfrchk8			@ reserve memory, sufficient space available?
	bls	alogc8			@	if not,  jump to perform gc
  	in2ra1	rva, \rat, \num, \den	@ store, commit and de-reserve
  .endif
	orr	lnk, sv3, #lnkbit0
.endm

.macro charp reg
	and	rva, \reg, #0xFF
	eq	rva, #char_tag
.endm

.macro ratcpx reg
	@ raise eq flag if reg contains a rational or complex
	@ uses rva
	and	rva, \reg, #0x07
	eq	rva, #0x04
	itTT	eq
	ldreq	rva, [\reg, #-4]
	andeq	rva, rva, #0x07		@ rva <- two-bit tag of object in num
	eqeq	rva, #0x03		@ is object a rational or complex?
.endm

.macro nmbrp reg
	@ raise eq flag if reg contains a rational, complex, int or float
	@ uses rva
	ratcpx	\reg			@ is object in reg a rat/cpx?
	itT	ne
	andne	rva, \reg,  #0x03	@ 	if not, rva <- two-bit tag of object in reg
	eqne	rva, #int_tag		@ 	if not, is object an integer?
	it	ne
	eqne	rva, #float_tag		@	if not, is object a float?
.endm

.macro varp reg
	@ raise eq flag if reg contains a variable or syntax item
	@ uses rva
	and	rva, \reg, #0xFF
	eq	rva, #variable_tag
.endm

.macro tagdp reg
	@ raise eq flag if reg points to a tagged item (string, vector, procedure, continuation, ...)
	@ uses rva
	and	rva, \reg, #0x07
	eq	rva, #0x04
	itTT	eq
	ldreq	rva, [\reg, #-4]
	andeq	rva, rva, #0x47
	eqeq	rva, #0x47
.endm

.macro sizdp reg
	@ raise eq flag if reg points to a tagged-sized item (string, symbol, vector, ...)
	@ uses rva
	and	rva, \reg, #0x07
	eq	rva, #0x04
	itTT	eq
	ldreq	rva, [\reg, #-4]
	andeq	rva, rva, #0xCF
	eqeq	rva, #0x4F
.endm

.macro vctrp reg
	@ raise eq flag if reg points to a vector
	@ uses rva
	and	rva, \reg, #0x07
	eq	rva, #0x04
	itT	eq
	ldrbeq	rva, [\reg, #-4]
	eqeq	rva, #vector_tag
.endm

.macro pntrp reg
	@ raise eq flag if reg contains a pointer
	tst	\reg,  #0x03
.endm

.macro pntrpeq reg
	tsteq	\reg,  #0x03
.endm

.macro pntrpne reg
	tstne	\reg,  #0x03
.endm

.macro macrop reg
	@ modifies:	rva
	and	rva, \reg, #0x07
	eq	rva, #0x04
	itTT	eq
	ldreq	rva, [\reg, #-4]
	eoreq	rva, rva, #0x0800	@ is tag in reg a macro tag?
	eqeq	rva, #proc
.endm

.macro execp reg
	@ raises eq flag if \reg is normal prim, proc or cont (not direct prim)
	@ modifies:	rva
	and	rva, \reg, #0x07
	eq	rva, #0x04
	itE	eq
	ldreq	rva, [\reg, #-4]
	setne	rva, \reg
	tst	rva, #0x0800
	itT	eq
	andeq	rva, rva, #0xf7
	eqeq	rva, #0xd7
.endm

.macro pairp reg
	tst	\reg, #0x07
.endm

.macro pairpeq reg
	tsteq	\reg, #0x07
.endm

.macro pairpne reg
	tstne	\reg, #0x07
.endm

.macro tuckd datast, reg, datast2
	restor	sv2			@ sv2 <- item-at-top-of-stack, dts <- (...)
	save2	sv2, sv1		@ dts <- (item-at-top-of-stack new-item ...)
.endm

.macro tuck reg, tmp
	@ on entry:	dts <- (item1 item2 ...)
	@ on exit:	dts <- (item1 reg item2 ...)
	@ on exit:	tmp <- item1
	restor	\tmp			@ tmp <- item1, dts <- (item2 ...)
	save2	\tmp, \reg		@ dts <- (item1 reg item2 ...)
.endm

/*------------------------------------------------------------------------------
	EVAL
------------------------------------------------------------------------------*/

.macro	evalsv1
	varp	sv1				@ is object a variable?
	it	eq
	bleq	sbevlv				@	if so,  sv1 <- value of var, rva <- non-pair
	pairp	rva				@ is object in sv1 (with 8-bit tag in rva) a pair?
	it	eq
	bleq	sbevll				@	if so,  sv1 <- value of list in sv1
.endm

/*------------------------------------------------------------------------------
	Addendum: Calling and branching to scheme functions or labels
------------------------------------------------------------------------------*/

.macro	call label
.ifndef	cortex
	set	cnt, pc			@ cnt <- instruction after next
	b	\label
.else
	add	cnt, pc, #4		@ cnt <- instruction after next (16-bit instruction)
	b	\label			@ (16 or 32-bit instruction)
	nop				@ <- cnt points here, or at next instruction for 32-bit branch
	nop				@ <- cnt points here, or at next instruction for 16-bit branch
.endif	
.endm

.macro	calla reg
.ifndef	cortex
	set	cnt, pc			@ cnt <- instruction after next
	set	pc,  \reg
.else
	add	cnt, pc, #4		@ cnt <- instruction after next (16-bit instruction)
	set	pc,  \reg		@ (16-bit instruction) (note: *add cnt, pc, #2* is 32 bit)
	nop
	nop				@ <- cnt points here, or at next instruction
.endif	
.endm

.macro	nullp reg
	eq	\reg, #null
.endm

.macro	nullpeq reg
	eqeq	\reg, #null
.endm

.macro	nullpne reg
	eqne	\reg, #null
.endm

.macro	izerop reg
	eq	\reg, #i0
.endm

.macro	int2raw raw, int
	asr	\raw, \int, #2
.endm

.macro	int2raweq raw, int
	asreq	\raw, \int, #2
.endm

.macro	int2rawne raw, int
	asrne	\raw, \int, #2
.endm

.macro	int2rawmi raw, int
	asrmi	\raw, \int, #2
.endm

.macro	raw2int int, raw  @ <- target (int) and source (raw) must be different regs
	set	\int, #int_tag
	orr	\int, \int, \raw, LSL #2
.endm
	
.macro	raw2inteq int, raw
	seteq	\int, #int_tag
	orreq	\int, \int, \raw, LSL #2
.endm
	
.macro	raw2intne int, raw
	setne	\int, #int_tag
	orrne	\int, \int, \raw, LSL #2
.endm
	
.macro	raw2intmi int, raw
	setmi	\int, #int_tag
	it	mi
	orrmi	\int, \int, \raw, LSL #2
.endm
	
.macro	chr2raw raw, chr
	lsr	\raw, \chr, #8
.endm

.macro	raw2chr chr, raw
	set	\chr, #char_tag
	orr	\chr, \chr, \raw, LSL #8
.endm
	
.macro	raw2chreq chr, raw
	seteq	\chr, #char_tag
	it	eq
	orreq	\chr, \chr, \raw, LSL #8
.endm

/*------------------------------------------------------------------------------
	swap macros
------------------------------------------------------------------------------*/

.macro swap reg1, reg2, temp
	set	\temp,  \reg1
	set	\reg1,  \reg2
	set	\reg2,  \temp
.endm

.macro swapmi reg1, reg2, temp
	setmi	\temp,  \reg1
	itT	mi
	setmi	\reg1,  \reg2
	setmi	\reg2,  \temp
.endm


	


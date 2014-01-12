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

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.2.	Numbers
@	6.2.5	Numerical operations:	number?, complex?, real?, rational?,
@					integer?,
@					exact?, inexact?
@					=, <, >, <=, >=, +, *, -, /,
@					quotient, remainder, modulo,
@					numerator, denominator
@					floor, ceiling, truncate, round,
@					exact->inexact, inexact->exact
@					zero?, positive?, negative?, odd?,
@					even?, max, min, abs, 
@					gcd, lcm, rationalize
@	6.2.6	Numerical input output:	number->string, string->number
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	Requires:
@			core:		flsfxt, trufxt, boolxt, corerr, notfxt
@					save, save3, cons, sav_rc, zmaloc
@
@	Modified by (switches):		CORE_ONLY, cortex
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


.ifdef	hardware_FPU
_func_
intflq:	@ integer? for float
	bic	rva, sv1, #0x80000000	@ rva <- number, without sign
	cmp	rva, #0x4a000000	@ does number have exponent >= 148 (no fractional part)?
	bpl	trufxt			@	if so,  exit with #t
	bic	rva, sv1, #0x03
  .ifndef FPU_is_maverick
	vmov	s0, rva
	vcvt.s32.f32	s0, s0
	vcvt.f32.s32	s0, s0
	vmov	rvb, s0
  .else
	cfmvsr	mvf0, rva
	cfcvts32 mvfx0, mvf0
	cfcvt32s mvf0, mvfx0
	cfmvrs	rvb, mvf0
  .endif
	eq	rva, rvb		@ are numbers equal?
	b	boolxt			@ return with #t/#f based on test result
.else
_func_
intflq:	@ integer? for float
	bic	rva, sv1, #0x80000000	@ rva <- number, without sign
	cmp	rva, #0x4a000000	@ does number have exponent >= 148 (no fractional part)?
	bpl	trufxt			@	if so,  exit with #t
	set	sv4, sv1
	bl	fltmte			@ sv1 <- mantissa,  rva <- exponent
	rsb	rvb, rva, #148		@ rvb <- right shift needed to get integer part of number (raw int)
	int2raw	rva, sv1		@ rva <- mantissa (raw)
	bl	iround
	raw2int	sv1, rva
	bl	i12flt
	eq	sv1, sv4		@ are numbers equal?
	b	boolxt			@ return with #t/#f based on test result
.endif


_func_
eqnint:	@ = for int
_func_
eqnflt:	@ = for flt
	eq	sv1, sv2
	it	ne
	setne	sv1, #f			@	if not, sv1 <- #f
	set	pc,  lnk		@ return with #f or value in sv1
	
_func_
eqnrat:	@ = for rat
_func_
eqncpx:	@ = for cpx
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	bl	eqrtcx
	orr	lnk, sv3, #lnkbit0
	it	ne
	setne	sv1, #f			@	if not, sv1 <- #f
	set	pc,  lnk		@ return with #f or value in sv1

_func_
eqrtcx:	@ raise eq flag on equality of rat/cpx
	@ modifies:	rva-rvc
	rawsplt	rva, rvc, sv1		@ rva <- word 1, rvc <- word 2 of x1, possible rat/cpx
	ldr	rvb, [sv2, #-4]		@ rvb <- word 1 of x2, possible rat/cpx
	eq	rva, rvb		@ are word 1 of x1 and x2 the same?
	itT	eq
	ldreq	rvb, [sv2]		@	if so,  rvb <- word 2 of x2
	eqeq	rvc, rvb		@	if so,  are word 2 of x1 and x2 the same?
	set	pc,  lnk		@ return with flag


_func_
ltflt:	@ < for flt
	anynan	sv1, sv2
	beq	cmpfls			@	if so,  exit reduction with #f
	postv	sv1			@ is x1 positive?
	it	ne
	postvne	sv2			@	if so,  is x2 negative?
	bne	gtint			@	if so,  jump to test for that
	postv	sv1			@ is x1 positive or 0?
	bne	cmptru			@	if not, exit with num2
	postv	sv2			@ is x2 positive or 0?
	bne	cmpfls			@	if not, exit with #f
	@ continue to ltint
_func_
ltint:	@ < for int (or positive floats)
	cmp	sv1, sv2		@ is x1 < x2 ?
	bmi	cmptru			@	if so,  jump to exit with x2
cmpfls:	set	sv1, #f			@ sv1 <- #f
	set	pc,  lnk		@ exit reduction with #f

_func_
ltrat:	@ < for rat
	bic	sv3, lnk, #lnkbit0	@ rvc <- lnk, saved (and made even if Thumb2)
	bl	eqrtcx
	orr	lnk, sv3, #lnkbit0
	beq	cmpfls
	save2	sv2, sv3
ltgtxt:	@ < > for rat (common exit)
	bl	mnsrat
	restor2	sv2, sv3
	pntrp	sv1
	itTE	eq
	ldreq	rva, [sv1]
	lsleq	rva, rva, #30
	setne	rva, sv1
	postv	rva
	itE	eq
	seteq	sv1, #f
	setne	sv1, sv2
	orr	lnk, sv3, #lnkbit0
	set	pc,  lnk


_func_
gtflt:	@ > for flt
	anynan	sv1, sv2		@ is either x1 or x2 nan?
	beq	cmpfls			@	if so,  exit reduction with #f
	postv	sv1			@ is x1 positive?
	it	ne
	postvne	sv2			@	if not, is x2 positive?
	bne	ltint			@	if not, jump to test for that
	postv	sv2			@ is x2 positive or 0?
	bne	cmptru			@	if not, exit with num2
	postv	sv1			@ is x1 positive or 0?
	bne	cmpfls			@	if not, exit with #f
	@ continue to gtint
_func_
gtint:	@ > for int
	cmp	sv2, sv1		@ is x1 >= x2 ?
	bpl	cmpfls			@	if not, jump to exit with #f
cmptru:	set	sv1, sv2		@ sv1 <- x2 (latest number)
	set	pc,  lnk		@ exit with num2

_func_
gtrat:	@ > for rat	
	bic	sv3, lnk, #lnkbit0	@ rvc <- lnk, saved (and made even if Thumb2)
	bl	eqrtcx
	orr	lnk, sv3, #lnkbit0
	beq	cmpfls
	save2	sv2, sv3
	swap	sv1, sv2, sv3
	b	ltgtxt


_func_
leint:	@ <= for int
	eq	sv1, sv2
	bne	ltint
	set	pc,  lnk
			
_func_
leflt:	@ <= for flt
	eq	sv1, sv2
	bne	ltflt
	set	pc,  lnk

_func_
lerat:	@ <= for rat
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	bl	eqrtcx
	orr	lnk, sv3, #lnkbit0
	bne	ltrat
	set	pc, lnk


_func_
geint:	@ >= for int
	eq	sv1, sv2
	bne	gtint
	set	pc,  lnk
			
_func_
geflt:	@ >= for flt
	eq	sv1, sv2
	bne	gtflt
	set	pc,  lnk

_func_
gerat:	@ >= for rat
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	bl	eqrtcx
	orr	lnk, sv3, #lnkbit0
	bne	gtrat
	set	pc, lnk


_func_
plsint:	@ + for int
	int2raw	rva, sv1		@ rva <- x1 (raw int)
	int2raw	rvb, sv2		@ rva <- x2 (raw int)
	add	rvc, rva, rvb
	raw2int	sv1, rvc
	ands	rva, rvc, #0xE0000000
	it	ne
	eqne	rva, #0xE0000000
	it	eq
	seteq	pc,  lnk
.ifdef	hardware_FPU
  .ifndef FPU_is_maverick
	vmov	s0,  rvc
	vcvt.f32.s32	s0, s0
	vmov	rva, s0
  .else
	cfmv64lr mvdx0, rvc
	cfcvt32s mvf0, mvfx0
	cfmvrs	rva, mvf0
  .endif
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  lnk
.else
	bic	rvc, rvc, #3
	orr	sv1, rvc, #int_tag
	set	rva, #150
	b	mteflt
.endif

.ifdef	hardware_FPU

_func_
plsflt:	@ + for float
	bic	rva, sv1, #0x03
	bic	rvb, sv2, #0x03
  .ifndef FPU_is_maverick
	vmov	s0, s1, rva, rvb
	vadd.f32 s0, s0, s1	
	vmov	rva, s0	
  .else
	cfmvsr	mvf0, rva
	cfmvsr	mvf1, rvb
	cfadds	mvf0, mvf0, mvf1
	cfmvrs	rva, mvf0
  .endif
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  lnk

.else	@ no hardware FPU

_func_
plsflt:	@ + for float
	anynan	sv1, sv2
	beq	nanlxt
	fltmte	rva, sv1		@ sv1 <- x1's signed mantissa,  rva <- x1's exponent
	fltmte	rvb, sv2		@ sv2 <- x2's signed mantissa,  rvb <- x2's exponent
	eq	rva, #0xff
	it	ne
	eqne	rvb, #0xff
	beq	plsspc
	cmp	rva, rvb		@ is x2's exponent > x1's exponent?
	itE	pl
	subpl	rvb, rva, rvb		@	if so,   rvb <- difference in exponents (>= 0)
	swapmi	sv1, sv2, rvc		@ sv1 <- num with lrgst expo,  sv2 <- num with smllst exp (sv4=tmp)
	itT	mi
	submi	rvb, rvb, rva		@	if not,  rvb <- difference in exponents (>= 0)
	addmi	rva, rva, rvb		@	if not,  rva <- largest exponent
	asr	rvb, sv2, rvb		@ rvb <- small mantissa shifted to large one (raw int)
	bic	rvb, rvb, #0x03		@ rva <- small mantissa shifted to large one, tag bits cleared
	orr	sv2, rvb, #int_tag	@ sv1 <- small mantissa shifted to large one (scheme int)
	add	sv1, sv1, sv2		@ sv1 <- sum of mantissas (pseudo scheme float)
	eor	sv1, sv1, #3		@ sv1 <- sum of mantissas (scheme int)
	b	mteflt			@ sv1 <- sum (scheme float) from sv1 & rva, and exit w/ rslt via lr
plsspc:	@ special addition of scheme floats with +/-inf
	eq	rva, rvb
	beq	plssp2
	eq	rva, #0xff
	itE	eq
	seteq	sv2, sv1
	setne	sv1, sv2
plssp2:	@	
	eor	rva, sv1, sv2		@ rva <- xor sv1 sv2 (sign of operands indicator)
	postv	rva			@ is rva positive (both sv1 and sv2 have same sign)?
	bne	nanlxt			@	if not, exit with nan
	ldr	sv1, =scheme_inf	@ sv1 <- inf
	postv	sv2			@ is result negative?
	it	ne
	ngfltne	sv1, sv1		@	if so,  sv1 <- -inf
	set	pc,  lnk		@ return with +/-inf or nan

.endif	@ yes/no hardware FPU
	
_func_
plsrat:	@ + for rational
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save	sv5
	save3	sv1, sv2, sv3		@ dts <- (rat1 rat2 lnk ...)
	denom	sv1, sv1		@ sv1 <- denom-rat1
	izerop	sv1
	beq	plsra0
	denom	sv2, sv2		@ sv2 <- denom-rat2
	izerop	sv2
	beq	plsra2
	bl	igcd			@ sv1 <- gcd of denom-rat1 and denom-rat2
	set	sv3, sv1		@ sv3 <- gcd of denom-rat1 and denom-rat2, saved
	car	sv1, dts		@ sv1 <- rat1
	denom	sv1, sv1		@ sv1 <- denom-rat1
	set	sv2, sv3		@ sv2 <- gcd of denom-rat1 and denom-rat2
	bl	idivid			@ sv1 <- denom-rat1 / gcd
	set	sv2, sv3		@ sv2 <- gcd of denom-rat1 and denom-rat2
	set	sv3, sv1		@ sv3 <- denom-rat1 / gcd, saved
	cadr	sv1, dts		@ sv1 <- rat2
	denom	sv1, sv1		@ sv1 <- denom-rat2
	bl	idivid			@ sv1 <- denom-rat2 / gcd
	restor	sv2			@ sv2 <- rat1,	dts <- (rat2 lnk ...)
	numerat	sv2, sv2		@ sv2 <- numer-rat1
	bl	prdint			@ sv1 <- numer-rat1 * denom-rat2 / gcd
	car	sv2, dts		@ sv2 <- rat2
	save	sv1			@ dts <- (num-rat1*den-rat2/gcd rat2 lnk ...)
	numerat	sv1, sv2		@ sv1 <- numer-rat2
	set	sv2, sv3		@ sv2 <- denom-rat1 / gcd
	bl	prdint			@ sv1 <- numer-rat2 * denom-rat1 / gcd
	restor	sv2			@ sv2 <- num-rat1*den-rat2/gcd,	dts <- (rat2 lnk ...)
	save	sv3			@ dts <- (den-rat1/gcd rat2 lnk ...)
	bl	unipls
	set	sv3, sv1
	restor2	sv1, sv2
	denom	sv2, sv2
	bl	prdint
	set	sv2, sv1
	set	sv1, sv3
_func_
plsra4:	@ common completion
	adr	lnk, plsra3
	b	unidiv

plsra0:	@ sv1 is n/0, what about sv2?
	set	rva, sv2
	restor2	sv1, sv2
	izerop	rva
	bne	plsra3
	bl	eqrtcx
	beq	plsra3
	set	sv1, #i0
	set	sv2, #i0
	b	plsra4
plsra2:	@ sv2 is n/0, but sv1 is normal => return sv2 (in sv1)
	restor2	sv1, sv1
_func_
plsra3:	@ return (also for prdrat, mnsrat, divrat)	
	restor2	sv3, sv5
	orr	lnk, sv3, #lnkbit0
	set	pc,  lnk	
	
_func_
plscpx:	@ + for cpx
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3
	imag	sv1, sv1
	imag	sv2, sv2
	bl	plsflt
	restor2	sv2, sv3
	save	sv1
	real	sv1, sv3
	real	sv2, sv2
	bl	plsflt
	restor2	sv2, sv3
	orr	lnk, sv3, #lnkbit0
	b	makcpx


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg


_func_
prdint:	@ product of scheme ints
	int2raw	rvc, sv1		@ rva <- x2 (raw int)
	int2raw	rva, sv2		@ rva <- x1 (raw int)
	smull	rva, rvb, rvc, rva	@ rva <- x1 (raw int) * x2 (raw int), rvc <- possible overflow
	raw2int	sv1, rva
	lsl	rvb, rvb, #3
	orrs	rvb, rvb, rva, lsr #29
	it	ne
	mvnsne	rvc, rvb
	it	eq
	seteq	pc,  lnk
	@ integer product overflow, convert to float
	lsl	rva, rva, #3
	set	rvc, rvb
	postv	rvc
	it	ne
	mvnne	rvc, rvc
	
.ifndef	hardware_FPU	@ exclude cortex-a8
  .ifndef cortex	@ left shift on ARMv4T
	set	sv2, #i0
prdcf0:	postv	rvc
	itT	eq
	addeq	sv2, sv2, #4
	lsleq	rvc, rvc, #1
	beq	prdcf0
	int2raw	rvc, sv2
  .else
	clz	rvc, rvc
  .endif
.else
  .ifndef FPU_is_maverick
	clz	rvc, rvc
  .else
	set	sv2, #i0
prdcf0:	postv	rvc
	itT	eq
	addeq	sv2, sv2, #4
	lsleq	rvc, rvc, #1
	beq	prdcf0
	int2raw	rvc, sv2
  .endif
.endif
	@ common completion	
	sub	rvc, rvc, #1
	lsl	rvb, rvb, rvc
	rsb	rvc, rvc, #32
	lsr	rva, rva, rvc
	orr	rvb, rvb, rva
	bic	rvb, rvb, #3
	orr	sv1, rvb, #int_tag
	add	rva, rvc, #147
	b	mteflt

.ifdef	hardware_FPU

_func_
prdflt:	@ * for float
	bic	rva, sv1, #0x03
	bic	rvb, sv2, #0x03
  .ifndef FPU_is_maverick
	vmov	s0, s1, rva, rvb
	vmul.f32 s0, s0, s1	
	vmov	rva, s0	
  .else
	cfmvsr	mvf0, rva
	cfmvsr	mvf1, rvb
	cfmuls	mvf0, mvf0, mvf1
	cfmvrs	rva, mvf0
  .endif
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  lnk

.else	@ no hardware FPU

_func_
prdflt:	@ product of scheme floats
	anynan	sv1, sv2		@ is either sv1 or sv2 = nan?
	beq	nanlxt			@	if so,  exit with nan
	fltmte	rva, sv1		@ sv1 <- signed mantissa of x1, rva <- biased exponent of x1
	fltmte	rvb, sv2		@ sv2 <- signed mantissa of x2, rvb <- biased exponent of x2
	eq	rva, #0xff
	it	ne
	eqne	rvb, #0xff
	beq	prdspc
	add	rvb, rvb, rva
	sub	rvb, rvb, #133		@ rvb <- biased exponent of result	
	int2raw	rva, sv1
	int2raw	rvc, sv2
	raw2int	sv2, rvb
	smull	rva, rvb, rvc, rva	@ rvb  <- product of x1 and x2 mantissas
	lsl	rvb, rvb, #17
	orr	rvb, rvb, rva, lsr #15
	lsl	rva, rva, #17
prdfl1:	@
	ands	rvc, rvb, #0x30000000
	it	ne
	eqne	rvc, #0x30000000
	bne	prdfl2
	lsl	rvb, rvb, #1
	tst	rva, #0x80000000
	it	ne
	orrne	rvb, rvb, #1
	lsls	rva, rva, #1
	sub	sv2, sv2, #4
	bne	prdfl1	
prdfl2:	raw2int	sv1, rvb
	int2raw	rva, sv2
	b	mteflt			@ sv1 <- float from sv1 sgnd mant. & rva bsd exp, return via lnk
prdspc:	@ special product of scheme floats with +/-inf
	eq	rva, #0
	it	eq
	eqeq	sv1, #i0
	beq	nanlxt			@ (* 0 inf) -> nan
	eq	rvb, #0
	it	eq
	eqeq	sv2, #i0
	beq	nanlxt			@ (* inf 0) -> nan
	eor	rva, sv1, sv2		@ rva <- item with sign of result in MSb
	and	rva, rva, #0x80000000	@ rva <- sign of result
	ldr	sv1, =scheme_inf	@ sv1 <- inf
	orr	sv1, sv1, rva		@ sv1 <- signed inf
	set	pc,  lnk		@ exit with +/-inf
	
.endif	@ yes/no hardware FPU


_func_
prdrat:	@ product of two rats
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save	sv5
	save3	sv1, sv2, sv3
	numerat	sv1, sv1		@ sv1 <- denominator of r1
	denom	sv2, sv2
	bl	makrat
	restor2	sv2, sv3
	save	sv1
	denom	sv2, sv2
	numerat	sv1, sv3
	bl	makrat
	restor	sv2
	bl	uninum
	pntrp	sv1
	it	ne
	setne	sv3, #5
	bne	prdrxt
	spltrat	sv3, sv2, sv2		@ sv3 <- numerator of r2, sv2 <- denominator of r2
	save	sv3
	spltrat	sv3, sv1, sv1		@ sv3 <- numerator of r1, sv1 <- denominator of r1
	bl	prdint			@ sv1 <- product of denominators
	set	sv2, sv3
	set	sv3, sv1
	restor	sv1
prdrxt:	@
	bl	prdint			@ sv1 <- product of numerators
	set	sv2, sv3		@ sv2 <- product of denominators
	adr	lnk, plsra3
	b	unidiv

_func_
prdcpx:	@ * for cpx
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3
	real	sv1, sv1		@ sv1 <- real part of z1
	imag	sv2, sv2		@ sv2 <- imag part of z2
	bl	prdflt			@ sv1 <- first real-x-imag product
	snoc	sv2, sv3, dts		@ sv2 <- z1, sv3 <- (z2 lnk ...)
	save	sv1			@ dts <- (partial-imag-prod z1 z2 lnk ...)
	car	sv1, sv3		@ sv1 <- z2
	real	sv1, sv1		@ sv1 <- real part of z2
	imag	sv2, sv2		@ sv2 <- imag part of z1
	bl	prdflt			@ sv1 <- second real-x-imag product
	restor	sv2			@ sv2 <- first  real-x-imag product, dts <- (z1 z2 lnk ...)
	bl	plsflt			@ sv1 <- imag part of product
	snoc	sv2, sv3, dts		@ sv2 <- z1, sv3 <- (z2 lnk ...)
	save	sv1			@ dts <- (imag-prod z1 z2 lnk ...)
	car	sv1, sv3		@ sv1 <- z2
	real	sv1, sv1		@ sv1 <- real part of z2
	real	sv2, sv2		@ sv2 <- real part of z1
	bl	prdflt			@ sv1 <- product of real parts
	cdr	sv3, dts		@ sv3 <- (z1 z2 lnk ...)
	snoc	sv2, sv3, sv3		@ sv2 <- z1, sv3 <- (z2 lnk ...)
	save	sv1			@ dts <- (prod-real-parts imag-prod z1 z2 lnk ...)
	car	sv1, sv3		@ sv1 <- z2
	imag	sv1, sv1		@ sv1 <- imag part of z2
	imag	sv2, sv2		@ sv2 <- imag part of z1
	bl	prdflt			@ sv1 <- product of imag parts
	ngflt	sv1, sv1		@ sv1 <- minus product of imag parts
	restor	sv2			@ sv2 <- product of real parts, dts <- (imag-prod z1 z2 lnk ...)
	bl	plsflt			@ sv1 <- real part of product
	restor	sv2			@ sv2 <- imag part of product, dts <- (z1 z2 lnk ...)
	cddr	dts, dts		@ dts <- (lnk ...)
	restor	sv3			@ sv3 <- lnk, dts <- (...)
	orr	lnk, sv3, #lnkbit0	@ lnk <- lnk, restored
	b	makcpx			@ jump to build complex, return via lnk


_func_
mnsint:	@ - for int
	ngint	sv2, sv2
	b	plsint

_func_
mnsflt:	@ - for flt
	anynan	sv1, sv2
	beq	nanlxt
	ngflt	sv2, sv2
	b	plsflt
	
_func_
mnsrat:	@ - for rat
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv3, sv5
	spltrat	sv1, sv2, sv2
	ngint	sv1, sv1
	bl	makrat
	set	sv2, sv1
	restor	sv1
	ldr	lnk, =plsra3
	b	unipls

_func_
mnscpx: @ - for cpx
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save2	sv1, sv3
	spltcpx	sv1, sv2, sv2
	ngflt	sv1, sv1
	ngflt	sv2, sv2
	bl	makcpx
	set	sv2, sv1
	restor2	sv1, sv3
	orr	lnk, sv3, #lnkbit0
	b	plscpx			@ continue to plus12 to add num1 with -num2


.ifdef	hardware_FPU

  .ifndef FPU_is_maverick

_func_
divflt:	@ / for flt
	@ modifies:	sv1, rva, rvb
	bic	rva, sv1, #0x03
	bic	rvb, sv2, #0x03
	vmov	s0, s1, rva, rvb
	vdiv.f32 s0, s0, s1	
	vmov	rva, s0	
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  lnk

  .else	@ Maverick Crunch FPU does not do division
	@ so, code below is same as with no hardware FPU

_func_
divflt:	@ / for flt
	@ modifies:	sv1, sv2, rva, rvb, rvc
	anynan	sv1, sv2
	beq	nanlxt
	eq	sv1, #f0
	it	ne
	eqne	sv2, #f0
	beq	divzro
	@ division of scheme floats
	set	rva, #0xFF000000	@ rva <- mask for float exponent
	and	rvb, rva, sv1, LSL #1	@ rvb <- exponent
	eq	rva, rvb
	itT	ne
	andne	rvb, rva, sv2, LSL #1	@ rvb <- exponent
	eqne	rva, rvb
	beq	divspc
	@ regular division of scheme floats
	fltmte	rva, sv1		@ sv1 <- dividand's mantissa,  rva <- dividand's biased exponent
	fltmte	rvb, sv2		@ sv2 <- divisor's mantissa,   rvb <- divisor's biased exponent
	add	rva, rva, #148		@ rva <- dividand's biased exponent + 127 + 21
	sub	rva, rva, rvb		@ rva <- initial result's biased exponent (raw int)
divnrm:	@ normal division of scheme floats (no zeros involved)
	and	rvc, sv1, #0x80000000
	postv	sv1			@ is dividand positive?
	itT	ne
	eorne	rvc, rvc, #int_tag	@	if not, sv5 <- lr xor int_tag => negative result
	ngintne	sv1, sv1		@	if not, sv1 <- -dividand (scheme int)
	postv	sv2			@ is divisor positive?
	itT	ne
	eorne	rvc, rvc, #int_tag	@	if not, sv5 <- lr xor sign (int_tag or zero)
	ngintne	sv2, sv2		@	if not, sv2 <- -divisor (scheme int)
	@ shift divisor left as much as possible
dvdls2:	@
	tst	sv2, #0x40000000	@ is bit 30 of divisor = 1?
	itTT	eq
	addeq	rva, rva, #1		@	if not, rva <- exponent minus 1
	lsleq	sv2, sv2, #1		@	if not, sv2 <- divisor shifted left (pseudo sheme float)
	eoreq	sv2, sv2, #0x03		@	if not, sv2 <- divisor shifted left (scheme int)
	beq	dvdls2			@	if not, jump to keep shifting
	int2raw	rvb, sv1		@ rvb <- initial dividand (raw int)
	set	sv1, #i0		@ sv1 <- initial result = 0 (scheme int)
	@  sv1 <- result mantissa, sv4 <- biased exponent of result (scheme int)
dvddls:	@ shift dividand (rvb) to be greater or equal to divisor (sv2)
	cmp	rvb, sv2, LSR #2	@ is dividand >= divisor (raw int)
	bpl	dvddvd			@	if so,  jump to continue
	lsl	rvb, rvb, #1		@ rvb <- dividand shifted left
	sub	rva, rva, #1		@ rva <- add 1 to shift
	lsl	sv1, sv1, #1		@ sv1 <- result shifted left (pseudo scheme float)
	eor	sv1, sv1, #3		@ sv1 <- result shifted left (scheme int)
	tst	sv1, #0x40000000	@ is result saturated?
	beq	dvddls			@	if not, jump to continue shifting dividand
dvddvd:	subs	rvb, rvb, sv2, LSR #2	@ rvb <- updated dividand = shifted dividand - divisor
	it	pl
	addpl	sv1, sv1, #4		@	if positive dividand, sv1 <- result + 1 (scheme int)
	beq	dvddon			@	if remainder is 0, jump to finish up  
	tst	sv1, #0x40000000	@ is result saturated?
	beq	dvddls			@	if not, jump to continue dividing
dvddon:	@ update result sign if necessary
	tst	rvc, #int_tag		@ should result be negative?
	it	ne
	ngintne	sv1, sv1		@	if so,  sv1 <-  -sv1
	b	mteflt			@ sv1 <- result as float, return via lr
divzro:	@ division of 0 by dividand or of divisor by 0
	eq	sv1, sv2		@ are divisor and dividand both zero?
	beq	nanlxt
	zerop	sv1			@ is dividand = 0 or 0.0?
	itTT	ne
	andne	rva, sv1, #0x80000000	@	if not, rva <- sign of dividand
	ldrne	sv1, =scheme_inf	@	if not, sv1 <- inf
	orrne	sv1, sv1, rva		@	if not, sv1 <- +/-inf (same sign as dividand)
	set	pc,  lnk		@ return with 0, 0.0 or inf
divspc:	@ special division of scheme floats with nan or +/-inf
	lsl	rvb, sv1, #1		@ rvb <- x1 without sign (shifted out)
	teq	rvb, sv2, LSL #1	@ is x1 (unsigned) = x2 (unsigned) ( +-inf  /  +-inf )?
	beq	nanlxt
	isinf	sv1
	it	ne
	setne	sv1, #f0		@	if not, sv1 <- 0.0	(value / +-inf)
	set	pc,  lnk		@ return with +/-inf or 0.0
	
  .endif	@ FPU_is_maverick

.else	@ no hardware FPU

_func_
divflt:	@ / for flt
	@ modifies:	sv1, sv2, rva, rvb, rvc
	anynan	sv1, sv2
	beq	nanlxt
	eq	sv1, #f0
	it	ne
	eqne	sv2, #f0
	beq	divzro
	@ division of scheme floats
	set	rva, #0xFF000000	@ rva <- mask for float exponent
	and	rvb, rva, sv1, LSL #1	@ rvb <- exponent
	eq	rva, rvb
	itT	ne
	andne	rvb, rva, sv2, LSL #1	@ rvb <- exponent
	eqne	rva, rvb
	beq	divspc
	@ regular division of scheme floats
	fltmte	rva, sv1		@ sv1 <- dividand's mantissa,  rva <- dividand's biased exponent
	fltmte	rvb, sv2		@ sv2 <- divisor's mantissa,   rvb <- divisor's biased exponent
	add	rva, rva, #148		@ rva <- dividand's biased exponent + 127 + 21
	sub	rva, rva, rvb		@ rva <- initial result's biased exponent (raw int)
divnrm:	@ normal division of scheme floats (no zeros involved)
	and	rvc, sv1, #0x80000000
	postv	sv1			@ is dividand positive?
	itT	ne
	eorne	rvc, rvc, #int_tag	@	if not, sv5 <- lr xor int_tag => negative result
	ngintne	sv1, sv1		@	if not, sv1 <- -dividand (scheme int)
	postv	sv2			@ is divisor positive?
	itT	ne
	eorne	rvc, rvc, #int_tag	@	if not, sv5 <- lr xor sign (int_tag or zero)
	ngintne	sv2, sv2		@	if not, sv2 <- -divisor (scheme int)
	@ shift divisor left as much as possible
dvdls2:	@
	tst	sv2, #0x40000000	@ is bit 30 of divisor = 1?
	itTT	eq
	addeq	rva, rva, #1		@	if not, rva <- exponent minus 1
	lsleq	sv2, sv2, #1		@	if not, sv2 <- divisor shifted left (pseudo sheme float)
	eoreq	sv2, sv2, #0x03		@	if not, sv2 <- divisor shifted left (scheme int)
	beq	dvdls2			@	if not, jump to keep shifting
	int2raw	rvb, sv1		@ rvb <- initial dividand (raw int)
	set	sv1, #i0		@ sv1 <- initial result = 0 (scheme int)
	@  sv1 <- result mantissa, sv4 <- biased exponent of result (scheme int)
dvddls:	@ shift dividand (rvb) to be greater or equal to divisor (sv2)
	cmp	rvb, sv2, LSR #2	@ is dividand >= divisor (raw int)
	bpl	dvddvd			@	if so,  jump to continue
	lsl	rvb, rvb, #1		@ rvb <- dividand shifted left
	sub	rva, rva, #1		@ rva <- add 1 to shift
	lsl	sv1, sv1, #1		@ sv1 <- result shifted left (pseudo scheme float)
	eor	sv1, sv1, #3		@ sv1 <- result shifted left (scheme int)
	tst	sv1, #0x40000000	@ is result saturated?
	beq	dvddls			@	if not, jump to continue shifting dividand
dvddvd:	subs	rvb, rvb, sv2, LSR #2	@ rvb <- updated dividand = shifted dividand - divisor
	it	pl
	addpl	sv1, sv1, #4		@	if positive dividand, sv1 <- result + 1 (scheme int)
	beq	dvddon			@	if remainder is 0, jump to finish up  
	tst	sv1, #0x40000000	@ is result saturated?
	beq	dvddls			@	if not, jump to continue dividing
dvddon:	@ update result sign if necessary
	tst	rvc, #int_tag		@ should result be negative?
	it	ne
	ngintne	sv1, sv1		@	if so,  sv1 <-  -sv1
	b	mteflt			@ sv1 <- result as float, return via lr
divzro:	@ division of 0 by dividand or of divisor by 0
	eq	sv1, sv2		@ are divisor and dividand both zero?
	beq	nanlxt
	zerop	sv1			@ is dividand = 0 or 0.0?
	itTT	ne
	andne	rva, sv1, #0x80000000	@	if not, rva <- sign of dividand
	ldrne	sv1, =scheme_inf	@	if not, sv1 <- inf
	orrne	sv1, sv1, rva		@	if not, sv1 <- +/-inf (same sign as dividand)
	set	pc,  lnk		@ return with 0, 0.0 or inf
divspc:	@ special division of scheme floats with nan or +/-inf
	lsl	rvb, sv1, #1		@ rvb <- x1 without sign (shifted out)
	teq	rvb, sv2, LSL #1	@ is x1 (unsigned) = x2 (unsigned) ( +-inf  /  +-inf )?
	beq	nanlxt
	isinf	sv1
	it	ne
	setne	sv1, #f0		@	if not, sv1 <- 0.0	(value / +-inf)
	set	pc,  lnk		@ return with +/-inf or 0.0
	
.endif	@ yes/no hardware FPU

_func_
divrat:	@ / for rats
	@ should do a cross gcd12 between num/denom
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv3, sv5
	spltrat	sv2, sv1, sv2		@ sv2 <- numerator of r2, sv1 <- denominator of r2
	bl	makrat
	restor	sv2
	ldr	lnk, =plsra3
	b	uniprd

_func_
divcpx:	@ / for cpx
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3
	real	sv1, sv2		@ sv1 <- real part of z2
	set	sv2, sv1		@ sv2 <- real part of z2
	bl	prdflt			@ sv1 <- (real-z2)^2
	snoc	sv2, sv3, dts		@ sv2 <- z1, sv3 <- (z2 lnk ...)
	save	sv1			@ dts <- ((real-z2)^2 z1 z2 lnk ...)
	car	sv1, sv3		@ sv1 <- z2
	imag	sv1, sv1		@ sv1 <- imag part of z2
	set	sv2, sv1		@ sv2 <- imag part of z2
	bl	prdflt			@ sv1 <- (imag-z2)^2
	restor	sv2			@ sv2 <- (real-z2)^2, dts <- (z1 z2 lnk ...)
	bl	plsflt			@ sv1 <- magnitude(z2)^2
	set	sv2, sv1		@ sv2 <- magnitude(z2)^2
	cadr	sv1, dts		@ sv1 <- z2
	save	sv2			@ dts <- (magnitude(z2)^2 z1 z2 lnk ...)
	imag	sv1, sv1		@ sv1 <- imag part of z2
	bl	divflt			@ sv1 <- imag part of z2 / magnitude(z2)^2
	restor	sv2			@ sv2 <- magnitude(z2)^2, dts <- (z1 z2 lnk ...)
	cadr	sv3, dts		@ sv3 <- z2
	save	sv1			@ dts <- (imag-z2/mag(z2)^2 z1 z2 lnk ...)
	real	sv1, sv3		@ sv1 <- real part of z2
	bl	divflt			@ sv1 <- real part of z2 / magnitude(z2)^2
	restor	sv2			@ sv2 <- imag part of z2 / magnitude(z2)^2, dts <- (z1 z2 lnk ...)
	ngflt	sv2, sv2		@ sv2 <- minus imag part of z2 / magnitude(z2)^2
	bl	makcpx			@ sv1 <- z2* / |z2|
	restor	sv2			@ sv2 <- z1, dts <- (z2 lnk ...)
	cdr	dts, dts		@ dts <- (lnk ...)
	restor	sv3			@ sv3 <- lnk, dts <- (...)
	orr	lnk, sv3, #lnkbit0	@ lnk <- lnk, restored
	b	prdcpx			@ jump to multiply z1 by z2* / |z2|, return via lnk
	
	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg


_func_
quoint:	@ quotient for int
	set	lnk, cnt		@ lnk <- return address
	izerop	sv2
	beq	makrat
	b	idivid			@ sv1 <- quotient, and return

_func_
quoflt:	@ quotient for flt (floats are truncated before getting quotient)
	bl	divflt
	lsr	rvb, sv1, #23
	and	rvb, rvb, #0xff
	eq	rvb, #0xff
	it	ne
	blne	itrunc
	set	sv2, #f0		@ sv2 <- 0.0
	set	lnk, cnt		@ lnk <- return address
	b	uninum

_func_
quorat:	@ quotient for rat
	bl	divrat
	intgrp	sv1
	it	eq
	seteq	pc,  cnt
	spltrat	sv1, sv2, sv1
	b	quoint


_func_
remint:	@ remainder for int
	zerop	sv2
	it	eq
	seteq	pc,  cnt
	bl	idivid			@ sv1 <- quotient, sv2 <- remainder
	set	sv1, sv2		@ sv1 <- remainder
	set	pc,  cnt		@ return

_func_
remflt:	@ remainder for flt (floats are truncated before getting remainder)
	save2	sv2, sv1
	bl	divflt
	bl	itrunc
	bl	i12flt
	restor	sv2
	bl	prdflt
	ngflt	sv1, sv1
	restor	sv2
	set	lnk, cnt
	b	plsflt

_func_
remrat:	@ remainder for rat
	@ (need to check if ratcdn returned some floats)
	spltrat	rvc, sv3, sv2
	izerop	sv3
	it	eq
	eqeq	rvc, sv3
	itT	eq
	seteq	sv1, sv2
	seteq	pc,  cnt
	spltrat	rvc, sv3, sv1
	izerop	sv3
	it	eq
	eqeq	rvc, sv3
	it	eq
	seteq	pc,  cnt
	izerop	sv3
	it	eq
	seteq	pc,  cnt
	bl	ratcdn			@ sv1 <- nn1, sv2 <- nn2, sv3 <- lcm
	bl	idivid			@ sv1 <- quotient, sv2 <- remainder
	set	sv1, sv2		@ sv1 <- remainder
	set	sv2, sv3		@ sv2 <- lcm
	set	lnk, cnt
	b	makrat
	
_func_
ratcdn:	@ set rationals to common denominator
	@ on entry:	sv1 <- rational
	@ on entry:	sv2 <- rational
	@ on exit:	sv1 <- nn1
	@ on exit:	sv2 <- nn2
	@ on exit:	sv3 <- lcm
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3		@ dts <- (p1/q1 p2/q2 lnk ...)
	denom	sv1, sv1		@ sv1 <- q1
	denom	sv2, sv2		@ sv2 <- q2
	bl	gcdint			@ sv1 <- gcd(q1,q2)
	set	sv3, dts
	save	sv1			@ dts <- (gcd(q1,q2) p1/q1 p2/q2 lnk ...)
	set	sv2, sv1
	cadr	sv1, sv3
	denom	sv1, sv1		@ sv1 <- q2
	bl	idivid			@ sv1 <- q2/gcd(q1,q2)
	car	sv3, sv3
	numerat	sv2, sv3		@ sv2 <- p1
	bl	prdint			@ sv1 <- p1 q2 / gcd(q1,q2) = nn1
	restor	sv2			@ sv2 <- gcd(q1,q2), dts <- (p1/q1 p2/q2 lnk ...)
	set	sv3, dts		@ dts <- (p1/q1 p2/q2 lnk ...)
	save	sv1			@ dts <- (nn1 p1/q1 p2/q2 lnk ...)
	snoc	sv1, sv3, sv3		@ sv1 <- p1/q1, sv3 <- (p2/q2 lnk ...)
	denom	sv1, sv1		@ sv1 <- q1
	bl	idivid			@ sv1 <- q1/gcd(q1,q2)
	save	sv1			@ dts <- (q1/gcd(q1,q2) nn1 p1/q1 p2/q2 lnk ...)
	car	sv2, sv3		@ sv2 <- p2/q2
	numerat	sv2, sv2		@ sv2 <- p2
	bl	prdint			@ sv1 <- p2 q1 / gcd(q1,q2) = nn2
	restor	sv2			@ sv2 <- q1/gcd(q1,q2), dts <- (nn1 p1/q1 p2/q2 lnk ...)
	cdr	sv3, dts		@ sv3 <- (p1/q1 p2/q2 lnk ...)
	save	sv1			@ dts <- (nn2 nn1 p1/q1 p2/q2 lnk ...)
	cadr	sv1, sv3		@ sv1 <- p2/q2
	denom	sv1, sv1		@ sv1 <- q2
	bl	prdint			@ sv1 <- q1 q2 / gcd(q1,q2) = lcm
	set	sv3, sv1		@ sv3 <- lcm
	restor2	sv2, sv1		@ sv2 <- nn2, sv1 <- nn1, dts <- (p1/q1 p2/q2 lnk ...)
	cddr	dts, dts		@ dts <- (lnk ...)
	restor	rva			@ rva <- lnk, dts <- (...)
	orr	lnk, rva, #lnkbit0
	set	pc,  lnk

_func_
gcdint:	@ gcd for int
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save	sv3
	set	sv3, sv1
	set	sv1, #i0
gcdien:	@ [internal entry]
	save	sv1
	adr	lnk, gcdlop
_func_	
gcdlop:	@ gcd loop
	izerop	sv2
	itT	ne
	setne	sv1, sv3
	setne	sv3, sv2		@ sv4 <- int2 (saved against idivid -- will become int1)
	bne	idivid			@ sv1 <- quotient, sv2 <- remainder -- will become int2
	@ gcd12 exit
	iabs	sv1, sv3
	restor2	sv2, sv3
	ldr	sv5, =unirtb
	b	unijrt

	
modulo: @ (modulo int1 int2)
	@ on entry:	sv1 <- (int1 int2)
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	zerop	sv2
	beq	corerr
	ldr	sv5, =modtbl		@ rvc <- operator table
	b	unijmp			@ jump to proper

_func_
modint:	@ modulo for int
	set	sv4, sv2		@ sv4 <- divisor, saved
	bl	idivid			@ sv1 <- quotient, sv2 <- remainder
	postv	sv1			@ is quotient positive?
	itE	eq
	seteq	sv1, sv2		@	if so,  sv1 <- remainder
	plusne	sv1, sv2, sv4		@	if not, sv1 <- remainder + divisor
	set	pc,  cnt

_func_
modflt:	@ modulo for flt
	save2	sv2, sv1
	bl	divflt
	bl	itrunc
	bl	i12flt
	car	sv2, dts
	save	sv1
	bl	prdflt
	ngflt	sv1, sv1
	caddr	sv2, dts
	bl	plsflt
	restor2	sv3, sv2
	cdr	dts, dts
	postv	sv2
	it	eq
	seteq	pc,  cnt
	set	lnk, cnt
	b	plsflt
	
_func_
modrat:	@ modulo for rat
	@ (need to check if ratcdn returned some floats)
	bl	ratcdn			@ sv1 <- nn1, sv2 <- nn2, sv3 <- lcm
	set	sv4, sv2		@ sv4 <- divisor, saved
	bl	idivid			@ sv1 <- quotient, sv2 <- remainder
	postv	sv1			@ is quotient positive?
	itE	eq
	seteq	sv1, sv2		@	if so,  sv1 <- remainder
	plusne	sv1, sv2, sv4		@	if not, sv1 <- remainder + divisor
	set	sv2, sv3		@ sv2 <- lcm
	set	lnk, cnt
	b	makrat


_func_
nmrflt:	@ numerator for flt
	bl	flt2ndn
	set	lnk, cnt
	b	i12flt
	
_func_
nmrrat:	@ numerator for rat
	numerat	sv1, sv1
	set	pc,  cnt


_func_
dnmint:	@ denominator for int
	set	sv1, #i1
	set	pc,  cnt

_func_
dnmflt:	@ denominator for flt
	bl	flt2ndn		@ sv1 <- numerator of flt, sv2 <- denominator of flt
	set	sv1, sv2
	set	lnk, cnt
	b	i12flt
	
_func_
dnmrat:	@ denominator for rat
	denom	sv1, sv1
	set	pc,  cnt


floor:	@ (floor number)
	@ on entry:	sv1 <- number
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	ldr	sv4, =sfloor
	ldr	rvc, =fctrtb
	pntrp	sv1
	itE	ne
	adrne	lnk, flrflt
	adreq	lnk, flrrat
	b	numjmp			@ rva <- number,  rvb <- right shift, sv2 <- type/rem

	
_func_
fctflt:	@ common function entry for floor, ceiling, truncate, round with float arg
.ifdef	hardware_FPU
	bic	rva, sv1, #0x80000000	@ rva <- number, without sign
	cmp	rva, #0x4a000000	@ does number have exponent >= 148 (no fractional part)?
	it	pl
	setpl	pc,  cnt		@	if so,  exit with original number
	bic	rva, sv1, #0x03
  .ifndef FPU_is_maverick
	vmov	s0, rva
  .else
	cfmvsr	mvf0, rva
  .endif
	set	pc,  lnk
.else
	set	sv2, sv1		@ sv2 <- number, saved against fltmte
	set	rvb, lnk		@ rvb <- lnk,    saved against fltmte
	bl	fltmte			@ sv1 <- mantissa,  rva <- exponent
	cmp	rva, #148		@ is exponent too large (float has no fractional part)
	itT	pl
	setpl	sv1, sv2		@	if so,  sv1 <- original number (restored)
	setpl	pc,  cnt		@	if so,  exit with original number
	set	lnk, rvb		@ lnk <- restored
	rsb	rvb, rva, #148		@ rvb <- right shift needed to get integer part of number (raw int)
	int2raw	rva, sv1		@ rva <- mantissa (raw)
	set	pc,  lnk		@ return
.endif
	
.ifdef	hardware_FPU
_func_
flrflt:	@ floor completion for float
  .ifndef FPU_is_maverick
	vmrs	rvb, fpscr
	bic	rvb, rvb, #0x00c00000	@ clear rounding mode
	orr	rvb, rvb, #0x00800000	@ rounding mode = towards -inf (i.e. floor)
	vmsr	fpscr, rvb
	vcvtr.s32.f32	s0, s0
_func_
fctfxt:	@ normal completion for float, common to floor, ceiling, truncate, round
	vmrs	rvb, fpscr
	orr	rvb, rvb, #0x00c00000	@ rounding mode = towards zero (i.e. truncate = default)
	vmsr	fpscr, rvb
	vcvt.f32.s32	s0, s0
	vmov	rva, s0	
  .else
	cfmv32sc mvdx1, dspsc		@ mvfx1 <- rounding mode from DSPSC
	cfmvr64l rvb, mvdx1		@ rvb   <- rounding mode
	orr	rvb, rvb, #0x0c00	@ rounding mode = towards -inf (i.e. floor)
	cfmv64lr mvdx1, rvb		@ mvfx1 <- new rounding mode
	cfmvsc32 dspsc, mvdx1		@ set rounding mode in DSPSC
	cfcvts32 mvfx0, mvf0		@ mvfx0 <- number rounded
_func_
fctfxt:	@ normal completion for float, common to floor, ceiling, truncate, round
	cfmv32sc mvdx1, dspsc		@ mvfx1 <- rounding mode from DSPSC
	cfmvr64l rvb, mvdx1		@ rvb   <- rounding mode
	bic	rvb, rvb, #0x0c00	@ clear rounding mode
	orr	rvb, rvb, #0x0400	@ rounding mode = towards zero (i.e. truncate = default)
	cfmv64lr mvdx1, rvb		@ mvfx1 <- new rounding mode
	cfmvsc32 dspsc, mvdx1		@ set rounding mode in DSPSC
	cfcvt32s mvf0, mvfx0
	cfmvrs	rva, mvf0
  .endif
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  cnt
.else
_func_
flrflt:	@ floor completion for float
	asr	rva, rva, rvb		@ rva <- number shifted to integer
_func_
fctfxt:	@ normal completion for float, common to floor, ceiling, truncate, round
	raw2int	sv1, rva
	set	lnk, cnt
	b	i12flt
.endif
	
_func_
fctrat:	@ common function entry for floor, ceiling, truncate, round with rational arg
	spltrat	sv3, sv5, sv1		@ sv3 <- numerator, sv5 <- denominator (for round)
	izerop	sv5
	it	eq
	seteq	pc,  cnt
	set	sv1, sv3
	set	sv2, sv5
	b	idivid			@ sv1 <- quotient, sv2 <- remainder, return via lnk
	
_func_
flrrat:	@ floor completion for rational
	postv	sv2
	it	ne
	subne	sv1, sv1, #4
	set	pc,  cnt
	

ceilin:	@ (ceiling number)
	@ on entry:	sv1 <- number
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	ldr	sv4, =sceili
	ldr	rvc, =fctrtb
	pntrp	sv1
	itE	ne
	adrne	lnk, celflt
	adreq	lnk, celrat
	b	numjmp			@ rva <- number,  rvb <- right shift, sv2 <- type/rem
	
.ifdef	hardware_FPU

_func_
celflt:	@ ceiling completion for float
  .ifndef FPU_is_maverick
	vmrs	rvb, fpscr
	bic	rvb, rvb, #0x00c00000	@ clear rounding mode
	orr	rvb, rvb, #0x00400000	@ rounding mode = towards +inf (i.e. ceiling)
	vmsr	fpscr, rvb
	vcvtr.s32.f32	s0, s0
	b	fctfxt
  .else
	cfmv32sc mvdx1, dspsc		@ mvdx1 <- rounding mode from DSPSC
	cfmvr64l rvb, mvdx1		@ rvb   <- rounding mode
	bic	rvb, rvb, #0x0c00	@ clear rounding mode
	orr	rvb, rvb, #0x0800	@ rounding mode = towards +inf (i.e. ceiling)
	cfmv64lr mvdx1, rvb		@ mvdx1 <- new rounding mode
	cfmvsc32 dspsc, mvdx1		@ set rounding mode in DSPSC
	cfcvts32 mvfx0, mvf0		@ mvfx0 <- ceiling of number
	b	fctfxt
  .endif
.else
_func_
celflt:	@ ceiling completion for float
	rsb	rva, rva, #0		@ rva <- negated number
	asr	rva, rva, rvb		@ rva <- number (negated) shifted to integer
	rsb	rva, rva, #0		@ rva <- number, de-negated = result
	b	fctfxt
.endif

_func_
celrat:	@ ceiling completion for rat
	postv	sv2
	it	eq
	addeq	sv1, sv1, #4
	set	pc,  cnt


trunca:	@ (truncate number)
	@ on entry:	sv1 <- number
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	ldr	sv4, =strunc
	ldr	rvc, =fctrtb
	pntrp	sv1
	itE	ne
	adrne	lnk, trcflt
	seteq	lnk, cnt
	b	numjmp			@ rva <- number,  rvb <- right shift, sv2 <- type/rem
	
.ifdef	hardware_FPU
_func_
trcflt:	@ truncate completion for float
  .ifndef FPU_is_maverick
	vcvt.s32.f32	s0, s0
	b	fctfxt
  .else
	cfcvts32 mvfx0, mvf0		@ mvfx0 <- number truncated
	b	fctfxt
  .endif
.else
_func_
trcflt:	@ truncate completion for float
	cmp	rva, #0			@ is number negative?
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- positive number
	asr	rva, rva, rvb		@ rva <- number, shifted to integer
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- integer, restored to proper sign
	b	fctfxt
.endif


round:	@ (round number)
	@ on entry:	sv1 <- number
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	ldr	sv4, =sround
	ldr	rvc, =fctrtb
	pntrp	sv1
	itE	ne
	adrne	lnk, rndflt
	adreq	lnk, rndrat
	b	numjmp			@ rva <- number,  rvb <- right shift, sv2 <- type/rem
	
.ifdef	hardware_FPU
_func_
rndflt:	@ round completion for float
  .ifndef FPU_is_maverick
	vmrs	rvb, fpscr
	bic	rvb, rvb, #0x00c00000	@ clear rounding mode (= round)
	vmsr	fpscr, rvb
	vcvtr.s32.f32	s0, s0
	b	fctfxt
  .else
	cfmv32sc mvdx1, dspsc		@ mvdx1 <- rounding mode from DSPSC
	cfmvr64l rvb, mvdx1		@ rvb   <- rounding mode
	bic	rvb, rvb, #0x0c00	@ clear rounding mode (= round)
	cfmv64lr mvdx1, rvb		@ mvdx1 <- new rounding mode
	cfmvsc32 dspsc, mvdx1		@ set rounding mode in DSPSC
	cfcvts32 mvfx0, mvf0		@ mvfx0 <- number rounded
	b	fctfxt
  .endif
.else
_func_
rndflt:	@ round completion for float
	adr	lnk, fctfxt
	b	iround
.endif
		
_func_
rndrat:	@ round completion for rat
	lsl	sv2, sv2, #1		@ sv2 <- remainder * 2 (pseudo float)
	eor	sv2, sv2, #3		@ sv2 <- remainder * 2 (scheme int)
	postv	sv1
	it	ne
	ngintne	sv2, sv2
	cmp	sv5, sv2
	bmi	rndraa
	eq	sv5, sv2		@ is 2*remainder = dividand?
	it	ne
	setne	pc,  cnt		@	if not, return
	tst	sv1, #4			@ is result even?
	it	eq
	seteq	pc,  cnt		@	if so,  return
rndraa:	@ adjust result up or down
	postv	sv1
	itE	eq
	addeq	sv1, sv1, #4
	subne	sv1, sv1, #4
	set	pc,  cnt
		
_func_
iround:	@ helper
	@ returns an int
	@ on entry:	sv1 <- mantissa
	@ on entry:	rva <- number
	@ on entry:	rvb <- exponent (negative)
	@ modifies:	sv2, rva, rvb
	cmp	rva, #0			@ is number negative?
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- -rva (make number positive)
	rsb	rvb, rvb, #32		@ rvb <- left shift needed to get fraction
	lsl	rva, rva, rvb		@ rva <- fraction, shifted all the way left
	rsb	rvb, rvb, #32		@ rvb <- right shift needed to get whole number
	eq	rva, #0x80000000	@ is fraction exactly 0.5 ?	
	beq	round2			@	if so,  jump to process that case
	tst	rva, #0x80000000	@ is fraction > 0.5
	itE	eq
	seteq	sv2, #0			@	if not, sv2 <- 0 (raw = o.k., not RAM pointer)
	setne	sv2, #int_tag		@	if so,  sv2 <- 1 (int_tag)
	asr	rva, sv1, #2		@ rva <- re-get number from mantissa (raw int)
	cmp	rva, #0			@ is number negative?
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- -rva, make number positive
.ifndef	cortex
	add	rva, sv2, rva, ASR rvb	@ rva <- integer plus zero or one
.else
	asr	rva, rva, rvb		@ rva <- integer plus zero or one
	add	rva, sv2, rva		@ rva <- integer plus zero or one
.endif
round1:	
	postv	sv1			@ was mantissa positive?
	it	ne
	rsbne	rva, rva, #0		@	if not, rva <- integer, restored to proper sign
	set	pc,  lnk
round2:	asr	rva, sv1, #2		@ rva <- re-get number from mantissa (raw int)
	cmp	rva, #0			@ is number negative?
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- -rva, make number positive	
	asr	rva, rva, rvb		@ rva <- integer part of number
	tst	rva, #1			@ is number odd?
	it	ne
	addne	rva, rva, #1		@	if so,  rva <- number made even
	b	round1			@ jump to finish up

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

.balign	4
	
taylor:	@ Taylor series computation
	@ on entry:	sv3 <- address of Taylor series coefficients	(scheme floats, stored last->first)
	@ on entry:	sv4 <- argument					(argument must be scheme float)
	@ on exit:	sv1 <- coeff + arg*(coeff + arg*(coeff + ...	(result is scheme float)
	@ modifies:	sv1-sv3, rva-rvc
	set	sv1, #f0		@ sv1 <- 0.0 = initial-result
tayllp:	@ loop
	set	sv2, sv4
	bl	prdflt			@ sv1 <- fractional-argument * previous-result
	car	sv2, sv3		@ sv2 <- Taylor series coefficient
	bl	plsflt			@ sv1 <- updated result = coeff + fractional-arg * previous-result
	incr	sv3, sv3		@ sv3 <- address of next Taylor series coefficient
	car	sv2, sv3		@ sv2 <- next coefficient
	nullp	sv2			@ is next coefficient null?
	bne	tayllp			@	if not, jump to add term to series
	set	pc,  cnt

.balign	4
	
_func_	
spcflt:	@ special values treatment for flt
	@ on entry:	sv1 <- value to check
	@ on entry:	sv5 <- special values jump table
	eq	sv1, #f0
	it	eq
	ldreq	pc, [sv5]		@ jump to special case where function arg = 0.0
	lsr	rva, sv1, #23
	and	rva, rva, #0xff
	eq	rva, #0xff
	it	ne
	setne	pc,  lnk
	tst	sv1, #4
	bne	nanfxt
	postv	sv1
	it	eq
	ldreq	pc, [sv5, #4]		@ jump to special case where function arg = +inf
	ldr	pc, [sv5, #8]		@ jump to special case where function arg = -inf


_func_	
expint:	@ exp for int
	postv	sv1			@ is number positive?
	itE	eq
	ldreq	sv3, =scheme_e		@	if so,  sv3 <- e (scheme float)
	ldrne	sv3, =scheme_em1	@	if not, sv3 <- 1/e (scheme float)
	iabs	sv5, sv1		@ sv5 <- n
	ldr	sv1, =scheme_one
	adr	lnk, expilp
expilp:	@ loop
	eq	sv5, #i0		@ is n zero?
	it	eq
	seteq	pc,  cnt		@	if so,  exit with result
	sub	sv5, sv5, #4
	set	sv2, sv3
	b	prdflt			@ sv1 <- result = previous result * (e or 1/e)
	
_func_	
exprat:	@ exp for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to expflt
	
_func_	
expflt:	@ exp for flt
	ldr	sv5, =expspc		@ sv5 <- special values jump table
	bl	spcflt			@ exit with value if sv1 = 0, +/-inf or nan
	set	sv4, sv1		@ sv4 <- number (saved)
	bl	fltmte			@ sv1 <- mantissa,  rva <- exponent
	cmp	rva, #148		@ is number too large for a scheme int
	it	mi
	bmi	expcnt			@	if not, jump to continue
	postv	sv4			@ is truncated float positive?
	beq	infxt
	b	f0fxt
expcnt:	
	int2raw	rvb, sv1		@ rvb <- number
	rsb	rva, rva, #148		@ rvb <- right shift needed to get integer part of number (raw int)
	rsb	rvb, rvb, #0		@ rvb <- positive mantissa
	asr	rva, rvb, rva		@ rva <- number, shifted to integer
	rsb	rva, rva, #0		@ rva <- original mantissa
	raw2int	sv5, rva		@ sv5 <- n == ceiling of number (scheme int)
	ngint	sv1, sv5
	set	sv2, sv4
	bl	i12flt
	bl	plsflt			@ sv1 <- fraction = number - ceiling-of-number (scheme float)
	set	sv4, sv1
	set	sv1, sv5	
	sav__c				@ dts <- (cnt ...)
	call	expint			@ sv1 <- exp(n) (scheme float)
	set	sv5, sv1		@ sv5 <- exp(n)
	ldr	sv3, =exptsc		@ sv3 <- address of Taylor series coefficients
	call	taylor			@ sv1 <- result = coeff + arg * (coeff + arg * (coeff + ...
	restor	cnt
	set	sv2, sv5
	set	lnk, cnt
	b	prdflt
	
_func_	
expcpx:	@ exp of cpx
	spltcpx	sv1, sv2, sv1
	sav_rc	sv2			@ dts <- (y cnt ...)
	call	expflt			@ sv1 <- exp(x)
	car	sv2, dts		@ sv2 <- y
	save	sv1			@ dts <- (exp(x) y cnt ...)
	set	sv1, sv2		@ sv1 <- y
	call	sinflt			@ sv1 <- sin(y)
	cadr	sv2, dts		@ sv2 <- y
	save	sv1			@ dts <- (sin(y) exp(x) y cnt ...)
	set	sv1, sv2		@ sv1 <- y
	call	cosflt			@ sv1 <- cos(y)
	restor	sv2			@ sv2 <- sin(y),	dts <- (exp(x) y cnt ...)
	bl	makcpx			@ sv1 <- cos(y) + i sin(y)
	restor	sv2			@ sv2 <- exp(x),	dts <- (y cnt ...)
	cdr	dts, dts		@ dts <- (cnt ...)
	restor	cnt			@ cnt <- cnt,		dts <- (...)
	set	lnk, cnt		@ lnk <- cnt
	b	uniprd


_func_	
ninfxt:	@ exit with -inf
	ldr	sv1, =scheme_inf		@ sv1 <- inf (scheme float)
	ngflt	sv1, sv1
	set	pc,  cnt

_func_	
ipifxt:	@ exit with inf + pi.i
	ldr	sv1, =scheme_inf		@ sv1 <- inf (scheme float)
	b	lognxt

_func_	
logint:	@ log for int
_func_	
lograt:	@ log for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to logflt

_func_	
logflt:	@ log for flt
	ldr	sv5, =logspc		@ sv5 <- special values jump table
	bl	spcflt			@ exit with value if sv1 = 0, +/-inf or nan
	postv	sv1			@ is number >= 0?
	bne	logneg			@	if not, jump to log of negative number
	ldr	sv2, =scheme_one	@ sv2 <- 1.0
	ldr	rva, =0x7F800000	@ rva <- mask for float's exponent
	and	rvb, sv1, rva		@ rvb <- number's base 2 biased exponent, in exp position
	bic	sv1, sv1, rva		@ sv1 <- number without exponent (scheme float)
	lsr	rvb, rvb, #23		@ rvb <- number's base 2 biased exponent (raw int)
	eq	rvb, #0			@ is exponent zero? (i.e. number is denormalized)
	bne	logcnt			@	if not,  jump to continue
	eor	sv1, sv1, #0x03		@ sv1 <- number as pseudo-scheme-int
	set	rva, #31		@ rva <- 31 (position of first potential msb)
intms0:	lsr	rvb, sv1, rva
	tst	sv1, rvb		@ is bit rva a 1 (tested against int_tag) ?
	it	eq
	subeq	rva, rva, #1		@ rva <- (rva - 1) = next possible msb
	beq	intms0			@ jump to test that bit
	rsb	rvb, rva, #23		@ rvb <- shift needed to pseud-normalize number
	bic	rva, sv1, #int_tag	@ rva <- number without tag
	lsl	rva, rva, rvb		@ rva <- number shifted to pseudo-normalized form
	bic	rva, rva, #0x00800000	@ rva <- pseudo-normalized number without 1. bit
	orr	sv1, rva, #float_tag	@ sv1 <- pseudo-normalized number (scheme float)
	rsb	rvb, rvb, #1		@ rvb  <- number's biased exponent (negative, raw int)
logcnt:	sub	rvb, rvb, #127		@ rvb <- power-of+2 of number (raw int)
	lsl	rvb, rvb, #2		@ rvb <- power-of+2, shifted
	orr	sv3, rvb, #int_tag	@ sv3 <- power-of+2 (scheme int)
	orr	sv1, sv1, sv2		@ sv1 <- number with biased exponent of 127 (i.e. 1.0 <= to < 2.0)
	tst	sv1, #0x00400000	@ is number >= 1.5?
	itT	ne
	bicne	sv1, sv1, #0x00800000	@	if so,  sv1 <- number rescaled to 0.75 -> 1.0
	addne	sv3, sv3, #4		@	if so,  sv3 <- power-of+2 adjusted to exponent of 126
	ngflt	sv2, sv2		@ sv2 <- -1.0
	bl	plsflt			@ sv1 <- adjusted-number-minus-1
	set	sv4, sv1
	set	sv1, sv3		@ sv1 <- power-of+2 (scheme int)
	ldr	sv2, =scheme_log_two	@ sv2 <- (log 2)
	bl	uniprd
	set	sv5, sv1
	ldr	sv3, =logtsc		@ sv3 <- address of Taylor series coefficients
	sav__c				@ dts <- (cnt ...)
	call	taylor			@ sv1 <- result = coeff + arg * (coeff + arg * (coeff + ...
	restor	cnt
	set	sv2, sv5
	set	lnk, cnt
	b	plsflt

logneg:	@ log of negative flt
	sav__c				@ dts <- (cnt ...)
	ngflt	sv1, sv1
	call	logflt
	restor	cnt
lognxt:	@ common exit for case with negative arg
	ldr	sv2, =scheme_pi
	set	lnk, cnt
	b	makcpx

_func_	
logcpx:	@ log of complex
	sav_rc	sv1			@ dts <- (z cnt ...)
	call	angcpx			@ sv1 <- angle(z)
	restor	sv2			@ sv2 <- z,	dts <- (cnt ...)
	save	sv1			@ dts <- (angle(z) cnt ...)
	set	sv1, sv2		@ sv1 <- z
	call	magcpx			@ sv1 <- magnitude(z)
	call	logflt			@ sv1 <- log(magnitude(z))
	restor2	sv2, cnt		@ sv2 <- angle(z), cnt <- cnt, dts <- (...)
	set	lnk, cnt		@ lnk <- cnt
	b	makcpx			@ sv1 <- log(magnitude(z)) + i angle(z)


_func_	
sinint:	@ sin for int
_func_	
sinrat:	@ sin for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to sinflt
	
_func_	
sinflt:	@ sin for flt
	ldr	sv5, =sinspc		@ sv5 <- special values jump table
	bl	spcflt			@ exit with value if sv1 = 0, +/-inf or nan
	set	sv3, #f0		@ sv3 <- +0.0 = sign of result (scheme float)
	postv	sv1			@ is angle positive?
	itT	ne
	ngfltne	sv1, sv1		@	if not, sv1 <- positive angle
	ngfltne	sv3, sv3		@	if not, sv3 <- -0.0, negative sign for result
	ldr	sv5, =scheme_two_pi	@ sv5 <- 2pi
	cmp	sv5, sv1		@ is angle <= 2pi ?
	bpl	sin1			@	if so,  jump to continue
	set	sv5, sv1
	ldr	sv2, =scheme_two_pi	@ sv2 <- 2pi
	bl	divflt			@ sv1 <- angle/2pi
	set	sv2, sv1		@ sv2 <- angle/2pi (saved)
	bl	fltmte			@ sv1 <- mantissa,  rva <- exponent
	cmp	rva, #148		@ is angle/2pi too large for a scheme int
	bpl	nanfxt
	rsb	rva, rva, #150		@ rva <- right shift needed to get integer part of number (raw int)
	asr	rva, sv1, rva		@ rva <- number, shifted to integer
	raw2int	sv1, rva		@ sv1 <- n == truncated(angle/2pi)
	bl	i12flt
	ldr	sv2, =scheme_two_pi	@ sv2 <- 2pi
	bl	prdflt			@ sv1 <- angle as n * 2pi
	ngflt	sv2, sv1		@ sv2 <- minus angle as n * 2pi
	set	sv1, sv5	
	bl	plsflt			@ sv1 <- angle remapped == angle - n * 2pi
sin1:	ldr	sv5, =scheme_pi		@ sv5 <- pi
	cmp	sv5, sv1		@ is angle <= pi ?
	itTTT	mi
	ngfltmi	sv1, sv1		@	if not, sv1 <- -angle
	ngfltmi	sv3, sv3		@	if not, sv3 <- -sign
	ldrmi	sv2, =scheme_two_pi	@	if not, sv2 <- 2pi
	blmi	plsflt			@	if not, sv1 <- (- 2pi angle)
	ldr	sv5, =scheme_half_pi	@ sv5 <- pi/2
	cmp	sv5, sv1		@ is angle <= pi/2 ?
	itTT	mi
	ngfltmi	sv1, sv1		@	if not, sv1 <- -angle
	ldrmi	sv2, =scheme_pi		@	if not, sv2 <- pi
	blmi	plsflt			@	if not, sv1 <- (- pi angle)
	@ calculate sine of angle between 0 and pi/2
	bic	rva, sv3, #float_tag	@ rva <- sign, raw
	orr	sv1, sv1, rva		@ sv1 <- signed-angle
	set	sv5, sv1
	set	sv2, sv1		@ sv2 <- signed-angle
	bl	prdflt			@ sv1 <- angle-squared	
	set	sv4, sv1
	ldr	sv3, =sintsc		@ sv3 <- address of Taylor series coefficients
	sav__c				@ dts <- (cnt ...)
	call	taylor			@ sv1 <- result = coeff + arg * (coeff + arg * (coeff + ...
	restor	cnt
	@ multiply result by signed-angle and exit
	set	sv2, sv5
	set	lnk, cnt
	b	prdflt

_func_	
sincpx:	@ sin of complex
	sav_rc	sv1			@ dts <- (z cnt ...)
	real	sv1, sv1		@ sv1 <- x
	call	cosflt			@ sv1 <- cos(x)
	car	sv2, dts		@ sv2 <- z
	save	sv1			@ dts <- (cos(x) z cnt ...)
	real	sv1, sv2		@ sv1 <- x
	call	sinflt			@ sv1 <- sin(x)
	cadr	sv2, dts		@ sv2 <- z
	save	sv1			@ dts <- (sin(x) cos(x) z cnt ...)
	imag	sv1, sv2		@ sv1 <- y
	call	expflt			@ sv1 <- exp(y)
	caddr	sv2, dts		@ sv2 <- z
	save	sv1			@ dts <- (exp(y) sin(x) cos(x) z cnt ...)
	imag	sv1, sv2		@ sv1 <- y
	ngflt	sv1, sv1		@ sv1 <- -y
	call	expflt			@ sv1 <- exp(-y)
	restor	sv2			@ sv2 <- exp(y),	dts <- (sin(x) cos(x) z cnt ...)
	set	sv4, sv1		@ sv4 <- exp(-y)
	set	sv5, sv2		@ sv5 <- exp(y)
	bl	plsflt			@ sv1 <- exp(y) + exp(-y)
	ngflt	sv2, sv4		@ sv2 <- -exp(-y)
	set	sv4, sv1		@ sv4 <- exp(y) + exp(-y)
	set	sv1, sv5		@ sv1 <- exp(y)
	bl	plsflt			@ sv1 <- exp(y) - exp(-y)
	restor2	sv5, sv2		@ sv5 <- sin(x), sv2 <- cos(x), dts <- (z cnt ...)
	bl	prdflt			@ sv1 <- [exp(y) - exp(-y)] * cos(x)
	swap	sv1, sv5, sv3		@ sv1 <- sin(x),	sv5 <- [exp(y) - exp(-y)] * cos(x)
	set	sv2, sv4		@ sv2 <- exp(y) + exp(-y)
	bl	prdflt			@ sv1 <- [exp(y) + exp(-y)] * sin(x)
	set	sv2, sv5		@ sv2 <- [exp(y) - exp(-y)] * cos(x)
	bl	makcpx			@ sv1 <- [exp(y) + exp(-y)] * sin(x) + i[exp(y) - exp(-y)] * cos(x)
	set	sv2, #0x09		@ sv2 <- 2 (scheme int)
	cdr	dts, dts		@ dts <- (cnt ...)
	restor	cnt			@ cnt <- cnt,		dts <- (...)
	set	lnk, cnt		@ lnk <- cnt
	b	unidiv
		

_func_	
cosint:	@ cos for int
_func_	
cosrat:	@ cos for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to cosflt
	
_func_	
cosflt:	@ cos for flt
	ldr	sv2, =scheme_half_pi	@ sv2 <- pi/2 (scheme float)
	adr	lnk, sinflt
	b	plsflt

_func_	
coscpx:	@ cos for cpx
	ldr	sv2, =scheme_half_pi	@ sv2 <- pi/2 (scheme float)
	bl	unipls
	floatp	sv1
	beq	sinflt			@	if so,  branch to calculate cos as sin(angle+pi/2) and exit
	b	sincpx			@ branch to calculate cos as sin(angle+pi/2) and exit


tan:	@ (tan angle)
	sav_rc	sv1			@ dts <- (angle cnt ...)
	ldr	rvc, =costb
	call	numjmp			@ sv1 <- cos(angle)
	set	sv2, sv1		@ sv2 <- cos(angle)
	restor	sv1			@ sv1 <- angle, dts <- (cnt ...)
	save	sv2			@ dts <- (cos(angle) cnt ...)
	ldr	rvc, =sintb
	call	numjmp			@ sv1 <- sin(angle)
	restor2	sv2, cnt		@ sv2 <- cos(angle), cnt <- cnt, dts <- (...)
	set	lnk, cnt
	b	unidiv
	
.ltorg
	
	
_func_	
asnint:	@ asin for int
_func_	
asnrat:	@ asin for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to asnflt
	
_func_	
asnflt:	@ asin for flt
	ldr	sv5, =asnspc		@ sv5 <- special values jump table
	bl	spcflt			@ exit with value if sv1 = 0, +/-inf or nan
	fabs	rva, sv1
	ldr	rvb, =#0x3D5F6376
	cmp	rva, rvb
	bmi	asnfsm
	set	sv4, sv1
	ldr	sv1, =scheme_one	@ sv3 <- 1 (sign as scheme float)
	fabs	sv3, sv4
	cmp	sv1, sv3
	itTT	mi
	setmi	sv1, sv4
	adrmi	lnk, asncpx
	setmi	sv2, #f0
	bmi	flt2cpx
	postv	sv4			@ is number positive?
	itT	ne
	ngfltne	sv4, sv4		@	if not, sv3 <- minus number
	ngfltne	sv1, sv1		@	if not, sv1 <- -1, sign
	set	sv5, sv1
	sav__c				@ dts <- (cnt ...)
	ldr	sv3, =asntsc		@ sv3 <- address of Taylor series coefficients
	call	taylor			@ sv1 <- result = coeff + arg * (coeff + arg * (coeff + ...))
	@ finish up
	restor	cnt
	set	sv3, sv4
	set	sv4, sv1
	ngflt	sv1, sv3		@ sv1 <- minus abs-number
	ldr	sv2, =scheme_one	@ sv2 <- 1.0 (scheme float)
	bl	plsflt			@ sv1 <- 1.0 - abs-number
	save3	sv4, sv5, cnt	
	call	sqrflt			@ sv1 <- sqrt(1-x)
	restor	sv2
	bl	uniprd
	set	sv2, sv1		@ sv2 <- result * sqrt(1-x)
	ldr	sv1, =scheme_half_pi	@ sv1 <- pi/2
	bl	unimns			@ sv1 <- pi/2 - result * sqrt(1-x)
	restor2	sv2, cnt
	set	lnk, cnt
	b	uniprd			@ sv1 <- sign * [ pi/2 - result * sqrt(1-x) ], return via lnk
		
asnfsm:	@ asin for small arg (< 0.0545382) -- formerly (< 1/32)
	set	sv2, sv1
	set	sv4, sv1
	bl	prdflt
	set	sv2, #0x19		@ sv2 <- 6 (scheme int)
	bl	unidiv
	ldr	sv2, =scheme_one
	bl	plsflt
	set	sv2, sv4
	set	lnk, cnt
	b	prdflt			@ sv1 <- x*(1+x^2/6)

_func_	
asncpx:	@ asin for cpx
	@
	@ for accuracy:
	@	if real part is negative:	
	@	1) negate the whole z
	@	2) compute asin
	@	3) negate the whole complex result
	@ (otherwise,  i z + sqrt(1 - z^2) gives huge roundoff error, eg. when z = -1000)
	@
	sav_rc	sv1			@ dts <- (z cnt ...)
	set	sv2, sv1		@ sv2 <- z
	bl	prdcpx			@ sv1 <- z^2
	set	sv2, sv1		@ sv2 <- z^2
	set	sv1, #5			@ sv1 <- 1 (scheme int)
	bl	unimns			@ sv1 <- 1 - z^2
	ldr	sv5, =sqrttb
	call	unijmp			@ sv1 <- sqrt(1 - z^2)
	restor	sv2			@ sv2 <- z,		dts <- (cnt ...)
	bl	uninum
	spltcpx	sv4, sv3, sv1		@ sv4 <- real( sqrt(1 - z^2) ), sv4 <- real( sqrt(1 - z^2) )
	spltcpx	sv2, sv1, sv2		@ sv2 <- x,  sv1 <- y
	fabs	rva, sv3		@ rva <- |imag(sqrt(1 - z^2))|
	fabs	rvb, sv4		@ rva <- |real(sqrt(1 - z^2))|
	cmp	rva, rvb		@ is |imag(sqrt(1 - z^2))| > |real(sqrt(1 - z^2))|
	bpl	asncp0
	@ if sv4 and sv1 have different signs, we have normal case, negate sv1, otherwise negate sv2
	eor	rva, sv1, sv4
	postv	rva
	itTEE	ne
	ngfltne	sv1, sv1		@ sv1 <- -y
	setne	sv5, #t
	ngflteq	sv2, sv2		@ sv2 <- -x
	seteq	sv5, #f
	b	asncp1
asncp0:	@ if sv3 and sv2 have same sign, we have normal case, negate sv1, otherwise negate sv2
	eor	rva, sv2, sv3
	postv	rva
	itTEE	ne
	ngfltne	sv2, sv2		@ sv2 <- -x
	setne	sv5, #f
	ngflteq	sv1, sv1		@ sv1 <- -y
	seteq	sv5, #t
asncp1:	@ continue
	fabs	rva, sv1
	eq	rva, #f0
	it	eq
	seteq	sv1, #f0
	fabs	rva, sv2
	eq	rva, #f0
	it	eq
	seteq	sv2, #f0
	swap	sv1, sv3, rva		@ sv1 <- imag( sqrt(1 - z^2) ), sv3 <- (-/+) y
	bl	plsflt			@ sv1 <- (+/-) x + imag( sqrt(1 - z^2) )
	swap	sv1, sv3, rva		@ sv1 <- (-/+) y, sv3 <- (+/-) x + imag( sqrt(1 - z^2) )
	set	sv2, sv4		@ sv2 <- real( sqrt(1 - z^2) )
	bl	plsflt			@ sv1 <- (-/+) y + real( sqrt(1 - z^2) )
	set	sv2, sv3		@ sv2 <- (+/-) x + imag( sqrt(1 - z^2) )
	bl	makcpx			@ sv1 <- (+/-) i z + sqrt(1 - z^2)
	save	sv5			@ dts <- (sign cnt ...)
	ldr	rvc, =logtb
	call	numjmp			@ sv1 <- log( (+/-) i z + sqrt(1 - z^2) )
	restor2	sv5, cnt		@ sv5 <- sign, cnt <- cnt, dts <- (...)
	floatp	sv1
	beq	asncp2
	spltcpx	sv2, sv1, sv1		@ sv2 <- real( log( (+/-) i z + sqrt(1 - z^2) ) )
					@ sv1 <- imag( log( (+/-) i z + sqrt(1 - z^2) ) )
	eq	sv5, #t
	itE	eq
	ngflteq	sv2, sv2		@	if so,  sv2 <- -real( log( (+/-) i z + sqrt(1 - z^2) ) )
	ngfltne	sv1, sv1		@	if not, sv1 <- -imag( log( (+/-) i z + sqrt(1 - z^2) ) )
	fabs	sv3, sv2
	eq	sv3, #f0
	it	eq
	seteq	sv2, #f0
	set	lnk, cnt		@ lnk <- cnt
	b	makcpx			@ sv1 <- log( i z + sqrt(1 - z^2) ) / i
asncp2:	@ purely imaginary argument
	eq	sv5, #t
	itE	eq
	ngflteq	sv2, sv1		@	if so,  sv2 <- -log( i z + sqrt(1 - z^2) )
	setne	sv2, sv1		@	if not, sv2 <-  log( i z + sqrt(1 - z^2) )
	set	sv1, #f0		@ sv1 <- 0.0
	set	lnk, cnt		@ lnk <- cnt
	b	makcpx			@ sv1 <- log( i z + sqrt(1 - z^2) ) / i
	

acos:	@ (acos z)
	sav__c				@ dts <- (cnt ...)
	ldr	rvc, =asintb
	call	numjmp
	restor	cnt
	set	sv2, sv1
	ldr	sv1, =scheme_half_pi	@ sv1 <- pi/2
	set	lnk, cnt
	b	unimns


_func_
pifxt:	@ exit with pi
	ldr	sv1, =scheme_pi		@ sv1 <- pi
	set	pc,  cnt
	
_func_
p2fxt:	@ exit with pi/2
	ldr	sv1, =scheme_half_pi	@ sv1 <- pi/2
	set	pc,  cnt
	
_func_
np2fxt:	@ exit with -pi/2
	ldr	sv1, =scheme_half_pi	@ sv1 <- pi/2
	ngflt	sv1, sv1
	set	pc,  cnt
	
_func_	
atnint:	@ atan for int
_func_	
atnrat:	@ atan for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to atnflt
	
_func_	
atnflt:	@ atan for flt
	nullp	sv2
	it	eq
	ldreq	sv2, =scheme_one	@	if not, sv2 <- 1.0 (x as scheme_float)
	nmbrp	sv2			@ is sv2 a number?
	bne	nanfxt
	bl	uninum			@ sv1 <- y (scheme float), sv2 <- x (scheme float)
	floatp	sv2			@ is sv2 a float (eg. rather than cpx)?
	bne	corerr
	set	sv3, #f0
	postv	sv1
	it	ne
	orrne	sv3, sv3, #4
	postv	sv2
	it	ne
	orrne	sv3, sv3, #8
	bl	divflt			@ sv1 <- arg == y / x
	eq	sv1, #f0		@ is arg = 0.0?
	it	eq
	tsteq	sv3, #8			@	if so,  was x positive?
	it	eq
	seteq	pc,  cnt		@	if so,  exit with 0.0
	ldr	sv5, =atnspc		@ sv5 <- special values jump table
	bl	spcflt			@ exit with value if sv1 = 0, +/-inf or nan
	fabs	sv1, sv1		@ sv1 <- absolute value of arg
	ldr	sv2, =scheme_one	@ sv2 <- 1.0
	cmp	sv2, sv1		@ is arg > 1.0 ?
	itT	mi
	orrmi	sv3, sv3, #16		@	if so,  sv3 <- quadrant updated with inversion flag
	swapmi	sv1, sv2, sv4		@	if so,  sv1 <- 1.0,  sv2 <- arg (sv4 used as temp)
	it	mi
	blmi	divflt			@	if so,  sv1 <- 1.0/arg
	set	sv5, sv3		@ sv5 <- quadrant	(saved)
	set	sv4, sv1		@ sv4 <- arg		(saved)
	set	sv2, sv1		@ sv2 <- arg
	bl	prdflt			@ sv1 <- arg**2
	save3	sv4, sv5, cnt
	set	sv4, sv1
	ldr	sv3, =atntsc		@ sv3 <- address of Taylor series coefficients
	call	taylor			@ sv1 <- result = coeff + arg * (coeff + arg * (coeff + ...
	restor3	sv2, sv3, cnt
	@ post-processing
	bl	prdflt			@ sv1 <- angle = arg*result
	tst	sv3, #16		@ was tangent inverted?
	itTT	ne
	ngfltne	sv1, sv1		@	if so,  sv1 <- -angle
	ldrne	sv2, =scheme_half_pi	@	if so,  sv2 <- pi/2
	blne	plsflt			@	if so,  sv1 <- pi/2 - angle
	tst	sv3, #8			@ is x negative?
	itTT	ne
	orrne	sv1, sv1, #0x80000000	@	if so,  sv1 <- -angle
	ldrne	sv2, =scheme_pi		@	if so,  sv2 <- pi
	blne	plsflt			@	if so,  sv1 <- pi - angle
	tst	sv3, #4			@ is y negative?
	it	ne
	ngfltne	sv1, sv1		@	if so,  sv1 <- -angle
	set	pc,  cnt

_func_	
atncpx:	@ atan of complex
	sav_rc	sv1			@ dts <- (z cnt ...)
	imag	sv2, sv1		@ sv2 <- y
	ldr	sv1, =scheme_one	@ sv1 <- 1.0
	bl	plsflt			@ sv1 <- 1 + y
	car	sv2, dts		@ sv2 <- z
	real	sv2, sv2		@ sv2 <- x
	eq	sv2, #f0		@ <- don't negate real part if zero, it results in bad complex num.
					@    both makcpx and ngflt could/should account for this
	it	ne
	ngfltne	sv2, sv2		@	if not, sv2 <- -x
	bl	makcpx			@ sv1 <- 1 - i z = 1 + y - i x
	ldr	rvc, =logtb
	call	numjmp			@ sv1 <- log(1 - i z)
	restor	sv4			@ sv4 <- z,		dts <- (cnt ...)
	save	sv1			@ dts <- (log(1 - i z) cnt ...)
	imag	sv2, sv4		@ sv2 <- y
	ldr	sv1, =scheme_one	@ sv1 <- 1.0
	bl	mnsflt			@ sv1 <- 1 - y
	real	sv2, sv4		@ sv2 <- x
	bl	makcpx			@ sv1 <-  1 + i z = 1 - y + i x
	ldr	rvc, =logtb
	call	numjmp			@ sv1 <- log(1 + i z)
	restor	sv2			@ sv2 <- log(1 - i z),	dts <- (cnt ...)
	bl	unimns			@ sv1 <- log(1 + i z) - log(1 - i z)	
	set	sv2, #9			@ sv2 <- 2 (scheme int)
	bl	uninum
	restor	cnt			@ cnt <- cnt,		dts <- (...)
	floatp	sv1
	beq	atncp2
	bl	divcpx
	spltcpx	sv2, sv1, sv1
	ngflt	sv2, sv2
	set	lnk, cnt
	b	makcpx
atncp2:	@ purely imaginary argument
	bl	divflt
	ngflt	sv2, sv1
	set	sv1, #f0
	set	lnk, cnt
	b	makcpx
	

_func_	
ziifxt:	@ exit with 0.0 + inf.i
	set	sv1, #f0
	ldr	sv2, =scheme_inf		@ sv2 <- inf (scheme float)
	set	lnk, cnt
	b	makcpx

_func_	
sqrint:	@ sqrt for int
_func_	
sqrrat:	@ sqrt for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to sqrflt
	
_func_	
sqrflt:	@ sqrt for flt
	ldr	sv5, =sqrspc		@ sv5 <- special values jump table
	bl	spcflt			@ exit with value if sv1 = 0, +/-inf or nan
	@ continue to sqrcpx
	
_func_	
sqrcpx:	@ sqrt for cpx
	sav_rc	sv1			@ dts <- (z cnt ...)
	ldr	rvc, =logtb
	call	numjmp			@ sv1 <- log(z)
	ldr	sv2, =scheme_0p5	@ sv2 <- 0.5
	bl	uniprd			@ sv1 <- 0.5*log(z)
	ldr	rvc, =exptb
	call	numjmp			@ sv1 <- sqrt(z)	
	set	sv4, sv1		@ sv4 <- sqrt(z)
	set	sv2, sv1		@ sv2 <- sqrt(z)
	restor2	sv1, cnt		@ sv1 <- z, cnt <- cnt, dts <- (...)
	@ refinement
	bl	unidiv			@ sv1 <- z / sqrt(z)
	set	sv2, sv4		@ sv2 <- sqrt(z)
	bl	unipls			@ sv1 <- sqrt(z) + z / sqrt(z)
	ldr	sv2, =scheme_two	@ sv2 <- 2.0
	set	lnk, cnt
	b	unidiv			@ sv1 <- [sqrt(z) + z / sqrt(z)] / 2


expt:	@ (expt z1 z2)
	intgrp	sv2
	beq	exptnt
	nmbrp	sv2
	bne	corerr
	isnan	sv2
	beq	corerr
	ldr	sv3, =scheme_one	@ sv3 <- 1.0
	eq	sv1, sv3		@ is z1 = 1.0?
	it	ne
	eqne	sv1, #5			@	if not, is z1 = 1?
	it	ne
	eqne	sv2, sv3		@	if not, is z2 = 1.0?
	it	ne
	eqne	sv2, #5			@	if not, is z1 = 1?
	it	eq
	seteq	pc,  cnt		@	if so,  exit with z1
	anyzro	sv1, sv2		@ is z1 or z2 = 0 or 0.0?
	beq	exptzr			@	if so,  jump to that case
	anyinf	sv1, sv2		@ is z1 or z2 = +/- inf?
	beq	exptnn			@	if so,  jump to that case
exptrg:	@
	@ to do:
	@ check if z2 is an integer when z1 < 0, otherwise, z1 < 0 => nan through log (complex number)
	@ --> split z1 into integer and fractional part and process expt accordingly, skipping log if
	@ fractional part is zero
	@
	sav_rc	sv2			@ dts <- (z2 cnt ...)
	ldr	rvc, =logtb
	call	numjmp			@ sv1 <- log(z1)
	restor2	sv2, cnt		@ sv2 <- z2, cnt <- cnt, dts <- (...)
	bl	uniprd			@ sv1 <- z2*log(z1),		returns via lnk
	ldr	sv5, =exptb
	b	unijmp			@ sv1 <- exp(z2*log(z1)),	returns via cnt

exptzr:	@ expt with z1 or z2 = 0
	zerop	sv2			@ is z2 = 0?
	itT	eq
	seteq	sv1, sv3		@	if so,  sv1 <- 1.0
	seteq	pc,  cnt		@	if so,  exit with 1.0
	postv	sv2			@ is z2 positive?
	bne	infxt	
	set	pc,  cnt		@ exit with 0, 0.0 or inf
exptnn:	@ expt with z1 or z2 = nan
	postv	sv2			@ is z2 positive?
	beq	exptpn			@	if so,  jump to process positive exponent
	cmp	sv1, sv3		@ is z1 > 1?
	bpl	f0fxt
	postv	sv1			@ is z1 > 0?
	beq	infxt
	b	nanfxt
exptpn:	cmp	sv1, sv3		@ is z1 > 1?
	bpl	infxt
	postv	sv1			@ is z1 >= 0?
	beq	f0fxt
	b	nanfxt

exptnt:	@ expt when z2 is an integer
	set	sv4, sv2
	postv	sv4
	beq	exptn0
	iabs	sv4, sv4
	set	sv2, sv1
	ldr	sv1, =scheme_one
	bl	unidiv
exptn0:	
	save	sv1
	set	sv1, #5	
exptn1:	@ loop
	eq	sv4, #i0
	itT	eq
	cdreq	dts, dts
	seteq	pc,  cnt
	sub	sv4, sv4, #4
	car	sv2, dts
	adr	lnk, exptn1
	b	uniprd


@-------------------------------------------------------------------------------
@ dump literal constants (up to 4K of code before and after this point)
@-------------------------------------------------------------------------------
.ltorg


_func_	
mrcint:	@ make-rectangular for int
_func_	
mrcrat:	@ make-rectangular for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to mrcflt
	
_func_	
mrcflt:	@ make-rectangular for flt
	bl	uninum
	floatp	sv1
	bne	corerr
	set	lnk, cnt
	b	makcpx


_func_	
mpoint:	@ make-polar for int
_func_	
mporat:	@ make-polar for rat
	bl	ir12fl			@ sv1 <- scheme float from scheme int or rational in sv1
	@ continue to mpoflt
	
_func_	
mpoflt:	@ make-polar for flt
	bl	uninum
	floatp	sv1
	bne	corerr
	save3	sv2, sv1, cnt		@ dts <- (x4 x3 cnt ...)
	set	sv1, sv2		@ sv1 <- x4
	call	sinflt			@ sv1 <- sin(x4)
	restor	sv2			@ sv2 <- x4
	save	sv1			@ dts <- (sin(x4) x3 cnt ...)
	set	sv1, sv2		@ sv1 <- x4
	call	cosflt			@ sv1 <- cos(x4)
	restor	sv2			@ sv2 <- sin(x4),	dts <- (x3 cnt ...)
	bl	makcpx			@ sv1 <- cos(x4) + i sin(x4)
	set	sv2, sv1		@ sv2 <- cos(x4) + i sin(x4)
	restor2	sv1, cnt		@ sv1 <- x3, cnt <- cnt, dts <- (...)
	set	lnk, cnt		@ lnk <- cnt
	b	uniprd


_func_	
rptcpx:	@ real-part for cpx
	real	sv1, sv1
	set	pc,  cnt


_func_	
imgcpx:	@ imag-part for cpx
	imag	sv1, sv1
	set	pc,  cnt


_func_	
absint:	@ abs for int
	iabs	sv1, sv1
	set	pc,  cnt
	
_func_	
absflt:	@ abs for flt
	fabs	sv1, sv1
	set	pc,  cnt
	
_func_	
absrat:	@ abs for rat
	spltrat	sv1, sv2, sv1		@ sv1 <- numerator, sv2 <- denominator
	iabs	sv1, sv1
	set	lnk, cnt
	b	makrat
	
_func_	
magcpx:	@ magnitude for cpx
	spltcpx	sv1, sv4, sv1		@ sv1 <- real part, sv4 <- imag part
	set	sv2, sv1		@ sv2 <- x
	bl	prdflt			@ sv1 <- x^2
	set	sv5, sv1		@ sv5 <- x^2, saved
	set	sv1, sv4		@ sv1 <- y
	set	sv2, sv1		@ sv2 <- y
	bl	prdflt			@ sv1 <- y^2
	set	sv2, sv5		@ sv2 <- x^2
	bl	plsflt			@ sv1 <- magnitude(z)^2
	b	sqrflt			@ sv1 <- magnitude(z), return via cnt


_func_	
angrat:	@ angle for rat
	numerat	sv1, sv1
_func_	
angint:	@ angle for int
_func_	
angflt:	@ angle for flt
	postv	sv1
	itE	eq
	seteq	sv1, #f0
	ldrne	sv1, =scheme_pi
	set	pc,  cnt
	
_func_	
angcpx:	@ angle for cpx
	spltcpx	sv2, sv1, sv1		@ sv2 <- real part, sv1 <- imag part
	b	atnflt

@-------------------------------------------------------------------------------
@ dump literal constants (up to 4K of code before and after this point)
@-------------------------------------------------------------------------------
.ltorg


ex2inx:	@ (exact->inexact z)
	@ on entry:	sv1 <- z
	@ on exit:	sv1 <- inexact version of z
	@ modifies:	sv1, rva
	set	sv2, #f0		@ sv2 <- float zero
	set	lnk, cnt
	b	uninum
	

_func_
i2eflt:	@ inexact->exact for flt
	bl	flt2ndn			@ sv1 <- numerator (int), sv2 <- denominator (int)
	set	lnk, cnt
	b	makrat
	
@-------------------------------------------------------------------------------
@ dump literal constants (up to 4K of code before and after this point)
@-------------------------------------------------------------------------------
.ltorg

/*------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.2.   Numbers
@  II.A.6.2.5  Numerical operations SUPPORT:	uninum, fltmte, mteflt
@-----------------------------------------------------------------------------*/

_func_
infxt:	@ exit with inf
	ldr	sv1, =scheme_inf
	set	pc,  cnt		@ return

_func_
i0fxt:	@ exit with 0
	set	sv1, #i0
	set	pc,  cnt		@ return

_func_
f0fxt:	@ exit with 0.0
	set	sv1, #f0
	set	pc,  cnt		@ return

_func_
f1fxt:	@ exit with 1.0
	ldr	sv1, =scheme_one
	set	pc,  cnt		@ return

_func_
nanfxt:	@ exit with nan
	ldr	sv1, =scheme_nan
	set	pc,  cnt
	
_func_
nanlxt:	@ exit with nan, via lnk
	ldr	sv1, =scheme_nan
	set	pc,  lnk


_func_	
numgto:	@ jump to function in address table based on object type (for paptbl:)
	set	rvc, sv5
_func_	
numjmp:	@ jump to function in address table based on object type
	@ on entry:	sv1 <-	object (hopefully a number)
	@ on entry:	rvc <-	table start address
	@ on entry:		offsets: 0, 4, 8, 12, 16 for nan, int, flt, rat, cpx
	ands	rva, sv1, #3
	it	ne
	eqne	rva, #3
	it	ne
	ldrne	pc,  [rvc, rva, lsl #2]
	@ rat/cpx or nan
	and	rvb, sv1, #0x07
	eq	rvb, #0x04
	itTT	eq
	ldrbeq	rvb, [sv1, #-4]
	andeq	rva, rvb, #0x07
	eqeq	rva, #3			@ rat/cpx?
	itTT	eq
	andeq	rva, rvb, #0x0C
	addeq	rva, rvc, rva, lsr #1
	ldreq	pc,  [rva, #12]
	ldr	pc,  [rvc]		@ error, pointer is not rat/cpx


_func_	
prdnml:	@ reduce the list of numbers in sv1 using pred in sv5 (oprts on sv1, sv2) and dflt rslt in sv4
	sav__c				@ dts <- (cnt ...)
	call	rdcnml			@ sv1 <- reduction-result
	restor	cnt			@ cnt <- cnt, dts <- (...)
	isnan	sv1			@ is reduction-result nan?
	it	ne
	eqne	sv1, #f			@	if not, is reduction-result = #f?
	b	notfxt			@ return with #f/#t based on test result

_func_	
rdcnml:	@ reduce the list of numbers in sv1 using operator in sv5 (oprts on sv1, sv2) and dflt rslt in sv4
	@ on entry:	sv1 <- (arg1 ...)
	@ on entry:	sv4 <- default-result
	@ on entry:	sv5 <- operator
	@ on exit:	sv1 <- result
	nullp	sv1			@ are there no arguments?
	itT	ne
	cdrne	sv2, sv1		@	if not, sv2 <- (num2 ...)
	nullpne	sv2			@	if not, is there only one argument?
	itT	ne
	carne	sv4, sv1		@	if not, sv4 <- num1 = updated startup value
	setne	sv1, sv2		@	if not, sv1 <- (num2 ...) = updated list of numbers
	it	eq
	eqeq	sv4, #t			@	if so,  was starting value #t?
	itT	eq
	seteq	sv1, sv4		@		if so,  sv1 <- #t
	seteq	pc,  cnt		@		if so,  exit with #t
	set	sv2, sv1		@ sv2 <- '() if 0 args, (num1) if 1 arg or (num2 ...) if > 1 arg
	set	sv1, sv4		@ sv1 <- default result if <= 1 arg or num1 if > 1 arg
	set	sv4, sv2		@ sv4 <-  '() if 0 args, (num1) if 1 arg or (num2 ...) if > 1 arg
	nmbrp	sv1
	bne	nanfxt			@	if not, exit with nan
	adr	lnk, rdcncn		@ lnk <- return from operator
_func_	
rdcncn:	@ reduction loop
	@ on entry:	sv1 <- current/default result
	@ on entry:	sv4 <- list of numbers
	@ on entry:	sv5 <- jump table of function to apply to pairs of numbers
	@ preserves:	sv5    (function called needs to preserve sv4, sv5)
	nullp	sv4			@ is (num1 num2 ...) null?
	it	ne
	eqne	sv1, #f			@	if not, is sv1 = #f
	it	eq
	seteq	pc,  cnt		@	if so,  exit with result in sv1
	snoc	sv2, sv4, sv4		@ sv2 <- num1,	sv4 <- (num2 ...)
	b	unijmp

_func_
makrat:	@ build rational from scheme ints in sv1 (numer) and sv2 (denom)
	@ on entry:	sv1 <- numerator   (scheme int)
	@ on entry:	sv2 <- denominator (scheme int)
	@ on exit:	sv1 <- rational, or int if sv2 = 1
	@ modifies:	sv1-sv3, rva-rvc
	@ check if denominator is zero
	izerop	sv2			@ is denominator = 0?
	bne	makra0			@	if not, jump to normal case
	@ denominator is zero:	0/0 or n/0
	izerop	sv1			@ is numerator = 0?
	beq	int2rat			@	if so,  jump to build rat
	postv	sv1			@ is numerator positive?
	set	sv1, #5			@ sv1 <- 1 (scheme int)
	it	ne
	ngintne	sv1, sv1		@	if not, sv1 <- -1 (scheme int)
	b	int2rat			@ jump to build rat
makra0:	@ non-zero denominator	
	@ check if denominator is negative:	m/-n  ->  -m/n
	postv	sv2			@ is denominator positive?
	it	ne
	ngintne	sv1, sv1		@	if not, sv1 <- minus numerator
	it	ne
	ngintne	sv2, sv2		@	if not, sv2 <- minus denominator
	@ check simple cases:	 0/n and n/1
	eq	sv1, #i0		@ is numerator = 0?
	it	ne
	eqne	sv2, #i1		@	if not, is denominator = 1?
	it	eq
	seteq	pc,  lnk		@	if either, return with numerator
	@ simplify the fraction
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv2, sv1, sv3
	bl	igcd			@ sv1 <- greatest common divisor of numerator and denominator
	set	sv3, sv1		@ sv3 <- gcd, saved
	set	sv2, sv1		@ sv2 <- gcd
	restor	sv1			@ sv1 <- denominator
	bl	idivid			@ sv1 <- simplified denominator
	set	sv2, sv3		@ sv2 <- gcd
	set	sv3, sv1		@ sv3 <- simplified denominator
	restor	sv1			@ sv1 <- numerator
	bl	idivid			@ sv1 <- simplified numerator
	set	sv2, sv3		@ sv2 <- simplified denominator
	restor	sv3
	orr	lnk, sv3, #lnkbit0
	eq	sv2, #i1		@ is simplified fraction denominator = 1?
	it	eq
	seteq	pc,  lnk		@	if so,  return with simplified numerator
_func_
int2rat: @ int -> rat
	@ on entry:	sv1 <- integer
	@ on entry:	sv2 <- integer (1, as scheme int, when called by uninum)
	@ on exit:	sv1 <- rational
	@ modifies:	sv1, sv3, rva, rvb, rvc
	int2rat	sv1, sv1, sv2
	set	pc,  lnk	


.balign	4
_func_
makcpx:	@ build complex from scheme floats in sv1 (real) and sv2 (imag)
	@ on entry:	sv1 <- real part      (scheme float)
	@ on entry:	sv2 <- imaginary part (scheme float)
	@ on exit:	sv1 <- complex, or float if sv2 = 0.0
	eq	sv2, #f0
	it	eq
	seteq	pc,  lnk
_func_
flt2cpx: @ float -> cpx
	@ on entry:	sv1 <- float
	@ on entry:	sv2 <- float (0, as scheme float, when called by uninum)
	@ on exit:	sv1 <- complex
	@ modifies:	sv1, sv3, rva, rvb, rvc
	flt2cpx	sv1, sv1, sv2
	set	pc,  lnk	


_func_
igcd:	@ on entry:	sv1 <- scheme int
	@ on entry:	sv2 <- scheme int
	@ on exit:	sv1 <- gcd of sv1 and sv2 (scheme int)
	@ modifies:	sv1-sv3, rva-rvc
	bic	sv3, lnk, #lnkbit0	@ sv5 <- lnk, saved (and made even if Thumb2)
	save	sv3
	set	sv3, sv1
	adr	lnk, igcdl
_func_
igcdl:	@ igcd loop
	izerop	sv2
	itT	ne
	setne	sv1, sv3
	setne	sv3, sv2		@ sv3 <- int2 (saved against idivid -- will become int1)
	bne	idivid			@ sv1 <- quotient, sv2 <- remainder -- will become int2
	@ igcd exit
	iabs	sv1, sv3
	restor	sv3
	orr	lnk, sv3, #lnkbit0
	set	pc,  lnk
	

_func_
flt2ndn:	@ common entry for numerator and denominator
	@ used also in inexact->exact, rationalize
	@ on entry:	sv1 <- float
	@ on exit:	sv1 <- float's numerator   (scheme int)
	@ on exit:	sv2 <- float's denominator (scheme int)
	@ modifies:	sv1, sv2, sv3, rva, rvb, rvc
	@ check for 0.0, nan and inf
	eq	sv1, #f0
	itTT	eq
	seteq	sv1, #i0
	seteq	sv2, #i1
	seteq	pc,  lnk
	isnan	sv1
	itTT	eq
	seteq	sv1, #i0
	seteq	sv2, #i0
	seteq	pc,  lnk
	isinf	sv1
	bne	nmdne0
	postv	sv1			@ is number positive?
	set	sv1, #i1		@ sv1 <- 1 (scheme int)
	it	ne
	ngintne	sv1, sv1		@	if not, sv1 <- -1 (scheme int)
	set	sv2, #i0
	set	pc,  lnk
nmdne0:	@ normal cases	
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	bl	fltmte			@ sv1 <- mantissa, rva <- biased exponent
	cmp	rva, #156
	bmi	nmdne1
	eq	rva, #156
	itT	eq
	lsleq	rvb, sv1, #9
	eqeq	rvb, #0x0200
	bne	corerr
	postv	sv1
	itTEE	eq
	mvneq	rvb, #0
	biceq	rvb, rvb, #0xE0000000
	setne	rvb, #0xE0000000
	orrne	rvb, rvb, #1
	raw2int	sv1, rvb
	set	sv2, #i1
	b	nmdnxt
nmdne1:	@
	cmp	rva, #148
	bmi	nmdne2
	sub	rva, rva, #148
	bic	rvb, sv1, #3
	lsl	rvb, rvb, rva
	orr	sv1, rvb, #int_tag
	set	sv2, #i1
	b	nmdnxt
nmdne2:	@
	cmp	rva, #127
	bmi	nmdne4
	rsb	rva, rva, #148
	set	rvb, #1
	lsl	rvb, rvb, rva
	raw2int	sv2, rvb
	save3	sv2, sv1, sv3		@ dts <- (denom numer lnk ...)
	bl	igcd
	set	sv2, sv1
	restor	sv1			@ sv1 <- denom, dts <- (numer lnk ...)
	save	sv2			@ dts <- (gcd numer lnk ...)
	bl	idivid			@ sv1 <- denom/gcd
	set	sv3, sv1
	restor2	sv2, sv1		@ sv2 <- gcd, sv1 <- numer, dts <- (lnk ...)
	save	sv3			@ dts <- (denom/gcd lnk ...)
	bl	idivid			@ sv1 <- numer/gcd
	restor2	sv2, sv3		@ sv2 <- denom/gcd, sv3 <- lnk, dts <- (...)
	b	nmdnxt
nmdne4:	@
	bl	mteflt
	set	sv2, sv1
	ldr	sv1, =scheme_one
	save	sv3
	bl	divflt
	bl	flt2ndn
	swap	sv1, sv2, sv3
	restor	sv3
	postv	sv2
	it	ne
	ngintne	sv1, sv1
	it	ne
	ngintne	sv2, sv2
nmdnxt:	@ exit	
	orr	lnk, sv3, #lnkbit0
	set	pc,  lnk

_func_	
unipls:	@ uniformize numbers in sv1, sv2, then do: plus
	ldr	sv5, =plustb
	b	unijmp

_func_	
unimns:	@ uniformize numbers in sv1, sv2, then do: minus
	ldr	sv5, =minutb
	b	unijmp

_func_	
uniprd:	@ uniformize numbers in sv1, sv2, then do: prod
	ldr	sv5, =prodtb
	b	unijmp

_func_	
unidiv:	@ uniformize numbers in sv1, sv2, then do: divi
	ldr	sv5, =divitb
	b	unijmp

_func_	
uninum:	@ [entry]
	ldr	sv5, =unirtb
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, to avoid a jump
_func_
unijrt:	@ [return address]
	orr	lnk, sv3, #lnkbit0	@ lnk <- lnk, restored
_func_
unijmp:	@ [entry]
	@ makes sv1 (x1) and sv2 (x2) either both scheme ints or both scheme floats
	@ modifies:	sv1-sv3, rva-rvc
	ands	rva, sv1, #3
	beq	unij1p
	eq	rva, #3
	beq	unijer
	ands	rvb, sv2, #3
	beq	unij2p
	eq	rvb, #3
	beq	unijer
	@ x1 is int/flt, x2 is int/flt
	eq	rva, rvb
	it	eq
	ldreq	pc,  [sv5, rva, lsl #2]
	orr	rva, rva, #0x01
	lsl	rva, rva, #1
	b	unij4p
unij1p:	@ x1 is rat/cpx
	ldrb	rva, [sv1, #-4]
	and	rva, rva, #0x0f
	and	rvc, rva, #0x07
	eq	rvc, #3
	bne	unijer
	ands	rvb, sv2, #3
	bne	unij3p
	@ x1 is rat/cpx, x2 is rat/cpx
	ldrb	rvb, [sv2, #-4]
	and	rvb, rvb, #0x0f
	and	rvc, rvb, #0x07
	eq	rvc, #3
	bne	unijer
	eq	rva, rvb
	itTTT	eq
	andeq	rva, rva, #0x0c
	lsreq	rva, rva, #1
	addeq	rva, rva, #12
	ldreq	pc,  [sv5, rva]
	eor	rva, rva, #0x08
	lsr	rva, rva, #1
	b	unij4p
unij2p:	@ x1 is int/flt, x2 is rat/cpx
	ldrb	rvb, [sv2, #-4]
	and	rvb, rvb, #0x0f
	and	rvc, rvb, #0x07
	eq	rvc, #3
	bne	unijer
	add	rvc, rva, rvb, lsr #2
	sub	rva, rvc, #1
	b	unij4p
unij3p:	@ x1 is rat/cpx, x2 is int/flt
	eq	rvb, #3
	beq	unijer
	add	rvc, rvb, rva, lsr #2
	add	rva, rvc, #3
unij4p:	@ continue
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	ldr	lnk, =unijrt
	ldr	rvc, =unijtb
	ldr	pc,  [rvc, rva, lsl #2]

unijer:	@ non-number encountered
	ldr	pc,  [sv5]


_func_
lnklnk:	@ return via lnk	
	set	pc, lnk

.ifdef	hardware_FPU

_func_
ir12fl:	@ convert scheme int or rat in sv1 to a float (return via lnk)
	@ input:	sv1	scheme int or rational
	@ output:	sv1	scheme float
	@ modifies:	sv1, rva, rvb
	pntrp	sv1
	beq	r12flt
	@ continue to i12flt
	
_func_
i12flt:	@ convert scheme int in sv1 to a float
	@ input:	sv1	scheme int
	@ output:	sv1	scheme float
	@ modifies:	sv1, rva
	int2raw	rva, sv1
  .ifndef FPU_is_maverick
	vmov	s0, rva
	vcvt.f32.s32	s0,  s0
	vmov	rva, s0
  .else
	cfmv64lr mvdx0, rva
	cfcvt32s mvf0, mvfx0
	cfmvrs	rva, mvf0
  .endif
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  lnk
	
_func_
i22flt:	@ convert scheme int in sv2 to a float
	@ input:	sv2	scheme int
	@ output:	sv2	scheme float
	@ modifies:	sv2, rva
	int2raw	rva, sv2
  .ifndef FPU_is_maverick
	vmov	s0, rva
	vcvt.f32.s32	s0,  s0
	vmov	rva, s0
  .else
	cfmv64lr mvdx0, rva
	cfcvt32s mvf0, mvfx0
	cfmvrs	rva, mvf0
  .endif
	bic	rva, rva, #0x03
	orr	sv2, rva, #f0
	set	pc,  lnk
	
_func_
r12flt: @ convert rational in sv1 to float
	@ on entry:	sv1 <- rational
	@ on exit:	sv1 <- float
	@ modifies:	sv1, rva, rvb

  .ifndef FPU_is_maverick

	rawsplt	rva, rvb, sv1
	lsr	rva, rva, #2
	bic	rva, rva, #3
	orr	rva, rva, rvb, lsl #30
	bic	rvb, rvb, #3
	vmov	s0, s1, rva, rvb
	vcvt.f32.s32	s0, s0
	vcvt.f32.s32	s1, s1
	vdiv.f32	s0, s0, s1	
	vmov	rva, s0	
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  lnk

  .else		@ FPU_is_maverick

	@ maverick crunch has no division, use code from non_FPU version
	cfmv64lr mvdx0, rvc		@ use FPU reg to save rvc
	cfmv64lr mvdx1, lnk		@ use FPU reg to save lnk
	save	sv2
	bl	rat2fl
	restor	sv2
	cfmvr64l rvc, mvdx0
	cfmvr64l lnk, mvdx1
	set	pc,  lnk
	
_func_
rat2fl: @ helper function
	@ modifies:	sv1, sv2, rva, rvb, rvc
	rawsplt	rva, rvb, sv1
	lsr	rva, rva, #2
	bic	rva, rva, #3
	orr	rva, rva, rvb, lsl #30
	bic	rvb, rvb, #3
	orr	sv1, rva, #int_tag
	orr	sv2, rvb, #int_tag
	izerop	sv2
	beq	divzro
	set	rva, #148		@ rva <- biased exponent of dividand
	b	divnrm			@ sv1 <- sv1/sv2 as float, returns via lnk

  .endif	@ FPU_is_maverick
	
_func_
r22flt: @ convert rational in sv2 to float
	@ on entry:	sv2 <- rational
	@ on exit:	sv2 <- float
	@ modifies:	sv2, rva, rvb
	swap	sv1, sv2, rva
	bl	r12flt
	swap	sv1, sv2, rva
	b	unijrt

.else	@ no hardware FPU
	
_func_
ir12fl:	@ convert scheme int or rat in sv1 to a float (return via lnk)
	@ input:	sv1	scheme int or rational
	@ output:	sv1	scheme float
	@ modifies:	sv1, sv4, sv5, rva, rvb, rvc
	pntrp	sv1
	beq	r12fln
	@ continue to i12flt
	
_func_
i12flt:	@ convert scheme int in sv1 to a float
	@ input:	sv1	scheme int	signed 'in-place' mantissa
	@ output:	sv1	scheme float
	@ modifies:	sv1, rva, rvb, rvc
	set	rva, #148
	b	mteflt
	
_func_
i22flt:	@ convert scheme int in sv2 to a float
	@ input:	sv1	scheme int	signed 'in-place' mantissa
	@ output:	sv1	scheme float
	@ modifies:	sv1, rva, rvb, rvc
	swap	sv1, sv2, rvc
	set	rva, #148
	bl	mteflt
	swap	sv1, sv2, rvc
	b	unijrt
	
_func_
r12flt: @ convert rational in sv1 to float
	@ on entry:	sv1 <- rational
	@ on exit:	sv1 <- float
	@ modifies:	sv1, rva, rvb, rvc
	save	sv2
	bl	rat2fl
	restor	sv2
	b	unijrt
	
_func_
r12fln: @ convert rational in sv1 to float
	@ on entry:	sv1 <- rational
	@ on exit:	sv1 <- float
	@ modifies:	sv1, sv4, sv5, rva, rvb, rvc
	@ returns via:	lnk
	set	sv4, sv2
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved (and made even if Thumb2)
	bl	rat2fl
	orr	lnk, sv5, #lnkbit0	@ lnk <- lnk, restored
	set	sv2, sv4
	set	pc,  lnk
	
_func_
r22flt: @ convert rational in sv2 to float
	@ on entry:	sv2 <- rational
	@ on exit:	sv2 <- float
	@ modifies:	sv2, rva, rvb, rvc
	swap	sv1, sv2, rvc
	save	sv2
	bl	rat2fl
	restor	sv2
	swap	sv1, sv2, rvc
	b	unijrt

_func_
rat2fl: @ helper function
	@ modifies:	sv1, sv2, rva, rvb, rvc
	rawsplt	rva, rvb, sv1
	lsr	rva, rva, #2
	bic	rva, rva, #3
	orr	rva, rva, rvb, lsl #30
	bic	rvb, rvb, #3
	orr	sv1, rva, #int_tag
	orr	sv2, rvb, #int_tag
	izerop	sv2
	beq	divzro
	set	rva, #148		@ rva <- biased exponent of dividand
	b	divnrm			@ sv1 <- sv1/sv2 as float, returns via lnk

.endif	@ yes/no hardware FPU
		
_func_
i12rat:	@ convert scheme int in sv1 to a rational
	@ input:	sv1	scheme int
	@ output:	sv1	scheme rational
	@ modifies:	sv1, rva, rvb, rvc
	save2	sv2, sv3
	set	sv2, #i1		@ sv2 <- 1 as scheme int
	bl	int2rat
	restor2	sv2, sv3
	b	unijrt
	
_func_
i22rat:	@ convert scheme int in sv2 to a rational
	@ input:	sv2	scheme int
	@ output:	sv2	scheme rational
	@ modifies:	sv1, rva, rvb, rvc
	save2	sv1, sv3
	set	sv1, sv2
	set	sv2, #i1		@ sv2 <- 1 as scheme int
	bl	int2rat
	set	sv2, sv1
	restor2	sv1, sv3
	b	unijrt
	
_func_
f12cpx:	@ convert scheme float in sv1 to a complex
	@ input:	sv1	scheme int
	@ output:	sv1	scheme rational
	@ modifies:	sv1, rva, rvb, rvc
	save2	sv2, sv3
	set	sv2, #f0		@ sv2 <- 0 as scheme float
	bl	flt2cpx
	restor2	sv2, sv3
	b	unijrt
	
_func_
f22cpx:	@ convert scheme float in sv2 to a complex
	@ input:	sv2	scheme int
	@ output:	sv2	scheme rational
	@ modifies:	sv1, rva, rvb, rvc
	save2	sv1, sv3
	set	sv1, sv2
	set	sv2, #f0		@ sv2 <- 0 as scheme float
	bl	flt2cpx
	set	sv2, sv1
	restor2	sv1, sv3
	b	unijrt

_func_
fltmte:	@ convert float to 'in-place' mantissa and biased exponent
	@ on entry:	sv1 <- number					(scheme float)
	@ on exit:	sv1 <- signed 'in-place' mantissa of sv1	(scheme int)
	@ on exit:	rva <- biased exponent of sv1			(raw int)
	@ modifies:	sv1, rva
	fltmte	rva, sv1
	set	pc,  lnk		@ return

.ifdef	hardware_FPU

_func_
mteflt:	@ convert 'in-place' mantissa and biased exponent to float
	@ input:	sv1	scheme int	signed 'in-place' mantissa
	@ input:	rva	raw int		biased exponent
	@ output:	sv1	scheme float
	@ modifies:	sv1, rva, rvb
	int2raw	rvb, sv1
  .ifndef FPU_is_maverick
	vmov	s0,  rvb
	vcvt.f32.s32	s0,  s0
	sub	rva, rva, #21
	lsl	rva, rva, #23
	vmov	s1,  rva
	vmul.f32	s0,  s0,  s1
	vmov	rva, s0
  .else
	cfmv64lr mvdx0, rvb
	cfcvt32s mvf0, mvfx0
	sub	rva, rva, #21
	lsl	rva, rva, #23
	cfmvsr	mvf1, rva
	cfmuls	mvf0, mvf0, mvf1
	cfmvrs	rva, mvf0
  .endif
	bic	rva, rva, #0x03
	orr	sv1, rva, #f0
	set	pc,  lnk
	
.else	@ no hardware FPU
		
_func_
mteflt:	@ convert 'in-place' mantissa and biased exponent to float
	@ input:	sv1	scheme int	signed 'in-place' mantissa
	@ input:	rva	raw int		biased exponent
	@ output:	sv1	scheme float
	@ modifies:	sv1, rva, rvb, rvc
	eq	sv1, #i0		@ is number zero ?
	beq	mtefzr
	set	rvc, #f0		@ sv4 <- 0.0, initial result (scheme float)
	cmp	sv1, #0			@ is mantissa negative?
	itT	mi
	ngfltmi	rvc, rvc		@	if so,  sv4 <- -0.0, initial result (scheme float)
	ngintmi	sv1, sv1		@	if so,  sv1 <- mantissa (positive)
	set	rvb, rva		@ rvb <- biased exponent (saved)
.ifndef	cortex
	set	rva, #31		@ rva <- 31 (position of first potential msb)
fltmsb:	tst	sv1, sv1, LSR rva	@ is bit rva a 1 (tested against int_tag) ?
	itT	eq
	subeq	rva, rva, #1		@	if not, rva <- (rva - 1) = next possible msb
	beq	fltmsb			@	if not, jump to test that bit
.else
	clz	rva, sv1		@ rva <- number of leading zeroes in sv1
	rsb	rva, rva, #31		@ rva <- msb of sv1
.endif
	sub	rva, rva, #23		@ rva <- how much to shift mantissa to the right
	add	rvb, rvb, rva		@ rvb <- updated biased exponent
	cmp	rvb, #255		@ is updated biased exponent >= 255 ?
	bpl	mtefnf
	cmp	rvb, #1			@ is updated biased exponent less than 1 ?
	bmi	mtefdn			@	if so,  jump to prepare for denormalized number
mtefr0:	@ continue (in normal or denormalized case)
	orr	rvc, rvc, rvb, LSL #23	@ sv4 <- result sign + exponent + float tag
.ifndef	cortex
	cmp	rva, #0			@ are we shifting mantissa to the right?
	itTTT	pl
	lsrpl	rva, sv1, rva		@	if so,  rva <- shifted unsigned mantissa
	addpl	rvb, rva, #2		@	if so,  rvb <- shiftd usgn mantis, rounded up (>= 0.5 -> 1)
	lsrpl	rva, rvb, #24		@	if so,  rva <- 1 if rounding increased power of 2 of result
	lsrpl	rvb, rvb, rva		@	if so,  rvb <- mant shftd if rndng incrsd pow of 2 of reslt
	itT	pl
	addpl	rvc, rvc, rva, LSL #23	@	if so,  sv4 <- biased expo incrsd if rndng incrsd pow of 2
	bicpl	rvb, rvb, #3		@	if so,  rvb <- shifted unsigned mantissa without tag
	itTT	mi
	rsbmi	rva, rva, #0		@	if not, rva <- how much to shift mantissa to the left
	bicmi	rvb, sv1, #3		@	if not, rvb <- unsigned mantissa without tag
	lslmi	rvb, rvb, rva		@	if not, rvb <- shifted unsigned mantissa without tag
.else
	cmp	rva, #0			@ are we shifting mantissa to the right?
	bmi	mtefl4
	@ shifting to the right
	set	rvb, rva
	set	rva, sv1
mtefl0:	eq	rvb, #0
	itT	ne	
	lsrne	rva, rva, #1		@	if so,  rva <- shifted unsigned mantissa
	subne	rvb, rvb, #1
	bne	mtefl0
	add	rvb, rva, #2		@ rvb <- shifted unsigned mantissa, rounded up (>= 0.5 -> 1)
	lsr	rva, rvb, #24		@ rva <- 1 if rounding increased power of 2 of result
	add	rvc, rvc, rva, LSL #23	@ sv4 <- biased expon. increased if rounding increased power of 2
mtefl1:	eq	rva, #0
	itT	ne
	lsrne	rvb, rvb, #1		@	if so,  rvb <- mant shiftd if rndng incrsd pwr of 2 of rslt
	subne	rva, rva, #1
	bne	mtefl1
	bic	rvb, rvb, #3		@ rvb <- shifted unsigned mantissa without tag
	b	mtefl6
mtefl4:	@ shifting to the left
	rsb	rva, rva, #0		@ rva <- how much to shift mantissa to the left
	bic	rvb, sv1, #3		@ rvb <- unsigned mantissa without tag
mtefl5:	eq	rva, #0
	itT	ne
	lslne	rvb, rvb, #1		@ rvb <- shifted unsigned mantissa without tag
	subne	rva, rva, #1
	bne	mtefl5
.endif
mtefl6:	@ finish up
	set	rva, #0xff		@ rva <- exponent mask
	tst	rvc, rva, lsl #23	@ is expo. 0 (i.e. dnrmlzd) ? [excld dnrm (poss rnd up) from 1 clr]
	it	ne
	bicne	rvb, rvb, #0x00800000	@	if not, rvb <- shifted unsigned mantissa without tag and 1.
	orr	sv1, rvc, rvb		@ sv1 <- float
	set	pc,  lnk		@ return
mtefzr:	@ return zero
	set	sv1, #f0		@ sv1 <- 0.0
	set	pc,  lnk		@ exit with 0.0	
mtefnf:	@ return inf	
	set	rvb, #255		@ rvb <- 255
	orr	sv1, rvc, rvb, LSL #23	@ sv1 <- +/- inf
	set	pc,  lnk		@ return with +/- inf
mtefdn:	@ prepare for denormalized number
	add	rva, rva, #1		@ rva <- required right shift + 1 (for denormalization)
	sub	rva, rva, rvb		@ rva <- right shift needed to get exponent of zero
	set	rvb, #0			@ rvb <- zero (denormalized exponent)
	b	mtefr0

.endif	@ yes/no hardware FPU
		
	
.ifndef	cortex	@ integer division on ARMv4T (arm7tdmi, arm920t) and ARMv7A (cortex-a8)

idivid:	@ integer division:
	@ on entry:	sv1 <- dividand		(scheme int)
	@ on entry:	sv2 <- divisor		(scheme int)
	@ on exit:	sv1 <- quotient		(scheme int)
	@ on exit:	sv2 <- remainder	(scheme int)
	@ modifies:	sv1, sv2, rva, rvb, rvc
	set	rvc, #0
	postv	sv1
	itT	ne
	eorne	rvc, rvc, #0x14
	ngintne	sv1, sv1
	postv	sv2
	itT	ne
	eorne	rvc, rvc, #0x18
	ngintne	sv2, sv2	
	int2raw	rva, sv1		@ rva <- int1 (raw int)
	int2raw	rvb, sv2		@ rvb <- int2 (raw int)
pdivsh:	lsl	rvb, rvb, #1		@ rvb <- divisor, shifted leftwards as necessary
	cmp	rva, rvb		@ is dividand >= divisor ?
	bpl	pdivsh			@	if so, jump to keep shifting divisor, leftward
	lsr	rvb, rvb, #1		@ rvb <- shifted divisor/2
	raw2int	sv1, rvb		@ sv1 <- divisor as scheme integer
	set	rvb, rva		@ rvb <- dividand (will be remainder)
	set	rva, #0			@ rva <- 0 (initial quotient, raw int)
pdivcn:	lsl	rva, rva, #1		@ rva <- updated quotient
	cmp	rvb, sv1, LSR #2	@ is dividand >= divisor?
	itT	pl
	subpl	rvb, rvb, sv1, LSR #2	@	if so,  rvb <- dividand - divisor
	addpl	rva, rva, #1		@	if so,  rva <- quotient + 1
	eq	sv1, sv2		@ is divisor = original divisor (i.e. done)?
	itT	ne
	addne	sv1, sv1, #1		@	if not, sv1 <- divisor as pseudo float
	lsrne	sv1, sv1, #1		@	if not, sv1 <- divisor shifted right by 1 (scheme int)
	bne	pdivcn			@	if not, jump to continue dividing
	raw2int	sv1, rva		@ sv1 <- quotient (scheme int)
	raw2int	sv2, rvb		@ sv2 <- remainder (scheme int)
	tst	rvc, #0x04		@ should remainder be positive?
	it	ne
	ngintne	sv2, sv2		@	if not, sv2 <- remainder (negative)
	tst	rvc, #0x10		@ should quotient be positive?
	it	ne
	ngintne	sv1, sv1		@	if not, rva <- quotient (negative)
	set	pc,  lnk		@ return

.else	@ integer division on ARMv7M (cortex-m3 -- not available of ARMv7A, cortex-a8)

_func_
idivid:	@ integer division:	 rva{quot} rvb{rem} <- rva / rvb 
	@ modifies:	sv1, sv2, rva, rvb
	@ rva and rvb must be from 30-bit scheme ints (i.e. 31 or 32 bit ints don't work)
	int2raw	rva, sv1		@ rva <- int1 (raw int)
	int2raw	rvb, sv2		@ rvb <- int2 (raw int)
	sdiv	rva, rva, rvb
	mul	rvb, rvb, rva
	rsb	rvb, rvb, sv1, ASR #2
	raw2int	sv1, rva		@ sv1 <- quotient (scheme int)
	raw2int	sv2, rvb		@ sv2 <- remainder (scheme int)
	set	pc,  lnk
	
.endif	@ ifndef cortex

	
.ifdef	hardware_FPU

_func_
itrunc:	@ truncate number in sv1
	@ modifies:	sv1, rva
	@ note:		may need to check for "overflow" (number too large)
	bic	rva, sv1, #0x80000000	@ rva <- number, without sign
	cmp	rva, #0x59000000	@ does number have exponent >= 178 (no integer equivalent)?
	bpl	corerr			@	if so,  itrunc error
	bic	rva, sv1, #0x03
  .ifndef FPU_is_maverick
	vmov	s0, rva
	vcvt.s32.f32	s0, s0
	vmov	rva, s0
  .else
	cfmvsr	mvf0, rva
	cfcvts32 mvfx0, mvf0
	cfmvr64l rva, mvdx0
  .endif
	raw2int	sv1, rva
	set	pc,  lnk

.else	@ no hardware FPU

_func_
itrunc:	@ truncate number in sv1
	@ modifies:	sv1, rva, rvb
	set	rvb, lnk
	bl	fltmte			@ sv1 <- mantissa,  rva <- exponent
	set	lnk, rvb
	cmp	rva, #148
	bpl	itrun2
	rsb	rvb, rva, #148		@ rvb <- right shift needed to get integer part of number (raw int)
	asr	rva, sv1, #2		@ rva <- mantissa (raw)
	cmp	rva, #0			@ is number negative?
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- positive number
	asr	rva, rva, rvb		@ rva <- number, shifted to integer
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- integer, restored to proper sign
	raw2int	sv1, rva
	set	pc,  lnk
itrun2:	@ left shift
	sub	rvb, rva, #148
	cmp	rvb, #30
	bpl	itrerr
	asr	rva, sv1, #2		@ rva <- mantissa (raw)
	cmp	rva, #0			@ is number negative?
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- positive number
	lsl	rva, rva, rvb		@ rva <- number, shifted to integer
	it	mi
	rsbmi	rva, rva, #0		@	if so,  rva <- integer, restored to proper sign
	asr	rvb, rva, rvb
	lsl	rvb, rvb, #2
	orr	rvb, rvb, #int_tag
	eq	rvb, sv1
	it	ne
	asrne	rva, sv1, #2
	bne	itrerr
	raw2int	sv1, rva
	set	pc,  lnk
itrerr:	@ itrunc error
	raw2int	sv1, rva
	b	corerr
	
.endif	@ yes/no hardware FPU


@-------------------------------------------------------------------------------
@ dump literal constants (up to 4K of code before and after this point)
@-------------------------------------------------------------------------------
.ltorg

/*------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.2.   Numbers
@  II.A.6.2.6. Numerical input and output CORE:	number->string, string->number
@-----------------------------------------------------------------------------*/


pnmstr:	@ (number->string number <radix>)
	@ on entry:	sv1 <- number, sv2 <- <radix>
	@ on exit:	sv1 <- string
numstr:	@ [internal entry]
	pntrp	sv1			@ is number a rational or complex?
	beq	numsts			@	if so,  jump to process that case
numstn:	@ normal conversion	
	set	sv5, sv1		@ sv5 <- number (saved against malloc, pcons, pshdat)
	set	sv3, #0			@ sv3 <- 0
	nullp	sv2			@ no radix given?
	it	eq
	seteq	sv2, #0x29		@	if so, sv2 <- radix=10 (scheme int)
	set	sv1, #0x31		@ sv4 <- max of 12 digits (aligned) for decimal int or float (+/-)
	eq	sv2, #0x29		@ is radix 10?
	itTTT	ne
	setne	sv1, #0x81		@	if not, sv1 <- 32 digs + 4 byt hdr for bin int (scheme int)
	setne	sv3, #0x05		@	if not, sv3 <- shift = 1 (scheme int)
	setne	sv4, #0x05		@	if not, sv4 <- 1-bit mask (scheme int)
	eqne	sv2, #0x09		@	if not, is radix 2?
	itTTT	ne
	setne	sv1, #0x31		@	if not, sv1 <- 12 digs + 4 byt hdr for oct int (scheme int)
	setne	sv3, #0x0D		@	if not, sv3 <- shift = 3 (scheme int)
	setne	sv4, #0x1D		@	if not, sv4 <- 3-bit mask (scheme int)
	eqne	sv2, #0x21		@	if not, is radix 8?
	itTTT	ne
	setne	sv1, #0x21		@	if not, sv1 <- 8 digs + 4 byt hdr for hex int (scheme int)
	setne	sv3, #0x11		@	if not, sv3 <- shift = 4 (scheme int)
	setne	sv4, #0x3D		@	if not, sv4 <- 4-bit mask (scheme int)
	eqne	sv2, #0x41		@	if not, is radix 16?
	set	sv2, sv1		@ sv2 <- size of string to allocate
	straloc	sv1, sv2		@ sv1 <- address of digits-string
	int2raw	rva, sv5		@ rva <- number (eg. raw int)
	eq	sv3, #0			@ is radix decimal?
	beq	numst1			@	if so,  jump to decimal conversion
	@ scheme 32-bit item -> binary, octal or hexadecimal digits, as string
	strlen	sv5, sv1		@ sv5 <- number of digits (scheme int)
	sub	sv5, sv5, #0x04		@ sv5 <- offset to last digit (scheme int)
numst0:	and	rvb, rva, sv4, LSR #2	@ rvb <- masked bits
	cmp	rvb, #0x0A		@ are they above 9?
	itE	pl
	addpl	rvb, rvb, #0x37		@	if so,  rvb <- raw ASCII char A to F
	addmi	rvb, rvb, #0x30		@	if not, rvb <- raw ASCII char 0 to 9
	bytset	sv1, sv5, rvb		@ store raw ASCII char into digits string
	eq	sv5, #i0		@ are we done?
	it	eq
	seteq	pc,  cnt		@	if so,  return
	lsr	rvb, sv3, #2		@ rvb <- shift as raw int
	lsr	rva, rva, rvb		@ rva <- raw number, shifted
	sub	sv5, sv5, #4		@ sv4 <- offset of previous digit
	b	numst0			@ jump to continue conversion

numst1:	@ convert to base 10 string (integer or float)
	cmp	rva, #0			@ see if number is negative
	itE	pl
	setpl	rvb, #' 		@	if not, rvb <- ascii space
	setmi	rvb, #'-		@	if so,  rvb <- ascii - (minus)
	tst	sv5, #int_tag		@ is number an integer?
	set	sv5, #i0		@ sv5 <- offset to sign as scheme int
	bytset	sv1, sv5, rvb		@ store sign into digits array
	beq	numst4			@	if not, jump to float conversion
	@ integer to base 10 string conversion -- extract digits
	set	sv5, #0x31		@ sv5 <- offset to (after) 12th digit as scheme int
	cmp	rva, #0			@ see if number is negative
	it	mi
	rsbmi	rva, rva, #0		@	if so,  make number positive
numst2:	@
	bl	dg2asc
	sub	sv5, sv5, #4		@ sv5 <- offset to digit
	bytset	sv1, sv5, rvb		@ store digit into digits array
	eq	rva, #0			@ is quotient zero?
	bne	numst2			@	if not, jump to keep extracting digits
	set	sv2, #i0		@ sv2 <- offset to 1st digit or sign as scheme int
	bytref	rva, sv1, sv2		@ rva <-  sign digit
	eq	rva, #0x2D		@ is sign "-" ?
	it	eq
	addeq	sv2, sv2, #4		@	if so,  adjust offset to 1st digit
	rsb	rva, sv5, #0x31		@ rva <- number of digits * 4
	orr	sv3, rva, #0x01		@ sv3 <- number of digits as scheme int
	it	eq
	addeq	sv3, sv3, #4		@	adjust number of chars if number is negative
	add	sv3, rva, sv2		@ sv3 <- offset to position of last digit
	set	sv4, sv1		@ sv4 <- char source = destination
numst3:	@ integer to base 10 string conversion -- move digits to begining of string
	eq	sv2, sv3		@ are we done?
	beq	numstx
	bytref	rva, sv4, sv5		@ rva <- next digit
	bytset	sv1, sv2, rva		@ store digit sequentially back into array
	add	sv2, sv2, #4		@ sv2 <- next destination offset
	add	sv5, sv5, #4		@ sv5 <- next source offset
	b	numst3
numstx:	
	lsl	rva, sv3, #6
	orr	rva, rva, #string_tag
	str	rva, [sv1, #-4]		@ store number of digits in array
	set	pc,  cnt

numst4:	@ scheme float -> digits that make up float, as symbol
	@ mantissa (21 or even 23 bits) has max of 7 digits + sign
	@ exponent has max of 2 digits + sign
	@ total is 12 digits, including e or E
	lsl	rva, rva, #2		@ rva <- float as raw value
	cmp	rva, #0			@ see if float is negative
	it	mi
	addmi	sv5, sv5, #4		@	if negative, update storage offset to account for "-" sign
	@ begin extracting number, watch for +/-0.0, +/-inf, +/-nan
	fabs	rva, rva		@ rva <- raw float, cleared sign
	eq	rva, #0			@ is float zero?
	itT	eq
	ldreq	sv4, =zerof_
	beq	nflstQ
	lsl	rva, rva, #1		@ rva <- exponent and mantissa, shifted left
	and	rvb, rva, #0xFF000000	@ rvb <- biased binary exponent, shifted all the way left
	eq	rvb, #0xFF000000	@ is exponent 255? => nan or inf
	bne	nflstA			@	if not, jump to process regular number
	eq	rva, #0xFF000000	@ is exponent 255 and mantissa zero? (i.e. Inf)
	itE	eq
	ldreq	sv4, =inf___		@	if so,  sv4 <- inf as symbol characters
	ldrne	sv4, =nan___		@	if not, sv4 <- nan as symbol characters
nflstQ:	set	sv2, sv5
	set	sv5, #i0
	strlen	rva, sv4
	bic	rva, rva, #3
	add	sv3, sv2, rva
	b	numst3

nflstA:	lsr	rvb, rvb, #24		@ rvb <- biased binary exponent
	bic	rva, rva, #0xFF000000	@ rva <- mantissa (pre-shifted left by 1)
	orr	rva, rva, #0x01000000	@ rva <- mantissa with 1.x
	lsl	rva, rva, #7		@ rva <- full mantissa shifted all the way left
	eq	rvb, #0			@ is biased binary exponent zero?
	itEE	ne
	subne	rvc, rvb, #127		@	if not, rvb <- unbiased exponent
	subeq	rvc, rvb, #126		@	if so,  rvb <- unbiased exponent (denormalized)
	biceq	rva, rva, #0x80000000	@	if so,  rva <- mantissa 0.x (denormalized)
	@ convert exponent to decimal
	set	sv2, #int_tag		@ sv2 <- decimal exponent (scheme int)
	cmp	rvc, #30		@ is bin exp >= 30?
	bpl	nflstp			@	if so,  jump to process exponent greater than 31
nflstn:	bl	lftshf			@ rva <- rva shifted left, rvb <- # shift steps
	rsb	rvc, rvb, rvc		@ rvb <- updated binary exponent (raw)
	lsr	rva, rva, #4		@ rva <- rva / 16
	set	rvb, #4
	add	rvc, rvb, rvc		@ rvb <- updated binary exponent (raw)
	lsl	rvb, rva, #3
	add	rva, rvb, rva, LSL #1	@ rva <- 10*rva
	sub	sv2, sv2, #4
	cmp	rvc, #30		@ is bin exp >= 30?
	bmi	nflstn			@	if not, keep going
nflstp:	bl	idiv10			@ rva <- rva/10  (number/10) (rvb used)
	add	sv2, sv2, #4
	bl	lftshf			@ rva <- rva shifted left, rvb <- # shift steps
	rsb	rvc, rvb, rvc		@ rvb <- updated binary exponent (raw)
	cmp	rvc, #30		@ is bin exp >= 30?
	bpl	nflstp
	rsb	rvb, rvc, #31
	lsr	rva, rva, rvb		@ rva <- number (with no extraneous bin exp)
	@ rva = number (unsigned, sign is in sv1 already), sv2 = decimal exponent (scheme int, signed)
	set	sv4, sv2		@ sv4 <- decimal exponent
	set	sv5, #0x31		@ sv5 <- offset to (after) 12th digit as scheme int
nflst0:	@
	bl	dg2asc			@ rvb <- remainder as digit
	sub	sv5, sv5, #4		@ sv5 <- offset to digit
	bytset	sv1, sv5, rvb		@ store digit into digits array
	eq	rva, #0			@ is quotient zero?
	bne	nflst0
	set	sv2, #i0		@ sv2 <- offset to 1st digit or sign as scheme int
	bytref	rva, sv1, sv2		@ rva <-  sign digit
	eq	rva, #0x2D		@ is sign "-" ?
	it	eq
	addeq	sv2, sv2, #4		@	if so, adjust offset to 1st digit
	rsb	rva, sv5, #0x31		@ rva <- number of digits * 4
	@ update exponent for future position of dot
	lsr	rvb, rva, #2		@ rvb <- number of digits, raw int
	sub	rvb, rvb, #1		@ rvb <- how much to increase exponent by (for upcoming dot)
	add	rvb, rvb, sv4, ASR #2	@ rvb <- updated decimal exponent (raw int)
	raw2int	sv4, rvb
	@ shift digits back to start of array then round number to 6 digits, if necessary
	cmp	rva, #28
	itTE	pl
	setpl	rva, #28		@	rva <- maximum number of digits to keep: 7 (* 4)
	setpl	rvb, #t			@	rvb <- true that we need to round result
	setmi	rvb, #f			@	rvb <- no, we don't need to round
	add	sv3, rva, sv2		@ sv3 <- offset to position of last digit + 1
nflst1:	eq	sv2, sv3		@ was that the last digit?
	itT	eq
	subeq	sv2, sv2, #4		@	if so,  sv2 <- offset to position of last digit
	subeq	sv3, sv3, #4		@	if so,  sv3 <- offset to position of last digit
	beq	nflst2			@	if so,  jump to continue
	bytref	rva, sv1, sv5		@ rva <- next digit
	bytset	sv1, sv2, rva		@ store digit sequentially back into array
	add	sv2, sv2, #4		@ sv2 <- next destination offset
	add	sv5, sv5, #4		@ sv5 <- next source offset
	b	nflst1
nflst2:	eq	rvb, #t			@ should number be rounded?
	bne	nflst3			@	if not, jump to continue
	cmp	rva, #0x35		@ is last digit >= 5?
	it	mi
	submi	sv3, sv3, #4		@	if not, eliminate it (adjust offset to end of digits)
	bmi	nflst3			@	if not, jump to continue
	@ round number to 6 digits (if necessary)
nflst4:	eq	sv2, #i0		@ were we at last digit?
	itT	ne
	subne	sv2, sv2, #4		@	if not, sv2 <- offset of previous digit
	bytrefne rvb, sv1, sv2		@ 	if not, rvb <- digit
	it	ne
	eqne	rvb, #0x2D		@ 	if not, is this digit a minus sign?
	it	eq
	seteq	sv2, sv3		@	if so,  sv2 <- offset of last digit (prepare to splice 1)
	beq	nflst5			@	if so,  jump to add a leading 1
	eq	rvb, #0x39		@ is previous digit a 9?
	itE	eq
	seteq	rvb, #0x30		@	rvb <- (if so) make previous digit zero
	addne	rvb, rvb, #1		@	rvb <- (if not) add 1 to previous digit
	bytset	sv1, sv2, rvb		@ rvb <- updated previous digit
	beq	nflst4			@	if carry-over, redo loop with previous digit
	sub	sv3, sv3, #4		@ eliminate last digit
	b	nflst3			@ jump to continue
nflst5:	@ splice a 1 before the other digits (due to carry-over), update exponent
	eq	sv2, #i0		@ were we at first digit?
	itT	ne
	subne	sv2, sv2, #4		@	if not, sv2 <- offset of previous digit
	bytrefne rvb, sv1, sv2		@ 	if not, rvb <- previous digit
	itT	ne
	addne	sv2, sv2, #4		@	if not, sv2 <- offset, restored
	eqne	rvb, #0x2D		@ 	if not, is previous digit a minus sign?
	it	eq
	seteq	rvb, #0x31		@	if so,  rvb <- (if time to splice) ASCII 1
	bytset	sv1, sv2, rvb		@ store digit there
	it	ne
	subne	sv2, sv2, #4		@	if not, sv2 <- offset of previous digit
	bne	nflst5			@	if not, jump to keep scanning
	asr	rvb, sv4, #2		@ rvb <- exponent (raw int)
	add	rvb, rvb, #1		@ rvb <- exponent increased by 1 (raw int)
	raw2int	sv4, rvb
nflst3:	@ put decimal dot in
	add	sv3, sv3, #4		@ sv3 <- offset to new end of digits (with dot)
	set	sv2, sv3		@ sv2 <- offset to new end of digits (with dot)
nflst6:	eq	sv2, #i0		@ were we at first digit?
	itT	ne
	subne	sv2, sv2, #4		@	if not, sv2 <- offset of previous digit
	bytrefne rvb, sv1, sv2		@ 	if not, rvb <- previous digit
	itT	ne
	addne	sv2, sv2, #4		@	if not, sv2 <- offset, restored
	eqne	rvb, #0x2D		@ 	if not, is previous digit a minus sign?
	itT	eq
	addeq	sv2, sv2, #4		@	if so,  sv2 <- offset to where dot goes
	seteq	rvb, #0x2E		@	if so,  rvb <- (if time to splice) ASCII dot
	bytset	sv1, sv2, rvb		@ store dot there
	it	ne
	subne	sv2, sv2, #4		@	if not, sv2 <- offset of previous digit
	bne	nflst6			@	if not, jump to keep scanning
	@ erase trailing zeros, and maybe the dot too
nflst7:	bytref	rvb, sv1, sv3		@ rvb <-  last digit
	eq	rvb, #0x30		@ is it a zero?
	it	eq
	subeq	sv3, sv3, #4		@	if so,  delete it
	beq	nflst7			@	if so,  branch back to next digit
	eq	sv4, #i0		@ is exponent zero?
	beq	nflsxt			@	if so, exit
	set	rvb, #0x65		@ rvb <- ASCII e
	add	sv3, sv3, #4		@ sv3 <- updated offset to last digit
	bytset	sv1, sv3, rvb		@ store e there
	int2raw	rva, sv4
	cmp	rva, #0			@ is exponent positive?
	itTTT	mi
	rsbmi	rva, rva, #0		@	if not, make it positive
	setmi	rvb, #0x2D		@	if not, rvb <- ASCII minus
	addmi	sv3, sv3, #4		@	if not, sv3 <- updated offset to last digit
	bytsetmi sv1, sv3, rvb		@	if not, store minus there
	add	sv3, sv3, #4		@ sv3 <- offset to where to store exponent digits
	bl	dg2asc			@ rvb <- remainder as digit
	eq	rva, #0			@ is quotient zero?
	it	ne
	addne	sv3, sv3, #4		@	if not, sv3 <- position for exponent
	bytset	sv1, sv3, rvb		@ store exponent there
	beq	nflsxt			@	if so, (if quotient is zero) exit
	bl	dg2asc			@ rvb <- remainder as digit
	sub	sv5, sv3, #4		@ sv5 <- position of where to put second digit of exponent
	bytset	sv1, sv5, rvb		@ store exponent there
nflsxt:	add	sv3, sv3, #4		@ sv3 <- number of digits (scheme int)
	set	rva, #string_tag
	orr	sv3, rva, sv3, LSL #6
	str	sv3, [sv1, #-4]		@ store number of digits in array
	set	pc,  cnt

dg2asc:	@ digit to ascii
	set	rvc, lnk
	raw2int	sv2, rva
	bl	idiv10			@ rva <- rva / 10 = quotient
	lsl	rvb, rva, #1		@ rvb <- quotient * 2
	add	rvb, rvb, rva, LSL #3	@ rvb <- quotient * 10
	rsb	rvb, rvb, sv2, LSR #2	@ rvb <- original num minus 10*quotient = remainder (rightmost dig)
	add	rvb, rvb, #0x30		@ rvb <- remainder as ascii digit
	set	pc,  rvc

numsts:	@ convert rational or complex to string
	sav_rc	sv1
	rawsplt	rva, rvc, sv1
	and	rvb, rva, #0x0f
	lsr	rva, rva, #2
	bic	rva, rva, #3
	orr	rva, rva, rvc, lsl #30
	eq	rvb, #rational_tag
	itE	eq
	orreq	sv1, rva, #int_tag
	orrne	sv1, rva, #float_tag
	set	sv2, #null
	call	numstn			@ sv1 <- numerator/real-part-string
	car	sv2, dts		@ sv2 <- number
	save	sv1			@ dts <- (numerator/real-part-string number cnt ...)
	rawsplt	rva, rvc, sv2
	bic	rvc, rvc, #3
	tst	rva, #0x08		@ is this a rational?
	itE	eq
	orreq	sv1, rvc, #int_tag
	orrne	sv1, rvc, #float_tag
	set	sv2, #null
	call	numstn			@ sv1 <- denominator/imaginary-part-string
	restor3	sv2, sv3, cnt		@ sv2 <- nmrtr/real-part-strng, sv3 <- nmbr, cnt <- cnt, dts <- (.)
	strlen	rva, sv1
	strlen	rvb, sv2
	add	rvc, rva, rvb
	add	sv4, rvc, #3
	rawsplt	rva, rvb, sv3
	eor	rvb, rvb, #0x80000000
	tst	rva, #0x08
	itT	ne
	tstne	rvb, #0x80000000
	addne	sv4, sv4, #4
	straloc	sv5, sv4
	set	sv4, #i0
	strlen	rvb, sv2
numrc0:	bytref	rva, sv2, sv4
	bytset	sv5, sv4, rva
	add	sv4, sv4, #4
	eq	sv4, rvb
	bne	numrc0
	ldr	rvc, [sv3, #-4]
	ldr	rvb, [sv3]
	eor	rvb, rvb, #0x80000000
	tst	rvc, #0x08		@ is this a rational?
	itT	eq
	seteq	rva, #'/
	bytseteq sv5, sv4, rva
	itEEE	eq
	addeq	sv4, sv4, #4
	tstne	rvb, #0x80000000
	setne	rva, #'+
	bytsetne sv5, sv4, rva
	it	ne
	addne	sv4, sv4, #4
	set	sv2, #i0
	strlen	rva, sv1
numrc1:	bytref	rvb, sv1, sv2
	bytset	sv5, sv4, rvb
	add	sv2, sv2, #4
	add	sv4, sv4, #4
	eq	sv2, rva
	bne	numrc1
	ldr	rvc, [sv3, #-4]
	tst	rvc, #0x08		@ is this a rational?
	itT	ne
	setne	rvb, #'i
	bytsetne sv5, sv4, rvb
	set	sv1, sv5
	set	pc,  cnt


pstnum:	@ (string->number string <fmt>)
	@ on entry:	sv1 <- string, sv2 <- <fmt>
strnum:	@ [internal entry]
	strlen	sv3, sv1		@ sv3 <- number of digits (scheme int)
	set	sv5, #i0		@ sv5 <- offset of 1st char
strnen:	@ [internal re-entry]
	eq	sv5, sv3		@ string has no characters?
	beq	i0fxt
	bytref	rva, sv1, sv5		@ rva <- 1st char of string
	eq	rva, #'#		@ is it a #?
	beq	strn_0			@	if so,  jump to use it to decide format
	eq	sv2, #0x29		@ is fmt = 10 (decimal format)?
	it	ne
	nullpne	sv2			@	or was no format specified?
	beq	strn10			@	if so,  jump to decimal conversion
	set	sv4, #0x05		@ sv4 <- 1 (shift, scheme int), assume <fmt> is binary  
	eq	sv2, #0x09		@ is fmt = 2, really?
	itT	ne
	setne	sv4, #0x11		@	if not, sv4 <- 4 (shift, scheme int), assume <fmt> is hex
	eqne	sv2, #0x41		@	if not, is fmt = 16, really?
	it	ne
	setne	sv4, #0x0D		@	if not, sv4 <- 3 (shift, scheme int), assume <fmt> is octal
	b	strn_1			@ jump to binary, otal, hexadecimal conversion
strn_0:	@ identify format based on leading #d, #b, #o, #x, #e, #i
	add	sv5, sv5, #4		@ sv5 <- offset to digits after #
	bytref	rva, sv1, sv5		@ rva <- char of string, after #
	add	sv5, sv5, #4		@ sv5 <- offset to digits after #x
	orr	rva, rva, #0x20		@ rva <- 2nd char of string, lower case
	eq	rva, #'d		@ is 2nd char a d?  --  D?
	beq	strn10			@	if so,  jump to decimal conversion
	set	sv4, #0x05		@ sv4 <- 1 (shift, scheme int), assume <fmt> is binary
	eq	rva, #'b		@ is 2nd char a b?  --  b?
	itT	ne
	setne	sv4, #0x0D		@	if not, sv4 <- 3 (shift, scheme int), assume <fmt> is octal
	eqne	rva, #'o		@	if not, is 2nd char a o?  --  O?
	itT	ne
	setne	sv4, #0x11		@	if not, sv4 <- 4 (shift, scheme int), assume <fmt> is hex
	eqne	rva, #'x		@	if not, is 2nd char a x?
	bne	strnei			@	if not, jump to #e/#i case
strn_1:	@ keep going with binary, octal or hexadecimal (exact) conversion
	set	rvb, #0			@ rvb <- stores result	
	bytref	rvc, sv1, sv5
	eq	rvc, #'-		@ is it a minus?
	it	eq
	addeq	sv5, sv5, #4
strn_2:	@ binary, octal and hexadecimal conversion
	eq	sv5, sv3		@ are we done with string?
	beq	strn_3
	lsr	rva, sv4, #2		@ rva <- shift
	lsl	rvb, rvb, rva		@ rvb <- prior result, shifted
	bytref	rva, sv1, sv5		@ rva <- char
	tst	rva, #0x40		@ is char a->f or A->F?
	it	ne
	addne	rva, rva, #0x09		@	if so,  adjust it
	and	rva, rva, #0x0F		@ rva <- decimal value of char (raw int)
	add	rvb, rva, rvb		@ rvb <- updated result (raw int)
	add	sv5, sv5, #4		@ sv5 <- offset of next digit (scheme int)
	b	strn_2			@ jump to continue conversion
strn_3:	@ binary, octal and hexadecimal conversion
	raw2int	sv1, rvb		@ sv1 <- value as scheme int
	eq	rvc, #'-
	it	eq
	nginteq	sv1, sv1
	set	pc,  cnt
	
strn10:	@ decimal conversion to integer or float, overflows to nan
	@ on entry:	sv1 <- string
	@ on entry:	sv3 <- offset to after last digit
	@ on entry:	sv5 <- offset to first digit
	sub	sv2, sv3, #4		@ sv2 <- offset of last char
	bytref	rva, sv1, sv2		@ rva <- char
	eq	rva, #'i
	beq	strcpx
	set	sv2, sv5
strnlp:	bytref	rva, sv1, sv2		@ rva <- char
	eq	rva, #'/
	beq	strrat
	add	sv2, sv2, #4
	eq	sv2, sv3
	bne	strnlp
	set	lnk, cnt
_func_	
strnrm:	@ normal conversion of string to int or float
	@ on entry:	sv1 <- string
	@ on entry:	sv3 <- offset to after last digit
	@ on entry:	sv5 <- offset to first digit
	set	rvb, #0
	set	sv4, #null
	bytref	rva, sv1, sv5
	eq	rva, #'-		@ is it a minus?
	itEE	eq
	seteq	rvc, #f
	setne	rvc, #t
	subne	sv5, sv5, #4		@	if not,  sv5 <- offset of before first digit
strn11:	add	sv5, sv5, #4		@ sv5 <- offset of next digit
	eq	sv5, sv3		@ are we done with string?
	beq	strn12			@	if so,  jump to finish up
	bytref	rva, sv1, sv5		@ rva <- char
	eq	rva, #'.		@ is char #\. ?
	it	eq
	seteq	sv4, sv5		@	if so,  sv4 <- offset of dot
	beq	strn11			@	if so,  jump to keep processing number
	eq	rva, #'#
	itT	eq
	seteq	sv4, sv5		@	if so,  sv4 <- offset of #
	seteq	rva, #'0
	cmp	rva, #'0		@ is char >= #\0 ?
	bmi	strn12			@	if not, jump to finish up or convert exponent
	cmp	rva, #':		@ and is it <= #\9 ?
	bpl	strn12			@	if not, jump to finish up or convert exponent
	and	rva, rva, #0x0F		@ rva <- integer from digit (raw int)
	lsl	rvb, rvb, #1		@ rvb <- previous result * 2 (raw int)
	adds	rvb, rvb, rvb, LSL #2	@ rvb <- previous result * 10 (raw int)
	bcs	corerr
	adds	rvb, rvb, rva		@ rvb <- updated integer result (raw int)
	bcs	corerr
	eq	rvc, #f
	it	eq
	eqeq	rvb, #0x20000000
	beq	strn11
	tst	rvb, #0xE0000000
	bne	corerr
	b	strn11			@ jump to continue processing
strn12:	@
	eq	rvc, #f
	it	eq
	rsbeq	rvb, rvb, #0		@ if so,  rvb <- negative number (raw int)
	raw2int	sv2, rvb		@ sv2 <- number (scheme int)
	eq	sv5, sv3		@ are we at end of string?
	it	eq
	nullpeq	sv4			@	and was no dot or exponent encountered?
	itT	eq
	seteq	sv1, sv2		@	if so,  sv1 <- number (an integer)
	seteq	pc,  lnk
	@ float conversion, sv2 is integer part (scheme int), sv4 is position of dot or null
	nullp	sv4			@ was a dot encountered?
	it	eq
	seteq	rvb, #0			@	if not, rvb <- 0 (exponent due to dot)
	itTTT	ne
	subne	rvb, sv5, sv4		@	if so,  rvb <- current position - dot position
	lsrne	rvb, rvb, #2		@	if so,  rvb <- exponent + 1 (raw int)
	subne	rvb, rvb, #1		@	if so,  rvb <- exponent due to dot (positive)
	rsbne	rvb, rvb, #0		@	if so,  rvb <- exponent due to dot (properly negative)
	eq	sv5, sv3		@ was string fully processed? (no e or E part)
	beq	strn16			@	if so,  skip processing of e/E part
	lsl	rvb, rvb, #8		@ rvb <- exponent due to dot, shifted
	add	sv5, sv5, #4		@ sv5 <- index of 1st digit of e/E exponent
	bytref	rva, sv1, sv5		@ rva <- 1st digit of e/E exponent
	eq	rva, #'-		@ is it a minus?
	itEE	eq
	orreq	sv4, rvb, #f		@	if minus, sv4 <- dot exponent packed with #f
	orrne	sv4, rvb, #t		@	if plus,  sv4 <- dot exponent packed with #t
	subne	sv5, sv5, #4		@	if plus,  sv5 <- offset of before first digit
	set	rvb, #0			@ rvb <- 0 (starting vaue of e/E exponent)
strn14:	add	sv5, sv5, #4		@ sv5 <- offset of next digit
	eq	sv5, sv3		@ are we done with string?
	beq	strn15			@	if so, jump to finish up
	bytref	rva, sv1, sv5		@ rva <- char
	and	rva, rva, #0x0F		@ rva <- integer from digit (raw int)
	lsl	rvb, rvb, #1		@ rvb <- previous result * 2 (raw int)
	add	rvb, rvb, rvb, LSL #2	@ rvb <- previous result * 10 (raw int)
	add	rvb, rvb, rva		@ rvb <- updated integer result (raw int)
	b	strn14			@ jump to continue processing
strn15:	and	sv3, sv4, #0xFF
	eq	sv3, #f
	it	eq
	rsbeq	rvb, rvb, #0
	add	rvb, rvb, sv4, ASR #8
strn16:	@ unpack sv2 to rva (num) sv1 (sign in float) and rvb to rvb (num) + branch according to sign
	set	sv1, #f0		@ sv1 <- blank scheme float (zero)
	int2raw	rva, sv2		@ rva <- number as raw int
	cmp	rva, #0			@ is number negative?
	itT	mi
	orrmi	sv1, sv1, #0x80000000	@	if so, place minus sign in float
	rsbmi	rva, rva, #0		@	if so, make number positive
	eq	rva, #0			@ is number zero?
	it	eq
	seteq	pc,  lnk		@	if so, exit with +/- 0.0
	set	rvc, lnk		@ rvc <- lnk saved against lftshf, idiv10
	set	sv4, #i0		@ sv4 <- 0 (scheme int)
	set	sv5, sv4
	cmp	rvb, #0			@ is decimal exponent negative?
	it	mi
	rsbmi	rvb, rvb, #0		@	if so, make it positive
	orr	sv2, sv4, rvb, LSL #2	@ sv2 <- decimal exponent as scheme int
	bmi	tokfln			@	if dec exp is negative, branch to process negative exponent
tokflp:	bl	lftshf			@ rva <- number shifted left, rvb <- # shift steps
	rsb	rvb, rvb, sv5, ASR #2	@ rvb <- updated binary exponent (raw int)
	orr	sv5, sv4, rvb, LSL #2	@ sv5 <- bin exp decreased by shift (scheme int)
	eq	sv2, sv4		@ are we done? (decimal exponent = 0 as scheme int)
	beq	tokfxz			@	if so, exit
	@ divide number by 16, update binary exponent
	lsr	rva, rva, #4		@ rva <- number / 16
	set	rvb, #4			@ rvb <- 4
	add	rvb, rvb, sv5, ASR #2	@ rvb <- updated binary exponent (raw int)
	orr	sv5, sv4, rvb, LSL #2	@ sv5 <- bin exponent increased by 4 (scheme int)
	@ multiply number by 10 and update decimal exponent (sv2)
	sub	sv2, sv2, #4		@ sv2 <- decimal exponent minus 1 (scheme int)
	lsl	rvb, rva, #3		@ rvb <- number * 8
	add	rva, rvb, rva, LSL #1	@ rva <- number * 10
	b	tokflp
tokfln:	bl	lftshf			@ rva <- number shifted left, rvb <- # shift steps
	rsb	rvb, rvb, sv5, ASR #2	@ rvb <- updated binary exponent
	orr	sv5, sv4, rvb, LSL #2	@ sv5 <- bin exp decreased by shift (scheme int)
	eq	sv2, sv4		@ are we done? (decimal exponent = 0 as scheme int)
	beq	tokfxz			@	if so, exit
	@ divide number by 10 and update decimal exponent (sv2)
	sub	sv2, sv2, #4		@ sv2 <- decimal exponent ("neg") minus 1 (scheme int)
	bl	idiv10			@ rva <- number / 10
	b	tokfln
tokfxz: @
	set	lnk, rvc		@ lnk <- lnk, restored	
	lsr	rva, rva, #3
	set	rvb, #3
	add	rvb, rvb, sv5, ASR #2
	postv	sv1			@ is number positive?
	it	ne
	rsbne	rva, rva, #0		@	if not, negativize it
	orr	sv1, sv4, rva, LSL #2	@ sv1 <- number (scheme int)
	add	rva, rvb, #148		@ 127 + 21
	b	mteflt

strrat:	@ string -> rational
	@ on entry:	 sv2 <- offset of /
	save3	sv1, sv2, sv3
	set	sv3, sv2
	bl	strnrm			@ sv1 <- numerator-or-real-part
	tst	sv1, #float_tag		@ is numerator a scheme int?
	bne	corerr			@	if not, jump to report error
	set	sv4, sv1		@ sv4 <- numerator-or-real-part
	restor3	sv1, sv5, sv3
	save	sv4			@ dts <- (numerator-or-real-part ...)
	add	sv5, sv5, #4
	eq	sv5, sv3
	it	eq
	seteq	sv1, #5
	pntrp	sv1
	it	eq
	bleq	strnrm			@ sv1 <- denominator-or-imaginary part
	tst	sv1, #float_tag		@ is denominator a scheme int?
	bne	corerr			@	if not, jump to report error
	restor	sv4			@ sv4 <- numerator-or-real-part, dts <- (...)
	set	sv2, sv1		@ sv2 <- denominator
	set	sv1, sv4		@ sv1 <- numerator
	set	lnk, cnt
	b	makrat

strcpx:	@ string -> complex
	sub	sv3, sv3, #4
	set	sv2, sv3
strcx1:	@ loop to find +/- between real and imag parts
	sub	sv2, sv2, #4
	eq	sv2, sv5
	beq	strcx2			@ no real part
	bytref	rva, sv1, sv2		@ rva <- char
	eq	rva, #'+
	it	ne
	eqne	rva, #'-
	bne	strcx1
	eq	sv2, sv5
	beq	strcx2
	sub	rvc, sv2, #4
	bytref	rva, sv1, rvc		@ rva <- prior char
	eq	rva, #'e
	it	ne
	eqne	rva, #'E
	beq	strcx1
	@ extract parts
	save3	sv1, sv2, sv3
	set	sv3, sv2
	bl	strnrm			@ sv1 <- real-part
	set	sv2, #f0
	bl	uninum
	set	sv4, sv1		@ sv4 <- real-part
	restor3	sv1, sv5, sv3
	save	sv4			@ dts <- (real-part ...)
	bytref	rva, sv1, sv5
	eq	rva, #'-
	it	ne
	addne	sv5, sv5, #4
	bl	strnrm			@ sv1 <- imaginary part
	restor	sv2			@ sv2 <- real-part, dts <- (...)
strrc1:	@ finish up
	swap	sv1, sv2, sv3		@ sv1 <- real-part, sv2 <- imag-part, sv3 <- temp
	bl	uninum
	set	lnk, cnt
	b	makcpx
strcx2:	@ complex with no real part
	bl	strnrm			@ sv1 <- imaginary part
	set	sv2, #f0		@ sv2 <- real-part (zero)
	b	strrc1
	
strnei:	@ number starting with #e or #|, or #i or #~
	@ on entry, rva <- char following #
	eq	rva, #'e
	it	ne
	eqne	rva, #'|
	itE	eq
	seteq	sv4, #t
	setne	sv4, #f
	sav_rc	sv4
	call	strnen
	restor2	sv4, cnt
	eq	sv4, #t
	it	eq
	ldreq	rvc, =inx2tb
	beq	numjmp
	set	sv2, #f0		@ sv2 <- float zero
	set	lnk, cnt
	b	uninum

/*------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.2.   Numbers
@  II.A.6.2.6. Numerical input and output SUPPORT:	lftshf, idiv10
@-----------------------------------------------------------------------------*/

.ifndef	hardware_FPU	@ exclude cortex-a8
  .ifndef cortex	@ left shift on ARMv4T

lftshf:	@ shift rva left until it starts with a 1, rvb has number of steps used to shift
	set	rvb, #0
lftsh0:	cmp	rva, #0
	it	mi
	setmi	pc,  lnk
	lsl	rva, rva, #1
	add	rvb, rvb, #1
	eq	rvb, #32
	it	eq
	seteq	pc,  lnk
	b	lftsh0

  .else	@ left shift on ARMv7M (cortex-m3)

_func_	
lftshf:	@ shift rva left until it starts with a 1, rvb has number of steps used to shift
	clz	rvb, rva
	lsl	rva, rva, rvb
	set	pc,  lnk

  .endif

.else	@ left shift on devices with FPU (eg. ARMv7A (cortex-a8) or EP9302 = ARMv4T)

  .ifndef FPU_is_maverick
	
_func_	
lftshf:	@ shift rva left until it starts with a 1, rvb has number of steps used to shift
	clz	rvb, rva
	lsl	rva, rva, rvb
	set	pc,  lnk

  .else
	
lftshf:	@ shift rva left until it starts with a 1, rvb has number of steps used to shift
	set	rvb, #0
lftsh0:	cmp	rva, #0
	it	mi
	setmi	pc,  lnk
	lsl	rva, rva, #1
	add	rvb, rvb, #1
	eq	rvb, #32
	it	eq
	seteq	pc,  lnk
	b	lftsh0

  .endif
	
.endif

.ifndef cortex	@ integer division by 10 on ARMv4T and ARMv7A (cortex-a8)
	
idiv10:	@ positive integer division by 10:	rva <- rva / 10 (rvb used also)
	lsr	rvb, rva, #1		@ rvb <- num/2^1
	add	rvb, rvb, rva, LSR #2	@ rvb <- num/2^(1+2)
	add	rvb, rvb, rvb, LSR #4	@ rvb <- num/2^(1+2+5+6)
	add	rvb, rvb, rvb, LSR #8	@ rvb <- num/2^(1+2+5+6+9+10+13+14)
	add	rvb, rvb, rvb, LSR #16	@ rvb <- num/2^(1+2+5+6+9+10+13+14+17+18+21+22+25+26+29+30)
	lsr	rvb, rvb, #3		@ rvb <- num/2^(4+5+8+9+12+13+16+17+20+21+24+25+28+29+32+33)
	sub	rva, rva, rvb, LSL #3	@ rva <- approximation error: rva -  8*rvb
	sub	rva, rva, rvb, LSL #1	@ rva <- approximation error: rva - 10*rvb (value: 0 to 9?)
	add	rva, rva, #6		@ rva <- aproximation error + 6 (0110)
	add	rva, rvb, rva, LSR #4	@ rva <- rva / 10 == rvb + (approximation error + 6)/16
	set	pc,  lnk		@ return (result is in rva)

.else	@ integer division by 10 on ARMv7M (cortex-m3)
	
_func_	
idiv10:	@ positive integer division by 10:	rva <- rva / 10 (rvb used also)
	set	rvb, #10
	udiv	rva, rva, rvb
	set	pc,  lnk

.endif


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg





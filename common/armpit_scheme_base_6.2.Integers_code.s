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

.balign	4

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.2.	Numbers
@	6.2.5	Numerical operations:	number?, =, <, >, <=, >=, +, *, -, /,
@					quotient, remainder, modulo,
@	6.2.6	Numerical input output:	number->string, string->number
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	Requires:
@			core:		flsfxt, trufxt, boolxt, corerr, notfxt
@					save, save3, cons, sav_rc, zmaloc
@
@	Modified by (switches):		cortex
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
eqn:	@ (= num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ pre-entry:	prdnml reduces input args over following predicate
_func_
eqnint:	@ = for int
	eq	sv1, sv2
	it	ne
	setne	sv1, #f			@	if not, sv1 <- #f
	set	pc,  lnk		@ return with #f or value in sv1
	

	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
lt:	@ (< num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ pre-entry:	prdnml reduces input args over following predicate
_func_
ltint:	@ < for int (or positive floats)
	cmp	sv1, sv2		@ is x1 < x2 ?
	bmi	cmptru			@	if so,  jump to exit with x2
cmpfls:	set	sv1, #f			@ sv1 <- #f
	set	pc,  lnk		@ exit reduction with #f


	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
gt:	@ (> num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ pre-entry:	prdnml reduces input args over following predicate
_func_
gtint:	@ > for int
	cmp	sv2, sv1		@ is x1 >= x2 ?
	bpl	cmpfls			@	if not, jump to exit with #f
cmptru:	set	sv1, sv2		@ sv1 <- x2 (latest number)
	set	pc,  lnk		@ exit with num2


	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
le:	@ (<= num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ pre-entry:	prdnml reduces input args over following predicate
_func_
leint:	@ <= for int
	eq	sv1, sv2
	bne	ltint
	set	pc,  lnk


	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
ge:	@ (>= num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ pre-entry:	prdnml reduces input args over following predicate
_func_
geint:	@ >= for int
	eq	sv1, sv2
	bne	gtint
	set	pc,  lnk


	EPFUNC	i0, ordcnml, 0		@ primitive, init-sv4 = #i0, fentry = rdcnml, narg = listed
plus:	@ (+ num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (sum)
	@ pre-entry:	rdcnml reduces input args over following operation
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
	@ integer sum overflow, error out
	b	corerr


	EPFUNC	i1, ordcnml, 0		@ primitive, init-sv4 = #i1, fentry = rdcnml, narg = listed
produc: @ (* num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (product)
	@ pre-entry:	rdcnml reduces input args over following operation
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
	@ integer product overflow, error out
	b	corerr


	EPFUNC	i0, ordcnml, 0		@ primitive, init-sv4 = #i0, fentry = rdcnml, narg = listed
minus:	@ (- num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (diference)
	@ pre-entry:	rdcnml reduces input args over following operation
_func_
mnsint:	@ - for int
	ngint	sv2, sv2
	b	plsint


	EPFUNC	i1, ordcnml, 0		@ primitive, init-sv4 = #i1, fentry = rdcnml, narg = listed
divisi: @ (/ num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (division)
	@ pre-entry:	rdcnml reduces input args over following operation

.ifndef	cortex	@ integer division on arm v4T (arm7tdmi, arm920t)

idivid:	@ integer division:
	@ on entry:	sv1 <- dividand		(scheme int)
	@ on entry:	sv2 <- divisor		(scheme int)
	@ on exit:	sv1 <- quotient		(scheme int)
	@ on exit:	sv2 <- remainder	(scheme int)
	@ modifies:	sv1, sv2, rva, rvb, rvc
	izerop	sv2
	seteq	sv1, sv2
	beq	corerr
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

.else	@ integer division on cortex
	
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


quotie: @ (quotient int1 int2)
	@ on entry:	sv1 <- num1
	@ one entry:	sv2 <- num2
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	set	lnk, cnt		@ lnk <- return address
	izerop	sv2
	beq	corerr
	b	idivid			@ sv1 <- quotient, and return


remain: @ (remainder int1 int2)
	@ on entry:	sv1 <- (int1 int2)
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	izerop	sv2
	it	eq
	seteq	pc,  cnt
	bl	idivid			@ sv1 <- quotient, sv2 <- remainder
	set	sv1, sv2		@ sv1 <- remainder
	set	pc,  cnt		@ return


modulo: @ (modulo int1 int2)
	@ on entry:	sv1 <- (int1 int2)
	@ on exit:	sv1 <- result
	@ modifies:	sv1-sv5, rva, rvb
	set	sv4, sv2		@ sv4 <- divisor, saved
	bl	idivid			@ sv1 <- quotient, sv2 <- remainder
	postv	sv1			@ is quotient positive?
	itE	eq
	seteq	sv1, sv2		@	if so,  sv1 <- remainder
	plusne	sv1, sv2, sv4		@	if not, sv1 <- remainder + divisor
	set	pc,  cnt


/*------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.2.   Numbers
@  II.A.6.2.5  Numerical operations SUPPORT:	prdnml, rdcnml, idivid	
@-----------------------------------------------------------------------------*/


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
	adr	lnk, rdcncn		@ lnk <- return from operator
_func_	
rdcncn:	@ reduction loop
	@ on entry:	sv1 <- current/default result
	@ on entry:	sv4 <- list of numbers
	@ on entry:	sv5 <- function to apply to pairs of numbers
	@ preserves:	sv5    (functions called need to preserve sv4, sv5)
	nullp	sv4			@ is (num1 num2 ...) null?
	it	ne
	eqne	sv1, #f			@	if not, is sv1 = #f
	it	eq
	seteq	pc,  cnt		@	if so,  exit with result in sv1
	snoc	sv2, sv4, sv4		@ sv2 <- num1,			sv4 <- (num2 ...)
	set	pc,  sv5
	

/*------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.2.   Numbers
@  II.A.6.2.6. Numerical input and output CORE:	number->string, string->number
@-----------------------------------------------------------------------------*/


pnmstr:	@ (number->string number <radix>)
	@ on entry:	sv1 <- number, sv2 <- <radix>
	@ on exit:	sv1 <- string
numstr:	@ [internal entry]
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
	setne	sv1, #0x21		@	if not, sv1 <- 8 digs + 4 byte hdr for hex int (scheme int)
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
	beq	corerr
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

dg2asc:	@ digit to ascii
	set	rvc, lnk
	raw2int	sv2, rva
	bl	idiv10			@ rva <- rva / 10 = quotient
	lsl	rvb, rva, #1		@ rvb <- quotient * 2
	add	rvb, rvb, rva, LSL #3	@ rvb <- quotient * 10
	rsb	rvb, rvb, sv2, LSR #2	@ rvb <- original num minus 10*quotient = remainder (rightmost dig)
	add	rvb, rvb, #0x30		@ rvb <- remainder as ascii digit
	set	pc,  rvc


pstnum:	@ (string->number string <fmt>)
	@ on entry:	sv1 <- string, sv2 <- <fmt>
strnum:	@ [internal entry]
	strlen	sv3, sv1		@ sv3 <- number of digits (scheme int)
	set	sv5, #i0		@ sv5 <- offset of 1st char
strnen:	@ [internal re-entry]
	eq	sv5, sv3		@ done (no chars)?
	itT	eq
	seteq	sv1, #i0
	seteq	pc,  cnt		@	if so,  return
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
	bne	corerr
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
	beq	corerr
	set	sv2, sv5
strnlp:	bytref	rva, sv1, sv2		@ rva <- char
	eq	rva, #'/
	beq	corerr
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
	beq	corerr
	eq	rva, #'#
	itT	eq
	seteq	sv4, sv5		@	if so,  sv4 <- offset of dot
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
	b	corerr

/*------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.2.   Numbers
@  II.A.6.2.6. Numerical input and output SUPPORT:	lftshf, idiv10
@-----------------------------------------------------------------------------*/

.ifndef	cortex	@ 

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

.else	@ for cortex

_func_	
lftshf:	@ shift rva left until it starts with a 1, rvb has number of steps used to shift
	clz	rvb, rva
	lsl	rva, rva, rvb
	set	pc,  lnk

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


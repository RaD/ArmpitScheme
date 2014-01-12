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

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
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
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	8
scmplx:	.ascii	"complex?"

	SYMSIZE	5
sreal:	.ascii	"real?"

	SYMSIZE	9
sratio:	.ascii	"rational?"

	SYMSIZE	8
sinteg:	.ascii	"integer?"

	SYMSIZE	6
sexact:	.ascii	"exact?"

	SYMSIZE	8
sinxct:	.ascii	"inexact?"
	
	SYMSIZE	9
snmrtr:	.ascii	"numerator"

	SYMSIZE	11
sdnmnt:	.ascii	"denominator"

	SYMSIZE	5
sfloor:	.ascii	"floor"

	SYMSIZE	7
sceili:	.ascii	"ceiling"

	SYMSIZE	8
strunc:	.ascii	"truncate"

	SYMSIZE	5
sround:	.ascii	"round"

	SYMSIZE	3
sexp:	.ascii	"exp"

	SYMSIZE	3
slog:	.ascii	"log"

	SYMSIZE	3
ssin:	.ascii	"sin"

	SYMSIZE	3
scos:	.ascii	"cos"

	SYMSIZE	3
stan:	.ascii	"tan"

	SYMSIZE	4
sasin:	.ascii	"asin"

	SYMSIZE	4
sacos:	.ascii	"acos"

	SYMSIZE	4
satan:	.ascii	"atan"

	SYMSIZE	4
ssqrt:	.ascii	"sqrt"

	SYMSIZE	4
sexpt:	.ascii	"expt"

	SYMSIZE	16
smkrec:	.ascii	"make-rectangular"

	SYMSIZE	10
smkpol:	.ascii	"make-polar"

	SYMSIZE	9
srlpt:	.ascii	"real-part"

	SYMSIZE	9
simgpt:	.ascii	"imag-part"

	SYMSIZE	9
smagni:	.ascii	"magnitude"
	
	SYMSIZE	5
sangle:	.ascii	"angle"
	
	SYMSIZE	14
sex2in:	.ascii	"exact->inexact"

	SYMSIZE	14
sin2ex:	.ascii	"inexact->exact"

	SYMSIZE	3
zerof_:	.ascii	"0.0"

	SYMSIZE	4
inf___:	.ascii	"inf."

	SYMSIZE	4
nan___:	.ascii	"nan."


	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
number:	@ (number? obj)
cmplx:	@ (complex? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	@ jump table for number?
	.word	flsfxt			@ #f <- non-number
	.word	trufxt			@ #t <- integer
	.word	trufxt			@ #t <- float
	.word	trufxt			@ #t <- rational
	.word	trufxt			@ #t <- complex

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
real:	@ (real? obj)
ration:	@ (rational? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ jump table for real? and rational?
	.word	flsfxt			@ #f <- non-number
	.word	trufxt			@ #t <- integer
	.word	trufxt			@ #t <- float
	.word	trufxt			@ #t <- rational
	.word	flsfxt			@ #f <- complex

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
integr:	@ (integer? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ jump table for integer?
	.word	flsfxt			@ #f <- non-number
	.word	trufxt			@ #t <- integer
	.word	intflq			@ routine for float
	.word	flsfxt			@ #f <- rational
	.word	flsfxt			@ #f <- complex

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
exact:	@ (exact? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	@ jump table for exact?
	.word	flsfxt			@ #f <- non-number
	.word	trufxt			@ #t <- integer
	.word	flsfxt			@ #f <- float
	.word	trufxt			@ #t <- rational
	.word	flsfxt			@ #f <- complex

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
inxact:	@ (inexact? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	@ jump table for inexact?
	.word	flsfxt			@ #f <- non-number
	.word	flsfxt			@ #f <- integer
	.word	trufxt			@ #t <- float
	.word	flsfxt			@ #f <- rational
	.word	trufxt			@ #t <- complex

	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
eqn:	@ (= num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ jump table for =
	.word	corerr
	.word	eqnint
	.word	eqnflt
	.word	eqnrat
	.word	eqncpx

	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
lt:	@ (< num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
lttb:	@ jump table for <
	.word	corerr
	.word	ltint
	.word	ltflt
	.word	ltrat
	.word	corerr

	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
gt:	@ (> num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
gttb:	@ jump table for >
	.word	corerr
	.word	gtint
	.word	gtflt
	.word	gtrat
	.word	corerr
	
	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
le:	@ (<= num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ jump table for <=
	.word	corerr
	.word	leint
	.word	leflt
	.word	lerat
	.word	corerr

	EPFUNC	t, oprdnml, 0		@ primitive, init-sv4 = #t, fentry = prdnml, narg = listed
ge:	@ (>= num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- #t/#f
	@ jump table for >=
	.word	corerr
	.word	geint
	.word	geflt
	.word	gerat
	.word	corerr

	EPFUNC	i0, ordcnml, 0		@ primitive, init-sv4 = 0, fentry = rdcnml, narg = listed
plus:	@ (+ num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (sum)
plustb:	@ jump table for +
	.word	corerr
	.word	plsint
	.word	plsflt
	.word	plsrat
	.word	plscpx
			
	EPFUNC	i1, ordcnml, 0		@ primitive, init-sv4 = 1, fentry = rdcnml, narg = listed
produc: @ (* num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (product)
prodtb:	@ jump table for *
	.word	corerr
	.word	prdint
	.word	prdflt
	.word	prdrat
	.word	prdcpx
		
	EPFUNC	i0, ordcnml, 0		@ primitive, init-sv4 = 0, fentry = rdcnml, narg = listed
minus:	@ (- num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (diference)
minutb:	@ jump table for -
	.word	corerr
	.word	mnsint
	.word	mnsflt
	.word	mnsrat
	.word	mnscpx
			
	EPFUNC	i1, ordcnml, 0		@ primitive, init-sv4 = 1, fentry = rdcnml, narg = listed
divisi: @ (/ num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- result (division)
divitb:	@ jump table for /
	.word	corerr
	.word	makrat
	.word	divflt
	.word	divrat
	.word	divcpx

	EPFUNC	null, ounijmp, 2	@ primitive, init-sv4 = none, fentry = unijmp, narg = 2
quotie: @ (quotient int1 int2)
	@ on entry:	sv1 <- num1
	@ one entry:	sv2 <- num2
	@ on exit:	sv1 <- result
	@ jump table for quotient
	.word	corerr
	.word	quoint
	.word	quoflt
	.word	quorat
	.word	corerr

	EPFUNC	null, ounijmp, 2	@ primitive, init-sv4 = none, fentry = unijmp, narg = 2
remain: @ (remainder int1 int2)
	@ on entry:	sv1 <- (int1 int2)
	@ on exit:	sv1 <- result
	@ jump table for remainder
	.word	corerr
	.word	remint
	.word	remflt
	.word	remrat
	.word	corerr

modtbl:	@ jump table for modulo
	.word	corerr
	.word	modint
	.word	modflt
	.word	modrat
	.word	corerr

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
nmrtr:	@ (numerator q)
	@ on entry:	sv1 <- q
	@ on exit:	sv1 <- numerator of q
	@ jump table for numerator
	.word	corerr
	.word	return
	.word	nmrflt
	.word	nmrrat
	.word	corerr

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
dnmntr:	@ (denominator q)
	@ on entry:	sv1 <- q
	@ on exit:	sv1 <- denominator of q
	@ jump table for denominator
	.word	corerr
	.word	dnmint
	.word	dnmflt
	.word	dnmrat
	.word	corerr

fctrtb:	@ jump table for entry into floor, ceiling, truncate, round
	.word	error4			@ non-number
	.word	return			@ integer
	.word	fctflt			@ float
	.word	fctrat			@ rational
	.word	error4			@ complex

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
exp:	@ (exp number)
	@  89 or greater gives inf, -102 or smaller gives 0.0
exptb:	@ jump table for exp
	.word	nanfxt
	.word	expint
	.word	expflt
	.word	exprat
	.word	expcpx
expspc:	@ special returns table for exp
	.word	f1fxt			@ 1.0 <- (exp 0)
	.word	infxt			@ inf <- (exp inf)
	.word	f0fxt			@ 0.0 <- (exp -inf)

exptsc:	@ Taylor Series Coefficients (tsc) for exponential
.word	0x32D7322A	@ 0011-0010-1101-0111-0011-0010-0010-1010 (/ 39916800)	
.word	0x3493F27E	@ 0011-0100-1001-0011-1111-0010-0111-1110 (/ 3628800)
.word	0x3638EF1E	@ 0011-0110-0011-1000-1110-1111-0001-1110 (/ 362880)
.word	0x37D00D02	@ 0011-0111-1101-0000-0000-1101-0000-0010 (/ 40320)
.word	0x39500D02	@ 0011-1001-0101-0000-0000-1101-0000-0010 (/ 5040)
.word	0x3AB60B62	@ 0011-1010-1011-0110-0000-1011-0110-0010 (/ 720)
.word	0x3C08888A	@ 0011-1100-0000-1000-1000-1000-1000-1010 (/ 120
.word	0x3D2AAAAA	@ 0011-1101-0010-1010-1010-1010-1010-1010 (/ 24)
.word	0x3E2AAAAA	@ 0011-1110-0010-1010-1010-1010-1010-1010 (/ 6)
.word	0x3F000002	@ 0011-1111-0000-0000-0000-0000-0000-0010 (/ 2)
.word	scheme_one	@ 0011-1111-1000-0000-0000-0000-0000-0010 (/ 1)
.word	scheme_one	@ 0011-1111-1000-0000-0000-0000-0000-0010 (1)
.word	scheme_null	@ null == end

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
log:	@ (log number)
logtb:	@ jump table for log
	.word	nanfxt
	.word	logint
	.word	logflt
	.word	lograt
	.word	logcpx
logspc:	@ special returns table for log
	.word	ninfxt			@     -inf <- (log 0)
	.word	infxt			@      inf <- (log inf)
	.word	ipifxt			@ inf+pi.i <- (log -inf)

logtsc:	@ Taylor Series Coefficients (tsc) for log function
	.word	0x3D579436		@ 0011-1101-0101-0111-1001-0100-0011-0110 (/ 19)
	.word	0xBD638E3A		@ 1011-1101-0110-0011-1000-1110-0011-1010 (/ -18)
	.word	0x3D70F0F2		@ 0011-1101-0111-0000-1111-0000-1111-0010 (/ 17)
	.word	0xBD800002		@ 1011-1101-1000-0000-0000-0000-0000-0010 (/ -16)
	.word	0x3D88888A		@ 0011-1101-1000-1000-1000-1000-1000-1010 (/ 15)
	.word	0xBD924926		@ 1011-1101-1001-0010-0100-1001-0010-0110 (/ -14)
	.word	0x3D9D89DA		@ 0011-1101-1001-1101-1000-1001-1101-1010 (/ 13)
	.word	0xBDAAAAAA		@ 1011-1101-1010-1010-1010-1010-1010-1010 (/ -12)
	.word	0x3DBA2E8A		@ 0011-1101-1011-1010-0010-1110-1000-1010 (/ 11)
	.word	0xBDCCCCCE		@ 1011-1101-1100-1100-1100-1100-1100-1110 (/ -10)
	.word	0x3DE38E3A		@ 0011-1101-1110-0011-1000-1110-0011-1010 (/ 9)
	.word	0xBE000002		@ 1011-1110-0000-0000-0000-0000-0000-0010 (/ -8)
	.word	0x3E124926		@ 0011-1110-0001-0010-0100-1001-0010-0110 (/ 7)
	.word	0xBE2AAAAA		@ 1011-1110-0010-1010-1010-1010-1010-1010 (/ -6)
	.word	0x3E4CCCCE		@ 0011-1110-0100-1100-1100-1100-1100-1110 (/ 5)
	.word	0xBE800002		@ 1011-1110-1000-0000-0000-0000-0000-0010 (/ -4)
	.word	0x3EAAAAAA		@ 0011-1110-1010-1010-1010-1010-1010-1010 (/ 3)
	.word	0xBF000002		@ 1011-1111-0000-0000-0000-0000-0000-0010 (/ -2)
	.word	scheme_one		@ 0011-1111-1000-0000-0000-0000-0000-0010 (/ 1.0)
	.word	float_tag		@ 0000-0000-0000-0000-0000-0000-0000-0010 = 0.0
	.word	scheme_null		@ null == end

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
sin:	@ (sin angle)
sintb:	@ jump table for sin
	.word	nanfxt
	.word	sinint
	.word	sinflt
	.word	sinrat
	.word	sincpx
sinspc:	@ special returns table for sin
	.word	f0fxt			@ 0.0 <- (sin 0)
	.word	nanfxt			@ nan <- (sin inf)
	.word	nanfxt			@ nan <- (sin -inf)

sintsc:	@ Taylor Series Coefficients (tsc) for sine function
	.word	0x2F30922E		@ 0010-1111-0011-0000-1001-0010-0010-1110 (/ 13!)	
	.word	0xB2D7322A		@ 1011-0010-1101-0111-0011-0010-0010-1010 (/ -39916800)	
	.word	0x3638EF1E		@ 0011-0110-0011-1000-1110-1111-0001-1110 (/ 362880)
	.word	0xB9500D02		@ 1011-1001-0101-0000-0000-1101-0000-0010 (/ -5040)
	.word	0x3C08888A		@ 0011-1100-0000-1000-1000-1000-1000-1010 (/ 120
	.word	0xBE2AAAAA		@ 1011-1110-0010-1010-1010-1010-1010-1010 (/ -6)
	.word	scheme_one		@ 0011-1111-1000-0000-0000-0000-0000-0010 (/ 1.0)
	.word	scheme_null		@ null == end


	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
cos:	@ (cos angle)
costb:	@ jump table for cos
	.word	nanfxt
	.word	cosint
	.word	cosflt
	.word	cosrat
	.word	coscpx
	
	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
asin:	@ (asin number)	A.S. 4.4.46
asintb:	@ jump table for asin
	.word	nanfxt
	.word	asnint
	.word	asnflt
	.word	asnrat
	.word	asncpx
asnspc:	@ special returns table for asin
	.word	f0fxt			@ 0.0 <- (asin 0)
	.word	nanfxt			@ nan <- (asin inf)
	.word	nanfxt			@ nan <- (asin -inf)
	
asntsc:	@ Taylor Series Coefficients (tsc) for arcsine function
	.word	0xBAA57A2A		@ 1011-1010-1010-0101-0111-1010-0010-1010  -0.0012624911
	.word	0x3BDA90C6		@ 0011-1011-1101-1010-1001-0000-1100-0110   0.0066700901
	.word	0xBC8BFC66		@ 1011-1100-1000-1011-1111-1100-0110-0110  -0.0170881256
	.word	0x3CFD10FA		@ 0011-1100-1111-1101-0001-0000-1111-1010   0.0308918810
	.word	0xBD4D8392		@ 1011-1101-0100-1101-1000-0011-1001-0010  -0.0501743046
	.word	0x3DB63A9E		@ 0011-1101-1011-0110-0011-1010-1001-1110   0.0889789874
	.word	0xBE5BBFCA		@ 1011-1110-0101-1011-1011-1111-1100-1010  -0.2145988016
	.word	scheme_half_pi		@ pi/2
	.word	scheme_null		@ null == end


	EPFUNC	null, onumgto, 2	@ primitive, init-sv4 = none, fentry = numgto, narg = 2
atan:	@ (atan y <x>)
	@ jump table for atan
	.word	nanfxt
	.word	atnint
	.word	atnflt
	.word	atnrat
	.word	atncpx
atnspc:	@ special returns table for atan
	.word	pifxt			@    pi <- (atan 0), other case (0.0) dealt internally
	.word	p2fxt			@  pi/2 <- (atan inf)
	.word	np2fxt			@ -pi/2 <- (atan -inf)

atntsc:	@ Taylor Series Coefficients (tsc) for arctangent function
	.word	0x3B3BD74A		@ 0011-1011-0011-1011-1101-0111-0100-1010   0.0028662257
	.word	0xBC846E02		@ 1011-1100-1000-0100-0110-1110-0000-0010  -0.0161657367
	.word	0x3D2FC1FE		@ 0011-1101-0010-1111-1100-0001-1111-1110   0.0429096138
	.word	0xBD9A3176		@ 1011-1101-1001-1010-0011-0001-0111-0110  -0.0752896400
	.word	0x3DDA3D82		@ 0011-1101-1101-1010-0011-1101-1000-0010   0.1065626393
	.word	0xBE117FC6		@ 1011-1110-0001-0001-0111-1111-1100-0110  -0.1420889944
	.word	0x3E4CBBE6		@ 0011-1110-0100-1100-1011-1011-1110-0110   0.1999355085
	.word	0xBEAAAA6A		@ 1011-1110-1010-1010-1010-1010-0110-1010  -0.3333314528
	.word	scheme_one		@ one
	.word	scheme_null		@ null == end


	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
sqrt:	@ (sqrt number)
sqrttb:	@ jump table for sqrt
	.word	nanfxt
	.word	sqrint
	.word	sqrflt
	.word	sqrrat
	.word	sqrcpx
sqrspc:	@ special returns table for sqrt
	.word	f0fxt			@     0.0 <- (sqrt 0)
	.word	infxt			@     inf <- (sqrt inf)
	.word	ziifxt			@ 0+inf.i <- (sqrt -inf)
	
	EPFUNC	null, onumgto, 2	@ primitive, init-sv4 = none, fentry = numgto, narg = 2
makrec:	@ (make-rectangular x1 x2)
	@ on entry:	sv1 <- x1		(scheme float)
	@ on entry:	sv2 <- x2		(scheme float)
	@ on exit:	sv1 <- z = x1 + x2 i	(scheme complex)
	@ jump table for make-rectangular
	.word	corerr
	.word	mrcint
	.word	mrcflt
	.word	mrcrat
	.word	corerr

	EPFUNC	null, onumgto, 2	@ primitive, init-sv4 = none, fentry = numgto, narg = 2
makpol:	@ (make-polar x3 x4)
	@ on entry:	sv1 <- x3		(scheme float)
	@ on entry:	sv2 <- x4		(scheme float)
	@ on exit:	sv1 <- z = x3*e^(x4 i)	(scheme complex)
	@ jump table for make-polar
	.word	corerr
	.word	mpoint
	.word	mpoflt
	.word	mporat
	.word	corerr

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
realpt:	@ (real-part z)
	@ on entry:	sv1 <- z		(scheme complex)
	@ on exit:	sv1 <- real part of z	(scheme float)
	@ jump table for real-part
	.word	corerr
	.word	return
	.word	return
	.word	return
	.word	rptcpx

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
imagpt:	@ (imag-part z)
	@ on entry:	sv1 <- z		(scheme complex)
	@ on exit:	sv1 <- imag part of z	(scheme float)
	@ jump table for imag-part
	.word	corerr
	.word	i0fxt
	.word	f0fxt
	.word	i0fxt
	.word	imgcpx

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
magnit:	@ (magnitude z)
	@ on entry:	sv1 <- z		(scheme complex)
	@ on exit:	sv1 <- magnitude of z	(scheme float)
	@ jump table for magnitude
	.word	corerr
	.word	absint
	.word	absflt
	.word	absrat
	.word	magcpx
	
	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
angle:	@ (angle z)
	@ on entry:	sv1 <- z		(scheme complex)
	@ on exit:	sv1 <- angle of z	(scheme float)
	@ jump table for angle
	.word	nanfxt
	.word	angint
	.word	angflt
	.word	angrat
	.word	angcpx

	EPFUNC	null, onumgto, 1	@ primitive, init-sv4 = none, fentry = numgto, narg = 1
inx2ex:	@ (inexact->exact z)
	@ on entry:	sv1 <- z
	@ on exit:	sv1 <- exact version of z
inx2tb:	@ jump table for inexact->exact
	.word	corerr
	.word	return
	.word	i2eflt
	.word	return
	.word	corerr


unijtb:	@ jump table for numeric type conversions
	.word	i12rat, r22flt, i12flt, f12cpx
	.word	i22rat, r12flt, i22flt, f22cpx
	
unirtb:	@ return table (turns unijmp into uninum)
	.word	corerr
	.word	lnklnk
	.word	lnklnk
	.word	lnklnk
	.word	lnklnk








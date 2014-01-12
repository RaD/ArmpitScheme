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


	@-------.-------.-------.-------.-------+
@-------@	4.1. sub-environment		|
	@	4.1.2 literal expressns		|
	@	4.1.4 procedures		|
	@	4.1.5 conditionals		|
	@	4.1.6 assignments		|
	@-------.-------.-------.-------.-------+

		VECSIZE	(end_of_basenv - basenv) >> 2
basenv:

quote_env:
	DESYNTAX quote, 0, oreturn, 1		@ (quote expr)

lambda_env:
	DSYNTAX	lambda,	plmbda,	1		@ (lambda vars-list body)
if_env:
	DSYNTAX	if,	pif,	1		@ (if pred true-exp <false-exp>)
set_env:
	DSYNTAX	set,	pset,	2		@ (set! var exp)

	@-------.-------.-------.-------.-------+
	@	4.2. sub-environment		|
	@	4.2.3 sequencing		|
	@	4.2.6 quasiquotation		|
	@-------.-------.-------.-------.-------+

begin_env:
	DSYNTAX	begin,	sqnce,	0		@ (begin exp1 exp2 ...)
unquote_env:
	.word	unquote, scheme_true		@ unquote
unqtsplc_env:
	.word	unqtsplc, scheme_true		@ unquote-splicing
quasiquote_env:
	DSYNTAX	sqsqot,	pqsqot,	1		@ (quasiquote expr-list)

	@-------.-------.-------.-------.-------+
	@	4.3. sub-environment		|
	@	4.3.2. pattern language		|
	@-------.-------.-------.-------.-------+

.ifndef r3rs

	DSYNTAX	letsyn,	splet,	1	@ (let-syntax bindings-list exp1 exp2 ...)
	DSYNTAX	ltrsyn,	spletr,	1	@ (letrec-syntax bindings-list exp1 exp2 ...)
synt_rules_env:
	DSYNTAX	synrls,	sntxrl,	0	@ (syntax-rules	literals rule1 ...)
ellipsis_env:
	.word	ellipsis, scheme_true	@ ...		4.3.c. constants
underscore_env:
	.word	underscore, scheme_true	@ _
	DSYNTAX	expand,	pmxpnd,	1	@ (expand expr)	4.3.s.	support
	DSYNTAX	smatch,	pmatch,	4	@ (match expr pat bndngs lits)
	DSYNTAX	substt,	psubst,	2	@ (substitute bindings template)

.endif
	
	@-------.-------.-------.-------.-------+
	@	5.2 definitions			|
	@	5.3 syntax definition		|
	@-------.-------.-------.-------.-------+

define_env:
	DSYNTAX	def,	pdefin,	1		@ (define var exp)
	DSYNTAX	defsyn,	pdefin,	1		@ (define-syntax var rules)

	@-------.-------.-------.-------.-------+
	@	6.1. sub-environment		|
	@-------.-------.-------.-------.-------+

	DPFUNC	seqv,	peq,	2		@ (eq? obj1 obj2)
	DPFUNC	seq,	peq,	2		@ (eqv? obj1 obj2)
	DPFUNC	sequal,	pequal,	2		@ (equal? obj1 obj2)
	
	@-------.-------.-------.-------.-------+
	@	6.2. sub-environment		|
	@-------.-------.-------.-------.-------+

.ifdef	integer_only
	DEPFUNC	snumbe,	iint, otypchk,1	@ (number? obj)
.else
	.word	snumbe,	number		@ (number? obj)
.endif
	.word	seqn,	eqn		@ (=  num1 num2 ...)
	.word	slt,	lt		@ (<  num1 num2 ...)
	.word	sgt,	gt		@ (>  num1 num2 ...)
	.word	sle,	le		@ (<= num1 num2 ...)
	.word	sge,	ge		@ (>= num1 num2 ...)
plus_env:
	.word	splus,	plus		@ (+  num1 num2 ...)
	.word	sprodu,	produc		@ (*  num1 num2 ...)
	.word	sminus,	minus		@ (-  num1 num2 ...)
	.word	sdivis,	divisi		@ (/  num1 num2 ...)

.ifdef	integer_only
	DPFUNC	squoti,	quotie,	2	@ (quotient  int1 int2)
	DPFUNC	sremai,	remain,	2	@ (remainder int1 int2)
	DPFUNC	smodul,	modulo,	2	@ (modulo    int1 int2)
.else
	.word	squoti,	quotie		@ (quotient  num1 num2)
	.word	sremai,	remain		@ (remainder num1 num2)
	DPFUNC	smodul,	modulo,	2	@ (modulo    num1 num2)
	.word	scmplx,	cmplx		@ (complex?  obj)
	.word	sreal,	real		@ (real?     obj)
	.word	sratio,	ration		@ (rational? obj)
	.word	sinteg,	integr		@ (integer?  obj)
	.word	sexact,	exact		@ (exact?    obj)
	.word	sinxct,	inxact		@ (inexact?  obj)
	.word	snmrtr,	nmrtr		@ (numerator   q)
	.word	sdnmnt,	dnmntr		@ (denominator q)
	DPFUNC	sfloor,	floor,	1	@ (floor    number)
	DPFUNC	sceili,	ceilin,	1	@ (ceiling  number)
	DPFUNC	strunc,	trunca,	1	@ (truncate number)
	DPFUNC	sround,	round,	1	@ (round    number)
	.word	sexp,	exp		@ (exp number)
	.word	slog,	log		@ (log number)
	.word	ssin,	sin		@ (sin angle)
	.word	scos,	cos		@ (cos angle)
	DPFUNC	stan,	tan,	1	@ (tan angle)
	.word	sasin,	asin		@ (asin number)
	DPFUNC	sacos,	acos,	1	@ (acos z)
	.word	satan,	atan		@ (atan y <x>)
	.word	ssqrt,	sqrt		@ (sqrt number)
	DPFUNC	sexpt,	expt,	2	@ (expt z1 z2)
	.word	smkrec,	makrec		@ (make-rectangular x1 x2)
	.word	smkpol,	makpol		@ (make-polar x3 x4)
	.word	srlpt,	realpt		@ (real-part z)
	.word	simgpt,	imagpt		@ (imag-part z)
	.word	smagni,	magnit		@ (magnitude z)
	.word	sangle,	angle		@ (angle     z)
	DPFUNC	sex2in,	ex2inx,	1	@ (exact->inexact z)
	.word	sin2ex,	inx2ex		@ (inexact->exact z)
.endif	@ .ifdef integer_only

	DPFUNC	snmstr,	pnmstr,	2	@ (number->string number <radix>)
	DPFUNC	sstnum,	pstnum,	2	@ (string->number string <fmt>)

	@-------.-------.-------.-------.-------+
	@	6.3.2. sub-environment		|
	@-------.-------.-------.-------.-------+

	DPFUNC	pair,	ppair,	1		@ (pair? object)
cons_env:
	DPFUNC	scons,	pcons,	2		@ (cons item1 item2)
	DPFUNC	car,	pcar,	1		@ (car list)
	DPFUNC	cdr,	pcdr,	1		@ (cdr list)
	DPFUNC	setcar,	pstcar,	2		@ (set-car! pair obj)
	DPFUNC	setcdr,	pstcdr,	2		@ (set-cdr! pair obj)

	@-------.-------.-------.-------.-------+
	@	6.3.3. symbols			|
	@-------.-------.-------.-------.-------+

	DEPFUNC	symbol, ivar, 	otypchk, 1	@ (symbol? object)
	DPFUNC	ssmstr,	psmstr,	1		@ (symbol->string symbol)
	DPFUNC	sstsym,	pstsym,	1		@ (string->symbol string)

	@-------.-------.-------.-------.-------+
	@	6.3.4. characters		|
	@-------.-------.-------.-------.-------+

	DEPFUNC	char, 	ichr, 	otypchk, 1	@ (char? object)
	DPFUNC	chareq,	pcheq,	2		@ (char=? char1 char2)
	DPFUNC	charlt,	pchlt,	2		@ (char<? char1 char2)
	DPFUNC	chargt,	pchgt,	2		@ (char>? char1 char2)
	DPFUNC	charle,	pchle,	2		@ (char<=? char1 char2)
	DPFUNC	charge,	pchge,	2		@ (char>=? char1 char2)
	DPFUNC	chrint,	pchint,	1		@ (char->integer char)
	DPFUNC	intchr,	pintch,	1		@ (integer->char int)

	@-------.-------.-------.-------.-------+
	@	6.3.5. strings			|
	@-------.-------.-------.-------.-------+

	DEPFUNC	sqstng, istr, 	otypchk, 1	@ (string? object)
	DPFUNC	smakst,	makstr,	2		@ (make-string k <char>)
	DPFUNC	sstlen,	strlen,	1		@ (string-length string)
	DPFUNC	sstref,	strref,	2		@ (string-ref string k)
	DPFUNC	sstset,	strset,	3		@ (string-set! string k char)

	@-------.-------.-------.-------.-------+
	@	6.3.6. vectors			|
	@-------.-------.-------.-------.-------+

	DEPFUNC	sqvect, ivec, 	otypchk, 1	@ (vector? object)
	DPFUNC	smkvec,	pmkvec,	1		@ (make-vector size <fill>)
	DPFUNC	svclen,	veclen,	1		@ (vector-length vector)
	DPFUNC	svcref,	vecref,	2		@ (vector-ref vector k)
	DPFUNC	svcset,	vecset,	3		@ (vector-set! vector k item)

	@-------.-------.-------.-------.-------+
	@	6.4. control features		|
	@-------.-------.-------.-------.-------+

	DEPFUNC	sprocd, iprc, 	otypchk, 1	@ (procedure?
	DPFUNC	sapply,	papply,	1		@ (apply fun arg1 ... args)
	DPFUNC	scllcc,	callcc,	1		@ (call/cc procedure)
	DPFUNC	scwcc,	callcc,	1		@ (call-with-current-continuation procedure)

.ifndef r3rs

	DEPFUNC	svalus,	null, 	oreturn, 0	@ (values obj ...)
	DPFUNC	scllwv,	callwv,	2		@ (call-with-values producer consumer)
	DPFUNC	sdnwnd,	dynwnd,	3		@ (dynamic-wind before thunk after)

.endif

	@-------.-------.-------.-------.-------+
	@	6.5. eval			|
	@-------.-------.-------.-------.-------+

	DPFUNC	seval,	peval,	2		@ (eval expr env)
	DPFUNC	sscenv,	screnv,	1		@ (scheme-report-environment version)
	DPFUNC	snlenv,	nulenv,	1		@ (null-environment version)
	DPFUNC	sinenv,	pinenv,	0		@ (interaction-environment)

	@-------.-------.-------.-------.-------+
	@	6.6. ports, input, output	|
	@-------.-------.-------.-------.-------+
	
	.word	sinpor,	inport			@ (input-port? obj ...)
	DPFUNC	soutpr,	outprt,	0		@ (output-port? obj ...)
curinport_env:
	DPFUNC	scripr,	criprt,	0		@ (current-input-port)
curoutport_env:
	DPFUNC	scropr,	croprt,	0		@ (current-output-port)
	DPFUNC	sopnif,	opnifl,	2		@ (open-input-file  filename <port-model>)
	DPFUNC	sopnof,	opnofl,	2		@ (open-output-file filename <port-model>)
	.word	sclsip,	clsipr			@ (close-input-port  port ...)
	DPFUNC	sclsop,	clsopr,	0		@ (close-output-port port <model>)
	DEPFUNC	sredch,	(0x22<<2)|i0, oioprfn,0	@ (read-char <port> <reg> <n>)
	DEPFUNC	spekch,	(0x22<<2)|f0, oioprfn,0	@ (peek-char <port> <reg> <n>)
	DPFUNC	seofob,	eofobj,	1		@ (eof-object? object)
	DEPFUNC	schrdy,	(0x23<<2)|i0, oioprfn,0	@ (char-ready? <port> <reg> <n>)
	DEPFUNC	swrtch,	(0x02<<2)|i0, oioprfn,1	@ (write-char char <port> <reg> <n> ...)

	@-------.-------.-------.-------.-------+
	@	addendum sub-environment	|
	@-------.-------.-------.-------.-------+

	DPFUNC	sunloc,	unlock,	0	@ (unlock)
	DPFUNC	sfiles,	files,	1	@ (files <port-model>)
.ifndef	live_SD	
	DPFUNC	serase,	erase,	0	@ (erase <sector>|<-1>)
	DPFUNC	sfpgwr,	fpgwrt,	2	@ (fpgw pseudo-file-descriptor file-flash-page)
.endif
.ifdef	onboard_SDFT
	DPFUNC	ssdini,	psdini,	0	@ (sd-init)
.endif

end_of_basenv:	@ end of basenv

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\

		CONSTANTS

\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

.macro	make_var_from_basenv var_name, var_env
	\var_name =((\var_env-basenv+4)<<13)|((base_env-scmenv)<<6)|variable_tag
.endm


	make_var_from_basenv	plus_var,	plus_env
	make_var_from_basenv	cons_var,	cons_env


	@-------.-------.-------.-------.-------+
@-------@	4.1. Constants			|
	@-------.-------.-------.-------.-------+

	make_var_from_basenv	define_var,	define_env
	make_var_from_basenv	lambda_var,	lambda_env
	make_var_from_basenv	set_var,	set_env
	make_var_from_basenv	quote_var,	quote_env
	make_var_from_basenv	if_var,		if_env

	@-------.-------.-------.-------.-------+
@-------@	4.2. Constants			|
	@-------.-------.-------.-------.-------+

	make_var_from_basenv	begin_var,	begin_env
	make_var_from_basenv	unquote_var,	unquote_env
	make_var_from_basenv	unqtsplc_var,	unqtsplc_env
	make_var_from_basenv	quasiquote_var,	quasiquote_env

	@-------.-------.-------.-------.-------+
@-------@	4.3. Constants			|
	@-------.-------.-------.-------.-------+
	
.ifndef r3rs

	make_var_from_basenv	synt_rules_var,	synt_rules_env
	make_var_from_basenv	ellipsis_var,	ellipsis_env
	make_var_from_basenv	underscore_var,	underscore_env

.endif
	
	@-------.-------.-------.-------.-------+
@-------@	6.6. Constants			|
	@-------.-------.-------.-------.-------+

	make_var_from_basenv	curinport_var,	curinport_env
	make_var_from_basenv	curoutport_var,	curoutport_env


/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\

		SYMBOLS

\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	4.1.	Primitive expression types:	quote, lambda, if, set!
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	5
quote:	.ascii	"quote"

	SYMSIZE	6
lambda:	.ascii	"lambda"

	SYMSIZE	2
if:	.ascii	"if"

	SYMSIZE	4
set:	.ascii	"set!"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	4.2.3.	sequencing:		begin
	4.2.6.	quasiquotation:		unquote, unquote-splicing, quasiquote
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	5
begin:	.ascii	"begin"

	SYMSIZE	10
sqsqot:	.ascii	"quasiquote"

	SYMSIZE	7
unquote: .ascii	"unquote"

	SYMSIZE	16
unqtsplc: .ascii "unquote-splicing"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	4.3.1.	binding constructs for syntactic keywords:
					let-syntax, letrec-syntax
	4.3.2.	Pattern language:	syntax-rules
	4.3.c.	constants:		..., _
	4.3.s.	support:		expand, match, substitute
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

.ifndef r3rs				@ /--------if--------\

	SYMSIZE	10
letsyn:	.ascii	"let-syntax"

	SYMSIZE	13
ltrsyn:	.ascii	"letrec-syntax"

	SYMSIZE	12
synrls:	.ascii	"syntax-rules"

	SYMSIZE	3
ellipsis: .ascii	"..."		@ ... (variable)

	SYMSIZE	1
underscore: .ascii	"_"		@ _ (variable)

	SYMSIZE	6
expand:	.ascii	"expand"

	SYMSIZE	5
smatch:	.ascii	"match"

	SYMSIZE	10
substt:	.ascii	"substitute"


.endif					@ \______endif_______/
	
/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	5.2.	Definitions:		define
	5.3.	syntax definitions:	define-syntax
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	6
def:	.ascii	"define"
	
	SYMSIZE	13
defsyn:	.ascii	"define-syntax"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.	Standard Procedures
	6.1.	Equivalence predicates:	eq?, eqv?, equal?
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	4
seqv:	.ascii	"eqv?"

	SYMSIZE	3
seq:	.ascii	"eq?"

	SYMSIZE	6
sequal:	.ascii	"equal?"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\

  INTEGER ONLY:

	6.2.5	Numerical operations:	number?, =, <, >, <=, >=, +, *, -, /,
					quotient, remainder, modulo
	6.2.6	Numerical input output:	number->string, string->number

  GENERAL NUMBERS:

	6.2.5	Numerical operations:	number?, complex?, real?, rational?,
					integer?,
					exact?, inexact?
					=, <, >, <=, >=, +, *, -, /,
					quotient, remainder, modulo,
					numerator, denominator
					floor, ceiling, truncate, round,
					exact->inexact, inexact->exact
					zero?, positive?, negative?, odd?,
					even?, max, min, abs, 
					gcd, lcm, rationalize
	6.2.6	Numerical input output:	number->string, string->number
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	7
snumbe:	.ascii	"number?"

	SYMSIZE	1
seqn:	.ascii	"="

	SYMSIZE	1
slt:	.ascii	"<"

	SYMSIZE	1
sgt:	.ascii	">"

	SYMSIZE	2
sle:	.ascii	"<="

	SYMSIZE	2
sge:	.ascii	">="

	SYMSIZE	1
splus:	.ascii	"+"

	SYMSIZE	1
sprodu:	.ascii	"*"

	SYMSIZE	1
sminus:	.ascii	"-"

	SYMSIZE	1
sdivis:	.ascii	"/"

	SYMSIZE	8
squoti:	.ascii	"quotient"

	SYMSIZE	9
sremai:	.ascii	"remainder"

	SYMSIZE	6
smodul:	.ascii	"modulo"

	SYMSIZE	14
snmstr:	.ascii	"number->string"

	SYMSIZE	14
sstnum:	.ascii	"string->number"

.ifndef	integer_only			@ /--------if--------\

	.include "armpit_scheme_base_6.2.Numbers_data.s"

.endif					@ \______endif_______/

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.3.2.	Pairs and list:		pair?, cons, car, cdr, set-car!,
					set-cdr!
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	5
pair:	.ascii	"pair?"

	SYMSIZE	4
scons:	.ascii	"cons"

	SYMSIZE	3
car:	.ascii	"car"

	SYMSIZE	3
cdr:	.ascii	"cdr"

	SYMSIZE	8
setcar:	.ascii	"set-car!"

	SYMSIZE	8
setcdr:	.ascii	"set-cdr!"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.3.3.	Symbols:		symbol?, symbol->string, string->symbol
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	7
symbol:	.ascii	"symbol?"

	SYMSIZE	14
ssmstr:	.ascii	"symbol->string"

	SYMSIZE	4
undef_:	.ascii	"#<?>"

	SYMSIZE	14
sstsym:	.ascii	"string->symbol"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.3.4.	Characters:		char?, char=?, char<?, char>?, char<=?,
					char>=?, char->integer, integer->char
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	5
char:	.ascii	"char?"

	SYMSIZE	6
chareq:	.ascii	"char=?"

	SYMSIZE	6
charlt:	.ascii	"char<?"

	SYMSIZE	6
chargt:	.ascii	"char>?"

	SYMSIZE	7
charle:	.ascii	"char<=?"

	SYMSIZE	7
charge:	.ascii	"char>=?"

	SYMSIZE	13
chrint:	.ascii	"char->integer"

	SYMSIZE	13
intchr:	.ascii	"integer->char"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.3.5.	Strings:		string?, make-string, string-length,
					string-ref, string-set!
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	7
sqstng:	.ascii	"string?"

	SYMSIZE	11
smakst:	.ascii	"make-string"

	SYMSIZE	13
sstlen:	.ascii	"string-length"

	SYMSIZE	10
sstref:	.ascii	"string-ref"

	SYMSIZE	11
sstset:	.ascii	"string-set!"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.3.6.	Vectors:		vector?, make-vector, vector-length,
					vector-ref, vector-set!
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	7
sqvect:	.ascii	"vector?"

	SYMSIZE	11
smkvec:	.ascii	"make-vector"

	SYMSIZE	13
svclen:	.ascii	"vector-length"

	SYMSIZE	10
svcref:	.ascii	"vector-ref"

	SYMSIZE	11
svcset:	.ascii	"vector-set!"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.4.	control features:	procedure?, apply, call/cc,
					call-with-current-continuation, values,
					call-with-values, dynamic-wind
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	10
sprocd:	.ascii	"procedure?"

	SYMSIZE	5
sapply:	.ascii	"apply"

	SYMSIZE	7
scllcc:	.ascii	"call/cc"

	SYMSIZE	30
scwcc:	.ascii	"call-with-current-continuation"

.ifndef r3rs				@ /--------if--------\

	SYMSIZE	6
svalus:	.ascii	"values"

	SYMSIZE	16
scllwv:	.ascii	"call-with-values"

	SYMSIZE	12
sdnwnd:	.ascii	"dynamic-wind"

.endif					@ \______endif_______/

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.5.	eval:			eval, scheme-report-environment,
					null-environment,
					interaction-environment
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	4
seval:	.ascii	"eval"

	SYMSIZE	25
sscenv:	.ascii	"scheme-report-environment"

	SYMSIZE	16
snlenv:	.ascii	"null-environment"

	SYMSIZE	23
sinenv:	.ascii	"interaction-environment"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.6.1.	ports:			input-port?, output-port?,
					current-input-port, current-output-port,
					open-input-file, open-output-file,
					close-input-port, close-output-port
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	11
sinpor:	.ascii	"input-port?"

	SYMSIZE	12
soutpr:	.ascii	"output-port?"

	SYMSIZE	18
scripr:	.ascii	"current-input-port"

	SYMSIZE	19
scropr:	.ascii	"current-output-port"

	SYMSIZE	15
sopnif:	.ascii	"open-input-file"

	SYMSIZE	16
sopnof:	.ascii	"open-output-file"

	SYMSIZE	16
sclsip:	.ascii	"close-input-port"

	SYMSIZE	17
sclsop:	.ascii	"close-output-port"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	6.6.2.	input:			read-char, peek-char,
					eof-object?, char-ready?
	6.6.3.	output:			write-char
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	9
sredch:	.ascii	"read-char"

	SYMSIZE	9
spekch:	.ascii	"peek-char"

	SYMSIZE	11
seofob:	.ascii	"eof-object?"

	SYMSIZE	11
schrdy:	.ascii	"char-ready?"

	SYMSIZE	10
swrtch:	.ascii	"write-char"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*\
	7.	Addendum:		erase, fpgw, unlock, files, sd-init
\*======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

.ifndef	live_SD				@ /--------if--------\

	SYMSIZE	5
serase:	.ascii	"erase"

	SYMSIZE	4
sfpgwr:	.ascii	"fpgw"

.endif					@ \______endif_______/

	SYMSIZE	6
sunloc:	.ascii	"unlock"

	SYMSIZE	5
sfiles:	.ascii	"files"

.ifdef	onboard_SDFT			@ /--------if--------\

	SYMSIZE	7
ssdini:	.ascii	"sd-init"

.endif					@ \______endif_______/



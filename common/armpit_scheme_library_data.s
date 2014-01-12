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
	@	4.2. sub-environment		|
	@-------.-------.-------.-------.-------+

		VECSIZE	(end_of_libenv - libenv) >> 2
libenv:

.ifndef	r3rs

cond_env:	.word	cond,	pcond		@ cond		4.2.1 conditionals
case_env:	.word	case,	pcase		@ case
and_env:	.word	and,	pand		@ and
or_env:		.word	or,	por		@ or
let_env:	.word	let,	plet		@ let		4.2.2 binding constructs
lets_env:	.word	lets,	plets		@ let*
letrec_env:	.word	letr,	pletr		@ letrec
do_env:		.word	do,	pdo		@ do		4.2.4 iteration
		.word	delay,	pdelay		@ delay		4.2.5 delayed evaluation

.else

cond_env:	DSYNTAX	cond,	pcond,	0	@ cond		4.2.1 conditionals
case_env:	DSYNTAX	case,	pcase,	1	@ case
and_env:	DSYNTAX	and,	pand,	0	@ and
or_env:		DSYNTAX	or,	por,	0	@ or
let_env:	DSYNTAX	let,	plet,	1	@ let		4.2.2 binding constructs
lets_env:	DSYNTAX	lets,	plets,	1	@ let*
letrec_env:	DSYNTAX	letr,	pletr,	1	@ letrec
do_env:		DSYNTAX	do,	pdo,	2	@ do		4.2.4 iteration
		DSYNTAX	delay,	pdelay,	0	@ delay		4.2.5 delayed evaluation

.endif

mkprms_env:	DPFUNC	mkp,	mkprms,	1	@ _mkp			(make-promise)
else_env:	.word	else,	scheme_true	@ else		4.2.c constants
implies_env:	.word	implies, scheme_true	@ =>
var0_env:	.word	var0,	scheme_true	@ var0
		.word	var1,	scheme_true	@ var1
		.word	var2,	scheme_true	@ var2
		.word	var3,	scheme_true	@ var3
		.word	var4,	scheme_true	@ var4
		.word	var5,	scheme_true	@ var5
		.word	var6,	scheme_true	@ var6

	@-------.-------.-------.-------.-------+
	@	6.2. sub-environment		|
	@-------.-------.-------.-------.-------+

.ifdef	integer_only
	DPFUNC	szero,	zero,	1	@ zero?
	DPFUNC	sposit,	positi,	1	@ positive?
	DPFUNC	snegat,	negati,	1	@ negative?
	DPFUNC	sodd,	odd,	1	@ odd?
	DPFUNC	seven,	even,	1	@ even?
	.word	smax,	max		@ max
	.word	smin,	min		@ min
	DPFUNC	sabs,	abs,	1	@ abs
	.word	sgcd,	gcd		@ gcd
	.word	slcm,	lcm		@ lcm
.else
	DPFUNC	szero,	zero,	1	@ zero?
	.word	sposit,	positi		@ positive?
	.word	snegat,	negati		@ negative?
	DPFUNC	sodd,	odd,	1	@ odd?
	DPFUNC	seven,	even,	1	@ even?
	.word	smax,	max		@ max
	.word	smin,	min		@ min
	.word	sabs,	abs		@ abs
	.word	sgcd,	gcd		@ gcd
	.word	slcm,	lcm		@ lcm	
	.word	srtnlz,	rtnlz		@ rationalize
.endif
	
	@-------.-------.-------.-------.-------+
	@	6.3.1. sub-environment		|
	@-------.-------.-------.-------.-------+

	DEPFUNC	not,	inot, otypchk,1	@ not
	DPFUNC	booln,	pbooln,	1	@ boolean?

	@-------.-------.-------.-------.-------+
	@	6.3.2. sub-environment		|
	@-------.-------.-------.-------.-------+

	DEPFUNC	caar,   (0x04<<2)|i0, ocxxxxr,1	@ caar
	DEPFUNC	cadr,   (0x05<<2)|i0, ocxxxxr,1	@ cadr
	DEPFUNC	cdar,   (0x06<<2)|i0, ocxxxxr,1	@ cdar
	DEPFUNC	cddr,   (0x07<<2)|i0, ocxxxxr,1	@ cddr
	DEPFUNC	caaar,  (0x08<<2)|i0, ocxxxxr,1	@ caaar
	DEPFUNC	caadr,  (0x09<<2)|i0, ocxxxxr,1	@ caadr
	DEPFUNC	cadar,  (0x0A<<2)|i0, ocxxxxr,1	@ cadar
	DEPFUNC	caddr,  (0x0B<<2)|i0, ocxxxxr,1	@ caddr
	DEPFUNC	cdaar,  (0x0C<<2)|i0, ocxxxxr,1	@ cdaar
	DEPFUNC	cdadr,  (0x0D<<2)|i0, ocxxxxr,1	@ cdadr
	DEPFUNC	cddar,  (0x0E<<2)|i0, ocxxxxr,1	@ cddar
	DEPFUNC	cdddr,  (0x0F<<2)|i0, ocxxxxr,1	@ cdddr
	DEPFUNC	caaaar, (0x10<<2)|i0, ocxxxxr,1	@ caaaar
	DEPFUNC	caaadr, (0x11<<2)|i0, ocxxxxr,1	@ caaadr
	DEPFUNC	caadar, (0x12<<2)|i0, ocxxxxr,1	@ caadar
	DEPFUNC	caaddr, (0x13<<2)|i0, ocxxxxr,1	@ caaddr
	DEPFUNC	cadaar, (0x14<<2)|i0, ocxxxxr,1	@ cadaar
	DEPFUNC	cadadr, (0x15<<2)|i0, ocxxxxr,1	@ cadadr
	DEPFUNC	caddar, (0x16<<2)|i0, ocxxxxr,1	@ caddar
	DEPFUNC	cadddr, (0x17<<2)|i0, ocxxxxr,1	@ cadddr
	DEPFUNC	cdaaar, (0x18<<2)|i0, ocxxxxr,1	@ cdaaar
	DEPFUNC	cdaadr, (0x19<<2)|i0, ocxxxxr,1	@ cdaadr
	DEPFUNC	cdadar, (0x1A<<2)|i0, ocxxxxr,1	@ cdadar
	DEPFUNC	cdaddr, (0x1B<<2)|i0, ocxxxxr,1	@ cdaddr
	DEPFUNC	cddaar, (0x1C<<2)|i0, ocxxxxr,1	@ cddaar
	DEPFUNC	cddadr, (0x1D<<2)|i0, ocxxxxr,1	@ cddadr
	DEPFUNC	cdddar, (0x1E<<2)|i0, ocxxxxr,1	@ cdddar
	DEPFUNC	cddddr, (0x1F<<2)|i0, ocxxxxr,1	@ cddddr
	DEPFUNC	snull,	inul,	otypchk, 1	@ (null? obj)
	DPFUNC	listp,	plistp,	1		@ (list? obj)
	DEPFUNC	list,	null,	oreturn, 0	@ (list item1 item2 ...)
	DPFUNC	slngth,	plngth,	1		@ (length list)
	DPFUNC	append,	pappnd,	0		@ (append list1 list2 ...)
	DPFUNC	srevrs,	prevrs,	1		@ (reverse list)
	DPFUNC	lstail,	plstal,	2		@ (list-tail list k)
	DPFUNC	lstref,	plstrf,	2		@ (list-ref  list k)
memv_env:
	DPFUNC	smemv,	pmemv,	2		@ (memv   obj list)
	DPFUNC	memq,	pmemv,	2		@ (memq   obj list)
	DPFUNC	member,	pmembr,	2		@ (member obj list)
	DPFUNC	sassq,	passq,	2		@ (assq   obj alist)
	DPFUNC	sassv,	passq,	2		@ (assv   obj alist)
	DPFUNC	assoc,	passoc,	2		@ (assoc  key binding-list)

	@-------.-------.-------.-------.-------+
	@	6.3.4. sub-environment		|
	@-------.-------.-------.-------.-------+

	DPFUNC	chrceq,	pchceq,	2	@ (char-ci=?  char1 char2)
	DPFUNC	chrclt,	pchclt,	2	@ (char-ci<?  char1 char2)
	DPFUNC	chrcgt,	pchcgt,	2	@ (char-ci>?  char1 char2)
	DPFUNC	chrcle,	pchcle,	2	@ (char-ci<=? char1 char2)
	DPFUNC	chrcge,	pchcge,	2	@ (char-ci>=? char1 char2)
	DPFUNC	chralp,	pchalp,	1	@ (char-alphabetic? char)
	DPFUNC	chrnum,	pchnum,	1	@ (char-numeric?    char)
	DPFUNC	chrspa,	pchspa,	1	@ (char-whitespace? char)
	DPFUNC	chrupq,	pchupq,	1	@ (char-upper-case? char)
	DPFUNC	chrloq,	pchloq,	1	@ (char-lower-case? char)
	DPFUNC	chrupc,	pchupc,	1	@ (char-upcase      char)
	DPFUNC	chrdnc,	pchdnc,	1	@ (char-downcase    char)

	@-------.-------.-------.-------.-------+
	@	6.3.5. sub-environment		|
	@-------.-------.-------.-------.-------+

	DPFUNC	spstng,	pstrng,	0	@ (string        char1 char2 ...)
	DPFUNC	sstequ,	strequ,	2	@ (string=?      string1 string2)
	DPFUNC	sstceq,	strceq,	2	@ (string-ci=?   string1 string2)
	DPFUNC	sstlt,	strlt,	2	@ (string<?      string1 string2)
	DPFUNC	sstgt,	strgt,	2	@ (string>?      string1 string2)
	DPFUNC	sstle,	strle,	2	@ (string<=?     string1 string2)
	DPFUNC	sstge,	strge,	2	@ (string>=?     string1 string2)
	DPFUNC	sstclt,	strclt,	2	@ (string-ci<?   string1 string2)
	DPFUNC	sstcgt,	strcgt,	2	@ (string-ci>?   string1 string2)
	DPFUNC	sstcle,	strcle,	2	@ (string-ci<=?  string1 string2)
	DPFUNC	sstcge,	strcge,	2	@ (string-ci>=?  string1 string2)
	DPFUNC	ssubst,	substr,	3	@ (substring     string start end)
	DPFUNC	sstapp,	strapp,	0	@ (string-append st1 st2 ...)
	DPFUNC	sstlst,	strlst,	1	@ (string->list  string)
	DPFUNC	slstst,	lststr,	1	@ (list->string  list)
	DPFUNC	sstcpy,	strcpy,	1	@ (string-copy   string)
	DPFUNC	sstfil,	strfil,	2	@ (string-fill   string char)

	@-------.-------.-------.-------.-------+
	@	6.3.6. sub-environment		|
	@-------.-------.-------.-------.-------+

	DPFUNC	svctor,	vector,	0	@ (vector       item1 item2 ...)
	DPFUNC	svclst,	pvclst,	1	@ (vector->list vector)
	DPFUNC	slsvec,	plsvec,	1	@ (list->vector list)
	DPFUNC	svcfll,	pvcfll,	2	@ (vector-fill

	@-------.-------.-------.-------.-------+
	@	6.4. sub-environment		|
	@-------.-------.-------.-------.-------+

	DPFUNC	smap,	map,	1	@ (map      fun list1 list2 ...)
	DPFUNC	sfreac,	foreac,	1	@ (for-each fun list1 list2 ...)
	DPFUNC	sforce,	force,	1	@ (force promise)
	
	@-------.-------.-------.-------.-------+
	@	6.6. sub-environment		|
	@	6.6.1 ports			|
	@-------.-------.-------.-------.-------+
	
	DPFUNC	scwipf,	cwinpf,	3	@ (call-with-input-file	 string <port-model> proc)
	DPFUNC	scwopf,	cwoutf,	3	@ (call-with-output-file string <port-model> proc)
	DPFUNC	snewln,	pnewln,	0	@ (newline <port> <reg> <n> ...)

	@-------.-------.-------.-------.-------+
	@	system utility  sub-environment	|
	@-------.-------.-------.-------.-------+

	DPFUNC	s_dfnd, p_dfnd,	1	@ (defined? var)
	DPFUNC	s_link, link,	1	@ (link cvec)
	DPFUNC	s_upah, p_upah,	1	@ (unpack-above-heap obj)
.ifndef exclude_lib_mod
	DPFUNC	s_libs, p_libs,	0	@ (libs)
  .ifdef LIB_TOP_PAGE
	DPFUNC	s_erlb, p_erlb,	0	@ (erase-libs)
	DPFUNC	s_uplb, p_uplb,	1	@ (unpack-to-lib obj)
  .else
	DPFUNC	s_uplb, p_upah,	1	@ (unpack-to-lib obj)
  .endif
.endif

end_of_libenv:	@ end of libenv

@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======@
@										@
@		CONSTANTS							@
@										@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======@
	
.macro	make_var_from_libenv var_name, var_env
	\var_name = ((\var_env-libenv+4)<<13)|((lib_env-scmenv)<<6)|variable_tag
.endm
	
	@-------.-------.-------.-------.-------+
@-------@	4.2. Constants			|
	@-------.-------.-------.-------.-------+

	make_var_from_libenv	else_var,	else_env
	make_var_from_libenv	implies_var,	implies_env
	make_var_from_libenv	cond_var,	cond_env
	make_var_from_libenv	case_var,	case_env
	make_var_from_libenv	and_var,	and_env
	make_var_from_libenv	or_var,		or_env
	make_var_from_libenv	let_var,	let_env
	make_var_from_libenv	lets_var,	lets_env
	make_var_from_libenv	letrec_var,	letrec_env
	make_var_from_libenv	do_var,		do_env
	make_var_from_libenv	mkpromise_var,	mkprms_env
	make_var_from_libenv	var0_var,	var0_env
	make_var_from_libenv	var1_var,	(var0_env +  8)
	make_var_from_libenv	var2_var,	(var0_env + 16)
	make_var_from_libenv	var3_var,	(var0_env + 24)
	make_var_from_libenv	var4_var,	(var0_env + 32)
	make_var_from_libenv	var5_var,	(var0_env + 40)
	make_var_from_libenv	var6_var,	(var0_env + 48)
	
	@-------.-------.-------.-------.-------+
@-------@	6.3.2. Constants		|
	@-------.-------.-------.-------.-------+

	make_var_from_libenv	memv_var,	memv_env


/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	4.2.1.	conditionals:			cond, case, and, or
@	4.2.2.	binding constructs:		let, let*, letrec
@	4.2.3.	sequencing:			begin
@	4.2.4.	iteration:			do
@	4.2.5.	delayed evaluation:		delay
@	4.2.c.	constants:			else, =>, var0, var1, var2,
@						var3, var4, var5, var6
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	4
cond:	.ascii	"cond"

	SYMSIZE	4
case:	.ascii	"case"

	SYMSIZE	3
and:	.ascii	"and"

	SYMSIZE	2
or:	.ascii	"or"

	SYMSIZE	3
let:	.ascii	"let"

	SYMSIZE	4
lets:	.ascii	"let*"

	SYMSIZE	6
letr:	.ascii	"letrec"

	SYMSIZE	2
do:	.ascii	"do"

	SYMSIZE	5
delay:	.ascii	"delay"

	SYMSIZE	4
mkp:	.ascii	"_mkp"

@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::
@
@	4.2.c.	constants:   else, =>, var0, var1, var2, var3, var4, var5, var6
@
@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::

	SYMSIZE	4
else:	.ascii	"else"

	SYMSIZE 2
implies: .ascii	"=>"

	SYMSIZE	4
var0:	.ascii	"var0"

	SYMSIZE	4
var1:	.ascii	"var1"

	SYMSIZE	4
var2:	.ascii	"var2"

	SYMSIZE	4
var3:	.ascii	"var3"

	SYMSIZE	4
var4:	.ascii	"var4"

	SYMSIZE	4
var5:	.ascii	"var5"

	SYMSIZE	4
var6:	.ascii	"var6"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.2.5	Numerical operations:	zero?, positive?, negative?, odd?,
@					even?, max, min, abs, gcd, lcm,
@					rationalize (if not integer only)
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/
	
	SYMSIZE	5
szero:	.ascii	"zero?"

	SYMSIZE	9
sposit:	.ascii	"positive?"
	
	SYMSIZE	9
snegat:	.ascii	"negative?"

	SYMSIZE	4
sodd:	.ascii	"odd?"

	SYMSIZE	5
seven:	.ascii	"even?"

	SYMSIZE	3
smax:	.ascii	"max"

	SYMSIZE	3
smin:	.ascii	"min"
	
	SYMSIZE	3
sabs:	.ascii	"abs"
	
	SYMSIZE	3
sgcd:	.ascii	"gcd"
	
	SYMSIZE	3
slcm:	.ascii	"lcm"

.ifndef	integer_only

	SYMSIZE	11
srtnlz:	.ascii	"rationalize"

.endif

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.3.1.	booleans:		not, boolean?
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	3
not:	.ascii	"not"

	SYMSIZE	8
booln:	.ascii	"boolean?"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.3.2.	Pairs and list:		caar, cadr, ..., cdddar, cddddr,
@					null?, list?, list, length, append, reverse,
@					list-tail, list-ref, memq, memv, member,
@					assq, assv, assoc
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	4
caar:	.ascii	"caar"

	SYMSIZE	4
cadr:	.ascii	"cadr"

	SYMSIZE	4
cdar:	.ascii	"cdar"

	SYMSIZE	4
cddr:	.ascii	"cddr"

	SYMSIZE	5
caaar:	.ascii	"caaar"

	SYMSIZE	5
caadr:	.ascii	"caadr"

	SYMSIZE	5
cadar:	.ascii	"cadar"

	SYMSIZE	5
caddr:	.ascii	"caddr"

	SYMSIZE	5
cdaar:	.ascii	"cdaar"

	SYMSIZE	5
cdadr:	.ascii	"cdadr"

	SYMSIZE	5
cddar:	.ascii	"cddar"

	SYMSIZE	5
cdddr:	.ascii	"cdddr"

	SYMSIZE	6
caaaar:	.ascii	"caaaar"

	SYMSIZE	6
caaadr:	.ascii	"caaadr"

	SYMSIZE	6
caadar:	.ascii	"caadar"

	SYMSIZE	6
caaddr:	.ascii	"caaddr"

	SYMSIZE	6
cadaar:	.ascii	"cadaar"

	SYMSIZE	6
cadadr:	.ascii	"cadadr"

	SYMSIZE	6
caddar:	.ascii	"caddar"

	SYMSIZE	6
cadddr:	.ascii	"cadddr"

	SYMSIZE	6
cdaaar:	.ascii	"cdaaar"

	SYMSIZE	6
cdaadr:	.ascii	"cdaadr"

	SYMSIZE	6
cdadar:	.ascii	"cdadar"

	SYMSIZE	6
cdaddr:	.ascii	"cdaddr"

	SYMSIZE	6
cddaar:	.ascii	"cddaar"

	SYMSIZE	6
cddadr:	.ascii	"cddadr"

	SYMSIZE	6
cdddar:	.ascii	"cdddar"

	SYMSIZE	6
cddddr:	.ascii	"cddddr"

	SYMSIZE	5
snull:	.ascii	"null?"

	SYMSIZE	5
listp:	.ascii	"list?"

	SYMSIZE	4
list:	.ascii	"list"

	SYMSIZE	6
slngth:	.ascii	"length"

	SYMSIZE	6
append:	.ascii	"append"

	SYMSIZE	7
srevrs:	.ascii	"reverse"

	SYMSIZE	9
lstail:	.ascii	"list-tail"

	SYMSIZE	8
lstref:	.ascii	"list-ref"

	SYMSIZE	4
memq:	.ascii	"memq"

	SYMSIZE	4
smemv:	.ascii	"memv"

	SYMSIZE	6
member:	.ascii	"member"

	SYMSIZE	4
sassq:	.ascii	"assq"

	SYMSIZE	4
sassv:	.ascii	"assv"

	SYMSIZE	5
assoc:	.ascii	"assoc"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.3.4.	Characters:		char-ci=?, char-ci<?, char-ci>?,
@					char-ci<=?, char-ci>=?, char-alphabetic?
@					char-numeric?, char-whitespace?,
@					char-upper-case?, char-lower-case?,
@					char-upcase, char-downcase
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	9
chrceq:	.ascii	"char-ci=?"

	SYMSIZE	9
chrclt:	.ascii	"char-ci<?"

	SYMSIZE	9
chrcgt:	.ascii	"char-ci>?"

	SYMSIZE	10
chrcle:	.ascii	"char-ci<=?"

	SYMSIZE	10
chrcge:	.ascii	"char-ci>=?"

	SYMSIZE	16
chralp:	.ascii	"char-alphabetic?"

	SYMSIZE	13
chrnum:	.ascii	"char-numeric?"

	SYMSIZE	16
chrspa:	.ascii	"char-whitespace?"
	
	SYMSIZE	16
chrupq:	.ascii	"char-upper-case?"

	SYMSIZE	16
chrloq:	.ascii	"char-lower-case?"

	SYMSIZE	11
chrupc:	.ascii	"char-upcase"

	SYMSIZE	13
chrdnc:	.ascii	"char-downcase"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.3.5.	Strings:		string, string=?,
@					string-ci=?, string<?, string>?,
@					string<=?, string>=?, 
@					string-ci<?, string-ci>?,
@					string-ci<=?, string-ci>=?,
@					substring, string-append,
@					string->list, list->string,string-copy,
@					string-fill
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	6
spstng:	.ascii	"string"

	SYMSIZE	8
sstequ:	.ascii	"string=?"

	SYMSIZE	11
sstceq:	.ascii	"string-ci=?"

	SYMSIZE	8
sstlt:	.ascii	"string<?"

	SYMSIZE	8
sstgt:	.ascii	"string>?"

	SYMSIZE	9
sstle:	.ascii	"string<=?"

	SYMSIZE	9
sstge:	.ascii	"string>=?"

	SYMSIZE	11
sstclt:	.ascii	"string-ci<?"

	SYMSIZE	11
sstcgt:	.ascii	"string-ci>?"

	SYMSIZE	12
sstcle:	.ascii	"string-ci<=?"

	SYMSIZE	12
sstcge:	.ascii	"string-ci>=?"

	SYMSIZE	9
ssubst:	.ascii	"substring"

	SYMSIZE	13
sstapp:	.ascii	"string-append"

	SYMSIZE	12
sstlst:	.ascii	"string->list"

	SYMSIZE	12
slstst:	.ascii	"list->string"

	SYMSIZE	11
sstcpy:	.ascii	"string-copy"

	SYMSIZE	12
sstfil:	.ascii	"string-fill!"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.3.6.	Vectors:		vector, vector->list, list->vector,
@					vector-fill
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	6
svctor:	.ascii	"vector"

	SYMSIZE	12
svclst:	.ascii	"vector->list"

	SYMSIZE	12
slsvec:	.ascii	"list->vector"

	SYMSIZE	12
svcfll:	.ascii	"vector-fill!"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.4.	control features:	map, for-each,	force
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	3
smap:	.ascii	"map"

	SYMSIZE	8
sfreac:	.ascii	"for-each"
	
	SYMSIZE	5
sforce:	.ascii	"force"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	6.6.1.	ports:			call-with-input-file,
@					call-with-output-file,
@	6.6.3.	output:			newline
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	20
scwipf:	.ascii	"call-with-input-file"

	SYMSIZE	21
scwopf:	.ascii	"call-with-output-file"

	SYMSIZE	7
snewln:	.ascii	"newline"

/*------.-------.-------.-------.-------+
@	system utility  sub-environment	|
@-------.-------.-------.-------.------*/
	
	SYMSIZE	8
s_dfnd:	.ascii	"defined?"
	
	SYMSIZE	4
s_link:	.ascii	"link"
	
	SYMSIZE	17
s_upah:	.ascii	"unpack-above-heap"
	
.ifndef exclude_lib_mod

	SYMSIZE	4
s_libs:	.ascii	"libs"
	
  .ifdef LIB_TOP_PAGE

	SYMSIZE	10
s_erlb:	.ascii	"erase-libs"
	
  .endif	@ .ifdef LIB_TOP_PAGE

	SYMSIZE	13
s_uplb:	.ascii	"unpack-to-lib"

.endif		@ do not exclude_lib_mod


/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@			GENERAL NUMBERS (see also integers only further up)
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.2.	Numbers
@	6.2.5	Numerical operations:	zero?, positive?, negative?, odd?, even?
@					max, min, abs,gcd, lcm, rationalize
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	Requires:
@			core:		flsfxt, trufxt, boolxt, corerr, notfxt
@					save, save3, cons, sav_rc, zmaloc
@
@	Modified by (switches):			
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

.ifndef	integer_only

	EPFUNC	null, onumgto, 1		@ primitive, init-sv4 = none, fentry = numgto, narg = 1
positi:	@ (positive? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ jump table for positive?
	.word	flsfxt
	.word	pstint
	.word	pstflt
	.word	pstrat
	.word	flsfxt

	EPFUNC	null, onumgto, 1		@ primitive, init-sv4 = none, fentry = numgto, narg = 1
negati:	@ (negative? obj)
	@ on entry:	sv1 <- obj	
	@ on exit:	sv1 <- #t/#f
	@ jump table for negative?
	.word	flsfxt
	.word	ngtint
	.word	ngtflt
	.word	ngtrat
	.word	flsfxt

	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
max:	@ (max num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- max of (num1 num2 ...)
	@ jump table for max
	.word	corerr
	.word	maxint
	.word	maxflt
	.word	maxrat
	.word	corerr

	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
min:	@ (min num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- min of (num1 num2 ...)
	@ jump table for min
	.word	corerr
	.word	minint
	.word	minflt
	.word	minrat
	.word	corerr

	EPFUNC	null, onumgto, 1		@ primitive, init-sv4 = none, fentry = numgto, narg = 1
abs:	@ (abs number)
	@ on entry:	sv1 <- number
	@ on exit:	sv1 <- absolute value of number
	.word	corerr
	.word	absint
	.word	absflt
	.word	absrat
	.word	corerr

	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
gcd:	@ (gcd n1 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- gcd of (num1 num2 ...)
	.word	corerr
	.word	gcdint
	.word	gcdflt
	.word	gcdrat
	.word	corerr

	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
lcm:	@ (lcm n1 ...)			  ((n1 ...) ...) -> (int ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- lcm of (num1 num2 ...)
	.word	corerr
	.word	lcmint
	.word	lcmflt
	.word	lcmrat
	.word	corerr

	EPFUNC	null, ounijmp, 2		@ primitive, init-sv4 = none, fentry = unijmp, narg = 2
rtnlz:	@ (rationalize x y)
	@ on entry:	sv1 <- x
	@ on entry:	sv2 <- y
	@ on exit:	sv1 <- ratio
	.word	corerr
	.word	rtzint
	.word	rtzflt
	.word	rtzrat
	.word	corerr
rtyspc:	@ special returns table for rationalize, based on y, tested first (but after x == nan)
	.word	return			@   x <- (rationalize x 0)
	.word	f0fxt			@ 0.0 <- (rationalize x inf)
	.word	f0fxt			@ 0.0 <- (rationalize x -inf)
rtxspc:	@ special returns table for rationalize, based on x, tested after rtyspc
	.word	return			@    0 <- (rationalize 0 y)
	.word	return			@  inf <- (rationalize inf y)
	.word	return			@ -inf <- (rationalize -inf y)


.endif

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@			R5RS MACROS (R3RS defined as syntax in code file)
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	4.	Expressions
@	4.2.	Derived expression types
@	4.2.1.	conditionals:			cond, case, and, or
@	4.2.2.	binding constructs:		let, let*, letrec
@	4.2.3.	sequencing:			begin
@	4.2.4.	iteration:			do
@	4.2.5.	delayed evaluation:		delay
@	4.2.c.	constants:			else, =>, var0, var1, var2,
@						var3, var4, var5, var6
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

.ifndef r3rs

	MACRO
pcond:	@ (cond clause1 clause2 ...)
	@(define-syntax cond
	@  (syntax-rules (else =>)
	@    ((_ (else result1 ...))
	@     (begin result1 ...))
	@    ((_ (test => result))
	@     (let ((temp test)) (if temp (result temp))))
	@    ((_ (test => result) clause1 ...)
	@     (let ((temp test)) (if temp (result temp) (cond clause1 ...))))
	@    ((_ (test)) test)
	@    ((_ (test) clause1 ...)
	@     (let ((temp test)) (if temp temp (cond clause1 ...))))
	@    ((_ (test result1 ...))
	@     (if test (begin result1 ...)))
	@    ((_ (test result1 ...) clause1 ...)
	@     (if test (begin result1 ...) (cond clause1 ...)))))
	.word	. + 12				@ pointer to literals
	.word	. + 16				@ pointer to macro body
	.word	scheme_null			@ end of tag

	.word	implies_var,	else_null
	.word	cond_a,	. + 4,	cond_b,	. + 4,	cond_c,	. + 4,	cond_d,	. + 4
	.word	cond_e,	. + 4,	cond_f,	. + 4,	cond_g,	scheme_null
cond_a:	@ pattern:	(_ (else result1 ...))
	@ template:	(begin result1 ...)
	@		(_ (else var2 ...))
	@		(begin var2 ...)
	@ var2 <-> result1
	.word	condaP,	. + 4, condaT, scheme_null
condaP:	@ (_ (else result1 ...))
	.word	underscore_var,	. + 4
	.word	. + 8,		scheme_null
	.word	else_var,	var2_ellipse
condaT:	@ (begin result1 ...)
	.word	begin_var,	var2_ellipse
cond_b:	@ pattern:	(_ (test => result))
	@ template:	(let ((temp test)) (if temp (result temp)))
	@		(_ (var1 => var2))
	@		(let ((var0 var1)) (if var0 (var2 var0)))
	@ var0 <-> temp
	@ var1 <-> test
	@ var2 <-> result
	.word	condbP,	. + 4, condbT, scheme_null
condbP:	@ (_ (test => result))
	.word	underscore_var,	. + 4
	.word	condcP + 16,	scheme_null
condbT:	@ (let ((temp test)) (if temp (result temp)))
	.word	let_var,	. + 4
	.word	condcT + 16,	. + 4
	.word	. + 8,		scheme_null
	.word	if_var,	. + 4
	.word	var0_var,	. + 4
	.word	condcT + 56,	scheme_null
cond_c:	@ pattern:	(_ (test => result) clause1 ...)
	@ template:	(let ((temp test)) (if temp (result temp) (cond clause1 ...)))
	@		(_ (var1 => var2) var3 ...)
	@		(let ((var0 var1)) (if var0 (var2 var0) (cond var3 ...)))
	@ var0 <-> temp
	@ var1 <-> test
	@ var2 <-> result
	@ var3 <-> clause1
	.word	condcP,	. + 4, condcT, scheme_null
condcP:	@ (_ (test => result) clause1 ...)
	.word	underscore_var,	. + 4
	.word	. + 8,		var3_ellipse
	.word	var1_var,	. + 4
	.word	implies_var,	. + 4
	.word	var2_var,	scheme_null
condcT:	@ (let ((temp test)) (if temp (result temp) (cond clause1 ...)))
	.word	let_var,	. + 4
	.word	. + 8,		. + 12
	.word	var0_1_null,	scheme_null
	.word	. + 8,		scheme_null
	.word	if_var,	. + 4
	.word	var0_var,	. + 4
	.word	. + 8,		. + 20
	.word	var2_var,	. + 4
	.word	var0_var,	scheme_null
	.word	. + 8,		scheme_null
	.word	cond_var,	var3_ellipse
cond_d:	@ pattern:	(_ (test))
	@ template:	test
	@		(_ (var1))
	@		var1
	@ var1 <-> test
	.word	conddP,	. + 4, var1_var, scheme_null
conddP:	@ (_ (test))
	.word	underscore_var,	. + 4
	.word	var1_null,	scheme_null
cond_e:	@ pattern:	(_ (test) clause1 ...)
	@ template:	(let ((temp test)) (if temp temp (cond clause1 ...)))
	@		(_ (var1) var3 ...)
	@		(let ((var0 var1)) (if var0 var0 (cond var3 ...)))
	@ var0 <-> temp
	@ var1 <-> test
	@ var3 <-> clause1
	.word	condeP,	. + 4, condeT, scheme_null
condeP:	@ (_ (test) clause1 ...)
	.word	underscore_var,	. + 4
	.word	var1_null,	var3_ellipse
condeT:	@ (let ((temp test)) (if temp temp (cond clause1 ...)))
	.word	let_var,	. + 4
	.word	condcT + 16,	. + 4
	.word	. + 8,		scheme_null
	.word	if_var,	. + 4
	.word	var0_var,	. + 4
	.word	var0_var,	condcT + 72
cond_f:	@ pattern:	(_ (test result1 ...))
	@ template:	(if test (begin result1 ...))
	@		(_ (var1 var2 ...))
	@		(if var1 (begin var2 ..))
	@ var1 <-> test
	@ var2 <-> result1
	.word	condfP,	. + 4, condfT, scheme_null
condfP:	@ (_ (test result1 ...))
	.word	underscore_var,	. + 4
	.word	var1_2_ellipse,	scheme_null
condfT:	@ (if test (begin result1 ...))
	.word	if_var,	. + 4
	.word	var1_var,	cond_a + 8
cond_g:	@ pattern:	(_ (test result1 ...) clause1 ...)
	@ template:	(if test (begin result1 ...) (cond clause1 ...))
	@		(_ (var1 var2 ...) var3 ...)
	@		(if var1 (begin var2 ...) (cond var3 ...))
	@ var1 <-> test
	@ var2 <-> result1
	@ var3 <-> clause1
	.word	condgP,	. + 4, condgT, scheme_null
condgP:	@ (_ (test result1 ...) clause1 ...)
	.word	underscore_var,	. + 4
	.word	var1_2_ellipse,	var3_ellipse
condgT:	@ (if test (begin result1 ...) (cond clause1 ...))
	.word	if_var,	. + 4
	.word	var1_var,	. + 4
	.word	condaT,		condcT + 72


	MACRO
pcase:	@ (case key clause1 clause2 ...)
	@(define-syntax case
	@  (syntax-rules (else)
	@    ((_ (key ...) clauses ...)
	@     (let ((atom-key (key ...))) (case atom-key clauses ...)))
	@    ((_ key (else result1 ...))
	@     (begin result1 ...))
	@    ((_ key ((atom ...) result1 ...))
	@     (if (memv key (quote (atom ...))) (begin result1 ...)))
	@    ((_ key ((atoms ...) result1 ...) clause1 ...)
	@     (if (memv key (quote (atoms ...))) (begin result1 ...) (case key clause1 ...)))))
	.word	else_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag

	.word	case_a,	. + 4,	case_b,	. + 4,	case_c,	. + 4,	case_d,	scheme_null
case_a:	@ pattern:	(_ (key ...) clauses ...)
	@ template:	(let ((atom-key (key ...))) (case atom-key clauses ...))
	@		(_ (var0 ...) var2 ...)
	@ ->->->		(let (var1 (var0 ...)) (case var1 var2 ...))
	@ var0 <-> key
	@ var1 <-> atom-key
	@ var2 <-> clauses
	.word	caseaP,	. + 4, caseaT, scheme_null
caseaP:	@ (_ (key ...) clauses ...)
	.word	underscore_var,	. + 4
	.word	var0_ellipse,	var2_ellipse
caseaT:	@ (let ((atom-key (key ...))) (case atom-key clauses ...))
	.word	let_var,	. + 4
	.word	. + 8,		. + 28
	.word	. + 8,		scheme_null
	.word	var1_var,	. + 4
	.word	var0_ellipse,	scheme_null
	.word	. + 8,		scheme_null
	.word	case_var,	var1_2_ellipse
case_b:	@ pattern:	(_ key (else result1 ...))
	@ template:	(begin result1 ...)
	@		(_ var0 (else var3 ...))
	@		(begin var3 ...)
	@ var0 <-> key
	@ var3 <-> result1
	.word	casebP,	. + 4, casebT, scheme_null
casebP:	@ (_ key (else result1 ...))
	.word	underscore_var,	. + 4
	.word	var0_var,	. + 4
	.word	. + 8,		scheme_null
	.word	else_var,	var3_ellipse
casebT:	@ (begin result1 ...)
	.word	begin_var,	var3_ellipse
case_c:	@ pattern:	(_ key ((atom ...) result1 ...))
	@ template:	(if (memv key (quote (atom ...))) (begin result1 ...))
	@ ->->->key	(_ var1 ((var1 ...) var3 ...))
	@		(if (memv var0 (quote (var1 ...))) (begin var3 ...)))
	@ var0 <-> atom
	@ var1 <-> key
	@ var3 <-> result1
	.word	casecP,	. + 4, casecT, scheme_null
casecP:	@ (_ key ((atom ...) result1 ...))
	.word	underscore_var,	. + 4
	.word	var1_var,	. + 4
	.word	. + 8,		scheme_null
	.word	var0_ellipse,	var3_ellipse
casecT:	@ (if (memv key (quote (atom ...))) (begin result1 ...))
	.word	if_var,	. + 4
	.word	. + 8,		case_b + 8
	.word	memv_var,	. + 4
	.word	var1_var,	. + 4
	.word	. + 8,		scheme_null
	.word	quote_var,	. + 4
	.word	var0_ellipse,	scheme_null
case_d:	@ pattern:	(_ key ((atoms ...) result1 ...) clause1 ...)
	@ template:	(if (memv key (quote (atoms ...))) (begin result1 ...) (case key clause1 ...))
	@ ->-> atoms	(_ var1 ((var1 ...) var3 ...) var2 ...)
	@ ->-> key	(if (memv var0 (quote (var1 ...))) (begin var3 ...) (case var1 var2 ...)))) 
	@ var0 <-> atoms
	@ var1 <-> key
	@ var2 <-> clause1
	@ var3 <-> result1
	.word	casedP,	. + 4, casedT, scheme_null
casedP:	@ (_ key ((atoms ...) result1 ...) clause1 ...)
	.word	underscore_var,	. + 4
	.word	var1_var,	. + 4
	.word	casecP + 24,	var2_ellipse
casedT:	@ (if (memv key (quote (atoms ...))) (begin result1 ...) (case key clause1 ...))
	.word	if_var,	. + 4
	.word	casecT + 16,	. + 4
	.word	casebT,		caseaT + 40
	

	MACRO
pand:	@ (and exp1 exp2 ...)
	@ (define-syntax and
	@   (syntax-rules ()
	@     ((_) #t)
	@     ((_ test) test)
	@     ((_ test1 test2 ...)
	@      (if test1 (and test2 ...) #f))))
	.word	scheme_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag

	.word	and_a,	. + 4,	and_b,	. + 4,	and_c,	scheme_null
and_a:	@ ((_) #t)
	.word	underscore_null,	true_null	@ ((_) #t)
and_b:	@ ((_ test) test)
	.word	und_var1_null,		var1_null	@ ((_ test) test)
and_c:	@ ((_ test1 test2 ...)
	@  (if test1 (and test2 ...) #f))
	.word	und_var12_ell,		. + 4		@ ((_ test1 test2 ...)
	.word	. +  8,			scheme_null	@  (
	.word	if_var,		. + 4		@   if
	.word	var1_var,		. + 4		@     test1
	.word	. + 8,			false_null	@                       #f)
	.word	and_var,		var2_ellipse	@       (and test2 ...)


	MACRO
por:	@ (or exp1 exp2 ...)
	@(define-syntax or
	@  (syntax-rules ()
	@    ((_) #f )
	@    ((_ test) test)
	@    ((_ test1 test2 ...)
	@     (let ((x test1))
	@       (if x x (or test2 ...))))))
	.word	scheme_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag

	.word	or_a,	. + 4,	and_b,	. + 4,	or_c,	scheme_null	@ case b same as and
or_a:	@ ((_) #f )
	.word	underscore_null,	false_null	@ ((_) #f)
or_c:	@ ((_ test1 test2 ...)
	@  (let ((x test1))
	@    (if x x (or test2 ...))))))
	.word	und_var12_ell,		. + 4		@ ((_ test1 test2 ...)
	.word	. + 8,			scheme_null	@  (
	.word	let_var,		. + 4		@   let
	.word	. + 8,			. + 12		@     (
	.word	var0_1_null,		scheme_null	@      (x test1))
	.word	. + 8,			scheme_null	@   (                    )
	.word	if_var,		. + 4		@   if
	.word	var0_var,		. + 4		@     x
	.word	var0_var,		. + 4		@     x
	.word	. + 8,			scheme_null	@                       )
	.word	or_var,			var2_ellipse	@       (or test2 ...)

@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::
@
@	4.2.2.	binding constructs:	let, let*, letrec
@
@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::

	MACRO
plet:	@ (let <name> bindings-list exp1 exp2 ...)
	@ (define-syntax let
	@   (syntax-rules ()
	@     ((_ ((name val) ...) body1 ...)
	@      ((lambda (name ...) body1 ...)
	@       val ...))
	@     ((_ tag ((name val) ...) body1 ...)
	@      ((letrec
	@ 	 ((tag (lambda (name ...) body1 ...)))
	@	 tag)
	@       val ...))))
	.word	scheme_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag
	.word	let_a, . + 4, let_b, scheme_null
let_a:	@ pattern:	(_ ((name val) ...) body1 ...)
	@ template:	((lambda (name ...) body1 ...) val ...)
	@ var0 <-> name
	@ var1 <-> val
	@ var2 <-> body1
	.word	let_aP,	. + 4, let_aT, scheme_null
let_aP:	@ pattern:	(_ ((name val) ...) body1 ...)
	.word	underscore_var,	letcm1
let_aT:	@ template:	((lambda (name ...) body1 ...) val ...)
	.word	letcm2,		var1_ellipse
let_b:	@ pattern:	(_ tag ((name val) ...) body1 ...)
	@ template:	((letrec
	@		   ((tag (lambda (name ...) body1 ...)))
	@		  tag)
	@	         val ...)
	@ var0 <-> name
	@ var1 <-> val
	@ var2 <-> body1
	@ var3 <-> tag
	.word	let_bP,	. + 4, let_bT, scheme_null
let_bP:	.word	underscore_var,	. + 4
	.word	var3_var,	letcm1
let_bT:	.word	. + 8,		var1_ellipse
	.word	letrec_var,	. + 4
	.word	. + 8,		var3_null
	.word	. + 8,		scheme_null
	.word	var3_var,	. + 4
	.word	letcm2,		scheme_null
	
letcm1:	@ (((name val) ...) body1 ...)
	@ var0 <-> name
	@ var1 <-> val
	@ var2 <-> body1
	.word	. + 8,		var2_ellipse
	.word	var0_1_null,	ellipse_null

letcm2:	@ (lambda (name ...) body1 ...)
	@ var0 <-> name
	@ var2 <-> body1
	.word	lambda_var,	. + 4
	.word	var0_ellipse,	var2_ellipse


	MACRO
plets:	@ (let* bindings-list exp1 exp2 ...)
	@ (define-syntax let*
	@   (syntax-rules ()
	@     ((_ ()  body1 ...)
	@      (let ()  body1 ...))
	@     ((_ (binding1) body1 ...)
	@      (let (binding1) body1 ...))
	@     ((_ (binding1 binding2 ...) body1 ...)
	@      (let (binding1)
	@        (let* (binding2 ...) body1 ...)))))
	.word	scheme_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag

	.word	lets_a,	. + 4,	lets_b,	. + 4,	lets_c,	scheme_null
lets_a:	@ pattern:	(_ ()  body1 ...)
	@ template:	(let ()  body1 ...)
	@ var2 <-> body1
	.word	letsaP,	. + 4, letsaT, scheme_null
letsaP:	@ (_ ()  body1 ...)
	.word	underscore_var,	. + 4
	.word	scheme_null,	var2_ellipse
letsaT:	@ (let ()  body1 ...)
	.word	let_var,	letsaP + 8
lets_b:	@ pattern:	(_ (binding1) body1 ...)
	@ template:	(let (binding1) body1 ...)
	@ var1 <-> binding1
	@ var2 <-> body1
	.word	letsbP,	. + 4, letsbT, scheme_null
letsbP:	@ (_ (binding1) body1 ...)
	.word	underscore_var,	. + 4
	.word	var1_null,	var2_ellipse
letsbT:	@ (let (binding1) body1 ...)
	.word	let_var,	letsbP + 8
lets_c:	@ pattern:	(_ (binding1 binding2 ...) body1 ...)
	@ template:	(let (binding1)
	@		 (let* (binding2 ...) body1 ...))
	@ var0 <-> body1
	@ var1 <-> binding1
	@ var2 <-> binding2
	.word	letscP,	. + 4, letscT, scheme_null
letscP:	@ (_ (binding1 binding2 ...) body1 ...)
	.word	underscore_var,	. + 4
	.word	var1_2_ellipse,	var0_ellipse
letscT:	@ (let (binding1) (let* (binding2 ...) body1 ...))
	.word	let_var,	. + 4
	.word	var1_null,	. + 4
	.word	. + 8,		scheme_null
	.word	lets_var,	. + 4
	.word	var2_ellipse,	var0_ellipse


	MACRO
pletr:	@ (letrec bindings-list exp1 exp2 ...)
	@ (define-syntax letrec
	@   (syntax-rules ()
	@     ((_ ((var1 init1) ...) body ...)
	@      (letrec #t (var1 ...) () ((var1 init1) ...) body ...))
	@     ((_ #t () (temp1 ...) ((var1 init1) ...) body ...)
	@      (let ((var1 #t) ...)
	@        (let ((temp1 init1) ...) (set! var1 temp1) ... body ...)))
	@     ((_ #t (x . y) temp ((var1 init1) ...) body ...)
	@      (letrec #t y (newtemp . temp) ((var1 init1) ...) body ...))))
	.word	scheme_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag

	.word	letr_a, . + 4, letr_b, . + 4,	letr_c, scheme_null
letr_a:	@ pattern:	(_ ((var1 init1) ...) body ...)
	@ template:	(letrec #t (var1 ...) () ((var1 init1) ...) body ...)
	@		(_ ((var0 var1) ...) var2 ...)
	@		(letrec #t (var0 ...) () ((var0 var1) ...) var2 ...)
	@ var0 <-> var1
	@ var1 <-> init1
	@ var2 <-> body
	.word	let_aP,	. + 4, letraT, scheme_null	@ pattern same as let_a
letraT:	@ (letrec #t (var1 ...) () ((var1 init1) ...) body ...)
	.word	letrec_var,	. + 4
	.word	scheme_true,	. + 4
	.word	var0_ellipse,	. + 4
	.word	scheme_null,	letcm1
letr_b:	@ pattern:	(_ #t () (temp1 ...) ((var0 init1) ...) body ...)
	@ template:	(let ((var0 #t) ...)
	@	          (let ((temp1 init1) ...) (set! var0 temp1) ... body ...))
	@		(_ #t () (var3 ...) ((var0 var1) ...) var2 ...)
	@		(let ((var0 #t) ...)
	@		  (let ((var3 var1) ...) (set! var0 var3) ... var2 ...))
	@ var0 <-> var0
	@ var1 <-> init1
	@ var2 <-> body
	@ var3 <-> temp1
	.word	letrbP,	. + 4, letrbT, scheme_null
letrbP:	@ (_ #t () (temp1 ...) ((var0 init1) ...) body ...)
	.word	underscore_var,	. + 4
	.word	scheme_true,	. + 4
	.word	scheme_null,	. + 4
	.word	var3_ellipse,	letcm1
letrbT:	@ (let ((var0 #t) ...)
	@   (let ((temp1 init1) ...) (set! var0 temp1) ... body ...))
	.word	let_var,	. + 4
	.word	. + 8,		. + 20
	.word	. + 8,		ellipse_null
	.word	var0_var,	true_null
	.word	. + 8,		scheme_null
	.word	let_var,	. + 4
	.word	. + 8,		. + 20
	.word	. + 8,		ellipse_null
	.word	var3_var,	var1_null
	.word	. + 8,		. + 20
	.word	set_var,	. + 4
	.word	var0_var,	var3_null
	.word	ellipsis_var,	var2_ellipse
letr_c:	@ pattern:	(_ #t (x . y) temp ((var0 init1) ...) body ...)
	@ template:	(letrec #t y (newtemp . temp) ((var0 init1) ...) body ...)
	@		(_ #t (var4 . var5) var3 ((var0 var1) ...) var2 ...)
	@		(letrec #t var5 (var6 . var3) ((var0 var1) ...) var2 ...)
	@ var0 <-> var0
	@ var1 <-> init1
	@ var2 <-> body
	@ var3 <-> temp
	@ var4 <-> x
	@ var5 <-> y
	@ var6 <-> newtemp
	.word	letrcP,	. + 4, letrcT, scheme_null
letrcP:	@ (_ #t (x . y) temp ((var0 init1) ...) body ...)
	.word	underscore_var,	. + 4
	.word	scheme_true,	. + 4
	.word	. + 8,		. + 12
	.word	var4_var,	var5_var
	.word	var3_var,	letcm1
letrcT:	@ (letrec #t y (newtemp . temp) ((var0 init1) ...) body ...)
	.word	letrec_var,	. + 4
	.word	scheme_true,	. + 4
	.word	var5_var,	. + 4
	.word	. + 8,		letcm1
	.word	var6_var,	var3_var

@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::
@
@	4.2.4.	iteration:		do
@
@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::

	MACRO
pdo:	@ (do ((var1 init1 <step1>) ...) (test expr1 expr2 ...) command1 command2 ...)
@(define-syntax do
@  (syntax-rules ()
@    ((_ ((var init . step) ...) (test expr ...))
@     (do ((var init . step) ...) (test expr ...) #f))
@    ((_ ((var init . step) ...) (test expr ...) command ...)
@     (letrec
@         ((loop
@           (lambda (var ...)
@             (if test
@                 (begin (if #f  #f) expr ...)
@                 (begin command ... (loop (do #t var . step) ...))))))
@       (loop init ...)))
@    ((_ #t x) x)
@    ((_ #t x y) y)))
	.word	scheme_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag
	.word	do_a,	. + 4,	do_b,	. + 4,	do_c,	. + 4,	do_d,	scheme_null
do_a:	@ pattern:	(_ ((var init . step) ...) (test expr ...))
	@ template:	(do ((var init . step) ...) (test expr ...) #f)
	@		(_ ((var0 var3 . var4) ...) (var1 var2 ...))
	@ -> list		 (do ((var0 var3 . var4) ...) (var1 var2 ...) #f)
	@ var0 <-> var
	@ var1 <-> test
	@ var2 <-> expr
	@ var3 <-> init
	@ var4 <-> step
	.word	do_aP,	. + 4, do_aT, scheme_null
do_aP:	@ (_ ((var init . step) ...) (test expr ...))
	.word	underscore_var,	. + 4
	.word	. + 8,		. + 28
	.word	. + 8,		ellipse_null
	.word	var0_var,	. + 4
	.word	var3_var,	var4_var
	.word	var1_2_ellipse,	scheme_null
do_aT:	@ (do ((var init . step) ...) (test expr ...) #f)
	.word	do_var,		. + 4
	.word	do_aP + 16,	. + 4
	.word	var1_2_ellipse,	false_null
do_b:	@ pattern:	(_ ((var init . step) ...) (test expr ...) command ...)
	@ template:	(letrec
	@	         ((loop
	@	           (lambda (var ...)
	@	             (if test
	@	                 (begin (if #f  #f) expr ...)
	@	                 (begin command ... (loop (do #t var . step) ...))))))
	@	         (loop init ...))
	@ -> do, list	(do ((var0 var3 . var4) ...) ((var1 var2 ...)) var5 ...)
	@		(letrec
	@		  ((var6
	@		    (lambda (var0 ...)
	@		      (if var1
	@			 (begin (if #f #f) var2 ...)
	@			 (begin var5 ... (var6 (do #t var0 . var4) ...))))))
	@		 (var6 var3 ...))
	@ var0 <-> var
	@ var1 <-> test
	@ var2 <-> expr
	@ var3 <-> init
	@ var4 <-> step
	@ var5 <-> command
	@ var6 <-> loop
	.word	do_bP,	. + 4, do_bT, scheme_null
do_bP:	@ (_ ((var init . step) ...) (test expr ...) command ...)
	.word	underscore_var,	. + 4
	.word	do_aP + 16,	. + 4
	.word	var1_2_ellipse,	. + 4
	.word	var5_var,	ellipse_null
do_bT:	@ (letrec
	@   ((loop (lambda (var ...)
	@	      (if test
	@	         (begin (if #f #f) expr ...)
	@	         (begin command ... (loop (do #t var . step) ...))))))
	@  (loop init ...))
	.word	letrec_var,	. + 4
	.word	. + 24,		. + 4
	.word	. + 8,		scheme_null
	.word	var6_var,	var3_ellipse
	.word	. + 8,		scheme_null
	.word	var6_var,	. + 4
	.word	. + 8,		scheme_null
	.word	lambda_var,	. + 4
	.word	var0_ellipse,	. + 4
	.word	. + 8,		scheme_null
	.word	if_var,	. + 4
	.word	var1_var,	. + 4
	.word	. + 8,		. + 36
	.word	begin_var,	. + 4
	.word	. + 8,		var2_ellipse
	.word	if_var,	. + 4
	.word	scheme_false,	false_null
	.word	. + 8,		scheme_null
	.word	begin_var,	. + 4
	.word	var5_var,	. + 4
	.word	ellipsis_var,	. + 4
	.word	. + 8,		scheme_null
	.word	var6_var,	. + 4
	.word	. + 8,		ellipse_null
	.word	do_var,		. + 4
	.word	scheme_true,	. + 4
	.word	var0_var,	var4_var
do_c:	@ pattern:	(_ #t x)
	@ template:	x
	@		(_ #t var1)
	@		 var1
	@ var1 <-> x
	.word	do_cP,	. + 4, var1_var, scheme_null
do_cP:	@ (_ #t x)
	.word	underscore_var,	. + 4
	.word	scheme_true,	var1_null
do_d:	@ pattern:	(_ #t x y)
	@ template:	y
	@		(_ #t var0 var1)
	@		var1
	@ var0 <-> x
	@ var1 <-> y
	.word	do_dP,	. + 4, var1_var, scheme_null
do_dP:	@ (_ #t x y)
	.word	underscore_var,	. + 4
	.word	scheme_true,	var0_1_null

@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::
@
@	4.2.5.	delayed evaluation:	delay
@
@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::

	MACRO
pdelay:	@ (delay expr)
	@(define-syntax delay
	@  (syntax-rules ()
	@    ((_ expr)
	@     (_mkp (lambda () expr)))))
	.word	scheme_null			@ pointer to literals
	.word	. + 8				@ pointer to macro body
	.word	scheme_null			@ end of tag
	.word	dlay_a, scheme_null
dlay_a:	@ pattern:	(_ expr)
	@ template:	(_mkp (lambda () expr))
	@ var1 <-> expr
	.word	dly_aP,	. + 4, dly_aT, scheme_null
dly_aP:	@ pattern:	(_ expr)
	.word	underscore_var,	var1_null
dly_aT:	@ template:	(_mkp (lambda () expr))
	.word	mkpromise_var,	. + 4
	.word	. + 8,		scheme_null
	.word	lambda_var,	. + 4
	.word	scheme_null,	var1_null


@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::
@
@	4.2.c.	common completion lists
@
@:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::.:::::::

.balign	8

var0_1_null:	.word	var0_var,	var1_null	@ (var0 var1)
und_var1_null:	.word	underscore_var,	var1_null	@ (_ var1)
und_var12_ell:	.word	underscore_var,	var1_2_ellipse	@ (_ var1 var2 ...)
var1_2_ellipse:	.word	var1_var,	var2_ellipse	@ (var1 var2 ...)
var0_ellipse:	.word	var0_var,	ellipse_null	@ (var0 ...)
var1_ellipse:	.word	var1_var,	ellipse_null	@ (var1 ...)
var2_ellipse:	.word	var2_var,	ellipse_null	@ (var2 ...)
var3_ellipse:	.word	var3_var,	ellipse_null	@ (var3 ...)
ellipse_null:	.word	ellipsis_var,	scheme_null	@ ( ...)
else_null:	.word	else_var,	scheme_null	@ (else)	
underscore_null: .word	underscore_var,	scheme_null	@ (_)
var1_null:	.word	var1_var,	scheme_null	@ (var1)
var3_null:	.word	var3_var,	scheme_null	@ (var3)
true_null:	.word	scheme_true,	scheme_null	@ (#t)
false_null:	.word	scheme_false,	scheme_null	@ (#f)


.endif		@ .ifndef r3rs




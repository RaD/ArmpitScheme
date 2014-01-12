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
@				R5RS (see R3RS below)
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

mkprms:	@ (_mkp proc)
	@ on entry:	sv1 <- proc = (lambda env () expr)
	@ on exit:	sv1 <- (promise env () expr)
	@ return a lambda with extended env
	@
	@ well, probably better off returning a compiled proc, branching to assembly code
	@ (maybe even two of those?)
	@
	@ var0 <- #f, var1 <- proc
	@ build var list
	ldr	sv2, =var2_var
	list	sv3, sv2
	ldr	sv2, =var1_var
	cons	sv3, sv2, sv3
	ldr	sv2, =var0_var
	cons	sv3, sv2, sv3		@ sv3 <- (var0 var1 var2)
	@ build val list
	list	sv4, sv1
	set	sv2, #f	
	cons	sv4, sv2, sv4
	cons	sv4, sv2, sv4		@ sv4 <- (#f #f proc)
	@ extend environment
	sav_ec				@ dts <- (env cnt ...)
	call	mkfrm
	@ build promise (compiled thunk with extended env)
	set	sv2, #null
	ldr	sv3, =prmcod
	set	sv1, #procedure
	orr	sv1, sv1, #0xC000
	tagwenv	sv1, sv1, sv2, sv3	@ sv1 <- promise == [proc_tag () prmcod prom-env]
	restor2	env, cnt		@ env <- env, cnt <- cnt, dts <- (...)
	set	pc,  cnt


	PFUNC	0
prmcod:	@ code for make-promise
	ldr	sv1, =var0_var
	bl	bndchk
	eq	sv5, #t
	bne	prmco1
	ldr	sv1, =var1_var
	bl	bndchk
	set	sv1, sv5
	set	pc,  cnt
prmco1:	
	sav_ec
	ldr	sv1, =var2_var
	bl	bndchk
	set	sv1, sv5
	set	sv2, #null
	call	apply
	set	sv2, sv1
	restor2	env, cnt
	ldr	sv1, =var0_var
	bl	bndchk
	eq	sv5, #t
	bne	prmco2
	ldr	sv1, =var1_var
	bl	bndchk
	set	sv1, sv5
	set	pc,  cnt
prmco2:	@ set result in promise env
	ldr	sv1, =var0_var
	bl	bndchk
	set	sv4, #t
	setcdr	sv3, sv4
	ldr	sv1, =var1_var
	bl	bndchk
	setcdr	sv3, sv2
	set	sv1, sv2
	set	pc,  cnt
		

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

.endif		@ .ifndef r3rs
	
/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@				R3RS (see R5RS above)
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

.ifdef r3rs

pcond:	@ (cond clause1 clause2 ...)
	@ on entry:	sv1 <- (clause1 clause2 ...)
	@ on exit:	sv1 <- result
	sav_ec				@ dts <- (env cnt ...)
	set	sv4, sv1		@ sv4 <- (clause1 clause2 ...)
cond0:	@ evaluate tests in sequence and branch to expr as appropriate
	nullp	sv4			@ no more clauses?
	beq	condxt			@	if so,  jump to exit with '() or #f
	caar	sv1, sv4		@ sv1 <- test1-or-else from clause1
	ldr	sv3, =else_var		@ sv3 <- else
	eq	sv1, sv3		@ is sv1 = else?
	beq	cond1			@	if so,  jump to evaluate expressions1
	car	env, dts		@ env <- env
	save	sv4			@ dts <- ((clause1 clause2 ...) env cnt ...)
	call	eval			@ sv1 <- test1-val
	restor	sv4			@ sv4 <- (clause1 clause2 ...),	dts <- (env cnt ...)
	eq	sv1, #f			@ did test return #f?
	it	eq
	cdreq	sv4, sv4		@	if so,  sv4 <- (clause2 ...)
	beq	cond0			@	if so,  jump to continue evaluating tests
cond1:	@ evaluate expressions for #t test or else clause
	cdar	sv4, sv4		@ sv4 <- (<=>> expr1 expr2 ...)
	car	sv2, sv4		@ sv2 <- =>-or-expr1
	ldr	sv5, =implies_var	@ sv5 <- =>
	eq	sv2, sv5		@ is sv2 = =>?
	beq	cond2			@	if so,  jump to process that case
	set	sv2, #null		@ sv2 <- '()
	restor	env			@ env <- original env, dts <- (cnt ...)
	set	sv1, #procedure		@ sv1 <- procedure_tag
	orr	sv1, sv1, #0x4000	@ sv1 <- full proc tag
	tagwenv	sv1, sv1, sv2, sv4	@ sv1 <- proc == [proc_tag vars-list (body) env]
	restor	cnt			@ cnt <- cnt, dts <- (...)
	b	apply
cond2:	@ evaluate the case with =>
	car	env, dts		@ env <- env
	list	sv1, sv1		@ sv2 <- (test-val)
	save	sv1			@ dts <- ((test-val) env cnt ...)
	cadr	sv1, sv4		@ sv1 <- procedure-of-1-arg
	call	eval			@ sv1 <- proc
	restor	sv2			@ sv2 <- (test-val) = argl
	restor2	env, cnt		@ env <- original env, cnt <- cnt, dts <- (...)
	b	apply
condxt:	@ exit without match
	restor2	env, cnt		@ env <- original env, cnt <- cnt, dts <- (...)
	set	pc, cnt


pcase:	@ (case key clause1 clause2 ...)
	@ on entry:	sv1 <- key
	@ on entry:	sv2 <- (clause1 clause2 ...)
	@ on exit:	sv1 <- result
	savrec	sv2			@ dts <- ((clause1 clause2 ...) env cnt ...)
	call	eval			@ sv1 <- key-val
	restor	sv4			@ sv4 <- (clause1 clause2 ...)
	save	sv1			@ dts <- (key-val env cnt ...)
	ldr	sv5, =else_var		@ sv5 <- else
case0:	@ look for key in clauses' datum
	nullp	sv4			@ done with clauses?
	beq	casext			@	if so,  jump to exit
	caar	sv2, sv4		@ sv2 <- datum1-or-else from clause1
	eq	sv2, sv5		@ is sv2 = else?
	beq	case1			@	if so,  jump to evaluate expressions1
	call	memv			@ sv1 <- sublist or #f (look for key-val sv1 in datum sv2)
	eq	sv1, #f			@ key not in datum?
	itT	eq
	careq	sv1, dts		@	if so,  sv1 <- key-val, restored
	cdreq	sv4, sv4		@	if so,  sv4 <- rest of datum-list
	beq	case0			@	if so,  jump to continue scanning datum-list
case1:	@ evaluate expressions
	restor3	sv1, env, cnt		@ sv1 <- dummy, env <- original env, cnt <- cnt, dts <- (...)
	cdar	sv1, sv4		@ sv1 <- (expr1 expr2 ...)
	b	sqnce
casext:	@ exit without match
	restor3	sv1, env, cnt		@ sv1 <- dummy, env <- original env, cnt <- cnt, dts <- (...)
	set	sv1, #f
	set	pc, cnt


pand:	@ (and exp1 exp2 ...)
	@ on entry:	sv1 <- (exp1 exp2 ...),		sv5<- env
	@ on exit:	sv1 <- result
	set	sv4, #t			@ sv4 <- #t, default value with no args
	b	andor			@ jump to common and/or process loop


por:	@ (or exp1 exp2 ...)
	@ on entry:	sv1 <- (exp1 exp2 ...),		sv5<- env
	@ on exit:	sv1 <- result
	set	sv4, #f			@ sv4 <- #f, default value with no args
andor:	@ [internal entry] common loop for and/or
	nullp	sv1			@ no arguments?
	itT	eq
	seteq	sv1, sv4		@	if so,  sv1 <- default result
	seteq	pc,  cnt		@	if so,  return with default result
	set	sv3, sv1		@ sv3 <- (exp1 exp2 ...)
	savrec	sv4			@ dts <- (dflt env cnt ...)
andorL:	@ evaluate body of function, one expression at a time
	@ sv3 <- body = (exp1 exp2 ...),  dts <- (env cnt ...)
	snoc	sv1, sv3, sv3		@ sv1 <- exp1,			sv2 <- (exp2 ...)
	nullp	sv3			@ are we at last expression?
	beq	andorT			@	if so,  jump to process it as a tail call
	cadr	env, dts		@ env <- env
	save	sv3			@ dts <- ((exp2 ...) env cnt ...)
	call	eval			@ sv1 <- val1, from evaluating sv1 in default environment
	restor	sv3			@ sv3 <- (exp1 exp2 ...),	dts <- (env cnt ...)
	car	sv4, dts		@ sv4 <- default val (#t for AND, #f for OR)
	eq	sv1, sv4		@ is result = default (AND with #t or OR with #f)
	beq	andorL			@	if so,  jump to keep looping
	eq	sv1, #f			@ is result #f?
	it	ne
	eqne	sv4, #f			@	if not, is default #f (i.e. OR)?
	bne	andorL			@		if neither, jump to keep looping (AND with NOT #f)
andoxt:	@ immediate exit
	cdr	dts, dts		@ dts <- (env cnt ...)
	restor2	env, cnt		@ env <- env, cnt <- cnt, dts <- (...)
	set	pc, cnt			@ return
andorT:	@ tail-call for last expression in function body
	cdr	dts, dts		@ dts <- (env cnt...)
	restor2	env, cnt		@ env <- env, cnt <- cnt, dts <- (...)
	b	eval			@ jump to evaluate tail


plet:	@ (let <name> bindings-list exp1 exp2 ...)
	@ on entry:	sv1 <- name or bindings-list
	@ on entry:	sv2 <- (bindings-list exp1 exp2 ...) or (exp1 exp2 ...)
	@ on exit:	sv1 <- result
	save	sv1			@ dts <- (<name>-or-b-lst ...)
	varp	sv1			@ is this a named-let?
	it	eq
	snoceq	sv1, sv2, sv2		@	if so,  sv1 <- b-lst,	sv2 <- (exp1 exp2 ...)
	save	sv2			@ dts <- ((exp1 exp2 ...) <name>-or-b-lst ...)
	set	sv5, #null		@ sv5 <- '()
	list	sv2, sv5		@ sv2 <- (() . var-list-tail)
	list	sv5, sv5		@ sv5 <- (() . uval-list-tail)
	save2	sv2, sv5		@ dts <- ((() . vrlst) (() . uvllst) (ex1 ex2 ..) <nam>-or-blst ..)
	set	sv3, sv1		@ sv3 <- bindings-list
let0:	@ build lists of init vars and init uvals
	nullp	sv3			@ is bindings-list done?
	beq	let1			@	if so, jump to continue
	snoc	sv1, sv3, sv3		@ sv1 <- binding1,		sv3 <- rest of bindings-list
	snoc	sv1, sv4, sv1		@ sv1 <- var1,			sv4 <- (uval1)
	list	sv1, sv1		@ sv1 <- (var1)
	setcdr	sv2, sv1		@ store (var1) at tail of sv2
	set	sv2, sv1		@ sv2 <- new var list tail
	car	sv4, sv4		@ sv4 <- uval1
	list	sv4, sv4		@ sv4 <- (uval1)
	setcdr	sv5, sv4		@ store (uval1) at tail of sv5
	set	sv5, sv4		@ sv5 <- new uval list tail
	b	let0			@ jump to continue building var and uval lists
let1:	@ extract built-lists and expr list from stack
	restor2	sv2, sv5		@ sv2 <- (() . vrlst), sv5<-(().uvllst), dts<-((ex1.) <nam>|blst .)
	cdr	sv2, sv2		@ sv2 <- var-list
	cdr	sv5, sv5		@ sv5 <- uval-list
	restor	sv3			@ sv3 <- (exp1 exp2 ...),	dts <-  (<name>-or- b-lst ...)
	car	sv4, dts		@ sv4 <- <name> or b-lst
	varp	sv4			@ is this a named-let?
	it	ne
	bne	let2			@	if not, jump to continue
	list	sv4, sv4		@ sv1 <- (name) = upcoming binding for name
	list	sv1, sv4		@ sv1 <- ((name)) = upcoming binding frame for name	
	cons	env, sv1, env		@ env <- updated environment for named-let
let2:	@ build lambda and jump to eval
	set	sv1, #procedure		@ sv1 <- procedure tag
	orr	sv1, sv1, #0x4000	@ sv1 <- full proc tag
	tagwenv	sv1, sv1, sv2, sv3	@ sv1 <- proc == [proc_tag vars-list (body) env]
	restor	sv2			@ sv2 <- <name> or b-lst,	dts <- (...)
	varp	sv2			@ is this a named-let?
	it	eq
	setcdreq sv4, sv1		@	if so,  store binding for named-let in environment
	cons	sv1, sv1, sv5		@ sv1 <- ((procedure env (var1 ...) (exp1 exp2 ...)) uval1 ...)
	b	eval			@ jump to evaluate the lambda


plets:	@ (let* bindings-list exp1 exp2 ...)
	@ on entry:	sv1 <- bindings-list
	@ on entry:	sv2 <- (exp1 exp2 ...)
	@ on exit:	sv1 <- result
	sav_rc	sv2			@ dts <- ((exp1 ...) cnt ...)
lets0:	@ extend environment with binding for each init-var
	nullp	sv1			@ is bindings-list done?
	beq	lets1			@	if so, jump to continue
	snoc	sv1, sv3, sv1		@ sv1 <- binding1,		sv3 <- rest of bindings-list
	save	sv3			@ dts <- (rest-of-b-lst (exp1 ...) cnt ...)
	snoc	sv1, sv3, sv1		@ sv1 <- var1,			sv3 <- (uval1)
	list	sv1, sv1		@ sv1 <- (var1) = upcoming binding for var1
	list	sv1, sv1		@ sv1 <- ((var1)) = upcoming frame for var1
	cons	env, sv1, env		@ env <- environment for evaluation
	save	env			@ dts <- (env rest-of-b-lst (exp1 ...) cnt ...)
	car	sv1, sv3		@ sv1 <- uval1
	call	eval			@ sv1 <- val1
	restor	env			@ env <- env,			dts <- (rst-b-lst (exp1 ..) env ..)
	caar	sv2, env		@ sv2 <- (var1) = null binding for var1
	setcdr	sv2, sv1		@ store val1 in (var1) binding
	restor	sv1			@ sv1 <- rest-of-b-lst,		dts <- ((exp1 ...) cnt ...)
	b	lets0			@ jump to continue evaluating and binding the inits
lets1:	@ evaluate body in environment extended with let-bindings
	restor2	sv1, cnt		@ sv1 <- (exp1 ...), cnt <- cnt, dts <- (...)
	b	sqnce


pletr:	@ (letrec bindings-list exp1 exp2 ...)
	@ on entry:	sv1 <- bindings-list
	@ on entry:	sv2 <- (exp1 exp2 ...)
	@ on exit:	sv1 <- result
	save3	sv1, sv2, cnt		@ dts <- (let-bindings-lst (exp1 ...) cnt ...)
	@ build environment frame for let-vars
	set	sv3, sv1		@ sv3 <- let-bindings-list
	set	sv4, sv1		@ sv4 <- pseudo-val-list (used for initialization)
	call	mkfrm			@ env <- let-env = (new-frame . env)
	@ prepare to evaluate binding vals for let-vars
	car	sv3, dts		@ sv3 <- let-bindings-list
	save	env			@ dts <- (let-env let-bindings-list (exp1 ...) cnt ...)
	set	sv4, #null		@ sv4 <- initial list of vals for let-vars
letr2:	@ evaluate let-vals
	nullp	sv3			@ is bindings-list done?
	beq	letr3			@	if so, jump to continue
	car	env, dts		@ env <- let-env
	snoc	sv1, sv3, sv3		@ sv1 <- binding1,		sv3 <- rest of bindings-list
	cadr	sv1, sv1		@ sv1 <- uval1
	save2	sv4, sv3		@ dts <- (val-lst rst-b-lst let-env (exp1 ...) env cnt ...)
	call	eval			@ sv1 <- val1
	restor2	sv4, sv3		@ sv4 <- oldvlst, sv3 <- rstblst, dts <- (ltnv ltbds (ex1 .) cnt .)
	cons	sv4, sv1, sv4		@ sv4 <- (val1 ...) = updated vals list	
	b	letr2			@ jump to continue building init vals list
letr3:	@ keep going
	restor	env			@ env <- let-env,	dts <- (let-bindings-list (exp1 ..) cnt ..)
	restor3	sv3, sv1, cnt		@ sv3 <- let-bindings-lst, sv1 <- (ex1 ..), cnt <- cnt, dts <- (..)
	@ reverse vals list
	set	sv5, #null
ltr3_1:	nullp	sv4
	beq	ltr3_3
	snoc	sv2, sv4, sv4
	cons	sv5, sv2, sv5
	b	ltr3_1
ltr3_3:	@ bind vals to vars
	nullp	sv3			@ is let-bindings-list null?
	beq	sqnce
	snoc	sv2, sv3, sv3		@ sv2 <- (var uinit)
	car	rva, sv2		@ rva <- var
	car	sv4, env		@ sv4 <- current frame
ltr3_4:	@ bind var to val
	snoc	sv2, sv4, sv4		@ sv2 <- 1st binding in frame
	car	rvb, sv2		@ rvb <- 1st var in frame
	eq	rvb, rva		@ does var to add go farther in frame?
	bne	ltr3_4
	snoc	sv4, sv5, sv5
	setcdr	sv2, sv4
	b	ltr3_3


pdo:	@ (do ((var1 init1 <step1>) ...) (test expr1 expr2 ...) command1 command2 ...)
	@ on entry:	sv1 <- ((var1 init1 <step1>) ...)
	@ on entry:	sv2 <- (test expr1 expr2 ...)
	@ on entry:	sv3 <- (command1 command2 ...)
	@ on exit:	sv1 <- result
	save3	sv2, sv3, cnt		@ dts <- ((test expr1 ...) (command1 ...) cnt ...)
	save2	env, sv1		@ dts <- (env inits-list (test expr1 ...) (command1 ...) cnt ...)
	set	sv4, #null		@ sv4 <- '() = initial init-vals-list
do0:	@ build list of evaluated inits into sv4
	nullp	sv1			@ done with inits list?
	beq	do1			@	if so, jump to continue
	car	env, dts		@ env <- env
	snoc	sv1, sv2, sv1		@ sv1 <- (var1 init1 <step1>),	sv2 <- ((var2 init2 <step2>) ...)
	cadr	sv1, sv1		@ sv1 <- init1
	save2	sv4, sv2		@ dts <- (init-vals-list ((var2 init2 <step2>) ...) env ...)
	call	eval			@ sv1 <- init1-val
	restor	sv4			@ sv4 <- init-vals-list, dts <- (((var2 init2 <step2>) ...) env ..)
	cons	sv4, sv1, sv4		@ sv4 <- updated init-vals-list
	restor	sv1			@ sv1 <- ((vr2 in2 <stp2>) ..),	dts <- (env inits-list ...)
	b	do0			@ jump to continue evaluating inits
do1:	@ reverse vals list
	set	sv2, sv4
	set	sv4, #null
do1_b:	nullp	sv2
	beq	do1_c
	snoc	sv1, sv2, sv2
	cons	sv4, sv1, sv4
	b	do1_b
do1_c:	@ build environment frame for do-vars
	cadr	sv3, dts		@ sv3 <- inits-list
	car	env, dts		@ env <- saved env
	call	mkfrm			@ env <- do-env = (new-frame . env)
do5:	@ evaluate the test
	cddr	sv1, dts		@ sv1 <- ((test expr1 ...) (command1 ...) env cnt ...)
	caar	sv1, sv1		@ sv1 <- test
	save	env			@ dts <- (do-env env inits-list ...)
	call	eval			@ sv1 <- value of test
	eq	sv1, #f			@ done with do?
	bne	doexit			@	if so,  jump to exit
	@ evaluate the commands
	car	env, dts		@ env <- do-env
	cdddr	sv1, dts		@ sv1 <- ((test expr1 ...) (command1 ...) cnt ...)
	cadr	sv1, sv1		@ sv1 <- (command1 ...)
	call	sqnce
	@ evaluate the steps
	cddr	sv1, dts		@ sv1 <- (inits-list ...)
	car	sv1, sv1		@ sv1 <- ((var1 init1 <step1>) (var2 init2 <step2>) ...)
	set	sv4, #null		@ sv4 <- '() = initial init-vals-list
do6:	@ build list of evaluated steps into sv4 then jump back to iterate
	nullp	sv1			@ done with steps list?
	it	eq
	cdreq	dts, dts		@	if so,  dts <- (env inits-lst (test exp1 .) (cmd1 .) cnt .)
	beq	do1			@	if so,  jump to next iteration
	car	env, dts		@ env <- do-env
	snoc	sv1, sv2, sv1		@ sv1 <- (var1 init1 <step1>),	sv2 <- ((var2 init2 <step2>) ...)
	save2	sv4, sv2		@ dts <- (step-vals-list ((var2 init2 <step2>) ...) do-env ...)
	cddr	sv2, sv1		@ sv2 <- (<step>)
	nullp	sv2			@ no step?
	itE	eq
	careq	sv1, sv1		@	if so,  sv1 <- var1
	carne	sv1, sv2		@	if not, sv1 <- step1
	call	eval			@ sv1 <- step1-val
	restor	sv4			@ sv4 <- step-vals-list, dts <- (((var2 ini2 <stp2>) ..) do-env ..)
	cons	sv4, sv1, sv4		@ sv4 <- updated step-vals-list
	restor	sv1			@ sv1 <- ((vr2 in2 <stp2>) ..),	dts <- (do-env env inits-list ...)
	b	do6			@ jump to continue evaluating steps
doexit:	@ exit the do -- evaluate the expressions
	restor3	env, sv4, sv2		@ env <- donv, sv4 <- nv, sv2<-dmy, dts<-((tst e1 .) (cm1 .) cnt .)
	restor3	sv3, sv2, cnt		@ sv3 <- (test expr1 ...), sv2 <- dummy, cnt <- cnt, dts <- (...)
	set	sv2, #null		@ sv2 <- '()
	cdr	sv3, sv3		@ sv3 <- (expr1 ...)
	set	sv1, #procedure		@ sv1 <- procedure_tag
	orr	sv1, sv1, #0x4000	@ sv1 <- full proc tag	
	tagwenv	sv1, sv1, sv2, sv3	@ sv1 <- proc == [proc_tag vars-list (body) do-env]
	set	env, sv4		@ env <- env, restored
	b	apply			@ jump to evaluate expression sequence

	
pdelay:	@ (delay expr)
	@ on entry:	sv1 <- (expr)
	@ on exit:	sv1 <- (promise env () expr)
	set	sv2, sv1		@ sv2 <- (expr)
	set	sv1, #null		@ sv1 <- '()
	set	sv3, #procedure		@ sv3 <- partial proc tag
	orr	sv3, sv3, #0x4000	@ sv3 <- full proc tag
	tagwenv	sv1, sv3, sv1, sv2	@ sv1 <- proc == [proc_tag () expr env]
	b	mkprms


mkprms:	@ (_mkp proc)
	@ on entry:	sv1 <- proc = (lambda env () expr)
	@ on exit:	sv1 <- (promise env () expr)
	@ return a lambda with extended env
	@
	@ well, probably better off returning a compiled proc, branching to assembly code
	@ (maybe even two of those?)
	@
	@ var0 <- #f, var1 <- proc
	@ build var list
	ldr	sv2, =var0_var
	ldr	sv3, =var1_var
	ldr	sv4, =var2_var
	set	sv5, #null
	llcons	sv3, sv2, sv3, sv4, sv5	@ sv3 <- (var0 var1 var2)
	@ build val list
	set	sv2, #f	
	llcons	sv4, sv2, sv2, sv1, sv5	@ sv4 <- (#f #f proc)
	@ extend environment
	sav_ec				@ dts <- (env cnt ...)
	call	mkfrm
	@ build promise (compiled thunk with extended env)
	set	sv2, #null
	ldr	sv3, =prmcod
	set	sv4, #procedure
	orr	sv4, sv4, #0xC000
	tagwenv	sv1, sv4, sv2, sv3	@ sv1 <- promise == [promise_tag () prm-cod prm-env]
	restor2	env, cnt		@ env <- env, cnt <- cnt, dts <- (...)
	set	pc,  cnt
	

	PFUNC	0
prmcod:	@ code for make-promise
	ldr	sv1, =var0_var
	bl	bndchk
	eq	sv5, #t
	bne	prmco1
	ldr	sv1, =var1_var
	bl	bndchk
	set	sv1, sv5
	set	pc,  cnt
prmco1:	
	sav_ec
	ldr	sv1, =var2_var
	bl	bndchk
	set	sv1, sv5
	set	sv2, #null
	call	apply
	set	sv2, sv1
	restor2	env, cnt
	ldr	sv1, =var0_var
	bl	bndchk
	eq	sv5, #t
	bne	prmco2
	ldr	sv1, =var1_var
	bl	bndchk
	set	sv1, sv5
	set	pc,  cnt
prmco2:	@ set result in promise env
	ldr	sv1, =var0_var
	bl	bndchk
	set	sv4, #t
	setcdr	sv3, sv4
	ldr	sv1, =var1_var
	bl	bndchk
	setcdr	sv3, sv2
	set	sv1, sv2
	set	pc,  cnt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

.endif		@ .ifdef r3rs

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@			INTEGER ONLY (see general numbers further down)
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.2.	Numbers
@	6.2.5	Numerical operations:	zero?, positive?, negative?, odd?,
@					even?, max, min, abs, gcd, lcm
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
	
.ifdef	integer_only

zero:	@ (zero? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1
	izerop	sv1
	b	boolxt


positi:	@ (positive? obj)
	@ on entry:	sv1 <- obj	
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	izerop	sv1
	beq	notfxt
	postv	sv1			@ is number positive?
	b	boolxt			@ exit with #t/#f based on result

negati:	@ (negative? obj)
	@ on entry:	sv1 <- obj	
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	postv	sv1			@ is number positive?
	b	notfxt			@ exit with #f/#t based on result


odd:	@ (odd? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	intgrp	sv1			@ is sv1 an integer?
	bne	boolxt			@	if not, exit with #f
	tst	sv1, #0x04		@ is sv1 even?
	b	notfxt			@ return with not #t/#f

even:	@ (even? obj)
	@ on entry:	sv1 <- obj	
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	intgrp	sv1			@ is sv1 an integer?
	it	eq
	tsteq	sv1, #0x04		@	if so,  is it even?
	b	boolxt			@ return with #t/#f


_func_	
mmglen:	@ entry for max, min, gcd, lcm (integer only version)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on entry:	sv5 <- binary operator = maxint, minint, gcdint or lcmint
	@ on exit:	sv4 <- startup value for rdcnml
	nullp	sv1			@ are there no arguments?
	itE	eq
	seteq	sv4, sv1		@	if so,  sv4 <- '()
	carne	sv4, sv1		@	if not, sv4 <- num1
	b	rdcnml			@ jump to reduce arg-list using operator and default value


	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
max:	@ (max num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on exit:	sv1 <- max of (num1 num2 ...)
	@ modifies:	sv1-sv5, rva-rvc
	cmp	sv1, sv2		@ is x1 >= x2 ?
	it	mi
	setmi	sv1, sv2		@	if not, sv1 <- x2 (largest number)
	set	pc,  lnk		@ return with largest number in sv1


	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
min:	@ (min num1 num2 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	cmp	sv1, sv2		@ is x1 >= x2 ?
	it	pl
	setpl	sv1, sv2		@	if not, sv1 <- x2 (smallest number)
	set	pc,  lnk		@ return with smallest number in sv1


abs:	@ (abs number)
	@ on entry:	sv1 <- number
	iabs	sv1, sv1
	set	pc,  cnt


	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
gcd:	@ (gcd n1 ...)
	@ on entry:	sv1 <- (num1 num2 ...)
_func_
gcdint:	@ gcd for int
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save	sv3
	set	sv3, sv1
	set	sv1, #i0
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
	orr	lnk, sv3, #lnkbit0
	set	pc,  lnk

	
	EPFUNC	null, ommglen, 0		@ primitive, init-sv4 = none, fentry = mmglen, narg = listed
lcm:	@ (lcm n1 ...)			  ((n1 ...) ...) -> (int ...)
	@ on entry:	sv1 <- (num1 num2 ...)
	eq	sv1, #i0
	it	ne
	eqne	sv2, #i0
	itT	eq
	seteq	sv1, #i0
	seteq	pc,  lnk
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	iabs	sv1, sv1
	iabs	sv2, sv2
	save3	sv1, sv2, sv3		@ dts <- (int1 int2 lnk ...)
	bl	gcdint			@ sv1 <- gcd of int1 and int2 (scheme int)
	set	sv2, sv1
	restor	sv1			@ sv1 <- int1,		dts <- (int2 lnk ...)
	bl	idivid			@ sv1 <- n1 / gcd (scheme int)
	restor2	sv2, sv3		@ sv2 <- int2, sv3 <- lnk, dts <- (...)
	orr	lnk, sv3, #lnkbit0
	b	prdint
	
.endif

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

zero:	@ (zero? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1
	zerop	sv1
	b	boolxt


_func_	
pstrat:	@ positive? for rat
	numerat	sv1, sv1
_func_	
pstint:	@ positive? for int
_func_	
pstflt:	@ positive? for flt
	zerop	sv1
	beq	notfxt
	postv	sv1			@ is number positive?
	b	boolxt			@ exit with #t/#f based on result


_func_	
ngtrat:	@ negative? for rat
	numerat	sv1, sv1
_func_	
ngtint:	@ negative? for int
_func_	
ngtflt:	@ negative? for flt
	postv	sv1			@ is number positive?
	b	notfxt			@ exit with #f/#t based on result

	
odd:	@ (odd? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	intgrp	sv1			@ is sv1 an integer?
	bne	boolxt			@	if not, exit with #f
	tst	sv1, #0x04		@ is sv1 even?
	b	notfxt			@ return with not #t/#f


even:	@ (even? obj)
	@ on entry:	sv1 <- obj	
	@ on exit:	sv1 <- #t/#f
	@ modifies:	sv1, rva
	intgrp	sv1			@ is sv1 an integer?
	it	eq
	tsteq	sv1, #0x04		@	if so,  is it even?
	b	boolxt			@ return with #t/#f

_func_
mmglen:	@ entry for max, min, gcd, lcm (general numbers version)
	@ on entry:	sv1 <- (num1 num2 ...)
	@ on entry:	sv5 <- binary operator table = maxtb, mintb, gcdtb or lcmtb
	@ on exit:	sv4 <- startup value for rdcnml
	nullp	sv1			@ are there no arguments?
	itE	eq
	seteq	sv4, sv1		@	if so,  sv4 <- '()
	carne	sv4, sv1		@	if not, sv4 <- num1
	b	rdcnml			@ jump to reduce arg-list using operator and default value


_func_	
maxflt:	@ max for flt
	anynan	sv1, sv2
	beq	nanlxt
	postv	sv1			@ is x1 positive?
	it	ne
	postvne	sv2			@	if so,  is x2 negative?
	bne	minint			@	if so,  jump to compare that (both floats negative)
	postv	sv1			@ is x1 positive or 0?
	itE	ne
	setne	sv1, sv2		@	if not, sv1 <- x2 (largest number)
	postveq	sv2			@	if so,  is x2 positive or 0?
	it	ne
	setne	pc,  lnk		@	if not, (either is negative) exit with the non-negative one
	@ continue to maxint

_func_	
maxint:	@ max for int
	cmp	sv1, sv2		@ is x1 >= x2 ?
	it	mi
	setmi	sv1, sv2		@	if not, sv1 <- x2 (largest number)
	set	pc,  lnk		@ return with largest number in sv1

_func_	
maxrat:	@ max for rat
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3
	denom	sv1, sv1
	numerat	sv2, sv2
	bl	prdint
	set	sv3, sv1
	snoc	sv1, sv2, dts
	car	sv2, sv2
	numerat	sv1, sv1
	denom	sv2, sv2
	bl	prdint
	set	sv2, sv3
	ldr	rvc, =gttb
mxmnrt:	@ max/min common completion for rat
	bl	numjmp	
	eq	sv1, #f
	restor3	sv1, sv2, sv3
	orr	lnk, sv3, #lnkbit0
	it	eq
	seteq	sv1, sv2		@	if not, sv1 <- x2 (largest number)
	denom	sv2, sv1
	eq	sv2, #5
	it	eq
	nmrtreq	sv1, sv1
	set	pc,  lnk		@ return with largest number in sv1


_func_	
minflt:	@ min for flt
	anynan	sv1, sv2
	beq	nanlxt
	postv	sv1			@ is x1 negative?
	it	ne
	postvne	sv2			@	if so,  is x2 negative?
	bne	maxint			@	if so,  jump to compare that (both floats negative)
	postv	sv2			@ is x2 positive or 0?
	itE	ne
	setne	sv1, sv2		@	if not, sv1 <- x2 (smallest number)
	postveq	sv1			@	if so,  is x1 positive or 0?
	it	ne
	setne	pc,  lnk		@	if not, (either is negative) exit with the negative one
	@ continue to minint

_func_	
minint:	@ min for int
	cmp	sv1, sv2		@ is x1 >= x2 ?
	it	pl
	setpl	sv1, sv2		@	if not, sv1 <- x2 (smallest number)
	set	pc,  lnk		@ return with smallest number in sv1
	
_func_	
minrat:	@ min for rat
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3
	denom	sv1, sv1
	numerat	sv2, sv2
	bl	prdint
	set	sv3, sv1
	snoc	sv1, sv2, dts
	car	sv2, sv2
	numerat	sv1, sv1
	denom	sv2, sv2
	bl	prdint
	set	sv2, sv3
	ldr	rvc, =lttb
	b	mxmnrt			@ jump to common completion of max/min for rat


_func_
gcdflt:	@ gcd for flt
	bic	sv3, lnk, #lnkbit0	@ sv5 <- lnk, saved (and made even if Thumb2)
	save	sv3
	bl	itrunc
	set	sv3, sv1
	set	sv1, sv2
	bl	itrunc
	set	sv2, sv1
	set	sv1, #f0
	b	gcdien

_func_
gcdrat:	@ gcd for rat
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3		@ dts <- (rat1 rat2 lnk ...)
	denom	sv1, sv1
	denom	sv2, sv2
	bl	lcmint			@ sv1 <- lcm of denom1 and denom2 (scheme int)
	restor2	sv2, sv3		@ sv2 <- rat1, sv3 <- rat2, dts <- (lnk ...)
	save	sv1			@ dts <- (denom-lcm lnk ...)
	numerat	sv1, sv2
	numerat	sv2, sv3
	bl	gcdint			@ sv1 <- numerat-gcd
	restor2	sv2, sv3		@ sv2 <- denom-lcm, sv3 <- lnk, dts <- (...)
	orr	lnk, sv3, #lnkbit0	@ lnk <- lnk, restored
	b	makrat			@ jump to make rational result


_func_
lcmint:	@ lcm for int
	eq	sv1, #i0
	it	ne
	eqne	sv2, #i0
	itT	eq
	seteq	sv1, #i0
	seteq	pc,  lnk
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	iabs	sv1, sv1
	iabs	sv2, sv2
	save3	sv1, sv2, sv3		@ dts <- (int1 int2 lnk ...)
	bl	gcdint			@ sv1 <- gcd of int1 and int2 (scheme int)
	set	sv2, sv1
	restor	sv1			@ sv1 <- int1,		dts <- (int2 lnk ...)
	bl	idivid			@ sv1 <- n1 / gcd (scheme int)
	restor2	sv2, sv3		@ sv2 <- int2, sv3 <- lnk, dts <- (...)
	orr	lnk, sv3, #lnkbit0
	b	prdint

_func_
lcmflt:	@ lcm for flt
	eq	sv1, #f0
	it	ne
	eqne	sv2, #f0
	itT	eq
	seteq	sv1, #f0
	seteq	pc,  lnk
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save	sv3
	bl	itrunc
	swap	sv1, sv2, sv3
	bl	itrunc
	bl	lcmint
	restor	sv3			@ sv3 <- lnk,		dts <- (...)
	orr	lnk, sv3, #lnkbit0
	b	i12flt

_func_
lcmrat:	@ lcm for rat
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save3	sv1, sv2, sv3		@ dts <- (rat1 rat2 lnk ...)
	denom	sv1, sv1
	denom	sv2, sv2
	bl	gcdint			@ sv1 <- gcd of denom1 and denom2 (scheme int)
	restor2	sv2, sv3		@ sv2 <- rat1, sv3 <- rat2, dts <- (lnk ...)
	save	sv1			@ dts <- (denom-gcd lnk ...)
	numerat	sv1, sv2
	numerat	sv2, sv3
	bl	lcmint			@ sv1 <- numerat-lcm
	restor2	sv2, sv3		@ sv2 <- denom-gcd, sv3 <- lnk, dts <- (...)
	orr	lnk, sv3, #lnkbit0	@ lnk <- lnk, restored
	izerop	sv2
	it	eq
	seteq	pc,  lnk
	b	makrat			@ jump to make rational result


_func_
rtzint:	@ rationalize for int
	iabs	sv2, sv2
	set	sv5, sv1
	iabs	sv1, sv1
	set	sv4, sv2
	bl	plsint
	set	sv2, sv4
	set	sv4, sv1
	set	sv1, sv5
	iabs	sv1, sv1
	bl	mnsint
	eor	rva, sv1, sv4
	postv	rva
	it	ne
	setne	sv1, #i0
rtzrxi:	@ exit for int
	postv	sv5
	it	ne
	ngintne	sv1, sv1
	set	pc,  cnt
	
_func_
rtzflt:	@ rationalize for flt
	isnan	sv1
	it	eq
	seteq	pc,  cnt
	@ rationalize with x and y as flt
	set	sv4, sv1	@ sv4 <- x
	fabs	sv1, sv2	@ sv1 <- |y|
	ldr	sv5, =rtyspc
	bl	spcflt
	set	sv1, sv4	@ sv1 <- x
	ldr	sv5, =rtxspc
	bl	spcflt
	@ exit with 0.0 if range is larger than val (i.e. spans 0)
	fabs	sv1, sv2	@ sv1 <- |y|
	fabs	sv3, sv4	@ sv3 <- |x|
	cmp	sv1, sv3
	bpl	f0fxt
	@ find top and bottom of interval (and sort, in absolute value, in case top/bottom are unsorted)
	set	sv2, sv4	@ sv2 <- x
	set	sv3, sv1	@ sv3 <- |y|
	bl	plsflt		@ sv1 <- top-signed = x + |y|
	set	sv2, sv3	@ sv2 <- |y|
	set	sv3, sv1	@ sv3 <- top-signed
	set	sv1, sv4	@ sv1 <- x
	bl	mnsflt		@ sv1 <- bottom-signed = x - |y|
	sav_rc	sv1		@ dts <- (bottom-signed cnt ...)
	fabs	sv1, sv1
	fabs	sv2, sv3
	set	sv4, #null
	cmp	sv1, sv2
	bmi	rtzflp
	swap	sv1, sv2, rva
rtzflp:	@ loop
	save3	sv1, sv2, sv4	@ dts <- (bottom top coeffs top-signed cnt ...)
	call	dnmflt
	set	sv3, sv1	@ sv3 <- denom-bottom	
	restor3	sv1, sv2, sv4	@ sv1 <- bottom, sv2 <- top, sv4 <- coeffs, dts <- (top-signed cnt ...)
	set	sv5, sv1	@ sv5 <- bottom
	ldr	rvc, =scheme_one
	eq	sv3, rvc
	beq	rtzfx1
	bl	itrunc
	set	sv3, sv1	@ sv3 <- truncated bottom
	set	sv1, sv2
	bl	itrunc		@ sv1 <- truncated top
	eq	sv1, sv3
	bne	rtzfx0
	cons	sv4, sv3, sv4	@ sv4 <- updated coeffs list
	@ sv5 <- bottom, sv2 <- top, sv4 <- coefs list
	set	sv1, sv2
	bl	flt2ndn		@ sv1 <- numer-top, sv2 <- denom-top
	set	sv3, sv2	@ sv3 <- denom-top
	bl	idivid		@ sv2 <- remainder-top
	set	sv1, sv3	@ sv1 <- denom-top
	bl	i12flt
	save	sv4
	set	sv4, sv5	@ sv4 <- bottom
	bl	unidiv		@ sv1 <- denom-top/remainder-top
	swap	sv1, sv4, sv3	@ sv1 <- bottom, sv4 <- denom-top/remainder-top
	bl	flt2ndn		@ sv1 <- numer-bottom, sv2 <- denom-bottom
	set	sv3, sv2	@ sv3 <- denom-bottom
	bl	idivid		@ sv2 <- remainder-bottom
	set	sv1, sv3	@ sv1 <- denom-bottom
	bl	i12flt
	bl	unidiv		@ sv1 <- denom-bottom/remainder-bottom
	set	sv2, sv1	@ sv2 <- denom-bottom/remainder-bottom
	set	sv1, sv4	@ sv1 <- denom-top/remainder-top
	restor	sv4		@ sv4 <- coefs list
	b	rtzflp
rtzfx0:	@ build 1+truncated bottom
	ldr	sv2, =scheme_one
	set	sv1, sv3	@ sv1 <- truncated bottom
	bl	i12flt
	bl	plsflt
rtzfx1:	@ sv1 <- bottom or 1+truncated bottom
	@ sv4 <- coeffs list
	nullp	sv4
	beq	rtzfxt
	set	sv2, sv1
	ldr	sv1, =scheme_one
	bl	divflt
	snoc	sv2, sv4, sv4
	adr	lnk, rtzfx1
	b	unipls
	
rtzfxt:	@ exit
	restor2	sv5, cnt
	postv	sv5
	it	ne
	ngfltne	sv1, sv1
	set	pc,  cnt

_func_
rtzrat:	@ rationalize for rat
	@ rationalize with x and y as rat
	@ return nan if sv1 == 0/0
	rawsplt	rva, rvb, sv1
	eq	rva, #3
	it	eq
	eqeq	rvb, #0
	it	eq
	seteq	pc,  cnt
	@ return nan if sv2 == 0/0
	rawsplt	rva, rvb, sv2
	eq	rva, #3
	it	eq
	eqeq	rvb, #0
	itT	eq
	seteq	sv1, sv2
	seteq	pc,  cnt
	@ return 0 if sv2 == 1/0
	eq	rva, #0x13
	it	eq
	eqeq	rvb, #0
	beq	i0fxt
	@ return 0 if sv2 == -1/0
	mvn	rvc, rva
	eq	rvc, #0x0c
	it	eq
	eqeq	rvb, #3
	beq	i0fxt
	@ return sv1 if sv2 == 0/1
	eq	rva, #3
	it	eq
	eqeq	rvb, #4
	it	eq
	seteq	pc,  cnt
	@ return sv1 if sv1 == +/- 1/0
	ldr	rvb, [sv1]
	bic	rvb, rvb, #3
	eq	rvb, #0
	it	eq
	seteq	pc,  cnt	
	@ check if |x| <= |y| if so, return 0
	numerat	sv5, sv1
	sav_rc	sv5		@ dts <- (x-numerat-signed cnt ...)
	set	sv4, sv1	@ sv4 <- x
	set	sv1, sv2	@ sv1 <- y
	call	absrat		@ sv1 <- |y|
	set	sv5, sv1	@ sv5 <- |y|
	set	sv1, sv4	@ sv1 <- x
	call	absrat		@ sv1 <- |x|
	set	sv4, sv1	@ sv4 <- |x|
	set	sv2, sv5	@ sv2 <- |y|
	save	sv5		@ dts <- (|y| x-numerat-signed cnt ...)
	bl	unipls		@ sv1 <- top
	restor	sv2		@ sv2 <- |y|,	dts <- (x-numerat-signed cnt ...)
	save	sv1		@ dts <- (top x-numerat-signed cnt ...)
	set	sv1, sv4	@ sv1 <- |x|
	bl	unimns		@ sv1 <- bottom
	restor	sv2		@ sv2 <- top,	dts <- (x-numerat-signed cnt ...)
	bl	uninum		@ sv1 and sv2 both int or rat	
	intgrp	sv1
	bne	rtlzr0
	eor	rva, sv1, sv2
	postv	rva
	beq	rtlzr1
rtzaxt:	@ exit with 0	
	restor2	sv5, cnt
	b	i0fxt
	
rtlzr0:	@
	numerat	sv3, sv1
	numerat	sv4, sv2
	eor	rva, sv3, sv4
	postv	rva
	bne	rtzaxt
rtlzr1:		
	set	sv4, #null
rtzrlp:	@ loop
	@ sv1 <- bottom, sv2 <- top
	intgrp	sv1
	beq	rtzrx1
	denom	sv3, sv1
	eq	sv3, #5
	it	eq
	nmrtreq	sv1, sv3
	beq	rtzrx1
	set	sv3, sv1	@ sv3 <- bottom
	spltrat	sv1, sv2, sv2	@ sv1 <- top-numerator, sv2 <- top-denominator
	save	sv2		@ dts <- (top-denominator x-signed cnt ...)
	bl	idivid		@ sv1 <- top-quotient, sv2 <- top-remainder
	set	sv5, sv2	@ sv5 <- top-remainder
	set	sv2, sv3	@ sv2 <- bottom
	set	sv3, sv1	@ sv3 <- top-quotient
	spltrat	sv1, sv2, sv2	@ sv1 <- bottom-numerator, sv2 <- bottom-denominator
	save	sv2		@ dts <- (bottom-denominator top-denominator x-signed cnt ...)
	bl	idivid		@ sv1 <- bottom-quotient, sv2 <- bottom-remainder
	eq	sv1, sv3
	bne	rtzrx0
	cons	sv4, sv1, sv4	@ sv4 <- updated coeffs list
	@ sv2 <- bottom-remainder, sv5 <- top-remainder
	restor	sv1		@ sv1 <- bottom-denominator, dts <- (top-denominator x-signed cnt ...)
	bl	makrat		@ sv1 <- bottom-denominator/bottom-remainder
	set	sv2, sv5	@ sv2 <- top-remainder
	set	sv5, sv1	@ sv5 <- bottom-denominator/bottom-remainder
	restor	sv1		@ sv1 <- top-denominator, dts <- (x-signed cnt ...)
	bl	makrat		@ sv1 <- top-denominator / top-remainder
	set	sv2, sv5	@ sv2 <- bottom-denominator / bottom-remainder
	adr	lnk, rtzrlp
	b	uninum
	
rtzrx0:	@ build 1+bottom-quotient
	cddr	dts, dts
	add	sv1, sv1, #4
rtzrx1:	@ sv1 <- bottom or 1+truncated bottom
	@ sv4 <- coeffs list
	nullp	sv4
	beq	rtzrxt
	set	sv2, sv1
	set	sv1, #5
	bl	unidiv
	snoc	sv2, sv4, sv4
	adr	lnk, rtzrx1
	b	unipls
	
rtzrxt:	@ exit
	restor2	sv5, cnt
	intgrp	sv1
	beq	rtzrxi
	spltrat	sv1, sv2, sv1
	postv	sv5
	it	ne
	ngintne	sv1, sv1
	set	lnk, cnt
	b	makrat

.endif

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.3.	Other Data Types
@	6.3.1.	booleans:		not, boolean?
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	Requires:
@			core:		boolxt
@
@	Modified by (switches):			
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


pbooln:	@ (boolean? obj)
	@ on entry:	sv1 <-obj
	@ on exit:	sv1 <- #t if obj = #t or #f, else #f
	eq	sv1, #t
	it	ne
	eqne	sv1, #f
	b	boolxt

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.3.	Other Data Types
@	6.3.2.	Pairs and list:		caar, cadr, ..., cdddar, cddddr,
@					null?, list?, list, length, append, reverse,
@					list-tail, list-ref, memq, memv, member,
@					assq, assv, assoc
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


_func_	
cxxxxr:	@ (cxxxxr obj)
	@ on entry:	sv1 <- list
	@ on entry:	sv4 <- car/cdr code (scheme int)
	@ on entry:	sv5 <- symbol of function after the one that called cxxxxr (for error4)
	@
	@ code in sv4 is 8-bits, lsb 0 means car, lsb 1 means cdr,
	@ code is shifted right at each step and process ends when code = 1.
	@
	lsr	rvb, sv4, #2		@ rvb <- car/cdr code (raw)
jxxxxr:	@ (cxxxxr list)
	@ uses code in rvb to determine car/cdr
	eq	rvb, #1			@ done with car/cdr code?
	it	eq
	seteq	pc,  cnt		@	if so,  exit
	pairp	sv1			@ is it a pair?
	bne	corerr
	tst	rvb, #1			@ is bit 0 of rva a one?
	itE	eq
	careq	sv1, sv1		@	if not, sv1 <- (car list)
	cdrne	sv1, sv1		@	if so,  sv1 <- (cdr list)
	lsr	rvb, rvb, #1		@ rva <- shifted car/cdr code
	b	jxxxxr			@ jump to continue


plistp:	@ (list? obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- #t/#f
	ldr	rvc, =heapbottom	@ rvc <- heap bottom address
	ldr	rva, =heaptop1		@ rva <- heap top address
	sub	rvc, rva, rvc		@ rvc <- max number of bytes to search
	lsr	rvc, rvc, #3		@ rvc <- max number of cons cells to search
	set	sv3, sv1		@ sv3 <- start of list -- for cyclic list
qlist0:	nullp	sv1			@ is list '()?
	beq	boolxt			@	if so,  return #t
	pairp	sv1			@ is item a pair?
	bne	notfxt			@	if not, return #f
	cdr	sv1, sv1		@ sv1 <- (cdr obj)
	subs	rvc, rvc, #1		@ rvc <- remaining max number of cons cells to search, is it zero?
	beq	flsfxt			@	if so,  return #f
	b	qlist0			@ jump to keep going through potential list


plngth:	@ (length list)
	@ on entry:	sv1 <- list
	@ on exit:	sv1 <- length of list (scheme int)
	ldr	rvc, =heapbottom	@ rvc <- heap bottom address
	ldr	rva, =heaptop1		@ rva <- heap top address
	sub	rvc, rva, rvc		@ rvc <- max number of bytes to search
	lsr	rvc, rvc, #3		@ rvc <- max number of cons cells to search
	set	sv2, #i0		@ sv2 <- initial list length = 0 (scheme int)
lengt0:	nullp	sv1			@ at end of list?
	itT	eq
	seteq	sv1, sv2		@	if so,  sv1 <- length
	seteq	pc,  cnt		@	if so,  return with length
	pairp	sv1			@ is object a pair?
	bne	flsfxt			@	if not, return #f
	cdr	sv1, sv1		@ sv1 <- (cdr obj)
	incr	sv2, sv2		@ sv2 <- updated list length
	subs	rvc, rvc, #1		@ rvc <- remaining max number of cons cells to search, is it zero?
	beq	flsfxt			@	if so,  return #f
	b	lengt0			@ jump back to keep going


pappnd:	@ (append list1 list2 ...)
	@ on entry:	sv1 <- (list1 list2 ...)
	@ on exit:	sv1 <- appended lists
	set	sv4, sv1		@ sv4 <- (list1 list2 ...)
	set	sv1, #null		@ sv1 <- '()
	list	sv5, sv1		@ sv5 <- (null . null) = (() tail-ref)
	save	sv5			@ dts <- ((() tail-ref) ...)
appen0:	nullp	sv4			@ done?
	beq	appext			@	if so,  jump to exit
	snoc	sv3, sv4, sv4		@ sv3 <- list1,  sv4 <- (list2 ...)
	nullp	sv4			@ is rest-of lists null?
	it	eq
	setcdreq sv5, sv3		@	if so,  store last list as cdr of appended result
	beq	appext			@	if so,  jump to exit
appen2:	nullp	sv3			@ is list1 null?
	beq	appen0			@	if so,  branch to process next list
	snoc	sv1, sv3, sv3		@ sv1 <- car1 == car of list1,  sv3 <- rest of list1
	list	sv1, sv1		@ sv1 <- (car1)
	setcdr	sv5, sv1		@ set (car1) as cdr of result
	set	sv5, sv1		@ sv5 <- result's tail
	b	appen2			@ jump to continue appending
appext:	restor	sv1			@ sv1 <- (() . result),		dts <- (...)
	cdr	sv1, sv1		@ sv1 <- result
	set	pc,  cnt


prevrs:	@ (reverse list)
	@ on entry:	sv1 <- list
	@ on exit:	sv1 <- reversed list
	set	sv2, sv1		@ sv2 <- list
	set	sv1, #null		@ sv1 <- '() = initial reversed list

_func_
rvrls0:	pairp	sv2		@ item is a list?
	it	ne
	setne	pc,  cnt		@	if not, return reversed list in sv1
	set	sv3, sv1		@ sv2 <- current reversed list
	snoc	sv1, sv2, sv2		@ sv1 <- car of rest of list,		sv4  <- cdr of rest of list
	cons	sv1, sv1, sv3		@ sv1 <- (car . reversed list) = updated reversed list
	b	rvrls0


plstal:	@ (list-tail list k)
	@ on entry:	sv1 <- list
	@ on entry:	sv2 <- k
	@ on exit:	sv1 <- tail of list or ()
	set	sv3, #f
	b	lstre0


plstrf:	@ (list-ref list k)
	@ on entry:	sv1 <- list
	@ on entry:	sv2 <- k
	@ on exit:	sv1 <- k-th item from list or ()
	set	sv3, #t
lstre0:	nullp	sv1			@ is list empty?
	it	eq
	seteq	pc,  cnt		@	if so,  exit with null as result
	izerop	sv2			@ is k zero?
	itT	ne
	cdrne	sv1, sv1		@ sv1 <- (cdr list)
	decrne	sv2, sv2		@ sv2 <- k - 1 (scheme int)
	bne	lstre0			@ jump to continue looking for ref
	eq	sv3, #t
	it	eq
	careq	sv1, sv1
	set	pc,  cnt


pmemv:	@ (memv obj list)
	@ on entry:	sv1 <- obj
	@ on entry:	sv2 <- list
	@ on exit:	sv1 <- sub-list or #f
	@ modifies:	sv1, sv2, sv3
	swap	sv1, sv2, sv3
memv0:	nullp	sv1			@ is list null?
	beq	notfxt
	car	sv3, sv1		@ sv3 <- (car list)
	eq	sv2, sv3		@ is car list = obj?
	it	eq
	seteq	pc,  cnt
	cdr	sv1, sv1		@ sv1 <- (cdr list)
	b	memv0			@ jump to continue looking for obj


pmembr:	@ (member obj list)
	@ on entry:	sv1 <- obj
	@ on entry:	sv2 <- list
	@ on exit:	sv1 <- sub-list or #f
	sav_rc	sv1			@ dts <- (obj cnt ...)
membe0:	nullp	sv2			@ is list null?
	it	eq
	seteq	sv1, #f			@	if so,  sv1 <- #f
	beq	membxt			@	if so,  jump to exit with #f
	car	sv1, dts		@ sv1 <- obj
	save	sv2			@ dts <- (list obj cnt ...)
	car	sv2, sv2		@ sv2 <- arg = (car list)
	call	pequal			@ sv1 <- #t/#f, from (equal sv1 sv2)
	restor	sv2			@ sv2 <- list,		dts <- (obj cnt ...)
	eq	sv1, #t			@ was object found?
	it	eq
	seteq	sv1, sv2
	beq	membxt			@	if so,  jump to exit with rest of list
	cdr	sv2, sv2		@ sv1 <- (cdr list) = restlist
	b	membe0			@ jump to continue looking for obj
membxt:	cdr	dts, dts		@ dts <- (cnt ...)
	restor	cnt			@ cnt <- cnt,		dts <- (...)
	set	pc,  cnt


passq:	@ (assq obj alist)
	@ on entry:	sv1 <- obj
	@ on entry:	sv2 <- alist
	@ on exit:	sv1 <- binding-or-#f
	@ on exit:	sv2 <- null-or-rest-of-alist
	@ on exit:	sv3 <- obj
	@ preserves:	sv4-sv5
	set	sv3, sv1		@ sv3 <- obj = key
assq0:	@ loop
	nullp	sv2			@ is binding-list null?
	beq	notfxt			@	if so,  exit with #f
	snoc	sv1, sv2, sv2		@ sv1 <- 1st binding,		sv2 <- rest of binding-list
	car	sv4, sv1		@ sv4 <- bkey of 1st binding (bkey . bval) in binding-list
	eq	sv3, sv4		@ is bkey = key ?
	bne	assq0			@	if not, jump to keep searching
	set	pc,  cnt		@ return with binding in sv1


passoc:	@ (assoc key binding-list)
	@ on entry:	sv1 <- key
	@ on entry:	sv2 <- binding-list
	@ on exit:	sv1 <- binding-or-#f
	sav_rc	sv1			@ dts <- (key cnt ...)
assoc0:	@ sv1 <- binding-list, dts <- (key ...)
	nullp	sv2			@ is binding-list null?
	it	eq
	seteq	sv1, #f			@	if so,  sv1 <- #f
	beq	assoxt			@	if so,  jump to exit with #f
	car	sv1, dts		@ sv1 <- key
	save	sv2			@ dts <- (binding-list key cnt ...)
	caar	sv2, sv2		@ sv2 <- key
	call	pequal			@ sv1 <- #t/#f, from (equal sv1 sv2)
	restor	sv2			@ sv2 <- binding-list,	dts <- (key cnt ...)
	eq	sv1, #t			@ was a binding found?
	it	ne
	cdrne	sv2, sv2		@	if not, sv2 <- rest-of-binding-list
	bne	assoc0			@	if not, jump to continue searching
	car	sv1, sv2		@ sv1 <- winning binding
assoxt:	cdr	dts, dts		@ dts <- (cnt ...)
	restor	cnt			@ cnt <- cnt,		dts <- (...)
	set	pc,  cnt

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.3.	Other Data Types
@	6.3.4.	Characters:		char-ci=?, char-ci<?, char-ci>?,
@					char-ci<=?, char-ci>=?, char-alphabetic?
@					char-numeric?, char-whitespace?,
@					char-upper-case?, char-lower-case?,
@					char-upcase, char-downcase
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

pchceq:	@ (char-ci=? char1 char2):	
	@ on entry:	sv1 <- char1
	@ on entry:	sv2 <- char2
	@ on exit:	sv1 <- #t/#f
	ldr	lnk, =pcheq
	b	toloc2			@ sv1, sv2 <- lower case char1, char2 and jump to char=?


pchclt:	@ (char-ci<? char1 char2)
	@ on entry:	sv1 <- char1
	@ on entry:	sv2 <- char2
	@ on exit:	sv1 <- #t/#f
	ldr	lnk, =pchlt
	b	toloc2			@ sv1, sv2 <- lower case char1, char2 and jump to char<?


pchcgt:	@ (char-ci>? char1 char2)
	@ on entry:	sv1 <- char1
	@ on entry:	sv2 <- char2
	@ on exit:	sv1 <- #t/#f
	ldr	lnk, =pchgt
	b	toloc2			@ sv1, sv2 <- lower case char1, char2 and jump to char>?


pchcle:	@ (char-ci<=? char1 char2)
	@ on entry:	sv1 <- char1
	@ on entry:	sv2 <- char2
	@ on exit:	sv1 <- #t/#f
	ldr	lnk, =pchle
	b	toloc2			@ sv1, sv2 <- lower case char1, char2 and jump to char<=?


pchcge:	@ (char-ci>=? char1 char2)
	@ on entry:	sv1 <- char1
	@ on entry:	sv2 <- char2
	@ on exit:	sv1 <- #t/#f
	ldr	lnk, =pchge
	b	toloc2			@ sv1, sv2 <- lower case char1, char2 and jump to char>=?


pchalp:	@ (char-alphabetic? char)
	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- #t/#f
	bl	tolocs			@ rvc <- #t/#f based on whether sv1 is upper case
	eq	rvc, #t			@ is char upper case?
	it	ne
	blne	toupcs			@	if not,  rvc <- #t/#f based on whether sv1 is lower case
	set	sv1, rvc		@ sv1 <- #t/#f result (#t if upper case or lower case)
	set	pc,  cnt		@ return


pchnum:	@ (char-numeric? char)
	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- #t/#f
	set	rvb, #'9		@ rvb <- ascii char 9
	chr2raw	rva, sv1		@ rva <- raw char
	cmp	rva, #'0		@ is char >= ascii char 0?
	it	pl
	cmppl	rvb, rva		@	if so,  is char <= ascii char 9?
	itE	pl
	setpl	sv1, #t			@		if so,  sv1 <- #t
	setmi	sv1, #f			@		if not, sv1 <- #f
	set	pc,  cnt		@ return with #t/#f

	
pchspa:	@ (char-whitespace? char)
	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- #t/#f
	chr2raw	rvb, sv1
	eq	rvb, #'\r		@ is char a carriage return?
	it	ne
	eqne	rvb, #'  		@	if not, is char a space?
	it	ne
	eqne	rvb, #'			@	if not, is char a tab?
	it	ne
	eqne	rvb, #'\n		@	if not, is char a lf?
	b	boolxt			@ return with #t/#f


pchupq:	@ (char-upper-case? char)
	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- #t/#f
	bl	tolocs			@ rvc <- #t/#f based on whether sv1 is upper case
	set	sv1, rvc		@ sv1 <- result
	set	pc,  cnt		@ return


pchloq:	@ (char-lower-case? char)
	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- #t/#f
	bl	toupcs			@ rvc <- #t/#f based on whether sv1 is lower case
	set	sv1, rvc		@ sv1 <- result
	set	pc,  cnt		@ return


pchupc:	@ (char-upcase char)
	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- char in upper case
	set	lnk, cnt
	b	toupcs

pchdnc:	@ (char-downcase char)
	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- char in lower case
	set	lnk, cnt
	b	tolocs
	
.balign	4
	
toupcs:	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- upper case version of char
	@ on exit:	rvc <- #t/#f based on whether char was lower case or not
	set	rvb, #'z
	chr2raw	rva, sv1
	cmp	rva, #'a
	it	pl
	cmppl	rvb, rva
	itTE	pl
	bicpl	sv1, sv1, #0x2000	@	if so,  sv1 <- upper case version of char
	setpl	rvc, #t
	setmi	rvc, #f
	set	pc,  lnk

.balign	4
	
_func_
toloc2:	@ on entry:	sv1 <- char1
	@ on entry:	sv2 <- char2
	@ on exit:	sv1 <- lower case version of char1
	@ on exit:	sv2 <- lower case version of char2
	@ on exit:	rvc <- #t/#f based on whether char1 was upper case or not
	set	rvb, #'Z
	chr2raw	rva, sv2
	cmp	rva, #'A
	it	pl
	cmppl	rvb, rva
	it	pl
	orrpl	sv2, sv2, #0x2000
_func_
tolocs:	@ on entry:	sv1 <- char
	@ on exit:	sv1 <- lower case version of char
	@ on exit:	rvc <- #t/#f based on whether char was upper case or not
	set	rvb, #'Z
	chr2raw	rva, sv1
	cmp	rva, #'A
	it	pl
	cmppl	rvb, rva
	itTE	pl
	orrpl	sv1, sv1, #0x2000
	setpl	rvc, #t
	setmi	rvc, #f
	set	pc,  lnk

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.3.	Other Data Types
@	6.3.5.	Strings:		string, string=?,
@					string-ci=?, string<?, string>?,
@					string<=?, string>=?, 
@					string-ci<?, string-ci>?,
@					string-ci<=?, string-ci>=?,
@					substring, string-append,
@					string->list, list->string,string-copy,
@					string-fill
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


pstrng:	@ (string char1 char2 ...)
	@ on entry:	sv1 <- (char1 char2 ...)
	@ on exit:	sv1 <- string
	set	sv5, sv1		@ sv5 <- char list (saved)
	set	sv2, #i0		@ sv2 <- initial list length = 0 (scheme int)
strin0:	nullp	sv1
	itT	ne
	cdrne	sv1, sv1
	incrne	sv2, sv2
	bne	strin0
	straloc	sv1, sv2		@ sv1 <- allocated string of size sv2
	set	sv3, #i0		@ sv3 <- offset to start address of items (scheme int)
strin1:	cmp	sv3, sv2		@ done copying chars?
	it	pl
	setpl	pc,  cnt		@	if so,  return string
	snoc	sv4, sv5, sv5		@ sv4 <- 1st char (scheme char),  sv5 <- remaining chars list
	strset	sv1, sv3, sv4
	incr	sv3, sv3
	b	strin1


strequ:	@ (string=? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pcheq		@ sv5 <- address of comparison routine
streq0:	@ [ internal entry]
	strlen	sv3, sv1		@ sv3 <- length of string1
	strlen	sv4, sv2		@ sv4 <- length of string2
	eq	sv3, sv4		@ are string lengths equal?
	bne	boolxt			@	if not, return with #f
strcmp:	@ [internal entry] string comparison based on function in sv5
	save3	sv1, sv2, cnt		@ dts <- (string1 string2 cnt ...)
	strlen	sv3, sv1		@ sv3 <- length of string1
	strlen	sv4, sv2		@ sv4 <- length of string2
	cmp	sv4, sv3		@ is string2 shorter than string1?
	it	mi
	setmi	sv3, sv4		@	if so,  sv3 <- shortest string length
	save	sv3			@ dts <- (length string1 string2 cnt ...)
	set	sv1, #t			@ sv1 <- #t = initial result
	set	sv4, #i0		@ sv4 <- 0, start char offset (scheme int)
	ldr	cnt, =strcrt		@ cnt <- comparison return address
strclp:	@ loop to compare chars
	snoc	sv2, sv3, dts		@ sv2 <- count, sv3 <- (string1 string2 cnt ...)
	eq	sv2, sv4		@ done comparing?
	beq	strcxt			@	if so,  jump to exit
	snoc	sv1, sv2, sv3		@ sv1 <- string1, sv2 <- (string2 cnt ...)
	car	sv2, sv2		@ sv2 <- string2
	strref	sv1, sv1, sv4		@ sv1 <- char1, from string1
	strref	sv2, sv2, sv4		@ sv2 <- char2, from string2
	set	pc,  sv5		@ sv1 <- #t/#f from jump to comparison routine
strcrt:	eq	sv1, #f			@ did test fail?
	beq	strcxt			@	if so,  jump to exit
	add	sv4, sv4, #4		@ sv4 <- offset f next char
	b	strclp			@ jump to keep comparing chars
strcxt:	@ exit
	restor	sv2			@ sv2 <- length, dts <- (string1 string2 cnt ...)
	restor3	sv2, sv3, cnt		@ sv2 <- string1, sv3 <- string2, cnt <- cnt, dts <-(...)
	set	pc,  cnt		@ return


strceq:	@ (string-ci=? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchceq		@ sv5 <- address of comparison routine
	b	streq0


strlt:	@ (string<? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchlt		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


strgt:	@ (string>? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchgt		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


strle:	@ (string<=? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchle		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


strge:	@ (string>=? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchge		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


strclt:	@ (string-ci<? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchclt		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


strcgt:	@ (string-ci>? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchcgt		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


strcle:	@ (string-ci<=? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchcle		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


strcge:	@ (string-ci>=? string1 string2)
	@ on entry:	sv1 <- string1
	@ on entry:	sv2 <- string2
	@ on exit:	sv1 <- #t/#f
	ldr	sv5, =pchcge		@ sv5 <- address of comparison routine
	b	strcmp			@ jump to compare strings and return with #t/#f


substr:	@ (substring string start end)
	@ on entry:	sv1 <- list
	@ on entry:	sv2 <- start
	@ on entry:	sv3 <- end
	@ on exit:	sv1 <- string
	set	lnk, cnt
	b	subcpy


strapp:	@ (string-append st1 st2 ...)
	@ on entry:	sv1 <- (st1 st2 ...)
	@ on exit:	sv1 <- string
	set	sv5, sv1		@ sv5 <- (st1 st2 ...)
	set	sv4, sv1		@ sv4 <- (st1 st2 ...)
	@ count total number of chars in strings to be appended
	set	sv2, #i0		@ sv2 <- initial size
strap0:	nullp	sv4			@ done counting chars?
	beq	strap1			@	if so,  jump to allocate new string
	snoc	sv1, sv4, sv4		@ sv1 <- st1,  sv4 <- (st2 ...)
	strlen	sv3, sv1		@ sv3 <- number of characters in st1
	plus	sv2, sv2, sv3		@ sv2 <- updated character count
	b	strap0			@ jump to keep counting chars
strap1:	@ allocate memory for new string
	straloc	sv1, sv2		@ sv1 <- newly-allocated target string
	@ append strings into new string
	set	sv4, #i0		@ sv4 <- offset to start address of items (scheme int)
strap2:	nullp	sv5			@ done with all strings?
	it	eq
	seteq	pc,  cnt		@	if so,  return
	snoc	sv3, sv5, sv5		@ sv3 <- source string,  sv5 <- rest-of-source-string-list
	strlen	sv2, sv3		@ sv2 <- number of characters in source string
	set	rvb, #i0		@ rvb <- offset to start address in source
strap3:	eq	rvb, sv2		@ done with this string?
	beq	strap2			@	if so,  jump to process next string
	strref	rva, sv3, rvb		@ rva <- source raw ASCII char
	strset	sv1, sv4, rva		@ store it in target string
	incr	rvb, rvb		@ rvb <- updated offset to source char
	incr	sv4, sv4		@ sv4 <- updated offset to destination char
	b	strap3			@ jump to keep copying


strlst:	@ (string->list string)
	@ on entry:	sv1 <- string
	@ on exit:	sv1 <- list
	set	sv3, sv1		@ sv3 <- string
	strlen	sv4, sv3		@ sv4 <- number of characters in string
	set	sv1, #null		@ sv1 <- '()
strls0:	izerop	sv4			@ done making list?
	it	eq
	seteq	pc,  cnt		@	if so,  return
	set	sv2, sv1		@ sv2 <- previous list of characters (for cons)
	decr	sv4, sv4		@ sv4 <- offset of next character
	strref	sv1, sv3, sv4		@ sv1 <- next character
	cons	sv1, sv1, sv2		@ sv1 <- (char ...) = updated list of characters
	b	strls0			@ jump to process rest of string


lststr:	@ (list->string list)
	@ on entry:	sv1 <- list
	@ on exit:	sv1 <- string
	b	pstrng


strcpy:	@ (string-copy string)
	@ on entry:	sv1 <- string
	@ on exit:	sv1 <- string
	set	sv2, #i0		@ sv2 <- position of 1st char (scheme int)
	strlen	sv3, sv1		@ sv3 <- position after last char (scheme int)
	b	substr


strfil:	@ (string-fill! string char)
	@ on entry:	sv1 <- string
	@ on entry:	sv2 <- char
	@ on exit:	sv1 <- string
	strlen	sv3, sv1		@ sv3 <- string length (scheme int)
	chr2raw	rvb, sv2		@ rvb <- ascii char
	b	fill8			@ perform fill and return

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.3.	Other Data Types
@	6.3.6.	Vectors:		vector, vector->list, list->vector,
@					vector-fill
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


vector:	@ (vector item1 item2 ...)
	@ on entry:	sv1 <- (item1 item2 ...)
	@ on exit:	sv1 <- vector == #(item1 item2 ...)
	b	plsvec


pvclst:	@ (vector->list vector)
	@ on entry:	sv1 <- vector
	@ on exit:	sv1 <- list
	@ preserves:	sv2 (for wrtvec:)
	set	sv4, sv1		@ sv4 <- vector
	veclen	sv5, sv4		@ sv5 <- number of items, (scheme int)
	set	sv1, #null		@ sv1 <- '() = initial result list
vecls0:	izerop	sv5			@ no more vector items?
	it	eq
	seteq	pc,  cnt		@	if so,  exit
	set	sv3, sv1		@ sv3 <- current result list
	decr	sv5, sv5		@ sv5 <- position of next item from vector
	vecref	sv1, sv4, sv5		@ sv1 <- item from vector
	cons	sv1, sv1, sv3		@ sv1 <- updated result list
	b	vecls0			@ jump to continue


plsvec:	@ (list->vector list) --- used by parsqt
	@ on entry:	sv1 <- list   ==  (item1 item2 ...)
	@ on exit:	sv1 <- vector == #(item1 item2 ...)
	@ preserves:	none
	set	sv5, sv1		@ sv5 <- items list (saved)
	sav__c				@ dts <- (cnt ...)
	set	sv2, sv1
	set	sv1, #i0
lstvln:	nullp	sv2
	itT	ne
	cdrne	sv2, sv2
	addne	sv1, sv1, #4
	bne	lstvln	
	set	sv2, #null		@ sv2 <- '() = fill for vector
	call	pmkvec			@ sv1 <- new, cleared vector of size sv1
	restor	cnt
	set	sv2, #i0		@ sv2 <- position of 1st vector item
lstve0:	nullp	sv5			@ done copying?
	it	eq
	seteq	pc,  cnt		@	if so,  exit
	snoc	sv4, sv5, sv5		@ sv4 <- next item,  sv5 <- remaining items
	vecset	sv1, sv2, sv4		@ store item in vector
	incr	sv2, sv2		@ sv2 <- position of next vector item
	b	lstve0			@ jump to continue copying from list to vector


pvcfll:	@ (vector-fill! vector fill)
	@ on entry:	sv1 <- vector
	@ on entry:	sv2 <- fill
	@ on exit:	sv1 <- vector == #(fill fill ...)
	b	vecfil

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.4.	control features:	map, for-each,	force
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


map:	@ (map fun list1 list2 ...)
	@ on entry:	sv1 <- fun
	@ on entry:	sv2 <- (list1 list2 ...)
	set	sv3, #null
mapfor:	@ common loop for map/for-each
	save3	sv3, sv1, cnt		@ dts <- (()=val-list-or-#npo fun cnt ...)
	set	sv1, sv2		@ sv1 <- (list1 list2 ...)
_func_
mapf0:	nullp	sv1			@ is list of lists null?
	itT	ne
	carne	sv2, sv1		@	if not, sv1 <- list1
	nullpne	sv2			@	if not, is list1 null?
	beq	mapfxt			@	if so,  exit (lol or list is null)
	set	sv4, sv1		@ sv4 <- (list1 list2 ...) -- saved against cars
	set	sv3, sv4		@ sv3 <- (list1 list2 ...) -- for cars
	call	cars			@ sv1 <- (item1 item2 ...) -- cars of lists
	set	sv2, sv1		@ sv2 <- (item1 item2 ...)
	cadr	sv1, dts		@ sv1 <- fun
	save	sv4			@ dts <- ((list1 list2 ...) val-list fun cnt ...)
	call	apply			@ sv1 <- new-val, from applying fun in sv1 to (itm1 itm2 ...) = sv2
	restor	sv3			@ sv3 <- (list1 list2 ...),	dts <- (val-lst-or-#npo fun cnt ..)
	adr	cnt, mapf0		@ cnt <- mapf0 (return for cdrs)
	car	sv2, dts		@ sv2 <- val-list-or-#npo
	eq	sv2, #npo		@ doing for-each?
	beq	cdrs			@	if so,  sv1 <- (cdr-list1 cdr-list2 ...), and jump to mapf0
	cdr	dts, dts		@ dts <- (fun cnt ...)
	cons	sv1, sv1, sv2		@ sv1 <- new-val-list
	save	sv1			@ sv1 <- (new-val-list fun cnt ...)
	b	cdrs			@ sv1 <- (cdr-list1 cdr-list2 ...), and jump to mapf0
mapfxt:	@ exit
	restor3	sv1, sv2, cnt		@ sv1 <- val-list-or-#npo, sv2 <- dummy, cnt <- cnt, dts <- (...)
	eq	sv1, #npo		@ doing for-each?
	it	eq
	seteq	pc, cnt			@	if so,  return with npo
	b	prevrs			@ reverse val-list in sv1 and exit via cnt


foreac:	@ (for-each fun list1 list2 ...)
	@ on entry:	sv1 <- fun
	@ on entry:	sv2 <- (list1 list2 ...)
	set	sv3, #npo
	b	mapfor


force:	@ (force promise)
	@ on entry:	sv1 <- promise
	set	sv2, #null		@ sv2 <- '()
	b	apply

/*------------------------------------------------------------------------------
@  II.H.6.     Standard Procedures
@  II.H.6.4.   control features SUPPORT:		cars, cdrs
@-----------------------------------------------------------------------------*/

.balign	4

cars:	@ return a list of cars	of the lists in sv3
	set	sv1, #null		@ sv1 <- '() = initial result
itcars:	nullp	sv3			@ done with lists?
	beq	irevrs			@	if so,  jump to reverse list and return via cnt
	set	sv2, sv1		@ sv2 <- (...) = current result
	car	sv1, sv3		@ sv1 <- arg1
	pntrp	sv1			@ is sv1 a pointer?
	it	eq
	careq	sv1, sv1		@	if so,  sv1 <- car-arg1
	cons	sv1, sv1, sv2		@ sv1 <- (car-arg1 ...)
	cdr	sv3, sv3		@ sv3 <- (arg2 arg3 ...)
	b	itcars			@ jump to continue consing cars
	
cdrs:	@ return a list of cdrs	of the lists in sv3
	set	sv1, #null		@ sv1 <- '() = initial result
itcdrs:	nullp	sv3			@ done with lists?
	beq	irevrs			@	if so,  jump to reverse list and return via cnt
	set	sv2, sv1		@ sv2 <- (...) = current result
	car	sv1, sv3		@ sv1 <- arg1
	pntrp	sv1			@ is arg1 a pointer?
	it	eq
	cdreq	sv1, sv1		@	if so,  sv1 <- cdr-arg1
	cons	sv1, sv1, sv2		@ sv1 <- (cdr-arg ...)
	cdr	sv3, sv3		@ sv3 <- (arg2 arg3 ...)
	b	itcdrs			@ jump to continue consing cdrs

irevrs:	@ reverse the list in sv1
	@ sv1  -> sv1  (iso-memory, uses sv2, sv3)
	set	sv2, #null		@ sv2 <- '() = initial result
	nullp	sv1			@ is input list null?
	it	eq
	seteq	pc,  cnt		@	if so,  return
precnt:	cdr	sv3, sv1		@ sv3 <- cdr of input list
	setcdr	sv1, sv2		@ sv2 -> cdr of input list
	nullp	sv3			@ done with input list?
	it	eq
	seteq	pc,  cnt		@	if so,  return
	set	sv2, sv1		@ sv2 <- input list
	set	sv1, sv3		@ sv1 <- cdr of input list
	b	precnt

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	6.	Standard Procedures
@	6.6.	Input and Output
@	6.6.1.	ports:			call-with-input-file,
@					call-with-output-file,
@	6.6.3.	output:			newline
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


cwinpf:	@ (call-with-input-file string <port-model> proc)
	@ on entry:	sv1 <- string
	@ on entry:	sv2 <- port-model or proc
	@ on entry:	sv3 <- proc or ()
	nullp	sv3			@ is port-model provided?
	itT	eq
	seteq	sv3, sv2		@	if not, sv3 <- proc
	seteq	sv2, #null		@	if not, sv2 <- () (no port)
	save3	sv1, sv3, cnt		@ dts <- (string proc cnt ...)
	call	opnifl			@ sv1 <- file handle or 0
	set	sv2, sv1		@ sv2 <- file handle or 0
	restor2	sv3, sv1		@ sv3 <- string, sv1 <- proc, dts <- (cnt ...)
	eq	sv2, #i0		@ unable to open?
	beq	cwifer			@	if so,  jump to report error
	list	sv2, sv2		@ sv2 <- (file-handle)
	save	sv2			@ dts <- ((file-handle) cnt ...)
	call	apply			@ sv1 <- result of calling proc on port
	restor2	sv1, cnt		@ sv1 <- (file-handle), cnt <- cnt, dts <- (...)
	set	sv4, #(0x80 | t)
	bl	ioprfe
	b	clsipr			@ jump to close input port, return via cnt
	
cwifer:	@ error in call-with-input-file
	set	sv1, sv3		@ sv2 <- argument (fun or argl) that caused the error
	ldr	sv4, =scwipf		@ sv1 <- address of function with error
	b	error4


cwoutf:	@ (call-with-output-file string <port-model> proc)
	@ on entry:	sv1 <- string
	@ on entry:	sv2 <- port-model or proc
	@ on entry:	sv3 <- proc or ()
	nullp	sv3			@ is port-model provided?
	itT	eq
	seteq	sv3, sv2		@	if not, sv3 <- proc
	seteq	sv2, #null		@	if not, sv2 <- () (no port)
	save3	sv1, sv3, cnt		@ dts <- (string proc cnt ...)
	call	opnofl			@ sv1 <- file handle or 0
	set	sv2, sv1		@ sv2 <- file handle or 0
	restor2	sv3, sv1		@ sv3 <- string, sv1 <- proc, dts <- (cnt ...)
	eq	sv2, #i0		@ unable to open?
	beq	cwofer			@	if so,  jump to report error
	list	sv2, sv2		@ sv2 <- (file-handle)
	save	sv2			@ dts <- ((file-handle) cnt ...)
	call	apply			@ sv1 <- result of calling proc on port
	restor2	sv1, cnt		@ sv1 <- (file-handle), cnt <- cnt, dts <- (...)
	set	sv2, #null		@ sv2 <- '() = normal close mode
	b	clsopr			@ jump to close output port, return via cnt
cwofer:	@ error in call-with-output-file
	set	sv1, sv3		@ sv2 <- argument (fun or argl) that caused the error
	ldr	sv4, =scwopf		@ sv1 <- address of function with error
	b	error4


pnewln:	@ (newline <port> <reg> <n> ...)
	@ on entry:	sv1 <- (<port> <reg> <n> ...) or (((port <reg> <n> ...) . port-vector))
	@ on exit:	sv1 <- npo
	set	sv2, sv1		@ sv2 <- (<port> <reg> <n> ...)
	set	rvb, #'\r
	raw2chr	sv1, rvb
	set	sv4, #((0x02<<2)|i0)
	b	ioprfn			@ jump to write the newline (cr)

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg


@-------.-------.-------.-------.-------+
@	system utility  sub-environment	|
@-------.-------.-------.-------.-------+


p_dfnd:	@ (defined? var)
	@ on entry:	sv1 <- var
	@ on exit:	sv1 <- #t/#f
	bl	bndchk
	nullp	sv3
	b	notfxt


link:	@ (link cvec)
	@ on entry:	sv1 <- cvec = #(code-bytevector *asm-comp-link* *compile-syms* *long-jumps*)
	@ on exit:	sv1 <- linked code bytevector
	vcrfi	sv2, sv1, 0		@ sv2 <- code-bytevector
	save3	sv2, sv1, cnt		@ dts <- (code-bytevector cvec cnt ...)
	@ link the symbols used by the compiled code
	vcrfi	sv5, sv1, 1		@ sv5 <- *asm-comp-link*
p_ln00:	@ loop over compiler symbols to link
	nullp	sv5			@ done linking compiler symbols?
	beq	p_lnlj			@	if so,  jump to link long jumps
	save	sv5			@ dts <- (symbols-to-link code-bytevector cvec cnt ...) 
	car	sv4, sv5		@ sv4 <- position of first symbol to link (pos . key)
	cdr	sv4, sv4		@ sv4 <- symbol key in *compile-syms* a-list
	caddr	sv1, dts		@ sv1 <- cvec = #(code-bv *as-lnk* *comp-syms* *lng-jmps*)
	vcrfi	sv3, sv1, 2		@ sv3 <- *compile-syms*
p_ln01:	@ search loop for symbol name
	nullp	sv3			@ done scanning *compile-syms*?
	beq	corerr			@	if so,  report error (key must be in a-list)
	snoc	sv2, sv3, sv3		@ sv2 <- (key1 . symname1), sv3 <- rest of *compile-syms*
	car	rva, sv2		@ rva <- key1
	eq	rva, sv4		@ key found?
	bne	p_ln01			@	if not, jump to check next item in *compile-syms*
	cdr	sv1, sv2		@ sv1 <- symbol-name (string)
	call	pstsym			@ sv1 <- symbol (from name)
	restor	sv5			@ sv5 <- *asm-comp-link*, dts <- (code-bytevector cvec cnt ...)
	snoc	sv4, sv5, sv5		@ sv4 <- 1st sym to lnk (pos . key), sv5 <- rst of *asm-comp-link*
	car	sv4, sv4		@ sv4 <- position of symbol in code (scheme int)
	int2raw	rva, sv4		@ rva <- position of symbol in code (raw int)
	car	sv2, dts		@ sv2 <- code bytevector
	str	sv1, [sv2, rva]		@ store symbol in code bytevector
	b	p_ln00			@ jump to link other symbols
p_lnlj:	@ link the long jumps
	cadr	sv1, dts		@ sv1 <- cvec
	vcrfi	sv5, sv1, 3		@ sv5 <- *long-jumps*
p_ln04:	@ loop
	nullp	sv5			@ done linking long jumps?
	beq	p_lnxt			@	if so,  jump to exit
	save	sv5			@ dts <- (long-jumps code-bytevector cvec cnt ...)
	cdar	sv1, sv5		@ sv1 <- first long jump target name (string)
	call	pstsym			@ sv1 <- first long jump target name (symbol)
	bl	bndchk			@ sv5 <- long jump preamble address (i.e. cdr of binding)
	set	rva, sv5		@ rva <- function code start address
	restor	sv5			@ sv5 <- long jumps, dts <- (code-bytevector cvec cnt ...)
	snoc	sv4, sv5, sv5		@ sv4 <- first long jump, sv5 <- rest of long jumps
	car	sv4, sv4		@ sv4 <- position of first long jump in code (scheme int)	
	int2raw	rvb, sv4		@ rvb <- position of first long jump in code (raw int)
	car	sv1, dts		@ sv1 <- code bytevector
	str	rva, [sv1, rvb]		@ store long jump in code bytevector
	b	p_ln04			@ jump to link other long jumps
p_lnxt:	@ done, return
	restor3	sv1, sv2, cnt		@ sv1 <- code bytevector, sv2 <- cvec (dummy), cnt <- cnt
	set	pc,  cnt		@ return
	
@ (define (link cvec)
@   (let ((code (vector-ref cvec 0)))
@     ;; link the symbols used by the compiled code
@     (map
@      (lambda (lvar)
@	(let ((n (car lvar))
@	      (s (string->symbol (cdr (assq (cdr lvar) (vector-ref cvec 2))))))
@	  (bytevector-u16-native-set!
@	   code n (bitwise-ior (bitwise-arithmetic-shift s 2) #x0f)) ; synt/var
@	  (bytevector-u16-native-set! code (+ n 2) (bitwise-arithmetic-shift s -14))))
@      (vector-ref cvec 1))
@     ;; link the long jumps
@     (map
@      (lambda (ljmp)
@	(bytevector-copy!
@	 (address-of (eval (string->symbol (cdr ljmp)) (interaction-environment)) 4)
@	 0 code (car ljmp) 4))
@      (vector-ref cvec 3))
@     code))


p_upah:	@ (unpack-above-heap obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- result
	set	sv2, #i1
_func_
p_upae:	@ [internal entry]
	vctrp	sv1
	bne	unpack
	sav_rc	sv2
	call	link
	restor2	sv2, cnt
	b	unpack

.ifndef exclude_lib_mod

p_libs:	@ (libs)
	@ on exit:	sv1 <- list of library names
	vcrfi	sv5, glv, 12
	set	sv1, #null
p_lib0:	@ loop
	nullp	sv5
	it	eq
	seteq	pc,  cnt
	set	sv2, sv1
	snoc	sv4, sv5, sv5
	vcrfi	sv1, sv4, 0
	vcrfi	sv1, sv1, 0
	list	sv1, sv1
	cons	sv1, sv1, sv2
	b	p_lib0

  .ifdef LIB_TOP_PAGE

p_erlb:	@ (erase-libs)
	@ on exit:	sv1 <- list of library names
	set	sv1, #i0
	orr	sv1, sv1, #0x80000000
	list	sv1, sv1
	b	erase


p_uplb:	@ (unpack-to-lib obj)
	@ on entry:	sv1 <- obj
	@ on exit:	sv1 <- result
	set	sv2, #f0	@ sv2 <- 0.0	(scheme float)
	mvn	sv2, sv2	@ sv2 <- -1	(scheme int)
	b	p_upae

  .endif	@ .ifdef LIB_TOP_PAGE

.endif	@ do not exclude_lib_mod







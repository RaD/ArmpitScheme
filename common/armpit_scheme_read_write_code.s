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

/*------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.4. System interface:	OPTIONAL:	load (used by boot)
@-----------------------------------------------------------------------------*/


pload:	@ (load filename <port-model>)
	@ on entry:	sv1 <- filename
	@ on entry:	sv2 <- <port-model> or null
	sav__c				@ dts <- (cnt ...)
	call	opnifl			@ sv1 <- port
	list	sv1, sv1		@ sv1 <- (port), for setipr
	set	sv4, #(0x80 | t)
	bl	ioprfe			@ sv1 <- full input-port
	save	sv1			@ dts <- (port cnt ...)
load1:	car	sv1, dts		@ sv1 <- port
	set	sv4, #((0x24<<2)|i0)
	call	ioprfn			@ sv1 <- expr read from file
	ldr	sv2, =eof_char		@ sv2 <- end-of-file character
	eq	sv1, sv2		@ end-of file found?
	beq	loadxt			@	if so,  jump to close file and exit
	vcrfi	env, glv, 7		@ env from glv (***NEW***)
	call	eval			@ sv1 <- result, from evaluating sv1 in default environment
	b	load1			@ jump back to read and evaluate next expression
loadxt:	@ exit
	restor	sv1			@ sv1 <- port, dts <- (cnt ...)
	restor	cnt			@ cnt <- cnt
	b	clsipr			@ close the input port, return npo via prtcli

/*------------------------------------------------------------------------------
@
@	CHARACTER INPUT/OUTPUT PORT -- COMMON FUNCTIONS
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input  SUPPORT 3 - character input  port:	pchred
@  II.A.6.6.3. output SUPPORT 3 - character output port:	pchwrt, rwrite
@-----------------------------------------------------------------------------*/


pchred:	@ read function for character input port (common to uart, file, usb)
	@ on entry:	sv1 <- ((<port> <reg> <n>) . port-vector) = full input port
	@ on exit:	sv1 <- parsed scheme expression
	@ modifies:	sv1, sv2, sv3, sv4, sv5, rva, rvb, rvc
	@ returns via cnt (through parse and mxpnd if needed)
	bl	getc0			@ sv4 <- prev chr pos or fil desc (for getc1)
					@ sv2 <- 0 or pos/desc cpy
	eq	sv2, #i0		@ port can be read?
	beq	readxt			@	if not, jump to return eof
	@ port can be read, proceed
	set	sv5, #0x15		@ sv5 <- par-cnt=0 (b16:31), commnt=#f (b4), par-inc=1 (b2)
	set	rvb, #0x0		@ rvb <- npo, pseudo-previous character
rdexp0:	@ wait for a full datum or eof
	bl	getc1			@ rvb <- raw char read,	rvc <- prev char, sv4 <- updtd pos/descr
	eq	rvb, #eof		@ is byte the end-of-file byte?
	beq	rdexp1			@	if so,  jump to process possible early end-of-input
	eq	rvb, #'\r		@ is char a carriage return?
	it	ne
	eqne	rvb, #'\n		@	if not, is char a line feed?
	itE	eq
	orreq	sv5, sv5, #0x10		@	if so,  set comment indicator to #f (set b4 in sv5)
	eqne	rvb, #' 		@	if not, is char a space?
	it	eq
	eqeq	sv5, #0x15		@	if so, is par-cnt=0, par-inc=1, comment=#f (scheme int)?
	beq	rdexp2			@			if so,  jump to extract and parse expr
	eq	rvb, #'\r		@ is char a carriage return?
	it	ne
	eqne	rvb, #'\n		@	if not, is char a line feed?
	beq	rdexp0			@		if so,  jump to keep scanning characters
	tst	sv5, #0x10		@ are we within a comment?
	beq	rdexp0			@	if so,  jump to keep scanning characters
	eq	rvc, #'\\		@ is previous character a \?
	it	eq
	seteq	rvb, 0x00		@	if so,  rvb <- npo (clear rvb in case of \\)
	beq	rdexp0			@	if so,  jump to process next chars
	and	rva, sv5, #0x04		@ rva <- paren-inc
	eq	rvb, #'(		@ is character a ( ?
	it	eq
	addeq	sv5, sv5, rva, lsl #6	@	if so,  sv5 <- paren-count increased by paren-inc
	beq	rdexp0			@	if so,  jump to keep scanning characters
	eq	rvb, #')		@ is character a ) ?
	it	eq
	subeq	sv5, sv5, rva, lsl #6	@	if so,  sv5 <- paren-count decreased by paren-inc

@ last minute change (June 18, 2011):	swap comments in 2 lines below to revert
@	beq	rdexp0			@ 	if so,  jump to keep scanning characters
	beq	rdexp4			@ 	if so,  jump to check if acceptable end of expression
	
	eq	rvb, #'"		@ is character a " ?
	it	eq
	eoreq	sv5, sv5, #0x04		@	if so,  sv5 <- paren-inc toggled (between 0 and 1)
	
@ last minute change (June 18, 2011):	swap comments in 2 lines below to revert
@	beq	rdexp0			@	if so,  jump to keep scanning characters
	beq	rdexp4			@	if so,  jump to check if acceptable end of expression
	
	eq	rvb, #';		@ is char a semi-colon?
	bne	rdexp0			@	if not, jump to keep scanning characters
	tst	sv5, #0x04		@ are we outside of a string (i.e. paren-inc=1)?
	it	ne
	bicne	sv5, sv5, #0x10		@		if so,  set comment indic to #t (clear b4 in sv5)
	b	rdexp0			@ jump to keep scanning characters
rdexp1: @ eof encountered -- return expr or eof or re-read buffer
	cdr	rva, sv1		@ rva <- port-vector
	vcrfi	rva, rva, 5		@ rva <- value of 'wait-for-cr' from port
	eq	rva, #t			@ wait for cr?
	beq	pchred			@	if so,  jump back to re-read buffer from start
	bic	rva, sv5, #0x10		@ rva <- paren-count and paren-inc (comment indicator cleared)
	eq	rva, #0x05		@ did we get a full expr (par-cnt=0 & par-inc=1, scheme int)?
	beq	rdexp3			@	if so,  jump to extract and parse
	b	readxt			@ jump to return eof
	
@ last minute change (June 18, 2011):	comment-out this block of code to revert
rdexp4:	@ closing parenthesis or double-quote encountered
	@ check if this is acceptable as end of expression
	eq	sv5, #0x15		@ is par-cnt=0, par-inc=1, comment=#f (scheme int)?
	bne	rdexp0
	cdr	rva, sv1		@ rva <- port-vector
	vcrfi	rva, rva, 5		@ rva <- value of 'wait-for-cr' from port
	eq	rva, #t			@ wait for cr?
	beq	rdexp0
	b	rdexp3

rdexp2:	@ full datum identified, ends in space or cr -- return expr or wait for cr
	cdr	rva, sv1		@ rva <- port-vector
	vcrfi	rva, rva, 5		@ rva <- value of 'wait-for-cr' from port
	eq	rva, #t			@ wait for cr?
	it	eq
	eqeq	rvb, #' 		@	if so,  was last char a space?
	beq	rdexp0			@		if so,  jmp to continue read from port (until cr)
rdexp3: @ extract expression from buffer/file based on sv2 and sv4 (pos/descriptor)
	bl	getc2			@ sv1 <- string read-in, side-effect: buffer/desriptor updated
	pntrp	sv1			@ was a string acquired?
	bne	readxt			@	if not, jump to exit with eof
.ifndef r3rs
	sav__c				@ dts <- (cnt ...)
	call	pparse			@ sv1 <- parsed expression
	vcrfi	sv5, glv, 14
	nullp	sv5
	bne	rdexp9
	restor	cnt			@ cnt <- cnt, dts <- (...)
	b	pmxpnd			@ sv1 <- parsed expr with expanded macros, return via cnt
rdexp9:	save	env
	set	env, sv5
	call	pmxpnd
	restor2	env, cnt
	set	pc,  cnt
.else
	b	pparse			@ sv1 <- parsed expression, return via cnt
.endif
	
readxt:	@ return eof
	ldr	sv1, =eof_char		@ sv1 <- eof
	set	pc,  cnt		@ return


pchwrt:	@ character output port write sub-function (common to uart, file, usb)
	@ on entry:	sv1 <- object
	@ on entry:	sv2 <- ((port offset ...) . port-vector) = full output port
	sav__c				@ dts <- (cnt ...)
	call	rwrite
	restor	cnt
	b	npofxt
	
_func_	
rwrite:	@ [internal entry] -- recursive entry point
	@ on entry:	sv1 <- object
	@ on entry:	sv2 <- ((port offset ...) . port-vector) = full output port
	@ write external representation of object in sv1 to port in sv2
	@ return via cnt
	bl	typsv1			@ rva <- type tag of obj1 (sv1)
	set	lnk, cnt
	eq	rva, #i0
	it	ne
	eqne	rva, #f0
	it	ne
	eqne	rva, #rational_tag
	it	ne
	eqne	rva, #complex_tag
	beq	wrtnum
	eq	rva, #char_tag
	beq	wrtcha
	eq	rva, #variable_tag
	beq	wrtvar
	eq	rva, #vector_tag
	beq	wrtvec
	eq	rva, #string_tag
	beq	wrtstr
	eq	rva, #bytevector_tag
	beq	wrtvu8
	eq	rva, #list_tag
	beq	wrtlst
	eq	rva, #symbol_tag
	itT	ne
	ldrne	sv1, =null__
	eqne	rva, #null
	itT	ne
	ldrne	sv1, =true__
	eqne	rva, #t
	itT	ne
	ldrne	sv1, =false_
	eqne	rva, #f
	itT	ne
	ldrne	sv1, =proc__
	eqne	rva, #procedure
	itT	ne
	ldrne	sv1, =bltn_
	eqne	rva, #bltn
	beq	prtwrc
	b	corerr


_func_	
wrtcha:	@ write-out a character
	eq	sv1, #npo		@ is char the non-printing object?
	it	eq
	seteq	pc,  cnt
	caar	sv4, sv2		@ rvc <- port address
	tst	sv4, #int_tag		@ is port-address an integer? (i.e. doing write, not display)
	beq	prtwrc			@	if so,  write the char out and return via lnk
	save	sv1			@ dts <- (char port ...)
	ldr	sv1, =pound_char	@	if so,  sv1 <-  pound, #, (scheme char)
	bl	prtwrc			@	if so,  write pound out
	ldr	sv1, =backslash_char	@	if so,  sv1 <-  backslash, \, (scheme char)
	bl	prtwrc			@	if so,  write backslash out
	restor	sv1			@ sv1 <- char,  dts <- (port ...)
	set	lnk, cnt
	b	prtwrc			@ write the space out and return via lnk/cnt

_func_	
wrtvar:	@ write-out a variable
	sav_rc	sv2
	adr	cnt, r2wstx
	b	psmstr

_func_	
wrtnum:	@ write-out a number
	sav_rc	sv2
	set	sv2, #null
	adr	cnt, r2wstx
	b	numstr

_func_	
wrtstr:	@ write-out a string
	save	sv1			@ dts <- (string port ...)
	caar	sv1, sv2		@ rvc <- port address
	tst	sv1, #int_tag		@ is port-address an integer? (i.e. doing write, not display)
	itT	ne
	ldrne	sv1, =dbl_quote_char	@ sv1 <- double quote (scheme char)
	blne	prtwrc			@	if so,  write double quote out
	restor	sv1			@ sv1 <- string,		dts <- (port ...)
	bl	prtwrc			@ write string out
	caar	sv1, sv2		@ rvc <- port address
	tst	sv1, #int_tag		@ is port-address an integer? (i.e. doing write, not display)
	itT	ne
	ldrne	sv1, =dbl_quote_char	@ sv1 <- double quote (scheme char)
	blne	prtwrc			@	if so,  write double quote out
	set	pc,  cnt

_func_	
wrtvec:	@ write-out a vector
	sav_rc	sv1			@ dts <- (vector cnt ...)
	ldr	sv1, =pound_char	@ sv1 <- pound (scheme char)
	bl	prtwrc			@ write pound out
	ldr	sv1, =open_par_char	@ sv1 <- open parenthesis (scheme char)
	bl	prtwrc			@ write open parenthesis out
	set	sv1, #i0		@ sv1 <- 0 = offset (scheme int)
wrtvlp:	save	sv1			@ dts <- (offset vector cnt ...)
	set	rvc, sv1		@ rvc <- item offset (scheme int)
	cadr	sv1, dts		@ sv1 <- vector
	veclen	rva, sv1		@ rva <- vector length (scheme int)	
	cmp	rvc, rva
	bpl	wrtvdn
	cmp	rvc, #i1
	it	pl
	blpl	wrtspc
	car	sv1, dts
	bic	rvc, sv1, #1
	cadr	sv1, dts
	ldr	sv1, [sv1, rvc]
	call	rwrite
	restor	sv1
	add	sv1, sv1, #4
	b	wrtvlp

_func_	
wrtvu8:	@ write-out a bytevector
	sav_rc	sv1			@ dts <- (bytevector cnt ...)
	ldr	sv1, =vu8str
	bl	prtwrc			@ write string out
	ldr	sv1, =open_par_char	@ sv1 <- open parenthesis (scheme char)
	bl	prtwrc			@ write open parenthesis out
	set	sv1, #i0		@ sv1 <- 0 = item offset (scheme int)
wrtv8l:	save	sv1			@ dts <- (offset bytevector cnt ...)
	set	rvc, sv1		@ rvc <- item offset (scheme int)
	cadr	sv1, dts		@ sv1 <- bytevector
	vu8len	rva, sv1
	cmp	rvc, rva
	bpl	wrtvdn
	cmp	rvc, #i1
	it	pl
	blpl	wrtspc
	car	sv1, dts
	int2raw	rvc, sv1
	cadr	sv1, dts
	ldrb	rvc, [sv1, rvc]
	raw2int	sv1, rvc
	call	rwrite
	restor	sv1
	add	sv1, sv1, #4
	b	wrtv8l
wrtvdn:	@ done
	restor3	rva, rvb, cnt
	b	wrtclp
		
_func_	
wrtlst:	@ write the contents of a list
	save	sv1			@ dts<- (list ...)
	ldr	sv1, =open_par_char	@ sv1 <- open parenthesis (scheme char)
	bl	prtwrc			@ write open parenthesis out
wrtcac:	@ write the car and then the cdr of the list
	@ dts <- (list ...)
	caar	sv1, dts		@ sv1 <- car-of-list
	sav__c				@ dts <- (cnt ...)
	call	rwrite
	restor	cnt
	@ write the cdr of a proper or improper list
	@ dts <- (list ...)
	cdar	sv1, dts
	nullp	sv1
	it	ne
	blne	wrtspc
	restor	sv1			@ sv1 <- list,		dts <- (port ...)
	cdr	sv1, sv1		@ sv1 <- cdr-of-list
	nullp	sv1			@ is cdr-of-list null?
	beq	wrtclp			@	if so,  jump to write closing parenthesis
	save	sv1			@ dts <- (cdr-of-list port ...)
	bl	typsv1			@ rva <- type tag of cdr-of-list(sv1)
	eq	rva, #list_tag		@ is cdr-of-list a list?
	beq	wrtcac			@	if so,  jump to write cdr as a proper list
	
wrtipl:	@ write the cdr of an improper list
	@ dts <- (cdr-of-list ...)
	ldr	sv1, =dot_char		@ sv1 <- dot (scheme char)
	bl	prtwrc			@ write dot out
	bl	wrtspc
	restor	sv1			@ sv1 <- cdr-of-list,		dts <- (...)
	sav__c				@ dts <- (cnt ...)
	call	rwrite
	restor	cnt
wrtclp:	@ write backspace, closing parenthesis, space, then exit
	@ dts <- (port ...)
	ldr	sv1, =close_par_char	@ sv1 <- close parenthesis (scheme char)
	set	lnk, cnt
	b	prtwrc			@ write the space out and return via lnk/cnt

_func_
r2wstx:	@ restore sv2 and cnt, then write string in sv1 and return via cnt
	restor2	sv2, cnt
	set	lnk, cnt
	b	prtwrc			@ write the space out and return via lnk/cnt

_func_
wrtspc:	@ write space and return
	ldr	sv1, =space_char	@ sv1 <- space (scheme char)
	b	prtwrc			@ write the space out and return via lnk
		

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

/*------------------------------------------------------------------------------
@  II.B.6.     Standard Procedures
@  II.B.6.6.   Input and Output
@  II.B.6.6.2. input:				read [parse]
@-----------------------------------------------------------------------------*/


pparse:	@ (parse expr)
	@ on entry:	sv1 <- expression as string
	@ on exit:	sv1 <- parsed scheme expression (ready for eval)
	set	sv4, #0			@ sv1 <- 0 (bottom of parse stack)
	save2	sv1, sv4		@ dts <- (expr-string 0 ...)
	set	sv5, #i0		@ sv5 <- offset to 1st char (scheme int)	
parse0:	@ parse expression on stack
	@ sv5 <- offset of previous char
	@ dts <- (expr <result> 0 ...)
	car	sv4, dts		@ sv4 <- expr
	strlen	sv3, sv4		@ sv3 <- number of chars in expr (scheme int)
	cmp	sv5, sv3		@ did we process all chars?
	bpl	parsxt			@	if so,  jump to exit
	@ skip over leading backspace, tab, lf, cr, space
	bytref	rva, sv4, sv5		@ rva <- char
	cmp	rva, #'!		@ is char a control character (eg. tab, lf, cr, space ...)
	it	mi
	addmi	sv5, sv5, #4		@ 	if so,  sv5 <- offset of next char to get from buffer
	bmi	parse0			@	if so,  jump to keep looping over chars
	@ check for beginning of comment
	eq	rva, #'; 		@ is char a semi-colon? (begining of comment)
	beq	prsskp
	@ check for a start of list, quoted or quasiquoted expression
	set	sv1, #0x60		@ sv1 <- indicator for open parenthesis
	eq	rva, #'(		@ is char an open parenthesis?
	itT	ne
	setne	sv1, #0x20		@	if not, sv1 <- "quote" indicator
	eqne	rva, #''		@	if not, is char a quote?
	itT	ne
	setne	sv1, #0x30		@	if not, sv1 <- "backquote"=backquote_char indicator
	eqne	rva, #'`		@	if not, is char a backquote?
	beq	prsrcr
	@ check for the cdr of an improper list
	add	sv1, sv5, #4		@ sv1 <- offset to next char
	bytref	rvb, sv4, sv1		@ rvb <- next char
	eq	rva, #'.		@ is char a dot?
	it	eq
	eqeq	rvb, #' 		@	if so,  is next char a space? (improper list)
	it	eq
	ldreq	sv1, =cons_env		@	if so,  sv1 <- "cons" (indicator for improper list)
	beq	prsrcr
	@ check for an unquoted or unquoted-spliced expression (uses rvb <- next char, extracted above)
	eq	rva, #',		@ is char a comma?
	beq	prsuqt
	@ check for an end of list
	eq	rva, #')		@ is char a close parenthesis?
	beq	prsclp			@ 	if so, jump to recover list from stack
	@ default: parse a token
	sav__c				@ dts <- (cnt expr <result> 0 ...)
	call	toksch			@ sv1 <- token converted to scheme, or list->vector indicator
	restor	cnt			@ cnt <- cnt,  dts <- (expr <result> 0 ...)
  .ifndef exclude_lib_mod
	ldr	rva, =library_var
	eq	sv1, rva
	itT	ne
	ldrne	rvb, =export_var
	eqne	sv1, rvb
	itT	ne
	ldrne	rvc, =import_var
	eqne	sv1, rvc
	beq	parslb
  .endif
	ldr	rva, =tokvec		@ rva <- [indicator that list needs conversion to vector]
	eq	sv1, rva		@ need to perform list->vector?
	itT	ne
	ldrne	rva, =tokvu8		@ rva <- [indicator that list needs conversion to vector]
	eqne	sv1, rva		@ need to perform list->vector?
	bne	parse5			@	if not, jump to keep parsing
	set	sv2, #null
	tuck	sv2, sv3
	ldr	rva, =tokvec		@ rva <- [indicator that list needs conversion to vector]
	eq	sv1, rva		@ need to perform list->vector?
	itE	eq
	seteq	sv1, #0x10		@ sv1 <- indicator for list->vector
	setne	sv1, #0x70		@ sv1 <- indicator for u8-list->bytevector
parse5:	tuckd	dts, sv1, dts		@ dts <- (expr token ... 0 ...)
parsqt:	@ check if there's an operation underneath result
	@ on entry:	dts <- (expr result operation-or-0 ...)
	cdr	sv2, dts		@ sv2 <- (result operation-or-0 ...)
	cdr	sv3, sv2		@ sv3 <- (operation-or-0 ...)
	car	sv1, sv3		@ sv1 <- operation or 0
	eq	sv1, #0			@ is there no operation to perform on result?
	it	eq
	addeq	sv5, sv5, #4		@ 	if so,  sv5 <- offset of next char to get from buffer
	beq	parse0			@	if so,  jump to parse expression following list
	@ check if operation is quote, quasiquote, unquote or unquote-splicing
	ldr	rva, =quote_var		@ sv4 <- "quote" scheme symbol-id
	eq	sv1, #0x20		@ is "quote" underneath?
	itT	ne
	ldrne	rva, =quasiquote_var	@	if not, sv4 <- "backquote" scheme symbol-id
	eqne	sv1, #0x30		@	if not, is "backquote" underneath?
	itT	ne
	ldrne	rva, =unquote_var	@	if not, sv4 <- "unquote" scheme symbol-id
	eqne	sv1, #0x40		@	if not, is "unquote" underneath?
	itT	ne
	ldrne	rva, =unqtsplc_var	@	if not, sv4 <- "unquote-splicing" scheme symbol-id
	eqne	sv1, #0x50		@	if not, is "unquote-splicing" underneath?
	beq	parsqu			@	if so,  jump to perform quotation/unquotation
	@ check if operation is to convert list to vector (pound underneath result)
	eq	sv1, #0x10		@ convert list to vector?
	it	ne
	eqne	sv1, #0x70		@	if not, convert list to bytevector?
	it	ne
	addne	sv5, sv5, #4		@ 	if so,  sv5 <- offset of next char to get from buffer
	bne	parse0			@	if not,  jump to parse expression following list
	set	sv4, sv1
	@ perform list->vector or list->bytevector
	@ and clear # and () from stack, then branch back to parse0
	car	sv1, sv2		@ sv1 <- result (vector as list)
	cdr	sv2, sv3		@ sv2 <- (() ...)
	car	sv3, dts		@ sv1 <- expr
	cdr	dts, sv2		@ dts <- (...)
	car	sv2, dts		@ sv2 <- quote or unquote or something else
	save2	sv5, sv3		@ dts <- (char-offset expr ...)
	sav_rc	sv4			@ dts <- (vec-type-indicator cnt char-offset expr ...)
	eq	sv2, #0x30		@ is "backquote" underneath?
	bne	parsqS			@	if not, jump to keep going
	call	pqsqot			@ sv1 <- quasiquote-expanded expression (vector as list)
parsqS:	@ get list length
	set	sv5, sv1		@ sv5 <- result (as list) saved
	set	sv2, #i0		@ sv2 <- 0, initial length of list
parsqT:	nullp	sv1			@ done with list?
	itT	ne
	cdrne	sv1, sv1		@	if not, sv1 <- rest of list
	addne	sv2, sv2, #4		@	if not, sv2 <- upated list size
	bne	parsqT			@	if not, jump to keep counting
	@ convert list to vector or bytevector
	set	sv1, sv2		@ sv1 <- list length (scheme int)
	set	sv2, #null		@ sv2 <- '() = fill for vector
	restor	sv4			@ sv4 <- vec-type-indicator, dts <- (cnt char-offset expr ...)
	eq	sv4, #0x70		@ rebuilding a bytevector?
	beq	prmkv8			@	if so,  jump to that case
	@ convert list to vector and return to parsing
	call	pmkvec			@ sv1 <- new, cleared vector of size sv1
	set	sv2, #i0		@ sv2 <- position of 1st vector item
lstve1:	nullp	sv5			@ done copying?
	beq	lstvxt			@	if so,  jump to exit
	snoc	sv4, sv5, sv5		@ sv4 <- next item,  sv5 <- remaining items
	vecset	sv1, sv2, sv4		@ store item in vector
	incr	sv2, sv2		@ sv2 <- position of next vector item
	b	lstve1			@ jump to continue copying from list to vector
prmkv8:	@ convert list to bytevector and return to parsing
	call	makvu8			@ sv1 <- new, cleared bytevector of size sv1
	set	rvc, #0
prmv80:	nullp	sv5
	beq	lstvxt
	snoc	sv4, sv5, sv5		@ sv4 <- next item,  sv5 <- remaining items
	int2raw	rvb, sv4
	strb	rvb, [sv1, rvc]
	add	rvc, rvc, #1
	b	prmv80
lstvxt:	@ return when done
	restor2	cnt, sv5		@ cnt <- cnt, sv5 <- char-offset, dts <- (expr ...)
	b	parse5			@ jump to continue parsing

.ifndef exclude_lib_mod

parslb:	@ special considerations for (library ...) or (export ...) or (import ...)
	cadr	sv3, dts		@ sv3 <- possible list indicator on stack
	eq	sv3, #0x60		@ is library, export, import at beginning of list?
	bne	parse5			@	if not, jump back for normal processing
	eq	sv1, rvb		@ is it (export ...)?
	itT	eq
	seteq	rva, #5			@	if so,  rva <- 5
	vcstieq	glv, 15, rva		@ 	if so,  set library-parse-export-mode-5 in glv
	beq	parse5			@	if so,  jump to continue parsing  
	eq	sv1, rvc		@ is it (import ...)?
	beq	parsir			@	if so,  jump to that case
	@ (library ...)
	@ build new built-in env vector for this library, and set it in glv for post-parsing ops
	set	rva, #13
	vcsti	glv, 15, rva		@ set library-parse-mode-13 in glv for zrslb & tokend
	bl	zrslb			@ sv3 <- built-in environment
	vcsti	glv, 14, sv3
	b	parse5

parsir:	@ (import ...)
	vcrfi	sv3, glv, 15		@ sv3 <- current parse mode
	nullp	sv3			@ nothing special mode (i.e. not inside (library ...))?
	itT	eq
	seteq	rva, #9			@	if so,  rva <- 2 (scheme int)
	vcstieq	glv, 15, rva		@	if so,  set parse-mode flag for tokend
	beq	parse5			@	if so,  jump to continue parsing
	car	sv4, dts		@ sv4 <- expr
	savrec	sv1			@ dts <- (import_var env cnt expr <result> 0 ...)
	save	sv5			@ dts <- (char-offset import_var env cnt expr <result> 0 ...)
	set	sv1, sv4		@ sv1 <- expr
	set	sv2, sv5		@ sv2 <- char-offset
prsir1:	@ find lib name in input string
	add	sv2, sv2, #4		@ sv2 <- char-offset, updated for next char
	bytref	rva, sv1, sv2		@ rva <- char
	eq	rva, #')		@ is char a close parenthesis (end of (import ...))?
	beq	prsir9			@	if so,  done importing, jump to finish up
	eq	rva, #'(		@ is char an open parenthesis (start of lib name)?
	bne	prsir1			@	if not, jump to keep looking for open par
	set	sv3, sv2		@ sv3 <- start offset
@***************** may need removal if name not copied correctly ****************
	add	sv2, sv2, #4		@ sv2 <- start offset for lib-name copy
	set	rvb, #1			@ rvb <- 1 = paren count
prsir2:	add	sv3, sv3, #4		@ sv3 <- updated char offset
	bytref	rva, sv1, sv3		@ rva <- char
	eq	rva, #'(		@ is char an open parenthesis?
	it	eq
	addeq	rvb, rvb, #1		@	if so,  rvb <- updated open-par count
	eq	rva, #')		@ is char a close parenthesis?
	it	eq
	subseq	rvb, rvb, #1		@	if so,  rvb <- updated par count, is it zero?
	bne	prsir2			@	if not, jump to keep looking for end of lib name
	@ find lib in lib-flash and store its exports in this-lib's-env
	save2	sv1, sv3		@ dts <- (exp lb-nam-end chr-off imprt_var env cnt exp <res> 0 .)
	bl	subcpy			@ sv1 <- lib to import (name string)
	bl	lbimp			@ rvb <- lib's export offset or 1, sv5 <- lib's export sub-env
	eq	rvb, #1			@ library found?
	itT	ne
	vcrfine	sv1, glv, 14		@	if so,  sv1 <- this-lib-env
	strne	sv5, [sv1, rvb]		@	if so,  store lib's export sub-env in this-lib-env
	@ continue to process next lib in input string
	restor2	sv1, sv2		@ sv1 <- exp, sv2 <- lb-nm-nd, dts <- (cof imv env cn exp <r> 0 .)
	b	prsir1			@ jump to process next lib

prsir9:	@ done importing, resume parsing
	restor2	sv5, sv1		@ sv5 <- char-off, sv1 <- imp_var, dts <- (env cnt expr <re> 0 .)
	restor2	env, cnt		@ env <- env, cnt <- cnt, dts <- (expr <result> 0 ...)
	@ note:	here, we skip re-parsing of import form and, essentially, set it to (import) for
	@	execution (i.e., no args). Alternative would be to set glv, 15 to #9.
	sub	sv5, sv2, #4		@ sv5 <- offset to before closing parenthesis in (import ...)
	b	parse5			@ jump to continue parsing

.endif	@ do not exclude_lib_mod


parsqu:	@ process quoted expression (cons quote in front of it)
	set	sv1, rva		@ sv1 <- scheme symbol-id for the type of quote
	snoc	sv2, sv3, sv2		@ sv2 <- result,		sv3 <- (operation ...)
	list	sv2, sv2		@ sv2 <- (result)
	cdr	sv3, sv3
	bcons	sv2, sv1, sv2, sv3	@ sv2 <- (updated-result ...)	
	car	sv1, dts		@ sv1 <- expr
	cons	dts, sv1, sv2		@ dts <- (expr updated-result ... 0 ...)
	b	parsqt			@ jump to process possible operation underneath new-result
	
prsskp:	@ skip over a comment
	add	sv5, sv5, #4		@ sv5 <- offset to next character
	cmp	sv5, sv3		@ did we process all chars?  (NEW -- to remove data abort issue)
	bpl	parsxt			@	if so,  jump to exit (NEW -- to remove data abort issue)
	bytref	rva, sv4, sv5		@ rva  <- char
	eq	rva, #'\r		@ is char a cr? (end of comment)
	it	ne
	eqne	rva, #'\n		@	if not, is char a line feed?
	bne	prsskp			@	if not, jump to keep scanning comment chars
	add	sv5, sv5, #4		@ sv5 <- offset of next char to get from buffer
	b	parse0			@ jump to parse expression following comment

prsuqt:	@ unquote or unquote-splicing
	eq	rvb, #'@		@ is next char a @?
	itTE	eq
	addeq	sv5, sv5, #4		@	if so,  sv5 <- offset to @
	seteq	sv1, #0x50		@	if so,  sv1 <- "unquote-splicing" indicator
	setne	sv1, #0x40		@	if not, sv1 <- "unquote" indicator
prsrcr:	@ tuck indicator into stack and recurse on the parsing
	tuckd	dts, sv1, dts		@ dts <- (expr "cons" ... 0 ...)
	add	sv5, sv5, #4		@ sv5 <- offset of next char to get from buffer
	b	parse0			@ jump to parse expression following dot of improper list
	
prsclp:	@ recover a parsed list from stack
	restor	sv4			@ sv4 <- expr,  dts <- ((itn itn-1 ... it2 it1) ... 0 ...)
	eq	sv4, #0			@ no expression on stack?
	it	eq
	seteq	sv1, #0
	beq	prserr			@	if so,  jump to parse error
	set	sv2, #null		@ sv2 <- ()
	set	sv3, #0x60		@ sv3 <- open parenthesis = end of list-on-stack indicator
dstls0:	restor	sv1			@ sv1 <- stack item, itn,  ds <- (itn-1 ... it2 it1 "(" .. 0 ..)
	eq	sv1, #0			@ parse stack exhausted with no opening parenthesis?
	beq	prserr			@	if so,  jump to parse error
	eq	sv1, sv3		@ is stack item a "(" ?
	beq	dstls1			@	if so, we're done with the stack
	ldr	rva, =cons_env		@ rva <- "cons" = improper list
	eq	sv1, rva		@ is stack item "cons"
	it	eq
	careq	sv2, sv2		@	if so,  sv2 <- 1st item of current cdr
	beq	dstls0			@	if so, jump to continue processing stack
	cons	sv2, sv1, sv2		@ sv2 <- (itn itn+1 ...)
	b	dstls0			@ jump to continue processing stack
dstls1:	@ finish up

  .ifndef exclude_lib_mod
	pntrp	sv2			@ non-null list result?
	bne	dstlxt			@	if not, jump to return
	car	rvc, sv2		@ rvc <- item at start of list
	set	rva, #null
	ldr	rvb, =library_var
	eq	rvc, rvb		@ did we recover a (library ...) list?
	itTT	ne
	setne	rva, #i0
	ldrne	rvb, =export_var
	eqne	rvc, rvb		@	if not, did we recover a (export ...) list?
	beq	dstls2			@	if so,  jump to update library-parse-export-mode in glv
	ldr	rvb, =import_var
	eq	rvc, rvb		@	if not, did we recover a (import ...) list?
	bne	dstlxt
	vcrfi	rvb, glv, 15
	eq	rvb, #9			@ are we in nothing-special-mode?
	it	eq
	seteq	rva, #null		@	if so,  rva <- () to clear parse mode
dstls2:	@ update parse mode
	vcsti	glv, 15, rva		@	if so,  clear library-parse-export-mode in glv
  .endif  @ do not exclude_lib_mod

dstlxt:	@ return
	save2	sv4, sv2		@ dts <- (expr (it1 ... itn) ... 0 ...)
	b	parsqt			@ jump to process possible operation underneath recovered list

parsxt:	@ recover result from stack (expr <result> 0 ...) and exit
	cdr	dts, dts		@ (<result> 0 ...)
	restor	sv1			@ sv1 <- result or 0,  dts <- (<0> ...)
	eq	sv1, #0			@ did parsing return nothing?
	itTE	eq
	seteq	sv1, #npo		@	if so,  sv1 <- non-printing character
	seteq	rva, #0
	restorne rva		@	if not, dts <- (...)
	eq	rva, #0
	bne	prserr
	set	pc,  cnt

prserr:	@ parse error, for example no opening parenthesis for a closing parenthesis
	@ Note: parser doesn't catch the opposite case (eg. "(hello") and leaves residue
	@ on stack -- need to clear stack using ctrl-c in this case.
	ldr	sv4, =sparse
	ldr	sv1, =badexp
	b	error4


toksch:	@ convert string token to scheme internal representation
	@ on entry:	sv4 <- buffer
	@ on entry:	sv5 <- offset to start of token
	@ on entry:	dts <- (cnt expr ... 0 ...)
	bytref	rva, sv4, sv5		@ rva <- char
	@ check if there's a single char to convert
	strlen	sv3, sv4		@ sv3 <- number of chars in expr (scheme int)
	sub	sv3, sv3, #4		@ sv3 <- offset to last char (scheme int)
	cmp	sv5, sv3		@ single char?
	bpl	tok1ch			@	if so,  jump to process single char cases
	@ conversion for case where 1st two chars of token may determine type
	add	sv1, sv5, #4		@ sv1 <- offset to next char
	bytref	rvb, sv4, sv1		@ rvb <- next char
	@ test for double-quote-something => string
	eq	rva, #'"		@ is char a double quote "? (start of string)
	beq	tokstr			@	if so, jump to convert token to string
	@ test for pound-something => number, vector, char, #t/#f or symbol
	eq	rva, #'#		@ is char a #  --  pound?
	beq	tokpnd			@	if so,  jump to convert accordingly
	@ test for minus-dot => number
	eq	rva, #'-		@ is char a minus sign "-"?
	itT	eq
	seteq	rva, rvb
	eqeq	rvb, #'.		@	if so,  is following char a dot?
	beq	toknum
	@ test for dot-space => cdr of improper list
	eq	rva, #'.		@ is char a dot?
	itT	eq
	seteq	rva, rvb
	eqeq	rvb, #0x20		@	if so,  is following char a space?
	beq	tokils			@	if so,  jump to convert token to cdr of improper list
tok1ch:	@ conversion for case where a single char (1st char of token) determines type
	cmp	rva, #'0		@ is char less than 0  --  digit 0?
	bmi	toksym			@	if so,  jump to see if it is #something
	cmp	rva, #':		@ is char smaller than 9+1  --  digit 9, + 1?
	bmi	toknum			@	if so,  jump to convert token to number
toksym:	@ convert token to a symbol
	ldr	sv1, =pstsym		@ sv1 <- [string->symbol alternate entry]
	b	tokprc			@ jump to convert token to symbol (via string)

tokpnd:	@ analyze token that starts with # (pound)
	eq	rvb, #'\\		@ is next char a \?
	beq	tokchr			@	if so,  jump to convert token to char
	eq	rvb, #'(		@ is next char an open parenthesis?
	beq	tokvec			@	if so,  jump to convert token to vector
	eq	rvb, #'v		@ is next char a v (eg. #vu8())?
	it	eq
	bleq	tokvu8			@	if so,  jump to possibly convert token to bytevector
	set	sv2, #f			@ sv2 <- #f (default for tokcbe)
	eq	rvb, #'t		@ is next char a t?
	itE	eq
	seteq	sv2, #t			@	if so,  sv2 <- #t (for tokcbe)
	eqne	rvb, #'f		@	if not, is next char a f?
	beq	tokcbe			@	if so,  jump to convert to #t/#f
	bic	rvb, rvb, #0x20		@ rvb <- char following pound, without case (lower->upper)
	eq	rvb, #'I		@ is it an I or i? => inexact number
	it	ne
	eqne	rvb, #'B		@	if not, is it a  B or b? => binary number
	it	ne
	eqne	rvb, #'O		@	if not, is it an O or o? => octal number
	it	ne
	eqne	rvb, #'X		@	if not, is it an X or x? => hexadecimal number
	it	ne
	eqne	rvb, #'E		@	if not, is it an E or e? => exact number
	it	ne
	eqne	rvb, #'D		@	if not, is it a  D or d? => decimal number
	bne	toksym			@	if not, jump to convert to symbol
toknum:	@ convert a token to a number
	ldr	sv1, =strnum		@ sv1 <- [string->number alternate entry]
	b	tokprc			@ jump to convert token to number (via string)
	
tokvec:	@ schemize a vector (via list, parse-quote and list->vector)
	ldr	sv1, =tokvec		@ sv1 <- [list->vector indicator]
	set	pc,  cnt		@ return (caller will check sv1 and proceed accordingly)

tokvu8:	@ schemize a bytevector, possibly, (via list and u8-list->bytevector)
	@ called by bl to be able to return to parsing if token is a symbol (eg. #vwxyz)
	add	sv2, sv5, #16		@ sv2 <- offset to open parenthesis if #vu8()
	cmp	sv2, sv3		@ enough chars for #vu8()?
	it	pl
	setpl	pc,  lnk		@	if not, return to parsing
	bytref	rvc, sv4, sv2		@ rvc <- last char to check
	eq	rvc, #'(		@ is it an open parenthesis?
	itT	eq
	subeq	sv2, sv2, #4		@	if so,  sv2 <- offset of previous char
	bytrefeq rvc, sv4, sv2		@	if so,  rvc <- previous char
	it	eq
	eqeq	rvc, #'8		@	if so,  is it 8?
	itT	eq
	subeq	sv2, sv2, #4		@	if so,  sv2 <- offset of previous char
	bytrefeq rvc, sv4, sv2		@	if so,  rvc <- previous char
	it	eq
	eqeq	rvc, #'u		@	if so,  is it u?
	it	ne
	setne	pc,  lnk		@	if not, return to parsing
	add	sv5, sv5, #12		@ sv5 <- updated char start (offset of 8, before open par.)
	ldr	sv1, =tokvu8		@ sv1 <- [u8-list->bytevector indicator]
	set	pc,  cnt		@ return (caller will check sv1 and proceed accordingly)

tokchr:	@ convert a token to a char
	add	sv5, sv1, #4		@ sv5 <- offset to character
	bytref	rva, sv4, sv5		@ rva <- char
	strlen	rvb, sv4
	sub	rvb, rvb, #4
	cmp	sv5, rvb
	bpl	tokchs
	add	rvb, sv1, #8		@ rvb <- offset to next character
	bytref	rvb, sv4, rvb		@ rvb <- next char
	bic	rvb, rvb, #0x20		@ rvb <- next char, without case
	eq	rvb, #'P		@ is next char a P? (for \sPace, \space, doesn't check all chars)
	it	eq
	seteq	rva, #'\ 		@	if so,  rva <- ascii space
	eq	rvb, #'E		@ is next char an E? (for \nEwline, \newline)
	it	eq
	seteq	rva, #'\r		@	if so,  rva <- ascii carriage return
tokchs:	raw2chr	sv2, rva		@ sv2 <- char as scheme char (saved against tokend)
	add	sv5, sv5, #4		@ sv5 <- offset to next character
tokcbe:	@ finish up for char or #t/#f
	bl	tokend			@ sv1 <- offset of char after end of char token
	sub	sv5, sv1, #4		@ sv5 <- offset of last char in char token
	set	sv1, sv2		@ sv1 <- char as scheme char
	set	pc,  cnt
	
tokstr:	@ convert token to a string
	save	sv4			@ dts <- (buffer ...)
tokst0:	@ look for closing double-quote
	bytref	rva, sv4, sv1		@ rva <- char
	eq	rva, #'\\		@ is char a \?
	it	eq
	addeq	sv1, sv1, #8		@	if so,  sv1 <- offest of char after next (i.e. skip next)
	beq	tokst0			@	if so,  jump to keep looking for closing double-quote
	eq	rva, #'"		@ is char a double quote "? (end of string)
	it	ne
	addne	sv1, sv1, #4		@	if not, sv1 <- offest of next char
	bne	tokst0			@	if not, continue scanning for closing double-quote
	@ extract string
	save	sv1			@ dts <- (closing-quote-offset buffer cnt expr ...)
	set	sv1, sv4		@ sv1 <- buffer containing string
	add	sv2, sv5, #4		@ sv2 <- offset to 1st char of string (after opening dbleqot)
	car	sv3, dts		@ sv3 <- closing-quote-offset
	bl	subcpy			@ sv1 <- string characters (substring)
	@ strip 1st \ in \\ and \doublequote
	set	sv4, sv1		@ sv4 <- destination for memcpy
	strlen	sv3, sv1		@ sv3 <- number of chars in string
	set	sv5, #i0		@ sv5 <- start offset = 4 (scheme int)
	ldr	rvc, [sv1, #-4]		@ rvc <- string tag, to count removed \
tokst1:	cmp	sv5, sv3		@ at end of string?
	bpl	tokst2			@	if so,  jump to finish up
	bytref	rvb, sv1, sv5		@ rvb <- previous char
	add	sv5, sv5, #4		@ sv5 <- offset of current char
	eq	rvb, #'\\		@ was previous char a \?
	bne	tokst1			@	if not, jump to keep scanning string
	set	sv2, sv5		@ sv2 <- source start offset
	sub	rvb, sv2, #4		@ rvb <- target start offset (scheme int)
	int2raw	rvb, rvb		@ rvb <- target start offset (raw int)
memcpy:	@ Copy a block of memory, one byte at a time
	@ copy from start to end
	cmp	sv2, sv3		@ are we done copying?
	it	mi
	bytrefmi rva, sv1, sv2		@ rva <- raw byte from source
	itTT	mi
	strbmi	rva, [sv4, rvb]		@ store it in target
	addmi	sv2, sv2, #4		@ sv2 <- updated source end offset
	addmi	rvb, rvb, #1		@ rvb <- updated target end address
	bmi	memcpy			@ jump to continue copying bytes
	sub	rvc, rvc, #0x0100	@ rvc <- updated string size tag
	sub	sv3, sv3, #4		@ sv3 <- updated string length (scheme int)
	b	tokst1			@ jump to keep stripping \
tokst2:	@ finish up token->string conversion
	str	rvc, [sv1, #-4]		@ update the result string tag
	restor2	sv5, sv4		@ sv5 <- quote-offset, sv4 <- buffer,	 dts <- (cnt expr ...)
	set	pc,  cnt

tokils:	@ schemize the cdr of an improper list
	add	sv5, sv5, #8		@ sv5 <- offset of character after next
	sav__c				@ dts <- (cnt ...)
	call	toksch			@ sv1 <- token
	restor3	cnt, sv3, sv4		@ cnt <- cnt, sv3 <- upper-cnt,
					@ sv4 <- expr, dts <- (itn itn-1 .. it1 "(" ..)
tokscc:	bytref	rva, sv4, sv5		@ rva <- char -- scan for closing parenthesis
	eq	rva, #')		@ is char a closing par?
	it	ne
	addne	sv5, sv5, #4		@	if not, sv5 <- offset to next character
	bne	tokscc			@	if not, may want to check for null to avoid infinite loop
	restor	sv2			@ sv2 <- itn,			dts <- (itn-1 .. it2 it1 "(" ..)
dstil0:	restor	sv1			@ sv1 <- stack item, itn-1,	dts <- (itn-2 .. it2 it1 "(" ..)
	ldr	rva, =open_par_char
	eq	sv1, rva		@ is sv1 = "(" ?
	beq	dstil1			@	if so, we're done with the stack
	cons	sv2, sv1, sv2		@ sv2 <- (itn itn+1 ...)
	b	dstil0			@ jump to process remainder of stack
dstil1:	set	sv1, sv2		@ sv1 <- result
	save2	sv3, sv4		@ dts <- (upper-cnt expr ... 0 ...)
	set	pc,  cnt

_func_	
tokend:	@ return in sv1 the position of the character after the end
	@ of the read buffer token that starts at sv5
	@ on entry:	sv4 <- address of read buffer
	@ on entry:	sv5 <- start offset of token
	@ on exit:	sv1 <- end offset of token
	@ modifies:	sv1, sv3, rva
	set	sv1, sv5		@ sv1 <- offset to 1st char
	strlen	sv3, sv4		@ sv3 <- number of chars in expr (scheme int)
  .ifndef exclude_lib_mod
	vcrfi	rva, glv, 15
	eq	rva, #9
	it	ne
	eqne	rva, #13
	beq	token1
  .endif
token0:	cmp	sv1, sv3		@ at end of expression?
	it	pl
	setpl	pc,  lnk		@	if so,  return
	bytref	rva, sv4, sv1		@ rva <- char
	eq	rva, #'\t		@ is char a tab?
	it	ne
	eqne	rva, #'\r		@	if not, is char a cr?
	it	ne
	eqne	rva, #'\n		@	if not, is char a line feed?
	it	ne
	eqne	rva, #'\ 		@	if not, is char a space?
	it	ne
	eqne	rva, #')		@	if not, is char a closing parenthesis?
	it	ne
	eqne	rva, #'(		@	if not, is char an opening parenthesis?
	it	ne
	@ The two lines below are contributed by Christophe Scholl of the Brussels Free University
	eqne	rva, #';		@	if not, is char a semi-colon (start of comment)?
	it	ne
	addne	sv1, sv1, #4		@	if not, sv1 <- offset to next char as scheme int
	bne	token0			@	if not done, jump to continue counting characters
	set	pc,  lnk		@ return

.ifndef exclude_lib_mod

token1:	@ end of token for (possibly compound) library name
	@ used for:	(library (lib name) ...) and (import (lib name1) (lib name2) ...)
	@ Note:		for (import ...) this code is used only outside of a (library ...) clause
	@		(see prsir1: for code used within a library clause).
	set	sv3, #5			@ sv3 <- initial parenthesis count (scheme int)
token2:	bytref	rva, sv4, sv1		@ rva <- char
	eq	rva, #'(		@ is char an open parenthesis?
	it	eq
	addeq	sv3, sv3, #4		@	if so,  sv3 <- updated parenthesis count
	eq	rva, #')		@ is char a close parenthesis?
	itT	eq
	subeq	sv3, sv3, #4		@	if so,  sv3 <- updated parenthesis count
	eqeq	sv3, #i0		@	if so,  is parenthesis count zero?
	it	ne
	addne	sv1, sv1, #4		@	if not, sv1 <- offset to next char
	bne	token2			@	if not, jump to keep looking for end of compound token
	vcrfi	rva, glv, 15		@ rva <- current parse mode
	eq	rva, #13		@ are we parsing (library (lib name) ...)
	itT	eq
	seteq	rva, #i0		@	if so,  rva <- 0 (scheme int)
	vcstieq	glv, 15, rva		@	if so,  set library-parse-mode in glv (normal parse)
	set	pc,  lnk		@ return

.endif
	
tokprc:	@ convert token to string and then convert it according to func in sv1.
	@ on entry:	sv1 <- func
	@ on entry:	sv4 <- read buffer
	@ on entry:	sv5 <- start offset
	@ on exit:	sv1 <- result
	@ on exit:	sv5 <- updated offset
	set	sv2, sv1		@ sv2 <- func, saved against tokend
	bl	tokend			@ sv1 <- offset to char after end of token
	sav_rc	sv1			@ dts <- (end-offset cnt expr ...)
	swap	sv2, sv5, sv3		@ sv2 <- start offset,  sv5 <- func
	set	sv3, sv1		@ sv3 <- offset to char after end of token
	set	sv1, sv4		@ sv1 <- expr
	bl	subcpy			@ sv1 <- token-string
	set	sv2, #null		@ sv2 <- '(), for string->number, fmt = '()
	calla	sv5			@ sv1 <- result of applying func in sv3 to token-string in sv1
	restor2	sv5, cnt		@ sv5 <- end-offset, cnt <- cnt, dts <- (expr ...)
	sub	sv5, sv5, #4		@ sv5 <- offset to last char of substringed symbol item
	set	pc,  cnt

	
/*------------------------------------------------------------------------------
@  II.B.6.     Standard Procedures
@  II.B.6.6.   Input and Output
@  II.B.6.6.3. output:				prompt
@-----------------------------------------------------------------------------*/


prompt:	@ (prompt)
	ldr	sv1, =prmpt_
	set	sv2, #null
	set	sv4, #((0x03<<2)|i0)
	b	ioprfn			@ write-out the prompt
	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg







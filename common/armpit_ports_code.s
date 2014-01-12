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

@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.1. ports SUPPORT 1:				setipr, setopr,
@-------------------------------------------------------------------------------

_func_
ioprfe:	@ [internal entry]
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved (even if Thumb2)
_func_	
ioprfn:	@ [internal only]
	@ set default input port (do not modify sv2, sv3, lnk, cnt)
	@ on entry:	sv1 <- () or (<port> <reg> <n> ...) or (((port <reg> <n> ...) . port-vector))
	@ on entry:	sv3 <- () or 0, () means error out on problem, 0 means return 0 on problem
	@ on exit:	sv1 <- ((port <reg> <n> ...) . port-vector) = full input-port
	and	rva, sv4, #0x7f
	eq	rva, #f
	itE	eq
	seteq	sv3, #i0
	setne	sv3, #null
	orr	sv3, sv3, sv4, lsl #8
	tst	sv4, #0x80		@ dealing with output port?
	itEE	eq
	ldreq	sv4, =curoutport_var	@	if so, sv1 <- symbol-id of current-output-port
	setne	sv2, sv1		@	if not,
	ldrne	sv4, =curinport_var	@	if not, sv1 <- symbol-id of current-input-port
	@ on entry:	sv2 <- port or null
	@ on entry:	sv3 <- () or 0, () means error out on problem, 0 means return 0 on problem
	@ on entry:	sv4 <- curinport_var or curoutport_var
	@ on entry:	sv5 <- lnk of caller
	@ on exit:	sv2 <- (port <reg> <n> ...) or ((port <reg> <n> ...) . port-vector)
	@ on exit:	sv4 <- port model if port is not a file handle
	@ on exit:	rvb <- port type indicator
	@ preserves:	sv1, sv5 and sv3 (sv3 must be immediate, not pointer)
	nullp	sv2			@ is a port specified?
	bne	getpr1			@	if so,  skip call to (current-output-port)
	save3	sv1, sv3, sv5		@ dts <- (obj lnk ...)
	sav_ec	
	list	sv1, sv4		@ sv1 <- (current-output-port)	
	call	eval			@ sv1 <- prt or (prt <reg> <n> .) or ((prt <reg> <n> ..) . prt-vec)
	set	sv2, sv1		@ sv2 <- prt or (prt <reg> <n> .) or ((prt <reg> <n> ..) . prt-vec)
	restor2	env, cnt
	restor3	sv1, sv3, sv5		@ sv1 <- obj, sv5 <- lnk, dts <- (...)
	pntrp	sv2			@ is sv2 a pointer?
	beq	getpr2			@	if so,  jump to continue
	list	sv2, sv2		@ sv2 <- (port)
	b	getpr2			@ jump to continue
getpr1:	@ build port-vector if needed
	car	sv4, sv2		@ sv4 <- port or ((port <reg> <n> ...) . port-vector)
	pntrp	sv4			@ is this a pointer?
	it	eq
	seteq	sv2, sv4		@	if so,  sv2 <- ((port <reg> <n> ...) . port-vector)
getpr2:	@ continue building port-vector if needed
	snoc	rvb, sv4, sv2		@ rvb <-p|(p<r><n>.),sv4 <-(<r><n>.)|pvc
	pntrp	rvb			@ is this a pointer?
	beq	ioprfd			@	if so, return w/full-port in sv2
	intgrp	rvb
	bne	getprr
	@ check if reg was specified
	pntrp	sv4
	itE	eq
	careq	rva, sv4		@ rva <- reg
	setne	rva, #null
	intgrp	rva			@ is reg an int?
	beq	getpr5
	@ possible file port (character port, no reg)
	cmp	rvb, #0x4000		@ is port below highst fil prt bas adrs?
	bmi	getpr4
getpr5:	@ memory port or ISR (on glv)
	vcrfi	sv4, glv, 13		@ sv4 <- built-in env vec
	vcrfi	sv4, sv4, 3		@ sv4 <- built-in port env
	intgrp	rva			@ is reg an int?
	it	eq
	vcrfieq	sv4, sv4, 3
	beq	ioprfd			@	if so, return w/full-port in sv2
	ldr	rva, [sv4, #-4]		@ rva <- built-in port env vector tag
	lsr	rva, rva, #8		@ rva <- size of port env vec (raw int)
getpr3:	@ fixed-address ports - scan port model bindings
	sub	rva, rva, #1
	ldr	sv4, [sv4, rva, lsl #2]	@ sv4 <- port model
	vcrfi	rvc, sv4, 0		@ rvc <- port address
	eq	rvb, rvc
	beq	ioprfd			@	if so, return w/full-port in sv2
	subs	rva, rva, #1
	beq	getprr
	vcrfi	sv4, glv, 13		@ sv4 <- built-in env vec
	vcrfi	sv4, sv4, 3		@ sv4 <- built-in port env
	b	getpr3
getpr4:	@ file port
	set	sv2, rvb
	set	rvc, sv3
	bl	ffhofl
	set	sv3, rvc
	nullp	sv4
	it	eq
	seteq	sv2, rvb
	beq	getprr
	set	sv2, sv4
	set	rvb, sv2
ioprfd:	@ continue
	@ sv2 <- port model or full port
	@ rvb <- port address or non-gced pointer (used as indicator)
	lsr	sv3, sv3, #8
	pntrp	rvb			@ was a full port specified on input?
	beq	iprfxt			@	if so,  jmp to ret w/ful-prt sv1
	tst	sv3, #0x80
	itE	eq
	vcrfieq	sv4, sv4, 2		@ sv4 <- output port-vec frm port model
	vcrfine	sv4, sv4, 1		@ sv4 <- input  port-vec frm port model
	cons	sv2, sv2, sv4		@ sv2 <- (port adrs . port-vec) =ful prt
iprfxt:	@ common exit
	tst	sv3, #0x80
	it	ne
	setne	sv1, sv2		@ sv1 <- port model or full port
	and	rvc, sv3, #0x03
	eq	rvc, #3
	itT	eq
	orreq	lnk, sv5, #lnkbit0	@ lnk <- made odd if Thumb2
	seteq	pc,  lnk
	tst	sv3, #0x02
	beq	iprfx1
	snoc	sv2, sv5, sv2		@ sv1 <- (port ...),	sv5 <- port-vec
	snoc	sv2, sv4, sv2		@ sv1 <- port,		sv4 <- (...)
	eor	sv2, sv2, #0x03		@ sv1 <- port as pseudo float (for peek)
	bcons	sv2, sv2, sv4, sv5	@ sv1 <- ((port ...) . port-vector)	
	tst	sv3, #0x80
	it	ne
	setne	sv1, sv2		@ sv1 <- port model or full port
iprfx1:	@ finish up
	int2raw	rvc, sv3
	ldr	lnk, =npofxt		@ lnk <- exit via npofxt (wrt-chr/nwln)
	@ continue to prtfun
_func_	
prtfun:	@ call a port-vector function
	@ on entry:	sv1 or sv2 <- ((port <reg> <n> ...) . port-vec) =ful prt
	@ on entry:	rvc <- index of function to call in output port-vector
	@ modifies:	rva, possibly rvc (if input-port funtion)
	@ [internal entry]
	@ Note:	port-vector's address must be in non-heap (i.e. fixed) memory
	@	otherwise if gc occurs (through multitasking or interrupt that
	@	does zmaloc) then rva could become invalid in-between the
	@	cdr(ne/eq) and ldr lines below.
	tst	rvc, #0x20		@ is this an input-port function?
	itTE	ne
	bicne	rvc, rvc, #0x20		@	if so,  rvc <- offset to func
	cdrne	rva, sv1		@	if so,  rva <- input  port-vec
	cdreq	rva, sv2		@	if not, rva <- output port-vec
	ldr	rva, [rva, rvc, lsl #2]
	pntrp	rva
	it	ne
	lsrne	rva, rva, #16
  .ifdef CORE_BASE
  	it	ne
	orrne	rva, rva, #CORE_BASE
  .endif
	orr	rva, rva, #lnkbit0	@ rva <- adrs chosn func cod odd if T2
	set	pc,  rva		@ jump to chosen func code (ret via lnk)

_func_
getprr:	@ report error if needed
	and	rva, sv3, #0xff
	eq	rva, #i0
	itT	ne
	setne	sv1, sv2
	ldrne	sv4, =port
	bne	error4
	set	sv1, #i0
	set	sv2, sv1
	set	rvb, #0
	orr	lnk, sv5, #lnkbit0	@ lnk <- made odd if Thumb2
	set	pc,  lnk


@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input  SUPPORT 1:		iprtfn
@  II.A.6.6.3. output SUPPORT 1:		oprtfn, prtwrc
@-------------------------------------------------------------------------------

	
_func_
getc0:	@ prepare to get one or more chars from input-port in sv1
	@ preserve all but rva, rvb
	set	rvc, #0x26		@ rvc <- 6 = offset to func in port-vec
	b	prtfun			@ jump to helper function
	
_func_
getc1:	@ get one char from input-port in sv1
	@ preserve all but rva, rvb
	set	rvc, #0x27		@ rvc <- 7 = offset to func in port-vec
	b	prtfun			@ jump to helper function
	
_func_
getc2:	@ what to do after getting one or more chars from input-port in sv1
	@ preserve all but rva, rvb
	set	rvc, #0x28		@ rvc <- 8 = offset to func in port-vec
	b	prtfun			@ jump to helper function
	
_func_
prtwrc:	@ port write-char / write-string function
	@ write scheme char or string sv1 to port sv2 using port's write-char
	@ on entry:	sv1 <- character
	@ on entry:	sv2 <- full output port
	set	rvc, #0x02		@ rvc <- 2, write-char/write-string ofst
	b	prtfun			@ jump to call function

_func_
prthwp:	@ port hw-putc function
	@ on entry:	sv1 <- character
	set	rvc, #0x04		@ rvc <- 4, ofst of hw-putc in port-vec
	b	prtfun			@ jump to call function

	
@-------------------------------------------------------------------------------
@
@	MEMORY INPUT/OUTPUT PORT
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input  SUPPORT 3 - memory input port:	memipr, pmmrdc, pmmred
@  II.A.6.6.3. output SUPPORT 3 - memory output port:	memopr, pmmwrc, pmmwrt
@-------------------------------------------------------------------------------

npofun:	@ exit with non-printing-object
	set	sv1, #npo
	set	pc,  cnt

trufun:	@ exit with #t
	set	sv1, #t
	set	pc,  cnt

pmmrdc:	@ read-char / peek-char function for memory input port
	@ on entry:	sv1 <- ((port reg <n>) . port-vector) = full input port
	@ on exit:	sv1 <- char read
	@ modifies:	sv1, sv2, rvb
	@ returns via cnt
	car	sv1, sv1		@ sv1 <- (port reg <n>)
	snoc	sv1, sv2, sv1		@ sv1 <- port,		sv2 <- (reg <n>)
	car	sv2, sv2		@ sv2 <- reg
	lsr	rvb, sv1, #2		@ rvb <- port base adrs without upr 2bit
	lsl	rvb, rvb, #4		@ rvb <- full port base address
  .ifndef cortex
	bytref	rvb, rvb, sv2		@ rvb <- byte from register
  .else
	add	rvb, rvb, sv2, asr #2
	ldrb	rvb, [rvb]
  .endif
	raw2chr	sv1, rvb		@ sv1 <- byte, as scheme char
	set	pc,  cnt		@ return

.ifndef	exclude_read_write


pmmred:	@ read function for memory input port
	@ on entry:	sv1 <- ((port reg <n>) . port-vector) = full input port
	@ on exit:	sv1 <- object read
	@ modifies:	sv1, sv2, sv3, rva, rvb
	@ returns via cnt
	car	sv1, sv1		@ sv1 <- (port reg <n>)
	snoc	sv1, sv2, sv1		@ sv1 <- port,		sv2 <- (reg <n>)
	car	sv2, sv2		@ sv2 <- reg
	set	sv3, sv2
	tst	sv2, #0x80000000	@ is offset negative?
	it	ne
	ngintne	sv2, sv2		@	if so,  sv2 <- positive offset
	bic	sv2, sv2, #0x0c		@ sv2 <- offset aligned to 32-bit
	lsr	rvb, sv1, #2		@ rvb <- port base adrs without upr 2bit
	lsl	rvb, rvb, #4		@ rvb <- full port base address
	wrdref	rva, rvb, sv2		@ rva <- value from register (raw  int)
	raw2int	sv1, rva		@ sv1 <- value (scheme int)
	tst	sv3, #0x80000000	@ was offset 0+?
	it	eq
	seteq	pc, cnt			@	if so,  return with obj in sv1
	bic	rva, rva, #0x03
	orr	sv2, rva, #i0
	set	sv3, sv1
	mkvu84	sv1			@ sv1 <- #vu8(space-for-4-items)
	lsr	rvc, sv3, #2
	bic	rva, sv2, #0x03
	orr	rva, rva, rvc
	str	rva, [sv1]
	set	pc,  cnt
	
.endif


pmmwrc:	@ write-char function for memory output port
	@ on entry:	sv1 <- char
	@ on entry:	sv2 <- ((port offset ...) . port-vector) = full out port
	@ returns via lnk
	car	sv2, sv2		@ sv2 <- (port offset ...)
	snoc	sv2, sv3, sv2		@ sv2 <- port,	sv3 <- (offset ...)
	car	sv3, sv3		@ sv3 <- offset
	lsr	rvb, sv2, #2		@ rvb <- port base adrs without upr 2bit
	lsl	rvb, rvb, #4		@ rvb <- full port base address
	chr2raw	rva, sv1		@ rva <- byte from schm char (ascii val)
	bytset	rvb, sv3, rva		@ write byte to register
	set	pc,  lnk		@ return

.ifndef	exclude_read_write

pmmwrt:	@ write object in sv1 to port in sv2 --  function for memory output port
	@ on entry:	sv1 <- object
	@ on entry:	sv2 <- ((port offset ...) . port-vector) = full out port
	car	sv2, sv2		@ sv2 <- (port offset ...)
	snoc	sv2, sv3, sv2		@ sv2 <- port,	sv3 <- (offset ...)
	car	sv3, sv3		@ sv3 <- offset
	lsr	rvb, sv2, #2		@ rvb <- port base adrs without upr 2bit
	lsl	rvb, rvb, #4		@ rvb <- full port base address
	tst	sv3, #0x80000000	@ is offset 0+?
	itEE	eq
	int2raweq rva, sv1		@	if so,  rva <- object (raw int)
	cdrne	rva, sv1		@	if not, rva <- adrs from bytevec
	ngintne	sv3, sv3		@	if not, sv3 <- positive offset
	bic	sv3, sv3, #0x0c		@ sv3 <- offset aligned to 32-bit
	wrdst	rvb, sv3, rva		@ store obj in register (base adrs+ofst)
	b	npofxt			@ return with npo
	
.endif

@-------------------------------------------------------------------------------
@
@	CHARACTER INPUT/OUTPUT PORT -- COMMON FUNCTIONS
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input  SUPPORT 3 - character input  port:	pchrdc,	pchrdy
@-------------------------------------------------------------------------------


pchrdc:	@ read-char / peek-char for character input port (uart, file, usb)
	@ on entry:	sv1 <- ((port reg <n>) . port-vector) = full input port
	@ on exit:	sv1 <- char read
	@ modifies:	sv1, sv2, sv3, sv4, sv5, rva, rvb, rvc
	@ returns via cnt
redch0:	bl	getc0			@ sv4 <- prior char pos/fil desc (getc1)
					@ sv2 <- 0 or pos/descr copy
	eq	sv2, #i0		@ port can't be read?
	it	eq
	ldreq	sv3, =eof_char		@	if so,  sv3 <- eof
	beq	redchx			@	if so,  jump to exit with eof
	caar	sv3, sv1		@ sv3 <- port
	tst	sv3, #0x01		@ is port a float (peek- vs read-)?
	it	eq
	seteq	sv4, sv2		@	if so,  sv4 <- fil-desc copy
	bl	getc1			@ rvb <- chr read,rvc=rvb,sv4<-updtd pos
	eq	rvb, #eof		@ is char an eof?
	bne	redch1			@	if not,  jump to updt pos, exit
	cdr	rvc, sv1		@ rvc <- port-vector
	vcrfi	rvc, rvc, 5		@ rvc <- value of port go-through-on-eof
	eq	rvc, #f			@ is eof acceptable?
	it	eq
	ldreq	sv3, =eof_char		@	if so,  sv3 <- eof
	beq	redchx			@	if so,  jump to exit
	b	redch0			@ jump back to re-read buffer/file
redch1:	@ update input-port's buffer if needed
	caar	sv3, sv1		@ sv3 <- port
	tst	sv3, #0x01		@ is port a float (peek- vs read-char)?
	raw2chr	sv3, rvb		@ sv3 <- char (scheme char)
	beq	redchx			@	if so,  jump to skip bfr update
	save	sv3			@ dts <- (char ...)
	bl	getc2			@ sv1 <- string read, bfr/desc updated
	restor	sv3			@ sv3 <- char,		dts <- (...)
redchx:	@ finish up
	set	sv1, sv3		@ sv1 <- char (scheme char)
	set	pc,  cnt		@ return


pchrdy:	@ char-ready? for character input port (common to uart, file, usb)
	@ on entry:	sv1 <- ((<port> <reg> <n>) . port-vector) = full in port
	@ on exit:	sv1 <- #t/#f indicating port char-ready status
	@ modifies:	sv1, sv2, sv3, sv4, sv5, rva, rvb, rvc
	@ returns via cnt
	bl	getc0			@ sv4 <- prior chr pos/fil desc (getc1)
					@ sv2 <- 0 or pos/descr copy
	eq	sv2, #i0		@ port can't be read?
	beq	notfxt			@	if so,  exit with #f
	set	sv4, sv2		@ sv4 <- position/descriptor-copy
	bl	getc1			@ rvb <- chr read,rvc=rvb,sv4<-updtd pos
	eq	rvb, #eof		@ is char an eof?
	bne	notfxt			@	if not, jump to exit with #t
	cdr	rvc, sv1		@ rvc <- port-vector
	vcrfi	rvc, rvc, 5		@ rvc <- value of port go-through-on-eof
	eq	rvc, #f			@ is eof acceptable?
	b	boolxt			@ exit with #t/#f based on result

@-------------------------------------------------------------------------------
@
@	UART INPUT/OUTPUT PORT and ISR
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input SUPPORT 4 - uart/usb input port:	uaripr, puagc0,1,2
@  II.A.6.6.3. output SUPPORT 4 - uart output port:	uaropr, puawrc, puaptc
@-------------------------------------------------------------------------------



puagc0:	@ uart read-helper init function
	@ prepare to get one or more chars from uart
	@ on entry:	sv1 <- ((port <reg> <n>) . port-vector) = full input port
	@ on exit:	sv2 <- position of last char read from buffer, copy
	@ on exit:	sv4 <- position of last char read from buffer
	@ preserves:	sv1, sv3, sv5, rva, rvb, rvc
	@ modifies:	sv2, sv4
	cdar	sv2, sv1
	pntrp	sv2
	itEE	eq
	careq	sv2, sv2
	ldrne	sv2, =BUFFER_START
	vcrfine	sv2, sv2, READ_BF_offset	
	vcrfi	sv2, sv2, 0		@ sv2 <- num chars in bfr (int/flt)
	and	sv2, sv2, #3
	add	sv2, sv2, #0x0C		@ sv2 <- ofst to befr 1st chr in READBFR
	set	sv4, sv2		@ sv4 <- ofst to befr 1st chr in READBFR
	set	pc,  lnk		@ return
	

puagc1:	@ uart read-helper getc function
	@ get next char from uart into rvb, update char position in sv4
	@ on entry:	sv1 <- ((port <reg> <n>) . port-vec) = full input port
	@ on entry:	sv2 <- value to preserve (eg. ofst to before 1st chr)
	@ on entry:	sv4 <- ofst to befr 1st char in READBFR or copy (pk-chr)
	@ on entry:	sv5 <- value to preserve (eg. lnk of caller)
	@ on entry:	rvc <- value to preserve (eg. previous char read)
	@ on exit:	rvb <- ascii char read or eof (raw ascii char)
	@ on exit:	rvc <- entry val of rvb (pchred prev chr, frdxp4 pos)
	@ on exit:	sv4 <- updated char offset in READBUFFER (or its copy)
	@ preserves:	sv1, sv2, sv5, rva
	@ modifies:	sv3, sv4, rvb, rvc
	set	rvc, rvb		@ rvc <- entry val of rvb, set for exit
	cdar	sv3, sv1
	pntrp	sv3
	itEE	eq
	careq	sv3, sv3
	ldrne	sv3, =BUFFER_START
	vcrfine	sv3, sv3, READ_BF_offset	
	vcrfi	rvb, sv3, 0		@ rvb <- num chars in bfr (scheme int)
	add	rvb, rvb, #0x10		@ rvb <- offest to after last bfr char
	add	sv4, sv4, #0x04		@ sv4 <- offset of char to read
	cmp	sv4, rvb		@ is ofst of chr to rd past end of bfr?
	itE	pl
	setpl	rvb, #eof		@	if so,  rvb <- eof
	bytrefmi rvb, sv3, sv4		@	if not, rvb <- chr from read bfr
	set	pc,  lnk		@ return	


puagc2:	@ uart read-helper function finish-up
	@ extract string and crunch buffer
	@ on entry:	sv1 <- ((port <reg> <n>) . port-vec) = full input port
	@ on entry:	sv2 <- offset to before 1st char in READBUFFER
	@ on entry:	sv4 <- offset of last char read
	@ on exit:	sv1 <- string to be parsed or eof-char
	@ preserves:	sv5
	@ modifies:	sv1, sv2, sv3, sv4, rva, rvb, rvc
	bic	sv3, lnk, #lnkbit0	@ sv5 <- lnk, saved (made even if T2)
	save3	sv4, sv3, sv5		@ dts <- (end lnk sv5 ...)
	cdar	sv3, sv1		@ sv3 <- (port's read buffer) or '()
	pntrp	sv3			@ does port have read buffer?
	itEE	eq
	careq	sv1, sv3		@	if so,  sv1 <- port's read buffr
	ldrne	sv1, =BUFFER_START
	vcrfine	sv1, sv1, READ_BF_offset
	car	sv3, dts		@ sv3 <- end -- offset to last char
	save	sv1			@ dts <- (port's-read-bfr end lnk sv5 .)
	add	sv2, sv2, #4		@ sv2 <- start -- offset to 1st char
	bl	subcpy			@ sv1 <- expression -- i.e. substring
	restor	sv3			@ sv3 <- rd-bfr rstrd,dts<-(end lk sv5.)
	restor	sv4			@ sv4 <- strt chrs to mov,dts<-(lk sv5.)
	save	sv1			@ dts <- (expr-to-parse lnk sv5 ...)
	set	sv1, sv3		@ sv1 <- port's-read-buffer
	add	sv2, sv4, #4		@ sv2 <- start offset, incl header & cr
	vcrfi	sv3, sv1, 0		@ rvb <- number of chars in buffer
	add	sv3, sv3, #0x10		@ rvb <- offest to after last buffr char
	set	sv4, sv1		@ sv4 <- destination
	set	rvb, #4
	swi	run_no_irq		@ disable interrupts (user mode)
cpmem:	@ copy from start to end
	cmp	sv2, sv3		@ are we done copying?
	it	mi
	bytrefmi rva, sv1, sv2		@ rva <- raw byte from source
	itTT	mi
	strbmi	rva, [sv4, rvb]		@ store it in target
	addmi	sv2, sv2, #4		@ sv2 <- updated source end offset
	addmi	rvb, rvb, #1		@ rvb <- updated target end address
	bmi	cpmem			@ jump to continue copying bytes
	sub	rvb, rvb, #4		@ rvb <- number of chars copied
	lsl	rvb, rvb, #2		@ rvb <- number of chars, shifted
	vcrfi	sv5, sv1, 0		@ sv5 <- num chars in buffer (int/flt)
	and	sv5, sv5, #3
	orr	rvb, rvb, sv5		@ rvb <- number of chars (scheme int)
	vcsti	sv1, 0, rvb		@ store that in buffer
	swi	run_normal		@ re-enable interrupts (user mode)
	restor2	sv1, sv5		@ sv1 <- exp to pars,sv5<-lk,dts<-(sv5.)
	orr	lnk, sv5, #lnkbit0	@ lnk <- restored
	restor	sv5			@ sv5 <- restored, dts <- (...)
	set	pc,  lnk		@ return

puawrc:	@ uart write-char / write-string sub-function
	@ on entry:	sv1 <- scheme char or string to write out
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vec) = full out port
	@ modifies:	sv4, rva, rvb, rvc
	caar	sv4, sv2		@ sv4 <- port
	lsr	rva, sv4, #2		@ rva <- port base adrs without upr 2bt
	lsl	sv4, rva, #4		@ sv4 <- full port base address
	pntrp	sv1			@ are we writing a string?
	beq	pputs			@	if so,  write string ret via lnk
	chr2raw	rvb, sv1		@ rvb <- raw ASCII character from sv1
	b	prthwp			@ jump to write character (ret via lnk)

puaptc:	@ uart putc sub-sub-function
	@ write raw ascii value in rvb to UART specified by base address in sv4
	@ on entry:	sv1 <- scheme char or string to write out
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vec) = full out port
	@ on entry:	sv3 <- saved lnk from caller of caller
	@ on entry:	sv4 <- port address
	@ on entry:	sv5 <- saved lnk from caller
	@ on entry:	rvb <- ascii char to write + offset in string (if strng)
	@ preserves:	sv1, sv2, sv3, sv4, sv5, rvb, rvc
	@ modifies:	rva
	swi	run_no_irq		@ disable interrupts (user mode)
uarptd:	ldrb    rva, [sv4, #uart_status]@ rva <- Status of UART
	tst	rva, #uart_txrdy	@ is UART ready to send byte?
	beq	uarptd			@	if not, jump to keep waiting
        strb	rvb, [sv4, #uart_thr]	@ Write content of rvb out to UART's THR
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk

puaisr:	@ uart ISR
	eq	rvb, #uart0_int_num	@ is interrupt for UART0?
	itE	eq			@	if-then (Thumb-2)
	ldreq	rva, =uart0_base	@	if so,  rva <- UART0 base adrs
	ldrne	rva, =uart1_base	@	if not, rva <- UART1 base adrs
	ldrb    fre, [rva, #uart_rhr]	@ fre <- Byte from UART
	ldr	rvb, =BUFFER_START
	vcrfi	rvb, rvb, READ_BF_offset
	ldr	cnt, [rvb, #-4]
	lsr	cnt, cnt, #6
	sub	cnt, cnt, #0x10
	vcrfi	rvc, rvb, 0
	tst	rvc, #i0		@ are we in normal mode?
	beq	uarnec			@	if not, jump to special mode
	eq	fre, #3			@ is byte a ctrl-c?
	beq	uarbrk			@	if so,  exit via break int
	eq	fre, #'\n		@ is byte a lf?
	beq	uarskp			@	if so,  ignore it (jump to exit)
	eq	fre, #'\b		@ is byte a backspace?
	beq	uarbks			@	if so,  jump to process it
	cmp	rvc, cnt		@ readbuffer full?
	bpl	uarskp			@	if so,  jump to exit
	add	cnt, rvb, rvc, lsr #2	@ cnt <- char offset (after num-chars)
	strb	fre, [cnt, #4]		@ store byte in buffer
	add	rvc, rvc, #4		@ rvc <- offset of next char in buffer
	bl	iuaptc			@ echo character
uarixt:	@ finish up
	vcsti	rvb, 0, rvc		@ store number of chars in bfr, sch int
uarskp:	@ clear interrupt in uart[0/1] and interrupt vector
	clearUartInt			@ clear interrupt in uart[0/1]
	b	gnisxt			@ jump to exit isr (simple)

_func_
uarbks:	@ process a backspace
	lsrs	cnt, rvc, #2		@ is num chars in buffer zero?
	it	ne
	subne	rvc, rvc, #4		@	if not, rvc <- offst of nxt chr
	bl	iuaptc			@ write backspace out to UART
	set	fre, #' 		@ fre <- space (raw ASCII)
	bl	iuaptc			@ write space out to UART
	set	fre, #'\b		@ fre <- backspace
	bl	iuaptc			@ write backspace out to UART
	b	uarixt

_func_
uarnec:	@ process char with no special treatment and no echo
	eor	cnt, cnt, #3
	cmp	rvc, cnt		@ readbuffer full?
	bpl	uarskp			@	if so,  jump to exit
	add	cnt, rvb, rvc, lsr #2	@ cnt <- char offset (after num-chars)
	strb	fre, [cnt, #4]		@ store byte in buffer
	add	rvc, rvc, #4		@ rvc <- offset of next char in buffer
	b	uarixt

_func_
iuaptc:	@ write raw ascii value in fre (r0) to UART specified in rva (r2)
	@ on entry:	fre <- raw char to write out
	@ on entry:	rva <- uart base address
	@ modifies:	cnt
	ldrb    cnt, [rva, #uart_status] @ cnt <- Status of UART
	tst	cnt, #uart_txrdy	@ is UART ready to send byte?
	beq	iuaptc			@	if not, jump to keep waiting
        str	fre, [rva, #uart_thr]	@ Write content of fre out to UART's THR
	set	pc,  lnk		@ return

_func_
uarbrk:	@ process a break (ctrl-c)
	clearUartInt			@ clear interrupt in uart[0/1]
	ldr	rva, =BUFFER_START	@ rva <- address of main buffer
	vcrfi	rva, rva, READ_BF_offset @ rva <- address of readbuffer
	set	rvb, #i0		@ rvb <- 0 (scheme int)
	vcsti	rva, 0, rvb		@ set number of chars in readbuffer to 0
	mvn	rvb, fre		@ rvb <-  3 (ascii ctrl-c) inverted
	add	rvb, rvb, #1		@ rvb <- -3 (to indicate ctrl-c)
	set	pc,  lnk		@ return to genisr
	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input SUPPORT 5  - file input  port:	filipr, pflcli, pflgc0,
@							pflgc1, pflgc2
@  II.A.6.6.3. output SUPPORT 5 - file output port:	filopr, pflclo, pflwrc,
@							pflptc, pputs
@-------------------------------------------------------------------------------

	PFUNC	2
pflwrc:	@ file write-char / write-string sub-function
	@ on entry:	sv1 <- scheme char or string to write out
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vec) = full out port
	@ on exit:	sv4 <- updated file descriptor
	@ modifies:	sv3, sv4, sv5, rva, rvb, rvc
	@ write char in sv1 to FLASH file in sv2
	set	sv5, sv2		@ sv5 <- out port savd (ffhofl mods sv2)
	caar	sv2, sv2		@ sv2 <- file-ID (for ffhofl)
	tst	sv2, #f0		@ is file-ID an int?
	it	ne
	eorne	sv2, sv2, #0x03		@	if not, sv2 <- fileID for ffhofl
	bic	rvc, lnk, #lnkbit0	@ rvc <- lnk, saved against flok, ffhofl
	bl	flok			@ acquire file system lock
	bl	ffhofl			@ sv4 <- desc,sv2<-pre-lst,sv3<-post-lst
	set	sv2, sv5		@ sv2 <- full output port, restored
	set	sv3, rvc		@ sv3 <- saved lnk (pputs mods rvc)
	nullp	sv4			@ file open?
	it	ne
	cadarne	sv4, sv4		@	if so,  sv4 <- #(fnam pg ofst())
	itT	ne
	vcrfine sv5, sv4, 3		@	if so,  sv5 <- (<buffer>)
	nullpne	sv5			@	if so,  is file opened for out?
	beq	pflwrx			@		if not, jump to exit
	pntrp	sv1			@ is object to write a string?
	beq	pflwrs			@	if so, jump to write string
	chr2raw	rvb, sv1		@ rvb <- raw ascii char
	bl	prthwp			@ jump to write character
	b	pflwrx			@ jump to finish up
pflwrs:	bl	pputs			@ jump to write string
pflwrx:	@ finish up
	orr	lnk, sv3, #lnkbit0	@ lnk <- lnk, restored
	b	funlok			@ release file system and return via lnk
	
_func_	
pputs:	@ port write string function
	@ write string in sv1 to port in sv2
	@ on entry:	sv1 <- string
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vec) = full out port
	@ on entry:	sv3 <- saved lnk from caller
	@ on entry:	sv4 <- file descriptor / port position desciptor
	@ on exit:	sv4 <- updated file descriptor / port position desciptor
	@ preserves:	sv1, sv2, sv3, sv4 (if not file)
	@ modifies:	sv4 (if file), sv5, rva, rvb, rvc
	caar	sv5, sv2		@ sv5 <- port
	set	rvc, #i0		@ rvc <- 1st char offset (scheme int)
	tst	sv5, #0x02		@ is port a float (display vs write)?
	it	ne
	eorne	rvc, rvc, #0x03		@	if so,  rvc <- 1st char offset
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved against oprtfn
pputs0:	strlen	rva, sv1		@ rva <- number of chars (scheme int)
	cmp	rvc, rva		@ done writing?
	itT	pl
	orrpl	lnk, sv5, #lnkbit0
	setpl	pc,  lnk
	bytref	rvb, sv1, rvc		@ rvb <- raw ascii char
	tst	rvc, #0x02		@ doing display (rather than write)?
	bne	pputs1			@	if so,  jump to write char
	eq	rvb, #'"		@ writing a " (dble-quote), withn strng?
	it	ne
	eqne	rvb, #'\\		@	if not, writing \, withn strng?
	bne	pputs1
	set	rvb, #'\\
	orr	rvb, rvb, rvc, lsl #8	@ rvb <- ascii chr + savd src strng ofst
	bl	prthwp			@ jump to write character
	lsr	rvc, rvb, #8		@ rvc <- offset of char, restored
	bytref	rvb, sv1, rvc		@ rvb <- raw ascii char, re-acquired
pputs1:	@ write char to port	
	orr	rvb, rvb, rvc, lsl #8	@ rvb <- ascii chr + savd src strng ofst
	bl	prthwp			@ jump to write character
	lsr	rvc, rvb, #8		@ rvc <- offset of char, restored
	add	rvc, rvc,  #4		@ rvc <- offset of nxt char (scheme int)
	b	pputs0			@ jump to keep writing


.ifndef live_SD

	PFUNC	1
pflgc0:	@ file read-helper init function
	@ prepare to get one or more chars from file
	@ on entry:	sv1 <- ((fid #(fname page offset ())) . port-vector) = full input port
	@ on exit:	sv2 <- #(fid page offset) == file start-status partial copy or 0 if file can't be read
	@ on exit:	sv4 <- pointer to #(fname page offset ()) in full input port
	@ preserves:	sv1, sv5
	@ modifies:	sv2, sv3, sv4, rva, rvb, rvc
	bic	rvc, lnk, #lnkbit0	@ rvc <- lnk (saved against flok, ffhofl)
	caar	sv2, sv1		@ sv2 <- file handle (i.e. port) (for ffhofl)
	tst	sv2, #0x01		@ is port a float (doing peek-char rather than read-char)?
	it	eq
	eoreq	sv2, sv2, #0x03
	bl	flok			@ acquire file system lock
	bl	ffhofl			@ sv4 <- full-port or (), sv2 <- pre-sublist, sv3 <- post-sublist
	orr	lnk, rvc, #lnkbit0	@ lnk <- restored
	@ verify that file is open and has flash presence (could be open, but not yet on flash)
	nullp	sv4			@ file open?
	itTT	ne
	carne	sv4, sv4		@	if so,  sv4 <- (fid #(fname page offset ()))
	snocne	sv2, sv4, sv4		@	if so,  sv2 <- fid, sv4 <- (#(fname page offset ()))
	carne	sv4, sv4		@	if so,  sv4 <- #(fname page offset ())
	itT	ne
	vcrfine rva, sv4, 1		@	if so,  rva <- page
	eqne	rva, #i0		@	if so,  is pg 0? (fl not yet wrttn to FLSH | rd to end)
	it	eq
	seteq	sv2, #i0		@	if so,  sv2 <- 0, indicates fil cant be read (scheme int)
	beq	funlok			@	if so,  release file system lock, return via lnk
	@ copy sv4 contents into sv2
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk (saved against zmaloc)
	set	rvb, #12		@ rvb <- 16 = bytes needed to copy file descriptor
	bl	zmaloc			@ rva <- address of memory block = descriptor copy
	vcsti	rva, 0, sv2		@ store handle in copy block
	vcrfi	rvc, sv4, 1		@ rvc <- page from file descriptor
	vcsti	rva, 1, rvc		@ store page in copy block
	vcrfi	rvc, sv4, 2		@ rvc <- offset from file descriptor
	vcsti	rva, 2, rvc		@ store offset in copy block
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv2, rva, rvb		@ sv2 <- #vu8(fid fpag offst) copied positn [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	orr	lnk, sv3, #lnkbit0	@ lnk <- restored
	b	funlok			@ release file system lock, return via lnk


	PFUNC	4
pflgc1:	@ file read-helper getc function
	@ on entry:	sv1 <- ((fid #(fname page offset ())) . port-vector) = full input port
	@ on entry:	sv2 <- #(fid page offset) == file start-status partial copy
	@ on entry:	sv4 <- pointer to #(fname page offset ()) in full input port
	@ on entry:	sv5 <- value to preserve (eg. lnk of caller)
	@ on entry:	rvc <- value to preserve (eg. previous char read)
	@ on exit:	rvb <- ascii char read or eof (raw ascii char)
	@ on exit:	rvc <- entry value of rvb (eg. prev char in pchred, position in frdxp4)
	@ on exit:	sv4 <- updated file descriptor (or its partial copy)
	@ preserves:	sv1, sv2, sv5
	@ modifies:	sv3, sv4, rva, rvb, rvc
	set	rvc, rvb		@ rvc <- entry value of rvb, set for exit
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk (saved against flok)
	bl	flok			@ acquire file system lock
	orr	lnk, sv3, #lnkbit0	@ lnk <- lnk (restored)
	@ verify that file has flash presence
	vcrfi	sv3, sv4, 1		@ sv3 <- page address
	eq	sv3, #i0		@ is page zero? (file not yet written to FLASH)
	beq	fgetcx			@	if so,  jump to exit with eof-char
	vcrfi	rva, sv4, 2		@ rva <- offset
	asr	rva, rva, #2		@ rva <- offset (raw int)
	cmp	rva, #F_PAGE_SIZE	@ is offset larger than page size?
	bmi	fgetc2			@	if not, jump to continue
	@ find address of next page of file
	ldr	sv3, =F_START_PAGE	@ sv3 <- address of flash start page for files
fgetc1:	vcrfi	rva, glv, 11		@ rva <- address of end of file flash (crunch space)
	bic	rva, rva, #i0
	cmp	sv3, rva		@ is page >= end page?
	bpl	fgetcx			@	if so,  jump to exit with eof-char
	tbrfi	rva, sv3, 0		@ rva <- potential file ID on FLASH
	vcrfi	rvb, sv4, 1		@ rvb <- original page address
	tbrfi	rvb, rvb, 0		@ rvb <- file ID
	eq	rvb, rva		@ is it the ID we're looking for?
	itTTT	eq
	tbrfieq rva, sv3, 1		@	if so,  rva <- file block number
	vcrfieq rvb, sv4, 1		@	if so,  rvb <- original page address
	tbrfieq rvb, rvb, 1		@	if so,  rvb <- original block number
	increq	rvb, rvb		@	if so,  rvb <- next block
	it	eq
	eqeq	rvb, rva		@	if so,  is it the block number we're looking for?
	it	ne
	addne	sv3, sv3, #F_PAGE_SIZE	@	if not, sv3 <- start address of next page
	bne	fgetc1			@	if not, jump to scan next page
	@ update file descriptor
	vcsti	sv4, 1, sv3		@ store new page in file descriptor
	set	rva, #49		@ rva <- offset, byte 12 (scheme int)
	vcsti	sv4, 2, rva		@ store new offset in file descriptor
fgetc2:	@ read from page in descriptor sv4 and update descriptor
	vcrfi	sv3, sv4, 1		@ sv3 <- start address of page
	tbrfi	rvb, sv3, 2		@ rvb <- offset of last char in file
	vcrfi	rva, sv4, 2		@ rva <- offset to read from
	cmp	rva, rvb		@ is offset >= offset of last char in file?
	bpl	fgetcx			@	if so,  jump to exit with eof-char
	bytref	rvb, sv3, rva		@ rvb <- byte from FLASH
	eq	rvb, #0xFF		@ is byte the end-of-file byte?
	beq	fgetcx			@	if so,  jump to exit with eof-char
	incr	rva, rva		@ rva <- offset to next char
	vcsti	sv4, 2, rva		@ store updated offset in file descriptor
fgetc3:	set	rva, #0			@ rva <- 0, files unlocked indicator
	ldr	sv3, =BUFFER_START	@ sv3 <- address of main system buffer
	vcsti	sv3, FILE_LOCK, rva	@ set file system to unlocked state	
	set	pc,  lnk
fgetcx:	@ exit with eof
	set	rvb, #eof		@ rvb <- eof
	b	fgetc3


	PFUNC	5
pflgc2:	@ file read-helper function finish-up
	@ extract string and update file descriptor function
	@ on entry:	sv1 <- ((fid #(fname page offset ())) . port-vector) = full input port
	@ on entry:	sv2 <- #(fid page offset) == file start-status partial copy
	@ on entry:	sv4 <- pointer to #(fname page offset ()) in full input port
	@ on exit:	sv1 <- string to be parsed or eof-char
	@ preserves:	sv5
	@ modifies:	sv1, sv2, sv3, sv4, rva, rvb, rvc
	@ use sv1 = start of what to read and sv4 = end of what to read to find how many chars to read
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk, saved (and made even if Thumb2)
	save	sv3			@ dts <- (lnk ...)
	bl	flok			@ acquire file system lock
	vcrfi	sv3, sv2, 2		@ sv3 <- start offset of file read
	vcrfi	rvc, sv4, 2		@ sv5 <- end offset of file read
	vcsti	sv4, 2, sv3		@ set start offset back into file descriptor (to restart read)
	vcrfi	rva, sv2, 1		@ rva <- start page address of file read
	vcrfi	rvb, sv4, 1		@ rvb <- end page address of file read
	vcsti	sv4, 1, rva		@ set start page back into file descriptor (to restart read)
	tbrfi	rva, rva, 1		@ rva <- file read start block number
	tbrfi	rvb, rvb, 1		@ rvb <- file read end block number
	sub	rvb, rvb, rva		@ rvb <- number of blocks spanned by read * 4
	asr	rvb, rvb, #2		@ rvb <- number of blocks spanned by read
	set	rva, #F_PAGE_SIZE	@ rva <- file page size
	sub	rva, rva, #12		@ rva <- file page size minus header (for blocks > 0)
	muls	rvb, rva, rvb		@ rvb <- number of chars for pages spanned by read, is it zero?
	itEEE	eq
	subeq	rvb, rvc, sv3		@	if so,  rvb <- number of chars to read * 4
	subne	rvb, rvb, sv3, ASR #2	@	if not, rvb <- num of chars to read adjstd for strt offst
	addne	rvb, rvb, rvc, ASR #2	@	if not, rvb <- num of chars to read adjstd for end offst
	lslne	rvb, rvb, #2		@	if not, rvb <- number of chars to read * 4
	eq	rvb, #0			@ is number of chars zero (i.e. end of file)?
	it	eq
	ldreq	sv1, =eof_char		@	if so,  sv1 <- eof_char
	beq	frdxxt			@	if so,  exit with eof_char
	orr	sv3, rvb, #i0		@ sv3 <- num of chars to read, saved against zmaloc (scheme int)
	asr	rvb, rvb, #2		@ rvb <- number of chars to read (raw int)
	@ allocate target string
	bl	zmaloc			@ rva <- address of reserved memory block
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv2, rva, rvb		@ sv2 <- free string for chars read [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	set	rva, #string_tag	@ rva <- full string tag for zero chars
	orr	rva, rva, sv3, LSL #6	@ rva <- full string tag with number of chars to get
	str	rva, [sv2, #-4]		@ store it in reserved memory block
	@ get characters from file into target string
	bl	funlok			@ release file system lock, for pflgc1
	set	rvb, #i0		@ sv3 <- offest to 1st char (scheme int)
frdxp4:	bl	getc1			@ rvb <- chr frm flsh, rvc <- rvb, sv4 <- updtd pg & offst as ndd
	bytsetu	sv2, rvc, rvb		@ store it in target string
	strlen	rva, sv2		@ rva <- number of chars to get (scheme int) (modifies rvb)
	add	rvb, rvc, #4		@ rvb <- offset of next char
	cmp	rvb, rva		@ done getting chars?
	it	mi
	bmi	frdxp4			@	if not, jump to continue
	bl	flok			@ acquire file system lock, to own the lock when exit releases it
	set	sv1, sv2		@ sv1 <- extracted string
frdxxt:	@ finish up
	restor	sv3			@ sv3 <- lnk,				dts <- (...)
	orr	lnk, sv3, #lnkbit0	@ lnk <- restored
	b	funlok			@ release file system lock, return via lnk


	PFUNC	3
finfo:	@ file info -- return in sv2 information about the file whose name string is in sv3
	@ (best with scheme interrupts off)
	@ on entry:	sv1 <- (null . input-or-output-port-vector)
	@ on entry:	sv2 <- (null . input-or-output-port-vector) (symmetry of inbound call)
	@ on entry:	sv3 <- file name string
	@ on exit:	sv2 <- #(fname page offset ()) or 0.0 if file not found
	@ modifies:	sv2, sv4, sv5, rva, rvb, rvc
	@ returns via lnk
	set	sv1, sv3		@ sv1 <- file name string (for stsyeq), and saved
	set	sv4, sv2		@ sv4 <- (null . input-or-output-port-vector), saved
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved (and made even if Thumb2)
	ldr	sv2, =F_START_PAGE	@ sv2 <- address of flash start page for files
finfo0:	@ loop
	vcrfi	rva, glv, 11		@ rva <- address of end of file flash (crunch space)
	bic	rva, rva, #i0
	cmp	sv2, rva		@ is page >= end page?
	it	pl
	setpl	sv2, #f0		@	if so,  sv2 <- 0.0 (file not found)
	bpl	finfo2
	tbrfi	rva, sv2, 0		@ rva <- potential file ID
	and	rva, rva, #0xff
	eq	rva, #0xfd		@ is this an active file page?
	bne	finfo1			@	if not, jump to scan next page
	tbrfi	rva, sv2, 1		@ rva <- file block number
	eq	rva, #i0		@ is it block number 0? (i.e. this is the start page of a file)
	bne	finfo1			@	if not, jump to scan next page
	add	sv2, sv2, #20		@ sv2 <- address of file name in page	
	bl	stsyeq			@ are file names equal?
	sub	sv2, sv2, #20		@ sv2 <- address of start of page
finfo1:	itT	ne
	addne	sv2, sv2, #F_PAGE_SIZE	@	if so,  sv2 <- next page
	bne	finfo0			@	if so,  jump to scan next page
finfo2:	@ finish up
	set	rvb, #20		@ rvb <- 28 = bytes needed to update open file list
	bl	zmaloc			@ rva <- address of memory block = updated open file list
	set	rvc, #vector_tag	@ rva <- null vector tag
	orr	rvc, rvc, #0x0400	@ rva <- full vector tag with size (4 items)
	str	rvc, [rva, #-4]		@ fre+7 <- #( ___  ___  ___  ___ )
	ldr	rvc, [sv1, #-4]		@ rvc <- file name string tag
	lsr	rvc, rvc, #6		@ rvc <- #bytes in file name (scheme int)
	add	rvc, rvc, #0x5C		@ rvc <- #bytes in file name + 3 + offst to dat in fil (scheme int)
	bic	rvc, rvc, #0x0C		@ rvc <- offset to data in file, word aligned (scheme int)
	stmia	rva!, {sv1, sv2, rvc}	@ fre <- #(fname page offset ___  ___ )
	set	rvc, #null
	stmia	rva!, {rvc}		@ fre <- #(fname page-address data-offset () ___ )
	stmia	rva!, {rvc}		@ fre <- #(fname page-address data-offset () ())
	sub	sv2, rva, rvb		@ sv2 <- updated open file list [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	@ return
	set	sv3, sv1		@ sv3 <- file name, restored
	set	sv1, sv4		@ sv1 <- (null . input-or-output-port-vector), restored
	orr	lnk, sv5, #lnkbit0	@ lnk <- lnk, restored
	set	pc,  lnk		@ return


	PFUNC	1
filist:	@ return a list of files on this device (flash)
	@ on entry:	sv1 <- (null . input-port-vector)
	@ on exit:	sv1 <- list of file names
	@ returns via cnt
	set	sv1, #null		@ sv1 <- () = initial list cdr
	ldr	sv3, =F_START_PAGE	@ sv3 <- address of flash start page for files
	sub	sv3, sv3, #F_PAGE_SIZE	@ sv3 <- page before first file page
	vcrfi	sv4, glv, 11		@ sv4 <- address of end of file flash (crunch space)
	bic	sv4, sv4, #i0
files0:	
	add	sv3, sv3, #F_PAGE_SIZE	@ sv3 <- next page
	cmp	sv3, sv4		@ is page >= end page?
	it	pl
	setpl	pc,  cnt		@	if so,  return with list of file names
	tbrfi	rva, sv3, 0		@ rva <- potential file ID
	and	rva, rva, #0xff		@ rva <- lower byte of potential ID
	eq	rva, #0xfd		@ rva <- is this a valid ID (non-erased file)?
	bne	files0			@	if not, jump to scan next page
	tbrfi	rva, sv3, 1		@ rva <- file block number
	eq	rva, #i0		@ is it block number 0? (i.e. the start page of a file)
	bne	files0			@	if not, jump to scan next page
	set	sv2, sv1
	add	sv1, sv3, #20		@	if so,  sv1 <- file-name == address of file name in page
	cons	sv1, sv1, sv2		@	if so,  sv1 <- (file-name ...)
	b	files0			@ jump to scan next page


	PFUNC	2
pflclo:	@ file close-output-port sub-function
	@ on entry:	sv1 <- (<mode>), if non-null, close as input file (i.e. forget write-on-close)
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vector) = full output port
	@ on entry:	sv4 <- descriptor of file being closed, from open file list (from ffhofl)
	nullp	sv1			@ perform write-on-close?
	bne	npofxt			@	if not, jump to exit
	nullp	sv4			@ was file in open file list?
	beq	npofxt			@	if not, jump to exit
	cadar	sv4, sv4		@ sv4 <- #(fname page offset ())
	set	sv3, #i0		@ sv3 <- 0 (scheme int) for fwrfla/gc protection
	bl	flok
	bl	fwrfla			@ write file buffer (from sv4) to flash
	bl	funlok			@ release file system lock
	b	npofxt			@ return with npo


	PFUNC	2
pflptc:	@ file putc sub-sub-function
	@ on entry:	sv1 <- scheme char or string to write out
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vector) = full output port
	@ on entry:	sv3 <- saved lnk from caller of caller
	@ on entry:	sv4 <- file descriptor
	@ on entry:	sv5 <- saved lnk from caller
	@ on entry:	rvb <- ascii char to be written to file + offset of char in string (if string)
	@ on exit:	sv4 <- updated file descriptor
	@ preserves:	sv1, sv2, sv3, sv5, rvb
	@ modifies:	sv4, rva, rvc
	bic	rvc, lnk, #lnkbit0	@ rvc <- lnk, saved against fwrfla (and made even if Thumb2)
	@ does buffer need to be written to flash?
	vcrfi	rva, sv4, 2		@ rva <- offset
	asr	rva, rva, #2		@ rva <- offset (raw int)
	cmp	rva, #F_PAGE_SIZE	@ is offset larger than page size?
	it	pl
	blpl	fwrfla			@	if so,  sv4 <- updtd descr, rva <- stat, wrt bffr to flsh
	orr	lnk, rvc, #lnkbit0	@ lnk <- restored (as Thumb)
	eq	rva, #0			@ did write fail?
	it	eq
	seteq	pc,  lnk		@	if so,  return
	@ write char in rvb to buffer in file descriptor sv4
	set	rvc, sv5		@ rvc <- saved lnk from caller (frees sv5 to use for bffr below)
	vcrfi	rva, sv4, 2		@ rva <- offset
	vcrfi	sv5, sv4, 3		@ sv5 <- buffer (scheme vector, gc-eable)
	bytsetu	sv5, rva, rvb		@ store character in buffer	
	incr	rva, rva		@ rva <- updated offset
	vcsti	sv4, 2, rva		@ store updated offset in file descriptor
	vcsti	sv5, 2, rva		@ store updated offset in buffer
	set	sv5, rvc		@ sv5 <- saved lnk from caller, restored
	set	pc,  lnk		@ return

_func_	
fwrfla:	@ write buffer to flash, 
	@ on entry:	sv4 <- file descriptor
	@ on entry:	rvb <- char to be written to file next (to be saved, restored)
	@ on entry:	rvc <- lnk of caller (to be saved, restored)
	@ uses:		sv2, rva, rvb
	@ uses:		68 bytes of user-stack space
	@ identify file ID and block number for buffer
	stmfd	sp!, {rvb, rvc, lnk}	@ store scheme registers onto stack
	save	sv2
	vcrfi	sv2, sv4, 1		@ sv2 <- page address
	eq	sv2, #i0		@ does buffer contain page zero of file? (i.e. this is a new file)
	itTTT	ne
	tbrfine rvb, sv2, 1		@	if not, rvb <- block number of previous file page
	addne	rvb, rvb, #4		@	if not, rvb <- block number for buffer/new page
	tbrfine rva, sv2, 0		@	if not, rva <- ID of file
	bne	fwrfl1			@	if not, jump to continue
	@ find a new ID for file
	set	rva, #0xfd		@ rva <- #xfd, tentative file Id (#b0...0 1111 1101 -- scheme int)
	ldr	sv2, =F_START_PAGE	@ sv2 <- address of flash start page for files
fwrfl0:	
	vcrfi	rvb, glv, 11		@ rvb <- address of end of file flash (crunch space)
	bic	rvb, rvb, #i0
	cmp	sv2, rvb		@ is page >= end page? (i.e. file ID is new)
	itT	pl
	setpl	rvb, #i0		@	if so,  rvb <- 0, block number for new file
	bpl	fwrfl1			@	if so,  jump to continue with ID in rva
	tbrfi	rvb, sv2, 0		@ rvb <- potential file ID from flash
	eq	rva, rvb		@ is flash file ID equal to the tentative file ID?
	itTE	eq
	addeq	rva, rva, #0x100	@	if so,  rva <- new tentative file ID
	ldreq	sv2, =F_START_PAGE	@	if so,  sv2 <- address of start page to scan for file ID
	addne	sv2, sv2, #F_PAGE_SIZE	@	if not, sv2 <- address of next page
	b	fwrfl0			@ jump to scan next page
fwrfl1:	@ store file ID and block number in buffer
	vcrfi	sv2, sv4, 3		@ sv2 <- buffer
	vcsti	sv2, 0, rva		@ store file ID in buffer
	vcsti	sv2, 1, rvb		@ store block number in buffer
	@ identify a free page in which to write buffer
	ldr	sv2, =F_START_PAGE	@ sv2 <- address of flash start page for files
fwrfl2:	
	vcrfi	rva, glv, 11		@ rva <- address of end of file flash (crunch space)
	bic	rva, rva, #i0
	cmp	sv2, rva		@ is page >= end page?
	bpl	fwrcrn			@	if so, jump to crunch files in flash (returns to fwrflc)
	tbrfi	rva, sv2, 0		@ rva <- potential free page in flash
	mvns	rva, rva		@ rva <- not(rva) & set eq flag if that is zero, i.e. page is free
	it	ne
	addne	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- address of next page
	bne	fwrfl2			@ jump to scan next page
fwrflc:	@ commit write to flash (destination page is in sv2)
	bl	wrtfla
	@ update file descriptor
	vcsti	sv4, 1, sv2		@ store (prev)page in file descriptor
	set	sv2, #49		@ sv2 <- (new)offset (12 as scheme int)
	vcsti	sv4, 2, sv2		@ store (new)offset in file descriptor
	@ erase crunch space if needed and return
	bl	fcsdel			@ erase crunch space if needed (cleanup)
	set	rva, #0xff		@ rva <- non-zero status = write o.k.
fwrfxt:	@ exit
	restor	sv2
	ldmfd	sp!, {rvb, rvc, pc}	@ return

	
_func_	
fwrcrn:	@ file crunching during file write
	@ on entry:	sv2 <- F_START_PAGE
	@ on entry:	sv4 <- file descriptor of file to write to flash after crunch
	@ on entry:	sp  <- (rvb, rvc, pc)
	@ modifies:	sv2, sv4, rva, rvb, rvc, lnk, dts
	@ returns to:	fwrflc (not lnk, not cnt)
	bl	ff1del			@ sv2 <- 1st page with pseudo deleted file, rva <- 0 if none
	eq	rva, #0			@ is flash completely full? (no pseudo-deleted page)
	beq	fwrfxt			@	if so,  return with rva=0 (raw int) - flash completely full
	@ crunch files in flash (to free space for buffer)
	save	sv4			@ save sv4 (file descriptor vector of file to write after crunch)
	@ allocate memory for file descriptor and buffer
	bl	mkfdsc			@ sv4 <- blank output file descriptor (with buffer)
	bl	pgsctr			@ rva <- sector of deleted page whose address is in sv2
	add	rvc, rva, #1		@ rvc <- sector after that of deleted page
	@ copy from source FLASH page(s) to target FLASH page(s) (if src wasn't deltd)
	ldr	rvb, =flashsectors	@ rvb <- address of FLASH sector table
	ldr	rva, [rvb, rva, LSL #2]	@ rva <- address of start page of source sector
	ldr	rvb, [rvb, rvc, LSL #2]	@ rvb <- address of start page of next sector (end page)
	vcrfi	rvc, glv, 11		@ rvc <- address of crunch space (destination, pseudo scheme int)
	bic	rvc, rvc, #i0		@ rvc <- address of crunch space (destination)
	vcsti	sv4, 2, rva		@ store src start page address in caller-tmp-storage of sv4
	bl	flshcp			@ perform flash copy (sv4 updated)
	@ prepare to copy back from extra FLASH to file FLASH, or commit write if done crunching
	vcrfi	rva, glv, 11		@ rva <- address of crunch space (source start, pseudo scheme int)
	bic	rva, rva, #i0		@ rva <- address of crunch space (source start)
	vcrfi	rvb, sv4, 1		@ rvb <- address of end of extra FLASH target (source end)
	vcrfi	rvc, sv4, 2		@ rvc <- start address of former source = destination for copy
	bl	flshcp			@ perform flash copy (sv4 updated)
	vcrfi	sv2, sv4, 1		@ sv2 <- address after end of copied pages (target)
	restor	sv4			@ restore sv4 (file descriptor)
	b	fwrflc			@ jump back to commit write to FLASH
	

	PFUNC	3
filers:	@ erase an existing file before writing to it (pseudo-erase,
	@ old file invalidated) and, prepare output buffer contents
	@ on entry:	sv1 <- (null . input-or-output-port-vector)
	@ on entry:	sv2 <- (null . in-or-out-port-vec) (sym inbound call)
	@ on entry:	sv4 <- #(name page offset buffer)
	@ modifies:	sv2, sv3, sv5, rva, rvb, rvc
	@ updates:	sv4 (page updated to 0, scheme int)
	@ returns via lnk
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved (made even if T2)
	vcrfi	sv2, sv4, 1		@ sv2 <- strt-pg of fil, #f0 if not fnd
	eq	sv2, #f0		@ file not found?
	beq	flers1			@	if so,  jump to continue
	tbrfi	sv3, sv2, 0		@ sv3 <- fil ID, from strt pg of old fil
	ldr	sv2, =F_START_PAGE	@ sv2 <- adrs of flash strt pg for fils
flers0:	@ loop
	vcrfi	rvb, glv, 11		@ rvb <- address of end of file flash
	bic	rvb, rvb, #i0		@ rvb <- address of flash crunch sector
	cmp	sv2, rvb		@ is page >= end page?
	bpl	flers1			@	if so,  jump to continue (done)
	tbrfi	rva, sv2, 0		@ rva <- potential file ID for page
	eq	sv3, rva		@ is page's fil ID that of fil to erase?
	it	eq
.ifndef	wrtflr
	bleq	wrtfla			@	if so,  overwrite page to ID 0
.else
	bleq	wrtflr			@	if so,  overwrite page to ID 0
.endif
	add	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- address of next page
	b	flers0			@ jump to continue scanning pages
flers1:	@ initialize info and buffer
	orr	lnk, sv5, #lnkbit0	@ lnk <- restored
	vcrfi	sv5, sv4, 0		@ sv5 <- file name
	vcrfi	sv3, sv4, 3		@ sv3 <- buffer
	set	rva, #i0		@ rva <- 0 (scheme int)
	vcsti	sv4, 1, rva		@ page <- 0 (scheme int)
	vcsti	sv3, 0, rva		@ buffer <- 'ID=0
	vcsti	sv3, 1, rva		@ buffer <- 'ID=0,block-number=0
	vcrfi	rvb, sv4, 2		@ rvb <- offset
	vcsti	sv3, 2, rvb		@ buffer <- 'ID=0,block-number=0,offset
	@ copy file name into buffer
flers2:	sub	rvb, rvb, #16		@ rvb <- ofst nxt wrd of fnam strng cpy
	sub	rvc, rvb, #80		@ rvc <- ofst in src strng, 20B blw bfr
	wrdref	rva, sv5, rvc		@ rva <- word from file name string
	wrdst	sv3, rvb, rva		@ store it in bfr (mods rvc)
	eq	rvb, #65		@ done copying file name string (+ tag)?
	bne	flers2			@	if not, jump to keep copying
	set	pc,  lnk		@ return with address in sv2

.ltorg

.endif	@ .ifndef live_SD


.ifdef	onboard_SDFT

.ifdef	sd_is_on_spi

_func_	
sd_ini:	@ initialize communication with SD card
	@ on exit:	sv1 <- #t/#f for initialization success/failure
	@ modifies:	sv1, sv3, sv4, sv5, rva, rvb, rvc
	bl	sd_dsl
	bl	sd_slo
	set	rvc, #10
sd_in0:	@ initial pulse train
	bl	sd_get
	subs	rvc, rvc, #1
	bne	sd_in0
	bl	sd_sel
	set	sv4, #i0
	set	rvc, #0
	bl	sd_cmd
	set	sv3, #i0
sd_in1:	@ connect
	set	sv4, #i1
	set	rvc, #0
	bl	sd_cmd
	eq	rvb, #0
	beq	sd_in2
	add	sv3, sv3, #4
	cmp	sv3, #0x8000
	bmi	sd_in1
sd_in2:	@ continue
	eq	rvb, #0
	itE	eq
	seteq	sv1, #t
	setne	sv1, #f
	set	rvb, #0x10
	raw2int	sv4, rvb
	set	rvc, 512
	bl	sd_cmd
	@ done
	bl	sd_dsl
	bl	sd_cfg
	set	pc,  cnt

_func_	
sd_cmd:	@ send cmd to SD card
	@ on entry:	sv4 <- cmd (scheme int)
	@ on entry:	rvc <- arg (raw int)
	@ on exit:	rvb <- value returned by cmd
	@ modifies:	sv5, rva, rvb
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
	bl	sd_get
	int2raw	rvb, sv4
	orr	rvb, rvb, #0x40
	bl	sd_put
	lsr	rvb, rvc, #24
	bl	sd_put
	lsr	rvb, rvc, #16
	bl	sd_put
	lsr	rvb, rvc, #8
	bl	sd_put
	set	rvb, rvc
	bl	sd_put
	eq	sv4, #i0
	itE	eq
	seteq	rvb, #0x95		@ CRC for CMD 0
	setne	rvb, #0xff 		@ pseudo-crc for other cmds
	bl	sd_put
	@ wait for non #xff response
	set	rvc, #1
sd_cm1:	@ wait loop
	bl	sd_get
	eq	rvb, #0xff
	bne	sd_cm2
	add	rvc, rvc, #1
	eq	rvc, #10
	bne	sd_cm1
sd_cm2:	@ done, return
	orr	lnk, sv5, #lnkbit0	@ lnk <- restored
	set	pc,  lnk


_func_	
_sgb:	@ [internal only]
	@ sd-get-block internal func
	@ on entry:  rvc <- block number to be read (scheme int)
	@ on entry:  sv3 <- buffer in which to store block data (scheme bytevec)
	@ on exit:   sv3 <- updated buffer
	@ modifies:  sv3, sv5, rva, rvb, rvc
	bic	sv5, lnk, #lnkbit0
	bl	sd_cfg			@ configure the spi interface
	bl	sd_sel			@ select sd
	@ put-cmd
	@ 1- get
	bl	sd_get
	@ 2- write read-single-block cmd for block in rvc
	set	rvb, #0x51
	bl	sd_put
	bic	rvc, rvc, #3
	lsr	rvb, rvc, #17
	bl	sd_put
	lsr	rvb, rvc, #9
	bl	sd_put
	lsr	rvb, rvc, #1
	bl	sd_put
	lsl	rvb, rvc, #7
	bl	sd_put
sgrdwt:	@ 3- wait for read-ready
	bl	sd_get
	eq	rvb, #0xfe
	bne	sgrdwt
	@ get and save data (512 bytes)
	set	rvc, #0
sggtlp:	@ loop
	bl	sd_get
	strb	rvb, [sv3, rvc]
	add	rvc, rvc, #1
	eq	rvc, #0x0200
	bne	sggtlp
	@ get crc
	bl	sd_get
	bl	sd_get
	@ return
	bl	sd_dsl			@ de-select sd
	orr	lnk, sv5, #lnkbit0	@ lnk <- restored
	set	pc,  lnk

_func_	
_spb:	@ [internal only]
	@ sd-put-block internal func
	@ on entry:  rvc <- block number to be write (scheme int)
	@ on entry:  sv3 <- buffer with block data to write to sd (schm bytevec)
	@ modifies:  sv5, rva, rvb, rvc
	bic	sv5, lnk, #lnkbit0
	swi	run_no_irq
	bl	sd_cfg			@ configure the spi interface
	bl	sd_sel			@ select sd
	@ put-cmd
	@ 1- get
	bl	sd_get
	@ 2- write write-single-block cmd for block in rvc
	set	rvb, #0x58
	bl	sd_put
	bic	rvc, rvc, #3
	lsr	rvb, rvc, #17
	bl	sd_put
	lsr	rvb, rvc, #9
	bl	sd_put
	lsr	rvb, rvc, #1
	bl	sd_put
	lsl	rvb, rvc, #7
	bl	sd_put
	set	rvb, #0xff 		@ put pseudo-crc
	bl	sd_put
	@ 3- wait for read-ready -- wait for non #xff response (desired: 0)
	set	rvc, #1
spbrdw:	@ wait loop
	bl	sd_get
	eq	rvb, #0xff
	bne	spbct1
	add	rvc, rvc, #1
	eq	rvc, #10
	bne	spbrdw
spbct1:	@ wait on zero read -- wait for #xff response following 0 response
	bl	sd_get
	eq	rvb, #0xff
	bne	spbct1
	@ write out the data
	set	rvb, #0xfe 		@ start token
	bl	sd_put
	set	rvc, #0
spbwlp:	@ write loop
	ldrb	rvb, [sv3, rvc]
	bl	sd_put
	add	rvc, rvc, #1
	eq	rvc, #0x0200
	bne	spbwlp
	@ write out pseudo-crc
	set	rvb, #0xff
	bl	sd_put
	set	rvb, #0xff
	bl	sd_put
	@ wait for write completion
	bl	sd_get
	set	rvc, #1
spbwt2:	@ wait loop
	bl	sd_get
	eq	rvb, #0
	bne	spbdon
	add	rvc, rvc, #1
	cmp	rvc, #(1 << 24)
	bmi	spbwt2
spbdon:	@ done	
	bl	sd_get
	@ return
	bl	sd_dsl			@ de-select sd
	swi	run_normal
	orr	lnk, sv5, #lnkbit0	@ lnk <- restored
	set	pc,  lnk

	
.endif
	
.ifdef sd_is_on_mci


_func_
sd_ini:	@ initialize SD card function (repeat manually on #f)
	@ on exit:	sv1 <- #t/#f for initialization success/failure
	@ modifies:	sv1, sv3, sv4, sv5, rva, rvb, rvc
	bl	sd_slo			@ 400KHz, 1-bit bus, CLK enabled
	@ go to idle state: CMD0, arg=0
	set	sv4, #i0
	set	rvc, #0
	bl	sdpcmd			@ go to idle state
	@ CMD55, arg=0
	set	sv4, #((55 << 2) | i0)
	set	rvc, #0
	bl	sdpcmd			@ CMD55
	@ get op-cond: CMD41, arg=0x40ff8000
	set	sv4, #((41 << 2) | i0)
	ldr	rvc, =0x40ff8000
	bl	sdpcmd			@ CMD41, get op-cond, expect #xff800
	@ CMD55, arg=0
	set	sv4, #((55 << 2) | i0)
	set	rvc, #0
	bl	sdpcmd			@ CMD55
	@ get op-cond: CMD41, arg=0x40ff8000
	set	sv4, #((41 << 2) | i0)
	ldr	rvc, =0x40ff8000
	bl	sdpcmd			@ CMD41, get op-cond, expect #xff800
	@ set CID: CMD2, arg=0, long response
	set	sv4, #((2 << 2) | i0)
	orr	sv4, sv4, #0x10000000
	set	rvc, #0
	bl	sdpcmd			@ CMD2, set CID (negative for long resp)
	@ get address: CMD3, arg=0
	set	sv4, #((3 << 2) | i0)
	set	rvc, #0
	bl	sdpcmd			@ CMD3, get address
	@ if get-address didn't work, exit with #f
	eq	rvb, #0
	itT	eq
	seteq	sv1, #f
	seteq	pc,  cnt
	@ save cRCA in sv1, sv2
	bic	rvc, rvb, #3
	orr	sv2, rvc, #i0
	raw2int	sv1, rvb
	@ send CSD: CMD9, arg=cRCA, long response
	set	sv4, #((9 << 2) | i0)
	orr	sv4, sv4, #0x10000000
	bic	rvc, sv2, #3
	orr	rvc, rvc, sv1, lsr #2
	bl	sdpcmd			@ CMD9, send CSD (negativ for long resp)
	@ select card: CMD7, arg=cRCA
	set	sv4, #((7 << 2) | i0)
	bic	rvc, sv2, #3
	orr	rvc, rvc, sv1, lsr #2
	bl	sdpcmd			@ CMD7, select card, expect #x700
	@ switch to fast mode, wide bus
	bl	sd_fst			@ set MCI to 9-25 MHz,wide bus,CLK enab
	@ CMD55, arg=cRCA
	set	sv4, #((55 << 2) | i0)
	bic	rvc, sv2, #3
	orr	rvc, rvc, sv1, lsr #2
	bl	sdpcmd			@ CMD55, short response, expect #x920
	@ set bus to 4-bits: CMD6, arg=0x02
	set	sv4, #((6 << 2) | i0)
	set	rvc, #0x02
	bl	sdpcmd			@ CMD6, set bus size to 4b, expect #x920
	@ set block length to 512: CMD16, arg=512
	set	sv4, #((16 << 2) | i0)
	set	rvc, #512
	bl	sdpcmd			@ CMD16, set 512B blk len, expect #x900
	@ build bytevector for cRCA (return value)
	mkvu84	sv4			@ sv4 <- #vu8(space-for-4-items)
	bic	rvc, sv2, #3
	orr	rvc, rvc, sv1, lsr #2
	str	rvc, [sv4]
	set	sv1, sv4
	@ return (sv1 contains cRCA as bytevector)
	set	pc,  cnt

.endif

_func_	
_snf:	@ _snf [internal only]
	@ sd-get-info internal func
	@ on entry:	sv1 <- (null . input-port-vector)
	@ on entry:	sv3 <- file name or other thing to store in info vector
	@ on exit:	sv2 <- preliminary file/fat16 info vector:
	@			#(sv3{eg. file name} _0_ root-dir-block cluster2-block _0_             _0_ 
	@			 blocks-per-cluster  _0_ fat-block      root-dir-block cluster2-block)
	@ on exit:	sv3 <- bytevector to use as data buffer (512 bytes)
	@ modifies:	sv2, sv3, sv5, rva, rvb, rvc
	@ returns via lnk
	bic	sv5, lnk, #lnkbit0
	@ allocate space for info vector
	set	rvb, #44
	bl	zmaloc
	set	rvc, #(11 << 8)
	orr	rvc, rvc, #vector_tag	@ rvc <- vector tag
	str	rvc, [rva, #-4]
	set	rvc, rvb
	set	sv2, #i0
_snfil:	subs	rvc, rvc, #4
	it	pl
	strpl	sv2, [rva, rvc]
	bpl	_snfil
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv2, rva, rvb		@ sv2 <- allocated block [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	vcsti	sv2, 0, sv3		@ set file name (original) into info vector
	vcsti	sv2, 4, sv4		@ save sv4 (eg. lnk of caller) in info vector temp space
	vcsti	sv2, 5, sv5		@ save lnk in info vector temp space
	@ allocate buffer
	set	rvb, #0x81
	lsl	rvb, rvb, #2
	bl	zmaloc
	set	rvc, #0x020000
	orr	rvc, rvc, #bytevector_tag	@ rvc <- bytevector tag
	str	rvc, [rva, #-4]
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv3, rva, rvb		@ sv3 <- allocated block [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	@	get block 0
	set	rvc, #i0
	bl	_sgb			@ sv3 <- block 0 data
	@ extract partition 0 block from data buffer
	set	rvc, #227
	lsl	rvc, rvc, #1
	ldrh	rva, [sv3, rvc]
	add	rvc, rvc, #2
	ldrh	rvb, [sv3, rvc]
	orr	rva, rva, rvb, lsl #16
	@ get partition 0 block
	lsl	rvc, rva, #2
	orr	sv4, rvc, #i0		@ sv4 <- partition 0 block number
	set	rvc, sv4
	bl	_sgb			@ sv3 <- partition 0 block data
	@ extract fat block, then root dir block, then cluster 2 block
	ldrb	rvc, [sv3, #13]
	lsl	rvc, rvc, #2
	orr	rvc, rvc, #i0 		@ rvc <-  blocks per cluster (scheme int)
	vcsti	sv2, 6, rvc 		@ save blocks per cluster in info vector
	ldrh	rva, [sv3, #14]
	add	sv4, sv4, rva, lsl #2 	@ sv4 <- fat block = partitin 0 block + # rsrvd sectrs (scheme int)
	vcsti	sv2, 8, sv4 		@ save fat block in info vector temp space
	ldrb	rva, [sv3, #16]
	ldrh	rvb, [sv3, #22]
	mul	rva, rvb, rva
	add	rvb, sv4, rva, lsl #2 	@ rvb <- root dir blk = fat blk + fat cpies*sect/fat (scheme int)
	ldrb	rva, [sv3, #17]
	ldrb	rvc, [sv3, #18]
	orr	rva, rva, rvc, lsl #8
	lsr	rva, rva, #4
	add	rva, rvb, rva, lsl #2 	@ rva <-  cluster 2 block = root + #root entries / 16 (scheme int)
	vcsti	sv2,  2, rvb
	vcsti	sv2,  3, rva
	vcsti	sv2,  9, rvb
	vcsti	sv2, 10, rva
	@ return
	vcrfi	sv4, sv2, 4		@ sv4 <- sv4, restored
	vcrfi	sv5, sv2, 5		@ sv5 <- lnk, restored
	set	rva, #i0
	vcsti	sv2, 4, rva
	vcsti	sv2, 5, rva
	orr	lnk, sv5, #lnkbit0
	set	pc, lnk

	PFUNC	1
qfilst:	@ FLST
	@ file-list:  list the files on the device
	@ for files in top directory of FAT16.
	@ file names are in 8.3 format (eg. "test.scm"), i.e. no long filenames.
	@ on entry:	sv1 <- (null . input-port-vector)
	@ on exit:	sv1 <- list of file names
	@ modifies:	sv2, sv3, sv4, sv5, rva, rvb, rvc
	@ returns via cnt
	@ get sd-card parameters
	bl	_snf	 	@ sv2 <- #(file name  _0_ root-dir-block cluster2-block _0_       _0_ 
	@				  blocks-per-cluster  _0_ fat-blk      root-dir-blk cluster2-blk)
	@			  sv3 <- buffer (512 bytes) (bytevector)
	@ build the file list
	set	sv4, #null
flslp0:	@ scan over directory blocks
	vcrfi	rvc, sv2, 2		@ rvc <- current block (from dir block to cluster 2 block)
	vcrfi	rva, sv2, 10		@ rva <- cluster 2 block (scheme int)
	eq	rva, rvc		@ are we at end of directory?
	beq	flsdon			@ 	if so,  jump to finish up
	add	rva, rvc, #4
	vcsti	sv2, 2, rva		@ store next directory block in info vector
	bl	_sgb			@ sv3 <- dir block data
	set	rvc, #-32		@ rvc <- offset to before first directory entry
flslp1:	@ process a directory block (512 bytes)
	add	rvc, rvc, #32		@ rvc <- offset of next directory entry
	tst	rvc, #0x0200		@ are we at end of this directory block?
	it	ne
	bne	flslp0			@ 	if so,  jump back to process next directory block
	ldrb	rva, [sv3, rvc]
	eq	rva, #0			@ is this the last entry in directory?
	it	eq
	beq	flsdon			@ 	if so,  jump to finish up
	@ check for deleted file or long file name (don't list those)
	eq	rva, #0xe5		@ is this a deleted file?
	itTT	ne
	addne	rva, rvc, #11		@	if not, rva <- offset to attributes field
	ldrbne	rva, [sv3, rva]		@	if not, rva <- file attributes
	eqne	rva, #0x0f		@	if not, is this a long file-name?
	beq	flslp1			@ 	if so,  jump back to process next directory entry
	@ dir entry found, get its file name into file-name list (sv4)
	orr	sv5, rvc, #i0		@ rvc <- dir entry offset (saved against _alo)
	set	rvb, #28		@ rvb <- 28 bytes to allocate (cons cell + string with <= 16 chars)
	bl	zmaloc
	add	rvc, rva, #8
	str	rvc, [rva, #-4]
	set	rvc, #0x1000
	orr	rvc, rvc, #string_tag
	stmia	rva, {sv4, rvc}
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv4, rva, #32		@ sv4 <- allocated block [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	bic	rvc, sv5, #i0		@ rvc <- dir entry offset (restored)
	@ copy file name into new string
	car	sv1, sv4		@ sv1 <- new string for file name
	set	rvb, #0			@ rvb <- initial char offset in target string
flslp2:	@ loop over characters
	and	rva, rvc, #0x0f		@ rva <- char offset in target string, including header
	eq	rva, #11		@ done copying file name?
	beq	flslp4			@	if so,  jump to adjust file name size
	eq	rva, #0x08		@ are we at start of file name extension?
	bne	flslp3			@	if not, jump to keep going
	ldrb	rva, [sv3, rvc]		@ rva <- first char of extension
	eq	rva, #32		@ is first char of extension a space?
	beq	flslp4			@	if so,  no extension, jump to adjust file name size
	set	rva, #'\.		@ rva <- dot
	strb	rva, [sv1, rvb]		@ store dot in file name in target string
	add	rvb, rvb, #1		@ rvb <- updated char offset in target string
flslp3:	@ keep going
	ldrb	rva, [sv3, rvc]		@ rva <- char from file name in directory entry
	eq	rva, #32		@ is char a space?
	itT	ne
	strbne	rva, [sv1, rvb]		@	if not, store char in string
	addne	rvb, rvb, #1		@	if not, rvb <- updated char offset in target string
	add	rvc, rvc, #1		@ rvc <- offset of next file name char in directory entry
	b	flslp2			@ jump back to continue copying file name chars
flslp4:	@ update file name (size, sub-dir) and go to next file
	bic	rvc, rvc, #0x0f		@ rvc <- offset to attributes part of file name
	orr	rvc, rvc, #0x0b		@ rvc <- offset to attributes part of file name
	ldrb	rva, [sv3, rvc]		@ rva <- attributes byte
	ands	rva, rva, #0x10		@ rva <- sub-dir bit, is this a sub-dir?
	beq	flslp5			@	if not, jump to continue
	set	rva, #'\/		@ rva <- slash character
	strb	rva, [sv1, rvb]		@ store sub-dir indicator (/) in file name string
	add	rvb, rvb, #1		@ rvb <- updated char offset in target string
flslp5:	@ keep going
	lsl	rvb, rvb, #8		@ rvb <- number of chars shifted
	orr	rvb, rvb, #string_tag	@ rvb <- full tag for file name string
	str	rvb, [sv1, #-4]		@ update file name string size tag
	bic	rvc, rvc, #0x0f		@ rvc <- start offset of current directory entry
	b	flslp1			@ jump back to process next directory entry
flsdon:	@ finish up
	set	sv2, #null
	set	sv3, sv2
	set	sv1, sv4
	@ return
	set	pc, cnt

_func_	
_nft:	@ get file name into fat16 format
	@ [internal only]
	@ on entry: sv4 <- file name string
	@ on exit:  sv1 <- file name string in FAT16 format
	@ modifies: sv1, sv5, rva, rvb, rvc
	bic	sv5, lnk, #lnkbit0 	@ sv5 <- lnk saved against toupcs
	set	rvb, #12
	bl	zmaloc
	set	rvc, #(11 << 8)
	orr	rvc, rvc, #string_tag
	str	rvc, [rva, #-4]
	set	rvc, #32 		@ rvc <- ascii space
	orr	rvc, rvc, rvc, lsl #8	@ rvc <- two  ascii spaces 	16-bits)
	orr	rvc, rvc, rvc, lsl #16	@ rvc <- four ascii spaces (32-bits)
	str	rvc, [rva]
	str	rvc, [rva, #4]
	str	rvc, [rva, #8]
	add	rva, rva, rvb		@ rva <- adrs of next fre cell lvl 2 rsv
	sub	sv1, rva, rvb		@ sv1 <- allocated block  [commit dest]
	orr	fre, rva, #0x02		@ de-reserve free-pointer [restart crit]
	ldr	rva, [sv4, #-4]
	lsr	rva, rva, #8
	cmp	rva, #13
	bpl	noequiv
	set	rvc, #-1		@ rvc <- ofst to befor 1st chr in filnam
befordot: @ process file name
	bl	fnfguc			@ rvb <- new chr frm src fnam,rvc <-ofst
	eq	rvb, #'.		@ is char a dot?
	beq	afterdot		@	if so,  jump to process file ext
	eq	rvc, #8			@ are we at 9th char with no dot found?
	beq	noequiv			@	if so,  jump to no equivalence
	strb	rvb, [sv1, rvc]		@ store char in target
	b	befordot		@ jump back to keep processing file name
afterdot: @ process file extension
	sub	rvb, rva, rvc		@ rvb <- num chars in extension + 1
	cmp	rvb, #5			@ are there 4 or more chrs in extension?
	bpl	noequiv			@	if so,  jump to no equiv case
	bl	fnfguc			@ rvb <- 1st ext chr in uprcase, if alph
	strb	rvb, [sv1, #8]		@ store char in target
	bl	fnfguc			@ rvb <- 2nd ext chr in uprcase, if alph
	strb	rvb, [sv1, #9]		@ store char in target
	bl	fnfguc			@ rvb <- 3rd ext chr in uprcase, if alph
	strb	rvb, [sv1, #10]		@ store char in target
fnexit:	@ normal exit
	orr	lnk, sv5, #lnkbit0
	set	pc,  lnk
noequiv: @ exit with no equivalence
	set	sv1, #i0
	b	fnexit

_func_
fnfguc:	@ get next char from source and convert to upper case, or exit if done
	@ on entry:	sv4 <- source file name string
	@ on entry:	rva <- length of file name string
	@ on entry:	rvc <- offset of previous char in file name
	@ on exit:	rvb <- char from file name, in upper case if alphabetic
	@ on exit:	rvc <- offset to returned char in file name
	@ modifies:	rvb, rvc
     	add	rvc, rvc, #1		@ rvc <- offset of char to get
     	cmp	rvc, rva		@ done getting chars?
	bpl	fnexit			@	if so,  jump to normal exit
     	ldrb	rvb, [sv4, rvc]		@ rvb <- char from source string
	@ convert to upper case, if alphabetic
	cmp	rvb, #'a
	it	mi
	setmi	pc,  lnk
	cmp	rvb, #'{
	it	mi
	bicmi	rvb, rvb, #32
	set	pc,  lnk

_func_	
_ffd:	@ find file in root directory
	@ [internal only]
	@ on entry: sv1 <- FAT16 8.3 file name string
	@ on entry: sv2 <- info vector, [2]=root-dir-block, [10]=cluster2-block
	@ on exit:  sv2 <- info vector, [2]=dir block after that containng fil nam (if fnd) or after target
	@ on exit:  sv3 <- 512B dir block data buffer containing file name (if found)
	@ on exit:  rvc <- offset of file entry in dir block + 15 (with header/tag) (if fnd) or 0 (not fnd)
	@ side-effects: contents of sv2 index 2
	@ modifies: sv3, sv4, sv5, rva, rvb, rvc
	bic	sv4, lnk, #lnkbit0 	@ sv4 <- lnk saved against _sgb
ffdlp0:	
     	vcrfi	rvc, sv2, 2		@ rvc <- directory block to examine next
     	vcrfi	rva, sv2, 10		@ rva <- cluster2-block (end of directory)
     	eq	rva, rvc		@ directory exhausted?
	it	eq
	seteq	rvc, #0x0200		@	if so,  rvc <- indicator for no room left in dir
	beq	ffdfnf			@ 	if so,  jump to exit (file not found)
     	add	rva, rvc, #4		@ rva <- next directory block to examine
     	vcsti	sv2, 2, rva		@ store next block to examine in info vector
     	bl	_sgb			@ sv3 <- dir block data (512 bytes)
	set	rvc, #-32		@ rvc <- offset to before first directory entry
ffdlp1:	
	add	rvc, rvc, #32		@ rvc <- offset of next directory entry
	tst	rvc, #0x0200		@ at end of dir-data block?
	bne	ffdlp0			@	if so,  jump back to process next block
	ldrb	rva, [sv3, rvc]		@ rva <- 1st character of dir entry
	eq	rva, #0			@ at end of directory?
	beq	ffdfnf			@ 	if so,  jump to exit (file not found)
	@ check for deleted file, long file name or directory (don't scan those)
	eq	rva, #0xe5		@ is this a deleted file?
	itTT	ne
	addne	rva, rvc, #11		@	if not, rva <- offset to attributes field
	ldrbne	rva, [sv3, rva]		@	if not, rva <- file attributes
	eqne	rva, #0x0f		@	if not, is this a long file-name?
	itT	ne
	andne	rva, rva, #0x10		@	if not, rva <- sub-dir bit
	eqne	rva, #0x10		@	if not, is this a sub-directory?
     	beq	ffdlp1			@	if so,  jump back to test next dir entry	
ffdlp2:	@ compare file name chars
	and	rvb, rvc, #0x0f		@ rvb <- offset into file name being searched for (incl. header)
	eq	rvb, #11		@ checked all file name chars and they match?
	beq	ffdxit			@ 	if so,  jump to exit (file found)
	ldrb	rva, [sv3, rvc]		@ rva <- character of dir entry
	ldrb	rvb, [sv1, rvb]		@ rvb <- character of target file name
	eq	rva, rvb		@ are chars the same?
	it	eq
	addeq	rvc, rvc, #1		@ 	if so,  rvc <- offset of next char
	beq	ffdlp2			@ 	if so,  jump back to compare next chars
	bic	rvc, rvc, #0x0f		@ rvc <- start offset of current dir entry
	b	ffdlp1			@ jump back to test next dir entry
ffdfnf:	@ exit for file not found
	set	rvb, rvc		@ rvb <- offset in sv3 of free dir entry, or #x0200 if dir full
     	set	rvc, #0			@ rvc <- 0 == file not found indicator
ffdxit:	@ normal exit
     	orr	lnk, sv4, #lnkbit0
     	set	pc,  lnk


	PFUNC	3
qfinfo:	@ find file and get its info
	@ for a file in top directory of FAT.
	@ file name is in 8.3 format (eg. "test.scm"), i.e. no long filenames.
	@ called with file system locked (chain: FNFO <- prtifi | prtofi <- opnife | opnofe)
	@ on entry:	sv1 <- (null . input-or-output-port-vector)
	@ on entry:	sv2 <- (null . input-or-output-port-vector) (symmetry of inbound call)
	@ on entry:	sv3 <- file name string
	@ on exit:	sv2 <- #(fname byte-in-file|#f0 file-size buffer|#f0 byte-in-block block-in-cluster
	@			 blocks-per-cluster file-cluster-list fat-blk root-dir-blk cluster2-block)
	@ on exit:	sv3 <- file name string in FAT16 format (caps with spaces)
	@ modifies:	sv2, sv4, sv5, rva, rvb, rvc
	@ returns via lnk
	bic	sv4, lnk, #lnkbit0 	@ sv4 <- lnk saved against _snf
	bl	_snf		 	@ sv2 <- #(file name      _0_ root-dir-blk cluster2-blk _0_  _0_ 
					@	  blks-per-clstr  _0_ fat-blk      root-dir-blk clstr2-blk)
					@ sv3 <- buffer (512 bytes)			(bytevector)
	vcsti	sv2, 4, sv1		@ sav (null . port model) in inf vec tmp
	vcsti	sv2, 5, sv4		@ sav lnk in info vector temp space
	set	rva, #null
	vcsti	sv2, 7, rva 		@ set file cluster list to '()
	@ convert file name to fat
	vcrfi	sv4, sv2, 0 		@ sv4 <- file name string
	bl	_nft 			@ sv1 <- FAT16-frmt fnam 8.3, 0 no equiv
	eq	sv1, #i0
	it	eq
	seteq	rva, #f0
	beq	fnfxt
	@ find file
	bl	_ffd			@ sv2 <- updtd inf vec [2]=blk aftr fnam
					@ sv3 <- dir block data
					@ rvc <- fil ntry ofst in dr blk +15 or0
	eq	rvc, #0			@ file not found?
	it	eq
	seteq	rva, #f0
	beq	fnfxt			@	if so,  go to file not found xit
	@ process the file-found case (fill-in the info vector)
	bic	rvc, rvc, #0x0f
	add	rvc, rvc, #28
	ldr	rva, [sv3, rvc]
	lsl	rva, rva, #2
	orr	rva, rva, #i0 		@ rva <- file size (scheme int)
	vcsti	sv2, 2, rva 		@ store file size in info vector
	@ build file blocks list (start blocks of file clusters)
     	set	sv4, #null
     	sub	rvc, rvc, #2
fnflop:	@ loop
     	ldrh	rva, [sv3, rvc]		@ rva <- start cluster of file (raw int)
     	set	rvb, #0xff
     	set	rvc, #0xf7
     	orr	rvb, rvc, rvb, lsl #8	@ rvb <- 0xfff7 = last cluster indicator
     	cmp	rvb, rva
     	bmi	fnfdon
     	sub	rvc, rva, #2
     	vcrfi	rvb, sv2, 6 		@ rvb <- number of blocks per cluster
     	lsr	rvb, rvb, #2
     	mul	rvc, rvb, rvc
     	vcrfi	rvb, sv2, 10		@ rvb <- cluster 2 block
     	add	sv1, rvb, rvc, lsl #2
     	lsl	rva, rva, #2
     	orr	sv5, rva, #i0
     	cons	sv4, sv1, sv4
     	set	sv1, sv5
     	lsr	rvc, sv1, #10
     	vcrfi	rvb, sv2, 8 		@ rvb <- fat block
	add	rvc, rvb, rvc, lsl #2
	bl	_sgb 			@ sv3 <- data from next block of fat
	and	rvc, sv1, #0x03fc
	lsr	rvc, rvc, #1
     	b	fnflop
fnfdon:	@ reverse the block list
     	set	sv5, #null
fnfrvl:	@ loop
     	nullp	sv4			@ done reversing block list?
     	beq	fnfxt0			@ 	if so,  jump to finish up
     	snoc	sv1, sv4, sv4
     	cons	sv5, sv1, sv5
	b	fnfrvl
fnfxt0:	@ finish up
     	vcsti	sv2, 7, sv5 		@ stor fil clstr strt blk lst in inf vec
	@ get 1st data block of file and store it in info vector
     	car	rvc, sv5
     	bl	_sgb 			@ sv3 <- dat frm dat block of fil, 512B
     	set	rva, #i0
fnfxt:	@ return
     	vcsti	sv2, 1, rva		@ byte-in-file <- 0 found, 0.0 not found
     	vcsti	sv2, 3, sv3 		@ store data buffer in info vector
     	vcrfi	sv3, sv2, 0		@ sv3 <- file name, restored
     	vcrfi	sv1, sv2, 4		@ sv1 <- (null . port model), restored
     	vcrfi	sv5, sv2, 5		@ sv5 <- lnk, restored
     	set	rva, #i0
     	vcsti	sv2, 4, rva		@ set byte-in-block    to 0
     	vcsti	sv2, 5, rva		@ set block-in-cluster to 0
     	orr	lnk, sv5, #lnkbit0
     	set	pc, lnk


	PFUNC	1
qflgc0:	@ _SG0 [internal only]
	@ file read-helper init function
	@ prepare to get one or more chars from file
	@ on entry:	sv1 <- ((fid #(fname page ofst ())) . port-vec)
	@ on exit:	sv2 <- #(fid page ofst) = fil start-stat partial copy
	@ on exit:	sv4 <- pointer to #(fname page offset ()) in full port
	@ preserves:	sv1, sv5
	@ modifies:	sv2, sv3, sv4, rva, rvb, rvc
	bic	sv3, lnk, #lnkbit0	@ sv3 <- lnk (saved against zmaloc)
	cadar	sv4, sv1		@ sv4 <- #(fnam bytinfil fsz bfr bytinblk blkinclstr
					@	   blksperclstr fclstrlst tmp tmp tmp)
	set	rvb, #44		@ rvb <- 44 = data bytes to cpy fil desc
	bl	zmaloc
	set	rvc, rvb
qfl0lp:	@
	subs	rvc, rvc, #4
	ldr	sv2, [sv4, rvc]
	str	sv2, [rva, rvc]
	bpl	qfl0lp
	add	rva, rva, rvb		@ rva <- adrs of nxt fre cell, lvl 2 rsv
	sub	sv2, rva, rvb		@ sv2 <- copd desc inf blk [commit dest]
	orr	fre, rva, #0x02		@ de-reserve free-pointer [restart crit]
	orr	lnk, sv3, #lnkbit0	@ lnk <- restored
	set	pc,  lnk


	PFUNC	4
qflgc1:	@ _SG1 [internal only]
	@ file read-helper getc function
	@ on entry:	sv1 <- ((port <reg> <n>) . port-vec) = full in port
	@ on entry:	sv2 <- value to preserve (eg. file desc partial copy)
	@ on entry:	sv4 <- file desc or its partial cpy (eg. for peek-)
	@ on entry:	sv5 <- value to preserve (eg. lnk of caller)
	@ on entry:	rvc <- value to preserve (eg. previous char read)
	@ on exit:	rvb <- ascii char read or eof (raw ascii char)
	@ on exit:	sv4 <- updated file descriptor (or its partial copy)
	@ preserves:	sv1, sv2, sv5, rvc (no zmaloc, no cons, no save)
	@ modifies:	sv3, sv4, rva, rvb
_func_
qfgc1e:	@ [internal entry]
	@ check if file was read to end
     	vcrfi	rva, sv4, 1 		@ rva <- byte in file (scheme int)
     	vcrfi	rvb, sv4, 2 		@ rvb <- size of file (scheme int)
     	cmp	rva, rvb 		@ file read to end?
	itT	pl
	setpl	rvb, #eof		@	if so,  rvb <- eof
	setpl	pc,  lnk		@	if so,  return
	@ update byte in file
     	add	rva, rva, #4
     	vcsti	sv4, 1, rva
	@ check if a new block needs loading
     	vcrfi	rva, sv4, 4 		@ rva <- byte in block (scheme int)
     	lsr	rvb, rva, #4 		@ rva <- byte in block / 4 (raw int)
     	cmp	rvb, #0x80 		@ not yet at end of 512-byte block?
     	bmi	qfgtc2			@      if so,  jump to get char
	@ prepare to load next block of file from SD card
     	vcsti	sv4, 8, sv5
     	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, almost saved
     	vcsti	sv4, 9, sv5
     	lsl	rvc, rvc, #2
     	orr	rvc, rvc, #i0
     	vcsti	sv4, 10, rvc
     	vcrfi	rvc, sv4, 5 		@ rvc <- block in cluster (scheme int)
     	add	rvc, rvc, #4 		@ rvc <- next block in cluster (sch int)
     	vcrfi	rvb, sv4, 6 		@ rvb <- blocks per cluster (scheme int)
     	cmp	rvc, rvb 		@ still within cluster?
     	bmi	qfgtc1			@      if so,  jump to keep going
     	vcrfi	sv3, sv4, 7 		@ sv3 <- cluster list
     	cdr	sv3, sv3 		@ sv3 <- rest of cluster list
     	vcsti	sv4, 7, sv3 		@ set updated cluster list in info vec
     	set	rvc, #i0 		@ rvc <- 0, block in cluster
qfgtc1:	@ load next block of file from SD card
     	vcsti	sv4, 5, rvc 		@ save updated block in cluster
     	vcrfi	sv3, sv4, 7 		@ sv3 <- cluster list
     	car	rvb, sv3 		@ rvb <- start block of current cluster
     	bic	rvc, rvc, #0x03
     	add	rvc, rvb, rvc		@ rvc <- new block to be read
     	vcrfi	sv3, sv4, 3 		@ sv3 <- buffer
     	bl	_sgb 			@ get new block data into buffer
     	vcrfi	rvc, sv4, 10
     	lsr	rvc, rvc, #2
     	vcrfi	sv5, sv4, 9
     	orr	lnk, sv5, #lnkbit0
     	vcrfi	sv5, sv4, 8
     	set	rva, #i0
     	vcsti	sv4, 4, rva 		@ set byte in block to 0
qfgtc2:	@ get char and update descriptor
     	vcrfi	sv3, sv4, 3 		@ sv3 <- buffer
     	vcrfi	rva, sv4, 4 		@ rva <- byte in block (scheme int)
     	int2raw rvb, rva		@ rvb <- byte in block (raw int)
     	ldrb	rvb, [sv3, rvb] 	@ rvb <- raw ascii char from buffer
     	add	rva, rva, #4
     	vcsti	sv4, 4, rva 		@ save next byte in block
	@ exit
     	set	rva, #i0
     	vcsti	sv4,  8, rva
     	vcsti	sv4,  9, rva
     	vcsti	sv4, 10, rva
     	set	pc,  lnk

	PFUNC	5
qflgc2:	@ _SG2 [internal only]
	@ file read-helper function finish-up
	@ extract string and update file descriptor function
	@ on entry:	sv1 <- ((port <reg> <n>) . port-vector) = full input port
	@ on entry:	sv2 <- initial file descriptor partial copy (start of string in flash)
	@ on entry:	sv4 <- updated file descriptor (end of string in flash)
	@ on exit:	sv1 <- string to be parsed or eof-char
	@ preserves:	sv5
	@ modifies:	sv1, sv2, sv3, sv4, rva, rvb, rvc
	@ identify number of bytes to get
     	vcrfi	rva, sv2, 1		@ rva <- start byte in file (scheme int)
     	vcrfi	rvb, sv4, 1		@ rvb <- end byte in file (scheme int)
     	subs	rvb, rvb, rva		@ rvb <- number of chars to read * 4 (raw int), is it zero?
	itTT	eq
	seteq	rvb, #(eof << 8)
	orreq	sv1, rvb, #char_tag
	seteq	pc,  lnk
	vcsti	sv4, 8, sv5		@ save sv5 in info vector
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, almost saved
	vcsti	sv4, 9, sv5		@ save lnk (via sv5) in info vector
	orr	sv1, rvb, #i0		@ sv1 <- number of chars to read, saved (scheme int)
	vcsti	sv4, 1, rva		@ set start byte back into file descriptor (to restart read)
	vcrfi	rva, sv2, 4		@ rva <- start byte in block  (scheme int)
	vcsti	sv4, 4, rva		@ set start byte in block back in descriptor
	vcrfi	rva, sv2, 5		@ rva <- starting block in cluster (scheme int)
	vcrfi	rvc, sv4, 5		@ rvc <- ending block in cluster (scheme int)
	vcsti	sv4, 5 ,rva		@ set starting block in cluster back in descriptor
	eq	rva, rvc		@ are starting and ending blocks the same? (set flag)
	vcrfi	sv3, sv4, 7		@ sv3 <- ending cluster list
	car	rvc, sv3		@ rvc <- ending cluster
	vcrfi	sv3, sv2, 7		@ sv3 <- starting cluster list
	car	rva, sv3		@ rva <- starting cluster
	vcsti	sv4, 7, sv3		@ set starting cluster list back in descriptor
	it	eq
	eqeq	rva, rvc		@      if so,  are start & end clstrs same? (if start/end blks are)
	beq	qrdxp1			@      if so,  jump to keep going
	@ re-get starting block data (rva is starting cluster)
	bic	rva, rva, #0x03
	vcrfi	rvc, sv4, 5		@ rvc <- starting block in cluster (scheme int)
     	add	rvc, rvc, rva		@ rvc <- block to be read
     	vcrfi	sv3, sv4, 3		@ sv3 <- buffer
     	bl	_sgb
	@ keep going (rvb is number of bytes to get)
qrdxp1:	
	int2raw	rvb, sv1		@ rvb <- number of chars to read (raw int)
	@ allocate target string
	bl	zmaloc
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv2, rva, rvb		@ sv2 <- free string for chars read [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	set	rva, #string_tag	@ rva <- full string tag for zero chars
	orr	rva, rva, sv1, lsl #6	@ rva <- full string tag with number of chars to get
	str	rva, [sv2, #-4]		@ store it in reserved memory block
	@ get characters from file into target string
	vcrfi	sv1, sv4, 9		@ sv1 <- lnk saved against _SG1 (_SG1 modifies temp space in sv4)
	vcrfi	sv5, sv4, 8		@ sv5 <- sv5, restored
	set	rvc, #0			@ rvc <- offest to 1st char
qrdxp4:	bl	qfgc1e			@ rvb <- raw char frm SD, sv4 <- page and offst updatd as needd
	strb	rvb, [sv2, rvc]		@ store it in target string
	strlen	rva, sv2
	add	rvc, rvc, #1		@ rvc <- offset of next char
	cmp	rvc, rva, lsr #2	@ done getting chars?
	bmi	qrdxp4			@	if not, jump to continue
	@ exit
	orr	lnk, sv1, #lnkbit0	@ lnk <- lnk, restored
	set	sv1, sv2		@ sv1 <- extracted string
	set	pc, lnk


	PFUNC	2
qflclo:	@ _fcl == pflclo
	@ file close-output-port sub-function
	@ on entry:	sv1 <- (<mode>), if non-null, close as input file (i.e. forget write-on-close)
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vector) = full output port
	@ on entry:	sv4 <- descriptor of file being closed, from open file list (from ffhofl)
	nullp	sv1			@ perform write-on-close?
  	bne	npofxt			@	if not, jump to exit
  	nullp	sv4			@ was file in open file list?
	beq	npofxt			@	if not, jump to exit
	cadar	sv4, sv4		@ sv4 <- #(fname page offset ())
	bl	flok			@ acquire file system lock
  	vcrfi	rva, sv4, 4		@ rva <- byte-in-block
  	eq	rva, #i0		@ partial block to write?
  	beq	fatwrt			@ 	if not, jump to update fat and dir entry
  	bl	_fwr			@ write last, partial, block of file
	@ update file-size for partial block
  	vcrfi	rvb, sv4, 1		@ rvb <- byte-in-file (scheme int)
	sub	rvb, rvb, #(1 << 11)	@ rvb <- file-size minus block size (scheme int)
  	vcrfi	rva, sv4, 4		@ rva <- byte-in-block
  	bic	rva, rva, #0x03
  	add	rvb, rvb, rva		@ rvb <- file-size (scheme int)
  	vcsti	sv4, 1, rvb		@ store file size in file info vector
fatwrt:	@ write fat link sequence in fat -- _spb
  	set	sv2, sv4		@ sv2 <- file info vector, for upcoming ops (eg. _nft, for _ffd)
  	vcrfi	sv4, sv2, 7		@ sv4 <- list of file cluster start blocks (starting with last)
  	nullp	sv4			@ no cluster list in this file (empty file)?
  	beq	dirwrt			@ 	if so,  jump to update directory entries
  	vcrfi	sv3, sv2, 3		@ sv3 <- 512B buffer (for _sgb, _spb)
	@ process last cluster
  	bl	getfatblock		@ sv3 <- fat block containing file cluster at start of sv4
					@ sv1 <- last cluster number (scheme int)
  	lsr	rva, sv1, #2		@ rva <- last cluster number (raw int)
	set	rvb, #(0xff << 8)	@ rvb <- last cluster of file indicator (partial)
	orr	rvb, rvb, #0xff		@ rvb <- last cluster of file indicator (complete)
  	and	rvc, rva, #0xff
  .ifdef cortex
  	strh	rvb, [sv3, rvc, lsl #1]	@ store next cluster link in fat bffr, at prev clstr entry (in rva)
  .else
	lsl	rvc, rvc, #1
  	strh	rvb, [sv3, rvc]		@ store next cluster link in fat bffr, at prev clstr entry (in rva)
  .endif
fatclop:	@ loop over other clusters
  	cdr	sv5, sv4		@ sv5 <- rest of cluster list
  	nullp	sv5			@ done processing cluster list?
  	beq	fatspb			@ 	if so,  jump to write updated fat block to sd-card
  	car	rvb, sv5		@ rvb <- start block of prev cluster of file (working backwards)
  	bl	blk2cl			@ rva <- cluster number (raw int) of block in rvb (scheme int)
  	lsr	rvb, sv1, #10		@ rvb <- block offset of fat clustr currently being updtd (raw int)
  	lsr	rvc, rva, #8		@ rvc <- block offset of fat cluster of previous cluster (raw int)
  	eq	rvb, rvc		@ are clusters in same fat block?
  	bne	fatspb			@ 	if not, jump to write updated fat block to sd-card
  	lsr	rvb, sv1, #2		@ rvb <- next cluster number (relative to previous cluster)
  	lsl	rvc, rva, #2		@ 
  	orr	sv1, rvc, #i0		@ sv1 <- next cluster (for next round) (scheme int)
  	and	rvc, rva, #0xff
  .ifdef cortex
  	strh	rvb, [sv3, rvc, lsl #1]	@ store next cluster link in fat bffr, at prev clstr entry (in rva)
  .else
	lsl	rvc, rvc, #1
  	strh	rvb, [sv3, rvc]		@ store next cluster link in fat bffr, at prev clstr entry (in rva)
  .endif
  	set	sv4, sv5
  	b	fatclop
fatspb:	@ write updated fat block to sd-card
	lsr	rva, sv1, #10		@ rva <- block of fat currently being updated (raw int)
	vcrfi	rvc, sv2, 8
  	add	rvc, rvc, rva, lsl #2	@ rva <- block of fat currently being updated (scheme int)
  	bl	_spb			@ write updated fat block to sd-card
	@ check if done, and, if not, start processing next needed cluster block of fat
  	cdr	sv5, sv4		@ sv5 <- rest of cluster list
  	nullp	sv5			@ done processing cluster list?
  	beq	fatwrt4			@ 	if so,  jump to continue
  	vcsti	sv2, 7, sv1		@ store next cluster in info vector
  	set	sv4, sv5
  	bl	getfatblock		@ sv3 <- fat block containing file cluster at start of sv4
					@ sv1 <- cluster number (scheme int)
  	lsr	rva, sv1, #2		@ rva <- cluster number (raw int)
  	vcrfi	rvb, sv2, 7		@ rvb <- next cluster (scheme int)
  	lsr	rvb, rvb, #2		@ rvb <- next cluster (raw int)
  	and	rvc, rva, #0xff
  .ifdef cortex
  	strh	rvb, [sv3, rvc, lsl #1]	@ store next cluster link in fat bffr, at prev clstr entry (in rva)
  .else
	lsl	rvc, rvc, #1
  	strh	rvb, [sv3, rvc]		@ store next cluster link in fat bffr, at prev clstr entry (in rva)
  .endif
  	b	fatclop			@ jump back to process this fat cluster block

	
getfatblock:	@ subroutine getfatblock
  	bic	rvc, lnk, #lnkbit0 	@ rvc <- lnk, saved
  	car	rvb, sv4
  	bl	blk2cl			@ rva <- cluster number (raw int) of block in rvb (scheme int)
  	orr	lnk, rvc, #lnkbit0 	@ lnk <- restored
  	lsl	rvb, rva, #2
  	orr	sv1, rvb, #i0
  	lsr	rva, sv1, #10
  	vcrfi	rvc, sv2, 8		@ rvb <- fat block
  	add	rvc, rvc, rva, lsl #2
  	b	_sgb			@ sv3 <- fat block containing file cluster, returns via lnk
	
_func_
blk2cl:	@ subroutine to get cluster number from block number
	@ rva <- cluster number (raw int) of block in rvb (scheme int)
  	vcrfi	rva, sv2, 10		@ rva <- start block of cluster 2 (scheme int)
  	sub	rva, rvb, rva		@ rva <- start block*4 relative to cluster 2 (raw int)
  	lsr	rva, rva, #2		@ rva <- start block relative to cluster 2 (raw int)
  	vcrfi	rvb, sv2, 6		@ rvb <- blocks per cluster (scheme int)
  	lsr	rvb, rvb, #2
blk2sh:	@ loop
	lsrs	rvb, rvb, #1
	it	ne
	lsrne	rva, rva, #1
	bne	blk2sh
	add	rva, rva, #2		@ rva <- start cluster of file (raw int)
	set	pc,  lnk
	
fatwrt4: @ continue
  	vcsti	sv2, 7, sv4		@ store last cluster (as list) in info vector
dirwrt:	@ write directory entry in dir
  	vcrfi	sv4, sv2, 0		@ sv4 <- file name
  	bl	_nft 			@ sv1 <- FAT16-formatted file name (8.3) or 0 if no equivalence
  	vcrfi	sv3, sv2, 3
  	vcrfi	rva, sv2, 9		@ rva <- root-dir block
  	vcsti	sv2, 2, rva		@ store root-dir-block at offset 2 (for _ffd)
  	bl	_ffd			@ sv2 <- updated info vector [2]=dir block after that for file name
					@ sv3 <- dir block data
					@ rvc <- ofst of fil ntry in dir blk (+15) (rawint) | 0 (filnotfnd)
					@ rvb <- file not fnd: ofst of fre ntry in dir blk (+ hdr) (rawint)
					@	 or #x0200 (dir full)
  	eq	rvb, #0x0200		@ dir full?
	it	ne
 	setne	rvc, rvb		@	if not, rvc <- offst of fre ntry in dir blk (+hdr) (rawint)
	bne	namwrt			@	if not, jump to continue
	bl	qfndfl			@ find a deleted file in dir to reclaim
	eq	rvc, #0x0200		@ no deleted file to reclaim?
	beq	opnfer			@	if so,  jump to report error
	bl	qfprg			@ purge delted file and its cluster list
	b	dirwrt			@ jump back to write dir entry to flash, using reclaimed space
namwrt:	@ copy file name into dir buffer
	and	rvb, rvc, #0x0f
	eq	rvb, #11
	itTT	ne
	ldrbne	rva, [sv1, rvb]
	strbne	rva, [sv3, rvc]
	addne	rvc, rvc, #1
	bne	namwrt
	@ copy file size into sv3 (dir block buffer)
	bic	rvc, rvc, #0x0f
	add	rvc, rvc, #28		@ rvc <- offset of file size in dir buffer (incl. header)
	vcrfi	rva, sv2, 1		@ rva <- file size (scheme int)
	lsr	rva, rva, #2		@ rva <- file size (raw int)
	str	rva, [sv3, rvc]		@ store file size in dir buffer
	@ copy 1st cluster of file into sv3 (dir block buffer)
	vcrfi	sv4, sv2, 7		@ sv4 <- start block of first file cluster (listed scheme int)
	nullp	sv4
	it	eq
	seteq	rva, #0
	beq	strwrt
	car	rvb, sv4		@ rvb <- start block of first file cluster (scheme int)
	bl	blk2cl			@ rva <- cluster number (raw int) of block in rvb (scheme int)
strwrt:	@ perform write
	sub	rvc, rvc, #2		@ rvc <- offset of file start cluster in dir buffer
	strh	rva, [sv3, rvc]		@ store start cluster of file in dir data buffer
	@ write updated dir to sd-card
	vcrfi	rvc, sv2, 2		@ rvc <- target dir block + 1 (scheme int)
	sub	rvc, rvc, #4		@ rvc <- target dir block (scheme int)
	bl	_spb			@ write updated dir block to sd-card
pflclx:	@ unlock the file system and exit
	bl	funlok
	b	npofxt

_func_
qfndfl:	@ find a deleted file in the root dir
	@ deleted dir-entries for normal file names are ok
	@ deleted entries for long file names are ok but start cluster will be 0 (file size 0)
	@ deleted sub-directory entries are skipped
  	vcrfi	rvc, sv2, 9
  	vcsti	sv2, 2, rvc		@ store dir start block in info vector, for scan
qfndf0:	@ loop over directory blocks
     	vcrfi	rvc, sv2, 2		@ rvc <- directory block to examine next
     	vcrfi	rva, sv2, 10		@ rva <- cluster2-block (end of directory)
     	eq	rva, rvc		@ directory exhausted?
	itT	eq
	seteq	rvc, #0x0200
	seteq	pc,  lnk
     	add	rva, rvc, #4		@ rva <- next directory block to examine
     	vcsti	sv2, 2, rva		@ store next block to examine in info vector
	bic	sv4, lnk, #lnkbit0 	@ sv4 <- lnk, saved
     	bl	_sgb			@ sv3 <- dir block data (512 bytes)
	orr	lnk, sv4, #lnkbit0
     	set	rvc, #0
qfndf1:	@ loop over directory entries in block
     	ldrb	rva, [sv3, rvc]		@ rva <- 1st character of dir entry
	eq	rva, #0xe5		@ is this a deleted file?
	bne	qfndf5			@	if not, jump to loop back
	add	rva, rvc, #11		@ rva <- offset to file attributes
	ldrb	rva, [sv3, rva]		@ rva <- file attributes
	tst	rva, #0x10		@ is it a deleted sub-directory?
	it	eq
	seteq	pc,  lnk		@	if not, return (deleted file found)
qfndf5:	@ loop back
     	add	rvc, rvc, #32		@ rvc <- start offset of next dir entry
     	tst	rvc, #0x0200		@ at end of dir-data block?
     	bne	qfndf0			@	if so,  jump back to process next block
     	b	qfndf1			@ jump back to test next dir entry

_func_
qfprg:	@ purge a file's directory entry and its cluster list in fat
	@ on exit:	sv4 <- 0 (scheme int) if no clusters were purged
	add	rva, rvc, #26
	ldrh	rva, [sv3, rva]
	raw2int	sv4, rva		@ sv4 <- deleted file's start cluster (scheme int)
	vcrfi	rva, sv2, 2
	vcsti	sv2, 2, sv4
	set	sv4, rva		@ sv4 <- deleted file's directory block + 1 (scheme int)
	add	rvb, rvc, #32
	set	rva, #0
qfprg0:	@ erase file directory entry in buffer
	str	rva, [sv3, rvc]
	add	rvc, rvc, #4
	eq	rvc, rvb
	bne	qfprg0
	@ update directory block in flash
	sub	rvc, sv4, #4
	bic	sv4, lnk, #lnkbit0 	@ sv4 <- lnk, saved
     	bl	_spb			@ write updated block to file
	orr	lnk, sv4, #lnkbit0
	@ update fat (based on start cluster in sv2[2])
	vcrfi	sv4, sv2, 2		@ sv4 <- deleted file's start cluster (scheme int)
	eq	sv4, #i0		@ was this an empty file?
	beq	qfprgx			@	if so,  jump to skip cluster clearing in fat
	@ clear file clusters from fat
	bic	sv5, lnk, #lnkbit0 	@ sv5 <- lnk, nearly saved
	vcsti	sv2, 2, sv5		@ save lnk in info vector
qfprcl:	@ acquire fat block for cluster
	lsr	rvc, sv4, #10		@ rvc <- file cluster offset in fat (raw int)
     	vcrfi	rvb, sv2, 8 		@ rvb <- fat block (scheme int)
	add	rvc, rvb, rvc, lsl #2	@ rvc <- fat block where file cluster is (for _sgb)
     	bl	_sgb 			@ sv3 <- data from fat block containing cluster in sv4
	lsr	rvc, sv4, #10		@ rvc <- file cluster offset in fat (raw int)
     	vcrfi	rvb, sv2, 8 		@ rvb <- fat block (scheme int)
	add	sv5, rvb, rvc, lsl #2	@ sv5 <- fat block where file cluster is (saved for upcoming _spb)
qfprc0:	@ loop over file clusters to clear within this fat block
	int2raw	rvc, sv4
     	and	rvc, rvc, #0xff
	lsl	rvc, rvc, #1
	ldrh	rva, [sv3, rvc]		@ rva <- next cluster of file (raw int)
	set	rvb, #0
	strh	rvb, [sv3, rvc]		@ clear next cluster of file, in buffer
	lsr	rvc, sv4, #10		@ rvc <- previous cluster's offset in fat
	raw2int	sv4, rva		@ sv4 <- next cluster of file (scheme int)
     	ldr	rvb, =0xfff7		@ rvb <- last cluster indicator
     	cmp	rva, rvb		@ is this the last cluster?
	bpl	qfprc1			@	if so,  jump to write updated fat block to card
	lsr	rvb, sv4, #10		@ rvb <- next cluster's offset in fat
	eq	rvb, rvc		@ is next cluster in same fat block as previous cluster?
	beq	qfprc0			@	if so,  jump back to process next cluster
qfprc1:	@ write updated (cleared) fat block to flash
	set	rvc, sv5		@ rvc <- fat block where file cluster(s) is (for _spb)
	bl	_spb			@ write updated fat block to flash
	int2raw	rva, sv4		@ rva <- cluster to visit next (raw int)
     	ldr	rvb, =0xfff7		@ rvb <- last cluster indicator
     	cmp	rva, rvb		@ done visiting clusters?
	bmi	qfprcl			@	if not, jump back to clear next clusters
	@ restore link
	vcrfi	sv5, sv2, 2		@ sv5 <- lnk, nearly restored
	orr	lnk, sv5, #lnkbit0	@ lnk <- lnk, restored
qfprgx:	@ return
	set	pc,  lnk


_func_
_ffr:	@ _ffr
	@ find a free cluster in which to write a file's data buffer
	@ called with file system locked (chain: _ffr <- _fwr <- pflptc <- {pputs} <-  pflwrc)
	@ modifies:	sv2, sv3, sv4[2], sv5, rva-rvc
	bic	sv2, lnk, #lnkbit0 	@ sv2 <- lnk, saved
	@ allocate buffer for fat reading
	set	rvb, #0x81
	lsl	rvb, rvb, #2
  	bl	zmaloc
	set	rvc, #0x020000
	orr	rvc, rvc, #bytevector_tag @ rvc <- bytevector tag
	str	rvc, [rva, #-4]
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv3, rva, rvb		@ sv3 <- allocated block [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	orr	lnk, sv2, #lnkbit0 	@ lnk <- restored
	@ find a free cluster and add it to file cluster list
	vcrfi	rvc, sv4, 8		@ rvc <- FAT block
	vcsti	sv4, 2, rvc		@ store fat block in info vector, for scan
fatblockloop:	
	vcrfi	rvc, sv4, 2
	vcrfi	rva, sv4, 9
	cmp	rvc, rva		@ scanned the whole fat?
	itT	pl
	setpl	rvc, #0			@ 	if so,  rvc <- 0 (no free cluster)
	setpl	pc,  lnk		@ 	if so,  return with no free cluster indicator
	add	rva, rvc, #4
	vcsti	sv4, 2, rva
	bic	sv2, lnk, #lnkbit0 	@ sv2 <- lnk, saved
	bl	_sgb			@ sv3 <- contents of fat block
	orr	lnk, sv2, #lnkbit0 	@ lnk <- restored
	set	rvb, #0x0200
fatloop: @
	subs	rvb, rvb, #2
	bmi	fatblockloop
	ldrh	rva, [sv3, rvb]
	eq	rva, #0
	bne	fatloop
	@ calculate start block for cluster in this fat entry
	vcrfi	rvc, sv4, 2
	sub	rvc, rvc, #4		@ rvc <- fat block with free cluster (scheme int)
	vcrfi	rva, sv4, 8		@ rva <- fat block (scheme int)
	sub	rvc, rvc, rva		@ rvc <- cluster*8 (raw int)
	lsl	rvc, rvc, #6		@ rvc <- cluster*512 (raw int)
	add	rvc, rvc, rvb, lsr #1	@ rvc <- possible free cluster (raw int)
	sub	rvc, rvc, #2		@ rvc <- possible free cluster, relative to cluster 2 (raw int)
	vcrfi	rva, sv4, 6		@ rva <- blocks-per-cluster (scheme int)
	lsr	rva, rva, #2
	mul	rvc, rva, rvc		@ rvc <- start block of poss. free clstr, rel. to clstr 2 (raw int)
	vcrfi	rva, sv4, 10		@ rva <- cluster-2 block (scheme int)
	add	rvc, rva, rvc, lsl #2	@ rvc <- start block of poss. free cluster (scheme int)
	@ check for this cluster's start block on the open file list
	vcrfi	sv2, glv, 6		@ sv2 <- open file list
filelistloop:	
	nullp	sv2			@ done scanning open file list
	it	eq
	seteq	pc,  lnk		@ 	if so,  return with start-block of free cluster in rvc
	caar	sv5, sv2		@ sv5 <- (handle #(fname ...))
	cadr	sv5, sv5		@ sv5 <- #(fname ...)
	ldr	rva, [sv5, #-4]		@ sv5 <- tag of file info vector
	lsr	rva, rva, #8		@ rva <- size of file info vector (raw int)
	eq	rva, #11		@ is this a sd-file info vector (size = 11)?
	bne	nextfile		@	if not, jump to scan rest of open file list
	@ check open sd-file's cluster list
	vcrfi	sv5, sv5, 7		@ sv5 <- file's cluster list
fileclusterloop:
	nullp	sv5			@ done scanning cluster list?
	beq	nextfile		@	if so,  jump to scan rest of open file list
	car	rva, sv5		@ rva <- cluster (in use) from cluster list
	eq	rva, rvc		@ is this the possible free cluster (i.e. cluster in use)?
	beq	fatloop			@	if so,  jump back to try a different free cluster
	cdr	sv5, sv5		@ sv5 <- rest of cluster list for this file
	b	fileclusterloop		@ jump back to scan rest of file's cluster list
nextfile:	
	cdr	sv2, sv2		@ sv2 <- rest of open file list
	b	filelistloop		@ jump back to scan rest of open file list


_func_	
_fwr:	@ _fwr == fwrfla
	@ write buffer to flash, 
	@ called with file system locked (chain: _fwr <- pflptc <- {pputs} <- pflwrc)
	@ on entry:	sv4 <- file descriptor
	@ on entry:	rvb <- char to be written to file next (to be saved, restored)
	@ on entry:	rvc <- lnk of caller (to be saved, restored)
	@ uses:		sv2, rva, rvb
	@ uses:		68 bytes of user-stack space
	@ identify file ID and block number for buffer
	stmdb	sp!, {rvb, rvc, lnk}	@ store scheme registers onto stack
	save3	sv2, sv3, sv5
	vcrfi	rva, sv4, 5		@ rva <- block-in-cluster (scheme int)
	eq	rva, #i0
	bne	sdwr5
sdwr2:	@ find a free cluster (if any) for file data
	bl	_ffr			@ rvc <- start block of free cluster on SD card, or 0 if none
	eq	rvc, 0			@ free space available?
	bne	sdwr4			@	if so,  jump to continue
	swap	sv2, sv4, sv5
	bl	qfndfl			@ find a deleted file in dir to reclaim
	eq	rvc, #0x0200		@ no deleted file to reclaim?
	beq	sdwr3			@	if so,  jump to return with no room indicator
	bl	qfprg			@ purge delted file and its cluster list
	swap	sv2, sv4, sv5
	b	sdwr2
sdwr3:	@ absolutely no space left
	swap	sv2, sv4, sv5
	set	rva, 0			@ rva <- 0 (no room left indicator)
	b	sdwrxt			@ jump to exit		
sdwr4:	@ free cluster found, add it to the file's cluster list in info vector
	set	sv3, rvc
	vcrfi	sv5, sv4, 7
	cons	sv5, sv3, sv5
	vcsti	sv4, 7, sv5
sdwr5:	@ write data to block in file cluster
	vcrfi	sv3, sv4, 7 		@ sv3 <- cluster list
	car	rvb, sv3 		@ rvb <- start block of current cluster (scheme int)
	vcrfi	rvc, sv4, 5		@ rvc <- block-in-cluster (scheme int)
	bic	rvc, rvc, #0x03
	add	rvc, rvb, rvc		@ rvc <- destination block for write (scheme int)
	vcrfi	sv3, sv4, 3		@ sv3 <- buffer to write
	bl	_spb			@ write buffer to sd-card [modifies sv3, sv5, rva-rvc]
	@ update block-in-cluster
	vcrfi	rva, sv4, 5		@ rva <- block-in-cluster (scheme int)
	add	rva, rva, #4
	vcrfi	rvb, sv4, 6		@ rvb <- blocks per cluster (scheme int)
	cmp	rva, rvb
	it	pl
	setpl	rva, #i0
	vcsti	sv4, 5, rva		@ store updated block-in-cluster in info vector
	@ update byte-in-file
	vcrfi	rva, sv4, 1		@ rva <- byte-in-file (scheme int)
	add	rva, rva, #(1 << 11)
	vcsti	sv4, 1, rva
sdwrxt:	@ exit
  	restor3	sv2 sv3 sv5
  	ldmia	sp!, {rvb, rvc, lnk}
  	set	pc,  lnk


	PFUNC	2
qflptc:	@ _ptc == pflptc
	@ file putc sub-sub-function
	@ called with file system locked (chain: pflptc <- {pputs} <- pflwrc)
	@ on entry:	sv1 <- scheme char or string to write out
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vec) = full out port
	@ on entry:	sv3 <- saved lnk from caller of caller
	@ on entry:	sv4 <- file descriptor
	@ on entry:	sv5 <- saved lnk from caller
	@ on entry:	rvb <- ascii char to write + ofst of char in string
	@ on exit:	sv4 <- updated file descriptor
	@ preserves:	sv1, sv2, sv3, sv5, rvb
	@ modifies:	sv4, rva, rvc
	@ does buffer need to be written to flash?
  	vcrfi	rva, sv4, 4		@ rva <- byte-in-block (scheme int)
  	asr	rvc, rva, #2		@ rvc <- byte-in-block (raw int)
  	cmp	rvc, #512		@ byte-in-block larger than page size?
  	bmi	bfrupd
  	bic	rvc, lnk, #lnkbit0	@ rvc <- lnk, saved against fwrfla
  	bl	_fwr
  	orr	lnk, rvc, #lnkbit0	@ lnk <- restored 
  	eq	rva, #0			@ did write fail (if _fwr was called)?
	it	eq
  	seteq	pc,  lnk		@	if so,  return
  	set	rva, #i0		@ rva <- byte-in-block for char in rvb
bfrupd:	@ write char in rvb to buffer in file descriptor sv4
	add	rvc, rva, #4		@ rvc <- updated byte-in-block
	vcsti	sv4, 4, rvc		@ store updatd byte-in-block in fil desc
	set	rvc, sv5		@ rvc <- saved lnk from caller, free sv5
	vcrfi	sv5, sv4, 3		@ sv5 <- buffer (scheme vec, gc-eable)
	lsr	rva, rva, #2		@ rva <- offset, incl. header (raw int)
	strb	rvb, [sv5, rva]		@ store character in buffer
	set	sv5, rvc		@ sv5 <- lnk from caller, restored
	set	pc,  lnk		@ return


	PFUNC	3
qfilers: @ _fer == filers
	@ erase an existing file before writing to it (pseudo-erasure where old
	@ file is invalidated) and, prepare output buffer contents
	@ called with file system locked (chain: _fer <- prtfrs <- opnofe)
	@ on entry:	sv1 <- (null . input-or-output-port-vec)
	@ on entry:	sv2 <- (null . input-or-output-port-vec) (sym inbnd cal)
	@ on entry:	sv4 <- #(fname           byte-in-file|#f0  file-size
	@			buffer 	         byte-in-block     blk-in-clstr
	@			blocks-per-clstr file-clstr-lst    fat-block      
	@			root-dir-block   cluster2-block)
	@ on entry:	sv3 <- buffer (empty) {also referenced by sv4}
	@ modifies:	sv2, sv3, sv5, rva, rvb, rvc
	@ updates:	sv4 (page updated to 0, scheme int)
	@ returns via lnk
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved (made even if T2)
  	vcrfi	rvb, sv4, 1		@ rvb <- #i0=file found, #f0=not found
  	eq	rvb, #f0		@ file not found?
  	beq	flersx			@	if so,  jump to continue
	@ erase an exiting file
  	save3	sv4, sv1, sv5		@ save registers against _nft and _ffd
  	vcrfi	sv4, sv4, 0		@ sv4 <- file name (for _nft)
  	bl	_nft 			@ sv1 <- FAT16-formatted file name (8.3)
  	car	sv2, dts		@ sv2 <- file info vector (for _ffd)
  	vcrfi	rva, sv2, 9		@ rva <- root-dir block
  	vcsti	sv2, 2, rva		@ store root-dir-blk at ofst 2, for _ffd
  	bl	_ffd			@ sv2 <- updtd info vec [2]=dir blk aftr
	@				  sv3 <- dir block data
	@       	 	 	  rvc <- ofst of file in dir blk (+ 15)
	bic	rvb, rvc, #0x0f
	set	rva, #0xe5
	strb	rva, [sv3, rvb]
	vcrfi	rvc, sv2, 2		@ rvc <- dir blk after fnam to erase
	sub	rvc, rvc, #4		@ rvc <- dir blk w/fnam to erase
	bl	_spb			@ overwrite dir block with file name
	restor3	sv4, sv1, sv5		@ restore saved registers
	@ initialize file info vector and return
flersx:	@
	set	rva, #null
	vcsti	sv4, 7, rva 		@ set file cluster list to '()
	set	rva, #i0
	vcsti	sv4, 1, rva		@ set byte-in-file     to 0
	vcsti	sv4, 2, rva		@ set file size        to 0
	vcsti	sv4, 4, rva		@ set byte-in-block    to 0
	vcsti	sv4, 5, rva		@ set block-in-cluster to 0
	orr	lnk, sv5, #lnkbit0	@ lnk <- restored
	set	pc,  lnk		@ return


.endif	@  onboard_SDFT

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.1. ports SUPPORT 2:	flok,funlok,ffind,ffhofl,fnewhd,fclose,fwrfla
@-------------------------------------------------------------------------------


_func_	
flok:	@ acquire the file system lock
	eor	fre, fre, #0x03		@ fre <- ...bbb01	(reserv level 1)
	ldr	rvb, =BUFFER_START
flokwt:	vcrfi	rva, rvb, FILE_LOCK
	eq	rva, #0
	bne	flokwt
	bic	rva, fre, #0x03
	vcsti	rvb, FILE_LOCK, fre	@ reserve the file system, [commit rsrv]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [restart crt]
	set	pc,  lnk		@ return
	
_func_	
funlok:	@ release the file system lock
	set	rva, #0			@ rva <- 0, files unlocked indicator
	ldr	rvb, =BUFFER_START
	vcsti	rvb, FILE_LOCK, rva	
	set	pc,  lnk		@ return


_func_	
ffhofl:	@ return the file descriptor of a file that is on the open file list
	@ also return pointer to file list
	@ on entry:	sv2 <- file ID/handle
	@ on exit:	sv4 <- file descriptor or null if file not on list
	@ on exit:	sv2 <- open-file-list link to curr desc (for fil close)
	@ on exit:	sv3 <- open-file-list after current desc (for fil close)
	@ modifies:	sv2, sv3, sv4, rva, rvb
	set	rvb, sv2
	set	sv2, #null
	vcrfi	sv3, glv, 6		@ sv3 <- list of open files frm glbl vec
ffhof0:	nullp	sv3			@ done scanning open file list?
	itT	eq
	seteq	sv4, sv3		@	if so,  sv4 <- '()
	seteq	pc,  lnk		@	if so,  jump to exit
	car	sv4, sv3		@ sv4 <- open file descr
	caar	sv4, sv4		@ sv4 <- handle
	eq	sv4, rvb		@ is this the handle to acquire?
	itT	ne
	setne	sv2, sv3		@	if not, sv2 <-ptr to prv opn fil
	cdrne	sv3, sv3		@ 	if not, sv3 <-remnng opn fil lst
	bne	ffhof0			@	if not, scan remndr opn fil lst
	car	sv4, sv3		@ sv4 <- open file descr
	cdr	sv3, sv3		@ sv3 <- remaining open files list
	set	pc,  lnk		@ return sv4-descr,sv2-prels,sv3-postls
	

@-------------------------------------------------------------------------------
@   III.A.2. FILE system crunching
@
@	File system crunch for small memory and regular MCUs
@-------------------------------------------------------------------------------

.ifndef	live_SD

_func_	
pgsctr:	@ on entry:	sv2{r5} <- start address of flash page of which sector is sought
	@ on exit:	rva{r2} <- flash sector number in which page is found (raw int)
	@ modifies:	rvb{r3}
	set	rva, #0
pgsct0:	ldr	rvb, =flashsectors
	ldr	rvb, [rvb, rva, LSL #2]
	cmp	sv2, rvb
	itT	mi
	submi	rva, rva, #1
	setmi	pc,  lnk		@ return
	add	rva, rva, #1
	b	pgsct0

.ifdef	LIB_TOP_PAGE
		
_func_	
lbsctr:	@ on entry:	sv2{r5} <- start address of flash page of which lib sector is sought
	@ on exit:	rva{r2} <- flash sector number in which page is found (raw int)
	@ modifies:	rvb{r3}
	set	rva, #0
lbsct0:	ldr	rvb, =lib_sectors
	ldr	rvb, [rvb, rva, LSL #2]
	cmp	sv2, rvb
	itT	mi
	submi	rva, rva, #1
	setmi	pc,  lnk		@ return
	add	rva, rva, #1
	b	lbsct0

.endif

	
_func_
mkfdsc:	@ build a new (output) file descriptor
	@ on exit:	sv4 <- new extended file descriptor (5 items vs 4 in normal descriptor)
	@ modifies:	sv4, rva, rvb, rvc
	@ returns via:	lnk
	bic	sv4, lnk, #lnkbit0	@ sv4 <- lnk, saved (and made even if Thumb2)
	set	rvb, #F_PAGE_SIZE	@ rvb <- flash page size (bytes)
	add	rvb, rvb, #28		@ rvb <- size of block to allocate for file descriptor + buffer
	bl	zmaloc			@ rva <- address of free block
	set	rva, #0x0500		@ rva <- number of items in vector (5, shifted)
	orr	rva, rva, #vector_tag	@ rva <- vector tag for file descriptor
	str	rva, [fre, #-1]		@ store vector tag in file descriptor
	set	rva, #i0		@ rva <- 0 (scheme int)
	str	sv4, [fre, #3]		@ store lnk (sv4) in file descriptor (for gc and to restore lnk)
	str	rva, [fre, #7]		@ store 0 in file descriptor (for gc)
	str	rva, [fre, #11]		@ store 0 in file descriptor (for gc)
	str	rva, [fre, #19]		@ store 0 in file descriptor (for gc)
	add	rva, fre, #27		@ rva <- address of buffer (8-byte aligned)
	str	rva, [fre, #15]		@ store buffer address in file descriptor
	set	rva, #(F_PAGE_SIZE << 8) @ rva <- flash page size (bytes)
	orr	rva, rva, #bytevector_tag @ rva <- bytevector tag for buffer
	str	rva, [fre, #23]		@ store tag in buffer
	add	rva, fre, #3		@ rva <- address of start of file descriptor + buffer
	add	rva, rva, rvb		@ rva <- address of next free cell
	sub	sv4, rva, rvb		@ sv4 <- file descriptor [* commit destination*]
	orr	fre, rva, #0x02		@ fre <- next free cell [* de-reserve memory*]
	vcrfi	lnk, sv4, 0
	set	rva, #i0
	vcsti	sv4, 0, rva
	orr	lnk, lnk, #lnkbit0	@ lnk <- lnk, restored
	set	pc,  lnk		@ return

_func_
ff1del:	@ find 1st flash page with pseudo-erased file
	@ on exit:	sv2 <- 1st flash page with pseudo-erased file
	@ on exit:	rva <- 0 if no pseudo-erased file found
	@ modifes:	sv2, rva, rvb, rvc
	@ returns via:	lnk
	ldr	sv2, =F_START_PAGE
	sub	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- address of previous page
	set	rva, #0			@ rva <- 0 (raw int), default return value indicating flash full
	vcrfi	rvb, glv, 11		@ rvb <- address of end of file flash (crunch space)
	bic	rvb, rvb, #i0
fcrnlp:	add	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- address of next page
	cmp	sv2, rvb		@  is page >= end page (flash is completely full)?
	it	pl
	setpl	pc,  lnk		@	if so,  return rva=0 (raw int) - no pseudo-deleted file
	tbrfi	rvc, sv2, 0		@ rvc <- word 0 from potential deleted page in flash
	mvns	rvc, rvc
	beq	fcrnlp
	mvn	rvc, rvc
	and	rvc, rvc, #0xff		@ rvc <- byte 0 of potential deleted page
	eq	rvc, #0xfd		@ is this page in use?
	beq	fcrnlp			@	if so,  jump to scan next page
	set	rva, #1			@ rva <- 1 (indicates a pseudo-deleted page was found)
	set	pc,  lnk		@ return
	
_func_
fcsdel:	@ erase crunch space if needed
	@ modifies:	sv2, rva
	vcrfi	sv2, glv, 11		@ sv2 <- flash crunch space address (pseudo scheme int)
	bic	sv2, sv2, #i0		@ sv2 <- flash crunch space address
	ldr	rva, [sv2]		@ rva <- 1st word in crunch space
	mvns	rva, rva		@ rva <- inverted 1st word, is it zero (erased)?
	bne	ersfla			@	if not, jump to erase extra flash sector, return via lnk
	set	pc,  lnk		@ return

_func_
flshcp:	@ copy from source FLASH page(s) to destination FLASH page(s) (if src wasn't deltd or is lib)
	@ on entry:	rva <- source      start page
	@ on entry:	rvb <- source      end   page
	@ on entry:	rvc <- destination start page
	@ on entry:	sv4 <-	special output file descriptor:
	@			#(____________  _______________ caller-tmp-storage  buffer  ______________)
	@ on exit:	sv4 <-	updated special output file descriptor:
	@			#(src-end-page  dest-end-page   caller-tmp-storage  buffer  src-end-page)
	@ modifies:	sv2, sv4, rva, rvb, rvc
	@ returns via:	lnk
	@ Note:		sector of 1st dest page is erased if 1st word in 1st dest page is not #xffffffff
	@ Note:		erased source pages (corresponding to erased files) are not copied
	@ Note:		copy is from:	src-start-page <= flash-page < src-end-page
	@ Note:		this routine switches mode to run_no_irq and back to run_normal
	@ side-effects:	the open-file list (glv, 6) is updated with page destination addresses
	@		if a copied page is in the open-file list.
	vcsti	sv4, 4, rva		@ store source      start page in pseudo-file-descriptor
	vcsti	sv4, 0, rvb		@ store source      end   page in pseudo-file-descriptor
	vcsti	sv4, 1, rvc		@ store destination start page in pseudo-file-descriptor
	set	sv2, rvc		@ sv2 <- destination start page
	set	rvc, lnk		@ rvc <- lnk, saved
	ldr	rva, [sv2]		@ rva <- 1st word in destination start page
	mvns	rva, rva		@ is destination start page erased?
	beq	fcrnc1			@	if so,  jump to skip destination sector erasure
.ifndef	LIB_TOP_PAGE
	bl	ersfla			@ jump to erase destination sector
.else
  .ifdef SHARED_LIB_FILE
	bl	ersfla			@ jump to erase destination sector
  .else
	adr	lnk, fcrnc1
	ldr	rvb, =LIB_BOTTOM_PAGE
	cmp	sv2, rvb
	ldr	rvb, =LIB_TOP_PAGE
	cmppl	rvb, sv2
	bmi	ersfla
	b	libers
  .endif
.endif
	@ at this point: sv4 <-	special output file descriptor:
	@			#(src-end-page  dest-start-page caller-tmp-storage  buffer  src-start-page)
_func_
fcrnc1:	@ copy from source FLASH page in [sv4, 4] to target FLASH page in [sv4, 1] (if src wasn't deltd)
	vcrfi	sv2, sv4, 4		@ sv2 <- source page address
	vcrfi	rvb, sv4, 0		@ rvb <- address after end page
	cmp	sv2, rvb		@ done writing?
	it	pl
	setpl	pc,  rvc		@	if so,  return
	
.ifndef	LIB_TOP_PAGE
	tbrfi	rva, sv2, 0		@ rva <- 1st word of FLASH page
	and	rva, rva, #0xff		@ rva <- lower byte of 1st word
	eq	rva, #0xfd		@ is this a valid file (not deleted)?
	bne	fcrnc5			@	if not, (deleted page) skip copying to extra FLASH
.else
	vcrfi	rvb, glv, 12		@ rvb <- possible lib space bottom address
	nullp	rvb			@ any lib to check against?
	beq	flshc3			@	if not, jump to check for valid file
	@ check if source is a lib page
	cmp	sv2, rvb
	ldr	rva, =LIB_TOP_PAGE
	it	pl
	cmppl	rva, sv2
	bpl	flshc4			@	if so,  skip checking for file validity
	@ check if destination is a lib page
	vcrfi	rva, sv4, 1
	cmp	rva, rvb
	ldr	rvb, =LIB_TOP_PAGE
	it	pl
	cmppl	rvb, rva
	bpl	flshc4			@	if so,  skip checking for file validity

flshc3:	@ copying from file space, check if we're copying a valid file page (i.e. non-deleted)
	tbrfi	rva, sv2, 0		@ rva <- 1st word of FLASH page
	and	rva, rva, #0xff		@ rva <- lower byte of 1st word
	eq	rva, #0xfd		@ is this a valid file (not deleted)?
	bne	fcrnc5			@	if not, (deleted page) skip copying to extra FLASH
flshc4:	@ continue
.endif

	bl	fpgcpy			@ copy data from source FLASH page to destination FLASH page
	bl	foflup			@ update open-file list (if source page address is on that list)
	@ update target FLASH page address
	vcrfi	sv2, sv4, 1		@ sv2 <- target FLASH page adddress
	add	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- address of next FLASH page in target sector (next target)
	vcsti	sv4, 1, sv2		@ store it back in RAM file descriptor
fcrnc5:	@ update source FLASH page address
	vcrfi	sv2, sv4, 4		@ sv2 <- source FLASH page address
	add	sv2, sv2, #F_PAGE_SIZE	@ sv2 <- address of next FLASH page in source sector (next source)
	vcsti	sv4, 4, sv2		@ store it back in non-heap RAM
	b	fcrnc1			@ jump to copy next page to extra FLASH

_func_
fpgcpy:	@ copy a flash page from src to dest (both in FLASH)
	@ on entry:	sv4 <-	special output file descriptor:
	@			#(caller-tmp-storage  dest-page  caller-tmp-storage  buffer  src-page)
	@ modifes:	sv2, rva, rvb
	@ returns via:	lnk
	vcrfi	sv2, sv4, 3		@ sv2 <- buffer's address
	set	rvb, #0			@ rvb <- 0, initial offset
fpgcp0:	cmp	rvb, #F_PAGE_SIZE	@ are we done copying?
	itTTT	mi
	vcrfimi	rva, sv4, 4		@	if not, rva <- source page address
	ldrmi	rva, [rva, rvb]		@	if not, rva <- data word from FLASH source
	strmi	rva, [sv2, rvb]		@	if not, store data word into target RAM buffer
	addmi	rvb, rvb, #4		@	if not, rvb <- offset in target
	bmi	fpgcp0			@	if not, jump to keep copying
	@ write non-heap RAM to target FLASH page
	vcrfi	sv2, sv4, 1		@ sv2 <- target FLASH page address
.ifndef	LIB_TOP_PAGE
	b	wrtfla			@ write data to target FLASH, return to caller via lnk
.else
  .ifdef SHARED_LIB_FILE
	b	wrtfla			@ write data to target FLASH, return to caller via lnk
  .else
	ldr	rvb, =LIB_BOTTOM_PAGE
	cmp	sv2, rvb
	ldr	rvb, =LIB_TOP_PAGE
	cmppl	rvb, sv2
	bmi	wrtfla
	b	libwrt
  .endif
.endif

.endif	@  live_SD

		
_func_
foflup:	@ update open-file list (if source page address is on that list)
	@ on entry:	sv4 <-	special output file descriptor:
	@			#(caller-tmp-stor  dest-page  caller-tmp-stor  caller-tmp-stor  src-page)
	@ modifes:	sv2, rva, rvb
	@ returns via:	lnk
	@ Note:		this routine switches mode to run_no_irq and back to run_normal
	@ side-effects:	the open-file list (glv, 6) is updated with page address dest-page
	@		wherever it conatains page-address src-page.
	swi	run_no_irq		@ disable interrupts (user mode)
	vcrfi	rva, glv, 6		@ rva <- open-files list
foflu0:	
	nullp	rva			@ done updating addresses?
	beq	foflu1			@	if so,  jump to continue
	car	rvb, rva		@ rvb <- 1st file descriptor
	@
	@ possible bug:
	@
	@ with possible external file systems and their open file descriptors stored
	@ on open-file list, it may be necessary to check first that this descriptor
	@ is for an on-chip file (before getting/checking the page address) here.
	@
	@ workaround:	do not use when external-file-port files are open (a bit too limiting though)
	@
	vcrfi	rvb, rvb, 1		@ rvb <- page address from descriptor
	vcrfi	sv2, sv4, 4		@ sv2 <- source page address
	eq	sv2, rvb		@ does this page descriptor include this page address?
	itTT	eq
	careq	rvb, rva		@	if so,  rvb <- file descriptor
	vcrfieq sv2, sv4, 1		@	if so,  sv2 <- target address in extra flash=new page adrs
	vcstieq rvb, 1, sv2		@	if so,  store new page address in file descriptor
	cdr	rva, rva		@ rva <- rest of open-files list
	b	foflu0			@ jump to continue updating page addresses in open-files list
foflu1:	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return
	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

@-------------------------------------------------------------------------------
@
@	I2C INPUT/OUTPUT PORT and ISR
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input SUPPORT 4  - i2c input  port:	i2cipr, pi2rdy, pi2red
@  II.A.6.6.3. output SUPPORT 4 - i2c output port:	i2copr, pi2wrt
@-------------------------------------------------------------------------------

.ifdef	include_i2c

	PFUNC	0
lnkfxt:	@ return via lnk
	set	pc, lnk

	PFUNC	2
pi2rdy:	@ char-ready? function for i2c input port
	@ on entry:	sv1 <- ((<port> <reg> <n>) . port-vector) = full input port
	@ on exit:	sv1 <- #t/#f indicating port char-ready status
	@ modifies:	sv1, sv2, sv3, sv4, sv5, rva, rvb, rvc
	@ returns via cnt
	car	sv1, sv1		@ sv1 <- full input port
	snoc	sv1, sv2, sv1		@ sv1 <- port,		sv2 <- (<reg> <n> ...)
	lsr	rva, sv1, #2		@ rva <- port base address without upper two bits
	lsl	sv1, rva, #4		@ sv1 <- full port base address
	ldr	rvb, =i2c0_base
	eq	rvb, sv1		@ is port i2c0?
	itE	eq
	ldreq	sv5, =I2C0BUFFER	@	if so,  sv5 <- address of i2c0buffer
	ldrne	sv5, =I2C1BUFFER	@	if not, sv5 <- address of i2c1buffer
	tbrfi	rvb, sv5, 1		@ rvb <- data ready status from i2cbuffer[4]
	eq	rvb, #t			@ is i2c data ready?
	b	boolxt

.ifndef	exclude_read_write
		

	PFUNC	2
pi2red:	@ read function for i2c input port
	@ on entry:	sv1 <- ((<port> <reg> <n>) . port-vector) = full input port
	@ on exit:	sv1 <- object read
	@ modifies:	sv1, sv2, sv3, sv4, sv5, rva, rvb, rvc
	@ returns via cnt
	car	sv1, sv1		@ sv1 <- full input port
	snoc	sv1, sv2, sv1		@ sv1 <- port,		sv2 <- (<reg> <n> ...)
	nullp	sv2			@ is (<reg> ...) unspecified (reading as slave)?
	itE	eq
	seteq	sv3, sv2		@	if so,  sv3 <- '() (n is not specified either)
	snocne	sv2, sv3, sv2		@	if not, sv2 <- <reg>,		sv3 <- (<n> ...)
	lsr	rva, sv1, #2		@ rva <- port base address without upper two bits
	lsl	sv1, rva, #4		@ sv1 <- full port base address
	ldr	rvb, =i2c0_base
	eq	rvb, sv1		@ is port i2c0?
	itE	eq
	ldreq	sv5, =I2C0BUFFER	@	if so,  sv5 <- address of i2c0buffer
	ldrne	sv5, =I2C1BUFFER	@	if not, sv5 <- address of i2c1buffer
	nullp	sv2			@ are we reading as slave (i.e. <reg> = '())?
	beq	i2crde			@	if so, jump to process that
	@ reading as master, first write-out mcu-id and registers
i2crd0:	@ wait for i2c channel to be free
	swi	run_no_irq		@ disable interrupts
	tbrfi	rvb, sv5, 0		@ rvb <- status of i2c channel
	eq	rvb, #f			@ is i2c channel not busy?
	beq	i2crd1			@	if so, jump to continue
	swi	run_normal		@ re-enable interrupts
	b	i2crd0			@ jump to keep waiting
i2crd1:	@ write target mcu address and number of additional address bytes (if any) in i2c buffer[0,4]
	vcrfi	rvb, sv2, 0		@ rvb <- mcu-id (1st element of reg-vector)	
	tbsti	rvb, sv5, 0		@ store i2c write address in i2cbuffer[0]
	veclen	rvb, sv2		@ rvb <- additional number of address bytes + 1 (scheme int)
	sub	rvb, rvb, #4		@ rvb <- additional number of address bytes (scheme int)
	tbsti	rvb, sv5, 1		@ store addtnl num of address bytes in i2cbuffer[4] (dat not ready)
	eq	rvb, #i0		@ no registers specified?
	beq	i2crd3			@	if so,  (no reg) jump to initiate read transfer	
	@ write additional address bytes (if any) in i2c buffer[8] (backwards)
	set	rva, #0x21		@ rva <- 12, offset to byte in reg-vector (scheme int)
	add	sv4, rvb, #0x20		@ sv4 <- additional number of address bytes (scheme int)
i2crd2:	eq	sv4, #0x21		@ are we done writing additional address bytes?
	beq	i2crd4
	wrdref	rvb, sv2, rva		@ 	if not, rvb <- next address byte from reg-vec (scheme int)
	lsr	rvb, rvb, #2		@	if not, rvb <- next address byte (raw int)
	sub	sv4, sv4, #4		@	if not, sv4 <- addrss byt offst in i2cbuffr[8] (scheme int)
	bytsetu	sv5, sv4, rvb		@	if not, store address byte in i2cbuffer[8+offset]
	add	rva, rva, #0x10		@	if not, rva <- nxt offst to addrss byt in rgvc (scheme int)
	b	i2crd2			@	if not, jump to store next additional address byte
i2crd4:	@ initiate i2c write of registers
	set	rva, sv1		@ rva <- port address
	bl	hwi2cr			@ initiate i2c read, as master, (write internal address registers)
i2crd3:	@ start/re-start data transfer (for reading)
	tbrfi	rvb, sv5, 0		@ rvb <- mcu write address from i2cbuffer[0]
	eor	rvb, rvb, #3		@ rvb <- mcu read address as scheme pseudo float)
	tbsti	rvb, sv5, 0		@ store i2c read or write address in i2cbuffer[0]
	@ set number of bytes to receive
	nullp	sv3			@ is there an unspecified number of bytes to receive?
	itEE	eq
	seteq	rvb, sv3		@	if so,  rvb <- '()
	carne	sv3, sv3		@	if not, sv3 <- n
	lsrne	rvb, sv3, #2		@	if not, rvb <- number of bytes to receive (raw int)
	tbsti	rvb, sv5, 3		@ store number of bytes to receive in i2c buffer[12]
	swi	run_normal		@ re-enable interrupts
	set	rva, sv1		@ rva <- port address
	bl	hwi2ni			@ initiate transfer
i2crde:	@ wait for i2c data to be ready
	swi	run_no_irq		@ disable interrupts
	tbrfi	rvb, sv5, 1		@ rvb <- data ready status from i2cbuffer[4]
	eq	rvb, #t			@ is i2c data ready?
	beq	i2crdf			@	if so, jump to continue
	swi	run_normal		@ re-enable interrupts
	b	i2crde			@ jump to keep waiting
i2crdf:	@ get data
	ldr	rvb, =i2c0_base		@ rvb <- i2c0 base address
	eq	rvb, sv1		@ is port i2c0?
	set	rvb, #null		@ rvb <- '()
	itTEE	eq
	vcrfieq sv1, glv, 2		@	if so,  sv1 <- object received in glv for i2c0
	vcstieq glv, 2, rvb		@	if so,  store '() in glv (for gc)
	vcrfine sv1, glv, 3		@	if not, sv1 <- object received in glv for i2c1
	vcstine glv, 3, rvb		@	if not, store '() in glv (for gc)
	tbrfi	rva, sv5, 4		@ rva <- number of bytes received
	cmp	rva, #5			@ were more than 4 bytes received?
	bpl	i2crxt			@	if so,  jump to exit
	eq	rva, #4			@ were exactly 4 bytes received?
	it	eq
	tbrfieq sv1, sv5, 2		@	if so,  sv1 <- object received
	beq	i2crxt			@	if so,  jump to exit
	add	rvb, rva, #7		@ rvb <- address of last byte received (i2cbuffer[8 to 10])
	ldrb	rva, [sv5, #8]		@ rva <- MSB byte from i2cbuffer[8]
	strb	rva, [sv5, #11]		@ store MSB in i2cbuffer[11]
	ldrb	rva, [sv5, rvb]		@ rva <- last byte received (LSB)
	strb	rva, [sv5, #8]		@ store LSB in i2cbuffer[8]
	ldrb	rva, [sv5, #11]		@ rva <- MSB back from i2cbuffer[11]
	strb	rva, [sv5, rvb]		@ store MSB at position of last byte received
	ldr	rva, [sv5, #8]		@ rva <- raw data with extraneous upper byte
	bic	rva, rva, #0xFF000000	@ rva <- data
	lsl	rva, rva, #2		@ rva <- data, shifted
	orr	sv1, rva, #int_tag	@ sv1 <- data (scheme int)
i2crxt:	@ exit
	set	rva, #f
	tbsti	rva, sv5, 1		@ store #f (data not ready)   in i2cbuffer[4]
	tbsti	rva, sv5, 0		@ store #f (channel not busy) in i2cbuffer[0]
	swi	run_normal		@ re-enable interrupts
	pntrp	sv1			@ did we receive a packed item?
	it	eq
	seteq	sv2, #null		@	if so,  sv2 <- '() == unpack to heap
	beq	unpack			@	if so,  sv1 <- unpacked-object, return via cnt
	set	pc,  cnt

.endif

.ifndef	exclude_read_write


	PFUNC	2
pi2wrt:	@ i2c output port write sub-function
	@ write scheme item in sv1 to i2c port in sv2
	@ on entry:	sv1 <- object
	@ on entry:	sv2 <- ((port target n ...) . port-vector) = full output port
	pntrp	sv1
	bne	puti2r
	@ pack object in r1 before sending it out through i2c
	sav_rc	sv2			@ dts <- (full-output-port cnt ...)
	list	sv1, sv1		@ sv1 <- (object)
	call	pack
	restor2	sv2, cnt		@ sv2 <- full output port, cnt <- cnt, dts <- (...)
puti2r:	@ continue
	car	sv2, sv2		@ sv2 <- (port target n ...)
	snoc	sv2, sv3, sv2		@ sv2 <- port,		sv3 <- (target n ...)
	lsr	rva, sv2, #2		@ rva <- port base address without upper two bits
	lsl	sv2, rva, #4		@ sv2 <- full port base address
	ldr	rvb, =i2c0_base		@ rvb <- address of i2c base port #0
	eq	rvb, sv2		@ is port i2c0?
	itE	eq
	ldreq	sv5, =I2C0BUFFER	@	if so,  sv5 <- address of i2c0buffer
	ldrne	sv5, =I2C1BUFFER	@	if not, sv5 <- address of i2c1buffer
i2cwr0:	@ wait for i2c channel to be free
	swi	run_no_irq		@ disable interrupts
	tbrfi	rvb, sv5, 0		@ rvb <- status of i2c channel
	eq	rvb, #f			@ is i2c channel not busy?
	beq	i2cwr1			@	if so, jump to continue
	swi	run_normal		@ re-enable interrupts
	b	i2cwr0			@ jump to keep waiting
i2cwr1:	@ write object to send in global vector
	ldr	rvb, =i2c0_base
	eq	rvb, sv2		@ is port i2c0?
	itE	eq
	vcstieq glv, 2, sv1		@	if so,  store object in glv, for i2c0, to support gc
	vcstine glv, 3, sv1		@	if not, store object in glv, for i2c1, to support gc
	@ write target mcu address and number of additional address bytes (if any) in i2c buffer[0,4]
	nullp	sv3			@ is (<reg> ...) unspecified (writing as slave)?
	itE	eq
	seteq	sv4, sv3		@	if so,  sv4 <- '() (n is not specified either)
	snocne	sv3, sv4, sv3		@	if not, sv3 <- target,	sv4 <- (n ...)
	nullp	sv3			@ are we writing as slave (i.e. <reg> = '())?
	itE	eq
	seteq	rvb,  sv3		@	if so,  rvb <- '()
	vcrfine rvb, sv3, 0		@	if not, rvb <- mcu-id (1st element of reg-vector)
	tbsti	rvb, sv5, 0		@ store mcu-id/null in i2cbuffer[0] (indicates channel now busy)
	itE	eq
	seteq	rvb, #i0		@	if so,  rvb <- 0 (scheme int) additnl num of address bytes
	veclenne rvb, sv3		@	if not, rvb <- additnl num of addrss bytes + 1 (scheme int)
	it	ne
	subne	rvb, rvb, #4		@	if not, rvb <- additnl number of address bytes (scheme int)
	tbsti	rvb, sv5, 1		@ store addtnl num of address bytes in i2cbuffer[4] (dat not ready)
	@ write additional address bytes (if any) in i2c buffer[8] (backwards)
	set	sv1, #0x21		@ sv1 <- 12, offset to byte in reg-vector (scheme int)
	add	rva, rvb,  #0x20	@ rva <- additional number of address bytes (scheme int)
i2cwr2:	eq	rva, #0x21		@ are we done writing additional address bytes?
	beq	i2cwr4
	wrdref	rvb, sv3, sv1		@ 	if not, rvb <- next address byte from reg-vec (scheme int)
	lsr	rvb, rvb, #2		@	if not, rvb <- next address byte (raw int)
	sub	rva, rva, #4		@	if not, rva <- addrss byt offst in i2cbuffr[8] (scheme int)
	bytsetu	sv5, rva, rvb		@	if not, store address byte in i2cbuffer[8+offset]
	add	sv1, sv1, #0x10		@	if not, sv1 <- nxt offst to addrss byt in rgvc (scheme int)
	b	i2cwr2			@	if not, jump to store next additional address byte
i2cwr4:	@ write number of bytes to send in i2c buffer[12]
	nullp	sv4			@ is number of bytes to send, <n>, unspecified?
	itT	ne
	carne	sv4, sv4		@	if not, sv4 <- n
	lsrne	rvb, sv4, #2		@	if not, rvb <- number of bytes to send (raw int)
	bne	i2cwr3			@	if not,  jump to store it in i2c buffer[12]
	ldr	rvb, =i2c0_base		@ rvb <- i2c0 port address
	eq	rvb, sv2		@ is port i2c0?
	itE	eq
	vcrfieq sv1, glv, 2		@	if so,  sv1 <- object in glv for i2c0
	vcrfine sv1, glv, 3		@	if not, sv1 <- object in glv for i2c1
	pntrp	sv1			@ is object a pointer?
	itE	ne
	setne	rvb,  #4		@	if not, rvb <- 4 bytes to send (raw int)
	vecleneq rvb, sv1		@	if so,  rvb <- number of bytes in object (scheme int)
	itT	eq
	lsreq	rvb, rvb, #2		@	if so,  rvb <- number of bytes in object (raw int)
	addeq	rvb, rvb, #4		@	if so,  rvb <- number of bytes to send (raw int)
i2cwr3:	tbsti	rvb, sv5, 3		@ store number of bytes to send in i2c buffer[12]
	@ initiate i2c write (if writing as master) and exit
	swi	run_normal		@ re-enable interrupts
	tbrfi	rvb, sv5, 0		@ rvb <- mcu-id/null
	nullp	rvb			@ are we writing as slave?
	itT	ne
	setne	rva, sv2		@	if not, rva <- port address (raw)
	blne	hwi2ni			@	if not, jump to hw-specific write-as-master inittn routine
	b	npofxt

.endif


@-------------------------------------------------------------------------------
@  II.I.7. I2C ISR:			pi2isr
@-------------------------------------------------------------------------------


pi2isr:	@ I2C ISR -- not completed for this new version
	@
	@ If gc was interrupted, glv may not be valid
	@    => need to test for memory reservation state early on
	@
	@
	@ see if memory transaction or gc was interrupted
	str	rvb, [sp,  #-12]
	ldmia	sp!, {fre}
	tst	fre, #0x02		@ was memory reserved?
	it	eq
	bleq	genism			@	if so,  jump to deal with that (restart or go-through)
	stmdb	sp!, {fre}
	ldr	rvb, [sp,  #-12]
	@ see if interrupt requires zmaloc
	eq	rvb, #i2c0_int_num
	itE	eq
	ldreq	rva, =i2c0_base		@	if so,  rva <- I2C0 base address
	ldrne	rva, =i2c1_base		@	if not, rva <- I2C1 base address
	bl	hwi2st			@ rvb <- i2c status	(rva remains i2c base address)
	ldr	lnk, =i2c0_base
	eq	rva, lnk
	itE	eq
	ldreq	lnk, =I2C0BUFFER
	ldrne	lnk, =I2C1BUFFER
	eq	rvb, #i2c_irm_rcv	@ is status: Receiving as Master with new data received?
	it	ne
	eqne	rvb, #i2c_irs_rcv	@	if not, is status Receiving as Slave with new dat received?
	itT	eq
	tbrfieq lnk, lnk, 4		@	if so, lnk <- number of data bytes received before this one
	eqeq	lnk, #7			@	if so, were 7 bytes received before this one?
	beq	i2c_maloc		@		if so, jump to allocate Heap memory for object
	@ interrupt doesn't require zmaloc, keep going
	stmdb	sp!, {sv1-sv5}		@ store user mode registers on irq stack
	@ identify i2c channel
	set	sv3, rva		@ sv3 <- i2c[0/1] relevant base address for this interrupt
	ldr	rva, =i2c0_base
	eq	sv3, rva
	itTEE	eq
	seteq	sv1, #12		@	if so,  sv1 <- 12 == offset in glv for I2C0 object
	ldreq	sv2, =I2C0BUFFER	@	if so,  sv2 <- i2c0 buffer address
	setne	sv1, #16		@	if not, sv1 <- 16 == offset in glv for I2C1 object
	ldrne	sv2, =I2C1BUFFER	@	if not, sv2 <- i2c1 buffer address
	bl	i2c_hw_branch
	b	i2cxit

i2c_wm_ini:	@ Writing as Master -- slave has acknowledged address (I2STAT = 0x18)
	bl	gldon
	set	rva, #0			@ rva <- 0 = number of bytes sent
	tbsti	rva, sv2,  4		@ store number of bytes sent (0)
	b	i2c_wm_put
	
i2c_wm_put:	@ Writing as Master -- slave ready to receive data  (I2STAT = 0x28)
	bl	i2putp			@ prologue:	write additional address bytes if needed
	bl	i2putc			@ write data
	bl	i2pute			@ epilogue:	set completion status if needed
	b	i2cxit			@ exit isr
	
i2c_wm_end:	@ Writing as Master -- completed, exit (I2STAT = 0x58)
	set	rvb, #f			@ rvb <- #f
	tbsti	rvb, sv2,  1		@ set data ready to #f
	str	rvb, [glv, sv1]		@ set source object to #f in glv (released for gc)
	bl	hwi2we			@ set channel busy status/stop bit at end of write as master
	bl	gldoff
	b	i2cxit			@ exit isr

i2c_rm_ini: @ Reading as Master -- slave has acknowldgd address (I2STAT = 0x40, set nak if need just 1 byt)
	bl	yldon
	set	rva, #i0		@ rva <- 0 (scheme int)
	tbsti	rva, sv2,  2		@ store 0 as data received so far
	set	rva, #0			@ rva <- 0
	tbsti	rva, sv2,  4		@ store 0 as number of bytes received
	b	i2rmxt

i2c_rm_get: @ Reading as Master, new byte received
	bl	i2getc
i2rmxt: @ exit when reading as master
	tbrfi	rva, sv2,  4		@ rva <- number of bytes read so far
	tbrfi	rvb, sv2,  3		@ rvb <- number of bytes to read
	nullp	rvb			@ undefined number of bytes to read?
	bne	i2rmx1			@	if not, jump to see if there's only 1 byte left to read
	eq	rva, #1			@ have we received just one byte?
	bne	i2cxit			@	if not, exit
	ldrb	rva, [sv2, #8]		@ rva <- byte received
	and	rva, rva, #0xFF		@ rva <- lower 8 bits of byte received (whole byte really)
	eq	rva, #bytevector_tag	@ are we reading a sized object?
	itT	ne
	setne	rva, #4			@	if not, rva <- 4 (number of bytes to read)
	tbstine rva, sv2,  3		@	if not, store 4 as number of bytes to read
	b	i2cxit			@ exit

i2rmx1:	@ set stop bit/other ending parms, if needed
	sub	rvb, rvb, rva		@ rvb <- number of bytes remaining to read
	eq	rvb, #1			@ only one byte left?
	it	eq
	bleq	i2cstp			@	if so,  jump to end or prepare to end transfer
	b	i2cxit

i2c_rm_end:	@ Reading as Master -- last byte received (I2STAT = 0x58)
	bl	i2getc
	bl	hwi2re			@ set stop bit if needed
	b	i2c_rs_end

i2c_ws_ini:	@ Writing as Slave -- address recognized as mine (I2STAT = 0xA8)
	bl	gldon
	tbrfi	rva, sv2, 0		@ rva <- channel-busy status
	eq	rva, #f			@ is channel free?
	itTTT	eq
	seteq	rva, #i0		@	if so,  rva <- 0 (scheme int)
	tbstieq rva, sv2, 0		@	if so,  store 0 (scheme int) as channel-busy
	tbstieq rva, sv2, 1		@	if so,  store 0 (scheme int) as data-not-ready/#addrss-byts
	ldreq	rva, =eof_char		@	if so,  rva <- eof-character
	itTT	eq
	streq	rva, [glv, sv1]		@	if so,  store eof-character as object to send
	seteq	rva, #4			@	if so,  rva <- 4 (raw int) = number of bytes to send
	tbstieq rva, sv2, 3		@	if so,  store 4 as number of bytes to send
	set	rva, #0x00		@ rva <- 0 = number of bytes sent
	tbsti	rva, sv2, 4		@ store number of bytes sent (0)
	b	i2c_ws_put

i2c_ws_put:	@ Writing as Slave -- master requests byte (I2STAT = 0xB8)
	bl	i2putc
	b	i2cxit			@ exit isr

i2c_ws_end:	@ Writing as Slave -- NAK received from master - i.e. done (I2STAT = 0xC0)
	set	rvb, #f			@ rvb <- #f
	tbsti	rvb, sv2, 0		@ set channel-busy to #f
	bl	gldoff
	b	i2cxit

i2c_rs_ini:	@ Receiving as Slave -- address recognized as mine (I2STAT = 0x60)
	bl	yldon
	set	rva, #0			@ rva <- 0
	tbsti	rva, sv2, 2		@ store 0 as data received so far
	tbsti	rva, sv2, 4		@ store 0 as number of bytes received
	b	i2cxit

i2c_rs_get:	@ Receiving as Slave -- new data received (I2STAT = 0x80)
	bl	i2getc
	b	i2cxit

i2c_rs_end:	@ Receiving as Slave -- STOP or re-START received (I2STAT = 0xA0)
	set	rva, #f			@ rva <- #f
	tbsti	rva, sv2, 0		@ set busy status to #f in i2cbuffer[0]
	set	rva, #t			@ rva <- #t
	tbsti	rva, sv2, 1		@ set data ready to #t in i2cbuffer[4]
	bl	yldoff
	b	i2cxit

i2putc:	@ write to i2c, from buffer or glv
	tbrfi	rvb, sv2, 4		@ rvb <- number of bytes sent
	add	rva, rvb, #1		@ rva <- updated number of bytes sent
	tbsti	rva, sv2, 4		@ store updated number of bytes sent
	tbrfi	rva, sv2, 3		@ rva <- number of bytes to send
	cmp	rva, #4			@ are we sending less than 4 bytes?
	itTTT	mi
	submi	rva, rva, rvb		@	if so,  rva <- offset of byte to send + 1
	submi	rva, rva, #1		@	if so,  rva <- offset of byte to send
	lslmi	rva, rva, #3		@	if so,  rva <- number of bits to shift to get target byte
	ldrmi	rvb, [glv, sv1]		@	if so,  rvb <- scheme int containing bytes to send
	itTT	mi
	lsrmi	rvb, rvb, #2		@	if so,  rvb <- raw int containing bytes to send
	lsrmi	rvb, rvb, rva		@	if so,  rvb <- raw int, shifted to get byte in bits 0-7
	andmi	rva, rvb, #0xFF		@	if so,  rva <- byte to send
	bmi	i2put1			@	if so,  jump to send byte
	cmp	rva, #5			@ are we sending more than 4 bytes?
	itE	mi
	addmi	rva, glv, sv1		@	if not, rva <- address of object in glv
	ldrpl	rva, [glv, sv1]		@	if so,  rva <- address of object from glv
	ldrb	rva, [rva, rvb]		@ rva <- next byte of object
i2put1:	strb	rva, [sv3, #i2c_thr]	@ put next data byte in I2C data register
	set	pc,  lnk

i2getc:	@ get character from i2c data register and store it in i2cbuffer or glv
	tbrfi	rvb, sv2, 4		@ rvb <- number of data bytes received before this one
	add	rva, rvb, #1		@ rva <- updated number of bytes received
	tbsti	rva, sv2, 4		@ store updated number of received bytes in i2cbuffer[16]
	cmp	rvb, #8			@ were 8 bytes already received?
	itE	mi
	addmi	rva, sv2, #8		@	if not, rva <- storage start address in i2cbuffer
	ldrpl	rva, [glv, sv1]		@	if so,  rva <- storage start address in glv
	add	rvb, rvb, rva		@ rvb <- address at which to store new byte
	ldrb	rva, [sv3, #i2c_rhr]	@ rva <- received byte from I2C data register
	strb	rva, [rvb]		@ store the byte in memory	
	set	pc,  lnk

i2c_maloc: @ Receiving as Master or Slave -- 7 bytes received
	@ store new byte, allocate Heap memory for object
	@ and update number of bytes to read
	ldmia	sp!, {fre}
	stmdb	sp,  {rva}		@ save i2c[0/1] base address on stack
	ldr	lnk, =i2c0_base
	eq	rva, lnk		@ is it an I2C0 interrupt?
	itE	eq
	ldreq	rvb, =I2C0BUFFER
	ldrne	rvb, =I2C1BUFFER
	ldrb	rva, [rva, #i2c_rhr]	@ rva <- received byte from I2C data register
	strb	rva, [rvb, #15]		@ store the byte in memory			
	tbrfi	rva, rvb, 4		@ rva <- number of data bytes received before this one
	add	rva, rva, #1		@ rva <- updated number of bytes received
	tbsti	rva, rvb, 4		@ store updated number of received bytes in i2cbuffer[16]
	ldr	rva, [rvb, #8]		@ rva <- tag of sized object
	lsr	rva, rva, #8		@ rva <- number of data bytes in sized-object (raw int)	
	add	rvb, rva, #4		@ rvb <- number of bytes to allocate, with header
	bl	zmaloc			@ rva <- address of sized object
	add	fre, rva, rvb		@ fre <- address of next free cell (level 2 reserved)
	orr	fre, fre, #0x02		@ fre <- de-reserved
	ldmdb	sp,  {rvb}		@ rvb <- i2c[0/1] base address restored from stack
	stmdb	sp!, {fre}
	stmdb	sp!, {sv1-sv5}		@ store user mode registers on irq stack
	set	sv3, rvb		@ sv3 <- i2c[0/1] base address
	ldr	rvb, =i2c0_base
	eq	sv3, rvb
	itTEE	eq
	streq	rva, [glv, #12]		@	if so,  store address of sized object in glv
	ldreq	sv2, =I2C0BUFFER	@	if so,  sv2 <- i2c0 buffer address
	strne	rva, [glv, #16]		@	if not, store address of sized object in glv
	ldrne	sv2, =I2C1BUFFER	@	if not, sv2 <- i2c1 buffer address
	@ next 2 lines shouldn't be necessary anymore if i2cmlc threshold is lowered to 4 bytes
	tbrfi	rvb, sv2, 3		@ rvb <- 1st data word of object
	str	rvb, [rva,  #4]		@ store it into sized object
	tbrfi	rvb, sv2, 2		@ rvb <- tag of sized object
	str	rvb, [rva]		@ store tag into sized object
	lsr	rvb, rvb, #8		@ rvb <- number of data bytes in sized-object (raw int)
	add	rvb, rvb, #4		@ rvb <- number of bytes in object, with header
	tbsti	rvb, sv2, 3		@ store number of bytes to read (total, raw) in i2cbuffer[12]
	b	i2cxit

i2cxit:	@ standard i2c exit
	bl	hwi2cs			@ clear SI, if needed
	@ restore registers and return
	ldmia	sp!, {sv1-sv5}
	b	gnisxt			@ jump to exit isr (simple)
	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

.endif	@ include_i2c

@-------------------------------------------------------------------------------
@
@ III.C. COMMON COMPONENTS OF USB I/O and ISR
@
@-------------------------------------------------------------------------------

.ifdef	native_usb

pusptc:	@ usb putc sub-sub-function
	@ write raw ascii value in rvb to USB write buffer
	@ on entry:	sv1 <- scheme char or string to write out
	@ on entry:	sv2 <- ((port <reg> <n> ...) . port-vec) = full out port
	@ on entry:	sv3 <- saved lnk from caller of caller
	@ on entry:	sv4 <- port address
	@ on entry:	sv5 <- saved lnk from caller
	@ on entry:	rvb <- ascii char to write + offset of char in string
	@ preserves:	sv1, sv2, sv3, sv4, sv5, rvb
	@ modifies:	rva, rvc
	@ returns via lnk (through usbhwrc)
	ldr	rva, =BUFFER_START	@ rva <- address of main buffer
	vcrfi	rva, rva, WRITE_BF_offset @ rva <- address of WRITEBUFFER
	swi	run_no_irq		@ disable interrupts (user mode)
	vcrfi	rvc, rva, 0		@ rvc <- num chars in wrt bffr (sch int)
	add	rvc, rvc, #4		@ rvc <- buffer tag w/number of chars+1
	vcsti	rva, 0, rvc		@ store updated number of chars
	add	rvc, rva, rvc, lsr #2	@ rvc <- buffer address for char minus 3
	strb	rvb, [rvc, #3]		@ store new character in buffer
	b	usbhwrc			@ init usb write, re-enab ints, return

@-------------------------------------------------------------------------------
@ USB ISR
@-------------------------------------------------------------------------------

usbisr:	@ interrupt service routine for USB, branched from genisr on cortex-m3
	stmdb	sp!, {sv1-sv5, env, dts, glv}	@ store remnng user regs on stk
	@ get and process interrupt
	ldr	rva, =usb_base
.ifndef	usbhwgetDevEPint
	ldr	sv1, [rva, #usb_istat_dv] @ sv1 <- Device Interrupt Status
.else
	bl	usbhwgetDevEPint	@ sv1 <- USB int status (EP and/or dev)
.endif
	ldr	rvb, =usb_iep_mask
	tst	sv1, rvb		@ is this an Enpoint (Slow) Interrupt?
	bne	usbEPi			@	if so, jump to process it
.ifdef	usbhwgetDevint
	bl	usbhwgetDevint		@ sv1 <- USB device (only) int status
.endif
	tst	sv1, #usb_idv_mask	@ is this a Device Status Interrupt ?
	beq	usbDSx			@ 	if not, jump to exit
usbDSi: @ Process a Device Status Interrupt [internal entry]
	bl	usbhwDeviceStatus	@ rvb <- device status
	tst	rvb, #usb_busreset	@ did we device receive a bus reset?
	beq	usbSUS			@	if not, jump to see if suspend
	bl	usbhwReset
	set	rvb, #0			@ rvb <- 0
	ldr	rva, =USB_CONF		@ rva <- address of conf status in RAM
	str	rvb, [rva]		@ store zero as conf status
	ldr	rva, =USB_CHUNK		@ rva <- address of chunk in RAM
	str	rvb, [rva]		@ set remaining bytes to send to zero
	b	usbDSx			@ jump to exit
usbSUS:	tst	rvb, #usb_suspend	@ did device receive a state change?
	it	ne
	blne	usbhwRemoteWakeUp	@	if so,  jump to process it
usbDSx: @ clear Device Status Interrupt and exit
.ifdef	usb_iclear_dv			@ MCUs w/interrupt not cleared on read
	bic	sv1, sv1, #usb_itxendp	@ exclude Txendpkt bit from int clearing
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt register
.endif
usbixt:	@ exit usb ISR
	@ restore registers and return
	ldmia	sp!, {sv1-sv5, env, dts, glv} @ restore user mode regs from stk
	b	gnisxt			@ jump to exit isr (simple)

usbEPi:	@ Process an endpoint (slow) interrupt
	bl	usbhwEndpointStatus	@ sv2, sv3 <- EP stat (sv3 w/SETUP inf)
	tst	sv2, #usbCO_ibit	@ is interrupt for Control OUT EP ?
	bne	usbCOi			@	if so, jump to process EP0 int
	tst	sv2, #usbCI_ibit	@ is interrupt for Control IN EP ?
	bne	usbCIi			@	if so, jump to process EP1 int
	tst	sv2, #usbBO_ibit	@ is interrupt for Bulk Out EP ?
	bne	usbBOi			@	if so, jump to process EP4 int
	tst	sv2, #usbBI_ibit	@ is interrupt for Bulk IN EP ?
	bne	usbBIi			@	if so, jump to process EP5 int
usbEPx:	@ clear endpoint interrupt and exit
.ifdef	usb_iclear_dv			@ MCUs w/interrupt not cleared on read
	bic	sv1, sv1, #usb_itxendp	@ exclude Txendpkt bit from int clearing
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dvep] @ clear USB EP/DV interrupt reg
.endif
	b	usbixt

usbBOi:	@ Process interrupt for Bulk OUT endpoint
	@ read data from usb FIFO
.ifdef	usbhwBOe
	bl	usbhwBOe		@ special entry: clr Rx/Bk int
.endif
	set	env, #UsbBulkOutEP	@ env <- Bulk OUT EP (phys = 4, log = 2)
	ldr	dts, =USB_BULK_DATA	@ dts <- address of bulk data buffer
	bl	rdEP			@ cnt <- updated num bytes (read data)
.ifdef	debug_usb
	ldr	rva, =RAMTOP
	ldr	rvb, [rva]
	add	rvb, rvb, #12		@ rvb <- next free byte
	str	rvb, [rva]
	sub	rva, rvb, #12		@ rva <- current free byte
	ldr	rvb, =0x0b0b0b0b
	str	rvb, [rva]
	ldr	rvc, =USB_BULK_DATA	@ rvc <- Setup
	ldr	rvb, [rvc]
	str	rvb, [rva, #4]
	ldr	rvb, [rvc, #4]
	str	rvb, [rva, #8]
.endif
	cmp	cnt, #0			@ is data count negative (error)?
	bmi	usbStall		@	if so,  stall
	eq	cnt, #0			@ was no data read?
	beq	usbEPx			@	if so,  exit isr
	@ copy data to read and write buffers
	ldr	dts, =USB_BULK_DATA	@ dts <- address of bulk data buffer
	ldr	env, =BUFFER_START	@ env <- start address of buffers
	vcrfi	sv4, env, WRITE_BF_offset @ sv4 <- address of WRITEBUFFER
	vcrfi	rvc, sv4, 0		@ rvc <- num chars in writ buf (sch int)
	lsr	rvc, rvc, #2
	add	sv4, sv4, #4		@ sv4 <- address of 1st char in WRITEBUF
	vcrfi	env, env, READ_BF_offset @ env <- address of READBUFFER
	vcrfi	rva, env, 0		@ rva <- num chars in buffer (sch int)
	add	env, env, #4		@ env <- address of 1st char in READBUF
	set	sv5, #0
	tst	rva, #i0
	lsr	rva, rva, #2
	beq	usbnec
usb4_0:	cmp	sv5, cnt		@ done gettng chars frm USB blk dat buf?
	bpl	usb4_1			@	if so,  jump to finish up
	ldrb	rvb, [dts, sv5]		@ rvb <- char from USB bulk data buffer
	add	sv5, sv5, #1		@ sv5 <- offset nxt char USB blk dat buf
	eq	rvb, #3
	beq	usbbrk
	eq	rvb, #'\n		@ is byte a newline (lf)
	beq	usb4_0			@	if so,  jump to process chars
	strb	rvb, [env, rva]		@ store character in READBUFFER
	strb	rvb, [sv4, rvc]		@ store character in WRITEBUFFER
	add	rva, rva, #1		@ rva <- offset of next char in READBUF
	add	rvc, rvc, #1		@ rva <- offset of next char in WRITEBUF
	eq	rvb, #'\b		@ was byte a backspace?
	bne	usb4_0			@	if not, jump to process chars
usb4_3:	@ process a backspace character
	subs	rva, rva, #2
	it	mi
	setmi	rva, #0
	set	rvb, #' 		@ rvb <- space (raw ASCII)
	strb	rvb, [sv4, rvc]		@ store character in WRITEBUFFER
	add	rvc, rvc, #1		@ rva <- offset of next char in WRITEBUF
	set	rvb, #'\b		@ rvb <- backspace
	strb	rvb, [sv4, rvc]		@ store character in WRITEBUFFER
	add	rvc, rvc, #1		@ rva <- offset of next char in WRITEBUF
	b	usb4_0
usb4_1:	@ finish up
	raw2int	rvb, rva
	str	rvb, [env, #-4]		@ update READBUFFER tag
	raw2int	rvb, rvc
	str	rvb, [sv4, #-4]		@ update WRITEBUFFER tag
	bl	usbhwBOw		@ echo the characters read
	b	usbixt			@ exit

usbnec:	@ process chars with no special treatment and no echo
	ldrb	rvb, [dts, sv5]		@ rvb <- char from USB bulk data buffer
	add	sv5, sv5, #1		@ sv5 <- offset nxt char USB blk dat buf
	strb	rvb, [env, rva]		@ store character in READBUFFER
	add	rva, rva, #1		@ rva <- offset of next char in READBUF
	cmp	sv5, cnt		@ done gettng chars frm USB blk dat buf?
	bmi	usbnec			@	if not, jump to get more chars
	lsl	rvb, rva, #2
	orr	rvb, rvb, #f0
	str	rvb, [env, #-4]		@ update READBUFFER tag
	b	usbixt			@ exit

usbbrk:	@ process reception of a break (ctrl-c)
.ifdef	usb_iclear_dv			@ MCUs w/interrupt not cleared on read
	bic	sv1, sv1, #usb_itxendp	@ exclude Txendpkt bit from int clearing
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dvep] @ clear USB EP/DV interrupt register
.endif
	sub	rva, env, #4 		@ rva <- address of READBUFFER
	ldmia	sp!, {sv1-sv5, env, dts, glv}	@ restor usr mode regs frm stack
	set	rvc, #i0
	vcsti	rva, 0, rvc
	mvn	rvb, rvb
	add	rvb, rvb, #1
	b	genis0

usbBIi:	@ Process interrupt for Bulk IN endpoint
.ifdef	usbhwBIe
	bl	usbhwBIe		@ special entry: clr txpktend/txcomp int
.endif
	set	env, #UsbBulkInEP	@ env <- Bulk IN EP (phys = 5, log = 2)
	ldr	dts, =BUFFER_START
	vcrfi	dts, dts, WRITE_BF_offset @ dts <- address of WRITEBUFFER	
	vcrfi	cnt, dts, 0		@ cnt <- num chars in writ buf (sch int)
.ifdef	debug_usb
	ldr	rva, =RAMTOP
	ldr	rvb, [rva]
	add	rvb, rvb, #4		@ rvb <- next free byte
	str	rvb, [rva]
	sub	rva, rvb, #4		@ rva <- current free byte
	ldr	rvb, =0xaabbccdd
	str	rvb, [rva]
.endif
	cmp	cnt, #5
	bmi	usbEPx
	add	dts, dts, #4		@ dts <- adrs of 1st char in WRITEBUFFER
	lsr	cnt, cnt, #2
.ifndef	has_HS_USB
	set	rvb, #64
.else
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	itE	eq
	seteq	rvb, #64
	setne	rvb, #512
.endif
	cmp	cnt, rvb
	it	pl
	setpl	cnt, rvb
.ifdef	debug_usb
	ldr	rva, =RAMTOP
	ldr	rvb, [rva]
	add	rvb, rvb, #16		@ rvb <- next free byte
	str	rvb, [rva]
	sub	rva, rvb, #16		@ rva <- current free byte
	ldr	rvb, =0x0c0c0c0c
	str	rvb, [rva]
	str	cnt, [rva, #4]
	ldr	rvc, [dts]		@ rvc <- 4 chars from buffer
	str	rvc, [rva, #8]
	ldr	rvc, [dts, #-4]		@ rvc <- num chars in buffer
	lsr	rvc, rvc, #2
	str	rvc, [rva, #12]
.endif
.ifndef	usbhwBIw
	bl	wrtEP			@ write buffer to Bulk IN EP (normal)
.else
	bl	usbhwBIw		@ write buffer to Bulk IN EP (special)
.endif
	@ update the write buffer
	ldr	env, =BUFFER_START
	vcrfi	env, env, WRITE_BF_offset @ env <- address of WRITEBUFFER
	vcrfi	rva, env, 0		@ rva <- num chars in writ buf (sch int)
	lsr	sv5, rva, #2
.ifndef	has_HS_USB
	set	rvb, #64
.else
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	itE	eq
	seteq	rvb, #64
	setne	rvb, #512
.endif
	cmp	sv5, rvb
	it	pl
	setpl	sv5, rvb
	rsb	rvb, sv5, rva, LSR #2	@ rvb <- num byts to remain in writ buf
	lsl	rvc, rvb, #2
	orr	rvc, rvc, #i0
	str	rvc, [env]
	add	env, env, #4
	set	sv3, #0			@ sv3 <- number of bytes moved = 0
usb5_0:	cmp	sv3, rvb		@ have we moved all bytes ?
.ifndef	usbhwBIx
	bpl	usbEPx			@	if so,  exit (normal)
.else
	bpl	usbhwBIx		@	if so,  exit (special)
.endif
	ldrb	sv4, [env, sv5]		@ sv4 <- byte
	strb	sv4, [env, sv3]		@ store it at earlier index in write buf
	add	sv3, sv3, #1		@ sv3 <- updated number of moved bytes
	add	sv5, sv5, #1		@ sv5 <- updtd offset to next byt to mov
	b	usb5_0

usbCIi:	@ Process interrupt for Control IN Endpoint
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	ldr	rva, =USB_CHUNK
	ldr	dts, [rva, #4]		@ dts <- start address of data to send
	ldr	cnt, [rva]		@ cnt <- how many bytes remain to send
.ifndef	has_HS_USB
	set	rvb, #8
.else
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	itE	eq
	seteq	rvb, #8
	setne	rvb, #64
.endif
	cmp	cnt, rvb		@ want to send more than 8/64 bytes?
	itTE	pl
	subpl	sv5, cnt, rvb		@	if so,  sv5 <- remainng num byts
	setpl	cnt, rvb		@	if so,  cnt <- 8/64=num byts snd
	setmi	sv5, #0			@	if not, sv5 <- 0=num byts remain
	str	sv5, [rva]		@ store that in USB_CHUNK
	itE	pl
	addpl	sv5, dts, cnt		@	if so,  sv5 <- adrs remainng dat
	setmi	sv5, dts		@	if not, sv5 <- prior address
	str	sv5, [rva, #4]		@ store that in USB_CHUNK
.ifndef	usbhwCIw
	bl	wrtEPU			@ write buffer to EP0 IN (normal)
.else
	bl	usbhwCIw		@ write buffer to EP0 IN (special)
.endif
	b	usbixt			@ jump to exit

usbCOi:	@ Process interrupt for Control OUT Endpoint
	tst	sv3, #usbCO_setupbit	@ is last rcvd pkt for EP0 a Setup pkt?
	beq	usbDSP			@	if not, jump to DATA/STATUS phas
	set	rvb, #0			@ rvb <- 0
	ldr	rva, =USB_CHUNK		@ rva <- address of chunk in RAM
	str	rvb, [rva]		@ set remaining bytes to send to zero	
	set	env, #UsbControlOutEP	@ env <- Control OUT EndPoint
	ldr	dts, =USB_SETUP_BUFFER	@ dts <- Setup
.ifndef	usbhwSetup
	bl	rdEP			@ read SETUP pkt into buffer (normal)
.else
	bl	usbhwSetup		@ read SETUP pkt into buffer (special)
.endif
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	ldr	sv5, [rva, #4]		@ sv5 <- index(16), length(16)
	lsrs	cnt, sv5, #16		@ cnt <- num byts to tfer, is it zero?
	beq	usbRQS			@	if so,  jump to process request
	tst	rvb, #0x80		@ is dir from dev to host?
	beq	usbEPx			@	if not, exit
	b	usbRQS			@	if so,  jump to process request
usbDSP:	@ Data/Status Phase
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	eq	rvb, #0xFF		@ is data OUT phase complete?
	beq	usbhwStatusOut		@	if so,  jump to Status OUT phase
	@ Data OUT Phase
	ldr	sv5, [rva, #4]		@ sv5 <- index(16), length(16)
	lsrs	cnt, sv5, #16		@ cnt <- num byts to tfer, is it zero?
	beq	usbEPx			@	if so,  jump to return
	@ continue to usbRQS
usbRQS:	@ process EP0 request
	@ here:		rva <- USB_SETUP_BUFFER
	@ here:		rvb <- reqtyp(8l), request(8h), val(16H)
	@ here:		sv5 <- index(16L), length(16H)
	@ here:		cnt <- num bytes to transfer (length)
	ldr	rvc, =0xFF7F		@ rvc <- mask for Standard Requests
	and	rvc, rvb, rvc		@ rvc <- possible Standard request
	lsr	rvb, rvb, #16		@ rvb <- value of request
	and	sv5, sv5, #0xFF		@ sv5 <- EP logical number (from index)
	@ process possible Standard Requests
	eq	rvc, #0x0000		@ Get Status of Device Standard req?
	it	ne
	eqne	rvc, #0x0001		@ 	if not, Get Stat Interf Std req?
	itT	ne
	ldrne	sv3, =0x0A01		@	if not, sv3 <- Intrf of Intrf
	eqne	rvc, sv3		@ 	if not, Get Intrf of Intrf req?
	it	eq
	ldreq	dts, =USB_ZERO		@ 	if so,  dts <- buffer of zeros
	beq	usbCEw			@	if so,  jump to send buf content
	eq	rvc, #0x0500		@ Set Address of Device Standard req?
	beq	usbhwSetAddress		@	if so,  jump to set the address
	eq	rvc, #0x0600		@ Get Descriptor of Device Standard req?
	beq	usbDGD			@	if so,  jump to process that
	eq	rvc, #0x0800		@ Get Configuration of Device Stndr req?
	it	eq
	ldreq	dts, =USB_CONF		@ 	if so,  dts <- USB conf stat buf
	beq	usbCEw			@	if so,  jump to send buf content
	eq	rvc, #0x0900		@ Set Configuration of Device Stndr req?
	beq	usbDSC			@	if so,  jump to process that
	ldr	sv3, =0x0B01
	eq	rvc, sv3		@ Set Interface of Interface Stndrd req?
	beq	usbISI			@	if so,  jump to process that
	eq	rvc, #0x0002		@ Get Status of Endpoint Standard req?
	beq	usbEGS			@	if so,  jump to process that
	ldr	sv3, =0x0102
	eq	rvc, sv3		@ Clear Feature of Endpoint Standrd req?
	beq	usbECF			@	if so,  jump to process that
	ldr	sv3, =0x0302
	eq	rvc, sv3		@ Set Feature of Endpoint Standard req?
	beq	usbESF			@	if so,  jump to process that
	@ process possible Class Requests
	ldr	sv3, =0xFF60		@ sv3 <- mask for Class Requests
	and	rvc, sv3, rvc		@ rvc <- possible Class Request
	ldr	sv3, =0x2020
	eq	rvc, sv3		@ Set Line Coding Class request?
	beq	usbCSL			@	if so,  jump to process that
	ldr	sv3, =0x2120
	eq	rvc, sv3		@ Get Line Coding Class request?
	it	eq
	ldreq	dts, =USB_LineCoding	@	if so,  dts <- line coding buf
	beq	usbCEw			@	if so,  jump to send buf content
	ldr	sv3, =0x2220
	eq	rvc, sv3		@ Set Control Line State Class req?
	beq	usbSIx			@	if so,  jump to Status IN Phase
	b	usbStall		@ Stall on unknown request

usbCSL:	@ 6.2.12 (CDC) Set Line Coding Class request
	set	env, #UsbControlOutEP	@ env <- Control OUT EndPoint
	ldr	dts, =USB_LineCoding
	bl	rdEP			@ read int data into buffer (dts)
	cmp	cnt, #0
	bmi	usbStall
	b	usbSIx			@ jump to Status IN Phase and exit

usbECF:	@ 9.4.1 Clear Feature of Endpoint Standard request
	@ on entry:	rva <- USB_SETUP_BUFFER address
	@ on entry:	rvb <- value of request (feature to clear)
	@ on entry:	sv5 <- EP logical number (from index)
	tst	rvb, #0xff		@ is Feature to clear EP Halt?
	bne	usbStall		@	if not, exit with Stall
	bl	usbhwUnstallEP		@ Clear HALT by unstalling EP
	b	usbSIx			@ jump to Status IN Phase and exit

usbDGD:	@ 9.4.3 Get Descriptor of Device Standard request
	@ on entry:	rva <- USB_SETUP_BUFFER address
	@ on entry:	rvb <- descr index(8l), descr type(8h) (val of request)
	@ on entry:	sv5 <- EP logical number (from index)
	@ on entry:	cnt <- num bytes to transfer (length of request)
	and	sv5, rvb, #0xFF		@ sv5 <- descriptor index
	lsr	rvb, rvb, #8		@ rvb <- dscrptr typ (1-dev,2-cfg,3-str,
					@	4-if,5-ep,6-dq,7-osp,8-pow)
.ifndef	has_HS_USB
	ldr	dts, =USB_DeviceDesc	@	if so,  dts  <- adrs of dev desc
.else
	ldr	rva, =USB_FSHS_MODE
	ldr	rva, [rva]
	eq	rva, #0
	itE	eq
	ldreq	dts, =USB_DeviceDesc	@	if so,  dts  <- FS dev desc adrs
	ldrne	dts, =USB_HS_DeviceDesc	@	if not, dts  <- HS dev desc adrs
.endif
	set	rva, #0			@ rva <- index = 0
	set	env, #0			@ env <- offset to next desc (init=0)
usbS61:	add	dts, dts, env		@ dts <- address of next descriptor
	ldrb	env, [dts]		@ env <- size of descriptor
	eq	env, #0			@ have we reached end of descrip table?
	beq	usbStall		@	if so, return Stall nothng found
	ldrb	rvc, [dts, #1]		@ rvc <- item at pos 1 in desc (typ)
	eq	rvb, rvc		@ is type = descriptor type ?
	bne	usbS61			@	if not, go to scan rest of descs
	eq	sv5, rva		@ is index = Descriptor index?
	it	ne
	addne	rva, rva, #1		@	if not, rva <- index + 1
	bne	usbS61
	@ send cnt bytes of the descriptor
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	ldr	rva, =USB_CHUNK
.ifndef	has_HS_USB
	set	rvb, #8
.else
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	itE	eq
	seteq	rvb, #8
	setne	rvb, #64
.endif
	add	rvb, rvb, #1	
	cmp	cnt, rvb		@ is packet size > 8 (max packet size)
	sub	rvb, rvb, #1
	itE	pl
	subpl	sv5, cnt, rvb		@	if so,  sv5 <- nmbr bytes remain
	setmi	sv5, #0			@	if not, sv5 <- 0
	str	sv5, [rva]		@ store that in USB_CHUNK
	itTE	pl
	setpl	cnt, rvb		@	if so,  cnt <- nmbr bytes to Tx
	addpl	sv5, dts, cnt		@	if so,  sv5 <- adrs of next chnk
	setmi	sv5, dts		@	if not, sv5 <- prior address
	str	sv5, [rva, #4]		@ store that in USB_CHUNK
	b	usbhwDGD

usbEGS:	@ 9.4.5 Get Status of Endpoint Standard request -- respnd whthr EP stlld
	@ on entry:	rva <- USB_SETUP_BUFFER address
	@ on entry:	rvb <- value of request
	@ on entry:	sv5 <- EP logical number (from request index)
	bl	usbhwEGS		@ rvb <- Status of EP
	ldr	dts, =USB_DATA		@ dts <- buffer
	str	rvb, [dts]		@ store stall status in buffer
	set	cnt, #2			@ cnt <- 2 bytes to send
usbCEw:	@ write data from buffer in dts to host
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	bl	wrtEP			@ write 2 bytes (0 0) to EP
	b	usbSOx			@ jump to Status OUT Phase and exit

usbDSC:	@ 9.4.7 Set Configuration of Device Standard request
	@ on entry:	rva <- USB_SETUP_BUFFER address
	@ on entry:	rvb <- configuration to set (value of request)
	@ on entry:	sv5 <- EP logical number (from request index)
	and	sv5, rvb, #0xFF		@ sv5 <- config = lower byt of setup val
	eq	sv5, #0			@ is configuration zero ?
	bne	usbS90
	@ de-configure the device
	bl	usbhwDeconfigure
	set	rvb, #0
	b	usbS91			@ jump to finish up
usbS90:	eq	sv5, #1			@ is the selected configuration #1 ?
	bne	usbStall		@	if not, exit with Stall bad conf
	@ configure the device
	bl	usbhwConfigure
	set	rvb, #1
usbS91:	@ finish up
	ldr	rva, =USB_CONF		@ rva <- address of conf status in RAM
	str	rvb, [rva]		@ store 1 as conf status
	b	usbSIx			@ jump to Status IN Phase and exit

usbESF:	@ 9.4.9 Set Feature of Endpoint Standard request
	@ on entry:	rva <- USB_SETUP_BUFFER address
	@ on entry:	rvb <- feature to set (value of request)
	@ on entry:	sv5 <- EP logical number (from request index)
	tst	rvb, #0xff		@ is Feature EP Halt ?
	bne	usbStall		@	if not, exit with Stall
	@ set HALT Feature by stalling EP
	bl	usbhwStallEP		@ Stall EP
	b	usbSIx			@ jump to Status IN Phase and exit

usbISI:	@ 9.4.10 Set Interface of Interface Standard request
	@  there is only one interface (= 0)
	@ on entry:	rva <- USB_SETUP_BUFFER address
	@ on entry:	rvb <- feature to set (value of request)
	@ on entry:	sv5 <- EP logical number (from request index)
	eq	rvb, #0x00		@ is alternate setting = zero ?
	bne	usbStall		@	if not, Stall
	b	usbSIx			@ jump to Status IN Phase and exit

usbSIx:	@ USB Status IN  exit -- write null packet to Control EP
.ifndef usbhwSIX
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	set	cnt, #0x00		@ cnt <- 0 bytes to send
	bl	wrtEP			@ write 0 bytes to EP
	b	usbEPx
.else
	b	usbhwSIX		@ jump to hw-specific routine
.endif
	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

.endif	@ native_usb



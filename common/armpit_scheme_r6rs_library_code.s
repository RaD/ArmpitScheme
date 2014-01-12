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
@  II.I.2. bytevectors
@-----------------------------------------------------------------------------*/


pmkvu8:	@ (make-bytevector k <fill>)
	@ on entry:	sv1 <- k
	@ on entry:	sv2 <- <fill>
	@ on exit:	sv1 <- bytevector
	@ preserves:	sv2, sv4, sv5
makvu8:	@ [internal entry]
	set	sv3, sv1		@ sv3 <- size of bytevector to allocate
	vu8aloc	sv1, sv3		@ sv1 <- allocated bytevector of size sv1
	nullp	sv2			@ was fill specified?
	itE	eq
	seteq	rvb, #0			@	if not, rvb <- 0
	lsrne	rvb, sv2, #2	
	b	fill8


vu8len:	@ (bytevector-length bytevector)
	@ on entry:	sv1 <- bytevector
	@ on exit:	sv1 <- int
	vu8len	sv1, sv1		@ sv1 <- bytevector length (scheme int)
	set	pc,  cnt


vu8cpy:	@ (bytevector-copy! src src-start dest dest-start k)
	@ on entry:	sv1 <- src
	@ on entry:	sv2 <- src-start
	@ on entry:	sv3 <- dest
	@ on entry:	sv4 <- dest-start
	@ on entry:	sv5 <- (k)
	car	sv5, sv5
	add	rvc, sv2, sv5
	eor	rvc, rvc, #0x03
	cmp	sv2, sv4
	itT	mi
	addmi	sv4, sv4, sv5
	eormi	sv4, sv4, #0x03
	bmi	vu8cpd
vu8cpu:	@ copy up
	cmp	sv2, rvc
	bpl	npofxt
.ifndef	cortex
	ldrb	rva, [sv1, sv2, lsr #2]
	strb	rva, [sv3, sv4, lsr #2]
.else
	int2raw	rvb, sv2
	ldrb	rva, [sv1, rvb]
	int2raw	rvb, sv4
	strb	rva, [sv3, rvb]
.endif
	add	sv2, sv2, #4
	add	sv4, sv4, #4
	b	vu8cpu
vu8cpd:	@ copy down
	sub	rvc, rvc, #4
	sub	sv4, sv4, #4
	cmp	rvc, sv2
	bmi	npofxt
.ifndef	cortex
	ldrb	rva, [sv1, rvc, lsr #2]
	strb	rva, [sv3, sv4, lsr #2]
.else
	int2raw	rvb, rvc
	ldrb	rva, [sv1, rvb]
	int2raw	rvb, sv4
	strb	rva, [sv3, rvb]
.endif
	b	vu8cpd


_func_
vu8ren:	@ (bytevector-u8-ref  bytevector k)			when sv4 =   i0
	@ (bytevector-u8-set! bytevector k octet)		when sv4 =  i32
	@ (bytevector-u16-native-ref  bytevector k)		when sv4 =   i1
	@ (bytevector-u16-native-set! bytevector k u16-item)	when sv4 =  i33
	@ (bytevector-s32-native-ref  bytevector k)		when sv4 =   i2
	@ (bytevector-s32-native-set! bytevector k s30-item)	when sv4 =  i34
	@ common entry for bytevector-xx-ref/set! (from paptbl:)
	@ on entry:	sv1 <- bytevector
	@ on entry:	sv2 <- 2nd input arg (eg. position, k)
	@ on entry:	sv3 <- 3rd input arg (eg. octet, scheme int, or null)
	@ on entry:	sv5 <- remainder of function
	@ on exit:	rvb <- position (scheme int)
	@ on exit:	rvc <- raw octet (if sv3 is octet)
	int2raw	rvb, sv2
	tst	sv4, #0x80
	bne	vu8set
	tst	sv4, #0x08
	itE	eq
	ldrheq	rvb, [sv1, rvb]		@ rvb <- octet (raw int)
	ldrne	rvb, [sv1, rvb]		@ rvb <- octet (raw int)
	tst	sv4, #0x04
	it	eq
	andeq	rvb, rvb, #0xff
	raw2int	sv1, rvb		@ sv1 <- octet (scheme int)
	set	pc,  cnt

vu8set:	@ bytevector-xx-set!
	int2raw	rvc, sv3
	eq	sv4, #i32
	it	eq
	strbeq	rvc, [sv1, rvb]		@ update content of bytevector
	beq	npofxt			@ return with npo
	tst	sv4, #0x08
	itE	eq
	strheq	rvc, [sv1, rvb]		@ update content of bytevector
	strne	rvc, [sv1, rvb]		@ update content of bytevector
	b	npofxt			@ return with npo

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg


/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	11.4.	Exact Bitwise Operations:	bitwise-ior, bitwise-xor,
@						bitwise-and, bitwise-not,
@						bitwise-arithmetic-shift,
@						bitwise-bit-set?,
@						bitwise-copy-bit,
@						bitwise-bit-field,
@						bitwise-copy-bit-field
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	Requires:
@			core:		lcons, lambda_synt, sav__c, save, eval,
@					npofxt
@
@	Modified by (switches):			
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


	EPFUNC	i0, obwloop, 0		@ primitive, init-sv4 = 0, fentry = bwloop, narg = listed
logior:	@ (bitwise-ior int1 int2 ...)
	@ on entry:	sv1 <- (int1 int2 ...)
	orr	rva, rva, rvb
	set	pc,  lnk


	EPFUNC	i0, obwloop, 0		@ primitive, init-sv4 = 0, fentry = bwloop, narg = listed
logxor:	@ (bitwise-xor int1 int2 ...)
	@ on entry:	sv1 <- (int1 int2 ...)
	eor	rva, rva, rvb
	set	pc,  lnk


	EPFUNC	0xfd, obwloop, 0	@ primitive, init-sv4 = -1, fentry = bwloop, narg = listed
logand:	@ (bitwise-and int1 int2 ...)
	@ on entry:	sv1 <- (int1 int2 ...)
	and	rva, rva, rvb
	set	pc,  lnk


	EPFUNC	null, obwloop, 1	@ primitive, init-sv4 = none, fentry = bwloop, narg = 1
lognot:	@ (bitwise-not ei1)
	@ on entry:	sv1 <- ei1	(scheme int or #vu8)
	mvn	rva, rva		@ rva <- inverted bits of rva
	b	bwexit			@ jump to common exit


	EPFUNC	null, obwfent, 2	@ primitive, init-sv4 = none, fentry = bwfent, narg = 2
pbwash:	@ (bitwise-arithmetic-shift ei1 ei2)
	@ on entry:	sv1 <- ei1 = object to shift				(scheme int or #vu8)
	@ on entry:	sv2 <- ei2 = +l/-r-shift				(scheme int)
	cmp	rvb, #0			@ is shift positive?
	itEE	pl
	lslpl	rva, rva,rvb		@	if so,  rva <- raw int shifted left
	rsbmi	rvb, rvb, #0		@	if not, rvb <- minus shift
	asrmi	rva, rva, rvb		@	if not, rva <- raw int shifted right
	b	bwexit			@ jump to common exit


	EPFUNC	null, obwfent, 3	@ primitive, init-sv4 = none, fentry = bwfent, narg = 3
pbwif:	@ (bitwise-if ei1 ei2 ei3)
	@ on entry:	sv1 <- ei1 = test-bits item			(scheme int or #vu8)
	@ on entry:	sv2 <- ei2 = bit-field to fill in if ei1 has 1	(scheme int or #vu8)
	@ on entry:	sv3 <- ei3 = bit-field to fill in if ei1 has 0	(scheme int or #vu8)
	@ on exit:	sv1 <- item with bits from ei2 and ei2 based on mask in ei1 (int or #vu8)
	and	rvb, rva, rvb		@ rvb <- ei2 bits masked by ei1
	mvn	rva, rva		@ rva <- inverted test-bit mask
	and	rvc, rva, rvc		@ rvc <- ei3 bits masked by not ei1
	orr	rva, rvb, rvc		@ rva <- result (raw int)
	b	bwexit			@ jump to common exit


pbwbst:	@ (bitwise-bit-set? ei1 ei2)
	@ on entry:	sv1 <- ei1 = item to test		(scheme int or #vu8)
	@ on entry:	sv2 <- ei2 = bit position to test	(scheme int)
	@ on exit:	sv1 <- #t/#f
	pntrp	sv1
	itE	eq
	ldreq	rva, [sv1]
	int2rawne rva, sv1
	int2raw	rvb, sv2
	asr	rva, rva, rvb
	tst	rva, #1
	b	notfxt			@ jump to exit with #f/#t


	EPFUNC	null, obwfent, 3	@ primitive, init-sv4 = none, fentry = bwfent, narg = 3
pbwcpb:	@ (bitwise-copy-bit ei1 ei2 ei3)
	@ on entry:	sv1 <- ei1 = item in which to set/clear bit		(scheme int or #vu8)
	@ on entry:	sv2 <- ei2 = bit position to set/clear			(scheme int)
	@ on entry:	sv3 <- ei3 = 1 to set bit, 0 to clear			(scheme int)
	@ on exit:	sv1 <- copy of ei1, with bit at ei2 set or cleared
	set	rvc, #1
	lsl	rvb, rvc, rvb
	eq	sv3, #i0
	itE	eq
	biceq	rva, rva, rvb
	orrne	rva, rva, rvb
	b	bwexit			@ jump to common exit
		

	EPFUNC	null, obwfent, 3	@ primitive, init-sv4 = none, fentry = bwfent, narg = 3
pbwbfl:	@ (bitwise-bit-field ei1 ei2 ei3)
	@ on entry:	sv1 <- ei1, item from which to get bit-field		(scheme int or #vu8)
	@ on entry:	sv2 <- ei2, start position of bits to get		(scheme int)
	@ on entry:	sv3 <- ei3, end   position of bits to get		(scheme int)
	@ on exit:	sv1 <- bits from start to end (excl.) of ei1, shifted to bit 0
	set	rvb, #-1
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb
	int2raw	rvb, sv2
	lsr	rva, rva, rvb
	b	bwexit			@ jump to common exit
		

pbwbcf:	@ (bitwise-copy-bit-field ei1 ei2 ei3 ei4)
	@ on entry:	sv1 <- ei1 = item in which to insert bit-field		(scheme int or #vu8)
	@ on entry:	sv2 <- ei2 = start position of bits to insert		(scheme int)
	@ on entry:	sv3 <- ei3 = end   position of bits to insert		(scheme int)
	@ on entry:	sv4 <- ei4 = bit-field to insert into ei1		(scheme int or #vu8)
	@ on exit:	sv1 <- ei1 with bits of ei4 inserted at ei2 to ei3 (#i0 or #vu8)
	swap	sv2, sv4, sv5		@ sv2 <- ei4 = bit-field, sv4 <- ei2 = start (sv5 used as temp)
	bl	bwfen			@ sv1 <- ei1 (eg. bv-copy), rva-rvc <- ei1,ei4,ei3 contents (raw)
	set	rvb, #-1		@ rvb <- #xffffffff
	lsl	rva, rvb, rvc		@ rva <- bit mask:	end-bit    -> bit-31
	int2raw	rvc, sv4		@ rvc <- start bit position
	lsl	rvb, rvb, rvc		@ rvb <- bit mask:	start-bit -> bit-31
	bic	rvb, rvb, rva		@ rvb <- bit mask:	start-bit -> end-bit (excluded)
	pntrp	sv2			@ is ei4 (bit-field) a bytevector?
	itE	eq
	ldreq	rva, [sv2]		@	if so,  rva <- ei4 bit-field data (raw int)
	asrne	rva, sv2, #2		@	if not, rva <- ei4 bit-field data (raw int)
	lsl	rva, rva, rvc		@ rva <- bit-field, shifted in place to start-bit
	and	rva, rva, rvb		@ rva <- bit-field, trimmed to start-end size
	pntrp	sv1			@ is ei1 (source item) a bytevector?
	itE	eq
	ldreq	rvc, [sv1]		@	if so,  rvc <- ei1 source item data (raw int)
	asrne	rvc, sv1, #2		@	if not, rvc <- ei1 source item data (raw int)
	bic	rvc, rvc, rvb		@ rvc <- source item data with bit-field cleared
	orr	rva, rva, rvc		@ rva <- source data with bit-field filled in
	b	bwexit			@ jump to common exit

/*------------------------------------------------------------------------
@
@	11.4 Exact Bitwise Operations:	Common entry and exit
@
@-----------------------------------------------------------------------*/
	
	
_func_
bwloop:	@ bitwise logical operations loop
	set	sv3, sv1
	lsl	rva, sv4, #24
	asr	sv1, rva, #24
	set	sv4, sv5
	@ on entry:	sv1 <- start value for result (scheme int)
	@ on entry:	sv3 <- list of input data
	@ on entry:	sv4 <- function to apply to data
	int2raw	rva, sv1		@ rva <- initial result (raw int)
_func_	@ loop over input data list
bwlop1:	nullp	sv3
	beq	bwexit
	snoc	sv2, sv3, sv3
	bic	rvc, sv1, sv2		@ rvc <- cross-type identifier for sv1 and sv2
	tst	rvc, #1			@ is sv1 a scheme int and sv2 a bytevector?
	itTT	ne
	raw2intne sv1, rva		@	if so,  sv1 <- current result (scheme int)
	blne	bwsv1b			@	if so,  sv1 <- bytevector allocated for result
	pntrp	sv2
	itE	eq
	ldreq	rvb, [sv2]
	asrne	rvb, sv2, #2
	adr	lnk, bwlop1
	set	pc,  sv4
	
_func_
bwexit:	@ [common exit]
	pntrp	sv1
	itTE	ne
	raw2intne sv1, rva		@ sv1 <- shifted int
	streq	rva, [sv1]
	set	pc,  cnt

_func_
bwfent:	@ common function entry for paptbl
	orr	lnk, sv5, #lnkbit0	@ lnk <- set from sv5 = function code address to execute	
_func_
bwfen:	@ common function entry
	pntrp	sv1			@ is ei1 a bytevector?
	it	ne
	pntrpne	sv2			@	if not, is ei2 a bytevector?
	it	ne
	pntrpne	sv3			@	if not, is ei3 a bytevector?
	itTTT	ne
	asrne	rva, sv1, #2		@	if not, rva <- ei1 data (raw int)
	asrne	rvb, sv2, #2		@	if not, rvb <- ei2 data (raw int)
	asrne	rvc, sv3, #2		@	if not, rvc <- ei3 data (raw int)
	setne	pc,  lnk		@	if not, return
_func_	@ upgrade sv1 to bytevector
bwsv1b:	@ [internal entry]

.ifdef enable_MPU

	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
	bic	fre, fre, #0x03		@ upd <- reserve memory
	set	rva, #0x0400
	orr	rva, rva, #bytevector_tag
	pntrp	sv1
	itE	eq
	ldreq	rvc, [sv1]
	asrne	rvc, sv1, #2		@ rvc <- ei1 data (raw int)
	stmia	fre!, {rva, rvc}	@ fre <- addr of next free cell
	sub	sv1, fre, #4		@ sv1 <- address of cons cell, [*commit destination*]
	orr	fre, fre, #0x02		@ de-reserve memory, [*restart critical instruction*]
	orr	lnk, sv5, #lnkbit0	@ lnk <- lnk, restored
.else
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
	set	rvb, #4			@ rvb <- number of bytes to allocate
	bl	zmaloc			@ rva <- addr of object (symbol-tagged)
	pntrp	sv1
	itE	eq
	ldreq	rvc, [sv1]
	asrne	rvc, sv1, #2		@ rvc <- ei1 data (raw int)
	str	rvc, [rva]		@ store ei1 data in bytevector
	add	rva, rva, rvb		@ rva <- address of next free cell
	sub	sv1, rva, rvb		@ sv1 <- address of bytevec, [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	orr	lnk, sv5, #lnkbit0	@ lnk <- lnk, restored
.endif
	ldr	rva, [sv1]		@ rva <- ei1 data (raw int)
	pntrp	sv2			@ is ei2 a bytevector?
	itE	eq
	ldreq	rvb, [sv2]		@	if so,  rvb <- ei2 data (raw int)
	asrne	rvb, sv2, #2		@	if not, rvb <- ei2 data (raw int)
	pntrp	sv3			@ is ei3 a bytevector?
	itE	eq
	ldreq	rvc, [sv3]		@	if so,  rvc <- ei3 data (raw int)
	asrne	rvc, sv3, #2		@	if not, rvc <- ei3 data (raw int)
	set	pc,  lnk		@ return


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg


/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	Addendum Register Bitwise Operations:		bitwise-copy-bit,
@							bitwise-copy-bit-field
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/


_func_
regent:	@ entry for register-oriented functions, for paptbl
	orr	lnk, sv5, #lnkbit0	@ lnk <- set from sv5 = function code address to execute
_func_
reg_en:	@ [internal entry] using bl
	int2raw	rva, sv1
	lsl	rva, rva, #4
	int2raw	rvb, sv2
	set	pc,  lnk


	EPFUNC	null, oregent, 3	@ primitive,init-sv4=no,fentry=regent,narg=3
prcpbt:	@ (register-copy-bit reg ofst ei2 ei3)
	@ on entry:	sv1 <- reg  = register base address for set/clear bit	(scheme int)
	@ on entry:	sv2 <- ofst = register offset for set/clear bit		(scheme int)
	@ on entry:	sv3 <- ei2  = bit position to set/clear			(scheme int)
	@ on entry:	sv4 <- (ei3) where ei3 = 1 to set bit, 0 to clear	(scheme int)
	@ on exit:	sv1 <- npo
	@ pre-entry:	regent sets rva to register address (sv1) and rvb to offset (raw sv2)
	pntrp	sv4
	it	eq
	careq	sv4, sv4		@ sv4 <- ei3	
_func_
rcpbit:	@ [internal entry]
	add	rva, rva, rvb
	int2raw	rvb, sv3
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva]
	eq	sv4, #i0
	itE	eq
	biceq	rvb, rvb, rvc
	orrne	rvb, rvb, rvc
	str	rvb, [rva]
	b	npofxt


prcpbf:	@ (register-copy-bit-field reg ofst ei2 ei3 ei4)
	@ on entry:	sv1 <- reg   = register base address for set/clear bit	(scheme int)
	@ on entry:	sv2 <- ofst  = register offset for set/clear bit	(scheme int)
	@ on entry:	sv3 <- ei2   = start position of bits to insert		(scheme int)
	@ on entry:	sv4 <- ei3   = end   position of bits to insert		(scheme int)
	@ on entry:	sv5 <- (ei4) = bit-field to insert into reg+ofst	(scheme int, listed)
	@ on exit:	sv1 <- npo
	int2raw	rvc, sv4
	set	rvb, #-1		@ rvb <- #xffffffff
	lsl	rva, rvb, rvc		@ rva <- bit mask:	end-bit    -> bit-31
	int2raw	rvc, sv3		@ rvc <- start bit position
	lsl	rvb, rvb, rvc		@ rvb <- bit mask:	start-bit -> bit-31
	bic	rvc, rvb, rva		@ rvc <- bit mask:	start-bit -> end-bit (excluded)
	bl	reg_en			@ rva <- reg address, rvb <- raw offset, from sv1-sv2
	ldr	rvb, [rva, rvb]
	bic	rva, rvb, rvc
	car	sv5, sv5
	int2raw	rvb, sv3
	cmp	rvb, #2
	itTEE	pl
	subpl	rvb, rvb, #2
	lslpl	rvb, sv5, rvb
	rsbmi	rvb, rvb, #2
	lsrmi	rvb, sv5, rvb
	and	rvc, rvb, rvc
	orr	rvc, rva, rvc
	bl	reg_en			@ rva <- reg address, rvb <- raw offset, from sv1-sv2
	str	rvc, [rva, rvb]
	b	npofxt

	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg


/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	11.2.	Fixnum Operations:	fx=?, fx>?, fx<?, fx>=?, fx<=?
@					fxmax, fxmin, fx+, fx*, fx-, fx/
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	Requires:
@			core:		boolxt
@
@	Modified by (switches):			
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/
	
.ifdef	include_r6rs_fx

_func_
pfxeq:	@ (fx=? int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	eq	sv1, sv2
	b	boolxt


_func_
pfxgt:	@ (fx>? int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	eq	sv1, sv2
	beq	notfxt
	@ continue to pfxge

_func_
pfxge:	@ (fx>=? int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	cmp	sv1, sv2
	itE	pl
	setpl	sv1, #t
	setmi	sv1, #f
	set	pc,  cnt


_func_
pfxlt:	@ (fx<? int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	eq	sv1, sv2
	beq	notfxt
	@ continue to pfxle

_func_
pfxle:	@ (fx<=? int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	cmp	sv2, sv1
	itE	pl
	setpl	sv1, #t
	setmi	sv1, #f
	set	pc,  cnt


_func_
pfxmax:	@ (fxmax int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	cmp	sv1, sv2
	it	mi
	setmi	sv1, sv2
	set	pc,  cnt


_func_
pfxmin:	@ (fxmin int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	cmp	sv2, sv1
	it	mi
	setmi	sv1, sv2
	set	pc,  cnt


_func_
pfxmns:	@ (fx- int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	ngint	sv2, sv2
	@ continue to pfxpls

_func_
pfxpls:	@ (fx+ int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	int2raw	rva, sv1		@ rva <- x1 (raw int)
	int2raw	rvb, sv2		@ rva <- x2 (raw int)
	add	rvc, rva, rvb
	raw2int	sv1, rvc
	ands	rva, rvc, #0xE0000000
	it	ne
	eqne	rva, #0xE0000000
	it	eq
	seteq	pc,  cnt
	@ integer sum overflow, error out
	b	corerr


_func_
pfxprd:	@ (fx* int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	int2raw	rvc, sv1		@ rva <- x2 (raw int)
	int2raw	rva, sv2		@ rva <- x1 (raw int)
	smull	rva, rvb, rvc, rva	@ rva <- x1 (raw int) * x2 (raw int), rvc <- possible overflow
	raw2int	sv1, rva
	lsl	rvb, rvb, #3
	orrs	rvb, rvb, rva, lsr #29
	it	ne
	mvnsne	rvc, rvb
	it	eq
	seteq	pc,  cnt
	@ integer product overflow, error out
	b	corerr


_func_
pfxdiv:	@ (fx/ int1 int2)
	@ on entry:	sv1 <- int1
	@ on entry:	sv2 <- int2
	set	lnk, cnt
	b	idivid


_func_
fxchk2:	@ common entry for binary fixnum functions
	@ (type-checking)
	and	rva, sv1, #0x03
	eq	rva, #i0
	itT	eq
	andeq	rvb, sv2, #0x03
	eqeq	rvb, #i0
	bne	fxerr
	bic	rva, sv4, #3
	ldr	sv5, =fxtb
	ldr	pc, [sv5, rva]
	
fxerr:	@ error out
	eq	rva, #i0
	it	eq
	seteq	sv1, sv2
	b	corerr
	
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg

.endif	@	include_r6rs_fx


/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@
@	testing.	itak:				
@
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

.ifndef small_memory

pitak:	@ (itak x y z)
	@ on entry:	sv1 <- x
	@ on entry:	sv2 <- y
	@ on entry:	sv3 <- z
takin:	cmp	sv2, sv1	@ done?
	itT	pl
	setpl	sv1, sv3	@    if so,  sv1 <- z, result
	setpl	pc,  cnt	@    if so,  return
	sav__c			@ dts <- (cnt ...)
	save3	sv1, sv2, sv3	@ dts <- (x y z cnt ...)
	sub	sv1, sv1, #4	@ sv1 <- (- x 1)
	call	takin		@ sv1 <- xnew = (itak sv1 sv2 sv3)
	snoc	sv3, sv4, dts	@ sv3 <- x,    sv4 <- (y z cnt ...)
	snoc	sv4, sv5, sv4	@ sv4 <- y,    sv5 <- (z cnt ...)
	car	sv2, sv5	@ sv2 <- z
	save	sv1		@ dts <- (xnew x y z cnt ...)
	sub	sv1, sv4, #4	@ sv1 <- (- y 1)
	call	takin		@ sv1 <- ynew = (itak sv1 sv2 sv3)
	cdr	sv4, dts	@ sv4 <- (x y z cnt ...)
	snoc	sv2, sv4, sv4	@ sv2 <- x,    sv4 <- (y z cnt ...)
	snoc	sv3, sv4, sv4	@ sv3 <- y,    sv4 <- (z cnt ...)
	car	sv4, sv4	@ sv4 <- z
	save	sv1		@ dts <- (ynew xnew x y z cnt ...)
	sub	sv1, sv4, #4	@ sv1 <- (- z 1)
	call	takin		@ sv1 <- znew = (itak sv1 sv2 sv3)
	set	sv3, sv1	@ sv3 <- znew
	restor2	sv2, sv1	@ sv1 <- xnew, sv2 <- ynew, dts <- (x y z cnt ...)
	cdddr	dts, dts	@ dts <- (cnt ...)
	restor	cnt		@ cnt <- cnt,   dts <- (...)
	b	takin		@ jump to compute (itak sv1 sv2 sv3)

.endif



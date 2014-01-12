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
@-------@	r6rs lib sub-environment	|
	@-------.-------.-------.-------.-------+

		VECSIZE	(end_of_r6lenv - r6lenv) >> 2
r6lenv:
	@-------.-------.-------.-------.-------+
	@	2. sub-environment		|
	@	bytevectors			|
	@-------.-------.-------.-------.-------+

	DEPFUNC	svu8p, ivu8, otypchk, 1		@ (bytevector? obj)
	DPFUNC	smkvu8,	pmkvu8,	2		@ (make-bytevector k <fill>)
	DPFUNC	svu8ln,	vu8len,	1		@ (bytevector-length bytevector)
	DPFUNC	svu8cp,	vu8cpy,	4		@ (bytevector-copy! src src-start dest dest-start k)
	DEPFUNC	svu8rf,	 i0, ovu8ren, 2		@ (bytevector-u8-ref          bytevector k)
	DEPFUNC	svu8st,	i32, ovu8ren, 3		@ (bytevector-u8-set!         bytevector k octet)
	DEPFUNC	svu6rf,	 i1, ovu8ren, 2		@ (bytevector-u16-native-ref  bytevector k)
	DEPFUNC	svu6st,	i33, ovu8ren, 3		@ (bytevector-u16-native-set! bytevector k u16-item)
	DEPFUNC	svu3rf,	 i2, ovu8ren, 2		@ (bytevector-s32-native-ref  bytevector k)
	DEPFUNC	svu3st,	i34, ovu8ren, 3		@ (bytevector-s32-native-set! bytevector k s30-item)
	
	@-------.-------.-------.-------.-------+
	@	11.4. sub-environment		|
	@	bitwise operations		|
	@-------.-------.-------.-------.-------+

	.word	slgior,	logior			@ (bitwise-ior int1 int2 ...)
	.word	slgxor,	logxor			@ (bitwise-xor int1 int2 ...)
	.word	slgand,	logand			@ (bitwise-and int1 int2 ...)
	.word	slgnot,	lognot			@ (bitwise-not ei1)
	.word	sbwash,	pbwash			@ (bitwise-arithmetic-shift ei1 ei2)
	.word	sbwif,	pbwif			@ (bitwise-if             ei1 ei2 ei3)
	DPFUNC	sbwbst,	pbwbst,	2		@ (bitwise-bit-set?       ei1 ei2)
	.word	sbwcpb, pbwcpb			@ (bitwise-copy-bit       ei1 ei2 ei3)
	.word	sbwbfl, pbwbfl			@ (bitwise-bit-field      ei1 ei2 ei3)
	DPFUNC	sbwbcf, pbwbcf,	4		@ (bitwise-copy-bit-field ei1 ei2 ei3 ei4)

	@-------.-------.-------.-------.-------+
	@	Addendum sub-environment	|
	@-------.-------.-------.-------.-------+
	
	.word	srcpbt, prcpbt			@ (register-copy-bit reg ofst ei2 ei3)
	DPFUNC	srcpbf, prcpbf,	4		@ (register-copy-bit-field reg ofst ei2 ei3 ei4)

	@-------.-------.-------.-------.-------+
	@	11.2. sub-environment		|
	@	fixnum operations		|
	@-------.-------.-------.-------.-------+

.ifdef	include_r6rs_fx

	DEPFUNC	sfxeq,	 i0, ofxchk2, 2		@ (fx=?	 int1 int2)
	DEPFUNC	sfxgt,	 i1, ofxchk2, 2		@ (fx>?  int1 int2)
	DEPFUNC	sfxlt,	 i2, ofxchk2, 2		@ (fx<?  int1 int2)
	DEPFUNC	sfxge,	 i3, ofxchk2, 2		@ (fx>=? int1 int2)
	DEPFUNC	sfxle,	 i4, ofxchk2, 2		@ (fx<=? int1 int2)	
	DEPFUNC	sfxmax,	 i5, ofxchk2, 2		@ (fxmax int1 int2)	
	DEPFUNC	sfxmin,	 i6, ofxchk2, 2		@ (fxmin int1 int2)
	DEPFUNC	sfxpls,	 i7, ofxchk2, 2		@ (fx+	 int1 int2)
	DEPFUNC	sfxmns,	 i8, ofxchk2, 2		@ (fx-	 int1 int2)
	DEPFUNC	sfxprd,	 i9, ofxchk2, 2		@ (fx*	 int1 int2)
	DEPFUNC	sfxdiv,	i10, ofxchk2, 2		@ (fx/   int1 int2)

.endif

	@-------.-------.-------.-------.-------+
	@	11.3. sub-environment		|
	@	flonum operations		|
	@-------.-------.-------.-------.-------+

.ifdef	include_r6rs_fl

	.word	sfleq,	pfleq			@ fl=?			
	.word	sflgt,	pflgt			@ fl>?
	.word	sfllt,	pfllt			@ fl<?
	.word	sflge,	pflge			@ fl>=?
	.word	sflle,	pflle			@ fl<=?
	.word	sflmax,	pflmax			@ flmax
	.word	sflmin,	pflmin			@ flmin
	.word	sflpls,	pflpls			@ fl+
	.word	sflmns,	pflmns			@ fl-
	.word	sflprd,	pflprd			@ fl*
	.word	sfldiv,	pfldiv			@ fl/

.endif

	@-------.-------.-------.-------.-------+
	@	testing				|
	@-------.-------.-------.-------.-------+

.ifndef small_memory

	DPFUNC	sitak,	pitak,	3		@ (itak x y z)

.endif


end_of_r6lenv:	@ end of r6rs library env vector
	

/*------------------------------------------------------------------------------
@  II.I.2. bytevectors
@-----------------------------------------------------------------------------*/

	SYMSIZE	11
svu8p:	.ascii	"bytevector?"

	SYMSIZE	15
smkvu8:	.ascii	"make-bytevector"

	SYMSIZE	17
svu8ln:	.ascii	"bytevector-length"
	
	SYMSIZE	16
svu8cp:	.ascii	"bytevector-copy!"

	SYMSIZE	17
svu8rf:	.ascii	"bytevector-u8-ref"

	SYMSIZE	18
svu8st:	.ascii	"bytevector-u8-set!"

	SYMSIZE	25
svu6rf:	.ascii	"bytevector-u16-native-ref"

	SYMSIZE	26
svu6st:	.ascii	"bytevector-u16-native-set!"

	SYMSIZE	25
svu3rf:	.ascii	"bytevector-s32-native-ref"

	SYMSIZE	26
svu3st:	.ascii	"bytevector-s32-native-set!"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	11.4.	Exact Bitwise Operations:	bitwise-ior, bitwise-xor,
@						bitwise-and, bitwise-not,
@						bitwise-arithmetic-shift,
@						bitwise-bit-set?,
@						bitwise-copy-bit,
@						bitwise-bit-field,
@						bitwise-copy-bit-field
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	11
slgior:	.ascii	"bitwise-ior"

	SYMSIZE	11
slgxor:	.ascii	"bitwise-xor"

	SYMSIZE	11
slgand:	.ascii	"bitwise-and"

	SYMSIZE	11
slgnot:	.ascii	"bitwise-not"

	SYMSIZE	24
sbwash:	.ascii	"bitwise-arithmetic-shift"

	SYMSIZE	10
sbwif:	.ascii	"bitwise-if"

	SYMSIZE	16
sbwbst:	.ascii	"bitwise-bit-set?"

	SYMSIZE	16
sbwcpb:	.ascii	"bitwise-copy-bit"

	SYMSIZE	17
sbwbfl:	.ascii	"bitwise-bit-field"

	SYMSIZE	22
sbwbcf:	.ascii	"bitwise-copy-bit-field"

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	Addendum Register Bitwise Operations:		bitwise-copy-bit,
@							bitwise-copy-bit-field
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

	SYMSIZE	17
srcpbt:	.ascii	"register-copy-bit"

	SYMSIZE	23
srcpbf:	.ascii	"register-copy-bit-field"
	
/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	11.2.	Fixnum Operations:	fx=?, fx>?, fx<?, fx>=?, fx<=?
@					fxmax, fxmin, fx+, fx*, fx-, fx/
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/
	
.ifdef	include_r6rs_fx

	SYMSIZE	4
sfxeq:	.ascii	"fx=?"

	SYMSIZE	4
sfxgt:	.ascii	"fx>?"

	SYMSIZE	4
sfxlt:	.ascii	"fx<?"

	SYMSIZE	5
sfxge:	.ascii	"fx>=?"

	SYMSIZE	5
sfxle:	.ascii	"fx<=?"

	SYMSIZE	5
sfxmax:	.ascii	"fxmax"

	SYMSIZE	5
sfxmin:	.ascii	"fxmin"

	SYMSIZE	3
sfxpls:	.ascii	"fx+"

	SYMSIZE	3
sfxprd:	.ascii	"fx*"

	SYMSIZE	3
sfxmns:	.ascii	"fx-"

	SYMSIZE	3
sfxdiv:	.ascii	"fx/"

.endif	@	include_r6rs_fx

/*======-=======-=======-=======-=======-=======-=======-=======-=======-=======
@	testing.	itak:				
@=======-=======-=======-=======-=======-=======-=======-=======-=======-=====*/

.ifndef small_memory

	SYMSIZE	4
sitak:	.ascii	"itak"

.endif


.ifdef	include_r6rs_fx

fxtb:	@ jump table for fixnum functions
	.word	pfxeq
	.word	pfxgt
	.word	pfxlt
	.word	pfxge
	.word	pfxle
	.word	pfxmax
	.word	pfxmin
	.word	pfxpls
	.word	pfxmns
	.word	pfxprd
	.word	pfxdiv

.endif





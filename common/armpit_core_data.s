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
@-------@	core sub-environment		|
	@-------.-------.-------.-------.-------+

		VECSIZE	(end_of_corenv - corenv) >> 2
corenv:

winders_env:	.word	wndrs,	scheme_true	@ _winders
catch_env:	DPFUNC	scatch,	catch,	0	@ (_catch)
program_env:	.word	sprgrm,	scheme_true	@ _prg
@ Addendum: ISR vector, Read Buffer, uart input-port vect (read-only), uart output-port vect (read-only)
		DPFUNC	pGLV,	_GLV, 0		@ (_GLV)
@ Addendum: procedures for linking external code / installing non-moving objects into RAM
		DSYNTAX	s_lkp,	evlvar, 1	@ (_lkp var)
		DSYNTAX	s_mkc,	_mkcpl, 2	@ (_mkc vars-list code-address)
		DSYNTAX	s_apl,	_apply, 2	@ (_apl function args-list)
		DSYNTAX	s_dfv,	vrnsrt, 1	@ (_dfv var)
		DSYNTAX	s_alo,	zmaloc, 0	@ _alo
		DSYNTAX	sisrxt,	gnisxt, 0	@ _isx   isr exit
		DSYNTAX	sgnism,	genism, 0	@ _ism   isr memory allocation (check reservation ...)
@ Addendum: error, gc
		DPFUNC	sthrow,	throw,	2	@ throw
		DPFUNC	sgc,	pgc,	0	@ (gc)
		DSYNTAX	s_gc,	_gc,	0	@ (_gc)
		DPFUNC	s_err,	corerr,	1	@ (_err arg)
		.word	sversi,	versn_		@ version
@ Addendum: pack, library modules of r6rs, file space cleaning
		DPFUNC	sadrof,	padrof,	2	@ (address-of obj ofst)
		DPFUNC	spkdts,	pkdtst,	3	@ (packed-data-set! bv pos val)
		DPFUNC	sunpak,	unpack,	2	@ (unpack packed-object destination)
		DPFUNC	spack,	pack, 	0	@ (pack object)

.ifndef exclude_lib_mod

library_env:	DSYNTAX	slibra,	plibra,	1	@ (library (lib name) expressions)
export_env:	DSYNTAX	sexpor,	pexpor,	1	@ (export expr)
import_env:	DSYNTAX	simpor,	pimpor,	0	@ (import (lib1) (lib2) ...)

.endif

.ifndef	live_SD
		DPFUNC	sfcln,	ffcln,	0	@ (fsc) (file space cleaning)
.endif

@ Addendum: balancing the top-level b-tree

.ifdef top_level_btree
		DPFUNC	sbalan,	_bal,	1	@ (_bal btree)
.endif

end_of_corenv:	@ end of corenv
	
	@-------.-------.-------.-------.-------+
@-------@	core Constants			|
	@-------.-------.-------.-------.-------+

.macro	make_var_from_corenv var_name, var_env
	\var_name = ((\var_env - corenv + 4) << 13) | ((core_env - scmenv) << 6) | variable_tag
.endm

	make_var_from_corenv	winders_var,	winders_env
	make_var_from_corenv	catch_var,	catch_env
	make_var_from_corenv	program_var,	program_env
.ifndef exclude_lib_mod
	make_var_from_corenv	library_var,	library_env
	make_var_from_corenv	export_var,	export_env
	make_var_from_corenv	import_var,	import_env
.endif
	
	@-------.-------.-------.-------.-------+
@-------@	Core Function Names		|
	@-------.-------.-------.-------.-------+

	SYMSIZE	4
sprgrm:	.ascii	"_prg"

	SYMSIZE	8
wndrs:	.ascii	"_winders"
	
	SYMSIZE	4
pISR:	.ascii	"_ISR"

	SYMSIZE	4
sisrxt:	.ascii	"_isx"

	SYMSIZE	4
sgnism:	.ascii	"_ism"

	SYMSIZE	2
sgc:	.ascii	"gc"

	SYMSIZE	3
s_gc:	.ascii	"_gc"

	SYMSIZE	4
s_alo:	.ascii	"_alo"

	SYMSIZE	4
s_mkc:	.ascii	"_mkc"

	SYMSIZE	4
s_apl:	.ascii	"_apl"

	SYMSIZE	4
s_lkp:	.ascii	"_lkp"

	SYMSIZE	4
s_dfv:	.ascii	"_dfv"

	SYMSIZE	6
scatch:	.ascii	"_catch"

	SYMSIZE	5
sthrow:	.ascii	"throw"

	SYMSIZE	4
s_err:	.ascii	"_err"

	SYMSIZE	4
core_:	.ascii	"core"

	SYMSIZE	7
sversi:	.ascii	"version"
	
	SYMSIZE	3
versn_:	.ascii	"060"

	SYMSIZE	4
pGLV:	.ascii	"_GLV"

	SYMSIZE	10
sadrof:	.ascii	"address-of"

	SYMSIZE	16
spkdts:	.ascii	"packed-data-set!"

	SYMSIZE	6
sunpak:	.ascii	"unpack"

	SYMSIZE	4
spack:	.ascii	"pack"

.ifndef	exclude_lib_mod		@ /--------if--------\

	SYMSIZE	7
slibra:	.ascii	"library"

	SYMSIZE	6
sexpor:	.ascii	"export"

	SYMSIZE	6
simpor:	.ascii	"import"

.endif				@ \______endif_______/

.ifndef	live_SD			@ /--------if--------\

	SYMSIZE	3
sfcln:	.ascii	"fsc"

.endif				@ \______endif_______/

.ifdef top_level_btree		@ /--------if--------\

	SYMSIZE	4
sbalan:	.ascii	"_bal"

.endif				@ \______endif_______/


.balign 8

stkbtm:	.word	null
	.word	stkbtm


.balign	4

typtbl:	@ type classification table for typchk
	
aint:	.byte	i0		@ number? (integer_only)
achr:	.byte	npo		@ char?
anul:	.byte	null		@ null?
aprc:	.byte	proc		@ procedure?
anot:	.byte	f		@ not
avar:	.byte	variable_tag	@ symbol?
astr:	.byte	string_tag	@ string?
avec:	.byte	vector_tag	@ vector?
avu8:	.byte	bytevector_tag	@ bytevector?

	@ type classification constants for EPFUNC-otypchk

	iint	= ((aint - typtbl) << 2) | i0
	ichr	= ((achr - typtbl) << 2) | i0
	inul	= ((anul - typtbl) << 2) | i0
	iprc	= ((aprc - typtbl) << 2) | i0
	inot	= ((anot - typtbl) << 2) | i0
	ivar	= ((avar - typtbl) << 2) | i0
	istr	= ((astr - typtbl) << 2) | i0
	ivec	= ((avec - typtbl) << 2) | i0
	ivu8	= ((avu8 - typtbl) << 2) | i0

.balign	4








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
@-------@ reader sub-environment		|
	@-------.-------.-------.-------.-------+

	VECSIZE	(end_of_rw_env - rw_env) >> 2

rw_env:
	DEPFUNC	sread,	(0x24<<2)|i0, oioprfn,0	@ read		6.6.2 input
write_env:
	DEPFUNC	swrite,	(0x03<<2)|i0, oioprfn,1	@ write		6.6.3 output
	DEPFUNC	sdispl,	(0x03<<2)|f0, oioprfn,1	@ display
	DPFUNC	sload,	pload,	2	@ (load filename <port-model>)	6.6.4 system interface
	DPFUNC	sparse,	pparse,	1	@ (parse expr)			Addendum
	DPFUNC	sprmpt,	prompt,	0	@ (prompt)

end_of_rw_env:	@ end of rw_env

.macro	make_var_from_rwenv var_name, var_env
	\var_name =((\var_env-rw_env+4)<<13)|((rdwr_env-scmenv)<<6)|variable_tag
.endm

	make_var_from_rwenv	write_var,	write_env


	SYMSIZE	4
sread:	.ascii	"read"

	SYMSIZE	5
swrite:	.ascii	"write"

	SYMSIZE	2
null__:	.ascii	"()"

	SYMSIZE	2
true__:	.ascii	"#t"

	SYMSIZE	2
false_:	.ascii	"#f"

	SYMSIZE	7
proc__:	.ascii	"#<proc>"

	SYMSIZE	6
bltn_:	.ascii	"#<bin>"

	SYMSIZE	4
vu8str:	.ascii	"#vu8"
	
	SYMSIZE	7
sdispl:	.ascii	"display"

	SYMSIZE	4
sload:	.ascii	"load"

	SYMSIZE	5
sparse:	.ascii	"parse"

	SYMSIZE	4
badexp:	.ascii	"?exp"

	SYMSIZE	6
sprmpt:	.ascii	"prompt"

	SYMSIZE	4
prmpt_:	.ascii	"ap> "
	







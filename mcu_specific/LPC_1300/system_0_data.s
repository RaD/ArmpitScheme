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


		VECSIZE	(end_of_s0_env - s0_env) >> 2

	@-------.-------.-------.-------.-------+
s0_env:	@	system 0 sub-environment	|
	@-------.-------.-------.-------.-------+

	@-------.-------.-------.-------.-------+
	@	register address bindings	|
	@-------.-------.-------.-------.-------+
	
	.word	ssysc,	(sys_ctrl  >> 2) | i0	@ sysc <- SYSAHBCLKCTRL
	.word	siocf,	(iocon_pio >> 2) | i0	@ iocf <- IOCON_R
	.word	sgio0,	(io0_base  >> 2) | i0	@ gio0
	.word	sgio1,	(io1_base  >> 2) | i0	@ gio1
	.word	sgio2,	(io2_base  >> 2) | i0	@ gio2
	.word	sgio3,	(io3_base  >> 2) | i0	@ gio3
	.word	sadc0,	(adc0_base >> 2) | i0	@ adc0

	@-------.-------.-------.-------.-------+
	@	utility functions (system 0)	|
	@-------.-------.-------.-------.-------+

	.word	spin, ppin			@ pin
	.word	stic, ptic			@ tic (systick timer)

end_of_s0_env:	@ end of system 0 env vector
	

@-------------------------------------------------------------------------------
@  register address bindings -- names
@-------------------------------------------------------------------------------


	SYMSIZE	4
ssysc:	.ascii	"sysc"

	SYMSIZE	4
siocf:	.ascii	"iocf"

	SYMSIZE	4
sgio0:	.ascii	"gio0"

	SYMSIZE	4
sgio1:	.ascii	"gio1"

	SYMSIZE	4
sgio2:	.ascii	"gio2"

	SYMSIZE	4
sgio3:	.ascii	"gio3"

	SYMSIZE	4
sadc0:	.ascii	"adc0"

/*  utility functions			*/

	SYMSIZE	3
spin:	.ascii	"pin"

	SYMSIZE	3
stic:	.ascii	"tic"







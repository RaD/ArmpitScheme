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
	
	.word	ssysc,	(sys_ctrl     >> 2) | i0	@ sysc  <- SCU base
	.word	sVIC,	(int_base     >> 2) | i0	@ VIC   <- VIC 0
	.word	srtc0,	(rtc0_base    >> 2) | i0	@ rtc0
	.word	sgioa,	(ioA_base     >> 2) | i0	@ gioa -- gio B-D are not scheme int-able
	.word	sgioe,	(ioE_base     >> 2) | i0	@ gioe
	.word	sgiof,	(ioF_base     >> 2) | i0	@ giof -- gio G is not scheme int-able
	.word	sgioh,	(ioH_base     >> 2) | i0	@ gioh
	.word	stmr0,	(timer0_base  >> 2) | i0	@ tmr0
	.word	stmr1,	(timer1_base  >> 2) | i0	@ tmr1
	.word	suar0,	(uart0_base   >> 2) | i0	@ uar0
	.word	suar1,	(uart1_base   >> 2) | i0	@ uar1
	.word	sspi0,	(spi0_base    >> 2) | i0	@ spi0
	.word	sadc0,	(adc0_base    >> 2) | i0	@ adc0
	.word	spwm0,	(pwm0_base    >> 2) | i0	@ pwm0
	.word	spwm1,	(pwm1_base    >> 2) | i0	@ pwm1

	@-------.-------.-------.-------.-------+
	@	utility functions (system 0)	|
	@-------.-------.-------.-------.-------+

	DPFUNC	scfpwr, pcfpwr,	2		@ config-power
	.word	spstdr, ppstdr			@ pin-set-dir
	.word	spnset, ppnset			@ pin-set
	.word	spnclr, ppnclr			@ pin-clear
	.word	spnstq, ppnstq			@ pin-set?
	.word	ststrt, ptstrt			@ restart (timer)
	.word	ststop, ptstop			@ stop    (timer)
	.word	sspput, pspput			@ spi-put
	.word	sspget, pspget			@ spi-get
	

end_of_s0_env:	@ end of system 0 env vector
	

/*------------------------------------------------------------------------------
@  register address bindings -- names
@-----------------------------------------------------------------------------*/

	SYMSIZE	4
ssysc:	.ascii	"sysc"

	SYMSIZE	3
sVIC:	.ascii	"VIC"

	SYMSIZE	4
srtc0:	.ascii	"rtc0"

	SYMSIZE	4
sgioa:	.ascii	"gioa"

	SYMSIZE	4
sgioe:	.ascii	"gioe"

	SYMSIZE	4
sgiof:	.ascii	"giof"

	SYMSIZE	4
sgioh:	.ascii	"gioh"

	SYMSIZE	4
stmr0:	.ascii	"tmr0"

	SYMSIZE	4
stmr1:	.ascii	"tmr1"

	SYMSIZE	4
suar0:	.ascii	"uar0"

	SYMSIZE	4
suar1:	.ascii	"uar1"

	SYMSIZE	4
sspi0:	.ascii	"spi0"

	SYMSIZE	4
sadc0:	.ascii	"adc0"

	SYMSIZE	4
spwm0:	.ascii	"pwm0"

	SYMSIZE	4
spwm1:	.ascii	"pwm1"

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

	SYMSIZE	12
scfpwr:	.ascii	"config-power"

	SYMSIZE	11
spstdr:	.ascii	"pin-set-dir"

	SYMSIZE	7
spnset:	.ascii	"pin-set"
	
	SYMSIZE	9
spnclr:	.ascii	"pin-clear"
	
	SYMSIZE	8
spnstq:	.ascii	"pin-set?"

	SYMSIZE	4
ststop:	.ascii	"stop"

	SYMSIZE	7
ststrt:	.ascii	"restart"

	SYMSIZE	7
sspput:	.ascii	"spi-put"

	SYMSIZE	7
sspget:	.ascii	"spi-get"







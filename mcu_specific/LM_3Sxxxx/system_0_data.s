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
	@	system 0 sub-environment	|
	@-------.-------.-------.-------.-------+

		VECSIZE	(end_of_s0_env - s0_env) >> 2

	@-------.-------.-------.-------.-------+
s0_env:	@	register address bindings	|
	@-------.-------.-------.-------.-------+
	
	.word	s_rcc,	(rcc_base     >> 2) | i0	@ rcc  <- rcc base
	.word	sgioa,	(ioporta_base >> 2) | i0	@ gioa
	.word	sgiob,	(ioportb_base >> 2) | i0	@ giob
	.word	sgioc,	(ioportc_base >> 2) | i0	@ gioc
	.word	sgiod,	(ioportd_base >> 2) | i0	@ giod
	.word	sgioe,	(ioporte_base >> 2) | i0	@ gioe
	.word	sgiof,	(ioportf_base >> 2) | i0	@ giof
	.word	sgiog,	(ioportg_base >> 2) | i0	@ giog
	.word	sgioh,	(ioporth_base >> 2) | i0	@ gioh
	.word	stmr0,	(timer0_base  >> 2) | i0	@ tmr0
	.word	stmr1,	(timer1_base  >> 2) | i0	@ tmr1
	.word	stmr2,	(timer2_base  >> 2) | i0	@ tmr2
	.word	stmr3,	(timer3_base  >> 2) | i0	@ tmr3
	.word	suar0,	(uart0_base   >> 2) | i0	@ uar0
	.word	suar1,	(uart1_base   >> 2) | i0	@ uar1
	.word	spwm0,	(pwm0_base    >> 2) | i0	@ pwm0
	.word	s_i2c0,	(i2c0_base    >> 2) | i0	@ i2c0
	.word	s_i2c1,	(i2c1_base    >> 2) | i0	@ i2c1
	.word	sssi0,	(ssi0_base    >> 2) | i0	@ ssi0
	.word	sssi1,	(ssi1_base    >> 2) | i0	@ ssi1
	.word	sadc0,	(adc0_base    >> 2) | i0	@ adc0

	@-------.-------.-------.-------.-------+
	@	utility functions (system 0)	|
	@-------.-------.-------.-------.-------+

	DPFUNC	scfpwr, pcfpwr,	3		@ config-power
	.word	scfgpn, pcfgpn			@ config-pin
	.word	spnset, ppnset			@ pin-set
	.word	spnclr, ppnclr			@ pin-clear
	.word	spnstq, ppnstq			@ pin-set?
	DPFUNC	ststrt, ptstrt,	1		@ tic-start (systick timer)
	DPFUNC	ststop, ptstop,	0		@ tic-stop  (systick timer)
	DPFUNC	stkred, ptkred,	0		@ tic-read  (systick timer)
	.word	sspput, pspput			@ spi-put
	.word	sspget, pspget			@ spi-get
	

end_of_s0_env:	@ end of system 0 env vector


/*------------------------------------------------------------------------------
@  register address bindings -- names
@-----------------------------------------------------------------------------*/

	SYMSIZE	3
s_rcc:	.ascii	"rcc"

	SYMSIZE	4
sgioa:	.ascii	"gioa"

	SYMSIZE	4
sgiob:	.ascii	"giob"

	SYMSIZE	4
sgioc:	.ascii	"gioc"

	SYMSIZE	4
sgiod:	.ascii	"giod"

	SYMSIZE	4
sgioe:	.ascii	"gioe"

	SYMSIZE	4
sgiof:	.ascii	"giof"

	SYMSIZE	4
sgiog:	.ascii	"giog"

	SYMSIZE	4
sgioh:	.ascii	"gioh"

	SYMSIZE	4
stmr0:	.ascii	"tmr0"

	SYMSIZE	4
stmr1:	.ascii	"tmr1"

	SYMSIZE	4
stmr2:	.ascii	"tmr2"

	SYMSIZE	4
stmr3:	.ascii	"tmr3"

	SYMSIZE	4
suar0:	.ascii	"uar0"

	SYMSIZE	4
suar1:	.ascii	"uar1"

	SYMSIZE	4
spwm0:	.ascii	"pwm0"

	SYMSIZE	4
s_i2c0:	.ascii	"i2c0"

	SYMSIZE	4
s_i2c1:	.ascii	"i2c1"

	SYMSIZE	4
sssi0:	.ascii	"ssi0"

	SYMSIZE	4
sssi1:	.ascii	"ssi1"

	SYMSIZE	4
sadc0:	.ascii	"adc0"

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

	SYMSIZE	12
scfpwr:	.ascii	"config-power"
	
	SYMSIZE	10
scfgpn:	.ascii	"config-pin"
	
	SYMSIZE	7
spnset:	.ascii	"pin-set"
	
	SYMSIZE	9
spnclr:	.ascii	"pin-clear"
	
	SYMSIZE	8
spnstq:	.ascii	"pin-set?"
	
	SYMSIZE	8
ststop:	.ascii	"tic-stop"
	
	SYMSIZE	9
ststrt:	.ascii	"tic-start"
	
	SYMSIZE	8
stkred:	.ascii	"tic-read"

	SYMSIZE	7
sspput:	.ascii	"spi-put"
	
	SYMSIZE	7
sspget:	.ascii	"spi-get"
	


	

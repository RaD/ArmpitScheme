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
	
	.word	ssysc,	(sys_ctrl    >> 2) | i0	@ sysc <- sys_ctrl
	.word	sVIC,	(int_base    >> 2) | i0	@ VIC
	.word	srtc0,	(rtc0_base   >> 2) | i0	@ rtc0
	.word	sgio0,	(io0_base    >> 2) | i0	@ gio0
	.word	sgio1,	(io1_base    >> 2) | i0	@ gio1
	.word	sgio2,	(io2_base    >> 2) | i0	@ gio2
	.word	sgio3,	(io3_base    >> 2) | i0	@ gio3
	.word	sgio4,	(io4_base    >> 2) | i0	@ gio4
	.word	sgio5,	(io5_base    >> 2) | i0	@ gio5
	.word	sgio6,	(io6_base    >> 2) | i0	@ gio6
	.word	sgio7,	(io7_base    >> 2) | i0	@ gio7
	.word	stmr0,	(timer0_base >> 2) | i0	@ tmr0
	.word	stmr1,	(timer1_base >> 2) | i0	@ tmr1
	.word	suar0,	(uart0_base  >> 2) | i0	@ uar0
	.word	s_i2c0,	(i2c0_base   >> 2) | i0	@ i2c0
	.word	sadc0,	(adc0_base   >> 2) | i0	@ adc0
	.word	smci,	(mci_base    >> 2) | i0	@ mci
	.word	sgdma,	(gdma_base   >> 2) | i0	@ gdma <- gpdma
	.word	slcd,	(lcd_base    >> 2) | i0	@ lcd

	@-------.-------.-------.-------.-------+
	@	utility functions (system 0)	|
	@-------.-------.-------.-------.-------+

	DPFUNC	scfgpn, pcfgpn,	4		@ config-pin
	.word	spnset, ppnset			@ pin-set
	.word	spnclr, ppnclr			@ pin-clear
	.word	spnstq, ppnstq			@ pin-set?
	.word	ststrt, ptstrt			@ restart (timer)
	.word	ststop, ptstop			@ stop (timer)
	

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
sgio0:	.ascii	"gio0"

	SYMSIZE	4
sgio1:	.ascii	"gio1"

	SYMSIZE	4
sgio2:	.ascii	"gio2"

	SYMSIZE	4
sgio3:	.ascii	"gio3"

	SYMSIZE	4
sgio4:	.ascii	"gio4"

	SYMSIZE	4
sgio5:	.ascii	"gio5"

	SYMSIZE	4
sgio6:	.ascii	"gio6"

	SYMSIZE	4
sgio7:	.ascii	"gio7"

	SYMSIZE	4
stmr0:	.ascii	"tmr0"

	SYMSIZE	4
stmr1:	.ascii	"tmr1"

	SYMSIZE	4
suar0:	.ascii	"uar0"

	SYMSIZE	4
s_i2c0:	.ascii	"i2c0"

	SYMSIZE	4
sadc0:	.ascii	"adc0"

	SYMSIZE	3
smci:	.ascii	"mci"

	SYMSIZE	4
sgdma:	.ascii	"gdma"

	SYMSIZE	3
slcd:	.ascii	"lcd"

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

	SYMSIZE	10
scfgpn:	.ascii	"config-pin"

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
	




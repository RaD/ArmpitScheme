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
	
	.word	sVIC,	(int_en_base >> 2)|i0	@ VIC  <- 0xe000e100 (int enab)
	.word	srtc0,	(rtc0_base   >> 2)|i0	@ rtc0
	.word	sgio0,	(0    << 2) | i0	@ gio0
	.word	sgio1,	(1    << 2) | i0	@ gio1
	.word	sgio2,	(2    << 2) | i0	@ gio2
	.word	sgio3,	(3    << 2) | i0	@ gio3
	.word	sgio4,	(4    << 2) | i0	@ gio4
	.word	sgio5,	(5    << 2) | i0	@ gio5
	.word	sgio6,	(6    << 2) | i0	@ gio6
	.word	sgio7,	(7    << 2) | i0	@ gio7
	.word	stmr0,	(timer0_base >> 2)|i0	@ tmr0
	.word	stmr1,	(timer1_base >> 2)|i0	@ tmr1
	.word	suar0,	(uart0_base  >> 2)|i0	@ uar0
	.word	suar1,	(uart1_base  >> 2)|i0	@ uar1
	.word	spwm1,	(pwm1_base   >> 2)|i0	@ pwm1
	.word	s_i2c0,	(i2c0_base   >> 2)|i0	@ i2c0
	.word	s_i2c1,	(i2c1_base   >> 2)|i0	@ i2c1
	.word	sspi0,	(spi0_base   >> 2)|i0	@ spi0
	.word	sspi1,	(spi1_base   >> 2)|i0	@ spi1
	.word	sadc0,	(adc0_base   >> 2)|i0	@ adc0
	.word	smmc,	(mmc_base    >> 2)|i0	@ mmc

	@-------.-------.-------.-------.-------+
	@	utility functions (system 0)	|
	@-------.-------.-------.-------.-------+

	DPFUNC	svmsr,  pvmsr,	1		@ vmsr
	DPFUNC	svmrs,  pvmrs,	0		@ vmrs
	DPFUNC	scfgpn, pcfgpn,	3		@ config-pin
	DPFUNC	spstdr, ppstdr,	3		@ pin-set-dir
	DPFUNC	spnset, ppnset,	2		@ pin-set
	DPFUNC	spnclr, ppnclr,	2		@ pin-clear
	DPFUNC	spnstq, ppnstq,	2		@ pin-set?
	DPFUNC	ststrt, ptstrt,	1		@ tic-start (systick timer)
	DPFUNC	ststop, ptstop,	0		@ tic-stop  (systick timer)
	DPFUNC	stkred, ptkred,	0		@ tic-read  (systick timer)
	.word	sspput, pspput			@ spi-put
	.word	sspget, pspget			@ spi-get
	DPFUNC	ssdgb, 	psdgb,	1		@ sdgb
	DPFUNC	ssdpb, 	psdpb,	2		@ sdpb

end_of_s0_env:	@ end of system 0 env vector
	

/*------------------------------------------------------------------------------
@  register address bindings -- names
@-----------------------------------------------------------------------------*/

	SYMSIZE	3
sVIC:	.ascii	"VIC"

	SYMSIZE	4
spsl0:	.ascii	"psl0"

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
suar1:	.ascii	"uar1"

	SYMSIZE	4
spwm1:	.ascii	"pwm1"

	SYMSIZE	4
s_i2c0:	.ascii	"i2c0"

	SYMSIZE	4
s_i2c1:	.ascii	"i2c1"

	SYMSIZE	4
sspi0:	.ascii	"spi0"

	SYMSIZE	4
sspi1:	.ascii	"spi1"

	SYMSIZE	4
sadc0:	.ascii	"adc0"

	SYMSIZE	4
spmd0:	.ascii	"pmd0"

	SYMSIZE	3
smmc:	.ascii	"mmc"
	
/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

	SYMSIZE	4
ssdgb:	.ascii	"sdgb"
	
	SYMSIZE	4
ssdpb:	.ascii	"sdpb"
	
	SYMSIZE	4
svmsr:	.ascii	"vmsr"
	
	SYMSIZE	4
svmrs:	.ascii	"vmrs"
	
	SYMSIZE	10
scfgpn:	.ascii	"config-pin"
	
	SYMSIZE	11
spstdr:	.ascii	"pin-set-dir"
	
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
	





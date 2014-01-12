/*------------------------------------------------------------------------------
@
@  ARMPIT SCHEME Version 060
@
@  ARMPIT SCHEME is distributed under The MIT License.

@  Copyright (c) 2012-2013 Petr Cermak

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

	.word	s_rcc,	(rcc_base     >> 2) | i0	@ rcc  <- rcc base
	.word	sgioa,	(ioporta_base >> 2) | i0	@ gioa
	.word	sgiob,	(ioportb_base >> 2) | i0	@ giob
	.word	sgioc,	(ioportc_base >> 2) | i0	@ gioc
	.word	sgiod,	(ioportd_base >> 2) | i0	@ giod
	.word	sgioe,	(ioporte_base >> 2) | i0	@ gioe
	.word	sgiof,	(ioportf_base >> 2) | i0	@ giof
	.word	sgiog,	(ioportg_base >> 2) | i0	@ giog
	.word	sgioh,	(ioporth_base >> 2) | i0	@ gioh
	.word	sgioi,	(ioporti_base >> 2) | i0	@ gioi
	.word	stmr1,	(timer1_base_a  >> 2) | i0	@ tmr1
	.word	stmr2,	(timer2_base  >> 2) | i0	@ tmr2 (armpit timer 0 w/r interrupts)
	.word	stmr3,	(timer3_base  >> 2) | i0	@ tmr3 (armpit timer 1 w/r interrupts)
	.word	stmr4,	(timer4_base  >> 2) | i0	@ tmr4
	.word	stmr5,	(timer5_base  >> 2) | i0	@ tmr5
	.word	stmr6,	(timer6_base  >> 2) | i0	@ tmr6
	.word	stmr7,	(timer7_base  >> 2) | i0	@ tmr7
	.word	stmr8,	(timer8_base  >> 2) | i0	@ tmr8
	.word	stmr9,	(timer9_base  >> 2) | i0	@ tmr9
	.word	stmr10,	(timer10_base >> 2) | i0	@ tmr10
	.word	stmr11,	(timer11_base >> 2) | i0	@ tmr11
	.word	stmr12,	(timer12_base >> 2) | i0	@ tmr12
	.word	stmr13,	(timer13_base >> 2) | i0	@ tmr13
	.word	stmr14,	(timer14_base >> 2) | i0	@ tmr14
	.word	suar1,	(uart0_base   >> 2) | i0	@ uar1 (USART1, armpit UAR0 port)
	.word	suar2,	(uart1_base   >> 2) | i0	@ uar2 (USART2, armpit UAR1 port)
	.word	s_i2c1,	(i2c0_base    >> 2) | i0	@ i2c1 (armpit I2C0 port)
	.word	s_i2c2,	(i2c1_base    >> 2) | i0	@ i2c2 (armpit I2C1 port)
	.word	sspi1,	(spi1_base    >> 2) | i0	@ spi1
	.word	sspi2,	(spi2_base    >> 2) | i0	@ spi2
	.word	sspi3,	(spi3_base    >> 2) | i0	@ spi3
	.word	sadc1,	(adc1_base    >> 2) | i0	@ adc1
	.word	sadc2,	(adc2_base    >> 2) | i0	@ adc2
	.word	sadc3,	(adc3_base    >> 2) | i0	@ adc3
	.word	s_sdio,	(sdio_base    >> 2) | i0	@ sdio
	.word	s_fsmc,	(fsmc_base    >> 2) | i0	@ fsmc
	.word	s_afm,	(afm_base     >> 2) | i0	@ afm

	@-------.-------.-------.-------.-------+
	@	utility functions (system 0)	|
	@-------.-------.-------.-------.-------+

	DPFUNC	scfpwr, pcfpwr,	3		@ config-power
	DPFUNC	scfgpn, pcfgpn,	4		@ config-pin
	DPFUNC	scfppp, pcfppp,	4		@ config-pin-pp
	DPFUNC	scfafm, pcfafm,	3		@ config-afm
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
sgioi:	.ascii	"gioi"

	SYMSIZE	4
stmr1:	.ascii	"tmr1"

	SYMSIZE	4
stmr2:	.ascii	"tmr2"

	SYMSIZE	4
stmr3:	.ascii	"tmr3"

	SYMSIZE	4
stmr4:	.ascii	"tmr4"

	SYMSIZE	4
stmr5:	.ascii	"tmr5"

	SYMSIZE	4
stmr6:	.ascii	"tmr6"

	SYMSIZE	4
stmr7:	.ascii	"tmr7"

	SYMSIZE	4
stmr8:	.ascii	"tmr8"

	SYMSIZE	4
stmr9:	.ascii	"tmr9"

	SYMSIZE	5
stmr10:	.ascii	"tmr10"

	SYMSIZE	5
stmr11:	.ascii	"tmr11"

	SYMSIZE	5
stmr12:	.ascii	"tmr12"

	SYMSIZE	5
stmr13:	.ascii	"tmr13"

	SYMSIZE	5
stmr14:	.ascii	"tmr14"

	SYMSIZE	4
suar1:	.ascii	"uar1"

	SYMSIZE	4
suar2:	.ascii	"uar2"

	SYMSIZE	4
s_i2c1:	.ascii	"i2c1"

	SYMSIZE	4
s_i2c2:	.ascii	"i2c2"

	SYMSIZE	4
sspi1:	.ascii	"spi1"

	SYMSIZE	4
sspi2:	.ascii	"spi2"

	SYMSIZE	4
sspi3:	.ascii	"spi3"

	SYMSIZE	4
sadc1:	.ascii	"adc1"

	SYMSIZE	4
sadc2:	.ascii	"adc2"

	SYMSIZE	4
sadc3:	.ascii	"adc3"

	SYMSIZE	4
s_sdio:	.ascii	"sdio"

	SYMSIZE	4
s_fsmc:	.ascii	"fsmc"

	SYMSIZE	3
s_afm:	.ascii	"afm"

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

	SYMSIZE	12
scfpwr:	.ascii	"config-power"

	SYMSIZE	10
scfgpn:	.ascii	"config-pin"

	SYMSIZE	13
scfppp: .ascii	"config-pin-pp"

	SYMSIZE	10
scfafm: .ascii	"config-afm"

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









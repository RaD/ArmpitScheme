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
	
	.word	scorcm,	(CORE_CM_base >> 2) | i0	@ core_cm 
	.word	swkpcm,	(WKUP_CM_base >> 2) | i0	@ wkup_cm 
	.word	spercm,	(PER_CM_base  >> 2) | i0	@ per_cm 
	.word	ssysc,	(SCM_base     >> 2) | i0	@ sysc <- SCM
	.word	sVIC,	(int_base     >> 2) | i0	@ VIC
	.word	sgio1,	(io1_base     >> 2) | i0	@ gio1
	.word	sgio2,	(io2_base     >> 2) | i0	@ gio2
	.word	sgio3,	(io3_base     >> 2) | i0	@ gio3
	.word	sgio4,	(io4_base     >> 2) | i0	@ gio4
	.word	sgio5,	(io5_base     >> 2) | i0	@ gio5
	.word	sgio6,	(io6_base     >> 2) | i0	@ gio6
	.word	stmr1,	(timer0_base  >> 2) | i0	@ tmr1 <- timer int in core
	.word	stmr2,	(timer2_base  >> 2) | i0	@ tmr2 <- timer int in core
	.word	stmr3,	(timer3_base  >> 2) | i0	@ tmr3
	.word	stmr4,	(timer4_base  >> 2) | i0	@ tmr4
	.word	stmr5,	(timer5_base  >> 2) | i0	@ tmr5
	.word	stmr6,	(timer6_base  >> 2) | i0	@ tmr6
	.word	stmr7,	(timer7_base  >> 2) | i0	@ tmr7
	.word	stmr8,	(timer8_base  >> 2) | i0	@ tmr8
	.word	stmr9,	(timer9_base  >> 2) | i0	@ tmr9
	.word	stmr10,	(timer10_base >> 2) | i0	@ tmr10
	.word	stmr11,	(timer11_base >> 2) | i0	@ tmr11
	.word	suar0,	(uart0_base   >> 2) | i0	@ uar0 <- UART3 aka UAR0/1
	.word	suar3,	(uart0_base   >> 2) | i0	@ uar3 <- UART3 aka UAR0/1
	.word	s_i2c0,	(i2c0_base    >> 2) | i0	@ i2c0 <- I2C1 (set in OMAP_35xx.h)
	.word	s_i2c1,	(i2c1_base    >> 2) | i0	@ i2c1 <- I2C1
	.word	sspi1,	(spi1_base    >> 2) | i0	@ spi1
	.word	sspi2,	(spi2_base    >> 2) | i0	@ spi2
	.word	sspi3,	(spi3_base    >> 2) | i0	@ spi3
	.word	sspi4,	(spi4_base    >> 2) | i0	@ spi4
	.word	smci,	(mmc1_base    >> 2) | i0	@ mci <- MMC1

	@-------.-------.-------.-------.-------+
	@	utility functions (system 0)	|
	@-------.-------.-------.-------.-------+

	.word	scfpwr, pcfpwr			@ config-power
	DPFUNC	scfgpd, pcfgpd,	2		@ config-pad
	.word	spstdr, ppstdr			@ pin-set-dir
	.word	spnset, ppnset			@ pin-set
	.word	spnclr, ppnclr			@ pin-clear
	.word	spnstq, ppnstq			@ pin-set?
	.word	ststrt, ptstrt			@ restart (timer)
	.word	ststop, ptstop			@ stop (timer)
	.word	si2crs, pi2crs			@ i2c-reset
	DPFUNC	si2crx, pi2crx,	3		@ i2c-read
	DPFUNC	si2ctx, pi2ctx,	1		@ i2c-write
	.word	s_rd16, p_rd16			@ rd16
	DPFUNC	s_wr16, p_wr16,	3		@ wr16
	DPFUNC	s_sgb,	p_sgb,	1		@ _sgb
	DPFUNC	s_spb,	p_spb,	2		@ _spb
	

end_of_s0_env:	@ end of system 0 env vector


/*------------------------------------------------------------------------------
@  register address bindings -- names
@-----------------------------------------------------------------------------*/

	SYMSIZE	4
ssysc:	.ascii	"sysc"

	SYMSIZE	3
sVIC:	.ascii	"VIC"

	SYMSIZE	7
scorcm:	.ascii	"core_cm"

	SYMSIZE	7
swkpcm:	.ascii	"wkup_cm"

	SYMSIZE	6
spercm:	.ascii	"per_cm"

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

	SYMSIZE	4
suar0:	.ascii	"uar0"

	SYMSIZE	4
suar3:	.ascii	"uar3"

	SYMSIZE	4
s_i2c0:	.ascii	"i2c0"

	SYMSIZE	4
s_i2c1:	.ascii	"i2c1"

	SYMSIZE	4
sspi1:	.ascii	"spi1"

	SYMSIZE	4
sspi2:	.ascii	"spi2"

	SYMSIZE	4
sspi3:	.ascii	"spi3"

	SYMSIZE	4
sspi4:	.ascii	"spi4"

	SYMSIZE	3
smci:	.ascii	"mci"

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/
	
	SYMSIZE	12
scfpwr:	.ascii	"config-power"
	
	SYMSIZE	10
scfgpd:	.ascii	"config-pad"
	
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
	
	SYMSIZE	9
si2crs:	.ascii	"i2c-reset"

	SYMSIZE	8
si2crx:	.ascii	"i2c-read"

	SYMSIZE	9
si2ctx:	.ascii	"i2c-write"

	SYMSIZE	4
s_rd16:	.ascii	"rd16"

	SYMSIZE	4
s_wr16:	.ascii	"wr16"

	SYMSIZE	4
s_sgb:	.ascii	"_sgb"

	SYMSIZE	4
s_spb:	.ascii	"_spb"






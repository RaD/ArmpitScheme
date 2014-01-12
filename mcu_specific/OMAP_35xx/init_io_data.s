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


	VECSIZE	num_interrupts

ISR_vector:

	.word	i0			@ 0
	.word	i0			@ 1
	.word	i0			@ 2
	.word	i0			@ 3
	.word	i0			@ 4
	.word	i0			@ 5
	.word	i0			@ 6
	.word	i0			@ 7
	.word	i0			@ 8
	.word	i0			@ 9
	.word	i0			@ 10
	.word	i0			@ 11
	.word	i0			@ 12
	.word	i0			@ 13
	.word	i0			@ 14
	.word	i0			@ 15
	.word	i0			@ 16
	.word	i0			@ 17
	.word	i0			@ 18
	.word	i0			@ 19
	.word	i0			@ 20
	.word	i0			@ 21
	.word	i0			@ 22
	.word	i0			@ 23
	.word	i0			@ 24
	.word	i0			@ 25
	.word	i0			@ 26
	.word	i0			@ 27
	.word	i0			@ 28
	.word	i0			@ 29
	.word	i0			@ 30
	.word	i0			@ 31
	.word	i0			@ 32
	.word	i0			@ 33
	.word	i0			@ 34
	.word	i0			@ 35
	.word	i0			@ 36
	UPFUNC	ptmisr,	0		@ 37:	timer0
	UPFUNC	ptmisr,	0		@ 38:	timer1
	.word	i0			@ 39
	.word	i0			@ 40
	.word	i0			@ 41
	.word	i0			@ 42
	.word	i0			@ 43
	.word	i0			@ 44
	.word	i0			@ 45
	.word	i0			@ 46
	.word	i0			@ 47
	.word	i0			@ 48
	.word	i0			@ 49
	.word	i0			@ 50
	.word	i0			@ 51
	.word	i0			@ 52
	.word	i0			@ 53
	.word	i0			@ 54
	.word	i0			@ 55
	UPFUNC	pi2isr,	0		@ 56:	i2c0 (if included)
	UPFUNC	pi2isr,	0		@ 57:	i2c1 (if included)
	.word	i0			@ 58
	.word	i0			@ 59
	.word	i0			@ 60
	.word	i0			@ 61
	.word	i0			@ 62
	.word	i0			@ 63
	.word	i0			@ 64
	.word	i0			@ 65
	.word	i0			@ 66
	.word	i0			@ 67
	.word	i0			@ 68
	.word	i0			@ 69
	.word	i0			@ 70
	.word	i0			@ 71
	.word	i0			@ 72
	.word	i0			@ 73
	UPFUNC	puaisr,	0		@ 74:	uart0/1
	.word	i0			@ 75
	.word	i0			@ 76
	.word	i0			@ 77
	.word	i0			@ 78
	.word	i0			@ 79
	.word	i0			@ 80
	.word	i0			@ 81
	.word	i0			@ 82
	.word	i0			@ 83
	.word	i0			@ 84
	.word	i0			@ 85
	.word	i0			@ 86
	.word	i0			@ 87
	.word	i0			@ 88
	.word	i0			@ 89
	.word	i0			@ 90
	.word	i0			@ 91
	UPFUNC	usbisr,	0		@ 92:	USB - no DMA (if included)
	UPFUNC	usbisr,	0		@ 93:	USB - DMA (if included)
	.word	i0			@ 94
	.word	i0			@ 95


@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

.ifndef	live_SD
	

.ifdef TI_Beagle
flashsectors:	@ 256 x 128KB RAM Blocks shadowing file FLASH (top 32MB) of Micron MT29F2G16ABC on board
.word	0x86000000, 0x86020000,  0x86040000,  0x86060000,  0x86080000,  0x860A0000,  0x860C0000,  0x860E0000
.word	0x86100000, 0x86120000,  0x86140000,  0x86160000,  0x86180000,  0x861A0000,  0x861C0000,  0x861E0000
.word	0x86200000, 0x86220000,  0x86240000,  0x86260000,  0x86280000,  0x862A0000,  0x862C0000,  0x862E0000
.word	0x86300000, 0x86320000,  0x86340000,  0x86360000,  0x86380000,  0x863A0000,  0x863C0000,  0x863E0000
.word	0x86400000, 0x86420000,  0x86440000,  0x86460000,  0x86480000,  0x864A0000,  0x864C0000,  0x864E0000
.word	0x86500000, 0x86520000,  0x86540000,  0x86560000,  0x86580000,  0x865A0000,  0x865C0000,  0x865E0000
.word	0x86600000, 0x86620000,  0x86640000,  0x86660000,  0x86680000,  0x866A0000,  0x866C0000,  0x866E0000
.word	0x86700000, 0x86720000,  0x86740000,  0x86760000,  0x86780000,  0x867A0000,  0x867C0000,  0x867E0000
.word	0x86800000, 0x86820000,  0x86840000,  0x86860000,  0x86880000,  0x868A0000,  0x868C0000,  0x868E0000
.word	0x86900000, 0x86920000,  0x86940000,  0x86960000,  0x86980000,  0x869A0000,  0x869C0000,  0x869E0000
.word	0x86A00000, 0x86a20000,  0x86a40000,  0x86a60000,  0x86a80000,  0x86aA0000,  0x86aC0000,  0x86aE0000
.word	0x86B00000, 0x86b20000,  0x86b40000,  0x86b60000,  0x86b80000,  0x86bA0000,  0x86bC0000,  0x86bE0000
.word	0x86C00000, 0x86c20000,  0x86c40000,  0x86c60000,  0x86c80000,  0x86cA0000,  0x86cC0000,  0x86cE0000
.word	0x86D00000, 0x86d20000,  0x86d40000,  0x86d60000,  0x86d80000,  0x86dA0000,  0x86dC0000,  0x86dE0000
.word	0x86E00000, 0x86e20000,  0x86e40000,  0x86e60000,  0x86e80000,  0x86eA0000,  0x86eC0000,  0x86eE0000
.word	0x86F00000, 0x86f20000,  0x86f40000,  0x86f60000,  0x86f80000,  0x86fA0000,  0x86fC0000,  0x86fE0000
.word	0x87000000, 0x87020000,  0x87040000,  0x87060000,  0x87080000,  0x870A0000,  0x870C0000,  0x870E0000
.word	0x87100000, 0x87120000,  0x87140000,  0x87160000,  0x87180000,  0x871A0000,  0x871C0000,  0x871E0000
.word	0x87200000, 0x87220000,  0x87240000,  0x87260000,  0x87280000,  0x872A0000,  0x872C0000,  0x872E0000
.word	0x87300000, 0x87320000,  0x87340000,  0x87360000,  0x87380000,  0x873A0000,  0x873C0000,  0x873E0000
.word	0x87400000, 0x87420000,  0x87440000,  0x87460000,  0x87480000,  0x874A0000,  0x874C0000,  0x874E0000
.word	0x87500000, 0x87520000,  0x87540000,  0x87560000,  0x87580000,  0x875A0000,  0x875C0000,  0x875E0000
.word	0x87600000, 0x87620000,  0x87640000,  0x87660000,  0x87680000,  0x876A0000,  0x876C0000,  0x876E0000
.word	0x87700000, 0x87720000,  0x87740000,  0x87760000,  0x87780000,  0x877A0000,  0x877C0000,  0x877E0000
.word	0x87800000, 0x87820000,  0x87840000,  0x87860000,  0x87880000,  0x878A0000,  0x878C0000,  0x878E0000
.word	0x87900000, 0x87920000,  0x87940000,  0x87960000,  0x87980000,  0x879A0000,  0x879C0000,  0x879E0000
.word	0x87A00000, 0x87a20000,  0x87a40000,  0x87a60000,  0x87a80000,  0x87aA0000,  0x87aC0000,  0x87aE0000
.word	0x87B00000, 0x87b20000,  0x87b40000,  0x87b60000,  0x87b80000,  0x87bA0000,  0x87bC0000,  0x87bE0000
.word	0x87C00000, 0x87c20000,  0x87c40000,  0x87c60000,  0x87c80000,  0x87cA0000,  0x87cC0000,  0x87cE0000
.word	0x87D00000, 0x87d20000,  0x87d40000,  0x87d60000,  0x87d80000,  0x87dA0000,  0x87dC0000,  0x87dE0000
.word	0x87E00000, 0x87e20000,  0x87e40000,  0x87e60000,  0x87e80000,  0x87eA0000,  0x87eC0000,  0x87eE0000
.word	0x87F00000, 0x87f20000,  0x87f40000,  0x87f60000,  0x87f80000,  0x87fA0000,  0x87fC0000,  0x87fE0000
.word	0x88000000
.endif	@ .ifdef TI_Beagle


.endif	@ .ifndef live_SD

	



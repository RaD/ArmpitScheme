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

	.word	i0			@  0
	UPFUNC	puaisr,	0		@  1:	DBGU - debug UART (for debug only)
	.word	i0			@  2
	.word	i0			@  3
	.word	i0			@  4
	.word	i0			@  5
	UPFUNC	puaisr,	0		@  6:	uart0
	UPFUNC	puaisr,	0		@  7:	uart1
	.word	i0			@  8
	.word	i0			@  9
	UPFUNC	usbisr,	0		@ 10:	UDP / USB (if included)
	UPFUNC	pi2isr,	0		@ 11:	i2c0 / i2c1 (if included)
	.word	i0			@ 12
	.word	i0			@ 13
	.word	i0			@ 14
	.word	i0			@ 15
	.word	i0			@ 16
	UPFUNC	ptmisr,	0		@ 17:	timer0
	UPFUNC	ptmisr,	0		@ 18:	timer1
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



flashsectors:	@ 128 x 128KB RAM Blocks shadowing file FLASH (top 16 MB) of Samsung K9F4G08UOA
.word	0x23000000, 0x23020000,  0x23040000,  0x23060000,  0x23080000,  0x230A0000,  0x230C0000,  0x230E0000
.word	0x23100000, 0x23120000,  0x23140000,  0x23160000,  0x23180000,  0x231A0000,  0x231C0000,  0x231E0000
.word	0x23200000, 0x23220000,  0x23240000,  0x23260000,  0x23280000,  0x232A0000,  0x232C0000,  0x232E0000
.word	0x23300000, 0x23320000,  0x23340000,  0x23360000,  0x23380000,  0x233A0000,  0x233C0000,  0x233E0000
.word	0x23400000, 0x23420000,  0x23440000,  0x23460000,  0x23480000,  0x234A0000,  0x234C0000,  0x234E0000
.word	0x23500000, 0x23520000,  0x23540000,  0x23560000,  0x23580000,  0x235A0000,  0x235C0000,  0x235E0000
.word	0x23600000, 0x23620000,  0x23640000,  0x23660000,  0x23680000,  0x236A0000,  0x236C0000,  0x236E0000
.word	0x23700000, 0x23720000,  0x23740000,  0x23760000,  0x23780000,  0x237A0000,  0x237C0000,  0x237E0000
.word	0x23800000, 0x23820000,  0x23840000,  0x23860000,  0x23880000,  0x238A0000,  0x238C0000,  0x238E0000
.word	0x23900000, 0x23920000,  0x23940000,  0x23960000,  0x23980000,  0x239A0000,  0x239C0000,  0x239E0000
.word	0x23A00000, 0x23a20000,  0x23a40000,  0x23a60000,  0x23a80000,  0x23aA0000,  0x23aC0000,  0x23aE0000
.word	0x23B00000, 0x23b20000,  0x23b40000,  0x23b60000,  0x23b80000,  0x23bA0000,  0x23bC0000,  0x23bE0000
.word	0x23C00000, 0x23c20000,  0x23c40000,  0x23c60000,  0x23c80000,  0x23cA0000,  0x23cC0000,  0x23cE0000
.word	0x23D00000, 0x23d20000,  0x23d40000,  0x23d60000,  0x23d80000,  0x23dA0000,  0x23dC0000,  0x23dE0000
.word	0x23E00000, 0x23e20000,  0x23e40000,  0x23e60000,  0x23e80000,  0x23eA0000,  0x23eC0000,  0x23eE0000
.word	0x23F00000, 0x23f20000,  0x23f40000,  0x23f60000,  0x23f80000,  0x23fA0000,  0x23fC0000,  0x23fE0000
.word	0x24000000



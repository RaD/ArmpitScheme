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
	.word	i0			@  1
	.word	i0			@  2
	.word	i0			@  3
	UPFUNC	ptmisr,	0		@  4:	timer0
	UPFUNC	ptmisr,	0		@  5:	timer1
	.word	i0			@  6
	.word	i0			@  7
	.word	i0			@  8
	.word	i0			@  9
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
	UPFUNC	puaisr,	0		@ 23:	uart0
	.word	i0			@ 24
	UPFUNC	puaisr,	0		@ 25:	uart1
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
	.word	i0			@ 37
	.word	i0			@ 38
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
	.word	i0			@ 56
	.word	i0			@ 57
	.word	i0			@ 58
	.word	i0			@ 59
	.word	i0			@ 60
	.word	i0			@ 61
	.word	i0			@ 62
	UPFUNC	pi2isr,	0		@ 63:	i2c0/1 (if included)


@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@


.ifdef CS_E9302
flashsectors:	@ 128 x 128KB FLASH sectors of Intel JS28F128 J3D75 on CS-EP9302 board
.word	0x60000000, 0x60020000,  0x60040000,  0x60060000,  0x60080000,  0x600A0000,  0x600C0000,  0x600E0000
.word	0x60100000, 0x60120000,  0x60140000,  0x60160000,  0x60180000,  0x601A0000,  0x601C0000,  0x601E0000
.word	0x60200000, 0x60220000,  0x60240000,  0x60260000,  0x60280000,  0x602A0000,  0x602C0000,  0x602E0000
.word	0x60300000, 0x60320000,  0x60340000,  0x60360000,  0x60380000,  0x603A0000,  0x603C0000,  0x603E0000
.word	0x60400000, 0x60420000,  0x60440000,  0x60460000,  0x60480000,  0x604A0000,  0x604C0000,  0x604E0000
.word	0x60500000, 0x60520000,  0x60540000,  0x60560000,  0x60580000,  0x605A0000,  0x605C0000,  0x605E0000
.word	0x60600000, 0x60620000,  0x60640000,  0x60660000,  0x60680000,  0x606A0000,  0x606C0000,  0x606E0000
.word	0x60700000, 0x60720000,  0x60740000,  0x60760000,  0x60780000,  0x607A0000,  0x607C0000,  0x607E0000
.word	0x60800000, 0x60820000,  0x60840000,  0x60860000,  0x60880000,  0x608A0000,  0x608C0000,  0x608E0000
.word	0x60900000, 0x60920000,  0x60940000,  0x60960000,  0x60980000,  0x609A0000,  0x609C0000,  0x609E0000
.word	0x60A00000, 0x60a20000,  0x60a40000,  0x60a60000,  0x60a80000,  0x60aA0000,  0x60aC0000,  0x60aE0000
.word	0x60B00000, 0x60b20000,  0x60b40000,  0x60b60000,  0x60b80000,  0x60bA0000,  0x60bC0000,  0x60bE0000
.word	0x60C00000, 0x60c20000,  0x60c40000,  0x60c60000,  0x60c80000,  0x60cA0000,  0x60cC0000,  0x60cE0000
.word	0x60D00000, 0x60d20000,  0x60d40000,  0x60d60000,  0x60d80000,  0x60dA0000,  0x60dC0000,  0x60dE0000
.word	0x60E00000, 0x60e20000,  0x60e40000,  0x60e60000,  0x60e80000,  0x60eA0000,  0x60eC0000,  0x60eE0000
.word	0x60F00000, 0x60f20000,  0x60f40000,  0x60f60000,  0x60f80000,  0x60fA0000,  0x60fC0000,  0x60fE0000
.word	0x61000000
.endif	@ .ifdef CS_E9302
	


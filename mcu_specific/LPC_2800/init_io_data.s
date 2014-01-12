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
	.word	i0			@  4
	UPFUNC	ptmisr,	0		@  5:	timer0
	UPFUNC	ptmisr,	0		@  6:	timer1
	.word	i0			@  7
	.word	i0			@  8
	.word	i0			@  9
	.word	i0			@ 10
	.word	i0			@ 11
	UPFUNC	puaisr,	0		@ 12:	uart0/1
	UPFUNC	pi2isr,	0		@ 13:	i2c0/1 (if included)
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
	UPFUNC	usbisr,	0		@ 26:	USB (if included)
	UPFUNC	usbisr,	0		@ 27:	USB (if included)
	UPFUNC	usbisr,	0		@ 28:	USB (if included)
	UPFUNC	usbisr,	0		@ 29:	USB (if included)
	.word	i0			@ 30
	.word	i0			@ 31


@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@


.ifdef LPC_H2888
flashsectors:	@ 8 x 8KB + 31 x 64KB FLASH sectors of Intel JS28F160C3-BD70 on LPC-H2888 board
.word	0x20000000, 0x20002000, 0x20004000, 0x20006000, 0x20008000, 0x2000A000, 0x2000C000, 0x2000E000
.word	0x20010000, 0x20020000, 0x20030000, 0x20040000, 0x20050000, 0x20060000, 0x20070000, 0x20080000
.word	0x20090000, 0x200A0000, 0x200B0000, 0x200C0000, 0x200D0000, 0x200E0000, 0x200F0000, 0x20100000
.word	0x20110000, 0x20120000, 0x20130000, 0x20140000, 0x20150000, 0x20160000, 0x20170000, 0x20180000
.word	0x20190000, 0x201A0000, 0x201B0000, 0x201C0000, 0x201D0000, 0x201E0000, 0x201F0000, 0x20200000
.endif






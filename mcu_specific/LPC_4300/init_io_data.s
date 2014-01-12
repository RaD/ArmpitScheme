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
	.word	i0			@  5
	.word	i0			@  6
	.word	i0			@  7
	UPFUNC	usbisr,	0		@  8:	USB-0 (if included)
	.word	i0			@  9
	.word	i0			@ 10
	.word	i0			@ 11
	UPFUNC	ptmisr,	0		@ 12:	timer0
	UPFUNC	ptmisr,	0		@ 13:	timer1
	.word	i0			@ 14
	.word	i0			@ 15
	.word	i0			@ 16
	.word	i0			@ 17
	UPFUNC	pi2isr,	0		@ 18:	i2c0 (if included)
	UPFUNC	pi2isr,	0		@ 19:	i2c1 (if included)
	.word	i0			@ 20
	.word	i0			@ 21
	.word	i0			@ 22
	.word	i0			@ 23
	UPFUNC	puaisr,	0		@ 24:	uart0
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
	.word	i0			@ 53 - extra
	.word	i0			@ 54 - extra
	.word	i0			@ 55 - extra
	.word	i0			@ 56 - extra
	.word	i0			@ 57 - extra
	.word	i0			@ 58 - extra
	.word	i0			@ 59 - extra
	.word	i0			@ 60 - extra
	.word	i0			@ 61 - extra
	.word	i0			@ 62 - extra
	.word	i0			@ 63 - extra

	
/*------------------------------------------------------------------------------
@
@    FLASH I/O:	Internal Flash
@
@-----------------------------------------------------------------------------*/


.ifdef LPC4330_Xplorer
.balign	4
flashsectors:	@ 64 x 64KB sectors of SPIFI FLASH: SPANSION S25FL032P
.ifdef	SHARED_LIB_FILE
lib_sectors:	@ lib shares on-chip file flash
.endif
.word	0x14000000, 0x14010000, 0x14020000, 0x14030000, 0x14040000, 0x14050000, 0x14060000, 0x14070000
.word	0x14080000, 0x14090000, 0x140A0000, 0x140B0000, 0x140C0000, 0x1405D000, 0x140E0000, 0x140F0000
.word	0x14100000, 0x14110000, 0x14120000, 0x14130000, 0x14140000, 0x14150000, 0x14160000, 0x14170000
.word	0x14180000, 0x14190000, 0x141A0000, 0x141B0000, 0x141C0000, 0x1415D000, 0x141E0000, 0x141F0000
.word	0x14200000, 0x14210000, 0x14220000, 0x14230000, 0x14240000, 0x14250000, 0x14260000, 0x14270000
.word	0x14280000, 0x14290000, 0x142A0000, 0x142B0000, 0x142C0000, 0x1425D000, 0x142E0000, 0x142F0000
.word	0x14300000, 0x14310000, 0x14320000, 0x14330000, 0x14340000, 0x14350000, 0x14360000, 0x14370000
.word	0x14380000, 0x14390000, 0x143A0000, 0x143B0000, 0x143C0000, 0x1435D000, 0x143E0000, 0x143F0000
.word	0x14400000, 0x14ffffff
.endif	@ .ifdef LPC4330_Xplorer



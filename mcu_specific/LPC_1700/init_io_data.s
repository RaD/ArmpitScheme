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
	UPFUNC	ptmisr,	0		@  1:	timer0
	UPFUNC	ptmisr,	0		@  2:	timer1
	.word	i0			@  3
	.word	i0			@  4
	UPFUNC	puaisr,	0		@  5:	uart0
	UPFUNC	puaisr,	0		@  6:	uart1
	.word	i0			@  7
	.word	i0			@  8
	.word	i0			@  9
	UPFUNC	pi2isr,	0		@ 10:	i2c0 (if included)
	UPFUNC	pi2isr,	0		@ 11:	i2c0 (if included)
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
	UPFUNC	usbisr,	0		@ 24:	USB (if included)
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
	.word	i0			@ 63

	
@---------------------------------------------------------------------------------------
@
@    FLASH I/O:	Internal Flash
@
@---------------------------------------------------------------------------------------


	
.ifdef Blueboard_1768
@
@ Note:	 on some LPC1768 hardware (week 11 to 34, 2010) the sector starting at 0x70000 cannot be written.
@
.balign	4
flashsectors:	@ 16 x 4KB, 14 x 32KB FLASH sectors of LPC1768
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x09000, 0x0A000, 0x0B000, 0x0C000, 0x0D000, 0x0E000, 0x0F000
.word	0x10000, 0x18000, 0x20000, 0x28000, 0x30000, 0x38000, 0x40000, 0x48000
.word	0x50000, 0x58000, 0x60000, 0x68000, 0x70000, 0x78000, 0x80000, 0x0FFFFFFC
.endif	@ .ifdef Blueboard_1768





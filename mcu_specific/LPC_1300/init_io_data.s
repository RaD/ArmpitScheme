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
	.word	i0			@ 37
	.word	i0			@ 38
	.word	i0			@ 39
	UPFUNC	pi2isr,	0		@ 40:	i2c0 (if included)
	UPFUNC	ptmisr,	0		@ 41:	timer0
	UPFUNC	ptmisr,	0		@ 42:	timer1
	.word	i0			@ 43
	.word	i0			@ 44
	.word	i0			@ 45
	UPFUNC	puaisr,	0		@ 46:	uart0
	UPFUNC	usbisr,	0		@ 47:	USB (if included)
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
	
/*----------------------------------------------------------------------------*\
*
*    FLASH I/O:	Internal Flash
*
\*----------------------------------------------------------------------------*/

.ifdef LPC_P1343
flashsectors:	@ 8 x 4KB FLASH sectors of LPC2131
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000, 0x08000, 0x0FFFFFFC
.endif	@ .ifdef LPC_P1343




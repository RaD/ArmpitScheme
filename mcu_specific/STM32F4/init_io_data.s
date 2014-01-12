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
	UPFUNC	ptmisr,	0		@ 24:	timer0
	.word	i0			@ 25
	.word	i0			@ 26
	.word	i0			@ 27
	UPFUNC	ptmisr,	0		@ 28:	timer1 (STM32 timer 2)
	.word	i0			@ 29:
	.word	i0			@ 30
	UPFUNC	pi2isr,	0		@ 31:	i2c0 (if included)
	.word	i0			@ 32
	UPFUNC	pi2isr,	0		@ 33:	i2c1 (if included)
	.word	i0			@ 34
	.word	i0			@ 35
	.word	i0			@ 36
	UPFUNC	puaisr,	0		@ 37:	uart0 (STM32 USART 1) (or uart1)
	UPFUNC	puaisr,	0		@ 38:	uart1 (STM32 USART 2) (or uart0)
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
	UPFUNC	ptmisr,	0		@ 50
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
	.word	i0			@ 64
	.word	i0			@ 65
	.word	i0			@ 66
	UPFUNC	usbisr,	0		@ 67:	USB OTG FS  (if included)
	.word	i0			@ 68
	.word	i0			@ 69
	.word	i0			@ 70
	.word	i0			@ 71
	.word	i0			@ 72
	.word	i0			@ 73
	.word	i0			@ 74
	.word	i0			@ 75
	.word	i0			@ 76
	.word	i0			@ 77
	.word	i0			@ 78
	.word	i0			@ 79
	.word	i0			@ 80
	.word	i0			@ 81



@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@


flashsectors:	@ 4 x 16KB, 1 x 64KB, 7 x 128 KB, FLASH sectors of STM32F4
lib_sectors:	@ lib shares on-chip file flash
.word	0x08000000, 0x08004000, 0x08008000, 0x0800C000, 0x08010000
.word	0x08020000, 0x08040000, 0x08060000, 0x08080000, 0x080A0000, 0x080C0000, 0x080E0000
.word	0x08100000, 0x08800000








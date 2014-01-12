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
	UPFUNC	puaisr,	0		@  5:	uart0
	UPFUNC	puaisr,	0		@  6:	uart1
	.word	i0			@  7
	UPFUNC	pi2isr,	0		@  8:	i2c0 (if included)
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
	UPFUNC	ptmisr,	0		@ 19:	timer0
	.word	i0			@ 20
	UPFUNC	ptmisr,	0		@ 21:	timer1
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
	UPFUNC	pi2isr,	0		@ 37:	i2c1 (if included)
	.word	i0			@ 38
	.word	i0			@ 39
	.word	i0			@ 40
	.word	i0			@ 41
	.word	i0			@ 42
	.word	i0			@ 43
	UPFUNC	usbisr,	0		@ 44:	USB OTG FS Device (if included)
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
	.word	i0			@ 74
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
	.word	i0			@ 92
	.word	i0			@ 93
	.word	i0			@ 94
	.word	i0			@ 95
	.word	i0			@ 96
	.word	i0			@ 97
	.word	i0			@ 98
	.word	i0			@ 99
	.word	i0			@ 100
	.word	i0			@ 101
	.word	i0			@ 102
	.word	i0			@ 103
	.word	i0			@ 104
	.word	i0			@ 105
	.word	i0			@ 106
	.word	i0			@ 107
	.word	i0			@ 108
	.word	i0			@ 109
	.word	i0			@ 110
	.word	i0			@ 111
	.word	i0			@ 112
	.word	i0			@ 113
	.word	i0			@ 114
	.word	i0			@ 115
	.word	i0			@ 116
	.word	i0			@ 117
	.word	i0			@ 118
	.word	i0			@ 119
	.word	i0			@ 120
	.word	i0			@ 121
	.word	i0			@ 122
	.word	i0			@ 123
	.word	i0			@ 124
	.word	i0			@ 125
	.word	i0			@ 126
	.word	i0			@ 127
	.word	i0			@ 128
	.word	i0			@ 129
	.word	i0			@ 130
	.word	i0			@ 131
	.word	i0			@ 132
	.word	i0			@ 133
	.word	i0			@ 134
	.word	i0			@ 135
	.word	i0			@ 136
	.word	i0			@ 137
	.word	i0			@ 138


@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@


.balign	4
flashsectors:	@ 128 x 2 KB FLASH sectors of LM4F232 and LM4F120
		@ (2KB accounts for Rev. A1-A2 silicon errata)
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000000, 0x00000800, 0x00001000, 0x00001800, 0x00002000, 0x00002800, 0x00003000, 0x00003800
.word	0x00004000, 0x00004800, 0x00005000, 0x00005800, 0x00006000, 0x00006800, 0x00007000, 0x00007800
.word	0x00008000, 0x00008800, 0x00009000, 0x00009800, 0x0000a000, 0x0000a800, 0x0000b000, 0x0000b800
.word	0x0000c000, 0x0000c800, 0x0000d000, 0x0000d800, 0x0000e000, 0x0000e800, 0x0000f000, 0x0000f800
.word	0x00010000, 0x00010800, 0x00011000, 0x00011800, 0x00012000, 0x00012800, 0x00013000, 0x00013800
.word	0x00014000, 0x00014800, 0x00015000, 0x00015800, 0x00016000, 0x00016800, 0x00017000, 0x00017800
.word	0x00018000, 0x00018800, 0x00019000, 0x00019800, 0x0001a000, 0x0001a800, 0x0001b000, 0x0001b800
.word	0x0001c000, 0x0001c800, 0x0001d000, 0x0001d800, 0x0001e000, 0x0001e800, 0x0001f000, 0x0001f800
.word	0x00020000, 0x00020800, 0x00021000, 0x00021800, 0x00022000, 0x00022800, 0x00023000, 0x00023800
.word	0x00024000, 0x00024800, 0x00025000, 0x00025800, 0x00026000, 0x00026800, 0x00027000, 0x00027800
.word	0x00028000, 0x00028800, 0x00029000, 0x00029800, 0x0002a000, 0x0002a800, 0x0002b000, 0x0002b800
.word	0x0002c000, 0x0002c800, 0x0002d000, 0x0002d800, 0x0002e000, 0x0002e800, 0x0002f000, 0x0002f800
.word	0x00030000, 0x00030800, 0x00031000, 0x00031800, 0x00032000, 0x00032800, 0x00033000, 0x00033800
.word	0x00034000, 0x00034800, 0x00035000, 0x00035800, 0x00036000, 0x00036800, 0x00037000, 0x00037800
.word	0x00038000, 0x00038800, 0x00039000, 0x00039800, 0x0003a000, 0x0003a800, 0x0003b000, 0x0003b800
.word	0x0003c000, 0x0003c800, 0x0003d000, 0x0003d800, 0x0003e000, 0x0003e800, 0x0003f000, 0x0003f800
.word	0x00040000, 0x00050000





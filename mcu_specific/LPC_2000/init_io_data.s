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
	UPFUNC	puaisr,	0		@  6:	uart0
	UPFUNC	puaisr,	0		@  7:	uart1
	.word	i0			@  8
	UPFUNC	pi2isr,	0		@  9:	i2c0 (if included)
	.word	i0			@ 10
	.word	i0			@ 11
	.word	i0			@ 12
	.word	i0			@ 13
	.word	i0			@ 14
	.word	i0			@ 15
	.word	i0			@ 16
	.word	i0			@ 17
	.word	i0			@ 18
	UPFUNC	pi2isr,	0		@ 19:	i2c1 (if included)
	.word	i0			@ 20
	.word	i0			@ 21
	UPFUNC	usbisr,	0		@ 22:	USB (if included)
	.word	i0			@ 23
	.word	i0			@ 24
	.word	i0			@ 25
	.word	i0			@ 26
	.word	i0			@ 27
	.word	i0			@ 28
	.word	i0			@ 29
	.word	i0			@ 30
	.word	i0			@ 31


/*----------------------------------------------------------------------------*\
*
*    FLASH I/O:	Internal Flash
*
\*----------------------------------------------------------------------------*/

.ifdef TINY_2131
flashsectors:	@ 8 x 4KB FLASH sectors of LPC2131
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x0FFFFFFC
.endif	@ .ifdef TINY_2131
	
.ifdef LPC_H2103
flashsectors:	@ 8 x 4KB FLASH sectors of LPC2103
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x0FFFFFFC
.endif	@ .ifdef LPC_H2103
	
.ifdef TINY_2106
flashsectors:	@ 16 x 8KB FLASH sectors of LPC2106
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x02000, 0x04000, 0x06000, 0x08000, 0x0A000, 0x0C000, 0x0E000
.word	0x10000, 0x12000, 0x14000, 0x16000, 0x18000, 0x1A000, 0x1C000, 0x1E000
.word	0x0FFFFFFC
.endif	@ .ifdef TINY_2106
	
.ifdef TINY_2138
flashsectors:	@ 8 x 4KB, 14 x 32KB, 5 x 4KB FLASH sectors of LPC2138
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x10000, 0x18000, 0x20000, 0x28000, 0x30000, 0x38000, 0x40000
.word	0x48000, 0x50000, 0x58000, 0x60000, 0x68000, 0x70000
.word	0x78000, 0x79000, 0x7A000, 0x7B000, 0x7C000, 0x7D000, 0x0FFFFFFC
.endif	@ .ifdef TINY_2138
	
.ifdef SFE_Logomatic1
flashsectors:	@ 8 x 4KB, 14 x 32KB, 5 x 4KB FLASH sectors of LPC2138
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x10000, 0x18000, 0x20000, 0x28000, 0x30000, 0x38000, 0x40000
.word	0x48000, 0x50000, 0x58000, 0x60000, 0x68000, 0x70000
.word	0x78000, 0x79000, 0x7A000, 0x7B000, 0x7C000, 0x7D000, 0x0FFFFFFC
.endif	@ .ifdef SFE_Logomatic1

.ifdef SFE_Logomatic2
flashsectors:	@ 8 x 4KB, 14 x 32KB, 5 x 4KB FLASH sectors of LPC2148
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x10000, 0x18000, 0x20000, 0x28000, 0x30000, 0x38000
.word	0x40000, 0x48000, 0x50000, 0x58000, 0x60000, 0x68000, 0x70000
.word	0x78000, 0x79000, 0x7A000, 0x7B000, 0x7C000, 0x7D000, 0x0FFFFFFC
.endif	@ .ifdef SFE_Logomatic2

.ifdef LPC_H2148
flashsectors:	@ 8 x 4KB, 14 x 32KB, 5 x 4KB FLASH sectors of LPC2148
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x10000, 0x18000, 0x20000, 0x28000, 0x30000, 0x38000
.word	0x40000, 0x48000, 0x50000, 0x58000, 0x60000, 0x68000, 0x70000
.word	0x78000, 0x79000, 0x7A000, 0x7B000, 0x7C000, 0x7D000, 0x0FFFFFFC
.endif	@ .ifdef LPC_H2148

.ifdef LCDDemo_2158
flashsectors:	@ 8 x 4KB, 14 x 32KB, 5 x 4KB FLASH sectors of LPC2158
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x10000, 0x18000, 0x20000, 0x28000, 0x30000, 0x38000
.word	0x40000, 0x48000, 0x50000, 0x58000, 0x60000, 0x68000, 0x70000
.word	0x78000, 0x79000, 0x7A000, 0x7B000, 0x7C000, 0x7D000, 0x0FFFFFFC
.endif	@ .ifdef LCDDemo_2158

.ifdef LPC2478_STK
flashsectors:	@ 8 x 4KB, 14 x 32KB, 5 x 4KB FLASH sectors of LPC2478
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x01000, 0x02000, 0x03000, 0x04000, 0x05000, 0x06000, 0x07000
.word	0x08000, 0x10000, 0x18000, 0x20000, 0x28000, 0x30000, 0x38000
.word	0x40000, 0x48000, 0x50000, 0x58000, 0x60000, 0x68000, 0x70000
.word	0x78000, 0x79000, 0x7A000, 0x7B000, 0x7C000, 0x7D000, 0x0FFFFFFC
.endif	@ .ifdef LPC2478_STK


.ifdef LPC_H2214
flashsectors:	@ FLASH sectors of MX26LV800BTC on LPC-H2214
		@ 1 x 16KB, 2 x 8KB, 1 x 32KB, 15 x 64KB
.word	0x80000000, 0x80004000, 0x80006000, 0x80008000
.word	0x80010000, 0x80020000, 0x80030000, 0x80040000, 0x80050000, 0x80060000
.word	0x80070000, 0x80080000, 0x80090000, 0x800A0000, 0x800B0000, 0x800C0000
.word	0x800D0000, 0x800E0000, 0x800F0000, 0x80100000

lib_sectors:	@ 8 x 8KB + 2 x 64kB + 8 x 8 kB on-chip FLASH sectors of LPC2214
.word	0x00000, 0x02000, 0x04000, 0x06000, 0x08000, 0x0A000, 0x0C000, 0x0E000
.word	0x10000, 0x20000
.word	0x30000, 0x32000, 0x34000, 0x36000, 0x38000, 0x3A000, 0x3C000, 0x3E000
.word	0x0FFFFFFC
.endif	@ ifdef LPC_H2214

.ifdef LPC_H2294
flashsectors:	@ sectors of Intel JS28F320C3-BD70 on LPC-H2294 board
		@ 8 x 8KB + 63 x 64KB FLASH (similar to LPC-H2888)
.word	0x80000000, 0x80002000, 0x80004000, 0x80006000, 0x80008000, 0x8000A000
.word	0x8000C000, 0x8000E000, 0x80010000, 0x80020000, 0x80030000, 0x80040000
.word	0x80050000, 0x80060000, 0x80070000, 0x80080000, 0x80090000, 0x800A0000
.word	0x800B0000, 0x800C0000, 0x800D0000, 0x800E0000, 0x800F0000, 0x80100000
.word	0x80110000, 0x80120000, 0x80130000, 0x80140000, 0x80150000, 0x80160000
.word	0x80170000, 0x80180000, 0x80190000, 0x801A0000, 0x801B0000, 0x801C0000
.word	0x801D0000, 0x801E0000, 0x801F0000, 0x80200000, 0x80210000, 0x80220000
.word	0x80230000, 0x80240000, 0x80250000, 0x80260000, 0x80270000, 0x80280000
.word	0x80290000, 0x802A0000, 0x802B0000, 0x802C0000, 0x802D0000, 0x802E0000
.word	0x802F0000, 0x80300000, 0x80310000, 0x80320000, 0x80330000, 0x80340000
.word	0x80350000, 0x80360000, 0x80370000, 0x80380000, 0x80390000, 0x803A0000
.word	0x803B0000, 0x803C0000, 0x803D0000, 0x803E0000, 0x803F0000, 0x80400000

lib_sectors:	@ 8 x 8KB + 2 x 64kB + 8 x 8 kB on-chip FLASH sectors of LPC2294
.word	0x00000, 0x02000, 0x04000, 0x06000, 0x08000, 0x0A000, 0x0C000, 0x0E000
.word	0x10000, 0x20000
.word	0x30000, 0x32000, 0x34000, 0x36000, 0x38000, 0x3A000, 0x3C000, 0x3E000
.word	0x0FFFFFFC
.endif	@ ifdef LPC_H2294




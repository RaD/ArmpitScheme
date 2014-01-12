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
	UPFUNC	puaisr,	0		@ 14:	usart0
	UPFUNC	puaisr,	0		@ 15:	usart1
	.word	i0			@ 16
	.word	i0			@ 17
	.word	i0			@ 18
	UPFUNC	pi2isr,	0		@ 19:	TWI0 / i2c0 (if included)
	UPFUNC	pi2isr,	0		@ 20:	TWI1 / i2c1 (if included)
	.word	i0			@ 21
	.word	i0			@ 22
	UPFUNC	ptmisr,	0		@ 23:	TC0 / timer0
	UPFUNC	ptmisr,	0		@ 24:	TC1 / timer1
	.word	i0			@ 25
	.word	i0			@ 26
	.word	i0			@ 27
	.word	i0			@ 28
	.word	i0			@ 29
	.word	i0			@ 30
	.word	i0			@ 31
	.word	i0			@ 32
	.word	i0			@ 33
	UPFUNC	usbisr,	0		@ 34:	UDP / USB (if included)
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


@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@


flsRAM:	@ code to be copied to RAM, at fre+, such that execution is from RAM while
	@ FLASH is being written. i.e. do: (1) ldr lnk, =xyz (2) set pc, fre to initiate
	@ EEFC address = 0x400E0A00
	set	rvb, #0x40000000
	orr	rvb, rvb, #0x0E0000
	orr	rvb, rvb, #0x000A00
	str	rva, [rvb, #0x04]		@ perform FLASH write
	@ wait for completion or timeout
	nop					@ landing pad
	nop					@ landing pad
	nop					@ landing pad
	nop					@ landing pad
	nop					@ landing pad
	nop					@ landing pad
	nop					@ landing pad
	ldr	rva, [rvb, #0x08]		@ get status
	tst	rva, #0x01			@ FRDY?
	itT	eq
	subeq	rva, pc,  #20			@	if not, jump back to get status
	seteq	pc,  rva
	set	pc,  lnk			@ return
flsRND: @ end of ram code


flashsectors:	@ 64 x 4kB sectors (AT91SAM3S MCU doesn't use sectors though, just 256 byte pages)
lib_sectors:	@ lib shares on-chip file flash
.word	0x000000, 0x001000, 0x002000, 0x003000, 0x004000, 0x005000, 0x006000, 0x007000
.word	0x008000, 0x009000, 0x00A000, 0x00B000, 0x00C000, 0x00D000, 0x00E000, 0x00F000
.word	0x010000, 0x011000, 0x012000, 0x013000, 0x014000, 0x015000, 0x016000, 0x017000
.word	0x018000, 0x019000, 0x01A000, 0x01B000, 0x01C000, 0x01D000, 0x01E000, 0x01F000
.word	0x020000, 0x021000, 0x022000, 0x023000, 0x024000, 0x025000, 0x026000, 0x027000
.word	0x028000, 0x029000, 0x02A000, 0x02B000, 0x02C000, 0x02D000, 0x02E000, 0x02F000
.word	0x030000, 0x031000, 0x032000, 0x033000, 0x034000, 0x035000, 0x036000, 0x037000
.word	0x038000, 0x039000, 0x03A000, 0x03B000, 0x03C000, 0x03D000, 0x03E000, 0x03F000, 0x040000, 0x0FFFFFFC




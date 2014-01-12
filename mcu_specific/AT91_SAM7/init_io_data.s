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

/*------------------------------------------------------------------------------
@
@ Contributions:
@
@     This file includes contributions by Robbie Dinn, marked <RDC>
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
	UPFUNC	puaisr,	0		@  6:	uart0
	UPFUNC	puaisr,	0		@  7:	uart1
	.word	i0			@  8
	UPFUNC	pi2isr,	0		@  9:	i2c0 / i2c1 (if included)
	.word	i0			@ 10
	UPFUNC	usbisr,	0		@ 11:	USB (if included)
	UPFUNC	ptmisr,	0		@ 12:	timer0
	UPFUNC	ptmisr,	0		@ 13:	timer1
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



	SYMSIZE	4
flash_:	.ascii	"FLSH"

.balign 4

flsRAM:	@ code to be copied to RAM, at fre+, such that exec is from RAM while
	@ FLASH is being written. i.e. (1) ldr lnk, =xyz (2) set pc, fre to init
	set	rvb, #0
	mvn	rvb, rvb
	bic	rvb, rvb, #0xff
	str	rva, [rvb, #0x64]	@ perform FLASH write
	@ wait for completion or timeout
	set	rva, #0			@ rva <- 0, for timeout
	set	rvb, #0
	mvn	rvb, rvb
	bic	rvb, rvb, #0xff
	ldr	rvb, [rvb, #0x68]	@ get status
	tst	rvb, #0x01		@ FRDY?
	addeq	rva, rva, #1
	tsteq	rva, #0x800000		@ rva <- timeout, approx 1 sec
	subeq	pc,  pc,  #36		@	if not, jump back to get status
	set	pc,  lnk		@ return
flsRND: @ end of ram code


flashsectors:	@ 64 x 4kB sectors (AT91SAM7 MCU doesn't use sectors though)
lib_sectors:	@ lib shares on-chip file flash
.word	0x000000,0x001000,0x002000,0x003000,0x004000,0x005000,0x006000,0x007000
.word	0x008000,0x009000,0x00A000,0x00B000,0x00C000,0x00D000,0x00E000,0x00F000
.word	0x010000,0x011000,0x012000,0x013000,0x014000,0x015000,0x016000,0x017000
.word	0x018000,0x019000,0x01A000,0x01B000,0x01C000,0x01D000,0x01E000,0x01F000
.word	0x020000,0x021000,0x022000,0x023000,0x024000,0x025000,0x026000,0x027000
.word	0x028000,0x029000,0x02A000,0x02B000,0x02C000,0x02D000,0x02E000,0x02F000
.word	0x030000,0x031000,0x032000,0x033000,0x034000,0x035000,0x036000,0x037000
.word	0x038000,0x039000,0x03A000,0x03B000,0x03C000,0x03D000,0x03E000,0x03F000
.word	0x040000,0x0FFFFFFC




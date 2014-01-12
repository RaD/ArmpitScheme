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

	UPFUNC	ptmisr,	0		@  0:	timer0
	.word	i0			@  1
	.word	i0			@  2
	.word	i0			@  3
	.word	i0			@  4
	.word	i0			@  5
	.word	i0			@  6
	UPFUNC	pi2isr,	0		@  7:	i2c0 (if included)
	UPFUNC	pi2isr,	0		@  8:	i2c1 (if included)
	UPFUNC	puaisr,	0		@  9:	uart0
	UPFUNC	puaisr,	0		@ 10:	uart1
	.word	i0			@ 11
	.word	i0			@ 12
	.word	i0			@ 13
	.word	i0			@ 14
	.word	i0			@ 15
	.word	i0			@ 16
	.word	i0			@ 17
	.word	i0			@ 18
	UPFUNC	ptmisr,	0		@ 19:	timer1
	.word	i0			@ 20
	.word	i0			@ 21
	.word	i0			@ 22
	.word	i0			@ 23
	.word	i0			@ 24
	.word	i0			@ 25
	UPFUNC	usbisr,	0		@ 26:	USB LP (if included)
	.word	i0			@ 27
	.word	i0			@ 28
	.word	i0			@ 29
	.word	i0			@ 30
	.word	i0			@ 31



@
@ 1- Initialization from FLASH and writing to FLASH
@

	SYMSIZE	4	
flash_:	.ascii	"FLSH"

.balign	4


flsRAM:	@ code to be copied to RAM, at fre+, such that exec is from RAM while
	@ FLASH is written. i.e. do: (1) ldr lnk, =xyz (2) set pc, fre to init
	set	rvb, #0x100000		@ rvb <- flash_base = FLASH_CR0
	str	rva, [rvb]		@ start write/erase operation
	set	rva, #0x100000		@ rva <- timeout to susp, approx 200 ms
	@ wait loop
	set	rvb, #0x100000		@ rvb <- flash_base = FLASH_CR0
	eq	rva, #0
	subsne	rva, rva, #1		@ rva <- timeout updated, is it zero?
	ldreq	rvb, [rvb]
	tsteq	rvb, #0x10
	orreq	rva, rvb, #0x40000000
	set	rvb, #0x100000		@ rvb <- flash_base = FLASH_CR0
	streq	rva, [rvb]		@	if so,  initiate suspend of op
	ldr	rvb, [rvb]		@ rvb <- stat of flsh bnks frm FLASH_CR0
	tst	rvb, #0x12		@ is bank 0 busy? (LOCK & BSYA0, chckbl)
	subne	pc,  pc, #48		@	if so,  jump to keep waiting
	@ wait a bit if WPG/DWPG/SER is stuck
	set	rva, #0x100000		@ rva <- timeout to susp, approx 100 ms
	set	rvb, #0x100000		@ rvb <- flash_base = FLASH_CR0
	ldr	rvb, [rvb]
	subs	rva, rva, #1
	tstne	rvb, #0x38000000
	subne	pc,  pc, #24		@	if so,  jump to keep waiting
	@ exit
	set	pc,  lnk		@ return
flsRND: @ end of ram code
	

flashsectors:	@ 4 x 8KB, 1 x 32KB, 3 x 64KB, Bank 0 FLASH sectors of STR711
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x02000, 0x04000, 0x06000, 0x08000
.word	0x10000, 0x20000, 0x30000, 0x40000, 0x0FFFFFFC







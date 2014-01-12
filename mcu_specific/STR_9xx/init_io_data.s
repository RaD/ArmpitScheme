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

	UPFUNC	ptmisr,	0		@  0
	.word	i0			@  1
	.word	i0			@  2
	.word	i0			@  3
	UPFUNC	ptmisr,	0		@  4:	timer0
	UPFUNC	ptmisr,	0		@  5:	timer1
	.word	i0			@  6
	.word	i0			@  7
	.word	i0			@  8
	UPFUNC	usbisr,	0		@  9:	USB LP (if included)
	.word	i0			@ 10
	.word	i0			@ 11
	.word	i0			@ 12
	.word	i0			@ 13
	.word	i0			@ 14
	.word	i0			@ 15
	UPFUNC	puaisr,	0		@ 16:	uart0
	UPFUNC	puaisr,	0		@ 17:	uart1
	.word	i0			@ 18
	UPFUNC	pi2isr,	0		@ 19:	i2c0 (if included)
	UPFUNC	pi2isr,	0		@ 20:	i2c1 (if included)
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



@
@ 1- Initialization from FLASH and writing to FLASH
@

	
flsULK:	@ unlock flash code (to be executed from RAM)
	@ on entry:	glv <- address of flash sector table
	@ on entry:	rva <- sector number of 1st file flash sector
	@ on entry:	rvb <- address of this code in RAM
	@ on entry:	rvc <- end address of file flash
	@ modifies:	sv1, rva, env, cnt
	@ returns via:	lnk
	@ loop over flash blocks to be unlocked
	ldr	cnt, [glv, rva, LSL #2]		@ cnt <- start address of flash sector
	@ unlock sector that starts at cnt
	ldr	env, [glv]			@ env <- FLASH start address
	set	sv1, #0x60			@ sv1 <- CFI unlock block command code
	strh	sv1, [cnt]			@ initiate block unlock
	set	sv1, #0xd0			@ sv1 <- CFI confirm unlock command code
	strh	sv1, [cnt]			@ confirm block unlock
	@ wait for FLASH device to be ready
	set	sv1, #0x90			@ sv1 <- CFI read device ID command code
	strh	sv1, [env]			@ initiate ID and status read
	ldrh	sv1, [cnt, #5]			@ sv1 <- block prot status, STR91xFAxx6,7
	cmp	cnt, rvc			@ done unlocking?
	addmi	rva, rva, #1			@	if not, rva <- next sector number
	setmi	pc, rvb 			@	if not, jump to unlock next sector
	@ Return to FLASH Read Array mode and exit
	set	sv1, #0xff			@ sv1 <- CFI Read Array command code
	strh	sv1, [env]			@ set FLASH to read array mode
	set	pc,  lnk
flsULE:	@ end of unlock code


flsRAM:	@ flash writing/erasing code to be copied to RAM
	@ on entry:	rva <- flash writing (#x40) or erasing (#x20) code
	@ on entry:	rvb <- start address of target flash sector
	@ on entry:	rvc <- address of flash start (if erase)
	@ on entry:	sv2 <- destination flash page start address (if write)
	@ on entry:	sv3 <- data buffer to be written (if write)
	@ on entry:	sv5 <- end target address (if write)
	@ on entry:	cnt <- this routine's start address in RAM
	@ modifies:	sv2, sv3, rva, rvc, cnt (if write)
	@ returns via:	lnk
	eq	rva, #0x20			@ doing erase?
	adrne	cnt, flwren			@	if not, cnt <- loop adddress for write
	setne	pc, cnt				@	if not, jump to write
	@ sector erase routine: erase block whose address starts at sv2
	strh	rva, [rvb]			@ initiate erase block
	set	rva, #0xd0			@ rva <- CFI confirm erase command code
	strh	rva, [rvb]			@ confirm erase block
	@ wait for FLASH device to be ready
	ldrh	rva, [rvb]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	subeq	pc, pc, #16			@	if not, jump back to keep waiting
	@ Return to FLASH Read Array mode and return
	set	rva, #0xff			@ rva <- CFI Read Array command code
	strh	rva, [rvb]			@ set FLASH to read array mode
	set	pc,  lnk			@ return
flwren:	@ file writing routine
	@ write lower 2 bytes of word
	ldrh	rvc, [sv3]			@ rvc <- lower half of word to write
	set	rva, #0x40			@ rva <- CFI word program command code
	strh	rva, [sv2]			@ start half word write
	strh	rvc, [sv2]			@ confirm half word write
	@ wait for FLASH device to be ready
	ldrh	rva, [rvb]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	subeq	pc, pc, #16			@	if not, jump to keep waiting
	@ write upper two bytes of word
	ldrh	rvc, [sv3, #2]			@ rvc <- upper half word to write
	set	rva, #0x40			@ rva <- CFI word program command code
	strh	rva, [sv2]			@ start half word write
	strh	rvc, [sv2, #2]			@ confirm half word write
	@ wait for FLASH device to be ready
	ldrh	rva, [rvb]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	subeq	pc, pc, #16			@	if not, jump to keep waiting
	@ jump to keep writing or finish up
	add	sv3, sv3, #4			@ sv3 <- address of next source word
	add	sv2, sv2, #4			@ sv2 <- target address of next word
	cmp	sv2, sv5			@ done writing page?
	setmi	pc, cnt				@	if not, jump to keep writing
	@ Return to FLASH Read Array mode and return
	set	rva, #0xff			@ rva <- CFI Read Array command code
	strh	rva, [rvb]			@ set FLASH to read array mode
	set	pc,  lnk			@ return
flsRND: @ end of ram code
	
	

flashsectors:	@ 8 x 64KB, Bank 0 FLASH sectors of STR911
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000, 0x10000, 0x20000, 0x30000, 0x40000, 0x50000, 0x60000, 0x70000
.word	0x80000, 0x0FFFFFFC


	






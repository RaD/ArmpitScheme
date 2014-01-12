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
	UPFUNC	ptmisr,	0		@ 10:	timer0
	UPFUNC	ptmisr,	0		@ 11:	timer1
	.word	i0			@ 12
	.word	i0			@ 13
	.word	i0			@ 14
	UPFUNC	puaisr,	0		@ 15:	uart1
	.word	i0			@ 16
	.word	i0			@ 17
	.word	i0			@ 18
	.word	i0			@ 19
	.word	i0			@ 20
	.word	i0			@ 21
	.word	i0			@ 22
	.word	i0			@ 23
	.word	i0			@ 24
	UPFUNC	usbisr,	0		@ 25:	USB device (if included)
	.word	i0			@ 26
	UPFUNC	pi2isr,	0		@ 27:	i2c0/1 (if included)
	UPFUNC	puaisr,	0		@ 28:	uart0
	.word	i0			@ 29
	.word	i0			@ 30
	.word	i0			@ 31


@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

wflRAM:	@ code to be copied to S3C24xx boot SRAM to run from SRAM while
	@ writing file FLASH	
	@ initiate write-buffer to FLASH
	set	rva, #0xe8		@ rva <- CFI write-buffer command code
	strh	rva, [sv1]		@ initiate write-buffer
	ldrh	rva, [sv1]		@ rva <- FLASH device status
	tst	rva, #0x80		@ is FLASH ready?
	subeq	pc,  pc, #24		@	if not, jump to keep waiting
	@ set count and transfer data to FLASH write-buffer
	set	rva, #0x1f		@ rva <- 32 bytes to write
	strh	rva, [sv1]		@ set number of bytes to write in CFI
	ldmia	sv3!, {fre,cnt,rva,rvb,sv5,env,dts,glv}	@ next 8 src dat words
	stmia	sv2,  {fre,cnt,rva,rvb,sv5,env,dts,glv}	@ store words in FLASH
	stmia	sv2!, {fre,cnt,rva,rvb,sv5,env,dts,glv}	@ store data AGAIN (cfi)
	@ commit write-buffer to FLASH
	set	rva, #0xd0		@ rva <- CFI confirm wrt-bfr cmnd code
	strh	rva, [sv1]		@ confirm write-buffer command
	ldrh	rva, [sv1]		@ rva <- FLASH device status
	tst	rva, #0x80		@ is FLASH ready?
	subeq	pc,  pc,  #16		@	if not, jump to keep waiting
	set	rva, #0x50		@ rva <- CFI Clear Stat Reg command code
	strh	rva, [sv1]		@ clear the status register
	set	rva, #0xff		@ rva <- CFI Read Array command code
	strh	rva, [sv1]		@ set FLASH to read array mode
	set	pc,  lnk		@ return
wflEND:	@ end of SRAM code
		

rflRAM:	@ code to be copied to S3C24xx boot SRAM to run from SRAM while
	@ erasing file FLASH
	@ unlock block to be erased (unlocks all blocks really it seems)
	set	rva, #0x60		@ rva <- CFI unlock block command code
	strh	rva, [sv1]		@ initiate block unlock
	set	rva, #0xd0		@ rva <- CFI confirm unlock command code
	strh	rva, [sv1]		@ confirm block unlock
	ldrh	rva, [sv2]		@ rva <- FLASH device status
	tst	rva, #0x80		@ is FLASH ready?
	subeq	pc,  pc,  #16		@	if not, jump to keep waiting
	set	rva, #0x50		@ rva <- CFI Clear Stat Reg command code
	strh	rva, [sv1]		@ clear the status register
	@ erase block whose address starts at sv2
	set	rva, #0x20		@ rva <- CFI erase block command code
	strh	rva, [sv2]		@ initiate erase block
	set	rva, #0xd0		@ rva <- CFI confirm erase command code
	strh	rva, [sv2]		@ confirm erase block
	ldrh	rva, [sv2]		@ rva <- FLASH device status
	tst	rva, #0x80		@ is FLASH ready?
	subeq	pc,  pc,  #16		@	if not, jump to keep waiting
	set	rva, #0x50		@ rva <- CFI Clear Stat Reg command code
	strh	rva, [sv1]		@ clear the status register
	set	rva, #0xff		@ rva <- CFI Read Array command code
	strh	rva, [sv1]		@ set FLASH to read array mode
	set	pc,  lnk		@ return
rflEND:	@ end of RAM code


.ifdef TCT_Hammer
flashsectors:	@ 128 x 128KB FLASH sectors of Intel JS28F128 J3D75 on TCT Hammer board
.word	0x00000000, 0x00020000,  0x00040000,  0x00060000,  0x00080000,  0x000A0000,  0x000C0000,  0x000E0000
.word	0x00100000, 0x00120000,  0x00140000,  0x00160000,  0x00180000,  0x001A0000,  0x001C0000,  0x001E0000
.word	0x00200000, 0x00220000,  0x00240000,  0x00260000,  0x00280000,  0x002A0000,  0x002C0000,  0x002E0000
.word	0x00300000, 0x00320000,  0x00340000,  0x00360000,  0x00380000,  0x003A0000,  0x003C0000,  0x003E0000
.word	0x00400000, 0x00420000,  0x00440000,  0x00460000,  0x00480000,  0x004A0000,  0x004C0000,  0x004E0000
.word	0x00500000, 0x00520000,  0x00540000,  0x00560000,  0x00580000,  0x005A0000,  0x005C0000,  0x005E0000
.word	0x00600000, 0x00620000,  0x00640000,  0x00660000,  0x00680000,  0x006A0000,  0x006C0000,  0x006E0000
.word	0x00700000, 0x00720000,  0x00740000,  0x00760000,  0x00780000,  0x007A0000,  0x007C0000,  0x007E0000
.word	0x00800000, 0x00820000,  0x00840000,  0x00860000,  0x00880000,  0x008A0000,  0x008C0000,  0x008E0000
.word	0x00900000, 0x00920000,  0x00940000,  0x00960000,  0x00980000,  0x009A0000,  0x009C0000,  0x009E0000
.word	0x00A00000, 0x00a20000,  0x00a40000,  0x00a60000,  0x00a80000,  0x00aA0000,  0x00aC0000,  0x00aE0000
.word	0x00B00000, 0x00b20000,  0x00b40000,  0x00b60000,  0x00b80000,  0x00bA0000,  0x00bC0000,  0x00bE0000
.word	0x00C00000, 0x00c20000,  0x00c40000,  0x00c60000,  0x00c80000,  0x00cA0000,  0x00cC0000,  0x00cE0000
.word	0x00D00000, 0x00d20000,  0x00d40000,  0x00d60000,  0x00d80000,  0x00dA0000,  0x00dC0000,  0x00dE0000
.word	0x00E00000, 0x00e20000,  0x00e40000,  0x00e60000,  0x00e80000,  0x00eA0000,  0x00eC0000,  0x00eE0000
.word	0x00F00000, 0x00f20000,  0x00f40000,  0x00f60000,  0x00f80000,  0x00fA0000,  0x00fC0000,  0x00fE0000
.word	0x01000000
.endif	@ .ifdef TCT_Hammer
	






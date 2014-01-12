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


	@ disable watchdog
	ldr	rva, =0x53000000
	set	rvb, #0x00
	str	rvb, [rva]

	@ disable interrupts (via mask)
	ldr	rva, =int_base
	ldr	rvb, =0xffffffff
	str	rvb, [rva, #0x08]	@ disable ints in INTMSK
	ldr	rvb, =0x07ff
	str	rvb, [rva, #0x1c]	@ disable sub-ints in INTSUBMSK

	@ configure PLL
	ldr	rva, =0x4c000000
	set	rvb, #0x03		@ rvb <- 3, Hclk = Fclk/2, Pclk = Hclk/2
	str	rvb, [rva, #0x14]

.ifdef	native_usb
	ldr	rvb, =0x078023
	str	rvb, [rva, #0x08]	@ set UPLL to 48MHz (for USB)
	nop
	nop
	nop
	nop
	nop
	nop
	nop
.endif	@ native_usb
	
	ldr	rvb, =PLL_PM_parms
	str	rvb, [rva, #0x04]

	@ use CPS15 to switch from Fast Bus Mode to Sync/Async Mode
	mrc	p15, 0, rvb, c1, c0, 0
	orr	rvb, rvb, #0xC0000000	@ set clock mode to asynchronous
	mcr	p15, 0, rvb, c1, c0, 0

	@ configure external memory
	@ BANK 0, (autoconf) intel flash 28F128J3-D75 (same as EP9302) (16MB)
	@ Bank 6,7, SDRAM, Micron MT48LC16M16A2, BG-75, 4M x 16 X 4 banks (32MB)
	ldr	rva, =0x48000000
	ldr	rvb, =0x11000000
	str	rvb, [rva]		@ Bank 6,7 SDRAM dat bus wdth=16b,nowait
	ldr	rvb, =0x018001
	str	rvb, [rva, #0x1c]	@ Bank 6,SDRAM,9bit col adrs,2clkCAS>RAS
	str	rvb, [rva, #0x20]	@ Bank 7,SDRAM,9bit col adrs
	ldr	rvb, =0x8404e9
	str	rvb, [rva, #0x24]	@ SDRAM precharge (originally: 0x9c0459)
	set	rvb, #0xb2
	str	rvb, [rva, #0x28]	@ Burst enable, 128/128MB mem map (p208)
	set	rvb, #0x20
	str	rvb, [rva, #0x2c]	@ Bank 6, CL = 2 (originally CL3, 0x30)
	str	rvb, [rva, #0x30]	@ Bank 7, CL = 2

	@ copy scheme code to SDRAM
	bl	codcpy

	@ initialize TTB (Translat Table Base) Dflt Mem space, not cach, not bfr
	ldr	rvc, =0x0C12		@ rvc <- r/w perm,dom 0,not cach/bfr,1MB
	set	rva, #RAMBOTTOM
	orr	rva, rva, #0x010000	@ rva <- start of TTB (64kb into SDRAM)
	set	rvb, rvc		@ rvb <- section 0 descriptor
ttbst0:	str	rvb, [rva, rvb, LSR #18] @ store section desc in Translation Tbl
	add	rvb, rvb, #0x00100000
	eq	rvb, rvc
	bne	ttbst0

	@ continue initializing TTB, for Scheme core SDRAM (cacheable, buffered)
	ldr	rvc, =0x0C1E		 @ rvc <- r/w perm,domain 0,cach/bfr,1MB
	set	rvb, rvc		 @ rvb <- section 0 descriptor
	str	rvb, [rva, rvb, LSR #18] @ store section desc in Translation Tbl
	orr	rvb, rvb, #RAMBOTTOM
ttbst1:	str	rvb, [rva, rvb, LSR #18] @ store section desc in Translation Tbl
	add	rvb, rvb, #0x00100000
	tst	rvb, #0x02000000
	beq	ttbst1

	@ remap RAMBOTTOM to 0x00 (schm cod-rd-only frm 0x00,r/w frm #RAMBOTTOM)
	set	rvb, rvc
	orr	rvb, rvb, #RAMBOTTOM
	str	rvb, [rva]		@ store section desc in Translation Tbl

	@ use coprocessor 15 to set domain access control, TTB base, enable MMU
	set	rvb, #0x01		@ rvb <- domain 0 client access perms
	mcr	p15, 0, rvb, c3, c0, 0	@ set domain access into CP15 reg 3
	mcr	p15, 0, rva, c2, c0, 0	@ set TTB base address into CP15 reg 2
	mrc	p15, 0, rvb, c1, c0, 0	@ rvb <- contents of ctrl reg CP15 reg 1
	orr	rvb, rvb, #0x5000	@ rvb <- contents ord w/Icache,rnd-robin
	orr	rvb, rvb, #0x0005	@ rvb <- contents ord w/Dcache,MMU enab

	@ jump to non-remapped SDRAM to enable MMU
	ldr	rvc, =enbttb
	set	rva, #RAMBOTTOM
	orr	rva, rva, #0x00100000
	ldmia	rvc, {fre,cnt,sv1-sv5}
	stmia	rva, {fre,cnt,sv1-sv5}
	set	pc,  rva		@ jump to copied cache/MMU init
	
enbttb:	@ code copied to SDRAM to execute from non-remapped space
	@ as cache/MMU is enabled
	mcr	p15, 0, rvb, c1, c0, 0	@ set cache/MMU enable into CP15 reg 1
	nop
	nop
	nop
	nop
	nop
	@ jump to remainder of initialization
	set	pc, #0x00

codcpy:	@ copy scheme to SDRAM address 0x30000000 (RAMBOTTOM)
	ldr	r8,  = _text_section_address_	@ start of source
	ldr	r9,  = _startcode	@ start of destination (build_link file)
	ldr	r10, = _endcode		@ end of destination   (build_link file)
	orr	r9,  r9,  #RAMBOTTOM
	orr	r10, r10, #RAMBOTTOM
	add	r10, r10,  #4
codcp0:	ldmia	r8!, {r0-r7}
	stmia	r9!, {r0-r7}
	cmp	r9,  r10
	bmi	codcp0
	set	pc,  lnk


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

@-------------------------------------------------------------------------------
@		
@  STARTUP CODE FOR EP93xx
@
@	boot section, starts with "CRUS" at 0x60000000 for EP9302 Boot Process
@		
@-------------------------------------------------------------------------------

.ascii	"CRUS"
	@ clear watchdog and 64Hz timer interrupts
	ldr	r6, =0x80930000
	set	r7, #0x00
	str	r7, [r6, #0x18]		@ TINT clear
	str	r7, [r6, #0x1c]		@ Watchdog clear
	ldr	r5, =0x80940000
	ldr	r7, =0xAA55
	strh	r7, [r5]		@ disable watchdog

	@ configure external memory:	 FLASH
	ldr	r5, =0x80080018
	ldr	r7, =0x100014a2
	str	r7, [r5]		@ SMCBCR[6]

	@ configure clocks/plls
	ldr	r7, =PLL_PM_parms
	str	r7, [r6, #0x20]		@ ClkSet1

	@ follow clkset1 by 5 nops (according to the manual)
	nop
	nop
	nop
	nop
	nop
	ldr	r7, =0x300dc317
	str	r7, [r6, #0x24]		@ ClkSet2

	@ use CPS15 to switch from Fast Bus Mode to Sync/Async Mode
	MRC	p15, 0, r7, c1, c0, 0
	orr	r7,  r7, #0xC0000000	@ set clock mode to asynchronous
	MCR	p15, 0, r7, c1, c0, 0

	@ configure external memory:	 SDRAM
	set	r9, #0x80000000		@ r9  <- base address / GIConf value (clk enable)
	orr	r6, r9, #0x00060000	@ r6  <- SDRAMDevCfg[0]
	bl	wt100			@ wait for stabilization
	ldr	r7, =0x0021002C		@ RAStoCAS2, burst4, cas2, SROMLL=1(exch AD12,13-Ba0,1),4banks,16bit
	str	r7, [r6, #0x1c]		@ SDRAMDevCfg[3] <- config
	bl	wt100			@ wait for stabilization
	orr	r7, r9, #0x03
	str	r7, [r6, #0x04]		@ SDRAM GIConfig <- clk enab, fre run, MRS=1, Init=1 => NOP
	bl	wt100			@ wait for stabilization
	str	r9, [r6, #0x04]		@ SDRAM GIConfig <- clk enab, fre run => normal operation
	set	r7, #0x00000000
	str	r7, [r7]		@ write to bank 0 (substitute for precharge all cf errata)
	set	r7, #0x00200000
	str	r7, [r7]		@ write to bank 1 (substitute for precharge all cf errata)
	set	r7, #0x00400000
	str	r7, [r7]		@ write to bank 2 (substitute for precharge all cf errata)
	set	r7, #0x00600000
	str	r7, [r7]		@ write to bank 3 (substitute for precharge all cf errata)
	orr	r7, r9, #0x01
	str	r7, [r6, #0x04]		@ SDRAM GIConfig <- clk enab, fre run, MRS=0, Init=1 => precharge all
	set	r7, #0x0A
	str	r7, [r6, #0x08]		@ SDRAM RefrshTimr <- 10 clock cycles
	bl	wt100			@ wait for stabilization
	ldr	r7, =0x0208
	str	r7, [r6, #0x08]		@ SDRAM RefrshTimr <- 516 (8 ms)
	orr	r7, r9, #0x02
	str	r7, [r6, #0x04]		@ SDRAM GIConfig <- clk enab, fre run, MRS=1, Init=0 => Mode reg accss
	set	r7, #0x4600
	ldr	r7, [r7]		@ set WBM=0, TM=0, CAS2, SEQ, BL=8 in SDRAM chip
	str	r9, [r6, #0x04]		@ SDRAM GIConfig <- clk enab, fre run => normal operation

	@ initialize TTB (Translation Table Base) for Default Memory space (not cacheable, not buffered)
	ldr	r2,  =0x0C12		@ r2  <- r/w permitted, domain 0, not cacheable/buffered, 1MB sect.
	set	r0,  #0x010000		@ r0  <- address of start of TTB
	set	r1,  r2			@ r1  <- section 0 descriptor
ttbst0:	str	r1,  [r0,  r1, LSR #18]	@ store section descriptor in Translation Table
	add	r1,  r1, #0x00100000
	eq	r1,  r2
	bne	ttbst0
	@ continue initializing TTB, for SDRAM (cacheable, buffered)
	set	r1,  r0
	ldr	r2,  =0x0C1E		@ r2  <- r/w permitted, domain 0, cacheable/buffered, 1MB sect.
	add	r3,  r2, #0x01000000
	add	r4,  r2, #0x04000000
	add	r5,  r2, #0x05000000
ttbst1:	str	r2,  [r1]		@ store section descriptor in Translation Table
	str	r3,  [r1,  #32]		@ store section descriptor in Translation Table
	str	r4,  [r1,  #64]		@ store section descriptor in Translation Table
	str	r5,  [r1,  #96]		@ store section descriptor in Translation Table
	add	r1,  r1, #4
	add	r2,  r2, #0x00100000
	add	r3,  r3, #0x00100000
	add	r4,  r4, #0x00100000
	add	r5,  r5, #0x00100000
	tst	r3,  #0x00800000
	beq	ttbst1

	@ use coprocessor 15 to set domain access control, TTB base and enable MMU
	set	r3,  #0x01		@ r3  <- domain 0 uses client access perms (A & P bits checked)
	mcr	p15, 0,  r3, c3, c0, 0	@ set domain access into CP15 register 3
	bl	wt100
	mcr	p15, 0,  r0, c2, c0, 0	@ set TTB base address into CP15 register 2
	bl	wt100
	mrc	p15, 0,  r7, c1, c0, 0	@ r7 <- contents of control register (CP15 reg. 1)
	orr	r7,  r7, #0x5000	@ r7 <- contents orred with Icache enable, round-robin
	orr	r7,  r7, #0x0005	@ r7 <- contents orred with Dcache and MMU enable
	mcr	p15, 0,  r7, c1, c0, 0	@ set cache/MMU enbale into CP15 register 1
	bl	wt100

	@ copy ARMPIT Scheme code to SDRAM
	bl	codcpy

	@ jump to start running Scheme code
	set	pc,  #0x00

wt100:	@ wait countdown loop
	set	r8, #32768
wt100c:	subs	r8, r8, #1
	bne	wt100c
	set	pc,  lnk

codcpy:	@ copy scheme to SDRAM address 0x00000000
	ldr	r8,  = _text_section_address_	@ start of source
	ldr	r9,  = _startcode	@ start of destination (from build_link file)
	ldr	r10, = _endcode		@ end of destination (from build_link file)
	add	r10, r10,  #4
codcp0:	ldmia	r8!, {r0-r7}
	stmia	r9!, {r0-r7}
	cmp	r9,  r10
	bmi	codcp0
	set	pc,  lnk






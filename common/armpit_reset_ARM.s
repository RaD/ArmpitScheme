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
@  I.B.1. ARMv4T, ARMv5TEJ, ARMv7A
@-------------------------------------------------------------------------------


_start:	@ reset startup (address 0x00 normally)

.ifndef	rst_direct_branch

	ldr	pc,  =reset		@ reset
	ldr	pc,  =inserr		@ undefined instruction handler
	ldr	pc,  =swi_hndlr		@ software interrupt
	ldr	pc,  =prferr		@ prefetch abort handler
	ldr	pc,  =daterr		@ data abort handler
	.space 4
  .ifndef irq_direct_branch
        ldr	pc,  [pc, #int_voffset]	@ IRQ:	jump to isr stord in VICVectAddr
  .else
        ldr	pc,  =genisr		@ IRQ:	jump to genisr
  .endif
	subs	pc,  lr, #4		@ FIQ:	return

.else	@ (eg. AT91-SAM9)

	b	reset			@ reset
	b	inserr			@ undefined instruction handler
	b	swi_hndlr		@ software interrupt
	b	prferr			@ prefetch abort handler
	b	daterr			@ data abort handler
	.space 4			@ uplodr may wrt val here lpc21isp,SAMBA
        b	genisr			@ IRQ:	jump to genisr
	b	fiqisr			@ FIQ:	branch to FIQ return
fiqisr:	subs	pc,  lr, #4		@ FIQ return
	
.endif

	SYMSIZE	4
snster:	.ascii	"inst"

	SYMSIZE	4
sprfer:	.ascii	"pref"
	
	SYMSIZE	4
sdater:	.ascii	"data"

inserr:	@ undefined instruction handler
	ldr	rvb, =GRNLED
	adr	sv4, snster
	set	sv1, lnk
	b	errcmn

prferr:	@ prefetch abort handler
	ldr	rvb, =REDLED
	adr	sv4, sprfer
	sub	sv1, lnk,  #4
	b	errcmn
	
daterr:	@ data abort handler
	ldr	rvb, =YELLED
	adr	sv4, sdater
	sub	sv1, lnk,  #8
errcmn:	@ [internal entry]
	bl	ledon
	orr	sv1, sv1, #int_tag
	ldr	lnk, =error4
	bic	rvb, fre, #0x03
	orr	fre, rvb, #0x02
	movs	pc,  lnk

swi_hndlr: @ switch from user mode to specified mode
	@ (including switching interrupts on/off in user mode)
	ldr	r13, [lnk, #-4]		@ r13  <- swi instruction, incl. its arg
	bic	r13, r13, #0xff000000	@ r13  <- new mode = argument of swi
	msr	spsr_c, r13		@ set into spsr
	movs	pc,  lnk		@ return

reset0:	@ soft reset when scheme heap is exhausted
	swi	isr_normal		@ switch to IRQ mode with interrupts
	ldr	sp,  =RAMTOP		@ set stack pointer for IRQ mode
	sub	sp,  sp, #4
	msr	cpsr_c, #normal_run_mode @ switch to user mode with interrupts
	ldr	sp,  =RAMTOP		@ set stack pointer for system mode
	sub	sp,  sp, #92
	bl	rldon			@ turn on red (or other) led
	bl	gldoff			@ turn on green (or other) led
	set	rvb, #0x02		@ reset and stop/disable Timers
	ldr	rva, =timer0_base
	str	rvb, [rva, #timer_ctrl]
	ldr	rvb, [rva, #timer_istat]
	str	rvb, [rva, #timer_iset]
	ldr	rva, =timer1_base
	str	rvb, [rva, #timer_ctrl]
	ldr	rvb, [rva, #timer_istat]
	str	rvb, [rva, #timer_iset]
	b	scinit			@ jump to initialize scheme and boot

reset:	@ set stacks for various MCU modes
.ifdef	STR_9xx
	mrc	p15, 0, cnt, c1, c0, 0
	orr	cnt, cnt, #0x08
	mcr	p15, 0, cnt, c1, c0, 0	@ enable buffered writes to AMBA AHB
	set	cnt, #0x40000
	mcr	p15, 1, cnt, c15, c1, 0	@ order TCM instr (cf.errata, Flash mem)
.endif
	ldr	r3, =RAMTOP
	sub	fre, r3, #4
	msr	CPSR_c,  #0x1F		@ switch to system mode with interrupts
	set	sp, fre			@ set system mode stack pointer
	msr	CPSR_c,  #0x1B		@ switch to undef instr mode with ints
	set	sp, fre			@ set undef instr mode stack pointer
	msr	CPSR_c,  #0x17		@ switch to abort mode with interrupts
	set	sp, fre			@ set abort mode stack pointer
	msr	CPSR_c,  #0x13		@ switch to supervisor mode with ints
	set	sp, fre			@ set service mode stack pointer
	msr	CPSR_c,  #isr_normal	@ switch to IRQ mode with interrupts
	set	sp, fre			@ set IRQ mode stack pointer
	msr	CPSR_c,  #0x11		@ switch to FIQ mode with interrupts
	set	sp, fre			@ set FIQ mode stack pointer
	msr	cpsr_c, #normal_run_mode @ switch to user mode with interrupts
	sub	sp,  r3, #92		@ set user mode stack pointer



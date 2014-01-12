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
@  I.B.2. Cortex
@-------------------------------------------------------------------------------

.ifndef	run_from_ram

_start:	.word	MAIN_STACK			@ 0x00 - Main Stack base address
	.word	reset				@ 0x01 - Reset isr
	.word	nmi_hndlr			@ 0x02 - Non Maskable Int isr
	.word	fault_hndlr			@ 0x03 - Hard Fault isr
	.word	mpu_hndlr			@ 0x04 - MPU isr
	.word	busf_hndlr			@ 0x05 - Bus Fault isr
	.word	usef_hndlr			@ 0x06 - Usage Fault isr
	.word	0x00				@ 0x07 - reserved (LPC checksum)
	.word	0x00				@ 0x08 - reserved
	.word	0x00				@ 0x09 - reserved
	.word	0x00				@ 0x0A - reserved
	.word	svc_hndlr			@ 0x0B - software int handler
	.word	debug_hndlr			@ 0x0C - debug monitor
	.word	0x00				@ 0x0D - reserved
	.word	pends_hndlr			@ 0x0E - pendable service reqst
	.word	tick_hndlr			@ 0x0F - SYS Tick handler
	.word	genisr, genisr, genisr, genisr	@ 0x10-0x13 -> INT 00-03
	.word	genisr, genisr, genisr, genisr	@ 0x14-0x17 -> INT 04-07
	.word	genisr, genisr, genisr, genisr	@ 0x18-0x1B -> INT 08-11
	.word	genisr, genisr, genisr, genisr	@ 0x1C-0x1F -> INT 12-15
	.word	genisr, genisr, genisr, genisr	@ 0x20-0x23 -> INT 16-19
	.word	genisr, genisr, genisr, genisr	@ 0x24-0x27 -> INT 20-23
	.word	genisr, genisr, genisr, genisr	@ 0x28-0x2B -> INT 24-27
	.word	genisr, genisr, genisr, genisr	@ 0x2C-0x2F -> INT 28-31
.if num_interrupts > 32
	.word	genisr, genisr, genisr, genisr	@ 0x30-0x33 -> INT 32-33
	.word	genisr, genisr, genisr, genisr	@ 0x34-0x37 -> INT 36-39
	.word	genisr, genisr, genisr, genisr	@ 0x38-0x3B -> INT 40-43
	.word	genisr, genisr, genisr, genisr	@ 0x3C-0x3F -> INT 44-47
	.word	genisr, genisr, genisr, genisr	@ 0x40-0x43 -> INT 48-51
	.word	genisr, genisr, genisr, genisr	@ 0x44-0x47 -> INT 52-55
	.word	genisr, genisr, genisr, genisr	@ 0x48-0x4B -> INT 56-59
	.word	genisr, genisr, genisr, genisr	@ 0x4C-0x4F -> INT 60-63
.endif
.if num_interrupts > 64
	.word	genisr, genisr, genisr, genisr	@ 0x50-0x53 -> INT 64-67
	.word	genisr, genisr, genisr, genisr	@ 0x54-0x57 -> INT 68-71
	.word	genisr, genisr, genisr, genisr	@ 0x58-0x5B -> INT 72-75
	.word	genisr, genisr, genisr, genisr	@ 0x5C-0x5F -> INT 76-79
	.word	genisr, genisr, genisr, genisr	@ 0x60-0x63 -> INT 80-83
	.word	genisr, genisr, genisr, genisr	@ 0x64-0x67 -> INT 84-87
	.word	genisr, genisr, genisr, genisr	@ 0x68-0x6B -> INT 88-91
	.word	genisr, genisr, genisr, genisr	@ 0x6C-0x6F -> INT 92-95
.endif
.if num_interrupts > 96
	.word	genisr, genisr, genisr, genisr	@ 0x50-0x53 -> INT  96--99
	.word	genisr, genisr, genisr, genisr	@ 0x54-0x57 -> INT 100-103
	.word	genisr, genisr, genisr, genisr	@ 0x58-0x5B -> INT 104-107
	.word	genisr, genisr, genisr, genisr	@ 0x5C-0x5F -> INT 108-111
	.word	genisr, genisr, genisr, genisr	@ 0x60-0x63 -> INT 112-115
	.word	genisr, genisr, genisr, genisr	@ 0x64-0x67 -> INT 116-119
	.word	genisr, genisr, genisr, genisr	@ 0x68-0x6B -> INT 120-123
	.word	genisr, genisr, genisr, genisr	@ 0x6C-0x6F -> INT 124-127
.endif
.if num_interrupts > 128
	.word	genisr, genisr, genisr, genisr	@ 0x50-0x53 -> INT 128-131
	.word	genisr, genisr, genisr, genisr	@ 0x54-0x57 -> INT 132-135
	.word	genisr, genisr, genisr, genisr	@ 0x58-0x5B -> INT 136-139
	.word	genisr, genisr, genisr, genisr	@ 0x5C-0x5F -> INT 140-143
	.word	genisr, genisr, genisr, genisr	@ 0x60-0x63 -> INT 144-147
	.word	genisr, genisr, genisr, genisr	@ 0x64-0x67 -> INT 148-151
	.word	genisr, genisr, genisr, genisr	@ 0x68-0x6B -> INT 152-155
	.word	genisr, genisr, genisr, genisr	@ 0x6C-0x6F -> INT 156-159
.endif

.endif	@ run_from_ram

.ifdef	enable_MPU
_func_
mpu_hndlr:
	@ perform gc on MPU FAULT
	mrs	fre, psp		@ fre <- psp stack
	@ find start address of memory allocation sequence
	ldr	rva, =0x0003F020	@ rva <- mach code of: bic fre, fre, #3
	ldr	rvb, [fre, #24]		@ rvb <- address of faulted storage inst
	bic	rvb, rvb, #0x01		@ rvb <- address with cleared Thumb bit
cisrch:	sub	rvb, rvb, #2
	ldr	cnt, [rvb]
	eq	cnt, rva
	bne	cisrch
	add	cnt, rvb, #4
	@ de-reserve memory in case an int (eg. timer) arose while handling this
	ldr	rvb, [fre]
	bic	rvb, rvb, #7		@ rvb <- 8-byte aligned (eg. for ibcons)
	orr	rvb, rvb, #0x02
	str	rvb, [fre]
	@ set stack up to perform gc
	set	rvb, #24		@ rvb <- 24 default/max num bytes needed
	str	rvb, [fre, #12]		@ set number of bytes needed from gc
	ldr	rva, =gc_bgn		@ rva <- address of gc routine	
	set	rvb, #normal_run_mode	@ rvb <- normal run mode
	add	fre, fre, #20
	stmia	fre, {cnt, rva, rvb}	@ set svd lnk_usr,pc_usr,run_mode for gc
	bx	lnk			@ jump to gc, thread mode, process stack
.else
_func_
mpu_hndlr:
	@ continue to nmi_hndler, etc... (default fault handlers)
.endif

_func_
fault_hndlr:
_func_
nmi_hndlr:
_func_
busf_hndlr:
_func_
usef_hndlr:
_func_
debug_hndlr:
_func_
pends_hndlr:
	b	pends_hndlr

_func_
tick_hndlr:
	mrs	rvc, psp		@ rvc <- psp stack
	set	sp,  rvc		@ sp  <- psp stack, for genis0
	@ *** Workaround for Cortex-M3 errata bug #382859, Category 2,
	@ *** present in r0p0, fixed in r1p0,
	@ *** affects LM3S1968 (needed for multitasking)
	ldr	rvb, [sp, #28]		@ rvb <- saved xPSR
	ldr	rva, =0x0600000c	@ rva <- msk to id if ldm/stm intrptd
	tst	rvb, rva		@ was interruted instruction ldm/stm?
	itT	eq
	biceq	rvb, rvb, #0xf0		@	if so,  rvb <- xPSR to restart
	streq	rvb, [sp, #28]		@	if so,  store xPSR back on stack
	@ *** end of workaround
	ldr	rva, =systick_base
	ldr	rvb, [rva, #tick_ctrl]	@ clear the tick flag
	set	rvb, #0x05
	str	rvb, [rva, #tick_ctrl]	@ disab systick int generation (if set)
@	set	rvb, #64		@ rvb <-  64 = interrupt num for systick
	set	rvb, #0xff		@ rvb <- 255 = interrupt num for systick
	b	genis0

_func_
svc_hndlr:
	mrs	rva, psp		@ rva <- psp stack
	ldr	rvc, [rva, #24]		@ rvc <- saved lnk_irq (pc_usr) frm stk
	ldrh	rvb, [rvc, #-2]		@ rvb <- svc instruction, incl its arg
	and	rvb, rvb, #0xff		@ rvb <- argument of svc
	eq	rvb, #isr_no_irq	@ stay in irq mode and continue?
	itTT	eq
	seteq	sp,  rva		@ 	if so,  sp  <- psp stack
	addeq	sp,  sp, #32		@ 	if so,  sp  <- psp stack, updatd
	seteq	pc,  rvc		@	if so,  return, in IRQ mode
svcigc:	@ [internal entry from genism]
	ldr	cnt, =int_en_base
	eq	rvb, #run_normal	@ enable interrupts?
	it	ne
	addne	cnt, cnt, #int_disab1
	@ enable/disable scheme interrupts
	ldr	rva, =BUFFER_START
	vcrfi	fre, rva, CTX_EI_offset	   @ fre <- enabled scheme ints   0--31
	str	fre, [cnt, #0x00]
.if num_interrupts > 32
	vcrfi	fre, rva, CTX_EI_offset+4  @ fre <- enabled scheme ints  32--63
	str	fre, [cnt, #0x04]
.endif
.if num_interrupts > 64
	vcrfi	fre, rva, CTX_EI_offset+8  @ fre <- enabled scheme ints  64--95
	str	fre, [cnt, #0x08]
.endif
.if num_interrupts > 96
	vcrfi	fre, rva, CTX_EI_offset+12 @ fre <- enabled scheme ints  96-127
	str	fre, [cnt, #0x0C]
.endif
.if num_interrupts > 128
	vcrfi	fre, rva, CTX_EI_offset+16 @ fre <- enabled scheme ints 128-159
	str	fre, [cnt, #0x10]
.endif
	mrs	rva, control		@ rva  <- content of Processor Cntrl reg
	eq	rvb, #run_prvlgd	@ set thread mode to privileged, no irq?
	itE	eq
	biceq	rva, rva, #0x01		@ 	if so,  rva  <- prvlgd Thread bt
	orrne	rva, rva, #0x01		@ 	if not, rva  <- unprvlgd Thrd bt
	msr	control, rva		@ set Thread mode to privil/unprivileged
	ldr	pc,  =0xfffffffd	@ return to thread mode, w/process stack


.ifdef	enable_MPU

_func_
hptp2mpu: @ update MPU for new heaptop(s)
	@ called via:	bl, entered right after "swi run_prvlgd" so dsb/isb
	@						not needed on entry
	@ called with:	mcu in privileged mode (set before call)
	@ modifies:	rvb, rvc
	@ returns via:	lnk
	ldr	rvc, =mpu_base		@ rva      <- address of MPU_TYPE
	set	rvb, #3
	str	rvb, [rvc, #0x08]	@ MPU_RNR  <- set region to 3
	set	rvb, #0x0008		@ rvb      <- size = 32B
	strh	rvb, [rvc, #0x10]	@ MPU_RASR <- set region size (disabled)
  .ifndef mark_and_sweep
	vcrfi	rvb, glv, 9		@ rvc <- heaptop0 -- from global vector
  .else
	vcrfi	rvb, glv, 1		@ rva <- heaptop -- from global vector
  .endif
	bic	rvb, rvb, #i0		@ rvb      <- heaptop region (32B align)
	str	rvb, [rvc, #0x0c]	@ MPU_RBAR <- set region start address
	ldr	rvb, =0x02040009	@ rvb      <- nrm hndl rw,usr ro,shr,32B
	str	rvb, [rvc, #0x10]	@ MPU_RASR <- set regn attrs (enabled)
  .ifndef mark_and_sweep
	set	rvb, #4
	str	rvb, [rvc, #0x08]	@ MPU_RNR  <- set region to 4
	set	rvb, #0x0008		@ rvb      <- size = 32B
	strh	rvb, [rvc, #0x10]	@ MPU_RASR <- set region size (disabled)
	vcrfi	rvb, glv, 10		@ rvb      <- heaptop1 from global vec
	bic	rvb, rvb, #i0		@ rvb      <- heaptop region (32B align)
	str	rvb, [rvc, #0x0c]	@ MPU_RBAR <- set region start address
	ldr	rvb, =0x02040009	@ rvb      <- nrm hndl rw,usr ro,shr,32B
	str	rvb, [rvc, #0x10]	@ MPU_RASR <- set region attributes
  .endif
	dsb				@ complete outstanding data accesses
	isb				@ complete outstanding instructions
	set	pc,  lnk		@ return
.endif

_func_
isrreset: @ soft reset when heap is exhausted and system is in IRQ Handler mode
	mrs	rva, control		@ rva  <- content of Processor Cntrl reg
	bic	rva, rva, #0x01		@ rva  <- bit for privilegd Thread mode
	msr	control, rva		@ set Thread mode to privlgd (for reset)
	mrs	rvc, psp		@ rvc <- psp stack
	ldr	rvb, =reset		@ rvb <- address of reset routine
	str	rvb, [rvc, #24]		@ set saved pc_usr (lnk_irq) for reset
	set	rvb, #normal_run_mode	@ rvb <- normal run mode
	str	rvb, [rvc, #28]		@ set normal run mode in saved xPSR
	ldr	pc,  =0xfffffffd	@ jump to reset in privileged thread mod

_func_
reset0:	@ soft reset when scheme heap is exhausted
	bl	rldon			@ turns on red (or other) led
	bl	gldoff			@ turns on green led (or other)
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ
	@ continue to reset (below)

_func_
reset:	@ enable MPU if desired (done in privileged mode)
.ifdef	enable_MPU
	@ for cortex-M4 MPU and memory map
	ldr	rva, =mpu_base		@ rva      <- address of MPU_TYPE
	set	rvb, #5			@ rvb      <- bit to enab MPU w/dflt map
	str	rvb, [rva, #0x04]	@ MPU_CTRL <- enable MPU
	set	rvb, #0x10		@ rvb      <- region 0 adrs=0x00, valid
	str	rvb, [rva, #0x0c]	@ MPU_RBAR <- set region start address
	ldr	rvb, =0x0306003f	@ rvb      <- norml mem rw,shar,cach,4GB
	str	rvb, [rva, #0x10]	@ MPU_RASR <- set region attributes
	set	rvb, #0x11		@ rvb      <- region 1 adrs=0x00, valid
	str	rvb, [rva, #0x0c]	@ MPU_RBAR <- set region start address
	ldr	rvb, =0x13051b3f	@ rvb      <- dev xn,rw,share,4GB w/hols
	str	rvb, [rva, #0x10]	@ MPU_RASR <- set region attributes
	ldr	rvb, =0xe0000012	@ rvb      <- region 2 adrs=0xe0000000
	str	rvb, [rva, #0x0c]	@ MPU_RBAR <- set region start address
	ldr	rvb, =0x13040027	@ rvb      <- strng-ordrd xn,rw,shar,1MB
	str	rvb, [rva, #0x10]	@ MPU_RASR <- set region attributes
	ldr	rva, =0xe000ed24	@ rva <- address of SHCSR register
	set	rvb, #(1 << 16)		@ rvb <- bit to enab rprtng MemMng Fault
	str	rvb, [rva]		@ enable MemManage fault handling
.endif
.ifdef	hardware_FPU
	@ enable FPU if desired (done in privileged mode, enables all access)
	ldr	rva, =0xe000ed88	@ rva    <- address of CPACR
	ldr	rvb, [rva]		@ rvb    <- contents of CPACR
	orr	rvb, rvb, #(0xf << 20)	@ rvb    <- bits 20-23 enab CP10,11 FPU
	str	rvb, [rva]		@ CPACR <- enable FPU
	dsb				@ wait for store (bit 20-23) to complete
	isb				@ wait for instr to complete (FPU enbld)
	vmrs	rva, fpscr		@ rva    <- contents of FPSCR
	orr	rva, rva, #0x00c00000	@ rva    <- round towards zero (trunc)
	vmsr	fpscr, rva		@ FPSCR <- updated rounding mode
	ldr	rva, =0xe000ef34	@ rva    <- address of FPCCR
	set	rvb, #0			@ rvb    <- all bits cleared
	str	rvb, [rva]		@ FPCCR <- no FPU reg stacking on int
	dsb				@ wait for store to complete
	isb				@ wait for instruction to complete
.endif
	@ configure Process Stack, select it and drop to User mode
	ldr	rva, =MAIN_STACK - 88	@ rva  <- address of Process Stack
	msr	psp, rva		@ Set Process stack address
	mrs	rva, control		@ rva  <- content of Processor Cntrl reg
	orr	rva, rva, #0x02		@ rva  <- code to use Process stack
.ifdef	hardware_FPU
	bic	rva, rva, #0x04		@ rva  <- clear FPCA bit (make sure)
.endif
	orr	rva, rva, #0x01		@ rva  <- bit for User (unpriv) mode
	msr	control, rva		@ drop to unprivlgd mode, Process stack



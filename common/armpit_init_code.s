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
@  I.B.3. Scheme Initialization ALL ARCHITECTURES
@
@-------------------------------------------------------------------------------

_func_
_code_:	@ hardware and scheme system initialization
	bl	hwinit			@ initialize the hardware
scinit:	@ initialize the scheme system
	ldr	fre, =heapbottom	@ initialize free-pointer {fre}
  .ifdef mark_and_sweep
	add	fre, fre, #40		@ fre <- for 8B-aligned reg sav in gc
  .endif
	set	sv1, #null
	@
	@ initialize fixed (main system) buffer
	@
	ldr	sv3, =BUFFER_START
	ldr	rva, =BUF_bv_tag
	str	rva, [sv3, #-4]
	set	rvb, #0
	vcsti	sv3, FILE_LOCK, rvb	@ set file lock to free state
	@ ISR vector initialization
	ldr	rva, =ISR_vector
	vcsti	sv3, ISR_V_offset, rva
	@ prepare the readbuffer
	ldr	sv2, =READBUFFER
	ldr	rva, =RBF_bv_tag
	str	rva, [sv2, #-4]
	set	rvb, #i0
	vcsti	sv2, 0, rvb
	vcsti	sv3, READ_BF_offset, sv2 @ set readbuffer address in main buffer
	@ prepare the writebuffer
.ifndef	WRITEBUFFER
	vcsti	sv3, WRITE_BF_offset, sv1 @ set writebfr adrs to () in main bfr
.else
	ldr	sv2, =WRITEBUFFER
	ldr	rva, =WBF_bv_tag
	str	rva, [sv2, #-4]
	set	rvb, #i0
	vcsti	sv2, 0, rvb
	vcsti	sv3, WRITE_BF_offset, sv2 @ set writebuffer address in main bfr
.endif
.ifdef	include_i2c
	@ i2c initialization
	set	rvb, #f
	vcsti	sv3, I2C0_BF_offset,   rvb	@ set busy status to #f for I2C0
	vcsti	sv3, I2C0_BF_offset+4, rvb	@ set data ready  to #f for I2C0
	vcsti	sv3, I2C1_BF_offset,   rvb	@ set busy status to #f for I2C1
	vcsti	sv3, I2C1_BF_offset+4, rvb	@ set data ready  to #f for I2C1
.endif
.ifdef	cortex	@
	ldr	rvb, =scheme_ints_en1
	vcsti	sv3, CTX_EI_offset, rvb		@ set enabled ints  0-31 in bfr
  .if num_interrupts > 32
	ldr	rvb, =scheme_ints_en2
	vcsti	sv3, CTX_EI_offset+4, rvb	@ set enabled ints 32-63 in bfr
  .endif
  .if num_interrupts > 64
	ldr	rvb, =scheme_ints_en3
	vcsti	sv3, CTX_EI_offset+8, rvb	@ set enabled ints 64-95 in bfr
  .endif
  .if num_interrupts > 96
	ldr	rvb, =scheme_ints_en4
	vcsti	sv3, CTX_EI_offset+12, rvb	@ set enabled ints 96-127 in bfr
  .endif
  .if num_interrupts > 128
	ldr	rvb, =scheme_ints_en5
	vcsti	sv3, CTX_EI_offset+16, rvb	@ set enabld ints 128-159 in bfr
  .endif
.endif
	@
	@ build new handler/utility global vector
	@
	add	glv, fre, #4		@ glv <- adrs of hndlr vec=1st fre-cel+4
	add	fre, fre, #72
	set	rva, #vector_tag
	orr	rva, rva, #(17 << 8)
	str	rva, [glv, #-4]
	vcsti	glv, 0, sv1		@ null, callbacks
	vcsti	glv, 2, sv1		@ null, i2c0 data
	vcsti	glv, 3, sv1		@ null, i2c1 data
	@ default io ports initialization
	ldr	sv2, =vuart0
	vcsti	glv, 4, sv2		@ default input/output port model
	@ store MAIN buffer in GLV
	vcsti	glv, 5, sv3		@ put MAIN buffer in GLV
	@ open-file-list initialization
	vcsti	glv, 6, sv1		@ null, initial open file list	
	@ initialize obarray to '()
	vcsti	glv, 8, sv1		@ obarray
	@ initialize heaptop, heaptop-0/1
	ldr	rva, =heaptop0
.ifdef	enable_MPU
  .ifdef mark_and_sweep
	sub	rva, rva, #32		@ rva <- heaptop dcrsd below grey set
  .endif
.endif
	orr	rva, rva, #i0
	vcsti	glv, 1, rva		@ heaptop = heaptop0
	vcsti	glv, 9, rva		@ heaptop0 (stop-copy) or Xtra File RAM
	ldr	rva, =heaptop1
.ifdef mark_and_sweep
	add	rva, rva, #EXTRA_FILE_RAM @ rva <- grey set start address
.endif
	orr	rva, rva, #i0
	vcsti	glv, 10, rva		@ heaptop1 (stop-copy) or grey-set adrs
	@ store built-in environment in global vector
	ldr	rvb, =scmenv
	vcsti	glv, 13, rvb		@ set built-in environment in glv
	vcsti	glv, 14, sv1		@ set lib-building/parse mode1 to null
	vcsti	glv, 15, sv1		@ set lib-building/parse mode2 to null
	@ initialize primitive pre-function entry table
	ldr	rva, =paptbl
	vcsti	glv, 16, rva
	@ initialize environment to (((_winders . null) (_catch . #<primitive>)
	@ (_prg . boot-or-not))) and store it in GLV
	set	env, fre
	add	rva, fre, #8
	stmia	fre!, {rva, sv1}
.ifdef top_level_btree
	set	rvb, #vector_tag
	orr	rvb, rvb, #0x300
	add	sv2, fre, #16
	add	sv3, fre, #24
	add	sv4, fre, #48
	ldr	sv5, =catch_var
	ldr	rvc, =catch
	stmia	fre!, {rvb,sv2-sv5,rvc}
	add	sv2, fre, #16
	set	sv3, #null
	set	sv4, #null
	ldr	sv5, =winders_var
	set	rvc, #null
	stmia	fre!, {rvb,sv2-sv5,rvc}
	add	sv2, fre, #16
	ldr	sv5, =program_var
	stmia	fre!, {rvb,sv2-sv5,rvc}
.else	@ non-btree	
	add	rvb, fre, #8
	add	sv2, fre, #16
	ldr	sv3, =winders_var
	set	sv4, #null
	add	sv5, fre, #24
	add	rvc, fre, #32
	stmia	fre!, {rvb, sv2-sv5, rvc}
	ldr	rvb, =catch_var
	ldr	sv2, =catch
	add	sv3, fre, #16
	ldr	sv5, =program_var
	set	rvc, #null
	stmia	fre!, {rvb, sv2-sv5, rvc}
.endif
	bl	FlashInitCheck		@ rva <- status of boot override pin
	eq	rva, #0			@ is pin low?
	itE	eq
	seteq	sv5, #f			@	if so,  sv5 <- #f=dont load boot
	setne	sv5, #t			@	if not, sv5 <- #t=do load boot
	str	sv5, [fre, #-4]		@ bind boot-or-not with _prg in env
	vcsti	glv, 7, env		@ set env into glv
	@ initialize flash file and library limits
	@ and store them in GLV
.ifndef	LIB_TOP_PAGE
  .ifndef live_SD
	ldr	sv3, =F_END_PAGE
	orr	sv3, sv3, #i0
  .else
	set	sv3, #i0
  .endif
	vcsti	glv, 11, sv3		@ set file flash end page in glv
	vcsti	glv, 12, sv1		@ set lib start page to '() in glv
.else	
	@ update file flash limits for possible flash library
	ldr	sv2, =LIB_TOP_PAGE
	ldr	sv3, =F_END_PAGE
	set	sv4, sv2
flbchk:	sub	sv4, sv4, F_PAGE_SIZE
	ldr	rva, [sv4]
	mvns	rva, rva		@ is flash cell empty (#xffffffff)?
	bne	flbchk
	add	sv4, sv4, F_PAGE_SIZE
	eq	sv4, sv2
	it	eq
	seteq	sv4, #null
	vcsti	glv, 12, sv4		@ set lib start page in glv
  .ifdef  SHARED_LIB_FILE
	beq	flbskp
	set	sv2, sv4		@ sv2 <- lib start page adrs for pgsctr
	bl	pgsctr			@ rva <- lib start sector (raw int)
	set	rvc, rva		@ rvc <- lib start sectr (raw int, savd)
	set	sv2, sv3
	bl	pgsctr			@ rva <- fil crunch space sctr (raw int)
	cmp	rva, rvc
	itTT	pl
	subpl	rva, rvc, #1
	ldrpl	rvc, =flashsectors
	ldrpl	sv3, [rvc, rva, lsl #2]
flbskp:	
  .endif @ SHARED_LIB_FILE
	orr	sv3, sv3, #i0
	vcsti	glv, 11, sv3		@ set file flash end page in glv
.endif
.ifdef	enable_MPU
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ
	bl	hptp2mpu		@ update MPU for heaptop(s)
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ
.endif
	@ initialize scheme stack to cycle over null stack-bottom
	ldr	dts, =stkbtm
	@ de-reserve memory
	orr	fre, fre, #0x02
	@ enable IRQ
	enable_VIC_IRQ	
.ifndef	exclude_read_write
	@ start resident program (REP)
	ldr	sv1, =prgstr
	call	pparse
	b	eval
.endif

@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg






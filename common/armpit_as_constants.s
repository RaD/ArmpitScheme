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

@===============================================================================
@
@ Contributions:
@
@     This file includes contributions by Robbie Dinn, marked <RDC>
@
@===============================================================================

@-------------------------------------------------------------------------------
@
@  0.E.	  Scheme Tags and Constants
@
@-------------------------------------------------------------------------------

@ tags and constants:
@ a) Immediate tags
@ a1) numbers & pointers
pointer_tag	= 0x00
int_tag		= 0x01			@ integer tag
float_tag	= 0x02			@ float tag
@ a2) var/synt, broken-heart, offset-tag
broken_heart	= 0x9F			@ 
variable_tag	= 0xAF
@ a3) ground items
scheme_null	= 0x0F
scheme_true	= 0x1F
scheme_false	= 0x2F
char_tag	= 0x3F
@ b) non-Immediate tags
@ b1) sized -- non-gceable
symbol_tag	= 0x7F			@ #x30 mask used in gc to id non-gceable
string_tag	= 0x5F			@ 
bytevector_tag	= 0x6F			@ 
@ b2) sized -- gceable
vector_tag	= 0x4F			@ vector
@ b3) implicitly sized
builtin_tag	= 0xD7			@ built-in procedure or syntax (4W)
procedure	= 0xDF			@ procedure, continuation or macro (4W)
@ c) 8-byte (4-bit tag)
rational_tag	= 0x03
complex_tag	= 0x0B

@ list tag reported by typchk, typsv1
@ (lists are not type tagged in the internal representation)
list_tag	= 0xFF

@ abbreviations
t	= scheme_true
f	= scheme_false
null	= scheme_null
i0	= int_tag
i1	=  (1 << 2) | i0
i2	=  (2 << 2) | i0
i3	=  (3 << 2) | i0
i4	=  (4 << 2) | i0
i5	=  (5 << 2) | i0
i6	=  (6 << 2) | i0
i7	=  (7 << 2) | i0
i8	=  (8 << 2) | i0
i9	=  (9 << 2) | i0
i10	= (10 << 2) | i0
i32	= (32 << 2) | i0
i33	= (33 << 2) | i0
i34	= (34 << 2) | i0
f0	= float_tag
npo	= char_tag
proc	= procedure
bltn	= builtin_tag

@ floating point constants
scheme_inf	= 0x7F800002
scheme_nan	= 0x7F800006
scheme_pi	= 0x40490FDA	@ 0100-0000-0100-1001-0000-1111-1101-1010 pi
scheme_two_pi	= 0x40C90FDA	@ 0100-0000-1100-1001-0000-1111-1101-1010 2*pi
scheme_half_pi	= 0x3FC90FDA	@ 0011-1111-1100-1001-0000-1111-1101-1010 pi/2
scheme_log_two	= 0x3F317216	@ 0011-1111-0011-0001-0111-0010-0001-0110 (ln 2)
scheme_two	= 0x40000002	@ 0100-0000-0000-0000-0000-0000-0000-0010 two
scheme_one	= 0x3F800002	@ 0011-1111-1000-0000-0000-0000-0000-0010 one
scheme_1p5	= 0x3FC00002	@ 0011-1111-1100-0000-0000-0000-0000-0010 1.5
scheme_0p5	= 0x3F000002	@ 0011-1111-0000-0000-0000-0000-0000-0010 0.5
scheme_e	= 0x402DF856	@ 0100-0000-0010-1101-1111-1000-0101-0110 e
scheme_em1	= 0x3EBC5AB6	@ 0011-1110-1011-1100-0101-1010-1011-0110 1/e

@ punctuation
backspace_char	= (0x08 << 8) | char_tag	@     backspace
tab_char	= (0x09 << 8) | char_tag	@	tab
lf_char		= (0x0A << 8) | char_tag	@     lf
cr_char		= (0x0D << 8) | char_tag	@     cr
newline_char	= (0x0D << 8) | char_tag	@     cr
space_char	= (0x20 << 8) | char_tag	@     space
dbl_quote_char	= (0x22 << 8) | char_tag	@  "  double quote "
pound_char	= (0x23 << 8) | char_tag	@  #  pound
open_par_char	= (0x28 << 8) | char_tag	@  (  open parenthesis
close_par_char	= (0x29 << 8) | char_tag	@  )  close parenthesis
dot_char	= (0x2E << 8) | char_tag	@  .  dot
at_char		= (0x40 << 8) | char_tag	@  @  at char
backslash_char	= (0x5C << 8) | char_tag	@  \  backslash
eof		= 0x03				@     eof = ctrl-c
eof_char	= (eof << 8) | char_tag		@     eof char

/*------------------------------------------------------------------------------
@	
@	dummy sub-environments and pre-entry function labels for
@	items not included in assembly based on configuration switches
@	(used at labels scmenv: and/or paptbl: in armpit_050.s).
@
@-----------------------------------------------------------------------------*/

@ define dummy labels for sub-environments that are not included
@ based on configuration options.

.ifdef	exclude_read_write
  rw_env = empty_vector
.endif

.ifdef	CORE_ONLY
  libenv = empty_vector
.endif

.ifndef	include_system0
  s0_env = empty_vector
.endif


@ define dummy labels for common pre-entry functions that are not included
@ based on configuration options.

.ifdef	integer_only
  unijmp = corerr
  numgto = corerr
.endif

.ifdef CORE_ONLY
  mmglen = corerr
  cxxxxr = corerr
.endif

.ifndef include_r6rs_fx
  fxchk2 = corerr
.endif
	
/*------------------------------------------------------------------------------
@	
@	dummy ISR labels for cases where USB or I2C are
@	not included in assembly based on configuration switches
@	(used in ISR vector in mcu_specific/family/family_init_io.s).
@
@-----------------------------------------------------------------------------*/

.ifndef	include_i2c
	pi2isr = start_of_code + i0
.endif

.ifndef	native_usb
	usbisr = start_of_code + i0
.endif

	
/*------------------------------------------------------------------------------
@
@  0.F.	  REGISTER RENAMING for SCHEME
@
@-----------------------------------------------------------------------------*/

fre	.req r0		@ free pointer
cnt	.req r1		@ continuation (return address)
rva	.req r2		@ raw value a
rvb	.req r3		@ raw value b
sv1	.req r4		@ scheme value 1
sv2	.req r5		@ scheme value 2
sv3	.req r6		@ scheme value 3
sv4	.req r7		@ scheme value 4
sv5	.req r8		@ scheme value 5
env	.req r9		@ default environment
dts	.req r10	@ data stack
glv	.req r11	@ global vector
rvc	.req r12	@ raw value c
lnk	.req r14	@ jump link -- lr

/*------------------------------------------------------------------------------
@
@  0.B.   Common Definitions (heap size, buffers, code address)
@
@-----------------------------------------------------------------------------*/

ALLLED		= REDLED | YELLED | GRNLED

@
@ Note:	for stop-and-copy gc, each half-heap's size must be a multiple of 8
@	bytes. Thus, heaptop1 minus heapbottom must be a multiple of 16 bytes.
@	Given that RAMTOP and RAMBOTTOM are 16-byte aligned, the requirement is
@	met if stack_size, READBUFFER, RBF_size, WRITEBUFFER, WBF_size,
@	and EXTRA_FILE_RAM are all 16-byte aligned, and/or made so by choosing
@	appropriate 8 and/or 16 byte spacers below.
@

.ifdef	BUFFER_START
  .ifndef heapbottom
	heapbottom	= RAMBOTTOM
  .endif
.else
  .ifndef STR_7xx
    .ifndef  AT91_SAM7
	BUFFER_START	= RAMBOTTOM + 0x04	@ size 0x7c inc. tag, 4B bndry
    .endif
  .endif
  .ifdef STR_7xx	@ account for sp slippage on stm/ldm
	BUFFER_START	= RAMBOTTOM + 0x00A4	@ size is 0x7c including tag
  .endif
  .ifdef  AT91_SAM7	@ account for sp slippage on stm/ldm
	BUFFER_START	= RAMBOTTOM + 0x00A4	@ size is 0x7c including tag
  .endif
.endif

.ifndef cortex
	BUF_bv_tag	= (0x78 << 8) | bytevector_tag
	READBUFFER	= BUFFER_START + 0x80	@ must start on a 16B boundary+4
.else
  .if num_interrupts < 65
	BUF_bv_tag	= (0x78 << 8) | bytevector_tag
  .else
	BUF_bv_tag    = ((0x7C+((num_interrupts-65)&0x60)>>3)<<8)|bytevector_tag
  .endif
  .if num_interrupts > 96
	READBUFFER	= BUFFER_START + 0x90	@ must start on a 16B boundary+4
  .else
	READBUFFER	= BUFFER_START + 0x80	@ must start on a 16B boundary+4
  .endif
.endif
	RBF_bv_tag	= ((RBF_size + 4) << 8) | bytevector_tag


.ifdef	WBF_size   
	WRITEBUFFER	= READBUFFER  + RBF_size + 8 @ above readbuffer + tag & pos
	heapbtm_ges	= WRITEBUFFER + WBF_size + 4
	WBF_bv_tag	= ((WBF_size + 4) << 8) | bytevector_tag
.else
	heapbtm_ges	= READBUFFER  + RBF_size + 12
.endif

.ifndef heapbottom
  .ifndef enable_MPU
	heapbottom	= heapbtm_ges	@ above main and read buffers, 16B align
  .else
    .ifndef mark_and_sweep
	heapbottom	= (heapbtm_ges + 63) & 0xffffffc0
    .else
	heapbottom	= heapbtm_ges	@ above main and read buffers, 16B align
    .endif
  .endif
.endif



@ --------- HEAP -----------

/* define default top of main stack for cortex-m3/m4 */
.ifdef	cortex
  .ifndef MAIN_STACK
	MAIN_STACK 	= RAMTOP
  .endif
.endif

/* non-default stack_size is defined in device_family.h if needed */
.ifndef	stack_size
	stack_size	= 160		@ 0xA0
.endif

/* non-zero EXTRA_FILE_RAM is defined in device_family.h if needed */
.ifndef EXTRA_FILE_RAM
	EXTRA_FILE_RAM	= 0
.endif


.ifdef mark_and_sweep
	grey_set_size	= (RAMTOP - RAMBOTTOM) >> 8 	@ grey/black size, words
	heap_div	= 0
  .ifdef enable_MPU
	heaptop_mask	= 0xffffffe0
  .endif
.else
	grey_set_size	= 0
	heap_div	= 1
  .ifdef enable_MPU
	heaptop_mask	= 0xffffffc0
	heap_margin	= 64
  .endif
.endif
.ifndef heaptop_mask
	heaptop_mask	= 0xffffffff
.endif
.ifndef heap_margin
	heap_margin	= 0
.endif

heaptop_ges	= RAMTOP - stack_size - EXTRA_FILE_RAM - grey_set_size << 3
heaptop1	= heaptop_ges & heaptop_mask
heaptop0	= (heaptop1 - heapbottom - heap_margin) >> heap_div + heapbottom


/* --------- BUFFERS ----------- */
FILE_LOCK	=  0
ISR_V_offset	=  1
READ_BF_offset	=  2
@ space for I2C0ADR at offset = 3, BUFFER_START + 0x0C, (eg. AT91SAM7, EP9302)
I2C0_BF_offset	=  4
I2C1_BF_offset	=  9
WRITE_BF_offset	= 14
USB_CONF_offset	= 15
USB_DATA_offset	= 16
USB_CHNK_offset	= 18
USB_LC_offset	= 20
USB_ST_BF_offset= 22
USB_BK_DT_offset= 24
USB_ZERO_offset	= 26
CTX_EI_offset	= 28
@ writebuffer is now set in MCU specific .h files

	
F_LOCK		= BUFFER_START + FILE_LOCK   << 2
.ifndef	I2C0ADR
  I2C0ADR	= BUFFER_START + 0x0C
.endif
I2C0BUFFER	= BUFFER_START + I2C0_BF_offset   << 2
I2C1BUFFER	= BUFFER_START + I2C1_BF_offset   << 2
USB_CONF	= BUFFER_START + USB_CONF_offset  << 2
USB_DATA	= BUFFER_START + USB_DATA_offset  << 2
USB_CHUNK	= BUFFER_START + USB_CHNK_offset  << 2
USB_LineCoding	= BUFFER_START + USB_LC_offset    << 2
USB_SETUP_BUFFER= BUFFER_START + USB_ST_BF_offset << 2
USB_BULK_DATA	= BUFFER_START + USB_BK_DT_offset << 2
USB_ZERO	= BUFFER_START + USB_ZERO_offset  << 2
	

/* ----- DEFAULT CODE ADDRESSES ------------------------ */
@ Specify where to store scheme+reset code (.text section)
@ scheme data (.data section)
@ and boot code (boot section) in MCU FLASH or RAM
/* non-default addresses (if any) are in device_family.h */

.ifndef	_text_section_address_
	_text_section_address_	= 0x00000000	@ where scheme  code is stored
.endif
.ifndef	_text_link_address_
	_text_link_address_	= 0x00000000	@ where scheme code runs from
.endif
	code_size_16		= (((end_of_code + 15 - start_of_code) >> 4) << 4)
.ifndef	_data_section_address_
	_data_section_address_	= _text_section_address_ + (((end_of_code + 15 - start_of_code) >> 4) << 4)
.endif
.ifndef	_data_link_address_
	_data_link_address_	= _text_link_address_ + (((end_of_code + 15 - start_of_code) >> 4) << 4)
.endif
.ifndef	_boot_section_address_
	_boot_section_address_	= 0x00010000	@ where startup code runs from
.endif


/* ---- DEFAULT USB REGISTER FOR EP INT CLEARING --------------------- */
/* non-default usb_iclear_dvep is defined in device_family.h if needed */
.ifdef	native_usb			@ if USB is enabled
  .ifdef  usb_iclear_dv			@ + MCU needs EP int clrd in Dev
     .ifndef  usb_iclear_dvep		@ + MCU doesn't use special reg
     usb_iclear_dvep = usb_iclear_dv	@ then EP int is cleared in this
     .endif
  .endif
.endif


/*----------------------------------------------------------------------------*/


@ ARM MCU interrupts definitions (ARCHv4T, not Cortex)

IRQ_disable	= 0x80
FIQ_disable	= 0x40

/*------------------------------------------------------------------------------
@
@  0.D.	  RUNNING MODES and SWP instruction
@
@-----------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------
@
@ Note:	 lnkbit0 is needed, on cortex, by operations where lnk is stored in a
@ scheme register, and needs to lose (bic) its lsb (which is 1 for THUMB mode)
@ so that it becomes gc-safe. Similarly, restoring lnk from a scheme register
@ needs it to be orred with this lnkbit0.
@
@-----------------------------------------------------------------------------*/

.ifndef cortex
	run_normal	= 0x10		@ user mode with    interrupts
	normal_run_mode	= 0x10
	run_no_irq	= 0x90		@ user mode without interrupts
	isr_normal	= 0x12		@ IRQ  mode with    interrupts
	isr_no_irq	= 0x92		@ IRQ  mode without interrupts
	lnkbit0		= 0		@ used to keep lnk in ARM mode
  .ifndef cortex_a8
	mcu_has_swp	= 1		@ MCU supports SWP instruction
  .endif
.else
	run_normal	= 0x10
	normal_run_mode	= 0x01000000	@ xPSR with bit 24 (Thumb mode) set
	run_prvlgd	= 0x99		@ privileged mode: thread,prvlgd,no IRQ
	run_no_irq	= 0x90		@ user mode without interrupts
	isr_normal	= 0x12		@ IRQ  mode with    interrupts, not used
	isr_no_irq	= 0x92		@ IRQ  mode without interrupts
	lnkbit0		= 1		@ used to keep lnk in THUMB mode
.endif








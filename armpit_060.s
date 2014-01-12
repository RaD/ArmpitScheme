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

/*==============================================================================
@
@ Contributions:
@
@     This file includes contributions by Robbie Dinn, marked <RDC>
@     This file includes contributions by Petr Cermak, marked <PCC>
@
@=============================================================================*/

@-------------------------------------------------------------------------------
@  Select MCU-ID (for variables and i2c) (use even address, min=2, max=254)
@-------------------------------------------------------------------------------

@mcu_id		= 2			@ set i2c address of   1 (i.e.   2 / 2)
mcu_id		= 200			@ set i2c address of 100 (i.e. 200 / 2)
@mcu_id		= 254			@ set i2c address of 127 (i.e. 254 / 2)

@-------------------------------------------------------------------------------
@  Specify board- and device-specific constants and macros
@-------------------------------------------------------------------------------

.include "board.h"			@ Parameters Specific to each Board
.include "device_family.h"		@ HARDWARE CONSTANTS for each MCU Family

.ifndef	small_memory

  @-------------------------------------------------------------------------------
  @  Assembly options for most MCUs
  @  Check that .bin file is below 64 KB after re-assembly (approx. 60KB
  @  for live_SD versions of TI_Beagle(_XM) and GMX_OVERO_TIDE).
  @-------------------------------------------------------------------------------
  mark_and_sweep	= 1		@ use mark-and-sweep garbage collection
  oba_above_heap	= 1		@ store obarray above the heap
  include_r6rs_fx	= 1		@ include R6RS fx+, fx-, ...
  include_system0	= 1		@ include system-0 (gpio bindings ...)
  fast_eval_apply 	= 1		@ use faster eval/apply for 1-3 var/args
  fast_lambda_lkp 	= 1		@ use fast var lookup inside closures

.else

  @-----------------------------------------------------------------------------
  @  Assembly options for small memory MCUs:	NXP 2131, 2103, 1343
  @  Check that .bin file is below 24 KB after re-assembly.
  @-----------------------------------------------------------------------------
  mark_and_sweep	= 1		@ use mark-and-sweep garbage collection
  CORE_ONLY		= 1		@ remove armpit_scheme_library.s
  integer_only		= 1		@ remove float, complex, rationals
  exclude_pack		= 1		@ exclude the pack function
  r3rs			= 1		@ restrict language to R3RS scheme
  include_system0	= 1		@ include system-0 (gpio bindings ...)

.endif

@-------------------------------------------------------------------------------
@  Additional assembly options for most MCUs
@  For regular MCUs: uncomment if desired.
@  Note: these options are not used in distribution but could be useful.
@  Check that .bin file is below 24KB/60KB/64KB after re-assembly.
@-------------------------------------------------------------------------------

@inline_cons	= 1	@ uncomment to use inlined cons and save functions
@top_level_btree	= 1	@ uncomment to use a btree for top-level env
@include_i2c	= 1	@ uncomment to include the I2C subsystem (if available)
@exclude_read_write = 1	@ uncomment to exclude read (parse...), write, display
	
@-------------------------------------------------------------------------------
@
@   PROGRAM CODE:
@
@	Assembler Constants
@	Assembler Macros
@	Reset and Initialization code
@	MCU-Dependent Initialization and I/O Routines
@	Turning LEDs on/off
@	Scheme environment, functions and ports
@	Startup Code for LPC_2800, EP_93xx, S3C24xx, OMAP_35xx -- .data section
@
@-------------------------------------------------------------------------------
	
@-------------------------------------------------------------------------------
@ Assembler Constants and Macros
@-------------------------------------------------------------------------------

.include "armpit_as_constants.s"	@ armpit assembly constants for scheme
.include "armpit_as_macros.s"		@ armpit assembly macros for scheme

@-------------------------------------------------------------------------------
@ Various assembler/linker parameters
@-------------------------------------------------------------------------------

.syntax unified				@ enable Thumb-2 mode

.global _start
.global _code_
.global	_text_link_address_		@ code address when system is running
.global _text_section_address_		@ code address in FLASH
.global	_data_link_address_		@ data address when system is running
.global _data_section_address_		@ data address in FLASH
.global _boot_section_address_		@ startup code address in FLASH (if any)

/*------------------------------------------------------------------------------
@ Code instructions section (.text)
@-----------------------------------------------------------------------------*/

.text					@ code (_start label) link at 0x00

@-------------------------------------------------------------------------------
@ Reset and Initialization
@-------------------------------------------------------------------------------

start_of_code:

.ifndef	cortex
  .include "armpit_reset_ARM.s"	@ int vects+resets for arm7tdmi,cortexa8
.else
  .include "armpit_reset_CM3.s"	@ int vects+resets for cortex-m3/-m4
.endif

.include "armpit_init_code.s"		@ initialization code init glv, enab int
.include "init_io_code.s"		@ MCU-dependent initialization and I/O 

@-------------------------------------------------------------------------------
@  Turning LEDs on/off
@
@	There are two types of LED on/off approaches:
@	  The default is where the MCU has separate SET and CLEAR registers
@	  otherwise, the has_combined_set_clear flag needs to be set,
@         for single register MCUs
@-------------------------------------------------------------------------------

_func_	
yldon:	ldr	rvb, =YELLED
	b	ledon
_func_	
gldon:	ldr	rvb, =GRNLED
	b	ledon
_func_	
rldon:	ldr	rvb, =REDLED
_func_	
ledon:
.ifdef has_combined_set_clear
	ldr	rva, =LEDIO
	ldr     rva, [rva, #io_set]
	orr	rvb, rvb, rva
.endif
	ldr	rva, =LEDIO
	str     rvb, [rva, #io_set]
	set	pc,  lnk
	
_func_	
yldoff:	ldr	rvb, =YELLED
	b	ledoff
_func_	
gldoff:	ldr	rvb, =GRNLED
	b	ledoff
_func_	
rldoff:	ldr	rvb, =REDLED
_func_	
ledoff:
.ifdef has_combined_set_clear
	ldr	rva, =LEDIO
	ldr     rva, [rva, #io_clear]
	bic	rvb, rva, rvb
.endif
	ldr	rva, =LEDIO
	str     rvb, [rva, #io_clear]
	set	pc,  lnk

@-------------------------------------------------------------------------------
@ Scheme code
@-------------------------------------------------------------------------------

.include "armpit_core_code.s"
.include "armpit_scheme_base_code.s"

.ifdef	native_usb
  .include "usb.s"			@ MCU-dependent functions of USB I/O,ISR
.endif
.include "armpit_ports_code.s"

.ifndef	exclude_read_write
  .include "armpit_scheme_read_write_code.s"
.endif

.ifndef	CORE_ONLY
  .include "armpit_scheme_library_code.s"
.endif

.include "armpit_scheme_r6rs_library_code.s"

.ifdef include_system0
  .include "system_0_code.s"
.endif

end_of_code:

/*------------------------------------------------------------------------------
@ Code data section (.data for Harvard split option)
@-----------------------------------------------------------------------------*/

.ifdef harvard_split

.data	@ -------- start of .data section with Harvard split -------------------

.endif

start_of_data:

/*-------.-------.-------.-------.-------.--------------------------------------
|*	Scheme environment, functions and ports				 	
\*-------.-------.-------.-------.-------.--------------------------------------

	/*-------.-------.-------.-------.-------.-------*\
--------|*	built-in environment			 *|
	\*-------.-------.-------.-------.-------.-------*/

		VECSIZE	(end_of_scmenv - scmenv) >> 2
scmenv:		.word	empty_vector	@ private sub-env (used in libraries)
core_env:	.word	corenv		@ 0.0.	Core
base_env:	.word	basenv		@ 4.1.	Primitive expression types
port_env:	.word	prtenv		@	Ports, keep at idx 2 or prt fail
rdwr_env:	.word	rw_env		@ 4.1.	Primitive expression types
lib_env:	.word	libenv		@ 4.2.	Derived expression types
r6lb_env:	.word	r6lenv		@	R6RS lib (2.bytvct,11.4bitwise)
sys0_env:	.word	s0_env		@	system 0

end_of_scmenv:	@ end of scmenv

	/*-------.-------.-------.-------.-------.-------*\
--------|*	empty sub-environment vector		 *|
	\*-------.-------.-------.-------.-------.-------*/

		VECSIZE	0		@ armpit_as_constants.s, absent sub-envs
empty_vector:

	/*-------.-------.-------.-------.-------.-------*\
--------|*	primtive pre-entry function table	 *|
	\*-------.-------.-------.-------.-------.-------*/
	@ secondary apply table for primitives that start with a jump
	@ pre-function indices (for EPFUNC) are computed below the table.

		VU8SIZE	(end_of_paptbl - paptbl)
paptbl:		.word	0x00		@ dummy (offst 0 = no pre-ntry in apply)
atypchk:	.word	typchk		@ armpit_core.s
areturn:	.word	return		@ armpit_core.s
aioprfn:	.word	ioprfn		@ arpit_ports.s
aprdnml:	.word	prdnml		@ scheme_base_6.2.Integers.s & Numbers.s
ardcnml:	.word	rdcnml		@ scheme_base_6.2.Integers.s & Numbers.s
aunijmp:	.word	unijmp		@ armpit_scheme_base_6.2.Numbers.s
anumgto:	.word	numgto		@ armpit_scheme_base_6.2.Numbers.s
ammglen:	.word	mmglen		@ armpit_scheme_base_6.2.Numbers.s
acxxxxr:	.word	cxxxxr		@ armpit_scheme_library.s
avu8ren:	.word	vu8ren		@ armpit_scheme_r6rs_library.s
abwloop:	.word	bwloop		@ armpit_scheme_r6rs_library.s
abwfent:	.word	bwfent		@ armpit_scheme_r6rs_library.s
aregent:	.word	regent		@ armpit_scheme_r6rs_library.s
afxchk2:	.word	fxchk2		@ armpit_scheme_r6rs_library.s

end_of_paptbl:	@ end of paptbl

	/*-------.-------.-------.-------.-------.-------*\
--------|*	pre-entry function table indices	 *|
	\*-------.-------.-------.-------.-------.-------*/

	otypchk	= (atypchk - paptbl) >> 2
	oreturn = (areturn - paptbl) >> 2
	oioprfn = (aioprfn - paptbl) >> 2
	oprdnml	= (aprdnml - paptbl) >> 2
	ordcnml	= (ardcnml - paptbl) >> 2
	ounijmp	= (aunijmp - paptbl) >> 2
	onumgto	= (anumgto - paptbl) >> 2
	ommglen	= (ammglen - paptbl) >> 2
	ocxxxxr	= (acxxxxr - paptbl) >> 2
	ovu8ren	= (avu8ren - paptbl) >> 2
	obwloop	= (abwloop - paptbl) >> 2
	obwfent	= (abwfent - paptbl) >> 2
	oregent = (aregent - paptbl) >> 2
	ofxchk2	= (afxchk2 - paptbl) >> 2

@ ------------------------------------------

.include "armpit_init_data.s"		@ initialization code init glv, enab int
.include "init_io_data.s"		@ MCU-dependent initialization and I/O 

@ ------------------------------------------

.include "armpit_core_data.s"
.include "armpit_scheme_base_data.s"
.include "armpit_ports_data.s"

.ifndef	exclude_read_write
  .include "armpit_scheme_read_write_data.s"
.endif

.ifndef	CORE_ONLY
  .include "armpit_scheme_library_data.s"
.endif

.include "armpit_scheme_r6rs_library_data.s"

.ifdef include_system0
  .include "system_0_data.s"
.endif

end_of_data:


.ifndef harvard_split

.data	@ ------- start of empty .data section without Harvard split -----------

.endif

/*------------------------------------------------------------------------------
@ boot section (if MCU needs separate startup)
@-----------------------------------------------------------------------------*/

.section boot_section, "ax"

.ifdef	include_startup
  .include "startup.s"		@ code for LPC_2800, EP_93xx, S3C24xx, OMAP_35xx
.endif

.ifdef run_from_ram
    .include "armpit_startup_CM3.s"	@ int vects+resets for cortex-m3/-m4
.endif


.end


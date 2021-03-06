/*------------------------------------------------------------------------------
@
@  ARMPIT SCHEME Version 060
@
@  ARMPIT SCHEME is distributed under The MIT License.

@  Copyright (c) 2012-2013 Petr Cermak

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

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

pcfpwr:	@ (config-power rcof bit val)
	@ on entry:	sv1 <- rcof (offset in rcc)	(scheme int)
	@ on entry:	sv2 <- bit position		(scheme int)
	@ on entry:	sv3 <- val (1 or 0)		(scheme int)
	@ on exit:	sv1 <- npo
	set	sv4, sv3
	set	sv3, sv2
	ldr	rva, =rcc_base
	int2raw	rvb, sv1
	b	rcpbit


pcfgpn:	@ (config-pin port pin cnf mode)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin  (0 to 15)		(scheme int)
	@ on entry:	sv3 <- mode (i/o..)   		(scheme int)
	@ on entry:	sv4 <- speed		    	(scheme int)
	@ on exit:	sv1 <- npo
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	ldr	rva, [rvc]          @   rva - mem reg value
	int2raw	rvc, sv2
	and	rvc, rvc, #0x0F
	lsl	rvc, rvc, #1        @   pin num * ( 2 bit for cnf )
	set	rvb, #0x03          @   mask 2 bits for bic
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb       @   mask rva
	int2raw	rvb, sv3
	and	rvb, rvb, #0x03     @   only 2 bits cnf
	lsl	rvb, rvb, rvc       @   shift
	orr	rva, rva, rvb       @   orr cnf to rva
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	str	rva, [rvc]          @   store rva back MODER
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	ldr	rva, [rvc, #0x08]   @   rva - mem reg value
	int2raw	rvc, sv2
	and	rvc, rvc, #0x0F
	lsl	rvc, rvc, #1        @   pin num * ( 2 bit for mode )
	set	rvb, #0x03          @   mask 2 bits for bic
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb       @   mask rva
	int2raw	rvb, sv4
	and	rvb, rvb, #0x03     @   only 2 bits mode
	lsl	rvb, rvb, rvc       @   shift
	orr	rva, rva, rvb       @   orr mode to rva
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	str	rva, [rvc, #0x08]   @   store rva back OSPEEDER
	b	npofxt


pcfppp: @ (config-pin-pp port pin cnf mode)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin  (0 to 15)		(scheme int)
	@ on entry:	sv3 <- out type		    	(scheme int)
	@ on entry:	sv4 <- pull up/pull down   	(scheme int)
	@ on exit:	sv1 <- npo
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	ldr	rva, [rvc, #0x04]   @   rva - mem reg value
	int2raw	rvc, sv2
	and	rvc, rvc, #0x0F
	set	rvb, #0x01          @   mask 1 bits for bic
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb       @   mask rva
	int2raw	rvb, sv3
	and	rvb, rvb, #0x01     @   only 1 bits mode
	lsl	rvb, rvb, rvc       @   shift
	orr	rva, rva, rvb       @   orr mode to rva
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	str	rva, [rvc, #0x04]   @   store rva back OTYPER
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	ldr	rva, [rvc, #0x0C]   @   rva - mem reg value
	int2raw	rvc, sv2
	and	rvc, rvc, #0x0F
	lsl	rvc, rvc, #1        @   pin num * ( 2 bit for PUPDR )
	set	rvb, #0x03          @   mask 2 bits for bic
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb       @   mask rva
	int2raw	rvb, sv4
	and	rvb, rvb, #0x03     @   only 2 bits cnf
	lsl	rvb, rvb, rvc       @   shift
	orr	rva, rva, rvb       @   orr mode to rva
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	str	rva, [rvc, #0x0C]   @   store rva back PUPDR
	b	npofxt


pcfafm: @ (config-afm port pin cnf mode)
	@ on entry:	sv1 <- port (eg. giob)		(scheme int)
	@ on entry:	sv2 <- pin  (0 to 15)		(scheme int)
	@ on entry:	sv3 <- afm	(AFM = 0..15)   (scheme int)
	@ on exit:	sv1 <- npo
	int2raw	rvc, sv1
	lsl	rvc, rvc, #4
	cmp	sv2, #16
	it	pl
	addpl	rvc, rvc, #4    @   if pin great and equal 16
	orr	sv5, rvc, #i0
	ldr	rva, [rvc]
	int2raw	rvc, sv2
	and	rvc, rvc, #0x0f
	lsl	rvc, rvc, #2
	@  mask AFM
	set	rvb, #0x0f
	lsl	rvb, rvb, rvc
	bic	rva, rva, rvb
	int2raw	rvb, sv3
	and	rvb, rvb, #0x0f
	lsl	rvb, rvb, rvc
	orr	rva, rva, rvb
	bic	rvc, sv5, #i0
	str	rva, [rvc, 0x20]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
@	str	rvc, [rva, #io_set]
@ It's best to keep io_set as ODR (in STM32F4.h) and use BSRR low 16 here (because of common
@ code in core for setting/clearing LEDs on error, that uses io_set=ODR)
@ An alternative would be to add a flag such as gpio_has_16bit_set_clear and modify the LED
@ code in armpit_051.s accordingly (and unset has_combined_set_clear + redefine io_set and io_clear).
	strh	rvc, [rva, #0x18]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
@	lsl	rvc, rvc, 16
@	str	rvc, [rva, #io_clear]
@ It's best to keep io_clear as ODR (in STM32F4.h) and use BSRR high 16 here (because of common
@ code in core for setting/clearing LEDs on error, that uses io_clear=ODR).
@ An alternative would be to add a flag such as gpio_has_16bit_set_clear and modify the LED
@ code in armpit_051.s accordingly (and unset has_combined_set_clear + redefine io_set and io_clear).
	strh	rvc, [rva, #0x1a]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva, #io_state]
	tst	rvb, rvc
	b	notfxt


ptstop:	@ (tic-stop)
	@ stop the systick timer
	@ on exit:	sv1 <- npo
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	set	rvb, #0
	str	rvb, [rva, #tick_ctrl]
	swi	run_normal		@ set Thread mode, unprivileged, with IRQ (user)
	b	npofxt


ptstrt:	@ (tic-start bool)
	@ start the systick timer (without interrupt generation if bool = #f)
	@ on entry:	sv1 <- #f (no interrupts) or anything else, including null (interrupts)
	@ on exit:	sv1 <- npo
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	set	rvb, #0
	str	rvb, [rva, #tick_ctrl]
	str	rvb, [rva, #tick_val]
	eq	sv1, #f
	itE	eq
	seteq	rvb, #0x05
	setne	rvb, #0x07
	str	rvb, [rva, #tick_ctrl]
	swi	run_normal		@ set Thread mode, unprivileged, with IRQ (user)
	b	npofxt


ptkred:	@ (tic-read)
	@ read current value of the systick timer
	@ on exit:	sv1 <- value from systick timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	rva, =systick_base
	ldr	rvb, [rva, #tick_val]
	raw2int	sv1, rvb
	swi	run_normal		@ set Thread mode, unprivileged, with IRQ (user)
	set	pc,  cnt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
psppt0:	ldr	rvc, [rva, #spi_status]
	tst	rvc, #spi_txrdy
	beq	psppt0
	str	rvb, [rva, #spi_thr]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
pspget:	@ (spi-get port)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on exit:	sv1 <- data from spi		(scheme int)
pspgt0:	ldr	rvb, [rva, #spi_status]
	tst	rvb, #spi_rxrdy
	beq	pspgt0
	ldr	rvb, [rva, #spi_rhr]
	raw2int	sv1, rvb
	set	pc,  cnt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg








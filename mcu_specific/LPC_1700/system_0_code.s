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
@  utility functions
@-------------------------------------------------------------------------------

pcfpwr:	@ (config-power bit val)
	@ sets or clears bit in PCONP
	@ on entry:	sv1 <- bit position	(scheme int)
	@ on entry:	sv2 <- val (1 or 0)	(scheme int)
	@ on exit:	sv1 <- npo
	set	sv3, sv1
	set	sv4, sv2
	ldr	rva, =sys_ctrl
	set	rvb, #0xc4
	b	rcpbit

pcfgpn:	@ (config-pin main sub cfg . <mod> <od>)
	@ configure a pin, from P0.0 to P2.13
	@ cfg:		#b00 to #b11
	@ <mod>:	#b00 = pull-up, #b01 = repeater, #b10 = no pull-up/dn, #b11 = pull-down
	@ <od>:		0 or 1, open drain
	@ on entry:	sv1 <- main (0 to 2)				(scheme int)
	@ on entry:	sv2 <- sub  (0 to 31)				(scheme int)
	@ on entry:	sv3 <- cfg (eg. #b01)				(scheme int)
	@ on entry:	sv4 <- (<mod> <od>) = rest of input args	(list)
	@ on exit:	sv1 <- npo
	int2raw	rvc, sv1		@ rvc <- main part of pin (raw int)
	lsl	rvc, rvc, #3		@ rvc <- pinsel/mod offset from pinsel0/mod0
	cmp	sv2, #65		@ is pin (sub) > 15?
	it	pl
	addpl	rvc, rvc, #4		@	if so, rvc <- offset adjusted for pins 16-31
	raw2int	sv5, rvc		@ sv5 <- pinsel/mod offset, saved (scheme int)
	@ update pin configuration
	ldr	rvb, =PINSEL0		@ rvb <- pinsel base
	set	sv1, sv3		@ sv1 <- cfg
	bl	pcfgph			@ rva <- updated pin configuration word, rvc <- offset
	ldr	rvb, =PINSEL0		@ rvb <- pinsel base
	str	rva, [rvb, rvc]		@ update pin configuration in pinsel
	@ update pin mode
	nullp	sv4			@ mod specified?
	beq	npofxt			@	if not, return
	ldr	rvb, =PINMODE0		@ rvb <- pinmod base
	snoc	sv1, sv4, sv4		@ sv1 <- mod, sv4 <- (<od>)
	bl	pcfgph			@ rva <- updated pin mode word, rvc <- offset
	ldr	rvb, =PINMODE0
	str	rva, [rvb, rvc]
	@ update pin open-drain functionality
	nullp	sv4			@ open-drain specified?
	beq	npofxt			@	if not, return
	set	sv3, sv2		@ sv3 <- sub, 0 to 31 = bit pos	(scheme int)
	car	sv4, sv4		@ sv4 <- od, 0 or 1		(scheme int)
	ldr	rva, =PINMODE_OD0	@ rva <- pinmod open-drain base address
	lsr	rvb, rvc, #1		@ rvb <- OD register offset, unaligned
	bic	rvb, rvb, #0x03		@ rvb <- OD register offset, aligned
	b	rcpbit			@ jump to register-copy-bit

_func_
pcfgph:	@ update configuration/mode bits helper function
	@ on entry:	rvb <- pinsel/pinmod base address
	@ on entry:	rvc <- offset of pin conf/mod, from base	(raw int)
	@ on entry:	sv1 <- new configuration/mode			(scheme int)
	@ on entry:	sv2 <- sub (input arg of config-pin function)	(scheme int)
	@ on entry:	sv5 <- offset of pin conf/mod, from base	(scheme int)
	@ on exit:	rva <- updated configuration/mode word		(raw int)
	@ modifies:	rva, rvb
	ldr	rva, [rvb, rvc]		@ rva <- current pin configurations/mode
	int2raw	rvc, sv2		@ rvc <- bit mask position/2
	and	rvc, rvc, #0x0f		@ rvc <- bit mask position modulo 16
	lsl	rvc, rvc, #1		@ rvc <- mask position
	set	rvb, #0x03		@ rvb <- base mask
	lsl	rvb, rvb, rvc		@ rvb <- mask, shifted in place
	bic	rva, rva, rvb		@ rva <- pin configurations/modes with mask cleared
	int2raw	rvb, sv1		@ rvb <- new configuration/mode
	lsl	rvb, rvb, rvc		@ rvb <- new configuration/mode, shifted in place
	orr	rva, rva, rvb		@ rva <- full new configuration/mode
	int2raw	rvc, sv5		@ rvc <- pinsel/mod offset
	set	pc,  lnk

	EPFUNC	null, oregent, 3	@ primitive, init-sv4 = none, fentry = regent, narg = 3
ppstdr:	@ (pin-set-dir port pin dir)
	@ on entry:	sv1 <- port (gio0 to gio4)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on entry:	sv3 <- dir  (0=input, 1=output)	(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0-4 as full address (from sv1, through regent)
	set	rvb, #io_dir		@ rvb <- 0x08 = offset to pin dir reg in gio0-4
	set	sv4, sv3
	set	sv3, sv2
	b	rcpbit

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio0 to gio4)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0-4 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_set]
	b	npofxt

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio0 to gio4)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0-4 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_clear]
	b	npofxt

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gio0 to gio4)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	@ rva <- gio0-4 as full address (from sv1, through regent)
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

	EPFUNC	null, oregent, 2		@ primitive, init-sv4 = none, fentry = regent, narg = 2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
	str	rvb, [rva, #spi_thr]
	b	npofxt

	EPFUNC	null, oregent, 1		@ primitive, init-sv4 = none, fentry = regent, narg = 1
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








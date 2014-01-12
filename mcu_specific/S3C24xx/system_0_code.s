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
@-------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

pcfpwr:	@ (config-power bit val)
	@ sets/clears bit in CLKCON (peripherals enabled by default at startup)
	@ on entry:	sv1 <- bit position	(scheme int)
	@ on entry:	sv2 <- val (1 or 0)	(scheme int)
	@ on exit:	sv1 <- npo
	set	sv3, sv1
	set	sv4, sv2
	ldr	rva, =sys_ctrl
	set	rvb, #0x0c
	b	rcpbit
	
	
	EPFUNC	null, oregent, 3	@ primitive,in-sv4=no,fent=regent,narg=3
pcfgpn:	@ (config-pin port pin cfg . <pup>)
	@ port:		giob-gioh, port
	@ pin:		0-15, pin on port
	@ cfg:		0-3,  #b00=input, #b01=output, #b10=AF 1, #b11=AF 2
	@ pup:		0/1,  1 = enable pull-up (default)
	@ on entry:	sv1 <- port (giob to gioh)		(scheme int)
	@ on entry:	sv2 <- pin  (0 to 15)			(scheme int)
	@ on entry:	sv3 <- cfg  (0 to  3)			(scheme int)
	@ on entry:	sv4 <- (<pup>)				(list)
	@ on exit:	sv1 <- npo
	@ rva <- giob-h as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	@ configure pin mode
	set	sv5, rva
	ldr	rvc, [sv5, #0x00]
	and	rvb, rvb, #0x0f
	lsl	rvb, rvb, #1
	set	rva, #0x03
	lsl	rva, rva, rvb
	bic	rvc, rvc, rva
	int2raw	rva, sv3
	and	rva, rva, #0x03
	lsl	rva, rva, rvb
	orr	rvc, rvc, rva
	str	rvc, [sv5, #0x00]
	@ configure pull-up
	pntrp	sv4
	bne	npofxt
	car	sv4, sv4
	int2raw	rvb, sv2
	and	rvb, rvb, #0x0f
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rva, [sv5, #0x08]
	eq	sv4, #i0		@ disable pull-up?
	orreq	rva, rva, rvc		@	if so,  set   disable pullup bit
	bicne	rva, rva, rvc		@	if not, clear disable pullup bit
	str	rva, [sv5, #0x08]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive,in-sv4=no,fent=regent,narg=2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	swi	run_no_irq
	ldr	rvb, [rva, #io_state]	@ rvb <- pin statuses
	orr	rvb, rvb, rvc
	str	rvb, [rva, #io_state]	@ set pin
	swi	run_normal
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive,in-sv4=no,fent=regent,narg=2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio0 or gio1)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio0/1 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	swi	run_no_irq
	ldr	rvb, [rva, #io_state]	@ rvb <- pin statuses
	bic	rvb, rvb, rvc
	str	rvb, [rva, #io_state]	@ clear pin
	swi	run_normal
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive,in-sv4=no,fent=regent,narg=2
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


	EPFUNC	null, oregent, 2	@ primitive,in-sv4=no,fent=regent,narg=2
ptstop:	@ (stop tmr chan)
	@ stops channel (0-4) of tmr0
	@ on entry:	sv1 <- tmr (tmr0 only)	(scheme int)
	@ on entry:	sv2 <- chan = 0 to 4, or null
	@ on exit:	sv1 <- npo
	nullp	sv2			@ was channel specified?
	seteq	rvb, #0			@	if not, assume channel 0
	eq	rvb, #0			@ is channel = 0?
	lslne	rvb, rvb, #2		@	if not, rvb <- 4*channel
	addne	rvb, rvb, #4		@	if not, rvb <- 4*channel+4=offst
	set	rvc, #0x1f		@ rvc <- channel clearing code
	lsl	rvc, rvc, rvb		@ rvc <- clearing code shiftd to channel
	ldr	rvb, [rva, #0x08]	@ rvb <- current timer control
	bic	rvb, rvb, rvc		@ rvb <- timer control with channel clrd
	str	rvb, [rva, #0x08]	@ set updated control in timer
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive,in-sv4=no,fent=regent,narg=1
ptstrt:	@ (restart tmr)
	@ restarts tmr0 in one-shot mode
	@ on entry:	sv1 <- tmr (tmr0 only)	(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rvb, [rva, #0x08]
	bic	rvb, rvb, #0x0f
	str	rvb, [rva, #0x08]
	orr	rvb, rvb, #0x02
	str	rvb, [rva, #0x08]
	eor	rvb, rvb, #0x03
	str	rvb, [rva, #0x08]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive,in-sv4=no,fent=regent,narg=2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
psppt0:	ldr	rvc, [rva, #spi_status]	@ ssta
	tst	rvc, #spi_txrdy
	beq	psppt0
	str	rvb, [rva, #spi_thr]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive,in-sv4=no,fent=regent,narg=1
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






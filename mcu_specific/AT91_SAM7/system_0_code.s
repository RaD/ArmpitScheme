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

/*------------------------------------------------------------------------------
@
@ Contributions:
@
@     This file includes contributions by Robbie Dinn, marked <RDC>
@
@-----------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
@  utility functions
@-----------------------------------------------------------------------------*/

pcfpwr:	@ (config-power bit val)
	@ on entry:	sv1 <- bit position	(scheme int)
	@ on entry:	sv2 <- val (1 or 0)	(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rva, =PMC_base
	int2raw	rvb, sv1
	set	rvc, #1
	lsl	rvc, rvc, rvb
	eq	sv2, #i1		@ enable power?
	streq	rvc, [rva, #0x10]	@	if so,  PMC_PCER <- enable  peripheral clock
	strne	rvc, [rva, #0x14]	@	if not, PMC_PCDR <- disable peripheral clock
	b	npofxt			@ return


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
pcfgpn:	@ (config-pin port pin dig ddir pup afab adir)						<RDC>
	@ port:		port   (gioa or giob)							<RDC>
	@ pin:		0-31,  for PA0 to PA31
	@ dig:		0/1,   1 -> digital function (0 for alternate)
	@ ddir:		0/1,   1 -> output direction (digital)
	@ pup:		0/1,   1 -> pull-up resistor
	@ afab:		0/1/2, 1 -> periph A function, 2 -> periph B function
	@ adir:		0/1,   1 -> output write enable (alternate function) 
	@ on entry:	sv1 <- port (gioa or giob)	(scheme int)				<RDC>
	@ on entry:	sv2 <- pin (0 to 31)		(scheme int)
	@ on entry:	sv3 <- (pin dig pup afab dir)	(list)
	@ on exit:	sv1 <- npo
	@ rva <- gioa/b as full address (from sv1, through regent)				<RDC>
	@ rvb <- pin    as raw int	(from sv2, through regent)				<RDC>
	set	rvc, #1			@ rvc <- 1
	lsl	rvb, rvc, rvb		@ rvb <- bit in pin position
	@ digital function configuration
	nullp	sv3			@ no more configuration?				<RDC>
	beq	npofxt			@	if so,  exit
	snoc	sv1, sv2, sv3		@ sv1 <- dig,  sv2 <- (ddir pup afab adir)		<RDC>
	eq	sv1, #i1		@ digital?
	streq	rvb, [rva, #0x00]	@	if so,  PIO_PER <- enable  digital function
	strne	rvb, [rva, #0x04]	@	if not, PIO_PDR <- disable digital function
	@ digital direction configuration
	nullp	sv2			@ no more configuration?
	beq	npofxt			@	if so,  exit
	snoc	sv1, sv2, sv2		@ sv1 <- ddir,  sv2 <- (pup afab adir)
	eq	sv1, #i1		@ output?
	streq	rvb, [rva, #0x10]	@	if so,  PIO_OER <- enable  output direction
	strne	rvb, [rva, #0x14]	@	if not, PIO_ODR <- disable output direction
	@ pull-up resistor configuration
	nullp	sv2			@ no more configuration?
	beq	npofxt			@	if so,  exit
	snoc	sv1, sv2, sv2		@ sv1 <- pup,  sv2 <- (afab adir)
	eq	sv1, #i1		@ pull-up?
	streq	rvb, [rva, #0x60]	@	if so,  PIO_PUER <- enable  pull-up
	strne	rvb, [rva, #0x64]	@	if not, PIO_PUDR <- disable pull-up
	@ alternate function configuration
	nullp	sv2			@ no more configuration?
	beq	npofxt			@	if so,  exit
	snoc	sv1, sv2, sv2		@ sv1 <- afab,  sv2 <- (adir)
	eq	sv1, #i1		@ peripheral A function?
	streq	rvb, [rva, #0x70]	@	if so,  PIO_ASR <- enable peripheral A function
	eq	sv1, #9			@ peripheral B function?
	streq	rvb, [rva, #0x74]	@	if so,  PIO_BSR <- enable peripheral B function
	@ output write configuration
	nullp	sv2			@ no more configuration?
	beq	npofxt			@	if so,  exit
	snoc	sv1, sv2, sv2		@ sv1 <- adir,  sv2 <- ()
	eq	sv1, #i1		@ output write?
	streq	rvb, [rva, #0xa0]	@	if so,  PIO_OWER <- enable  output write
	strne	rvb, [rva, #0xa4]	@	if not, PIO_OWDR <- disable output write
	b	npofxt

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gioa or giob)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gioa/b as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_set]
	b	npofxt

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gioa or giob)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gioa/b as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_clear]
	b	npofxt

	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gioa or giob)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	@ rva <- gioa/b as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva, #io_state]
	tst	rvb, rvc
	b	notfxt

	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstop:	@ (stop tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	set	rvb, #2
	str	rvb, [rva, #0x00]
	b	npofxt

	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstrt:	@ (restart tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	set	rvb, #5
	str	rvb, [rva, #0x00]
	b	npofxt

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
	and	rvb, rvb, #0xff
	raw2int	sv1, rvb
	set	pc,  cnt


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg





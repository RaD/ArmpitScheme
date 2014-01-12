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
@  utility functions
@-----------------------------------------------------------------------------*/

psdgb:	@ (sdgb block-number)
	@ allocate buffer
	set	rvb, #0x82
	lsl	rvb, rvb, #2
	bl	zmaloc
	set	rvc, #0x80
	lsl	rvc, rvc, #10
	orr	rvc, rvc, #0x6f		@ rvc <- bytevector tag
	str	rvc, [rva]
	add	rva, rva, rvb		@ rva <- address of next free cell (level 2 reserved)
	sub	sv3, rva, rvb		@ sv3 <- allocated block [*commit destination*]
	orr	fre, rva, #0x02		@ de-reserve free-pointer, [*restart critical instruction*]
	@	get block of data
	set	rvc, sv1		@ rvc <- block number for _sgb (scheme int)
	bl	_sgb			@ sv3 <- block data
	set	sv1, sv3		@ sv1 <- block data
	set	pc,  cnt		@ return


psdpb:	@ (sdpb block buffer)
	set	rvc, sv1
	set	sv3, sv2
	bl	_spb
	b	npofxt
	
	
pvmsr:	@ (vmsr rounding-mode)
	@ sets rounding mode in fpscr register
	@ #b11 = to 0, #b10 = to -Inf, #b01 = to +Inf, #b00 = nearest
	@ on entry:	sv1 <- rounding-mode (0 to 3)		(scheme int)
	@ on exit:	sv1 <- npo
	int2raw	rva, sv1
	and	rva, rva, #3
	lsl	rva, rva, #22
	vmrs	rvb, fpscr
	bic	rvb, rvb, #0x00c00000	@ clear rounding mode
	orr	rvb, rvb, rva		@ set new rounding mode
	vmsr	fpscr, rvb
	b	npofxt


pvmrs:	@ (vmrs)
	@ return value of fpscr register
	@ on exit:	sv1 <- contents of fpscr 29:0		(scheme int)
	vmrs	rva, fpscr
	raw2int	sv1, rva
	set	pc,  cnt


pcfgpn:	@ (config-pin main sub cfg)
	@ configure a pin, from P0_0 to PF_11
	@ cfg:		#b gifudmmm, bits: 	
	@		g=filter,i=inbuffer,f=fast,u=~pullup,d=pulldown,mmm=mode
	@ on entry:	sv1 <- main (0 to 15 for P0 to PF)	(scheme int)
	@ on entry:	sv2 <- sub  (0 to 15 for Pn_0 to Pn_15)	(scheme int)
	@ on entry:	sv3 <- cfg (eg. #x00)			(scheme int)
	@ on exit:	sv1 <- npo
	int2raw	rvc, sv1		@ rvc <- main part of pin (raw int)
	set	rvb, #0x80
	mul	rvb, rvb, rvc
	ldr	rva, =SCU_SFSP0_n	@ rva <- SCU Pin cfg reg for P0_0
	add	rva, rva, rvb		@ rva <- SCU Pin cfg reg for Pmain_0
	bic	rvb, sv2, #3
	add	rva, rva, rvb		@ rva <- SCU Pin cfg reg for Pmain_sub
	int2raw	rvb, sv3
	str	rvb, [rva]
	b	npofxt
	
	
ppstdr:	@ (pin-set-dir port pin dir)
	@ on entry:	sv1 <- port (gio0 to gio7)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on entry:	sv3 <- dir  (0=input, 1=output)	(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rva, =io0_base
	add	rva, rva, sv1
	bic	rva, rva, #3
	set	rvb, #io_dir		@ rvb <- offset to pin dir reg in gio0-4
	set	sv4, sv3
	set	sv3, sv2
	b	rcpbit
	

ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio0 to gio7)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rva, =io0_base
	add	rva, rva, sv1
	bic	rva, rva, #3
	int2raw	rvb, sv2
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_set]
	b	npofxt
		
	
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio0 to gio7)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rva, =io0_base
	add	rva, rva, sv1
	bic	rva, rva, #3
	int2raw	rvb, sv2
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_clear]
	b	npofxt
	

ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gio0 to gio7)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	ldr	rva, =io0_base
	add	rva, rva, sv1
	bic	rva, rva, #3
	int2raw	rvb, sv2
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva, #io_dir]	@ rvb <- pin directions
	tst	rvb, rvc		@ is this an input pin w/input buffer?
	itE	eq
	ldreq	rvb, [rva, #io_state]	@	if so,  rvb <- input  pin status
	ldrne	rvb, [rva, #io_set]	@	if not, rvb <- output pin status
	tst	rvb, rvc
	b	notfxt
	
	
ptstop:	@ (tic-stop)
	@ stop the systick timer
	@ on exit:	sv1 <- npo
	swi	run_prvlgd		@ Thread mode, privileged, no IRQ
	ldr	rva, =systick_base
	set	rvb, #0
	str	rvb, [rva, #tick_ctrl]
	swi	run_normal		@ Thread mode, unprivileged, with IRQ
	b	npofxt


ptstrt:	@ (tic-start bool)
	@ start the systick timer (without interrupt generation if bool = #f)
	@ on entry:	sv1 <- #f (no ints) or anything else, eg. null (ints)
	@ on exit:	sv1 <- npo
	swi	run_prvlgd		@ Thread mode, privileged, no IRQ
	ldr	rva, =systick_base
	set	rvb, #0
	str	rvb, [rva, #tick_ctrl]
	str	rvb, [rva, #tick_val]
	eq	sv1, #f
	itE	eq
	seteq	rvb, #0x05
	setne	rvb, #0x07
	str	rvb, [rva, #tick_ctrl]
	swi	run_normal		@ Thread mode, unprivileged, with IRQ
	b	npofxt


ptkred:	@ (tic-read)
	@ read current value of the systick timer
	@ on exit:	sv1 <- value from systick timer
	swi	run_prvlgd		@ Thread mode, privileged, no IRQ
	ldr	rva, =systick_base
	ldr	rvb, [rva, #tick_val]
	raw2int	sv1, rvb
	swi	run_normal		@ Thread mode, unprivileged, with IRQ
	set	pc,  cnt


	EPFUNC	0, oregent, 2		@ primitive,insv4=none,fen=regent,narg=2
pspput:	@ (spi-put port val)
	@ on entry:	sv1 <- port (spi0 or spi1)	(scheme int)
	@ on entry:	sv2 <- val
	@ on exit:	sv1 <- npo
	str	rvb, [rva, #spi_thr]
	b	npofxt


	EPFUNC	0, oregent, 1		@ primitive,insv4=none,fen=regent,narg=1
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





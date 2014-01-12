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

	EPFUNC	null, oregent, 3	@ primitive, init-sv4 = none, fentry = regent, narg = 3
pcfpwr:	@ (config-power cm bit val)
	@ set/clear bit in core_cm, wkup_cm or per_cm
	@ two bits are set/cleared: fclken1 and iclken1 (functional and interface clocks)
	@ on entry:	sv1 <- cm = core_cm, wkup_cm or per_cm	(scheme int)
	@ on entry:	sv2 <- bit position			(scheme int)
	@ on entry:	sv3 <- val (1 or 0)			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- cm     as full address (from sv1, through regent)
	@ rvb <- bit    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	eq	sv3, #i1
	@ functional clock
	ldr	rvb, [rva, #F_clck]
	orreq	rvb, rvb, rvc
	bicne	rvb, rvb, rvc
	str	rvb, [rva, #F_clck]
	@ interface clock
	ldr	rvb, [rva, #I_clck]
	orreq	rvb, rvb, rvc
	bicne	rvb, rvb, rvc
	str	rvb, [rva, #I_clck]
	@ return
	b	npofxt


pcfgpd:	@ (config-pad ofst cfg)
	@ sets low/hi 16-bit pad configuration in SCM at specified offset
	@ ofst:		#x30 for CONTROL_PADCONF_SDRC_D0
	@ ofst:		#x32 for CONTROL_PADCONF_SDRC_D1
	@		etc ... (i.e. offset is 16-bit to choose hi/lo pad)
	@ on entry:	sv1 <- ofst (#x30 to #x5f8)		(scheme int)
	@ on entry:	sv2 <- cfg  (eg. #x0100)		(scheme int)
	@ on exit:	sv1 <- npo
	ldr	rva, =SCM_base
	int2raw	rvc, sv1
	bic	rvb, rvc, #0x03
	add	rva, rva, rvb
	tst	rvc, #0x03		@ setting low pad?
	ldr	rvb, [rva]		@ rvb <- current pad configuration
	@ clear hi or lo part of pad conf
	lsreq	rvb, rvb, #16		@	if lo pad, rvb <- conf shifted
	lsl	rvb, rvb, #16		@ rvb <- conf shifted/unshifted (cleared)
	lsrne	rvb, rvb, #16		@	if hi pad, rvb <- conf unshifted (cleared)
	@ set new conf into pad
	int2raw	rvc, sv2		@ rvc <- new configuration
	lslne	rvc, rvc, #16		@	if hi pad, rvc <- new conf shifted
	orr	rvb, rvb, rvc		@ rvb <- updated pad configuration
	str	rvb, [rva]		@ store updated pad configuration
	@ done
	b	npofxt


	EPFUNC	null, oregent, 3	@ primitive, init-sv4 = none, fentry = regent, narg = 3
ppstdr:	@ (pin-set-dir port pin dir)
	@ OMAP uses 0 for output, 1 for input, but we change that
	@ to 1 for output and 0 for input so it is the same as other
	@ MCUs
	@ on entry:	sv1 <- port (gio1 to gio6)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on entry:	sv3 <- dir  (0=input, 1=output)	(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio1-6 as full address (from sv1, through regent)
	set	rvb, #io_dir		@ rvb <- 0x08 = offset to pin dir reg in gio0/1
	eq	sv3, #i1		@ setting to ouput?
	seteq	sv4, #i0		@	if so,  sv4 <- 0 for OMAP
	setne	sv4, #i1		@	if not, sv4 <- 1 for OMAP
	set	sv3, sv2
	b	rcpbit


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnset:	@ (pin-set port pin)
	@ on entry:	sv1 <- port (gio1 to gio6)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio1-6 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_set]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnclr:	@ (pin-clear port pin)
	@ on entry:	sv1 <- port (gio1 to gio6)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- npo
	@ rva <- gio1-6 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	str	rvc, [rva, #io_clear]
	b	npofxt


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
ppnstq:	@ (pin-set? port pin)
	@ on entry:	sv1 <- port (gio1 to gio6)	(scheme int)
	@ on entry:	sv2 <- pin			(scheme int)
	@ on exit:	sv1 <- #t/#f pin status (#t = high)
	@ rva <- gio1-6 as full address (from sv1, through regent)
	@ rvb <- pin    as raw int	(from sv2, through regent)
	set	rvc, #1
	lsl	rvc, rvc, rvb
	ldr	rvb, [rva, #io_dir]	  @ rvb <- pin directions (0=out, 1=in)
	tst	rvb, rvc
	ldreq	rvb, [rva, #io_out_state] @ rvb <- output state
	ldrne	rvb, [rva, #io_state]	  @ rvb <- input state
	tst	rvb, rvc
	b	notfxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstop:	@ (stop tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	set	rvb, #0
	str	rvb, [rva, #0x24]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
ptstrt:	@ (restart tmr)
	@ on entry:	sv1 <- tmr (tmr0 or tmr1)	(scheme int)
	@ on exit:	sv1 <- npo
	set	rvb, #0
	str	rvb, [rva, #0x28]
	set	rvb, #0x41
	str	rvb, [rva, #0x24]
	b	npofxt


	EPFUNC	null, oregent, 1	@ primitive, init-sv4 = none, fentry = regent, narg = 1
pi2crs:	@ (i2c-reset i2c-base)
	@ on entry:	sv1 <- i2c-base (i2c0 or i2c1)		(scheme int)
	@ on exit:	sv1 <- npo
	bl	hw_i2c_reset		@ perform i2c-reset (input data: rva)
	b	npofxt			@ return with npo


pi2crx:	@ (i2c-read i2c-base target-address <register> <count>)
	@ on entry:	sv1 <- i2c-base (i2c0 or i2c1)		(scheme int)
	@ on entry:	sv2 <- target-address
	@ on entry:	sv3 <- (<register> <count>)
	@ on exit:	sv1 <- byte or double-byte read		(scheme int)
	@ note 1:	count is 1 or 2 and defaults to 1.
	@ note 2:	set reg to '() if there is no reg and count needs to be 2.
	int2raw	rva, sv1		@ rva <- i2c-base address (raw int)
	lsl	rva, rva, #4		@ rva <- full i2c-base address

	int2raw	rvc, sv2
	and	rvc, rvc, #0xff
	int2raw	rvb, sv3
	orr	rvc, rvc, rvb, lsl #8
	pntrp	sv4
	careq	sv3, sv4
	setne	sv3, #i1
	bl	hw_i2c_read		@ rvc <- data from i2c-read (input data: rva, rvc, sv3)
	raw2int	sv1, rvc		@ sv1 <- i2c data (scheme int)
	set	pc,  cnt		@ return


pi2ctx:	@ (i2c-write i2c-base target-address <byte1> <byte2> <byte3>)
	@ on entry:	sv1 <- i2c-base (i2c0 or i2c1)		(scheme int)
	@ on entry:	sv2 <- (target-address <byte1> <byte2> <byte3>)
	@ on exit:	sv1 <- npo
	@ get target address into rvc
	snoc	sv4, sv5, sv2		@ sv4 <- target-address, sv5 <- (<byte1> <byte2> <byte3>)
	int2raw	rvc, sv4		@ rvc <- target-address (raw int)
	and	rvc, rvc, #0xff		@ rvc <- target-address, trimmed
	@ pack bytes to write into rvc, and update count in sv3
	set	sv3, #i0		@ sv3 <- initial number of bytes to write (scheme int)
	set	rvb, #8			@ rvb <- shift in rvc-pack for next data byte
pi2ct0:	@ loop
	nullp	sv5			@ done with data bytes?
	beq	pi2ct1			@	if so,  jump to finish up
	snoc	sv4, sv5, sv5		@ sv4 <- 1st byte, sv5 <- list of remaining bytes
	int2raw	rva, sv4		@ rva <- 1st byte (raw int)
	and	rva, rva, #0xff		@ rva <- 1st byte, trimmed
	lsl	rva, rva, rvb		@ rva <- 1st byte, shifted in place
	orr	rvc, rvc, rva		@ rvc <- updated address/data pack
	add	sv3, sv3, #4		@ sv3 <- updated number of bytes to write (scheme int)
	add	rvb, rvb, #8		@ rvb <- updated shift for next byte
	cmp	rvb, #32		@ max number of bytes not exceeded?
	bmi	pi2ct0			@	if so,  jump to continue packing bytes
pi2ct1:	@ finish up
	int2raw	rva, sv1		@ rva <- i2c-base address (raw int)
	lsl	rva, rva, #4		@ rva <- full i2c-base address
	bl	hw_i2c_write		@ perform i2c-write (input data: rva, rvc, sv3)
	b	npofxt			@ return with npo


	EPFUNC	null, oregent, 2	@ primitive, init-sv4 = none, fentry = regent, narg = 2
p_rd16:	@ (rd16 reg ofst)
	@ on entry:	sv1 <- reg				(scheme int)
	@ on entry:	sv2 <- ofst				(scheme int)
	@ on exit:	sv1 <- 16-bit value from reg+ofst	(scheme int)
	ldrh	rvc, [rva, rvb]
	raw2int	sv1, rvc
	set	pc,  cnt


p_wr16:	@ (wr16 val reg ofst)
	@ on entry:	sv1 <- val (16-bit)			(scheme int)
	@ on entry:	sv2 <- reg				(scheme int)
	@ on entry:	sv3 <- ofst				(scheme int)
	@ on exit:	sv1 <- npo
	int2raw	rva, sv2
	lsl	rva, rva, #4
	int2raw	rvb, sv3
	int2raw	rvc, sv1
	strh	rvc, [rva, rvb]
	b	npofxt			@ return with npo


p_sgb:	@ (_sgb block-number)
	@ get a block of data (512 bytes) from sd-card (eg. after sd-init)
	@ on entry:	sv1 <- block-number			(scheme int)
	@ on exit:	sv1 <- sd block data			(bytevector)
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


p_spb:	@ (_spb data-block block-number)
	@ put a block of data (512 bytes) onto sd-card (eg. after sd-init)
	@ on entry:	sv1 <- data block			(bytevector)
	@ on entry:	sv2 <- block-number			(scheme int)
	@ on exit:	sv1 <- npo
	set	rvc, sv2		@ rvc <- block number for _spb (scheme int)
	set	sv3, sv1		@ sv3 <- block data for _spb
	bl	_spb			@ perform write
	b	npofxt			@ return with npo


@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
@ dump literal constants (up to 4K of code before and after this point)
@~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~-~~~~~~~
.ltorg





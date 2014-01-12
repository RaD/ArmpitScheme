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

		response to device interrupts 

------------------------------------------------------------------------------*/

usbhwDeviceStatus: @ return device status in rvb
	set	rvb, sv1		@ rvb  <- Device Interrupt Status
	set	pc,  lnk

usbhwReset: @ reset usb hardware
	ldr	rva, =usb_base
usbDS0:	ldr	rvb, =0x8000		@ rvb <- enable, Control endpoint
	str	rvb, [rva, #usb_csr0]
	ldr	rvb, [rva, #usb_csr0]
	eq	rvb, #0x8000
	bne	usbDS0
	ldr	rvb, =0x0F		@ enable USB interrupts (0-3)
	str	rvb, [rva, #usb_ier]
	ldr	rvb, =0xFFFF		@ clear USB interrupts
	str	rvb, [rva, #usb_iclear_dv]
	set	pc,  lnk

usbhwRemoteWakeUp:
	set	pc,  lnk

/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

usbhwEndpointStatus: @ get status of EP whose interrupt is in sv2 into sv3
	ldr	rva, =usb_base
	ldr	sv2, [rva, #usb_istat_ep] @ sv2 <- Endpoint Int Status (eisr)
	str	sv2, [rva, #usb_iclear_ep] @ clear the interrupt
	and	rvb, sv2, #0x0F
	cmp	rvb, #2
	it	pl
	addpl	rvb, rvb, #0x04
	and	rvb, rvb, #0x0C
	add	rva, rva, rvb
	ldr	sv3, [rva, #usb_csr0]
	set	pc,  lnk

/* BULK IN Enpoint Interrupt Response */

usbhwBIe: @ Bulk IN EP isr entry: clear the txcomp int
	ldr	rva, =usb_base
	ldr	env, [rva, #usb_ibulkin]
	bic	env, #0x01		@ txcomp
	str	env, [rva, #usb_ibulkin]
	set	pc,  lnk

_func_
usbhwBIw:
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt register (DEV_INT_CLR = disr)	
	b	wrtEPU				@ write data from dts to host, return to point of call

usbhwBIx: @ Bulk IN EP isr exit (special)
	b	usbixt


/* BULK OUT Enpoint Interrupt Response */

usbhwBOe: @ Bulk OUT EP isr entry: clear int
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clr USB int reg (DEV_INT_CLR=disr)
	set	pc,  lnk

_func_
usbhwBOw: @ initiate input data echo (if needed) through Bulk IN EP
	@ modifies:	rva, rvb
	@ returns via:	lnk
	ldr	rva, =usb_base		@ rva <- USB base address
	ldr	rvb, [rva, #usb_ibulkin] @ rvb <- content of UDP_CSR3 (BulkIN EP3 sta/ctl)
	tst	rvb, #0x01		@ is txcomp set?
	it	eq
	tsteq	rvb, #usb_txrdy		@	if not, is txpktrdy set?
	itT	eq
	orreq	rvb, rvb, #usb_txrdy	@	if not, rvb <- USB sta/ctl w/Txpktrdy bit
	streq	rvb, [rva, #usb_ibulkin] @	if not, set packet ready in USB stat/ctrl
	beq	usbhwBOw		@	if not, jump back to verify bit settings
	set	pc,  lnk		@ return (transfer via usbBIi)
	

/* CONTROL IN Enpoint Interrupt Response */

usbhwCIw: @ Control IN interrupt response
	@ write data to Control In Endpoint (write cnt bytes starting at dts to enpoint in env)
	ldr	rva, =usb_base
	eq	cnt, #0
	beq	usbCIZ
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt register (DEV_INT_CLR = disr)	
	b	wrtEPU	
usbCIZ: ldr	rvb, [rva, #usb_csr0]
usbCIY:	bic	rvb, #0xFF
	str	rvb, [rva, #usb_csr0]
	ldr	sv4, [rva, #usb_csr0]
	tst	sv4, #0xFF
	bne	usbCIY
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt register (DEV_INT_CLR = disr)	
	set	pc,  lnk

/* CONTROL OUT Enpoint Interrupt Response */

usbhwSetup: @ Control OUT Interrupt, Setup Phase
	@ (eg. section 9.13) uses rva, rvb, env, dts, cnt, returns cnt = count
	@ env <- EPNum, dts <- buffer
	ldr	rva, =usb_base
	set	env, #0
rdSTP1:	eq	env, #8
	itTT	ne
	ldrbne	rvb, [rva, #usb_fdr0]
	strbne	rvb, [dts, env]
	addne	env, env, #1
	bne	rdSTP1
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	ldr	rva, =usb_base
	tst	rvb, #0x80		@ is direction from device to host (bit 7 set in reqtyp)?
	beq	usbST5
usbST1:	ldr	rvb, [rva, #usb_csr0]
	orr	rvb, rvb, #0x80
	str	rvb, [rva, #usb_csr0]
	ldr	sv4, [rva, #usb_csr0]
	eq	sv4, rvb
	bne	usbST1
	b	usbST3
usbST5:	ldr	rvb, [rva, #usb_csr0]
	bic	rvb, rvb, #0x80
	str	rvb, [rva, #usb_csr0]
	ldr	sv4, [rva, #usb_csr0]
	eq	sv4, rvb
	bne	usbST5
usbST3:	ldr	rvb, [rva, #usb_csr0]
	bic	rvb, rvb, #0x04
	str	rvb, [rva, #usb_csr0]
	ldr	sv4, [rva, #usb_csr0]
	eq	sv4, rvb
	bne	usbST3
	set	pc,  lnk

usbhwDGD: @ send specified device descriptor
	eq	cnt, #0
	beq	usbSOx
	@ clear current interrupt
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt register (DEV_INT_CLR = disr)	
	bl	wrtEPU			@ write packet without waiting for or clearing txcomp
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, =0xFF
	str	rvb, [rva]
	b	usbixt

usbhwEGS: @ Get Status of Endpoint in sv5 into rvb
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base
	add	rva, rva, rvb, LSL #2
	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x8000		@ is the selected endpoint enabled (epeds)?
	itE	eq
	seteq	rvb, #0			@	if not, rvb <- 0, not enabled
	setne	rvb, #1			@	if so,  rvb <- 1, enabled
	set	pc,  lnk

usbhwSetAddress: @ Set Device to Address in sv5
	@ USB Status IN  exit -- write null packet to   EP 1 (phys, aka 0x80)
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	set	cnt, #0x00		@ cnt <- 0 bytes to send
	bl	wrtEP			@ write 0 bytes to EP
	ldr	rva, =USB_SETUP_BUFFER	@ rva <- address of setup buffer
	ldr	sv5, [rva]		@ sv5 <- reqtyp(8), request(8), val(16)
	lsr	sv5, sv5, #16		@ sv5 <- address = val(16)	
	orr	rvb, sv5, #0x100	@ rvb <- address ored with Device Enable (0x100)
	ldr	rva, =usb_base
	str	rvb, [rva, #usb_faddr]	@ set address	
	set	rvb, #1
	str	rvb, [rva, #usb_glbstate] @ set FADDEN bit
	b	usbEPx

usbhwConfigure: @ Configure the device
	@ stop uart from generating Rx interrupts (they cause noise on shared READBUFFER)
	ldr	rva, =uart0_base
	set	rvb, #1
	str	rvb, [rva, #0x0c]	@ US0_IDR <- Disable uart0 RxRDY interrupt
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ configure USB
	ldr	rva, =usb_base
hwcnf1:	ldr	rvb, =0x8700		@ rvb <- enable, interrupt IN endpoint
	str	rvb, [rva, #usb_csr1]
	ldr	sv4, [rva, #usb_csr1]
	eq	sv4, rvb
	bne	hwcnf1
hwcnf2:	ldr	rvb, =0x8200		@ rvb <- enable, bulk OUT endpoint
	str	rvb, [rva, #usb_csr2]
	ldr	sv4, [rva, #usb_csr2]
	eq	sv4, rvb
	bne	hwcnf2
hwcnf3:	ldr	rvb, =0x8600		@ rvb <- enable, bulk IN endpoint
	str	rvb, [rva, #usb_ibulkin]
	ldr	sv4, [rva, #usb_ibulkin]
	eq	sv4, rvb
	bne	hwcnf3
	set	rvb, #0x02
	str	rvb, [rva, #usb_glbstate] @ set CONFG bit
	@ set default i/o port to usb
	ldr	rvb, =vusb
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

usbhwDeconfigure: @ Deconfigure the device
	ldr	rva, =usb_base
	ldr	rvb, [rva, #usb_glbstate]
	bic	rvb, rvb, #0x02		@ clear CONFG bit
	str	rvb, [rva, #usb_glbstate]
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ set uart to generate Rx interrupts
	ldr	rva, =uart0_base
	set	rvb, #1
	str	rvb, [rva, #0x08]	@ US0_IER  <- enable RxRDY interrupt
	@ set default i/o port to uart
	ldr	rvb, =vuart0
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

/* Status IN/OUT responses */

usbhwStatusOut:	@ Control OUT Interrupt, Status OUT Phase
	b	usbCIi

usbSOx:	@ Prepare setup buffer for Status OUT Phase 
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, =0x00
	str	rvb, [rva]
	set	env, #UsbControlOutEP	@ env <- Control OUT EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	bl	rdEP
	b	usbEPx

/* Enpoint stalling, unstalling */

usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80)
	ldr	rva, =usb_base
	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x20
	itT	eq
	orreq	rvb, rvb, #0x20		@ forcestall
	streq	rvb, [rva, #usb_csr0]
	beq	usbStall
usbSt1:	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x08		@ stallsent
	beq	usbSt1
hwstl1:	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x28
	itT	ne
	bicne	rvb, #0x28		@ forcestall, stallsent
	strne	rvb, [rva, #usb_csr0]
	bne	hwstl1
	b	usbEPx

usbhwStallEP: @ Stall the EndPoint in sv5
	and	rvb, sv5, #0x0F		@ rvb  <- logical endpoint
	ldr	rva, =usb_base
	add	rva, rva, rvb, LSL#2
	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x20
	itT	eq
	orreq	rvb, rvb, #0x20		@ forcestall
	streq	rvb, [rva, #usb_csr0]
	beq	usbhwStallEP
usbse1:	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x08		@ stallsent
	beq	usbse1
hwst_1:	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x28
	itT	ne
	bicne	rvb, rvb, #0x28		@ forcestall, stallsent
	strne	rvb, [rva, #usb_csr0]
	bne	hwst_1
	set	pc,  lnk

usbhwUnstallEP:	@ Unstall the EndPoint in sv5, jump to Status IN
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base
	add	rva, rva, rvb, LSL #2
	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x20
	itT	ne
	bicne	rvb, rvb, #0x20		@ forcestall
	strne	rvb, [rva, #usb_csr0]
	bne	usbhwUnstallEP
	set	pc,  lnk

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write

------------------------------------------------------------------------------*/

_func_
rdEP:	@ (eg. section 9.13)
	@ on entry:	env <- EPNum, dts <- buffer
	@ uses rva, rvb, env, dts, cnt, returns cnt = count
	ldr	rva, =usb_base		@ rva <- USB base register
	add	rva, rva, env, LSL #2	@ rva <- Stat/Ctl register for EP
	ldr	rvb, [rva, #usb_csr0]	@ rvb <- EP status
	tst	rvb, #0x42		@ is rxdatabk0 or rxdatabk1 set?
	beq	rdEP			@	if not, jump back to wait
	lsr	cnt, rvb, #16		@ cnt <- bytecount
	set	env, #0
rdEP1:	eq	env, cnt
	itTT	ne
	ldrbne	rvb, [rva, #usb_fdr0]
	strbne	rvb, [dts, env]
	addne	env, env, #1
	bne	rdEP1
	ldr	rvb, =usb_base		@ rvb <- USB base register
	sub	env, rva, rvb
	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #0x02
	it	ne
	setne	env, #0x02
	tst	rvb, #0x40
	it	ne
	orrne	env, env, #0x40
	tst	rvb, #0x01
	it	ne
	orrne	env, env, #0x01
rdEP6:	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, env
	itT	ne
	bicne	rvb, rvb, env		@ rxdatabk0, rxdatabk1, txcomp
	strne	rvb, [rva, #usb_csr0]
	bne	rdEP6
	set	pc,  lnk

_func_
wrtEP:	@ (eg. section 9.14)
	@ on entry:	env <- EPNum, dts <- buffer, cnt <- cnt
	@ uses rva, rvb, env, dts, cnt
	ldr	rva, =usb_base		@ rva <- USB base register
	add	rva, rva, env, LSL #2	@ rva <- Stat/Ctrl register for EP
	ldr	rvb, [rva, #usb_csr0]	@ rvb <- content of Stat/Ctrl for EP
	tst	rvb, #usb_txrdy		@ is txpktrdy set?
	bne	wrtEP			@	if so,  jump back to wait
	set	env, #0			@ env <- 0 = write char offset
wrtEP1:	eq	env, cnt		@ done writing?
	itTT	ne
	ldrbne	rvb, [dts, env]		@ 	if not, rvb <- next data word
	strbne	rvb, [rva, #usb_fdr0]	@	if not, write data to Transmit register
	addne	env, env, #1		@ 	if not, env <- updated data source address
	bne	wrtEP1			@	if not, jump back to keep writing chars
wrtEP6:	ldr	rvb, [rva, #usb_csr0]	@ rvb <- content of Stat/Ctrl for EP
	tst	rvb, #usb_txrdy		@ is txpktrdy set?
	itT	eq
	orreq	rvb, rvb, #usb_txrdy	@	if so,  rvb <- sta/ctl with txpktrdy set
	streq	rvb, [rva, #usb_csr0]	@	if so,  set txpktrdy
	beq	wrtEP6			@	if so,  jump back to check status
wrtEP2:	ldr	rvb, [rva, #usb_csr0]	@ rvb <- content of Stat/Ctrl for EP
	tst	rvb, #0x01		@ is txcomp set (Tx done)?
	beq	wrtEP2			@	if not, jump back to keep waiting
wrtEP7:	ldr	rvb, [rva, #usb_csr0]	@ rvb <- content of Stat/Ctrl for EP
	tst	rvb, #0x01		@ is txcomp set?
	itT	ne
	bicne	rvb, rvb, #0x01		@ 	if so,  rvb <- sta/ctl with txcomp clrd
	strne	rvb, [rva, #usb_csr0]	@	if so,  clear txcomp in sta/ctl
	bne	wrtEP7			@	if so,  jump back to check status
	set	pc,  lnk		@ return

_func_
wrtEPU:	@ (eg. section 9.14)
	@ on entry:	env <- EPNum, dts <- buffer, cnt <- cnt
	@ uses rva, rvb, env, dts, cnt
	ldr	rva, =usb_base		@ rva <- USB base register
	add	rva, rva, env,  LSL #2	@ rva <- Stat/Ctrl register for EP
	ldr	rvb, [rva, #usb_csr0]	@ rvb <- content of Stat/Ctrl
	tst	rvb, #0x01		@ is txcomp set?
	itT	ne
	bicne	rvb, rvb, #0x01		@ 	if so,  rvb <- clear txcomp in sta/ctl
	strne	rvb, [rva, #usb_csr0]	@	if so,  clear txcomp in register
	bne	wrtEPU			@	if so,  jump back to check status
	set	env,  #0		@ env <- 0 = initial char offset
wrtEU3:	eq	env,  cnt		@ done writing chars?
	itTT	ne
	ldrbne	rvb, [dts, env]		@ 	if not, rvb <- next data byte
	strbne	rvb, [rva, #usb_fdr0]	@ 	if not, write data to Transmit register
	addne	env, env,  #1		@ 	if not, env <- updated data source address
	bne	wrtEU3			@	if not, jump back to keep writing chars
wrtEU4:	ldr	rvb, [rva, #usb_csr0]
	tst	rvb, #usb_txrdy
	itT	eq
	orreq	rvb, rvb, #usb_txrdy	@ txpktrdy
	streq	rvb, [rva, #usb_csr0]
	beq	wrtEU4
	set	pc,  lnk

/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

_func_
usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base		@ rva <- USB base address
	ldr	rvc, [rva, #usb_ibulkin] @ rvc <- content of UDP_CSR3 (BulkIN EP3 sta/ctl)
	tst	rvc, #0x01		@ is txcomp set?
	it	eq
	tsteq	rvc, #usb_txrdy		@	if not, is txpktrdy set?
	itT	eq
	orreq	rvc, rvc, #usb_txrdy	@	if not, rvb <- USB sta/ctl w/Txpktrdy bit
	streq	rvc, [rva, #usb_ibulkin] @	if not, set packet ready in USB stat/ctrl
	beq	usbhwrc			@	if not, jump back to verify bit settings
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return




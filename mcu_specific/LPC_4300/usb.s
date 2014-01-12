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

_func_
usbhwDeviceStatus: @ return device status in rvb
	@ on exit:	rvb <- device status
	@ modifies:	rva, rvb
	@ side-effect:	clears usb interrupts (global, not endpoint)
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt
	set	rvb, sv1
	set	pc,  lnk

_func_
usbhwReset:
	ldr	rva, =usb_base
	ldr	rvb, [rva, #0xac]	@ rvb <- ENDPTSETUPSTAT
	str	rvb, [rva, #0xac]	@ clear EP setups
	ldr	rvb, [rva, #0xbc]	@ rvb <- ENDPTCOMPLETE
	str	rvb, [rva, #0xbc]	@ clear EP complete
urstw0:	ldr	rvb, [rva, #0xb0]	@ rvb <- ENDPTPRIME
	eq	rvb, #0
	bne	urstw0
	mvn	rvb, rvb
	str	rvb, [rva, #0xb4]	@ ENDPTFLUSH <- flush endpoints
urstw1:	ldr	rvb, [rva, #usb_istat_dv] @ rvb <- device status
	tst	rvb, #0x04		@ port change detected?
	beq	urstw1
	set	rvb, #0x04
	str	rvb, [rva, #usb_iclear_dv]
	@
	@ we can check attach speed (FS vs HS) at #0x84 USB_PORTSC1 (p. 461)
	@ and then update USB_FSHS_MODE accordingly. but here, we run in full-speed
	@ only (set in LPC_4300_init_io.s).
	@
.ifdef has_HS_USB
	ldr	rvb, [rva, #0x84]	@ rvb <- USB_PORTSC1
	tst	rvb, #(1 << 27)		@ running in HS mode?
	itTT	ne
	ldrne	rva, =USB_FSHS_MODE	@
	setne	rvb, #1			@
	strne	rvb, [rva]		@ 	if so,  indicate that USB is now in HS mode
.endif
.ifdef debug_usb
	@ DEBUG -> store packet into RAM
	set	rva, #0x20000000
	ldr	rvc, [rva]
	add	rvb, rvc, #4
	str	rvb, [rva]
	add	rva, rva, rvc
	set	rvb, #0xaa
	str	rvb, [rva, #0]
	ldr	rvb, =0xABCDEF00
	str	rvb, [rva, #4]
.endif
	ldr	sv5, =usb_queue_heads
	add	rva, sv5, #0x0200
	b	hwprimeEP0rd

_func_
usbhwRemoteWakeUp:
	set	pc,  lnk

/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

_func_
usbhwEndpointStatus: @ return endpoint status in sv3
	ldr	rva, =usb_base
	ldr	sv2, [rva, #usb_istat_ep]	@ sv2 <- Endpoint Interrupt Status (eisr)
	ldr	sv3, [rva, #0xac]		@ sv3 <- EPSetupSTAT
	@ clear selected interrupts
	str	sv2, [rva, #usb_iclear_ep]	@ clear the interrupt
	tst	sv3, #1
	it	ne
	orrne	sv2, sv2, #usbCO_ibit
	@ clear control IN interrupt if there's a bulk in/out interrupt
	tst	sv2, #4
	it	eq
	tsteq	sv2, #(4 << 16)
	it	ne
	bicne	sv2, sv2, #(1 << 16)
.ifdef debug_usb
	@ DEBUG -> store packet into RAM
	set	rva, #0x20000000
	ldr	rvc, [rva]
	add	rvb, rvc, #8
	str	rvb, [rva]
	add	rva, rva, rvc
	str	sv2, [rva, #0]
	str	sv3, [rva, #4]
	ldr	rvb, =0xABCDEF00
	str	rvb, [rva, #8]
.endif
	ldr	rva, =usb_base
	set	pc,  lnk

/* BULK IN Enpoint Interrupt Response */

_func_
usbhwBIe: @ clear the txendpkt interrupt
	and	env, sv1, #usb_itxendp
	ldr	rva, =usb_base
	str	env, [rva, #usb_iclear_dv] @ clear USB interrupt register
	set	pc,  lnk

/* BULK OUT Enpoint Interrupt Response */

_func_
usbhwBOw: @ initiate input data echo (if needed)
	@ modifies:	rva, rvb
	@ returns via:	lnk
	ldr	rva, =usb_base
	ldr	rvb, [rva, #usb_ibulkin]
	tst	rvb, #usb_txrdy		@ txpktrdy
	bne	usbixt			@ exit
	ldr	rva, =usb_queue_heads
	add	rvb, rva, #0x0140	@ rvb <- address of QH2  IN
	add	rva, rva, #0x02a0	@ rva <- address of dTD2 IN
	str	rva, [rvb, #0x08]	@ store address of dTD in QH next dTD
	set	rva, #0
	str	rva, [rvb, #0x0c]	@ clear QH STAT
	add	rvb, rvb, #0x160	@ rvb <- address of dTD2 IN
	set	rva, #1
	str	rva, [rvb]		@ set dTD as list tail
	set	rva, #0x80		@ dTD status = active, data count = 0
	orr	rva, rva, #(1 << 15)	@ set interrupt on completion for dTD
	str	rva, [rvb, #0x04]	@ store control info in dTD
	ldr	rva, =usb_base
	set	rvb, #(4 << 16)
	str	rvb, [rva, #0xb0]	@ ENDPTPRIME <- prime endpoint
	@ wait for bit to be set in ENDPTSTATUS
uhwrE1:	ldr	rvb, [rva, #0xb8]
	tst	rvb, #(4 << 16)
	beq	uhwrE1
	b	usbixt			@ exit

/* CONTROL IN Enpoint Interrupt Response */


/* CONTROL OUT Enpoint Interrupt Response */

_func_
usbhwSetup: @ Control OUT Interrupt, Setup Phase
	ldr	rva, =usb_queue_heads
	ldr	rvb, [rva, #0x28]
	str	rvb, [dts]
	ldr	rvb, [rva, #0x2c]
	str	rvb, [dts, #4]
.ifdef debug_usb
	@ DEBUG -> store packet into RAM
	set	rva, #0x20000000
	ldr	rvc, [rva]
	add	rvb, rvc, #8
	str	rvb, [rva]
	add	rva, rva, rvc
	ldr	rvb, [dts, #0]
	str	rvb, [rva, #0]
	ldr	rvb, [dts, #4]
	str	rvb, [rva, #4]
	ldr	rvb, =0xABCDEF00
	str	rvb, [rva, #8]
.endif	
	ldr	rva, =usb_base
	str	sv3, [rva, #0xac]	@ ENDPTSetupSTAT <- ack/clr setup rcvd
uhwsw0:	ldr	rvb, [rva, #0xac]
	eq	rvb, #0
	bne	uhwsw0
	set	rvb, #(1 << 16)
	orr	rvb, rvb, #1
	str	rvb, [rva, #0xb4]	@ flush pending cntrl IN/OUT tfr, if any
uhwsw1:	ldr	rvb, [rva, #0xb8]
	tst	rvb, #1
	it	eq
	tsteq	rvb, #(1 << 16)
	bne	uhwsw1
	set	pc,  lnk

_func_
usbhwDGD: @ 9.4.3 Get Descriptor of Device Standard request
	bl	wrtEP
	b	usbSOx
	
_func_
usbhwEGS: @ Get Status of Endpoint in sv5 into rvb
	@ on entry:	sv5 <- endpoint to get status from
	@ on exit:	rvb <- endpoint status: 0 = not stalled, 1 = stalled
	@ modifies:	rvb
	set	rvb, #0
	set	pc,  lnk

_func_
usbhwSetAddress: @ Set Device to Address in SETUP buffer
	@ modifies:	rva, rvb
	ldr	rva, =USB_SETUP_BUFFER	@ rva <- address of setup buffer
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	lsr	rvb, rvb, #16		@ rvb <- address = val(16)	
	ldr	rva, =usb_base
	lsl	rvb, rvb, #25
	orr	rvb, rvb, #(1 << 24)
	str	rvb, [rva, #0x54]
	b	usbSIx			@ jump to Status IN Phase and exit

_func_
usbhwConfigure: @ Configure the device
	@ modifies:	rva, rvb, rvc, sv4, sv5
	@ side-effects:	uart interrupts, default i/o port, read buffer
	@ stop uart from generating Rx interrupts (noise on shared READBUFFER)
	ldr	rva, =uart0_base
	set	rvb, #0
	str	rvb, [rva, #uart_ier]	@ U0IER <- disable UART0 RDA interrupt
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ Realize the Interrupt In Endpoint (phys 3, log 1, aka 0x81)
	ldr	rva, =usb_base
	ldr	rvb, =((1<<23) | (3<<18))
	str	rvb, [rva, #0xc4]	@ EPCTRL1  <- enab EP 1 Tx,as int EP
	ldr	rvc, =usb_queue_heads	@ rvc <- Queue Heads start address
	ldr	rvb, =0x20080000	@ rvb <- no ZLT, 8-byte max packet
	str	rvb, [rvc, #0xc0]	@ QH1 IN  <- set capabilities
	set	rvb, #0
	str	rvb, [rvc, #0xc4]	@ QH1 IN  <- set current dTD
	set	rvb, #1
	str	rvb, [rvc, #0xc8]	@ QH1 IN  <- set tail
	@ Realize the Bulk Out/In Endpoint (phys. 4, 5, log. 2)
	ldr	rvb, =((1<<23) | (2<<18) | (1<<7) | (2<<2))
	str	rvb, [rva, #0xc8]	@ EPCTRL2  <- enab EP 2 Rx,Tx,as bulk EP
	add	rvc, rvc, #0x0100
	ldr	rvb, =0x20400000	@ rvb <- no ZLT, 64-byte max packet
	str	rvb, [rvc, #0x00]	@ QH2 OUT <- set capabilities
	str	rvb, [rvc, #0x40]	@ QH2 IN  <- set capabilities
	set	rvb, #0
	str	rvb, [rvc, #0x04]	@ QH2 OUT <- set current dTD
	str	rvb, [rvc, #0x44]	@ QH2 IN  <- set current dTD
	set	rvb, #1
	str	rvb, [rvc, #0x08]	@ QH2 OUT <- set tail
	str	rvb, [rvc, #0x48]	@ QH2 IN  <- set tail
	set	sv5, rvc
	add	rva, sv5, #0x0180
	set	sv4, lnk
	bl	hwprimeEP0rd
	@ set default i/o port to usb
	ldr	rvb, =vusb
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  sv4

_func_
usbhwDeconfigure: @ Deconfigure the device
	@ modifies:	rva, rvb
	@ side-effects:	uart interrupts, default i/o port, read buffer
	@ disable the Interrupt In and Bulk Out/In EP 2 (phys. 3,4,5 log. 1,2)
	ldr	rva, =usb_base
	ldr	rvb, =((0<<23) | (3<<18))
	str	rvb, [rva, #0xc4]	@ EPCTRL1  <- disab EP 1 Tx, int EP
	ldr	rvb, =((0<<23) | (2<<18) | (0<<7) | (2<<2))
	str	rvb, [rva, #0xc8]	@ EPCTRL1  <- disab EP 2 Rx,Tx, bulk EP
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ set uart to generate Rx interrupts
	ldr	rva, =uart0_base
	set	rvb, #1
	str	rvb, [rva, #uart_ier]	@ U0IER <- disable UART0 RDA interrupt
	@ set default i/o port to uart
	ldr	rvb, =vuart0
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

/* Status IN/OUT responses */

_func_
usbhwStatusOut:	@ Control OUT Interrupt, Status OUT Phase
	set	env,  #UsbControlOutEP	@ env <- Control OUT EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	set	cnt, #0			@ cnt <- 0 bytes to read
	bl	rdEP			@ read 0 bytes from EP
	b	usbEPx

_func_
usbSOx:	@ Prepare setup buffer for Status OUT Phase
	@ modifies:	rva, rvb, sv5
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, =0xFF
	str	rvb, [rva]	
	ldr	sv5, =usb_queue_heads
	add	rva, sv5, #0x0200
	bl	hwprimeEP0rd
	b	usbEPx

/* Enpoint stalling, unstalling */

_func_
usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80)
	b	usbEPx

_func_
usbhwStallEP: @ Stall EP in sv5
	@ on entry:	sv5 <- endpoint to stall
	set	pc,  lnk

_func_
usbhwUnstallEP:	@ Unstall the EndPoint in sv5
	@ on entry:	sv5 <- endpoint to unstall
	set	pc,  lnk

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write and helper functions

------------------------------------------------------------------------------*/

_func_
rdEP:	@ (eg. section 9.13) uses rva, rvb, env, dts, cnt, returns cnt = count
	@ on entry:	env <- EPNum
	@ on entry:	dts <- buffer
	@ on exit:	cnt <- number of bytes read
	@ modifies:	rva, rvb, sv5, cnt
	set	rvb, #0x40
	mul	rvb, env, rvb
	ldr	rva, =usb_queue_heads
	add	sv5, rva, rvb		@ sv5 <- QHn address
	set	rvb, #0x20
	mul	rvb, env, rvb
	add	rva, rva, rvb
	add	rva, rva, #0x0200	@ rva <- dTDn address
	ldr	rvb, [sv5, #0x00]
	ldr	cnt, [rva, #0x04]
	lsr	rvb, rvb, #16
	and	rvb, rvb, #0xff
	lsr	cnt, cnt, #16
	and	cnt, cnt, #0xff
	sub	cnt, rvb, cnt
	set	rvb, #0x200
	mul	rvb, env, rvb
	ldr	rva, =usb_queue_heads
	add	rva, rva, rvb
	add	rva, rva, #(1 << 12)	@ rva <- Buffer0 address
	set	sv5, #0
rdEP_1:	@ read packet into data buffer
	ldrb	rvb, [rva, sv5]		@ rvb <- next data byte
	strb	rvb, [dts, sv5]		@ write data to buffer
	add	sv5, sv5, #1		@ dts <- updated data source address
	cmp	sv5, cnt		@ done?
	bmi	rdEP_1			@	if not, jump back to continue
	set	rvb, #0x40
	mul	rvb, env, rvb
	ldr	rva, =usb_queue_heads
	add	sv5, rva, rvb		@ sv5 <- QHn address
	set	rvb, #0x20
	mul	rvb, env, rvb
	add	rva, rva, rvb
	add	rva, rva, #0x0200	@ rva <- dTDn address
_func_
hwprimeEP0rd: @ continue and [internal entry]
	@ on entry:	sv5 <- QHn  address for endpoint
	@ on entry:	rva <- dTDn address for endpoint
	str	rva, [sv5, #0x08]	@ store address of dTD in QH next dTD
	set	rvb, #0
	str	rvb, [sv5, #0x0c]	@ clear QH STAT
	set	rvb, #1
	str	rvb, [rva]		@ set dTD as list tail
	ldr	rvb, [sv5]
	and	rvb, rvb, #0xff0000	@ data count (max for EP)
	orr	rvb, rvb, #(1 << 15)	@ set interrupt on completion for dTD
	orr	rvb, rvb, #0x80		@ dTD status = active
	str	rvb, [rva, #0x04]	@ store control info in dTD
	ldr	rvb, =usb_queue_heads
	sub	rvb, sv5, rvb
	lsl	rvb, rvb, #3
	ldr	sv5, =usb_queue_heads
	add	rvb, sv5, rvb
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x08]	@ store buffer ptr 0
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x0c]	@ store buffer ptr 1
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x10]	@ store buffer ptr 2
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x14]	@ store buffer ptr 3
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x18]	@ store buffer ptr 4
	lsr	sv5, rva, #6
	and	sv5, sv5, #3
	ldr	rva, =usb_base
	set	rvb, #1
	lsl	rvb, rvb, sv5
	str	rvb, [rva, #0xb0]	@ ENDPTPRIME <- prime endpoint
	@ may want to wait for bit to be set in ENDPTSTATUS here
rdEP_2:	ldr	sv5, [rva, #0xb8]
	tst	sv5, rvb
	beq	rdEP_2
	set	pc,  lnk

_func_
wrtEPU:	@ (eg. section 9.14)
	@ on entry:	env <- EPNum
	@ on entry:	dts <- buffer
	@ on entry:	cnt <- cnt
	@ modifies:	rva, sv1, sv4
	set	sv4, lnk
	bl	wrtEP
	bic	sv1, sv1, #usb_itxendp	   @ exclude Txendpkt bit from interrupt clearing
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt
	set	pc,  sv4

_func_
wrtEP:	@ (eg. section 9.14) uses rva, rvb, env, dts, cnt
	@ on entry:	env <- EPNum
	@ on entry:	dts <- data start address (buffer)
	@ on entry:	cnt <- number of bytes to write to USB
	@ set write_enable bit, and endpoint to use in control register
	and	env, env, #0x0F
	eq	env, #0
	beq	wrtEw1
	@ for bulk EP (eg. echo of rcvd chars) wait for prior tranfer to be complete
	ldr	rva, =usb_base
wrtEw0:	ldr	rvb, [rva, #usb_ibulkin]
	tst	rvb, #usb_txrdy		@ txpktrdy
	bne	wrtEw0
wrtEw1:	@ continue
	set	rvb, #0x40
	mul	rvb, env, rvb
	ldr	rva, =usb_queue_heads
	add	sv5, rva, rvb
	set	rvb, #0x20
	mul	rvb, env, rvb
	add	rva, rva, rvb
	add	rva, rva, #0x0200
	str	rva, [sv5, #0x08]	@ store address of dTD in QH next dTD
	set	rvb, #0
	str	rvb, [sv5, #0x0c]	@ clear QH STAT
	set	rvb, #1
	str	rvb, [rva]		@ set dTD as list tail
	lsl	rvb, cnt, #16		@ set data count for dTD
	eq	cnt, #0			@ transferring zero bytes?
	it	ne
	orrne	rvb, rvb, #(1 << 15)	@ 	if not, set interrupt on completion for dTD
	orr	rvb, rvb, #0x80		@ dTD status = active
	str	rvb, [rva, #0x04]	@ store control info in dTD
	set	rvb, #0x0200
	mul	rvb, env, rvb
	ldr	sv5, =usb_queue_heads
	add	rvb, sv5, rvb
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x08]	@ store buffer ptr 0
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x0c]	@ store buffer ptr 1
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x10]	@ store buffer ptr 2
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x14]	@ store buffer ptr 3
	add	rvb, rvb, #(1 << 12)
	str	rvb, [rva, #0x18]	@ store buffer ptr 4
	sub	rva, rvb, #(1 << 14)
	set	sv5, #0
	@ write data packet to send
wrtEP1:	ldrb	rvb, [dts, sv5]		@ rvb <- next data word
	strb	rvb, [rva, sv5]		@ write data to Transmit buffer
	add	sv5, sv5, #1		@ dts <- updated data source address
	cmp	sv5, cnt
	bmi	wrtEP1
	ldr	rva, =usb_base
	set	rvb, #1
	lsr	sv5, env, #1
	lsl	rvb, rvb, sv5
	lsl	rvb, rvb, #16
	str	rvb, [rva, #0xb0]	@ ENDPTPRIME <- prime endpoint
	@ may want to wait for bit to be set in ENDPTSTATUS here
wrtEP2:	ldr	sv5, [rva, #0xb8]
	tst	sv5, rvb
	beq	wrtEP2
	set	pc,  lnk

/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

_func_
usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base
	ldr	rvc, [rva, #usb_ibulkin]
	tst	rvc, #usb_txrdy		@ txpktrdy
	bne	usbhwrcxt
	ldr	rva, =usb_queue_heads
	add	rvc, rva, #0x0140	@ rvc <- address of QH2  IN
	add	rva, rva, #0x02a0	@ rva <- address of dTD2 IN
	str	rva, [rvc, #0x08]	@ store address of dTD in QH next dTD
	set	rva, #0
	str	rva, [rvc, #0x0c]	@ clear QH STAT
	add	rvc, rvc, #0x160	@ rvc <- address of dTD2 IN
	set	rva, #1
	str	rva, [rvc]		@ set dTD as list tail
	set	rva, #0x80		@ dTD status = active, data count = 0
	orr	rva, rva, #(1 << 15)	@ set interrupt on completion for dTD
	str	rva, [rvc, #0x04]	@ store control info in dTD
	ldr	rva, =usb_base
	set	rvc, #(4 << 16)
	str	rvc, [rva, #0xb0]	@ ENDPTPRIME <- prime endpoint
	@ wait for bit to be set in ENDPTSTATUS
uhwrc1:	ldr	rvc, [rva, #0xb8]
	tst	rvc, #(4 << 16)
	beq	uhwrc1
usbhwrcxt: @ finish up
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return




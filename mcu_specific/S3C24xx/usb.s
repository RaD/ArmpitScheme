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

usbhwgetDevint: @ get device interrupt status into sv1
	@ on entry:	rva <- USB base address
	@ on exit:	sv1 <- interrupt status w/r Device
	ldr	sv1, [rva, #usb_istat_dv2] @ sv1 <- Device Interrupt Status
	set	pc,  lnk

usbhwDeviceStatus: @ return device status in rvb
	set	rvb, sv1		@ rvb <- Dev Int Stat, rst,resum,suspnd
	set	pc,  lnk

usbhwReset:
	ldr	rva, =USB_SETUP_BUFFER
	set	rvb, #0
	str	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	ldr	rva, =usb_base
	set	rvb, #0x80		@ rvb <- bit to enable USB at address 0
	str	rvb, [rva, #usb_daddr]
	set	pc,  lnk

usbhwRemoteWakeUp: @ suspend/wakeup
	set	pc,  lnk

/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

usbhwEndpointStatus: @ get status of EP whose interrupt is in sv2 into sv3
	ldr	rva, =usb_base
	set	sv2, sv1		@ sv2 <- Endpoint Interrupt Status
	set	sv3, sv2
	tst	sv2, #1			@ EP0 (control) interrupt?
	seteq	pc,  lnk		@	if not, return w/int in sv2, sv3
	set	sv3, lnk
	set	env, #0
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	lnk, sv3
	ldr	sv3, [rva, #usb_ctl_stat]
	tst	sv3, #0x11		@ is OUT_PKT_RDY or SETUP_END set?
	seteq	sv2, #2			@	if not, sv2 <- control In  indic
	setne	sv2, #1			@	if so,  sv2 <- control out indic
	mvn	sv3, sv3
	set	pc,  lnk
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	ldr	rva, =0x2021
	eq	rva, rvb
	biceq	sv3, sv3, #0x110
	set	pc,  lnk

/* BULK IN Enpoint Interrupt Response */


/* BULK OUT Enpoint Interrupt Response */

usbhwBOw: @ initiate input data echo (if needed)
	@ modifies:	rva, rvb, rvc
	@ returns via:	usbixt (direct exit)
	set	env, #UsbBulkInEP
	bl	usbhwSelectEP		   @ rva <- usb_base,sel EP in INDEX_REG
	ldr	rvc, [rva, #usb_ctl_stat]  @ rvc <- status from IN_CSR1_REG
	tst	rvc, #1			   @ is IN_PKT_RDY set (dev wtng 2 snd)?
	itT	eq
	seteq	rvc, #1			   @	if not, rvc <- IN_PKT_RDY
	streq	rvc, [rva, #usb_ctl_stat]  @ 	if not, set IN_PKT_RDY in TXCSR
	b	usbixt

/* CONTROL IN Enpoint Interrupt Response */

	
/* CONTROL OUT Enpoint Interrupt Response */

usbhwSetup: @ see also rdEP, here, env = 0
	@ on entry:	dts <- USB_SETUP_BUFFER
	ldr	rvb, [dts]		@ rvb <- reqtyp(8), request(8), val(16)
	ldr	rva, =0x2021
	eq	rva, rvb
	beq	usbsrq
	set	sv3, lnk		@ sv3 <- lnk, saved against bl
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwReadEP2Buf
	set	lnk, sv3		@ lnk <- lnk, restored
	set	rvb, #0x40		  @ rvb <- SERVICED_OUT_PKT_RDY
	str	rvb, [rva, #usb_ctl_stat] @ clear OUT_PKT_RDY bit in EP0_CSR
	set	pc,  lnk

usbsrq:	@ continue to process request (via usbRQS)
	set	rva, dts		@ rva <- USB_SETUP_BUFFER
	ldr	sv5, [dts, #4]		@ sv5 <- index(16), length(16)
	lsr	cnt, sv5, #16		@ cnt <- length of data to transfer
	@ here:		rva <- USB_SETUP_BUFFER
	@ here:		rvb <- reqtyp(8l), request(8h), val(16H)
	@ here:		sv5 <- index(16L), length(16H)
	@ here:		cnt <- num bytes to transfer (length)
	b	usbRQS

usbhwDGD: @ 9.4.3 Get Descriptor of Device Standard request	
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwWriteBuf2EP	@ write from buffer to IN EP
	set	rvb, #0x02		  @ rvb <- IN_PKT_RDY bit for EP0
	str	rvb, [rva, #usb_ctl_stat] @ set IN_PKT_RDY bit in EP0_CSR
	b	usbSOx

usbhwEGS: @ Get Status of Endpoint in sv5 into rvb
	ldr	rva, =usb_base
	set	rvb, #1
	set	pc,  lnk

usbhwSetAddress: @ Set Device to Address in sv5
	ldr	rva, =usb_base
	orr	rvb, rvb, #0x80		   @ rvb <- adrs ored w/Dev Enab (0x100)
	str	rvb, [rva, #usb_daddr]	   @ set address	
	set	env, #UsbControlInEP	   @ env <- Control IN EndPoint
	bl	usbhwSelectEP		   @ rva <- usb_base,sel EP in INDEX_REG
	set	rvb, #0x08		   @ rvb <- DATA_END
	str	rvb, [rva, #usb_ctl_stat]  @ set DATA_END bit in EP0_CSR
	b	usbEPx

usbhwConfigure: @ Configure the device
	@ stop uart from generating Rx interrupts (noise on shared READBUFFER)
	ldr	rva, =uart0_base
	set	rvb, #0
	str	rvb, [rva, #0x04]	@ UCON0 <- disable Tx, Rx, and error Int
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ configure USB
	set	rvc, lnk		@ rvc <- lnk, saved
	set	env, #UsbBulkOutEP
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	rvb, #0
	str	rvb, [rva, #0x48]	@ set direction to OUT in IN_CSR2_REG
	set	rvb, #0x08
	str	rvb, [rva, #0x40]	@ set packet size to 64 byts in MAXP_REG
	set	env, #UsbBulkInEP
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	lnk, rvc		@ lnk <- lnk, restored
	set	rvb, #0x20
	str	rvb, [rva, #0x48]	@ set direction to IN in IN_CSR2_REG
	set	rvb, #0x08
	str	rvb, [rva, #0x40]	@ set packet size to 64 byts in MAXP_REG
	@ set default i/o port to usb
	ldr	rvb, =vusb
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

usbhwDeconfigure: @ Deconfigure the device
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ set uart to generate Rx interrupts
	ldr	rva, =uart0_base
	set	rvb, #0x45
	str	rvb, [rva, #0x04]	@ UCON0 <- enable Tx, Rx, and error ints
	@ set default i/o port to uart
	ldr	rvb, =vuart0
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

/* Status IN/OUT responses */

usbhwStatusOut:	@ Control OUT Interrupt, Status OUT Phase
	set	env, #UsbControlOutEP		@ env <- Control OUT EndPoint	
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	rvb, #0x80		  @ rvb <- SERVICED_SETUP_END
	str	rvb, [rva, #usb_ctl_stat] @ set SERVICED_SETUP_END in EP0_CSR
	ldr	dts, =USB_DATA		  @ dts <- buffer
	set	cnt, #0			  @ cnt <- 0 bytes to read
	bl	rdEP			  @ read 0 bytes from EP
	b	usbEPx

usbSOx:	@ Prepare setup buffer for Status OUT Phase 
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, =0xFF
	str	rvb, [rva]
	b	usbEPx

usbhwSIX: @ status IN exit
	ldr	rva, =USB_SETUP_BUFFER
	set	rvb, #0xFF
	str	rvb, [rva]
	ldr	rva, =USB_CHUNK
	set	rvb, #0
	str	rvb, [rva]		@ cnt <- 0 bytes remain to be sent
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	set	cnt, #0x00		@ cnt <- 0 bytes to send
	bl	wrtEP			@ write 0 bytes to EP
	b	usbEPx

/* Enpoint stalling, unstalling */

usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80) -- i.e. Control IN
	set	env, #UsbControlOutEP	  @ env <- Control OUT EndPoint
	bl	usbhwSelectEP		  @ rva <- usb_base, sel EP in INDEX_REG
	set	rvb, #0x68
	str	rvb, [rva, #usb_ctl_stat] @ set SERVICED_OUT_PKT_RDY+SEND_STALL
	b	usbEPx

usbhwUnstallEP:	@ Unstall the EndPoint in sv5, jump to Status IN
	set	pc,  lnk

usbhwStallEP: @ Stall the EndPoint in r5
	set	pc,  lnk

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write and helper functions

------------------------------------------------------------------------------*/

rdEP:	@ read from endpoint in env to buffer in dts with count in cnt
	set	sv5, lnk
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwReadEP2Buf
	set	lnk, sv5
	cmp	env, #2
	setpl	rvb, #0
	strpl	rvb, [rva, #0x50]	@ clear OUT_PKT_RDY bit in OUT_CSR1_REG
	setpl	pc,  lnk
	@ EP0 special processing	
	set	rvb, #0x40		  @ rvb <- SERVICED_OUT_PKT_RDY
	eq	cnt, #0			  @ zero bytes to read?
	orreq	rvb, rvb, #0x08		  @	if so,  rvb <- SRVCDPKT,DATA_END
	str	rvb, [rva, #usb_ctl_stat] @ set SERVICED_OUTPKT_RDY in EP0_CSR
	set	pc,  lnk
	
wrtEPU:	@ clear EP rcv interrupt then write data to Bulk In Endpoint
	@ (write cnt bytes starting at dts to enpoint in env)
	ldr	rva, =usb_base	
	str	sv1, [rva, #usb_iclear_ep] @ clear USB EP interrupt register
	@ continue to wrtEP

wrtEP:	@ write data from buffer to IN EP
	set	sv5, lnk		  @ sv5 <- lnk, saved
	bl	usbhwSelectEP		  @ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwWriteBuf2EP	  @ write from buffer to IN EP
	set	lnk, sv5		  @ lnk <- lnk, restored
	cmp	env, #2
	setpl	rvb, #1
	strpl	rvb, [rva, #usb_ctl_stat] @ set IN_PKT_RDY bit in IN_CSR1_REG
	setpl	pc,  lnk
	@ EP0 special processing
	ldr	rvb, =USB_CHUNK
	ldr	rvb, [rvb]		  @ rvb <- num bytes remaining to send
	eq	rvb, #0			  @ nothing remaining?
	setne	rvb, #0x02		  @	if not, rvb <- IN_PKT_RDY
	strne	rvb, [rva, #usb_ctl_stat] @ 	if not, set PKTRDY in EP0_CSR
	setne	pc,  lnk		  @ 	if not, return
	eq	rvb, cnt
	setne	rvb, #0x0A		  @	if not, rvb <- IN_PKT_RDY
	strne	rvb, [rva, #usb_ctl_stat] @ set IN_PKT_RDY bit in EP0_CSR
	set	pc,  lnk


/* helper functions */

usbhwSelectEP: @ select EP in INDEX_REG
	@ on entry:	env <- EP to select
	@ on exit:	rva <- usb base address
	@ modifies:	rva, rvb
	ldr	rva, =usb_base		   @ rva <- usb_base
	str	env, [rva, #usb_index_reg] @ select endpoint in INDEX_REG
usbslw:	ldr	rvb, [rva, #usb_index_reg] @ rvb <- selected EP
	eq	rvb, env		   @ is it the desired EP?
	bne	usbslw			   @	if not, jump back to wait
	set	pc,  lnk		   @ return

usbhwReadEP2Buf: @ read from OUT EP into buffer
	@ on entry:	env <- EP to read from (selected already)
	@ on entry:	rva <- usb base address
	@ on exit:	cnt <- number of bytes read
	@ modifies:	rvb, rvc, cnt
	ldr	cnt, [rva, #usb_rcvd_cnt] @ cnt <- byte count from OUT_FIFO_CNT1_REG
	add	rva, rva, #0x80		  @ rva <- address of base of EP FIFOs
	set	rvb, #0
usbrbt:	@ read bytes
	cmp	rvb, cnt
	ldrmi	rvc, [rva, env, lsl #2]	  @ rvc <- data byte from EPn_FIFO
	strbmi	rvc, [dts, rvb]
	addmi	rvb, rvb, #1
	bmi	usbrbt
	ldr	rva, =usb_base
	set	pc,  lnk

usbhwWriteBuf2EP: @ write from buffer to IN EP
	@ on entry:	rva <- usb_base
	@ on entry:	env <- IN EP to write to
	@ on entry:	dts <- buffer
	@ on entry:	cnt <- number of bytes to send
	@ modifies:	rvb, rvc
	eq	env, #0
	seteq	rvb, #0
	setne	rvb, #1
usbwwt:	ldr	rvc, [rva, #usb_ctl_stat]
	tst	rvc, rvb
	bne	usbwwt
	add	rva, rva, #0x80		@ rva <- address of base of EP FIFOs
	set	rvb, #0
usbwbt:	@ write bytes
	cmp	rvb, cnt
	ldrbmi	rvc, [dts, rvb]		@ rvc <- data from buffer
	strmi	rvc, [rva, env, lsl #2]	@ store it in EPn_FIFO
	addmi	rvb, rvb, #1
	bmi	usbwbt
	ldr	rva, =usb_base
	set	pc,  lnk

/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base
	set	rvc, #UsbBulkInEP
	str	rvc, [rva, #usb_index_reg] @ select endpoint in INDEX_REG
usbwcw:	ldr	rvc, [rva, #usb_index_reg] @ rvc <- selected EP from INDEX_REG
	eq	rvc, #UsbBulkInEP	   @ correct endpoint selected?
	bne	usbwcw			   @	if not, jump back to re-select
	ldr	rvc, [rva, #usb_ctl_stat]  @ rvc <- status from IN_CSR1_REG
	tst	rvc, #1			   @ is IN_PKT_RDY set (dev wtng 2 snd)?
	itT	eq
	seteq	rvc, #1			   @	if not, rvc <- IN_PKT_RDY
	streq	rvc, [rva, #usb_ctl_stat]  @ 	if not, set IN_PKT_RDY in TXCSR
	swi	run_normal		   @ enable interrupts (user mode)
	set	pc,  lnk		   @ return







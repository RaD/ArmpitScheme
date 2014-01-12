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

	(Note: macros usbldr and usbstr are defined in device_family.h)

------------------------------------------------------------------------------*/

_func_
usbhwgetDevEPint: @ get EP int statuts into sv1
	@ on entry:	rva <- USB base address
	@ on exit:	sv1 <- interrupt status w/r EP and/or Device
	ldr	sv1, [rva, #usb_istat_dv]
	lsr	sv1, sv1, #16		@ sv1 <- USBTXIS shftd frm USBFADDR+TXIS
	ldrh	sv2, [rva, #0x04]	@ sv2 <- USBRXIS
	orr	sv1, sv1, sv2		@ sv1 <- TX and RX EP ints combined
	set	pc,  lnk

_func_
usbhwgetDevint: @ get Device int statuts into sv1
	@ on entry:	rva <- USB base address
	@ on exit:	sv1 <- interrupt status for Device
	ldrb	sv1, [rva, #usb_istat_dv2] @ sv1 <- Dev Int Stat = dwStatus
	set	pc,  lnk

_func_
usbhwDeviceStatus: @ return device status in rvb
	ldr	rva, =usb_base
	ldrb	rvb, [rva, #0x0a]	@ rvb <- USBIS interrupt status
	set	pc,  lnk

_func_
usbhwReset:
	ldr	rva, =USB_SETUP_BUFFER
	set	rvb, #0			@ rvb <- 0
	str	rvb, [rva]		@ clear the setup buffer
.ifdef USB_FSHS_MODE
	ldr	rva, =usb_base
	ldrb	rvb, [rva, #0x01]
	tst	rvb, #0x10
	seteq	rvb, #0			@ rvb <- 0
	setne	rvb, #1
	ldr	rva, =USB_FSHS_MODE
	str	rvb, [rva]		@ indicate that USB is not in HS mode
.endif
	set	pc,  lnk

_func_
usbhwRemoteWakeUp:	
	set	pc,  lnk

/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

_func_
usbhwEndpointStatus: @ get status of EP whose interrupt is in sv2 into sv3
	ldr	rva, =usb_base
	set	sv2, sv1		@ sv2 <- Endpoint Int Stat (shifted)
	set	sv3, sv2
	tst	sv2, #1			@ EP0 (control) interrupt?
	it	eq
	seteq	pc,  lnk		@	if not, return w/int in sv2, sv3
	set	sv3, lnk
	set	env, #0
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	lnk, sv3
	usbldr	sv3, rva, usb_ctl_stat
	tst	sv3, #0x10
	itTTT	ne
	setne	sv2, #0
	setne	rvb, #0x80
	usbstrne rvb, rva, usb_ctl_stat	@ set SERVICED_SETUP_END in EP0_CSR
	setne	pc,  lnk
	tst	sv3, #0x04		@ responding to sent_stall?
	itTT	ne
	setne	sv2, #0
	usbstrne sv2, rva, usb_ctl_stat
	setne	pc,  lnk
	tst	sv3, #0x11		@ is OUT_PKT_RDY or SETUP_END set?
	itE	eq
	seteq	sv2, #2			@	if not, sv2 <- control In indic
	setne	sv2, #1			@	if so,  sv2 <- control out indic
	mvn	sv3, sv3
	set	pc,  lnk

/* BULK IN Enpoint Interrupt Response */


/* BULK OUT Enpoint Interrupt Response */

_func_
usbhwBOw: @ initiate input data echo (if needed)
	@ modifies:	rva, rvb, rvc
	@ returns via:	usbixt (direct exit)
	b	usbBIi			@ jump to write OUT data to IN EP

/* CONTROL IN Enpoint Interrupt Response */

_func_
usbhwCIw:  @ Control IN EP interrupt response
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rva, [rva]
	eq	rva, #0xff
	beq	usbEPx
	b	wrtEP

/* CONTROL OUT Enpoint Interrupt Response */

_func_
usbhwSetup: @ see also rdEP, here, env = 0
	@ on entry:	env <- Control OUT EndPoint (0)
	@ on entry:	dts <- Setup_buffer
	@ on exit:	setup packet data is loaded into setup_buffer
	@ modifies:	rva, rvb, rvc, sv3, cnt
	set	sv3, lnk		@ sv3 <- lnk, saved against bl
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwReadEP2Buf
	set	lnk, sv3		@ lnk <- lnk, restored
	set	rvb, #0x40		@ rvb <- SERVICED_OUT_PKT_RDY 
	usbstr	rvb, rva, usb_ctl_stat	@ clear OUT_PKT_RDY bit in EP0_CSR
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	tst	rvb, #0x80		@ is direction from device to host?
	it	ne
	setne	pc,  lnk		@	if so,  return
	ldr	sv5, [rva, #4]		@ sv5 <- index(16), length(16)
	lsrs	cnt, sv5, #16		@ cnt <- length of data to transfer byts
	it	eq
	seteq	pc,  lnk		@ may need to set data-end too here(?)
	ldr	sv3, =usb_base
usbewt:	ldrh	rvc, [sv3, #0x02]	@ rvc <- USBTxIS
	tst	rvc, #1
	beq	usbewt
	usbldr	rvc, sv3, usb_ctl_stat	@ 
	@ here:		rva <- USB_SETUP_BUFFER
	@ here:		rvb <- reqtyp(8l), request(8h), val(16H)
	@ here:		sv5 <- index(16L), length(16H)
	@ here:		cnt <- num bytes to transfer (length)
	b	usbRQS

_func_
usbhwDGD: @ Get Descriptor of Device Standard request	
	@ on entry:	env <- Control IN EP
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwWriteBuf2EP	@ write from buffer to IN EP
	set	rvb, #0x02		@ rvb <- IN_PKT_RDY bit for EP0 
	usbstr	rvb, rva, usb_ctl_stat	@ set IN_PKT_RDY bit in EP0_CSR
	b	usbEPx

usbhwEGS: @ Get Status of Endpoint in sv5 into rvb
	ldr	rva, =usb_base
	set	rvb, #1
	set	pc,  lnk

_func_
usbhwSetAddress: @ Set Device to Address in rvb
	set	sv5, rvb		@ sv5 <- address to set (value of reqst)
	set	env, #UsbControlInEP		@ env <- Control IN EndPoint
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	rvb, #0x08		@	if so,  rvb <- PKT_RDY, DATA_END
	usbstr	rvb, rva, usb_ctl_stat	@ set IN_PKT_RDY bit in EP0_CSR
usbawt:	ldrh	rvb, [rva, #0x02]	@ rvb <- int for EP IN
	tst	rvb, #1			@ is control IN EP int asserted?
	beq	usbawt			@	if not, jump to wait
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	usbldr	rvc, rva, usb_ctl_stat	@ 
	strb	sv5, [rva, #usb_daddr]	@ set address
	b	usbEPx

_func_
usbhwConfigure: @ Configure the device
	@ stop uart from generating Rx interrupts (they cause noise on shared READBUFFER)
	ldr	rva, =uart0_base
	set	rvb, #0
	str	rvb, [rva, #0x04]	@ UCON0 <- disable Tx and Rx, and error Interrupt
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ configure USB
.ifdef usb_index_reg
	set	rvc, lnk
	set	env, #UsbBulkOutEP
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	rvb, #0
	strh	rvb, [rva, #0x12]	@ set direction to OUT in IN_CSR2_REG
	strh	rvb, [rva, #0x16]	@ set direction to OUT in IN_CSR2_REG
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	seteq	rvb, #64
	setne	rvb, #512
	strh	rvb, [rva, #0x10]	@ set packet size to 64 bytes in MAXP_REG
	strh	rvb, [rva, #0x14]	@ set packet size to 64 bytes in MAXP_REG
	set	env, #UsbBulkInEP
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	lnk, rvc
	set	rvb, #0x2000
@ modified 07/05/12 -- apparently there was a bug here!
@	strh	rvb, [rva, #0x10]	@ set direction to IN in IN_CSR2_REG
	strh	rvb, [rva, #0x12]	@ set direction to IN in IN_CSR2_REG
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	seteq	rvb, #64
	setne	rvb, #512
	strh	rvb, [rva, #0x10]	@ set packet size to 64 bytes in MAXP_REG
	strh	rvb, [rva, #0x14]	@ set packet size to 64 bytes in MAXP_REG
.else
	ldr	rva, =usb_base
	set	rvb, #0
	strh	rvb, [rva, #0x122]	@ set direction to OUT in USB_Tx_CSRL2
	strh	rvb, [rva, #0x126]	@ clear USB_Rx_CSRL2
	set	rvb, #64
	strh	rvb, [rva, #0x120]	@ set pkt siz to 64 byts in USB_Tx_MAXP2
	strh	rvb, [rva, #0x124]	@ set pkt siz to 64 byts in USB_Rx_MAXP2
	set	rvb, #0x2000
	strh	rvb, [rva, #0x132]	@ set direction to IN in USB_Tx_CSRL3
	set	rvb, #64
	strh	rvb, [rva, #0x130]	@ set pkt siz to 64 byts in USB_Tx_MAXP3
	strh	rvb, [rva, #0x134]	@ set pkt siz to 64 byts in USB_Rx_MAXP3
.endif
	@ set default i/o port to usb
	ldr	rvb, =vusb
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

_func_
usbhwDeconfigure: @ Deconfigure the device
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ set uart to generate Rx interrupts
	ldr	rva, =uart0_base
	set	rvb, #0x01
	str	rvb, [rva, #0x04]	@ UCON0 <- enable Tx and Rx, and error interrupt
	@ set default i/o port to uart
	ldr	rvb, =vuart0
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

/* Status IN/OUT responses */

_func_
usbhwStatusOut:	@ Control OUT Interrupt, Status OUT Phase
	set	env, #UsbControlOutEP	@ env <- Control OUT EndPoint	
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	rvb, #0x80		@ rvb <- SERVICED_SETUP_END
	usbstr	rvb, rva, usb_ctl_stat	@ set SERVICED_SETUP_END in EP0_CSR
	b	usbEPx

_func_
usbSOx:	@ Prepare setup buffer for Status OUT Phase 
	ldr	rva, =USB_SETUP_BUFFER
	set	rvb, #0xFF
	str	rvb, [rva]
	b	usbEPx

_func_
usbhwSIX: @ status IN exit
	ldr	rva, =USB_SETUP_BUFFER
	set	rvb, #0xFF
	str	rvb, [rva]
	set	rvb, #0
	ldr	rva, =USB_CHUNK
	str	rvb, [rva]		@ cnt <- 0 bytes remain to be sent	
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	rvb, #0x08		@ rvb <- IN_PKT_RDY
	usbstr	rvb, rva, usb_ctl_stat	@ set IN_PKT_RDY bit in EP0_CSR
usbswt:	ldrh	rvb, [rva, #0x02]
	tst	rvb, #1
	beq	usbswt
	usbldr	rvc, rva, usb_ctl_stat	@ set IN_PKT_RDY bit in EP0_CSR
	b	usbEPx

/* Enpoint stalling, unstalling */

_func_
usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80) -- i.e. Control IN
	set	env, #UsbControlOutEP	@ env <- Control OUT EndPoint
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	set	rvb, #0x68
	usbstr	rvb, rva, usb_ctl_stat	@ set SERVICED_OUT_PKT_RDY & SEND_STALL	
	b	usbEPx

_func_
usbhwStallEP: @ Stall the EndPoint in r5
	set	pc,  lnk

_func_
usbhwUnstallEP:	@ Unstall the EndPoint in sv5, jump to Status IN
	set	pc,  lnk

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write and helper functions

------------------------------------------------------------------------------*/

_func_
rdEP:	@ read from endpoint in env to buffer in dts with count in cnt
	set	sv5, lnk
	bl	usbhwSelectEP		@ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwReadEP2Buf
	set	lnk, sv5
	cmp	env, #2
	bpl	rdEPn
	@ EP0 post-read processing
	@ assumes payload is always 8-byte or less for cntrl EP (sets dataend)
	set	rvb, #0x48
	usbstr	rvb, rva, usb_ctl_stat	@ set SERVICED_OUTPKT_RDY in EP0_CSR
	set	pc,  lnk
rdEPn:	@ BUlk OUT EP post-read processing
	set	rvb, #0
	usbstr	rvb, rva, usb_ibulkout	@ clear OUT_PKT_RDY bit in OUT_CSR2_REG
	set	pc,  lnk

_func_
wrtEPU:	@ clear EP rcv interrupt then write data to Bulk In Endpoint
	@ (write cnt bytes starting at dts to enpoint in env)
wrtEP:	@ write data to Control IN or Bulk IN EP
	@ on entry:	cnt <- number of bytes to write
	@ on entry:	dts <- start address of data in buffer
	@ on entry:	env <- EP to write to
	set	sv5, lnk		  @ sv5 <- lnk, saved
	bl	usbhwSelectEP		  @ rva <- usb_base, selct EP in INDEX_REG
	bl	usbhwWriteBuf2EP	  @ write from buffer to IN EP
	set	lnk, sv5		  @ lnk <- lnk, restored
	cmp	env, #2			  @ writing to control EP?
	bpl	wrtEPn			  @	if not, jump to process Bulk EP
	@ EP0 post-write processing
	ldr	rvb, =USB_CHUNK
	ldr	rvb, [rvb]		  @ rvb <- how many bytes remain to be sent
	eq	rvb, #0			  @ more bytes to send after this?
	itE	eq
	seteq	rvb, #0x0a		  @ 	if not, rvb <- PKT_RDY + DATAEND
	setne	rvb, #0x02		  @	if so,  rvb <- IN_PKT_RDY
	usbstr	rvb, rva, usb_ctl_stat	@ update EP0_CSR
	beq	usbSOx			  @	if not, goto Stat OUT (last pkt)
	set	pc,  lnk		  @ return

wrtEPn:	@ Bulk IN post-write processing
	usbldr	rvb, rva, usb_ibulkin	@ rvb <- TxCSLR3
	tst	rvb, #usb_txrdy		 @ EP ready to send?
	it	ne
	setne	pc,  lnk		 @ 	if so,  return
	set	rvb, #usb_txrdy		 @ rvb <- IN_PKT_RDY bit
	usbstr	rvb, rva, usb_ibulkin	@ set PKT_RDY bit in TXCSR
	b	wrtEPn		 	 @ jump to wait for EP TxRdy

/* helper functions */

_func_
usbhwSelectEP: @ select EP in INDEX_REG
	@ on entry:	env <- EP to select
	@ on exit:	rva <- usb base address
	@ modifies:	rva, rvb
	ldr	rva, =usb_base		   @ rva <- usb_base
  .ifdef usb_index_reg
	strb	env, [rva, #usb_index_reg] @ select endpoint in INDEX_REG
usbslw:	ldrb	rvb, [rva, #usb_index_reg] @ rvb <- selected EP
	eq	rvb, env		   @ is it the desired EP?
	bne	usbslw			   @	if not, jump back to wait
  .endif
	set	pc,  lnk		   @ return

_func_
usbhwReadEP2Buf: @ read from OUT EP into buffer
	@ on entry:	env <- EP to read from (selected already)
	@ on entry:	rva <- usb base address
	@ on exit:	cnt <- number of bytes read
	@ modifies:	rvb, rvc, cnt
  .ifdef usb_index_reg
	ldrh	cnt, [rva, #usb_rcvd_cnt] @ cnt <- byte count from OUT_FIFO_CNT1_REG
  .else
	eq	env, #0
	itE	eq
	ldrbeq	cnt, [rva, #0x108]	@ cnt <- byte count for EP0 Rx FIFO
	ldrhne	cnt, [rva, #0x128]	@ cnt <- byte count for EP2 Rx FIFO	
  .endif
	add	rva, rva, #0x20		@ rva <- address of base of EP FIFOs
	set	rvb, #0
usbrwr:	@ read words
	sub	rvc, cnt, rvb
	cmp	rvc, #4
	bmi	usbrbt
	cmp	rvb, cnt
	bpl	usbrbt
	ldr	rvc, [rva, env, lsl #2]	@ rvc <- data word from EPn_FIFO
	str	rvc, [dts, rvb]		@ store it in buffer
	add	rvb, rvb, #4
	b	usbrwr
usbrbt:	@ read bytes
	eq	rvb, cnt
	itTT	ne
	ldrbne	rvc, [rva, env, lsl #2]	@ rvc <- data byte from EPn_FIFO
	strbne	rvc, [dts, rvb]		@ store it in buffer
	addne	rvb, rvb, #1
	bne	usbrbt
	ldr	rva, =usb_base
	set	pc,  lnk

_func_
usbhwWriteBuf2EP: @ write from buffer to IN EP
	@ on entry:	rva <- usb_base
	@ on entry:	env <- IN EP to write to
	@ on entry:	dts <- buffer
	@ on entry:	cnt <- number of bytes to send
	@ modifies:	rvb, rvc
	eq	env, #0
	itE	eq
	seteq	rvb, #0
	setne	rvb, #usb_txrdy
usbwwt:	usbldr	rvc, rva, usb_ibulkin
	tst	rvc, rvb
	bne	usbwwt
	add	rva, rva, #0x20		@ rva <- address of base of EP FIFOs
	set	rvb, #0
usbwwr:	@ write words
	sub	rvc, cnt, rvb
	cmp	rvc, #4
	bmi	usbwbt
	cmp	rvb, cnt
	bpl	usbwbt
	ldr	rvc, [dts, rvb]		@ rvc <- data from buffer
	str	rvc, [rva, env, lsl #2]	@ store it in EPn_FIFO
	add	rvb, rvb, #4
	b	usbwwr
usbwbt:	@ write bytes
	eq	rvb, cnt
	itTT	ne
	ldrbne	rvc, [dts, rvb]		@ rvc <- data from buffer
	strbne	rvc, [rva, env, lsl #2]	@ store it in EPn_FIFO
	addne	rvb, rvb, #1
	bne	usbwbt
	ldr	rva, =usb_base
	set	pc,  lnk

/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

_func_
usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base
  .ifdef usb_index_reg
	set	rvc, #UsbBulkInEP
	strb	rvc, [rva, #usb_index_reg] @ select endpoint in INDEX_REG
usbwcw:	ldrb	rvc, [rva, #usb_index_reg] @ rvc <- selected EP from INDEX_REG
	eq	rvc, #UsbBulkInEP	   @ correct endpoint selected?
	bne	usbwcw			   @	if not, jump back to re-select
  .endif
usbwcl:	@ check for TxRdy or set-and-wait on TxRdy
	usbldr	rvc, rva, usb_ibulkin	   @ rvc <- status from IN_CSR1_REG
	tst	rvc, #usb_txrdy		   @ is IN_PKT_RDY set (dev wtng 2 snd)?
	bne	usbwcx
	set	rvc, #usb_txrdy
	usbstr	rvc, rva, usb_ibulkin	   @ 	if not, set IN_PKT_RDY in TXCSR
	b	usbwcl
usbwcx:	@ return
	swi	run_normal		   @ enable interrupts (user mode)
	set	pc,  lnk		   @ return




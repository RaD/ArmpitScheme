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

usbhwgetDevEPint: @ special interrupt entry processing for this MCU
	@ on entry:	rva <- USB base address
	@ on exit:	sv1 <- interrupt status w/r EP and/or Device
	ldr	sv1, [rva, #usb_istat_dv]
	tst	sv1, #usb_iep_mask	@ is this an Enpoint (Slow) Interrupt?	
	setne	sv3, #usbCO_setupbit
	bne	usbCOi			@	if so, jump to process it
	tst	sv1, #usb_idv_mask	@ is this a Device Status Interrupt?
	bne	usbDSi			@	if so, jump to process it
	b	usbEPi			@ jump to process an enpoint interrupt

usbhwDeviceStatus: @ return device status in rvb
	set	rvb, sv1
	set	pc,  lnk

usbhwReset:
	ldr	rvb, =0x8004107c
	ldr	env, =0xaa37
	str	env, [rvb]
	set	rvb, #0
	ldr	rva, =USB_FSHS_MODE
	str	rvb, [rva]		@ indicate that USB is not in HS mode
	ldr	rva, =usb_base
	set	env, #0x20		@ rvb <- 0x20
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP 0 SETUP
	set	env, #0x08
	str	env, [rva, #usb_reep]	@ USB EP  Type  <- control, enabled
	set	env, #0x00		@ rvb <- 0x00
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP 0 SETUP
	set	env, #0x08
	str	env, [rva, #usb_reep]	@ USB EP  Type  <- control, enabled
	set	env, #0x01		@ rvb <- 0x20
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP 0 SETUP
	set	env, #0x08
	str	env, [rva, #usb_reep]	@ USB EP  Type  <- control, enabled
	set	rvb, #0x54		@ rvb <- 0x54 = ACK,STALL NYET,some NAK
	str	rvb, [rva, #0x10]	@ USB Int cfg <- ACK,STALL NYET,some NAK
	set	rvb, #0xb9		@ rvb <- 0xb9
	str	rvb, [rva, #0x8c]	@ USB Dev Int Enab <- rst,susp,rsm,setup
	set	rvb, #0x03		@ rvb <- 0x03
	str	rvb, [rva, #0x90]	@ USB EP  Int Enable  <- EP 0 Rx and Tx
	set	rvb, #0x80		@ rvb <- 0x80
	str	rvb, [rva]		@ USB Device Address <- 0,device enabled
	set	pc,  lnk

usbhwRemoteWakeUp:
	@ process change to HS, suspend, resume (do nothing on suspend/resume)
.ifdef has_HS_USB
	tst	rvb, #0x20		@ is it a FS to HS interrupt?
	seteq	pc,  lnk		@	if not, return
	set	rvb, #1
	ldr	rva, =USB_FSHS_MODE
	str	rvb, [rva]		@ indic that USB has switched to HS mode
.endif
	set	pc,  lnk
	
/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

usbhwEndpointStatus: @ return endpoint status in r3
	ldr	rva, =usb_base
	ldr	sv2, [rva, #usb_istat_ep]  @ sv2 <- Endpoint Interrupt Status
	str	sv2, [rva, #usb_iclear_ep] @ clear the interrupt
	set	sv3, #0			   @ sv3 <- 0 (setup treated at isr top)
	set	pc,  lnk

/* BULK IN Enpoint Interrupt Response */


/* BULK OUT Enpoint Interrupt Response */

_func_
usbhwBOw: @ initiate input data echo (if needed)
	@ modifies:	rva, rvb
	@ returns via:	lnk
	b	usbBIi			@ jump to write OUT data to IN EP

/* CONTROL IN Enpoint Interrupt Response */


/* CONTROL OUT Enpoint Interrupt Response */

usbhwSetup: @ Control OUT Interrupt, Setup Phase
	@ dts <- buffer
	set	env, #0x20		@ rvb <- EP 0 Setup is EP to read from
	ldr	rva, =usb_base
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP in env
	ldr	cnt, [rva, #usb_rxplen]	@ cnt <- number of bytes to read
	ldr	rvb, =0x3FF		@ rvb <- mask to get number of bytes
	and	cnt, cnt, rvb		@ cnt <- number of bytes to read
	ldr	rvb, [rva, #usb_rxdata]	@	if not, rvb <- next word read
	str	rvb, [dts]		@	if not, store next word in bfr
	ldr	rvb, [rva, #usb_rxdata]	@	if not, rvb <- next word read
	str	rvb, [dts, #4]		@	if not, store next word in bfr
	ldr	rvb, [dts, #4]
	lsr	rvb, rvb, #16
	eq	rvb, #0
	seteq	env, #UsbControlInEP	@ env  <- Control IN EndPoint
	streq	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP in env
	seteq	rvb, #2			@	if so,  rvb <- 4
	streq	rvb, [rva, #usb_ctrl]	@	if so,  USBECtrl <- Stat IN Phs
	seteq	pc,  lnk
	ldr	rvb, [dts]
	tst	rvb, #0x80
	seteq	env, #UsbControlOutEP	@	if so,  env  <- Control OUT EP
	setne	env, #UsbControlInEP	@	if not, env  <- Control IN  EP
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP in env
	ldr	rvb, [rva, #usb_ctrl]	@ rvb <- contents of USBECtrl
	orr	rvb, rvb, #4		@ rvb <- USBEctrl | 4 to init DATA phase
	str	rvb, [rva, #usb_ctrl]	@ set USBECtrl to initiate DATA phase
	set	pc,  lnk		@ return

usbhwDGD: @ get Descriptor of Device
	bl	wrtEP
	b	usbSOx
	
usbhwEGS: @ Get Status of Endpoint in sv5 into rvb
	set	sv4, lnk
	bl	usbhwEPSet		@ rva <- usb_base, rvb <- EP cntrl dat
	tst	rvb, #0x01		@ is the selected endpoint stalled?
	seteq	rvb, #0			@	if not, rvb <- 0 -- not stalled
	setne	rvb, #1			@	if so,  rvb <- 1 -- stalled
	set	pc,  sv4

usbhwSetAddress: @ Set Device to Address in rvb
	ldr	rva, =USB_SETUP_BUFFER	@ rva <- address of setup buffer
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	lsr	rvb, rvb, #16		@ rvb <- address = val(16)
	orr	rvb, rvb, #0x80		@ rvb <- adrs ored with Dev Enab (0x80)
	ldr	rva, =usb_base
	str	rvb, [rva, #usb_dev_adr]
	b	usbSIx			@ jump to Status IN Phase and exit

usbhwConfigure: @ Configure the device
	set	sv4, lnk
	@ stop uart from generating Rx interrupts (noise on shared READBUFFER)
	ldr	rva, =uart0_base
	set	rvb, #0
	str	rvb, [rva, #uart_ier]	@ U0IER <- disable UART0 RDA interrupt
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ de-realize target endpoints
	ldr	rva, =usb_base
	ldr	sv5, =0x05040302	@ sv5 <- EP realize: 2<-0,3<-0,4<-0,5<-0
	bl	usbhwReEPs		@ de-realize EPs
	@ Realize the Interrupt Out Endpoint (phys 2, log 1, aka 0x01)
	set	rvb, #0x02		@ rvb <- EP phys number = 2
	str	rvb, [rva, #usb_epind]	@ Load EP idx Reg with physical EP num
	set	rvb, #8			@ rvb <- max packet size = 8
	str	rvb, [rva, #usb_maxpsize]	@ set the max packet size
	@ Realize the Interrupt In Endpoint (phys 3, log 1, aka 0x81)
	set	rvb, #0x03		@ rvb <- EP phys number = 3
	str	rvb, [rva, #usb_epind]	@ Load EP idx Reg with physical EP num
	set	rvb, #8			@ rvb <- max packet size = 8
	str	rvb, [rva, #usb_maxpsize]	@ set the max packet size
	@ Realize the BULK OUT Endpoint (phys 4, log 2, aka 0x02)
	set	rvb, #0x04		@ rvb <- EP phys number = 4
	str	rvb, [rva, #usb_epind]	@ Load EP idx Reg with physical EP num
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	seteq	rvb, #64
	setne	rvb, #512
	str	rvb, [rva, #usb_maxpsize] @ load the max packet size Register
	@ Realize the BULK IN Endpoint (phys 5, log 2, aka 0x02)
	set	rvb, #0x05		@ rvb <- EP phys number = 5
	str	rvb, [rva, #usb_epind]	@ Load EP idx Reg with physical EP num
	ldr	rvb, =USB_FSHS_MODE
	ldr	rvb, [rvb]
	eq	rvb, #0
	seteq	rvb, #64
	setne	rvb, #512
	str	rvb, [rva, #usb_maxpsize] @ load the max packet size Register
	@ Realize the Interrupt Out Endpoint (phys 2, log 1, aka 0x01)
	@ Realize the Interrupt In Endpoint (phys 3, log 1, aka 0x81)
	@ Realize the BULK OUT Endpoint (phys 4, log 2, aka 0x02)
	@ Realize the BULK IN Endpoint (phys 5, log 2, aka 0x02)
	ldr	sv5, =0xa5a4b3b2	@ sv5 <- realize:2<x0B,3<x0B,4<x0A,5<x0A
	bl	usbhwReEPs		@ realize EPs
	@ enable interrupts for physical EP 3, 4 and 5 (EP 2 is not used)
	set	rvb, #0x44		@ rvb <- 0x44=ACKSTALLNYET/ACK/ACKSTALL
	str	rvb, [rva, #0x10]	@ USB Int config <- int on above choices
	set	rvb, #0x3B		@ rvb <- 0x3B
	str	rvb, [rva, #0x90]	@ EP Int Enab <- EP0,1,4,5 Rx,Tx,EP3 Tx
	@ set default i/o port to usb
	ldr	rvb, =vusb
	vcsti	glv, 4, rvb		@ default in/output port model
	set	pc,  sv4

usbhwDeconfigure: @ Deconfigure the device
	set	sv4, lnk
	@ enable interrupts for physical EP 0 only (disab those for EP 3,4,5)
	ldr	rva, =usb_base
	set	rvb, #0x03		@ rvb <- 0x03
	str	rvb, [rva, #0x90]	@ USB EP  Int Enab <- EP 0 Rx, Tx only
	@ de-realize target endpoints
	ldr	sv5, =0x05040302	@ sv5 <- EP realize: 2<-0,3<-0,4<-0,5<-0
	bl	usbhwReEPs		@ jump to de-realize EPs
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
	vcsti	glv, 4, rvb		@ default in/output port model
	set	pc,  sv4

usbhwReEPs: @ realize/de-realize EPs
	@ on entry:	rva <- usb_base
	@ on entry:	sv5 <- EPs and cfg vals, eg. #xv5v4v3v2 (4-bit per EP)
	and	rvb, sv5, #0x0F
	str	rvb, [rva, #usb_epind]	@ Load EP idx Reg with physical EP num
	lsr	sv5, sv5, #4
	and	rvb, sv5, #0x0F
	str	rvb, [rva, #usb_reep]	@ set EP type to 0, no type, disabled
	lsrs	sv5, sv5, #4
	bne	usbhwReEPs
	set	pc,  lnk

/* Status IN/OUT responses */

usbhwStatusOut:	@ Control OUT Interrupt, Status OUT Phase
	b	usbEPx

usbSOx:	@ Prepare setup buffer for Status OUT Phase 
	b	usbEPx

/* Enpoint stalling, unstalling */

usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80)
	set	rvb, #0x01
	ldr	rva, =usb_base
	str	rvb, [rva, #usb_epind]	@ USB EP INDEX <- select EP to stall
	ldr	rvb, [rva, #usb_ctrl]
	orr	rvb, rvb, #0x01
	str	rvb, [rva, #usb_ctrl]
	b	usbEPx

usbhwStallEP: @ Stall EP in sv5
	set	sv4, lnk
	bl	usbhwEPSet		@ rva <- usb_base, rvb <- EP control dat
	orr	rvb, rvb, #0x01
	str	rvb, [rva, #usb_ctrl]
	set	pc,  sv4

usbhwUnstallEP:	@ Unstall the EndPoint in sv5
	set	sv4, lnk
	bl	usbhwEPSet		@ rva <- usb_base, rvb <- EP control dat
	bic	rvb, rvb, #0x01
	str	rvb, [rva, #usb_ctrl]
	set	pc,  sv4

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write and helper functions

------------------------------------------------------------------------------*/

rdEP:	@ uses sv5, rva, rvb, env, dts, cnt, returns cnt = count
	@ env <- EPNum, dts <- buffer
	ldr	rva, =usb_base
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP in env
	eq	env, #UsbControlOutEP	@ were we reading from  EP 0 SETUP EP?
	ldreq	rvb, [rva, #usb_ctrl]	@	if so,  rvb <- USBECtrl
	orreq	rvb, rvb, #4
	streq	rvb, [rva, #usb_ctrl]	@	if so,  USBECtrl <-init DATA phs
	ldr	cnt, [rva, #usb_rxplen]	@ r11 <- num bytes to read
	ldr	rvb, =0x3FF		@ rvb <- mask to get number of bytes
	and	cnt, cnt, rvb		@ r11 <- number of bytes to read
	add	sv5, cnt, #3		@ r5  <- number of bytes to read + 3
	lsr	sv5, sv5, #2		@ r5  <- number of words to read
	@ read data
rdEP_1:	eq	sv5, #0			@ done reading?
	ldrne	rvb, [rva, #usb_rxdata]	@	if not, rvb <- next word read
	strne	rvb, [dts]		@	if not, store next word in bfr
	addne	dts, dts, #4		@	if not, r10 <- updtd storg adrs
	subne	sv5, sv5, #1		@	if not, r5  <- upd num wrd to rd
	bne	rdEP_1			@	if not, jump to keep reading
	@ return
	set	pc,  lnk		@ return

	
wrtEP:	@ uses sv5, rva, rvb, env, dts, cnt
	@ env <- EPNum, dts <- buffer, cnt <- cnt
	@ set endpoint to use in control register
	ldr	rva, =usb_base
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP in env
	eq	env, #UsbControlInEP	@ writing to EP0 Control IN EndPoint?
	bne	wrtEPq			@	if not, jump to continue
	ldr	rvb, [rva, #usb_ctrl]	@ rvb <- USBECtrl
	tst	rvb, #0x02		@ going to status out phase (data done)?
	eqeq	cnt, #0			@	if so, are we writing 0 bytes?
	beq	wrtEPS			@	if so,  jump to Status OUT
	tst	rvb, #0x02		@ data phase not done?
	orreq	rvb, rvb, #4		@	if so,  yes, we're done
	streq	rvb, [rva, #usb_ctrl]	@	if so,  USBECtrl <- Stat IN phas
wrtEPq:	@ continue/wait
	tst	env, #0x0E		@ writing to EP0?
	beq	wrtEP0			@	if so,  skip bufr rdy chk
	ldr	rvb, [rva, #usb_ctrl]
	tst	rvb, #0x20		@ is buffer ready (not full)?
	bne	wrtEPq			@	if not, jump back to wait
wrtEP0:	@ keep going
	str	cnt, [rva, #usb_txplen]	@ set number of bytes to write
	add	sv5, cnt, #3		@ sv5  <- number of bytes to write + 3
	lsr	sv5, sv5, #2		@ sv5  <- number of words to write
	@ write data
wrtEP1:	eq	sv5, #0
	it	eq
	seteq	pc,  lnk		@ return
	ldrb	rvb, [dts]
	ldrb	cnt, [dts, #1]
	orr	rvb, rvb, cnt, lsl #8
	ldrb	cnt, [dts, #2]
	orr	rvb, rvb, cnt, lsl #16
	ldrb	cnt, [dts, #3]
	orr	rvb, rvb, cnt, lsl #24
	str	rvb, [rva, #usb_txdata]	@ write word to USB
	add	dts, dts, #4
	sub	sv5, sv5, #1		@ sv5  <- how many words remain to wrt?
	b	wrtEP1

wrtEPS:	@ get ready for status OUT phase
	set	env, #UsbControlOutEP	@ env <- control OUT EP
	str	env, [rva, #usb_epind]	@ USB EP  INDEX <- select EP in env
	set	rvb, #2
	str	rvb, [rva, #usb_ctrl]	@ USBECtrl <- initiate Status phase
	set	rvb, #0xff
	ldr	rva, =USB_SETUP_BUFFER
	str	rvb, [rva]		@ rvb  <- reqtyp(8), request(8), val(16)
	ldr	rva, =usb_base
	set	pc,  lnk		@ return	

wrtEPU:	@ (eg. section 9.14)
	@ env <- EPNum, dts <- buffer, cnt <- count
	set	sv4, lnk
	bl	wrtEP
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt
	set	pc,  sv4

/* helper functions */

usbhwEPSet: @ get control data for EP in sv5
	@ on entry:	sv5 <- EP
	@ on exit:	rva <- usb_base
	@ on exit:	rvb <- EP control data
	and	rvb, sv5, #0x0F		@ rvb <- EP logical number
	lsl	rvb, rvb, #1		@ rvb <- EP physical number (if even)
	tst	sv5, #0x80
	addne	rvb, rvb, #1		@ rvb <- EP physical index
	ldr	rva, =usb_base
	str	rvb, [rva, #usb_epind]	@ USB EP INDEX <- select EP
	ldr	rvb, [rva, #usb_ctrl]
	set	pc,  lnk


/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

_func_
usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base
	set	rvc, #UsbBulkInEP
	str	rvc, [rva, #usb_epind]	@ USB EP  INDEX <- select EP 5
	ldr	rvc, [rva, #usb_ctrl]
	tst	rvc, #usb_txrdy		@ is buffer ready (not full)?
	itT	eq
	seteq	rvc, #usbBI_ibit	@ 	if not, rvc <- EP2 Tx Int bit
	streq	rvc, [rva, #usb_iset_ep] @ 	if not, USBEPIntSet <- Bulk IN
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return





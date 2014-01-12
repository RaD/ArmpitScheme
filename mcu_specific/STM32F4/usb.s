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
	set	rvb, sv1		@ rvb <- Device Interrupt Status
	set	pc,  lnk

_func_
usbhwReset:
	ldr	rva, =usb_base		@ rva <- USB base address
	set	rvb, #0x400000
	orr	rvb, rvb, #0x40
	str	rvb, [rva, #0x24]	@ GRXFSIZ  <- 64w Rx FIFO
	add	rvb, rvb, #0x40
	str	rvb, [rva, #0x28]	@ DIEPTXF0 <- 64w EP0 Tx FIFO, start= 64
	add	rva, rva, #0x0100	@ rva <- USB IN FIFO regs base address
	add	rvb, rvb, #0x40
	str	rvb, [rva, #0x04]	@ DIEPTXF1 <- 64w FIFO 1, start = 128
	add	rvb, rvb, #0x40
	str	rvb, [rva, #0x08]	@ DIEPTXF2 <- 64w FIFO 2, start = 192
	add	rvb, rvb, #0x40
	str	rvb, [rva, #0x0c]	@ DIEPTXF3 <- 64w FIFO 3, start = 256
	add	rvb, rvb, #0x40
	str	rvb, [rva, #0x00]	@ HPTXFSIZ <- 64w Host FIFO,start=256+64
	sub	rva, rva, #0x0100	@ rva <- USB base address (restored)
	set	rvb, #0x0420
	str	rvb, [rva, #0x10]	@ GRSTCTL <- flush all Tx Fifos
ushw_y:	ldr	rvb, [rva, #0x10]
	tst	rvb, #(1 << 31)		@ FIFOs flushed?
	beq	ushw_y			@	if not, jump back to wait
	set	rvb, #0x0010
	str	rvb, [rva, #0x10]	@ GRSTCTL <- flush Rx Fifo
ushw_x:	ldr	rvb, [rva, #0x10]
	tst	rvb, #(1 << 31)		@ FIFO flushed?
	beq	ushw_x			@	if not, jump back to wait
	tst	rvb, #0x10		@ FIFO flushed (test 2)?
	bne	ushw_x			@	if not, jump back to wait
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	ldr	rvb, [rva]		@ rvb <- DCFG
	bic	rvb, rvb, #0x07f0
	orr	rvb, rvb, #0x0003
	str	rvb, [rva]		@ DCFG     <- Dev mod full spd, addrss 0
	set	rvb, #0
	str	rvb, [rva, #0x34]	@ DIEPEMPMSK <- mask TxFIfo empty ints
	set	rvb, #0x01
	str	rvb, [rva, #0x1c]	@ DAINTMSK <- unmask EP0 IN ints
	set	rvb, #0x00
	str	rvb, [rva, #0x10]	@ DIEPMSK  <- mask global EP IN ints
	set	rvb, #0x00
	str	rvb, [rva, #0x14]	@ DOEPMSK  <- mask global EP OUT ints
	set	rvb, #(1 << 29)
	orr	rvb, rvb, #(1 << 19)
	orr	rvb, rvb, #8	
	str	rvb, [rva, #0x0310]	@ DOEPTSIZ0 <- EP0 OUT up to 3 setup pkt
	set	rvb, #0x03
	orr	rvb, rvb, #(1 << 31)
	orr	rvb, rvb, #(1 << 27)	@ nak until loaded	
	str	rvb, [rva, #0x0100]	@ DIEPCTL0  <- EP0 IN 8 byte packet size
	set	rvb, #3
	orr	rvb, rvb, #(1 << 31)
	orr	rvb, rvb, #(1 << 26)	@ rvb <- clear NAK generation
	str	rvb, [rva, #0x0300]	@ DOEPCTL0  <- enable EP0 OUT for Rx
	set	pc,  lnk

_func_
usbhwRemoteWakeUp: @ suspend/wakeup
	set	pc,  lnk

/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

_func_
usbhwEndpointStatus: @ get status of EP into sv2 and sv3 (sv1 is device interrupt from usb_istr)
	@ on entry:	sv1 <- GINTSTS
	@ on exit:	sv2 <- DAINT
	@ on exit:	sv3 <- DIEPINTx / DOEPINTx
	@ side-effect:	clears EP interrupt
	@ modifies:	rva, rvb, sv2, sv3
	tst	sv1, #0x1000		@ is interrupt a reset, mixed w/EP ints?
	bne	usbDSi			@	if so,  jump back to dev int
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	ldr	sv2, [rva, #0x18]	@ sv2 <- DAINT (EP interrupts)
	ldr	rvb, [rva, #0x1c]	@ rvb <- DAINTMSK (allowed EP ints)
	and	sv2, sv2, rvb		@ sv2 <- allowed, active EP ints
	eq	sv2, #0			@ any DAINT signalled?
	beq	usbhwEPstd		@	if not, jump to Bulk Rx or Ctrl
	ldr	rvb, [rva, #0x08]	@ rvb <- DSTS (must read on DAINT int)
	add	rva, rva, #0x0100	@ rva <- USB base address + 0x900
	tst	sv2, #usbCO_ibit	@ is interrupt for Control OUT EP 0?
	it	ne
	addne	rva, rva, #0x0200	@ 	if so,  rva <- USB base + 0xb00
	bne	usbhwEPstc		@	if so,  jump to finish up
	tst	sv2, #usbBO_ibit	@ is interrupt for Bulk Out EP 2?
	it	ne
	addne	rva, rva, #0x0240	@ 	if so,  rva <- USB base + 0xb40
	bne	usbhwEPstc		@	if so,  jump to finish up
	tst	sv2, #usbBI_ibit	@ is interrupt for Bulk IN EP 3?
	it	ne
	addne	rva, rva, #0x60		@ 	if so,  rva <- USB base + 0x960
usbhwEPstc:
	ldr	sv3, [rva, #0x08]	@ sv3 <- DIEPINTx/DOEPINTx EP int stat
	str	sv3, [rva, #0x08]	@ clear EP int
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	set	rvc, #0
	str	rvc, [rva, #0x10]	@ DIEPMSK <- re-mask all EP IN ints
	set	pc,  lnk

usbhwEPstd: @ non-DAINT Bulk Rx or Control Rx/Tx interrupt
	ldr	rva, =usb_base		@ rva <- USB base address
	ldr	rvb, [rva, #0x1c]	@ rvb <- GRXSTSR (peek Rx FIFO)
	tst	sv1, #0x10		@ is this a Rx interrupt (vs Tx)
	itE	eq
	addeq	rva, rva, #0x0900	@ 	if not, rva <- IN  EP base addrs
	addne	rva, rva, #0x0b00	@	if so,  rva <- OUT EP base addrs
	tst	rvb, #3			@ int is for control EP?
	itTEE	eq
	ldreq	sv2, [rva, #0x08]	@ 	if so,  sv2 <- DIEPINT0/DOEPINT0
	streq	sv2, [rva, #0x08]	@	if so,  clear control int
	ldrne	sv2, [rva, #0x48]	@ 	if not, sv2 <- DOEPINT2 Bulk OUT
	strne	sv2, [rva, #0x48]	@	if not, clear Bulk OUT int
	tst	sv1, #0x10		@ is this a Rx interrupt (vs Tx)
	bne	usbhwEPstdRx
	b	usbEPx			@ exit on Control IN int

usbhwEPstdRx: @ non-DAINT Control OUT or Bulk OUT interrupt
	tst	rvb, #0x0f		@ EP0 ?
	itE	eq
	seteq	sv2, #usbCO_ibit	@	if so,  sv2 <- Ctrl OUT indic
	setne	sv2, #usbBO_ibit	@	if not, sv2 <- Bulk OUT indic
	lsr	rvb, rvb, #17		@ rvb <- packet info, shifted
	and	rvb, rvb, #0x0f		@ rvb <- packet info, masked
	set	sv3, #0			@ sv3 <- 0 (non-SETUP packet indicator)
	eq	rvb, #0x06		@ SETUP received?
	itE	eq
	seteq	sv3, #usbCO_setupbit	@	if so,  sv3 <- set SETUP bit
	eqne	rvb, #0x02		@ 	if not, OUT packet received?
	it	eq
	seteq	pc,  lnk		@	if so,  return for normal proc
	@ other (global OUT NAK, OUT complete, SETUP complete, reserved)
	set	sv2, #0			@ sv2 <- 0 (cleared, nothing to do)
	ldr	rva, =usb_base		@ rva <- USB base address
	ldr	rvb, [rva, #0x20]	@ rvb <- GRXSTSP (pop Rx FIFO)
	set	pc,  lnk		@ return for isr EP exit

/* BULK IN Enpoint Interrupt Response */


/* BULK OUT Enpoint Interrupt Response */

_func_
usbhwBOw: @ initiate input data echo (if needed)
	@ modifies:	rva, rvb
	@ returns via:	lnk
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	ldr	rvc, [rva, #0x10]	@ rvc <- DIEPMSK
	orr	rvc, rvc, #0x01		@ rvc <- DIEPMSK + bit for TxComp
	str	rvc, [rva, #0x10]	@ DIEPMSK <- unmask TxComp int
	add	rva, rva, #0x0100	@ rva <- IN EP regs base address
	ldr	rvc, [rva, #0x60]	@ rvc <- DIEPCTL3
	tst	rvc, #(1 << 31)		@ is EP enabled (waiting to send)?
	it	ne
	setne	pc,  lnk		@	if so,  return	
	set	rvc, #(1 << 19)
	str	rvc, [rva, #0x70]	@ DIEPTSIZ3 <- zero bytes to snd for pkt
	ldr	rvc, [rva, #0x60]	@ rvc <- DIEPCTL3
	orr	rvc, rvc, #(1 << 15)	@ rvc <- EP active bit
	orr	rvc, rvc, #(1 << 31)	@ rvc <- enable EP bit
	orr	rvc, rvc, #(1 << 26)	@ rvc <- clear NAK generation
	str	rvc, [rva, #0x60]	@ DIEPCTL3  <- enable EP for transmission
	set	pc,  lnk		@ return

/* CONTROL IN Enpoint Interrupt Response */


/* CONTROL OUT Enpoint Interrupt Response */

_func_
usbhwSetup: @ Control OUT Interrupt, Setup Phase
	set	sv3, lnk
	bl	rdEP
	set	lnk, sv3
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	set	rvb, #0xc00
	str	rvb, [rva, #4]		@ DCTL <- clr glbl OUT NAK, set prg done
	set	pc,  lnk		@ setup packet read in hwstatus above

_func_
usbhwDGD: @ 9.4.3 Get Descriptor of Device Standard request	
	bl	wrtEP
	b	usbSOx

_func_
usbhwEGS: @ Get stall Status of Endpoint in sv5 into rvb
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base		@ rva <- USB base address
	tst	sv5, #0x80		@ is this an OUT EP?
	itE	eq
	addeq	rva, rva, #0x0b00	@	if so,  rva <- OUT EP base addrs
	addne	rva, rva, #0x0900	@	if not, rva <- IN  EP base addrs
	add	rva, rva, rvb, LSL #5
	ldr	rvb, [rva]		@ rvb <- DIEPCTLx / DOEPCTLx
	tst	rvb, #(1 << 21)		@ is EP non-stalled
	itE	ne
	setne	rvb, #0			@	if not, rvb <- 0, stalled
	seteq	rvb, #1			@	if so,  rvb <- 1, not stalled
	set	pc,  lnk

_func_
usbhwSetAddress: @ Set Device to Address in sv5
	@ USB Status IN  exit -- write null packet to   EP 1 (phys, aka 0x80)
	@ disable the correct transfer interrupt mask (CTRM) in USB_CNTR	
	ldr	rva, =USB_SETUP_BUFFER	@ rva <- address of setup buffer
	ldr	sv5, [rva]		@ sv5 <- reqtyp(8), request(8), val(16)
	lsr	sv5, sv5, #16		@ sv5 <- address = val(16)
	lsl	sv5, sv5, #4
	ldr	rva, =usb_base		@ rva <- USB base address
	ldr	rvb, [rva, #usb_daddr]	@ rvb <- address reg content
	bic	rvb, rvb, #0x07f0
	orr	rvb, rvb, sv5
	str	rvb, [rva, #usb_daddr]	@ set address
	b	usbSIx

_func_
usbhwConfigure: @ Configure the device
	@ stop uart from generating Rx interrupts 
	@ (they cause noise on shared READBUFFER)
	ldr	rva, =uart0_base
	ldr	rvb, =0x200c
	str	rvb, [rva, #0x0c]	@ USART_CR1 <- Tx-Rx en,8N1,no Rx int
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ configure USB
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0900	@ rva <- IN EP regs base address
	ldr	rvb, = #((1 << 22) | (3 << 18) | (1 << 15) | 8)
	str	rvb, [rva, #0x20]	@ DIEPCTL1  <- FIFO 1,Int IN,act,8byts
	ldr	rvb, = #((2 << 22) | (2 << 18) | (1 << 15) | 64)
	str	rvb, [rva, #0x60]	@ DIEPCTL3  <- FIFO 3,Bulk IN,act,64byts
	add	rva, rva, #0x0200	@ rva <- OUT EP regs base address
	set	rvb, #64
	str	rvb, [rva, #0x50]	@ DOEPTSIZ2 <- EP2 pktsz=64byts,exp 1pkt
	ldr	rvb, = #((1 << 31) | (1 << 28) | (2 << 18) | (1 << 15) | 64)
	str	rvb, [rva, #0x40]	@ DOEPCTL2  <- EP2 Bulk OUT,activ,64byts
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	ldr	rvb, [rva, #0x1c]	@ rvb <- DAINTMSK
	orr	rvb, rvb, #0x040000
	orr	rvb, rvb, #0x0a
	str	rvb, [rva, #0x1c]	@ DAINTMSK <- unmask ints EP 1i,2o,3i
	ldr	rva, =usb_base		@ rva <- USB base address
	set	rvb, #0x00a0		@ TX2 FIFO flush bits
	str	rvb, [rva, #0x10]	@ GRSTCTL <- flush selected Tx Fifo(s)
	@ set default i/o port to usb
	ldr	rvb, =vusb		@ rvb <- USB port model
	vcsti	glv, 4, rvb		@ set default i/o port model to USB
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
	ldr	rvb, =0x202c
	str	rvb, [rva, #0x0c]	@ USART_CR1 <- Tx-Rx en,8N1,Rx int
	@ set default i/o port to uart
	ldr	rvb, =vuart0
	vcsti	glv, 4, rvb		@ set default i/o port model to uart
	set	pc,  lnk

/* Status IN/OUT responses */

_func_
usbhwStatusOut:	@ Control OUT Interrupt, Status OUT Phase
	set	env, #UsbControlOutEP	@ env <- Control OUT EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	set	cnt, #0			@ cnt <- 0 bytes to read
	bl	rdEP			@ read 0 bytes from EP
	b	usbEPx

_func_
usbSOx:	@ Prepare setup buffer for Status OUT Phase 
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, =0xFF
	str	rvb, [rva]
	b	usbEPx

/* Enpoint stalling, unstalling */

_func_
usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80) -- i.e. Control IN
	ldr	rva, =usb_base		@ rva <- USB base address
	ldr	rvb, [rva, #0x0900]	@ rvb <- DIEPCTL0
	orr	rvb, rvb, #(1 << 21)
	str	rvb, [rva, #0x0900]	@ send stall
	b	usbEPx

_func_
usbhwStallEP: @ Stall the EndPoint in sv5
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base		@ rva <- USB base address
	tst	sv5, #0x80		@ is this an OUT EP?
	itE	eq
	addeq	rva, rva, #0x0b00	@	if so,  rva <- OUT EP base addrs
	addne	rva, rva, #0x0900	@	if not, rva <- IN  EP base addrs
	add	rva, rva, rvb, LSL #5
	ldr	rvb, [rva]		@ rvb <- DIEPCTLx / DOEPCTLx
	orr	rvb, rvb, #(1 << 21)
	str	rvb, [rva]		@ stall EP
	set	pc,  lnk

_func_
usbhwUnstallEP:	@ Unstall the EndPoint in sv5, jump to Status IN
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base		@ rva <- USB base address
	tst	sv5, #0x80		@ is this an OUT EP?
	itE	eq
	addeq	rva, rva, #0x0b00	@ 	if so,  rva <- OUT EP base addrs
	addne	rva, rva, #0x0900	@ 	if not, rva <- IN  EP base addrs
	add	rva, rva, rvb, LSL #5
	ldr	rvb, [rva]		@ rvb <- DIEPCTLx / DOEPCTLx
	bic	rvb, rvb, #(1 << 21)
	str	rvb, [rva]		@ unstall EP
	set	pc,  lnk

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write and helper functions

------------------------------------------------------------------------------*/

_func_
rdEP:	@ read from endpoint in env to buffer in dts with count in cnt
	and	env, env, #0x0F
	ldr	rva, =usb_base		@ rva <- USB base address
	ldr	rvb, [rva, #0x20]	@ rvb <- GRXSTSP (pop Rx FIFO)
	lsr	cnt, rvb, #4
	and	cnt, cnt, #0xff		@ cnt <- received byte count (up to 256)
	set	rvb, #0			@ rvb <- initial offset in dest buffer
usbSEZ:	cmp	rvb, cnt		@ done getting data?
	bpl	usbSEX
	ldr	rvc, [rva, #0x20]	@ rvc <- word from Rx FIFO
	str	rvc, [dts, rvb]		@ store it in buffer
	add	rvb, rvb, #4		@ rvb <- updated destination offset
	b	usbSEZ
usbSEX:	ldr	rvb, [rva, #0x14]	@ rvb <- GINTSTS
	tst	rvb, #0x10
	it	ne
	ldrne	rvb, [rva, #0x20]	@ rvb <- GRXSTSP (pop Rx FIFO) -- clear
	bne	usbSEX
	add	rva, rva, #0x0b00	@ rva <- DOEPCTL0 EP0 OUT (base address)
	add	rva, rva, env, LSL #5	@ rva <- DOEPCTLx EP0 OUT (base address)
	eq	env, #0
	itTE	eq	
	seteq	rvb, #(1 << 29)
	orreq	rvb, rvb, #8
	setne	rvb, #64
	str	rvb, [rva, #0x10]	@ DOEPTSIZx <- num bytes to read for pkt
	eq	env, #0
	itEE	eq
	seteq	rvb, #3
	setne	rvb, #64
	orrne	rvb, rvb, #(2 << 18)
	orr	rvb, rvb, #(1 << 15)
	orr	rvb, rvb, #(1 << 31)
	orr	rvb, rvb, #(1 << 26)	@ rvb <- clear NAK generation
	str	rvb, [rva]		@ DOEPCTLx  <- enable EP for Rx
	set	pc,  lnk

_func_
wrtEP:	@ write data to Control In Endpoint (cnt bytes from dts to EP in env)
wrtEPU:	@ write data to Control In Endpoint (cnt bytes from dts to EP in env)
	and	env, env, #0x0F
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0900	@ rva <- IN EP regs base address
	add	rva, rva, env, LSL #5	@ rva <- DIEPCTLx address for EP
	eq	env, #0
	beq	wrtEw1
wrtEw0:	ldr	rvb, [rva] 		@ rvb <- DIEPCTLx
	tst	rvb, #(1 << 31)		@ EP active?
	bne	wrtEw0
wrtEw1:	set	rvb, #(1 << 19)
	orr	rvb, rvb, cnt
	str	rvb, [rva, #0x10]	@ DIEPTSIZx <- num bytes for pkt
	ldr	rvb, [rva, #0x08]	@ rvb <- DIEPINTx
	orr	rvb, rvb, #1
	str	rvb, [rva, #0x08]	@ DIEPINTx  <- clear Tx interrupt on EP
	ldr	rvb, [rva]		@ rvb <- DIEPCTLx
	orr	rvb, rvb, #(1 << 15)	@ rvb <- EP active bit
	orr	rvb, rvb, #(1 << 31)	@ rvb <- enable EP bit
	orr	rvb, rvb, #(1 << 26)	@ rvb <- clear NAK generation
	str	rvb, [rva]		@ DIEPCTLx  <- enable EP for Tx
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x1000	@ rva <- address of EP0 FIFO
	add	rva, rva, env, lsl #12	@ rva <- address of EPx FIFO
	set	rvb, #0
wrtEPX:	cmp	rvb, cnt
	bpl	wrtEPY
	ldr	rvc, [dts, rvb]
	str	rvc, [rva]
	add	rvb, rvb, #4
	b	wrtEPX
wrtEPY:	eq	env, #0
	it	ne
	setne	pc,  lnk
	@ EP0
	eq	cnt, #0
	it	eq
	seteq	pc,  lnk
	ldr	rva, =USB_CHUNK
	ldr	rvb, [rva]		@ rvb <- how many bytes remain to send
	eq	rvb, #0			@ end of transfer?
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	ldr	rvb, [rva, #0x34]	@ rvb <- DIEPEMPMSK
	itE	eq
	biceq	rvb, rvb, #1		@ 	if so,  rvb <- mask   EP0 bit
	orrne	rvb, rvb, #1		@	if not, rvb <- unmask EP0 bit
	str	rvb, [rva, #0x34]	@ DIEPEMPMSK <- un/mask EP0 Tx empty int
	set	pc,  lnk

/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

_func_
usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0800	@ rva <- USB device regs base address
	ldr	rvc, [rva, #0x10]	@ rvc <- DIEPMSK
	orr	rvc, rvc, #0x01		@ rvc <- DIEPMSK + bit for TxComp
	str	rvc, [rva, #0x10]	@ DIEPMSK <- unmask TxComp int
	ldr	rva, =usb_base		@ rva <- USB base address
	add	rva, rva, #0x0900	@ rva <- IN EP regs base address
	ldr	rvc, [rva, #0x60]	@ rvc <- DIEPCTL3
	tst	rvc, #(1 << 31)		@ is EP enabled (waiting to send)?
	bne	usbhwrcxt		@	if so,  jump to return
	set	rvc, #(1 << 19)
	str	rvc, [rva, #0x70]	@ DIEPTSIZ3 <- zero bytes to snd for pkt
	ldr	rvc, [rva, #0x60]	@ rvc <- DIEPCTL3
	orr	rvc, rvc, #(1 << 15)	@ rvc <- EP active bit
	orr	rvc, rvc, #(1 << 31)	@ rvc <- enable EP bit
	orr	rvc, rvc, #(1 << 26)	@ rvc <- clear NAK generation
	str	rvc, [rva, #0x60]	@ DIEPCTL3  <- enable EP for transmission
usbhwrcxt: @ finish-up
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return




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
	set	rvb, sv1		@ rvb <- Device Interrupt Status
	set	pc,  lnk

usbhwReset:
	ldr	rva, =usb_base
	ldr	rvb, [rva]
	eor	rvb, rvb, #0x3000
	eor	rvb, rvb, #0x0030
	bic	rvb, rvb, #0xC000
	bic	rvb, rvb, #0x00C0
	orr	rvb, rvb, #0x0200
	str	rvb, [rva]		@ USB_EP0R <- enable EP 0 as control EP
	set	rvb, #0x80		@ rvb <- bit to enable USB at address 0
	str	rvb, [rva, #usb_daddr]
	set	pc,  lnk

usbhwRemoteWakeUp: @ suspend/wakeup
	ldr	rva, =usb_base
	ldr	rvb, [rva, #0x40]	@ rvb <- contents of USB_CNTR
	eor	rvb, rvb, #0x08		@ rvb <- USB_CNTR with FSUSP bit toggled
	str	rvb, [rva, #0x40]
	set	pc,  lnk

/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

usbhwEndpointStatus: @ get status of EP into sv2 and sv3 (sv1 is device int)
	ldr	rva, =usb_base
	and	rvb, sv1, #0x0F		@ rvb <- endpoint part of istr
	ldr	sv3, [rva, rvb, LSL #2]	@ sv3 <- content of USB_EPnR (EP Stat)
	eq	rvb, #0			@ is interrupt for EP0?
	it	eq
	seteq	rvb, #0x010000		@	if so,  rvb <- indic bit for EP0
	eq	rvb, #1			@ is interrupt for EP1?
	it	eq
	seteq	rvb, #0x040000		@	if so,  rvb <- indic bit for EP1
	eq	rvb, #2			@ is interrupt for EP2?
	it	eq
	seteq	rvb, #0x100000		@	if so,  rvb <- indic bit for EP2
	eq	rvb, #3			@ is interrupt for EP3?
	it	eq
	seteq	rvb, #0x400000		@	if so,  rvb <- indic bit for EP3
	tst	sv1, #0x10		@ is this an IN transfer?
	it	eq
	lsleq	rvb, rvb, #1		@	if so,  adjust indic bit
	set	sv2, rvb
	set	pc,  lnk

/* BULK IN Enpoint Interrupt Response */

usbhwBIe: @ clear the txcomp interrupt
	ldr	env, =UsbBulkInEP
	ldr	rva, =usb_base
	ldr	rvb, [rva, env, LSL #2]	@ rvb <- USB_EPnR
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00F0
	orr	rvb, rvb, #0x8000
	str	rvb, [rva, env, LSL #2]	@ USB_EPnR <- Clear CTR-TX int on EP
	set	pc,  lnk


usbhwBIw: @ write to Bulk IN EP
	ldr	rva, =usb_base
	ldr	rvc, [rva, #usb_ibulkin] @ rvc <- USB_EP3R
	tst	rvc, #usb_txrdy		 @ is EP3 active (or stalled)?
	bne	usbhwBIw		 @	if so,  jump back to wait f/idle
	b	wrtEPU

/* BULK OUT Enpoint Interrupt Response */

usbhwBOe: @ Bulk OUT EP int entry
	bic	sv1, sv1, #usb_itxendp	   @ exclude Txendpkt bit from int clr
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt register
	set	pc,  lnk

usbhwBOw: @ initiate input data echo (if needed)
	@ modifies:	rva, rvb
	@ returns via:	lnk
	ldr	rva, =usb_base
	ldr	rvb, [rva, #usb_ibulkin] @ rvb <- contents of USB_EP3R
	tst	rvb, #usb_txrdy		 @ is EP3 idle or disabled?
	it	ne
	setne	pc,  lnk		 @	if not, return (good to go)
	ldr	rva, =usb_hw_buffer	 @ rva <- usb hardware buffer start
.ifndef usb_cntreg_32b
	set	rvb, #0			 @ rvb <- num bytes to send (raw int)
	str	rvb, [rva, #0x34]	 @ store num byt to snd in USB_COUNT3_TX
.else
	ldr	rvb, [rva, #0x1c]
	bic	rvb, rvb, #0xff00
	bic	rvb, rvb, #0x00ff
	str	rvb, [rva, #0x1c]	@ store 0 bytes to send in USB_COUNT3_TX
.endif
	ldr	rva, =usb_base
	ldr	rvb, [rva, #usb_ibulkin] @ rvb <- contents of USB_EP3R
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00C0
	eor	rvb, rvb, #0x0030
	orr	rvb, rvb, #0x8000
	orr	rvb, rvb, #0x0080
	str	rvb, [rva, #usb_ibulkin] @ USB_EP3R <- EP data VALID, tx rdy
	b	usbhwBOw

/* CONTROL IN Enpoint Interrupt Response */


/* CONTROL OUT Enpoint Interrupt Response */

usbhwDGD: @ 9.4.3 Get Descriptor of Device Standard request	
	bl	wrtEP
	b	usbSOx

usbhwEGS: @ Get Status of Endpoint in sv5 into rvb
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base
	ldr	env, [rva, rvb, LSL #2]
	tst	rvb, #0x80
	it	eq
	lsreq	env, env, #8
	and	rvb, env, #0x30
	eq	rvb, #0x30
	itE	eq
	seteq	rvb, #0			@	if so,  rvb <- 0, not enabled
	setne	rvb, #1			@	if not, rvb <- 1, enabled
	set	pc,  lnk

usbhwSetAddress: @ Set Device to Address in sv5
	@ USB Status IN  exit -- write null packet to   EP 1 (phys, aka 0x80)
	@ disable the correct transfer interrupt mask (CTRM) in USB_CNTR
	ldr	rva, =usb_base
	ldr	rvb, [rva, #0x40]
	bic	rvb, rvb, #0x9C00
	str	rvb, [rva, #0x40]	
	set	env, #UsbControlInEP	@ env <- Control IN EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	set	cnt, #0x00		@ cnt <- 0 bytes to send
	bl	wrtEP			@ write 0 bytes to EP
hwsta0:	@ wait for tx to be complete (CTR_TX in USB_EP0R) then clear CTR_TX
	ldr	rvb, [rva]		@ rvb <- contents of USB_EP0R
	tst	rvb, #0x80		@ is CTR_TX set?
	beq	hwsta0			@	if not, jump to keep waiting
	ldr	rvb, [rva]		@ rvb <- contents of USB_EP0R
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00F0
	orr	rvb, rvb, #0x8000
	str	rvb, [rva]		@ USB_EPnR <- Clear CTR-TX int on EP
	ldr	rvb, [rva]		@ rvb <- contents of USB_EP0R
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00C0
	eor	rvb, rvb, #0x0030
	orr	rvb, rvb, #0x8000
	str	rvb, [rva]		@ USB_EPnR <- EP data VALID, tx when rdy
	@ re-enable the correct transfer interrupt mask (CTRM) in USB_CNTR
	ldr	rva, =usb_base
	ldr	rvb, [rva, #0x40]
	orr	rvb, rvb, #0x9C00
	str	rvb, [rva, #0x40]
	ldr	rva, =USB_SETUP_BUFFER	@ rva <- address of setup buffer
	ldr	sv5, [rva]		@ sv5 <- reqtyp(8), request(8), val(16)
	lsr	sv5, sv5, #16		@ sv5 <- address = val(16)
	orr	rvb, sv5, #0x80		@ rvb <- address ored w/Dev Enab (0x80)
	ldr	rva, =usb_base
	str	rvb, [rva, #0x4C]	@ set address
	b	usbEPx
	
usbhwConfigure: @ Configure the device
	@ stop uart from generating Rx interrupts (noise on shared READBUFFER)
	ldr	rva, =uart0_base
	ldr	rvb, =uart_iRx_dis
	str	rvb, [rva, #uart_ienab]	@ UART0_IE <- disable RxBufNotEmpty Int
	@ clear the readbuffer
	ldr	rva, =BUFFER_START
	vcrfi	rva, rva, READ_BF_offset
	set	rvb, #i0
	vcsti	rva, 0, rvb
	@ configure USB
	ldr	rva, =usb_base
	ldr	rvb, =0x0621
	str	rvb, [rva, #0x04]	@ enable EP1 -- Interrupt IN
	ldr	rvb, =0x3002
	str	rvb, [rva, #0x08]	@ enable EP2 -- Bulk OUT
	ldr	rvb, =0x0023
	str	rvb, [rva, #0x0C]	@ enable EP3 -- Bulk IN
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
	ldr	rvb, =uart_iRx_ena
	str	rvb, [rva, #uart_ienab]	@ UART0_IE <- enable RxBufNotEmpty Int
	@ set default i/o port to uart
	ldr	rvb, =vuart0
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  lnk

/* Status IN/OUT responses */

usbhwStatusOut:	@ Control OUT Interrupt, Status OUT Phase
	set	env, #UsbControlOutEP	@ env <- Control OUT EndPoint
	ldr	dts, =USB_DATA		@ dts <- buffer
	set	cnt, #0			@ cnt <- 0 bytes to read
	bl	rdEP			@ read 0 bytes from EP
	b	usbEPx

usbSOx:	@ Prepare setup buffer for Status OUT Phase 
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, =0xFF
	str	rvb, [rva]
	b	usbEPx

/* Enpoint stalling, unstalling */

usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80) -- i.e. Control IN
	ldr	rva, =usb_base
	ldr	rvb, [rva]		@ rvb <- USB_EP0R
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00C0
	eor	rvb, rvb, #0x0010
	orr	rvb, rvb, #0x8000
	str	rvb, [rva]		@ USB_EPnR <- EP data VALID, tx when rdy
	b	usbEPx

usbhwStallEP: @ Stall the EndPoint in r5
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base
	ldr	rvb, [rva, rvb, LSL #2]	@ rvb <- USB_EPnR
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00C0
	tst	sv5, #0x80
	itE	ne
	eorne	rvb, rvb, #0x0010
	eoreq	rvb, rvb, #0x0100
	orr	rvb, rvb, #0x8000
	and	sv5, sv5, #0x0F		@ rvb <- logical endpoint
	str	rvb, [rva, sv5, LSL #2]	@ USB_EPnR <- EP data VALID, tx when rdy
	set	pc,  lnk

usbhwUnstallEP:	@ Unstall the EndPoint in sv5, jump to Status IN
	and	rvb, sv5, #0x0F		@ rvb <- logical endpoint
	ldr	rva, =usb_base
	ldr	rvb, [rva, rvb, LSL #2]	@ rvb <- USB_EPnR
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00C0
	tst	sv5, #0x80
	itE	ne
	eorne	rvb, rvb, #0x0020
	eoreq	rvb, rvb, #0x0300
	orr	rvb, rvb, #0x8000
	and	sv5, sv5, #0x0F		@ sv5 <- logical endpoint
	str	rvb, [rva, sv5, LSL #2]	@ USB_EPnR <- EP data VALID, tx when rdy
	set	pc,  lnk

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write and helper functions

------------------------------------------------------------------------------*/

rdEP:	@ read from endpoint in env to buffer in dts with count in cnt
	and	env, env, #0x0F
	ldr	rva, =usb_base
	ldr	rvb, [rva, env, LSL #2]	@ rvb <- USB_EPnR
	bic	rvb, rvb, #0xF000
	bic	rvb, rvb, #0x00F0
	orr	rvb, rvb, #0x0080
	str	rvb, [rva, env, LSL #2]	@ USB_EP0R <- Clear CTR-RX int on EP0
	ldr	rva, =usb_hw_buffer	@ rva <- usb hardware buffer start
  .ifndef usb_cntreg_32b
	add	rva, rva, env, LSL #4	@ rva <- start of pkt bfr table for EP0
	ldr	cnt, [rva, #12]		@ cnt <- num bytes rcvd (USB_COUNTn_RX)
	bic	cnt, cnt, #0xFC00	@ cnt <- number of bytes received
	ldr	rvb, [rva, #8]		@ rvb <- offset to USB_ADRn_RX data / 2
	ldr	rva, =usb_hw_buffer	@ rva <- usb hardware buffer start
	add	rva, rva, rvb, LSL #1	@ rva <- start adrs of Rx pkt mem for EP
	set	rvb, #0
usbSEZ:	cmp	rvb, cnt
	bpl	usbSEX
	ldr	rvc, [rva, rvb, LSL #1]
	strh	rvc, [dts, rvb]
	add	rvb, rvb, #2
	b	usbSEZ
  .else
	add	rva, rva, env, LSL #3	@ rva <- start of pkt bfr table for EP0
	ldr	cnt, [rva, #4]		@ cnt <- num bytes rcvd (USB_COUNTn_RX)
	lsr	cnt, cnt, #16
	bic	cnt, cnt, #0xFC00	@ cnt <- number of bytes received
	ldr	rvb, [rva]		@ rvb <- offset to USB_ADRn_RX data
	lsr	rvb, rvb, #16
	ldr	rva, =usb_hw_buffer	@ rva <- usb hardware buffer start
	add	rva, rva, rvb		@ rva <- start adrs of Rx pkt mem for EP
	set	rvb, #0
usbSEZ:	cmp	rvb, cnt
	bpl	usbSEX
	ldr	rvc, [rva, rvb]
	str	rvc, [dts, rvb]
	add	rvb, rvb, #4
	b	usbSEZ
  .endif
usbSEX:	ldr	rva, =usb_base
	ldr	rvb, [rva, env, LSL #2]	@ rvb <- USB_EPnR
	bic	rvb, rvb, #0xC000
	bic	rvb, rvb, #0x00F0
	eor	rvb, rvb, #0x3000
	orr	rvb, rvb, #0x0080
	orr	rvb, rvb, #0x8000
	str	rvb, [rva, env, LSL #2]	@ USB_EP0R <- EP dat VALID, rcv when rdy
	set	pc,  lnk

wrtEP:	@ write data to Control or Bulk In Endpoint
wrtEPU:	@ write data to Control or Bulk In Endpoint
	and	env, env, #0x0F
	ldr	rva, =usb_base
	ldr	rvb, [rva, env, LSL #2]	@ rvb <- USB_EPnR
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00F0
	orr	rvb, rvb, #0x8000
	str	rvb, [rva, env, LSL #2]	@ USB_EPnR <- Clear CTR-TX int on EP
	ldr	rva, =usb_hw_buffer	@ rva <- usb hardware buffer start
  .ifndef usb_cntreg_32b
	add	rva, rva, env, LSL #4	@ rva <- start of pkt bfr table for EP
wrtEPW:	set	rvb, #0
	str	rvb, [rva, #4]		@ store num byte to snd in USB_COUNTn_TX
	ldr	rvb, [rva, #4]		@ store num byte to snd in USB_COUNTn_TX
	eq	rvb, #0
	bne	wrtEPW
	str	cnt, [rva, #4]		@ store num byte to snd in USB_COUNTn_TX
	ldr	rvb, [rva, #0]		@ rvb <- offset to USB_ADRn_TX data / 2
	ldr	rva, =usb_hw_buffer	@ rva <- usb hardware buffer start
	add	rva, rva, rvb, LSL #1	@ rva <- start adrs of Tx pkt mem for EP
	set	rvb, #0
wrtEPX:	cmp	rvb, cnt
	bpl	wrtEPY
	ldrb	rvc, [dts, rvb]
	add	rvb, rvb, #1
	ldrb	sv5, [dts, rvb]
	sub	rvb, rvb, #1
	orr	rvc, rvc, sv5, lsl #8
	str	rvc, [rva, rvb, LSL #1]
	add	rvb, rvb, #2
	b	wrtEPX
  .else
	add	rva, rva, env, LSL #3	@ rva <- start of pkt bfr table for EP
	ldr	rvb, [rva, #4]
	bic	rvb, rvb, #0xff00
	bic	rvb, rvb, #0x00ff
	orr	rvb, rvb, cnt
	str	rvb, [rva, #4]		@ store num byte to snd in USB_COUNTn_TX
	ldr	rvb, [rva, #0]		@ rvb <- offset to USB_ADRn_TX data
	bic	rvb, rvb, #0xff000000
	bic	rvb, rvb, #0x00ff0000
	ldr	rva, =usb_hw_buffer	@ rva <- usb hardware buffer start
	add	rva, rva, rvb		@ rva <- start adrs of Tx pkt mem for EP
	set	rvb, #0
wrtEPX:	cmp	rvb, cnt
	bpl	wrtEPY
	add	rvb, rvb, #3
	ldrb	rvc, [dts, rvb]		@ rvb <- byte 3 of next data word
	sub	rvb, rvb, #1
	ldrb	sv5, [dts, rvb]		@ sv5 <- byte 2 of next data word
	orr	rvc, sv5, rvc, lsl #8	@ rvb <- bytes 3 and 2 combined
	sub	rvb, rvb, #1
	ldrb	sv5, [dts, rvb]		@ rvb <- byte 1 of next data word
	orr	rvc, sv5, rvc, lsl #8	@ rvb <- bytes 3, 2 and 1 combined
	sub	rvb, rvb, #1
	ldrb	sv5, [dts, rvb]		@ rvb <- byte 0 of next data word
	orr	rvc, sv5, rvc, lsl #8	@ rvb <- full data word
	str	rvc, [rva, rvb]
	add	rvb, rvb, #4
	b	wrtEPX
  .endif
wrtEPY:	ldr	rva, =usb_base
	ldr	rvb, [rva, env, LSL #2]	@ rvb <- USB_EPnR
	and	rvc, rvb, #0x30		@ rvc <- STAT_TX bits
	eq	rvc, #0x30		@ is EPn active?
	it	eq
	seteq	pc,  lnk		@	if so, jump to return (ok to go)
	bic	rvb, rvb, #0xF100
	bic	rvb, rvb, #0x00C0
	eor	rvb, rvb, #0x0030
	orr	rvb, rvb, #0x8000
	orr	rvb, rvb, #0x0080
	str	rvb, [rva, env, LSL #2]	@ USB_EPnR <- EP data VALID (tx rdy)
	b	wrtEPY

/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

_func_
usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base
	ldr	rvc, [rva, #usb_ibulkin] @ rvb <- contents of USB_EP3R
	tst	rvc, #usb_txrdy		@ is EP3 idle (or disabled)?
	bne	usbhwrc0		@	if not, jump to return, ok to go
	ldr	rva, =usb_hw_buffer	@ rva <- usb hardware buffer start
  .ifndef usb_cntreg_32b
	set	rvc, #0			@ rvb <- numb byts to send (raw int)
	str	rvc, [rva, #0x34]	@ store num byt to send in USB_COUNT3_TX
  .else
	ldr	rvc, [rva, #0x1c]
	bic	rvc, rvc, #0xff00
	bic	rvc, rvc, #0x00ff
	str	rvc, [rva, #0x1c]	@ store 0 bytes to send in USB_COUNT3_TX
  .endif
	ldr	rva, =usb_base
	ldr	rvc, [rva, #usb_ibulkin] @ rvb <- contents of USB_EP3R
	bic	rvc, rvc, #0xF100
	bic	rvc, rvc, #0x00C0
	eor	rvc, rvc, #0x0030
	orr	rvc, rvc, #0x8000
	orr	rvc, rvc, #0x0080
	str	rvc, [rva, #usb_ibulkin] @ USB_EP3R <- EP dat VALID, tx when rdy
	b	usbhwrc
usbhwrc0:
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return






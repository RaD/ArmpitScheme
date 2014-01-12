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
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt
	set	sv4, lnk
	ldr	rvb, =0xFE0500		@ rvb <- Get Device Status command
	bl	wrtcmd			@ get the device status
	ldr	rvb, =0xFE0200		@ rvb <- Read Device Status command
	bl	rdcmd			@ read the device status to rvb
	set	pc,  sv4

_func_
usbhwReset:
 .ifndef usb_reep
	ldr	rva, =usb_base
	set	rvb, #0xff
	orr	rvb, rvb, rvb, lsl #8
	str	rvb, [rva, #usb_iclear_dv] @ clear USB ints (esp. txpacketend)
	set	rvb, #0x66
	orr	rvb, rvb, #0x0200
	str	rvb, [rva, #0x04]	@ enable interrupts
 .endif
	set	pc,  lnk

_func_
usbhwRemoteWakeUp:	
	set	sv4, lnk
	ldr	rvb, =0xFE0500		@ rvb <- Get/Set Device Status command
	bl	wrtcmd			@ get ready to set the device status
	ldr	rvb, =0x010100		@ rvb <- Set Status command
	bl	wrtcmd			@ set dev stat to 0x01 (remote wakeup)
	set	pc,  sv4

/*------------------------------------------------------------------------------

		response to endpoint interrupts 

------------------------------------------------------------------------------*/

_func_
usbhwEndpointStatus: @ return endpoint status in sv3
 .ifdef usb_reep
	ldr	rva, =usb_base
	ldr	sv2, [rva, #usb_istat_ep]  @ sv2 <- Endpoint Interrupt Status
	str	sv2, [rva, #usb_iclear_ep] @ clear the interrupt
usbhw0:	ldr	rvb, [rva, #usb_istat_dv]  @ rvb <- Device Interrupt Status
	tst	rvb, #usb_icd_full	   @ is command data rdy (CDFULL=0x20)?
	beq	usbhw0			   @	if not, jump to wait for it
	ldr	sv3, [rva, #usb_cmd_data]  @ sv3 <- command data (EP status)
	set	pc,  lnk
 .else
	@ modifies sv2, sv3, sv4, sv5, rva, rvb, env
	set	sv4, lnk
	set	sv2, sv1		@ sv2 <- endpoint interrupts
	ldr	rva, =usb_base
	and	rvb, sv1, #0x01fe
	str	rvb, [rva, #usb_iclear_dv] @ clear USB interrupt
	set	sv5, #UsbControlOutEP
	tst	sv2, #usbCO_ibit	@ is interrupt for Control OUT EP ?
	itT	eq
	seteq	sv5, #UsbControlInEP
	tsteq	sv2, #usbCI_ibit	@ is interrupt for Control IN EP ?
	itT	eq
	seteq	sv5, #UsbBulkOutEP
	tsteq	sv2, #usbBO_ibit	@ is interrupt for Bulk Out EP ?
	itT	eq
	seteq	sv5, #UsbBulkInEP
	tsteq	sv2, #usbBI_ibit	@ is interrupt for Bulk IN EP ?
	it	eq
	seteq	pc, sv4
	bl	usbhwEPSet		@ rvb <- EP frmtd for cmnd wrt (phys ep)
	orr	rvb, rvb, #0x400000	@ rvb <- full cmnd to set sel EP/clr int
	bic	env, rvb, #0x500	@ env <- phys endpoint, shifted, saved
	bl	wrtcmd			@ select endpoint
	orr	rvb, env, #0x200	@ rvb <- command to read status
	bl	rdcmd			@ rvb <- cmd/data (read status)
	set	sv3, rvb
	set	pc,  sv4
 .endif

/* BULK IN Enpoint Interrupt Response */

_func_
usbhwBIe: @ clear the txendpkt interrupt
	and	env, sv1, #usb_itxendp
	ldr	rva, =usb_base
	str	env, [rva, #usb_iclear_dv] @ clear USB interrupt reg
	set	pc,  lnk

/* BULK OUT Enpoint Interrupt Response */

_func_
usbhwBOw: @ initiate input data echo (if needed)
	@ modifies:	rva, rvb
	@ returns via:	lnk
	ldr	rva, =usb_base
	ldr	rvb, [rva, #usb_ibulkin] @ rvb <- USBDevIntSt
	tst	rvb, #usb_txrdy		@ is Bulk IN EP already ready to Tx
	itT	ne
	strne	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt
	setne	pc,  lnk		@ 	if so,  return (good to go)
	set	cnt, #0			@ cnt <- 0 (0 bytes to init write)
	set	env, #UsbBulkInEP	@ env <- Bulk IN EP (phys = 5, log = 2)
	b	wrtEPU

/* CONTROL IN Enpoint Interrupt Response */


/* CONTROL OUT Enpoint Interrupt Response */

_func_
usbhwDGD: @ 9.4.3 Get Descriptor of Device Standard request
	bl	wrtEP
	b	usbSOx

_func_
usbhwEGS: @ Get Status of Endpoint in sv5 into rvb
	set	sv4, lnk
	bl	usbhwEPSet		@ rvb <- EP format for cmd write (phys)
	bic	env, rvb, #0x500	@ env <- physical EP, shifted, saved
	bl	wrtcmd			@ select endpoint
	orr	rvb, env, #0x200	@ rvb <- command to read status
	bl	rdcmd			@ rvb <- cmd/data (read status)
	tst	rvb, #0x02		@ is the selected endpoint stalled?
	itE	eq
	seteq	rvb, #0			@	if not, rvb <- 0, not stalled
	setne	rvb, #1			@	if so,  rvb <- 1, stalled
	set	pc,  sv4

_func_
usbhwSetAddress: @ Set Device to Address in sv5
	ldr	rvb, =0xD00500		@ rvb <- Set Address command
	bl	wrtcmd			@ execute Set Address command
	ldr	rva, =USB_SETUP_BUFFER	@ rva <- address of setup buffer
	ldr	rvb, [rva]		@ rvb <- reqtyp(8), request(8), val(16)
	lsr	rvb, rvb, #16		@ rvb <- address = val(16)
	orr	rvb, rvb, #0x80		@ rvb <- address ored with Dev Enab 0x80
	lsl	rvb, rvb, #16		@ rvb <- address/enable shifted
	orr	rvb, rvb, #0x0100	@ rvb <- command to set address (part 2)
	bl	wrtcmd			@ Set the address
	b	usbSIx			@ jump to Status IN Phase and exit

_func_
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
	@ Realize the Interrupt In Endpoint (phys 3, log 1, aka 0x81)
 .ifdef usb_reep
	set	sv5, #3
	bl	usbhwReEP
 .endif
	ldr	rvb, =0x430500		@ rvb <- cmnd to set stat of EP 3 (phys)
	bl	wrtcmd			@ set endpoint status ...
	ldr	rvb, =0x100		@ rvb <- data for command = 0
	bl	wrtcmd			@ ... to 0
	@ Realize the BULK OUT Endpoint (phys 4, log 2, aka 0x02)
 .ifdef usb_reep
	set	sv5, #4
	bl	usbhwReEP
 .endif
	ldr	rvb, =0x440500		@ rvb <- cmnd to set stat of EP 0xA phys
	bl	wrtcmd			@ set endpoint status ...
	ldr	rvb, =0x100		@ rvb <- data for command = 0
	bl	wrtcmd			@ ... to 0
	@ Realize the BULK IN Endpoint (phys 5, log 2, aka 0x82)
 .ifdef usb_reep
	set	sv5, #5
	bl	usbhwReEP
 .endif
	ldr	rvb, =0x450500		@ rvb <- cmnd to set stat of EP 0xA phys
	bl	wrtcmd			@ set endpoint status ...
	ldr	rvb, =0x100		@ rvb <- data for command = 0
	bl	wrtcmd			@ ... to 0
	@ configure device
	ldr	rvb, =0xD80500		@ rvb <- command to config device 0xD8
	bl	wrtcmd			@ set device configuration status ...
	ldr	rvb, =0x010100		@ rvb <- data for command = 1
	bl	wrtcmd			@ ... to 1
	@ set default i/o port to usb
	ldr	rvb, =vusb
	vcsti	glv, 4, rvb		@ default input/output port model
	set	pc,  sv4

 .ifdef usb_reep
usbhwReEP: @ realize endpoint in sv5 (raw int)
	@ modifies:	rva, rvb
	set	rvb, #1
	lsl	rvb, rvb, sv5
	ldr	rva, =usb_base
	ldr	rva, [rva, #usb_reep]	@ rva <- current content of ReEP reg
	orr	rvb, rva, rvb		@ bit for EP 3
	ldr	rva, =usb_base
	str	rvb, [rva, #usb_reep]	@ OR EP with current val of realized reg
	str	sv5, [rva, #usb_epind]	@ Load EP index Reg with physical EP num
	cmp	sv5, #4
	itE	mi
	setmi	rvb, #0x08		@ rvb <-  8 bytes=max pkt siz for EP3
	setpl	rvb, #0x64		@ rvb <- 64 bytes=max pkt siz for EP4,5
	str	rvb, [rva, #usb_maxpsize] @ load the max packet size Register
usbhw1:	ldr	rvb, [rva, #usb_istat_dv] @ check for EP Reallized bit set
	tst	rvb, #0x0100		@ is EP realized (= 0x100)?
	beq	usbhw1			@	if not, jump to wait for this
	set	rvb, #0x0100		@ rvb <- EP Reallized bit = 0x100
	str	rvb, [rva, #usb_iclear_dv] @ Clear the EP Realized bit
	set	pc,  lnk
 .endif

_func_
usbhwDeconfigure: @ Deconfigure the device
	set	sv4, lnk
	ldr	rvb, =0xD80500		@ rvb <- command to config device 0xD8
	bl	wrtcmd			@ set device configuration status ...
	ldr	rvb, =0x100		@ rvb <- data for command = 0
	bl	wrtcmd			@ ... to 0
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
	set	pc,  sv4

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
	ldr	rva, =USB_SETUP_BUFFER
	ldr	rvb, =0xFF
	str	rvb, [rva]
	b	usbEPx

/* Enpoint stalling, unstalling */

_func_
usbStall: @ stall endpoint 1 (phys 1, log 0, aka 0x80)
	ldr	rvb, =0x410500		@ rvb <- set endpoint 1 status command
	bl	wrtcmd			@ set EP status
	ldr	rvb, =0x010100
	bl	wrtcmd			@ ... , EP_ST == 1);
	b	usbEPx

_func_
usbhwStallEP: @ Stall EP in sv5
	set	sv4, lnk
	bl	usbhwEPSet		@ rvb <- EP format for cmnd writing phys
	orr	rvb, rvb, #0x400000	@ rvb <- full command to set stat of EP
	bl	wrtcmd			@ set status of EP ...
	ldr	rvb, =0x010100
	bl	wrtcmd			@ ... to 1 = stalled
	set	pc,  sv4

_func_
usbhwUnstallEP:	@ Unstall the EndPoint in sv5
	set	sv4, lnk
	bl	usbhwEPSet		@ rvb <- EP format for cmnd writing phys
	orr	rvb, rvb, #0x400000	@ rvb <- full command to set stat of EP
	bl	wrtcmd			@ set status of EP ...
	ldr	rvb, =0x000100
	bl	wrtcmd			@ ... to 0 = not stalled	
	set	pc,  sv4

/*------------------------------------------------------------------------------

		common functions for response to endpoint interrupts:
		read, write and helper functions

------------------------------------------------------------------------------*/

.ifdef	LPC_13xx
  @ adjustment for LPC 1300 such that rdEP starts on 2-byte boundary
  .balign	16
  .space	2
.endif

_func_
rdEP:	@ (eg. section 9.13) uses rva, rvb, env, dts, cnt, returns cnt = count
	@ env <- EPNum, dts <- buffer
	@ set read_enable bit, and endpoint to use in control register
	and	rvb, env, #0x0F		@ rvb <- logical endpoint number
	lsl	rvb, rvb, #2		@ rvb <- logical endpoint number, shftd
	orr	rvb, rvb, #0x01		@ rvb <- log ep num shftd ored w/read_en
	ldr	rva, =usb_base
	str	rvb, [rva, #usb_ctrl]	@ enable reading from endpoint buffer
	nop
	nop
	nop
	@ wait for packet ready
rdEP_0:	ldr	cnt, [rva, #usb_rxplen]	@ cnt <- contents of Receive Length reg
 .ifndef LPC_13xx
	tst	cnt, #0x800		@ is the received packet ready (0x800)?
	beq	rdEP_0			@	if not, jump to keep waiting
 .endif
	@ verify that packet is valid
	tst	cnt, #0x400		@ is packet valid ?
	itT	eq
	seteq	cnt, #-1		@	if not, set count to -1
	seteq	pc,  lnk		@	if not, return w/count{cnt} = -1
	@ get count from packet
	ldr	rvb, =0x3FF		@ rvb <- mask to get number of bytes
	and	cnt, cnt, rvb		@ cnt <- number of bytes read
	@ read data
rdEP_1:	ldr	rvb, [rva, #usb_ctrl]
	tst	rvb, #0x01		@ is read_enable still asserted ?
	beq	rdEP_2			@	if not, exit read loop
	ldr	rvb, [rva, #usb_rxdata]	@ rvb <- word of data read
	str	rvb, [dts]		@ store it in buffer
	add	dts, dts, #4		@ dts <- updated data storage address
	b	rdEP_1
rdEP_2:	set	dts, lnk		@ dts <- saved lnk
	@ send select endpoint to protocol engine
	set	sv5, env
	bl	usbhwEPSet		@ rvb <- EP format for cmnd writing phys
	bl	wrtcmd			@ select the endpoint
	@ issue clear buffer command (0xF2)
	ldr	rvb, =0xF20500		@ rvb <- clear buffer cmnd = 0x00F20500
	bl	wrtcmd			@ clear the endpoint's receive buffer
	set	pc,  dts		@ return

_func_
wrtEP:	@ (eg. section 9.14) uses rva, rvb, env, dts, cnt
	@ env <- EPNum, dts <- buffer, cnt <- cnt
	@ set write_enable bit, and endpoint to use in control register
	and	rvb, env, #0x0F		@ rvb <- logical endpoint number
	lsl	rvb, rvb, #2		@ rvb <- logical endpoint number shifted
	orr	rvb, rvb, #0x02		@ rvb <- log ep shftd ored w/write_enab
	ldr	rva, =usb_base		@ rva <- USB base register
	str	rvb, [rva, #usb_ctrl]	@ enable writing to endpoint buffer
	nop
	nop
	nop
	str	cnt, [rva, #usb_txplen]	@ set the number of bytes to be sent
	nop
	nop
	nop
	@ write data packet to send
wrtEP1:	ldr	rvb, [rva, #usb_ctrl]
	tst	rvb, #0x02		@ is write_enable still asserted ?
	beq	wrtEP2			@	if not, exit write loop
 .ifdef cortex
	ldr	rvb, [dts]		@ rvb <- next data word
 .else
	ldrb	rvb, [dts, #3]		@ rvb <- byte 3 of next data word
	ldrb	sv5, [dts, #2]		@ sv5 <- byte 2 of next data word
	orr	rvb, sv5, rvb, lsl #8	@ rvb <- bytes 3 and 2 combined
	ldrb	sv5, [dts, #1]		@ rvb <- byte 1 of next data word
	orr	rvb, sv5, rvb, lsl #8	@ rvb <- bytes 3, 2 and 1 combined
	ldrb	sv5, [dts]		@ rvb <- byte 0 of next data word
	orr	rvb, sv5, rvb, lsl #8	@ rvb <- full data word
 .endif
	str	rvb, [rva, #usb_txdata]	@ write data to Transmit register
	add	dts, dts, #4		@ dts <- updated data source address
	b	wrtEP1
wrtEP2:	set	dts, lnk		@ dts <- saved lnk
	@ send select endpoint command to protocol engine
	set	sv5, env
	bl	usbhwEPSet		@ rvb <- EP format for cmnd write phys
	bl	wrtcmd			@ select the endpoint
	@ issue validate buffer command (0xFA)
	ldr	rvb, =0xFA0500		@ rvb <- valid buffer cmnd = 0x00FA0500
	bl	wrtcmd			@ validate the EP's transmit buffer
	set	pc,  dts		@ return

_func_
wrtEPU:	@ (eg. section 9.14)
	@ env <- EPNum, dts <- buffer, cnt <- cnt
	set	sv4, lnk
	bl	wrtEP
	bic	sv1, sv1, #usb_itxendp	@ exclude Txendpkt bit from int clearing
	ldr	rva, =usb_base
	str	sv1, [rva, #usb_iclear_dv] @ clear USB interrupt
	set	pc,  sv4

/* helper functions */

_func_
usbhwEPSet: @ get EP into proper format for writing cmd to engine	
	@ on entry:	sv5 <- EP
	@ on exit:	rvb <- EP formated for command writing
	@ modifies:	rvb
	@ returns via:	lnk
	and	rvb, sv5, #0x0F			@ rvb <- EP logical number
	lsl	rvb, rvb, #1			@ rvb <- EP physical number (if even)
	tst	sv5, #0x80			@ is this an IN enpoint (odd) ?
	it	ne
	addne	rvb, rvb, #1			@	if so,  rvb <- EP physical index
	lsl	rvb, rvb, #16			@ rvb <- command shifted
	orr	rvb, rvb, #0x0500		@ rvb <- full command to set status of EP
	set	pc,  lnk

_func_
wrtcmd:	@ write command/data from rvb to USB protocol engine (uses sv5, rva, rvb)
	@ modifies:	sv5, rva, rvb
	ldr	rva, =usb_base
	set	sv5, #usb_icc_empty		@ sv5 <- CCEMTY bit
	orr	sv5, sv5, #usb_icd_full		@ sv5 <- CCEMTY and CDFULL bits
	str	sv5, [rva, #usb_iclear_dv]	@ Clear both CCEMTY & CDFULL bits
	str	rvb, [rva, #usb_cmd_code]	@ 
wrtcm0:	ldr	rvb, [rva, #usb_istat_dv]	@ rvb <- Device Interrupt Status
	tst	rvb, #usb_icc_empty		@ has command been processed (i.e. rvb has CCEMTY) ?
	beq	wrtcm0				@	if not, jump to wait for it
	set	rvb, #usb_icc_empty		@ rvb <- CCEMTY
	str	rvb, [rva, #usb_iclear_dv]	@ clear CCEMTY bit
	set	pc,  lnk			@ return

_func_
rdcmd:	@ read command data, cmd in rvb, result in rvb (uses sv5, rva, rvb)
	@ always follows a wrtcmd (never used alone)
	@ modifies:	sv5, rva, rvb
	ldr	rva, =usb_base
	str	rvb, [rva, #usb_cmd_code]	@ CMD_CODE -> protocol engine
rdcmd1:	ldr	rvb, [rva, #usb_istat_dv]	@ rvb <- Device Interrupt Status
	tst	rvb, #usb_icd_full		@ is command data ready (i.e. rvb has CDFULL) ?
	beq	rdcmd1				@	if not, jump to wait for it
	ldr	rvb, [rva, #usb_cmd_data]	@ rvb <- command data
	set	sv5, #usb_icd_full		@ sv5 <- CDFULL
	str	sv5, [rva, #usb_iclear_dv]	@ clear the CDFULL bit
	set	pc,  lnk			@ return

/*------------------------------------------------------------------------------

		initiate USB character write from scheme (port function)

------------------------------------------------------------------------------*/

_func_
usbhwrc: @ initiate usb write, re-enable ints and return
	@ modifies:	rva, rvc
	@ returns via:	lnk
	ldr	rva, =usb_base
	ldr	rvc, [rva, #usb_ibulkin] @ rvb <- USB Int Stat
	tst	rvc, #usb_txrdy		@ is bulkin EP already ready to Tx
	itT	eq
	seteq	rvc, #usbBI_ibit	@ 	if not, rvc <- EP2 Tx Int bit
	streq	rvc, [rva, #usb_iset_dv] @ 	if not, USBEPIntSet <- Bulk IN
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return




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


	@-------.-------.-------.-------.-------+
@-------@	ports sub-environment		|
	@-------.-------.-------.-------.-------+

		VECSIZE	(end_of_prtenv - prtenv) >> 2
prtenv:
		.word	sfile,	vfile	@ FILE	[keep me at index 0 for getprt]
		.word	smemry,	vmemry	@ MEM	[keep me at index 1 for getprt]
		.word	suart0,	vuart0	@ UAR0
.ifndef	CORE_ONLY
		.word	suart1,	vuart1	@ UAR1
.endif
.ifdef	native_usb
		.word	susb,	vusb	@ USB
.endif
.ifdef	onboard_SDFT
		.word	ssdft,	vsdft	@ SDFT
.endif
.ifdef	include_i2c
		.word	si2c0,	vi2c0	@ I2C0
		.word	si2c1,	vi2c1	@ I2C1
.endif
	
end_of_prtenv:	@ end of prtenv


	SYMSIZE	4			@ port as symbol
port:	.ascii	"port"

	SYMSIZE	4
sfile:	.ascii	"FILE"

	SYMSIZE	3
smemry:	.ascii	"MEM"

	SYMSIZE	4
suart0:	.ascii	"UAR0"

.ifndef	CORE_ONLY

	SYMSIZE	4
suart1:	.ascii	"UAR1"

.endif

.ifdef	native_usb

	SYMSIZE	3
susb:	.ascii	"USB"

.endif

.ifdef	onboard_SDFT

	SYMSIZE	4
ssdft:	.ascii	"SDFT"

.endif

.ifdef	include_i2c

	SYMSIZE	4
si2c0:	.ascii	"I2C0"

	SYMSIZE	4
si2c1:	.ascii	"I2C1"

.endif
	
@-------------------------------------------------------------------------------
@
@	CHARACTER INPUT/OUTPUT PORT -- COMMON FUNCTIONS
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input  SUPPORT 3 - character input  port:	pchrdc,	pchrdy
@-------------------------------------------------------------------------------

	/* memory port-model		--------------------------------------*/

	VECSIZE	3
vmemry:	.word	i0
	.word	memipr
	.word	memopr

	/* memory input port-vector	--------------------------------------*/

	VECSIZE	5			@ memory input port-vector
memipr:	.word	i1			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-input-port	[return via cnt]
	UPFUNC	pmmrdc,	2		@ read-char / peek-char	[return via cnt]
	UPFUNC	trufun,	0		@ char-ready?		[return via cnt]
  .ifndef exclude_read_write
	UPFUNC	pmmred,	2		@ read			[return via cnt]
  .else
	.word	scheme_null
  .endif

	/* memory output port-vector	--------------------------------------*/

	VECSIZE	4			@ memory output port-vector
memopr:	.word	i2			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-output-port	[return via cnt]
	UPFUNC	pmmwrc,	2		@ write-char/string (lf)[return via lnk]
  .ifndef exclude_read_write
	UPFUNC	pmmwrt,	2		@ write / display	[return via cnt]
  .else
	.word	scheme_null
  .endif


@-------------------------------------------------------------------------------
@
@	UART INPUT/OUTPUT PORT and ISR
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input SUPPORT 4 - uart/usb input port:	uaripr, puagc0,1,2
@  II.A.6.6.3. output SUPPORT 4 - uart output port:	uaropr, puawrc, puaptc
@-------------------------------------------------------------------------------

	/* uart0 port-model		--------------------------------------*/

	VECSIZE	3
vuart0:	.word	(uart0_base >> 2) | i0
	.word	uaripr
	.word	uaropr

	/* uart1 port-model		--------------------------------------*/

.ifndef	CORE_ONLY

	VECSIZE	3
vuart1:	.word	(uart1_base >> 2) | i0
	.word	uaripr
	.word	uaropr
	
.endif

	/* uart input port-vector	--------------------------------------*/

	VECSIZE	9			@ uart input port-vector
uaripr:	.word	i1			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-input-port	[return via cnt]
	UPFUNC	pchrdc,	2		@ read-char / peek-char	[return via cnt]
	UPFUNC	pchrdy,	2		@ char-ready?		[return via cnt]
  .ifndef	exclude_read_write
	UPFUNC	pchred,	2		@ read			[return via cnt]
  .else
	.word	scheme_null
  .endif
	.word	scheme_true		@ wait-for-cr? #t=only cr is end of expr
	UPFUNC	puagc0,	1		@ read-helper, init	[return via lnk]
	UPFUNC	puagc1,	4		@ read-helper, getc	[return via lnk]
	UPFUNC	puagc2,	5		@ read-helper, finish up[return via lnk]

	/* uart output port-vector	--------------------------------------*/

	VECSIZE	5			@ uart output port-vector
uaropr:	.word	i2			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-output-port	[return via cnt]
	UPFUNC	puawrc,	2		@ write-char/string (nl)[return via lnk]
  .ifndef	exclude_read_write
	UPFUNC	pchwrt,	2		@ write / display	[return via cnt]
  .else
	.word	scheme_null
  .endif
	UPFUNC	puaptc,	2		@ putc			[return via lnk]


@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input SUPPORT 5  - file input  port:	filipr, pflcli, pflgc0,
@							pflgc1, pflgc2
@  II.A.6.6.3. output SUPPORT 5 - file output port:	filopr, pflclo, pflwrc,
@							pflptc, pputs
@-------------------------------------------------------------------------------

	/* file port-model		--------------------------------------*/

	VECSIZE	3
vfile:	.word	i0
  .ifndef live_SD
	.word	filipr
	.word	filopr
  .else
	.word	qflipr
	.word	qflopr
  .endif

.ifndef live_SD

	/* file input port-vector	--------------------------------------*/

	VECSIZE	12			@ file input port-vector
filipr:	.word	i1			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-input-port	[return via cnt]
	UPFUNC	pchrdc,	2		@ read-char / peek-char	[return via cnt]
	UPFUNC	pchrdy,	2		@ char-ready?		[return via cnt]
  .ifndef	exclude_read_write
	UPFUNC	pchred,	2		@ read			[return via cnt]
  .else
	.word	scheme_null
  .endif
	.word	scheme_false		@ wait-for-cr? #f=>eof,space,cr=expr end
	.word	pflgc0			@ read-helper, init	[return via lnk]
	.word	pflgc1			@ read-helper, getc	[return via lnk]
	.word	pflgc2			@ read-helper, finish-up[return via lnk]
	.word	finfo			@ input file file-info	[return via lnk]
	.word	filist			@ input port file-list	[return via cnt]
	.word	i0			@ input file buffer size

	/* file output port-vector	--------------------------------------*/

	VECSIZE	8			@ file output port-vector
filopr:	.word	i2			@ port-type:	1=in, 2=out (scheme int)
	.word	pflclo			@ close-output-port	[return via cnt]
	.word	pflwrc			@ write-char/string (lf)[return via lnk]
  .ifndef	exclude_read_write
	UPFUNC	pchwrt,	2		@ write / display	[return via cnt]
  .else
	.word	scheme_null
  .endif
	.word	pflptc			@ putc			[return via lnk]
	.word	finfo			@ output file file-info	[return via lnk]
	.word	filers			@ file erase		[return via lnk]
	.word	(F_PAGE_SIZE << 2) | i0	@ output file buffer size


.endif	@ .ifndef live_SD

.ifdef	onboard_SDFT

	/* sd-card port-model		--------------------------------------*/

	VECSIZE	3
vsdft:	.word	i0
	.word	qflipr
	.word	qflopr

	/* sd-card input port-vector	--------------------------------------*/

	VECSIZE	12			@ file input port-vector
qflipr:	.word	i1			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-input-port	[return via cnt]
	UPFUNC	pchrdc,	2		@ read-char / peek-char	[return via cnt]
	UPFUNC	pchrdy,	2		@ char-ready?		[return via cnt]
.ifndef	exclude_read_write
	UPFUNC	pchred,	2		@ read			[return via cnt]
.else
	.word	scheme_null
.endif
	.word	scheme_false		@ wait-for-cr? #f=>eof,space,cr=expr end
	.word	qflgc0			@ read-helper, init	[return via lnk]
	.word	qflgc1			@ read-helper, getc	[return via lnk]
	.word	qflgc2			@ read-helper, finish-up[return via lnk]
	.word	qfinfo			@ input file file-info	[return via lnk]
	.word	qfilst			@ input port file-list	[return via cnt]
	.word	(512 << 2) | i0		@ input file buffer size

	/* sd-card output port-vector	--------------------------------------*/

	VECSIZE	8			@ file output port-vector
qflopr:	.word	i2			@ port-type:	1=in, 2=out (scheme int)
	.word	qflclo			@ close-output-port	[return via cnt]
	.word	pflwrc			@ write-char/string (nl)[return via lnk]
.ifndef	exclude_read_write
	UPFUNC	pchwrt,	2		@ write / display	[return via cnt]
.else
	.word	scheme_null
.endif
	.word	qflptc			@ putc			[return via lnk]
	.word	qfinfo			@ output file file-info	[return via lnk]
	.word	qfilers			@ file erase		[return via lnk]
	.word	(512 << 2) | i0		@ output file buffer size

.endif	@  onboard_SDFT


@-------------------------------------------------------------------------------
@
@	I2C INPUT/OUTPUT PORT and ISR
@
@-------------------------------------------------------------------------------
@  II.A.6.     Standard Procedures
@  II.A.6.6    Input and Output
@  II.A.6.6.2. input SUPPORT 4  - i2c input  port:	i2cipr, pi2rdy, pi2red
@  II.A.6.6.3. output SUPPORT 4 - i2c output port:	i2copr, pi2wrt
@-------------------------------------------------------------------------------

.ifdef	include_i2c

	/* i2c0 port-model		--------------------------------------*/

	VECSIZE	3
vi2c0:	.word	(i2c0_base >> 2) | i0
	.word	i2cipr
	.word	i2copr

	/* i2c1 port-model		--------------------------------------*/

	VECSIZE	3
vi2c1:	.word	(i2c1_base >> 2) | i0
	.word	i2cipr
	.word	i2copr
	
	/* i2c input port vector	--------------------------------------*/

	VECSIZE	5			@ i2c input port-vector
i2cipr:	.word	i1			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-input-port	[return via cnt]
	UPFUNC	npofun,	0		@ read-char / peek-char	[return via cnt]
	.word	pi2rdy			@ char-ready?		[return via cnt]
.ifndef	exclude_read_write
	.word	pi2red			@ read			[return via cnt]
.else
	.word	scheme_null
.endif

	/* i2c output port vector	--------------------------------------*/

	VECSIZE	4			@ i2c output port-vector
i2copr:	.word	i2			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-output-port	[return via cnt]
	.word	lnkfxt			@ write-char/string (nl)[return via lnk]
.ifndef	exclude_read_write
	.word	pi2wrt			@ write / display	[return via cnt]
.else
	.word	scheme_null
.endif


.endif	@ include_i2c

@-------------------------------------------------------------------------------
@
@ III.C. COMMON COMPONENTS OF USB I/O and ISR
@
@-------------------------------------------------------------------------------

.ifdef	native_usb

	/* usb port-model		--------------------------------------*/

	VECSIZE	3
vusb:	.word	(usb_base >> 2) | i0
	.word	usbipr
	.word	usbopr

	/* usb input port vector	--------------------------------------*/

	VECSIZE	9			@ usb input port-vector
usbipr:	.word	i1			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-input-port	[return via cnt]
	UPFUNC	pchrdc,	2		@ read-char / peek-char	[return via cnt]
	UPFUNC	pchrdy,	2		@ char-ready?		[return via cnt]
.ifndef	exclude_read_write
	UPFUNC	pchred,	2		@ read			[return via cnt]
.else
	.word	scheme_null
.endif
	.word	scheme_true		@ wait-for-cr? #t=>only cr is end of exp
	UPFUNC	puagc0,	1		@ read-helper, init	[return via lnk]
	UPFUNC	puagc1,	4		@ read-helper, getc	[return via lnk]
	UPFUNC	puagc2,	5		@ read-helper, finish up[return via lnk]

	/* usb output port vector	--------------------------------------*/

	VECSIZE	5			@ usb output port-vector
usbopr:	.word	i2			@ port-type:	1=in, 2=out (scheme int)
	UPFUNC	npofun,	0		@ close-output-port	[return via cnt]
	UPFUNC	puawrc,	2		@ write-char/string (nl)[return via lnk]
.ifndef	exclude_read_write
	UPFUNC	pchwrt,	2		@ write / display	[return via cnt]
.else
	.word	scheme_null
.endif
	UPFUNC	pusptc,	2		@ putc			[return via lnk]


@-------------------------------------------------------------------------------
@
@  USB descriptors and configuration
@
@-------------------------------------------------------------------------------


USB_DeviceDesc:

@ Device Descriptor:
@ ------------------
@	bLength		bDescriptorType bcdUSB(L,H)
@       18 bytes	1 = device	usb 1.10
@.byte   0x12,		0x01,		0x10,	0x01
.byte   0x12,		0x01,		0x00,	0x02

@	bDeviceClass	bDeviceSubClass bDeviceProtocol bMaxPacketSize0
@	2 = CDC		0 = none	0 = std USB	8 bytes
.byte	0x02,		0x00,		0x00,		0x08

@	idVendor(L, H)	idProduct(L, H)	bcdDevice(L,H)
@					release 1.0
.byte	0xFF,	0xFF,	0x05,	0x00,	0x00,	0x01

@	iManufacturer	iProduct	iSerialNumber	bNumConfigurations
@	is in string 1	is in string 2	is in string 3	1 config only
.byte	0x01,		0x02,		0x03,		0x01

@ Configuration Descriptor:
@ -------------------------
@	bLength		bDescriptorType wTotalLength	bNumInterfaces
@	9 bytes		2 = config	100 bytes (L,H)	2 interfaces
.byte	0x09,		0x02,		0x43,	0x00,	0x02

@	bConfigValue	iConfiguration	bmAttributes	bMaxPower
@	config #1	0 = no string	0xC0 = usbpwr	250 x 2 mA
.byte	0x01,		0x00,		0xC0,		0xFA


@ Interface 0 Setting 0 CDC ACM Interface Descriptor:
@ ---------------------------------------------------
@	bLength		bDescriptorType bIntrfcNumber	bAlternateSetting
@	9 bytes		4 = interf	interface 0	setting 0
.byte	0x09,		0x04,		0x00,		0x00

@	bNumEndpoints	bIntrfcClss	bIntrfcSbClss	bIntrfcPrtcl	
@	uses 1 endpnt	2 = CDC		2 = ACM		1 = Hayes modem	
.byte	0x01,		0x02,		0x02,		0x01		

@	iIntrfc
@	0 = no string
.byte	0x00


@ Header Functional Descriptor (CDC):
@ -----------------------------------
@	bFunctionLength	bDescriptorType bDescripSubType	bcdDCD (L,H)
@	5 bytes		CS_INTERFACE	0 = Header	1.10
.byte	0x05,		0x24,		0x00,		0x10,	0x01

@ Call Management Functional Descriptor (CDC):
@ --------------------------------------------
@	bFunctionLength	bDescriptorType bDescripSubType	bmCapabilities
@	5 bytes		CS_INTERFACE	1 = Call Mgmnt	1 = mgmt on CDC
.byte	0x05,		0x24,		0x01,		0x01

@	bDataInterface
@	interface 1 used for mgmnt
.byte	0x01

@ ACM Functional Descriptor (CDC):
@ --------------------------------
@	bFunctionLength	bDescriptorType bDescripSubType	bmCapabilities
@	4 bytes		CS_INTERFACE	2 = ACM	
.byte	0x04,		0x24,		0x02,		0x02

@ Union Functional Descriptor (CDC):
@ ----------------------------------
@	bFunctionLength	bDescriptorType bDescriptorSbTp	
@	5 bytes		CS_INTERFACE	6 = Union	
.byte	0x05,		0x24,		0x06		

@	bMasterInterfce	bSlaveInterface0
@	Interface 0	Interface 1
.byte	0x00,		0x01

@ Endpoint 1 (Interrupt In, notification) Descriptor:
@ ---------------------------------------------------
@	bLength		bDescriptorType bEndpointAddress
@	7 bytes		5 = endpoint	EP1, IN
.byte	0x07,		0x05,		0x81

@	bmAttributes	wMaxPacketSize	bInterval
@	3 = interrupt	8 bytes	(L,H)	polling interval
@.byte	0x03,		0x08,	0x00,	0x0A
.byte	0x03,		0x08,	0x00,	0x10

@ Interface 1 Setting 0 CDC Data Class Interface Descriptor:
@ ----------------------------------------------------------
@	bLength		bDescriptorType bIntrfcNumber	bAlternateSetting
@	9 bytes		4 = interf	interface 1	setting 0
.byte	0x09,		0x04,		0x01,		0x00

@	bNumEndpoints	bIntrfcClss	bIntrfcSbClss	bIntrfcPrtcl
@	uses 2 endpnts	10 = CDC Data	0 = default	0 = no specific
.byte	0x02,		0x0A,		0x00,		0x00

@	iIntrfc
@	0 = no string
.byte	0x00

@ Endpoint 2 (bulk data OUT, phys=5):
@ ------------------------------------
@	bLength		bDescriptorType bEndpointAddress
@	7 bytes		5 = endpoint	EP2, OUT
.byte	0x07,		0x05,		0x02

@	bmAttributes	wMaxPacketSize	bInterval
@	2 = bulk	64 bytes (L,H)	bulk EP never NAKs
.byte	0x02,		0x40,	0x00,	0x00

@ Bulk IN Endpoint, LPC2000: 2 (bulk data IN, phys=5), AT91SAM7: 3
@ ----------------------------------------------------------------
@	bLength		bDescriptorType bEndpointAddress
@	7 bytes		5 = endpoint	EP2, IN
.byte	0x07,		0x05,		usbBulkINDescr

@	bmAttributes	wMaxPacketSize	bInterval
@	2 = bulk	64 bytes (L,H)	bulk EP never NAKs
.byte	0x02,		0x40,	0x00,	0x00

@ String Descriptor 0 (language ID):
@ ----------------------------------
@	bLength		bDescriptorType language ID
@	4 bytes		3 = string	English US (L,H)
.byte	0x04,		0x03,		0x09,	0x04

@ String Descriptor 1: Manufacturer
@ ---------------------------------
@	bLength		bDescriptorType
@	14 bytes	3 = string
.byte	0x0E,		0x03

@	String contents
@	A	r	m	p	i	t
.hword	0x41,	0x72,	0x6D,	0x70,	0x69,	0x74

@ String Descriptor 2: Product
@ ----------------------------
@	bLength		bDescriptorType
@	14 bytes	3 = string
.byte	0x0E,		0x03

@	String contents
@	S	c	h	e	m	e
.hword	0x53,	0x63,	0x68,	0x65,	0x6D,	0x65

@ String Descriptor 3: Version
@ ----------------------------
@	bLength		bDescriptorType
@	8 bytes	3 = string
.byte	0x08,		0x03

@	String contents
@	0	6	0
.hword	0x30,	0x36,	0x30

@ Terminating zero:
@ -----------------
.byte	0x00


.balign 4

@-------------------------------------------------------------------------------
@
@  USB descriptors and configuration for High-Speed (HS) Mode
@
@-------------------------------------------------------------------------------
	
.ifdef	has_HS_USB
	
USB_HS_DeviceDesc:

@ Device Descriptor:
@ ------------------
@	bLength		bDescriptorType bcdUSB(L,H)
@       18 bytes	1 = device	usb 1.10
@.byte   0x12,		0x01,		0x10,	0x01
.byte   0x12,		0x01,		0x00,	0x02

@	bDeviceClass	bDeviceSubClass bDeviceProtocol bMaxPacketSize0
@	2 = CDC		0 = none	0 = std USB	64 bytes
.byte	0x02,		0x00,		0x00,		0x40

@	idVendor(L, H)	idProduct(L, H)	bcdDevice(L,H)
@					release 1.0
.byte	0xFF,	0xFF,	0x05,	0x00,	0x00,	0x01

@	iManufacturer	iProduct	iSerialNumber	bNumConfigurations
@	is in string 1	is in string 2	is in string 3	1 config only
.byte	0x01,		0x02,		0x03,		0x01

@ Configuration Descriptor:
@ -------------------------
@	bLength		bDescriptorType wTotalLength	bNumInterfaces
@	9 bytes		2 = config	100 bytes (L,H)	2 interfaces
.byte	0x09,		0x02,		0x43,	0x00,	0x02

@	bConfigValue	iConfiguration	bmAttributes	bMaxPower
@	config #1	0 = no string	0xC0 = usbpwr	250 x 2 mA
.byte	0x01,		0x00,		0xC0,		0xFA


@ Interface 0 Setting 0 CDC ACM Interface Descriptor:
@ ---------------------------------------------------
@	bLength		bDescriptorType bIntrfcNumber	bAlternateSetting
@	9 bytes		4 = interf	interface 0	setting 0
.byte	0x09,		0x04,		0x00,		0x00

@	bNumEndpoints	bIntrfcClss	bIntrfcSbClss	bIntrfcPrtcl	
@	uses 1 endpnt	2 = CDC		2 = ACM		1 = Hayes modem	
.byte	0x01,		0x02,		0x02,		0x01		

@	iIntrfc
@	0 = no string
.byte	0x00


@ Header Functional Descriptor (CDC):
@ -----------------------------------
@	bFunctionLength	bDescriptorType bDescripSubType	bcdDCD (L,H)
@	5 bytes		CS_INTERFACE	0 = Header	1.10
.byte	0x05,		0x24,		0x00,		0x10,	0x01

@ Call Management Functional Descriptor (CDC):
@ --------------------------------------------
@	bFunctionLength	bDescriptorType bDescripSubType	bmCapabilities
@	5 bytes		CS_INTERFACE	1 = Call Mgmnt	1 = mgmt on CDC
.byte	0x05,		0x24,		0x01,		0x01

@	bDataInterface
@	interface 1 used for mgmnt
.byte	0x01

@ ACM Functional Descriptor (CDC):
@ --------------------------------
@	bFunctionLength	bDescriptorType bDescripSubType	bmCapabilities
@	4 bytes		CS_INTERFACE	2 = ACM	
.byte	0x04,		0x24,		0x02,		0x02

@ Union Functional Descriptor (CDC):
@ ----------------------------------
@	bFunctionLength	bDescriptorType bDescriptorSbTp	
@	5 bytes		CS_INTERFACE	6 = Union	
.byte	0x05,		0x24,		0x06		

@	bMasterInterfce	bSlaveInterface0
@	Interface 0	Interface 1
.byte	0x00,		0x01

@ Endpoint 1 (Interrupt In, notification) Descriptor:
@ ---------------------------------------------------
@	bLength		bDescriptorType bEndpointAddress
@	7 bytes		5 = endpoint	EP1, IN
.byte	0x07,		0x05,		0x81

@	bmAttributes	wMaxPacketSize	bInterval
@	3 = interrupt	8 bytes	(L,H)	polling interval
@.byte	0x03,		0x08,	0x00,	0x0A
.byte	0x03,		0x08,	0x00,	0x10

@ Interface 1 Setting 0 CDC Data Class Interface Descriptor:
@ ----------------------------------------------------------
@	bLength		bDescriptorType bIntrfcNumber	bAlternateSetting
@	9 bytes		4 = interf	interface 1	setting 0
.byte	0x09,		0x04,		0x01,		0x00

@	bNumEndpoints	bIntrfcClss	bIntrfcSbClss	bIntrfcPrtcl
@	uses 2 endpnts	10 = CDC Data	0 = default	0 = no specific
.byte	0x02,		0x0A,		0x00,		0x00

@	iIntrfc
@	0 = no string
.byte	0x00

@ Endpoint 2 (bulk data OUT, phys=5):
@ ------------------------------------
@	bLength		bDescriptorType bEndpointAddress
@	7 bytes		5 = endpoint	EP2, OUT
.byte	0x07,		0x05,		0x02

@	bmAttributes	wMaxPacketSize	bInterval
@	2 = bulk	512 bytes (L,H)	bulk EP never NAKs
.byte	0x02,		0x00,	0x02,	0x00

@ Bulk IN Endpoint, LPC2000: 2 (bulk data IN, phys=5), AT91SAM7: 3
@ ----------------------------------------------------------------
@	bLength		bDescriptorType bEndpointAddress
@	7 bytes		5 = endpoint	EP2, IN
.byte	0x07,		0x05,		usbBulkINDescr

@	bmAttributes	wMaxPacketSize	bInterval
@	2 = bulk	512 bytes (L,H)	bulk EP never NAKs
.byte	0x02,		0x00,	0x02,	0x00

@ String Descriptor 0 (language ID):
@ ----------------------------------
@	bLength		bDescriptorType language ID
@	4 bytes		3 = string	English US (L,H)
.byte	0x04,		0x03,		0x09,	0x04

@ String Descriptor 1: Manufacturer
@ ---------------------------------
@	bLength		bDescriptorType
@	14 bytes	3 = string
.byte	0x0E,		0x03

@	String contents
@	A	r	m	p	i	t
.hword	0x41,	0x72,	0x6D,	0x70,	0x69,	0x74

@ String Descriptor 2: Product
@ ----------------------------
@	bLength		bDescriptorType
@	14 bytes	3 = string
.byte	0x0E,		0x03

@	String contents
@	S	c	h	e	m	e
.hword	0x53,	0x63,	0x68,	0x65,	0x6D,	0x65

@ String Descriptor 3: Version
@ ----------------------------
@	bLength		bDescriptorType
@	8 bytes	3 = string
.byte	0x08,		0x03

@	String contents
@	0	6	0
.hword	0x30,	0x36,	0x30

@ Terminating zero:
@ -----------------
.byte	0x00


.balign 4


.endif		@ HS descriptors


.endif	@ native_usb



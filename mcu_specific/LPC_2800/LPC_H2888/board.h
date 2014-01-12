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

@-------10--------20--------30--------40--------50--------60--------70--------80

/* =======  BOARD =========== */
LPC_H2888	= 1		@ Olimex H2888 / LPC 2888

/* ======= OPTIONS ========== */
native_usb	= 1		@ comment out to exclude usb support

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDIO		= io2_base	@ PINS_2
REDLED		= 0x02
YELLED		= REDLED
GRNLED		= REDLED
@ --------- FREQs -----------
.ifdef native_usb
  UART0_DIV_L	= 0x39		@ lower byte of div for 9600 baud, pclk = 48MHz
  UART0_DIV_H	= 0x01		@ upper byte of div for 9600 baud, pclk = 48MHz
.else
  UART0_DIV_L	= 0x87		@ lower byte of div for 9600 baud, pclk = 60MHz
  UART0_DIV_H	= 0x01		@ upper byte of div for 9600 baud, pclk = 60MHz
.endif
@ --------- RAM ------------
RAMBOTTOM	= 0x00000000	@ off-chip SDRAM, remapped by MMU
RAMTOP		= 0x02000000	@ 32MB off-chip SDRAM
@ --------- BUFFERS --------
BUFFER_START	= RAMBOTTOM+0x020000+4	@ 128kb into SDRAM (for scheme code)
RBF_size	= 0x020000	@ READBUFFER size for tag as bytevector (128KB)
WBF_size	= 0x020000	@ WRITEBUFFER size for tag as bytevector (128KB)
heapbottom	= RAMBOTTOM + 0x100000	@ 1MB into SDRAM
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x20010000	@ 1st page of external FLASH (for files)
F_END_PAGE	= 0x201F0000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 512		@ size of pages used for files

@-------10--------20--------30--------40--------50--------60--------70--------80





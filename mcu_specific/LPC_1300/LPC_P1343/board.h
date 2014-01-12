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
LPC_P1343	= 1		@ Olimex LPC-P1343 / NXP LPC1343

/* ======= OPTIONS ========== */
native_usb	= 1		@ comment out to exclude usb support
small_memory	= 1		@ use small memory model (core only ...)
exclude_lib_mod = 1		@ exclude r6rs (library ...) forms

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= iocon_pio	@ board LED control is on IOCON_PIOn
LEDIO		= io3_base	@ board LED on/off pins are on IO1PINs
REDLED		= 0x01		@ P3.0
YELLED		= 0x02		@ P3.1
GRNLED		= 0x04		@ P3.2
@ --------- FREQs -----------
CLOCK_FREQ	= 0x011940	@ 72000 kHz = clock frequency (72 MHz)
PLL_PM_parms	= 0x25		@ 12MHz Xtal PLLdiv out=4,fdbk=6 > 288MHz,72MHz
UART0_DIV_L	= 0xd5		@ lower byte of div for 9600 baud, pclk = 72MHz
UART0_DIV_H	= 0x01		@ upper byte of div for 9600 baud, pclk = 72MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x10000000	@ Main on-chip RAM
RAMTOP		= 0x10002000	@ LPC 1343 (8 kB)
@ --------- BUFFERS --------
RBF_size	= 0x0400	@ READBUFFER  size for tag as bytevector (1KB)
WBF_size	= 0x0400	@ WRITEBUFFER size for tag as bytevector (1KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x00006000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x00007000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files

@-------10--------20--------30--------40--------50--------60--------70--------80







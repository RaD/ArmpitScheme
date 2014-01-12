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
TINY_2106	= 1		@ NewMicros Tiny 2106 / LPC 2106

/* ======= OPTIONS ========== */

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= PINSEL1	@ board LED control is on PINSEL1
LEDIO		= io0_base	@ board LED on/off pins are on IO0PINs
REDLED		= 0x00800000	@ bit 23 for red led on P0.23
YELLED		= 0x01000000	@ bit 24 for yellow led on P0.24
GRNLED		= 0x02000000	@ bit 25 for green led on P0.25
@ --------- FREQs ----------
CLOCK_FREQ	= 0xEA60	@ LPC2106 -- 60000 kHz = clock frequency
PLL_PM_parms	= 0x25		@ LPC2106 (10MHz) PLL div 2, mul 6 -> 60MHZ
UART0_DIV_L	= 0x87		@ lower byte of div for 9600 baud, pclk = 60MHz
UART0_DIV_H	= 0x01		@ upper byte of div for 9600 baud, pclk = 60MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x40000000
RAMTOP		= 0x40010000	@ LPC 2106 (64 kB)
@ --------- BUFFERS --------
RBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x00010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x0001C000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 512		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x00014000	@ 80KB into flash (after 2x8KB file pages+code)
LIB_TOP_PAGE	= 0x0001E000	@ start of boot block

@-------10--------20--------30--------40--------50--------60--------70--------80





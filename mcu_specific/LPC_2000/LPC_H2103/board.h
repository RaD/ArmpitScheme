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
LPC_H2103	= 1		@ Olimex LPC-H2103 / LPC 2103

/* ======= OPTIONS ========== */
small_memory	= 1

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= PINSEL1	@ board LED control is on PINSEL1
LEDIO		= io0_base	@ board LED on/off pins are on IO0PINs
GRNLED		= 0x04000000	@ P0.26 (only user LED onboard)
REDLED		= GRNLED	@ use green led
YELLED		= GRNLED	@ use green led
@ --------- FREQs -----------
CLOCK_FREQ	= 0xE666	@ LPC2103 -- 58982 KHz = clock frequency
PLL_PM_parms	= 0x23		@ LPC2103 (14.7456 MHz) PLL div 2, mul 4 = 60MHz
UART0_DIV_L	= 0x80		@ lower byte of div for 9600 baud, pclk = 60MHz
UART0_DIV_H	= 0x01		@ upper byte of div for 9600 baud, pclk = 60MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x40000000
RAMTOP		= 0x40002000	@ LPC 2103 (8 kB)
@ --------- BUFFERS --------
RBF_size	= 0x0400	@ READBUFFER size for tag as bytevector (1KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x00006000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x00007000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files

@-------10--------20--------30--------40--------50--------60--------70--------80





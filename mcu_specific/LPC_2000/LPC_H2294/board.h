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
LPC_H2294	= 1		@ Olimex H2294 / LPC 2294

/* ======= OPTIONS ========== */
onboard_SDFT	= 1		@ comment out to exclude SD-card file system

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= PINSEL1	@ LPC 2294 LED
LEDIO		= io0_base	@ LEDs are on IO0PINs
REDLED		= 0x60000000	@ P0.30 (and P0.29 for 30-bit internal repres.)
YELLED		= REDLED	@ P0.30
GRNLED		= REDLED	@ P0.30
@ --------- SD card ---------
sd_is_on_spi	= 1		@ SD card uses SPI interface
sd_spi		= spi0_base	@ SD card is on SPI0
sd_spi_gpio	= io0_base	@ SD card/SPI0 gpio0 P0.4,5,6=SCK0,MISO0,MOSI0
spi_old_silicon	= 1		@ SPI0 needs P0.7 conf as SSEL0 and tied to 3.3V
sd_cs_gpio	= io0_base	@ SD card chip-select is on gpio0
sd_cs		= 1 << 20	@ SD card chip-select P0.20 (the 20 in 1<< 20)
@ --------- FREQs -----------
CLOCK_FREQ	= 0xE666	@ LPC2294 -- 58982 kHz = clock frequency
PLL_PM_parms	= 0x23		@ LPC2294 (14.7456MHz) PLL div 2, mul 4 = 59MHz
UART0_DIV_L	= 0x80		@ lower byte of div for 9600 baud, pclk = 59MHz
UART0_DIV_H	= 0x01		@ upper byte of div for 9600 baud, pclk = 59MHz
@ --------- RAM ------------	  1MB off-chip RAM
RAMBOTTOM	= 0x81000000	@ LPC 2294 (1MB off-chip RAM)
RAMTOP		= 0x81100000	@ LPC 2294 (1MB off-chip RAM)
@ --------- BUFFERS --------
BUFFER_START	= 0x40000000+4	@ 16kb on-chip RAM
RBF_size	= 0x3f00	@ READBUFFER size for bytevector tag 16128 Bytes
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x80010000	@ 1st 64KB page of external FLASH (for files)
F_END_PAGE	= 0x803F0000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 512		@ size of pages used for files
LIB_BOTTOM_PAGE	= 0x00010000	@ 64KB into on-chip flash (page after code)
LIB_TOP_PAGE	= 0x0003E000	@ start of boot block

@-------10--------20--------30--------40--------50--------60--------70--------80





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
TCT_Hammer	= 1		@ TinCan Tools Hammer / S3C2410A, 200MHz

/* ======= OPTIONS ========== */
native_usb	= 1		@ comment out to exclude usb support
onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDIO		= 0x56000054	@ GPIO Port F, GPFDAT = reg control of LED pins
REDLED		= 0x01		@ bit 0
YELLED		= REDLED	@ aliased to red led
GRNLED		= REDLED	@ aliased to red led
@ --------- SD card --------- (card on TCT Hammer carrier board)
sd_is_on_spi	= 1		@ SD card uses SPI interface
sd_spi		= spi1_base	@ SD card is on SPI1
sd_spi_gpio	= ioG_base	@ SD card / SPI1 is on gpio_G
sd_cs_gpio	= ioH_base	@ SD card chip-select is on gpio_H
sd_cs		= 1 << 1	@ SD card chip-select gpio_H.1 (the 1 in << 1)
@ --------- FREQs -----------
PLL_PM_parms	= 0x0a1031	@ PLL1 parms for fclk = 202.8 MHz
UART0_DIV	= 329		@ divisor for 9600 baud if pclk = 202.8/4 MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x30000000	@ Bottom of SDRAM Bank 6
RAMTOP		= 0x32000000	@ 32MB into SDRAM (bank 6/7 as 16MB/16MB contig)
@ --------- BUFFERS --------
BUFFER_START	= RAMBOTTOM+0x020000+4	@ 128kb into SDRAM (allows for MMU TTB)
RBF_size	= 0x10000	@ READBUFFER  size for tag as bytevector (64 KB)
WBF_size	= 0x10000	@ WRITEBUFFER size for tag as bytevector (64 KB)
heapbottom	= RAMBOTTOM + 0x100000	@ 1MB into SDRAM
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x00100000	@ 1st page of FLASH for files 1MB in FLASH (MMU)
F_END_PAGE	= 0x00FE0000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 512		@ size of pages used for files

@-------10--------20--------30--------40--------50--------60--------70--------80





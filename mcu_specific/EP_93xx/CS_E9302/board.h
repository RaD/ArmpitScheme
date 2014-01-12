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
CS_E9302	= 1		@ Olimex CS-E9302 / EP9302

/* ======= OPTIONS ========== */
hardware_FPU	= 1		@ comment this to use soft float (no FPU use)
onboard_SDFT	= 1		@ comment this to exclude SD-card code

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDIO		= 0x80840020	@ address of register control for LED pins
REDLED		= 0x02		@ bit 1
YELLED		= 0x02		@ aliased to red led
GRNLED		= 0x01		@ bit 0
@ --------- SD card --------- 
sd_is_on_spi	= 1		@ SD card uses SPI interface
sd_spi		= spi0_base	@ SD card is on SPI0 (aka SPI1)
sd_cs_gpio	= ioF_base	@ SD card chip-select is on gpio_F
sd_cs		= 1 << 3	@ SD card chip-select gpio_F.3 (the 1 in << 3)
@ --------- FREQs -----------
PLL_PM_parms	= 0x02b49907	@ PLL1 parms for 166MHz
UART0_DIV_L	= 0x2F		@ lower byte of div for 9600 baud, pclk = 166MHz
UART0_DIV_H	= 0x00		@ upper byte of div for 9600 baud, pclk = 166MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x00000000	@ SDRAM, SROMLL=1, 4x8MB remapped to contig 32MB
RAMTOP		= 0x02000000	@ 32MB into SDRAM
@ --------- BUFFERS --------
BUFFER_START	= RAMBOTTOM+0x020000+4	@ 128kb into SDRAM (for scheme code)
RBF_size	= 0x10000	@ READBUFFER size for tag as bytevector (64KB)
heapbottom	= RAMBOTTOM + 0x100000	@ 1MB into SDRAM
@ --------- FLASH ----------
F_START_PAGE	= 0x60020000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x60FE0000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 512		@ size of pages used for files

@-------10--------20--------30--------40--------50--------60--------70--------80






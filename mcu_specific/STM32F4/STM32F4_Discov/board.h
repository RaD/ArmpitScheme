/*------------------------------------------------------------------------------
@
@  ARMPIT SCHEME Version 060
@
@  ARMPIT SCHEME is distributed under The MIT License.

@  Copyright (c) 2012-2013 Petr Cermak

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
STM32F4_Discov	= 1		@ STM32F4 Discovery board, Cortex-M4F

/* ======= OPTIONS ========== */
hardware_FPU	= 1		@ comment out to use soft float (no FPU use)
native_usb	= 1		@ comment out to assemble without usb support
harvard_split	= 1		@ uncomment to store .data section in CCM

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= ioportd_base	@ LED IO function control is on I/O Port D
LEDIO		= ioportd_base	@ LED on/off control is on I/O Port D
REDLED		= 1 << 14	@ PD.14
YELLED		= 1 << 13	@ PD.13 -- STAT2 yellow LED on board
GRNLED		= 1 << 12	@ PD.12 -- STAT1 green  LED on board
@ --------- SD card ---------
@onboard_SDFT	= 1		@ comment out to exclude SD card file system
@sd_is_on_spi	= 1		@ SD card is on sd/mmc interface
@sd_spi		= spi1_base	@ SD card is on SPI1
@sd_spi_gpio	= ioporta_base	@ SD card SPI1 port A PA4,5,6,7=SS,SCK,MISO,MOSI
@sd_cs_gpio	= ioporta_base	@ SD card chip-select is on IO port A
@sd_cs		= 1 << 8	@ SD card chip-select on PA.8 (the 8 in 1<< 8)
@ --------- FREQs -----------
Clock_parms	= 4 | (168 << 6) | (0 << 16) | (1 << 22) | (7 << 24)
Prescl_parms	= (0 << 4) | (5 << 10) | (4 << 13) | (8 << 16)
SYSTICK_RELOAD	= 168*10000 - 1	@ systick reload for 10ms interrupts at  168 MHz
UART0_DIV	= (0x5b<<4 | 1)	@ divisor for 115200 baud at APB2 Clock = 84 MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000
RAMTOP		= 0x2001C000	@ top of STM32F407VC 112 KB SRAM
@ --------- BUFFERS --------
RBF_size	= 0x0800	@ READBUFFER  size for tag as bytevector (2KB)
WBF_size	= 0x0800	@ WRITEBUFFER size for tag as bytevector (2KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x08020000	@ address of 1st page of FLASH for files
F_END_PAGE	= 0x080E0000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x08060000	@ above files (after 2x128KB file sectors+code)
LIB_TOP_PAGE	= 0x08100000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80




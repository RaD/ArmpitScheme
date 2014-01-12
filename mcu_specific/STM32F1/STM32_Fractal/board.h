/*------------------------------------------------------------------------------
@
@  ARMPIT SCHEME Version 060
@
@  ARMPIT SCHEME is distributed under The MIT License.

@  Copyright (c) 2012-2013 Tzirechnoy

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
STM32_Fractal	= 1		@ Fractal MCU32-1.12 Board / STM32F103RBT6 Cx-M3
STM32_H103	= 1		@ similar to Olimex STM32-H103

/* ======= OPTIONS ========== */
native_usb	= 1		@ comment out to exclude usb support
@onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem
always_init_usb	= 1		@ comment out to init USB only when plugged in
manual_usb_reset = 1		@ comment out to exclude manual disconnect code

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= ioportc_base	@ LED IO function control is on I/O Port C
LEDIO		= ioportc_base	@ LED on/off control is on I/O Port C
REDLED		= GRNLED	@ aliased to grnled
YELLED		= GRNLED	@ aliased to grnled
GRNLED		= 0x1000	@ PC12 (the only board LED except for power)
@ --------- SD card ---------
sd_is_on_spi	= 1		@ SD card uses SPI interface
sd_spi		= spi1_base	@ SD card is on SPI1
sd_spi_gpio	= ioporta_base	@ SD card IO port A PA4,5,6,7=SS,SCK,MISO,MOSI
sd_cs_gpio	= ioporta_base	@ SD card chip-select is on IO port A
sd_cs		= 1 << 8	@ SD card chip-select pin PA.8 (the 8 in 1<< 8)
@ --------- FREQs -----------
Clock_parms	= 0x001d2402	@ USB=48MHz,HSEPLLmult9=72MHz,AHB=36MHz=ADC=APBn
UART0_DIV	= 0x0ea6	@ divisor for 9600 baud at APB2 Clock = 36 MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000
RAMTOP		= 0x20005000	@ top of STM32 20 KB SRAM
@ --------- BUFFERS --------
RBF_size	= 0x0600	@ READBUFFER  size for tag as bytevector (1.5KB)
WBF_size	= 0x0600	@ WRITEBUFFER size for tag as bytevector (1.5KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x08010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x0801fC00	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x08010800	@ 66KB into flash (after 2x1KB file pages+code)
LIB_TOP_PAGE	= 0x08020000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80






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
STM32_LCD	= 1		@ Olimex STM32-LCD / STM32F103ZET6 Cortex-M3

/* ======= OPTIONS ========== */
native_usb	= 1		@ comment out to exclude usb support
onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= ioportb_base	@ LED IO function on IO Port B (no LED on board)
LEDIO		= ioportb_base	@ LED on/off control is on I/O Port B
REDLED		= GRNLED	@ aliased to grnled
YELLED		= GRNLED	@ aliased to grnled
GRNLED		= 0x04		@ PB2 (no LED on board use PB2 for external LED)
@ --------- SD card ---------
sd_is_on_mci	= 1		@ SD card uses MCI interface
sd_mci		= sdio_base	@ SD card is on sdio peripheral
@ --------- FREQs -----------
Clock_parms	= 0x001d2402	@ USB=48MHz,HSEPLLmult9=72MHz,AHB=36MHz,ADC,APBn
UART0_DIV	= 0x0ea6	@ divisor for 9600 baud at APB2 Clock = 36 MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000
RAMTOP		= 0x20010000	@ top of STM32F103ZE 64 KB SRAM
@ --------- BUFFERS --------
RBF_size	= 0x0800	@ READBUFFER  size for tag as bytevector (2KB)
WBF_size	= 0x0800	@ WRITEBUFFER size for tag as bytevector (2KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x08010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x0807f800	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x08011000	@ 68KB into flash, after 2x2KB file sectors+code
LIB_TOP_PAGE	= 0x08080000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80






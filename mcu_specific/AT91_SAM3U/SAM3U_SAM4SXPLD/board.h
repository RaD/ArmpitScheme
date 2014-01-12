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
SAM3U_SAM4SXPLD	= 1		@ Atmel/Embest SAM4S-Xplained, AT91-SAM3U4C chip

/* ======= OPTIONS ========== */
enable_MPU	= 1		@ comment out to not use the MPU
@native_usb	= 1		@ comment out to assemble without usb support

/* ===== CONFIGURATION ====== */
@ ----- LEDs / BUTTON -------
LEDPINSEL	= pioa_base	@ where to write 1 to make pin a gpio
LEDIO		= pioa_base
REDLED		= (1 << 28)	@ PA28
YELLED		= GRNLED	@ aliased to green LED
GRNLED		= (1 << 29)	@ PA29
LED_PIO_ID	= 10		@ PIO A (peripheral ID = 10)
BOOTOVERRID_PRT	= pioa_base	@ Boot-override (TP4) is on I/O Port A
BOOTOVERRID_BUT	= 25		@ Boot-override test-point is on pin PA25
BUT_PIO_ID	= 10		@ PIO A (peripheral ID = 10)
@ --------- FREQs -----------
@PLL_parmsA	= 0x201F3F02	@ XTal=12 MHz, PLLA x32/2 -> 96x2 MHz
PLL_parmsA	= 0x200F3F02	@ XTal=12 MHz, PLLA x16/2 -> 96MHz
@PLL_parmsA	= 0x20073F01	@ XTal=12 MHz, PLLA x8/1 -> 96MHz
@UPLL_parms	= 0x000F3F02	@ XTal=12 MHz, PLLB x16/2 -> 48x2 MHz for USB
@PLL_parmsB	= 0x000F3F02	@ XTal=12 MHz, PLLB x16/2 -> 48x2 MHz for USB
UART0_DIV	= 52		@ uart frequency div for 115200 bauds at 96MHz
SYSTICK_RELOAD	= 96*10000 - 1	@ systick reload for 10ms interrupts  at 96MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000	@ bottom of RAM
RAMTOP		= 0x2000C000	@ AT91-SAM3U4C (32KB contiguous SRAM0)
@ --------- BUFFERS --------
BUFFER_START	= 0x20080000	@ AT91-SAM3U4C (16KB SRAM1)
RBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
WBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
@@@ NO -- aligned wrong -- I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x00010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x0001F000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x00012000	@ 72KB into flash (after 2x4KB file pages+code)
LIB_TOP_PAGE	= 0x00020000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80





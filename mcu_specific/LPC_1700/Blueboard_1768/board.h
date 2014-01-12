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
Blueboard_1768	= 1		@ ngxtechnologies Blueboard LPC1768-H, LPC1768

/* ======= OPTIONS ========== */
native_usb	= 1		@ comment out to exclude usb support
onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem
enable_MPU	= 1		@ comment this line out to not use the MPU

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= PINSEL3	@ board LED control is on PINSEL3
LEDIO		= io1_base	@ board LED on/off pins are on IO1PINs
REDLED		= GRNLED	@ aliased
YELLED		= GRNLED	@ aliased
GRNLED		= 0x20000000	@ P1.29
@ --------- SD card ---------
sd_is_on_spi	= 1		@ SD card uses SPI interface
sd_spi		= spi0_base	@ SD card is on SPI0 (legacy SPI)
sd_spi_gpio	= io0_base	@ SD card SPI0 gpio0 P015,17,18=SCK0,MISO0,MOSI0
sd_cs_gpio	= io0_base	@ SD card chip-select is on gpio0
sd_cs		= 1 << 16	@ SD card chip-select P0.16 (the 16 in 1 << 16)
@ --------- FREQs -----------
CLOCK_FREQ	= 0x017700	@ 96000 kHz = clock frequency (96 MHz)
PLL_PM_parms	= 0x0B		@ 12 MHz Xtal PLL div 1, multiplier 12 -> 288MHZ
UART0_DIV_L	= 0x38		@ lower byte of div for 9600 baud, pclk = 48MHz
UART0_DIV_H	= 0x01		@ upper byte of div for 9600 baud, pclk = 48MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x10000000	@ Main on-chip RAM
RAMTOP		= 0x10008000	@ LPC 1768 (32 kB)
@ --------- BUFFERS --------
BUFFER_START	= 0x2007C000+4	@ AHB RAM Bank 0, 16KB, 0x2007C000 to 0x2007FFFF
RBF_size	= 0x1000	@ READBUFFER  size for tag as bytevector (4KB)
WBF_size	= 0x0C00	@ WRITEBUFFER size for tag as bytevector (3KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
@ Note: some LPC1768 hardware revisions have the flash sector at 0x70000 not
@	write-able even though IAP does not return an error (0x78000 remains
@	write-able though).
@       This is undocumented but discussed in electronix.ru forums (Dec. 6,
@	2010 to Mar. 3, 2011) and apparently confirmed by NXP (chips from
@	week 11 to 34 of 2010, possibly marked: rescreen).
@
@       Select F_END_PAGE and LIB_TOP_PAGE accordingly below.
@
F_START_PAGE	= 0x00010000	@ address of 1st page of FLASH (for files)
@F_END_PAGE	= 0x00078000	@ page after last page of FLASH used for files
F_END_PAGE	= 0x00068000	@ 0x70000 not accessible on this NXP mcu rev
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x00020000	@ 128KB into flash, after 2x32KB file pages+code
@LIB_TOP_PAGE	= 0x00080000	@ after last flash page
LIB_TOP_PAGE	= 0x00070000	@ adjusted: 0x70000 no-access on this NXP mcu

@-------10--------20--------30--------40--------50--------60--------70--------80






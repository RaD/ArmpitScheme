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
SAM3_H256	= 1		@ Olimex SAM3-H256 / AT91-SAM3S4B

/* ======= OPTIONS ========== */
enable_MPU	= 1		@ comment out to not use the MPU
native_usb	= 1		@ comment out to assemble without usb support
@onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= pioa_base	@ where to write 1 to make pin a gpio
LEDIO		= pioa_base
REDLED		= GRNLED	@ PA8
YELLED		= GRNLED	@ PA8
GRNLED		= (1 << 8)	@ PA8
LED_PIO_ID	= 11		@ PIO A (peripheral ID = 11)
BOOTOVERRID_PRT	= pioa_base	@ Boot-override (BUT1) is on I/O Port A
BOOTOVERRID_BUT	= 19		@ Boot-override button is on pin PA19
BUT_PIO_ID	= 11		@ PIO A (peripheral ID = 11)
@ --------- SD card ---------
sd_is_on_spi	= 1		@ if used, SD card will be on SPI interface
sd_spi		= spi0_base	@ SD card is on SPI0
sd_spi_gpio	= pioa_base	@ SD card port A PA11,12,13,14=SS,MISO,MOSI,CLK
@ --------- FREQs -----------
PLL_parmsA	= 0x201F3F03	@ XTal=12 MHz, PLLA x32/3 -> 64x2 MHz
PLL_parmsB	= 0x000F3F02	@ XTal=12 MHz, PLLB x16/2 -> 48x2 MHz for USB
FLSH_WTSTA 	= 3		@ flash wait states for 64MHz: 3 =>4 cycles r/w
FLSH_WRTWS 	= 6		@ flash write wait states, 64MHz: 6 =>7 cyc. r/w
UART0_DIV	= 417		@ usart0 frequency div for 9600 bauds at 64 MHz
SYSTICK_RELOAD	= 64*10000 - 1	@ systick reload for 10ms interrupts at 64 MHz
SPI_LS_DIV	= 255		@ SPI low  speed SCBR: 64 MHz/255 =  250 KHz
SPI_HS_DIV	= 10		@ SPI high speed SCBR: 64 MHz/10  =  6.4 MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000	@ bottom of RAM
RAMTOP		= 0x2000C000	@ AT91-SAM3S4B (48kB)
@ --------- BUFFERS --------
RBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
WBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
@ --------- FLASH ----------
F_START_PAGE	= 0x00010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x0003F000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x00012000	@ 72KB into flash (after 2x4KB file pages+code)
LIB_TOP_PAGE	= 0x00040000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80





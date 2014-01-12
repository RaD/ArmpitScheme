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
EK_LM4F120	= 1		@ TI EK LM4F120XL Launchpad Crtx-M4F LM4F120H5QR

/* ======= OPTIONS ========== */
hardware_FPU	= 1		@ comment out to use soft float (no FPU use)
enable_MPU	= 1		@ comment out to not use the MPU
native_usb	= 1		@ comment out to assemble without usb support
@onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem

/* ===== CONFIGURATION ====== */
@ ----- LEDs / BUTTON -------
LEDPINSEL	= ioportf_base	@ LED IO function control is on I/O Port F
LEDIO		= ioportf_base	@ LED on/off control is on I/O Port F
REDLED		= (1 << 1)	@ PF1 RGB LED, red   line
YELLED		= (1 << 2)	@ PF2 RGB LED, blue  line
GRNLED		= (1 << 3)	@ PF3 RGB LED, green line
BOOTOVERRID_PRT	= ioportf_base	@ Boot-override (SW1) is on I/O Port F
BOOTOVERRID_BUT	= 4		@ Boot-override is PF4
ENABLE_PORTS	= (1 << 5)	@ Power up port F (A=0, B=1, ...) for LEDs/BUTN
@ --------- SD card ---------
sd_is_on_spi	= 1
sd_spi		= ssi0_base	@ SD card is on SSI0
sd_spi_gpio	= ioporta_base	@ SD card SSI0 I/O port A PA2,4,5=CLK,MISO,MOSI
sd_cs_gpio	= ioporta_base	@ SD card chip-select is on I/O port A pins
sd_cs		= 1 << (3 + 2)	@ SD card chip-select PA3 pin (the 3 in (3+2))
@ --------- FREQs -----------
UART0_IDIV	= 43		@ integer    divisor for 115200 baud at 80 MHz
UART0_FDIV	= 26		@ fractional divisor for 115200 baud at 80 MHz
SYSTICK_RELOAD	= 80*10000 - 1	@ systick reload for 10ms interrupts at 80 MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000	@ start of on-chip RAM
RAMTOP		= 0x20008000	@ (32 kB)
@ --------- BUFFERS --------
RBF_size	= 0x0800	@ READBUFFER  size for tag as bytevector (2KB)
WBF_size	= 0x0800	@ WRITEBUFFER size for tag as bytevector (2KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x00010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x0003f000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x00011000	@ 68 KB in flash (after 2x2x1KB file pages+code)
LIB_TOP_PAGE	= 0x00040000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80




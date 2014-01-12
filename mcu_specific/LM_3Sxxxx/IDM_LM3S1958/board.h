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
IDM_LM3S1958	= 1		@ Luminary Micro 3.5in LCD Int.Disp.Mod.LM3S1958

/* ======= OPTIONS ========== */
enable_MPU	= 1		@ comment this line out to not use the MPU
onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem

/* ===== CONFIGURATION ====== */
@ ----- LEDs / BUTTON ------
LEDPINSEL	= ioportg_base	@ LED IO function control is on I/O Port G
LEDIO		= ioportg_base	@ LED on/off control is on I/O Port G
REDLED		= GRNLED	@ aliased to grnled
YELLED		= GRNLED	@ aliased to grnled
GRNLED		= 0x04		@ PG2 (the only board LED except for status-type)
BOOTOVERRID_PRT	= ioportg_base	@ Boot-override (PG3, Up-button) is on I/O Port G
BOOTOVERRID_BUT	= 3		@ Boot-override is PG3
ENABLE_PORTS	= (1 << 6)	@ Power up port G (A=0, B=1, ...) for LEDs/BUTN
@ --------- SD card ---------
sd_is_on_spi	= 1		@ SD card is on SPI(SSI) interface
sd_spi		= ssi1_base	@ SD card is on SSI1
sd_spi_gpio	= ioporte_base	@ SD card SSI0 I/O port E, PE0,2,3=CLK,MISO,MOSI
sd_cs_gpio	= ioporte_base	@ SD card chip-select is on I/O port E pins
sd_cs		= 1 << (1 + 2)	@ SD card chip-select on PE1 (the 1 in (1 + 2))
@ --------- FREQs -----------
@UART0_IDIV	= 325		@ integer    divisor for   9600 baud at 50 MHz
@UART0_FDIV	=  33		@ fractional divisor for   9600 baud at 50 MHz
UART0_IDIV	=  27		@ integer    divisor for 115200 baud at 50 MHz
UART0_FDIV	=   8		@ fractional divisor for 115200 baud at 50 MHz
SYSTICK_RELOAD	= 50*10000 - 1	@ systick reload for 10ms interrupts at 50 MHz
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000	@ start of on-chip RAM
RAMTOP		= 0x20010000	@ (64kB)
@ --------- BUFFERS --------
RBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x00010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x0003fC00	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 256		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x00010800	@ 66KB into flash (after 2x1 KB file pages+code)
LIB_TOP_PAGE	= 0x00040000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80




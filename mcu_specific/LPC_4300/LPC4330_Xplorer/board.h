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
LPC4330_Xplorer	= 1		@ NGX LPC4330-Xplorer / NXP LPC4330

/* ======= OPTIONS ========== */
hardware_FPU	= 1		@ comment out to use soft float (no FPU use)
enable_MPU	= 1		@ comment out to not use the MPU
native_usb	= 1		@ comment out to exclude usb support
onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem
upload_via_DFU	= 1		@ comment out to upload to SPIFI via JTAG
run_in_bank2	= 1		@ comment out to run core from 0x10000000

/* ===== CONFIGURATION ====== */
@ --------- LEDs -----------
LEDPINSEL	= SCU_SFSP2_n	@ LED pin func ctl P2_11/12(A9/B9)-GPIO1[11/12]
LEDIO		= io1_base	@ LED on/off pins are on GPIO1[n]
REDLED		= 1 << 11	@ Blue  LED on GPIO1[11]
YELLED		= GRNLED	@ aliased
GRNLED		= 1 << 12	@ Green LED on GPIO1[12]
@ ------ Native USB --------
usb_queue_heads	= 0x20004000	@ USB queue heads stored in 3rd RAM bank
@ --------- SD card ---------
sd_is_on_mci	= 1		@ SD card is on sd/mmc interface
sd_mci		= mmc_base	@ base address of sd/mmc interface
@ --------- FREQs -----------
UART0_DIV_L	= 110		@ divisor low  byte, 115200 baud, pclk = 204 MHz
UART0_DIV_H	= 0		@ divisor high byte, 115200 baud, pclk = 204 MHz
SYSTICK_RELOAD	= 204*10000 - 1	@ systick reload for 10ms interrupts at 204 MHz
@ --------- RAM ------------
.ifdef run_in_bank2
  RAMBOTTOM	= 0x10000000	@ heap in on-chip RAM, bank 1 (code in bank 2)
  RAMTOP	= 0x10020000	@ LPC 4330 (128 kB)
.else
  RAMBOTTOM	= 0x10080000	@ heap in on-chip RAM, bank 2 (code in bank 1)
  RAMTOP	= 0x10092000	@ LPC 4330 (72 kB)
.endif
@ --------- BUFFERS --------
.ifdef run_in_bank2
  BUFFER_START	= 0x10090000+4	@ buffers in on-chip RAM bank 2, after 64KB code
.else
  BUFFER_START	= 0x10010000+4	@ buffers in on-chip RAM bank 1, after 64KB code
.endif
RBF_size	= 0x1000	@ READBUFFER  size for tag as bytevector (4KB)
WBF_size	= 0x0C00	@ WRITEBUFFER size for tag as bytevector (3KB)
I2C0ADR		= i2c0_base + i2c_address
@ --------- FLASH ----------
F_START_PAGE	= 0x14010000	@ SPIFI (above 64KB stored code)
F_END_PAGE	= 0x143F0000	@ top of 4 MB SPIFI, minus top 64KB crnch sector
F_PAGE_SIZE	= 256		@ size of pages used for files
@ uncomment the following 3 lines to store and run installed libraries in SPIFI
@ (when commented, libs install to top of heap RAM but do not survive reboots)
SHARED_LIB_FILE = 1		@ library and file space are both in SPIFI
LIB_BOTTOM_PAGE = 0x14030000	@ 192KB into SPIFI (after 3x64KB file sects+code
LIB_TOP_PAGE	= 0x14400000	@ top of SPIFI (4 MB)

@-------10--------20--------30--------40--------50--------60--------70--------80





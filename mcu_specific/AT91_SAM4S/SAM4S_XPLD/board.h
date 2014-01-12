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
SAM4S_XPLD	= 1		@ Atmel/Embest SAM4S-Xplained / AT91-SAM4S16C

/* ======= OPTIONS ========== */
enable_MPU	= 1		@ comment out to not use the MPU
native_usb	= 1		@ comment out to assemble without usb support
@onboard_SDFT	= 1		@ comment out to exclude SD card file subsystem
uart_not_usart	= 1		@ uncomment to use uart0,1 as scheme uarts
switch_uart01	= 1		@ uncomment to use uart1/usart1 as scheme uart0
external_ram	= 1		@ uncomment to enable ISSI external RAM: NCS0,1
@run_at_84_MHz	= 1		@ uncomment to run at 84 MHz (default is 120MHz)

/* ===== CONFIGURATION ====== */
@ ----- LEDs / BUTTON -------
LEDPINSEL	= pioc_base	@ where to write 1 to make pin a gpio
LEDIO		= pioc_base
REDLED		= (1 << 10)	@ PC10 (actually yellow)
YELLED		= (1 << 17)	@ PC17
GRNLED		= YELLED	@ aliased to YELLED
LED_PIO_ID	= 13		@ PIO C (peripheral ID = 13)
BOOTOVERRID_PRT	= pioa_base	@ Boot-override (BP2) is on I/O Port A
BOOTOVERRID_BUT	= 5		@ Boot-override button is on pin PA5
BUT_PIO_ID	= 11		@ PIO A (peripheral ID = 11)
@ --------- SD card ---------
sd_is_on_spi	= 1		@ if used, SD card will be on SPI interface
sd_spi		= spi0_base	@ SD card is on SPI0
sd_spi_gpio	= pioa_base	@ SD card port A PA11,12,13,14=SS,MISO,MOSI,CLK
@ --------- FREQs -----------
.ifndef run_at_84_MHz
 PLL_parmsA	= 0x20273F02	@ XTal=12 MHz, PLLA x40/2 -> 120x2 MHz
 PLL_parmsB	= 0x000F3F02	@ XTal=12 MHz, PLLB x16/2 ->  48x2 MHz for USB
 FLSH_WTSTA 	= 5		@ flash wait states for 120MHz: 5 =>6 cycles r/w
 UART0_DIV	= 65		@ uart0 frequency div for 115200 bauds at 120MHz
 SYSTICK_RELOAD	= 120*10000 - 1	@ systick reload for 10ms interrupts at 120 MHz
 SPI_LS_DIV	= 255		@ SPI low  speed SCBR: 120 MHz/255 = 470 KHz
 SPI_HS_DIV	= 10		@ SPI high speed SCBR: 120 MHz/10  =  12 MHz
 SMC_SETUP	= 0x00000100	@ ISSI 66WV51216DBLL, 55ns r/w setup clock ticks
 SMC_PULSE	= 0x07070607	@ ISSI 66WV51216DBLL, 55ns r/w pulse clock ticks
 SMC_CYCLE	= 0x00070007	@ ISSI 66WV51216DBLL, 55ns r/w cycle clock ticks
.else
 PLL_parmsA	= 0x201b3f02	@ XTal=12 MHz, PLLA x28/2 ->  84x2 MHz
 PLL_parmsB	= 0x000f3f02	@ XTal=12 MHz, PLLB x16/2 ->  48x2 MHz for USB
 FLSH_WTSTA 	= 3		@ flash wait states for  84MHz: 3 =>4 cycles r/w
 UART0_DIV	= 46		@ uart0 frequency div for 115200 bauds at  84MHz
 SYSTICK_RELOAD	= 84*10000 - 1	@ systick reload for 10ms interrupts at  84 MHz
 SPI_LS_DIV	= 255		@ SPI low  speed SCBR:  84 MHz/255 = 329 KHz
 SPI_HS_DIV	= 10		@ SPI high speed SCBR:  84 MHz/10  =   8.4 MHz
 SMC_SETUP	= 0x00000100	@ ISSI 66WV51216DBLL, 55ns r/w setup clock ticks
 SMC_PULSE	= 0x05050405	@ ISSI 66WV51216DBLL, 55ns r/w pulse clock ticks
 SMC_CYCLE	= 0x00050005	@ ISSI 66WV51216DBLL, 55ns r/w cycle clock ticks
.endif
@ --------- RAM ------------
RAMBOTTOM	= 0x20000000	@ bottom of RAM
RAMTOP		= 0x20020000	@ AT91-SAM4S16C (128KB)
@ --------- BUFFERS --------
RBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
WBF_size	= 0x0800	@ READBUFFER size for tag as bytevector (2KB)
@ --------- FLASH ----------
F_START_PAGE	= 0x00010000	@ address of 1st page of FLASH (for files)
F_END_PAGE	= 0x00070000	@ page after last page of FLASH used for files
F_PAGE_SIZE	= 512		@ size of pages used for files
SHARED_LIB_FILE	= 1		@ library and file space share on-chip flash
LIB_BOTTOM_PAGE	= 0x00030000	@ 192KB into flash (after 2x64KB fil sects+code)
LIB_TOP_PAGE	= 0x00080000	@ end of flash

@-------10--------20--------30--------40--------50--------60--------70--------80





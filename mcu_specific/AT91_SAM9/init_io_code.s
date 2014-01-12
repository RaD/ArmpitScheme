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

hwinit:	@ pre-set common values
	set	r0,  #0
	set	r1,  #1
	set	r2,  #2
	set	r3,  #3
	set	r4,  #4

	@ initialization of PLLA and main clock
	@ (Note: BootROM pre-sets PLLB to 96/48MHz for USB, disables watchdog and enables reset button)
	ldr	r6,  =PMC_base
	ldr	r7,  =PLLA_parms
	str	r7,  [r6,  #0x28]	@ PMC_PLLAR  <- 200.1 MHz for CPU
pllwt1:	ldr	r7,  [r6,  #0x68]	@ r7 <- content of PMC_SR (status register)
	tst	r7,  #0x02		@ is PLLA locked (PMC_LOCKA bit set)?
	beq	pllwt1			@	if not, jump to keep waiting
	set	r7,  #0x100
	orr	r7,  r7, #0x002
	str	r7,  [r6,  #0x30]	@ PMC_MCKR  <- set master clock to PLLA/2 = 100 MHz
pllwt3:	ldr	r7,  [r6,  #0x68]	@ r7 <- content of PMC_SR (status register)
	tst	r7,  #0x08		@ is master clock ready (PMC_MCKRDY set)?
	beq	pllwt3			@	if not, jump to keep waiting

	@ initialize SDRAM, 2 x K4S561632J-UC75 for 32-bit data bus, CAS 2 at 100 MHz
	@ (see also LPC2478-STK, LPC-H2888)
	ldr	r6,  =pioc_base
	ldr	r7,  =0xffff0000
	str	r7,  [r6,  #0x04]	@ PIOC_PDR  <- disable pio function for PC16-31
	str	r7,  [r6,  #0x60]	@ PIOC_PUDR <- disable pull-up for PC16-31
	str	r7,  [r6,  #0x70]	@ PIOC_ASR  <- select Periph A function, SDRAM D16-31, for PC16-31
	ldr	r6,  =0xffffee00	@ r6  <- MATRIX base address
	ldr	r7,  [r6,  #0x30]	@ r7  <- EBI_CSA
	orr	r7,  r7, #0x0002
	orr	r7,  r7, #0x0100
	str	r7,  [r6,  #0x30]	@ EBI_CSA  <- allocate CS1A to SDRAM, no pull-up on D0-15
	ldr	r6,  =0xffffea00	@ r6  <- SDRAMC base address
	ldr	r7,  =0x75227159	@ r7  <- txsr=7(tras+trp),tras=5(45ns),trcd=2(20ns),trp=2(20ns),
					@	 trc=7(65ns),twr=1(trdl=1@100MHz),32bt,cas2,4bk,13row,9col
	str	r7,  [r6,  #0x08]	@ SDRAMC_CR <- configure SDRAM for 100 MHz
	set	r7,  #0x010000
ramwt1:	@ wait a bit (>= 200 us)
	subs	r7, r7, #1
	bne	ramwt1
	set	r8,  #0x20000000	@ r8  <- SDRAM base address (normally RAMBOTTOM)
	str	r1,  [r6,  #0x00]	@ SDRAMC_MR <- 1, NOP command
	str	r0,  [r8]		@ issue command
	str	r2,  [r6,  #0x00]	@ SDRAMC_MR <- 2, Precharge-All command
	str	r0,  [r8]		@ issue command
	set	r7,  #8
ramlp1:	@ auto-refresh loop
	str	r4,  [r6,  #0x00]	@ SDRAMC_MR <- 4, Auto-Referesh command
	str	r0,  [r8]		@ issue command
	subs	r7,  r7, #1
	bne	ramlp1
	str	r3,  [r6,  #0x00]	@ SDRAMC_MR <- 3, Load-Mode-Register command
	str	r0,  [r8]		@ issue command
	str	r0,  [r6,  #0x00]	@ SDRAMC_MR <- 0, Normal-Mode command
	str	r0,  [r8]		@ issue command
	set	r7,  #0x0300
	str	r7,  [r6,  #0x04]	@ SDRAMC_TR <- refresh at 7.68us (768x10ns < 64ms/8K = 7.81us)

	@ initialize FLASH, 1 x K9F4G08U0A-PCB0 (cf. k9xxg08uxa.pdf and ATMEL doc6255.pdf)
	@ PC0/NANDOE #RE, PC1/NANDWE #WE, PC14 #CE, PC15 Rdy/#Bsy, A21/NANDCLE CLE, A22/NANDALE ALE, D0-7 i/o
	ldr	r6,  =PMC_base
	set	r7,  #(1 << 4)
	str	r7,  [r6,  #0x10]	@ PMC_PCER <- Enable clock/power for PIOC
	ldr	r6,  =pioc_base
	set	r7,  #0x03
	str	r7,  [r6,  #0x04]	@ PIOC_PDR <- Disable the GPIO for PC0, PC1
	str	r7,  [r6,  #0x70]	@ PIOC_ASR <- Select NAND OE-WE function (Periph A) for PC0-1
	set	r7,  #(1 << 14)
	str	r7,  [r6,  #0x10]	@ PIOC_OER  <- set CS (PC14) as gpio output
	str	r7,  [r6,  #io_set]	@ PIOC_SODR <- set CS (PC14) high (de-select NAND chip)
	ldr	r6,  =0xffffee00	@ r6  <- MATRIX base address
	ldr	r7,  [r6,  #0x30]	@ r7  <- EBI_CSA
	orr	r7,  r7, #0x08
	str	r7,  [r6,  #0x30]	@ EBI_CSA  <- allocate CS3A to SmartMedia/NAND
	ldr	r6,  =0xffffec00	@ r6  <- SMC base address
	ldr	r7,  =0x01010101
	str	r7,  [r6,  #0x30]	@ SMC_SETUP_3 <- 2 clocks for RE/WE setup (12 ns)
	ldr	r7,  =0x03030303
	str	r7,  [r6,  #0x34]	@ SMC_PULSE_3 <- 2 clocks for RE/WE pulse (12 ns)
	ldr	r7,  =0x05050505
	str	r7,  [r6,  #0x38]	@ SMC_CYCLE_3 <- 5 clocks for Setup+Pulse+Hold (10 ns Hold)
	ldr	r7,  =0x020003
	str	r7,  [r6,  #0x3c]	@ SMC_MODE_3  <- RE/WE ctrl, 8-bit bus, 2+1 clk before bus release

	@ select FLASH and wait for ready
	ldr	r7,  =pioc_base
	set	r6,  #(1 << 14)
	str	r6,  [r7, #io_clear]
wflrdy:	ldr	r6,  [r7,  #io_state]
	tst	r6,  #(1 << 15)
	beq	wflrdy

	@ copy file FLASH contents into shadow RAM
	ldr	r8,  =F_START_PAGE
cpyfl0:	@ configure flash for read operation with RAM address in r8
	ldr	r7,  =#0x40200000	@ sv1 <- command-write address (CS3) for FLASH
	set	r6,  #0x00		@ rvb <- flash read command
	strb	r6,  [r7]		@ set page read command in FLASH
	eor	r7,  r7,  #(3 << 21)	@ sv1 <- address-write address (CS3) for FLASH
	set	r6,  #0x00		@ rvb <- 0, start offset for write
	strb	r6,  [r7]		@ set start byte in page address low = Col Adr.1 = 0 in FLASH
	strb	r6,  [r7]		@ set start byte in page address high (4 bits, Col Adr.2) in FLASH
	lsr	r6,  r8,  #11
	and	r6,  r6,  #0xff
	strb	r6,  [r7]		@ set page-in-block (b0-5) and block addr low (Row Adr.1) in FLASH
	lsr	r6,  r8,  #19
	and	r6,  r6,  #0x1f
	strb	r6,  [r7]		@ set block address middle (Row Adr. 2) in FLASH
	set	r6,  #0x00
	strb	r6,  [r7]		@ set block address high (4 bits, Row Adr. 3) in FLASH
	eor	r7,  r7,  #(3 << 21)	@ sv1 <- command-write address (CS3) for FLASH
	set	r6,  #0x30		@ rvb <- #x30, page read confirm command
	strb	r6,  [r7]		@ set page read confirm in FLASH
	bic	r7,  r7,  #(3 << 21)	@ r7  <- data-read/write address (CS3) for FLASH
	@ read data
	ldr	r9,  =pioc_base		@ r9  <- Rdy/~Bsy status gpio
cpyfl1:	ldr	r6,  [r9,  #io_state]
	tst	r6,  #(1 << 15)
	beq	cpyfl1
	ldr	r6,  [r7]
	str	r6,  [r8]
	add	r8,  r8, #4
	tst	r8,  #0xff
	tsteq	r8,  #0x0700
	bne	cpyfl1
	@
	@ The copying done here takes 90 seconds to get 16 MB from flash to RAM.
	@ That's a long time to wait for startup.
	@ Currently, 128 blocks x 64 pages per block (each page is 2 KB) are read.
	@ So the rate is 21 us per 32-bit word, 11 ms per page, 700 ms per block, 190 KB per second.
	@ I would have expected 100 us per page at most (factor of 100 faster).
	@ Maybe we could skip reading of pages in blocks whose 1st page starts
	@ with #xffffffff (i.e. nothing written to that block yet).
	@ Or, skip to next block on any page that starts with #xffffffff.
	@ The shadow RAM would still need to be initialized however (for the
	@ remaining pages in the skipped block).
	@ This RAM initialization might be done before cpyfl0.
	@ Also, less than 16 MB of flash could be used.
	@
	@ Maybe reading the Ready/Busy pin for each word slows things down a lot?
	@
	@ Another issue is that we don't check for bad flash blocks.
	@ Samsung documentation indicates that bad blocks are possible even
	@ in a brand new FLASH chip of K9F4... type.
	@ Possibly, for a bad block, the shadow RAM would be written with all 0's
	@ or some other indicator to avoid using those pages for new files.
	@ Also, bad blocks should probably not be erased in flash (this removes
	@ the invalid block indicators -- it's too late for my chip).
	@ It is not 100% clear how fsc/file-crunch would deal with that though
	@ (if it is ever needed with 16 MB).
	@
	@ The user may be advised to use the SD-card, rather than NAND flash to
	@ store user files.
	@ Meanwhile, Armpit Scheme's (erase) affects only the lower 16 MB of NAND
	@ flash (out of 512 MB) so the possible erasure of invalid blocks (or their
	@ info) affects only the bottom of the chip (and block 0 is guaranteed good).
	@
	@ check for end of file flash
	ldr	r7,  =F_END_PAGE
	eq	r7,  r8
	bne	cpyfl0
	@ de-select FLASH
	ldr	r7,  =pioc_base
	set	r6,  #(1 << 14)
	str	r6,  [r7,  #io_set]
	
	@ initialization of gpio pins for LEDs
	ldr	r6,  =PMC_base
	str	r4,  [r6,  #0x10]	@ PMC_PCER -- Enable clock/power for LED gpio (PIOA)
	ldr	r6,  =LEDPINSEL
	ldr	r7,  =ALLLED
	str	r7,  [r6]		@ set gpio function for led
	ldr	r6,  =LEDIO
	str	r7,  [r6,  #io_dir]	@ set led as outputs

	@ initialization of uart 
	@ (Note: BootROM enables DBGU uart at 115200, 8N1, need to change freq and re-connect pins)
	ldr	r6, =uart0_base
	ldr	r7, =0xffffffff
	str	r7, [r6, #0x0c]		@ disable all uart interrupts
	ldr	r7,  =UART0_DIV
	str	r7,  [r6,  #0x20]	@ US0_BRGR -- Set Baud Rate to 9600 (CLOCK/UART0_DIVx16)
	ldr	r7,  =0x0202
	str	r7,  [r6,  #0x0120]	@ US0_PTCR -- Disable DMA transfers (just in case)
	ldr	r6,  =pioa_base
	set	r7,  #0x600
	str	r7,  [r6,  #0x04]	@ PIOA_PDR -- Disable the GPIO for uart0 pins (bits 9, 10)
	str	r7,  [r6,  #0x70]	@ PIOA_ASR -- Select uart0 function (Periph A, bits 9,10)
	ldr	r6, =uart0_base
	str	r1,  [r6,  #0x08]	@ US0_IER  -- Enable RxRDY interrupt
	set	r7,  #0x50
	str	r7,  [r6]		@ US0_CR   -- Enable uart0 RX and TX (bits 4, 6)

	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	r6,  =I2C0ADR		@ r6  <- I2C0 mcu-address address
	set	r7,  #mcu_id
	str	r7,  [r6]		@ I2C0ADR <- set mcu address
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB_CONF <- USB device is not yet configured

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

	@ configure pins and SPI0 for SD-card
	@ (Note: BootROM disables spi0 after loading code, otherwise we'd have to make
	@	 sure PA.3 is reverted from NCS0 to gpio input to avoid conflict)
	@ clock (power-up) the SPI peripheral
	ldr	r6, =PMC_base
	set	r7, #(1 << 12)
	str	r7, [r6, #0x10]
	@ set CS pin to output and set it high (de-select SD)
	ldr	r6, =sd_cs_gpio
	set	r7, #sd_cs
	str	r7, [r6, #0x10]		@ PIOA_OER  <- set CS pin as output
	str	r7, [r6, #0x30]		@ PIOA_SODR <- set SD CS pin high (deselect SD card)
	@ configure SPI0 pins to Peripheral A (PA.0-2 as MISO, MOSI, CLK)
	ldr	r6, =sd_spi_gpio
	set	r7, #0x07
	str	r7, [r6, #0x04]		@ PIO_PDR <- disable GPIO function on SPI0 pins
	str	r7, [r6, #0x70]		@ PIO_ASR <- enable Peripheral A function on SPI0 pins
	@ low-speed (approx 400 KHz)
	ldr	r6, =sd_spi
	set	r7, #0x81
	str	r7, [r6, #0x00]		@ SPI_CR <- reset SPI
	set	r7, #0x01
	str	r7, [r6, #0x00]		@ SPI_CR <- enable SPI
	set	r7, #0x01
	str	r7, [r6, #0x04]		@ SPI_MR <- enable master mode
	set	r7, #0xfa00
	orr	r7, r7, #0x02
	str	r7, [r6, #0x30]		@ SPI_CSR0 <- 100 MHz / 250 = 400 KHz, POL/PHA=0

  .endif @ sd_is_on_spi

.endif	@ onboard_SDFT
	

.ifdef	native_usb

	@ initialization of USB device controller -- **** MUST BE LAST ****
	@ (Note: internal 1.5 K pull-up, bit 30 in USB_PUCR, #xffffee34, is set by BootROM)
	ldr	r6,  =USB_LineCoding
	ldr	r7,  =115200
	str	r7,  [r6]
	set	r7,  #0x00080000
	str	r7,  [r6,  #0x04]
	ldr	r6,  =USB_CHUNK
	str	r0,  [r6]
	ldr	r6,  =USB_ZERO
	str	r0,  [r6]
	ldr	r6,  =USB_CONF
	str	r0,  [r6]
	ldr	r6,  =PMC_base
	set	r7,  #0x0080
	str	r7,  [r6]		@ PMC_SCER  -- enable USB clock
	set	r7,  #(1 << 10)
	str	r7,  [r6,  #0x10]	@ PMC_PCER  -- enable USB (periph #10 = bit 10)
	ldr	r6,  =usb_base
	ldr	r7,  =0xffff
	str	r7,  [r6,  #0x20]	@ UDP_ICR   -- clear USB interrupts
	@ configure control endpoint
	ldr	r6,  =usb_base
	set	r7,  #0x8000
	str	r7,  [r6,  #0x30]	@ UDP_CSR0  -- r7  <- enable, Control endpoint
	set	r7,  #0x0100
	str	r7,  [r6,  #0x08]	@ UDP_FADDR -- enable transfers on address 0
	ldr	r7,  =0xFF0F
	str	r7,  [r6,  #0x10]	@ UDP_IER   -- enable USB interrupts (0-3)
	str	r0,  [r6,  #0x74]	@ UDP_TXVC  -- enable transceiver


.endif	@ native_usb

	@ end of the hardware initialization
	set	pc,  lnk


/*------------------------------------------------------------------------------
@ AT91_SAM9
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/

	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

FlashInitCheck: @ return status of flash init enable/override gpio pin (PA27=BP3) in r6/rva
	ldr	rva, =pioa_base			@ 
	ldr	rva, [rva, #io_state]
	and	rva, rva, #(1 << 27)		@ rva <- status of boot override pin, PA27, BP3
	set	pc,  lnk


wrtfla:	@ write to flash, sv2 is page address, sv4 is file descriptor
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5,  env, dts, glv} @ store scheme registers onto stack
	@ copy buffer data from file descriptor (sv4) (RAM) to RAM and FLASH buffer (sv2)
	vcrfi	sv3, sv4, 3		@ sv3 <- buffer address
	@ select FLASH
	ldr	rvb, =pioc_base
	set	rvc, #(1 << 14)
	str	rvc, [rvb, #io_clear]
	@ configure flash for program operation
	ldr	sv1, =#0x40200000	@ sv1 <- command write address (CS3) for FLASH
	set	rvb, #0x80		@ rvb <- flash write command
	strb	rvb, [sv1]		@ set page program command in FLASH
	eor	sv1, sv1, #(3 << 21)	@ sv1 <- address write address (CS3) for FLASH
	set	rvb, #0x00		@ rvb <- 0, start offset for write
	strb	rvb, [sv1]		@ set start byte-in-page address low  = Col Adr.1 = 0 in FLASH
	strb	rvb, [sv1]		@ set start byte-in-page address high = Col Adr.2 = 0 in FLASH
	lsr	rvb, sv2, #11
	and	rvb, rvb, #0xff
	strb	rvb, [sv1]		@ set page-in-block (b0-5) & block addr low (Row Adr.1) in FLASH
	lsr	rvb, sv2, #19
	and	rvb, rvb, #0x1f
	strb	rvb, [sv1]		@ set block address middle (Row Adr. 2) in FLASH
	set	rvb, #0x00
	strb	rvb, [sv1]		@ set block address high (4 bits, Row Adr. 3) in FLASH
	eor	sv1, sv1, #(1 << 22)	@ sv1 <- data write address (CS3) for FLASH
	@ write data
	set	rvc, #0
	ldr	rva, =pioc_base		@ rva <- Rdy/~Bsy status gpio
wrtfl1:	ldr	rvb, [rva, #io_state]
	tst	rvb, #(1 << 15)
	beq	wrtfl1
	ldrb	rvb, [sv3, rvc]
	strb	rvb, [sv2, rvc]
	strb	rvb, [sv1]
	add	rvc, rvc, #1
	eq	rvc, #F_PAGE_SIZE
	bne	wrtfl1
	@ complete write, check status
	orr	sv1, sv1, #(1 << 21)	@ sv1 <- command write address (CS3) for FLASH
	set	rvb, #0x10		@ rvb <- flash write confirm command
	strb	rvb, [sv1]		@ set confirm command in gpmc
	bl	flstwt
	@ de-select FLASH
	ldr	rvb, =pioc_base
	set	rvc, #(1 << 14)
	str	rvc, [rvb, #io_set]
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}	@ restore scheme registers from stack
	orr	fre, fre, #0x02			@ fre <- fre-ptr de-reserved
	swi	run_normal			@ enable interrupts (user mode)
	set	pc,  lnk			@ return

flstwt:	@ get flash status
	@ on entry:	sv1 <- command write address (CS3) for FLASH
	@ on entry:	sv1 <- data read/write address (CS3) for FLASH
	@ modifies:	rvb, sv1
	@ wait for flash ready
	ldr	rvb, =pioc_base		@ rvb <- Rdy/~Bsy status gpio
	ldr	rvb, [rvb, #io_state]
	tst	rvb, #(1 << 15)
	beq	flstwt
	set	rvb, #0x70
	strb	rvb, [sv1]		@ set get status command in FLASH
	bic	sv1, sv1, #(1 << 21)	@ sv1 <- data read / write address (CS3) for FLASH
	ldrb	rvb, [sv1]		@ rvb <- flash status
	set	pc,  lnk

ersfla:	@ erase flash sector that contains page address in sv2
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {sv1}			@ store scheme registers onto stack
	@ select FLASH
	ldr	rvb, =pioc_base
	set	rvc, #(1 << 14)
	str	rvc, [rvb, #io_clear]
	@ prepare for flash block-erase operation
	ldr	sv1, =#0x40200000	@ sv1 <- command write address (CS3) for FLASH
	set	rvb, #0x60		@ rvb <- flash erase-block command
	strb	rvb, [sv1]		@ set page program command in FLASH
	eor	sv1, sv1, #(3 << 21)	@ sv1 <- address write address (CS3) for FLASH
	lsr	rvb, sv2, #11
	and	rvb, rvb, #0xff
	strb	rvb, [sv1]		@ set page-in-block (b0-5) & block addr low (Row Adr.1) in FLASH
	lsr	rvb, sv2, #19
	and	rvb, rvb, #0x1f
	strb	rvb, [sv1]		@ set block address middle (Row Adr. 2) in FLASH
	set	rvb, #0x00
	strb	rvb, [sv1]		@ set block address high (4 bits, Row Adr. 3) in FLASH
	@ comfirm erase
	eor	sv1, sv1, #(3 << 21)	@ sv1 <- command write address (CS3) for FLASH
	set	rvb, #0xd0		@ rvb <- flash erase confirm command
	strb	rvb, [sv1]		@ set confirm command in gpmc
	@ erase corresponding shadow RAM
	set	rvc, #0
	mvn	rvb, rvc
ersfl1:	str	rvb, [sv2, rvc]		@ store #xffffffff in RAM
	add	rvc, rvc, #4
	eq	rvc, #0x20000		@ 128kB / block
	bne	ersfl1
	@ check flash status/wait for flash ready
	bl	flstwt
	@ de-select FLASH
	ldr	rvb, =pioc_base
	set	rvc, #(1 << 14)
	str	rvc, [rvb, #io_set]
	@ finish up
	ldmfd	sp!, {sv1}		@ restore scheme regs from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk} @ restore scheme regs from stack
	orr	fre, fre, #0x02		@ fre <- fre-ptr de-reserved
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return
	

	
.ltorg	@ dump literal constants here => up to 4K of code before and after this point


/*------------------------------------------------------------------------------
@
@ 2- SD card low-level interface
@
@-----------------------------------------------------------------------------*/

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

_func_	
sd_cfg:	@ configure spi speed (high), phase, polarity
	@ modifies:	rva, rvb
	ldr	rva, =sd_spi
	set	rvb, #0x81
	str	rvb, [rva, #0x00]	@ SPI_CR <- reset SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x00]	@ SPI_CR <- enable SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x04]	@ SPI_MR <- enable master mode
	set	rvb, #0x0600
	orr	rvb, rvb, #0x02
	str	rvb, [rva, #0x30]	@ SPI_CSR0 <- 100 MHz / 6 = 16.67 MHz, POL/PHA=0
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	@ modifies:	rva, rvb
	ldr	rva, =sd_spi
	set	rvb, #0x81
	str	rvb, [rva, #0x00]	@ SPI_CR <- reset SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x00]	@ SPI_CR <- enable SPI
	set	rvb, #0x01
	str	rvb, [rva, #0x04]	@ SPI_MR <- enable master mode
	set	rvb, #0xfa00
	orr	rvb, rvb, #0x02
	str	rvb, [rva, #0x30]	@ SPI_CSR0 <- 100 MHz / 250 = 400 KHz, POL/PHA=0
	set	pc,  lnk

_func_	
sd_sel:	@ select SD-card subroutine
	@ modifies:	rva, rvb
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_clear]	@ clear CS pin
	set	pc,  lnk
	
_func_	
sd_dsl:	@ de-select SD-card subroutine
	@ modifies:	rva, rvb
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_set]	@ set CS pin
	set	pc,  lnk
	
_func_	
sd_get:	@ sd-spi get sub-routine
	@ modifies:	rva, rvb
	set	rvb, #0xff
_func_	
sd_put:	@ sd-spi put sub-routine
	@ modifies:	rva, rvb
	ldr	rva, =sd_spi
	ldr	rva, [rva, #spi_status]	@ ssta
	tst	rva, #spi_txrdy
	beq	sd_put
	ldr	rva, =sd_spi
	and	rvb, rvb, #0xff
	str	rvb, [rva, #spi_thr]	@ sdtx (sdat)
sd_gpw:	@ wait
	ldr	rvb, [rva, #spi_status]	@ ssta
	tst	rvb, #spi_rxrdy		@ sdrr
	beq	sd_gpw
	ldr	rvb, [rva, #spi_rhr]	@ sdrx (sdat)
	and	rvb, rvb, #0xff
	set	pc, lnk

  .endif @ sd_is_on_spi

.endif	@ 	onboard_SDFT
	
@
@ 2- I2C hardware and Interrupt routines
@

.ifdef	include_i2c

hwi2cr:	@ write-out additional address registers, if needed
	@ modify interupts, as needed
	@ on entry:	sv5 <- i2c[0/1]buffer
	@ on entry:	r6  <- i2c[0/1] base address (also I2CONSET)
	@ interrupts are disabled throughout
	set	pc,  lnk
	
hwi2ni:	@ initiate i2c read/write, as master
	@ on entry:	r6  <- i2c base address
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [rva, #i2c_iclear]	@ disable all TWI interrupts
	set	rvb, #0x05		@ r7  <- TXRDY and TXCOMP
	str	rvb, [rva, #i2c_ienable] @ enable TXRDY and TXCOMP interrupts
	set	rvb, #4			@ r7  <- TWI enable bit
	str	rvb, [rva, #i2c_ctrl]	@ start transfer
	set	pc,  lnk

hwi2st:	@ get i2c interrupt status and base address
	@ on exit:	r6 <- i2c[0/1] base address
	@ on exit:	r7 <- i2c interrupt status
	ldr	rvb, [rva, #i2c_status]	@ r7  <- current status of TWI interface
	ldr	rva, [rva, #i2c_imask]	@ r6  <- TWI enabled Interrupt Mask
	and	rvb, rvb, rva		@ r7  <- asserted TWI interrupts (without potential spurious bits)
	ldr	rva, =i2c0_base		@ r6  <- address of Status Register (restored)
	set	pc,  lnk

hwi2cs:	@ clear SI
	set	pc,  lnk

i2c_hw_branch:	@ process interrupt
	eq	rvb, #0x05		@ Writing or Reading as Master -- bus mastered (txrdy and txcomp set)
	beq	i2c_hw_mst_bus
	tst	rvb, #0x0100		@ Writing or Reading as Master -- NAK received --  re-send byte
	bne	i2cnak
	tst	rvb, #0x04		@ Writing as Master -- slave ok to receive data (txrdy set)
	bne	i2c_wm_put
	tst	rvb, #0x02		@ Reading as Master -- new byte received (rxrdy set)
	bne	i2c_rm_get
	tst	rvb, #0x01		@ Writing or Reading as Master  -- transmission complete (txcomp set)
	bne	i2c_mst_end
	set	pc,  lnk

i2c_hw_mst_bus:	@ Reading or Writing as Master -- bus now mastered
	@ on entry:	sv1 <- i2c[0/1] data offset in glv
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	set	rvb, #0			@ r7  <- 0, number of bytes sent/received so far
	tbsti	rvb, sv2, 4		@ store number of bytes sent/received in i2c buffer
	@ store internal address bytes in TWI_IADR 
	set	rva, #i2c_iadr		@ r6  <- 0, offset to internal address in TWI_IADR
	tbrfi	sv4, sv2, 1		@ sv4 <- number of internal address bytes (scheme int)
	add	sv4, sv4, #0x20		@ sv4 <- additional number of address bytes (scheme int)
i2str0:	eq	sv4, #0x21		@ are we done writing additional address bytes?
	subne	sv4, sv4, #4		@	if not, sv4 <- address byt offset in i2cbuffer[8] (scheme int)
	ldrbne	rvb, [sv2, sv4, LSR #2]	@	if not, r7  <- address byte from i2cbuffer[8+offset]
	strbne	rvb, [sv3, rva]		@ 	if not, store next internal address byte in TWO_IADR
	addne	rva, rva,#1		@	if not, r6  <- offset to next internal address in TWI_IADR
	bne	i2str0			@	if not, jump to store next internal address byte
	@ set TWI_MMR to write/read to/from i2c address with appropriate number of internal address bytes
	tbrfi	rvb, sv2, 0		@ r7  <- address of mcu to wrt/rd dat to/from (scheme int{w}/float{r})
	tst	rvb, #0x02		@ is this a write operation?
	seteq	rva, #0x0000		@	if so,  r6  <- TWI r/w bit set to write, and  addrss of target
	setne	rva, #0x1000		@	if not, r6  <- TWI r/w bit set to read, and address of target
	lsr	rvb, rvb, #2		@
	orr	rva, rva, rvb, LSL #16	@
	tbrfi	rvb, sv2, 1		@ r7  <- number of internal address bytes (scheme int)
	lsr	rvb, rvb, #2		@ r7  <- number of internal address bytes (raw int)
	orr	rva, rva, rvb, LSL #8	@ r6  <- r/w and #internal address bytes
	str	rva, [sv3, #i2c_mode]	@ set r/w bit, #internal address bytes and target address in TWI MMR
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ deactivate interrupts
	beq	i2strw			@	if so,  jump to start a write
	@ start an i2c read
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to read
	cmp	rva, #2			@ are we reading just 1 byte?
	setmi	rvb, #1			@	if so,  r7  <- TXCOMP bit
	setpl	rvb, #2			@	if not, r7  <- TWI RXRDY bit
	str	rvb, [sv3, #i2c_ienable] @ enable TWI RXRDY interrupt
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to send/read
	cmp	rva, #2			@ are we reading just 1 byte?
	setmi	rvb, #3			@	if so,  r7  <- stop and start bits
	setpl	rvb, #1			@	if not, r7  <- start bit
	str	rvb, [sv3, #i2c_ctrl]	@ start transfer
	bl	gldon			@ turn led on
	b	i2cxit			@ exit
i2strw:	@ start an i2c write
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to send
	cmp	rva, #2			@ are we sending just 1 byte?
	setmi	rvb, #1			@	if so,  r7  <- TWI TXCOMP bit
	setpl	rvb, #4			@	if not, r7  <- TWI TXRDY bit
	orrpl	rvb, rvb, #0x0100	@	if not, r7  <- TXRDY and NAK bits
	str	rvb, [sv3, #i2c_ienable] @ enable TWI TXCOMP OR TXRDY interrupt
	bl	i2putc			@ jump to write 1st byte
	tbrfi	rva, sv2,  3		@ r6  <- number of bytes to send
	cmp	rva, #2			@ are we sending just 1 byte?
	setmi	rvb, #3			@	if so,  r7  <- stop and start bits
	strmi	rvb, [sv3, #i2c_ctrl]	@	if so,  start transfer
	bl	gldon			@ turn led on
	b	i2cxit
	
i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer or r12
	set	pc,  lr

i2pute:	@ Epilogue:	set completion status if needed
	tbrfi	rva, sv2, 3		@ r6  <- number of data bytes to send (raw int)
	tbrfi	rvb, sv2, 4		@ r7  <- number of data bytes sent (raw int)
	eq	rva, rvb		@ done sending?
	beq	i2cstp			@	if so,  jump to end transfer
	set	pc,  lnk

i2cnak:	@ re-send last byte
	tbrfi	rvb, sv2, 4		@ r7  <- number of data bytes sent (raw int)
	sub	rvb, rvb, #1
	tbsti	rvb, sv2, 4		@ r7  <- number of data bytes sent (raw int)
	b	i2c_wm_put
	
i2cstp:	@ NAK received or just 1 byte left to read, set stop bit
	@ note how this is also the bottom of i2pute, above
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	rvb, #1			@ r7  <- TXCOMP bit
	str	rvb, [sv3, #i2c_ienable] @ enable TWI TXCOMP interrupt
	set	rvb, #2			@ r7  <- stop bit
	str	rvb, [sv3, #i2c_ctrl]	@ set stop transfer
	set	pc,  lnk

i2c_mst_end:	@ txcomp received
	tbrfi	rvb, sv2, 0		@ r6  <- address of mcu to wrt/rd dat to/from (scheme int{w}/float{r})
	tst	rvb, #0x02		@ is this a write operation?
	beq	i2c_wm_end
	b	i2c_rm_end

hwi2we:	@ set busy status/stop bit at end of write as master
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	@ on entry:	r7  <- #f
	tbsti	rvb, sv2, 0		@ set busy status to #f (transfer done)
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	pc,  lnk
	
hwi2re:	@ set stop bit if needed at end of read-as-master
	@ on entry:	sv3 <- i2c[0/1] base address
	ldr	rvb, =0x107		@ r7  <- NACK, TXRDY, RXRDY and TXCOMP
	str	rvb, [sv3, #i2c_iclear]	@ disable TWI interrupts
	set	pc,  lnk

.endif

.ltorg






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
	set	fre, #0
	set	sv1, #1
	set	sv2, #2
	set	sv3, #3
	set	sv4, #4
	set	sv5, #5
	ldr	rva, =sys_ctrl		@ rva <- scu register base (0x5C002000)

	@ intialize and enable flash banks 0 and 1
	ldr	rvc, =0x54000000	@ rvc <- addres of FMI register (non-buffered)
	str	sv4, [rvc]		@ FMI_BBSR   <- boot bank size = 2^4*32KB = 512KB
	str	fre, [rvc, #0x0C]	@ FMI_BBADR  <- boot bank address = 0
	str	sv2, [rvc, #0x04]	@ FMI_NBBSR  <- non-boot bank size = 2^2*8KB = 32KB
	set	rvb, #0x20000
	str	rvb, [rvc, #0x10]	@ FMI_NBBADR <- non-boot bank address = #x80000
	set	rvb, #0x18
	str	rvb, [rvc, #0x18]	@ FMI_CR     <- enable flash banks 0 and 1

	@ configure flash for high-freq, 2-wait-states (note: need to use 16-bit str)
	set	rvc, #0x80000		@ rvc <- flash bank 1 start address
	set	rvb, #0x60
	strh	rvb, [rvc]		@ prepare to write flash config
	add	rvc, rvc, #0x3000
	add	rvc, rvc, #0x0040
	set	rvb, #0x03
	strh	rvb, [rvc]		@ configure flash banks 0-1 for 2 read wait states, high freq

	@ set RAM to 96KB (default is 32KB)
	ldr	rvb, =0x0197
	str	rvb, [rva, #0x34]	@ SCU_SCR0 <- set RAM size to 96KB

	@ configure PLL for 96MHz, and enable it
	ldr	rvb, =PLL_parms
	orr	rvb, rvb, #0x80000
	str	rvb, [rva, #0x04]	@ SCU_PLLCONF <- enable PLL for 2x192/4 = 96 MHz
pll_wt:	ldr	rvb, [rva, #0x08]
	tst	rvb, #0x01		@ PLL locked?
	beq	pll_wt			@	if not, jump to keep waiting
	set	rvb, #0x0480
	str	rvb, [rva]		@ SCU_CLKCNTR <- all clocks = 96MHz, but USB and PCLK = 48MHz

	@ power-up VIC
	ldr	rvb, [rva, #0x14]
	orr	rvb, rvb, #0x20
	str	rvb, [rva, #0x14]	@ SCU_PCGR0 <- enable VIC clock
	ldr	rvb, [rva, #0x1C]
	orr	rvb, rvb, #0x20
	str	rvb, [rva, #0x1C]	@ SCU_PRR0  <- de-assert VIC reset

	@ power-up TIM 0-1, UART 0-1, I2C 0-1, GPIO 0-9
	ldr	rvb, = 0xFFC0D9
	str	rvb, [rva, #0x18]	@ SCU_PCGR1 <- enable TIM, UART, I2C, GPIO clocks
	str	rvb, [rva, #0x20]	@ SCU_PRR0  <- de-assert reset on TIM, UART, I2C, GPIO

	@ configure LED pin (P0.0 although no LED is on board)
	str	sv1, [rva, #0x44]	@ SCU_GPIOOUT0  <- output function for P0.0
	str	sv1, [rva, #0x84]	@ SCU_GPIOTYPE0 <- open-collector mode on P0.0
	ldr	rvc, =ioport0_base
	str	sv1, [rvc, #io_dir]	@ GPIO0_DIR     <- set P0.0 as output

	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	rvc, =I2C0ADR
	set	rvb, #mcu_id
	str	rvb, [rvc]		@ I2C0ADR <- set mcu address

	@ configure UART0 pins (P3.0 = Rx, P3.1 = Tx)
	str	sv1, [rva, #0x70]	@ SCU_GPIOIN3   <- connect pin P3.0 to input block
	set	rvb, #0x08
	str	rvb, [rva, #0x50]	@ SCU_GPIOOUT3  <- set P3.1 to AF 2 output
	ldr	rvc, =ioport3_base
	str	sv2, [rvc, #io_dir]	@ GPIO3_DIR     <- set P3.1 as output
	@ configure UART0 peripheral
	ldr	rvc, =uart0_base
	set	rvb, #UART0_DIV
	str	rvb, [rvc, #0x24]	@ UART_IBRD <- 9600 bauds with BRCLK = 48MHz
	set	rvb, #UART0_DIV2
	str	rvb, [rvc, #0x28]	@ UART_FBRD <- 9600 bauds with BRCLK = 48MHz
	set	rvb, #0x60
	str	rvb, [rvc, #0x2C]	@ UART_LCR  <- 8,N,1 mode (actuates baud rate)
	set	rvb, #0x0300
	str	rvb, [rvc, #0x30]	@ UART_CR   <- enable Tx, Rx
	set	rvb, #0x10
	str	rvb, [rvc, #0x38]	@ UART_IMSC <- enable Rx interrupt
	ldr	rvb, [rvc, #0x30]
	orr	rvb, rvb, #1
	str	rvb, [rvc, #0x30]	@ UART_CR   <- enable Tx, Rx, uart

	@ set USB configuration to not-configured
	ldr	rvc, =USB_CONF
	str	fre, [rvc]		@ USB device is not yet configured

	@ unlock the file flash sectors
	set	dts, lnk		@ dts <- lnk, saved
	ldr	cnt, =flsULK		@ cnt <- start address of flashing code
	ldr	rvb, =flsULE		@ rvb <- end address of flashing code
	bl	cp2RAM			@ copy flash unlock code to RAM
	ldr	sv2, =F_START_PAGE	@ sv2 <- start address of file flash
	bl	pgsctr			@ rva <- sector number (raw int), from page in sv2
	ldr	rvc, =F_END_PAGE	@ rvc <- end address of file flash
	ldr	glv, =flashsectors	@ glv <- address of flash sector table
	adr	lnk, unlkrt
	ldr	rvb, =heaptop1
	add	rvb, rvb, #4
	set	pc,  rvb		@ jump to unlock FLASH routine in RAM
unlkrt:	@ copy FLASH writing/erasing code to RAM
	ldr	cnt, =flsRAM		@ cnt <- start address of flashing code
	ldr	rvb, =flsRND		@ rvb <- end address of flashing code
	bl	cp2RAM			@ copy flash writing code to RAM
	@ restore modified registers
	ldr	rva, =sys_ctrl		@ rva <- scu register base (0x5C002000)
	set	sv1, #1
	set	sv2, #2
	set	lnk, dts
	
.ifdef	native_usb

	@ initialization of USB device controller
	ldr	rvc, =USB_LineCoding
	ldr	rvb, =115200
	str	rvb, [rvc]		@ 115200 bauds
	set	rvb, #0x00080000
	str	rvb, [rvc,  #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	rvc, =USB_CHUNK
	str	fre, [rvc]		@ zero bytes remaining to send at startup
	ldr	rvc, =USB_ZERO
	str	fre, [rvc]		@ alternate interface and device/interface status = 0
	ldr	rvc, =USB_CONF
	str	fre, [rvc]		@ USB device is not yet configured
	@ power-up USB
	ldr	rvb, [rva, #0x14]
	orr	rvb, rvb, #0x0200
	str	rvb, [rva, #0x14]	@ SCU_PCGR0 <- enable USB
	ldr	rvb, [rva, #0x1C]
	orr	rvb, rvb, #0x0200
	str	rvb, [rva, #0x1C]	@ SCU_PRR0  <- de-assert USB reset
	ldr	rvc, =usb_base
	ldr	rvb, [rvc, #0x40]
	bic	rvb, rvb, #0x02
	str	rvb, [rvc, #0x40]	@ USB_CNTR   -> exit power-down mode
	@ wait for module initialization (1 micro-sec)
	set	rvb, #0x0100
hwiwt3:	subs	rvb, rvb, #1
	bne	hwiwt3
	@ continue bringing up USB
	str	fre, [rvc, #0x40]	@ USB_CNTR   -> exit reset mode
	str	fre, [rvc, #0x40]	@ USB_CNTR   -> exit reset mode (again, to make sure)
	str	fre, [rvc, #0x44]	@ USB_ISTR   -> clear potential spurious pending interrupts
	ldr	rvb, [rva, #0x14]
	orr	rvb, rvb, #0x0400
	str	rvb, [rva, #0x14]	@ SCU_PCGR0 <- enable USB 48MHz clock
	set	rvb, #0x9C00
	str	rvb, [rvc, #0x40]	@ USB_CNTR   -> interrupt on ctr, wakeup, suspend, reset
	@ configure buffer allocation table
	str	fre, [rvc, #0x50]	@ USB_BTABLE    -> buffer allocation table starts at offset 0
	sub	env, rvc, #0x0800
	ldr	rvb, =0x01100100
	str	rvb, [env, #0x00]	@ USB_ADR0_TX   -> EP0 send buff strt offst=0x0100 (2 x 0x80)
	ldr	rvb, =0x10000000
	str	rvb, [env, #0x04]	@ USB_COUNT0_TX -> 0 bytes to transmit
	ldr	rvb, =0x01300120
	str	rvb, [env, #0x08]	@ USB_ADR1_TX   -> EP0 send buff strt offst=0x0100 (2 x 0x80)
	ldr	rvb, =0x10000000
	str	rvb, [env, #0x0c]	@ USB_COUNT1_TX -> 0 bytes to transmit
	ldr	rvb, =0x01c00140
	str	rvb, [env, #0x10]	@ USB_ADR2_TX   -> EP0 send buff strt offst=0x0100 (2 x 0x80)
	ldr	rvb, =0x84000000
	str	rvb, [env, #0x14]	@ USB_COUNT2_TX -> 0 bytes to transmit
	ldr	rvb, =0x02c00240
	str	rvb, [env, #0x18]	@ USB_ADR3_TX   -> EP0 send buff strt offst=0x0100 (2 x 0x80)
	ldr	rvb, =0x84000000
	str	rvb, [env, #0x1c]	@ USB_COUNT3_TX -> 0 bytes to transmit
	@ configure EP0, device address, and enable USB
	ldr	rvb, =0x3230
	str	rvb, [rvc]		@ USB_EP0R      -> configure enpoint 0 as control EP
	set	rvb, #0x80
	str	rvb, [rvc, #0x4c]	@ USB_DADDR	-> enable USB, address is 0

.endif	@ native_usb
	@ enf of the hardware initialization
	set	pc,  lnk


/*------------------------------------------------------------------------------
@ STR_7xx
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/

@
@ 1- Initialization from FLASH and writing to FLASH
@

FlashInitCheck:	
	ldr	rvc, =sys_ctrl		@ rva <- scu register base (0x5C002000)
	set	rvb, #0x08
	str	rvb, [rvc, #0x64]	@ SCU_GPIOIN0   <- connect pin P0.3 to input block
	ldr	rvb, =ioport0_base
	ldr	rva, [rvb, #io_set]	@ rva <- data values from IOPORT0
	and	rva, rva, #0x08		@ rva <- status of P0.3
	set	rvb, #0
	str	rvb, [rvc, #0x64]	@ SCU_GPIOIN0   <- disconnect P0.3 from input block
	set	pc,  lnk
	
cp2RAM:	@ copy code block delimited by cnt and rvb to RAM
	@ on entry:	cnt <- addresss of start of code block
	@ on entry:	rvb <- addresss of end   of code block
	@ modifies:	rvc, env, cnt
	@ returns via:	lnk
	ldr	rvc, =heaptop1		@ rvc <- RAM target address
	add	rvc, rvc, #4
hwiwt6:	ldr	env, [cnt]		@ env <- next flashing code instruction
	str	env, [rvc]		@ store it in free RAM
	eq	cnt, rvb		@ done copying the flashing code?
	addne	cnt, cnt, #4		@	if not, cnt <- next source address
	addne	rvc, rvc, #4		@	if not, rvc <- next target address
	bne	hwiwt6			@	if not, jump to keep copying code to RAM
	set	pc,  lnk


wrtfla:	@ write to flash, sv2 = page address, sv4 = file descriptor
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	@ copy buffer data from file descriptor{sv4} (RAM) to FLASH buffer {sv2}
	vcrfi	sv3, sv4, 3			@ sv3 <- buffer address
	add	sv5, sv2, #F_PAGE_SIZE		@ sv5 <- end target address
	bl	pgsctr				@ rva <- sector number (raw int), from page address in sv2
	ldr	rvb, =flashsectors		@ rvb <- address of flash address table
	ldr	rvb, [rvb, rva,LSL #2]		@ rvb <- start address of target flash sector
	adr	lnk, flwrrt
	set	rva, #0x40			@ rva <- CFI word program command code
	ldr	cnt, =heaptop1
	add	cnt, cnt, #4
	set	pc,  cnt			@ jump to FLASH-write routine in RAM
flwrrt:	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}	@ restore scheme registers from stack
	swi	run_normal			@ enable interrupts (user mode)
	set	pc,  lnk			@ return

ersfla:	@ erase flash sector that contains page address in sv2
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	swi	run_no_irq				@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	@ prepare flash sector for write
	bl	pgsctr				@ rva <- sector number (raw int), from page address in sv2
	ldr	rvb, =flashsectors		@ rvb <- address of flash sector table
	ldr	rvb, [rvb, rva, LSL #2]		@ rvb <- address of flash sector start
	adr	lnk, flerrt
	set	rva, #0x20			@ rva <- CFI erase sector command code
	ldr	cnt, =heaptop1
	add	cnt, cnt, #4
	set	pc,  cnt			@ jump to FLASH-write routine in RAM
flerrt:	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}	@ restore scheme registers from stack
	swi	run_normal				@ enable interrupts (user mode)
	set	pc,  lnk			@ return



	
@
@ 2- I2C Interrupt routine
@

.ifdef	include_i2c

hwi2cr:	@ write-out additional address registers, if needed
	@ on entry:	sv5 <- i2c[0/1]buffer
	@ on entry:	r6  <- i2c[0/1] base address (also I2CONSET)
	set	rvb, #0			@ r7  <- 0 bytes to send (scheme int)
	tbsti	rvb, sv5, 3		@ store number of bytes to send in i2c buffer[12]
	@ initiate i2c read/write, as master
	swi	run_normal			@ re-enable interrupts
	ldrb	rvb, [rva, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x08		@ r7  <- contents orred with start bit
	strb	rvb, [rva, #i2c_cr]	@ initiate bus mastering (write start to I2C[0/1]_CR)
hwi2r0:	@ wait for mcu address and registers to have been transmitted
	swi	run_no_irq			@ disable interrupts
	tbrfi	rvb, sv5, 1		@ r7  <- data ready status from i2cbuffer[4]
	eq	rvb, #f			@ is i2c data ready = #f (i.e. addresses have been transmitted)
	seteq	pc,  lnk		@	if so, jump to continue
	swi	run_normal			@ re-enable interrupts
	b	hwi2r0			@ jump to keep waiting
	
hwi2ni:	@ initiate i2c read/write, as master
	@ on entry:	r6  <- i2c[0/1] base address (also I2CONSET)
	ldrb	rvb, [rva, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x08		@ r7  <- contents orred with start bit
	strb	rvb, [rva, #i2c_cr]	@ initiate bus mastering (write start to I2C[0/1]_CR)
	set	pc,  lnk
	
hwi2st:	@ get i2c interrupt status and base address
	ldrb	rvb, [rva, #i2c_stat2]	@ r7  <- I2C Status from SR2
	eq	rvb, #0			@ anything from SR2?
	lslne	rvb, rvb, #8		@	if so,   r7  <- I2C SR2 status, shifted
	ldrbeq	rvb, [rva, #i2c_stat1]	@	if not,  r7  <- I2C Status from SR1
	set	pc,  lnk
	
i2c_hw_branch:
	eq	rvb, #0x94		@ Slave Read/Write -- my address recognzd, EV1-SR1, EVF BSY ADSL,#0x94
	beq	i2c_hw_slv_ini
	eq	rvb, #0x98		@ Slave Read  -- new data received,	   EV2-SR1, EVF BSY BTF,#0x98
	beq	i2c_hw_rs_get
	eq	rvb, #0xB8		@ Slave Write -- master requests byte, EV3-SR1,EVF TRA BSY BTF,#0xB8
	beq	i2c_hw_ws_put
	tst	rvb, #0x1000		@ Slave Write -- NAK received, Tx done,	  EV3-1	- SR2, AF, #0x10
	bne	i2c_hw_ws_end
	tst	rvb, #0x0800		@ Slave Read  -- STOP or re-START received, EV4	- SR2, STOPF, #0x08
	bne	i2c_rs_end
	eq	rvb, #0x93		@ Master Read/Write -- bus now mstrd, EV5- SR1, EVF BSY MSL SB, #0x93
	beq	i2c_hw_mst_bus
	tst	rvb, #0x2000		@ Master Read/Write -- slave ackn. address, EV6	- SR2, ENDAD, #0x20
	bne	i2c_hw_mst_ini
	eq	rvb, #0x9A		@ Master Read -- new byte received, EV7	- SR1, EVF BSY BTF MSL, #0x9A
	beq	i2c_hw_rm_get
	eq	rvb, #0xBA		@ Master Write - slav ok to rcv dat, EV8-SR1,EVF TRA BSY BTF MSL,#0xBA
	beq	i2c_wm_put
	set	pc,  lnk

i2c_hw_slv_ini: @ Slave Read/Write -- my address recognized  (EV1)
	tbrfi	rva, sv2, 0		@ r6  <- channel-busy status
	eq	rva, #f			@ is channel free?
	seteq	rva, #i0		@	if so,  r6  <- 0 (scheme int)
	tbstieq rva, sv2, 0		@	if so,  store 0 (scheme int) as channel-busy
	set	rva, #0			@ r6  <- 0
	tbsti	rva, sv2, 4		@ store 0 as number of bytes sent/received
	b	i2cxit

i2c_hw_rs_get:	
	tbrfi	rvb, sv2, 4		@ r7  <- number of bytes sent
	eq	rvb, #0
	tbstieq rvb, sv2, 2		@	if so,  store 0 as data received so far (clear received data)
	bleq	yldon
	b	i2c_rs_get

i2c_hw_ws_put:	
	tbrfi	rvb, sv2, 4		@ r7  <- number of bytes sent
	eq	rvb, #0
	bne	i2c_ws_put
	bl	gldon
	tbrfi	rva, sv2, 0		@ r6  <- channel-busy status
	eq	rva, #i0		@ was channel free at start of transfer?
	tbstieq rva, sv2, 1		@	if so,  store 0 (scheme int) as data-not-ready/#address-bytes
	ldreq	rva, =eof_char		@	if so,  r6  <- eof-character
	streq	rva, [glv, sv1]		@	if so,  store eof-character as object to send
	seteq	rva, #4			@	if so,  r6  <- 4 (raw int) = number of bytes to send
	tbstieq rva, sv2, 3		@	if so,  store 4 as number of bytes to send
	b	i2c_ws_put

i2c_hw_ws_end:	@ Slave Write -- NAK received, Tx done,	  EV3-1	- SR2, AF, #0x10
	ldrb	rvb, [sv3, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x02		@ r7  <- contents orred with stop bit
	strb	rvb, [sv3, #i2c_cr]	@ set stop bit
	ldrb	rvb, [sv3, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	bic	rvb, rvb, #0x02		@ r7  <- contents with cleared stop bit
	strb	rvb, [sv3, #i2c_cr]	@ clear stop bit
	b	i2c_ws_end

i2c_hw_mst_bus:	@ Master Read/Write -- bus now mastered (EV5)
	bl	gldon
	tbrfi	rva, sv2, 0		@ r6  <- address of mcu to send data to (scheme int)
	lsr	rva, rva, #1		@ r6  <- mcu-id as int -- note: ends with 0 (i.e. divide by 2)
	strb	rva, [sv3, #i2c_thr]	@ set address of mcu to send data to
	b	i2cxit

i2c_hw_mst_ini: @ Master Read/Write -- slave aknowledged address (EV6)
	ldrb	rvb, [sv3, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	strb	rvb, [sv3, #i2c_cr]	@ re-store contents of cr (to clear THIS interrupt)
	tbrfi	rvb, sv2, 0		@ r6  <- addrss of mcu to wrt/rd data to/from (scheme int{w}/float{r})
	tst	rvb, #0x02		@ is this a write operation?
	beq	i2c_wm_ini
	b	i2c_rm_ini
	
hwi2we:	@ set busy status/stop bit at end of write as master
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	@ on entry:	r7  <- #f
	tbrfi	rva, sv2, 3		@ r6  <- number of data bytes to send (raw int)
	eq	rva, #0			@ were we sending 0 bytes (i.e. rdng as mastr & done writng addrss byt
	seteq	pc,  lnk
	tbsti	rvb, sv2, 0		@ set busy status to #f (transfer done)
	ldrb	rvb, [sv3, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x02		@ r7  <- contents orred with stop bit
	strb	rvb, [sv3, #i2c_cr]	@ initiate stop (write stop to I2C[0/1]_CR)
	set	pc,  lnk
	
i2c_hw_rm_get:
	ldrb	rvb, [sv3, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	tst	rvb, #0x04		@ is ack bit asserted?
	bne	i2c_rm_get		@	if so,  jump to perform normal read
	b	i2c_rm_end		@ jump to perform end of read as master (nack was set on prior byte)

hwi2re:	@ set stop bit if needed at end of read-as-master
	ldrb	rvb, [sv3, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x06		@ r7  <- contents orred with stop bit and ack bit (reset nak to ack)
	strb	rvb, [sv3, #i2c_cr]	@ initiate stop (write stop to I2C[0/1]_CR)
	set	pc,  lnk
	
hwi2cs:	@ clear SI
	set	pc,  lnk
	
i2cstp:	@ prepare to end Read as Master transfer
	ldrb	rvb, [sv3, #i2c_cr]	@ r7  <- current content of I2C[0/1]_CR
	bic	rvb, rvb, #0x04		@ r7  <- contents with ack bit cleared
	strb	rvb, [sv3, #i2c_cr]	@ set nak in cr
	set	pc,  lnk

i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer or r12 (prologue)
	set	pc,  lnk
	
i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	tbrfi	rva, sv2, 3		@ r6  <- number of data bytes to send (raw int)
	tbrfi	rvb, sv2, 4		@ r7  <- number of data bytes sent (raw int)
	eq	rva, rvb		@ done sending?
	beq	i2c_wm_end		@	if so,  jump to end transfer
	set	pc,  lnk

.endif
	
.ltorg






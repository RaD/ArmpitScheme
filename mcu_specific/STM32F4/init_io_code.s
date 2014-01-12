/*------------------------------------------------------------------------------
@
@  ARMPIT SCHEME Version 060
@
@  ARMPIT SCHEME is distributed under The MIT License.

@  Copyright (c) 2012-2013 Petr Cermak

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


_func_
hwinit:
	@ pre-set common values
	set	r0,  #0
	set	r1,  #1
	set	r2,  #2
	set	r3,  #3
	set	r4,  #4
	set	r5,  #5

	@ allow 4-byte stack (clear STKALIGN in CCR)
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	r10, =0xE000ED14
	str	r0,  [r10]
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ Reset the RCC clock configuration to the default reset state ------------
	@ Set HSION bit
	ldr	r10, =rcc_base
	set	r7,  #0x00001
	str	r7,  [r10]		@ RCC_CR    <- set HSION
	@ Reset CFGR register
	ldr	r10, =rcc_base
	set	r7,  #0x00000
	str	r7,  [r10, #0x08]		@ RCC_CFGR
	@ Reset HSEON, CSSON and PLLON bits
	ldr	r10, =rcc_base
	ldr	r7,  [r10]
	ldr	r6,  =0xFEF6FFFF
	bic	r7,  r7, r6
	str	r7,  [r10]
	@ Reset PLLCFGR register
	@ RCC->PLLCFGR = 0x24003010;
	ldr	r10, =rcc_base
	ldr	r7,  =0x24003010
	str	r7,  [r10, #0x08]
	@ Reset HSEBYP bit
	@ RCC->CR &= (uint32_t)0xFFFBFFFF;
	ldr	r10, =rcc_base
	ldr	r7,  [r10]
	ldr	r6,  =0xFFFBFFFF
	bic	r7,  r7, r6
	str	r7,  [r10]

	@ Disable all interrupts
	@ RCC->CIR = 0x00000000;
	ldr	r10, =rcc_base
	set	r7,  #0x00000000
	str	r7,  [r10, #0x0C]

	@ initialization of clocks
	ldr	r10, =rcc_base
	ldr	r7,  [r10]
	orr	r7,  r7, #(1<<16)
	str	r7,  [r10]		@ RCC_CR    <- set HSEON
hwiwt0:	ldr	r7,  [r10]
	tst	r7,  #(1<<17)		@ RCC_CR    <- wait for HSERdy bit
	beq	hwiwt0

	@ Select regulator voltage output Scale 1 mode, System frequency up to 168 MHz
	ldr	r7,  [r10, #0x40]
	orr	r7,  r7, #(1<<28)	@ RCC_APB1ENR_PWREN
	str	r7,  [r10, #0x40]	@ RCC_APB1ENR
	@ PWR->CR |= PWR_CR_VOS;
	ldr	r10, =pwr_base
	set	r7,  #(1<<14)
	str	r7,  [r10]

	@ FLASH_ACR <- enable buffer, 6 wait states as SYSCLK will be 168 MHz
	@ (can be reduced to 5 wait states if voltage is known to be 2.7-3.6V)
	ldr	r6,  =flashcr_base
	set	r7,  #0x06		@ r7  <- 6 wait states
	orr	r7,  r7, #(7 << 8)	@ r7  <- wait states orred with cache/prefetch enable
	str	r7,  [r6]		@ FLASH_ACR <- set wait states and enable cache/prefetch
hwfwt0:	ldr	r7,  [r6]		@ r7  <- contents of FLASH_ACR
	tst	r7,  #0x04		@ at least 4 wait states (i.e. good to go)?
	beq	hwfwt0			@	if not, jump back to wait

	@ Configure the main PLL
	ldr	r10, =rcc_base
	ldr	r7,  =Clock_parms
	str	r7,  [r10, #0x04]

	@ Configure Prescaler
	ldr	r7,  [r10, #0x08]
	ldr	r6,  =Prescl_parms
	orr	r7,  r7, r6
	str	r7,  [r10, #0x08]

	@ PLL ON
	ldr	r7,  [r10]
	orr	r7,  r7, #(1<<24)
	str	r7,  [r10]		@ RCC_CR    <- turn PLL on
hwiwt1:	ldr	r7,  [r10]
	tst	r7,  #(1<<25)		@ RCC_CFGR  <- wait for PLL to be connected
	beq	hwiwt1

	@ PLL as System clock
	ldr	r7,  [r10, #0x08]
	ldr	r6,  =0xFFFFFFFC
	and	r7,  r7, r6
	orr	r7,  r7, #(1<<1)
	str	r7,  [r10, #0x08]	@ RCC_CR    <- turn PLL as System clock on
hwiwt2:	ldr	r7,  [r10, #0x08]
	tst	r7,  #(1<<3)		@ RCC_CFGR  <- wait for PLL as System clock ready
	beq	hwiwt2

	@ initialization of FLASH
	ldr	r6,  =flashcr_base
	ldr	r7,  =0x45670123
	str	r7,  [r6,  #0x04]	@ FLASH_KEYR <- KEY1, start to unlock flash registers
	ldr	r7,  =0xcdef89ab
	str	r7,  [r6,  #0x04]	@ FLASH_KEYR <- KEY2, finish unlocking of flash registers

	@ initialize Cortex-M3 SysTick Timer
	swi	run_prvlgd		@ set Thread mode, privileged, no IRQ (privileged user mode)
	ldr	r6,  =systick_base
	ldr	r7,  =SYSTICK_RELOAD
	str	r7,  [r6, #tick_load]	@ SYSTICK-RELOAD  <- value for 10ms timing at 72MHz
	str	r0,  [r6, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	r5,  [r6, #tick_ctrl]	@ SYSTICK-CONTROL <- 5 = enabled, no interrupt, run from cpu clock
	swi	run_no_irq		@ set Thread mode, unprivileged, no IRQ (user no IRQ)

	@ initialization of user button and LED gpio pins
	@ 1- Power port A (for user button) and port D for LEDs
	ldr	r7,  [r10, #0x30]	@ r7  <- RCC_AHB1ENR
	orr	r7,  r7, #0x09
	str	r7,  [r10, #0x30]	@ RCC_AHB1ENR <- enable clock for GPIO ports A and D
	@ 2- GPIOD_CRL   <- set PD12-PD13 as output
	ldr	r6,  =LEDPINSEL
	set	r7,  #(0b010101 << 24)
	str	r7,  [r6,  #0x00]	@ GPIOD_CRL   <- PD12-PD14 (LED) pins set as output

	@ initialization of USART1 for 9600 8N1 operation
	@ 1- Power clock for port B
	ldr	r7,  [r10, #0x30]
	orr	r7,  r7, #(1<<1)
	str	r7,  [r10, #0x30]
	@ 2- GPIOB_CRL   <- PB6/PB7 (USART1 Tx/Rx) cfg AF out, push-pull & input
	ldr	r6,  =ioportb_base
	ldr	r7,  [r6,  #0x00]
	bic	r7,  r7, #(0b1111 << 12)    @ alternate function mode
	orr	r7,  r7, #(0b1010 << 12)
	str	r7,  [r6,  #0x00]
	ldr	r7,  [r6,  #0x08]
	bic	r7,  r7, #(0b1111 << 12)      @ speed at 25MHz
	orr	r7,  r7, #(0b0101 << 12)
	str	r7,  [r6,  #0x08]
	ldr	r7,  [r6,  #0x0C]
	bic	r7,  r7, #(0b1111 << 12)      @ Tx,PB6 Pull Up, Rx, PB7 No Pull
	orr	r7,  r7, #(0b0001 << 12)
	str	r7,  [r6,  #0x0C]
	ldr	r7,  [r6,  #0x20]
	bic	r7,  r7, #(0b11111111 << 24)      @ AFR, AF7
	orr	r7,  r7, #(0b01110111 << 24)
	str	r7,  [r6,  #0x20]

	@ Power clock for USART1
	ldr	r7,  [r10, #0x44]
	orr	r7,  r7, #(1<<4)
	str	r7,  [r10, #0x44]
	ldr	r6,  =uart0_base
	ldr	r7,  =UART0_DIV
	str	r7,  [r6,  #0x08]	@ USART_BRR   <- 9600 bauds (or 230K from config file)
	ldr	r7,  =0xa02c
	str	r7,  [r6,  #0x0c]	@ USART_CR1   <- USART, Tx and Rx enabled at 8N1, with Rx interrupt, over8=1

.ifdef harvard_split

	@ copy .data section to CCM
	ldr	r6,  =_data_section_address_	@ start of source
	ldr	r7,  =_startdata	@ start of destination (from build_link file)
	ldr	r8,  =_enddata		@ end of destination (from build_link file)
	add	r8,  r8,  #4
datcp0:	ldmia	r6!, {r11-r12}
	stmia	r7!, {r11-r12}
	cmp	r7,  r8
	bmi	datcp0

.endif

	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	r7,  [r10, #0x40]	@ r7  <- RCC_APB1ENR
	orr	r7,  r7, #(1 << 21)	@ r7  <- I2C1 enable bit
	str	r7,  [r10, #0x40]	@ RCC_APB1ENR <- enable clock for I2C1
	ldr	r6,  =I2C0ADR
	set	r7,  #mcu_id
	str	r7,  [r6]

	@ initialization of USB configuration
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB_CONF <- USB device is not yet configured
	
.ifdef	native_usb

  .ifdef STM32F4_Discov
	@ check if USB is powered (PA9 OTG_VBUS power pin), otherwise, return
	ldr	r6,  =ioporta_base
	ldr	r7,  [r6,  #io_state]
	tst	r7, #(1 << 9)
	it	eq
	seteq	pc,  lnk
  .endif
  
	@ 2- GPIOA  <- PA9, 10, 11, 12 configure USB OTG FS AF to VBUS, ID, DM, DP
	ldr	r6,  =ioporta_base
	ldr	r7,  [r6,  #0x00]
	bic	r7,  r7, #(0b1111 << 22)    @ alternate function mode
	orr	r7,  r7, #(0b1010 << 22)
	str	r7,  [r6,  #0x00]		@ GPIOA_MODER <- AF for PA9-12
	ldr	r7,  [r6,  #0x08]
	bic	r7,  r7, #(0b1111 << 22)	@ speed
	orr	r7,  r7, #(0b1010 << 22)
	str	r7,  [r6,  #0x08]		@ GPIOA_SPEEDR <- 50 MHz
	ldr	r7,  [r6,  #0x24]
	bic	r7,  r7, #(0b11111111 << 12)	@ AF10 for DM, DP -- PA11, 12
	orr	r7,  r7, #(0b10101010 << 12)
	str	r7,  [r6,  #0x24]		@ GPIOA_AFRH <- AF10 (OTG_FS) for PA10-12
	@ enable USB OTG FS clock
	ldr	r7,  [r10, #0x34]
	orr	r7,  r7, #(1 << 7)
	str	r7,  [r10, #0x34]	@ RCC_AHB2ENR  <- enable USB OTG FS clock (for 72 MHz main clock)  
	@ initialization of USB device controller 
	ldr	r6,  =USB_LineCoding
	ldr	r7,  =115200
	str	r7,  [r6]		@ 115200 bauds
	set	r7,  #0x00080000
	str	r7,  [r6,  #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	r6,  =USB_CHUNK
	str	r0,  [r6]		@ zero bytes remaining to send at startup
	ldr	r6,  =USB_ZERO
	str	r0,  [r6]		@ alternate interface and device/interface status = 0
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB device is not yet configured	
	ldr	r6,  =usb_base
	ldr	r7,  =0x40002487
	str	r7,  [r6, #0x0c]	@ GUSBCFG <- device mode, trdt=9 (72MHz)
	set	r7,  #0x81
	str	r7,  [r6, #0x08]	@ GAHBCFG <- unmsk glbl OTG ints,Txlvl=0
	ldr	r7,  =0x041010
	str	r7,  [r6, #0x18]	@ GINTMSK <- unmask RXFLVL,IN,RESET ints
	add	r6,  r6, #0x0800
	ldr	r7,  [r6]
	orr	r7,  r7,  r3
	str	r7,  [r6]		@ DCFG    <- device full speed,address 0
	sub	r6,  r6, #0x0800
	set	r7,  #0x090000
	str	r7,  [r6, #0x38]	@ GCCFG   <- power up transc, VBus sens
	
.endif
	
	@ enf of the hardware initialization
	set	pc,  lnk


/*------------------------------------------------------------------------------
@ STM32x
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@-----------------------------------------------------------------------------*/

@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

_func_
FlashInitCheck: @ return status of flash init enable/override gpio pin (USER button, PA.0) in rva
	ldr	rva, =ioporta_base		@ rva <- GPIO port A where PA0 is located
	ldr	rva, [rva, #io_state]		@ rva <- status of input pins on Port A
	mvn	rva, rva			@ rva <- inverted state (button is normally high, low if pressed)
	and	rva, rva, #0x01			@ rva <- status of PA0 only (non-zero if PA0 is pressed)
	set	pc,  lnk			@ return


_func_
wrtfla:	@ write to flash, sv2 = page address, sv4 = file descriptor
_func_
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	set	rvc, #F_PAGE_SIZE
_func_
wrtfle:	@ [internal entry] (for wrtflr = file pseudo-erase)
	stmfd	sp!, {sv3}			@ store scheme registers onto stack
	ldr	rva, =flashcr_base		@ rva <- flash registers base address
	set	rvb, #0x01			@ rvb <- bit 0, PG (program)
	orr	rvb, rvb, #0x0100		@ rvb <- 16-bit programming (PSIZE and PG)
	str	rvb, [rva, #0x10]		@ set program command in FLASH_CR
	vcrfi	sv3, sv4, 3			@ sv3 <- buffer address from file descriptor
	@ check for file pseudo-erasure
	eq	rvc, #0
	it	eq
	strheq	rvc, [sv2]			@ write half-word to flash
	beq	wrtfl1
wrtfl0:	@ write #F_PAGE_SIZE bytes to flash
	sub	rvc, rvc, #2
	ldrh	rvb, [sv3, rvc]			@ rvb <- half-word to write, from buffer
	strh	rvb, [sv2, rvc]			@ write half-word to flash
wrtfl1:	@ wait for flash ready
	ldr	rvb, [rva, #0x0c]		@ rvb <- FLASH_SR
	tst	rvb, #(1 << flash_busy)		@ is BSY still asserted?
	bne	wrtfl1				@	if so,  jump to keep waiting
	eq	rvc, #0				@ done?
	bne	wrtfl0				@	if not, jump to keep writing
	@ exit
	set	rvb, #0x00			@ rvb <- 0
	str	rvb, [rva, #0x10]		@ clear contents of FLASH_CR
	ldmfd	sp!, {sv3}			@ restore scheme registers from stack
	set	pc,  lnk			@ return

_func_
wrtflr:	@ pseudo-erase a file flash page, sv2 = page address, sv4 = file descriptor
	@ Note:	overwriting a flash cell with anything other than 0x0000 can produce
	@	errors on this MCU. For this reason, #0 is used here (rather than #i0).
	set	rvc, #0
	b	wrtfle

_func_
ersfla:	@ erase flash sector that contains page address in sv2
_func_
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	set	rvc, lnk			@ rvc <- lnk, saved against pgsctr
	bl	pgsctr				@ rva <- sector number (raw int), from page address in r5 {sv2}
	set	lnk, rvc			@ lnk <- lnk, restored
	lsl	rvb, rva, #3			@ rvb <- bits 6:3, SNB (sector number)
	orr	rvb, rvb, #(1 << 16)		@ rvb <- bit 16, Start erase
	orr	rvb, rvb, #0x02			@ rvb <- bit 1,  PER (page erase)
	ldr	rva, =flashcr_base		@ rva <- flash registers base address
	str	rvb, [rva, #0x10]		@ start erase page via FLASH_CR (stalls cpu if run from flash)
ersfl0:	ldr	rvb, [rva, #0x0c]		@ rvb <- FLASH_SR
	tst	rvb, #(1 << flash_busy)		@ is BSY still asserted?
	bne	ersfl0				@	if so,  jump to keep waiting
	set	rvb, #0x00			@ rvb <- 0
	str	rvb, [rva, #0x10]		@ clear contents of FLASH_CR
	set	pc,  lnk			@ return


.ltorg






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

/*------------------------------------------------------------------------------
@
@ Contributions:
@
@     This file includes contributions by tzirechnoy, marked <TZC>
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

	@ initialization of clocks
	ldr	r10, =rcc_base
	ldr	r7,  [r10]
	orr	r7,  r7, #0x010000
	str	r7,  [r10]		@ RCC_CR    <- set HSEON
hwiwt0:	ldr	r7,  [r10]
	tst	r7,  #0x020000		@ RCC_CR    <- wait for HSERdy bit
	beq	hwiwt0
	ldr	r6,  =flashcr_base
	set	r7,  #0x32
	str	r7,  [r6]		@ FLASH_ACR <- bfr,2 wt stats for 72MHz
.ifdef	connectivity_ln
	ldr	r7,  =Clock_parms2
	str	r7,  [r10, #0x2c]	@ RCC_CFGR2 <- PLL3x2=50MHz,PLL2x8/5=40M
	ldr	r7,  [r10]
	orr	r7,  r7, #0x04000000
	str	r7,  [r10]		@ RCC_CR    <- turn PLL2 on
hwiwt2:	ldr	r7,  [r10]
	tst	r7,  #0x08000000	@ RCC_CR    <- wait for PLL2 locked
	beq	hwiwt2
	orr	r7,  r7, #0x10000000
	str	r7,  [r10]		@ RCC_CR    <- turn PLL3 on
hwiwt3:	ldr	r7,  [r10]
	tst	r7,  #0x20000000	@ RCC_CR    <- wait for PLL3 locked
	beq	hwiwt3
.endif
	ldr	r7,  =Clock_parms
	str	r7,  [r10, #0x04]	@ RCC_CFGR  <- USB=48,AHB=72,APB12=36MHz
	ldr	r7,  [r10]
	orr	r7,  r7, #0x01000000
	str	r7,  [r10]		@ RCC_CR    <- turn PLL on
hwiwt1:	ldr	r7,  [r10, #0x04]
	tst	r7,  #0x08		@ RCC_CFGR  <- wait for PLL connected
	beq	hwiwt1

	@ initialization of FLASH
	ldr	r7,  =0x45670123
	str	r7,  [r6,  #0x04]	@ FLASH_KEYR <- KEY1, unlock flash regs
	ldr	r7,  =0xcdef89ab
	str	r7,  [r6,  #0x04]	@ FLASH_KEYR <- KEY2, unlock flash regs

	@ initialize Cortex-M3 SysTick Timer
	swi	run_prvlgd		@ Thread mode, prvlgd, no IRQ
	ldr	r6,  =systick_base
	ldr	r7,  =719999
	str	r7,  [r6, #tick_load]	@ SYSTICK-RELOAD  <- 10ms at 72MHz
	str	r0,  [r6, #tick_val]	@ SYSTICK-VALUE   <- 0
	str	r5,  [r6, #tick_ctrl]	@ SYSTICK-CONTROL <- enab,no int,cpu clk
	swi	run_no_irq		@ Thread mode, unprvlgd, no IRQ

	@ initialization of LED gpio pins
.ifdef STM32_H103
	set	r7,  #0x10
	str	r7,  [r10, #24]		@ RCC_APB2ENR <- enab clck I/O Port C
	ldr	r6,  =ioportc_base
	ldr	r7,  [r6,  #0x04]
	bic	r7,  r7, #0x0F0000
	orr	r7,  r7, #0x070000
	str	r7,  [r6,  #0x04]	@ GPIOC_CRH   <- PC12 LED open drain out
.endif
.ifdef STM32_H107
	set	r7,  #0x1d
	str	r7,  [r10, #24]		@ RCC_APB2ENR <- enab clck Port ABC,AFIO
	ldr	r6,  =ioportc_base
	ldr	r7,  [r6,  #0x00]
	bic	r7,  r7, #(0xFF << 24)
	orr	r7,  r7, #(0x33 << 24)
	str	r7,  [r6,  #0x00]	@ GPIOC_CRL   <- PC6,7 LED push-pull out
.endif
.ifdef STM32_DT_Board
	set	r7,  #0x14
	str	r7,  [r10, #24]		@ RCC_APB2ENR <- enab clck I/O Ports AC
	ldr	r6,  =ioporta_base
	ldr	r7,  [r6,  #0x04]
	bic	r7,  r7, #0x0F
	orr	r7,  r7, #0x07
	str	r7,  [r6,  #0x04]	@ GPIOA_CRH   <- PA8 LED open drain out
.endif
.ifdef STM32_LCD
	set	r7,  #0x2c
	str	r7,  [r10, #24]		@ RCC_APB2ENR <- enab clck I/O Ports ABD
	ldr	r6,  =ioportb_base
	ldr	r7,  [r6,  #0x00]
	bic	r7,  r7, #0x0F00
	orr	r7,  r7, #0x0700
	str	r7,  [r6,  #0x00]	@ GPIOB_CRL   <- PB2 opt open drain out
.endif

	@ initialization of USART1 for 9600 8N1 operation
.ifndef connectivity_ln
	ldr	r7,  [r10, #24]
	ldr	r8,  =0x4004
	orr	r7,  r7, r8
	str	r7,  [r10, #24]		@ RCC_APB2ENR <- enab clck USART1 Port A
	ldr	r6,  =ioporta_base
	ldr	r7,  [r6,  #0x04]
	bic	r7,  r7, #0x00F0
	orr	r7,  r7, #0x00B0
	str	r7,  [r6,  #0x04]	@ GPIOA_CRH <- PA9 USART1 Tx AF out pspl
.else

  .ifndef swap_default_usart
	
	ldr	r6,  =afio_base
	ldr	r7,  [r6, #0x04]
	orr	r7,  r7, #0x06		@ USART1 -> PB, I2C1 -> PB
	orr	r7,  r7, #(1 << 12)	@ TIM4 -> PD
	orr	r7,  r7, #0xc0		@ TIM1 -> PE
	orr	r7,  r7, #(6 << 12)	@ CAN1 -> PD
	str	r7,  [r6, #0x04]	@ AFIO_MAPR <- urt1TxRx=PB6-7,tm4=PD1215
	ldr	r7,  [r10, #24]
	orr	r7,  r7, #0x4000
	str	r7,  [r10, #24]		@ RCC_APB2ENR <- enable clock for USART1
	ldr	r6,  =ioportb_base
	ldr	r7,  [r6,  #0x00]
	bic	r7,  r7, #(0xff << 24)
	orr	r7,  r7, #(0x8b << 24)
	str	r7,  [r6,  #0x00]	@ GPIOB_CRL <- PB6Tx/7Rx AF out pspl/in

  .else
	
	ldr	r7,  [r10, #0x1c]
	orr	r7,  r7, #0x20000
	str	r7,  [r10, #0x1c]	@ RCC_APB1ENR <- enab clk USART2 (UAR0)
	ldr	r6,  =ioporta_base
	ldr	r7,  [r6,  #0x00]
	bic	r7,  r7, #0xFF00
	orr	r7,  r7, #0x8B00
	str	r7,  [r6,  #0x00]	@ GPIOA_CRL <- PA2Tx/3Rx AF out pspl/in

  .endif
	
.endif
	ldr	r6,  =uart0_base
	ldr	r7,  =UART0_DIV
	str	r7,  [r6,  #0x08]	@ USART_BRR <- 9600 bauds
	ldr	r7,  =0x202c
	str	r7,  [r6,  #0x0c]	@ USART_CR1 <- TxRx enab, 8N1, Rx int
	@ initialization of mcu-id for vars (normally I2c adrs if slave enab)
	set	r7,  #0x200000
	str	r7,  [r10, #28]
	ldr	r6,  =I2C0ADR
	set	r7,  #mcu_id
	str	r7,  [r6]
	@ initialization of APB1 and APB2 Peripheral Clock Power
	ldr	r7,  [r10, #24]
	ldr	r8,  =0x00005E7D
	orr	r7,  r7, r8
	str	r7,  [r10, #24]		@ RCC_APB2ENR <- AFIO,ABCDE,AD12,TM1,SP1
	ldr	r7,  [r10, #28]
	ldr	r8,  =0x00624007	@ TIM2,3,4, SPI2, USART2, I2C1,2
	orr	r7,  r7, r8
	str	r7,  [r10, #28]		@ RCC_APB1ENR <- TM234,SP2,UAR2,3,I2C1,2
	
	@ initialization of SD card pins

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

	@ configure pins and SPI peripheral
	@ SPIn_CR1  <- disable SPIn (clear faults if any)
	ldr	r6, =sd_spi
	ldr	r7, [r6, #0x08]		@ SPIn_SR, read to clear fault flags
	set	r7, #0x00
	str	r7, [r6, #0x00]		@ SPIn_CR1  <- disable SPIn (clr faults)
	@ configure CS pin as gpio out
 	ldr	r6, =sd_cs_gpio
	ldr	r7, [r6, #0x04]		@ r7 <- config pins 8-15
	bic	r7, r7, #0x0f
	orr	r7, r7, #0x01		@ r7 <- PA.8 cfg GPIO out,push-pul,10MHz
	str	r7, [r6, #0x04]
	@ de-select sd
	set	r7, #sd_cs
	str	r7, [r6, #0x14]	@ clear CS pin
	@ de-select inbound SS pin
 	ldr	r6, =sd_spi_gpio
	ldr	r7, [r6, #0x00]		@ r7 <- config of pins 0-7
	bic	r7, r7, #0x0f0000
	orr	r7, r7, #0x080000	@ r7 <- PA.4 (SPI SS) config as input
	str	r7, [r6, #0x00]
	set	r7, #(1 << 4)
	str	r7, [r6, #0x10]		@ set SS pin (PA.4)
	@ config sck, miso and mosi pins as spi (AF push-pull out, GPIOn_CRL/H)
	ldr	r7, [r6, #0x00]		@ r7 <- config of pins 0-7
	bic	r7, r7, #0xff000000
	bic	r7, r7, #0x00f00000
	orr	r7, r7, #0xBB000000
	orr	r7, r7, #0x00B00000	@ r7 <- PA.5,6,7 cfg as AFIO (SPI)
	str	r7, [r6, #0x00]
	@ low speed (approx 400KHz)
	ldr	r6, =sd_spi
	ldr	r7, [r6, #0x08]		@ SPIn_SR, read to clear fault flags
	set	r7, #0x00
	str	r7, [r6, #0x00]		@ SPIn_CR1  <- disab SPIn (clr faults)
	set	r7, #0x74
	str	r7, [r6, #0x00]		@ SPIn_CR1 <- PHA0,POL0,8b,Mst,Enab,280K

  .endif @ sd_is_on_spi
	
  .ifdef sd_is_on_mci

	@ power/clock the SDIO peripheral
	ldr	r7, [r10, #0x14]
	orr	r7, r7, #0x0400
	str	r7, [r10, #0x14]	@ RCC_AHBENR <- power-up sdio
	@ configure SDIO pins: PD2, PC8-12
	ldr	r6,  =ioportd_base
	ldr	r7, [r6]
	bic	r7, r7, #0x0f00
	orr	r7, r7, #0x0b00
	str	r7, [r6]		@ IOPORTD CRL <- PD2 to SDIO AFSEL,PshPl
	ldr	r6,  =ioportc_base
	ldr	r7, [r6, #4]
	lsr	r7, r7, #20
	lsl	r7, r7, #20
	ldr	r8, =0x0bbbbb
	orr	r7, r7, r8
	str	r7, [r6, #4]		@ IOPORTC CRH <- PC8-12 to SDIO AFSEL,PP
	@ power-up and power-on mci peripheral function
	ldr	r6, =sd_mci
	str	r2, [r6]		@ set MCI to power-up phase
	set	r7, #0x0b2
	orr	r7, r7, #0x4100
	str	r7, [r6, #0x04]	@ enable 400KHz MCI CLK, narrow bus
mcipw0:	str	r3, [r6]		@ set MCI to power-on phase
	ldr	r7, [r6]
	eq	r7, #3
	bne	mcipw0

  .endif @ sd_is_on_mci
	
.endif	@ onboard_SDFT

	@ initialization of USB configuration
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB_CONF <- USB dev not yet cnfgd
	
.ifdef	native_usb

  .ifndef always_init_usb		@					<TZC>

    .ifdef STM32_H103
	@ check if USB is powered (PC4 USB-P power pin), otherwise, return
	ldr	r6,  =ioportc_base
	ldr	r7,  [r6,  #0x08]
	tst	r7, #(1 << 4)
	it	eq
	seteq	pc,  lnk
    .endif
    .ifdef STM32_H107
	@ check if USB is powered (PA9 OTG_VBUS power pin), otherwise, return
	ldr	r6,  =ioporta_base
	ldr	r7,  [r6,  #0x08]
	tst	r7, #(1 << 9)
	it	eq
	seteq	pc,  lnk
    .endif
    .ifdef STM32_LCD
	@ check if USB is powered (PA0 USB-P power pin), otherwise, return
	ldr	r6,  =ioporta_base
	ldr	r7,  [r6,  #0x08]
	tst	r7, #0x01
	it	eq
	seteq	pc,  lnk
    .endif

  .endif				@ for .ifndef always_init_usb		<TZC>

	@ enable USB clock
  .ifndef connectivity_ln
	ldr	r7,  [r10, #0x1c]
	orr	r7,  r7, #0x00800000
	str	r7,  [r10, #0x1c]	@ RCC_APB1ENR <- enable clock for USB
  .else
	ldr	r7,  [r10, #0x14]
	orr	r7,  r7, #0x1000
	str	r7,  [r10, #0x14]	@ RCC_AHBENR  <- enable USB OTG FS clock
  .endif
	@ initialization of USB device controller
	ldr	r6,  =USB_LineCoding
	ldr	r7,  =115200
	str	r7,  [r6]		@ 115200 bauds
	set	r7,  #0x00080000
	str	r7,  [r6,  #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	r6,  =USB_CHUNK
	str	r0,  [r6]		@ zero bytes remaining to snd at startup
	ldr	r6,  =USB_ZERO
	str	r0,  [r6]		@ alt interface and dev/interface stat=0
	ldr	r6,  =USB_CONF
	str	r0,  [r6]		@ USB device is not yet configured

  .ifndef connectivity_ln

.ifdef	debug_usb
	
	@ DEBUG
	ldr	r6, =RAMTOP
	add	r7, r6, #4
	str	r7, [r6]
	add	r6, r6, #4
	set	r7, #0
dbgini:	str	r7, [r6]
	add	r6, r6, #4
	tst	r6, #0x1000		@ for STM32_H103 (16KB to 20KB into RAM)
	beq	dbgini

.endif

.ifdef manual_usb_reset
	@ USB disconnect simulation with hard soldered 1.5k pull-up on D+	<TZC>
	@ output 0 to PA12 for some time					<TZC>
	ldr	r6, =usb_base		@					<TZC>
	str	r3, [r6, #0x40]		@ USB_CNT -> powerdown/reset		<TZC>
	ldr	r6, =ioporta_base	@					<TZC>
	ldr	r5, [r6, #0x04]		@ GPIO 8 - 15 reg			<TZC>
	mov	r9, r5			@ save it				<TZC>
	mov	r7, #0xFFF0FFFF		@					<TZC>
	and	r5, r5, r7		@					<TZC>
	mov	r7, #0x00010000		@ 0001 -- output push-pull		<TZC>
	orr	r5, r5, r7		@					<TZC>
	str	r5, [r6, #0x04]		@					<TZC>
	lsl	r5, r1, #12		@					<TZC>
	str	r5, [r6, #0x14]		@ reset pin				<TZC>
	@ wait									<TZC>
	lsl	r7, r1, 17		@					<TZC>
	@ ***FIXME*** How much time should it be?				<TZC>
	@ I expect something around 3 ms					<TZC>
usblp1: subs	r7, r7, #1		@					<TZC>
	bne	usblp1			@					<TZC>
	@ get GPIO back			@					<TZC>
	str	r9, [r6, #0x04]		@					<TZC>
.endif

	set	r5,  #0xA0000000
	ldr	r6,  =usb_base
	str	r1,  [r6,  #0x40]	@ USB_CNTR   -> exit power down mode
	@ need to make sure there's enough time between exitng pwr mode (above)
	@ and exitng reset mode (below).
	@ if needed, block below could probably be moved to after buffer alloc
	@ table initialization or, branch-link to a wait loop
	set	r7,  #0x80		@ 00
hwiwt3:	subs	r7,  r7, #1
	bne	hwiwt3
	str	r0,  [r6,  #0x40]	@ USB_CNTR   -> exit reset mode
	str	r0,  [r6,  #0x40]	@ USB_CNTR   -> exit reset mode, be sure
	str	r0,  [r6,  #0x44]	@ USB_ISTR   -> clr spurious pndng ints
	set	r7,  #0x9C00
	str	r7,  [r6,  #0x40]	@ USB_CNTR   -> int ctr,wakup,susp,reset
	@ end of said 'moveable?' block
	str	r0,  [r6,  #0x50]	@ BTABLE    -> bfr alloc tbl strt ofst=0
	add	r9,  r6, #0x0400
	set	r7,  #0x80
	str	r7,  [r9]		@ ADR0_TX   -> EP0 snd bfr str of=0x0100
	str	r0,  [r9,  #0x04]	@ COUNT0_TX -> 0 bytes to transmit
	set	r7,  #0x88
	str	r7,  [r9,  #0x08]	@ ADR0_RX   -> EP0 rcv bfr str of=0x0110
	set	r7,  #0x1000
	str	r7,  [r9,  #0x0c]	@ COUNT0_RX -> blksz= 2B,bfsz= 8B,0B rcv
	set	r7,  #0x90
	str	r7,  [r9,  #0x10]	@ ADR1_TX   -> EP1 snd bfr str of=0x0110
	str	r0,  [r9,  #0x14]	@ COUNT1_TX -> 0 bytes to transmit
	set	r7,  #0x98
	str	r7,  [r9,  #0x18]	@ ADR1_RX   -> EP1 rcv bfr str of=0x0118
	set	r7,  #0x1000
	str	r7,  [r9,  #0x1c]	@ COUNT1_RX -> blksz= 2B,bfsz= 8B,0B rcv
	set	r7,  #0xa0
	str	r7,  [r9,  #0x20]	@ ADR2_TX   -> EP2 snd bfr str of=0x0120
	str	r0,  [r9,  #0x24]	@ COUNT2_TX -> 0 bytes to transmit
	set	r7,  #0xe0
	str	r7,  [r9,  #0x28]	@ ADR2_RX   -> EP2 rcv bfr str of=0x0160
	set	r7,  #0x8400
	str	r7,  [r9,  #0x2c]	@ COUNT2_RX -> blksz=32B,bfsz=64B,0B rcv
	ldr	r7,  =0x01a0
	str	r7,  [r9,  #0x30]	@ ADR3_TX   -> EP3 snd bfr str of=0x0120
	str	r0,  [r9,  #0x34]	@ COUNT3_TX -> 0 bytes to transmit
	ldr	r7,  =0x01e0
	str	r7,  [r9,  #0x38]	@ ADR3_RX   -> EP3 rcv bfr str of=0x0160
	set	r7,  #0x8400
	str	r7,  [r9,  #0x3c]	@ COUNT3_RX -> blksz=32B,bfsz=64B,0B rcv
	@ if needed, block below could probably be moved to after buffer alloc
	@ table initialization or, branch-link to a wait loop
	ldr	r7,  =0x3230
	str	r7,  [r6]		@ USB_EP0R      -> cfg EP0 as control EP
	set	r7,  #0x80
	str	r7,  [r6,  #0x4c]	@ USB_DADDR	-> enable USB, address 0
	
  .else	@ connectivity line USB OTG FS
	@
	@ Note:	This interface is not operational in this version
	@	Code below is under construction.
	@

.ifdef	debug_usb
	
	@ DEBUG
	ldr	r6, =RAMTOP
	add	r7, r6, #4
	str	r7, [r6]
	add	r6, r6, #4
	set	r7, #0
dbgini:	str	r7, [r6]
	add	r6, r6, #4
	tst	r6, #0x10000
	beq	dbgini

.endif

	ldr	r6,  =usb_base
	ldr	r7,  =0x40002487
	str	r7,  [r6, #0x0c]	@ GUSBCFG <- force dev mod,trdt=9(72MHz)
	set	r7,  #0x81
	str	r7,  [r6, #0x08]	@ GAHBCFG <- unmsk glbl ints,Txlvl=0
	ldr	r7,  =0x041010
	str	r7,  [r6, #0x18]	@ GINTMSK <- unmsk RXFLVL,IN,RESET ints
	add	r6,  r6, #0x0800
	ldr	r7,  [r6]
	orr	r7,  r7,  r3
	str	r7,  [r6]		@ OTG_FS_DCFG <- dev is full sped,adrs 0
	sub	r6,  r6, #0x0800
	set	r7,  #0x090000
	str	r7,  [r6, #0x38]	@ OTG_FS_GCCFG <- power up, VBus sensing
	
  .endif @ for ifndef connectivity_ln
	
  .ifdef STM32_H103
	@ signify to USB host that device is attached on USB bus (set PC11 low)
	ldr	r6,  =ioportc_base
	ldr	r7,  [r6,  #0x04]
	bic	r7,  r7, #0x00F000
	orr	r7,  r7, #0x007000
	str	r7,  [r6,  #0x04]	@ GPIOC_CRH <- PC11(DISC) GP out,open dr
	set	r7,  #0x0800		@ r7 <- pin 11
	str	r7,  [r6,  #io_clear]
  .endif
  .ifdef STM32_LCD
	@ signify to USB host that device is attached on USB bus (set PD3 low)
	ldr	r6,  =ioportd_base
	ldr	r7,  [r6,  #0x00]
	bic	r7,  r7, #0x00F000
	orr	r7,  r7, #0x007000
	str	r7,  [r6,  #0x00]	@ GPIOA_CRL <- PD3(DISC) GP out,open dr
	set	r7,  #0x08		@ r7 <- pin 3
	str	r7,  [r6,  #io_clear]
  .endif
	
.endif	@ native_usb

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

.ifdef STM32_H103
_func_
FlashInitCheck: @ return status of boot override pin (PA.0) in rva
	ldr	rva, =ioporta_base	@ rva <- GPIO port A for PA0
	ldr	rva, [rva, #0x08]	@ rva <- status of Port A pins
	and	rva, rva, #0x01		@ rva <- PA0 only (non-0 if hi)
	set	pc,  lnk		@ return
.endif

.ifdef STM32_H107
_func_
FlashInitCheck: @ return status of boot override pin (WKUP button, PA.0) in rva
	ldr	rva, =ioporta_base	@ rva <- GPIO port A for PA0
	ldr	rva, [rva, #0x08]	@ rva <- status of Port A pins
	mvn	rva, rva		@ rva <- inverted pin statuses
	and	rva, rva, #0x01		@ rva <- PA0 only (0 if pressed)
	set	pc,  lnk		@ return
.endif

.ifdef STM32_DT_Board
_func_	
FlashInitCheck: @ return status of  boot override pin (SW1, PC.9) in rva
	ldr	rva, =ioportc_base	@ rva <- GPIO port C for PC9
	ldr	rva, [rva, #0x08]	@ rva <- status of Port C pins
	and	rva, rva, #0x0200	@ rva <- PC9 only (non-0 if hi)
	set	pc,  lnk		@ return
.endif

.ifdef STM32_LCD
_func_	
FlashInitCheck: @ return status of boot override pin (I2C1_SDA1, PB.7) in rva
	ldr	rva, =ioportb_base	@ rva <- GPIO port B for PB7
	ldr	rva, [rva, #0x08]	@ rva <- status of Port B pins
	and	rva, rva, #0x0080	@ rva <- PB7 only (non-0 if hi)
	set	pc,  lnk		@ return
.endif


_func_	
wrtfla:	@ write to flash, sv2 = page address, sv4 = file descriptor
_func_	
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	
	set	rvc, #F_PAGE_SIZE
_func_
wrtfle:	@ [internal entry] (for wrtflr = file pseudo-erase)
	stmfd	sp!, {sv3}		@ store scheme registers onto stack
	ldr	rva, =0x40022000	@ rva <- flash registers base address
	set	rvb, #0x01		@ rvb <- bit 0, PG (program)
	str	rvb, [rva, #0x10]	@ set program command in FLASH_CR
	vcrfi	sv3, sv4, 3		@ sv3 <- buffer address from file desc
	@ check for file pseudo-erasure
	eq	rvc, #0
	it	eq
	strheq	rvc, [sv2]		@ write half-word to flash
	beq	wrtfl1
wrtfl0:	@ write #F_PAGE_SIZE bytes to flash
	sub	rvc, rvc, #2
	ldrh	rvb, [sv3, rvc]		@ rvb <- half-word to write, from buffer
	strh	rvb, [sv2, rvc]		@ write half-word to flash
wrtfl1:	@ wait for flash ready
	ldr	rvb, [rva, #0x0c]	@ rvb <- FLASH_SR
	tst	rvb, #0x01		@ is BSY still asserted?
	bne	wrtfl1			@	if so,  jump to keep waiting
	eq	rvc, #0			@ done?
	bne	wrtfl0			@	if not, jump to keep writing
	@ exit
	set	rvb, #0x00		@ rvb <- 0
	str	rvb, [rva, #0x10]	@ clear contents of FLASH_CR
	ldmfd	sp!, {sv3}		@ restore scheme registers from stack
	set	pc,  lnk		@ return

_func_	
wrtflr:	@ pseudo-erase a file flash page, sv2 = page address, sv4 = file desc
	@ Note:	overwriting a flash cell w/anything other than 0x00 can produce
	@	errors on this MCU. For this reason, #0 is used here (vs #i0).
	set	rvc, #0
	b	wrtfle

_func_	
ersfla:	@ erase flash sector that contains page address in sv2
_func_	
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	ldr	rva, =0x40022000	@ rva <- flash registers base address
	set	rvb, #0x02		@ rvb <- bit 1, PER (page erase)
	str	rvb, [rva, #0x10]	@ set page erase command in FLASH_CR
	str	sv2, [rva, #0x14]	@ set page to erase in FLASH_AR
	set	rvb, #0x42		@ rvb <- bits 6 & 1, STRT + PER (erase)
	str	rvb, [rva, #0x10]	@ FLASH_CR strt erase (stalls cpu)
ersfl0:	ldr	rvb, [rva, #0x0c]	@ rvb <- FLASH_SR
	tst	rvb, #0x01		@ is BSY still asserted?
	bne	ersfl0			@	if so,  jump to keep waiting
	set	rvb, #0x00		@ rvb <- 0
	str	rvb, [rva, #0x10]	@ clear contents of FLASH_CR
	set	pc,  lnk		@ return


.ltorg

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
	ldr	rvb, [rva, #0x08]	@ SPIn_SR, read to clr fault flag if any
	set	rvb, #0x00
	str	rvb, [rva, #0x00]	@ SPIn_CR1  <- disab SPIn, clr faults
	set	rvb, #0x44
	str	rvb, [rva, #0x00]	@ SPIn_CR1 <- PHA0,POL0,8b,Mstr,Enab,18M
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	@ modifies:	rva, rvb
	ldr	rva, =sd_spi
	ldr	rvb, [rva, #0x08]	@ SPIn_SR, read to clr fault flag if any
	set	rvb, #0x00
	str	rvb, [rva, #0x00]	@ SPIn_CR1  <- disab SPIn, clr faults
	set	rvb, #0x74
	str	rvb, [rva, #0x00]	@ SPIn_CR1 <- PHA0,POL0,8b,Mstr,Ena,280K
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
sd_get:	@ _sgb get sub-routine
	@ modifies:	rva, rvb
	set	rvb, #0xff
_func_	
sd_put:	@ _sgb put sub-routine
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
	set	pc, lnk

  .endif  @ sd_is_on_spi

  .ifdef sd_is_on_mci

_func_
_sgb:	@ [internal only]
	@ sd-get-block internal func
	@ on entry:  rvc <- block number to be read (scheme int)
	@ on entry:  sv3 <- buffer in which to store block data (scheme bytevec)
	@ on exit:   sv3 <- updated buffer
	@ modifies:  sv3, sv5, rva, rvb, rvc
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
sgb_sr:	@ start/restart transfer
	@ prepare for read-block
	bl	sd_pre			@ prepare mci
	set	rvb, rvc
	bl	sd_arg			@ set arg (block number) in MCIargument
	@ send cmd 17 (read single block)
	set	rvb, #17
	bl	sd_cmd
	eq	rva, #0
	itT	ne
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	sgb_sr
	@ MCIDataCtl <- 512B, block, from card
	ldr	rva, =sd_mci		@ rva <- mci address
	set	rvb, #0x93
	str	rvb, [rva, #0x2c]
	@ get and save data
	set	rvc, #0
sgb_gd:	@ get-data loop
	ldr	rvb, [rva, #0x34]	@ stat
	tst	rvb, #0x3f		@ error?
	itT	ne
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	sd_cm1			@	if so,  jump to restart
	tst	rvb, #0x220000		@ is data available?
	beq	sgb_gd
	ldr	rvb, [rva, #0x80]
	str	rvb, [sv3, rvc]
	add	rvc, rvc, #4
	eq	rvc, #512
	bne	sgb_gd
	@ return
	orr	lnk, sv5, #lnkbit0
	set	pc,  lnk

_func_
_spb:	@ [internal only]
	@ sd-put-block internal func
	@ on entry:  rvc <- block number to be written (scheme int)
	@ on entry:  sv3 <- buffer with block data to write to sd (bytevector)
	@ modifies:  sv5, rva, rvb, rvc
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
spb_sr:	@ start/restart transfer
	@ prepare for write-block
	bl	sd_pre			@ prepare mci
	set	rvb, rvc
	bl	sd_arg			@ set arg (block number) in MCIargument
	@ send cmd 24 (write single block)
	set	rvb, #24
	bl	sd_cmd
	eq	rva, #0
	itT	ne
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	spb_sr
	@ MCIDataCtl <- 512B, block, to card
	ldr	rva, =sd_mci		@ rva <- mci address
	set	rvb, #0x91
	str	rvb, [rva, #0x2c]
	@ write data
	set	rvc, #0
	adr	lnk, spb_sr
spb_wd:	@ write-data loop
	ldr	rvb, [rva, #0x34]	@ stat
	tst	rvb, #0x3f		@ error?
	itT	ne
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	sd_cm1			@ if so,  jump to restart
	tst	rvb, #0x044000
	beq	spb_wd
	ldr	rvb, [sv3, rvc]
	str	rvb, [rva, #0x80]
	add	rvc, rvc, #4
	eq	rvc, #512
	bne	spb_wd
	@ wait for DataBlockEnd
	adr	lnk, spb_sr
spb_wt:	@ wait loop
	ldr	rvb, [rva, #0x34]	@ stat
	tst	rvb, #0x3f		@ error?
	itT	ne
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	sd_cm1			@ jump to restart
	tst	rvb, #0x0400
	beq	spb_wt
	ldr	rvc, [rva, #0x14]	@ rvc <- response0	
spb_ts:	@ wait for card in ready-tran state
	bl	sd_pre			@ prepare mci
	set	rvb, #0
	bl	sd_arg			@ set arg (eg. block num) in MCIargument
	set	rvb, #13
	bl	sd_cmd
	eq	rva, #0
	it	ne
	eqne	rvb, #9
	bne	spb_ts
	@ return
	orr	lnk, sv5, #lnkbit0
	set	pc,  lnk

_func_	
sd_pre:	@ mci-prep subroutine
	set	rvb, #0
	ldr	rva, =sd_mci
	str	rvb, [rva, #0x0c]	@ clear previous MCI command
	set	rvb, #0x0700
	orr	rvb, rvb, #0xff
	str	rvb, [rva, #0x38]	@ clear MCI Stat flags
	set	rvb, #(1 << 27)
	str	rvb, [rva, #0x24]	@ set timeout to > 1e8 in MCIDataTimer
	set	rvb, #512
	str	rvb, [rva, #0x28]	@ set MCIDataLength to 512
	set	pc,  lnk

_func_	
sd_arg:	@ mci-arg subroutine (set arg)
	@ on entry: rvb <- arg (0 as raw int, or block number as scheme int)
	ldr	rva, =sd_mci
	bic	rvb, rvb, #3
	lsl	rvb, rvb, #7
	str	rvb, [rva, #0x08]	@ set arg in MCIargument
	set	pc,  lnk
	
_func_	
sd_cmd:	@ mci-cmd subroutine (put cmd)
	@ on entry: rvb <- cmd
	orr	rvb, rvb, #0x0440
	ldr	rva, =sd_mci		@ rva <- mci address
	str	rvb, [rva, #0x0c]
sd_cm0:	@ comand wait loop
	ldr	rvb, [rva, #0x34]	@ stat
	tst	rvb, #0x04		@ cmd timeout?
	bne	sd_cm1
	tst	rvb, #0x40
	beq	sd_cm0
	@ get response
	ldr	rvb, [rva, #0x14]	@ response
	lsr	rvb, rvb, #8
	and	rvb, rvb, #0x0f
	eq	rvb, #9			@ cmd rcvd w/card rdy & in tran state?
	itT	eq
	seteq	rva, #0
	seteq	pc,  lnk
_func_	
sd_cm1:	@ wait then restart transfer
	@ [also: internal entry]
	set	rvb, #(1 << 18)
sd_cm2:	@ wait loop
	subs	rvb, rvb, #1
	bne	sd_cm2
	ldr	rva, =sd_mci	
	ldr	rvb, [rva, #0x14]	@ response
	lsr	rvb, rvb, #8
	and	rvb, rvb, #0x0f
	set	pc,  lnk
	
_func_	
sd_slo:	@ configure mci speed (low = 400 KHz), 1-bit bus, clock enabled
	ldr	rva, =sd_mci
	set	rvb, #0x4100
	orr	rvb, rvb, #0xb2
	str	rvb, [rva, #0x04]	@ 400KHz,1b bus,CLK enab,HW flow cntrl
	set	pc,  lnk

_func_	
sd_fst:	@ configure mci speed (high = 2 MHz), wide bus, clock enabled
	ldr	rva, =sd_mci
	set	rvb, #0x4900
	orr	rvb, rvb, #0x22
	str	rvb, [rva, #0x04]        @ 2 MHz,wide bus,CLK enab,HW flow cntrl
	set	pc,  lnk

_func_	
sdpcmd:	@ function to write a command to SD/MMC card during initialization
	@ on entry:	sv4 <- cmd (scheme int)
	@ on entry:	rvc <- arg (raw int)
	@ on exit:	rvb <- response0
	@ modifies:	rva, rvb
	ldr	rva, =sd_mci
	set	rvb, #0
	str	rvb, [rva, #0x0c]	@ clear previous cmd
	set	rvb, #0x0700
	orr	rvb, rvb, #0xff
	str	rvb, [rva, #0x38]	@ clear stat flags
	str	rvc, [rva, #0x08]	@ set arg in MCIargument
	int2raw	rvb, sv4
	and	rvb, rvb, #0xff
	orr	rvb, rvb, #0x0400
	eq	sv4, #i0
	it	ne
	orrne	rvb, rvb, #0x40
	tst	sv4, #0x10000000
	it	ne
	orrne	rvb, rvb, #0x80
	str	rvb, [rva, #0x0c]	@ send cmd
sdpcmb:	@ wait for mci not busy
	ldr	rvb, [rva, #0x34]
	tst	rvb, #0x3800
	bne	sdpcmb
	set	rvb, #0x200000
sdpcmw:	@ wait a bit more (some cards seem to need this)
	subs	rvb, rvb, #1
	bne	sdpcmw
	@ if CMD3 (get address), check status and exit with indicator if bad
	eq	sv4, #0x0d		@ CMD3?
	bne	sdpcmc
	ldr	rvb, [rva, #0x34]
	eq	rvb, #0x40
	itT	ne
	setne	rvb, #0
	setne	pc,  lnk
sdpcmc:	@ continue
	ldr	rvb, [rva, #0x34]
	lsl	rvb, rvb, #21
	lsr	rvb, rvb, #21
	str	rvb, [rva, #0x38]	@ clear status register
	ldr	rvb, [rva, #0x14]	@ rvb <- response0
	set	pc,  lnk
  	
  .endif  @ sd_is_on_mci

.endif
	
@
@ 2- I2C Interrupt routine
@

.ifdef	include_i2c

_func_
hwi2cr:	@ write-out additional address registers, if needed
	@ on entry:	sv5 <- i2c[0/1]buffer
	@ on entry:	rva <- i2c[0/1] base address (also I2CONSET)
	@ modifies:	rvb
	set	rvb, #0			@ rvb <- 0 bytes to send (scheme int)
	tbsti	rvb, sv5, 3		@ store num byts to snd in i2c bfr[12]
	@ initiate i2c read/write, as master
	set	rvb, #0
	strh	rvb, [rva, #i2c_stat1]	@ clear SR1 clear-able error bits
	swi	run_normal		@ re-enable interrupts
	ldrh	rvb, [rva, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x100	@ rvb <- contents orred with start bit
	strh	rvb, [rva, #i2c_cr1]	@ init bus mstrng, wrt strt to I2C0/1_CR
hwi2r0:	@ wait for mcu address and registers to have been transmitted
	swi	run_no_irq			@ disable interrupts
	tbrfi	rvb, sv5, 1		@ rvb <- data rdy stat frm i2cbuffer[4]
	eq	rvb, #f			@ is i2c dat rdy=#f (adrs hav been Txd)?
	it	eq
	seteq	pc,  lnk		@	if so, jump to continue
	swi	run_normal		@ re-enable interrupts
	b	hwi2r0			@ jump to keep waiting

_func_
hwi2ni:	@ initiate i2c read/write, as master
	@ possibly as a re-start condition during read (after writing adrs byts)
	@ on entry:	rva <- i2c[0/1] base address (also I2CONSET)
	@ modifies:	rvb
	set	rvb, #0
	strh	rvb, [rva, #i2c_stat1]	@ clear SR1 clear-able error bits
	ldrh	rvb, [rva, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x100	@ rvb <- contents orred with start bit
	strh	rvb, [rva, #i2c_cr1]	@ init bus mstrng, wrt strt to I2C0/1_CR
	ldrh	rvb, [rva, #i2c_cr2]	@ rvb <- current content of I2C[0/1]_CR2
	orr	rvb, rvb, #0x0400	@ rvb <- strt gnrtng Tx ints, eg.restart
	strh	rvb, [rva, #i2c_cr2]	@ update I2C[0/1]_CR2
	set	pc,  lnk
	
_func_
hwi2st:	@ get i2c interrupt status and base address
	@ on entry:	rva <- i2c[0/1] base address
	@ modifies:	rvb
	ldrh	rvb, [rva, #i2c_stat2]	@ rvb <- I2C Status from SR2
	tst	rvb, #1			@ are we in slave mode?
	ldrh	rvb, [rva, #i2c_stat1]	@ rvb <- I2C Status from SR1
	itE	eq
	biceq	rvb, rvb, #0x20		@	if so,  rvb <- clr bit 5, slave
	orrne	rvb, rvb, #0x20		@	if not, rvb <- set bit 5, master
	@ get rid of BTF	
	bic	rvb, rvb, #0x04
	set	pc,  lnk

_func_
i2c_hw_branch:	@ process interrupt
	eq	rvb, #0x02		@ Slave Rd/Wrt my adrs rcgnzd, EV1 ADDR
	beq	i2c_hw_slv_ini
	eq	rvb, #0x40		@ Slave Rd  -- new data rcvd, EV2 RxNE
	beq	i2c_hw_rs_get
	eq	rvb, #0x80		@ Slave Wrt -- mstr reqsts byte EV3 TxE
	beq	i2c_hw_ws_put
	tst	rvb, #0x0400		@ Slave Wrt -- NAK rcvd Tx done EV3-1 AF
	bne	i2c_hw_ws_end
	tst	rvb, #0x0010		@ Slave Rd  -- STOP rcvd, EV4 STOPF
	bne	i2c_hw_rs_end
	tst	rvb, #0x01		@ Mstr Rd/Wrt - bus now mstrd EV5 SB,MSL
	bne	i2c_hw_mst_bus
	eq	rvb, #0x21		@ Mstr Rd/Wrt - bus now mstrd EV5 SB,MSL
	beq	i2c_hw_mst_bus
	tst	rvb, #0x02		@ Mstr Rd/Wrt - slave ackn adrs EV6 ADDR
	bne	i2c_hw_mst_ini
	eq	rvb, #0x60		@ Mstr Rd -- new byte rcvd EV7 RxNE,MSL
	beq	i2c_hw_rm_get
	eq	rvb, #0xA0		@ Mstr Wrt slv ok to rcv dat EV8 TxE,MSL
	beq	i2c_wm_put
	set	pc,  lnk
	
_func_
i2c_hw_slv_ini: @ Slave Read/Write -- my address recognized  (EV1)
	tbrfi	rva, sv2, 0		@ r6  <- channel-busy status
	eq	rva, #f			@ is channel free?
	itT	eq
	seteq	rva, #i0		@	if so,  rva <- 0 (schm int)
	tbstieq rva, sv2, 0		@	if so,  store 0 as channel-busy
	set	rva, #0			@ r6  <- 0
	tbsti	rva, sv2, 4		@ store 0 as num bytes sent/received
	b	i2cxit

_func_
i2c_hw_rs_get:	
	tbrfi	rvb, sv2, 4		@ r7  <- number of bytes sent
	eq	rvb, #0
	itT	eq
	tbstieq rvb, sv2, 2		@	if so,  store 0 dat rcvd so far
	bleq	yldon
	b	i2c_rs_get

_func_
i2c_hw_ws_put:
	tbrfi	rvb, sv2, 4		@ rvb <- number of bytes sent
	eq	rvb, #0
	beq	i2wsp0
	tbrfi	rva, sv2, 3		@ rva <- number of bytes to send
	eq	rva, rvb
	bne	i2c_ws_put
	b	i2cxit
	
i2wsp0:	@ set number of bytes to send
	bl	gldon
	tbrfi	rva, sv2, 0		@ r6  <- channel-busy status
	eq	rva, #i0		@ was channel free at start of transfer?
	itTTT	eq
	tbstieq rva, sv2, 1		@	if so,  store 0 dat-not-rdy/adrs
	ldreq	rva, =eof_char		@	if so,  rva <- eof-character
	streq	rva, [glv, sv1]		@	if so,  store eof-char to snd
	seteq	rva, #4			@	if so,  rva <- 4=num byts to snd
	it	eq
	tbstieq rva, sv2, 3		@	if so,  store 4=num byts to snd
	b	i2c_ws_put

_func_
i2c_hw_ws_end:	@ Slave Write -- NAK received, Tx done,	  EV3-1	- SR2, AF, #0x10
	ldrh	rvb, [sv3, #i2c_stat1]	@ rvb <- current cntnt of I2C[0/1]_STAT1
	bic	rvb, rvb, #0x0400	@ rvb <- contents with cleared AF bit
	strh	rvb, [sv3, #i2c_stat1]	@ clear AF bit
	b	i2c_ws_end

_func_
i2c_hw_rs_end:	@ Slave Read -- STOP or re-START received
	ldrh	rvb, [sv3, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR1
	bic	rvb, rvb, #0x0200	@ rvb <- contents with cleared stop bit
	strh	rvb, [sv3, #i2c_cr1]	@ clear stop bit
	b	i2c_rs_end

_func_
i2c_hw_mst_bus:	@ Master Read/Write -- bus now mastered (EV5)
	bl	gldon
	tbrfi	rva, sv2, 0		@ rva <- adrs of mcu to snd dat to (int)
	lsr	rva, rva, #1		@ rva <- mcu-id as int -- ends with 0
	strb	rva, [sv3, #i2c_thr]	@ set address of mcu to send data to
	@ wait for target to be addressed (avoids getting a TxE int before then)
	@ a bit risky if remote device doesn't exist we get jammed inside int!!!
	set	rvb, #0x1000000
i2c_hw_mst_bwt:
	subs	rvb, rvb, #1
	beq	i2cxit
	ldrh	rva, [sv3, #i2c_stat1]
	tst	rva, #0x02
	beq	i2c_hw_mst_bwt
_func_
i2c_hw_mst_ini: @ Master Read/Write -- slave aknowledged address (EV6)
	ldrh	rvb, [sv3, #i2c_stat2]	@ rvb <- I2C Status from SR2 (clear int)
	tbrfi	rvb, sv2, 0		@ rva <- adr of mcu to wrt/rd dat to/frm
	tst	rvb, #0x02		@ is this a write operation?
	beq	i2c_wm_ini
	ldrh	rvb, [sv3, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR
	orr	rvb, rvb, #0x0400	@ rvb <- contents with ack bit set
	strh	rvb, [sv3, #i2c_cr1]	@ set ack in cr	
	b	i2c_rm_ini

_func_
hwi2we:	@ set busy status/stop bit at end of write as master
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	@ on entry:	rvb <- #f
hwi2ww:	@ wait for either TxE or BTF to be set before setting STOP condition
	ldrh	rvb, [sv3, #i2c_stat1]	@ rvb <- current content of I2C0/1_STAT1
	tst	rvb, #0x84
	beq	hwi2ww
	tbrfi	rva, sv2, 3		@ r6  <- num data byts to send (raw int)
	eq	rva, #0			@ were we sendng 0 byts (rd as mstr/don)
	beq	hwi2wv
	set	rvb, #f			@ rvb <- #f
	tbsti	rvb, sv2, 0		@ set busy status to #f (transfer done)
	ldrh	rvb, [sv3, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR1
	orr	rvb, rvb, #0x0200	@ rvb <- contents orred with stop bit
	strh	rvb, [sv3, #i2c_cr1]	@ initiate stop (wrt stop to I2C0/1_CR1)
	set	pc,  lnk

hwi2wv:	@ prepare for re-start
	ldrh	rvb, [sv3, #i2c_cr2]	@ rvb <- current content of I2C[0/1]_CR2
	tst	rvb, #0x02		@ is interface busy?
	bne	hwi2wv
	bic	rvb, rvb, #0x0400	@ rvb <- stop generating Tx interrupts
	strh	rvb, [sv3, #i2c_cr2]	@ update I2C[0/1]_CR2
	set	pc,  lnk
	
_func_
i2c_hw_rm_get:
	ldrh	rvb, [sv3, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR
	tst	rvb, #0x0400		@ is ack bit asserted?
	bne	i2c_rm_get		@	if so,  jump to normal read
	b	i2c_rm_end		@ jmp to end rd as mstr (nack prior byt)

_func_
hwi2re:	@ set stop bit if needed at end of read-as-master
	ldrh	rvb, [sv3, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR1
	orr	rvb, rvb, #0x0600	@ rvb <- contents ord w/stop + ack bit
	strh	rvb, [sv3, #i2c_cr1]	@ initiate stop (write stop to I2Cn_CR1)

hwi2ry:	@ wait for device not busy, no longer master
	ldrh	rvb, [sv3, #i2c_stat2]
	tst	rvb, #0x03
	bne	hwi2ry
hwi2rz:	@ flush DR
	ldrh	rvb, [sv3, #i2c_stat1]
	tst	rvb, #0x40
	it	ne
	ldrbne	rvb, [sv3, #i2c_rhr]
	bne	hwi2rz	
	set	pc,  lnk
	
_func_
hwi2cs:	@ clear interrupt (if it needs a read of SR2 to clear)
	ldrh	rva, [sv3, #i2c_stat2]
	set	pc,  lnk
	
_func_
i2cstp:	@ prepare to end Read as Master transfer
	ldrh	rvb, [sv3, #i2c_cr1]	@ rvb <- current content of I2C[0/1]_CR
	bic	rvb, rvb, #0x0400	@ rvb <- contents with ack bit cleared
	strh	rvb, [sv3, #i2c_cr1]	@ set nak in cr
	set	pc,  lnk

_func_
i2putp:	@ Prologue:	write addtnl adrs byts to i2c, from bfr/r12 (prologue)
	@ check if address bytes need sending
	@ if not, return via lnk unless #bytes to write is zero
	@		-> if so, jump to i2pute o2 i2c_wm_end
	@ if so, write them out and subtract count, then skip i2putc
	@		-> jump to i2pute
	@ with link set to i2cxit
	tbrfi	rva, sv2, 1		@ rva <- num addtnl adrs byts to snd
	eq	rva, #i0		@ no more address bytes to send?
	itTT	eq
	tbrfieq rva, sv2, 3		@	if so,  rva <- num byts to send
	tbrfieq rvb, sv2, 4		@	if so,  rvb <- num byts sent raw
	eqeq	rva, rvb		@	if so,  done sending data?
	beq	i2c_wm_end		@		if so, stop or restart
	tbrfi	rvb, sv2,  1		@ rvb <- num adrs bytes remaining to snd
	eq	rvb, #i0		@ done sending address bytes?
	it	eq	
	seteq	pc,  lnk		@	if so,  return
	and	rvb, rvb, #0x03
	eq	rvb, #i0
	bne	i2cxit	
	tbrfi	rvb, sv2,  1		@ rvb <- num adrs byts remnng to snd
	sub	rvb, rvb, #4		@ rvb <- updtd num adrs byts to snd
	tbsti	rvb, sv2, 1		@ stor updtd num adrs byts to snd
	add	rva, sv2, #8		@ rva <- adrs of addtl adrs byts in bfr
	lsr	rvb, rvb, #2
	ldrb	rva, [rva, rvb]		@ rva <- next address byte to send
	strb	rva, [sv3, #i2c_thr]	@ put next data byte in I2C data reg
	b	i2cxit

_func_
i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	tbrfi	rva, sv2, 3		@ rva <- num data bytes to snd (raw int)
	tbrfi	rvb, sv2, 4		@ rvb <- num data bytes sent (raw int)
	eq	rva, rvb		@ done sending?
	beq	i2c_wm_end		@	if so,  jump to end transfer
	set	pc,  lnk


.endif






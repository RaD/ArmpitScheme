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


	
hwinit:
@ initialize the Memory Accelerator Module (MAM) for 60MHZ operation -----------
@ according to the Errata published online, disabling MAM can cause
@ problems with SRAM reading while running a program from Flash
@ recommended settings are: MAMCR = 0x2 and MAMTIM = 0x1 (<20MHZ)
@ 0x2 (<40MHZ) 0x3 (>40MHZ) or MAMCR = 0x0 and MAMTIM = 0x1.
@ To set MAMTIM first set MAMCR to 0 then back to non-zero value
	@ pre-set common values
	set	fre,  #0
	set	sv1,  #1
	set	sv2,  #2
	set	sv3,  #3
	set	sv4,  #4
	set	sv5,  #5
	@ set MAMTIM
	ldr	rva,  =sys_ctrl
	str	fre,  [rva]		@ MAMCR  <- 0
  .ifndef LPC2478_STK
	str	sv3,  [rva,  #0x04]	@ MAMTIM <- 3 for PLL at 60 MHZ
	str	sv2,  [rva]		@ MAMCR  <- 2 to enable MAMTIM
	str	sv1,  [rva,  #0x0100]	@ VPBDIV  <- peripheral clock divisor
  .else
	str	sv4,  [rva,  #0x04]	@ MAMTIM <- 4 for PLL at 72 MHZ
	str	sv2,  [rva]		@ MAMCR  <- 2 to enable MAMTIM
	add	rvb, rva, #0x0100
	@ enable the main oscillator
	set	rvc, #0x20
	str	rvc, [rvb, #0xa0]
moswt0:	@ wait for main oscillator to be ready
	ldr	rvc, [rvb, #0xa0]
	tst	rvc, #0x40
	beq	moswt0
	@ select clocks and dividers
	set	sv4, #0xaa
	set	sv5, #0x55
	str	sv1, [rva,  #0x80]	@ PLLCON  <-    1 == enable+discnnct PLL
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	sv5, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
	str	fre, [rva,  #0x80]	@ PLLCON  <-    0 == disbl+discnnctd PLL
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	sv5, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
	str	sv1, [rvb, #0x0c]	@ CLKSRCSEL <- 1, select Main Osc
	str	sv3, [rvb, #0x04]	@ CCLKCFG   <- 3, CPU = 288MHz/4 = 72MHz
	set	rvc, #0x05
	str	rvc, [rvb, #0x08]	@ USBCLKCFG <- 5, USB = 288MHz/6 = 48MHz
	ldr	rvc, =0x55555555
	str	rvc, [rvb, #0xa8]	@ PCLKSEL1 <- peripherals at 72 MHz
	str	rvc, [rvb, #0xac]	@ PCLKSEL2 <- peripherals at 72 MHz
  .endif
	@ configure the PLL
	ldr	rvb, =PLL_PM_parms
	str	rvb, [rva,  #0x84]	@ PLLCFG  <- PLL_PM_parms
	str	sv1, [rva,  #0x80]	@ PLLCON  <-    1 == enable PLL
	set	sv4, #0xaa
	set	sv5, #0x55
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	sv5, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
pllwt0:	ldr	rvb, [rva,  #0x88]	@ rvb <- PLL status
	tst	rvb, #PLOCK_bit		@ is PLL locked?
	beq	pllwt0			@	if not, jump to keep waiting
	str	sv3, [rva,  #0x80]	@ PLLCON  <-    3 == connect PLL
	str	sv4, [rva,  #0x8c]	@ PLLFEED <- 0xaa == feed PLL
	str	sv5, [rva,  #0x8c]	@ PLLFEED <- 0x55 == feed PLL
	@ re-set modified common values
	set	sv4,  #4
	set	sv5,  #5
  .ifdef LPC_H2214
	@ initialization of external memory parameters (LPC2214)
	ldr	rva,  =0xE002C014	@ rva  <- PINSEL2
	ldr	rvb,  =0x0F000924
	str	rvb,  [rva]		@ PINSEL2 <- 
					@ F=A23:1 are address lines (not A0)
					@ 9=P3.27:26->WE,CS1
					@ 2=P2.31:0-D31:0,P3.31:28-BLS0:3,
					@   P1.1:0-OE,CS0
					@ 4=P1.31:26-debug,P1.25:16-gpio not trc
@ R/W bus wait (IDCY) set to 16x16.67ns (largest allowable value)
@	ldr	rva,  =0xFFE00000
@	ldr	rvb,  =0x1000348F
@	str	rvb,  [rva]		@ BCG0 <- 
@					@ offchip bank 0,FLASH,MX26LV800BTC,R55ns/W55ns,0x80000000->0x80FFFFFF
@					@ 01/b29:28->MW=16bit,110/b15:11->WST2=6(write=9cycles),1/b10->RBLE=1,
@					@ 100/b9:5  ->WST1=4 (read=7cycles), 1111/b3:0 ->IDCY=F (R/W bus wait)
@					@ note: RW55ns chip should have WST1=3, WST2=3
@	ldr	rvb,  =0x2000040F
@	str	rvb,  [rva,  #0x04]	@ BCFG1 <- 
@					@ offchip bank 1, SRAM, 71V416, R12ns/W12ns, 0x81000000 -> 0x81FFFFFF
@					@ 10/b29:28->MW=32bit,000/b15:11->WST2=0 (write=3cycls),1/b10->RBLE=1,
@					@ 000/b9:5  ->WST1=0 (read=3 cycles), 1111/b3:0->IDCY=F (R/W bus wait)
	@ R/W bus wait (IDCY) set to 25ns (2x16.67ns) rather than 16x16.67ns
	@ as tDF = 25ns on Micron Flash (Chip deselected to High-Z data lines)
	@ (meanwhile, on K6R4016, tDH and tHz = 5ns, but still set to 2x16.67ns
	@ to account for bank switching)
	ldr	rva,  =0xFFE00000
	ldr	rvb,  =0x10003481
	str	rvb,  [rva]		@ BCG0 <- 
					@ offchip bank 0,FLASH,MX26LV800BTC,
					@ R55ns/W55ns,0x80000000->0x80FFFFFF
					@ 01/b29:28->MW=16bit,110/b15:11->WST2=6
					@ (write=9cycles),1/b10->RBLE=1,100/b9:5
					@ ->WST1=4 (read=7cycles), 0001/b3:0 
					@ ->IDCY=2 (R/W bus wait)
					@ note: RW55ns chip should be WST1/2=3/3
	ldr	rvb,  =0x20000401
	str	rvb,  [rva,  #0x04]	@ BCFG1 <- 
					@ offchip bank 1, SRAM,K6R4016V1D-TC10,R/W10ns,0x81000000->0x81FFFFFF
					@ 10/b29:28->MW=32bit,000/b15:11->WST2=0 (write=3cycls),1/b10->RBLE=1,
					@ 000/b9:5  ->WST1=0 (read=3 cycles), 0001/b3:0->IDCY=2 (R/W bus wait)
  .endif
  .ifdef LPC_H2294
	@ initialization of external memory parameters (LPC2294)
	ldr	rva,  =0xE002C014	@ rva  <- PINSEL2
	ldr	rvb,  =0x0F000924
	str	rvb,  [rva]		@ PINSEL2 <- 
					@ F = A23:1 are address lines (not A0)
					@ 9 = P3.27:26->WE,CS1
					@ 2 = P2.31:0->D31:0,  P3.31:28->BLS0:3, P1.1:0->OE,CS0
					@ 4 = P1.31:26->debug, P1.25:16->gpio (not trace)
	@ R/W bus wait (IDCY) set to 20ns (2x16.67ns) rather than 16x16.67ns
	@ as tEHQZ = 20ns on INTEL Flash (Chip deselected to High-Z data lines)
	@ (meanwhile, on K6R4016, tDH and tHz = 5ns, but still set to 2x16.67ns to account for bank switching)
	ldr	rva,  =0xFFE00000
	ldr	rvb,  =0x10003481
	str	rvb,  [rva]		@ BCG0 <- 
					@ offchip bnk0,FLASH,JS28F320C3-BD70,R70ns/W70ns,0x80000000-0x80FFFFFF
					@ 01/b29:28->MW=16bit,110/b15:11->WST2=6(write=9cycles),1/b10->RBLE=1,
					@ 100/b9:5  ->WST1=4 (read=7cycles), 0001/b3:0 ->IDCY=2 (R/W bus wait)
	ldr	rvb,  =0x20000401
	str	rvb,  [rva,  #0x04]	@ BCFG1 <- 
					@ off-chip bank 1, SRAM, K6R4016V1D-UI10,R/W10ns,0x81000000-0x81FFFFFF
					@ 10/b29:28->MW=32bit,000/b15:11->WST2=0 (write=3cycls),1/b10->RBLE=1,
					@ 000/b9:5  ->WST1=0 (read=3 cycles), 0001/b3:0->IDCY=2 (R/W bus wait)
  .endif
  .ifdef LPC2478_STK
	@ configuration of external memory control pins
	@ K4S561632C-TC/L75
	@ see NXP AN10771.pdf for config
	@ also ARM infocenter PL176 for ordering of RASCAS vs SDRAM MODE setting
	ldr	rva, =PINSEL0
	ldr	rvc, =0x55555555
	ldr	rvb, =0x00fcfcc0
	bic	rvb, rvc, rvb
	str	rvb, [rva, #0x14]	@ pinsel5 <- memory bus alternate func
	str	rvc, [rva, #0x18]	@ pinsel6 <- memory bus alternate func
	str	rvc, [rva, #0x1c]	@ pinsel7 <- memory bus alternate func
	bic	rvb, rvc, #0xC0000000
	str	rvb, [rva, #0x20]	@ pinsel8 <- memory bus alternate func
	set	rvb, #0x040000
	str	rvb, [rva, #0x24]	@ pinsel9 <- memory bus alternate func
	lsl	rvc, rvc, #0x01
	ldr	rvb, =0x00fcfcc0
	bic	rvb, rvc, rvb
	str	rvb, [rva, #0x54]	@ pinmode5 <- disable pull-u/d resistor
	str	rvc, [rva, #0x58]	@ pinmode6 <- disable pull-u/d resistor
	str	rvc, [rva, #0x5c]	@ pinmode7 <- disable pull-u/d resistor
	bic	rvb, rvc, #0xC0000000
	str	rvb, [rva, #0x60]	@ pinmode8 <- disable pull-u/d resistor
	set	rvb, #0x080000
	str	rvb, [rva, #0x64]	@ pinmode9 <- disable pull-u/d resistor
	@ initialization of external memory (LPC2478)
	ldr	rva,  =0xFFE08000	@ rva  <- EMC Control
	str	sv1,  [rva]		@ EMCCONTROL <- 1 -- Enable EMC
	str	sv1,  [rva, #0x28]	@ CONFIG <- 1, Cmd delayed w/EMCCLKDELAY
	str	sv1,  [rva, #0x30]	@ tRP   <- 20/13.9 + 1 = 2, prech time
	str	sv3,  [rva, #0x34]	@ tRAS  <- 45/13.9 + 1 = 4, row act time
	str	fre,  [rva, #0x38]	@ tSREX <- 1, self-rfrsh exit tim (tXSR)
	str	fre,  [rva, #0x3C]	@ tAPR  <- 1, last data out to active
	str	sv3,  [rva, #0x40]	@ tDAL  <- 1+20/13.9=3, last din to act
	str	fre,  [rva, #0x44]	@ tWR   <- 1, wrt rcvr tim tDPL,RWL,RDL
	str	sv4,  [rva, #0x48]	@ tRC   <- 65/13.9+1=5, row cycle time
	str	sv4,  [rva, #0x4C]	@ tRFC  <- 66/13.9+1=5, aut-rfrsh/to-act
	str	fre,  [rva, #0x50]	@ tXSR  <- 1, exit self-refresh to activ
	str	sv1,  [rva, #0x54]	@ tRRD  <- 15/13.9+1=2, Bank A to B act
	str	sv1,  [rva, #0x58]	@ tMRD  <- 2, load mode reg to act tRSA
	@ Initialize SDRAM chip (JEDEC)
	ldr	rvb,  =0x0183
	str	rvb,  [rva, #0x20]	@ CONTROL <- 0x0183, 8:7<-11=NOP, clk-clkout run, rfrsh nrml
	@ wait countdown
	set	rvc, #0x080000
	subs	rvc, rvc, #1
	subne	pc,  pc,  #12
	@ keep going
	ldr	rvb,  [rva, #0x20]
	bic	rvb,  rvb, #0x0080
	str	rvb,  [rva, #0x20]	@ CONTROL, SDRAMINI <- 2, bits 8:7<-10, PALL (prchrge all)
	str	sv1, [rva, #0x24]	@ REFRESH <- 1 (refresh every 16 clocks during precharge)
	@ wait countdown
	set	rvc, #0x080000
	subs	rvc, rvc, #1
	subne	pc,  pc,  #12
	@ keep going
	ldr	rvb,  =35
	str	rvb,  [rva, #0x24]	@ REFRESH <-  64ms/8192 = 7.81us -> (78125 / 13.9 + 1) >> 4
	set	rvb, #0x0200
	orr	rvb,  rvb, #0x0002	@ RAS <- 3 clk
	str	rvb,  [rva, #0x0104]	@ RASCAS <- 3, 2,  bit 9:8, 1:0<-10 -- 3 AHB HCLK cycles lat
	ldr	rvb,  =0x4680
	str	rvb,  [rva, #0x100]	@ CONFIG <- 0x0004680, 13 row, 9 col, 32-bit, SDRAM
	ldr	rvb,  [rva, #0x20]
	eor	rvb,  rvb, #0x0180
	str	rvb,  [rva, #0x20]	@ CONTROL, SDRAMINI <- 1, bits 8:7<-01, MODE command
	ldr	rvb,  =0xA0044000	@ **rvb <- RAM Code for sequential burst of 4 words, CAS-2
	ldr	rvb,  [rvb]		@ set mode into RAM mode register
	set	rvb,  #0
	str	rvb,  [rva, #0x20]	@ CONTROL <- 0x0000, NORMAL mode command
	ldr	rvb,  [rva, #0x100]
	orr	rvb,  rvb, #0x080000
	str	rvb,  [rva, #0x100]	@ CONFIG, BUF_EN <- 1, bit 19, enable r/w buffers
	@ wait countdown
	set	rvc, #0x080000
	subs	rvc, rvc, #1
	subne	pc,  pc,  #12
	@ keep going
  .endif
	@ initialization of mcu-id for variables (normally I2c address if slave enabled)
	ldr	rva,  =i2c0_base		@ rva  <- I2C0 base address
	set	rvb,  #mcu_id
	str	rvb,  [rva, #i2c_address]	@ I2C0ADR <- set mcu address
	@ initialization of gpio pins
	ldr	rva, =LEDPINSEL
	str	fre, [rva]		@ LEDs are on P1.21-23 (213X) or P0.23-25 (2106) GPIO function
	ldr	rva, =LEDIO
	ldr	rvb, =ALLLED
	str	rvb, [rva,  #io_dir]	@ make all LED pins an output
	@ initialization of interrupts
	ldr	rva, =int_base		@ rva <- Vectored Interrupt Controller (VIC) base address
	str	fre, [rva,  #0x0c]	@ VICIntSelect   <- all interrupts are IRQ
	ldr	rvb, =genisr
  .ifndef LPC2478_STK
	str	rvb, [rva, #0x34]	@ VICDefVectAddr <- Default IRQ handler
  .else
	add	rvc, rva, #0x100
	str	rvb, [rvc, #0x10]	@ VICVectAddr4  <- TIMER0 IRQ handler = genisr
	str	rvb, [rvc, #0x14]	@ VICVectAddr5  <- TIMER1 IRQ handler = genisr
	str	rvb, [rvc, #0x18]	@ VICVectAddr6  <- UART0  IRQ handler = genisr
	str	rvb, [rvc, #0x1c]	@ VICVectAddr7  <- UART1  IRQ handler = genisr
	str	rvb, [rvc, #0x24]	@ VICVectAddr9  <- I2C0   IRQ handler = genisr
	str	rvb, [rvc, #0x4c]	@ VICVectAddr19 <- I2C1   IRQ handler = genisr
  .endif
	@ initialization of UART0 for 9600 8N1 operation
	ldr	rva,  =PINSEL0		@ rva  <- PINSEL0
  .ifndef LPC2478_STK
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x0F
	orr	rvb, rvb, #0x05
	str	rvb, [rva]		@ PINSEL0      <- Enable UART0 pins (P0.0 and P0.1)
  .else
	ldr	rvb, [rva, #0x40]
	bic	rvb, rvb, #0xF0
	orr	rvb, rvb, #0xA0
	str	rvb, [rva, #0x40]	@ PINMODE0     <- disable pull-up/down resistors on uart0 pins
	ldr	rvb, [rva]
	bic	rvb, rvb, #0xF0
	orr	rvb, rvb, #0x50
	str	rvb, [rva]		@ PINSEL0      <- Enable UART0 pins (P0.2 and P0.3)
  .endif
	ldr	rva, =uart0_base
	str	sv1, [rva, #0x08]	@ U0FCR        <- Enable UART0, Rx trigger-level = 1 char
	set	rvb, #0x80
	str	rvb, [rva, #0x0c]	@ U0LCR        <- Enable UART0 divisor latch
	ldr	rvb, =UART0_DIV_L
	str	rvb, [rva]		@ U0DLL        <- UART0 lower byte of divisor for 9600 baud
	ldr	rvb, =UART0_DIV_H
	str	rvb, [rva, #0x04]	@ U0DLM        <- UART0 upper byte of divisor for 9600 baud
	str	sv3, [rva, #0x0c]	@ U0LCR        <- Disable UART0 divisor latch and set 8N1 transmission
	str	sv1, [rva, #0x04]	@ U0IER        <- Enable UART0 RDA interrupt
	@ initialization of SD card pins
.ifdef	onboard_SDFT

  .ifdef sd_is_on_spi
	
	@ SPI0 interface pins P0.4, P0.5, P0.6 used for SCK0, MISO0, MOSI0
	@ sd_cs (gpio) used for CS
	
	@ configure chip-select pin as gpio out, and de-select sd card
	ldr	rva, =sd_cs_gpio
	ldr	rvb, [rva, #io_dir]
	orr	rvb, rvb, #sd_cs
	str	rvb, [rva, #io_dir]	@ sd_cs_gpio, IODIR <- sd_cs pin set as output
	set	rvb, #sd_cs
	str	rvb, [rva, #io_set]	@ set sd_cs pin to de-select sd card
	@ configure other spi pins: P0.4,5,6 configured via pinsel0 (psl0) as SPI (cfg = #b01)
	ldr	rva, =PINSEL0
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x003f00
	orr	rvb, rvb, #0x001500
	str	rvb, [rva]
  .ifdef spi_old_silicon @ (TINY_2106, LPC_H2214, LPC_H2294)
	@ also configure SSEL0 (P0.7) and tie it to 3.3 Volt manually (with a wire)
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x00c000
	orr	rvb, rvb, #0x004000
	str	rvb, [rva]
  .endif
	@ configure spi mode for card initialization
	ldr	rva, =sd_spi
	set	rvb, #150
	str	rvb, [rva, #0x0c]	@ s0spccr clk <- 60MHz/150 = 400 KHz
	set	rvb, #0x20
	str	rvb, [rva, #0x00]	@ s0spcr (control) #x00 master, 8-bit, POL=PHA=0
	
  .endif
	
  .ifdef sd_is_on_mci

	@ MCI interface with DMA, as implemented on LPC-2478-STK
	@ Pins P1.2, P1.3, P1.5, P1.6, P1.7, P1.11, P1.12 <- MCI function
	
	@ power-up and enable gpdma
	ldr	rva, =sys_ctrl
	ldr	rvb, [rva, #0xc4]
	orr	rvb, rvb, #0x20000000
	str	rvb, [rva, #0xc4]	@ power-up GPDMA (PCONP bit 29)
	ldr	rva, =gdma_base
	str	sv1, [rva, #0x30]	@ enable gpdma, little-endian
	ldr	rva, =bdma_base
	ldr	rvb, =0x02006f
	str	rvb, [rva]		@ init dma buffer with bytevector tag
	@ power-up and configure mci peripheral
	ldr	rva, =sys_ctrl
	ldr	rvb, [rva, #0xc4]
	orr	rvb, rvb, #0x10000000
	str	rvb, [rva, #0xc4]	@ power-up SD/MMC block (PCONP bit 28)
	ldr	rvb, [rva, #0x1ac]
	orr	rvb, rvb, #0x03000000
	str	rvb, [rva, #0x1ac]	@ PCLK_MCI = 9MHz, PCLKSEL1 24:25
	ldr	rvb, [rva, #0x1a0]
	orr	rvb, rvb, #0x08
	str	rvb, [rva, #0x1a0]	@ MCIPWR phase active high (SCS bit 3)
	@ configure mci pins
	ldr	rva, =PINSEL2
	ldr	rvb, [rva]
	ldr	rvc, =0x03c0fcf0
	bic	rvb, rvb, rvc
	ldr	rvc, =0x0280a8a0
	orr	rvb, rvb, rvc
	str	rvb, [rva]		@ P1.2,3,5-7,11,12 <- MCI function (#b10)
	ldr	rvb, [rva, #0x40]
	ldr	rvc, =0x03c0fcf0
	bic	rvb, rvb, rvc
	str	rvb, [rva, #0x40]	@ P1.2,3,5-7,11,12 <- mode 0 (#b00)
	@ power-up and power-on mci peripheral function
	ldr	rva, =mci_base
	str	sv2, [rva]		@ set MCI to power-up phase
	set	rvb, #0x016
	orr	rvb, rvb, #0x100
	str	rvb, [rva, #0x04]	@ enable 400KHz (200KHz?) MCI CLK, narrow bus
mcipw0:	str	sv3, [rva]		@ set MCI to power-on phase
	ldr	rvb, [rva]
	eq	rvb, #3
	bne	mcipw0
	
  .endif

.endif	@ onboard_SDFT
		
  .ifdef LPC_H2294
	@ unlock the INTEL FLASH
	set	rvc, lnk
	bl	unlok
	set	lnk, rvc
  .endif
	@ USB
	ldr	rva,  =USB_CONF
	str	fre,  [rva]		@ USB_CONF <- USB device is not yet configured
  .ifdef SFE_Logomatic2
	@  Turn on USB PCLK in PCONP register (to power up USB RAM)
	ldr	rva,  =0xE01FC0C4	@ rva  <- PCONP = power ctrl for peripherals
	ldr	rvb,  [rva]
	orr	rvb,  rvb, #0x80000000
	str	rvb,  [rva]		@ PCONP <- power the USB RAM and clock, etc...
  .endif @ SFE_Logomatic2
  .ifdef LPC_H2148
	@  Turn on USB PCLK in PCONP register (to power up USB RAM)
	ldr	rva,  =0xE01FC0C4	@ rva  <- PCONP = power ctrl for peripherals
	ldr	rvb,  [rva]
	orr	rvb,  rvb, #0x80000000
	str	rvb,  [rva]		@ PCONP <- power the USB RAM and clock, etc...
  .endif @ LPC_H2148
  .ifdef LCDDemo_2158
	@  Turn on USB PCLK in PCONP register (to power up USB RAM)
	ldr	rva,  =0xE01FC0C4	@ rva  <- PCONP = power ctrl for peripherals
	ldr	rvb,  [rva]
	orr	rvb,  rvb, #0x80000000
	str	rvb,  [rva]		@ PCONP <- power the USB RAM and clock, etc...
  .endif @ LCDDemo_2158
  .ifdef LPC2478_STK
	@  Turn on USB PCLK in PCONP register (to power up USB subsystem)
	ldr	rva,  =0xE01FC0C4	@ rva  <- PCONP = power ctrl for peripherals
	ldr	rvb,  [rva]
	orr	rvb,  rvb, #0x80000000
	str	rvb,  [rva]		@ PCONP <- power the USB RAM and clock, etc...
  .endif @ LPC2478_STK

.ifdef	native_usb

@ 10. initialization of USB device controller
@ 1.5 now that USB RAM is ON, initialize it
	ldr	rva,  =USB_LineCoding
	ldr	rvb,  =115200
	str	rvb,  [rva]		@ 115200 bauds
	set	rvb,  #0x00080000
	str	rvb,  [rva,  #0x04]	@ 8 data bits, no parity, 1 stop bit
	ldr	rva,  =USB_CHUNK
	str	fre,  [rva]		@ zero bytes remaining to send at startup
	ldr	rva,  =USB_ZERO
	str	fre,  [rva]		@ alternate interface and device/interface status = 0
	ldr	rva,  =USB_CONF
	str	fre,  [rva]		@ USB device is not yet configured
	@ see if USB is plugged in (if not, exit USB setup)
.ifndef LPC2478_STK
	ldr	rva,  =PINSEL1
	ldr	rvb,  [rva]
	bic	rvb,  rvb,  #0x00C000
	str	rvb,  [rva]		@ set P0.23 (VBUS) as GPIO
	ldr	rva,  =io0_base
	ldr	rvb,  [rva]
	tst	rvb,  #0x00800000	@ branch to resetC if tst IO0PIN, 0x800000 gives eq
	seteq	pc,  lnk		@ i.e. exit hardare initialization if VBUS is not on
.else
	ldr	rva,  =PINSEL0
	ldr	rvb,  [rva, #0x40]
	bic	rvb,  rvb, #0x30000000
	orr	rvb,  rvb, #0x20000000
	str	rvb,  [rva, #0x40]	@ PINMODE0     <- disable pull-up/down resistor on P0.14/VBUS
	ldr	rvb,  [rva]
	bic	rvb,  rvb,  #0x30000000
	str	rvb,  [rva]		@ set P0.14 (VBUS) as GPIO
	ldr	rva,  =io0_base
	ldr	rvb,  [rva]
	tst	rvb,  #0x00004000	@ branch to resetC if P0.14 (VBUS) is not high
	seteq	pc,  lnk		@ i.e. exit hardare initialization if VBUS is not on
.endif
	@ disable UART0 interrupts if USB is plugged in (they can cause noise on the shared READBUFFER)
	ldr	rva,  =int_base
	set	rvb,  #uart0_int
	str	rvb,  [rva,  #0x14]	@ VicIntEnClear <- Disable UART0 Interrupt (IRQ#6 -> bit 6)
	ldr	rva,  =uart0_base
	str	fre,  [rva,  #0x04]	@ U0IER <- Disable UART0 RDA interrupt
.ifndef LPC2478_STK
	@  3. Turn on PLL1 at 48 MHz for USB clock (see 4-8)
	ldr	rva,  =0xE01FC000
	ldr	rvb,  =PLL1_PM_parms
	str	rvb,  [rva,  #0xa4]	@ PLL1CFG <- dividor and multiplier for 48 MHZ (USB) / configure PLL1
	str	sv1,  [rva,  #0xa0]	@ PLL1CON <- enable PLL1
	set	sv4,  #0xaa
	set	sv5,  #0x55
	str	sv4,  [rva,  #0xac]	@ PLL1FEED <- feed PLL1
	str	sv5,  [rva,  #0xac]	@ PLL1FEED <- feed PLL1
usbwt0:	ldr	rvb,  [rva,  #0xa8]	@ rvb <- PLL status
	tst	rvb,  #0x0400		@ is PLL locked?
	beq	usbwt0			@	if not, jump to keep waiting
	str	sv3,  [rva,  #0xa0]	@ PLL1CON <- connect PLL1
	str	sv4,  [rva,  #0xac]	@ PLL1FEED <- feed PLL1
	str	sv5,  [rva,  #0xac]	@ PLL1FEED <- feed PLL1
.else
	@  3. Turn on USB device clock (see 9-2-1)  (4. we're using port1 for device = default)
	ldr	rva, =0xFFE0CFF4	@ rva <- USBClkCtrl
	set	rvb, #0x12		@ rvb <- DEV_CLK_EN, AHB_CLK_EN
	str	rvb, [rva]		@ enable USB clock and AHB clock
usbwt0:	ldr	rvb, [rva]
	and	rvb, rvb, #0x12
	eq	rvb, #0x12
	bne	usbwt0
.endif
	@  4. Disable all USB interrupts.
	ldr	rva,  =USBIntSt
	str	fre,  [rva]
	ldr	rva,  =usb_base
	str	fre,  [rva,  #0x04]	@ USBDevIntEn
	str	fre,  [rva,  #0x34]	@ USBEpIntEn
	@  5. Configure pins
.ifndef LPC2478_STK
	@ Set PINSEL1 to enable USB VBUS and the soft connect/good link LED function.
	@  VBUS = 15:14 (P0.23) -> 01, UP_LED = 31:30 (P0.31) -> 01, CONNECT = 31:30 -> 10
	ldr	rva, =PINSEL1
	ldr	rvb, [rva]
	bic	rvb, rvb,  #0xC0000000
	bic	rvb, rvb,  #0x0000C000
	orr	rvb, rvb,  #0x00004000
	str	rvb, [rva]		@ VBUS: unplug => CON_CH DEV_STAT intrpt
	ldr	rva, =io0_base
	ldr	rvb, [rva,  #io_dir]
	orr	rvb, rvb, #0xE0000000
	str	rvb, [rva,  #io_dir]	@ config P0.29-31 as outpt gpio (for USB pseud-connct fnctin on P0.31)
.else
	@ enable USB D-, D+, USB_UP_LED1, USB-Connect (GPIO)
	ldr	rva, =PINSEL1
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x3C000000
	orr	rvb, rvb, #0x14000000
	str	rvb, [rva]		@ set P0.29, P0.30 to USB1(device) D-, D+
	ldr	rva, =PINSEL3
	ldr	rvb, [rva]
	bic	rvb, rvb, #0xF0
	orr	rvb, rvb, #0x10
	str	rvb, [rva]		@ set P1.18 to USB_UP_LED, P1.19 GPIO (USB_CONNECT)
	ldr	rvb,  [rva, #0x40]
	bic	rvb,  rvb, #0xF0
	orr	rvb,  rvb, #0xA0
	str	rvb,  [rva, #0x40]	@ PINMODE0     <- disable pull-up/down resistors on pins
	ldr	rva, =io1_base
	ldr	rvb, [rva,  #io_dir]
	orr	rvb, rvb, #0x00080000
	str	rvb, [rva,  #io_dir]	@ config P1.19 as output gpio (for USB pseudo-connect function)
.endif
	@  6. Set Endpoint index and MaxPacketSize registers for EP0 and EP1, and wait until the
	@  EP_RLZED bit in the Device interrupt status register is set so that EP0/1 are realized.
	ldr	rva,  =usb_base
	str	fre,  [rva,  #0x48]	@ USBEpInd     -- USBEpIndEP_INDEX <- 0
	set	sv4,  #0x08
	str	sv4,  [rva,  #0x4c]	@ USBMaxPSize  -- MAXPACKET_SIZE <- 8
	set	sv5, #0x0100
usbwt1:	ldr	rvb,  [rva]		@ USBDevIntSt  -- wait for dev_int_stat to have EP_RLZED_INT (= 0x100)
	tst	rvb,  sv5
	beq	usbwt1
	str	sv5, [rva, #0x08]	@ USBDevIntClr -- clear EP_RLZD_INT
	str	sv1, [rva, #0x48]	@ USBEpInd     -- EP_INDEX <- 1
	str	sv4, [rva, #0x4c]	@ USBMaxPSize  -- MAXPACKET_SIZE <-8
usbwt2:	ldr	rvb, [rva]		@ USBDevIntSt  -- wait for dev_int_stat to have EP_RLZED_INT (= 0x100)
	tst	rvb, sv5
	beq	usbwt2
	str	sv5, [rva, #0x08]	@ USBDevIntClr -- clear EP_RLZD_INT
	@  7. Clear, then Enable, all Endpoint interrupts
	ldr	sv4, =0xFFFFFFFF
	str	sv4, [rva,  #0x38]	@ USBEpIntClr  -- EP_INT_CLR = 0xFFFFFFFF;
	str	sv4, [rva,  #0x34]	@ USBEpIntEn   -- EP_INT_EN  = 0xFFFFFFFF;
	@  8. Clear Device Interrupts, then Enable DEV_STAT, EP_SLOW, EP_FAST, FRAME
	str	sv4, [rva,  #0x08]	@ USBDevIntClr -- DEV_INT_CLR = 0xFFFFFFFF;
	set	rvb,  #0x0c
	str	rvb,  [rva,  #0x04]	@ USBDevIntEn  -- rvb  <- 0x08 (DEV_STAT_INT) + 0x04 (EP_SLOW_INT)
	@  9. Install USB interrupt handler in the VIC table and enable USB interrut in VIC.
  .ifdef LPC2478_STK
	ldr	rva, =int_base		@ rva <- Vectored Interrupt Controller (VIC) base address
	ldr	rvb,  =genisr
	str	rvb, [rva, #0x0158]	@ VICVectAddr22 <- USB   IRQ handler = usbisr
  .endif
	@ 10. Set default USB address to 0x0 and send Set Address cmd to the protoc engin (twice, see manual).
	set	rvc, lnk		@ r12 <- lnk, saved against wrtcmd
	ldr	rvb,  =0xD00500
	bl	wrtcmd			@ execute set-address command (0x0500 = write command)
	ldr	rvb,  =0x800100
	bl	wrtcmd			@ execute device enable on address zero (0x80) (0x0100 = write data)
	ldr	rvb,  =0xD00500
	bl	wrtcmd			@ execute set-address command (0x0500 = write command)
	ldr	rvb,  =0x800100
	bl	wrtcmd			@ execute device enable on address zero (0x80) (0x0100 = write data)
	@ 11. Set CON bit to 1 to make SoftConnect_N active (send Set Device Status cmd to protocol engine)
	ldr	rvb,  =0xFE0500
	bl	wrtcmd			@ execute get/set device status command
	ldr	rvb,  =0x010100
	bl	wrtcmd			@ execute set device status to connected (0x01)
	@ 12. Set AP_Clk high so that USB clock does not disconnect on suspend
	ldr	rvb,  =0xF30500	
	bl	wrtcmd			@ execute get/set mode command
	ldr	rvb,  =0x010100
	bl	wrtcmd			@ execute set mode to "no suspend" (0x01) (around p. 197, 225)
	@ exit once connected
	ldr	rva,  =USBIntSt
	set	rvb,  #0x80000000
	str	rvb,  [rva]		@ activate USB interupts (connect to VIC)
	set	lnk, rvc		@ lnk <- restored
.endif	@ native_usb
	@ end of the hardware initialization
	set	pc,  lnk

@------------------------------------------------------------------------------------------------
@
@	 1- Initialization from FLASH, writing to and erasing FLASH
@	 2- I2C Interrupt routine
@
@------------------------------------------------------------------------------------------------
	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@

  .ifndef LCDDemo_2158
    .ifndef LPC2478_STK
FlashInitCheck: @ return status of flash init enable/override gpio pin (P0.3) in rva
	ldr	rvb, =PINSEL0		@ set P0.3 to gpio
	ldr	sv1, [rvb]
	bic	rva, sv1, #0x00C0
	str	rva, [rvb]
	ldr	rvb, =io0_base		@ set P0.3 as input
	ldr	sv2, [rvb, #io_dir]
	bic	rva, sv2, #0x08
	str	rva, [rvb, #io_dir]	
	ldr	rva, [rvb]		@ rva <- values of all P0.X
	and	rva, rva, #8		@ rva <- status of P0.3 only (return value)
	str	sv2, [rvb, #io_dir]
	ldr	rvb, =PINSEL0		@ reset P0.3 to its initialized setting
	str	sv1, [rvb]
	set	sv1, #null		@ sv1 <- '() (cleared for exit)
	set	sv2, sv1		@ sv2 <- '() (cleared for exit)
	set	pc,  lnk
    .endif
  .endif
  .ifdef LPC2478_STK
FlashInitCheck: @ return status of flash init enable/override gpio pin (P2.19 - button 1) in rva
	ldr	rvb, =0x3fffc054	@ rvb <- address of fio2pin
	ldr	rva, [rvb]		@ rva <- values of all P2.X
	and	rva, rva, #0x080000	@ rva <- status of P2.19 only (return value)
	set	pc,  lnk
  .endif
  .ifdef LCDDemo_2158
FlashInitCheck: @ return status of flash init enable/override gpio pin (P0.16 - Mode switch) in rva
	ldr	rvb, =io0_base		@ rvb <- address of gpio 0 base register
	ldr	rva, [rvb]		@ rva <- values of all P0.X
	and	rva, rva, #0x010000	@ rva <- status of P0.16 only (Mode switch) (return value)
	set	pc,  lnk
  .endif

	
@---------------------------------------------------------------------------------------
@
@    FLASH I/O:	Internal Flash
@
@---------------------------------------------------------------------------------------

.ifndef LPC_H2214	@ if not a LPC-H2214 which has external FLASH
  .ifndef LPC_H2294	@ if not a LPC-H2294 which has external FLASH

wrtfla:	@ write to file flash
libwrt:	@ write to on-chip lib flash (lib shares on-chip file flash)
	@ on entry:	sv2 <- target flash page address
	@ on entry:	sv4 <- file descriptor with data to write
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	set	rvb, #20		@ rvb <- 20 = space for 5 IAP arguments (words)
	bl	zmaloc			@ rva <- address of free memory
	bic	fre, fre, #0x03		@ fre <- address of free cell for IAP arguments
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
    .ifdef LPC2478_STK
	ldr	fre, =0x4000F000	@ fre <- address for IAP arguments (60KB into on-chip RAM)
    .endif
	@ prepare flash sector for write
	bl	pgsctr			@ r2  <- sector number (raw int), from page address in r5 {sv2}
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	r0,  {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ copy RAM flash to FLASH
	ldmfd	sp,  {r0, r1, r4-r7}	@ restore r5 {sv2} = page address and r7 {sv4} = fil dscrptr frm stack
    .ifdef LPC2478_STK
	ldr	r0,  =0x4000F000	@ r0  <- address for IAP arguments (60KB into on-chip RAM)
    .endif
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)	
	set	r2,  #51		@ r2  <- IAP command 51 -- copy RAM to FLASH
	set	r3,  r5			@ r3  <- page address
	vcrfi	r4,  r7,  3		@ r4  <- address of buffer
    .ifdef LPC2478_STK
	add	r5,  r0, #24
	set	r6,  #F_PAGE_SIZE
wrtflp:	subs	r6,  r6, #4
	ldr	r7,  [r4, r6]
	str	r7,  [r5, r6]
	bne	wrtflp
	set	r4,  r5
    .endif
	set	r5,  #F_PAGE_SIZE	@ r5  <- number of bytes to write
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	r0,  {r2-r6}		@ store IAP arguments (command, page, source, numbytes, freq)
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	orr	fre, fre, #0x02		@ fre <- fre-ptr de-reserved
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

ersfla:	@ erase flash sector that contains page address in sv2
libers:	@ erase on-chip lib flash sector (lib shares on-chip file flash)
	@ on entry:	sv2 <- target flash page address (whole sector erased)
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	set	rvb, #16		@ rvb <- 16 = space for 4 IAP arguments (words)
	bl	zmaloc			@ rva <- address of free memory
	bic	fre, fre, #0x03		@ fre <- address of free cell for IAP arguments
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
    .ifdef LPC2478_STK
	ldr	fre, =0x4000F000	@ fre <- address for IAP arguments (63KB into on-chip RAM)
    .endif
	@ prepare flash sector for write
	bl	pgsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	fre, {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ erase flash sector
	ldmfd	sp,  {fre, cnt, sv1-sv2}	@ restore page address in sv2 {r5} from stack
    .ifdef LPC2478_STK
	ldr	r0,  =0x4000F000	@ r0  <- address for IAP arguments (63KB into on-chip RAM)
    .endif
	bl	pgsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #52		@ r3  <- IAP command 52 -- erase FLASH sector(s)
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	fre, {r3-r6}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	orr	fre, fre, #0x02		@ fre <- fre-ptr de-reserved
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

go_iap:	ldr	r12, =IAP_ENTRY		@ r12 <- address of IAP routine
	bx	r12			@ jump to perform IAP

  .endif @ ifndef LPC-H2294
.endif @ ifndef LPC-H2214


@---------------------------------------------------------------------------------------
@
@    FLASH I/O:	Internal AND External Flash
@
@---------------------------------------------------------------------------------------

.ifdef LPC_H2214	@ code to use external FLASH on LPC-H2214
			@ Micron MX26LV800BTC

wrtfla:	@ write to flash, sv2 = target page address, sv4 = file descriptor
	@ uses 56 bytes of user-stack space
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}		@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	@ copy buffer data from file descriptor {sv4=r7} (RAM) to FLASH {sv2=r5}
	vcrfi	sv3, sv4, 3		@ sv3 <- buffer address	(source start, minus one word)
	add	rva, sv2, #F_PAGE_SIZE	@ rva <- end target address
	@ perform write, 2 half-words at a time
	ldr	sv1, =0x80000aaa	@ sv1 <- flash command address 1
	ldr	sv5, =0x80000554	@ sv5 <- flash command address 2
wrtfl0:	ldrh	rvb, [sv2]		@ rvb <- prior contents of FLASH cell, half-word 1
	set	rvc, #0xaa		@ rvc <- flash command 1
	strh	rvc, [sv1]		@ write command to flash
	set	rvc, #0x55		@ rvc <- flash command 2
	strh	rvc, [sv5]		@ write command to flash
	set	rvc, #0xa0		@ rvc <- flash command 3
	strh	rvc, [sv1]		@ write command to flash
	ldrh	rvc, [sv3]		@ rvc <- first half-word from buffer
	and	rvc, rvc, rvb		@ rvc <- new data ANDed with original FLASH contents
	strh	rvc, [sv2]		@ write ANDed data to FLASH cell
wrtfw0:	ldrh	rvb, [sv2]		@ rvb <- contents of FLASH cell, half-word 1
	eq	rvc, rvb		@ has flash content been updated?
	bne	wrtfw0			@	if not, jump to keep waiting
	ldrh	rvb, [sv2, #2]		@ rvb <- prior contents of FLASH cell, half-word 2
	set	rvc, #0xaa		@ rvc <- flash command 1
	strh	rvc, [sv1]		@ write command to flash
	set	rvc, #0x55		@ rvc <- flash command 2
	strh	rvc, [sv5]		@ write command to flash
	set	rvc, #0xa0		@ rvc <- flash command 3
	strh	rvc, [sv1]		@ write command to flash
	ldrh	rvc, [sv3, #2]		@ rvc <- second half-word from buffer
	and	rvc, rvc, rvb		@ rvc <- new data ANDed with original FLASH contents
	strh	rvc, [sv2, #2]		@ write ANDed data to FLASH cell
wrtfw1:	ldrh	rvb, [sv2, #2]		@ rvb <- contents of FLASH cell, half-word 2
	eq	rvc, rvb		@ has flash content been updated?
	bne	wrtfw1			@	if not, jump to keep waiting
	add	sv3, sv3, #4		@ sv3 <- next source word address
	add	sv2, sv2, #4		@ sv2 <- next destination address
	cmp	sv2, rva		@ done writing?
	bmi	wrtfl0			@	if not, jump to keep writing to flash
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

ersfla:	@ erase flash sector that contains page address in sv2
	@ uses 56 bytes of user-stack space
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}		@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	@ prepare flash sector for write
	bl	pgsctr			@ rva <- sector number (raw int), from page address in sv2
	ldr	rvb, =flashsectors	@ rvb <- address of flash sector table
	ldr	rvb, [rvb, rva, LSL #2]	@ rvb <- start address of flash block to be erased
	ldr	sv1, =0x80000aaa	@ sv1 <- flash command address 1
	ldr	sv5, =0x80000554	@ sv5 <- flash command address 2
	set	rvc, #0xaa		@ rvc <- flash command 1
	strh	rvc, [sv1]		@ write command to flash
	set	rvc, #0x55		@ rvc <- flash command 2
	strh	rvc, [sv5]		@ write command to flash
	set	rvc, #0x80		@ rvc <- flash command 3
	strh	rvc, [sv1]		@ write command to flash
	set	rvc, #0xaa		@ rvc <- flash command 1
	strh	rvc, [sv1]		@ write command to flash
	set	rvc, #0x55		@ rvc <- flash command 2
	strh	rvc, [sv5]		@ write command to flash
	set	rvc, #0x30		@ rvc <- flash command 4 -- erase block
	strh	rvc, [rvb]		@ write command to flash -- erase block rvb
	ldr	rvc, =0xffff		@ rvc <- #xffff = erased half-word mask
erswt0:	ldrh	rva, [rvb]		@ rva <- 1st half-wrod of erased flash block
	eq	rva, rvc		@ is it erased?
	bne	erswt0			@	if not, jump to keep waiting
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return



libwrt:	@ write to on-chip lib flash,
	@ on entry:	sv2 <- target flash page address
	@ on entry:	sv4 <- file descriptor with data to write
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	@ prepare flash sector for write
	bl	lbsctr			@ r2  <- sector number (raw int), from page address in r5 {sv2}
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	r0,  {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ copy RAM flash to FLASH
	ldmfd	sp,  {r0, r1, r4-r7}	@ restore r5 {sv2} = page address and r7 {sv4} = fil dscrptr frm stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)	
	set	r2,  #51		@ r2  <- IAP command 51 -- copy RAM to FLASH
	set	r3,  r5			@ r3  <- page address
	vcrfi	r4,  r7,  3		@ r4  <- address of buffer
	add	r5,  r0, #24
	set	r6,  #F_PAGE_SIZE
libwlp:	subs	r6,  r6, #4
	ldr	r7,  [r4, r6]
	str	r7,  [r5, r6]
	bne	libwlp
	set	r4,  r5
	set	r5,  #F_PAGE_SIZE	@ r5  <- number of bytes to write
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	r0,  {r2-r6}		@ store IAP arguments (command, page, source, numbytes, freq)
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

libers:	@ erase on-chip lib flash sector that contains page address in sv2
	@ on entry:	sv2 <- target flash page address (whole sector erased)
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	@ prepare flash sector for write
	bl	lbsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	fre, {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ erase flash sector
	ldmfd	sp,  {fre, cnt, sv1-sv2}	@ restore page address in sv2 {r5} from stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	bl	lbsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #52		@ r3  <- IAP command 52 -- erase FLASH sector(s)
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	fre, {r3-r6}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

go_iap:	ldr	r12, =IAP_ENTRY		@ r12 <- address of IAP routine
	bx	r12			@ jump to perform IAP


.endif	@ ifdef LPC_H2214

.ifdef LPC_H2294	@ code to use external FLASH on LPC-H2294
			@ INTEL JS28F320C3-BD70
			@ similar to LPC-H2888

wrtfla:	@ write to flash, sv2 = page address, sv4 = file descriptor
	swi	run_no_irq			@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	@ copy buffer data from file descriptor{sv4} (RAM) to FLASH buffer {sv2}
	vcrfi	sv3, sv4, 3			@ sv3 <- buffer address	
	add	sv5, sv2, #F_PAGE_SIZE		@ sv5 <- end target address
wrtfl0:	bl	pgsctr				@ rva <- sector number (raw int), from page address in sv2
	ldr	rvb, =flashsectors		@ rvb <- address of flash address table
	ldr	rvb, [rvb, rva,LSL #2]		@ rvb <- start address of target flash block
	@ write lower 2 bytes of word
	ldrh	rvc, [sv3]			@ rvc <- lower half of word to write
	set	rva, #0x40			@ rva <- CFI word program command code
	strh	rva, [sv2]			@ start half word write
	strh	rvc, [sv2]			@ confirm half word write
flwrw1:	@ wait for FLASH device to be ready
	ldrh	rva, [rvb]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	beq	flwrw1				@	if not, jump to keep waiting
	@ write upper two bytes of word
	ldrh	rvc, [sv3, #2]			@ rvc <- upper half word to write
	set	rva, #0x40			@ rva <- CFI word program command code
	strh	rva, [sv2, #2]			@ start half word write
	strh	rvc, [sv2, #2]			@ confirm half word write
flwrw2:	@ wait for FLASH device to be ready
	ldrh	rva, [rvb]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	beq	flwrw2				@	if not, jump to keep waiting
	@ jump to keep writing or finish up
	add	sv3, sv3, #4			@ sv3 <- address of next source word
	add	sv2, sv2, #4			@ sv2 <- target address of next word
	cmp	sv2, sv5			@ done writing page?
	bmi	wrtfl0				@	if not, jump to keep writing
	@ Return to FLASH Read Array mode
	set	rva, #0x00ff			@ rva <- CFI Read Array command code
	strh	rva, [rvb]			@ set FLASH to read array mode
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}	@ restore scheme registers from stack
	swi	run_normal				@ enable interrupts (user mode)
	set	pc,  lnk			@ return

ersfla:	@ erase flash sector that contains page address in sv2
	swi	run_no_irq				@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk}	@ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	@ prepare flash sector for write
	bl	pgsctr				@ rva <- sector number (raw int), from page address in sv2
	ldr	rvb, =flashsectors		@ rvb <- address of flash sector table
	ldr	rvb, [rvb, rva, LSL #2]		@ rvb <- address of flash block start
	@ erase block whose address starts at sv2
	set	rva, #0x0020			@ rva <- CFI erase block command code
	strh	rva, [rvb]			@ initiate erase block
	set	rva, #0x00d0			@ rva <- CFI confirm erase command code
	strh	rva, [rvb]			@ confirm erase block
	@ wait for FLASH device to be ready
	ldr	rvb, =flashsectors		@ rvb <- address of flash sector table
	ldr	rvb, [rvb]			@ rvb <- FLASH start address
flrdwt:	ldrh	rva, [rvb]			@ rva <- FLASH device status
	tst	rva, #0x80			@ is FLASH ready?
	beq	flrdwt				@	if not, jump to keep waiting
	@ Return to FLASH Read Array mode
	set	rva, #0x00ff			@ rva <- CFI Read Array command code
	strh	rva, [rvb]			@ set FLASH to read array mode
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}	@ restore scheme registers from stack
	swi	run_normal				@ enable interrupts (user mode)
	set	pc,  lnk			@ return

unlok:	@ unlock all file flash -- called by hwinit
	set	sv3, lnk			@ sv3 <- lnk, saved
	ldr	sv2, =F_START_PAGE		@ sv2 <- start address of file flash
	bl	pgsctr				@ rva <- sector number (raw int), from page address in r5
	ldr	rvb, =F_END_PAGE		@ rvb <- end address of file flash
	ldr	env, =flashsectors		@ env <- address of flash sector table
unlok0:	@ loop over flash blocks to be unlocked
	ldr	sv2, [env, rva, LSL #2]		@ sv2 <- start address of flash sector
	@ unlock block that starts at sv2
	ldr	fre, [env]			@ fre <- FLASH start address
	set	sv1, #0x0060			@ sv1 <- CFI unlock block command code
	strh	sv1, [sv2]			@ initiate block unlock
	set	sv1, #0x00d0			@ sv1 <- CFI confirm unlock command code
	strh	sv1, [sv2]			@ confirm block unlock
	@ wait for FLASH device to be ready
	set	sv1, #0x0090			@ sv1 <- CFI read device ID command code
	strh	sv1, [fre]			@ initiate ID and status read
unlok1:	ldrh	sv1, [sv2, #4]			@ sv1 <- block status
	tst	sv1, #0x03			@ is block unlocked?
	bne	unlok1				@	if not, jump to keep waiting
	cmp	sv2, rvb			@ done unlocking?
	addmi	rva, rva, #1			@	if not, rva <- next sector number
	bmi	unlok0				@	if not, jump to unlock next sector
	@ Return to FLASH Read Array mode and exit
	set	sv1, #0x00ff			@ sv1 <- CFI Read Array command code
	strh	sv1, [fre]			@ set FLASH to read array mode
	set	pc,  sv3			@ return



libwrt:	@ write to on-chip lib flash,
	@ on entry:	sv2 <- target flash page address
	@ on entry:	sv4 <- file descriptor with data to write
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	@ prepare flash sector for write
	bl	lbsctr			@ r2  <- sector number (raw int), from page address in r5 {sv2}
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	r0,  {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ copy RAM flash to FLASH
	ldmfd	sp,  {r0, r1, r4-r7}	@ restore r5 {sv2} = page address and r7 {sv4} = fil dscrptr frm stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	set	r1,  r0			@ r1  <- IAP results table (same as arguments)	
	set	r2,  #51		@ r2  <- IAP command 51 -- copy RAM to FLASH
	set	r3,  r5			@ r3  <- page address
	vcrfi	r4,  r7,  3		@ r4  <- address of buffer
	add	r5,  r0, #24
	set	r6,  #F_PAGE_SIZE
libwlp:	subs	r6,  r6, #4
	ldr	r7,  [r4, r6]
	str	r7,  [r5, r6]
	bne	libwlp
	set	r4,  r5
	set	r5,  #F_PAGE_SIZE	@ r5  <- number of bytes to write
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	r0,  {r2-r6}		@ store IAP arguments (command, page, source, numbytes, freq)
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

libers:	@ erase on-chip lib flash sector that contains page address in sv2
	@ on entry:	sv2 <- target flash page address (whole sector erased)
	@ preserves:	all
	swi	run_no_irq		@ disable interrupts (user mode)
	stmfd	sp!, {rva, rvb, rvc, lnk} @ store scheme registers onto stack
	stmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ store scheme registers onto stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	@ prepare flash sector for write
	bl	lbsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #50		@ r3  <- IAP command 50 -- prepare sector for write
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	stmia	fre, {r3-r5}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ erase flash sector
	ldmfd	sp,  {fre, cnt, sv1-sv2}	@ restore page address in sv2 {r5} from stack
	ldr	r0,  =0x40003C00	@ fre <- address for IAP arguments (15KB into on-chip RAM)
	bl	lbsctr			@ r2  <- sector number (raw int), from page address in sv2
	set	r1,  fre		@ r1  <- IAP results table (same as arguments)
	set	r3,  #52		@ r3  <- IAP command 52 -- erase FLASH sector(s)
	set	r4,  r2			@ r4  <- start sector
	set	r5,  r2			@ r5  <- end sector
	ldr	r6,  =CLOCK_FREQ	@ r6  <- clock frequency
	stmia	fre, {r3-r6}		@ write IAP arguments
	bl	go_iap			@ run IAP
	@ finish up
	ldmfd	sp!, {fre, cnt, sv1-sv5, env, dts, glv}	@ restore scheme registers from stack
	ldmfd	sp!, {rva, rvb, rvc, lnk}		@ restore scheme registers from stack
	swi	run_normal		@ enable interrupts (user mode)
	set	pc,  lnk		@ return

go_iap:	ldr	r12, =IAP_ENTRY		@ r12 <- address of IAP routine
	bx	r12			@ jump to perform IAP


.endif	@ ifdef LPC_H2294


.ltorg	@ dump literal constants here => up to 4K of code before and after this point


@------------------------------------------------------------------------------------------------
@
@ 2- SD card low-level interface
@
@------------------------------------------------------------------------------------------------

.ifdef	onboard_SDFT
	
  .ifdef sd_is_on_spi

_func_	
sd_cfg:	@ configure spi speed (high), phase, polarity
	ldr	rva, =sd_spi
	set	rvb, #8
	str	rvb, [rva, #0x0c]	@ s0spccr clk <- 60MHz/8 = 7.5 MHz
	set	rvb, #0x20
	str	rvb, [rva, #0x00]	@ s0spcr (control) #x00 master, 8-bit, POL=PHA=0
	set	pc,  lnk

_func_	
sd_slo:	@ configure spi speed (low), phase, polarity
	ldr	rva, =sd_spi
	set	rvb, #150
	str	rvb, [rva, #0x0c]	@ s0spccr clk <- 60MHz/150 = 400 KHz
	set	rvb, #0x20
	str	rvb, [rva, #0x00]	@ s0spcr (control) #x00 master, 8-bit, POL=PHA=0
	set	pc,  lnk

_func_	
sd_sel:	@ select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_clear]	@ clear-pin
	set	pc,  lnk
	
_func_	
sd_dsl:	@ de-select SD-card subroutine
	ldr	rva, =sd_cs_gpio
	set	rvb, #sd_cs
	str	rvb, [rva, #io_set]	@ set-pin
	set	pc,  lnk
	
_func_	
sd_get:	@ _sgb get sub-routine
	set	rvb, #0xff
_func_	
sd_put:	@ _sgb put sub-routine
	ldr	rva, =sd_spi
	and	rvb, rvb, #0xff
	str	rvb, [rva, #spi_thr]	@ sdtx (sdat)
sd_gpw:	@ wait
	ldr	rvb, [rva, #spi_status]	@ ssta
	tst	rvb, #spi_rxrdy		@ sdrr
	beq	sd_gpw
	ldr	rvb, [rva, #spi_rhr]	@ sdrx (sdat)
	set	pc, lnk

  .endif @ sd_is_on_spi


  .ifdef sd_is_on_mci

	@ 4-bit bus interface
	@
_sgb:	@ [internal only]
	@ sd-get-block internal func
	@ on entry:  rvc <- block number to be read (scheme int)
	@ on entry:  sv3 <- buffer in which to store block data (scheme bytevector)
	@ on exit:   sv3 <- updated buffer
	@ modifies:  sv3, sv5, rva, rvb, rvc
	@	dmactl  (#x0849 . #x2200) ; #x08492200
	@	dmacfg  (#x0001 . #x3009) ; #x013009 (dma channel locked) (#x003009 for unlocked)
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
sgb_sr:	@ start/restart transfer
	@ clear dma channel  0 via DMACC0Config
	ldr	rva, =gdma_base
	set	rvb, #0
	str	rvb, [rva, #0x110]
	@ prepare for read-block
	bl	sd_pre		@ prepare mci
	set	rvb, rvc
	bl	sd_arg		@ set arg (block number) in MCIargument
	set	rvb, #17
	bl	sd_cmd
	eq	rva, #0
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	sgb_sr
	@ configure gpdma
	ldr	rva, =sd_mci
	add	rvb, rva, #0x80		@ rvb <- MCIFIFO address
	ldr	rva, =gdma_base
	str	rvb, [rva, #0x100]	@ set MCIFIFO as DMACC0SrcAddr
	ldr	rvb, =bdma_base
	add	rvb, rvb, #4
	str	rvb, [rva, #0x104]	@ set dma buffer + 4 as DMACC0DestAddr
	ldr	rvb, =0x08492200
	str	rvb, [rva, #0x10c]	@ DMACC0Control <- 512B, 8x32, incr. dest
	@ enable dma transfer
	ldr	rvb, =0x013009
	str	rvb, [rva, #0x110]	@ DMACC0Config <- lock, MCI->mem, MCIctl, enab
	@ MCIDataCtl <- 512B, block, dma ,from card
	ldr	rva, =sd_mci		@ rva <- mci address
	set	rvb, #0x9b
	str	rvb, [rva, #0x2c]
	@ wait for DataBlockEnd
	set	rvc, #0x400
	adr	lnk, sgb_sr
sgb_wt:	@ wait loop
	ldr	rvb, [rva, #0x34]	@ stat
	tst	rvb, #0x3f		@ error?
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	sd_cm1			@ jump to restart
	tst	rvb, rvc
	beq	sgb_wt
	@ copy data into sv3
	ldr	rva, =bdma_base
	set	rvc, #512
sgb_cp:	@ copy loop
	ldr	rvb, [rva, rvc]
	subs	rvc, rvc, #4
	str	rvb, [sv3, rvc]
	bne	sgb_cp
	@ return
	orr	lnk, sv5, #lnkbit0
	set	pc,  lnk
	
	@ 4-bit bus interface
	@
_spb:	@ [internal only]
	@ sd-put-block internal func
	@ on entry:  rvc <- block number to be written (scheme int)
	@ on entry:  sv3 <- buffer with block data to write to sd (scheme bytevector)
	@ modifies:  sv5, rva, rvb, rvc
	@     dmactl  (#x0449 . #x2200) ; #x04492200
	@     dmacfg  (#x0001 . #x2901) ; #x012901 (dma channel locked) (#x002901 for unlocked)
	bic	sv5, lnk, #lnkbit0	@ sv5 <- lnk, saved
spb_sr:	@ start/restart transfer
	@ clear dma channel  0 via DMACC0Config
	ldr	rva, =gdma_base
	set	rvb, #0
	str	rvb, [rva, #0x110]
	@ prepare for write-block
	bl	sd_pre		@ prepare mci
	set	rvb, rvc
	bl	sd_arg		@ set arg (block number) in MCIargument
	@ copy data from sv3 to dma buffer
	ldr	rva, =bdma_base
	set	rvc, #0
spb_cp:	@ copy loop
	ldr	rvb, [sv3, rvc]
	add	rvc, rvc, #4
	str	rvb, [rva, rvc]
	eq	rvc, #512
	bne	spb_cp
	@ send cmd 24 (write single block)
	set	rvb, #24
	bl	sd_cmd
	eq	rva, #0
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	spb_sr
	@ configure gpdma and enable transfer
	ldr	rva, =sd_mci
	add	rvb, rva, #0x80		@ rvb <- MCIFIFO address
	ldr	rva, =gdma_base
	str	rvb, [rva, #0x104]	@ set MCIFIFO as DMACC0DestAddr
	ldr	rvb, =bdma_base
	add	rvb, rvb, #4
	str	rvb, [rva, #0x100]	@ set dma buffer + 4 as DMACC0SrcAddr
	ldr	rvb, =0x04492200
	str	rvb, [rva, #0x10c]	@ DMACC0Control <- 512B, 8x32, incr. src
	ldr	rvb, =0x012901
	str	rvb, [rva, #0x110]	@ DMACC0Config <- lock, mem->MCI, MCIctl, enab
	@ MCIDataCtl <- 512B, block, dma, to card
	ldr	rva, =sd_mci		@ rva <- mci address
	set	rvb, #0x99
	str	rvb, [rva, #0x2c]
	@ wait for DataBlockEnd
	set	rvc, #0x400
	adr	lnk, spb_sr
spb_wt:	@ wait loop
	ldr	rvb, [rva, #0x34]	@ stat
	tst	rvb, #0x3f		@ error?
	ldrne	rvc, [rva, #0x08]
	lsrne	rvc, rvc, #7
	bne	sd_cm1			@ jump to restart
	tst	rvb, rvc
	beq	spb_wt
	ldr	rvc, [rva, #0x14]	@ rvc <- response0 
spb_ts:	@ wait for card in ready-tran state
	bl	sd_pre		@ prepare mci
	set	rvb, #0
	bl	sd_arg		@ set arg (block number) in MCIargument
	set	rvb, #13
	bl	sd_cmd
	eq	rva, #0
	eqne	rvb, #9
	bne	spb_ts
	@ return
	orr	lnk, sv5, #lnkbit0
	set	pc,  lnk
	
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

sd_arg:	@ mci-arg subroutine (set arg)
	@ on entry: rvb <- arg (0 as raw int, or block number as scheme int)
	ldr	rva, =sd_mci
	bic	rvb, rvb, #3
	lsl	rvb, rvb, #7
	str	rvb, [rva, #0x08]	@ set arg in MCIargument
	set	pc,  lnk
	
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
	eq	rvb, #9			@ was cmd received while card ready and in tran state?
	seteq	rva, #0
	seteq	pc,  lnk
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
	set	rvb, #0x0100
	orr	rvb, rvb, #0x16
	str	rvb, [rva, #0x04]	@ set MCI to 400KHz (200KHz?), 1-bit bus, CLK enabled
	set	pc,  lnk

_func_	
sd_fst:	@ configure mci speed (high = 9 MHz), wide bus, clock enabled
	ldr	rva, =sd_mci
	set	rvb, #0x0d00
	orr	rvb, rvb, #0x16
	str	rvb, [rva, #0x04]        @ set MCI to 9 MHz (i.e. bypass), wide bus, CLK enabled
	set	pc,  lnk

sdpcmd:	@ function to write a command to SD/MMC card
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
	orr	rvb, rvb, #0x0400	@ bit to enable CPSM
	eq	sv4, #i0
	orrne	rvb, rvb, #0x40		@ bit to wait for response
	tst	sv4, #0x10000000
	orrne	rvb, rvb, #0x80		@ bit for long (vs short) response
	str	rvb, [rva, #0x0c]	@ send cmd
sdpcmb:	@ wait for mci not busy
	ldr	rvb, [rva, #0x34]
	tst	rvb, #0x3800
	bne	sdpcmb
	set	rvb, #0x100000
sdpcmw:	@ wait a bit more (some cards seem to need this)
	subs	rvb, rvb, #1
	bne	sdpcmw
	@ if CMD3 (get address), check status and exit with indicator if bad
	eq	sv4, #0x0d		@ CMD3?
	bne	sdpcmc
	ldr	rvb, [rva, #0x34]
	eq	rvb, #0x40
	setne	rvb, #0
	setne	pc,  lnk
sdpcmc:	@ continue
	ldr	rvb, [rva, #0x34]
	lsl	rvb, rvb, #21
	lsr	rvb, rvb, #21
	str	rvb, [rva, #0x38]	@ clear status register
	ldr	rvb, [rva, #0x14]	@ rvb <- response0
	set	pc,  lnk
		
  .endif @ sd_is_on_mci

.endif	@ onboard_SDFT

	
@---------------------------------------------------------------------------------------
@
@ 2- I2C Interrupt routine
@
@---------------------------------------------------------------------------------------

.ifdef	include_i2c

hwi2cr:	@ write-out additional address registers, if needed
	@ modify interupts, as needed
	@ on entry:	sv5 <- i2c[0/1]buffer
	@ on entry:	rva <- i2c[0/1] base address (also I2CONSET)
	@ interrupts are disabled throughout
	set	rvb, #0			@ rvb <- 0 bytes to send (scheme int)
	tbsti	rvb, sv5, 3		@ store number of bytes to send in i2c buffer[12]
	@ initiate i2c read/write, as master
	swi	run_normal		@ re-enable interrupts
	set	rvb, #0x20		@ rvb <- i2c START command
	strb	rvb, [rva, #i2c_cset]	@ initiate bus mastering (write start to i2c[0/1]conset)
hwi2r0:	@ wait for mcu address and registers to have been transmitted
	swi	run_no_irq		@ disable interrupts
	tbrfi	rvb, sv5, 1		@ rvb <- data ready status from i2cbuffer[4]
	eq	rvb, #f			@ is i2c data ready = #f (i.e. addresses have been transmitted)
	seteq	pc,  lnk		@	if so, jump to continue
	swi	run_normal		@ re-enable interrupts
	b	hwi2r0			@ jump to keep waiting

hwi2ni:	@ initiate i2c read/write, as master
	@ on entry:	rva <- i2c[0/1] base address (also I2CONSET)
	set	rvb, #0x20		@ rvb <- i2c START command
	strb	rvb, [rva, #i2c_cset]	@ initiate bus mastering (write start to i2c[0/1]conset)
	set	pc,  lnk

hwi2st:	@ get i2c interrupt status and base address
	@ on exit:	rva <- i2c[0/1] base address
	@ on exit:	rvb <- i2c interrupt status
	ldrb	rvb, [rva, #i2c_status]	@ r7  <- I2C Status
	set	pc,  lnk

i2c_hw_branch:	@ process interrupt
	eq	rvb, #0x08		@ Master Read/Write -- bus now mastered		(I2STAT = 0x08)
	beq	i2c_hw_mst_bus
	eq	rvb, #0x18		@ Master Write -- slave has acknowledged adress	(I2STAT = 0x18)
	beq	i2c_wm_ini
	eq	rvb, #0x28		@ Master Write -- slave ok to receive data	(I2STAT = 0x28)
	beq	i2c_wm_put
	eq	rvb, #0x40		@ Master Read  -- slave ackn. adress (set nak?)	(I2STAT = 0x40)
	beq	i2c_rm_ini
	eq	rvb, #i2c_irm_rcv	@ Master Read  -- new byte received (set nak?)	(I2STAT = 0x50)
	beq	i2c_rm_get
	eq	rvb, #0x58		@ Master Read  -- last byte received		(I2STAT = 0x58)
	beq	i2c_rm_end
	eq	rvb, #0x60		@ Slave Read   -- address recognized as mine	(I2STAT = 0x60)
	beq	i2c_rs_ini
	eq	rvb, #i2c_irs_rcv	@ Slave Read   -- new data received		(I2STAT = 0x80)
	beq	i2c_rs_get
	eq	rvb, #0xA0		@ Slave Read   -- STOP or re-START received	(I2STAT = 0xA0)
	beq	i2c_rs_end
	eq	rvb, #0xA8		@ Slave Write  -- address recognized as mine	(I2STAT = 0xA8)
	beq	i2c_ws_ini
	eq	rvb, #0xB8		@ Slave Write  -- master requests byte		(I2STAT = 0xB8)
	beq	i2c_ws_put
	eq	rvb, #0xC0		@ Slave Write  -- NAK received from master/done	(I2STAT = 0xC0)
	beq	i2c_ws_end
	set	pc,  lnk

i2c_hw_mst_bus:	@ Reading or Writing as Master -- bus now mastered (I2STAT = 0x08)
	tbrfi	rva, sv2, 0		@ rva <- address of mcu to send data to (scheme int)
	lsr	rva, rva, #1		@ rva <- mcu-id as int -- note: ends with 0 (i.e. divide by 2)
	strb	rva, [sv3, #i2c_thr]	@ set address of mcu to send data to
	set	rva, #0x20		@ rva <- bit 5
	strb	rva, [sv3, #i2c_cclear]	@ clear START bit to enable Tx of target address
	b	i2cxit

hwi2we:	@ set busy status/stop bit at end of write as master
	@ on entry:	sv2 <- i2c[0/1] buffer address
	@ on entry:	sv3 <- i2c[0/1] base address
	@ on entry:	rvb <- #f
	tbrfi	rva, sv2, 3		@ rva <- number of data bytes to send (raw int)
	eq	rva, #0			@ were we sendng 0 byts (i.e. rdng as mastr, done writng addrss byts)?
	tbstine rvb, sv2, 0		@	if not, set busy status to #f (transfer done)
	setne	rva, #0x10		@	if not, rva <-  STOP bit used to stop i2c transfer
	strbne	rva, [sv3, #i2c_cset]	@	if not, set  STOP bit to stop i2c transfer
	set	pc,  lnk
	
hwi2re:	@ set stop bit if needed at end of read-as-master
	set	rva, #0x014		@ rva <- bit4 | bit 2
	strb	rva, [sv3, #i2c_cset]	@ set STOP bit and reset AA to AK
	set	pc,  lnk
	
hwi2cs:	@ clear SI
	set	rva, #0x08		@ clear SI
	strb	rva, [sv3, #i2c_cclear]
	set	pc,  lnk

i2cstp:	@ prepare to end Read as Master transfer
	set	rva, #0x04		@ rva <- bit 2
	strb	rva, [sv3, #i2c_cclear]	@ set AA to NAK
	set	pc,  lnk

i2putp:	@ Prologue:	write additional address bytes to i2c, from buffer or r12 (prologue)
	tbrfi	rva, sv2, 1		@ rva <- number of additional address bytes to send (scheme int)
	eq	rva, #i0		@ no more address bytes to send?
	tbrfieq rva, sv2, 3		@	if so,  rva <- number of data bytes to send (raw int)
	tbrfieq rvb, sv2, 4		@	if so,  rvb <- number of data bytes sent (raw int)
	eqeq	rva, rvb		@	if so,  are we done sending data?
	beq	i2c_wm_end		@		if so, jump to stop or restart x-fer and exit
	tbrfi	rvb, sv2,  1		@ r7  <- number of address bytes remaining to send (scheme int)
	eq	rvb, #i0		@ done sending address bytes?
	subne	rvb, rvb, #4		@	if not, rvb <- updated num of addrss byts to send (scheme int)
	tbstine rvb, sv2, 1		@	if not, store updatd num of addrss byts to snd in i2cbuffer[4]
	addne	rva, sv2, #8		@	if not, rva <- address of additional address byts in i2cbuffer
	ldrbne	rva, [rva, rvb, LSR #2]	@	if not, rva <- next address byte to send
	strbne	rva, [sv3, #i2c_thr]	@ put next data byte in I2C data register
	bne	i2cxit
	set	pc,  lnk

i2pute:	@ Epilogue:	set completion status if needed (epilogue)
	set	pc,  lnk

.endif

.ltorg	@ dump literal constants here => up to 4K of code before and after this point














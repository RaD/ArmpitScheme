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


.ifdef	live_SD

	@ disable and invalidate L2 cache
	mrc	p15, 0, fre, c1, c0, 1	@ fre <- contents of aux control register (CP15 reg. 1)
	bic	fre, fre, #0x02
	set	r12, #3			@ r12 <- write fre to aux control reg smc call index
	smc	#0			@ secure monitor call to disable L2 cache
	@ (initialization pdf, p. 20)
	set	r12, #1			@ r12 <- clear cache smi call
	smc	#0			@ secure monitor call to invalidate L2 cache
	@ open-up the L3 interconnect firewall (eg. interconnects, p. 74)
	@ SDRAM Memory Scheduler (SMS)
	set	rva, #0x6c000000	@ SMS base address (memory controller)
	ldr	rvb, =0xFFFFFFFF
	str	rvb, [rva, #0x48]	@ SMS_RG_ATT0 <- full access (p. 149)
	@ RT, GPMC, OCM RAM
	ldr	rva, =0x68010000	@ rva <- L3_PM_RT base
	ldr	rvb, =0x563E
	ldr	rvc, =0xFFFF
	set	sv1, #0
	str	rvb, [rva, #0x50]	@ RT L3_PM_READ_PERMISSION,          region 0
	str	rvb, [rva, #0x58]	@ RT L3_PM_WRITE_PERMISSION,         region 0
	str	rvc, [rva, #0x68]	@ RT L3_PM_REQ_INFO_PERMISSION,      region 1
	str	sv1, [rva, #0x80]	@ RT L3_PM_ADDR_MATCH,               region 1
	add	rva, rva, #0x2400	@ rva <- L3_PM_GPMC base
	str	rvc, [rva, #0x48]	@ GPMC L3_PM_REQ_INFO_PERMISSION,    region 0
	str	rvb, [rva, #0x50]	@ GPMC L3_PM_READ_PERMISSION,        region 0
	str	rvb, [rva, #0x58]	@ GPMC L3_PM_WRITE_PERMISSION,	     region 0
	add	rva, rva, #0x0400	@ rva <- L3_PM_OCM_RAM base
	str	rvc, [rva, #0x48]	@ OCM RAM L3_PM_REQ_INFO_PERMISSION, region 0
	str	rvb, [rva, #0x50]	@ OCM RAM L3_PM_READ_PERMISSION,     region 0
	str	rvb, [rva, #0x58]	@ OCM RAM L3_PM_WRITE_PERMISSION,    region 0
	str	sv1, [rva, #0xa0]	@ OCM RAM L3_PM_ADDR_MATCH,          region 2
	@ turn clock functions/interfaces on
	@ 1- CORE domain
	@ McBSP 1,5, GPT 10, 11, uart 1,2, i2c 1-3, spi 1-4, mmc 1-2, sdrc
	ldr	rva, =CORE_CM_base	@ cm_fclken1_core
	ldr	rvb, =0x03fffe00
	str	rvb, [rva, #F_clck]	@ cm_fclken1_core
	ldr	rvb, =0x3ffffed2
	str	rvb, [rva, #I_clck]	@ cm_iclken1_core
	@ 2- WAKE-UP domain
	@ GP timer 1, gpio 1, wdt 2, smart reflex 1,2, 32K sync timer
	ldr	rva, =WKUP_CM_base	@ cm_fclken_wkup
	set	rvb, #0xe9
	str	rvb, [rva, #F_clck]	@ cm_fclken_wkup
	set	rvb, #0x3f
	str	rvb, [rva, #I_clck]	@ cm_iclken_wkup
	@ 3- PERIPHERAL domain
	@ McBSP 2-4, GP Timer 2-9, uart3, wdt3, gpio 2-6
	ldr	rva, =PER_CM_base	@ cm_fclken_per
	ldr	rvb, =0x03ffff
	str	rvb, [rva, #F_clck]	@ cm_fclken_per
	str	rvb, [rva, #I_clck]	@ cm_iclken_per
	set	rvb, #0xff
	str	rvb, [rva, #0x40]	@ cm_clksel_per <- GPT2-9 use sys-clk
	@ initialize clocks in prcm
	ldr	rva, = 0x48306d00
	set	rvb, #0x03		@ 26 MHz
	str	rvb, [rva, #0x40]	@ prm_clksel <- OSC_SYS_CLK = 26 MHz
	ldr	rva, = 0x48307200
	ldr	rvb, [rva, #0x70]	@ rvb <- prm_clksrc_ctrl
	bic	rvb, rvb, #0xc3
	orr	rvb, rvb, #0x80
	str	rvb, [rva, #0x70]	@ prm_clksrc_ctrl <- SYS_CLCK = OSC_SYS_CLK / 2
	@
	@ DPLL4: set-up the peripherals dpll
	@
	ldr	rva, =0x48004d00	@ rva <- cm_clken_pll (core dpll)
	ldr	rvb, [rva]		@ rvb <- cm_clken_pll contents
	bic	rvb, rvb, #0x070000
	orr	rvb, rvb, #0x010000	@ 
	orr	rvb, rvb, #0xf0000000	@ power-down EMU, CAM, DSS, TV
	orr	rvb, rvb, #0x00001000	@ power-down EMU core	
	str	rvb, [rva]		@ cm_clken_pll <- dpll4 stop
plstw4:	@ wait for stop
	ldr	rvb, [rva, #0x20]	@ rvb <- cm_idlest_ckgen
	tst	rvb, #0x02		@ stopped?
	bne	plstw4			@	if not, jump to keep waiting
	ldr	rvb, =PLL4_parms	@ M=0x1b0 or 0x360, N=0x0c, DCO_SEL=NA or 0x02, SD_DIV=NA or 0x04
	str	rvb, [rva, #0x44]	@ cm_clksel2_pll <- X2 = 864 MHz
	set	rvb, #0x09
	str	rvb, [rva, #0x48]	@ cm_clksel3_pll <- M2 = 9 to generate 96 MHz as 864 MHz / 9
	ldr	rvb, [rva]		@ rvb <- cm_clken_pll contents
	orr	rvb, rvb, #0x070000	@ 
	str	rvb, [rva]		@ cm_clken_pll <- dpll4 lock
pllkw4:	@ wait for lock
	ldr	rvb, [rva, #0x20]	@ rvb <- cm_idlest_ckgen
	tst	rvb, #0x02		@ locked?
	beq	pllkw4			@	if not, jump to keep waiting
	@
	@ DPLL3: setup the core dpll
	@
	ldr	rva, =0x48004d00	@ rva <- cm_clken_pll (dpll3 = core dpll)
	ldr	rvb, [rva]
	bic	rvb, rvb, #0x07
	orr	rvb, rvb, #0x06
	str	rvb, [rva]		@ cm_clken_pll <- dpll3 in fast relock bypass
plstw3:	@ wait for bypass
	ldr	rvb, [rva, #0x20]	@ rvb <- cm_idlest_ckgen
	tst	rvb, #1			@ bypassed?
	bne	plstw3			@	if not, jump to keep waiting
	ldr	rvb, =PLL3_parms	@ M2, M and N parameters for M2X1 (twice the L3 freq)
	str	rvb, [rva, #0x40]	@ cm_clksel1_pll <- M2, M, N for 2 x L3 freq, 4 x L4 freq
	ldr	rvb, [rva]		@ rvb <- contents of cm_clken_pll (dpll3 = core dpll)
.ifndef	TI_Beagle_XM
	bic	rvb, rvb, #0xff
	orr	rvb, rvb, #0x37		@ fsel = 0x03, lock
.else
	bic	rvb, rvb, #0x0f
	orr	rvb, rvb, #0x07		@ lock (no fsel on DM37)
.endif
	str	rvb, [rva]		@ cm_clken_pll <- dpll3 lock
plbwt4:	@ wait for lock
	ldr	rvb, [rva, #0x20]	@ rvb <- cm_idlest_ckgen
	tst	rvb, #1			@ locked?
	beq	plbwt4			@	if not, jump to keep waiting
	@
	@ DPLL1: set-up the MPU dpll
	@
	ldr	rva, =0x48004900	@ MPU dpll
	ldr	rvb, [rva, #4]
	bic	rvb, rvb, #0x07
	orr	rvb, rvb, #0x05
	str	rvb, [rva, #4]		@ cm_clken_pll_mpu <- dpll1 in low power bypass
plbwt1:	@ wait for bypass
	ldr	rvb, [rva, #0x24]	@ rvb <- cm_idlest_pll_mpu
	tst	rvb, #1			@ bypassed?
	bne	plbwt1			@	if not, jump to keep waiting
	ldr	rvb, =PLL1_parms	@ rvb <- fclk vs corclk, M and N for MPU frequency selection
	str	rvb, [rva, #0x40]	@ cm_clksel1_pll_mpu <- set MPU frequency PLL parameters
	set	rvb, #0x01
	str	rvb, [rva, #0x44]	@ cm_clksel2_pll_mpu <- M2 = 0x01
	ldr	rvb, [rva, #4]
.ifndef	TI_Beagle_XM
	bic	rvb, rvb, #0xff
	orr	rvb, rvb, #0x37		@ fsel = 0x03, lock
.else
	bic	rvb, rvb, #0x0f
	orr	rvb, rvb, #0x07		@ lock (no fsel on DM37)
.endif
	str	rvb, [rva, #4]		@ cm_clken_pll_mpu <- dpll1, lock
plmwt1:	@ wait for lock
	ldr	rvb, [rva, #0x24]	@ rvb <- cm_idlest_pll_mpu
	tst	rvb, #1			@ locked?
	beq	plmwt1			@	if not, jump to keep waiting
	@ sdrc pads (POP RAM)
	ldr	rva, =SCM_base		@ rva <- SCM base (System Control Module, p.131)
	add	rva, rva, #0x0200
	ldrh	rvb, [rva, #0x62]
	bic	rvb, rvb, #0x0100
	bic	rvb, rvb, #0x0007
	strh	rvb, [rva, #0x62]	@ cke0 <- output, pull-up, mode 0
.ifdef	configure_CS1
	ldrh	rvb, [rva, #0x64]
	bic	rvb, rvb, #0x0100
	bic	rvb, rvb, #0x0007
	strh	rvb, [rva, #0x64]	@ cke1 <- output, pull-up, mode 0
.endif
	@ sdrc controller (external POP ram)
	set	rva, #0x6d000000	@ SDRC base
	set	rvb, #0x02
	str	rvb, [rva, #0x10]	@ reset sdrc
sdrwt1:	@ wait for reset
	ldr	rvb, [rva, #0x14]
	tst	rvb, #0x01
	beq	sdrwt1
	set	rvb, #0x00
	str	rvb, [rva, #0x10]	@ de-assert reset (sysconfig)
	set	rvb, #0x0100
	str	rvb, [rva, #0x44]	@ set sharing mode
.ifdef	configure_CS1
	set	rvb, #(configure_CS1 >> 7)	@ cs1 start address (0x01 = 128MB, 0x02 = 256MB)
	str	rvb, [rva, #0x40]	@ sdrc_cs_cfg <- CS1 starts at 128MB or 256MB
.endif	
	ldr	rvb, =SDRC_MCFG		@ RAS=13/14,CAS=10,128/256MB/bank,row-bank-col,32bit,mobeDDR,DpPwrDn
	str	rvb, [rva, #0x80]	@ sdrc_mcfg_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xb0]	@ sdrc_mcfg_1
.endif
	ldr	rvb, =SDRC_ACTIM_A
	ldr	rvc, =SDRC_ACTIM_B
	str	rvb, [rva, #0x9c]	@ sdrc_actim_ctrla_0
	str	rvc, [rva, #0xa0]	@ sdrc_actim_ctrlb_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xc4]	@ sdrc_actim_ctrla_1
	str	rvc, [rva, #0xc8]	@ sdrc_actim_ctrlb_1
.endif
	ldr	rvb, =SDRC_RFR_CTRL	@ 1294 or 1560 (#x4dc or #x5e6 + 50) -> 7.8us / 6 or 5ns (166/200 MHz)
	str	rvb, [rva, #0xa4]	@ sdrc_rfr_ctrl_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xd4]	@ sdrc_rfr_ctrl_1
.endif
	set	rvb, #0x81
	str	rvb, [rva, #0x70]	@ sdrc_power <- power the POP system
	set	rvb, #0x00		@ NOP command
	str	rvb, [rva, #0xa8]	@ sdrc_manual_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xd8]	@ sdrc_manual_1
.endif
	set	rvc, #0x040000
memwt1:	@ wait a bit
	subs	rvc, rvc, #1
	bne	memwt1
	set	rvb, #0x01		@ precharge command
	str	rvb, [rva, #0xa8]	@ sdrc_manual_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xd8]	@ sdrc_manual_1
.endif
	set	rvb, #0x02		@ auto-refresh command
	str	rvb, [rva, #0xa8]	@ sdrc_manual_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xd8]	@ sdrc_manual_1
.endif
	str	rvb, [rva, #0xa8]	@ sdrc_manual_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xd8]	@ sdrc_manual_1
.endif
	set	rvb, #0x32		@ CAS 3, Burst Length 4
	str	rvb, [rva, #0x84]	@ sdrc_mr_0
.ifdef	configure_CS1
	str	rvb, [rva, #0xb4]	@ sdrc_mr_1
.endif
	@ dlla
.ifndef	TI_Beagle_XM
	set	rvb, #0x0a		@ rvb <- enable dlla, 72 deg phase (I think)
.else
	set	rvb, #0x08		@ rvb <- enable dlla, 90 deg phase
.endif
	str	rvb, [rva, #0x60]	@ sdrc_dlla_ctrl <- enable dlla
	set	rvc, #0x080000
dlawt2:	@ wait a bit
	subs	rvc, rvc, #1
	bne	dlawt2

.endif	@ live_SD

	@
	@ disable watchdog 2
	@
	ldr	rva, =0x48314000	@ rva <- watchdog 2 base address
	ldr	rvb, =0xAAAA		@ rvb <- unlock code 1
	str	rvb, [rva, #0x48]	@ unlock watchdog, step 1
wdwt1:	ldr	rvb, [rva, #0x34]	@ rvb <- watchdog status
	eq	rvb, #0
	bne	wdwt1
	ldr	rvb, =0x5555		@ rvb <- unlock code 2
	str	rvb, [rva, #0x48]	@ unlock watchdog, step 2
wdwt2:	ldr	rvb, [rva, #0x34]	@ rvb <- watchdog status
	eq	rvb, #0
	bne	wdwt2
	@ set interrupt vectors
	ldr	rva, =0x4020ffc8	@ rva <- destination (initialization, p.26)
	ldr	rvb, =0xe59ff014	@ rvb <- ldr pc, [pc, #0x14]
	str	rvb, [rva]		@ undef instr
	str	rvb, [rva, #0x04]	@ swi
	str	rvb, [rva, #0x08]	@ prefetch
	str	rvb, [rva, #0x0c]	@ data abort
	str	rvb, [rva, #0x10]	@ unused/crc
	str	rvb, [rva, #0x14]	@ irq
	str	rvb, [rva, #0x18]	@ fiq
	ldr	rvb, =inserr
	str	rvb, [rva, #0x1c]	@ undef instr
	ldr	rvb, =swi_hndlr
	str	rvb, [rva, #0x20]	@ swi
	ldr	rvb, =prferr
	str	rvb, [rva, #0x24]	@ prefetch
	ldr	rvb, =daterr
	str	rvb, [rva, #0x28]	@ data abort
	ldr	rvb, =genisr
	str	rvb, [rva, #0x30]	@ irq
	str	rvb, [rva, #0x34]	@ fiq
	@ invalidate other caches, disable MMU
	set	rvb, #0
	mcr	p15, 0, rvb, c8, c7, 0	@ invalidate instruction and data TLBs
	mcr	p15, 0, rvb, c7, c5, 0	@ invalidate instruction caches
	mrc	p15, 0, rvb, c1, c0, 0	@ rvb <- contents of control register (CP15 reg. 1)
	bic	rvb, rvb, #0x01
	mcr	p15, 0, rvb, c1, c0, 0	@ disable MMU in CP15 register 1
	@ initialize TTB (Translation Table Base) for Default Memory space (not cacheable, not buffered)
	ldr	rvc, =0x0C02		@ rvc <- r/w permitted, domain 0, not cacheable/buffered, 1MB sect.
	ldr	rva, =0x80010000	@ rva <- address of start of TTB (64kb into SDRAM)
	set	rvb, rvc		@ rvb <- section 0 descriptor
ttbst0:	str	rvb, [rva, rvb, LSR #18] @ store section descriptor in Translation Table
	add	rvb, rvb, #0x00100000
	eq	rvb, rvc
	bne	ttbst0
	@ continue initializing TTB, for Scheme core and SDRAM (cacheable, buffered)
	ldr	rvc, =0x0C0E		@ rvc <- r/w permitted, domain 0, cacheable/buffered, 1MB sect.
	@ 0x40200000 direct mapped
	orr	rvb, rvc, #0x40000000
	orr	rvb, rvb, #0x00200000
	str	rvb, [rva, rvb, LSR #18] @ store section descriptor in Translation Table
	orr	rvb, rvc, #0x80000000
ttbst1:	str	rvb, [rva, rvb, LSR #18] @ store section descriptor in Translation Table
	add	rvb, rvb, #0x00100000
	lsr	rvc, rvb, #20
.ifdef	TI_Beagle
  .ifndef live_SD
	eors	rvc, rvc, #0x860	@ 96MB (32MB to shadow flash)
  .else
	eors	rvc, rvc, #0x880	@ 128MB
  .endif
.endif
.ifdef	TI_Beagle_XM
	eors	rvc, rvc, #0xa00	@ 512MB
.endif
.ifdef	GMX_OVERO_TIDE
	eors	rvc, rvc, #0xa00	@ 512MB
.endif	
	bne	ttbst1
	@ use coprocessor 15 to set domain access control, TTB base and enable MMU
	set	rvb, #0x01		@ rvb <- domain 0 uses client access perms (A & P bits checked)
	mcr	p15, 0, rvb, c3, c0, 0	@ set domain access into CP15 register 3
	orr	rva, rva, #0x18		@ TTB 0 outer cacheable, write-back, no allocate on write
	mcr	p15, 0, rva, c2, c0, 0	@ set TTB 0 base address into CP15 register 2
	mcr	p15, 0, rva, c2, c0, 1	@ set TTB 1 base address into CP15 register 2 (same as TTB 0)
	@ L2 cache RAM latency selection and enabling
	@ Note:	latency setting requires secure mode -- disabled here -- accept pre-set default
.ifndef	hardware_FPU
	@ enable L2 cache
	set	rvb, #0x52		@ L2 enable, speculative, Cp15 inval
	mcr	p15, 0, rvb, c1, c0, 1	@ set L2 enable, specultv and CP15 inval in CP15 aux control register
.else
	@ enable L2 cache and NEON/VFP
	set	rvb, #0x72		@ L2 enable, NEON Cache enab, speculative, Cp15 inval
	mcr	p15, 0, rvb, c1, c0, 1	@ set sel in CP15 aux control register
	set	rvb, #0xf00000		@ enable VFP and NEON coprocessors
	mcr	p15, 0, rvb, c1, c0, 2	@ set sel in CP15 coprocessor access control register
	set	r1, #0
	isb				@ instruction memory barrier
	set	rvb, #0x40000000
	fmxr	fpexc, rvb		@ enable VFP/NEON (bit 30 in FPEXC)
	vmrs	rvb, fpscr
	orr	rvb, rvb, #0x00c00000	@ rounding mode = towards zero (i.e. truncate)
	vmsr	fpscr, rvb
.endif
	mrc	p15, 0, rvb, c1, c0, 0	@ rvb <- contents of control register (CP15 reg. 1)
	bic	rvb, rvb, #0x0002	@ rvb <- alignment bit cleared (b1)
	orr	rvb, rvb, #0x1800	@ rvb <- Icache enable (b12), flow prediction enable (b11)
	orr	rvb, rvb, #0x0005	@ rvb <- Dcache enable (b2),  MMU enable (b0)
	mcr	p15, 0, rvb, c1, c0, 0	@ set cache/MMU enable into CP15 register 1
	@ copy scheme code to SDRAM
	bl	codcpy
	@ jump to remainder of initialization
	ldr	pc, =_start

codcpy:	@ copy scheme to SDRAM address 0x80000000
	ldr	r8,  = _text_section_address_	@ start of source
	ldr	r9,  = _startcode	@ start of destination (from build_link file)
	ldr	r10, = _endcode		@ end of destination (from build_link file)
	add	r10, r10,  #4
codcp0:	ldmia	r8!, {r0-r7}
	stmia	r9!, {r0-r7}
	cmp	r9,  r10
	bmi	codcp0
	set	pc,  lnk


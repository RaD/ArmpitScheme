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


	VECSIZE	num_interrupts

ISR_vector:

	.word	i0			@  0
	.word	i0			@  1
	.word	i0			@  2
	.word	i0			@  3
	.word	i0			@  4
	UPFUNC	puaisr,	0		@  5:	uart0
	UPFUNC	puaisr,	0		@  6:	uart1
	.word	i0			@  7
	UPFUNC	pi2isr,	0		@  8:	i2c0 (if included)
	.word	i0			@  9
	.word	i0			@ 10
	.word	i0			@ 11
	.word	i0			@ 12
	.word	i0			@ 13
	.word	i0			@ 14
	.word	i0			@ 15
	.word	i0			@ 16
	.word	i0			@ 17
	.word	i0			@ 18
	UPFUNC	ptmisr,	0		@ 19:	timer0
	.word	i0			@ 20
	UPFUNC	ptmisr,	0		@ 21:	timer1
	.word	i0			@ 22
	.word	i0			@ 23
	.word	i0			@ 24
	.word	i0			@ 25
	.word	i0			@ 26
	.word	i0			@ 27
	.word	i0			@ 28
	.word	i0			@ 29
	.word	i0			@ 30
	.word	i0			@ 31
	.word	i0			@ 32
	.word	i0			@ 33
	.word	i0			@ 34
	.word	i0			@ 35
	.word	i0			@ 36
	UPFUNC	pi2isr,	0		@ 37:	i2c1 (if included)
	.word	i0			@ 38
	.word	i0			@ 39
	.word	i0			@ 40
	.word	i0			@ 41
	.word	i0			@ 42
	.word	i0			@ 43
	UPFUNC	usbisr,	0		@ 44:	USB OTG FS Device (if included)
	.word	i0			@ 45
	.word	i0			@ 46
	.word	i0			@ 47
	.word	i0			@ 48
	.word	i0			@ 49
	.word	i0			@ 50
	.word	i0			@ 51
	.word	i0			@ 52
	.word	i0			@ 53
	.word	i0			@ 54
	.word	i0			@ 55
	.word	i0			@ 56
	.word	i0			@ 57
	.word	i0			@ 58
	.word	i0			@ 59
	.word	i0			@ 60
	.word	i0			@ 61
	.word	i0			@ 62
	.word	i0			@ 63

	
@
@ 1- Initialization from FLASH, writing to and erasing FLASH
@


.ifndef TI_EValBot

.balign	4
flashsectors:	@ 256 x 1KB FLASH sectors of LM3S1958, LM3S1968, LM3S6965
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000000, 0x00000400, 0x00000800, 0x00000C00, 0x00001000, 0x00001400, 0x00001800, 0x00001C00
.word	0x00002000, 0x00002400, 0x00002800, 0x00002C00, 0x00003000, 0x00003400, 0x00003800, 0x00003C00
.word	0x00004000, 0x00004400, 0x00004800, 0x00004C00, 0x00005000, 0x00005400, 0x00005800, 0x00005C00
.word	0x00006000, 0x00006400, 0x00006800, 0x00006C00, 0x00007000, 0x00007400, 0x00007800, 0x00007C00
.word	0x00008000, 0x00008400, 0x00008800, 0x00008C00, 0x00009000, 0x00009400, 0x00009800, 0x00009C00
.word	0x0000a000, 0x0000a400, 0x0000a800, 0x0000aC00, 0x0000b000, 0x0000b400, 0x0000b800, 0x0000bC00
.word	0x0000c000, 0x0000c400, 0x0000c800, 0x0000cC00, 0x0000d000, 0x0000d400, 0x0000d800, 0x0000dC00
.word	0x0000e000, 0x0000e400, 0x0000e800, 0x0000eC00, 0x0000f000, 0x0000f400, 0x0000f800, 0x0000fC00
.word	0x00010000, 0x00010400, 0x00010800, 0x00010C00, 0x00011000, 0x00011400, 0x00011800, 0x00011C00
.word	0x00012000, 0x00012400, 0x00012800, 0x00012C00, 0x00013000, 0x00013400, 0x00013800, 0x00013C00
.word	0x00014000, 0x00014400, 0x00014800, 0x00014C00, 0x00015000, 0x00015400, 0x00015800, 0x00015C00
.word	0x00016000, 0x00016400, 0x00016800, 0x00016C00, 0x00017000, 0x00017400, 0x00017800, 0x00017C00
.word	0x00018000, 0x00018400, 0x00018800, 0x00018C00, 0x00019000, 0x00019400, 0x00019800, 0x00019C00
.word	0x0001a000, 0x0001a400, 0x0001a800, 0x0001aC00, 0x0001b000, 0x0001b400, 0x0001b800, 0x0001bC00
.word	0x0001c000, 0x0001c400, 0x0001c800, 0x0001cC00, 0x0001d000, 0x0001d400, 0x0001d800, 0x0001dC00
.word	0x0001e000, 0x0001e400, 0x0001e800, 0x0001eC00, 0x0001f000, 0x0001f400, 0x0001f800, 0x0001fC00
.word	0x00020000, 0x00020400, 0x00020800, 0x00020C00, 0x00021000, 0x00021400, 0x00021800, 0x00021C00
.word	0x00022000, 0x00022400, 0x00022800, 0x00022C00, 0x00023000, 0x00023400, 0x00023800, 0x00023C00
.word	0x00024000, 0x00024400, 0x00024800, 0x00024C00, 0x00025000, 0x00025400, 0x00025800, 0x00025C00
.word	0x00026000, 0x00026400, 0x00026800, 0x00026C00, 0x00027000, 0x00027400, 0x00027800, 0x00027C00
.word	0x00028000, 0x00028400, 0x00028800, 0x00028C00, 0x00029000, 0x00029400, 0x00029800, 0x00029C00
.word	0x0002a000, 0x0002a400, 0x0002a800, 0x0002aC00, 0x0002b000, 0x0002b400, 0x0002b800, 0x0002bC00
.word	0x0002c000, 0x0002c400, 0x0002c800, 0x0002cC00, 0x0002d000, 0x0002d400, 0x0002d800, 0x0002dC00
.word	0x0002e000, 0x0002e400, 0x0002e800, 0x0002eC00, 0x0002f000, 0x0002f400, 0x0002f800, 0x0002fC00
.word	0x00030000, 0x00030400, 0x00030800, 0x00030C00, 0x00031000, 0x00031400, 0x00031800, 0x00031C00
.word	0x00032000, 0x00032400, 0x00032800, 0x00032C00, 0x00033000, 0x00033400, 0x00033800, 0x00033C00
.word	0x00034000, 0x00034400, 0x00034800, 0x00034C00, 0x00035000, 0x00035400, 0x00035800, 0x00035C00
.word	0x00036000, 0x00036400, 0x00036800, 0x00036C00, 0x00037000, 0x00037400, 0x00037800, 0x00037C00
.word	0x00038000, 0x00038400, 0x00038800, 0x00038C00, 0x00039000, 0x00039400, 0x00039800, 0x00039C00
.word	0x0003a000, 0x0003a400, 0x0003a800, 0x0003aC00, 0x0003b000, 0x0003b400, 0x0003b800, 0x0003bC00
.word	0x0003c000, 0x0003c400, 0x0003c800, 0x0003cC00, 0x0003d000, 0x0003d400, 0x0003d800, 0x0003dC00
.word	0x0003e000, 0x0003e400, 0x0003e800, 0x0003eC00, 0x0003f000, 0x0003f400, 0x0003f800, 0x0003fC00
.word	0x00040000, 0x00050000

.else	@ TI_EvalBot

.balign	4
flashsectors:	@ 64 x 4 KB FLASH sectors of LM3S9B92 (best to use 4 KB sectors for erase, p.307)
lib_sectors:	@ lib shares on-chip file flash
.word	0x00000000, 0x00001000, 0x00002000, 0x00003000, 0x00004000, 0x00005000, 0x00006000, 0x00007000
.word	0x00008000, 0x00009000, 0x0000a000, 0x0000b000, 0x0000c000, 0x0000d000, 0x0000e000, 0x0000f000
.word	0x00010000, 0x00011000, 0x00012000, 0x00013000, 0x00014000, 0x00015000, 0x00016000, 0x00017000
.word	0x00018000, 0x00019000, 0x0001a000, 0x0001b000, 0x0001c000, 0x0001d000, 0x0001e000, 0x0001f000
.word	0x00020000, 0x00021000, 0x00022000, 0x00023000, 0x00024000, 0x00025000, 0x00026000, 0x00027000
.word	0x00028000, 0x00029000, 0x0002a000, 0x0002b000, 0x0002c000, 0x0002d000, 0x0002e000, 0x0002f000
.word	0x00030000, 0x00031000, 0x00032000, 0x00033000, 0x00034000, 0x00035000, 0x00036000, 0x00037000
.word	0x00038000, 0x00039000, 0x0003a000, 0x0003b000, 0x0003c000, 0x0003d000, 0x0003e000, 0x0003f000
.word	0x00040000, 0x00050000
	
.endif








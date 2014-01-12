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

@-------------------------------------------------------------------------------
@
@  I.B.3. Scheme Initialization ALL ARCHITECTURES
@
@-------------------------------------------------------------------------------

	
.ifndef	exclude_read_write

		SYMSIZE	(prgend - prgstr)

prgstr:		@ start of startup program

.ascii		"(begin "
.ascii		  "(write (call/cc (lambda (_prg) (set! _catch _prg)))) "
.ascii		  "(if (eq? _prg #t) "
.ascii		      "(load ((lambda () (set! _prg #f) \"boot\")))) "
.ascii		  "(define (_prg) "
.ascii		    "(write-char #\\newline) "
.ascii		    "(prompt) "
.ascii		    "(write (eval (read) (interaction-environment))) "
.ascii		    "(_prg)) "
.ascii		  "(_prg))"

prgend:		@ end of startup program

.balign	4

.endif




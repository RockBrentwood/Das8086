# 8086 16-Bit Disassembler

Derived from a disassembler for the 16-bit member, 8086, of the x86 family,
originally written by Justo Senka in x86 assembly suitable for processing by MASM or TASM,
it is being prepared for translation to C.

It only handles the limited subset of the 8086 comprising the opcodes:

    MOV PUSH POP ADD INC SUB DEC CMP MUL DIV CALL RET JMP LOOP INT, and most of Jumps

and is being staged for upward expansion to include the other opcodes.

![Left: Disassembled code --- Right: Original Code](https://github.com/RockBrentwood/Das8086/blob/master/Images/DisAsm2.png?raw=true)

## How to run

**DOS platform required, for now**

It can be run on a 16-bit OS, such as DOS,
or on any host that has installed a DOS emulator (such as DOSBox) or other 8086 Emulator, such as Emu8086.

When translated to C, this restriction will be removed
and the program will be compileable on any host that has a C compiler upwardly compatible with C99,
and executable on any platform which the C compiler compiles to.

The program executes from the command line and expects 2 arguments:
- InFile: the file to disassemble,
- ExFile: the disassembly output.
Example: `DisAsm86 Test.bin Test.s`

## How to compile

Can be easily compiled with:
- Emu8086: Open source file and press run.
  Runs on contemporary hosts.
- DOS: Using Tasm 1.4.
  For now, a copy of TASM has been provided, along with a Makefile for compiling on DOS.
  The DOS host should have a "make" utility (e.g. "nmake").
  To compile by hand, from within DOSBox:
     `Tasm\Tasm DisAsm86` command will compile source to obj,
  and
     `Tasm\tlink DisAsm86.obj` will link the object file to create the executable.

## Source Code

Uploading just now, but originally it was written in late 2014.
Source Code is released under MIT license.
It can be used freely however you want, although, there are some bugs and it doesn't support all instructions as it was written as part of learning process.
Storing source code here to preserve it for future generations as it could be used for a learning material to something the world has already passed and forgotten.. 8086

## Upward Revision

A root canal is being done on the source to open up its structure
so that it can be scaled up to handle later versions of the x86 family.

Its main talking point is that it is making direct use of the compile binary opcode maps
that were originally presented in Intel's 80x86 family references.

It may also be downgraded to handle the 8080/8085, which is the immediate forebear of the 8086, as well as the Z80.

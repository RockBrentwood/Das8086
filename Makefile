## Makefile: DOS version - to be run either on a native DOS platform or in DosBox on a host that has DosBox installed.
## This assumes some version of the "make" utility is available (e.g. "nmake").
## The "make test" routine is not fully-operational:
## you need to compare, by hand, the "Test.s" file in the "Tests" directory manually with the reference file "TestB.s".
AS=tasm\tasm
LN=tasm\tlink
#X=
#O=.o
#S=.s
#RM=rm -f
X=.exe
O=.obj
S=.asm
RM=del

all: DisAsm86$X
DisAsm86$O: DisAsm86$S
	$(AS) DisAsm86$S
DisAsm86$X: DisAsm86$O
	$(LN) DisAsm86$O
clean:
	$(RM) DisAsm86$O
clobber: clean
	$(RM) DisAsm86$X
test:	DisAsm86$X
	cd Tests
	..\DisAsm86$X Test.bin Test.s
##	diff Test.s TestB.s
	cd ..

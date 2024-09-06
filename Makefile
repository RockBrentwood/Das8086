CC=gcc
LN=gcc
X=
O=.o
C=.c
RM=rm -f

all: DisAsm86$X
DisAsm86$O: DisAsm86$C
	$(CC) -c $^
DisAsm86$X: DisAsm86$O
	$(LN) $^ -o $@
clean:
	$(RM) DisAsm86$O
	$(RM) Tests/Test.s
clobber: clean
	$(RM) DisAsm86$X
test:	DisAsm86$X
	cd Tests; ../DisAsm86$X Test.bin Test.s; diff Test.s TestB.s; cd ..

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

typedef unsigned char byte;
typedef unsigned word;

word BaseIP = 0x100;

byte InBuf[0x10000]; // A buffer set at the maximum size of an 8086 segment.
byte ExBuf[61];
byte IsRw = 0;
bool IsRs = false;
byte DispN = 0;
byte OpCode = 0;
byte ModByte = 0;
word ByteP = 9;
word CurIP = 0;

typedef struct ListItem *ListItem;
struct ListItem {
   byte _Bytes, _Mask, _xrm, _d, _w, _s, _xcm, _Op, _Reg, _PB;
// All of the 00 aaa 0dw xrm should be combined: AOp (add,or,adc,sbb,and,sub,xor,cmp), (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
// All of the 00 aaa 10w should be combined: AOp (add,or,adc,sbb,and,sub,xor,cmp), (AL,Ib; AX,Iw)
} ListTab[] = {
   { 0000, 0374, 1, 1, 1, 0, 00,  7, 0000, 0x00 }, // 00 000 0dw xrm: add (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0010, 0374, 1, 1, 1, 0, 00,  8, 0000, 0x00 }, // 00 001 0dw xrm: or (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0020, 0374, 1, 1, 1, 0, 00,  9, 0000, 0x00 }, // 00 010 0dw xrm: adc (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0030, 0374, 1, 1, 1, 0, 00, 10, 0000, 0x00 }, // 00 011 0dw xrm: sbb (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0040, 0374, 1, 1, 1, 0, 00, 11, 0000, 0x00 }, // 00 100 0dw xrm: and (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0050, 0374, 1, 1, 1, 0, 00, 12, 0000, 0x00 }, // 00 101 0dw xrm: sub (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0060, 0374, 1, 1, 1, 0, 00, 13, 0000, 0x00 }, // 00 110 0dw xrm: xor (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0070, 0374, 1, 1, 1, 0, 00, 14, 0000, 0x00 }, // 00 111 0dw xrm: cmp (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0004, 0376, 0, 0, 1, 0, 00,  7, 0000, 0x01 }, // 00 000 10w: add (AL,Ib; AX,Iw)
   { 0014, 0376, 0, 0, 1, 0, 00,  8, 0000, 0x01 }, // 00 001 10w: or (AL,Ib; AX,Iw)
   { 0024, 0376, 0, 0, 1, 0, 00,  9, 0000, 0x01 }, // 00 010 10w: adc (AL,Ib; AX,Iw)
   { 0034, 0376, 0, 0, 1, 0, 00, 10, 0000, 0x01 }, // 00 011 10w: sbb (AL,Ib; AX,Iw)
   { 0044, 0376, 0, 0, 1, 0, 00, 11, 0000, 0x01 }, // 00 100 10w: and (AL,Ib; AX,Iw)
   { 0054, 0376, 0, 0, 1, 0, 00, 12, 0000, 0x01 }, // 00 101 10w: sub (AL,Ib; AX,Iw)
   { 0064, 0376, 0, 0, 1, 0, 00, 13, 0000, 0x01 }, // 00 110 10w: xor (AL,Ib; AX,Iw)
   { 0074, 0376, 0, 0, 1, 0, 00, 14, 0000, 0x01 }, // 00 111 10w: cmp (AL,Ib; AX,Iw)
   { 0006, 0347, 0, 0, 0, 0, 00,  5, 0030, 0x00 }, // 00 0rr 110: push Rs (ES,CS,SS,DS)
   { 0046, 0347, 0, 0, 0, 0, 00, 29, 0030, 0x00 }, // 00 1rr 110: Rs: (ES,CS,SS,DS)
   { 0007, 0347, 0, 0, 0, 0, 00,  6, 0030, 0x00 }, // 00 0rr 111: pop Rs (ES,CS,SS,DS) CS is excluded on 80186+
// { 0047, 0347, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 00 1bb 111: BOp (daa,das,aaa,aas)
   { 0100, 0370, 0, 0, 3, 0, 00,  3, 0007, 0x00 }, // 01 000 rrr: inc Rw (AX,CX,DX,BX,SP,BP,SI,DI)
   { 0110, 0370, 0, 0, 3, 0, 00,  4, 0007, 0x00 }, // 01 001 rrr: dec Rw (AX,CX,DX,BX,SP,BP,SI,DI)
   { 0120, 0370, 0, 0, 3, 0, 00,  5, 0007, 0x00 }, // 01 010 rrr: push Rw (AX,CX,DX,BX,SP,BP,SI,DI)
   { 0130, 0370, 0, 0, 3, 0, 00,  6, 0007, 0x00 }, // 01 011 rrr: pop Rw (AX,CX,DX,BX,SP,BP,SI,DI)
// { 0140, 0377, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 01 100 000: pusha [80186+]
// { 0141, 0377, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 01 100 001: popa [80186+]
// { 0142, 0377, 1, 0, 3, 0, 00, __, 0000, 0x00 }, // 01 100 010 xrm: bound Rw,Ew [80186+]
// { 0150, 0375, 0, 0, 0, 1, 00,  5, 0200, 0x02 }, // 01 101 0s0: push (Iw; Is) [80186+]
// { 0151, 0375, 1, 0, 0, 1, 00, 18, 0000, 0x02 }, // 01 101 0s0 xrm: imul (Rw,Ew,Iw; Rw,Ew,Is) [80186+]
// { 0154, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 01 101 10w: (insb,insw) [80186+]
// { 0156, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 01 101 11w: (outsb,outsw) [80186+]
   { 0x70, 0xf0, 0, 0, 0, 0, 00, 30, 0200, 0x10 }, // 0111 cccc: jCC Jb (o,no,b,nb,e,ne,na,a,s,ns,p,np,l,ge,le,g)
// All of the 10 000 0sw /A should be combined using AOp like this:
// { 0200, 0374, 2, 0, 1, 1, 00, __, 0000, 0x00 }, // 10 000 0sw xAm: AOp (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 00,  7, 0000, 0x00 }, // 10 000 0sw x0m: add (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 01,  8, 0000, 0x00 }, // 10 000 0sw x1m: or (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 02,  9, 0000, 0x00 }, // 10 000 0sw x2m: adc (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 03, 10, 0000, 0x00 }, // 10 000 0sw x3m: sbb (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 04, 11, 0000, 0x00 }, // 10 000 0sw x4m: and (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 05, 12, 0000, 0x00 }, // 10 000 0sw x5m: sub (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 06, 13, 0000, 0x00 }, // 10 000 0sw x6m: xor (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0200, 0374, 2, 0, 1, 1, 07, 14, 0000, 0x00 }, // 10 000 0sw x7m: cmp (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
   { 0204, 0376, 1, 0, 1, 2, 00,  2, 0000, 0x00 }, // 10 000 10w: test (Eb,Ib; Ew,Iw)
   { 0206, 0376, 1, 0, 1, 2, 00,  1, 0000, 0x00 }, // 10 000 11w: xchg (Eb,Ib; Ew,Iw)
   { 0210, 0374, 1, 1, 1, 0, 00,  0, 0000, 0x00 }, // 10 001 0dw xrm: mov (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
   { 0214, 0375, 1, 1, 3, 0, 00,  0, 0030, 0x00 }, // 10 001 100 xrm: mov Ew,Rs
// { 0215, 0377, 1, 0, 3, 0, 00, __, 0000, 0x00 }, // 10 001 101 xrm: lea Ew (r != 3)
   { 0217, 0377, 2, 0, 3, 0, 00,  6, 0000, 0x00 }, // 10 001 111 x0m: pop Ew
// { 0220, 0370, 0, 0, 0, 0, 00,  1, 0007, 0x00 }, // 10 010 rrr: xchg AX, Rw (note: xchg AX, AX = nop)
// { 0230, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 10 011 00w: COp (cbw,cwd)
   { 0232, 0377, 0, 0, 0, 0, 00, 21, 0200, 0x04 }, // 10 011 010: call Af
// { 0233, 0377, 0, 0, 0, 0, 00, __, 0000, 0x00 }, // 10 011 011: wait
// { 0234, 0374, 0, 0, 0, 0, 00, __, 0000, 0x00 }, // 10 011 1ff: FOp (pushf, popf, sahf, lahf)
   { 0240, 0374, 0, 1, 1, 0, 00,  0, 0040, 0x00 }, // 10 100 0dw: mov (AL,Mb; AX,Mw; Mb,AL; Mw,AL)
// { 0244, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 10 100 10w: (movsb,movsw)
// { 0246, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 10 100 11w: (cmpsb,cmpsw)
   { 0250, 0376, 0, 0, 1, 0, 00,  2, 0000, 0x01 }, // 10 101 00w: test (AL,Ib; AX,Iw)
// { 0252, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 10 101 01w: (stosb,stosw)
// { 0254, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 10 101 10w: (lodsb,lodsw)
// { 0256, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 10 101 11w: (scasb,scasw)
   { 0260, 0360, 0, 0, 0, 0, 00,  0, 0017, 0x01 }, // 10 11w rrr: mov (Rb,Ib; Rw,Iw)
// { 0300, 0376, 2, 0, 1, 0, __, __, 0000, 0x00 }, // 11 000 00w xAm: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,Ib; Ew,Iw) [80186+]
   { 0302, 0377, 0, 0, 0, 0, 00, 24, 0200, 0x02 }, // 11 000 010: ret Iw
   { 0303, 0377, 0, 0, 0, 0, 00, 24, 0200, 0x00 }, // 11 000 011: ret
// { 0304, 0377, 1, 0, 3, 0, 00, __, 0000, 0x00 }, // 11 000 100 xrm: les Rw,Ew
// { 0305, 0377, 1, 0, 3, 0, 00, __, 0000, 0x00 }, // 11 000 101 xrm: lds Rw,Ew
   { 0306, 0376, 2, 0, 1, 2, 00,  0, 0000, 0x00 }, // 11 000 11w x0m: mov (Eb,Ib; Ew,Iw)
// { 0310, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 001 000: enter [80186+]
// { 0311, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 001 001: leave [80186+]
   { 0312, 0377, 0, 0, 0, 0, 00, 25, 0200, 0x02 }, // 11 001 010: retf Iw
   { 0313, 0377, 0, 0, 0, 0, 00, 25, 0200, 0x00 }, // 11 001 011: retf
// { 0314, 0377, 0, 0, 0, 0, 00, 23, 0200, 0x00 }, // 11 001 100: int 3
   { 0315, 0377, 0, 0, 0, 0, 00, 23, 0200, 0x01 }, // 11 001 101: int Ib
// { 0316, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 001 110: into
   { 0317, 0377, 0, 0, 0, 0, 00, 26, 0200, 0x00 }, // 11 001 111: iret
// { 0320, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 11 010 00w: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,Ib; Ew,Iw)
// { 0322, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 11 010 01w: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,CL; Ew,CL)
// { 0324, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 010 100: aam
// { 0325, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 010 101: aad
// { 0326, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 010 110: salc [excluded on 80186+]
// { 0327, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 010 111: xlat
// { 0330, 0370, 1, 0, 0, 0, 00, __, 0007, 0x00 }, // 11 011 ppp xrm: esc p Eb
// { 0340, 0377, 0, 0, 0, 0, 00, __, 0200, 0x10 }, // 11 100 000: loopne Jb
// { 0341, 0377, 0, 0, 0, 0, 00, __, 0200, 0x10 }, // 11 100 001: loope Jb
   { 0342, 0377, 0, 0, 0, 0, 00, 27, 0200, 0x10 }, // 11 100 010: loop Jb
   { 0343, 0377, 0, 0, 0, 0, 00, 28, 0200, 0x10 }, // 11 100 011: jcxz Jb
// { 0344, 0376, 0, 0, 1, 0, 00, __, 0000, 0x01 }, // 11 100 10w: in (AL,Ib; AX,Ib)
// { 0346, 0376, 0, 0, 1, 0, 00, __, 0000, 0x01 }, // 11 100 11w: out (Ib,AL; Ib,AX)
   { 0350, 0377, 0, 0, 0, 0, 00, 21, 0200, 0x20 }, // 11 101 000: call An
   { 0351, 0377, 0, 0, 0, 0, 00, 22, 0200, 0x20 }, // 11 101 001: jmp An
   { 0352, 0377, 0, 0, 0, 0, 00, 22, 0200, 0x04 }, // 11 101 010: jmp Af
   { 0353, 0377, 0, 0, 0, 0, 00, 22, 0200, 0x10 }, // 11 101 011: jmp Jb
// { 0354, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 11 101 10w: in (AL,DX; AX,DX)
// { 0356, 0376, 0, 0, 1, 0, 00, __, 0000, 0x00 }, // 11 101 11w: out (DX,AL; DX,AX)
// { 0360, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 110 000: lock
// { 0362, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 110 010: repne
// { 0363, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 110 011: rep
// { 0364, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 110 100: hlt
// { 0365, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 110 101: cmc
// { 0366, 0376, 2, 0, 1, 0, 00, __, 0000, 0x01 }, // 11 110 11w x0m: test (Eb,Ib; Ew,Iw)
   { 0366, 0376, 2, 0, 1, 0, 02, 15, 0000, 0x00 }, // 11 110 11w x2m: neg (Eb; Ew)
   { 0366, 0376, 2, 0, 1, 0, 03, 16, 0000, 0x00 }, // 11 110 11w x3m: not (Eb; Ew)
   { 0366, 0376, 2, 0, 1, 0, 04, 17, 0000, 0x00 }, // 11 110 11w x4m: mul (Eb; Ew)
   { 0366, 0376, 2, 0, 1, 0, 05, 18, 0000, 0x00 }, // 11 110 11w x5m: imul (Eb; Ew)
   { 0366, 0376, 2, 0, 1, 0, 06, 19, 0000, 0x00 }, // 11 110 11w x6m: div (Eb; Ew)
   { 0366, 0376, 2, 0, 1, 0, 07, 20, 0000, 0x00 }, // 11 110 11w x7m: idiv (Eb; Ew)
// { 0370, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 111 000: clc
// { 0371, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 111 001: stc
// { 0372, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 111 010: cli
// { 0373, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 111 011: sti
// { 0374, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 111 100: cld
// { 0375, 0377, 0, 0, 0, 0, 00, __, 0200, 0x00 }, // 11 111 101: std
   { 0376, 0376, 2, 0, 1, 0, 00,  3, 0000, 0x00 }, // 11 111 11w x0m: inc (Eb; Ew)
   { 0376, 0376, 2, 0, 1, 0, 01,  4, 0000, 0x00 }, // 11 111 11w x1m: dec (Eb; Ew)
   { 0377, 0377, 2, 0, 3, 0, 02, 21, 0000, 0x00 }, // 11 111 111 x2m: call near En
   { 0377, 0377, 2, 0, 4, 0, 03, 21, 0000, 0x00 }, // 11 111 111 x3m: call far Ef
   { 0377, 0377, 2, 0, 2, 0, 04, 22, 0000, 0x00 }, // 11 111 111 x4m: jmp near En
   { 0377, 0377, 2, 0, 3, 0, 05, 22, 0000, 0x00 }, // 11 111 111 x5m: jmp far Ef
   { 0377, 0377, 2, 0, 3, 0, 06,  5, 0000, 0x00 }, // 11 111 111 x6m: push Ew
};
const size_t ListN = sizeof ListTab/sizeof ListTab[0];
ListItem ListEnd = ListTab + ListN - 1;

void ShowS(const char *S, size_t N, word *XP) {
   word X = *XP;
   for (size_t n = 0; n < N; n++) ExBuf[X++] = *S++;
   *XP = X;
}
#define Show1(S, XP) ShowS((S), 1, (XP))
#define Show2(S, XP) ShowS((S), 2, (XP))
#define Show3(S, XP) ShowS((S), 3, (XP))
#define Show4(S, XP) ShowS((S), 4, (XP))

void ShowByteHex(byte B, word *XP) {
   word X = *XP;
   byte H = B/0x10; ExBuf[X++] = H + (H < 10? '0': 'A' - 10);
   byte L = B%0x10; ExBuf[X++] = L + (L < 10? '0': 'A' - 10);
   *XP = X;
}

void ShowWordHex(word W, word *XP) { ShowByteHex((W >> 8)&0xff, XP), ShowByteHex(W&0xff, XP); }

void WriteAddress(void) { // BaseIP + CurIP: The (relocated) address.
   ByteP = 0;
   ShowWordHex(CurIP + BaseIP, &ByteP), Show2(": ", &ByteP), ShowByteHex(OpCode, &ByteP), Show1(" ", &ByteP);
}

void WriteCommand(byte Op) { // Op: operator number.
   const char *Command[] = {
      "MOV ", "XCHG", "TEST",
      "INC ", "DEC ", "PUSH", "POP ",
      "ADD ", "OR  ", "ADC ", "SBB ", "AND ", "SUB ", "XOR ", "CMP ",
      "NEG ", "NOT ", "MUL ", "IMUL", "DIV ", "IDIV",
      "CALL", "JMP ", "INT ",
      "RET ", "RETF", "IRET",
      "LOOP", "JCXZ",
      "  : ", "    "
   };
   word X = 24; Show4(Command[Op], &X);
}

void WriteJcc(byte cc) { // cc: condition number.
   const char *Jcc[] = {
      "JO  ", "JNO ", "JB  ", "JNB ", "JE  ", "JNE ", "JNA ", "JA  ",
      "JS  ", "JNS ", "JP  ", "JNP ", "JL  ", "JGE ", "JLE ", "JG  "
   };
   word X = 24; Show4(Jcc[cc], &X);
}

void WriteSegReg(byte Reg, word *XP) { // Reg: Register number, *XP: the line column to write to.
   const char *SegName[] = { "ES", "CS", "SS", "DS" };
   Show2(SegName[Reg], XP), IsRs = false;
}

void WriteReg(byte Reg, word *XP) { // Reg: Register number (if !IsRs), *XP: the line column to write to.
   const char *RegName[] = { "AL", "CL", "DL", "BL", "AH", "CH", "DH", "BH", "AX", "CX", "DX", "BX", "SP", "BP", "SI", "DI" };
   if (IsRs)
      WriteSegReg((ModByte >> 3)&3, XP);
   else
      Show2(RegName[Reg], XP);
}

byte ReadByte(void) { // CurIP: the last command IP, &ByteP: the line column to write to => the byte.
   byte B = InBuf[++CurIP];
   ShowByteHex(B, &ByteP), Show1(" ", &ByteP);
   return B;
}

word ReadInt(void) {
   byte L = ReadByte(), H = L&0x80? 0xff: 0x00;
   return H << 8 | L;
}

word ReadWord(void) {
   byte L = ReadByte(), H = ReadByte();
   return H << 8 | L;
}

void WriteDirectAddress(word *XP) { // *XP: the line column to write to.
   Show2("[0", XP), ShowWordHex(ReadWord(), XP), Show2("h]", XP);
}

void WriteEffAddr(byte DispN, word *XP) { // DispN: the number of displacement bytes, *XP: the line column to write to.
   const char *RegMode[] = { "[BX+SI]", "[BX+DI]", "[BP+SI]", "[BP+DI]", "[SI]", "[DI]", "[BP]", "[BX]" };
// Write Register/Memory Address.
// Direct address, xm == 06.
   if ((ModByte&0307) == 006) WriteDirectAddress(XP);
// Indexed address, xm != 06.
   else {
      const char *Reg = RegMode[ModByte&7]; ShowS(Reg, strlen(Reg), XP);
   }
// Write Displacement.
   if (DispN != 0) {
   // There is a displacement.
      Show4(" + 0", XP);
   // One-byte offset.
      if (DispN == 1) ShowByteHex(ReadByte(), XP), Show1("h", XP);
   // Two-byte offset.
      else ShowWordHex(ReadWord(), XP), Show1("h", XP);
   }
}

void WriteFreeOperand(byte DispN, word *XP) { // DispN: the number of bytes, *XP: the line column to write to.
// No operands.
   if (DispN == 0) return;
// One-byte operand.
   else if (DispN <= 1) Show1("0", XP), ShowByteHex(ReadByte(), XP), Show1("h", XP);
// Two-byte operand.
   else if (DispN <= 2) Show1("0", XP), ShowWordHex(ReadWord(), XP), Show1("h", XP);
// Four-byte operand: far address.
   else {
      word Off = ReadWord(), Seg = ReadWord();
      Show1("0", XP), ShowWordHex(Seg, XP), Show2("h:", XP);
      Show1("0", XP), ShowWordHex(Off, XP), Show1("h", XP);
   }
}

void WriteJumpDisp(byte DispN, word *XP) { // DispN: the number of displacement bytes, *XP: the line column to write to.
// One versus two byte jump displacement.
   word DX = DispN == 1? ReadInt(): ReadWord();
   ShowWordHex(CurIP + 1 + BaseIP + DX, XP), Show1("h", XP);
}

void CheckRv(ListItem LP) { // LP: the command prototype
   switch (LP->_w) {
      case 3: IsRw = 010; break;
      case 4: IsRw = 020; break;
      case 1: IsRw = OpCode&1? 010: 000; break;
      default: IsRw = 000; break;
   }
}

void CheckMod(ListItem LP) { // LP: the command prototype.
   word X;
   CheckRv(LP);
   DispN = (ModByte >> 6)&3;
   if (DispN == 3) {
      if (LP->_d == 1 && !(OpCode&2))
      // Direction Reverse 1: r/m <- reg // _d = 0.
         X = 34, WriteReg((ModByte >> 3)&7 | IsRw, &X),
         X = 30, WriteReg(ModByte&7 | IsRw, &X), Show2(", ", &X);
      else
      // reg <- r/m // _d = 1 or no at all.
         X = 30, WriteReg((ModByte >> 3)&7 | IsRw, &X), Show2(", ", &X), WriteReg(ModByte&7 | IsRw, &X);
   } else if (LP->_d == 1 && !(OpCode&2))
   // Direction Reverse 2: r/m <- reg // _d = 0.
      X = 30, WriteEffAddr(DispN, &X), Show2(", ", &X), WriteReg((ModByte >> 3)&7 | IsRw, &X);
   else
   // reg <- r/m // _d = 1 or no at all.
      X = 30, WriteReg((ModByte >> 3)&7 | IsRw, &X), Show2(", ", &X), WriteEffAddr(DispN, &X);
}

void CheckSBit(ListItem LP, word *XP) { // LP: the command prototype, *XP: the line column to write to.
   if (IsRw == 0) WriteFreeOperand(1, XP);
   else if (LP->_s == 2 || !(OpCode&2)) WriteFreeOperand(2, XP);
// Expanded according to the expansion rule.
   else Show1("0", XP), ShowWordHex(ReadInt(), XP), Show1("h", XP);
}

void CheckMod2(ListItem LP) { // LP: the command prototype.
   CheckRv(LP);
   DispN = (ModByte >> 6)&3;
   word X = 30;
   if (DispN == 3) { // r/m(reg) <- (bop) // _d = 0.
      WriteReg(ModByte&7 | IsRw, &X);
      if (LP->_s != 0) Show2(", ", &X), CheckSBit(LP, &X);
   } else { // r/m <- (bop) // _d = 0.
      switch (IsRw) {
         case 000: Show2("b.", &X); break;
         case 010: Show2("w.", &X); break;
         case 020: Show3("dw.", &X); break;
      }
      WriteEffAddr(DispN, &X);
      if (LP->_s != 0) Show2(", ", &X), CheckSBit(LP, &X);
   }
}

void CheckOpCode(void) {
// Format:
// Addr: hh hh hh hh hh hh Mnem  Arg, Arg...
// 01234567890123456789012345678901234567890
// 0.........1.........2.........3.........4
   WriteAddress();
   ListItem LP = ListTab;
   while (1) {
      if ((OpCode&LP->_Mask) == LP->_Bytes) {
         if (LP->_xrm == 0) break;
         ModByte = ReadByte();
         if (LP->_xrm == 2) {
            byte DL = (ModByte >> 3)&7;
            for (; LP->_xcm != DL; LP++);
         }
         break;
      }
      if (++LP > ListEnd) return;
   }
   word X = 30;
   WriteCommand(LP->_Op);
   if ((OpCode&0xf0) == 0x70) {
   // Conditional Jumps.
      WriteJcc(OpCode&0xf);
      WriteJumpDisp(1, &X);
      return;
   } else if (LP->_Reg == 0200) {
   // Command with no register.
      byte Disp = LP->_PB;
      if (Disp < 0x10) // Free Operand.
         WriteFreeOperand(Disp, &X);
      else // Displacement.
         WriteJumpDisp((Disp >> 4)&0xf, &X);
      return;
   }
   IsRs = false;
   if (LP->_Reg == 0030) {
   // Has a segment register here.
      IsRs = true;
      if (LP->_xrm != 1) { // Defer adding the segment to MOD.
      // Segment override versus segment register operand.
         if (LP->_Op == 29) X = 24; WriteSegReg((OpCode >> 3)&3, &X);
         return;
      }
   }
   if (LP->_Reg == 0040) {
      CheckRv(LP);
      if (LP->_d == 1 && (OpCode&2)) // Normal order.
         WriteDirectAddress(&X), Show2(", ", &X), WriteReg(OpCode&LP->_Reg&0xf | IsRw, &X);
      else // Reverse order.
         WriteReg(OpCode&LP->_Reg&0xf | IsRw, &X), Show2(", ", &X), WriteDirectAddress(&X);
   } else if (LP->_xrm == 0) {
   // No MOD here.
   // Word or byte.
      switch (LP->_w) {
         default: if ((OpCode&LP->_Reg) > 7) goto Mode3; else goto Mode2;
         case 1: if ((OpCode&1) == 1) goto Mode3; else goto Mode2;
         case 2: Mode2:
            WriteReg(OpCode&LP->_Reg, &X);
            if (LP->_PB == 1) // Has one free operand.
               Show3(", 0", &X), ShowByteHex(ReadByte(), &X), Show1("h", &X);
         break;
         case 3: Mode3:
            WriteReg(OpCode&LP->_Reg | 010, &X);
            if (LP->_PB == 1) // Has two free operands.
               Show3(", 0", &X), ShowWordHex(ReadWord(), &X), Show1("h", &X);
         break;
      }
   } else
   // Has MOD here.
      if (LP->_xrm == 2)
         CheckMod2(LP);
      else
         CheckMod(LP);
}

int main(int AC, char *AV[]) {
   char *App = AC < 1? NULL: AV[0]; if (App == NULL || *App == '\0') App = "DisAsm86";
   if (AC < 3) {
   // puts("\r\nInvalid arguments\r\n"); // Originally used individually on each of the command-line parameters.
      printf(
         "%s: Originally by Justas Glodenis\r\n"
         "Arguments to use in order:\r\n"
         "* InFile: the file to disassemble,\r\n"
         "* ExFile: the disassembly output.\r\n"
         "Example: `DisAsm86 Test.bin Test.s`\r\n",
         App
      );
      return EXIT_FAILURE;
   }
// Read the names of the two files.
   char *InFile = AV[1];
   char *ExFile = AV[2];
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   FILE *InF = fopen(InFile, "rb"); if (InF == NULL) { printf("\r\nNo file opened: %s\r\n", InFile); return EXIT_FAILURE; }
// Read data from a file.
   word InN = fread(InBuf, 1, sizeof InBuf, InF);
   fclose(InF);
// Perform the calculations.
   FILE *ExF = fopen(ExFile, "wb"); if (ExF == NULL) { printf("\r\nNo file created: %s\r\n", ExFile); return EXIT_FAILURE; }
   for (; CurIP < InN; CurIP++) {
      OpCode = InBuf[CurIP];
   // Clear the output buffer and pad an end-of-line marker '\n'.
      memset(ExBuf, ' ', sizeof ExBuf - 1), ExBuf[sizeof ExBuf - 1] = '\n';
      CheckOpCode();
      fwrite(ExBuf, 1, sizeof ExBuf, ExF);
   }
   fclose(ExF);
// Report the files written.
   puts("\r\nFile written successfully.\r\n");
   return EXIT_SUCCESS;
}

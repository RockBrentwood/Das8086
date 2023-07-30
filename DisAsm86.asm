model small
.stack 100h
.data

BaseIP			dw 100h
Ok			db 13, 10
			db "File written successfully.", 13, 10
			db '$'
NoFileOpened		db 13, 10
			db "No file opened: "
			db '$'
NoFileCreated		db 13, 10
			db "No file created: "
			db '$'
Eol			db 13, 10
			db '$'
InvalidArguments	db 13, 10
			db "Invalid arguments", 13, 10
			db '$'
Banner			db 13, 10
			db "Originally by Justas Glodenis", 13, 10
			db "Arguments to use in order:", 13, 10
			db "* InFile: the file to disassemble,", 13, 10
			db "* ExFile: the disassembly output.", 13, 10
			db "Example: `DisAsm86 Test.bin Test.s`"
			db '$'
InFile		db 20 dup(0), '$'
ExFile		db 20 dup(0)
InBuf		db 0ffh dup(0)
ExBuf		db 60 dup(' '), '$'
InFD		dw 0
ExFD		dw 0
InN		dw 0
IsRw		db 0
IsRs		db 0
DispN		db 0
OpCode		db 0
ModByte		db 0
ByteP		dw 9
CurIP		dw 0

;; struct ListItem {
_Bytes	equ 0
_Mask	equ 1
_xrm	equ 2
_d	equ 3
_w	equ 4
_s	equ 5
_xcm	equ 6
_Op	equ 7
_Reg	equ 8
_PB	equ 9
;; };

;;         0     1     2  3  4  5  6   7    8     9
;;     OpBytes OpMask xrm d  w  s xcm  Op  Reg  P/B Op
;; All of the 00 aaa 0dw xrm should be combined: AOp (add,or,adc,sbb,and,sub,xor,cmp), (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;; All of the 00 aaa 10w should be combined: AOp (add,or,adc,sbb,and,sub,xor,cmp), (AL,Ib; AX,Iw)
ListTab	db 000q, 374q, 1, 1, 1, 0, 0q, 07, 000q, 00	;; 00 000 0dw xrm: add (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 010q, 374q, 1, 1, 1, 0, 0q, 08, 000q, 00	;; 00 001 0dw xrm: or (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 020q, 374q, 1, 1, 1, 0, 0q, 09, 000q, 00	;; 00 010 0dw xrm: adc (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 030q, 374q, 1, 1, 1, 0, 0q, 10, 000q, 00	;; 00 011 0dw xrm: sbb (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 040q, 374q, 1, 1, 1, 0, 0q, 11, 000q, 00	;; 00 100 0dw xrm: and (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 050q, 374q, 1, 1, 1, 0, 0q, 12, 000q, 00	;; 00 101 0dw xrm: sub (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 060q, 374q, 1, 1, 1, 0, 0q, 13, 000q, 00	;; 00 110 0dw xrm: xor (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 070q, 374q, 1, 1, 1, 0, 0q, 14, 000q, 00	;; 00 111 0dw xrm: cmp (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 004q, 376q, 0, 0, 1, 0, 0q, 07, 000q, 01	;; 00 000 10w: add (AL,Ib; AX,Iw)
	db 014q, 376q, 0, 0, 1, 0, 0q, 08, 000q, 01	;; 00 001 10w: or (AL,Ib; AX,Iw)
	db 024q, 376q, 0, 0, 1, 0, 0q, 09, 000q, 01	;; 00 010 10w: adc (AL,Ib; AX,Iw)
	db 034q, 376q, 0, 0, 1, 0, 0q, 10, 000q, 01	;; 00 011 10w: sbb (AL,Ib; AX,Iw)
	db 044q, 376q, 0, 0, 1, 0, 0q, 11, 000q, 01	;; 00 100 10w: and (AL,Ib; AX,Iw)
	db 054q, 376q, 0, 0, 1, 0, 0q, 12, 000q, 01	;; 00 101 10w: sub (AL,Ib; AX,Iw)
	db 064q, 376q, 0, 0, 1, 0, 0q, 13, 000q, 01	;; 00 110 10w: xor (AL,Ib; AX,Iw)
	db 074q, 376q, 0, 0, 1, 0, 0q, 14, 000q, 01	;; 00 111 10w: cmp (AL,Ib; AX,Iw)
	db 006q, 347q, 0, 0, 0, 0, 0q, 05, 030q, 00	;; 00 0rr 110: push Rs (ES,CS,SS,DS)
	db 046q, 347q, 0, 0, 0, 0, 0q, 29, 030q, 00	;; 00 1rr 110: Rs: (ES,CS,SS,DS)
	db 007q, 347q, 0, 0, 0, 0, 0q, 06, 030q, 00	;; 00 0rr 111: pop Rs (ES,CS,SS,DS) CS is excluded on 80186+
;;	db 047q, 347q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 00 1bb 111: BOp (daa,das,aaa,aas)
	db 100q, 370q, 0, 0, 3, 0, 0q, 03, 007q, 00	;; 01 000 rrr: inc Rw (AX,CX,DX,BX,SP,BP,SI,DI)
	db 110q, 370q, 0, 0, 3, 0, 0q, 04, 007q, 00	;; 01 001 rrr: dec Rw (AX,CX,DX,BX,SP,BP,SI,DI)
	db 120q, 370q, 0, 0, 3, 0, 0q, 05, 007q, 00	;; 01 010 rrr: push Rw (AX,CX,DX,BX,SP,BP,SI,DI)
	db 130q, 370q, 0, 0, 3, 0, 0q, 06, 007q, 00	;; 01 011 rrr: pop Rw (AX,CX,DX,BX,SP,BP,SI,DI)
;;	db 140q, 377q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 01 100 000: pusha [80186+]
;;	db 141q, 377q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 01 100 001: popa [80186+]
;;	db 142q, 377q, 1, 0, 3, 0, 0q, __, 000q, 00	;; 01 100 010 xrm: bound Rw,Ew [80186+]
;;	db 150q, 375q, 0, 0, 0, 1, 0q, 05, 200q, 02	;; 01 101 0s0: push (Iw; Is) [80186+]
;;	db 151q, 375q, 1, 0, 0, 1, 0q, 18, 000q, 02	;; 01 101 0s0 xrm: imul (Rw,Ew,Iw; Rw,Ew,Is) [80186+]
;;	db 154q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 01 101 10w: (insb,insw) [80186+]
;;	db 156q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 01 101 11w: (outsb,outsw) [80186+]
	db 070h, 0f0h, 0, 0, 0, 0, 0q, 30, 200q, 10h	;; 0111 cccc: jCC Jb (o,no,b,nb,e,ne,na,a,s,ns,p,np,l,ge,le,g)
;; All of the 10 000 0sw /A should be combined using AOp like this:
;;	db 200q, 374q, 2, 0, 1, 1, 0q, __, 000q, 00	;; 10 000 0sw xAm: AOp (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 0q, 07, 000q, 00	;; 10 000 0sw x0m: add (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 1q, 08, 000q, 00	;; 10 000 0sw x1m: or (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 2q, 09, 000q, 00	;; 10 000 0sw x2m: adc (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 3q, 10, 000q, 00	;; 10 000 0sw x3m: sbb (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 4q, 11, 000q, 00	;; 10 000 0sw x4m: and (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 5q, 12, 000q, 00	;; 10 000 0sw x5m: sub (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 6q, 13, 000q, 00	;; 10 000 0sw x6m: xor (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 200q, 374q, 2, 0, 1, 1, 7q, 14, 000q, 00	;; 10 000 0sw x7m: cmp (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 204q, 376q, 1, 0, 1, 2, 0q, 02, 000q, 00	;; 10 000 10w: test (Eb,Ib; Ew,Iw)
	db 206q, 376q, 1, 0, 1, 2, 0q, 01, 000q, 00	;; 10 000 11w: xchg (Eb,Ib; Ew,Iw)
	db 210q, 374q, 1, 1, 1, 0, 0q, 00, 000q, 00	;; 10 001 0dw xrm: mov (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 214q, 375q, 1, 1, 3, 0, 0q, 00, 030q, 00	;; 10 001 100 xrm: mov Ew,Rs
;;	db 215q, 377q, 1, 0, 3, 0, 0q, __, 000q, 00	;; 10 001 101 xrm: lea Ew (r != 3)
	db 217q, 377q, 2, 0, 3, 0, 0q, 06, 000q, 00	;; 10 001 111 x0m: pop Ew
;;	db 220q, 370q, 0, 0, 0, 0, 0q, 01, 007q, 00	;; 10 010 rrr: xchg AX, Rw (note: xchg AX, AX = nop)
;;	db 230q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 10 011 00w: COp (cbw,cwd)
	db 232q, 377q, 0, 0, 0, 0, 0q, 21, 200q, 04	;; 10 011 010: call Af
;;	db 233q, 377q, 0, 0, 0, 0, 0q, __, 000q, 00	;; 10 011 011: wait
;;	db 234q, 374q, 0, 0, 0, 0, 0q, __, 000q, 00	;; 10 011 1ff: FOp (pushf, popf, sahf, lahf)
	db 240q, 374q, 0, 1, 1, 0, 0q, 00, 040q, 00	;; 10 100 0dw: mov (AL,Mb; AX,Mw; Mb,AL; Mw,AL)
;;	db 244q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 10 100 10w: (movsb,movsw)
;;	db 246q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 10 100 11w: (cmpsb,cmpsw)
	db 250q, 376q, 0, 0, 1, 0, 0q, 02, 000q, 01	;; 10 101 00w: test (AL,Ib; AX,Iw)
;;	db 252q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 10 101 01w: (stosb,stosw)
;;	db 254q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 10 101 10w: (lodsb,lodsw)
;;	db 256q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 10 101 11w: (scasb,scasw)
	db 260q, 360q, 0, 0, 0, 0, 0q, 00, 017q, 01	;; 10 11w rrr: mov (Rb,Ib; Rw,Iw)
;;	db 300q, 376q, 2, 0, 1, 0, __, __, 000q, 00	;; 11 000 00w xAm: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,Ib; Ew,Iw) [80186+]
	db 302q, 377q, 0, 0, 0, 0, 0q, 24, 200q, 02	;; 11 000 010: ret Iw
	db 303q, 377q, 0, 0, 0, 0, 0q, 24, 200q, 00	;; 11 000 011: ret
;;	db 304q, 377q, 1, 0, 3, 0, 0q, __, 000q, 00	;; 11 000 100 xrm: les Rw,Ew
;;	db 305q, 377q, 1, 0, 3, 0, 0q, __, 000q, 00	;; 11 000 101 xrm: lds Rw,Ew
	db 306q, 376q, 2, 0, 1, 2, 0q, 00, 000q, 00	;; 11 000 11w x0m: mov (Eb,Ib; Ew,Iw)
;;	db 310q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 001 000: enter [80186+]
;;	db 311q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 001 001: leave [80186+]
	db 312q, 377q, 0, 0, 0, 0, 0q, 25, 200q, 02	;; 11 001 010: retf Iw
	db 313q, 377q, 0, 0, 0, 0, 0q, 25, 200q, 00	;; 11 001 011: retf
;;	db 314q, 377q, 0, 0, 0, 0, 0q, 23, 200q, 00	;; 11 001 100: int 3
	db 315q, 377q, 0, 0, 0, 0, 0q, 23, 200q, 01	;; 11 001 101: int Ib
;;	db 316q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 001 110: into
	db 317q, 377q, 0, 0, 0, 0, 0q, 26, 200q, 00	;; 11 001 111: iret
;;	db 320q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 11 010 00w: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,Ib; Ew,Iw)
;;	db 322q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 11 010 01w: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,CL; Ew,CL)
;;	db 324q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 010 100: aam
;;	db 325q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 010 101: aad
;;	db 326q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 010 110: salc [excluded on 80186+]
;;	db 327q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 010 111: xlat
;;	db 330q, 370q, 1, 0, 0, 0, 0q, __, 007q, 00	;; 11 011 ppp xrm: esc p Eb
;;	db 340q, 377q, 0, 0, 0, 0, 0q, __, 200q, 10h	;; 11 100 000: loopne Jb
;;	db 341q, 377q, 0, 0, 0, 0, 0q, __, 200q, 10h	;; 11 100 001: loope Jb
	db 342q, 377q, 0, 0, 0, 0, 0q, 27, 200q, 10h	;; 11 100 010: loop Jb
	db 343q, 377q, 0, 0, 0, 0, 0q, 28, 200q, 10h	;; 11 100 011: jcxz Jb
;;	db 344q, 376q, 0, 0, 1, 0, 0q, __, 000q, 01	;; 11 100 10w: in (AL,Ib; AX,Ib)
;;	db 346q, 376q, 0, 0, 1, 0, 0q, __, 000q, 01	;; 11 100 11w: out (Ib,AL; Ib,AX)
	db 350q, 377q, 0, 0, 0, 0, 0q, 21, 200q, 20h	;; 11 101 000: call An
	db 351q, 377q, 0, 0, 0, 0, 0q, 22, 200q, 20h	;; 11 101 001: jmp An
	db 352q, 377q, 0, 0, 0, 0, 0q, 22, 200q, 04	;; 11 101 010: jmp Af
	db 353q, 377q, 0, 0, 0, 0, 0q, 22, 200q, 10h	;; 11 101 011: jmp Jb
;;	db 354q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 11 101 10w: in (AL,DX; AX,DX)
;;	db 356q, 376q, 0, 0, 1, 0, 0q, __, 000q, 00	;; 11 101 11w: out (DX,AL; DX,AX)
;;	db 360q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 110 000: lock
;;	db 362q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 110 010: repne
;;	db 363q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 110 011: rep
;;	db 364q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 110 100: hlt
;;	db 365q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 110 101: cmc
;;	db 366q, 376q, 2, 0, 1, 0, 0q, __, 000q, 01	;; 11 110 11w x0m: test (Eb,Ib; Ew,Iw)
	db 366q, 376q, 2, 0, 1, 0, 2q, 15, 000q, 00	;; 11 110 11w x2m: neg (Eb; Ew)
	db 366q, 376q, 2, 0, 1, 0, 3q, 16, 000q, 00	;; 11 110 11w x3m: not (Eb; Ew)
	db 366q, 376q, 2, 0, 1, 0, 4q, 17, 000q, 00	;; 11 110 11w x4m: mul (Eb; Ew)
	db 366q, 376q, 2, 0, 1, 0, 5q, 18, 000q, 00	;; 11 110 11w x5m: imul (Eb; Ew)
	db 366q, 376q, 2, 0, 1, 0, 6q, 19, 000q, 00	;; 11 110 11w x6m: div (Eb; Ew)
	db 366q, 376q, 2, 0, 1, 0, 7q, 20, 000q, 00	;; 11 110 11w x7m: idiv (Eb; Ew)
;;	db 370q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 111 000: clc
;;	db 371q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 111 001: stc
;;	db 372q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 111 010: cli
;;	db 373q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 111 011: sti
;;	db 374q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 111 100: cld
;;	db 375q, 377q, 0, 0, 0, 0, 0q, __, 200q, 00	;; 11 111 101: std
	db 376q, 376q, 2, 0, 1, 0, 0q, 03, 000q, 00	;; 11 111 11w x0m: inc (Eb; Ew)
	db 376q, 376q, 2, 0, 1, 0, 1q, 04, 000q, 00	;; 11 111 11w x1m: dec (Eb; Ew)
	db 377q, 377q, 2, 0, 3, 0, 2q, 21, 000q, 00	;; 11 111 111 x2m: call near En
	db 377q, 377q, 2, 0, 4, 0, 3q, 21, 000q, 00	;; 11 111 111 x3m: call far Ef
	db 377q, 377q, 2, 0, 2, 0, 4q, 22, 000q, 00	;; 11 111 111 x4m: jmp near En
	db 377q, 377q, 2, 0, 3, 0, 5q, 22, 000q, 00	;; 11 111 111 x5m: jmp far Ef
ListEnd	db 377q, 377q, 2, 0, 3, 0, 6q, 05, 000q, 00	;; 11 111 111 x6m: push Ew

.code
_main:
   mov AX, @data
   mov DS, AX
   mov BX, 81h ;; The address of the first character of the parameter.
   cmp byte ptr ES:[BX], 13
   je _00f
      mov DL, ES:[BX+1]
      cmp DL, 13
   je _00f
      cmp DL, '/'
      jne _01f
      mov DL, ES:[BX+2]
      cmp DL, '?'
      jne WrongParams
   _00f:
   jmp WriteInfo
_01f:
;; Read the names of the two files.
   inc BX
   mov DI, offset InFile
   call ReadFileName
   jc WrongParams
   inc BX
   mov DI, offset ExFile
   call ReadFileName
   jc WrongParams
;; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;; Read data from a file.
   mov DX, offset InFile
   mov CX, offset InBuf
   call OpenInFile
   jc NoInFile
;; Perform the calculations.
   mov BX, CurIP
   call OpenExFile
   jc NoExFile
   _0b:
      mov BX, CurIP
      cmp BX, InN
      jge _02f
      mov SI, offset InBuf
      mov DL, [SI+BX]
      mov OpCode, DL
   ;; Clear the output buffer and pad an end-of-line marker '\n'.
      mov DI, offset ExBuf
      push BX
      mov BX, 0
      _1b:
         mov byte ptr [DI+BX], ' '
         inc BX
         cmp BX, 60
      jl _1b
      mov byte ptr [DI+BX], 10
      pop BX
      call CheckOpCode
      call WriteLine
      inc CurIP
      inc BX
   jmp _0b
_02f:
   call CloseExFile
;; Report the files written.
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset Ok
   mov AH, 09h
   int 21h
;; exit(EXIT_SUCCESS);
   mov AX, 4c00h
   int 21h
WrongParams:
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset InvalidArguments
   mov AH, 09h
   int 21h
jmp Exit0
WriteInfo:
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset Banner
   mov AH, 09h
   int 21h
jmp Exit0
NoInFile:
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset NoFileOpened
   mov AH, 09h
   int 21h
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset InFile
   mov AH, 09h
   int 21h
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset Eol
   mov AH, 09h
   int 21h
   jmp Exit0
NoExFile:
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset NoFileCreated
   mov AH, 09h
   int 21h
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset ExFile
   mov AH, 09h
   int 21h
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset Eol
   mov AH, 09h
   int 21h
Exit0:
;; exit(EXIT_FAILURE);
   mov AX, 4c01h
   int 21h

ReadFileName proc ;; ES:BX: Location on the command line to read from, DS:DI: The file name buffer to read to.
   mov DX, 0
   _2b:
      mov AL, ES:BX
      cmp AL, ' '
      je _03f
      cmp AL, 0
      je _03f
      cmp AL, 13
      je _03f
      push BX
      mov BX, DX
      mov [DI+BX], AL
      pop BX
      inc BX
      inc DX
   jmp _2b
_03f:
   cmp DX, 1
   jle _04f
      clc
   jmp _05f
   _04f:
      stc
   _05f:
ret
ReadFileName endp

OpenInFile proc
;; File Read Open. Access/Sharing Mode, CL: Attribute Mask => (CF, AX): (1, Error Code) or (0, File Handle).
   mov DX, offset InFile
   mov AH, 3dh
   mov AL, 02h
   int 21h
   mov InFD, AX
   jnc _06f
      stc
   jmp _07f
   _06f:
      mov BX, InFD ;; File Handle
      mov DX, offset InBuf
      mov CX, 0ffh
   ;; File Read. BX: File Handle, DS:DX: Buffer, CX: Size => (CF, AX) = (1, Error Code) or (0, Bytes Read).
      mov AH, 3fh
      int 21h
      mov InN, AX
   ;; File Close. BX: File Handle => (CF, AX) = (1, Error Code) or (0, *).
      mov AH, 3eh
      int 21h
      clc
   _07f:
ret
OpenInFile endp

OpenExFile proc
   push AX
   mov CX, 40h
   mov DX, offset ExFile
;; File Write Open. DS:DX: File Name, CX: File Attributes => (CF, AX) = (1, Error Code) or (0, File Handle).
   mov AH, 3ch
   int 21h
   mov ExFD, AX
   pop AX
ret
OpenExFile endp

WriteLine proc
   push BX
   mov BX, ExFD
   mov DX, offset ExBuf
   mov CX, 61
;; File Write. BX: File Handle, DS:DX: Buffer, CX: Bytes => (CF, AX) = (1, Error Code) or (0, Bytes Written).
   mov AH, 40h
   int 21h
   pop BX
ret
WriteLine endp

CloseExFile proc
   push BX AX
   mov BX, ExFD
;; File Close. BX: File Handle => (CF, AX) = (1, Error Code) or (0, *).
   mov AH, 3eh
   int 21h
   pop AX BX
ret
CloseExFile endp

ShowS1 macro S1
   mov byte ptr [DI+BX], S1
   inc BX
endm

ShowS2 macro S2
   mov [DI+BX], ((S2 and 0ffh) shl 8) or ((S2 and 0ff00h) shr 8)
   add BX, 2
endm

ShowS3 macro S2, S1
   ShowS2 S2
   ShowS1 S1
endm

;; Output 2 characters to the buffer.
Show2 macro S2
   mov [DI+BX], S2
   add BX, 2
endm

ShowByteHex macro
   ShowS1 "0"
   call ReadByte
   Show2 AX
   ShowS1 "h"
endm

ShowWordHex macro
   ShowS1 "0"
   call ReadByte
   push AX
   call ReadByte
   Show2 AX
   pop AX
   Show2 AX
   ShowS1 "h"
endm

CheckOpCode proc
;; Format:
;; Addr: hh hh hh hh hh hh Mnem  Arg, Arg...
;; 01234567890123456789012345678901234567890
;; 0.........1.........2.........3.........4
   call WriteAddress
   mov SI, offset ListTab
   _3b:
      mov DL, OpCode
      and DL, [SI+_Mask]
      cmp DL, [SI+_Bytes]
      jne _08f
         cmp byte ptr [SI+_xrm], 0
         je _09f
         call ReadByte
         mov ModByte, DL
         cmp byte ptr [SI+_xrm], 2
         jne _09f
         shr DL, 3
         and DL, 7
         _4b:
            cmp [SI+_xcm], DL
            je _09f
            add SI, 10
         jmp _4b
      _08f:
      add SI, 10
      mov AX, offset ListEnd
      cmp SI, AX
   jle _3b
jmp Exit1
_09f:
   mov BL, [SI+_Op]
   call WriteCommand
   mov DL, OpCode
   and DL, 0f0h
   cmp DL, 70h
   jne _0af
   ;; Conditional Jumps.
      mov BL, OpCode
      and BL, 0fh
      call WriteJcc
      mov DispN, 1
      mov BX, 30
      call WriteJumpDisp
   jmp Exit1
   _0af:
   mov AL, [SI+_Reg]
   cmp AL, 200q
   jne _0df
   ;; Command with no register.
      mov AL, [SI+_PB]
      cmp AL, 10h
      jge _0bf
      ;; Free Operand.
         mov DispN, AL
         mov BX, 30
         call WriteFreeOperand
      jmp _0cf
      _0bf:
      ;; Displacement.
         shr AL, 4
         and AL, 0fh
         mov DispN, AL
         mov BX, 30
         call WriteJumpDisp
      _0cf:
   jmp Exit1
   _0df:
   mov IsRs, 0
   mov AL, [SI+_Reg]
   cmp AL, 030q
   jne _10f
   ;; Has a segment register here.
      mov IsRs, 1
      mov AL, [SI+_xrm]
      cmp AL, 1	;; Defer adding the segment ...
   je _10f	;; ... to MOD.
      mov AL, [SI+_Op]
      cmp AL, 29
      jne _0ef
      ;; Segment override.
         mov BX, 24
      jmp _0ff
      _0ef:
      ;; Ordinary command with a segment register.
         mov BX, 30
      _0ff:
      mov AL, OpCode
      call WriteSegReg
      jmp Exit1
   _10f:
   mov AL, [SI+_Reg]
   cmp AL, 040q
   jne _13f
      call CheckRv
      mov AL, [SI+_d]
      cmp AL, 1
      jne _11f
         mov DL, OpCode
         and DL, 2
         cmp DL, 0
      je _11f
      ;; Normal order.
         mov BX, 30
         call WriteDirectAddress
         ShowS2 ", "
         mov AL, OpCode
         and AL, [SI+_Reg]
         and AL, 0fh
         or AL, IsRw
         call WriteReg
      jmp _12f
      _11f:
      ;; Reverse order.
         mov BX, 32
         ShowS2 ", "
         call WriteDirectAddress
         mov AL, OpCode
         and AL, [SI+_Reg]
         and AL, 0fh
         or AL, IsRw
         push BX
         mov BX, 30
         call WriteReg
         pop BX
      _12f:
   jmp Exit1
   _13f:
   mov AL, [SI+_xrm]
   cmp AL, 0
   je _14f
      jmp HasMod
   _14f:
;; No MOD here.
;; Word or byte.
   mov AL, [SI+_w]
   cmp AL, 2
   je _16f
   cmp AL, 3
   je _17f
   cmp AL, 1
   jne _15f
      mov DL, OpCode
      and DL, 1
      cmp DL, 1
      je _17f
   jmp _16f
   _15f:
      mov DL, OpCode
      and DL, [SI+_Reg]
      cmp DL, 7
      jg _17f
   _16f:
      mov AL, OpCode
      and AL, [SI+_Reg]
      mov BX, 30
      call WriteReg
      mov AL, [SI+_PB]
      cmp AL, 1
      jne _18f
      ;; Has one free operand.
         ShowS2 ", "
         ShowByteHex
   jmp _18f
   _17f:
      mov AL, OpCode
      and AL, [SI+_Reg]
      or AL, 010q
      mov BX, 30
      call WriteReg
      mov AL, [SI+_PB]
      cmp AL, 1
      jne _18f
      ;; Has two free operands.
         ShowS2 ", "
         ShowWordHex
   _18f:
jmp Exit1
HasMod:
;; Has MOD here.
   cmp byte ptr [SI+_xrm], 2
   jne _19f
      call CheckMod2
   jmp Exit1
   _19f:
      call CheckMod
Exit1:
ret
CheckOpCode endp

.data
Hex db 10h
.code
ByteToHex proc ;; AL: The byte value to convert to hex.
   mov AH, 0
   div Hex
   cmp AL, 10
   jge _1af
      add AL, '0'
   jmp _1bf
   _1af:
      add AL, 'A'-10
   _1bf:
   cmp AH, 10
   jge _1cf
      add AH, '0'
   jmp _1df
   _1cf:
      add AH, 'A'-10
   _1df:
ret
ByteToHex endp

WriteAddress proc ;; BaseIP+CurIP: The (relocated) address
   push BX
   mov BX, CurIP
   add BX, BaseIP
   mov AL, BH
   call ByteToHex
   mov [DI+0], AX
   mov AL, BL
   call ByteToHex
   mov [DI+2], AX
   mov byte ptr [DI+4], ':'
   mov AL, OpCode
   call ByteToHex
   mov [DI+6], AX
   pop BX
   mov ByteP, 9
ret
WriteAddress endp

.data
;;          0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30
Command db "MOV XCHGTESTINC DEC PUSHPOP ADD OR  ADC SBB AND SUB XOR CMP NEG NOT MUL IMULDIV IDIVCALLJMP INT RET RETFIRETLOOPJCXZ  :     "
.code
WriteCommand proc ;; BL: Operator number.
   push SI
   mov SI, offset Command
   mov BH, 0
   shl BX, 2
   mov AX, [SI+BX]
   mov [DI+24], AX
   add BX, 2
   mov AX, [SI+BX]
   mov [DI+26], AX
   pop SI
ret
WriteCommand endp

.data
;;          0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16
Jcc     db "JO  JNO JB  JNB JE  JNE JNA JA  JS  JNS JP  JNP JL  JGE JLE JG  "
.code
WriteJcc proc ;; BL: Operator number.
   push SI
   mov SI, offset Jcc
   mov BH, 0
   shl BX, 2
   mov AX, [SI+BX]
   mov [DI+24], AX
   add BX, 2
   mov AX, [SI+BX]
   mov [DI+26], AX
   pop SI
ret
WriteJcc endp

.data
;;          0 1 2 3 4 5 6 7 8 9 101112131415
RegName db "ALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI"
.code
WriteReg proc ;; AL: Register number or Shifted ModByte, &BX: the line column to write to (updated).
   cmp IsRs, 1
   je _1ef
      push SI
      mov SI, offset RegName
      xchg AX, BX
      mov BH, 0
      shl BX, 1
      mov BX, [SI+BX]
      xchg AX, BX
      Show2 AX
      pop SI
   jmp _1ff
   _1ef:
      mov AL, ModByte
      call WriteSegReg
   _1ff:
ret
WriteReg endp

.data
;;          0 1 2 3
SegName db "ESCSSSDS"
.code
WriteSegReg proc ;; AL: ComByte, &BX: the line column to write to (updated).
   push SI
   mov SI, offset SegName
   xchg AX, BX
   mov BH, 0
   and BL, 030q
   shr BX, 2
   mov BX, [SI+BX]
   xchg AX, BX
   Show2 AX
   mov IsRs, 0
   pop SI
ret
WriteSegReg endp

.data
;;             0       1       2       3       4       5       6       7
RegMode db "[BX+SI] [BX+DI] [BP+SI] [BP+DI] [SI]    [DI]    [BP]    [BX]    "
.code
WriteEffAddr proc ;; DispN: the number of displacement bytes, &BX: the line column to write to (updated).
;; Write Register/Memory Address.
   push AX
   mov AX, BX
   push BX
   mov BL, ModByte
   and BL, 307q
   cmp BL, 006q ;; Direct address, MOD = 00, r/m = 110
   je _21f
      mov BH, 0
      mov BL, ModByte
      and BL, 7
      shl BX, 3
      push SI
      push DI
      mov SI, offset RegMode
      add DI, AX
      mov AX, [SI+BX]
      mov [DI], AX
      mov AX, [SI+BX+2]
      mov [DI+2], AX
      mov AX, [SI+BX+4]
      mov [DI+4], AX
      mov AX, [SI+BX+6]
      mov [DI+6], AX
      pop DI
      pop SI
      pop BX
      mov DL, ModByte
      and DL, 7
      cmp DL, 4
      jge _20f
      ;; Less than 4.
         add BX, 7
      jmp _22f
      _20f:
         add BX, 4
      jmp _22f
   _21f:
      pop BX
      call WriteDirectAddress
   _22f:
;; Write Displacement.
   push CX
   mov CL, DispN
   cmp CL, 0
   je Exit2
;; There is a displacement.
   ShowS3 " +"," "
   cmp CL, 1
   jne _23f
   ;; One-byte offset.
      ShowByteHex
   jmp Exit2
   _23f:
   ;; Two-byte offset.
      ShowWordHex
Exit2:
   pop CX AX
ret
WriteEffAddr endp

WriteDirectAddress proc ;; &BX: the line column to write to (updated).
   ShowS1 "["
   ShowWordHex
   ShowS1 "]"
ret
WriteDirectAddress endp

WriteFreeOperand proc ;; DispN: the number of bytes, &BX: the line column to write to (updated).
   push CX
   mov CL, DispN
   cmp CL, 0
   je Exit3
;; There are operands.
   cmp CL, 1
   jg _24f
   ;; One-byte operand.
      ShowByteHex
   jmp Exit3
   _24f:
   cmp CL, 2
   jg _25f
   ;; Two-byte operand.
      ShowWordHex
   jmp Exit3
   _25f:
   ;; Four-byte operand: far address.
      push BX
      add BX, 7
      ShowWordHex
      pop AX
      xchg AX, BX
      ShowWordHex
      ShowS1 ":"
      xchg AX, BX
Exit3:
   pop CX
ret
WriteFreeOperand endp

WriteJumpDisp proc ;; DispN: the number of displacement bytes, &BX: the line column to write to (updated).
   push CX
   cmp DispN, 1
   jne _26f
   ;; One-byte jump displacement.
      call ReadInt
   jmp _27f
   _26f:
   ;; Two-byte jump displacement.
      call ReadWord
   _27f:
   mov CX, CurIP
   inc CX
   add CX, BaseIP
   add CX, DX
   mov AL, CH
   call ByteToHex
   Show2 AX
   mov AL, CL
   call ByteToHex
   Show2 AX
   ShowS1 "h"
   pop CX
ret
WriteJumpDisp endp

ReadByte proc ;; CurIP: the last command IP, &ByteP: the line column to write to (updated) => AX: the byte in hex, DL: the byte.
   push SI
   mov SI, offset InBuf
   xchg BX, CurIP
   inc BX
   mov DL, [SI+BX]
   xchg BX, CurIP
   xchg BX, ByteP
   mov AL, DL
   call ByteToHex
   Show2 AX
   ShowS1 " "
   xchg BX, ByteP
   pop SI
ret
ReadByte endp

ReadInt proc ;; CurIP: the last command IP, &ByteP: the line column to write to (updated) => DX: the byte, sign-extended to word-size.
   call ReadByte
   xchg AX, DX
   cbw
   xchg AX, DX
ret
ReadInt endp

ReadWord proc ;; CurIP: the last command IP, &ByteP: the line column to write to (updated) => DX; the word
   push SI
   mov SI, offset InBuf
   xchg BX, CurIP
   inc BX
   mov DL, [SI+BX]
   inc BX
   mov DH, [SI+BX]
   xchg BX, CurIP
   xchg BX, ByteP
   mov AL, DL
   call ByteToHex
   Show2 AX
   ShowS1 " "
   mov AL, DH
   call ByteToHex
   Show2 AX
   ShowS1 " "
   xchg BX, ByteP
   pop SI
ret
ReadWord endp

CheckRv proc ;; SI: the command prototype
   push AX
   mov IsRw, 000q
   mov AL, [SI+_w]
   cmp AL, 1
   jne _28f
      mov AH, OpCode
      and AH, 1
      cmp AH, 1
      jne Exit4
         mov IsRw, 010q
   jmp Exit4
   _28f:
   cmp AL, 3
   jne _29f
      mov IsRw, 010q
   jmp Exit4
   _29f:
   cmp AL, 4
   jne Exit4
      mov IsRw, 020q
   Exit4:
   pop AX
ret
CheckRv endp

CheckSBit proc ;; SI: the command prototype, BX: the line column to write to.
   cmp IsRw, 0
   jne _2af
      mov DispN, 1
      call WriteFreeOperand
   jmp Exit5
   _2af:
   mov DL, [SI+_s]
   cmp DL, 2
   je _2bf
      mov DH, OpCode
      and DH, 2
      cmp DH, 2
      je _2cf
   _2bf:
      mov DispN, 2
      call WriteFreeOperand
   jmp Exit5
   _2cf:
;; Expanded according to the expansion rule.
   call ReadInt
   ShowS1 "0"
   mov AL, DL
   call ByteToHex
   push AX
   mov AL, DH
   call ByteToHex
   Show2 AX
   pop AX
   Show2 AX
   ShowS1 "h"
Exit5:
ret
CheckSBit endp

CheckMod proc ;; SI: the command prototype.
   push BX
   call CheckRv
   mov DL, ModByte
   shr DL, 6
   and DL, 3
   mov DispN, DL
   cmp DL, 3
   jne _2ef
   mov AL, [SI+_d]
   cmp AL, 1
   jne _2df
      mov DH, OpCode
      and DH, 2
      cmp DH, 2
   je _2df
   ;; Direction Reverse 1:
   ;; r/m <- reg // d = 0.
      mov AL, ModByte
      shr AL, 3
      and AL, 7
      or AL, IsRw
      mov BX, 34
      call WriteReg
      mov AL, ModByte
      and AL, 7
      or AL, IsRw
      mov BX, 30
      call WriteReg
      ShowS2 ", "
   jmp Exit6
   _2df:
   ;; reg <- r/m // d = 1 or no at all.
      mov AL, ModByte
      shr AL, 3
      and AL, 7
      or AL, IsRw
      mov BX, 30
      call WriteReg
      ShowS2 ", "
      mov AL, ModByte
      and AL, 7
      or AL, IsRw
      call WriteReg
   jmp Exit6
_2ef:
   mov AL, [SI+_d]
   cmp AL, 1
   jne _2ff
      mov AH, OpCode
      and AH, 2
      cmp AH, 2
   je _2ff
   ;; Direction Reverse 2:
   ;; r/m <- reg // d = 0.
      mov BX, 30
      call WriteEffAddr
      ShowS2 ", "
      mov AL, ModByte
      shr AL, 3
      and AL, 7
      or AL, IsRw
      call WriteReg
   jmp Exit6
   _2ff:
   ;; reg <- r/m // d = 1 or no at all.
      mov BX, 34
      call WriteEffAddr
      mov AL, ModByte
      shr AL, 3
      and AL, 7
      or AL, IsRw
      mov BX, 30
      call WriteReg
      ShowS2 ", "
Exit6:
   pop BX
ret
CheckMod endp

CheckMod2 proc ;; SI: the command prototype.
   push BX
   call CheckRv
   mov DL, ModByte
   shr DL, 6
   and DL, 3
   mov DispN, DL
   cmp DL, 3
   jne _31f
   ;; r/m(reg) <- (bop) // d = 0.
      mov AL, ModByte
      and AL, 7
      or AL, IsRw
      mov BX, 30
      call WriteReg
      mov AL, [SI+_s]
      cmp AL, 0
      je _30f
         ShowS2 ", "
         call CheckSBit
      _30f:
   jmp Exit7
   _31f:
;; r/m <- (bop) // d = 0.
   mov BX, 30
   cmp IsRw, 0
   jne _32f
      ShowS2 "b."
      jmp _34f
   _32f:
   cmp IsRw, 010q
   jne _33f
      ShowS2 "w."
      jmp _34f
   _33f:
   cmp IsRw, 020q
   jne _34f
      ShowS3 "dw","."
   _34f:
   call WriteEffAddr
   cmp byte ptr [SI+_s], 0
   je _35f
      ShowS2 ", "
      call CheckSBit
   _35f:
Exit7:
   pop BX
ret
CheckMod2 endp

end _main

.model small
.stack 100h
.data

BaseIP			dw 100h
Ok			db 13, 10
			db "File written successfully.", 13, 10
			db '$'
NoSuchFile		db 13, 10
			db "No such file: "
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
ExBuf		db 60 dup(32), '$'
Eol		db 10, 13, '$'
IsRw		db 0
IsRs		db 0
DispN		db 0
IsCondJump	db 0
SafeDX		dw 0
Hex		db 10h
ByteP		dw 9
CurIP		dw 0
FileHandle	dw 0

;;          0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16
Command db "MOV PUSHPOP ADD INC SUB DEC CMP MUL DIV CALLRET JMP LOOPINT   :     "
Jcc     db "JO  JNO JB  JNB JE  JNE JNA JA  JS  JNS JP  JNP JL  JGE JLE JG  "

;;          0 1 2 3 4 5 6 7 8 9 101112131415
RegName db "ALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI"

;;          0 1 2 3
SegName db "ESCSSSDS"

;;             0       1       2       3       4       5       6       7
RegMode db "[BX+SI] [BX+DI] [BP+SI] [BP+DI] [SI]    [DI]    [BP]    [BX]    "

;;         0          1          2  3  4  5   6  7   8          9
;;         OpBytes    OpMask    xrm d  w  s  XCM Op  Reg      p/bop
;;	All of the 00 aaa 0dw xrm should be combined: AOp (add,or,adc,sbb,and,sub,xor,cmp), (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;;	All of the 00 aaa 10w should be combined: AOp (add,or,adc,sbb,and,sub,xor,cmp), (AL,Ib; AX,Iw)
ListTab	db 00000000b, 11111100b, 1, 1, 1, 0, 0q, 03, 00000000b, 00	;; 00 000 0dw xrm: add (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 00000100b, 11111110b, 0, 0, 1, 0, 0q, 03, 00000000b, 01	;; 00 000 10w: add (AL,Ib; AX,Iw)
;;	db 00001000b, 11111100b, 1, 1, 1, 0, 0q, __, 00000000b, 00	;; 00 001 0dw xrm: or (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;;	db 00001100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 00 001 10w: or (AL,Ib; AX,Iw)
;;	db 00010000b, 11111100b, 1, 1, 1, 0, 0q, __, 00000000b, 00	;; 00 010 0dw xrm: adc (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;;	db 00010100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 00 010 10w: adc (AL,Ib; AX,Iw)
;;	db 00011000b, 11111100b, 1, 1, 1, 0, 0q, __, 00000000b, 00	;; 00 011 0dw xrm: sbb (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;;	db 00011100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 00 011 10w: sbb (AL,Ib; AX,Iw)
;;	db 00100000b, 11111100b, 1, 1, 1, 0, 0q, __, 00000000b, 00	;; 00 100 0dw xrm: and (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;;	db 00100100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 00 100 10w: and (AL,Ib; AX,Iw)
	db 00101000b, 11111100b, 1, 1, 1, 0, 0q, 05, 00000000b, 00	;; 00 101 0dw xrm: sub (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 00101100b, 11111110b, 0, 0, 1, 0, 0q, 05, 00000000b, 01	;; 00 101 10w: sub (AL,Ib; AX,Iw)
;;	db 00110000b, 11111100b, 1, 1, 1, 0, 0q, __, 00000000b, 00	;; 00 110 0dw xrm: xor (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;;	db 00110100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 00 110 10w: xor (AL,Ib; AX,Iw)
	db 00111000b, 11111100b, 1, 1, 1, 0, 0q, 07, 00000000b, 00	;; 00 111 0dw xrm: cmp (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
	db 00111100b, 11111110b, 0, 0, 1, 0, 0q, 07, 00000000b, 01	;; 00 111 10w: cmp (AL,Ib; AX,Iw)
	db 01000000b, 11111000b, 0, 0, 3, 0, 0q, 04, 00000111b, 00	;; 01 000 rrr: inc Rw (AX,CX,DX,BX,SP,BP,SI,DI)
	db 01001000b, 11111000b, 0, 0, 3, 0, 0q, 06, 00000111b, 00	;; 01 001 rrr: dec Rw (AX,CX,DX,BX,SP,BP,SI,DI)
	db 01010000b, 11111000b, 0, 0, 3, 0, 0q, 01, 00000111b, 00	;; 01 010 rrr: push Rw (AX,CX,DX,BX,SP,BP,SI,DI)
	db 01011000b, 11111000b, 0, 0, 3, 0, 0q, 02, 00000111b, 00	;; 01 011 rrr: pop Rw (AX,CX,DX,BX,SP,BP,SI,DI)
	db 00000110b, 11100111b, 0, 0, 0, 0, 0q, 01, 00011000b, 00	;; 00 0ss 110: push Rs (ES,CS,SS,DS)
	db 00000111b, 11100111b, 0, 0, 0, 0, 0q, 02, 00011000b, 00	;; 00 0ss 111: pop Rs (ES,CS,SS,DS) CS is excluded on 80186+
	db 00100110b, 11100111b, 0, 0, 0, 0, 0q, 15, 00011000b, 00	;; 00 1ss 110: Seg: (ES,CS,SS,DS)
;;	db 00100111b, 11100111b, 0, 0, 0, 0, 0q, __, 00011000b, 00	;; 00 1bb 111: BOp (daa,das,aaa,aas)
	db 01110000b, 11110000b, 0, 0, 0, 0, 0q, 16, 10000000b, 00	;; 0111 cccc: jCC Jb (o,no,b,nb,e,ne,na,a,s,ns,p,np,l,ge,le,g)
;; All of the 10 000 0sb /aaa should be combined using AOp like this:
;;	db 10000000b, 11111100b, 2, 0, 1, 1, 0q, __, 00000000b, 00	;; 10 000 0sw xAm: AOp (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 10000000b, 11111100b, 2, 0, 1, 1, 0q, 03, 00000000b, 00	;; 10 000 0sw x0m: add (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
;;	db 10000000b, 11111100b, 2, 0, 1, 1, 1q, __, 00000000b, 00	;; 10 000 0sw x1m: or (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
;;	db 10000000b, 11111100b, 2, 0, 1, 1, 2q, __, 00000000b, 00	;; 10 000 0sw x2m: adc (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
;;	db 10000000b, 11111100b, 2, 0, 1, 1, 3q, __, 00000000b, 00	;; 10 000 0sw x3m: sbb (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
;;	db 10000000b, 11111100b, 2, 0, 1, 1, 4q, __, 00000000b, 00	;; 10 000 0sw x4m: and (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 10000000b, 11111100b, 2, 0, 1, 1, 5q, 05, 00000000b, 00	;; 10 000 0sw x5m: sub (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
;;	db 10000000b, 11111100b, 2, 0, 1, 1, 6q, __, 00000000b, 00	;; 10 000 0sw x6: xor (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
	db 10000000b, 11111100b, 2, 0, 1, 1, 7q, 07, 00000000b, 00	;; 10 000 0sw x7m: cmp (Eb,Ib; Ew,Iw; Eb,Is; Ew,Is)
;;	db 10000100b, 11111110b, 2, 0, 1, 0, 0q, __, 00000000b, 00	;; 10 000 10w: test (Eb,Ib; Ew,Iw)
;;	db 10000110b, 11111110b, 2, 0, 1, 0, 0q, __, 00000000b, 00	;; 10 000 11w: xchg (Eb,Ib; Ew,Iw)
	db 10001000b, 11111100b, 1, 1, 1, 0, 0q, 00, 00000000b, 00	;; 10 001 0dw xrm: mov (Eb,Rb; Ew,Rw; Rb,Eb; Rw,Ew)
;;	db 10001101b, 11111111b, 1, 0, 3, 0, 0q, __, 00000000b, 00	;; 10 001 101 xrm: lea Ew (r != 3)
	db 10001100b, 11111101b, 1, 1, 3, 0, 0q, 00, 00011000b, 00	;; 10 001 100 xrm: mov (Ew,Rs; Rs,Ew)
	db 10001111b, 11111111b, 2, 0, 3, 0, 0q, 02, 00000000b, 00	;; 10 001 111 x0m: pop Ew
;;	db 10010000b, 11111000b, 0, 0, 0, 0, 0q, __, 00000111b, 00	;; 10 010 rrr: xchg AX, Rw (note: xchg AX, AX = nop)
;;	db 10011000b, 11111110b, 0, 0, 1, 0, 0q, 00, 00000000b, 00	;; 10 011 00w: COp (cbw,cwd)
	db 10011010b, 11111111b, 0, 0, 0, 0, 0q, 10, 10000000b, 04	;; 10 011 010: call Af
;;	db 10011011b, 11111111b, 0, 0, 0, 0, 0q, __, 00000000b, 00	;; 10 011 011: wait
;;	db 10011100b, 11111100b, 0, 0, 0, 0, 0q, __, 00000000b, 00	;; 10 011 1ff: FOp (pushf, popf, sahf, lahf)
	db 10100000b, 11111100b, 0, 1, 1, 0, 0q, 00, 00100000b, 00	;; 10 100 0dw: mov (AL,Mb; AX,Mw; Mb,AL; Mw,AL)
;;	db 10100100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 10 100 10w: (movsb,movsw)
;;	db 10100110b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 10 100 11w: (cmpsb,cmpsw)
;;	db 10101000b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 10 101 00w: test (AL,Ib; AX,Iw)
;;	db 10101010b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 10 101 01w: (stosb,stosw)
;;	db 10101100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 10 101 10w: (lodsb,lodsw)
;;	db 10101110b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 10 101 11w: (scasb,scasw)
	db 10110000b, 11110000b, 0, 0, 0, 0, 0q, 00, 00001111b, 01	;; 10 11w rrr: mov (Rb,Ib; Rw,Iw)
	db 11000010b, 11111111b, 0, 0, 0, 0, 0q, 11, 10000000b, 02	;; 11 000 010: ret Iw
	db 11000011b, 11111111b, 0, 0, 0, 0, 0q, 11, 10000000b, 00	;; 11 000 011: ret
;;	db 11000100b, 11111111b, 1, 0, 3, 0, 0q, __, 00000000b, 00	;; 11 000 100 xrm: les Rw,Ew
;;	db 11000101b, 11111111b, 1, 0, 3, 0, 0q, __, 00000000b, 00	;; 11 000 101 xrm: lds Rw,Ew
	db 11000110b, 11111110b, 2, 0, 1, 2, 0q, 00, 00000000b, 00	;; 11 000 11w x0m: mov (Eb,Ib; Ew,Iw)
;;	db 11001010b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 02	;; 11 001 010: retf Iw
;;	db 11001011b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 001 011: retf
;;	db 11001100b, 11111111b, 0, 0, 0, 0, 0q, 14, 10000000b, 00	;; 11 001 100: int 3
	db 11001101b, 11111111b, 0, 0, 0, 0, 0q, 14, 10000000b, 01	;; 11 001 101: int Ib
;;	db 11001110b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 001 110: into
;;	db 11001111b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 001 111: iret
;;	db 11010000b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 11 010 00w: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,Ib; Ew,Iw)
;;	db 11010010b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 11 010 01w: SOp (rol,ror,rcl,rcr,shl,shr,-,sar) (Eb,CL; Ew,CL)
;;	db 11010101b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 010 100: aam
;;	db 11010101b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 010 101: aad
;;	db 11010111b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 010 111: xlat
;;	db 11011000b, 11111000b, 1, 0, 0, 0, 0q, __, 00000111b, 00	;; 11 011 ppp xrm: esc p Eb
;;	db 11100000b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 10h	;; 11 100 010: loopne Jb
;;	db 11100001b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 10h	;; 11 100 010: loope Jb
	db 11100010b, 11111111b, 0, 0, 0, 0, 0q, 13, 10000000b, 10h	;; 11 100 010: loop Jb
;;	db 11100011b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 10h	;; 11 100 010: jcxz Jb
;;	db 11100100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 11 100 10w: in (AL,Ib; AX,Ib)
;;	db 11100110b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 01	;; 11 100 11w: out (Ib,AL; Ib,AX)
	db 11101000b, 11111111b, 0, 0, 0, 0, 0q, 10, 10000000b, 20h	;; 11 101 000: call An
	db 11101001b, 11111111b, 0, 0, 0, 0, 0q, 12, 10000000b, 20h	;; 11 101 001: jmp An
	db 11101010b, 11111111b, 0, 0, 0, 0, 0q, 12, 10000000b, 04	;; 11 101 010: jmp Af
	db 11101011b, 11111111b, 0, 0, 0, 0, 0q, 12, 10000000b, 10h	;; 11 101 011: jmp Jb
;;	db 11101100b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 11 101 10w: in (AL,DX; AX,DX)
;;	db 11101110b, 11111110b, 0, 0, 1, 0, 0q, __, 00000000b, 00	;; 11 101 11w: out (DX,AL; DX,AX)
;;	db 11110000b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 110 000: lock
;;	db 11110010b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 110 010: repne
;;	db 11110011b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 110 011: rep
;;	db 11110100b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 110 100: hlt
;;	db 11110101b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 110 101: cmc
;;	db 11110110b, 11111110b, 2, 0, 1, 0, 0q, __, 00000000b, 00	;; 11 110 11w x0m: test (Eb,Ib; Ew,Iw)
;;	db 11110110b, 11111110b, 2, 0, 1, 0, 2q, __, 00000000b, 00	;; 11 110 11w x2m: neg (Eb; Ew)
;;	db 11110110b, 11111110b, 2, 0, 1, 0, 3q, __, 00000000b, 00	;; 11 110 11w x3m: not (Eb; Ew)
	db 11110110b, 11111110b, 2, 0, 1, 0, 4q, 08, 00000000b, 00	;; 11 110 11w x4m: mul (Eb; Ew)
;;	db 11110110b, 11111110b, 2, 0, 1, 0, 5q, __, 00000000b, 00	;; 11 110 11w x5m: imul (Eb; Ew)
	db 11110110b, 11111110b, 2, 0, 1, 0, 6q, 09, 00000000b, 00	;; 11 110 11w x6m: div (Eb; Ew)
;;	db 11110110b, 11111110b, 2, 0, 1, 0, 7q, __, 00000000b, 00	;; 11 110 11w x7m: idiv (Eb; Ew)
;;	db 11111000b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 111 000: cmc
;;	db 11111001b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 111 001: stc
;;	db 11111010b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 111 010: cmi
;;	db 11111011b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 111 011: sti
;;	db 11111100b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 111 100: cmd
;;	db 11111101b, 11111111b, 0, 0, 0, 0, 0q, __, 10000000b, 00	;; 11 111 101: std
	db 11111110b, 11111110b, 2, 0, 1, 0, 0q, 04, 00000000b, 00	;; 11 111 11w x0m: inc (Eb; Ew)
	db 11111110b, 11111110b, 2, 0, 1, 0, 1q, 06, 00000000b, 00	;; 11 111 11w x1m: dec (Eb; Ew)
	db 11111111b, 11111111b, 2, 0, 3, 0, 2q, 10, 00000000b, 00	;; 11 111 111 x2m: call near En
	db 11111111b, 11111111b, 2, 0, 4, 0, 3q, 10, 00000000b, 00	;; 11 111 111 x3m: call far Ef
	db 11111111b, 11111111b, 2, 0, 2, 0, 4q, 12, 00000000b, 00	;; 11 111 111 x4m: jmp near En
	db 11111111b, 11111111b, 2, 0, 3, 0, 5q, 12, 00000000b, 00	;; 11 111 111 x5m: jmp far Ef
ListEnd	db 11111111b, 11111111b, 2, 0, 3, 0, 6q, 01, 00000000b, 00	;; 11 111 111 x6m: push Ew

.code
   mov AX, @data
   mov DS, AX
   mov BX, 81h ;; The address of the first character of the parameter.
   cmp byte ptr ES:[BX], 13
   je _00f
      mov DL, ES:[BX + 1]
      cmp DL, 13
   je _00f
      cmp DL, '/'
      jne _01f
      mov DL, ES:[BX + 2]
      cmp DL, '?'
      jne WrongParams
   _00f:
   jmp WriteInfo
_01f:
;; Read the names of the two files.
   inc BX
   mov DI, offset InFile
   call ReadFileName
   cmp CL, 'E'
   je WrongParams
   inc BX
   mov DI, offset ExFile
   call ReadFileName
   cmp CL, 'E'
   je WrongParams
;; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;; Read data from a file.
   mov DX, offset InFile
   mov CX, offset InBuf
   call ReadFile
   push CX
   cmp CL, 'F'
   je NoFile
;; Perform the calculations.
   mov BX, CurIP
   call OpenFile
   _0b:
      mov BX, CurIP
      pop CX
      cmp BX, CX
      jge _03f
      push CX
      mov SI, offset InBuf
      mov DI, offset ExBuf
      mov DH, 0
      mov DL, [SI][BX]
   ;; Clear the output buffer and pad an end-of-line marker '\n'.
      push BX
      mov BX, 0
      _1b:
         mov byte ptr [DI][BX], 32
         inc BX
         cmp BX, 62
         jge _02f
      jmp _1b
   _02f:
   ;; --
      mov byte ptr [DI][60], 10
      pop BX
      mov ByteP, 9
      call CheckOpCode
      call WriteLine
      inc CurIP
      inc BX
   jmp _0b
_03f:
   call CloseFile
;; Report the files written.
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset Ok
   mov AH, 09h
   int 21h
jmp Exit0
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
NoFile:
   push DX
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset NoSuchFile
   mov AH, 09h
   int 21h
   pop DX
;; Put String: DS:DX: '$'-terminated string.
   mov AH, 09h
   int 21h
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset Eol
   mov AH, 09h
   int 21h
Exit0:
;; Exit. Status: AL.
   mov AX, 4c00h
   int 21h

ReadFileName proc ;; ES:BX: Location on the command line to read from, DS:DI: The file name buffer to read to.
   mov DX, 0
   _2b:
      mov AL, ES:BX
      cmp AL, 32
      je _04f
      cmp AL, 0
      je _04f
      cmp AL, 13
      je _04f
      push BX
      mov BX, DX
      mov [DI][BX], AL
      pop BX
      inc BX
      inc DX
   jmp _2b
_04f:
   cmp DX, 1
   jle _05f
      mov CL, 'T'
   jmp _06f
   _05f:
      mov CL, 'E'
   _06f:
ret
ReadFileName endp

ReadFile proc
;; File Read Open. DS:DX: File Name, AL: Access/Sharing Mode, CL: Attribute Mask => (CF, AX): (1, Error Code) or (0, File Handle).
   mov AH, 3dh
   mov AL, 02h
   int 21h
   jnc _07f
      mov CL, 'F'
   jmp _08f
   _07f:
      mov BX, AX ;; File Handle
      mov DX, CX
      mov CX, 0ffh
   ;; File Read. BX: File Handle, DS:DX: Buffer, CX: Size => (CF, AX) = (1, Error Code) or (0, Bytes Read).
      mov AH, 3fh
      int 21h
      mov CX, AX
   ;; File Close. BX: File Handle => (CF, AX) = (1, Error Code) or (0, *).
      mov AH, 3eh
      int 21h
   _08f:
ret
ReadFile endp

OpenFile proc
   push AX
   push DX
   mov CX, 01000000b
   mov DX, offset ExFile
;; File Write Open. DS:DX: File Name, CX: File Attributes => (CF, AX) = (1, Error Code) or (0, File Handle).
   mov AH, 3ch
   int 21h
   mov FileHandle, AX
   pop DX
   pop AX
ret
OpenFile endp

WriteLine proc
   push BX
   push DX
   mov BX, FileHandle
   mov DX, offset ExBuf
   mov CX, 61
;; File Write. BX: File Handle, DS:DX: Buffer, CX: Bytes => (CF, AX) = (1, Error Code) or (0, Bytes Written).
   mov AH, 40h
   int 21h
;; Put String: DS:DX: '$'-terminated string.
   mov DX, offset ExBuf
   mov AH, 09h
   int 21h
   pop DX
   pop BX
ret
WriteLine endp

CloseFile proc
   push BX
   push AX
   mov BX, FileHandle
;; File Close. BX: File Handle => (CF, AX) = (1, Error Code) or (0, *).
   mov AH, 3eh
   int 21h
   pop AX
   pop BX
ret
CloseFile endp

CheckOpCode proc ;; DL: OpCode
;; Format:
;; Addr: hh hh hh hh hh hh Mnem  Arg, Arg...
;; 01234567890123456789012345678901234567890
;; 0.........1.........2.........3.........4
   call WriteAddress
   mov DH, DL
   mov SafeDX, DX
   mov SI, offset ListTab
   _3b:
      mov DX, SafeDX
      mov AL, [SI + 1]
      and DL, AL
      mov AL, [SI]
      cmp DL, AL
      jne _09f
         cmp byte ptr [SI + 2], 2
         jne _0bf
         call ReadByte
         mov SafeDX, DX
         and DL, 00111000b
         shr DL, 3
         _4b:
            cmp [SI + 6], DL
            je _0bf
            add SI, 10
         jmp _4b
      _09f:
      add SI, 10
      mov AX, offset ListEnd
      cmp SI, AX
   jle _3b
jmp Exit1
_0bf:
   mov AL, [SI + 7]
   call WriteCommand
   and DL, 11110000b
   cmp DL, 01110000b
   jne _0cf
   ;; Conditional Jumps.
      mov IsCondJump, 1
      mov AL, DH
      and AL, 00001111b
      call WriteCommand
      mov AX, 30
      mov DispN, 1
      call WriteJumpDisp
   jmp Exit1
   _0cf:
   mov DL, DH
   mov AL, [SI + 8]
   cmp AL, 10000000b
   jne _10f
   ;; Command with no register.
      mov AL, [SI + 9]
      cmp AL, 0
      je _0ff
         cmp AL, 4
         je _0ef
            cmp AL, 10h
            jge _0df
            ;; Free Operand.
               mov DispN, AL
               mov AX, 30
               call WriteFreeOperand
            jmp _0ff
            _0df:
         ;; Displacement.
            and AL, 11110000b
            shr AL, 4
            mov DispN, AL
            mov AX, 30
            call WriteJumpDisp
         jmp _0ff
         _0ef:
         mov DispN, 2
         mov AX, 37
         call WriteFreeOperand
         mov DispN, 2
         mov AX, 30
         call WriteFreeOperand
         mov byte ptr [DI + 36], ':'
      _0ff:
   jmp Exit1
   _10f:
   mov IsRs, 0
   mov AL, [SI + 8]	;; @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   cmp AL, 00011000b
   jne _12f
   ;; Has a segment register here.
      mov IsRs, 1
      mov AL, [SI + 2]
      cmp AL, 1	;; Defer adding the segment ...
   je _12f	;; ... to MOD.
      mov AL, [SI + 7]
      cmp AL, 15
      jne _11f
      ;; Segment override.
         mov AX, 24
         call WriteSegReg
      jmp Exit1
      _11f:
   ;; Ordinary command with a segment register.
      mov AX, 30
      call WriteSegReg
   jmp Exit1
   _12f:
   mov AL, [SI + 8]	;; @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   cmp AL, 00100000b
   jne _15f
      mov IsRw, 0
      call CheckRv
      mov AL, [SI + 3]
      cmp AL, 1
      jne _13f
         and DL, 00000010b
         cmp DL, 00000000b
      je _13f
      ;; Normal order.
         mov AX, 30
         call WriteDirectAddress
         mov [DI + 38], " ,"
         mov DL, DH
         mov AL, [SI + 8]
         and DL, AL
         and DL, 00001111b
         or DL, IsRw
         mov AX, 40
         call WriteReg
      jmp _14f
      _13f:
      ;; Reverse order.
         mov AX, 34
         call WriteDirectAddress
         mov [DI + 32], " ,"
         mov DL, DH
         mov AL, [SI + 8]
         and DL, AL
         and DL, 00001111b
         or DL, IsRw
         mov AX, 30
         call WriteReg
      _14f:
   jmp Exit1
   _15f:
   mov AL, [SI + 2]
   cmp AL, 0
   je _16f
      jmp HasMod
   _16f:
;; No MOD here.
;; Word or byte.
   mov AL, [SI + 4]
   cmp AL, 2
   je _18f
      cmp AL, 3
      je _19f
      cmp AL, 1
      jne _17f
         and DL, 00000001b
         cmp DL, 1
         je _19f
      jmp _18f
      _17f:
      mov DL, DH
      mov AL, [SI + 8]
      and DL, AL
      cmp DL, 00000111b
      jg _19f
   _18f:
      mov DL, DH
      mov AL, [SI + 8]
      and DL, AL
      mov AX, 30
      call WriteReg
      mov AL, [SI + 9]
      cmp AL, 1
      jne _1af
   ;; Has one free operand.
      call ReadByte
      mov [DI + 35], AX
      mov [DI + 32], " ,"
      mov byte ptr[DI + 34], '0'
      mov byte ptr[DI + 37], 'h'
   jmp _1af
   _19f:
      mov DL, DH
      mov AL, [SI + 8]
      and DL, AL
      or DL, 00001000b
      mov AX, 30
      call WriteReg
      mov AL, [SI + 9]
      cmp AL, 1
   jne _1af
   ;; Has two free operands.
      call ReadByte
      mov [DI + 37], AX
      call ReadByte
      mov [DI + 35], AX
      mov [DI + 32], " ,"
      mov byte ptr[DI + 34], '0'
      mov byte ptr[DI + 39], 'h'
   _1af:
jmp Exit1
HasMod:
;; Has MOD here.
   cmp byte ptr [SI + 2], 2
   jne _1bf
      call CheckMod2
   jmp Exit1
   _1bf:
   call ReadByte
   call CheckMod
Exit1:
ret
CheckOpCode endp

ByteToHex proc ;; DL: The byte value to convert to hex.
   mov AH, 0
   mov AL, DL
   div Hex
   cmp AL, 9
   jg _1cf
      add AL, 48
   jmp _1df
   _1cf:
      add AL, 55
   _1df:
   cmp AH, 9
   jg _1ef
      add AH, 48
   jmp _1ff
   _1ef:
      add AH, 55
   jmp _1ff
_1ff:
ret
ByteToHex endp

WriteAddress proc ;; BaseIP+CurIP: The (relocated) address, DL: The OpCode.
   push BX
   push DX
   mov BX, CurIP
   add BX, BaseIP
   mov DL, BH
   call ByteToHex
   mov [DI + 0], AX
   mov DL, BL
   call ByteToHex
   mov [DI + 2], AX
   mov byte ptr [DI + 4], ':'
   pop DX ;; Retrieve the opcode to write out, too.
   pop BX
   call ByteToHex
   mov [DI + 6], AX
ret
WriteAddress endp

WriteCommand proc ;; AL: Operator number.
   push SI
   push BX
   mov SI, offset Command
   cmp IsCondJump, 1
   jne _20f
      mov SI, offset Jcc
      mov IsCondJump, 0
   _20f:
   mov AH, 0
   mov BX, AX
   shl BX, 2
   mov AX, [SI][BX]
   mov [DI + 24], AX
   add BX, 2
   mov AX, [SI][BX]
   mov [DI + 26], AX
   pop BX
   pop SI
ret
WriteCommand endp

WriteReg proc ;; DL: Register number or Shifted MOD REG R/M, AX: the line column to write to.
   push BX
   push DX
   push SI
   mov BL, IsRs
   cmp BL, 1
   je _21f
      mov BH, 0
      mov BL, DL
      shl BX, 1
      mov SI, offset RegName
      add DI, AX
      mov BX, [SI][BX]
      mov [DI], BX ;; Output 2 characters to the buffer.
      sub DI, AX
   jmp _22f
   _21f:
      mov DX, SafeDX
      call WriteSegReg
   _22f:
   pop SI
   pop DX
   pop BX
ret
WriteReg endp

WriteSegReg proc ;; DL: ComByte, AX: the line column to write to.
   push BX
   push DX
   push SI
   mov BH, 0
   mov BL, DL
   and BL, 00011000b
   shr BX, 2
   mov SI, offset SegName
   add DI, AX
   mov BX, [SI][BX]
   mov [DI], BX ;; Output 2 characters to the buffer.
   sub DI, AX
   mov IsRs, 0
   pop SI
   pop DX
   pop BX
ret
WriteSegReg endp

WriteEffAddr proc ;; DL: MOD REG R/M, &AX: the line column to write to (updated).
;; Write Register/Memory Address.
   push BX
   push DX
   push SI
   push DI
   push AX
   mov DX, SafeDX
   mov BX, DX
   and BL, 11000111b
   cmp BL, 00000110b ;; Direct address, MOD = 00, r/m = 110
   je _24f
      mov BH, 0
      mov BL, DL
      and BL, 00000111b
      shl BX, 3
      mov SI, offset RegMode
      add DI, AX
      mov AX, [SI][BX]
      mov [DI], AX
      mov AX, [SI][BX + 2]
      mov [DI + 2], AX
      mov AX, [SI][BX + 4]
      mov [DI + 4], AX
      mov AX, [SI][BX + 6]
      mov [DI + 6], AX
      and DL, 00000111b
      cmp DL, 4
      pop AX
      jge _23f
      ;; Less than 4.
         add AX, 7
      jmp _25f
      _23f:
         add AX, 4
      jmp _25f
   _24f:
   pop AX
   call WriteDirectAddress
   add AX, 8
_25f:
   pop DI
   pop SI
   pop DX
   pop BX
;; Write Displacement.
   push BX
   push CX
   push DX
   mov BX, AX
   mov CH, 0
   mov CL, DispN
   cmp CL, 0
   je Exit3
;; There is a displacement.
   mov [DI][BX], "+ "
   mov [DI][BX + 2], "0 "
   add BX, 4
   cmp CL, 1
   jne _26f
   ;; One-byte offset.
      call ReadByte
      mov [DI + BX], AX
      mov byte ptr [DI][BX + 2], 'h'
      mov AX, BX
      add AX, 3
   jmp Exit3
   _26f:
   ;; Two-byte offset.
      call ReadByte
      mov [DI][BX + 2], AX
      call ReadByte
      mov [DI][BX], AX
      mov byte ptr [DI][BX + 4], 'h'
      mov AX, BX
      add AX, 5
Exit3:
   pop DX
   pop CX
   pop BX
   mov DispN, 0
ret
WriteEffAddr endp

WriteDirectAddress proc ;; AX: the line column to write to.
   push BX
   push CX
   push DX
   mov BX, AX
   mov [DI][BX], "0["
   mov [DI][BX + 6], "]h"
   call ReadByte
   mov [DI][BX + 4], AX
   call ReadByte
   mov [DI][BX + 2], AX
   mov AX, BX
   pop DX
   pop CX
   pop BX
ret
WriteDirectAddress endp

WriteFreeOperand proc ;; DispN: the number of bytes, AX: the line column to write to.
   push BX
   push CX
   push DX
   mov BX, AX
   mov CH, 0
   mov CL, DispN
   cmp CL, 0
   je Exit4
;; There are operands.
   cmp CL, 1
   jg _27f
   ;; One-byte operand.
      call ReadByte
      mov byte ptr [DI][BX], '0'
      mov [DI][BX + 1], AX
      mov byte ptr [DI][BX + 3], 'h'
   jmp Exit4
   _27f:
   ;; Two-byte operand.
      mov byte ptr [DI][BX], '0'
      call ReadByte
      mov [DI][BX + 3], AX
      call ReadByte
      mov [DI][BX + 1], AX
      mov byte ptr [DI][BX + 5], 'h'
Exit4:
   pop DX
   pop CX
   pop BX
   mov DispN, 0
ret
WriteFreeOperand endp

WriteJumpDisp proc ;; DispN: the number of displacement bytes, AX: the line column to write to.
   push BX
   push CX
   push DX
;; xor CX, CX ;; (@) Default case?
   mov BX, AX
   cmp DispN, 0
   je _2af
   cmp DispN, 1
   jne _29f
   ;; One-byte jump displacement.
      call ReadByte
      mov CX, CurIP
      inc CX
      add CX, BaseIP
      mov DH, 0
      cmp DL, 080h
      jb _28f
         mov DH, 0ffh
      _28f:
      add CX, DX
   jmp _2af
   _29f:
   ;; Two-byte jump displacement.
      call ReadByte
      mov DH, DL
      call ReadByte
      xchg DL, DH
      mov CX, CurIP
      inc CX
      add CX, BaseIP
      add CX, DX
   _2af:
   mov byte ptr [DI][BX + 4], 'h'
   mov DL, CH
   call ByteToHex
   mov [DI][BX + 0], AX
   mov DL, CL
   call ByteToHex
   mov [DI][BX + 2], AX
   mov DispN, 0
   pop DX
   pop CX
   pop BX
ret
WriteJumpDisp endp

ReadByte proc ;; CurIP: the last command IP, &ByteP: the line column to write to (updated) => AX: the byte in hex, DL: the byte.
   push SI
   push BX
   mov BX, CurIP
   inc BX
   mov SI, offset InBuf
   mov DL, [SI][BX]
   mov CurIP, BX
   mov BX, ByteP
   call ByteToHex
   mov [DI][BX], AX
   add BX, 3
   mov ByteP, BX
   pop BX
   pop SI
ret
ReadByte endp

CheckRv proc ;; SI: the command prototype, DH: the OpCode.
   push AX
   push DX
   mov AL, [SI + 4]
   cmp AL, 1
   jne _2bf
      and DH, 00000001b
      cmp DH, 00000001b
   jne _2bf
      mov IsRw, 00001000b
   _2bf:
   cmp AL, 3
   jne _2cf
      mov IsRw, 00001000b
   _2cf:
   cmp AL, 4
   jne _2df
      mov IsRw, 00010000b
   _2df:
   pop DX
   pop AX
ret
CheckRv endp

CheckSBit proc ;; DH: the OpCode, AX: the line column to write to.
   push BX
   push DX
   mov BX, AX
   cmp IsRw, 0
   jne _2ef
      mov DispN, 1
      call WriteFreeOperand
   jmp Exit5
   _2ef:
   mov DL, [SI + 5]
   cmp DL, 2
   je _2ff
      mov DX, SafeDX
      and DH, 00000010b
      cmp DH, 00000010b
      je _30f
   _2ff:
      mov DispN, 2
      call WriteFreeOperand
   jmp Exit5
   _30f:
;; Expanded according to the expansion rule.
   call ReadByte
   mov DH, 0
   cmp DL, 10000000b
   jb _31f
      mov DH, 0ffh
   _31f:
   call ByteToHex
   mov [DI][BX + 3], AX
   mov DL, DH
   call ByteToHex
   mov [DI][BX + 1], AX
   mov byte ptr [DI][BX + 0], '0'
   mov byte ptr [DI][BX + 5], 'h'
Exit5:
   pop DX
   pop BX
ret
CheckSBit endp

CheckMod proc ;; SI: the command prototype, DH: the OpCode, DL: mod reg r/m.
   push SI
   push BX
   push DX
   mov SafeDX, DX
   mov IsRw, 0
   mov DispN, 0
   call CheckRv
   and DL, 11000000b
   cmp DL, 11000000b
   je _33f
      cmp DL, 00000000b
      jne _32f
      jmp _35f
      _32f:
         shr DL, 6
         mov DispN, DL
      jmp _35f
   _33f:
;; DH: The OpCode, DL: mod reg r/m, SI: the command prototype.
   mov AL, [SI + 3]
   cmp AL, 1
   jne _34f
      and DH, 00000010b
      cmp DH, 00000010b
      mov DX, SafeDX
   je _34f
   ;; Direction Reverse 1:
   ;; r/m <- reg // d = 0.
      and DL, 00111000b
      shr DL, 3
      or DL, IsRw
      mov AX, 34
      call WriteReg
      mov DX, SafeDX
      and DL, 00000111b
      or DL, IsRw
      mov AX, 30
      call WriteReg
      mov [DI + 32], " ,"
   jmp Exit6
   _34f:
   ;; reg <- r/m // d = 1 or no at all.
      and DL, 00111000b
      shr DL, 3
      or DL, IsRw
      mov AX, 30
      call WriteReg
      mov DX, SafeDX
      and DL, 00000111b
      or DL, IsRw
      mov AX, 34
      call WriteReg
      mov [DI + 32], " ,"
   jmp Exit6
_35f:
   mov AL, [SI + 3]
   cmp AL, 1
   jne _36f
      and DH, 00000010b
      cmp DH, 00000010b
      mov DX, SafeDX
   je _36f
   ;; Direction Reverse 2:
   ;; r/m <- reg // d = 0.
      mov AX, 30
      call WriteEffAddr
      add DI, AX
      mov [DI], " ,"
      sub DI, AX
      mov DX, SafeDX
      and DL, 00111000b
      shr DL, 3
      or DL, IsRw
      add AX, 2
      call WriteReg
   jmp Exit6
   _36f:
   ;; reg <- r/m // d = 1 or no at all.
      mov AX, 34
      call WriteEffAddr
      mov DX, SafeDX
      and DL, 00111000b
      shr DL, 3
      or DL, IsRw
      mov AX, 30
      call WriteReg
      mov [DI + 32], " ,"
Exit6:
   pop DX
   pop BX
   pop SI
ret
CheckMod endp

CheckMod2 proc ;; SI: the command prototype, SafeDX: (DH: the OpCode, DL: mod reg r/m).
   push SI
   push BX
   push DX
   mov DX, SafeDX
   mov IsRw, 0
   mov DispN, 0
   call CheckRv
   and DL, 11000000b
   cmp DL, 11000000b
   je _38f
      cmp DL, 00000000b
      jne _37f
      jmp _3af
   _37f:
      shr DL, 6
      mov DispN, DL
   jmp _3af
   _38f:
   ;; DH: The OpCode, DL: mod reg r/m, SI: the command prototype.
   ;; r/m(reg) <- (bop) // d = 0.
      mov DX, SafeDX
      and DL, 00000111b
      or DL, IsRw
      mov AX, 30
      call WriteReg
      mov AL, [SI + 5]
      cmp AL, 0
      je _39f
         mov [DI + 32], " ,"
         mov DX, SafeDX
         mov AX, 34
         call CheckSBit
      _39f:
   jmp Exit7
   _3af:
;; r/m <- (bop) // d = 0.
   mov AX, 30
   cmp IsRw, 0
   jne _3bf
      mov [DI + 30], ".b"
      add AX, 2
   _3bf:
   cmp IsRw, 00001000b
   jne _3cf
      mov [DI + 30], ".w"
      add AX, 2
   _3cf:
   cmp IsRw, 00010000b
   jne _3df
      mov [DI + 30], "wd"
      mov byte ptr [DI + 32], '.'
      add AX, 3
   _3df:
   call WriteEffAddr
   cmp byte ptr [SI + 5], 0
   je _3ef
      add DI, AX
      mov [DI], " ,"
      sub DI, AX
      mov DX, SafeDX
      add AX, 2
      call CheckSBit
   _3ef:
Exit7:
   pop DX
   pop BX
   pop SI
ret
CheckMod2 endp

end

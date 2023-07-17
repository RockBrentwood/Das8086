.model small
.stack 100h
.data

ListEnd equ List41
PosLinkisOrg dw 100h
Ok db 13, 10, 'File written successfully.', 13, 10, '$'
NoSuchFile db 13, 10, 'No such file: ', '$'
InvalidArguments db 13, 10, 'Invalid arguments', 13, 10, '$'
Banner db 13, 10, 'Made by Justas Glodenis', 13, 10, 'Arguments to use in order: ', 13, 10, 'arg 1: sourceFile - file to disassemble', 13, 10, 'arg 2: destinationFile - output for disassembled code', 13, 10, 'example: ', 96, 'disasm sourceFile.com destinationFile.txt', 96, '$'
File1 db 20 dup(0), '$'
RezFile db 20 dup(0)
Duom1 db 255 dup(0)
Rez db 60 dup(32), '$'
Eol db 10, 13, '$'
IsRw db 0
IsRs db 0
IsPosLinkis db 0
IsComJump db 0
SafeDX dw 0
Hex db 10h
Nr dw 9
ByteNumber dw 0
FileHandler dw 0

;;           0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16
Command db 'MOV PUSHPOP ADD INC SUB DEC CMP MUL DIV CALLRET JMP LOOPINT   :     '
Jcc     db     'JO  JNO JB  JNB JE  JNE JNA JA  JS  JNS JP  JNP JL  JGE JLE JG  '
RegName db 'ALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI'
SegName db 'ESCSSSDS'

;;		  0       1       2       3       4       5       6       7
RegMode db '[BX+SI] [BX+DI] [BP+SI] [BP+DI] [SI]    [DI]    [BP]    [BX]    '

	;;      0          1        2  3   4   5   6    7       8       9
	;;  HAS or IS:   comBytes   MOD d   w   s  XCM  comNR   reg    p/bop
List01 db 00000000b, 11111100b, 01, 01, 01, 00, 000b, 03, 00000000b, 00
List02 db 00000100b, 11111110b, 00, 00, 01, 00, 000b, 03, 00000000b, 01
List03 db 00101000b, 11111100b, 01, 01, 01, 00, 000b, 05, 00000000b, 00
List04 db 00101100b, 11111110b, 00, 00, 01, 00, 000b, 05, 00000000b, 01
List05 db 00111000b, 11111100b, 01, 01, 01, 00, 000b, 07, 00000000b, 00
List06 db 00111100b, 11111110b, 00, 00, 01, 00, 000b, 07, 00000000b, 01
List07 db 01000000b, 11111000b, 00, 00, 03, 00, 000b, 04, 00000111b, 00
List08 db 01001000b, 11111000b, 00, 00, 03, 00, 000b, 06, 00000111b, 00
List09 db 01010000b, 11111000b, 00, 00, 03, 00, 000b, 01, 00000111b, 00
List10 db 01011000b, 11111000b, 00, 00, 03, 00, 000b, 02, 00000111b, 00
List11 db 00000110b, 11100111b, 00, 00, 00, 00, 000b, 01, 00011000b, 00
List12 db 00000111b, 11100111b, 00, 00, 00, 00, 000b, 02, 00011000b, 00
List13 db 00100110b, 11100111b, 00, 00, 00, 00, 000b, 15, 00011000b, 00
List14 db 10001000b, 11111100b, 01, 01, 01, 00, 000b, 00, 00000000b, 00
List15 db 10001100b, 11111101b, 01, 01, 03, 00, 000b, 00, 00011000b, 00
List16 db 10110000b, 11110000b, 00, 00, 00, 00, 000b, 00, 00001111b, 01
List17 db 10100000b, 11111100b, 00, 01, 01, 00, 000b, 00, 00100000b, 00
List18 db 11001101b, 11111111b, 00, 00, 00, 00, 000b, 14, 10000000b, 01
List19 db 11000011b, 11111111b, 00, 00, 00, 00, 000b, 11, 10000000b, 00
List20 db 11000010b, 11111111b, 00, 00, 00, 00, 000b, 11, 10000000b, 02
List21 db 10011010b, 11111111b, 00, 00, 00, 00, 000b, 10, 10000000b, 04
List22 db 11101010b, 11111111b, 00, 00, 00, 00, 000b, 12, 10000000b, 04
List23 db 01110000b, 11110000b, 00, 00, 00, 00, 000b, 16, 10000000b, 00 ;; isimtis
List24 db 11101000b, 11111111b, 00, 00, 00, 00, 000b, 10, 10000000b, 20h
List25 db 11101001b, 11111111b, 00, 00, 00, 00, 000b, 12, 10000000b, 20h
List26 db 11101011b, 11111111b, 00, 00, 00, 00, 000b, 12, 10000000b, 10h
List27 db 11100010b, 11111111b, 00, 00, 00, 00, 000b, 13, 10000000b, 10h
List28 db 11111110b, 11111110b, 02, 00, 01, 00, 000b, 04, 00000000b, 00
List29 db 11111110b, 11111110b, 02, 00, 01, 00, 001b, 06, 00000000b, 00
List30 db 11111111b, 11111111b, 02, 00, 03, 00, 010b, 10, 00000000b, 00
List31 db 11111111b, 11111111b, 02, 00, 04, 00, 011b, 10, 00000000b, 00
List32 db 11111111b, 11111111b, 02, 00, 02, 00, 100b, 12, 00000000b, 00
List33 db 11111111b, 11111111b, 02, 00, 03, 00, 101b, 12, 00000000b, 00
List34 db 11111111b, 11111111b, 02, 00, 03, 00, 110b, 01, 00000000b, 00
List35 db 11110110b, 11111110b, 02, 00, 01, 00, 100b, 08, 00000000b, 00
List36 db 11110110b, 11111110b, 02, 00, 01, 00, 110b, 09, 00000000b, 00
List37 db 10001111b, 11111111b, 02, 00, 03, 00, 000b, 02, 00000000b, 00
List38 db 10000000b, 11111100b, 02, 00, 01, 01, 000b, 03, 00000000b, 00
List39 db 10000000b, 11111100b, 02, 00, 01, 01, 101b, 05, 00000000b, 00
List40 db 10000000b, 11111100b, 02, 00, 01, 01, 111b, 07, 00000000b, 00
List41 db 11000110b, 11111110b, 02, 00, 01, 02, 000b, 00, 00000000b, 00

.code
   mov AX, @data
   mov DS, AX
   mov BX, 81h ;; pirmas simbolio parametre adresas
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
;; Nuskaito dvieju failu vardus
   inc BX
   mov DI, offset File1
   call ReadFileName
   cmp CL, 'E'
   je WrongParams
   inc BX
   mov DI, offset RezFile
   call ReadFileName
   cmp CL, 'E'
   je WrongParams
;; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;; Nuskaito duomenis is failo
   mov DX, offset File1
   mov CX, offset Duom1
   call ReadFile
   push CX
   cmp CL, 'F'
   je NoFile
;; Atlieka skaiciavimus
   mov BX, ByteNumber
   call OpenFile
   _0b:
      mov BX, ByteNumber
      pop CX
      cmp BX, CX
      jge _03f
      push CX
      mov SI, offset Duom1
      mov DI, offset Rez
      mov DH, 0
      mov DL, [SI][BX]
   ;; nulina reikesmes ir padeda \N zenkla
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
      mov Nr, 9
      call CheckCommandByte
      call WriteLine
      inc ByteNumber
      inc BX
   jmp _0b
_03f:
   call CloseFile
;; Iraso i faila
   mov DX, offset Ok
   mov AH, 09h
   int 21h
jmp Exit0
WrongParams:
   mov DX, offset InvalidArguments
   mov AH, 09h
   int 21h
jmp Exit0
WriteInfo:
   mov DX, offset Banner
   mov AH, 09h
   int 21h
jmp Exit0
NoFile:
   push DX
   mov DX, offset NoSuchFile
   mov AH, 09h
   int 21h
   pop DX
   mov AH, 09h
   int 21h
   mov DX, offset Eol
   mov AH, 09h
   int 21h
Exit0:
   mov AX, 4c00h
   int 21h

ReadFileName proc
   mov CL, 'F'
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
   mov AH, 3dh ;; open
   mov AL, 02h
   int 21h
   jnc _07f ;; CF = 0 (no error)
      mov CL, 'F'
   jmp _08f
   _07f:
      mov BX, AX ;; File Handler
      mov DX, CX
      mov CX, 0ffh
      mov AH, 3fh ;; read
      int 21h
      mov CX, AX
      mov AH, 3eh ;; close
      int 21h
   _08f:
ret
ReadFile endp

OpenFile proc
   push AX
   push DX
   mov CX, 01000000b
   mov DX, offset RezFile
   mov AH, 3ch ;; Create
   int 21h
   mov FileHandler, AX
   pop DX
   pop AX
ret
OpenFile endp

WriteLine proc
   push BX
   push DX
   mov BX, FileHandler ;; FileHandler
   mov DX, offset Rez
   mov CX, 61
   mov AH, 40h ;; Write
   int 21h
   mov DX, offset Rez
   mov AH, 09h
   int 21h
   pop DX
   pop BX
ret
WriteLine endp

CloseFile proc
   push BX
   push AX
   mov BX, FileHandler
   mov AH, 3eh ;; close
   int 21h
   pop AX
   pop BX
ret
CloseFile endp

CheckCommandByte proc ;; DL: byte, BX: byte address
   call WriteAddress
   mov DH, DL
   mov SafeDX, DX
   mov SI, offset List01
   _3b:
      mov DX, SafeDX
      mov AL, [SI + 1]
      and DL, AL
      mov AL, [SI]
      cmp DL, AL
      jne _09f
         cmp byte ptr [SI + 2], 2
         jne _0bf
         call ReadOneMoreByte
         mov SafeDX, DX
         and DL, 00111000b
         shr DL, 3
         sub SI, 10
         _4b:
            add SI, 10
            cmp [SI + 6], DL
            je _0bf
         jmp _4b
      _09f:
      mov AX, offset ListEnd
      cmp SI, AX
      jge _0af
      add SI, 10
   jmp _3b
_0af:
jmp Exit1
_0bf:
   mov AL, [SI + 7]
   call WriteCommand
   and DL, 11110000b
   cmp DL, 01110000b
   jne _0cf
   ;; Conditional Jumps
      mov IsComJump, 1
      mov AL, DH
      and AL, 00001111b
      call WriteCommand
      mov AX, 30
      mov IsPosLinkis, 1
      call WriteJumpPosLinkis
   jmp Exit1
   _0cf:
   mov DL, DH
   mov AL, [SI + 8]
   cmp AL, 10000000b
   jne _10f
   ;; Command with no reg
      mov AL, [SI + 9]
      cmp AL, 0
      je _0ff
         cmp AL, 4
         je _0ef
            cmp AL, 0fh
            jg _0df
            ;; Free Operand
               mov IsPosLinkis, AL
               mov AX, 30
               call WriteFreeOperand
            jmp _0ff
            _0df:
         ;; PosLinkis
            and AL, 11110000b
            shr AL, 4
            mov IsPosLinkis, AL
            mov AX, 30
            call WriteJumpPosLinkis
         jmp _0ff
         _0ef:
         mov IsPosLinkis, 2
         mov AX, 37
         call WriteFreeOperand
         mov IsPosLinkis, 2
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
   ;; Has seg reg here
      mov IsRs, 1
      mov AL, [SI + 2]
      cmp AL, 1	;; if it has MOD, skip adding segment now
   je _12f	;; MOD will do it
      mov AL, [SI + 7]
      cmp AL, 15
      jne _11f
      ;; segmento keitimo komanda
         mov AX, 24
         call WriteSegReg
      jmp Exit1
      _11f:
   ;; eiline komanda su segmento registru
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
      ;; Normal
         mov AX, 30
         call WriteDirectAddress
         mov [DI + 38], ' ,'
         mov DL, DH
         mov AL, [SI + 8]
         and DL, AL
         and DL, 00001111b
         or DL, IsRw
         mov AX, 40
         call WriteReg
      jmp _14f
      _13f:
      ;; Reverse
         mov AX, 34
         call WriteDirectAddress
         mov [DI + 32], ' ,'
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
;; no MOD here..............................................
;; word or byte
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
   ;; has free operand
      call ReadOneMoreByte
      mov [DI + 35], AX
      mov [DI + 32], ' ,'
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
   ;; has two free operands
      call ReadOneMoreByte
      mov [DI + 37], AX
      call ReadOneMoreByte
      mov [DI + 35], AX
      mov [DI + 32], ' ,'
      mov byte ptr[DI + 34], '0'
      mov byte ptr[DI + 39], 'h'
   _1af:
jmp Exit1
HasMod:
;; has MOD here............................................
   cmp byte ptr [SI + 2], 2
   jne _1bf
      call CheckMod2
   jmp Exit1
   _1bf:
   call ReadOneMoreByte
   call CheckMod
jmp Exit1
Exit1:
ret
CheckCommandByte endp

ValueToHex proc ;; DL: 1-byte value to change
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
ValueToHex endp

WriteAddress proc ;; BX: address
   push BX
   push DX
   mov BX, ByteNumber
   add BX, PosLinkisOrg
   mov DL, BH
   call ValueToHex
   mov [DI + 0], AX
   mov DL, BL
   call ValueToHex
   mov [DI + 2], AX
   mov byte ptr [DI + 4], ':'
   pop DX	;; also writes the first byte
   pop BX
   call ValueToHex
   mov [DI + 6], AX
ret
WriteAddress endp

WriteCommand proc ;; AL: command num
   push SI
   push BX
   mov SI, offset Command
   cmp IsComJump, 1
   jne _20f
      mov SI, offset Jcc
      mov IsComJump, 0
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

WriteReg proc ;; DL: reg nr or Shifted MOD REG R/M, AX: position to write
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
      mov [DI], BX ;; iraso i eilute
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

WriteSegReg proc ;; DL: ComByte, AX: position to write
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
   mov [DI], BX ;; iraso i eilute
   sub DI, AX
   mov IsRs, 0
   pop SI
   pop DX
   pop BX
ret
WriteSegReg endp

WriteRegMemory proc ;; DH: ComByte, DL: MOD REG R/M, AX: position to write => AX: place to write next
   push BX
   push DX
   push SI
   push DI
   push AX
   mov DX, SafeDX
   mov BX, DX
   and BL, 11000111b
   cmp BL, 00000110b ;; Tiesioginis adresas, MOD = 00, r/m = 110
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
      ;; less than 5
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
ret
WriteRegMemory endp

WritePosLinkis proc
   push BX
   push CX
   push DX
   mov BX, AX
   mov CH, 0
   mov CL, IsPosLinkis
   cmp CL, 0
   je Exit3
;; Yra poslinkis
   mov [DI][BX], '+ '
   mov [DI][BX + 2], '0 '
   add BX, 4
   cmp CL, 1
   jne _26f
   ;; Vieno baito poslinkis
      call ReadOneMoreByte
      mov [DI + BX], AX
      mov byte ptr [DI][BX + 2], 'h'
      mov AX, BX
      add AX, 3
   jmp Exit3
   _26f:
;; Dvieju baitu poslinkis
   call ReadOneMoreByte
   mov [DI][BX + 2], AX
   call ReadOneMoreByte
   mov [DI][BX], AX
   mov byte ptr [DI][BX + 4], 'h'
   mov AX, BX
   add AX, 5
jmp Exit3
Exit3:
   pop DX
   pop CX
   pop BX
   mov IsPosLinkis, 0
ret
WritePosLinkis endp

WriteDirectAddress proc ;; AX: place where to write
   push BX
   push CX
   push DX
   mov BX, AX
   mov [DI][BX], '0['
   mov [DI][BX + 6], ']h'
   call ReadOneMoreByte
   mov [DI][BX + 4], AX
   call ReadOneMoreByte
   mov [DI][BX + 2], AX
   mov AX, BX
   pop DX
   pop CX
   pop BX
ret
WriteDirectAddress endp

WriteFreeOperand proc ;; IsPosLinkis: num of bytes, AX: place to write => AX: symbols written
   push BX
   push CX
   push DX
   mov BX, AX
   mov CH, 0
   mov CL, IsPosLinkis
   cmp CL, 0
   je Exit4
;; Yra Operandas
   cmp CL, 1
   jg _27f
   ;; Vieno baito Operandas
      call ReadOneMoreByte
      mov byte ptr [DI][BX], '0'
      mov [DI][BX + 1], AX
      mov byte ptr [DI][BX + 3], 'h'
      mov AX, 4
   jmp Exit4
   _27f:
;; Dvieju baitu Operandas
   mov byte ptr [DI][BX], '0'
   call ReadOneMoreByte
   mov [DI][BX + 3], AX
   call ReadOneMoreByte
   mov [DI][BX + 1], AX
   mov byte ptr [DI][BX + 5], 'h'
   mov AX, 6
jmp Exit4
Exit4:
   pop DX
   pop CX
   pop BX
   mov IsPosLinkis, 0
ret
WriteFreeOperand endp

WriteJumpPosLinkis proc ;; AX: place to write, IsPosLinkis: bytes poslinkio
   push BX
   push CX
   push DX
   mov BX, AX
   cmp IsPosLinkis, 0
   je _2af
   cmp IsPosLinkis, 1
   jne _29f
   ;; Vieno baito Jump poslinkis
      call ReadOneMoreByte
      mov CX, ByteNumber
      inc CX
      add CX, PosLinkisOrg
      mov DH, 0
      cmp DL, 080h
      jb _28f
         mov DH, 0ffh
      _28f:
      add CX, DX
   jmp _2af
   _29f:
   ;; Dvieju baitu Jump poslinkis
      call ReadOneMoreByte
      mov DH, DL
      call ReadOneMoreByte
      xchg DL, DH
      mov CX, ByteNumber
      inc CX
      add CX, PosLinkisOrg
      add CX, DX
   _2af:
   mov byte ptr [DI][BX + 4], 'h'
   mov DL, CH
   call ValueToHex
   mov [DI][BX + 0], AX
   mov DL, CL
   call ValueToHex
   mov [DI][BX + 2], AX
   mov IsPosLinkis, 0
   pop DX
   pop CX
   pop BX
ret
WriteJumpPosLinkis endp

ReadOneMoreByte proc ;; BX: last command num, Nr: where to put byte in line => AX: byte in hex, DL: byte
   push SI
   push BX
   mov BX, ByteNumber
   inc BX
   mov SI, offset Duom1
   mov DL, [SI][BX]
   mov ByteNumber, BX
   mov BX, Nr
   call ValueToHex
   mov [DI][BX], AX
   add BX, 3
   mov Nr, BX
   pop BX
   pop SI
ret
ReadOneMoreByte endp

CheckRv proc ;; SI: command prototype address, DH: ComByte
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

CheckSBit proc ;; DH: com byte, DL: MOD ... R/M byte, AX: where to write
   push BX
   push DX
   mov BX, AX
   cmp IsRw, 0
   jne _2ef
      mov IsPosLinkis, 1
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
      mov IsPosLinkis, 2
      call WriteFreeOperand
   jmp Exit5
   _30f:
;; Pleciama pagal pletimo taisykle
   call ReadOneMoreByte
   mov DH, 0
   cmp DL, 10000000b
   jb _31f
      mov DH, 0ffh
   _31f:
   call ValueToHex
   mov [DI][BX + 3], AX
   mov DL, DH
   call ValueToHex
   mov [DI][BX + 1], AX
   mov byte ptr [DI][BX + 0], '0'
   mov byte ptr [DI][BX + 5], 'h'
Exit5:
   pop DX
   pop BX
ret
CheckSBit endp

CheckMod proc ;; DH: command byte, DL: mod reg r/m
   push SI
   push BX
   push DX
   mov SafeDX, DX
   mov IsRw, 0
   mov IsPosLinkis, 0
   call CheckRv
   and DL, 11000000b
   cmp DL, 11000000b
   je _33f
      cmp DL, 00000000b
      jne _32f
      jmp _35f
      _32f:
         shr DL, 6
         mov IsPosLinkis, DL
      jmp _35f
   _33f:
;; args: DH: command byte, DL: mod reg r/m, SI: offset List??
   mov AL, [SI + 3]
   cmp AL, 1
   jne _34f
      and DH, 00000010b
      cmp DH, 00000010b
      mov DX, SafeDX
   je _34f
   ;; Direction Reverse 1
   ;; r/m <- reg // d = 0
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
      mov [DI + 32], ' ,'
   jmp Exit6
   _34f:
;; reg <- r/m // d = 1 or no at all
   and DL, 00111000b
   shr DL, 3
   or DL, IsRw
   mov AX, 30
   call WriteReg
   mov DX, SafeDX
   mov DX, SafeDX
   and DL, 00000111b
   or DL, IsRw
   mov AX, 34
   call WriteReg
   mov [DI + 32], ' ,'
jmp Exit6
_35f:
   mov AL, [SI + 3]
   cmp AL, 1
   jne _36f
      and DH, 00000010b
      cmp DH, 00000010b
      mov DX, SafeDX
   je _36f
   ;; Direction Reverse 2
   ;; r/m <- reg // d = 0
      mov AX, 30
      call WriteRegMemory
      call WritePosLinkis
      add DI, AX
      mov [DI], ' ,'
      sub DI, AX
      mov DX, SafeDX
      and DL, 00111000b
      shr DL, 3
      or DL, IsRw
      add AX, 2
      call WriteReg
   jmp Exit6
   _36f:
;; reg <- r/m // d = 1 or no at all
   mov AX, 34
   call WriteRegMemory
   call WritePosLinkis
   mov DX, SafeDX
   and DL, 00111000b
   shr DL, 3
   or DL, IsRw
   mov AX, 30
   call WriteReg
   mov [DI + 32], ' ,'
jmp Exit6
Exit6:
   pop DX
   pop BX
   pop SI
ret
CheckMod endp

CheckMod2 proc ;; SafeDX: DH: command byte, DL: mod reg r/m
   push SI
   push BX
   push DX
   mov DX, SafeDX
   mov IsRw, 0
   mov IsPosLinkis, 0
   call CheckRv
   and DL, 11000000b
   cmp DL, 11000000b
   je _38f
      cmp DL, 00000000b
      jne _37f
      jmp _3af
   _37f:
      shr DL, 6
      mov IsPosLinkis, DL
   jmp _3af
   _38f:
   ;; args: DH: command byte, DL: mod reg r/m, SI: offset List??
   ;; r/m(reg) <- (bop) // d = 0
      mov DX, SafeDX
      and DL, 00000111b
      or DL, IsRw
      mov AX, 30
      call WriteReg
      mov AL, [SI + 5]
      cmp AL, 0
      je _39f
         mov [DI + 32], ' ,'
         mov DX, SafeDX
         mov AX, 34
         call CheckSBit
      _39f:
   jmp Exit7
   _3af:
;; r/m <- (bop) // d = 0
   mov AX, 30
   cmp IsRw, 0
   jne _3bf
      mov [DI + 30], '.b'
      add AX, 2
   _3bf:
   cmp IsRw, 00001000b
   jne _3cf
      mov [DI + 30], '.w'
      add AX, 2
   _3cf:
   cmp IsRw, 00010000b
   jne _3df
      mov [DI + 30], 'wd'
      mov byte ptr [DI + 32], '.'
      add AX, 3
   _3df:
   call WriteRegMemory
   call WritePosLinkis
   cmp byte ptr [SI + 5], 0
   je _3ef
      add DI, AX
      mov [DI], ' ,'
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

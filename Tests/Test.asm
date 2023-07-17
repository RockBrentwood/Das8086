.model small
.stack 100h
.code
;; proc _memcpy		;; void memcpy(word De as [BP+2], word Ad as [BP+4], word N as [BP+6]);
   push BP		;; enter, using ES
   mov BP, SP
   push ES
   mov CX, [BP+6]	;; if ((CX = N) == 0) return 0;
   jcxz _1f
   mov SI, [BP+4]	;; DS:SI = Ad;
   mov DI, [BP+2]	;; ES:DI = De;
   push DS
   pop ES
   _1b:			;; do {
      mov AL, [SI]	;; *ES:DI = AL = *DS:SI;
      mov [DI], AL
      inc SI		;; DS:SI++;
      inc DI		;; ES:DI++;
      dec CX		;; CX--;
   jnz _1b		;; } while (CX != 0);
_1f:
   pop ES		;; leave;
   pop BP
   sub AX, AX		;; return 0;
ret
;; endp
end

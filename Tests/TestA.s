00000000  55                push bp
00000001  8BEC              mov bp,sp
00000003  06                push es
00000004  8B4E06            mov cx,[bp+0x6]
00000007  E311              jcxz 0x1a
00000009  8B7604            mov si,[bp+0x4]
0000000C  8B7E02            mov di,[bp+0x2]
0000000F  1E                push ds
00000010  07                pop es
00000011  8A04              mov al,[si]
00000013  8805              mov [di],al
00000015  46                inc si
00000016  47                inc di
00000017  49                dec cx
00000018  75F7              jnz 0x11
0000001A  07                pop es
0000001B  5D                pop bp
0000001C  2BC0              sub ax,ax
0000001E  C3                ret
0000001F  F38A02            rep mov al,[bp+si]
00000022  0000              add [bx+si],al
00000024  74                db 0x74

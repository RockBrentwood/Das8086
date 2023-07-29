0100: 55                PUSH  BP                            
0101: 8B EC             MOV   BP, SP                        
0103: 06                PUSH  ES                            
0104: 8B 4E 06          MOV   CX, [BP] + 006h               
0107: E3 11             JCXZ  011Ah                         
0109: 8B 76 04          MOV   SI, [BP] + 004h               
010C: 8B 7E 02          MOV   DI, [BP] + 002h               
010F: 1E                PUSH  DS                            
0110: 07                POP   ES                            
0111: 8A 04             MOV   AL, [SI]                      
0113: 88 05             MOV   [DI], AL                      
0115: 46                INC   SI                            
0116: 47                INC   DI                            
0117: 49                DEC   CX                            
0118: 75 F7             JNE   0111h                         
011A: 07                POP   ES                            
011B: 5D                POP   BP                            
011C: 2B C0             SUB   AX, AX                        
011E: C3                RET                                 
011F: F3                                                    
0120: 8A 02             MOV   AL, [BP+SI]                   
0122: 00 00             ADD   [BX+SI], AL                   
0124: 74 00             JE    0126h                         

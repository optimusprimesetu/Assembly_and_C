    ORG    $1000
START:
    MOVE.L #50, D0         ; Close any open files first
    TRAP   #15

    MOVE.L #51, D0         ; OPEN FILE
    LEA    FILENAME, A1   
    TRAP   #15             ; D1 HOLD FILE ID

    CMP.L  #$FFFFFFFF, D1  ; IF FILE DOES NOT EXIST
    BEQ    ERROR_EXIT

    MOVE.L #53, D0         ; READ FILE
    MOVE.L #1024, D2       ; Read 1024 BYTES
    LEA    FILE_BUFFER, A1 
    TRAP   #15            
    
    CMP.L  #0, D2          ; IF FILE IS EMPTY THEN EXIT
    BLE    ERROR_EXIT

    BSR    COUNT_WORDS     ; Results in D7

    ; Random Index: Time % WordCount
    MOVE.L #8, D0
    TRAP   #15            
    AND.L  #$0000FFFF, D1 
    DIVU.W D7, D1         
    SWAP   D1              ; Remainder in lower D1
    MOVE.W D1, D5          ; Target Word Index
    
    LEA    FILE_BUFFER, A0
    CLR.W  D6             
    BRA    FIND_WORD_LOOP


COUNT_WORDS:
    CLR.L  D7             
    LEA    FILE_BUFFER, A1
    MOVE.L D2, D3         
LOOP_COUNT_WORDS:
    MOVE.B (A1)+, D0      
    CMP.B  #10, D0        ; Look for Line Feed
    BNE    NOT_NEWLINE
    ADDQ.L #1, D7         
NOT_NEWLINE:
    SUBQ.L #1, D3
    BNE    LOOP_COUNT_WORDS
    MOVE.B -1(A1), D0
    CMP.B  #10, D0
    BEQ    COUNT_DONE
    ADDQ.L #1, D7         ; Count last word if no final \n
COUNT_DONE:
    RTS

FIND_WORD_LOOP:
    CMP.W  D5, D6         
    BEQ    COPY_START
SKIP_WORD:
    MOVE.B (A0)+, D0
    CMP.B  #10, D0        
    BNE    SKIP_WORD
    ADDQ.W #1, D6         
    BRA    FIND_WORD_LOOP

COPY_START:
    LEA    SECRET_BUF, A1
    CLR.W  D2             
COPY_CHAR:
    MOVE.B (A0)+, D0
    CMP.B  #0, D0         
    BEQ    FINISH_COPY
    CMP.B  #13, D0        ; Carriage Return
    BEQ    FINISH_COPY
    CMP.B  #10, D0        ; Line Feed
    BEQ    FINISH_COPY
    MOVE.B D0, (A1)+      
    ADDQ.W #1, D2         
    BRA    COPY_CHAR
FINISH_COPY:
    MOVE.B #0, (A1)       
    MOVE.W D2, WORD_LEN

    LEA    GUESS_BUF, A1
    MOVE.W WORD_LEN, D3
    SUBQ.W #1, D3         
FILL_MASK:
    MOVE.B #'_', (A1)+
    DBRA   D3, FILL_MASK
    MOVE.B #0, (A1)       
    MOVE.B #6, LIVES      

GAME_LOOP:
    MOVE.W #$FF00, D1      
    MOVE.L #11, D0         
    TRAP   #15

    MOVE.L #93, D0
    MOVE.L #2, D1
    TRAP   #15

    BSR    DRAW_GALLOWS
    MOVE.W #350, D5        ; X Offset for Stickman
    MOVE.W #100, D6        ; Y Offset for Stickman
    BSR    DRAW_STICKMAN

    LEA    OFFSET_NEWLINES, A1
    MOVE.L #14, D0
    TRAP   #15
    
    LEA    MSG_LIVES, A1
    TRAP   #15
    MOVE.L #3, D0          ; Print number
    CLR.L  D1
    MOVE.B LIVES, D1
    TRAP   #15

    LEA    NEWLINE, A1
    MOVE.L #14, D0
    TRAP   #15

    LEA    MSG_WORD, A1
    TRAP   #15
    LEA    GUESS_BUF, A1  
    TRAP   #15

    LEA    NEWLINE, A1
    MOVE.L #14, D0
    TRAP   #15

    LEA    MSG_PROMPT, A1
    TRAP   #15

    MOVE.L #5, D0         ; Get Char
    TRAP   #15
    
    ; Uppercase Conversion
    CMP.B  #'a', D1
    BLT    CHECK_MATCH
    CMP.B  #'z', D1
    BGT    CHECK_MATCH
    SUB.B  #32, D1        

CHECK_MATCH:
    LEA    SECRET_BUF, A0
    LEA    GUESS_BUF, A1
    MOVE.W WORD_LEN, D3
    SUBQ.W #1, D3
    CLR.B  D4             

SCAN_LOOP:
    CMP.B  (A0)+, D1      
    BNE    SKIP_REPLACE
    MOVE.B D1, (A1)       
    MOVE.B #1, D4         
SKIP_REPLACE:
    ADDQ.L #1, A1 
    DBRA   D3, SCAN_LOOP

    TST.B  D4
    BNE    CHECK_WIN
    
    SUBQ.B #1, LIVES
    BEQ    GAME_OVER_LOSE
    BRA    GAME_LOOP

CHECK_WIN:
    LEA    GUESS_BUF, A0
WIN_SCAN:
    MOVE.B (A0)+, D0 
    BEQ    GAME_OVER_WIN  
    CMP.B  #'_', D0
    BEQ    GAME_LOOP      
    BRA    WIN_SCAN

DRAW_GALLOWS:
    MOVEM.L D0-D4, -(A7)
    MOVE.L #84, D0         
    MOVE.W #150, D1        ; Base
    MOVE.W #250, D2
    MOVE.W #300, D3
    MOVE.W #250, D4
    TRAP   #15
    MOVE.W #225, D1        ; Pole
    MOVE.W #250, D2
    MOVE.W #225, D3
    MOVE.W #50, D4
    TRAP   #15
    MOVE.W #225, D1        ; Top Bar
    MOVE.W #50, D2
    MOVE.W #350, D3
    MOVE.W #50, D4
    TRAP   #15
    MOVE.W #350, D1        ; Rope
    MOVE.W #50, D2
    MOVE.W #350, D3
    MOVE.W #90, D4
    TRAP   #15
    MOVEM.L (A7)+, D0-D4
    RTS

DRAW_STICKMAN:
    MOVEM.L D0-D4/D7, -(A7)
    CLR.L   D7
    MOVE.B  LIVES, D7       
    CMP.B   #5, D7         ; Head
    BGT     DRAW_DONE       
    MOVE.L  #91, D0         
    MOVE.W  D5, D1
    SUB.W   #10, D1        
    MOVE.W  D6, D2
    SUB.W   #10, D2        
    MOVE.W  D5, D3
    ADD.W   #10, D3        
    MOVE.W  D6, D4
    ADD.W   #10, D4        
    TRAP    #15
    CMP.B   #4, D7         ; Spine
    BGT     DRAW_DONE       
    MOVE.L  #84, D0         
    MOVE.W  D5, D1
    MOVE.W  D6, D2
    ADD.W   #10, D2        
    MOVE.W  D5, D3
    MOVE.W  D6, D4
    ADD.W   #60, D4        
    TRAP    #15
    CMP.B   #3, D7         ; L Arm
    BGT     DRAW_DONE
    MOVE.W  D5, D1
    MOVE.W  D6, D2
    ADD.W   #25, D2
    MOVE.W  D5, D3
    SUB.W   #20, D3
    MOVE.W  D6, D4
    ADD.W   #40, D4
    TRAP    #15
    CMP.B   #2, D7         ; R Arm
    BGT     DRAW_DONE
    MOVE.W  D5, D1
    MOVE.W  D6, D2
    ADD.W   #25, D2
    MOVE.W  D5, D3
    ADD.W   #20, D3
    MOVE.W  D6, D4
    ADD.W   #40, D4
    TRAP    #15
    CMP.B   #1, D7         ; L Leg
    BGT     DRAW_DONE
    MOVE.W  D5, D1
    MOVE.W  D6, D2
    ADD.W   #60, D2
    MOVE.W  D5, D3
    SUB.W   #15, D3
    MOVE.W  D6, D4
    ADD.W   #90, D4
    TRAP    #15
    CMP.B   #0, D7         ; R Leg
    BGT     DRAW_DONE
    MOVE.W  D5, D1
    MOVE.W  D6, D2
    ADD.W   #60, D2
    MOVE.W  D5, D3
    ADD.W   #15, D3
    MOVE.W  D6, D4
    ADD.W   #90, D4
    TRAP    #15
DRAW_DONE:
    MOVEM.L (A7)+, D0-D4/D7
    RTS

GAME_OVER_WIN:
    LEA    MSG_REVEAL_W, A1
    MOVE.L #14, D0
    TRAP   #15
    LEA    GUESS_BUF, A1  
    TRAP   #15
    BRA    FINISH

GAME_OVER_LOSE:
    ; Draw the final limb one last time
    BSR    DRAW_STICKMAN 
    LEA    MSG_REVEAL, A1
    MOVE.L #14, D0
    TRAP   #15
    LEA    SECRET_BUF, A1
    TRAP   #15
    BRA    FINISH

ERROR_EXIT:
    LEA    MSG_ERR, A1
    MOVE.L #14, D0
    TRAP   #15

FINISH:
    MOVE.L #9, D0          ; Program halt
    TRAP   #15

FILENAME:       DC.B    'WORDS.BIN',0
NEWLINE:        DC.B    13,10,0
OFFSET_NEWLINES: DC.B   13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,0
MSG_LIVES:      DC.B    'Lives Left: ',0
MSG_WORD:       DC.B    'The Word:   ',0
MSG_PROMPT:     DC.B    'Guess a Letter: ',0
MSG_REVEAL_W:   DC.B    13,10,'CONGRATULATIONS! YOU SAVED HIM: ',0
MSG_REVEAL:     DC.B    13,10,'GAME OVER. THE WORD WAS: ',0
MSG_ERR:        DC.B    13,10,'CRITICAL ERROR: CHECK WORDS.BIN',0


WORD_LEN:       DS.W    1
LIVES:          DS.B    1
FILE_BUFFER:    DS.B    1024  
SECRET_BUF:     DS.B    64    
GUESS_BUF:      DS.B    64    

    END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

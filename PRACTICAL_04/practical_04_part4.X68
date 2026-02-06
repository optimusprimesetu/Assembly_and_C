    ORG    $1000
START:
    MOVE.L #51, D0        ; OPEN FILE
    LEA    FILENAME, A1   
    TRAP   #15            ; D1 HOLD FILE ID

    CMP.L  #$FFFFFFFF, D1 ; IF FILE DOES NOT EXIST
    BEQ    ERROR_EXIT

    MOVE.L #53, D0        ; READ FILE
    MOVE.L #1024, D2      ; Read 1024 BYTES
    LEA    FILE_BUFFER, A1 
    TRAP   #15            
    
    CMP.L  #0, D2         ; IF FILE IS EMPTY THEN EXIT
    BLE    ERROR_EXIT

    BSR COUNT_WORDS ; D7 - COUNT OF WORDS
    
    MOVE.L #8, D0
    TRAP #15      ; D1.L - CURRENT TIME IN 100THS OF A SECOND

    MOVE.W #1, D5 
    
    LEA    FILE_BUFFER, A0
    CLR.W  D6             ; Current Word Index
    
    JMP FIND_WORD_LOOP

COUNT_WORDS:
    ; A1 HAS FILE_BUFFER ADDRESS
    ; D7 WILL HAVE WORD COUNT
    ; D0 BYTE INDEX
    MOVE.L #0, D0
    BRA LOOP_COUNT_WORDS
    RTS
    
LOOP_COUNT_WORDS:
    CMP.B  #0, A1
    
    MOVE.B (A1)+, D0 ; CURRENT BYTE IN D0; A1 INCREMENTED AFTER
    CMP.B  #13, D0   ; \r
    BEQ    INCREMENT_LOOP_COUNT_WORDS
    
    
INCREMENT_LOOP_COUNT_WORDS:
    ADD.L #1, D7
    JMP LOOP_COUNT_WORDS
    
FIND_WORD_LOOP:
    CMP.W  D5, D6         ; Are we at the target word?
    BEQ    COPY_START

SKIP_WORD:
    MOVE.B (A0)+, D0      ; READ CHARA
    BEQ    ERROR_EXIT     ; End of file reached?
    CMP.B  #10, D0        ; Is it Line Feed (\n)?
    BNE    SKIP_WORD      ; If not, keep skipping
    ADDQ.W #1, D6         ; Found newline, increment index
    BRA    FIND_WORD_LOOP

COPY_START:
    LEA    SECRET_BUF, A1
    CLR.W  D2             ; Length counter

COPY_CHAR:
    MOVE.B (A0)+, D0
    BEQ    FINISH_COPY    ; End of buffer
    CMP.B  #13, D0        ; CR? Stop.
    BEQ    FINISH_COPY
    CMP.B  #10, D0        ; LF? Stop.
    BEQ    FINISH_COPY
    
    MOVE.B D0, (A1)+      ; Copy valid char
    ADDQ.W #1, D2         ; Length++
    BRA    COPY_CHAR

FINISH_COPY:
    MOVE.B #0, (A1)       ; Null terminate
    MOVE.W D2, WORD_LEN   ; Save length
    
    ; Safety check: Did we pick an empty line?
    TST.W  D2
    BEQ    ERROR_EXIT     ; If length is 0, quit (or you could retry)

    ; =============================================================
    ; 3. GAME INITIALIZATION
    ; =============================================================
    LEA    GUESS_BUF, A1
    MOVE.W WORD_LEN, D3
    SUBQ.W #1, D3         ; DBRA loop count (N-1)

FILL_MASK:
    MOVE.B #'_', (A1)+
    DBRA   D3, FILL_MASK
    MOVE.B #0, (A1)       ; Null terminate mask string
    
    MOVE.B #6, LIVES      ; Start lives

    ; =============================================================
    ; 4. MAIN GAME LOOP (RENDER & INPUT)
    ; =============================================================
GAME_LOOP:
    ; --- CLEAR SCREEN (Optional, usually Task 20) ---
    ; MOVE.L #20, D0
    ; TRAP   #15

    ; --- PRINT LIVES ---
    LEA    NEWLINE, A1
    MOVE.L #14, D0
    TRAP   #15
    
    LEA    MSG_LIVES, A1
    MOVE.L #14, D0
    TRAP   #15
    
    MOVE.L #3, D0         ; Print Number
    MOVE.B LIVES, D1
    AND.L  #$FF, D1       ; Clear trash bits
    TRAP   #15

    ; --- PRINT WORD MASK (e.g. "_ _ A _") ---
    LEA    NEWLINE, A1
    MOVE.L #14, D0
    TRAP   #15

    LEA    MSG_WORD, A1
    MOVE.L #14, D0
    TRAP   #15
    
    LEA    GUESS_BUF, A1  ; Print the underscores
    MOVE.L #14, D0
    TRAP   #15

    ; --- ASK FOR INPUT ---
    LEA    NEWLINE, A1
    MOVE.L #14, D0
    TRAP   #15

    LEA    MSG_PROMPT, A1
    MOVE.L #14, D0
    TRAP   #15

    MOVE.L #5, D0         ; Read Char into D1
    TRAP   #15
    
    ; --- LOGIC: CONVERT UPPERCASE ---
    CMP.B  #'a', D1
    BLT    CHECK_MATCH
    CMP.B  #'z', D1
    BGT    CHECK_MATCH
    SUB.B  #32, D1        ; 'a' -> 'A'


CHECK_MATCH:
    LEA    SECRET_BUF, A0
    LEA    GUESS_BUF, A1
    MOVE.W WORD_LEN, D3
    SUBQ.W #1, D3
    CLR.B  D4             ; D4 = Match Found Flag (0 = No, 1 = Yes)

SCAN_LOOP:
    CMP.B  (A0)+, D1      ; Compare Input vs Secret
    BNE    SKIP_REPLACE
    
    MOVE.B D1, (A1)       ; Reveal letter in Guess Buffer
    MOVE.B #1, D4         ; Set Flag = True

SKIP_REPLACE:
    ADDQ.L #1, A1 
    DBRA   D3, SCAN_LOOP

    TST.B  D4
    BNE    CHECK_WIN
    
    ; No match found
    SUBQ.B #1, LIVES
    BEQ    GAME_OVER_LOSE
    BRA    GAME_LOOP

CHECK_WIN:
    ; CHECK GUESSED BUFFER FOR UNDERSCORES
    LEA    GUESS_BUF, A0
    
WIN_SCAN:
    MOVE.B (A0)+, D0 ; POINT TO START OF THE GUESS BUFFER AND THEN INCREMENT THE POINTER
    BEQ    GAME_OVER_WIN ; 
    CMP.B  #'_', D0
    BEQ    GAME_LOOP ; IF UNDERSCORE FOUND '_' THEN CONTINUE THE GAME
    BRA    WIN_SCAN

GAME_OVER_WIN:
    LEA    NEWLINE, A1
    MOVE.L #14, D0
    LEA    MSG_REVEAL_W, A1
    TRAP   #15
    LEA    GUESS_BUF, A1  ; SHOW THE FULL WORD
    TRAP   #15
    BRA    FINISH

GAME_OVER_LOSE:
    ; REVEAL THE WORD AT THE END OF THE GAME
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
    SIMHALT

FILENAME:     DC.B    'WORDS.BIN',0
NEWLINE:      DC.B    13,10,0
MSG_LIVES:    DC.B    'Lives: ',0
MSG_WORD:     DC.B    'Word:  ',0
MSG_PROMPT:   DC.B    'Enter Letter: ',0
MSG_REVEAL_W: DC.B    13,10,'YOU GUESSED THE WORD: ',0
MSG_REVEAL:   DC.B    13,10,'THE WORD WAS: ',0
MSG_ERR:      DC.B    'PLEASE MAKE SURE FILE WORDS.BIN EXISTS AND CONTAINS A WORD PER LINE',0

WORD_LEN:    DS.W    1
LIVES:       DS.B    1

; Buffers
FILE_BUFFER: DS.B    1024  ; Raw file data
SECRET_BUF:  DS.B    64    ; The current correct answer
GUESS_BUF:   DS.B    64    ; The masked "___" string

    END START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

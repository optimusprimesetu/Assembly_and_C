ORG    $1000
START:
    ; --- YOUR FILE LOADING CODE ---
    MOVE.L #51, D0        ; OPEN FILE
    LEA    FILENAME, A1   ; Load address of filename
    TRAP   #15            ; File ID returned in D1

    MOVE.L #53, D0        ; READ FILE
    MOVE.L #256, D2       ; Read 256 bytes
    LEA    SECRET_BUF, A1 ; Read into SECRET_BUF (The answer)
    TRAP   #15            ; D2 = bytes read

    CMP.L  #0, D2         ; EXIT IF READ <= 0
    BLE    END_GAME
    
    MOVE.B #0, (A1, D2)   ; NULL terminate buffer
    
    ; --- SAVE WORD LENGTH ---
    ; D2 currently holds the length of the word read from file.
    ; We need to save this to know when to stop looping later.
    MOVE.W D2, WORD_LEN

    ; --- INITIALIZATION PHASE ---
    ; Copy underscores into GUESS_BUF based on length of SECRET_BUF
    LEA    SECRET_BUF, A0
    LEA    GUESS_BUF, A1
    MOVE.W WORD_LEN, D3   ; Counter
    SUBQ.W #1, D3         ; Adjust for DBRA (0-based)

INIT_MASK_LOOP:
    MOVE.B #'_', (A1)+    ; Put underscore in guess buffer
    DBRA   D3, INIT_MASK_LOOP
    MOVE.B #0, (A1)       ; Null terminate guess buffer

    MOVE.B #5, LIVES      ; Set Lives to 5

; --- MAIN GAME LOOP ---
GAME_LOOP:
    ; 1. Clear Screen (Optional, but nice. Task 20 is Clear Console)
    ; MOVE.L #20, D0
    ; TRAP   #15

    ; 2. Print Current Status
    LEA    MSG_WORD, A1   ; "Word: "
    MOVE.L #14, D0        ; Print String Task
    TRAP   #15
    
    LEA    GUESS_BUF, A1  ; The underscores "_____"
    MOVE.L #14, D0
    TRAP   #15
    
    LEA    NEWLINE, A1
    MOVE.L #14, D0
    TRAP   #15
    
    LEA    MSG_GUESS, A1  ; "Enter Letter: "
    MOVE.L #14, D0
    TRAP   #15

    ; 3. Get User Input
    MOVE.L #5, D0         ; Task 5: Read Character to D1.B
    TRAP   #15
    
    ; Convert to Uppercase (Simple trick: AND with roughly 11011111)
    ; Assuming simple ASCII. If 'a' (97), sub 32 -> 'A' (65)
    CMP.B  #'a', D1
    BLT    CHECK_LOGIC    ; If less than 'a', assume it's uppercase
    CMP.B  #'z', D1
    BGT    CHECK_LOGIC    ; If greater than 'z', ignore
    SUB.B  #32, D1        ; Convert lower to upper

    ; 4. Check the Letter
CHECK_LOGIC:
    LEA    SECRET_BUF, A0 ; Pointer to answer
    LEA    GUESS_BUF, A1  ; Pointer to guesses
    MOVE.W WORD_LEN, D3   ; Loop counter
    SUBQ.W #1, D3         
    
    MOVE.B #0, D4         ; D4 will be our "Did we match?" flag (0=No, 1=Yes)

SCAN_WORD:
    CMP.B  (A0)+, D1      ; Compare Input (D1) with Secret (A0)
    BNE    NO_MATCH_HERE
    
    ; -- WE HAVE A MATCH --
    MOVE.B D1, (A1)       ; Write the letter into the Guess Buffer
    MOVE.B #1, D4         ; Set Flag: We found a match!

NO_MATCH_HERE:
    ADDQ.L #1, A1         ; Move guess pointer forward
    DBRA   D3, SCAN_WORD  ; Loop for length of word

    ; 5. Update Lives or Check Win
    TST.B  D4             ; Check if we found a match (D4 == 1?)
    BNE    CHECK_WIN      ; If match, check if we won
    
    ; -- WRONG GUESS --
    SUBQ.B #1, LIVES      ; Lives--
    BEQ    GAME_OVER_LOSE ; If Lives == 0, Lose
    BRA    GAME_LOOP      ; Else, try again

CHECK_WIN:
    ; Check if there are any underscores left in GUESS_BUF
    LEA    GUESS_BUF, A0
CHECK_WIN_LOOP:
    CMP.B  #0, (A0)       ; End of string?
    BEQ    GAME_OVER_WIN  ; If we hit NULL without finding '_', we won!
    CMP.B  #'_', (A0)+    ; Is it an underscore?
    BEQ    GAME_LOOP      ; If yes, game continues
    BRA    CHECK_WIN_LOOP

; --- ENDINGS ---
GAME_OVER_LOSE:
    LEA    MSG_LOSE, A1
    MOVE.L #14, D0
    TRAP   #15
    BRA    END_GAME

GAME_OVER_WIN:
    LEA    GUESS_BUF, A1  ; Show the full word one last time
    MOVE.L #14, D0
    TRAP   #15
    LEA    MSG_WIN, A1
    MOVE.L #14, D0
    TRAP   #15

END_GAME:
    SIMHALT

; --- DATA SECTION ---
FILENAME:    DC.B    'WORDS.BIN',0
MSG_WORD:    DC.B    13,10,'Current Word: ',0  ; 13,10 is Newline
MSG_GUESS:   DC.B    13,10,'Guess a letter: ',0
MSG_WIN:     DC.B    13,10,'YOU WIN!',0
MSG_LOSE:    DC.B    13,10,'GAME OVER.',0
NEWLINE:     DC.B    13,10,0

LIVES:       DS.B    1
WORD_LEN:    DS.W    1

; Buffers
SECRET_BUF:  DS.B    256   ; The word read from file
GUESS_BUF:   DS.B    256   ; The word shown to user (___)

    END START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

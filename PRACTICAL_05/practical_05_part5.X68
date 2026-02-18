    ORG    $1000

; --- CONSTANTS ---
DAMAGE        EQU     10              ; Damage when Collisions occur
POWER_UP_HEAL EQU     20

START:
    LEA     PLAYER_X, A2            ; Player will move along X axis
    LEA     ENEMY_POSITIONS, A3     ; Enemy positions or spawn points
    BRA     GAME_LOOP

GAME_LOOP:
    BSR     COUNT_ENEMIES           ; Count enemies
    MOVE.L  D0, D4                  ; Store count in D4

    LEA     MSG_GAMELOOP, A1        ; Load "Game Loop" message
    BSR     DRAW                    ; Print it (Task 14, cursor stays at end)
    
    LEA     CRLF, A1                ; Load New Line
    BSR     DRAW                    ; Print New Line (Cursor moves down)

    BSR     UPDATE                  ; Call UPDATE
    BRA     GAME_LOOP               ; Repeat

UPDATE:
    ; --- DISPLAY HEALTH ---
    LEA     MSG_HEALTH, A1
    BSR     DRAW                    ; Print "Health : "

    CLR.L   D1                      ; Clear D1 to remove junk data
    MOVE.B  PLAYER_HEALTH, D1       ; Load Health into D1
    MOVE.B  #3, D0                  ; TASK 3: Print Decimal Number
    TRAP    #15

    LEA     CRLF, A1                ; Print New Line
    BSR     DRAW

    BSR CHECK_POWER_UP

    ; --- DISPLAY POSITION ---
    LEA     MSG_POSITION, A1
    BSR     DRAW                    ; Print "Player X: "

    MOVE.L  PLAYER_X, D1            ; Load X Position (Longword) into D1
    MOVE.B  #3, D0                  ; TASK 3: Print Decimal Number
    TRAP    #15

    LEA     CRLF, A1                ; Print New Line
    BSR     DRAW

    ; --- GAME LOGIC ---
    CMP.B   #0, PLAYER_HEALTH       ; Check if Health <= 0
    BLE     GAME_OVER
    
    ADD.L   #1, PLAYER_X            ; Move Player
    BSR     COLLISION               ; Check Collisions
    RTS

DRAW:
    MOVE.B  #14, D0                 ; Task 14: Print String WITHOUT new line
    TRAP    #15
    RTS

CHECK_POWER_UP:
    MOVE.L  CURRENT_POWER_UP, D0
    LSL.L   #2, D0 ; multiply by 4 because each power up is a long
                   ; so to move in 4 bytes increments
    
    LEA     POWER_UPS,        A4
    
    MOVE.L  (A4, D0.L),       D2 
    
    CMP.L   #0, D2
    BEQ     POWER_DONE
    
    MOVE.L  PLAYER_X,         D3
    
    CMP.L   D2, D3
    BNE     POWER_DONE
    
    ADD.B   #POWER_UP_HEAL, PLAYER_HEALTH
    ADD.L   #1, CURRENT_POWER_UP
POWER_DONE:
    RTS

COLLISION:
    LEA     ENEMY_POSITIONS, A3     ; Reset pointer to start of enemies
    
COLLISION_LOOP:
    MOVE.L  (A3)+, D2               ; Get Enemy X (Longword)
    BEQ     COLLISION_DONE          ; If 0 (Terminator), we are done checking
    
    MOVE.L  PLAYER_X, D3            ; Get Player X (Longword)
    CMP.L   D2, D3                  ; Compare them
    BEQ     REDUCE_HEALTH           ; Hit!
    BRA     COLLISION_LOOP          ; Check next enemy

REDUCE_HEALTH:
    LEA     MSG_COLLISION, A1
    BSR     DRAW
    LEA     CRLF, A1
    BSR     DRAW

    SUB.B   #DAMAGE, PLAYER_HEALTH

    LEA     MSG_DAMAGE, A1
    BSR     DRAW
    LEA     CRLF, A1
    BSR     DRAW
    
    ; We fall through to COLLISION_DONE to return safely to UPDATE

COLLISION_DONE:
    RTS

GAME_OVER:
    LEA     MSG_GAMEOVER, A1
    BSR     DRAW
    STOP    #$2700

COUNT_ENEMIES:
    CLR.L   D0                      ; Initialize counter to 0
    LEA     ENEMY_POSITIONS, A0     ; Load Address of Array

COUNT_LOOP:
    TST.L   (A0)+                   ; Test Longword (4 bytes)
    BEQ     END_COUNTING            ; If 0, end
    ADD.L   #1, D0                  ; Increment counter
    BRA     COUNT_LOOP

END_COUNTING:
    RTS

PLAYER_X         DC.L    1
PLAYER_HEALTH    DC.B    100
MSG_HEALTH       DC.B    'Health : ', 0
MSG_POSITION     DC.B    'Player X: ', 0
MSG_GAMELOOP     DC.B    'Game Loop', 0
MSG_COLLISION    DC.B    'Collision', 0
MSG_GAMEOVER     DC.B    'Game Over', 0
MSG_DAMAGE       DC.B    'Taking Damage', 0
CRLF             DC.B    $0D, $0A, 0

EVEN

ENEMY_POSITIONS  DC.L    20, 30, 40, 50, 60, 70, 80, 90, 200, 300, 500, 0
POWER_UPS        DC.L    10, 55, 220, 0
CURRENT_POWER_UP DC.L    0

    END     START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

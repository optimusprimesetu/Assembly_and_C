    ORG    $1000
START:
    ; --- SETUP POINTERS ---
    LEA    PLAYER_BASE, A0    ; A0 points to Player Data Block
    LEA    BOSS_BASE, A1      ; A1 points to Boss Data Block
    LEA    GAME_STATE, A2     ; A2 points to General Game State

    ; --- EXAMPLE SET 1: PLAYER DATA (Using A0) ---
    ; 1. Player Health (Byte) - Start at 100% ($64)
    
    MOVE.B #$64, (A0)         
    
    ; 2. Player Max Health (Byte) - Offset by 1
    MOVE.B #$64, 1(A0)        
    
    ; 3. Player X Position (Word) - Offset by 2. Set to 500
    MOVE.W #500, 2(A0)        
    
    ; 4. Player Y Position (Word) - Offset by 4. Set to 100
    MOVE.W #100, 4(A0)        

    ; 5. Player Lives (Byte) - Offset by 6. Start with 3 lives.
    MOVE.B #3, 6(A0)

    ; --- EXAMPLE SET 2: BOSS DATA (Using A1) ---
    ; 6. Boss Health (Word) - Bosses have more HP (1000 = $03E8)
    MOVE.W #1000, (A1)

    ; 7. Boss X Position (Word)
    MOVE.W #800, 2(A1)

    ; 8. Boss Y Position (Word)
    MOVE.W #100, 4(A1)

    ; 9. Boss Type/ID (Byte)
    MOVE.B #1, 6(A1)

    ; --- EXAMPLE SET 3: GLOBAL GAME STATE (Using A2) ---
    ; 10. Current Score (Long Word) - Score can be huge, use .L
    MOVE.L #0, (A2)           ; Start score at 0

    ; 11. High Score (Long Word) 
    MOVE.L #50000, 4(A2)      ; Previous high score

    ; 12. Level Number (Byte)
    MOVE.B #1, 8(A2)

    SIMHALT

; --- MEMORY RESERVATION ---
; We use DS (Define Space) to reserve empty room for our variables
PLAYER_BASE:    DS.B 10       ; Reserve 10 bytes for player

; typedef struct {
;   char  health;    // offset: 0
;   char  max_health // offset: 1
;   short x;         // offset: 2
;   short y          // offset: 4
;   char lives;      // offset: 6
; } player_t;   

BOSS_BASE:      DS.B 10       ; Reserve 10 bytes for boss
GAME_STATE:     DS.B 20       ; Reserve 20 bytes for game state

    END    START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

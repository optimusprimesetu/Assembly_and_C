ORG    $1000
START:
    ; --- SETUP POINTERS ---
    LEA    PLAYER_BASE, A0    ; A0 -> player_t
    LEA    BOSS_BASE, A1      ; A1 -> boss_t
    LEA    GAME_STATE, A2     ; A2 -> game_state_t

    ; --- PLAYER DATA ---
    MOVE.B #$64, (A0)         ; health
    MOVE.B #$64, 1(A0)        ; max_health
    MOVE.W #500, 2(A0)        ; x
    MOVE.W #100, 4(A0)        ; y
    MOVE.B #3, 6(A0)          ; lives

    ; --- BOSS DATA ---
    MOVE.W #1000, (A1)        ; health (Word)
    MOVE.W #800, 2(A1)        ; x
    MOVE.W #100, 4(A1)        ; y
    MOVE.B #1, 6(A1)          ; boss_id

    ; --- GLOBAL GAME STATE ---
    MOVE.L #0, (A2)           ; score (Long)
    MOVE.L #50000, 4(A2)      ; high_score (Long)
    MOVE.B #1, 8(A2)          ; level

    SIMHALT

; --- MEMORY RESERVATION & C-STRUCTURE DEFINITIONS ---

; typedef struct {
;   unsigned char health;     // offset 0 (1 byte)
;   unsigned char max_health; // offset 1 (1 byte)
;   short         x;          // offset 2 (2 bytes)
;   short         y;          // offset 4 (2 bytes)
;   unsigned char lives;      // offset 6 (1 byte)
; } player_t;                 // total: 7 bytes
PLAYER_BASE:    DS.B 7        

; typedef struct {
;   short         health;     // offset 0 (2 bytes)
;   short         x;          // offset 2 (2 bytes)
;   short         y;          // offset 4 (2 bytes)
;   unsigned char boss_id;    // offset 6 (1 byte)
; } boss_t;                   // total: 7 bytes
BOSS_BASE:      DS.B 7        

; typedef struct {
;   unsigned int  score;      // offset 0 (4 bytes)
;   unsigned int  high_score; // offset 4 (4 bytes)
;   unsigned char level;      // offset 8 (1 byte)
; } game_state_t;             // total: 9 bytes
GAME_STATE:     DS.B 9        

    END    START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

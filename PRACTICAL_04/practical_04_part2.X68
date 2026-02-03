*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

    ; Health byte at $3000
    MOVE.B #100, $3000
    
        MOVE.B #100, $3000
    
    ; Move location of NPC into Data Register
    MOVE.B #$12, D2 ; X
    MOVE.B #$22, D3 ; Y
    
    ; Bitwise AND D2 and D3
    AND.B D2, D3
    
    ; Health (Byte) address at A1 register
    LEA $3000, A1    ; Health (Byte) address at A1 register
    LEA $3000, A1
    
    ; Hit by NPC
    SUB.B #20, (A1)
    
    ; Pickup health found
    ADD.B #10, (A1)
    
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

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
    
    ; Health (Byte) address at A1 register
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

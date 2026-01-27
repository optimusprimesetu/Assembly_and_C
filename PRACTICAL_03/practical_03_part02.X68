ORG    $1000
START:
    LEA    $4000, A2      ; Point A2 to memory address $4000
    MOVE.B #100, (A2)     ; Move 100 (Hex $64) to address $4000
    SUB.B  #10, (A2)      ; Subtract 10 from the value currently living at address $4000

    SIMHALT

    END    START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

    ORG    $1000
START:
    LEA    $4000, A1      ; Load Effective Address $4000 into Address Register 1
    MOVE.B #100, (A1)     ; Move value 100 into the memory location A1 is pointing to

    SIMHALT               ; Halt the simulator

    END    START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

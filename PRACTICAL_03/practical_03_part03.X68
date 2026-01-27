    ORG    $1000
START:
    LEA    HEALTH, A3     ; Load the address of the label 'HEALTH' into A3
    SUB.B  #10, (A3)      ; Subtract 10 from the value found at that address

    SIMHALT

HEALTH  DC.B   $64        ; Define Constant Byte: Initialize 'HEALTH' with Hex $64 (100 decimal)

    END    START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

    LEA    STRING, A1

    MOVE.B #13, D0
    TRAP   #15
    
    MOVE.B #14, D0
    TRAP   #15
    
    MOVE.B #2, D0
    TRAP   #15
    
    
    MOVE.L #-6, D1
    MOVE.B #4,  D2
    MOVE.B #20, D0
    TRAP   #15

    MOVE.B #4, D0
    TRAP   #15
    
    SIMHALT             ; halt simulator


STRING: DC.B 'STRING',0

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

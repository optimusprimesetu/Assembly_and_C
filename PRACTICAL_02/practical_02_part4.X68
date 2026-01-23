    ORG     $1000
START:

    ; This code demonstrates the data movement flow for long, word, and byte lengths 
    ; each block shows loading literals into registers, moving data between registers, 
    ; and moving values between registers and specific memory addresses
    MOVE.L  #100,       D0
    MOVE.L  #$100,      D1
    MOVE.L  #%100,      D2

    MOVE.L  D0,         D3

    MOVE.L  D1,         $3000

    MOVE.L  $3000,      D4


    MOVE.W  #50,        D0
    MOVE.W  #$64,       D1
    MOVE.W  #%1010,     D2

    MOVE.W  D2,         D5

    MOVE.W  D1,         $3010

    MOVE.W  $3010,      D6

    MOVE.W  #100,       $3020

    MOVE.W  $3020,      D7


    MOVE.B  #10,        D0
    MOVE.B  #$0F,       D1
    MOVE.B  #%11110000, D2

    MOVE.B  D2,         D3

    MOVE.B  D1,         $3030

    MOVE.B  $3030,      D4

    MOVE.B  #$55,       $3040
    MOVE.B  #%10101010, $3050

    SIMHALT
    END     START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

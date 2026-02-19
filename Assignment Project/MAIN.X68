*-----------------------------------------------------------
* Title      : Game Starter Kit - Rhythm Cyclist Edition
* Written by : Philip Bourke (Mod by Gemini)
* Date       : 05/02/2026
* Description: Vector Cyclist (Circles/Spokes), Full HUD
*-----------------------------------------------------------
    ORG    $1000
START:                ; first instruction of program

*-----------------------------------------------------------
* Section       : Trap Codes
*-----------------------------------------------------------
TC_SCREEN   EQU         33          
TC_S_SIZE   EQU         00          
TC_KEYCODE  EQU         19          
TC_DBL_BUF  EQU         92          
TC_CURSR_P  EQU         11          
TC_DELAY    EQU         23          
TC_TIME     EQU         08          
TC_EXIT     EQU         09          

*-----------------------------------------------------------
* Section       : Character Setup
*-----------------------------------------------------------
PLYR_W_INIT EQU         40          ; Extended to fit two wheels
PLYR_H_INIT EQU         20          

PLYR_DFLT_V EQU         00          
PLYR_JUMP_V EQU        -15          
PLYR_DFLT_G EQU         01          

GND_TRUE    EQU         01          
GND_FALSE   EQU         00          

NOTE1_IDX   EQU         00          
NOTE2_IDX   EQU         01          
NOTE3_IDX   EQU         02          

ENMY_W_INIT EQU         15          
ENMY_H_INIT EQU         25          
ENMY_JUMP_V EQU        -12          

*-----------------------------------------------------------
* Section       : Game Stats
*-----------------------------------------------------------
POINTS      EQU         01          
SPACEBAR    EQU         $20         
ESCAPE      EQU         $1B         

*-----------------------------------------------------------
* Subroutine    : Initialise
*-----------------------------------------------------------
INITIALISE:
    BSR     NOTE1_LOAD                
    BSR     NOTE2_LOAD               
    BSR     NOTE3_LOAD               

    MOVE.B  #TC_SCREEN, D0          
    MOVE.L  #TC_S_SIZE, D1          
    TRAP    #15                     
    MOVE.W  D1,         SCREEN_H    
    SWAP    D1                      
    MOVE.W  D1,         SCREEN_W    

    CLR.L   D1                      
    MOVE.W  SCREEN_W,   D1          
    LSR.L   #1,         D1          
    SUB.L   #50,        D1          ; Offset player left
    MOVE.L  D1,         PLAYER_X    

    CLR.L   D1                      
    MOVE.W  SCREEN_H,   D1          
    LSR.L   #1,         D1          
    MOVE.L  D1,         PLAYER_Y    

    CLR.L   D1                      
    MOVE.L  #00,        D1          
    MOVE.L  D1,         PLAYER_SCORE

    MOVE.L  #PLYR_DFLT_V, PLYR_VELOCITY
    MOVE.L  #PLYR_DFLT_G, PLYR_GRAVITY
    MOVE.L  #GND_TRUE,  PLYR_ON_GND 

    CLR.L   D1                      
    MOVE.W  SCREEN_W,   D1          
    MOVE.L  D1,         ENEMY_X     

    CLR.L   D1                      
    MOVE.W  SCREEN_H,   D1          
    LSR.L   #1,         D1          
    MOVE.L  D1,         ENEMY_Y     

    MOVE.L  #00,        ENMY_VELOCITY
    MOVE.L  #01,        ENMY_GRAVITY
    MOVE.L  #GND_TRUE,  ENMY_ON_GND

    ; Enable double buffering
    MOVE.B  #TC_DBL_BUF,D0          
    MOVE.B  #17,        D1          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$FF00,     D1          
    TRAP    #15                     

    MOVE.L  #RHYTHM_2, RHYTHM_PTR   
    MOVE.W  #0, NOTE_INDEX          
    MOVE.B  #TC_TIME, D0
    TRAP    #15
    MOVE.L  D1, LOOP_START_TIME     

*-----------------------------------------------------------
* Subroutine    : Game Loop
*-----------------------------------------------------------
GAMELOOP:
    BSR     INPUT                   
    BSR     UPDATE                  
    BSR     IS_PLAYER_ON_GND        
    BSR     IS_ENEMY_ON_GND         
    BSR     CHECK_COLLISIONS        
    BSR     DRAW                    
    
    BSR     PLAY_DYNAMIC_RHYTHM     
    
    MOVE.L  #1,         D1          
    MOVE.B  #TC_DELAY,  D0          
    TRAP    #15                     
    BRA     GAMELOOP                

*-----------------------------------------------------------
* Subroutine    : Dynamic Rhythm Engine
*-----------------------------------------------------------
PLAY_DYNAMIC_RHYTHM:
    MOVEM.L D0-D4/A0, -(A7)         
    MOVE.B  #TC_TIME, D0
    TRAP    #15                     
    MOVE.L  D1, D3                  
    SUB.L   LOOP_START_TIME, D1     
    
    MOVE.L  RHYTHM_PTR, A0          
    MOVE.W  NOTE_INDEX, D2          
    MULU    #8, D2                  
    ADDA.L  D2, A0                  
    
    CMP.L   #$FFFFFFFF, (A0)        
    BEQ     RESET_MUSIC_LOOP
    CMP.L   (A0), D1                
    BLT     END_MUSIC_ROUTINE       

    MOVE.L  4(A0), D1               
    MOVE.B  #72, D0                 
    TRAP    #15
    ADD.W   #1, NOTE_INDEX          
    BRA     END_MUSIC_ROUTINE

RESET_MUSIC_LOOP:
    MOVE.W  #0, NOTE_INDEX          
    MOVE.L  D3, LOOP_START_TIME     

END_MUSIC_ROUTINE:
    MOVEM.L (A7)+, D0-D4/A0         
    RTS

*-----------------------------------------------------------
* Subroutines   : Input & Physics Updates
*-----------------------------------------------------------
INPUT:
    CLR.L   D1                      
    MOVE.B  #TC_KEYCODE,D0          
    TRAP    #15                     
    MOVE.B  D1,         D2          
    CMP.B   #00,        D2          
    BEQ     PROCESS_INPUT           
    TRAP    #15                     
    CMP.B   #$FF,       D1          
    BEQ     PROCESS_INPUT           
    RTS                             

PROCESS_INPUT:
    MOVE.L  D2,         CURRENT_KEY 
    CMP.L   #ESCAPE,    CURRENT_KEY 
    BEQ     EXIT                    
    CMP.L   #SPACEBAR,  CURRENT_KEY 
    BEQ     JUMP                    
    RTS                             

UPDATE:
    ; Player Physics
    MOVE.L  PLYR_VELOCITY, D1       
    ADD.L   PLYR_GRAVITY, D1        
    MOVE.L  D1,         PLYR_VELOCITY 
    ADD.L   PLAYER_Y,   D1          
    MOVE.L  D1,         PLAYER_Y    

    ; Enemy Physics
    MOVE.L  ENMY_VELOCITY, D1
    ADD.L   ENMY_GRAVITY, D1
    MOVE.L  D1,         ENMY_VELOCITY
    ADD.L   ENEMY_Y,    D1
    MOVE.L  D1,         ENEMY_Y

    ; Enemy Movement
    MOVE.L  ENEMY_X,    D1          
    CMP.L   #00,        D1          
    BLE     RESET_ENEMY_POSITION    
    SUB.L   #03,        ENEMY_X     

    CMP.L   #GND_TRUE,  ENMY_ON_GND
    BNE     UPDATE_DONE         
    MOVE.B  #TC_TIME,   D0
    TRAP    #15                     
    AND.L   #$3F,       D1          
    CMP.L   #$01,       D1          
    BEQ     ENEMY_JUMP              
UPDATE_DONE:
    RTS                             

ENEMY_JUMP:
    MOVE.L  #ENMY_JUMP_V, ENMY_VELOCITY
    MOVE.L  #GND_FALSE, ENMY_ON_GND
    RTS

RESET_ENEMY_POSITION:
    CLR.L   D1                      ; FIXED: Clears upper bits so X doesn't go negative
    MOVE.W  SCREEN_W,   D1          
    MOVE.L  D1,         ENEMY_X     
    BRA     UPDATE_DONE             ; Re-enters loop cleanly

*-----------------------------------------------------------
* Subroutine    : Draw Master
*-----------------------------------------------------------
DRAW: 
    ; Black Screen Wipe using Task 87 (Rectangle)
    MOVE.L  #$00000000, D1  
    MOVE.B  #80, D0         
    TRAP    #15
    MOVE.B  #81, D0         
    TRAP    #15
    
    MOVE.L  #0, D1          
    MOVE.L  #0, D2          
    CLR.L   D3
    MOVE.W  SCREEN_W, D3    
    CLR.L   D4
    MOVE.W  SCREEN_H, D4    
    MOVE.B  #87, D0         
    TRAP    #15
    
    MOVE.B  #82, D0         
    TRAP    #15

    ; Set Line Pen Width
    MOVE.W  #3, D1
    MOVE.B  #93, D0         
    TRAP    #15

    BSR     DRAW_PLYR_DATA          
    BSR     DRAW_PLAYER             
    BSR     DRAW_ENEMY              

    MOVE.B  #94, D0         
    TRAP    #15
    RTS                             

*-----------------------------------------------------------
* Subroutine    : Draw Helper (Line)
*-----------------------------------------------------------
DRAW_LINE:
    MOVE.B  #84, D0         ; Task 84: Draw line from X1,Y1 to X2,Y2
    TRAP    #15
    RTS

*-----------------------------------------------------------
* Subroutine    : Draw Cyclist
*-----------------------------------------------------------
DRAW_PLAYER:
    MOVEM.L D0-D7, -(A7)
    MOVE.L  #WHITE, D1          
    MOVE.B  #80, D0          
    TRAP    #15                     

    MOVE.L  PLAYER_X, D5            ; D5 = Base X
    MOVE.L  PLAYER_Y, D6            ; D6 = Base Y

    ; Rear Wheel (Unfilled Ellipse)
    MOVE.L D5, D1
    SUB.L #10, D1           ; LX
    MOVE.L D6, D2
    SUB.L #10, D2           ; UY
    MOVE.L D5, D3
    ADD.L #10, D3           ; RX
    MOVE.L D6, D4
    ADD.L #10, D4           ; LY
    MOVE.B #91, D0          ; Task 91: Unfilled Ellipse
    TRAP #15
    
    ; Rear Wheel Spokes
    MOVE.L D5, D1
    MOVE.L D6, D2
    SUB.L #10, D2
    MOVE.L D5, D3
    MOVE.L D6, D4
    ADD.L #10, D4
    BSR DRAW_LINE           ; Vertical Spoke

    MOVE.L D5, D1
    SUB.L #10, D1
    MOVE.L D6, D2
    MOVE.L D5, D3
    ADD.L #10, D3
    MOVE.L D6, D4
    BSR DRAW_LINE           ; Horizontal Spoke

    ; Front Wheel (Unfilled Ellipse)
    MOVE.L D5, D1
    ADD.L #30, D1           ; LX = Center(40) - 10
    MOVE.L D6, D2
    SUB.L #10, D2           ; UY
    MOVE.L D5, D3
    ADD.L #50, D3           ; RX = Center(40) + 10
    MOVE.L D6, D4
    ADD.L #10, D4           ; LY
    MOVE.B #91, D0
    TRAP #15

    ; Front Wheel Spokes
    MOVE.L D5, D1
    ADD.L #40, D1
    MOVE.L D6, D2
    SUB.L #10, D2
    MOVE.L D1, D3
    MOVE.L D6, D4
    ADD.L #10, D4
    BSR DRAW_LINE           ; Vertical Spoke

    MOVE.L D5, D1
    ADD.L #30, D1
    MOVE.L D6, D2
    MOVE.L D5, D3
    ADD.L #50, D3
    MOVE.L D6, D4
    BSR DRAW_LINE           ; Horizontal Spoke

    ; Bike Frame Triangles
    MOVE.L D5, D1           ; Rear hub
    MOVE.L D6, D2
    MOVE.L D5, D3           ; Bottom bracket
    ADD.L #15, D3
    MOVE.L D6, D4
    BSR DRAW_LINE           

    MOVE.L D3, D1
    MOVE.L D4, D2
    MOVE.L D5, D3           ; Seat
    ADD.L #10, D3
    MOVE.L D6, D4
    SUB.L #20, D4
    BSR DRAW_LINE           

    MOVE.L D3, D1
    MOVE.L D4, D2
    MOVE.L D5, D3           ; Back to rear hub
    MOVE.L D6, D4
    BSR DRAW_LINE           

    MOVE.L D5, D1           ; Seat
    ADD.L #10, D1
    MOVE.L D6, D2
    SUB.L #20, D2
    MOVE.L D5, D3           ; Handlebars
    ADD.L #35, D3
    MOVE.L D6, D4
    SUB.L #25, D4
    BSR DRAW_LINE           

    MOVE.L D3, D1
    MOVE.L D4, D2
    MOVE.L D5, D3           ; Bottom bracket
    ADD.L #15, D3
    MOVE.L D6, D4
    BSR DRAW_LINE           

    MOVE.L D5, D1           ; Handlebars
    ADD.L #35, D1
    MOVE.L D6, D2
    SUB.L #25, D2
    MOVE.L D5, D3           ; Front hub
    ADD.L #40, D3
    MOVE.L D6, D4
    BSR DRAW_LINE           

    ; Rider Head (Unfilled Ellipse)
    MOVE.L D5, D1
    ADD.L #5, D1            ; LX
    MOVE.L D6, D2
    SUB.L #40, D2           ; UY
    MOVE.L D5, D3
    ADD.L #15, D3           ; RX
    MOVE.L D6, D4
    SUB.L #30, D4           ; LY
    MOVE.B #91, D0
    TRAP #15

    ; Rider Body & Arms
    MOVE.L D5, D1
    ADD.L #10, D1
    MOVE.L D6, D2
    SUB.L #30, D2
    MOVE.L D5, D3
    ADD.L #10, D3
    MOVE.L D6, D4
    SUB.L #20, D4
    BSR DRAW_LINE           ; Back

    MOVE.L D5, D1
    ADD.L #10, D1
    MOVE.L D6, D2
    SUB.L #27, D2
    MOVE.L D5, D3
    ADD.L #35, D3
    MOVE.L D6, D4
    SUB.L #25, D4
    BSR DRAW_LINE           ; Arms

    ; Animated Legs
    MOVE.B  #TC_TIME, D0
    TRAP    #15
    BTST    #4, D1
    BNE     .DRAW_FRAME_B

.DRAW_FRAME_A:              ; Pedal Down
    MOVE.L D5, D1
    ADD.L #10, D1
    MOVE.L D6, D2
    SUB.L #20, D2           ; Hip
    MOVE.L D5, D3
    ADD.L #20, D3
    MOVE.L D6, D4
    SUB.L #10, D4           ; Knee
    BSR DRAW_LINE
    
    MOVE.L D3, D1
    MOVE.L D4, D2
    MOVE.L D5, D3
    ADD.L #15, D3
    MOVE.L D6, D4
    ADD.L #5, D4            ; Foot
    BSR DRAW_LINE
    BRA     .DRAW_DONE_P

.DRAW_FRAME_B:              ; Pedal Up
    MOVE.L D5, D1
    ADD.L #10, D1
    MOVE.L D6, D2
    SUB.L #20, D2           ; Hip
    MOVE.L D5, D3
    ADD.L #15, D3
    MOVE.L D6, D4
    SUB.L #25, D4           ; Knee High
    BSR DRAW_LINE
    
    MOVE.L D3, D1
    MOVE.L D4, D2
    MOVE.L D5, D3
    ADD.L #15, D3
    MOVE.L D6, D4
    SUB.L #5, D4            ; Foot High
    BSR DRAW_LINE

.DRAW_DONE_P:
    MOVEM.L (A7)+, D0-D7    
    RTS                             

*-----------------------------------------------------------
* Subroutine    : Draw Enemy
*-----------------------------------------------------------
DRAW_ENEMY:
    MOVEM.L D0-D7, -(A7)
    MOVE.L  #RED, D1          
    MOVE.B  #80, D0          
    TRAP    #15                     

    MOVE.L  ENEMY_X, D5
    MOVE.L  ENEMY_Y, D6

    ; Enemy Head (Unfilled Ellipse)
    MOVE.L D5, D1
    SUB.L #5, D1            ; LX
    MOVE.L D6, D2
    SUB.L #25, D2           ; UY
    MOVE.L D5, D3
    ADD.L #5, D3            ; RX
    MOVE.L D6, D4
    SUB.L #15, D4           ; LY
    MOVE.B #91, D0
    TRAP #15

    ; Enemy Body
    MOVE.L D5, D1
    MOVE.L D6, D2
    SUB.L #15, D2
    MOVE.L D5, D3
    MOVE.L D6, D4
    SUB.L #10, D4
    BSR DRAW_LINE

    ; Running Animation
    MOVE.B  #TC_TIME, D0
    TRAP    #15
    BTST    #4, D1
    BNE     .DRAW_EN_B

.DRAW_EN_A:                 ; Wide Stride
    MOVE.L D5, D1           ; Left Leg
    MOVE.L D6, D2
    SUB.L #10, D2
    MOVE.L D5, D3
    SUB.L #8, D3
    MOVE.L D6, D4
    BSR DRAW_LINE

    MOVE.L D5, D1           ; Right Leg
    MOVE.L D6, D2
    SUB.L #10, D2
    MOVE.L D5, D3
    ADD.L #8, D3
    MOVE.L D6, D4
    BSR DRAW_LINE

    MOVE.L D5, D1           ; Left Arm
    MOVE.L D6, D2
    SUB.L #13, D2
    MOVE.L D5, D3
    SUB.L #6, D3
    MOVE.L D6, D4
    SUB.L #13, D4
    BSR DRAW_LINE

    MOVE.L D5, D1           ; Right Arm
    MOVE.L D6, D2
    SUB.L #13, D2
    MOVE.L D5, D3
    ADD.L #6, D3
    MOVE.L D6, D4
    SUB.L #13, D4
    BSR DRAW_LINE
    BRA .DRAW_EN_DONE

.DRAW_EN_B:                 ; Crossed Legs
    MOVE.L D5, D1           ; Left Leg IN
    MOVE.L D6, D2
    SUB.L #10, D2
    MOVE.L D5, D3
    ADD.L #4, D3
    MOVE.L D6, D4
    BSR DRAW_LINE

    MOVE.L D5, D1           ; Right Leg IN
    MOVE.L D6, D2
    SUB.L #10, D2
    MOVE.L D5, D3
    SUB.L #4, D3
    MOVE.L D6, D4
    BSR DRAW_LINE

    MOVE.L D5, D1           ; Arms Down
    MOVE.L D6, D2
    SUB.L #13, D2
    MOVE.L D5, D3
    MOVE.L D6, D4
    SUB.L #8, D4
    BSR DRAW_LINE

.DRAW_EN_DONE:
    MOVEM.L (A7)+, D0-D7
    RTS                             

*-----------------------------------------------------------
* Subroutine    : Draw Player Data (Full Original HUD restored)
*-----------------------------------------------------------
DRAW_PLYR_DATA:
    CLR.L   D1                      
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0201,     D1          
    TRAP    #15                     
    LEA     SCORE_MSG,  A1          
    MOVE    #13,        D0          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0901,     D1          
    TRAP    #15                     
    MOVE.B  #03,        D0          
    MOVE.L  PLAYER_SCORE,D1         
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0202,     D1          
    TRAP    #15                     
    LEA     X_MSG,      A1          
    MOVE    #13,        D0          
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P, D0          
    MOVE.W  #$0502,     D1          
    TRAP    #15                     
    MOVE.B  #03,        D0          
    MOVE.L  PLAYER_X,   D1          
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$1002,     D1          
    TRAP    #15                     
    LEA     Y_MSG,      A1          
    MOVE    #13,        D0          
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$1202,     D1          
    TRAP    #15                     
    MOVE.B  #03,        D0          
    MOVE.L  PLAYER_Y,   D1          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0203,     D1          
    TRAP    #15                     
    LEA     V_MSG,      A1          
    MOVE    #13,        D0          
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0503,     D1          
    TRAP    #15                     
    MOVE.B  #03,        D0          
    MOVE.L  PLYR_VELOCITY,D1        
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$1003,     D1          
    TRAP    #15                     
    LEA     G_MSG,      A1          
    MOVE    #13,        D0          
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$1203,     D1          
    TRAP    #15                     
    MOVE.B  #03,        D0          
    MOVE.L  PLYR_GRAVITY,D1         
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0204,     D1          
    TRAP    #15                     
    LEA     GND_MSG,    A1          
    MOVE    #13,        D0          
    TRAP    #15                     
    
    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0604,     D1          
    TRAP    #15                     
    MOVE.B  #03,        D0          
    MOVE.L  PLYR_ON_GND,D1          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$2001,     D1          
    TRAP    #15                     
    LEA     KEYCODE_MSG, A1         
    MOVE    #13,        D0          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$3001,     D1          
    TRAP    #15                     
    MOVE.L  CURRENT_KEY,D1          
    MOVE.B  #03,        D0          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0205,     D1          
    TRAP    #15                     
    LEA     UPDATE_MSG, A1          
    MOVE    #13,        D0          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0206,     D1          
    TRAP    #15                     
    LEA     DRAW_MSG,   A1          
    MOVE    #13,        D0          
    TRAP    #15                     

    MOVE.B  #TC_CURSR_P,D0          
    MOVE.W  #$0207,     D1          
    TRAP    #15                     
    LEA     IDLE_MSG,   A1          
    MOVE    #13,        D0          
    TRAP    #15                     
    RTS 

*-----------------------------------------------------------
* Subroutines   : Ground & Collisions
*-----------------------------------------------------------
IS_PLAYER_ON_GND:
    CLR.L   D1                      
    MOVE.W  SCREEN_H,   D1          
    LSR.L   #1,         D1          
    MOVE.L  PLAYER_Y,   D2          
    CMP.L   D1,         D2          
    BGE     SET_ON_GROUND           
    MOVE.L  #GND_FALSE, PLYR_ON_GND 
    RTS                             

SET_ON_GROUND:
    MOVE.L  D1,         PLAYER_Y    
    MOVE.L  #00,        PLYR_VELOCITY 
    MOVE.L  #GND_TRUE,  PLYR_ON_GND 
    RTS

IS_ENEMY_ON_GND:
    CLR.L   D1
    MOVE.W  SCREEN_H,   D1
    LSR.L   #1,         D1
    MOVE.L  ENEMY_Y,    D2
    CMP.L   D1,         D2
    BGE     SET_ENMY_ON_GROUND
    MOVE.L  #GND_FALSE, ENMY_ON_GND
    RTS

SET_ENMY_ON_GROUND:
    MOVE.L  D1,         ENEMY_Y     
    MOVE.L  #00,        ENMY_VELOCITY
    MOVE.L  #GND_TRUE,  ENMY_ON_GND
    RTS

JUMP:
    CMP.L   #GND_TRUE,PLYR_ON_GND   
    BNE     JUMP_DONE               
    MOVE.L  #PLYR_JUMP_V,PLYR_VELOCITY 
JUMP_DONE:
    RTS                             

CHECK_COLLISIONS:
    MOVE.L  PLAYER_X, D1
    MOVE.L  ENEMY_X, D2
    ADD.L   #ENMY_W_INIT, D2
    CMP.L   D2, D1
    BGT     NO_COLLISION

    MOVE.L  PLAYER_X, D1
    ADD.L   #PLYR_W_INIT, D1
    MOVE.L  ENEMY_X, D2
    CMP.L   D2, D1
    BLT     NO_COLLISION

    MOVE.L  PLAYER_Y, D1
    MOVE.L  ENEMY_Y, D2
    ADD.L   #ENMY_H_INIT, D2
    CMP.L   D2, D1
    BGT     NO_COLLISION

    MOVE.L  PLAYER_Y, D1
    ADD.L   #PLYR_H_INIT, D1
    MOVE.L  ENEMY_Y, D2
    CMP.L   D2, D1
    BLT     NO_COLLISION

    MOVE.L  #0, PLAYER_SCORE
    RTS
NO_COLLISION:
    ADD.L   #POINTS, PLAYER_SCORE
    RTS

*-----------------------------------------------------------
* Subroutines   : Sounds Loading & Exit
*-----------------------------------------------------------
NOTE1_LOAD:
    LEA     NOTE1_WAV,  A1          
    MOVE    #NOTE1_IDX, D1          
    MOVE    #71,        D0          
    TRAP    #15                     
    RTS                             

NOTE2_LOAD:
    LEA     NOTE2_WAV,  A1          
    MOVE    #NOTE2_IDX, D1          
    MOVE    #71,        D0          
    TRAP    #15                     
    RTS                             

NOTE3_LOAD:
    LEA     NOTE3_WAV,  A1          
    MOVE    #NOTE3_IDX, D1          
    MOVE    #71,        D0          
    TRAP    #15                     
    RTS                             

EXIT:
    MOVE.B  #TC_EXIT,   D0          
    TRAP    #15                     
    SIMHALT

*-----------------------------------------------------------
* Section       : Data & Variables
*-----------------------------------------------------------
SCORE_MSG       DC.B    'Score : ', 0
KEYCODE_MSG     DC.B    'KeyCode : ', 0
JUMP_MSG        DC.B    'Jump....', 0
IDLE_MSG        DC.B    'Idle....', 0
UPDATE_MSG      DC.B    'Update....', 0
DRAW_MSG        DC.B    'Draw....', 0
X_MSG           DC.B    'X:', 0
Y_MSG           DC.B    'Y:', 0
V_MSG           DC.B    'V:', 0
G_MSG           DC.B    'G:', 0
GND_MSG         DC.B    'GND:', 0
EXIT_MSG        DC.B    'Exiting....', 0

WHITE           EQU     $00FFFFFF
RED             EQU     $000000FF   

SCREEN_W        DS.W    01
SCREEN_H        DS.W    01
CURRENT_KEY     DS.L    01
PLAYER_X        DS.L    01
PLAYER_Y        DS.L    01
PLAYER_SCORE    DS.L    01
PLYR_VELOCITY   DS.L    01
PLYR_GRAVITY    DS.L    01
PLYR_ON_GND     DS.L    01
ENEMY_X         DS.L    01
ENEMY_Y         DS.L    01
ENMY_VELOCITY   DS.L    01
ENMY_GRAVITY    DS.L    01
ENMY_ON_GND     DS.L    01

RHYTHM_PTR      DS.L    01      
NOTE_INDEX      DS.W    01      
LOOP_START_TIME DS.L    01      

RHYTHM_2:
    DC.L 30,  NOTE1_IDX     
    DC.L 60,  NOTE2_IDX     
    DC.L 90,  NOTE1_IDX     
    DC.L 150, NOTE3_IDX     
    DC.L $FFFFFFFF          

NOTE1_WAV       DC.B    'note1.wav',0
NOTE2_WAV       DC.B    'note2.wav',0
NOTE3_WAV       DC.B    'note3.wav',0

    END    START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

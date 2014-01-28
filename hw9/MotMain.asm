    NAME    MOTMAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             Motor Unit Main Loop                           ;
;                                 Homework  9                                ;
;                                  EE/CS  51                                 ;
;                                 Archan Luhar                               ;
;                                TA:  Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program initializes the hardware on the motor unit
;                   as well as the necessary timers
; Input:            Serial.
; Output:           Serial, Motors, Laser.
;
; User Interface:   Serial Input controls the motor unit.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    11/20/13  Archan Luhar     Created hw8main.asm. Contains main function
;                               that calls the test function.


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE    SEGMENT PUBLIC 'CODE'
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP


; External references
    EXTRN   InitCS:NEAR
    EXTRN   InitMotorTimers:NEAR
    EXTRN   InitParallel:NEAR
    EXTRN   InitSerialPort:NEAR
    EXTRN   InitSerialParser:NEAR
    EXTRN   InitEventQueue:NEAR
    EXTRN   DequeueEvent:NEAR
    EXTRN   EventHandler:NEAR


START:  
MAIN:
    MOV     AX, DGROUP              ; Initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; Initialize the data segment
    MOV     DS, AX

    CALL    InitCS                  ; Init chip select
    CALL    InitMotorTimers         ; Init motor timers and handlers
    CALL    InitParallel            ; Init parallel
    CALL    InitSerialPort          ; Init serial
    CALL    InitSerialParser        ; Init serial parser
    CALL    InitEventQueue          ; Init events
    
    STI
    
MotorMainLoop:                      ; Wait for things to happen
    CALL DequeueEvent               ; Dequeue event (blocking)
    CALL EventHandler               ; Call event handler with this event
    JMP MotorMainLoop

EndMain:
    HLT
    

CODE ENDS



DATA    SEGMENT PUBLIC  'DATA'

    ; Nothing in the data segment but need it for initializing DS

DATA    ENDS


STACK SEGMENT STACK 'STACK'

    DB      80 DUP ('Stack ')       ; 240 words

TopOfStack      LABEL   WORD
STACK  ENDS


    END START
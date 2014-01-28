    NAME    REMMAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                             Remote Unit Main Loop                          ;
;                                 Homework  9                                ;
;                                  EE/CS  51                                 ;
;                                 Archan Luhar                               ;
;                                TA:  Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program initializes the hardware on the remote unit
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
;    11/20/13  Archan Luhar     d


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE    SEGMENT PUBLIC 'CODE'
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP


; External references
    EXTRN   InitCS:NEAR
    EXTRN   InitRemoteTimers:NEAR
    EXTRN   InitSerialPort:NEAR
    EXTRN   InitDisplay:NEAR
    EXTRN   InitSwitches:NEAR
    EXTRN   InitKeyParser:NEAR
    EXTRN   InitSerialParser:NEAR
    EXTRN   DequeueEvent:NEAR
    EXTRN   EventHandler:NEAR
    EXTRN   InitEventQueue:NEAR


START:  
MAIN:
    CLI

    MOV     AX, DGROUP              ; Initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; Initialize the data segment
    MOV     DS, AX

    CALL    InitCS
    CALL    InitRemoteTimers
    CALL    InitSerialPort
    CALL    InitKeyParser
    CALL    InitSerialParser
    CALL    InitDisplay
    CALL    InitSwitches
    CALL    InitEventQueue
    
    STI
    
RemoteMainLoop:                     ; Wait for things to happen
    CALL DequeueEvent
    CALL EventHandler
    JMP RemoteMainLoop

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
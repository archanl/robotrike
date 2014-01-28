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
;
; Input:            Serial.
; Output:           Serial, Motors, Laser.
;
; User Interface:   Serial output controls the motor unit.
;                   Switch  6 - speed up
;                   Switch  7 - stop
;                   Switch  8 - slow down
;                   Switch  3 - turn left (rotate direction -5 degrees)
;                   Switch 11 - turn right (rotate direction +5 degrees)
;                   Switch 15 - Fire laser
;                   Switch 16 - Turn off laser
;                   Display shows current speed (0-100) when changing it.
;                   Display shows current direction (0-359) when changing it.
;                   Display shows current laser status (On or Off) when changes.
;
; Error Handling:   All serial output from motor unit is displayed. Thus,
;                   if it has error, it will output error string which will
;                   be displayed.
;                   Mostly bad serial characters are ignored / handled properly
;                   as not to mess up general functionality.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    11/28/13  Archan Luhar     Finished remote unit main loop


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

    CALL    InitCS                  ; Init chip select
    CALL    InitRemoteTimers        ; Init remote timers
    CALL    InitSerialPort          ; Init serial
    CALL    InitKeyParser           ; Init key parser
    CALL    InitSerialParser        ; Init serial char parser
    CALL    InitDisplay             ; Init display hardware/data
    CALL    InitSwitches            ; Init switches hardware/data
    CALL    InitEventQueue          ; Init events
    
    STI                             ; Enable interrupts, after initialization
    
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
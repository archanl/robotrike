    NAME    HW4MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW4MAIN                                  ;
;                             Homework 4 Main Loop                           ;
;                                  EE/CS 51                                  ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program allocates space for shared variables needed
;                   for the display routines. It also calls all the
;                   initialization and test functions.
;
; Input:            None.
; Output:           Display.
;
; User Interface:   None.
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
;    11/12/13  Archan Luhar     Created hw4main.asm. Contains main function
;                               that calls display initialization and test
;                               functions.
;    11/18/13  Archan Luhar     Finished documentation.


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE    SEGMENT PUBLIC 'CODE'
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP


; External references
    EXTRN   DisplayInit:NEAR
    EXTRN   DisplayTest:NEAR
    EXTRN   DisplayHex:NEAR
    EXTRN   DisplayNum:NEAR



START:  
MAIN:
    MOV     AX, DGROUP              ; Initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; Initialize the data segment
    MOV     DS, AX

    CALL    DisplayInit             ; Initialize the CS, timer, and interrupt
    
    STI                             ; Enable interrupts

    CALL    DisplayTest             ; Test out the display


CODE ENDS


DATA    SEGMENT PUBLIC  'DATA'

    ; Nothing in the data segment but need it for initializing DS

DATA    ENDS


STACK SEGMENT STACK 'STACK'

    DB      80 DUP ('Stack ')       ; 240 words

TopOfStack      LABEL   WORD
STACK  ENDS


    END START
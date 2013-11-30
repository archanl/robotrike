    NAME    HW6MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW5MAIN                                  ;
;                               Homework 5 Main                              ;
;                                  EE/CS 51                                  ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program initializes the proper hardware and memory
;                   for the purpose of testing out reading the target board's
;                   switches on the keypad.
;                   This main file calls a test function in order to initialize
;                   the testing environment. Calls are made by the switch
;                   routines to another test function EnqueueEvent which
;                   uses the display routines to display information about
;                   the key presses. Make sure debouncing and keypress-repeat
;                   work!
;
; Input:            Switches.
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
;    11/19/13  Archan Luhar     Created hw5main.asm. Contains main function
;                               that calls chip initialization functions, and
;                               test function..


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE    SEGMENT PUBLIC 'CODE'
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP


; External references
    EXTRN   InitCS:NEAR
    EXTRN   InitTimer:NEAR
    EXTRN   InitSwitches:NEAR
    EXTRN   InitDisplay:NEAR
    EXTRN   KeyTest:NEAR


START:  
MAIN:
    MOV     AX, DGROUP              ; Initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; Initialize the data segment
    MOV     DS, AX

    CALL    InitCS                  ; Initialize chip selects
    CALL    InitTimer               ; Initialize timer handlers and controllers
    CALL    InitDisplay             ; Initialize display variables
    CALL    InitSwitches            ; Initialize switches variables
    
    STI                             ; Enable interrupts so event handlers can
                                    ; function.
    
    CALL    KeyTest                 ; Test function will setup test environment

    
CODE ENDS


DATA    SEGMENT PUBLIC  'DATA'

    ; Nothing in the data segment but need it for initializing DS

DATA    ENDS


STACK SEGMENT STACK 'STACK'

    DB      80 DUP ('Stack ')       ; 240 words

TopOfStack      LABEL   WORD
STACK  ENDS


    END START
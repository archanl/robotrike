    NAME    HW6MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW6MAIN                                  ;
;                               Homework 6 Main                              ;
;                                  EE/CS 51                                  ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program initializes the proper hardware and memory
;                   for the purpose of testing out reading the target board's
;                   parallel output to the three motors and the on laser.
;
;                   This main file calls a test function in order to initialize
;                   the testing environment. Calls are made by the switch
;                   routines to another test function EnqueueEvent which
;                   uses the display routines to display information about
;                   the key presses. Make sure debouncing and keypress-repeat
;                   work!
;
; Input:            Switches.
; Output:           Parallel.
;
; User Interface:   None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      The fact that there are three motors is hard coded.
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
    EXTRN   InitTimer0:NEAR
    EXTRN   SetTimerInterrupts:NEAR
    EXTRN   InstallTimer0EventHandler:NEAR
    EXTRN   InitParallel:NEAR
    EXTRN   MotorTest:NEAR


START:  
MAIN:
    MOV     AX, DGROUP              ; Initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; Initialize the data segment
    MOV     DS, AX

    CALL    InitCS
    CALL    InitParallel            ; Initializes the parallel port

    CALL    InstallTimer0EventHandler ; Initialize timers and interrupts
    CALL    InitTimer0
    CALL    SetTimerInterrupts
    
    STI                             ; Enable interrupts so event handlers can
                                    ; function.
    
    CALL    MotorTest

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
    NAME    HW7MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW7MAIN                                  ;
;                               Homework 7 Main                              ;
;                                  EE/CS 51                                  ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program initializes the proper hardware and memory
;                   for the purpose of testing the serial interface on the
;                   target board.
;
;                   This main file calls the serial initialization function
;                   that sets up the serial port hardware and interrupt
;                   vector.
;                   
;                   It also calls a test function which sends over serial
;                   a series of messages. Then, this test function
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
    EXTRN   InitSerialPort:NEAR
    EXTRN   SerialIOTest :NEAR


START:  
MAIN:
    MOV     AX, DGROUP              ; Initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; Initialize the data segment
    MOV     DS, AX

    CALL    InitCS
    CALL    InitSerialPort            ; Initializes the serial port
    
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
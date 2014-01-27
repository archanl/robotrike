    NAME    HW8MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW8MAIN                                  ;
;                               Homework 8 Main                              ;
;                                  EE/CS 51                                  ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program initializes the segment registers and stack.
;                   Then it calls the test function which tests the serial
;                   character parser.
;
; Input:            None.
; Output:           None.
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
;    11/20/13  Archan Luhar     Created hw8main.asm. Contains main function
;                               that calls the test function.


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE    SEGMENT PUBLIC 'CODE'
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP


; External references
    EXTRN   InitCS:NEAR
    EXTRN   InitSerialParser:NEAR
    EXTRN   ParseTest:NEAR


START:  
MAIN:
    MOV     AX, DGROUP              ; Initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; Initialize the data segment
    MOV     DS, AX

    CALL    InitCS
    CALL    InitSerialParser
    
    STI
    
    CALL    ParseTest               ; Call parser test function

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
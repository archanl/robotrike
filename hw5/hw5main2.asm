    NAME    HW5MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW5MAIN                                  ;
;                        Homework 5 Main 2 - No Display                      ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program initializes the proper hardware and memory
;                   for the purpose of testing out reading the target board's
;                   switches on the keypad.
;                   This main file goes into an infinite loop so that the user
;					can halt and read the buffer written to by EnqueueEvent when
;					keys are pressed. dump EventBuf 100H to read test buffer.
;					To be used with HW5TEST.
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
; 	11/19/13  	Archan Luhar	Created hw5main.asm. Contains main function
;                               that calls chip initialization functions, and
;                               test function..
;	11/27/13	Archan Luhar	Doesn't call function in HW54TEST. To be used
;								with HW5TEST and key presses read in buffer.


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE    SEGMENT PUBLIC 'CODE'
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP


; External references
    EXTRN   InitCS:NEAR
    EXTRN   InitTimer:NEAR
    EXTRN   InitSwitches:NEAR
    EXTRN   InitDisplay:NEAR


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

EndlessLoop:
	JMP EndlessLoop					; Infinite loop to wait for key presses
									; that get written to a buffer by the test
									; file.

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
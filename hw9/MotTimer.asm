    NAME    MOTTIMER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   MOTTIMER                                 ;
;                      Timer 0 (for motors) Setup Functions                  ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions to initialize the timers and their event
; handlers.
;
; The included public functions are:
;   - InitMotorTimers
;           Initializes the timers and their interrupts
;
;
; Revision History:
;       11/12/2013      Archan Luhar    Adopted Glen George's timer code
;                                       for the display assignment.
;       11/18/2013      Archan Luhar    Cleaned up formatting and commenting.
;        1/27/2014      Archan Luhar    Modified for motor timers only


; Local include files
$INCLUDE(timer.inc)     ; Contains various addresses and values related to
                        ; interrupt and timer behavior
$INCLUDE(general.inc)


CGROUP  GROUP   CODE
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

; External references
; All non-meta timer event handlers should be listed here
    EXTRN   ParallelTimerEventHandler:NEAR


; InitMotorTimers
;
; Description:      Initializes timer and event handler for timer 0, the timer
;                   used by the motors.
;
; Operation:        Install Timer0EventHandler into Tmr0Vec.
;                   Initialize Timer 0 counts and enable interrupt.
;                   Initalize interrupt controller for timer interrupts.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  DX = out register, AL = out value
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           Control registers
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      3 words (2 here and 1 in InstallVector macro)
;
; Author:           Archan Luhar
; Last Modified:    Jan. 27, 2014

InitMotorTimers             PROC    NEAR
                            PUBLIC  InitMotorTimers
    
    PUSH AX
    PUSH DX

    %InstallVector(Tmr0Vec, Timer0EventHandler)
    
    ; Timer 0
    MOV     DX, Tmr0Count       ; Initialize the count register to 0
    XOR     AX, AX
    OUT     DX, AL

    MOV     DX, Tmr0MaxCntA     ; Setup max count for 0.25 ms
    MOV     AX, TIMER_0_MAX_COUNT_VAL
    OUT     DX, AL

    MOV     DX, Tmr0Ctrl        ; Setup control register, enable interrupts
    MOV     AX, Tmr0CtrlVal
    OUT     DX, AL

    ; Timer Interrupt Control
                                ; Initialize interrupt controller for timers
    MOV     DX, INTCtrlrCtrl    ; Setup the interrupt control register
    MOV     AX, INTCtrlrCVal
    OUT     DX, AL

    MOV     DX, INTCtrlrEOI     ; Send a timer EOI (to clear out controller)
    MOV     AX, TimerEOI
    OUT     DX, AL
    
    POP DX
    POP AX

    RET

InitMotorTimers                   ENDP




; Timer0EventHandler
;
; Description:      Handles the timer 0 interrupts. Calls all functions that
;                   rely on timer 0 events.
;
; Operation:        Calls the parallel timer event handler.
;                   Sends a timer EOI to the interrupt control register.
;                   Then returns using IRET.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      2 words and a NEAR call.
;
; Author:           Glen George, Archan Luhar
; Last Modified:    Dec. 1, 2013

Timer0EventHandler          PROC    NEAR

    PUSH DX
    PUSH AX

    CALL ParallelTimerEventHandler

    MOV DX, INTCtrlrEOI             ; Send timer EOI
    MOV AX, TimerEOI
    OUT DX, AL

    POP AX
    POP DX
    IRET                            ; IRET must be used in interrupt handler

Timer0EventHandler          ENDP



CODE ENDS
    END
    NAME    REMTIMER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   REMTIMER                                 ;
;                   Timer 2 (for switch/display) Setup Functions             ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                TA:  Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains functions to initialize the timers and their event
; handlers.
;
; The included public functions are:
;   - InitRemoteTimers
;           Initializes the timers and their interrupts
;
;
; Revision History:
;       11/12/2013      Archan Luhar    Adopted Glen George's timer code
;                                       for the display assignment.
;       11/18/2013      Archan Luhar    Cleaned up formatting and commenting.
;        1/27/2014      Archan Luhar    Modified for remote timers only


; Local include files
$INCLUDE(timer.inc)     ; Contains various addresses and values related to
                        ; interrupt and timer behavior
$INCLUDE(general.inc)


CGROUP  GROUP   CODE
    ASSUME  CS:CGROUP, ES:NOTHING

CODE    SEGMENT PUBLIC 'CODE'

; External references
; All non-meta timer event handlers should be listed here
    EXTRN   DisplayTimerEventHandler:NEAR
    EXTRN   SwitchesTimerEventHandler:NEAR


; InitRemoteTimers
;
; Description:      Initializes timer and event handler for timer 0, the timer
;                   used by the display and switches.
;
; Operation:        Install Timer2EventHandler into Tmr2Vec.
;                   Initialize Timer 2 counts and enable interrupt.
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

InitRemoteTimers            PROC    NEAR
                            PUBLIC  InitRemoteTimers
    
    PUSH AX
    PUSH DX

    %InstallVector(Tmr2Vec, Timer2EventHandler)

    ; Timer 2
    MOV     DX, Tmr2Count       ; Initialize the count register to 0
    XOR     AX, AX
    OUT     DX, AL

    MOV     DX, Tmr2MaxCnt      ; Setup max count for 1 ms
    MOV     AX, TIMER_2_MAX_COUNT_VAL
    OUT     DX, AL

    MOV     DX, Tmr2Ctrl        ; Setup control register, enable interrupts
    MOV     AX, Tmr2CtrlVal
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

InitRemoteTimers            ENDP


; Timer2EventHandler
;
; Description:      Handles the timer 2 interrupts. Calls all functions that
;                   rely on timer 2 events.
;
; Operation:        Calls the display timer event handler.
;                   Calls the switches timer event handler.
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
; Last Modified:    Nov. 18, 2013

Timer2EventHandler          PROC    NEAR

    PUSH DX
    PUSH AX

    CALL DisplayTimerEventHandler
    CALL SwitchesTimerEventHandler

    MOV DX, INTCtrlrEOI             ; Send timer EOI
    MOV AX, TimerEOI
    OUT DX, AL

    POP AX
    POP DX
    IRET                            ; IRET must be used in interrupt handler

Timer2EventHandler          ENDP


CODE ENDS
    END
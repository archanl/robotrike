    NAME    TIMER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    TIMER                                   ;
;               Timer Initialization and Interrupt Setup Functions           ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions to initialize the timers and their event
; handlers.
;
; The included public functions are:
;   - InstallTimer2EventHandler
;           Installs the event handler for timer 2 into the vector table.
;   - InitTimer
;           Initializes the timers and their interrupts
; The included private functions are:
;   - Timer0EventHandler
;           Calls all necessary external event handlers that rely on timer 0
;   - Timer2EventHandler
;           Calls all necessary external event handlers that rely on timer 2
;
;
; Revision History:
;       11/12/2013      Archan Luhar    Adopted Glen George's timer code
;                                       for the display assignment.
;       11/18/2013      Archan Luhar    Cleaned up formatting and commenting.

; Local include files
$INCLUDE(timer.inc)     ; Contains various addresses and values related to
                        ; interrupt and timer behavior


CGROUP  GROUP   CODE
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

; External references
; All non-meta timer event handlers should be listed here
    EXTRN   ParallelTimerEventHandler:NEAR
;    EXTRN   DisplayTimerEventHandler:NEAR
;    EXTRN   SwitchesTimerEventHandler:NEAR


; InitTimer
;
; Description:      Calls functions that initialize timers and their event
;                   handlers. MUST call this to use display and keypad routines.
;
; Operation:        Calls the event handler installer and interrupt setter.
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
; Stack Depth:      1 NEAR call.
;
; Author:           Archan Luhar
; Last Modified:    Nov. 20, 2013
InitTimer                   PROC    NEAR
                            PUBLIC  InitTimer

    CALL InstallTimerEventHandlers
    CALL SetTimerInterrupts
    
    RET

InitTimer                   ENDP



; InstallTimer[x]EventHandler
; (Timer 0 and Timer 2)
;
; Description:      Installs the timer interrupt event handlers into the
;                   interrupt vector table.
;
; Operation:        Writes the segment and and offset of the handler to the
;                   appropriate slot in the interrupt vector table.
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
; Stack Depth:      2 words.
;
; Author:           Glen George, Archan Luhar
; Last Modified:    Nov. 18, 2013


InstallTimer0EventHandler   PROC    NEAR
                            PUBLIC  InstallTimer0EventHandler

    PUSH AX                     ; Save Registers
    PUSH ES

    XOR     AX, AX              ; Clear ES (interrupt vectors are in segment 0)
    MOV     ES, AX

    %InstallVector(Tmr0Vec, Timer0EventHandler)

    POP ES                      ; Restores registers
    POP AX

    RET

InstallTimer0EventHandler   ENDP

InstallTimerEventHandlers   PROC    NEAR
                            PUBLIC  InstallTimerEventHandlers

    PUSH AX                     ; Save Registers
    PUSH ES

    XOR     AX, AX              ; Clear ES (interrupt vectors are in segment 0)
    MOV     ES, AX

    %InstallVector(Tmr0Vec, Timer0EventHandler)
    %InstallVector(Tmr2Vec, Timer2EventHandler)

    POP ES                      ; Restores registers
    POP AX

    RET

InstallTimerEventHandlers   ENDP


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

    ;CALL DisplayTimerEventHandler
    ;CALL SwitchesTimerEventHandler

    MOV DX, INTCtrlrEOI             ; Send timer EOI
    MOV AX, TimerEOI
    OUT DX, AL

    POP AX
    POP DX
    IRET                            ; IRET must be used in interrupt handler

Timer2EventHandler          ENDP




InitTimer0                  PROC NEAR
                            PUBLIC InitTimer0

        PUSH AX                     ; Save registers
        PUSH DX

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

        POP DX                      ; Restore registers
        POP AX

        RET


InitTimer0                  ENDP

InitTimer2                  PROC NEAR
                            PUBLIC InitTimer2

        PUSH AX                     ; Save registers
        PUSH DX

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
        
        POP DX                      ; Restore registers
        POP AX

        RET


InitTimer2                  ENDP

; SetTimerInterrupts
;
; IMPORTANT NOTE:   CURRENLTY ONLY INITIALIZES TIMER 2.
;
; Description:      Initialize the 80188 Timers.  The timers are initialized
;                   to generate interrupts every MS_PER_SEC milliseconds.
;                   The interrupt controller is also initialized to allow the
;                   timer interrupts.  Timer #2 is used to generate the
;                   interrupts for the display handler.
;
; Operation:        The appropriate values are written to the timer control
;                   registers in the PCB.  Also, the timer count registers
;                   are reset to zero.  Finally, the interrupt controller is
;                   setup to accept timer interrupts and any pending
;                   interrupts are cleared by sending a TimerEOI to the
;                   interrupt controller.
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
; Stack Depth:      2 words.
;
; Author:           Glen George, Archan Luhar
; Last Modified:    Nov. 18, 2013

SetTimerInterrupts          PROC    NEAR
                            PUBLIC  SetTimerInterrupts

        PUSH AX                     ; Save registers
        PUSH DX

        ; Timer Interrupt Control
                                    ; Initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl    ; Setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI     ; Send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL
        
        POP DX                      ; Restore registers
        POP AX

        RET

SetTimerInterrupts          ENDP


CODE ENDS
    END
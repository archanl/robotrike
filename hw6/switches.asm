    NAME    SWITCHES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   SWITCHES                                 ;
;                               SWITCHES Routines                            ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions to handle a periodic timer event to update
; check key presses and execute the right key handler.
;
; The included public functions are:
;   - SwitchesTimerEventHandler
;           Checks the switches to see if any are pressed and debounces them and
;           calls the appropriate switch handler (currently just a test function
;           that enqueues the call arguments and displays them).
;   - SwitchEventHandler
;           Calls the right function given which key's handler to trigger.
;           Currently only calls test EnqueueEvent function.
;
; Revision History:
;       11/20/2013      Archan Luhar    Finished switches.
;       11/29/2013      Archan Luhar    Passes switch press event constant to
;                                       EnqueueEvent instead of key number.

; local includes
$INCLUDE(general.inc)
$INCLUDE(switches.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP

; External references
    EXTRN   EnqueueEvent:NEAR



; InitSwitches
;
; Description:      This function initializes the shared variables for the
;                   switch routines. MUST call this before calling any switch
;                   routine.
;
; Operation:        Initialize current_pressed_switch to 0 to define
;                   no switches pressed. (see DATA section)
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: None.
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      0.
;
; Author:           Archan Luhar
; Last Modified:    11/20/2013

InitSwitches    PROC    NEAR
                PUBLIC  InitSwitches
    
    MOV current_pressed_switch, NO_SWITCH_PRESSED
    
    RET

InitSwitches    ENDP



; SwitchesTimerEventHandler
;
; Description:      This function handles the timer interrupt to
;                   manage the switch presses. This function should be called
;                   by a timer handler every 1 ms. It scans for pressed
;                   switches and calls the appropriate handler for the switch
;                   after debouncing the press.
;
; Operation:        If switch was pressed recently:
;                       Checks if it still pressed. If not, it resets
;                           the current_pressed_switch variable.
;                       If so, checks if debounce countdown has reached zero.
;                           If debounce countdown ~= 0, it decrements it.
;                           If = 0, it decrements a key repeat countdown if
;                               that is not 0, else it calls the key handler and
;                               resets the key repeat countdown (debouncing it
;                               once).
;                   
;                   If switch is not pressed:
;                       It scans all the switch rows and sees if the last nibble
;                       has a pressed switch. Raw, the last nibble is all 1's
;                       if no switch is pressed. If the last switch in the row
;                       is pressed, the first nibble is 0.
;                       If it finds a row with a pressed switch, it records the
;                       row address and the row's data. It also resets
;                       the key press debounce and key repeat shared variables.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  
;
; Shared Variables: current_pressed_switch
;                   switch_press_countdown
;                   current_pressed_row
;                   switch_press_repeat_countdown
;                   switch_press_repeat_debounced
;                   
;
; Global Variables: None.
;
; Input:            Switches.
;
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      2 words + 1 possible NEAR call.
;
; Author:           Archan Luhar
; Last Modified:    11/20/2013

SwitchesTimerEventHandler   PROC    NEAR
                            PUBLIC  SwitchesTimerEventHandler

    PUSH AX                         ; Save registers        
    PUSH DX

    WasSwitchPressed:                       ; Checks if switch was pressed.
        MOV AH, current_pressed_switch
        TEST AH, AH                         
        JNZ SwitchWasPressed                ; If so, check debounce countdown
        ; JNZ SwitchWasNotPressed           ; else, scan the switches.

    
    SwitchWasNotPressed:
    ScanSwitches:
        MOV DX, FIRST_SWITCHES_ROW      ; Get address of first row of switches

    DeterminePressedRow:                ; Get row value and make it usable
        IN AL, DX                               ; Read value from row
        NOT AL                                  ; Invert value
        SHL AL, BYTE_BITS - SWITCHES_PER_ROW    ; Get relevant bits on left
        
        ; Shift relevant bits to left side of byte. If all were not pressed,
        ; the bits in the relevant nibble would be all 1's. NOT of that would be
        ; all 0's. Shifting those all the way to the left yields a 0 AL since
        ; shifting pushes 0's on the right.
        JZ EndDeterminePressedRow       ; If no switch currently pressed, loop.

    SwitchPressed:                      ; Else store current info and end.
        MOV current_pressed_row, DX     ; Store row address
        MOV current_pressed_switch, AL  ; Store row value
        
        ; Reset the countdowns. Initially, only a debounce is needed.
        MOV switch_press_countdown, KEY_PRESS_INIT_DEBOUNCE
        MOV switch_press_repeat_countdown, 0        ; 0's indicate false
        MOV switch_press_repeat_debounced, 0
        JMP EndSwitchesTimerEventHandler
    
    EndDeterminePressedRow:
        INC DX                                          ; Move on to next row.
        CMP DX, FIRST_SWITCHES_ROW + NUM_SWITCH_ROWS    ; If switch row within
        JB DeterminePressedRow                          ; upper bound, loop.
        JMP EndSwitchesTimerEventHandler                ; Else, wait till
                                                        ; next iteration.


    SwitchWasPressed:
    CheckDebounce:
        MOV DX, switch_press_countdown
        TEST DX, DX                         ; If debounce countdown has reached
        JZ CheckCurrentSwitchState          ; zero, check the switch now.
        ; JNZ UpdateDebounceCountdown

    UpdateDebounceCountdown:
        DEC switch_press_countdown          ; If not, decrement countdown
        JMP EndSwitchesTimerEventHandler    ; and wait till next iteration.
    
    CheckCurrentSwitchState:                ; Debounce countdown is done.
        MOV DX, current_pressed_row         ; Get the row the switch was in.
        IN AL, DX                           ; Get the current value of that row.
        NOT AL                              ; Invert the value.
        SHL AL, BYTE_BITS - SWITCHES_PER_ROW; Get relevant bits on left.

        CMP AH, AL                          ; Compare row pattern to when it
        JE SwitchStillPressed               ; was pressed. If same, evaluate.
        ; JNE ResetSwitches                 
    
    ResetSwitches:                          ; If changed, invalidate and reset.
        MOV current_pressed_switch, NO_SWITCH_PRESSED
        JMP EndSwitchesTimerEventHandler    ; End and wait for next iteration.

    SwitchStillPressed:                     ; If switch is still pressed,
        MOV BX, switch_press_repeat_countdown   ; check to wait for repeat.
        TEST BX, BX
        JZ CallSwitchEvent                  ; If repeat countdown is 0, call.
    
    UpdateRepeatCountdown:                  ; If not, decrement repeat countdown
        DEC switch_press_repeat_countdown   ; and wait for next iteration.
        JMP EndSwitchesTimerEventHandler

    CallSwitchEvent:                        ; Handles key press event calling.
        CALL SwitchEventHandler             ; Args: Row address=DX, val=AL
        MOV DL, switch_press_repeat_debounced   ; If key repeating has been
        TEST DL, DL                             ; already "debounced" then
        JNZ ResetRepeatWithoutDebounce          ; Reset key repeating.
        ; JZ ResetRepeatWithDebounce            ; Else reset it with added time.
    
    ResetRepeatWithDebounce:
        MOV switch_press_repeat_countdown, KEY_REPEAT_RATE + KEY_REPEAT_DEBOUNCE
        MOV switch_press_repeat_debounced, 1    ; Mark repeating debounced.
        JMP EndSwitchesTimerEventHandler
    
    ResetRepeatWithoutDebounce:
        MOV switch_press_repeat_countdown, KEY_REPEAT_RATE
        JMP EndSwitchesTimerEventHandler


    EndSwitchesTimerEventHandler:
        POP DX                              ; Restore registers and return
        POP AX
        RET

SwitchesTimerEventHandler   ENDP


; SwitchEventHandler
;
; Description:      This function calls the appropriate handler for the key.
;                   Currently it calls the test EnqueueEvent function with
;                   the key number indexed by 0 as its code and number.
;
; Operation:        Calculates switch number as follows:
;                   row = row address - first row address
;                   col = SWITCHES_PER_ROW - # of left shits to enable sign bit
;                   switch number = NUM_SWITCH_ROWS * col + row
;                   Calls EnqueueEvent with switch number AL and switch event in
;                   AH.
;
; Arguments:        DX = Row address
;                   AL = Row value (1011 means all but third switch pressed)
;
; Return Value:     None.
;
; Local Variables:  DL = row
;                   DX = col
;                   AH, AL = Key Event, switch #: argument to EnqueueEvent
;
; Shared Variables: None.
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Limitations:      Uses shift left 2 to multiply by 4 (number of rows).
;                   If don't want it to be hard coded, then use MUL by num rows.
;
; Registers Used:   None.
;
; Stack Depth:      3 words.
;
; Author:           Archan Luhar
; Last Modified:    11/29/2013

SwitchEventHandler          PROC NEAR
                            PUBLIC SwitchEventHandler
    
    InitSwitchEventHandler:
        PUSH AX                         ; Save registers
        PUSH DX
        PUSH BX
    
    DetermineSwitchRow:
        SUB DX, FIRST_SWITCHES_ROW      ; DX contains row number 0,1,..
    
    DetermineSwitchColumn:
        MOV BL, SWITCHES_PER_ROW - 1    ; Determine column by testing high bit
        TEST AL, AL                     ; (sign) and decrementing row counter BL
        JS EndSwitchEventHandler        ; when shifting left the row value.
    DetermineSwitchColumnLoop:
        DEC BL
        SHL AL, 1
        JS EndSwitchEventHandler        ; Found column with 1 bit.
        JMP DetermineSwitchColumnLoop
    
    ; AH = Switch Event
    ; AL = Switch number
    EndSwitchEventHandler:
        MOV AL, BL
        SHL AL, 2
        ADD AL, DL                      ; Key number = AL = column * 4 + row
        
        MOV AH, SWITCH_PRESS_EVENT      ; Event code = AH = switch press event

        CALL EnqueueEvent               ; Calls the event handler queueing fnc.
        
        POP BX                          ; Restore registers
        POP DX
        POP AX
        
        RET
        
SwitchEventHandler          ENDP




CODE ENDS


DATA SEGMENT PUBLIC 'DATA'

    current_pressed_row             DW  ?   ; Address of row currently pressed
    current_pressed_switch          DB  ?   ; Value of pressed row. (0 if none)
    switch_press_repeat_debounced   DB  ?   ; Boolean: key repeat debounced?
    switch_press_repeat_countdown   DW  ?   ; Countdown for key repeat
    switch_press_countdown          DW  ?   ; Countdown for key debounce

DATA ENDS


    END
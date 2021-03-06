    NAME KEYPARSE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    KEYPARSE                                ;
;                               Remote Key Parsing                           ;
;                                    EE/CS 51                                ;
;                                  Archan Luhar                              ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions to handle key presses in the remote unit.
; A table is used to map the key to a procedure. This can be easily
; modified to a table of multiple but currently the UI is very basic and
; has only one state.
;
; The included public functions are:
;   - InitKeyParser
;           Initializes the current state of the state machine. MUST be called
;           before using ParseKey.
;   - ParseKey
;           Given a key, execute related function.
;
; Revision History:
;  1/27/2014    Archan Luhar        Finished key parsing table and functions
;  1/28/2014    Archan Luhar        Finished commenting




; Import necessary definitions and macros
$INCLUDE(general.inc)
$INCLUDE(KeyParse.inc)
$INCLUDE(events.inc)

; setup code and data groups
    CGROUP  GROUP   CODE
    DGROUP  GROUP   DATA

; segment register assumptions
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP



CODE    SEGMENT PUBLIC 'CODE'

; External References
    EXTRN   SerialPutChar:NEAR
    



; InitKeyParser
;
; Description:      This function initializes the state of the state machine
;                   required for the key parser. It MUST be called
;                   before calling ParseKey.
;
; Operation:        Sets the KeyParserCurrentState to the initial state
;                   K_INITIAL.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: ParserCurrentState (W)
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
; Data Structures:  State Machine
;
; Registers Used:   None.
;
; Stack Depth:      0
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

InitKeyParser    PROC    NEAR
                    PUBLIC  InitKeyParser

    MOV KeyParserCurrentState, K_INITIAL
    RET

InitKeyParser ENDP



; ParseKey
;
; Description:      This function updates the remote UI key input state machine
;                   and calls the proper functions according to the state.
;
; Operation:        Look up what state to change to next and what action to take
;					in a table indexed by the states and sub-indexed by the key.
;
; Arguments:        AL = Key value (0 to 15)
;
; Return Value:     None.
;
; Local Variables:  CL = Argument copy
;                   AX = row in table
;                   BX = actual offset into table
;
; Shared Variables: KeyParserCurrentState (R/W)
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
; Data Structures:  State Machine (table lookup).
;
; Registers Used:   None.
;
; Stack Depth:      3 words + call.
;
; Author:           Glen George (state machine lookup), Archan Luhar
; Last Modified:    1/27/2014

ParseKey 	PROC    NEAR
            PUBLIC  ParseKey

StartParseKey:
    PUSH AX
    PUSH BX
    PUSH CX
	MOV CL, AL                  ; CL = argument copy

ParseKeyTransition:             ;figure out what transition to do
    MOV	AL, NUM_KEYS            ;find row in the table
    MUL	KeyParserCurrentState   ;AX is start of row for current state
    ADD	AL, CL                  ;get the actual transition by adding key number
    ADC	AH, 0                   ;propagate low byte carry into high byte

    IMUL BX, AX, SIZE KEY_TRANSITION_ENTRY  ; BX = to table offset

ParseKeyDoActions:
    CALL CS:KeyTable[BX].ACTION	            ;do the action

ParseKeyDoTransition:
    MOV CL, CS:KeyTable[BX].NEXTSTATE       ; Update the current state to
    MOV KeyParserCurrentState, CL           ; the next state specified

EndParseKey:
    POP CX
    POP BX
    POP AX
    RET

ParseKey 	ENDP






; doNOP
;
; Description:      This function does nothing but returns. Useful for keys
;                   that don't do anything.
;
; Operation:        Do nothing. Return.
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
; Registers Used:   AX
;
; Stack Depth:      0
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doNOP           PROC    NEAR
    NOP
    RET
doNOP           ENDP


; doTurnLeft
;
; Description:      Send command to turn left slightly.
;
; Operation:        Send via serial the direction command character followed by
;                   minus sign followed by the angle step constant followed by
;                   the end command character.
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
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

doTurnLeft      PROC    NEAR

    PUSH AX
    
    MOV AL, SCHAR_DIR
    CALL SerialPutChar
    
    MOV AL, SCHAR_NEGATIVE
    CALL SerialPutChar
    
    MOV AL, ANGLE_STEP_CHAR
    CALL SerialPutChar
    
    MOV AL, SCHAR_END
    CALL SerialPutChar
    
    POP AX
    RET
    
doTurnLeft      ENDP


; doTurnRight
;
; Description:      Send command to turn right slightly.
;
; Operation:        Send via serial the direction command character followed by
;                   followed by the angle step constant followed by
;                   the end command character.
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
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

doTurnRight     PROC    NEAR

    PUSH AX
    
    MOV AL, SCHAR_DIR
    CALL SerialPutChar
    
    MOV AL, SCHAR_POSITIVE
    CALL SerialPutChar
    
    MOV AL, ANGLE_STEP_CHAR
    CALL SerialPutChar
    
    MOV AL, SCHAR_END
    CALL SerialPutChar
    
    POP AX
    RET
    
doTurnRight     ENDP


; doStop
;
; Description:      Send command to set speed to 0.
;
; Operation:        Send via serial the absolute speed command character
;                   followed by the 0 character followed by
;                   the end command character.
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
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

doStop          PROC    NEAR

    PUSH AX
    
    MOV AL, SCHAR_SPEED
    CALL SerialPutChar
    
    MOV AL, '0'
    CALL SerialPutChar
    
    MOV AL, SCHAR_END
    CALL SerialPutChar
    
    POP AX
    RET
    
doStop          ENDP


; doSpeedUp
;
; Description:      Send command to increase relative speed.
;
; Operation:        Send via serial the relative speed command character
;                   followed by the one percent speed step characters
;                   followed by the end command character.
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
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

doSpeedUp     PROC    NEAR

    PUSH AX
    
    MOV AL, SCHAR_REL_SPEED
    CALL SerialPutChar
    
    MOV AL, REL_SPEED_STEP_CHAR1
    CALL SerialPutChar
    MOV AL, REL_SPEED_STEP_CHAR2
    CALL SerialPutChar
    MOV AL, REL_SPEED_STEP_CHAR3
    CALL SerialPutChar
    
    MOV AL, SCHAR_END
    CALL SerialPutChar
    
    POP AX
    RET
    
doSpeedUp     ENDP


; doSlowDown
;
; Description:      Send command to decrease relative speed.
;
; Operation:        Send via serial the relative speed command character
;                   followed by the negative sign
;                   followed by the one percent speed step characters
;                   followed by the end command character.
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
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

doSlowDown     PROC    NEAR

    PUSH AX
    
    MOV AL, SCHAR_REL_SPEED
    CALL SerialPutChar
    
    MOV AL, SCHAR_NEGATIVE
    CALL SerialPutChar
    
    MOV AL, REL_SPEED_STEP_CHAR1
    CALL SerialPutChar
    MOV AL, REL_SPEED_STEP_CHAR2
    CALL SerialPutChar
    MOV AL, REL_SPEED_STEP_CHAR3
    CALL SerialPutChar
    
    MOV AL, SCHAR_END
    CALL SerialPutChar
    
    POP AX
    RET
    
doSlowDown     ENDP


; doLaserOn
;
; Description:      Send command to turn on laser.
;
; Operation:        Send via serial the fire laser command character
;                   followed by the end command character.
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
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

doLaserOn       PROC    NEAR

    PUSH AX
    
    MOV AL, SCHAR_LASER_ON
    CALL SerialPutChar

    MOV AL, SCHAR_END
    CALL SerialPutChar
    
    POP AX
    RET
    
doLaserOn       ENDP


; doLaserOff
;
; Description:      Send command to turn off laser.
;
; Operation:        Send via serial the turn off laser command character
;                   followed by the end command character.
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
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

doLaserOff      PROC    NEAR

    PUSH AX
    
    MOV AL, SCHAR_LASER_OFF
    CALL SerialPutChar

    MOV AL, SCHAR_END
    CALL SerialPutChar
    
    POP AX
    RET
    
doLaserOff      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; KeyTable
;
; Description:      This is the state transition table for the Remote keypad.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Glen George, Archan Luhar
; Last Modified:    Jan. 27, 2014


KEY_TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?               ;first action for the transition
KEY_TRANSITION_ENTRY        ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nextstate, action))  (
    KEY_TRANSITION_ENTRY< %nextstate, OFFSET(%action) >
)

KeyTable    LABEL    KEY_TRANSITION_ENTRY

    ;Current State = K_INITIAL                      Input Token Type
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 1
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 2
    %TRANSITION(K_INITIAL, doTurnLeft)              ;Key 3
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 4
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 5
    %TRANSITION(K_INITIAL, doSpeedUp)               ;Key 6
    %TRANSITION(K_INITIAL, doStop)                  ;Key 7
    %TRANSITION(K_INITIAL, doSlowDown)              ;Key 8
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 9
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 10
    %TRANSITION(K_INITIAL, doTurnRight)             ;Key 11
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 12
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 13
    %TRANSITION(K_INITIAL, doNOP)                   ;Key 14
    %TRANSITION(K_INITIAL, doLaserOn)               ;Key 15
    %TRANSITION(K_INITIAL, doLaserOff)              ;Key 16




CODE ENDS


DATA SEGMENT PUBLIC 'DATA'

    ; Keep track of the current state
    KeyParserCurrentState  DB  ?

DATA ENDS


    END
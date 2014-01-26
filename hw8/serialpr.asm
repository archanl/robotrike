    NAME SERIALPR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    SERIALPR                                ;
;                                Serial Processing                           ;
;                                    EE/CS 51                                ;
;                                  Archan Luhar                              ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions to handle characters as they come linearly via
; the serial port. A state machine is used to keep track of the type and values
; of the characters that are being processed.
;
; The included public functions are:
;   - InitSerialParser
;           Initializes the current state of the state machine. MUST be called
;           before using ParseSerialChar.
;   - ParseSerialChar
;           Given a character, update the state machine and call relevant
;           external functions as the command is described from the char stream.
;
; Revision History:
;        1/20/2013      Archan Luhar    Started coding structure of the SM
;       11/23/2013      Archan Luhar    Finished coding
;       11/25/2013      Archan Luhar    Finished debugging
;       11/26/2013      Archan Luhar    Finished commenting



; Import necessary definitions and macros
$INCLUDE(general.inc)
$INCLUDE(serialpr.inc)
$INCLUDE(motors.inc)

; setup code and data groups
    CGROUP  GROUP   CODE
    DGROUP  GROUP   DATA

; segment register assumptions
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP



CODE    SEGMENT PUBLIC 'CODE'

; External References
    EXTRN   SetMotorSpeed:NEAR
    EXTRN   GetMotorSpeed:NEAR
    EXTRN   GetMotorDirection:NEAR
    EXTRN   SetLaser:NEAR
    EXTRN   GetLaser:NEAR
    EXTRN   SetTurretAngle:NEAR
    EXTRN   GetTurretAngle:NEAR
    EXTRN   SetRelTurretAngle:NEAR
    EXTRN   SetTurretElevation:NEAR
    EXTRN   GetTurretElevation:NEAR
    



; InitSerialParser
;
; Description:      This function initializes the state of the state machine
;                   required for the serial parser. It MUST be called
;                   before calling ParseSerialChar.
;
; Operation:        Sets the ParserCurrentState to the initial state ST_INITIAL.
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
; Last Modified:    1/23/2014

InitSerialParser    PROC    NEAR
                    PUBLIC  InitSerialParser

    MOV ParserCurrentState, ST_INITIAL
    RET

InitSerialParser ENDP





; ParseSerialChar
;
; Description:      This function updates the serial state machine and executes
;                   the proper functions according to the commands given via
;                   a series of characters (expected from serial input)
;
; Operation:        This function looks up the type and value of the given
;                   character in a table. Then, it looks up what state to change
;                   to next and what action to take in a table indexed by
;                   the states and sub-indexed by the token type.
;
; Arguments:        AL = character to parse.
;
; Return Value:     AX = 0 (PARSE_SUCCESS) or 1 (PARSE_FAILURE)
;
; Local Variables:  CH, CL = token type and value
;                   AX = rwo in table
;                   BX = actual offset into table
;
; Shared Variables: ParserCurrentState (R/W)
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           None.
;
; Error Handling:   See Return Value.
;
; Algorithms:       None.
;
; Data Structures:  State Machine (table lookup).
;
; Registers Used:   AX
;
; Stack Depth:      2 words + call.
;
; Author:           Archan Luhar
; Last Modified:    1/23/2014

ParseSerialChar PROC    NEAR
                PUBLIC  ParseSerialChar

StartParseSerialChar:
    PUSH BX
    PUSH CX

DoNextToken:            ;get next input for state machine
    AND AL, TOKEN_MASK
    CALL GetFPToken         ; Input is in AL, get token type and value
    MOV	CX, AX              ; Save token type (AH) and value (AL) in CX

ComputeTransition:      ;figure out what transition to do
    MOV	AL, NUM_TOKEN_TYPES ;find row in the table
    MUL	ParserCurrentState  ;AX is start of row for current state
    ADD	AL, CH              ;get the actual transition by adding token type
    ADC	AH, 0               ;propagate low byte carry into high byte

    IMUL BX, AX, SIZE TRANSITION_ENTRY   ; BX = to table offset

DoActions:              ;do the action (should affect AX, return value)
    MOV	AL, CL              ;get token value back for actions
    CALL CS:StateTable[BX].ACTION	    ;do the action

DoTransition:				            ; Update the current state to
    MOV CL, CS:StateTable[BX].NEXTSTATE ; the next state specified
    CMP AX, PARSE_SUCCESS
    JNE ResetParserState
    MOV ParserCurrentState, CL          ; in the table entry
    JMP EndParseSerialChar

ResetParserState:
    MOV ParserCurrentState, ST_INITIAL
    ;JMP EndParseSerialChar
    
EndParseSerialChar:
    POP CX
    POP BX
    RET

ParseSerialChar ENDP





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; clear bad number flag ; clear sign flag
inputNumClear   PROC    NEAR
    
    MOV inputNumIsNegative, FALSE
    MOV inputNumber, 0
    
    MOV AX, PARSE_SUCCESS
    RET

inputNumClear   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; set sign flag
inputNumNeg     PROC    NEAR

    MOV inputNumIsNegative, TRUE

    MOV AX, PARSE_SUCCESS
    RET

inputNumNeg     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; update input number
inputNumDigit   PROC    NEAR

BeginInputNumDigit:
    PUSH BX
    PUSH CX
    PUSH DX

InputNumDigitMakeSpace:
    ; Let CX be the new digit
    MOV CL, AL
    XOR CH, CH
    
    ; Get the current number and multiply it by 10 (shift places to the left)
    MOV AX, inputNumber
    MOV BX, INPUT_NUM_BASE

    CMP inputNumIsNegative, TRUE
    JE InputNumDigitSubDigit
    ;JNE InputNumDigitAddDigit

InputNumDigitAddDigit:
    MUL BX                      ; (DX|AX) <-- AX * BX
    JO InputNumDigitFailure
    ADD AX, CX
    JO InputNumDigitFailure
    JMP InputNumDigitSuccess

InputNumDigitSubDigit:
    IMUL BX                      ; (DX|AX) <-- AX * BX
    JO InputNumDigitFailure
    SUB AX, CX
    JO InputNumDigitFailure
    ;JMP InputNumDigitSuccess

InputNumDigitSuccess:
    MOV inputNumber, AX
    MOV AX, PARSE_SUCCESS
    JMP EndInputNumDigit

InputNumDigitFailure:
    MOV AX, PARSE_FAILURE
    ;JMP EndInputNumDigit

EndInputNumDigit:
    POP DX
    POP CX
    POP BX
    RET

inputNumDigit   ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doNOP           PROC    NEAR
    MOV AX, PARSE_SUCCESS
    RET
doNOP           ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doError         PROC    NEAR
    MOV AX, PARSE_FAILURE
    RET
doError         ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doSetAbsSpeed           PROC    NEAR

BeginDoSetAbsSpeed:
    PUSH BX

    MOV AX, inputNumber
    MOV BX, NO_CHANGE_ANGLE
    CALL SetMotorSpeed

    MOV AX, PARSE_SUCCESS
    POP BX
    RET

doSetAbsSpeed           ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doSetRelSpeed           PROC    NEAR

BeginDoSetRelSpeed:
    PUSH BX

    CALL GetMotorSpeed
    MOV BX, inputNumber
    CMP inputNumIsNegative, TRUE
    JE doSetRelSpeedSatSub
    ;JNE doSetRelSpeedSatAdd

    
doSetRelSpeedSatAdd:
    ADD AX, BX
    JNC doSetRelSpeedDoSet
    ;JC doSetRelSpeedSatUp

doSetRelSpeedSatUp:
    MOV AX, MAX_SPEED
    JMP doSetRelSpeedDoSet

    
doSetRelSpeedSatSub:
    NEG BX
    CMP BX, AX
    JA doSetRelSpeedSatDown
    SUB AX, BX
    JMP doSetRelSpeedDoSet

doSetRelSpeedSatDown:
    MOV AX, 0
    ;JMP doSetRelSpeedDoSet

    
doSetRelSpeedDoSet:
    MOV BX, NO_CHANGE_ANGLE
    CALL SetMotorSpeed

    ;JMP EndDoSetRelSpeed

EndDoSetRelSpeed:
    MOV AX, PARSE_SUCCESS
    POP BX
    RET

doSetRelSpeed           ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doSetDirection           PROC    NEAR

BeginDoSetDirection:
    PUSH BX
    PUSH DX

    doSetDirectionNormalizeAngle:                 ; The following block of code normalizes
        MOV AX, inputNumber         ; the given angle to be between 0 and 360
        CMP AX, 0
        JGE doSetDirectionAngleIsPositive
    doSetDirectionAngleIsNegative:                ; If the angle given is negative then
        NEG AX                      ; Make positive
        XOR DX, DX
        MOV BX, 360
        DIV BX                      ; Divide by 360
        MOV AX, DX                  ; Get the remainder
        NEG AX                      ; Make negative again
        ADD AX, 360                 ; Final angle is 360 - (given mod 360)
        JMP doSetDirectionSetDirection
    doSetDirectionAngleIsPositive:
        XOR DX, DX                  ; If angle is positive, get its mod 360
        MOV BX, 360
        DIV BX
        MOV AX, DX                  ; Final angle is (given mod 360)
        ;JMP doSetDirectionSetDirection

    
doSetDirectionSetDirection:
    MOV BX, AX
    CALL GetMotorDirection
    ADD BX, AX
    
    MOV AX, NO_CHANGE_SPEED
    CALL SetMotorSpeed
    

    ;JMP EndDoSetDirection

EndDoSetDirection:
    MOV AX, PARSE_SUCCESS
    POP DX
    POP BX
    RET

doSetDirection           ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doRotateTurretAbs           PROC    NEAR

BeginDoRotateTurretAbs:
    MOV AX, inputNumber
    CALL SetTurretAngle

    ;JMP EndDoRotateTurretAbs

EndDoRotateTurretAbs:
    MOV AX, PARSE_SUCCESS
    RET

doRotateTurretAbs           ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doRotateTurretRel           PROC    NEAR

BeginDoRotateTurretRel:
    PUSH BX

    MOV AX, inputNumber
    CALL SetRelTurretAngle

    ;JMP EndDoRotateTurretRel

EndDoRotateTurretRel:
    MOV AX, PARSE_SUCCESS
    POP BX
    RET

doRotateTurretRel           ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doSetTurretElevation    PROC    NEAR

BeginDoSetTurretElevation:
    MOV AX, inputNumber
    CALL SetTurretElevation

    ;JMP EndDoSetTurretElevation

EndDoSetTurretElevation:
    MOV AX, PARSE_SUCCESS
    RET

doSetTurretElevation    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doLaserOn       PROC    NEAR
    MOV AX, TRUE
    CALL SetLaser

    MOV AX, PARSE_SUCCESS
    RET
doLaserOn       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doLaserOff      PROC    NEAR

    MOV AX, FALSE
    CALL SetLaser

    MOV AX, PARSE_SUCCESS
    RET

doLaserOff      ENDP








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; StateTable
;
; Description:      This is the state transition table for the state machine.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Glen George, Archan Luhar
; Last Modified:    Feb. 26, 2003


TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?               ;first action for the transition
TRANSITION_ENTRY        ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nextstate, action))  (
    TRANSITION_ENTRY< %nextstate, OFFSET(%action) >
)

StateTable    LABEL    TRANSITION_ENTRY

    ;Current State = ST_INITIAL                     Input Token Type
    %TRANSITION(ST_ABS_SPEED, inputNumClear)        ;TOKEN_ABS_SPEED
    %TRANSITION(ST_REL_SPEED, inputNumClear)        ;TOKEN_REL_SPEED
    %TRANSITION(ST_SET_DIR, inputNumClear)          ;TOKEN_SET_DIR
    %TRANSITION(ST_ROT_TUR, inputNumClear)          ;TOKEN_ROT_TUR
    %TRANSITION(ST_ELE_TUR, inputNumClear)          ;TOKEN_ELE_TUR
    %TRANSITION(ST_LASER_ON, doNOP)                 ;TOKEN_LAS_ON
    %TRANSITION(ST_LASER_OFF, doNOP)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doNOP)                  ;TOKEN_RETURN
    %TRANSITION(ST_INITIAL, doNOP)                  ;TOKEN_OTHER

    ;;;;;;;;;;
    
    ;Current State = ST_ABS_SPEED                   Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_ABS_SPEED_SIGN, doNOP)           ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ABS_SPEED_DIGIT, inputNumDigit)  ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_ABS_SPEED, doNOP)                ;TOKEN_OTHER

    ;Current State = ST_ABS_SPEED_SIGN              Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ABS_SPEED_DIGIT, inputNumDigit)  ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_ABS_SPEED_SIGN, doNOP)           ;TOKEN_OTHER
    
    ;Current State = ST_ABS_SPEED_DIGIT             Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ABS_SPEED_DIGIT, inputNumDigit)  ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doSetAbsSpeed)          ;TOKEN_RETURN
    %TRANSITION(ST_ABS_SPEED_DIGIT, doNOP)          ;TOKEN_OTHER

    ;;;;;;;;;;

    ;Current State = ST_REL_SPEED                   Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_REL_SPEED_SIGN, doNOP)           ;TOKEN_PLUS
    %TRANSITION(ST_REL_SPEED_SIGN, inputNumNeg)     ;TOKEN_MINUS
    %TRANSITION(ST_REL_SPEED_DIGIT, inputNumDigit)  ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_REL_SPEED, doNOP)                ;TOKEN_OTHER

    ;Current State = ST_REL_SPEED_SIGN              Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_REL_SPEED_DIGIT, inputNumDigit)  ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_REL_SPEED_SIGN, doNOP)           ;TOKEN_OTHER

    ;Current State = ST_REL_SPEED_DIGIT             Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_REL_SPEED_DIGIT, inputNumDigit)  ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doSetRelSpeed)          ;TOKEN_RETURN
    %TRANSITION(ST_REL_SPEED_DIGIT, doNOP)          ;TOKEN_OTHER

    ;;;;;;;;;;
    
    ;Current State = ST_SET_DIR                     Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_SET_DIR_SIGN, doNOP)             ;TOKEN_PLUS
    %TRANSITION(ST_SET_DIR_SIGN, inputNumNeg)       ;TOKEN_MINUS
    %TRANSITION(ST_SET_DIR_DIGIT, inputNumDigit)    ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_SET_DIR, doNOP)                  ;TOKEN_OTHER

    ;Current State = ST_SET_DIR_SIGN                Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_SET_DIR_DIGIT, inputNumDigit)    ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_SET_DIR_SIGN, doNOP)             ;TOKEN_OTHER

    ;Current State = ST_SET_DIR_DIGIT               Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_SET_DIR_DIGIT, inputNumDigit)    ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doSetDirection)         ;TOKEN_RETURN
    %TRANSITION(ST_SET_DIR_DIGIT, doNOP)            ;TOKEN_OTHER

    ;;;;;;;;;;
    
    ;Current State = ST_ROT_TUR                     Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_ROT_TUR_SIGN, doNOP)             ;TOKEN_PLUS
    %TRANSITION(ST_ROT_TUR_SIGN, inputNumNeg)       ;TOKEN_MINUS
    %TRANSITION(ST_ROT_TUR_ABS_DIGIT, inputNumDigit);TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_ROT_TUR, doNOP)                  ;TOKEN_OTHER

    ;Current State = ST_ROT_TUR_SIGN                Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ROT_TUR_REL_DIGIT, inputNumDigit);TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_ROT_TUR_SIGN, doNOP)             ;TOKEN_OTHER

    ;Current State = ST_ROT_TUR_ABS_DIGIT           Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ROT_TUR_ABS_DIGIT, inputNumDigit);TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doRotateTurretAbs)      ;TOKEN_RETURN
    %TRANSITION(ST_ROT_TUR_ABS_DIGIT, doNOP)        ;TOKEN_OTHER

    ;Current State = ST_ROT_TUR_REL_DIGIT           Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ROT_TUR_REL_DIGIT, inputNumDigit);TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doRotateTurretRel)      ;TOKEN_RETURN
    %TRANSITION(ST_ROT_TUR_REL_DIGIT, doNOP)        ;TOKEN_OTHER

    ;;;;;;;;;;

    ;Current State = ST_ELE_TUR                     Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_ELE_TUR_SIGN, doNOP)             ;TOKEN_PLUS
    %TRANSITION(ST_ELE_TUR_SIGN, inputNumNeg)       ;TOKEN_MINUS
    %TRANSITION(ST_ELE_TUR_DIGIT, inputNumDigit)    ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_ELE_TUR, doNOP)                  ;TOKEN_OTHER

    ;Current State = ST_ELE_TUR_SIGN                Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ELE_TUR_DIGIT, inputNumDigit)    ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_RETURN
    %TRANSITION(ST_ELE_TUR_SIGN, doNOP)             ;TOKEN_OTHER

    ;Current State = ST_ELE_TUR_DIGIT               Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_ELE_TUR_DIGIT, inputNumDigit)    ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doSetTurretElevation)   ;TOKEN_RETURN
    %TRANSITION(ST_ELE_TUR_DIGIT, doNOP)            ;TOKEN_OTHER

    ;;;;;;;;;;

    ;Current State = ST_LASER_ON                    Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doLaserOn)              ;TOKEN_RETURN
    %TRANSITION(ST_LASER_ON, doNOP)                 ;TOKEN_OTHER

    ;Current State = ST_LASER_OFF                   Input Token Type
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ABS_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_REL_SPEED
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_SET_DIR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ROT_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_ELE_TUR
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_ON
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_LAS_OFF
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_PLUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_MINUS
    %TRANSITION(ST_INITIAL, doError)                ;TOKEN_DIGIT
    %TRANSITION(ST_INITIAL, doLaserOff)             ;TOKEN_RETURN
    %TRANSITION(ST_LASER_OFF, doNOP)                ;TOKEN_OTHER

    ;;;;;;;;;;


    
    
    


; GetFPToken
;
; Description:      This procedure returns the token class and token value for
;                   the passed character.  The character is truncated to
;                   7-bits.
;
; Operation:        Looks up the passed character in two tables, one for token
;                   types or classes, the other for token values.
;
; Arguments:        AL - character to look up.
; Return Value:     AL - token value for the character.
;                   AH - token type or class for the character.
;
; Local Variables:  BX - table pointer, points at lookup tables.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Table lookup.
; Data Structures:  Two tables, one containing token values and the other
;                   containing token types.
;
; Registers Used:   AX, BX.
; Stack Depth:      0 words.
;
; Author:           Glen George
; Last Modified:    Feb. 26, 2003

GetFPToken    PROC    NEAR

InitGetFPToken:                     ;setup for lookups
    AND    AL, TOKEN_MASK               ;strip unused bits (high bit)
    MOV    AH, AL                       ;and preserve value in AH

TokenTypeLookup:                        ;get the token type
    MOV     BX, OFFSET(TokenTypeTable)  ;BX points at table
    XLAT    CS:TokenTypeTable           ;have token type in AL
    XCHG    AH, AL                      ;token type in AH, character in AL

TokenValueLookup:                   ;get the token value
    MOV     BX, OFFSET(TokenValueTable) ;BX points at table
    XLAT    CS:TokenValueTable          ;have token value in AL

EndGetFPToken:                      ;done looking up type and value
    RET

GetFPToken    ENDP




; Token Tables
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;
; Author:           Glen George, Archan Luhar
; Last Modified:    Jan 23, 2014

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_OTHER, 0)     ;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)     ;SOH
        %TABENT(TOKEN_OTHER, 2)     ;STX
        %TABENT(TOKEN_OTHER, 3)     ;ETX
        %TABENT(TOKEN_OTHER, 4)     ;EOT
        %TABENT(TOKEN_OTHER, 5)     ;ENQ
        %TABENT(TOKEN_OTHER, 6)     ;ACK
        %TABENT(TOKEN_OTHER, 7)     ;BEL
        %TABENT(TOKEN_OTHER, 8)     ;backspace
        %TABENT(TOKEN_OTHER, 9)     ;TAB
        %TABENT(TOKEN_OTHER, 10)    ;new line
        %TABENT(TOKEN_OTHER, 11)    ;vertical tab
        %TABENT(TOKEN_OTHER, 12)    ;form feed
        %TABENT(TOKEN_RETURN, 13)   ;carriage return
        %TABENT(TOKEN_OTHER, 14)    ;SO
        %TABENT(TOKEN_OTHER, 15)    ;SI
        %TABENT(TOKEN_OTHER, 16)    ;DLE
        %TABENT(TOKEN_OTHER, 17)    ;DC1
        %TABENT(TOKEN_OTHER, 18)    ;DC2
        %TABENT(TOKEN_OTHER, 19)    ;DC3
        %TABENT(TOKEN_OTHER, 20)    ;DC4
        %TABENT(TOKEN_OTHER, 21)    ;NAK
        %TABENT(TOKEN_OTHER, 22)    ;SYN
        %TABENT(TOKEN_OTHER, 23)    ;ETB
        %TABENT(TOKEN_OTHER, 24)    ;CAN
        %TABENT(TOKEN_OTHER, 25)    ;EM
        %TABENT(TOKEN_OTHER, 26)    ;SUB
        %TABENT(TOKEN_OTHER, 27)    ;escape
        %TABENT(TOKEN_OTHER, 28)    ;FS
        %TABENT(TOKEN_OTHER, 29)    ;GS
        %TABENT(TOKEN_OTHER, 30)    ;AS
        %TABENT(TOKEN_OTHER, 31)    ;US
        %TABENT(TOKEN_OTHER, ' ')   ;space
        %TABENT(TOKEN_OTHER, '!')   ;!
        %TABENT(TOKEN_OTHER, '"')   ;"
        %TABENT(TOKEN_OTHER, '#')   ;#
        %TABENT(TOKEN_OTHER, '$')   ;$
        %TABENT(TOKEN_OTHER, 37)    ;percent
        %TABENT(TOKEN_OTHER, '&')   ;&
        %TABENT(TOKEN_OTHER, 39)    ;'
        %TABENT(TOKEN_OTHER, 40)    ;open paren
        %TABENT(TOKEN_OTHER, 41)    ;close paren
        %TABENT(TOKEN_OTHER, '*')   ;*
        %TABENT(TOKEN_PLUS, +1)     ;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)    ;,
        %TABENT(TOKEN_MINUS, -1)    ;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)     ;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')   ;/
        %TABENT(TOKEN_DIGIT, 0)     ;0  (digit)
        %TABENT(TOKEN_DIGIT, 1)     ;1  (digit)
        %TABENT(TOKEN_DIGIT, 2)     ;2  (digit)
        %TABENT(TOKEN_DIGIT, 3)     ;3  (digit)
        %TABENT(TOKEN_DIGIT, 4)     ;4  (digit)
        %TABENT(TOKEN_DIGIT, 5)     ;5  (digit)
        %TABENT(TOKEN_DIGIT, 6)     ;6  (digit)
        %TABENT(TOKEN_DIGIT, 7)     ;7  (digit)
        %TABENT(TOKEN_DIGIT, 8)     ;8  (digit)
        %TABENT(TOKEN_DIGIT, 9)     ;9  (digit)
        %TABENT(TOKEN_OTHER, ':')    ;:
        %TABENT(TOKEN_OTHER, ';')    ;;
        %TABENT(TOKEN_OTHER, '<')    ;<
        %TABENT(TOKEN_OTHER, '=')    ;=
        %TABENT(TOKEN_OTHER, '>')    ;>
        %TABENT(TOKEN_OTHER, '?')    ;?
        %TABENT(TOKEN_OTHER, '@')    ;@
        %TABENT(TOKEN_OTHER, 'A')    ;A
        %TABENT(TOKEN_OTHER, 'B')    ;B
        %TABENT(TOKEN_OTHER, 'C')    ;C
        %TABENT(TOKEN_SET_DIR, 'D')  ;Set Direction Command
        %TABENT(TOKEN_ELE_TUR, 'E')  ;Set Turret Elevation Command
        %TABENT(TOKEN_LAS_ON, 'F')   ;Laser On Command
        %TABENT(TOKEN_OTHER, 'G')    ;G
        %TABENT(TOKEN_OTHER, 'H')    ;H
        %TABENT(TOKEN_OTHER, 'I')    ;I
        %TABENT(TOKEN_OTHER, 'J')    ;J
        %TABENT(TOKEN_OTHER, 'K')    ;K
        %TABENT(TOKEN_OTHER, 'L')    ;L
        %TABENT(TOKEN_OTHER, 'M')    ;M
        %TABENT(TOKEN_OTHER, 'N')    ;N
        %TABENT(TOKEN_LAS_OFF, 'O')  ;Laser Off Command
        %TABENT(TOKEN_OTHER, 'P')    ;P
        %TABENT(TOKEN_OTHER, 'Q')    ;Q
        %TABENT(TOKEN_OTHER, 'R')    ;R
        %TABENT(TOKEN_ABS_SPEED, 'S');Set Absolute Speed Command
        %TABENT(TOKEN_ROT_TUR, 'T')  ;Rotate Turret Command
        %TABENT(TOKEN_OTHER, 'U')    ;U
        %TABENT(TOKEN_REL_SPEED, 'V');Set Relative Speed Command
        %TABENT(TOKEN_OTHER, 'W')    ;W
        %TABENT(TOKEN_OTHER, 'X')    ;X
        %TABENT(TOKEN_OTHER, 'Y')    ;Y
        %TABENT(TOKEN_OTHER, 'Z')    ;Z
        %TABENT(TOKEN_OTHER, '[')    ;[
        %TABENT(TOKEN_OTHER, 92)     ;backslash character
        %TABENT(TOKEN_OTHER, ']')    ;]
        %TABENT(TOKEN_OTHER, '^')    ;^
        %TABENT(TOKEN_OTHER, '_')    ;_
        %TABENT(TOKEN_OTHER, '`')    ;`
        %TABENT(TOKEN_OTHER, 'a')    ;a
        %TABENT(TOKEN_OTHER, 'b')    ;b
        %TABENT(TOKEN_OTHER, 'c')    ;c
        %TABENT(TOKEN_SET_DIR, 'd')  ;Set Direction Command
        %TABENT(TOKEN_ELE_TUR, 'e')  ;Set Turret Elevation Command
        %TABENT(TOKEN_LAS_ON, 'f')   ;Laser On Command
        %TABENT(TOKEN_OTHER, 'g')    ;g
        %TABENT(TOKEN_OTHER, 'h')    ;h
        %TABENT(TOKEN_OTHER, 'i')    ;i
        %TABENT(TOKEN_OTHER, 'j')    ;j
        %TABENT(TOKEN_OTHER, 'k')    ;k
        %TABENT(TOKEN_OTHER, 'l')    ;l
        %TABENT(TOKEN_OTHER, 'm')    ;m
        %TABENT(TOKEN_OTHER, 'n')    ;n
        %TABENT(TOKEN_LAS_OFF, 'o')  ;Laser Off Command
        %TABENT(TOKEN_OTHER, 'p')    ;p
        %TABENT(TOKEN_OTHER, 'q')    ;q
        %TABENT(TOKEN_OTHER, 'r')    ;r
        %TABENT(TOKEN_ABS_SPEED, 's');Set Absolute Speed Command
        %TABENT(TOKEN_ROT_TUR, 't')  ;Rotate Turret Command
        %TABENT(TOKEN_OTHER, 'u')    ;u
        %TABENT(TOKEN_REL_SPEED, 'v');Set Relative Speed Command
        %TABENT(TOKEN_OTHER, 'w')    ;w
        %TABENT(TOKEN_OTHER, 'x')    ;x
        %TABENT(TOKEN_OTHER, 'y')    ;y
        %TABENT(TOKEN_OTHER, 'z')    ;z
        %TABENT(TOKEN_OTHER, '{')    ;{
        %TABENT(TOKEN_OTHER, '|')    ;|
        %TABENT(TOKEN_OTHER, '}')    ;}
        %TABENT(TOKEN_OTHER, '~')    ;~
        %TABENT(TOKEN_OTHER, 127)    ;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable    LABEL   BYTE
        %TABLE


; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable    LABEL       BYTE
        %TABLE




CODE ENDS


DATA SEGMENT PUBLIC 'DATA'
    ; Keep track of the current state
    ParserCurrentState  DB  ?
    
    ; Shared variables necessary for parsing input digits
    inputNumIsNegative  DB  ?
    inputNumber         DW  ?
DATA ENDS


    END
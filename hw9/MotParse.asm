    NAME MOTPARSE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    MOTPARSE                                ;
;                              Motor Serial Parsing                          ;
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
;        1/20/2014      Archan Luhar    Started coding structure of the SM
;        1/23/2014      Archan Luhar    Finished coding
;        1/25/2014      Archan Luhar    Finished debugging
;        1/26/2014      Archan Luhar    Finished commenting
;        1/28/2014      Archan Luhar    Added code to output current status.



; Import necessary definitions and macros
$INCLUDE(general.inc)
$INCLUDE(MotParse.inc)
$INCLUDE(motors.inc)
$INCLUDE(events.inc)

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
    EXTRN   SetTurretAngle:NEAR         ; Turret procedures are dummies
    EXTRN   GetTurretAngle:NEAR
    EXTRN   SetRelTurretAngle:NEAR
    EXTRN   SetTurretElevation:NEAR
    EXTRN   GetTurretElevation:NEAR
    EXTRN   Dec2String:NEAR             ; Needed for converting status number
    EXTRN   SerialPutChar:NEAR          ; Needed for outputing status
    



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
    MOV SerialOutputText, ASCII_NULL
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
; Error Handling:   If parse error, sets current state to ST_INITIAL.
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



; inputNumClear
;
; Description:      This function resets the input number shared variable as
;                   well as the associated flags. Must call when starting
;                   the generation of a number.
;
; Operation:        Set inputNumIsNegative to FALSE.
;                   Set inputNumber to 0.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  None.
;
; Shared Variables: inputNumIsNegative (W)
;                   inputNumber        (W)
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
; Last Modified:    1/27/2014

inputNumClear   PROC    NEAR
    
    MOV inputNumIsNegative, FALSE
    MOV inputNumber, 0
    
    MOV AX, PARSE_SUCCESS
    RET

inputNumClear   ENDP


; inputNumNeg
;
; Description:      This function sets the negative sign flag of the input
;                   number to true. Should call when encountering a negative
;                   (-) symbol.
;
; Operation:        Set inputNumIsNegative to TRUE.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  None.
;
; Shared Variables: inputNumIsNegative (W)
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
; Last Modified:    1/27/2014

inputNumNeg     PROC    NEAR

    MOV inputNumIsNegative, TRUE

    MOV AX, PARSE_SUCCESS
    RET

inputNumNeg     ENDP


; inputNumDigit
;
; Description:      This function updates the input number with a new digit.
;                   For example a number 56 would be updated to 563 by calling
;                   this function with the argument 3.
;
; Operation:        Signed multiply current number by 10. If overflow, fail.
;                   Add digit to current number if positive. If overflow, fail.
;                   Subtract digit from current number if negative. Fail on OF.
;
; Arguments:        AX = new digit
;
; Return Value:     AX = parsing status = PARSE_SUCCESS or PARSE_FAILURE
;
; Local Variables:  CX = new digit
;                   BX = number base (10)
;                   AX = new number
;
; Shared Variables: inputNumIsNegative (R)
;                   inputNumber        (R/W)
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Multiply current number by 10 and add/subtract new digit.
;
; Data Structures:  None.
;
; Registers Used:   AX
;
; Stack Depth:      3
;
; Author:           Archan Luhar
; Last Modified:    1/27/2014

inputNumDigit   PROC    NEAR

BeginInputNumDigit:
    PUSH BX                     ; Save registers
    PUSH CX
    PUSH DX

InputNumDigitMakeSpace:
    ; Let CX be the new digit
    MOV CL, AL
    XOR CH, CH
    
    ; Get the current number and multiply it by 10 (shift places to the left)
    MOV AX, inputNumber
    MOV BX, INPUT_NUM_BASE
    IMUL BX                     ; (DX|AX) <-- AX * BX
    JO InputNumDigitFailure     ; Fail if overflows

    ; Jump to correct label based on if the current number is pos. or neg.
    CMP inputNumIsNegative, TRUE
    JE InputNumDigitSubDigit
    ;JNE InputNumDigitAddDigit

InputNumDigitAddDigit:
    ; Number is positive, add the digit
    ADD AX, CX
    JO InputNumDigitFailure     ; Fail if overflows
    JMP InputNumDigitSuccess

InputNumDigitSubDigit:
    ; Number is negative, subtract the digit
    SUB AX, CX
    JO InputNumDigitFailure     ; Fail if overflows
    ;JMP InputNumDigitSuccess

InputNumDigitSuccess:
    ; Update the shared variable and indicate parsing success
    MOV inputNumber, AX
    MOV AX, PARSE_SUCCESS
    JMP EndInputNumDigit

InputNumDigitFailure:
    ; Don't update the shared variable and indicate parsing failure
    MOV AX, PARSE_FAILURE
    ;JMP EndInputNumDigit

EndInputNumDigit:               ; Restore registers
    POP DX
    POP CX
    POP BX
    RET                         ; Return

inputNumDigit   ENDP




; doNOP
;
; Description:      This function does nothing but return PARSE_SUCCESS.
;                   Should be the "transition" function of a state when
;                   it is simply ignoring the character.
;
; Operation:        Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
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
    MOV AX, PARSE_SUCCESS
    RET
doNOP           ENDP


; doError
;
; Description:      This function does nothing but return PARSE_FAILURE.
;                   Should be the "transition" function of a state when
;                   it encounters an invalid command/character.
;
; Operation:        Return PARSE_FAILURE in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_FAILURE
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

doError         PROC    NEAR
    MOV AX, PARSE_FAILURE
    RET
doError         ENDP



; doSetAbsSpeed
;
; Description:      This function sets the motor speed according to the input
;                   number generated.
;                   Should be the "transition" function of the S state when
;                   it encounters a return \r character.
;
; Operation:        Call SetMotorSpeed with inputNumber and NO_CHANGE_ANGLE.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  AX = inputNumber (speed)
;                   BX = NO_CHANGE_ANGLE (angle)
;
; Shared Variables: inputNumber (R)
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
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doSetAbsSpeed           PROC    NEAR

    ; Save Register
    PUSH BX

    ; Get input number as speed and don't change angle
    MOV AX, inputNumber
    MOV BX, NO_CHANGE_ANGLE
    CALL SetMotorSpeed

    ; Output status
    CALL SerialOutSpeed
    
    ; Successfully parsed
    MOV AX, PARSE_SUCCESS
    
    ; Pop Register and return
    POP BX
    RET

doSetAbsSpeed           ENDP


; doSetRelSpeed
;
; Description:      This function increases/decreases the motor speed as
;                   determined by the inputNumber which signifies the
;                   amount to change.
;                   Should be the "transition" function of the V state when
;                   it encounters a return \r character.
;
; Operation:        Determine new speed by getting current speed and adding the
;                   input number to the current speed. If overflows when adding
;                   saturate to MAX_SPEED. If underflows when subtracting then
;                   saturate to 0.
;                   Call SetMotorSpeed with new speed and NO_CHANGE_ANGLE.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  CX = temporary variable for storing old speed
;                   AX = new speed (speed)
;                   BX = NO_CHANGE_ANGLE (angle)
;
; Shared Variables: inputNumber (R)
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
; Stack Depth:      2 words + call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doSetRelSpeed           PROC    NEAR

BeginDoSetRelSpeed:
    PUSH BX                             ; Save registers
    PUSH CX

    CALL GetMotorSpeed                  ; AX = Get the current motor speed
    MOV BX, inputNumber                 ; BX = Get the change in speed
    CMP inputNumIsNegative, TRUE        ; If change is negative
    JE doSetRelSpeedSatSub              ; jump to proper point
    ;JNE doSetRelSpeedSatAdd

    
doSetRelSpeedSatAdd:                    ; Increment motor speed and saturate
    MOV CX, AX                          ; Temporarily store current speed
    ADD AX, BX                          ; Add the change

    CMP AX, NO_CHANGE_SPEED             ; If after change new speed is no change
    JE doSetRelSpeedSatUp               ; speed, saturate to correct max speed.

    CMP AX, CX                          ; If after the change the new speed
    JAE doSetRelSpeedDoSet              ; is (unsigned) >= old, all is good.
    ;JNA doSetRelSpeedSatUp             ; Else, saturate to max speed.

doSetRelSpeedSatUp:
    MOV AX, MAX_SPEED                   ; Saturate to max speed and set it.
    JMP doSetRelSpeedDoSet

    
doSetRelSpeedSatSub:
    NEG BX
    CMP BX, AX                          ; Check if change will result in
    JA doSetRelSpeedSatDown             ; underflow. If so, saturate down.
    SUB AX, BX                          ; Else subtract the |change| from
    JMP doSetRelSpeedDoSet              ; current speed and set new speed.

doSetRelSpeedSatDown:
    MOV AX, 0                           ; Saturate down to 0.
    ;JMP doSetRelSpeedDoSet

    
doSetRelSpeedDoSet:
    MOV BX, NO_CHANGE_ANGLE             ; Don't change angle
    CALL SetMotorSpeed                  ; Set the new speed

    ;JMP EndDoSetRelSpeed

EndDoSetRelSpeed:
    ; Output status
    CALL SerialOutSpeed
    
    MOV AX, PARSE_SUCCESS               ; Indicate parsing success
    POP CX                              ; Restore registers
    POP BX
    RET                                 ; Return

doSetRelSpeed           ENDP



; doSetDirection
;
; Description:      This function increases/decreases the motor direction as
;                   determined by the inputNumber which signifies the
;                   angle amount to change.
;                   Should be the "transition" function of the D state when
;                   it encounters a return \r character.
;
; Operation:        Determine new direction by getting current direciton and
;                   adding the normalized input number angle to the current
;                   direction. The angle is normalized by taking modulo
;                   360 if positive, or 360 - (abs value modulo 360) if neg.
;                   Call SetMotorSpeed with NO_CHANGE_SPEED and new angle.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  AX = temporary normalized new angle
;                   AX = NO_CHANGE_SPEED (speed)
;                   BX = new angle (angle)
;
; Shared Variables: inputNumber (R)
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
; Stack Depth:      2 words + call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014
doSetDirection           PROC    NEAR

BeginDoSetDirection:
    PUSH BX
    PUSH DX

doSetDirectionNormalizeAngle:   ; The following block of code normalizes
    MOV AX, inputNumber         ; the given angle to be between 0 and 360
    CMP AX, 0
    JGE doSetDirectionAngleIsPositive

doSetDirectionAngleIsNegative:  ; If the angle given is negative then
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
    CALL GetMotorDirection      ; Get the current direction and
    ADD BX, AX                  ; add in the new normalized angle.
    
    MOV AX, NO_CHANGE_SPEED     ; Don't change speed
    CALL SetMotorSpeed          ; AX = no speed change, BX = new angle.

    ;JMP EndDoSetDirection

EndDoSetDirection:
    ; Output status
    CALL SerialOutDirection
    
    MOV AX, PARSE_SUCCESS       ; Indicate parsing success
    POP DX                      ; Restore registers
    POP BX
    RET                         ; All done, return

doSetDirection           ENDP



; doRotateTurretAbs
;
; Description:      This function sets the turret angle to that specified
;                   by the input number angle.
;                   Should be the "transition" function of the T state when
;                   it is directly followed by digits and then it
;                   encounters a return \r character.
;
; Operation:        Call SetTurretAngle with inputNumber argument in AX.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  AX = inputNumber (angle)
;
; Shared Variables: inputNumber (R)
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
; Stack Depth:      1 call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doRotateTurretAbs           PROC    NEAR

    ; Get angle and call setter function
    MOV AX, inputNumber
    CALL SetTurretAngle

    ; Indicate success and return
    MOV AX, PARSE_SUCCESS
    RET

doRotateTurretAbs           ENDP


; doRotateTurretAbs
;
; Description:      This function changes the turret angle by the amount
;                   specified by the input number angle.
;                   Should be the "transition" function of the T state when
;                   it is followed by a sign (+/-) and digits and then it
;                   encounters a return \r character.
;
; Operation:        Call SetRelTurretAngle with inputNumber argument in AX.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  AX = inputNumber (angle)
;
; Shared Variables: inputNumber (R)
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
; Stack Depth:      1 call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doRotateTurretRel           PROC    NEAR

    ; Get angle and call relative setter function
    MOV AX, inputNumber
    CALL SetRelTurretAngle

    ; Indicate success and return
    MOV AX, PARSE_SUCCESS
    RET

doRotateTurretRel           ENDP


; doSetTurretElevation
;
; Description:      This function sets the turret elevation to that specified
;                   by the input number angle.
;                   Should be the "transition" function of the E state when
;                   it is followed by (optional + sign and) digits and then it
;                   encounters a return \r character.
;
; Operation:        Call SetTurretElevation with inputNumber argument in AX.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  AX = inputNumber (angle)
;
; Shared Variables: inputNumber (R)
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
; Stack Depth:      1 call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doSetTurretElevation    PROC    NEAR

    ; Get angle and call setter function
    MOV AX, inputNumber
    CALL SetTurretElevation

    ; Indicate success and return
    MOV AX, PARSE_SUCCESS
    RET

doSetTurretElevation    ENDP



; doLaserOn
;
; Description:      This function turns on the laser.
;                   Should be the "transition" function of the F state when
;                   it is followed by a return \r character.
;
; Operation:        Call SetLaser with TRUE argument in AX.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  AX = laser state = TRUE
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
; Stack Depth:      1 call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doLaserOn       PROC    NEAR

    ; Set laser status to TRUE, on
    MOV AX, TRUE
    CALL SetLaser
    
    ; Output status
    CALL SerialOutLaser

    ; Indicate success and return
    MOV AX, PARSE_SUCCESS
    RET

doLaserOn       ENDP


; doLaserOff
;
; Description:      This function turns off the laser.
;                   Should be the "transition" function of the F state when
;                   it is followed by a return \r character.
;
; Operation:        Call SetLaser with FALSE argument in AX.
;                   Return PARSE_SUCCESS in AX.
;
; Arguments:        None.
;
; Return Value:     AX = parsing status = PARSE_SUCCESS
;
; Local Variables:  AX = laser state = FALSE
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
; Stack Depth:      1 call
;
; Author:           Archan Luhar
; Last Modified:    1/24/2014

doLaserOff      PROC    NEAR

    ; Set laser status to FALSE, off
    MOV AX, FALSE
    CALL SetLaser
    
    ; Output status
    CALL SerialOutLaser

    ; Indicate success and return
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



        
        

; SerialOutOutputText
;
; Description:      Outputs the SerialOutputText string via serial.
;
; Operation:        Go through each character of SerialOutputText and queue
;                   it up for serial. Then queue up to serial the end character.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  AL = argument for SerialPutChar
; Shared Variables: SerialOutputText (R)
; Global Variables: None.
;
; Input:            None.
; Output:           Queues up characters for output via serial port.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      2 words + call
;
; Author:           Archan Luhar
; Last Modified:    Jan. 28, 2014

SerialOutOutputText PROC    NEAR

BeginSerialOutOutputText:
    PUSH AX
    PUSH DI
    MOV DI, OFFSET(SerialOutputText)

LoopSerialOutOutputText:
    CMP BYTE PTR [DI], ASCII_NULL
    JE EndSerialOutOutputText
    
    MOV AL, BYTE PTR [DI]
    CALL SerialPutChar
    INC DI
    
    JMP LoopSerialOutOutputText

EndSerialOutOutputText:
    MOV AL, SCHAR_END
    CALL SerialPutChar

    POP DI
    POP AX
    RET

SerialOutOutputText ENDP


; SerialOutSpeed
;
; Description:      Outputs the current speed status via serial. Should be
;                   called after changing the motor speed.
;
; Operation:        Output the characters "SPEED" followed by the actual speed
;                   converted to a string representing the percentage of the max
;                   speed.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  AL = argument for SerialPutChar
;                   BX = divisor to convert speed to percentage
;                   BX = intermediate register for copying DS to ES
;                   ES:SI = DS:offset to start of buffer to write percent chars
;
; Shared Variables: SerialOutputText (W)
; Global Variables: None.
;
; Input:            None.
; Output:           Queues up characters for output via serial port.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      5 words + call
;
; Author:           Archan Luhar
; Last Modified:    Jan. 28, 2014

SerialOutSpeed      PROC    NEAR

    PUSH BX
    PUSH SI
    PUSH ES
    PUSH AX
    PUSH DX
    
    MOV AL, 'S'
    CALL SerialPutChar
    MOV AL, 'P'
    CALL SerialPutChar
    MOV AL, 'E'
    CALL SerialPutChar
    MOV AL, 'E'
    CALL SerialPutChar
    MOV AL, 'D'
    CALL SerialPutChar
    
    CALL GetMotorSpeed
    XOR DX, DX
    MOV BX, 655  ; 1 percent of MAX_SPEED
    DIV BX
    ; Speed percentage is now in AX
    
    MOV BX, DS
    MOV ES, BX
    MOV SI, OFFSET(SerialOutputText)
    CALL Dec2String
    CALL SerialOutOutputText
    
    POP DX
    POP AX
    POP ES
    POP SI
    POP BX
    RET
    
SerialOutSpeed      ENDP


; SerialOutDirection
;
; Description:      Outputs the current direction status via serial. Should be
;                   called after changing the motor direction.
;
; Operation:        Output the characters "DIREC" followed by the direction as
;                   the degree number converted to string representation.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  AL = argument for SerialPutChar
;                   BX = intermediate register for copying DS to ES
;                   ES:SI = DS:offset to start of buffer to write percent chars
;
; Shared Variables: SerialOutputText (W)
; Global Variables: None.
;
; Input:            None.
; Output:           Queues up characters for output via serial port.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      f words + call
;
; Author:           Archan Luhar
; Last Modified:    Jan. 28, 2014

SerialOutDirection  PROC    NEAR

    PUSH BX
    PUSH SI
    PUSH ES
    PUSH AX
    
    MOV AL, 'D'
    CALL SerialPutChar
    MOV AL, 'I'
    CALL SerialPutChar
    MOV AL, 'R'
    CALL SerialPutChar
    MOV AL, 'E'
    CALL SerialPutChar
    MOV AL, 'C'
    CALL SerialPutChar
    
    CALL GetMotorDirection
    ; Direction (0 to 360) is now in AX
    
    MOV BX, DS
    MOV ES, BX
    MOV SI, OFFSET(SerialOutputText)
    CALL Dec2String
    CALL SerialOutOutputText
    
    POP AX
    POP ES
    POP SI
    POP BX
    RET

SerialOutDirection  ENDP


; SerialOutDirection
;
; Description:      Outputs the current laser status via serial. Should be
;                   called after changing the laser power on or off.
;
; Operation:        Output the characters "LASER" followed by the "ON" if the
;                   laser is on or "OFF" if it is off. Output the end char to
;                   signify end of string.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  AL = argument for SerialPutChar
;
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           Queues up characters for output via serial port.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    Jan. 28, 2014

SerialOutLaser      PROC    NEAR

BeginSerialOutLaser:
    PUSH AX
    
    MOV AL, 'L'
    CALL SerialPutChar
    MOV AL, 'A'
    CALL SerialPutChar
    MOV AL, 'S'
    CALL SerialPutChar
    MOV AL, 'E'
    CALL SerialPutChar
    MOV AL, 'R'
    CALL SerialPutChar

    CALL GetLaser
    CMP AX, TRUE
    JE SerialOutLaserOn
    
SerialOutLaserOff:
    MOV AL, 'O'
    CALL SerialPutChar
    MOV AL, 'F'
    CALL SerialPutChar
    MOV AL, 'F'
    CALL SerialPutChar
    JMP EndSerialOutLaser
    
SerialOutLaserOn:
    MOV AL, 'O'
    CALL SerialPutChar
    MOV AL, 'N'
    CALL SerialPutChar
    JMP EndSerialOutLaser

EndSerialOutLaser:
    MOV AL, SCHAR_END
    CALL SerialPutChar

    POP AX
    RET

SerialOutLaser      ENDP


CODE ENDS


DATA SEGMENT PUBLIC 'DATA'

    ; Keep track of the current state
    ParserCurrentState  DB  ?
    
    ; Shared variables necessary for parsing input digits
    inputNumIsNegative  DB  ?
    inputNumber         DW  ?
    
    ; Temporary buffer for writing status numbers (e.g. speed -> string)
    SerialOutputText        DB  MAX_TEXT_LENGTH DUP (?)

DATA ENDS


    END
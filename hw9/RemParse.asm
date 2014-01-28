    NAME REMPARSE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    REMPARSE                                ;
;                              Remote Serial Parsing                         ;
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
$INCLUDE(events.inc)

; setup code and data groups
    CGROUP  GROUP   CODE
    DGROUP  GROUP   DATA

; segment register assumptions
    ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP



CODE    SEGMENT PUBLIC 'CODE'

; External References
    EXTRN   Display:NEAR
    



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

    MOV SerialInputText, ASCII_NULL
    MOV SerialInputTextIndex, 0
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

    CMP AL, SCHAR_END
    JNE ParseSerialCharAddChar
    ;JE ParseSerialCharDisplay

ParseSerialCharDisplay:
    PUSH ES
    PUSH SI
    
    MOV BX, DS
    MOV ES, BX
    MOV SI, OFFSET(SerialInputText)
    CALL Display
    
    ; Reset
    CALL InitSerialParser
    
    POP SI
    POP ES
    JMP EndParseSerialChar

ParseSerialCharAddChar:
    MOV BX, SerialInputTextIndex
    
    CMP BX, MAX_TEXT_LENGTH - 2
    JAE EndParseSerialChar
    
    MOV SerialInputText[BX], AL
    
    INC BX
    MOV SerialInputText[BX], ASCII_NULL
    
    MOV SerialInputTextIndex, BX
    ;JMP EndParseSerialChar
    
EndParseSerialChar:
    POP BX
    RET

ParseSerialChar ENDP



CODE ENDS


DATA SEGMENT PUBLIC 'DATA'

    SerialInputTextIndex    DW                  ?
    SerialInputText         DB  MAX_TEXT_LENGTH DUP (?)

DATA ENDS


    END
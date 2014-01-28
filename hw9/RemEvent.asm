    NAME    REMEVENT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   REMEVENT                                 ;
;                          Remote Unit  Event Functions                      ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the event handler for the remote unit.
;
; The included public functions are:
;   - EventHandler
;           Handles a local event given event type in AH and value in AL.
;
; Revision History:
;        1/24/2014      Archan Luhar    Wrote event handler for remote unit.

$INCLUDE(general.inc)
$INCLUDE(events.inc)


CGROUP  GROUP   CODE
CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

; External References
    EXTRN   ParseKey:NEAR
    EXTRN   ParseSerialChar:NEAR
    EXTRN   Display:NEAR



STRING_ERROR LABEL BYTE 
    DB 'ERROR'
    DB ASCII_NULL

STRING_SERIAL_ERROR LABEL BYTE
    DB 'SRL ERR'
    DB ASCII_NULL


; EventHandler
;
; Description:      Handles local (as supposed to system wide) events.
;                   Should be called with an event that is dequeued from the
;                   event queue.
;
; Operation:        Compare the event type to serial error event code or
;                   serial character received code. Execute ParseSerialChar
;                   if character received. Execute ParseKey if switch pressed.
;                   Display serial error if serial error event. Display general
;                   error otherwise.
;
; Arguments:        AH, AL = event type, event value
; Return Value:     None.
;
; Local Variables:  AL = argument for SerialPutChar or ParseSerialChar
;                   ES:SI = CS:SI pointer to error string
;
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           Queues up character for output via serial port.
;
; Error Handling:   Bad events result in error beign displayed.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      3 words + call
;
; Author:           Archan Luhar
; Last Modified:    Jan. 28, 2014

EventHandler        PROC        NEAR
                    PUBLIC      EventHandler

BeginEventHandler:
    CMP AH, EVENT_KEYPRESS
    JE DoKeypressEvent

    CMP AH, EVENT_SERIAL_CHAR
    JE DoSerialCharEvent
    
    ;JMP CheckErrorEvents


BeginErrorEvents:
    PUSH ES
    PUSH SI
    PUSH BX
    MOV BX, CS
    MOV ES, BX ; Must have error now

    CMP AH, EVENT_SERIAL_ERROR
    JE DoSerialErrorEvent
    
    ;JMP DoEventErrorEvent

DoEventErrorEvent:
    MOV SI, OFFSET(STRING_ERROR)
    JMP EndErrorEvents

DoSerialErrorEvent:
    MOV SI, OFFSET(STRING_SERIAL_ERROR)
    ;JMP EndErrorEvents

EndErrorEvents:
    CALL Display
    POP BX
    POP SI
    POP ES
    JMP EndEventHandler

    
DoKeypressEvent:
    CALL ParseKey           ; Key value arg is in AL already
    JMP EndEventHandler

DoSerialCharEvent:
    CALL ParseSerialChar
    ;JMP EndEventHandler

EndEventHandler:
    RET

EventHandler	    ENDP



CODE ENDS

END
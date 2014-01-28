    NAME    MOTEVENT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   MOTEVENT                                 ;
;                           Motor Unit Event Functions                       ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the event handler for the motor unit.
;
; The included public functions are:
;   - EventHandler
;           Handles a local event given event type in AH and value in AL.
;
; Revision History:
;        1/24/2014      Archan Luhar    Wrote event handler for motor unit.


$INCLUDE(events.inc)
$INCLUDE(MotParse.inc)


CGROUP  GROUP   CODE
CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

EXTRN   SerialPutChar:NEAR
EXTRN   ParseSerialChar:NEAR
        

; EventHandler
;
; Description:      Handles local (as supposed to system wide) events.
;                   Should be called with an event that is dequeued from the
;                   event queue.
;
; Operation:        Compare the event type to serial error event code or
;                   serial character received code. Execute ParseSerialChar
;                   if character received. Output via serial an error message
;                   otherwise.
;
; Arguments:        AH, AL = event type, event value
; Return Value:     None.
;
; Local Variables:  AL = argument for SerialPutChar or ParseSerialChar
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           Queues up character for output via serial port.
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

EventHandler        PROC        NEAR
                    PUBLIC      EventHandler

BeginEventHandler:
    PUSH AX
    CMP AH, EVENT_SERIAL_CHAR
    JE DoSerialCharEvent
    ;JNE DoSerialErrorEvent

DoSerialErrorEvent:
    MOV AL, SCHAR_END
    CALL SerialPutChar
    MOV AL, SCHAR_SERIAL_ERROR
    CALL SerialPutChar
    MOV AL, SCHAR_END
    CALL SerialPutChar
    JMP EndEventHandler

DoSerialCharEvent:
    CALL ParseSerialChar
    CMP AX, PARSE_FAILURE
    JE DoSerialErrorEvent
    ;JMP EndEventHandler

EndEventHandler:
    POP AX
    RET

EventHandler	    ENDP



CODE ENDS

END
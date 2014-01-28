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


$INCLUDE(events.inc)
$INCLUDE(MotParse.inc)


CGROUP  GROUP   CODE
CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

EXTRN   SerialPutChar:NEAR
EXTRN   ParseSerialChar:NEAR
        

EventHandler        PROC        NEAR
                    PUBLIC      EventHandler

BeginEventHandler:
    CMP AH, EVENT_SERIAL_CHAR
    JE DoSerialCharEvent
    ;JNE DoSerialErrorEvent

DoSerialErrorEvent:
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
    RET

EventHandler	    ENDP



CODE ENDS

END
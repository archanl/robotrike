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
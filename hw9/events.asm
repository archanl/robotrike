    NAME    EVENTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    EVENTS                                  ;
;                             General Event Functions                        ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


$INCLUDE(events.inc)
$INCLUDE(queue.inc)


CGROUP  GROUP   CODE
CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

; External References
    EXTRN   QueueInit:NEAR
    EXTRN   Dequeue:NEAR
    EXTRN   Enqueue:NEAR

    
InitEventQueue  PROC    NEAR
                PUBLIC  InitEventQueue

	PUSH AX
	PUSH SI
	
    MOV     SI, OFFSET(eventQueue)   ; Let SI be the pointer to the queue
    MOV     AX, EVENTS_QUEUE_LENGTH ; Set size to that defined in inc
    MOV     BL, QUEUE_WORD_ELEM     ; Set element size to byte (characters)
    CALL    QueueInit               ; Initialize the queue metadata.
	
	POP SI
	POP AX
    
    RET

InitEventQueue  ENDP

EnqueueEvent  PROC    NEAR
                PUBLIC  EnqueueEvent

	PUSH SI
	
    MOV     SI, OFFSET(eventQueue)   ; Let SI be the pointer to the queue
    CALL    Enqueue               ; Initialize the queue metadata.
	
	POP SI
    
    RET

EnqueueEvent  ENDP

DequeueEvent  PROC    NEAR
                PUBLIC  DequeueEvent

    PUSH SI
	
    MOV     SI, OFFSET(eventQueue)   ; Let SI be the pointer to the queue
    CALL    Dequeue               ; Initialize the queue metadata.
	
	POP SI
    
    RET

DequeueEvent  ENDP



CODE ENDS


DATA SEGMENT PUBLIC 'DATA'
    eventQueue      queueSTRUC  <>              ; queue buffers received events
DATA ENDS

END
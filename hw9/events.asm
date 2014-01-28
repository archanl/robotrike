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

; This file contains the functions and data for the local event queue.
;
; The included public functions are:
;   - InitEventQueue
;           Initializes the event queue. Must be called at start of program.
;   - EnqueueEvent
;           Enqueues AX = AH, AL = event type, event value in the event queue.
;   - DequeueEvent
;           Dequeues event AX = AH, AL = event type, event value
;
; Revision History:
;        1/26/2014      Archan Luhar    Wrote events file.


$INCLUDE(events.inc)
$INCLUDE(queue.inc)


CGROUP  GROUP   CODE
CODE	SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

; External References
    EXTRN   QueueInit:NEAR
    EXTRN   Dequeue:NEAR
    EXTRN   Enqueue:NEAR

    
; InitEventQueue
;
; Description:      Initializes event queue. Must be called at start of program.
;
; Operation:        Calls initialization function QueueInit on eventQueue shared
;                   variable.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  AX = queue length
;                   BL = queue element type (word)
;                   SI = queue offset
;
; Shared Variables: eventQueue (W)
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   None.
; Stack Depth:      3 words + call
;
; Author:           Archan Luhar
; Last Modified:    Jan. 27, 2014

InitEventQueue  PROC    NEAR
                PUBLIC  InitEventQueue

	PUSH AX
    PUSH BX
	PUSH SI
	
    MOV     SI, OFFSET(eventQueue)   ; Let SI be the pointer to the queue
    MOV     AX, EVENTS_QUEUE_LENGTH ; Set size to that defined in inc
    MOV     BL, QUEUE_WORD_ELEM     ; Set element size to byte (characters)
    CALL    QueueInit               ; Initialize the queue metadata.
	
	POP SI
    POP BX
	POP AX
    
    RET

InitEventQueue  ENDP


; EnqueueEvent
;
; Description:      Enqueues an event to the event queue.
;
; Operation:        Call Enqueue on the eventQueue.
;
; Arguments:        AH, AL = event type, event value
; Return Value:     None.
;
; Local Variables:  SI = queue offset
;
; Shared Variables: eventQueue (R/W)
; Global Variables: None.
;
; Input:            None.
; Output:           None.
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
; Last Modified:    Jan. 27, 2014

EnqueueEvent  PROC    NEAR
                PUBLIC  EnqueueEvent

	PUSH SI
	
    MOV     SI, OFFSET(eventQueue)   ; Let SI be the pointer to the queue
    CALL    Enqueue               ; Initialize the queue metadata.
	
	POP SI
    
    RET

EnqueueEvent  ENDP


; DequeueEvent
;
; Description:      Dequeues an event from the event queue.
;
; Operation:        Call Dequeue on the eventQueue.
;
; Arguments:        None.
; Return Value:     AH, AL = event type, event value
;
; Local Variables:  SI = queue offset
;
; Shared Variables: eventQueue (R/W)
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   AX
; Stack Depth:      1 word + call
;
; Author:           Archan Luhar
; Last Modified:    Jan. 27, 2014

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
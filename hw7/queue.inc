;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    QUEUE                                   ;
;                       Queue Routine Include Definitions                    ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Defines queue metadata byte offset constants and test function constants

QUEUE_TEST_LENGTH 			EQU     256

; Number of bytes of metadata before the queue elements data starts
QUEUE_QUEUE_OFFSET          EQU     7

; Maximum number of bytes of queue data in the queue struct.
; The queue struct must me initialized with less bytes than this max number.
; E.g. 256 word sized elements = 512 bytes: good
; E.g. 512 byte sized elements = 512 bytes: good
QUEUE_MAX_BYTES             EQU     256

; Defines the two types of elements in the queue
QUEUE_BYTE_ELEM             EQU 0
QUEUE_WORD_ELEM             EQU 1

; Defines the number of bytes in the two possible element sizes byte and word
ELEM_BYTE_SIZE              EQU     1
ELEM_WORD_SIZE              EQU     2


; Queue Structure which defines the metadata and the start of the queue
; elements data.
; elem_size:    1 if each element is byte, 2 if each element is a word
; len:          Max number of elements in queue
; head_index: 	Number of elements offset from start of queue elements data
; count:        Current number of elements in the queue.
; queue:        Start of queue elements.
queueSTRUC STRUC 
    elem_size   DB  ?
    len         DW  ? 
    head_index  DW  ?
    count       DW  ?
    queue       DB  QUEUE_MAX_BYTES DUP (?)
queueSTRUC ENDS
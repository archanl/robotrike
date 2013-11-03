    NAME    HW3MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3MAIN                                  ;
;                             Homework 3 Main Loop                           ;
;                                  EE/CS 51                                  ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program allocates space for myQueue and calls my own
;                   defined MyQueueTest which is used for stepping through
;                   element enqueuing and dequeuing to check correct memory.
;                   This program also calls the QueueTest function provided by
;                   Glen.
;
; Input:            None.
; Output:           None.
;
; User Interface:   None. User can set breakpoint at MyQueueTest to step through
;                   sample queue additions and removals to see changes in
;                   the memory storing the queue.
;                   If QueueTest succeeds, infinite loop occurs at
;                   breakpoint hw3test.QueueGood.
;
; Error Handling:   If QueueTest fails, infinite loop occurs at breakpoint
;                   hw3test.QueueError.
;
; Algorithms:       None.
; Data Structures:  Queue struct is defined in queue.inc. It uses a cyclic array
;
; Known Bugs:       None.
; Limitations:      There must be less than 1024 bytes of elements.
;
; Revision History:
;    11/02/13  Archan Luhar     Created hw3main.asm. Contains main function
;                               that calls test functions. Also allocates
;                               queue struct in DS.


; Include file defines queue metadata offset constants
$INCLUDE(queue.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


    ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations

    EXTRN   QueueInit:NEAR
    EXTRN   QueueEmpty:NEAR
    EXTRN   QueueFull:NEAR
    EXTRN   Dequeue:NEAR
    EXTRN   Enqueue:NEAR
    EXTRN   QueueTest:NEAR



START:  

MAIN:
    MOV     AX, DGROUP              ;initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ;initialize the data segment
    MOV     DS, AX

    MOV     SI, OFFSET(myQueue)     ; Let SI be the pointer to the queue
    MOV     AX, QUEUE_TEST_LENGTH   ; Set size to that defined in inc
    MOV     BL, ELEM_BYTE_SIZE      ; Set element size to byte
    CALL    QueueInit               ; Initialize the queue

    CALL    MyQueueTest             ; Test out the queue briefly

    MOV     CX, QUEUE_TEST_LENGTH   ; Pass the queue and queue length to
    CALL    QueueTest               ; provided test function.


; Enqueues a bunch of numbers to see if properly stored. Must use debugger
; to verify queue data in memory at SI.
MyQueueTest:
    MOV AL, 1002H;
    CALL Enqueue;
    MOV AX, 3004H;
    CALL Enqueue;
    MOV AX, 5006H;
    CALL Enqueue;
    MOV AX, 7008H;
    CALL Enqueue;
    MOV AX, 9000H;
    CALL Enqueue;
    CALL QueueEmpty;
    CALL QueueFull;
    CALL Dequeue;

DATA SEGMENT PUBLIC 'DATA'
    myQueue   queueSTRUC  <>
DATA ENDS


STACK SEGMENT STACK 'STACK'
    DB      80 DUP ('Stack ')       ;240 words
TopOfStack      LABEL   WORD
STACK  ENDS


CODE ENDS
    END START

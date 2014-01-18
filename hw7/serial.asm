    NAME SERIAL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     SERIAL                                 ;
;                                 SERIAL Routine                             ;
;                                    EE/CS 51                                ;
;                                  Archan Luhar                              ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    EXTRN   QueueInit:NEAR
    EXTRN   QueueEmpty:NEAR
    EXTRN   QueueFull:NEAR
    EXTRN   Dequeue:NEAR
    EXTRN   Enqueue:NEAR
    

$INCLUDE(queue.inc)


; InitSerialPort
;
; Description:      This procedure initializes the serial port.  It sets it to
;                   eight data bits, no parity, one stop bit, 9600 baud, and
;                   no interrupts.  DTR and RTS are both set active.
;
; Operation:        The initialization values are written to the serial chip
;                   and the error status is cleared.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None.
; Shared Variables: ErrorBits - set to NO_ERROR.
; Global Variables: None.
;
; Input:            None.
; Output:           DTR and RTS are set to one.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   AX, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Feb. 6, 2003

InitSerialPort  PROC    NEAR
                PUBLIC  InitSerialPort


Init82050:                              ;initialize the 82050

        MOV     SI, OFFSET(receiveQueue); Let SI be the pointer to the queue
        MOV     AX, SERIAL_QUEUE_LENGTH ; Set size to that defined in inc
        MOV     BL, ELEM_BYTE_SIZE      ; Set element size to byte
        CALL    QueueInit               ; Initialize the queue
        
        MOV     SI, OFFSET(sendQueue)   ; Let SI be the pointer to the queue
        MOV     AX, SERIAL_QUEUE_LENGTH ; Set size to that defined in inc
        MOV     BL, ELEM_BYTE_SIZE      ; Set element size to byte
        CALL    QueueInit               ; Initialize the queue
        
        
        
        MOV     DX, SERIAL_LCR          ;talk to the baud rate divisor registers
        MOV     AL, ENABLE_BRG_ACC
        OUT     DX, AL

        MOV     DX, SERIAL_BRG_DIV      ;set the baud rate divisor
        MOV     AX, BAUD9600
        OUT     DX, AL                  ;write a byte at a time
        INC     DX
        MOV     AL, AH
        OUT     DX, AL

        MOV     DX, SERIAL_LCR          ;set all parameters in the line
        MOV     AL, SERIAL_SETUP        ;    control register
        OUT     DX, AL                  ;   (also changes access back to Rx/Tx)

        ; Install serial interrupt handler into the vector table
        InstallVector(INT_VEC_SERIAL, SerialInterruptHandler)
        
        MOV     DX, SERIAL_IER          ;enable interrupts
        MOV     AL, SERIAL_EN_IRQ
        OUT     DX, AL

        MOV     DX, SERIAL_MCR                  ;set the modem control lines
        MOV     AL, SERIAL_RTS + SERIAL_DTR     ;RTS and DTR both on
        OUT     DX, AL

        ;JMP    InitErrorStatus         ;now initialize the error status


InitErrorStatus:                        ;reset the error status
        MOV     ErrorBits, NO_ERROR
        ;JMP    EndInitSerialPort       ;all done initializing error status


EndInitSerialPort:                      ;done initializing the serial port -
        RET                             ;   return


InitSerialPort  ENDP



; SerialPutChar
;
; Description:      This function adds a character to a queue to be sent
;                   over the serial interface.
;
; Operation:        Enqueues character to serial buffer queue.
;                   If queue was full, sets the carry flag and returns. If not,
;                   clears the carry flag.
;
; Arguments:        AL - character to put to serial
;
; Return Value:     Carry flag - clear if successful, set if failed (full queue)
;
; Local Variables:  -
;
; Shared Variables: serial_queue - READ/WRITE
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
; Registers Used:   Carry flag.
;
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/25/2013
;
; Pseudocode
; ----------
;                   if serial_queue is not full:
;                       serial_queue.enqueue(char)
;                       clear carry flag
;                   else:
;                       set carry flag
;                   return
;


; SerialInterruptHandler
;
; Description:      Handles the serial queue data and also any received data.
;
; Operation:        Enqueues events if char is received.
;                   Sends chars if serial_queue is not empty.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  char = received char
;
; Shared Variables: serial_queue - READ/WRITE
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
; Registers Used:   None.
;
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/25/2013
;
; Pseudocode
; ----------
;                   if received char:
;                       EnqueueEvent(received_char)
;                   if serial_queue is not empty:
;                       char = serial_queue.dequeue()
;                       send char
;                   
;


; SetSerial.{Baud, Parity, DataSize}
;
; Description:      Sets all the default serial parameters.
;
; Operation:        Sets the baud rate, parity, data size. Uses specified
;                   pre-processor defined EQU's.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: serial_baud_rate    (WRITE)
;                   serial_parity       (WRITE)
;                   serial_data_size    (WRITE)
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           Serial Controller.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/25/2013
;
; Pseudocode
; 
; set baud rate and serial_baud_rate from defined constant 
; set parity and serial_parity from defined constant 
; set data size and serial_data_size from defined constant 
;




DATA SEGMENT PUBLIC 'DATA'
    sendQueue       queueSTRUC  <>
    receiveQueue    queueSTRUC  <>
DATA ENDS
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
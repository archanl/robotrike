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

    
$INCLUDE(general.inc)
$INCLUDE(queue.inc)
$INCLUDE(serial.inc)
$INCLUDE(simpmac.inc)

; setup code and data groups
CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


; segment register assumptions
        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP



CODE    SEGMENT PUBLIC 'CODE'


    EXTRN   QueueInit:NEAR
    EXTRN   QueueEmpty:NEAR
    EXTRN   QueueFull:NEAR
    EXTRN   Dequeue:NEAR
    EXTRN   Enqueue:NEAR
    EXTRN   EnqueueEvent:NEAR


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
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI
    
    MOV     SI, OFFSET(sendQueue)   ; Let SI be the pointer to the queue
    MOV     AX, SERIAL_QUEUE_LENGTH ; Set size to that defined in inc
    MOV     BL, QUEUE_BYTE_ELEM     ; Set element size to byte
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
    %InstallVector(INT_VEC_SERIAL, SerialInterruptHandler)
    
    MOV     DX, SERIAL_IER          ;enable interrupts
    MOV     AL, SERIAL_EN_IRQ
    OUT     DX, AL

    ;MOV     DX, SERIAL_MCR                  ;set the modem control lines
    ;MOV     AL, SERIAL_RTS + SERIAL_DTR     ;RTS and DTR both on
    ;OUT     DX, AL

    ;JMP    InitErrorStatus         ;now initialize the error status

InitKickstartStatus:
    MOV KickstartNeeded, TRUE

InitErrorStatus:                        ;reset the error status
    MOV     ErrorBits, NO_ERROR
    ;JMP    EndInitSerialPort       ;all done initializing error status

    MOV     DX, SERIAL_ICR    ; Setup the interrupt control register
    MOV     AX, SERIAL_ICR_VAL
    OUT     DX, AL
    MOV DX, INTCtrlrEOI             ; Send serial EOI
    MOV AX, SerialEOI
    OUT DX, AL
        
EndInitSerialPort:                      ;done initializing the serial port -
    POP SI
    POP DX
    POP BX
    POP AX
    RET                             ;   return


InitSerialPort  ENDP





KickStartSerialTx   PROC    NEAR
                    PUBLIC  KickStartSerialTx
    
BeginKickStartSerialTx:
    PUSH DX
    PUSH AX

DoTxKickstart:
    MOV DX, SERIAL_IER          ;enable interrupts
    MOV AL, SERIAL_EN_IRQ_NOTX
    OUT DX, AL
    MOV AL, SERIAL_EN_IRQ
    OUT DX, AL

EndKickStartSerialTx:
    POP AX
    POP DX
    RET
    
KickStartSerialTx   ENDP


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
; SerialPutChar
;
; Description:      This function outputs the passed character to the serial
;                   port.  It does not return until it has output the
;                   character (actually until it is written to the 82050).
;
; Operation:        The function loops waiting for the serial output channel
;                   to be ready to transmit a character.  Once it is ready the
;                   character is written.
;
; Arguments:        (SP + 2) - character to output to the serial channel.
; Return Value:     None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           A character to the serial port.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, DX
; Stack Depth:      2 words
;
; Author:           Glen George
; Last Modified:    Nov. 19, 1997

SerialPutChar   PROC    NEAR
                PUBLIC  SerialPutChar

StartSerialPutChar:                     ;get ready to output a character
    PUSH SI
    
SerialPutCharCheckReady:
    Call SerialOutRdy
    JNZ PutSerialChar
    ;JZ SerialPutCharError

SerialPutCharError:
    STC                                 ; Set carry flag to indicate error
    JMP EndSerialPutChar                ; End function

PutSerialChar:                      ; Send the character now
    CLC                             ; Clear carry flag to indicate success
    %CRITICAL_START
    MOV SI, OFFSET(sendQueue)
    Call Enqueue                    ; Argument is in AL, Queue location is in SI
SerialPutCharKickCheck:
    CMP KickstartNeeded, FALSE
    JE EndPutSerialChar
    ;JNE SerialPutCharKickstart
SerialPutCharKickstart:
    CALL KickStartSerialTx
    MOV KickstartNeeded, FALSE
    ;JMP EndPutSerialChar
EndPutSerialChar:
    %CRITICAL_END
    ;JMP EndSerialPutChar
    
EndSerialPutChar:
    POP SI
    RET

SerialPutChar   ENDP





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

SerialInterruptHandler  PROC NEAR

    StartSerialInterruptHandler:
        PUSH AX
        PUSH DX
        PUSH SI
        
    SerialInterruptCheckType:
        MOV DX, SERIAL_IIR
        IN AL, DX
        
        CMP AL, SERIAL_IIR_ERR
        JE SerialInterruptError
        
        CMP AL, SERIAL_IIR_RXA
        JE SerialInterruptReceive
        
        CMP AL, SERIAL_IIR_TXA
        JE SerialInterruptTransmit
    
    SerialInterruptError:
        MOV  DX, SERIAL_LSR          ;read the line status register
        IN   AL, DX
        OR   ErrorBits, AL           ;keep error status updated
        MOV  AL, ErrorBits
        MOV  AH, SERIAL_ERROR_EVENT
        CALL EnqueueEvent
        JMP  EndSerialInterruptHandler
    
    SerialInterruptReceive:
        MOV  DX, SERIAL_RX_REG       ;read it from the receive register
        IN   AL, DX
        MOV  AH, SERIAL_RECEIVE_EVENT
        CALL EnqueueEvent
        JMP  EndSerialInterruptHandler

    SerialInterruptTransmit:
        MOV  SI, Offset(sendQueue)
        CALL QueueEmpty
        JZ EndSerialInterruptHandler
        CALL Dequeue
        MOV  DX, SERIAL_TX_REG       ;write it to the transmit register
        OUT  DX, AL
    SerialInterruptTxKickCheck:
        CALL QueueEmpty
        JNZ EndSerialInterruptHandler
        ;JZ SerialInterruptTxKickNeeded
    SerialInterruptTxKickNeeded:
        MOV KickstartNeeded, TRUE
        ;JMP  EndSerialInterruptHandler
        
    EndSerialInterruptHandler:
        MOV DX, INTCtrlrEOI             ; Send serial EOI
        MOV AX, SerialEOI
        OUT DX, AL
        
        POP SI
        POP DX
        POP AX
        IRET

SerialInterruptHandler  ENDP




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
;SerialGetChar   PROC    NEAR
;                PUBLIC  SerialGetChar
;
;
;StartSerialGetChar:                     ;get ready to read a character
;        PUSH    AX
;        PUSH    DX
;
;SerialGetCharWait:                      ;wait until have a character
;        CALL    SerialInRdy             ;check if there is a character
;        OR      AL, AL                  ;set flags based on return value
;        JZ      SerialGetCharWait       ;loop until there is a character
;        ;JNZ    GetSerialChar           ;otherwise have a character
;
;
;GetSerialChar:                          ;get the character now
;        MOV     DX, SERIAL_RX_REG       ;read it from the receive register
;        IN      AL, DX
;        MOV     AH, 0                   ;make sure AH is doesn't cause problems
;        ;JMP    CheckErrorStatus        ;also check the error status
;
;CheckErrorStatus:                       ;see if there is a pending error
;        TEST    ErrorBits, ERROR_BIT_MASK
;        JZ      EndSerialGetChar        ;if no error, we're done
;        ;JNZ    HaveSerialError         ;otherwise have an error
;
;HaveSerialError:                        ;have an error on the serial channel
;        MOV     AX, GETCHAR_ERROR       ;set the error return value
;        ;JMP    EndSerialGetChar        ;and all done now
;
;
;EndSerialGetChar:                       ;done - just return
;        POP DX
;        POP AX
;        RET
;
;
;SerialGetChar   ENDP

;SerialInRdy     PROC    NEAR
;                PUBLIC  SerialInRdy
;
;    PUSH SI
;    MOV SI, OFFSET(RxQueue)
;    CALL QueueEmpty                      ; ZF gets set if queue is full
;    POP SI
;
;SerialInRdy     ENDP


SerialOutRdy    PROC    NEAR
                PUBLIC  SerialOutRdy

    PUSH SI
    MOV SI, OFFSET(sendQueue)
    CALL QueueFull                      ; ZF gets set if queue is full
    POP SI
    RET

SerialOutRdy    ENDP







; SerialErrStatus
;
; Description:      This function returns the error status of the serial port
;                   and resets that status to no errors (zero).
;
; Operation:        The error status is read, masked to be the error bits
;                   only, and then reset to no errors.  The read and masked
;                   value is returned.
;
; Arguments:        None.
; Return Value:     AX - error status, TRUE (non-zero) if there was an error
;                   on the serial channel, FALSE (zero) otherwise.
;
; Local Variables:  None.
; Shared Variables: ErrorBits - read to compute the return value and then
;                               reset to NO_ERROR.
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
; Registers Used:   flags, AX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Feb. 6, 2003

SerialErrStatus PROC    NEAR
                PUBLIC  SerialErrStatus

StartSerialErrStatus:                   ;get the error status

    MOV     AL, ErrorBits           ;get the status into AL
    AND     AX, ERROR_BIT_MASK      ;mask error bits and extend into AX
    MOV     ErrorBits, NO_ERROR     ;and clear the error status
    ;JMP    EndSerialErrStatus      ;now all done

EndSerialErrStatus:                     ;done - just return with status in AX
    RET

SerialErrStatus ENDP




CODE    ENDS




;the data segment
DATA SEGMENT PUBLIC 'DATA'
    KickstartNeeded DB          ?
    ErrorBits       DB          ?               ;error status from the 82050
    sendQueue       queueSTRUC  <>
DATA ENDS


END

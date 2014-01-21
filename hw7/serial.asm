    NAME SERIAL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     SERIAL                                 ;
;                                 SERIAL Routine                             ;
;                                    EE/CS 51                                ;
;                                  Archan Luhar                              ;
;                                 TA:  Joe Greef                             ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Import necessary definitions and macros
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

; External References
    EXTRN   QueueInit:NEAR
    EXTRN   QueueEmpty:NEAR
    EXTRN   QueueFull:NEAR
    EXTRN   Dequeue:NEAR
    EXTRN   Enqueue:NEAR
    EXTRN   EnqueueEvent:NEAR


; InitSerialPort
;
; Description:      This procedure initializes the 82050 port.  It sets it to
;                   eight data bits, no parity, one stop bit, 9600 baud, and
;                   no interrupts.  DTR and RTS are both set active.
;
; Operation:        The initialization values are written to the serial and
;                   interrupt chips.
;                   The shared variables are initialized and the error status is
;                   cleared.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  SI - sendQueue offset
;                   AX, BL - QueueInit parameters
;                   DX - hw register addresses
;                   AL - values to OUT to hw registers
;
; Shared Variables: ErrorBits       (W)
;                   sendQueue       (W)
;                   KickstartNeeded (W)
;
; Global Variables: None.
;
; Input:            None.
; Output:           Control and interrupt registers
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags (call)
; Stack Depth:      4 words + call
;
; Author:           Glen George, Archan Luhar
; Last Modified:    Jan. 20, 2014

InitSerialPort  PROC    NEAR
                PUBLIC  InitSerialPort

StartInitSerialPort:                ; Save the registers temporarily used
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

SetSerialSharedVars:    
    MOV     SI, OFFSET(sendQueue)   ; Let SI be the pointer to the queue
    MOV     AX, SERIAL_QUEUE_LENGTH ; Set size to that defined in inc
    MOV     BL, QUEUE_BYTE_ELEM     ; Set element size to byte (characters)
    CALL    QueueInit               ; Initialize the queue metadata.
    
    MOV     KickstartNeeded, TRUE

    MOV     ErrorBits, NO_ERROR     ; Reset the error status

SetupSerialHardware:
    MOV     DX, SERIAL_LCR          ; Talk to the baud rate divisor registers
    MOV     AL, ENABLE_BRG_ACC      ; (LCR is now in baud rate set mode)
    OUT     DX, AL

    MOV     DX, SERIAL_BRG_DIV      ; Set the baud rate divisor
    MOV     AX, BAUD9600
    OUT     DX, AL                  ; Write a byte at a time. Low byte
    INC     DX
    MOV     AL, AH
    OUT     DX, AL                  ; High byte

    MOV     DX, SERIAL_LCR          ; Set all parameters in the line control reg
    MOV     AL, SERIAL_SETUP
    OUT     DX, AL                  ; (also changes access back to Rx/Tx)
    
    MOV     DX, SERIAL_IER          ; Serial Interrupt enable register
    MOV     AL, SERIAL_EN_IRQ       ; Enable interrupts
    OUT     DX, AL

SetupSerialInterrupts:
    ; Install serial interrupt handler into the vector table
    %InstallVector(INT_VEC_SERIAL, SerialInterruptHandler)

    MOV     DX, SERIAL_ICR          ; Setup the relevant interrupt control reg
    MOV     AX, SERIAL_ICR_VAL
    OUT     DX, AL

    MOV     DX, INTCtrlrEOI         ; Send serial EOI to reset the interrupts
    MOV     AX, SerialEOI
    OUT     DX, AL
        
EndInitSerialPort:                  ; Restore saved registers
    POP SI
    POP DX
    POP BX
    POP AX
    RET                             ; Return

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
; Local Variables:  SI - offset of sendQueue
;
; Shared Variables: sendQueue       (R/W)
;                   KickstartNeeded (R/W)
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
; Data Structures:  queues are used (sendQueue)
;
; Registers Used:   flags (carry flag is return value)
;
; Stack Depth:      1 word + calls
;
; Author:           Archan Luhar
; Last Modified:    11/25/2013

SerialPutChar   PROC    NEAR
                PUBLIC  SerialPutChar

StartSerialPutChar:                     ;get ready to output a character
    PUSH SI
    
SerialPutCharCheckReady:
    MOV SI, OFFSET(sendQueue)
    CALL QueueFull                      ; ZF gets set if queue is full
    JNZ PutSerialChar
    ;JZ SerialPutCharError

SerialPutCharError:
    STC                                 ; Set carry flag to indicate error
    JMP EndSerialPutChar                ; End function

PutSerialChar:                      ; Send the character now
    CLC                             ; Clear carry flag to indicate success
    %CRITICAL_START                 ; Macro pushes flag, saves carry flag 0
    Call Enqueue                    ; Enqueue AL in sendQueue
SerialPutCharKickCheck:
    CMP KickstartNeeded, FALSE
    JE EndPutSerialChar             ; If kick start not needed, skip kickstart
    ;JNE SerialPutCharKickstart
SerialPutCharKickstart:
    CALL KickStartSerialTx          ; Else, kickstart
    MOV KickstartNeeded, FALSE      ; And reset variable to FALSE
    ;JMP EndPutSerialChar
EndPutSerialChar:
    %CRITICAL_END                   ; Critical code ends here, restores flags
    ;JMP EndSerialPutChar
    
EndSerialPutChar:
    POP SI
    RET

SerialPutChar   ENDP




; SerialInterruptHandler
;
; Description:      Handles the serial error, received data, and transmit empty
;                   interrupts. EnqueueEvent's received data/errors and
;                   transmits data from the sendQueue.
;
; Operation:        Enqueues events if char is received or error.
;                   Sends chars if sendQueue is not empty. Sets KickStartNeeded
;                   if sendQueue is empty after dequeueing. Sends proper EOI.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  AH - EnqueueEvent event type
;                   AL - OUT values / queue values
;                   DX - OUT registers
;                   SI - sendQueue offset
;
; Shared Variables: sendQueue (R/W)
;                   ErrorBits (W)
;                   KickstartNeeded (W)
;
; Global Variables: None.
;
; Input:            Serial.
;
; Output:           Serial.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  queues are used (sendQueue)
;
; Registers Used:   flags
;
; Stack Depth:      3 words + calls
;
; Author:           Archan Luhar
; Last Modified:    1/20/2014

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
        
        POP SI                          ; Restore registers
        POP DX
        POP AX
        IRET                            ; IRET because this handles an interrupt

SerialInterruptHandler  ENDP



; KickStartSerialTx
;
; Description:      This procedure resets the THRE interrupt -- the transmit
;                   holding register empty interrupt. This is needed when
;                   it has been fired and subsequently the interrupt caught but
;                   not handled with a new character to transmit. Thus, the
;                   next character put into the transmit queue buffer will not
;                   be sent unless this interrupt is kickstarted. Must call this
;                   when KickstartNeeded shared variable is TRUE.
;
; Operation:        Outputs to the serial interrupt enable register
;                   a value that turns off the THRE interrupt. Then it outputs
;                   again another value that turns it on.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  AX, DX - OUT value, OUT register
;
; Shared Variables: None.
;
; Global Variables: None.
;
; Input:            None.
; Output:           Serial IER
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags
; Stack Depth:      2 words
;
; Author:           Archan Luhar
; Last Modified:    Jan. 20, 2014

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



; Serial shared data in the data segment
DATA SEGMENT PUBLIC 'DATA'
    KickstartNeeded DB          ?               ; Kickstart needed boolean
    ErrorBits       DB          ?               ; Error status from the 82050
    sendQueue       queueSTRUC  <>              ; queue buffers Tx characters
DATA ENDS


END

        NAME  POLLSER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    POLLSER                                 ;
;                            Polled Serial I/O Demo                          ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains routines for doing polled serial I/O using an 82050.  The
; functions included are:
;    InitSerialPort  - initialize the serial channel
;    SerialInRdy     - determine if the serial channel has input data ready
;    SerialOutRdy    - determine if the serial channel is ready to transmit
;    SerialGetChar   - get a character from the serial channel
;    SerialPutChar   - output a character to the serial channel
;    SerialErrStatus - return and clear the serial error status
;
; Revision History:
;    11/10/93  Glen George              initial revision
;    11/14/94  Glen George              SerialGetChar and SerialPutChar now
;                                          use SerialInRdy and SerialOutRdy
;                                       updated comments
;                                       added Revision History section
;    11/11/96  Glen George              updated comments
;    11/19/97  Glen George              added SerialErrStatus function
;                                       changed argument passing and return
;                                          values to match C functions
;                                       changed code segment name to match C
;                                       added Shared Variables sections to
;                                          function headers
;    10/20/98  Glen George              changed InitSerialPort to always do
;                                          byte I/O
;                                       fixed bug in SerialGetChar (AH could
;                                          have been uninitialized on return)
;                                       updated comments
;    12/26/99  Glen George              changed to using groups for the
;                                          segment registers to be compatible
;                                          with C
;                                       updated comments
;     1/30/02  Glen George              added proper assume for ES
;     2/06/03  Glen George              now using the constants NO_ERROR and
;                                          GETCHAR_ERROR
;                                       updated comments



; local include files
$INCLUDE(SERIAL.INC)




; setup code and data groups
CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


; segment register assumptions
        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP



CODE    SEGMENT PUBLIC 'CODE'




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

        MOV     DX, SERIAL_IER          ;turn off interrupts
        MOV     AL, SERIAL_DIS_IRQ
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




; SerialInRdy
;
; Description:      This function returns with AL non-zero if there is a
;                   character ready to be read from the serial port, and with
;                   AL equal to zero otherwise.
;
; Operation:        The Line Status Register is read, the error information
;                   is saved and whether or not a character is available is
;                   returned.  The return value is created by ANDing with the
;                   receive ready bit.
;
; Arguments:        None.
; Return Value:     AL - TRUE (non-zero) if there is a character available on
;                   the serial port, FALSE (zero) otherwise.
;
; Local Variables:  None.
; Shared Variables: ErrorBits - the newly read error bits are OR'ed into this
;                               value.
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
; Registers Used:   flags, AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 10, 1993

SerialInRdy     PROC    NEAR
                PUBLIC  SerialInRdy


        MOV     DX, SERIAL_LSR          ;read the line status register
        IN      AL, DX
        OR      ErrorBits, AL           ;keep error status updated
        AND     AL, RX_DATA_RDY         ;set AL appropriately


        RET                             ;all done - return


SerialInRdy     ENDP




; SerialOutRdy
;
; Description:      This function returns with AL non-zero if the serial
;                   channel is ready to transmit another character, otherwise
;                   AL is set to zero.
;
; Operation:        The Line Status Register is read, the error information
;                   is saved and whether or not the system is ready for
;                   another character to transmit is returned.  The return
;                   value is created by ANDing with the transmit ready bit.
;
; Arguments:        None.
; Return Value:     AL - TRUE (non-zero) if the serial port is ready to
;                   transmit a character, FALSE (zero) otherwise.
;
; Local Variables:  None.
; Shared Variables: ErrorBits - the newly read error bits are OR'ed into this
;                               value.
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
; Registers Used:   flags, AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 10, 1993

SerialOutRdy    PROC    NEAR
                PUBLIC  SerialOutRdy


        MOV     DX, SERIAL_LSR          ;read the line status register
        IN      AL, DX
        OR      ErrorBits, AL           ;keep error status updated
        AND     AL, TX_DATA_RDY         ;set AL appropriately


        RET                             ;all done - return


SerialOutRdy    ENDP




; SerialGetChar
;
; Description:      This function gets a character from the serial port.  It
;                   does not return until it has the character.  If there is
;                   an error on the serial port, GETCHAR_ERROR is returned.
;
; Operation:        The function loops waiting for there to be a character
;                   on the serial input channel.  Once there is a character
;                   the character is read.  The error flags are also checked
;                   and if there are errors the return value is set to
;                   GETCHAR_ERROR.
;
; Arguments:        None.
; Return Value:     AX - character read from the serial channel, or
;                   GETCHAR_ERROR if there is an error.
;
; Local Variables:  None.
; Shared Variables: ErrorBits - read for error return.
; Global Variables: None.
;
; Input:            A character from the serial port.
; Output:           None.
;
; Error Handling:   If there is an error getting the character (as reported by
;                   the 82050), GETCHAR_ERROR is returned.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, DX
; Stack Depth:      1 word
;
; Author:           Glen George
; Last Modified:    Feb. 6, 2003

SerialGetChar   PROC    NEAR
                PUBLIC  SerialGetChar


StartSerialGetChar:                     ;get ready to read a character

SerialGetCharWait:                      ;wait until have a character
        CALL    SerialInRdy             ;check if there is a character
        OR      AL, AL                  ;set flags based on return value
        JZ      SerialGetCharWait       ;loop until there is a character
        ;JNZ    GetSerialChar           ;otherwise have a character


GetSerialChar:                          ;get the character now
        MOV     DX, SERIAL_RX_REG       ;read it from the receive register
        IN      AL, DX
        MOV     AH, 0                   ;make sure AH is doesn't cause problems
        ;JMP    CheckErrorStatus        ;also check the error status

CheckErrorStatus:                       ;see if there is a pending error
        TEST    ErrorBits, ERROR_BIT_MASK
        JNZ     EndSerialGetChar        ;if no error, we're done
        ;JZ     HaveSerialError         ;otherwise have an error

HaveSerialError:                        ;have an error on the serial channel
        MOV     AX, GETCHAR_ERROR       ;set the error return value
        ;JMP    EndSerialGetChar        ;and all done now


EndSerialGetChar:                       ;done - just return
        RET


SerialGetChar   ENDP




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


Argument        EQU     [BP + 4]        ;where the argument is


StartSerialPutChar:                     ;get ready to output a character

        PUSH    BP                      ;setup the stack frame
        MOV     BP, SP

SerialPutCharWait:                      ;wait until ready to transmit the character
        CALL    SerialOutRdy            ;check if ready to output the character
        OR      AL, AL                  ;set flags based on return value
        JZ      SerialPutCharWait       ;loop until ready to transmit
        ;JNZ    PutSerialChar           ;otherwise transmit the character


PutSerialChar:                          ;send the character now
        MOV     AL, Argument            ;get character to output
        MOV     DX, SERIAL_TX_REG       ;write it to the transmit register
        OUT     DX, AL
        ;JMP    EndSerialPutChar        ;now all done


EndSerialPutChar:                       ;done - restore BP and return
        POP     BP
        RET


SerialPutChar   ENDP




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

DATA    SEGMENT PUBLIC  'DATA'


ErrorBits       DB      ?               ;error status from the 82050


DATA    ENDS



        END

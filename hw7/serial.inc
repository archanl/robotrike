;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  SERIAL.INC                                ;
;                            Polled Serial I/O Demo                          ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the serial I/O routines (in the file
; POLLSER.ASM).  These definitions just cover the 16C450 Aynchronous
; Communications Controller chip on the target board.  The definitions assume
; the serial chip is selected with PCS3 (it is based at address 180H),
;
; Revision History:
;    11/10/93  Glen George              initial revision
;    11/14/94  Glen George              updated comments
;    11/13/95  Glen George              changed ENABLE_BRG_ACC constant to be
;                                          in binary
;                                       corrected definition of BAUD9600 (had
;                                          forgotten divide-by-two of 80188
;                                          system clock)
;    11/11/96  Glen George              updated comments
;    11/17/97  Glen George              updated comments
;    12/26/99  Glen George              updated comments
;     2/06/03  Glen George              added constants for NO_ERROR and
;                                          GETCHAR_ERROR
;                                       updated comments
;     3/03/03  Glen George              changed constants to match 16C450 on
;                                          student boards instead of 82050 on
;                                          old target boards (mainly baudrate)
;
;     1/17/14  Archan Luhar             added interrupt vector table position
;                                       for serial chip

; Interrupt definitions
INTCtrlrEOI     EQU     0FF22H          ; Interrupt controller EOI register
INT_2_VEC       EQU     14
INT_VEC_SERIAL  EQU     INT_2_VEC
INT_2_EOI       EQU     000EH
SerialEOI       EQU     INT_2_EOI

SERIAL_ICR      EQU     0FF3CH          ; int 2 (serial) int contrl register
SERIAL_ICR_VAL  EQU     00001H          ;0000 0000 000- ----  reserved
                                        ;---- ---- ---0 ----  edge triggering
                                        ;---- ---- ---- 0---  enable interrupt
                                        ;---- ---- ---- -111  int 2 priority


SERIAL_QUEUE_LENGTH EQU 128

; Events
SERIAL_ERROR_EVENT   EQU 1
SERIAL_RECEIVE_EVENT EQU 2


; Serial (16C450) Defintions


; Register I/O Addresses

SERIAL_BRG_DIV  EQU     100H            ;baud rate generator divisor (R/W)
SERIAL_RX_REG   EQU     100H            ;receive data register (R)
SERIAL_TX_REG   EQU     100H            ;transmit data register (W)
SERIAL_IER      EQU     101H            ;interrupt enable register (R/W)
SERIAL_IIR      EQU     102H            ;interrupt identification register (R)
SERIAL_LCR      EQU     103H            ;line control register (R/W)
SERIAL_MCR      EQU     104H            ;modem control register (R/W)
SERIAL_LSR      EQU     105H            ;line status register (R/W)


; Register Bit Values

; Line Control Register
ENABLE_BRG_ACC  EQU     10000000B       ;enable access to the baud rate divisor
SERIAL_SETUP    EQU     00000011B       ;0-------  access Rx/Tx data registers
                                        ;-0------  no break output
                                        ;--000---  no parity
                                        ;-----0--  one stop bit
                                        ;------11  8 data bits

; Interrupt Enable Register
SERIAL_EN_IRQ   EQU     00000111B       ;0000---- Unused
                                        ;----0--- Disable modem status
                                        ;-----1-- Enable receiver line status
                                        ;------1- Enable THRE interrupt
                                        ;-------1 Enable received data available interrupt
SERIAL_EN_IRQ_NOTX  EQU 00000101B       ;0000---- Unused
                                        ;----0--- Disable modem status
                                        ;-----1-- Enable receiver line status
                                        ;------0- Disable THRE interrupt
                                        ;-------1 Enable received data available interrupt
SERIAL_DIS_IRQ  EQU     00000000B       ;disable all interrupts


; Modem Control Register
SERIAL_RTS      EQU     00000010B       ;RTS output bit
SERIAL_DTR      EQU     00000001B       ;DTR output bit

; Baud Rate Generator
BAUD9600        EQU     60              ;divisor for 9600 baud
                                        ;  18.432e6 / 4 / 9600 / 16 ==> 30

; Line Status Register
RX_DATA_RDY     EQU     00000001B       ;have data ready in receiver
TX_DATA_RDY     EQU     00100000B       ;ready to transmit data
ERROR_BIT_MASK  EQU     00011110B       ;error bits

; Interrupt Identification Register
SERIAL_IIR_ERR  EQU     00000110B
SERIAL_IIR_RXA  EQU     00000100B
SERIAL_IIR_TXA  EQU     00000010B


; General Constants
NO_ERROR        EQU     0               ;no errors in the serial system
GETCHAR_ERROR   EQU     -1              ;SerialGetChar error return value

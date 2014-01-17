;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   INIT.INC                                 ;
;                              Initialization Code                           ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the initialization code (INIT.ASM).
;
; Revision History:
;    11/17/97  Glen George      initial revision (from 10/28/97 version of
;                                  EHDEMO.INC)
;    12/26/99  Glen George      updated comments
;     2/06/03  Glen George      changed value of MPCSval to a legal value
;                               added some interrupt controller constants
;                               changed RESERVED_VECS to be for the debugger,
;                                  not the ICE



; Chip Select Unit Definitions

; Addresses
PACSreg         EQU     0FFA4H          ;address of PACS register
MPCSreg         EQU     0FFA8H          ;address of MPCS register

; Control Register Values
PACSval         EQU     00003H          ;PCS base at 0, 3 wait states
MPCSval         EQU     00183H          ;PCS in I/O space, use PCS5/6,
                                        ;   3 wait states, MCSn is 8K


; Interrupt Controller Definitions (needed by IllegalEventHandler)

; Addresses
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

; Register Values
NonSpecEOI      EQU     08000H          ;Non-specific EOI command


; General Definitions

RESERVED_VECS   EQU     4               ;vectors reserved for debugger

        NAME  INIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     INIT                                   ;
;                           Initialization Functions                         ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the initialization functions for the example programs.
; The functions included are:
;    InitCS             - initialize the chip select logic
;    ClrIRQVectors      - clear the interrupt vector table
;    IllegalEventHander - illegal event handler for ClrIRQVectors
;
; Revision History:
;    11/19/97  Glen George      initial revision (from 10/29/97 version of
;                                  EHDEMO.ASM)
;    10/20/98  Glen George      updated comments
;    12/26/99  Glen George      changed segment names and switched to using
;                                   groups for the segment registers to be
;                                   compatible with C
;                               updated comments
;     1/26/00  Glen George      fixed typo in segment names
;     1/30/02  Glen George      added proper assumes for DS and ES
;                               switched to using ES to initialize vectors
;                               send a non-specific EOI in the illegal event
;                                  handler
;     2/06/03  Glen George      updated comments



; local include files
$INCLUDE(INIT.INC)




; setup code group
CGROUP  GROUP   CODE


; segment register assumptions
        ASSUME  CS:CGROUP, DS:NOTHING, ES:NOTHING



CODE    SEGMENT PUBLIC 'CODE'




; InitCS
;
; Description:      Initialize the Peripheral Chip Selects on the 80188.
;
; Operation:        Write initialization values to MPCS and PACS.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None.
; Shared Variables: None.
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
; Registers Used:   AX, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Oct. 29, 1997

InitCS  PROC    NEAR
        PUBLIC  InitCS


        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)


        RET                     ;done so return


InitCS  ENDP




; ClrIRQVectors
;
; Description:      This function installs the IllegalEventHandler for all
;                   interrupt vectors in the interrupt vector table.  Note
;                   that all 256 vectors are initialized so the code must be
;                   located above 400H.  The initialization skips the first
;                   RESERVED_VECS vectors.
;
; Operation:        The code loops, starting at vector RESERVED_VECS and
;                   ending at vector 256.  For each vector the address of
;                   IllegalEventHandler is written.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  CX - vector counter.
;                   SI - pointer to the vector table.
; Shared Variables: None.
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
; Registers Used:   flags, AX, CX, SI, ES
; Stack Depth:      1 word
;
; Author:           Glen George
; Last Modified:    Jan. 30, 2002

ClrIRQVectors   PROC    NEAR
                PUBLIC  ClrIRQVectors


InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear DS (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 4 * RESERVED_VECS   ;initialize SI to skip RESERVED_VECS (4 bytes each)

        MOV     CX, 256 - RESERVED_VECS ;up to 256 vectors to initialize


ClrVectorLoop:                  ;loop clearing each vector
                                ;store the vector
        MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
        MOV     ES: WORD PTR [SI + 2], SEG(IllegalEventHandler)

        ADD     SI, 4           ;update pointer to next vector

        LOOP    ClrVectorLoop   ;loop until have cleared all vectors
        ;JMP    EndClrIRQVectors;and all done


EndClrIRQVectors:               ;all done, return
        RET


ClrIRQVectors   ENDP




; IllegalEventHandler
;
; Description:      This procedure is the event handler for illegal
;                   (uninitialized) interrupts.
;
; Operation:        The function does nothing - it just sends a non-specific
;                   EOI (doesn't know which interrupt occurred) and returns.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None.
; Shared Variables: None.
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
; Registers Used:   None
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Jan. 30, 2002

IllegalEventHandler     PROC    NEAR

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-sepecific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP



CODE    ENDS



        END

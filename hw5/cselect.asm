    NAME    CSELECT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    CSELECT                                 ;
;                           Chip Select Initialization                       ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


$INCLUDE(cselect.inc)


CGROUP  GROUP   CODE
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP

        
; InitDisplayCS/InitCS
;
; Description:       Initialize the Peripheral Chip Selects on the 80188.
;
; Operation:         Writes the initial values to the PACS and MPCS registers.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Used:    None.
; Stack Depth:       2 words.
;
; Author:            Glen George, Archan Luhar
; Last Modified:     Nov. 18, 2013

InitCS          PROC    NEAR
                PUBLIC  InitCS

    PUSH AX
    PUSH DX

    MOV     DX, PACSreg     ;setup to write to PACS register
    MOV     AX, PACSval
    OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

    MOV     DX, MPCSreg     ;setup to write to MPCS register
    MOV     AX, MPCSval
    OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)

    POP DX
    POP AX
    RET

InitCS          ENDP



CODE ENDS
    END
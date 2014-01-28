    NAME DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    DISPLAY                                 ;
;                               Display Routines                             ;
;                                   EE/CS 51                                 ;
;                                 Archan Luhar                               ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions to handle a periodic timer event to update
; the display and functions to display an ASCII string, hexadecimal number,
; or decimal number.
;
; The included public functions are:
;   - DisplayTimerEventHandler
;           Updates the display, iterating over the display buffer
;   - Display
;           Given an ascii string argument, writes to pattern to display buffer
;   - DisplayNum
;           Given a number , writes its decimal representation to display buffer
;   - DisplayHex
;           Given a number, writes its hexadecimal representation to buffer
;
; Revision History:
;       11/12/2013      Archan Luhar    Finished debugging.
;       11/18/2013      Archan Luhar    Finished documentation.
;       11/20/2013      Archan Luhar    Updated how data is initialized.

; local includes
$INCLUDE(general.inc)
$INCLUDE(display.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP

; External references
    EXTRN   Dec2String:NEAR
    EXTRN   Hex2String:NEAR
    EXTRN   ASCIISegTable:NEAR

; InitDisplay
;
; Description:      This function initializes the shared variables for the
;                   display routines. MUST call this before calling any display
;                   routine.
;
; Operation:        Zeroes out display_buffer array. Zeroes out display_ascii
;                   array. Initializes display_index to beginning: 0.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  BX = array offset
;                   CX = array looping end condition
;
; Shared Variables: display_buffer
;                   display_index
;                   display_ascii
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
; Stack Depth:      2 words.
;
; Author:           Archan Luhar
; Last Modified:    11/20/2013

InitDisplay    PROC    NEAR
               PUBLIC  InitDisplay

    PUSH BX
    PUSH CX

    MOV BX, OFFSET(display_buffer)
    MOV CX, OFFSET(display_buffer) + NUM_DIGITS * BYTES_IN_WORD
    InitDisplayBuffer:
        MOV WORD PTR [BX], BLANK_DISPLAY
        INC BX
        CMP BX, CX
        JNE InitDisplayBuffer
    
    MOV display_index, 0
    
    MOV BX, OFFSET(display_ascii)
    MOV CX, OFFSET(display_ascii) + NUM_DIGITS
    InitDisplayASCII:
        MOV BYTE PTR [BX], ASCII_NULL
        INC BX
        CMP BX, CX
        JNE InitDisplayASCII
    
    POP CX
    POP BX
    RET

InitDisplay ENDP



; Display
;
; Description:      This function is used to display a <null> terminated string
;                   to the LED display on the target board. The function does
;                   not actually output to the display. It just writes to a
;                   buffer which is read by DisplayTimerEventHandler.
;
; Operation:        This function goes through each character of the string
;                   located at ES:SI and writing to the buffer the segment
;                   pattern corresponding to the character. A table stored in
;                   CS is used. The table's nth word corresponds to the pattern
;                   for the nth ascii character.
;
; Arguments:        SI - the offset from ES which is the location of the the
;                   string.
;
; Return Value:     None.
;
; Local Variables:  DX = pointer to segment pattern table
;                   DI = pointer to display buffer
;                   CX = end condition for DI
;                   BL = character loaded from argument
;                   BX = offset into pattern table
;
; Shared Variables: display_buffer - a portion of the memory dedicated to
;                                    storing the exact representation of the
;                                    currently displayed characters. The display
;                                    timer event handler will display what is in
;                                    buffer location.
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  Array.
;
; Registers Used:   None.
;
; Stack Depth:      6 words.
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013

Display     PROC    NEAR
            PUBLIC  Display

    PUSH AX                             ; Save Registers
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; DX = offset into CS to segment pattern table
    MOV DX, OFFSET(ASCIISegTable)

    ; DI = offset into DS to buffer of an LED display
    MOV DI, OFFSET(display_buffer)

    ; CX = loop end condition = past buffers of all digits, each buffer 2 bytes
    MOV CX, OFFSET(display_buffer) + (NUM_DIGITS * BYTES_IN_WORD)

    SetBufferLoop:
        MOV BL, ES:BYTE PTR [SI]        ; BL = argument[0]
        CMP BL, ASCII_NULL              ; If character is ASCII NULL,
        JE SkipStringIndexIncrement     ; don't increase string index

    IncrementStringIndex:
        INC SI                          ; If character is not null, get string
                                        ; index ready for loop back
    SkipStringIndexIncrement:
    WriteChar:
        XOR BH, BH                      ; BH = 0
        SHL BX, 1                       ; BX = 2 * ascii value of character
                                        ; BX = pattern offset
                                        ; (each segment pattern is 1 word
                                        ;  whereas each character is 1 byte)

        ADD BX, DX                      ; BX = pattern offset + table offset
        MOV AX, CS:[BX]                 ; AX = segment pattern

        MOV [DI], AX                    ; DS:[display_buffer pointer] = pattern

    EndBufferLoop:
        ADD DI, BYTES_IN_WORD           ; Increment display buffer pointer by 1
                                        ; word because each pattern is a word.
        CMP DI, CX                      ; If buffer pointer is not past all the
        JNE SetBufferLoop               ; buffers, then loop. Else, end Display.

    EndDisplay:
        POP DI                          ; Restore registers and return
        POP SI
        POP DX
        POP CX
        POP BX
        POP AX
        RET

Display ENDP



; DisplayNum
;
; Description:      This function is used to display a decimal number to
;                   the LED display.
;
; Operation:        This function simply calls Dec2String to get the ASCII
;                   representation of the number and then calls Display
;                   to display the ascii representation of the number.
;                   Dec2String writes to DS:SI (display_ascii) which is passed
;                   to Display as ES:SI.
;
; Arguments:        AX - number to display.
;
; Return Value:     None.
;
; Local Variables:  ES = DS
;                   SI = offset into DS of display_ascii
;
; Shared Variables: display_ascii
; Global Variables: None.
;
; Input:            None.
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
; Stack Depth:      3 words: 2 registers and a call to a NEAR function.
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013

DisplayNum  PROC    NEAR
            PUBLIC  DisplayNum

    PUSH ES                             ; Save registers
    PUSH BX
    
    MOV BX, DS                          ; Since DS = SEG(display_offset)
    MOV ES, BX                          ; Setup to write ASCII to DS:SI
    MOV SI, OFFSET(display_ascii)       ; And to read ASCII from ES:SI

    CALL Dec2String                     ; Argument is AX, writes to DS:SI
    CALL Display                        ; Argument string read from ES:SI.
    
    POP BX                              ; Restore registers
    POP ES
    
    RET

DisplayNum ENDP


; DisplayHex
;
; Description:      This function is used to display a hexadecimal number to
;                   the LED display.
;
; Operation:        This function simply calls Hex2String to get the ASCII
;                   representation of the number and then call Display
;                   to display the ascii representation of the number.
;                   Dec2String writes to DS:SI (display_ascii) which is passed
;                   to Display as ES:SI.
;
; Arguments:        AX - number to display.
;
; Return Value:     None.
;
; Local Variables:  ES = DS
;                   SI = offset into DS of display_ascii
;
; Shared Variables: display_ascii
; Global Variables: None.
;
; Input:            None.
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
; Stack Depth:      3 words: 2 registers and a call to a NEAR function.
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013

DisplayHex  PROC    NEAR
            PUBLIC  DisplayHex

    PUSH ES                             ; Save registers
    PUSH BX
    
    MOV BX, DS                          ; Since DS = SEG(display_offset)
    MOV ES, BX                          ; Setup to write ASCII to DS:SI
    MOV SI, OFFSET(display_ascii)       ; And to read ASCII from ES:SI

    CALL Hex2String                     ; Argument is AX, writes to DS:SI
    CALL Display                        ; Argument string read from ES:SI.
    
    POP BX                              ; Restore registers
    POP ES
    
    RET

DisplayHex ENDP



; DisplayTimerEventHandler
;
; Description:      This function should be called on timer interrupt to output
;                   the display buffer onto the physical display.
;
; Operation:        At each call, this function reads the pattern for one of
;                   the displays indexed by the shared variable display_index
;                   and outputs the pattern to the corresponding display.
;                   It then increments the display_index and wraps it around
;                   to 0 so that the index cycles from 0 to NUM_DIGITS - 1.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: display_buffer
;                   display_index
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           Display.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      4 words: 4 registers pushed.
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013

DisplayTimerEventHandler    PROC    NEAR
                            PUBLIC  DisplayTimerEventHandler
    DisplayTimerEventHandlerInit:
        PUSH AX                             ; Save registers
        PUSH BX
        PUSH DX
        PUSH SI

        MOV BX, OFFSET(display_buffer)      ; Get display buffer address
        MOV SI, display_index               ; SI = display index

        SHL SI, 1                           ; SI = buffer offset = SI * 2
                                            ; (BYTES_IN_WORD = 
                                            ;  2 bytes per buffer word)

        MOV AX, [BX][SI]                    ; AX = character pattern
        XCHG AH, AL                         ; AL = 14 segment modifier pattern
                                            ; AH = display pattern

        SHR SI, 1                           ; SI = display index

    DisplayUpdate:
        MOV DX, LEDDisplay14                ; Set the 14 segment modifier
        OUT DX, AL

                                            ; AX = pattern . modifier
        SHR AX, BYTE_BITS                   ; AX =       0 . pattern
                                            ;                AL = pattern
        
        MOV DX, LEDDisplay                  ; Set the current LED display
        ADD DX, SI                          ; Make sure to offset by the index
        OUT DX, AL


    DisplayIndexUpdate:
        INC SI                              ; Increment the display index
        CMP SI, NUM_DIGITS                  ; If not reached max,
        JB  SkipDisplayIndexWrap            ; don't wrap around.

    DisplayIndexWrap:
        MOV SI, 0                           ; Else, wrap the digit index back to
                                            ; 0.

    SkipDisplayIndexWrap:
    EndDisplayTimerEventHandler:
        MOV display_index, SI               ; Update the shared variable
                                            ; display_index =
                                            ;   display_index + 1 mod NUM_DIGITS

        POP SI                              ; Restore registers
        POP DX
        POP BX
        POP AX
        RET

DisplayTimerEventHandler ENDP


CODE ENDS



DATA SEGMENT PUBLIC 'DATA'

    ; Stores the representation of the current display
    display_buffer DW   NUM_DIGITS   DUP (?)
    
    ; The display timer handler keeps track of which display to OUTput to next
    display_index  DW   ?
    
    ; A space allocated to read/write temporary ascii strings for the display
    display_ascii  DB   NUM_DIGITS   DUP (?)

DATA ENDS



    END
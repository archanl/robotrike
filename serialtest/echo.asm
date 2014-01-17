        NAME  ECHO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     ECHO                                   ;
;                              Echo Program Demo                             ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program is a demonstration program to show polled
;                   serial I/O (actually this program does not assume polled
;                   serial I/O).  It echos any characters received on the
;                   serial port back to the serial port, converting lowercase
;                   characters to uppercase and leaving all other characters
;                   unchanged.  Note: the program is an infinite loop, there
;                   no way to exit it.
;
; Input:            Characters from the serial channel.
; Output:           The input characters are output to the serial channel with
;                   lowercase characters converted to uppercase.
;
; User Interface:   None, the input is echoed.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Limitations:      Assumes the ASCII character set.
;
; Revision History:
;    11/10/93  Glen George              initial revision
;    11/14/94  Glen George              added chip select initialization
;                                       added error checking on input
;                                       added Revision History section
;    11/13/95  Glen George              updated comments
;    11/11/96  Glen George              updated comments
;    11/19/97  Glen George              changed name of stack and code
;                                          segments to be compatible with C
;                                       changed the argument passing to
;                                          SerialPutChar to be compatible with
;                                          C code
;                                       added call to ClrIRQVectors in
;                                          initialization
;    12/26/99  Glen George              changed to using groups for the
;                                          segment registers to be compatible
;                                          with C
;                                       updated comments
;     1/30/02  Glen George              added proper assume for ES



; local include files
;   none




; setup code and data groups
CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


; segment register assumptions
        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP



CODE    SEGMENT PUBLIC 'CODE'



; function declarations
        EXTRN   InitCS:NEAR		;initialize the PCS lines
        EXTRN   ClrIRQVectors:NEAR      ;setup the IRQ vector table
        EXTRN   InitSerialPort:NEAR	;initialize the serial port
        EXTRN   SerialGetChar:NEAR	;get a character from the serial port
        EXTRN   SerialPutChar:NEAR	;output a character to the serial port




StartEcho:      

        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX


        CALL    InitCS                  ;initialize the chip selects
	CALL    ClrIRQVectors		;clear out the interrupt vector table

        CALL    InitSerialPort          ;initialize the serial port


CharacterLoop:                          ;now loop, getting and converting characters
        CALL    SerialGetChar           ;get a character, checking for errors
	TEST    AX, 8000H		;check for negative (error)
        JNZ     CharacterLoop           ;if there was an error, ignore the character
        ;JZ     ProcessCharacter        ;otherwise have a character, process it

ProcessCharacter:                       ;convert lowercase to uppercase
        CMP     AL, 'a'                 ;check if lowercase (need to convert)
        JL      OutputChar              ;< 'a' -- just output it
        CMP     AL, 'z'
        JG      OutputChar              ;> 'z' -- just output it
        ;JLE    ConvertChar             ;else need to convert the character

ConvertChar:                            ;convert from lowercase to uppercase -
        SUB     AL, 'a' - 'A'           ;   assumes ASCII
        ;JMP    OutputChar              ;converted the character, now output it

OutputChar:                             ;output character to the serial port
	PUSH	AX			;put on stack for output routine
        CALL    SerialPutChar           ;output the character
	POP     AX                      ;clear the argument off the stack

        JMP     CharacterLoop           ;now loop forever


EndEcho:                                ;end of echoing
        HLT                             ;never executed




CODE    ENDS




;the data segment

DATA    SEGMENT PUBLIC  'DATA'


                ;nothing in the data segment but need it for initializing DS


DATA    ENDS




;the stack

STACK           SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')	; 240 words for stack

TopOfStack      LABEL   WORD

STACK           ENDS



        END     StartEcho

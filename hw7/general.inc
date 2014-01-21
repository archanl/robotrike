; General Definitions
ASCII_NULL      EQU     0
BYTES_IN_WORD   EQU     2
BYTE_BITS       EQU     8               ; Number of bits in a byte
TRUE            EQU     1
FALSE           EQU     0

%*DEFINE(InstallVector(vector, event_handler))   (
    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX
    
    MOV     ES: WORD PTR (4 * %vector), OFFSET(%event_handler)
    MOV     ES: WORD PTR (4 * %vector + 2), SEG(%event_handler)
    
    POP ES
    POP AX
)
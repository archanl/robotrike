; General Definitions
ASCII_NULL      EQU     0
BYTES_IN_WORD   EQU     2
BYTE_BITS       EQU     8               ; Number of bits in a byte

%*DEFINE(InstallVector(vector, event_handler))   (
    MOV     ES: WORD PTR (4 * %vector), OFFSET(%event_handler)
    MOV     ES: WORD PTR (4 * %vector + 2), SEG(%event_handler)
)
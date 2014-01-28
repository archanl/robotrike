; TRIKE MOVEMENT CONSTANTS
; ------------------------
MINIMUM_ACTIVE_PULSE_WIDTH  EQU 1       ; Pulse widths range from 0 to 255
INACTIVE_MOTOR_PULSE_WIDTH  EQU 0       ; No pulses = 0 pulse width
STATIONARY_SPEED            EQU 0       ; Default movement state
DEFAULT_ANGLE               EQU 0       ; Default movement orientation state
NO_CHANGE_ANGLE             EQU -32768  ; Don't change if angle parameter is =
NO_CHANGE_SPEED             EQU 65535  ; Don't change if speed parameter is =
MAX_SPEED                   EQU 65534


; PARALLEL HARDWARE CONFIGURATION, OUTPUT SELECTORS, AND BEHAVIOR BITS:
; ---------------------------------------------------------------------

; Parallel Hardware configuration
PARALLEL_CTRL_REG           EQU 0183H

                               ;1------- Mode Set Flag Active
                               ;-00----- Group A Mode 0 Basic Input Output
                               ;---1---- Port A Input (Doesn't matter)
                               ;----0--- Port C Upper Output (Doesn't matter)
                               ;-----0-- Group B Mode 0 Basic Input Output
                               ;------0- Port B Output (IMPORTANT)
                               ;-------0 Port C Lower Output (Doesn't matter)
PARALLEL_CTRL_VAL           EQU 10010000B

PARALLEL_PORTB_REG          EQU 0181H


; Parallel Output Configuration
DEFAULT_PARALLEL_PORTB      EQU 00000000B   ; No Parallel output in port B

; Port B Bit Clear Masks 
MOTORS_CLR_DIR_MASK         EQU 11101010B   ; Clears motor direction bits
PARALLEL_CLR_POW_MASK       EQU 01010101B   ; Clears motor and laser power bits


; Motor Direction Bits in Port B
M1_DIRECITON_BIT            EQU 0
M2_DIRECITON_BIT            EQU 2
M3_DIRECITON_BIT            EQU 4

; Motor Power Bits in Port B
M1_POWER_BIT                EQU 1
M2_POWER_BIT                EQU 3
M3_POWER_BIT                EQU 5


; Laser Power Bit in Port B
LASER_POWER_BIT             EQU 7

; Laser Behavior
LASER_OFF                   EQU 0



; SPEED AND ANGLE CALCULATION CONSTANTS
; -------------------------------------
; 360 * normalizer = 0FFFFH
ANGLE_NORMALIZER            EQU 182


; Force vectors for each motor
INIT_F1_X                   EQU 07FFFH
INIT_F1_Y                   EQU 00000H

INIT_F2_X                   EQU 0C000H
INIT_F2_Y                   EQU 09127H

INIT_F3_X                   EQU 0C000H
INIT_F3_Y                   EQU 06ED9H



; MACROS
; ------

; Sets bit number 'bit' at register 'reg'
%*DEFINE(SETBIT(reg, bit))   (
    OR %reg, (1 SHL %bit)
)


; Clears bit number 'bit' at register 'reg'
%*DEFINE(CLRBIT(reg, bit))   (
    AND %reg, (NOT (1 SHL %bit))
)


; Stores dotproduct of (x_reg, y_reg) and (f_x, f_y) in AX.
; Modifies register CX.
%*DEFINE(DOTPRODUCT(x_reg, y_reg, f_x, f_y))   (
        ; CX = force vector x times speed in x direction
        MOV AX, %x_reg
        IMUL %f_x
        MOV CX, DX

        ; CX = CX + force vector y times speed in y direction
        MOV AX, %y_reg
        IMUL %f_y
        ADD CX, DX

                        ; Correct for two multiplications (one for force and
                        ; one for trig):
        SAL CX, 2       ; Q0.15 Floating point arithmetic shift
        SAR CX, 8       ; Arithmetically make CH fill CX
        MOV AX, CX      ; AX = [80, 7F] = [-128, 127]
)


; Assumes speed in AX. Writes absolute value of speed to corresponding pulse
; width byte memory pw in the DS segment.
%*DEFINE(WRITEPULSEWIDTH(pw))   (
        ; AX = absolute value of speed: [-128, 127] -> [0, 128]
        CWD             ; Sign of AX fills DX
        XOR AX, DX      ; If AX < 0 gives 1's complement, else unchanged
        SUB AX, DX      ; If AX < 0 gives 2's complement = -AX, else unchanged

        ; Saturated addition to normalize speed to [0, 128] -> [0, 255]
        MOV BL, AL          ; BL = AL = abs(speed)
        ADD  AL, BL         ; AL = AL + BL = abs(speed) * 2 WITH POSSIBLE CARRY
        SBB  BL, BL         ; BL = 0 if no carry, BL = -1 = FFH if carry
        OR   AL, BL         ; AL = AL + BL if no carry, AL = FFH if carry

        ; Write pulse width to memory
        MOV %pw, AL

        ; Results:
        ; DL and DH are sign registers. Both are FFH if speed was negative.
        ;                               Both are 00H if speed was positive.
        ; AL contains the normalized speed [0, 255].
        ; AL is written to memory location pw.
)


; Assumes sign register is DL and mask register is BL.
%*DEFINE(UPDATEDIRECTIONBITMASK(direction_bit))   (
        SHR DL, 7                   ; Move sign bit to low bit and clear others

        SHL DL, %direction_bit      ; Move low bit to direction bit position.
                                    ; Now all except direction bit are 0.
                                    ; And direction bit is 0 if sign was pos.
                                    ; Else, direction bit is 1.

        OR BL, DL                   ; Write the direciton bit to the mask.
)
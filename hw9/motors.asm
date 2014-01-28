    NAME MOTORS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     MOTORS                                 ;
;                                 Motor Routines                             ;
;                                    EE/CS 51                                ;
;                                  Archan Luhar                              ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions to handle a periodic timer event to update
; the parallel output to the motors and the laser.
;
; The included public functions are:
;   - SwitchesTimerEventHandler
;           Checks the switches to see if any are pressed and debounces them and
;           calls the appropriate switch handler (currently just a test function
;           that enqueues the call arguments and displays them).
;   - SwitchEventHandler
;           Calls the right function given which key's handler to trigger.
;           Currently only calls test EnqueueEvent function.
;
; Revision History:
;       11/29/2013      Archan Luhar    Started Motors.
;

; local includes
$INCLUDE(general.inc)
$INCLUDE(simpmac.inc)
$INCLUDE(motors.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP

; External references
    EXTRN   Cos_Table:NEAR
    EXTRN   Sin_Table:NEAR



    
; SetMotorSpeed
;
; Description:      This function initializes the memory for shared variables
;                   used by the parallel port functions. This function must be
;                   called prior to using motors and lasers. It also initalizes
;                   the control register for the parallel port.
;
; Operation:        Sets the shared variables to their default values.
;                   Output control register value to parallel register.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: pulseWidths (WRITE)
;                   driveSpeed (WRITE)
;                   driveAngle (WRITE)
;                   parallelPortB (WRITE)
;                   pulseWidthCounter (WRITE)
;                   pulseWidthM1 (WRITE)
;                   pulseWidthM2 (WRITE)
;                   pulseWidthM3 (WRITE)
;                   f1_X (WRITE)
;                   f1_Y (WRITE)
;                   f2_X (WRITE)
;                   f2_Y (WRITE)
;                   f3_X (WRITE)
;                   f3_Y (WRITE)
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           PARALLEL_CTRL_REG
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      2 words
;
; Author:           Archan Luhar
; Last Modified:    11/30/2013
InitParallel    PROC NEAR
                PUBLIC InitParallel

    PUSH AX
    PUSH DX

    MOV DX, PARALLEL_CTRL_REG
    MOV AX, PARALLEL_CTRL_VAL
    OUT DX, AL

    MOV driveSpeed, STATIONARY_SPEED
    MOV driveAngle, DEFAULT_ANGLE
    MOV laserStatus, LASER_OFF

    MOV pulseWidthCounter, MINIMUM_ACTIVE_PULSE_WIDTH
    MOV pulseWidthM1, INACTIVE_MOTOR_PULSE_WIDTH
    MOV pulseWidthM2, INACTIVE_MOTOR_PULSE_WIDTH
    MOV pulseWidthM3, INACTIVE_MOTOR_PULSE_WIDTH
    
    MOV f1_X, INIT_F1_X
    MOV f1_Y, INIT_F1_Y
    MOV f2_X, INIT_F2_X
    MOV f2_Y, INIT_F2_Y
    MOV f3_X, INIT_F3_X
    MOV f3_Y, INIT_F3_Y

    MOV parallelPortB, DEFAULT_PARALLEL_PORTB

    POP DX
    POP AX

    RET

InitParallel    ENDP

    
; SetMotorSpeed
;
; Description:      This function sets the speed and angle of the RoboTrike
;                   motors. The speed is passed as an unsigned int,
;                   its magnitude / MAX_UINT indicating the percentage of the
;                   maximum speed. The angle is passed in as a signed integer,
;                   where 180 degrees is the maxed signed int value and -180
;                   degrees is the minimum. The angle is relative to a fixed
;                   direction on the RoboTrike.
;
; Operation:        Sets the motor pulse timeout counts to to the speed
;                   in the direction of their spin. The shared variables are set
;                   in a specific ratio as determined by the following geometry.
;                                   
;                                             --- M1 --- +
;
;                                                  r    +S
;                                                  | a /
;                                       +          |  /       /
;                                        \         | /       /
;                                         \M3             M2/
;                                          \               +
;
;                   Let a be the angle in degrees from the reference line r.
;                   Let S be the speed.
;
;                   A timeout occurs when the "count" of a motor reaches
;                   a max 0FFFFH. Thus, the motor with a higher speed will
;                   wrap past  the max count (timeout) more often and trigger a
;                   pulse more often. The counts are to be incremented in
;                   MotorTimerEventHandler.
;
; Arguments:        AX = speed [0, 65534] corresponding to -> [0, 255].
;                   BX = amgle [0, 65534] corresponding to -> [0, 360).
;                   A max integer means do not change the respective
;                   property (speed, direction).
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: pulseWidths (WRITE)
;                   driveSpeed (READ/WRITE)
;                   driveAngle (READ/WRITE)
;                   parallelPortB (WRITE)
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
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/30/2013

SetMotorSpeed   PROC NEAR
                PUBLIC SetMotorSpeed

    InitSetMotorSpeed:
        PUSHA


    CheckSpeedChange:
        CMP AX, NO_CHANGE_SPEED     ; If speed is maxed, don't change speed
        JNE SpeedChanged
    KeepCurrentSpeed:               ; Get current speed for calculations
        MOV AX, driveSpeed
        JMP NormalizeSpeed
    SpeedChanged:                   ; Else, store speed given
        MOV driveSpeed, AX
        ; JMP NormalizeSpeed
    NormalizeSpeed:                 ; Lose precision in speed but needed to make
        SHR AX, 1                   ; sign positive for signed multiplication.
        MOV CX, AX                  ; CX = speed

    CheckAngleChange:
        MOV AX, BX
        CMP AX, NO_CHANGE_ANGLE     ; Same as with speed, don't change if max
        JNE NormalizeAngle
    KeepCurrentAngle:
        MOV AX, driveAngle
        JMP GetAngleTableOffset
    NormalizeAngle:                 ; The following block of code normalizes
        MOV AX, BX                  ; the given angle to be between 0 and 360
        CMP AX, 0
        JGE AngleIsPositive
    AngleIsNegative:                ; If the angle given is negative then
        NEG AX                      ; Make positive
        XOR DX, DX
        MOV BX, 360
        DIV BX                      ; Divide by 360
        MOV AX, DX                  ; Get the remainder
        NEG AX                      ; Make negative again
        ADD AX, 360                 ; Final angle is 360 - (given mod 360)
        JMP SaveNewAngle
    AngleIsPositive:
        XOR DX, DX                  ; If angle is positive, get its mod 360
        MOV BX, 360
        DIV BX
        MOV AX, DX                  ; Final angle is (given mod 360)
        ;JMP SaveNewAngle
    SaveNewAngle:
        MOV driveAngle, AX
        ;JMP GetAngleTableOffset

    GetAngleTableOffset:
        SHL AX, 1                   ; AX = angle * 2 (byte offset in word table)
        MOV BX, AX                  ; BX = byte offset into trig word table

        
    ; Get signed velocity components: speed_x, speed_y in DI, SI respectively
    GetXYSpeeds:
        MOV AX, CS:[BX + OFFSET(Cos_Table)]             ; DI = cos(angle)
        IMUL CX                     ; DX | AX = cos(angle) (AX) * speed (CX)
        MOV DI, DX                  ; DI = speed_x
        
        MOV AX, CS:[BX + OFFSET(Sin_Table)]             ; SI = sin(angle)
        IMUL CX                     ; DX | AX = sin(angle) (AX) * speed (CX)
        MOV SI, DX                  ; SI = speed_y

        
    ; Writes motor pulse widths and directions.
    ; Dots the velocity vector with the motor force vector (result in AX)
    ; Then writes the normalized pulse width based on the speed (reads AX)
    ; Then writes to the mask ()
    SetupDirectionBitMask:
        XOR BL, BL
    SetMotor1:
        %DOTPRODUCT(DI, SI, f1_X, f1_Y)                 ; Motor 1 speed (+/-)
        %WRITEPULSEWIDTH(pulseWidthM1)                  ; width[0] = abs(speed)
        %UPDATEDIRECTIONBITMASK(M1_DIRECITON_BIT)       ; forward if +, back -
    SetMotor2:
        %DOTPRODUCT(DI, SI, f2_X, f2_Y)                 ; Motor 2 speed (+/-)
        %WRITEPULSEWIDTH(pulseWidthM2)                  ; width[1] = abs(speed)
        %UPDATEDIRECTIONBITMASK(M2_DIRECITON_BIT)       ; forward if +, back -
    SetMotor3:
        %DOTPRODUCT(DI, SI, f3_X, f3_Y)                 ; Motor 3 speed (+/-)
        %WRITEPULSEWIDTH(pulseWidthM3)                  ; width[2] = abs(speed)
        %UPDATEDIRECTIONBITMASK(M3_DIRECITON_BIT)       ; forward if +, back -
    WriteDirectionBitMask:
        AND parallelPortB, MOTORS_CLR_DIR_MASK      ; Clears direction bits        
        OR  parallelPortB, BL                       ; Sets proper direction bits

    EndSetMotorSpeed:
        POPA
        RET

SetMotorSpeed   ENDP



; ParallelTimerEventHandler
;
; Description:      Manages the motor counts and sends pulses to motors
;                   with a frequency depending on the direction and speed.
;
; Operation:        The timer handler will increment the counts every iteration.
;                   When a count = its corresponding speed, the appropriate
;                   motor will be sent a pulse and the count wrapped back to 0.
;
; Arguments:        None.
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: pulseWidthCounter (READ/WRITE)
;                   pulseWidths (READ)
;                   laserStatus (READ)
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           Motors.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Registers Used:   None.
;
; Stack Depth:      3 words
;
; Author:           Archan Luhar
; Last Modified:    11/30/2013

ParallelTimerEventHandler   PROC NEAR
                            PUBLIC ParallelTimerEventHandler

    InitParallelTimerEventHandler:
        PUSH AX
        PUSH CX
        PUSH DX

    LoadParallelBufferAndPulseWidthCounter:
        XOR AH, AH
        MOV AL, parallelPortB               ; Load the parallel port B buffer
        AND AL, PARALLEL_CLR_POW_MASK       ; Clear motor and laser power bits
        MOV CL, pulseWidthCounter           ; Load the pulse width counter


    ; Motor Pulses: Turn on power when pulse width is <= pulseWidthCounter
    Motor1Pulse:
        CMP pulseWidthM1, CL                ; Check if counter is above width
        JB Motor2Pulse                      ; Counter and widths both unsigned.
        %SETBIT(AL, M1_POWER_BIT)           ; If <= set the power bit else skip.

    Motor2Pulse:
        CMP pulseWidthM2, CL
        JB Motor3Pulse
        %SETBIT(AL, M2_POWER_BIT)

    Motor3Pulse:
        CMP pulseWidthM3, CL
        JB IncrementPulseWidthCounter
        %SETBIT(AL, M3_POWER_BIT)

    ; Done with pulses, increment counter and loop to MINIMUM_ACTIVE_PULSE_WIDTH
    IncrementPulseWidthCounter:
        INC CL
        JNZ UpdatePulseWidthCounter
        ; JS ResetPulseWidthCounter
    ResetPulseWidthCounter:
        MOV CL, MINIMUM_ACTIVE_PULSE_WIDTH
    UpdatePulseWidthCounter:
        MOV pulseWidthCounter, CL


    ; Turn laser bit on if applicable
    LaserToggle:
        CMP laserStatus, LASER_OFF      ; If laser status is off,
        JE OutputParallelFromBuffer     ; Keep laser bit off in buffer.
        ; JNE TurnLaserOn

    TurnLaserOn:
        %SETBIT(AL, LASER_POWER_BIT)


    ; Output the buffer that was just created to the port
    OutputParallelFromBuffer:
        MOV DX, PARALLEL_PORTB_REG      ; Output the buffer to parallel port B
        OUT DX, AL
    SaveParallelBuffer:
        MOV parallelPortB, AL           ; Save the parallel port B buffer

    EndParallelTimerEventHandler:
        POP DX
        POP CX                          ; Restore registers
        POP AX

        RET                             ; Return to timer handler manager

ParallelTimerEventHandler   ENDP



; GetMotorSpeed
;
; Description:      Returns the current motor speed in AX.
;
; Operation:        Gets the motor speed from the shared memory.
;
; Arguments:        None.
;
; Return Value:     AX = motor speed.
;
; Local Variables:  None.
;
; Shared Variables: driveSpeed
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
; Registers Used:   AX.
;
; Stack Depth:      0
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013

GetMotorSpeed   PROC NEAR
                PUBLIC GetMotorSpeed

    MOV AX, driveSpeed              ; Set laser status shared variable from AX
    RET

GetMotorSpeed   ENDP



; GetMotorDirection
;
; Description:      Returns the current motor direction in AX.
;
; Operation:        Gets the motor direction from the shared memory.
;
; Arguments:        None.
;
; Return Value:     AX = motor direction.
;
; Local Variables:  None.
;
; Shared Variables: motor_info.
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
; Registers Used:   AX.
;
; Stack Depth:      0
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013

GetMotorDirection   PROC NEAR
                    PUBLIC GetMotorDirection

    MOV AX, driveAngle              ; Set laser status shared variable from AX
    RET

GetMotorDirection   ENDP



; SetLaser
;
; Description:      Sets Laser on or off depending on a boolean argument.
;
; Operation:        Sets the laserStatus shared variable from the AX argument.
;                   The parallel timer event handler should read this boolean
;                   to turn on and off the laser.
;
; Arguments:        AX = zero turns it off, nonzero turns it on
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: laserStatus (WRITE)
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
; Stack Depth:      0
;
; Author:           Archan Luhar
; Last Modified:    11/30/2013

SetLaser            PROC NEAR
                    PUBLIC SetLaser

    MOV laserStatus, AX             ; Set laser status shared variable from AX
    RET

SetLaser            ENDP


; GetLaser
;
; Description:      Returns zero if laser is off, else returns nonzero value.
;
; Operation:        Reads the shared variable laserStatus and returns it in AX.
;
; Arguments:        None.
;
; Return Value:     AX = zero if off, nonzero if on.
;
; Local Variables:  None.
;
; Shared Variables: laserStatus (READ)
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
; Registers Used:   AX.
;
; Stack Depth:      0
;
; Author:           Archan Luhar
; Last Modified:    11/29/2013

GetLaser            PROC NEAR
                    PUBLIC GetLaser

    MOV AX, laserStatus             ; Return laser status shared variable via AX
    RET

GetLaser            ENDP




; Dummy Functions, Turret rotation and elevation not Implemented
SetTurretAngle PROC NEAR
               PUBLIC SetTurretAngle
    NOP
    RET
SetTurretAngle ENDP

SetRelTurretAngle PROC NEAR
               PUBLIC SetRelTurretAngle
    NOP
    RET
SetRelTurretAngle ENDP

GetTurretAngle PROC NEAR
               PUBLIC GetTurretAngle
    MOV AX, 0
    RET
GetTurretAngle ENDP

SetTurretElevation PROC NEAR
               PUBLIC SetTurretElevation
    NOP
    RET
SetTurretElevation ENDP

GetTurretElevation PROC NEAR
               PUBLIC GetTurretElevation
    MOV AX, 0
    RET
GetTurretElevation ENDP





CODE ENDS


DATA SEGMENT PUBLIC 'DATA'

    ; states of the motor and laser
    driveSpeed                  DW  ?
    driveAngle                  DW  ?
    laserStatus                 DW  ?

    ; bit buffer for the parallel port b
    parallelPortB               DB  ?   ; PARALLEL BUFFER

    ; PWM variables
    pulseWidthCounter           DB  ?   ; PULSE COUNTER AND PULSE WIDTHS
    pulseWidthM1                DB  ?
    pulseWidthM2                DB  ?
    pulseWidthM3                DB  ?
    
    ; Force variables for the motor -- in case user wants to change them
    ; A function would have to be implemented to set them.
    f1_X                        DW ?
    f1_Y                        DW ?
    f2_X                        DW ?
    f2_Y                        DW ?
    f3_X                        DW ?
    f3_Y                        DW ?

DATA ENDS


    END
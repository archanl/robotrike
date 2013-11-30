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
; check key presses and execute the right key handler.
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
;       11/29/2013      Archan Luhar    Finished switches.

; local includes
$INCLUDE(general.inc)
$INCLUDE(motors.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP

; External references
    EXTRN   EnqueueEvent:NEAR
    
    
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
;                   in the direction of their spin. The shared variables
;                   motor1_count, motor2_count, and motor3_count are set in a
;                   specific ratio as determined by the following geometry.
;                                   
;                                             --- M1 --- +
;
;                                                  r    +S
;                                                  | a /
;                                       +          |  /       +
;                                        \         | /       /
;                                         \M2             M2/
;                                          \               /
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
; Arguments:        AX = speed
;                   BX = direction
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: motor_info       2 word array
;                   motor_speeds     3 word array
;                   motor_directions 3 byte array
;                   motor_counts     3 word array
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
; Last Modified:    11/18/2013
;
; Pseudocode
; ----------
;                   motor_speeds[1] = motor_counts[1] = |S * sin(angle)     |
;                   motor_speeds[2] = motor_counts[2] = |S * cos(angle - 30)|
;                   motor_speeds[3] = motor_speeds[3] = |S * cos(angle + 30)|
;                   motor_directions[1] = sign(S * sin(angle))
;                   motor_directions[2] = sign(S * cos(angle - 30))
;                   motor_directions[3] = sign(S * cos(angle + 30))
;                   
;                   motor_info[speed] = S
;                   motor_info[direction] = angle
;


; MotorTimerEventHandler
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
; Shared Variables: motor_speeds     3 word array
;                   motor_directions 3 byte array
;                   motor_counts     3 word array
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
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013
;
; Pseudocode
; 
; for i in range(num_motors):
;       if motor_speeds[i] > ZERO_THRESHOLD:
;           motor_counts[i] += motor_speeds[i]
;           if overflow:
;               Pulse motor i in direction motor_directions[i]
;           



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
; Registers Used:   AX, return value.
;
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013
;
; Pseudocode
; ----------
;
; return motor_info[speed]
;


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
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/18/2013
;
; Pseudocode
; ----------
;
; return motor_info[direction]
;



; SetLaser
;
; Description:      Sets Laser on or off depending on a boolean argument.
;
; Operation:        Sets the laser_on shared variable to the argument and
;                   turns on/off laser.
;
; Arguments:        AX = zero turns it off, nonzero turns it on
;
; Return Value:     None.
;
; Local Variables:  None.
;
; Shared Variables: laser_on
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
; Last Modified:    11/18/2013
;
; Pseudocode
; ----------
;
; turnOn = AX
;
; if turnOn:
;       turn on laser
; else:
;       turn off laser
;
; laser_on = turnOn
;


; GetLaser
;
; Description:      Returns zero if laser is off, else returns nonzero value.
;
; Operation:        Reads the shared variable laser_on and returns it in AX.
;
; Arguments:        None.
;
; Return Value:     AX = zero if off, nonzero if on.
;
; Local Variables:  None.
;
; Shared Variables: laser_on
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
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    11/29/2013

GetLaser            PROC NEAR
                    PUBLIC GetLaser

    MOV AX, laserStatus             ; Return laser status shared variable via AX
    RET

GetLaser            ENDP


CODE ENDS


DATA SEGMENT PUBLIC 'DATA'

    pulseWidthCounter           Dw  ?
    pulseWidths                 DW  NUM_MOTORS  DUP (?)
    driveSpeed                  DW  ?
    driveAngle                  DB  ?
    laserStatus                 DB  ?
    
    

DATA ENDS


    END
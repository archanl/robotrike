    NAME SERIALPR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    SERIALPR                                ;
;                                Serial Processing                           ;
;                                    EE/CS 51                                ;
;                                  Archan Luhar                              ;
;                                 TA: Joe Greef                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
; ParseSerialChar
;
; Description:      This function updates the state machine and executes
;                   the proper functions according to the commands given.
;
; Operation:        This function receives a character and inserts it into
;                   the current state of the parsing state machine.
;                   Then it calls the action associated with the current state.
;                   The action updates the state machine and if necessary
;                   calls an external function with parameters built from
;                   the values in thes tate machine.
;
; Arguments:        AL = character to parse.
;
; Return Value:     AX = zero if successful, nonzero if there parsing error.
;
; Local Variables:  None.
;
; Shared Variables: currentState
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
; Registers Used:   AX
;
; Stack Depth:      .
;
; Author:           Archan Luhar
; Last Modified:    12/2/2013
;
; Pseudocode:
; -----------
;   characterParser(char):
;       status = successful
;       currentState.value = char
;       status = currentState.action()
;       return status
;       
;
;   Example state machine:
;       Main -> SetSpeedState -> NextSpeedByte -
;         ^                                    |
;         |------------------------------------|
;
;   How it could evolve:
;       (state would be initialized to the main state)
;
;       State: Main (value = set speed constant, action = MainHandler)
;           Action: if currentState.value is in table of main states
;                       newState = lookup proper state (SetSpeedState)
;                       Set currentState to newState
;                       return success
;                   else:
;                       return failure
;
;       State: SetSpeedState
;           Value:  Lower 8 bits of speed
;           Action: Set currentState to NextSpeedByte. Return success.
;
;       State: NextSpeedByte
;           Value:  Upper 8 bits of speed
;           Action: speed = NextSpeedByte.value | SetSpeedState.value
;                   angle = no change
;                   call SetMotorSpeed(speed, angle)
;                   Set state to Main.
;                   Return success.
;           


CODE ENDS


DATA SEGMENT PUBLIC 'DATA'
; state machine
DATA ENDS


    END
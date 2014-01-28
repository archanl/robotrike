; Events include file
; Definitons shared between units

; Length of event queue
EVENTS_QUEUE_LENGTH     EQU 64

; Event codes
EVENT_KEYPRESS          EQU 0
EVENT_SERIAL_ERROR      EQU 1
EVENT_SERIAL_CHAR       EQU 2

; Serial character types
SCHAR_SERIAL_ERROR      EQU 'E'		; Only sent from motor to remote unit
SCHAR_NEGATIVE			EQU '-'
SCHAR_POSITIVE			EQU '+'
SCHAR_SPEED             EQU 'S'
SCHAR_REL_SPEED			EQU 'V'
SCHAR_DIR               EQU 'D'
SCHAR_LASER_ON			EQU 'F'
SCHAR_LASER_OFF			EQU 'O'
SCHAR_END               EQU 13		; Must end all messages with this

; Each speed step should be 1% of max speed: 655
REL_SPEED_STEP_CHAR1	EQU '6'
REL_SPEED_STEP_CHAR2	EQU '5'
REL_SPEED_STEP_CHAR3	EQU '5'

; Each angle step = 5 degrees
ANGLE_STEP_CHAR			EQU '5'
FIRST_SWITCHES_ROW          EQU     80H ; address of first switch row input
SWITCHES_PER_ROW            EQU     4   ; number of columns
NUM_SWITCH_ROWS             EQU     4   ; number of rows

NO_SWITCH_PRESSED           EQU     0   ; current_pressed_switch default value

; Debouncing and repeat times
KEY_PRESS_INIT_DEBOUNCE     EQU     50  ; ms
KEY_REPEAT_DEBOUNCE         EQU     500 ; ms
KEY_REPEAT_RATE             EQU     100 ; ms
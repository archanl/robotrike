; Timer Interrupt Vector
Tmr2Vec         EQU     19              ; Timer 2


; Interrupt Controller Addresses
INTCtrlrCtrl    EQU     0FF32H          ; Timer interrupt controller
INTCtrlrEOI     EQU     0FF22H          ; Interrupt controller EOI register

; Interrupt Controller Register Values
INTCtrlrCVal    EQU     00001H          ;0000 0000 0000 ----  reserved
                                        ;---- ---- ---- 0---  enable interrupt
                                        ;---- ---- ---- -001  timer priority

TimerEOI        EQU     00008H          ; Timer EOI command for all timers


; Timer Addresses
Tmr2Ctrl        EQU     0FF66H          ; Timer 2 Control Register
Tmr2MaxCnt      EQU     0FF62H          ; Timer 2 Max Count A Register
Tmr2Count       EQU     0FF60H          ; Timer 2 Count Register

; Timer Control Register Value
Tmr2CtrlVal     EQU     0E001H          ;1--- ---- ---- ----  enable timer
                                        ;-1-- ---- ---- ----  write to control
                                        ;--1- ---- ---- ----  enable interrupts
                                        ;---- 0000 00-0 000-  reserved
                                        ;---0 ---- --0- ----  read only
                                        ;---- ---- ---- ---1  continuous mode


; Timing Definitions
COUNTS_PER_MS   EQU     2304            ; Number of timer counts per 1 ms
                                        ; (assumes 18.432 MHz clock)
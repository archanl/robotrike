; Timer Interrupt Vector
Tmr0Vec         EQU     8               ; Timer 0
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
Tmr0Ctrl        EQU     0FF56H          ; Timer 0 Control Register
Tmr0MaxCntA     EQU     0FF52H          ; Timer 0 Max Count A Register
Tmr0Count       EQU     0FF50H          ; Timer 0 Count Register

Tmr2Ctrl        EQU     0FF66H          ; Timer 2 Control Register
Tmr2MaxCnt      EQU     0FF62H          ; Timer 2 Max Count A Register
Tmr2Count       EQU     0FF60H          ; Timer 2 Count Register


; Timer Control Register Value
Tmr0CtrlVal     EQU     0E001H          ; 1--- ---- ---- ----  Enable timer
                                        ; -1-- ---- ---- ----  Write to control
                                        ; --1- ---- ---- ----  Enable interrupts
                                        ; ---- 0000 00-- ----  Reserved
                                        ; ---0 ---- --0- ----  Read only
                                        ; ---- ---- ---0 ----  TMRIN0 is enable
                                        ; ---- ---- ---- 00--  No prescaling
                                        ; ---- ---- ---- --0-  Single cntr mode
                                        ; ---- ---- ---- ---1  Continuous mode

Tmr2CtrlVal     EQU     0E001H          ;1--- ---- ---- ----  Enable timer
                                        ;-1-- ---- ---- ----  Write to control
                                        ;--1- ---- ---- ----  Enable interrupts
                                        ;---- 0000 00-0 000-  Reserved
                                        ;---0 ---- --0- ----  Read only
                                        ;---- ---- ---- ---1  Continuous mode


; Timing Definitions assuming 18.432 MHz clock
COUNTS_PER_MS_DIV_4         EQU     576     ; Number of timer counts per 0.25 ms
TIMER_0_MAX_COUNT_VAL       EQU     COUNTS_PER_MS_DIV_4

COUNTS_PER_MS               EQU     2304    ; Number of timer counts per 1 ms
TIMER_2_MAX_COUNT_VAL       EQU     COUNTS_PER_MS
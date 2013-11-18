; Chip Select Unit Addresses
PACSreg         EQU     0FFA4H          ; PACS register
MPCSreg         EQU     0FFA8H          ; MPCS register

; Control Register Values
PACSval         EQU     00000H          ;0000000000------  starts address 0
                                        ;----------000---  reserved
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states

MPCSval         EQU     00183H          ;0---------000---  reserved
                                        ;-0000001--------  MCS is 8KB
                                        ;--------1-------  output PCS5/PCS6
                                        ;---------0------  PCS in I/O space
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states
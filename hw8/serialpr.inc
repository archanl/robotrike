; Serial Parser Include File

; Serial Processing Definitions
PARSE_SUCCESS   EQU 0
PARSE_FAILURE   EQU 1

INPUT_NUM_BASE  EQU 10





; States for the serial processor state machine
; Must match order of state table entries
ST_INITIAL                  EQU 0

ST_ABS_SPEED                EQU 1
ST_ABS_SPEED_SIGN           EQU 2
ST_ABS_SPEED_DIGIT          EQU 3

ST_REL_SPEED                EQU 4
ST_REL_SPEED_SIGN           EQU 5
ST_REL_SPEED_DIGIT          EQU 6

ST_SET_DIR                  EQU 7
ST_SET_DIR_SIGN             EQU 8
ST_SET_DIR_DIGIT            EQU 9

ST_ROT_TUR                  EQU 10
ST_ROT_TUR_SIGN             EQU 11
ST_ROT_TUR_ABS_DIGIT        EQU 12
ST_ROT_TUR_REL_DIGIT        EQU 13

ST_ELE_TUR                  EQU 14
ST_ELE_TUR_SIGN             EQU 15
ST_ELE_TUR_DIGIT            EQU 16

ST_LASER_ON                 EQU 17
ST_LASER_OFF                EQU 18

NUM_STATES                  EQU 19


; Token types
TOKEN_ABS_SPEED EQU 0
TOKEN_REL_SPEED EQU 1
TOKEN_SET_DIR   EQU 2
TOKEN_ROT_TUR   EQU 3
TOKEN_ELE_TUR   EQU 4
TOKEN_LAS_ON    EQU 5
TOKEN_LAS_OFF   EQU 6
TOKEN_PLUS      EQU 7
TOKEN_MINUS     EQU 8
TOKEN_DIGIT     EQU 9
TOKEN_RETURN    EQU 10
TOKEN_OTHER     EQU 11

NUM_TOKEN_TYPES EQU 12



; Other Constants

TOKEN_MASK    EQU    01111111B    ;mask high bit of token

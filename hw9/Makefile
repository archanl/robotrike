# EE/CS 51
# HW9 - Robotrike Makefile
# Archan Luhar
# TA: Joe Greef

all: commonassemble remoteassemble motorassemble commonlink remonlylink motonlylink remotelink motorlink remotelocate motorlocate
remote: commonassemble remoteassemble commonlink remonlylink remotelink remotelocate
motor: commonassemble motorassemble commonlink motonlylink motorlink motorlocate


commonassemble:
	asm86 cselect.asm m1 ep db
	asm86 events.asm m1 ep db
	asm86 queue.asm m1 ep db
	asm86 serial.asm m1 ep db
	asm86 converts.asm m1 ep db

remoteassemble:
	asm86 RemMain.asm m1 ep db
	asm86 RemTimer.asm m1 ep db
	asm86 RemEvent.asm m1 ep db
	asm86 KeyParse.asm m1 ep db
	asm86 RemParse.asm m1 ep db
	asm86 display.asm m1 ep db
	asm86 switches.asm m1 ep db
	asm86 segtab14.asm m1 ep db

motorassemble:
	asm86 MotMain.asm m1 ep db
	asm86 MotTimer.asm m1 ep db
	asm86 MotEvent.asm m1 ep db
	asm86 MotParse.asm m1 ep db
	asm86 motors.asm m1 ep db
	asm86 trigtbl.asm m1 ep db

	
commonlink:
	link86 converts.obj,cselect.obj,events.obj,queue.obj,serial.obj to common.lnk
remonlylink:
	link86 RemMain.obj,RemEvent.obj,RemTimer.obj,KeyParse.obj,RemParse.obj,segtab14.obj,display.obj,switches.obj to remonly.lnk
motonlylink:
	link86 MotMain.obj,MotTimer.obj,MotEvent.obj,MotParse.obj,motors.obj,trigtbl.obj to motonly.lnk
	
remotelink:
	link86 remonly.lnk,common.lnk to remote.lnk
motorlink:
	link86 motonly.lnk,common.lnk to motor.lnk

remotelocate:
	loc86 remote.lnk NOIC AD(SM(CODE(400H),DATA(4000H), STACK(7000H)))

motorlocate:
	loc86 motor.lnk NOIC AD(SM(CODE(400H),DATA(4000H), STACK(7000H)))
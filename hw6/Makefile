# EE/CS 51
# HW6 - Parallel Output (Motor Routines and Output, Laser Output)
# Archan Luhar
# TA: Joe Greef

all: assemble link locate

check:
	asm86chk hw6main.asm

	asm86chk cselect.asm
	
	asm86chk timer.asm

	asm86chk trigtbl.asm
	asm86chk motors.asm

assemble:
	asm86 hw6main.asm m1 ep db

	asm86 cselect.asm m1 ep db
	
	asm86 timer.asm m1 ep db

	asm86 trigtbl.asm m1 ep db
	asm86 motors.asm m1 ep db

link:
	link86 hw6main.obj,hw6test.obj,cselect.obj,timer.obj,trigtbl.obj,motors.obj

locate:
	loc86 hw6main.lnk NOIC AD(SM(CODE(400H),DATA(4000H), STACK(7000H)))
# EE/CS 51
# HW4 - Display Routines
# Archan Luhar
# TA: Joe Greef

all: assemble link locate

check:
	asm86chk hw4main.asm
	asm86chk display.asm
	asm86chk cselect.asm
	asm86chk timer.asm
	asm86chk converts.asm

assemble:
	asm86 hw4main.asm m1 ep db
	asm86 display.asm m1 ep db
	asm86 segtab14.asm m1 ep db
	asm86 cselect.asm m1 ep db
	asm86 timer.asm m1 ep db
	asm86 converts.asm m1 ep db

link:
	link86 hw4main.obj,display.obj,segtab14.obj,cselect.obj,timer.obj,converts.obj,hw4test.obj

locate:
	loc86 hw4main.lnk
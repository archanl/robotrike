# EE/CS 51
# HW4 - Display Routines
# Archan Luhar
# TA: Joe Greef

all: assemble link locate

check:
	asm86chk hw5main.asm
	asm86chk cselect.asm
	asm86chk timer.asm
	asm86chk segtab14.asm
	asm86chk converts.asm
	asm86chk switches.asm
	asm86chk display.asm

assemble:
	asm86 hw5main.asm m1 ep db
	asm86 cselect.asm m1 ep db
	asm86 timer.asm m1 ep db
	asm86 segtab14.asm m1 ep db
	asm86 converts.asm m1 ep db
	asm86 display.asm m1 ep db
	asm86 switches.asm m1 ep db

link:
	link86 hw5main.obj,cselect.obj,timer.obj,segtab14.obj,converts.obj,display.obj,switches.obj,hw54test.obj

locate:
	loc86 hw5main.lnk
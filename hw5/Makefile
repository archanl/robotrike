# EE/CS 51
# HW5 - Keypad Routines
# Archan Luhar
# TA: Joe Greef

all: assemblemain assemble link locate

nodisplay: assemblemainnodisplay assemble nodisplaylink locate

check:
	asm86chk hw5main.asm
	asm86chk hw5main2.asm
	asm86chk cselect.asm
	asm86chk timer.asm
	asm86chk segtab14.asm
	asm86chk converts.asm
	asm86chk switches.asm
	asm86chk display.asm

assemblemain:
	asm86 hw5main.asm m1 ep db

assemblemainnodisplay:
	asm86 hw5main2.asm m1 ep db

assemble:
	asm86 display.asm m1 ep db
	asm86 cselect.asm m1 ep db
	asm86 timer.asm m1 ep db
	asm86 segtab14.asm m1 ep db
	asm86 converts.asm m1 ep db
	asm86 switches.asm m1 ep db

link:
	link86 hw5main.obj,cselect.obj,timer.obj,segtab14.obj,converts.obj,display.obj,switches.obj,hw54test.obj

nodisplaylink:
	link86 hw5main2.obj,cselect.obj,timer.obj,segtab14.obj,converts.obj,display.obj,switches.obj,hw5test.obj TO hw5main.lnk

locate:
	loc86 hw5main.lnk NOIC AD(SM(CODE(400H),DATA(4000H), STACK(7000H)))
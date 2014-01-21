# EE/CS 51
# HW8 - Serial Processing Makefile
# Archan Luhar
# TA: Joe Greef

all: check assemble link locate

check:
	asm86chk hw8main.asm

	asm86chk serialpr.asm

assemble:
	asm86 hw8main.asm m1 ep db

	asm86 serialpr.asm m1 ep db


link:
	link86 hw8main.obj,serialpr.obj,hw8test.obj

locate:
	loc86 hw8main.lnk NOIC AD(SM(CODE(400H),DATA(4000H), STACK(7000H)))
# EE/CS 51
# HW7 - Serial Input Output
# Archan Luhar
# TA: Joe Greef

all: check assemble link locate

check:
	asm86chk hw7main.asm

	asm86chk cselect.asm
    
    asm86chk queue.asm

	asm86chk serial.asm

assemble:
	asm86 hw7main.asm m1 ep db

	asm86 cselect.asm m1 ep db
    
    asm86 queue.asm m1 ep db

	asm86 serial.asm m1 ep db

link:
	link86 hw7main.obj,hw7test.obj,cselect.obj,queue.obj,serial.obj

locate:
	loc86 hw7main.lnk NOIC AD(SM(CODE(400H),DATA(4000H), STACK(7000H)))
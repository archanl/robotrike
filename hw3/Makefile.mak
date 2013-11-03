# EE/CS 51
# HW3 - Queue Routines
# Archan Luhar
# TA: Joe Greef

# Makefile.mak

all: assemble link locate

check:
	asm86chk queue.asm
	asm86chk hw3main.asm

assemble:
	asm86 queue.asm m1 ep db
	asm86 hw3main.asm m1 ep db

link:
	link86 hw3main.obj,queue.obj,hw3test.obj

locate:
	loc86 hw3main.lnk
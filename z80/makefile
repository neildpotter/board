rom.z80 : *.asm
	rm rom.collection
	cat restart.as interrupt.as *.asm  >> rom.collection
	z80-asm rom.collection rom.z80

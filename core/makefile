core.z80 : *.asm
	rm rom.collection
	cat interrupt.as *.asm  >> rom.collection
	z80-asm rom.collection 2000:core.z80

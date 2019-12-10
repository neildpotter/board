echo.z80 : echo.asm zzz*.asm
	rm app.collection
	cat echo.asm zzz_jumptable.asm zzz_dummyEndpoints.asm  >> app.collection
	z80-asm app.collection 0000:100:echo.z80

diss.z80 : diss.asm zzz*.asm
	rm app.collection
	cat diss.asm zzz_jumptable.asm zzz_dummyEndpoints.asm  >> app.collection
	z80-asm app.collection 0000:2700:diss.z80


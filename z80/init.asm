	;
	; Init.asm
	; Initialize the board
	;
initInit:

	DI
	ld a,0x0f
	out (memLatch), a			; default to slot 7
	LD SP, memSharedTop
	ld a, iValue
	ld i,a
	call memInit					; Initialize the memory (select the default slot)
	call ctcInit					; Initialize the CTC
	call pioInit					; Initialize the PIOs
	call dartInit					; Initialize the dart

	IM 2
	EI
	jp keepAlive
	call memTest
initHalt:
	halt
	jr initHalt



	;
	; pio.asm
	; Parallel input output code
	;
	
	;
	; Port mappings correspond to hardware address
	;
pio1Adata 	equ 0xBC			; PIO 1 is the chip on the left
pio1AControl equ 0xBD
pio1Bdata 	equ 0xBE
pio1BControl equ 0xBF

pio2Adata 	equ 0x7C			; PIO 2 is the chip on the right
pio2AControl equ 0x7D
pio2Bdata 	equ 0x7E
pio2BControl equ 0x7F

pioInit:
	;
	; Initialize port B of the chip on the right as output
	;
	ld a,0x0f						; Mode word - output
	out (pio2BControl),a
	ld a,0x7f
	out (pio2Bdata),a
	ld (iy+pioLEDS),a
	ret


	;CR67 - bit 0
	;CR70 - bit 1
	;CR29 - bit 2
	;CR32 - bit 3
	;CR24 - bit 4
	;CR26 - bit 5
	;CR25 - bit 6

	;
	; define a base process to soak up the CPU
	; l = bit mask to toggle
	;
baseProcess:
	ld c,200							
baseProcess1:
	ld b,h
baseProcess2:
	call procYield
	dec b
	jr nz,baseProcess2
	ld a,(iy+pioLEDS)
	xor l							; output the bit
	out (pio2Bdata),a
	ld (iy+pioLEDS),a
	dec c
	jr nz,baseProcess
	ret

	;
	; Interrupt service routines
	;
pio1Interrupt:	
pio2Interrupt:
	reti

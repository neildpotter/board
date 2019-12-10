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
		ret

	;
	; Interrupt service routines
	;
pio1Interrupt:	
pio2Interrupt:
	reti

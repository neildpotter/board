	;
	; ctc.asm
	; Counter timer code
	;
	
	;
	; Port mappings correspond to hardware address
	;
ctcChannel0 equ 0xEC
ctcChannel1 equ 0xED
ctcChannel2 equ 0xEE
ctcChannel3 equ 0xEF

ctcInit:
	;
	; Channel 0 is the serial clock for channel A of the dart
	; Set the divider to correspond to 9600 baud, no interrupts
	;
	LD a, 0x07				;  0 = Disable interupt
							;  0 = timer mode
							;  0 = 16 prescaler
							;  0 = Clock falling edge
							;  0 = Automatic trigger when time constant is loaded
							;  1 = Time constant follows
							;  1 = Reset
							;  1 = Control word
	OUT (ctcChannel0), a
	LD a, 0x2				; Time constant corresponding to 9600 baud
	OUT (ctcChannel0), a
	ret

	;
	; CTC interrupt routine
ctcInterrupt:

	reti



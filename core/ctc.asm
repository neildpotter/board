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

	; Write the interrupt vector to Channel0. CTC supplies bits 2 and 1, bit 0 identifies it as an interrupt vector

	ld a,ctcVector
	OUT (ctcChannel0), a

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


	; Channel 2 is a prescaler, feeding Channel 3
	; Divide the system 4.9152Mhz clock by 256 * 60 = 320hz 
	LD a, 0x27				;  0 = Disable interupt
							;  0 = timer mode
							;  1 = 256 prescaler
							;  0 = Clock falling edge
							;  0 = Automatic trigger when time constant is loaded
							;  1 = Time constant follows
							;  1 = Reset
							;  1 = Control word
	OUT (ctcChannel2), a
	LD a, 60					; Time constant corresponding to 320hz
	OUT (ctcChannel2), a

	ld (iy+clockh),0
	ld (iy+clockm),0
	ld (iy+clocks),0
	ld (iy+clockd),0

	; Channel 1 interupts 75 times per second.
	; 5.9152 Mhz /256 prescaler / 256 counter
	LD a, 0xa7				;  1 = Enable interupt
							;  0 = timer mode
							;  1 = 256 prescaler
							;  0 = Clock falling edge
							;  0 = Automatic trigger when time constant is loaded
							;  1 = Time constant follows
							;  1 = Reset
							;  1 = Control word
	OUT (ctcChannel1), a
	LD a,0					; Time constant 256 corresponding to 75hz
	OUT (ctcChannel1), a
	ret




	;
	; CTC interrupt routine
ctcInterrupt0:
ctcInterrupt3:
ctcInterrupt2:
	reti
ctcInterrupt1:
	di
	ex af,af'
	dec (iy+procCount)                                         ; decrement the proc counter to eventually force priority 1
	jr nz,ctcProcCountContinue
	ld (iy+procCount),maxProcInterval
ctcProcCountContinue
	exx
	ld hl,procYield
	push hl						
	exx
	dec (iy+clockt)
	jr nz,ctcinteruptend
	ld (iy+clockt),75				; 4.9152 mhz /256 /256 = 75hz

	ld a,(iy+clocks)
	inc a
	ld (iy+clocks),a
	cp 60
	jr nz,ctcinteruptend

	ld (iy+clocks),0
	ld a,(iy+clockm)
	inc a
	cp 60
	ld (iy+clockm),a
	jr nz,ctcinteruptend
	ld (iy+clockm),0
	ld a,(iy+clockh)
	inc a
	cp 24
	ld (iy+clockh),a
	jr nz,ctcinteruptend
	ld (iy+clockh),0
	inc (iy+clockd)
ctcInteruptend:
	ex af,af'
	ei
	reti

ctcGetTime:
	ld c,(iy+clockd)
	ld b,(iy+clockh)
	ld h,(iy+clockm)
	ld l,(iy+clocks)
	ret




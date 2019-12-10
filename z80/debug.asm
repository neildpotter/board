
            ; Debug
            ; Output 16 bytes of memory dump starting from HL
            ;

debug:
	push af           
	push hl
	push de
	push bc
            ;
            ; Output the address in hex
            ;
	ld a,h
	call toHex
	ld a,d
	RST 0x10
	ld a,e
	RST 0x10
	ld a,l
	call toHex
	ld a,d
	RST 0x10
	ld a,e
	RST 0x10
	ld a,':'
	RST 0x10
	ld a,' '
	RST 0x10
	;
        ; Output 16 bytes in hex
	;
 	ld b,16
debugLoop:
	ld a,(hl)
	call toHex
	ld a,d
	RST 0x10
	ld a,e
	RST 0x10
	ld a,' '
	RST 0x10
	inc hl
	dec b
	ld a,b
	or a
	jr nz,debugLoop
	;
	; Terminate the line with a CR LF
	;
	ld a,0x0D
	RST 0x10
	ld a,0x0A
	RST 0x10
 	pop bc
	pop de
	pop hl
	pop af           
	ret
	;
        ; Convert A to ascii hex in DE
	;

toHex:
	push bc
	push af
	ld c, a                      ; a = number to convert
	call num1
	ld d, a
	ld a, c
	call Num2
	ld e, a
	pop af
	pop bc
	ret                           ; return with hex number in de

num1:
	rra
	rra
	rra
	rra
num2:       
	or 0xF0
	daa
	add a, 0xA0
	adc a, 0x40               ; Ascii hex at this point (0 to F)  
	ret

 

 

 

 

 

 

 

 

____________________________

 


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
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,l
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,'-'
	call dartPutTerm
	ld a,' '
	call dartPutTerm
	;
        ; Output 16 bytes in hex
	;
 	ld b,16
	push hl
debugLoop:
	ld a,(hl)
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,' '
	call dartPutTerm
	inc hl
	dec b
	ld a,b
	or a
	jr nz,debugLoop
	;
	; repeat writing the ascii
	;
	ld a,9
	call dartPutTerm
	pop hl
	ld b,16
debugLoop2:
	ld a,(hl)
	cp 0x20
	jr c,debugLoop3
	cp 0x7f
	jr nc,debugLoop3
	jr debugLoop4
debugLoop3:
	ld a,'.'
debugLoop4:
	call dartPutTerm
	inc hl
	djnz debugLoop2
	;
	; Terminate the line with a CR LF
	;
	ld a,0x0D
	call dartPutTerm
	ld a,0x0A
	call dartPutTerm
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


debugHLDE:
	push af           
	push hl
	push de
	push bc
	push de 
           ;
            ; Output HL in hex
            ;
	ld a,h
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,l
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,'-'
	call dartPutTerm
	pop hl
		; 
		; output DE in hex
		;
	ld a,h
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,l
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	;
	; Terminate the line with a CR LF
	;
	ld a,0x0D
	call dartPutTerm
	ld a,0x0A
	call dartPutTerm
 	pop bc
	pop de
	pop hl
	pop af           
	ret

 	;
	; Dump registers
	;

registerHL: defm "HL "
	defb	0
registerDE: defm "DE "
	defb	0
registerBC: defm "BC "
	defb	0
registerAF: defm "AF "
	defb	0
registerIX: defm "IX "
	defb	0
registerIY: defm "IY "
	defb	0
registerSP: defm "SP "
	defb	0

debugRegisters:
	push af
	push hl
	push bc
	push de

	push iy
	push ix
	push af
	push de
	push hl
	push bc

	ld hl,0
	add hl,sp
	push hl
	pop bc
	ld hl,registerSP
	call debugReg

	pop bc
	ld hl,registerBC
	call debugReg

	pop bc
	ld hl,registerHL
	call debugReg

	pop bc
	ld hl,registerDE
	call debugReg

	pop bc
	ld hl,registerAF
	call debugAF

	pop bc
	ld hl,registerIX
	call debugReg

	pop bc	
	ld hl,registerIY
	call debugReg

	pop de
	pop bc
	pop hl
	pop af
	ret


debugAF:				; HL has the register name, BC the value
	call dartPutString
	ld a,b
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,9
	call dartPutTerm
	ld a,'-'
	bit 7,c
	jr z,debugAF1
	ld a,'S'
debugAF1:
	call dartPutTerm
	ld a,'-'
	bit 6,c
	jr z,debugAF2
	ld a,'Z'
debugAF2:
	call dartPutTerm
	ld a,'-'
	bit 4,c
	jr z,debugAF3
	ld a,'H'
debugAF3:
	call dartPutTerm
	ld a,'-'
	bit 2,c
	jr z,debugAF4
	ld a,'P'
debugAF4:
	call dartPutTerm
	ld a,'-'
	bit 1,c
	jr z,debugAF5
	ld a,'N'
debugAF5:
	call dartPutTerm
	ld a,'-'
	bit 0,c
	jr z,debugAF6
	ld a,'C'
debugAF6:
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	ld a,0x0a
 	call dartPutTerm
	ret

debugReg:				; HL has the register name, BC the value
	call dartPutString
	ld a,b
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm

	ld a,c
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	ld a,0x0a
 	call dartPutTerm
	ret
 

debugDelay:
	push hl
	push bc
	push af
	ld hl,0
debugDelay1:
	ld b,20
debugDelay2
	nop
	nop
	djnz debugDelay2
	dec hl
	ld a,h
	or l
	jr nz,debugDelay1
	pop af
	pop bc
	pop hl
	ret
 
; Print the value of a in decimal
putTermDecimal
	push bc
	ld	c,100
	call	Na1
	ld	c,10
	call	Na1
	ld	c,1
	call Na1
	pop bc
	ret
Na1:	ld	b,'0'
	dec b
Na2:	inc	b
	sub c
	jr	nc,Na2
	add	a,c			
	push af			
	ld	a,b					
	call	dartPutTerm	
	pop af
	ret

	;
	; Write a 16 bit number in hl to the term
	; 
putTerm16:
	push af
	push de
	push bc
	push hl
	ld a,h
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,l
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	pop hl
	pop bc
	pop de
	pop af
	ret

putCRLF:
	push af
	ld a,0x0a
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	pop af
	ret


hereMsg: defm " Here!"
	defb	0x0a, 0x0d, 0

here:
	call putTerm16
	push hl
	ld hl,hereMsg
	call dartPutString
	pop hl
	ret
 








____________________________

 

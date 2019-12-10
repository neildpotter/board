	;
	; Convert the relative address to absolute addresses to make code relocatable
	; DE = relative address of conversion table
	; HL = address module
	;
blockRelocate:
	push hl
	add hl,de					; absolute address of table
	ex de,hl
	pop hl
blockRelocateLoop:
	ex de,hl						; table to HL
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld a,b
	or c							; end of table?
	jr z,blockRelocateEnd
	ex de,hl						; block address to hl
	push hl
	add hl,bc					; absolute address of correction
	push hl
	pop bc						; address of item to fix
	pop hl
	ld a,(bc)						; add the base address to the low byte
	add a,l
	ld (bc),a						
	inc bc
	ld a,(bc)						; high byte
	adc a,h
	ld (bc),a
	jr blockRelocateLoop
blockRelocateEnd:
	ret





















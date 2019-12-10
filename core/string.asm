;
; String utilities
;

; compare null terminated strings at HL and DE return flags

strcmp:
	push hl
	push de
	push bc
	ld c,a
	push bc
strcmp1:
	ld a,(de)
	cp (hl)
	jr nz,strcmp2
	inc de
	inc hl
	or a
	jr nz,strcmp1
strcmp2:
	pop bc
	ld a,c					; restore A but not F
	pop bc
	pop de
	pop hl
	ret						; flags - nz - different, z - same
;
; copy null terminated string from HL to DE
;
strcpy:
	push hl
	push de
	push af
strcpy1:
	ld a,(hl)
	ld (de),a
	inc hl
	inc de
	or a
	jr nz,strcpy1
	pop af
	pop de
	pop hl
	ret

					; return the length of a string 
					; HL = string
					; BC - length
strlen:
	push hl
	push af
	ld bc,0
strlen2:
	ld a,(hl)
	or a
	jr z,strlen3
	inc hl
	inc bc				; count
	jr strlen2
strlen3:
	pop af
	pop hl
	ret










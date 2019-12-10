	;
	; Buffer.asm
	; Initialize a buffer
	; Write a character to the buffer
	; Read a character from the bufffer
	;

	;
	; Initialize a buffer
	; A = size. Address of buffer in HL
buffInit:

	ld l, a
	ld h, 0
	inc hl
	inc hl
	inc hl			; 3 bytes for head, tail and size respectively
	call malloc		; allocate memory size hl

	push hl			; location of the buffer
	ld (hl), 0			; initialize head
	inc hl
	ld (hl), 0			; initialize tail
	inc hl
	ld (hl), a			; buffer size
	pop hl			; return the address of the structure
	ret

	;
	; Write a byte to the buffer
	; hl = structure address, a = byte to write
	;
buffWrite:
	push af
	push bc
	push hl
	push de
	ld d,a			; Keep the byte to write
	ld c, (hl)			; head
	inc hl
	ld b, (hl)			; tail
	inc hl
	ld e, (hl)			; size
	inc hl			; now points to the first byte of the buffer
	;
	; Check if the buffer is full. Its full if advancing the head one would correspond to the tail
	;
	ld a,c
	inc a			; try and see
	cp e			; Wraps beyond the end?
	jr nz, writeNoWrap
	ld a, 0			; wrap
writeNoWrap:
	sub b			; head = tail?
	jr z, writeBufferFull
	;
	; Add the byte to the buffer and advance the pointers
	;
	ld b, 0			; now bc = head
	add hl, bc
	ld (hl), d			; the byte to write
	inc c
	ld a, c
	cp e			; wrap?
	jr nz, writeNoWrap2
	ld c, 0
writeNoWrap2:
writeBufferFull:
	pop de
	pop hl			; structure pointer
	ld (hl), c			; update the head
	pop bc
	pop af
	ret

	;
	; read a byte from the buffer
	; hl = structure address, returned a = byte read
	;

buffRead:
	push bc
	push hl
	push de
	ld b, (hl)			; head
	inc hl
	ld c, (hl)			; tail
	inc hl
	ld e, (hl)			; size
	inc hl			; Now points to first byte in buffer
	;
	; Check if there is anything in the buffer
	;
	ld a, b
	sub c			; if the buffer is empty, return 0
	jr z, readBufferEmpty
	;
	; get the byte from the tail
	;
	ld b, 0			; now bc is the tail
	add hl, bc
	ld b, (hl)
	;
	; Update the tail so it points to the next byte
	;
	inc c
	ld a, c
	cp e			; wrap?
	jr nz, readNoWrap
	ld c, 0
readNoWrap:
	ld a, b
readBufferEmpty:
	pop de
	pop hl
	inc hl
	ld (hl), c			; update the tail
	dec hl
	pop bc
	ret




buffHalt:
	halt
	jr buffHalt



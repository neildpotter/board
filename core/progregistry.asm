;
; program registery
;
; a linked list of programs and their starting addresses
;
;  Linked list pointer
;  |                          Start address of program
;  |                          |
; [][][name][page][addr][help][package 10]
;      |           |                    |
;      |           |                   20 bytes of help
;      |          type 1 = embedded, 2 = packaged
;      verb 8 bytes null terminated
;      

progSizeEmbedded	equ 34 		; size of an embedded entry (code is in core)
progSizePackaged 	equ 44		; size of an packaged entry (code is in a package)

progEmbedded		equ 1		; types
progPackaged		equ 2
	;
	; add a program to the program registry
	; HL - verb, DE - routine, BC - help text, A -type - 1 = Embedded, 2 = Packaged, IX - package name
	; 
progRegister:
	push bc
	push de
	push hl	
	push af
	call progFindItem				; see if its already registered
	jr nc,progReg0
	pop af
	ex de,hl
	jr progUpdateReg
	;
	; Skip to the end of the linked list
	;
progReg0:
	ld de,progRegl
	push iy
	pop hl
	add hl,de					; HL is ** link
progReg1:
	ld e,(hl)
	inc hl
	ld d,(hl)						; DE is *item
	dec hl
	ld a,e
	or d
	ex de,hl
	jr nz,progReg1
	;
	; Add a new item at the end.
	;
	pop af
	ld hl,progSizeEmbedded
	cp progEmbedded
	jr z,progReg2
	ld hl,progSizePackaged
progReg2:
	call mallocBlock
	ex de,hl
	ld (hl),e						; link it to previous or root
	inc hl
	ld (hl),d
progUpdateReg:
	inc de
	inc de
	pop hl						; copy in the name
	call strcpy	; jump in here to amend an entry
	ld hl,8
	add hl,de					; points to type
	ld (hl),a
	inc hl
	pop de						; start address
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	pop de						; help text
	ex de,hl
	push de
	call strcpy
	pop de
	cp progEmbedded
	jr z,progReg3
	ld hl,20						; bytes of help
	add hl,de
	ex de,hl
	push ix
	pop hl
	call strcpy					; package name
progReg3:
	ret

	;
	; remove a program from the registry
	; HL - name of program to remove
	;
progRemove:
	ex de,hl						; name to remove
	ld bc,progRegl
	push iy
	pop hl
	add hl,bc					; HL is ** link
progRemove1:
	ld c,(hl)
	inc hl
	ld b,(hl)
	dec hl
	ld a,b						; end of linked list?
	or c
	jr z,progRemoveEnd
	push hl						; previous entry
	push bc
	push bc						; this entry
	pop hl
	inc hl
	inc hl
	call strcmp					; match the name?
	pop hl						; this entry
	pop bc						; previous entry
	jr nz,progRemove1			; go to the next one
	push hl						; points to the current item
	;
	; unlink the current item
	;
	ld a,(hl)						; link to next item - low
	ld (bc),a						; pointer to previous link
	inc bc
	inc hl
	ld a,(hl)						; link to next item - high
	ld (bc),a						; pointer to previous link	
	pop hl
	call free						; free the item
progRemoveEnd:
	ret


	;
	; find a program by name and return its address and ram page
	; HL - name of program to find, HL - start addr, B - type, DE package
	;
progFind:
	call progFindItem
	jr nc,progNotFound
	ld de,10
	add hl,de
	ld b,(hl)						; type
	inc hl
	ld e,(hl)						; start address
	inc hl
	ld d,(hl)
	ex de,hl
	ld a,b
	cp progEmbedded
	ret z						; 
	push hl
	ld hl,21						; to package name
	add hl,de
	ex de,hl
	pop hl	
	ret

progNotFound:
	ld b,0
	ld hl,0
	ret


	; find a program by name and return the item address
	; 
progFindItem:
	ex de,hl
	ld h,(iy+progRegh)
	ld l,(iy+progRegl)
progFind1:
	ld a,l						; end of linked list?
	or h
	jr z,progFindNot
	inc hl
	inc hl
	call strcmp					; match the name?
	jr z,progFindFound
	push de
	dec hl
	ld d,(hl)
	dec hl
	ld e,(hl)
	ex de,hl
	pop de
	jr progFind1
progFindNot:
	ret

progFindFound:
	dec hl
	dec hl
	scf
	ret


	;
	;  List the programs loaded in the registry
	;
progList:
	ld h,(iy+progRegh)
	ld l,(iy+progRegl)
progList1:
	ld a,l						; end of linked list?
	or h
	jr z,progListEnd
	push hl
	inc hl
	inc hl
	call dartPutString				; print the name
	ld a,9
	call dartPutTerm
	pop hl
	push hl
	ld de,13						; offset to help text
	add hl,de
	call dartPutString				; print the help text
	ld a,0x0a
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	pop hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	jr progList1
progListEnd:
	ret





















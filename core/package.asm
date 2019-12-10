	;
	; package - install, uninstall and display installed packages

	;                    0       1        2            3              4         5                15       16
	; package <LLl><LLh><bufferl><bufferh><type><name10><fileL><fileH>
packageLen equ	17						; bytes
packageReadBuffer	equ		20				; enough to get the start of the file and read the name

packageTransient equ 2				; drop package
packagePermanent equ 1				; keep package in memory

packageInit:
	ld (iy+packageRootl),0				; initialize the link list
	ld (iy+packageRooth),0
	ret

	; Create a new named package and return it
	; HL - file path, C = mode - 1 - permanent, 2 - transient
	; returns C = success, HL = package 
packageNew:
	push hl
	push bc
	ld b,0						; read the file and get the name from it
	call fileOpen
	jp nc,packageFailed2			; file not found
	ld hl,packageReadBuffer
	call malloc
	ld b,packageReadBuffer
	call fileRead
	jp nc,packageFailed2			; read failed
	call fileClose
	push hl
	inc hl
	inc hl
	inc hl
	inc hl						; advance to package name
	push hl

	call packageFind
	jp c,packageFailed4			; package already exists by that name

	push iy						; create a new package on the end of the linked list
	pop hl
	ld de,packageRootl					; find the end of the package linked list
	add hl,de
packageNewLoop:
	ld e,(hl)
	inc hl
	ld d,(hl)
	dec hl
	ex de,hl
	ld a,h
	or l
	jr nz,packageNewLoop				; find the end of the linked list

	ld hl,packageLen 						; make a new package object
	call mallocBlock
	ex de,hl
	ld (hl),e								; add it to the end of the linked list
	inc hl
	ld (hl),d		
	inc de
	inc de
	inc de
	inc de								; to type
	inc de								; to package name
	pop hl								; package name
	call strcpy
	pop hl
	call free								; free the 20 byte buffer
	dec de								; to type
	pop bc								; type
	ld a,c
	ld (de),a								; type
	ld hl,11								; length of package name
	add hl,de							; hl now to file name
	ex de,hl
	pop hl								; filename
	push de								; package object
	call strlen							; length of filename to BC
	push hl								; filename
	push bc
	pop hl								; length
	inc hl								; one more for srting 0
	call mallocBlock						; buffer for the filename
	pop de								; filename
	ex de,hl
	call strcpy							; copy the filename to the buffer
	pop hl								; package object
	ld (hl),e
	inc hl
	ld (hl),d								; link in the filename buffer
	ld de,16
	sbc hl,de							; rewind back to package object start
	scf									; success
	ret
			; load up the package object into memory
			; HL = package object
packageLoad:
	push hl
	inc hl
	inc hl
	ld a,(hl)
	inc hl
	or (hl)								; is it already loaded?
	jr nz,packageLoadDone
	pop hl								; package
	push hl
	ld de,15								; file name buffer
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)								; de has the filename
	ex de,hl
	call fileSize							; get the file size
	jp nc,packageFailed1
	ex de,hl
	push bc
	pop hl
	call mallocBlock						; the buffer for the package itself

	ex de,hl
	call packageReadFromFile				; read the file HL to the buffer DE size BC
	jp nc,packageFailed1					; TODO - free malloc'd block
	pop hl								; package
	push hl
	inc hl
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d								; attached the buffer
	ex de,hl								; initialize the package
	ld a,(hl)
	cp 0x18
	jr nz,packageLoadDone
	ld de,packageLoadDone
	push de
	jp (hl)								; call routine 0
packageLoadDone:
	pop hl								; package
	scf
	ret

			; unload a package - un-init and drop its buffer
			; HL = package
packageUnload:
	push hl
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld a,e
	or d
	jr z,packageUnloadDone				; there is no buffer
	ex de,hl								; the buffer
	call free
	pop hl								; package
	push hl
	inc hl
	inc hl
	ld (hl),0								; null the buffer entry in the package
	inc hl								; so we know its unloaded
	ld (hl),0
packageUnloadDone:
	pop hl								; package
	scf
	ret
					; uninitialize the package
					; HL - loaded package
packageUninit:
	push hl					; package
	inc hl
	inc hl
	ld e,(hl)					; get buffer
	inc hl
	ld d,(hl)
	ld a,e
	or d
	jr z,packageUninitRet		; it isn't loaded	
	ex de,hl
	inc hl
	inc hl					; call the packages uninit
	ld a,(hl)
	cp 0x18					; should be a jr
	jr nz,packageUninitRet
	ld de,packageUninitRet
	push de
	jp (hl)
packageUninitRet:
	pop hl					; package
	ret

	; destroy a package
	; hl = package
packageDestroy:
	push hl
	pop bc
	push iy
	pop hl
	ld de,packageRootl
	add hl,de
packageDestroyLoop:
	ld e,(hl)
	inc hl
	ld d,(hl)
	dec hl
	ld a,e
	or d
	jr z,packageDestroyEnd					; end of linked list
	push hl									; last item
	push de									; next item
	ex de,hl									; hl = current pack
	sbc hl,bc
	pop hl
	pop de									; next item
	jr nz,packageDestroyLoop					; no match
	ld a,(hl)									; remove item from linked list
	ld (de),a
	inc de
	inc hl
	ld a,(hl)
	ld (de),a
	dec hl
											; uninit the package	
	call packageLoad
	call packageUninit
	call packageUnload						; unload it
	push hl
	ld de,15									; free the filename buffer				
	add hl,de
	ld e,(hl)					
	inc hl
	ld d,(hl)
	ex de,hl
	call free
	pop hl									; package
	call free									; free the package itself
	scf
packageDestroyEnd:
	ret

			; Return the buffer for a package
			; HL - package
			; DE - buffer
packageBuffer:
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	dec hl
	dec hl
	dec hl
	ret

			; Return the package type in A
			; HL = package
packageType:
	push hl
	push de
	ld de,4
	add hl,de
	ld a,(hl)
	pop de
	pop hl
	ret


			; read the package from the file into the buffer
			;  file HL to the buffer DE size BC
packageReadFromFile:
	push hl
	push de
	push bc						; size
	ld b,0						; open for read
	call fileOpen
	jr nc,packageFailed3
	pop bc						; size
	ex de,hl
packageReadLoop:				; hl = current buffer position
	ld a,b						; bc = bytes remaining to be loaded
	or c
	jr z,packageReadDone		; if its done
	ld a,b
	or a
	jr nz,packageRead1
	ld a,c						; if only c bytes remain, just ask for that
	jr packageRead2
packageRead1:
	ld a,255						; otherwise get the maximum
packageRead2:
	push bc
	ld b,a						; number of bytes to read
	call fileRead
	jr nc,packageFailed3			; read failed
	ld e,b						; number of bytes read
	ld d,0
	add hl,de					; advance the buffer pointer
	pop bc
	ld a,c
	sub e						; subtract the number of bytes read
	ld c,a	
	jr nc,packageRead3
	dec b
packageRead3	
	jr packageReadLoop
packageReadDone:
	call fileClose
	pop de
	pop hl
	scf
	ret	

packageFailed4:
	pop hl
packageFailed3:
	pop hl
packageFailed2:
	pop hl
packageFailed1:	
	pop hl
packageFailed:
	and a						; failed
	ret



packageHeaderMsg defm "Name	Pack	Buf	File"
	defb 0x0a,0x0d,0

	; list the packages on the screen
packageList:
	ld hl,packageHeaderMsg
	call dartPutString
	push iy
	pop hl
	ld de,packageRootl
	add hl,de
packageListLoop:
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld a,e
	or d
	ret z									; end of linked list
	push de									; current package
	ex de,hl
	inc hl
	inc hl
	inc hl
	inc hl
	call dartPutString							; name
	ld a,0x09
	call dartPutTerm
	pop hl
	push hl
	call putTerm16							; address
	ld a,0x09
	call dartPutTerm	
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	call putTerm16							; buffer
	ld a,0x09
	call dartPutTerm	
	ld hl,12									; bufferh -> file
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	call dartPutString
	call putCRLF
	pop hl
	jr packageListLoop

	; Find a package named HL
	; HL - null terminated name
	; returns C = success, HL = package
packageFind:
	push de
	push hl
	push iy
	pop hl
	ld de,packageRootl
	add hl,de							; start of linked list
packageFindLoop:
	ld e,(hl)
	inc hl
	ld d,(hl)								; next item
	ld a,d
	or e
	jr z,packageFindEnd
	pop hl								; name we're looking for
	push hl
	push de
	inc de
	inc de								; header
	inc de
	inc de								; buffer
	inc de
	call strcmp							; this our package?
	pop hl
	jr nz,packageFindLoop	
	scf									; success
packageFindEnd:
	pop de								; discard the name
	pop de
	ret










		;
		; Block file 
		; Receive a block of data over the serial port and write to memory
		;
blockMessage: 
	defm " Bytes received"
	defb 0

blockInit:
	ld hl, 40
	call malloc
	ld (iy+blockStarth),h
	ld (iy+blockStartl),l
	ret

blockReceive:
	ld bc,0
	call blockReceive0
	push bc
	pop hl
							; Print how many bytes were received
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
	ld hl,blockMessage
	rst 0x18
	ld a,0x0D
	RST 0x10
	ld a,0x0A
	RST 0x10
	ret

blockReceive0
		;
		; Receive two hex characters and a space, write to the block
		; Exit on error
		;
	ld h,(iy+blockStarth)
	ld l,(iy+blockStartl)
	ld hl,blockRAMstart 			; write to the bottom of the current ram
blockReceive1:
	RST 0x08
	or a
	jr z,blockReceive1
	cp 'Z'						; Terminator	
	ret z
	ld d,a
blockReceive2:
	RST 0x08
	or a
	jr z,blockReceive2
	cp 'Z'						; Terminator	
	ret z
	ld e,a	
	call blockHexToNum
	ld (hl),a						; store the byte
	inc bc
	inc hl
blockReceive3:
	RST 0x08
	or a
	jr z,blockReceive3
	cp 'Z'						; Terminator	
	ret z
	cp ' '						; must be a space or its an error
	ret nz
	jr blockReceive1				; next byte
	;
	; Dump the block to debug
	;
blockDebug:
	ld h,(iy+blockStarth)
	ld l,(iy+blockStartl)
	ld hl,blockRamStart			; wrote it here
	call debug
	ret

blockExecute:
	jp blockRamStart

	;
	; Convert two hex characters in D and E to their value in A
	;
blockHexToNum:
	 ld   a,d
         call Hex1
         add  a,a
         add  a,a
         add  a,a
         add  a,a
         ld   d,a
         ld   a,e
         call Hex1
         or   d
         ret

Hex1:
	 sub 48
         cp   10
         ret  c
         sub 7
         ret


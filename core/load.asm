		;
		; Load file from serial transfer 
		; Receive a block of data over the serial port and write to file
		;

loadFailedMsg: 
	defm "Load Failed"
	defb 0x0a, 0x0d, 0

loadBufSize equ 20

	; load
	; HL - filename
	; C = success
loadSerialToFile:
	push hl					; file name
	ld b,1					; write and not amend
	call fileOpen
	jr nc,loadFailed
	call loadInit				; process the header
	jr z,loadFailed			
	ld hl,loadBufSize			; make a temporary buffer
	call malloc
loadLoop:
	push hl
	ld b,loadBufSize
	ld c,0
loadLoop1:
	call loadNextByte			; receve byte to A
	jr z,loadDone
	ld (hl),a					
	inc hl
	inc c					; count how many bytes in buffer
	djnz loadLoop1			; fill up the little buffer
	ld b,c
	pop hl
	push hl
	call fileWrite
	pop hl
	jr nc,loadFailed
	jr loadLoop

loadDone:
	ld b,c
	pop hl
	push hl
	call fileWrite				; end of transmission - write the last bytes
	jr nc,loadFailed1
	call fileClose
	pop hl
	call free					; free the little buffer
	pop hl					; file name
	push hl
	call fileSize
	jr nc,loadFailed
	push bc
	pop hl
	call putTerm16			; print number of bytes read
	ld hl, loadSuccessMsg
	call dartPutString
	pop hl
	call dartPutString
	call putCRLF
	ret

loadSuccessMsg:	defm " bytes load to "
	defb 0


loadFailed1:
	pop hl
loadFailed
	pop hl	
	call loadWaitForEnd
	ld hl,loadFailedMsg
	call dartPutString
	pop hl
	ret

		; Process the header
		; 
		; Receive L followed by four hex characters and a space header
		; bc - size
		; NZ success, Z error
		;
loadInit:
	call loadNextChar
	ret z
	cp 'L'						; Header character
	jr nz,loadInit
	call loadNextByte
	ret z
	ld b,a
	call loadNextByte
	ret z
	ld c,a
	ret							; bc = size

loadNextByte:
	call loadNextChar
	ret z
	ld d,a
	call loadNextChar
	ret z
	ld e,a
	call loadNextChar
	ret z
	cp ' '						; must be  a space or we're out of sync
	jr nz,loadNextByte2
	call loadHexToNum
	inc e						; clear the z flag
	ret
loadNextByte2:
	ld a,0
	or a
	ret							; error - return zero

loadWaitForEnd:					; wait for the end of the stream
	call loadNextChar
	jr nz,loadWaitForEnd
	ret

loadNextChar:
	call dartGetKey
	or a
	jr z,loadNextChar				; wait for next character
	cp 'Z'						; terminator?
	ret

	;
	; Convert two hex characters in D and E to their value in A
	;
loadHexToNum:
	 ld   a,d
         call loadHex1
         add  a,a
         add  a,a
         add  a,a
         add  a,a
         ld   d,a
         ld   a,e
         call loadHex1
         or   d
         ret

loadHex1:
	 sub 48
         cp   10
         ret  c
         sub 7
         ret




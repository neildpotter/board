; ramdisk
; present memory as blocks
; need to make this thread safe

ramDiskStart equ 0x8000
ramBlockSize equ 128		; bytes per block
ramNumBlocks equ 256		; 128 blocks in a chip

ramBlockHOutOfRange equ 32	; d block number < 32
ramBlockLOutOfRange equ 8	; e block number <

rdTestName:	defm "R2"
		defb 0
rdTestString: defm "Hello world "
		defb 0
rdTestString2: defm "Goodbye "
		defb 0
ramRootBlockl equ 1				; root block
ramRootBlockh equ 0

firstFileName defm "/baby/cakes/test"
	defb 0

rdTest:				; hl is block number, s is operation
	ld a,c
	cp 1					; 1 = create device
	jr nz,rdTest1

	ld hl,firstFileName
	ld b,1					; open for write
	call fileOpen
	ld hl,rdTestString
	ld b,12					; 12 bytes
	call fileWrite
	call fileClose
	ret

rdTest1:
	cp 2					; 2 = format device and create a root directory
	jr nz,rdTest2
	ld hl,firstFileName
	ld b,1					; open for write
	call fileOpen
	ld hl,rdTestString2
	ld b,8					; 9 bytes
	call fileWrite
	call fileClose
	ret
rdTest2:
	cp 3					; 3 = size
	jr nz,rdTest3
	ld hl,firstFileName
	call fileSize
	push bc
	pop hl
	call putTerm16
	call putCRLF
	
	ret
rdTest3:
	cp 4					; 4 = read
	jr nz,rdTest4

	ret

rdTest4:

	ret


	; initialize the ramDisk
	; A = RAM page number
rdInit:
	call devNew

	ld (ix+devData1), a			; ram page
	add a,'0'
	ld (ix+devName0), 'R'			; device name
	ld (ix+devName1), a
	ld (ix+devName2), 0			; string terminator	
	ld (ix+devDefaultBlockl),ramRootBlockl 
	ld (ix+devDefaultBlockh),ramRootBlockh
	ld hl, rdRead
	ld (ix+devReadl),l				; object oriented stuff
	ld (ix+devReadh),h
	ld hl, rdWrite
	ld (ix+devWritel),l			
	ld (ix+devWriteh),h
	ld hl, rdDelete
	ld (ix+devDeletel),l			
	ld (ix+devDeleteh),h
	ld hl, rdCreate
	ld (ix+devCreatel),l			
	ld (ix+devCreateh),h
	ld hl, rdFormat
	ld (ix+devFormatl),l			
	ld (ix+devFormath),h
	scf							; Success
	ret

	; read block DE to buffer HL
	; IX pointer to device
rdRead:
	push hl
	push de
	push bc
	push hl
	call rdOffset					; get the address of the block
	jr nc,rdReadErr
	pop de						; hl offset, de buffer
	ld b,ramBlockSize
	ld c,(iy+ramSelected)
rdRead1
	push bc
	ld a,(ix+devData1)
	call memSelect				; source memory
	ld b,(hl)
	ld a,c
	call memSelect				; destination memory
	ld a,b
	ld (de),a	
	pop bc
	inc hl
	inc de
	djnz rdRead1
	pop bc
	pop de
	pop hl
	scf							; success
	ret

rdReadErr:
	ld a,errFileRead
	call errPrint
	pop hl
	pop bc
	pop de
	pop hl						; Fail
	ret

	; write block DE from buffer HL
	; IX pointer to device
rdWrite:
	push hl
	push de
	push bc
	push hl
	call rdOffset					; get the address of the block
	jr nc,rdWriteErr
	pop de						; hl offset, de buffer
	ld b,ramBlockSize
	ld c,(iy+ramSelected)
rdWrite1
	push bc
	ld a,(de)						; get the byte from source memory buffer
	ld b,a	
	ld a,(ix+devData1)
	call memSelect				; select the ram disk
	ld (hl),b						; write the byte to ram disk buffer
	ld a,c
	call memSelect				; switch back to source memory 
	pop bc
	inc hl
	inc de
	djnz rdWrite1
	pop bc
	pop de
	pop hl
	scf							; success
	ret

rdWriteErr:
	ld a,errFileWrite
	call errPrint
	pop hl
	pop bc
	pop de
	pop hl
	ret

rdOffset:
	ld a,d						; check block numbers are within bounds
	cp ramBlockHOutOfRange		; d must be 0 - 31
	ld a,errFileBadBlock
	jr nc,rdOffsetErr
	ld a,e
	cp ramBlockLOutOfRange		; e must be 0 - 7
	ld a,errFileBadBlock
	jr nc,rdOffsetErr

	ld c,(iy+ramSelected)
	ld a,(ix+devData1)
	call memSelect				; source memory
	push bc
	ld hl,ramDiskStart			; check block is allocated in the table
	ld c,d
	ld b,0
	add hl,bc					; offset to allocation table
	pop bc
	ld b,e						; lower block number
	inc b
	ld a,0
	scf
rdOffset0:						; make the bit mask with a one in position
	rla
	djnz rdOffset0
	and (hl)						; is the block allocated?
	push af
	ld a,c
	call memSelect				; source memory
	pop af
	ld a,errFileNoBlock
	jr z,rdOffsetErr1				; no its not allocated - so its an error

	ld hl,ramDiskStart			; compute the block offset
	ld bc,ramBlockSize*8			; d implies this offset
rdOffset1:
	ld a,d
	cp 0
	jr z,rdOffset2
	add hl,bc
	dec d
	jr rdOffset1
rdOffset2:
	ld bc,ramBlockSize 			; e implies this offset
rdOffset3:
	ld a,e
	cp 0
	jr z,rdOffset4
	add hl,bc
	dec e
	jr rdOffset3
rdOffset4:
	scf							; success
	ret
rdOffsetErr:
	call errPrint
	and a						; error
	ret

rdOffsetErr1:
	call errPrint
	and a						; error
	ret
	; delete block
	; IX pointer to device
	; DE block number
rdDelete:
	ld hl,ramDiskStart
	ld a,d
	cp ramBlockHOutOfRange		; d must be 0 - 31
	ld a,errFileBadBlock
	jr nc,rdOffsetErr
	ld a,e
	cp ramBlockLOutOfRange		; e must be 0 - 7
	ld a,errFileBadBlock
	jr nc,rdOffsetErr
	ld c,d
	ld b,0
	add hl,bc					; offset to allocation table
	inc e
	ld a,0xff
rdDelete1:						; make the bit mask with a zero in position
	rla
	dec e
	jr nz,rdDelete1
	ld e,a
	ld c,(iy+ramSelected)			; update the allocation table
	ld a,(ix+devData1)
	call memSelect
	ld d,(hl)
	ld a,e
	and (hl)						; reset the bit in the map to free the block
	ld (hl),a
	cp d						; was it deallocated already?
	push af
	ld a,c
	call memSelect				; not thread safe
	pop af
	ld a,errFileNoBlock
	jr z,rdOffsetErr1				; error - it was already deleted
	scf							; success
	ret

	; allocate and return an empty block
	; IX pointer to device
rdCreate:
	ld hl,ramDiskStart
	ld c,(iy+ramSelected)
	ld a,(ix+Devdata1)
	call memSelect				; select this device's chip
	ld b,ramNumBlocks/8			; size of allocation table
	ld de,0						; compute block number
rdCreate1:
	ld a,(hl)
	cp 0xff						; all blocks full?
	jr z,rdCreateNext
	ld b,8
rsCreate2:							; find the first 0 bit = empty block
	rra
	jr nc,rdCreateEmpty
	inc e						; e is the sub-block
	djnz rsCreate2
rdCreateEmpty:
	ld a,d
	cp ramBlockHOutOfRange		; d must be 0 - 31
	jr nc,rdCreateErr
	ld a,e
	cp ramBlockLOutOfRange		; e must be 0 - 7
	jr nc,rdCreateErr	
	push de						; completed block number
	inc e
	ld a,0
	scf
rdCreateEmpty1					; create the bit mask
	rla
	dec e
	jr nz,rdCreateEmpty1
	or (hl)						; set the bit indicating the block is used
	ld (hl),a
	pop de						; block de reserved
	ld a,c
	call memSelect				; put it back to original ram
	scf
	ret
rdCreateNext:
	inc hl
	inc d
	djnz rdCreate1
	ld a,c
	call memSelect				; put it back to original ram
	and a						; Failed
	ret							; de = 0 - no block available

rdCreateErr:
	ld a,c
	call memSelect				; put it back to original ram
	ld a,errFileFull
	call errPrint
	and a						; failed
	ret							; de = 0 - no block available


	; format the ram disk.
	; clear the allocation table in the first block
	; IX pointer to device
rdFormat:
	ld hl,ramDiskStart
	ld b,ramBlockSize
	ld c,(iy+ramSelected)
	ld a,(ix+DevData1)
	call memSelect				; select this device's chip
	
rdFormat1:
	ld (hl),0
	inc hl
	djnz rdFormat1
	ld a,1
	ld (ramDiskStart),a			; reserve block 0 for the allocation table
	ld a,c
	call memSelect				; put it back to original ram
	scf							; success
	ret









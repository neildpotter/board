;malloc
;free

;    length of this block
;     |     address returned to user /freed
;     |     |
;     [][][]data[][][]data[][][]data[][][]
;       |  |                                      |
;	|  proc ID                          |                       end is 00
;	| bit 7 - 0 - this block is active

	 
;	
	 
mallocInit:
	ld h,(iy+heaph)
	ld l,(iy+heapl)
	ld a,0
	ld (hl),0
	inc hl
	ld (hl),0				; write the end of memory header
	inc hl
	ld (hl),0
	ld (iy+heapSizel),0		; total size allocate to heap
	ld (iy+heapSizeh),0
	ld (iy+memTopl),l			; furtherest reaches of memory
	ld (iy+memToph),h
	ret


	;
	; hl bytes required, hl return address of zero;d memory
	; belonging to process 0 so it doesn't automatically free
	;
mallocBlock
	call malloc
	dec hl
	ld (hl),0
	inc hl
	ret
	;
	;  hl bytes required, hl return address of zero'd memory
	; belonging to the current process so it frees when the process exits
	; 
malloc:				
	push af
	push bc
	push de
	res 7,h				; signalling bit
	bit 0,l
	jr z,malloc1
	inc hl				; make sure block is even sized to simplify the headers
malloc1:
	ex de,hl
malloc2:
	;
	; add to the size allocated
	;
	ld l,(iy+heapSizel)
	ld h,(iy+heapSizeh)
	add hl,de
	ld (iy+heapSizel),l		; total size allocate to heap
	ld (iy+heapSizeh),h
	;
	; find an open block or stick it on the end
	;
	ld h,(iy+heaph)
	ld l,(iy+heapl)
	ld bc,0				; don't skip first block
mallocnextBlock:
	add hl,bc			; skip to next block
	ld c,(hl)
	inc hl
	ld b,(hl)			; bc = length of this block
	inc hl
	inc hl
	ld a,b
	or c
	jr z,mallocaddBlockToEnd	; found the end of the allocated space
	;
	; check if the current block is in use and big enough
	;
	bit 7,b				; 0 = in use
	jr z,mallocnextBlock
	res 7,b				; for size comp
	;
	; see if this freed block is big enough for the request
	;
	push hl				; pointer to this block's start
    	push bc				; space available
	pop hl	
	sbc hl,de			; space - size available

	jr z,mallocjustFits		; asking for the exactly the same size
	jr c,mallocnotEnoughRoom	; required exceeds space available
	push de
	ld de,4				; margin
	sbc hl,de
	pop de
	jr nc, moreThanEnoughRoom	; space is much bigger, break it into two
	jr mallocjustFits			; space is just bigger - use it all

mallocnotEnoughRoom:			; consider next block
    	pop hl
	jr mallocnextBlock
	
mallocjustFits:
	pop hl
	push bc
	pop de				; allocate the size of the original block
	dec hl
	call procThisID		; write the process ID in the third byte
	ld (hl),a
	dec hl				; write the length desired block
	ld (hl),d
	dec hl
	ld (hl),e
	inc hl
	inc hl
	inc hl
	push hl
	jr mallocnextFill			; zero out the block and return its address
	;
	; The space available is much bigger than needed
	; split it into two blocks - used and remainder unused
	; 
moreThanEnoughRoom:
	pop hl
	dec hl
	call procThisID		; write the process ID in the third byte
	ld (hl),a
	dec hl				; write the length of the block
	ld (hl),d
	dec hl
	ld (hl),e
	inc hl
	inc hl	
	inc hl
	push hl				; start address of the user's memory
mallocfillIt:
	ld (hl),0			; zero fill
	inc hl
	dec bc				; original space
	dec de				; size we want
	ld a,d
	or e
	jr nz,mallocfillIt
	;
	; Create a new unused block for the remainder space
	;
	dec bc				; three bytes less for the extra header
	dec bc
	dec bc
	set 7,b				; bc is the remainder size. bit 7 indicates unused
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	ld (hl),0				; proc ID
	pop hl				; start address of user's memory
	pop de	
	pop bc
	pop af
	ret
   
mallocaddBlockToEnd:
	dec hl
	call procThisID		; write the process ID in the third byte
	ld (hl),a
	dec hl				; write the length of the block
	ld (hl),d
	dec hl
	ld (hl),e
	inc hl
	inc hl
	inc hl
	push hl				; save the return address
	inc de
	inc de				; write three more zeros as end markers   
	inc de
	;
	; adding on the end sets a new memTop, so record the high point
	;
	push hl
	add hl,de
	ld (iy+memTopl),l
	ld (iy+memToph),h
	pop hl

mallocnextFill:
	ld (hl),0			; zero it out
	inc hl
	dec de
	ld a,d
	or e
	jr nz,mallocnextFill

	pop hl				; start address of block
	pop de	
	pop bc
	pop af
	ret
	
	;
	; free - the block pointed by hl
	;
free:
	push de
	push bc
	push af
	ex de,hl
	ld h,(iy+heaph)
	ld l,(iy+heapl)
	ld bc,0
freenextBlock:
	add hl,bc			; advance to next block
	ld c,(hl)
	inc hl				; is this our block?
	ld b,(hl)
	inc hl
	inc hl
	ld a,b
	or c				; end of malloc blocks?
	jr z,freeendBlock
	push hl
	sbc hl,de			; will be zero if our block
	pop hl
	res 7,b
	jr nz,freenextBlock		; not ours
	dec hl
	ld (hl),0			; proc ID - not owned
	dec hl
	set 7,b
	ld (hl),b			; indicates not in use
	dec hl
	ld (hl),c
	res 7,b
	ld l,(iy+heapSizel)
	ld h,(iy+heapSizeh)
	sbc hl,bc
	ld (iy+heapSizel),l		; total size allocate to heap
	ld (iy+heapSizeh),h

freeConsolidateBlocks:
freeendBlock:				; cycle through entire space and consolidate free blocks

	ld h,(iy+heaph)
	ld l,(iy+heapl)
	ld de,0
freenextConsolidate:
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	inc hl
	ld a,e
	or d
	jr z,freeendConsolidation	; end of block found
	bit 7,d
	jr z,freenextConsolidate	; in use, so skip to the next one
	;
	; see if the next block is also free
	; if so, they can be joined as one free block
	;
	push hl
	res 7,d
	add hl,de
	ld c,(hl)
	inc hl
	ld b,(hl)
	pop hl
	ld a,b
	or c
	jr z,freeendBlockFree		; got a free block at the end of the list
	
	bit 7,b
	jr z,freenextConsolidate	; next one is in use, so skip
	;
	; two unused adjacent blocks - make them one
	;
	res 7,b
	ex de,hl
	add hl,bc				; total first + second + header
	inc hl
	inc hl
	inc hl
	set 7,h					; indicate unused
	ex de,hl
	dec hl	
	ld (hl),0					; proc ID
	dec hl					; step back over first header
	ld (hl),d				; and write in new length
	dec hl
	ld (hl),e
 ;	call debugRegisters
   	ld de,0					; consider this block again with the next
	jr freenextConsolidate
	
freeendBlockFree:				; last block is free, make this one the end
	dec hl
	ld (hl),0					; proc ID
	dec hl
	ld (hl),0					; pointer
	dec hl
	ld (hl),0
	ld de,0
	ld (iy+memTopl),l			; new end revises the maxium extent of heap
	ld (iy+memToph),h	
	jr freenextConsolidate
	
freeendConsolidation:
	pop af
	pop bc
	pop de
	ret
	

	;
	; Free process memory - free all blocks owned by process a
	;
freeProcessMemory:
	push de				; exit is through free block consolidation so need these
	push bc
	push af
	ld d,a				; process ID
	ld h,(iy+heaph)
	ld l,(iy+heapl)
	ld bc,0
freeProcBlock:
	add hl,bc				; advance to next block
	ld c,(hl)
	inc hl				
	ld b,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld a,b
	or c						; end of malloc blocks list?
	jr z,freeBlockEnd
	bit 7,b					; block already freed?
	res 7,b
	jr nz,freeProcBlock
	ld a,d					;  block in use...
	cp e
	jr nz,freeProcBlock		; but not our block
	;
	; Free this block by updating the header
	;
	dec hl
	ld (hl),0					; overwrite the process id
	dec hl
	set 7,(hl)				; mark as free
	inc hl
	inc hl
	push hl
	ld l,(iy+heapSizel)
	ld h,(iy+heapSizeh)
	sbc hl,bc
	ld (iy+heapSizel),l		; total size allocate to heap
	ld (iy+heapSizeh),h
	pop hl
	jr freeProcBlock			; keep going down the chain

freeBlockEnd
	jp freeConsolidateBlocks
	
memHeapHeader: defm "Addr	Size	Owner"
	defb	0x0a, 0x0d, 0

debugHeap:
	push hl
	push de
	push af
	ld hl,memHeapHeader
	call dartPutString
	ld h,(iy+heaph)
	ld l,(iy+heapl)
	ld de,0
debugHeapLoop:
	add hl,de
	
	;
	; detect breakage, don't just crash
	ld a,h
	cp 0x20
	jr nc,debugHeap1
	call debugRegisters
	jr debugHeapEnd
debugHeap1:
	push hl
	inc hl
	inc hl
	inc hl
	call putTerm16					; address of user memory
	pop hl
	ld a,9
	call dartPutTerm
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ex de,hl
	call putTerm16					; size
	ex de,hl
	ld a,9
	call dartPutTerm
	ld a,(hl)
	inc hl
	push de
	call toHex
	ld a,d
	call dartPutTerm					; owner
	ld a,e
	call dartPutTerm
	pop de
	ld a,0x0a
	call dartputTerm
	ld a,0x0d
	call dartputTerm
	res 7,d
	ld a,d
	or e
	jr nz,debugHeapLoop
debugHeapEnd:
	;call debugDelay
	pop af
	pop de
	pop hl
	ret	



	
	
	
	
	
	

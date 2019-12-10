		;
		; mem.asm
		; Control the memory select latch
		;



memLatch equ 0xF7			; Memory latch hardware address

memTop equ 0xFFFE			; Top of shared memory
memShared equ 0xE000		; Shared memory in slot 7 starts here
bootRamStart equ 0xC000
memSharedTop equ 0xfffe		; top of shared memory
memRAMstart equ 0x8000	; First byte of switchable RAM
blockRAMstart equ 0x8000
;
; IY Space
;
heaph		equ 0x00			; Address of next available mermory on the heap
heapl		equ 0x01
dartRooth 	equ 0x02			; storage for dart
dartRootl 	equ 0x03
pio1Rooth 	equ 0x04			; storage for left pio
pio1Rootl 	equ 0x05
pio2Rooth 	equ 0x06			; Storage for right pio
pio2Rootl 	equ 0x07
commonID	equ 0x08			; Common ID
blockStarth	equ 0x09
blockStartl	equ 0x0a


memInit:
	ld a, 7					; Default to slot 7
	call memSelect

	ld IY bootRamStart		; IY points to first 127 bytes of shared memory
	;
	ld hl, bootRamStart		; Start of malloc memory
	ld bc, 128				; Start of malloc memory
	add hl,bc
	ld (IY+heaph),h
	ld (iy+heapl),l
	ld a,'Q'
	ld (iy+commonID),a

	ret


	;
	; Select memory chip 1 - 7 using the A register
	;
	; Bit 0 	Bit 1	Bit 2	RAM
	;   	0		0		0		7
	;	1		0		0		6
	;	0		1		0		5
	;	1		1		0		4
	;	0		0		1		3
	;	1		0		1		2
	;	0		1		1		1
	;	1		1		1		None
					; This table is incorrect because Data bus 0 actually connects to D3 on the latch
			;          None	1		2		3		4		5		6		7		8-error	9
;memPortMap: defb 0x0D,	0x07, 	0x06,	0x04,	0x03,	0x02,	0x01,	0x00,	0x50	0xA0

memPortMap:  defb  0x00,	0x01,	0x04,	0x07,	0x08,	0x09,	0x0E,	0x0F
memSelect:
	ret
	PUSH hl
	PUSH bc
	ld b,0
	ld c, a
	ld hl, memPortMap		
	add hl, bc			; index into the port map
	ld a, (hl)
	out (memLatch), a

	POP BC
	POP HL
	ret

memSlot: 
	defm "Slot "
	defb 0
memEmpty: 
	defm "Empty"
	defb 0
memBytes: 
	defm "Bytes Free"
	defb 0
	;
	; Test the memory 
	; Test each slot and report on the number of bytes free
	;
memTest:

	ld b,2					; Start with slot 1	
	;
	; Test shared memory
	;
memTestNextSlot:


	ld hl, memRAMstart 		; Test the ram from the start					
	ld de, memShared		; to the shared memory
	ld a, b					; of slot a
	call memTestSegment
		;
		; Write the output
		;
	push hl
	ld HL,memSlot
	rst 0x18
	ld a, b
	call toHex
	ld a,e
	rst 0x10
	ld a,':'
	rst 0x10
	pop hl
	ld a,h
	or l
	jr z, memSlotEmpty
	ld a,h
	call toHex
	ld a,d
	rst 0x10
	ld a,e
	rst 0x10
	ld a,l
	call toHex
	ld a,d
	rst 0x10
	ld a,e
	rst 0x10
	ld a, ' '
	rst 0x10
	ld hl,memBytes
	rst 0x18
	; For this slot, print the common byte
	di
	ld a,b
	call memSelect
	ld a,(iy+commonID)
	rst 0x10
	ld a,7
	call memSelect
	ei
	jr memSlotNotEmpty
memSlotEmpty:
	ld hl,memEmpty
	rst 0x18
memSlotNotEmpty:
	ld a,0x0D
	RST 0x10
	ld a,0x0A
	RST 0x10
	inc b	
	ld a,b
	cp 8
	jr nz, memTestNextSlot
	ret
	;
	; Test segment A from HL to DE. Return the number of bytes free in HL, or 0 if RAM is faulty
	;
memTestSegment:
	push bc
	push af
	push ix
	ld ix,0x0000
	ld b,a
memTestNextByte
	ld a,b
	di
	call memSelect			; Select the slot
							; Read and write to the address. Jump out if there is a fault
	ld a, 0x00				; Test 0
	ld (hl), a
	ld a,(hl)
	cp 0x00
	jr nz, memError	
	ld a, 0xaa				; Test aa
	ld (hl), a
	ld a,(hl)
	cp 0xaa
	jr nz, memError	
	ld a, 0x55				; Test 55
	ld (hl), a
	ld a,(hl)
	cp 0x55
	jr nz, memError	
	ld a, 0xff					; Test ff
	ld (hl), a
	ld a,(hl)
	cp 0xff
	jr nz, memError	
	ld a,7
	call memSelect			; Select the slot
	ei
	inc hl					; next byte
	inc ix					; number of bytes tested
	push hl
	sub a
	sbc hl,de				; DE byte limit
	ld a,h
	or l
	pop hl
	jr nz, memTestNextByte

memError:
	push ix
	pop hl					; number of bytes successfully tested
	ld a,7
	call memSelect			; Select slot 7	
	ei
	pop ix
	pop af
	pop bc
	ret

basicTest:
	;
	; Read a write from FFFF
	;
	ld d,0
	ld hl,0xe000
basicTest1
	ld c,0
	ld (hl),c
	ld a,(hl)
	cp c
	jr z, basicTest2
	ld d, 0xff						; Failed
basicTest2:
	ld c,0xff
	ld (hl),c
	ld a,(hl)
	cp c
	jr z, basicTest3
	ld d, 0xff						; Failed
basicTest3:
	ld c,0xaa
	ld (hl),c
	ld a,(hl)
	cp c
	jr z, basicTest4
	ld d, 0xff						; Failed
basicTest4:
	ld c,0x55
	ld (hl),c
	ld a,(hl)
	cp c
	jr z, basicTest5
	ld d,0xff						; Failed
basicTest5:
	inc hl
	ld a,h
	or l
	jr nz,basicTest1

;	rst 0x08						; Read from the key buffer
	cp 0
	jr z,basicTest55
;	rst 0x10						; if there is anything, write it to the terminal
basicTest55:
	;
	; Output status to the latch
	;
	ld a, d
	and 2						; bit 1 = error, success. Bit 0 - alternates to show life
	inc e
	bit 0,e
	jr z, basicTest6
	or 1
basicTest6:
;	out (memLatch), a

	;
	; Write a character to the DART to see if we get anything
	ld a, 'Z'
	out (dartAdata), a

	jr basicTest
	;
	; Fail
	;
basicError:
	ld a,0x00
;	out (memLatch), a
	jr basicTest

	;
	; Use up the CPU 
	; and blink the LED so we know its alive
	;
keepAlive:
	ld hl,0xffff
hlloop:
	ld d, 1
dloop:
	dec d
	ld a,d
	or 0
	jr nz,dloop
	dec hl
	ld a,h
	or l
	jr nz, hlloop

	ld a,1
;	out (memLatch),a
	ld hl,0xffff
hlloop2:
	ld d, 1
dloop2:
	dec d
	ld a,d
	or 0
	jr nz,dloop2
	dec hl
	ld a,h
	or l
	jr nz, hlloop2
	ld a,0
;	out (memLatch),a


	; Reflect characters received back to the terminal

KeepAliveNextKey:
	call dartGetKey
	cp 0
	jp z keepAlive
	cp 'T'							; B dumps the tx buffer
	jr nz,KeepAliveNextChar1

	ld h,(iy+dartRooth)				; address of our memory chunk
	ld l,(iy+dartRootl)
	push hl
	pop ix
	ld h,(ix+channelAtxBufh)			; address of the transmit buffer
	ld l,(ix+channelAtxBufl)
	call debug
	jr KeepAliveNextKey

KeepAliveNextChar1:
	cp 'R'
	jr nz,KeepAliveNextChar2
	ld h,(iy+dartRooth)				; address of our memory chunk
	ld l,(iy+dartRootl)
	push hl
	pop ix
	ld h,(ix+channelArxBufh)			; address of the transmit buffer
	ld l,(ix+channelArxBufl)
	call debug
	jp KeepAliveNextKey

KeepAliveNextChar2:
	cp 'M'
	jr nz,KeepAliveNextChar3

	call memTest
	jp KeepAliveNextKey

KeepAliveNextChar3:
	cp 'B'
	jr nz,KeepAliveNextChar4

	call blockInit
	call blockReceive
	jp KeepAliveNextKey

KeepAliveNextChar4:
	cp 'D'
	jr nz,KeepAliveNextChar5

	call blockDebug
	jp KeepAliveNextKey

KeepAliveNextChar5:
	cp 'X'
	jr nz,KeepAliveNextChar

	call blockExecute
	jp KeepAliveNextKey

KeepAliveNextChar:
	call dartPutTerm
	jp KeepAliveNextKey


	;
	; Malloc a block of memory
	; hl = size to allocate in bytes, hl returned = start address of block
	;
malloc:
	push bc
	push af
	ld b,(iy+heaph)			; Next available space on the heap
	ld c,(iy+heapl)

	push bc					; store the start address so we can return it
mallocLoop:
	ld a, 0	
	ld (bc), a					; write zeros into the space
	inc bc
	dec hl
	ld a, h
	or l
	jr nz, mallocLoop			; Keep going for HL bytes

	ld (iy+heaph),b			; Next available memory is here
	ld (iy+heapl),c

	pop hl					; recover the start address
	pop af
	pop bc
	ret	




		

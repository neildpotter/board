		;
		; mem.asm
		; Control the memory select latch
		;



memLatch equ 0xF7			; Memory latch hardware address

memTop equ 0x7FFE			; Top of shared memory
memShared equ 0x5000		; IY Memory
;mallocBase equ 0xE800		; test new malloc routines here
memRAMstart equ 0x8000	; First byte of switchable RAM

memNumSlots equ 8				; there are 8 slots
;
; IY Space
;
heaph			equ 0x00			; Address of bottom of the heap
heapl			equ 0x01
dartRooth 		equ 0x02			; storage for dart
dartRootl 		equ 0x03
pio1Rooth 		equ 0x04			; storage for left pio
pio1Rootl 		equ 0x05
pio2Rooth 		equ 0x06			; Storage for right pio
pio2Rootl 		equ 0x07
commonID		equ 0x08			; Common ID
blockStarth		equ 0x09
blockStartl		equ 0x0a
escapeState		equ 0x0b			; Line Editor
keyCommand1 	equ 0x0c			; Line Editor
keyCommand2 	equ 0x0d
editBuffersL		equ 0x0e			; Edit buffer structure
editBuffersH		equ 0x0f
currentEditBuffer 	equ 0x10			; Current edit buffer
procListl			equ 0x11			; Address of the process list
procListh		equ 0x12
procCount		equ 0x13			; Counter for priority switch
baseProcCount	equ 0x14			; base process counter
pioLeds			equ 0x15
clockt			equ 0x16			; ticks
clocks			equ 0x17			; seconds
clockm			equ 0x18			; minutes
clockh			equ 0x19			; hours
clockd			equ 0x1a			; days
memTopl		equ 0x1b			; highest memory allocated to heap
memToph		equ 0x1c
heapSizel		equ 0x1d			; total size of heap
heapSizeh		equ 0x1e
tempProc		equ 0x1f
tempProc2		equ 0x20
progRegl		equ 0x21			; program registry
progRegh		equ 0x22
defaultPriority	equ 0x23
ramSelected		equ 0x24			; current ram chip selected
devL			equ 0x25			; device linked list
devH			equ 0x26	
fhRootBlockl		equ 0x27			; root file system
fhRootBlockh	equ 0x28
fhRootDevice0	equ 0x29
fhRootDevice1	equ 0x2a
fhRootDevice2	equ 0x2b
fhRootDevice3	equ 0x2c
packageRootl	equ 0x2d			; package linked list
packageRooth	equ 0x2e



memInit:
	ld IY memShared			; IY points to first 127 bytes of shared memory

	ld a, 7					; Default to slot 7
	call memSelect
	;
	ld hl, memShared			; Start of malloc memory
	ld bc, 128				; Start of malloc memory
	add hl,bc
	ld (iy+heaph),h			; heap
	ld (iy+heapl),l
	ld (iy+progRegl),0			; program register
	ld (iy+progRegh),0
	ld a,'Q'
	ld (iy+commonID),a
	ld (iy+defaultPriority),5	; default priority for new processes
	call mallocInit
	ret


	;
	; Select memory chip 1 - 7 using the A register
	;
; mapping is not straight forward because cpu to 374 is miswired, and bits are miswired to 138.
			;  slot    ROM   Shared   2		3		4		5		6		7
memPortMap:  defb  0x00,	0x01,	0x02,	0x06,	0x01,	0x05,	0x03,	0x07
memSelect:
	cp 2
	ret c
	cp 8
	ret nc
	PUSH hl
	PUSH bc
	ld (iy+ramSelected),a
	ld b,0
	ld c, a
	ld hl, memPortMap		
	add hl, bc			; index into the port map
	ld a, (hl)
	out (memLatch), a
	POP BC
	POP HL
	ret

; mem test
; test memory from hl length bc 
; return a = 0 good

memTestSuccessMessage: defm "Memory OK"
	defb 0x0d, 0x0a, 0
memTestErrorMessage: defm "Memory Error"
	defb 0x0d, 0x0a, 0

memTest:
	ld a,0
	ld (hl),a
	cp (hl)
	jr nz, memError
	ld a,0xff
	ld (hl),a
	cp (hl)
	jr nz, memError
	ld a,0xaa
	ld (hl),a
	cp (hl)
	jr nz, memError
	ld a,0x55
	ld (hl),a
	cp (hl)
	jr nz, memError
	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,memTest
	ld hl,memTestSuccessMessage
	call dartPutString
	ret					; passed 

memError:
	ld hl,memTestErrorMessage
	call dartPutString
	ld a,1
	ret



		

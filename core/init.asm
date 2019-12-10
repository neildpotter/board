	;
	; Init.asm
	; Initialize the board
	;

initMessage0:
	defb 0x0d
	defm "Welcome..."
	defb 0x0d,0x0a,0

initMessage:
	defb 0x0d
	defm "Hello World!"
	defb 0x0d,0x0a,0

initInit:
	DI

	LD SP, memTop
	ld a, iValue
	ld i,a
	call memInit					; Initialize the memory (select the default slot)
	call devInit					; initialize device header
	call procInit					; initialize processes
	call ctcInit					; Initialize the CTC
	call pioInit					; Initialize the PIOs
	call dartInit					; Initialize the dart
	call fileInit					; initialize the file system
	call commandInit				; initialize the static commands
	call lineEditorInit				; initialize the line editor
	call packageInit
	IM 2
	EI
	ld hl,initMessage
	call dartPutString

	ld hl,command
	ld bc,0
	ld a,3
	ld de,commandText
	call newProcess

	ld hl,baseProcess
	ld a,2
	ld de,baseText0
	ld bc,0x3001					; toggle bit 0
	call newProcess

	ld hl,baseProcess
	ld a,2
	ld de,baseText1
	ld bc,0x4002					; toggle bit 1
	call newProcess

	ld hl,baseProcess
	ld a,2
	ld de,baseText2
	ld bc,0x6704					; toggle bit 2
	call newProcess

	ld hl,baseProcess
	ld a,2
	ld de,baseText3
	ld bc,0x8108					; toggle bit 3
	call newProcess



;	ld hl,baseProcess
;	ld a,2
;	ld de,baseText5
;	ld bc,0x0020					; toggle bit 5
;	call newProcess

	ld hl,baseProcess
	ld a,4
	ld de,baseText6
	ld bc,0xa740					; toggle bit 6
	call newProcess

	call procRun					; run all the processes - does not return
	ld l,(iy+procListl)
	ld h,(iy+procListh)

	jp command

commandText defm "CMD"
	defb 0
baseText0: defm "BASE0"
	defb 0
baseText1: defm "BASE1"
	defb 0
baseText2: defm "BASE2"
	defb 0
baseText3: defm "BASE3"
	defb 0
baseText4: defm "BASE4"
	defb 0
baseText5: defm "BASE5"
	defb 0
baseText6: defm "BASE6"
	defb 0




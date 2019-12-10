

	;
	; Process non-escaped special characters and by default, regular characters
	;
keyState equ 1
keyTable:
	defw	0x0d,	keyState,	processEnter
	defw	0x7F,	keyState,	processBackspace
	defw	0x09,	keyState,	processTab
	defw	0x1b,	escState,	processNull
	defw	0,		keyState,	processCharacter
	;
	; process character following an ESC - its either [ or an error
	;
escState equ 2
escapeTable:
	defw	0x5B,	brkState,	processNull
	defw	0x0D,	keyState,	processAltEnter
	defw	0,		keyState,	processError
	;
	; process character following ESC [ - either directly execute or assemble a command
	;
brkState equ 3
escbracketTable:
	defw	0x44,	keyState,	processLeftArrow
	defw	0x43,	keyState,	processRightArrow
	defw	0x42,	keyState,	processDownArrow
	defw	0x41,	keyState,	processUpArrow
	defw	0x47,	keyState,	process5Key
	defw	0,		lngState,	prepareCMD
	;
	; Collect the 2nd n command or execute the command
	;
lngState	equ 4
longEscTable:
	defw	0x7E	keyState,	executeCMD
	defw	0,		lng2State,	prepareCMD2

lng2State	equ 5
long2EscTable:
	defw	0x7E	keyState,	executeCMD
	defw	0,		keyState,	processError
	; 
	; Map the nn command in ESC [nn~ to a handler routine
	;
cmdTable:
	defw	0x32,	processInsert
	defw	0x33,	processDelete
	defw	0x31,	processHome
	defw	0x35,	processPageUp
	defw	0x36,	processPageDown
	defw	0x34,	processEnd
	defw	0x3131,	processPF1
	defw	0x3231,	processPF2
	defw	0x3331,	processPF3
	defw	0x3431,	processPF4
	defw	0x3531,	processPF5
	defw	0x3731,	processPF6
	defw	0x3831,	processPF7
	defw	0x3931,	processPF8
	defw	0x3032,	processPF9
	defw	0x3132,	processPF10
	defw	0x3332,	processPF11
	defw	0x3432,	processPF12
	defw	0,		processError

	;
	; Table of states and which table to use
	;
tableStateTable:
	defw	keyState,	keyTable
	defw	escState,	escapeTable
	defw	brkState,	escBracketTable
	defw	lngState,	longEscTable	
	defw	lng2State,	long2EscTable	
	defw	0,			keyTable

	; 
	; Initialize the line editor
	;
lineEditorInit:
	ld a,keyState
	ld (iy+escapeState),a			; Initial state
	ld a,0
	ld (iy+keyCommand1),a
	ld (iy+keyCommand2),a
	call initEditBuffer				; Initialize the line buffers and cursors
	ret
	;
	; Process next character
	;
processKey:
	ld b,a
	ld c,(iy+escapeState)			; Determine which table to use
	ld hl,tableStateTable
	ld de,4

tableLoop:
	ld a,(hl)
	;	call debugRegisters
	;	call debug
	cp 0						; bad value - fell off end of table of tables
	jr z,tableLoopDone
	cp c
	jr z,tableLoopDone
	add hl,de
	jr tableLoop

tableLoopDone:
	inc hl
	inc hl
	ld e,(hl)					; Pick up the address of the escape table
	inc hl
	ld d,(hl)
	ex de,hl
	ld de,6					; Size of an escape table entry	

keyLoop:					; Find key in the table, and jump to its routine
	ld a,(hl)
	cp 0					; end of table - default
	jr z,keyFound
	cp b					; matched the character received
	jr z,keyFound
	add hl,de				; next row
	jr keyLoop

keyFound:
	inc hl
	inc hl
	ld a,(hl)					; Next state from table
	ld (iy+escapeState),a

	inc hl
	inc hl
	ld e,(hl)					; Routine address from table
	inc hl
	ld d,(hl)
	ex de,hl
	jp (hl)					; Jump to the routine

	;
	; Store the character from the long escape sequence
	;
prepareCMD:					; Store the command string from ESC [ nn ~
	ld a,0
	ld (iy+keyCommand2),a	; clear second byte
	ld (iy+keyCommand1),b	; first byte
	ret

prepareCMD2:
	ld (iy+keyCommand2),b	; second byte
	ret


	; 
	; execute according to the previously stored character in the long escape sequence
	;
executeCMD:
	ld hl,cmdTable			; the command table
	ld b,(iy+keyCommand1)
	ld c,(iy+keyCommand2)	; previously received commands
	ld de,4					; size of cmd row
executeLoop:
	ld a,(hl)
	cp 0
	jr z,executeFound			; table default
	cp b
	jr nz,executeNext			; did not match character 
	inc hl	
	ld a,(hl)
	dec hl
	cp c					; and matched second character?
	jr z,executeFound
executeNext
	add hl,de
	jr executeLoop
executeFound:
	ld a,0
	ld (iy+keyCommand1),a
	ld (iy+keyCommand2),a	; clear the command buffer
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	jp (hl)					; run the handler rountine	



tabText:
	defm "Tab"
	defb 0x0a,0x0d,0

errorText:
	defm "Error"
	defb 0x0a,0x0d,0
leftArrowText:
	defb 0x1b,0x5b,0x44,0
rightArrowText:
	defb 0x1b,0x5b,'C',0



homeText:
	defm "Home"
	defb 0x0a,0x0d,0
upText:
	defm "Page Up"
	defb 0x0a,0x0d,0
downText:
	defm "Page Down"
	defb 0x0a,0x0d,0
endText:
	defm "End"
	defb 0x0a,0x0d,0



pf12Text
	defm "PF12"
	defb 0x0a,0x0d,0
key5Text
	defm "5Key"
	defb 0x0a,0x0d,0
altEnterText
	defm "AltEnter"
	defb 0x0a,0x0d,0
timeText
	defm "Time (DD-HH:MM:SS) - "
	defb 0

	;
	; Key process handlers
	;
processEnter:
	ld a,0x0a
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	;
	; Execute the routine by the first verb
	;
	ld a,(iy+currentEditBuffer)						; Get the edit buffer
	call getEditBuffer
	ld c,(ix+editBufferLen)
	ld b,0
	push hl
	add hl,bc
	ld (hl),0										; null terminate the buffer
	pop hl	
	call commandDoCMD
	;
	; repair the zeros in the old edit buffer caused by tokenization
	ld a,(iy+currentEditBuffer)
	call getEditBuffer
	ld b,(ix+editBufferLen)
processEnter0:
	ld a,b								; while - in case the lenght is zero
	or a
	jr z,processEnter1a
	ld a,(hl)
	or a
	jr nz, processEnter1
	ld (hl),' '
processEnter1:
	inc hl
	djnz processEnter0
processEnter1a:
	;
	; move to the next buffer, leave the previous intact
	;
	ld b,(iy+currentEditBuffer)
	ld a,b							; from buffer
	add a,1
	cp editBufferMaxBuffers
	jr c,processEnter2
	ld a,0
processEnter2:
	ld (iy+currentEditBuffer),a						; Get the edit buffer
	call getEditBuffer

processEnter3:							; clear the buffer
	ld a,0
	ld (ix+editBufferCursor),a
	ld (ix+editBufferLen),0
	ret

processDelete:
	ld a,(iy+currentEditBuffer)						; Get the edit buffer
	call getEditBuffer
	ld a,(ix+editBufferCursor)
	cp (ix+editBufferLen)
	ret z										; do nothing if at end of line 
	ld e,a
	ld d,0
	add hl,de									; offset to new cursor position
	ld d,(ix+editBufferLen)
	push hl
processDelete1:
	inc hl
	ld a,(hl)										; shift everthing left from cursor to length left
	dec hl
	ld (hl),a
	inc hl
	inc e
	ld a,d
	cp e
	jr nz,processDelete1
	dec (ix+editBufferLen)
	ld b,(ix+editBufferCursor)						; redisplay the line from cursor to len
	ld a,(ix+editBufferLen)	
	sub b										; length to re-display
	ld b,a
	ld c,a
	pop hl
processDelete2:								; while there is one more character
	ld a,0
	or b
	jr z,processDelete3		
	ld a,(hl)
	call dartPutTerm
	inc hl
	dec b
	jr processDelete2
processDelete3:								; while there is one more character, move the cursor back
	ld a,' '
	call dartPutTerm								; overwrite the last character
	inc c
processDelete31:
	ld a,0
	or c
	jr z,processDelete4
	ld a,0x1b
	call dartPutTerm
	ld a,'['
	call dartPutTerm
	ld a,'D'
	call dartPutTerm
	dec c
	jr processDelete31
processDelete4:
	ret

processCallHL:
	jp (hl)

processBackspace:
	ld a,(iy+currentEditBuffer)						; Get the edit buffer
	call getEditBuffer
	ld a,(ix+editBufferCursor)
	or a
	ret z										; backspace to beginning of buffer
	dec (ix+editBufferCursor)
	dec a
	ld e,a
	ld d,0
	add hl,de									; offset to new cursor position
	ld d,(ix+editBufferLen)
	push hl
processBackspace1:
	inc hl
	ld a,(hl)										; shift everthing left from new cursor to length
	dec hl
	ld (hl),a
	inc hl
	inc e
	ld a,d
	cp e
	jr nz,processBackSpace1
	dec (ix+editBufferLen)
	ld a,b
	call dartPutTerm								; backspace
	ld b,(ix+editBufferCursor)						; redisplay the line from cursor to len
	ld a,(ix+editBufferLen)	
	sub b										; length to re-display
	ld b,a
	ld c,a
	pop hl
processBackSpace2:								; while there is one more character
	ld a,0
	or b
	jr z,processBackSpace3		
	ld a,(hl)
	call dartPutTerm
	inc hl
	dec b
	jr processBackSpace2
processBackSpace3:								; while there is one more character, move the cursor back
	ld a,' '
	call dartPutTerm								; overwrite the last character
	inc c
processBackSpace31:
	ld a,0
	or c
	jr z,processBackSpace4
	ld a,0x1b
	call dartPutTerm
	ld a,'['
	call dartPutTerm
	ld a,'D'
	call dartPutTerm
	dec c
	jr processBackSpace31
processBackSpace4:
	ret

processTab:
	ld hl,tabText
	call dartPutString
	ret

processCharacter:
	ld a,(iy+currentEditBuffer)						; Get the edit buffer
	call getEditBuffer
	ld a,(ix+editBufferInsertMode)
	or a
	jr nz,processCharacterInsert					; insert mode is on	
	
	ld e,(ix+editBufferCursor)
	ld d,0
	add hl,de									; offset to next character position	
	ld (hl),b										; overwrite mode - write the character
	ld a,(ix+editBufferMaxLen)
	cp e
	jr z,processCharacter1						; buffer full already
	ld a,(ix+editBufferLen)
	cp e										
	jr nz,processCharacter0						; typing mid line - then the line does not get longer
	inc (ix+editBufferLen)		
processCharacter0:
	inc (ix+editBufferCursor)						; cursor to next position
	ld a,b
	call dartPutTerm								; print the character to screen
	ret
processCharacterInsert:
	ld a,(ix+editBufferLen)							; move the buffer contents to the right
	ld e,(ix+editBufferLen)
	ld d,0
	add hl,de									; last character in the buffer

processCharacterInsert1:	
	ld c,(hl)
	inc hl
	ld (hl),c
	dec hl
	cp  (ix+editBufferCursor)
	jr z,processCharacterInsert1a					; done shifting when we've moved the cursor's
	dec a
	dec hl
	jr processCharacterInsert1						; next character back

processCharacterInsert1a							; hl points to the cursor
	ld a,(ix+editBufferLen)							;
	cp (ix+editBufferMaxLen)
	jr z,processCharacterInsert2					; Buffer is already full sized, dont extend
	inc (ix+editBufferLen)
processCharacterInsert2:
	ld (hl),b										; character goes in
	ld a,(ix+editBufferLen)
	sub (ix+editBufferCursor)						; number of character to the right including the new one
	inc (ix+editBufferCursor)
	ld b,a
	ld c,a
processCharacterInsert3:
	ld a,(hl)
	call dartPutTerm								; write right part of the buffer to the screen
	inc hl
	djnz processCharacterInsert3		
processCharacterInsert4:							; move the cursor back to the insert point + 1
	dec c
	jr z,processCharacterInsert6
	ld a,0x1b
	call dartPutTerm
	ld a,'['
	call dartPutTerm
	ld a,'D'
	call dartPutTerm
	jr processCharacterInsert4
processCharacterInsert6:
	ret
processCharacter1:
	ld a,b
	call dartPutTerm
	ld a,0x09
	call dartPutTerm								; back space because end of buffer	
	ret

processNull:
	ret
	;
	; On error - reset the states so it doesn't get stuck
	;
processError:
	ld a,keyState
	ld (iy+escapeState),a			; Initial state
	ld a,0
	ld (iy+keyCommand1),a
	ld (iy+keyCommand2),a
	ld hl,errorText
	call dartPutString
	ret
processLeftArrow:


	ld a,(iy+currentEditBuffer)						; Get the edit buffer
	call getEditBuffer
	ld a,(ix+editBufferCursor)
	or a
	ret z										; cannot left arrow past begining
	dec (ix+editBufferCursor)
	ld hl,leftArrowText
	call dartPutString
	ret


processRightArrow:
	ld a,(iy+currentEditBuffer)						; Get the edit buffer
	call getEditBuffer
	ld a,(ix+editBufferCursor)
	cp (ix+editBufferLen)
	ret z										; cannot left arrow past end
	inc (ix+editBufferCursor)
	ld hl,rightArrowText
	call dartPutString
	ret

processDownArrow:
	ld b,(iy+currentEditBuffer)
	ld a,b							; from buffer
	add a,1
	cp editBufferMaxBuffers
	jr c,processDownArrow1
	ld a,0
processDownArrow1:
	ld c,a							; to buffer
	ld (iy+currentEditBuffer),a
	call switchBuffers
	ret


processUpArrow:
	ld b,(iy+currentEditBuffer)
	ld a,b							; from buffer
	sub 1
	jr nc,processUpArrow1
	ld a,editBufferMaxBuffers
	dec a
processUpArrow1:
	ld c,a							; to buffer
	ld (iy+currentEditBuffer),a
	call switchBuffers
	ret

switchBuffers
	ld a,b
	call getEditBuffer
	ld b,(ix+editBufferCursor)

switchBuffers1:						; move cursor to beggining of line
	ld a,0x1b
	call dartPutTerm
	ld a,'['
	call dartPutTerm
	ld a,b
	call putTermDecimal
	ld a,'D'
	call dartPutTerm
;	djnz switchBuffers1
	ld e,(ix+editBufferLen)				; length of old buffer
	ld a,c
	call getEditBuffer
	ld b,(ix+editBufferLen)				; length of new buffer
switchBuffers2:
	ld a,b	
	or a
	jr z,switchBuffers3				; for the lenght of the new buffer, display it
	ld a,(hl)
	call dartPutTerm
	inc hl
	djnz switchBuffers2
switchBuffers3:
	ld d,(ix+editBufferLen)				; length of new buffer
	ld a,e
	sub d							; old len - new len
	jr c,switchBuffers6
	jr z,switchBuffers6
	ld c,a							; if the old buffer was longer, blank the extra
	ld b,a

switchBuffers4:
	ld a,' '
	call dartPutTerm
	djnz switchBuffers4
	ld b,c
switchBuffers5:
	ld a,0x1b
	call dartPutTerm
	ld a,'['
	call dartPutTerm
	ld a,b
	call putTermDecimal
	ld a,'D'
	call dartPutTerm
;	djnz switchBuffers5
switchBuffers6:
	ld a,(ix+editBufferLen)
	ld (ix+editBufferCursor),a			; cursor to line end
	ret
	;
	; Toggle the edit mode from insert to overwrite
	;

processInsert:
	ld a,(iy+currentEditBuffer)						; Get the edit buffer
	call getEditBuffer
	ld a,(ix+editBufferInsertMode)
	or a
	jr nz,processInsert1							; insert mode is on, turn it off	
	ld a,1
	ld (ix+editBufferInsertMode),a
	ret
processInsert1:
	ld a,0
	ld (ix+editBufferInsertMode),a
	ret

processHome:
	ld hl,homeText
	call dartPutString
	ret
processPageUp:
	ld hl,upText
	call dartPutString
	ret
processPageDown:
	ld hl,downText
	call dartPutString
	ret
processEnd:
	ld hl,endText
	call dartPutString
	ret
processPF1:
	; ld hl,pf1Text
	; call dartPutString
	ld a,0x0a
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	ld a,(iy+currentEditBuffer)						; Show the edit buffer
	call getEditBuffer
	call debug
	ret
processPF2:
;	ld hl,pf2Text
;	call dartPutString
	ld a,0x0a
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	ld a,(iy+currentEditBuffer)						; Show the edit buffer structure
	call getEditBuffer
	push ix
	pop hl
	call debug
	ret
processPF3:
	call procPS
	ret
processPF4:										; print the time
uptime:
	ld hl,timeText
	call dartPutString
	call ctcGetTime
	
	ld a,c										; days
	call putTermDecimal
	ld a,'-'
	call dartPutTerm

	ld a,b										; hours
	call putTermDecimal

	ld a,':'
	call dartPutTerm
	ld a,h										; minutes
	call putTermDecimal

	ld a,':'
	call dartPutTerm
	ld a,l										; seconds
	call putTermDecimal

	ld a,0x0D
	call dartPutTerm
	ld a,0x0A
	call dartPutTerm
	ret



processPF5:
	ld hl,0x5
	call malloc
	push hl
	call debug
	call free
	pop hl
	; call debugHeap
	ret
processPF6:
	ld hl,baseProcess
	ld a,3
	ld de,baseText4
	ld bc,0x1910					; toggle bit 4
	call newProcess
	ld (iy+tempProc),a
	ret
processPF7:
	ld a,(iy+tempProc)
	call kill
	ret
processPF8:
	ld hl,baseProcess
	ld a,2
	ld de,baseText5
	ld bc,0x0020					; toggle bit 5
	call newProcess
	ld (iy+tempProc2),a
	ret
processPF9:
	ld a,(iy+tempProc2)
	call kill
	ret
processPF10:
	call debugProc
	ret
processPF11:
	call debugHeap
	ret
processPF12:
	ld hl,pf12Text
	call dartPutString
	ret
process5Key:
	ld hl,key5Text
	call dartPutString
	ret
processAltEnter:
	ld hl,altEnterText
	call dartPutString
	ret



	;
	; Edit buffer structure
	; an array of structure, each element a buffer and associated variables
	; Indexes
editBufferAddressL equ 0					; Address of this buffer
editBufferAddressH equ 1
editBufferLen equ 2						; Length populated
editBufferCursor equ 3					; Current cursor position
editBufferMaxLen equ 4					; Maximum length for this buffer
editBufferInsertMode equ 5				; Insert mode = 1
	; Constants
editBufferSize equ 6						; 6 bytes an entry
editBufferMaxBuffers equ 5				; Number of buffers in rotation
editBufferDefaultLen equ 81				; Default max buffer len

initEditBuffer:
	ld b,editBufferMaxBuffers
	ld c,editBufferSize
	ld a,0
initEditBuffer1:							; Calculate size of edit buffer structure
	add a,c
	djnz initEditBuffer1
	ld l,a
	ld h,0								; hl = total size of structure
	call malloc
	ld (iy+editBuffersL),l					; Store the edit buffer structure
	ld (iy+editBuffersH),h
	ld a,0
	ld (iy+currentEditBuffer),a				; start with first buffer
	ret
	;
	; Return the current edit buffer structure A in IX
	;
getEditBuffer:
	push bc
	push de
	ld l,(iy+editBuffersL)					; find the edit buffer structure
	ld h,(iy+editBuffersH)
	cp editBufferMaxBuffers				; Check upper limit on buffers
	jr c,getEditBuffer1
	ld a,0
getEditBuffer1

	ld c,a
	ld b,editBufferSize
	ld a,0
getEditBuffer2:
	add a,c
	djnz getEditBuffer2					; multiple offset
	ld e,a
	ld d,0	
	add hl,de							; hl now points to this edit buffer
	push hl
	pop ix
	pop de
	pop bc
	ld l,(ix+editBufferAddressL)
	ld h,(ix+editBufferAddressH)
	ld a,h								; return with HL and IX if there is a buffer in this slot
	or l
	ret nz							
	ld hl,editBufferDefaultLen				; if no edit buffer there, make one
	call malloc							; for process 0 in case this cmd exits
	ld (ix+editBufferAddressL),l				; store the edit buffer
	ld (ix+editBufferAddressH),h
	ld a,editBufferDefaultLen
	ld (ix+editBufferMaxLen),a
	ld (ix+editBufferInsertMode),a			; force insert mode on
	ret





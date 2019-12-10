	;
	; dart.asm
	; Dual asynchronous receiver transmitter
	;
	
	;
	; Port mappings correspond to hardware address
	;
dartAdata 		equ 0xDC			; PIO 1 is the chip on the left
dartAControl 	equ 0xDD
dartBdata 		equ 0xDE
dartBControl 	equ 0xDF

	; Dart memory


channelArxBufl	equ 0
channelArxBufh	equ 1
channelAtxBufl	equ 2
channelAtxBufh	equ 3
channelBrxBufl	equ 4
channelBrxBufh	equ 5
channelBtxBufl	equ 6
channelBtxBufh	equ 7

dartMemory		equ 8				; 8 bytes needed for dart storage


dartInit:
	;
	; Set up storage for the dart
	;
	ld hl, dartMemory
	call malloc
	ld (iy+dartRooth),h				; address of our memory chunk
	ld (iy+dartRootl),l
	push hl
	pop ix
	;
	; Create buffers for input and output
	;
	ld a, 40							; Keyboard receive buffer - 40 bytes
	call buffInit
	ld (ix+channelArxBufl),l
	ld (ix+channelArxBufh),h

	ld a, 80							; Terminal tx buffer - 80 bytes
	call buffInit
	ld (ix+channelAtxBufl),l
	ld (ix+channelAtxBufh),h
	;
	; Set up channel A
	;

	LD a, 1							; Write to register 1A
	OUT (dartAcontrol), a
	LD a, 0x1A
	OUT (dartAControl), a
									; 7 - wait/ready enable
									; 6 - wait/ready function
									; 5 - wait/ready on R/T
									; 4 - 1 Interrupt on all Rx characters, parity does not affect vector
									; 3 - 1 "
									; 2 - 1 Status affects vector (B only)
									; 1 - 1 Tx Int Enable
									; 0 - Ext Int enable

	LD a, 1							; Write to register 1B
	OUT (dartBcontrol), a
	LD a, 0x1E
	OUT (dartBControl), a

	LD a, 2							; Write to register 2
	OUT (dartBcontrol), a
	LD a, dartVector
	OUT (dartBControl), a				; Interrupt vector - channel B only

	LD a, 3							; Write to register 3
	OUT (dartAcontrol), a
	LD a, 0xC1
	OUT (dartAControl), a
									; 7 - 1 - Rx 8 bits /character
									; 6 - 1 - Rx 8 bits /character
									; 5 - auto enables
									; 4 - 0 Not used
									; 3 - 0
									; 2 - 0
									; 1 - 0
									; 0 - 1 - Rx enable

	LD a, 4							; Write to register 4
	OUT (dartAcontrol), a
	LD a, 0x44
	OUT (dartAControl), a
									; 7 - 0 - X16 clock mode
									; 6 - 1 - X16 clock mode
									; 5 - 0 Not used
									; 4 - 0
									; 3 - 0 - 1 stop bit per character
									; 2 - 1 - 1 stop bit per character
									; 1 - 0 - parity odd
									; 0 - 0 - disable parity

	LD a, 5							; Write to register 5
	OUT (dartAcontrol), a
	LD a, 0x68
	OUT (dartAControl), a
									; 7 - DTR
									; 6 - 1 TX 8 bits /character
									; 5 - 1 TX 8 bits /character
									; 4 - 0 - send break
									; 3 - 1 - Tx enable
									; 2 - 0 - Not used
									; 1 - 0 - RTS
									; 0 - 0 - not used 

	LD a, 0x00						; Write to register 0
	OUT (dartAcontrol), a
									; 7 - 0 - Not used 
									; 6 - 0 - Not used
									; 5 - 1 - enable int on next Rx Character
									; 4 - 0
									; 3 - 0
									; 2 - 0 Register 0
									; 1 - 0
									; 0 - 0

	ret

	;
	; Rx Interrupt channel A
	;
dartAReceiveInterrupt:
	di
	push af
	in a,(dartAcontrol)			; read register 0
	bit 0,a						; 1 = read byte ready
	jr z, dartAReceiveInterruptEnd
	;
	; Get the byte from the dart and write it to the read buffer
	;
	push ix
	in a,(dartAdata)					; The received byte from the dart
	exx
	ld h,(iy+dartRooth)				; address of our memory chunk
	ld l,(iy+dartRootl)
	push hl
	pop ix
	ld h,(ix+channelArxBufh)			; get the rx buffer
	ld l,(ix+channelArxBufl)
	call buffWrite					; Add the received byte to the rx buffer
	pop ix
	exx
dartAReceiveInterruptEnd:
	pop af
	ei
	reti
	;
	; Tx Interrupt channel A
	;
dartATransmitInterrupt:
	di
	push af
	in a,(dartAcontrol)
	bit 2,a							; 1 = write register empty
	jr z,dartATransmitInterruptEnd
	;
	; If the dart needs another byte, send it
	;
	exx
	push ix
	ld h,(iy+dartRooth)				; address of our memory chunk
	ld l,(iy+dartRootl)
	push hl
	pop ix
	ld h,(ix+channelAtxBufh)			; address of the transmit buffer
	ld l,(ix+channelAtxBufl)
	call buffRead
	or a								; zero means buffer empty
	jr z,dartATxWriteEmpty
	out (dartAdata),a					; Send the byte
	exx
	pop ix
dartATransmitInterruptEnd:
	pop af
	ei
	reti
									; If the transmitter is empty, reset the interrupt
dartATxwriteEmpty:
	ld a, 0x28						; Reset TxInt Pending - write to reg 0
	out (dartAcontrol),a				
	exx
	pop ix
	pop af
	ei
	reti
	;
	; External status and receive error interrupts  - try resetting
	;
dartAExternalStatusInterrupt:
dartASpecialRecieveInterrupt:
dartBTransmitInterrupt:                        
dartBExternalStatusInterrupt:                      
dartBReceiveInterrupt:                                        
dartBSpecialRecieveInterrupt:           
	di
	push af
	ld a, 0x10			; reset ext /status interrupt
	out (dartAcontrol),a	
 	ld a,0x30			; Error reset
	out (dartAcontrol),a	
	pop af
	ei
	reti

	
	;
	; Check for and return a keypress
	; Or return 0 if there is no key
	;
dartGetKey:
	push hl
	push ix
	ld h,(iy+dartRooth)				; address of our memory chunk
	ld l,(iy+dartRootl)
	push hl
	pop ix
	ld h,(ix+channelArxBufh)			; get the rx buffer
	ld l,(ix+channelArxBufl)
	call buffread						; get a byte from the receive buffer
	pop ix
	pop hl
	ret
	;
	; Write a byte to the output queue
	; Wake up the dart if its idle so the byte goes out
	;
dartPutTerm:
	push hl
	push ix
	ld h,(iy+dartRooth)				; address of our memory chunk
	ld l,(iy+dartRootl)
	push hl
	pop ix
	ld h,(ix+channelAtxBufh)			; get the rx buffer
	ld l,(ix+channelAtxBufl)
	push af
									; Check the size of the tx buffer - and wait if its nearly full
dartPutTermRepeat:
	call buffCount
	cp 78							; Buffer is 80 bytes big
	jr c, dartPutTermNoWait			; buffer not too full
	call procYield
	jr dartPutTermRepeat

dartPutTermNoWait
	pop af
	DI
	call buffWrite					; write the byte to the tx buffer



	;
	; If the write buffer on the dart is empty, start the sending so that interrupts wlll take care of the rest
	;
	in a,(dartAcontrol)
	bit 2,a							; 1 = write register empty
	jr z,dartPutTermEnd
	;
	; If the dart needs another byte, send it
	;
	call buffRead
	or a								; zero means buffer empty
	jr z,dartPutTermEnd
	out (dartAdata),a					; Send the byte

dartPutTermEnd:
	EI
	pop ix
	pop hl
	ret
	;
	; Dart Put String - write a null terminated string to the terminal
	; HL - string
dartPutString:
	push af
	push hl
dartPutStringNext:
	ld a,(hl)
	or a
	jr z, dartPutStringEnd
	call dartPutTerm
	inc hl
	jr dartPutStringNext
dartPutStringEnd:
	pop hl
	pop af
	ret

            
	;
	; Dart Put Buffer - write a series of characters to the terminal
	; HL - string
	; A - length
dartPutBuffer:
	push af
	push bc
	push hl
	ld b,a
	or a
	jr z,dartPutBufferEnd
dartPutBufferNext:
	ld a,(hl)
	call dartPutTerm
	inc hl
	djnz dartPutBufferNext
dartPutBufferEnd:
	pop hl
	pop bc
	pop af
	ret




 


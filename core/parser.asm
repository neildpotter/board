;
; Parser
;
; tokenize a null terminated string. Input string hl, token a 
; output de = pointer to token or 0, a - length of token

parserTokenize:
	push ix	
	push hl
	push bc
	ld c,a				; token number we are looking for - 0 = first
	ld d,1				; mode - whitespace  =1 
	ld e,0				; token counter
	ld ix,0				; output token start address

parserTokenize1:
	ld a,(hl)
	or a
	jr z,parserTokenize4 	; process end of buffer as whitespace
		; is the buffer done?

		; determine if the character is whitespace
	ld a,(hl)
	cp 0x20
	jr z,parserTokenize4
	cp 9
	jr z,parserTokenize4
	;
	; this is a character
	;
	ld a,d
	or a
	jr z,parserTokenize2
						; character and was on whitespace
	push hl
	pop ix				; first character - store start of token
	ld d,0				; now on characters
	jr parserTokenize10	

parserTokenize2:			; character and was on character
	jr parserTokenize10

parserTokenize4:			; process whitespace
	ld a,d
	or a
	jr z,parserTokenize5
						; whitespace and was on whitespace
	jr parserTokenize10	; do nothing
parserTokenize5:			; whitespace and was on character - end of token found
	ld d,1				; now on whitespace
	ld a,c
	cp e				; is this the token were looking for
	jr z,parserTokenize20
	inc e				; count tokens found
	ld ix,0
	; next character
parserTokenize10:

	ld a,(hl) 
	or a
	jr z,parserTokenize20	; end of buffer
	inc hl
	jr parserTokenize1	; next character

parserTokenize20:		; found the token
	push ix
	pop de				; token start address, if there is one
	ld a,d
	or e
	jr z,parserTokenize21	; no token found
	sbc hl,de			; compute length of token
	ld a,l				; lenght of token
parserTokenize21:
	pop bc
	pop hl	
	pop ix
	ret

	;
	; parse a byte value from a token on the command line
	; HL - command line. A switch character
	; BC = byte value, A - valid (0 not valid)
parseByteToken:
	call parserFindTokenSwitch
	or a
	ret z
	call parserGetArg
	or a
	ret z	
	ld bc,0
	ld a,(de)
	call hexToBinary
	jr c,parseByteEnd
	inc de
	ld a,(de)
	call hexToBinary
	jr c,parseByteEnd
	inc de
	ld a,(de)
	call hexToBinary
	jr c,parseByteEnd
	inc de
	ld a,(de)
	call hexToBinary
parseByteEnd:
	ld a,1
	ret
parseByteError:
	ld bc,0
	ld a,0
	ret

	;
	; parse a byte value from noun on the command line
	; HL - command line.
	; BC = byte value, A - valid (0 not valid)
parseByteNoun:
	call parserFindNoun
	or a
	ret z
	ld bc,0
	ld a,(de)
	call hexToBinary
	jr c,parseNounError
	inc de
	ld a,(de)
	call hexToBinary
	jr c,parseNounEnd
	inc de
	ld a,(de)
	call hexToBinary
	jr c,parseNounEnd
	inc de
	ld a,(de)
	call hexToBinary
parseNounEnd:
	ld a,1
	ret
parseNounError:
	ld bc,0
	ld a,0
	ret

	;
	; for the current token, find the = sign and return that
	; DE - token, A - length
	; DE - arg, A - length of arg, or 0 for no arg
parserGetArg:
	ld b,a
parserGetArgLoop
	ld a,(de)
	inc de
	dec b
	cp '='
	jr z,parserGetArgFound				; found the start of the arg	
	ld a,b
	jr nz,parserGetArgLoop
	ld a,0
	ret
parserGetArgFound:
	ld a,b
	ret

parserFindNoun:
	; Find the noun on the comand line
	; HL - command line
	; DE - noun, A length of noun
	ld b,0							; token counter
parserFindNounNext:
	ld a,b							; token to find
	inc b
	call parserTokenize

	ld c,a							; token length
	or a
	jr z,parserFindNounEnd			; end of tokens, so we didn't find it
	call isSwitch
	or a
	jr nz,parserFindNounNext			; token is a switch - keep looking
	ld a,c	
parserFindNounEnd
	ret								; A = 0 - no token, A = token length



	;
	; Find the token with the switch indicated
	; HL - command line. A switch
	; DE - token that includes the switch, A length of token
parserFindTokenSwitch:
	ld b,0							; token counter
	ld c,a							; switch to look for
parserFindTokenNext:
	ld a,b							; token to find
	inc b
	call parserTokenize

	or a
	jr z,parserFindTokenEnd			; end of tokens, so we didn't find it
	call isSwitch
	or a
	jr z,parserFindTokenNext
	call includesMySwitch			; token is a switch - does it have my switch
	or a
	jr z,parserFindTokenNext
parserFindTokenEnd

	ret								; A = 0 - no token, A = token length

	; DE = point to token -  a - length
isSwitch:
	push af
	ld a,(de)
	cp '-'
	jr z,isSwitchIs
	pop af
	ld a,0
	ret								; not a swtich
isSwitchIs:
	pop af							; is a switch
	ret

	; DE = pointer - a length, C switch to find
includesMySwitch:
	push af
	push bc
	push de
	ld b,a							; length
includesMySwitchLoop:
	ld a,(de)
	cp c
	jr z,includesMySwitchFound
	cp '='							; end of switches
	jr z,includesMySwitchNotFound
	inc de
	djnz includesMySwitchLoop
includesMySwitchNotFound:
	pop de
	pop bc
	pop af
	ld a,0
	ret
includesMySwitchFound:
	pop de
	pop bc
	pop af
	ret

	;
	; Convert a character to binary
	; A - character, B - binary - C flag set means invalid
hexToBinary:
	cp '0'
	jr c,hexToBinaryNone
	cp '9'
	jr z,hexToBinaryNumber
	jr c,hexToBinaryNumber
	cp 'A'
	jr c,hexToBinaryNone
	cp 'F'
	jr z,hexToBinaryUpper
	jr c,hexToBinaryUpper
	cp 'a'
	jr c,hexToBinaryNone
	cp 'f'
	jr z,hexToBinaryLower
	jr c,hexToBinaryLower
hexToBinaryNone:
	scf
	ret
hexToBinaryLower
	sub 'a'
	add a,'A'
hexToBinaryUpper
	sub 'A'
	add a,'0'
	add a,10
hexToBinaryNumber
	sub '0'
	rl c
	rl b
	rl c
	rl b
	rl c
	rl b
	rl c
	rl b
	add a,c
	ld c,a	
	ret

	; trim the token - e.g., convert filename -r=2 to filename\0
	; write a 0x00 to terminate the token string
	; hl = token	
parserTrim:
	push hl
	push af
parseTrimLoop:
	ld a,(hl)
	cp 0
	jr z,parseTrimEnd
	cp ' '
	jr z,parseTrimEnd
	cp 0x09
	jr z,parseTrimEnd
	inc hl
	jr parseTrimLoop
parseTrimEnd:
	ld (hl),0
	pop af
	pop hl
	ret








	









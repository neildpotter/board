	org 0
	;
	; Initialize
	; 

	jr init
	jr deinit
packageName:
	defm "echo"
	defb 0
init:
	ld de,conversionTable					; modify the 16bit addresses to absolutes
	call _relocate
in0:	ld ix,packageName
in1:	ld hl,echoVerb						; register the program
in2:	ld de,cmdEcho						; offset to the start
in3:	ld bc,echoHelp
	ld a,2								; package verb
	call _register
	ret
deinit:
in4:	ld hl,echoVerb
	call _unregister						; don't do this with package verbs
	ret
	;
	; help text
	;
echoHelp: 
	defm "echo text"	
	defb 0
	;
	; program command verb
	;
echoVerb:
	defm "echo"
	defb 0

	;
	; the command - runs in a new process
	;
cmdEcho:
	; hl						Command line
	call _PutString
	call _putCRLF
	ret

conversionTable:
	defw in0+2				; ix
	defw in1+1
	defw in2+1
	defw in3+1
	defw in4+1
	defw 0					; terminator



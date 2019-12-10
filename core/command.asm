	;
	; Commands
	; Front-end for keyed commands. 
	; 

	;
	; Add static routines to program registry
	;
psVerb:
	defm "ps"
	defb 0
psHelp: 
	defm "process -d debug"
	defb 0
clsVerb:
	defm "cls"
	defb 0
clsHelp: 
	defm "clear screen"
	defb 0
helpVerb:
	defm "help"
	defb 0
helpHelp: 
	defm "Annette Baby!"
	defb 0
uptimeVerb:
	defm "uptime"
	defb 0
uptimeHelp: 
	defm "time since reboot"
	defb 0
heapVerb:
	defm "heap"
	defb 0
heapHelp: 
	defm "display the heap"
	defb 0
devVerb:
	defm "dev"
	defb 0
devHelp:
	defm "device [-r=ram]"
	defb 0
rebootVerb:
	defm "reboot"
	defb 0
rebootHelp: 
	defm "restart 0"
	defb 0
memVerb:
	defm "mem"
	defb 0
memHelp: defm "<addr> -n=bytes"
	defb 0
priVerb:
	defm "pri"
	defb 0
priHelp: defm "default priority n"
	defb 0
setVerb:
	defm "set"
	defb 0
setHelp: 
	defm "addr -n=bytes -v=val"
	defb 0

testVerb:
	defm "test"
	defb 0
testhelp: defm "<nnnn>"
	defb 0 
peekVerb:
	defm "peek"
	defb 0
peekHelp: defm "<addr>"
	defb 0
pokeVerb:
	defm "poke"
	defb 0
pokeHelp: 
	defm "<adde> -b=byte"
	defb 0
killVerb:
	defm "kill"
	defb 0
killHelp: defm "procID"
	defb 0
ledVerb:
	defm "led"
	defb 0
ledHelp: 
	defm "-b=bit -r=rate"
	defb 0
loadVerb:
	defm "load"
	defb 0
loadHelp: 
	defm "perl load.pm file"
	defb 0
restartVerb:
	defm "restart"
	defb 0 
restartHelp: 
	defm "restart core"
	defb 0
ramVerb:
	defm "ram"
	defb 0 
ramHelp: 
	defm "ram <slot>"
	defb 0
mTestVerb:
	defm "mtest"
	defb 0 
mTestHelp: 
	defm "addr -n=len -r -all"
	defb 0
mkdirHelp:
	defm "mkdir /dir"
	defb 0
mkdirVerb
	defm "mkdir"
	defb 0
formatHelp:
	defm "format device"
	defb 0
formatVerb:
	defm "format"
	defb 0
sizeHelp:
	defm "file size path"
	defb 0
sizeVerb:
	defm "size"
	defb 0
lsHelp:
	defm "ls path"
	defb 0
lsVerb
	defm "ls"
	defb 0
delHelp:
	defm "delete file"
	defb 0
delVerb
	defm "del"
	defb 0
rmdirHelp:
	defm "remove dir or mount"
	defb 0
rmdirVerb
	defm "rmdir"
	defb 0
catHelp:
	defm "cat file"
	defb 0
catVerb
	defm "cat"
	defb 0
mountHelp:
	defm "mount path -r=chip"
	defb 0
mountVerb
	defm "mount"
	defb 0
loopVerb:
	defm "loop"
	defb 0 
loopHelp: defm "<iterations>"
	defb 0
cmdVerb:
	defm "cmd"
	defb 0
cmdHelp: 
	defm "new cmd shell"	
	defb 0
exitVerb:
	defm "exit"
	defb 0
exitHelp: 
	defm "exit cmd shell"	
	defb 0
packVerb:
	defm "pack"
	defb 0
packHelp: 
	defm "package -l -d"
	defb 0

					; Create entries for a the embedded commands - those compiled into core
commandInit:
	ld hl,psVerb				; command verb
	ld de,cmdPS				; dump the processes
	ld bc,psHelp
	ld a,progEmbedded		; embedded command
	call progRegister
	ld hl,clsVerb
	ld de,cmdCLS
	ld bc,clsHelp
	ld a,progEmbedded
	call progRegister
	ld hl,helpVerb
	ld de,progList
	ld bc,helpHelp
	ld a,progEmbedded
	call progRegister
	ld hl,uptimeVerb
	ld de,uptime
	ld bc,uptimeHelp
	ld a,progEmbedded
	call progRegister
	ld hl,heapVerb
	ld de,debugHeap
	ld bc,heapHelp
	ld a,progEmbedded
	call progRegister
	ld hl,rebootVerb
	ld de,cmdReboot
	ld bc,rebootHelp
	ld a,progEmbedded
	call progRegister
	ld hl,memVerb
	ld de,cmdMemDump
	ld bc,memHelp
	ld a,progEmbedded
	call progRegister
	ld hl,mTestVerb
	ld de,cmdMemTest
	ld bc,mTestHelp
	ld a,progEmbedded
	call progRegister
	ld hl,devVerb
	ld de,cmdDevTest
	ld bc,devHelp
	ld a,progEmbedded
	call progRegister
	ld hl,setVerb
	ld de,cmdSet
	ld bc,setHelp
	ld a,progEmbedded
	call progRegister
	ld hl,loadVerb
	ld de,cmdLoad			; blockCommand
	ld bc,loadHelp
	ld a,progEmbedded
	call progRegister
	ld hl,testVerb
	ld de,cmdTest
	ld bc,testHelp
	ld a,progEmbedded
	call progRegister
	ld hl,peekVerb
	ld de,cmdPeek
	ld bc,peekHelp
	ld a,progEmbedded
	call progRegister
	ld hl,priVerb
	ld de,cmdPriority
	ld bc,priHelp
	ld a,progEmbedded
	call progRegister
	ld hl,pokeVerb
	ld de,cmdPoke
	ld bc,pokeHelp
	ld a,progEmbedded
	call progRegister
	ld hl,killVerb
	ld de,cmdKill
	ld bc,killHelp
	ld a,progEmbedded
	call progRegister
	ld hl,ledVerb
	ld de,cmdLED
	ld bc,ledHelp
	ld a,progEmbedded
	call progRegister
	ld hl,restartVerb
	ld de,cmdRestart
	ld bc,restartHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,ramVerb
	ld de,cmdRAM
	ld bc,ramHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,loopVerb
	ld de,cmdLoop
	ld bc,loopHelp
	ld a,progEmbedded
	call progRegister
	ld hl,cmdVerb
	ld de,command
	ld bc,cmdHelp
	ld a,progEmbedded
	call progRegister
	ld hl,exitVerb
	ld de,cmdExit
	ld bc,exitHelp
	ld a,progEmbedded
	call progRegister
	ld hl,mountVerb
	ld de,cmdmount
	ld bc,mountHelp
	ld a,progEmbedded
	call progRegister
	ld hl,mkdirVerb
	ld de,cmdMkdir
	ld bc,mkdirHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,rmdirVerb
	ld de,cmdRmdir
	ld bc,rmdirHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,lsVerb
	ld de,cmdLs
	ld bc,lsHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,catVerb
	ld de,cmdCat
	ld bc,catHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,delVerb
	ld de,cmdDel
	ld bc,delHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,sizeVerb
	ld de,cmdSize
	ld bc,sizeHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,packVerb
	ld de,cmdPackage
	ld bc,packHelp
	ld a,progEmbedded
	call progRegister	
	ld hl,formatVerb
	ld de,cmdFormat
	ld bc,formatHelp
	ld a,progEmbedded
	call progRegister
	ret


	; cmd process loop
	; receive keyboad input. Process keys - parse and execute commands
	;
command:

command1
	call procYield						; get the next keypress or null
	call dartGetKey			
	or a
	jr z,command1						; buffer empty
	call processKey
	jr command1


	;
	; Clear the screen
	;
clsString:
	defb 0x1b,'[','2','J',0X1b,'[','H',0
cmdCLS:
	ld hl,clsString
	call dartPutString
	ret
	;
	; Restart
	;
cmdReboot:
	RST 0x00

cmdDevTest:
	ld a,'r'
	call parseByteToken
	jr z,cmdDevTest1
	ld a,c					; c value of r=n - implying - make a ram disk
	call rdInit

cmdDevTest1:				; show all the devices allocated
	call devList
	ret

							; exit the current command shell by killing its process
cmdExit:
	call procFindParentID

	call kill					; kill the cmd process - which is the parent to this exit
	ret

cmdTest:					; run various test commands
	; hl						Command line
	call parseByteNoun
	or a
	ret z
	push bc
	ld a,'s'
	call parseByteToken
	pop hl
	or a
	ret z
	call rdTest				; hl is block number, s is operation
;	call putTerm16
;	call putCRLF
	ret

cmdKill:							; kill process by ID
	call parseByteNoun
	or a
	ret z
	ld a,c						; process ID to kill
	call kill
	ret

cmdPeek:						; return content of memory
	call parseByteNoun
	or a
	ret z
	push bc
	pop hl
	call debug
	ret

cmdRAM:						; switch ram slots
	call parseByteNoun
	or a
	ret z
	ld a,c				; slot number
	cp 8				; can't be more than 7
	ret nc
	cp 2				; can't be 1 or 2
	ret c
	call memSelect
	ret

cmdPS:							; show processes
	ld a,'d'
	call parseByteToken
	or a
	jp nz,debugProc
	jp procPS


cmdPoke						; set byte location to value
	call parseByteNoun
	or a
	ret z
	push bc
	ld a,'b'
	call parseByteToken
	pop hl
	or a
	ret z
	ld (hl),c					; poke it in
	ret

cmdLED							; Flash an LED
	ld a,'b'					; bit
	call parseByteToken
	or a
	ret z
	cp 8
	ret nc
	push bc
	ld a,'r'					; rate
	call parseByteToken
	or a
	ret z
	ld a,c						; rate
	pop bc
	ld b,a
	ld a,c
	ld c,1					; bit number
cmdLEDLoop:
	dec a
	jr z,cmdLEDstart
	sla c
	jr cmdLEDLoop	
cmdLEDstart:
	push bc
	pop hl
	jp baseProcess


cmdMemTest:
	call parseByteNoun			; start address
	or a
	jr nz,cmdMemTest1
	ld bc,0x8000					; default
cmdMemTest1:
	push bc
	ld a,'n'						; number of bytes
	call parseByteToken
	or a
	jr nz,cmdMemTest2
	ld bc,0x100					; default
cmdMemTest2
	push bc						; number 
	ld a,'r'
	call parseByteToken			; ram slot selected?
	or a
	jr z,cmdMemTest3
	ld a,c
	call memSelect				; select the ram slot
cmdMemTest3:
	ld a,'a'						; test all ram slots?
	call parseByteToken
	or a
	jr nz, cmdMemTestAllSlots
	pop bc						; number
	pop hl						; start
	call memTest
	ret
cmdMemTestAllSlots:
	pop bc						; number
	pop hl						; start
	ld a,2						; start with slot 2
cmdMemTestNextSlot:
	push af
	push hl
	push bc
	call memSelect
	call memTest
	pop bc
	pop hl
	pop af
	inc a
	cp 8
	jr nz,cmdMemTestNextSlot
	ret

priorityMessage defm "Default Priority "
	defb 0

cmdPriority:						; set default priority for new processes
	call parseByteNoun			; optional priority
	or a
	jr z,cmdPriority1				; jump if just looking
	ld (iy+defaultPriority), c		; set the default priority
cmdPriority1:
	ld hl,priorityMessage
	call dartPutString
	ld a,(iy+defaultPriority)
	call toHex
	ld a,e
	call dartPutTerm
	call putCRLF
	ret


cmdMemDump:					; print a page of memory
	call parseByteNoun			; start address
	or a
	jr nz,cmdMemDump1
	ld bc,0x8000					; default
cmdMemDump1:
	push bc
	ld a,'n'						; number of bytes
	call parseByteToken
	or a
	jr nz,cmdMemDump2
	ld bc,0x100					; default
cmdMemDump2
	pop hl
cmdMemDump3:
	call debug
	ld de,0x10
	adc hl,de
	push hl
	push bc
	pop hl
	sbc hl,de
	push hl
	pop bc
	pop hl
	jr nc,cmdMemDump3
	ret

cmdSet:							; fill memory with a value
	call parseByteNoun			; start address
	or a
	ret z						; no default address
	push bc
	ld a,'v'
	call parseByteToken			; non default byte value
	or a
	jr nz,cmdSet1
	ld bc,0						; write 0 by default
cmdSet1:
	push bc
	ld a,'n'						; number of bytes
	call parseByteToken
	or a
	jr nz,cmdSet2
	ld bc,0x10					; default count
cmdSet2
	pop de						; e = byte to write
	pop hl						; start address
cmdSet3:
	ld (hl),e
	inc hl
	dec bc
	ld a,b
	or c
	jr nz, cmdSet3
	ret


cmdRestart					; restart core
	jp initInit

cmdLoop:					; loop process to load CPU
	ld bc,100
	call parseByteNoun				; 
cmdLoop1:
	push bc
	ld hl,0
cmdLoop2:
	dec hl
	ld a,h
	or l
	jr nz,cmdLoop2
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,cmdLoop1
	ret

	; package commands
cmdPackage
	push hl
	ld a,'d'						; delete?
	call parseByteToken
	or a
	jr nz,cmdPackDelete
	ld a,'l'						; load?
	call parseByteToken
	or a
	jr nz,cmdPackNew

	pop hl
	call packageList
	ret
cmdPackNew:

	pop hl				; filename
	call parserTrim
	call packageNew		; cread a new package entry
	call c,packageLoad	; load the file into the package
	call packageType		; get the package type in A
	cp packageTransient
	ret nz
	call packageUnload	; unload transient packages
	ret


cmdPackDelete:
	pop hl
	call parserTrim
	call packageFind		
	ret nc
	call packageDestroy			; drop the package
	ret


	; format a device and create a root directory
cmdFormat:
	call fileFormat				; hl device name
	ret

	; make a directory
cmdMkDir
	push hl						; directory name
	call fhNew
	pop hl
	call fhMakeDir
	ret

	; remove a directory or mount
cmdRmdir:
	call dirDelete
	ret


	; list files
cmdLs:
	call fhDir
	ret
	; delete file
cmdDel:
	call fileDelete
	ret
	; cat a file
	; HL = filename
cmdCat
	ld b,0					; open for write
	call fileOpen
	ret nc					; file not found
	ld hl,10					; temporary buffer
	call malloc
cmdCatLoop:
	ld b,8					; 9 bytes
	push hl
	call fileRead
	jr nc,cmdCatEnd			; Error
	ld a,b
	or a
	jr z,cmdCatEnd			; End of file
	pop hl
	push hl
cmdCatNext
	ld a,(hl)
	inc hl
	call dartPutTerm
	djnz cmdCatNext			; b bytes were read
	pop hl
	jr cmdCatLoop
cmdCatEnd:
	pop hl
	call free
	call putCRLF
	call fileClose
	ret

						; mount a device to the file system
cmdMount:
	push hl
	ld a,'r'
	call parseByteToken			; device option - RAM
	ld b,0
	or a
	jr z,cmdMountError			; missing -r option no device indicated 
	call fhNew
	ld hl,5
	call malloc					; buffer for the device name
	ld (hl),'R'
	ld a,c
	add a,'0'
	inc hl
	ld (hl),a
	dec hl						; device to mount
	ex de,hl
	pop hl						; path to mount to
	call parserTrim
	call fhMount
	ret

cmdMountError:
	pop hl
	ret

	; print the size of a file
cmdSize:
	call parserTrim
	call fileSize
	call dartPutString
	ld a,9
	call dartPutTerm
	push bc
	pop hl
	call putTerm16
	call putCRLF
	ret

	; Load serial data to a file
cmdLoad:
	call parserTrim					; filename
	call loadSerialToFile
	ret


	;
	; Run a process to execute the command 
	; HL points to the command line, length B
	; 
commandDoCMD:
	push hl				; command line
	push bc				; length
	ld a,0				; token 0 is the verb
	call parserTokenize	; de verb, a length
	or a
	pop bc
	pop hl
	ret z				; no verb, so do nothing
	;call debugRegisters
	push de				; verb 
	push af				; length is A
		;
		; find the second token - this is the start of the arguments
		;
	ld a,1				; token 1 is the args to the verb
	call parserTokenize	; de - is args, length a
	pop af				; token length
	pop hl				; verb token
	push de				; args
		; null terminate the verb so the strcmps work
	push hl
	ld e,a
	ld d,0
	add hl,de
	ld (hl),0				; null terminate the verb
	pop hl
	push hl				; verb
	ld a,'&'
	cp (hl)
	jr nz,commandDoCMD1
	inc hl
commandDoCMD1:
	call progFind			; b = type, hl = start address, de = package name
	ld a,h
	or l					; found a match?
	jr z,commandSyntaxErr
	ld a,b
	cp progEmbedded	; run embedded command - compiled in core?
	jr z,commandDoCMD15

	ex de,hl				; run command from a package by loading it
	call packageFind		; Find the package supporting this verb
	jr nc, cmdPackageError
	call packageLoad		; load the pfile into the package, if not already loaded
	jr nc,cmdPackageError
	pop hl				; verb
	push hl
	ld a,'&'
	cp (hl)
	jr z,cmdPackageError	; no support for asynchronous running in packages
						; need to find the prog again because loading it may have updated the start address
	call progFind			; b = type, hl = start address, de = package name
	pop de				; verb
	pop bc				; args
	ld a,(iy+defaultPriority) ; priority
	push de				; verb
	call newProcess		; kick off a new process with the args
	call procWaitFor		
	pop hl				; verb
	call progFind			; Find the package again 
	ex de,hl
	call packageFind
	jr nc, cmdPackageError
	call packageType		; was packaged loaded as transient (drop after each use) or permanent (leave loaded)?
	cp packagePermanent
	ret z
	call packageUnload	; unload transient packages to free up memory
	ret

commandDoCMD15:		; run Embedded commands - those compiled in core
	pop de				; verb
	pop bc				; args
	ld a,(de)
	cp '&'				; first character of verb is & - don't wait
	jr z,commandDoCMD2
						; hl = start address
	ld a,(iy+defaultPriority) ; priority
	call newProcess		; kick off a new process with the args
	call procWaitFor	
	ret
commandDoCMD2:		; don't wait
	ld a,(iy+defaultPriority)
	inc de
	call newProcess
	ret

cmdPackageError:
	ld a,errBadPackage
	call errPrint
	ret

cmdSyntaxMsg: defm "Error: "
	defb 0

cmdNotFound: defm ": command not found"
	defb 0x0a, 0x0d, 0

commandSyntaxErr:		; Verb not found, print an error
	ld hl,cmdSyntaxMsg
	call dartPutString
	pop hl				; verb
	call dartPutString
	ld hl,cmdNotFound
	call dartPutString
	pop bc				; args
	ret


 
            ;
            ; Process structure
            ;
procID			equ 0
procStackOrgl	equ 1				; stack malloc address
procStackOrgh	equ 2
procStackl		equ 3				; stack pointer
procStackh		equ 4
procRAMslot		equ 5			
procPriority		equ 6			
procState		equ 7
procFlags		equ 8				; 1 - kill, 2 - sleep
procParentID		equ 9
procNextl		equ 10				; Linked list to next process
procNexth		equ 11                
procWaitingID	equ 12        
procName		equ 13				; 8 bytes of name
 
procSize		equ 22				; 22 bytes per entry
 
procIdle			equ 0				; Process state enumerated
procWaiting		equ 1
procExecuting	equ 2
procSleep		equ 3
procTerm		equ 4


procLowestPriority equ 3				; priorities are 0 (highest) 3 (lowest)
procDefaultStack	equ 0x60			; number of bytes of stack to reserve per process
maxProcInterval	equ 10				; reset priority every n clock ticks (75ms)
		;
		; Initialise the process table
		;
procInit:
	ld hl,0
	ld (iy+procListl),l
	ld (iy+procListh),h
	ld a,0
	ld (iy+baseProcCount),a
	ret

	;
	; run the process scheduler (does not return)
procRun:

	
	jp procStart

            ;
            ; Yield to the next process
            ;
procYield:
	di
	push af
	push bc
	push de
	push hl
	push ix
	ld e,(iy+procListl)					; find this process on the list - its the one executing
	ld d,(iy+procListh)				; DE points to a process
procYield1:
	ld a,e
	or d
	jp z,procYieldNoProcesses			; this is not a process, so it can't yield
	push de
	pop ix
	ld a,(ix+procState)
	cp procExecuting					; find our process
	jr z,procYield2
	ld e,(ix+procNextl)				; to next process in the list
	ld d,(ix+procNexth)
	jr procYield1		

procYield2:
	ld a,procWaiting					; set our process to waiting state
	bit 1,(ix+procFlags)
	jr z,procYield24
	res 1,(ix+procFlags)
	ld a,procSleep					; bit 2 and process goes to sleep
procYield24:
	ld (ix+procState),a
	ld hl,0
	add hl,sp
	ld (ix+procStackl),l				; store the stack pointer away in the process
	ld (ix+procStackh),h	
	;
	; Now the current process is properly to bed, consider waking up the next
	;
	ld a,(iy+procCount)				; is it time to reset priority?
	cp maxProcInterval
	jr z,procStart
procNextProc:
	ld e,(ix+procNextl)				; next process
	ld d,(ix+procNexth)
	ld a,d
	or e
	jr nz,procYield3					; end of process list? Go to top
procStart:
	ld e,(iy+procListl)
	ld d,(iy+procListh)
procYield3:
	push de
	pop ix
	ld a,(ix+procState)				; skip sleeping processes
	cp procSleep
	jr z,procNextProc
	;
	; if the next process is marked as killed, dont run it - consider deleting it
	;
	ld a,(ix+procFlags)
	and 1
	jr z,procYield4					; not killed, so run it
	ld a,(ix+procID)					; if there are children, hold off terming it until there are none

	call procNumChildren
	or a
	jr nz,procNextProc					; skip this one and try the next
	; 
	; if there's a process sleeping on this process, wake it
	;
	ld a,(ix+procWaitingID)
	or a
	jr z,procYield55
	push ix
	push de
	push bc
	call procfind
	jr nc,procYield45						; can't find it
	ld (ix+procState),procWaiting
procYield45:
	pop bc
	pop de
	pop ix
procYield55:
	; 
	; remove this process from the linked list
	; scan the list to find the previous process
	push iy
	pop bc
	ld hl,procListl					; root of linked list

procTermLoop:

	add hl,bc
	ld c,(hl)							; this is not right.
	inc hl
	ld b,(hl)
	dec hl							; hl address of last pointer. de & ix points to the proc to remove

	ld a,b							; previous pointer points to this process?
	cp d
	jr nz,procTermNext	
	ld a,c
	cp e
	jr nz,procTermNext

	;call debugHeap
									; hl points to the previous pointer
	ld e,(ix+procNextl)				; unlink
	ld (hl),e
	inc hl
	ld d,(ix+procNexth)
	ld (hl),d

	; 
	; free up everything	
	;
	ld l,(ix+procStackOrgl)				; free the stack
	ld h,(ix+procStackOrgh)
	call free
	ld a,(ix+procID)
	call freeProcessMemory				; free any memory this process may have allocated
	push ix
	pop hl
	call free							; free the process block
	;
	; done killing, go back and run something
	; 
	jr procStart						

procTermNext:
	ld hl,procNextl					; offset to pointers within process block
	jr procTermloop

procYield4:
	ld a,procExecuting				; restore and resume this process
	ld (ix+procState),a
	ld l,(ix+procStackl)				; restore the stack
	ld h,(ix+procStackh)
	ld sp,hl
procYieldNoProcesses:
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ei								
	ret
			; Create a 
			; New process a = priority, hl = start address, bc arguments to HL in the process
			; de - process name 
newProcess:
	di
	push bc							; Arguments
	push hl							; start address
	push de							; Name
	ld hl,procSize
	call malloc					; Make a new process block - forward linked list
	push hl							; new process block

	push iy							; get the root address in case we need to insert at top
	pop hl
	ld de,procListl
	add hl,de						; hl points to root proc list
	ld e,(iy+procListl)                               	; de points to next proc, or null
	ld d,(iy+procListh)
	ld c,a							; desired priority

newProcess1:
	ld a,d
	or e								; end of linked list?
	jr z,newProcess2
	push de
	pop ix
	ld b,(ix+procPriority)
	ld a,c
	cp b							; add in priority order
	jr c,newProcess2
	ex de,hl
	ld de,procNextl
	add hl,de						; this process's next pointer							
	ld e,(ix+procNextl)				; next process
	ld d,(ix+procNexth)
	jr newProcess1

newProcess2:
	pop ix							; new process block
	ld (ix+procNexth),d
	ld (ix+procNextl),e
	ld (ix+procPriority),c
	push ix
	pop bc
	ld (hl),c							; Update root or previous process pointer
	inc hl
	ld (hl),b	

	call procNewID					; get a unique procID	
	ld (ix+procID),a

	ld hl,procName					; name offset
	add hl,bc
	pop bc							; name

newProcess3:
	ld a,(bc)
	ld (hl),a
	inc bc
	inc hl
	or a
	jr nz,newProcess3
	;
	; write this processes ID as the parent ID
	;
	call procThisID
	ld (ix+procParentID),a
	;
	; make the stack for this process
	;
	ld hl,procDefaultStack				; stack space for this process
	ld de,procDefaultStack
	call malloc
	ld (ix+procStackOrgl),l				; record the stack so we can free it later
	ld (ix+procStackOrgh),h
	add hl,de						
	dec hl
	dec hl							; to top of stack
		;
		; Build out the processes stack so it can simply resume
		;
	ld bc,procTermMe				; last resort return if process exits
	ld (hl),b
	dec hl
	ld (hl),c
	dec hl	
	pop bc							; start address - will be returned to on yield exit
	ld (hl),b
	dec hl		; 	return address 
	ld (hl),c
	dec hl		;	push af
	ld (hl),1
	dec hl
	ld (hl),2
	dec hl		;	push bc
	ld (hl),3
	dec hl
	ld (hl),4
	dec hl		;	push de
	ld (hl),5
	dec hl
	pop bc							; arguments
	ld (hl),6
	dec hl		;	push de
	ld (hl),b
	dec hl		
	ld (hl),c
	dec hl		;	push hl
	ld (hl),0x88
	dec hl		;	push ix
	ld (hl),0x88
	ld (ix+procStackl),l				; save the stack into the process block
	ld (ix+procStackh),h
	ld a,procWaiting
	ld (ix+procState),a					; allow the process to run
	ld a,(ix+procID)				; return the process id
	ei
	ret

	;
	; Terminate this process
	; Called when a process returns after exiting from its main process loop
procTermMe:
	call procThisID				; get this process id
	call kill						; kill this process
	call procYield
	jr procTermMe				; it should never get this far
	;
	; put this process to sleep until 
	; process A exits
	; 
procWaitFor:
	di
	call procFind						; find the IX for the process
	jr nc,procWaitNone	
	push ix
	call procThisID					; get this process ID
	pop ix
	ld (ix+procWaitingID),a			; mark target process with my ID
	call procFind						; find my ix
	set 1,(ix+procFlags)				; Send this process to sleep
	ei
	call procYield					; yield and sleep
	ret

procWaitNone:
	ei
	ret							; target process does not exist

	;
	; find process ID A and return its IX
	;
procFind:
	push bc
	push de
	ld b,a
	ld e,(iy+procListl)
	ld d,(iy+procListh)				; DE points to a process
procFind1:
	ld a,e
	or d								; end of linked list?
	jr z,procFind3
	push de
	pop ix
	ld a,(ix+procID)
	cp b							; the process we'll wait for
	jr z,procFind2
	ld e,(ix+procNextl)				; to next process in the list
	ld d,(ix+procNexth)
	jr procFind1	
procFind2:
	scf								; found!
procFind3:
	pop de
	pop bc
	ret

	;
	; return a new unique procID in a
	;
procNewID:
	push ix
procNewID1:
	inc (iy+baseProcCount)
	ld a,(iy+baseProcCount)
	call procFind				; if this ID is in use, get another
	jr c,procNewID1
	ld a,(iy+baseProcCount)
	pop ix
	ret



                      	 ;
                        ; Timer interrupt
                        ; Called periodically by the CTC
                        ;
procTimerInterupt
	di
	ex af,af'
	ld a,(iy+procCount)                                         ; decrement the proc counter to eventually force priority 1
	or a
	jr z,procTimerInt1
	dec a
	ld (iy+procCount),a
procTimerInt1:
	ex af,af'
	ei
	jp procYield
		        ;
			; List the running processes
			; 	
processText: defm "ID	Name	Parent	Pri	State	Stack"
	defb 0x0a,0x0d,0
processTextMem: defm "Heap	size	top"
	defb 0x0a,0x0d,0

procIdleMsg:
	defm "Idle"
	defb 0
procWaitMsg:
	defm "Wait"
	defb 0
procExecMsg:
	defm "Exec"
	defb 0
procSleepMsg:
	defm "Sleep"
	defb 0
procTermMsg:
	defm "Term"	
	defb 0

procStateMsgs:
	defw procIdleMsg, procWaitMsg, procExecMsg, procSleepMsg, ProcTermMsg

procPS:
	ld hl,processText
	call dartPutString

	ld e,(iy+procListl)						; Follow the linked list to print each process
	ld d,(iy+procListh)

procPS1:
	ld a,e
	or d
	jp z,procPS2
	push de
	pop ix

	ld a,(ix+procID)							; process ID
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,9
	call dartPutTerm

	push ix									; Name
	pop hl
	ld de,procName
	add hl,de
	call dartPutString
	ld a,9
	call dartPutTerm

	ld a,(ix+procParentID)						; Parent ID
	call toHex
	ld a,d
	call dartPutTerm
	ld a,e
	call dartPutTerm
	ld a,9
	call dartPutTerm

	ld a,(ix+procPriority)						; priority
	call toHex
	ld a,e
	call dartPutTerm
	ld a,9
	call dartPutTerm
	
	ld e,(ix+procState)						; state
	ld d,0
	push hl
	ld hl,procStateMsgs
	add hl,de
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	call dartPutString
	pop hl

	;	call toHex
	;	ld a,e
	;	call dartPutTerm
	ld a,9
	call dartPutTerm

;	ld l,(ix+procStackl)						; stack
;	ld h,(ix+procStackh)
;	ld e,(ix+procStackOrgl)
;	ld d,(ix+procStackOrgh)
;	sbc hl,de				
	ld e,(ix+procStackOrgl)
	ld d,(ix+procStackOrgh)
	ld hl,0
stackCount:
	ld a,(de)
	or a
	inc hl
	inc de
	jr z,stackCount			
	call putTerm16

	ld a,0x0a
	call dartPutTerm	
	ld a,0x0d
	call dartPutTerm	

	ld d,(ix+procNexth)					; next entry
	ld e,(ix+procNextl)
	jp procPS1
procPS2:

	ld hl,processTextMem					; print memory stats
	call dartPutString
	ld a,9
	call dartPutTerm
	ld h,(iy+heapSizeh)
	ld l,(iy+heapSizel)
	call putTerm16
	ld a,9
	call dartPutTerm
	ld h,(iy+memToph)
	ld l,(iy+memTopl)
	call putTerm16
	ld a,0x0a
	call dartPutTerm	
	ld a,0x0d
	call dartPutTerm	
	ret

	;
	; Return this processes ID in a
	;
procThisID:
	push de
	push ix
	ld e,(iy+procListl)
	ld d,(iy+procListh)				; DE points to a process
procThis1:
	ld a,e
	or d								; end of linked list?
	jr z,procThis3
	push de
	pop ix
	ld a,(ix+procState)
	cp procExecuting					; find our process
	jr z,procThis2
	ld e,(ix+procNextl)				; to next process in the list
	ld d,(ix+procNexth)
	jr procThis1		
procThis2:
	ld a,(ix+procID)
procThis3:
	pop ix
	pop de
	ret

procFindParentID
	call procThisID
	call procFind
	ld a,(ix+procParentID)
	ret
	;
	; Kill a process with a = process ID

kill:
	push ix
	push bc
	push hl
;	call debugProc
;	call debugHeap
	ld c,a
	ld l,(iy+procListl)					; skip through the linked list and find our process	
	ld h,(iy+procListh)
killNext:
	ld a,l
	or h
	jr z,killEnd						; end of list found
	push hl
	pop ix
	ld a,(ix+procID)					; is this the one to be killed?
	cp c
	jr z,killFound
	ld l,(ix+procNextl)
	ld h,(ix+procNexth)				; to next item on linked list
	jr killNext
killFound:
	ld (ix+procFlags),1				; mark it to die
killEnd:
;	call debugProc
;	call debugHeap
	pop hl
	pop bc
	pop ix
	ret

	;
	; Count the children for a given process A
	;
procNumChildren:
	push ix
	push de
	push bc
	ld b,0						; counter
	ld c,a						; proc id to match
	ld e,(iy+procListl)					; skip through the linked list 
	ld d,(iy+procListh)				; and count processes with matching parents
procNumNext:
	ld a,e
	or d
	jr z,procNumEnd					; end of list found
	push de
	pop ix
	ld e,(ix+procNextl)
	ld d,(ix+procNexth)				; to next item on linked list	
	ld a,(ix+procParentID)				; is this a child?
	cp c
	jr nz,procNumNext	
	inc b
	jr procNumNext
procNumEnd:
	ld a,b
	pop bc
	pop de
	pop ix
	ret


debugProc:
	push hl
	push ix
	push af
	ld l,(iy+procListl)
	ld h,(iy+procListh)				; DE points to a process
debugProc1:
	ld a,h
	or l								; end of linked list?
	jr z,debugProc3
	ld a,h
	cp 0x20
	jr nc,debugproc4
	call debugRegisters
	jr debugProc3
debugProc4:
	push hl
	pop ix
	ld a,' '
	call dartPutTerm
	call PutTerm16
	ld a,' '
	call dartPutTerm
	ld l,(ix+procID)
	ld h,0
	call PutTerm16
	ld a,0x0a
	call dartPutTerm
	ld a,0x0d
	call dartPutTerm
	ld l,(ix+procNextl)				; to next process in the list
	ld h,(ix+procNexth)
	jr debugProc1		
debugProc3:
	;call debugDelay
	pop af
	pop ix
	pop hl
	ret
























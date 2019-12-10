;
;
; Device super class

devNextl	equ 0
devNexth	equ 1
devName0	equ 2
devName1	equ 3
devName2	equ 4
devData1	equ 5
devCreatel	equ 6
devCreateh	equ 7
devFormatl	equ 8
devFormath	equ 9
devReadl	equ 0x0a
devReadh	equ 0x0b
devWritel	equ 0x0c
devWriteh	equ 0x0d
devDeletel	equ 0x0e
devDeleteh	equ 0x0f
devDefaultBlockl	equ 0x10
devDefaultBlockh	equ 0x11

devSize 		equ 0x12
	;
	; Initialize the devices list
	;
devInit:
	ld (iy+devL), 0
	ld (iy+devh), 0
	ret
	;
	; Create a new device
	;
devNew:
	push af
	push de
	push hl
	push iy
	pop hl
	ld de,devL
	add hl,de			; find the next empty slot

devNew1:
	ld e,(hl)				; get the next pointer
	inc hl
	ld d,(hl)
	dec hl

	ld a,d
	or e					; null?
	ex de,hl
	jr nz,devNew1

	ld hl,devSize			; make a new one and add it on the end
	call mallocBlock
	ld a,l
	ld (de),a
	inc de
	ld a,h
	ld (de),a

	push hl
	pop ix				; return it in IX
	pop hl
	pop de
	pop af
	ret

	; find device named hl
devFind:	
	push de
	push hl				; null terminated string
	push iy
	pop hl
	ld de,devL
	add hl,de			; start of device linked list
devFind1:		
	ld e,(hl)				; loop down the list looking for a matching device by name
	inc hl
	ld d,(hl)
	ld a,e
	or d
	pop hl				; name we're looking for
	push hl
	jr z,devNotFound		; end of list

	inc de
	inc de				; to name
	call strcmp
	dec	de
	dec de
	jr z,devFound
	ex de,hl
	jr devFind1

devNotFound:
	and 0	
	pop hl
	pop de
	ret					; not found - z flag set
devFound:
	push de
	pop ix				; return ix pointing to device
	or 1	
	pop hl	
	pop de
	ret					; found - nz flag

devCreate:
	push hl
	ld l,(ix+devCreatel)
	ld h,(ix+devCreateh)
	ex (sp),hl
	ret


devFormat:
	push hl
	ld l,(ix+devFormatl)
	ld h,(ix+devFormath)
	ex (sp),hl
	ret


devRead
	push hl
	ld l,(ix+devReadl)
	ld h,(ix+devReadh)
	ex (sp),hl
	ret

devWrite:
	push hl
	ld l,(ix+devWritel)
	ld h,(ix+devWriteh)
	ex (sp),hl
	ret

devDelete:
	push hl
	ld l,(ix+devDeletel)
	ld h,(ix+devDeleteh)
	ex (sp),hl
	ret

	; List the devices available and some kind of status
devList:
	push iy
	pop hl
	ld de,devL
	add hl,de			; hl - start of linked list
devList1:		
	ld e,(hl)				; next device block
	inc hl
	ld d,(hl)
	ld a,e
	or d
	ret z				; end of list
	push de
	inc de
	inc de				; to name field
	ex de,hl
	call dartPutString
	call putCRLF
	pop hl
	jr devList1






















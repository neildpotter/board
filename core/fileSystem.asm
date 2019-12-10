; File
; simple file system with file names using a block device


fileRootDevice:					; device to create root of file system
	defm "R2"
	defb 0,0



; initialize the file system

;fileHandle: structure
fhPtrl			equ 0		; buffer pointer
fhPtrh			equ 1
fhPos			equ 2		; 1 byte current offset position in buffer
fhType			equ 3		; D dir F file M mount
fhSize			equ 4		; number of file bytes, number of directory entries
fhMode			equ 5		; 0 = read, 1 = write
fhBlockl			equ 6		; current block being accessed
fhBlockh		equ 7
fhDevice0		equ 8		; 4 byte current device name currently accessed
fhDevice1		equ 9
fhDevice2		equ 10
fhDevice3		equ 11
fhDirl			equ 12		; directory linked list
fhDirh			equ 13		; 
fhNextBlockl		equ 14 		; value of the next block
fhNextBlockh	equ 15
fhMountDev0	equ 16		; values of a mount parsed
fhMountDev1	equ 17
fhMountDev2	equ 18
fhMountDev3	equ 19
fhMountBlockl	equ 20
fhMountBlockh	equ 21
fhFlags			equ 22		; 0 path or file find
fhCount			equ 23
fhFilePart		equ 24		; filename len buffer for the part of the file name
fileHandleSize equ	34 		; bytes

fileNameLen		equ	8		; Directory sizes
fileBlockNumLen	equ 2		; file blocks numbers are two bytes

; file block structure




fileInit:
	ld hl,fileRootDevice			; see if the device exists, if not create it
	call devFind
	jr nz,fileInit1
	ld a,2						; make a ram disk device on RAM chip
	call rdInit	
fileInit1:
	ld a,(ix+devDefaultBlockl)
	ld (iy+fhRootBlockl),a			; start of ram disk 
	ld a,(ix+devDefaultBlockh)
	ld (iy+fhRootBlockh),a
	ld hl,fileRootDevice
	ld a,(hl)
	ld (iy+fhRootDevice0),a
	inc hl
	ld a,(hl)
	ld (iy+fhRootDevice1),a
	inc hl
	ld a,(hl)
	ld (iy+fhRootDevice2),a
	inc hl
	ld a,(hl)
	ld (iy+fhRootDevice3),a
	ret
	
			; Format a device
			; hl = device name
fileFormat:
	push hl	
	call devFind
	ld a,errFileNoDevice 
	jr z,fileFormatErr						; device not found
	call devFormat
	ld a,errFileFormatError
	jr nc,fileFormatErr					; write the root directory
	call devCreate						; allocate the first block
	ld a,errFileFull
	jr nc,fileFormatErr
	call fhNew
	ld (ix+fhBlockl),e
	ld (ix+fhBlockh),d

	push ix
	pop hl
	ld de,fhDevice0
	add hl,de

	ex de,hl
	pop hl								; device name

	call strcpy							; copy device name to fh

	ld (ix+fhType), 'D'	
	call fhUpdate						; update the buffer
	call fhWrite							; write to storage
	ret

fileFormatErr:
	pop hl
	call errPrint
	ret

	; Open a file for read or write.
	;  - read - find the file and position at the beginning
	; - write - find the file and position at the end, or create the file
	; hl - filename
	; b = mode - 0 = read, 1 = write, 3 = append
	; returns ix = fh or null, C = file, NC = no file 
fileOpen:
	push bc
	push de
	call fhNew						; start a filehandle
	ld (ix+fhMode),b
	push hl
	push bc
	call fhFindPath					; does the file exist?
	pop bc

	jr nc,fileOpenNotFound
	ld a,b
	cp 0							; read mode
	jr z,fileOpenRead

	cp 1							; write with no append
	ld a,errFileExists
	jr z,fileOpenError
	;								; existing file open for write - append
fileOpenWrite1:
	ld d,(ix+fhNextBlockh)				; advance to last block in file
	ld e,(ix+fhNextBlockl)
	ld a,d
	or e
	jr z,fileOpenWrite2
	ld (ix+fhBlockl),e
	ld (ix+fhBlockh),d
	call fhRead
	ld a,errFileRead
	jr nc,fileOpenError
	call fhParse
	jr fileOpenWrite1
fileOpenWrite2:
	ld a,(ix+fhSize)					; Now advance to end of file
	ld (ix+fhPos),a
	pop hl
	pop de
	pop bc
	scf
	ret

fileOpenRead:
	pop hl
	pop de
	pop bc
	scf								; success
	ret	

fileOpenNotFound:
	ld a,b
	cp 0							; if read mode and file not found, bail
	ld a,errFileNotFound
	jr z,fileOpenError

	set 0,(ix+fhFlags)					; write mode - consider creating the file
	pop hl
	push hl							; file name
	call fhFindPath
	ld a,errFileDirNotFound
	jr nc,fileOpenError				; path not found

	pop hl							; create a file
	call fhMakeNewDirEntry				; make a new entry and add it to the directory

	ld (ix+fhType),'F'						; new entry is a File
	ld (ix+fhSize),0						; and its empty
	call fhUpdate						; build the buffer for the sub dir
	call fhWrite							; write the buffer to storage
	ld a,errFileWrite
	jr nc,fileOpenError1
	pop de
	pop bc
	scf
	ret

fileOpenError:
	pop hl
	pop de
	pop bc
fileOpenError1:
	call errPrint
	call fhDestroy
	and a							; file not found
	ret	

	; write to an open file
	; ix = filehandle
	; hl = buffer
	; b = number of bytes
fileWrite:
	push hl
fileWriteLoop:
	ld a,(ix+fhMode)					; 0 = read, 1 = write
	or a				
	ld a,errFileWrite		
	jr z,fileWriteError
	ld a,ramBlockSize-4				; minus block, type and size
	sub (ix+fhPos)					; calculate how many bytes remain on this block
	ld c,a
	call fhGetPosIndex				; compute a pointer to the current point in buffer
fileWrite1:
	ld a,c
	or a
	jr z,fileWrite2						; out of space on this block
	ld a,b
	or a
	jr z,fileWriteEnd					; nothing more to copy
	ld a,(hl)							; input buffer
	ld (de),a							; file buffer
	inc hl
	inc de
	dec b
	dec c
	inc (ix+fhPos)					; buffer moved along
	inc (ix+fhSize)					; size extended
	jr fileWrite1
fileWrite2:
	push hl
	push de							; get another block
	push bc
	push ix
	pop hl
	ld de,fhDevice0
	add hl,de
	push ix
	call devFind
	call devCreate					; create a new empty block in storage on the same device
	pop ix
	ld a,errFileFull
	jr nc,fileWriteError1
	ld (ix+fhNextBlockl),e				; record the new block's number in this block
	ld (ix+fhNextBlockh),d
	push de
	call fhUpdate					; write blocks & sizes to the buffer
	call fhWrite						; write the block to storage
	ld a,errFileWrite
	jr nc,fileWriteError2
	call fhClean						; clear the buffer and set the position to 0
	pop de
	ld (ix+fhBlockl),e					; point to the new block
	ld (ix+fhBlockh),d
	pop bc
	pop de
	pop hl
	jr fileWriteLoop					; loop to write the remaining buffer
fileWriteEnd:
	pop hl
	scf								; success
	ret

fileWriteError2:
	pop de
fileWriteError1:
	pop bc
	pop de
	pop hl
fileWriteError:
	call errPrint
	pop hl
	and a							; fail
	ret

	; read from an open file
	; ix = filehandle
	; hl = buffer
	; b = number of bytes to read
	; output  = number bytes read, C = EOF

fileRead:
	push hl
	ld (ix+fhCount),0					; number of bytes read
fileRead0:
	ld a,(ix+fhSize)					; total size on block
	sub (ix+fhPos)					; calculate how many bytes remain on this block
	ld c,a
	call fhGetPosIndex				; compute a pointer to the current point in buffer
fileRead1:
	ld a,b
	or a
	jr z,fileReadEnd					; nothing more to copy
	ld a,c
	or a
	jr z,fileRead2						; ran to the end on this block

	ld a,(de)							; file buffer
	ld (hl),a							; output buffer
	inc hl
	inc de
	dec b
	dec c
	inc (ix+fhPos)					; buffer moved along
	inc (ix+fhCount)					; number of bytes read
	jr fileRead1
fileRead2:							; end of block. Load up the next block
	push hl
	push de							; get another block
	push bc
	ld e,(ix+fhNextBlockl)
	ld d,(ix+fhNextBlockh)
	ld a,e
	or d
	jr z,fileReadEOF
	ld (ix+fhBlockl),e					; get the next block
	ld (ix+fhBlockh),d
	call fhClean						; clear the buffer and set the position to 0
	call fhRead						; read the next block from storage
	ld a,errFileRead
	jr nc,fileReadError
	call fhParse						; 
	pop bc
	pop de
	pop hl
	jr fileRead0						; loop to read from the remaining buffer
fileReadEOF:
	pop bc
	pop de
	pop hl
fileReadEnd:
	ld b,(ix+fhCount)					; return number of bytes
	scf								; success
	pop hl
	ret

fileReadError:
	call errPrint
	pop bc
	pop de
	pop hl
	and a							; failed
	ld b,0
	pop hl
	ret	

	; close a file and discard the file handle
	; ix = filehandle
fileClose:
	ld a,(ix+fhMode)
	or a								; read - just close it
	jr z,fileClose1
	call fhUpdate
	call fhWrite						; flush the file
	ld a,errFileWrite
	call nc,errPrint
fileClose1:
	call fhDestroy					; dump the file handle
	ret

	; file delete
	; find the path to a file, remove it from the directory and free all its blocks
	; hl = path
fileDelete:
	call fhNew
	set 0,(ix+fhFlags)					; find the path to the file
	call fhFindPath
	ld a,errFileNotFound
	jr nc,fileDeleteError
	ld a,(ix+fhType)					; better be a directory
	cp 'D'
	ld a,errFileNotAFile
	jr nz,fileDeleteError
	call fhFindDirItem				; match the file in the filepart to the directory
	ld a,h							; TODO check the directory item is a file before doing this!!!
	or l
	ld a,errFileNotFound
	jr z,fileDeleteError					
	push hl							; found the entry. Delete the filepart and write it back to the storage 
	ld de,FileNameLen+2				; linked list pointers
	add hl,de
	ld e,(hl)							; block number of start of the file
	inc hl
	ld d,(hl)
	pop bc							; dir entry
	push de							; file block number
	call fhRemDirItem				; remove item BC from the dir list
	call fhUpdate					; write the directory back to the buffer
	call fhWrite						; update the store
	pop de

fileDeleteLoop:
	call fhClean						; free up the blocks occupied by the file
	ld (ix+fhBlockl),e
	ld (ix+fhBlockh),d
	call fhRead
	ld a,errFileRead
	jr nc,fileDeleteError
	call fhParse
	call fhDelete						; free the block
	ld e,(ix+fhNextBlockl)
	ld d,(ix+fhNextBlockh)
	ld a,e
	or d
	jr nz,fileDeleteLoop
	ret

fileDeleteError:
	call errPrint
	ret

	; return the size of the data in a file
	; hl - path
	; returns BC - size, C success, NC fail
fileSize
	push hl
	call fhNew
	call fhFindPath					; find the file and parse first block
	ld hl,0							; file size counter
	push hl
	jr nc,fileSizeEnd					; not found
fileSizeLoop:
	ld c,(ix+fhSize)
	ld b,0
	pop hl
	add hl,bc						; add the size of this block
	push hl
	ld d,(ix+fhNextBlockh)				; advance to next block in file
	ld e,(ix+fhNextBlockl)
	ld a,d
	or e
	jr z,fileSizeEnd1					; end of file
	ld (ix+fhBlockl),e
	ld (ix+fhBlockh),d
	call fhRead						; read and parse it
	call fhParse
	jr fileSizeLoop
fileSizeEnd1:
	scf								; success
fileSizeEnd:
	call fhDestroy					; drop the file handler
	pop bc
	pop hl
	ret


	; dir delete
	; find the path to a dir, remove it from its parent directory if its empty
	; hl = path
dirDelete:
	call fhNew
	push hl
	call fhFindPath					; find the path to the directory
	pop hl
	ld a,errFileDirNotFound
	jr nc,fileDeleteError
	ld a,(ix+fhType)
	cp 'D'
	jr nz,dirDelete1					; its not a directory
	ld a,(ix+fhSize)					; number of files in said directory
	or a
	ld a,errFileDirNotEmpty
	jr nz,fileDeleteError
	jr dirDelete2						; good to go
dirDelete1:
	cp 'M'
	call debugRegisters
	ld a,errFileDirNotFound
	jr nz,fileDeleteError				; can delete mounts here
dirDelete2:
	call fhDestroy
	jp fileDelete						; so now its just a file to delete
	


	; compute DE to point to the buffer's next position
	; ix = filehandle
fhGetPosIndex:
	push hl
	ld l,(ix+fhPtrl)					; buffer
	ld h,(ix+fhPtrh)
	ld e,(ix+fhPos)					; position in buffer
	ld d,0
	inc de							; next pointerl
	inc de							; next pointerh
	inc de							; size
	inc de							; type
	add hl,de
	ex de,hl							; de = index to buffer
	pop hl
	ret

	; file handle class
	; create a new filehandle
	; return ix = filehandle 
fhNew:
	push hl
	ld hl,fileHandleSize
	call malloc
	push hl
	pop ix
	ld hl,ramBlockSize				; make a buffer
	call malloc
	ld (ix+fhPtrl),l
	ld (ix+fhPtrh),h
	ld (ix+fhFlags),0					; by default, find to file
	pop hl
	ret

	; destroy a filehandle
	; ix = filehandle
fhDestroy:
	push af
	push hl
	push de
	ld l,(ix+fhPtrl)					; free the buffer
	ld h,(ix+fhPtrh)
	call free
	ld l,(ix+fhDirl)					; free the entries on the directory linked list
	ld h,(ix+fhDirh)		
fhDestroy1:
	ld a,l
	or h
	jr z,fhDestroy2
	ld e,(hl)							; get next pointer before freeing it
	inc hl
	ld d,(hl)
	dec hl
	call free
	ex de,hl
	jr fhDestroy1

fhDestroy2:
	push ix
	pop hl
	call free							; free the file handler block itself
	pop de
	pop hl
	pop af
	ret

	; clear the directory and buffer from fh
	; ix = filehandle
fhClean:
	push hl
	push de
	push bc
	ld l,(ix+fhDirl)					; free the entries on the directory linked list
	ld h,(ix+fhDirh)		
fhClean1:
	ld a,l
	or h
	jr z,fhClean2
	ld e,(hl)							; get next pointer before freeing it
	inc hl
	ld d,(hl)
	dec hl
	call free
	ex de,hl
	jr fhClean1
fhClean2:
	ld (ix+fhDirl),0
	ld (ix+fhDirh),0
	ld (ix+fhPos),0
	ld (ix+fhSize),0
	ld (ix+fhNextBlockh),0
	ld (ix+fhNextBlockl),0
	ld l,(ix+fhPtrl)
	ld h,(ix+fhPtrh)
	ld b,ramBlockSize
fhClean3:
	ld (hl),0
	inc hl
	djnz fhClean3
	ld de,fhFilePart					; clean out the fhFilePart buffer
	push ix
	pop hl
	add hl,de
	ld b, fileNameLen
fhClean4:
	ld (hl),0
	inc hl
	djnz fhClean4
	pop bc
	pop de
	pop hl
	ret


	;
	; Parse the current block in the buffer and set variables
	; ix = file handle pointer
fhParse:
	push hl
	push de
	push bc
	ld l,(ix+fhPtrl)					; get the pointer to the buffer
	ld h,(ix+fhPtrh)

	ld e,(hl)							; get the next block pointer
	inc hl
	ld d,(hl)
	inc hl
	ld (ix+fhNextBlockl),e
	ld (ix+fhNextBlockh),d
	
	ld a,(hl)							; get data size
	inc hl
	ld (ix+fhSize),a
	ld a,(hl)							; get the type				
	inc hl
	ld (ix+fhType),a
fhParse1:
	push hl
	push af
	ld l,(ix+fhDirl)					; free any entries on the directory linked list
	ld h,(ix+fhDirh)		
fhParse2:
	ld a,l
	or h
	jr z,fhParse3
	ld e,(hl)							; get next pointer before freeing it
	inc hl
	ld d,(hl)
	dec hl
	call free
	ex de,hl
	jr fhParse2
fhParse3:
	pop af
	pop hl							; initialize other attributes
	ld (ix+fhDirl),0					; dont do this or we'll lose track of memory items
	ld (ix+fhDirh),0
	cp 'D'							; is this a directory?
	jr nz,fhParseNext
	ld b,(ix+fhSize)					; size is the number of directory entries
fhParseDir:
	ld a,b
	or a
	jr z,fhParseEnd					; while there are directories
	push bc
	push hl							; buffer pointer

	call fhAddDirItem
	ex de,hl							; directory item to DE
	pop hl
	inc de							; advance past link list pointer
	inc de
	ld bc,fileNameLen+fileBlockNumLen
	ldir
	pop bc
	djnz fhParseDir
	jr fhParseEnd
fhParseNext:
	cp 'M'							; is this a mount?
	jr nz,fhParseEnd

	ld a,(hl)							; 
	ld (ix+fhMountDev0),a
	inc hl
	ld a,(hl)							; 
	ld (ix+fhMountDev1),a
	inc hl
	ld a,(hl)							; 
	ld (ix+fhMountDev2),a
	inc hl
	ld a,(hl)							;
	ld (ix+fhMountDev3),a
	inc hl
	ld a,(hl)							; copy block from mount
	ld (ix+fhMountBlockl),a
	inc hl
	ld a,(hl)							
	ld (ix+fhMountBlockh),a
fhParseEnd:
	pop bc
	pop de
	pop hl
	ret

	; update
	; write values from the fileheader to the buffer

fhUpdate:
	push hl
	push de
	push bc
	ld l,(ix+fhPtrl)					; get the pointer to the buffer
	ld h,(ix+fhPtrh)

	ld e,(ix+fhNextBlockl)
	ld d,(ix+fhNextBlockh)
	ld (hl),e							; set the next block pointer
	inc hl
	ld (hl),d
	inc hl

	ld e,(ix+fhSize)
	ld (hl),e							; set data size
	inc hl

	ld a,(ix+fhType)					; set the type
	ld (hl),a
	inc hl
	cp 'D'							; if a directory, re-write the structure from the linked list
	jr nz,fhUpdate1
	ex de,hl							; de now points to the buffer
	push de
	pop hl
	ld b,ramBlockSize-4				; next pointer, type, size
fhUpdateDir0:						; clear out the buffer as it will only be directories
	ld (hl),0
	inc hl
	djnz fhUpdateDir0

	ld l,(ix+fhDirl)
	ld h,(ix+fhDirh)
	ld b,0							; count the directories
fhUpdateDir:
	ld a,l
	or h
	jr z,fhUpdateDir1					; for each entry, write the name and block number to the buffer
	push bc
	ld c,(hl)
	inc hl
	ld b,(hl)							; next pointer
	inc hl
	push bc

	ld bc,fileNameLen+fileBlockNumLen		; data length
	ldir
	pop hl
	pop bc
	inc b
	jr fhUpdateDir
fhUpdateDir1:
	ld l,(ix+fhPtrl)					; get the pointer to the buffer
	ld h,(ix+fhPtrh)
	inc hl
	inc hl
	ld (hl),b							; size = number of directories
	jr fhUpdateEnd
fhUpdate1
	cp 'M'							; if a mount write device and block
	jr nz,fhUpdateEnd
	ld a,(ix+fhMountDev0)	
	ld (hl),a
	inc hl
	ld a,(ix+fhMountDev1)
	ld (hl),a
	inc hl
	ld a,(ix+fhMountDev2)
	ld (hl),a
	inc hl
	ld a,(ix+fhMountDev3)
	ld (hl),a
	inc hl
	ld a,(ix+fhMountBlockl)
	ld (hl),a
	inc hl			
	ld a,(ix+fhMountBlockh)
	ld (hl),a
fhUpdateEnd:
	pop bc
	pop de
	pop hl
	ret

	; set the filehandle to a type D - directory, F - file, M - mount
	; ix = filehandle
fhSetType:
	ld (ix+fhType),'D'				; becomes a directory
	ret

	; Add an entry to the directory structure
	; ix = filehandle
	; returns hl = directory item
fhAddDirItem:
	push de
	push ix
	pop hl
	ld de,fhDirl
	add hl,de					; hl is **list

fhAddDirItem1:
	ld e,(hl)						; find the end of the linked list
	inc hl
	ld d,(hl)
	dec hl

	ld a,e
	or d
	jr z,fhAddDirItem2					; found the end

	ex de,hl
	jr fhAddDirItem1

fhAddDirItem2:
	ex de,hl
	ld hl,fileNameLen+fileBlockNumLen+2		; item len + next pointer
	call malloc
	ex de,hl
	ld (hl),e							; link the new entry
	inc hl
	ld (hl),d
	ex de,hl							; return the item
	pop de
	ret

	; Remove an entry to the directory structure
	; ix = filehandle
	; bc = item to remove
fhRemDirItem:
	push ix
	pop hl
	ld de,fhDirl
	add hl,de					; hl is **list

fhRemDirItem1:
	ld e,(hl)						; find the item in the linked list
	inc hl
	ld d,(hl)
	dec hl

	ld a,e
	or d
	jr z,fhAddDirItem2			; found the end

	ex de,hl
	ld a,b
	cp h
	jr nz,fhRemDirItem1
	ld a,c
	cp l
	jr nz,fhRemDirItem1			; not the item we're looking for		

	ld a,(hl)						; unlink (copy the item's next pointer to the previous's pointer)
	ld (de),a
	inc hl
	inc de
	ld a,(hl)
	ld (de),a

	dec hl						; free up the item
	call free	

fhRemDirItem2:
	ret

	; Find a file item - return the item who's filename matches the file part
	; ix - filehandler
	; returns HL = item, or null
fhFindDirItem:
	push ix
	pop hl
	ld de,fhDirl
	add hl,de					; hl is **list
	push hl
	push ix
	pop hl
	ld de,fhFilePart
	add hl,de
	push hl
	pop bc						; file part
	pop hl						; dir linked list
fhFindDirItem1:
	ld e,(hl)						; next item in the list
	inc hl
	ld d,(hl)
	ld a,e
	or d
	jr z,fhFindDirItemEnd			; found the end

	ex de,hl						; hl is the item
	push hl
	inc hl
	inc hl
	push bc						; does the item filename HL match the file part BC
	ld e,fileNameLen
fhFindDirItem2:
	ld a,(bc)						
	cp (hl)
	jr nz,fhFindDirItem3			; no match
	or a
	jr z,fhFindDirItem3			; end of name and they match
	inc hl
	inc bc
	dec e
	jr nz,fhFindDirItem2			; next character
fhFindDirItem3:
	pop bc
	pop hl
	jr nz,fhFindDirItem1			; try next item
	ret							; return item
fhFindDirItemEnd:				; item not found
	ld hl,0
	ret

	; Write an file entry to a file dir item
	; hl - item
	; de - name
	; bc - block number
fhWriteDir:
	inc hl
	inc hl
	ex de,hl
	push bc
	ld bc,fileNameLen
	ldir
	pop bc
	ex de,hl
	ld (hl),c						; block number
	inc hl
	ld (hl),b
	ret

	; find the device /block indicated by the end of file path. Point the fh at the start block for that path
	; hl = path
	; ix = filehandler		fhFlags - 0 find to filename, 1 find to pathname
	; c = found, nc = not found
fhFindPath:
	call fhSetRoot
	call fhRead					; read the root block
	jp z,fhFindFail
	call fhParse					; parse and set indicators into fh
fhFindPathLoop:
	call fhTokenizePath
	jr nc,fhFindPathEnd			; there was no token

	bit 0,(ix+fhFlags)				; if looking for a path only, don't consider the filename
	jr z,fhFindPathLoop0
	ld a,e
	or d
	jr z,fhFindPathEnd			; looking for path only

fhFindPathLoop0:
	push de						; keep the file path as we work down it
	ld a,(ix+fhType)
	cp 'D'						; is this a directory?
	jr nz,fhFindPathLoop1

	call fhFindDirItem			; find the dir item matching the file part
	ld a,h
	or l
	jr z,fhFindFail1
	ld de,fileNameLen+2			; linked list header
	add hl,de
	ld a,(hl)						; get the block number
	ld (ix+fhBlockl),a
	inc hl
	ld a,(hl)						; get the block number
	ld (ix+fhBlockh),a
	jr fhFindNext
fhFindPathLoop1:
	cp 'M'						; is this a mount? Should never happen
	jr nz,fhFindPathLoop2
	jr fhFindFail1
fhFindPathLoop2:
	cp 'F'
	jr nz,fhFindFail1
fhFindNext:
	call fhRead					; read the block to the buffer
	jr z,fhFindFail1	

	call fhParse
	ld a,(ix+fhType)				; if this is a mount, change devices immediately - never return a mount
	cp 'M'						; is this a mount?
	jr nz,fhFindNext1
	ld a,(ix+fhMountDev0)			; copy the device from the mount to follow it
	ld (ix+fhDevice0),a
	ld a,(ix+fhMountDev1)	
	ld (ix+fhDevice1),a
	ld a,(ix+fhMountDev2)	
	ld (ix+fhDevice2),a
	ld a,(ix+fhMountDev3)
	ld (ix+fhDevice3),a
	ld a,(ix+fhMountBlockl)		; copy the block from the mount to follow it
	ld (ix+fhBlockl),a
	ld a,(ix+fhMountBlockh)
	ld (ix+fhBlockh),a
	call fhRead					; read the block to the buffer
	jr z,fhFindFail1	
	call fhParse
fhFindNext1
	pop hl
	ld a,h
	or l
	jr z,fhFindPathEnd			; no more tokens to consider
	jr fhFindPathLoop

fhFindFail1:
	pop hl

fhFindFail:
	and 0
	ret
fhFindPathEnd:
	scf
	ret

	; make a directory at path
	; ix = filehandle
	; hl = path
fhRootFilePath: defb '/',0					; the root path

fhMakeDir:

	push hl
	set 0,(ix+fhFlags)						; search to parent directory, not the new dir we want to make
	call fhFindPath
	jr nc,fhMakeDirError			

	pop hl
	call fhMakeNewDirEntry				; make a new entry and add it to the directory

	; make a file and enter it into the directory
	; ix - filehandle pointing to the directory
	; hl - path

	ld (ix+fhType),'D'						; new sub directory is a directory
	ld (ix+fhSize),0						; and its empty
	call fhUpdate						; build the buffer for the sub dir
	call fhWrite							; write the buffer to storage
	ret


fhMakeNewDirEntry:
	call fhGetFileName					; get last part of the path to DE
	call fhAddDirItem						; add the new block to the parent dir
	inc hl
	inc hl								; past the linked list header
	push hl
	ex de,hl
	call strcpy							; copy the filename into the item
	pop hl
	ld de,fileNameLen
	add hl,de
	push hl								; pointer to fileDir block number
	
	push ix								; find the device for this new dir
	push ix
	ld de,fhDevice0
	pop hl
	add hl,de							; device offset name
	call devFind						
	call devCreate						; create a new block on the device for the new dir in DE

	pop ix								; back to fh again
	pop hl								; dir item
	ld (hl),e
	inc hl
	ld (hl),d								; copy block number
	push de
	call fhUpdate						; write the parent dir changes to buffer
	call fhWrite							; update storage

	call fhClean							; clear the parent directory stuff out
	pop de

	ld (ix+fhblockl),e
	ld (ix+fhblockh),d
	ret

fhDevNoDir:
	defm "Dir Not Found"
	defb 0x0a,0x0d,0

fhMakeDirError:

	ld hl,fhDevNoDir
	call dartPutString
	pop hl
	ret

	; mount a device to the file system by creating a mount object as a file
	; ix - filehandle
	; hl = path to make mount
	; de = device to mount

fhMount:
	push de
	push ix
	push hl
	ex de,hl							; check the device exists
	call devFind							; 
	jr z,fhMountNoDev

	ld c,(ix+devDefaultBlockl)			; get the default block for the device
	ld b,(ix+devDefaultBlockh)
	pop hl
	pop ix							; path and fh
	push bc
	call fhMakeDir

	pop bc
	pop de							; get device and block
	ld (ix+fhMountBlockl),c			; start block for the device
	ld (ix+fhMountBlockh),b
	ld (ix+fhType),'M'
	ld a,(de)
	ld (ix+fhMountDev0),a			; copy device and default block
	inc de
	ld a,(de)
	ld (ix+fhMountDev1),a
	inc de
	ld a,(de)
	ld (ix+fhMountDev2),a
	inc de
	ld a,(de)
	ld (ix+fhMountDev3),a
	call fhUpdate
	call fhWrite						; write the mount to the device
	ret

fhNoDevMsg:
	defm "No Device"
	defb 0x0a,0x0d, 0

fhMountNoDev:
	pop de
	pop hl
	ld hl,fhNoDevMsg
	call dartPutString
	pop ix
	ret



	; print a directory from path
 	; hl = path

fhDirRoot:	defb '/',0

fhDir:
	ld a,h
	or l
	jr nz,fhDir2
	ld hl,fhDirRoot
fhDir2:
	call fhNew						; Create a filehandle
	call fhFindPath					; go to the path
	jr nc,fhDirError	
	call fhGetFilePart					; print the objects name
	ld c,0							; directory level indentation
	call fhPrintDirectory
	call fhDestroy
	ret
fhDirMsg 	defm "Path Not Found"	
	defb 0x0a,0x0d,0
fhDirError:
	ld hl,fhDirMsg
	call dartPutString
	ret
	
fhPrintDirectory:
	push bc
	ld a,(ix+fhType)
	cp 'D'							; is this a directory?
	jr nz,fhPrintDirectoryNext
	push ix							; get the dir linked list
	pop hl
	ld de,fhDirl
	add hl,de
fhPrintDirLoop:

	ld e,(hl)							; traverse the linked list
	inc hl
	ld d,(hl)
	ld a,e
	or d
	jp z,fhPrintDirectoryEnd			; end of linked list
	push bc
	ex de,hl
	push hl
	push ix
	inc hl
	inc hl
	ld b,c
fhPrintDirTabs:
	ld a,b
	or a
	jr z,fhPrintDirTabs2
	ld a,' '
	call dartPutTerm
	djnz fhPrintDirTabs
fhPrintDirTabs2:
	ld a,'/'
	call dartPutTerm
	call dartPutString					; print the sub-directory name

	call putCRLF
	ld de,fileNameLen
	add hl,de						; advance to block number
	ld e,(hl)
	inc hl
	ld d,(hl)							; block number
	push de
	push ix							; copy the device name
	pop hl
	ld de,fhDevice0
	add hl,de
	call fhNew
	ld a,(hl)							; old device name
	ld (ix+fhDevice0),a
	inc hl
	ld a,(hl)							; old device name
	ld (ix+fhDevice1),a
	inc hl
	ld a,(hl)							; old device name
	ld (ix+fhDevice2),a
	inc hl
	ld a,(hl)							; old device name
	ld (ix+fhDevice3),a
	pop de
	ld (ix+fhBlockl),e					; add the block number
	ld (ix+fhBlockh),d
	call fhRead

	call fhParse

	inc c							; indent for next level 4 spaces
	inc c
	inc c
	inc c
	call fhPrintDirectory				; recursive
	call fhDestroy
	pop ix
	pop hl
	pop bc
	jr fhPrintDirLoop
fhPrintDirectoryNext:
	cp 'M'							; is this a mount?
	jr nz,fhPrintDirectoryEnd

	push ix
	push bc
	ld d,(ix+fhMountDev0)			; copy the device from the mount to follow it
	ld e,(ix+fhMountDev1)	
	ld h,(ix+fhMountDev2)	
	ld l,(ix+fhMountDev3)
	ld b,(ix+fhMountBlockl)		; copy the block from the mount to follow it
	ld c,(ix+fhMountBlockh)
	call fhNew
	ld (ix+fhDevice0),d
	ld (ix+fhDevice1),e
	ld (ix+fhDevice2),h
	ld (ix+fhDevice3),l
	ld (ix+fhBlockl),b
	ld (ix+fhBlockh),c
	call fhRead
	call fhParse
	pop bc
	call fhPrintDirectory
	call fhDestroy
	pop ix
fhPrintDirectoryEnd:
	pop bc
	ret








	; set the root block and root device from IY
	; ix = filehandle
fhSetRoot:
	ld a,(iy+fhRootBlockl)				; set the root file system block and device
	ld (ix+fhBlockl),a		
	ld a,(iy+fhRootBlockh)
	ld (ix+fhBlockh),a	
	ld a,(iy+fhRootDevice0)
	ld (ix+fhDevice0),a	
	ld a,(iy+fhRootDevice1)
	ld (ix+fhDevice1),a	
	ld a,(iy+fhRootDevice2)
	ld (ix+fhDevice2),a
	ld a,(iy+fhRootDevice3)
	ld (ix+fhDevice3),a	
	ret

	; tokenize the filepath
	; ix = filehandle
	; hl = filepath or last token
	; output - de = null or points to the / of the following token
	; output C = token copied, NC = no token found

fhTokenizePath:
	push bc
	push hl
	ld de,0						; prepare for no more tokens
fhTokenizePath1:
	ld a,(hl)
	inc hl
	or a
	jr z,fhTokenizeEndNoMatch	; end of filename path
	cp '/'
	jr nz,fhTokenizePath1			; find the end of this name
	ld a,(hl)						; end of path?
	or a
	jr z,fhTokenizeEndNoMatch
	push hl						; update the file part in the filehandler with this part
	push ix
	pop hl
	ld de,fhfilePart
	add hl,de
	pop de						
	ld b,filenameLen				; return value in de
fhTokenizeCopy1:
	ld a,(de)						; file name parsed from the string
	ld (hl),0
	or a
	jr z,fhTokenizeCopy2			; copy just the name part of the path and null term it
	cp '/'
	jr z,fhTokenizeCopy2			; space or tab terminates as well
	ld (hl),a
	inc hl
	inc de
	djnz fhTokenizeCopy1
fhTokenizeCopy2:
	ld a,(de)
	cp '/'						; is there another token?
	jr z,fhTokenizeEndMatch
	ld de,0						; no more tokens after this one - TODO - need this?
fhTokenizeEndMatch:
	pop hl
	pop bc
	scf							; set C
	ret

fhTokenizeEndNoMatch:
	pop hl
	pop bc
	and a						; reset C
	ret

	; return the filename from a path. Its the last word after the last /
	; hl = filepath
	; output - de = last path entry
fhGetFileName:
	push hl
	call fhTokenizePath
	ld a,e
	or d
	jr z, fhGetFileNameEnd
	pop hl
	ex de,hl
	jr fhGetFileName
fhGetFileNameEnd:
	pop de				; go back to the last but one token
	inc de				; advance past the /
	ld a,(de)
	or a
	ret nz
	ld de,0
	ret

	; return the file part from the fileheader
	; ix - file header
	; output - hl = file part

fhGetFilePart:
	push de
	push ix
	pop hl
	ld de,fhFilePart			; ix offset to the filepart
	add hl,de
	pop de
	ret


	; read primative - read the current device /block into the buffer
	; ix = filehandle
	; returns C = success, NC = failed

fhRead:
	push ix
	push hl
	push de


	ld l,(ix+fhPtrl)					; buffer pointer
	ld h,(ix+fhPtrh)
	push hl

	push ix
	pop hl
	ld de,fhDevice0	
	add hl,de						; offset to the device name

	ld e,(ix+fhBlockl)
	ld d,(ix+fhBlockh)					; de block number

	call devFind						; ix points to device

	pop hl							; buffer pointer
	jr z,fhReadFail
	call devRead
fhReadFail:
	pop de
	pop hl
	pop ix							; filehandle again
	ret

	; write primative - write the buffer to the current device /block
	; ix = filehandle
	; returns NZ = success, Z = failed

fhWrite:
	push ix
	push hl
	push de

	ld l,(ix+fhPtrl)					; buffer pointer
	ld h,(ix+fhPtrh)
	push hl

	push ix
	pop hl
	ld de,fhDevice0	
	add hl,de						; offset to the device name
	ld e,(ix+fhBlockl)
	ld d,(ix+fhBlockh)					; de block number


	call devFind						; ix points to device
	pop hl							; buffer pointer
	call z,fhWriteDevNotFound
	jr z,fhWriteFail
	call devWrite
fhWriteFail:
	pop de
	pop hl
	pop ix							; filehandle again
	ret

fhDevNotFound:
	defm "Device not found"
	defb 0x0a,0x0d,0
fhWriteDevNotFound:
	ld hl,fhDevNotFound
	call dartPutString
	ret

	; fhDelete - delete the block in storage pointed to by fh
	; ix = filehandler
fhDelete:
	push ix
	push hl
	push de
	push ix
	pop hl
	ld de,fhDevice0
	add hl,de
	ld e,(ix+fhBlockl)
	ld d,(ix+fhBlockh)					; de block number
	call devFind
	call devDelete					; delete the block DE on device IX
	pop de
	pop hl
	pop ix
	ret



















			;
			; errors
			;

errFileNotFound equ 1
errFileNotFoundMsg defm "File Not Found"
	defb 0
errFileNoDevice equ 2
errFileNoDeviceMsg defm "No Device"
	defb 0
errFileFull equ 3
errFileFullMsg defm "Full"
	defb 0
errFileBadBlock equ 4
errFileBadBlockMsg defm "Bad Block"
	defb 0
errFileRead	equ 5
errFileReadMsg	defm "Read Fail"
	defb 0
errFileWrite	equ 6
errFileWriteMsg	defm "Write Fail"
	defb 0
errFileNoBlock	equ 7
errFileNoBlockMsg	defm "No Block"
	defb 0
errFileFormatError	equ 8
errFileFormatErrorMsg	defm "Format Fail"
	defb 0
errFileDirNotFound	equ 9
errFileDirNotFoundMsg	defm "Dir Not Found"
	defb 0
errFileNotAFile		equ 10
errFileNotAFileMsg	defm "Not a file"
	defb 0
errFileDirNotEmpty	equ 11
errFileDirNotEmptyMsg	defm "Not Empty"
	defb 0
errFileExists			equ 12
errFileExistsMsg		defm "File Already Exists"
	defb 0
errBadPackage		equ 13
errBadPackageMsg	defm "Bad Package"
	defb 0
errUnknownError	defm "Error"
	defb 0

errTable:
	defw	errFileNotFound,	errFileNotFoundMsg
	defw	errFileNoDevice,	errFileNoDeviceMsg
	defw	errFileFull,		errFileFullMsg
	defw	errFileBadBlock,	errFileBadBlockMsg
	defw	errFileRead,		errFileReadMsg
	defw	errFileWrite,		errFileWriteMsg
	defw	errFileNoBlock,	errFileNoBlockMsg
	defw	errFileFormatError, errFileFormatErrorMsg
	defw	errFileDirNotFound, errFileDirNotFoundMsg
	defw	errFileNotAFile,	errFileNotAFileMsg
	defw	errFileDirNotEmpty,	errFileDirNotEmptyMsg
	defw	errFileExists,		errFileExistsMsg
	defw	errBadPackage,	errBadPackageMsg
	defw	0,				errUnknownError

	;
	; Print error A
	;	
errPrint:
	push af					; call nc,errPrint
	push hl
	push de
	ld hl,errTable
	ld e,a
errPrint0:
	ld a,(hl)
	cp e					; match error number?
	jr z,errPrint1
	or a						; end of table
	jr z,errPrint1
	inc hl					; to next entry
	inc hl
	inc hl
	inc hl		
	jr errPrint0

errPrint1:
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	call dartPutString
	call putCRLF
	pop de
	pop hl
	pop af
	ret




	;
	; Define the restarts in the first page
	;

	org 0x0000
	JP initInit				; Board initialization

	org 0x0008				; RST8
	JP dartGetKey				; Read A from the keyboard

	org 0x0010				; RST10
	JP dartPutTerm				; Write A to the terminal

	org 0x0018				; RST18
	JP dartPutString				; Write a null terminated string pointed to by HL to the terminal


	org 0x0020				; RST20
	JP malloc					; Allocate HL bytes on the heap and return the address in HL


	org 0x0028				; RST28
	JP memSelect				; Select memory slot A


	org 0x0030				; RST30
	JP debug					; Dump 16 bytes to terminal from address hl

	org 0x0038				; RST38
	ret						; Nothing here yet



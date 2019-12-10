	org 0x2000
	jp initInit						; program starts here

	;
	; Interrupt vector table
	;

iValue equ 0x20					; Top part of the vector table

	org 0x2040
	defw	ctcInterrupt0				; CTC channel 0 Interupts
	defw	ctcInterrupt1				; CTC channel 1 Interupts
	defw	ctcInterrupt2				; CTC channel 2 Interupts
	defw	ctcInterrupt3				; CTC channel 3 Interupts
ctcVector equ 0x40

	org 0x2048
	defw  pio1Interrupt				; PIO 1 interrupt 
pio1Vector equ 0x48

	org 0x2050
	defw  pio2Interrupt				; PIO 2 interrupt 
pio2Vector equ 0x50

	org 0x2060
	defw dartBTransmitInterrupt                                      ; Transmit channel B
	defw dartBExternalStatusInterrupt                            ; External status channel B
	defw dartBReceiveInterrupt                                        ; Receive channel B
	defw dartBSpecialRecieveInterrupt                           ; Special receive error channel B
	defw dartATransmitInterrupt                                       ; Channel A	
	defw dartAExternalStatusInterrupt
	defw dartAReceiveInterrupt
	defw dartASpecialRecieveInterrupt

dartVector equ 0x60




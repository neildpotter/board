	;
	; Interrupt vector table
	;

iValue equ 0x00					; Top part of the vector table

	org 0x0040
	defw	ctcInterrupt				; CTC Interupts
ctcVector equ 0x40

	org 0x0048
	defw  pio1Interrupt				; PIO 1 interrupt 
pio1Vector equ 0x48

	org 0x0050
	defw  pio2Interrupt				; PIO 2 interrupt 
pio2Vector equ 0x50

	org 0x0060
	defw dartBTransmitInterrupt                                      ; Transmit channel B
	defw dartBExternalStatusInterrupt                            ; External status channel B
	defw dartBReceiveInterrupt                                        ; Receive channel B
	defw dartBSpecialRecieveInterrupt                           ; Special receive error channel B
	defw dartATransmitInterrupt                                       ; Channel A	
	defw dartAExternalStatusInterrupt
	defw dartAReceiveInterrupt
	defw dartASpecialRecieveInterrupt

dartVector equ 0x60




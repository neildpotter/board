	;
	; disassembler
	;

; 	nnnn  op  op  op  op   bit    7,  (ix  +23 )            nf
;	012345678901234567890123456789012345

dissTextEnd	equ 34
dissNumOpcodes equ 35
dissFlags equ 36							; bit 7- offset consumed, 3 - ix, 4 iy
dissTextStart equ 17
dissOpcodeStart equ 5
	org 0
	;
	; Initialize
	; 
	jr init
	jr deinit
packageName:
	defm "diss"							; package name
	defb 0
init:
	ld de,conversionTable					; modify the 16bit addresses to absolutes
	call _relocate
in0:	ld ix,packageName
in1:	ld hl,dissVerb						; register the program
in2:	ld de,cmdDisassemble	
in3:	ld bc,dissHelp
	ld a,2								; package verb
	call _register
	ret

deinit:
ita:	ld hl,dissVerb
	call _unregister
	ret

dissVerb:
	defm "diss"
	defb 0 
dissHelp: 
	defm "<addr> -l=lines"
	defb 0 
dissBaseOffset:	defw 0					; will be the base offset
	;
	; Disassemble command line
	;
cmdDisassemble:
	call _parseByteNoun				; 
	or a
	ret z
	push bc
	ld a,'l'					; lines
	call _parseByteToken
	or a
	jr z,cmdDisassemble5
							; BC = number of lines
	pop de					; op code address
	jr cmdDisassembleLoop	
cmdDisassemble5:
	ld bc,10					; default number of lines
	pop de					; op code address
cmdDisassembleLoop:
	push bc
	push de
	pop hl
	ld hl,40
	call _malloc				; make a buffer for the output
	push hl
	pop bc					; buffer address
in4:	call disassemble
	push bc
	pop hl
	call _putString
	call _putCRLF
	call _free
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,cmdDisassembleLoop
	ret	

conversionTable:
	defw in0+2, in1+1, in2+1, in3+1, in4+1,in5+1,in6+1,in7+1,in8+1,in9+1,ina+1,inb+1
	defw io1+1, io2+1, io3+1, io4+1, io5+1, io6+1, io7+1, io8+2, io9+1, ioa+2
	defw ip1+1, ip2+1, ip3+1, ip4+1, ip5+1, ip6+1, ip7+1, ip8+1, ip9+1, ipa+1,ipb+1
	defw iq1+1, iq2+1, iq3+1, iq4+1, iq5+1, iq6+1, iq7+1, iq8+1, iq9+1, iqa+1,iqb+1,iqc+1
	defw ir1+1, ir2+1, ir3+1, ir4+1, ir5+1, ir6+1, ir7+1, ir8+1, ir9+1, ira+1,irb+1, irc+1, ird+1
	defw is1+1, is2+1, is3+1, is4+1, is5+1, is6+1, is7+1, is8+1, is9+1, isa+1,isb+1,isc+1
	defw it1+1, it2+1, it3+1, it4+1, it5+1, it6+1, it7+1, it8+1, it9+1,ita+1
	defw dissBaseOffset
	defw 0					; terminator
	;
	; Disassembler
	;
	; DE points to opcode, BC to buffer
	; DE points to next opcode

disassemble:
	push bc
	push hl
	push af
	;
	; clear the buffer and set defaults
	;
	push bc
	push bc
	pop ix
	pop hl
	ld a,dissTextEnd
dissFillLoop:
	ld (hl),' '
	inc hl
	dec a
	jr nz,dissFillLoop
	ld (ix+dissTextEnd),0				; null terminate the text
	ld (ix+dissNumOpcodes),0			; no opcodes yet
	ld (ix+dissFlags),0				; no flags
	; Write the base address into positions 0-4
	push de
	ld a,d
	ld l,e
	call _toHex
	ld (ix+0),d
	ld (ix+1),e
	ld a,l
	call _toHex
	ld (ix+2),d
	ld (ix+3),e
	ld (ix+4),9				; tab
	pop de
	ld hl,dissTextStart
	add hl,bc				; address of text start
	push hl
	pop bc
	;
	; Process ED, CB, FD and DD pre-codes
	;
in5:	ld hl,dissMainTable
	ld a,(de)
	cp 0xDD					; IX prefix
	jr nz, dissLoop1
	set 3,(ix+dissFlags)		; ix flag
in6:	call dissAddOpcode
	inc de
	ld a,(de)
	jr dissLoop2
dissLoop1:
	cp 0xFD					; IY prefix
	jr nz,dissLoop2
	set 4,(ix+dissFlags)		; iy flag
in7:	call dissAddOpcode
	inc de
	ld a,(de)
dissLoop2:
	cp 0xCB
	jr nz,dissLoop0
in8:	call dissAddOpcode
	inc de
in9:	ld hl,dissCBTable
	jr dissLoop3
dissLoop0:
	cp 0xED
	jr nz,dissLoop3
ina:	call dissAddOpcode
	inc de
inb:	ld hl,dissEDTable
	;
	; scan the table  - apply the mask, then compare to find the row
	;
dissLoop3:
io1: call dissAddOpcode
dissLoop:
	ld a,(de)
	and (hl)					; mask
	inc hl
	cp (hl)					; compare	
	jr z,dissProcessRow
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	jr dissLoop				; it must find something
dissProcessRow:
	inc hl
io2: call dissAction
	inc hl
io3: call dissAction
	inc hl
io4: call dissAction
	inc hl
io5: call dissAction
	pop af
	pop hl
	pop bc
	inc de					; to next op code
	ret

dissAddOpcode:
	ld a,(de)
	push de
	call _toHex
	push bc
	push hl
	push ix
	pop hl
	ld bc,dissOpcodeStart		; compute where to write the text
	add hl,bc
	ld bc,3					; 3 positions per opcode
	ld a,(ix+dissNumOpcodes)
dissAddOpcode1:
	or a
	jr z,dissAddOpcode2
	add hl,bc
	dec a
	jr dissAddOpcode1
dissAddOpcode2
	ld (hl),d
	inc hl
	ld (hl),e
	inc (ix+dissNumOpcodes)	; another op code!
	pop hl
	pop bc
	pop de
	ret

dissMainTable:
			; mask	cp		action		action		action		action
	defb	0xff,	0x00,	dissNOP,	0,			0,			0		; nop
	defb	0xff,	0x76,	dissHALT,	0,			0,			0		; halt
	defb	0xc0,	0x40,	dissLD,		dissR40,	dissCm,		dissR81	; ld r,r
	defb	0xC7,	0x04,	dissINC,		dissR40,	0,			0		; inc r
	defb	0xC7,	0x05,	dissDEC,	dissR40,	0,			0		; dec r
	defb	0xFF,	0x27,	dissDAA,	0,			0,			0		; daa
	defb	0xFF,	0x2F,	dissCPL,		0,			0,			0		; cpl
	defb	0xFF,	0x3F,	dissCCF,		0,			0,			0		; ccf
	defb	0xFF,	0x37,	dissSCF,		0,			0,			0		; scf
	defb	0xFF,	0xF3,	dissDI,		0,			0,			0		; di
	defb	0xFF,	0xFB,	dissEI,		0,			0,			0		; ei
	defb	0xC7,	0x06,	dissLD,		dissR40,	dissCM,		dissN	; ld r,n
	defb	0xFF,	0x22,	dissLD,		dissLnnL,	dissCM,		dissHL	; ld (nn),hl
	defb	0xFF,	0x2A,	dissLD,		dissHL,		dissCM,		dissLnnL ; ld hl,(nn)
	defb	0xFF,	0x3A,	dissLD,		dissA,		dissCM,		dissLnnL ; ld a,(nn)
	defb	0xFF,	0x32,	dissLD,		dissLnnL,	dissCM,		dissA	; ld (nn),a
	defb	0xCF,	0x0A,	dissLD,		dissA,		dissCM,		dissLR54L ; ld a,(rr)
	defb	0xCF,	0x02,	dissLD,		dissLR54L,	dissCM,		dissA	; ld (rr),a
	defb	0xCF,	0x01,	dissLD,		dissR54SP,	dissCM,		dissNN	; ld rr,nn
	defb	0xFF,	0xF9,	dissLD,		dissSP,		dissCM,		dissHL	; ld sp,hl
	defb	0xCF,	0xC5,	dissPUSH,	dissR54AF,	0,			0		; push rr
	defb	0xCF,	0xC1,	dissPOP,		dissR54AF,	0,			0		; pop rr
	defb	0xFF,	0xEB,	dissEXDEHL,	0,			0,			0		; ex de,hl
	defb	0xFF,	0x08,	dissEXAFAF,	0,			0,			0		; ex af,af'
	defb	0xFF,	0xD9,	dissEXX,	0,			0,			0		; exx
	defb	0xFF,	0xE3,	dissEX,		dissLspL,	dissCM,		dissHL	; ex (sp),hl
	defb	0xF8,	0x80	dissADD,	dissA,		dissCM,		dissR8	; add a,r
	defb	0xFF,	0xC6,	dissADD,	dissA,		dissCM,		dissN	; add a,n
	defb	0xF8,	0x88	dissADC,	dissA,		dissCM,		dissR8	; adc a,r
	defb	0xFF,	0xCE,	dissADC,	dissA,		dissCM,		dissN	; adc a,n
	defb	0xF8,	0x90	dissSUB,	dissR8,		0,			0		; sub r
	defb	0xFF,	0xD6,	dissSUB,	dissN,		0,			0		; sub n
	defb	0xF8,	0x98	dissSBC,	dissA,		dissCM,		dissR8	; sbc a,r
	defb	0xFF,	0xDE,	dissSBC,	dissA,		dissCM,		dissN	; sbc a,n
	defb	0xF8,	0xA0	dissAND,	dissR8,		0,			0		; and r
	defb	0xFF,	0xE6,	dissAND,	dissN,		0,			0		; and n
	defb	0xF8,	0xB0	dissOR,		dissR8,		0,			0		; or r
	defb	0xFF,	0xF6,	dissOR,		dissN,		0,			0		; or n
	defb	0xF8,	0xA8	dissXOR,	dissR8,		0,			0		; xor r
	defb	0xFF,	0xEE,	dissXOR,	dissN,		0,			0		; xor n
	defb	0xF8,	0xB8	dissCP,		dissR8,		0,			0		; cp r
	defb	0xFF,	0xFE,	dissCP,		dissN,		0,			0		; cp n
	defb	0xCF,	0x09,	dissADD,	dissHL,		dissCM,		dissR54SP	; add hl,rr
	defb	0xCF,	0x03,	dissINC,		dissR54SP,	0,			0		; inc rr
	defb	0xCF,	0x0B,	dissDEC,	dissR54SP,	0,			0		; dec rr
	defb	0xFF,	0x07,	dissRLCA,	0,			0,			0		; rlca
	defb	0xFF,	0x17,	dissRLA,	0,			0,			0		; rla
	defb	0xFF,	0x0F,	dissRRCA,	0,			0,			0		; rrca
	defb	0xFF,	0x1F,	dissRRA,	0,			0,			0		; rra
	defb	0xFF,	0xC3,	dissJP,		dissNN,		0,			0		; jp nn
	defb	0xFF,	0xC3,	dissJP,		dissnn,		0,			0		; jp nn
	defb	0xC7,	0xC2,	dissJP,		dissCC,		dissCM,	dissNN		; jp cc,nn
	defb	0xFF,	0x18,	dissJR,		dissREL,		0,			0		; jr rel (single byte, compute the address
	defb	0xE7,	0x20,	dissJR,		dissCC1,	dissCM,	dissREL		; jr cc,rel
	defb	0xFF,	0xE9,	dissJP,		dissLhlL,	0,			0		; jp (hl)
	defb	0xFF,	0x10,	dissDJNZ,	dissREL,		0,			0		; djnz rel
	defb	0xFF,	0xCD,	dissCALL,	dissNN,		0, 			0		; call nn
	defb	0xC7,	0xC4,	dissCALL,	dissCC,		dissCM,		dissNN	; call CC,nn
	defb	0xFF,	0xC9,	dissRET,		0,			0,			0		; ret
	defb	0xC7,	0xC0,	dissRET,		dissCC,		0,			0		; ret cc
	defb	0xC7,	0xC7,	dissRST,		dissAddr,	0,			0		; rst xxh
	defb	0xFF,	0xDB,	dissIN,		dissA,		dissCM,		dissLnL	; in a,(n)
	defb	0xFF,	0xD3,	dissOUT,	dissLnL,		dissCM,		dissA	; out (n),a
	defb	0,		0,		0,		0,		0,		0			; catch all
	
dissEDTable:
	defb	0xFF,	0x57,	dissLD,		dissA,		dissCM,	dissI			; ld a,i
	defb	0xFF,	0x5F,	dissLD,		dissA,		dissCM,	dissR			; ld a,r
	defb	0xFF,	0x47,	dissLD,		dissI,		dissCM,	dissA			; ld i,a
	defb	0xFF,	0x4F,	dissLD,		dissR,		dissCM,	dissA			; ld r,a
	defb	0xCF,	0x4B,	dissLD,		dissR54SP,	dissCM,	dissLnnL		; ld rr,(nn)
	defb	0xCF,	0x43,	dissLD,		dissLnnL,	dissCM,	dissR54PLS		; ld (nn),rr
	defb	0xFF,	0xA0,	dissLDI,		0,	0,	0							; ldi
	defb	0xFF,	0xB0,	dissLDIR,	0,	0,	0							; ldir
	defb	0xFF,	0xA8,	dissLDD,		0,	0,	0							; ldd
	defb	0xFF,	0xB8,	dissLDDR,	0,	0,	0							; lddr
	defb	0xFF,	0xA1,	dissCPI,		0,	0,	0							; cpi
	defb	0xFF,	0xB1,	dissCPIR,	0,	0,	0							; cpir
	defb	0xFF,	0xA9,	dissCPD,		0,	0,	0							; cpd
	defb	0xFF,	0xB9,	dissCPDR,	0,	0,	0							; cpdr
	defb	0xFF,	0x44,	dissNEG,		0,	0,	0							; neg
	defb	0xFF,	0x46,	dissIM0,		0,	0,	0							; IM0
	defb	0xFF,	0x56,	dissIM1,		0,	0,	0							; IM1
	defb	0xFF,	0x5E,	dissIM2,		0,	0,	0							; IM2
	defb	0xCF,	0x4A,	dissADC,	dissHL,	dissCM,	dissR54SP			; adc hl,rr
	defb	0xCF,	0x42,	dissSBC,	dissHL,	dissCM,	dissR54SP			; sbc hl,rr	
	defb	0xFF,	0x6F,	dissRLD,	0,	0,	0							; rld
	defb	0xFF,	0x67,	dissRRD,	0,	0,	0							; rrd
	defb	0xFF,	0x4D,	dissRETI,	0,	0,	0							; reti
	defb	0xFF,	0x45,	dissRETN,	0,	0,	0							; retn
	defb	0xC7,	0x40,	dissIN,		dissR40, dissCM, dissLCL				; in r,(c)	
	defb	0xFF,	0xA2,	dissINI,		0,	0,	0							; ini
	defb	0xFF,	0xB2,	dissINIR,	0,	0,	0							; inir
	defb	0xFF,	0xAA,	dissIND,		0,	0,	0							; ind
	defb	0xFF,	0xBA,	dissINDR,	0,	0,	0							; indr
	defb	0xC7,	0x41,	dissOUT,	dissLCL,	dissCM,	dissR40				; out (c),r
	defb	0xFF,	0xA3,	dissOUTI,	0,	0,	0							; outi
	defb	0xFF,	0xB3,	dissOTIR,	0,	0,	0							; otir
	defb	0xFF,	0xAB,	dissOUTD,	0,	0,	0							; outd
	defb	0xFF,	0xBB,	dissOTDR,	0,	0,	0							; otdr
	defb	0,		0,		0,		0,		0,		0			; catch all

dissCBTable:
	defb	0xF8,	0x00,	dissRLC,		dissR8,		0,	0					; rlc r
	defb	0xF8,	0x08,	dissRRC,	dissR8,		0,	0					; rrc r
	defb	0xF8,	0x10,	dissRL,		dissR8,		0,	0					; rl r
	defb	0xF8,	0x18,	dissRR,		dissR8,		0,	0					; rr r
	defb	0xF8,	0x20,	dissSLA,		dissR8,		0,	0					; sla r
	defb	0xF8,	0x28,	dissSRA,	dissR8,		0,	0					; sra r
	defb	0xF8,	0x30,	dissSLL,		dissR8,		0,	0					; ssl r *
	defb	0xF8,	0x38,	dissSRL,	dissR8,		0,	0					; srl r
	defb	0xC0,	0x40,	dissBIT,		dissNBit,	dissCM,	dissR8			; bit n,r
	defb	0xC0,	0xC0,	dissSET,		dissNBit,	dissCM,	dissR8			; set n,r
	defb	0xC0,	0x80,	dissRES,	dissNBit,	dissCM,	dissR8			; res n,r
	defb	0,		0,		0,		0,		0,		0			; catch all

	;
	; Look up the action code in the dissOpCodes or dissActions table
	; 
dissAction:
	ld a,(hl)			; action code
	or a
	ret z			; 0 action code - do nothing
	push hl
	bit 7,a			; high bit = action codes
io6: ld hl,dissActionTable
	jr nz,dissAction1
io7: ld hl,dissOpCodeTable
dissOpCodeLoop:
	cp (hl)
	inc hl
	inc hl
	jr z,dissDoOpCode
	inc hl
	inc hl			; next byte
	jr dissOpCodeLoop
	;
	; Copy an op code string to the output
	;
dissDoOpCode:
	push de
	ld e,(hl)			; get the string
	inc hl
	ld d,(hl)
	ex de,hl
io8: ld de,(dissBaseOffset)	; adjust opcode strings to absolute addresses
	add hl,de
	pop de
io9: call dissCopyString
	pop hl
	ret

dissCopyString:
	ld a,(hl)
	or a
	ret z
	ld (bc),a
	inc bc
	inc hl
	jr dissCopyString

	;
	; call the action routine by code
	;
dissAction1:
	cp (hl)			; low byte
	inc hl
	inc hl
	jr z,dissActionFound
	inc hl
	inc hl
	jr dissAction1	; next byte

dissActionFound:
	push de
	ld e,(hl)			; get the action routine
	inc hl
	ld d,(hl)
	ex de,hl
ioa: ld de,(dissBaseOffset)	; adjust opcode strings to absolute addresses
	add hl,de
	pop de

	jp (hl)			; jump to the handler routine

dissActionDone:		; that all jump back here
	pop hl
	ret
	;
	; codes that result in string output
	;
dissNOP	equ		1	
dissNOPtxt:	defm	"nop "
			defb 0
dissLD		equ		2
dissLDtxt	defm	"ld "
			defb 0
dissHALT	equ		3
dissHALTtxt	defm	"halt "
			defb 0
dissINC		equ		4
dissINCtxt	defm	"inc "
			defb 0
dissDEC		equ		5
dissDECtxt	defm	"dec "
			defb 0
dissPUSH	equ		6
dissPUSHtxt	defm	"push "
			defb 0
dissPOP		equ		7
dissPOPtxt	defm	"pop "
			defb 0
dissEXDEHL	equ		8
dissEXDEHLtxt	defm	"ex de,hl "
			defb 0
dissEXAFAF	equ		9
dissEXAFAFtxt	defm	"ex af,af' "
			defb 0
dissEXX		equ		10
dissEXXtxt	defm	"exx "
			defb 0
dissLDI		equ		11
dissLDItxt	defm	"ldi "
			defb 0
dissLDIR		equ		12
dissLDIRtxt	defm	"ldir "
			defb 0
dissLDD		equ		13
dissLDDtxt	defm	"ldd "
			defb 0
dissLDDR		equ		14
dissLDDRtxt	defm	"lddr "
			defb 0
dissCPI		equ		15
dissCPItxt	defm	"cpi "
			defb 0
dissCPIR		equ		16
dissCPIRtxt	defm	"cpir "
			defb 0
dissCPD		equ		17
dissCPDtxt	defm	"cpd "
			defb 0
dissCPDR		equ		18
dissCPDRtxt	defm	"cpdr "
			defb 0
dissADD		equ		19
dissADDtxt	defm	"add "
			defb 0
dissADC		equ		20
dissADCtxt	defm	"adc "
			defb 0
dissSUB		equ		21
dissSUBtxt	defm	"sub "
			defb 0
dissSBC		equ		22
dissSBCtxt	defm	"sbc "
			defb 0
dissAND		equ	23
dissANDtxt	defm	"and "
			defb 0
dissOR		equ		24
dissORtxt	defm	"or "
			defb 0
dissXOR		equ		25
dissXORtxt	defm	"xor "
			defb 0
dissCP		equ		26
dissCPtxt	defm	"cp "
			defb 0
dissDAA		equ		27
dissDAAtxt	defm	"daa "
			defb 0
dissCPL		equ		28
dissCPLtxt	defm	"cpl "
			defb 0
dissNEG		equ		29
dissNEGtxt	defm	"neg "
			defb 0
dissCCF		equ		30
dissCCFtxt	defm	"ccf "
			defb 0
dissSCF		equ		31
dissSCFtxt	defm	"scf "
			defb 0
dissDI		equ		32
dissDItxt	defm	"di "
			defb 0
dissEI		equ		33
dissEItxt	defm	"ei "
			defb 0
dissIM0		equ		34
dissIM0txt	defm	"im 0 "
			defb 0
dissIM1		equ		35
dissIM1txt	defm	"im 1 "
			defb 0
dissIM2		equ		36
dissIM2txt	defm	"im 2 "
			defb 0
dissRLCA		equ		37
dissRLCAtxt	defm	"rlca "
			defb 0
dissRLA		equ		38
dissRLAtxt	defm	"rla "
			defb 0
dissRRCA		equ		39
dissRRCAtxt	defm	"rrca "
			defb 0
dissRRA		equ		40
dissRRAtxt	defm	"rra "
			defb 0
;dissHL		equ		41
;dissHLtxt	defm	"hl"
;			defb 0
dissA		equ		42
dissAtxt		defm	"a"
			defb 0
dissSP		equ		43
dissSPtxt	defm	"sp"
			defb 0
dissJP		equ		44
dissJPtxt	defm	"jp "
			defb 0
dissDJNZ	equ		45
dissDJNZtxt	defm	"djnz "
			defb 0
dissCALL	equ		46
dissCALLtxt	defm	"call "
			defb 0
dissRET		equ		47
dissRETtxt	defm	"ret "
			defb 0
dissRST		equ		48
dissRSTtxt	defm	"rst "
			defb 0
dissIN		equ		49
dissINtxt	defm	"in "
			defb 0
dissOUT		equ		50
dissOUTtxt	defm	"out "
			defb 0
dissJR		equ		51
dissJRtxt	defm	"jr "
			defb 0
;dissLhlL		equ		52
;dissLhlLtxt	defm	"(hl) "
;			defb 0
dissLCL		equ		53
dissLCLtxt	defm	"(c)"
			defb 0
dissLspL	equ		54
dissLspLtxt	defm	"(sp)"
			defb 0
dissRLD		equ		55
dissRLDtxt	defm	"rld "
			defb 0
dissRRD	equ		56
dissRRDtxt	defm	"rrd "
			defb 0
dissRETI	equ		57
dissRETItxt	defm	"reti "
			defb 0
dissRETN	equ		58
dissRETNtxt	defm	"retn "
			defb 0
dissINI		equ		59
dissINItxt	defm	"ini "
			defb 0
dissINIR		equ		60
dissINIRtxt	defm	"inir "
			defb 0
dissIND		equ		61
dissINDtxt	defm	"ind "
			defb 0
dissINDR	equ		62
dissINDRtxt	defm	"indr "
			defb 0
dissOUTI	equ		63
dissOUTItxt	defm	"outi "
			defb 0
dissOTIR	equ		64
dissOTIRtxt	defm	"otir "
			defb 0
dissOUTD	equ		65
dissOUTDtxt	defm	"outd "
			defb 0
dissOTDR	equ		66
dissOTDRtxt	defm	"otdr "
			defb 0
dissI		equ		67
dissItxt		defm	"i"
			defb 0
dissR		equ		68
dissRtxt		defm	"r "
			defb 0
dissEX		equ		69
dissEXtxt	defm	"ex "
			defb 0
dissRLC		equ		70
dissRLCtxt	defm	"rlc "
			defb 0
dissRRC	equ		71
dissRRCtxt	defm	"rrc "
			defb 0
dissRL		equ		72
dissRLtxt	defm	"rl "
			defb 0
dissRR		equ		73
dissRRtxt	defm	"rr "
			defb 0
dissSLA		equ		74
dissSLAtxt	defm	"sla "
			defb 0
dissSRA		equ		75
dissSRAtxt	defm	"sra "
			defb 0
dissSLL		equ		76
dissSLLtxt	defm	"sll "
			defb 0
dissSRL		equ		77
dissSRLtxt	defm	"srl "
			defb 0
dissBIT		equ		78
dissBITtxt	defm	"bit "
			defb 0
dissSET		equ		79
dissSETtxt	defm	"set "
			defb 0
dissRES		equ		80
dissREStxt	defm	"res "
			defb 0


dissOpCodeTable:
	defw	dissNOP,	dissNOPtxt
	defw	dissLD,		dissLDtxt
	defw	dissHALT,	dissHALTtxt
	defw	dissINC,		dissINCtxt
	defw	dissPUSH,	dissPUSHtxt
	defw	dissPOP,		dissPOPtxt
	defw	dissEXDEHL,	dissEXDEHLtxt
	defw	dissEXAFAF,	dissEXAFAFtxt
	defw	dissEXX,	dissEXXtxt
	defw	dissEX,		dissEXtxt
	defw	dissLDI,		dissLDItxt
	defw	dissLDIR,	dissLDIRtxt
	defw	dissLDD,	dissLDDtxt
	defw	dissLDDR,	dissLDDRtxt
	defw	dissCPI,		dissCPItxt
	defw	dissCPIR,	dissCPIRtxt
	defw	dissCPD,	dissCPDtxt
	defw	dissCPDR,	dissCPDRtxt
	defw	dissADD,	dissADDtxt
	defw	dissADC,	dissADCtxt
	defw	dissSUB,	dissSUBtxt
	defw	dissSBC,	dissSBCtxt
	defw	dissAND,	dissANDtxt
	defw	dissOR,		dissORtxt
	defw	dissXOR,	dissXORtxt
	defw	dissCP,		dissCPtxt
	defw	dissDAA,	dissDAAtxt
	defw	dissCPL,		dissCPLtxt
	defw	dissNEG,	dissNEGtxt
	defw	dissCCF,		dissCCFtxt
	defw	dissSCF,		dissSCFtxt
	defw	dissDI,		dissDItxt
	defw	dissEI,		dissEItxt
	defw	dissIM0,		dissIM0txt
	defw	dissIM1,		dissIM1txt
	defw	dissIM2,		dissIM2txt
	defw	dissRLCA,	dissRLCAtxt
	defw	dissRLA,	dissRLAtxt
	defw	dissRRCA,	dissRRCAtxt
	defw	dissRRA,	dissRRAtxt
;	defw	dissHL,		dissHLtxt
	defw	dissA,		dissAtxt
	defw	dissSP,		dissSPtxt
	defw	dissJP,		dissJPtxt
	defw	dissDJNZ,	dissDJNZtxt	
	defw	dissCALL,	dissCALLtxt
	defw	dissRET,		dissRETtxt
	defw	dissRST,		dissRSTtxt	
	defw	dissIN,		dissINtxt	
	defw	dissOUT,	dissOUTtxt	
	defw	dissNEG,	dissNEGtxt	
	defw	dissIM0,		dissIM0txt	
	defw	dissIM1,		dissIM1txt	
	defw	dissIM2,		dissIM2txt	
	defw	dissJR,		dissJRtxt	
	defw	dissRLD,	dissRLDtxt	
	defw	dissRRD,	dissRRDtxt	
	defw	dissRETI,	dissRETItxt	
	defw	dissRETN,	dissRETNtxt	
	defw	dissINI,		dissINItxt	
	defw	dissINIR,	dissINIRtxt	
	defw	dissIND,		dissINDtxt	
	defw	dissINDR,	dissINDRtxt	
	defw	dissOUTI,	dissOUTItxt	
	defw	dissOTIR,	dissOTIRtxt	
	defw	dissOUTD,	dissOUTDtxt	
	defw	dissOTDR,	dissOTDRtxt	
	defw	dissI,		dissItxt
	defw	dissR,		dissRtxt	
;	defw	dissLhlL,	dissLhlLtxt
	defw	dissLCL,		dissLCLtxt
	defw	dissLspL,	dissLspLtxt
	defw	dissRLC,		dissRLCtxt
	defw	dissRRC,	dissRRCtxt
	defw	dissRL,		dissRLtxt
	defw	dissRR,		dissRRtxt
	defw	dissSLA,		dissSLAtxt
	defw	dissSRA,	dissSRAtxt
	defw	dissSLL,		dissSLLtxt
	defw	dissSRL,	dissSRLtxt
	defw	dissBIT,		dissBITtxt
	defw	dissSET,		dissSETtxt
	defw	dissRES,	dissREStxt
	defw	dissDEC,	dissDECtxt


	;
	; codes that result in a handler routine call
	;
dissR8		equ		0x81
dissR40		equ		0x82
dissCm		equ		0x83
dissN		equ		0x84
dissLnnL	equ		0x85
dissLrrL		equ		0x86
dissR54AF	equ		0x87
dissR54SP	equ		0x88
dissNN		equ		0x89
dissCC		equ		0x90
dissCC1		equ		0x91
dissREL		equ		0x92
dissAddr	equ		0x93
dissLnL		equ		0x94
dissNBit		equ		0x95
dissLR54L	equ		0x96
dissR54PLS	equ		0x97
dissHL		equ		0x98
dissLhlL		equ		0x99
dissR81		equ		0x9A

dissActionTable:
	defw	dissR8,		dissRegister8
	defw	dissR40,	dissRegister40
	defw	dissCm,		dissComma
	defw	dissN,		dissImmediate
	defw	dissLnnL,	diss16Ref
	defw	dissLrrL,		dissR54Ref
	defw	dissR54AF,	diss16BitRegAF
	defw	dissR54SP,	diss16BitRegSP
	defw	dissNN,		diss16Immediate
	defw	dissCC,		dissCondition8
	defw	dissCC1,	dissCondition4
	defw	dissREL,		dissRelativeJump
	defw	dissAddr,	dissRestartAddr
	defw	dissLnL,		dissRelativeOneByte
	defw	dissNBit,	dissBitNumber
	defw	dissLR54L,	diss16BitRegL
	defw	dissR54PLS,	diss16BitRegPlus
	defw	dissHL,		dissPrintHL
	defw	dissLhlL,	dissPrintLhlL
	defw	dissR81,	dissRegister81
	;
	; Action routines
	;
dissRelativeOneByte:
	ld a,0x28
	ld (bc),a
	inc bc
ip1:	call dissImmediate8
	ld a,0x29
	ld (bc),a
	inc bc
ip2:	jp dissActionDone

dissImmediate:
ip3:	call dissImmediate8
ip4:	jp dissActionDone

dissImmediate8:			; 8 bit immediate
	inc de
ip5:	call dissAddOpcode
	ld a,(de)
	push de
	call _toHex
	ld a,d
	ld (bc),a
	inc bc
	ld a,e
	ld (bc),a
	inc bc
	pop de
	ret	

diss16Immediate:		; 16 bit immediate
ip6:	call diss16
ip7:	jp dissActionDone

diss16Ref:
	ld a,0x28
	ld (bc),a
	inc bc
ip8:	call diss16
	ld a,0x29
	ld (bc),a
	inc bc
ip9:	jp dissActionDone

diss16:
	inc de
ipa:	call dissAddOpcode
	inc de
ipb:	call dissAddOpcode
	ld a,(de)
	push de
	call _toHex
	ld a,d
	ld (bc),a
	inc bc
	ld a,e
	ld (bc),a
	inc bc
	pop de
	dec de
	ld a,(de)
	push de
	call _toHex
	ld a,d
	ld (bc),a
	inc bc
	ld a,e
	ld (bc),a
	inc bc
	pop de
	inc de
	ret

dissRelativeJump:		; generate address of a relative jump
	inc de
iq1:	call dissAddOpcode
	ld a,(de)				; offset from de+1
	push de
	inc de				; base of offset
	ex de,hl
	ld d,0
	ld e,a
	bit 7,a				; positive offset?
	jr z,dissRel2
	ld d,0xff				; negate de
dissRel2:
	add hl,de
	ld a,h
	call _toHex
	ld a,d
	ld (bc),a
	inc bc
	ld a,e
	ld (bc),a
	inc bc
	ld a,l
	call _toHex
	ld a,d
	ld (bc),a
	inc bc
	ld a,e
	ld (bc),a
	inc bc
	pop de
iq2:	jp dissActionDone


dissRegister81:			; print r from bits 210 

	ld a,(ix+dissFlags)	; ix or iy?
	or a
	jr z,dissRegister8

	ld a,(de)
	bit 7,(ix+dissFlags)	; has the +n been consumed? If so, reach back over it to get the opcode
	jr z,dissRegister811	; e.g., ld d,(ix+87) - has not yet encountered the 87
	dec de				; e.g., ld (ix+88),e - has encountered the 88, therefore needs to backtrack to get the opcode
	ld a,(de)				; step back to behind IX/IY+n offset and get the opcodes to figure out the register
	inc de
dissRegister811:
	and 7				; op code
iq3:	ld hl,dissRegisterTable
iq4:	call dissRegister41
iq5:	jp dissActionDone

dissRegister8:			; print r from bits 210
	ld a,(de)
	and 7				; op code
iq6:	ld hl,dissRegisterTable
iq7:	call dissRegister41
iq8:	jp dissActionDone

dissComma:
	ld a,','
	ld (bc),a
	inc bc
iq9:	jp dissActionDone

dissBitNumber:			; print bit number from bits 543
iqa:	ld hl,dissBitNumberTable
iqb:	call diss543single
iqc:	jp dissActionDone

dissRegister40:			; print r from bits 543
ir1:	ld hl,dissRegisterTable
ir2:	call diss543single
ir3:	jp dissActionDone

diss543single:			; print a single lookup from bits 543
	ld a,(de)				; op code
	and 0x38
	rra
	rra
	rra
dissRegister41
	add a,l
	ld l,a
	jr nc,dissRegister42
	inc h
dissRegister42:
	ld a,(hl)
	ld (bc),a
	inc bc
	cp 'X'
	jr nz,dissRegister44
	dec bc
ir4:	call dissDolHLl
	;ld hl,dissRegisterHL
	;call dissCopyString
dissRegister44:
	ret

dissRegisterTable:
	defm "bcdehlXa"
dissBitNumberTable:
	defm "01234567"
dissRegisterHL
	defm "(hl)"
	defb 0	

dissR54Ref:
	ld a,0x28
	ld (bc),a
	inc bc
ir5:	ld hl,diss16RegisterTableSP
ir6:	call diss16BitRegSP
	ld a,0x29
	ld (bc),a
	inc bc
ir7:	jp dissActionDone

diss16BitRegAF:			; print register rr from bits 54
ir8:	ld hl,diss16RegisterTableAF
ir9:	call diss54
ira:	jp dissActionDone
diss16BitRegSP:			; print register rr from bits 54
irb:	ld hl,diss16RegisterTableSP
irc:	call diss54
ird:	jp dissActionDone

diss16BitRegL:			; print register rr from bits 54 (de)
	ld a,0x28
	ld (bc),a
	inc bc
is1:	ld hl,diss16RegisterTableSP
is2:	call diss54
	ld a,0x29
	ld (bc),a
	inc bc
is3:	jp dissActionDone

diss16BitRegPlus:		; print register rr from bits 54 after immediate address
	dec de
	dec de
is4:	ld hl,diss16RegisterTableSP
is5:	call diss54
	inc de
	inc de
is6:	jp dissActionDone

dissCondition8:
is7:	ld hl,dissConditionTable1
is8:	call diss543
is9:	jp dissActionDone
dissCondition4:
isa:	ld hl,dissConditionTable2
isb:	call diss543
isc:	jp dissActionDone
dissRestartAddr:
it1:	ld hl,dissRestartsTable
it2:	call diss543
it3:	jp dissActionDone


diss543:
	ld a,(de)
	and 0x38
	rra
	rra
	jr dissR16BitReg1
diss54:
	ld a,(de)				; op code
	and 0x30
	rra
	rra
	rra
	or (ix+dissFlags)		; add IX and IY
	and 0x3f			; ignore bit 7 which is used for something else
dissR16BitReg1
	add a,l
	ld l,a
	jr nc,dissR16BitReg2
	inc h
dissR16BitReg2:
	ld a,(hl)
	ld (bc),a
	inc bc
	inc hl
	ld a,(hl)
	ld (bc),a
	inc bc
	ret

diss16RegisterTableAF:
	defm "bcdehlafbcdeixafbcdeiyaf"
diss16RegisterTableSP:
	defm "bcdehlspbcdeixspbcdeiysp"

dissConditionTable1:
	defm "nz znc cpope p m"
dissConditionTable2:
	defm "xxxxxxxxnz znc c"
dissRestartsTable:
	defm "0008101820283038"

dissPrintLhlL:
it4:	call dissDolHLl
it5:	jp dissActionDone

dissPrintHL:
it6:	call dissDoHL
it7:	jp dissActionDone

dissDolHLl:
	ld a,0x28
	ld (bc),a
	inc bc
it8:	call dissDoHL
	ld a,(ix+dissFlags)			; is there an ix or iy prefix?
	or a
	jr z,dissDolHLl1
	inc de						; ix or iy offset
it9:	call dissAddOpCode
	ld a,'+'
	ld (bc),a
	inc bc
	push de
	ld a,(de)
	call _toHex					; TODO- make it +/-
	ld a,d
	ld (bc),a
	inc bc
	ld a,e
	ld (bc),a
	inc bc
	pop de
	set 7,(ix+dissFlags)			; +n offset has been consumed
dissDolHLl1:
	ld a,0x29
	ld (bc),a
	inc bc
	ret

dissDoHL:						; print HL, IX or IY
	bit 3,(ix+dissFlags)
	jr z,dissDoHL1
	ld a,'i'
	ld (bc),a
	inc bc
	ld a,'x'
	ld (bc),a
	inc bc
	ret
dissDoHL1:
	bit 4,(ix+dissFlags)
	jr z,dissDoHL2
	ld a,'i'
	ld (bc),a
	inc bc
	ld a,'y'
	ld (bc),a
	inc bc
	ret
dissDoHL2
	ld a,'h'
	ld (bc),a
	inc bc
	ld a,'l'
	ld (bc),a
	inc bc
	ret




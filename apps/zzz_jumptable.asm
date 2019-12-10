		;
		; Jump table
		; Make core routines accessible to loadable programs

	org 0x2080
_malloc:			jp malloc
_free			jp free
_lineEditorInit:	jp lineEditorInit
_processKey:		jp processKey
_debug			jp debug
_toHex			jp toHex
_debugRegisters	jp debugRegisters
_putDecimal		jp putTermDecimal
_put16			jp putTerm16
_putCRLF		jp putCRLF
_yield			jp procYield
_newProcess		jp newProcess
_getCh			jp dartGetKey
_putCh			jp dartPutTerm
_putString		jp dartPutString
_tokenize		jp parserTokenize
_parseByteToken	jp parseByteToken
_parseByteNoun	jp parseByteNoun
_relocate		jp blockRelocate
_strcmp			jp strcmp
_strcpy			jp strcpy
_register			jp progRegister
_unregister		jp progRemove



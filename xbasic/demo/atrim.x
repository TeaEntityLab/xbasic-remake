'
' ####################
' #####  PROLOG  #####
' ####################
'
' This program demonstrates the LTRIM$(), RTRIM$(), TRIM$() intrinsics,
' and also the XstLTRIM(), XstRTRIM(), XstTRIM() library functions.
' See comments in function Entry() for details.
'
'
PROGRAM	"atrim"
VERSION	"0.0000"
'
IMPORT "xst"
IMPORT "xui"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
' The LTRIM$(), RTRIM$(), TRIM$() intrinsics trim
' all characters with values <= 0x20 and >= 0x80 .
' This generally works fine for English, but may
' trim characters valid/desired in other languages.
'
' The XstLTRIM(), XstRTRIM(), XstTRIM() functions
' accept an XLONG array argument to specify which
' characters should be trimmed.  Only characters
' with zero in the corresponding array location
' are trimmed by these functions.
'
FUNCTION  Entry ()
'
' create array for XstLTRIM(), XstRTRIM(), XstTRIM()
'
	DIM array[255]							' array to hold trim characters
'
	FOR i = 0 TO 255						' for all characters
		array[i] = i							'	trim nothing except 0x00 - null character
	NEXT i
'
' set array to trim only four characters and no others
'
	array[' '] = 0							' trim space characters
	array['\t'] = 0							' trim tab characters
	array[0x00] = 0							' trim null characters
	array[0xFF] = 0							' trim character 255
'
' create some test strings
'
	upper = 47
	DIM s$[upper]
'
	s$[00] = "xxxxxxxxx"
	s$[01] = " xxxxxxxx"
	s$[02] = "  xxxxxxx"
	s$[03] = "xxxxxxxx "
	s$[04] = "xxxxxxx  "
	s$[05] = " xxxxxxx "
	s$[06] = "  xxxxx  "
	s$[07] = "  xx xx  "
'
	s$[08] = "xxxxxxxxx"
	s$[09] = "\txxxxxxxx"
	s$[10] = "\t\txxxxxxx"
	s$[11] = "xxxxxxxx\t"
	s$[12] = "xxxxxxx\t\t"
	s$[13] = "\txxxxxxx\t"
	s$[14] = "\t\txxxxx\t\t"
	s$[15] = "\t\txx\txx\t\t"
'
	s$[16] = "xxxxxxxxx"
	s$[17] = "\0xxxxxxxx"
	s$[18] = "\0\0xxxxxxx"
	s$[19] = "xxxxxxxx\0"
	s$[20] = "xxxxxxx\0\0"
	s$[21] = "\0xxxxxxx\0"
	s$[22] = "\0\0xxxxx\0\0"
	s$[23] = "\0\0xx\0xx\0\0"
'
	s$[24] = "xxxxxxxxx"
	s$[25] = "\xFFxxxxxxxx"
	s$[26] = "\xFF\xFFxxxxxxx"
	s$[27] = "xxxxxxxx\xFF"
	s$[28] = "xxxxxxx\xFF\xFF"
	s$[29] = "\xFFxxxxxxx\xFF"
	s$[30] = "\xFF\xFFxxxxx\xFF\xFF"
	s$[31] = "\xFF\xFFxx\xFFxx\xFF\xFF"
'
	s$[32] = "xxxxxxxxx"
	s$[33] = "\x10xxxxxxxx"
	s$[34] = "\x10\x10xxxxxxx"
	s$[35] = "xxxxxxxx\x10"
	s$[36] = "xxxxxxx\x10\x10"
	s$[37] = "\x10xxxxxxx\x10"
	s$[38] = "\x10\x10xx\x10xx\x10\x10"
	s$[39] = "\x10\x10xx\x10xx\x10\x10"
'
	s$[40] = "xxxxxxxxx"
	s$[41] = "\xA0xxxxxxxx"
	s$[42] = "\xA0\xA0xxxxxxx"
	s$[43] = "xxxxxxxx\xA0"
	s$[44] = "xxxxxxx\xA0\xA0"
	s$[45] = "\xA0xxxxxxx\xA0"
	s$[46] = "\xA0\xA0xx\xA0xx\xA0\xA0"
	s$[47] = "\xA0\xA0xx\xA0xx\xA0\xA0"
'
' show what each function does
'
	PRINT
	PRINT "::: note ::: tab characters disturb the column alignment in some rows"
	PRINT
	PRINT "              LTRIM$()/XstLTRIM   RTRIM$()/XstRTRIM   TRIM$()/XstTRIM"
'
	FOR i = 0 TO upper
		string$ = s$[i]
		a$ = LTRIM$ (string$)
		b$ = RTRIM$ (string$)
		c$ = TRIM$ (string$)
'
		d$ = string$
		e$ = string$
		f$ = string$
'
		XstLTRIM (@d$, @array[])
		XstRTRIM (@e$, @array[])
		XstTRIM (@f$, @array[])
'
		PRINT "intrinsic :   ";
		PRINT LJUST$ ("<" + a$ + ">", 20);
		PRINT LJUST$ ("<" + b$ + ">", 20);
		PRINT LJUST$ ("<" + c$ + ">", 20)
		PRINT "functions :   ";
		PRINT LJUST$ ("<" + d$ + ">", 20);
		PRINT LJUST$ ("<" + e$ + ">", 20);
		PRINT LJUST$ ("<" + f$ + ">", 20)
'		PRINT
	NEXT i
END FUNCTION
END PROGRAM

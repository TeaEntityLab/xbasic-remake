'
'
' ####################  QuickBasic to XBasic translator
' #####  PROLOG  #####  copyright 1999
' ####################  Max Reason
'
PROGRAM	"qbtoxb"
VERSION	"0.0060"
'
IMPORT	"xma"
IMPORT	"xst"
IMPORT	"xgr"
IMPORT	"xui"
'
' This software is "open source", subject to the terms and conditions
' of the GPU = "GNU general public license", which is reproduced at
' http://www.opensource.org/licenses/gpl-license.html .
'
' Microsoft distributes a stripped-down QuickBasic product called QBasic,
' but throughout this program, qbasic and QBasic always refer-to QuickBasic.
'
' This program is currently work-in-progress and far from functional.
'
' This following summarizes the flow of this program.
'
'	Entry()													' the entry function - start here
'		LoadQBasicProgram()						' load QBasic program into qbasic$[]
'		QBasicToXBasic()							' translate qbasic$[] source into xbasic$[]
'			Initialize()								' initialize everything that needs initializing
'				InitializeVariables()			' create and initialize fundamental variables and arrays
'				InitializeQBasicTokens()	' defines all QBasic language-defined symbols and tokens
'				InitializeXBasicTokens()	' defines all XBasic language-defined symbols and tokens
'				InitializeQBasicTokens()	' adds XBasic-equivalent-tokens to QBasic tokens
'				InitializeXBasicTokens()	' pass #2 probably not necessary for XBasic
'				ParseQBasic()							' parse QBasic source-code into tokens
'					CallsManyFunctions 			' ParseQBasic() calls many functions
'				Translate()								' translate tokens into XBasic source
'					TranslateLine()					' translate line of tokens to XBasic
'					CallsManyFunctions			' Translate() calls many functions
'
'
' Parsing a QuickBasic program creates an array of token-numbers
' in three-dimensional array #program[function,line,token].
' The lower 24-bits of a token is the token-number, which gives
' access to information about the token at #token[token-number].
' The upper 8-bits of a token contains leading-whitespace info.
' See the TOKEN composite data-type declaration below for details.
'
'
' #######################################
' #####  composite/structure types  #####
' #######################################
'
' TOKEN variables hold both QBasic and XBasic tokens.
'
TYPE TOKEN								'
	XLONG			.token				' token number in #token[]
	XLONG			.string				' string number in #string$[]
	XLONG			.length				' length of string in characters
	XLONG			.function			' function number this string is in
	XLONG			.hashback			' previous token with same hash
	XLONG			.hashnext			' next token with same hash
	XLONG			.kindback			' previous token of same kind
	XLONG			.kindnext			' next token of same kind
	XLONG			.first				' first executable line in source
	XLONG			.final				' final executable line in source
	XLONG			.hash					' hash value of this string
	XLONG			.kind					' statement, operator, etc.
	XLONG			.type					' data-type - SBYTE, UBYTE, SSHORT, USHORT, etc.
	XLONG			.scope				' scope of allocation - AUTO, STATIC, SHARED, EXTERNAL
	XLONG			.translate		' translate token - in other language
	XLONG			.address			' address in memory
	XLONG			.akind[15]		' argument kinds
	XLONG			.atype[15]		' argument data-types
	GIANT			.ivalue				' any integer-type value
	DOUBLE		.fvalue				' floating-point value
	XLONG			.lineq				' function source line - QB
	XLONG			.linex				' function source line - XB
	XLONG			.reserve54		'
	XLONG			.reserve55		'
	XLONG			.reserve56		'
	XLONG			.reserve57		'
	XLONG			.reserve58		'
	XLONG			.reserve59		'
	XLONG			.reserve60		'
	XLONG			.reserve61		'
	XLONG			.reserve62		'
	XLONG			.reserve63		'
END TYPE
'
'
' #######################
' #####  functions  #####
' #######################
'
DECLARE FUNCTION  Entry                   ()
DECLARE FUNCTION  Initialize              ()
DECLARE FUNCTION  InitializeVariables     ()
DECLARE FUNCTION  InitializeQBasicTokens  ()
DECLARE FUNCTION  InitializeXBasicTokens  ()
DECLARE FUNCTION  LoadQBasicProgram       (@qbasic$[])								' find and load QBasic program
DECLARE FUNCTION  QBasicToXBasic          (@qbasic$[], @xbasic$[])		' translate QBasic to XBasic
DECLARE FUNCTION  ParseQBasic             ()													' parse QBasic program to create tokens
DECLARE FUNCTION  Translate               ()													' translate program tokens to XBasic source
DECLARE FUNCTION  TranslateLine           (@line[])										' translate line of tokens to XBasic source
DECLARE FUNCTION  TranslateStatement			(@line[], @offset)					' translate statement on line to XBasic source
'
DECLARE FUNCTION  DeparseTokens           (@token[], @line$)					' convert tokens into line of source
DECLARE FUNCTION  ParseSourceLine         (@line$, @line[])						' parse source line into tokens
DECLARE FUNCTION  ParseWhitespace         (@line$, @offset)						' parse whitespace characters
DECLARE FUNCTION  ParseCharacter          (@line$, @offset)						' parse special character (operators, etc)
DECLARE FUNCTION  ParseNumber             (@line$, @offset)						' parse numeric string
DECLARE FUNCTION  ParseSymbol             (@line$, @offset)						' parse symbol
DECLARE FUNCTION  GetSymbol               (@line$, @offset, @symbol$)	' get symbol
DECLARE FUNCTION  OutputToken             (@token)										' output token
DECLARE FUNCTION  TestForKeyword          (@symbol$)									' keyword?
DECLARE FUNCTION  MinTypeFromGiant        (value$$)										' integer type
DECLARE FUNCTION  MinTypeFromDouble       (value#)										' float type
'
DECLARE FUNCTION  AddKeyword              (translate, function, scope, kind, type, atype1, atype2, atype3, @string$)
DECLARE FUNCTION  FindToken               (@match[], function, scope, kind, type, atype1, atype2, atype3, @string$)
DECLARE FUNCTION  AddToken                (@token, function, scope, kind, type, atype1, atype2, atype3, @string$)
DECLARE FUNCTION  OutputXBasic            (@text$[])
DECLARE FUNCTION  TokenRestOfLine         ()
DECLARE FUNCTION  PrintTokens             ()
DECLARE FUNCTION  PrintHash               ()
DECLARE FUNCTION  Terminate               ()
'
'
'
' ##############################
' #####  shared constants  #####
' ##############################
'
	$$TYPE_NONE							= 0x00000000	' NONE - type unknown
	$$TYPE_VOID							= 0x00000001	' VOID - type prohibited
	$$TYPE_SBYTE						= 0x00000002	' SBYTE - 8-bit signed integer
	$$TYPE_UBYTE						= 0x00000003	' UBYTE - 8-bit unsigned integer
	$$TYPE_SSHORT						= 0x00000004	' SSHORT - 16-bit signed integer
	$$TYPE_USHORT						= 0x00000005	' USHORT - 16-bit unsigned integer
	$$TYPE_SLONG						= 0x00000006	' SLONG - 32-bit signed integer
	$$TYPE_ULONG						= 0x00000007	' ULONG - 32-bit unsigned integer
	$$TYPE_XLONG						= 0x00000008	' XLONG - CPU integer
	$$TYPE_GOADDR						= 0x00000009	' GOADDR - label address
	$$TYPE_SUBADDR					= 0x0000000A	' SUBADDR - subroutine address
	$$TYPE_FUNCADDR					= 0x0000000B	' FUNCADDR - function address
	$$TYPE_GIANT						= 0x0000000C	' GIANT - 64-bit signed integer
	$$TYPE_SINGLE						= 0x0000000D	' SINGLE - IEEE 32-bit
	$$TYPE_DOUBLE						= 0x0000000E	' DOUBLE - IEEE 64-bit
	$$TYPE_UNDEFINED				= 0x0000000F	'
	$$TYPE_STRING						= 0x00000013	' STRING - string/array of UBYTEs
	$$TYPE_STRING_ASCII			= 0x00000013	' STRING - string/array of UBYTEs
	$$TYPE_STRING_UNICODE		= 0x00000015	' UNICODE - string/array of USHORTs
	$$TYPE_COMPOSITE_FIRST	= 0x00000020	' first composite type
	$$TYPE_COMPOSITE_FINAL	= 0x0000FFFF	' final composite type
'
	$$FORM_BIT							= 0x00010001	' 0b01001101
	$$FORM_OCTAL						= 0x00010002	' 0o01234567
	$$FORM_DECIMAL					= 0x00010003	' 1234567890
	$$FORM_HEXADECIMAL			= 0x00010004	' 0x0123456789ABCDEF or &H0123456789ABCDEF
'
	$$KIND_NONE							= 0x00000000	' kind unknown
	$$KIND_STATEMENT				= 0x00000001	' language statement
	$$KIND_INTRINSIC				= 0x00000002	' intrinsic function
	$$KIND_OPERATOR					= 0x00000004	' OR  AND  XOR  +  -  *  \  /  etc.
	$$KIND_KEYWORD					= 0x00000008	'
	$$KIND_LABEL						= 0x00000010	' GOTO label
	$$KIND_SUBNAME					= 0x00000020	' GOSUB subname
	$$KIND_FUNCTION					= 0x00000040	' function in program
	$$KIND_TYPE							= 0x00000080	' data-type
	$$KIND_SYMBOL						= 0x00000100	' unknown kind of symbol
	$$KIND_LITERAL					= 0x00000200	' number or string
	$$KIND_CHARCON					= 0x00000400	' character constant - as in 'a'
	$$KIND_CONSTANT					= 0x00000800	' user-defined constant
	$$KIND_VARIABLE					= 0x00001000	' simple variable
	$$KIND_ARRAY						= 0x00002000	' array variable
	$$KIND_COMPOSITE        = 0x00004000	' structure symbol
	$$KIND_ELEMENT					= 0x00008000	' structure element
	$$KIND_COMMENT					= 0x00010000	' rest of the line
	$$KIND_CHARACTER				= 0x00020000	' : ; , ( )
	$$KIND_WHITESTRING			= 0x00040000	' string of whitespace
	$$KIND_AVAILABLE_19			= 0x00080000	'
	$$KIND_AVAILABLE_20			= 0x00100000	'
	$$KIND_AVAILABLE_21			= 0x00200000	'
	$$KIND_AVAILABLE_22			= 0x00400000	'
	$$KIND_AVAILABLE_23			= 0x00800000	'
	$$KIND_AVAILABLE_24			= 0x01000000	'
	$$KIND_AVAILABLE_25			= 0x02000000	'
	$$KIND_AVAILABLE_26			= 0x04000000	'
	$$KIND_AVAILABLE_27			= 0x08000000	'
	$$KIND_AVAILABLE_28			= 0x10000000	'
	$$KIND_AVAILABLE_29			= 0x20000000	'
	$$KIND_QBASIC						= 0x40000000	' QBasic language element
	$$KIND_XBASIC						= 0x80000000	' XBasic language element
'
	$$SCOPE_NONE						= 0x00000000	' scope unknown
	$$SCOPE_AUTO						= 0x00000001	' function and temporary
	$$SCOPE_AUTOX						= 0x00000002	' function and temporary
	$$SCOPE_STATIC					= 0x00000003	' function and permanent
	$$SCOPE_SHARED					= 0x00000004	' program and permanent
	$$SCOPE_SHARED_NAME			= 0x00000005	' program and permanent - sharename
	$$SCOPE_EXTERNAL				= 0x00000006	' modules and permanent - static linked modules
	$$SCOPE_EXTERNAL_NAME		= 0x00000007	' modules and permanent - static linked modules - sharename
'
	$$MIN_SBYTE				= -128
	$$MAX_SBYTE				= 127
	$$MIN_UBYTE				= 0
	$$MAX_UBYTE				= 255
	$$MIN_SSHORT			= -32768
	$$MAX_SSHORT			= 32767
	$$MIN_USHORT			= 0
	$$MAX_USHORT			= 65535
	$$MIN_SLONG				= -2147483648
	$$MAX_SLONG				= 2147483647
	$$MIN_ULONG				= 0
	$$MAX_ULONG				= 4294967395$$
	$$MIN_XLONG				= $$MIN_SLONG
	$$MAX_XLONG				= $$MAX_ULONG
	$$MIN_GOADDR			= $$MIN_XLONG
	$$MAX_GOADDR			= $$MAX_XLONG
	$$MIN_SUBADDR			= $$MIN_XLONG
	$$MAX_SUBADDR			= $$MAX_XLONG
	$$MIN_FUNCADDR		= $$MIN_XLONG
	$$MAX_FUNCADDR		= $$MAX_XLONG
	$$MIN_SINGLE			= 0sFF7FFFFF
	$$MAX_SINGLE			= 0s7F7FFFFF
	$$MIN_DOUBLE			= 0dFFEFFFFFFFFFFFFF
	$$MAX_DOUBLE			= 0d7FEFFFFFFFFFFFFF
	$$MIN_GIANT				= 0x8000000000000000
	$$MAX_GIANT				= 0x7FFFFFFFFFFFFFFF
'
'
' ##############################
' #####  shared variables  #####
' ##############################
'
	TOKEN		#toktemp						' temporary - for compiler tests
	XLONG		#print							' temporary - for debugging
'
	XLONG		#pass								' pass # for parse or compile
	XLONG		#line								' current line in function
	XLONG		#token							' current token on line
	XLONG		#function						' function being parsed or translated
	XLONG		#whitebyte					' whitestring # = entry in #whitestring$[]
'
	XLONG		#ustring						' upper-bound of #string$[]
	XLONG		#nstring						' next slot in #string$[]
	XLONG		#utoken							' upper-bound of #token[]
	XLONG		#ntoken							' next slot in #token[]
'
	XLONG		#quline							' upper QBasic source-code line
	XLONG		#qnline							' next QBasic source-code line
	XLONG		#xuline							' upper XBasic source-code line
	XLONG		#xnline							' next XBasic source-code line
'
	XLONG		#qatoken						' first QBasic keyword token-number
	XLONG		#qztoken						' final QBasic keyword token-number
	XLONG		#xatoken						' first XBasic keyword token-number
	XLONG		#xztoken						' final XBasic keyword token-number
'
	USHORT	#hx[]								' hash mixer
	XLONG		#hash[]							' hash table
	XLONG		#kind[]							' first token of each kind
	TOKEN		#token[]						' holds all symbol-table tokens
	STRING	#string$[]					' holds all symbol-table strings
	XLONG		#program[]					' holds token-numbers for entire program : #program[function,line,token]
	XLONG		#functoken[]				' holds token-number of every function in the program
	XLONG		#whitetoken[]				' token-numbers of 256 leading-whitespace strings representable in upper-byte of tokens
'
	STRING	#qbasic$[]					' holds entire QBasic source program
	STRING	#xbasic$[]					' holds entire XBasic source program
'
' the following arrays test and/or convert characters in a single array access
'
	UBYTE		#charsetSymbolFirst[]
	UBYTE		#charsetSymbolInner[]
	UBYTE		#charsetSymbolFinal[]
	UBYTE		#charsetSymbol[]
	UBYTE		#charsetUpper[]
	UBYTE		#charsetLower[]
	UBYTE		#charsetNumeric[]
	UBYTE		#charsetUpperLower[]
	UBYTE		#charsetUpperNumeric[]
	UBYTE		#charsetLowerNumeric[]
	UBYTE		#charsetUpperLowerNumeric[]
	UBYTE		#charsetUpperToLower[]
	UBYTE		#charsetLowerToUpper[]
	UBYTE		#charsetVex[]
	UBYTE		#charsetHexUpper[]
	UBYTE		#charsetHexLower[]
	UBYTE		#charsetHexUpperLower[]
	UBYTE		#charsetHexUpperToLower[]
	UBYTE		#charsetHexLowerToUpper[]
	UBYTE		#charsetBackslash[]
	UBYTE		#charsetBackslashByte[]
	UBYTE		#charsetBackslashChar[]
	UBYTE		#charsetNormalChar[]
	UBYTE		#charsetOctal[]
	UBYTE		#charsetPrintChar[]
	UBYTE		#charsetSuffix[]
	UBYTE		#charsetSpaceTab[]
	UBYTE		#charsetWhitespace[]
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	XstGetConsolePositionAndSize (@xDisp, @yDisp, @width, @height)
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
	maxwidth = #displayWidth - #windowBorderWidth - #windowBorderWidth
'
	width = MIN (maxwidth, 1016)
'
' set console width for printing speed efficiency and smoothness
'
	XstCreateConsole (xDisp, yDisp, width, height)
'
	LoadQBasicProgram (@qbasic$[])						' load QBasic program into qbasic$[]
	QBasicToXBasic (@qbasic$[], @xbasic$[])		' translate qbasic$[] into xbasic$[]
END FUNCTION
'
'
' ###########################
' #####  Initialize ()  #####
' ###########################
'
FUNCTION  Initialize ()
'
	#print = 1
'
	#pass = 0											'
	InitializeVariables ()				' create arrays for tokens, symbols, etc.
'
	#pass = 1
	#ntoken = 0										' zero token number
	#nstring = 0									' zero string number
	InitializeXBasicTokens ()			' pass 1 cannot fill-in equivalent QBasic tokens
	InitializeQBasicTokens ()			' pass 1 cannot fill-in equivalent XBasic tokens
'
	#pass = 2
	#ntoken = 0										' zero token number
	#nstring = 0									' zero string number
	InitializeXBasicTokens ()			' pass 2 can fill-in equivalent QBasic tokens
	InitializeQBasicTokens ()			' pass 2 can fill-in equivalent XBasic tokens
'
	#pass = 0											'
	IF #print THEN PrintTokens ()	' look at the tokens
'
	IF #print THEN
		PRINT "               "; HEX$(#xatoken,4);; HEX$(#xztoken,4);; HEX$(#qatoken,4);; HEX$(#qztoken,4)
		PRINT
		PrintHash ()								' look at hash table
	END IF
END FUNCTION
'
'
' ####################################
' #####  InitializeVariables ()  #####
' ####################################
'
FUNCTION  InitializeVariables ()
'
	#nwhite = 0												' start at white 0
	#ntoken = 0												' start at token 0
	#nstring = 0											' start at string 0
	#function = 0											' start with PROLOG
'
	#uhash = 255											' 8-bit hash size for now
	#uwhite = 255											' maximum of 255 whitestrings
	#utoken = 4095										' start with room for 4096 tokens
	#ustring = 4095										' start with room for 4096 strings
	#ufunction = 1023									' start with room for 1024 functions
	#uwhitestring = 255								' never more than 255 leading-whitestring tokens
'
	DIM #hx[255]											' dimension hash mix
	DIM #hash[#uhash]									' dimension hash array
	DIM #token[#utoken]								' dimension token array
	DIM #string$[#ustring]						'	dimension string array
	DIM #program[#ufunction,]					' dimension program array
	DIM #functoken[#ufunction]				' dimension function array
	DIM #whitetoken[#uwhitestring]		' dimension whitetoken array
	DIM #whitestring$[#uwhitestring]	' dimension whitestring array
'
	#hx[  0] = 0xF3C9	: #hx[ 64] = 0x811D	: #hx[128] = 0x199C	: #hx[192] = 0xD0C8
	#hx[  1] = 0xE034	: #hx[ 65] = 0xC6E3	: #hx[129] = 0x1299	: #hx[193] = 0x3C07
	#hx[  2] = 0xB37C	: #hx[ 66] = 0xCA5D	: #hx[130] = 0xA314	: #hx[194] = 0xDDCA
	#hx[  3] = 0x4E31	: #hx[ 67] = 0x5AF2	: #hx[131] = 0xEF45	: #hx[195] = 0xB2C1
	#hx[  4] = 0xC0DE	: #hx[ 68] = 0xB2F3	: #hx[132] = 0xEFC3	: #hx[196] = 0x6A7C
	#hx[  5] = 0x2487	: #hx[ 69] = 0xCF28	: #hx[133] = 0x8A2D	: #hx[197] = 0x5E02
	#hx[  6] = 0x98E2	: #hx[ 70] = 0x4714	: #hx[134] = 0x2553	: #hx[198] = 0x4C8B
	#hx[  7] = 0x557C	: #hx[ 71] = 0x32B0	: #hx[135] = 0x8CA6	: #hx[199] = 0x6652
	#hx[  8] = 0xA6CB	: #hx[ 72] = 0x9A76	: #hx[136] = 0x60B8	: #hx[200] = 0x3C50
	#hx[  9] = 0x410D	: #hx[ 73] = 0xB2A4	: #hx[137] = 0x2192	: #hx[201] = 0x02B8
	#hx[ 10] = 0x7767	: #hx[ 74] = 0xDE9B	: #hx[138] = 0xA15C	: #hx[202] = 0x7B70
	#hx[ 11] = 0x3861	: #hx[ 75] = 0xE0E1	: #hx[139] = 0xA527	: #hx[203] = 0x118F
	#hx[ 12] = 0x5517	: #hx[ 76] = 0xA7C3	: #hx[140] = 0x1FAC	: #hx[204] = 0xEF65
	#hx[ 13] = 0x0918	: #hx[ 77] = 0x0E48	: #hx[141] = 0xC554	: #hx[205] = 0x3D6E
	#hx[ 14] = 0xF3AF	: #hx[ 78] = 0xFABE	: #hx[142] = 0x5ECB	: #hx[206] = 0xCAB2
	#hx[ 15] = 0x2EAB	: #hx[ 79] = 0xE351	: #hx[143] = 0x7941	: #hx[207] = 0x23F0
	#hx[ 16] = 0x210D	: #hx[ 80] = 0x4419	: #hx[144] = 0x3EA2	: #hx[208] = 0x927F
	#hx[ 17] = 0xDF19	: #hx[ 81] = 0x5AB4	: #hx[145] = 0xE73D	: #hx[209] = 0x1F12
	#hx[ 18] = 0x2F0B	: #hx[ 82] = 0xDDF9	: #hx[146] = 0xDE62	: #hx[210] = 0xEDCE
	#hx[ 19] = 0x269A	: #hx[ 83] = 0x513E	: #hx[147] = 0x9FFA	: #hx[211] = 0x0D52
	#hx[ 20] = 0xE171	: #hx[ 84] = 0x1BDF	: #hx[148] = 0x0CE8	: #hx[212] = 0x69B5
	#hx[ 21] = 0x8D07	: #hx[ 85] = 0xA0BC	: #hx[149] = 0x8683	: #hx[213] = 0x9DC4
	#hx[ 22] = 0x0AF1	: #hx[ 86] = 0xC2E5	: #hx[150] = 0x481C	: #hx[214] = 0x910F
	#hx[ 23] = 0x4627	: #hx[ 87] = 0x5917	: #hx[151] = 0x80E4	: #hx[215] = 0xEE6D
	#hx[ 24] = 0x7C4B	: #hx[ 88] = 0x0448	: #hx[152] = 0xC43E	: #hx[216] = 0xA0E7
	#hx[ 25] = 0xA59A	: #hx[ 89] = 0xE110	: #hx[153] = 0x7830	: #hx[217] = 0xF2ED
	#hx[ 26] = 0x561F	: #hx[ 90] = 0xA4C8	: #hx[154] = 0x3952	: #hx[218] = 0x6EA2
	#hx[ 27] = 0x1F90	: #hx[ 91] = 0x5BC6	: #hx[155] = 0x2BBA	: #hx[219] = 0xFEFC
	#hx[ 28] = 0x9407	: #hx[ 92] = 0x1250	: #hx[156] = 0x476D	: #hx[220] = 0x0A20
	#hx[ 29] = 0xAAAA	: #hx[ 93] = 0x3D09	: #hx[157] = 0xF307	: #hx[221] = 0xA568
	#hx[ 30] = 0x404B	: #hx[ 94] = 0xD230	: #hx[158] = 0x5A6A	: #hx[222] = 0xB90E
	#hx[ 31] = 0xCCB2	: #hx[ 95] = 0x19F1	: #hx[159] = 0x232A	: #hx[223] = 0xFA26
	#hx[ 32] = 0xB6B8	: #hx[ 96] = 0x28D0	: #hx[160] = 0x36DA	: #hx[224] = 0xFB8E
	#hx[ 33] = 0x93E5	: #hx[ 97] = 0x0FD7	: #hx[161] = 0x1448	: #hx[225] = 0x3091
	#hx[ 34] = 0xCD83	: #hx[ 98] = 0x79BD	: #hx[162] = 0x016A	: #hx[226] = 0x56A1
	#hx[ 35] = 0x8392	: #hx[ 99] = 0xE856	: #hx[163] = 0xF0CC	: #hx[227] = 0x184A
	#hx[ 36] = 0x951B	: #hx[100] = 0xDDDE	: #hx[164] = 0x5328	: #hx[228] = 0xDEC0
	#hx[ 37] = 0x983F	: #hx[101] = 0xBD28	: #hx[165] = 0x8B83	: #hx[229] = 0xC39F
	#hx[ 38] = 0x1BB3	: #hx[102] = 0xD9F7	: #hx[166] = 0x1566	: #hx[230] = 0xBED3
	#hx[ 39] = 0x40A7	: #hx[103] = 0xCBB9	: #hx[167] = 0xB0D3	: #hx[231] = 0x51F5
	#hx[ 40] = 0x5D7E	: #hx[104] = 0x9B85	: #hx[168] = 0xCE2F	: #hx[232] = 0xC0E9
	#hx[ 41] = 0x65A1	: #hx[105] = 0x82DC	: #hx[169] = 0x30FA	: #hx[233] = 0x617B
	#hx[ 42] = 0x8576	: #hx[106] = 0x67B0	: #hx[170] = 0x49C6	: #hx[234] = 0xF6E9
	#hx[ 43] = 0xAC39	: #hx[107] = 0x8720	: #hx[171] = 0x94D9	: #hx[235] = 0x9775
	#hx[ 44] = 0xFE04	: #hx[108] = 0x0CDF	: #hx[172] = 0xE69B	: #hx[236] = 0xD5A5
	#hx[ 45] = 0x6C6F	: #hx[109] = 0xA884	: #hx[173] = 0x7B2C	: #hx[237] = 0xF7D3
	#hx[ 46] = 0x838F	: #hx[110] = 0x238D	: #hx[174] = 0x340B	: #hx[238] = 0x2BD5
	#hx[ 47] = 0xDA44	: #hx[111] = 0xACED	: #hx[175] = 0x2E46	: #hx[239] = 0xBB3D
	#hx[ 48] = 0x7B93	: #hx[112] = 0x773B	: #hx[176] = 0xFD83	: #hx[240] = 0x1483
	#hx[ 49] = 0x851E	: #hx[113] = 0x84F1	: #hx[177] = 0xB1A9	: #hx[241] = 0x5906
	#hx[ 50] = 0xD23F	: #hx[114] = 0xB1A6	: #hx[178] = 0x6F78	: #hx[242] = 0x6D25
	#hx[ 51] = 0x1F47	: #hx[115] = 0x049F	: #hx[179] = 0xF3FE	: #hx[243] = 0x0BEE
	#hx[ 52] = 0x7C74	: #hx[116] = 0x8B30	: #hx[180] = 0x387B	: #hx[244] = 0xE76B
	#hx[ 53] = 0xBF9D	: #hx[117] = 0xB545	: #hx[181] = 0xCCC2	: #hx[245] = 0x6751
	#hx[ 54] = 0x7646	: #hx[118] = 0x48EC	: #hx[182] = 0x762C	: #hx[246] = 0x2A06
	#hx[ 55] = 0xC9FF	: #hx[119] = 0xF885	: #hx[183] = 0x603E	: #hx[247] = 0x49E3
	#hx[ 56] = 0x7944	: #hx[120] = 0x3985	: #hx[184] = 0x02F9	: #hx[248] = 0x9854
	#hx[ 57] = 0x953D	: #hx[121] = 0x3D6A	: #hx[185] = 0x3F51	: #hx[249] = 0x11F4
	#hx[ 58] = 0xE666	: #hx[122] = 0x6871	: #hx[186] = 0x6C2E	: #hx[250] = 0xA655
	#hx[ 59] = 0xB2DA	: #hx[123] = 0x2F08	: #hx[187] = 0x0777	: #hx[251] = 0x742F
	#hx[ 60] = 0x743C	: #hx[124] = 0x94DE	: #hx[188] = 0xE456	: #hx[252] = 0x8C19
	#hx[ 61] = 0xDB99	: #hx[125] = 0x4CA5	: #hx[189] = 0x7AA0	: #hx[253] = 0xB74A
	#hx[ 62] = 0x48BB	: #hx[126] = 0xD5EA	: #hx[190] = 0x0766	: #hx[254] = 0xD219
	#hx[ 63] = 0xF794	: #hx[127] = 0xAD4C	: #hx[191] = 0x4882	: #hx[255] = 0x63DD
'
'
' dimension charset arrays - all have 256 entries, one for each byte/character value
'
	DIM #charsetSymbolFirst[255]
	DIM #charsetSymbolInner[255]
	DIM #charsetSymbolFinal[255]
	DIM #charsetSymbol[255]
	DIM #charsetUpper[255]
	DIM #charsetLower[255]
	DIM #charsetNumeric[255]
	DIM #charsetUpperLower[255]
	DIM #charsetUpperNumeric[255]
	DIM #charsetLowerNumeric[255]
	DIM #charsetUpperLowerNumeric[255]
	DIM #charsetUpperToLower[255]
	DIM #charsetLowerToUpper[255]
	DIM #charsetVex[255]
	DIM #charsetHexUpper[255]
	DIM #charsetHexLower[255]
	DIM #charsetHexUpperLower[255]
	DIM #charsetHexUpperToLower[255]
	DIM #charsetHexLowerToUpper[255]
	DIM #charsetBackslash[255]
	DIM #charsetBackslashByte[255]
	DIM #charsetBackslashChar[255]
	DIM #charsetNormalChar[255]
	DIM #charsetOctal[255]
	DIM #charsetPrintChar[255]
	DIM #charsetSuffix[255]
	DIM #charsetSpaceTab[255]
	DIM #charsetWhitespace[255]
'
'
' ***********************************
' *****  #charsetSymbolFirst[]  *****  A-Z  a-z  (others 0)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetSymbolFirst[i] = i
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetSymbolFirst[i] = i
			CASE  (i  = '_')									: #charsetSymbolFirst[i] = i
			CASE ELSE													: #charsetSymbolFirst[i] = 0
		END SELECT
	NEXT i
'
'
' ***********************************
' *****  #charsetSymbolInner[]  *****  A-Z  a-z  0-9  "_"  (others 0)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetSymbolInner[i] = i
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetSymbolInner[i] = i
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetSymbolInner[i] = i
			CASE  (i  = '_')									: #charsetSymbolInner[i] = i
			CASE ELSE													: #charsetSymbolInner[i] = 0
		END SELECT
	NEXT i
'
'
' ***********************************
' *****  #charsetSymbolFinal[]  *****  A-Z  a-z  0-9  "_"  (others 0)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetSymbolFinal[i] = i
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetSymbolFinal[i] = i
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetSymbolFinal[i] = i
			CASE  (i  = '_')									: #charsetSymbolFinal[i] = i
			CASE ELSE													: #charsetSymbolFinal[i] = 0
		END SELECT
	NEXT i
'
'
' ******************************
' *****  #charsetSymbol[]  *****  A-Z  a-z  0-9  "_"  (others 0)
' ******************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetSymbol[i] = i
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetSymbol[i] = i
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetSymbol[i] = i
			CASE  (i  = '_')									: #charsetSymbol[i] = i
			CASE ELSE													: #charsetSymbol[i] = 0
		END SELECT
	NEXT i
'
'
' *****************************
' *****  #charsetUpper[]  *****  A-Z  (others 0)
' *****************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetUpper[i] = i
			CASE ELSE													: #charsetUpper[i] = 0
		END SELECT
	NEXT i
'
'
' *****************************
' *****  #charsetLower[]  *****  a-z  (others 0)
' *****************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetLower[i] = i
			CASE ELSE													: #charsetLower[i] = 0
		END SELECT
	NEXT i
'
'
' *******************************
' *****  #charsetNumeric[]  *****  0-9  (others 0)
' *******************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetNumeric[i] = i
			CASE ELSE													: #charsetNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' **********************************
' *****  #charsetUpperLower[]  *****  A-Z  a-z  (others 0)
' **********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetUpperLower[i] = i
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetUpperLower[i] = i
			CASE ELSE													: #charsetUpperLower[i] = 0
		END SELECT
	NEXT i
'
'
' ************************************
' *****  #charsetUpperNumeric[]  *****  A-Z  0-9  (others 0)
' ************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetUpperNumeric[i] = i
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetUpperNumeric[i] = i
			CASE ELSE													: #charsetUpperNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' ************************************
' *****  #charsetLowerNumeric[]  *****  a-z  0-9  (others 0)
' ************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetLowerNumeric[i] = i
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetLowerNumeric[i] = i
			CASE ELSE													: #charsetLowerNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' *****************************************
' *****  #charsetUpperLowerNumeric[]  *****  A-Z  a-z  0-9  (others 0)
' *****************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetUpperLowerNumeric[i] = i
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetUpperLowerNumeric[i] = i
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetUpperLowerNumeric[i] = i
			CASE ELSE													: #charsetUpperLowerNumeric[i] = 0
		END SELECT
	NEXT i
'
'
' ************************************
' *****  #charsetUpperToLower[]  *****  A-Z  ==>>  a-z  (others unchanged)
' ************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z'))	: #charsetUpperToLower[i] = i + 32
			CASE ELSE													: #charsetUpperToLower[i] = i
		END SELECT
	NEXT i
'
'
' ************************************
' *****  #charsetLowerToUpper[]  *****  a-z  ==>>  A-Z  (others unchanged)
' ************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'a') AND (i <= 'z'))	: #charsetLowerToUpper[i] = i - 32
			CASE ELSE													: #charsetLowerToUpper[i] = i
		END SELECT
	NEXT i
'
'
' ***************************
' *****  #charsetVex[]  *****  0-9  A-V  (others 0)
' ***************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetVex[i] = i
			CASE ((i >= 'A') AND (i <= 'V'))	: #charsetVex[i] = i
			CASE ELSE													: #charsetVex[i] = 0
		END SELECT
	NEXT i
'
'
' *****************************
' *****  #charsetOctal[]  *****  0-7
' *****************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '7'))	: #charsetHexUpper[i] = i
			CASE ELSE													: #charsetHexUpper[i] = 0
		END SELECT
	NEXT i
'
'
' ********************************
' *****  #charsetHexUpper[]  *****  0-9  A-F  (others 0)
' ********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetHexUpper[i] = i
			CASE ((i >= 'A') AND (i <= 'F'))	: #charsetHexUpper[i] = i
			CASE ELSE													: #charsetHexUpper[i] = 0
		END SELECT
	NEXT i
'
'
' ********************************
' *****  #charsetHexLower[]  *****  0-9  a-f  (others 0)
' ********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetHexLower[i] = i
			CASE ((i >= 'a') AND (i <= 'f'))	: #charsetHexLower[i] = i
			CASE ELSE													: #charsetHexLower[i] = 0
		END SELECT
	NEXT i
'
'
' *************************************
' *****  #charsetHexUpperLower[]  *****  0-9  A-F  a-f  (others 0)
' *************************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetHexUpperLower[i] = i
			CASE ((i >= 'A') AND (i <= 'F'))	: #charsetHexUpperLower[i] = i
			CASE ((i >= 'a') AND (i <= 'f'))	: #charsetHexUpperLower[i] = i
			CASE ELSE													: #charsetHexUpperLower[i] = 0
		END SELECT
	NEXT i
'
'
' ***************************************  0-9
' *****  #charsetHexUpperToLower[]  *****  A-F  ==>>  a-f  (others 0)
' ***************************************  a-f
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetHexUpperToLower[i] = i
			CASE ((i >= 'A') AND (i <= 'F'))	: #charsetHexUpperToLower[i] = i + 32
			CASE ((i >= 'a') AND (i <= 'f'))	: #charsetHexUpperToLower[i] = i
			CASE ELSE													: #charsetHexUpperToLower[i] = 0
		END SELECT
	NEXT i
'
'
' ***************************************  0-9
' *****  #charsetHexLowerToUpper[]  *****  a-f  ==>>  A-F  (others 0)
' ***************************************  A-F
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetHexLowerToUpper[i] = i
			CASE ((i >= 'A') AND (i <= 'F'))	: #charsetHexLowerToUpper[i] = i
			CASE ((i >= 'a') AND (i <= 'f'))	: #charsetHexLowerToUpper[i] = i - 32
			CASE ELSE													: #charsetHexLowerToUpper[i] = 0
		END SELECT
	NEXT i
'
'
' *********************************  \a  \b  \d  \f  \n  \r  \v  \\  \"  \z
' *****  #charsetBackslash[]  *****  \0 - \V
' *********************************  (others unchanged)
'
' Convert character following a \ into the proper binary value
' For all characters without special binary values, return the character
'
	offset = 10 - 'A'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9'))	: #charsetBackslash[i] = i - '0'
			CASE ((i >= 'A') AND (i <= 'V'))	: #charsetBackslash[i] = i + offset
			CASE ELSE													: #charsetBackslash[i] = i
		END SELECT
	NEXT i
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE '\\'	: #charsetBackslash[i] = 0x5C		' backslash
			CASE '"'	: #charsetBackslash[i] = 0x22		' double-quote
			CASE 'a'	: #charsetBackslash[i] = 0x07		' alarm (bell)
			CASE 'b'	: #charsetBackslash[i] = 0x08		' backspace
			CASE 'd'	: #charsetBackslash[i] = 0x7F		' delete
			CASE 'e'	: #charsetBackslash[i] = 0x1B		' escape
			CASE 'f'	: #charsetBackslash[i] = 0x0C		' form-feed
			CASE 'n'	: #charsetBackslash[i] = 0x0A		' newline
			CASE 'r'	: #charsetBackslash[i] = 0x0D		' return
			CASE 't'	: #charsetBackslash[i] = 0x09		' tab
			CASE 'v'	: #charsetBackslash[i] = 0x0B		' vertical-tab
			CASE 'z'	: #charsetBackslash[i] = 0xFF		' finale  (highest UBYTE)
		END SELECT
	NEXT i
'
'
' *************************************  \a  \b  \d  \e  \f  \n  \r  \t  \v
' *****  #charsetBackslashByte[]  *****  \\  \"
' *************************************
'
' Return printable character intended to follow \ backslash character for
' SIMPLE (only simple) 1 character backslash codes, as understood by dumb
' assemblers, for example.  Otherwise, return zero.
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE 0x5C	: #charsetBackslashByte[i] = '\\'	' backslash
			CASE 0x22	: #charsetBackslashByte[i] = '"'		' double-quote
			CASE 0x07	: #charsetBackslashByte[i] = 'a'		' alarm (bell)
			CASE 0x08	: #charsetBackslashByte[i] = 'b'		' backspace
			CASE 0x7F	: #charsetBackslashByte[i] = 'd'		' delete
			CASE 0x1B	: #charsetBackslashByte[i] = 'e'		' escape
			CASE 0x0C	: #charsetBackslashByte[i] = 'f'		' form-feed
			CASE 0x0A	: #charsetBackslashByte[i] = 'n'		' newline
			CASE 0x0D	: #charsetBackslashByte[i] = 'r'		' return
			CASE 0x09	: #charsetBackslashByte[i] = 't'		' tab
			CASE 0x0B	: #charsetBackslashByte[i] = 'v'		' vertical-tab
			CASE 0x00	: #charsetBackslashByte[i] = '0'		' null
			CASE ELSE	: #charsetBackslashByte[i] = 0			' non-simple backslash
		END SELECT
	NEXT i
'
'
' *************************************  \a  \b  \d  \e  \f  \n  \r  \t  \v
' *****  #charsetBackslashChar[]  *****  \\  \"
' *************************************
'
' Return printable character intended to follow \ backslash character
' Return bytes that are normal, printable, non-backslash characters
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE 0x5C	: #charsetBackslashChar[i] = '\\'	' backslash
			CASE 0x22	: #charsetBackslashChar[i] = '"'		' double-quote
			CASE 0x07	: #charsetBackslashChar[i] = 'a'		' alarm (bell)
			CASE 0x08	: #charsetBackslashChar[i] = 'b'		' backspace
			CASE 0x7F	: #charsetBackslashChar[i] = 'd'		' delete
			CASE 0x1B	: #charsetBackslashChar[i] = 'e'		' escape
			CASE 0x0C	: #charsetBackslashChar[i] = 'f'		' form-feed
			CASE 0x0A	: #charsetBackslashChar[i] = 'n'		' newline
			CASE 0x0D	: #charsetBackslashChar[i] = 'r'		' return
			CASE 0x09	: #charsetBackslashChar[i] = 't'		' tab
			CASE 0x0B	: #charsetBackslashChar[i] = 'v'		' vertical-tab
			CASE ELSE	: #charsetBackslashChar[i] = 0			' not a backslash char
		END SELECT
	NEXT i
'
'
' **********************************  0x00 - 0x1F  ===>>  0
' *****  #charsetNormalChar[]  *****  0x7F - 0xFF  ===>>  0  (others unchanged)
' **********************************   \  and  "   ===>>  0
'
' Normal printable characters = the character, all others = 0
' NOTE:  tab, newline, etc... not considered normal printable characters
' NOTE:  backslash not considered normal printable character (need \\)
' NOTE:  double-quote not considered normal printable character (need \")
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <=  31)	: #charsetNormalChar[i] = 0
			CASE (i >= 127)	: #charsetNormalChar[i] = 0
			CASE (i = '\\')	: #charsetNormalChar[i] = 0
			CASE (i = '"')	: #charsetNormalChar[i] = 0
			CASE ELSE				: #charsetNormalChar[i] = i
		END SELECT
	NEXT i
'
'
' *********************************  0x00 - 0x1F  ===>>  0
' *****  #charsetPrintChar[]  *****  0x7F - 0xFF  ===>>  0
' *********************************  (others unchanged)
'
' Printable characters = the character, all others = 0
' NOTE:  tab, newline, etc... not considered normal printable characters
' NOTE:  backslash is a printable character
' NOTE:  double-quote is a printable character
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <=  31)	: #charsetPrintChar[i] = 0
			CASE (i >= 127)	: #charsetPrintChar[i] = 0
			CASE ELSE				: #charsetPrintChar[i] = i
		END SELECT
	NEXT i
'
'
' ******************************
' *****  #charsetSuffix[]  *****  valid type suffixes
' ******************************
'
	#charsetSuffix['%']	= '%'
	#charsetSuffix['&']	= '&'
	#charsetSuffix['!']	= '!'
	#charsetSuffix['#']	= '#'
	#charsetSuffix['$']	= '$'
'
'
' ********************************
' *****  #charsetSpaceTab[]  *****  only <space> and <tab> are true
' ********************************
'
	#charsetSpaceTab[0x09]	= 0x09		' <tab>		= '\t'
	#charsetSpaceTab[0x20]	= 0x20		' <space>	= ' '
'
'
' **********************************
' *****  #charsetWhitespace[]  *****  all whitespace characters (space, tab, garbage)
' **********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <= 0x20)	: #charsetWhitespace[i] = i		' from 0x00 to 0x20 (tab, space, trash)
			CASE (i >= 0x80)	: #charsetWhitespace[i] = i		' from 0x80 to 0xFF (unprintable trash)
		END SELECT
	NEXT i
END FUNCTION
'
'
' #######################################
' #####  InitializeQBasicTokens ()  #####
' #######################################
'
FUNCTION  InitializeQBasicTokens ()
'
' define some shorthand variables
'
' common types
'
	t0 = 0
	tw = $$TYPE_SSHORT		' word
	ti = $$TYPE_XLONG			' integer
	tg = $$TYPE_GIANT			' giant-integer
	tf = $$TYPE_DOUBLE		' floating-point
	ts = $$TYPE_STRING		' nominal string
'
' common kinds
'
	k0 = 0
	ks = $$KIND_QBASIC | $$KIND_STATEMENT
	ki = $$KIND_QBASIC | $$KIND_INTRINSIC
	ko = $$KIND_QBASIC | $$KIND_OPERATOR
	kk = $$KIND_QBASIC | $$KIND_KEYWORD
	kt = $$KIND_QBASIC | $$KIND_TYPE
	kl = $$KIND_QBASIC | $$KIND_LITERAL
	kf = $$KIND_QBASIC | $$KIND_FUNCTION
	ky = $$KIND_QBASIC | $$KIND_SYMBOL
	kv = $$KIND_QBASIC | $$KIND_VARIABLE
	ka = $$KIND_QBASIC | $$KIND_ARRAY
	kc = $$KIND_QBASIC | $$KIND_COMPOSITE
	ke = $$KIND_QBASIC | $$KIND_ELEMENT
	kh = $$KIND_QBASIC | $$KIND_CHARACTER
	kq = $$KIND_QBASIC
'
' common scopes
'
	s0 = 0
	sa = $$SCOPE_AUTO
	sl = $$SCOPE_STATIC
	ss = $$SCOPE_SHARED
	se = $$SCOPE_EXTERNAL
'
	q0 = 0
	x0 = 0
'
'
' token_number     = AddKeyword (translate, function, scope, kind, rtype, arg0, arg1, arg2, string$)
'
	#qatoken         = #ntoken + 1
	#Q_ABS           = AddKeyword (#X_ABS        , f0, s0, ki, tf, tf, t0, t0, "ABS")
	#Q_ABSOLUTE      = AddKeyword (            x0, f0, s0, ki, tf, tf, t0, t0, "ABSOLUTE")
	#Q_ACCESS        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ACCESS")
	#Q_ALIAS         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ALIAS")
	#Q_AND           = AddKeyword (#X_AND        , f0, s0, ko, t0, t0, t0, t0, "AND")
	#Q_ANY           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ANY")
	#Q_APPEND        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "APPEND")
	#Q_AS            = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "AS")
	#Q_ASC           = AddKeyword (#X_ASC        , f0, s0, ki, t0, t0, t0, t0, "ASC")
	#Q_ATN           = AddKeyword (#X_ATAN       , f0, s0, ki, t0, t0, t0, t0, "ATN")
	#Q_BASE          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "BASE")
	#Q_BEEP          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "BEEP")
	#Q_BINARY        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "BINARY")
	#Q_BLOAD         = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "BLOAD")
	#Q_BSAVE         = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "BSAVE")
	#Q_BYVAL         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "BYVAL")
	#Q_CALL          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CALL")
	#Q_CALLS         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CALLS")
	#Q_CASE          = AddKeyword (#X_CASE       , f0, s0, ks, t0, t0, t0, t0, "CASE")
	#Q_CCUR          = AddKeyword (#X_GIANT      , f0, s0, ki, t0, t0, t0, t0, "CCUR")
	#Q_CDBL          = AddKeyword (#X_DOUBLE     , f0, s0, ki, t0, t0, t0, t0, "CDBL")
	#Q_CDECL         = AddKeyword (#X_CFUNCTION  , f0, s0, k0, t0, t0, t0, t0, "CDECL")
	#Q_CHAIN         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CHAIN")
	#Q_CHDIR         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CHDIR")
	#Q_CHDRIVE       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CHDRIVE")
	#Q_CHR_D         = AddKeyword (#X_CHR_D      , f0, s0, ki, t0, t0, t0, t0, "CHR$")
	#Q_CINT          = AddKeyword (#X_SSHORT     , f0, s0, ki, t0, t0, t0, t0, "CINT")
	#Q_CIRCLE        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CIRCLE")
	#Q_CLEAR         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CLEAR")
	#Q_CLNG          = AddKeyword (#X_SLONG      , f0, s0, ki, t0, t0, t0, t0, "CLNG")
	#Q_CLOSE         = AddKeyword (#X_CLOSE      , f0, s0, k0, t0, t0, t0, t0, "CLOSE")
	#Q_CLS           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CLS")
	#Q_COLOR         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "COLOR")
	#Q_COM           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "COM")
	#Q_COMMAND_D     = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "COMMAND$")
	#Q_COMMON        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "COMMON")
	#Q_CONST         = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "CONST")
	#Q_COS           = AddKeyword (#X_COS        , f0, s0, ki, t0, t0, t0, t0, "COS")
	#Q_CSNG          = AddKeyword (#X_SINGLE     , f0, s0, ki, t0, t0, t0, t0, "CSNG")
	#Q_CSRLIN        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CSRLIN")
	#Q_CURDIR_D      = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "CURDIR$")
	#Q_CURRENCY      = AddKeyword (#X_GIANT      , f0, s0, k0, t0, t0, t0, t0, "CURRENCY")
	#Q_CVC           = AddKeyword (#X_GIANT      , f0, s0, ki, t0, t0, t0, t0, "CVC")
	#Q_CVD           = AddKeyword (#X_DOUBLE     , f0, s0, ki, t0, t0, t0, t0, "CVD")
	#Q_CVI           = AddKeyword (#X_SSHORT     , f0, s0, ki, t0, t0, t0, t0, "CVI")
	#Q_CVL           = AddKeyword (#X_SLONG      , f0, s0, ki, t0, t0, t0, t0, "CVL")
	#Q_CVS           = AddKeyword (#X_SINGLE     , f0, s0, ki, t0, t0, t0, t0, "CVS")
	#Q_CVSMBF        = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "CVSMBF")
	#Q_DATA          = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "DATA")
	#Q_DATE_D        = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "DATE$")
	#Q_DECLARE       = AddKeyword (#X_DECLARE    , f0, s0, ks, t0, t0, t0, t0, "DECLARE")
	#Q_DEF           = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "DEF")
	#Q_DEFCUR        = AddKeyword (#X_GIANT      , f0, s0, ks, t0, t0, t0, t0, "DEFCUR")
	#Q_DEFDBL        = AddKeyword (#X_DOUBLE     , f0, s0, ks, t0, t0, t0, t0, "DEFDBL")
	#Q_DEFINT        = AddKeyword (#X_SSHORT     , f0, s0, ks, t0, t0, t0, t0, "DEFINT")
	#Q_DEFLNG        = AddKeyword (#X_SLONG      , f0, s0, ks, t0, t0, t0, t0, "DEFLNG")
	#Q_DEFSNG        = AddKeyword (#X_SINGLE     , f0, s0, ks, t0, t0, t0, t0, "DEFSNG")
	#Q_DEFSTR        = AddKeyword (#X_STRING     , f0, s0, ks, t0, t0, t0, t0, "DEFSTR")
	#Q_DELETE        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "DELETE")
	#Q_DIM           = AddKeyword (#X_DIM        , f0, s0, ks, t0, t0, t0, t0, "DIM")
	#Q_DIR_D         = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "DIR$")
	#Q_DO            = AddKeyword (#X_DO         , f0, s0, ks, t0, t0, t0, t0, "DO")
	#Q_DOUBLE        = AddKeyword (#X_DOUBLE     , f0, s0, k0, t0, t0, t0, t0, "DOUBLE")
	#Q_DRAW          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "DRAW")
	#Q_DYNAMIC       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "DYNAMIC")
	#Q_ELSE          = AddKeyword (#X_ELSE       , f0, s0, ks, t0, t0, t0, t0, "ELSE")
	#Q_ELSEIF        = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "ELSEIF")
	#Q_END           = AddKeyword (#X_END        , f0, s0, ks, t0, t0, t0, t0, "END")
	#Q_ENDIF         = AddKeyword (#X_ENDIF      , f0, s0, ks, t0, t0, t0, t0, "ENDIF")
	#Q_ENVIRON       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ENVIRON")
	#Q_ENVIRON_D     = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ENVIRON$")
	#Q_EOF           = AddKeyword (#X_EOF        , f0, s0, ki, t0, t0, t0, t0, "EOF")
	#Q_EQV           = AddKeyword (            x0, f0, s0, ko, t0, t0, t0, t0, "EQV")
	#Q_ERASE         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ERASE")
	#Q_ERDEV         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ERDEV")
	#Q_ERDEV_D       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ERDEV$")
	#Q_ERL           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ERL")
	#Q_ERR           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ERR")
	#Q_ERROR         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "ERROR")
	#Q_EVENT         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "EVENT")
	#Q_EXIT          = AddKeyword (#X_EXIT       , f0, s0, ks, t0, t0, t0, t0, "EXIT")
	#Q_EXP           = AddKeyword (#X_EXP        , f0, s0, ki, t0, t0, t0, t0, "EXP")
	#Q_FIELD         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "FIELD")
	#Q_FILEATTR      = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "FILEATTR")
	#Q_FILES         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "FILES")
	#Q_FIX           = AddKeyword (#X_FIX        , f0, s0, ki, t0, t0, t0, t0, "FIX")
	#Q_FN            = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "FN")
	#Q_FOR           = AddKeyword (#X_FOR        , f0, s0, ks, t0, t0, t0, t0, "FOR")
	#Q_FRE           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "FRE")
	#Q_FREEFILE      = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "FREEFILE")
	#Q_FUNCTION      = AddKeyword (#X_FUNCTION   , f0, s0, ks, t0, t0, t0, t0, "FUNCTION")
	#Q_GET           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "GET")
	#Q_GOSUB         = AddKeyword (#X_GOSUB      , f0, s0, ks, t0, t0, t0, t0, "GOSUB")
	#Q_GOTO          = AddKeyword (#X_GOTO       , f0, s0, ks, t0, t0, t0, t0, "GOTO")
	#Q_HEX_D         = AddKeyword (#X_HEX_D      , f0, s0, ki, t0, t0, t0, t0, "HEX$")
	#Q_IF            = AddKeyword (#X_IF         , f0, s0, ks, t0, t0, t0, t0, "IF")
	#Q_IMP           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "IMP")
	#Q_INCLUDE       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "INCLUDE")
	#Q_INKEY_D       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "INKEY$")
	#Q_INP           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "INP")
	#Q_INPUT         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "INPUT")
	#Q_INPUT_D       = AddKeyword (#X_INLINE_D   , f0, s0, k0, t0, t0, t0, t0, "INPUT$")
	#Q_INSTR         = AddKeyword (#X_INSTR      , f0, s0, ki, t0, t0, t0, t0, "INSTR")
	#Q_INT           = AddKeyword (#X_INT        , f0, s0, ki, t0, t0, t0, t0, "INT")
	#Q_INTEGER       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "INTEGER")
	#Q_INTERRUPT     = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "INTERRUPT")
	#Q_IOCTL         = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "IOCTL")
	#Q_IOCTL_D       = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "IOCTL$")
	#Q_IS            = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "IS")
	#Q_KEY           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "KEY")
	#Q_KILL          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "KILL")
	#Q_LBOUND        = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "LBOUND")
	#Q_LCASE_D       = AddKeyword (#X_LCASE_D    , f0, s0, ki, t0, t0, t0, t0, "LCASE$")
	#Q_LEFT_D        = AddKeyword (#X_LEFT_D     , f0, s0, ki, t0, t0, t0, t0, "LEFT$")
	#Q_LEN           = AddKeyword (#X_LEN        , f0, s0, ki, t0, t0, t0, t0, "LEN")
	#Q_LET           = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "LET")
	#Q_LINE          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "LINE")
	#Q_LIST          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "LIST")
	#Q_LOC           = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "LOC")
	#Q_LOCAL         = AddKeyword (#X_AUTO       , f0, s0, k0, t0, t0, t0, t0, "LOCAL")
	#Q_LOCATE        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "LOCATE")
	#Q_LOCK          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "LOCK")
	#Q_LOF           = AddKeyword (#X_LOF        , f0, s0, ki, t0, t0, t0, t0, "LOF")
	#Q_LOG           = AddKeyword (#X_LOG        , f0, s0, ki, t0, t0, t0, t0, "LOG")
	#Q_LONG          = AddKeyword (#X_SLONG      , f0, s0, k0, t0, t0, t0, t0, "LONG")
	#Q_LOOP          = AddKeyword (#X_LOOP       , f0, s0, ks, t0, t0, t0, t0, "LOOP")
	#Q_LPOS          = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "LPOS")
	#Q_LPRINT        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "LPRINT")
	#Q_LSET          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "LSET")
	#Q_LTRIM_D       = AddKeyword (#X_LTRIM_D    , f0, s0, ki, t0, t0, t0, t0, "LTRIM$")
	#Q_MID_D         = AddKeyword (#X_MID_D      , f0, s0, ki, t0, t0, t0, t0, "MID$")
	#Q_MKC_D         = AddKeyword (#X_STRING_D   , f0, s0, ki, t0, t0, t0, t0, "MKC$")
	#Q_MKDIR         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "MKDIR")
	#Q_MKDMBF_D      = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "MKDMBF$")
	#Q_MKD_D         = AddKeyword (#X_STRING_D   , f0, s0, ki, t0, t0, t0, t0, "MKD$")
	#Q_MKI_D         = AddKeyword (#X_STRING_D   , f0, s0, ki, t0, t0, t0, t0, "MKI$")
	#Q_MKL_D         = AddKeyword (#X_STRING_D   , f0, s0, ki, t0, t0, t0, t0, "MKL$")
	#Q_MKS_D         = AddKeyword (#X_STRING_D   , f0, s0, ki, t0, t0, t0, t0, "MKS$")
	#Q_MKSMBF_D      = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "MKSMBF$")
	#Q_MOD           = AddKeyword (#X_MOD        , f0, s0, ko, t0, t0, t0, t0, "MOD")
	#Q_NAME          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "NAME")
	#Q_NEXT          = AddKeyword (#X_NEXT       , f0, s0, ks, t0, t0, t0, t0, "NEXT")
	#Q_NOT           = AddKeyword (#X_NOT        , f0, s0, ko, t0, t0, t0, t0, "NOT")
	#Q_OCT_D         = AddKeyword (#X_OCT_D      , f0, s0, ki, t0, t0, t0, t0, "OCT$")
	#Q_OFF           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "OFF")
	#Q_ON            = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "ON")
	#Q_OPEN          = AddKeyword (#X_OPEN       , f0, s0, k0, t0, t0, t0, t0, "OPEN")
	#Q_OPTION        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "OPTION")
	#Q_OR            = AddKeyword (#X_OR         , f0, s0, ko, t0, t0, t0, t0, "OR")
	#Q_OUT           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "OUT")
	#Q_OUTPUT        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "OUTPUT")
	#Q_PAINT         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PAINT")
	#Q_PALETTE       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PALETTE")
	#Q_PCOPY         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PCOPY")
	#Q_PEEK          = AddKeyword (#X_UBYTE_AT   , f0, s0, ki, t0, t0, t0, t0, "PEEK")
	#Q_PEN           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PEN")
	#Q_PLAY          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PLAY")
	#Q_PMAP          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PMAP")
	#Q_POINT         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "POINT")
	#Q_POKE          = AddKeyword (#X_UBYTE_AT   , f0, s0, ks, t0, t0, t0, t0, "POKE")
	#Q_POS           = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "POS")
	#Q_PRESET        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PRESET")
	#Q_PRINT         = AddKeyword (#X_PRINT      , f0, s0, ks, t0, t0, t0, t0, "PRINT")
	#Q_PSET          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PSET")
	#Q_PUT           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "PUT")
	#Q_RANDOM        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RANDOM")
	#Q_RANDOMIZE     = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RANDOMIZE")
	#Q_READ          = AddKeyword (#X_READ       , f0, s0, ks, t0, t0, t0, t0, "READ")
	#Q_REDIM         = AddKeyword (#X_REDIM      , f0, s0, ks, t0, t0, t0, t0, "REDIM")
	#Q_REM           = AddKeyword (#X_REMARK     , f0, s0, ks, t0, t0, t0, t0, "REM")
	#Q_RESET         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RESET")
	#Q_RESTORE       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RESTORE")
	#Q_RESUME        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RESUME")
	#Q_RETURN        = AddKeyword (            x0, f0, s0, ks, t0, t0, t0, t0, "RETURN")
	#Q_RIGHT_D       = AddKeyword (#X_RIGHT_D    , f0, s0, ki, t0, t0, t0, t0, "RIGHT$")
	#Q_RMDIR         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RMDIR")
	#Q_RND           = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "RND")
	#Q_RSET          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RSET")
	#Q_RTRIM_D       = AddKeyword (#X_RTRIM_D    , f0, s0, ki, t0, t0, t0, t0, "RTRIM$")
	#Q_RUN           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "RUN")
	#Q_SADD          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SADD")
	#Q_SCREEN        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SCREEN")
	#Q_SEEK          = AddKeyword (#X_SEEK       , f0, s0, ki, t0, t0, t0, t0, "SEEK")
	#Q_SEG           = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SEG")
	#Q_SELECT        = AddKeyword (#X_SELECT     , f0, s0, ks, t0, t0, t0, t0, "SELECT")
	#Q_SETMEM        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SETMEM")
	#Q_SGN           = AddKeyword (#X_SGN        , f0, s0, ki, t0, t0, t0, t0, "SGN")
	#Q_SHARED        = AddKeyword (#X_SHARED     , f0, s0, ks, t0, t0, t0, t0, "SHARED")
	#Q_SHELL         = AddKeyword (#X_SHELL      , f0, s0, k0, t0, t0, t0, t0, "SHELL")
	#Q_SIGNAL        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SIGNAL")
	#Q_SIN           = AddKeyword (#X_SIN        , f0, s0, ki, t0, t0, t0, t0, "SIN")
	#Q_SINGLE        = AddKeyword (#X_SINGLE     , f0, s0, ks, t0, t0, t0, t0, "SINGLE")
	#Q_SLEEP         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SLEEP")
	#Q_SOUND         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SOUND")
	#Q_SPACE_D       = AddKeyword (#X_SPACE_D    , f0, s0, ki, t0, t0, t0, t0, "SPACE$")
	#Q_SPC           = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "SPC")
	#Q_SQR           = AddKeyword (#X_SQRT       , f0, s0, ki, t0, t0, t0, t0, "SQR")
	#Q_SSEG          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SSEG")
	#Q_SSEGADD       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SSEGADD")
	#Q_STACK         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "STACK")
	#Q_STATIC        = AddKeyword (#X_STATIC     , f0, s0, ks, t0, t0, t0, t0, "STATIC")
	#Q_STEP          = AddKeyword (#X_STEP       , f0, s0, ks, t0, t0, t0, t0, "STEP")
	#Q_STICK         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "STICK")
	#Q_STOP          = AddKeyword (#X_STOP       , f0, s0, ks, t0, t0, t0, t0, "STOP")
	#Q_STR_D         = AddKeyword (#X_STR_D      , f0, s0, ki, t0, t0, t0, t0, "STR$")
	#Q_STRIG         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "STRIG")
	#Q_STRING        = AddKeyword (#X_STRING     , f0, s0, k0, t0, t0, t0, t0, "STRING")
	#Q_STRING_D      = AddKeyword (#X_CHR_D      , f0, s0, ki, t0, t0, t0, t0, "STRING$")
	#Q_SUB           = AddKeyword (#X_FUNCTION   , f0, s0, ks, t0, t0, t0, t0, "SUB")
	#Q_SWAP          = AddKeyword (#X_SWAP       , f0, s0, ks, t0, t0, t0, t0, "SWAP")
	#Q_SYSTEM        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "SYSTEM")
	#Q_TAB           = AddKeyword (#X_TAB        , f0, s0, ki, t0, t0, t0, t0, "TAB")
	#Q_TAN           = AddKeyword (#X_TAN        , f0, s0, ki, t0, t0, t0, t0, "TAN")
	#Q_THEN          = AddKeyword (#X_THEN       , f0, s0, ks, t0, t0, t0, t0, "THEN")
	#Q_TIME_D        = AddKeyword (            x0, f0, s0, ki, t0, t0, t0, t0, "TIME$")
	#Q_TIMER         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "TIMER")
	#Q_TO            = AddKeyword (#X_TO         , f0, s0, ks, t0, t0, t0, t0, "TO")
	#Q_TROFF         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "TROFF")
	#Q_TRON          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "TRON")
	#Q_TYPE          = AddKeyword (#X_TYPE       , f0, s0, ks, t0, t0, t0, t0, "TYPE")
	#Q_UBOUND        = AddKeyword (#X_UBOUND     , f0, s0, ki, t0, t0, t0, t0, "UBOUND")
	#Q_UCASE_D       = AddKeyword (#X_UCASE_D    , f0, s0, ki, t0, t0, t0, t0, "UCASE$")
	#Q_UEVENT        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "UEVENT")
	#Q_UNLOCK        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "UNLOCK")
	#Q_UNTIL         = AddKeyword (#X_UNTIL      , f0, s0, ks, t0, t0, t0, t0, "UNTIL")
	#Q_UPDATE        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "UPDATE")
	#Q_USING         = AddKeyword (#X_FORMAT_D   , f0, s0, ks, t0, t0, t0, t0, "USING")
	#Q_VAL           = AddKeyword (#X_DOUBLE     , f0, s0, ki, t0, t0, t0, t0, "VAL")
	#Q_VARPTR        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "VARPTR")
	#Q_VARPTR_D      = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "VARPTR$")
	#Q_VARSEG        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "VARSEG")
	#Q_VIEW          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "VIEW")
	#Q_WAIT          = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "WAIT")
	#Q_WEND          = AddKeyword (#X_LOOP       , f0, s0, ks, t0, t0, t0, t0, "WEND")
	#Q_WHILE         = AddKeyword (#X_DO         , f0, s0, ks, t0, t0, t0, t0, "WHILE")
	#Q_WIDTH         = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "WIDTH")
	#Q_WINDOW        = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "WINDOW")
	#Q_WRITE         = AddKeyword (#X_WRITE      , f0, s0, ks, t0, t0, t0, t0, "WRITE")
	#Q_XOR           = AddKeyword (#X_XOR        , f0, s0, ko, t0, t0, t0, t0, "XOR")
'
'	#Q_POST_SSHORT   = AddKeyword (#X_POST_SSHORT, f0, s0, kc,  4, t0, t0, t0, "%")		' part of string ???
'	#Q_POST_SLONG    = AddKeyword (#X_POST_SLONG , f0, s0, kc,  6, t0, t0, t0, "&")		' part of string ???
'	#Q_POST_SINGLE   = AddKeyword (#X_POST_SINGLE, f0, s0, kc, 13, t0, t0, t0, "!")		' part of string ???
'	#Q_POST_DOUBLE   = AddKeyword (#X_POST_DOUBLE, f0, s0, kc, 14, t0, t0, t0, "#")		' part of string ???
'	#Q_POST_STRING   = AddKeyword (#X_POST_STRING, f0, s0, kc, 15, t0, t0, t0, "$")		' part of string ???
'
	#Q_PLUS          = AddKeyword (#X_PLUS       , f0, s0, ko, t0, t0, t0, t0, "+")		' unary
	#Q_MINUS         = AddKeyword (#X_MINUS      , f0, s0, ko, t0, t0, t0, t0, "-")		' unary
'	#Q_ADDRESS       = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "&")		' unary
'
	#Q_ADD           = AddKeyword (#X_ADD        , f0, s0, ko, t0, t0, t0, t0, "+")
	#Q_SUBTRACT      = AddKeyword (#X_SUBTRACT   , f0, s0, ko, t0, t0, t0, t0, "-")
	#Q_MULTIPLY      = AddKeyword (#X_MULTIPLY   , f0, s0, ko, t0, t0, t0, t0, "*")
	#Q_DIVIDE        = AddKeyword (#X_DIVIDE     , f0, s0, ko, t0, t0, t0, t0, "/")
	#Q_POWER         = AddKeyword (#X_POWER      , f0, s0, ko, t0, t0, t0, t0, "^")
	#Q_IDIVIDE       = AddKeyword (#X_IDIVIDE    , f0, s0, ko, t0, t0, t0, t0, "\\")
	#Q_REMAINDER     = AddKeyword (#X_MOD        , f0, s0, ko, t0, t0, t0, t0, "%")
'
	#Q_NOTBIT        = AddKeyword (#X_NOT        , f0, s0, ko, t0, t0, t0, t0, "~")		' unary
	#Q_ANDBIT        = AddKeyword (#X_AND        , f0, s0, ko, t0, t0, t0, t0, "&")
	#Q_ORBIT         = AddKeyword (#X_OR         , f0, s0, ko, t0, t0, t0, t0, "|")
	#Q_EQ            = AddKeyword (#X_EQ         , f0, s0, ko, t0, t0, t0, t0, "=")
	#Q_NE            = AddKeyword (#X_NE         , f0, s0, ko, t0, t0, t0, t0, "<>")
	#Q_LT            = AddKeyword (#X_LT         , f0, s0, ko, t0, t0, t0, t0, "<")
	#Q_LE            = AddKeyword (#X_LE         , f0, s0, ko, t0, t0, t0, t0, "<=")
	#Q_GE            = AddKeyword (#X_GE         , f0, s0, ko, t0, t0, t0, t0, ">=")
	#Q_GT            = AddKeyword (#X_GT         , f0, s0, ko, t0, t0, t0, t0, ">")
'
	#Q_LPAREN        = AddKeyword (#X_LPAREN     , f0, s0, kc, t0, t0, t0, t0, "(")
	#Q_RPAREN        = AddKeyword (#X_RPAREN     , f0, s0, kc, t0, t0, t0, t0, ")")
	#Q_LBRAK         = AddKeyword (#X_LBRAK      , f0, s0, kc, t0, t0, t0, t0, "[")
	#Q_RBRAK         = AddKeyword (#X_RBRAK      , f0, s0, kc, t0, t0, t0, t0, "]")
	#Q_COMMA         = AddKeyword (#X_COMMA      , f0, s0, kc, t0, t0, t0, t0, ",")
	#Q_COLON         = AddKeyword (#X_COLON      , f0, s0, kc, t0, t0, t0, t0, ":")
	#Q_SEMI          = AddKeyword (#X_SEMI       , f0, s0, kc, t0, t0, t0, t0, ";")

'
'	#Q_KEYWORD       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "")
'	#Q_KEYWORD       = AddKeyword (            x0, f0, s0, k0, t0, t0, t0, t0, "")
	#qztoken         = #ntoken
END FUNCTION
'
'
' #######################################
' #####  InitializeXBasicTokens ()  #####
' #######################################
'
FUNCTION  InitializeXBasicTokens ()
'
' define shorthand variables to make function calls readable
'
' common data-types
'
	t0 = 0
	ti = $$TYPE_XLONG			' integer
	tg = $$TYPE_GIANT			' giant-integer
	tf = $$TYPE_DOUBLE		' floating-point
	ts = $$TYPE_STRING		' nominal string
'
' common kinds
'
	k0 = 0
	ks = $$KIND_XBASIC | $$KIND_STATEMENT
	ki = $$KIND_XBASIC | $$KIND_INTRINSIC
	ko = $$KIND_XBASIC | $$KIND_OPERATOR
	kk = $$KIND_XBASIC | $$KIND_KEYWORD
	kt = $$KIND_XBASIC | $$KIND_TYPE
	kl = $$KIND_XBASIC | $$KIND_LITERAL
	kf = $$KIND_XBASIC | $$KIND_FUNCTION
	ky = $$KIND_XBASIC | $$KIND_SYMBOL
	kv = $$KIND_XBASIC | $$KIND_VARIABLE
	ka = $$KIND_XBASIC | $$KIND_ARRAY
	kc = $$KIND_XBASIC | $$KIND_COMPOSITE
	ke = $$KIND_XBASIC | $$KIND_ELEMENT
	kh = $$KIND_XBASIC | $$KIND_CHARACTER
	km = $$KIND_XBASIC | $$KIND_FUNCTION		' math library functions look like intrinsics
	kx = $$KIND_XBASIC
'
' common kinds
'
	s0 = 0
	sa = $$SCOPE_AUTO
	sx = $$SCOPE_AUTOX
	sl = $$SCOPE_STATIC
	ss = $$SCOPE_SHARED
	se = $$SCOPE_EXTERNAL
'
	q0 = 0
	x0 = 0
'
'
' token_number     = AddKeyword (translate, function, scope, kind, rtype, arg0, arg1, arg2, string$)
'
	#xatoken         = #ntoken + 1
	#X_ABS           = AddKeyword (#Q_ABS        , f0, s0, ki, tf, tf, t0, t0, "ABS")
	#X_ALL           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "ALL")
	#X_AND           = AddKeyword (#Q_AND        , f0, s0, ko, t0, t0, t0, t0, "AND")
	#X_ANY           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "ANY")
	#X_ASC           = AddKeyword (#Q_ASC        , f0, s0, ki, t0, t0, t0, t0, "ASC")
	#X_ATAN          = AddKeyword (#Q_ATN        , f0, s0, km, t0, t0, t0, t0, "ATAN")
	#X_ATTACH        = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "ATTACH")
	#X_AUTO          = AddKeyword (            q0, f0, sa, ks, t0, t0, t0, t0, "AUTO")
	#X_AUTOX         = AddKeyword (            q0, f0, sx, ks, t0, t0, t0, t0, "AUTOX")
	#X_BIN_D         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "BIN$")
	#X_BINB_D        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "BINB$")
	#X_BITFIELD      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "BITFIELD")
	#X_CASE          = AddKeyword (#Q_CASE       , f0, s0, ks, t0, t0, t0, t0, "CASE")
	#X_CFUNCTION     = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "CFUNCTION")
	#X_CHR_D         = AddKeyword (#Q_CHR_D      , f0, s0, ki, t0, t0, t0, t0, "CHR$")
	#X_CJUST_D       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "CJUST$")
	#X_CLOSE         = AddKeyword (#Q_CLOSE      , f0, s0, ki, t0, t0, t0, t0, "CLOSE")
	#X_CLR           = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "CLR")
	#X_CSIZE         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "CSIZE")
	#X_CSIZE_D       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "CSIZE$")
	#X_CSTRING_D     = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "CSTRING$")
	#X_DEC           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "DEC")
	#X_DECLARE       = AddKeyword (#Q_DECLARE    , f0, s0, ks, t0, t0, t0, t0, "DECLARE")
	#X_DHIGH         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "DHIGH")
	#X_DIM           = AddKeyword (#Q_DIM        , f0, s0, ki, t0, t0, t0, t0, "DIM")
	#X_DLOW          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "DLOW")
	#X_DMAKE         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "DMAKE")
	#X_DO            = AddKeyword (#Q_DO         , f0, s0, ks, t0, t0, t0, t0, "DO")
	#X_DOUBLE        = AddKeyword (#Q_DOUBLE     , f0, s0, ks, t0, t0, t0, t0, "DOUBLE")
	#X_DOUBLE        = AddKeyword (#Q_DOUBLE     , f0, s0, ki, t0, t0, t0, t0, "DOUBLE")
	#X_DOUBLEAT      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "DOUBLEAT")
	#X_ELSE          = AddKeyword (#Q_ELSE       , f0, s0, ks, t0, t0, t0, t0, "ELSE")
	#X_END           = AddKeyword (#Q_END        , f0, s0, ks, t0, t0, t0, t0, "END")
	#X_ENDIF         = AddKeyword (#Q_ENDIF      , f0, s0, ks, t0, t0, t0, t0, "ENDIF")
	#X_EOF           = AddKeyword (#Q_EOF        , f0, s0, ki, t0, t0, t0, t0, "EOF")
	#X_ERROR         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "ERROR")
	#X_EXIT          = AddKeyword (#Q_EXIT       , f0, s0, ks, t0, t0, t0, t0, "EXIT")
	#X_EXP           = AddKeyword (#Q_EXP        , f0, s0, km, t0, t0, t0, t0, "EXP")
	#X_EXTERNAL      = AddKeyword (            q0, f0, se, ks, t0, t0, t0, t0, "EXTERNAL")
	#X_EXTS          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "EXTS")
	#X_EXTU          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "EXTU")
	#X_FALSE         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "FALSE")
	#X_FIX           = AddKeyword (#Q_FIX        , f0, s0, ki, t0, t0, t0, t0, "FIX")
	#X_FOR           = AddKeyword (#Q_FOR        , f0, s0, ks, t0, t0, t0, t0, "FOR")
	#X_FORMAT_D      = AddKeyword (#Q_USING      , f0, s0, ki, t0, t0, t0, t0, "FORMAT$")
	#X_FUNCADDR      = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "FUNCADDR")
	#X_FUNCADDR      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "FUNCADDR")
	#X_FUNCADDRAT    = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "FUNCADDRAT")
	#X_FUNCADDRESS   = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "FUNCADDRESS")
	#X_FUNCTION      = AddKeyword (#Q_FUNCTION   , f0, s0, ks, t0, t0, t0, t0, "FUNCTION")
	#X_GHIGH         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "GHIGH")
	#X_GIANT         = AddKeyword (#Q_GIANT      , f0, s0, ks, t0, t0, t0, t0, "GIANT")
	#X_GIANT         = AddKeyword (#Q_GIANT      , f0, s0, ki, t0, t0, t0, t0, "GIANT")
	#X_GIANTAT       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "GIANTAT")
	#X_GLOW          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "GLOW")
	#X_GMAKE         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "GMAKE")
	#X_GOADDR        = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "GOADDR")
	#X_GOADDR        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "GOADDR")
	#X_GOADDRAT      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "GOADDRAT")
	#X_GOADDRESS     = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "GOADDRESS")
	#X_GOSUB         = AddKeyword (#Q_GOSUB      , f0, s0, ks, t0, t0, t0, t0, "GOSUB")
	#X_GOTO          = AddKeyword (#Q_GOTO       , f0, s0, ks, t0, t0, t0, t0, "GOTO")
	#X_HEX_D         = AddKeyword (#Q_HEX_D      , f0, s0, ki, t0, t0, t0, t0, "HEX$")
	#X_HEXX_D        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "HEXX$")
	#X_HIGH0         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "HIGH0")
	#X_HIGH1         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "HIGH1")
	#X_IF            = AddKeyword (#Q_IF         , f0, s0, ks, t0, t0, t0, t0, "IF")
	#X_IFF           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "IFF")
	#X_IFT           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "IFT")
	#X_IFZ           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "IFZ")
	#X_INC           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "INC")
	#X_INCHR         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "INCHR")
	#X_INCHRI        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "INCHRI")
	#X_INT           = AddKeyword (#Q_INT        , f0, s0, ki, t0, t0, t0, t0, "INT")
	#X_INTERNAL      = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "INTERNAL")
	#X_LCASE_D       = AddKeyword (#Q_LCASE_D    , f0, s0, ki, t0, t0, t0, t0, "LCASE$")
	#X_LCLIP_D       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "LCLIP$")
	#X_LEFT_D        = AddKeyword (#Q_LEFT_D     , f0, s0, ki, t0, t0, t0, t0, "LEFT$")
	#X_LEN           = AddKeyword (#Q_LEN        , f0, s0, ki, t0, t0, t0, t0, "LEN")
	#X_LJUST_D       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "LJUST$")
	#X_LOF           = AddKeyword (#Q_LOF        , f0, s0, ki, t0, t0, t0, t0, "LOF")
	#X_LOG           = AddKeyword (#Q_LOG        , f0, s0, km, t0, t0, t0, t0, "LOG")
	#X_LOOP          = AddKeyword (#Q_LOOP       , f0, s0, ks, t0, t0, t0, t0, "LOOP")
	#X_LTRIM_D       = AddKeyword (#Q_LTRIM_D    , f0, s0, ki, t0, t0, t0, t0, "LTRIM$")
	#X_MAKE          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "MAKE")
	#X_MAX           = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "MAX")
	#X_MID_D         = AddKeyword (#Q_MID_D      , f0, s0, ki, t0, t0, t0, t0, "MID$")
	#X_MIN           = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "MIN")
	#X_MOD           = AddKeyword (#Q_MOD        , f0, s0, ko, t0, t0, t0, t0, "MOD")
	#X_NEXT          = AddKeyword (#Q_NEXT       , f0, s0, ks, t0, t0, t0, t0, "NEXT")
	#X_NOT           = AddKeyword (#Q_NOT        , f0, s0, ko, t0, t0, t0, t0, "NOT")
	#X_NULL_D        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "NULL$")
	#X_OCT_D         = AddKeyword (#Q_OCT_D      , f0, s0, ki, t0, t0, t0, t0, "OCT$")
	#X_OCTO_D        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "OCTO$")
	#X_OPEN          = AddKeyword (#Q_OPEN       , f0, s0, ki, t0, t0, t0, t0, "OPEN")
	#X_OR            = AddKeyword (#Q_OR         , f0, s0, ko, t0, t0, t0, t0, "OR")
	#X_POF           = AddKeyword (#Q_POF        , f0, s0, ki, t0, t0, t0, t0, "POF")
	#X_PRINT         = AddKeyword (#Q_PRINT      , f0, s0, ks, t0, t0, t0, t0, "PRINT")
	#X_PROGRAM       = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "PROGRAM")
	#X_QUIT          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "QUIT")
	#X_RCLIP_D       = AddKeyword (#Q_RCLIP_D    , f0, s0, ki, t0, t0, t0, t0, "RCLIP$")
	#X_READ          = AddKeyword (#Q_READ       , f0, s0, ks, t0, t0, t0, t0, "READ")
	#X_REDIM         = AddKeyword (#Q_REDIM      , f0, s0, ks, t0, t0, t0, t0, "REDIM")
	#X_RETURN        = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "RETURN")
	#X_RIGHT_D       = AddKeyword (#Q_RIGHT_D    , f0, s0, ki, t0, t0, t0, t0, "RIGHT$")
	#X_RINCHR        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "RINCHR")
	#X_RINCHRI       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "RINCHRI")
	#X_RINSTR        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "RINSTR")
	#X_RINSTRI       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "RINSTRI")
	#X_RJUST_D       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "RJUST$")
	#X_ROTATER       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "ROTATER")
	#X_RTRIM_D       = AddKeyword (#Q_RTRIM_D    , f0, s0, ki, t0, t0, t0, t0, "RTRIM$")
	#X_SBYTE         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "SBYTE")
	#X_SBYTE         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SBYTE")
	#X_SBYTEAT       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SBYTEAT")
	#X_SEEK          = AddKeyword (#Q_SEEK       , f0, s0, ki, t0, t0, t0, t0, "SEEK")
	#X_SELECT        = AddKeyword (#Q_SELECT     , f0, s0, ks, t0, t0, t0, t0, "SELECT")
	#X_SET           = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SET")
	#X_SGN           = AddKeyword (#Q_SGN        , f0, s0, ki, t0, t0, t0, t0, "SGN")
	#X_SFUNCTION     = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "SFUNCTION")
	#X_SHARED        = AddKeyword (#Q_SHARED     , f0, s0, ks, t0, t0, t0, t0, "SHARED")
	#X_SHELL         = AddKeyword (#Q_SHELL      , f0, ss, ki, t0, t0, t0, t0, "SHELL")
	#X_SIGN          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SIGN")
	#X_SIGNED_D      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SIGNED$")
	#X_SIN           = AddKeyword (#Q_SIN        , f0, s0, km, t0, t0, t0, t0, "SIN")
	#X_SINGLE        = AddKeyword (#Q_SINGLE     , f0, s0, ks, t0, t0, t0, t0, "SINGLE")
	#X_SINGLE        = AddKeyword (#Q_SINGLE     , f0, s0, ki, t0, t0, t0, t0, "SINGLE")
	#X_SINGLEAT      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SINGLEAT")
	#X_SIZE          = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SIZE")
	#X_SLONG         = AddKeyword (#Q_LONG       , f0, s0, ks, t0, t0, t0, t0, "SLONG")
	#X_SLONG         = AddKeyword (#Q_LONG       , f0, s0, ki, t0, t0, t0, t0, "SLONG")
	#X_SLONGAT       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SLONGAT")
	#X_SMAKE         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SMAKE")
	#X_SPACE_D       = AddKeyword (#Q_SPACE_D    , f0, s0, ki, t0, t0, t0, t0, "SPACE$")
	#X_SSHORT        = AddKeyword (#Q_SHORT      , f0, s0, ks, t0, t0, t0, t0, "SSHORT")
	#X_SSHORT        = AddKeyword (#Q_SHORT      , f0, s0, ki, t0, t0, t0, t0, "SSHORT")
	#X_SSHORTAT      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SSHORTAT")
	#X_SQRT          = AddKeyword (#Q_INTEGER    , f0, s0, km, t0, t0, t0, t0, "SQRT")
	#X_STATIC        = AddKeyword (#Q_STATIC     , f0, sl, ks, t0, t0, t0, t0, "STATIC")
	#X_STEP          = AddKeyword (#Q_STEP       , f0, s0, ks, t0, t0, t0, t0, "STEP")
	#X_STOP          = AddKeyword (#Q_STOP       , f0, s0, ks, t0, t0, t0, t0, "STOP")
	#X_STR_D         = AddKeyword (#Q_STR_D      , f0, s0, ki, t0, t0, t0, t0, "STR$")
	#X_STRING        = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "STRING")
	#X_STRING        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "STRING")
	#X_STRING_D      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "STRING$")
	#X_STUFF_D       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "STUFF$")
	#X_SUB           = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "SUB")
	#X_SUBADDR       = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "SUBADDR")
	#X_SUBADDR       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SUBADDR")
	#X_SUBADDRAT     = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SUBADDRAT")
	#X_SUBADDRESS    = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "SUBADDRESS")
	#X_SWAP          = AddKeyword (#Q_SWAP       , f0, s0, ki, t0, t0, t0, t0, "SWAP")
	#X_TAB           = AddKeyword (#Q_TAB        , f0, s0, ki, t0, t0, t0, t0, "TAB")
	#X_TAN           = AddKeyword (#Q_TAN        , f0, s0, km, t0, t0, t0, t0, "TAN")
	#X_THEN          = AddKeyword (#Q_THEN       , f0, s0, ks, t0, t0, t0, t0, "THEN")
	#X_TO            = AddKeyword (#Q_TO         , f0, s0, ks, t0, t0, t0, t0, "TO")
	#X_TRIM_D        = AddKeyword (#Q_TRIM_D     , f0, s0, ki, t0, t0, t0, t0, "TRIM$")
	#X_TYPE          = AddKeyword (#Q_TYPE       , f0, s0, ks, t0, t0, t0, t0, "TYPE")
	#X_UBOUND        = AddKeyword (#Q_UBOUND     , f0, s0, ki, t0, t0, t0, t0, "UBOUND")
	#X_UBYTE         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "UBYTE")
	#X_UBYTE         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "UBYTE")
	#X_UBYTEAT       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "UBYTEAT")
	#X_UCASE_D       = AddKeyword (#Q_UCASE_D    , f0, s0, ki, t0, t0, t0, t0, "UCASE$")
	#X_ULONG         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "ULONG")
	#X_ULONG         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "ULONG")
	#X_ULONGAT       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "ULONGAT")
	#X_UNION         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "UNION")
	#X_UNTIL         = AddKeyword (#Q_UNTIL      , f0, s0, ks, t0, t0, t0, t0, "UNTIL")
	#X_USHORT        = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "USHORT")
	#X_USHORT        = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "USHORT")
	#X_USHORTAT      = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "USHORTAT")
	#X_VOID          = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "VOID")
	#X_WHILE         = AddKeyword (#Q_WHILE      , f0, s0, ks, t0, t0, t0, t0, "WHILE")
	#X_WRITE         = AddKeyword (#Q_WRITE      , f0, s0, ks, t0, t0, t0, t0, "WRITE")
	#X_XLONG         = AddKeyword (            q0, f0, s0, ks, t0, t0, t0, t0, "XLONG")
	#X_XLONG         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "XLONG")
	#X_XLONGAT       = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "XLONGAT")
	#X_XMAKE         = AddKeyword (            q0, f0, s0, ki, t0, t0, t0, t0, "XMAKE")
	#X_XOR           = AddKeyword (#Q_XOR        , f0, s0, ko, t0, t0, t0, t0, "XOR")
'
	#X_PRE_BYREF     = AddKeyword (            q0, f0, s0, kh, t0, t0, t0, t0, "@")
	#X_PRE_SHARED    = AddKeyword (            q0, f0, s5, kh, t0, t0, t0, t0, "#")
	#X_PRE_EXTERNAL  = AddKeyword (            q0, f0, s7, kh, t0, t0, t0, t0, "##")
'
'	#X_POST_SBYTE    = AddKeyword (            q0, f0, s0, kh,  2, t0, t0, t0, "@")		' part of symbol
'	#X_POST_UBYTE    = AddKeyword (            q0, f0, s0, kh,  3, t0, t0, t0, "@@")	' part of symbol
'	#X_POST_SSHORT   = AddKeyword (#Q_POST_SSHORT, f0, s0, kh,  4, t0, t0, t0, "%")		' part of symbol
'	#X_POST_USHORT   = AddKeyword (            q0, f0, s0, kh,  5, t0, t0, t0, "%%")	' part of symbol
'	#X_POST_SLONG    = AddKeyword (#Q_POST_SLONG , f0, s0, kh,  6, t0, t0, t0, "&")		' part of symbol
'	#X_POST_ULONG    = AddKeyword (            q0, f0, s0, kh,  7, t0, t0, t0, "&&")	' part of symbol
'	#X_POST_XLONG    = AddKeyword (            q0, f0, s0, kh,  8, t0, t0, t0, "~")		' part of symbol
'	#X_POST_GIANT    = AddKeyword (            q0, f0, s0, kh, 12, t0, t0, t0, "$$")	' part of symbol
'	#X_POST_SINGLE   = AddKeyword (#Q_POST_SINGLE, f0, s0, kh, 13, t0, t0, t0, "!")		' part of symbol
'	#X_POST_DOUBLE   = AddKeyword (#Q_POST_DOUBLE, f0, s0, kh, 14, t0, t0, t0, "#")		' part of symbol
'	#X_POST_STRING   = AddKeyword (#Q_POST_STRING, f0, s0, kh, 15, t0, t0, t0, "$")		' part of symbol
'
	#X_PLUS          = AddKeyword (#Q_PLUS       , f0, s0, ko, t0, t0, t0, t0, "+")		' unary
	#X_MINUS         = AddKeyword (#Q_MINUS      , f0, s0, ko, t0, t0, t0, t0, "-")		' unary
	#X_ADDRESS       = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "&")		' unary
'
	#X_ADD           = AddKeyword (#Q_ADD        , f0, s0, ko, t0, t0, t0, t0, "+")
	#X_SUBTRACT      = AddKeyword (#Q_SUBTRACT   , f0, s0, ko, t0, t0, t0, t0, "-")
	#X_MULTIPLY      = AddKeyword (#Q_MULTIPLY   , f0, s0, ko, t0, t0, t0, t0, "*")
	#X_DIVIDE        = AddKeyword (#Q_DIVIDE     , f0, s0, ko, t0, t0, t0, t0, "/")
	#X_POWER         = AddKeyword (#Q_POWER      , f0, s0, ko, t0, t0, t0, t0, "**")
	#X_IDIVIDE       = AddKeyword (#Q_IDIVIDE    , f0, s0, ko, t0, t0, t0, t0, "\\")
	#X_REMAINDER     = AddKeyword (#Q_MOD        , f0, s0, ko, t0, t0, t0, t0, "%")
'
	#X_USHIFT        = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "<<<")
	#X_DSHIFT        = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, ">>>")
	#X_LSHIFT        = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "<<")
	#X_RSHIFT        = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, ">>")
	#X_NOTBIT        = AddKeyword (#Q_NOT        , f0, s0, ko, t0, t0, t0, t0, "~")
	#X_ANDBIT        = AddKeyword (#Q_AND        , f0, s0, ko, t0, t0, t0, t0, "&")
	#X_ORBIT         = AddKeyword (#Q_OR         , f0, s0, ko, t0, t0, t0, t0, "|")
	#X_TESTL         = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "!!")
	#X_NOTL          = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "!")
	#X_ANDL          = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "&&")
	#X_XORL          = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "^^")
	#X_ORL           = AddKeyword (            q0, f0, s0, ko, t0, t0, t0, t0, "||")
	#X_EQ            = AddKeyword (#Q_EQ         , f0, s0, ko, t0, t0, t0, t0, "=")
	#X_NE            = AddKeyword (#Q_NE         , f0, s0, ko, t0, t0, t0, t0, "<>")
	#X_LT            = AddKeyword (#Q_LT         , f0, s0, ko, t0, t0, t0, t0, "<")
	#X_LE            = AddKeyword (#Q_LE         , f0, s0, ko, t0, t0, t0, t0, "<=")
	#X_GE            = AddKeyword (#Q_GE         , f0, s0, ko, t0, t0, t0, t0, ">=")
	#X_GT            = AddKeyword (#Q_GT         , f0, s0, ko, t0, t0, t0, t0, ">")
	#X_EQU           = AddKeyword (#Q_EQ         , f0, s0, ko, t0, t0, t0, t0, "==")
	#X_NEQ           = AddKeyword (#Q_NE         , f0, s0, ko, t0, t0, t0, t0, "!=")
	#X_NGE           = AddKeyword (#Q_LT         , f0, s0, ko, t0, t0, t0, t0, "!>=")
	#X_NGT           = AddKeyword (#Q_LE         , f0, s0, ko, t0, t0, t0, t0, "!>")
	#X_NLE           = AddKeyword (#Q_GE         , f0, s0, ko, t0, t0, t0, t0, "!<")
	#X_NLT           = AddKeyword (#Q_GT         , f0, s0, ko, t0, t0, t0, t0, "!<=")
'
'	#X_KEYWORD       = AddKeyword (            q0, f0, s0, k0, t0, t0, t0, t0, "")
'	#X_KEYWORD       = AddKeyword (            q0, f0, s0, k0, t0, t0, t0, t0, "")
	#xztoken         = #ntoken
END FUNCTION
'
'
' ##################################
' #####  LoadQBasicProgram ()  #####
' ##################################
'
FUNCTION  LoadQBasicProgram (@qbasic$[])
'
	DIM qbasic$[]																		' empty qbasic$[]
' print = $$TRUE																	' print for debugging
	XstGetCommandLineArguments (@count, @arg$[])		' arg$[1] = QBasic program filename
'
' input filename of QBasic program if no command line argument
'
	IF (count < 2) THEN
		qfile$ = INLINE$ ("input filename of QuickBasic file ===>> ")
		IFZ qfile$ THEN qfile$ = "qbasic.bas"
	ELSE
		qfile$ = arg$[1]
	END IF
'
' qfile$ = filename of QBasic program - must be ASCII
'
	IFZ qbasic$[] THEN
		XstLoadStringArray (@qfile$, @qbasic$[])	' qbasic$[] = QBasic program
	END IF
'
	IFZ qbasic$[] THEN
		dot = RINSTR (qfile$, ".")
		IF dot THEN file$ = LEFT$ (qfile$, dot-1)
	END IF
'
	IFZ qbasic$[] THEN
		qfile$ = file$ + ".bas"
		XstLoadStringArray (@qfile$, @qbasic$[])	' qbasic$[] = QBasic program
	END IF
'
	IFZ qbasic$[] THEN
		qfile$ = file$ + ".x"
		XstLoadStringArray (@qfile$, @qbasic$[])	' qbasic$[] = QBasic program
	END IF
'
' print QBasic program during testing
'
	uline = UBOUND (qbasic$[])									' upper bound of QBasic array
	FOR line = 0 TO uline												' for all lines of QBasic source
		line$ = RTRIM$(qbasic$[line])							' line$ = next line of QBasic program
		IF line$ THEN topline = line							' this could be the final QBasic line
		IF print THEN PRINT line$									' perhaps print the QBasic line
		qbasic$[line] = line$											' replace trimmed line
	NEXT line
'
	IF (topline != uline) THEN REDIM qbasic$[topline]
END FUNCTION
'
'
' ###############################
' #####  QBasicToXBasic ()  #####
' ###############################
'
FUNCTION  QBasicToXBasic (@qb$[], @xb$[])
'
	DIM xb$[]														' no XBasic source
	IFZ qb$[] THEN RETURN								' no QBasic source
'
	Initialize ()												' initialize everything
'
	DIM #qbasic$[]											'
	DIM #xbasic$[]											' no XBasic source yet
	SWAP #qbasic$[], qb$[]							' make QBasic source SHARED
'
	ParseQBasic ()											' convert #qbasic$[] source into tokens in #program[]
	Translate ()												' translate #program[] tokens into xbasic$[] source code
'
	SWAP #qbasic$[], qb$[]							' restore QBasic source
	SWAP #xbasic$[], xb$[]							' return XBasic source
END FUNCTION
'
'
' ############################
' #####  ParseQBasic ()  #####
' ############################
'
FUNCTION  ParseQBasic ()
'
	IFZ #qbasic$[] THEN RETURN					' no QBasic source program
	#quline = UBOUND (#qbasic$[])				' last line in QBasic source
'
' parse QBasic program into tokens-numbers in #program[function,line,token]
' creates symbol table in #token[] and #string$[]
'
	line = 0
	uline = 4095
	DIM line[uline,]
'
	#function = 0
'
	FOR i = 0 TO #quline											' for all QBasic lines
		DIM token[]															' start with zero tokens
		function = #function										' remember this function-number
		qbasic$ = #qbasic$[i]										' next line of QBasic source-code
		qbasicline$ = qbasic$										'
		ParseSourceLine (@qbasic$, @token[])		' parse this line into tokens
		IF #print THEN PRINT										'
		IF #print THEN PRINT qbasic$						'
		IF #print THEN DeparseTokens (@token[], @line$) : PRINT line$
		IF token[] THEN
			IF (function != #function) THEN				' first executable line of new function
				DEC line														' this line goes in the next function
				REDIM line[line,]										' array size = number of lines in function
				IF (#ufunction < #function) THEN
					#ufunction = #ufunction + 1024		' add 1024 lines to this function
					REDIM #program[#ufunction,]				' make room for new lines of tokens in function
				END IF
				SWAP #program[#function,], line[]		' attach lines of tokens to program function
				INC #function												' next function number
				line = 0														' first line in new function
				uline = 4095												' default number of lines in new function
				DIM line[uline,]										' make room for lines of tokens in new function
			END IF
		END IF
		IF (line > uline) THEN									' more lines than array space
			uline = uline + 256										' allow room for 256 more lines
			REDIM line[uline,]										' make room for more lines of tokens
		END IF
		SWAP line[line,], token[]								' add tokens to program
	NEXT i
END FUNCTION
'
'
' ##########################
' #####  Translate ()  #####
' ##########################
'
FUNCTION  Translate ()
	XLONG  function[]
	XLONG  line[]
'
	#xline = 0																				' start at beginning
	DIM #xbasic$[]																		' start with no XBasic
	IFZ #program[] THEN RETURN												' no QBasic program tokens
	XstLoadStringArray (@"start.txt", @start$[])			' get standard XBasic startup
	IFZ start$[] THEN RETURN													' support text-file missing
	#xuline = #quline << 1														' double room for XBasic
	DIM xbasic$[#xuline]															' array to hold XBasic
	OutputXBasic (@start$[])													' startup #xbasic$[]
'
'
' translate QBasic tokens in #program[function,line,token] into XBasic source
'
	line = 0
	token = 0
	#function = 0
	#ufunction = UBOUND (#program[])
'
	DIM func[]
	DIM line[]
'
	FOR function = 0 TO ufunction											' for all functions in program
		SWAP #program[#function,], function[]						' function[] = tokens for function
		uline = UBOUND (function[])											' # of lines in this function
		#function = function														' #function = this function
		FOR line = 0 TO uline														' for all lines in function
			SWAP function[line,], line[]									' line[] = tokens for next line
			TranslateLine (@line[])												' translate QBasic tokens to XBasic source
		NEXT line																				'
	NEXT function
END FUNCTION
'
'
' ##############################
' #####  TranslateLine ()  #####
' ##############################
'
FUNCTION  TranslateLine (line[])
'
	ntoken = 0
	IFZ line[] THEN RETURN
	utoken = UBOUND (line[])
'
' translate all statements on line
'
	DO
		done = TranslateStatement (@line[], @ntoken)
		IF (ntoken > utoken) THEN EXIT DO
	LOOP UNTIL done
END FUNCTION
'
'
' ###################################
' #####  TranslateStatement ()  #####
' ###################################
'
FUNCTION  TranslateStatement (line[], ntoken)


END FUNCTION
'
'
' ##############################
' #####  DeparseTokens ()  #####
' ##############################
'
FUNCTION  DeparseTokens (token[], line$)
'
	line$ = ""
	IFZ token[] THEN RETURN
'
	upper = UBOUND (token[])
'
	FOR i = 0 TO upper
		token = token[i]
		IFZ token THEN DO NEXT
		whitestring = token >> 24
		token = token AND 0x00FFFFFF
		IF whitestring THEN line$ = line$ + #whitestring$[whitestring]
		IF (token <= #utoken) THEN
			line$ = line$ + #string$[#token[token].string]
		END IF
	NEXT i
END FUNCTION
'
'
' ################################
' #####  ParseSourceLine ()  #####  parse line of QBasic source into tokens
' ################################
'
FUNCTION  ParseSourceLine (@line$, @line[])
	STATIC  FUNCADDR  XLONG  parseFunction[] (STRING, XLONG)
'
	IFZ parseFunction[] THEN GOSUB LoadParseFunctionArray
'
	offset = 0																' offset to next character in line$
	DIM line[]																' start with nothing on line
	DIM #line[]																' start with no tokens on line
	#whitebyte = 0														' leading whitespace byte = zero
	#nlinetoken = 0														' where to put next token in #line[]
	#ulinetoken = 255													' upper bound of #line[] of tokens
	DIM #line[#ulinetoken]										' make room for plenty of tokens
	#functionLine = $$FALSE										' not function definition line
'
	IFZ line$ THEN RETURN											' empty line
	uchar = UBOUND (line$)										' uchar = upper character in line$
'
' parse the line - one language element at a time
'
	DO																															' all characters on line
		char = line${offset}																					' get next character on line
		token = @parseFunction[char] (@line$, @offset)								' call appropriate function to process
		token = token AND 0x00FFFFFF																	' remove whitestring from token
		IFZ token THEN EXIT DO																				' zero token means end of line
'
		IF (#ntoken == 1) THEN																				' first important token on line
			IF ((token == #Q_FUNCTION) OR (token == #Q_SUB)) THEN				' first line of new function
				INC #function																							' next function
			END IF
		END IF
	LOOP WHILE (offset <= uchar)
'
	IFZ #nlinetoken THEN											' nothing but whitespace = blank line
		DIM #line[]															'
		DIM line[]															'
	ELSE																			'
		REDIM #line[#nlinetoken]								' resize token array to minimum
		#line[#nlinetoken] = 0									' null terminate just in case
		SWAP line[], #line[]										' return line[] of tokens
	END IF																		'
'
	RETURN																		' end of function
'
'
'
' ****************************************
' *****  SUB LoadParseFunctionArray  *****
' ****************************************
'
' Array parseFunction[] contains the addresses of the functions that
' should parse the next language-element, based on its 1st character.
' For example, if the first character of a language-element is "0"-"9",
' the language-element is some kind of number.  "+","-",etc = operators.
' "A"-"Z", "a"-"z", "_" = some kind of symbol.  space & tab = whitespace.
'
' #####  NOTE  #####
'
' The following character ranges are more-or-less correct for XBasic,
' but almost certainly need a little modification for QBasic.
'
SUB LoadParseFunctionArray
	DIM parseFunction[255]
	FOR c = 0 TO 255
		SELECT CASE TRUE
			CASE (c >= 128)	: parseFunction[c] = &ParseWhitespace()		' convert trash to spaces
			CASE (c >= 123)	: parseFunction[c] = &ParseCharacter()		' character or operator
			CASE (c >=  97)	: parseFunction[c] = &ParseSymbol()				' "a-z"
			CASE (c ==  95)	: parseFunction[c] = &ParseSymbol()				' "_"
			CASE (c >=  91)	: parseFunction[c] = &ParseCharacter()		' character or operator
			CASE (c >=  65)	: parseFunction[c] = &ParseSymbol()				' "A-Z"
			CASE (c >=  58)	: parseFunction[c] = &ParseCharacter()		' character or operator
			CASE (c >=  48)	: parseFunction[c] = &ParseNumber()				' "0-9"
			CASE (c ==  36)	: parseFunction[c] = &ParseSymbol()				' "$con" or "$$con
			CASE (c ==  35)	: parseFunction[c] = &ParseSymbol()				' "#var" or "##var"
			CASE (c >=  33)	: parseFunction[c] = &ParseCharacter()		' character / operator
			CASE (c ==  32)	: parseFunction[c] = &ParseWhitespace()		' space chars
			CASE (c ==   9)	: parseFunction[c] = &ParseWhitespace()		' tab chars
			CASE (c <=   8)	: parseFunction[c] = &ParseWhitespace()		' convert trash to spaces
		END SELECT
	NEXT c
END SUB
END FUNCTION
'
'
' ################################
' #####  ParseWhitespace ()  #####  parse whitespace characters into a whitespace-string token
' ################################
'
' This function collects consecutive whitespace characters starting
' at offset in line$.  This function then looks for the whitespace-string
' it collected in the 255 element #whitestring$[] array.  If it finds an
' identical whitestring, it returns the element # of the matching element
' in #whitestring$[].  If it doesn't find a match, it adds the whitestring
' to #whitestring$[] and returns the element # of the new whitestring.
' If a program is wacko enough to have more than 255 different whitespace
' strings, this function will return one of the 255 existing whitespaces.
'
' The 255 whitespace values are designed to be imbedded in whatever token
' follows to indicate "leading whitespace".
'
FUNCTION  ParseWhitespace (@line$, @offset)
'
	token = 0
	first = offset
	#whitebyte = 0
'
	DO
		char = line${offset}									' char = next character
		white = #charsetWhitespace[char]			' is character whitespace
		IFZ char THEN RETURN #whitebyte				' clip trailing whitespace
		IFZ white THEN EXIT DO								' exit unless whitespace
		INC offset														' next character on line
	LOOP
'
	token = 0
	past = offset
	length = past - first
	IFZ length THEN RETURN #whitebyte			' no whitespace
'
	whitestring$ = MID$ (line$, first+1, length)
	IFZ whitestring$ THEN RETURN #whitebyte
'
	FOR i = 1 TO #nwhite
		IF (whitestring$ == #whitestring$[i]) THEN #whitebyte = i : RETURN #whitebyte
	NEXT i
'
' this whitestring is not yet in whitestring array, so add it
'
	IF (#nwhite < #uwhite) THEN
		INC #nwhite
		#whitestring$[#nwhite] = whitestring$
		#whitebyte = #nwhite
	ELSE
		#whitebyte = 1			' no room for another whitestring, so fake one
	END IF
'
	RETURN #whitebyte
END FUNCTION
'
'
' ###############################
' #####  ParseCharacter ()  #####  parse special characters into the appropriate token
' ###############################
'
' This function parses 1 or more consecutive non-alphanumeric
' characters starting at offset in line$ into a symbol-token.
' Examples include operators ("<>", "<", "<=", "+", "*", "/")
' and other language elements ("[" "]" "(" ")" "'"), etc.
'
FUNCTION  ParseCharacter (@line$, @offset)
	STATIC  SUBADDR  parseCharacter[]
	STATIC  XLONG  characterToken[]
'
	IFZ characterToken[] THEN GOSUB Initialize
'
	linelength = LEN (line$)
	char = line${offset}
	start = offset
	INC offset
'
	token = characterToken[char]									' this one character generates a token
	IFZ token THEN GOSUB @parseCharacter[char]		' GOSUB a subroutine to parse this token
	IF token THEN OutputToken (@token)						' add token to program
	RETURN token
'
'
' characters that have their own tokens
'
SUB Character
	symbol$ = CHR$ (char)
	token = AddToken (0, 0, 0, $$KIND_CHARACTER, 0, 0, 0, 0, @symbol$)
	IF token THEN #token[token].ivalue = char
END SUB
'
'
' *************************************************************************
' *****  Parse characters that may be part of 1+ character sequences  *****
' *************************************************************************
'
'
'
' *****  &  *****
'
' &O = prefix for octal literal : &O17777777777 = max-long : &O37777777777 = -1
' &H = prefix for hexadecimal literal
'
SUB Ampersand
	value = 0											' value = 0
	digits = 0										' hex digits
	char = line${offset}					' char after &
'
	INC offset										' offset to character after &O or &H prefix
'
	SELECT CASE char
		CASE 'O'
				char = line${offset}				' but only if next character is 0-7
				DO WHILE #charsetOctal[char]			' while character is 0-7
					INC digits								' count valid hexadecimal digits
					INC offset								' offset to next hexadecimal digit
					SELECT CASE TRUE
						CASE ((char >= '0') AND (char <= '7'))	: octal = char - '0'
					END SELECT
					char = line${offset}							' next character
					value = (value << 3) OR octal			' create cumulative hex value
				LOOP UNTIL (value AND 0xE0000000)		' quit before 32-bits overflows
		CASE 'H'
				char = line${offset}				' but only if next character is 0-9 or A-F
				DO WHILE #charsetHexUpper[char]		' while character is 0-9 or A-F
					INC digits								' count valid hexadecimal digits
					INC offset								' offset to next hexadecimal digit
					SELECT CASE TRUE
						CASE ((char >= '0') AND (char <= '9'))	: hex = char - '0'
						CASE ((char >= 'A') AND (char <= 'F'))	: hex = char - 'A' + 10
'						CASE ((char >= 'a') AND (char <= 'f'))	: hex = char - 'a' + 10		' always upper-case in QBasic
					END SELECT
					char = line${offset}							' next character
					value = (value << 4) OR hex				' create cumulative hex value
				LOOP UNTIL (value AND 0xF0000000)		' quit before 32-bits overflows
	END SELECT
'
	IFZ digits THEN
		offset = start + 1
		token = AddToken (0, 0, 0, $$KIND_CHARACTER, 0, 0, 0, 0, @"&")
	ELSE
		symbol$ = MID$ (line$, start+1, digits+2)
		token = AddToken (0, 0, 0, $$KIND_LITERAL, $$TYPE_XLONG, 0, 0, 0, @symbol$)
		IF token THEN #token[token].ivalue = value
	END IF
END SUB
'
'
' *****  "  *****  Literal string  *****
'
SUB DoubleQuote
	scans = offset				' 0 offset to character after opening double-quote
	start = offset				' 1 offset to opening double-quote
 	final = linelength		' 0 offset to null-terminator
'
	IF (scans < final) THEN
		rawchar = line${scans}
		DO UNTIL (rawchar = '"')
			IF (rawchar = '\\') THEN
				INC scans
				rawchar = line${scans}
			END IF
			INC scans
			rawchar = line${scans}
		LOOP WHILE (scans < final)
	END IF
'
	IF (scans < final) THEN
		INC scans
		offset = scans		' terminated by " character - normal case
	ELSE
		offset = scans		' terminated by end-of-line null-terminator, not "
		INC scans
	END IF
'
	lit$ = MID$ (line$, start, (scans-start)) + "\""
	token = AddToken (0, 0, 0, $$KIND_LITERAL, $$TYPE_STRING, 0, 0, 0, @lit$)
END SUB
'
'
' *****  '  *****
'
SUB SingleQuote
	comment$ = MID$ (line$, offset)
	token = AddToken (0, 0, 0, $$KIND_COMMENT, $$TYPE_STRING, 0, 0, 0, @comment$)
	offset = linelength
END SUB
'
'
' *****  .  *****   .2345e3 (a number)  or  .component of composite
'
SUB Dot
	two = line${offset}
	SELECT CASE TRUE
		CASE #charsetNumeric[two]								' a number, like .234567
					DEC offset
					token = ParseNumber (@line$, @offset)
		CASE #charsetUpperLower[two]						' composite element, like .ssn in variable.ssn
					DEC offset
					token = ParseSymbol (@line$, @offset)
		CASE ELSE																' standalone . is a syntax error
					token = AddToken (0, 0, 0, $$KIND_CHARACTER, $$TYPE_UBYTE, 0, 0, 0, ".")
					IF token THEN #token[token].ivalue = '.'
					token = #Q_DOT
	END SELECT
END SUB
'
'
' *****  <  *****   <  <>  <=
'
SUB LessThan
	two = line${offset}												' char after <
	SELECT CASE two
		CASE '>'	: token = #Q_NE	: INC offset	' <>
		CASE '='	: token = #Q_LE	: INC offset	' <=
		CASE ELSE	: token = #Q_LT								' <
	END SELECT
END SUB
'
'
' *****  >  *****  >  >=
'
SUB GreaterThan
	two = line${offset}
	SELECT CASE two
		CASE '='	: token = #Q_GE	: INC offset		' >=
		CASE ELSE	: token = #Q_GT									' >
	END SELECT
END SUB
'
'
'
' **********************************************************************************
' *****  load characterToken[] with tokens for 1-character length tokens only  *****
' *****  load parseCharacter[] with addresses of routines to parse characters  *****
' **********************************************************************************
'
SUB Initialize
	DIM characterToken[255]
	DIM parseCharacter[255]
'
' The following single characters get parsed into a token.
' In other words, whenever the first character a parse routine
' encounters is one of these characters, the single character
' always gets parsed into a token.
'
	characterToken [ '+' ] = #Q_PLUS
	characterToken [ '-' ] = #Q_MINUS
	characterToken [ '*' ] = #Q_MULTIPLY
	characterToken [ '/' ] = #Q_DIVIDE
	characterToken [ '^' ] = #Q_POWER
	characterToken [ '=' ] = #Q_EQ
'	characterToken [ '&' ] = #Q_AMPERSAND								' does QuickBasic support & operator ???
	characterToken ['\\' ] = #Q_IDIVIDE
	characterToken [ '(' ] = #Q_LPAREN
	characterToken [ ')' ] = #Q_RPAREN
	characterToken [ '[' ] = #Q_LBRAK
	characterToken [ ']' ] = #Q_RBRAK
	characterToken [ ':' ] = #Q_COLON
	characterToken [ ';' ] = #Q_SEMI
	characterToken [ ',' ] = #Q_COMMA
'
' subroutines to process tokens starting with any character
'
'																											'  00-32 handled elsewhere
	parseCharacter [ '!' ] = SUBADDRESS (Character)			'  !
	parseCharacter [ '"' ] = SUBADDRESS (DoubleQuote)		'  "
	parseCharacter [ '#' ] = SUBADDRESS (Character)			'  #
	parseCharacter [ '$' ] = SUBADDRESS (Character)			'  $
	parseCharacter [ '%' ] = SUBADDRESS (Character)			'  %
	parseCharacter [ '&' ] = SUBADDRESS (Ampersand)			'  &
	parseCharacter [ ''' ] = SUBADDRESS (SingleQuote)		'  '
	parseCharacter [ '.' ] = SUBADDRESS (Dot)						'  .
'																											'     48-57 handled elsewhere
	parseCharacter [ '<' ] = SUBADDRESS (LessThan)			'  <  <=  <>
	parseCharacter [ '>' ] = SUBADDRESS (GreaterThan)		'  >  >=
	parseCharacter [ '?' ] = SUBADDRESS (Character)			'  ?
	parseCharacter [ '@' ] = SUBADDRESS (Character)			'  @
'																											'     65-90 handled elsewhere
	parseCharacter [ '_' ] = SUBADDRESS (Character)			'  _
	parseCharacter [ '`' ] = SUBADDRESS (Character)			'  `
'																											'     97-122 handled elsewhere
	parseCharacter [ '{' ] = SUBADDRESS (Character)			'  {
	parseCharacter [ '|' ] = SUBADDRESS (Character)			'  |
	parseCharacter [ '}' ] = SUBADDRESS (Character)			'  }
	parseCharacter [ '~' ] = SUBADDRESS (Character)			'  ~
	parseCharacter [ 127 ] = SUBADDRESS (Character)			'     CHR$(127)
'																											'     128-255 are white trash
END SUB
END FUNCTION
'
'
' ############################
' #####  ParseNumber ()  #####  parse a number into the appropriate number token
' ############################
'
FUNCTION  ParseNumber (@line$, @offset)
'
	enter = offset
	start = offset
	specType = XstStringToNumber (@line$, @start, @offset, @rtype, @value$$)
	vhi = GHIGH (value$$)
	vlo = GLOW (value$$)
	value = vlo
'
	suffix = line${offset}
	IF (specType < 0) THEN specType = 0
'
' see if number is followed by a type-suffix
'
	IFZ specType THEN
		SELECT CASE suffix
			CASE '%'	: specType = $$TYPE_SSHORT	: INC offset
			CASE '&'	: specType = $$TYPE_SLONG		: INC offset
			CASE '!'	: specType = $$TYPE_SINGLE	: INC offset
			CASE '#'	: specType = $$TYPE_DOUBLE	: INC offset
		END SELECT
	END IF
'
	number$ = MID$ (line$, start+1, offset-start)
'
' if type not specified by anything yet, decide on basis of the value
'
	IFZ specType THEN
		SELECT CASE rtype
			CASE 0							: specType = $$SLONG			' zero
			CASE $$TYPE_XLONG		: specType = $$SLONG			' "0x..."
			CASE $$TYPE_SINGLE	: specType = $$SINGLE			' "0s..."
			CASE $$TYPE_GIANT		: specType = MinTypeFromGiant (value$$)
			CASE $$TYPE_DOUBLE	:	value#   = DMAKE (vhi, vlo)
														specType = MinTypeFromDouble (value#)
			CASE ELSE						: PRINT "ParseNumber() : error" : RETURN ($$FALSE)
		END SELECT
	END IF
'
' add the literal number token to the token stream
'
	type = specType
	kind = $$KIND_LITERAL
	token = AddToken (0, 0, 0, kind, type, 0, 0, 0, @number$)
	IF token THEN
		IF (type < $$TYPE_SINGLE) THEN #token[token].ivalue = value$$ ELSE #token[token].fvalue = value#
	END IF
	OutputToken (@token)
	RETURN (token)
END FUNCTION
'
'
' ############################
' #####  ParseSymbol ()  #####  parse a symbol into the appropriate token
' ############################
'
FUNCTION  ParseSymbol (@line$, @offset)
'
' collect the symbol
'
	token = 0
	start = offset
	GetSymbol (@line$, @offset, @symbol$)
	IFZ symbol$ THEN RETURN token
'
' is symbol a keyword or component of composite
'
	firstchar = line${start}
	afterchar = line${offset}
	finalchar = line${offset-1}
'
' ??? keyword symbol ???
'
	IF (firstchar != '.') THEN
		token = TestForKeyword (@symbol$)
		IF token THEN
			OutputToken (token)
			RETURN (token)
		END IF
	END IF
'
' 1st and 2nd tokens on line need special attention
'
	SELECT CASE #tokenptr
		CASE 0	:	IF ((afterchar == ':') AND (LEN(symbol$) == offset)) THEN		' label:
								INC offset
								token = AddToken (0, 0, 0, $$KIND_LABEL, $$TYPE_GOADDR, 0, 0, 0, @symbol$)
								OutputToken (@token)
								RETURN (token)
							END IF
		CASE 1	:	IF (#lasttoken == #Q_TYPE) THEN
								IF #charsetUpperLower[firstchar] THEN
									IF #charsetUpperLowerNumeric[finalchar] THEN
										token = AddToken (0, 0, 0, $$KIND_TYPE, 0, 0, 0, 0, @symbol$)
										OutputToken (@token)
										RETURN (token)
									END IF
								END IF
							END IF
	END SELECT
'
' certain symbols are interpreted differently if following certain tokens
'
	SELECT CASE #lasttoken
		CASE #Q_GOTO																				' GOTO label
			token = AddToken (0, 0, 0, $$KIND_LABEL, $$TYPE_GOADDR, 0, 0, 0, @symbol$)
			OutputToken (@token)
			RETURN (token)
		CASE #Q_GOSUB, #Q_SUB																' SUB subname or GOSUB subname
			token = AddToken (0, 0, 0, $$KIND_LABEL, $$TYPE_SUBADDR, 0, 0, 0, @symbol$)
			OutputToken (@token)
			RETURN (token)
		CASE #Q_LPAREN
			SELECT CASE #backtoken
				CASE T_GOADDRESS																' GOADDRESS (label)
					token = AddToken (0, 0, 0, $$KIND_LABEL, $$TYPE_GOADDR, 0, 0, 0, @symbol$)
					OutputToken (@token)
					RETURN (token)
				CASE T_SUBADDRESS																' SUBADDRESS (subname)
					token = AddToken (0, 0, 0, $$KIND_LABEL, $$TYPE_SUBADDR, 0, 0, 0, @symbol$)
					OutputToken (@token)
					RETURN (token)
			END SELECT
		CASE ELSE
	END SELECT
'
' symbols that begin with certain characters require special attention
'
' .components of composites
'
	IF (firstchar = '.') THEN															' .COMPONENT name
		token = AddToken (0, 0, 0, $$KIND_SYMBOL, 0, 0, 0, 0, @symbol$)
		OutputToken (@token)
		RETURN (token)
	END IF
'
' normal symbols can have type suffix characters
'
	SELECT CASE afterchar
		CASE '@'	:	symbol$ = symbol$ + "@"
								type = $$SBYTE
								INC offset
		CASE '%'	:	symbol$ = symbol$ + "%"
								type = $$SSHORT
								INC offset
		CASE '&'	:	symbol$ = symbol$ + "&"
								type = $$SLONG
								INC offset
		CASE '!'	:	symbol$ = symbol$ + "!"
								type = $$SINGLE
								INC offset
		CASE '#'	:	symbol$ = symbol$ + "#"
								type = $$DOUBLE
								INC offset
		CASE '$'	:	symbol$ = symbol$ + "$"
								type = $$STRING
								INC offset
		CASE ELSE	:	type = 0
	END SELECT
'
' see what follows trailing spaces/tabs
'
	sx = 0
	test = line${offset + sx}
	DO WHILE (#charsetSpaceTab[test])
		INC sx
		test = line${offset + sx}
	LOOP
'
' see if this is an array or function symbol
'
	SELECT CASE test
		CASE '('	: kind = $$KIND_FUNCTION
		CASE '['	: kind = $$KIND_ARRAY
		CASE ELSE	: kind = $$KIND_VARIABLE
	END SELECT
'
	token = AddToken (0, 0, 0, kind, type, scope, 0, 0, @symbol$)
	OutputToken (@token)
	RETURN (token)
END FUNCTION
'
'
' ##########################
' #####  GetSymbol ()  #####
' ##########################
'
FUNCTION  GetSymbol (line$, offset, symbol$)
'
	start = offset
	char = line${offset}
	IF (char == '.') THEN INC offset : char = line${offset}		' .component symbol
'
	DO WHILE (#charsetSymbolInner[char])												' TRUE while A-Z, a-z, 0-9, "_"
		INC offset
		char = line${offset}
	LOOP
'
	symbol$ = MID$ (line$, start+1, offset-start)
END FUNCTION
'
'
' ############################
' #####  OutputToken ()  #####  parse a symbol into the appropriate token
' ############################
'
FUNCTION  OutputToken (token)
'
	#backtoken = #lasttoken
	#lasttoken = token
'
	IF (#nlinetoken > #ulinetoken) THEN
		#ulinetoken = #ulinetoken + 256
		REDIM #line[#ulinetoken]
	END IF
'
	IF (#whitebyte > 255) THEN #whitebyte = 1			' disaster catcher
	token = (#whitebyte << 24) + token						' put whitebyte in token
	#line[#nlinetoken] = token										' add complete token to line of tokens
	INC #nlinetoken																' next token in this line of tokens
	#whitebyte = 0																' whitestring output so cancel it
'
	IF #print THEN PRINT " "; HEX$(token,8);
END FUNCTION
'
'
' ###############################
' #####  TestForKeyword ()  #####
' ###############################
'
FUNCTION  TestForKeyword (string$)
'
	token = 0
	IFZ string$ THEN RETURN token
'
	firstchar = string${0}
	IF (firstchar = '_') THEN RETURN token
'
	length = LEN (string$)
	upper = length - 1
	hash = 0
'
	FOR i = 0 TO upper												' for all bytes in string
		hash = hash + #hx[string${i}]						' add hash for that byte
	NEXT i																		' next byte in string
'
	hash = hash AND 0x000000FF								' clip hash to byte
	token = 0
'
' is symbol a QBasic keyword ???
'
	FOR t = #qatoken TO #qztoken
		IF (hash == #token[t].hash) THEN
			IF (#string$[#token[t].string] == string$) THEN		' found keyword
				token = t
				EXIT FOR
			END IF
		END IF
	NEXT t
	RETURN token
END FUNCTION
'
'
' #################################
' #####  MinTypeFromGiant ()  #####
' #################################
'
FUNCTION  MinTypeFromGiant (v$$)
'
	SELECT CASE TRUE
		CASE ((v$$ >= $$MIN_USHORT) AND (v$$ <= $$MAX_USHORT))	: rt = $$USHORT
		CASE ((v$$ >= $$MIN_SSHORT) AND (v$$ <= $$MAX_SSHORT))	: rt = $$SSHORT
		CASE ((v$$ >= $$MIN_SLONG)  AND (v$$ <= $$MAX_SLONG))		: rt = $$SLONG
		CASE ELSE																								: rt = $$GIANT
	END SELECT
	RETURN (rt)
END FUNCTION
'
'
' ##################################
' #####  MinTypeFromDouble ()  #####
' ##################################
'
FUNCTION  MinTypeFromDouble (value#)
'
	IF (value# < 0) THEN value# = -value#
	minSingleExponent# = 0s00800000
	maxSingleExponent# = 0s7F000000
	IF (value# < minSingleExponent#) THEN RETURN ($$TYPE_DOUBLE)
	IF (value# > maxSingleExponent#) THEN RETURN ($$TYPE_DOUBLE)
	svalue! = value#
	dvalue# = svalue!
	IF (value# == dvalue#) THEN RETURN ($$TYPE_SINGLE)
	RETURN ($$TYPE_DOUBLE)
END FUNCTION
'
'
' ###########################
' #####  AddKeyword ()  #####
' ###########################
'
FUNCTION  AddKeyword (translate, function, scope, kind, type, atype1, atype2, atype3, string$)
'
	ntoken = 0																' 0 means failure
	IFZ string$ THEN RETURN ntoken						' empty string is no keyword
'
	IF (kind AND $$KIND_QBASIC) THEN qbasic = $$TRUE ELSE qbasic = $$FALSE
	IF (kind AND $$KIND_XBASIC) THEN xbasic = $$TRUE ELSE xbasic = $$FALSE
'
	length = LEN (string$)										' length of string
	upper = length - 1												' upper bound
	hash = 0																	' initialize
'
	FOR i = 0 TO upper												' for all bytes in string
		hash = hash + #hx[string${i}]						' add hash for that byte
	NEXT i																		' next byte in string
'
	hash = hash AND 0x000000FF								' clip hash to byte
	hashtoken = #hash[hash]										' see if any tokens with this hash exist yet
	INC #nstring															' store string in next string-number
	INC #ntoken																' store token in next token-number
'
	SELECT CASE #pass
		CASE 1	: GOSUB PassOne									' establish token and string
		CASE 2	: GOSUB PassTwo									' add translate token and string
	END SELECT
	RETURN ntoken															'
'
'
' *********************
' *****  PassOne  *****  update hash-links in tokens
' *********************
'
SUB PassOne
	IFZ hashtoken THEN												' first string with this hash value
		#hash[hash] = #ntoken										' remember first token with this hash
		hashback = #ntoken											' this is also the last string with this hash
		hashnext = 0														' no more strings with this hash value yet
	ELSE																			'
		last = #token[hashtoken].hashback				' last contains last entry with this hash
		next = #token[hashtoken].hashnext				' next contains second entry with this hash
		IF #token[last].hashnext THEN STOP			' error if last token already points forward
		#token[hashtoken].hashback = #ntoken		' point first token with this hash at this one
		#token[last].hashnext = #ntoken					' last token with this hash becomes next-to-last
		hashback = last													' previous token with this hash value
		hashnext = 0														' last token with this hash value
	END IF
'
' add token information and symbol string
'
	#string$[#nstring] = string$							' add new symbol to string table
'
	#token[#ntoken].translate = translate			' token in other language - QBasic or XBasic
	#token[#ntoken].function = function				' function this token is defined in
	#token[#ntoken].string = #nstring					' string that contains this symbol
	#token[#ntoken].length = length						' length of this token symbol
	#token[#ntoken].token = #ntoken						' token number of this token
	#token[#ntoken].scope = scope							' scope of token
	#token[#ntoken].kind = kind								' kind of token
	#token[#ntoken].type = type								' type of token
	#token[#ntoken].hash = hash								' hash of token
	#token[#ntoken].hashback = hashback				' previous token with this hash
	#token[#ntoken].hashnext = hashnext				' next token with this hash
	#token[#ntoken].akind[0] = 0							' kind of argument 0
	#token[#ntoken].akind[1] = 0							' kind of argument 1
	#token[#ntoken].akind[2] = 0							' kind of argument 2
	#token[#ntoken].atype[0] = atype1					' type of argument 0
	#token[#ntoken].atype[1] = atype2					' type of argument 1
	#token[#ntoken].atype[2] = atype3					' type of argument 2
	#token[#ntoken].first = 0									'
	#token[#ntoken].final = 0									'
	#token[#ntoken].ivalue = 0$$							'
	#token[#ntoken].fvalue = 0.00#						'
	ntoken = #ntoken
END SUB
'
'
' *********************
' *****  PassTwo  *****  update hash-links in tokens
' *********************
'
SUB PassTwo
	IF (#string$[#token[#ntoken].string] != string$) THEN PRINT "#####  disaster  #####" : EXIT SUB
	IF (#token[#ntoken].function != function) THEN PRINT "#####  disaster  #####" : EXIT SUB
	IF (#token[#ntoken].length != length) THEN PRINT "#####  disaster  #####" : EXIT SUB
	IF (#token[#ntoken].token != #ntoken) THEN PRINT "#####  disaster  #####" : EXIT SUB
	IF (#token[#ntoken].scope != scope) THEN PRINT "#####  disaster  #####" : EXIT SUB
	IF (#token[#ntoken].kind != kind) THEN PRINT "#####  disaster  #####" : EXIT SUB
	IF (#token[#ntoken].type != type) THEN PRINT "#####  disaster  #####" : EXIT SUB
'
	#token[#ntoken].translate = translate
	ntoken = #ntoken
END SUB
END FUNCTION
'
'
' ##########################
' #####  FindToken ()  #####
' ##########################
'
FUNCTION  FindToken (@match[], function, scope, kind, type, atype1, atype2, atype3, string$)
'
	ntoken = 0																' token not found
	DIM match[]																' no matches found yet
	IFZ string$ THEN RETURN ntoken						' empty symbol is no symbol
'
	IF (kind AND $$KIND_QBASIC) THEN qbasic = $$TRUE ELSE qbasic = $$FALSE
	IF (kind AND $$KIND_XBASIC) THEN xbasic = $$TRUE ELSE xbasic = $$FALSE
'
	length = LEN (string$)										' length of string in bytes
	upper = length - 1												' upper bound of string
	hash = 0																	' initialize hash
'
	FOR i = 0 TO upper												' for all bytes in string
		hash = hash + #hx[string${i}]						' add hash for that byte
	NEXT i
'
	hash = hash AND 0x000000FF								' clip hash to byte value
'
	ntoken = #hash[hash]											' first entry with this hash
	IFZ ntoken THEN RETURN $$FALSE						' no symbol with this hash
'
' check all symbols with this hash for a match
'
'
	nmatch = 0																' number of matches
	umatch = 15																' maximum match number
	DIM match[umatch]													' upper bound of match[]
'
	DO
		symbol = #token[ntoken].string										' entry in string table
		IF (symbol$ == #string$[string]) THEN							' symbols match
			IF (function == #token[ntoken].function) THEN		' functions match
				IF (nmatch > umatch) THEN											' make more room
					umatch = umatch + 16												' 16 more now
					REDIM match[umatch]													' make room
				END IF																				'
				match[nmatch] = ntoken												' return the token
				INC nmatch																		' next match number
			END IF																					'
		END IF
		ntoken = #token[ntoken].hashnext									' next token with same hash
	LOOP WHILE ntoken																		' no more tokens with this hash
END FUNCTION
'
'
' #########################
' #####  AddToken ()  #####
' #########################
'
FUNCTION  AddToken (@token, function, scope, kind, type, atype1, atype2, atype3, string$)
'
	ntoken = 0																' token not added
	IFZ string$ THEN RETURN ntoken						' empty string is no symbol
'
	IF (kind AND $$KIND_QBASIC) THEN qbasic = $$TRUE ELSE qbasic = $$FALSE
	IF (kind AND $$KIND_XBASIC) THEN xbasic = $$TRUE ELSE xbasic = $$FALSE
'
	length = LEN (string$)										' length of string in bytes
	upper = length - 1												' upper bound of string
	hash = 0																	' initialize hash
'
	FOR i = 0 TO upper												' for all bytes in string
		hash = hash + #hx[string${i}]						' add hash for that byte
	NEXT i																		' next byte in string
'
	hash = hash AND 0x000000FF								' clip hash to byte
	hashtoken = #hash[hash]										' see if any tokens with this hash exist yet
	ntoken = 0																' no token yet
'
' If no token has this hash, this must be a new token, and
' therefore this token is definitely added to symbol-table.
'
	IFZ hashtoken THEN GOSUB NewHash
	IF ntoken THEN RETURN ntoken
'
' If token already exists, return the existing token
'
	GOSUB FindToken
	IF ntoken THEN RETURN ntoken
'
' otherwise create and return a new token
'
	GOSUB AddToken
	RETURN ntoken
'
'
' *********************
' *****  NewHash  *****  token must be new because hash-value is zero
' *********************
'
SUB NewHash
	ntoken = 0
	INC #ntoken															' store token in next token-number
	INC #nstring														' store string in next string-number
	#hash[hash] = #ntoken										' remember base-token with this hash
	#token[#ntoken].hashback = #ntoken			' this is also the last string with this hash
	#token[#ntoken].hashnext = #ntoken			' this is also the next string with this hash
'
	#token[#ntoken].hash = hash							'
	#token[#ntoken].kind = kind							'
	#token[#ntoken].type = type							'
	#token[#ntoken].scope = scope						'
	#token[#ntoken].token = #ntoken					'
	#token[#ntoken].length = length					'
	#token[#ntoken].string = #nstring				'
	#token[#ntoken].function = function			'
	#token[#ntoken].atype[1] = atype1				'
	#token[#ntoken].atype[2] = atype2				'
	#token[#ntoken].atype[3] = atype3				'
	#string$[#nstring] = string$						'
	ntoken = #ntoken												' return token number of this new token
	token = ntoken
END SUB
'
'
' ***********************
' *****  FindToken  *****
' ***********************
'
SUB FindToken
	ntoken = 0
	last = #token[hashtoken].hashback				' last contains last entry with this hash
	next = #token[hashtoken].hashnext				' next contains second entry with this hash
	token = last														' start with last token with this hash value
'
	DO
		IF (kind == #token[token].kind) THEN
			IF (hash == #token[token].hash) THEN
				IF (scope == #token[token].scope) THEN
					IF (length == #token[token].length) THEN
						IF (string$ == #string$[#token[token].string]) THEN			' found token
							ntoken = token
							EXIT DO
						END IF
					END IF
				END IF
			END IF
		END IF
		IF (token == hashtoken) THEN EXIT DO	' no more tokens with this hash value
		token = #token[token].hashback				' next token to test
	LOOP
END SUB
'
'
' **********************
' *****  AddToken  *****
' **********************
'
SUB AddToken
	ntoken = 0															' new token not added yet
	INC #ntoken															' store token in next token-number
	INC #nstring														' store string in next string-number
	last = #token[hashtoken].hashback				' last contains last entry with this hash
'
	#token[#ntoken].hashback = last					' new last-entry points back to old last-entry
	#token[#ntoken].hashnext = hashtoken		' new last-entry points back at first-entry
	#token[last].hashnext = #ntoken					' old last-entry points next to new last-entry
	#token[hashtoken].hashback = #ntoken		' the base-entry points back at new last-entry
'
	#hash[hash] = #ntoken										' remember first token with this hash
	#token[#ntoken].hash = hash							'
	#token[#ntoken].kind = kind							'
	#token[#ntoken].type = type							'
	#token[#ntoken].scope = scope						'
	#token[#ntoken].token = #ntoken					'
	#token[#ntoken].length = length					'
	#token[#ntoken].string = #nstring				'
	#token[#ntoken].function = function			'
	#token[#ntoken].atype[1] = atype1				'
	#token[#ntoken].atype[2] = atype2				'
	#token[#ntoken].atype[3] = atype3				'
	#string$[#nstring] = string$						'
	ntoken = #ntoken												' return token number of this new token
	token = ntoken
END SUB
END FUNCTION
'
'
' #############################
' #####  OutputXBasic ()  #####
' #############################
'
FUNCTION  OutputXBasic (text$[])

	IFZ text$[] THEN RETURN
	upper = UBOUND (text$[])
	lines = upper + 1
'
	new = #xline + lines
'
	IF (new > (#xuline - 256)) THEN
		#xuline = #xuline + 1024
		REDIM #xbasic$[#xuline]
	END IF
'
	FOR i = 0 TO upper
		#xbasic$[#xline] = text$[i]
		INC #xline
	NEXT i
END FUNCTION
'
'
' ################################
' #####  TokenRestOfLine ()  #####
' ################################
'
FUNCTION  TokenRestOfLine ()
'
' xxxxx
'
END FUNCTION
'
'
' ############################
' #####  PrintTokens ()  #####
' ############################
'
FUNCTION  PrintTokens ()
'
	FOR i = 0 TO #ntoken+1
		IFZ (i AND 0x000F) THEN PRINT " tok# trantok# hash back next func     kind datatype scope    integer-value length  symbol-string    translate-symbol"
		PRINT " ";
		PRINT HEX$(#token[i].token,4);;
		PRINT HEX$(#token[i].translate,8);;
		PRINT HEX$(#token[i].hash,4);;
		PRINT HEX$(#token[i].hashback,4);;
		PRINT HEX$(#token[i].hashnext,4);;
		PRINT HEX$(#token[i].function,4);;
		PRINT HEX$(#token[i].kind,8);;
		PRINT HEX$(#token[i].type,8);;
		PRINT HEX$(#token[i].scope,5);;
		PRINT HEX$(#token[i].ivalue,16);;
'		PRINT HEX$(#token[i].fvalue,16);;
		PRINT HEX$(#token[i].length,6);;;
		PRINT FORMAT$("<<<<<<<<<<<<<<<<", #string$[#token[i].string]);;
'
		translate = #token[i].translate
		IF translate THEN PRINT #string$[#token[translate].string] ELSE PRINT
	NEXT i
END FUNCTION
'
'
' ##########################
' #####  PrintHash ()  #####
' ##########################
'
FUNCTION  PrintHash ()
'
	FOR i = 0 TO 255
		PRINT HEX$(i,2); " : ";
		n = #hash[i]
		DO WHILE n
			PRINT HEX$(n,4);;
			n = #token[n].hashnext
		LOOP
		PRINT
	NEXT i
END FUNCTION
'
'
' ##########################
' #####  Terminate ()  #####
' ##########################
'
FUNCTION  Terminate ()
'
' xxxxx
'
END FUNCTION
END PROGRAM

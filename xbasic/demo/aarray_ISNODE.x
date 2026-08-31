'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aarray_ISNODE"
VERSION	"0.0000"
'
IMPORT	"xst"
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  PrintArray (ANY array[])
DECLARE FUNCTION  TypeNumberToName (type, type$)
DECLARE FUNCTION  TestThree ()

$$HIGHER_DIMENSION = 0x20000000
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'	UBYTE  array[]
'	UBYTE  data[]
	USHORT  array[]
	USHORT  data[]
'
	XstClearConsole()
	GOSUB TestOne
	GOSUB TestTwo
	TestThree ()
	RETURN
'
'
' *****  TestOne  *****
'
SUB TestOne
	PRINT
	PRINT "######################"
	PRINT "#####  test one  #####"
	PRINT "######################"
	DIM array$[3]
	array$[0] = "zero"
	array$[1] = "one"
	array$[2] = "two"
	array$[3] = "three"
	PrintArray (@array$[])
END SUB
'
'
' *****  TestTwo  *****
'
SUB TestTwo
	PRINT
	PRINT "######################"
	PRINT "#####  test two  #####"
	PRINT "######################"
'
	DIM array[3,2,]
'	DIM array[2,]								' create upper dimension of 2D array
'
	DIM data[0]									' create array with 1 USHORT element
	data[0] = 10
	ATTACH data[] TO array[1,0,]	' attach 1 element array to array[0,]
'
	DIM data[2]									' create array with 3 USHORT elements
	data[0] = 20
	data[1] = 21
	data[2] = 22
	ATTACH data[] TO array[1,1,]	' attach 3 element array to array[1,]
'
	DIM data[7]									' create array with 8 USHORT elements
	data[0] = 30
	data[1] = 31
	data[2] = 32
	data[3] = 33
	data[4] = 34
	data[5] = 35
	data[6] = 36
	data[7] = 37
	ATTACH data[] TO array[1,2,]	' attach 8 element array to array[2,]
'
' pass array to function
'
	PrintArray (@array[])				' pass 2D array to function PrintArray()
END SUB
END FUNCTION
'
'
' ###########################
' #####  PrintArray ()  #####
' ###########################
'
FUNCTION  PrintArray (array[])
	STATIC  dimension
	SBYTE sbyte[]
	UBYTE ubyte[]
	SSHORT sshort[]
	USHORT ushort[]
	SLONG slong[]
	ULONG ulong[]
	XLONG xlong[]
	SHARED iShared$
'
	IFZ array[] THEN
		PRINT SPACE$(30); iShared$; "] = "; "EMPTY"
		RETURN
	END IF
'
	type = TYPE (array[])
	IF ((type < $$SBYTE) OR (type > $$DCOMPLEX)) THEN RETURN		' not handled
'
' next dimension (increase from left to right)
'
	IFZ dimension THEN
		iShared$ = "array["
	END IF
	INC dimension
'
' print header of this array
'
	PRINT
	PRINT "########  dimension = "; dimension
	higher = $$FALSE
	isnode = ISNODE (array[])
	reason$ = " ::: this lowest dimension holds data"
	IF isnode THEN reason$ = " ::: this is a higher dimension"
'
' print datatype of this array
'
	TypeNumberToName (type, @type$)
	PRINT "the datatype of this array = "; type$; reason$
'
' process higher dimensions
'
	iLocal$ = iShared$
	IF isnode THEN
		upper = UBOUND (array[])
'		PRINT "upper bound of this dimension = "; upper
		PRINT "upper bound of this dimension "; iShared$; "] = "; upper
		FOR i = 0 TO upper
			ATTACH array[i,] TO temp[]
			iShared$ = iLocal$ +STRING$(i) + ","
			PrintArray (@temp[])
			ATTACH temp[] TO array[i,]
		NEXT i
		DEC dimension
		iShared$ = iLoacal$
		RETURN
	END IF
'
' process lowest = data dimension
'
	upper = UBOUND (array[])
	upper$ = STRING$(upper)
	length = LEN(upper$)
'
'
' process each datatype separately
'
	SELECT CASE type
		CASE  $$SBYTE			: GOSUB sbyte
		CASE  $$UBYTE			: GOSUB ubyte
		CASE  $$SSHORT		: GOSUB sshort
		CASE  $$USHORT		: GOSUB ushort
'		CASE  $$SLONG			: GOSUB slong
'		CASE  $$ULONG			: GOSUB ulong
'		CASE  $$XLONG			: GOSUB xlong
'		CASE  $$GOADDR		: GOSUB goaddr
'		CASE  $$SUBADDR		: GOSUB subaddr
'		CASE  $$FUNCADDR	: GOSUB funcaddr
'		CASE  $$GIANT			: GOSUB giant
'		CASE  $$SINGLE		: GOSUB single
'		CASE  $$DOUBLE		: GOSUB double
		CASE  $$STRING		: GOSUB string
'		CASE  $$SCOMPLEX	: GOSUB scomplex
'		CASE  $$DCOMPLEX	: GOSUB dcomplex
	END SELECT
	DEC dimension
	RETURN
'
'
' *****  sbyte  *****
'
SUB sbyte
	PRINT "sbyte"
END SUB
'
'
' *****  ubyte  *****
'
SUB ubyte
	ATTACH array[] TO ubyte[]
'
	FOR i = 0 TO upper
		PRINT SPACE$(22); " ubyte "; iLocal$; STRING$(i); "] = "; STRING$(ubyte[i])
	NEXT i
'
	ATTACH ubyte[] TO array[]
END SUB
'
'
' *****  sshort  *****
'
SUB sshort
	PRINT "sshort"
END SUB
'
'
' *****  ushort  *****
'
SUB ushort
	ATTACH array[] TO ushort[]
'
	FOR i = 0 TO upper
		PRINT SPACE$(22); " ushort "; iLocal$; STRING$(i); "] = "; STRING$(ushort[i])
	NEXT i
'
	ATTACH ushort[] TO array[]
END SUB
'
'
' *****  string  *****
'
SUB string
	ATTACH array[] TO string$[]
'
	FOR i = 0 TO upper
		PRINT SPACE$(21); " string$ "; iLocal$; STRING$(i); "] = "; "\"";string$[i];"\""
	NEXT i
'
	ATTACH string$[] TO array[]
END SUB

END FUNCTION
'
'
' #################################
' #####  TypeNumberToName ()  #####
' #################################
'
FUNCTION  TypeNumberToName (type, type$)
'
	type$ = ""
'
	SELECT CASE type
		CASE  0						: type$ = "NONE"
		CASE  1						: type$ = "VOID"
		CASE  $$SBYTE			: type$ = "SBYTE"
		CASE  $$UBYTE			: type$ = "UBYTE"
		CASE  $$SSHORT		: type$ = "SSHORT"
		CASE  $$USHORT		: type$ = "USHORT"
		CASE  $$SLONG			: type$ = "SLONG"
		CASE  $$ULONG			: type$ = "ULONG"
		CASE  $$XLONG			: type$ = "XLONG"
		CASE  $$GOADDR		: type$ = "GOADDR"
		CASE  $$SUBADDR		: type$ = "SUBADDR"
		CASE  $$FUNCADDR	: type$ = "FUNCADDR"
		CASE  $$GIANT			: type$ = "GIANT"
		CASE  $$SINGLE		: type$ = "SINGLE"
		CASE  $$DOUBLE		: type$ = "DOUBLE"
		CASE  $$STRING		: type$ = "STRING"
		CASE  $$SCOMPLEX	: type$ = "SCOMPLEX"
		CASE  $$DCOMPLEX	: type$ = "DCOMPLEX"
	END SELECT
END FUNCTION
'
'
' ##########################
' #####  TestThree ()  #####
' ##########################
'
FUNCTION  TestThree ()
UBYTE  ubyte[]
USHORT ushort[]

	PRINT
	PRINT "########################"
	PRINT "#####  test three  #####"
	PRINT "########################"

	DIM s$[1,0]
	s$[0,0] = "abc"
	s$[1,0] = "def"

	DIM ubyte[3]
	ubyte[0] = 32
	ubyte[1] = 33
	ubyte[2] = 34
	ubyte[3] = 35

	DIM ushort[2]
	ushort[0] = 63000
	ushort[1] = 64000
	ushort[2] = 65000

	DIM array[2,]

	ATTACH s$[] TO xtemp[]
	ATTACH xtemp[] TO array[0,]
	ATTACH ubyte[] TO xtemp[]
	ATTACH xtemp[] TO array[1,]
	ATTACH ushort[] TO xtemp[]
	ATTACH xtemp[] TO array[2,]

	file$ = "array.xbar"
	error = XstSaveArray (file$, @array[])
	IF error THEN
		PRINT "Error saving file", file$, ERROR$(error)
		STOP
	END IF

	PrintArray (@array[])

	DIM array[]
	error = XstLoadArray (file$, @array[])
	IF error THEN
		STOP
	END IF

	ATTACH array[0,] TO xtemp[]
	ATTACH xtemp[] TO s$[]
	ATTACH array[1,] TO xtemp[]
	ATTACH xtemp[] TO ubyte[]
	ATTACH array[2,] TO xtemp[]
	ATTACH xtemp[] TO ushort[]

END FUNCTION
END PROGRAM

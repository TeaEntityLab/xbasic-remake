'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aarray"
VERSION	"0.0000"
'
IMPORT	"xst"
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  PrintArray (ANY array[])
DECLARE FUNCTION  TypeNumberToName (type, type$)

$$HIGHER_DIMENSION = 0x20000000
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	USHORT  array[]
	USHORT  data[]
'
	XstClearConsole()
	GOSUB TestOne
	GOSUB TestTwo
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
'
	IFZ array[] THEN RETURN
'
	type = TYPE (array[])
	IF ((type < $$SBYTE) OR (type > $$DCOMPLEX)) THEN RETURN		' not handled
'
' next dimension (increase from left to right)
'
	INC dimension
'
' print header of this array
'
	PRINT
	PRINT "########  dimension = "; dimension
	higher = $$FALSE
	address = &array[]
	GOSUB PrintArrayHeader
	reason$ = " ::: this lowest dimension holds data"
	IF (infowd AND $$HIGHER_DIMENSION) THEN reason$ = " ::: because this higher dimension holds addresses"
'
' print datatype of this array
'
	TypeNumberToName (type, @type$)
	PRINT "the datatype of this array = "; type$; reason$
'
' process higher dimensions
'
	IF (infowd AND $$HIGHER_DIMENSION) THEN
		upper = UBOUND (array[])
		PRINT "upper bound of this dimension = "; upper
		FOR i = 0 TO upper
			ATTACH array[i,] TO temp[]
			PrintArray (@temp[])
			ATTACH temp[] TO array[i,]
		NEXT i
		DEC dimension
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
	PRINT "ubyte"
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
		PRINT " ushort [ ... "; RJUST$(STRING$(i),length); " ] = "; STRING$(ushort[i])
	NEXT i
END SUB
'
'
' *****  string  *****
'
SUB string
	ATTACH array[] TO string$[]
'
	FOR i = 0 TO upper
		PRINT " string$ [ ... "; RJUST$(STRING$(i),length); " ] = "; string$[i]
	NEXT i
END SUB

'
'
' *****  PrintArrayHeader  *****
'
SUB PrintArrayHeader
	size = XLONGAT(address-0x10)
	infowd = ULONGAT(address-0x08)
	xbflag = ULONGAT(address-0x4)
	IF (infowd AND $$HIGHER_DIMENSION) THEN header$ = " = higher dimension" ELSE header$ = " = lowest dimension = data"
	PRINT HEX$(xbflag,8);; HEX$(size,16);; HEX$(infowd,8);; header$
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
END PROGRAM

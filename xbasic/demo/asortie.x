'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"asortie"
VERSION	"0.0001"
'
IMPORT	"xst"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	DIM sdas$[14]
	DIM sdai$[14]
	DIM sdns$[14]
	DIM sdni$[14]
	DIM sias$[14]
	DIM siai$[14]
	DIM sins$[14]
	DIM sini$[14]
'
	GOSUB Initialize
	flag = $$SortDecreasing
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		sdas$[i] = field3$[i]
	NEXT i
'
	GOSUB Initialize
	flag = $$SortDecreasing OR $$SortCaseInsensitive
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		sdai$[i] = field3$[i]
	NEXT i
'
	GOSUB Initialize
	flag = $$SortDecreasing OR $$SortAlphaNumeric
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		sdns$[i] = field3$[i]
	NEXT i
'
	GOSUB Initialize
	flag = $$SortDecreasing OR $$SortCaseInsensitive OR $$SortAlphaNumeric
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		sdni$[i] = field3$[i]
	NEXT i
'
	GOSUB Initialize
	flag = $$SortIncreasing
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		sias$[i] = field3$[i]
'		PRINT sias$[i]
	NEXT i
'
	GOSUB Initialize
	flag = $$SortCaseInsensitive
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		siai$[i] = field3$[i]
	NEXT i
'
	GOSUB Initialize
	flag = $$SortAlphaNumeric
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		sins$[i] = field3$[i]
	NEXT i
'
	GOSUB Initialize
	flag = $$SortCaseInsensitive OR $$SortAlphaNumeric
	XstQuickSort (@field3$[], @orderArray[], 0, UBOUND(field3$[]), flag)
	FOR i = 0 TO UBOUND(field3$[])
		sini$[i] = field3$[i]
	NEXT i
'
' print the results
'
	PRINT
	PRINT "Decreasing       Decreasing       Decreasing       Decreasing"
	PRINT "Alphabetic       Alphabetic       AlphaNumeric     AlphaNumeric"
	PRINT "CaseSensitive    CaseInsensitive  CaseSensitive    CaseInsensitive"
	PRINT "=================================================================="
	FOR i = 0 TO UBOUND(field3$[])
		PRINT										FORMAT$ ("<<<<", sdas$[i]);
		PRINT "             " + FORMAT$ ("<<<<", sdai$[i]);
		PRINT "             " + FORMAT$ ("<<<<", sdns$[i]);
		PRINT "             " + FORMAT$ ("<<<<", sdni$[i])
	NEXT i
	PRINT
	PRINT "Increasing       Increasing       Increasing       Increasing"
	PRINT "Alphabetic       Alphabetic       AlphaNumeric     AlphaNumeric"
	PRINT "CaseSensitive    CaseInsensitive  CaseSensitive    CaseInsensitive"
	PRINT "=================================================================="
	FOR i = 0 TO UBOUND(field3$[])
		PRINT										FORMAT$ ("<<<<", sias$[i]);
		PRINT "             " + FORMAT$ ("<<<<", siai$[i]);
		PRINT "             " + FORMAT$ ("<<<<", sins$[i]);
		PRINT "             " + FORMAT$ ("<<<<", sini$[i])
	NEXT i
	RETURN
'
'
' *****  Initialize  *****
'
SUB Initialize
	DIM field3$[14]
	field3$[0] = "a"
	field3$[1] = "aaaa"
	field3$[2] = "aAaa"
	field3$[3] = "Aaaa"
	field3$[4] = "AAAA"
	field3$[5] = "a3bb"
	field3$[6] = "a11c"
	field3$[7] = "1aaa"
	field3$[8] = "2aaa"
	field3$[9] = "1"
	field3$[10]= "2"
	field3$[11]= "baaa"
	field3$[12]= "Baaa"
	field3$[13]= "bbaa"
	field3$[14]= "baaB"
END SUB
END FUNCTION
END PROGRAM

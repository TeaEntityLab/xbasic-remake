'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"afile"
VERSION	"0.0000"
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
' how to open and close files
'
	ifile$ = "new.hlp"			' raw text file
	lfile$ = "lower.txt"		' lower case file
	ufile$ = "upper.txt"		' upper case file
'
	ifile = OPEN (ifile$, $$RD)		' raw text file
	lfile = OPEN (lfile$, $$WR)		' lower case file
	ufile = OPEN (ufile$, $$WR)		' upper case file
'
	IF (ifile < 3) THEN GOSUB Error : RETURN		' report error
	IF (lfile < 3) THEN GOSUB Error : RETURN		' report error
	IF (ufile < 3) THEN GOSUB Error : RETURN		' report error
'
	lof = LOF (ifile)
'
	raw$ = NULL$ (lof)				' hold raw text
	lower$ = NULL$ (lof)			' hold lower case text
	upper$ = NULL$ (lof)			' hold upper case text
	READ [ifile], raw$				' read raw text
'
	delta = 'a' - 'A'					' difference between upper & lower case
	bytes = LEN (raw$)				' bytes in text
'
	FOR offset = 0 TO bytes-1
		raw = raw${offset}
		IF ((raw >= 'A') AND (raw <= 'Z')) THEN lower${offset} = raw + delta ELSE lower${offset} = raw
		IF ((raw >= 'a') AND (raw <= 'z')) THEN upper${offset} = raw - delta ELSE upper${offset} = raw
	NEXT offset
'
' write the lower-case and upper-case files - different ways for illustration
'
	WRITE [lfile], lower$			' the easy way
'
	FOR offset = 0 TO bytes-1
		byte@@ = upper${offset}	' get one byte
		WRITE [ufile], byte@@		' write one byte
	NEXT offset
'
' close all the files
'
	CLOSE (ifile)
	CLOSE (lfile)
	CLOSE (ufile)
'
' now do the same thing with standard library convenience functions
'
	raw$ = ""
	lower$ = ""
	upper$ = ""
'
	XstLoadString (ifile$, @raw$)
	lower$ = LCASE$(raw$)
	upper$ = UCASE$(raw$)
	XstSaveString ("lower.too", @lower$)
	XstSaveString ("upper.too", @upper$)
	RETURN
'
'
'
' *****  Error  *****
'
SUB Error
	error = ERROR (0)
	XstErrorNumberToName (error, @error$)
	PRINT "error #"; error; "  = "; error$
	IF (ifile > 3) THEN CLOSE (ifile)
	IF (lfile > 3) THEN CLOSE (lfile)
	IF (ufile > 3) THEN CLOSE (ufile)
END SUB
END FUNCTION
END PROGRAM

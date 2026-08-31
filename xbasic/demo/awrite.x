'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"awrite"
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

	filename$ = "test.lab"
	ofile = OPEN (filename$, $$WRNEW)
	IF (ofile < 3) THEN RETURN
'
	empty$ = ""
	eof = EOF (ofile)
	SEEK (ofile, eof)
	write$ = "lab.test"
'
	WRITE [ofile], write$
	WRITE [ofile], empty$
	WRITE [ofile], filename$
	CLOSE (ofile)
'
	ifile = OPEN (filename$, $$RD)
	IF (ifile < 3) THEN RETURN
'
	length1 = LEN (write$)
	length2 = LEN (filename$)
	read1$ = NULL$ (length1)
	read2$ = NULL$ (length2)
'
	READ [ifile], read1$
	READ [ifile], empty$
	READ [ifile], read2$
	CLOSE (ifile)
'
	PRINT "<"; read1$; ">"
	PRINT "<"; empty$; ">"
	PRINT "<"; read2$; ">"
END FUNCTION
END PROGRAM

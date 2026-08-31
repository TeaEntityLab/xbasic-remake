'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"astring"
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
	ofile$ = "astring.dat"
	one$ = "string number one"
	two$ = "string number two here"
	zero$ = ""
	none$ = ""
	nada$ = ""
'
	ofile = OPEN (ofile$, $$WR)
	IF (ofile < 3) THEN RETURN ($$TRUE)
'
	error01 = XstWriteString (ofile, @ofile$)
	error02 = XstWriteString (ofile, @zero$)
	error03 = XstWriteString (ofile, @none$)
	error04 = XstWriteString (ofile, @one$)
	error05 = XstWriteString (ofile, @nada$)
	error06 = XstWriteString (ofile, @two$)
	CLOSE (ofile)
'
	ifile$ = ofile$
	ifile = OPEN (ifile$, $$RD)
	IF (ifile < 3) THEN RETURN ($$TRUE)
	length = LOF (ifile)
'
	a$ = ""
	b$ = ""
	c$ = ""
	d$ = ""
	e$ = ""
	f$ = ""
	error07 = XstReadString (ifile, @a$)
	error08 = XstReadString (ifile, @b$)
	error09 = XstReadString (ifile, @c$)
	error10 = XstReadString (ifile, @d$)
	error11 = XstReadString (ifile, @e$)
	error12 = XstReadString (ifile, @f$)
	CLOSE (ifile)
'
	PRINT error01;; error02;; error03;; error04;; error05;; error06;; length
	PRINT error07;; error08;; error09;; error10;; error11;; error12;; length
'
	PRINT "<"; ofile$; "> : <"; a$; ">"; " :"; LEN(a$)
	PRINT "<"; zero$; "> : <"; b$; ">"; " :"; LEN(b$)
	PRINT "<"; none$; "> : <"; c$; ">"; " :"; LEN(c$)
	PRINT "<"; one$; "> : <"; d$; ">"; " :"; LEN(d$)
	PRINT "<"; nada$; "> : <"; e$; ">"; " :"; LEN(e$)
	PRINT "<"; two$; "> : <"; f$; ">"; " :"; LEN(f$)
	RETURN ($$FALSE)
END FUNCTION
END PROGRAM

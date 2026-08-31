'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"amerge"
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
' test number one
'
	a$ = "This is a test."
	b$ = " stupid"
	c$ = XstMergeStrings$ (@a$, @b$, 10, 0)

	PRINT
	PRINT "<<<<<"
	PRINT "a$ = \""; a$; "\""
	PRINT "b$ = \""; b$; "\""
	PRINT "c$ = \""; c$; "\""
	PRINT ">>>>>"
'
' test number two
'
	c$ = XstMergeStrings$ (@a$, @b$, 15, 0)

	PRINT
	PRINT "<<<<<"
	PRINT "a$ = \""; a$; "\""
	PRINT "b$ = \""; b$; "\""
	PRINT "c$ = \""; c$; "\""
	PRINT ">>>>>"
'
' test number three
'
	b$ = " dumb"
	c$ = XstMergeStrings$ (@a$, @b$, 10, 0)

	PRINT
	PRINT "<<<<<"
	PRINT "a$ = \""; a$; "\""
	PRINT "b$ = \""; b$; "\""
	PRINT "c$ = \""; c$; "\""
	PRINT ">>>>>"
'
' test number four
'
	b$ = " dumb"
	c$ = XstMergeStrings$ (@a$, @b$, 5, 5)

	PRINT
	PRINT "<<<<<"
	PRINT "a$ = \""; a$; "\""
	PRINT "b$ = \""; b$; "\""
	PRINT "c$ = \""; c$; "\""
	PRINT ">>>>>"
'
' test number five
'
	b$ = " for fools!"
	c$ = XstMergeStrings$ (@a$, @b$, 15, 1)

	PRINT
	PRINT "<<<<<"
	PRINT "a$ = \""; a$; "\""
	PRINT "b$ = \""; b$; "\""
	PRINT "c$ = \""; c$; "\""
	PRINT ">>>>>"
'
' test number six
'
	b$ = " for fools!"
	c$ = XstMergeStrings$ (@a$, @b$, 15, 234)

	PRINT
	PRINT "<<<<<"
	PRINT "a$ = \""; a$; "\""
	PRINT "b$ = \""; b$; "\""
	PRINT "c$ = \""; c$; "\""
	PRINT ">>>>>"
END FUNCTION
END PROGRAM

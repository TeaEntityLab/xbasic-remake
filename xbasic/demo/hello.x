'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "hello"
VERSION "0.0001"
'
	IMPORT "xst"
'
DECLARE FUNCTION  Hello ()
'
'
' ######################
' #####  Hello ()  #####
' ######################
'
FUNCTION  Hello ()
'
	XstDisplayConsole ()
	PRINT "Hello Programmer"
	string$ = INLINE$("Press Enter => ")
'
END FUNCTION
END PROGRAM

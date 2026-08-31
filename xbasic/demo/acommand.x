'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"acommand"
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
	XstGetCommandLine (@command$)
	XstGetCommandLineArguments (@argc, @argv$[])
	PRINT command$
	FOR i = 0 TO argc-1
		PRINT argv$[i]
	NEXT i
	a$ = INLINE$ ("press enter to terminate ===>> ")
	PRINT a$
END FUNCTION
END PROGRAM

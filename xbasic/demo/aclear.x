'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"clear"
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
'
FUNCTION  Entry ()
'
	FOR i = 0 TO 63
		PRINT i
		IFZ (i AND 16) THEN XstClearConsole()
	NEXT i
END FUNCTION
END PROGRAM

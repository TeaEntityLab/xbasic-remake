'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "ahowdy"
VERSION "0.0001"
'
EXPORT
INTERNAL FUNCTION  Entry ()
DECLARE FUNCTION  Howdy ()
END EXPORT
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	PRINT "Hello from Entry()"
END FUNCTION
'
'
' ######################
' #####  Howdy ()  #####
' ######################
'
FUNCTION  Howdy ()
'
	PRINT "Hello from ahowdy!"
END FUNCTION
END PROGRAM

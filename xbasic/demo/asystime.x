'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "systime"
VERSION "0.0000"
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
	PRINT " begin    end    delay"
	XstGetSystemTime (@start)
	FOR i = 0 TO 100000
		XstGetSystemTime (@msec)
	NEXT i
	XstGetSystemTime (@finish)
	PRINT CJUST$(STRING$(start),8); CJUST$(STRING$(finish),8); CJUST$(STRING$(finish-start),8); "ms to call XstGetSystemTime(@msec) 100000 times"
END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"arotate"
VERSION	"0.0000"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
ULONG a
'
	a = 0b10000000000000011000000000000001
'
	PRINT
	FOR i = 0 TO 32
		r = ROTATER(a,i)																					' rotate right
		l = ROTATEL(a,i)																					' rotate left
		y = ROTATEL(a,32-i)																				' rotate right
		z = ROTATER(a,32-i)																				' rotate left
		PRINT BIN$(r,32);; BIN$(l,32);;; BIN$(y,32);; BIN$(z,32)	' print bits
	NEXT i
END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "aprofile"
VERSION "0.0001"
'
IMPORT "xst"
IMPORT "kernel32"
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  StringsToStringArray (addr, @array$[])
DECLARE FUNCTION  GetString (@addr, @string$)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	SetLastError (0)
	temp$ = NULL$ (4095)
	profile$ = NULL$ (4095)
	bytes = GetPrivateProfileStringA (0, 0, 0, &profile$, 4095, &"win.ini")
	IF (bytes < 0) THEN
		errno = GetLastError ()
		XstSystemErrorToError (errno, @error)
		XstSystemErrorNumberToName (errno, @errno$)
		XstErrorNumberToName (error, @error$)
		PRINT bytes, errno, errno$, error$
		RETURN ($$TRUE)
	END IF
	StringsToStringArray (&profile$, @profile$[])
	IFZ profile$[] THEN RETURN
'
' Print all string values of all keys in all sections
'
	PRINT
	PRINT "*************************************"
	PRINT "*****  Private Profile Strings  *****"
	PRINT "*************************************"
	PRINT
	upper = UBOUND (profile$[])
	FOR s = 0 TO upper
		section$ = profile$[s]
		PRINT "["; section$; "]"
		GetPrivateProfileStringA (&section$, 0, 0, &profile$, 4095, &"win.ini")
		StringsToStringArray (&profile$, @key$[])
		IF key$[] THEN
			u = UBOUND (key$[])
			FOR i = 0 TO u
				key$ = key$[i]
				pad = 32 - LEN (key$)
				pad = MAX (pad, 2)
				pad$ = " " + CHR$('.', pad-2) + " "
				default$ = "0"
				GetPrivateProfileStringA (&section$, &key$, 0, &temp$, 4095, &"win.ini")
				value$ = CSTRING$ (&temp$)
				PRINT "  "; key$; pad$; "\""; value$; "\""
			NEXT i
		END IF
	NEXT s
'
' Create new section "Bonkers" with key "Trashburger" equals value "Cholesterol"
'
	WritePrivateProfileStringA (&"Bonkers", &"Trashburger", &"Cholesterol", &"win.ini")
'
' Make sure "[Bonkers].Trashburger = Cholesterol" was created
'
	GetPrivateProfileStringA (&"Bonkers", &"Trashburger", 0, &temp$, 4095, &"win.ini")
	value$ = CSTRING$ (&temp$)
	PRINT "\n\nBonkers : Trashburger = "; value$
'
' Delete section "Bonkers", including all keys within it
'
	WritePrivateProfileStringA (&"Bonkers", 0, 0, &"win.ini")
'
' Confirm that section "Bonkers" no longer exists
'
	temp$ = NULL$ (4095)
	GetPrivateProfileStringA (&"Bonkers", 0, 0, &temp$, 4095, &"win.ini")
	value$ = CSTRING$ (&temp$)
	PRINT "should be empty string ===>> \""; value$; "\""
'
	temp$ = NULL$ (4095)
	GetPrivateProfileStringA (&"Bonkers", &Trashburger, 0, &temp$, 4095, &"win.ini")
	value$ = CSTRING$ (&temp$)
	PRINT "should be empty string ===>> \""; value$; "\""
	PRINT
	PRINT "******************"
	PRINT "*****  DONE  *****"
	PRINT "******************"
END FUNCTION
'
'
' #####################################
' #####  StringsToStringArray ()  #####
' #####################################
'
FUNCTION  StringsToStringArray (addr, array$[])
'
	DIM array$[]
	IFZ addr THEN RETURN		' null pointer
	byte = UBYTEAT (addr)		' first byte
	IFZ byte THEN RETURN		' no array at all
'
	i = 0
	upper = 255
	DIM array$[upper]
'
	DO
		GetString (@addr, @string$)
		IFZ string$ THEN EXIT DO
		IF (i > upper) THEN
			upper = upper + 256
			REDIM array$[upper]
		END IF
		array$[i] = string$
		INC i
	LOOP
'
	DEC i
	REDIM array$[i]
END FUNCTION
'
'
' ##########################
' #####  GetString ()  #####
' ##########################
'
FUNCTION  GetString (addr, string$)
'
	string$ = ""
	IFZ addr THEN RETURN
	byte = UBYTEAT (addr)
	IFZ byte THEN RETURN
'
	a = addr
	i = -1
	DO
		byte = UBYTEAT (a)
		INC a
		INC i
	LOOP WHILE byte
'
	IFZ i THEN INC addr : RETURN		' move past empty string
	string$ = NULL$ (i)							' make destination string
'
	FOR d = 0 TO i-1
		string${d} = UBYTEAT (addr)		' add next byte to string
		INC addr
	NEXT d
	INC addr												' move past null terminator
END FUNCTION
END PROGRAM

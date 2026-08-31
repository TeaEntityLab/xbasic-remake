'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aback"
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
	XstClearConsole()
'
	upper = 255
	DIM user[upper]
	FOR i = 0 TO upper
		SELECT CASE TRUE
			CASE (i == 0x09)	: user[i] = 0		' no backslash tab
			CASE (i == 0x0A)	: user[i] = 0		' no backslash newline
			CASE (i == 0x0D)	: user[i] = 0		' no backslash return
			CASE (i == 0x1E)	: user[i] = 0		' no backslash test == up-arrow, maybe
			CASE (i == 0x1F)	: user[i] = 0		' no backslash test == down-arrow, maybe
			CASE (i <= 0x1F)	: user[i] = 1		' do backslash codes
			CASE (i == 0x22)	: user[i] = 1		' do backslash of "
			CASE (i == 0x5C)	: user[i] = 1		' do backslash of \
			CASE (i == 0xFE)	: user[i] = 1		' do backslash test \xFE
			CASE (i == 0xFF)	: user[i] = 1		' do backslash test \xFF
			CASE ELSE					: user[i] = 0		' no backslash
		END SELECT
	NEXT i
'
	a0$ = ""
	FOR i = 0x00 TO 0x3F
		a0$ = a0$ + CHR$(i)
	NEXT i
'
	a1$ = ""
	FOR i = 0x40 TO 0x7F
		a1$ = a1$ + CHR$(i)
	NEXT i
'
	a2$ = ""
	FOR i = 0x80 TO 0xBF
		a2$ = a2$ + CHR$(i)
	NEXT i
'
	a3$ = ""
	FOR i = 0xC0 TO 0xFF
		a3$ = a3$ + CHR$(i)
	NEXT i
'
	PRINT "\n\n#####"
	PRINT "a : binary"
	PRINT "b : XstBinStringToBackString$()"
	PRINT "c : XstBinStringToBackStringNL$()"
	PRINT "d : XstBinStringToBackStringThese$()";
'
	PRINT "\n\n#####  0x00 to 0x3F  #####";
	b$ = a0$ : p$ = "a : " : GOSUB Print
	b$ = XstBinStringToBackString$ (@a0$) : p$ = "b : " : GOSUB Print
	b$ = XstBinStringToBackStringNL$ (@a0$) : p$ = "c : " : GOSUB Print
	b$ = XstBinStringToBackStringThese$ (@a0$, @user[]) : p$ = "d : " : GOSUB Print
'
	PRINT "\n\n#####  0x40 to 0x7F  #####";
	b$ = a1$ : p$ = "a : " : GOSUB Print
	b$ = XstBinStringToBackString$ (@a1$) : p$ = "b : " : GOSUB Print
	b$ = XstBinStringToBackStringNL$ (@a1$) : p$ = "c : " : GOSUB Print
	b$ = XstBinStringToBackStringThese$ (@a1$, @user[]) : p$ = "d : " : GOSUB Print
'
	PRINT "\n\n#####  0x80 to 0xBF  #####";
	b$ = a2$ : p$ = "a : " : GOSUB Print
	b$ = XstBinStringToBackString$ (@a2$) : p$ = "b : " : GOSUB Print
	b$ = XstBinStringToBackStringNL$ (@a2$) : p$ = "c : " : GOSUB Print
	b$ = XstBinStringToBackStringThese$ (@a2$, @user[]) : p$ = "d : " : GOSUB Print
'
	PRINT "\n\n#####  0xC0 to 0xFF  #####";
	b$ = a3$ : p$ = "a : " : GOSUB Print
	b$ = XstBinStringToBackString$ (@a3$) : p$ = "b : " : GOSUB Print
	b$ = XstBinStringToBackStringNL$ (@a3$) : p$ = "c : " : GOSUB Print
	b$ = XstBinStringToBackStringThese$ (@a3$, @user[]) : p$ = "d : " : GOSUB Print
	PRINT
	RETURN
'
'
' *****  Print  *****
'
SUB Print
	PRINT
	PRINT p$;
	upper = UBOUND (b$)
	FOR i = 0 TO upper
		c = b${i}
		IF (c = 0x0A) THEN c = 'n'
		PRINT CHR$(c);
	NEXT i
END SUB
END FUNCTION
END PROGRAM

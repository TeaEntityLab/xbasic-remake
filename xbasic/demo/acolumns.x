'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"acolumns"
VERSION	"0.0001"
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
	number = 1234
	string$ = "text"
'
	PRINT "-----------"
	result$ = FORMAT$ ("<<<<<<<<<<<", string$)		: PRINT result$		' left
	result$ = FORMAT$ ("|||||||||||", string$)		: PRINT result$		' center
	result$ = FORMAT$ (">>>>>>>>>>>", string$)		: PRINT result$		' right
	PRINT "-----------"
'
	width = 11
	result$ = FORMAT$ (CHR$('<',width), string$)	: PRINT result$		' left
	result$ = FORMAT$ (CHR$('|',width), string$)	: PRINT result$		' center
	result$ = FORMAT$ (CHR$('>',width), string$)	: PRINT result$		' right
	PRINT "-----------"
'
	result$ = LJUST$ (string$, width)							: PRINT result$		' left
	result$ = CJUST$ (string$, width)							: PRINT result$		' center
	result$ = RJUST$ (string$, width)							: PRINT result$		' right
	PRINT "-----------"
'
	result$ = FORMAT$ ("###########", number)			: PRINT result$		' number-right
	result$ = FORMAT$ (CHR$('#',width), number)		: PRINT result$		' number-right
	PRINT "-----------"
'
	result$ = RJUST$ (STRING$(number), width)			: PRINT result$		' number-right
	result$ = CJUST$ (STRING$(number), width)			: PRINT result$		' number-center
	result$ = LJUST$ (STRING$(number), width)			: PRINT result$		' number-left
	PRINT "-----------"
'
	width1 = 4
	width2 = 5
	width3 = 6
	width4 = 7
'
	FOR i = 1 TO 8
		number1 = i
		number2 = i * i
		number3 = i * i * i
		number4 = i * i * i * i
		name$ = "heading " + CHR$('>',i)
		PRINT RJUST$(name$,20); FORMAT$(CHR$('#',width1),number1); FORMAT$(CHR$('#',width2),number2); FORMAT$(CHR$('#',width3),number3); FORMAT$(CHR$('#',width4),number4)
	NEXT i
	PRINT "-----------"
END FUNCTION
END PROGRAM

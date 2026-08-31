'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"acharmap"
VERSION	"0.0001"
'
IMPORT	"xst"
IMPORT	"xgr"
IMPORT  "xui"
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
	DIM map[255]
	FOR i = 0 TO 255
		map[i] = i				' create character map array with 1:1 mapping = no character translation
	NEXT i
'
' install a few character translations
'
	XstGetImplementation (@implementation$)
	windows = INSTR (implementation$, "windows")
'
	IF windows THEN
		map['a'] = 0x84			' the following are interesting on my windows system
		map['e'] = 0x89
		map['i'] = 0x8C
		map['o'] = 0x94
		map['u'] = 0x81
		map['y'] = 0x98
		map['c'] = 0x87
		map['n'] = 0xA4
		map['?'] = 0xA8
		map['!'] = 0xAD
	ELSE
		map['a'] = 0xE4			' the following are interesting on my linux system
		map['e'] = 0xEB
		map['i'] = 0xEF
		map['o'] = 0xF6
		map['u'] = 0xFC
		map['y'] = 0xFF
		map['c'] = 0xE7
		map['n'] = 0xF1
		map['?'] = 0xBF
		map['!'] = 0xA1
	END IF
'
' install into console
'
	XstGetConsoleGrid (@grid)
'
' make a test string with all 256 characters (except newline = space)
'
	offset = 0
	test$ = NULL$ (264)
	FOR i = 0 TO 255
		IF (i = 10) THEN
			test${i+o} = ' '
		ELSE
			test${i+o} = i
		END IF
		IF ((i AND 0x1F) = 0x1F) THEN
			INC o
			test${i+o} = '\n'
		END IF
	NEXT i
'
' change console character map and print the character set
'
	XuiSendStringMessage (grid, "SetCharacterMapArray", 0, 0, 0, 0, 1, @map[])
	XuiSendStringMessage (grid, "SetTextArray", 0, 0, 0, 0, 0, @empty$[])
	PRINT test$
'
' make sure character map array is returned intact
'
	XuiSendStringMessage (grid, "GetCharacterMapArray", 0, 0, 0, 0, 1, @char[])
	PRINT implementation$
	PRINT "***  test character map array modified ***"
	PRINT "Microsoft Windows is as wierd as Bill Gates!"
	PRINT "Did the quick brown fox jump over the lazy dog?"
	PRINT
'
' show some mapped and unmapped characters in a dialog window
'
	a$ = implementation$ + "\n"
	a$ = a$ + "**  test character map array modified ***\n"
	a$ = a$ + "Microsoft Windows is as wierd as Bill Gates!\n"
	a$ = a$ + "Did the quick brown fox jump over the lazy dog?\n\n"
	a$ = a$ + " a e i o u y c n ? ! \n"
	a$ = a$ + " \xDF \xE0 \xE1 \xE2 \xE3 \xE4 \xE5 \xE6 \xE7 \xE8 \xE9 \xEA \xEB \xEC \xED \xEE \xEF \n"
	a$ = a$ + " \xA9 \xF0 \xF1 \xF2 \xF3 \xF4 \xF5 \xF6 \xF7 \xF8 \xF9 \xFA \xFB \xFC \xFD \xFE \xFF \n"
	XgrSetGridCharacterMapArray (0, @map[])
	XuiMessage (@a$)
	XgrSetGridCharacterMapArray (0, @empty[])
'
' remove character mapping from the console
'
	DIM map[]
	XuiSendStringMessage (grid, "SetCharacterMapArray", 0, 0, 0, 0, 1, @map[])
'
' make sure character mapping is gone
'
	PRINT "**  test character map array original ***"
	PRINT "Microsoft Windows is as wierd as Bill Gates!"
	PRINT "Did the quick brown fox jump over the lazy dog?"
	PRINT
END FUNCTION
END PROGRAM

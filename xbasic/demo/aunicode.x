'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aunicode"
VERSION	"0.0006"
'
IMPORT	"xst"
IMPORT	"xgr"
'
' This program displays all 65535 unicode characters.
' No font has displayable images for every possible
' unicode character, and many fonts only have images
' for English language characters and a few others.
'
' Start Windows Explorer, look in the c:/windows/fonts/
' directory for large .TTF font files; larger than 100KB.
' Double click on those fonts, and note the font name
' displayed at the top of the font-viewer program window.
' Assign those names to variable font$ in this program
' and run it to see the fonts.  Change the XstSleep()
' delay (milliseconds) to have more/less time to view
' each display of 512 characters.  To quickly display
' all characters, comment out the XstSleep() line.
'
' To stop this program from executing, press any key
' several times.
'
' The XgrDrawTextWide() family of functions that support
' drawing unicode strings were added recently in v6.0022
' of XBasic and have been tested very little.
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
	USHORT  text[]
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
	x = 0
	y = 0
	w = #displayWidth
	h = #displayHeight
	t = $$WindowTypeNoFrame
'
	XgrCreateWindow (@window, t, x, y, w, h, 0, "")
	XgrSetWindowTitle (window, @"display 65536 unicode characters")
	XgrCreateGrid (@grid, 0, 0, 0, w, h, window, 0, 0)
	XgrDisplayWindow (window)
	XgrClearGrid (grid, $$Black)
'
' try some of the first four fonts to see asian/chinese characters
'
	font$ = "MS Hei"
'	font$ = "MS Song"
'	font$ = "MingLiU"
'	font$ = "GulimChe"
'	font$ = "MS Gothic"
'	font$ = "Comic Sans MS"
'	font$ = "Courier New"
'	font$ = "Arial"
'
	XgrCreateFont (@font, @font$, 640, 400, 0, 0)
	XgrSetGridFont (grid, font)
'
' draw 256 lines of 256 characters per line
'
	c = 0
	DIM text[37]
	color = $$BrightCyan
'
	FOR i = 0 TO 2047
		IFZ (i AND 0x0F) THEN
			x = 4
			y = 32
			XstSleep (250)												' delay before displaying next page
			XgrMessagesPending (@count)
			IF (count > 5) THEN EXIT FOR					' a few keystrokes will break out
			XgrClearGrid (grid, $$Black)
			XgrSetDrawpoint (grid, 0, 0)
			XgrDrawText (grid, $$BrightGreen, "#####  font = " + font$)
		END IF
		line$ = HEX$(c,4)
		text[0] = line${0}
		text[1] = line${1}
		text[2] = line${2}
		text[3] = line${3}
		text[4] = ':'
		text[5] = ' '
		FOR j = 0 TO 31
			text[j+6] = c
			INC c
		NEXT j
		XgrSetDrawpoint (grid, x, y)
		XgrDrawTextWide (grid, color, @text[])
		y = y + 48
	NEXT i
'
	y = y - 32
	DIM text[5]
	text[0] = '_'
	text[1] = '_'
	text[2] = '_'
	text[3] = '_'
	text[4] = '_'
	text[5] = '_'
	XgrSetDrawpoint (grid, x, y)
	XgrDrawTextWide (grid, color, @text[])
	XgrDestroyFont (font)
	XstSleep (1000)
END FUNCTION
END PROGRAM

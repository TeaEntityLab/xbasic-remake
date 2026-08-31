'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"wviewbmp"
VERSION	"0.0000"
'
	IMPORT	"xst"
	IMPORT	"xgr"
	IMPORT	"xui"
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
	XstClearConsole ()
'
' get full path/file name of all bitmap files - return if none
'
	base$ = "$XBDIR"
	filter$ = "*.bmp"
'
	XstFindFiles (@base$, @filter$, -1, @file$[])
	IFZ file$[] THEN RETURN
'
' create window to display the bmp images
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
	width = 16
	height = 16
	x = (#displayWidth - width) >> 1
	y = 50
	XuiCreateWindow (@grid, @"XuiLabel", x, y, width, height, $$WindowTypeNoFrame, "")
	IFZ grid THEN RETURN
	XuiSendStringMessage (grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)
'
' display all BMP images
'
	ufile = UBOUND (file$[])
	FOR i = 0 TO ufile
		file$ = file$[i]
		XuiSendStringMessage (grid, @"SetImage", @image, 0, 0, 0, 0, file$)
		XuiSendStringMessage (grid, @"GetImageCoords", 0, 0, @width, @height, 0, 0)
'
' Skip to the next file if either the width or height is zero
'
		IFZ (width && height) THEN DO NEXT
'
		x = (#displayWidth - width) >> 1
		y = 50
		PRINT RJUST$(STRING$(width),4); "  x"; RJUST$(STRING$(height),4); " : "; file$
		XuiSendStringMessage (grid, @"ResizeWindow", x, y, width, height, 0, 0)
		XuiSendStringMessage (grid, @"RedrawWindow", 0, 0, 0, 0, 0, 0)
		XgrProcessMessages ($$ProcessAllOrNone)
		XstSleep (200)
	NEXT i
'
	IF grid THEN XuiSendStringMessage (grid, @"DestroyWindow", 0, 0, 0, 0, 0, 0)
'
	RETURN
'
END FUNCTION
END PROGRAM

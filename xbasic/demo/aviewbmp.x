'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aviewbmp"
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
	UBYTE  bmp[]
'
' get full path/file name of all bitmap files - return if none
'
	base$ = "/usr/"
	filter$ = "*.bmp"
	XstFindFiles (@base$, @filter$, -1, @file$[])
	IFZ file$[] THEN RETURN
'
' create window to display the bmp images
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
	XuiCreateWindow (@grid, @"XuiLabel", 100, 100, 100, 100, $$WindowTypeNoFrame, "")
	XuiSendStringMessage (grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)
	XgrProcessMessages ($$ProcessAllOrNone)
'	XgrClearGrid (grid, $$LightRed)
	IFZ grid THEN RETURN
'
' display all BMP images
'
	ufile = UBOUND (file$[])
	FOR i = 0 TO ufile
		file$ = file$[i]
		file = OPEN (file$, $$RD)
		IF (file < 3) THEN DO NEXT
		error = ERROR (0)
		IF error THEN DO NEXT
		bytes = LOF (file)
		upper = bytes - 1
		DIM bmp[upper]
		READ [file], bmp[]
		CLOSE (file)
		error = ERROR (0)
		IF error THEN DO NEXT
		GOSUB DisplayImage
	NEXT
'
	IF grid THEN XuiSendStringMessage (grid, @"DestroyWindow", 0, 0, 0, 0, 0, 0)
	RETURN
'
'
'
' ******************************
' *****  SUB DisplayImage  *****
' ******************************
'
SUB DisplayImage
	XgrGetImageArrayInfo (@bmp[], @bbp, @width, @height)
	x = (#displayWidth - width) >> 1
	y = (#displayHeight - height) >> 1
	IF (x < #windowBorderWidth) THEN x = #windowBorderWidth
	IF (y < (#windowTitleHeight + #windowBorderWidth)) THEN y = #windowBorderWidth + #windowTitleHeight
	PRINT RJUST$(STRING$(bytes),6); " : "; RJUST$(STRING$(width),4); ","; RJUST$(STRING$(height),4); " : "; file$
	XuiSendStringMessage (grid, @"ResizeWindow", x, y, width, height, 0, 0)
	XgrProcessMessages ($$ProcessAllOrNone)
	XgrSetImage (grid, @bmp[])
	DIM bmp[]
	XstSleep (200)
END SUB
END FUNCTION
END PROGRAM

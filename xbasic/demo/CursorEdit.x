'
' ####################
' #####  PROLOG  #####
' ####################
'
' subject to LGPL license - see COPYING_LIB
'
' cw2008can@yahoo.com
'
' for Windows XBasic
' for Linux XBasic
'
PROGRAM "CursorEdit"
VERSION "0.0000"  '2023 January 31
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
DECLARE  FUNCTION  Entry               ()
INTERNAL FUNCTION  CreateWindow        ()
INTERNAL FUNCTION  InitGui             ()
INTERNAL FUNCTION  LoadCursor          ()
INTERNAL FUNCTION  Message1234Button   (title$, message$, grids$, @kid, @reply$)
INTERNAL FUNCTION  QuitCursor          ()
INTERNAL FUNCTION  SaveCursor          ()
INTERNAL FUNCTION  Selection           (grid, message$, v0, v1, iCol, jRow, kid, r1$)
INTERNAL FUNCTION  Sleep               (msec)
INTERNAL FUNCTION  UpdateToggleButtons ()
'
$$ColumnsDefault = 16
$$RowsDefault    = 16
'
'
' ###################
' #####  Entry  #####
' ###################
'
FUNCTION Entry ()
	SHARED baseGridWidth
	SHARED curHeight
	SHARED curWidth
	SHARED cursorByte[]
	SHARED mainGrid
	SHARED menuGridsWidth
	SHARED redoLabelGrid
	SHARED restartLabelGrid
	SHARED timerRunning
	SHARED loadUpdateFlag

	InitGui ()

	XstDisplayConsole ()
	XstClearConsole ()
	curWidth  = $$ColumnsDefault
	curHeight = $$RowsDefault

	bytesUpper = (curWidth * curHeight)/8 -1
	DIM cursorByte[bytesUpper]
	CreateWindow ()
'
'
' convenience function message loop
'
	DO
		XgrProcessMessages ($$ProcessOneOnly)
		DO WHILE XuiGetNextCallback (@grid, @message$, @v0, @v1, @v2, @v3, @kid, @r1$)
			GOSUB Callback
		LOOP
		IF loadUpdateFlag THEN
			UpdateToggleButtons ()
		END IF
	LOOP
	RETURN
' --------------------------------------------------------------------------
'
' *****  Callback  *****
'
SUB Callback
	win = kid >> 16
	kid = kid AND 0xFF
	SELECT CASE message$
		CASE "CloseWindow" : GOSUB Quit
		CASE "Selection"   : Selection (grid, message$, v0, v1, v2, v3, win, r1$)
	END SELECT
END SUB
'
'
' *****  Quit  *****
'
SUB Quit
	abort = QuitCursor ()
	IFZ abort THEN
		XuiSendMessage ( mainGrid, #Destroy, 0, 0, 0, 0, 0, 0)
		XgrProcessMessages ($$ProcessAllOrNone)
		RETURN (0)
	END IF
END SUB
'
END FUNCTION
'
'
' #############################
' #####  CreateWindow ()  #####
' #############################
'
FUNCTION  CreateWindow ()
	SHARED tbGridNum[]
	SHARED mainGrid
	SHARED menuGridsWidth
	SHARED curHeight
	SHARED curWidth

	$XuiBase = 1
	$XuiPushButton = 5

	XgrGetDisplaySize (display$, 0, 0, @borderWidth, @titleHeight)
	XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
	maxW = workAreaWidth - (borderWidth * 2)
	maxH = workAreaHeight - (borderWidth * 2) - titleHeight
	buttonsHigh    = curHeight
	pushButtonSize = (maxH / buttonsHigh)

	font = 0
	text$ = " Load Cursor "
	XgrGetTextImageSize (font, text$, @dx, @dy, @width, @height, @gap, @space)

	pbx = 10                               ' push button/label x offset
	pbh = 26                               ' push button/label height
	IF (pbh < height) THEN pbh = height
	labw = 132                             ' label width
	labw = 132                             ' label width
	IF (labw < width) THEN labw = width
	pbw = labw - pbx - pbx                 ' push button width
	pblx = pbx + pbw + 2                   ' push button label x offset
	pblw = pbx + labw - pblx               ' push button label width
	menuGridsWidth =  labw

	buttonsWide    = curWidth

	buttonsTotal   = buttonsWide * curHeight
'	squaresLeft = buttonsTotal
	DIM tbGridNum[curWidth-1, curHeight-1]
'
' create window with XuiPushButton grid
'
	baseGridWidth  = pushButtonSize * buttonsWide
	baseGridHeight = pushButtonSize * buttonsHigh

	windowWidth = baseGridWidth + menuGridsWidth
	x = workAreaWidth - windowWidth - (borderWidth * 2)
	y = ((workAreaHeight - baseGridHeight + titleHeight) / 2) + workAreaY
	wt = $$WindowTypeFixedSize OR $$WindowTypeSystemMenu
	XuiCreateWindow      (@grid, @"XuiBase", x, y, windowWidth, baseGridHeight, wt, "")
	XuiSendMessage ( grid, #SetCallback, grid, &XuiQueueCallbacks(), 0, 0, -1, -1)
	XuiSendMessage ( grid, #SetWindowTitle, @wind, 0, 0, 0, 0, "Cursor")
	XuiSendMessage ( grid, #GetWindow, @wind, 0, 0, 0, 0, 0)
	mainGrid = grid
	XuiSendMessage (wind, #WindowSetIcon, #iconHand, 0, 0, 0, 0, 0)

	bgColor = $$White
	bdColor = $$Grey
	w = pushButtonSize
	h = pushButtonSize
	FOR jRow = 0 TO curHeight-1
		FOR iCol = 0 TO curWidth-1
			x = iCol * pushButtonSize + menuGridsWidth
			y = jRow * pushButtonSize
'			tbGridNum[iCol,jRow].colorNum = colorNum
			GOSUB CreateToggleButton
			tbGridNum[iCol,jRow] = tbGrid
		NEXT iCol
	NEXT jRow

	GOSUB CreateControlButtons

	XuiSendMessage ( grid, #DisplayWindow, 0, 0, 0, 0, 0, 0)

'
'
' *****  CreateToggleButton  *****
'
SUB CreateToggleButton
	XuiToggleButton (@tbGrid, #Create, x, y, w, h, wind, grid)
	XuiSendMessage  (tbGrid, #SetCallback, grid, &XuiQueueCallbacks(), iCol, jRow, 6, "Toggle")
	XuiSendMessage  (tbGrid, #SetHelpString, 0, 0, 0, 0, 0, "Do I really need help?")
	XuiSendMessage  (tbGrid, #SetColor, bgColor, $$White, bdColor, $$Black, 0, 0)
	XuiSendMessage  (tbGrid, #SetColorExtra, $$Black, $$White, $$Yellow, $$Red, 0, 0)
	XuiSendMessage  (tbGrid, #SetBorder, $$BorderLoLine1, $$BorderLower1, $$BorderRaise1, 0, 0, 0)
	XuiSendMessage  (tbGrid, #SetFontNumber, fontLarge, 0, 0, 0, 0, 0)
END SUB
'
' *****  CreateControlButtons  *****
'
SUB CreateControlButtons

	buttonName$ = "Load Cursor" : i = 1 : GOSUB CreateOneControlButton
'
	buttonName$ = "Save Cursor" : i = 2 : GOSUB CreateOneControlButton
'
	buttonName$ = "Quit"        : i = 3 : GOSUB CreateOneControlButton

END SUB
'
' *****  CreateOneControlButton  *****
'
SUB CreateOneControlButton
	y = i * 100
	XuiPushButton	 (@tbGrid, #Create, pbx, y, pbw, pbh, wind, grid)
	XuiSendMessage ( tbGrid, #SetCallback, grid, &XuiQueueCallbacks(), curWidth, i, 0-$XuiPushButton, 0)
	XuiSendMessage ( tbGrid, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( tbGrid, #SetGridName, 0, 0, 0, 0, 0, buttonName$)
	XuiSendMessage ( tbGrid, #SetTextString, 0, 0, 0, 0, 0, buttonName$)
	XuiSendMessage ( tbGrid, #SetColor, $$Steel, $$Blue, $$Black, $$White, 0, 0)
	XuiSendMessage ( tbGrid, #SetColorExtra, $$Yellow, $$Yellow, $$Black, $$White, 0, 0)
	XuiSendMessage ( tbGrid, #SetBorder, $$BorderLoLine1, $$BorderRaise1, $$BorderLower1, $$BorderLoLine1, 0, 0)
	XuiSendMessage ( tbGrid, #SetFontNumber, @font, 0, 0, 0, 0, 0)
END SUB
'
END FUNCTION
'
'
' ########################
' #####  InitGui ()  #####
' ########################
'
FUNCTION  InitGui ()

	XgrRegisterIcon      (@"hand",           @#iconHand)
	XgrRegisterIcon      (@"handb",          @#iconHandb)

	XgrRegisterMessage (@"CloseWindow",      @#CloseWindow)
	XgrRegisterMessage (@"Create",           @#Create)
	XgrRegisterMessage (@"Destroy",          @#Destroy)
	XgrRegisterMessage (@"DisplayWindow",    @#DisplayWindow)
	XgrRegisterMessage (@"GetGridName",      @#GetGridName)
	XgrRegisterMessage (@"GetSize",          @#GetSize)
	XgrRegisterMessage (@"GetWindow",        @#GetWindow)
	XgrRegisterMessage (@"GetWindowSize",    @#GetWindowSize)
	XgrRegisterMessage (@"MouseEnter",       @#MouseEnter)
	XgrRegisterMessage (@"MouseExit",        @#MouseExit)
	XgrRegisterMessage (@"RedrawGrid",       @#RedrawGrid)
	XgrRegisterMessage (@"SetBorder",        @#SetBorder)
	XgrRegisterMessage (@"SetCallback",      @#SetCallback)
	XgrRegisterMessage (@"SetColor",         @#SetColor)
	XgrRegisterMessage (@"SetColorExtra",    @#SetColorExtra)
	XgrRegisterMessage (@"SetFont",          @#SetFont)
	XgrRegisterMessage (@"SetFontNumber",    @#SetFontNumber)
	XgrRegisterMessage (@"SetGridName",      @#SetGridName)
	XgrRegisterMessage (@"SetHelpString",    @#SetHelpString)
	XgrRegisterMessage (@"SetStyle",         @#SetStyle)
	XgrRegisterMessage (@"SetTextString",    @#SetTextString)
	XgrRegisterMessage (@"SetTexture",       @#SetTexture)
	XgrRegisterMessage (@"SetValue",         @#SetValue)
	XgrRegisterMessage (@"SetWindowTitle",   @#SetWindowTitle)
	XgrRegisterMessage (@"TimeOut",          @#TimeOut)
	XgrRegisterMessage (@"WindowSetIcon",    @#WindowSetIcon)

'	error = XgrIconNameToNumber ("hand", @icon)
'	error = XgrIconNameToNumber ("handb", @iconb)
'	error = XgrIconNameToNumber ("window", @iconw)

END FUNCTION
'
'
' #########################
' #####  LoadCursor ()  #####
' #########################
'
' #define insert_width 16
' #define insert_height 16
' #define insert_x_hot 2
' #define insert_y_hot 7
' static char insert_bits[] = {
'    0x1f, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00,
'    0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00, 0x04, 0x00,
'    0x04, 0x00, 0x04, 0x00, 0x1f, 0x00, 0x00, 0x00};
'
FUNCTION  LoadCursor ()
	SHARED mainGrid
	SHARED curName$
	SHARED curHeight
	SHARED curWidth
	SHARED curXHot
	SHARED curYHot
	SHARED cursorAltered
	SHARED cursorByte[]
	SHARED cursorFile$
	SHARED loadUpdateFlag

	XstFileSelectSetInfo (saveDir$, "*.cur, *.msk, *.ico", 100, 0, 50, 50)
	XstFileSelectOpen ($$RD, @file$, @fileNumber)
	IF (fileNumber < 3) THEN
		PRINT "Unable to open file", file$
		RETURN
	END IF

	curXHot = -1
	curYHot = -1
	FOR i = 0 TO 4
		string$ = INFILE$(fileNumber)
		PRINT string$
		uWord = XstParseWhitespaceToArray (string$, @word$[])
		IF (uWord = 2) THEN
			value2 = XLONG(word$[2])
		END IF
		SELECT CASE word$[0]
			CASE "#define" : SELECT CASE RIGHT$(word$[1], 6)
												CASE	"_width" :  curName$ = LEFT$(word$[1], LEN(word$[1])-6)
																					curWidth = value2
												CASE	"height" : curHeight = value2
												CASE	"_x_hot" :  curXHot  = value2
												CASE	"_y_hot" :  curYHot  = value2
											END SELECT
			CASE "static"  : IF (word$[uWord] == "{") THEN
													EXIT FOR
												END IF
			CASE ELSE : PRINT "Formar error in file"
									EXIT FUNCTION
		END SELECT
	NEXT i

	cursorFile$ = file$

	parseData = $$TRUE
	bytesUpper = (curWidth * curHeight)/8 -1
	DIM cursorByte[bytesUpper]
	vi = 0

	DO UNTIL EOF(fileNumber)
		string$ = INFILE$(fileNumber)
		PRINT string$
		IF parseData THEN
			GOSUB ParseDataBits
		END IF
		IF (RIGHT$(string$) = "{") THEN
			parseData = $$TRUE
			vi = 0
		END IF
		IF (RIGHT$(string$) = "}") THEN
			parseData = $$FALSE
		END IF
	LOOP

	cursorAltered = $$FALSE
	loadUpdateFlag = $$TRUE
	RETURN
'
'
' *****  ParseDataBits  *****
'
SUB ParseDataBits
	word = 1
	DO
		word$ = XstParseWhitespace$ (string$, word)
		IFZ word$ THEN
			EXIT SUB
		END IF
		IF (vi > bytesUpper) THEN
			bytesUpper = vi
			REDIM cursorByte[vi]
		END IF
		byte = UBYTE(word$)
		cursorByte[vi] = byte
		INC vi
		INC word
	LOOP
END SUB

END FUNCTION
'
'
' #################################
' #####  Message1234Button()  #####
' #################################
'
' The number of push buttons depends on the number of lines in grids$,'
' each line is the name for each button. If grids$ is blank, it defaults
' to 1 button named "cancel"
'
FUNCTION  Message1234Button (title$, message$, grids$, @kid, @reply$)
	SHARED baseGridWidth
	SHARED mainGrid
	SHARED menuGridsWidth

	IFZ grids$ THEN grids$ = "cancel"
	XstStringToStringArray (grids$, @grids$[])
	uGrids = UBOUND(grids$[])
	SELECT CASE uGrids
		CASE 0    : wt$ = "XuiMessage1B"
		CASE 1    : wt$ = "XuiMessage2B"
		CASE 2    : wt$ = "XuiMessage3B"
		CASE 3    : wt$ = "XuiMessage4B"
		CASE ELSE : wt$ = "XuiMessage4B"
	END SELECT

	XuiSendMessage (mainGrid, #GetWindowSize, @xw, @yw, 0, 0, 0, 0)
	XuiSendMessage (mainGrid, #GetSize, @x, @y, @width, @height, 0, 0)

	w = 300
	h = 150
	x = xw + menuGridsWidth + (baseGridWidth / 2)
	y = yw + y + (height /4)

	XuiCreateWindow (@grid, @wt$, x, y, w, h, 0, "")
	XuiSendMessage  (grid, #SetFont, 0, 0, 0, 0, 1, @"9x15bold")
	XuiSendMessage  (grid, #SetTexture, $$TextureFlat, 0, 0, 0, 1, 0)
	XuiSendMessage  (grid, #SetColor, $$Steel, $$Black, -1, -1, -1, 0)
	XuiGetReply     (grid, title$, message$, grids$, @v0, @v1, @kid, @reply$)
	XuiSendMessage  (grid, #Destroy, 0, 0, 0, 0, 0, 0)

	IF (kid < 2) THEN
		reply$ = "CloseWindow"
	ELSE
		reply$ = TRIM$(grids$[kid-2])
	END IF

END FUNCTION
'
'
' ############################
' #####  QuitCursor ()  #####
' ############################
'
FUNCTION  QuitCursor ()
	SHARED cursorAltered

	IFZ cursorAltered THEN
		RETURN (0)
	END IF

	title$ = "Quit Cursor"
	message$ = " Cursor data changes have not been saved "
	grids$ = "quit\ncancel"
	Message1234Button (title$, message$, grids$, @kid, @reply$)

	IF (kid != 2) THEN THEN RETURN (-1)  ' not enter button ?

END FUNCTION
'
'
' #########################
' #####  SaveCursor ()  #####
' #########################
'
FUNCTION  SaveCursor ()
	SHARED cursorAltered
	SHARED cursorByte[]
	SHARED cursorFile$
	SHARED curHeight
	SHARED curWidth
	SHARED curXHot
	SHARED curYHot

	file$ =  cursorFile$
	XstFileSelectSetInfo (file$, "*.cur, *.msk, *.ico, *.txt", 100, 0, 40, 50)
	XstFileSelect ("Save Cursor File", @file$)
	IFZ file$ THEN RETURN
	readable = XstGetFileAttributes (file$, @attributes)
	IF (readable) THEN
		title$ = "Save Cursor"
		IF (readable AND $$FileReadOnly) THEN
			message$ = " File is Read Only: \n\n " + file$
			grids$ = "cancel"
			Message1234Button (title$, message$, grids$, @kid, @reply$)
		ELSE
			message$ = " File alread exists: \n\n " + file$
			grids$ = " overwrite \n cancel "
			Message1234Button (title$, message$, grids$, @kid, @reply$)
			IF (kid != 2) THEN RETURN
		END IF
	END IF

	fileNumber = OPEN(file$, $$WRNEW)
	IF (fileNumber < 3) THEN
		PRINT "Unable to open file", file$
		RETURN
	END IF

	XstDecomposePathname (file$, @path$, @parent$, @fileName$, @curName$, @extent$)

'	STOP
	PRINT [fileNumber], "#define " + curName$ + "_width" + STR$(curWidth)
	PRINT [fileNumber], "#define " + curName$ + "_height" + STR$(curHeight)
	IF (extent$ <> ".ico") THEN
		PRINT [fileNumber], "#define " + curName$ + "_x_hot" + STR$(curXHot)
		PRINT [fileNumber], "#define " + curName$ + "_y_hot" + STR$(curYHot)
	END IF
	PRINT [fileNumber], "static char " + curName$ + "_bits[] = {"

	upper = UBOUND(cursorByte[])
	PRINT [fileNumber], "  ";
	FOR i = 0 TO upper-1
		cursorByte$ = " " + HEXX$(cursorByte[i],2) + ","
		cursorByte$ = LCASE$(cursorByte$)
		PRINT [fileNumber], cursorByte$;
		IFZ ((i+1) MOD 12) THEN
			PRINT [fileNumber]
			PRINT [fileNumber], "  ";
		END IF
	NEXT i
	cursorByte$ = " " + HEXX$(cursorByte[i],2) + "};"
	cursorByte$ = LCASE$(cursorByte$)
	PRINT [fileNumber], cursorByte$
	fileNumber = CLOSE (fileNumber)
	IFZ fileNumber THEN
		cursorAltered = $$FALSE
	END IF

END FUNCTION
'
' #######################
' #####  Selection  #####
' #######################
'
FUNCTION Selection (grid, message$, v0, v1, iCol, jRow, kid, r1$)
	SHARED tbGridNum[]
'	SHARED colorNum
	SHARED cursorAltered
	SHARED cursorByte[]
	SHARED curWidth
	SHARED highestNonblankCol
	SHARED loadUpdateFlag
	SHARED mainGrid

	maxiCol = UBOUND(tbGridNum[])
	maxjRow = UBOUND(tbGridNum[0,])
'
	IF (iCol > curWidth-1) THEN
		IF (iCol == curWidth) THEN ' this might be a control button
			IFZ v1 THEN
				gridName$ = "zero grid number"
			ELSE
				XuiSendMessage (v1, #GetGridName, 0, 0, 0, 0, 0, @gridName$)
			END IF
			SELECT CASE gridName$
				CASE "Save Cursor"  : SaveCursor ()
				CASE "Load Cursor"  : XuiSendMessage ( mainGrid, #Destroy, 0, 0, 0, 0, 0, 0)
															LoadCursor ()
															CreateWindow ()

				CASE "Quit"        : XuiCallback (v1, #CloseWindow, 0, 0, 0, 0, 0, 0)
				CASE ELSE          : PRINT "Control Push Button =", gridName$
			END SELECT
			RETURN
		ELSE
			PRINT "Out of bounds square row = " jRow : RETURN
		END IF
	END IF
	IF (jRow > maxjRow) THEN PRINT "Out of bounds square jRow = " jRow : RETURN

	IFZ loadUpdateFlag
		cursorAltered = $$TRUE
	END IF

	IF v0 THEN
		bgColor = $$Black
	ELSE
		bgColor = $$White
	END IF
	tbGrid = tbGridNum[iCol,jRow]
	XuiSendMessage (tbGrid, #SetColor, bgColor, $$Blue, bdColor, $$Green, 0, 0)
	XuiSendMessage (tbGrid, #RedrawGrid, 0, 0, 0, 0, 0, 0)

	button = (jRow * curWidth) + iCol
	byteIndex = button\8
	bitNumber = button MOD 8

	value = cursorByte[byteIndex]{{1,bitNumber}}
	IF (value <> v0) THEN
		vBit = 1 << bitNumber
		cursorByte[byteIndex] = cursorByte[byteIndex] XOR vBit
	END IF

	RETURN

END FUNCTION
'
'
' ######################
' #####  Sleep ()  #####
' ######################
'
FUNCTION  Sleep (msec)
	SHARED loadingGame

	IFF loadingGame THEN
		XstSleep (msec)
	END IF

END FUNCTION
'
'
' ####################################
' #####  UpdateToggleButtons ()  #####
' ####################################
'
'
'
'
FUNCTION  UpdateToggleButtons ()
	SHARED tbGridNum[]
	SHARED cursorByte[]
	SHARED curHeight
	SHARED curWidth
	SHARED loadUpdateFlag
	STATIC button

	buttons = (curHeight * curWidth)
	IF (button >= buttons) THEN
		loadUpdateFlag = $$FALSE
		button = 0
	END IF

	byteIndex = button\8
	bitNumber = button MOD 8
	value = cursorByte[byteIndex]{{1,bitNumber}}
	col = button MOD curWidth
	row = button \ curWidth
	tbGrid = tbGridNum[col,row]
	XuiSendMessage (tbGrid, #SetValue, value, 0, 0, 0, 0, 0)
	error = XgrAddMessage (tbGrid, @#RedrawGrid, 0, 0, 0, 0, 0, 0)
	INC button

END FUNCTION
END PROGRAM

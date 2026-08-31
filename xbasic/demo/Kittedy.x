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
PROGRAM "Kittedy"
VERSION "0.0007"  '2022 April 8
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
TYPE SQUAREINFORMATION
	XLONG .grid
	XLONG .colorNum
END TYPE
'
DECLARE  FUNCTION  Entry             ()
INTERNAL FUNCTION  CheckAdjacent     (@x, @y)
INTERNAL FUNCTION  ColorShuffle      (gameNumber, @colors[])
INTERNAL FUNCTION  DisplayText       (text$)
INTERNAL FUNCTION  FindAdjacent      (@x, @y, adjacent, adjacent[], flagChar$)
INTERNAL FUNCTION  FindChange        (oldMoveNumber, newMoveNumber, iCol, jRow, flagChar$)
INTERNAL FUNCTION  GameOverCheck     (trace)
INTERNAL FUNCTION  GetSaveDirectory$ ()
INTERNAL FUNCTION  LoadGame          ()
INTERNAL FUNCTION  Message1234Button (title$, message$, grids$, @kid, @reply$)
INTERNAL FUNCTION  NewGame           (selectGame)
INTERNAL FUNCTION  QuitKittedy       ()
INTERNAL FUNCTION  RaiseColumn       (row, column)
INTERNAL FUNCTION  Redo              ()
INTERNAL FUNCTION  Restart           ()
INTERNAL FUNCTION  ResumeElapsedTime ()
INTERNAL FUNCTION  SaveGame          ()
INTERNAL FUNCTION  Selection         (grid, message$, v0, v1, iCol, jRow, kid, r1$)
INTERNAL FUNCTION  ShiftColumns      ()
INTERNAL FUNCTION  Sleep             (msec)
INTERNAL FUNCTION  StartElapsedTime  ()
INTERNAL FUNCTION  StopElapsedTime   ()
INTERNAL FUNCTION  TraceEntryLoad    (entryNumber)
INTERNAL FUNCTION  TumbleAndShift    ()
INTERNAL FUNCTION  TumbleColumn      (row, column)
INTERNAL FUNCTION  Undo              ()
'
$$SaveSubDir$ = "kittedy"
'
$$MaxColors   = 5   '0 is Black + 5 working colors Blue, Green, Magenta (Pink), Red, Yellow
$$MaxColumn   = 9   '10 columns (0 = left, 9 = right)
$$MaxRow      = 15  '16 rows    (0 = top, 15 = bottom)
$$NoTrace     = 0
$$Trace       = -1
'
'
' ###################
' #####  Entry  #####
' ###################
'
FUNCTION Entry ()
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED baseGridWidth
	SHARED blockGrid
	SHARED borderEqualBackground
	SHARED colorTable[]
	SHARED controlButtonNames$[]
	SHARED flags
	SHARED found[]
	SHARED grid
	SHARED loadGameLabelGrid
	SHARED mainGrid
	SHARED menuGridsWidth
	SHARED newGameLabelGrid
	SHARED redoLabelGrid
	SHARED restartLabelGrid
	SHARED squaresLeft
	SHARED timeGrid
	SHARED undoLabelGrid
	SHARED saveGameLabelGrid
	SHARED selectGameLabelGrid
	SHARED GIANT startfiletime
	SHARED timerRunning
	STATIC count
	STATIC label

	$XuiBase = 1
	$XuiPushButton = 5

	borderEqualBackground = $$FALSE
'
' Initialize color table
'
	DIM colorTable[$$MaxColors]
		colorTable[0] = $$Black           ' erased or blank block
		colorTable[1] = $$LightBlue
		colorTable[2] = $$BrightGreen
		colorTable[3] = $$LightMagenta    ' is this the same as pink?
		colorTable[4] = $$LightRed
		colorTable[5] = $$BrightYellow

	XgrGetDisplaySize (display$, 0, 0, @borderWidth, @titleHeight)
	XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
	maxW = workAreaWidth - (borderWidth * 2)
	maxH = workAreaHeight - (borderWidth * 2) - titleHeight
	buttonsHigh    = $$MaxRow + 1
	pushButtonSize = (maxH / buttonsHigh)

	font = 0
	text$ = " Remaining Blocks "
	XgrGetTextImageSize (font, text$, @dx, @dy, @width, @height, @gap, @space)

	pbx = 15                               ' push button/label x offset
	pbh = 26                               ' push button/label height
	IF (pbh < height) THEN pbh = height
	labw = 132                             ' label width
	IF (labw < width) THEN labw = width
	pbw = labw * 2 / 3                     ' push button width
	pblx = pbx + pbw + 2                   ' push button label x offset
	pblw = pbx + labw - pblx               ' push button label width
	menuGridsWidth = pbx + labw + pbx + 1

	buttonsWide    = $$MaxColumn + 1

	buttonsTotal   = buttonsWide * buttonsHigh
	squaresLeft = buttonsTotal
	DIM squareInfo[$$MaxColumn, $$MaxRow]

	XgrRegisterMessage   ("CloseWindow", @#CloseWindow)
	XgrRegisterMessage   ("Create",      @#Create)
	XgrRegisterMessage   ("MouseExit",   @#MouseExit)
	XgrRegisterMessage   ("MouseEnter",  @#MouseEnter)
'
	GOSUB CreateLargeFont
'
' create window with XuiPushButton grid
'
	baseGridWidth  = pushButtonSize * buttonsWide
	baseGridHeight = pushButtonSize * buttonsHigh

	windowWidth = baseGridWidth + menuGridsWidth
	x = ((workAreaWidth - windowWidth) / 2) + workAreaX
	y = ((workAreaHeight - baseGridHeight + titleHeight) / 2) + workAreaY
	wt = $$WindowTypeFixedSize OR $$WindowTypeSystemMenu
	XuiCreateWindow      (@grid, @"XuiBase", x, y, windowWidth, baseGridHeight, wt, "")
	XuiSendStringMessage ( grid, @"SetCallback", grid, &XuiQueueCallbacks(), 0, 0, -1, -1)
	XuiSendStringMessage ( grid, @"SetWindowTitle", @wind, 0, 0, 0, 0, "Kittedy")
	XuiSendStringMessage ( grid, @"GetWindow", @wind, 0, 0, 0, 0, 0)
	mainGrid = grid

	bgColor = colorTable[0]
	bdColor = bgColor
	w = pushButtonSize
	h = pushButtonSize
	FOR jRow = 0 TO $$MaxRow
		FOR iCol = 0 TO $$MaxColumn
			x = iCol * pushButtonSize + menuGridsWidth
			y = jRow * pushButtonSize
			squareInfo[iCol,jRow].colorNum = colorNum
			GOSUB CreatePressButton
			squareInfo[iCol,jRow].grid = pbGrid
		NEXT iCol
	NEXT jRow

	GOSUB CreateControlButtons
	GOSUB CreateLabelBoxes

	XuiSendStringMessage ( grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)

	GameOverCheck ($$NoTrace)
'
' convenience function message loop
'
	DO
		XgrProcessMessages ($$ProcessOneOnly)
		DO WHILE XuiGetNextCallback (@grid, @message$, @v0, @v1, @v2, @v3, @kid, @r1$)
			GOSUB Callback
		LOOP
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
		CASE "TimeOut"     : GOSUB UpdateElapsedTime
	END SELECT
END SUB
'
'
'
'
SUB Quit
	abort = QuitKittedy ()
	IFZ abort THEN
		XuiSendStringMessage ( mainGrid, "Destroy", 0, 0, 0, 0, 0, 0)
		XgrProcessMessages ($$ProcessAllOrNone)
		RETURN (0)
	END IF
END SUB
'
'
' *****  CreateLargeFont  *****
'
SUB CreateLargeFont
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"nimbus mono l", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"Courier", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"Courier New", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"liberation mono", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"dejavu sans mono", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"*mono*", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"MS Sans Serif", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"Arial", 640, 900, 0, 0)
	IFZ fontLarge THEN XgrCreateFont (@fontLarge, @"Comic Sans MS", 640, 900, 0, 0)

'	XgrGetFontInfo (fontLarge, @fontName$, @fontSize, @fontWeight, @fontItalic, @fontAngle)
	IFZ fontLarge THEN fontLarge = font
END SUB
'
' *****  CreatePressButton  *****
'
SUB CreatePressButton
	XuiPressButton       (@pbGrid, #Create, x, y, w, h, wind, grid)
	XuiSendStringMessage ( pbGrid, "SetCallback", grid, &XuiQueueCallbacks(), iCol, jRow, 6, "Push")
	XuiSendStringMessage ( pbGrid, "SetHelpString", 0, 0, 0, 0, 0, "Do I really need help?")
	XuiSendStringMessage ( pbGrid, "SetColor", bgColor, $$White, bdColor, $$Black, 0, 0)
	XuiSendStringMessage ( pbGrid, "SetColorExtra", $$Black, $$White, $$Yellow, $$Red, 0, 0)
	XuiSendStringMessage ( pbGrid, "SetBorder", $$BorderLoLine1, $$BorderLower1, $$BorderRaise1, 0, 0, 0)
	XuiSendStringMessage ( pbGrid, "SetFontNumber", fontLarge, 0, 0, 0, 0, 0)
END SUB
'
' *****  CreateControlButtons  *****
'
SUB CreateControlButtons

	buttonName$ = "Undo"             : i = 0 : GOSUB CreateOneControlButton
	undoLabelGrid = labelGrid
	buttonName$ = "Redo"             : i = 1 : GOSUB CreateOneControlButton
	redoLabelGrid = labelGrid
	buttonName$ = "Restart"          : i = 2 : GOSUB CreateOneControlButton
	restartLabelGrid = labelGrid
	noLabel = $$TRUE
	buttonName$ = "Quit"             : i = 4 : GOSUB CreateOneControlButton
	buttonName$ = "Select Game"      : i = 5 : GOSUB CreateOneControlButton
	selectGameLabelGrid = labelGrid
	buttonName$ = "New Game"         : i = 6 : GOSUB CreateOneControlButton
	newGameLabelGrid = labelGrid
	buttonName$ = "Save Game"        : i = 8 : GOSUB CreateOneControlButton
	saveGameLabelGrid = labelGrid
	buttonName$ = "Load Game"        : i = 9 : GOSUB CreateOneControlButton
	loadGameLabelGrid = labelGrid

END SUB
'
' *****  CreateOneControlButton  *****
'
SUB CreateOneControlButton
	y = ($$MaxRow-i) * pushButtonSize - pushButtonSize
	XuiPushButton		     (@pbGrid, #Create, pbx, y, pbw, pbh, wind, grid)
	XuiSendStringMessage ( pbGrid, "SetCallback", grid, &XuiQueueCallbacks(), $$MaxColumn+1, i, 0-$XuiPushButton, 0)
	XuiSendStringMessage ( pbGrid, "SetStyle", 2, 0, 0, 0, 0, 0)
	XuiSendStringMessage ( pbGrid, "SetGridName", 0, 0, 0, 0, 0, buttonName$)
	XuiSendStringMessage ( pbGrid, "SetTextString", 0, 0, 0, 0, 0, buttonName$)
	XuiSendStringMessage ( pbGrid, "SetColor", $$Steel, $$Blue, $$Black, $$White, 0, 0)
	XuiSendStringMessage ( pbGrid, "SetColorExtra", $$Yellow, $$Yellow, $$Black, $$White, 0, 0)
	XuiSendStringMessage ( pbGrid, "SetBorder", $$BorderLoLine1, $$BorderRaise1, $$BorderLower1, $$BorderLoLine1, 0, 0)

	XuiSendStringMessage ( pbGrid, "SetFontNumber", @font, 0, 0, 0, 0, 0)

	IF noLabel THEN
		noLabel = $$FALSE
		EXIT SUB
	END IF

	XuiLabel             (@labelGrid, #Create, pblx, y, pblw, pbh, wind, grid)
	XuiSendStringMessage ( labelGrid, "SetGridName", 0, 0, 0, 0, 0, buttonName$)
	XuiSendStringMessage ( labelGrid, "SetColor", $$Steel, $$Blue, $$Black, $$White, 0, 0)
	XuiSendStringMessage ( labelGrid, "SetBorder", $$BorderLoLine1, $$BorderLoLine1, $$BorderLoLine1, $$BorderLoLine1, 0, 0)

END SUB
'
' *****  CreateLabelBoxes  *****  for Elapsed Time and Remaining Blocks
'
SUB CreateLabelBoxes
	XuiLabel             (@elapsGrid, #Create, pbx, pbh, labw, pbh, wind, grid)
	XuiSendStringMessage ( elapsGrid, "SetGridName", 0, 0, 0, 0, 0, "ElapsedTime")
	XuiSendStringMessage ( elapsGrid, "SetColor", $$Steel, $$Blue, $$Black, $$White, 0, 0)
	XuiSendStringMessage ( elapsGrid, "SetBorder", $$BorderLoLine1, $$BorderLower1, $$BorderRaise1, 0, 0, 0)
	XuiSendStringMessage ( elapsGrid, "SetTextString", 0, 0, 0, 0, 0, "Elapsed Time")

	XuiLabel             (@timeGrid, #Create, pbx, pbh*2, labw, pbh, wind, grid)
	XuiSendStringMessage ( timeGrid, "SetGridName", 0, 0, 0, 0, 0, "Time")
	XuiSendStringMessage ( timeGrid, "SetColor", $$Steel, $$Blue, $$Black, $$White, 0, 0)
	XuiSendStringMessage ( timeGrid, "SetBorder", $$BorderLoLine1, $$BorderLower1, $$BorderRaise1, 0, 0, 0)
	XuiSendStringMessage ( timeGrid, "SetTextString", 0, 0, 0, 0, 0, "00:00:00")
	XgrRegisterMessage   (@"TimeOut", @#TimeOut)
	XuiSendStringMessage ( grid, @"SetMessageFunc", #TimeOut, &XuiCallback(), 0, 0, 0, 0)

	XuiLabel             (@remGrid, #Create, pbx, pbh*4, labw, pbh, wind, grid)
	XuiSendStringMessage ( remGrid, "SetGridName", 0, 0, 0, 0, 0, "RemainingBlocks")
	XuiSendStringMessage ( remGrid, "SetColor", $$Steel, $$Blue, $$Black, $$White, 0, 0)
	XuiSendStringMessage ( remGrid, "SetBorder", $$BorderLoLine1, $$BorderLower1, $$BorderRaise1, 0, 0, 0)
	XuiSendStringMessage ( remGrid, "SetTextString", 0, 0, 0, 0, 0, "Remaining Blocks")

	XuiLabel             (@blockGrid, #Create, pbx, pbh*5, labw, pbh*2, wind, grid)
	XuiSendStringMessage ( blockGrid, "SetGridName", 0, 0, 0, 0, 0, "Blocks")
	XuiSendStringMessage ( blockGrid, "SetColor", $$Steel, $$Blue, $$Black, $$White, 0, 0)
	XuiSendStringMessage ( blockGrid, "SetBorder", $$BorderLoLine1, $$BorderLower1, $$BorderRaise1, 0, 0, 0)
	XuiSendStringMessage ( blockGrid, "SetFontNumber", fontLarge, 0, 0, 0, 0, 0)
	XuiSendStringMessage ( blockGrid, "SetTextString", 0, 0, 0, 0, 0, "0")

END SUB
'
' *****  UpdateElapsedTime *****
'
SUB UpdateElapsedTime
	IFZ timerRunning THEN EXIT SUB
	XstGetLocalDateAndTime (@year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
	XstDateAndTimeToFileTime (year, month, day, weekDay, hour, minute, second, nanos, @filetime$$)
	difTime$$ = filetime$$ - startfiletime

	XstFileTimeToDateAndTime (difTime$$, 0, 0, @day, 0, @hour, @minute, @second, @nanos)
	hour$ = STRING$(hour)
	IF (LEN(hour$) < 2) THEN hour$ = "0" + hour$
	minute$ = STRING$(minute)
	IF (LEN(minute$) < 2) THEN minute$ = "0" + minute$
	second$ = STRING$(second)
	IF (LEN(second$) < 2) THEN second$ = "0" + second$
	elapse$ = hour$ + ":" + minute$ + ":" + second$
	XuiSendStringMessage ( timeGrid, "SetTextString", 0, 0, 0, 0, 0, elapse$)
	XuiSendStringMessage ( timeGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
	msec = 1000 - (nanos/1000000) + 1
	XgrSetGridTimer (grid, msec)
END SUB

END FUNCTION
'
'
' ##############################
' #####  CheckAdjacent ()  #####
' ##############################
'
' found = CheckAdjacent (column, row)
'
FUNCTION  CheckAdjacent (x, y)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED colorNum
	SHARED colorTable[]
	SHARED found[]

	bgColor = colorTable[0]
	bdColor = bgColor
	found = $$FALSE
	iCol = x+1 : jRow = y   : GOSUB Check
	iCol = x-1              : GOSUB Check
	iCol = x   : jRow = y+1 : GOSUB Check
	           : jRow = y-1 : GOSUB Check

	RETURN found
' ----------------------------------
'
' **** Check *****
'
SUB Check
	IF (iCol < 0) THEN EXIT SUB
	IF (jRow < 0) THEN EXIT SUB
	IF (iCol > $$MaxColumn) THEN EXIT SUB
	IF (jRow > $$MaxRow) THEN EXIT SUB
	IF (squareInfo[iCol,jRow].colorNum == colorNum) THEN
		IFZ found[iCol,jRow] THEN
			found[iCol,jRow] = $$TRUE
			INC found
			pbGrid = squareInfo[iCol,jRow].grid
			XuiSendStringMessage (pbGrid, "SetColor", bgColor, $$Blue, bdColor, $$Green, 0, 0)
			XuiSendStringMessage (pbGrid, "SetColor", $$Black, $$Blue, bdColor, $$Green, 0, 0)
			XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)
			foundMore = CheckAdjacent (iCol, jRow)
			found = found + foundMore
		END IF
	END IF
END SUB

END FUNCTION
'
'
' #############################
' #####  ColorShuffle ()  #####
' #############################
'
FUNCTION  ColorShuffle (gameNumber, @colors[])
	SHARED baseGridWidth
	SHARED mainGrid
	SHARED menuGridsWidth
	STATIC selectGame

	uBlocks = (($$MaxColumn+1) * ($$MaxRow+1)) -1
	DIM colors[uBlocks]
	DIM shuffle[uBlocks]

	DIM shuffle[uBlocks]
	k = 0
	FOR i = 1 TO $$MaxColors
		FOR j = 1 TO (uBlocks +1) / $$MaxColors
			shuffle[k] = i
			INC k
			IF (k > uBlocks) THEN
				EXIT FOR 2
			END IF
		NEXT j
	NEXT i

	state = gameNumber

	FOR i = uBlocks TO 0 STEP -1
		state = state * 214013 + 2531011 AND 0x7FFFFFFF
		rand = (state >> 16) MOD (i + 1)
		SWAP shuffle[rand], shuffle[i]
	NEXT i

	FOR i = 0 TO uBlocks
		colors[i] = shuffle[uBlocks - i]
	NEXT i

END FUNCTION
'
'
' ############################
' #####  DisplayText ()  #####
' ############################
'
' DisplayText (text$)
'
FUNCTION  DisplayText (text$)
	SHARED SQUAREINFORMATION squareInfo[]

	IFZ text$ THEN GOSUB EraseText

	XstStringToStringArray (text$, @s$[])
	uLine = UBOUND(s$[])
	IF (uLine > $$MaxRow) THEN uLine = $$MaxRow
	firstRow = ($$MaxRow - uLine) \ 2

	FOR sLine = 0 TO uLine
		sLine$ = TRIM$(s$[sLine])
		sLen = LEN(sLine$)
		IF (sLen > ($$MaxColumn+1)) THEN sLen = $$MaxColumn + 1
		firstCol = (($$MaxColumn + 1) - sLen) \ 2
		FOR sCol = 1 TO sLen
			GOSUB DisplayChar
		NEXT sCol
	NEXT sLine

	RETURN
' ---------------------------------------------------------
'
'
' *****  DisplayChar  *****
'
SUB DisplayChar
	buttonChar$ = MID$(sLine$, sCol, 1)
	pbGrid = squareInfo[firstCol+sCol-1, firstRow+sLine].grid
	XuiSendStringMessage (pbGrid, "SetTextString", 0, 0, 0, 0, 0, buttonChar$)
	XuiSendStringMessage (pbGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
END SUB
'
' *****  EraseText  *****
'
SUB EraseText
	FOR jRow = 0 TO $$MaxRow
		FOR iCol = 0 TO $$MaxColumn
			pbGrid = squareInfo[iCol,jRow].grid
			XuiSendStringMessage (pbGrid, "SetTextString", 0, 0, 0, 0, 0, "")
			XuiSendStringMessage (pbGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
		NEXT iCol
	NEXT jRow
END SUB

END FUNCTION
'
'
' #############################
' #####  FindAdjacent ()  #####
' #############################
'
' found = FindAdjacent (column, row, @adjacent, @adjacent[], flagChar$)
'
FUNCTION  FindAdjacent (x, y, @adjacent, @adjacent[], flagChar$)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED colorNum
	SHARED colorTable[]
	iCol = x+1 : jRow = y   : GOSUB Check
	iCol = x-1              : GOSUB Check
	iCol = x   : jRow = y+1 : GOSUB Check
	           : jRow = y-1 : GOSUB Check

	RETURN
' ----------------------------------
'
' **** Check *****
'
SUB Check
	IF (iCol < 0) THEN EXIT SUB
	IF (jRow < 0) THEN EXIT SUB
	IF (iCol > $$MaxColumn) THEN EXIT SUB
	IF (jRow > $$MaxRow) THEN EXIT SUB
	IF (squareInfo[iCol,jRow].colorNum == colorNum) THEN
		IFZ adjacent[iCol,jRow] THEN
			adjacent[iCol,jRow] = $$TRUE
			INC adjacent
			pbGrid = squareInfo[iCol,jRow].grid
			XuiSendStringMessage (pbGrid, "SetTextString", 0, 0, 0, 0, 0, flagChar$)
			XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)
			FindAdjacent (iCol, jRow, @adjacentMore, @adjacent[], flagChar$)         ' recursive call
			adjacent = adjacent + adjacentMore
		END IF
	END IF
END SUB

END FUNCTION
'
'
' ###########################
' #####  FindChange ()  #####
' ###########################
'
' FindChange (oldMoveNumber, newMoveNumber, @iCol, @jRow, flagChar$)
'
FUNCTION  FindChange (oldMoveNumber, newMoveNumber, iCol, jRow, flagChar$)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED colorNum
	SHARED gameTrace$[]

	oldTrace$ = gameTrace$[oldMoveNumber]
	newTrace$ = gameTrace$[newMoveNumber]

	error = XstParseStringToStringArray (oldTrace$, ",", @oldTrace$[])
	error = XstParseStringToStringArray (newTrace$, ",", @newTrace$[])

	FOR iCol = 0 TO $$MaxColumn
		oldTraceCol$ = oldTrace$[iCol]
		newTraceCol$ = newTrace$[iCol]
		IF (oldTraceCol$ != newTraceCol$) THEN
			uOld = UBOUND(oldTraceCol$)
			uNew = UBOUND(newTraceCol$)
			IF (uOld <= uNew) THEN uMin = uOld : uMax = uNew
			IF (uNew <= uOld) THEN uMin = uNew : uMax = uOld
'
			jRow = $$MaxRow
			FOR char = 0 TO uMin
				IF (oldTraceCol${char} != newTraceCol${char}) THEN
					GOSUB GetAdjacentBlocks
					EXIT FOR 2
				END IF
				DEC jRow
			NEXT char
			GOSUB GetAdjacentBlocks
			EXIT FOR
		END IF
	NEXT iCol
'
	RETURN
'
'----------------------------------------------------
'
' *****  GetAdjacentBlocks  *****
'
SUB GetAdjacentBlocks
	DIM adjacent[$$MaxColumn, $$MaxRow]                ' zero adjacent[] locations
	adjacent = 0                                       ' zero adjacent count
	colorNum = squareInfo[iCol,jRow].colorNum
	FindAdjacent (iCol, jRow, @adjacent, @adjacent[], flagChar$)
'	PRINT "FindChange(51)", iCol, jRow, adjacent
END SUB
'
END FUNCTION
'
'
' ##############################
' #####  GameOverCheck ()  #####
' ##############################
'
' GameOverCheck ($$Trace)
'
FUNCTION  GameOverCheck (trace)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED highestNonblankCol
	SHARED gameOver
	SHARED gameTrace$[]
	SHARED mainGrid
	SHARED squaresLeft
	SHARED blockGrid
	SHARED moveNumber

	IFZ trace THEN
		IFZ gameTrace$[] THEN
			DisplayText ("Click\n\nNew Game")
			RETURN
		END IF
	END IF

	IFZ gameTrace$[] THEN
		uGameTrace = ($$MaxRow + 1) * ($$MaxColumn + 1) \ 2 + 2
		DIM gameTrace$[uGameTrace]
		XuiSendStringMessage ( mainGrid, "GetWindowTitle", @window, 0, 0, 0, 0, @title$)
		gameTrace$[0] = title$
		moveNumber = 1
	ELSE
		IF trace THEN INC moveNumber
	END IF

	gameOver = $$TRUE
	trace$ = ""
	squareCount = 0
	FOR iCol = 0 TO $$MaxColumn
		FOR jRow = $$MaxRow TO 0 STEP -1
			colorNum = squareInfo[iCol,jRow].colorNum
			IFZ colorNum THEN EXIT FOR
			IF jRow THEN
				IF (colorNum == squareInfo[iCol,jRow-1].colorNum) THEN gameOver = $$FALSE
			END IF
			IF (iCol < $$MaxColumn) THEN
				IF (colorNum == squareInfo[iCol+1,jRow].colorNum) THEN gameOver = $$FALSE
			END IF
			INC squareCount
			trace$ = trace$ + CHR$(0x30 + colorNum)
		NEXT jRow
		IF (iCol <> $$MaxColumn) trace$ = trace$ + ","
	NEXT iCol

	IF trace THEN
		gameTrace$[moveNumber] = trace$
		FOR iTrace = moveNumber+1 TO UBOUND(gameTrace$[])
			gameTrace$[iTrace] = ""
		NEXT iTrace
	END IF

	squaresLeft = squareCount
	blocksLeft$ = STRING$(squaresLeft)
	XuiSendStringMessage ( blockGrid, "SetTextString", 0, 0, 0, 0, 0, blocksLeft$)
	XuiSendStringMessage ( blockGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)

	IF gameOver THEN
		StopElapsedTime ()
		IFZ squaresLeft THEN
			DisplayText ("You  won")
		ELSE
			DisplayText ("Game\nover\n\n\n\n")
		END IF
	END IF

END FUNCTION
'
'
' ##################################
' #####  GetSaveDirectory$ ()  #####
' ##################################
'
' saveDir$ = GetSaveDirectory$ ()
'
FUNCTION  GetSaveDirectory$ ()
	GOSUB CheckSavePath
	IF saveDir$ THEN
		RETURN saveDir$
	END IF

	title$ = "Add Save Directory"
	message$ = "Do you want to allow this\n program to create the directory\n"
	message$ = message$ + "\n" + $$SaveSubDir$
	message$ = message$ + "\nin\n" + homePath$
	gridTypeName$ = "XuiMessage2B"
	grids$ = "allow\ncancel"
	Message1234Button (title$, message$, grids$, @kid, @reply$)

	IF (kid == 2) THEN
		error = XstMakeDirectory (@fullPath$)
	END IF
	GOSUB CheckSavePath
	IF saveDir$ THEN
		RETURN saveDir$
	END IF
	message$ = "Failed to add Save Directory"
	grids$ = "cancel"
	Message1234Button (title$, message$, grids$, @kid, @reply$)
	RETURN saveDir$
'
'
' *****  CheckSavePath  *****
'
SUB CheckSavePath
	saveDir$ = ""
	homePath$ = XstGetHomePath$ ()
	XstGetFileAttributes (homePath$, @attributes)
	IF (attributes AND $$FileDirectory) THEN
		fullPath$ = homePath$ + $$PathSlash$ + $$SaveSubDir$ + $$PathSlash$
		XstGetFileAttributes (fullPath$, @attributes)
		IF (attributes AND $$FileDirectory) THEN
			saveDir$ = fullPath$
		END IF
	END IF
END SUB
'
END FUNCTION
'
'
' #########################
' #####  LoadGame ()  #####
' #########################
'
FUNCTION  LoadGame ()
	SHARED mainGrid
	SHARED loadGameLabelGrid
	SHARED loadingGame
	SHARED moveNumber
	SHARED gameTrace$[]
	STATIC loadGameCount

	saveDir$ = GetSaveDirectory$ ()

	XstFileSelectSetInfo (saveDir$, "Kittedy*.txt", 100, 0, 50, 50)
	XstFileSelect ("Select Kittedy Game", @filename$)
	IF filename$ THEN
		XstLoadStringArray (filename$, @gameTrace$[])
	END IF

	IF gameTrace$[] THEN
		string$ = gameTrace$[0]
		uWord = XstParseWhitespaceToArray (string$, @word$[])
		IF (uWord != 3) THEN
			GOSUB CheckOldFormat
		ELSE
			SELECT CASE FALSE
				CASE word$[0] == PROGRAM$(0) : GOSUB CheckOldFormat
				CASE word$[1] == "Game"      : GOSUB CheckOldFormat
				CASE word$[2] == "Number"    : GOSUB CheckOldFormat
'				CASE ELSE                    : title$ = string$
				CASE ELSE                    : GOSUB CheckGameNumber
			END SELECT
		END IF
'	title$ = title$ + "  Game  Number " + STR$(selectGame)
	XuiSendStringMessage ( mainGrid, "SetWindowTitle", @window, 0, 0, 0, 0, title$)
	END IF

	IF gameTrace$[] THEN
		moveNumber = 0
		Restart ()
		INC loadGameCount
		text$ = STRING$(loadGameCount)
		XuiSendStringMessage (loadGameLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
		XuiSendStringMessage (loadGameLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
		StartElapsedTime ()
	END IF

	loadingGame = $$TRUE
	FOR i = 0 TO UBOUND(gameTrace$[])
		error = Redo ()
		IF error THEN
			EXIT FOR
		END IF
	NEXT i
	loadingGame = $$FALSE

	RETURN
'
'
' *****  CheckOldFormat  *****
'
SUB CheckOldFormat
	len   = LEN(string$)
	count = XstTally (string$, ",")
	IF ((len == 169) && (count == 9)) THEN   ' looks like old format Kittedy file ?
		DIM s$[0]
		title$ = PROGRAM$(0)
		title$ = title$ + "  Game  File : " + filename$
		s$[0] = title$
		error = XstReplaceLines (@gameTrace$[], @s$[], 0, 0, 0, 1)
	ELSE
		title$ = string$
	END IF
END SUB
'
'
' *****  CheckGameNumber  *****
'
SUB CheckGameNumber
	gameNumber = XLONG(word$[3])
	clorsStart$ = gameTrace$[1]
	ColorShuffle (gameNumber, @colors[])
	len   = LEN(clorsStart$)
	count = XstTally (clorsStart$, ",")
	mismatch = $$TRUE
	IF ((len == 169) && (count == 9)) THEN
		mismatch = 0
		k = 0
		l = 0
		FOR i = 0 TO 9
			FOR j = 15 TO 0 STEP -1
				c = clorsStart${k} - 0x30
				IF (c != colors[(j*10+i)]) THEN
					mismatch = $$TRUE
				END IF
				INC k
				INC l
			NEXT j
			INC k
		NEXT i
	END IF
	IF mismatch THEN
		DIM s$[0]
		title$ = PROGRAM$(0)
		title$ = title$ + "  Game  File : " + filename$
	ELSE
		title$ = string$
	END IF

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

	XuiSendStringMessage (mainGrid, "GetWindowSize", @xw, @yw, 0, 0, 0, 0)
	XuiSendStringMessage (mainGrid, "GetSize", @x, @y, @width, @height, 0, 0)

	w = 300
	h = 150
	x = xw + menuGridsWidth + (baseGridWidth / 2) - (w /2)
	y = yw + y + (height * 5 / 8)

	XuiCreateWindow     (@grid, @wt$, x, y, w, h, 0, "")
	XuiSendStringMessage (grid, "SetFont", 0, 0, 0, 0, 1, @"9x15bold")
	XuiSendStringMessage (grid, "SetTexture", $$TextureFlat, 0, 0, 0, 1, 0)
	XuiSendStringMessage (grid, "SetColor", $$Steel, $$Black, -1, -1, -1, 0)
	XuiGetReply          (grid, title$, message$, grids$, @v0, @v1, @kid, @reply$)
	XuiSendStringMessage (grid, "Destroy", 0, 0, 0, 0, 0, 0)

	IF (kid < 2) THEN
		reply$ = "CloseWindow"
	ELSE
		reply$ = TRIM$(grids$[kid-2])
	END IF

END FUNCTION
'
'
' ########################
' #####  NewGame ()  #####
' ########################
'
' selectGame = $$FALSE to start a game with a random game number
' selectGame = $$TRUE for user to select a specific game number
'
FUNCTION  NewGame (selectGame)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED baseGridWidth
	SHARED borderEqualBackground
	SHARED colorTable[]
	SHARED gameTrace$[]
	SHARED highestNonblankCol
	SHARED mainGrid
	SHARED menuGridsWidth
	SHARED newGameLabelGrid
	SHARED redoCount
	SHARED redoLabelGrid
	SHARED restartCount
	SHARED restartLabelGrid
	SHARED selectGameLabelGrid
	SHARED undoCount
	SHARED undoLabelGrid
	STATIC newGameCount
	STATIC selectGameCount

	gameNumber = XstRandomRange (1, 32000)

	IF selectGame THEN GOSUB SelectGameNumber

	title$ = PROGRAM$(0)
	title$ = title$ + "  Game  Number " + STR$(gameNumber)
	XuiSendStringMessage ( mainGrid, "SetWindowTitle", @window, 0, 0, 0, 0, title$)

	DIM gameTrace$[]
	highestNonblankCol = $$MaxColumn
	moveNumber = 0
	bdColor = colorTable[0]

	ColorShuffle (gameNumber, @colors[])

	IFZ colors[] THEN RETURN
	iColor = 0
	FOR jRow = 0 TO $$MaxRow
		FOR iCol = 0 TO $$MaxColumn
			colorNum = colors[iColor]
			INC iColor
			squareInfo[iCol,jRow].colorNum = colorNum
			bgColor = colorTable[colorNum]
			IF borderEqualBackground THEN bdColor = bgColor
			pbGrid = squareInfo[iCol,jRow].grid
			XuiSendStringMessage (pbGrid, @"SetColor", bgColor, $$Blue, bdColor, $$Black, 0, 0)
			XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)
		NEXT iCol
	NEXT jRow

	GameOverCheck ($$Trace)
	IF selectGame THEN
		INC selectGameCount
		text$ = STRING$(selectGameCount)
		XuiSendStringMessage (selectGameLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
		XuiSendStringMessage (selectGameLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
	ELSE
		INC newGameCount
		text$ = STRING$(newGameCount)
		XuiSendStringMessage (newGameLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
		XuiSendStringMessage (newGameLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
	END IF

	redoCount    = 0
	restartCount = 0
	undoCount    = 0
	text$ = ""
	XuiSendStringMessage (redoLabelGrid,    "SetTextString", 0, 0, 0, 0, 0, text$)
	XuiSendStringMessage (redoLabelGrid,    "RedrawGrid", 0, 0, 0, 0, 0, 0)
	XuiSendStringMessage (restartLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
	XuiSendStringMessage (restartLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
	XuiSendStringMessage (undoLabelGrid,    "SetTextString", 0, 0, 0, 0, 0, text$)
	XuiSendStringMessage (undoLabelGrid,    "RedrawGrid", 0, 0, 0, 0, 0, 0)
	StartElapsedTime ()

	RETURN
'-----------------------------------------------------
'
'
' *****  SelectGameNumber  *****
'
SUB SelectGameNumber
	XuiSendStringMessage (mainGrid, "GetWindowSize", @xw, @yw, 0, 0, 0, 0)
	XuiSendStringMessage (mainGrid, "GetSize", @x, @y, @width, @height, 0, 0)

	w = 300
	h = 150
	x = xw + menuGridsWidth + (baseGridWidth / 2) - (w /2)
	y = yw + y + (height * 5 / 8)

	XuiCreateWindow (@grid, @"XuiDialog2B", x, y, w, h, 0, "")
	XuiSendStringMessage (grid, "SetFont", 0, 0, 0, 0, 1, @"9x15bold")
	XuiSendStringMessage (grid, "SetTexture", $$TextureFlat, 0, 0, 0, 1, 0)
	XuiSendStringMessage (grid, "SetColor", $$Steel, $$Black, -1, -1, -1, 0)

	title$ = "Select a Game"
	message$ = "Select a game number\n\n from 1 to 1,000,000,000"
	grids$ = STR$(gameNumber)
	XuiGetReply (grid, title$, message$, grids$, @v0, @v1, @kid, @reply$)
	XuiSendStringMessage (grid, "Destroy", 0, 0, 0, 0, 0, 0)

	IF (kid == 4) THEN THEN RETURN (-1)  ' cancel button
	IF (kid <> 4) THEN
		value$ = ""
		FOR i = 0 TO UBOUND(reply$)
			char$ = CHR$(reply${i})
			IF char$ <> "," THEN
				value$ = value$ + char$
			END IF
		NEXT i
		gameNumber = XLONG(value$)
	END IF
END SUB

END FUNCTION
'
'
' ############################
' #####  QuitKittedy ()  #####
' ############################
'
FUNCTION  QuitKittedy ()
	SHARED gameOver
	SHARED gameTrace$[]

	IF gameOver THEN RETURN (0)
	IFZ gameTrace$[] THEN RETURN (0)

	title$ = "Quit Kittedy"
	message$ = " Game is not finished "
	grids$ = "quit\ncancel"
	Message1234Button (title$, message$, grids$, @kid, @reply$)

	IF (kid != 2) THEN THEN RETURN (-1)  ' not enter button ?

END FUNCTION
'
'
' ############################
' #####  RaiseColumn ()  #####
' ############################
'
FUNCTION  RaiseColumn (column, row)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED borderEqualBackground
	SHARED colorTable[]

	bdColor = colorTable[0]
	FOR jRow = row TO 1 STEP -1
		pbGrid = squareInfo[column,jRow].grid
		colorNum = squareInfo[column,jRow-1].colorNum
		squareInfo[column,jRow].colorNum = colorNum
		bgColor = colorTable[colorNum]
		IF borderEqualBackground THEN bdColor = bgColor
		XuiSendStringMessage (pbGrid, "SetColor", bgColor, $$Blue, bdColor, $$Green, 0, 0)
		XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)
	NEXT jRow

	pbGrid = squareInfo[column,0].grid
	squareInfo[column,0].colorNum = 0
	bdColor = colorTable[0]
	XuiSendStringMessage (pbGrid, "SetColor", bdColor, $$Blue, bdColor, $$Green, 0, 0)
	XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)

END FUNCTION
'
'
' #####################
' #####  Redo ()  #####
' #####################
'
FUNCTION  Redo ()
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED colorTable[]
	SHARED found[]
	SHARED gameTrace$[]
	SHARED moveNumber
	SHARED redoCount
	SHARED redoLabelGrid

	uTrace = UBOUND(gameTrace$[])
	IF (moveNumber >= uTrace) THEN RETURN $$TRUE

	trace$ = gameTrace$[moveNumber+1]
	IFZ trace$ THEN RETURN $$TRUE
	oldMoveNumber = moveNumber
	INC moveNumber
	FindChange (oldMoveNumber, moveNumber, @iCol, @jRow, "XX")
	Sleep (500)
	DisplayText ("")

	DIM found[$$MaxColumn, $$MaxRow]         ' zero found[] contents
	found[iCol,jRow] = $$TRUE                ' clicked button is marked found

	found = CheckAdjacent (iCol, jRow)

	IFZ found THEN RETURN                    ' if no adjacent with same color do nothing
	squaresLeft = squaresLeft - (found + 1)
	bgColor = colorTable[0]
	bdColor = bgColor
	pbGrid = squareInfo[iCol,jRow].grid
	XuiSendStringMessage (pbGrid, "SetColor", bgColor, $$Blue, bdColor, $$Green, 0, 0)
	XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)

	TumbleAndShift ()


	TraceEntryLoad (moveNumber)

	GameOverCheck ($$NoTrace)
	INC redoCount
	text$ = STRING$(redoCount)
	XuiSendStringMessage (redoLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
	XuiSendStringMessage (redoLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ########################
' #####  Restart ()  #####
' ########################
'
FUNCTION  Restart ()
	SHARED moveNumber
	SHARED redoCount
	SHARED redoLabelGrid
	SHARED restartCount
	SHARED restartLabelGrid
	SHARED undoCount
	SHARED undoLabelGrid
	SHARED gameTrace$[]
'
' On a double restart zero the redo and undo count
'
	IFZ gameTrace$[] THEN
		redoCount = 0
		undoCount = 0
		text$ = ""
		XuiSendStringMessage (redoLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
		XuiSendStringMessage (redoLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
		XuiSendStringMessage (undoLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
		XuiSendStringMessage (undoLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
		RETURN
	END IF

	IF moveNumber THEN INC restartCount
	moveNumber = 1
	TraceEntryLoad (moveNumber)
	GameOverCheck ($$NoTrace)
	IF restartCount THEN
		text$ = STRING$(restartCount)
	ELSE
		text$ = ""
	END IF
	XuiSendStringMessage (restartLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
	XuiSendStringMessage (restartLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
	StartElapsedTime ()

END FUNCTION
'
'
' ##################################
' #####  ResumeElapsedTime ()  #####
' ##################################
'
FUNCTION  ResumeElapsedTime ()
	SHARED grid
	SHARED timerRunning

	IF timerRunning THEN RETURN
	XgrSetGridTimer (grid, 10)
	timerRunning = $$TRUE
END FUNCTION
'
'
' #########################
' #####  SaveGame ()  #####
' #########################
'
FUNCTION  SaveGame ()
	SHARED mainGrid
	SHARED saveGameLabelGrid
	SHARED gameTrace$[]
	STATIC saveGameCount

	IFZ gameTrace$[] THEN RETURN

	saveDir$ = GetSaveDirectory$ ()

	XuiSendStringMessage ( mainGrid, "GetWindowTitle", @window, 0, 0, 0, 0, @title$)
	DO
		space = INSTR (title$, " ")
		IF space THEN
			title$ = LEFT$(title$, space - 1) + MID$(title$, space + 1)
		END IF
	LOOP WHILE space
	DO
		tab = INSTR (title$, "\t")
		IF tab THEN
			title$ = LEFT$(title$, tab - 1) + MID$(title$, tab + 1)
		END IF
	LOOP WHILE space
	file$ = saveDir$ + "/" + title$ + ".txt"
	file$ = XstPathString$ (file$)

	XstFileSelectSetInfo (file$, "Kittedy*.txt", 100, 0, 40, 50)
	XstFileSelect ("Save Kittedy Game", @file$)
	IFZ file$ THEN RETURN
	readable = XstGetFileAttributes (file$, @attributes)
	IF (readable) THEN
		title$ = "Save Game"
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

	error = XstSaveStringArray (file$, @gameTrace$[])

	INC saveGameCount
	text$ = STRING$(saveGameCount)
	XuiSendStringMessage (saveGameLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
	XuiSendStringMessage (saveGameLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)

END FUNCTION
'
' #######################
' #####  Selection  #####
' #######################
'
FUNCTION Selection (grid, message$, v0, v1, iCol, jRow, kid, r1$)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED colorNum
	SHARED colorTable[]
	SHARED controlButtonNames$[]
	SHARED found[]
	SHARED highestNonblankCol
	SHARED squaresLeft

	maxiCol = UBOUND(squareInfo[])
	maxjRow = UBOUND(squareInfo[0,])
	DisplayText ("")                      ' erase any text
	IF (iCol > maxiCol) THEN
		IF (iCol == $$MaxColumn+1) THEN ' this might be a control button
			IFZ v1 THEN
				gridName$ = "zero grid number"
			ELSE
				XuiSendStringMessage (v1, "GetGridName", 0, 0, 0, 0, 0, @gridName$)
			END IF
			SELECT CASE gridName$
				CASE "New Game"    : NewGame  ($$FALSE)
				CASE "Undo"        : Undo     ()
				CASE "Redo"        : Redo     ()
				CASE "Restart"     : Restart  ()
				CASE "Save Game"   : SaveGame ()
				CASE "Select Game" : NewGame  ($$TRUE)
				CASE "Load Game"   : LoadGame ()
				CASE "Quit"        : XuiCallback (v1, #CloseWindow, 0, 0, 0, 0, 0, 0)
				CASE ELSE          : PRINT "Control Push Button =", gridName$
			END SELECT
			GameOverCheck ($$NoTrace)
			RETURN
		ELSE
			PRINT "Out of bounds square row = " jRow : RETURN
		END IF
	END IF
	IF (jRow > maxjRow) THEN PRINT "Out of bounds square jRow = " jRow : RETURN
	colorNum = squareInfo[iCol,jRow].colorNum

	DIM found[$$MaxColumn, $$MaxRow]         ' zero found[] contents
	found[iCol,jRow] = $$TRUE                ' clicked button is marked found

	found = CheckAdjacent (iCol, jRow)

	IFZ found THEN RETURN                    ' if no adjacent with same color do nothing
	squaresLeft = squaresLeft - (found + 1)
	bgColor = colorTable[0]
	bdColor = bgColor
	pbGrid = squareInfo[iCol,jRow].grid
	XuiSendStringMessage (pbGrid, "SetColor", bgColor, $$Blue, bdColor, $$Green, 0, 0)
	XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)

	TumbleAndShift ()
	GameOverCheck ($$Trace)

	RETURN

END FUNCTION
'
'
' #############################
' #####  ShiftColumns ()  #####
' #############################
'
FUNCTION  ShiftColumns ()
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED borderEqualBackground
	SHARED colorTable[]
	SHARED highestNonblankCol

	Sleep (200)
	maxRow = $$MaxRow
	FOR column = $$MaxColumn TO 0 STEP -1
		colorNum = squareInfo[column,maxRow].colorNum
		IF colorNum THEN
			highestNonblankCol = column
			EXIT FOR
		END IF
	NEXT column

	FOR column = highestNonblankCol-1 TO 0 STEP -1
		colorNum = squareInfo[column,maxRow].colorNum
		IFZ colorNum THEN GOSUB DoShift
	NEXT column

RETURN

' -----------------------------------------------
'
' *****  DoShift  *****
'
SUB DoShift
	FOR iCol = column TO highestNonblankCol
		FOR jRow = 0 TO $$MaxRow
			pbGrid = squareInfo[iCol,jRow].grid
			IF (iCol = $$MaxColumn) THEN
				colorNum = 0
			ELSE
				colorNum = squareInfo[iCol+1,jRow].colorNum
			END IF
			squareInfo[iCol,jRow].colorNum = colorNum
			bgColor = colorTable[colorNum]
			IF borderEqualBackground THEN
				bdColor = bgColor
			ELSE
				bdColor = colorTable[0]
			END IF
			XuiSendStringMessage (pbGrid, "SetColor", bgColor, $$Blue, bdColor, $$Green, 0, 0)
			XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)
		NEXT jRow
	NEXT iCol
	DEC highestNonblankCol

END SUB

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
' #################################
' #####  StartElapsedTime ()  #####
' #################################
'
FUNCTION  StartElapsedTime ()
	SHARED grid
	SHARED GIANT startfiletime
	SHARED timeGrid
	SHARED timerRunning

	XstGetLocalDateAndTime (@year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
	XstDateAndTimeToFileTime (year, month, day, weekDay, hour, minute, second, nanos, @filetime$$)
	startfiletime = filetime$$
	XuiSendStringMessage ( timeGrid, "SetTextString", 0, 0, 0, 0, 0, "00:00:00")
	msec = 1000 - (nanos/1000000)
	XgrSetGridTimer (grid, msec)
	timerRunning = $$TRUE
END FUNCTION
'
'
' ################################
' #####  StopElapsedTime ()  #####
' ################################
'
FUNCTION  StopElapsedTime ()
	SHARED grid
	SHARED timerRunning

	XgrSetGridTimer (grid, 0)
	timerRunning = $$FALSE
END FUNCTION
'
'
' ###############################
' #####  TraceEntryLoad ()  #####
' ###############################
'
FUNCTION  TraceEntryLoad (entryNumber)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED borderEqualBackground
	SHARED colorTable[]
	SHARED gameTrace$[]

	IFZ gameTrace$[] THEN RETURN
	IFZ entryNumber THEN RETURN

	trace$ = gameTrace$[entryNumber]
	traceLen = LEN(trace$)
	iCol = 0                           ' left
	jRow = $$MaxRow                    ' bottom
	bdColor = colorTable[0]

	FOR tracePos = 1 TO traceLen
		chr$ = MID$(trace$, tracePos, 1)
		IF (chr$ == ",") THEN
'
' A comma at the start of a column is actually
' for the end of the previous column, ignor it
' Otherwise make sure the rest of the column is color zero
'
			IF (jRow == $$MaxRow) THEN DO NEXT
			DO
				colorNum = squareInfo[iCol,jRow].colorNum
				IF colorNum THEN
					pbGrid = squareInfo[iCol,jRow].grid
					squareInfo[iCol,jRow].colorNum = 0
					bgColor = colorTable[0]
					XuiSendStringMessage (pbGrid, @"SetColor", bgColor, $$Blue, bgColor, $$Black, 0, 0)
					XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)
				END IF
				DEC jRow
				IF (jRow < 0) THEN EXIT DO
			LOOP
			INC iCol
			IF (iCol > $$MaxColumn) THEN EXIT FOR
			jRow = $$MaxRow
			DO NEXT
		ELSE
			colorNum = ASC(chr$) AND 0x7
			IF ((colorNum < 1) OR (colorNum >5)) THEN
				PRINT "TraceLoadEntry() Invalid color number", entryNumber, iCol, jRow, colorNum, chr$
				DO NEXT
			END IF
		END IF
		squareInfo[iCol,jRow].colorNum = colorNum
		bgColor = colorTable[colorNum]
		IF borderEqualBackground THEN bdColor = bgColor
		pbGrid = squareInfo[iCol,jRow].grid
		XuiSendStringMessage (pbGrid, @"SetColor", bgColor, $$Blue, bdColor, $$Black, 0, 0)
		XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)

		DEC jRow
		IF (jRow < 0) THEN
			jRow = $$MaxRow
			INC iCol
			IF (iCol > $$MaxColumn) THEN EXIT FOR
		END IF
	NEXT tracePos
'
' end of the trace entry
' The remaining squares should be marked and drawn black
'
	DO
		IF (iCol > $$MaxColumn) THEN EXIT DO
		pbGrid = squareInfo[iCol,jRow].grid
		squareInfo[iCol,jRow].colorNum = 0
		bgColor = colorTable[0]
		XuiSendStringMessage (pbGrid, @"SetColor", bgColor, $$Blue, bgColor, $$Black, 0, 0)
		XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)

		DEC jRow
		IF (jRow < 0) THEN
			jRow = $$MaxRow
			INC iCol
			IF (iCol > $$MaxColumn) THEN EXIT DO
		END IF
	LOOP

END FUNCTION
'
'
' ###############################
' #####  TumbleAndShift ()  #####
' ###############################
'
FUNCTION  TumbleAndShift ()
	SHARED found[]

	Sleep (150)
	doBlankColCheck = $$FALSE
	FOR jRow = 0 TO $$MaxRow
		IF tumbled THEN Sleep (100)
		tumbled = $$FALSE
		FOR iCol = 0 TO $$MaxColumn
			IF found[iCol,jRow] THEN
				TumbleColumn (iCol, jRow)
				tumbled = $$TRUE
				IF(jRow = $$MaxRow) THEN
					IFZ doBlankColCheck THEN doBlankColCheck = $$TRUE
				END IF
			END IF
		NEXT iCol
	NEXT jRow

	IFZ highestNonblankCol THEN highestNonblankCol = $$MaxColumn
	IF doBlankColCheck THEN ShiftColumns ()

END FUNCTION
'
'
' #############################
' #####  TumbleColumn ()  #####
' #############################
'
FUNCTION  TumbleColumn (column, row)
	SHARED SQUAREINFORMATION squareInfo[]
	SHARED borderEqualBackground
	SHARED colorTable[]

	bdColor = colorTable[0]
	FOR jRow = row TO 1 STEP -1
		pbGrid = squareInfo[column,jRow].grid
		colorNum = squareInfo[column,jRow-1].colorNum
		squareInfo[column,jRow].colorNum = colorNum
		bgColor = colorTable[colorNum]
		IF borderEqualBackground THEN bdColor = bgColor
		XuiSendStringMessage (pbGrid, "SetColor", bgColor, $$Blue, bdColor, $$Green, 0, 0)
		XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)
	NEXT jRow

	pbGrid = squareInfo[column,0].grid
	squareInfo[column,0].colorNum = 0
	bdColor = colorTable[0]
	XuiSendStringMessage (pbGrid, "SetColor", bdColor, $$Blue, bdColor, $$Green, 0, 0)
	XuiSendStringMessage (pbGrid, @"RedrawGrid", 0, 0, 0, 0, 0, 0)

END FUNCTION
'
'
' #####################
' #####  Undo ()  #####
' #####################
'
FUNCTION  Undo ()
	SHARED moveNumber
	SHARED undoLabelGrid
	SHARED undoCount

	IF (moveNumber < 2) THEN RETURN

	oldMoveNumber = moveNumber
	DEC moveNumber
	TraceEntryLoad (moveNumber)
	FindChange (oldMoveNumber, moveNumber, @iCol, @jRow, "**")
	GameOverCheck ($$NoTrace)
	INC undoCount
	text$ = STRING$(undoCount)
	XuiSendStringMessage (undoLabelGrid, "SetTextString", 0, 0, 0, 0, 0, text$)
	XuiSendStringMessage (undoLabelGrid, "RedrawGrid", 0, 0, 0, 0, 0, 0)
	ResumeElapsedTime ()
END FUNCTION
END PROGRAM

'
' #######################
' #####  IMPORTANT  #####
' #######################
'
' !!! This is NOT a program !!!
' !!! This file will not compile or execute !!!
'
' This is a collection of grids aka grid functions.
' This is meant to help you design / modify your own grid functions.
'
' These functions work, but are not guaranteed to be bug-free, since
' this file is not kept up to date when bugs are fixed and enhancements
' made in subsequent GraphicsDesigner and GuiDesigner releases.
'
' Note that you cannot imbed these functions in your programs without
' renaming the functions and grid types because the function and grid
' type names are already defined in GuiDesigner.
'
DECLARE FUNCTION  XuiCheckBox     (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiColor        (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiDialog2B     (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiDialog3B     (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiDialog4B     (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiDropBox      (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiDropButton   (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiLabel        (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiListBox      (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiListButton   (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiListDialog2B (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiMessage1B    (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiMessage2B    (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiMessage3B    (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiMessage4B    (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiPressButton  (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiProgress     (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiPushButton   (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiRadioBox     (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiRadioButton  (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiRange        (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiScrollBarH   (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiScrollBarV   (grid, message, v0, v1, v2, v3, r0, ANY)
DECLARE FUNCTION  XuiToggleButton (grid, message, v0, v1, v2, v3, r0, ANY)
'
'
' ############################
' #####  XuiCheckBox ()  #####
' ############################
'
FUNCTION  XuiCheckBox (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR		sub[]
	STATIC	upperMessage
	STATIC	XuiCheckBox
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiCheckBox) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiCheckBox, @v0, @v1, @v2, @v3, r0, r1, &XuiCheckBox())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiCheckBox")
END SUB
'
'
' *****  KeyDown  *****  #Selection callback on $$KeyEnter
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, 0, 0, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	state = v2																			' v2 = state
	key = state{8,24}																' virtual key
	IF (state AND $$AltBit) THEN EXIT SUB						' disallow Alt+Enter
	IF (key = $$KeyEnter) THEN GOSUB Selected				' got Enter
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	GOSUB Selected
END SUB
'
'
' *****  Selected  *****
'
SUB Selected
	XuiGetValue (grid, #GetValue, @state, 0, 0, 0, 0, 0)
	IF state THEN state = $$FALSE ELSE state = $$TRUE
	XuiSetValue (grid, #SetValue, state, 0, 0, 0, 0, 0)
	GOSUB RedrawGrid
	XuiCallback (grid, #Selection, state, 0, v2, v3, 0, grid)
END SUB
'
'
' *****  RedrawGrid  *****
'
SUB RedrawGrid
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	width = x2 - x1 + 1 : height = y2 - y1 + 1
	XuiGetValue (grid, #GetValue, @state, 0, 0, 0, 0, 0)
	XuiGetColor (grid, #GetColor, @back, @draw, @lo, @hi, 0, 0)
	XuiGetColorExtra (grid, #GetColorExtra, 0, @acc, 0, 0, 0, 0)
	XuiGetIndent (grid, #GetIndent, @inX, @inY, 0, 0, 0, @bw)
	xx = x1 + ((inX - 12) >> 1) + bw - 1 : yy = y1 + (height >> 1) - 6
	XgrDrawBorder (grid, $$BorderLower2, back, lo, hi, xx, yy, xx+11, yy+11)
	IF state THEN base = acc ELSE base = back
	XgrFillBox (grid, base, xx+2, yy+2, xx+9, yy+9)
	IF state THEN
		XgrDrawLine (grid, draw, xx+4, yy+3, xx+8, yy+7)
		XgrDrawLine (grid, draw, xx+3, yy+3, xx+8, yy+8)
		XgrDrawLine (grid, draw, xx+3, yy+4, xx+7, yy+8)
		XgrDrawLine (grid, draw, xx+3, yy+7, xx+7, yy+3)
		XgrDrawLine (grid, draw, xx+3, yy+8, xx+8, yy+3)
		XgrDrawLine (grid, draw, xx+4, yy+8, xx+8, yy+4)
	END IF
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Redraw]							= 0
	func[#RedrawGrid]					= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#KeyDown]							= SUBADDRESS (KeyDown)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#Redraw]							= SUBADDRESS (RedrawGrid)
	sub[#RedrawGrid]					= SUBADDRESS (RedrawGrid)
'
	IF func[0] THEN PRINT "XuiCheckBox() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiCheckBox() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiCheckBox, @"XuiCheckBox", &XuiCheckBox(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 20
'
	gridType = XuiCheckBox
	XuiSetGridTypeValue (gridType, @"x",            designX)
	XuiSetGridTypeValue (gridType, @"y",            designY)
	XuiSetGridTypeValue (gridType, @"width",        designWidth)
	XuiSetGridTypeValue (gridType, @"height",       designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",     32)
	XuiSetGridTypeValue (gridType, @"minHeight",    16)
	XuiSetGridTypeValue (gridType, @"indentLeft",   24)
	XuiSetGridTypeValue (gridType, @"align",        $$AlignMiddleLeft)
	XuiSetGridTypeValue (gridType, @"border",       $$BorderRaise1)
	XuiSetGridTypeValue (gridType, @"borderUp",     $$BorderRaise1)
	XuiSetGridTypeValue (gridType, @"borderDown",   $$BorderRaise1)
	XuiSetGridTypeValue (gridType, @"texture",      $$TextureLower1)
	XuiSetGridTypeValue (gridType, @"can",          $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",  $$RedrawDefault)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #########################
' #####  XuiColor ()  #####
' #########################
'
FUNCTION  XuiColor (grid, message, v0, v1, v2, v3, r0, r1)
  STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR		sub[]
	STATIC	upperMessage
	STATIC	XuiColor
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiColor) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiColor, @v0, @v1, @v2, @v3, r0, r1, &XuiColor())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiColor")
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	top = y1
	left = x1
	right = x2
	bottom = y2
	IF (v1 < top) THEN EXIT SUB
	IF (v0 < left) THEN EXIT SUB
	IF (v0 > right) THEN EXIT SUB
	IF (v1 > bottom) THEN EXIT SUB
	row = (v1 - top) >> 4
	col = (v0 - left) >> 3
	color = row * 25 + col
	XgrConvertColorToRGB (color, @red, @green, @blue)
	XuiCallback (grid, #Selection, color, red, green, blue, color, grid)
END SUB
'
'
' *****  Redraw  *****
'
SUB Redraw
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	colorNumber = 0
	FOR i = 0 TO 4
		FOR j = 0 TO 24
			x1 = j *  8:	x2 = x1 +  7
			y1 = i * 16:	y2 = y1 + 15
			XgrFillBox (grid, colorNumber, x1, y1, x2, y2)
			INC colorNumber
		NEXT j
	NEXT i
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#GetSmallestSize]		= &XuiGetMaxMinSize ()
	func[#Redraw]							= 0
	func[#RedrawGrid]					= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#Redraw]							= SUBADDRESS (Redraw)
	sub[#RedrawGrid]					= SUBADDRESS (Redraw)
'
	IF func[0] THEN PRINT "XuiColor() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiColor() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiColor, @"XuiColor", &XuiColor(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 200
	designHeight = 80
'
	gridType = XuiColor
	XuiSetGridTypeValue (gridType, @"x",              designX)
	XuiSetGridTypeValue (gridType, @"y",              designY)
	XuiSetGridTypeValue (gridType, @"width",          designWidth)
	XuiSetGridTypeValue (gridType, @"height",         designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",       designWidth)
	XuiSetGridTypeValue (gridType, @"minHeight",      designHeight)
	XuiSetGridTypeValue (gridType, @"maxWidth",       designWidth)
	XuiSetGridTypeValue (gridType, @"maxHeight",      designHeight)
	XuiSetGridTypeValue (gridType, @"can",            $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",    $$RedrawNone)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ############################
' #####  XuiDialog2B ()  #####  Label, TextLine, and 2 PushButtons
' ############################
'
FUNCTION  XuiDialog2B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiDialog2B
'
	$XuiDialog2B	= 0
	$Label				= 1
	$TextLine			= 2
	$Button0			= 3
	$Button1			= 4
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiDialog2B) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
	message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiDialog2B, @v0, @v1, @v2, @v3, r0, r1, &XuiDialog2B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiTextLine    (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDialog2B(), -1, -1, $TextLine, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLine")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDialog2B(), -1, -1, $Button0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDialog2B(), -1, -1, $Button1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiDialog2B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @labelWidth, @labelHeight, $Label, 8)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @textWidth, @textHeight, $TextLine, 8)
'
	buttonWidth = 8
	buttonHeight = 8
	FOR i = $Button0 TO $Button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth
	IF (width < labelWidth) THEN width = labelWidth
	v2 = width + bw + bw
	v3 = labelHeight + buttonHeight + textHeight + bw + bw
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
'
	h = labelHeight + buttonHeight + textHeight + bw + bw
	IF (v3 >= h + 4) THEN
		buttonHeight = buttonHeight + 4 : h = h + 4
		IF (v3 >= h + 4) THEN textHeight = textHeight + 4
	END IF
'
	labelWidth	= v2 - bw - bw
	labelHeight	= v3 - buttonHeight - textHeight - bw - bw
	buttonWidth	= labelWidth >> 1
	w0					= buttonWidth
	w1					= labelWidth - w0
'
	x = bw
	y = bw
	w = labelWidth
	XuiSendToKid (grid, #Resize, x, y, w, labelHeight, $Label, 0)
'
	y = y + labelHeight
	XuiSendToKid (grid, #Resize, x, y, w, textHeight, $TextLine, 0)
'
	h = buttonHeight
	y = y + textHeight
	XuiSendToKid (grid, #Resize, x, y, w0, h, $Button0, 0) : x = x + w0
	XuiSendToKid (grid, #Resize, x, y, w1, h, $Button1, 0) : x = x + w1
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]           = &XuiCallback()
	func[#GetSmallestSize]    = 0
	func[#Resize]             = 0
'
	DIM sub[upperMessage]
  sub[#Callback]            = SUBADDRESS (Callback)
	sub[#Create]              = SUBADDRESS (Create)
	sub[#CreateWindow]        = SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)
	sub[#Resize]              = SUBADDRESS (Resize)
  sub[#Selection]						= SUBADDRESS (Selection)
'
	IF func[0] THEN PRINT "XuiDialog2B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiDialog2B() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiDialog2B, @"XuiDialog2B", &XuiDialog2B(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 160
	designHeight = 68
'
	gridType = XuiDialog2B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        64)
	XuiSetGridTypeValue (gridType, @"minHeight",       24)
'	XuiSetGridTypeValue (gridType, @"minWidth",        designWidth)
'	XuiSetGridTypeValue (gridType, @"minHeight",       designHeight)
'	XuiSetGridTypeValue (gridType, @"maxWidth",        designWidth)
'	XuiSetGridTypeValue (gridType, @"maxHeight",       designHeight)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeValue (gridType, @"focusKid",        $TextLine)
	XuiSetGridTypeValue (gridType, @"inputTextString", $TextLine)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ############################
' #####  XuiDialog3B ()  #####  Label, TextLine, 3 PushButtons
' ############################
'
FUNCTION  XuiDialog3B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
  STATIC	SUBADDR  sub[]
	STATIC	upperMessage
  STATIC	XuiDialog3B
'
  $XuiDialog3B   =  0  ' kid  0 grid type = XuiDialog3B
  $Label         =  1  ' kid  1 grid type = XuiLabel
  $TextLine      =  2  ' kid  2 grid type = XuiTextLine
  $Button0       =  3  ' kid  3 grid type = XuiPushButton
  $Button1       =  4  ' kid  4 grid type = XuiPushButton
  $Button2       =  5  ' kid  5 grid type = XuiPushButton
'
  IFZ sub[] THEN GOSUB Initialize
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiDialog3B) THEN RETURN
  GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
	callback = message
  IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
  XuiCreateGrid  (@grid, XuiDialog3B, @v0, @v1, @v2, @v3, r0, r1, &XuiDialog3B())
  XuiLabel       (@g, #Create, 4, 4, 312, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
  XuiTextLine    (@g, #Create, 4, 24, 312, 24, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog3B(), -1, -1, $TextLine, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLine")
  XuiPushButton  (@g, #Create, 4, 48, 104, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog3B(), -1, -1, $Button0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
  XuiPushButton  (@g, #Create, 108, 48, 104, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog3B(), -1, -1, $Button1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Retry")
  XuiPushButton  (@g, #Create, 212, 48, 104, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog3B(), -1, -1, $Button2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
  GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
  XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
  v0 = 0 : v1 = 0 : r0 = window : display$ = r1$ : r1 = 0
  GOSUB Create
	r1 = 0 : r1$ = display$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiDialog3B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @labelWidth, @labelHeight, $Label, 8)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @textWidth, @textHeight, $TextLine, 8)
'
	buttonWidth = 8
	buttonHeight = 8
	FOR i = $Button0 TO $Button2
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth + buttonWidth
	IF (width < labelWidth) THEN width = labelWidth
	v2 = width + bw + bw
	v3 = labelHeight + buttonHeight + textHeight + bw + bw
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
'
	h = labelHeight + buttonHeight + textHeight + bw + bw
	IF (v3 >= (h + 4)) THEN h = h + 4 : buttonHeight = buttonHeight + 4
	IF (v3 >= (h + 4)) THEN h = h + 4 : textHeight = textHeight + 4
	IF (v3 >= (h + 4)) THEN h = h + 4 : labelHeight = labelHeight + 4
'
	labelWidth	= v2 - bw - bw
	labelHeight	= v3 - buttonHeight - textHeight - bw - bw
	buttonWidth	= labelWidth \ 3
	w0 = buttonWidth
	w1 = labelWidth - w0 - w0
	w2 = buttonWidth
'
	x = bw
	y = bw
	w = labelWidth
	XuiSendToKid (grid, #Resize, x, y, w, labelHeight, $Label, 0)
'
	y = y + labelHeight
	XuiSendToKid (grid, #Resize, x, y, w, textHeight, $TextLine, 0)
'
	h = buttonHeight
	y = y + textHeight
	XuiSendToKid (grid, #Resize, x, y, w0, h, $Button0, 0) : x = x + w0
	XuiSendToKid (grid, #Resize, x, y, w1, h, $Button1, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w2, h, $Button2, 0) : x = x + w2
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
'
	IF func[0] THEN PRINT "XuiDialog3B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiDialog3B() : Initialize : error ::: (undefined message)"
  XuiRegisterGridType (@XuiDialog3B, "XuiDialog3B", &XuiDialog3B(), @func[], @sub[])
'
  designX = 0
  designY = 0
  designWidth = 240
  designHeight = 68
'
	gridType = XuiDialog3B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        64)
	XuiSetGridTypeValue (gridType, @"minHeight",       24)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeValue (gridType, @"focusKid",         $TextLine)
	XuiSetGridTypeValue (gridType, @"inputTextString",  $TextLine)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ############################
' #####  XuiDialog4B ()  #####  Label, TextLine, 4 PushButtons
' ############################
'
FUNCTION  XuiDialog4B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
  STATIC	SUBADDR  sub[]
	STATIC	upperMessage
  STATIC	XuiDialog4B
'
  $XuiDialog4B   =  0  ' kid  0 grid type = XuiDialog4B
  $Label         =  1  ' kid  1 grid type = XuiLabel
  $TextLine      =  2  ' kid  2 grid type = XuiTextLine
  $Button0       =  3  ' kid  3 grid type = XuiPushButton
  $Button1       =  4  ' kid  4 grid type = XuiPushButton
  $Button2       =  5  ' kid  5 grid type = XuiPushButton
  $Button3       =  6  ' kid  6 grid type = XuiPushButton
'
  IFZ sub[] THEN GOSUB Initialize
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiDialog4B) THEN RETURN
  GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
	callback = message
  IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
  XuiCreateGrid  (@grid, XuiDialog4B, @v0, @v1, @v2, @v3, r0, r1, &XuiDialog4B())
  XuiLabel       (@g, #Create, 4, 4, 312, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
  XuiTextLine    (@g, #Create, 4, 24, 312, 24, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog4B(), -1, -1, $TextLine, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLine")
  XuiPushButton  (@g, #Create, 4, 48, 104, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog4B(), -1, -1, $Button0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
  XuiPushButton  (@g, #Create, 108, 48, 104, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog4B(), -1, -1, $Button1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Update")
  XuiPushButton  (@g, #Create, 212, 48, 104, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog4B(), -1, -1, $Button2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Retry")
  XuiPushButton  (@g, #Create, 212, 48, 104, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &XuiDialog4B(), -1, -1, $Button3, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button3")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
  GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
  XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
  v0 = 0 : v1 = 0 : r0 = window : display$ = r1$ : r1 = 0
  GOSUB Create
	r1 = 0 : r1$ = display$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiDialog4B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @labelWidth, @labelHeight, $Label, 8)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @textWidth, @textHeight, $TextLine, 8)
'
	buttonWidth = 8
	buttonHeight = 8
	FOR i = $Button0 TO $Button3
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth << 2
	IF (width < labelWidth) THEN width = labelWidth
	v2 = width + bw + bw
	v3 = labelHeight + buttonHeight + textHeight + bw + bw
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
'
	h = labelHeight + buttonHeight + textHeight + bw + bw
	IF (v3 >= (h + 4)) THEN h = h + 4 : buttonHeight = buttonHeight + 4
	IF (v3 >= (h + 4)) THEN h = h + 4 : textHeight = textHeight + 4
	IF (v3 >= (h + 4)) THEN h = h + 4 : labelHeight = labelHeight + 4
'
	labelWidth	= v2 - bw - bw
	labelHeight	= v3 - buttonHeight - textHeight - bw - bw
	buttonWidth	= labelWidth >> 2
	w0 = buttonWidth
	w1 = w0
	w2 = w1
	w3 = labelWidth - w0 - w1 - w2
'
	x = bw
	y = bw
	w = labelWidth
	XuiSendToKid (grid, #Resize, x, y, w, labelHeight, $Label, 0)
'
	y = y + labelHeight
	XuiSendToKid (grid, #Resize, x, y, w, textHeight, $TextLine, 0)
'
	h = buttonHeight
	y = y + textHeight
	XuiSendToKid (grid, #Resize, x, y, w0, h, $Button0, 0) : x = x + w0
	XuiSendToKid (grid, #Resize, x, y, w1, h, $Button1, 0) : x = x + w1
	XuiSendToKid (grid, #Resize, x, y, w2, h, $Button2, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w3, h, $Button3, 0) : x = x + w3
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
'
	IF func[0] THEN PRINT "XuiDialog4B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiDialog4B() : Initialize : error ::: (undefined message)"
  XuiRegisterGridType (@XuiDialog4B, "XuiDialog4B", &XuiDialog4B(), @func[], @sub[])
'
  designX = 0
  designY = 0
  designWidth = 320
  designHeight = 68
'
	gridType = XuiDialog4B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        64)
	XuiSetGridTypeValue (gridType, @"minHeight",       24)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeValue (gridType, @"focusKid",         $TextLine)
	XuiSetGridTypeValue (gridType, @"inputTextString",  $TextLine)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###########################
' #####  XuiDropBox ()  #####
' ###########################
'
FUNCTION  XuiDropBox (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR		sub[]
	STATIC	upperMessage
	STATIC	XuiDropBox
	STATIC	monitor
'
	$DropBox	= 0
	$Text			= 1
	$Button		= 2
	$PullDown	= 3
'
	$Style0		= 0			' list goes up/down, text line editable
	$Style1		= 1			' list always down, text line editable
	$Style2		= 2			' list goes up/down, text line not editable
	$Style3		= 3			' list always down, text line not editable
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiDropBox) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiDropBox, @v0, @v1, 128, 20, r0, r1, &XuiDropBox())
	XuiTextLine    (@g, #Create, 0, 0, 108, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDropBox(), -1, -1, $Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLine")
	XuiPressButton (@g, #Create, 108, 0, 20, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDropBox(), -1, -1, $Button, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PressButton")
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderRaise1, 0, 0, 0)
	XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetStyle, $$TriangleDown, 0, 0, 0, 0, 0)
	GOSUB CreatePullDown
	GOSUB Resize
END SUB
'
'
' *****  CreatePullDown  *****
'
SUB CreatePullDown
	XgrGetGridWindow (grid, @window)
	XgrConvertWindowToDisplay (grid, v0, v1+20, @xDisp, @yDisp)
	windowType = $$WindowTypeTopMost OR $$WindowTypeNoSelect OR $$WindowTypeNoFrame OR window
	XuiPullDown    (@g, #CreateWindow, xDisp, yDisp, v2, v3, windowType, 0)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDropBox(), -1, -1, $PullDown, grid)
	XuiSetValues (grid, #SetValues, g, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiDropBox")
END SUB
'
'
' *****  Destroy  *****
'
SUB Destroy
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendMessage (pulldown, #Destroy, 0, 0, 0, 0, 0, 0)
	XuiDestroy (grid, #Destroy, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  GetTextArray  *****
'
SUB GetTextArray
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendMessage (pulldown, #GetTextArray, 0, 0, 0, 0, 0, @r1$[])
END SUB
'
'
' *****  GetTextCursor  *****
'
SUB GetTextCursor
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendMessage (pulldown, #GetTextCursor, 0, @v1, 0, 0, 0, 0)
	XuiSendMessage (grid, #GetTextCursor, @v0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  GetTextString  *****
'
SUB GetTextString
	XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @r1$)
END SUB
'
'
' *****  Monitor  *****
'
SUB Monitor
	XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiDropBox(), 0, 0, 0, monitor)
	XuiMonitorContext (grid, #MonitorContext, grid, &XuiDropBox(), 0, 0, 0, monitor)
END SUB
'
'
' *****  MouseDown  *****  caused by #MonitorMouse
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IFZ pullstate THEN EXIT SUB
	IFZ pulldown THEN EXIT SUB
	IFZ monitor THEN EXIT SUB
	IFZ r1 THEN EXIT SUB
	gg = r1
'
	IF XuiGridContainsGridCoord (pulldown, gg, v0, v1, @xx, @yy) THEN
		XuiSendMessage (pulldown, message, xx, yy, v2, v3, 0, pulldown)
		r0 = -1
	ELSE
		IFZ (style AND 1) THEN GOSUB PullUp
		XuiSendToKid (grid, #GetGridNumber, @gb, 0, 0, 0, $Button, 0)
		IF XuiGridContainsGridCoord (gb, gg, v0, v1, 0, 0) THEN r0 = -1
	END IF
END SUB
'
'
' *****  MouseDrag  *****  caused by #MonitorMouse
'
SUB MouseDrag
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IFZ pullstate THEN EXIT SUB
	IFZ pulldown THEN EXIT SUB
	IFZ monitor THEN EXIT SUB
	IFZ r1 THEN EXIT SUB
	gg = r1
'
	IF XuiGridContainsGridCoord (pulldown, gg, v0, v1, @xx, @yy) THEN
		XuiSendMessage (pulldown, message, xx, yy, v2, v3, 0, pulldown)
	END IF
	r0 = -1
END SUB
'
'
' *****  MouseUp  *****  caused by #MonitorMouse
'
SUB MouseUp
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IFZ pullstate THEN EXIT SUB
	IFZ pulldown THEN EXIT SUB
	IFZ monitor THEN EXIT SUB
	IFZ r1 THEN EXIT SUB
	gg = r1
'
	IF XuiGridContainsGridCoord (pulldown, gg, v0, v1, @xx, @yy) THEN
		XuiSendMessage (pulldown, message, xx, yy, v2, v3, 0, pulldown)
	ELSE
		IFZ (style AND 1) THEN
			XuiSendToKid (grid, #GetGridNumber, @gb, 0, 0, 0, $Button, 0)
			IFZ XuiGridContainsGridCoord (gb, gg, v0, v1, 0, 0) THEN GOSUB PullUp
		END IF
	END IF
	r0 = -1
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF (v2 < (v3 + 32)) THEN v2 = v3 + 32
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	x1 = 0 : y1 = 0 : w1 = v2 - v3
	x2 = v2 - v3 : y2 = 0 : w2 = v3
	XuiSendToKid (grid, #Resize, x1, y1, w1, v3, $Text, 0)
	XuiSendToKid (grid, #Resize, x2, y2, w2, v3, $Button, 0)
	XuiSendMessage (pulldown, #Resize, 0, 0, 0, 0, 0, 0)
	XgrGetGridWindow (pulldown, @pullWindow)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (pullWindow, xDrop, yDrop, -1, -1)
	XuiSendMessage (pulldown, #Resize, 0, 0, x2-x1+1, 0, 0, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
'
	SELECT CASE r0
		CASE $Text			: item = -1
											IFZ (style AND 1) THEN GOSUB PullUp
											XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @text$)
											XuiSetTextString (grid, #SetTextString, 0, 0, 0, 0, 0, @text$)
											XuiSendMessage (pulldown, #GetTextArray, 0, 0, 0, 0, 0, @text$[])
											IF text$[] THEN
												upper = UBOUND (text$[])
												FOR i = 0 TO upper
													IF (text$ = text$[i]) THEN item = i : EXIT FOR
												NEXT i
											END IF
											XuiSendMessage (pulldown, #SetTextCursor, 0, @item, 0, 0, 0, 0)
											XuiCallback (grid, #Selection, item, 0, 0, 0, 0, 0)
		CASE $Button		:	IF (style AND 1) THEN GOSUB PullDown ELSE GOSUB PullToggle
		CASE $PullDown	: XuiSendMessage (pulldown, #GetTextArray, 0, 0, 0, 0, 0, @text$[])
											XuiSendMessage (pulldown, #GetTextCursor, @cp, @cl, 0, 0, 0, 0)
											IF ((v0 >= 0) AND (v0 <= UBOUND(text$[]))) THEN
												text$ = text$[v0]
												under = INSTR(text$, "_")
												IF under THEN text$ = LEFT$(text$,under-1) + MID$(text$, under+1)
												XuiSetTextString (grid, #SetTextString, 0, 0, 0, 0, 0, @text$)
												XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @text$)
												XuiSendToKid (grid, #Redraw, 0, 0, 0, 0, $Text, 0)
												XuiSendToKid (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Text, 0)
											END IF
											IFZ (style AND 1) THEN GOSUB PullUp
											XuiCallback (grid, #Selection, v0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  PullDown  *****
'
SUB PullDown
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF pullstate THEN EXIT SUB
	XgrGetGridWindow (grid, @window)
	XgrGetGridWindow (pulldown, @pullWindow)
	XuiSetValue (grid, #SetValue, $$TRUE, 0, 0, 0, 0, 1)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (pullWindow, xDrop, yDrop, -1, -1)
	XuiSendMessage (pulldown, #ShowWindow, 0, 0, 0, 0, 0, 0)
	monitor = $$TRUE
	GOSUB Monitor
END SUB
'
'
' *****  PullUp  *****
'
SUB PullUp
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IFZ pullstate THEN EXIT SUB
	XgrGetGridWindow (grid, @window)
	XgrGetGridWindow (pulldown, @pullWindow)
	XuiSetValue (grid, #SetValue, $$FALSE, 0, 0, 0, 0, 1)
	XuiSendMessage (pulldown, #HideWindow, 0, 0, 0, 0, 0, 0)
	monitor = $$FALSE
	GOSUB Monitor
END SUB
'
'
' *****  PullToggle  *****
'
SUB PullToggle
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF pullstate THEN GOSUB PullUp ELSE GOSUB PullDown
END SUB
'
'
' *****  SetStyle  *****
'
'	$Style0		= 0			' list goes up/down, text line editable
'	$Style1		= 1			' list always down, text line editable
'	$Style2		= 2			' list goes up/down, text line not editable
'	$Style3		= 3			' list always down, text line not editable
'
SUB SetStyle
	style = v0
	IF (style < 0) THEN EXIT SUB
	IF (style > 3) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @oldStyle, 0, 0, 0, 0, 0)
	XuiSetStyle (grid, #SetStyle, style, 0, 0, 0, 0, 0)
	IF (style = oldStyle) THEN EXIT SUB
	SELECT CASE style
		CASE 0:		XuiSendToKid (grid, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderRidge, 0, $Text, 0)
							XuiSendToKid (grid, #ShowTextCursor, 0, 0, 0, 0, $Text, 0)
		CASE 1:		XuiSendToKid (grid, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderRidge, 0, $Text, 0)
							XuiSendToKid (grid, #ShowTextCursor, 0, 0, 0, 0, $Text, 0)
							XuiSendMessage (pulldown, #ShowWindow, 0, 0, 0, 0, 0, 0)
		CASE 2:		XuiSendToKid (grid, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderRaise1, 0, $Text, 0)
							XuiSendToKid (grid, #HideTextCursor, 0, 0, 0, 0, $Text, 0)
		CASE 3:		XuiSendToKid (grid, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderRaise1, 0, $Text, 0)
							XuiSendToKid (grid, #HideTextCursor, 0, 0, 0, 0, $Text, 0)
							XuiSendMessage (pulldown, #ShowWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  SetColor  *****
'
SUB SetColor
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendToKid (grid, message, v0, v1, v2, v3, $Text, 0)
	XuiSendToKid (grid, message, v0, v1, v2, v3, $Button, 0)
	XuiSendMessage (pulldown, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  SetTextArray  *****
'
SUB SetTextArray
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF r1$[] THEN text$ = r1$[0]
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	under = INSTR (text$, "_")
	IF under THEN text$ = LEFT$(text$,under-1) + MID$(text$, under+1)
	cp = LEN (text$)
	XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @text$)
	XuiSendToKid (grid, #SetTextCursor, cp, 0, 0, 0, $Text, 0)
	XuiSendMessage (pulldown, #SetTextArray, 0, 0, 0, 0, 0, @r1$[])
	XuiSendMessage (pulldown, #Resize, 0, 0, x2-x1+1, 0, 0, 0)
	XuiSendMessage (pulldown, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  SetTextCursor  *****
'
SUB SetTextCursor
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF (v0 >= 0) THEN XuiSendToKid (grid, #SetTextCursor, v0, 0, 0, 0, $Text, 0)
	IF (v1 >= 0) THEN XuiSendMessage (pulldown, #SetTextCursor, 0, v1, 0, 0, 0, 0)
END SUB
'
'
' *****  SetTextString  *****
'
SUB SetTextString
	cp = LEN (r1$)
	XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @r1$)
	XuiSendToKid (grid, #SetTextCursor, cp, 0, 0, 0, $Text, 0)
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	abort = r0
	XuiCallback (grid, #TextEvent, v0, v1, v2, v3, @abort, grid)
	IF (abort = -1) THEN EXIT SUB
	IF (v2 AND $$TextModifyBit) THEN XgrJamMessage (grid, #TextModified, 0, 0, 0, 0, 0, 0)
'
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IFZ pulldown THEN EXIT SUB
	key = v2{$$VirtualKey}
'
	IF (v2 AND $$AltBit) THEN
		SELECT CASE key
			CASE $$KeyUpArrow		: GOSUB PullUp		: r0 = -1			' cancel
			CASE $$KeyDownArrow	: GOSUB PullDown	: r0 = -1			' cancel
		END SELECT
	ELSE
		IF (r0 != $PullDown) THEN		' avoid infinite loop stack overflow
			SELECT CASE key
				CASE $$KeyUpArrow, $$KeyDownArrow
							XuiSendMessage (pulldown, #KeyDown, v0, v1, v2, v3, 0, pulldown)
							XuiSendMessage (pulldown, #GetTextArray, 0, 0, 0, 0, 0, @item$[])
							XuiSendMessage (pulldown, #GetTextCursor, @cp, @cl, 0, 0, 0, 0)
							upper = UBOUND (item$[])
							IF (cl > upper) THEN cl = upper
							IF (cl < 0) THEN cl = 0
							item$ = item$[cl]
							cp = LEN(item$)
							XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @item$)
							XuiSendToKid (grid, #SetTextCursor, cp, 0, 0, 0, $Text, 0)
							XuiSendToKid (grid, #Redraw, 0, 0, 0, 0, $Text, 0)
							r0 = -1
			END SELECT
		END IF
	END IF
END SUB
'
'
' *****  TextModified  *****
'
SUB TextModified
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IFZ pulldown THEN EXIT SUB
	XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @text$)
	IFZ text$ THEN EXIT SUB
	XuiSendMessage (pulldown, #GetTextArray, 0, 0, 0, 0, 0, @list$[])
	IFZ list$[] THEN EXIT SUB
	uList = UBOUND (list$[])
	lenText = LEN (text$)
	FOR line = 0 TO uList
		list$ = list$[line]
		under = INSTR (list$, "_")
		IF under THEN list$ = LEFT$ (list$, under-1) + MID$ (list$, under+1)
		lenLine = LEN (list$)
		IF (lenLine < lenText) THEN DO NEXT
		IF (text$ = LEFT$ (list$, lenText)) THEN EXIT FOR
	NEXT line
	IF (line <= uList) THEN XuiSendMessage (pulldown, #SetTextCursor, 0, line, -1, -1, 0, 0)
END SUB
'
'
' *****  SendToKids  *****
'
SUB SendToKids
	XuiSendToKids (grid, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= 0
	func[#Destroy]						= 0
	func[#GetSmallestSize]		= &XuiGetMaxMinSize()
	func[#GetTextArray]				= 0
	func[#GetTextString]			= 0
	func[#Resize]							= 0
	func[#SetStyle]						= 0
	func[#SetTextArray]				= 0
	func[#SetTextString]			= 0
'
	DIM sub[upperMessage]
	sub[#Callback]						= SUBADDRESS (Callback)
	sub[#ContextChange]				= SUBADDRESS (PullUp)
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#Destroy]							= SUBADDRESS (Destroy)
	sub[#GetTextArray]				= SUBADDRESS (GetTextArray)
	sub[#GetTextCursor]				= SUBADDRESS (GetTextCursor)
	sub[#GetTextString]				= SUBADDRESS (GetTextString)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#MouseDrag]						= SUBADDRESS (MouseDrag)
	sub[#MouseUp]							= SUBADDRESS (MouseUp)
	sub[#Resize]							= SUBADDRESS (Resize)
	sub[#Selection]						= SUBADDRESS (Selection)
	sub[#SetColor]						= SUBADDRESS (SetColor)
	sub[#SetColorExtra]				= SUBADDRESS (SetColor)
	sub[#SetFont]							= SUBADDRESS (SendToKids)
	sub[#SetFontNumber]				= SUBADDRESS (SendToKids)
	sub[#SetStyle]						= SUBADDRESS (SetStyle)
	sub[#SetTextArray]				= SUBADDRESS (SetTextArray)
	sub[#SetTextCursor]				= SUBADDRESS (SetTextCursor)
	sub[#SetTextString]				= SUBADDRESS (SetTextString)
	sub[#TextEvent]						= SUBADDRESS (TextEvent)
	sub[#TextModified]				= SUBADDRESS (TextModified)
'
	IF func[0] THEN PRINT "XuiDropBox() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiDropBox() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiDropBox, @"XuiDropBox", &XuiDropBox(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 24
'
	gridType = XuiDropBox
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Text)
	XuiSetGridTypeValue (gridType, @"inputTextString",  $Text)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##############################
' #####  XuiDropButton ()  #####
' ##############################
'
FUNCTION  XuiDropButton (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR		sub[]
	STATIC	upperMessage
	STATIC	XuiDropButton
	STATIC	monitor
'
	$DropButton	= 0
	$Button			= 1
	$PullDown		= 2
'
	$Style0			= 0			' list goes up/down
	$Style1			= 1			' list always down
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiDropButton) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiDropButton, @v0, @v1, 128, 20, r0, r1, &XuiDropButton())
	XuiPressButton (@g, #Create, 108, 0, 20, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDropButton(), -1, -1, $Button, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PressButton")
	GOSUB CreatePullDown
	GOSUB Resize
END SUB
'
'
' *****  CreatePullDown  *****
'
SUB CreatePullDown
	XgrGetGridWindow (grid, @window)
	XgrConvertWindowToDisplay (grid, v0, v1+20, @xDisp, @yDisp)
	windowType = $$WindowTypeTopMost OR $$WindowTypeNoSelect OR $$WindowTypeNoFrame OR window
	XuiPullDown    (@g, #CreateWindow, xDisp, yDisp, v2, v3, windowType, 0)
	XuiSendMessage ( g, #SetCallback, grid, &XuiDropButton(), -1, -1, $PullDown, grid)
	XuiSetValues   (grid, #SetValues, g, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiDropButton")
END SUB
'
'
' *****  Destroy  *****
'
SUB Destroy
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendMessage (pulldown, #Destroy, 0, 0, 0, 0, 0, 0)
	XuiDestroy (grid, #Destroy, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  GetTextArray  *****
'
SUB GetTextArray
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendMessage (pulldown, #GetTextArray, 0, 0, 0, 0, 0, @r1$[])
END SUB
'
'
' *****  GetTextCursor  *****
'
SUB GetTextCursor
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendMessage (pulldown, #GetTextCursor, 0, @v1, 0, 0, 0, 0)
	v0 = 0
END SUB
'
'
' *****  GetTextString  *****
'
SUB GetTextString
	XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Button, @r1$)
END SUB
'
'
' *****  Monitor  *****
'
SUB Monitor
	XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiDropButton(), 0, 0, 0, monitor)
	XuiMonitorContext (grid, #MonitorContext, grid, &XuiDropButton(), 0, 0, 0, monitor)
END SUB
'
'
' *****  MouseDown  *****  caused by #MonitorMouse
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IFZ pullstate THEN EXIT SUB
	IFZ pulldown THEN EXIT SUB
	IFZ monitor THEN EXIT SUB
	IFZ r1 THEN EXIT SUB
	gg = r1
'
	IF XuiGridContainsGridCoord (pulldown, gg, v0, v1, @xx, @yy) THEN
		XuiSendMessage (pulldown, message, xx, yy, v2, v3, 0, pulldown)
		r0 = -1
	ELSE
		IFZ (style AND 1) THEN GOSUB PullUp
		XuiSendToKid (grid, #GetGridNumber, @gb, 0, 0, 0, $Button, 0)
		IF XuiGridContainsGridCoord (gb, gg, v0, v1, 0, 0) THEN r0 = -1
	END IF
END SUB
'
'
' *****  MouseDrag  *****  caused by #MonitorMouse
'
SUB MouseDrag
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IFZ pullstate THEN EXIT SUB
	IFZ pulldown THEN EXIT SUB
	IFZ monitor THEN EXIT SUB
	IFZ r1 THEN EXIT SUB
	gg = r1
'
	IF XuiGridContainsGridCoord (pulldown, gg, v0, v1, @xx, @yy) THEN
		XuiSendMessage (pulldown, message, xx, yy, v2, v3, 0, pulldown)
	END IF
	r0 = -1
END SUB
'
'
' *****  MouseUp  *****  caused by #MonitorMouse
'
SUB MouseUp
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IFZ pullstate THEN EXIT SUB
	IFZ pulldown THEN EXIT SUB
	IFZ monitor THEN EXIT SUB
	IFZ r1 THEN EXIT SUB
	gg = r1
'
	IF XuiGridContainsGridCoord (pulldown, gg, v0, v1, @xx, @yy) THEN
		XuiSendMessage (pulldown, message, xx, yy, v2, v3, 0, pulldown)
	ELSE
		IFZ (style AND 1) THEN
			XuiSendToKid (grid, #GetGridNumber, @gb, 0, 0, 0, $Button, 0)
			IFZ XuiGridContainsGridCoord (gb, gg, v0, v1, 0, 0) THEN GOSUB PullUp
		END IF
	END IF
	r0 = -1
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	XuiSendToKid (grid, #Resize, 0, 0, v2, v3, $Button, 0)
	XuiSendMessage (pulldown, #Resize, 0, 0, 0, 0, 0, 0)
	XgrGetGridWindow (pulldown, @pullWindow)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (pullWindow, xDrop, yDrop, -1, -1)
	XuiSendMessage (pulldown, #Resize, 0, 0, x2-x1+1, 0, 0, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
'
	SELECT CASE r0
		CASE $Button		:	IF (style AND 1) THEN GOSUB PullDown ELSE GOSUB PullToggle
		CASE $PullDown	: XuiSendMessage (pulldown, #GetTextArray, 0, 0, 0, 0, 0, @text$[])
											XuiSendMessage (pulldown, #GetTextCursor, @cp, @cl, 0, 0, 0, 0)
											IF ((v0 >= 0) AND (v0 <= UBOUND(text$[]))) THEN
												text$ = text$[v0]
												under = INSTR(text$, "_")
												IF under THEN text$ = LEFT$(text$,under-1) + MID$(text$, under+1)
												XuiSetTextString (grid, #SetTextString, 0, 0, 0, 0, 0, @text$)
											END IF
											IFZ (style AND 1) THEN GOSUB PullUp
											XuiCallback (grid, #Selection, v0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  PullDown  *****
'
SUB PullDown
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF pullstate THEN EXIT SUB
	XgrGetGridWindow (grid, @window)
	XgrGetGridWindow (pulldown, @pullWindow)
	XuiSetValue (grid, #SetValue, $$TRUE, 0, 0, 0, 0, 1)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (pullWindow, xDrop, yDrop, -1, -1)
	XuiSendMessage (pulldown, #ShowWindow, 0, 0, 0, 0, 0, 0)
	monitor = $$TRUE
	GOSUB Monitor
END SUB
'
'
' *****  PullUp  *****
'
SUB PullUp
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IFZ pullstate THEN EXIT SUB
	XgrGetGridWindow (grid, @window)
	XgrGetGridWindow (pulldown, @pullWindow)
	XuiSetValue (grid, #SetValue, $$FALSE, 0, 0, 0, 0, 1)
	XuiSendMessage (pulldown, #HideWindow, 0, 0, 0, 0, 0, 0)
	monitor = $$FALSE
	GOSUB Monitor
END SUB
'
'
' *****  PullToggle  *****
'
SUB PullToggle
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF pullstate THEN GOSUB PullUp ELSE GOSUB PullDown
END SUB
'
'
' *****  SetStyle  *****
'
'	$Style0		= 0			' list goes up/down
'	$Style1		= 1			' list always down
'
SUB SetStyle
	style = v0
	IF (style < 0) THEN EXIT SUB
	IF (style > 1) THEN EXIT SUB
	XuiSetStyle (grid, #SetStyle, style, 0, 0, 0, 0, 0)
	IF (style AND 1) THEN GOSUB PullDown
END SUB
'
'
' *****  SetColor  *****
'
SUB SetColor
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendToKid (grid, message, v0, v1, v2, v3, $Button, 0)
	XuiSendMessage (pulldown, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  SetTextArray  *****
'
SUB SetTextArray
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	XuiSendMessage (pulldown, #SetTextArray, 0, 0, 0, 0, 0, @r1$[])
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XuiSendMessage (pulldown, #Resize, 0, 0, x2-x1+1, 0, 0, 0)
	XuiSendMessage (pulldown, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  SetTextCursor  *****
'
SUB SetTextCursor
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IF (v1 >= 0) THEN XuiSendMessage (pulldown, #SetTextCursor, 0, v1, 0, 0, 0, 0)
END SUB
'
'
' *****  SetTextString  *****
'
SUB SetTextString
	XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Button, @r1$)
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	XuiGetValues (grid, #GetValues, @pulldown, @pullstate, 0, 0, 0, 0)
	IFZ pulldown THEN EXIT SUB
	key = v2{$$VirtualKey}
'
	IF (v2 AND $$AltBit) THEN
		SELECT CASE key
			CASE $$KeyUpArrow		: GOSUB PullUp		: r0 = -1			' cancel
			CASE $$KeyDownArrow	: GOSUB PullDown	: r0 = -1			' cancel
		END SELECT
	ELSE
		IF (r0 != $PullDown) THEN		' avoid infinite loop stack overflow
			SELECT CASE key
				CASE $$KeyUpArrow, $$KeyDownArrow
							XuiSendMessage (pulldown, #KeyDown, v0, v1, v2, v3, 0, pulldown)
							r0 = -1
			END SELECT
		END IF
	END IF
END SUB
'
'
' *****  SendToKids  *****
'
SUB SendToKids
	XuiSendToKids (grid, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= 0
	func[#Destroy]						= 0
	func[#GetSmallestSize]		= &XuiGetMaxMinSize()
	func[#GetTextArray]				= 0
	func[#Resize]							= 0
	func[#SetStyle]						= 0
	func[#SetTextArray]				= 0
	func[#SetTextString]			= 0
'
	DIM sub[upperMessage]
	sub[#Callback]						= SUBADDRESS (Callback)
	sub[#ContextChange]				= SUBADDRESS (PullUp)
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#Destroy]							= SUBADDRESS (Destroy)
	sub[#GetTextArray]				= SUBADDRESS (GetTextArray)
	sub[#GetTextCursor]				= SUBADDRESS (GetTextCursor)
	sub[#GetTextString]				= SUBADDRESS (GetTextString)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#MouseDrag]						= SUBADDRESS (MouseDrag)
	sub[#MouseUp]							= SUBADDRESS (MouseUp)
	sub[#Resize]							= SUBADDRESS (Resize)
	sub[#Selection]						= SUBADDRESS (Selection)
	sub[#SetColor]						= SUBADDRESS (SetColor)
	sub[#SetColorExtra]				= SUBADDRESS (SetColor)
	sub[#SetFont]							= SUBADDRESS (SendToKids)
	sub[#SetFontNumber]				= SUBADDRESS (SendToKids)
	sub[#SetStyle]						= SUBADDRESS (SetStyle)
	sub[#SetTextArray]				= SUBADDRESS (SetTextArray)
	sub[#SetTextCursor]				= SUBADDRESS (SetTextCursor)
	sub[#SetTextString]				= SUBADDRESS (SetTextString)
	sub[#TextEvent]						= SUBADDRESS (TextEvent)
'
	IF func[0] THEN PRINT "XuiDropButton() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiDropButton() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiDropButton, @"XuiDropButton", &XuiDropButton(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 24
'
	gridType = XuiDropButton
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Button)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #########################
' #####  XuiLabel ()  #####
' #########################
'
FUNCTION  XuiLabel (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiLabel
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, @XuiLabel) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiLabel, @v0, @v1, @v2, @v3, r0, r1, &XuiLabel())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiLabel")
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
'
	IF func[0] THEN PRINT "XuiLabel() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiLabel() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiLabel, @"XuiLabel", &XuiLabel(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 16
'
	gridType = XuiLabel
	XuiSetGridTypeValue (gridType, @"x",           designX)
	XuiSetGridTypeValue (gridType, @"y",           designY)
	XuiSetGridTypeValue (gridType, @"width",       designWidth)
	XuiSetGridTypeValue (gridType, @"height",      designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",    4)
	XuiSetGridTypeValue (gridType, @"minHeight",   4)
	XuiSetGridTypeValue (gridType, @"align",       $$AlignMiddleCenter)
	XuiSetGridTypeValue (gridType, @"justify",     $$JustifyCenter)
	XuiSetGridTypeValue (gridType, @"border",      $$BorderRaise)
	XuiSetGridTypeValue (gridType, @"texture",     $$TextureRaise1)
	XuiSetGridTypeValue (gridType, @"redrawFlags", $$RedrawDefaultNoFocus)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###########################
' #####  XuiListBox ()  #####
' ###########################
'
FUNCTION  XuiListBox (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiListBox
'
	$ListBox	= 0
	$Text			= 1
	$Button		= 2
	$List			= 3
'
	$Style0		= 0			' list goes up/down, text line editable
	$Style1		= 1			' list always down, text line editable
	$Style2		= 2			' list goes up/down, text line not editable
	$Style3		= 3			' list always down, text line not editable
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiListBox) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiListBox, @v0, @v1, 128, 20, r0, r1, &XuiListBox())
	XuiTextLine    (@g, #Create, 0, 0, 108, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListBox(), -1, -1, $Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLine")
	XuiPressButton (@g, #Create, 108, 0, 20, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListBox(), -1, -1, $Button, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PressButton")
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderRaise1, 0, 0, 0)
	XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetStyle, $$TriangleDown, 0, 0, 0, 0, 0)
	GOSUB CreateList
	GOSUB Resize
END SUB
'
'
' *****  CreateList  *****
'
SUB CreateList
	XgrConvertWindowToDisplay (grid, v0, v1+20, @xDisp, @yDisp)
	XgrGetGridWindow (grid, @window)
	windowType = $$WindowTypeTopMost OR $$WindowTypeNoFrame OR window
	XuiList        (@g, #CreateWindow, xDisp, yDisp, v2, v3, windowType, 0)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListBox(), -1, -1, $List, grid)
	XuiSendMessage ( g, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderRidge, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Yellow, $$Yellow, -1, -1, 2, 0)
	XuiSetValues   (grid, #SetValues, g, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiListBox")
END SUB
'
'
' *****  Destroy  *****
'
SUB Destroy
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiSendMessage (list, #Destroy, 0, 0, 0, 0, 0, 0)
	XuiDestroy (grid, #Destroy, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  GetTextArray  *****
'
SUB GetTextArray
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @r1$[])
END SUB
'
'
' *****  GetTextCursor  *****
'
SUB GetTextCursor
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiSendToKid (grid, #GetTextCursor, @v0, 0, 0, 0, $Text, 0)
	XuiSendMessage (list, #GetTextCursor, 0, @v1, 0, 0, 0, 0)
END SUB
'
'
' *****  GetTextString  *****
'
SUB GetTextString
	XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @r1$)
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF (v2 < (v3 + 32)) THEN v2 = v3 + 32
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	x1 = 0 : y1 = 0 : w1 = v2 - v3
	x2 = v2 - v3 : y2 = 0 : w2 = v3
	XuiSendToKid (grid, #Resize, x1, y1, w1, v3, $Text, 0)
	XuiSendToKid (grid, #Resize, x2, y2, w2, v3, $Button, 0)
	XuiSendMessage (list, #Resize, 0, 0, 0, 0, 0, 0)
	XgrGetGridWindow (list, @listWindow)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (listWindow, xDrop, yDrop, -1, -1)
	GOSUB SizeList
	XuiSendMessage (list, #Resize, 0, 0, x2-x1+1, height, 0, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	SELECT CASE r0
		CASE $Text			: IFZ (style AND 1) THEN GOSUB PullUp
											XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @text$)
											XuiSetTextString (grid, #SetTextString, 0, 0, 0, 0, 0, @text$)
											XuiSendMessage (list, #GetTextCursor, 0, @cl, 0, 0, 0, 0)
											XuiCallback (grid, #Selection, cl, 0, 0, 0, 0, 0)
		CASE $Button		:	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
											XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
											IF (style AND 1) THEN GOSUB PullDown ELSE GOSUB PullToggle
		CASE $List			: XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @text$[])
											XuiSendMessage (list, #GetTextCursor, @cp, @cl, 0, 0, 0, 0)
											IF ((v0 >= 0) AND (v0 <= UBOUND(text$[]))) THEN
												text$ = text$[v0]
												under = INSTR(text$, "_")
												IF under THEN text$ = LEFT$(text$,under-1) + MID$(text$, under+1)
												XuiSetTextString (grid, #SetTextString, 0, 0, 0, 0, 0, @text$)
												XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @text$)
												XuiSendToKid (grid, #Redraw, 0, 0, 0, 0, $Text, 0)
												XuiSendToKid (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Text, 0)
											END IF
											IFZ (style AND 1) THEN GOSUB PullUp
											XuiCallback (grid, #Selection, v0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  PullDown  *****
'
SUB PullDown
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF listState THEN EXIT SUB
	XgrGetGridWindow (grid, @window)
	XgrGetGridWindow (list, @listWindow)
	XuiSetValue (grid, #SetValue, $$TRUE, 0, 0, 0, 0, 1)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (listWindow, xDrop, yDrop, -1, -1)
	XuiSendMessage (list, #ShowWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  PullUp  *****
'
SUB PullUp
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IFZ listState THEN EXIT SUB
	XuiSetValue (grid, #SetValue, $$FALSE, 0, 0, 0, 0, 1)
	XuiSendMessage (list, #HideWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  PullToggle  *****
'
SUB PullToggle
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF listState THEN GOSUB PullUp ELSE GOSUB PullDown
END SUB
'
'
' *****  SetStyle  *****
'
'	$Style0		= 0			' list goes up/down, text line editable
'	$Style1		= 1			' list always down, text line editable
'	$Style2		= 2			' list goes up/down, text line not editable
'	$Style3		= 3			' list always down, text line not editable
'
SUB SetStyle
	style = v0
	IF (style < 0) THEN EXIT SUB
	IF (style > 3) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @oldStyle, 0, 0, 0, 0, 0)
	XuiSetStyle (grid, #SetStyle, style, 0, 0, 0, 0, 0)
	IF (style = oldStyle) THEN EXIT SUB
	SELECT CASE style
		CASE 0:		XuiSendToKid (grid, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderRidge, 0, $Text, 0)
							XuiSendToKid (grid, #ShowTextCursor, 0, 0, 0, 0, $Text, 0)
		CASE 1:		XuiSendToKid (grid, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderRidge, 0, $Text, 0)
							XuiSendToKid (grid, #ShowTextCursor, 0, 0, 0, 0, $Text, 0)
							XuiSendMessage (list, #ShowWindow, 0, 0, 0, 0, 0, 0)
		CASE 2:		XuiSendToKid (grid, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderRaise1, 0, $Text, 0)
							XuiSendToKid (grid, #HideTextCursor, 0, 0, 0, 0, $Text, 0)
		CASE 3:		XuiSendToKid (grid, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderRaise1, 0, $Text, 0)
							XuiSendToKid (grid, #HideTextCursor, 0, 0, 0, 0, $Text, 0)
							XuiSendMessage (list, #ShowWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  SetColors  *****
'
SUB SetColors
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiSendToKid (grid, message, v0, v1, v2, v3, $Text, 0)
	XuiSendToKid (grid, message, v0, v1, v2, v3, $Button, 0)
	XuiSendMessage (list, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  SetTextArray  *****
'
SUB SetTextArray
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF r1$[] THEN text$ = r1$[0]
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	under = INSTR (text$, "_")
	IF under THEN text$ = LEFT$(text$,under-1) + MID$(text$, under+1)
	cp = LEN (text$)
	IF r1$[] THEN
		XuiSendMessage (list, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		XuiGetTextArraySize (@r1$[], font, @w, @h, @width, @height, extra, extra)
	END IF
	height = height + 24
	IF (height > 256) THEN height = 256
	XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @text$)
	XuiSendToKid (grid, #SetTextCursor, cp, 0, 0, 0, $Text, 0)
	XuiSendMessage (list, #SetTextArray, 0, 0, 0, 0, 0, @r1$[])
	GOSUB SizeList
	XuiSendMessage (list, #Resize, 0, 0, x2-x1+1, height, 0, 0)
	XuiSendMessage (list, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  SizeList  *****
'
SUB SizeList
	XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @list$[])
	height = 0
	IF list$[] THEN
		XuiSendMessage (list, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		XuiGetTextArraySize (@list$[], font, 0, 0, 0, @height, 0, 0)
	END IF
	DIM list$[]
	height = height + 24
	IF (height > 256) THEN height = 256
END SUB
'
'
' *****  SetTextCursor  *****
'
SUB SetTextCursor
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF (v0 >= 0) THEN XuiSendToKid (grid, #SetTextCursor, v0, 0, 0, 0, $Text, 0)
	IF (v1 >= 0) THEN XuiSendMessage (list, #SetTextCursor, 0, v1, -1, -1, 0, 0)
END SUB
'
'
' *****  SetTextString  *****
'
SUB SetTextString
	cp = LEN (r1$)
	XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @r1$)
	XuiSendToKid (grid, #SetTextCursor, cp, 0, 0, 0, $Text, 0)
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	abort = r0
	XuiCallback (grid, #TextEvent, v0, v1, v2, v3, @abort, grid)
	IF (abort = -1) THEN EXIT SUB
'
	IF (v2 AND $$TextModifyBit) THEN XgrJamMessage (grid, #TextModified, 0, 0, 0, 0, 0, 0)
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IFZ list THEN EXIT SUB
	key = v2{$$VirtualKey}
'
	IF (v2 AND $$AltBit) THEN
		SELECT CASE key
			CASE $$KeyUpArrow		: GOSUB PullUp		: r0 = -1			' cancel
			CASE $$KeyDownArrow	: GOSUB PullDown	: r0 = -1			' cancel
		END SELECT
	ELSE
		IF (r0 != $List) THEN
			SELECT CASE key
				CASE $$KeyUpArrow, $$KeyDownArrow
							XuiSendMessage (list, #KeyDown, v0, v1, v2, v3, 0, list)
							XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @item$[])
							XuiSendMessage (list, #GetTextCursor, @cp, @cl, 0, 0, 0, 0)
							upper = UBOUND (item$[])
							IF (cl > upper) THEN cl = upper
							IF (cl < 0) THEN cl = 0
							item$ = item$[cl]
							cp = LEN(item$)
							XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Text, @item$)
							XuiSendToKid (grid, #SetTextCursor, cp, 0, 0, 0, $Text, 0)
							XuiSendToKid (grid, #Redraw, 0, 0, 0, 0, $Text, 0)
							r0 = -1
			END SELECT
		END IF
	END IF
END SUB
'
'
' *****  TextModified  *****
'
SUB TextModified
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IFZ list THEN EXIT SUB
	XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @text$)
	IFZ text$ THEN EXIT SUB
	XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @list$[])
	IFZ list$[] THEN EXIT SUB
	uList = UBOUND (list$[])
	lenText = LEN (text$)
	FOR line = 0 TO uList
		list$ = list$[line]
		under = INSTR (list$, "_")
		IF under THEN list$ = LEFT$ (list$, under-1) + MID$ (list$, under+1)
		lenLine = LEN (list$)
		IF (lenLine < lenText) THEN DO NEXT
		IF (text$ = LEFT$ (list$, lenText)) THEN EXIT FOR
	NEXT line
	IF (line <= uList) THEN XuiSendMessage (list, #SetTextCursor, 0, line, -1, -1, 0, 0)
END SUB
'
'
' *****  SendToKids  *****
'
SUB SendToKids
	XuiSendToKids (grid, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= 0
	func[#Destroy]						= 0
	func[#GetSmallestSize]		= &XuiGetMaxMinSize()
	func[#GetTextArray]				= 0
	func[#GetTextString]			= 0
	func[#Resize]							= 0
	func[#SetStyle]						= 0
	func[#SetTextArray]				= 0
	func[#SetTextString]			= 0
'
	DIM sub[upperMessage]
	sub[#Callback]						= SUBADDRESS (Callback)
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#Destroy]							= SUBADDRESS (Destroy)
	sub[#GetTextArray]				= SUBADDRESS (GetTextArray)
	sub[#GetTextCursor]				= SUBADDRESS (GetTextCursor)
	sub[#GetTextString]				= SUBADDRESS (GetTextString)
	sub[#Resize]							= SUBADDRESS (Resize)
	sub[#Selection]						= SUBADDRESS (Selection)
	sub[#SetColor]						= SUBADDRESS (SetColors)
	sub[#SetColorExtra]				= SUBADDRESS (SetColors)
	sub[#SetFont]							= SUBADDRESS (SendToKids)
	sub[#SetFontNumber]				= SUBADDRESS (SendToKids)
	sub[#SetStyle]						= SUBADDRESS (SetStyle)
	sub[#SetTextArray]				= SUBADDRESS (SetTextArray)
	sub[#SetTextCursor]				= SUBADDRESS (SetTextCursor)
	sub[#SetTextString]				= SUBADDRESS (SetTextString)
	sub[#TextEvent]						= SUBADDRESS (TextEvent)
	sub[#TextModified]				= SUBADDRESS (TextModified)
'
	IF func[0] THEN PRINT "XuiListBox() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiListBox() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiListBox, @"XuiListBox", &XuiListBox(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 24
'
	gridType = XuiListBox
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Text)
	XuiSetGridTypeValue (gridType, @"inputTextString",  $Text)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawNone)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##############################
' #####  XuiListButton ()  #####
' ##############################
'
FUNCTION  XuiListButton (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  XuiListButton
	STATIC  downGrid
	STATIC  outside
'
	$ListButton	= 0
	$List				= 1
'
	$Style0			= 0			' list goes up/down, text line editable
	$Style1			= 1			' list always down, text line editable
	$Style2			= 2			' list goes up/down, text line not editable
	$Style3			= 3			' list always down, text line not editable
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiListButton) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiListButton, @v0, @v1, @v2, @v3, r0, r1, &XuiListButton())
	GOSUB CreateList
	GOSUB Resize
END SUB
'
'
' *****  CreateList  *****
'
SUB CreateList
	XgrGetGridWindow (grid, @window)
	XgrConvertWindowToDisplay (grid, v0, v1+20, @xDisp, @yDisp)
	windowType = $$WindowTypeTopMost OR $$WindowTypeNoFrame OR window
	XuiList (@g, #CreateWindow, xDisp, yDisp, v2, v3, windowType, 0)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListButton(), -1, -1, $List, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"List")
	XuiSendMessage ( g, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderRidge, 0, 0, 0)
	XuiSetValues (grid, #SetValues, g, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiListButton")
END SUB
'
'
' *****  Destroy  *****
'
SUB Destroy
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiSendMessage (list, #Destroy, 0, 0, 0, 0, 0, 0)
	XuiDestroy (grid, #Destroy, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  GetTextArray  *****
'
SUB GetTextArray
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @r1$[])
END SUB
'
'
' *****  GetTextCursor  *****
'
SUB GetTextCursor
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiSendMessage (list, #GetTextCursor, @v0, @v1, @v2, @v3, 0, 0)
END SUB
'
'
' *****  GrabTextArray  *****
'
SUB GrabTextArray
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XuiSendMessage (list, #GrabTextArray, 0, 0, 0, 0, 0, @r1$[])
END SUB
'
'
' *****  KeyDown  *****
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IFZ list THEN EXIT SUB
	key = v2{$$VirtualKey}
'
	IF (v2 AND $$AltBit) THEN
		SELECT CASE key
			CASE $$KeyUpArrow		: GOSUB PullUp
			CASE $$KeyDownArrow	: GOSUB PullDown
		END SELECT
	ELSE
		IFZ callback THEN			' avoid stack overflow
			SELECT CASE key
				CASE $$KeyUpArrow, $$KeyDownArrow, $$KeyEnter
							XuiSendMessage (list, #KeyDown, v0, v1, v2, v3, 0, list)
			END SELECT
		END IF
	END IF
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IF (style AND 1) THEN GOSUB PullDown ELSE GOSUB PullToggle
	downGrid = grid
END SUB
'
'
' *****  MouseDrag  *****
'
SUB MouseDrag
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IFZ listState THEN EXIT SUB
	IF outside THEN
		XgrConvertLocalToDisplay (r1, v0, v1, @xDisp, @yDisp)
		XgrConvertDisplayToLocal (list, xDisp, yDisp, @x, @y)
		XgrGetGridBoxLocal (list, @x1, @y1, @x2, @y2)
		IF (x >= x1) THEN
			IF (x <= x2) THEN
				IF (y >= y1) THEN
					IF (y <= y2) THEN
						XuiSendMessage (list, message, x, y, v2, v3, 0, list)
					END IF
				END IF
			END IF
		END IF
	END IF
END SUB
'
'
' *****  MouseEnter  *****
'
SUB MouseEnter
	IF downGrid THEN outside = $$FALSE
END SUB
'
'
' *****  MouseExit  *****
'
SUB MouseExit
	IF downGrid THEN outside = $$TRUE
END SUB
'
'
' *****  MouseUp  *****
'
SUB MouseUp
	downGrid = $$FALSE
	outside = $$FALSE
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF (v2 < (v3 + 32)) THEN v2 = v3 + 32
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	XuiSendMessage (list, #Resize, 0, 0, 0, 0, 0, 0)
	XgrGetGridWindow (list, @listWindow)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (listWindow, xDrop, yDrop, -1, -1)
	GOSUB SizeList
	XuiSendMessage (list, #Resize, 0, 0, x2-x1+1, height, 0, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	SELECT CASE r0
		CASE $List			: XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @text$[])
											XuiSendMessage (list, #GetTextCursor, @cp, @cl, 0, 0, 0, 0)
											IF ((v0 >= 0) AND (v0 <= UBOUND(text$[]))) THEN
												text$ = text$[v0]
												under = INSTR(text$, "_")
												IF under THEN text$ = LEFT$(text$,under-1) + MID$(text$, under+1)
												XuiSetKeyboardFocus (grid, #SetKeyboardFocus, 0, 0, 0, 0, 0, 0)
											END IF
											IFZ (style AND 1) THEN GOSUB PullUp
											XuiCallback (grid, #Selection, v0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  PullDown  *****
'
SUB PullDown
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF listState THEN EXIT SUB
	XgrGetGridWindow (grid, @window)
	XgrGetGridWindow (list, @listWindow)
	XuiSetValue (grid, #SetValue, $$TRUE, 0, 0, 0, 0, 1)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XgrConvertWindowToDisplay (grid, x1, y2+1, @xDrop, @yDrop)
	XgrSetWindowPositionAndSize (listWindow, xDrop, yDrop, -1, -1)
	XuiSendMessage (list, #ShowWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  PullUp  *****
'
SUB PullUp
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IFZ listState THEN EXIT SUB
	XuiSetValue (grid, #SetValue, $$FALSE, 0, 0, 0, 0, 1)
	XuiSendMessage (list, #HideWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  PullToggle  *****
'
SUB PullToggle
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF listState THEN GOSUB PullUp ELSE GOSUB PullDown
END SUB
'
'
' *****  PokeTextArray  *****
'
SUB PokeTextArray
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	XuiSendMessage (list, #PokeTextArray, 0, 0, 0, 0, 0, @r1$[])
END SUB
'
'
' *****  SetStyle  *****
'
'	$Style0		= 0			' list goes up/down
'	$Style1		= 1			' list always down
'	$Style2		= 2			' list goes up/down
'	$Style3		= 3			' list always down
'
SUB SetStyle
	style = v0
	IF (style < 0) THEN EXIT SUB
	IF (style > 3) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiGetStyle (grid, #GetStyle, @oldStyle, 0, 0, 0, 0, 0)
	XuiSetStyle (grid, #SetStyle, style, 0, 0, 0, 0, 0)
	IF (style = oldStyle) THEN EXIT SUB
	SELECT CASE style
		CASE 0,2:	XuiSendMessage (list, #HideWindow, 0, 0, 0, 0, 0, 0)
		CASE 1,3:	XuiSendMessage (list, #ShowWindow, 0, 0, 0, 0, 0, 0)
	END SELECT
END SUB
'
'
' *****  SetColors  *****
'
SUB SetColors
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiSendMessage (list, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  SetTextArray  *****
'
SUB SetTextArray
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	IF r1$[] THEN text$ = r1$[0]
	XgrGetGridBoxWindow (grid, @x1, @y1, @x2, @y2)
	under = INSTR (text$, "_")
	IF under THEN text$ = LEFT$(text$,under-1) + MID$(text$, under+1)
	cp = LEN (text$)
	IF r1$[] THEN
		XuiSendMessage (list, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		XuiGetTextArraySize (@r1$[], font, @w, @h, @width, @height, extra, extra)
	END IF
	height = height + 24
	IF (height > 256) THEN height = 256
	XuiSendMessage (list, #SetTextArray, 0, 0, 0, 0, 0, @r1$[])
	GOSUB SizeList
	XuiSendMessage (list, #Resize, 0, 0, x2-x1+1, height, 0, 0)
	XuiSendMessage (list, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  SetTextCursor  *****
'
SUB SetTextCursor
	XuiGetValues (grid, #GetValues, @list, @listState, 0, 0, 0, 0)
	XuiSendMessage (list, #SetTextCursor, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  SizeList  *****
'
SUB SizeList
	XuiSendMessage (list, #GetTextArray, 0, 0, 0, 0, 0, @list$[])
	height = 0
	IF list$[] THEN
		XuiSendMessage (list, #GetFontNumber, @font, 0, 0, 0, 0, 0)
		XuiGetTextArraySize (@list$[], font, 0, 0, 0, @height, 0, 0)
	END IF
	DIM list$[]
	height = height + 24
	IF (height > 256) THEN height = 256
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	GOSUB KeyDown
END SUB
'
'
' *****  SendToKids  *****
'
SUB SendToKids
	XuiSendToKids (grid, message, v0, v1, v2, v3, 0, r1)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= 0
	func[#Destroy]						= 0
	func[#GetSmallestSize]		= &XuiGetMaxMinSize()
	func[#GetTextArray]				= 0
	func[#GrabTextArray]			= 0
	func[#PokeTextArray]			= 0
	func[#Resize]							= 0
	func[#SetStyle]						= 0
	func[#SetTextArray]				= 0
'
	DIM sub[upperMessage]
	sub[#Callback]						= SUBADDRESS (Callback)
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#Destroy]							= SUBADDRESS (Destroy)
	sub[#GetTextArray]				= SUBADDRESS (GetTextArray)
	sub[#GrabTextArray]				= SUBADDRESS (GrabTextArray)
	sub[#KeyDown]							= SUBADDRESS (KeyDown)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#MouseDrag]						= SUBADDRESS (MouseDrag)
	sub[#MouseEnter]					= SUBADDRESS (MouseEnter)
	sub[#MouseExit]						= SUBADDRESS (MouseExit)
	sub[#MouseUp]							= SUBADDRESS (MouseUp)
	sub[#PokeTextArray]				= SUBADDRESS (PokeTextArray)
	sub[#Resize]							= SUBADDRESS (Resize)
	sub[#Selection]						= SUBADDRESS (Selection)
	sub[#SetColor]						= SUBADDRESS (SetColors)
	sub[#SetColorExtra]				= SUBADDRESS (SetColors)
	sub[#SetFont]							= SUBADDRESS (SendToKids)
	sub[#SetFontNumber]				= SUBADDRESS (SendToKids)
	sub[#SetStyle]						= SUBADDRESS (SetStyle)
	sub[#SetTextArray]				= SUBADDRESS (SetTextArray)
	sub[#TextEvent]						= SUBADDRESS (TextEvent)
'
	IF func[0] THEN PRINT "XuiListButton() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiListButton() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiListButton, @"XuiListButton", &XuiListButton(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 24
'
	gridType = XuiListButton
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRaise1)
	XuiSetGridTypeValue (gridType, @"texture",         $$TextureLower1)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawDefault)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ################################
' #####  XuiListDialog2B ()  #####  Label, List, TextLine, and 2 PushButtons
' ################################
'
FUNCTION  XuiListDialog2B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiListDialog2B
'
	$Dialog		= 0
	$Label		= 1
	$List			= 2
	$Text			= 3
	$Button0	= 4
	$Button1	= 5
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiListDialog2B) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****
'
SUB Callback
	IF (r1 = #Selection) THEN
		XuiCallback (grid, message, v0, v1, v2, v3, r0, r1)
	ELSE
		message = r1
		callback = message
		IF (message <= upperMessage) THEN GOSUB @sub[message]
	END IF
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiListDialog2B, @v0, @v1, @v2, @v3, r0, r1, &XuiListDialog2B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiList        (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListDialog2B(), -1, -1, $List, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"List")
	XuiTextLine    (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListDialog2B(), -1, -1, $Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLine")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListDialog2B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" Enter ")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiListDialog2B(), -1, -1, $Button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @" Cancel ")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiListDialog2B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @labelWidth, @labelHeight, $Label, 8)
	XuiSendToKid (grid, #GetSmallestSize, 10, 8, @listWidth, @listHeight, $List, 64)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, 0, @textHeight, $Text, 8)
'
	buttonWidth = 8
	buttonHeight = 8
	FOR i = $Button0 TO $Button1
		XuiSendToKid (grid, #GetSmallestSize, 0, 0, @width, @height, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth
	IF (width < labelWidth) THEN width = labelWidth
	IF (width < listWidth) THEN width = listWidth
	v2 = width + bw + bw
	v3 = labelHeight + listHeight + buttonHeight + textHeight + bw + bw
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize				' returns bw and heights
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
'	Resize grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	h = labelHeight + listHeight + buttonHeight + textHeight + bw + bw
	IF (v3 >= h + 4) THEN
		buttonHeight = buttonHeight + 4 : h = h + 4
		IF (v3 >= h + 4) THEN
			textHeight = textHeight + 4 : h = h + 4
			IF (v3 >= h + 4) THEN
				labelHeight = labelHeight + 4
			END IF
		END IF
	END IF
'
'	Resize kids
'
	x = bw
	y = bw
	w = v2 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, labelHeight, $Label, 0)
'
	y = y + labelHeight
	h = v3 - labelHeight - textHeight - buttonHeight - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w, h, $List, 0)
'
	y = y + h
	XuiSendToKid (grid, #Resize, x, y, w, textHeight, $Text, 0)
'
	y = y + textHeight
	h = buttonHeight
	w1 = w >> 1
	w2 = v2 - w1 - bw - bw
	XuiSendToKid (grid, #Resize, x, y, w2, h, $Button0, 0) : x = x + w2
	XuiSendToKid (grid, #Resize, x, y, w1, h, $Button1, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  GotKeyboardFocus  *****
'
SUB GotKeyboardFocus
	XuiSendToKid (grid, #ShowTextCursor, -1, -1, -1, -1, $Text, 0)
END SUB
'
'
' *****  LostKeyboardFocus  *****
'
SUB LostKeyboardFocus
	XuiSendToKid (grid, #HideTextCursor, -1, -1, -1, -1, $Text, 0)
END SUB
'
'
' *****  KeyDown  *****  Send upArrow, downArrow, pageUp, pageDown to XuiList
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	IF (v2{$$KeyKind} = $$KeyKindVirtual) THEN
		key = v2{8,0}
		SELECT CASE key
			CASE $$KeyUpArrow, $$KeyDownArrow, $$KeyPageUp, $$KeyPageDown
						XuiSendToKid (grid, #KeyDown, v0, v1, v2, v3, $List, r1)
			CASE ELSE
						XuiSendToKid (grid, #KeyDown, v0, v1, v2, v3, $Text, r1)
		END SELECT
	ELSE
		XuiSendToKid (grid, #KeyDown, v0, v1, v2, v3, $Text, r1)
	END IF
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
	abort = r0
	XuiCallback (grid, #TextEvent, v0, v1, v2, v3, @abort, grid)
	IF (abort = -1) THEN EXIT SUB
	IF (v2 AND $$TextModifyBit) THEN XgrJamMessage (grid, #TextModified, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  TextModified  *****
'
SUB TextModified
	XuiSendToKid (grid, #GetTextString, 0, 0, 0, 0, $Text, @text$)
	IFZ text$ THEN EXIT SUB
	XuiSendToKid (grid, #GrabTextArray, 0, 0, 0, 0, $List, @list$[])
	IFZ list$[] THEN EXIT SUB
	uList = UBOUND(list$[])
	IF (uList = 0) THEN
		XuiSendToKid (grid, #PokeTextArray, 0, 0, 0, 0, $List, @list$[])
		EXIT SUB
	END IF
	lenText = LEN(text$)
	FOR line = 0 TO uList
		lenLine = LEN(list$[line])
		IF (lenLine < lenText) THEN DO NEXT
		IF (text$ = LEFT$(list$[line],lenText)) THEN EXIT FOR
	NEXT line
	XuiSendToKid (grid, #PokeTextArray, 0, 0, 0, 0, $List, @list$[])
	IF (line <= uList) THEN
		XuiSendToKid (grid, #SetTextCursor, 0, line, -1, -1, $List, 0)
	END IF
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#GetSmallestSize]		= 0
	func[#MouseDown]					= &XuiMouseDownSetKeyboardFocus()
	func[#Resize]							= 0
	func[#Selection]					= &XuiCallback()
'
	DIM sub[upperMessage]
	sub[#Callback]						= SUBADDRESS (Callback)
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#GotKeyboardFocus]		= SUBADDRESS (GotKeyboardFocus)
	sub[#KeyDown]							= SUBADDRESS (KeyDown)
	sub[#LostKeyboardFocus]		= SUBADDRESS (LostKeyboardFocus)
	sub[#Resize]							= SUBADDRESS (Resize)
	sub[#TextEvent]						= SUBADDRESS (TextEvent)
	sub[#TextModified]				= SUBADDRESS (TextModified)
'
	IF func[0] THEN PRINT "XuiListDialog2B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiListDialog2B() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiListDialog2B, @"XuiListDialog2B", &XuiListDialog2B(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 96
	designHeight = 96
'
	gridType = XuiListDialog2B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        designWidth)
	XuiSetGridTypeValue (gridType, @"minHeight",       designHeight)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Text)
	XuiSetGridTypeValue (gridType, @"inputTextString",  $Text)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  XuiMessage1B ()  #####  Label and PushButton
' #############################
'
FUNCTION  XuiMessage1B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiMessage1B
'
	$Message1B		= 0
	$Label				= 1
	$Button0			= 2
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiMessage1B) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiMessage1B, @v0, @v1, @v2, @v3, r0, r1, &XuiMessage1B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage1B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PushButton")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiMessage1B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
'
	XuiSendToKid (grid, #GetSmallestSize, @labelWidth, @labelHeight, 0, 0, $Label, 8)
	XuiSendToKid (grid, #GetSmallestSize, @width, @height, 0, 0, $Button0, 8)
	IF (width > buttonWidth) THEN buttonWidth = width
	IF (height > buttonHeight) THEN buttonHeight = height
'
	width = buttonWidth
	height = labelHeight + buttonHeight
	IF (width < labelWidth) THEN width = labelWidth
	v2 = width + bw + bw
	v3 = height + bw + bw
END SUB
'
'
' *****  Resize  *****		This reconfigures window to current text sizes
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	IF (v3 >= (labelHeight + buttonHeight + bw + bw + 4)) THEN buttonHeight = buttonHeight + 4
'
	labelWidth	= v2 - bw - bw
	labelHeight	= v3 - buttonHeight - bw - bw
	buttonWidth	= labelWidth
'
	x = bw
	y = bw
	XuiSendToKid (grid, #Resize, x, y, labelWidth, labelHeight, $Label, 0)
'
	y = y + labelHeight
	XuiSendToKid (grid, #Resize, x, y, buttonWidth, buttonHeight, $Button0, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
'
	IF func[0] THEN PRINT "XuiMessage1B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiMessage1B() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiMessage1B, @"XuiMessage1B", &XuiMessage1B(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 48
'
	gridType = XuiMessage1B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Button0)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  XuiMessage2B ()  #####  Label and 2 PushButtons
' #############################
'
FUNCTION  XuiMessage2B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiMessage2B
'
	$Message2B		= 0
	$Label				= 1
	$Button0			= 2
	$Button1			= 3
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiMessage2B) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiMessage2B, @v0, @v1, @v2, @v3, r0, r1, &XuiMessage2B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage2B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage2B(), -1, -1, $Button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiMessage2B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, @labelWidth, @labelHeight, 0, 0, $Label, 8)
	FOR i = $Button0 TO $Button1
		XuiSendToKid (grid, #GetSmallestSize, @width, @height, 0, 0, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth
	height = labelHeight + buttonHeight
	IF (width < labelWidth) THEN width = labelWidth
	v2 = width + bw + bw
	v3 = height + bw + bw
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	IF (v3 >= (labelHeight + buttonHeight + bw + bw + 4)) THEN buttonHeight = buttonHeight + 4
'
	labelWidth	= v2 - bw - bw
	labelHeight	= v3 - buttonHeight - bw - bw
	buttonWidth	= labelWidth >> 1
	width0			= buttonWidth
	width1			= labelWidth - width0
'
	x = bw : y = bw
	XuiSendToKid (grid, #Resize, x, y, labelWidth, labelHeight, $Label, 0)
'
	h = buttonHeight
	y = y + labelHeight
	XuiSendToKid (grid, #Resize, x, y, width0, h, $Button0, 0) : x = x + width0
	XuiSendToKid (grid, #Resize, x, y, width1, h, $Button1, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
'
	IF func[0] THEN PRINT "XuiMessage2B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiMessage2B() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiMessage2B, @"XuiMessage2B", &XuiMessage2B(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 160
	designHeight = 48
'
	gridType = XuiMessage2B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Button0)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  XuiMessage3B ()  #####  Label and 3 PushButtons
' #############################
'
FUNCTION  XuiMessage3B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiMessage3B
'
	$Message3B		= 0
	$Label				= 1
	$Button0			= 2
	$Button1			= 3
	$Button2			= 4
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiMessage3B) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiMessage3B, @v0, @v1, @v2, @v3, r0, r1, &XuiMessage3B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage3B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage3B(), -1, -1, $Button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Option")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage3B(), -1, -1, $Button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button2")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiMessage3B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, @labelWidth, @labelHeight, 0, 0, $Label, 8)
	FOR i = $Button0 TO $Button2
		XuiSendToKid (grid, #GetSmallestSize, @width, @height, 0, 0, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth + buttonWidth + buttonWidth
	height = labelHeight + buttonHeight
	IF (width < labelWidth) THEN width = labelWidth
	v2 = width + bw + bw
	v3 = height + bw + bw
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	v2 = MAX(vv2, v2)
	v3 = MAX(vv3, v3)
'
	width				= buttonWidth + buttonWidth + buttonWidth
	height			= labelHeight + buttonHeight + bw + bw
	IF (width < labelWidth) THEN width = labelWidth
	width				= width + bw + bw
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	IF (v3 >= (labelHeight + buttonHeight + bw + bw + 4)) THEN buttonHeight = buttonHeight + 4
'
	labelWidth	= v2 - bw - bw
	labelHeight	= v3 - buttonHeight - bw - bw
	buttonWidth	= labelWidth / 3
	width0			= buttonWidth
	width1			= buttonWidth
	width2			= labelWidth - width0 - width1
'
	x = bw
	y = bw
	XuiSendToKid (grid, #Resize, x, y, labelWidth, labelHeight, $Label, 0)
'
	h = buttonHeight
	y = y + labelHeight
	XuiSendToKid (grid, #Resize, x, y, width0, h, $Button0, 0) : x = x + width0
	XuiSendToKid (grid, #Resize, x, y, width1, h, $Button1, 0) : x = x + width1
	XuiSendToKid (grid, #Resize, x, y, width2, h, $Button2, 0) : x = x + width2
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
'
	IF func[0] THEN PRINT "XuiMessage3B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiMessage3B() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiMessage3B, @"XuiMessage3B", &XuiMessage3B(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 240
	designHeight = 48
'
	gridType = XuiMessage3B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Button0)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  XuiMessage4B ()  #####  Label and 4 PushButtons
' #############################
'
FUNCTION  XuiMessage4B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiMessage4B
'
	$Message4B	= 0  ' kid 0
	$Label			= 1  ' kid 1
	$Button0		= 2  ' kid 2
	$Button1		= 3  ' kid 3
	$Button2		= 4  ' kid 4
	$Button3		= 5  ' kid 5
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiMessage4B) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiMessage4B, @v0, @v1, @v2, @v3, r0, r1, &XuiMessage4B())
	XuiLabel       (@g, #Create, 4, 4, 400, 28, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 4, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage4B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
	XuiPushButton  (@g, #Create, 104, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage4B(), -1, -1, $Button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Update")
	XuiPushButton  (@g, #Create, 204, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage4B(), -1, -1, $Button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button2")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Retry")
	XuiPushButton  (@g, #Create, 304, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiMessage4B(), -1, -1, $Button3, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button3")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiMessage4B")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiSendToKid (grid, #GetSmallestSize, @labelWidth, @labelHeight, 0, 0, $Label, 8)
	FOR i = $Button0 TO $Button3
		XuiSendToKid (grid, #GetSmallestSize, @width, @height, 0, 0, i, 8)
		IF (width > buttonWidth) THEN buttonWidth = width
		IF (height > buttonHeight) THEN buttonHeight = height
	NEXT i
	width = buttonWidth << 2
	height = labelHeight + buttonHeight
	IF (width < labelWidth) THEN width = labelWidth
	v2 = width + bw + bw
	v3 = height + bw + bw
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
	width				= buttonWidth + buttonWidth + buttonWidth
	height			= labelHeight + buttonHeight + bw + bw
	IF (width < labelWidth) THEN width = labelWidth
	width				= width + bw + bw
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	IF (v3 >= (labelHeight + buttonHeight + bw + bw + 4)) THEN buttonHeight = buttonHeight + 4
'
	labelWidth	= v2 - bw - bw
	labelHeight	= v3 - buttonHeight - bw - bw
	buttonWidth	= labelWidth >> 2
	width0			= buttonWidth
	width1			= buttonWidth
	width2			= buttonWidth
	width3			= labelWidth - width0 - width1 - width2
'
	x = bw
	y = bw
	XuiSendToKid (grid, #Resize, x, y, labelWidth, labelHeight, $Label, 0)
'
	h = buttonHeight
	y = y + labelHeight
	XuiSendToKid (grid, #Resize, x, y, width0, h, $Button0, 0) : x = x + width0
	XuiSendToKid (grid, #Resize, x, y, width1, h, $Button1, 0) : x = x + width1
	XuiSendToKid (grid, #Resize, x, y, width2, h, $Button2, 0) : x = x + width2
	XuiSendToKid (grid, #Resize, x, y, width3, h, $Button3, 0) : x = x + width3
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]						= &XuiCallback()
	func[#GetSmallestSize]		= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
'
	IF func[0] THEN PRINT "XuiMessage4B() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiMessage4B() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiMessage4B, @"XuiMessage4B", &XuiMessage4B(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 320
	designHeight = 48
'
	gridType = XuiMessage4B
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"focusKid",         $Button0)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###############################
' #####  XuiPressButton ()  #####
' ###############################
'
FUNCTION  XuiPressButton (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiPressButton
	STATIC	downGrid
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiPressButton) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiPressButton, @v0, @v1, @v2, @v3, r0, r1, &XuiPressButton())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiPressButton")
END SUB
'
'
' *****  KeyDown  *****  #Selection on $$KeyEnter
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, 0, 0, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	state = v2															' v2 = state
	key = state{8,24}												' virtual key
	XuiCallback (grid, #TextEvent, v0, v1, v2, v3, 0, grid)
	IF (key = $$KeyEnter) THEN XuiCallback (grid, #Selection, 0, 0, v2, v3, 0, grid)
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	IF downGrid THEN downGrid = 0 : EXIT SUB
	XuiGetValue (grid, #GetValue, @on, 0, 0, 0, 0, 0)
	IF on THEN EXIT SUB
	XuiCallback (grid, #Selection, 0, 0, v2, v3, 0, grid)
	XuiGetTimer (grid, #GetTimer, @timer, 0, 0, 0, 0, 0)
	IFZ timer THEN EXIT SUB
	XuiStartTimer (grid, #StartTimer, 0, 0, 0, 0, 0, 0)
	XuiSetValue (grid, #SetValue, 1, 0, 0, 0, 0, 0)
	downGrid = grid
END SUB
'
'
' *****  RedrawGrid  *****  executes after func[#RedrawGrid]
'
SUB RedrawGrid
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	XuiGetValues (grid, #GetValues, @x1, @y1, @x2, @y2, 0, 0)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	XuiGetSize (grid, #GetSize, 0, 0, @w, @h, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	IFZ (style AND 0x1E) THEN EXIT SUB
	direction = style AND 0x001E
	XgrFillTriangle (grid, -1, 0, direction, x1, y1, x2, y2)
END SUB
'
'
' *****  TimeOff  *****
'
SUB TimeOff
	downGrid = 0
	XuiSetValue (grid, #SetValue, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  TimeOut  *****
'
SUB TimeOut
	XuiGetValue (grid, #GetValue, @on, 0, 0, 0, 0, 0)
	XuiGetTimer (grid, #GetTimer, @timer, 0, 0, 0, 0, 0)
	callback = $$TRUE
	SELECT CASE on
		CASE 0		: callback = $$FALSE
		CASE 2		: callback = $$FALSE
	END SELECT
	IF callback THEN XuiCallback (grid, #Selection, 0, 0, v2, v3, 0, grid)
	restart = on && timer && downGrid
	on = on + 1
'
	IF restart THEN
		XuiStartTimer (grid, #StartTimer, 0, 0, 0, 0, 0, 0)
		XuiSetValue (grid, #SetValue, on, 0, 0, 0, 0, 0)
	ELSE
		XuiSetValue (grid, #SetValue, 0, 0, 0, 0, 0, 0)
		downGrid = 0
	END IF
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#KeyDown]							= SUBADDRESS (KeyDown)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#MouseExit]						= SUBADDRESS (TimeOff)
	sub[#MouseUp]							= SUBADDRESS (TimeOff)
	sub[#Redraw]							= SUBADDRESS (RedrawGrid)
	sub[#RedrawGrid]					= SUBADDRESS (RedrawGrid)
	sub[#TimeOut]							= SUBADDRESS (TimeOut)
'
	IF func[0] THEN PRINT "XuiPressButton() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiPressButton() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiPressButton, @"XuiPressButton", &XuiPressButton(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 20
'
	gridType = XuiPressButton
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",          4)
	XuiSetGridTypeValue (gridType, @"minHeight",         4)
	XuiSetGridTypeValue (gridType, @"align",           $$AlignMiddleCenter)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRaise1)
	XuiSetGridTypeValue (gridType, @"borderUp",        $$BorderRaise1)
	XuiSetGridTypeValue (gridType, @"borderDown",      $$BorderLower1)
	XuiSetGridTypeValue (gridType, @"texture",         $$TextureLower1)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawDefault)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ############################
' #####  XuiProgress ()  #####
' ############################
'
FUNCTION  XuiProgress (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiProgress
'
	$Progress		= 0
'
	$position		= 0
	$fullScale	= 1
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiProgress) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiProgress, @v0, @v1, 120, 40, r0, r1, &XuiProgress())
	XuiSetColorExtra (grid, #SetColorExtra, -1, $$LightGreen, -1, -1, 0, 0)
	XuiSetValues   ( grid, #SetValues, 0, 100, 0, 0, 0, $position)
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiProgress")
END SUB
'
'
' ****  Resize  *****
'
SUB Resize
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  SetValue  *****
'
SUB SetValue
	XuiGetValues (grid, #GetValues, @position, @fullScale, 0, 0, 0, 0)
	XuiSetValue (grid, #SetValue, v0, v1, v2, v3, 0, r1)
	GOSUB UpdatePosition
END SUB
'
'
' *****  SetValues  *****
'
SUB SetValues
	XuiGetValues (grid, #GetValues, @position, @fullScale, 0, 0, 0, 0)
	XuiSetValues (grid, #SetValues, v0, v1, v2, v3, 0, r1)
	GOSUB UpdatePosition
END SUB
'
'
' *****  UpdatePosition  *****
'
SUB UpdatePosition
	XuiGetValues (grid, #GetValues, @v0, @v1, 0, 0, 0, 0)
	IF (v0 < 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = fullScale
	IF (v0 > v1) THEN v0 = v1
	XuiSetValues (grid, #SetValues, v0, v1, 0, 0, 0, 0)
	IF ((v0 = position) AND (v1 = fullScale)) THEN EXIT SUB
	IF (v0 > position) THEN
		XgrGetGridPositionAndSize (grid, 0, 0, @w, @h)
		XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
		XuiGetColorExtra (grid, #GetColorExtra, @d, @accent, 0, 0, 0, 0)
		m# = DOUBLE (v0) / DOUBLE (v1)
		w = m# * (w-bw-bw)
		IF (w < 1) THEN w = 1
		XgrFillBox (grid, accent, bw, bw, bw+w-1, h-bw-1)
	ELSE
		GOSUB Redraw
	END IF
END SUB
'
'
' *****  Redraw  *****
'
SUB Redraw
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	XuiRedraw (grid, #Redraw, 0, 0, 0, 0, 0, 0)
	XgrGetGridPositionAndSize (grid, @vv0, @vv1, @vv2, @vv3)
	XuiGetBorder (grid, #GetBorder, 0, 0, 0, 0, 0, @bw)
	XuiGetColorExtra (grid, #GetColorExtra, @d, @accent, 0, 0, 0, 0)
	XuiGetValues (grid, #GetValues, @position, @fullScale, 0, 0, 0, $position)
	m# = DOUBLE (position) / DOUBLE (fullScale)
	w = m# * (vv2-bw-bw)
	IF (w < 1) THEN w = 1
	XgrFillBox (grid, $$Grey, bw, bw, vv2-bw-1, vv3-bw-1)
	XgrFillBox (grid, accent, bw, bw, bw+w-1, vv3-bw-1)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#GetSmallestSize]		= &XuiGetMaxMinSize()
	func[#Redraw]							= 0
	func[#Resize]							= 0
	func[#SetPosition]				= 0
	func[#SetValue]						= 0
	func[#SetValues]					= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#SetPosition]				  = SUBADDRESS (SetValues)
	sub[#SetValue]						= SUBADDRESS (SetValue)
	sub[#SetValues]						= SUBADDRESS (SetValues)
	sub[#Redraw]							= SUBADDRESS (Redraw)
	sub[#Resize]							= SUBADDRESS (Resize)
'
	IF func[0] THEN PRINT "XuiProgress() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiProgress() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiProgress, @"XuiProgress", &XuiProgress(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 40
'
	gridType = XuiProgress
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        24)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderFrame)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##############################
' #####  XuiPushButton ()  #####
' ##############################
'
FUNCTION  XuiPushButton (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiPushButton
	STATIC	downGrid
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiPushButton) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiPushButton, @v0, @v1, @v2, @v3, r0, r1, &XuiPushButton())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiPushButton")
END SUB
'
'
' *****  KeyDown  *****  #Selection callback on $$KeyEnter
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, 0, 0, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	state = v2															' v2 = state
	key = state{8,24}												' virtual key
	IF (key = $$KeyEnter) THEN XuiCallback (grid, #Selection, v0, v1, v2, v3, 0, grid)
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	XuiGetState (grid, #GetState, @state, 0, @mouse, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	IF (style AND 1) THEN
		XuiCallback (grid, #Selection, 0, 0, v2, v3, 0, grid)
		EXIT SUB
	END IF
	XuiGetBorder (grid, #GetBorder, 0, 0, @border, 0, 0, 0)
	XuiSetBorder (grid, #SetBorder, border, -1, -1, 0, 0, 0)
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiPushButton(), 0, 0, 0, $$TRUE)
	downGrid = grid
END SUB
'
'
' *****  MouseEnter  *****
'
SUB MouseEnter
	IF (grid != r1) THEN EXIT SUB
	IF (grid != downGrid) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	XuiGetState (grid, #GetState, @state, 0, @mouse, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	XuiGetBorder (grid, #GetBorder, 0, 0, @border, 0, 0, 0)
	XuiSetBorder (grid, #SetBorder, border, -1, -1, 0, 0, 0)
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  MouseExit  *****
'
SUB MouseExit
	IF (grid != r1) THEN EXIT SUB
	IF (grid != downGrid) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	XuiGetState (grid, #GetState, @state, 0, @mouse, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	XuiGetBorder (grid, #GetBorder, 0, @border, 0, 0, 0, 0)
	XuiSetBorder (grid, #SetBorder, border, -1, -1, 0, 0, 0)
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  MouseUp  *****
'
SUB MouseUp
	IFZ downGrid THEN EXIT SUB
	IF (v2{$$ButtonNumber} = $$HelpButtonNumber) THEN EXIT SUB
	XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiPushButton(), 0, 0, 0, $$FALSE)
	XuiGetState (grid, #GetState, @state, 0, @mouse, 0, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	XgrGetGridBoxLocal (downGrid, @x1, @y1, @x2, @y2)
	inside = $$TRUE
	SELECT CASE TRUE
		CASE (v0 < x1)	: inside = $$FALSE
		CASE (v0 > x2)	: inside = $$FALSE
		CASE (v1 < y1)	: inside = $$FALSE
		CASE (v1 > y2)	: inside = $$FALSE
	END SELECT
	downGrid = 0
	IFZ inside THEN EXIT SUB
	XuiGetBorder (grid, #GetBorder, 0, @border, 0, 0, 0, 0)
	XuiSetBorder (grid, #SetBorder, border, -1, -1, 0, 0, 0)
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	XuiCallback (grid, #Selection, 0, 0, v2, v3, 0, grid)
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	DIM sub[upperMessage]
	sub[#Create]						= SUBADDRESS (Create)
	sub[#CreateWindow]			= SUBADDRESS (CreateWindow)
	sub[#KeyDown]						= SUBADDRESS (KeyDown)
	sub[#MouseDown]					= SUBADDRESS (MouseDown)
	sub[#MouseEnter]				= SUBADDRESS (MouseEnter)
	sub[#MouseExit]					= SUBADDRESS (MouseExit)
	sub[#MouseUp]						= SUBADDRESS (MouseUp)
'
	IF func[0] THEN PRINT "XuiPushButton() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiPushButton() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiPushButton, @"XuiPushButton", &XuiPushButton(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 20
'
	gridType = XuiPushButton
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",         4)
	XuiSetGridTypeValue (gridType, @"minHeight",        4)
	XuiSetGridTypeValue (gridType, @"align",           $$AlignMiddleCenter)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRaise2)
	XuiSetGridTypeValue (gridType, @"borderUp",        $$BorderRaise2)
	XuiSetGridTypeValue (gridType, @"borderDown",      $$BorderLower2)
	XuiSetGridTypeValue (gridType, @"texture",         $$TextureLower1)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawDefault)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ############################
' #####  XuiRadioBox ()  #####
' ############################
'
FUNCTION  XuiRadioBox (grid, message, v0, v1, v2, v3, r0, r1)
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiRadioBox
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiRadioBox) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiRadioBox, @v0, @v1, @v2, @v3, r0, r1, &XuiRadioBox())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiRadioBox")
END SUB
'
'
' *****  KeyDown  *****
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	state = v2																			' v2 = state
	key = state{8,24}																' virtual key
	IF (state AND $$AltBit) THEN EXIT SUB						' disallow Alt+Enter
	IF (key = $$KeyEnter) THEN GOSUB ButtonOn				' got Enter
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	GOSUB ButtonOn
END SUB
'
'
' *****  SetValue  *****
'
SUB SetValue
	IF r1 THEN EXIT SUB
	GOSUB SetValues
END SUB
'
'
' *****  SetValues  *****
'
SUB SetValues
	XuiGetValue (grid, #GetValue, @value0, 0, 0, 0, 0, 0)
	IF v0 THEN GOSUB ButtonOn ELSE GOSUB ButtonOff
END SUB
'
'
' *****  ButtonOff  *****
'
SUB ButtonOff
	XuiGetValue (grid, #GetValue, @value0, 0, 0, 0, 0, 0)
	IFZ value0 THEN EXIT SUB
	XuiSetValue (grid, #SetValue, $$FALSE, 0, 0, 0, 0, 0)
	GOSUB RedrawGrid
	XuiCallback (grid, #Selection, 0, 0, 0, 0, 0, grid)
END SUB
'
'
' *****  ButtonOn  *****
'
SUB ButtonOn
	XuiGetValue (grid, #GetValue, @value0, 0, 0, 0, 0, 0)
	IF value0 THEN EXIT SUB
	XuiSetValue  (grid, #SetValue, $$TRUE, 0, 0, 0, 0, 0)
	GOSUB ResetOtherRadioBoxes
	GOSUB RedrawGrid
	XuiCallback (grid, #Selection, -1, 0, 0, 0, 0, grid)
END SUB
'
'
' *****  ResetOtherRadioBoxes  *****  reset grids in same .group
'
SUB ResetOtherRadioBoxes
	XuiGetEnclosingGrid (grid, #GetEnclosingGrid, @gg, 0, 0, 0, 0, 0)
	XuiGetEnclosedGrids (gg, #GetEnclosedGrids, 0, 0, 0, 0, 0, @kk[])
	XuiGetGroup (grid, #GetGroup, @group, 0, 0, 0, 0, 0)
	IFZ group THEN EXIT SUB
'
	IF kk[] THEN
		FOR i = 0 TO UBOUND(kk[])
			k = kk[i]
			IF (k = grid) THEN DO NEXT
			IF k THEN XuiSendMessage (k, #GetGroup, @check, 0, 0, 0, 0, 0)
			IF (group = check) THEN XuiSendMessage (k, #SetValue, 0, 0, 0, 0, 0, 0)
		NEXT i
	END IF
END SUB
'
'
' *****  RedrawGrid  *****
'
SUB RedrawGrid
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	width = x2 - x1 + 1 : height = y2 - y1 + 1
	XuiGetValue (grid, #GetValue, @state, 0, 0, 0, 0, 0)
	XuiGetColor (grid, #GetColor, @back, @draw, @lo, @hi, 0, 0)
	XuiGetColorExtra (grid, #GetColorExtra, 0, @acc, 0, 0, 0, 0)
	XuiGetAlign (grid, #GetAlign, 0, 0, @inX, @inY, 0, @bw)
	xx = x1 + ((inX - 12) >> 1) + bw - 1 + 6
	yy = y1 + (height >> 1)
	XgrMoveTo (grid, xx, yy)
	XgrDrawCircle (grid, draw, 6)
	XgrDrawCircle (grid, draw, 5)
	IF state THEN
		XgrDrawCircle (grid,  acc, 4)
		XgrDrawCircle (grid,  acc, 3)
		XgrDrawCircle (grid, draw, 2)
		XgrDrawCircle (grid, draw, 1)
		XgrDrawCircle (grid, draw, 0)
		XgrDrawLine (grid, draw, xx-1, yy-1, xx+1, yy+1)
		XgrDrawLine (grid, draw, xx-1, yy+1, xx+1, yy-1)
	END IF
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#SetValue]						= 0
	func[#SetValues]					= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#KeyDown]							= SUBADDRESS (KeyDown)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#RedrawGrid]					= SUBADDRESS (RedrawGrid)
	sub[#SetValue]						= SUBADDRESS (SetValue)
	sub[#SetValues]						= SUBADDRESS (SetValues)
'
	IF func[0] THEN PRINT "XuiRadioBox() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiRadioBox() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiRadioBox, @"XuiRadioBox", &XuiRadioBox(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 20
'
	gridType = XuiRadioBox
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"indentLeft",      24)
	XuiSetGridTypeValue (gridType, @"group",            2)
	XuiSetGridTypeValue (gridType, @"align",           $$AlignMiddleLeft)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRaise1)
	XuiSetGridTypeValue (gridType, @"texture",         $$TextureLower1)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawDefault)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###############################
' #####  XuiRadioButton ()  #####
' ###############################
'
FUNCTION  XuiRadioButton (grid, message, v0, v1, v2, v3, r0, (r1, r1[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiRadioButton
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiRadioButton) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiRadioButton, @v0, @v1, @v2, @v3, r0, r1, &XuiRadioButton())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiRadioButton")
END SUB
'
'
' *****  KeyDown  *****
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	state = v2																			' v2 = state
	key = state{8,24}																' virtual key
	IF (state AND $$AltBit) THEN EXIT SUB						' disallow Alt+Enter
	IF (key = $$KeyEnter) THEN GOSUB ButtonOn				' got Enter
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	GOSUB ButtonOn
END SUB
'
'
' *****  SetValue  *****
'
SUB SetValue
	IF r1 THEN EXIT SUB
	GOSUB SetValues
END SUB
'
'
' *****  SetValues  *****
'
SUB SetValues
	XuiGetValue (grid, #GetValue, @value0, 0, 0, 0, 0, 0)
	IF v0 THEN GOSUB ButtonOn ELSE GOSUB ButtonOff
END SUB
'
'
' *****  ButtonOff  *****
'
SUB ButtonOff
	XuiGetValue (grid, #GetValue, @value0, 0, 0, 0, 0, 0)
	IFZ value0 THEN EXIT SUB
	XuiSetValue (grid, #SetValue, $$FALSE, 0, 0, 0, 0, 0)
	XuiGetBorder (grid, #GetBorder, 0, @border, 0, 0, 0, 0)
	XuiSetBorder (grid, #SetBorder, border, -1, -1, -1, 0, 0)
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	XuiCallback (grid, #Selection, 0, 0, 0, 0, 0, grid)
END SUB
'
'
' *****  ButtonOn  *****
'
SUB ButtonOn
	XuiGetValue (grid, #GetValue, @value0, 0, 0, 0, 0, 0)
	IF value0 THEN EXIT SUB
	XuiSetValue (grid, #SetValue, $$TRUE, 0, 0, 0, 0, 0)
	XuiGetBorder (grid, #GetBorder, 0, 0, @border, 0, 0, 0)
	XuiSetBorder (grid, #SetBorder, border, -1, -1, -1, 0, 0)
	GOSUB ResetOtherRadioButtons
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	XuiCallback (grid, #Selection, -1, 0, 0, 0, 0, grid)
END SUB
'
'
' *****  ResetOtherRadioButtons  *****  reset grids in same .group
'
SUB ResetOtherRadioButtons
	XuiGetEnclosingGrid (grid, #GetEnclosingGrid, @gg, 0, 0, 0, 0, 0)
	XuiGetEnclosedGrids (gg, #GetEnclosedGrids, 0, 0, 0, 0, 0, @kk[])
	XuiGetGroup (grid, #GetGroup, @group, 0, 0, 0, 0, 0)
	IFZ group THEN EXIT SUB
'
	IF kk[] THEN
		FOR i = 0 TO UBOUND(kk[])
			k = kk[i]
			IF (k = grid) THEN DO NEXT
			IF k THEN XuiSendMessage (k, #GetGroup, @check, 0, 0, 0, 0, 0)
			IF (group = check) THEN XuiSendMessage (k, #SetValue, 0, 0, 0, 0, 0, 0)
		NEXT i
	END IF
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#SetValue]						= 0
	func[#SetValues]					= 0
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#KeyDown]							= SUBADDRESS (KeyDown)
	sub[#MouseDown]						= SUBADDRESS (MouseDown)
	sub[#SetValue]						= SUBADDRESS (SetValue)
	sub[#SetValues]						= SUBADDRESS (SetValues)
'
	IF func[0] THEN PRINT "XuiRadioButton() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiRadioButton() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiRadioButton, @"XuiRadioButton", &XuiRadioButton(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 20
'
	gridType = XuiRadioButton
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        32)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"group",            1)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRaise2)
	XuiSetGridTypeValue (gridType, @"borderUp",        $$BorderRaise2)
	XuiSetGridTypeValue (gridType, @"borderDown",      $$BorderLower2)
	XuiSetGridTypeValue (gridType, @"texture",         $$TextureLower1)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawDefault)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #########################
' #####  XuiRange ()  #####
' #########################
'
FUNCTION  XuiRange (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiRange
'
	$Range			= 0
	$Label			= 1
	$ButtonUp		= 2
	$ButtonDown	= 3
'
	$value			= 0
	$addStep		= 1
	$minimum		= 2
	$maximum		= 3
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiRange) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
	callback = message
	IF (message <= upperMessage) THEN GOSUB @sub[message]
END SUB
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, XuiRange, @v0, @v1, @v2, @v3, r0, r1, &XuiRange())
	XuiCreateValueArray (grid, #CreateValueArray, 3, 0, 0, 0, 0, 0)
	XuiSetValues   ( grid, #SetValues, 0, 1, 0, 100, 0, 0)
	XuiLabel       (@g, #Create, 0,  0, 48, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, -1, -1, -1, 0, 0)
	XuiPressButton (@g, #Create, 48, 0, 12, 12, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiRange(), -1, -1, $ButtonUp, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTimer, 100, 0, 0, 0, 0, 0)
	XuiPressButton (@g, #Create, 48, 12, 12, 12, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiRange(), -1, -1, $ButtonDown, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTimer, 100, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #GetRedrawFlags, @r, 0, 0, 0, 0, 0)
	r = r AND NOT $$RedrawTextArray AND NOT $$RedrawTextString
	XuiSendMessage ( grid, #SetRedrawFlags, r, 0, 0, 0, $ButtonUp, 0)
	XuiSendMessage ( grid, #SetRedrawFlags, r, 0, 0, 0, $ButtonDown, 0)
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiRange")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @w1, @h1, $Label, 8)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @w2, @h2, $ButtonUp, 4)
	XuiSendToKid (grid, #GetSmallestSize, 0, 0, @w3, @h3, $ButtonDown, 4)
	big = (h1 + 1) >> 1
	IF (big < w2) THEN big = w2
	IF (big < w3) THEN big = w3
	IF (big < h2) THEN big = h2
	IF (big < h3) THEN big = h3
	w2 = big : w3 = big : h2 = big : h3 = big
	IF (h1 < (h2 + h3)) THEN h1 = h2 + h3
	IF (h1 > (h2 + h3)) THEN
		h1 = (h1 + 1) AND -2
		big = h1 >> 1
		w2 = big : w3 = big : h2 = big : h3 = big
	END IF
	IF (w1 < 16) THEN w1 = 16
	v2 = w1 + w2
	v3 = h1
END SUB
'
'
' *****  Redraw  *****
'
SUB Redraw
	XuiGetValue (grid, #GetValue, @value, 0, 0, 0, 0, 0)
	value$ = STRING$ (value)
	XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Label, @value$)
	XuiRedraw (grid, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	v2 = MAX (v2, vv2)
	v3 = MAX (v3, vv3)
'
	IF (v2 < ((v3 >> 1) + 16)) THEN v2 = (v3 >> 1) + 16
	IF (v2 < ((v3 >> 1) + w1)) THEN v2 = (v3 >> 1) + w1
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	big = v3 >> 1
	w1 = v2 - big
	w2 = big
	w3 = big
	h1 = v3
	h2 = big
	h3 = big
'
	XuiSendToKid (grid, #Resize,  0,  0, w1, h1, $Label, 0)
	XuiSendToKid (grid, #Resize, w1,  0, w2, h2, $ButtonUp, 0)
	XuiSendToKid (grid, #Resize, w1, h2, w3, h3, $ButtonDown, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	XuiGetValues (grid, #GetValues, 0, @add, 0, 0, 0, 0)
	SELECT CASE r0
		CASE $ButtonUp		: add = ABS(add)
		CASE $ButtonDown	: add = -ABS(add)
	END SELECT
	GOSUB UpdateValue
	XuiSendToKid (grid, #RedrawGrid, 0, 0, 0, 0, $Label, 0)
	XuiCallback (grid, #Selection, value, add, vMin, vMax, 0, 0)
END SUB
'
'
' *****  CheckValues  *****
'
SUB CheckValues
	XuiGetValues (grid, #GetValues, @value, @add, @vMin, @vMax, 0, 0)
	IF (value < vMin) THEN value = vMin
	IF (value > vMax) THEN value = vMax
	XuiSetValues (grid, #SetValues, value, add, vMin, vMax, 0, 0)
END SUB
'
'
' *****  TimeOut  *****
'
SUB TimeOut
	XuiGetValues (grid, #GetValues, 0, @add, 0, 0, 0, 0)
	GOSUB UpdateValue
	XuiSendToKid (grid, #Redraw, 0, 0, 0, 0, $Label, 0)
	XuiCallback (grid, #Selection, value, add, vMin, vMax, 0, 0)
END SUB
'
'
' *****  UpdateValue  *****
'
SUB UpdateValue
	XuiGetValues (grid, #GetValues, @value, 0, @vMin, @vMax, 0, 0)
	value = value + add
	IF (value < vMin) THEN value = vMin
	IF (value > vMax) THEN value = vMax
	XuiSetValues (grid, #SetValues, value, add, vMin, vMax, 0, 0)
	value$ = STRING$ (value)
	XuiSendToKid (grid, #SetTextString, 0, 0, 0, 0, $Label, @value$)
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
	func[#Callback]						= 0
	func[#GetSmallestSize]		= 0
	func[#Redraw]							= 0
	func[#Resize]							= 0
'
	DIM sub[upperMessage]
	sub[#Callback]						= SUBADDRESS (Callback)
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Redraw]							= SUBADDRESS (Redraw)
	sub[#Resize]							= SUBADDRESS (Resize)
	sub[#Selection]						= SUBADDRESS (Selection)
	sub[#SetValue]						= SUBADDRESS (CheckValues)
	sub[#SetValues]						= SUBADDRESS (CheckValues)
'
	IF func[0] THEN PRINT "XuiRange() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiRange() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiRange, @"XuiRange", &XuiRange(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 24
'
	gridType = XuiRange
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        24)
	XuiSetGridTypeValue (gridType, @"minHeight",       16)
	XuiSetGridTypeValue (gridType, @"texture",         $$TextureRaise1)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##############################
' #####  XuiScrollBarH ()  #####
' ##############################
'
FUNCTION  XuiScrollBarH (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiScrollBarH
	STATIC	focusGrid
'
	$msTimeOut	= 10
	$minMouse		= 12
	$maxMouse		= 13
	$lastValue	= 15
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiScrollBarH) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiScrollBarH, @v0, @v1, @v2, @v3, r0, r1, &XuiScrollBarH())
	XuiCreateValueArray (grid, #CreateValueArray, $lastValue, 0, 0, 0, 0, 0)
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiScrollBarH")
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @zero, @lo, @hi, @upper, 0, 0)
	msTimeOut = 60
	XuiGetValue (grid, #GetValue, @time, 0, 0, 0, 0, $msTimeOut)
	IFZ time THEN msTimeOut = 500
	XuiSetValue (grid, #SetValue, msTimeOut, 0, 0, 0, 0, $msTimeOut)
	SELECT CASE TRUE
		CASE (v0 < zero)
					XuiCallback (grid, #OneLess, 0, 0, 0, 0, 0, 0)
					XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarH(), 0, 0, 0, $$TRUE)
					XgrSetGridTimer (grid, msTimeOut)
		CASE (v0 > upper)
					XuiCallback (grid, #OneMore, 0, 0, 0, 0, 0, 0)
					XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarH(), 0, 0, 0, $$TRUE)
					XgrSetGridTimer (grid, msTimeOut)
		CASE (v0 < lo)
					IF v2{1,24} THEN																	' Button 1
						XuiCallback (grid, #MuchLess, 0, 0, 0, 0, 0, 0)
						XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarH(), 0, 0, 0, $$TRUE)
						XgrSetGridTimer (grid, msTimeOut)
					ELSE
						XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 8)
						XuiSetValue (grid, #SetValue, v1, 0, 0, 0, 0, 9)
						focusGrid = grid
						GOSUB MouseDrag
					END IF
		CASE (v0 > hi)
					IF v2{1,24} THEN																	' Button 1
						XuiCallback (grid, #MuchMore, 0, 0, 0, 0, 0, 0)
						XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarH(), 0, 0, 0, $$TRUE)
						XgrSetGridTimer (grid, msTimeOut)
					ELSE
						XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 8)
						XuiSetValue (grid, #SetValue, v1, 0, 0, 0, 0, 9)
						focusGrid = grid
						GOSUB MouseDrag
					END IF
		CASE ELSE
					XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarH(), 0, 0, 0, $$TRUE)
					XuiSetValue (grid, #SetValue, v0, 0, 0, 0, 0, 8)
					XuiSetValue (grid, #SetValue, v1, 0, 0, 0, 0, 9)
					XuiSetValue (grid, #SetValue, v0 - (lo - zero), 0, 0, 0, 0, 12)		' minMouse
					XuiSetValue (grid, #SetValue, v0 + (upper - hi), 0, 0, 0, 0, 13)	' maxMouse
					focusGrid = grid
	END SELECT
END SUB
'
'
' *****  MouseDrag  *****
'
SUB MouseDrag
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	IFZ focusGrid THEN EXIT SUB
'
	IF (r1 = grid) THEN
		vv0 = v0 : vv1 = v1
	ELSE
		XgrConvertLocalToDisplay (r1, v0, v1, @d0, @d1)
		XgrConvertDisplayToLocal (grid, d0, d1, @vv0, @vv1)
	END IF
'
	XuiGetValues (grid, #GetValues, @zero, @lo, @hi, @upper, 0, 0)
	XuiGetValues (grid, #GetValues, @xOld, @yOld, 0, 0, 0, 8)
	XuiGetValues (grid, #GetValues, @minMouse, @maxMouse, 0, 0, 0, 12)
'
	IF (vv0 < minMouse) THEN vv0 = minMouse
	IF (vv0 > maxMouse) THEN vv0 = maxMouse
'
	XuiSetValue (grid, #SetValue, vv0, 0, 0, 0, 0, 8)
	XuiSetValue (grid, #SetValue, vv1, 0, 0, 0, 0, 9)
'
	IF (xOld = vv0) THEN EXIT SUB								' ignore y only motion
'
	olo = lo
	ohi = hi
	minMove = zero - lo
	maxMove = upper - hi
	delta = vv0 - xOld
	IF (delta < 0) THEN
		move = MAX (delta, minMove)
	ELSE
		move = MIN (delta, maxMove)
	END IF
'
	IFZ move THEN EXIT SUB
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	XgrGetGridColors (grid, @back, 0, @loColor, @hiColor, 0, 0, 0, 0)
	XgrDrawBorder (grid, $$BorderFlat, back, loColor, hiColor, olo-2, y1+2, ohi+2, y2-2)
	lo = lo + move
	hi = hi + move
	IF (lo < zero) THEN
		diff = zero - lo
		lo = lo + diff
	END IF
	IF (hi > upper) THEN
		diff = upper - hi
		hi = hi + diff
	END IF
	XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 1)
	XuiSetValue (grid, #SetValue, hi, 0, 0, 0, 0, 2)
	XgrDrawBorder (grid, $$BorderRaise, back, loColor, hiColor, lo-2, y1+2, hi+2, y2-2)
	XuiCallback (grid, #Change, 0, lo-zero, hi-zero, upper-zero, 0, 0)
END SUB
'
'
' *****  MouseUp  *****
'
SUB MouseUp
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2{$$ButtonNumber} = $$HelpButtonNumber) THEN EXIT SUB
	XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarH(), 0, 0, 0, $$FALSE)
	focusGrid = 0
	XuiSetValue (grid, #SetValue, 0, 0, 0, 0, 0, $msTimeOut)
	XgrSetGridTimer (grid, 0)
END SUB
'
'
' *****  Redraw  *****
'
SUB Redraw
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	XgrClearGrid (grid, -1)
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	XgrGetGridColors (grid, @back, 0, @lo, @hi, 0, 0, 0, 0)
	XuiGetValues (grid, #GetValues, 0, @low, @high, 0, 0, 0)
	XgrDrawBorder (grid, $$BorderRidge, back, lo, hi, x1, y1, x2, y2)
	XgrFillBox (grid, back, x1, y1, x1+11, y2)
	XgrFillBox (grid, back, x2-11, y1, x2, y2)
	left = style AND 0x0002
	right = style AND 0x0001
	IF left THEN XgrFillTriangle (grid, -1, 0, $$TriangleLeft, x1+2, y1+2, x1+8, y2-2)
	IF right THEN XgrFillTriangle (grid, -1, 0, $$TriangleRight, x2-8, y1+2, x2-2, y2-2)
	XgrDrawBorder (grid, $$BorderRaise, back, lo, hi, x1, y1, x1+11, y2)
	XgrDrawBorder (grid, $$BorderRaise, back, lo, hi, x2-11, y1, x2, y2)
	XgrDrawBorder (grid, $$BorderRaise, back, lo, hi, low-2, y1+2, high+2, y2-2)
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	XuiGetValues (grid, #GetValues, @lowest, @low, @high, @highest, 0, 4)
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	zero = 14
	upper = v2 - 15
	ComputeLimits (@lo, @hi, zero, upper, lowest, low, high, highest)
	XuiSetValues (grid, #SetValues, zero, lo, hi, upper, 0, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  GetPosition  *****
'
SUB GetPosition
	XuiGetValues (grid, #GetValues, @v0, @v1, @v2, @v3, 0, 0)
END SUB
'
'
' *****  SetPosition  *****
'
SUB SetPosition
	XuiGetValues (grid, #GetValues, @zero, @lo, @hi, @upper, 0, 0)
'
	lowest		= v0	' lowest line # in document
	low				= v1	' lowest line # displayed
	high			= v2	' highest line # displayed
	highest		= v3	' highest line # in document
'
	XuiSetValues (grid, #SetValues, v0, v1, v2, v3, 0, 4)
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	XgrGetGridColors (grid, @back, 0, @loColor, @hiColor, 0, 0, 0, 0)
	XgrDrawBorder (grid, $$BorderFlat, back, loColor, hiColor, lo-2, y1+2, hi+2, y2-2)
	ComputeLimits (@lo, @hi, zero, upper, lowest, low, high, highest)
	XgrDrawBorder (grid, $$BorderRaise, back, loColor, hiColor, lo-2, y1+2, hi+2, y2-2)
	XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 1)
	XuiSetValue (grid, #SetValue, hi, 0, 0, 0, 0, 2)
END SUB
'
'
' *****  TimeOut  *****
'
SUB TimeOut
	XgrGetGridWindow (grid, @window)
	XgrGetMouseInfo (window, @grid, @v0, @v1, @v2, @v3)		' x, y, state, time
	IFZ v2{2,24} THEN EXIT SUB														' buttons 12 not down
	GOSUB MouseDown
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#GetSmallestSize]	= &XuiGetMaxMinSize()
	func[#Redraw]						= 0
	func[#RedrawGrid]				= 0
	func[#Resize]						= 0
'
	DIM sub[upperMessage]
	sub[#Create]						= SUBADDRESS (Create)
	sub[#CreateWindow]			= SUBADDRESS (CreateWindow)
	sub[#GetPosition]				= SUBADDRESS (GetPosition)
	sub[#MouseDown]					= SUBADDRESS (MouseDown)
	sub[#MouseDrag]					= SUBADDRESS (MouseDrag)
	sub[#MouseUp]						= SUBADDRESS (MouseUp)
	sub[#Redraw]						= SUBADDRESS (Redraw)
	sub[#RedrawGrid]				= SUBADDRESS (Redraw)
	sub[#Resize]						= SUBADDRESS (Resize)
	sub[#SetPosition]				= SUBADDRESS (SetPosition)
	sub[#TimeOut]						= SUBADDRESS (TimeOut)
'
	IF func[0] THEN PRINT "XuiScrollBarH() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiScrollBarH() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiScrollBarH, @"XuiScrollBarH", &XuiScrollBarH(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 12
'
	gridType = XuiScrollBarH
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        48)
	XuiSetGridTypeValue (gridType, @"minHeight",       12)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRidge)
'	XuiSetGridTypeValue (gridType, @"style",            3)
	XuiSetGridTypeValue (gridType, @"can",             $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawNone)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ##############################
' #####  XuiScrollBarV ()  #####
' ##############################
'
FUNCTION  XuiScrollBarV (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiScrollBarV
	STATIC	focusGrid
'
	$msTimeOut	= 10
	$minMouse		= 12
	$maxMouse		= 13
	$lastValue	= 15
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiScrollBarV) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiScrollBarV, @v0, @v1, @v2, @v3, r0, r1, &XuiScrollBarV())
	XuiCreateValueArray (grid, #CreateValueArray, $lastValue, 0, 0, 0, 0, 0)
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiScrollBarV")
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	XuiGetValues (grid, #GetValues, @zero, @lo, @hi, @upper, 0, 0)
	msTimeOut = 60
	XuiGetValue (grid, #GetValue, @time, 0, 0, 0, 0, $msTimeOut)
	IFZ time THEN msTimeOut = 500
	XuiSetValue (grid, #SetValue, msTimeOut, 0, 0, 0, 0, $msTimeOut)
	SELECT CASE TRUE
		CASE (v1 < zero)
					XuiCallback (grid, #OneLess, 0, 0, 0, 0, 0, 0)
					XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarV(), 0, 0, 0, $$TRUE)
					XgrSetGridTimer (grid, msTimeOut)
		CASE (v1 > upper)
					XuiCallback (grid, #OneMore, 0, 0, 0, 0, 0, 0)
					XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarV(), 0, 0, 0, $$TRUE)
					XgrSetGridTimer (grid, msTimeOut)
		CASE (v1 < lo)
					IF v2{1,24} THEN																	' Button 1
						XuiCallback (grid, #MuchLess, 0, 0, 0, 0, 0, 0)
						XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarV(), 0, 0, 0, $$TRUE)
						XgrSetGridTimer (grid, msTimeOut)
					ELSE
						XuiSetValue (grid, #SetValue, v0, 0, 0, 0, 0, 8)
						XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 9)
						focusGrid = grid
						GOSUB MouseDrag
					END IF
		CASE (v1 > hi)
					IF v2{1,24} THEN																	' Button 1
						XuiCallback (grid, #MuchMore, 0, 0, 0, 0, 0, 0)
						XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarV(), 0, 0, 0, $$TRUE)
						XgrSetGridTimer (grid, msTimeOut)
					ELSE
						XuiSetValue (grid, #SetValue, v0, 0, 0, 0, 0, 8)
						XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 9)
						focusGrid = grid
						GOSUB MouseDrag
					END IF
		CASE ELSE
					XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarV(), 0, 0, 0, $$TRUE)
					XuiSetValue (grid, #SetValue, v0, 0, 0, 0, 0, 8)
					XuiSetValue (grid, #SetValue, v1, 0, 0, 0, 0, 9)
					XuiSetValue (grid, #SetValue, v1 - (lo - zero), 0, 0, 0, 0, 12)		' minMouse
					XuiSetValue (grid, #SetValue, v1 + (upper - hi), 0, 0, 0, 0, 13)	' maxMouse
					focusGrid = grid
	END SELECT
END SUB
'
'
' *****  MouseDrag  *****
'
SUB MouseDrag
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	IFZ focusGrid THEN EXIT SUB
'
	IF (r1 = grid) THEN
		vv0 = v0 : vv1 = v1
	ELSE
		XgrConvertLocalToDisplay (r1, v0, v1, @d0, @d1)
		XgrConvertDisplayToLocal (grid, d0, d1, @vv0, @vv1)
	END IF
'
	XuiGetValues (grid, #GetValues, @zero, @lo, @hi, @upper, 0, 0)
	XuiGetValues (grid, #GetValues, @xOld, @yOld, 0, 0, 0, 8)
	XuiGetValues (grid, #GetValues, @minMouse, @maxMouse, 0, 0, 0, 12)
'
	IF (vv1 < minMouse) THEN vv1 = minMouse
	IF (vv1 > maxMouse) THEN vv1 = maxMouse
'
	XuiSetValue (grid, #SetValue, vv0, 0, 0, 0, 0, 8)
	XuiSetValue (grid, #SetValue, vv1, 0, 0, 0, 0, 9)
'
	IF (yOld = vv1) THEN EXIT SUB								' ignore x only motion
'
	olo = lo
	ohi = hi
	delta = vv1 - yOld
	minMove = zero - lo
	maxMove = upper - hi
	IF (delta < 0) THEN
		move = MAX (delta, minMove)
	ELSE
		move = MIN (delta, maxMove)
	END IF
'
	IFZ move THEN EXIT SUB
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	XgrGetGridColors (grid, @back, 0, @loColor, @hiColor, 0, 0, 0, 0)
	XgrDrawBorder (grid, $$BorderFlat, back, loColor, hiColor, x1+2, olo-2, x2-2, ohi+2)
	lo = lo + move
	hi = hi + move
	IF (lo < zero) THEN
		diff = zero - lo
		lo = lo + diff
	END IF
	IF (hi > upper) THEN
		diff = upper - hi
		hi = hi + diff
	END IF
	XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 1)
	XuiSetValue (grid, #SetValue, hi, 0, 0, 0, 0, 2)
	XgrDrawBorder (grid, $$BorderRaise, back, loColor, hiColor, x1+2, lo-2, x2-2, hi+2)
	XuiCallback (grid, #Change, 0, lo-zero, hi-zero, upper-zero, 0, 0)
END SUB
'
'
' *****  MouseUp  *****
'
SUB MouseUp
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2{$$ButtonNumber} = $$HelpButtonNumber) THEN EXIT SUB
	XuiMonitorMouse (grid, #MonitorMouse, grid, &XuiScrollBarV(), 0, 0, 0, $$FALSE)
	focusGrid = 0
	XuiSetValue (grid, #SetValue, 0, 0, 0, 0, 0, $msTimeOut)
	XgrSetGridTimer (grid, 0)
END SUB
'
'
' *****  Redraw  *****
'
SUB Redraw
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND redraw) THEN EXIT SUB
	XgrClearGrid (grid, -1)
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	XuiGetStyle (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	XgrGetGridColors (grid, @back, 0, @lo, @hi, 0, 0, 0, 0)
	XuiGetValues (grid, #GetValues, 0, @low, @high, 0, 0, 0)
	XgrDrawBorder (grid, $$BorderRidge, back, lo, hi, x1, y1, x2, y2)
	XgrFillBox (grid, back, x1, y1, x2, y1+11)
	XgrFillBox (grid, back, x1, y2-11, x2, y2)
	top = style AND 0x0002
	bottom = style AND 0x0001
	IF top THEN XgrFillTriangle (grid, -1, 0, $$TriangleUp, x1+2, y1+2, x2-2, y1+8)
	IF bottom THEN XgrFillTriangle (grid, -1, 0, $$TriangleDown, x1+2, y2-8, x2-2, y2-2)
	XgrDrawBorder (grid, $$BorderRaise, back, lo, hi, x1, y1, x2, y1+11)
	XgrDrawBorder (grid, $$BorderRaise, back, lo, hi, x1, y2-11, x2, y2)
	XgrDrawBorder (grid, $$BorderRaise, back, lo, hi, x1+2, low-2, x2-2, high+2)
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	XuiGetValues (grid, #GetValues, @lowest, @low, @high, @highest, 0, 4)
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	zero = 14
	upper = v3 - 15
	ComputeLimits (@lo, @hi, zero, upper, lowest, low, high, highest)
	XuiSetValues (grid, #SetValues, zero, lo, hi, upper, 0, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, v0, v1, v2, v3, 0, 0)
END SUB
'
'
' *****  GetPosition  *****
'
SUB GetPosition
	XuiGetValues (grid, #GetValues, @v0, @v1, @v2, @v3, 0, 0)
END SUB
'
'
' *****  SetPosition  *****
'
SUB SetPosition
	XuiGetValues (grid, #GetValues, @zero, @lo, @hi, @upper, 0, 0)
'
	lowest		= v0	' lowest line # in document
	low				= v1	' lowest line # displayed
	high			= v2	' highest line # displayed
	highest		= v3	' highest line # in document
'
	XuiSetValues (grid, #SetValues, v0, v1, v2, v3, 0, 4)
	XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
	XgrGetGridColors (grid, @back, 0, @loColor, @hiColor, 0, 0, 0, 0)
	XgrDrawBorder (grid, $$BorderFlat, back, loColor, hiColor, x1+2, lo-2, x2-2, hi+2)
	ComputeLimits (@lo, @hi, zero, upper, lowest, low, high, highest)
	XgrDrawBorder (grid, $$BorderRaise, back, loColor, hiColor, x1+2, lo-2, x2-2, hi+2)
	XuiSetValue (grid, #SetValue, lo, 0, 0, 0, 0, 1)
	XuiSetValue (grid, #SetValue, hi, 0, 0, 0, 0, 2)
END SUB
'
'
' *****  TimeOut  *****
'
SUB TimeOut
	XgrGetGridWindow (grid, @window)
	XgrGetMouseInfo (window, @grid, @v0, @v1, @v2, @v3)		' x, y, state, time
	IFZ v2{2,24} THEN EXIT SUB														' buttons 12 not down
	GOSUB MouseDown
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#GetSmallestSize]	= &XuiGetMaxMinSize()
	func[#Redraw]						= 0
	func[#RedrawGrid]				= 0
	func[#Resize]						= 0
'
	DIM sub[upperMessage]
	sub[#Create]						= SUBADDRESS (Create)
	sub[#CreateWindow]			= SUBADDRESS (CreateWindow)
	sub[#GetPosition]				= SUBADDRESS (GetPosition)
	sub[#MouseDown]					= SUBADDRESS (MouseDown)
	sub[#MouseDrag]					= SUBADDRESS (MouseDrag)
	sub[#MouseUp]						= SUBADDRESS (MouseUp)
	sub[#Redraw]						= SUBADDRESS (Redraw)
	sub[#RedrawGrid]				= SUBADDRESS (Redraw)
	sub[#Resize]						= SUBADDRESS (Resize)
	sub[#SetPosition]				= SUBADDRESS (SetPosition)
	sub[#TimeOut]						= SUBADDRESS (TimeOut)
'
	IF func[0] THEN PRINT "ScrollBarV() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "ScrollBarV() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiScrollBarV, @"XuiScrollBarV", &XuiScrollBarV(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 12
	designHeight = 80
'
	gridType = XuiScrollBarV
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",        12)
	XuiSetGridTypeValue (gridType, @"minHeight",       48)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRidge)
'	XuiSetGridTypeValue (gridType, @"style",            3)
	XuiSetGridTypeValue (gridType, @"can",             $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawNone)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ################################
' #####  XuiToggleButton ()  #####
' ################################
'
FUNCTION  XuiToggleButton (grid, message, v0, v1, v2, v3, r0, (r1, r1[], r1$))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiToggleButton
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiToggleButton) THEN RETURN
	GOSUB @sub[message]
	RETURN
'
'
' *****  Create  *****  v0123 = xywh : r0 = window : r1 = parent
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid (@grid, XuiToggleButton, @v0, @v1, @v2, @v3, r0, r1, &XuiToggleButton())
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0  = 0) THEN v0 = designX
	IF (v1  = 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiToggleButton")
END SUB
'
'
' *****  KeyDown  *****  #Selection on $$KeyEnter
'
SUB KeyDown
	XuiGetState (grid, #GetState, @state, @keyboard, 0, 0, 0, 0)
	IFZ (state AND keyboard) THEN EXIT SUB
	state = v2															' v2 = state
	key = state{8,24}												' virtual key
	IF (key = $$KeyEnter) THEN GOSUB Toggle
END SUB
'
'
' *****  MouseDown  *****
'
SUB MouseDown
	XuiGetState (grid, #GetState, @state, @keyboard, @mouse, @redraw, 0, 0)
	IFZ (state AND mouse) THEN EXIT SUB
	IF (v2 AND $$HelpButtonBit) THEN EXIT SUB
	GOSUB Toggle
END SUB
'
'
' *****  SetValue  *****
'
SUB SetValue
	IF r1 THEN EXIT SUB
	GOSUB SetValues
END SUB
'
'
' *****  SetValues  *****
'
SUB SetValues
	XuiGetValue (grid, #GetValue, @value0, 0, 0, 0, 0, 0)
	IF (v0 != value0) THEN GOSUB Toggle
END SUB
'
'
' *****  Toggle  *****
'
SUB Toggle
	XuiGetValue (grid, #GetValue, @state, 0, 0, 0, 0, 0)
	state = NOT state
	XuiSetValue (grid, #SetValue, state, 0, 0, 0, 0, 0)
	XuiGetBorder (grid, #GetBorder, @border, @borderUp, @borderDown, 0, 0, 0)
	IF state THEN border = borderDown ELSE border = borderUp
	XuiSetBorder (grid, #SetBorder, border, -1, -1, -1, 0, 0)
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	XuiCallback (grid, #Selection, state, 0, v2, v3, 0, grid)
END SUB
'
'
' *****  Initialize  ****
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#SetValue]					= 0
	func[#SetValues]				= 0
'
	DIM sub[upperMessage]
	sub[#Create]						= SUBADDRESS (Create)
	sub[#CreateWindow]			= SUBADDRESS (CreateWindow)
	sub[#KeyDown]						= SUBADDRESS (KeyDown)
	sub[#MouseDown]					= SUBADDRESS (MouseDown)
	sub[#SetValue]					= SUBADDRESS (SetValue)
	sub[#SetValues]					= SUBADDRESS (SetValues)
'
	IF func[0] THEN PRINT "XuiToggleButton() : Initialize : error ::: (undefined message)"
	IF sub[0] THEN PRINT "XuiToggleButton() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@XuiToggleButton, @"XuiToggleButton", &XuiToggleButton(), @func[], @sub[])
'
	designX = 0
	designY = 0
	designWidth = 80
	designHeight = 20
'
	gridType = XuiToggleButton
	XuiSetGridTypeValue (gridType, @"x",               designX)
	XuiSetGridTypeValue (gridType, @"y",               designY)
	XuiSetGridTypeValue (gridType, @"width",           designWidth)
	XuiSetGridTypeValue (gridType, @"height",          designHeight)
	XuiSetGridTypeValue (gridType, @"minWidth",         4)
	XuiSetGridTypeValue (gridType, @"minHeight",        4)
	XuiSetGridTypeValue (gridType, @"align",           $$AlignMiddleCenter)
	XuiSetGridTypeValue (gridType, @"border",          $$BorderRaise2)
	XuiSetGridTypeValue (gridType, @"borderUp",        $$BorderRaise2)
	XuiSetGridTypeValue (gridType, @"borderDown",      $$BorderLower2)
	XuiSetGridTypeValue (gridType, @"texture",         $$TextureLower1)
	XuiSetGridTypeValue (gridType, @"can",             $$Focus OR $$Respond OR $$Callback)
	XuiSetGridTypeValue (gridType, @"redrawFlags",     $$RedrawDefault)
	IFZ message THEN RETURN
END SUB
END FUNCTION
END PROGRAM

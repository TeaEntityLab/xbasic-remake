'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"ADrawing"
VERSION	"0.1000"
'
'This demo program provides examples on using various graphic drawing functions
'and altering various graphic settings such as color, line width, line style,
'and arrow direction. Various functions used in this program include:
'	XgrDrawArc()
'	XgrDrawBorder()
'	XgrDrawBox()
'	XgrDrawCircle()
'	XgrDrawLine()
'	XgrDrawPoint()
'	XgrDrawText()
'	XgrDrawTextFill()
'	XgrFillBox()
'	XgrFillTriangle()
'
'This program is in the public domain.
'David SZAFRANSKI
'June 1999
'digital_paris@csi.com
'
' You can stop the PDE from inserting the following PROLOG comment lines
' by removing them from the gprolog.xxx file in your \xb\xxx directory.
'
' Programs contain:  1: PROLOG          - no executable code - see below
'                    2: Entry function  - start execution at 1st declared func
' * = optional       3: Other functions - everything else - all other functions
'
' The PROLOG contains (in this order):
' * 1. Program name statement             PROGRAM "progname"
' * 2. Version number statement           VERSION "0.0000"
' * 3. Import library statements          IMPORT  "libName"
' * 4. Composite type definitions         TYPE <typename> ... END TYPE
'   5. Internal function declarations     DECLARE/INTERNAL FUNCTION Func (args)
' * 6. External function declarations     EXTERNAL FUNCTION FuncName (args)
' * 7. Shared constant definitions        $$ConstantName = literal or constant
' * 8. Shared variable declarations       SHARED  variable
'
' ******  Comment libraries in/out as needed  *****
'
	IMPORT	"xma"   ' Math library     : SIN/ASIN/SINH/ASINH/LOG/EXP/SQRT...
'	IMPORT	"xcm"   ' Complex library  : complex number library  (trig, etc)
	IMPORT	"xst"   ' Standard library : required by most programs
	IMPORT	"xgr"   ' GraphicsDesigner : required by GuiDesigner programs
	IMPORT	"xui"   ' GuiDesigner      : required by GuiDesigner programs
'
INTERNAL FUNCTION  Entry         ()
INTERNAL FUNCTION  InitGui       ()
INTERNAL FUNCTION  InitProgram   ()
INTERNAL FUNCTION  CreateWindows ()
INTERNAL FUNCTION  InitWindows   ()
INTERNAL FUNCTION  ADrawing      (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  ADrawingCode  (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  RandomN       (@RandomNReturn#)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	SHARED  terminateProgram
	STATIC	entry
'
	IF entry THEN RETURN					' enter once
	entry =  $$TRUE								' enter occured
'
	InitGui ()										' initialize messages
	InitProgram ()								' initialize this program
	CreateWindows ()							' create main window and others
	InitWindows ()								' initialize windows and grids
'
	IF LIBRARY(0) THEN RETURN			' main program executes message loop
'
	DO														' the message loop
		XgrProcessMessages (1)			' process one message
	LOOP UNTIL terminateProgram		' and repeat until program is terminated
END FUNCTION
'
'
' ########################
' #####  InitGui ()  #####
' ########################
'
' InitGui() initializes cursor, icon, message, and display variables.
' Programs can reference these variables, but must never change them.
'
FUNCTION  InitGui ()
'
' need to set program name so grid properties
' can be set from the grid property database.
'
	program$ = PROGRAM$(0)
	XstSetProgramName (@program$)
'
' ***************************************
' *****  Register Standard Cursors  *****
' ***************************************
'
	XgrRegisterCursor (@"default",      @#cursorDefault)
	XgrRegisterCursor (@"arrow",        @#cursorArrow)
	XgrRegisterCursor (@"n",            @#cursorN)
	XgrRegisterCursor (@"s",            @#cursorS)
	XgrRegisterCursor (@"e",            @#cursorE)
	XgrRegisterCursor (@"w",            @#cursorW)
	XgrRegisterCursor (@"ns",           @#cursorArrowsNS)
	XgrRegisterCursor (@"ns",           @#cursorArrowsSN)
	XgrRegisterCursor (@"ew",           @#cursorArrowsEW)
	XgrRegisterCursor (@"ew",           @#cursorArrowsWE)
	XgrRegisterCursor (@"nwse",         @#cursorArrowsNWSE)
	XgrRegisterCursor (@"nesw",         @#cursorArrowsNESW)
	XgrRegisterCursor (@"all",          @#cursorArrowsAll)
	XgrRegisterCursor (@"plus",         @#cursorPlus)
	XgrRegisterCursor (@"wait",         @#cursorWait)
	XgrRegisterCursor (@"insert",       @#cursorInsert)
	XgrRegisterCursor (@"crosshair",    @#cursorCrosshair)
	XgrRegisterCursor (@"hourglass",    @#cursorHourglass)
'
	#defaultCursor = #cursorDefault
'
'
' ********************************************
' *****  Register Standard Window Icons  *****
' ********************************************
'
'	XgrRegisterIcon (@"hand",					@#iconHand)
'	XgrRegisterIcon (@"asterisk",			@#iconAsterisk)
'	XgrRegisterIcon (@"question",			@#iconQuestion)
'	XgrRegisterIcon (@"exclamation",	@#iconExclamation)
'	XgrRegisterIcon (@"application",	@#iconApplication)
'
'	XgrRegisterIcon (@"hand",					@#iconStop)						' alias
'	XgrRegisterIcon (@"asterisk",			@#iconInformation)		' alias
'	XgrRegisterIcon (@"application",  @#iconBlank)					' alias
'
	XgrRegisterIcon (@"window",				@#iconWindow)					' custom
'
'
' ******************************
' *****  Register Messages *****  Create message numbers for message names
' ******************************
'
	XgrRegisterMessage (@"Blowback",										@#Blowback)
	XgrRegisterMessage (@"Callback",										@#Callback)
	XgrRegisterMessage (@"Cancel",											@#Cancel)
	XgrRegisterMessage (@"Change",											@#Change)
	XgrRegisterMessage (@"CloseWindow",									@#CloseWindow)
	XgrRegisterMessage (@"ContextChange",								@#ContextChange)
	XgrRegisterMessage (@"Create",											@#Create)
	XgrRegisterMessage (@"CreateValueArray",						@#CreateValueArray)
	XgrRegisterMessage (@"CreateWindow",								@#CreateWindow)
	XgrRegisterMessage (@"CursorH",											@#CursorH)
	XgrRegisterMessage (@"CursorV",											@#CursorV)
	XgrRegisterMessage (@"Deselected",							    @#Deselected)
	XgrRegisterMessage (@"Destroy",											@#Destroy)
	XgrRegisterMessage (@"Destroyed",										@#Destroyed)
	XgrRegisterMessage (@"DestroyWindow",								@#DestroyWindow)
	XgrRegisterMessage (@"Disable",											@#Disable)
	XgrRegisterMessage (@"Disabled",										@#Disabled)
	XgrRegisterMessage (@"Displayed",										@#Displayed)
	XgrRegisterMessage (@"DisplayWindow",								@#DisplayWindow)
	XgrRegisterMessage (@"Enable",											@#Enable)
	XgrRegisterMessage (@"Enabled",											@#Enabled)
	XgrRegisterMessage (@"Enter",												@#Enter)
	XgrRegisterMessage (@"ExitMessageLoop",							@#ExitMessageLoop)
	XgrRegisterMessage (@"Find",												@#Find)
	XgrRegisterMessage (@"FindForward",									@#FindForward)
	XgrRegisterMessage (@"FindReverse",									@#FindReverse)
	XgrRegisterMessage (@"Forward",											@#Forward)
	XgrRegisterMessage (@"GetAlign",										@#GetAlign)
	XgrRegisterMessage (@"GetBorder",										@#GetBorder)
	XgrRegisterMessage (@"GetBorderOffset",							@#GetBorderOffset)
	XgrRegisterMessage (@"GetCallback",									@#GetCallback)
	XgrRegisterMessage (@"GetCallbackArgs",							@#GetCallbackArgs)
	XgrRegisterMessage (@"GetCan",											@#GetCan)
	XgrRegisterMessage (@"GetCharacterMapArray",				@#GetCharacterMapArray)
	XgrRegisterMessage (@"GetCharacterMapEntry",				@#GetCharacterMapEntry)
	XgrRegisterMessage (@"GetClipGrid",									@#GetClipGrid)
	XgrRegisterMessage (@"GetColor",										@#GetColor)
	XgrRegisterMessage (@"GetColorExtra",								@#GetColorExtra)
	XgrRegisterMessage (@"GetCursor",										@#GetCursor)
	XgrRegisterMessage (@"GetCursorXY",									@#GetCursorXY)
	XgrRegisterMessage (@"GetDisplay",									@#GetDisplay)
	XgrRegisterMessage (@"GetEnclosedGrids",						@#GetEnclosedGrids)
	XgrRegisterMessage (@"GetEnclosingGrid",						@#GetEnclosingGrid)
	XgrRegisterMessage (@"GetFocusColor",								@#GetFocusColor)
	XgrRegisterMessage (@"GetFocusColorExtra",					@#GetFocusColorExtra)
	XgrRegisterMessage (@"GetFont",											@#GetFont)
	XgrRegisterMessage (@"GetFontMetrics",							@#GetFontMetrics)
	XgrRegisterMessage (@"GetFontNumber",								@#GetFontNumber)
	XgrRegisterMessage (@"GetGridFunction",							@#GetGridFunction)
	XgrRegisterMessage (@"GetGridFunctionName",					@#GetGridFunctionName)
	XgrRegisterMessage (@"GetGridName",									@#GetGridName)
	XgrRegisterMessage (@"GetGridNumber",								@#GetGridNumber)
	XgrRegisterMessage (@"GetGridProperties",						@#GetGridProperties)
	XgrRegisterMessage (@"GetGridType",									@#GetGridType)
	XgrRegisterMessage (@"GetGridTypeName",							@#GetGridTypeName)
	XgrRegisterMessage (@"GetGroup",										@#GetGroup)
	XgrRegisterMessage (@"GetHelp",											@#GetHelp)
	XgrRegisterMessage (@"GetHelpFile",									@#GetHelpFile)
	XgrRegisterMessage (@"GetHelpString",								@#GetHelpString)
	XgrRegisterMessage (@"GetHelpStrings",							@#GetHelpStrings)
	XgrRegisterMessage (@"GetHintString",								@#GetHintString)
	XgrRegisterMessage (@"GetImage",										@#GetImage)
	XgrRegisterMessage (@"GetImageCoords",							@#GetImageCoords)
	XgrRegisterMessage (@"GetIndent",										@#GetIndent)
	XgrRegisterMessage (@"GetInfo",											@#GetInfo)
	XgrRegisterMessage (@"GetJustify",									@#GetJustify)
	XgrRegisterMessage (@"GetKeyboardFocus",						@#GetKeyboardFocus)
	XgrRegisterMessage (@"GetKeyboardFocusGrid",				@#GetKeyboardFocusGrid)
	XgrRegisterMessage (@"GetKidArray",									@#GetKidArray)
	XgrRegisterMessage (@"GetKidNumber",								@#GetKidNumber)
	XgrRegisterMessage (@"GetKids",											@#GetKids)
	XgrRegisterMessage (@"GetKind",											@#GetKind)
	XgrRegisterMessage (@"GetMaxMinSize",								@#GetMaxMinSize)
	XgrRegisterMessage (@"GetMenuEntryArray",						@#GetMenuEntryArray)
	XgrRegisterMessage (@"GetMessageFunc",							@#GetMessageFunc)
	XgrRegisterMessage (@"GetMessageFuncArray",					@#GetMessageFuncArray)
	XgrRegisterMessage (@"GetMessageSub",								@#GetMessageSub)
	XgrRegisterMessage (@"GetMessageSubArray",					@#GetMessageSubArray)
	XgrRegisterMessage (@"GetModalInfo",								@#GetModalInfo)
	XgrRegisterMessage (@"GetModalWindow",							@#GetModalWindow)
	XgrRegisterMessage (@"GetParent",										@#GetParent)
	XgrRegisterMessage (@"GetPosition",									@#GetPosition)
	XgrRegisterMessage (@"GetProtoInfo",								@#GetProtoInfo)
	XgrRegisterMessage (@"GetRedrawFlags",							@#GetRedrawFlags)
	XgrRegisterMessage (@"GetSize",											@#GetSize)
	XgrRegisterMessage (@"GetSmallestSize",							@#GetSmallestSize)
	XgrRegisterMessage (@"GetState",										@#GetState)
	XgrRegisterMessage (@"GetStyle",										@#GetStyle)
	XgrRegisterMessage (@"GetTabArray",									@#GetTabArray)
	XgrRegisterMessage (@"GetTabWidth",									@#GetTabWidth)
	XgrRegisterMessage (@"GetTextArray",								@#GetTextArray)
	XgrRegisterMessage (@"GetTextArrayBounds",					@#GetTextArrayBounds)
	XgrRegisterMessage (@"GetTextArrayLine",						@#GetTextArrayLine)
	XgrRegisterMessage (@"GetTextArrayLines",						@#GetTextArrayLines)
	XgrRegisterMessage (@"GetTextCursor",								@#GetTextCursor)
	XgrRegisterMessage (@"GetTextFilename",							@#GetTextFilename)
	XgrRegisterMessage (@"GetTextFlag",									@#GetTextFlag) 'Add by technicorn *cw*
	XgrRegisterMessage (@"GetTextPosition",							@#GetTextPosition)
	XgrRegisterMessage (@"GetTextSelection",						@#GetTextSelection)
	XgrRegisterMessage (@"GetTextSpacing",							@#GetTextSpacing)
	XgrRegisterMessage (@"GetTextString",								@#GetTextString)
	XgrRegisterMessage (@"GetTextStrings",							@#GetTextStrings)
	XgrRegisterMessage (@"GetTexture",									@#GetTexture)
	XgrRegisterMessage (@"GetTimer",										@#GetTimer)
	XgrRegisterMessage (@"GetValue",										@#GetValue)
	XgrRegisterMessage (@"GetValueArray",								@#GetValueArray)
	XgrRegisterMessage (@"GetValues",										@#GetValues)
	XgrRegisterMessage (@"GetWindow",										@#GetWindow)
	XgrRegisterMessage (@"GetWindowFunction",						@#GetWindowFunction)
	XgrRegisterMessage (@"GetWindowGrid",								@#GetWindowGrid)
	XgrRegisterMessage (@"GetWindowIcon",								@#GetWindowIcon)
	XgrRegisterMessage (@"GetWindowSize",								@#GetWindowSize)
	XgrRegisterMessage (@"GetWindowTitle",							@#GetWindowTitle)
	XgrRegisterMessage (@"GotKeyboardFocus",						@#GotKeyboardFocus)
	XgrRegisterMessage (@"GrabArray",										@#GrabArray)
	XgrRegisterMessage (@"GrabTextArray",								@#GrabTextArray)
	XgrRegisterMessage (@"GrabTextString",							@#GrabTextString)
	XgrRegisterMessage (@"GrabValueArray",							@#GrabValueArray)
	XgrRegisterMessage (@"HalfPageDown",								@#HalfPageDown)              '*cw*
	XgrRegisterMessage (@"HalfPageUp",									@#HalfPageUp)                '*cw*
	XgrRegisterMessage (@"Help",												@#Help)
	XgrRegisterMessage (@"Hidden",											@#Hidden)
	XgrRegisterMessage (@"HideTextCursor",							@#HideTextCursor)
	XgrRegisterMessage (@"HideWindow",									@#HideWindow)
	XgrRegisterMessage (@"Initialize",									@#Initialize)
	XgrRegisterMessage (@"Initialized",									@#Initialized)
	XgrRegisterMessage (@"Inline",											@#Inline)
	XgrRegisterMessage (@"InquireText",									@#InquireText)
	XgrRegisterMessage (@"KeyboardFocusBackward",				@#KeyboardFocusBackward)
	XgrRegisterMessage (@"KeyboardFocusForward",				@#KeyboardFocusForward)
	XgrRegisterMessage (@"KeyDown",											@#KeyDown)
	XgrRegisterMessage (@"KeyUp",												@#KeyUp)
	XgrRegisterMessage (@"LostKeyboardFocus",						@#LostKeyboardFocus)
	XgrRegisterMessage (@"LostTextSelection",						@#LostTextSelection)
	XgrRegisterMessage (@"Maximized",										@#Maximized)
	XgrRegisterMessage (@"MaximizeWindow",							@#MaximizeWindow)
	XgrRegisterMessage (@"Maximum",											@#Maximum)
	XgrRegisterMessage (@"Minimized",										@#Minimized)
	XgrRegisterMessage (@"MinimizeWindow",							@#MinimizeWindow)
	XgrRegisterMessage (@"Minimum",											@#Minimum)
	XgrRegisterMessage (@"MonitorContext",							@#MonitorContext)
	XgrRegisterMessage (@"MonitorHelp",									@#MonitorHelp)
	XgrRegisterMessage (@"MonitorKeyboard",							@#MonitorKeyboard)
	XgrRegisterMessage (@"MonitorMouse",								@#MonitorMouse)
	XgrRegisterMessage (@"MouseDown",										@#MouseDown)
	XgrRegisterMessage (@"MouseDrag",										@#MouseDrag)
	XgrRegisterMessage (@"MouseEnter",									@#MouseEnter)
	XgrRegisterMessage (@"MouseExit",										@#MouseExit)
	XgrRegisterMessage (@"MouseMove",										@#MouseMove)
	XgrRegisterMessage (@"MouseUp",											@#MouseUp)
	XgrRegisterMessage (@"MouseWheel",									@#MouseWheel)
	XgrRegisterMessage (@"MuchLess",										@#MuchLess)
	XgrRegisterMessage (@"MuchMore",										@#MuchMore)
	XgrRegisterMessage (@"Notify",											@#Notify)
	XgrRegisterMessage (@"OneLess",											@#OneLess)
	XgrRegisterMessage (@"OneMore",											@#OneMore)
	XgrRegisterMessage (@"PageDown",										@#PageDown)              '*cw*
	XgrRegisterMessage (@"PageUp",											@#PageUp)                '*cw*
	XgrRegisterMessage (@"PokeArray",										@#PokeArray)
	XgrRegisterMessage (@"PokeTextArray",								@#PokeTextArray)
	XgrRegisterMessage (@"PokeTextString",							@#PokeTextString)
	XgrRegisterMessage (@"PokeValueArray",							@#PokeValueArray)
	XgrRegisterMessage (@"Print",												@#Print)
	XgrRegisterMessage (@"Redraw",											@#Redraw)
	XgrRegisterMessage (@"RedrawGrid",									@#RedrawGrid)
	XgrRegisterMessage (@"RedrawLines",									@#RedrawLines)
	XgrRegisterMessage (@"Redrawn",											@#Redrawn)
	XgrRegisterMessage (@"RedrawText",									@#RedrawText)
	XgrRegisterMessage (@"RedrawWindow",								@#RedrawWindow)
	XgrRegisterMessage (@"Replace",											@#Replace)
	XgrRegisterMessage (@"ReplaceForward",							@#ReplaceForward)
	XgrRegisterMessage (@"ReplaceReverse",							@#ReplaceReverse)
	XgrRegisterMessage (@"Reset",												@#Reset)
	XgrRegisterMessage (@"Resize",											@#Resize)
	XgrRegisterMessage (@"Resized",											@#Resized)
	XgrRegisterMessage (@"ResizeNot",										@#ResizeNot)
	XgrRegisterMessage (@"ResizeWindow",								@#ResizeWindow)
	XgrRegisterMessage (@"ResizeWindowToGrid",					@#ResizeWindowToGrid)
	XgrRegisterMessage (@"RestoreWindow",								@#RestoreWindow)       '*cw* 150720+
	XgrRegisterMessage (@"Reverse",											@#Reverse)
	XgrRegisterMessage (@"ScrollH",											@#ScrollH)
	XgrRegisterMessage (@"ScrollV",											@#ScrollV)
	XgrRegisterMessage (@"Select",											@#Select)
	XgrRegisterMessage (@"Selected",										@#Selected)
	XgrRegisterMessage (@"Selection",										@#Selection)
	XgrRegisterMessage (@"SelectWindow",								@#SelectWindow)
	XgrRegisterMessage (@"SetAlign",										@#SetAlign)
	XgrRegisterMessage (@"SetBorder",										@#SetBorder)
	XgrRegisterMessage (@"SetBorderOffset",							@#SetBorderOffset)
	XgrRegisterMessage (@"SetCallback",									@#SetCallback)
	XgrRegisterMessage (@"SetCan",											@#SetCan)
	XgrRegisterMessage (@"SetCharacterMapArray",				@#SetCharacterMapArray)
	XgrRegisterMessage (@"SetCharacterMapEntry",				@#SetCharacterMapEntry)
	XgrRegisterMessage (@"SetClipGrid",									@#SetClipGrid)
	XgrRegisterMessage (@"SetColor",										@#SetColor)
	XgrRegisterMessage (@"SetColorAll",									@#SetColorAll)
	XgrRegisterMessage (@"SetColorExtra",								@#SetColorExtra)
	XgrRegisterMessage (@"SetColorExtraAll",						@#SetColorExtraAll)
	XgrRegisterMessage (@"SetCursor",										@#SetCursor)
	XgrRegisterMessage (@"SetCursorXY",									@#SetCursorXY)
	XgrRegisterMessage (@"SetDisplay",									@#SetDisplay)
	XgrRegisterMessage (@"SetFocusColor",								@#SetFocusColor)
	XgrRegisterMessage (@"SetFocusColorExtra",					@#SetFocusColorExtra)
	XgrRegisterMessage (@"SetFont",											@#SetFont)
	XgrRegisterMessage (@"SetFontNumber",								@#SetFontNumber)
	XgrRegisterMessage (@"SetGridFunction",							@#SetGridFunction)
	XgrRegisterMessage (@"SetGridFunctionName",					@#SetGridFunctionName)
	XgrRegisterMessage (@"SetGridName",									@#SetGridName)
	XgrRegisterMessage (@"SetGridProperties",						@#SetGridProperties)
	XgrRegisterMessage (@"SetGridType",									@#SetGridType)
	XgrRegisterMessage (@"SetGridTypeName",							@#SetGridTypeName)
	XgrRegisterMessage (@"SetGroup",										@#SetGroup)
	XgrRegisterMessage (@"SetHelp",											@#SetHelp)
	XgrRegisterMessage (@"SetHelpFile",									@#SetHelpFile)
	XgrRegisterMessage (@"SetHelpString",								@#SetHelpString)
	XgrRegisterMessage (@"SetHelpStrings",							@#SetHelpStrings)
	XgrRegisterMessage (@"SetHintString",								@#SetHintString)
	XgrRegisterMessage (@"SetImage",										@#SetImage)
	XgrRegisterMessage (@"SetImageCoords",							@#SetImageCoords)
	XgrRegisterMessage (@"SetIndent",										@#SetIndent)
	XgrRegisterMessage (@"SetInfo",											@#SetInfo)
	XgrRegisterMessage (@"SetJustify",									@#SetJustify)
	XgrRegisterMessage (@"SetKeyboardFocus",						@#SetKeyboardFocus)
	XgrRegisterMessage (@"SetKeyboardFocusGrid",				@#SetKeyboardFocusGrid)
	XgrRegisterMessage (@"SetKidArray",									@#SetKidArray)
	XgrRegisterMessage (@"SetMaxMinSize",								@#SetMaxMinSize)
	XgrRegisterMessage (@"SetMenuEntryArray",						@#SetMenuEntryArray)
	XgrRegisterMessage (@"SetMessageFunc",							@#SetMessageFunc)
	XgrRegisterMessage (@"SetMessageFuncArray",					@#SetMessageFuncArray)
	XgrRegisterMessage (@"SetMessageSub",								@#SetMessageSub)
	XgrRegisterMessage (@"SetMessageSubArray",					@#SetMessageSubArray)
	XgrRegisterMessage (@"SetModalWindow",							@#SetModalWindow)
	XgrRegisterMessage (@"SetParent",										@#SetParent)
	XgrRegisterMessage (@"SetPosition",									@#SetPosition)
	XgrRegisterMessage (@"SetRedrawFlags",							@#SetRedrawFlags)
	XgrRegisterMessage (@"SetSize",											@#SetSize)
	XgrRegisterMessage (@"SetState",										@#SetState)
	XgrRegisterMessage (@"SetStyle",										@#SetStyle)
	XgrRegisterMessage (@"SetTabArray",									@#SetTabArray)
	XgrRegisterMessage (@"SetTabWidth",									@#SetTabWidth)
	XgrRegisterMessage (@"SetTextArray",								@#SetTextArray)
	XgrRegisterMessage (@"SetTextArrayLine",						@#SetTextArrayLine)
	XgrRegisterMessage (@"SetTextArrayLines",						@#SetTextArrayLines)
	XgrRegisterMessage (@"SetTextCursor",								@#SetTextCursor)
	XgrRegisterMessage (@"SetTextFilename",							@#SetTextFilename)
	XgrRegisterMessage (@"SetTextFlag",									@#SetTextFlag) 'Add by technicorn *cw*
	XgrRegisterMessage (@"SetTextSelection",						@#SetTextSelection)
	XgrRegisterMessage (@"SetTextSpacing",							@#SetTextSpacing)
	XgrRegisterMessage (@"SetTextString",								@#SetTextString)
	XgrRegisterMessage (@"SetTextStrings",							@#SetTextStrings)
	XgrRegisterMessage (@"SetTexture",									@#SetTexture)
	XgrRegisterMessage (@"SetTimer",										@#SetTimer)
	XgrRegisterMessage (@"SetValue",										@#SetValue)
	XgrRegisterMessage (@"SetValueArray",								@#SetValueArray)
	XgrRegisterMessage (@"SetValues",										@#SetValues)
	XgrRegisterMessage (@"SetWindowFunction",						@#SetWindowFunction)
	XgrRegisterMessage (@"SetWindowIcon",								@#SetWindowIcon)
	XgrRegisterMessage (@"SetWindowTitle",							@#SetWindowTitle)
	XgrRegisterMessage (@"ShowTextCursor",							@#ShowTextCursor)
	XgrRegisterMessage (@"ShowWindow",									@#ShowWindow)
	XgrRegisterMessage (@"SomeLess",										@#SomeLess)
	XgrRegisterMessage (@"SomeMore",										@#SomeMore)
	XgrRegisterMessage (@"StartTimer",									@#StartTimer)
	XgrRegisterMessage (@"SystemMessage",								@#SystemMessage)
	XgrRegisterMessage (@"TextDelete",									@#TextDelete)
	XgrRegisterMessage (@"TextEvent",										@#TextEvent)
	XgrRegisterMessage (@"TextInsert",									@#TextInsert)
	XgrRegisterMessage (@"TextModified",								@#TextModified)
	XgrRegisterMessage (@"TextReplace",									@#TextReplace)
	XgrRegisterMessage (@"TimeOut",											@#TimeOut)
	XgrRegisterMessage (@"Update",											@#Update)
	XgrRegisterMessage (@"WindowClose",									@#WindowClose)
	XgrRegisterMessage (@"WindowCreate",								@#WindowCreate)
	XgrRegisterMessage (@"WindowDeselected",						@#WindowDeselected)
	XgrRegisterMessage (@"WindowDestroy",								@#WindowDestroy)
	XgrRegisterMessage (@"WindowDestroyed",							@#WindowDestroyed)
	XgrRegisterMessage (@"WindowDisplay",								@#WindowDisplay)
	XgrRegisterMessage (@"WindowDisplayed",							@#WindowDisplayed)
	XgrRegisterMessage (@"WindowGetDisplay",						@#WindowGetDisplay)
	XgrRegisterMessage (@"WindowGetFunction",						@#WindowGetFunction)
	XgrRegisterMessage (@"WindowGetIcon",								@#WindowGetIcon)
	XgrRegisterMessage (@"WindowGetKeyboardFocusGrid",	@#WindowGetKeyboardFocusGrid)
	XgrRegisterMessage (@"WindowGetSelectedWindow",			@#WindowGetSelectedWindow)
	XgrRegisterMessage (@"WindowGetSize",								@#WindowGetSize)
	XgrRegisterMessage (@"WindowGetTitle",							@#WindowGetTitle)
	XgrRegisterMessage (@"WindowHelp",									@#WindowHelp)
	XgrRegisterMessage (@"WindowHidden",								@#WindowHidden)
	XgrRegisterMessage (@"WindowHide",									@#WindowHide)
	XgrRegisterMessage (@"WindowKeyDown",								@#WindowKeyDown)
	XgrRegisterMessage (@"WindowKeyUp",									@#WindowKeyUp)
	XgrRegisterMessage (@"WindowMaximize",							@#WindowMaximize)
	XgrRegisterMessage (@"WindowMaximized",							@#WindowMaximized)
	XgrRegisterMessage (@"WindowMinimize",							@#WindowMinimize)
	XgrRegisterMessage (@"WindowMinimized",							@#WindowMinimized)
	XgrRegisterMessage (@"WindowMonitorContext",				@#WindowMonitorContext)
	XgrRegisterMessage (@"WindowMonitorHelp",						@#WindowMonitorHelp)
	XgrRegisterMessage (@"WindowMonitorKeyboard",				@#WindowMonitorKeyboard)
	XgrRegisterMessage (@"WindowMonitorMouse",					@#WindowMonitorMouse)
	XgrRegisterMessage (@"WindowMouseDown",							@#WindowMouseDown)
	XgrRegisterMessage (@"WindowMouseDrag",							@#WindowMouseDrag)
	XgrRegisterMessage (@"WindowMouseEnter",						@#WindowMouseEnter)
	XgrRegisterMessage (@"WindowMouseExit",							@#WindowMouseExit)
	XgrRegisterMessage (@"WindowMouseMove",							@#WindowMouseMove)
	XgrRegisterMessage (@"WindowMouseUp",								@#WindowMouseUp)
	XgrRegisterMessage (@"WindowMouseWheel",						@#WindowMouseWheel)
	XgrRegisterMessage (@"WindowRedraw",								@#WindowRedraw)
	XgrRegisterMessage (@"WindowRegister",							@#WindowRegister)
	XgrRegisterMessage (@"WindowResize",								@#WindowResize)
	XgrRegisterMessage (@"WindowResized",								@#WindowResized)
	XgrRegisterMessage (@"WindowResizeToGrid",					@#WindowResizeToGrid)
	XgrRegisterMessage (@"WindowRestore",								@#WindowRestore)       '*cw* 150720+
	XgrRegisterMessage (@"WindowSelect",								@#WindowSelect)
	XgrRegisterMessage (@"WindowSelected",							@#WindowSelected)
	XgrRegisterMessage (@"WindowSetFunction",						@#WindowSetFunction)
	XgrRegisterMessage (@"WindowSetIcon",								@#WindowSetIcon)
	XgrRegisterMessage (@"WindowSetKeyboardFocusGrid",	@#WindowSetKeyboardFocusGrid)
	XgrRegisterMessage (@"WindowSetTitle",							@#WindowSetTitle)
	XgrRegisterMessage (@"WindowShow",									@#WindowShow)
	XgrRegisterMessage (@"WindowSystemMessage",					@#WindowSystemMessage)
	XgrRegisterMessage (@"LastMessage",									@#LastMessage)
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
END FUNCTION
'
'
' ############################
' #####  InitProgram ()  #####
' ############################
'
' Add code to this function to initialize anything your program needs
' to initialize before CreateWindows() creates your programs windows.
' For initialization after CreateWindows(), add code to InitWindows().
'
' Do not delete this function, leave it empty if not needed.
'
FUNCTION  InitProgram ()

END FUNCTION
'
'
' ##############################
' #####  CreateWindows ()  #####
' ##############################
'
' GuiDesigner puts code in CreateWindows() to create, initialize, display
' every window you design graphically.  Don't modify this function unless
' absolutely necessary - GuiDesigner needs to read and update it at times.
'
' CreateWindows() usually should not be executed when compiled as library.
' Start CreateWindows() with "IF LIBRARY(0) THEN RETURN" to assure this.
'
FUNCTION  CreateWindows ()
'
	IF LIBRARY(0) THEN RETURN
'
	ADrawing       (@ADrawing, #CreateWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( ADrawing, #SetCallback, ADrawing, &ADrawingCode(), -1, -1, -1, 0)
	XuiSendMessage ( ADrawing, #Initialize, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( ADrawing, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( ADrawing, #SetGridProperties, -1, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ############################
' #####  InitWindows ()  #####
' ############################
'
' Add code to this function to initialize anything your program needs
' to initialize after CreateWindows() creates your programs windows.
' For initialization before CreateWindows(), add code to InitProgram().
'
' Do not delete this function, leave it empty if not needed.
'
FUNCTION  InitWindows ()
'
'XgrSetCEO (&ADrawingCode()) 'Send all mouse event messages to program code function for processing

'
END FUNCTION
'
'
'	#########################
'	#####  ADrawing ()  #####
'	#########################
'
'	"Anatomy of Grid Functions" in the GuiDesigner Programmer Guide
'	describes the operation and modification of grid functions in detail.
'
'	WindowFromFunction and/or WindowToFunction may not work, or may not generate the desired results if you:
'		* Modify the kid constant definition improperly.
'		* Modify the code in the Create subroutine improperly.
'		* Imbed blank or comment lines in the Create subroutine.
'		* Remove the GOSUB Resize line in the Create subroutine (comment out is okay).
'		* Imbed special purpose code in the Create subroutine before the GOSUB Resize line.
'		* Delete any of the four lines that assign values to designX, designY, designWidth, designHeight.
'
' Note: Make sure that there are not any blank lines in this function or
'				the WindowFromFunction may not work properly
'	If any changes are made using the toolkit, some items may need to be replaced:
' Under GOSUB Resize the following line must be present:
' XuiSendMessage ( g, #SetMessageFunc, #RedrawGrid, &ADrawingCode(), 0, 0, 0, 0)
' Under XuiRange create section the following line must be present:
'	XuiSendMessage ( g, #SetValues, 1, 1, 1, 10, 0, 0)
'
FUNCTION  ADrawing (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  ADrawing
'
	$ADrawing               =   0  ' kid   0 grid type = ADrawing
	$DrawingPad             =   1  ' kid   1 grid type = XuiLabel
	$LineStyleDropButton    =   2  ' kid   2 grid type = XuiDropButton
	$XuiLabel707            =   3  ' kid   3 grid type = XuiLabel
	$LineWidthRange         =   4  ' kid   4 grid type = XuiRange
	$LineWidthLabel         =   5  ' kid   5 grid type = XuiLabel
	$DrawArcButton          =   6  ' kid   6 grid type = XuiRadioButton
	$DrawBorderButton       =   7  ' kid   7 grid type = XuiRadioButton
	$DrawBoxButton          =   8  ' kid   8 grid type = XuiRadioButton
	$DrawCircleButton       =   9  ' kid   9 grid type = XuiRadioButton
	$DrawLineButton         =  10  ' kid  10 grid type = XuiRadioButton
	$TriangleDirDropButton  =  11  ' kid  11 grid type = XuiDropButton
	$DrawPointButton        =  12  ' kid  12 grid type = XuiRadioButton
	$OptionsLabel           =  13  ' kid  13 grid type = XuiLabel
	$DrawTextButton         =  14  ' kid  14 grid type = XuiRadioButton
	$DrawTextFillButton     =  15  ' kid  15 grid type = XuiRadioButton
	$FillBoxButton          =  16  ' kid  16 grid type = XuiRadioButton
	$FillTriangleButton     =  17  ' kid  17 grid type = XuiRadioButton
	$UpperKid               =  17  ' kid maximum
'
'
	IFZ sub[] THEN GOSUB Initialize
'	XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, ADrawing) THEN RETURN
	IF (message <= upperMessage) THEN GOSUB @sub[message]
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
'NOTE: The label grid DrawingPad is sent a RedrawGrid message by using the following
'function XuiSendMessage ( g, #SetMessageFunc, #RedrawGrid, &ADrawingCode(), 0, 0, 0, 0)
'This sends the RedrawGrid message to the ADrawingCode function which then processes
'the message and redraws the grid DrawingPad whenever the grid is covered or
'or minimized.
'
'
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, ADrawing, @v0, @v1, @v2, @v3, r0, r1, &ADrawing())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"ADrawing")
	XuiLabel       (@g, #Create, 168, 4, 456, 504, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawingPad")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiDropButton  (@g, #Create, 4, 436, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $LineStyleDropButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LineStyleDropButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"[Line Style]\nSelect from list of 5 different line styles:\nSolid\nDash\nDot\nDashDot\nDashDotDot")
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Select Line Style")
	DIM text$[4]
	text$[0] = "Solid"
	text$[1] = "Dash"
	text$[2] = "Dot"
	text$[3] = "DashDot"
	text$[4] = "DashDotDot"
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"PressButton")
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 1, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 1, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"Select Line Style")
	XuiLabel       (@g, #Create, 4, 472, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"XuiLabel707")
	XuiRange       (@g, #Create, 108, 476, 44, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $LineWidthRange, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LineWidthRange")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleCenter, 0, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetTexture, $$TextureLower1, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 280, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"Label")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"1")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"Button0")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"Button1")
	XuiLabel       (@g, #Create, 12, 476, 92, 28, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LineWidthLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetTexture, $$TextureLower1, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Line Width")
	XuiRadioButton (@g, #Create, 4, 4, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawArcButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawArcButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Arc")
	XuiRadioButton (@g, #Create, 4, 40, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawBorderButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawBorderButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Border")
	XuiRadioButton (@g, #Create, 4, 76, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawBoxButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawBoxButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Box")
	XuiRadioButton (@g, #Create, 4, 112, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawCircleButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawCircleButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Circle")
	XuiRadioButton (@g, #Create, 4, 148, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawLineButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawLineButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Line")
	XuiDropButton  (@g, #Create, 4, 400, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $TriangleDirDropButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TriangleDirDropButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Triangle Direction")
	DIM text$[3]
	text$[0] = "TriangleUp"
	text$[1] = "TriangleRight"
	text$[2] = "TriangleDown"
	text$[3] = "TriangleLeft"
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"PressButton")
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 1, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 1, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"Triangle Direction")
	XuiRadioButton (@g, #Create, 4, 184, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawPointButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawPointButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Point")
	XuiLabel       (@g, #Create, 4, 364, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"OptionsLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$LightRed, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRidge, $$BorderRidge, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetTexture, $$TextureLower1, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Preferences")
	XuiRadioButton (@g, #Create, 4, 220, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawTextButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawTextButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Text")
	XuiRadioButton (@g, #Create, 4, 256, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $DrawTextFillButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DrawTextFillButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Draw Text Fill")
	XuiRadioButton (@g, #Create, 4, 292, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $FillBoxButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"FillBoxButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Fill Box")
	XuiRadioButton (@g, #Create, 4, 328, 164, 36, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &ADrawing(), -1, -1, $FillTriangleButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"FillTriangleButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$Grey, $$White, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderRaise1, $$BorderRaise1, $$BorderLower2, 0, 0, 0)
	XuiSendMessage ( g, #SetFont, 240, 800, 0, 0, 0, @"fixed")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Fill Triangle")
	GOSUB Resize
	XuiSendMessage (grid, #GetGridNumber, @g, 0, 0, 0, $DrawingPad, 0)
  XuiSendMessage ( g, #SetMessageFunc, #RedrawGrid, &ADrawingCode(), 0, 0, 0, 0)
	XuiSendMessage (grid, #GetGridNumber, @g, 0, 0, 0, $LineWidthRange, 0)
	XuiSendMessage ( g, #SetValues, 1, 1, 1, 10, 0, 0)
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
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"ADrawing")
END SUB
'
'
' *****  GetSmallestSize  *****  See "Anatomy of Grid Functions"
'
SUB GetSmallestSize
END SUB
'
'
' *****  Resize  *****  See "Anatomy of Grid Functions"
'
SUB Resize
END SUB
'
'
' *****  Selection  *****  See "Anatomy of Grid Functions"
'
SUB Selection
END SUB
'
'
' *****  Initialize  *****  ' see "Anatomy of Grid Functions"
'
SUB Initialize
	XuiGetDefaultMessageFuncArray (@func[])
	XgrMessageNameToNumber (@"LastMessage", @upperMessage)
'
	func[#Callback]           = &XuiCallback ()               ' disable to handle Callback messages internally
' func[#GetSmallestSize]    = 0                             ' enable to add internal GetSmallestSize routine
' func[#Resize]             = 0                             ' enable to add internal Resize routine
'
	DIM sub[upperMessage]
'	sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
	sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
	sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
'	sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
'	sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
	sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
	IF sub[0] THEN PRINT "ADrawing() : Initialize : error ::: (undefined message)"
	IF func[0] THEN PRINT "ADrawing() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@ADrawing, "ADrawing", &ADrawing(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
	designX = 157
	designY = 46
	designWidth = 628
	designHeight = 512
'
	gridType = ADrawing
	XuiSetGridTypeProperty (gridType, @"x",                designX)
	XuiSetGridTypeProperty (gridType, @"y",                designY)
	XuiSetGridTypeProperty (gridType, @"width",            designWidth)
	XuiSetGridTypeProperty (gridType, @"height",           designHeight)
	XuiSetGridTypeProperty (gridType, @"maxWidth",         designWidth)
	XuiSetGridTypeProperty (gridType, @"maxHeight",        designHeight)
	XuiSetGridTypeProperty (gridType, @"minWidth",         designWidth)
	XuiSetGridTypeProperty (gridType, @"minHeight",        designHeight)
	XuiSetGridTypeProperty (gridType, @"border",           $$BorderFrame)
	XuiSetGridTypeProperty (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$TextSelection)
	XuiSetGridTypeProperty (gridType, @"focusKid",         $LineStyleDropButton)
	XuiSetGridTypeProperty (gridType, @"inputTextString",  $LineStyleDropButton)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  ADrawingCode ()  #####
' #############################
'
' You can stop GuiDesigner from putting the following comment
' lines in callback functions by removing the comment lines in
' the code.xxx file in your \xb\xxx directory.
'
' This is a callback function that supports the grid function
' of the same name less the last 4 letters (ADrawingCode).
'
' When an important event occurs in the grid function created
' from your design window, is sends a callback message to this
' function, with the original message in r1.
'
' Most callback functions process only Selection messages
' because usually that's enough to perform their function.
'
' When keystrokes are entered into a TextLine or TextArea grid,
' this callback function receives a TextEvent callback message.
' This function can prevent Keystrokes from inserting characters
' in the TextLine or TextArea grid by returning a -1 in kid.
'
' The first time GuiDesigner generates this function, it puts
' a "SUB Selection" subroutine at the bottom of the function.
' It contains a SELECT CASE block with kid constants named the
' same as the grids you put in the design window.  For grids
' you didn't give a name (with the AppearanceWindow), a not
' very useful default name is substituted, so be sure to enter
' good GridNames in the Appearance window for every grid in
' your design windows.  If you change the GridNames later, the
' names in the SELECT CASE block are NOT updated, and you'll
' get "Undefined Constant" errors on lines with obsolete constant
' names when you recompile the program.  Then you'll have to
' update the names in the SELECT CASE block by hand.
'
' It's easy to find out what your code has to respond to...
' just run your program!  When you operate the grids in the
' window, the XuiReportMessage() call in this function prints
' the entry arguments in a ReportMessage window.  You can
' comment out this lines to disable this feature, but don't
' remove them entirely - it might come in handy later.
'
'
FUNCTION  ADrawingCode (grid, message, v0, v1, v2, v3, kid, r1)
'
	STATIC	drawingPad
	STATIC  func
'
	$ADrawing               =   0  ' kid   0 grid type = ADrawing
	$DrawingPad             =   1  ' kid   1 grid type = XuiLabel
	$LineStyleDropButton    =   2  ' kid   2 grid type = XuiDropButton
	$XuiLabel707            =   3  ' kid   3 grid type = XuiLabel
	$LineWidthRange         =   4  ' kid   4 grid type = XuiRange
	$LineWidthLabel         =   5  ' kid   5 grid type = XuiLabel
	$DrawArcButton          =   6  ' kid   6 grid type = XuiRadioButton
	$DrawBorderButton       =   7  ' kid   7 grid type = XuiRadioButton
	$DrawBoxButton          =   8  ' kid   8 grid type = XuiRadioButton
	$DrawCircleButton       =   9  ' kid   9 grid type = XuiRadioButton
	$DrawLineButton         =  10  ' kid  10 grid type = XuiRadioButton
	$TriangleDirDropButton  =  11  ' kid  11 grid type = XuiDropButton
	$DrawPointButton        =  12  ' kid  12 grid type = XuiRadioButton
	$OptionsLabel           =  13  ' kid  13 grid type = XuiLabel
	$DrawTextButton         =  14  ' kid  14 grid type = XuiRadioButton
	$DrawTextFillButton     =  15  ' kid  15 grid type = XuiRadioButton
	$FillBoxButton          =  16  ' kid  16 grid type = XuiRadioButton
	$FillTriangleButton     =  17  ' kid  17 grid type = XuiRadioButton
	$UpperKid               =  17  ' kid maximum
'
	IFZ drawingPad THEN GOSUB Initialize  'get grid number for grid $DrawingPad
'
'
'	XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
	IF (message = #Callback) THEN message = r1
'
	SELECT CASE message
		CASE #Selection		: GOSUB Selection   ' Common callback message
		CASE #CloseWindow : QUIT(0)						' CloseWindow message
		CASE #RedrawGrid	: GOSUB RedrawGrid	' RedrawGrid message occurs when grid is minimized or coverd by another window or grid
'		CASE #TextEvent		: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
	END SELECT
	RETURN
'
'
' *****  RedrawGrid  *****

SUB RedrawGrid

	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0 )
	v0 = $$TRUE
	kid = func
	GOSUB Selection

END SUB

' *****  Initialize  *****

SUB Initialize
' XuiGetGridNumber() gets the grid number for kid $DrawingPad

	XuiSendMessage (grid, #GetGridNumber, @drawingPad, 0, 0, 0, $DrawingPad, 0)

' XgrSetGridClip() will clip any part of drawings that try to draw past the
' boundaries of the chosed grid/kid

	XgrSetGridClip (drawingPad, drawingPad)

END SUB


' *****  Selection  *****

SUB Selection

	SELECT CASE kid
' Note: these DropButton grids rely on v0 for getting DropButton values

		CASE $LineStyleDropButton		: GOSUB LineStyle
		CASE $TriangleDirDropButton	: GOSUB TriangleDirection
	END SELECT

	IFZ v0 THEN EXIT SUB

	SELECT CASE kid
		CASE $ADrawing						:
		CASE $DrawingPad					:
		CASE $XuiLabel707					:
		CASE $LineWidthRange			: GOSUB WidthRange
		CASE $LineWidthLabel			:
		CASE $DrawArcButton				: GOSUB DrawArc
		CASE $DrawBorderButton		: GOSUB DrawBorder
		CASE $DrawBoxButton				:	GOSUB DrawBox
		CASE $DrawCircleButton		: GOSUB DrawCircle
		CASE $DrawLineButton			:	GOSUB DrawLine
		CASE $DrawPointButton			: GOSUB DrawPoint
		CASE $DrawTextButton			: GOSUB DrawText
		CASE $DrawTextFillButton	: GOSUB DrawTextFill
		CASE $FillBoxButton				: GOSUB FillBox
		CASE $FillTriangleButton	: GOSUB FillTriangle

	END SELECT
	func = kid

END SUB



'  *****  LineStyle  *****
SUB LineStyle
'	XgrSetGridDrawingMode (grid, drawingMode, lineStyle, lineWidth)
' drawingModes are values 0 to 3 , 0 = default
'	 Line Style Options:
'  $$LineStyleSolid      = 0
'  $$LineStyleDash       = 1
'  $$LineStyleDot        = 2
'  $$LineStyleDashDot    = 3
'  $$LineStyleDashDotDot = 4
' lineStyle only works when the lineWidth is set to 1
' lineWidth = value in pixels  SEE SUB WidthRange below

'	DropBox v0 : item - 0 is topmost item

	#lineStyle = v0
PRINT "lineStyle ="; v0
	XgrSetGridDrawingMode (drawingPad, 0, #lineStyle, #lineWidth)

'	PRINT "linestyle="; #lineStyle

END SUB


'  *****  WidthRange  *****
SUB WidthRange
' XgrSetGridDrawingMode (grid, drawingMode, lineStyle, lineWidth)
' lineWidth is a value in pixels
'	XuiSendStringMessage (grid, "GetValues", @v0, @v1, @v2, @v3, kid, 0)
	XuiSendStringMessage (grid, "GetValues", @v0, @v1, @v2, @v3, $LineWidthRange, 0)
' XuiRange sets v0 as current value

	#lineWidth = v0
	XgrSetGridDrawingMode (drawingPad, 0, #lineStyle, #lineWidth)

'	PRINT "linewidth="; #lineWidth

END SUB


'  *****  DrawArc  *****
SUB DrawArc

IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

' Clear the grid of previous drawing using XgrClearGrid
'	XgrClearGrid (grid, color)   color= -1 for current background color
	XgrClearGrid (drawingPad, -1)

'	XgrDrawArc (grid, color, r, startAngle#, endAngle#)
'	XgrDrawArc() draws a arc of radius r with center of curvature at
'	current drawpoint which does not need to be in the grid.
' It begins at startAngle# and ends at endAngle# expressed in radians
'	Angles increase counterclockwise, and a circle is $$TWOPI radians.
' Angles are folded into the range 0 to $$TWOPI before drawing.
' color = -1 means draw in the current drawing color.

' XgrSetDrawpoint (grid, x, y)
' XgrSetDrawpoint sets the position x, y of the pen position

	pi# = 3.1415926535896
  dtr# = pi# / 180.0

	Error = 170		'For some reason, the XgrSetDrawpoint does not seem to work here
	r = 30
	x = 20 + Error
	y = 50
	color = 100 		'colorNum $$LightRed = 100

		FOR theta = 0 TO 315 STEP 45	'draw 45 degree arc segments

			thetaStart# = theta								'starting angle in degrees
			thetaEnd# = thetaStart# + 45.0		'ending angle in degrees

			startAngle# = thetaStart# * dtr#	'starting angle in radians
			endAngle#   = thetaEnd# * dtr#		'ending angle in radians

 			XgrSetDrawpoint (drawingPad, x, y)
			XgrDrawArc (drawingPad, color, r, startAngle#, endAngle#)

			x = x + 50
		NEXT

 		XgrSetDrawpoint (drawingPad, 20, 70)
		XgrDrawText (drawingPad, -1, "45 Degree Arcs" )

		r = 40
		x = 20 + Error
		y = 150
		color = 15		'$$BrightGreen = 15

		FOR theta = 0 TO 270 STEP 90	'draw 90 degree arc segments

			thetaStart# = theta								'starting angle in degrees
			thetaEnd# = thetaStart# + 90.0		'ending angle in degrees

			startAngle# = thetaStart# * dtr#	'starting angle in radians
			endAngle#   = thetaEnd# * dtr#		'ending angle in radians

 			XgrSetDrawpoint (drawingPad, x, y)
			XgrDrawArc (drawingPad, color, r, startAngle#, endAngle#)

			x = x + 100
		NEXT

 		XgrSetDrawpoint (drawingPad, 20, 180)
		XgrDrawText (drawingPad, -1, "90 Degree Arcs" )


END IF
END SUB


'  *****  DrawBorder  *****
SUB DrawBorder

IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

' Clear the grid of previous drawing using XgrClearGrid
'	XgrClearGrid (grid, color)   color= -1 for current background color
	XgrClearGrid (drawingPad, -1)

' *****  grid border styles  *****
'
'  $$BorderHiLine1       =  4 : $$BorderLine1  =  4
'  $$BorderHiLine2       =  5 : $$BorderLine2  =  5
'  $$BorderHiLine4       =  6 : $$BorderLine4  =  6
'  $$BorderLoLine1       =  7
'  $$BorderLoLine2       =  8
'  $$BorderLoLine4       =  9
'  $$BorderRaise1        = 10 : $$BorderRaise  = 10
'  $$BorderRaise2        = 11
'  $$BorderRaise4        = 12
'  $$BorderLower1        = 13 : $$BorderLower  = 13
'  $$BorderLower2        = 14
'  $$BorderLower4        = 15
'  $$BorderFrame         = 16
'  $$BorderDrain         = 17
'  $$BorderRidge         = 18
'  $$BorderValley        = 19
'  $$BorderWide          = 20  ' window frame border w/o resize marks
'  $$BorderResize        = 21  ' window frame resize border

'	XgrDrawBorder (grid, border, back, low, high, x1, y1, x2, y2)
' back, low, high are colors, use -1 for current values
' border is the border number 4 to 21, borders 1 to 4 draw no border
' x1, y1, x2, y2 are the UL - LR corners of the border box

	gap = 19
	boxSize = 60

	border = 4

	FOR i = 0 TO 6		'no of rows
		y1 =(i*boxSize) + (i*gap) + gap
		y2 = y1 + boxSize

		FOR j = 0 TO 2		'no of columns
			x1 = (j*boxSize) + (j*gap) + gap
			x2 = x1 + boxSize

	  XgrDrawBorder (drawingPad, border, -1, -1, -1, x1, y1, x2, y2)
			INC border
		NEXT j
	NEXT i

END IF
END SUB


' *****  DrawBox  *****
SUB DrawBox

IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

' XgrDrawBox draws a box at x1, y1, x2, y2 in selected color
'	XgrDrawBox (grid, color, x1, y1, x2, y2)
'
	gap = 20
	boxSize = 50

	FOR i = 0 TO 6
		y1 =(i*boxSize) + (i*gap) + gap
		y2 = y1 + boxSize

		FOR j = 0 TO 5
			x1 = (j*boxSize) + (j*gap) + gap
			x2 = x1 + boxSize

'	Select a random color number from 0 to 124
			RandomN (@RandomNReturn#)
			rndNum# = RandomNReturn#
			colorNum = INT(rndNum# * 125)

	  XgrDrawBox (drawingPad, colorNum, x1, y1, x2, y2)

		NEXT j
	NEXT i

END IF
END SUB


' *****  DrawCircle  *****
SUB DrawCircle
IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

'	XgrDrawCircle (grid, color, r)
' XgrDrawCircle() draws a circle of radius r in selected color at current
'   set DrawPoint
' A circle drawn with the SetGridDrawingMode() linestyle=0 (solid line)
' and a linewidth = r will fill the circle. If a linestyle > 0 is chosen,
' then a "donut" type circle is drawn with outside edge of the circle
' expanding to r + linewidth/2

' XgrSetDrawpoint (grid, x, y)
' XgrSetDrawpoint sets the position x, y of the pen position

	gap = 10
	r = 10
	boxSize = r * 2

	FOR i = 0 TO 15		'no of rows
		y =(i*boxSize) + (i*gap) + gap + r


		FOR j = 0 TO 14	'no of columns
			x = (j*boxSize) + (j*gap) + gap + r

			XgrSetDrawpoint (drawingPad, x, y)


'	Select a random color number from 0 to 124
			RandomN (@RandomNReturn#)
			rndNum# = RandomNReturn#
			colorNum = INT(rndNum# * 125)

	  XgrDrawCircle (drawingPad, colorNum, r)

		NEXT j
	NEXT i

END IF
END SUB



' *****  DrawLine  *****
SUB DrawLine
IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

'XgrDrawLine (grid, color, x1, y1, x2, y2)
'XgrDrawLine draws a line from x1,y1 to x2,y2 using selected color

'This example draws a "Rose" pattern by drawing lines from points chosen
'along the edge of a circle and then drawing a line from each point to
'every other point on the circle.

	rads# = 3.141593 / 180.0

' Number of points
'	points = 20
'	Select a random number of points from 5 to 35
			RandomN (@RandomNReturn#)     'call RandomN() function
			rndNum# = RandomNReturn#
			points = INT(rndNum# * 30)+ 6

' Radius of circle
	dist = 210

	DIM pointsX[points]
	DIM pointsY[points]

	FOR i = 0 TO points
 		angle# = (360.0 / points) * i
		pointsX[i] = 230 + (dist * COS((angle# - 90) * rads#))
		pointsY[i] = 240 + (dist * SIN((angle# - 90) * rads#))
	NEXT i

		FOR i = 0 TO points
 			FOR j = i + 1 TO points - 1

 			XgrDrawLine (drawingPad, -1, pointsX[i], pointsY[i], pointsX[j], pointsY[j])

 			NEXT j
		NEXT i
END IF
END SUB


' *****  DrawPoint  *****
SUB DrawPoint

IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

'XgrDrawPoint  (grid, color, x, y)
'XgrDrawPoint draws a point (pixel) in selected color at x,y in grid

'This example draws a Spirograph made by plotting points from parametric equations

	pi# = 3.1415926535896
  dtr# = pi# / 180.0

'  a# = 100.0		'radius of inside circle
'  b# = 70.0			'radius of outside circle
'  h# = 70.0			'pen offset distance from center of outside circle h <= b

	DO
'	Select a random number for a# from 50 to 150
			RandomN (@RandomNReturn#)     'call RandomN() function
			rndNum# = RandomNReturn#
			a# = INT(rndNum# * 100)+ 51

'	Select a random number for b# from  20 to 120
			RandomN (@RandomNReturn#)     'call RandomN() function
			rndNum# = RandomNReturn#
			b# = INT(rndNum# * 100)+ 21

'	Select a random number for h# which is <= to b#
			RandomN (@RandomNReturn#)     'call RandomN() function
			rndNum# = RandomNReturn#
			h# = INT(rndNum# * b#)+ 1

	LOOP UNTIL (a# + b# + h# <= 200.0)

  increment# = 0.25   'increment for degrees, smaller for more detailed drawings
  t# = 0       'theta degrees
  m# = a# + b#   'for epi a+b+h must be <= 200 in order to fit onto grid
  n# = a# - b#
  rm# = m#/b#
  rn# = n#/b#

' select a color
'  $$Red              	=  50
'  $$BrightRed         	=  75
'  $$LightRed          	=  100

	color = 100

'Draw epitrochoid type spirograph

     tdtr# = t#*dtr#
     mbt# = rm#*tdtr#

'Parametric equations for epitrochoid

    x0# = m# * COS(tdtr#) - (h# * COS(mbt#)) + 230.0
    y0# = m# * SIN(tdtr#) - (h# * SIN(mbt#)) + 240.0

    xset = INT(x0#)      'draw first point at x0, y0 and t=0
    yset = INT(y0#)

		XgrDrawPoint (drawingPad, color, xset, yset)

    x# = 0.       'reset x
    y# = 0.       'reset y position

    DO WHILE (x# <> x0#) && (y# <> y0#)
'		draw the rest of the points until the pattern starts over

        t# = t# + increment#    'increment by .25 degrees
        tdtr# = t#*dtr#
        mbt# = rm#*tdtr#

        x# = m# * COS(tdtr#) - (h# * COS(mbt#)) + 230.0
        y# = m# * SIN(tdtr#) - (h# * SIN(mbt#)) + 240.0

        xset = INT(x#)
        yset = INT(y#)

				XgrDrawPoint (drawingPad, color, xset, yset)

    LOOP
END IF
END SUB


SUB TriangleDirection
'	Triangle Direction Options:
'  $$TriangleUp          = 16
'  $$TriangleRight       = 20
'  $$TriangleDown        = 24
'  $$TriangleLeft        = 28
'	DropBox v0 : item - 0 is topmost item

	#direction = 16 + (v0 * 4)
	PRINT "Triangle Direction="; #direction

END SUB



' *****  DrawText  *****

SUB DrawText
IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

'	XgrDrawText (grid, color, text$)
' XgrDrawText draws contents of text$ in selected color at current Drawpoint
' color = -1 draws in default color

' XgrSetDrawpoint (grid, x, y)
' XgrSetDrawpoint sets the position x, y of the pen position

	x = 10
	FOR y = 10 TO 470 STEP 18

'		Select a random color number from 0 to 124
			RandomN (@RandomNReturn#)
			rndNum# = RandomNReturn#
			colorNum = INT(rndNum# * 125)

			XgrSetDrawpoint (drawingPad, x, y)
			text$ = "XgrDrawText() example using colorNumber" + STR$(colorNum)
			XgrDrawText (drawingPad, colorNum, text$)
	NEXT y
END IF
END SUB



' ***** DrawTextFill  *****
SUB DrawTextFill
IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

'	XgrDrawTextFill (grid, color, text$)
' XgrDrawTextFill draws contents of text$ using selected background color at current Drawpoint
' color = -1 draws in default background color

' XgrSetDrawpoint (grid, x, y)
' XgrSetDrawpoint sets the position x, y of the pen position

	x = 10
	FOR y = 10 TO 470 STEP 18

'		Select a random color number from 0 to 124 for background color
			RandomN (@RandomNReturn#)
			rndNum# = RandomNReturn#
			backgroundColorNum = INT(rndNum# * 125)

' XgrSetBackgroundColor (grid, color)
' XgrSetBackgroundColor sets the background color of selected grid
' $$Black = 0
' $$White = 124
' $$LightGrey = 93

 	XgrSetBackgroundColor (drawingPad, backgroundColorNum)


'		Select a random color number from 0 to 124 for text color
			RandomN (@RandomNReturn#)
			rndNum# = RandomNReturn#
			colorNum = INT(rndNum# * 125)

		XgrSetDrawpoint (drawingPad, x, y)
		text$ = "XgrDrawTextFill() example w/ background colorNumber" + STR$(backgroundColorNum)
		XgrDrawTextFill (drawingPad, colorNum, text$)

	NEXT y
'	Set background color back to light grey
 	XgrSetBackgroundColor (drawingPad, 93)

END IF

END SUB


' *****  FillBox  *****
SUB FillBox

IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

' XgrFillBox fills a box at x1, y1, x2, y2 with selected color
' XgrFillBox (grid, color, x1, y1, x2, y2)
'
	gap = 20
	boxSize = 50

	FOR i = 0 TO 6
		y1 =(i*boxSize) + (i*gap) + gap
		y2 = y1 + boxSize

		FOR j = 0 TO 5
			x1 = (j*boxSize) + (j*gap) + gap
			x2 = x1 + boxSize

'Select a random color number from 0 to 124
			RandomN (@RandomNReturn#)
			rndNum# = RandomNReturn#
			colorNum = INT(rndNum# * 125)

	  XgrFillBox (drawingPad, colorNum, x1, y1, x2, y2)

		NEXT j
	NEXT i

END IF

END SUB


SUB FillTriangle

IFT v0 THEN 	'Radio Button v0 TRUE = selected, or FALSE = unselected

	XgrClearGrid (drawingPad, -1)

' XgrFillTriangle fills a triangle at x1, y1, x2, y2 with selected color
' using selected direction.
'	Triangle Direction Options:
'  $$TriangleUp          = 16
'  $$TriangleRight       = 20
'  $$TriangleDown        = 24
'  $$TriangleLeft        = 28
' Style is not yet available.
' XgrFillTriangle (grid, color, style, direction, x1, y1, x2, y2)
'
	IFZ #direction THEN #direction = 16

	gap = 1
	boxSize = 25

	FOR i = 0 TO 18     'no of rows
		y1 =(i*boxSize) + (i*gap) + gap
		y2 = y1 + boxSize

		FOR j = 0 TO 16   'no of columns
			x1 = (j*boxSize) + (j*gap) + gap
			x2 = x1 + boxSize

'Select a random color number from 0 to 124
			RandomN (@RandomNReturn#)
			rndNum# = RandomNReturn#
			colorNum = INT(rndNum# * 125)

	  XgrFillTriangle (drawingPad, colorNum, 0, #direction, x1, y1, x2, y2)

		NEXT j
	NEXT i

END IF

END SUB


END FUNCTION
'
'
' ########################
' #####  RandomN ()  #####
' ########################
'
FUNCTION  RandomN (@RandomNReturn#)
'random number generator by Brosco!
'returns a random value between 0 and 1
            IF #RandomNSeed# = 0 THEN GOSUB RandomNSeedRNG
            RandomNC1#=24298
            RandomNC2#=99991
            RandomNC3#=199017
            RandomNSeedTmp# = RandomNC1# * #RandomNSeed# + RandomNC2#
'	PRINT "RandomNSeedTmp#="; RandomNSeedTmp#
            #RandomNSeed# = RandomNSeedTmp# - INT( RandomNSeedTmp# / RandomNC3# ) * RandomNC3#
'	PRINT "RandomNSeed#="; #RandomNSeed#
            RandomNReturn# = #RandomNSeed# / RandomNC3#
'	PRINT "RandomNReturn#="; RandomNReturn#
RETURN
'
'
SUB RandomNSeedRNG
'            RandomNSeed = rnd(1) * 199017
						XstGetDateAndTime ( @year, @month, @day, @weekDay, @hour, @minute, @ second, @nanos)
						#RandomNSeed# = second/60.0 * 199017
'						PRINT "RandomNSeed#="; #RandomNSeed#
END SUB

END FUNCTION
END PROGRAM

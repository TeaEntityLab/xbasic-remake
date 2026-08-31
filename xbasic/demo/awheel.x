'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"progname"
VERSION	"0.0000"
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
'	IMPORT	"xma"   ' Math library     : SIN/ASIN/SINH/ASINH/LOG/EXP/SQRT...
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
INTERNAL FUNCTION  TestMouseWheel (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  TestMouseWheelCode (grid, message, v0, v1, v2, v3, kid, ANY)
DECLARE FUNCTION  MouseWheelController (v3)
DECLARE FUNCTION  CentralCEO ()
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
		CentralCEO ()

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
	XgrRegisterCursor (@"hand",         @#cursorHand)
	XgrRegisterCursor (@"help",         @#cursorHelp)
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
	TestMouseWheel (@TestMouseWheel, #CreateWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( TestMouseWheel, #SetCallback, TestMouseWheel, &TestMouseWheelCode(), -1, -1, -1, 0)
	XuiSendMessage ( TestMouseWheel, #Initialize, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( TestMouseWheel, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( TestMouseWheel, #SetGridProperties, -1, 0, 0, 0, 0, 0)
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

END FUNCTION
'
'
'	###############################
'	#####  TestMouseWheel ()  #####
'	###############################
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
FUNCTION  TestMouseWheel (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  TestMouseWheel
'
	$TestMouseWheel  =   0  ' kid   0 grid type = TestMouseWheel
	$XuiTextArea719  =   1  ' kid   1 grid type = XuiTextArea
	$XuiLabel723     =   2  ' kid   2 grid type = XuiLabel
	$XuiLabel724     =   3  ' kid   3 grid type = XuiLabel
	$XuiLabel725     =   4  ' kid   4 grid type = XuiLabel
	$XuiLabel726     =   5  ' kid   5 grid type = XuiLabel
	$XuiLabel727     =   6  ' kid   6 grid type = XuiLabel
	$Lv3             =   7  ' kid   7 grid type = XuiLabel
	$LMessage        =   8  ' kid   8 grid type = XuiLabel
	$Lv0             =   9  ' kid   9 grid type = XuiLabel
	$Lv1             =  10  ' kid  10 grid type = XuiLabel
	$Lv2             =  11  ' kid  11 grid type = XuiLabel
	$UpperKid        =  11  ' kid maximum
'
'
	IFZ sub[] THEN GOSUB Initialize
'	XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, TestMouseWheel) THEN RETURN
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
SUB Create
	IF (v0 <= 0) THEN v0 = 0
	IF (v1 <= 0) THEN v1 = 0
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiCreateGrid  (@grid, TestMouseWheel, @v0, @v1, @v2, @v3, r0, r1, &TestMouseWheel())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"TestMouseWheel")
	XuiTextArea    (@g, #Create, 4, 4, 428, 268, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $XuiTextArea719, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"XuiTextArea719")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderLower1, $$BorderLower1, $$BorderNone, 0, 0, 0)
	DIM text$[41]
	text$[ 0] = "This text-file displays a small explanation "
	text$[ 1] = "on how the WheelMouse message works."
	text$[ 3] = "When you scroll the wheel on the mouse,"
	text$[ 4] = "the CEO sents a #WindowMouseWheel message to the"
	text$[ 5] = "function that has CEO focus."
	text$[ 7] = "For any mouse-message the first three arguments"
	text$[ 8] = "(v0 - v2) are the same (xpos, ypos, keystate)"
	text$[ 9] = "The v3 argument contains two values:"
	text$[10] = "1 - direction"
	text$[11] = "2 - scroll-page size"
	text$[13] = "The direction is simply extracted by determining"
	text$[14] = "wether the value is negative or positive."
	text$[16] = "A Negative value means that the mouse is scrolled"
	text$[17] = "downwards so the cursor needs to scroll downwards."
	text$[19] = "A positive value means that the mouse is scrolled"
	text$[20] = "upwards."
	text$[22] = "The scroll-page size depends on the system "
	text$[23] = "configuration of the lines to scroll."
	text$[25] = "There is no basic wheel-mouse response configured"
	text$[26] = "for textareas, dropbuttons and lists, you have to"
	text$[27] = "implement it by yourself, this does give you the"
	text$[28] = "opportunity to use the wheelmouse message for other"
	text$[29] = "purposes than page-scrolling."
	text$[31] = "This example however just shows you the default"
	text$[32] = "usage of the wheelmouse and how to make a generic"
	text$[33] = "responder for any possible grids that has to "
	text$[34] = "respond the same way on the message."
	text$[36] = "Check out the MouseWheelController() function"
	text$[37] = "to see how the generic responder is put up."
	text$[39] = "You can call this responder from within any "
	text$[40] = "function and whatever grid in whatever window"
	text$[41] = "that supports scrolling will respond."
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"Text")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"ScrollH")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 2, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"ScrollV")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 3, 0)
	XuiLabel       (@g, #Create, 4, 276, 108, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $XuiLabel723, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"XuiLabel723")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message")
	XuiLabel       (@g, #Create, 112, 276, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $XuiLabel724, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"XuiLabel724")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"v0")
	XuiLabel       (@g, #Create, 192, 276, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $XuiLabel725, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"XuiLabel725")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"v1")
	XuiLabel       (@g, #Create, 272, 276, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $XuiLabel726, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"XuiLabel726")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"v2")
	XuiLabel       (@g, #Create, 352, 276, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $XuiLabel727, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"XuiLabel727")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"v3")
	XuiLabel       (@g, #Create, 352, 296, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $Lv3, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Lv3")
	XuiSendMessage ( g, #SetBorder, $$BorderLower1, $$BorderLower1, $$BorderNone, 0, 0, 0)
	XuiLabel       (@g, #Create, 4, 296, 108, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $LMessage, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LMessage")
	XuiSendMessage ( g, #SetBorder, $$BorderLower1, $$BorderLower1, $$BorderNone, 0, 0, 0)
	XuiLabel       (@g, #Create, 112, 296, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $Lv0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Lv0")
	XuiSendMessage ( g, #SetBorder, $$BorderLower1, $$BorderLower1, $$BorderNone, 0, 0, 0)
	XuiLabel       (@g, #Create, 192, 296, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $Lv1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Lv1")
	XuiSendMessage ( g, #SetBorder, $$BorderLower1, $$BorderLower1, $$BorderNone, 0, 0, 0)
	XuiLabel       (@g, #Create, 272, 296, 80, 20, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &TestMouseWheel(), -1, -1, $Lv2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Lv2")
	XuiSendMessage ( g, #SetBorder, $$BorderLower1, $$BorderLower1, $$BorderNone, 0, 0, 0)
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  v0123 = xywh : r0 = windowType : r1$ = display$
'
SUB CreateWindow
	IF (v0 == 0) THEN v0 = designX
	IF (v1 == 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, @r1$)
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"TestMouseWheel")
END SUB
'
'
' *****  GetSmallestSize  *****  see "Anatomy of Grid Functions"
'
SUB GetSmallestSize
END SUB
'
'
' *****  Redrawn  *****  see "Anatomy of Grid Functions"
'
SUB Redrawn
	XuiCallback (grid, #Redrawn, v0, v1, v2, v3, r0, r1)
END SUB
'
'
' *****  Resize  *****  see "Anatomy of Grid Functions"
'
SUB Resize
END SUB
'
'
' *****  Selection  *****  see "Anatomy of Grid Functions"
'
SUB Selection
END SUB
'
'
' *****  Initialize  *****  see "Anatomy of Grid Functions"
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
	sub[#Create]              = SUBADDRESS (Create)           ' must be subroutine in this function
	sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be subroutine in this function
'	sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
	sub[#Redrawn]             = SUBADDRESS (Redrawn)          ' generate #Redrawn callback if appropriate
'	sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
	sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
	IF sub[0] THEN PRINT "TestMouseWheel() : Initialize : error ::: (undefined message)"
	IF func[0] THEN PRINT "TestMouseWheel() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@TestMouseWheel, "TestMouseWheel", &TestMouseWheel(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
	designX = 306
	designY = 152
	designWidth = 436
	designHeight = 316
'
	gridType = TestMouseWheel
	XuiSetGridTypeProperty (gridType, @"x",                designX)
	XuiSetGridTypeProperty (gridType, @"y",                designY)
	XuiSetGridTypeProperty (gridType, @"width",            designWidth)
	XuiSetGridTypeProperty (gridType, @"height",           designHeight)
	XuiSetGridTypeProperty (gridType, @"maxWidth",         designWidth)
	XuiSetGridTypeProperty (gridType, @"maxHeight",        designHeight)
	XuiSetGridTypeProperty (gridType, @"minWidth",         designWidth)
	XuiSetGridTypeProperty (gridType, @"minHeight",        designHeight)
	XuiSetGridTypeProperty (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$InputTextString)
	XuiSetGridTypeProperty (gridType, @"focusKid",         $XuiTextArea719)
	XuiSetGridTypeProperty (gridType, @"inputTextArray",   $XuiTextArea719)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###################################
' #####  TestMouseWheelCode ()  #####
' ###################################
'
' You can stop GuiDesigner from putting the following comment
' lines in callback functions by removing the comment lines in
' the code.xxx file in your \xb\xxx directory.
'
' This is a callback function that supports the grid function
' of the same name less the last 4 letters (TestMouseWheelCode).
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
FUNCTION  TestMouseWheelCode (grid, message, v0, v1, v2, v3, kid, r1)
'
	$TestMouseWheel  =   0  ' kid   0 grid type = TestMouseWheel
	$XuiTextArea719  =   1  ' kid   1 grid type = XuiTextArea
	$XuiLabel723     =   2  ' kid   2 grid type = XuiLabel
	$XuiLabel724     =   3  ' kid   3 grid type = XuiLabel
	$XuiLabel725     =   4  ' kid   4 grid type = XuiLabel
	$XuiLabel726     =   5  ' kid   5 grid type = XuiLabel
	$XuiLabel727     =   6  ' kid   6 grid type = XuiLabel
	$Lv3             =   7  ' kid   7 grid type = XuiLabel
	$LMessage        =   8  ' kid   8 grid type = XuiLabel
	$Lv0             =   9  ' kid   9 grid type = XuiLabel
	$Lv1             =  10  ' kid  10 grid type = XuiLabel
	$Lv2             =  11  ' kid  11 grid type = XuiLabel
	$UpperKid        =  11  ' kid maximum
'
'	XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
	IF (message = #Callback) THEN message = r1
'
  XgrMessageNumberToName(message, @message$)
'
  IF LEFT$(message$, 6) == "Window" THEN	'Put this here when retreiving CEO messages
		' A "Window" message is send thus, the windownumber is put in the grid, NOT the gridnumber.
    XgrGetWindowGrid  (grid, @grid)  'So let's take care we get back the gridnumber.
		GOSUB ShowMessageContents
	END IF
'
	SELECT CASE message
		CASE #CloseWindow	:	QUIT(0)
		CASE #WindowMouseWheel	:GOSUB MouseWheel
		CASE #Selection		: GOSUB Selection   ' Common callback message
'		CASE #TextEvent		: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
	END SELECT
	RETURN
'
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE kid
		CASE $TestMouseWheel  :
		CASE $XuiTextArea719  :
		CASE $XuiLabel723     :
		CASE $XuiLabel724     :
		CASE $XuiLabel725     :
		CASE $XuiLabel726     :
		CASE $XuiLabel727     :
		CASE $Lv3             :
		CASE $LMessage        :
		CASE $Lv0             :
		CASE $Lv1             :
		CASE $Lv2             :
	END SELECT
END SUB

SUB MouseWheel
	onMouseOverGrid = MouseWheelController (v3)

	'Test if "screen-scrolling" mode is enabled instead of "line-scrolling" mode.
	SELECT CASE v3

		CASE 101
			XuiSendMessage ( grid, #SetTextString, 0,0,0,0, $Lv3, "PageUp")

		CASE -101
			XuiSendMessage ( grid, #SetTextString, 0,0,0,0, $Lv3, "PageDown")

	END SELECT

	IF ABS(v3) = 101 THEN
		XuiSendMessage ( grid, #Redraw, 0, 0, 0, 0, $Lv3, 0)
	END IF

END SUB

SUB ShowMessageContents
	'Only display "Window" messages!
	message$ = MID$(message$, 7)
  v0s$ = STRING(v0)
  v1s$ = STRING(v1)
  v2s$ = STRING(v2)
  v3s$ = STRING(v3)

	XuiSendMessage ( grid, #SetTextString, 0,0,0,0, $LMessage, message$)
	XuiSendMessage ( grid, #SetTextString, 0,0,0,0, $Lv0, v0s$)
	XuiSendMessage ( grid, #SetTextString, 0,0,0,0, $Lv1, v1s$)
	XuiSendMessage ( grid, #SetTextString, 0,0,0,0, $Lv2, v2s$)
	XuiSendMessage ( grid, #SetTextString, 0,0,0,0, $Lv3, v3s$)
	XuiSendMessage ( grid, #Redraw, 0, 0, 0, 0, $LMessage, 0)
	XuiSendMessage ( grid, #Redraw, 0, 0, 0, 0, $Lv0, 0)
	XuiSendMessage ( grid, #Redraw, 0, 0, 0, 0, $Lv1, 0)
	XuiSendMessage ( grid, #Redraw, 0, 0, 0, 0, $Lv2, 0)
	XuiSendMessage ( grid, #Redraw, 0, 0, 0, 0, $Lv3, 0)
END SUB

END FUNCTION
'
'
' #####################################
' #####  MouseWheelController ()  #####
' #####################################
'
FUNCTION  MouseWheelController (v3)

	'Get the gridnumber the mousepointer is hovering above
	XgrGetMouseInfo ( @window, @wingrid, @xWin, @yWin, @state, @time )

	'Get the gridnumber that has focus
	XuiSendMessage(wingrid,#GetKeyboardFocus,@FocusGrid,0,0,0,0,0)

	'Assuming it's a textarea, droplist, listbutton etc. get it's current settings and positions
	XuiSendMessage (FocusGrid, #GetTextCursor, @curPos, @curLine, @leftIndent, @topLine, 0, 0)

	SELECT CASE ALL TRUE		'Check which direction

		CASE v3 < 0	'Going down
			curLine = curLine + ABS(v3)
			topLine = topLine + ABS(v3)

		CASE v3 > 0	'Going up

			IF topLine <= ABS(v3) THEN
				curLine = 0
			ELSE
				curLine = curLine - ABS(v3)
				topLine = topLine - ABS(v3)
			END IF

	END SELECT

	'Reset coordinates to new coordinates
	XuiSendMessage (FocusGrid, #SetTextCursor, curPos, curLine, leftIndent, topLine, 0, 0)

	'Return the focusgrid (in case anyone might need it to do some other stuff with it)
	RETURN FocusGrid
END FUNCTION
'
'
' ###########################
' #####  CentralCEO ()  #####
' ###########################
'
FUNCTION  CentralCEO ()

	STATIC CEOWindow

	'Get the window number that is currently selected

	XgrGetSelectedWindow(@window)

	'If the current window has no CEO focus then set the CEO
	IF CEOWindow <> window THEN
		CEOWindow= window

		'get it's gridnumber
		XgrGetWindowGrid(window, @wingrid)

		'If the gridnumber is one of our own application grids...

		IF wingrid > 0 THEN
			'Grab it's gridtype name and strip off the first three letters

			XuiSendMessage (wingrid, #GetGridTypeName, 0, 0, 0, 0, 0, @gname$)
			gname$ = UCASE$(LEFT$(gname$, 3))

			'Check if the UCASE(windowname) is starting with a "XUI", in this case you stumble upon
			'an autonomous child-window which causes an application crash if you send a
			'#GetCallback message to this window!
			IF (wingrid > 0) AND (gname$ <> "XUI") THEN
				XuiSendMessage ( wingrid, #GetCallback,@callGrid, @callFunc, @v2, @v3, @r0, 0 )

				XgrSetCEO(callFunc)
			END IF

		END IF

	END IF
END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"anewlook"
VERSION	"0.0008"
'
IMPORT	"xst"
IMPORT	"xgr"
IMPORT	"xui"
'
INTERNAL FUNCTION  Entry          ()
INTERNAL FUNCTION  InitGui        ()
INTERNAL FUNCTION  InitProgram    ()
INTERNAL FUNCTION  CreateWindows  ()
INTERNAL FUNCTION  InitWindows    ()
INTERNAL FUNCTION  MainWindow     (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  MainWindowCode (grid, message, v0, v1, v2, v3, kid, ANY)
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
FUNCTION  CreateWindows ()
'
	IF LIBRARY(0) THEN RETURN
'
' compute initial size and position of window
'   minimal width for 80 character line
'   half display height
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
	line$ = "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	XgrGetTextImageSize (0, @line$, @dx, @dy, @width, @height, @gap, @space)
	maxwidth = #displayWidth - #windowBorderWidth - #windowBorderWidth
	textwidth = width + 32
'
	h = (#displayHeight >> 1) - #windowBorderWidth - #windowBorderWidth - #windowTitleHeight
	y = (#displayHeight >> 1) + #windowTitleHeight + #windowBorderWidth
	w = (#displayWidth >> 1) - #windowBorderWidth - #windowBorderWidth
	IF (w < textwidth) THEN w = textwidth
	IF (w > maxwidth) THEN w = maxwidth
	x = #displayWidth - w - #windowBorderWidth
'
	MainWindow     (@MainWindow, #CreateWindow, x, y, w, h, 0, 0)
	XuiSendMessage ( MainWindow, #SetCallback, MainWindow, &MainWindowCode(), -1, -1, -1, 0)
	XuiSendMessage ( MainWindow, #Initialize, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( MainWindow, #GetSmallestSize, 0, 0, @ww, @hh, 0, 0)
	IF (w < ww) THEN w = ww : x = #displayWidth - w - #windowBorderWidth
	XuiSendMessage ( MainWindow, #ResizeWindow, x, y, w, h, 0, 0)
	XuiSendMessage ( MainWindow, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( MainWindow, #SetGridProperties, -1, 0, 0, 0, 0, 0)
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
'	###########################
'	#####  MainWindow ()  #####
'	###########################
'
FUNCTION  MainWindow (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  MainWindow
'
  $MainWindow           =   0  ' kid   0 grid type = MainWindow
  $MenuBar              =   1  ' kid   1 grid type = XuiMenu
  $HotProlog            =   2  ' kid   2 grid type = XuiPushButton
  $FileLabel            =   3  ' kid   3 grid type = XuiLabel
  $StatusLabel          =   4  ' kid   4 grid type = XuiLabel
  $HotNew               =   5  ' kid   5 grid type = XuiPushButton
  $HotLoad              =   6  ' kid   6 grid type = XuiPushButton
  $HotSave              =   7  ' kid   7 grid type = XuiPushButton
  $HotSavePlus          =   8  ' kid   8 grid type = XuiPushButton
  $HotCut               =   9  ' kid   9 grid type = XuiPushButton
  $HotCopy              =  10  ' kid  10 grid type = XuiPushButton
  $HotPaste             =  11  ' kid  11 grid type = XuiPushButton
  $HotGui               =  12  ' kid  12 grid type = XuiPushButton
  $HotAbort             =  13  ' kid  13 grid type = XuiPushButton
  $HotFind              =  14  ' kid  14 grid type = XuiPushButton
  $HotReplace           =  15  ' kid  15 grid type = XuiPushButton
  $HotBack              =  16  ' kid  16 grid type = XuiPushButton
  $HotNext              =  17  ' kid  17 grid type = XuiPushButton
  $HotPrevious          =  18  ' kid  18 grid type = XuiPushButton
  $Function             =  19  ' kid  19 grid type = XuiListButton
  $HotStart             =  20  ' kid  20 grid type = XuiPushButton
  $HotContinue          =  21  ' kid  21 grid type = XuiPushButton
  $HotPause             =  22  ' kid  22 grid type = XuiPushButton
  $HotKill              =  23  ' kid  23 grid type = XuiPushButton
  $HotToCursor          =  24  ' kid  24 grid type = XuiPushButton
  $HotStepLocal         =  25  ' kid  25 grid type = XuiPushButton
  $HotStepGlobal        =  26  ' kid  26 grid type = XuiPushButton
  $HotToggleBreakpoint  =  27  ' kid  27 grid type = XuiPushButton
  $HotClearBreakpoints  =  28  ' kid  28 grid type = XuiPushButton
  $HotVariables         =  29  ' kid  29 grid type = XuiPushButton
  $HotFrames            =  30  ' kid  30 grid type = XuiPushButton
  $HotAssembly          =  31  ' kid  31 grid type = XuiPushButton
  $HotRegisters         =  32  ' kid  32 grid type = XuiPushButton
  $HotMemory            =  33  ' kid  33 grid type = XuiPushButton
  $Command              =  34  ' kid  34 grid type = XuiDropBox
  $TextLower            =  35  ' kid  35 grid type = XuiTextArea
  $UpperKid             =  35  ' kid maximum
'
'
	IFZ sub[] THEN GOSUB Initialize
'	XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, MainWindow) THEN RETURN
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
	XuiCreateGrid  (@grid, MainWindow, @v0, @v1, @v2, @v3, r0, r1, &MainWindow())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"MainWindow")
	XuiSendMessage ( grid, #SetBorder, $$BorderNone, $$BorderNone, $$BorderFrame, 0, 0, 0)
	XuiSendMessage ( grid, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:Environment")
	XuiMenu        (@g, #Create, 0, 0, 344, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $MenuBar, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"MenuBar")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderFrame, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:MenuBar")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"main menu")
	XuiSendMessage ( g, #SetFont, 300, 400, 0, 0, 0, @"Tw Cen MT")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"_file   _edit   _view   _option   _run   _debug   _status   _help")
	DIM text$[66]
	text$[ 0] = "_file   "
	text$[ 1] = " _new"
	text$[ 2] = " _text-load"
	text$[ 3] = " _load"
	text$[ 4] = " _save"
	text$[ 5] = " _mode"
	text$[ 6] = " _rename"
	text$[ 7] = " _quit"
	text$[ 8] = "_edit   "
	text$[ 9] = " _cut"
	text$[10] = " _grab"
	text$[11] = " _paste"
	text$[12] = " _delete"
	text$[13] = " _buffer"
	text$[14] = " _insert"
	text$[15] = " _erase"
	text$[16] = " _find"
	text$[17] = " _read"
	text$[18] = " _write"
	text$[19] = " _abandon"
	text$[20] = "_view   "
	text$[21] = " _function"
	text$[22] = " _prior function"
	text$[23] = " _new function"
	text$[24] = " _delete function"
	text$[25] = " _rename function"
	text$[26] = " _clone function"
	text$[27] = " _load function"
	text$[28] = " _save function"
	text$[29] = " _merge PROLOG"
	text$[30] = "_option   "
	text$[31] = " _misc"
	text$[32] = " _color of text-cursor"
	text$[33] = " _tab width (pixels)"
	text$[34] = "_run   "
	text$[35] = " _start"
	text$[36] = " _continue"
	text$[37] = " _jump"
	text$[38] = " _pause"
	text$[39] = " _kill"
	text$[40] = " _recompile"
	text$[41] = " _assembly"
	text$[42] = " _library"
	text$[43] = "_debug   "
	text$[44] = " _toggle breakpoint"
	text$[45] = " _clear all breakpoints"
	text$[46] = " _erase local breakpoints"
	text$[47] = " _memory"
	text$[48] = " _assembly"
	text$[49] = " _registers"
	text$[50] = "_status   "
	text$[51] = " _compilation errors"
	text$[52] = " _runtime errors"
	text$[53] = "_help  "
	text$[54] = " new"
	text$[55] = " _notes"
	text$[56] = " _support"
	text$[57] = " _message"
	text$[58] = " _language"
	text$[59] = " _operator"
	text$[60] = " _dot command"
	text$[61] = " standard library"
	text$[62] = " graphics library"
	text$[63] = " GuiDesigner library"
	text$[64] = " mathematics library"
	text$[65] = " complex number library"
	text$[66] = " network / internet library"
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"MenuPullDown")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:MenuBar")
	XuiPushButton  (@g, #Create, 344, 0, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotProlog, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotProlog")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotProlog")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display program PROLOG")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_prolog.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiLabel       (@g, #Create, 368, 0, 160, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"FileLabel")
	XuiSendMessage ( g, #SetColor, $$Grey, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, -1, -1, -1, $$LightYellow, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:FileLabel")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"filename")
	XuiSendMessage ( g, #SetFont, 280, 400, 0, 0, 0, @"Comic Sans MS")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"-filename-")
	XuiLabel       (@g, #Create, 528, 0, 160, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"StatusLabel")
	XuiSendMessage ( g, #SetColor, $$Grey, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, -1, -1, -1, $$LightYellow, 0, 0)
	XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:StatusLabel")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"status")
	XuiSendMessage ( g, #SetFont, 280, 400, 0, 0, 0, @"Comic Sans MS")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"-status-")
	XuiPushButton  (@g, #Create, 0, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotNew, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotNew")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotNew")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"new program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_new.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 24, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotLoad, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotLoad")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotLoad")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"load program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_open.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 48, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotSave, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotSave")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotSave")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"save program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_save.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 72, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotSavePlus, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotSavePlus")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotSavePlus")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"save new version of program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_saveplus.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 104, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotCut, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotCut")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotCut")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"cut selected text, put copy in clipboard")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_cut.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 128, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotCopy, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotCopy")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotCopy")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"copy selected text, put in clipboard")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_copy.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 152, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotPaste, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotPaste")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotPaste")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"paste clipboard text at cursor")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_paste.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 184, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotGui, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotGui")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotGui")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display/hide GuiDesigner toolkit")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_toolkit.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 208, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotAbort, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotAbort")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotAbort")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"abort executing command")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_stop.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 240, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotFind, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotFind")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotFind")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F11 : find string in program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_find.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 264, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotReplace, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotReplace")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotReplace")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F12 : replace string in program or text-file")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_replace.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 296, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotBack, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotBack")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotBack")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display previous function")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_back.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 320, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotNext, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotNext")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotNext")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display next function")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_next.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 344, 24, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotPrevious, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotPrevious")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotPrevious")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display previously displayed function")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_function_previous.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiListButton  (@g, #Create, 368, 24, 320, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $Function, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Function")
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, -1, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Function")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"view function")
	XuiSendMessage ( g, #SetFont, 300, 700, 0, 0, 0, @"Comic Sans MS")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"select function pulldown")
	DIM text$[4]
	text$[0] = "PROLOG / text - PROLOG is always first"
	text$[1] = "Entry         - entry function is always second"
	text$[2] = "FunctionFirst - first function sorted alphabetically"
	text$[3] = " ... "
	text$[4] = "FunctionFinal - final function sorted alphabetically"
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"FunctionPressButton")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:Function")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 1, @"view function")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"select function pulldown")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"FunctionPullDown")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 2, @"pde.hlp:Function")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 2, @"view function")
'	DIM text$[4]
'	text$[0] = "PROLOG / text  - PROLOG is always first"
'	text$[1] = "Entry          - entry function is always second"
'	text$[2] = "FunctionOne    - first function sorted alphabetically"
'	text$[3] = " ... "
'	text$[4] = "FunctionLast   - last function sorted alphabetically"
'	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 2, @text$[])
	XuiPushButton  (@g, #Create, 0, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotStart, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotStart")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotStart")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F1 : start program execution from beginning")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_start.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 24, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotContinue, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotContinue")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotContinue")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F2 : continue program execution after pause")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_continue.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 48, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotPause, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotPause")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotPause")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F3 : pause program execution now")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_pause.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 72, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotKill, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotKill")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotKill")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F4 : kill program execution : continue not possible")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_kill.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 104, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotToCursor, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotToCursor")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotToCursor")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F5 : execute program with breakpoint at cursor line")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_step_cursor.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 128, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotStepLocal, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotStepLocal")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotStepLocal")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F6 : execute single-step local - step over called functions")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_step_local.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 152, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotStepGlobal, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotStepGlobal")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotStepGlobal")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F7 : execute single-step global - step into called functions")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_step_global.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 184, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotToggleBreakpoint, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotToggleBreakpoint")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotToggleBreakpoint")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"toggle breakpoint on/off at cursor line")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_breakpoint.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 208, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotClearBreakpoints, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotClearBreakpoints")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotClearBreakpoints")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"clear all breakpoints")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_breakpoints_clear.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 240, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotVariables, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotVariables")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotVariables")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F8 : display variables - view and change values")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_variables.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 264, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotFrames, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotFrames")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotFrames")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F9 : display function call-stack")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_stack.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 296, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotAssembly, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotAssembly")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotAssembly")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"F10 : display assembly language for cursor line")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_assembly.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 320, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotRegisters, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotRegisters")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotRegisters")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display CPU registers")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_registers.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiPushButton  (@g, #Create, 344, 48, 24, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $HotMemory, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"HotMemory")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:HotMemory")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"display memory")
	XuiSendMessage ( g, #SetImage, 0, 0, 4, 4, 0, @"$XBDIR/images/icon_memory.bmp")
	XuiSendMessage ( g, #SetImageCoords, 0, 0, 16, 16, 0, 0)
	XuiDropBox     (@g, #Create, 368, 48, 320, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $Command, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Command")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, -1, 0, 0, 0, 0, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"enter dot commands here")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @".c enter dot commands here")
	DIM text$[15]
	text$[ 0] = ".c enter dot commands here"
	text$[ 1] = ".fl filename"
	text$[ 2] = ".ft filename"
	text$[ 3] = ".fs filename"
	text$[ 4] = ".fq"
	text$[ 5] = ".v funcname"
	text$[ 6] = ".v PROLOG"
	text$[ 7] = ".vp"
	text$[ 8] = ".v-"
	text$[ 9] = ".v"
	text$[10] = ".rs"
	text$[11] = ".rr"
	text$[12] = ".rk"
	text$[13] = ".h"
	text$[14] = ".f findstring"
	text$[15] = ".r findstring replacestring"
	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"CommandTextLine")
	XuiSendMessage ( g, #SetColorExtra, $$LightYellow, $$LightYellow, $$Black, $$White, 1, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 1, @"enter dot commands here")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @".c enter dot commands here")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"CommandPressButton")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 2, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 2, @"enter dot commands here")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"CommandPullDown")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 3, @"pde.hlp:Command")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 3, @"enter dot commands here")
'	DIM text$[15]
'	text$[ 0] = ".c enter dot commands here"
'	text$[ 1] = ".fl filename
'	text$[ 2] = ".ft filename
'	text$[ 3] = ".fs filename
'	text$[ 4] = ".fq"
'	text$[ 5] = ".v funcname"
'	text$[ 6] = ".v PROLOG"
'	text$[ 7] = ".vp"
'	text$[ 8] = ".v-"
'	text$[ 9] = ".v"
'	text$[10] = ".rs"
'	text$[11] = ".rr"
'	text$[12] = ".rk"
'	text$[13] = ".h"
'	text$[14] = ".f findstring"
'	text$[15] = ".r findstring replacestring"
'	XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 3, @text$[])
	XuiTextArea    (@g, #Create, 0, 72, 688, 128, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &MainWindow(), -1, -1, $TextLower, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLower")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 0, @"pde.hlp:TextLower")
	XuiSendMessage ( g, #SetHintString, 0, 0, 0, 0, 0, @"program or text")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"Text")
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 1, @"pde.hlp:TextLower")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"ScrollH")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 2, 0)
	XuiSendMessage ( g, #SetColor, 43, -1, -1, -1, 2, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 2, @"pde.hlp:TextLower")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"ScrollV")
	XuiSendMessage ( g, #SetStyle, 2, 0, 0, 0, 3, 0)
	XuiSendMessage ( g, #SetColor, 43, -1, -1, -1, 3, 0)
	XuiSendMessage ( g, #SetHelpString, 0, 0, 0, 0, 3, @"pde.hlp:TextLower")
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
	v0 = 0 : v1 = 0 : r0 = window : ATTACH r1$ TO display$
	GOSUB Create
	r1 = 0 : ATTACH display$ TO r1$
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"MainWindow")
END SUB
'
'
' *****  GetSmallestSize  *****  see "Anatomy of Grid Functions"
'
SUB GetSmallestSize
	v2 = designWidth
	v3 = designHeight
END SUB
'
'
' *****  Resize  *****  see "Anatomy of Grid Functions"
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	IF (v2 < vv2) THEN v2 = vv2
	IF (v3 < vv3) THEN v3 = vv3
'
' position and size main/parent grid
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
'
' make sure we have a plausibly compact font in the menu bar
'
	XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 280, 400, 0, 0, $MenuBar, @"MS Sans Serif")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Arial")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Comic Sans MS")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Helvetica")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 260, 400, 0, 0, $MenuBar, @"Helv")
	IFZ font THEN XuiSendMessage ( grid, #GetFontNumber, @font, 0, 0, 0, $MenuBar, 0)
	IFZ font THEN XuiSendMessage ( grid, #SetFont, 300, 400, 0, 0, $MenuBar, @"Tw Cen MT")
'
	XuiSendMessage (grid, #SetFontNumber, font, 0, 0, 0, $FileLabel, 0)
	XuiSendMessage (grid, #SetFontNumber, font, 0, 0, 0, $StatusLabel, 0)
'
	XuiGetSize (grid, #GetSize, @xx, @yy, @ww, @hh, $MainWindow, 0)		' whole window
	XuiGetSize (grid, #GetSize, @tx, @ty, @tw, @th, $TextLower, 0)		' program text
	XuiGetSize (grid, #GetSize, @fx, @fy, @fw, @fh, $Function, 0)			' function
'
	xw0 = v2 - fx									' space to right of menu-bar & buttons
	xw1 = xw0 >> 1								' width of left-hand button
	xw2 = xw0 - xw1								' width of right-hand button
	sx = fx + xw1									' x position of right-hand button
	th = v3 - ty									' new height of program text
'
'	PRINT v0; v1; v2; v3;; fx; sx; tx;;; xw0; xw1; xw2;;; xx; yy; ww; hh
'
	XuiSendMessage (grid, #Resize, fx,  0, xw1, 24, $FileLabel, 0)
	XuiSendMessage (grid, #Resize, sx,  0, xw2, 24, $StatusLabel, 0)
	XuiSendMessage (grid, #Resize, fx, 24, xw0, 24, $Function, 0)
	XuiSendMessage (grid, #Resize, fx, 48, xw0, 24, $Command, 0)
	XuiSendMessage (grid, #Resize, tx, ty,  v2, th, $TextLower, 0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  Selection  *****  see "Anatomy of Grid Functions"
'
SUB Selection
'	PRINT "MainWindow() : #Selection : "; grid;; message;; v0;; v1;; v2;; v3;; r0;; r1
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
	func[#GetSmallestSize]    = 0                             ' enable to add internal GetSmallestSize routine
	func[#GotKeyboardFocus]   = &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]  = &XuiLostKeyboardFocus()
	func[#Resize]             = 0                             ' enable to add internal Resize routine
	func[#SetKeyboardFocus]   = &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
'	sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
	sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
	sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
	sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
	sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
	sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
	IF sub[0] THEN PRINT "MainWindow() : Initialize : error ::: (undefined message)"
	IF func[0] THEN PRINT "MainWindow() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@MainWindow, "MainWindow", &MainWindow(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
	designX = 908
	designY = 623
	designWidth = 632
	designHeight = 200
'
	gridType = MainWindow
	XuiSetGridTypeProperty (gridType, @"x",                designX)
	XuiSetGridTypeProperty (gridType, @"y",                designY)
	XuiSetGridTypeProperty (gridType, @"width",            designWidth)
	XuiSetGridTypeProperty (gridType, @"height",           designHeight)
'	XuiSetGridTypeProperty (gridType, @"maxWidth",         designWidth)
'	XuiSetGridTypeProperty (gridType, @"maxHeight",        designHeight)
	XuiSetGridTypeProperty (gridType, @"minWidth",         designWidth)
	XuiSetGridTypeProperty (gridType, @"minHeight",        designHeight)
	XuiSetGridTypeProperty (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$InputTextString OR $$InputTextArray OR $$TextSelection)
	XuiSetGridTypeProperty (gridType, @"focusKid",         $TextLower)
	XuiSetGridTypeProperty (gridType, @"inputTextArray",   $TextLower)
	XuiSetGridTypeProperty (gridType, @"inputTextString",  $Command)
	XuiSetGridTypeProperty (gridType, @"redrawFlags",      $$RedrawClearBorder)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###############################
' #####  MainWindowCode ()  #####
' ###############################
'
FUNCTION  MainWindowCode (grid, message, v0, v1, v2, v3, kid, r1)
'
  $MainWindow           =   0  ' kid   0 grid type = MainWindow
  $MenuBar              =   1  ' kid   1 grid type = XuiMenu
  $HotProlog            =   2  ' kid   2 grid type = XuiPushButton
  $FileLabel            =   3  ' kid   3 grid type = XuiLabel
  $StatusLabel          =   4  ' kid   4 grid type = XuiLabel
  $HotNew               =   5  ' kid   5 grid type = XuiPushButton
  $HotLoad              =   6  ' kid   6 grid type = XuiPushButton
  $HotSave              =   7  ' kid   7 grid type = XuiPushButton
  $HotSavePlus          =   8  ' kid   8 grid type = XuiPushButton
  $HotCut               =   9  ' kid   9 grid type = XuiPushButton
  $HotCopy              =  10  ' kid  10 grid type = XuiPushButton
  $HotPaste             =  11  ' kid  11 grid type = XuiPushButton
  $HotGui               =  12  ' kid  12 grid type = XuiPushButton
  $HotAbort             =  13  ' kid  13 grid type = XuiPushButton
  $HotFind              =  14  ' kid  14 grid type = XuiPushButton
  $HotReplace           =  15  ' kid  15 grid type = XuiPushButton
  $HotBack              =  16  ' kid  16 grid type = XuiPushButton
  $HotNext              =  17  ' kid  17 grid type = XuiPushButton
  $HotPrevious          =  18  ' kid  18 grid type = XuiPushButton
  $Function             =  19  ' kid  19 grid type = XuiListButton
  $HotStart             =  20  ' kid  20 grid type = XuiPushButton
  $HotContinue          =  21  ' kid  21 grid type = XuiPushButton
  $HotPause             =  22  ' kid  22 grid type = XuiPushButton
  $HotKill              =  23  ' kid  23 grid type = XuiPushButton
  $HotToCursor          =  24  ' kid  24 grid type = XuiPushButton
  $HotStepLocal         =  25  ' kid  25 grid type = XuiPushButton
  $HotStepGlobal        =  26  ' kid  26 grid type = XuiPushButton
  $HotToggleBreakpoint  =  27  ' kid  27 grid type = XuiPushButton
  $HotClearBreakpoints  =  28  ' kid  28 grid type = XuiPushButton
  $HotVariables         =  29  ' kid  29 grid type = XuiPushButton
  $HotFrames            =  30  ' kid  30 grid type = XuiPushButton
  $HotAssembly          =  31  ' kid  31 grid type = XuiPushButton
  $HotRegisters         =  32  ' kid  32 grid type = XuiPushButton
  $HotMemory            =  33  ' kid  33 grid type = XuiPushButton
  $Command              =  34  ' kid  34 grid type = XuiDropBox
  $TextLower            =  35  ' kid  35 grid type = XuiTextArea
  $UpperKid             =  35  ' kid maximum
'
	XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
	IF (message = #Callback) THEN message = r1
'
	SELECT CASE message
		CASE #CloseWindow	: QUIT(0)						' Quit program
		CASE #Selection		: GOSUB Selection   ' Common callback message
		CASE #TextEvent		: GOSUB TextEvent   ' KeyDown in TextArea or Command
	END SELECT
	RETURN
'
'
' *****  Selection  *****
'
SUB Selection
	SELECT CASE kid
		CASE $MainWindow           : XuiMessage ("MainWindow")
		CASE $MenuBar              : GOSUB MainMenu
		CASE $HotProlog            : XuiMessage ("HotProlog")
		CASE $FileLabel            : XuiMessage ("FileLabel")
		CASE $StatusLabel          : XuiMessage ("StatusLabel")
		CASE $HotNew               : XuiMessage ("HotNew")
		CASE $HotLoad              : XuiMessage ("HotLoad")
		CASE $HotSave              : XuiMessage ("HotSave")
		CASE $HotSavePlus          : XuiMessage ("HotSavePlus")
		CASE $HotCut               : XuiMessage ("HotCut")
		CASE $HotCopy              : XuiMessage ("HotCopy")
		CASE $HotPaste             : XuiMessage ("HotPaste")
		CASE $HotGui               : XuiMessage ("HotGui")
		CASE $HotAbort             : XuiMessage ("HotAbort")
		CASE $HotFind              : XuiMessage ("HotFind")
		CASE $HotReplace           : XuiMessage ("HotReplace")
		CASE $HotBack              : XuiMessage ("HotBack")
		CASE $HotNext              : XuiMessage ("HotNext")
		CASE $HotPrevious          : XuiMessage ("HotPrevious")
		CASE $Function             : GOSUB GetEntry : XuiMessage ("Function\n\n" + entry$)
		CASE $HotStart             : XuiMessage ("HotStart")
		CASE $HotContinue          : XuiMessage ("HotContinue")
		CASE $HotPause             : XuiMessage ("HotPause")
		CASE $HotKill              : XuiMessage ("HotKill")
		CASE $HotToCursor          : XuiMessage ("HotToCursor")
		CASE $HotStepLocal         : XuiMessage ("HotStepLocal")
		CASE $HotStepGlobal        : XuiMessage ("HotStepGlobal")
		CASE $HotToggleBreakpoint  : XuiMessage ("HotToggleBreakpoint")
		CASE $HotClearBreakpoints  : XuiMessage ("HotClearBreakpoints")
		CASE $HotVariables         : XuiMessage ("HotVariables")
		CASE $HotFrames            : XuiMessage ("HotFrames")
		CASE $HotAssembly          : XuiMessage ("HotAssembly")
		CASE $HotRegisters         : XuiMessage ("HotRegisters")
		CASE $HotMemory            : XuiMessage ("HotMemory")
		CASE $Command              : GOSUB GetEntry : XuiMessage ("Command\n\n" + entry$)
		CASE $TextLower            : XuiMessage ("TextLower")
	END SELECT
END SUB
'
'
' *****  MainMenu  *****
'
SUB MainMenu
	XuiSendMessage (grid, #GetTextArray, 0, 0, 0, 0, kid, @text$[])
	upper = UBOUND (text$[])
	pulldown = 0
	menu = 0
	FOR i = 0 TO upper
		menu$ = text$[i]
		m$ = LTRIM$(menu$)
		IF (m$ = menu$) THEN
			INC menu
			IF (menu = v0) THEN
				found = $$TRUE
				EXIT FOR
			END IF
		END IF
	NEXT i
	IF found THEN
		menu$ = TRIM$ (menu$)
		entry$ = TRIM$ (text$[i+v1+1])
		XuiMessage ( "XuiMenu\n\nv0 = " + STRING$(v0) + " = \"" + menu$ + "\"\nv1 = " + STRING$(v1) + " = \"" + entry$ + "\"")
	END IF
END SUB
'
'
' *****  GetEntry  *****
'
SUB GetEntry
	entry$ = ""
	IF (v0 < 0) THEN
		XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, kid, @entry$)
	ELSE
		XuiSendMessage (grid, #GetTextArray, 0, 0, 0, 0, kid, @text$[])
		IF (v0 > UBOUND(text$[])) THEN EXIT SUB
		entry$ = text$[v0]
	END IF
END SUB
'
'
' *****  TextEvent  *****
'
SUB TextEvent
'	PRINT "MainWindowCode(): TextEvent: Key = "; CHR$(key)
	IF (v2 == 0x1B10001B) THEN
		SELECT CASE kid
			CASE $Command			: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $TextLower, 0)
													kid = -1
			CASE $TextLower		: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $Command, 0)
													kid = -1
		END SELECT
	END IF
	EXIT SUB
END SUB
END FUNCTION
END PROGRAM

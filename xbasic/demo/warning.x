'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"warning"
VERSION	"0.0007"
'
IMPORT  "xst"
IMPORT  "xui"
IMPORT  "xgr"
'
EXPORT
DECLARE  FUNCTION  Entry         ()
DECLARE  FUNCTION  Blowback      ()
END EXPORT
INTERNAL FUNCTION  InitGui       ()
INTERNAL FUNCTION  InitProgram   ()
INTERNAL FUNCTION  CreateWindows ()
EXPORT
DECLARE  FUNCTION  XuiWarning1B  (grid, message, v0, v1, v2, v3, kid, ANY)
DECLARE  FUNCTION  XuiWarning2B  (grid, message, v0, v1, v2, v3, kid, ANY)
DECLARE  FUNCTION  XuiWarning3B  (grid, message, v0, v1, v2, v3, kid, ANY)
DECLARE  FUNCTION  XuiWarning4B  (grid, message, v0, v1, v2, v3, kid, ANY)
END EXPORT
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
	IF entry THEN RETURN
	entry = $$TRUE
'
	Xui ()												' initialize GuiDesigner
	InitGui ()										' initialize messages
	InitProgram ()								' initialize this program
	CreateWindows ()							' create main window and others
	IF LIBRARY(0) THEN RETURN			' Return to main program message loop
'
	DO														' the message loop
		XgrProcessMessages (1)			' process one message
	LOOP UNTIL terminateProgram		' and repeat until program is terminated
END FUNCTION
'
'
' #########################
' #####  Blowback ()  #####
' #########################
'
FUNCTION  Blowback ()
'	PRINT "warning.x:Blowback()"
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
' Add code to InitProgram() to initialize whatever needs initialization.
' Do not delete this function - leave it empty if not needed.
'
FUNCTION  InitProgram ()
	XuiWarning1B (0, 0, 0, 0, 0, 0, 0, 0)
	XuiWarning2B (0, 0, 0, 0, 0, 0, 0, 0)
	XuiWarning3B (0, 0, 0, 0, 0, 0, 0, 0)
	XuiWarning4B (0, 0, 0, 0, 0, 0, 0, 0)
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
FUNCTION  CreateWindows ()
'
	IF LIBRARY(0) THEN RETURN
END FUNCTION
'
'
' #############################
' #####  XuiWarning1B ()  #####  Label and PushButton
' #############################
'
FUNCTION  XuiWarning1B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiWarning1B
'
	$Warning1B		= 0
	$Label				= 1
	$Button0			= 2
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiWarning1B) THEN RETURN
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
	XuiCreateGrid  (@grid, XuiWarning1B, @v0, @v1, @v2, @v3, r0, r1, &XuiWarning1B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning1B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PushButton")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1 = &WindowFunc()
'
SUB CreateWindow
	IF (v0 <= 0) THEN v0 = designX
	IF (v1 <= 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, r1)
	v0 = 0 : v1 = 0 : r0 = window : r1 = 0
	GOSUB Create
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiWarning1B")
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
	labelWidth = v2 - bw - bw
	labelHeight = v3 - buttonHeight - bw - bw
	buttonWidth = labelWidth
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
	IF sub[0] THEN PRINT "XuiWarning1B() : Initialize : error::: (undefined message)"
	IF func[0] THEN PRINT "XuiWarning1B() : Initialize : error::: (undefined message)"
	XuiRegisterGridType (@XuiWarning1B, @"XuiWarning1B", &XuiWarning1B(), @func[], @sub[])
'
	designX = 8
	designY = 27
	designWidth = 80
	designHeight = 48
'
	gridType = XuiWarning1B
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
' #####  XuiWarning2B ()  #####  Label and 2 PushButtons
' #############################
'
FUNCTION  XuiWarning2B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiWarning2B
'
	$Warning2B		= 0
	$Label				= 1
	$Button0			= 2
	$Button1			= 3
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiWarning2B) THEN RETURN
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
	XuiCreateGrid  (@grid, XuiWarning2B, @v0, @v1, @v2, @v3, r0, r1, &XuiWarning2B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning2B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning2B(), -1, -1, $Button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1 = &WindowFunc()
'
SUB CreateWindow
	IF (v0 <= 0) THEN v0 = designX
	IF (v1 <= 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, r1)
	v0 = 0 : v1 = 0 : r0 = window : r1 = 0
	GOSUB Create
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiWarning2B")
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
	labelWidth = v2 - bw - bw
	labelHeight = v3 - buttonHeight - bw - bw
	buttonWidth = labelWidth >> 1
	width0 = buttonWidth
	width1 = labelWidth - width0
'
	x = bw
	y = bw
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
	IF sub[0] THEN PRINT "XuiWarning2B() : Initialize : error::: (undefined message)"
	IF func[0] THEN PRINT "XuiWarning2B() : Initialize : error::: (undefined message)"
	XuiRegisterGridType (@XuiWarning2B, @"XuiWarning2B", &XuiWarning2B(), @func[], @sub[])
'
	designX = 8
	designY = 27
	designWidth = 160
	designHeight = 48
'
	gridType = XuiWarning2B
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
' #####  XuiWarning3B ()  #####  Label and 3 PushButtons
' #############################
'
FUNCTION  XuiWarning3B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiWarning3B
'
	$Warning3B		= 0
	$Label				= 1
	$Button0			= 2
	$Button1			= 3
	$Button2			= 4
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiWarning3B) THEN RETURN
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
	XuiCreateGrid  (@grid, XuiWarning3B, @v0, @v1, @v2, @v3, r0, r1, &XuiWarning3B())
	XuiLabel       (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning3B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning3B(), -1, -1, $Button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Option")
	XuiPushButton  (@g, #Create, 0, 0, 0, 0, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning3B(), -1, -1, $Button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button2")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1 = &WindowFunc()
'
SUB CreateWindow
	IF (v0 <= 0) THEN v0 = designX
	IF (v1 <= 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, r1)
	v0 = 0 : v1 = 0 : r0 = window : r1 = 0
	GOSUB Create
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiWarning3B")
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
' *****  Resize  *****		This reconfigures window to current text sizes
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	v2 = MAX(vv2, v2)
	v3 = MAX(vv3, v3)
'
	width = buttonWidth + buttonWidth + buttonWidth
	height = labelHeight + buttonHeight + bw + bw
	IF (width < labelWidth) THEN width = labelWidth
	width = width + bw + bw
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	IF (v3 >= (labelHeight + buttonHeight + bw + bw + 4)) THEN buttonHeight = buttonHeight + 4
'
	labelWidth = v2 - bw - bw
	labelHeight = v3 - buttonHeight - bw - bw
	buttonWidth = labelWidth / 3
	width0 = buttonWidth
	width1 = buttonWidth
	width2 = labelWidth - width0 - width1
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
	IF sub[0] THEN PRINT "XuiWarning3B() : Initialize : error::: (undefined message)"
	IF func[0] THEN PRINT "XuiWarning3B() : Initialize : error::: (undefined message)"
	XuiRegisterGridType (@XuiWarning3B, @"XuiWarning3B", &XuiWarning3B(), @func[], @sub[])
'
	designX = 8
	designY = 27
	designWidth = 240
	designHeight = 48
'
	gridType = XuiWarning3B
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
' #####  XuiWarning4B ()  #####  Label and 4 PushButtons
' #############################
'
FUNCTION  XuiWarning4B (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
	STATIC	SUBADDR  sub[]
	STATIC	upperMessage
	STATIC	XuiWarning4B
'
	$Warning4B	= 0  ' kid 0
	$Label			= 1  ' kid 1
	$Button0		= 2  ' kid 2
	$Button1		= 3  ' kid 3
	$Button2		= 4  ' kid 4
	$Button3		= 5  ' kid 5
'
	IFZ sub[] THEN GOSUB Initialize
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiWarning4B) THEN RETURN
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
	XuiCreateGrid  (@grid, XuiWarning4B, @v0, @v1, @v2, @v3, r0, r1, &XuiWarning4B())
	XuiLabel       (@g, #Create, 4, 4, 400, 28, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label")
	XuiPushButton  (@g, #Create, 4, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning4B(), -1, -1, $Button0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button0")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Enter")
	XuiPushButton  (@g, #Create, 104, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning4B(), -1, -1, $Button1, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button1")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Update")
	XuiPushButton  (@g, #Create, 204, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning4B(), -1, -1, $Button2, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button2")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Retry")
	XuiPushButton  (@g, #Create, 304, 32, 100, 28, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &XuiWarning4B(), -1, -1, $Button3, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Button3")
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Cancel")
	GOSUB Resize
END SUB
'
'
' *****  CreateWindow  *****  r0 = windowType : r1 = &WindowFunc()
'
SUB CreateWindow
	IF (v0 <= 0) THEN v0 = designX
	IF (v1 <= 0) THEN v1 = designY
	IF (v2 <= 0) THEN v2 = designWidth
	IF (v3 <= 0) THEN v3 = designHeight
	XuiWindow (@window, #WindowCreate, v0, v1, v2, v3, r0, r1)
	v0 = 0 : v1 = 0 : r0 = window : r1 = 0
	GOSUB Create
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XuiWarning4B")
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
' *****  Resize  *****		This reconfigures window to current text sizes
'
SUB Resize
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize
	v2 = MAX (vv2, v2)
	v3 = MAX (vv3, v3)
'
	width = buttonWidth + buttonWidth + buttonWidth
	height = labelHeight + buttonHeight + bw + bw
	IF (width < labelWidth) THEN width = labelWidth
	width = width + bw + bw
'
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	IF (v3 >= (labelHeight + buttonHeight + bw + bw + 4)) THEN buttonHeight = buttonHeight + 4
'
	labelWidth = v2 - bw - bw
	labelHeight = v3 - buttonHeight - bw - bw
	buttonWidth = labelWidth >> 2
	width0 = buttonWidth
	width1 = buttonWidth
	width2 = buttonWidth
	width3 = labelWidth - width0 - width1 - width2
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
	IF sub[0] THEN PRINT "XuiWarning4B() : Initialize : error::: (undefined message)"
	IF func[0] THEN PRINT "XuiWarning4B() : Initialize : error::: (undefined message)"
	XuiRegisterGridType (@XuiWarning4B, @"XuiWarning4B", &XuiWarning4B(), @func[], @sub[])
'
	designX = 8
	designY = 27
	designWidth = 320
	designHeight = 48
'
	gridType = XuiWarning4B
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
END PROGRAM

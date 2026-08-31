'
' ####################
' #####  PROLOG  #####
' ####################
'
' Display and play with the grids in the standard toolkit.
' Callback function arguments are printed in the console window.
' DemoButtons() sets special keyboard focus colors for XuiPushButtons.
'
PROGRAM "agrids"
VERSION "0.0014"
'
IMPORT "xst"
IMPORT "xgr"
IMPORT "xui"
'
INTERNAL FUNCTION  Entry              ()
INTERNAL FUNCTION  InitGui            ()
INTERNAL FUNCTION  InitProgram        ()
INTERNAL FUNCTION  CreateWindows      ()
INTERNAL FUNCTION  DemoGUI            (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoGUICode        (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoButton         (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoButtonCode     (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoText           (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoTextCode       (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoDialog         (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoDialogCode     (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoPullDown       (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoPullDownCode   (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoFileCode       (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoFontCode       (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoMiscellany     (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  DemoMiscellanyCode (grid, message, v0, v1, v2, v3, kid, ANY)
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
	IF LIBRARY(0) THEN RETURN			' main program has message loop
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
' ***************************************
' *****  Register Standard Cursors  *****
' ***************************************
'
	XgrRegisterCursor (@"Arrow",			@#cursorArrow)
	XgrRegisterCursor (@"UpArrow",		@#cursorArrowN)
	XgrRegisterCursor (@"Arrow",			@#cursorArrowNW)
	XgrRegisterCursor (@"SizeNS",			@#cursorArrowsNS)
	XgrRegisterCursor (@"SizeWE",			@#cursorArrowsWE)
	XgrRegisterCursor (@"SizeNWSE",		@#cursorArrowsNWSE)
	XgrRegisterCursor (@"SizeNESW",		@#cursorArrowsNESW)
	XgrRegisterCursor (@"SizeAll",		@#cursorArrowsAll)
	XgrRegisterCursor (@"CrossHair",	@#cursorCrosshair)
	XgrRegisterCursor (@"Arrow",			@#cursorDefault)
	XgrRegisterCursor (@"Wait",				@#cursorHourglass)
	XgrRegisterCursor (@"Insert",			@#cursorInsert)
	XgrRegisterCursor (@"No",					@#cursorNo)
	XgrRegisterCursor (@"Arrow",			@#defaultCursor)
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
	SHARED oldgroup, event
'
	oldgroup = 0
	event = 0
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
	SHARED  DemoButton,  DemoText,  DemoDialog,  DemoPullDown
	SHARED  DemoFile,  DemoFont,  DemoMiscellany
'
  IF LIBRARY(0) THEN RETURN
'
	wt = $$WindowTypeTitleBar
'
  DemoGUI (@DemoGUI, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoGUI, #SetCallback, DemoGUI, &DemoGUICode(), -1, -1, -1, 0)
  XuiSendMessage (DemoGUI, #Initialize, 0, 0, 0, 0, 0, 0)
  XuiSendMessage (DemoGUI, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
  DemoButton (@DemoButton, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoButton, #SetCallback, DemoButton, &DemoButtonCode(), -1, -1, -1, 0)
  XuiSendMessage (DemoButton, #Initialize, 0, 0, 0, 0, 0, 0)
'	XuiSendMessage (DemoButton, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
  DemoText (@DemoText, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoText, #SetCallback, DemoText, &DemoTextCode(), -1, -1, -1, 0)
  XuiSendMessage (DemoText, #Initialize, 0, 0, 0, 0, 0, 0)
'	XuiSendMessage (DemoText, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
  DemoDialog (@DemoDialog, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoDialog, #SetCallback, DemoDialog, &DemoDialogCode(), -1, -1, -1, 0)
  XuiSendMessage (DemoDialog, #Initialize, 0, 0, 0, 0, 0, 0)
'	XuiSendMessage (DemoDialog, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
  DemoPullDown (@DemoPullDown, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoPullDown, #SetCallback, DemoPullDown, &DemoPullDownCode(), -1, -1, -1, 0)
  XuiSendMessage (DemoPullDown, #Initialize, 0, 0, 0, 0, 0, 0)
'	XuiSendMessage (DemoPullDown, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
	XuiFile (@DemoFile, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoFile, #SetCallback, DemoFile, &DemoFileCode(), -1, -1, -1, 0)
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 0, @"DemoFile")
'	XuiSendMessage (DemoFile, #SetCallback, DemoFile, &DemoFile(), -1, -1, $File, DemoFile)
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 0, @"File")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 1, @"FileNameLabel")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 2, @"FileNameText")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 3, @"DirectoryLabel")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 4, @"FilesLabel")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 5, @"DirectoryBox")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 6, @"FileBox")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 7, @"EnterButton")
  XuiSendMessage (DemoFile, #SetGridName, 0, 0, 0, 0, 8, @"CancelButton")
  XuiSendMessage (DemoFile, #Initialize, 0, 0, 0, 0, 0, 0)
'	XuiSendMessage (DemoFile, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
	XuiFont (@DemoFont, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoFont, #SetCallback, DemoFont, &DemoFontCode(), -1, -1, -1, 0)
  XuiSendMessage (DemoFont, #SetGridName, 0, 0, 0, 0, 0, @"DemoFont")
  XuiSendMessage (DemoFont, #Initialize, 0, 0, 0, 0, 0, 0)
'	XuiSendMessage (DemoFont, #DisplayWindow, 0, 0, 0, 0, 0, 0)
'
  DemoMiscellany (@DemoMiscellany, #CreateWindow, 0, 0, 0, 0, wt, 0)
  XuiSendMessage (DemoMiscellany, #SetCallback, DemoMiscellany, &DemoMiscellanyCode(), -1, -1, -1, 0)
  XuiSendMessage (DemoMiscellany, #Initialize, 0, 0, 0, 0, 0, 0)
'	XuiSendMessage (DemoMiscellany, #DisplayWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ########################
' #####  DemoGUI ()  #####
' ########################
'
FUNCTION  DemoGUI (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
  STATIC  SUBADDR  sub[]
  STATIC  upperMessage
  STATIC  DemoGUI
'
  $DemoGUI         =  0  ' kid  0 grid type = DemoGUI
  $DoColor         =  1  ' kid  1 grid type = XuiCheckBox
  $DoLabel         =  2  ' kid  2 grid type = XuiCheckBox
  $DoCheckBox      =  3  ' kid  3 grid type = XuiCheckBox
  $DoRadioBox      =  4  ' kid  4 grid type = XuiCheckBox
  $DoPressButton   =  5  ' kid  5 grid type = XuiCheckBox
  $DoPushButton    =  6  ' kid  6 grid type = XuiCheckBox
  $DoToggleButton  =  7  ' kid  7 grid type = XuiCheckBox
  $DoRadioButton   =  8  ' kid  8 grid type = XuiCheckBox
  $DoScrollBarH    =  9  ' kid  9 grid type = XuiCheckBox
  $DoScrollBarV    = 10  ' kid 10 grid type = XuiCheckBox
  $DoTextLine      = 11  ' kid 11 grid type = XuiCheckBox
  $DoTextArea      = 12  ' kid 12 grid type = XuiCheckBox
  $DoMenu          = 13  ' kid 13 grid type = XuiCheckBox
  $DoMenuBar       = 14  ' kid 14 grid type = XuiCheckBox
  $DoPullDown      = 15  ' kid 15 grid type = XuiCheckBox
  $DoList          = 16  ' kid 16 grid type = XuiCheckBox
  $DoMessage1B     = 17  ' kid 17 grid type = XuiCheckBox
  $DoMessage2B     = 18  ' kid 18 grid type = XuiCheckBox
  $DoMessage3B     = 19  ' kid 19 grid type = XuiCheckBox
  $DoMessage4B     = 20  ' kid 20 grid type = XuiCheckBox
  $DoProgress      = 21  ' kid 21 grid type = XuiCheckBox
  $DoDialog2B      = 22  ' kid 22 grid type = XuiCheckBox
  $DoDialog3B      = 23  ' kid 23 grid type = XuiCheckBox
  $DoDialog4B      = 24  ' kid 24 grid type = XuiCheckBox
  $DoDropButton    = 25  ' kid 25 grid type = XuiCheckBox
  $DoDropBox       = 26  ' kid 26 grid type = XuiCheckBox
  $DoListButton    = 27  ' kid 27 grid type = XuiCheckBox
  $DoListBox       = 28  ' kid 28 grid type = XuiCheckBox
  $DoRange         = 29  ' kid 29 grid type = XuiCheckBox
  $DoFile          = 30  ' kid 30 grid type = XuiCheckBox
  $DoFont          = 31  ' kid 31 grid type = XuiCheckBox
  $DoListDialog2B  = 32  ' kid 32 grid type = XuiCheckBox
  $DoQuit          = 33  ' kid 33 grid type = XuiPressButton
  $UpperKid        = 33  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
' XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, DemoGUI) THEN RETURN
  IF (message <= upperMessage) THEN GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
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
  XuiCreateGrid (@grid, DemoGUI, @v0, @v1, @v2, @v3, r0, r1, &DemoGUI())
  XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"DemoGUI")
  XuiCheckBox    (@g, #Create, 4, 4, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoColor, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoColor")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Color")
  XuiCheckBox    (@g, #Create, 128, 4, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoLabel, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoLabel")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Label")
  XuiCheckBox    (@g, #Create, 252, 4, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoCheckBox, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoCheckBox")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"CheckBox")
  XuiCheckBox    (@g, #Create, 376, 4, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoRadioBox, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoRadioBox")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioBox")
  XuiCheckBox    (@g, #Create, 4, 20, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoPressButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoPressButton")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PressButton")
  XuiCheckBox    (@g, #Create, 128, 20, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoPushButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoPushButton")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PushButton")
  XuiCheckBox    (@g, #Create, 252, 20, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoToggleButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoToggleButton")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ToggleButton")
  XuiCheckBox    (@g, #Create, 376, 20, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoRadioButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoRadioButton")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioButton")
  XuiCheckBox    (@g, #Create, 4, 36, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoScrollBarH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoScrollBarH")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ScrollBarH")
  XuiCheckBox    (@g, #Create, 128, 36, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoScrollBarV, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoScrollBarV")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ScrollBarV")
  XuiCheckBox    (@g, #Create, 252, 36, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoTextLine, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoTextLine")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"TextLine")
  XuiCheckBox    (@g, #Create, 376, 36, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoTextArea, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoTextArea")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"TextArea")
  XuiCheckBox    (@g, #Create, 4, 52, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoMenu, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoMenu")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Menu")
  XuiCheckBox    (@g, #Create, 128, 52, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoMenuBar, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoMenuBar")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"MenuBar")
  XuiCheckBox    (@g, #Create, 252, 52, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoPullDown, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoPullDown")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PullDown")
  XuiCheckBox    (@g, #Create, 376, 52, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoList, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoList")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"List")
  XuiCheckBox    (@g, #Create, 4, 68, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoMessage1B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoMessage1B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message1B")
  XuiCheckBox    (@g, #Create, 128, 68, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoMessage2B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoMessage2B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message2B")
  XuiCheckBox    (@g, #Create, 252, 68, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoMessage3B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoMessage3B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message3B")
  XuiCheckBox    (@g, #Create, 376, 68, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoMessage4B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoMessage4B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message4B")
  XuiCheckBox    (@g, #Create, 4, 84, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoProgress, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoProgress")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Progress")
  XuiCheckBox    (@g, #Create, 128, 84, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoDialog2B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoDialog2B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Dialog2B")
  XuiCheckBox    (@g, #Create, 252, 84, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoDialog3B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoDialog3B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Dialog3B")
  XuiCheckBox    (@g, #Create, 376, 84, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoDialog4B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoDialog4B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Dialog4B")
  XuiCheckBox    (@g, #Create, 4, 100, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoDropButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoDropButton")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"DropButton")
  XuiCheckBox    (@g, #Create, 128, 100, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoDropBox, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoDropBox")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"DropBox")
  XuiCheckBox    (@g, #Create, 252, 100, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoListButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoListButton")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ListButton")
  XuiCheckBox    (@g, #Create, 376, 100, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoListBox, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoListBox")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ListBox")
  XuiCheckBox    (@g, #Create, 4, 116, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoRange, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoRange")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Range")
  XuiCheckBox    (@g, #Create, 128, 116, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoFile, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoFile")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"File")
  XuiCheckBox    (@g, #Create, 252, 116, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoFont, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoFont")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Font")
  XuiCheckBox    (@g, #Create, 376, 116, 124, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoListDialog2B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoListDialog2B")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderRaise1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ListDialog2B")
  XuiPressButton (@g, #Create, 4, 132, 496, 16, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoGUI(), -1, -1, $DoQuit, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DoQuit")
  XuiSendMessage ( g, #SetBorder, $$BorderLoLine1, $$BorderLoLine1, $$BorderLower1, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Quit")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"DemoGUI")
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
' sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
  sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
  sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
' sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
' sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
  sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
  IF sub[0] THEN PRINT "DemoGUI(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "DemoGUI(): Initialize: Error::: (Undefined Message)"
  XuiRegisterGridType (@DemoGUI, "DemoGUI", &DemoGUI(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
  designX = 516
  designY = 23
  designWidth = 504
  designHeight = 152
'
  gridType = DemoGUI
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"maxWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"maxHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback)
  XuiSetGridTypeValue (gridType, @"focusKid",         $DoColor)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
' ############################
' #####  DemoGUICode ()  #####
' ############################
'
FUNCTION  DemoGUICode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED oldgroup
	STATIC oldwindow
	SHARED DemoButton, DemoText, DemoDialog
	SHARED DemoPullDown, DemoFile, DemoFont, DemoMiscellany
'
  $DemoGUI         =  0  ' kid  0 grid type = DemoGUI
  $DoColor         =  1  ' kid  1 grid type = XuiCheckBox
  $DoLabel         =  2  ' kid  2 grid type = XuiCheckBox
  $DoCheckBox      =  3  ' kid  3 grid type = XuiCheckBox
  $DoRadioBox      =  4  ' kid  4 grid type = XuiCheckBox
  $DoPressButton   =  5  ' kid  5 grid type = XuiCheckBox
  $DoPushButton    =  6  ' kid  6 grid type = XuiCheckBox
  $DoToggleButton  =  7  ' kid  7 grid type = XuiCheckBox
  $DoRadioButton   =  8  ' kid  8 grid type = XuiCheckBox
  $DoScrollBarH    =  9  ' kid  9 grid type = XuiCheckBox
  $DoScrollBarV    = 10  ' kid 10 grid type = XuiCheckBox
  $DoTextLine      = 11  ' kid 11 grid type = XuiCheckBox
  $DoTextArea      = 12  ' kid 12 grid type = XuiCheckBox
  $DoMenu          = 13  ' kid 13 grid type = XuiCheckBox
  $DoMenuBar       = 14  ' kid 14 grid type = XuiCheckBox
  $DoPullDown      = 15  ' kid 15 grid type = XuiCheckBox
  $DoList          = 16  ' kid 16 grid type = XuiCheckBox
  $DoMessage1B     = 17  ' kid 17 grid type = XuiCheckBox
  $DoMessage2B     = 18  ' kid 18 grid type = XuiCheckBox
  $DoMessage3B     = 19  ' kid 19 grid type = XuiCheckBox
  $DoMessage4B     = 20  ' kid 20 grid type = XuiCheckBox
  $DoProgress      = 21  ' kid 21 grid type = XuiCheckBox
  $DoDialog2B      = 22  ' kid 22 grid type = XuiCheckBox
  $DoDialog3B      = 23  ' kid 23 grid type = XuiCheckBox
  $DoDialog4B      = 24  ' kid 24 grid type = XuiCheckBox
  $DoDropButton    = 25  ' kid 25 grid type = XuiCheckBox
  $DoDropBox       = 26  ' kid 26 grid type = XuiCheckBox
  $DoListButton    = 27  ' kid 27 grid type = XuiCheckBox
  $DoListBox       = 28  ' kid 28 grid type = XuiCheckBox
  $DoRange         = 29  ' kid 29 grid type = XuiCheckBox
  $DoFile          = 30  ' kid 30 grid type = XuiCheckBox
  $DoFont          = 31  ' kid 31 grid type = XuiCheckBox
  $DoListDialog2B  = 32  ' kid 32 grid type = XuiCheckBox
  $DoQuit          = 33  ' kid 33 grid type = XuiPressButton
  $UpperKid        = 33  ' kid maximum
'
'  XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
  SELECT CASE message
    CASE #Selection: GOSUB Selection   ' Common callback message
'   CASE #TextEvent: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
  END SELECT
  RETURN
'
'
' *****  Selection  *****
'
SUB Selection
  IF kid = $DemoGUI THEN EXIT SUB
  IF kid = $DoQuit THEN QUIT(0)
  map$ = "60000000111133312222622233336452"
  group = map${kid - 1}
  IF (group = 'x') THEN
    XuiMessage("Demo Not Implemented")
    i = kid : a = 0 : GOSUB Push
    EXIT SUB
  END IF
  IF v0 = 0 THEN i = kid : a = -1 : GOSUB Push : EXIT SUB
  FOR i = 1 TO 32
    IF map${i - 1} = oldgroup THEN a = 0: GOSUB Push
    IF map${i - 1} = group THEN a = -1: GOSUB Push
  NEXT i
  IF oldgroup THEN XuiSendMessage (oldwindow, #HideWindow, 0,0,0,0,0,0)
  oldgroup = group
  SELECT CASE group
    CASE '0': oldwindow = DemoButton
    CASE '1': oldwindow = DemoText
		CASE '2': oldwindow = DemoDialog
		CASE '3': oldwindow = DemoPullDown
		CASE '4': oldwindow = DemoFile
		CASE '5': oldwindow = DemoFont
		CASE '6': oldwindow = DemoMiscellany
  END SELECT
  XuiSendMessage (oldwindow, #ShowWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
SUB Push
  XuiSendMessage (grid, #SetValue, a, 0, 0, 0, i, 0)
  XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, i, 0)
END SUB
END FUNCTION
'
'
' ###########################
' #####  DemoButton ()  #####
' ###########################
'
FUNCTION  DemoButton (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
  STATIC  SUBADDR  sub[]
  STATIC  upperMessage
  STATIC  DemoButton
'
  $DemoButton     =  0  ' kid  0 grid type = DemoButton
  $Label0         =  1  ' kid  1 grid type = XuiLabel
  $Label1         =  2  ' kid  2 grid type = XuiLabel
  $Label2         =  3  ' kid  3 grid type = XuiLabel
  $CheckBox0      =  4  ' kid  4 grid type = XuiCheckBox
  $CheckBox1      =  5  ' kid  5 grid type = XuiCheckBox
  $CheckBox2      =  6  ' kid  6 grid type = XuiCheckBox
  $RadioBox0      =  7  ' kid  7 grid type = XuiRadioBox
  $RadioBox1      =  8  ' kid  8 grid type = XuiRadioBox
  $RadioBox2      =  9  ' kid  9 grid type = XuiRadioBox
  $PressButton0   = 10  ' kid 10 grid type = XuiPressButton
  $PressButton1   = 11  ' kid 11 grid type = XuiPressButton
  $PressButton2   = 12  ' kid 12 grid type = XuiPressButton
  $PushButton0    = 13  ' kid 13 grid type = XuiPushButton
  $PushButton1    = 14  ' kid 14 grid type = XuiPushButton
  $PushButton2    = 15  ' kid 15 grid type = XuiPushButton
  $ToggleButton0  = 16  ' kid 16 grid type = XuiToggleButton
  $ToggleButton1  = 17  ' kid 17 grid type = XuiToggleButton
  $ToggleButton2  = 18  ' kid 18 grid type = XuiToggleButton
  $RadioButton0   = 19  ' kid 19 grid type = XuiRadioButton
  $RadioButton1   = 20  ' kid 20 grid type = XuiRadioButton
  $RadioButton2   = 21  ' kid 21 grid type = XuiRadioButton
  $UpperKid       = 21  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
' XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, DemoButton) THEN RETURN
  IF (message <= upperMessage) THEN GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
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
  XuiCreateGrid (@grid, DemoButton, @v0, @v1, @v2, @v3, r0, r1, &DemoButton())
  XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"DemoButton")
  XuiLabel       (@g, #Create, 4, 4, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Label0")
  XuiLabel       (@g, #Create, 120, 4, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Label1")
  XuiLabel       (@g, #Create, 236, 4, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Label2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Label2")
  XuiCheckBox    (@g, #Create, 4, 24, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $CheckBox0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CheckBox0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"CheckBox0")
  XuiCheckBox    (@g, #Create, 120, 24, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $CheckBox1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CheckBox1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"CheckBox1")
  XuiCheckBox    (@g, #Create, 236, 24, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $CheckBox2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CheckBox2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"CheckBox2")
  XuiRadioBox    (@g, #Create, 4, 44, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $RadioBox0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"RadioBox0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioBox0")
  XuiRadioBox    (@g, #Create, 120, 44, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $RadioBox1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"RadioBox1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioBox1")
  XuiRadioBox    (@g, #Create, 236, 44, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $RadioBox2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"RadioBox2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioBox2")
  XuiPressButton (@g, #Create, 4, 64, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $PressButton0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PressButton0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PressButton0")
  XuiPressButton (@g, #Create, 120, 64, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $PressButton1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PressButton1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PressButton1")
  XuiPressButton (@g, #Create, 236, 64, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $PressButton2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PressButton2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PressButton2")
  XuiPushButton  (@g, #Create, 4, 84, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $PushButton0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PushButton0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PushButton0")
	XuiSendMessage ( g, #SetFocusColor, $$BrightGreen, -1, -1, -1, 0, 0)
  XuiPushButton  (@g, #Create, 120, 84, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $PushButton1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PushButton1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PushButton1")
	XuiSendMessage ( g, #SetFocusColor, $$BrightCyan, -1, -1, -1, 0, 0)
  XuiPushButton  (@g, #Create, 236, 84, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $PushButton2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PushButton2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"PushButton2")
	XuiSendMessage ( g, #SetFocusColor, $$BrightMagenta, -1, -1, -1, 0, 0)
  XuiToggleButton (@g, #Create, 4, 104, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $ToggleButton0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ToggleButton0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ToggleButton0")
  XuiToggleButton (@g, #Create, 120, 104, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $ToggleButton1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ToggleButton1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ToggleButton1")
  XuiToggleButton (@g, #Create, 236, 104, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $ToggleButton2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ToggleButton2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ToggleButton2")
  XuiRadioButton (@g, #Create, 4, 124, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $RadioButton0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"RadioButton0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioButton0")
  XuiRadioButton (@g, #Create, 120, 124, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $RadioButton1, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"RadioButton1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioButton1")
  XuiRadioButton (@g, #Create, 236, 124, 116, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoButton(), -1, -1, $RadioButton2, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"RadioButton2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"RadioButton2")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"DemoButton")
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
' sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
  sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
  sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
' sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
' sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
  sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
  IF sub[0] THEN PRINT "DemoButton(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "DemoButton(): Initialize: Error::: (Undefined Message)"
  XuiRegisterGridType (@DemoButton, "DemoButton", &DemoButton(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
  designX = 206
  designY = 248
  designWidth = 356
  designHeight = 148
'
  gridType = DemoButton
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"maxWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"maxHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback)
  XuiSetGridTypeValue (gridType, @"focusKid",         $CheckBox0)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###############################
' #####  DemoButtonCode ()  #####
' ###############################
'
FUNCTION  DemoButtonCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED event
'
  $DemoButton     =  0  ' kid  0 grid type = DemoButton
  $Label0         =  1  ' kid  1 grid type = XuiLabel
  $Label1         =  2  ' kid  2 grid type = XuiLabel
  $Label2         =  3  ' kid  3 grid type = XuiLabel
  $CheckBox0      =  4  ' kid  4 grid type = XuiCheckBox
  $CheckBox1      =  5  ' kid  5 grid type = XuiCheckBox
  $CheckBox2      =  6  ' kid  6 grid type = XuiCheckBox
  $RadioBox0      =  7  ' kid  7 grid type = XuiRadioBox
  $RadioBox1      =  8  ' kid  8 grid type = XuiRadioBox
  $RadioBox2      =  9  ' kid  9 grid type = XuiRadioBox
  $PressButton0   = 10  ' kid 10 grid type = XuiPressButton
  $PressButton1   = 11  ' kid 11 grid type = XuiPressButton
  $PressButton2   = 12  ' kid 12 grid type = XuiPressButton
  $PushButton0    = 13  ' kid 13 grid type = XuiPushButton
  $PushButton1    = 14  ' kid 14 grid type = XuiPushButton
  $PushButton2    = 15  ' kid 15 grid type = XuiPushButton
  $ToggleButton0  = 16  ' kid 16 grid type = XuiToggleButton
  $ToggleButton1  = 17  ' kid 17 grid type = XuiToggleButton
  $ToggleButton2  = 18  ' kid 18 grid type = XuiToggleButton
  $RadioButton0   = 19  ' kid 19 grid type = XuiRadioButton
  $RadioButton1   = 20  ' kid 20 grid type = XuiRadioButton
  $RadioButton2   = 21  ' kid 21 grid type = XuiRadioButton
  $UpperKid       = 21  ' kid maximum
'
'	XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
	IF (message = #Callback) THEN message = r1
'
	XuiSendMessage (grid, #GetGridName, 0, 0, 0, 0, kid, @name$)
	XgrMessageNumberToName (message, @message$)
'
  SELECT CASE message
    CASE #Selection		:	GOSUB Selection   ' Common callback message
  END SELECT
  RETURN
'
'
' *****  Selection  *****
'
SUB Selection
  IF kid = $DemoButton THEN EXIT SUB
	SELECT CASE TRUE
		CASE (kid < $PressButton0)	: PRINT event, name$, message$, v0
		CASE (kid < $PushButton0)		: PRINT event, name$, message$
		CASE (kid < $ToggleButton0)	: PRINT event, name$, message$, "  !!! #SetFocusColors in DemoButton() !!!"
		CASE ELSE										: PRINT event, name$, message$, v0
	END SELECT
	INC event
END SUB
END FUNCTION
'
'
' #########################
' #####  DemoText ()  #####
' #########################
'
FUNCTION  DemoText (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
  STATIC  SUBADDR  sub[]
  STATIC  upperMessage
  STATIC  DemoText
'
  $DemoText    =  0  ' kid  0 grid type = DemoText
  $TextLine    =  1  ' kid  1 grid type = XuiTextLine
  $ScrollBarH  =  2  ' kid  2 grid type = XuiScrollBarH
  $ScrollBarV  =  3  ' kid  3 grid type = XuiScrollBarV
  $List        =  4  ' kid  4 grid type = XuiList
  $TextArea    =  5  ' kid  5 grid type = XuiTextArea
  $UpperKid    =  5  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
' XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, DemoText) THEN RETURN
  IF (message <= upperMessage) THEN GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
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
  XuiCreateGrid (@grid, DemoText, @v0, @v1, @v2, @v3, r0, r1, &DemoText())
  XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"DemoText")
  XuiTextLine    (@g, #Create, 12, 168, 172, 28, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoText(), -1, -1, $TextLine, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextLine")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"TextLine")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"Coordinate830")
  XuiScrollBarH  (@g, #Create, 40, 36, 104, 12, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoText(), -1, -1, $ScrollBarH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ScrollBarH")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ScrollBarH")
  XuiScrollBarV  (@g, #Create, 12, 36, 12, 120, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoText(), -1, -1, $ScrollBarV, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ScrollBarV")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ScrollBarV")
  XuiList        (@g, #Create, 384, 36, 184, 160, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoText(), -1, -1, $List, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"List")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"List")
  DIM text$[12]
  text$[ 0] = "This is a \"List\"."
  text$[ 1] = "No user input."
  text$[ 2] = "Select line using "
  text$[ 3] = "mouse or RETURN key."
  text$[ 4] = "In this demo, line"
  text$[ 5] = "copied to TextLine."
  text$[ 6] = "(Select there to"
  text$[ 7] = "copy to TextArea.)"
  text$[ 8] = "Initial text entered"
  text$[ 9] = "same as in TextArea."
  text$[10] = "Of course, the same scrolling"
  text$[11] = "facilities are available"
  text$[12] = "as with the TextArea."
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"ListUp")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"ListDown")
  XuiTextArea    (@g, #Create, 192, 36, 184, 160, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoText(), -1, -1, $TextArea, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TextArea")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"TextArea")
  DIM text$[13]
  text$[ 0] = "This is a \"TextArea\". "
  text$[ 1] = "User may edit.  ESC "
  text$[ 2] = "key causes selection"
  text$[ 3] = "event.  In this demo,"
  text$[ 4] = "text will be copied"
  text$[ 5] = "to ListArea.  This"
  text$[ 6] = "initial text was"
  text$[ 7] = "entered using"
  text$[ 8] = "AppearanceTextArray"
  text$[ 9] = "under Text$[] button"
  text$[10] = "in Appearance window.  The text may"
  text$[11] = "extend beyond the physical"
  text$[12] = "limits of the window and scrolled"
  text$[13] = "into view using the scroll bars."
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"TextAreaUp")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"TextAreaDown")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"DemoText")
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
' sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
  sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
  sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
' sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
' sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
  sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
  IF sub[0] THEN PRINT "DemoText(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "DemoText(): Initialize: Error::: (Undefined Message)"
  XuiRegisterGridType (@DemoText, "DemoText", &DemoText(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
  designX = 44
  designY = 218
  designWidth = 580
  designHeight = 228
'
  gridType = DemoText
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"maxWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"maxHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$InputTextString OR $$TextSelection)
  XuiSetGridTypeValue (gridType, @"focusKid",         $TextLine)
  XuiSetGridTypeValue (gridType, @"inputTextArray",   $TextArea)
  XuiSetGridTypeValue (gridType, @"inputTextString",  $TextLine)
  IFZ message THEN RETURN
END SUB
END FUNCTION

'
'
' #############################
' #####  DemoTextCode ()  #####
' #############################
'
FUNCTION  DemoTextCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED event
'
  $DemoText    =  0  ' kid  0 grid type = DemoText
  $TextLine    =  1  ' kid  1 grid type = XuiTextLine
  $ScrollBarH  =  2  ' kid  2 grid type = XuiScrollBarH
  $ScrollBarV  =  3  ' kid  3 grid type = XuiScrollBarV
  $List        =  4  ' kid  4 grid type = XuiList
  $TextArea    =  5  ' kid  5 grid type = XuiTextArea
  $UpperKid    =  5  ' kid maximum
'
'  XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
  XuiSendMessage (grid, #GetGridName, 0, 0, 0, 0, kid, @name$)
  XgrMessageNumberToName (message, @message$)
'
  SELECT CASE message
    CASE #Initialize	: GOSUB Initialize
    CASE #Selection		: GOSUB Selection   ' Common callback message
		CASE #Change			: GOSUB Scroll
		CASE #MuchLess		: GOSUB Scroll
		CASE #MuchMore		: GOSUB Scroll
		CASE #OneLess			: GOSUB Scroll
		CASE #OneMore			: GOSUB Scroll
		CASE #SomeLess		: GOSUB Scroll
		CASE #SomeMore		: GOSUB Scroll
    CASE #TextEvent		: GOSUB TextEvent		' KeyDown in TextArea/TextLine
  END SELECT
  RETURN
'
'
'
SUB Initialize
  XuiSendMessage(grid, #SetPosition, 0, 1, 2, 4, $ScrollBarH, 0)
  XuiSendMessage(grid, #SetPosition, 0, 1, 2, 4, $ScrollBarV, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
  SELECT CASE kid
    CASE $DemoText    : EXIT SUB
    CASE $TextLine    :
			XuiSendMessage(grid, #GetTextString, 0, 0, 0, 0, kid, @text$)
			REDIM text$[9]
			FOR i = 0 TO 9
				text$[i] = CHR$(i + '0') + text$
			NEXT i
			XuiSendMessage(grid, #SetTextArray, 0, 0, 0, 0, $TextArea, @text$[])
			XuiSendMessage(grid, #Redraw, 0, 0, 0, 0, $TextArea, 0)
    CASE $List        :
			XuiSendMessage(grid, #GetTextArray, 0, 0, 0, 0, kid, @text$[])
			IF v0 = -1 THEN text$ = "User pressed ESC!" ELSE text$ = text$[v0]
			XuiSendMessage(grid, #SetTextString, 0, 0, 0, 0, $TextLine, @text$)
			XuiSendMessage(grid, #Redraw, 0, 0, 0, 0, $TextLine, 0)
    CASE $TextArea    :
			XuiSendMessage(grid, #GetTextArray, 0, 0, 0, 0, kid, @text$[])
			XuiSendMessage(grid, #SetTextArray, 0, 0, 0, 0, $List, @text$[])
			XuiSendMessage(grid, #Redraw, 0, 0, 0, 0, $List, 0)
  END SELECT
  IF kid = $List THEN
		PRINT event, name$, message$, v0: INC event
  ELSE
		PRINT event, name$, message$: INC event
  END IF
END SUB
'
SUB Scroll
  IF message = #Change THEN
		PRINT event, name$, message$, v0, v1, v2, v3 : INC event
  ELSE
		PRINT event, name$, message$ : INC event
  END IF
END SUB
'
SUB TextEvent
  PRINT event, name$, message$ : INC event
END SUB
END FUNCTION
'
'
' ###########################
' #####  DemoDialog ()  #####
' ###########################
'
FUNCTION  DemoDialog (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
  STATIC  SUBADDR  sub[]
  STATIC  upperMessage
  STATIC  DemoDialog
'
  $DemoDialog    =  0  ' kid  0 grid type = DemoDialog
  $Message1B     =  1  ' kid  1 grid type = XuiMessage1B
  $Message2B     =  2  ' kid  2 grid type = XuiMessage2B
  $Message3B     =  3  ' kid  3 grid type = XuiMessage3B
  $ListDialog2B  =  4  ' kid  4 grid type = XuiListDialog2B
  $Dialog2B      =  5  ' kid  5 grid type = XuiDialog2B
  $Dialog3B      =  6  ' kid  6 grid type = XuiDialog3B
  $Message4B     =  7  ' kid  7 grid type = XuiMessage4B
  $Dialog4B      =  8  ' kid  8 grid type = XuiDialog4B
  $UpperKid      =  8  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
' XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, DemoDialog) THEN RETURN
  IF (message <= upperMessage) THEN GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
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
  XuiCreateGrid (@grid, DemoDialog, @v0, @v1, @v2, @v3, r0, r1, &DemoDialog())
  XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"DemoDialog")
  XuiMessage1B   (@g, #Create, 92, 8, 80, 48, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $Message1B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Message1B")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message1B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"M1Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"M1Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"M1B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"M1B0")
  XuiMessage2B   (@g, #Create, 176, 8, 160, 48, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $Message2B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Message2B")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message2B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"M2Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"M2Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"M2B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"M2B0")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"M2B1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 3, @"M2B1")
  XuiMessage3B   (@g, #Create, 340, 8, 240, 48, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $Message3B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Message3B")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message3B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"M3Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"M3Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"M3B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"M3B0")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"M3B1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 3, @"M3B1")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 4, @"M3B2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 4, @"M3B2")
  XuiListDialog2B (@g, #Create, 8, 60, 164, 212, r0, grid)                             '*cw* 130731-+
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $ListDialog2B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ListDialog2B")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ListDialog2B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"L2Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"L2Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"L2List")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"L2List")
  DIM text$[7]
  text$[0] = "ListDialog2B has"
  text$[1] = "a \"List\".  In this"
  text$[2] = "demo, selected"
  text$[3] = "text will be sent"
  text$[4] = "\"around the horn\","
  text$[5] = "L2-D2-D3-D4 and"
  text$[6] = "back.  Initial text loaded via"
  text$[7] = "AppearanceTextArray."
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 2, @text$[])
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"L2TextLine")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 3, @"L2TextLine")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 4, @"L2B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 4, @" L2B0 ")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 5, @"L2B1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 5, @" L2B1 ")
  XuiDialog2B    (@g, #Create, 176, 60, 160, 68, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $Dialog2B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Dialog2B")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Dialog2B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"D2Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"D2Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"D2TextLine")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"D2TextLine")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"D2B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 3, @"D2B0")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 4, @"D2B1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 4, @"D2B1")
  XuiDialog3B    (@g, #Create, 340, 60, 240, 68, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $Dialog3B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Dialog3B")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Dialog3B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"D3Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"D3Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"D3TextLine")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"D3TextLine")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"D3B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 3, @"D3B0")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 4, @"D3B1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 4, @"D3B1")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 5, @"D3B2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 5, @"D3B2")
  XuiMessage4B   (@g, #Create, 260, 132, 320, 48, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $Message4B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Message4B")
  XuiSendMessage ( g, #SetBorder, $$BorderFlat4, $$BorderFlat4, $$BorderFlat4, -1, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Message4B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"M4Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"M4Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"M4B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"M4B0")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"M4B1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 3, @"M4B1")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 4, @"M4B2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 4, @"M4B2")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 5, @"M4B3")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 5, @"M4B3")
  XuiDialog4B    (@g, #Create, 260, 184, 320, 68, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoDialog(), -1, -1, $Dialog4B, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Dialog4B")
  XuiSendMessage ( g, #SetBorder, $$BorderFlat4, $$BorderFlat4, $$BorderFlat4, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureRaise1, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Dialog4B")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"D4Label")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"D4Label")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"D4TextLine")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 2, @"D4TextLine")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"D4B0")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 3, @"D4B0")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 4, @"D4B1")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 4, @"D4B1")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 5, @"D4B2")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 5, @"D4B2")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 6, @"D4B3")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 6, @"D4B3")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"DemoDialog")
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
' sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
  sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
  sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
' sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
' sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
  sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
  IF sub[0] THEN PRINT "DemoDialog(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "DemoDialog(): Initialize: Error::: (Undefined Message)"
  XuiRegisterGridType (@DemoDialog, "DemoDialog", &DemoDialog(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
  designX = 29
  designY = 212
  designWidth = 588
'  designHeight = 256  '*cw* 130731-
  designHeight = 280   '*cw* 130731+
'
  gridType = DemoDialog
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"maxWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"maxHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$TextSelection)
  XuiSetGridTypeValue (gridType, @"focusKid",         $Message1B)
  XuiSetGridTypeValue (gridType, @"inputTextString",  $ListDialog2B)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###############################
' #####  DemoDialogCode ()  #####
' ###############################
'
FUNCTION  DemoDialogCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED event
'
  $DemoDialog    =  0  ' kid  0 grid type = DemoDialog
  $Message1B     =  1  ' kid  1 grid type = XuiMessage1B
  $Message2B     =  2  ' kid  2 grid type = XuiMessage2B
  $Message3B     =  3  ' kid  3 grid type = XuiMessage3B
  $ListDialog2B  =  4  ' kid  4 grid type = XuiListDialog2B
  $Dialog2B      =  5  ' kid  5 grid type = XuiDialog2B
  $Dialog3B      =  6  ' kid  6 grid type = XuiDialog3B
  $Message4B     =  7  ' kid  7 grid type = XuiMessage4B
  $Dialog4B      =  8  ' kid  8 grid type = XuiDialog4B
  $UpperKid      =  8  ' kid maximum
'
'  XuiReportMessage(grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
  XuiCallback(@ccgrid, #GetCallbackArgs, @x, @x, @x, @x, @x, @x)
  XuiSendMessage(grid, #GetKidArray, @x, @x, 0, 0, kid, @cgrid[])
  ckid = 0: DO WHILE cgrid[ckid] <> ccgrid: INC ckid: LOOP
  XuiSendMessage(ccgrid, #GetGridName, 0, 0, 0, 0, 0, @name$)
  XgrMessageNumberToName(message, @message$)
  SELECT CASE message
    CASE #Selection: GOSUB Selection   ' Common callback message
    CASE #TextEvent: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
  END SELECT
  RETURN
'
'
' *****  Selection  *****
'
SUB Selection
	tkid = kid: tckid = 2
  SELECT CASE kid
    CASE $DemoDialog    : EXIT SUB
    CASE $ListDialog2B  :
			IF ckid = 2 THEN tckid= 3
			IF ckid = 3 THEN tkid = $Dialog2B
    CASE $Dialog2B      : IF ckid = 2 THEN tkid = $Dialog3B
    CASE $Dialog3B      : IF ckid = 2 THEN tkid = $Dialog4B
    CASE $Dialog4B      : IF ckid = 2 THEN tkid = $ListDialog2B
  END SELECT
	IF kid = $ListDialog2B && ckid = 2 THEN
		PRINT event, name$, message$, v0: INC event
	ELSE
		PRINT event, name$, message$: INC event
	END IF
	IF tkid = kid && tckid = 2 THEN EXIT SUB
	IF kid = $ListDialog2B && ckid = 2 THEN
		XuiSendMessage(cgrid[0], #GetTextArray, 0, 0, 0, 0, ckid, @text$[])
		IF v0 = -1 THEN text$ = "User pressed ESC!" ELSE text$ = text$[v0]
	ELSE
		XuiSendMessage(cgrid[0], #GetTextString, 0, 0, 0, 0, ckid, @text$)
	END IF
  XuiSendMessage(grid, #GetGridNumber, @tcgrid, @x, @x, @x, tkid, @x)
 	IF tkid = $ListDialog2B && tckid = 2 THEN
		DIM text$[9]
		FOR i = 0 TO 9
			text$[i] = CHR$(i + '0') + text$
		NEXT i
		XuiSendMessage(tcgrid, #SetTextArray, 0, 0, 0, 0, tckid, @text$[])
	ELSE
		XuiSendMessage(tcgrid, #SetTextString, 0, 0, 0, 0, tckid, @text$)
	END IF
 	XuiSendMessage(tcgrid,  #Redraw, 0, 0, 0, 0, tckid, 0)
END SUB
SUB TextEvent
  PRINT event, name$, message$: INC event
END SUB
END FUNCTION
'
'
' #############################
' #####  DemoPullDown ()  #####
' #############################
'
FUNCTION  DemoPullDown (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
  STATIC  SUBADDR  sub[]
  STATIC  upperMessage
  STATIC  DemoPullDown
'
  $DemoPullDown   =  0  ' kid  0 grid type = DemoPullDown
  $Menu           =  1  ' kid  1 grid type = XuiMenu
  $MenuBar        =  2  ' kid  2 grid type = XuiMenuBar
  $DropButton     =  3  ' kid  3 grid type = XuiDropButton
  $DropBox        =  4  ' kid  4 grid type = XuiDropBox
  $ListButton     =  5  ' kid  5 grid type = XuiListButton
  $ListBox        =  6  ' kid  6 grid type = XuiListBox
  $PullDownLabel  =  7  ' kid  7 grid type = XuiLabel
  $UpperKid       =  7  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
' XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, DemoPullDown) THEN RETURN
  IF (message <= upperMessage) THEN GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
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
  XuiCreateGrid (@grid, DemoPullDown, @v0, @v1, @v2, @v3, r0, r1, &DemoPullDown())
  XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"DemoPullDown")
  XuiMenu        (@g, #Create, 4, 4, 280, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoPullDown(), -1, -1, $Menu, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Menu")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Menu")
  DIM text$[11]
  text$[ 0] = "Menu_A"
  text$[ 1] = " MenuA_a"
	text$[ 2] = " MenuA_b"
	text$[ 3] = " MenuA_c"
	text$[ 4] = "Menu_B"
  text$[ 5] = " MenuB_a"
	text$[ 6] = " MenuB_b"
	text$[ 7] = " MenuB_c"
	text$[ 8] = "Menu_C"
  text$[ 9] = " MenuC_a"
	text$[10] = " MenuC_b"
	text$[11] = " MenuC_c"
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"MMenuBar")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"Menu_A  Menu_B  Menu_C")
  XuiMenuBar     (@g, #Create, 4, 24, 280, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoPullDown(), -1, -1, $MenuBar, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"MenuBar")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"MenuBar_X  MenuBar_Y  MenuBar_Z")
  XuiDropButton  (@g, #Create, 4, 44, 280, 24, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoPullDown(), -1, -1, $DropButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DropButton")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"DropButton")
  DIM text$[4]
  text$[0] = "0DropButton"
  text$[1] = "1DropButton"
  text$[2] = "2DropButton"
  text$[3] = "3DropButton"
  text$[4] = "4DropButton"
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiDropBox     (@g, #Create, 4, 68, 280, 24, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoPullDown(), -1, -1, $DropBox, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"DropBox")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"DBoxTextLine")
  DIM text$[4]
  text$[0] = "0DropBox"
  text$[1] = "1DropBox"
  text$[2] = "2DropBox"
  text$[3] = "3DropBox"
  text$[4] = "4DropBox"
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"DBoxTextLine")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"DBoxTextLine")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"DBoxButton")
  XuiListButton  (@g, #Create, 4, 92, 280, 24, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoPullDown(), -1, -1, $ListButton, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ListButton")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ListButton")
  DIM text$[4]
  text$[0] = "0ListButton"
  text$[1] = "1ListButton"
  text$[2] = "2ListButton"
  text$[3] = "3ListButton"
  text$[4] = "4ListButton"
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiListBox     (@g, #Create, 4, 116, 280, 24, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoPullDown(), -1, -1, $ListBox, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ListBox")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"LBoxTextLine")
  DIM text$[4]
  text$[0] = "0ListBox"
  text$[1] = "1ListBox"
  text$[2] = "2ListBox"
  text$[3] = "3ListBox"
  text$[4] = "4ListBox"
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"LBoxTextLine")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"LBoxTextLine")
  DIM text$[2]
  text$[0] = "List"
  text$[1] = "Box"
  text$[2] = "TextLine"
  XuiSendMessage ( g, #SetTextArray, 0, 0, 0, 0, 1, @text$[])
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"LBoxButton")
  XuiLabel       (@g, #Create, 4, 140, 280, 24, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PullDownLabel")
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"(This Label shows selected text)")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"DemoPullDown")
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
' sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
  sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
  sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
' sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
' sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
  sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
  IF sub[0] THEN PRINT "DemoPullDown(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "DemoPullDown(): Initialize: Error::: (Undefined Message)"
  XuiRegisterGridType (@DemoPullDown, "DemoPullDown", &DemoPullDown(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
  designX = 254
  designY = 222
  designWidth = 288
  designHeight = 168
'
  gridType = DemoPullDown
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"maxWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"maxHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$TextSelection)
  XuiSetGridTypeValue (gridType, @"focusKid",         $DropButton)
  XuiSetGridTypeValue (gridType, @"inputTextString",  $DropBox)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #################################
' #####  DemoPullDownCode ()  #####
' #################################
'
FUNCTION  DemoPullDownCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED event
'
  $DemoPullDown   =  0  ' kid  0 grid type = DemoPullDown
  $Menu           =  1  ' kid  1 grid type = XuiMenu
  $MenuBar        =  2  ' kid  2 grid type = XuiMenuBar
  $DropButton     =  3  ' kid  3 grid type = XuiDropButton
  $DropBox        =  4  ' kid  4 grid type = XuiDropBox
  $ListButton     =  5  ' kid  5 grid type = XuiListButton
  $ListBox        =  6  ' kid  6 grid type = XuiListBox
  $PullDownLabel  =  7  ' kid  7 grid type = XuiLabel
  $UpperKid       =  7  ' kid maximum
'
'  XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
	XuiSendMessage(grid, #GetGridName, 0, 0, 0, 0, kid, @name$)
	XgrMessageNumberToName(message, @message$)
  SELECT CASE message
    CASE #Selection: GOSUB Selection   ' Common callback message
    CASE #TextEvent: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
  END SELECT
  RETURN
'
'
' *****  Selection  *****
'
SUB Selection
	IF kid = $DemoPullDown THEN EXIT SUB
	IF kid = $Menu THEN PRINT event, name$, message$, v0, v1: INC event
	IF kid = $DropBox || kid = $ListBox THEN
		PRINT event, name$, message$: INC event
	ELSE
		IF kid <> $Menu THEN PRINT event, name$, message$, v0: INC event
	END IF
	IF kid = $Menu || kid = $MenuBar THEN EXIT SUB
	IF kid = $DropButton || kid = $ListButton THEN
		XuiSendMessage(grid, #GetTextArray, 0, 0, 0, 0, kid, @text$[])
		text$ = text$[v0]
	ELSE
		XuiSendMessage(grid, #GetTextString, 0, 0, 0, 0, kid, @text$)
	END IF
	XuiSendMessage(grid, #SetTextString, 0, 0, 0, 0, $PullDownLabel, @text$)
	XuiSendMessage(grid, #Redraw, 0, 0, 0, 0, $PullDownLabel, 0)
	IF kid = $DropButton || kid = $ListButton THEN EXIT SUB
	REDIM text$[4]
	FOR i = 0 TO 4
		text$[i] = CHR$(i + '0') + text$
	NEXT i
	XuiSendMessage(grid, #SetTextArray, 0, 0, 0, 0, kid, @text$[])
	IF kid = $DropBox THEN kid = $DropButton ELSE kid = $ListButton
	XuiSendMessage(grid, #SetTextArray, 0, 0, 0, 0, kid, @text$[])
END SUB
SUB TextEvent
	PRINT event, name$, message$: INC event
END SUB
END FUNCTION
'
'
' #############################
' #####  DemoFileCode ()  #####
' #############################
'
FUNCTION  DemoFileCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED event
'
  $DemoFile  =  0  ' kid  0 grid type = DemoFile
  $File      =  1  ' kid  1 grid type = XuiFile
  $UpperKid  =  1  ' kid maximum
'
'  XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
	XuiSendMessage(grid, #GetGridName, 0, 0, 0, 0, kid, name$)
	XgrMessageNumberToName(message, @message$)
  SELECT CASE message
    CASE #Selection: GOSUB Selection   ' Common callback message
'   CASE #TextEvent: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
  END SELECT
  RETURN
'
'
' *****  Selection  *****
'
SUB Selection
	IF (v0 = -1) THEN
		PRINT event, name$, message$, v0
		INC event
	ELSE
		XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, kid, @text$)
		PRINT event, name$, message$, v0, text$
		INC event
	END IF
END SUB
END FUNCTION
'
'
' #############################
' #####  DemoFontCode ()  #####
' #############################
'
FUNCTION  DemoFontCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED event
'
  $DemoFont  =  0  ' kid  0 grid type = DemoFont
  $Font      =  1  ' kid  1 grid type = XuiFont
  $UpperKid  =  1  ' kid maximum
'
'  XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
	XuiSendMessage(grid, #GetGridName, 0, 0, 0, 0, kid, @name$)
	XgrMessageNumberToName(message, @message$)
'
  SELECT CASE message
    CASE #Selection: GOSUB Selection   ' Common callback message
'   CASE #TextEvent: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
  END SELECT
  RETURN
'
'
' *****  Selection  *****
'
SUB Selection
	PRINT event, name$, message$, v0, "(incomplete)": INC event
END SUB
END FUNCTION
'
'
' ###############################
' #####  DemoMiscellany ()  #####
' ###############################
'
FUNCTION  DemoMiscellany (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
  STATIC  SUBADDR  sub[]
  STATIC  upperMessage
  STATIC  DemoMiscellany
'
  $DemoMiscellany  =  0  ' kid  0 grid type = DemoMiscellany
  $Color           =  1  ' kid  1 grid type = XuiColor
  $Range           =  2  ' kid  2 grid type = XuiRange
  $Progress        =  3  ' kid  3 grid type = XuiProgress
  $UpperKid        =  3  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
' XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, DemoMiscellany) THEN RETURN
  IF (message <= upperMessage) THEN GOSUB @sub[message]
  RETURN
'
'
' *****  Callback  *****  message = Callback : r1 = original message
'
SUB Callback
  message = r1
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
  XuiCreateGrid (@grid, DemoMiscellany, @v0, @v1, @v2, @v3, r0, r1, &DemoMiscellany())
  XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"DemoMiscellany")
  XuiColor       (@g, #Create, 12, 12, 200, 80, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoMiscellany(), -1, -1, $Color, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Color")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Color")
  XuiRange       (@g, #Create, 124, 128, 80, 24, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &DemoMiscellany(), -1, -1, $Range, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Range")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Range")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"RangeLabel")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 1, @"0")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"RangeUp")
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"RangeDown")
  XuiProgress    (@g, #Create, 20, 120, 80, 40, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Progress")
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Progress")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"DemoMiscellany")
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
' sub[#Callback]            = SUBADDRESS (Callback)         ' enable to handle Callback messages internally
  sub[#Create]              = SUBADDRESS (Create)           ' must be internal routine
  sub[#CreateWindow]        = SUBADDRESS (CreateWindow)     ' must be internal routine
' sub[#GetSmallestSize]     = SUBADDRESS (GetSmallestSize)  ' enable to add internal GetSmallestSize routine
' sub[#Resize]              = SUBADDRESS (Resize)           ' enable to add internal Resize routine
  sub[#Selection]           = SUBADDRESS (Selection)        ' routes Selection callbacks to subroutine
'
  IF sub[0] THEN PRINT "DemoMiscellany(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "DemoMiscellany(): Initialize: Error::: (Undefined Message)"
  XuiRegisterGridType (@DemoMiscellany, "DemoMiscellany", &DemoMiscellany(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
  designX = 307
  designY = 231
  designWidth = 228
  designHeight = 180
'
  gridType = DemoMiscellany
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"maxWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"maxHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback)
  XuiSetGridTypeValue (gridType, @"focusKid",         $Range)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ###################################
' #####  DemoMiscellanyCode ()  #####
' ###################################
'
FUNCTION  DemoMiscellanyCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED event
'
  $DemoMiscellany  =  0  ' kid  0 grid type = DemoMiscellany
  $Color           =  1  ' kid  1 grid type = XuiColor
  $Range           =  2  ' kid  2 grid type = XuiRange
  $Progress        =  3  ' kid  3 grid type = XuiProgress
  $UpperKid        =  3  ' kid maximum
'
'  XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
	XuiSendMessage(grid, #GetGridName, 0, 0, 0, 0, kid, @name$)
	XgrMessageNumberToName(message, @message$)
  SELECT CASE message
		CASE #Initialize:GOSUB Initialize
    CASE #Selection: GOSUB Selection   ' Common callback message
'   CASE #TextEvent: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
  END SELECT
  RETURN
'
'
SUB Initialize
	XuiSendMessage(grid, #SetValues, 25, 100, 0, 0, $Progress, 0)
	XuiSendMessage(grid, #SetValues, 25, 5, 0, 100, $Range, 0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	IF kid = $DemoMiscellany THEN EXIT SUB
	PRINT event, name$, message$, v0, v1, v2, v3: INC event
	IF kid <> $Range THEN EXIT SUB
	XuiSendMessage(grid, #SetValues, v0, 100, 0, 0, $Progress, 0)
END SUB
END FUNCTION
END PROGRAM

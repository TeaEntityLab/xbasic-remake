'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "acolors"
VERSION "0.0004"
'
IMPORT "xst"
IMPORT "xgr"
IMPORT "xui"
'
INTERNAL FUNCTION  Entry         ()
INTERNAL FUNCTION  InitGui       ()
INTERNAL FUNCTION  InitProgram   ()
INTERNAL FUNCTION  CreateWindows ()
INTERNAL FUNCTION  SolidColors   (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  SolidColorsCode (grid, message, v0, v1, v2, v3, kid, ANY)
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
  SolidColors   (@SolidColors, #CreateWindow, 0, 0, 0, 0, 0, 0)
  XuiSendMessage (SolidColors, #SetCallback, SolidColors, &SolidColorsCode(), -1, -1, -1, 0)
  XuiSendMessage (SolidColors, #DisplayWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ############################
' #####  SolidColors ()  #####
' ############################
'
FUNCTION  SolidColors (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC  designX,  designY,  designWidth,  designHeight
  STATIC  SUBADDR  sub[]
  STATIC  upperMessage
  STATIC  SolidColors
'
  $SolidColors   =   0  ' kid   0 grid type = SolidColors
  $Black         =   1  ' kid   1 grid type = XuiLabel
  $Blue          =   2  ' kid   2 grid type = XuiLabel
  $LightBlue     =   3  ' kid   3 grid type = XuiLabel
  $Green         =   4  ' kid   4 grid type = XuiLabel
  $Cyan          =   5  ' kid   5 grid type = XuiLabel
  $LightGreen    =   6  ' kid   6 grid type = XuiLabel
  $LightCyan     =   7  ' kid   7 grid type = XuiLabel
  $Red           =   8  ' kid   8 grid type = XuiLabel
  $Magenta       =   9  ' kid   9 grid type = XuiLabel
  $Brown         =  10  ' kid  10 grid type = XuiLabel
  $Grey          =  11  ' kid  11 grid type = XuiLabel
  $BrightGrey    =  12  ' kid  12 grid type = XuiLabel
  $LightRed      =  13  ' kid  13 grid type = XuiLabel
  $LightMagenta  =  14  ' kid  14 grid type = XuiLabel
  $LightYellow   =  15  ' kid  15 grid type = XuiLabel
  $White         =  16  ' kid  16 grid type = XuiLabel
  $Line1         =  17  ' kid  17 grid type = XuiLabel
  $Line2         =  18  ' kid  18 grid type = XuiLabel
  $Line3         =  19  ' kid  19 grid type = XuiLabel
  $Line4         =  20  ' kid  20 grid type = XuiLabel
  $Line5         =  21  ' kid  21 grid type = XuiLabel
  $Line6         =  22  ' kid  22 grid type = XuiLabel
  $Line7         =  23  ' kid  23 grid type = XuiLabel
  $Line8         =  24  ' kid  24 grid type = XuiLabel
  $Quit          =  25  ' kid  25 grid type = XuiPushButton
  $UpperKid      =  25  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
' XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, SolidColors) THEN RETURN
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
  XuiCreateGrid (@grid, SolidColors, @v0, @v1, @v2, @v3, r0, r1, &SolidColors())
  XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"SolidColors")
  XuiSendMessage ( grid, #SetAlign, $$AlignMiddleCenter, 0, -1, -1, 0, 0)
  XuiLabel       (@g, #Create, 4, 4, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Black")
  XuiSendMessage ( g, #SetColor, $$Black, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Black\n\n(drawing)\n(lowlight)\n(lowtext)")
  XuiLabel       (@g, #Create, 148, 4, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Blue")
  XuiSendMessage ( g, #SetColor, $$Blue, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Blue\n$$MediumBlue")
  XuiLabel       (@g, #Create, 292, 4, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LightBlue")
  XuiSendMessage ( g, #SetColor, $$LightBlue, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$LightBlue")
  XuiLabel       (@g, #Create, 436, 4, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Green")
  XuiSendMessage ( g, #SetColor, $$Green, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Green\n$$MediumGreen")
  XuiLabel       (@g, #Create, 4, 72, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Cyan")
  XuiSendMessage ( g, #SetColor, $$Cyan, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Cyan\n$$MediumCyan\n\n(dull)")
  XuiLabel       (@g, #Create, 148, 72, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LightGreen")
  XuiSendMessage ( g, #SetColor, $$LightGreen, $$Black, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$LightGreen")
  XuiLabel       (@g, #Create, 292, 72, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LightCyan")
  XuiSendMessage ( g, #SetColor, $$LightCyan, $$Black, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$LightCyan")
  XuiLabel       (@g, #Create, 436, 72, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Red")
  XuiSendMessage ( g, #SetColor, $$Red, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Red\n$$MediumRed")
  XuiLabel       (@g, #Create, 4, 140, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Magenta")
  XuiSendMessage ( g, #SetColor, $$Magenta, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Magenta\n$$MediumMagenta")
  XuiLabel       (@g, #Create, 148, 140, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Brown")
  XuiSendMessage ( g, #SetColor, $$Brown, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Brown\n$$MediumBrown")
  XuiLabel       (@g, #Create, 292, 140, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Grey")
  XuiSendMessage ( g, #SetColor, $$Grey, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$Grey\n$$MediumGrey")
  XuiLabel       (@g, #Create, 436, 140, 144, 68, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"BrightGrey")
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$BrightGrey\n\n(background)")
  XuiLabel       (@g, #Create, 4, 208, 144, 64, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LightRed")
  XuiSendMessage ( g, #SetColor, $$LightRed, $$Black, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$LightRed")
  XuiLabel       (@g, #Create, 148, 208, 144, 64, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LightMagenta")
  XuiSendMessage ( g, #SetColor, $$LightMagenta, $$Black, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$LightMagenta")
  XuiLabel       (@g, #Create, 292, 208, 144, 64, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LightYellow")
  XuiSendMessage ( g, #SetColor, 120, $$Black, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$LightYellow\n\n(accent)")
  XuiLabel       (@g, #Create, 436, 208, 144, 64, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"White")
  XuiSendMessage ( g, #SetColor, $$White, $$Black, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"$$White\n\n(highlight)\n(hightext)")
  XuiLabel       (@g, #Create, 4, 272, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line1")
  XuiSendMessage ( g, #SetColor, $$Black, $$Black, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"The colors above are almost always \"solid\" colors on most systems")
  XuiLabel       (@g, #Create, 4, 288, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line2")
  XuiSendMessage ( g, #SetColor, $$Black, $$LightGreen, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Default colors (shown in parentheses) are usually solid colors")
  XuiLabel       (@g, #Create, 4, 304, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line3")
  XuiSendMessage ( g, #SetColor, $$Black, $$LightCyan, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"IMPORT \"xgr\" defines these color name constants for programs")
  XuiLabel       (@g, #Create, 4, 320, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line4")
  XuiSendMessage ( g, #SetColor, $$Black, $$LightRed, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Video card/monitor combinations display colors differently")
  XuiLabel       (@g, #Create, 4, 336, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line5")
  XuiSendMessage ( g, #SetColor, $$Black, 120, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Most distributed programs should contain only these colors")
  XuiLabel       (@g, #Create, 4, 352, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line6")
  XuiSendMessage ( g, #SetColor, $$Black, $$White, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Most distributed programs should alter few if any colors")
  XuiLabel       (@g, #Create, 4, 368, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line7")
  XuiSendMessage ( g, #SetColor, $$Black, $$LightGreen, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Text grid background colors should always be solid")
  XuiLabel       (@g, #Create, 4, 384, 576, 16, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Line8")
  XuiSendMessage ( g, #SetColor, $$Black, $$LightCyan, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderNone, $$BorderNone, $$BorderNone, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureFlat, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"3D effect colors should rarely be altered")
  XuiPushButton  (@g, #Create, 4, 400, 576, 48, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &SolidColors(), -1, -1, $Quit, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Quit")
  XuiSendMessage ( g, #SetColor, 76, $$LightCyan, $$Black, $$White, 0, 0)
  XuiSendMessage ( g, #SetColorExtra, $$Grey, $$LightYellow, $$Black, $$LightCyan, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderRaise4, $$BorderRaise4, $$BorderLower2, -1, 0, 0)
  XuiSendMessage ( g, #SetTexture, $$TextureRaise1, 0, 0, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"some non-solid colors like this are okay backgrounds\n***  PRESS THIS BUTTON TO QUIT  ***")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"SolidColors")
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
  IF sub[0] THEN PRINT "SolidColors(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "SolidColors(): Initialize: Error::: (Undefined Message)"
  XuiRegisterGridType (@SolidColors, "SolidColors", &SolidColors(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
  designX = 436
  designY = 23
  designWidth = 584
  designHeight = 452
'
  gridType = SolidColors
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
  XuiSetGridTypeValue (gridType, @"focusKid",         $Quit)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ################################
' #####  SolidColorsCode ()  #####
' ################################
'
FUNCTION  SolidColorsCode (grid, message, v0, v1, v2, v3, kid, r1)
'
	SHARED  terminateProgram
'
  $SolidColors   =   0  ' kid   0 grid type = SolidColors
  $Black         =   1  ' kid   1 grid type = XuiLabel
  $Blue          =   2  ' kid   2 grid type = XuiLabel
  $LightBlue     =   3  ' kid   3 grid type = XuiLabel
  $Green         =   4  ' kid   4 grid type = XuiLabel
  $Cyan          =   5  ' kid   5 grid type = XuiLabel
  $LightGreen    =   6  ' kid   6 grid type = XuiLabel
  $LightCyan     =   7  ' kid   7 grid type = XuiLabel
  $Red           =   8  ' kid   8 grid type = XuiLabel
  $Magenta       =   9  ' kid   9 grid type = XuiLabel
  $Brown         =  10  ' kid  10 grid type = XuiLabel
  $Grey          =  11  ' kid  11 grid type = XuiLabel
  $BrightGrey    =  12  ' kid  12 grid type = XuiLabel
  $LightRed      =  13  ' kid  13 grid type = XuiLabel
  $LightMagenta  =  14  ' kid  14 grid type = XuiLabel
  $LightYellow   =  15  ' kid  15 grid type = XuiLabel
  $White         =  16  ' kid  16 grid type = XuiLabel
  $Line1         =  17  ' kid  17 grid type = XuiLabel
  $Line2         =  18  ' kid  18 grid type = XuiLabel
  $Line3         =  19  ' kid  19 grid type = XuiLabel
  $Line4         =  20  ' kid  20 grid type = XuiLabel
  $Line5         =  21  ' kid  21 grid type = XuiLabel
  $Line6         =  22  ' kid  22 grid type = XuiLabel
  $Line7         =  23  ' kid  23 grid type = XuiLabel
  $Line8         =  24  ' kid  24 grid type = XuiLabel
  $Quit          =  25  ' kid  25 grid type = XuiPushButton
  $UpperKid      =  25  ' kid maximum
'
'	XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
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
  SELECT CASE kid
    CASE $SolidColors   :
    CASE $Black         :
    CASE $Blue          :
    CASE $LightBlue     :
    CASE $Green         :
    CASE $Cyan          :
    CASE $LightGreen    :
    CASE $LightCyan     :
    CASE $Red           :
    CASE $Magenta       :
    CASE $Brown         :
    CASE $Grey          :
    CASE $BrightGrey    :
    CASE $LightRed      :
    CASE $LightMagenta  :
    CASE $LightYellow   :
    CASE $White         :
    CASE $Line1         :
    CASE $Line2         :
    CASE $Line3         :
    CASE $Line4         :
    CASE $Line5         :
    CASE $Line6         :
    CASE $Line7         :
    CASE $Line8         :
    CASE $Quit          : terminateProgram = $$TRUE
  END SELECT
END SUB
END FUNCTION
END PROGRAM

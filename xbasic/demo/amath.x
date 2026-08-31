'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"amath"
VERSION	"0.0009"
'
IMPORT	"xma"
IMPORT	"xst"
IMPORT	"xgr"
IMPORT	"xui"
'
'
'	***********************************
'	*****  Application Functions  *****
'	***********************************
'
DECLARE  FUNCTION  Entry         ()
INTERNAL FUNCTION  InitGui       ()
INTERNAL FUNCTION  InitProgram   ()
INTERNAL FUNCTION  CreateWindows ()
INTERNAL FUNCTION  InitWindows   ()
INTERNAL FUNCTION  Math          (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  MathCode      (grid, message, v0, v1, v2, v3, kid, ANY)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	SHARED  terminateProgram
'
	InitGui ()										' initialize messages
	InitProgram ()								' initialize this program
	CreateWindows ()							' create main window and others
	InitWindows ()								' initialize windows
'
	DO														' the message loop
		XgrProcessMessages (1)			' process one message
	LOOP UNTIL terminateProgram		' and repeats until program is terminated
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
FUNCTION  InitProgram ()
'		Initialize everything your program needs to initialize
END FUNCTION
'
'
' ##############################
' #####  CreateWindows ()  #####
' ##############################
'
FUNCTION  CreateWindows ()
	SHARED  Math
'
  Math           (@Math, #CreateWindow, 0, 0, 0, 0, 0, 0)
  XuiSendMessage ( Math, #SetCallback, Math, &MathCode(), -1, -1, -1, -1)
'  XuiSendMessage ( Math, #SetHelpFile, 0, 0, 0, 0, 0, @"Math.hlp")  '*cw* 211222-
  XuiSendMessage ( Math, #SetHelpFile, 0, 0, 0, 0, 0, @"amath.hlp")  '*cw* 211222+
  XuiSendMessage ( Math, #DisplayWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ############################
' #####  InitWindows ()  #####
' ############################
'
FUNCTION  InitWindows ()
	SHARED  Math
'
  XuiSendMessage ( Math, #MouseDown, 0, 0, 0, 0, 23, 0)
END FUNCTION
'
'
' #####################
' #####  Math ()  #####
' #####################
'
FUNCTION  Math (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC	designX,  designY,  designWidth,  designHeight
  STATIC	SUBADDR  sub[]
  STATIC	upperMessage
  STATIC	Math
'
  $Math     =  0  ' kid  0 grid type = Math
  $SIN      =  1  ' kid  1 grid type = XuiRadioButton
  $ASIN     =  2  ' kid  2 grid type = XuiRadioButton
  $Graphic  =  3  ' kid  3 grid type = XuiLabel
  $Graph    =  4  ' kid  4 grid type = XuiLabel
  $COS      =  5  ' kid  5 grid type = XuiRadioButton
  $ACOS     =  6  ' kid  6 grid type = XuiRadioButton
  $TAN      =  7  ' kid  7 grid type = XuiRadioButton
  $ATAN     =  8  ' kid  8 grid type = XuiRadioButton
  $COT      =  9  ' kid  9 grid type = XuiRadioButton
  $ACOT     = 10  ' kid 10 grid type = XuiRadioButton
  $SEC      = 11  ' kid 11 grid type = XuiRadioButton
  $ASEC     = 12  ' kid 12 grid type = XuiRadioButton
  $CSC      = 13  ' kid 13 grid type = XuiRadioButton
  $ACSC     = 14  ' kid 14 grid type = XuiRadioButton
  $SINH     = 15  ' kid 15 grid type = XuiRadioButton
  $ASINH    = 16  ' kid 16 grid type = XuiRadioButton
  $COSH     = 17  ' kid 17 grid type = XuiRadioButton
  $ACOSH    = 18  ' kid 18 grid type = XuiRadioButton
  $TANH     = 19  ' kid 19 grid type = XuiRadioButton
  $ATANH    = 20  ' kid 20 grid type = XuiRadioButton
  $COTH     = 21  ' kid 21 grid type = XuiRadioButton
  $ACOTH    = 22  ' kid 22 grid type = XuiRadioButton
  $SECH     = 23  ' kid 23 grid type = XuiRadioButton
  $ASECH    = 24  ' kid 24 grid type = XuiRadioButton
  $CSCH     = 25  ' kid 25 grid type = XuiRadioButton
  $ACSCH    = 26  ' kid 26 grid type = XuiRadioButton
  $SQRT     = 27  ' kid 27 grid type = XuiRadioButton
  $POWER    = 28  ' kid 28 grid type = XuiRadioButton
  $Range    = 29  ' kid 29 grid type = XuiLabel
  $LOG      = 30  ' kid 30 grid type = XuiRadioButton
  $EXP      = 31  ' kid 31 grid type = XuiRadioButton
  $Maximum  = 32  ' kid 32 grid type = XuiLabel
  $LOG10    = 33  ' kid 33 grid type = XuiRadioButton
  $EXP10    = 34  ' kid 34 grid type = XuiRadioButton
  $Minimum  = 35  ' kid 35 grid type = XuiLabel
  $CLEAR    = 36  ' kid 36 grid type = XuiRadioButton
  $QUIT     = 37  ' kid 37 grid type = XuiRadioButton
  $Comment  = 38  ' kid 38 grid type = XuiLabel
'
  IFZ sub[] THEN GOSUB Initialize
'	XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, Math) THEN RETURN
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
  XuiCreateGrid (@grid, Math, @v0, @v1, @v2, @v3, r0, r1, &Math())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"Math")
  XuiRadioButton (@g, #Create, 4, 4, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $SIN, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SIN")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"SIN")
  XuiRadioButton (@g, #Create, 68, 4, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ASIN, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ASIN")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ASIN")
  XuiLabel       (@g, #Create, 132, 4, 248, 248, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Graphic")
  XuiSendMessage ( g, #SetColor, 7, 0, 0, 124, 0, 0)
  XuiLabel       (@g, #Create, 140, 12, 232, 232, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Graph")
  XuiSendMessage ( g, #SetColor, 0, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetBorder, $$BorderHiLine1, $$BorderHiLine1, $$BorderRaise1, -1, 0, 0)
	XuiSendMessage ( g, #SetMessageFunc, #RedrawGrid, &MathCode(), 0, 0, 0, 0)
  XuiRadioButton (@g, #Create, 4, 24, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $COS, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"COS")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"COS")
  XuiRadioButton (@g, #Create, 68, 24, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ACOS, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ACOS")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ACOS")
  XuiRadioButton (@g, #Create, 4, 44, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $TAN, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TAN")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"TAN")
  XuiRadioButton (@g, #Create, 68, 44, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ATAN, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ATAN")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ATAN")
  XuiRadioButton (@g, #Create, 4, 64, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $COT, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"COT")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"COT")
  XuiRadioButton (@g, #Create, 68, 64, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ACOT, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ACOT")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ACOT")
  XuiRadioButton (@g, #Create, 4, 84, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $SEC, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SEC")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"SEC")
  XuiRadioButton (@g, #Create, 68, 84, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ASEC, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ASEC")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ASEC")
  XuiRadioButton (@g, #Create, 4, 104, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $CSC, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CSC")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"CSC")
  XuiRadioButton (@g, #Create, 68, 104, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ACSC, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ACSC")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ACSC")
  XuiRadioButton (@g, #Create, 4, 132, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $SINH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SINH")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"SINH")
  XuiRadioButton (@g, #Create, 68, 132, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ASINH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ASINH")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ASINH")
  XuiRadioButton (@g, #Create, 4, 152, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $COSH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"COSH")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"COSH")
  XuiRadioButton (@g, #Create, 68, 152, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ACOSH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ACOSH")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ACOSH")
  XuiRadioButton (@g, #Create, 4, 172, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $TANH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"TANH")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"TANH")
  XuiRadioButton (@g, #Create, 68, 172, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ATANH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ATANH")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ATANH")
  XuiRadioButton (@g, #Create, 4, 192, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $COTH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"COTH")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"COTH")
  XuiRadioButton (@g, #Create, 68, 192, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ACOTH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ACOTH")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ACOTH")
  XuiRadioButton (@g, #Create, 4, 212, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $SECH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SECH")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"SECH")
  XuiRadioButton (@g, #Create, 68, 212, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ASECH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ASECH")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ASECH")
  XuiRadioButton (@g, #Create, 4, 232, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $CSCH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CSCH")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"CSCH")
  XuiRadioButton (@g, #Create, 68, 232, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $ACSCH, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ACSCH")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"ACSCH")
  XuiRadioButton (@g, #Create, 4, 260, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $SQRT, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SQRT")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"SQRT")
  XuiRadioButton (@g, #Create, 68, 260, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $POWER, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"POWER")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"POWER")
  XuiLabel       (@g, #Create, 132, 260, 248, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Range")
  XuiSendMessage ( g, #SetColor, 61, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Range:")
  XuiRadioButton (@g, #Create, 4, 280, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $LOG, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LOG")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"LOG")
  XuiRadioButton (@g, #Create, 68, 280, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $EXP, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"EXP")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"EXP")
  XuiLabel       (@g, #Create, 132, 280, 248, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Maximum")
  XuiSendMessage ( g, #SetColor, 56, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Maximum:")
  XuiRadioButton (@g, #Create, 4, 300, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $LOG10, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LOG10")
  XuiSendMessage ( g, #SetColor, 18, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"LOG10")
  XuiRadioButton (@g, #Create, 68, 300, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $EXP10, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"EXP10")
  XuiSendMessage ( g, #SetColor, 16, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"EXP10")
  XuiLabel       (@g, #Create, 132, 300, 248, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Minimum")
  XuiSendMessage ( g, #SetColor, 56, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Minimum:")
  XuiRadioButton (@g, #Create, 4, 320, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $CLEAR, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CLEAR")
  XuiSendMessage ( g, #SetColor, 15, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"CLEAR")
  XuiRadioButton (@g, #Create, 68, 320, 64, 20, r0, grid)
  XuiSendMessage ( g, #SetCallback, grid, &Math(), -1, -1, $QUIT, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"QUIT")
  XuiSendMessage ( g, #SetColor, 78, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"QUIT")
	XuiSendMessage ( g, #SetTexture, $$TextureShadow, $$TextureShadow, 0, 0, 0, 0)
  XuiLabel       (@g, #Create, 132, 320, 248, 20, r0, grid)
  XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Comment")
  XuiSendMessage ( g, #SetColor, 57, 0, 0, 124, 0, 0)
  XuiSendMessage ( g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Comment:")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Math")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
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
  func[#Callback]           = &XuiCallback()
  func[#Resize]             = &XuiResizeNot()
'
  DIM sub[upperMessage]
  sub[#Create]              = SUBADDRESS (Create)
  sub[#CreateWindow]        = SUBADDRESS (CreateWindow)
'
  IF sub[0] THEN PRINT "First(): Initialize: Error::: Undefined Message"
  IF func[0] THEN PRINT "First(): Initialize: Error::: Undefined Message"
  XuiRegisterGridType (@Math, "Math", &Math(), @func[], @sub[])
'
  designX = 768
  designY = 23
  designWidth = 384
  designHeight = 344
'
  gridType = Math
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"maxWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"maxHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"minWidth",         designWidth)
  XuiSetGridTypeValue (gridType, @"minHeight",        designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Respond OR $$Callback)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #########################
' #####  MathCode ()  #####
' #########################
'
FUNCTION  MathCode (grid, message, v0, v1, v2, v3, r0, r1)
	STATIC	graph
	STATIC  func
'
  $Math     =  0  ' kid  0 grid type = Math
  $SIN      =  1  ' kid  1 grid type = XuiRadioButton
  $ASIN     =  2  ' kid  2 grid type = XuiRadioButton
  $Graphic  =  3  ' kid  3 grid type = XuiLabel
  $Graph    =  4  ' kid  4 grid type = XuiLabel
  $COS      =  5  ' kid  5 grid type = XuiRadioButton
  $ACOS     =  6  ' kid  6 grid type = XuiRadioButton
  $TAN      =  7  ' kid  7 grid type = XuiRadioButton
  $ATAN     =  8  ' kid  8 grid type = XuiRadioButton
  $COT      =  9  ' kid  9 grid type = XuiRadioButton
  $ACOT     = 10  ' kid 10 grid type = XuiRadioButton
  $SEC      = 11  ' kid 11 grid type = XuiRadioButton
  $ASEC     = 12  ' kid 12 grid type = XuiRadioButton
  $CSC      = 13  ' kid 13 grid type = XuiRadioButton
  $ACSC     = 14  ' kid 14 grid type = XuiRadioButton
  $SINH     = 15  ' kid 15 grid type = XuiRadioButton
  $ASINH    = 16  ' kid 16 grid type = XuiRadioButton
  $COSH     = 17  ' kid 17 grid type = XuiRadioButton
  $ACOSH    = 18  ' kid 18 grid type = XuiRadioButton
  $TANH     = 19  ' kid 19 grid type = XuiRadioButton
  $ATANH    = 20  ' kid 20 grid type = XuiRadioButton
  $COTH     = 21  ' kid 21 grid type = XuiRadioButton
  $ACOTH    = 22  ' kid 22 grid type = XuiRadioButton
  $SECH     = 23  ' kid 23 grid type = XuiRadioButton
  $ASECH    = 24  ' kid 24 grid type = XuiRadioButton
  $CSCH     = 25  ' kid 25 grid type = XuiRadioButton
  $ACSCH    = 26  ' kid 26 grid type = XuiRadioButton
  $SQRT     = 27  ' kid 27 grid type = XuiRadioButton
  $POWER    = 28  ' kid 28 grid type = XuiRadioButton
  $Range    = 29  ' kid 29 grid type = XuiLabel
  $LOG      = 30  ' kid 30 grid type = XuiRadioButton
  $EXP      = 31  ' kid 31 grid type = XuiRadioButton
  $Maximum  = 32  ' kid 32 grid type = XuiLabel
  $LOG10    = 33  ' kid 33 grid type = XuiRadioButton
  $EXP10    = 34  ' kid 34 grid type = XuiRadioButton
  $Minimum  = 35  ' kid 35 grid type = XuiLabel
  $CLEAR    = 36  ' kid 36 grid type = XuiRadioButton
  $QUIT     = 37  ' kid 37 grid type = XuiRadioButton
  $Comment  = 38  ' kid 38 grid type = XuiLabel
'
	IFZ graph THEN GOSUB Initialize
'	XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
	IF (message = #Callback) THEN message = r1
'
	SELECT CASE message
'   CASE #Help				:	GOSUB Help        ' callback when help requested
		CASE #CloseWindow	: GOSUB CloseWindow	' system menu close window
		CASE #RedrawGrid	:	GOSUB RedrawGrid	' redraw math function
    CASE #Selection		:	GOSUB Selection   ' common callback message
'   CASE #TextEvent		:	GOSUB TextEvent   ' from TextArea and TextLine
	END SELECT
'
'
' *****  CloseWindow  *****
'
SUB CloseWindow
	PRINT "CloseWindow"
	XuiSendMessage (grid, #MinimizeWindow, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  RedrawGrid  *****
'
SUB RedrawGrid
	XuiRedrawGrid (grid, #RedrawGrid, 0, 0, 0, 0, 0, 0)
	v0 = $$TRUE
	r0 = func
	GOSUB Selection
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
	IFZ v0 THEN EXIT SUB
	SELECT CASE r0
		CASE $SIN		: GOSUB PlotSIN
		CASE $COS		: GOSUB PlotCOS
		CASE $TAN		: GOSUB PlotTAN
		CASE $COT		: GOSUB PlotCOT
		CASE $SEC		: GOSUB PlotSEC
		CASE $CSC		: GOSUB PlotCSC
'
		CASE $ASIN	: GOSUB PlotASIN
		CASE $ACOS	: GOSUB PlotACOS
		CASE $ATAN	: GOSUB PlotATAN
		CASE $ACOT	: GOSUB PlotACOT
		CASE $ASEC	: GOSUB PlotASEC
		CASE $ACSC	: GOSUB PlotACSC
'
		CASE $SINH	: GOSUB PlotSINH
		CASE $COSH	: GOSUB PlotCOSH
		CASE $TANH	: GOSUB PlotTANH
		CASE $COTH	: GOSUB PlotCOTH
		CASE $SECH	: GOSUB PlotSECH
		CASE $CSCH	: GOSUB PlotCSCH
'
		CASE $ASINH	: GOSUB PlotASINH
		CASE $ACOSH	: GOSUB PlotACOSH
		CASE $ATANH	: GOSUB PlotATANH
		CASE $ACOTH	: GOSUB PlotACOTH
		CASE $ASECH	: GOSUB PlotASECH
		CASE $ACSCH	: GOSUB PlotACSCH
'
		CASE $SQRT	: GOSUB PlotSQRT
		CASE $POWER	:	GOSUB PlotPOWER
		CASE $LOG		: GOSUB PlotLOG
		CASE $EXP		: GOSUB PlotEXP
		CASE $LOG10	: GOSUB PlotLOG10
		CASE $EXP10	: GOSUB PlotEXP10
'
		CASE $CLEAR	:	XgrClearGrid (graph, -1) : GOSUB DrawAxes
		CASE $QUIT	:	QUIT(0)
	END SELECT
	func = r0
END SUB
'
'
' *****  DrawAxes  *****
'
SUB DrawAxes
	XgrClearGrid (graph, -1)
	XgrSetGridBoxScaled (graph, -1#, -1#, +1#, +1#)
	XgrDrawLineScaled (graph, $$Green, -1#, 0#, +1#, 0#)
	XgrDrawLineScaled (graph, $$Green, 0#, +1#, 0#, -1#)
	XgrDrawBoxScaled (graph, $$BrightGreen, -1#, -1#, +1#, +1#)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Range,   "Range::: " + range$)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Minimum, "Minumum: " + minimum$)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Maximum, "Maximum: " + maximum$)
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Comment, "Comment: " + comment$)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $Range, 0)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $Minimum, 0)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $Maximum, 0)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, $Comment, 0)
	range$ = ""
	minimum$ = ""
	maximum$ = ""
	comment$ = ""
END SUB
'
'
' *****  PlotSIN  *****
'
SUB PlotSIN
	range$ = "-2PI to +2PI"
	minimum$ = "-1"
	maximum$ = "+1"
	comment$ = "SIN()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$TWOPI, 1#, $$TWOPI, -1#)
	x# = -$$TWOPI
	y# = SIN (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$TWOPI TO $$TWOPI STEP ($$PI/64#)
		y# = SIN(x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotCOS
	range$ = "-2PI to +2PI"
	minimum$ = "-1"
	maximum$ = "+1"
	comment$ = "COS()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$TWOPI, 1#, $$TWOPI, -1#)
	x# = -$$TWOPI
	y# = COS (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$TWOPI TO $$TWOPI STEP ($$PI/64#)
		y# = COS (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotTAN
	range$ = "-2PI to +2PI"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "TAN()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$TWOPI, 4#, $$TWOPI, -4#)
	x# = -$$TWOPI
	y# = TAN (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$TWOPI TO $$TWOPI STEP ($$PI/64#)
		y# = TAN (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotCOT
	range$ = "-2PI to +2PI"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "COT()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$TWOPI, 4#, $$TWOPI, -4#)
	x# = -$$TWOPI
	y# = COT (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$TWOPI TO $$TWOPI STEP ($$PI/64#)
		y# = COT (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotSEC
	range$ = "-2PI to +2PI"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "SEC()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$TWOPI, 4#, $$TWOPI, -4#)
	x# = -$$TWOPI
	y# = SEC (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$TWOPI TO $$TWOPI STEP ($$PI/64#)
		y# = SEC (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotCSC
	range$ = "-2PI to +2PI"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "CSC()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$TWOPI, 4#, $$TWOPI, -4#)
	x# = -$$TWOPI
	y# = CSC (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$TWOPI TO $$TWOPI STEP ($$PI/64#)
		y# = CSC (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
'
' *****  PlotASIN  *****
'
SUB PlotASIN
	range$ = "-1 to +1"
	minimum$ = "-PI/2"
	maximum$ = "+PI/2"
	comment$ = "ASIN()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -1#, +$$PIDIV2, +1#, -$$PIDIV2)
	x# = -1#
	y# = ASIN (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -1# TO +1# STEP (1#/64#)
		y# = ASIN(x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotACOS
	range$ = "-1 to +1"
	minimum$ = "-PI"
	maximum$ = "+PI"
	comment$ = "ACOS()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -1#, +$$PI, +1#, -$$PI)
	x# = -1#
	y# = ACOS (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -1# TO +1# STEP (1#/64#)
		y# = ACOS (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotATAN
	range$ = "-8 to +8"
	minimum$ = "-PI/2"
	maximum$ = "+PI/2"
	comment$ = "ATAN()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -8#, +$$PIDIV2, +8#, -$$PIDIV2)
	x# = -8#
	y# = ATAN (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -8# TO +8# STEP (1#/16#)
		y# = ATAN (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotACOT
	range$ = "-4 to +4"
	minimum$ = "-PI"
	maximum$ = "+PI"
	comment$ = "ACOT()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -4#, +$$PI, 4#, -$$PI)
	x# = -4#
	y# = ACOT (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -4# TO 4# STEP (1#/16#)
		y# = ACOT (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotASEC
	range$ = "-16 to -1 : +1 to +16"
	minimum$ = "-PI"
	maximum$ = "+PI"
	comment$ = "ASEC()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -16#, +$$PI, +16#, -$$PI)
	x# = -16#
	y# = ASEC (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -16# TO -1# STEP (.5#)
		y# = ASEC (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
	x# = +1#
	y# = ASEC (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = +1# TO +16# STEP (.5#)
		y# = ASEC (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotACSC
	range$ = "-16 to -1 : +1 to +16"
	minimum$ = "-PI"
	maximum$ = "+PI"
	comment$ = "ACSC()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -16#, +$$PI, +16#, -$$PI)
	x# = -16#
	y# = ACSC (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -16# TO -1# STEP (.5#)
		y# = ACSC (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
	x# = +1#
	y# = ACSC (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = +1# TO +16# STEP (.5#)
		y# = ACSC (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
'
' *****  PlotSINH  *****
'
SUB PlotSINH
	range$ = "-2 to +2"
	minimum$ = "-2"
	maximum$ = "+2"
	comment$ = "SINH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -2#, +2#, +2#, -2#)
	x# = -2#
	y# = SINH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -2# TO +2# STEP (.0625#)
		y# = SINH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotCOSH
	range$ = "-4 to +4"
	minimum$ = "-16"
	maximum$ = "+16"
	comment$ = "COSH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -4#, +16#, +4#, -16#)
	x# = -4#
	y# = COSH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -4# TO +4# STEP (.0625#)
		y# = COSH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotTANH
	range$ = "-PI to +PI"
	minimum$ = "-1"
	maximum$ = "+1"
	comment$ = "TANH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$PI, +1#, +$$PI, -1#)
	x# = -$$PI
	y# = TANH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$PI TO +$$PI STEP ($$PI/64#)
		y# = TANH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotCOTH
	range$ = "-2 to +2"
	minimum$ = "-16"
	maximum$ = "+16"
	comment$ = "COTH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -2#, +16#, +2#, -16#)
	x# = -2#
	y# = COTH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -2# TO -.01# STEP (.0625#)
		y# = COTH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
	x# = .01#
	y# = COTH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = .01# TO +2# STEP (.0625#)
		y# = COTH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotSECH
	range$ = "-2PI to +2PI"
	minimum$ = "-1"
	maximum$ = "+1"
	comment$ = "SECH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -$$TWOPI, 1#, $$TWOPI, -1#)
	x# = -$$TWOPI
	y# = SECH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -$$TWOPI TO $$TWOPI STEP ($$PI/64#)
		y# = SECH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotCSCH
	range$ = "-2 to +2"
	minimum$ = "-16"
	maximum$ = "+16"
	comment$ = "CSCH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -2#, +16#, +2#, -16#)
	x# = -2#
	y# = CSCH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -2# TO -.01# STEP (.0625#)
		y# = CSCH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
	x# = +.01#
	y# = CSCH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = .01# TO +2# STEP (.0625#)
		y# = CSCH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
'
' *****  PlotASINH  *****
'
SUB PlotASINH
	range$ = "-16 to +16"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "ASINH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -16#, +4#, +16#, -4#)
	x# = -16#
	y# = ASINH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -16# TO +16# STEP (.25#)
		y# = ASINH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotACOSH
	range$ = "-16 to +16"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "ACOSH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -16#, +4#, +16#, -4#)
	x# = +1#
	y# = ACOSH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = +1# TO +16# STEP (.25#)
		y# = ACOSH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotATANH
	range$ = "-1 to +1"
	minimum$ = "-2"
	maximum$ = "+2"
	comment$ = "ATANH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -1#, +2#, +1#, -2#)
	x# = -.99#
	y# = ATANH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -.99# TO +.99# STEP (1#/64#)
		y# = ATANH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotACOTH
	range$ = "-4 to +4"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "ACOTH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -4#, +4#, +4#, -4#)
	x# = -4#
	y# = ACOTH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -4# TO -1.01# STEP (.0625#)
		y# = ACOTH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
	x# = +1.01#
	y# = ACOTH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = +1.01# TO +4# STEP (.0625#)
		y# = ACOTH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotASECH
	range$ = "-1 to +1"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "ASECH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -1#, +4#, +1#, -4#)
	x# = .01#
	y# = ASECH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = .01# TO 1# STEP (.0625#)
		y# = ASECH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotACSCH
	range$ = "-4 to +4"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "ACSCH()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -4#, +4#, +4#, -4#)
	x# = -4#
	y# = ACSCH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -4# TO -.01# STEP (.0625#)
		y# = ACSCH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
	x# = .01#
	y# = ACSCH (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = .01# TO +4# STEP (.0625#)
		y# = ACSCH (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
'
' *****  PlotSQRT  *****
'
SUB PlotSQRT
	range$ = "-1 to +1"
	minimum$ = "-1"
	maximum$ = "+1"
	comment$ = "SQRT()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -1#, +1#, +1#, -1#)
	x# = 0#
	y# = SQRT (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = 0# TO +1# STEP (1#/64#)
		y# = SQRT (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotPOWER
	range$ = "-2 to +2"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "x ** x  (x to the x)"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -2#, +4#, +2#, -4#)
	x# = .01#
	y# = POWER (x#, x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = .01# TO +2# STEP (1#/64#)
		y# = POWER (x#, x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotLOG
	range$ = "-4 to +4"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "LOG()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -4#, +4#, +4#, -4#)
	x# = .01#
	y# = LOG (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = .01# TO +4# STEP (1#/64#)
		y# = LOG (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotEXP
	range$ = "-2 to +2"
	minimum$ = "-8"
	maximum$ = "+8"
	comment$ = "EXP()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -2#, +8#, +2#, -8#)
	x# = -2#
	y# = EXP (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -2# TO +2# STEP (1#/64#)
		y# = EXP (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotLOG10
	range$ = "-4 to +4"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "LOG10()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -4#, +4#, +4#, -4#)
	x# = .01#
	y# = LOG10 (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = .01# TO +4# STEP (1#/64#)
		y# = LOG10 (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
SUB PlotEXP10
	range$ = "-1 to +1"
	minimum$ = "-4"
	maximum$ = "+4"
	comment$ = "EXP10()"
	GOSUB DrawAxes
	XgrSetGridBoxScaled (graph, -1#, +4#, +1#, -4#)
	x# = -1#
	y# = EXP10 (x#)
	XgrMoveToScaled (graph, x#, y#)
	FOR x# = -1# TO +1# STEP (1#/64#)
		y# = EXP10 (x#)
		XgrDrawLineToScaled (graph, $$Yellow, x#, y#)
	NEXT x#
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	XuiSendMessage (grid, #GetGridNumber, @graph, 0, 0, 0, $Graph, 0)
	XgrSetGridClip (graph, graph)
END SUB
END FUNCTION
END PROGRAM

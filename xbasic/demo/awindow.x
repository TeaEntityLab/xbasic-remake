'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"awindow"
VERSION	"0.0005"
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
INTERNAL FUNCTION  Entry         ()
INTERNAL FUNCTION  InitGui       ()
INTERNAL FUNCTION  InitProgram   ()
INTERNAL FUNCTION  CreateWindows ()
INTERNAL FUNCTION  XitMain       (grid, message, v0, v1, v2, v3, kid, ANY)
INTERNAL FUNCTION  XitMainCode   (grid, message, v0, v1, v2, v3, kid, ANY)
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
	Xui ()												' initialize GuiDesigner
	InitGui ()										' initialize messages
	InitProgram ()								' initialize this program
	CreateWindows ()							' create main window and others
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
FUNCTION  CreateWindows ()
'
  XitMain        (@XitMain, #CreateWindow, 0, 0, 0, 0, 0, 0)
  XuiSendMessage ( XitMain, #SetCallback, XitMain, &XitMainCode(), -1, -1, -1, 0)
  XuiSendMessage ( XitMain, #Initialize, 0, 0, 0, 0, 0, 0)
  XuiSendMessage ( XitMain, #DisplayWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ########################
' #####  XitMain ()  #####
' ########################
'
FUNCTION  XitMain (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
  STATIC	designX,  designY,  designWidth,  designHeight
  STATIC	SUBADDR  sub[]
	STATIC	upperMessage
  STATIC	XitMain
'
  $XitMain              =  0  ' kid  0 grid type = XitMain
  $MenuBar              =  1  ' kid  1 grid type = XuiMenu
  $FileLabel            =  2  ' kid  2 grid type = XuiLabel
  $TextUpper            =  3  ' kid  3 grid type = XuiTextArea
  $FunctionLabel        =  4  ' kid  4 grid type = XuiLabel
  $StatusLabel          =  5  ' kid  5 grid type = XuiLabel
  $ErrorLabel           =  6  ' kid  6 grid type = XuiLabel
  $HotStart             =  7  ' kid  7 grid type = XuiPushButton
  $HotContinue          =  8  ' kid  8 grid type = XuiPushButton
  $HotPause             =  9  ' kid  9 grid type = XuiPushButton
  $HotKill              = 10  ' kid 10 grid type = XuiPushButton
  $HotToCursor          = 11  ' kid 11 grid type = XuiPushButton
  $HotStepLocal         = 12  ' kid 12 grid type = XuiPushButton
  $HotStepGlobal        = 13  ' kid 13 grid type = XuiPushButton
  $HotVariables         = 14  ' kid 14 grid type = XuiPushButton
  $HotFrames            = 15  ' kid 15 grid type = XuiPushButton
  $HotAssembly          = 16  ' kid 16 grid type = XuiPushButton
  $HotFind              = 17  ' kid 17 grid type = XuiPushButton
  $HotReplace           = 18  ' kid 18 grid type = XuiPushButton
  $HotToggleBreakpoint  = 19  ' kid 19 grid type = XuiPushButton
  $HotClearBreakpoints  = 20  ' kid 20 grid type = XuiPushButton
  $HotGui               = 21  ' kid 21 grid type = XuiPushButton
  $HotAbort             = 22  ' kid 22 grid type = XuiPushButton
  $TextLower            = 23  ' kid 23 grid type = XuiTextArea
  $UpperKid             = 23  ' kid maximum
'
'
  IFZ sub[] THEN GOSUB Initialize
'	XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
  IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XitMain) THEN RETURN
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
  XuiCreateGrid (@grid, XitMain, @v0, @v1, @v2, @v3, r0, r1, &XitMain())
  XuiSendMessage (grid, #SetGridName, 0, 0, 0, 0, 0, @"XitMain")
  XuiSendMessage (grid, #SetBorder, 0, 0, $$BorderFrame, -1, 0, 0)
  XuiMenu       (@g, #Create, 0, 0, 468, 24, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $MenuBar, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"MenuBar")
  DIM text$[61]
  text$[ 0] = "_File  "
  text$[ 1] = " _New"
	text$[ 2] = " _TextLoad"
	text$[ 3] = " _Load"
	text$[ 4] = " _Save"
	text$[ 5] = " _Mode"
	text$[ 6] = " _Rename"
	text$[ 7] = " _Quit"
	text$[ 8] = "_Edit  "
  text$[ 9] = " _Cut"
	text$[10] = " _Grab"
	text$[11] = " _Paste"
	text$[12] = " _Delete"
	text$[13] = " _Buffer"
	text$[14] = " _Insert"
	text$[15] = " _Erase"
	text$[16] = " _Find"
	text$[17] = " _Read"
	text$[18] = " _Write"
	text$[19] = " _Abandon"
  text$[20] = "_View  "
  text$[21] = " _Function"
	text$[22] = " _PriorFunction"
	text$[23] = " _NewFunction"
	text$[24] = " _DeleteFunction"
	text$[25] = " _RenameFunction"
	text$[26] = " _CloneFunction"
	text$[27] = " _LoadFunction"
	text$[28] = " _SaveFunction"
	text$[29] = " _Merge PROLOG"
  text$[30] = "_Option  "
  text$[31] = " _Compile"
	text$[32] = " _TabWidth (pixels)"
  text$[33] = "_Run  "
  text$[34] = " _Start"
	text$[35] = " _Continue"
	text$[36] = " _Jump"
	text$[37] = " _Pause"
	text$[38] = " _Kill"
	text$[39] = " _Recompile"
	text$[40] = " _Assembly"
	text$[41] = " _Library"
	text$[42] = "_Debug  "
  text$[43] = " _ToggleBreakpoint"
	text$[44] = " _ClearAllBreakpoints"
	text$[45] = " _EraseLocalBreakpoints"
	text$[46] = " _Memory"
	text$[47] = " _Assembly"
	text$[48] = " _Registers"
	text$[49] = "_Status  "
  text$[50] = " _CompilationErrors"
	text$[51] = " _RuntimeErrors"
	text$[52] = "_Help  "
  text$[53] = " _Message"
	text$[54] = " _Language"
	text$[55] = " _Operator"
	text$[56] = " _DotCommand"
	text$[57] = " MathLibrary"
	text$[58] = " StandardLibrary"
	text$[59] = " GraphicsLibrary"
	text$[60] = " GuiDesignerLibrary"
	text$[61] = " ComplexNumberLibrary"
  XuiSendMessage (g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiLabel      (@g, #Create, 468, 0, 132, 24, r0, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"FileLabel")
  XuiSendMessage (g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiTextArea   (@g, #Create, 0, 24, 468, 72, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $TextUpper, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"TextUpper")
  XuiSendMessage (g, #SetTextString, 0, 0, 0, 0, 0, @"!!! Click right button on any grid for InstantHelp !!!\n.c\n")
  DIM text$[0]
  text$[0] = "!!!!!  This is awindow.x - not the PDE  !!!!!"
  XuiSendMessage (g, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
  XuiLabel      (@g, #Create, 468, 24, 132, 24, r0, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"FunctionLabel")
  XuiSendMessage (g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiLabel      (@g, #Create, 468, 48, 132, 24, r0, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"StatusLabel")
  XuiSendMessage (g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiLabel      (@g, #Create, 468, 72, 132, 24, r0, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"ErrorLabel")
  XuiSendMessage (g, #SetAlign, $$AlignMiddleLeft, -1, 4, 0, 0, 0)
  XuiPushButton (@g, #Create, 0, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotStart, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotStart")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xstart.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 32, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotContinue, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotContinue")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xcontin.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 64, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotPause, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotPause")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xpause.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 96, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotKill, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotKill")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xkill.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 132, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotToCursor, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotToCursor")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xtocurs.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 164, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotStepLocal, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotStepLocal")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xsteploc.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 196, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotStepGlobal, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotStepGlobal")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xstepglo.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 232, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotVariables, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotVariables")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xvar.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 264, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotFrames, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotFrames")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xframe.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 296, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotAssembly, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotAssembly")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xasm.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 332, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotFind, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotFind")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xfind.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 364, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotReplace, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotReplace")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xreplace.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 400, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotToggleBreakpoint, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotToggleBreakpoint")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xtogbpt.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 432, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotClearBreakpoints, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotClearBreakpoints")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xclrbpts.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 468, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotGui, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotGui")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xtoolkit.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiPushButton (@g, #Create, 568, 96, 32, 32, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $HotAbort, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"HotAbort")
  XuiSendMessage (g, #SetBorder, $$BorderRaise1, $$BorderRaise1, 0, -1, 0, 0)
  XuiSendMessage (g, #SetImage, 0, 0, 0, 0, 0, @"$XBDIR/images/xabort.bmp")
  XuiSendMessage (g, #SetImageCoords, 0, 0, 32, 32, 0, 0)
  XuiTextArea   (@g, #Create, 0, 128, 600, 72, r0, grid)
  XuiSendMessage (g, #SetCallback, grid, &XitMain(), -1, -1, $TextLower, grid)
  XuiSendMessage (g, #SetGridName, 0, 0, 0, 0, 0, @"TextLower")
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
  XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"XitMain")
END SUB
'
'
' *****  GetSmallestSize  *****
'
SUB GetSmallestSize
	XuiSendToKid (grid, #GetSmallestSize, @w, @h, @ww, @hh, $MenuBar, 0)
	v2 = ww + 132
	v3 = designHeight
	IF (v2 < designWidth) THEN v2 = designWidth
END SUB
'
'
' *****  Resize  *****
'
SUB Resize
	vv0 = v0
	vv1 = v1
	vv2 = v2
	vv3 = v3
	GOSUB GetSmallestSize						' get minWidth and minHeight in v2,v3
	v0 = vv0												' recover v0
	v1 = vv1												' recover v1
	IF (v2 < vv2) THEN v2 = vv2			' requested width greater than minWidth
	IF (v3 < vv3) THEN v3 = vv3			' requested height greater then minHeight
'
	width = v2
	height = v3
'
	lx = width - 132
	ax = width - 32
	tw = width
	th = height - 128
	XuiPositionGrid (grid, @v0, @v1, @v2, @v3)
	XuiSendMessage (grid, #Resize,   0,   0,  lx,  24, $MenuBar,             0)
	XuiSendMessage (grid, #Resize,  lx,   0, 132,  24, $FileLabel,           0)
	XuiSendMessage (grid, #Resize,   0,  24,  lx,  72, $TextUpper,           0)
	XuiSendMessage (grid, #Resize,  lx,  24, 132,  24, $FunctionLabel,       0)
	XuiSendMessage (grid, #Resize,  lx,  48, 132,  24, $StatusLabel,         0)
	XuiSendMessage (grid, #Resize,  lx,  72, 132,  24, $ErrorLabel,          0)
	XuiSendMessage (grid, #Resize,   0,  96,  32,  32, $HotStart,            0)
	XuiSendMessage (grid, #Resize,  32,  96,  32,  32, $HotContinue,         0)
	XuiSendMessage (grid, #Resize,  64,  96,  32,  32, $HotPause,            0)
	XuiSendMessage (grid, #Resize,  96,  96,  32,  32, $HotKill,             0)
	XuiSendMessage (grid, #Resize, 132,  96,  32,  32, $HotToCursor,         0)
	XuiSendMessage (grid, #Resize, 164,  96,  32,  32, $HotStepLocal,        0)
	XuiSendMessage (grid, #Resize, 196,  96,  32,  32, $HotStepGlobal,       0)
	XuiSendMessage (grid, #Resize, 232,  96,  32,  32, $HotVariables,        0)
	XuiSendMessage (grid, #Resize, 264,  96,  32,  32, $HotFrames,           0)
	XuiSendMessage (grid, #Resize, 296,  96,  32,  32, $HotAssembly,         0)
	XuiSendMessage (grid, #Resize, 332,  96,  32,  32, $HotFind,             0)
	XuiSendMessage (grid, #Resize, 364,  96,  32,  32, $HotReplace,          0)
	XuiSendMessage (grid, #Resize, 400,  96,  32,  32, $HotToggleBreakpoint, 0)
	XuiSendMessage (grid, #Resize, 432,  96,  32,  32, $HotClearBreakpoints, 0)
	XuiSendMessage (grid, #Resize, 468,  96,  32,  32, $HotGui,              0)
	XuiSendMessage (grid, #Resize,  ax,  96,  32,  32, $HotAbort,            0)
	XuiSendMessage (grid, #Resize,   0, 128,  tw,  th, $TextLower,           0)
	XuiResizeWindowToGrid (grid, #ResizeWindowToGrid, 0, 0, 0, 0, 0, 0)
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
	func[#GotKeyboardFocus]		= &XuiGotKeyboardFocus()
	func[#LostKeyboardFocus]	= &XuiLostKeyboardFocus()
	func[#Resize]							= 0
	func[#SetKeyboardFocus]		= &XuiSetKeyboardFocus()
'
	DIM sub[upperMessage]
	sub[#Create]							= SUBADDRESS (Create)
	sub[#CreateWindow]				= SUBADDRESS (CreateWindow)
	sub[#GetSmallestSize]			= SUBADDRESS (GetSmallestSize)
	sub[#Resize]							= SUBADDRESS (Resize)
'
  IF sub[0] THEN PRINT "First(): Initialize: Error::: (Undefined Message)"
  IF func[0] THEN PRINT "First(): Initialize: Error::: (Undefined Message)"
	XuiRegisterGridType (@XitMain, @"XitMain", &XitMain(), @func[], @sub[])
'
  designX = 420
  designY = 564
  designWidth = 600
  designHeight = 200
'
  gridType = XitMain
  XuiSetGridTypeValue (gridType, @"x",                designX)
  XuiSetGridTypeValue (gridType, @"y",                designY)
  XuiSetGridTypeValue (gridType, @"width",            designWidth)
  XuiSetGridTypeValue (gridType, @"height",           designHeight)
  XuiSetGridTypeValue (gridType, @"border",           $$BorderFrame)
  XuiSetGridTypeValue (gridType, @"can",              $$Focus OR $$Respond OR $$Callback OR $$InputTextArray)
  XuiSetGridTypeValue (gridType, @"focusKid",         $TextLower)
  XuiSetGridTypeValue (gridType, @"inputTextArray",   $TextLower)
  IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' ############################
' #####  XitMainCode ()  #####
' ############################
'
FUNCTION  XitMainCode (grid, message, v0, v1, v2, v3, kid, r1)
'
  $XitMain              =  0  ' kid  0 grid type = XitMain
  $MenuBar              =  1  ' kid  1 grid type = XuiMenu
  $FileLabel            =  2  ' kid  2 grid type = XuiLabel
  $TextUpper            =  3  ' kid  3 grid type = XuiTextArea
  $FunctionLabel        =  4  ' kid  4 grid type = XuiLabel
  $StatusLabel          =  5  ' kid  5 grid type = XuiLabel
  $ErrorLabel           =  6  ' kid  6 grid type = XuiLabel
  $HotStart             =  7  ' kid  7 grid type = XuiPushButton
  $HotContinue          =  8  ' kid  8 grid type = XuiPushButton
  $HotPause             =  9  ' kid  9 grid type = XuiPushButton
  $HotKill              = 10  ' kid 10 grid type = XuiPushButton
  $HotToCursor          = 11  ' kid 11 grid type = XuiPushButton
  $HotStepLocal         = 12  ' kid 12 grid type = XuiPushButton
  $HotStepGlobal        = 13  ' kid 13 grid type = XuiPushButton
  $HotVariables         = 14  ' kid 14 grid type = XuiPushButton
  $HotFrames            = 15  ' kid 15 grid type = XuiPushButton
  $HotAssembly          = 16  ' kid 16 grid type = XuiPushButton
  $HotFind              = 17  ' kid 17 grid type = XuiPushButton
  $HotReplace           = 18  ' kid 18 grid type = XuiPushButton
  $HotToggleBreakpoint  = 19  ' kid 19 grid type = XuiPushButton
  $HotClearBreakpoints  = 20  ' kid 20 grid type = XuiPushButton
  $HotGui               = 21  ' kid 21 grid type = XuiPushButton
  $HotAbort             = 22  ' kid 22 grid type = XuiPushButton
  $TextLower            = 23  ' kid 23 grid type = XuiTextArea
  $UpperKid             = 23  ' kid maximum
'
'	XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
  IF (message = #Callback) THEN message = r1
'
  SELECT CASE message
    CASE #Selection		: GOSUB Selection   ' Common callback message
    CASE #TextEvent		: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
		CASE #CloseWindow	: QUIT (0)
  END SELECT
  RETURN
'
'
' *****  Selection  *****
'
SUB Selection
  SELECT CASE  kid
    CASE $XitMain              :	XuiMessage (@"XitMain")
    CASE $MenuBar              :	GOSUB MainMenu
    CASE $FileLabel            :	XuiMessage (@"FileLabel")
    CASE $TextUpper            :	XuiMessage (@"TextUpper")
    CASE $FunctionLabel        :	XuiMessage (@"FunctionLabel")
    CASE $StatusLabel          :	XuiMessage (@"StatusLabel")
    CASE $ErrorLabel           :	XuiMessage (@"ErrorLabel")
    CASE $HotStart             :	XuiMessage (@"HotStart")
    CASE $HotContinue          :	XuiMessage (@"HotContinue")
    CASE $HotPause             :	XuiMessage (@"HotPause")
    CASE $HotKill              :	XuiMessage (@"HotKill")
    CASE $HotToCursor          :	XuiMessage (@"HotToCursor")
    CASE $HotStepLocal         :	XuiMessage (@"HotStepLocal")
    CASE $HotStepGlobal        :	XuiMessage (@"HotStepGlobal")
    CASE $HotVariables         :	XuiMessage (@"HotVariables")
    CASE $HotFrames            :	XuiMessage (@"HotFrames")
    CASE $HotAssembly          :	XuiMessage (@"HotAssembly")
    CASE $HotFind              :	XuiMessage (@"HotFind")
    CASE $HotReplace           :	XuiMessage (@"HotReplace")
    CASE $HotToggleBreakpoint  :	XuiMessage (@"HotToggleBreakpoint")
    CASE $HotClearBreakpoints  :	XuiMessage (@"HotClearBreakpoints")
    CASE $HotGui               :	XuiMessage (@"HotToolkit")
    CASE $HotAbort             :	QUIT (0)
    CASE $TextLower            :	XuiMessage (@"TextLower")
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
' *****  TextEvent  *****
'
SUB TextEvent
	key = v2 AND 0x00FF
	IF ((key >= '0') AND (key <= '9')) THEN kid = -1		' kill keystroke
	PRINT "XitMainCode(): TextEvent: Key = "; CHR$(key)
	IF (kid = -1) THEN PRINT "*****  Keystroke Suppressed  *****"
END SUB
END FUNCTION
END PROGRAM

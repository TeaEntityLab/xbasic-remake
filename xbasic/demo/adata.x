'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"adata"
VERSION	"0.0000"
'
IMPORT	"xst"
IMPORT	"xgr"
IMPORT	"xui"
'
' This is a short program that show ways to accomplish certain
' basic data entry techniques.  Most of this program was created
' from a blank slate by "File New GuiProgram" aka ".fn g".
'
' First the simple "Employee" window was layed with components
' from the GuiDesigner toolkit.  Then "Window ToFunction" in the
' GuiDesigner toolkit menu created Employee() and EmployeeCode()
' functions and added them to this program.  Except for the EMPLOYEE
' type declaration below, the only programmer written code is some
' simple data diddling code in EmployeeCode().
'
' All type declarations belong before the first function declaraction,
' so the EMPLOYEE type declaration is right below these comments.
' See EmployeeCode() for some sample code and more comments.
'
' Before you can do much with this program, run it and enter two or
' three fairly complete sets of "employee" information in the window
' that appears and press "Save Employee" when you are done each.
' Once you have saved two or three employee entries, you can try
' out the "Load Employee" capability - enter the first/middle/last
' names in the appropriate places in the window, then select the
' "Load Employee" button.  The data for the employee should appear
' in the window.  If that works, just for fun, enter a correct
' first and last name, but an incorrect middle name and try again.
'
' More notes about this program are in the EmployeeCode() function.
'
'
TYPE EMPLOYEE
	STRING*32			.firstName
	STRING*32			.middleName
  STRING*32			.lastName
	STRING*32			.address1
	STRING*32			.address2
	STRING*32			.city
	STRING*32			.state
	STRING*32			.zip
	STRING*32			.phone
	STRING*32			.fax
	STRING*32			.email
	STRING*32			.web
	STRING*32			.ssn
	STRING*32			.expertise1
	STRING*32			.expertise2
	STRING*32			.expertise3
	STRING*512		.comments
END TYPE
'
INTERNAL FUNCTION  Entry         ()
INTERNAL FUNCTION  InitGui       ()
INTERNAL FUNCTION  InitProgram   ()
INTERNAL FUNCTION  CreateWindows ()
INTERNAL FUNCTION  InitWindows   ()
INTERNAL FUNCTION  Employee      (grid, message, v0, v1, v2, v3, r0, ANY)
INTERNAL FUNCTION  EmployeeCode  (grid, message, v0, v1, v2, v3, kid, ANY)
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
  Employee (@Employee, #CreateWindow, 0, 0, 0, 0, 0, 0)
  XuiSendMessage (Employee, #SetCallback, Employee, &EmployeeCode(), -1, -1, -1, 0)
  XuiSendMessage (Employee, #Initialize, 0, 0, 0, 0, 0, 0)
  XuiSendMessage (Employee, #DisplayWindow, 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' ############################
' #####  InitWindows ()  #####
' ############################
'
FUNCTION  InitWindows ()

END FUNCTION
'
'
'	#########################
'	#####  Employee ()  #####
'	#########################
'
FUNCTION  Employee (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	STATIC  designX,  designY,  designWidth,  designHeight
	STATIC  SUBADDR  sub[]
	STATIC  upperMessage
	STATIC  Employee
'
	$Employee          =   0  ' kid   0 grid type = Employee
	$FirstNameLabel    =   1  ' kid   1 grid type = XuiLabel
	$FirstNameText     =   2  ' kid   2 grid type = XuiTextLine
	$MiddleNameLabel   =   3  ' kid   3 grid type = XuiLabel
	$MiddleNameText    =   4  ' kid   4 grid type = XuiTextLine
	$LastNameLabel     =   5  ' kid   5 grid type = XuiLabel
	$LastNameText      =   6  ' kid   6 grid type = XuiTextLine
	$Address1Label     =   7  ' kid   7 grid type = XuiLabel
	$Address1Text      =   8  ' kid   8 grid type = XuiTextLine
	$Address2Label     =   9  ' kid   9 grid type = XuiLabel
	$Address2Text      =  10  ' kid  10 grid type = XuiTextLine
	$CityLabel         =  11  ' kid  11 grid type = XuiLabel
	$CityText          =  12  ' kid  12 grid type = XuiTextLine
	$StateLabel        =  13  ' kid  13 grid type = XuiLabel
	$StateText         =  14  ' kid  14 grid type = XuiTextLine
	$ZipLabel          =  15  ' kid  15 grid type = XuiLabel
	$ZipText           =  16  ' kid  16 grid type = XuiTextLine
	$PhoneLabel        =  17  ' kid  17 grid type = XuiLabel
	$PhoneText         =  18  ' kid  18 grid type = XuiTextLine
	$FaxLabel          =  19  ' kid  19 grid type = XuiLabel
	$FaxText           =  20  ' kid  20 grid type = XuiTextLine
	$EmailLabel        =  21  ' kid  21 grid type = XuiLabel
	$EmailText         =  22  ' kid  22 grid type = XuiTextLine
	$WebLabel          =  23  ' kid  23 grid type = XuiLabel
	$WebText           =  24  ' kid  24 grid type = XuiTextLine
	$SSNLabel          =  25  ' kid  25 grid type = XuiLabel
	$SSNText           =  26  ' kid  26 grid type = XuiTextLine
	$Expertise1Label   =  27  ' kid  27 grid type = XuiLabel
	$Expertise1Text    =  28  ' kid  28 grid type = XuiTextLine
	$Expertise2Label   =  29  ' kid  29 grid type = XuiLabel
	$Expertise2Text    =  30  ' kid  30 grid type = XuiTextLine
	$Expertise3Label   =  31  ' kid  31 grid type = XuiLabel
	$Expertise3Text    =  32  ' kid  32 grid type = XuiTextLine
	$CommentsLabel     =  33  ' kid  33 grid type = XuiLabel
	$CommentsTextArea  =  34  ' kid  34 grid type = XuiTextArea
	$LoadButton        =  35  ' kid  35 grid type = XuiPushButton
	$SaveButton        =  36  ' kid  36 grid type = XuiPushButton
	$UpperKid          =  36  ' kid maximum
'
'
	IFZ sub[] THEN GOSUB Initialize
'	XuiReportMessage (grid, message, v0, v1, v2, v3, r0, r1)
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, Employee) THEN RETURN
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
	XuiCreateGrid  (@grid, Employee, @v0, @v1, @v2, @v3, r0, r1, &Employee())
	XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"Employee")
	XuiLabel       (@g, #Create, 4, 4, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"FirstNameLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"First Name")
	XuiTextLine    (@g, #Create, 104, 4, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $FirstNameText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"FirstNameText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 28, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"MiddleNameLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Middle Name")
	XuiTextLine    (@g, #Create, 104, 28, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $MiddleNameText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"MiddleNameText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 52, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LastNameLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Last Name")
	XuiTextLine    (@g, #Create, 104, 52, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $LastNameText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LastNameText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 76, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Address1Label")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Address1")
	XuiTextLine    (@g, #Create, 104, 76, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $Address1Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Address1Text")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 100, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Address2Label")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Address2")
	XuiTextLine    (@g, #Create, 104, 100, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $Address2Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Address2Text")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 124, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CityLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"City")
	XuiTextLine    (@g, #Create, 104, 124, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $CityText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CityText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 148, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"StateLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"State")
	XuiTextLine    (@g, #Create, 104, 148, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $StateText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"StateText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 172, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ZipLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Zip")
	XuiTextLine    (@g, #Create, 104, 172, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $ZipText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"ZipText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 196, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PhoneLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Phone")
	XuiTextLine    (@g, #Create, 104, 196, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $PhoneText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"PhoneText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 220, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"FaxLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Fax")
	XuiTextLine    (@g, #Create, 104, 220, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $FaxText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"FaxText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 244, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"EmailLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Email")
	XuiTextLine    (@g, #Create, 104, 244, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $EmailText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"EmailText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 268, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"WebLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Web")
	XuiTextLine    (@g, #Create, 104, 268, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $WebText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"WebText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 292, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SSNLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"SS#")
	XuiTextLine    (@g, #Create, 104, 292, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $SSNText, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SSNText")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 316, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Expertise1Label")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Expertise 1")
	XuiTextLine    (@g, #Create, 104, 316, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $Expertise1Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Expertise1Text")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 340, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Expertise2Label")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Expertise 2")
	XuiTextLine    (@g, #Create, 104, 340, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $Expertise2Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Expertise2Text")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 364, 100, 24, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Expertise3Label")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetAlign, $$AlignMiddleRight, $$JustifyCenter, -1, -1, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Expertise 3")
	XuiTextLine    (@g, #Create, 104, 364, 288, 24, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $Expertise3Text, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"Expertise3Text")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColorExtra, $$BrightGrey, $$LightYellow, $$Black, $$White, 1, 0)
	XuiLabel       (@g, #Create, 4, 388, 388, 32, r0, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CommentsLabel")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColor, $$BrightCyan, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"\x1F Our Comments : Employee Quicky Resume \x1F")
	XuiTextArea    (@g, #Create, 4, 420, 388, 116, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $CommentsTextArea, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"CommentsTextArea")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 1, @"Text")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 2, @"ScrollH")
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 3, @"ScrollV")
	XuiPushButton  (@g, #Create, 4, 536, 196, 32, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $LoadButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"LoadButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColor, 17, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Load Employee")
	XuiPushButton  (@g, #Create, 200, 536, 192, 32, r0, grid)
	XuiSendMessage ( g, #SetCallback, grid, &Employee(), -1, -1, $SaveButton, grid)
	XuiSendMessage ( g, #SetGridName, 0, 0, 0, 0, 0, @"SaveButton")
	XuiSendMessage ( g, #SetStyle, 0, 0, 0, 0, 0, 0)
	XuiSendMessage ( g, #SetColor, $$BrightOrange, $$Black, $$Black, $$White, 0, 0)
	XuiSendMessage ( g, #SetTextString, 0, 0, 0, 0, 0, @"Save Employee")
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
	XuiWindow (window, #WindowRegister, grid, -1, v2, v3, @r0, @"Employee")
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
	IF sub[0] THEN PRINT "Employee() : Initialize : error ::: (undefined message)"
	IF func[0] THEN PRINT "Employee() : Initialize : error ::: (undefined message)"
	XuiRegisterGridType (@Employee, "Employee", &Employee(), @func[], @sub[])
'
' Don't remove the following 4 lines, or WindowFromFunction/WindowToFunction will not work
'
	designX = 880
	designY = 23
	designWidth = 396
	designHeight = 572
'
	gridType = Employee
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
	XuiSetGridTypeValue (gridType, @"focusKid",         $FirstNameText)
	XuiSetGridTypeValue (gridType, @"inputTextArray",   $CommentsTextArea)
	XuiSetGridTypeValue (gridType, @"inputTextString",  $FirstNameText)
	IFZ message THEN RETURN
END SUB
END FUNCTION
'
'
' #############################
' #####  EmployeeCode ()  #####
' #############################
'
FUNCTION  EmployeeCode (grid, message, v0, v1, v2, v3, kid, r1)
	SHARED  terminateProgram
	EMPLOYEE  employee[]
	EMPLOYEE  employee
'
	$Employee          =   0  ' kid   0 grid type = Employee
	$FirstNameLabel    =   1  ' kid   1 grid type = XuiLabel
	$FirstNameText     =   2  ' kid   2 grid type = XuiTextLine
	$MiddleNameLabel   =   3  ' kid   3 grid type = XuiLabel
	$MiddleNameText    =   4  ' kid   4 grid type = XuiTextLine
	$LastNameLabel     =   5  ' kid   5 grid type = XuiLabel
	$LastNameText      =   6  ' kid   6 grid type = XuiTextLine
	$Address1Label     =   7  ' kid   7 grid type = XuiLabel
	$Address1Text      =   8  ' kid   8 grid type = XuiTextLine
	$Address2Label     =   9  ' kid   9 grid type = XuiLabel
	$Address2Text      =  10  ' kid  10 grid type = XuiTextLine
	$CityLabel         =  11  ' kid  11 grid type = XuiLabel
	$CityText          =  12  ' kid  12 grid type = XuiTextLine
	$StateLabel        =  13  ' kid  13 grid type = XuiLabel
	$StateText         =  14  ' kid  14 grid type = XuiTextLine
	$ZipLabel          =  15  ' kid  15 grid type = XuiLabel
	$ZipText           =  16  ' kid  16 grid type = XuiTextLine
	$PhoneLabel        =  17  ' kid  17 grid type = XuiLabel
	$PhoneText         =  18  ' kid  18 grid type = XuiTextLine
	$FaxLabel          =  19  ' kid  19 grid type = XuiLabel
	$FaxText           =  20  ' kid  20 grid type = XuiTextLine
	$EmailLabel        =  21  ' kid  21 grid type = XuiLabel
	$EmailText         =  22  ' kid  22 grid type = XuiTextLine
	$WebLabel          =  23  ' kid  23 grid type = XuiLabel
	$WebText           =  24  ' kid  24 grid type = XuiTextLine
	$SSNLabel          =  25  ' kid  25 grid type = XuiLabel
	$SSNText           =  26  ' kid  26 grid type = XuiTextLine
	$Expertise1Label   =  27  ' kid  27 grid type = XuiLabel
	$Expertise1Text    =  28  ' kid  28 grid type = XuiTextLine
	$Expertise2Label   =  29  ' kid  29 grid type = XuiLabel
	$Expertise2Text    =  30  ' kid  30 grid type = XuiTextLine
	$Expertise3Label   =  31  ' kid  31 grid type = XuiLabel
	$Expertise3Text    =  32  ' kid  32 grid type = XuiTextLine
	$CommentsLabel     =  33  ' kid  33 grid type = XuiLabel
	$CommentsTextArea  =  34  ' kid  34 grid type = XuiTextArea
	$LoadButton        =  35  ' kid  35 grid type = XuiPushButton
	$SaveButton        =  36  ' kid  36 grid type = XuiPushButton
	$UpperKid          =  36  ' kid maximum
'
' enable the following line to see ALL messages this function receives
'
'	XuiReportMessage (grid, message, v0, v1, v2, v3, kid, r1)
'
	IF (message = #Callback) THEN message = r1
'
' I added a #CloseWindow case below so I could minimize the
' window when the user closes the window from the system menu.
' I added a #TextEvent case below so I could move the keyboard
' focus directly to the "Load Employee" or "Save Employee"
' button in response to a Shift+Escape or Escape keystroke.
'
	SELECT CASE message
		CASE #CloseWindow	: GOSUB CloseWindow	' GOSUB CloseWindow
		CASE #Selection		: GOSUB Selection   ' Common callback message
		CASE #TextEvent		: GOSUB TextEvent   ' KeyDown in TextArea or TextLine
	END SELECT
	RETURN
'
'
' *****  CloseWindow  *****
'
SUB CloseWindow
'	XuiSendMessage (grid, #MinimizeWindow, 0, 0, 0, 0, 0, 0)
	terminateProgram = $$TRUE
END SUB
'
'
' *****  TextEvent  *****
'
' Press Control+S to move keyboard focus directly to SaveButton
' Press Control+L to move keyboard focus directly to LoadButton
' Press Control+T to move keyboard focus directly to top = "first name"
' Press EscapeKey to move keyboard focus directly to SaveButton
' Press Shift+EscapeKey to move keyboard focus directly to LoadButton
'
' 0x4C12000C = $$KeyL when $$KeyControl is down
' 0x53120013 = $$KeyS when $$KeyControl is down
' 0x54120014 = $$KeyT when $$KeyControl is down
' 0x1B01001B = $$KeyEscape
' 0x1B10001B = $$KeyEscape when $$KeyShift is down
'
SUB TextEvent
	SELECT CASE v2
		CASE 0x4C12000C	: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $LoadButton, 0)
		CASE 0x53120013	: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $SaveButton, 0)
		CASE 0x54120014	: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $FirstNameText, 0)
		CASE 0x1B01001B : XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $LoadButton, 0)
		CASE 0x1B10001B	: XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $SaveButton, 0)
	END SELECT
END SUB
'
'
' *****  Selection  *****
'
' I added the first three lines to perhaps do what you want.
' I added a short employee load and save subroutine at bottom.
'
' When an Enter key is pressed, a selection callback is produced
' which calls this function and the Selection subroutine below.
' The code I added sends a #KeyboardFocusForward message to the
' grid that received the Enter keystroke, which moves the keyboard
' focus to the next grid.
'
' Just for fun I added the second line below to see whether the
' Control key was down when the Enter keystroke occured.  If it
' was, I make the message #KeyboardFocusBackward.  This give the
' user a way to go backward almost as easily as forward.
'
' In this example, also notice that an Enter keystroke does not
' produce a Selection callback in the multi-line XuiTextArea grid
' at the bottom.  That makes sense of course because the whole
' purpose of a multi-line text grid is to accept multiple lines
' separated by Enter keystrokes.  But then how does the user move
' out of the text area grid?  If the Shift key is down when an
' Enter key is pressed, the Enter key does not insert into the
' text, but a Selection callback message IS produced.  This also
' works in the single line text grids.
'
' In summary, in all applications, the Alt+LeftArrow keystroke
' and Alt+RightArrow keystoke move to the previous and next
' selectable grid.  Get people to accept that convention and
' you need not write any code to deal with this functionality.
' The code below moves the keyboard focus to the next selectable
' grid when an Enter or Shift+Enter keystroke is entered in
' the single line text grids or a Shift+Enter keystroke is
' entered in the multi-line text grid.  The code below moves
' the keyboard focus to the previous selectable grid when a
' Control+Enter keystroke or Control+Shift+Enter keystroke is
' entered in the single line text grids or a Control+Shift+Enter
' keystroke is entered in the multi-line text grid.
'
'
SUB Selection
	mess = #KeyboardFocusForward
	IF (v0 AND $$ControlBit) THEN mess = #KeyboardFocusBackward
	XuiSendMessage (grid, mess, 0, 0, 0, 0, 0, 0)
  SELECT CASE kid
	CASE $Employee          :
	CASE $FirstNameLabel    :
	CASE $FirstNameText     :
	CASE $MiddleNameLabel   :
	CASE $MiddleNameText    :
	CASE $LastNameLabel     :
	CASE $LastNameText      :
	CASE $Address1Label     :
	CASE $Address1Text      :
	CASE $Address2Label     :
	CASE $Address2Text      :
	CASE $CityLabel         :
	CASE $CityText          :
	CASE $StateLabel        :
	CASE $StateText         :
	CASE $ZipLabel          :
	CASE $ZipText           :
	CASE $PhoneLabel        :
	CASE $PhoneText         :
	CASE $FaxLabel          :
	CASE $FaxText           :
	CASE $EmailLabel        :
	CASE $EmailText         :
	CASE $WebLabel          :
	CASE $WebText           :
	CASE $SSNLabel          :
	CASE $SSNText           :
	CASE $Expertise1Label   :
	CASE $Expertise1Text    :
	CASE $Expertise2Label   :
	CASE $Expertise2Text    :
	CASE $Expertise3Label   :
	CASE $Expertise3Text    :
	CASE $CommentsLabel     :
	CASE $CommentsTextArea  :
	CASE $LoadButton        : GOSUB LoadButton
	CASE $SaveButton        : GOSUB SaveButton
	END SELECT
END SUB
'
'
' *****  LoadButton  *****
'
' Loads the data on an employee given only first, middle, last names.
' It loads the employee data base, finds the name, and updates the
' fields in the window.  If this routine doesn't get a match of all
' three name components (first,middle,last), it reports the closest
' match so you can correct your entry if you want.
'
SUB LoadButton
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $FirstNameText, @first$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $MiddleNameText, @middle$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $LastNameText, @last$)
'
	first$ = TRIM$(first$)
	middle$ = TRIM$(middle$)
	last$ = TRIM$(last$)
	ll$ = ""
	mm$ = ""
	ff$ = ""
'
	IFZ last$ THEN
		XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $FirstNameText, 0)
		message$ = "ERROR\n\nNeed At Least\n\nLast Name and First Name"
		XuiMessage (@message$)
		EXIT SUB
	END IF
'
	IFZ first$ THEN
		XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $FirstNameText, 0)
		message$ = "ERROR\n\nNeed At Least\n\nLast Name and First Name"
		XuiMessage (@message$)
		EXIT SUB
	END IF
'
	GOSUB LoadEmployees
	upper = UBOUND (employee[])
'
	quality = 0
	FOR i = 0 TO upper
		f$ = TRIM$(employee[i].firstName)
		m$ = TRIM$(employee[i].middleName)
		l$ = TRIM$(employee[i].lastName)
		found = $$FALSE
		IF (l$ = last$) THEN
			IF (f$ = first$) THEN
				IF (m$ = middle$) THEN							' first, middle, last match
					found = $$TRUE
					employee = employee[i]
					GOSUB LoadEmployee
					quality = 4												' full match
					EXIT FOR
				ELSE																' first, last match
					IF (quality < 3) THEN
						ll$ = l$ : mm$ = m$ : ff$ = f$
						quality = 3
					END IF
				END IF
			ELSE																	' last matches
				IF (quality < 2) THEN
					ll$ = l$ : mm$ = m$ : ff$ = f$
					quality = 2
				END IF
			END IF
		ELSE
			IF (f$ = first$) THEN									' first matches
				IF (quality < 1) THEN
					ll$ = l$ : mm$ = m$ : ff$ = f$
					quality = 1
				END IF
			END IF
		END IF
	NEXT i
'
	SELECT CASE quality
		CASE 4		:	employee = employee[i]
								GOSUB LoadEmployee
		CASE 3		:	name$ = "\"" + first$ + "\"  :  \"" + middle$ + "\"  :  \"" + last$ + "\""
								message$ = "ERROR\n\n" + name$ + "\n\n" + "Not Found\n\nBut The Following Name Is Close\n\n\"" + ff$ + "\"  :  \"" + mm$ + "\"  :  \"" + ll$ + "\""
								XuiMessage (@message$)
		CASE 2		:	name$ = "\"" + first$ + "\"  :  \"" + middle$ + "\"  :  \"" + last$ + "\""
								message$ = "ERROR\n\n" + name$ + "\n\n" + "Not Found\n\nBut The Following Last Name Matches\n\n\"" + ff$ + "\"  :  \"" + mm$ + "\"  :  \"" + ll$ + "\""
								XuiMessage (@message$)
		CASE 1		:	name$ = "\"" + first$ + "\"  :  \"" + middle$ + "\"  :  \"" + last$ + "\""
								message$ = "ERROR\n\n" + name$ + "\n\n" + "Not Found\n\nBut The Following First Name Matches\n\n\"" + ff$ + "\"  :  \"" + mm$ + "\"  :  \"" + ll$ + "\""
								XuiMessage (@message$)
		CASE ELSE	:	name$ = "\"" + first$ + "\"  :  \"" + middle$ + "\"  :  \"" + last$ + "\""
								message$ = "ERROR\n\n" + name$ + "\n\n" + "Not Found"
								XuiMessage (@message$)
	END SELECT
'
	XuiSendMessage (grid, #SetKeyboardFocus, 0, 0, 0, 0, $FirstNameText, 0)
END SUB
'
'
' *****  SaveButton  *****
'
' If the employee name in the window matches one of the employee names
' in the employee[] array, update that entry in the employee[] array,
' otherwise increase the size of the employee[] array by one element
' and save the new employee name and information in that new element.
' Then save the employee[] array to disk as file "employee.dat".
'
SUB SaveButton
	found = $$FALSE
	GOSUB GetEmployee
	GOSUB LoadEmployees
	upper = UBOUND (employee[])
'
	FOR i = 0 TO upper
		f$ = TRIM$(employee[i].firstName)
		m$ = TRIM$(employee[i].middleName)
		l$ = TRIM$(employee[i].lastName)
		IF (f$ = firstName$) THEN
			IF (m$ = middleName$) THEN
				IF (l$ = lastName$) THEN
					employee[i] = employee		' update existing employee
					found = $$TRUE
				END IF
			END IF
		END IF
	NEXT i
'
	IFZ found THEN
		upper = upper + 1
		REDIM employee[upper]
		employee[upper] = employee			' new entry
	END IF
	GOSUB SaveEmployees
END SUB
'
'
' *****  LoadEmployee  *****
'
' Put the contents of the employee variable into the approriate grids
' in the window, then redraw the window so they become visible.
'
SUB LoadEmployee
	comments$ = TRIM$(employee.comments)
	XstStringToStringArray (@comments$, @comments$[])
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $FirstNameText, TRIM$(employee.firstName))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $MiddleNameText, TRIM$(employee.middleName))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $LastNameText, TRIM$(employee.lastName))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Address1Text, TRIM$(employee.address1))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Address2Text, TRIM$(employee.address2))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $CityText, TRIM$(employee.city))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $StateText, TRIM$(employee.state))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $ZipText, TRIM$(employee.zip))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $PhoneText, TRIM$(employee.phone))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $FaxText, TRIM$(employee.fax))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $EmailText, TRIM$(employee.email))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $WebText, TRIM$(employee.web))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $SSNText, TRIM$(employee.ssn))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Expertise1Text, TRIM$(employee.expertise1))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Expertise2Text, TRIM$(employee.expertise2))
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, $Expertise3Text, TRIM$(employee.expertise3))
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, $CommentsTextArea, @comments$[])
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, 0, 0)
END SUB
'
'
' *****  GetEmployee  *****
'
' Get the employee information from the appropriate grids
' in the window and assign them to the employee variable.
'
SUB GetEmployee
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $FirstNameText, @firstName$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $MiddleNameText, @middleName$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $LastNameText, @lastName$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $Address1Text, @address1$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $Address2Text, @address2$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $CityText, @city$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $StateText, @state$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $ZipText, @zip$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $PhoneText, @phone$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $FaxText, @fax$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $EmailText, @email$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $WebText, @web$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $SSNText, @ssn$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $Expertise1Text, @expertise1$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $Expertise2Text, @expertise2$)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $Expertise3Text, @expertise3$)
	XuiSendMessage (grid, #GetTextArray, 0, 0, 0, 0, $CommentsTextArea, @comments$[])
	XstStringArrayToString (@comments$[], @comments$)
	employee.firstName = firstName$
	employee.middleName = middleName$
	employee.lastName = lastName$
	employee.address1 = address1$
	employee.address2 = address2$
	employee.city = city$
	employee.state = state$
	employee.zip = zip$
	employee.phone = phone$
	employee.fax = fax$
	employee.email = email$
	employee.web = web$
	employee.ssn = ssn$
	employee.expertise1 = expertise1$
	employee.expertise2 = expertise2$
	employee.expertise3 = expertise3$
	employee.comments = comments$
END SUB
'
'
' *****  LoadEmployees  *****
'
' Load the "database" of employees into the employee[] array.
'
SUB LoadEmployees
	ifile = OPEN ("employee.dat", $$RD)
	IF (ifile < 0) THEN
		message$ = "ERROR\n\nCould Not Find File\n\nemployee.dat"
		XuiMessage (@message$)
		EXIT SUB
	END IF
'
	length = LOF (ifile)
	size = SIZE (employee)
	count = length \ size
	check = count * size
	IF (check != length) THEN
		message$ = "ERROR\n\nLength of File\n\nemployee.dat\n\nNot A Multiple\nOf SIZE(employee)"
		XuiMessage (@message$)
		CLOSE (ifile)
		EXIT SUB
	END IF
'
	upper = count - 1
	DIM employee[upper]
	READ [ifile], employee[]
	CLOSE (ifile)
END SUB
'
'
' *****  SaveEmployees  *****
'
' Rename the existing "employee.dat" file to "employee.bak",
' then save the employee[] array as file "employee.dat".
'
SUB SaveEmployees
	XstDeleteFile (@"\\xb\\employee.bak")
	XstRenameFile (@"\\xb\\employee.dat", @"\\xb\\employee.bak")
'
	ofile = OPEN ("employee.dat", $$WRNEW)
	IF (ofile < 3) THEN
		message$ = "ERROR\n\nCannot Open File\n\nemployee.dat"
		XuiMessage (@message$)
	ELSE
		WRITE [ofile], employee[]
		CLOSE (ofile)
	END IF
END SUB
END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "aeditors"
VERSION "0.0000"
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
' This program is a "GuiDesigner convenience function program"
' version of "editors.x", which does the same thing but is written
' as a "conventional GuiDesigner" program.
'
INTERNAL FUNCTION  Entry        ()
INTERNAL FUNCTION  CloseWindow  (grid)
INTERNAL FUNCTION  CreateWindow (grid, v0, v1)
INTERNAL FUNCTION  File         (grid, v0, v1, kid)
INTERNAL FUNCTION  FileLoad     (grid)
INTERNAL FUNCTION  FileSave     (grid)
INTERNAL FUNCTION  FileQuit     (grid)
INTERNAL FUNCTION  Edit         (grid, v0, v1, kid)
INTERNAL FUNCTION  EditCut      (grid)
INTERNAL FUNCTION  EditGrab     (grid)
INTERNAL FUNCTION  EditPaste    (grid)
INTERNAL FUNCTION  EditErase    (grid)
'
'
' ###################
' #####  Entry  #####
' ###################
'
FUNCTION  Entry ()
  SHARED  count
'
  $Edit      =   0  ' kid   0 grid type = XuiMenuTextArea1B
  $Menu      =   1  ' kid   1 grid type = XuiMenu
  $Text      =   2  ' kid   2 grid type = XuiTextArea
  $Button    =   3  ' kid   3 grid type = XuiPushButton
  $UpperKid  =   3  ' kid maximum
'
' get information about the display, windows, and execution environment
'
  XgrGetDisplaySize ("", @dw, @dh, @wbw, @wth)
	XstGetApplicationEnvironment (@standalone, 0)
'
' standalone programs don't want the console
'
	IF standalone THEN
		XstGetConsoleGrid (@grid)
		XuiSendStringMessage (grid, "HideWindow", 0, 0, 0, 0, 0, 0)
	END IF
'
' create an initial "editor" window
'
  CreateWindow (@grid, wbw, wbw+wth)
'
' convenience function message loop
'
  DO
    XgrProcessMessages (1)
    DO WHILE XuiGetNextCallback (@grid, @message$, @v0, @v1, @v2, @v3, @kid, @r1$)
      GOSUB Callback
    LOOP
  LOOP
  RETURN
'
' *****  Callback  *****
'
SUB Callback
  win = kid >> 16
  kid = kid AND 0xFF
  SELECT CASE message$
    CASE "CloseWindow" : GOSUB CloseWindow
    CASE "Selection"   : GOSUB Selection
  END SELECT
END SUB
'
'
' *****  CloseWindow  *****
'
SUB CloseWindow
  DEC count
  XuiSendStringMessage (grid, "DestroyWindow", 0, 0, 0, 0, 0, 0)
  IF (count < 0) THEN QUIT (0)
END SUB
'
'
' *****  Selection  *****
'
SUB Selection
  SELECT CASE kid
    CASE $Edit    :
    CASE $Menu    : GOSUB Menu
    CASE $Text    :
    CASE $Button  : GOSUB Another
  END SELECT
END SUB
'
'
' *****  Menu  *****
'
SUB Menu
  SELECT CASE v0
    CASE 1  : File (grid, v0, v1, kid)
    CASE 2  : Edit (grid, v0, v1, kid)
  END SELECT
END SUB
'
'
' *****  Another  *****
'
SUB Another
  INC count
  XuiSendStringMessage (grid, @"GetWindowSize", @wx, @wy, 0, 0, 0, 0)
  CreateWindow (@g, wx+wbw, wy+wbw+wth)
END SUB
END FUNCTION
'
'
' ############################
' #####  CloseWindow ()  #####
' ############################
'
FUNCTION  CloseWindow (grid)
  SHARED  count
'
  DEC count
  XuiSendStringMessage (grid, "DestroyWindow", 0, 0, 0, 0, 0, 0)
  IF (count < 0) THEN QUIT (0)
END FUNCTION
'
'
' #############################
' #####  CreateWindow ()  #####
' #############################
'
FUNCTION  CreateWindow (grid, v0, v1)
'
  XuiCreateWindow      (@grid, @"XuiMenuTextArea1B", v0, v1, 0, 0, 0, "")
  XuiSendStringMessage ( grid, @"SetCallback", grid, &XuiQueueCallbacks(), -1, -1, 0, -1)
  XuiSendStringMessage ( grid, @"SetWindowTitle", 0, 0, 0, 0, 0, @"Editor")
  XuiSendStringMessage ( grid, @"SetGridName", 0, 0, 0, 0, 0, @"Editor")
  XuiSendStringMessage ( grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)
END FUNCTION
'
'
' #####################
' #####  File ()  #####
' #####################
'
FUNCTION  File (grid, v0, v1, kid)
'
  SELECT CASE v1
    CASE 0  : FileLoad (grid)
    CASE 1  : FileSave (grid)
    CASE 2  : FileQuit (grid)
  END SELECT
END FUNCTION
'
'
' #########################
' #####  FileLoad ()  #####
' #########################
'
FUNCTION  FileLoad (grid)
'
  gridType$ = "XuiFile"
  title$ = "Select File"
  message$ = ""
  strings$ = ""
  reply$ = ""
  XuiGetResponse (@gridType$, @title$, @message$, @strings$, @v0, @v1, @kid, @reply$)
  IF reply$ THEN
    XstLoadStringArray (@reply$, @text$[])
    XuiSendStringMessage (grid, "SetTextArray", 0, 0, 0, 0, 2, @text$[])
    XuiSendStringMessage (grid, "Redraw", 0, 0, 0, 0, 0, 0)
  END IF
END FUNCTION
'
'
' #########################
' #####  FileSave ()  #####
' #########################
'
FUNCTION  FileSave (grid)
'
  gridType$ = "XuiFile"
  title$ = "Select File"
  message$ = ""
  strings$ = ""
  reply$ = ""
  XuiGetResponse (@gridType$, @title$, @message$, @strings$, @v0, @v1, @kid, @reply$)
  IF reply$ THEN
    XuiSendStringMessage (grid, "GetTextArray", 0, 0, 0, 0, 2, @text$[])
    XstSaveStringArray (@reply$, @text$[])
  END IF
END FUNCTION
'
'
' #########################
' #####  FileQuit ()  #####
' #########################
'
FUNCTION  FileQuit (grid)
  CloseWindow (grid)
END FUNCTION
'
'
' #####################
' #####  Edit ()  #####
' #####################
'
FUNCTION  Edit (grid, v0, v1, kid)
'
  SELECT CASE v1
    CASE 0  : EditCut (grid)
    CASE 1  : EditGrab (grid)
    CASE 2  : EditPaste (grid)
    CASE 3  : EditErase (grid)
  END SELECT
END FUNCTION
'
'
' ########################
' #####  EditCut ()  #####
' ########################
'
FUNCTION  EditCut (grid)
	UBYTE  null[]
'
	XgrGetTextSelectionGrid (@g)
	IF g THEN
		XuiSendStringMessage (g, "GetTextSelection", @begPos, @begLine, @endPos, @endLine, 0, @text$)
		IFZ text$ THEN RETURN
		XgrSetClipboard (0, $$ClipboardTypeText, @text$, @null[])
		XuiSendStringMessage (g, "TextReplace", begPos, begLine, endPos, endLine, 0, "")
		XuiSendStringMessage (g, "RedrawText", 0, 0, 0, 0, 0, 0)
	END IF
END FUNCTION
'
'
' #########################
' #####  EditGrab ()  #####
' #########################
'
FUNCTION  EditGrab (grid)
	UBYTE  null[]
'
	XgrGetTextSelectionGrid (@g)
	IF g THEN
		XuiSendStringMessage (g, "GetTextSelection", 0, 0, 0, 0, 0, @text$)
		XuiSendStringMessage (g, "RedrawText", 0, 0, $$SelectCancel, 0, 0, 0)
		IF text$ THEN XgrSetClipboard (0, $$ClipboardTypeText, @text$, @null[])
	END IF
END FUNCTION
'
'
' ##########################
' #####  EditPaste ()  #####
' ##########################
'
FUNCTION  EditPaste (grid)
	UBYTE  null[]
'
	XgrGetClipboard (0, $$ClipboardTypeText, @text$, @null[])
	IF text$ THEN
		XgrGetSelectedWindow (@window)
		XgrSendStringMessage (window, "WindowGetKeyboardFocusGrid", @g, 0, 0, 0, 0, 0)
		IF g THEN
			XuiSendStringMessage (g, "GetTextCursor", @cursorPos, @cursorLine, 0, 0, 0, 0)
			XuiSendStringMessage (g, "TextReplace", cursorPos, cursorLine, cursorPos, cursorLine, 0, @text$)
			XuiSendStringMessage (g, "RedrawText", 0, 0, 0, 0, 0, 0)
		END IF
	END IF
END FUNCTION
'
'
' ##########################
' #####  EditErase ()  #####
' ##########################
'
FUNCTION  EditErase (grid)
'
	XgrGetTextSelectionGrid (@g)
	IF g THEN
		XuiSendStringMessage (g, "GetTextSelection", @begPos, @begLine, @endPos, @endLine, 0, @text$)
		IFZ text$ THEN RETURN
		XuiSendStringMessage (g, "TextReplace", begPos, begLine, endPos, endLine, 0, "")
		XuiSendStringMessage (g, "RedrawText", 0, 0, 0, 0, 0, 0)
	END IF
END FUNCTION
END PROGRAM

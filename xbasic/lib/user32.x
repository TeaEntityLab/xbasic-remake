'
' ####################
' #####  PROLOG  #####
' ####################
'
' This program implements part of the user32 portion of the
' Microsoft Windows Win32 API for UNIX programs.
'
' Ideally portable programs should not call UNIX, X-Windows,
' or Windows functions directly.  Some programs that do call
' UNIX, XWindows, or Windows functions are still portable,
' however, because of cross-platform compatibility libraries
' like this one.  These libraries work in a simple manner.
'
' When a program running on Windows/WindowsNT calls a Windows
' API function, the Windows API function is directly invoked.
' When the same program running on UNIX calls a Windows API
' function, the Windows API function does not exist, but a
' function in this library with the same name does, and is
' thus invoked in the same manner as the Windows function.
' The substitute function in this library tries to perform
' the same service as the Windows API function, and in most
' cases there is little or no difference.
'
' The cross-platform compatibility libraries do not contain
' every Windows API function, and not every included function
' performs the exact same action or returns the same result.
' Some cross-platform compatibility functions exist, but do
' nothing at all (except perhaps return an error indication),
' though their inclusion does make it possible to at least
' run programs that call them.
'
' This library is FAR from complete at this time, but updates
' are expected on a regular basis.  Please give us feedback.
'
PROGRAM "user32"
VERSION "0.0000"
'
IMPORT  "clib"
IMPORT  "xwin"
'
EXPORT
TYPE WNDCLASS
  XLONG  .style
  XLONG  .lpfnWndProc
  XLONG  .cbClsExtra
  XLONG  .cbWndExtra
  XLONG  .hInstance
  XLONG  .hIcon
  XLONG  .hCursor
  XLONG  .hbrBackground
  XLONG  .lpszMenuName
  XLONG  .lpszClassName
END TYPE
'
DECLARE FUNCTION  AdjustWindowRectEx (rect, style, menu, moreStyle)
DECLARE FUNCTION  BringWindowToTop (hwnd)
DECLARE FUNCTION  ClientToScreen (hwnd, point)
DECLARE FUNCTION  CloseClipboard ()
DECLARE FUNCTION  CreateWindowExA (styleEx, className, windowName, style, x, y, w, h, owner, menu, inst, param)
DECLARE FUNCTION  DefWindowProcA (hwnd, message, wParam, lParam)
DECLARE FUNCTION  DestroyWindow (hwnd)
DECLARE FUNCTION  DispatchMessageA (msg)
DECLARE FUNCTION  DrawIcon (hdc, x, y, hIcon)
DECLARE FUNCTION  EmptyClipboard ()
DECLARE FUNCTION  EnableWindow (hwnd, enable)
DECLARE FUNCTION  FillRect (hdc, rect, hbrush)
DECLARE FUNCTION  GetAsyncKeyState (key)
DECLARE FUNCTION  GetCapture ()
DECLARE FUNCTION  GetClientRect (hwnd, addrRect)
DECLARE FUNCTION  GetClipboardData (format)
DECLARE FUNCTION  GetCursorPos (point)
DECLARE FUNCTION  GetDC (hwnd)
DECLARE FUNCTION  GetKeyState (key)
DECLARE FUNCTION  GetQueueStatus (flags)
DECLARE FUNCTION  GetSystemMetrics (nIndex)
DECLARE FUNCTION  GetUpdateRect (hwnd, rect, erase)
DECLARE FUNCTION  GetWindowTextA (hwnd, lpText, nMaxCount)
DECLARE FUNCTION  GetWindowTextLengthA (hwnd)
DECLARE FUNCTION  IsClipboardFormatAvailable (format)
DECLARE FUNCTION  IsIconic (hwnd)
DECLARE FUNCTION  IsZoomed (hwnd)
DECLARE FUNCTION  KillTimer (hwnd, timer)
DECLARE FUNCTION  LoadCursorA (hInst, lpszCursor)
DECLARE FUNCTION  LoadIconA (hInst, lpszIcon)
DECLARE FUNCTION  MessageBeep (type)
DECLARE FUNCTION  MoveWindow (hwnd, x, y, nWidth, nHeight, bRepaint)
DECLARE FUNCTION  OpenClipboard (handle)
DECLARE FUNCTION  PeekMessageA (lpmsg, hwnd, wMsgFilterMin, wMsgFilterMax, fuRemoveMsg)
DECLARE FUNCTION  RegisterClassA (WNDCLASS class)
DECLARE FUNCTION  ReleaseCapture ()
DECLARE FUNCTION  ReleaseDC (hwnd, hdc)
DECLARE FUNCTION  ScreenToClient (hwnd, point)
DECLARE FUNCTION  SetActiveWindow (hwnd)
DECLARE FUNCTION  SetCapture (hwnd)
DECLARE FUNCTION  SetClipboardData (format, handle)
DECLARE FUNCTION  SetCursor (hCursor)
DECLARE FUNCTION  SetFocus (hwnd)
DECLARE FUNCTION  SetTimer (hwnd, timer, msec, callFunc)
DECLARE FUNCTION  SetWindowPos (hwnd, stackAction, x, y, cx, cy, action)
DECLARE FUNCTION  SetWindowTextA (hwnd, lpszText)
DECLARE FUNCTION  ShowWindow (hwnd, show)
DECLARE FUNCTION  TranslateMessage (msg)
DECLARE FUNCTION  UpdateWindow (hwnd)
DECLARE FUNCTION  ValidateRect (hwnd, rect)
DECLARE FUNCTION  WaitMessage ()
END EXPORT
'
'
' ###################################
' #####  AdjustWindowRectEx ()  #####
' ###################################
'
FUNCTION  AdjustWindowRectEx (rect, style, menu, moreStyle)
'
'	PRINT "User32 : AdjustWindowRectEx()"
'
END FUNCTION
'
'
' #################################
' #####  BringWindowToTop ()  #####
' #################################
'
FUNCTION  BringWindowToTop (hwnd)
'
'	PRINT "User32 : BringWindowToTop()"
'
END FUNCTION
'
'
' ###############################
' #####  ClientToScreen ()  #####
' ###############################
'
FUNCTION  ClientToScreen (hwnd, point)
'
'	PRINT "User32 : ClientToScreen()"
'
END FUNCTION
'
'
' ###############################
' #####  CloseClipboard ()  #####
' ###############################
'
FUNCTION  CloseClipboard ()
'
'	PRINT "User32 : CloseClipboard()"
'
END FUNCTION
'
'
' ################################
' #####  CreateWindowExA ()  #####
' ################################
'
FUNCTION  CreateWindowExA (styleEx, className, windowName, style, x, y, w, h, owner, menu, inst, param)
'
'	PRINT "User32 : CreateWindowExA()"
'
END FUNCTION
'
'
' ###############################
' #####  DefWindowProcA ()  #####
' ###############################
'
FUNCTION  DefWindowProcA (hwnd, message, wParam, lParam)
'
'	PRINT "User32 : DefWindowProcA()"
'
END FUNCTION
'
'
' ###############################
' #####  DestroyWindow ()  ######
' ###############################
'
FUNCTION  DestroyWindow (hwnd)
'
'	PRINT "User32 : DestroyWindow()"
'
END FUNCTION
'
'
' #################################
' #####  DispatchMessageA ()  #####
' #################################
'
FUNCTION  DispatchMessageA (msg)
'
'	PRINT "User32 : DispatchMessageA()"
'
END FUNCTION
'
'
' #########################
' #####  DrawIcon ()  #####
' #########################
'
FUNCTION  DrawIcon (hdc, x, y, hIcon)
'
'	PRINT "User32 : DrawIcon()"
'
END FUNCTION
'
'
' ###############################
' #####  EmptyClipboard ()  #####
' ###############################
'
FUNCTION  EmptyClipboard ()
'
'	PRINT "User32 : EmptyClipboard()"
'
END FUNCTION
'
'
' #############################
' #####  EnableWindow ()  #####
' #############################
'
FUNCTION  EnableWindow (hwnd, enable)
'
'	PRINT "User32 : EnableWindow()"
'
END FUNCTION
'
'
' #########################
' #####  FillRect ()  #####
' #########################
'
FUNCTION  FillRect (hdc, rect, hbrush)
'
'	PRINT "User32 : FillRect()"
'
END FUNCTION
'
'
' #################################
' #####  GetAsyncKeyState ()  #####
' #################################
'
FUNCTION  GetAsyncKeyState (key)
'
'	PRINT "User32 : GetAsyncKeyState()"
'
END FUNCTION
'
'
' ###########################
' #####  GetCapture ()  #####
' ###########################
'
FUNCTION  GetCapture ()
'
'	PRINT "User32 : GetCapture()"
'
END FUNCTION
'
'
' ##############################
' #####  GetClientRect ()  #####
' ##############################
'
FUNCTION  GetClientRect (hwnd, addrRect)
'
'	PRINT "User32 : GetClientRect()"
'
END FUNCTION
'
'
' #################################
' #####  GetClipboardData ()  #####
' #################################
'
FUNCTION  GetClipboardData (format)
'
'	PRINT "User32 : GetClipboardData()"
'
END FUNCTION
'
'
' #############################
' #####  GetCursorPos ()  #####
' #############################
'
FUNCTION  GetCursorPos (point)
'
'	PRINT "User32 : GetCursorPos()"
'
END FUNCTION
'
'
' ######################
' #####  GetDC ()  #####
' ######################
'
FUNCTION  GetDC (hwnd)
'
'	PRINT "User32 : GetDC()"
'
END FUNCTION
'
'
' ############################
' #####  GetKeyState ()  #####
' ############################
'
FUNCTION  GetKeyState (key)
'
'	PRINT "User32 : GetKeyState()"
'
END FUNCTION
'
'
' ###############################
' #####  GetQueueStatus ()  #####
' ###############################
'
FUNCTION  GetQueueStatus (flags)
'
'	PRINT "User32 : GetQueueStatus()"
'
END FUNCTION
'
'
' #################################
' #####  GetSystemMetrics ()  #####
' #################################
'
FUNCTION  GetSystemMetrics (nIndex)
'
'	PRINT "User32 : GetSystemMetrics()"
'
END FUNCTION
'
'
' ##############################
' #####  GetUpdateRect ()  #####
' ##############################
'
FUNCTION  GetUpdateRect (hwnd, rect, erase)
'
'	PRINT "User32 : GetUpdateRect()"
'
END FUNCTION
'
'
' ###############################
' #####  GetWindowTextA ()  #####
' ###############################
'
FUNCTION  GetWindowTextA (hwnd, lpText, nMaxCount)
'
'	PRINT "User32 : GetWindowTextA()"
'
END FUNCTION
'
'
' #####################################
' #####  GetWindowTextLengthA ()  #####
' #####################################
'
FUNCTION  GetWindowTextLengthA (hwnd)
'
'	PRINT "User32 : GetWindowTextLengthA()"
'
END FUNCTION
'
'
' ###########################################
' #####  IsClipboardFormatAvailable ()  #####
' ###########################################
'
FUNCTION  IsClipboardFormatAvailable (format)
'
'	PRINT "User32 : IsClipboardFormatAvailable()"
'
END FUNCTION
'
'
' #########################
' #####  IsIconic ()  #####
' #########################
'
FUNCTION  IsIconic (hwnd)
'
'	PRINT "User32 : IsIconic()"
'
END FUNCTION
'
'
' #########################
' #####  IsZoomed ()  #####
' #########################
'
FUNCTION  IsZoomed (hwnd)
'
'	PRINT "User32 : IsZoomed()"
'
END FUNCTION
'
'
' ##########################
' #####  KillTimer ()  #####
' ##########################
'
FUNCTION  KillTimer (hwnd, timer)
'
'	PRINT "User32 : KillTimer()"
'
END FUNCTION
'
'
' ############################
' #####  LoadCursorA ()  #####
' ############################
'
FUNCTION  LoadCursorA (hInst, lpszCursor)
'
'	PRINT "User32 : LoadCursorA()"
'
END FUNCTION
'
'
' ##########################
' #####  LoadIconA ()  #####
' ##########################
'
FUNCTION  LoadIconA (hInst, lpszIcon)
'
'	PRINT "User32 : LoadIconA()"
'
END FUNCTION
'
'
' ############################
' #####  MessageBeep ()  #####
' ############################
'
FUNCTION  MessageBeep (type)
'
'	PRINT "User32 : MessageBeep()"
'
END FUNCTION
'
'
' ###########################
' #####  MoveWindow ()  #####
' ###########################
'
FUNCTION  MoveWindow (hwnd, x, y, nWidth, nHeight, bRepaint)
'
'	PRINT "User32 : MoveWindow()"
'
END FUNCTION
'
'
' ##############################
' #####  OpenClipboard ()  #####
' ##############################
'
FUNCTION  OpenClipboard (handle)
'
'	PRINT "User32 : OpenClipboard()"
'
END FUNCTION
'
'
' #############################
' #####  PeekMessageA ()  #####
' #############################
'
FUNCTION  PeekMessageA (lpmsg, hwnd, wMsgFilterMin, wMsgFilterMax, fuRemoveMsg)
'
'	PRINT "User32 : PeekMessageA()"
'
END FUNCTION
'
'
' ###############################
' #####  RegisterClassA ()  #####
' ###############################
'
FUNCTION  RegisterClassA (WNDCLASS class)
'
'	PRINT "User32 : RegisterClassA()"
'
END FUNCTION
'
'
' ###############################
' #####  ReleaseCapture ()  #####
' ###############################
'
FUNCTION  ReleaseCapture ()
'
'	PRINT "User32 : ReleaseCapture()"
'
END FUNCTION
'
'
' ##########################
' #####  ReleaseDC ()  #####
' ##########################
'
FUNCTION  ReleaseDC (hwnd, hdc)
'
'	PRINT "User32 : ReleaseDC()"
'
END FUNCTION
'
'
' ###############################
' #####  ScreenToClient ()  #####
' ###############################
'
FUNCTION  ScreenToClient (hwnd, point)
'
'	PRINT "User32 : ScreenToClient()"
'
END FUNCTION
'
'
' ################################
' #####  SetActiveWindow ()  #####
' ################################
'
FUNCTION  SetActiveWindow (hwnd)
'
'	PRINT "User32 : SetActiveWindow()"
'
END FUNCTION
'
'
' ###########################
' #####  SetCapture ()  #####
' ###########################
'
FUNCTION  SetCapture (hwnd)
'
'	PRINT "User32 : SetCapture()"
'
END FUNCTION
'
'
' #################################
' #####  SetClipboardData ()  #####
' #################################
'
FUNCTION  SetClipboardData (format, handle)
'
'	PRINT "User32 : SetClipboardData()"
'
END FUNCTION
'
'
' ##########################
' #####  SetCursor ()  #####
' ##########################
'
FUNCTION  SetCursor (hCursor)
'
'	PRINT "User32 : SetCursor()"
'
END FUNCTION
'
'
' #########################
' #####  SetFocus ()  #####
' #########################
'
FUNCTION  SetFocus (hwnd)
'
'	PRINT "User32 : SetFocus()"
'
END FUNCTION
'
'
' #########################
' #####  SetTimer ()  #####
' #########################
'
FUNCTION  SetTimer (hwnd, timer, msec, callFunc)
'
'	PRINT "User32 : SetTimer()"
'
END FUNCTION
'
'
' #############################
' #####  SetWindowPos ()  #####
' #############################
'
FUNCTION  SetWindowPos (hwnd, stackAction, x, y, cx, cy, action)
'
'	PRINT "User32 : SetWindowPos()"
'
END FUNCTION
'
'
' ###############################
' #####  SetWindowTextA ()  #####
' ###############################
'
FUNCTION  SetWindowTextA (hwnd, lpszText)
'
'	PRINT "User32 : SetWindowTextA()"
'
END FUNCTION
'
'
' ###########################
' #####  ShowWindow ()  #####
' ###########################
'
FUNCTION  ShowWindow (hwnd, show)
'
'	PRINT "User32 : ShowWindow()"
'
END FUNCTION
'
'
' #################################
' #####  TranslateMessage ()  #####
' #################################
'
FUNCTION  TranslateMessage (msg)
'
'	PRINT "User32 : TranslateMessage()"
'
END FUNCTION
'
'
' #############################
' #####  UpdateWindow ()  #####
' #############################
'
FUNCTION  UpdateWindow (hwnd)
'
'	PRINT "User32 : UpdateWindow()"
'
END FUNCTION
'
'
' #############################
' #####  ValidateRect ()  #####
' #############################
'
FUNCTION  ValidateRect (hwnd, rect)
'
'	PRINT "User32 : ValidateRect()"
'
END FUNCTION
'
'
' ############################
' #####  WaitMessage ()  #####
' ############################
'
FUNCTION  WaitMessage ()
'
'	PRINT "User32 : WaitMessage()"
'
END FUNCTION
END PROGRAM

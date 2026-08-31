'
' ####################
' #####  PROLOG  #####
' ####################
'
' This program gets the contents of the system clipboard twice and
' prints it in the console window.  First it calls a GraphicsDesigner
' function to get the clipboard text.  Then it calls the GetClipText()
' function to get the clipboard text.  GetClipText() calls Windows API
' functions to accomplish its mission, which demonstrates the process
' of calling API functions.  The API functions are in the "user32" and
' "kernel32" libraries, which means they need to be imported - which
' they are in two of the IMPORT statements below.  "xgr" is imported
' because XgrGetClipboard() is part of the GraphicsDesigner library.
'
' Make sure you've got text in the clipboard or this will be BORING !!!
'
PROGRAM "api"
VERSION "0.0001"
'
IMPORT	"xgr"   		' GraphicsDesigner
IMPORT	"user32"		' Windows API
IMPORT	"kernel32"	' Windows API
'
DECLARE  FUNCTION  Entry       ()
INTERNAL FUNCTION  GetClipText (@text$)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	UBYTE  image[]
'
	PRINT
	PRINT "#####  program started  #####"
	text$ = ""
	DIM image[]
	PRINT "*****  XgrGetClipboard(0)  *****"
	XgrGetClipboard (0, $$ClipTypeText, @text$, @image[])
	PRINT "<"; text$; ">", UBOUND (image[])
'
	text$ = ""
	DIM image[]
	PRINT "*****  XgrGetClipboard(1)  *****"
	XgrGetClipboard (1, $$ClipTypeText, @text$, @image[])
	PRINT "<"; text$; ">", UBOUND (image[])
'
	text$ = ""
	DIM image[]
	PRINT "*****  Windows API funcs  *****"
	GetClipText (@text$)
	PRINT "<"; text$; ">", UBOUND (image[])
'
	PRINT "#####  program completed  #####"
END FUNCTION
'
'
' ############################
' #####  GetClipText ()  #####
' ############################
'
FUNCTION  GetClipText (text$)
	$Text = 1
'
	text$ = ""															' default text$ is empty
	ok = OpenClipboard (0)									' open clipboard
	IFZ ok THEN CloseClipboard() : RETURN		' bad clipboard
	handle = GetClipboardData ($Text)				' get clipboard data handle
	IF (handle <= 0) THEN CloseClipboard() : RETURN	' bad handle
	IFZ handle THEN RETURN													' no text in clipboard
	addr = GlobalLock (handle)											' get address of text
	IFZ addr THEN CloseClipboard() : RETURN					' bad address
	upper = GlobalSize (handle)											' get upper bound of text$
	IF (upper <= 0) THEN CloseClipboard() : RETURN	' valid size ???
	text$ = NULL$(upper)										' create return string
	d = -1																	' destination offset
	lastByte = 0														' nothing to start
	FOR s = 0 TO upper											' for whole loop
		byte = UBYTEAT (addr, s)							' get next byte
		IFZ byte THEN EXIT FOR								' done on null terminator
		IF (byte = '\n') THEN									' if this byte is a newline
			IF (lastByte = '\r') THEN DEC d			' overwrite if lastByte was a <cr>
		END IF																'
		INC d
		text${d} = byte												' byte to text string
		lastByte = byte												' lastByte = this byte
	NEXT s																	' next source byte
	text$ = LEFT$(text$,d+1)								' give text$ correct length
	CloseClipboard ()
END FUNCTION
END PROGRAM

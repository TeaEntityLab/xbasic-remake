'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "hello"
VERSION "0.0000"
'
' To see how to make this a standalone program,
' click on "Help" in the main menu and then
' click on "Help Index"
' In the Help Index window, start typing "standalone..."
' until "Standalone Program" is highlighted in yellow,
' and then press the enter.
' An "instant help" window will appear with instructions
' on how to make a standalone program.
'
	IMPORT "xst"
	IMPORT "xui"
'
DECLARE FUNCTION  Entry ()
'
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
' First display a GUI window
' with the title  "ahello.x"
' and the message "Hello World"
'
	message$ = "[ahello.x]\n Hello World"
	XuiMessage (message$)
'
' The XstDisplayConsole() is needed to
' create a console in a standalone program.
'
	XstDisplayConsole ()  ' This will create an XBasic console

	PRINT "Hello World"
'
' The INLINE$() is so you have time to read the message
' before the console disappears.
'
	string$ = INLINE$("\nPress Enter to finnish ==> ")
'
END FUNCTION
END PROGRAM

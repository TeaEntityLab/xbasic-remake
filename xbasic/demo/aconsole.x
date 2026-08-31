'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"aconsole"
VERSION	"0.0002"     '2011 May 29
'
IMPORT	"xst"
IMPORT	"xgr"        ' needed for color definitions
'
' A fully functional and debugged GUI program
' running in standalone mode would normally
' have no need nor desire for a console window.
' So XBasic standalone programs, by default,
' do not have a console window. But sometimes
' a console window is a convenient way to
' display additional information.
' Command-line control programs need a console.
'
' The easiest way to have a console in a standalone program
' is with the function, "XstDisplayConsole()." It will make
' an existing console visible, but if there is no console,
' it will create a default console and then make it visible.
'
' The XstShowConsole() function will make an existing console
' visible, but it will not create a console if it does not exist.
'
' A non-GUI program can have a customized console by
' using the following Standard Library functions:
'
'   XstCreateConsole()
'   XstSetConsoleStyleAndColors()
'   XstSetConsoleFont()
'   XstShowConsole() or XstDisplayConsole()
'
' Also used in this program are the following functions to
' get the information about an existing console window:
'
'   XstGetConsolePositionAndSize()
'   XstGetConsoleStyleAndColors()
'   XstGetConsoleFont()
'
' If run in the Program Development Environment (PDE), this
' program will save the existing console window information,
' display two customized console windows and then restore
' the console back to the original settings.
'
' If run as a standalone program, it first uses the
' XstDisplayConsole() to create and show a default console,
' then display the two customized console windows and then
' end the program.
'
' This program also demonstrates the use of the functiuon:
'
'   XstXstWindowSizePercent()
'
' which takes position and size information given as a
' percentage of the work-area available to calculate the
' pixel figures neede to create the window.
'
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  SaveConsole ()
DECLARE FUNCTION  RestoreConsole ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	XstGetConsoleGrid (@grid)
	IF grid THEN
		SaveConsole ()         ' save existing console information
		XstClearConsole ()
	ELSE
		XstDisplayConsole ()   ' create and display a default console
	END IF
'
	PRINT
	PRINT "The easiest way to have a console window in a"
	PRINT "standalone program is to start the program with:"
	PRINT
	PRINT "  XstDisplayConsole()"
	PRINT
	string$ = INLINE$("Press Enter to see a customized console ==> ")
'
	xDisp = 50               ' 10% almost to the far left of the workarea
	yDisp = 90               ' 50% half way down the workarea
	width = 60               ' 50% half the width of the workarea
	height = 40              ' 75% 3/4 of the height of the workarea
	style = 7                ' 7 is the maximum style number
	font$ = "9x15bold"       ' a readable large font
	textBack = $$White       ' text area background color
	textDraw = $$BrightBlue  ' text drawing color
	scrollBack = $$Yellow    ' scrollbar background color
	scrollDraw = $$Red       ' scrollbar arrows color
	scrollLo = -1            ' scrollbar low  border color (-1 don't change)
	scrollHi = -1            ' scrollbar high border color (-1 don't change)
	GOSUB RemakeConsole
'
	XstClearConsole ()
	PRINT
	PRINT "A custom console is made using the functions:"
	PRINT
	PRINT "     XstCreateConsole ()"
	PRINT "     XstSetConsoleStyleAndColors ()"
	PRINT "     XstSetConsoleFont ()"
	PRINT "     XstShowConsole ()"
	PRINT
	string$ = INLINE$("Press Enter for second example ==> ")
'
	xDisp = 100 : yDisp = 10 : width = 90 : height = 45
	font$ = "12x24"
	textBack = $$Black : textDraw = $$White
	scrollBack = textBack : scrollDraw = textDraw
	GOSUB RemakeConsole
	PRINT
'
	IF grid THEN
		string$ = INLINE$("Press Enter to restore original console ==> ")
		RestoreConsole ()      ' put console settings back to original
	ELSE
		string$ = INLINE$("Press Enter to end this program ==> ")
	END IF
'
	RETURN
'
' *****  RemakeConsole  *****
'
SUB RemakeConsole

	XstHideConsole ()
	windowType = 0
	XstWindowSizePercent (@xDisp, @yDisp, @width, @height, windowType)
	XstCreateConsole (xDisp, yDisp, width, height)
	XstSetConsoleStyleAndColors (style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi)
	XstSetConsoleFont (size, weight, italic, angle, font$)
	XstShowConsole ()

END SUB

END FUNCTION
'
'
' ############################
' #####  SaveConsole ()  #####
' ############################
'
FUNCTION  SaveConsole ()
	SHARED xDisp, yDisp, width, height
	SHARED style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi
	SHARED size, weight, italic, angle, font$

	XstGetConsolePositionAndSize (@xDisp, @yDisp, @width, @height)
	XstGetConsoleStyleAndColors (@style, @textBack, @textDraw, @scrollBack, @scrollDraw, @scrollLo, @scrollHi)
	XstGetConsoleFont (@size, @weight, @italic, @angle, @font$)

END FUNCTION
'
'
' ###############################
' #####  RestoreConsole ()  #####
' ###############################
'
FUNCTION  RestoreConsole ()
	SHARED xDisp, yDisp, width, height
	SHARED style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi
	SHARED size, weight, italic, angle, font$

	XstCreateConsole (@xDisp, @yDisp, @width, @height)
	XstSetConsoleStyleAndColors (@style, @textBack, @textDraw, @scrollBack, @scrollDraw, @scrollLo, @scrollHi)
	XstSetConsoleFont (@size, @weight, @italic, @angle, @font$)


END FUNCTION
END PROGRAM

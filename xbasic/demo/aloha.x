'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "aloha"
VERSION "0.0002"
'
IMPORT	"xst"
IMPORT	"ahowdy"
'
' This program calls Howdy() in dynamic link library ahowdy.dll.
' ahowdy.x is the XBasic program from which ahowdy.dll was created.
' Note that ahowdy.x prints two lines, "Hello from Entry()" and
' "Hello from ahowdy!".  The first line is printed by the entry
' function in ahowdy, even though this program never called it,
' because the entry functions of dynamic link libraries are called
' by XBasic programs that import them.  See IMPORT "ahowdy" above.
' If you run this program several times, you'll notice that the
' "Hello from Entry()" appears only the first time - ahowdy.x has
' already been imported by the program development environment.
'
' ahowdy.dll may already exist in yuor working directory.  If not,
' you can create ahowdy.dll from ahowdy.x as follows:
'
' Enter "xb ahowdy.x -lib" in a console window.  This causes XBasic
' to compile ahowdy.x as a library and create ahowdy.s, ahowdy.mak,
' and a few other operating system specific support files.
'
' Enter "nmake ahowdy.mak" to convert ahowdy.s into ahowdy.dll.
'
'
' The IMPORT "ahowdy" statement in this PROLOG makes XBasic compile
' the contents of ahowdy.dec into this program.  ahowdy.dec contains
' "EXTERNAL FUNCTION  Howdy()" which is what makes it possible for
' this program to call Howdy() in ahowdy.dll.
'
' ahowdy.dll is a standalone library, which means it can be called
' by any XBasic program that contains an IMPORT "ahowdy" statement.
'
'
' First run this aloha.x program in the program development environment
' to make sure it runs and successfully calls Howdy() in ahowdy.dll.
' Then, if you want to convert this program into a standalone executable
' enter "xb aloha" in a console window, followed by "nmake aloha.mak".
' To run the resulting standalone aloha.exe/ahowdy.dll comination,
' enter "aloha" in a console window.
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	Howdy ()
	PRINT "Aloha from Hawaii!"
	XstSleep (2000)
	PRINT "*****  DONE  *****"
END FUNCTION
END PROGRAM

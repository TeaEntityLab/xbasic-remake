'
'
' ####################
' #####  PROLOG  #####
' ####################
'
' This program shows how easy it is to find all files
' of a given type in any directory and its subdirectories.
' This example finds and prints the full path-filename of
' all *.bmp files on the current hard drive.
'
' See the "aviewbmp.x" sample program to display the images.
'
'
PROGRAM	"afindall"
VERSION	"0.0000"
'
IMPORT	"xst"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()

	basedir$ = "/usr/xb"
	filefilter$ = "*.bmp"
'
	XstFindFiles (@basedir$, @filefilter$, $$TRUE, @file$[])
'
	FOR i = 0 TO UBOUND (file$[])
		PRINT file$[i]
	NEXT i
END FUNCTION
END PROGRAM

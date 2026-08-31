'
'
' ####################
' #####  PROLOG  #####
' ####################
'
' This is an XBasic program that recurses into every subdirectory
' to find every file on a drive or filesystem.
'
PROGRAM	"arecurse"
VERSION	"0.0001"
'
IMPORT	"xst"
'
'
' #######################
' #####  FUNCTIONS  #####
' #######################
'
DECLARE FUNCTION  Entry            ()
DECLARE FUNCTION  DisplayFiles     (path$, type$)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()

	path$ = "/home/"
	type$ = "*.bmp"
	DisplayFiles (@path$, @type$)
END FUNCTION
'
'
' #############################
' #####  DisplayFiles ()  #####
' #############################
'
FUNCTION  DisplayFiles (path$, type$)
	FILEINFO  fileinfo[]
'
	upper = UBOUND (path$)
	slasher = path${upper}
	IF (slasher != '/') THEN path$ = path$ + "/"
'	PRINT ">>>>> "; path$; type$
'
	DIM file$[]
	DIM fileinfo[]
	files$ = path$ + type$
	attributes = $$FileReadOnly | $$FileHidden | $$FileArchive | $$FileNormal
	XstGetFilesAndAttributes (@files$, attributes, @file$[], @fileinfo[])
'
	IF file$[] THEN
		DIM empty[]
		upper = UBOUND (file$[])
		XstQuickSort (@file$[], @empty[], 0, upper, 0)
		GOSUB ProcessFiles
	END IF
'
	DIM file$[]
	files$ = path$ + "*"
	XstGetFilesAndAttributes (@files$, $$FileDirectory, @file$[], @fileinfo[])
'
	IF file$[] THEN
		DIM empty[]
		upper = UBOUND (file$[])
		XstQuickSort (@file$[], @empty[], 0, upper, 0)
		FOR i = 0 TO upper
			subpath$ = path$ + file$[i] + "/"
'			PRINT " call DisplayFiles() : "; subpath$; type$
			DisplayFiles (subpath$, type$)
		NEXT i
	END IF
'
'	print = $$TRUE
	RETURN
'
'
SUB ProcessFiles
	count = 0
	ufile = UBOUND (file$[])
'
	FOR i = 0 TO ufile																			' for all files
		ifile$ = path$ + file$[i]															' path/filename
		ifile = OPEN (ifile$, $$RD)														' open file
		IF (ifile < 3) THEN																		' did not open
			PRINT "#####  error : "; ifile$											' report error
			DO NEXT
		END IF
		error = ERROR (0)																			' reset error
		IF error THEN DO NEXT																	' but skip this file
'
		bytes = LOF (ifile)																		' size of file in bytes
		PRINT RJUST$(STRING$(bytes),12); " : "; ifile$				' print file size in bytes
'		XstDeleteFile (ifile$)																'
		CLOSE (ifile)																					' close the file
	NEXT i
END SUB
END FUNCTION
END PROGRAM

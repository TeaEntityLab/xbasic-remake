'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"CreateHelp"
VERSION	"6.4.1"
'
	IMPORT	"xst"
	IMPORT	"xui"
	IMPORT	"xut"
'
'
DECLARE FUNCTION  Entry ()
'
' functions for extracting help text from source code files
'
DECLARE FUNCTION  XsrcToHelp ()
DECLARE FUNCTION  GetFirstFunction (@func$)
DECLARE FUNCTION  GetNextFunction (@func$)
DECLARE FUNCTION  GetDecFuncList (@textDec$[])
DECLARE FUNCTION  GetXInDec (@sortedArray$[])
DECLARE FUNCTION  CreateHelpArray (@array$[], @arrayOut$[])

DECLARE FUNCTION  FormatLine$ (line$)
DECLARE FUNCTION  RemoveQuoteSpace (@help$[])
'
DECLARE FUNCTION  TextToHelp ()
'
DECLARE FUNCTION  CreateIndex ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
'
FUNCTION  Entry ()
	SHARED dirSrc$
	SHARED dirHelp$


	error = XstGetCurrentDirectory (@directory$)
	IF (RIGHT$(directory$, 4) == $$PathSlash$ + "src") THEN
		error = XstChangeDirectory ("..")
	END IF
	error = XstGetCurrentDirectory (@directory$)
'
' An XBasic source directory should contain a 'makefile'
'
	filename$ = directory$ + $$PathSlash$ + "makefile"         ' win32
	error = XstGetFileAttributes (filename$, @attributes)
	IFZ attributes THEN
		filename$ = directory$ + $$PathSlash$ + "Makefile"       ' Linux
		error = XstGetFileAttributes (filename$, @attributes)
		IFZ attributes THEN
			GOSUB ErrorMessage
			RETURN
		END IF
	END IF
'
' An XBasic source directory will have a 'src' directory
'
	dirSrc$  = directory$ + $$PathSlash$ + "src"  + $$PathSlash$
	error = XstGetFileAttributes (dirSrc$, @attributes)
	IFZ (attributes AND $$FileDirectory) THEN
		GOSUB ErrorMessage
		RETURN
	END IF
'
' An XBasic source directory will have a 'help' directory
' to put the '.hlp' files
'
	dirHelp$ = directory$ + $$PathSlash$ + "help" + $$PathSlash$
	error = XstGetFileAttributes (dirHelp$, @attributes)
	IFZ (attributes AND $$FileDirectory) THEN
		GOSUB ErrorMessage
		RETURN
	END IF

	XstClearConsole ()

	XsrcToHelp ()
	TextToHelp ()
	CreateIndex ()

	PRINT
	PRINT "Close XBasic and in a Root Terminal, go to the directory:"
	PRINT
	PRINT directory$
	PRINT
	PRINT "Type \"sudo make install\""

	RETURN

'-----------------------------------------------------------
'
'
' *****  ErrorMessage  *****
'
SUB ErrorMessage
	message$ = "[CreateHelp Error]\n"
	message$ = message$ + "The current directory:\n"
	message$ = message$ + directory$ + "\n"
	message$ = message$ + "is not a valid XBasic source directory.\n"
	message$ = message$ + "To run this program, XBasic should be started from a\n"
	message$ = message$ + "terminal session while in an XBasic source directory.\n"
	XuiMessage (message$)
END SUB

END FUNCTION
'
'
' ###########################
' #####  XsrcToHelp ()  #####
' ###########################
'
FUNCTION  XsrcToHelp ()
	SHARED dirSrc$
	SHARED dirHelp$
	SHARED xsrcFileList$[]
	SHARED text$[]

	DIM xsrcFileList$[2]
	xsrcFileList$[0] = "xgr"
	xsrcFileList$[1] = "xst"
	xsrcFileList$[2] = "xui"

	SELECT CASE ##XBSystem
		CASE $$XBSysWin32 : dirSystem$ = "win32"
		CASE $$XBSysLinux : dirSystem$ = "linux"
		CASE ELSE          : RETURN
	END SELECT

	dirSystem$ = dirSrc$ + dirSystem$ + $$PathSlash$
	dirShared$ = dirSrc$ + "shared" + $$PathSlash$

	uXsrcFileList = UBOUND(xsrcFileList$[])
	FOR fileIndex = 0 TO uXsrcFileList
		file$ = xsrcFileList$[fileIndex]

		IF (file$ == "xui") THEN
			fileDecName$ = dirShared$ + file$ + ".dec"
		ELSE
			fileDecName$ = dirSystem$ + file$ + ".dec"
		END IF

		error = XstLoadStringArray (fileDecName$, @textDec$[])
		IF error THEN
			PRINT "Failed to load", fileDecName$
			RETURN
		END IF

		GetDecFuncList (@textDec$[])
		index = UBOUND(textDec$[])

		IF (file$ == "xui") THEN
			fileXname$ = dirShared$ + file$ + ".x"
		ELSE
			fileXname$ = dirSystem$ + file$ + ".x"
		END IF
		error = XstLoadStringArray (fileXname$, @text$[])
		IF error THEN
			PRINT "Failed to load", fileXname$
			RETURN
		ELSE
			PRINT "Processing file:", fileXname$
		END IF
		size = UBOUND(text$[])
		REDIM textDec$[size]

		GetFirstFunction (@func$)
		INC index
		textDec$[index] = func$
		DO
			GetNextFunction (@func$)
			IFZ func$ THEN EXIT DO
			INC index
			textDec$[index] = func$
		LOOP
		REDIM textDec$[index]

		XstQuickSort (@textDec$[], @orderArray[], 0, index, $$SortCaseInsensitive)
		GetXInDec (@textDec$[])
		CreateHelpArray(@textDec$[], @help$[])
		RemoveQuoteSpace (@help$[])
		fileOut$ = dirHelp$ + file$ + ".hlp"
		error = XstSaveStringArray (fileOut$, @help$[])
		IF error THEN
			PRINT "Failed to save", fileOut$
			RETURN
		ELSE
			PRINT " Output to file:", fileOut$
			PRINT
		END IF
	NEXT fileIndex

	RETURN

END FUNCTION
'
'
' #################################
' #####  GetFirstFunction ()  #####
' #################################
'
FUNCTION  GetFirstFunction (func$)
	SHARED text$[]
	SHARED endLine

'	DIM func$[]
	func$ = ""
	uText = UBOUND(text$[])
	FOR i = 0 TO uText
		line$ = text$[i]
		IF (LEFT$(line$, 8) == "FUNCTION") THEN
			endLine = i
			endPos = LEN(line$)
			GOSUB GetStart
			line$ = MID$(line$, 9)
			line$ = TRIM$(line$)
			paren = INSTR(line$, "(")
			IFZ paren THEN DO NEXT
			line$ = LEFT$(line$, paren-1)
			line$ = FormatLine$ (line$)
			func$ = line$ + " x" + STR$(startLine) + STR$(endPos) + STR$(endLine)
			EXIT FOR
		END IF
	NEXT i
'	XstStringArraySectionToStringArray (@text$[], @func$[], 0, startLine, endPos, endLine)

	RETURN
' --------------------------------------------------
'
' #####  GetStart  #####
'
SUB GetStart
	DO
		IF i THEN
			i = i-1
		ELSE
			startLine = 0
			EXIT SUB
		END IF
		'
		lineSt$ = text$[i]
		IF (LEFT$(lineSt$) <> "'") THEN
			startLine = i+1
			EXIT DO
		END IF
	LOOP

	lineSt$ = text$[startLine]
	lineSt$ = TRIM$(lineSt$)
	IF (lineSt$ == "'") THEN INC startLine
	lineSt$ = text$[startLine]
	lineSt$ = TRIM$(lineSt$)
	IF (lineSt$ == "'") THEN INC startLine

END SUB

END FUNCTION
'
'
' ################################
' #####  GetNextFunction ()  #####
' ################################
'
FUNCTION  GetNextFunction (@func$)
	SHARED text$[]
	SHARED endLine

'	DIM func$[]
	func$ = ""
	uText = UBOUND(text$[])
	FOR i = endLine TO uText
		line$ = text$[i]
		IF (LEFT$(line$, 12) == "END FUNCTION") THEN
			startLine = i+1
			line$ = text$[startLine]
			line$ = TRIM$(line$)
			IF (line$ == "'") THEN INC startLine
			line$ = text$[startLine]
			line$ = TRIM$(line$)
			IF (line$ == "'") THEN INC startLine
			EXIT FOR
		END IF
	NEXT i
	'
	FOR i = startLine TO uText
		line$ = text$[i]
		IF (LEFT$(line$, 8) == "FUNCTION") THEN
			endLine = i
			endPos = LEN(line$)
			line$ = MID$(line$, 9)
			line$ = TRIM$(line$)
			paren = INSTR(line$, "(")
			IFZ paren THEN DO NEXT
			line$ = LEFT$(line$, paren-1)
			line$ = FormatLine$ (line$)
			func$ = line$ + " x" + STR$(startLine) + STR$(endPos) + STR$(endLine)


'			XstStringArraySectionToStringArray (@text$[], @func$[], 0, startLine, endPos, endLine)
			EXIT FOR
		END IF
	NEXT i
'	XstStringArraySectionToStringArray (@text$[], @func$[], 0, startLine, endPos, endLine)

END FUNCTION
'
'
' ###############################
' #####  GetDecFuncList ()  #####
' ###############################
'
FUNCTION  GetDecFuncList (@textDec$[])

	utext = UBOUND (textDec$[])
	DIM textOut$[utext]
	iOut = 0
	FOR i = 0 TO utext
		line$ = textDec$[i]
		line$ = TRIM$(line$)
		IF (LEFT$(line$, 8) <> "EXTERNAL") THEN DO NEXT
		line$ = MID$(line$, 9)
		line$ = TRIM$(line$)
		IF (LEFT$(line$, 8) <> "FUNCTION") THEN DO NEXT
		line$ = MID$(line$, 9)
		line$ = TRIM$(line$)
		IF (LEFT$(line$, 3) == "Xxx") THEN
			PRINT "*****  ", line$            ' should not be in .dec file
			DO NEXT
		END IF
		paren = INSTR(line$, "(")
		IFZ paren THEN DO NEXT
		line$ = LEFT$(line$, paren-1)
		line$ = FormatLine$ (line$)
		line$ = line$ + " dec"
		textOut$[iOut] = line$
		INC iOut
	NEXT i
	DEC iOut
	REDIM textOut$[iOut]
	SWAP textDec$[], textOut$[]
	DIM textOut$[]
END FUNCTION
'
'
' ##########################
' #####  GetXInDec ()  #####
' ##########################
'
FUNCTION  GetXInDec (@sortedArray$[])

	uArray = UBOUND(sortedArray$[])
	DIM xArray$[uArray]
	j = 0
	FOR i = 0 TO uArray
		prevString$ = sortedArray$[i]
		XstParseStringToStringArray (prevString$, " ", @prevS$[])
		IF (prevS$[1] <> "dec") THEN DO NEXT
		string$ = sortedArray$[i+1]
		XstParseStringToStringArray (string$, " ", @s$[])
		IF (s$[1] <> "x") THEN DO NEXT
		IF (prevS$[0] <> s$[0]) THEN DO NEXT
		xArray$[j] = sortedArray$[i+1]
		INC j
		INC i
	NEXT i
	DEC j
	REDIM xArray$[j]
	SWAP xArray$[], sortedArray$[]
	DIM xArray$[]

END FUNCTION
'
'
' ################################
' #####  CreateHelpArray ()  #####
' ################################
'
FUNCTION  CreateHelpArray (@array$[], @arrayOut$[])
	SHARED text$[]

	DIM arrayOut$[]

	uArray = UBOUND (array$[])
	FOR i = 0 TO uArray
		section$ = array$[i]
		XstParseStringToStringArray (section$, " ", @s$[])
		uS = UBOUND (s$[])
		IF ((uS <> 4) && (s$[1] <> "x"))THEN
			PRINT "CreateHelpArray():Error on line ", i
			PRINT section$
			DO NEXT
		END IF
		sectionHeader$ = ":" + s$[0] + "()"
		uOut = UBOUND (arrayOut$[])
		REDIM arrayOut$[uOut+2]
		arrayOut$[uOut+1] = sectionHeader$
		firstS = XLONG(s$[2])
		countS = XLONG(s$[4]) - firstS + 1

		XstReplaceLines (@arrayOut$[], @text$[], uOut+2, 1, firstS, countS)
	NEXT i

END FUNCTION
'
'
' ############################
' #####  FormatLine$ ()  #####
' ############################
'
' line$ = FormatLine$ (line$)
'
FUNCTION  FormatLine$ (line$)

	line$ = TRIM$(line$)
	'
	' Change tab characters to space characters
	'
	DO
		pos = INSTR(line$, "\t")
		IFZ pos THEN EXIT DO
		line$ = STUFF$(line$, " ", pos)
	LOOP
	'
	' Change multiple spaces to single spaces
	'
	DO
		pos = INSTR(line$, "  ")
		IFZ pos THEN EXIT DO
		line$ = LEFT$(line$, pos) + MID$(line$, pos+2)
	LOOP
	'
	XstParseStringToStringArray (line$, " ", @line$[])
	uLine = UBOUND(line$[])
	IF (uLine > 1) THEN
		PRINT "FormatLine$():Invalid function", line$
		RETURN line$
	END IF
	IF (uLine = 1) THEN
		SELECT CASE line$[0]
			CASE "SBYTE"
			CASE "UBYTE"
			CASE "SSHORT"
			CASE "USHORT"
			CASE "SLONG"
			CASE "ULONG"
			CASE "XLONG"
			CASE "GOADDR"
			CASE "SUBADDR"
			CASE "GIANT"
			CASE "SINGLE"
			CASE "DOUBLE"
			CASE "STRING"
			CASE "SCOMPLEX"
			CASE "DCOMPLEX"
			CASE ELSE :
									PRINT "FormatLine$():Invalid function", line$
									RETURN line$
		END SELECT
		line$ = line$[1]
		line$ = TRIM$(line$)
	END IF

	RETURN line$

END FUNCTION
'
'
' #################################
' #####  RemoveQuoteSpace ()  #####
' #################################
'
FUNCTION  RemoveQuoteSpace (@help$[])

	uHelp = UBOUND (help$[])
	FOR i = 0 TO uHelp
		s$ = help$[i]
		sLen = LEN(s$)
		SELECT CASE sLen
			CASE 0
			CASE 1
				IF (s$ == "'") THEN s$ = ""
			CASE 2
				IF (LEFT$(s$, 2) == "' ") THEN
					s$ = ""
				ELSE
					IF (LEFT$(s$, 1) == "'") THEN
						s$ = LCLIP$(s$, 1)
					END IF
				END IF
			CASE ELSE
				IF (LEFT$(s$, 2) == "' ") THEN
					s$ = LCLIP$(s$, 2)
					IF (LEFT$(s$, 1) != "#") THEN               '*cw* 140713+
						s$ = "\t" + s$                            '*cw* 140713+
					END IF                                      '*cw* 140713+
				ELSE
					IF (LEFT$(s$, 1) == "'") THEN
						s$ = LCLIP$(s$, 1)
						IF (LEFT$(s$, 1) != "#") THEN             '*cw* 140713+
							s$ = "\t" + s$                          '*cw* 140713+
						END IF                                    '*cw* 140713+
					END IF
				END IF
			END SELECT
		help$[i] = s$
	NEXT i

END FUNCTION
'
'
' ###########################
' #####  TextToHelp ()  #####
' ###########################
'
FUNCTION  TextToHelp ()
	SHARED dirSrc$
	SHARED dirHelp$
	SHARED textFileList$[]

'	error = XstGetCurrentDirectory (@directory$)
'	IF (RIGHT$(directory$, 4) == "/src") THEN
'		error = XstChangeDirectory ("..")
'	END IF
'	error = XstGetCurrentDirectory (@directory$)
'	IF (LEN(directory$) != 22) THEN
'		PRINT "Not a valid xbasic source directory", directory$
'		RETURN
'	END IF
'	IF (LEFT$(directory$, 20) != "/usr/src/xbasic-6.3.") THEN
'		PRINT "Not a valid xbasic source directory", directory$
'		RETURN
'	END IF
'	pathOut$ = directory$ + "/help/"

	DIM textFileList$[3]
	textFileList$[0] = "lang"
	textFileList$[1] = "messages"
	textFileList$[2] = "misc"
	textFileList$[3] = "pde"

	dirText$ = dirSrc$ + "helpsrc" + $$PathSlash$ + "help_text" + $$PathSlash$

	uTextFileList = UBOUND (textFileList$[])
	FOR listNumber = 0 TO uTextFileList
		file$ = textFileList$[listNumber]
		fileIn$  = dirText$ + file$ + ".txt"
		fileOut$ = dirHelp$ + file$ + ".hlp"
		GOSUB MakeHlp
	NEXT listNumber

	PRINT
	RETURN
'
' --------------------------------------
'
' *****  MakeHlp  *****
'
SUB MakeHlp

	error = XstLoadStringArray (@fileIn$, @string$[])
	IF error THEN
		PRINT "Error loading", fileIn$
		PRINT ERROR$(ERROR(0))
		RETURN
	ELSE
		PRINT "Processing file:", fileIn$
	END IF

	outfile = OPEN(fileOut$, $$WRNEW)
	IF (outfile < 3) THEN
		PRINT "Error opening", fileOut$
		PRINT ERROR$(ERROR(0))
		RETURN
	ELSE
		PRINT " Output to file:", fileOut$
		PRINT
	END IF

	uString = UBOUND(string$[])
	DIM header$[]
	FOR i = 0 TO uString
		line$ = string$[i]

		isHeader = $$FALSE
		IF LEN(line$) > 1 THEN
			IF (ASC(line$, 1) == ':') THEN
				IF (ASC(line$, 2) != ':') THEN   ' not logical-compare "::"
					isHeader = $$TRUE
				END IF
			END IF
		END IF

		IF isHeader THEN
			GOSUB AddToHeader
		ELSE
			IF header$[] THEN
				GOSUB WriteHeader
			ELSE
				line$ = "\t" + line$
			END IF
		END IF

		PRINT [outfile], line$
	NEXT i
	CLOSE(outfile)

END SUB
'
'
' *****  AddToHeader  *****
'
SUB AddToHeader
	IFZ header$[] THEN
		uHeader = 0
	ELSE
		uHeader = UBOUND (header$[]) + 1
	END IF
	REDIM header$[uHeader]
	header$[uHeader] = MID$(line$, 2)
END SUB
'
'
' *****  WriteHeader  *****
'
SUB WriteHeader
	uHeader = UBOUND (header$[])
	IF (uHeader > 0) THEN
		IF (file$ == "pde") THEN
			XstDeleteLines (@header$[], 0, 1)  'delete first line if pde file
			uHeader = UBOUND (header$[])
		END IF
	END IF
	maxLen = 0
	FOR j = 0 TO uHeader
		lineLen = LEN(header$[j])
		IF (lineLen > maxLen) THEN maxLen = lineLen
	NEXT j
	hdrStartEnd$ = CHR$('#', maxLen + 14)
	PRINT [outfile], hdrStartEnd$
	hdrBorder$ = CHR$('#', 5) + SPACE$(maxLen + 4) + CHR$('#', 5)
	FOR j = 0 TO uHeader
		hdrLine$ = STUFF$ (hdrBorder$, header$[j], 8)
		PRINT [outfile], hdrLine$
	NEXT j
	PRINT [outfile], hdrStartEnd$
	DIM header$[]
END SUB

END FUNCTION
'
'
' ############################
' #####  CreateIndex ()  #####
' ############################
'
FUNCTION  CreateIndex ()
	SHARED dirHelp$
	SHARED xsrcFileList$[]
	SHARED textFileList$[]

	XstStringArrayToString (@xsrcFileList$[], @s1$)
	XstStringArrayToString (@textFileList$[], @s2$)
	s3$ = s1$ + "\n" + s2$
	XstStringToStringArray (s3$, @fileList$[])

	uFileList = UBOUND(fileList$[])
	FOR fileIndex = 0 TO uFileList
		file$ = fileList$[fileIndex]

		fileHlpName$ = dirHelp$ + file$ + ".hlp"
		error = XstLoadStringArray (fileHlpName$, @textHlp$[])
		IF error THEN
			PRINT "Failed to load", fileHlpName$
		ELSE
			PRINT "Processing file:", fileHlpName$
		END IF

		isPde = $$FALSE
		IF (file$ == "pde") THEN isPde = $$TRUE

		uhlp = UBOUND(textHlp$[])
		FOR i = 0 TO uhlp
			s$ = textHlp$[i]
			IF (LEFT$(s$) <> ":") THEN
				gotColon = $$FALSE
				DO NEXT
			END IF
			IF isPde THEN
				IFF gotColon THEN
					gotColon = $$TRUE
					DO NEXT             ' skip first entry of group if file is pde
				END IF
			END IF
			index$ = MID$(s$, 2)
			index$ = TRIM$(index$)
			index$ = index$ + " <" + file$ + ":>"
			uindex = UBOUND(index$[])
			INC uindex
			REDIM index$[uindex]
			index$[uindex] = index$
		NEXT i

	NEXT fileIndex

	XstQuickSort (@index$[], @orderArray[], 0, uindex, $$SortCaseInsensitive)
	INC uindex
	REDIM index$[uindex]
	version$ = XstVersion$ ()
	version$ = "Version " + version$
	index$[uindex] = version$
	fileOut$ = dirHelp$ + "index.hlp"
	error = XstSaveStringArray (fileOut$, @index$[])
	PRINT
	IF error THEN
		PRINT "Failed to save output file", fileOut$
	ELSE
		PRINT "Index  file  is:", fileOut$
		PRINT "Upper bound  is:", UBOUND(index$[])
		PRINT "Finished Processing help files"
	END IF

	RETURN

END FUNCTION
END PROGRAM

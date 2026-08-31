'
'
' ####################  Eddie Penninkhof
' #####  PROLOG  #####  copyright 2000
' ####################  XBasic platform independent utility library
'
' subject to LGPL license - see COPYING_LIB
'
' for Windows XBasic
' for Linux XBasic
'
' Note: this file is only used by the PDE, not by user programs.
'
PROGRAM "xutpde"
VERSION "0.0001"
'
IMPORT	"xst"
'IMPORT	"clib"
IMPORT "kernel32"
IMPORT "xut"
'
EXPORT
'
' Constants
'
	EXPORT	XBDir$												' The main XBasic directory.
	DECLARE FUNCTION XutPDEInit ()
END EXPORT

EXTERNAL FUNCTION  XxxXstLog                  (text$)
'
INTERNAL FUNCTION  InitDirectories            ()
'
'
'* Initialize the XutPDE - utilitiy-library.
'
FUNCTION XutPDEInit ()
	InitDirectories ()
END FUNCTION

'* Determine what the XBasic base directory is.
' Use the value of the environment variable XBDIR (if available), retrieve
' the directory from the pathname of the executable or use a system dependent
' default (/usr/xb (for Unix) or c:\xb (for Windows))
'
FUNCTION InitDirectories ()
	' First: use the environment variable XBDIR
	XstGetEnvironmentVariable(@"XBDIR", @##XBDir$)
	IFZ ##XBDir$
		' If the environment variable XBDIR is not set: try to get the XBasic
		' base-directory from the full filename/path of the executable.
		XstDecomposePathname(XstGetProgramFileName$(), @path$, @parent$, @filename$, @file$, @extent$)
		slash = RINSTR(path$, $$PathSlash$)
		IF slash THEN
			path$ = LEFT$(path$, slash - 1)
			##XBDir$ = path$
			XstSetEnvironmentVariable(@"XBDIR", @##XBDir$)
		END IF
	END IF
	IFZ ##XBDir$ THEN
		' Fallback to a system dependent default directory
		IF ##XBSystem == $$XBSysWin32 THEN
			##XBDir$ = "c:\\xb"
		ELSE
			##XBDir$ = "/usr/xb"
		END IF
		XstSetEnvironmentVariable(@"XBDIR", @##XBDir$)
	ELSE
		IF (##XBDir${UBOUND(XBDir$)} = $$PathSlash) THEN
			##XBDir$ = RCLIP$(##XBDir$, 1)		' remove trailing /
		END IF
	END IF
' Check if the include directory is available. Otherwise it's probably an
' installation error -> exit with an errormessage.
	testFile$ = ##XBDir$ + $$PathSlash$ + "include"
	XstGetFileAttributes(testFile$, @xb0)
	IFZ xb0 THEN
		XstAbend(testFile$ + " not found: Bad installation.")
	END IF
'
END FUNCTION
END PROGRAM

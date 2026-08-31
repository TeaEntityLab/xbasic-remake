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
' Note: this file is only used by both the PDE and user programs.
'
PROGRAM "xut"
VERSION "0.0001"
'
IMPORT	"xst"
'IMPORT	"clib"
IMPORT "kernel32"
'
EXPORT
'
' Constants
'
	$$XBSysLinux		= 1
	$$XBSysWin32		= 2

	EXPORT	XBSystem											' The XBasic system (values:
																				' $$XBSysLinux, $$XBSysWin32)
	DECLARE FUNCTION XutInit ()
END EXPORT
'
'
' ########################
' #####  XutInit ()  #####
' ########################
'
' Initialize the Xut - utilitiy-library.
'
FUNCTION XutInit ()
	' Currently this function is empty.
'
END FUNCTION
END PROGRAM

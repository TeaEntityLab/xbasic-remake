'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"ashell"
VERSION	"0.0000"
'
IMPORT "xst"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
' NOTE:
' SHELL() hangs until the command strings is completed,
' which means the invoked program terminates.
'
FUNCTION  Entry ()
'
' start gedit and have it open document $XBDIR/help/changelog.hlp
'
	a = SHELL ("gedit $XBDIR/help/changelog.hlp")
'
	text$ = "x-www-browser http://tech.groups.yahoo.com/groups/xbasic"
	a = SHELL (text$)
END FUNCTION
END PROGRAM

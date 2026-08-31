'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"adialog"
VERSION	"0.0000"
'
IMPORT "xui"
'
DECLARE  FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	XuiMessage ("Hello Fellow Programmer\n\nWelcome To The Future")
	XuiDialog ("What's your name?", "Billy Boy Gates", @reply, @reply$)
	IF reply$ THEN XuiMessage ("Your name is \"" + reply$ + "\"?\n\nI don't believe it!")
END FUNCTION
END PROGRAM

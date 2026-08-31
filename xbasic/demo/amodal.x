'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"amodal"
VERSION	"0.0002"
'
IMPORT	"xgr"
IMPORT	"xui"
'
DECLARE  FUNCTION  ModalDemo ()
'
' ##########################
' #####  ModalDemo ()  #####
' ##########################
'
' Demonstrate the following modal convenience functions,
'     plus non-modal convenience function XuiGetReply().
'
' XuiMessage (message$)
' XuiDialog (message$, default$, @kid, @reply$)
' XuiGetReply (grid, title$, message$, grids$, @v0, @v1, @kid, @reply$)
' XuiGetResponse (gridType$, title$, message$, grids$, @v0, @v1, @kid, @reply$)
'
FUNCTION  ModalDemo ()
	default$ = "Default Input String"
	XuiMessage ("To Display A Message\n\nXuiMessage(message$)\n\nPress Cancel\nTo Remove This Window")
	XuiDialog ("To Input Text\n\nXuiDialog(message$,default$,@kid,@reply$)\n\nInput String or click Enter/Cancel", default$, @kid, @reply$)
	XuiMessage ("Your Reply String Was\n\"" + reply$ + "\"\nReply kid # = " + STRING$(kid))
	XuiGetResponse ("XuiMessage4B", "End Convenience Function Demo", "That's all folks", "Bye\nAdios\nOuttaHere\nCancel", 0, 0, @kid, "")
	PRINT "You terminated with kid #"; kid
'
'
' Create and configure a window with convenience functions.
' Then call XuiGetReply() to operate it as a modal window.
'
	XuiCreateWindow (@grid, @"XuiDialog3B", 200, 200, 200, 100, 0, "")
	XuiSendStringMessage (grid, @"SetColor", $$LightBlue, $$Yellow, -1, -1, 1, 0)
	XuiSendStringMessage (grid, @"SetColorExtra", -1, -1, $$Black, $$Yellow, 1, 0)
	XuiSendStringMessage (grid, @"SetColor", $$BrightGreen, -1, -1, -1, 3, 0)
	XuiSendStringMessage (grid, @"SetColor", $$BrightCyan, -1, -1, -1, 4, 0)
	XuiSendStringMessage (grid, @"SetColor", $$BrightMagenta, -1, -1, -1, 5, 0)
	XuiSendStringMessage (grid, @"SetFocusColor", $$BrightGreen, -1, -1, -1, 3, 0)
	XuiSendStringMessage (grid, @"SetFocusColor", $$BrightCyan, -1, -1, -1, 4, 0)
	XuiSendStringMessage (grid, @"SetFocusColor", $$BrightMagenta, -1, -1, -1, 5, 0)
	XuiSendStringMessage (grid, @"SetFont", 800, 600, 400, 0, 1, @"Serif")
	XuiSendStringMessage (grid, @"SetTexture", $$TextureShadow, -1, -1, -1, 1, 0)
	XuiGetReply (grid, @"XuiGetReply ( )", @"People Of Earth\n\nYou Must Leave", @"Default String\nOne\nTwo\nThree", @v0, @v1, @kid, @reply$)
	PRINT HEX$(v0,8), HEX$(v1,8), kid, reply$
END FUNCTION
END PROGRAM

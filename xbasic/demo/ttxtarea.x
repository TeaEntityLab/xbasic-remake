'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "ttxtarea"
VERSION "6.3.26"
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
INTERNAL FUNCTION  TextArea        ( )
INTERNAL FUNCTION  GetDisplayGrid  ( @label )
INTERNAL FUNCTION  DisplayCallback ( grid, message$, v0, v1, v2, v3, kid, r1$ )
'
'
' ######################
' #####  TextArea  #####
' ######################
'
FUNCTION  TextArea ()
  $XuiTextArea = 11
	$TextArea			  =  0
	$Text					  =  1
	$ScrollH			  =  2
	$ScrollV			  =  3
	$lineNumKid     =  4
	$rulerKid       =  5
'
  GetDisplayGrid ( @label )
'
' create window with XuiTextArea grid
'
  XuiCreateWindow      (@grid, @"XuiTextArea", 100, 256, 256, 128, 0, "")
  XuiSendStringMessage ( grid, @"SetCallback", grid, &XuiQueueCallbacks(), -1, -1, $XuiTextArea, -1)
  XuiSendStringMessage ( grid, @"SetGridName", 0, 0, 0, 0, 0, @"TextArea")

'
' Set the Style to 2 for recessed scroll bars with arrow buttons
' Set the colors for LightGreen scroll bars with green arraows
'
	XuiSendStringMessage ( grid, @"GetStyle", @style, @styleMax, 0, 0, 0, 0)
	style = 2
	XuiSendStringMessage ( grid, @"SetStyle", style, @styleMax, 0, 0, 0, 0)
	XuiSendStringMessage ( grid, @"GetStyle", @style, @styleMax, 0, 0, 0, 0)
	XuiSendStringMessage ( grid, @"SetColor", $$LightGreen, $$Red, -1, -1, $ScrollH, 0)
	XuiSendStringMessage ( grid, @"SetColor", $$LightGreen, $$Red, -1, -1, $ScrollV, 0)
'
' Set the $$TextFlagLineNum to have line numbering
' Then set the $$TextFlagRuler to have a ruler grid
'
	XuiSendStringMessage ( grid, @"SetTextFlag", $$TextFlagLineNum, $$TRUE, 0, 0, 0, 0)
	XuiSendStringMessage ( grid, @"SetTextFlag", $$TextFlagRuler, $$TRUE, 0, 0, 0, 0)
	XuiSendStringMessage ( grid, @"SetColor", $$Cyan, -1, -1, -1, $lineNumKid, 0)
	XuiSendStringMessage ( grid, @"SetColor", $$Violet, -1, -1, -1, $rulerKid, 0)
'
' Set the colors for black text on a white background
'
	XuiSendStringMessage ( grid, @"SetColor", $$White, $$Black, -1, -1, $Text, 0)
'
' Set the $$TextFlagCursorLineHilite
'
	XuiSendStringMessage ( grid, @"SetTextFlag", $$TextFlagCursorLineHilite, $$TRUE, 0, 0, 0, 0)
'
' The following sets the color for the highlighted cursor line ($$BrightYellow)
' and the color used to draw the cursor ($$BrightGreen). The cursor is drawn in
' XOR mode so when green is XORed with yellow the result is red.
'
	XuiSendStringMessage ( grid, @"SetColorExtra", $$BrightGreen, -1, -1, $$BrightYellow, $Text, 0)
'
	DIM text$[2]
	text$[0] = "XuiTextArea"
	text$[1] = "line 2"
	text$[2] = "line 3"
  XuiSendStringMessage ( grid, @"PokeTextArray", 0, 0, 0, 0, 0, @text$[])
  XuiSendStringMessage ( grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)
'
' convenience function message loop
'
  DO
    XgrProcessMessages (1)
    DO WHILE XuiGetNextCallback (@grid, @message$, @v0, @v1, @v2, @v3, @kid, @r1$)
      GOSUB Callback
    LOOP
  LOOP
  RETURN
'
' callback
'
SUB Callback
  win = kid >> 16
  kid = kid AND 0xFF
  SELECT CASE message$
    CASE "CloseWindow" : QUIT (0)
    CASE "Selection"   : GOSUB Selection
    CASE ELSE          : DisplayCallback (grid, @message$, v0, v1, v2, v3, kid, @r1$)
  END SELECT
END SUB
'
' Selection message
'
SUB Selection
  DisplayCallback (grid, @message$, v0, v1, v2, v3, kid, @r1$)
END SUB
END FUNCTION
'
'
' ###############################
' #####  GetDisplayGrid ()  #####
' ###############################
'
FUNCTION  GetDisplayGrid ( label )
  STATIC  grid
'
  IFZ grid THEN
    XuiCreateWindow      (@grid, @"XuiLabel", 100, 100, 512, 128, 0, "")
    XuiSendStringMessage ( grid, @"SetColor", $$BrightGreen, -1, -1, -1, 0, 0)
    XuiSendStringMessage ( grid, @"SetAlign", $$AlignUpperLeft, 0, 0, 0, 0, 0)
    XuiSendStringMessage ( grid, @"SetJustify", $$JustifyLeft, 0, 0, 0, 0, 0)
    XuiSendStringMessage ( grid, @"SetIndent", 6, 4, 0, 0, 0, 0)
    XuiSendStringMessage ( grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)
  END IF
'
  label = grid
END FUNCTION
'
'
' ################################
' #####  DisplayCallback ()  #####
' ################################
'
FUNCTION  DisplayCallback ( grid, message$, v0, v1, v2, v3, kid, r1$ )
'
  XgrGetGridType (grid, @gridType)
  XgrGridTypeNumberToName (gridType, @gridType$)
'
  text$ = gridType$ + "\n"
  text$ = text$ + "   grid = " + HEX$ (grid, 8) + "\n"
  text$ = text$ + "message = " + message$ + "\n"
  text$ = text$ + "     v0 = " + HEX$ (v0,8) + "\n"
  text$ = text$ + "     v1 = " + HEX$ (v1,8) + "\n"
  text$ = text$ + "     v2 = " + HEX$ (v2,8) + "\n"
  text$ = text$ + "     v3 = " + HEX$ (v3,8) + "\n"
  text$ = text$ + "    kid = " + HEX$ (kid,8) + "\n"
  text$ = text$ + "    r1$ = " + r1$
'
  GetDisplayGrid (@label)
  XuiSendStringMessage (label, @"SetTextString", 0, 0, 0, 0, 0, @text$)
  XuiSendStringMessage (label, @"Redraw", 0, 0, 0, 0, 0, 0)
END FUNCTION
END PROGRAM

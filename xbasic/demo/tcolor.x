'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "tcolor"
VERSION "0.0000"
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
INTERNAL FUNCTION  Color           ( )
INTERNAL FUNCTION  GetDisplayGrid  ( @label )
INTERNAL FUNCTION  DisplayCallback ( grid, message$, v0, v1, v2, v3, kid, r1$ )
'
'
' ###################
' #####  Color  #####
' ###################
'
FUNCTION  Color ()
  $XuiColor = 0
'
  GetDisplayGrid ( @label )
'
' create window with XuiColor grid
'
  XuiCreateWindow      (@grid, @"XuiColor", 100, 256, 0, 0, 0, "")
  XuiSendStringMessage ( grid, @"SetCallback", grid, &XuiQueueCallbacks(), -1, -1, $XuiColor, -1)
  XuiSendStringMessage ( grid, @"SetGridName", 0, 0, 0, 0, 0, @"Color")
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
  XgrColorNumberToName (v0, @color$)
  IF color$ THEN color$ = " : " + color$
  text$ = "XuiColor\n"
  text$ = text$ + "    grid : " + HEX$ (grid,8) + "\n"
  text$ = text$ + " message : " + message$ + "\n"
  text$ = text$ + "      v0 : " + HEX$ (v0,8) + " : standard color #" + color$ + "\n"
  text$ = text$ + "      v1 : " + HEX$ (v1,8) + " : red intensity\n"
  text$ = text$ + "      v2 : " + HEX$ (v2,8) + " : green intensity\n"
  text$ = text$ + "      v3 : " + HEX$ (v3,8) + " : blue intensity\n"
  text$ = text$ + "     kid : " + HEX$ (kid,8) + "\n"
  text$ = text$ + "     r1$ : " + r1$
  XuiSendStringMessage (label, @"SetTextString", 0, 0, 0, 0, 0, @text$)    ' set message
  XuiSendStringMessage (label, @"Redraw", 0, 0, 0, 0, 0, 0)                ' redraw label
  XgrGetGridBox (label, @x1, @y1, @x2, @y2)
  XgrFillBox (label, v0, x2-174, y1+8, x2-8, y1+36)
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
    XuiSendStringMessage ( grid, @"SetColor", $$Cyan, -1, -1, -1, 0, 0)
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
  text$ = text$ + "    grid = " + HEX$ (grid, 8) + "\n"
  text$ = text$ + " message = " + message$ + "\n"
  text$ = text$ + "      v0 = " + HEX$ (v0,8) + "\n"
  text$ = text$ + "      v1 = " + HEX$ (v1,8) + "\n"
  text$ = text$ + "      v2 = " + HEX$ (v2,8) + "\n"
  text$ = text$ + "      v3 = " + HEX$ (v3,8) + "\n"
  text$ = text$ + "     kid = " + HEX$ (kid,8) + "\n"
  text$ = text$ + "     r1$ = " + r1$
'
  GetDisplayGrid (@label)
  XuiSendStringMessage (label, @"SetTextString", 0, 0, 0, 0, 0, @text$)
  XuiSendStringMessage (label, @"Redraw", 0, 0, 0, 0, 0, 0)
END FUNCTION
END PROGRAM

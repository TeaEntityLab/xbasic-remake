'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "tlist2"
VERSION "0.0000"
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
INTERNAL FUNCTION  ListDialog2B    ( )
INTERNAL FUNCTION  GetDisplayGrid  ( @label )
INTERNAL FUNCTION  DisplayCallback ( grid, message$, v0, v1, v2, v3, kid, r1$ )
'
'
' ##########################
' #####  ListDialog2B  #####
' ##########################
'
FUNCTION  ListDialog2B ()
  $XuiListDialog2B = 31
'
  GetDisplayGrid ( @label )
'
' create window with XuiListDialog2B grid
'
  DIM short$[7]
  short$[0] = "Zero"
  short$[1] = "One"
  short$[2] = "Two"
  short$[3] = "Three"
  short$[4] = "Four"
  short$[5] = "Five"
  short$[6] = "Six"
  short$[7] = "Seven"
'
  XuiCreateWindow      (@grid, @"XuiListDialog2B", 100, 256, 200, 212, 0, "")
  XuiSendStringMessage ( grid, @"SetCallback", grid, &XuiQueueCallbacks(), -1, -1, $XuiListDialog2B, -1)
  XuiSendStringMessage ( grid, @"SetGridName", 0, 0, 0, 0, 0, @"ListDialog2B")
  XuiSendStringMessage ( grid, @"SetTextString", 0, 0, 0, 0, 1, @"XuiListDialog2B")
  XuiSendStringMessage ( grid, @"SetTextString", 0, 0, 0, 0, 3, @"TextLine")
  XuiSendStringMessage ( grid, @"SetTextArray", 0, 0, 0, 0, 2, @short$[])
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
  SELECT CASE kid
    CASE 2  : XuiSendStringMessage (grid, @"GetTextArrayLine", v0, 0, 0, 0, 2, @a$)
    CASE 3  : XuiSendStringMessage (grid, @"GetTextString", 0, 0, 0, 0, 3, @a$)
    CASE 4  : XuiSendStringMessage (grid, @"GetTextString", 0, 0, 0, 0, 3, @a$)
    CASE 5  : a$ = "cancel"
  END SELECT
'
  text$ = "XuiListDialog2B"
  text$ = text$ + "\n    grid = " + HEX$ (grid,8)
  text$ = text$ + "\n message = " + message$
  text$ = text$ + "\n   state = " + HEX$ (v0,8) + " : " + a$
  text$ = text$ + "\n      v1 = " + HEX$ (v1,8)
  text$ = text$ + "\n      v2 = " + HEX$ (v2,8)
  text$ = text$ + "\n      v3 = " + HEX$ (v3,8)
  text$ = text$ + "\n     kid = " + HEX$ (kid,8)
  text$ = text$ + "\n     r1$ = " + r1$
  XuiSendStringMessage (label, @"SetTextString", 0, 0, 0, 0, 0, @text$)    ' set message text
  XuiSendStringMessage (label, @"Redraw", 0, 0, 0, 0, 0, 0)                ' redraw label
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

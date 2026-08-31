'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "tfile"
VERSION "0.0000"
'
IMPORT  "xst"
IMPORT  "xgr"
IMPORT  "xui"
'
INTERNAL FUNCTION  File            ( )
INTERNAL FUNCTION  GetDisplayGrid  ( @label )
INTERNAL FUNCTION  DisplayCallback ( grid, message$, v0, v1, v2, v3, kid, r1$ )
'
'
' ##################
' #####  File  #####
' ##################
'
FUNCTION  File ()
  STATIC  label
  $XuiFile = 29
'
  GetDisplayGrid ( @label )
'
' create window with XuiFile grid
'
  XuiCreateWindow      (@grid, @"XuiFile", 100, 256, 512, 384, 0, "")
  XuiSendStringMessage ( grid, @"SetCallback", grid, &XuiQueueCallbacks(), -1, -1, $XuiFile, -1)
  XuiSendStringMessage ( grid, @"SetGridName", 0, 0, 0, 0, 0, @"File")
  XuiSendStringMessage ( grid, @"SetTextString", 0, 0, 0, 0, 1, @"XuiFile")
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
  IF (v0 < 0) THEN
    file$ = "cancel"
  ELSE
    xx$ = ""
    attributes = 0
    XuiSendStringMessage (grid, @"GetTextString", 0, 0, 0, 0, 2, @file$)
    IF file$ THEN XstGetFileAttributes (@file$, @attributes)
    IFZ attributes THEN
      xx$ = xx$ + " $$FileNonexistent"
    ELSE
      SELECT CASE ALL TRUE
        CASE (attributes AND $$FileReadOnly)    : xx$ = xx$ + " $$FileReadOnly"
        CASE (attributes AND $$FileHidden)      : xx$ = xx$ + " $$FileHidden"
        CASE (attributes AND $$FileSystem)      : xx$ = xx$ + " $$FileSystem"
        CASE (attributes AND $$FileDirectory)   : xx$ = xx$ + " $$FileDirectory"
        CASE (attributes AND $$FileArchive)     : xx$ = xx$ + " $$FileArchive"
        CASE (attributes AND $$FileNormal)      : xx$ = xx$ + " $$FileNormal"
        CASE (attributes AND $$FileTemporary)   : xx$ = xx$ + " $$FileTemporary"
        CASE (attributes AND $$FileAtomicWrite) : xx$ = xx$ + " $$FileAtomicWrite"
        CASE (attributes AND $$FileExecutable)  : xx$ = xx$ + " $$FileExecutable"
      END SELECT
    END IF
  END IF
'
  text$ = "XuiFile\n"
  text$ = text$ + "    grid = " + HEX$ (grid, 8) + "\n"
  text$ = text$ + " message = " + message$ + "\n"
  text$ = text$ + "      v0 = " + HEX$ (v0,8) + "   : " + file$ + "\n"
  text$ = text$ + "      v1 = " + HEX$ (v1,8) + "   :" + xx$ + "\n"
  text$ = text$ + "      v2 = " + HEX$ (v2,8) + "\n"
  text$ = text$ + "      v3 = " + HEX$ (v3,8) + "\n"
  text$ = text$ + "     kid = " + HEX$ (kid,8) + "\n"
  text$ = text$ + "     r1$ = " + r1$
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

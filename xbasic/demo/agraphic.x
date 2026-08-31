'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"agraphic"
VERSION	"0.0003"
'
IMPORT	"xst"
IMPORT	"xgr"
'
' This program shows how to do graphics with functions
' in the XBasic GraphicsDesigner function library only.
' No GuiDesigner functions are called.
'
' This program creates a window, creates a single grid
' that fills the entire window, then draws a number of
' lines, circles, boxes, triangles and text in the grid.
'
' This program is primarily for programmers who want to
' add graphics to conventional programs but do not want
' to write GuiDesigner programs.
'
' This program demonstrates graphics in a normal window,
' then in simulated full screen mode.
'
' For examples of graphics in GuiDesigner programs,
' see the "acircle.x" and "ademo.x" sample programs.
'
' For examples on using graphics scaling see "DrawScaled.x" demo program.
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
'
FUNCTION  Entry ()
'
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
'
	GOSUB HalfSize
	XstSleep (4000)
	XgrDestroyWindow (window)
'
	GOSUB FullSize
	XstSleep (4000)
	XgrDestroyWindow (window)
	RETURN
'
'
' *****  HalfSize  *****
'
SUB HalfSize
	t = $$WindowTypeNormal
	x = #windowBorderWidth
	y = #windowBorderWidth + #windowTitleHeight
	w = (#displayWidth >> 1) - #windowBorderWidth - #windowBorderWidth
	h = (#displayHeight >> 1) - #windowBorderWidth - #windowBorderWidth - #windowTitleHeight
'
	XgrCreateWindow (@window, t, x, y, w, h, 0, "")
	XgrSetWindowTitle (window, @"GraphicsDesigner : simple demonstration")
	XgrCreateGrid (@grid, 0, 0, 0, w, h, window, 0, 0)
	XgrDisplayWindow (window)
'
	XgrClearGrid (grid, $$Black)
	XgrDrawLine (grid, $$LightYellow, 0, 0, w-1, h-1)
	XgrDrawLine (grid, $$LightGreen, w-1, 0, 0, h-1)
	x1 = (w >>> 2) - 1
	y1 = (h >>> 2) - 1
	x2 = w - (w >>> 2) - 1
	y2 = h - (h >>> 2) - 1
	XgrDrawBox (grid, $$LightBlue, x1, y1, x2, y2)
	r = h >>> 3
	XgrSetDrawpoint (grid, (w >> 1), (h >> 1))
	XgrDrawCircle (grid, $$LightRed, r)
	XgrDrawLine (grid, $$LightOrange, (w >> 1), 0, (w >> 1), h-1)
	XgrDrawLine (grid, $$LightCyan, 0, (h >> 1), w-1, (h >> 1))
	XgrSetDrawpoint (grid, (w >> 1), (h >> 1))
	XgrDrawCircle (grid, $$LightMagenta, r >> 1)
	XgrFillBox (grid, $$Grey, w - (w >> 3), h - (h >> 2), w - (w >> 4), h - (h >> 3) - 16)
	XgrFillTriangle (grid, $$Aqua, 0, $$TriangleUp, w >> 3, h >> 2, (w >> 2) - 8, (h >> 1) - 8)
	XgrSetDrawpoint (grid, (w >> 2), (h >> 3))
	XgrDrawText (grid, $$BrightGreen, @"draw simple graphics")
	XgrCreateFont (@font, @"Comic Sans MS", 480, 400, 0, 0)
	XgrSetDrawpoint (grid, (w >> 1) + 16, (h >> 3))
	XgrSetGridFont (grid, font)
	XgrDrawText (grid, $$BrightBlue, @"draw simple graphics")
END SUB
'
'
' *****  FullSize  *****
'
SUB FullSize
	x = 0
	y = 0
	w = #displayWidth
	h = #displayHeight
	t = $$WindowTypeNoFrame
'
	XgrCreateWindow (@window, t, x, y, w, h, 0, "")
	XgrSetWindowTitle (window, @"GraphicsDesigner : simple demonstration")
	XgrCreateGrid (@grid, 0, 0, 0, w, h, window, 0, 0)
	XgrDisplayWindow (window)
	XgrClearGrid (grid, $$Blue)
	XgrDrawLine (grid, $$LightGrey, 0, 0, w-1, 0)
	XgrDrawLine (grid, $$LightGrey, 0, 0, 0, h-1)
	XgrDrawLine (grid, $$LightCyan, 0, h-1, w-1, h-1)
	XgrDrawLine (grid, $$LightCyan, w-1, 0, w-1, h-1)
	XgrDrawLine (grid, $$LightGreen, w-1, 0, 0, h-1)
	XgrDrawLine (grid, $$LightYellow, 0, 0, w-1, h-1)
'
	XstSleep(2000)
	XgrClearGrid (grid, $$Black)
	XgrDrawLine (grid, $$Grey, 0, 0, w-1, 0)
	XgrDrawLine (grid, $$Grey, 0, 0, 0, h-1)
	XgrDrawLine (grid, $$Cyan, 0, h-1, w-1, h-1)
	XgrDrawLine (grid, $$Cyan, w-1, 0, w-1, h-1)
	XgrDrawLine (grid, $$LightYellow, 0, 0, w-1, h-1)
	XgrDrawLine (grid, $$LightGreen, w-1, 0, 0, h-1)
	x1 = (w >>> 2) - 1
	y1 = (h >>> 2) - 1
	x2 = w - (w >>> 2) - 1
	y2 = h - (h >>> 2) - 1
	XgrDrawBox (grid, $$LightBlue, x1, y1, x2, y2)
	r = h >>> 3
	XgrSetDrawpoint (grid, (w >> 1), (h >> 1))
	XgrDrawCircle (grid, $$LightRed, r)
	XgrDrawLine (grid, $$LightOrange, (w >> 1), 0, (w >> 1), h-1)
	XgrDrawLine (grid, $$LightCyan, 0, (h >> 1), w-1, (h >> 1))
	XgrSetDrawpoint (grid, (w >> 1), (h >> 1))
	XgrDrawCircle (grid, $$LightMagenta, r >> 1)
	XgrFillBox (grid, $$Grey, w - (w >> 3), h - (h >> 2), w - (w >> 4), h - (h >> 3) - 16)
	XgrFillTriangle (grid, $$Aqua, 0, $$TriangleUp, (w >> 1) + (w >> 3), h >> 2, (w >> 1) + (w >> 2) - 8, (h >> 1) - 8)
	XgrSetDrawpoint (grid, (w >> 2), (h >> 3))
	XgrDrawText (grid, $$BrightGreen, @"draw simple graphics")
	XgrCreateFont (@font, @"Comic Sans MS", 480, 400, 0, 0)
	XgrSetDrawpoint (grid, (w >> 1) + 16, (h >> 3))
	XgrSetGridFont (grid, font)
	XgrDrawText (grid, $$BrightBlue, @"draw simple graphics")
	XgrDestroyFont (font)
'
' draw all 256 characters of text in four lines
'
	a0$ = ""
	FOR i = 0x00 TO 0x3F
		a0$ = a0$ + CHR$(i)
	NEXT i
'
	a1$ = ""
	FOR i = 0x40 TO 0x7F
		a1$ = a1$ + CHR$(i)
	NEXT i
'
	a2$ = ""
	FOR i = 0x80 TO 0xBF
		a2$ = a2$ + CHR$(i)
	NEXT i
'
	a3$ = ""
	FOR i = 0xC0 TO 0xFF
		a3$ = a3$ + CHR$(i)
	NEXT i
'
	XgrCreateFont (@tfont, @"Courier New", 280, 400, 0, 0)
	XgrSetGridFont (grid, tfont)
'
	XgrSetDrawpoint (grid, 160, h-240)
	XgrDrawText (grid, $$BrightCyan, "#####  font = Courier New")
'
	XgrSetDrawpoint (grid, 160, h-220)
	XgrDrawText (grid, $$BrightCyan, a0$)
'
	XgrSetDrawpoint (grid, 160, h-200)
	XgrDrawText (grid, $$BrightCyan, a1$)
'
	XgrSetDrawpoint (grid, 160, h-180)
	XgrDrawText (grid, $$BrightCyan, a2$)
'
	XgrSetDrawpoint (grid, 160, h-160)
	XgrDrawText (grid, $$BrightCyan, a3$)
	XgrDestroyFont (tfont)
'
	tfont = 0
	XgrSetGridFont (grid, tfont)
'
	XgrSetDrawpoint (grid, 160, h-120)
	XgrDrawText (grid, $$BrightCyan, "#####  font = default")
'
	XgrSetDrawpoint (grid, 160, h-100)
	XgrDrawText (grid, $$BrightCyan, a0$)
'
	XgrSetDrawpoint (grid, 160, h-80)
	XgrDrawText (grid, $$BrightCyan, a1$)
'
	XgrSetDrawpoint (grid, 160, h-60)
	XgrDrawText (grid, $$BrightCyan, a2$)
'
	XgrSetDrawpoint (grid, 160, h-40)
	XgrDrawText (grid, $$BrightCyan, a3$)
'
'
' draw box around grey-scales
'
	XgrDrawLine (grid, $$LightYellow,  18,  98,  18, 261)
	XgrDrawLine (grid, $$LightYellow,  20,  98, 533, 354)
	XgrDrawLine (grid, $$LightYellow,  20, 262, 533, 518)
	XgrDrawLine (grid, $$LightYellow, 533, 355, 533, 517)
'
' draw a grey-scale in 8 colors (one color is black)
'
	FOR c = 0 TO 7
		FOR i = 0 TO 255
			x = (i << 1) + 20
			y = i + 100 + (c * 20)
			w = 2
			h = 20
			IF (c AND 0b001) THEN b = i ELSE b = 0
			IF (c AND 0b010) THEN g = i ELSE g = 0
			IF (c AND 0b100) THEN r = i ELSE r = 0
			color = (r << 24) OR (g << 16) OR (b << 8)
			XgrFillBox (grid, color, x, y, x+w-1, y+h-1)
	NEXT i
	NEXT c
END SUB
END FUNCTION
END PROGRAM

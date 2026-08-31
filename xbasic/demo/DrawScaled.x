'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"DrawScaled"
VERSION	"0.0002"
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
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  Draw (grid)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
'
FUNCTION  Entry ()
	'
	XgrGetDisplaySize (display$, @width, @height, @borderWidth, @titleHeight)
	XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
	'
	t = $$WindowTypeNormal
	x = workAreaX + borderWidth
	y = workAreaY + borderWidth + titleHeight
	h = workAreaHeight - borderWidth - borderWidth - titleHeight
	w = h
	'
	XgrCreateWindow (@window, t, x, y, w, h, 0, "")
	XgrSetWindowTitle (window, @"DrawScaled : simple demonstration")
	XgrCreateGrid (@grid, 0, 0, 0, w, h, window, 0, 0)
	XgrDisplayWindow (window)
	'
	XgrSetGridBoxScaled (grid, 0, 0, 100, 100)
	Draw (grid)
	XstSleep (1000)
	'
	XgrSetGridBoxScaled (grid, 0, 100, 100, 0)
	Draw (grid)
	XstSleep (1000)
	'
	XgrSetGridBoxScaled (grid, 100, 100, 0, 0)
	Draw (grid)
	XstSleep (1000)
	'
	XgrSetGridBoxScaled (grid, 100, 0, 0, 100)
	Draw (grid)
	XstSleep (1000)
'
'
'
	FOR scaleChange = 0 TO 50
		xz = 0 - scaleChange
		yz = 0 - scaleChange
		wz = 100 + scaleChange
		hz = 100 + scaleChange

		XgrSetGridBoxScaled (grid, xz, yz, wz, hz)
		Draw (grid)
		XstSleep (100)
		XstSleep (100)
	NEXT scaleChange
	XstSleep (2000)
'
'
	XgrCreateGrid  (@buffer, 1, 0, 0, w, h, window, grid, 0)
	rc = XgrSetGridBuffer (grid, buffer, 0, 0)
	XgrSetGridBoxScaled (grid, 0, 0, 100, 100)
'
	FOR scaleChange = 0 TO 50
		xz = 0 - scaleChange
		yz = 0 - scaleChange
		wz = 100 + scaleChange
		hz = 100 + scaleChange

		XgrSetGridBoxScaled (buffer, xz, yz, wz, hz)
		Draw (buffer)
		XgrRefreshGrid (grid)
		XstSleep (50)
	NEXT scaleChange
	'
	XstSleep (2000)
	'
END FUNCTION
'
'
' #####################
' #####  Draw ()  #####
' #####################
'
FUNCTION  Draw (grid)
'
	XgrClearGrid (grid, $$Black)

	XgrFillBoxScaled (grid, $$LightBlue, 25, 25, 75, 75)
	XgrDrawBoxScaled (grid, $$LightYellow, 25, 25, 75, 75)
	XgrSetDrawpointScaled (grid, 50, 50)
	XgrFillCircleScaled (grid, $$LightGreen, 12.5)
	XgrDrawCircleScaled (grid, $$LightRed, 12.5)
	XgrDrawCircleScaled (grid, $$LightMagenta, 20)
	XgrDrawLineScaled (grid, $$Yellow, 0, 0, 100, 100)
	XgrDrawLineScaled (grid, $$LightCyan, 0, 50, 100, 50)
	XgrFillBoxScaled (grid, $$Grey, 87.5, 75, 93.75, 83)

	XgrFillTriangleScaled (grid, $$Aqua, 0, $$TriangleUp, 10, 25, 23, 48)

	XgrGetGridBoxScaled (grid, @x1#, @y1#, @x2#, @y2#)
	xdp# = (x2#-x1#)/4 + x1#
	ydp# = (y2#-y1#)/8 + y1#
'	XgrSetDrawpointScaled (grid, xdp#, ydp#)
	XgrSetDrawpointScaled (grid, 25, 12.5)
'	XgrSetGridFont (grid, font)
	XgrSetGridFont (grid, 0)
	XgrDrawTextScaled (grid, $$BrightGreen, @"draw simple graphics")
	ratio# = 100 / ABS(x1# - x2#)
	fontSize = 480 * ratio#
'	XgrCreateFont (@font, @"Comic Sans MS", 480, 400, 0, 0)
'	XgrCreateFont (@font, @"Comic Sans MS", fontSize, 400, 0, 0)
	XgrCreateFont (@font, @"Helvetica", fontSize, 400, 0, 0)
	ydp# = (y2#-y1#)*13/16 + y1#
	DIM text$[0]
	text$[0] = "draw simple graphics"
	XgrGetTextArrayImageSize (font, @text$[], @w, @h, @width, @height, extraX, extraY)
'	XgrSetDrawpointScaled (grid, xdp#, ydp#)
	XgrSetDrawpointScaled (grid, 25, 87.5)
	XgrSetGridFont (grid, font)
	XgrDrawTextScaled (grid, $$BrightBlue, @"draw simple graphics")

END FUNCTION
END PROGRAM

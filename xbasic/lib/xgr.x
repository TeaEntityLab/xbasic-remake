'
'
' ##############################  Max Reason
' #####  GraphicsDesigner  #####  copyright 1988-2000
' ##############################  Linux XBasic GraphicsDesigner
'
' subject to LGPL license - see COPYING_LIB
'
' maxreason@maxreason.com
'
' for Linux XBasic
'
'
PROGRAM	"xgr"
VERSION	"6.4.5"
'
IMPORT	"xma"			' math library
IMPORT	"xst"			' standard library
IMPORT	"clib"		' C standard library
IMPORT	"xwin"	  ' XWindows library
'
EXPORT
'
'
' **********************************************
' *****  GraphicsDesigner COMPOSITE TYPES  *****
' **********************************************
'
TYPE MESSAGE
	XLONG			.wingrid						' window/grid number
	XLONG			.message						' message number
	XLONG			.v0									' arguments
	XLONG			.v1
	XLONG			.v2
	XLONG			.v3
	XLONG			.r0
	XLONG			.r1
END TYPE
END EXPORT
'
'
' *****  DIB = Device Independent Bitmap  *****
'
' A complete DIB contains:
'   		1		BitmapFileHeader
'   		1		BitmapInfoHeader
'   0-256		RGBQUAD elements (the palette) (0-2 RGB mask for 16,32)
'				*		image data
'
TYPE BitmapFileHeader				' 14 bytes
	USHORT   .bfType					' "BM"
	XLONG    .bfSize					' total DIB file size in bytes
	USHORT   .res1						'
	USHORT   .res2						'
	XLONG    .bfOffBits				' offset from file beginning to image data
END TYPE
'
TYPE BitmapInfoHeader
	XLONG    .size						' size of BitmapInfoHeader in bytes
	XLONG    .width						' width of image in pixels
	XLONG    .height					' height of image in pixels
	USHORT   .planes          ' always = 1
	USHORT   .bitCount				' bits per pixel (1,4,8,16,24,32)
	XLONG    .compression			' compression scheme (0 = none, 3 = BI_BITFIELDS)
	XLONG    .sizeImage				' ignore unless image compression
	XLONG    .xPixelsPerMeter	'
	XLONG    .yPixelsPerMeter	'
	XLONG    .colors					' number of colors in image
	XLONG    .importantColors	' number of important colors in image
END TYPE
'
' In a DIB, RGBQUAD data follows BitmapInfoHeader if bitCount = 1,4,8
' This data defines the pallete - it maps each pixel value into RGB.
' For bitCount = 1,4,8 there are 2,16,256 RGBQUAD elements.
'
' For bitCount = 16,24,32 there are three XLONG values (not RGBQUAD),
' one each for a mask to define red,green,blue bit fields, as in:
'			red		: 0xFFC00000		' 10 bits of red
'			green	: 0x003FF800		' 11 bits of green
'			blue	: 0x000007FF		' 11 bits of blue
'
'
TYPE RGBQUAD								'
	UBYTE    .blue						'
	UBYTE    .green						'
	UBYTE    .red							'
	UBYTE    .zero						'
END TYPE
'
'	status bits
'		0:  1 = actions registered	(by XgrCreateWindow)
'		1:  1 = colormap installed	(by XgrCreateWindow)
'
TYPE DISPLAY									' 1024 bytes : host display information
	XLONG   .display            ' native display #
	XLONG   .sdisplay           ' system display #
	XLONG   .status							' 0 if not open
	XLONG   .selectedWindow     '
	XLONG   .x                  ' should be 0
	XLONG   .y                  ' should be 0
	XLONG   .width              '
	XLONG   .height             '
	XLONG		.root								' native root window # (someday)
	XLONG   .reserved						'
	XLONG   .borderWidth       	' nominal
	XLONG   .titleHeight        ' nominal
	XLONG   .mouseX             '
	XLONG   .mouseY             '
	XLONG		.mouseState         '
	XLONG   .mouseTime          '
	XLONG		.mouseGrid          '
	XLONG   .mouseWindow        '
	XLONG   .mouseMessage       '
	XLONG   .mouseFocusGrid     ' ignored
	XLONG   .depth              '
	XLONG   .class              '
	XLONG		.screen							' X-Windows screen
	XLONG		.visual							' screen visual
	XLONG		.sroot              ' system root window #
	XLONG   .connect            ' connection file descriptor
	XLONG   .bitGravity         '
	XLONG   .winGravity         '
	XLONG   .backingStore       '
	XLONG   .backingPlanes      '
	XLONG   .backingPixel       '
	XLONG   .saveUnder          '
	XLONG   .mapInstalled       '
	XLONG   .mapState           '
	XLONG   .allEventMasks      '
	XLONG   .yourEventMask      '
	XLONG   .doNotPropagateMask '
	XLONG   .overrideRedirect   '
	XLONG   .defaultColormap    '
	XLONG   .colormap           '
	XLONG   .black              ' system color #
	XLONG   .white              ' system color #
	XLONG   .resyyy             '
	XLONG   .reszzz             '
	XLONG   .color[127]         ' native color # to system color #
	XLONG   .wmXoffset          ' new window managers have large transparent resizing border
	XLONG   .wmYoffset          ' new window managers have large transparent resizing border
	XLONG		.a[81]              ' pad / reserved
END TYPE
'
' *********************************
' *****  Xgr COMPOSITE TYPES  *****
' *********************************
'
EXPORT
TYPE FONT
	XLONG   .font								' native font #
	XLONG   .sfont							' system font #
	XLONG   .addrFont						' system font structure address
	XLONG   .count							' number of times created
	XLONG   .width							' max width of character cell
	XLONG   .height							' max height of character cell
	XLONG   .ascent							' baseline to highest top
	XLONG   .descent						' baseline to lowest bottom
	XLONG   .size               ' point size * 10
	XLONG   .weight             ' 0-1000 : thin, light, medium, bold, heavy
	XLONG   .italic             ' 0-1000 : slant-left, upright, slant-right
	XLONG   .angle              ' baseline angle in .1 degree units
	XLONG   .space
	XLONG   .gap
	XLONG   .resX
	XLONG   .resY
END TYPE
END EXPORT
'
TYPE POINT
	XLONG		.x									' x position
	XLONG		.y									' y position
END TYPE
'
TYPE DPOINT
	DOUBLE	.x									' x# position
	DOUBLE	.y									' y# position
END TYPE
'
TYPE BOX
	XLONG		.x1									' x position of 1st corner
	XLONG		.y1									' y position of 1st corner
	XLONG		.x2									' x position of 2nd corner
	XLONG		.y2									' y position of 2nd corner
END TYPE
'
TYPE DBOX
	DOUBLE	.x1									' x# position of 1st corner
	DOUBLE	.y1									' y# position of 1st corner
	DOUBLE	.x2									' x# position of 2nd corner
	DOUBLE	.y2									' y# position of 2nd corner
END TYPE
'
TYPE LINE = BOX
TYPE DLINE = DBOX
'
TYPE WINDOW                   ' 512 bytes : native window and grid information
	SLONG   .window             ' 00 : 0 if unallocated (wingrid #0 is invalid)
	SLONG   .parent             ' 01 : native parent #
	SLONG   .leader             ' 02 : native window # this window follows
	SLONG   .kind               ' 03 : top window, grid, etc.
	SLONG   .type               ' 04 : window/grid type (windowType/gridType)
	SLONG   .top                ' 05 : native window # of top window in family
	XLONG   .winFunc            ' 06 : native window function address
	XLONG   .gridFunc           ' 08 : native grid function address
	XLONG   .display            ' 0A : native display #
	SLONG   .buffer             ' 0B : image grid to buffer graphics
	SLONG   .bufferX            ' 0C : image buffer x axis relative to the grid (bufferX1 - gridX1)
	SLONG   .bufferY            ' 0D : image buffer y axis relative to the grid (bufferY1 - gridY1)
	SLONG   .font               ' 0E : native font #
	SLONG   .border             ' 0F : current border # or function to draw it
	SLONG   .borderUp           ' 10 : normal border # or function to draw it
	SLONG   .borderDown         ' 11 : active border # or function to draw it
	SLONG   .backgroundColor    ' 12 : native color # of background color
	SLONG   .drawingColor       ' 13 : native color # of drawing color
	SLONG   .lowlightColor      ' 14 : native color # of 3D shadow color
	SLONG   .highlightColor     ' 15 : native color # of 3D highlight color
	SLONG   .dullColor          ' 16 : native color # of dull color
	SLONG   .accentColor        ' 17 : native color # of accent color
	SLONG   .lowtextColor       ' 18 : native color # of 3D text shadow color
	SLONG   .hightextColor      ' 19 : native color # of 3D text highlight color
	SLONG   .backColor          ' 1A : standard color of current background color
	SLONG   .backBlue           ' 1B : blue intensity of current background color
	SLONG   .backGreen          ' 1C : green intensity of current background color
	SLONG   .backRed            ' 1D : red intensity of current background color
	SLONG   .drawColor          ' 1E : standard color of current drawing color
	SLONG   .drawBlue           ' 1F : blue intensity of current drawing color
	SLONG   .drawGreen          ' 20 : green intensity of current drawing color
	SLONG   .drawRed            ' 21 : red intensity of current drawing color
	SLONG   .priorX             ' 22 : previous X position
	SLONG   .priorY             ' 23 : previous Y position
	SLONG   .priorWidth         ' 24 : previous width
	SLONG   .priorHeight        ' 25 : previous height
	SLONG   .visibility         ' 26 : hidden/displayed/iconified (0/1/2,3)
	SLONG   .priorVisibility    ' 27 : previous visibility
	SLONG   .visibilityRequest  ' 28 : visibility function called, waiting for event to confirm
	SLONG   .mapped             ' 29 : changed only by MapNotify/UnmapNotify
	SLONG   .lineWidth          ' 2A : last lineWidth
	SLONG   .lineStyle          ' 2B : last lineStyle
	SLONG   .drawMode           ' 2C : last drawMode
	SLONG   .state              ' 2D : window or grid disable / enable
	SLONG   .borderWidth        ' 2E : in pixels - determined in "reparent" event
	SLONG   .titleHeight        ' 2F : in pixels - determined in "reparent" event
	SLONG   .whomask            ' 30 : owner ##WHOMASK
	SLONG   .timer              ' 31 : timer ID
	SLONG   .x                  ' 32 : left edge of window on parent or display
	SLONG   .y                  ' 33 : top edge of window on parent or display
	SLONG   .width              ' 34 : width of window interior
	SLONG   .height             ' 35 : height of window interior
	SLONG   .minWidth           ' 36 : minimum width
	SLONG   .minHeight          ' 37 : minimum height
	SLONG   .maxWidth           ' 38 : maximum width
	SLONG   .maxHeight          ' 39 : maximum height
	SLONG   .borderOffsetLeft   ' 3A :
	SLONG   .borderOffsetTop    ' 3B :
	SLONG   .borderOffsetRight  ' 3C :
	SLONG   .borderOffsetBottom ' 3D :
	SLONG   .gridBoxX1          ' 3E : corners of grid-box in grid coords
	SLONG   .gridBoxY1          ' 3F : corners of grid-box in grid coords
	SLONG   .gridBoxX2          ' 40 : corners of grid-box in grid coords
	SLONG   .gridBoxY2          ' 41 : corners of grid-box in grid coords
	DOUBLE  .gridBoxScaledX1    ' 42 : corners of grid-box in scaled coords
	DOUBLE  .gridBoxScaledY1    ' 44 : corners of grid-box in scaled coords
	DOUBLE  .gridBoxScaledX2    ' 46 : corners of grid-box in scaled coords
	DOUBLE  .gridBoxScaledY2    ' 48 : corners of grid-box in scaled coords
	DOUBLE  .xPixelsPerScaled   ' 4A : x grid units equal 1 scaled unit (signed)
	DOUBLE  .yPixelsPerScaled   ' 4C : y grid units equal 1 scaled unit (signed)
	DOUBLE  .xScaledPerPixel    ' 4E : x scaled units equal 1 grid unit (signed)
	DOUBLE  .yScaledPerPixel    ' 50 : y scaled units equal 1 grid unit (signed)
	DOUBLE  .drawpointScaledX   ' 52 : scaled coords
	DOUBLE  .drawpointScaledY   ' 54 : scaled coords
	SLONG   .drawpointGridX     ' 56 : gridbox coords
	SLONG   .drawpointGridY     ' 57 : gridbox coords
	SLONG   .drawpointX         ' 58 : local coords
	SLONG   .drawpointY         ' 59 : local coords
	SLONG   .clipX              ' 5A : left edge of clip box
	SLONG   .clipY              ' 5B : top edge of clip box
	SLONG   .clipWidth          ' 5C : current clipping width
	SLONG   .clipHeight         ' 5D : current clipping height
	SLONG   .icon               ' 5E :
	SLONG   .sicon              ' 5F :
	SLONG   .iconWidth          ' 60 :
	SLONG   .iconHeight         ' 61 :
	SLONG   .stop               ' 62 : system window # of top window in family x
	SLONG   .sroot              ' 63 : system window # of root window x
	SLONG   .sframe             ' 64 : system window # of frame window (motif) x
	XLONG   .sdisplay           ' 65 : system display # x
	SLONG   .swindow            ' 66 : system window # x
	SLONG   .sparent            ' 67 : system parent window # x
	SLONG   .scursor            ' 68 : system cursor # x
	XLONG   .gc                 ' 69 : graphics context
	SLONG   .visual             ' 6A : address of system visual structure x
	SLONG   .clickTime          ' 6B : last mouse button down time
	SLONG   .clickCount         ' 6C : count of mouse button clicks
	SLONG   .clickButton        ' 6D : # of last mouse button down
	SLONG   .sbackground        ' 6E : current system background pixel x
	SLONG   .sforeground        ' 6F : current system foreground pixel x
	SLONG   .sbackgroundDefault ' 70 : system background pixel for default background color
	SLONG   .sforegroundDefault ' 71 : system foreground pixel for default drawing color
	SLONG   .eventMask          ' 72 : XSelectInput() event mask
	SLONG   .configureRequest   ' 73 : window size and position change called, waiting for event to confirm
	SLONG   .x74                ' 74 :
	SLONG   .lastIn             ' 75 : message queue index of the last added message for this window
	SLONG   .wmXoffset          ' 76 : new window managers have large transparent resizing border
	SLONG   .wmYoffset          ' 77 : new window managers have large transparent resizing border
	SLONG   .x78                ' 78 :
	SLONG   .x79                ' 79 :
	SLONG   .x7A                ' 7A :
	SLONG   .x7B                ' 7B :
	SLONG   .destroy            ' 7C : destroy requested
	SLONG   .destroyed          ' 7D : destroyed event processed
	SLONG   .destroyProcessed 	' 7E : destroyed message processed
	SLONG   .x7F                ' 7F :
END TYPE
'
'TYPE MOUSESTATE
'	XLONG   .type               '
'	XLONG   .window             '
'	XLONG   .swindow            '
'	XLONG   .time               '
'	XLONG   .xWin               '
'	XLONG   .yWin               '
'	XLONG   .xDisp              '
'	XLONG   .yDisp              '
'	XLONG   .state              '
'	XLONG   .button             ' 0 for motion event
'	XLONG   .res1[5]
'END TYPE
'
'
' *****  xlib "fake" types  *****
'
' TYPE Display     = XLONG       '
' TYPE Screen      = XLONG       '
' TYPE Visual      = XLONG       '
' TYPE Pixmap      = XLONG       '
' TYPE GC          = XLONG       ' address of opaque structure
' TYPE Font        = XLONG       ' font ID number
' TYPE XFontStruct = XLONG       ' address of font structure
'
'	typedef struct {
'		int type;
'		Display *display;	/* Display the event was read from */
'		XID resourceid;		/* resource id */
'		unsigned long serial;	/* serial number of failed request */
'		unsigned char error_code;	/* error code of failed request */
'		unsigned char request_code;	/* Major op-code of failed request */
'		unsigned char minor_code;	/* Minor op-code of failed request */
'	} XErrorEvent;
'
' #######################
' #####  FUNCTIONS  #####
' #######################
'
' miscellaneous functions
'
EXPORT
DECLARE FUNCTION  Xgr                         ()
DECLARE FUNCTION  XgrBorderNameToNumber       (border$, @border)
DECLARE FUNCTION  XgrBorderNumberToName       (border, @border$)
DECLARE FUNCTION  XgrBorderNumberToWidth      (border, @width)
DECLARE FUNCTION  XgrColorNameToNumber        (color$, @color)
DECLARE FUNCTION  XgrColorNumberToName        (color, @color$)
DECLARE FUNCTION  XgrCursorNameToNumber       (cursor$, @cursor)
DECLARE FUNCTION  XgrCursorNumberToName       (cursor, @cursor$)
DECLARE FUNCTION  XgrGetClipboard             (clipboard, type, @data$, UBYTE @data[])
DECLARE FUNCTION  XgrGetCursor                (cursor)
DECLARE FUNCTION  XgrGetCursorOverride        (cursor)
DECLARE FUNCTION  XgrGetDisplayOffset         (display$, @xOffset, @yOffset, @bw, @th)
DECLARE FUNCTION  XgrGetDisplaySize           (display$, @w, @h, @bw, @th)
DECLARE FUNCTION  XgrGetKeystateModify        (state, @modify, @edit)
DECLARE FUNCTION  XgrGetWorkArea              (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
DECLARE FUNCTION  XgrIconNameToNumber         (icon$, @icon)
DECLARE FUNCTION  XgrIconNumberToName         (icon, @icon$)
DECLARE FUNCTION  XgrRegisterCursor           (cursor$, @cursor)
DECLARE FUNCTION  XgrRegisterIcon             (icon$, @icon)
DECLARE FUNCTION  XgrSetClipboard             (clipboard, type, @data$, UBYTE @data[])
DECLARE FUNCTION  XgrSetCursor                (cursor, @oldCursor)
DECLARE FUNCTION  XgrSetCursorOverride        (cursor, @oldCursorOverride)
DECLARE FUNCTION  XgrSetDebug                 (debug)
DECLARE FUNCTION  XgrSetGridCursor            (grid, cursor)
DECLARE FUNCTION  XgrSystemWindowToWindow     (swindow, @wingrid, @top)
DECLARE FUNCTION  XgrWindowToSystemWindow     (wingrid, @swindow)
DECLARE FUNCTION  XgrVersion$                 ()
'
' font functions
'
DECLARE FUNCTION  XgrCreateFont               (@font, fontName$, fontSize, fontWeight, fontItalic, fontAngle)
DECLARE FUNCTION  XgrDestroyFont              (font)
DECLARE FUNCTION  XgrGetFontInfo              (font, @fontName$, @fontSize, @fontWeight, @fontItalic, @fontAngle)
DECLARE FUNCTION  XgrGetFontMetrics           (font, @maxCharWidth, @maxCharHeight, @ascent, @descent, @gap, @space)
DECLARE FUNCTION  XgrGetFontNames             (@count, @fontName$[])
DECLARE FUNCTION  XgrGetTextArrayImageSize    (font, @text$[], @w, @h, @width, @height, extraX, extraY)
DECLARE FUNCTION  XgrGetTextImageSize         (font, @text$, @dx, @dy, @width, @height, @gap, @space)
'
' color functions
'
DECLARE FUNCTION  XgrConvertColorToRGB        (color, red, green, blue)
DECLARE FUNCTION  XgrConvertRGBToColor        (red, green, blue, color)
DECLARE FUNCTION  XgrGetBackgroundColor       (grid, color)
DECLARE FUNCTION  XgrGetBackgroundRGB         (grid, red, green, blue)
DECLARE FUNCTION  XgrGetDefaultColors         (back, draw, low, high, dull, acc, lowtext, hightext)
DECLARE FUNCTION  XgrGetDrawingColor          (grid, color)
DECLARE FUNCTION  XgrGetDrawingRGB            (grid, red, green, blue)
DECLARE FUNCTION  XgrGetGridColors            (grid, back, draw, low, high, dull, acc, lowtext, hightext)
DECLARE FUNCTION  XgrSetBackgroundColor       (grid, color)
DECLARE FUNCTION  XgrSetBackgroundRGB         (grid, red, green, blue)
DECLARE FUNCTION  XgrSetDefaultColors         (back, draw, low, high, dull, acc, lowtext, hightext)
DECLARE FUNCTION  XgrSetDrawingColor          (grid, color)
DECLARE FUNCTION  XgrSetDrawingRGB            (grid, red, green, blue)
DECLARE FUNCTION  XgrSetGridColors            (grid, back, draw, low, high, dull, acc, lowtext, hightext)
'
' window functions
'
DECLARE FUNCTION  XgrCreateWindow             (@window, windowType, x, y, width, height, winFunc, display$)
DECLARE FUNCTION  XgrDestroyWindow            (window)
DECLARE FUNCTION  XgrDisplayWindow            (window)
DECLARE FUNCTION  XgrFullscreenWindow         (window)
DECLARE FUNCTION  XgrGetModalWindow           (@window)
DECLARE FUNCTION  XgrGetWindowDisplay         (window, @display$)
DECLARE FUNCTION  XgrGetWindowFunction        (window, @func)
DECLARE FUNCTION  XgrGetWindowIcon            (window, @icon)
DECLARE FUNCTION  XgrGetWindowGrid            (window, @grid)
DECLARE FUNCTION  XgrGetWindowPositionAndSize (window, @x, @y, @width, @height)
DECLARE FUNCTION  XgrGetWindowState           (window, @visibility)
DECLARE FUNCTION  XgrGetWindowTitle           (window, @title$)
DECLARE FUNCTION  XgrGetWindowVisibility      (window, @visibility)
DECLARE FUNCTION  XgrHideWindow               (window)
DECLARE FUNCTION  XgrMaximizeWindow           (window)
DECLARE FUNCTION  XgrMinimizeWindow           (window)
DECLARE FUNCTION  XgrPlaceWindow              (windowType, xDisp, yDisp, width, height)
DECLARE FUNCTION  XgrRestoreWindow            (window)
DECLARE FUNCTION  XgrSetModalWindow           (window)
DECLARE FUNCTION  XgrSetWindowFunction        (window, func)
DECLARE FUNCTION  XgrSetWindowIcon            (window, icon)
DECLARE FUNCTION  XgrSetWindowMaxMinSize      (window)
DECLARE FUNCTION  XgrSetWindowPositionAndSize (window, xDisp, yDisp, width, height)
DECLARE FUNCTION  XgrSetWindowState           (window, visibility)
DECLARE FUNCTION  XgrSetWindowTitle           (window, title$)
DECLARE FUNCTION  XgrSetWindowVisibility      (window, visibility)
DECLARE FUNCTION  XgrShowWindow               (window)
'
' coordinate functions
'
DECLARE FUNCTION  XgrConvertDisplayToGrid     (grid, xDisp, yDisp, @xGrid, @yGrid)
DECLARE FUNCTION  XgrConvertDisplayToLocal    (grid, xDisp, yDisp, @x, @y)
DECLARE FUNCTION  XgrConvertDisplayToScaled   (grid, xDisp, yDisp, @x#, @y#)
DECLARE FUNCTION  XgrConvertDisplayToWindow   (grid, xDisp, yDisp, @xWin, @yWin)
DECLARE FUNCTION  XgrConvertGridToDisplay     (grid, xGrid, yGrid, @xDisp, @yDisp)
DECLARE FUNCTION  XgrConvertGridToLocal       (grid, xGrid, yGrid, @x, @y)
DECLARE FUNCTION  XgrConvertGridToScaled      (grid, xGrid, yGrid, @x#, @y#)
DECLARE FUNCTION  XgrConvertGridToWindow      (grid, xGrid, yGrid, @xWin, @yWin)
DECLARE FUNCTION  XgrConvertLocalToDisplay    (grid, x, y, @xDisp, @yDisp)
DECLARE FUNCTION  XgrConvertLocalToGrid       (grid, x, y, @xGrid, @yGrid)
DECLARE FUNCTION  XgrConvertLocalToScaled     (grid, x, y, @x#, @y#)
DECLARE FUNCTION  XgrConvertLocalToWindow     (grid, x, y, @xWin, @yWin)
DECLARE FUNCTION  XgrConvertScaledToDisplay   (grid, x#, y#, @xDisp, @yDisp)
DECLARE FUNCTION  XgrConvertScaledToGrid      (grid, x#, y#, @x, @y)
DECLARE FUNCTION  XgrConvertScaledToLocal     (grid, x#, y#, @x, @y)
DECLARE FUNCTION  XgrConvertScaledToWindow    (grid, x#, y#, @xWin, @yWin)
DECLARE FUNCTION  XgrConvertWindowToDisplay   (grid, xWin, yWin, @xDisp, @yDisp)
DECLARE FUNCTION  XgrConvertWindowToGrid      (grid, xWin, yWin, @xGrid, @yGrid)
DECLARE FUNCTION  XgrConvertWindowToLocal     (grid, xWin, yWin, @x, @y)
DECLARE FUNCTION  XgrConvertWindowToScaled    (grid, xWin, yWin, @x#, @y#)
'
DECLARE FUNCTION  XgrGetGridBox               (grid, @x1Grid, @y1Grid, @x2Grid, @y2Grid)
DECLARE FUNCTION  XgrGetGridBoxDisplay        (grid, @x1Disp, @y1Disp, @x2Disp, @y2Disp)
DECLARE FUNCTION  XgrGetGridBoxGrid           (grid, @x1Grid, @y1Grid, @x2Grid, @y2Grid)
DECLARE FUNCTION  XgrGetGridBoxLocal          (grid, @x1, @y1, @x2, @y2)
DECLARE FUNCTION  XgrGetGridBoxScaled         (grid, @x1#, @y1#, @x2#, @y2#)
DECLARE FUNCTION  XgrGetGridBoxWindow         (grid, @x1Win, @y1Win, @x2Win, @y2Win)
DECLARE FUNCTION  XgrGetGridCoordinates       (grid, @x, @y, @x1, @y1, @x2, @y2)
DECLARE FUNCTION  XgrGetGridCoords       (grid, @x, @y, @x1, @y1, @x2, @y2)
DECLARE FUNCTION  XgrGetGridPositionAndSize   (grid, @x, @y, @width, @height)
DECLARE FUNCTION  XgrSetGridBox               (grid, x1Grid, y1Grid, x2Grid, y2Grid)
DECLARE FUNCTION  XgrSetGridBoxGrid           (grid, x1Grid, y1Grid, x2Grid, y2Grid)
DECLARE FUNCTION  XgrSetGridBoxScaled         (grid, x1#, y1#, x2#, y2#)
DECLARE FUNCTION  XgrSetGridBoxScaledAt       (grid, x1#, y1#, x2#, y2#, x1, y1, x2, y2)
DECLARE FUNCTION  XgrSetGridPositionAndSize   (grid, x, y, width, height)
'
' grid functions
'
DECLARE FUNCTION  XgrCreateGrid               (@grid, gridType, x, y, width, height, window, parent, func)
DECLARE FUNCTION  XgrDestroyGrid              (grid)
DECLARE FUNCTION  XgrGetGridBorder            (grid, @border, @borderA, @borderB, @borderFlags)
DECLARE FUNCTION  XgrGetGridBorderOffset      (grid, @left, @top, @right, @bottom)
DECLARE FUNCTION  XgrGetGridBuffer            (grid, @buffer, @x, @y)
DECLARE FUNCTION  XgrGetGridCharacterMapArray (grid, @map[])
DECLARE FUNCTION  XgrGetGridDrawingMode       (grid, @mode, @lineStyle, @lineWidth)
DECLARE FUNCTION  XgrGetGridFont              (grid, @font)
DECLARE FUNCTION  XgrGetGridFunction          (grid, @func)
DECLARE FUNCTION  XgrGetGridParent            (grid, @parent)
DECLARE FUNCTION  XgrGetGridState             (grid, @state)
DECLARE FUNCTION  XgrGetGridTimerID           (grid, @timeOutID)
DECLARE FUNCTION  XgrGetGridType              (grid, @type)
DECLARE FUNCTION  XgrGetGridWindow            (grid, @window)
DECLARE FUNCTION  XgrGridTypeNameToNumber     (type$, @type)
DECLARE FUNCTION  XgrGridTypeNumberToName     (type, @type$)
DECLARE FUNCTION  XgrRegisterGridType         (type$, @type)
DECLARE FUNCTION  XgrSetGridBorder            (grid, border, borderA, borderB, borderFlags)
DECLARE FUNCTION  XgrSetGridBorderOffset      (grid, left, top, right, bottom)
DECLARE FUNCTION  XgrSetGridBuffer            (grid, buffer, x, y)
DECLARE FUNCTION  XgrSetGridDrawingMode       (grid, mode, lineStyle, lineWidth)
DECLARE FUNCTION  XgrSetGridFont              (grid, font)
DECLARE FUNCTION  XgrSetGridFunction          (grid, func)
DECLARE FUNCTION  XgrSetGridParent            (grid, parent)
DECLARE FUNCTION  XgrSetGridState             (grid, state)
DECLARE FUNCTION  XgrSetGridTimer             (grid, msec)
DECLARE FUNCTION  XgrSetGridType              (grid, type)
DECLARE FUNCTION  XgrSetGridCharacterMapArray (grid, @map[])
'
' drawing functions
'
DECLARE FUNCTION  XgrClearGrid                (grid, color)
DECLARE FUNCTION  XgrClearWindow              (window, color)
DECLARE FUNCTION  XgrDrawArc                  (grid, color, r, startAngle#, endAndge#)
DECLARE FUNCTION  XgrDrawArcGrid              (grid, color, r, startAngle#, endAndge#)
DECLARE FUNCTION  XgrDrawArcScaled            (grid, color, r#, startAngle#, endAndge#)
DECLARE FUNCTION  XgrDrawBorder               (grid, border, back, low, high, x1, y1, x2, y2)
DECLARE FUNCTION  XgrDrawBorderGrid           (grid, border, back, low, high, x1Grid, y1Grid, x2Grid, y2Grid)
DECLARE FUNCTION  XgrDrawBorderScaled         (grid, border, back, low, high, x1#, y1#, x2#, y2#)
DECLARE FUNCTION  XgrDrawBox                  (grid, color, x1, y1, x2, y2)
DECLARE FUNCTION  XgrDrawBoxGrid              (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
DECLARE FUNCTION  XgrDrawBoxScaled            (grid, color, x1#, y1#, x2#, y2#)
DECLARE FUNCTION  XgrDrawCircle               (grid, color, r)
DECLARE FUNCTION  XgrDrawCircleGrid           (grid, color, r)
DECLARE FUNCTION  XgrDrawCircleScaled         (grid, color, r#)
DECLARE FUNCTION  XgrDrawEllipse              (grid, color, rx, ry)
DECLARE FUNCTION  XgrDrawEllipseGrid          (grid, color, rx, ry)
DECLARE FUNCTION  XgrDrawEllipseScaled        (grid, color, rx#, ry#)
DECLARE FUNCTION  XgrDrawCurve                (grid, color, segments, x0, y0, x1, y1, x2, y2, x3, y3)
DECLARE FUNCTION  XgrDrawCurveGrid            (grid, color, segments, x0g, y0g, x1g, y1g, x2g, y2g, x3g, y3g)
DECLARE FUNCTION  XgrDrawCurveScaled          (grid, color, segments, x0#, y0#, x1#, y1#, x2#, y2#, x3#, y3#)
DECLARE FUNCTION  XgrDrawGridBorder           (grid, border)
DECLARE FUNCTION  XgrDrawLine                 (grid, color, x1, y1, x2, y2)
DECLARE FUNCTION  XgrDrawLineGrid             (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
DECLARE FUNCTION  XgrDrawLineScaled           (grid, color, x1#, y1#, x2#, y2#)
DECLARE FUNCTION  XgrDrawLineTo               (grid, color, x, y)
DECLARE FUNCTION  XgrDrawLineToGrid           (grid, color, xGrid, yGrid)
DECLARE FUNCTION  XgrDrawLineToScaled         (grid, color, x#, y#)
DECLARE FUNCTION  XgrDrawLineToDelta          (grid, color, dx, dy)
DECLARE FUNCTION  XgrDrawLineToDeltaGrid      (grid, color, dxGrid, dyGrid)
DECLARE FUNCTION  XgrDrawLineToDeltaScaled    (grid, color, dx#, dy#)
DECLARE FUNCTION  XgrDrawLines                (grid, color, first, count, ANY line[])
DECLARE FUNCTION  XgrDrawLinesGrid            (grid, color, first, count, ANY line[])
DECLARE FUNCTION  XgrDrawLinesScaled          (grid, color, first, count, ANY line[])
DECLARE FUNCTION  XgrDrawLinesTo              (grid, color, start, count, ANY line[])
DECLARE FUNCTION  XgrDrawLinesToGrid          (grid, color, start, count, ANY line[])
DECLARE FUNCTION  XgrDrawLinesToScaled        (grid, color, start, count, ANY line[])
DECLARE FUNCTION  XgrDrawPoint                (grid, color, x, y)
DECLARE FUNCTION  XgrDrawPointGrid            (grid, color, xGrid, yGrid)
DECLARE FUNCTION  XgrDrawPointScaled          (grid, color, x#, y#)
DECLARE FUNCTION  XgrDrawPoints               (grid, color, first, count, ANY point[])
DECLARE FUNCTION  XgrDrawPointsGrid           (grid, color, first, count, ANY point[])
DECLARE FUNCTION  XgrDrawPointsScaled         (grid, color, first, count, ANY point[])
DECLARE FUNCTION  XgrDrawText                 (grid, color, text$)
DECLARE FUNCTION  XgrDrawTextGrid             (grid, color, text$)
DECLARE FUNCTION  XgrDrawTextScaled           (grid, color, text$)
DECLARE FUNCTION  XgrDrawTextFill             (grid, color, text$)
DECLARE FUNCTION  XgrDrawTextFillGrid         (grid, color, text$)
DECLARE FUNCTION  XgrDrawTextFillScaled       (grid, color, text$)
DECLARE FUNCTION  XgrFillBox                  (grid, color, x1, y1, x2, y2)
DECLARE FUNCTION  XgrFillBoxGrid              (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
DECLARE FUNCTION  XgrFillBoxScaled            (grid, color, x1#, y1#, x2#, y2#)
DECLARE FUNCTION  XgrFillCircle               (grid, color, r)
DECLARE FUNCTION  XgrFillCircleGrid           (grid, color, r)
DECLARE FUNCTION  XgrFillCircleScaled         (grid, color, r#)
DECLARE FUNCTION  XgrFillEllipse              (grid, color, rx, ry)
DECLARE FUNCTION  XgrFillEllipseGrid          (grid, color, rx, ry)
DECLARE FUNCTION  XgrFillEllipseScaled        (grid, color, rx#, ry#)
DECLARE FUNCTION  XgrFillTriangle             (grid, color, style, direction, x1, y1, x2, y2)
DECLARE FUNCTION  XgrFillTriangleGrid         (grid, color, style, direction, x1Grid, y1Grid, x2Grid, y2Grid)
DECLARE FUNCTION  XgrFillTriangleScaled       (grid, color, style, direction, x1#, y1#, x2#, y2#)
DECLARE FUNCTION  XgrGetDrawpoint             (grid, x, y)
DECLARE FUNCTION  XgrGetDrawpointGrid         (grid, xGrid, yGrid)
DECLARE FUNCTION  XgrGetDrawpointScaled       (grid, x#, y#)
DECLARE FUNCTION  XgrGrabPoint                (grid, x, y, @r, @g, @b, @color)
DECLARE FUNCTION  XgrGrabPointGrid            (grid, xGrid, yGrid, @r, @g, @b, @color)
DECLARE FUNCTION  XgrGrabPointScaled          (grid, x#, y#, @r, @g, @b, @color)
DECLARE FUNCTION  XgrMoveDelta                (grid, dx, dy)
DECLARE FUNCTION  XgrMoveDeltaGrid            (grid, dxGrid, dyGrid)
DECLARE FUNCTION  XgrMoveDeltaScaled          (grid, dx#, dy#)
DECLARE FUNCTION  XgrMoveTo                   (grid, x, y)
DECLARE FUNCTION  XgrMoveToGrid               (grid, xGrid, yGrid)
DECLARE FUNCTION  XgrMoveToScaled             (grid, x#, y#)
DECLARE FUNCTION  XgrRedrawWindow             (window, action, x, y, width, height)
DECLARE FUNCTION  XgrSetDrawpoint             (grid, x, y)
DECLARE FUNCTION  XgrSetDrawpointGrid         (grid, xGrid, yGrid)
DECLARE FUNCTION  XgrSetDrawpointScaled       (grid, x#, y#)
'
' image functions
'
DECLARE FUNCTION  XgrCopyImage                (grid, source)
DECLARE FUNCTION  XgrDrawImage                (grid, source, sx1, sy1, sx2, sy2, dx1, dy1)
DECLARE FUNCTION  XgrGetImage                 (grid, UBYTE image[])
DECLARE FUNCTION  XgrGetImage32               (grid, UBYTE image[])
DECLARE FUNCTION  XgrGetImageArrayInfo        (UBYTE image[], @depth, @width, @height)
DECLARE FUNCTION  XgrGetImageArrayInfoPNM     (UBYTE image[], @depth, @width, @height)
DECLARE FUNCTION  XgrLoadFile                 (file$, UBYTE file[])
DECLARE FUNCTION  XgrLoadImage                (file$, UBYTE image[])
DECLARE FUNCTION  XgrRefreshGrid              (grid)
DECLARE FUNCTION  XgrSaveImage                (file$, UBYTE image[])
DECLARE FUNCTION  XgrSetImage                 (grid, UBYTE image[])
DECLARE FUNCTION  XgrSetImagePNM              (grid, UBYTE image[])
'
' focus functions
'
DECLARE FUNCTION  XgrGetMouseInfo             (@window, @grid, @x, @y, @state, @time)
DECLARE FUNCTION  XgrGetSelectedWindow        (@window)
DECLARE FUNCTION  XgrGetTextSelectionGrid     (@grid)
DECLARE FUNCTION  XgrSetSelectedWindow        (window)
DECLARE FUNCTION  XgrSetTextSelectionGrid     (grid)
DECLARE FUNCTION  XgrUnsetTextSelectionGrid   (grid)
'
' message functions
'
DECLARE FUNCTION  XgrAddMessage               (wingrid, message, v0, v1, v2, v3, r0, r1)
DECLARE FUNCTION  XgrDeleteMessages           (count)
DECLARE FUNCTION  XgrGetCEO                   (func)
DECLARE FUNCTION  XgrGetMessages              (@count, MESSAGE @message[])
DECLARE FUNCTION  XgrGetMessageType           (message, @messageType)
DECLARE FUNCTION  XgrGetMonitors              (grid, MESSAGE @monitor[])
DECLARE FUNCTION  XgrJamMessage               (wingrid, message, v0, v1, v2, v3, r0, r1)
DECLARE FUNCTION  XgrMallocInfo               (arena, ordblks, smblks, hblks, hblkhd, usmblks, fsmblks, wordblks, fordblks, keepcost)
DECLARE FUNCTION  XgrMessageNameToNumber      (message$, @message)
DECLARE FUNCTION  XgrMessageNames             (@count, @message$[])
DECLARE FUNCTION  XgrMessageNumberToName      (message, @message$)
DECLARE FUNCTION  XgrMessagesPending          (count)
DECLARE FUNCTION  XgrMonitor                  (grid, message, v0, v1, v2, v3, r0, r1)
DECLARE FUNCTION  XgrPeekMessage              (wingrid, message, v0, v1, v2, v3, r0, r1)
DECLARE FUNCTION  XgrProcessMessages          (count)
DECLARE FUNCTION  XgrRegisterMessage          (message$, @message)
DECLARE FUNCTION  XgrSendMessage              (wingrid, message, v0, v1, v2, v3, r0, r1)
DECLARE FUNCTION  XgrSendStringMessage        (wingrid, message$, v0, v1, v2, v3, r0, r1)
DECLARE FUNCTION  XgrSetCEO                   (func)
'
' old names and functions - stubs to be link compatible with GuiDesigner
'
DECLARE FUNCTION  XgrGetColors                (grid, @back, @draw, @low, @high, @dull, @acc, @lowtext, @hightext)
DECLARE FUNCTION  XgrGetGridClip              (grid, @clip)
DECLARE FUNCTION  XgrRegisterIconColor        (icon$, @icon)
DECLARE FUNCTION  XgrSetColors                (grid, back, draw, low, high, dull, acc, lowtext, hightext)
DECLARE FUNCTION  XgrSetGridClip              (grid, clip)
DECLARE FUNCTION  XgrGetSystemDisplay					()
'
'END EXPORT
'
DECLARE FUNCTION  XgrChangeProperty           (wingrid, property, type, mode, @data[])
DECLARE FUNCTION  XgrGetWindowPropertyXLONG   (wingrid, property, type, items, @data[])
'END EXPORT
DECLARE FUNCTION  XxxXgrAlarmBlock            ()
DECLARE FUNCTION  XxxXgrAlarmUnblock          ()
DECLARE FUNCTION  XxxXgrAsignAtom             (atom$, @atom)
DECLARE FUNCTION  XxxXgrAtomNameToNumber      (atom$, @atom)
DECLARE FUNCTION  XxxXgrAtomNumberToName      (atom, @atom$)
DECLARE FUNCTION  XxxXgrChangeProperty        (wingrid, property, type, format, mode, UBYTE data[], elements)
DECLARE FUNCTION  XxxXgrGetWindowMapped       (window, mapped)
DECLARE FUNCTION  XxxXgrGetWindowProperty     (wingrid, prop, off, longs, type, @rType, @rFormat, @rItems, @rAfter, UBYTE data[])
DECLARE FUNCTION  XxxXgrGetWMNormalHints      (window, XSizeHints sizeHints)
DECLARE FUNCTION  XxxXgrListProperties        (wingrid, @atoms[])
DECLARE FUNCTION  XxxXgrGetTransientForHint   (wingrid, @forwindow)
DECLARE FUNCTION  XxxXgrSetTransientForHint   (wingrid, forwingrid)
DECLARE FUNCTION  XxxXgrGetAllWindows         (WINDOW @windowReturn[], DISPLAY @displayReturn[], FONT fontReturn[])
DECLARE FUNCTION  XxxXgrLowerWindow           (window)
DECLARE FUNCTION  XxxXgrRaiseWindow           (window)
DECLARE FUNCTION  XxxXgrRestackWindows        (@windows[])
DECLARE FUNCTION  XxxXgrSendEvent             (wingrid, propogate, eventMask, addrXEvent)
DECLARE FUNCTION  XxxXgrConfigureWindow       (wingrid, valueMask, XWindowChanges values)
'END EXPORT
'
' private externally visible functions
'
DECLARE FUNCTION  XxxCheckMessages            ()
DECLARE FUNCTION  XxxCheckStack               ()
DECLARE FUNCTION  XxxXgrSysMessages           ()
DECLARE FUNCTION  XxxDispatchEvents           (sync, wait)
DECLARE FUNCTION  XxxXgrBlowback              ()
DECLARE FUNCTION  XxxXgrConsoleUpdateRequest  (consolePrinting)
DECLARE FUNCTION  XxxXgrGridTimer             (tgrid, timer, count, msec, time)
DECLARE FUNCTION  XxxXgrQuit                  ()
DECLARE FUNCTION  XxxXgrResetUserMode         ()
DECLARE FUNCTION  XxxXgrSetHelpWindow         (helpWindow)
DECLARE FUNCTION  XxxXgrSetHuh                (huh)
DECLARE FUNCTION  XxxXgrSleep                 (msec)
DECLARE FUNCTION  XxxXgrWindowToSystemDisplayAndWindow (window, @sdisplay, @swindow)
'
DECLARE FUNCTION  XxxDIBToDIB24               (UBYTE simage[], UBYTE dimage[])
DECLARE FUNCTION  XxxDIBToDIB32               (UBYTE simage[], UBYTE dimage[])
END EXPORT
'
' ****************************************
' *****  internal support functions  *****
' ****************************************
'
INTERNAL FUNCTION  ConvertColorToSystemColor   (grid, color, @pixel)
INTERNAL FUNCTION  ConvertRGBToSystemColor     (grid, red, green, blue, @pixel)
INTERNAL FUNCTION  CreateQueue                 (queue)
INTERNAL FUNCTION  DestroyUserResources        ()
INTERNAL FUNCTION  Display                     (display, command, display$)
INTERNAL FUNCTION  DispatchEvents              (sync, wait)
INTERNAL FUNCTION  EmptyHoldingQueue           ()
INTERNAL FUNCTION  Font                        (@font, command, display, @sfont, @addrFont, size, bold, italic, angle, ufont$)
INTERNAL FUNCTION  GetNewWindowNumber          (@wingrid)
INTERNAL FUNCTION  GraphicsContext             (@gc, command, sdisplay, screen, swindow, sfont)
INTERNAL FUNCTION  InvalidCursor               (cursor)
INTERNAL FUNCTION  InvalidDisplay              (display)
INTERNAL FUNCTION  InvalidFont                 (font)
INTERNAL FUNCTION  InvalidGrid                 (grid)
INTERNAL FUNCTION  InvalidGridType             (gridType)
INTERNAL FUNCTION  InvalidIcon                 (icon)
INTERNAL FUNCTION  InvalidWindow               (window)
INTERNAL FUNCTION  InvalidWinGrid              (wingrid)
INTERNAL FUNCTION  KeyboardMessage             (message)
INTERNAL FUNCTION  Log                         (log$, newline)
INTERNAL FUNCTION  MouseMessage                (message)
INTERNAL FUNCTION  NormalAngle                 (angle#)
INTERNAL FUNCTION  NormalAnglePlusMinus        (angle#)
INTERNAL FUNCTION  RedrawGridAndKids           (grid, action, xWin, yWin, width, height)
INTERNAL FUNCTION  RemoveMessage               (window, message, v0,v1,v2,v3,r0,r1)
INTERNAL FUNCTION  SetBackgroundColor          (window, color)
INTERNAL FUNCTION  SetBackgroundRGB            (window, red, green, blue)
INTERNAL FUNCTION  SetDrawingColor             (window, color)
INTERNAL FUNCTION  SetDrawingRGB               (window, red, green, blue)
INTERNAL FUNCTION  SetSwindowXref              (swindow, window)
INTERNAL FUNCTION  SystemButtonStateToButtonState   (button, system, time, state)
INTERNAL FUNCTION  SystemKeyStateToKeyState         (message, keysym, system, time, state)
INTERNAL FUNCTION  UpdateMouse                 (who)
INTERNAL FUNCTION  UpdateScaledCoordinates     (grid)
INTERNAL FUNCTION  WindowEnabledVisible        (wingrid)
INTERNAL FUNCTION  WinGridDrawable             (wingrid)
INTERNAL FUNCTION  LocalToBufferCoords         (grid, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @xx1, @yy1, @xx2, @yy2)
'
' private external functions
'
EXTERNAL FUNCTION  XxxGetImplementation        (name$)
EXTERNAL FUNCTION  XxxXstLog                   (text$)
EXTERNAL FUNCTION  XxxLog                      (text$)
EXTERNAL FUNCTION  XxxLog2                     (text$, int)
EXTERNAL FUNCTION  XxxLog10                    (logMessage$, window, grid, message, v0, v1, v2, v3, r0, r1)
EXTERNAL FUNCTION  XxxGetRbpRsp                (@rbp, @rsp)
EXTERNAL FUNCTION  XxxXstTimer                 (command, tgrid, timer, count, msec, func)
EXTERNAL CFUNCTION  printf                     (addr, ...)
EXTERNAL CFUNCTION  xbc_malloc                 (bytes)
'
'
' ************************************
' *****  system event functions  *****
' ************************************
'
' each event function handles one event - the event gives the function its name.
' the following table shows what event structures are passed to each function.
'
' event               function                    xlib structure
'
' ButtonPress         EventButtonPress()          XButtonEvent
' ButtonRelease       EventButtonRelease()        XButtonEvent
' CirculateNotify     EventCirculateNotify()      XCirculateEvent
' CirculateRequest    EventCirculateRequest()     XCirculateRequestEvent
' ClientMessage       EventClientMessage()        XClientMessageEvent
' ColormapNotify      EventColormapNotify()       XColormapEvent
' ConfigureNotify     EventConfigureNotify()      XConfigureEvent
' ConfigureRequest    EventConfigureRequest()     XConfigureRequestEvent
' CreateNotify        EventCreateNotify()         XCreateWindowEvent
' DestroyNotify       EventDestroyNotify()        XDestroyWindowEvent
' EnterNotify         EventEnterNotify()          XCrossingEvent
' Error               EventError()                XErrorEvent
' Expose              EventExpose()               XExposeEvent
' FocusIn             EventFocusIn()              XFocusChangeEvent
' FocusOut            EventFocusOut()             XFocusChangeEvent
' GraphicsExpose      EventGraphicsExpose()       XGraphicsExposeEvent
' GravityNotify       EventGravityNotify()        XGravityEvent
' KeyPress            EventKeyPress()             XKeyEvent
' KeyRelease          EventKeyRelease()           XKeyEvent
' KeymapNotify        EventKeymapNotify()         XKeymapEvent
' LeaveNotify         EventLeaveNotify()          XCrossingEvent
' MapNotify           EventMapNotify()            XMapEvent
' MapRequest          EventMapRequest()           XMapRequestEvent
' MappingNotify       EventMappingNotify()        XMappingEvent
' MotionNotify        EventMotionNotify()         XMotionEvent
' NoExpose            EventNoExpose()             XNoExposeEvent
' PropertyNotify      EventPropertyNotify()       XPropertyEvent
' ReparentNotify      EventReparentNotify()       XReparentEvent
' ResizeRequest       EventResizeRequest()        XResizeRequestEvent
' SelectionClear      EventSelectionClear()       XSelectionClearEvent
' SelectionNotify     EventSelectionNotify()      XSelectionEvent
' SelectionRequest    EventSelectionRequest()     XSelectionRequestEvent
' UnmapNotify         EventUnmapNotify()          XUnmapEvent
' VisibilityNotify    EventVisibilityNotify()     XVisibilityEvent
'
'
INTERNAL FUNCTION  EventButtonPress          (ANY)
INTERNAL FUNCTION  EventButtonRelease        (ANY)
INTERNAL FUNCTION  EventCirculateNotify      (ANY)
INTERNAL FUNCTION  EventCirculateRequest     (ANY)
INTERNAL FUNCTION  EventClientMessage        (ANY)
INTERNAL FUNCTION  EventColormapNotify       (ANY)
INTERNAL FUNCTION  EventConfigureNotify      (ANY)
INTERNAL FUNCTION  EventConfigureRequest     (ANY)
INTERNAL FUNCTION  EventCreateNotify         (ANY)
INTERNAL FUNCTION  EventDestroyNotify        (ANY)
INTERNAL FUNCTION  EventEnterNotify          (ANY)
INTERNAL CFUNCTION EventError                (dpy, ANY)
INTERNAL FUNCTION  EventExpose               (ANY)
INTERNAL FUNCTION  EventFocusIn              (ANY)
INTERNAL FUNCTION  EventFocusOut             (ANY)
INTERNAL FUNCTION  EventGraphicsExpose       (ANY)
INTERNAL FUNCTION  EventGravityNotify        (ANY)
INTERNAL FUNCTION  EventKeyPress             (ANY)
INTERNAL FUNCTION  EventKeyRelease           (ANY)
INTERNAL FUNCTION  EventKeymapNotify         (ANY)
INTERNAL FUNCTION  EventLeaveNotify          (ANY)
INTERNAL FUNCTION  EventMapNotify            (ANY)
INTERNAL FUNCTION  EventMapRequest           (ANY)
INTERNAL FUNCTION  EventMappingNotify        (ANY)
INTERNAL FUNCTION  EventMotionNotify         (ANY)
INTERNAL FUNCTION  EventNoExpose             (ANY)
INTERNAL FUNCTION  EventPropertyNotify       (ANY)
INTERNAL FUNCTION  EventReparentNotify       (ANY)
INTERNAL FUNCTION  EventResizeRequest        (ANY)
INTERNAL FUNCTION  EventSelectionClear       (ANY)
INTERNAL FUNCTION  EventSelectionNotify      (ANY)
INTERNAL FUNCTION  EventSelectionRequest     (ANY)
INTERNAL FUNCTION  EventUnmapNotify          (ANY)
INTERNAL FUNCTION  EventVisibilityNotify     (ANY)
'
INTERNAL FUNCTION  PrintWindowAttributes     (XWindowAttributes)
'
INTERNAL FUNCTION  PrintButtonPress          (ANY)
INTERNAL FUNCTION  PrintButtonRelease        (ANY)
INTERNAL FUNCTION  PrintCirculateNotify      (ANY)
INTERNAL FUNCTION  PrintCirculateRequest     (ANY)
INTERNAL FUNCTION  PrintClientMessage        (ANY)
INTERNAL FUNCTION  PrintColormapNotify       (ANY)
INTERNAL FUNCTION  PrintConfigureNotify      (ANY)
INTERNAL FUNCTION  PrintConfigureRequest     (ANY)
INTERNAL FUNCTION  PrintCreateNotify         (ANY)
INTERNAL FUNCTION  PrintDestroyNotify        (ANY)
INTERNAL FUNCTION  PrintEnterNotify          (ANY)
INTERNAL FUNCTION  PrintErrorX               (ANY)
INTERNAL FUNCTION  PrintExpose               (ANY)
INTERNAL FUNCTION  PrintFocusIn              (ANY)
INTERNAL FUNCTION  PrintFocusOut             (ANY)
INTERNAL FUNCTION  PrintGraphicsExpose       (ANY)
INTERNAL FUNCTION  PrintGravityNotify        (ANY)
INTERNAL FUNCTION  PrintKeyPress             (ANY)
INTERNAL FUNCTION  PrintKeyRelease           (ANY)
INTERNAL FUNCTION  PrintKeymapNotify         (ANY)
INTERNAL FUNCTION  PrintLeaveNotify          (ANY)
INTERNAL FUNCTION  PrintMapNotify            (ANY)
INTERNAL FUNCTION  PrintMapRequest           (ANY)
INTERNAL FUNCTION  PrintMappingNotify        (ANY)
INTERNAL FUNCTION  PrintMotionNotify         (ANY)
INTERNAL FUNCTION  PrintNoExpose             (ANY)
INTERNAL FUNCTION  PrintPropertyNotify       (ANY)
INTERNAL FUNCTION  PrintReparentNotify       (ANY)
INTERNAL FUNCTION  PrintResizeRequest        (ANY)
INTERNAL FUNCTION  PrintSelectionClear       (ANY)
INTERNAL FUNCTION  PrintSelectionNotify      (ANY)
INTERNAL FUNCTION  PrintSelectionRequest     (ANY)
INTERNAL FUNCTION  PrintUnmapNotify          (ANY)
INTERNAL FUNCTION  PrintVisibilityNotify     (ANY)
'
INTERNAL FUNCTION  JunkHeap                  ()
INTERNAL FUNCTION  DefaultFontNames          (count, name$[])
'
' Unicode Functions  **********************   Testing   *****************************
'
EXPORT
'
DECLARE FUNCTION  XgrXcwCreateFontSet        (fontSet, fontSetNames$, missing$[], def$)
DECLARE FUNCTION  XgrXcwGetFontsOfFontSet    (fontSet, XFontStruct xfstructList[], list$[])
DECLARE FUNCTION  XgrXcwSetDrawingColor      (window, color)
DECLARE FUNCTION  XgrXcwUtf8ToWc             (utf8$, ULONG wchar[])
DECLARE FUNCTION  XgrXwcTextExtents          (fontSet, wchar[], XRectangle rectInk, XRectangle rectOverall)
DECLARE FUNCTION  XgrXcwInvalidGrid          (grid)
DECLARE FUNCTION  XgrXcwWinGridDrawable      (winGrid)
DECLARE FUNCTION  XgrXcwLocalToBufferCoords  (grid, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @xx1, @yy1, @xx2, @yy2)
DECLARE FUNCTION  XgrXmbTextExtents          (fontSet, mbString$, XRectangle rectInk, XRectangle rectOverall)
DECLARE FUNCTION  XgrXcwGetUfont             (font, fontName$, ufont$, FONT fontInfo)
DECLARE FUNCTION  XgrXcwGetOneFontName       (@count, @fontName$)
DECLARE FUNCTION  XgrXcwFreeFontSet          (fontSet)
DECLARE FUNCTION  XgrXcwSetLocale$           (category, locale$)
'
'
' ****************************************
' *****  GraphicsDesigner Constants  *****
' ****************************************
'
' *****  kind of entity  *****
'
	$$KindWindow          = 1    ' same as $$Window
	$$KindGrid            = 2    ' same as $$Grid
	$$KindImage           = 4    ' same as $$Image
	$$Window              = 1    ' window = top level window, including pop-up
	$$Grid                = 2    ' grid = subwindow
	$$Image               = 4    ' image = pixmap
'
' permanently defined grid types (also registered as #GridTypeXXXX)
'
	$$GridTypeCoordinate  = 0    ' coordinate grid
	$$GridTypeImage       = 1    ' memory image
	$$GridTypeBuffer      = 1    ' alias
'
' permanently defined clipboard types
'
	$$ClipboardTypeNone   = 0    ' no contents
	$$ClipboardTypeText   = 1    ' ASCII text
	$$ClipboardTypeImage  = 2    ' DIB image
'
' *****  debug type  *****
'
	$$DebugBrief          = 1
	$$DebugWordy          = 2
	$$DebugError          = 4
'
' *****  monitor type  *****
'
	$$MonitorContext      = 1
	$$MonitorHelp         = 2
	$$MonitorKeyboard     = 4
	$$MonitorMouse        = 8
'
' *****  window types  *****
'
	$$WindowTypeTopMost        = 0x80000000
	$$WindowTypeNoSelect       = 0x40000000
	$$WindowTypeNoFrame        = 0x20000000
	$$WindowTypeResizeFrame    = 0x10000000
	$$WindowTypeTitleBar       = 0x08000000
	$$WindowTypeSystemMenu     = 0x04000000
	$$WindowTypeMinimizeBox    = 0x02000000
	$$WindowTypeMinimizeButton = 0x02000000
	$$WindowTypeMaximizeBox    = 0x01000000
	$$WindowTypeMaximizeButton = 0x01000000
	$$WindowTypeModal          = 0x99000000
	$$WindowTypeNormal         = 0x17000000
	$$WindowTypeFixedSize      = 0x08000000
	$$WindowTypeNoIcon         = 0x00100000
	$$WindowTypeDefault        = 0x00000000
	$$WindowTypeCloseMinimize  = 0x00010000
	$$WindowTypeCloseHide      = 0x00020000
	$$WindowTypeCloseDestroy   = 0x00040000
	$$WindowTypeCloseTerminate = 0x00080000
'
' *****  window states  *****
'
	$$WindowHidden        = 0
	$$WindowDisplayed     = 1
	$$WindowMinimized     = 2
	$$WindowMaximized     = 3
'
' *****  window minimum size *****
'
	$$WindowMinimumHeight = 16
	$$WindowMinimumWidth  = 16
'
' *****  grid states  *****
'
	$$GridDisabled        = 0
	$$GridEnabled         = 1
'
' *****  grid border styles  *****
'
	$$BorderNone          =  0
	$$BorderFlat          =  1 : $$BorderFlat1  =  1
	$$BorderFlat2         =  2
	$$BorderFlat4         =  3
	$$BorderHiLine1       =  4 : $$BorderLine1  =  4
	$$BorderHiLine2       =  5 : $$BorderLine2  =  5
	$$BorderHiLine4       =  6 : $$BorderLine4  =  6
	$$BorderLoLine1       =  7
	$$BorderLoLine2       =  8
	$$BorderLoLine4       =  9
	$$BorderRaise1        = 10 : $$BorderRaise  = 10
	$$BorderRaise2        = 11
	$$BorderRaise4        = 12
	$$BorderLower1        = 13 : $$BorderLower  = 13
	$$BorderLower2        = 14
	$$BorderLower4        = 15
	$$BorderFrame         = 16
	$$BorderDrain         = 17
	$$BorderRidge         = 18
	$$BorderValley        = 19
	$$BorderWide          = 20  ' wide window frame border w/o resize marks
	$$BorderWideResize    = 21  ' wide window frame border with resize marks
	$$BorderWindow        = 22  ' window frame border w/o resize marks
	$$BorderWindowResize  = 23  ' window frame border with resize marks
	$$BorderRise2         = 24
	$$BorderSink2         = 25
	$$BorderUpper         = 31  ' highest valid border number
'
' *****  drawing modes  *****
'
	$$DrawCOPY            = 0    ' obsolete set
	$$DrawSET             = 0
	$$DrawXOR             = 1
	$$DrawAND             = 2
	$$DrawOR              = 3
	$$DrawMax             = 3
'
	$$DrawModeCOPY        = 0    ' new set
	$$DrawModeSET         = 0
	$$DrawModeXOR         = 1
	$$DrawModeAND         = 2
	$$DrawModeOR          = 3
	$$DrawModeMax         = 3
'
	$$LineSolid           = 0    ' obsolete set
	$$LineDash            = 1
	$$LineDot             = 2
	$$LineDashDot         = 3
	$$LineDashDotDot      = 4
	$$LineMax             = 4
'
	$$LineStyleSolid      = 0    ' new set
	$$LineStyleDash       = 1
	$$LineStyleDot        = 2
	$$LineStyleDashDot    = 3
	$$LineStyleDashDotDot = 4
	$$LineStyleMax        = 4
'
	$$LineFill            = 0x0010
	$$LineFillDash        = 0x0011
	$$LineFillDot         = 0x0012
	$$LineFillDashDot     = 0x0013
	$$LineFillDashDotDot  = 0x0014
'
	$$TriangleUp          = 0x0010
	$$TriangleRight       = 0x0014
	$$TriangleDown        = 0x0018
	$$TriangleLeft        = 0x001C
'
	$$CurrentColor        = -1
	$$DefaultColor        = -1
'
	$$ClipTypeNone        = 0    ' none = no contents
	$$ClipTypeText        = 1    ' ASCII text
	$$ClipTypeImage       = 2    ' DIB format image
'
' ****************************************************
' *****  standard colors with names  (0 to 124)  *****
' ****************************************************
'
'   0xRRGGBBCC
'     RR          = 0x00 to 0xFF (0 to 255) red intensity
'       GG        = 0x00 to 0xFF (0 to 255) green intensity
'         BB      = 0x00 to 0xFF (0 to 255) blue intensity
'           CC    = 0x00 to 0x7C (0 to 124) standard color number
'
' ColorConstant  Decimal  Hexadecimal
'
'                         color#    RRGGBBCC
	$$Black               =   0   ' 0x00000000
	$$DarkBlue            =   1   ' 0x00003F01
	$$MediumBlue          =   2   ' 0x00007F02
	$$Blue                =   2   ' 0x00007F02
	$$BrightBlue          =   3   ' 0x0000BF03
	$$LightBlue           =   4   ' 0x0000FF04
	$$DarkGreen           =   5   ' 0x003F0005
	$$MediumGreen         =  10   ' 0x007F000A
	$$Green               =  10   ' 0x007F000A
	$$BrightGreen         =  15   ' 0x00BF000F
	$$LightGreen          =  20   ' 0x00FF0014
	$$DarkCyan            =   6   ' 0x003F3F06
	$$MediumCyan          =  12   ' 0x007F7F0C
	$$Cyan                =  12   ' 0x007F7F0C
	$$BrightCyan          =  18   ' 0x00BFBF12
	$$LightCyan           =  24   ' 0x00FFFF18
	$$DarkRed             =  25   ' 0x3F000019
	$$MediumRed           =  50   ' 0x7F000032
	$$Red                 =  50   ' 0x7F000032
	$$BrightRed           =  75   ' 0xBF00004B
	$$LightRed            = 100   ' 0xFF000064
	$$DarkMagenta         =  26   ' 0x3F003F1A
	$$MediumMagenta       =  52   ' 0x7F007F34
	$$Magenta             =  52   ' 0x7F007F34
	$$BrightMagenta       =  78   ' 0xBF00BF4E
	$$LightMagenta        = 104   ' 0xFF00FF68
	$$DarkBrown           =  30   ' 0x3F3F001E
	$$MediumBrown         =  60   ' 0x7F7F003C
	$$Brown               =  60   ' 0x7F7F003C
	$$Yellow              =  90   ' 0xBFBF005A
	$$BrightYellow        = 120   ' 0xFFFF0078
	$$LightYellow         = 120   ' 0xFFFF0078
	$$DarkGrey            =  31   ' 0x3F3F3F1F
	$$MediumGrey          =  62   ' 0x7F7F7F3E
	$$Grey                =  62   ' 0x7F7F7F3E
	$$BrightGrey          =  93   ' 0xBFBFBF5D
	$$LightGrey           =  93   ' 0xBFBFBF5D
	$$DarkSteel           =  32   ' 0x3F3F7F20
	$$MediumSteel         =  63   ' 0x7F7FBF3F
	$$Steel               =  63   ' 0x7F7FBF3F
	$$BrightSteel         =  94   ' 0xBFBFFF5E
	$$MediumOrange        =  81   ' 0xBF3F3F51
	$$Orange              =  81   ' 0xBF3F3F51
	$$BrightOrange        = 112   ' 0xFF7F7F70
	$$LightOrange         = 112   ' 0xFF7F7F70
	$$MediumAqua          =  42   ' 0x3FBF7F2A
	$$Aqua                =  42   ' 0x3FBF7F2A
	$$BrightAqua          =  73   ' 0x7FFFBF49
	$$DarkViolet          =  57   ' 0x7F3F7F39
	$$MediumViolet        =  88   ' 0xBF7FBF58
	$$Violet              =  88   ' 0xBF7FBF58
	$$BrightViolet        = 119   ' 0xFFBFFF77
	$$LightViolet         = 119   ' 0xFFBFFF77
	$$White               = 124   ' 0xFFFFFF7C
'
' keyboard key and mouse button bits in mouse messages
'
	$$MouseShiftKey       = 0x00010000  ' bit 16 = ShiftKey
	$$MouseControlKey     = 0x00020000  ' bit 17 = ControlKey
	$$MouseAltKey         = 0x00040000  ' bit 18 = AltKey
	$$MouseMod1Key        = 0x00040000  ' bit 18 = Mod1Key (alias AltKey)
	$$MouseMod2Key        = 0x00080000  ' bit 19 = Mod2Key
	$$MouseMod3Key        = 0x00100000  ' bit 20 = Mod3Key
	$$MouseMod4Key        = 0x00200000  ' bit 21 = Mod4Key
	$$MouseMod5Key        = 0x00400000  ' bit 22 = Mod5Key
	$$MouseButton1        = 0x01000000  ' bit 24 = MouseButton1  left button
	$$MouseButton2        = 0x02000000  ' bit 25 = MouseButton2  middle button
	$$MouseButton3        = 0x04000000  ' bit 26 = MouseButton3  right button
	$$MouseButton4        = 0x08000000  ' bit 27 = MouseButton4  extra button
	$$MouseButton5        = 0x10000000  ' bit 28 = MouseButton5  extra button
	$$MouseButtonMask     = 0x1F000000  '
'
	$$ShiftBit            = 0x00010000  ' bit 16
	$$ControlBit          = 0x00020000  ' bit 17
	$$CtrlBit             = 0x00020000  ' bit 17  alias
	$$AltBit              = 0x00040000  ' bit 18
	$$RightAltBit         = 0x00080000  ' bit 19
	$$RightShiftBit       = 0x00400000  ' bit 22
	$$RightControlBit     = 0x00800000  ' bit 23
	$$LeftButtonBit       = 0x01000000  ' bit 24
	$$MiddleButtonBit     = 0x02000000  ' bit 25
	$$RightButtonBit      = 0x04000000  ' bit 26
	$$HelpButtonBit       = 0x04000000  ' bit 26
'
' *****  key types  *****
'
	$$KeyTypeVirtualKey   = 0
	$$KeyTypeAscii        = 1
	$$KeyTypeUnicode      = 2
'
' *****  ASCII "control" characters  *****
'
	$$AsciiAlarm          = 0x07    ' \a
	$$AsciiBell           = 0x07    ' \a
	$$AsciiBackspace      = 0x08    ' \b
	$$AsciiTab            = 0x09    ' \t
	$$AsciiLinefeed       = 0x0A    ' \n
	$$AsciiNewline        = 0x0A    ' \n
	$$AsciiVerticalTab    = 0x0B    ' \v
	$$AsciiFormFeed       = 0x0C    ' \f
	$$AsciiEnter          = 0x0D    ' \r
	$$AsciiReturn         = 0x0D    ' \r
	$$AsciiEscape         = 0x1B    ' \e
	$$AsciiDelete         = 0x7F    ' \d
'
' *****  virtual key codes  *****
'
	$$VirtualKey          = BITFIELD (8,24)
	$$KeyLeftButton       = 0x01
	$$KeyRightButton      = 0x02
	$$KeyBreak            = 0x03
	$$KeyMiddleButton     = 0x04
	$$KeyBackspace        = 0x08
	$$KeyTab              = 0x09
	$$KeyClear            = 0x0C
	$$KeyEnter            = 0x0D
	$$KeyShift            = 0x10
	$$KeyControl          = 0x11
	$$KeyAlt              = 0x12
	$$KeyPause            = 0x13
	$$KeyCapLock          = 0x14
	$$KeyEscape           = 0x1B
	$$KeyControlA         = 0x01
	$$KeyControlB         = 0x02
	$$KeyControlC         = 0x03
	$$KeyControlD         = 0x04
	$$KeyControlE         = 0x05
	$$KeyControlF         = 0x06
	$$KeyControlG         = 0x07
	$$KeyControlH         = 0x08
	$$KeyControlI         = 0x09
	$$KeyControlJ         = 0x0A
	$$KeyControlK         = 0x0B
	$$KeyControlL         = 0x0C
	$$KeyControlM         = 0x0D
	$$KeyControlN         = 0x0E
	$$KeyControlO         = 0x0F
	$$KeyControlP         = 0x10
	$$KeyControlQ         = 0x11
	$$KeyControlR         = 0x12
	$$KeyControlS         = 0x13
	$$KeyControlT         = 0x14
	$$KeyControlU         = 0x15
	$$KeyControlV         = 0x16
	$$KeyControlW         = 0x17
	$$KeyControlX         = 0x18
	$$KeyControlY         = 0x19
	$$KeyControlZ         = 0x1A
	$$KeySpace            = 0x20
	$$KeyPageUp           = 0x21
	$$KeyPageDown         = 0x22
	$$KeyEnd              = 0x23
	$$KeyHome             = 0x24
	$$KeyLeftArrow        = 0x25
	$$KeyUpArrow          = 0x26
	$$KeyRightArrow       = 0x27
	$$KeyDownArrow        = 0x28
	$$KeySelect           = 0x29
	$$KeyExecute          = 0x2B
	$$KeyPrintScreen      = 0x2C
	$$KeyInsert           = 0x2D
	$$KeyDelete           = 0x2E
	$$KeyHelp             = 0x2F
	$$Key0                = 0x30
	$$Key1                = 0x31
	$$Key2                = 0x32
	$$Key3                = 0x33
	$$Key4                = 0x34
	$$Key5                = 0x35
	$$Key6                = 0x36
	$$Key7                = 0x37
	$$Key8                = 0x38
	$$Key9                = 0x39
	$$KeyA                = 0x41
	$$KeyB                = 0x42
	$$KeyC                = 0x43
	$$KeyD                = 0x44
	$$KeyE                = 0x45
	$$KeyF                = 0x46
	$$KeyG                = 0x47
	$$KeyH                = 0x48
	$$KeyI                = 0x49
	$$KeyJ                = 0x4A
	$$KeyK                = 0x4B
	$$KeyL                = 0x4C
	$$KeyM                = 0x4D
	$$KeyN                = 0x4E
	$$KeyO                = 0x4F
	$$KeyP                = 0x50
	$$KeyQ                = 0x51
	$$KeyR                = 0x52
	$$KeyS                = 0x53
	$$KeyT                = 0x54
	$$KeyU                = 0x55
	$$KeyV                = 0x56
	$$KeyW                = 0x57
	$$KeyX                = 0x58
	$$KeyY                = 0x59
	$$KeyZ                = 0x5A
	$$KeyLeftWindow       = 0x5B
	$$KeyRightWindow      = 0x5C
	$$KeyApps             = 0x5D
	$$Keypad0             = 0x60
	$$Keypad1             = 0x61
	$$Keypad2             = 0x62
	$$Keypad3             = 0x63
	$$Keypad4             = 0x64
	$$Keypad5             = 0x65
	$$Keypad6             = 0x66
	$$Keypad7             = 0x67
	$$Keypad8             = 0x68
	$$Keypad9             = 0x69
	$$KeypadMultiply      = 0x6A
	$$KeypadAdd           = 0x6B
	$$KeypadSubtract      = 0x6D
	$$KeypadDecimalPoint  = 0x6E
	$$KeypadDivide        = 0x6F
	$$KeyF1               = 0x70
	$$KeyF2               = 0x71
	$$KeyF3               = 0x72
	$$KeyF4               = 0x73
	$$KeyF5               = 0x74
	$$KeyF6               = 0x75
	$$KeyF7               = 0x76
	$$KeyF8               = 0x77
	$$KeyF9               = 0x78
	$$KeyF10              = 0x79
	$$KeyF11              = 0x7A
	$$KeyF12              = 0x7B
	$$KeyF13              = 0x7C
	$$KeyF14              = 0x7D
	$$KeyF15              = 0x7E
	$$KeyF16              = 0x7F
	$$KeyF17              = 0x80
	$$KeyF18              = 0x81
	$$KeyF19              = 0x82
	$$KeyF20              = 0x83
	$$KeyF21              = 0x84
	$$KeyF22              = 0x85
	$$KeyF23              = 0x86
	$$KeyF24              = 0x87
	$$KeyNumLock          = 0x90
	$$KeyScroll           = 0x91
	$$KeyLeftShift        = 0xA0
	$$KeyRightShift       = 0xA1
	$$KeyLeftControl      = 0xA2
	$$KeyRightControl     = 0xA3
	$$KeyLeftAlt          = 0xA4
	$$KeyLeftMenu         = 0xA4
	$$KeyRightAlt         = 0xA5
	$$KeyRightMenu        = 0xA5

'
' XgrXcwSetLocale$() categories
'
  $$LC_CTYPE            =  0
  $$LC_NUMERIC          =  1
  $$LC_TIME             =  2
  $$LC_COLLATE          =  3
  $$LC_MONETARY         =  4
  $$LC_MESSAGES         =  5
  $$LC_ALL              =  6
  $$LC_PAPER            =  7
  $$LC_NAME             =  8
  $$LC_ADDRESS          =  9
  $$LC_TELEPHONE        = 10
  $$LC_MEASUREMENT      = 11
  $$LC_IDENTIFICATION   = 12
'
' XgrProcessMessages() values for "maxcount" number of messages to process
'
	$$ProcessOneOnly      =  1
	$$ProcessOneOrNone    =  0
	$$ProcessOneOrAll     = -1
	$$ProcessAllOrNone    = -2
'
END EXPORT
'
' *****  general  *****
'
	$$None                = 0
	$$Create              = 1
	$$Destroy             = 2
	$$DestroyAll          = 3
	$$Open                = 4
	$$Close               = 5
	$$CloseAll            = 6
	$$CloseExcess         = 7		' leave defaults and standards open
'
	$$StateContents       = BITFIELD (2, 20)		' 0,1,2 = VirtualKey, ascii, unicode
'
' overlap constants for XgrLocalToBufferCoords()
'
	$$RegionExceedsBufferLeft    = 0x00000001
	$$RegionExceedsBufferTop     = 0x00000002
	$$RegionExceedsBufferRight   = 0x00000004
	$$RegionExceedsBufferBottom  = 0x00000008
'
	$$RegionExceedsGridLeft      = 0x00000010
	$$RegionExceedsGridTop       = 0x00000020
	$$RegionExceedsGridRight     = 0x00000040
	$$RegionExceedsGridBottom    = 0x00000080
'
	$$BufferExceedsGridLeft      = 0x00000100
	$$BufferExceedsGridTop       = 0x00000200
	$$BufferExceedsGridRight     = 0x00000400
	$$BufferExceedsGridBottom    = 0x00000800
'
	$$GridExceedsBufferLeft      = 0x00001000
	$$GridExceedsBufferTop       = 0x00002000
	$$GridExceedsBufferRight     = 0x00004000
	$$GridExceedsBufferBottom    = 0x00008000
'
	$$RegionOutsideBufferLeft    = 0x00010000
	$$RegionOutsideBufferTop     = 0x00020000
	$$RegionOutsideBufferRight   = 0x00040000
	$$RegionOutsideBufferBottom  = 0x00080000
	$$RegionOutsideBufferMask    = 0x000F0000
'
	$$RegionOutsideGridLeft      = 0x00100000
	$$RegionOutsideGridTop       = 0x00200000
	$$RegionOutsideGridRight     = 0x00400000
	$$RegionOutsdieGridBottom    = 0x00800000
	$$RegionOutsdieGridMask      = 0x00F00000
'
	$$BufferOutsideGridLeft      = 0x01000000
	$$BufferOutsideGridTop       = 0x02000000
	$$BufferOutsideGridRight     = 0x04000000
	$$BufferOutsideGridBottom    = 0x08000000
'
	$$GridOutsideBufferLeft      = 0x10000000
	$$GridOutsideBufferTop       = 0x20000000
	$$GridOutsideBufferRight     = 0x40000000
	$$GridOutsideBufferBottom    = 0x80000000
'
'
' ####################
' #####  Xgr ()  #####
' ####################
'
' Xgr ()
'
' Xgr initializes the Graphics Library
'
FUNCTION  Xgr ()
	SHARED  MESSAGE  message[]
	SHARED  MESSAGE  mess[]
	SHARED  WINDOW  window[]
	SHARED  charMap[]
	SHARED	event$[]
	SHARED  FUNCADDR	event[] (ANY)
	SHARED  FUNCADDR	ehelp[] (ANY)
	SHARED  UBYTE	charsetKeystateModify[]
	SHARED  UBYTE	virtualKey00[]
	SHARED  UBYTE	virtualKeyFF[]
	SHARED  UBYTE	asciiKey00[]
	SHARED  UBYTE	asciiKeyFF[]
	SHARED	UBYTE	altChar[]
	SHARED	UBYTE	altCharFF[]
	SHARED  borderWidth[]
	SHARED  border$[]
	SHARED  connect[]
	SHARED  bitmask[]
	SHARED  color$[]
	SHARED  r[]
	SHARED  g[]
	SHARED  b[]
	SHARED  rgb[]
	STATIC	entry
'
	IF entry THEN RETURN ($$FALSE)
	entry = $$TRUE
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"Xgr()lockout", lockout) : lockout = 0
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "Linux XBasic GraphicsDesigner"
	a$ = "maxreason@maxreason.com"
	a$ = ""
'
	XxxGetImplementation (@#implementation$)
'
' force xlib functions to be linked in so user programs can call 'em
'
	a = &XGetErrorText()
	a = &XListProperties()
	a = &XSetErrorHandler()
	a = &XSetIOErrorHandler()
'
	##WHOMASK = 0
	##LOCKOUT = 100001
	XSetErrorHandler (&EventError())			' we will try to handle errors
	##LOCKOUT = lockout
'
	DIM message[1,2047]
	DIM mess[31]
	DIM r[4]
	DIM g[4]
	DIM b[4]
	DIM rgb[255]
	DIM border$[31]
	DIM borderWidth[31]
	DIM bitmask[31]
	DIM connect[63]
	DIM altChar[255]
	DIM altCharFF[255]
	DIM asciiKey00[255]
	DIM asciiKeyFF[255]
	DIM virtualKey00[255]
	DIM virtualKeyFF[255]
	DIM charsetKeystateModify[255]
	DIM event[$$LastEvent]
	DIM ehelp[$$LastEvent]
	DIM event$[$$LastEvent]
'
	bitmask [ 0] = 0x00000001
	bitmask [ 1] = 0x00000002
	bitmask [ 2] = 0x00000004
	bitmask [ 3] = 0x00000008
	bitmask [ 4] = 0x00000010
	bitmask [ 5] = 0x00000020
	bitmask [ 6] = 0x00000040
	bitmask [ 7] = 0x00000080
	bitmask [ 8] = 0x00000100
	bitmask [ 9] = 0x00000200
	bitmask [10] = 0x00000400
	bitmask [11] = 0x00000800
	bitmask [12] = 0x00001000
	bitmask [13] = 0x00002000
	bitmask [14] = 0x00004000
	bitmask [15] = 0x00008000
	bitmask [16] = 0x00010000
	bitmask [17] = 0x00020000
	bitmask [18] = 0x00040000
	bitmask [19] = 0x00080000
	bitmask [20] = 0x00100000
	bitmask [21] = 0x00200000
	bitmask [22] = 0x00400000
	bitmask [23] = 0x00800000
	bitmask [24] = 0x01000000
	bitmask [25] = 0x02000000
	bitmask [26] = 0x04000000
	bitmask [27] = 0x08000000
	bitmask [28] = 0x10000000
	bitmask [29] = 0x20000000
	bitmask [30] = 0x40000000
	bitmask [31] = 0x80000000
'
' initialize pre-defined grid types
'
	#GridTypeCoordinate = 0
	#GridTypeBuffer = 1
	#GridTypeImage = 1
'
' assign starting default colors
'
	#defaultBackground = $$LightGrey
	#defaultDrawing = $$Black
	#defaultLowlight = $$Black
	#defaultHighlight = $$White
	#defaultAccent = $$Yellow
	#defaultDull = $$Black
	#defaultLowtext = $$Black
	#defaultHightext = $$White
'
' initialize r[], g[], b[], rgb[] with standard color values
'
	r[0] = 0x0000 : g[0] = 0x0000 : b[0] = 0x0000
	r[1] = 0x7FFF : g[1] = 0x7FFF : b[1] = 0x7FFF
	r[2] = 0xAFFF : g[2] = 0xAFFF : b[2] = 0xAFFF
	r[3] = 0xCFFF : g[3] = 0xCFFF : b[3] = 0xCFFF
	r[4] = 0xFFFF : g[4] = 0xFFFF : b[4] = 0xFFFF
'
	color = 0
	FOR r = 0 TO 4
		FOR g = 0 TO 4
			FOR b = 0 TO 4
				rr = (r[r] AND 0xFF00) << 16
				gg = (g[g] AND 0xFF00) << 8
				bb = (b[b] AND 0xFF00)
				rgb[color] = rr + gg + bb + color
				INC color
			NEXT b
		NEXT g
	NEXT r
'
' define border names and widths
'
	border$[$$BorderNone]					= "$$BorderNone"
	border$[$$BorderFlat1]				= "$$BorderFlat1"
	border$[$$BorderFlat2]				= "$$BorderFlat2"
	border$[$$BorderFlat4]				= "$$BorderFlat4"
	border$[$$BorderHiLine1]			= "$$BorderHiLine1"
	border$[$$BorderHiLine2]			= "$$BorderHiLine2"
	border$[$$BorderHiLine4]			= "$$BorderHiLine4"
	border$[$$BorderLoLine1]			= "$$BorderLoLine1"
	border$[$$BorderLoLine2]			= "$$BorderLoLine2"
	border$[$$BorderLoLine4]			= "$$BorderLoLine4"
	border$[$$BorderRaise1]				= "$$BorderRaise1"
	border$[$$BorderLower1]				= "$$BorderLower1"
	border$[$$BorderRaise2]				= "$$BorderRaise2"
	border$[$$BorderLower2]				= "$$BorderLower2"
	border$[$$BorderRaise4]				= "$$BorderRaise4"
	border$[$$BorderLower4]				= "$$BorderLower4"
	border$[$$BorderFrame]				= "$$BorderFrame"
	border$[$$BorderDrain]				= "$$BorderDrain"
	border$[$$BorderRidge]				= "$$BorderRidge"
	border$[$$BorderValley]				= "$$BorderValley"
	border$[$$BorderWide]   			= "$$BorderWide"
	border$[$$BorderWideResize]		= "$$BorderWideResize"
	border$[$$BorderWindow]				= "$$BorderWindow"
	border$[$$BorderWindowResize]	= "$$BorderWindowResize"
	border$[$$BorderRise2]   			= "$$BorderRise2"
	border$[$$BorderSink2]   			= "$$BorderSink2"
'
	borderWidth[$$BorderNone]						= 0
	borderWidth[$$BorderFlat1]					= 1
	borderWidth[$$BorderFlat2]					= 2
	borderWidth[$$BorderFlat4]					= 4
	borderWidth[$$BorderHiLine1]				= 1
	borderWidth[$$BorderHiLine2]				= 2
	borderWidth[$$BorderHiLine4]				= 4
	borderWidth[$$BorderLoLine1]				= 1
	borderWidth[$$BorderLoLine2]				= 2
	borderWidth[$$BorderLoLine4]				= 4
	borderWidth[$$BorderRaise1]					= 1
	borderWidth[$$BorderLower1]					= 1
	borderWidth[$$BorderRaise2]					= 2
	borderWidth[$$BorderLower2]					= 2
	borderWidth[$$BorderRaise4]					= 4
	borderWidth[$$BorderLower4]					= 4
	borderWidth[$$BorderFrame]					= 4
	borderWidth[$$BorderDrain]					= 4
	borderWidth[$$BorderRidge]					= 2
	borderWidth[$$BorderValley]					= 2
	borderWidth[$$BorderWide]						= 6
	borderWidth[$$BorderWideResize]			= 6
	borderWidth[$$BorderWindow]					= 8
	borderWidth[$$BorderWindowResize]		= 8
	borderWidth[$$BorderRise2]					= 2
	borderWidth[$$BorderSink2]					= 2
'
'
' ***********************************************
' *****  Initialize Color Constant Strings  *****
' ***********************************************
'
	DIM color$[255]
	color$[$$Black]							= "$$Black"						'   0
	color$[$$DarkBlue]					= "$$DarkBlue"				'   1
	color$[$$Blue]							= "$$Blue"						'   2
	color$[$$BrightBlue]				= "$$BrightBlue"			'   3
	color$[$$LightBlue]					= "$$LightBlue"				'   4
	color$[$$DarkGreen]					= "$$DarkGreen"				'   5
	color$[$$DarkCyan]					= "$$DarkCyan"				'   6
	color$[$$Green]							= "$$Green"						'  10
	color$[$$Cyan]							= "$$Cyan"						'  12
	color$[$$BrightGreen]				= "$$BrightGreen"			'  15
	color$[$$BrightCyan]				= "$$BrightCyan"			'  18
	color$[$$LightGreen]				= "$$LightGreen"			'  20
	color$[$$LightCyan]					= "$$LightCyan"				'  24
	color$[$$DarkRed]						= "$$DarkRed"					'  25
	color$[$$DarkMagenta]				= "$$DarkMagenta"			'  26
	color$[$$DarkBrown]					= "$$DarkBrown"				'  30
	color$[$$DarkGrey]					= "$$DarkGrey"				'  31
	color$[$$DarkSteel]					= "$$DarkSteel"				'  32
	color$[$$Aqua]							= "$$Aqua"						'  42
	color$[$$Red]								= "$$Red"							'  50
	color$[$$Magenta]						= "$$Magenta"					'  52
	color$[$$DarkViolet]				= "$$DarkViolet"			'  57
	color$[$$Brown]							= "$$Brown"						'  60
	color$[$$Grey]							= "$$Grey"						'  62
	color$[$$Steel]							= "$$Steel"						'  63
	color$[$$BrightAqua]				= "$$BrightAqua"			'  73
	color$[$$BrightRed]					= "$$BrightRed"				'  75
	color$[$$BrightMagenta]			= "$$BrightMagenta"		'  78
	color$[$$Orange]						= "$$Orange"					'  81
	color$[$$Violet]						= "$$Violet"					'  88
	color$[$$Yellow]						= "$$Yellow"					'  90
	color$[$$BrightGrey]				= "$$BrightGrey"			'  93
	color$[$$BrightSteel]				= "$$BrightSteel"			'  94
	color$[$$LightRed]					= "$$LightRed"				' 100
	color$[$$LightMagenta]			= "$$LightMagenta"		' 104
	color$[$$BrightOrange]			= "$$BrightOrange"		' 112
	color$[$$BrightViolet]			= "$$BrightViolet"		' 119
	color$[$$LightYellow]				= "$$LightYellow"			' 120
	color$[$$White]							= "$$White"						' 124
'
' initialize event strings
'
	event$ [ $$KeyPress          ]  = "$$KeyPress"
	event$ [ $$KeyRelease        ]  = "$$KeyRelease"
	event$ [ $$ButtonPress       ]  = "$$ButtonPress"
	event$ [ $$ButtonRelease     ]  = "$$ButtonRelease"
	event$ [ $$MotionNotify      ]  = "$$MotionNotify"
	event$ [ $$EnterNotify       ]  = "$$EnterNotify"
	event$ [ $$LeaveNotify       ]  = "$$LeaveNotify"
	event$ [ $$FocusIn           ]  = "$$FocusIn"
	event$ [ $$FocusOut          ]  = "$$FocusOut"
	event$ [ $$KeymapNotify      ]  = "$$KeymapNotify"
	event$ [ $$Expose            ]  = "$$Expose"
	event$ [ $$GrapicsExpose     ]  = "$$GrapicsExpose"
	event$ [ $$NoExpose          ]  = "$$NoExpose"
	event$ [ $$VisibilityNotify  ]  = "$$VisibilityNotify"
	event$ [ $$CreateNotify      ]  = "$$CreateNotify"
	event$ [ $$DestroyNotify     ]  = "$$DestroyNotify"
	event$ [ $$UnmapNotify       ]  = "$$UnmapNotify"
	event$ [ $$MapNotify         ]  = "$$MapNotify"
	event$ [ $$MapRequest        ]  = "$$MapRequest"
	event$ [ $$ReparentNotify    ]  = "$$ReparentNotify"
	event$ [ $$ConfigureNotify   ]  = "$$ConfigureNotify"
	event$ [ $$ConfigureRequest  ]  = "$$ConfigureRequest"
	event$ [ $$GravityNotify     ]  = "$$GravityNotify"
	event$ [ $$ResizeRequest     ]  = "$$ResizeRequest"
	event$ [ $$CirculateNotify   ]  = "$$CirculateNotify"
	event$ [ $$CirculateRequest  ]  = "$$CirculateRequest"
	event$ [ $$PropertyNotify    ]  = "$$PropertyNotify"
	event$ [ $$SelectionClear    ]  = "$$SelectionClear"
	event$ [ $$SelectionRequest  ]  = "$$SelectionRequest"
	event$ [ $$SelectionNotify   ]  = "$$SelectionNotify"
	event$ [ $$ColormapNotify    ]  = "$$ColormapNotify"
	event$ [ $$ClientMessage     ]  = "$$ClientMessage "
	event$ [ $$MappingNotify     ]  = "$$MappingNotify"
	event$ [ $$LastEvent         ]  = "$$LastEvent"
'
	event [ $$KeyPress          ] = &EventKeyPress()
	event [ $$KeyRelease        ] = &EventKeyRelease()
	event [ $$ButtonPress       ] = &EventButtonPress()
	event [ $$ButtonRelease     ] = &EventButtonRelease()
	event [ $$MotionNotify      ] = &EventMotionNotify()
	event [ $$EnterNotify       ] = &EventEnterNotify()
	event [ $$LeaveNotify       ] = &EventLeaveNotify()
	event [ $$FocusIn           ] = &EventFocusIn()
	event [ $$FocusOut          ] = &EventFocusOut()
	event [ $$KeymapNotify      ] = &EventKeymapNotify()
	event [ $$Expose            ] = &EventExpose()
	event [ $$GrapicsExpose     ] = &EventGraphicsExpose()
	event [ $$NoExpose          ] = &EventNoExpose()
	event [ $$VisibilityNotify  ] = &EventVisibilityNotify()
	event [ $$CreateNotify      ] = &EventCreateNotify()
	event [ $$DestroyNotify     ] = &EventDestroyNotify()
	event [ $$UnmapNotify       ] = &EventUnmapNotify()
	event [ $$MapNotify         ] = &EventMapNotify()
	event [ $$MapRequest        ] = &EventMapRequest()
	event [ $$ReparentNotify    ] = &EventReparentNotify()
	event [ $$ConfigureNotify   ] = &EventConfigureNotify()
	event [ $$ConfigureRequest  ] = &EventConfigureRequest()
	event [ $$GravityNotify     ] = &EventGravityNotify()
	event [ $$ResizeRequest     ] = &EventResizeRequest()
	event [ $$CirculateNotify   ] = &EventCirculateNotify()
	event [ $$CirculateRequest  ] = &EventCirculateRequest()
	event [ $$PropertyNotify    ] = &EventPropertyNotify()
	event [ $$SelectionClear    ] = &EventSelectionClear()
	event [ $$SelectionRequest  ] = &EventSelectionRequest()
	event [ $$SelectionNotify   ] = &EventSelectionNotify()
	event [ $$ColormapNotify    ] = &EventColormapNotify()
	event [ $$ClientMessage     ] = &EventClientMessage()
	event [ $$MappingNotify     ] = &EventMappingNotify()
	event [ $$LastEvent         ] = 0
'
	ehelp [ $$KeyPress          ] = &PrintKeyPress()
	ehelp [ $$KeyRelease        ] = &PrintKeyRelease()
	ehelp [ $$ButtonPress       ] = &PrintButtonPress()
	ehelp [ $$ButtonRelease     ] = &PrintButtonRelease()
	ehelp [ $$MotionNotify      ] = &PrintMotionNotify()
	ehelp [ $$EnterNotify       ] = &PrintEnterNotify()
	ehelp [ $$LeaveNotify       ] = &PrintLeaveNotify()
	ehelp [ $$FocusIn           ] = &PrintFocusIn()
	ehelp [ $$FocusOut          ] = &PrintFocusOut()
	ehelp [ $$KeymapNotify      ] = &PrintKeymapNotify()
	ehelp [ $$Expose            ] = &PrintExpose()
	ehelp [ $$GrapicsExpose     ] = &PrintGraphicsExpose()
	ehelp [ $$NoExpose          ] = &PrintNoExpose()
	ehelp [ $$VisibilityNotify  ] = &PrintVisibilityNotify()
	ehelp [ $$CreateNotify      ] = &PrintCreateNotify()
	ehelp [ $$DestroyNotify     ] = &PrintDestroyNotify()
	ehelp [ $$UnmapNotify       ] = &PrintUnmapNotify()
	ehelp [ $$MapNotify         ] = &PrintMapNotify()
	ehelp [ $$MapRequest        ] = &PrintMapRequest()
	ehelp [ $$ReparentNotify    ] = &PrintReparentNotify()
	ehelp [ $$ConfigureNotify   ] = &PrintConfigureNotify()
	ehelp [ $$ConfigureRequest  ] = &PrintConfigureRequest()
	ehelp [ $$GravityNotify     ] = &PrintGravityNotify()
	ehelp [ $$ResizeRequest     ] = &PrintResizeRequest()
	ehelp [ $$CirculateNotify   ] = &PrintCirculateNotify()
	ehelp [ $$CirculateRequest  ] = &PrintCirculateRequest()
	ehelp [ $$PropertyNotify    ] = &PrintPropertyNotify()
	ehelp [ $$SelectionClear    ] = &PrintSelectionClear()
	ehelp [ $$SelectionRequest  ] = &PrintSelectionRequest()
	ehelp [ $$SelectionNotify   ] = &PrintSelectionNotify()
	ehelp [ $$ColormapNotify    ] = &PrintColormapNotify()
	ehelp [ $$ClientMessage     ] = &PrintClientMessage()
	ehelp [ $$MappingNotify     ] = &PrintMappingNotify()
	ehelp [ $$LastEvent         ] = 0
'
'
' *****  translate keysym to ascii character  *****
'
' When the AltKey is down, the char is always the basic char
'   for keys 'a'...'z' and '0'...'9'.
' for example, the char for Alt+Shift+3 = '3', not '#'
' for example, the char for Alt+A = 'A', not 'a'
'
	FOR i = 0x00 TO 0xFF
		altChar[i] = i
	NEXT i
'
	FOR i = 'a' TO 'z'
		altChar[i] = i - 0x20				' lower case to upper case
	NEXT i
'
	altChar [ ')' ] = '0'
	altChar [ '!' ] = '1'
	altChar [ '@' ] = '2'
	altChar [ '#' ] = '3'
	altChar [ '$' ] = '4'
	altChar [ '%' ] = '5'
	altChar [ '^' ] = '6'
	altChar [ '&' ] = '7'
	altChar [ '*' ] = '8'
	altChar [ '(' ] = '9'
'
'
' group 00 : keysym = 0x00kk where kk = entry in following array
'
	FOR i = 0x20 TO 0xFF
		asciiKey00 [ i ] = i
	NEXT i
'
' group FF : keysym = 0xFFkk where kk = entry in following array
'
' $$KeyDelete is not included here because it does not enter
' a character or delete an existing character.  (escape doesn't either)
'
	asciiKeyFF [ $$XK_Backspace				AND 0x00FF ] = $$AsciiBackspace
	asciiKeyFF [ $$XK_Tab							AND 0x00FF ] = $$AsciiTab
	asciiKeyFF [ $$XK_Return					AND 0x00FF ] = $$AsciiEnter
	asciiKeyFF [ $$XK_Escape					AND 0x00FF ] = $$AsciiEscape
' added 010109 SVG, improved keypad support
	asciiKeyFF [ $$XK_KeypadSpace			AND 0x00FF ] = $$KeySpace
	asciiKeyFF [ $$XK_KeypadTab				AND 0x00FF ] = $$AsciiTab
	asciiKeyFF [ $$XK_KeypadEnter			AND 0x00FF ] = $$AsciiEnter
	asciiKeyFF [ $$XK_KeypadEqual			AND 0x00FF ] = '='
	asciiKeyFF [ $$XK_KeypadMultiply  AND 0x00FF ] = '*'
	asciiKeyFF [ $$XK_KeypadAdd				AND 0x00FF ] = '+'
	asciiKeyFF [ $$XK_KeypadSeparator	AND 0x00FF ] = ','
	asciiKeyFF [ $$XK_KeypadSubtract	AND 0x00FF ] = '-'
	asciiKeyFF [ $$XK_KeypadDecimal		AND 0x00FF ] = '.'
	asciiKeyFF [ $$XK_KeypadDivide		AND 0x00FF ] = '/'
	asciiKeyFF [ $$XK_Keypad_0					AND 0x00FF ] = '0'
	asciiKeyFF [ $$XK_Keypad_1					AND 0x00FF ] = '1'
	asciiKeyFF [ $$XK_Keypad_2					AND 0x00FF ] = '2'
	asciiKeyFF [ $$XK_Keypad_3					AND 0x00FF ] = '3'
	asciiKeyFF [ $$XK_Keypad_4					AND 0x00FF ] = '4'
	asciiKeyFF [ $$XK_Keypad_5					AND 0x00FF ] = '5'
	asciiKeyFF [ $$XK_Keypad_6					AND 0x00FF ] = '6'
	asciiKeyFF [ $$XK_Keypad_7					AND 0x00FF ] = '7'
	asciiKeyFF [ $$XK_Keypad_8					AND 0x00FF ] = '8'
	asciiKeyFF [ $$XK_Keypad_9					AND 0x00FF ] = '9'
'
' *****  translate keysym to virtual key  *****
'
' group 00 : keysym = 0x00kk where kk = entry in following array
'
	virtualKey00 [ $$XK_space		] = $$KeySpace	' space character
	virtualKey00 [ $$XK_0				] = $$Key0
	virtualKey00 [ $$XK_1				] = $$Key1
	virtualKey00 [ $$XK_2				] = $$Key2
	virtualKey00 [ $$XK_3				] = $$Key3
	virtualKey00 [ $$XK_4				] = $$Key4
	virtualKey00 [ $$XK_5				] = $$Key5
	virtualKey00 [ $$XK_6				] = $$Key6
	virtualKey00 [ $$XK_7				] = $$Key7
	virtualKey00 [ $$XK_8				] = $$Key8
	virtualKey00 [ $$XK_9				] = $$Key9
'
	virtualKey00 [ $$XK_A				] = $$KeyA
	virtualKey00 [ $$XK_B				] = $$KeyB
	virtualKey00 [ $$XK_C				] = $$KeyC
	virtualKey00 [ $$XK_D				] = $$KeyD
	virtualKey00 [ $$XK_E				] = $$KeyE
	virtualKey00 [ $$XK_F				] = $$KeyF
	virtualKey00 [ $$XK_G				] = $$KeyG
	virtualKey00 [ $$XK_H				] = $$KeyH
	virtualKey00 [ $$XK_I				] = $$KeyI
	virtualKey00 [ $$XK_J				] = $$KeyJ
	virtualKey00 [ $$XK_K				] = $$KeyK
	virtualKey00 [ $$XK_L				] = $$KeyL
	virtualKey00 [ $$XK_M				] = $$KeyM
	virtualKey00 [ $$XK_N				] = $$KeyN
	virtualKey00 [ $$XK_O				] = $$KeyO
	virtualKey00 [ $$XK_P				] = $$KeyP
	virtualKey00 [ $$XK_Q				] = $$KeyQ
	virtualKey00 [ $$XK_R				] = $$KeyR
	virtualKey00 [ $$XK_S				] = $$KeyS
	virtualKey00 [ $$XK_T				] = $$KeyT
	virtualKey00 [ $$XK_U				] = $$KeyU
	virtualKey00 [ $$XK_V				] = $$KeyV
	virtualKey00 [ $$XK_W				] = $$KeyW
	virtualKey00 [ $$XK_X				] = $$KeyX
	virtualKey00 [ $$XK_Y				] = $$KeyY
	virtualKey00 [ $$XK_Z				] = $$KeyZ
'
	virtualKey00 [ $$XK_a				] = $$KeyA
	virtualKey00 [ $$XK_b				] = $$KeyB
	virtualKey00 [ $$XK_c				] = $$KeyC
	virtualKey00 [ $$XK_d				] = $$KeyD
	virtualKey00 [ $$XK_e				] = $$KeyE
	virtualKey00 [ $$XK_f				] = $$KeyF
	virtualKey00 [ $$XK_g				] = $$KeyG
	virtualKey00 [ $$XK_h				] = $$KeyH
	virtualKey00 [ $$XK_i				] = $$KeyI
	virtualKey00 [ $$XK_j				] = $$KeyJ
	virtualKey00 [ $$XK_k				] = $$KeyK
	virtualKey00 [ $$XK_l				] = $$KeyL
	virtualKey00 [ $$XK_m				] = $$KeyM
	virtualKey00 [ $$XK_n				] = $$KeyN
	virtualKey00 [ $$XK_o				] = $$KeyO
	virtualKey00 [ $$XK_p				] = $$KeyP
	virtualKey00 [ $$XK_q				] = $$KeyQ
	virtualKey00 [ $$XK_r				] = $$KeyR
	virtualKey00 [ $$XK_s				] = $$KeyS
	virtualKey00 [ $$XK_t				] = $$KeyT
	virtualKey00 [ $$XK_u				] = $$KeyU
	virtualKey00 [ $$XK_v				] = $$KeyV
	virtualKey00 [ $$XK_w				] = $$KeyW
	virtualKey00 [ $$XK_x				] = $$KeyX
	virtualKey00 [ $$XK_y				] = $$KeyY
	virtualKey00 [ $$XK_z				] = $$KeyZ
'
' group FF : keysym = 0xFFkk where kk = entry in following array
'
	virtualKeyFF [ $$XK_Backspace				AND 0x00FF ] = $$KeyBackspace
	virtualKeyFF [ $$XK_Tab							AND 0x00FF ] = $$KeyTab
	virtualKeyFF [ $$XK_Clear						AND 0x00FF ] = $$KeyClear
	virtualKeyFF [ $$XK_Return					AND 0x00FF ] = $$KeyEnter
	virtualKeyFF [ $$XK_Escape					AND 0x00FF ] = $$KeyEscape
	virtualKeyFF [ $$XK_PageUp					AND 0x00FF ] = $$KeyPageUp
	virtualKeyFF [ $$XK_PageDown				AND 0x00FF ] = $$KeyPageDown
	virtualKeyFF [ $$XK_End							AND 0x00FF ] = $$KeyEnd
	virtualKeyFF [ $$XK_Home						AND 0x00FF ] = $$KeyHome
	virtualKeyFF [ $$XK_Left						AND 0x00FF ] = $$KeyLeftArrow
	virtualKeyFF [ $$XK_Up							AND 0x00FF ] = $$KeyUpArrow
	virtualKeyFF [ $$XK_Right						AND 0x00FF ] = $$KeyRightArrow
	virtualKeyFF [ $$XK_Down						AND 0x00FF ] = $$KeyDownArrow
	virtualKeyFF [ $$XK_Select					AND 0x00FF ] = $$KeySelect
	virtualKeyFF [ $$XK_Execute					AND 0x00FF ] = $$KeyExecute
	virtualKeyFF [ $$XK_Print						AND 0x00FF ] = $$KeyPrintScreen
	virtualKeyFF [ $$XK_Insert					AND 0x00FF ] = $$KeyInsert
	virtualKeyFF [ $$XK_Delete					AND 0x00FF ] = $$KeyDelete
	virtualKeyFF [ $$XK_Help						AND 0x00FF ] = $$KeyHelp
'
	virtualKeyFF [ $$XK_KeypadHome			AND 0x00FF ] = $$KeyHome
	virtualKeyFF [ $$XK_KeypadLeft			AND 0x00FF ] = $$KeyLeftArrow
	virtualKeyFF [ $$XK_KeypadUp				AND 0x00FF ] = $$KeyUpArrow
	virtualKeyFF [ $$XK_KeypadRight			AND 0x00FF ] = $$KeyRightArrow
	virtualKeyFF [ $$XK_KeypadDown			AND 0x00FF ] = $$KeyDownArrow
	virtualKeyFF [ $$XK_KeypadPageUp		AND 0x00FF ] = $$KeyPageUp
	virtualKeyFF [ $$XK_KeypadPageDown	AND 0x00FF ] = $$KeyPageDown
	virtualKeyFF [ $$XK_KeypadEnd				AND 0x00FF ] = $$KeyEnd
	virtualKeyFF [ $$XK_KeypadBegin			AND 0x00FF ] = $$Keypad5
	virtualKeyFF [ $$XK_KeypadInsert		AND 0x00FF ] = $$KeyInsert
	virtualKeyFF [ $$XK_KeypadDelete		AND 0x00FF ] = $$KeyDelete
'
	virtualKeyFF [ $$XK_Keypad_0				AND 0x00FF ] = $$Keypad0
	virtualKeyFF [ $$XK_Keypad_1				AND 0x00FF ] = $$Keypad1
	virtualKeyFF [ $$XK_Keypad_2				AND 0x00FF ] = $$Keypad2
	virtualKeyFF [ $$XK_Keypad_3				AND 0x00FF ] = $$Keypad3
	virtualKeyFF [ $$XK_Keypad_4				AND 0x00FF ] = $$Keypad4
	virtualKeyFF [ $$XK_Keypad_5				AND 0x00FF ] = $$Keypad5
	virtualKeyFF [ $$XK_Keypad_6				AND 0x00FF ] = $$Keypad6
	virtualKeyFF [ $$XK_Keypad_7				AND 0x00FF ] = $$Keypad7
	virtualKeyFF [ $$XK_Keypad_8				AND 0x00FF ] = $$Keypad8
	virtualKeyFF [ $$XK_Keypad_9				AND 0x00FF ] = $$Keypad9
'
	virtualKeyFF [ $$XK_KeypadMultiply	AND 0x00FF ] = $$KeypadMultiply
	virtualKeyFF [ $$XK_KeypadAdd				AND 0x00FF ] = $$KeypadAdd
	virtualKeyFF [ $$XK_KeypadSubtract	AND 0x00FF ] = $$KeypadSubtract
	virtualKeyFF [ $$XK_KeypadDecimal		AND 0x00FF ] = $$KeypadDecimalPoint
	virtualKeyFF [ $$XK_KeypadDivide		AND 0x00FF ] = $$KeypadDivide
'
	virtualKeyFF [ $$XK_F1							AND 0x00FF ] = $$KeyF1
	virtualKeyFF [ $$XK_F2							AND 0x00FF ] = $$KeyF2
	virtualKeyFF [ $$XK_F3							AND 0x00FF ] = $$KeyF3
	virtualKeyFF [ $$XK_F4							AND 0x00FF ] = $$KeyF4
	virtualKeyFF [ $$XK_F5							AND 0x00FF ] = $$KeyF5
	virtualKeyFF [ $$XK_F6							AND 0x00FF ] = $$KeyF6
	virtualKeyFF [ $$XK_F7							AND 0x00FF ] = $$KeyF7
	virtualKeyFF [ $$XK_F8							AND 0x00FF ] = $$KeyF8
	virtualKeyFF [ $$XK_F9							AND 0x00FF ] = $$KeyF9
	virtualKeyFF [ $$XK_F10							AND 0x00FF ] = $$KeyF10
	virtualKeyFF [ $$XK_F11							AND 0x00FF ] = $$KeyF11
	virtualKeyFF [ $$XK_F12							AND 0x00FF ] = $$KeyF12
	virtualKeyFF [ $$XK_F13							AND 0x00FF ] = $$KeyF13
	virtualKeyFF [ $$XK_F14							AND 0x00FF ] = $$KeyF14
	virtualKeyFF [ $$XK_F15							AND 0x00FF ] = $$KeyF15
	virtualKeyFF [ $$XK_F16							AND 0x00FF ] = $$KeyF16
	virtualKeyFF [ $$XK_F17							AND 0x00FF ] = $$KeyF17
	virtualKeyFF [ $$XK_F18							AND 0x00FF ] = $$KeyF18
	virtualKeyFF [ $$XK_F19							AND 0x00FF ] = $$KeyF19
	virtualKeyFF [ $$XK_F20							AND 0x00FF ] = $$KeyF20
	virtualKeyFF [ $$XK_F21							AND 0x00FF ] = $$KeyF21
	virtualKeyFF [ $$XK_F22							AND 0x00FF ] = $$KeyF22
	virtualKeyFF [ $$XK_F23							AND 0x00FF ] = $$KeyF23
	virtualKeyFF [ $$XK_F24							AND 0x00FF ] = $$KeyF24
'	virtualKeyFF [ $$XK_F25							AND 0x00FF ] = $$KeyF25
'	virtualKeyFF [ $$XK_F26							AND 0x00FF ] = $$KeyF26
'	virtualKeyFF [ $$XK_F27							AND 0x00FF ] = $$KeyF27
'	virtualKeyFF [ $$XK_F28							AND 0x00FF ] = $$KeyF28
'	virtualKeyFF [ $$XK_F29							AND 0x00FF ] = $$KeyF29
'	virtualKeyFF [ $$XK_F30							AND 0x00FF ] = $$KeyF30
'	virtualKeyFF [ $$XK_F31							AND 0x00FF ] = $$KeyF31
'	virtualKeyFF [ $$XK_F32							AND 0x00FF ] = $$KeyF32
'	virtualKeyFF [ $$XK_F33							AND 0x00FF ] = $$KeyF33
'	virtualKeyFF [ $$XK_F34							AND 0x00FF ] = $$KeyF34
'	virtualKeyFF [ $$XK_F35							AND 0x00FF ] = $$KeyF35
	virtualKeyFF [ $$XK_Shift_Left			AND 0x00FF ] = $$KeyLeftShift
	virtualKeyFF [ $$XK_Shift_Right			AND 0x00FF ] = $$KeyRightShift
	virtualKeyFF [ $$XK_Control_Left		AND 0x00FF ] = $$KeyLeftControl
	virtualKeyFF [ $$XK_Control_Right		AND 0x00FF ] = $$KeyRightControl
	virtualKeyFF [ $$XK_Caps_Lock				AND 0x00FF ] = $$KeyCapLock
	virtualKeyFF [ $$XK_Shift_Lock			AND 0x00FF ] = $$KeyCapLock
	virtualKeyFF [ $$XK_Meta_Left				AND 0x00FF ] = $$KeyLeftAlt
	virtualKeyFF [ $$XK_Meta_Right			AND 0x00FF ] = $$KeyRightAlt
	virtualKeyFF [ $$XK_Alt_Left				AND 0x00FF ] = $$KeyLeftAlt
	virtualKeyFF [ $$XK_Alt_Right				AND 0x00FF ] = $$KeyRightAlt
	virtualKeyFF [ $$XK_Super_Left			AND 0x00FF ] = $$KeyLeftAlt
	virtualKeyFF [ $$XK_Super_Right			AND 0x00FF ] = $$KeyRightAlt
	virtualKeyFF [ $$XK_Hyper_Left			AND 0x00FF ] = $$KeyLeftAlt
	virtualKeyFF [ $$XK_Hyper_Right			AND 0x00FF ] = $$KeyRightAlt
'
' added altCharFF 010109 SVG, improved keypad support
'
	altCharFF [ $$XK_Backspace			AND 0x00FF ] = $$KeyBackspace
	altCharFF [ $$XK_Tab						AND 0x00FF ] = $$KeyTab
	altCharFF [ $$XK_Clear					AND 0x00FF ] = $$KeyClear
	altCharFF [ $$XK_Return					AND 0x00FF ] = $$KeyEnter
	altCharFF [ $$XK_Pause					AND 0x00FF ] = $$KeyPause
	altCharFF [ $$XK_Scroll_Lock		AND 0x00FF ] = $$KeyScroll
	altCharFF [ $$XK_Escape					AND 0x00FF ] = $$KeyEscape
	altCharFF [ $$XK_Multi_Key			AND 0x00FF ] = $$KeyRightAlt
	altCharFF [ $$XK_Home						AND 0x00FF ] = $$KeyHome
	altCharFF [ $$XK_Left						AND 0x00FF ] = $$KeyLeftArrow
	altCharFF [ $$XK_Right					AND 0x00FF ] = $$KeyRightArrow
	altCharFF [ $$XK_Up							AND 0x00FF ] = $$KeyUpArrow
	altCharFF [ $$XK_Down						AND 0x00FF ] = $$KeyDownArrow
	altCharFF [ $$XK_PageUp					AND 0x00FF ] = $$KeyPageUp
	altCharFF [ $$XK_PageDown				AND 0x00FF ] = $$KeyPageDown
	altCharFF [ $$XK_End						AND 0x00FF ] = $$KeyEnd
	altCharFF [ $$XK_Select					AND 0x00FF ] = $$KeySelect
	altCharFF [ $$XK_Print					AND 0x00FF ] = $$KeyPrintScreen
	altCharFF [ $$XK_Execute				AND 0x00FF ] = $$KeyExecute
	altCharFF [ $$XK_Insert					AND 0x00FF ] = $$KeyInsert
	altCharFF [ $$XK_Delete					AND 0x00FF ] = $$KeyDelete
	altCharFF [ $$XK_Help						AND 0x00FF ] = $$KeyHelp
	altCharFF [ $$XK_Menu						AND 0x00FF ] = $$KeyApps
	altCharFF [ $$XK_KeypadSpace		AND 0x00FF ] = $$KeySpace
	altCharFF [ $$XK_KeypadTab			AND 0x00FF ] = $$KeyTab
	altCharFF [ $$XK_KeypadEnter		AND 0x00FF ] = $$KeyEnter
	altCharFF [ $$XK_KeypadHome			AND 0x00FF ] = $$Keypad7
	altCharFF [ $$XK_KeypadLeft			AND 0x00FF ] = $$Keypad4
	altCharFF [ $$XK_KeypadUp				AND 0x00FF ] = $$Keypad8
	altCharFF [ $$XK_KeypadRight		AND 0x00FF ] = $$Keypad6
	altCharFF [ $$XK_KeypadDown			AND 0x00FF ] = $$Keypad2
	altCharFF [ $$XK_KeypadPageUp		AND 0x00FF ] = $$Keypad9
	altCharFF [ $$XK_KeypadPageDown	AND 0x00FF ] = $$Keypad3
	altCharFF [ $$XK_KeypadEnd			AND 0x00FF ] = $$Keypad1
	altCharFF [ $$XK_KeypadBegin		AND 0x00FF ] = $$Keypad5
	altCharFF [ $$XK_KeypadInsert		AND 0x00FF ] = $$Keypad0
	altCharFF [ $$XK_KeypadDelete		AND 0x00FF ] = $$KeypadDecimalPoint
	altCharFF [ $$XK_KeypadMultiply	AND 0x00FF ] = $$KeypadMultiply
	altCharFF [ $$XK_KeypadAdd			AND 0x00FF ] = $$KeypadAdd
	altCharFF [ $$XK_KeypadSubtract	AND 0x00FF ] = $$KeypadSubtract
	altCharFF [ $$XK_KeypadDivide		AND 0x00FF ] = $$KeypadDivide
	altCharFF [ $$XK_Num_Lock				AND 0x00FF ] = $$KeyNumLock
	altCharFF [ $$XK_F1							AND 0x00FF ] = $$KeyF1
	altCharFF [ $$XK_F2							AND 0x00FF ] = $$KeyF2
	altCharFF [ $$XK_F3							AND 0x00FF ] = $$KeyF3
	altCharFF [ $$XK_F4							AND 0x00FF ] = $$KeyF4
	altCharFF [ $$XK_F5							AND 0x00FF ] = $$KeyF5
	altCharFF [ $$XK_F6							AND 0x00FF ] = $$KeyF6
	altCharFF [ $$XK_F7							AND 0x00FF ] = $$KeyF7
	altCharFF [ $$XK_F8							AND 0x00FF ] = $$KeyF8
	altCharFF [ $$XK_F9							AND 0x00FF ] = $$KeyF9
	altCharFF [ $$XK_F10						AND 0x00FF ] = $$KeyF10
	altCharFF [ $$XK_F11						AND 0x00FF ] = $$KeyF11
	altCharFF [ $$XK_F12						AND 0x00FF ] = $$KeyF12
	altCharFF [ $$XK_F13						AND 0x00FF ] = $$KeyF13
	altCharFF [ $$XK_F14						AND 0x00FF ] = $$KeyF14
	altCharFF [ $$XK_F15						AND 0x00FF ] = $$KeyF15
	altCharFF [ $$XK_F16						AND 0x00FF ] = $$KeyF16
	altCharFF [ $$XK_F17						AND 0x00FF ] = $$KeyF17
	altCharFF [ $$XK_F18						AND 0x00FF ] = $$KeyF18
	altCharFF [ $$XK_F19						AND 0x00FF ] = $$KeyF19
	altCharFF [ $$XK_F20						AND 0x00FF ] = $$KeyF20
	altCharFF [ $$XK_F21						AND 0x00FF ] = $$KeyF21
	altCharFF [ $$XK_F22						AND 0x00FF ] = $$KeyF22
	altCharFF [ $$XK_F23						AND 0x00FF ] = $$KeyF23
	altCharFF [ $$XK_F24						AND 0x00FF ] = $$KeyF24
	altCharFF [ $$XK_Shift_Left			AND 0x00FF ] = $$KeyLeftShift
	altCharFF [ $$XK_Shift_Right		AND 0x00FF ] = $$KeyRightShift
	altCharFF [ $$XK_Control_Left		AND 0x00FF ] = $$KeyLeftControl
	altCharFF [ $$XK_Control_Right	AND 0x00FF ] = $$KeyRightControl
	altCharFF [ $$XK_Caps_Lock			AND 0x00FF ] = $$KeyCapLock
	altCharFF [ $$XK_Alt_Left				AND 0x00FF ] = $$KeyLeftAlt
	altCharFF [ $$XK_Alt_Right			AND 0x00FF ] = $$KeyRightAlt
'
' *****  charsetKeystateModify[]  *****
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i = $$KeyTab)					: charsetKeystateModify[i] = i
			CASE (i = $$KeyEnter)				: charsetKeystateModify[i] = i
			CASE (i = $$KeyDelete)			: charsetKeystateModify[i] = i
			CASE (i = $$KeyInsert)			: charsetKeystateModify[i] = i
			CASE (i = $$KeyBackspace)		: charsetKeystateModify[i] = i
			CASE (i < 32)								: charsetKeystateModify[i] = 0
			CASE ELSE										: charsetKeystateModify[i] = i
		END SELECT
	NEXT i
'
' need to open a display and window to be able to register cursors and get
' #displayWidth, #displayHeight, #windowBorderWidth, #windowTitleHeight
'
	display$ = ""                                     '*cw* 220822+
'	display$ = ":0.0"                                 '*cw* 220822-
	error = Display (@display, $$Open, @display$)			' no error if already open
	IF error THEN
		PRINT "Can't open display \"" + display$ + "\"", error
		exit(1)
	END IF
'
' Asign needed Atoms
'
' need the #XA_CARDINAL and #XA_NET_WORKAREA atoms before XgrCreateWindow
'
	XxxXgrAsignAtom (@"ATOM",                         @#XA_ATOM)
	XxxXgrAsignAtom (@"BITMAP",                       @#XA_BITMAP)
	XxxXgrAsignAtom (@"CARDINAL",                     @#XA_CARDINAL)
	XxxXgrAsignAtom (@"CLIPBOARD",                    @#XA_CLIPBOARD)
	XxxXgrAsignAtom (@"DIB",                          @#XA_DIB)
	XxxXgrAsignAtom (@"IMAGE",                        @#XA_IMAGE)
	XxxXgrAsignAtom (@"PIXMAP",                       @#XA_PIXMAP)
	XxxXgrAsignAtom (@"PRIMARY",                      @#XA_PRIMARY)
	XxxXgrAsignAtom (@"SECONDARY",                    @#XA_SECONDARY)
	XxxXgrAsignAtom (@"STRING",                       @#XA_STRING)
	XxxXgrAsignAtom (@"TEXT",                         @#XA_TEXT)
	XxxXgrAsignAtom (@"WM_DELETE_WINDOW",             @#XA_WM_DELETE_WINDOW)
	XxxXgrAsignAtom (@"WM_NAME",                      @#XA_WM_NAME)
	XxxXgrAsignAtom (@"WM_PROTOCOLS",                 @#XA_WM_PROTOCOLS)
	XxxXgrAsignAtom (@"WM_SAVE_YOURSELF",             @#XA_WM_SAVE_YOURSELF)
	XxxXgrAsignAtom (@"WM_TAKE_FOCUS",                @#XA_WM_TAKE_FOCUS)
	XxxXgrAsignAtom (@"_NET_WM_STATE",                @#XA_NET_WM_STATE)
	XxxXgrAsignAtom (@"_NET_WM_STATE_ADD",            @#XA_NET_WM_STATE_ADD)
	XxxXgrAsignAtom (@"_NET_WM_STATE_REMOVE",         @#XA_NET_WM_STATE_REMOVE)
	XxxXgrAsignAtom (@"_NET_WM_STATE_TOGGLE",         @#XA_NET_WM_STATE_TOGGLE)
	XxxXgrAsignAtom (@"_NET_WM_STATE_ABOVE",          @#XA_NET_WM_STATE_ABOVE)
	XxxXgrAsignAtom (@"_NET_WM_STATE_FULLSCREEN",     @#XA_NET_WM_STATE_FULLSCREEN)
	XxxXgrAsignAtom (@"_NET_WM_STATE_HIDDEN",         @#XA_NET_WM_STATE_HIDDEN)
	XxxXgrAsignAtom (@"_NET_WM_STATE_MAXIMIZED_HORZ", @#XA_NET_WM_STATE_MAXIMIZED_HORZ)
	XxxXgrAsignAtom (@"_NET_WM_STATE_MAXIMIZED_VERT", @#XA_NET_WM_STATE_MAXIMIZED_VERT)
	XxxXgrAsignAtom (@"_NET_WORKAREA",                @#XA_NET_WORKAREA)
'
'
' Create eternal window
'
	XgrCreateWindow (@window, 0, 0, 0, $$WindowMinimumWidth, $$WindowMinimumHeight, 0, "")
'
	#sdisplayEternal = window[window].sdisplay
	#displayEternal = window[window].display
	#swindowEternal = window[window].swindow
	#windowEternal = window
'
' register standard cursors
'
	XgrRegisterCursor (@"default",      @#cursorDefault)
	XgrRegisterCursor (@"arrow",        @#cursorArrow)
	XgrRegisterCursor (@"n",            @#cursorN)
	XgrRegisterCursor (@"s",            @#cursorS)
	XgrRegisterCursor (@"e",            @#cursorE)
	XgrRegisterCursor (@"w",            @#cursorW)
	XgrRegisterCursor (@"ns",           @#cursorArrowsNS)
	XgrRegisterCursor (@"ns",           @#cursorArrowsSN)
	XgrRegisterCursor (@"ew",           @#cursorArrowsEW)
	XgrRegisterCursor (@"ew",           @#cursorArrowsWE)
	XgrRegisterCursor (@"nwse",         @#cursorArrowsNWSE)
	XgrRegisterCursor (@"nesw",         @#cursorArrowsNESW)
	XgrRegisterCursor (@"all",          @#cursorArrowsAll)
	XgrRegisterCursor (@"plus",         @#cursorPlus)
	XgrRegisterCursor (@"wait",         @#cursorWait)
	XgrRegisterCursor (@"insert",       @#cursorInsert)
	XgrRegisterCursor (@"crosshair",    @#cursorCrosshair)
	XgrRegisterCursor (@"hourglass",    @#cursorHourglass)
	XgrRegisterCursor (@"hand",         @#cursorHand)            '*cw* 230201
'	XgrRegisterCursor (@"help",         @#cursorHelp)            '*cw* 091204 until we get the files
'
' ********************************************
' *****  Register Standard Window Icons  *****
' ********************************************
'
'	XgrRegisterIcon (@"hand",					@#iconHand)
'	XgrRegisterIcon (@"asterisk",			@#iconAsterisk)
'	XgrRegisterIcon (@"question",			@#iconQuestion)
'	XgrRegisterIcon (@"exclamation",	@#iconExclamation)
'	XgrRegisterIcon (@"application",	@#iconApplication)
'
'	XgrRegisterIcon (@"hand",					@#iconStop)						' alias
'	XgrRegisterIcon (@"asterisk",			@#iconInformation)		' alias
'	XgrRegisterIcon (@"application",  @#iconBlank)					' alias
'
	XgrRegisterIcon (@"window",				@#iconWindow)					' custom
'
'
' register GraphicsDesigner messages
'
	XgrRegisterMessage (@"Blowback",										@#Blowback)
	XgrRegisterMessage (@"Callback",										@#Callback)
	XgrRegisterMessage (@"Cancel",											@#Cancel)
	XgrRegisterMessage (@"Change",											@#Change)
	XgrRegisterMessage (@"CloseWindow",									@#CloseWindow)
	XgrRegisterMessage (@"ContextChange",								@#ContextChange)
	XgrRegisterMessage (@"Create",											@#Create)
	XgrRegisterMessage (@"CreateValueArray",						@#CreateValueArray)
	XgrRegisterMessage (@"CreateWindow",								@#CreateWindow)
	XgrRegisterMessage (@"CursorH",											@#CursorH)
	XgrRegisterMessage (@"CursorV",											@#CursorV)
	XgrRegisterMessage (@"Deselected",							    @#Deselected)
	XgrRegisterMessage (@"Destroy",											@#Destroy)
	XgrRegisterMessage (@"Destroyed",										@#Destroyed)
	XgrRegisterMessage (@"DestroyWindow",								@#DestroyWindow)
	XgrRegisterMessage (@"Disable",											@#Disable)
	XgrRegisterMessage (@"Disabled",										@#Disabled)
	XgrRegisterMessage (@"Displayed",										@#Displayed)
	XgrRegisterMessage (@"DisplayWindow",								@#DisplayWindow)
	XgrRegisterMessage (@"Enable",											@#Enable)
	XgrRegisterMessage (@"Enabled",											@#Enabled)
	XgrRegisterMessage (@"Enter",												@#Enter)
	XgrRegisterMessage (@"ExitMessageLoop",							@#ExitMessageLoop)
	XgrRegisterMessage (@"Find",												@#Find)
	XgrRegisterMessage (@"FindForward",									@#FindForward)
	XgrRegisterMessage (@"FindReverse",									@#FindReverse)
	XgrRegisterMessage (@"Forward",											@#Forward)
	XgrRegisterMessage (@"GetAlign",										@#GetAlign)
	XgrRegisterMessage (@"GetBorder",										@#GetBorder)
	XgrRegisterMessage (@"GetBorderOffset",							@#GetBorderOffset)
	XgrRegisterMessage (@"GetCallback",									@#GetCallback)
	XgrRegisterMessage (@"GetCallbackArgs",							@#GetCallbackArgs)
	XgrRegisterMessage (@"GetCan",											@#GetCan)
	XgrRegisterMessage (@"GetCharacterMapArray",				@#GetCharacterMapArray)
	XgrRegisterMessage (@"GetCharacterMapEntry",				@#GetCharacterMapEntry)
	XgrRegisterMessage (@"GetClipGrid",									@#GetClipGrid)
	XgrRegisterMessage (@"GetColor",										@#GetColor)
	XgrRegisterMessage (@"GetColorExtra",								@#GetColorExtra)
	XgrRegisterMessage (@"GetCursor",										@#GetCursor)
	XgrRegisterMessage (@"GetCursorXY",									@#GetCursorXY)
	XgrRegisterMessage (@"GetDisplay",									@#GetDisplay)
	XgrRegisterMessage (@"GetEnclosedGrids",						@#GetEnclosedGrids)
	XgrRegisterMessage (@"GetEnclosingGrid",						@#GetEnclosingGrid)
	XgrRegisterMessage (@"GetFocusColor",								@#GetFocusColor)
	XgrRegisterMessage (@"GetFocusColorExtra",					@#GetFocusColorExtra)
	XgrRegisterMessage (@"GetFont",											@#GetFont)
	XgrRegisterMessage (@"GetFontMetrics",							@#GetFontMetrics)
	XgrRegisterMessage (@"GetFontNumber",								@#GetFontNumber)
	XgrRegisterMessage (@"GetGridFunction",							@#GetGridFunction)
	XgrRegisterMessage (@"GetGridFunctionName",					@#GetGridFunctionName)
	XgrRegisterMessage (@"GetGridName",									@#GetGridName)
	XgrRegisterMessage (@"GetGridNumber",								@#GetGridNumber)
	XgrRegisterMessage (@"GetGridProperties",						@#GetGridProperties)
	XgrRegisterMessage (@"GetGridType",									@#GetGridType)
	XgrRegisterMessage (@"GetGridTypeName",							@#GetGridTypeName)
	XgrRegisterMessage (@"GetGroup",										@#GetGroup)
	XgrRegisterMessage (@"GetHelp",											@#GetHelp)
	XgrRegisterMessage (@"GetHelpFile",									@#GetHelpFile)
	XgrRegisterMessage (@"GetHelpString",								@#GetHelpString)
	XgrRegisterMessage (@"GetHelpStrings",							@#GetHelpStrings)
	XgrRegisterMessage (@"GetHintString",								@#GetHintString)
	XgrRegisterMessage (@"GetImage",										@#GetImage)
	XgrRegisterMessage (@"GetImageCoords",							@#GetImageCoords)
	XgrRegisterMessage (@"GetIndent",										@#GetIndent)
	XgrRegisterMessage (@"GetInfo",											@#GetInfo)
	XgrRegisterMessage (@"GetJustify",									@#GetJustify)
	XgrRegisterMessage (@"GetKeyboardFocus",						@#GetKeyboardFocus)
	XgrRegisterMessage (@"GetKeyboardFocusGrid",				@#GetKeyboardFocusGrid)
	XgrRegisterMessage (@"GetKidArray",									@#GetKidArray)
	XgrRegisterMessage (@"GetKidNumber",								@#GetKidNumber)
	XgrRegisterMessage (@"GetKids",											@#GetKids)
	XgrRegisterMessage (@"GetKind",											@#GetKind)
	XgrRegisterMessage (@"GetMaxMinSize",								@#GetMaxMinSize)
	XgrRegisterMessage (@"GetMenuEntryArray",						@#GetMenuEntryArray)
	XgrRegisterMessage (@"GetMessageFunc",							@#GetMessageFunc)
	XgrRegisterMessage (@"GetMessageFuncArray",					@#GetMessageFuncArray)
	XgrRegisterMessage (@"GetMessageSub",								@#GetMessageSub)
	XgrRegisterMessage (@"GetMessageSubArray",					@#GetMessageSubArray)
	XgrRegisterMessage (@"GetModalInfo",								@#GetModalInfo)
	XgrRegisterMessage (@"GetModalWindow",							@#GetModalWindow)
	XgrRegisterMessage (@"GetParent",										@#GetParent)
	XgrRegisterMessage (@"GetPosition",									@#GetPosition)
	XgrRegisterMessage (@"GetProtoInfo",								@#GetProtoInfo)
	XgrRegisterMessage (@"GetRedrawFlags",							@#GetRedrawFlags)
	XgrRegisterMessage (@"GetSize",											@#GetSize)
	XgrRegisterMessage (@"GetSmallestSize",							@#GetSmallestSize)
	XgrRegisterMessage (@"GetState",										@#GetState)
	XgrRegisterMessage (@"GetStyle",										@#GetStyle)
	XgrRegisterMessage (@"GetTabArray",									@#GetTabArray)
	XgrRegisterMessage (@"GetTabWidth",									@#GetTabWidth)
	XgrRegisterMessage (@"GetTextArray",								@#GetTextArray)
	XgrRegisterMessage (@"GetTextArrayBounds",					@#GetTextArrayBounds)
	XgrRegisterMessage (@"GetTextArrayLine",						@#GetTextArrayLine)
	XgrRegisterMessage (@"GetTextArrayLines",						@#GetTextArrayLines)
	XgrRegisterMessage (@"GetTextCursor",								@#GetTextCursor)
	XgrRegisterMessage (@"GetTextFilename",							@#GetTextFilename)
	XgrRegisterMessage (@"GetTextFlag",									@#GetTextFlag)
	XgrRegisterMessage (@"GetTextPosition",							@#GetTextPosition)
	XgrRegisterMessage (@"GetTextSelection",						@#GetTextSelection)
	XgrRegisterMessage (@"GetTextSpacing",							@#GetTextSpacing)
	XgrRegisterMessage (@"GetTextString",								@#GetTextString)
	XgrRegisterMessage (@"GetTextStrings",							@#GetTextStrings)
	XgrRegisterMessage (@"GetTexture",									@#GetTexture)
	XgrRegisterMessage (@"GetTimer",										@#GetTimer)
	XgrRegisterMessage (@"GetValue",										@#GetValue)
	XgrRegisterMessage (@"GetValueArray",								@#GetValueArray)
	XgrRegisterMessage (@"GetValues",										@#GetValues)
	XgrRegisterMessage (@"GetWindow",										@#GetWindow)
	XgrRegisterMessage (@"GetWindowFunction",						@#GetWindowFunction)
	XgrRegisterMessage (@"GetWindowGrid",								@#GetWindowGrid)
	XgrRegisterMessage (@"GetWindowIcon",								@#GetWindowIcon)
	XgrRegisterMessage (@"GetWindowSize",								@#GetWindowSize)
	XgrRegisterMessage (@"GetWindowTitle",							@#GetWindowTitle)
	XgrRegisterMessage (@"GotKeyboardFocus",						@#GotKeyboardFocus)
	XgrRegisterMessage (@"GrabArray",										@#GrabArray)
	XgrRegisterMessage (@"GrabTextArray",								@#GrabTextArray)
	XgrRegisterMessage (@"GrabTextString",							@#GrabTextString)
	XgrRegisterMessage (@"GrabValueArray",							@#GrabValueArray)
	XgrRegisterMessage (@"HalfPageDown",								@#HalfPageDown)
	XgrRegisterMessage (@"HalfPageUp",									@#HalfPageUp)
	XgrRegisterMessage (@"Help",												@#Help)
	XgrRegisterMessage (@"Hidden",											@#Hidden)
	XgrRegisterMessage (@"HideTextCursor",							@#HideTextCursor)
	XgrRegisterMessage (@"HideWindow",									@#HideWindow)
	XgrRegisterMessage (@"Initialize",									@#Initialize)
	XgrRegisterMessage (@"Initialized",									@#Initialized)
	XgrRegisterMessage (@"Inline",											@#Inline)
	XgrRegisterMessage (@"InquireText",									@#InquireText)
	XgrRegisterMessage (@"KeyboardFocusBackward",				@#KeyboardFocusBackward)
	XgrRegisterMessage (@"KeyboardFocusForward",				@#KeyboardFocusForward)
	XgrRegisterMessage (@"KeyDown",											@#KeyDown)
	XgrRegisterMessage (@"KeyUp",												@#KeyUp)
	XgrRegisterMessage (@"LostKeyboardFocus",						@#LostKeyboardFocus)
	XgrRegisterMessage (@"LostTextSelection",						@#LostTextSelection)
	XgrRegisterMessage (@"Maximized",										@#Maximized)
	XgrRegisterMessage (@"MaximizeWindow",							@#MaximizeWindow)
	XgrRegisterMessage (@"Maximum",											@#Maximum)
	XgrRegisterMessage (@"Minimized",										@#Minimized)
	XgrRegisterMessage (@"MinimizeWindow",							@#MinimizeWindow)
	XgrRegisterMessage (@"Minimum",											@#Minimum)
	XgrRegisterMessage (@"MonitorContext",							@#MonitorContext)
	XgrRegisterMessage (@"MonitorHelp",									@#MonitorHelp)
	XgrRegisterMessage (@"MonitorKeyboard",							@#MonitorKeyboard)
	XgrRegisterMessage (@"MonitorMouse",								@#MonitorMouse)
	XgrRegisterMessage (@"MouseDown",										@#MouseDown)
	XgrRegisterMessage (@"MouseDrag",										@#MouseDrag)
	XgrRegisterMessage (@"MouseEnter",									@#MouseEnter)
	XgrRegisterMessage (@"MouseExit",										@#MouseExit)
	XgrRegisterMessage (@"MouseMove",										@#MouseMove)
	XgrRegisterMessage (@"MouseUp",											@#MouseUp)
	XgrRegisterMessage (@"MouseWheel",									@#MouseWheel)
	XgrRegisterMessage (@"MuchLess",										@#MuchLess)
	XgrRegisterMessage (@"MuchMore",										@#MuchMore)
	XgrRegisterMessage (@"Notify",											@#Notify)
	XgrRegisterMessage (@"OneLess",											@#OneLess)
	XgrRegisterMessage (@"OneMore",											@#OneMore)
	XgrRegisterMessage (@"PageDown",										@#PageDown)
	XgrRegisterMessage (@"PageUp",											@#PageUp)
	XgrRegisterMessage (@"PokeArray",										@#PokeArray)
	XgrRegisterMessage (@"PokeTextArray",								@#PokeTextArray)
	XgrRegisterMessage (@"PokeTextString",							@#PokeTextString)
	XgrRegisterMessage (@"PokeValueArray",							@#PokeValueArray)
	XgrRegisterMessage (@"Print",												@#Print)
	XgrRegisterMessage (@"Redraw",											@#Redraw)
	XgrRegisterMessage (@"RedrawGrid",									@#RedrawGrid)
	XgrRegisterMessage (@"RedrawLines",									@#RedrawLines)
	XgrRegisterMessage (@"Redrawn",											@#Redrawn)
	XgrRegisterMessage (@"RedrawText",									@#RedrawText)
	XgrRegisterMessage (@"RedrawWindow",								@#RedrawWindow)
	XgrRegisterMessage (@"Replace",											@#Replace)
	XgrRegisterMessage (@"ReplaceForward",							@#ReplaceForward)
	XgrRegisterMessage (@"ReplaceReverse",							@#ReplaceReverse)
	XgrRegisterMessage (@"Reset",												@#Reset)
	XgrRegisterMessage (@"Resize",											@#Resize)
	XgrRegisterMessage (@"Resized",											@#Resized)
	XgrRegisterMessage (@"ResizeNot",										@#ResizeNot)
	XgrRegisterMessage (@"ResizeWindow",								@#ResizeWindow)
	XgrRegisterMessage (@"ResizeWindowToGrid",					@#ResizeWindowToGrid)
	XgrRegisterMessage (@"RestoreWindow",								@#RestoreWindow)
	XgrRegisterMessage (@"Reverse",											@#Reverse)
	XgrRegisterMessage (@"ScrollH",											@#ScrollH)
	XgrRegisterMessage (@"ScrollV",											@#ScrollV)
	XgrRegisterMessage (@"Select",											@#Select)
	XgrRegisterMessage (@"Selected",										@#Selected)
	XgrRegisterMessage (@"Selection",										@#Selection)
	XgrRegisterMessage (@"SelectWindow",								@#SelectWindow)
	XgrRegisterMessage (@"SetAlign",										@#SetAlign)
	XgrRegisterMessage (@"SetBorder",										@#SetBorder)
	XgrRegisterMessage (@"SetBorderOffset",							@#SetBorderOffset)
	XgrRegisterMessage (@"SetCallback",									@#SetCallback)
	XgrRegisterMessage (@"SetCan",											@#SetCan)
	XgrRegisterMessage (@"SetCharacterMapArray",				@#SetCharacterMapArray)
	XgrRegisterMessage (@"SetCharacterMapEntry",				@#SetCharacterMapEntry)
	XgrRegisterMessage (@"SetClipGrid",									@#SetClipGrid)
	XgrRegisterMessage (@"SetColor",										@#SetColor)
	XgrRegisterMessage (@"SetColorAll",									@#SetColorAll)
	XgrRegisterMessage (@"SetColorExtra",								@#SetColorExtra)
	XgrRegisterMessage (@"SetColorExtraAll",						@#SetColorExtraAll)
	XgrRegisterMessage (@"SetCursor",										@#SetCursor)
	XgrRegisterMessage (@"SetCursorXY",									@#SetCursorXY)
	XgrRegisterMessage (@"SetDisplay",									@#SetDisplay)
	XgrRegisterMessage (@"SetFocusColor",								@#SetFocusColor)
	XgrRegisterMessage (@"SetFocusColorExtra",					@#SetFocusColorExtra)
	XgrRegisterMessage (@"SetFont",											@#SetFont)
	XgrRegisterMessage (@"SetFontNumber",								@#SetFontNumber)
	XgrRegisterMessage (@"SetGridFunction",							@#SetGridFunction)
	XgrRegisterMessage (@"SetGridFunctionName",					@#SetGridFunctionName)
	XgrRegisterMessage (@"SetGridName",									@#SetGridName)
	XgrRegisterMessage (@"SetGridProperties",						@#SetGridProperties)
	XgrRegisterMessage (@"SetGridType",									@#SetGridType)
	XgrRegisterMessage (@"SetGridTypeName",							@#SetGridTypeName)
	XgrRegisterMessage (@"SetGroup",										@#SetGroup)
	XgrRegisterMessage (@"SetHelp",											@#SetHelp)
	XgrRegisterMessage (@"SetHelpFile",									@#SetHelpFile)
	XgrRegisterMessage (@"SetHelpString",								@#SetHelpString)
	XgrRegisterMessage (@"SetHelpStrings",							@#SetHelpStrings)
	XgrRegisterMessage (@"SetHintString",								@#SetHintString)
	XgrRegisterMessage (@"SetImage",										@#SetImage)
	XgrRegisterMessage (@"SetImageCoords",							@#SetImageCoords)
	XgrRegisterMessage (@"SetIndent",										@#SetIndent)
	XgrRegisterMessage (@"SetInfo",											@#SetInfo)
	XgrRegisterMessage (@"SetJustify",									@#SetJustify)
	XgrRegisterMessage (@"SetKeyboardFocus",						@#SetKeyboardFocus)
	XgrRegisterMessage (@"SetKeyboardFocusGrid",				@#SetKeyboardFocusGrid)
	XgrRegisterMessage (@"SetKidArray",									@#SetKidArray)
	XgrRegisterMessage (@"SetMaxMinSize",								@#SetMaxMinSize)
	XgrRegisterMessage (@"SetMenuEntryArray",						@#SetMenuEntryArray)
	XgrRegisterMessage (@"SetMessageFunc",							@#SetMessageFunc)
	XgrRegisterMessage (@"SetMessageFuncArray",					@#SetMessageFuncArray)
	XgrRegisterMessage (@"SetMessageSub",								@#SetMessageSub)
	XgrRegisterMessage (@"SetMessageSubArray",					@#SetMessageSubArray)
	XgrRegisterMessage (@"SetModalWindow",							@#SetModalWindow)
	XgrRegisterMessage (@"SetParent",										@#SetParent)
	XgrRegisterMessage (@"SetPosition",									@#SetPosition)
	XgrRegisterMessage (@"SetRedrawFlags",							@#SetRedrawFlags)
	XgrRegisterMessage (@"SetSize",											@#SetSize)
	XgrRegisterMessage (@"SetState",										@#SetState)
	XgrRegisterMessage (@"SetStyle",										@#SetStyle)
	XgrRegisterMessage (@"SetTabArray",									@#SetTabArray)
	XgrRegisterMessage (@"SetTabWidth",									@#SetTabWidth)
	XgrRegisterMessage (@"SetTextArray",								@#SetTextArray)
	XgrRegisterMessage (@"SetTextArrayLine",						@#SetTextArrayLine)
	XgrRegisterMessage (@"SetTextArrayLines",						@#SetTextArrayLines)
	XgrRegisterMessage (@"SetTextCursor",								@#SetTextCursor)
	XgrRegisterMessage (@"SetTextFilename",							@#SetTextFilename)
	XgrRegisterMessage (@"SetTextFlag",									@#SetTextFlag)
	XgrRegisterMessage (@"SetTextSelection",						@#SetTextSelection)
	XgrRegisterMessage (@"SetTextSpacing",							@#SetTextSpacing)
	XgrRegisterMessage (@"SetTextString",								@#SetTextString)
	XgrRegisterMessage (@"SetTextStrings",							@#SetTextStrings)
	XgrRegisterMessage (@"SetTexture",									@#SetTexture)
	XgrRegisterMessage (@"SetTimer",										@#SetTimer)
	XgrRegisterMessage (@"SetValue",										@#SetValue)
	XgrRegisterMessage (@"SetValueArray",								@#SetValueArray)
	XgrRegisterMessage (@"SetValues",										@#SetValues)
	XgrRegisterMessage (@"SetWindowFunction",						@#SetWindowFunction)
	XgrRegisterMessage (@"SetWindowIcon",								@#SetWindowIcon)
	XgrRegisterMessage (@"SetWindowTitle",							@#SetWindowTitle)
	XgrRegisterMessage (@"ShowTextCursor",							@#ShowTextCursor)
	XgrRegisterMessage (@"ShowWindow",									@#ShowWindow)
	XgrRegisterMessage (@"SomeLess",										@#SomeLess)
	XgrRegisterMessage (@"SomeMore",										@#SomeMore)
	XgrRegisterMessage (@"StartTimer",									@#StartTimer)
	XgrRegisterMessage (@"SystemMessage",								@#SystemMessage)
	XgrRegisterMessage (@"TextDelete",									@#TextDelete)
	XgrRegisterMessage (@"TextEvent",										@#TextEvent)
	XgrRegisterMessage (@"TextInsert",									@#TextInsert)
	XgrRegisterMessage (@"TextModified",								@#TextModified)
	XgrRegisterMessage (@"TextReplace",									@#TextReplace)
	XgrRegisterMessage (@"TimeOut",											@#TimeOut)
	XgrRegisterMessage (@"Update",											@#Update)
	XgrRegisterMessage (@"WindowClose",									@#WindowClose)
	XgrRegisterMessage (@"WindowCreate",								@#WindowCreate)
	XgrRegisterMessage (@"WindowDeselected",						@#WindowDeselected)
	XgrRegisterMessage (@"WindowDestroy",								@#WindowDestroy)
	XgrRegisterMessage (@"WindowDestroyed",							@#WindowDestroyed)
	XgrRegisterMessage (@"WindowDisplay",								@#WindowDisplay)
	XgrRegisterMessage (@"WindowDisplayed",							@#WindowDisplayed)
	XgrRegisterMessage (@"WindowGetDisplay",						@#WindowGetDisplay)
	XgrRegisterMessage (@"WindowGetFunction",						@#WindowGetFunction)
	XgrRegisterMessage (@"WindowGetIcon",								@#WindowGetIcon)
	XgrRegisterMessage (@"WindowGetKeyboardFocusGrid",	@#WindowGetKeyboardFocusGrid)
	XgrRegisterMessage (@"WindowGetSelectedWindow",			@#WindowGetSelectedWindow)
	XgrRegisterMessage (@"WindowGetSize",								@#WindowGetSize)
	XgrRegisterMessage (@"WindowGetTitle",							@#WindowGetTitle)
	XgrRegisterMessage (@"WindowHelp",									@#WindowHelp)
	XgrRegisterMessage (@"WindowHidden",								@#WindowHidden)
	XgrRegisterMessage (@"WindowHide",									@#WindowHide)
	XgrRegisterMessage (@"WindowKeyDown",								@#WindowKeyDown)
	XgrRegisterMessage (@"WindowKeyUp",									@#WindowKeyUp)
	XgrRegisterMessage (@"WindowMaximize",							@#WindowMaximize)
	XgrRegisterMessage (@"WindowMaximized",							@#WindowMaximized)
	XgrRegisterMessage (@"WindowMinimize",							@#WindowMinimize)
	XgrRegisterMessage (@"WindowMinimized",							@#WindowMinimized)
	XgrRegisterMessage (@"WindowMonitorContext",				@#WindowMonitorContext)
	XgrRegisterMessage (@"WindowMonitorHelp",						@#WindowMonitorHelp)
	XgrRegisterMessage (@"WindowMonitorKeyboard",				@#WindowMonitorKeyboard)
	XgrRegisterMessage (@"WindowMonitorMouse",					@#WindowMonitorMouse)
	XgrRegisterMessage (@"WindowMouseDown",							@#WindowMouseDown)
	XgrRegisterMessage (@"WindowMouseDrag",							@#WindowMouseDrag)
	XgrRegisterMessage (@"WindowMouseEnter",						@#WindowMouseEnter)
	XgrRegisterMessage (@"WindowMouseExit",							@#WindowMouseExit)
	XgrRegisterMessage (@"WindowMouseMove",							@#WindowMouseMove)
	XgrRegisterMessage (@"WindowMouseUp",								@#WindowMouseUp)
	XgrRegisterMessage (@"WindowMouseWheel",						@#WindowMouseWheel)
	XgrRegisterMessage (@"WindowRedraw",								@#WindowRedraw)
	XgrRegisterMessage (@"WindowRegister",							@#WindowRegister)
	XgrRegisterMessage (@"WindowResize",								@#WindowResize)
	XgrRegisterMessage (@"WindowResized",								@#WindowResized)
	XgrRegisterMessage (@"WindowResizeToGrid",					@#WindowResizeToGrid)
	XgrRegisterMessage (@"WindowRestore",								@#WindowRestore)
	XgrRegisterMessage (@"WindowSelect",								@#WindowSelect)
	XgrRegisterMessage (@"WindowSelected",							@#WindowSelected)
	XgrRegisterMessage (@"WindowSetFunction",						@#WindowSetFunction)
	XgrRegisterMessage (@"WindowSetIcon",								@#WindowSetIcon)
	XgrRegisterMessage (@"WindowSetKeyboardFocusGrid",	@#WindowSetKeyboardFocusGrid)
	XgrRegisterMessage (@"WindowSetTitle",							@#WindowSetTitle)
	XgrRegisterMessage (@"WindowShow",									@#WindowShow)
	XgrRegisterMessage (@"WindowSystemMessage",					@#WindowSystemMessage)
	XgrRegisterMessage (@"LastMessage",									@#LastMessage)
'
' Check for Environment Variable "XBASICDEVELOPER" to
' enable extra information messages and debugging tools.
' Comment out these lines to disable debugging feature
'
	XstGetEnvironmentVariable ("XBASICDEVELOPER", @xbasicDeveloper$)  ' *cw-xbdv*
	IF (xbasicDeveloper$ == "yes") THEN ##XBDV = 0x12345678           ' *cw-xbdv*
'
' install default character map if one exists
'
	IF charMap[] THEN
		name$ = "$HOME" + $$PathSlash$ + "charmap.bin"
		XstGetFileAttributes (@name$, @attr)
			IF ((attr = 0) OR (attr AND $$FileDirectory)) THEN
			name$ = "." + $$PathSlash$ + "charmap.bin"
			XstGetFileAttributes (@name$, @attr)
			IF ((attr = 0) OR (attr AND $$FileDirectory)) THEN
				name$ = "$XBDIR" + $$PathSlash$ + "templates" + $$PathSlash$ + "charmap.bin"
				XstGetFileAttributes (@name$, @attr)
			END IF
		END IF
		IF attr THEN
			IFZ (attr AND $$FileDirectory) THEN
				ifile = OPEN (name$, $$RD)
				IF (ifile > 2) THEN
					size = LOF (ifile)
					IF (size >= 1024) THEN
						upper = (size >> 2) - 1
						##WHOMASK = 0
						DIM map[upper]
						##WHOMASK = whomask
						READ [ifile], map[]
						ATTACH map[] TO charMap[0,]
					END IF
					CLOSE (ifile)
				END IF
			END IF
		END IF
	END IF
'
'
' if you want to see the name of the server vendor, as in "The XFree86 Project, Inc"
'
'	addr = XServerVendor (#sdisplayEternal)
'	a$ = CSTRING$(addr) + "\n"
'	write (1, &a$, LEN(a$))
'
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ######################################
' #####  XgrBorderNameToNumber ()  #####
' ######################################
'
' error = XgrBorderNameToNumber (border$, @border)
'
' converts a border name into a border number
' appropriate for XgrDrawBorder() functions.
'
' see Help > Graphics Library (xgr)
'            *****  grid border styles  *****
'            starting with $$BorderNone
'
' error = $$TRUE if border$ name is not valid
'
FUNCTION  XgrBorderNameToNumber (border$, @border)
	SHARED	border$[]
'
	border = XLONG (border$)
	IF border THEN RETURN
	b$ = TRIM$ (border$)
	IFZ b$ THEN RETURN
'
	c = b${0}
	IF ((c >= '0') AND (c <= '9')) THEN RETURN		' "0" or "0x00" ...
	IF (c != '$') THEN b$ = "$$" + b$
'
	border = -1
	upper = UBOUND (border$[])
	FOR i = 0 TO upper
		IF (b$ = border$[i]) THEN
			border = i
			RETURN
		END IF
	NEXT i
	RETURN ($$TRUE)
END FUNCTION
'
'
' ######################################
' #####  XgrBorderNumberToName ()  #####
' ######################################
'
' XgrBorderNumberToName (border, @border$)
'
' If border number does not exist, border$ will return empty
'
FUNCTION  XgrBorderNumberToName (border, @border$)
	SHARED	border$[]
'
	border$ = ""
	upper = UBOUND (border$[])
	IF (border < 0) THEN RETURN
	IF (border > upper) THEN RETURN
	border$ = border$[border]
END FUNCTION
'
'
' #######################################
' #####  XgrBorderNumberToWidth ()  #####
' #######################################
'
' XgrBorderNumberToWidth (border, @width)
'
' Return the width in pixels for a border number
' or zero for an invalid border number
'
FUNCTION  XgrBorderNumberToWidth (border, @width)
	SHARED	borderWidth[]
'
	width = 0
	upper = UBOUND (borderWidth[])
	IF (border < 0) THEN RETURN
	IF (border > upper) THEN RETURN
	width = borderWidth[border]
END FUNCTION
'
'
' #####################################
' #####  XgrColorNameToNumber ()  #####
' #####################################
'
' error = XgrColorNameToNumber (color$, @color)
'
' error = $$TRUE if invalid color$ name
'
' See: XgrColorNumberToName(), XgrConvertColorToRGB(), XgrConvertRGBToColor()
'
FUNCTION  XgrColorNameToNumber (color$, color)
	SHARED	color$[]
'
	color = XLONG (color$)
	IF color THEN RETURN
	c$ = TRIM$ (color$)
	IFZ c$ THEN RETURN
'
	c = c${0}
	IF ((c >= '0') AND (c <= '9')) THEN RETURN		' "0" or "0x00" ...
	IF (c != '$') THEN c$ = "$$" + c$
'
	IF (c$ = "$$LightGrey") THEN c$ = "$$BrightGrey"
	IF (c$ = "$$BrightYellow") THEN c$ = "$$LightYellow"
	IF (c$ = "$$LightOrange") THEN c$ = "$$BrightOrange"
	IF (c$ = "$$LightViolet") THEN c$ = "$$BrightViolet"
'
	color = -1
	upper = UBOUND (color$[])
	FOR i = 0 TO upper
		IF (c$ = color$[i]) THEN
			color = i
			RETURN
		END IF
	NEXT i
	RETURN ($$TRUE)
END FUNCTION
'
'
' #####################################
' #####  XgrColorNumberToName ()  #####
' #####################################
'
' XgrColorNumberToName (color, @color$)
'
' Color numbers range from 0 to 124
' If color number is not valid, color$ will return blank
'
' See: XgrColorNameToNumber(), XgrConvertColorToRGB(), XgrConvertRGBToColor()
'
FUNCTION  XgrColorNumberToName (color, color$)
	SHARED	color$[]
'
	color$ = ""
	upper = UBOUND (color$[])
	IF (color < 0) THEN RETURN
	IF (color > upper) THEN RETURN
	color$ = color$[color]
END FUNCTION
'
'
' ######################################
' #####  XgrCursorNameToNumber ()  #####
' ######################################
'
' error = XgrCursorNameToNumber (cursor$, @cursor)
'
' error = $$TRUE if cursor$ name is not valid
'
' See: XgrCursorNumberToName()
'
FUNCTION  XgrCursorNameToNumber (cursor$, @cursor)
	SHARED  lastCursor
	SHARED  cursor$[]
'
	cursor = 0
	IFZ cursor$ THEN RETURN ($$FALSE)			' default system cursor
'
	IF (cursor$ = "LastCursor") THEN
		cursor = lastCursor
		RETURN ($$FALSE)
	END IF
'
	upper = UBOUND (cursor$[])
	FOR cursor = 0 TO upper
		IF (cursor$ = cursor$[cursor]) THEN RETURN ($$FALSE)	' found cursor
	NEXT cursor
'
	cursor = 0
	##ERROR = ($$ErrorObjectCursor << 8) OR $$ErrorNatureNonexistent
	IF ##XBDV THEN PRINT "XgrCursorNameToNumber():unregistered cursor:", cursor$
	RETURN ($$TRUE)
END FUNCTION
'
'
' ######################################
' #####  XgrCursorNumberToName ()  #####
' ######################################
'
' error = XgrCursorNumberToName (cursor, @cursor$)
'
' error = $$TRUE if cursor number is not valid
'
' See: XgrCursorNameToNumber()
'
FUNCTION  XgrCursorNumberToName (cursor, @cursor$)
	SHARED  cursor$[]
'
	cursor$ = ""
'
	upper = UBOUND (cursor$[])
	IF ((cursor < 0) OR (cursor > upper)) THEN
		##ERROR = ($$ErrorObjectCursor << 8) OR $$ErrorNatureInvalidIdentity
		IF ##XBDV THEN PRINT "XgrCursorNumberToName() : invalid cursor #", cursor
		RETURN ($$TRUE)
	END IF
'
	cursor$ = cursor$[cursor]
END FUNCTION
'
'
' ################################
' #####  XgrGetClipboard ()  #####
' ################################
'
' error = XgrGetClipboard (clipboard, @clipType, @text$, @image[])
'
' XgrGetClipboard() returns the current contents of clipboard in
' text$ and/or image[], depending on the type of data in clipboard,
' which is returned in clipType.  The interapplication clipboard,
' also called the system clipboard, is clipboard=0.
' Local XBasic clipboard numbers range from 1 to 7
'
' clipType = 0 = $$ClipboardTypeNone
' clipType = 1 = $$ClipboardTypeText
' clipType = 2 = $$ClipboardTypeImage
'
' See: XgrSetClipboard()
'
FUNCTION  XgrGetClipboard (clipboard, type, data$, UBYTE data[])
	SHARED  XSelectionEvent  selectionNotify
	SHARED  UBYTE  clipData[]
	SHARED  clipText$[]
	SHARED  clipType[]
	SHARED  eventTime
	UBYTE  temp[]
	AUTOX  rtype,  format,  items,  after,  data
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetClipboard()lockout", lockout) : lockout = 0
'
	type = 0
	data$ = ""
	DIM data[]
'
'	PRINT "XgrGetClipboard() : "; clipboard, type
'
	IFZ clipData[] THEN
		##WHOMASK = 0
		##LOCKOUT = 100002
		DIM clipType[7]
		DIM clipText$[7]
		DIM clipData[7,]
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
		FOR i = 0 TO 7
			clipType[i] = $$ClipboardTypeNone				' no contents
		NEXT i
	END IF
'
	IF ((clipboard < 0) OR (clipboard > 7)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrGetClipboard() : invalid clipboard # : "; clipboard
		RETURN ($$TRUE)
	END IF
'
	return = $$FALSE
	type = clipType[clipboard]
	sdisplay = #sdisplayEternal
	swindow = #swindowEternal
'
	IFZ clipboard THEN type = type OR $$ClipboardTypeText
'
	SELECT CASE ALL TRUE
		CASE (type AND $$ClipboardTypeText)		: GOSUB Text		' ASCII text
		CASE (type AND $$ClipboardTypeImage)	: GOSUB Image		' DIB format
	END SELECT
	RETURN (return)
'
'
' *****  Text  *****
'
SUB Text
	IF clipboard THEN
'		PRINT "XgrGetClipboard() : Text.x : "; clipboard; type
		data$ = clipText$[clipboard]								' copy of clipboard text
	ELSE
'		PRINT "XgrGetClipboard() : Text.0 : "; clipboard; type
		##WHOMASK = 0
		##LOCKOUT = 100003
		selectionNotify.type = $$FALSE
		XConvertSelection (sdisplay, #XA_CLIPBOARD, #XA_STRING, #XA_TEXT, swindow, eventTime)
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
'		PRINT "XgrGetClipboard() : Text.1 : "; clipboard; type; selectionNotify.type
		DO
			XstSleep (10)															' let the server execute
			DispatchEvents ($$TRUE, $$FALSE)					' wait for EventSelectionNotify
		LOOP UNTIL selectionNotify.type							' set by EventSelectionNotify
		selectionNotify.type = $$FALSE							' ready for next time
'		PRINT "XgrGetClipboard() : Text.2 : "; clipboard; type; selectionNotify.type
'
' need to call XGetWindowProperty() twice because the idiots who designed these functions
' and events don't provide any earlier way to know how many data bytes are in the selection.
'
		IF (selectionNotify.property = #XA_TEXT) THEN
			data$ = ""
			offset = 0					' start reading at the beginning of data$
			length = 0x00100000	' length is in XLONGs, not UBYTEs, so length = 1M XLONGs = 4MB
			delete = 1					' don't delete selection yet, since we're not really reading it here
			data = 0						' initialize data
			after = 0						' initialize after
			rtype = 0						' initialize rtype
			items = 0						' initialize items
			format = 0					' initialize format
			##WHOMASK = 0
			##LOCKOUT = 100004
			error = XGetWindowProperty (sdisplay, swindow, #XA_TEXT, offset, length, delete, #XA_STRING, &rtype, &format, &items, &after, &data)
			##LOCKOUT = lockout
			##WHOMASK = whomask
'			PRINT "XgrGetClipboard() : Text.3 : "; clipboard; type;; HEX$(data,8);; HEX$(&data$,8)
'			PRINT "XgrGetClipboard() : "; HEX$(sdisplay,8);; HEX$(swindow,8);; HEX$(#XA_TEXT,8);; HEX$(#XA_STRING,8);; HEX$(rtype,8);; HEX$(format,8);; HEX$(items,8);; HEX$(after,8);; HEX$(data,8);; HEX$(LEN(data$),8)
'			PRINT "sdisplay          = "; HEX$(sdisplay,8);; 				"XGetWindowProperty ( arg 1 )
'			PRINT "swindow           = "; HEX$(swindow,8);;					"XGetWindowProperty ( arg 2 )
'			PRINT "#XA_TEXT          = "; HEX$(#XA_TEXT,8);;				"XGetWindowProperty ( arg 3 )
'			PRINT "offset            = "; HEX$(offset,8);;					"XGetWindowProperty ( arg 4 )
'			PRINT "length            = "; HEX$(length,8);;					"XGetWindowProperty ( arg 5 )
'			PRINT "delete            = "; HEX$(delete,8);;					"XGetWindowProperty ( arg 6 )
'			PRINT "#XA_STRING        = "; HEX$(#XA_STRING,8);;			"XGetWindowProperty ( arg 7 )
'			PRINT "rtype             = "; HEX$(rtype,8);;						"XGetWindowProperty ( arg 8 )
'			PRINT "format            = "; HEX$(format,8);;					"XGetWindowProperty ( arg 9 )
'			PRINT "items             = "; HEX$(items,8);;						"XGetWindowProperty ( arg A )
'			PRINT "after             = "; HEX$(after,8);;						"XGetWindowProperty ( arg B )
'			PRINT "data aka &data$   = "; HEX$(data,8);;						"XGetWindowProperty ( arg C )
'			PRINT "eventTime         = "; HEX$(eventTime,8)
'			PRINT "#XA_PRIMARY       = "; HEX$(#XA_PRIMARY,8)
'			PRINT "#XA_CLIPBOARD     = "; HEX$(#XA_CLIPBOARD,8)
			IF data THEN
'				PRINT "data[-1]          = "; HEX$(XLONGAT(data,[-1]))
'				PRINT "data[-2]          = "; HEX$(XLONGAT(data,[-2]))
'				PRINT "data[-3]          = "; HEX$(XLONGAT(data,[-3]))
'				PRINT "data[-4]          = "; HEX$(XLONGAT(data,[-4]))
'				XLONGAT(data,[-1]) = 0x80130001
'				XLONGAT(data,[-2]) = items
'				PRINT "data[-1]          = "; HEX$(XLONGAT(data,[-1]))
'				PRINT "data[-2]          = "; HEX$(XLONGAT(data,[-2]))
'				PRINT "data[-3]          = "; HEX$(XLONGAT(data,[-3]))
'				PRINT "data[-4]          = "; HEX$(XLONGAT(data,[-4]))
'				XLONGAT (&&data$) = data
'				PRINT LEN(data$)
'				PRINT "."; data$; "."
				data$ = NULL$(items)
				XstCopyMemory (data, &data$, items)
				##WHOMASK = 0
				##LOCKOUT = 100004
				free (data)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
			IF data$ THEN
				##WHOMASK = 0
				clipText$[clipboard] = data$					' set local clipboard # 0
				##WHOMASK = whomask
			ELSE
				data$ = clipText$[clipboard]					' return local clipboard # 0
			END IF
		ELSE
			data$ = clipText$[clipboard]						' return local clipboard # 0
		END IF
	END IF
'	PRINT "XgrGetClipboard() : Text.5 : "; clipboard; type; "  <"; data$; ">"
END SUB
'
'
' *****  Image  *****
'
SUB Image
	IF clipData[clipboard,] THEN
		upper = UBOUND (clipData[clipboard,])
		DIM data[upper]
		FOR i = 0 TO upper
			data[i] = clipData[clipboard,i]						' copy of clipboard image
		NEXT i
	END IF
'	PRINT "XgrGetClipboard() : Image.z : "; clipboard; type
END SUB
END FUNCTION
'
'
' #############################
' #####  XgrGetCursor ()  #####
' #############################
'
' XgrGetCursor (@cursor)
'
' Returns the currently displayed cursor.
'
FUNCTION  XgrGetCursor (cursor)
	SHARED  activeCursor
'
	cursor = activeCursor
END FUNCTION
'
'
' #####################################
' #####  XgrGetCursorOverride ()  #####
' #####################################
'
' XgrGetCursorOverride (@cursor)
'
' Returns the active cursor override.
'
FUNCTION  XgrGetCursorOverride (cursor)
	SHARED  activeCursorOverride
'
	cursor = activeCursorOverride
END FUNCTION
'
'
' ####################################
' #####  XgrGetDisplayOffset ()  #####
' ####################################
'
' error = XgrGetDisplayOffset (display$, @xOffset, @yOffset, @borderWidth, @titleHeight)
'
' XgrGetDisplayOffset() returns the xOffset, yOffset for window position in pixels,
' as well as the borderWidth and titleHeight of decoration added
' by the display manager for windows that have borders and title-bars.
'
' Newer window managers have wide transparent resizing borders (10 pixels) but the
' x and y offset for the inside grid placement is different than the border width.
'
' display$ = "" denotes the default display.
' If display$ is not open, error = $$TRUE and size of default display is supplied
'
' See: XgrGetWorkArea(), XgrGetDisplaySize()
'
FUNCTION  XgrGetDisplayOffset (display$, xOffset, yOffset, borderWidth, titleHeight)
	SHARED  DISPLAY  display[]
	SHARED  display$[]
	STATIC vender
'
	upper = UBOUND (display$[])
	IF (display$ == "") THEN
		i = 1                    'default display
	ELSE
		FOR i = 1 TO upper
			IF (display$ == display$[i]) THEN EXIT IF 2
		NEXT i
		#ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureNonexistent
		return = $$TRUE          'indicate failure
		i = 1                    'default display
	END IF
	xOffset     = display[i].wmXoffset
	yOffset     = display[i].wmYoffset
	borderWidth = display[i].borderWidth
	titleHeight = display[i].titleHeight
	IFZ (borderWidth || titleHeight) THEN GOSUB GetxbrcBwTh
	RETURN (return)
'
'
' *****  GetxbrcBwTh  *****
'
SUB GetxbrcBwTh
	homepath$ = XstGetHomePath$()
	IF homepath$ THEN
		prefFileNumber = XstOpenPref(homepath$ + "/.xb64rc")
	END IF
	IF prefFileNumber THEN
		XstSetPrefSection (prefFileNumber, "PDE-WindowPositionsAndSizes")
		XstGetPrefXLONG (prefFileNumber, "Console-xOffset", 1, @xOffset)
		XstGetPrefXLONG (prefFileNumber, "Console-yOffset", 2, @yOffset)
		XstGetPrefXLONG (prefFileNumber, "Console-BW", 10, @borderWidth)
		XstGetPrefXLONG (prefFileNumber, "Console-TH", 23, @titleHeight)
		XstDiscardPref (prefFileNumber)
		IF (borderWidth > 10) THEN borderWidth = 10
		IF (titleHeight > 40) THEN titleHeight = 23
		IF (xOffset >= 10) THEN xOffset = 0
		IF (yOffset >= 10) THEN yOffset = 0
		IFZ xOffset THEN
			IF (borderWidth >= 10) THEN
				xOffset = 1
			ELSE
				xOffset = borderWidth
			END IF
		END IF
		IFZ yOffset THEN
			IF (borderWidth >= 10) THEN
				yOffset = 1
			ELSE
				yOffset = borderWidth
			END IF
		END IF
		display[i].wmXoffset = xOffset
		display[i].wmYoffset = yOffset
		display[i].borderWidth = borderWidth
		display[i].titleHeight = titleHeight
		#windowBorderWidth = borderWidth
		#windowTitleHeight = titleHeight
	END IF
	'
	' If there still is no border-width or title-height
	' then displaying #windowEternal should trigger
	' EventReparentNotify() to set them.
	'
	IFZ (borderWidth || titleHeight) THEN
		IF #windowEternal THEN
			XgrDisplayWindow (#windowEternal)
			XgrHideWindow (#windowEternal)
			xOffset     = display[i].wmXoffset
			yOffset     = display[i].wmYoffset
			borderWidth = display[i].borderWidth
			titleHeight = display[i].titleHeight
		END IF
	END IF
END SUB

END FUNCTION
'
'
' ##################################
' #####  XgrGetDisplaySize ()  #####
' ##################################
'
' error = XgrGetDisplaySize (display$, @width, @height, @borderWidth, @titleHeight)
'
' XgrGetDisplaySize() returns the width,height of  display$ in pixels,
' as well as the borderWidth and titleHeight of decoration added
' by the display manager for windows that have borders and title-bars.
'
' display$ = "" denotes the default display.
' If display$ is not open, error = $$TRUE and size of default display is supplied
'
' See: XgrGetWorkArea(), XgrGetDisplayOffset()
'
FUNCTION  XgrGetDisplaySize (display$, width, height, borderWidth, titleHeight)
	SHARED  DISPLAY  display[]
	SHARED  display$[]
	STATIC vender
'
	upper = UBOUND (display$[])
	IF (display$ == "") THEN
		i = 1                    'default display
	ELSE
		FOR i = 1 TO upper
			IF (display$ == display$[i]) THEN EXIT IF 2
		NEXT i
		#ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureNonexistent
		return = $$TRUE          'indicate failure
		i = 1                    'default display
	END IF
	width       = display[i].width
	height      = display[i].height
	borderWidth = display[i].borderWidth
	titleHeight = display[i].titleHeight
	IFZ (borderWidth || titleHeight) THEN GOSUB GetxbrcBwTh
	RETURN (return)
'
'
' *****  GetxbrcBwTh  *****
'
SUB GetxbrcBwTh
	homepath$ = XstGetHomePath$()
	IF homepath$ THEN
		prefFileNumber = XstOpenPref(homepath$ + "/.xb64rc")
	END IF
	IF prefFileNumber THEN
		XstSetPrefSection (prefFileNumber, "PDE-WindowPositionsAndSizes")
		XstGetPrefXLONG (prefFileNumber, "Console-xOffset", 0, @xOffset)
		XstGetPrefXLONG (prefFileNumber, "Console-yOffset", 0, @yOffset)
		XstGetPrefXLONG (prefFileNumber, "Console-BW", 0, @borderWidth)
		XstGetPrefXLONG (prefFileNumber, "Console-TH", 0, @titleHeight)
		XstDiscardPref (prefFileNumber)
		display[i].wmXoffset = xOffset
		display[i].wmYoffset = yOffset
		display[i].borderWidth = borderWidth
		display[i].titleHeight = titleHeight
		#windowBorderWidth = borderWidth
		#windowTitleHeight = titleHeight
	END IF
	'
	' If there still is no border-width or title-height
	' then displaying #windowEternal should trigger
	' EventReparentNotify() to set them.
	'
	IFZ (borderWidth || titleHeight) THEN
		IF #windowEternal THEN
			XgrDisplayWindow (#windowEternal)
			XgrHideWindow (#windowEternal)
			borderWidth = display[i].borderWidth
			titleHeight = display[i].titleHeight
		END IF
	END IF
END SUB

END FUNCTION
'
'
' #####################################
' #####  XgrGetKeystateModify ()  #####
' #####################################
'
' modify = XgrGetKeystateModify (state, @modify, @edit)
'
' XgrGetKeystateModify() estimates whether a #KeyDown message
' with the specified state argument would normally modify text
' in a common text grids like XuiTextLine and XuiTextArea.
'
FUNCTION  XgrGetKeystateModify (state, modify, edit)
	SHARED  UBYTE  charsetKeystateModify[]
'
	edit = 0
	modify = 0
	vkey = state >> 24
	key = state AND 0x00FF
	IFZ key THEN key = vkey
	alt = state AND $$AltBit
	control = state AND $$ControlBit
	contents = state{$$StateContents}       ' 0,1,2 = VirtualKey, ascii, unicode
'
	SELECT CASE contents
		CASE 0		:	IF control THEN
									SELECT CASE key
										CASE $$KeyTab					: modify = key	: edit = key
										CASE $$KeyEnter				: modify = key	: edit = key
										CASE $$KeyDelete			: modify = key	: edit = key
										CASE $$KeyInsert			: modify = 0		: edit = key
										CASE $$KeyBackspace		: modify = key	: edit = key
									END SELECT
								ELSE
									SELECT CASE key
										CASE $$KeyTab					: modify = key	: edit = key
										CASE $$KeyEnter				: modify = key	: edit = key
										CASE $$KeyDelete			: modify = key	: edit = key
'										CASE $$KeyInsert			: modify = key	: edit = key
										CASE $$KeyInsert			: IF (state AND $$ShiftBit) THEN
																							modify = key	: edit = key
																						ELSE
																							modify = 0  : edit = key
																						END IF
										CASE $$KeyBackspace		: modify = key	: edit = key
									END SELECT
								END IF
'		CASE 1		: IF control THEN
'
' ASCII plus control and alt together might be
' Alternate-Graphics on an international keyboard
'
		CASE 1		: IF (control && alt) THEN
									IF (key != vkey) THEN
										modifyy = charsetKeystateModify[key]
									END IF
								END IF
								IF control THEN
									SELECT CASE key
										CASE $$KeyControlH	: modify = key	: edit = $$KeyBackspace	' ^H = backspace
										CASE $$KeyControlI	: modify = key	: edit = $$KeyTab				' ^I = tab
										CASE $$KeyControlM	: modify = key	: edit = $$KeyEnter			' ^M = enter
										CASE $$KeyControlV	: modify = key	: edit = $$KeyInsert		' ^V = insert
										CASE $$KeyControlX	: modify = key	: edit = $$KeyDelete		' ^X = delete
									END SELECT
								ELSE
									SELECT CASE key
										CASE $$KeyTab					: modify = key	: edit = key
										CASE $$KeyEnter				: modify = key	: edit = key
										CASE $$KeyDelete			: modify = key	: edit = key
										CASE $$KeyInsert			: modify = key	: edit = key
										CASE $$KeyBackspace		: modify = key	: edit = key
										CASE ELSE							: modify = charsetKeystateModify[key]
									END SELECT
								END IF
		CASE ELSE	: modify = 0
	END SELECT
	RETURN (modify)
END FUNCTION
'
'
' ############################
' #####  XgrGetWorkArea  #####
' ############################
'
' error = XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
'
' If there is a error, it returns the display size as the work area.
'
FUNCTION  XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
'
' Set default to the display size
'
	XgrGetDisplaySize ("", @workAreaWidth, @workAreaHeight, @borderWidth, @titleHeight)
	workAreaX = 0
	workAreaY = 0
'
' Now get the most up-to-date values using the _NET_WORKAREA atom method
'
	##XERROR = 0
	wingrid = 0               ' root window
	XgrGetWindowPropertyXLONG   (wingrid, #XA_NET_WORKAREA, #XA_CARDINAL, 4, @data[])
	IF ##XERROR THEN PRINT "XgrGetWorkArea():XError", HEXX$(##XERROR, 6) : RETURN ($$TRUE)
	IF (UBOUND(data[]) < 3) THEN PRINT "XgrGetWorkArea():data[] UBOUND less than 3", UBOUND(data[]) : RETURN ($$TRUE)

	workAreaX      = data[0]
	workAreaY      = data[1]
	workAreaWidth  = data[2]
	workAreaHeight = data[3]
'
END FUNCTION
'
'
' ####################################
' #####  XgrIconNameToNumber ()  #####
' ####################################
'
' error = XgrIconNameToNumber (icon$, @icon)
'
' XgrIconNameToNumber() converts iconName$ into the iconNumber
' originally assigned it by XgrRegisterIcon().
' If iconName$ was never registered, iconNumber = 0.
'
FUNCTION  XgrIconNameToNumber (icon$, @icon)
	SHARED  lastIcon
	SHARED  icon$[]
'
	icon = 0
	IFZ icon$ THEN RETURN ($$FALSE)			' default system icon
'
	IF (icon$ = "LastIcon") THEN
		icon = lastIcon
		RETURN ($$FALSE)
	END IF
'
	upper = UBOUND (icon$[])
	FOR icon = 0 TO upper
		IF (icon$ = icon$[icon]) THEN RETURN ($$FALSE)	' found icon
	NEXT icon
'
	icon = 0
	##ERROR = ($$ErrorObjectIcon << 8) OR $$ErrorNatureNonexistent
	IF ##XBDV THEN PRINT "XgrIconNameToNumber() : unregistered icon"
	RETURN ($$TRUE)
END FUNCTION
'
'
' ####################################
' #####  XgrIconNumberToName ()  #####
' ####################################
'
' error = XgrIconNumberToName (iconNumber, @iconName$)
'
' XgrIconNumberToName() converts iconNumber into the iconName$
' it was created for by XgrRegisterIcon().
'
' If iconNumber has not been assigned to any icon, iconName$ = "".
'
FUNCTION  XgrIconNumberToName (icon, @icon$)
	SHARED  icon$[]
'
	icon$ = ""
'
	upper = UBOUND (icon$[])
	IF ((icon < 0) OR (icon > upper)) THEN
		##ERROR = ($$ErrorObjectIcon << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrIconNumberToName() : invalid icon #"
		RETURN ($$TRUE)
	END IF
'
	icon$ = icon$[icon]
END FUNCTION
'
'
' ##################################
' #####  XgrRegisterCursor ()  #####
' ##################################
'
' error = XgrRegisterCursor (filename$, @cursor)
'
' XgrRegisterCursor() assigns a unique cursor number for filename$
'
' filename$, excluding the directory portion, is changed to
' lower case characters and then checked for the following:
' If filename$ = "",           cursor = 0
' If filename$ = "default",    cursor = 0
' If filename$ = "LastCursor", cursor = highest cursor number assigned
' "crosshair" is converted to "plus"
' "hourglass" is converted to "wait"
'
FUNCTION  XgrRegisterCursor (filename$, @cursor)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  lastCursor
	SHARED  cursor$[]
	SHARED  cursor[]
	AUTOX  cx, cy
	AUTOX  mx, my
	AUTOX  cur, msk
	AUTOX  cwidth, cheight
	AUTOX  mwidth, mheight
	XColor  scb, scf
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrRegisterCursor()lockout", lockout) : lockout = 0
'
	XstGetPathComponents (@filename$, @path$, @drive$, @dir$, @cursor$, @attr)
'
	cursor$ = LCASE$(cursor$)
	ext$ = RIGHT$(cursor$, 4)
	IF ((ext$ == ".cur") || (ext$ == ".msk")) THEN cursor$ = RCLIP$(cursor$, 4)
'
	cursor = 0
	SELECT CASE cursor$
		CASE ""           : RETURN ($$FALSE)                       ' default cursor
		CASE "default"    : RETURN ($$FALSE)                       ' default cursor
		CASE "lastcursor" : cursor = lastCursor : RETURN ($$FALSE)
		CASE "crosshair"	: cursor$ = "plus"
		CASE "hourglass"	: cursor$ = "wait"
		CASE "sizeall"		: cursor$ = "all"
		CASE "sizenesw"		: cursor$ = "nesw"
		CASE "sizens"			: cursor$ = "ns"
		CASE "sizenwse"		: cursor$ = "nwse"
		CASE "sizewe"			: cursor$ = "we"
		CASE "uparrow"		: cursor$ = "n"
	END SELECT
'
	IFZ cursor$[] THEN
		##WHOMASK = 0
		DIM cursor[15]
		DIM cursor$[15]
		##WHOMASK = whomask
	END IF
'
	slot = -1
	upper = UBOUND (cursor$[])
	FOR cursor = 1 TO upper
		IF cursor$[cursor] THEN
			IF (cursor$ = cursor$[cursor]) THEN RETURN ($$FALSE)	' registered
		ELSE
			IF (slot < 0) THEN slot = cursor
		END IF
	NEXT cursor
'
' cursor not yet registered - try to load from disk
'
	IF (slot < 0) THEN
		##WHOMASK = 0
		slot = cursor
		upper = upper + 16
		REDIM cursor[upper]
		REDIM cursor$[upper]
		##WHOMASK = whomask
	END IF
'
	FOR w = 1 TO UBOUND (window[])
		IF window[w].window THEN
			swindow = window[w].swindow
			sdisplay = window[w].sdisplay
			EXIT FOR
		END IF
	NEXT w
'
	IF ((swindow = 0) OR (sdisplay = 0)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrRegisterCursor() : some display and window must exist"
		cursor = 0
		RETURN ($$TRUE)
	END IF
'
'	path$ = LCASE$(cursor$)
'	SELECT CASE path$
'		CASE "default"		: path$ = "arrow"
'		CASE "crosshair"	: path$ = "plus"
'		CASE "hourglass"	: path$ = "wait"
'	END SELECT
'
'	cursor = 0
'	dot = RINSTR (path$, ".")                           ' .extent ?
'	IF dot THEN path$ = LEFT$ (path$, dot-1)            ' remove .extent
'	back = RINSTR (path$, "/")                          ' imbedded path ?
'	IFZ back THEN path$ = "$XBDIR/images/" + path$      ' default path
	IF dir$ THEN
		path$ = cursor$
	ELSE
		path$ = "$XBDIR/images/" + cursor$                ' default path
	END IF
	cur$ = path$ + ".cur"
	msk$ = path$ + ".msk"
'
	cur$ = XstPathString$ (@cur$)
	msk$ = XstPathString$ (@msk$)
	XstGetFileAttributes (@cur$, @attcur)
	IFZ (attcur AND $$FileNormalOrReadOnly) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrRegisterCursor(120):File Nonexistent", cur$, HEXX$(attcur)
		cursor = 0
		RETURN ($$TRUE)
	END IF
	XstGetFileAttributes (@msk$, @attmsk)
'
	##WHOMASK = 0
	##LOCKOUT = 100005
	cerror = XReadBitmapFile (sdisplay, swindow, &cur$, &cwidth, &cheight, &cur, &cx, &cy)
	IF attmsk THEN
		merror = XReadBitmapFile (sdisplay, swindow, &msk$, &mwidth, &mheight, &msk, &mx, &my)
	ELSE
		msk = 0
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (cerror OR merror) THEN
		##ERROR = ($$ErrorObjectSystemFunction << 8) OR $$ErrorNatureFailed
		PRINT "XgrRegisterCursor() : XReadBitmapFile() failed : "; cerror; merror;; cur$;; msk$
		cursor = 0
		RETURN ($$TRUE)
	END IF
'
	IF attmsk THEN
		IF ((cwidth != mwidth) OR (cheight != mheight)) THEN
			##ERROR = ($$ErrorObjectCursor << 8) OR $$ErrorNatureInvalidSize
			PRINT "XgrRegisterCursor() : cursor and mask are not the same size"
			cursor = 0
			RETURN ($$TRUE)
		END IF
	END IF
'
' set cursor background and foreground colors
'
	scb.r = 0x0000FFFF												' white background
	scb.g = 0x0000FFFF                        '
	scb.b = 0x0000FFFF                        '
	scf.r = 0x00000000												' black forground
	scf.g = 0x00000000                        '
	scf.b = 0x00000000                        '
	scb.scolor = display[1].color[$$White]		' white background
	scf.scolor = display[1].color[$$Black]		' black foreground
'
	##WHOMASK = 0
	##LOCKOUT = 100006
	scursor = XCreatePixmapCursor (sdisplay, cur, msk, &scf, &scb, cx, cy)
	XFreePixmap (sdisplay, cur)
	IF attmsk THEN
		XFreePixmap (sdisplay, msk)
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ scursor THEN
		##ERROR = ($$ErrorObjectSystemFunction << 8) OR $$ErrorNatureFailed
		PRINT "XgrRegisterCursor() : XCreatePixmapCursor() failed"
		cursor = 0
		RETURN ($$TRUE)
	END IF
'
	cur$ = RCLIP$ (cur$, 4)										' remove ".cur"
	back = RINSTR (cur$, $$PathSlash$)				' find last path slash
	IF back THEN cur$ = MID$ (cur$, back+1)		' cur$ = pure cursor name
'
	cursor = slot

	##WHOMASK = 0
	cursor$[cursor] = cur$
	cursor[cursor] = scursor
	#cursorMax = cursor
	IF (cursor > lastCursor) THEN lastCursor = cursor
	##WHOMASK = whomask
END FUNCTION
'
'
' ################################
' #####  XgrRegisterIcon ()  #####
' ################################
'
' error = XgrRegisterIcon (filename$, @icon)
'
' XgrRegisterIcon() assigns a unique icon number for filename$
'
' If filename$ = "",         icon = 0
' If filename$ = "default",  icon = 0
' If filename$ = "LastIcon", icon = highest icon number assigned
'
FUNCTION  XgrRegisterIcon (filename$, @icon)
	SHARED  WINDOW  window[]
	SHARED  lastIcon
	SHARED  sicon[]
	SHARED  icon$[]
	SHARED  icon[]
	AUTOX  x
	AUTOX  y
	AUTOX  width
	AUTOX  height
	AUTOX  sicon
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrRegisterIcon()lockout", lockout) : lockout = 0
'
	icon = 0
	IFZ filename$ THEN RETURN ($$FALSE)								' default icon
	IF (filename$ = "default") THEN RETURN ($$FALSE)	' ditto
'
	IF (filename$ = "LastIcon") THEN
		icon = lastIcon
		RETURN ($$FALSE)
	END IF
'
	icon$ = filename$
	u = UBOUND (icon$)
	FOR i = 0 TO u
		c = icon${i}
		IF (c = '\\') THEN icon${i} = '/'			' change "\" to "/"
	NEXT i
'
	IFZ icon$[] THEN
		##WHOMASK = 0
		DIM icon[15]
		DIM icon$[15]
		DIM sicon[15]
		##WHOMASK = whomask
	END IF
'
	slot = -1
	upper = UBOUND (icon$[])
	FOR icon = 1 TO upper
		IF icon$[icon] THEN
			IF (icon$ = icon$[icon]) THEN RETURN ($$FALSE)	' registered
		ELSE
			IF (slot < 0) THEN slot = icon
		END IF
	NEXT icon
'
' icon not yet registered - try to load from disk
'
	IF (slot < 0) THEN
		##WHOMASK = 0
		slot = icon
		upper = upper + 16
		REDIM icon[upper]
		REDIM icon$[upper]
		REDIM sicon[upper]
		##WHOMASK = whomask
	END IF
'
	FOR w = 1 TO UBOUND (window[])
		IF window[w].window THEN
			swindow = window[w].swindow
			sdisplay = window[w].sdisplay
			EXIT FOR
		END IF
	NEXT w
'
	IF ((swindow = 0) OR (sdisplay = 0)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrRegisterIcon() : some display and window must exist"
		RETURN ($$TRUE)
	END IF
'
	path$ = LCASE$(icon$)
'
	icon = 0
	dot = RINSTR (path$, ".")                         ' .extent ?
	IF dot THEN path$ = LEFT$ (path$, dot-1)          ' remove .extent
	back = RINSTR (path$, "/")                        ' imbedded path ?
	IFZ back THEN path$ = "$XBDIR/images/" + path$    ' default path
	ico$ = path$ + ".ico"
'
	ico$ = XstPathString$ (@ico$)
'
	##WHOMASK = 0
	##LOCKOUT = 100007
	error = XReadBitmapFile (sdisplay, swindow, &ico$, &width, &height, &sicon, &x, &y)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	IF ##XBDV THEN PRINT "XgrRegisterIcon(110)", swindow, sdisplay, path$, icon
'	IF ##XBDV THEN PRINT "XgrRegisterIcon(111)", error, ico$, width, height, x, y
'
	IF error THEN
		##ERROR = ($$ErrorObjectSystemFunction << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrRegisterIcon() : XReadBitmapFile() failed : "; ico$
		RETURN ($$TRUE)
	END IF
'
	ico$ = RCLIP$ (ico$, 4)										' remove ".ico"
	back = RINSTR (ico$, $$PathSlash$)				' find last path slash
	IF back THEN ico$ = MID$ (ico$, back+1)		' ico$ = pure icon name
'
	icon = slot
	icon[icon] = icon
	##WHOMASK = 0
	icon$[icon] = ico$
	##WHOMASK = whomask
	sicon[icon] = sicon
	#iconMax = icon
	IF (icon > lastIcon) THEN lastIcon = icon
END FUNCTION
'
'
' ################################
' #####  XgrSetClipboard ()  #####
' ################################
'
' error = XgrSetClipboard (clipboard, clipType, @text$, @image[])
'
' XgrSetClipboard() installs text$ and/or image[] into clipboard,
' depending on the type of data specified by clipType.
' The system clipboard is clipboard=0.
'
' clipType = 0 = $$ClipboardTypeNone
' clipType = 1 = $$ClipboardTypeText
' clipType = 2 = $$ClipboardTypeImage
'
' See: XgrGetClipboard()
'
FUNCTION  XgrSetClipboard (clipboard, type, data$, UBYTE data[])
	SHARED  UBYTE  clipData[]
	SHARED  clipText$[]
	SHARED  clipType[]
	SHARED  eventTime
	UBYTE  temp[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetClipboard()lockout", lockout) : lockout = 0
'
'	PRINT "XgrSetClipboard().A : "; clipboard; type
'
	IFZ clipData[] THEN
		##WHOMASK = 0
		##LOCKOUT = 100008
		DIM clipType[7]
		DIM clipText$[7]
		DIM clipData[7,]
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
		FOR i = 0 TO 7
			clipType[i] = $$ClipboardTypeNone				' no contents
		NEXT i
	END IF
'
	IF ((clipboard < 0) OR (clipboard > 7)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrSetClipboard() : invalid clipboard #"
		RETURN ($$TRUE)
	END IF
'
	return = $$FALSE
	clipType[clipboard] = $$ClipboardTypeNone			' until proven otherwise
	sdisplay = #sdisplayEternal
	swindow = #swindowEternal
'
	SELECT CASE type
		CASE $$ClipboardTypeNone		: GOSUB None
		CASE $$ClipboardTypeText		:	GOSUB Text
		CASE $$ClipboardTypeImage		:	GOSUB Image
	END SELECT
'
	clipType = 0
	IF clipText$[clipboard] THEN clipType = clipType OR $$ClipboardTypeText
	IF clipData[clipboard,] THEN clipType = clipType OR $$ClipboardTypeImage
	clipType[clipboard] = clipType
	RETURN (return)
'
'
' *****  None  *****
'
SUB None
	##WHOMASK = 0
	clipText$[clipboard] = ""
	ATTACH clipData[clipboard,] TO temp[]
	##WHOMASK = whomask
END SUB
'
'
' *****  Text  *****
'
SUB Text
'	PRINT "XgrSetClipboard() : Text.A"; clipboard; type
	##WHOMASK = 0
	clipText$[clipboard] = ""												' clear text
	IF data$ THEN clipText$[clipboard] = data$
	##WHOMASK = whomask
'
' clipboard #0 is the interapplication clipboard aka the xlib PRIMARY selection
'
'
'	PRINT "XgrSetClipboard() : Text.B"; clipboard; type
	IFZ clipboard THEN
		IFZ swindow THEN EXIT SUB
		IFZ sdisplay THEN EXIT SUB
'		PRINT "XgrSetClipboard() : Text.C"; clipboard; type
		##WHOMASK = 0
		##LOCKOUT = 100009
		sowner = XSetSelectionOwner (sdisplay, #XA_PRIMARY, swindow, eventTime)
		sowner = XSetSelectionOwner (sdisplay, #XA_CLIPBOARD, swindow, eventTime)
		##LOCKOUT = lockout
		##WHOMASK = whomask
'		PRINT "XgrSetClipboard() : Text.D"; clipboard; type;; HEX$(sdisplay,8);; HEX$(swindow,8);; HEX$(sowner,8);; eventTime
	END IF
END SUB
'
'
' *****  Image  *****
'
SUB Image
	ATTACH clipData[clipboard,] TO temp[]						' clear image
	DIM temp[]
'
	IF data[] THEN
		upper = UBOUND (data[])
		datatype = TYPE (data[])
		IF (datatype != $$UBYTE) THEN
			##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidType
			IF ##XBDV THEN PRINT "XgrSetClipboard() : invalid image array type : data[] must be UBYTE"
			return = $$TRUE
			EXIT SUB
		END IF
'
		addr = &data[]
		b = UBYTEAT (addr, 0)
		m = UBYTEAT (addr, 1)
		IF ((b != 'B') OR (m != 'M')) THEN
			##ERROR = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidSignature
			IF ##XBDV THEN PRINT "XgrSetClipboard() : invalid image array signature : not BM"
			return = $$TRUE
			EXIT SUB
		END IF
'
		##WHOMASK = 0
		DIM temp[upper]
		##WHOMASK = whomask
'
		FOR i = 0 TO upper
			temp[i] = data[i]														' copy image data
		NEXT i
		ATTACH temp[] TO clipData[clipboard,]					' save image data
	END IF
'
' clipboard #0 is the interapplication clipboard aka the xlib PRIMARY selection
'
	IFZ clipboard THEN
		##WHOMASK = 0
		##LOCKOUT = 100010
		owner = XSetSelectionOwner (sdisplay, #XA_PRIMARY, swindow, eventTime)
		owner = XSetSelectionOwner (sdisplay, #XA_CLIPBOARD, swindow, eventTime)
		##LOCKOUT = lockout
		##WHOMASK = whomask
'		PRINT "XgrSetClipboard(0) : "; HEX$(sdisplay,8);; HEX$(swindow,8);; HEX$(owner,8)
	END IF
END SUB
END FUNCTION
'
'
' #############################
' #####  XgrSetCursor ()  #####
' #############################
'
' Not used in Linux.
'
' X11 changes the cursor as it moves from grid to grid
' as defined in XgrSetGridCursor()
'
' See: XgrSetGridCursor(), XuiSetCursor()
'
FUNCTION  XgrSetCursor (cursor, @oldCursor)
	SHARED  WINDOW  window[]
	SHARED  activeCursorOverride
	SHARED  activeCursor
	SHARED  cursor[]
'
	RETURN                                              ' Not used in Linux
'
'************************************************************************
'
	oldCursor = activeCursor
	IF (cursor = activeCursor) THEN RETURN ($$FALSE)		' no change
'
	IF InvalidCursor (cursor) THEN
		##ERROR = ($$ErrorObjectCursor << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrSetCursor() : invalid cursor #"
		RETURN ($$TRUE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetCursor()lockout", lockout) : lockout = 0
'
	activeCursor = cursor
	scursor = cursor[cursor]
	IF activeCursorOverride THEN RETURN ($$FALSE)				' no change now
'
	upper = UBOUND (window[])
	FOR w = 1 TO upper
		IF window[w].window THEN
			IF (w = window[w].top) THEN
				IF window[w].swindow THEN
					IFZ window[w].destroy THEN
						IFZ window[w].destroyed THEN
							IFZ window[w].destroyProcessed
								swindow = window[w].swindow
								sdisplay = window[w].sdisplay
								##WHOMASK = 0
								##LOCKOUT = 100011
								XDefineCursor (sdisplay, swindow, scursor)
								##LOCKOUT = lockout
								##WHOMASK = whomask
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT w
END FUNCTION
'
'
' #####################################
' #####  XgrSetCursorOverride ()  #####
' #####################################
'
' error = XgrSetCursorOverride (cursor, @oldCursor)
'
' XgrSetCursorOverride() sets the current cursorOverride and returns
' the oldCursorOverride.  The displayed cursor changes to cursor.
'
' If cursor = 0, the cursorOverride is removed and the
' cursor is set to the value before the any override.
'
' See: SetCursor, XgrRegisterCursor()
'
FUNCTION  XgrSetCursorOverride (cursor, @oldCursorOverride)
	SHARED  WINDOW  window[]
	SHARED  activeCursorOverride
	SHARED  cursor[]
'
	oldCursorOverride = activeCursorOverride
	IF (cursor = activeCursorOverride) THEN RETURN ($$FALSE)	' no change
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetCursorOverride()lockout", lockout) : lockout = 0
'
	IFZ cursor THEN
		GOSUB RestoreCursors
		RETURN
	END IF
'
	IF InvalidCursor (cursor) THEN
		##ERROR = ($$ErrorObjectCursor << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrSetCursorOverride() : invalid cursor #"
		RETURN ($$TRUE)
	END IF
'
	activeCursorOverride = cursor
	scursor = cursor[cursor]
'
	upper = UBOUND (window[])
	FOR w = 1 TO upper
		IF InvalidGrid (w) THEN DO NEXT
		IF window[w].window THEN
			IF (window[w].type > 1) THEN       'exclude image grids
				swindow = window[w].swindow
				sdisplay = window[w].sdisplay
				##WHOMASK = 0
				##LOCKOUT = 100012
				XDefineCursor (sdisplay, swindow, scursor)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
		END IF
	NEXT w
'
'
' *****  RestoreCursors  *****
'
SUB RestoreCursors
	activeCursorOverride = 0
	upper = UBOUND (window[])
	FOR w = 1 TO upper
		IF InvalidGrid (w) THEN DO NEXT
		IF window[w].window THEN
			IF (window[w].type > 1) THEN       'exclude image grids
				swindow = window[w].swindow
				sdisplay = window[w].sdisplay
				scursor = window[w].scursor      'scursor as set in XgrSetGridCursor()
				##WHOMASK = 0
				##LOCKOUT = 100013
				XDefineCursor (sdisplay, swindow, scursor)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
		END IF
	NEXT w
END SUB
'
END FUNCTION
'
'
' ############################
' #####  XgrSetDebug ()  #####  set debug variable
' ############################
'
' XgrSetDebug (arg)
'
'  $$DebugBrief          = 1
'  $$DebugWordy          = 2
'  $$DebugError          = 4
'
FUNCTION  XgrSetDebug (arg)
'
	##XBDV = arg

END FUNCTION
'
'
' #################################
' #####  XgrSetGridCursor ()  #####
' #################################
'
' error = XgrSetGridCursor (grid, cursor)
'
' XgrSetGridCursor() tells X11 the cursor to be displayed
' when the mouse is in this grid.
'
' See: XgrSetCursor(), XuiSetCursor()
'
FUNCTION  XgrSetGridCursor (grid, cursor)
	SHARED  WINDOW  window[]
	SHARED  activeCursorOverride
	SHARED  cursor[]
'
	IF InvalidCursor (cursor) THEN
		##ERROR = ($$ErrorObjectCursor << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrSetGridCursor() : invalid cursor #"
		RETURN ($$TRUE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetGridCursor()lockout", lockout) : lockout = 0
'
	scursor = cursor[cursor]
'
'		IF (scursor == window[grid].scursor) THEN RETURN
		window[grid].scursor = scursor
		swindow = window[grid].swindow
		sdisplay = window[grid].sdisplay
		##WHOMASK = 0
		##LOCKOUT = 100014
		XDefineCursor (sdisplay, swindow, scursor)
		##LOCKOUT = lockout
		##WHOMASK = whomask
		RETURN
'
END FUNCTION
'
'
' #####################################
' #####  XgrSystemWindowToWindow  #####
' #####################################
'
' error = XgrSystemWindowToWindow (swindow, @window, @top)
'
' swindow = requested Display Manager System Window number
' window  = returned native window number
' top     = returned native top level window number
'
' error is set if window is destroyed or in the process of being destroyed
'
' See: XgrWindowToSystemWindow()
'
FUNCTION  XgrSystemWindowToWindow (swindow, window, top)
	SHARED  swindow[]
	SHARED  WINDOW  window[]
'
	window = 0
	IFZ window[] THEN
		IF ##XBDV THEN
			PRINT "XgrSystemWindowToWindow() : Error : window[] is empty"
		END IF
		RETURN ($$TRUE)
	END IF
'
	swindex = swindow AND 0x1FFFFF
	IF (swindex <= UBOUND (swindow[])) THEN
		w = swindow[swindex]
		IF (window[w].swindow == swindow) THEN
			top = window[w].top
			window = w
		END IF
	END IF
'
' If swindow Xref has zero result then try the old slow search method
'
	IFZ window THEN
		FOR w = 1 TO UBOUND (window[])
			IF window[w].window THEN
				IF (window[w].swindow = swindow) THEN
					top = window[w].top
					window = w
					EXIT FOR
				END IF
			END IF
		NEXT w
		IF window THEN PRINT "XgrSystemWindowToWindow():old method", HEXX$(swindow), HEXX$(window), HEXX$(top)
	END IF
'
' if a grid or its window is being destroyed, return non-zero
'
	trash = $$FALSE
	IF window THEN
		trash = trash OR window[top].destroy
		trash = trash OR window[top].destroyed
		trash = trash OR window[top].destroyProcessed
		trash = trash OR window[window].destroy
		trash = trash OR window[window].destroyed
		trash = trash OR window[window].destroyProcessed
	END IF
	RETURN (trash)
END FUNCTION
'
'
' ########################################
' #####  XgrWindowToSystemWindow ()  #####
' ########################################
'
' XgrWindowToSystemWindow (window, @swindow)
'
' swindow = zero if no match found
'
' See: XgrSystemWindowToWindow()
'
FUNCTION  XgrWindowToSystemWindow (window, swindow)
	SHARED  WINDOW  window[]
'
	swindow = 0
	IF (window < 0) THEN RETURN
	IF (window == 0) THEN
'		IF ##XBDV THEN swindow = display[1].sroot
		RETURN
	END IF
	IF (window > UBOUND (window[])) THEN RETURN
	IFZ window[window].window THEN RETURN
	swindow = window[window].swindow
END FUNCTION
'
'
' ############################
' #####  XgrVersion$ ()  #####
' ############################
'
' version$ = XgrVersion$ ()
'
' XgrVersion$() returns the current Graphics User Interface version$.
'
FUNCTION  XgrVersion$ ()
'
	version$ = VERSION$ (0)
	RETURN (version$)
END FUNCTION
'
'
' ##############################
' #####  XgrCreateFont ()  #####
' ##############################
'
' XgrCreateFont (@font, font$, size, weight, italic, 0)
'
' size   = 20 * point size (ENspace)
' weight:
'    100 = "thin"
'    200 = "extralight"
'    300 = "light"
'    400 = "normal"
'    500 = "medium"
'    600 = "semibold"
'    700 = "bold"
'    800 = "extrabold"
'    900 = "heavy"
' italic = $$TRUE for italic
' angle  = $$FALSE (Not implemented yet)
'
' Example1 : XgrCreateFont (@font, @"Comic Sans MS", 480, 400, 0, 0)
' Example2 : XgrCreateFont (@font, @"9x15bold", 0, 0, 0, 0)            'name found with xlsfonts
'
' An X-Window font name is a string with 14 fields separated by "-"
'
' "-f-t-w-s-w-?-p-t-h-v-s-a-c-#"
'   | | | | | | | | | | | | | |
'   foundry - Adobe, Bitstream, etc
'     typeface - courier, helvetica, etc
'       weight - thin, normal, medium, demibold, bold, heavy, etc
'         slant - roman (normal), italic, oblique, ri (reverse italic), ro (reverse oblique), ot (other)
'           width - normal, condensed, semicondensed, narrow, doublewidth
'             ? - style ??? (informal, roman, serif, sansserif) ???
'               pixels -
'                 tenpoints - 10 * point size (point = 1/72 inch)
'                   hdpi - horizontal resolution in dots per inch
'                     vdpi - vertical resolution in dots per inch
'                       spacing - m = monospace : p = proportional : c = character cell
'                         average width in 1/10 pixels
'                           character set ("iso8859-1")
'                             character set number
'
' X-Window does not support drawing text an an angle.
'
' NOTE: Some Linux commands that can be helpful are:
'   xlsfonts - lists available fonts
'   xfontsel - interactive tool for selecting fonts
'   xfd      - to display characters for a font
'
'   gucharmap - Unicode characters
'
FUNCTION  XgrCreateFont (@font, font$, size, weight, italic, angle)
	SHARED	font$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrCreateFont()lockout", lockout) : lockout = 0
'
'	IF ##XBDV THEN PRINT "XgrCreateFont(59)", font$, size, weight, italic, angle
	font = 0
	IFZ font$ THEN RETURN ($$FALSE)
	typeface$ = TRIM$(LCASE$(font$))
	source$ = "*"
	spacing$ = "*"
'
	SELECT CASE typeface$
		CASE "default"	: RETURN ($$FALSE)
		CASE "system"   : RETURN ($$FALSE)
'		CASE "fixed"		: RETURN ($$FALSE)
		CASE "serif"		: source$ = "adobe"			: typeface$ = "utopia"
		CASE "sanserif"	: source$ = "adobe"			: typeface$ = "helvetica"
		CASE "courier"	: source$ = "adobe"	    : typeface$ = "courier"
		CASE "roman"		: source$ = "adobe"			: typeface$ = "utopia"
		CASE "fancy"		:	source$ = "bitstream"	: typeface$ = "charter"
		CASE "comic sans ms"   : source$ = "microsoft" : spacing$ = "p"
		CASE "trebuchet ms"    : source$ = "microsoft" : spacing$ = "p"
		CASE "verdana"         : source$ = "microsoft" : spacing$ = "p"
		CASE "times new roman" : source$ = "monotype"  : spacing$ = "p"
	END SELECT
'
'	source$ = "*"			' the sources above can cause problems and are not required
'
' generate X-Windows size name from size argument
'
'	size = size >> 1				' convert 1/20 points (ENspace) into 1/10 points (EMspace)
'
	SELECT CASE TRUE
		CASE (size == 0) : size$ = "*"
		CASE (size < 0) : pixels$ = STRING$(-size)
											size = -size * 9.6336
											size$ = STRING$(size)
'		CASE (size > 0)  : size$ = STRING$ (size >> 1) : pixels$ = STRING$(size/20)                   '  75 dpi
'		CASE (size > 0)  : size$ = STRING$ (size >> 1) : pixels$ = STRING$(size * 75 / 1440)          '  75 dpi
		CASE (size > 0)  : size$ = STRING$ (size >> 1) : pixels$ = STRING$(XLONG(size / 19.272))      '  75 dpi
'		CASE (size > 0)  : size$ = STRING$ (size >> 1) : pixels$ = STRING$((size + 16) * 100 / 1500)  ' 100 dpi
'		CASE (size > 0)  : size$ = STRING$ (size >> 1) : pixels$ = STRING$((size + 15) * 100 / 1445)  ' 100 dpi
	END SELECT
'
' generate X-Windows weight name from weight argument
'
	SELECT CASE TRUE
		CASE (weight <= 0)		: weight$ = "*"
'		CASE (weight <= 700)	: weight$ = "medium"
		CASE (weight <= 600)	: weight$ = "medium"
		CASE ELSE							: weight$ = "bold"
	END SELECT
'
'	weight = weight/100 * 100
'	SELECT CASE weight
'		CASE 100  : weight$ = "thin"
'		CASE 200  : weight$ = "extralight"
'		CASE 300  : weight$ = "light"
'		CASE 400  : weight$ = "normal"
'		CASE 500  : weight$ = "medium"
'		CASE 600  : weight$ = "semibold"
'		CASE 700  : weight$ = "bold"
'		CASE 800  : weight$ = "extrabold"
'		CASE 900  : weight$ = "heavy"
'		CASE ELSE : weight$ = "medium" : weight = 500
'	END SELECT
'
' generate X-Windows italic name from italic argument
'
	SELECT CASE TRUE
		CASE (italic < 0)			: italic$ = "i"			' was "*"
		CASE (italic = 0)			: italic$ = "r"
		CASE (italic > 0)			: italic$ = "o"
	END SELECT
'
' If font name is fully hyphenated X-Windows font name then base
' the font name on that, but insert size, bold, and italic fields.
' Otherwise generate an X-Windows font name from font name argument.
'
	DIM hyphen[15]
	DIM name$[15]
	offset = 0
	prior = 0
	entry = 0
	DO WHILE (entry <= 15)
		hyphen = INSTR (font$, "-", offset)
		IF hyphen THEN
			hyphen[entry] = hyphen
			offset = hyphen + 1
			IF entry THEN
'				PRINT font$, prior+1, hyphen-prior-1, LEN (font$)
'				PRINT SPACE$(prior) + "|" + CHR$('-', hyphen-prior-1)
				name$[entry] = MID$ (font$, prior+1, hyphen-prior-1)
			END IF
			INC entry
		END IF
		prior = hyphen
	LOOP WHILE hyphen
'
' 14 hyphens means valid X-Windows font name
'
	IF (entry = 14) THEN
		name$[14] = MID$ (font$, offset)			' field after last "-"
		FOR i = 0 TO 15
			IFZ name$[i] THEN name$[i] = "*"		' empty name to "*" wildcard
		NEXT i
	ELSE
		FOR i = 0 TO 15
			name$[i] = "*"											' not an X-Windows font name
		NEXT i
	END IF
'
	IF (entry >= 14) THEN typeface$ = "*"
'
	IF (name$[ 1] = "*") THEN name$[ 1] = source$
	IF (name$[ 2] = "*") THEN name$[ 2] = typeface$
	IF (name$[ 3] = "*") THEN name$[ 3] = weight$
	IF (name$[ 4] = "*") THEN name$[ 4] = italic$
	IF (name$[ 5] = "*") THEN name$[ 5] = "normal"
'	IF (name$[ 6] = "0") THEN name$[ 6] = "*"
	IF (name$[ 6] = "*") THEN name$[ 6] = ""
'	IF (name$[ 7] = "0") THEN name$[ 7] = "*"
	IF (name$[ 7] = "*") THEN name$[ 7] = pixels$
	IF (name$[ 8] = "*") THEN name$[ 8] = size$
	IF (name$[ 8] = "0") THEN name$[ 8] = size$

	IF (name$[ 9] = "*") THEN name$[ 9] = "75"
	IF (name$[ 9] = "0") THEN name$[ 9] = "75"
	IF (name$[10] = "*") THEN name$[10] = "75"
	IF (name$[10] = "0") THEN name$[10] = "75"
'	IF (name$[ 9] = "*") THEN name$[ 9] = "100"
'	IF (name$[ 9] = "0") THEN name$[ 9] = "100"
'	IF (name$[10] = "*") THEN name$[10] = "100"
'	IF (name$[10] = "0") THEN name$[10] = "100"

	IF (name$[11] = "*") THEN name$[11] = spacing$
'	IF (name$[12] = "0") THEN name$[12] = "*"
	IF (name$[12] = "*") THEN name$[12] = "0"
	IF (name$[13] = "*") THEN name$[13] = "iso8859"
	IF (name$[14] = "*") THEN name$[14] = "1"
'	IF (name$[14] = "*") THEN name$[14] = "15"
'
'	XstLog ("XgrCreateFont().X : " + font$ + " " + STRING$(font) + " " + STRING$(size) + " " + STRING$(weight) + " " + STRING$(italic) + " " + STRING$(angle))
'
	filter$ = "-" + name$[1] + "-" + name$[2] + "-" + name$[3] + "-" + name$[4] + "-" + name$[5] + "-" + name$[6] + "-" + name$[7] + "-" + name$[8] + "-" + name$[9] + "-" + name$[10] + "-" + name$[11] + "-" + name$[12] + "-" + name$[13] + "-" + name$[14]
	IFZ (size OR weight OR italic OR angle) THEN filter$ = font$
'
'	XstLog ("XgrCreateFont().Y : " + filter$)
'
'	IF ##XBDV THEN PRINT "XgrCreateFont(207) : "; filter$
'
	display = 1
	error = Font (@font, $$Create, display, @sfont, @addrFont, size, weight, italic, angle, @filter$)
'
	##WHOMASK = $$FALSE
	upper = UBOUND (font$[])
	IF (font > upper) THEN
		upper = font OR 0x0007
		REDIM font$[upper]
	END IF
	IF font THEN font$[font] = font$
	##WHOMASK = whomask

'	IF error THEN
'		IF ##XBDV THEN PRINT "XgrCreateFont(222):error", filter$
'	END IF
'
'	XstLog ("XgrCreateFont().Z : " + font$ + " # " + STRING$(font) + " " + STRING$(size) + " " + STRING$(weight) + " " + STRING$(italic) + " " + STRING$(angle) + " " + HEX$(sfont,8) + " " + HEX$(addrFont,8))
END FUNCTION
'
'
' ###############################
' #####  XgrDestroyFont ()  #####
' ###############################
'
' Unimpemented
'
FUNCTION  XgrDestroyFont (font)
'	PRINT "XgrDestroyFont() : unimpemented"
END FUNCTION
'
'
' ###############################
' #####  XgrGetFontInfo ()  #####
' ###############################
'
' error = XgrGetFontInfo (font, @fontName$, @fontSize, @fontWeight, @fontItalic, @fontAngle)
'
' XgrGetFontInfo() returns fontName$, fontSize,
' fontWeight, fontItalic, and fontAngle for font.
'
' See XgrCreateFont() for more details.
'
' See: XgrGetFontMetrics()
'
FUNCTION  XgrGetFontInfo (font, @fontName$, @size, @weight, @italic, @angle)
	SHARED  FONT  font[]
	SHARED  font$[]
'
	IF InvalidFont (font) THEN
		##ERROR = ($$ErrorObjectFont << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrGetFontInfo() : invalid font #"
		RETURN ($$TRUE)
	END IF
'
	fontName$ = font$[font]
	IFZ font THEN fontName$ = "default"
	size = font[font].size
	weight = font[font].weight
	italic = font[font].italic
	angle = font[font].angle
END FUNCTION
'
'
' ##################################
' #####  XgrGetFontMetrics ()  #####
' ##################################
'
' error = XgrGetFontMetrics (font, @maxCharWidth, @maxCharHeight, @ascent, @decent, @gap, @flags)
'
' XgrGetFontMetrics() returns the
' maximum character width in pixels,
' maximum character height in pixels,
' the ascent from the baseline of the tallest character,
' the decent from the baseline for the lowest character,
' the gap at the top that is normally interline spacing,
' may contain active character pixels for unusual characters,
' including characters with accents and umlauts.
'
' See: XgrGetFontInfo()
'
FUNCTION  XgrGetFontMetrics (font, @maxCharWidth, @maxCharHeight, @ascent, @descent, @gap, @space)
	SHARED  FONT  font[]
'
	gap = 0
	space = 0
	ascent = 0
	descent = 0
	maxCharWidth = 0
	maxCharHeight = 0
'
	IF InvalidFont (font) THEN
		##ERROR = ($$ErrorObjectFont << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrGetFontMetrics() : invalid font #"
		RETURN ($$TRUE)
	END IF
'
	gap = font[font].gap
	space = font[font].space
	ascent = font[font].ascent
	descent = font[font].descent
	maxCharWidth = font[font].width
	maxCharHeight = font[font].height
END FUNCTION
'
'
' ################################
' #####  XgrGetFontNames ()  #####
' ################################
'
' XgrGetFontNames (count, @fontName$[])
'
' XgrGetFontNames() returns the names of all typefaces
' from which fonts can be created by XgrCreateFont().
'
' count = -2 : list all typeface names
' count = -3 : list everything with detail information
'
' An X-Window font name is a string with 14 fields separated by "-"
'
' "-f-t-w-s-w-?-p-t-h-v-s-a-c-#"
'   | | | | | | | | | | | | | |
'   foundry - Adobe, Bitstream, etc
'     typeface - courier, helvetica, etc
'       weight - thin, normal, medium, demibold, bold, heavy, etc
'         slant - roman (normal), italic, oblique, ri (reverse italic), ro (reverse oblique), ot (other)
'           width - normal, condensed, semicondensed, narrow, doublewidth
'             ? - style ??? (informal, roman, serif, sansserif) ???
'               pixels -
'                 tenpoints - 10 * point size (point = 1/72 inch)
'                   hdpi - horizontal resolution in dots per inch
'                     vdpi - vertical resolution in dots per inch
'                       spacing - m = monospace : p = proportional : c = character cell
'                         average width in 1/10 pixels
'                           character set ("iso8859")
'                             character set extension # ("1")
'
FUNCTION  XgrGetFontNames (@count, @fontName$[])
	SHARED  DISPLAY  display[]
	STATIC  entry
	AUTOX  fonts
'
	IFZ entry THEN
		entry = $$TRUE
		DefaultFontNames (@c, @f$[])
		IF f$[] THEN
			file$ = "$XBDIR" + $$PathSlash$ + "templates" + $$PathSlash$ + "fonts.xxx"
			XstGetFileAttributes (file$, @attributes)
			IF (attributes AND ($$FileNormal OR $$FileArchive)) THEN
				IFZ (attributes AND $$FileReadOnly) THEN
					XstSaveStringArray (@file$, @f$[])
				END IF
			END IF
			DIM f$[]
		END IF
	END IF
'
'	IF (count == -2) THEN everything = $$TRUE
'	IF (count == -3) THEN everything = $$TRUE : detail = $$TRUE
	filter$ = "-*-*-*-*-*-*-0-0-*-*-*-0-*-*"
'
	SELECT CASE count
		CASE -2 : everything = $$TRUE
		CASE -3 : everything = $$TRUE
							detail = $$TRUE
		CASE -5 : everything = $$TRUE
							detail = $$TRUE
							IF fontName$[] THEN
								filter$ = fontName$[0]
								filter$ = TRIM$(filter$)
								filter$ = "-*-" + filter$ + "-*-*-*-*-0-0-75-75-*-0-iso8859-1"
							END IF
		CASE -7 : everything = $$TRUE
							detail = $$TRUE
							IF fontName$[] THEN
								filter$ = fontName$[0]
								filter$ = TRIM$(filter$)
								filter$ = "-*-" + filter$ + "-*-*-*-*-0-0-100-100-*-0-iso8859-1"
							END IF
	END SELECT
'
'	IF ##WHOMASK THEN PRINT "XgrGetFontNames()", count, everything, detail, filter$
'
	count = 0
	DIM fontName$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetFontNames()lockout", lockout) : lockout = 0
'
	sdisplay = display[1].sdisplay			' default display
'	IF everything THEN
'		filter$ = "-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
'		filter$ = "-*-*-*-*-*-*-0-0-*-*-*-0-*-*"
'		filter$ = "-*-*-*-*-*-*-0-0-100-100-*-0-iso8859-1"
'		filter$ = "-*-*-*-*-*-*-0-0-100-100-m-0-iso8859-1"
'		filter$ = "-*-*-*-*-*-*-0-0-100-100-c-0-iso8859-1"
'		filter$ = "-*-*-*-*-*-*-0-0-100-100-p-0-iso8859-1"
'	ELSE
'		filter$ = "-*-*-*-*-*-*-0-0-*-*-*-0-*-*"
'	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100015
'	addrFontList = XListFonts (sdisplay, &filter$, 4096, &fonts)
	addrFontList = XListFonts (sdisplay, &filter$, 8192, &fonts)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ fonts THEN RETURN ($$FALSE)						' no fonts
	IFZ addrFontList THEN RETURN ($$FALSE)		' no fonts
'
	f = 0
	count = 0
	upper = fonts
	addr = addrFontList
	DIM fontName$[upper]
	DIM field$[15]
	INC count
'
	DO
		INC f
		font = XLONGAT (addr)						' font = address of font name
		font$ = CSTRING$ (font)					' font$ = font name
		addr = addr + 8									' addr = address of next font name
		IF font$ THEN
			IF everything THEN
				offset = 1
				IF (font${0} = '-') THEN
					FOR i = 1 TO 14
						next = INSTR (font$, "-", offset+1)
						field$[i] = MID$ (font$, offset+1, next-offset-1)
						offset = next
					NEXT i
					IF ((LEFT$(field$[13],3) = "iso") AND (field$[14] != "1")) THEN DO LOOP
						IF detail THEN
							fontName$[count] = font$
						ELSE
							fontName$ = field$[2]
							FOR i = 1 TO count
								IF (fontName$ = fontName$[i]) THEN DO LOOP
							NEXT i
							fontName$[count] = fontName$
						END IF
						INC count
				END IF
			ELSE
				offset = 1
'				a$ = font$ + "\n"
'				write (1, &a$, LEN(a$))
				IF (font${0} = '-') THEN
					FOR i = 1 TO 14
						next = INSTR (font$, "-", offset+1)
						field$[i] = MID$ (font$, offset+1, next-offset-1)
						offset = next
					NEXT i
					IF (field$[7] = "0") THEN
						IF (field$[8] = "0") THEN
							IF (field$[11] != "c") THEN
								IF (field$[12] = "0") THEN
									fontName$ = field$[2]
									FOR i = 1 TO count
										IF (fontName$ = fontName$[i]) THEN DO LOOP
									NEXT i
'									a$ = field$[2] + "\n" + font$ + "\n"
'									write (1, &a$, LEN(a$))
									fontName$[count] = fontName$
									INC count
								END IF
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	LOOP UNTIL (f >= fonts)
'
	top = count - 1
	IF (top != upper) THEN REDIM fontName$[top]
	flags = $$SortIncreasing OR $$SortAlphaNumeric OR $$SortCaseSensitive
	XstQuickSort (@fontName$[], @orderArray[], 0, top, flags)
'
	##WHOMASK = 0
	##LOCKOUT = 100016
	XFreeFontNames (addrFontList)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #########################################
' #####  XgrGetTextArrayImageSize ()  #####
' #########################################
'
' error = XgrGetTextArrayImageSize (font, @text$[], @w, @h, @width, @height, extraX, extraY)
'
' Calculates the size of a box needed to deplay the text in text$[] using
' the font number and extraX and extraY supplied.
'
' Linux does not support drawwing text on an angle, so
' width will always equal w, and height will always equal h
'
' extraX is the number of pixels to add to the w and width
' extraY is the number of pixels to add to the h and height for each line in the text$[] array
'
FUNCTION  XgrGetTextArrayImageSize (font, text$[], w, h, width, height, extraX, extraY)
'
	IF InvalidFont (font) THEN
		##ERROR = ($$ErrorObjectFont << 8) OR $$ErrorNatureInvalidNumber
		IF ##XBDV THEN PRINT "XgrGetTextArrayImageSize() : invalid font #"; font
		RETURN ($$TRUE)
	END IF
'
	empty = $$FALSE
	IFZ text$[] THEN GOSUB Empty
'
	found = $$FALSE
	upper = UBOUND (text$[])
	FOR i = upper TO 0 STEP -1
		IF text$[i] THEN
			found = $$TRUE
			final = i
			EXIT FOR
		END IF
	NEXT i
'
	IFZ found THEN GOSUB Empty
'
	IF (final < upper) THEN
		REDIM text$[final]
		upper = final
	END IF
'
	XgrGetFontInfo (font, @name$, @size, @weight, @italic, @angle)
	XgrGetTextImageSize (font, @"W", 0, 0, @ww, @hh, @gg, @ss)
	ww = ww + extraX
	hh = hh + extraY
'
	width = 0
	height = 0
	FOR i = 0 TO upper
		IFZ text$[i] THEN
			width = MAX (width, ww)
			height = height + hh
		ELSE
			text$ = text$[i]
			XgrGetTextImageSize (font, @text$, 0, 0, @w, @h, @g, @s)
			w = w + extraX : h = h + extraY
			width = MAX (width, w)
			height = height + h
		END IF
	NEXT i
'
	w = width
	h = height
	IFZ angle THEN
		IF empty THEN DIM text$[]
		RETURN
	END IF
'
' Now take angle into account
'
	w# = width >> 1									' w# = 1/2 width
	h# = height >> 1								' h# = 1/2 height
	r# = SQRT (w#*w# + h#*h#)				' r# = radius of text box
	a# = angle * .1# * $$DEGTORAD		' a# = tilt angle in radians
	na# = ASIN (h# / r#)						' na# = natural angle to corner
	ax = r# * COS (a# - na# + $$PI)	' final x coord of upper-left corner
	ay = r# * SIN (a# - na# + $$PI)	' final y coord of upper-left corner
	bx = r# * COS (a# + na#)				' final x coord of upper-right corner
	by = r# * SIN (a# + na#)				' final y coord of upper-right corner
	cx = r# * COS (a# + na# + $$PI)	' final x coord of lower-left corner
	cy = r# * SIN (a# + na# + $$PI)	' final y coord of lower-left corner
	dx = r# * COS (a# - na#)				' final x coord of lower-right corner
	dy = r# * SIN (a# - na#)				' final y coord of lower-right corner
'
' Find highest and lowest x and y values
'
	minX = +r#
	minY = +r#
	maxX = -r#
	maxY = -r#
'
	IF (ax < minX) THEN minX = ax
	IF (bx < minX) THEN minX = bx
	IF (cx < minX) THEN minX = cx
	IF (dx < minX) THEN minX = dx
	IF (ax > maxX) THEN maxX = ax
	IF (bx > maxX) THEN maxX = bx
	IF (cx > maxX) THEN maxX = cx
	IF (dx > maxX) THEN maxX = dx
	IF (ay < minY) THEN minY = ay
	IF (by < minY) THEN minY = by
	IF (cy < minY) THEN minY = cy
	IF (dy < minY) THEN minY = dy
	IF (ay > maxY) THEN maxY = ay
	IF (by > maxY) THEN maxY = by
	IF (cy > maxY) THEN maxY = cy
	IF (dy > maxY) THEN maxY = dy
'
	width = maxX - minX + 1
	height = maxY - minY + 1
	IF empty THEN DIM text$[]
	RETURN ($$FALSE)
'
'
' *****  Empty  *****
'
SUB Empty
	empty = $$TRUE
	DIM text$[0]
	text$[0] = "W"
END SUB
END FUNCTION
'
'
' ####################################
' #####  XgrGetTextImageSize ()  #####
' ####################################
'
' error = XgrGetTextImageSize (font, text$, @dx, @dy, @width, @height, @gap, @space)
'
' Calculates the size of a box needed to deplay the characters in text$
' using the font number.
'
FUNCTION  XgrGetTextImageSize (font, text$, @dx, @dy, @width, @height, @gap, @space)
	SHARED  FONT  font[]
	AUTOX  direction,  ascent,  descent
	XFontStruct  fontStruct
	XCharStruct  info
'
	IF InvalidFont (font) THEN
		##ERROR = ($$ErrorObjectFont << 8) OR $$ErrorNatureInvalidNumber
		IF ##XBDV THEN PRINT "XgrGetTextImageSize() : invalid font #"; font
		RETURN ($$TRUE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetTextImageSize()lockout", lockout) : lockout = 0
'
	length = LEN (text$)
	addrFont = font[font].addrFont
	XLONGAT (&&fontStruct) = addrFont
	height = font[font].height
	flags = 0
	space = 0
	gap = 0
	dy = 0
	dx = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100017
	XTextExtents (addrFont, &text$, length, &direction, &ascent, &descent, &info)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	width = info.width
	dx = width
'	PRINT "XgrGetTextImageSize() : text$, length, direction, ascent, descent, dx, dy, width, height"
'	PRINT text$; length; direction; ascent; descent; dx; dy; width; height
END FUNCTION
'
'
' #####################################
' #####  XgrConvertColorToRGB ()  #####
' #####################################
'
' error = XgrConvertColorToRGB (color, @red, @green, @blue)
'
' valid color numbers are $$Black = 0 to $$White = 124
'
' See: XgrColorNameToNumber(), XgrColorNumberToName() XgrConvertRGBToColor()
'
FUNCTION  XgrConvertColorToRGB (color, red, green, blue)
	SHARED  rgb[]
'
'	IF (color < 0) THEN
'		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
'		IF ##XBDV THEN PRINT "XgrConvertColorToRGB() : invalid color # "; color
'		RETURN ($$TRUE)
'	END IF
'
'	IF (color > 124) THEN
'		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
'		IF ##XBDV THEN PRINT "XgrConvertColorToRGB() : invalid color # "; color
'		RETURN ($$TRUE)
'	END IF
'
'	IF (color AND 0x000000FF) THEN
'		rgb = rgb[color]
'		red = ((rgb >> 24) AND 0x00FF) << 8
'		green = ((rgb >> 16) AND 0x00FF) << 8
'		blue = ((rgb >> 8) AND 0x00FF) << 8
'	ELSE
'		rgb = color
'		red = ((rgb >> 24) AND 0x00FF) << 8
'		green = ((rgb >> 16) AND 0x00FF) << 8
'		blue = ((rgb >> 8) AND 0x00FF) << 8
'	END IF

	colorIndex = color AND 0x000000FF
	IF (colorIndex > 124) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrConvertColorToRGB() : invalid color # "; color
		RETURN ($$TRUE)
	END IF
'
	IF colorIndex THEN
		rgb = rgb[colorIndex]
		red = ((rgb >> 24) AND 0x00FF) << 8
		green = ((rgb >> 16) AND 0x00FF) << 8
		blue = ((rgb >> 8) AND 0x00FF) << 8
	ELSE
		rgb = colorIndex
		red = ((rgb >> 24) AND 0x00FF) << 8
		green = ((rgb >> 16) AND 0x00FF) << 8
		blue = ((rgb >> 8) AND 0x00FF) << 8
	END IF

END FUNCTION
'
'
' #####################################
' #####  XgrConvertRGBToColor ()  #####
' #####################################
'
' XgrConvertRGBToColor (red, green, blue, @color)
'
' See: XgrColorNameToNumber(), XgrColorNumberToName(), XgrConvertColorToRGB()
'
FUNCTION  XgrConvertRGBToColor (red, green, blue, color)
	SHARED  r[]
	SHARED  g[]
	SHARED  b[]
'
' get halfway intensities
'
	r1 = (r[0] + r[1]) >> 1
	r2 = (r[1] + r[2]) >> 1
	r3 = (r[2] + r[3]) >> 1
	r4 = (r[3] + r[4]) >> 1
'
	g1 = (g[0] + g[1]) >> 1
	g2 = (g[1] + g[2]) >> 1
	g3 = (g[2] + g[3]) >> 1
	g4 = (g[3] + g[4]) >> 1
'
	b1 = (b[0] + b[1]) >> 1
	b2 = (b[1] + b[2]) >> 1
	b3 = (b[2] + b[3]) >> 1
	b4 = (b[3] + b[4]) >> 1
'
' find closest r, g, b
'
	SELECT CASE TRUE
		CASE (red < r1)		: r = 0
		CASE (red < r2)		: r = 1
		CASE (red < r3)		: r = 2
		CASE (red < r4)		: r = 3
		CASE ELSE					: r = 4
	END SELECT
'
	SELECT CASE TRUE
		CASE (green < g1)	: g = 0
		CASE (green < g2)	: g = 1
		CASE (green < g3)	: g = 2
		CASE (green < g4)	: g = 3
		CASE ELSE					: g = 4
	END SELECT
'
	SELECT CASE TRUE
		CASE (blue < b1)	: b = 0
		CASE (blue < b2)	: b = 1
		CASE (blue < b3)	: b = 2
		CASE (blue < b4)	: b = 3
		CASE ELSE					: b = 4
	END SELECT
'
	c = r * 25 + g * 5 + b
	rr = (red >> 8) AND 0x00FF
	gg = (green >> 8) AND 0x00FF
	bb = (blue >> 8) AND 0x00FF
	color = (rr << 24) + (gg << 16) + (bb << 8) + c
END FUNCTION
'
'
' #######################################
' #####  XgrGetBackgroundColor  ()  #####
' #######################################
'
' error = XgrGetBackgroundColor (window, @color)
'
FUNCTION  XgrGetBackgroundColor (window, color)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrGetBackgroundColor() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	color = window[window].backgroundColor
END FUNCTION
'
'
' ####################################
' #####  XgrGetBackgroundRGB ()  #####
' ####################################
'
' error = XgrGetBackgroundRGB (window, @red, @green, @blue)
'
FUNCTION  XgrGetBackgroundRGB (window, red, green, blue)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrGetBackgroundRGB() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	red = window[window].backRed
	green = window[window].backGreen
	blue = window[window].backBlue
END FUNCTION
'
'
' ####################################
' #####  XgrGetDefaultColors ()  #####
' ####################################
'
' XgrGetDefaultColors (@back, @draw, @low, @high, @dull, @acc, @lowtext, @hightext)
'
FUNCTION  XgrGetDefaultColors (back, draw, low, high, dull, acc, lowtext, hightext)
'
	back = #defaultBackground
	draw = #defaultDrawing
	low = #defaultLowlight
	high = #defaultHighlight
	dull = #defaultDull
	acc = #defaultAccent
	lowtext = #defaultLowtext
	hightext = #defaultHightext
END FUNCTION
'
'
' ###################################
' #####  XgrGetDrawingColor ()  #####
' ###################################
'
' error = XgrGetDrawingColor (wingrid, @color)
'
FUNCTION  XgrGetDrawingColor (window, color)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrGetDrawingColor() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	color = window[window].drawingColor
END FUNCTION
'
'
' #################################
' #####  XgrGetDrawingRGB ()  #####
' #################################
'
' error = XgrGetDrawingRGB (window, @red, @green, @blue)
'
FUNCTION  XgrGetDrawingRGB (window, red, green, blue)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrGetDrawingRGB() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	red = window[window].drawRed
	green = window[window].drawGreen
	blue = window[window].drawBlue
END FUNCTION
'
'
' #################################
' #####  XgrGetGridColors ()  #####
' #################################
'
' error = XgrGetGridColors (grid, @back, @draw, @low, @high, @dull, @acc, @lowtext, @hightext)
'
FUNCTION  XgrGetGridColors (grid, @back, @draw, @low, @high, @dull, @acc, @lowtext, @hightext)
	SHARED  WINDOW  window[]
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridColors() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	back = window[window].backgroundColor
	draw = window[window].drawingColor
	low = window[window].lowlightColor
	high = window[window].highlightColor
	dull = window[window].dullColor
	acc = window[window].accentColor
	lowtext = window[window].lowtextColor
	hightext = window[window].hightextColor
END FUNCTION
'
'
' ######################################
' #####  XgrSetBackgroundColor ()  #####
' ######################################
'
' error = XgrSetBackgroundColor (grid, color)
'
FUNCTION  XgrSetBackgroundColor (grid, color)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  rgb[]
	AUTOX  XColor  sc
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetBackgroundColor()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetBackgroundColor() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IF (color = -1) THEN RETURN ($$FALSE)				' no change
'
	window = grid
	gc = window[window].gc
	display = window[window].display
	sdisplay = window[window].sdisplay
	colormap = display[display].colormap
	sbackground = window[window].sbackground
	sbackgroundDefault = window[window].sbackgroundDefault
'
' color = 0 means standard color # 0 = $$Black
'
	IFZ color THEN
		window[window].backRed = 0
		window[window].backGreen = 0
		window[window].backBlue = 0
		window[window].backColor = 0
		window[window].backgroundColor = 0
		scolor = display[display].color[0]
		window[window].sbackground = scolor
		window[window].sbackgroundDefault = scolor
'
		IF (scolor != sbackground) THEN
			##WHOMASK = 0
			##LOCKOUT = 100018
			XSetBackground (sdisplay, gc, scolor)
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
		RETURN ($$FALSE)
	END IF
'
' standard color # != 0 means color is standard color #
'
	c = color AND 0x000000FF
	IF (c > 124) THEN c = 124
'
	IF c THEN
		rgb = rgb[c]
		window[window].backColor = c
		window[window].backRed = (rgb AND 0xFF000000) >> 16
		window[window].backGreen = (rgb AND 0x00FF0000) >> 8
		window[window].backBlue = (rgb AND 0x0000FF00)
		window[window].backgroundColor = c
		scolor = display[display].color[c]
		window[window].sbackground = scolor
		window[window].sbackgroundDefault = scolor
'
		IF (scolor != sbackground) THEN
			##WHOMASK = 0
			##LOCKOUT = 100019
			XSetBackground (sdisplay, gc, scolor)
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
		RETURN ($$FALSE)
	END IF
'
' color is in rgb field of rgbc color argument
'
	red = (color AND 0xFF000000) >> 16
	green = (color AND 0x00FF0000) >> 8
	blue = (color AND 0x0000FF00)
'
	r = red >> 8
	g = green >> 8
	b = blue >> 8
	c = 0
'
	window[window].backRed = red
	window[window].backGreen = green
	window[window].backBlue = blue
	window[window].backColor = 0
	window[window].backgroundColor = (r << 24) + (g << 16) + (b << 8) + c
'
	sc.scolor = 0
	sc.r = red
	sc.g = green
	sc.b = blue
'
	##WHOMASK = 0
	##LOCKOUT = 100020
	okay = XAllocColor (sdisplay, colormap, &sc)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	scolor = sc.scolor
	window[window].sbackground = scolor
	window[window].sbackgroundDefault = scolor
	IFZ okay THEN PRINT "XgrSetBackgroundColor() : XAllocColor() failed : "; window, color, scolor, sbackground, sbackgroundDefault
'
	IF (scolor != sbackground) THEN
		##WHOMASK = 0
		##LOCKOUT = 100021
		XSetBackground (sdisplay, gc, scolor)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' ####################################
' #####  XgrSetBackgroundRGB ()  #####
' ####################################
'
' error = XgrSetBackgroundRGB (grid, red, green, blue)
'
FUNCTION  XgrSetBackgroundRGB (grid, red, green, blue)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	AUTOX  XColor  sc
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetBackgroundRGB() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetBackgroundRGB()lockout", lockout) : lockout = 0
'
	window = grid
	gc = window[window].gc
	display = window[window].display
	sdisplay = window[window].sdisplay
	colormap = display[display].colormap
	sbackground = window[window].sbackground
	sbackgroundDefault = window[window].sbackgroundDefault
'
' color = 0 means standard color # 0 = $$Black
'
	IFZ (red OR green OR blue) THEN
		window[window].backRed = 0
		window[window].backGreen = 0
		window[window].backBlue = 0
		window[window].backColor = 0
		window[window].backgroundColor = 0
		scolor = display[display].color[0]
		window[window].sbackground = scolor
		window[window].sbackgroundDefault = scolor
'
		IF (scolor != sbackground) THEN
			##WHOMASK = 0
			##LOCKOUT = 100022
			XSetBackground (sdisplay, gc, scolor)
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
		RETURN ($$FALSE)
	END IF
'
' allocate rgb color
'
	red = red AND 0x0000FFFF
	green = green AND 0x0000FFFF
	blue = blue AND 0x0000FFFF
	r = red >> 8
	g = green >> 8
	b = blue >> 8
	c = 0
'
	window[window].backRed = red
	window[window].backGreen = green
	window[window].backBlue = blue
	window[window].backColor = 0
	window[window].backgroundColor = (r << 24) + (g << 16) + (b << 8) + c
'
	sc.scolor = 0
	sc.r = red
	sc.g = green
	sc.b = blue
'
	##WHOMASK = 0
	##LOCKOUT = 100023
	okay = XAllocColor (sdisplay, colormap, &sc)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	scolor = sc.scolor
	window[window].sbackground = scolor
	window[window].sbackgroundDefault = scolor
	IFZ okay THEN PRINT "XgrSetBackgroundRGB() : XAllocColor() failed : "; window, color, scolor, sbackground, sbackgroundDefault
'
	IF (scolor != sbackground) THEN
		##WHOMASK = 0
		##LOCKOUT = 100024
		XSetBackground (sdisplay, gc, scolor)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' ####################################
' #####  XgrSetDefaultColors ()  #####
' ####################################
'
' XgrSetDefaultColors (back, draw, low, high, dull, acc, lowtext, hightext)
'
FUNCTION  XgrSetDefaultColors (back, draw, low, high, dull, acc, lowtext, hightext)
'
	IF (back != -1) THEN #defaultBackground = back
	IF (draw != -1) THEN #defaultDrawing = draw
	IF (low != -1) THEN #defaultLowlight = low
	IF (high != -1) THEN #defaultHighlight = high
	IF (dull != -1) THEN #defaultDull = dull
	IF (acc != -1) THEN #defaultAccent = acc
	IF (lowtext != -1) THEN #defaultLowtext = lowtext
	IF (hightext != -1) THEN #defaultHightext = hightext
END FUNCTION
'
'
' ###################################
' #####  XgrSetDrawingColor ()  #####
' ###################################
'
' error = XgrSetDrawingColor (wingrid, color)
'
' color values range from $$Black = 0 to $$White = 124
'
' See: "xgr.dec" for color constants
'
FUNCTION  XgrSetDrawingColor (grid, color)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  rgb[]
	AUTOX  XColor  sc
'
	IF InvalidWinGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetDrawingColor() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetDrawingColor()lockout", lockout) : lockout = 0
'
	window = grid
	gc = window[window].gc
	display = window[window].display
	sdisplay = window[window].sdisplay
	colormap = display[display].colormap
	sforeground = window[window].sforeground
	sforegroundDefault = window[window].sforegroundDefault
'
' color = 0 means standard color # 0 = $$Black
'
	IFZ color THEN
		window[window].drawRed = 0
		window[window].drawGreen = 0
		window[window].drawBlue = 0
		window[window].drawColor = 0
		window[window].drawingColor = 0
		scolor = display[display].color[0]
		window[window].sforeground = scolor
		window[window].sforegroundDefault = scolor
'
		IF (scolor != sforeground) THEN
			##WHOMASK = 0
			##LOCKOUT = 100025
			XSetForeground (sdisplay, gc, scolor)
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
		RETURN ($$FALSE)
	END IF
'
' standard color # != 0 means color is standard color #
'
	c = color AND 0x000000FF
	IF (c > 124) THEN c = 124
'
	IF c THEN
		rgb = rgb[c]
		window[window].drawColor = c
		window[window].drawRed = (rgb AND 0xFF000000) >> 16
		window[window].drawGreen = (rgb AND 0x00FF0000) >> 8
		window[window].drawBlue = (rgb AND 0x0000FF00)
		window[window].drawingColor = c
		scolor = display[display].color[c]
		window[window].sforeground = scolor
		window[window].sforegroundDefault = scolor
'
		IF (scolor != sforeground) THEN
			##WHOMASK = 0
			##LOCKOUT = 100026
			XSetForeground (sdisplay, gc, scolor)
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
		RETURN ($$FALSE)
	END IF
'
' color is in rgb field of rgbc color argument
'
	red = (color AND 0xFF000000) >> 16
	green = (color AND 0x00FF0000) >> 8
	blue = (color AND 0x0000FF00)
'
	r = red >> 8
	g = green >> 8
	b = blue >> 8
	c = 0
'
	window[window].drawRed = red
	window[window].drawGreen = green
	window[window].drawBlue = blue
	window[window].drawColor = 0
	window[window].drawingColor = (r << 24) + (g << 16) + (b << 8) + c
'
	sc.scolor = 0
	sc.r = red
	sc.g = green
	sc.b = blue
'
	##WHOMASK = 0
	##LOCKOUT = 100027
	okay = XAllocColor (sdisplay, colormap, &sc)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	scolor = sc.scolor
	window[window].sforeground = scolor
	window[window].sforegroundDefault = scolor
	IFZ okay THEN PRINT "XgrSetDrawingColor() : XAllocColor() failed : "; window, color, scolor, sforeground, sforegroundDefault
'
	IF (scolor != sforeground) THEN
		##WHOMASK = 0
		##LOCKOUT = 100028
		XSetForeground (sdisplay, gc, scolor)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' #################################
' #####  XgrSetDrawingRGB ()  #####
' #################################
'
' error = XgrSetDrawingRGB (grid, red, green, blue)
'
' red, green and blue values range from 0 to 65535 (16-bits)
'
FUNCTION  XgrSetDrawingRGB (grid, red, green, blue)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	AUTOX  XColor  sc
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetDrawingRGB() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetDrawingRGB()lockout", lockout) : lockout = 0
'
	window = grid
	gc = window[window].gc
	display = window[window].display
	sdisplay = window[window].sdisplay
	colormap = display[display].colormap
	sforeground = window[window].sforeground
	sforegroundDefault = window[window].sforegroundDefault
'
' color = 0 means standard color # 0 = $$Black
'
	IFZ (red OR green OR blue) THEN
		window[window].drawRed = 0
		window[window].drawGreen = 0
		window[window].drawBlue = 0
		window[window].drawColor = 0
		window[window].drawingColor = 0
		scolor = display[display].color[0]
		window[window].sforeground = scolor
		window[window].sforegroundDefault = scolor
'
		IF (scolor != sforeground) THEN
			##WHOMASK = 0
			##LOCKOUT = 100029
			XSetForeground (sdisplay, gc, scolor)
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
		RETURN ($$FALSE)
	END IF
'
' allocate rgb color
'
	red = red AND 0x0000FFFF
	green = green AND 0x0000FFFF
	blue = blue AND 0x0000FFFF
	r = red >> 8
	g = green >> 8
	b = blue >> 8
	c = 0
'
	window[window].drawRed = red
	window[window].drawGreen = green
	window[window].drawBlue = blue
	window[window].drawColor = 0
	window[window].drawingColor = (r << 24) + (g << 16) + (b << 8) + c
'
	sc.scolor = 0
	sc.r = red
	sc.g = green
	sc.b = blue
'
	##WHOMASK = 0
	##LOCKOUT = 100030
	okay = XAllocColor (sdisplay, colormap, &sc)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	scolor = sc.scolor
	window[window].sforeground = scolor
	window[window].sforegroundDefault = scolor
	IFZ okay THEN PRINT "XgrSetDrawingRGB() : XAllocColor() failed : "; window, color, scolor, sforeground, sforegroundDefault
'
	IF (scolor != sforeground) THEN
		##WHOMASK = 0
		##LOCKOUT = 100031
		XSetForeground (sdisplay, gc, scolor)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' ################################
' #####  XgrSetGridColors()  #####
' ################################
'
' error = XgrSetGridColors (grid, back, draw, low, high, dull, acc, lowtext, hightext)
'
FUNCTION  XgrSetGridColors (grid, back, draw, low, high, dull, acc, lowtext, hightext)
	SHARED  WINDOW  window[]
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridColors() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IF (back != -1) THEN XgrSetBackgroundColor (grid, back)
	IF (draw != -1) THEN XgrSetDrawingColor (grid, draw)
	IF (low != -1) THEN window[window].lowlightColor = low
	IF (high != -1) THEN window[window].highlightColor = high
	IF (dull != -1) THEN window[window].dullColor = dull
	IF (acc != -1) THEN window[window].accentColor = acc
	IF (lowtext != -1) THEN window[window].lowtextColor = lowtext
	IF (hightext != -1) THEN window[window].hightextColor = hightext
END FUNCTION
'
'
' ################################
' #####  XgrCreateWindow ()  #####
' ################################
'
' error = XgrCreateWindow (@window, windowTypeParent, x, y, w, h, &winFunc(), display$)
'
' window - window number created if successful
'
' windowTypeParent - the window types OR'd with the parent window number
' parent == 0  :  create "top level window" (framed by window manager)
' parent != 0  :  create "pop-up window" (frameless top level window)
'
' &winFunc() - address of the function to be called to process window messages
'
' display$ - a blank string "" for the default display
'
' See: XgrCreateGrid()
'
FUNCTION  XgrCreateWindow (window, windowTypeParent, x, y, w, h, winFunc, display$)
	SHARED  r[]
	SHARED  g[]
	SHARED  b[]
	SHARED  window$[]
	SHARED  sfontDefault
	SHARED  WINDOW	window[]
	SHARED  DISPLAY  display[]
	STATIC  WINDOW  defaultWindow
	STATIC  entry
	XWindowAttributes  attributes
	XSetWindowAttributes  setAttributes
	XSizeHints	sizeHints
	XSizeHints	normalSizeHints, userSizeHints                  '+++
	XGCValues  gcvalues
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrCreateWindow()lockout", lockout) : lockout = 0
'
	IFZ entry THEN GOSUB Initialize						' default window properties
'
'	PRINT "XgrCreateWindow(44)", x, y, w, h
	XgrPlaceWindow (windowTypeParent, @x, @y, @w, @h)
'	PRINT "XgrCreateWindow(46)", x, y, w, h
'
	window = 0
	parent = windowTypeParent AND 0x0000FFFF
	windowType = windowTypeParent AND 0xFFFF0000
'
	IFZ windowType THEN
		windowType = $$WindowTypeNormal
'		windowTypeParent = windowType OR parent
	END IF
	IF (windowType AND $$WindowTypeNoSelect) THEN
		windowType = windowType OR $$WindowTypeNoFrame
	END IF
	IF (windowType AND $$WindowTypeNoFrame) THEN
		windowType = windowType OR $$WindowTypeTopMost OR  $$WindowTypeNoIcon
	END IF
	windowTypeParent = windowType OR parent
'
	error = Display (@display, $$Open, @display$)			' no error if already open
'
	IF error THEN
		PRINT "XgrCreateWindow() Invalid display : \""; display$; "\" : reset to default"
		display = 1 : display$ = ""
	END IF
'
	XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
	windowBorderWidth = display[display].borderWidth
	windowTitleHeight = display[display].titleHeight
	wmXoffset = display[display].wmXoffset
	wmYoffset = display[display].wmYoffset
	IFZ windowBorderWidth THEN windowBorderWidth = 10
	IFZ windowTitleHeight THEN windowTitleHeight = 23
	IF (windowBorderWidth > 10) THEN windowBorderWidth = 10
	IF (windowTitleHeight > 40) THEN windowTitleHeight = 23
	IF (wmXoffset >= 10) THEN wmXoffset = 0
	IF (wmYoffset >= 10) THEN wmYoffset = 0
	IFZ wmXoffset THEN
		IF (windowBorderWidth >= 10) THEN
			wmXoffset = 1
		ELSE
			wmXoffset = windowBorderWidth
		END IF
	END IF
	IFZ wmYoffset THEN
		IF (windowBorderWidth >= 10) THEN
			wmYoffset = 1
		ELSE
			wmYoffset = windowBorderWidth
		END IF
	END IF
	display[i].wmXoffset = wmXoffset
	display[i].wmYoffset = wmYoffset
'
	IF (w <= 7) THEN w = workAreaWidth >> 2
	IF (h <= 7) THEN h = workAreaHeight >> 2
'
	IF (w < $$WindowMinimumWidth)  THEN w = $$WindowMinimumWidth
	IF (h < $$WindowMinimumHeight) THEN h = $$WindowMinimumHeight
'
' set up info and attributes of window, including event types to receive
'
	root = display[display].root
	sroot = display[display].sroot
	class = display[display].class
	depth = display[display].depth
	sblack = display[display].black
	swhite = display[display].white
	visual = display[display].visual
	screen = display[display].screen
	sparent = display[display].sroot
	sdisplay = display[display].sdisplay
'
' Most programs that call XgrCreateWindow do not handle a fail return properly.
' So print a message to indicate a problem and set the parent to zero and carry on.
'
	IF parent THEN
		IF InvalidWinGrid (parent) THEN
			PRINT "XgrCreateWindow():error:bad parent:"; parent; " (reset parent to zero)"
			parent = 0
		END IF
	END IF
'
	mask = 0
	valuemask = 0
	mask = mask OR $$KeyPressMask
	mask = mask OR $$KeyReleaseMask
	mask = mask OR $$ButtonPressMask
	mask = mask OR $$ButtonReleaseMask
	mask = mask OR $$EnterWindowMask
	mask = mask OR $$LeaveWindowMask
	mask = mask OR $$ButtonMotionMask
	mask = mask OR $$ExposureMask
	mask = mask OR $$VisibilityChangeMask
	mask = mask OR $$StructureNotifyMask
	mask = mask OR $$FocusChangeMask
	setAttributes.eventMask = mask
	valuemask = $$CWEventMask
'
' popup windows want no frame and no window manager placement changes
'
'	IF (parent OR (windowType AND $$WindowTypeNoFrame)) THEN
	IF (parent OR (windowType AND $$WindowTypeNoFrame) OR (windowType AND $$WindowTypeNoSelect)) THEN
		valuemask = valuemask | $$CWOverrideRedirect
		setAttributes.overrideRedirect = 1
		valuemask = valuemask | $$CWSaveUnder
		setAttributes.saveUnder = 1
'		IF ##CAPSLOCK THEN PRINT "XgrCreateWindow", HEXX$(valuemask)
	END IF
'
' create the window
'
	IF (windowType AND $$WindowTypeNoFrame) THEN
		xx = x
		yy = y
	ELSE
		xx = x - wmXoffset
		yy = y - windowTitleHeight- wmYoffset
	END IF
'
'	IF whomask THEN PRINT "XgrCreateWindow(167)", x, y, xx, yy, w, h, wmXoffset, wmYoffset
	##WHOMASK = 0
	##LOCKOUT = 100032
	swindow = XCreateWindow (sdisplay, sparent, xx, yy, w, h, 0, depth, $$InputOutput, visual, valuemask, &setAttributes)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ swindow THEN
		##ERROR = ($$ErrorObjectSystemRoutine << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrCreateWindow() : error : XCreateWindow() failed"
		RETURN ($$TRUE)
	END IF
'
' success - assign a native window number
'
	GetNewWindowNumber (@window)
'	PRINT "XgrCreateWindow(184) window, swindow :", window, HEXX$(swindow)
'
' set window manager hints for top level windows (window broken otherwise)
'
	IFZ parent THEN
		sizeHints.flags = 0x007C
'		sizeHints.x = x           'obsolete
'		sizeHints.y = y           'obsolete
'		sizeHints.width = w       'obsolete
'		sizeHints.height = h      'obsolete
'
' maxWidth and maxHeight must be 0xFFFF for the Maximize buttton to work
' On  KDE  there is no Maximize buttton if the values are not 0xFFFF
' On Gnome there is no Maximize buttton if the value is 0xFFFFFFFF
' When minimums equal maximums there is no Maximize buttton
'
' If there is a frame but not a resize frame, make min and max equal
'
		IFZ (windowType AND ($$WindowTypeNoFrame OR $$WindowTypeResizeFrame)) THEN
			sizeHints.minWidth = w
			sizeHints.minHeight = h
			sizeHints.maxWidth = w
			sizeHints.maxHeight = h
		ELSE
			sizeHints.minWidth = $$WindowMinimumWidth
			sizeHints.minHeight = $$WindowMinimumHeight
			sizeHints.maxWidth = 0xFFFF
			sizeHints.maxHeight = 0xFFFF
		END IF
'
' if inc = 0 then KDE crashes when a window is maximized
'
		sizeHints.widthInc = 1
		sizeHints.heightInc = 1

		##WHOMASK = 0
		##LOCKOUT = 100033
		XSetWMNormalHints (sdisplay, swindow, &sizeHints)
'
'		DIM class$[1]
'		class$[0] = "XBasic"
'		class$[1] = "XBasic"
'		XSetClassHint (sdisplay, swindow, &class$[])
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
' prevent close button from killing the application or top-level window
'
	IF #XA_WM_DELETE_WINDOW THEN
		##WHOMASK = 0
		##LOCKOUT = 100034
		XSetWMProtocols (sdisplay, swindow, &#XA_WM_DELETE_WINDOW, 1)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
' create font and gc (graphics context)
'
	##WHOMASK = 0
	IFZ sfontDefault THEN Font (@font, $$Create, display, @sfontDefault, @addrFont, 0, 0, 0, 0, "")
	GraphicsContext (@gc, $$Create, sdisplay, screen, swindow, sfontDefault)
	##WHOMASK = whomask
'
	##WHOMASK = 0
	window$[window] = ""											' default window name/title
	##WHOMASK = whomask
	window[window] = defaultWindow						' default window properties
'
	window[window].window = window            ' native window #
	window[window].type = windowType          ' native windowType
	window[window].leader = parent            ' native leader window #
	window[window].top = window               ' native top level window #
	window[window].display = display					' native display #
	window[window].winFunc = winFunc					' window function
	window[window].font = font                ' native font # (default)
'
	window[window].backgroundColor = #defaultBackground
	window[window].drawingColor = #defaultDrawing
	window[window].lowlightColor = #defaultLowlight
	window[window].highlightColor = #defaultHighlight
	window[window].dullColor = #defaultDull
	window[window].accentColor = #defaultAccent
	window[window].lowtextColor = #defaultLowtext
	window[window].hightextColor = #defaultHightext
'
	XgrConvertColorToRGB (#defaultBackground, @br, @bg, @bb)
	XgrConvertColorToRGB (#defaultDrawing, @dr, @dg, @db)
	window[window].backColor = #defaultBackground
	window[window].backBlue = bb
	window[window].backGreen = bg
	window[window].backRed = br
	window[window].drawColor = #defaultDrawing
	window[window].drawBlue = db
	window[window].drawGreen = dg
	window[window].drawRed = dr
	window[window].whomask = whomask					         ' owner whomask
'
	window[window].x = x											         ' requested
	window[window].y = y											         ' requested
	window[window].width = w									         ' requested
	window[window].height = h									         ' requested
	window[window].borderWidth = windowBorderWidth
	window[window].titleHeight = windowTitleHeight
	window[window].wmXoffset = wmXoffset
	window[window].wmYoffset = wmYoffset
'
	IF (windowType AND $$WindowTypeResizeFrame) THEN
		window[window].minWidth = $$WindowMinimumWidth
		window[window].minHeight = $$WindowMinimumHeight
		window[window].maxWidth = 0xFFFF
		window[window].maxHeight = 0xFFFF
	ELSE
		window[window].minWidth = w
		window[window].minHeight = h
		window[window].maxWidth = w
		window[window].maxHeight = h
	END IF
'
	window[window].gridBoxX1 = 0							   ' default origin = 0,0
	window[window].gridBoxY1 = 0							   ' default origin = 0,0
	window[window].gridBoxX2 = w - 1             ' from requested width
	window[window].gridBoxY2 = h - 1             ' from requested height
	window[window].gridBoxScaledX1 = 0#
	window[window].gridBoxScaledY1 = 0#
	window[window].gridBoxScaledX2 = DOUBLE(w-1)
	window[window].gridBoxScaledY2 = DOUBLE(h-1)
	window[window].xPixelsPerScaled = 1#
	window[window].yPixelsPerScaled = 1#
	window[window].xScaledPerPixel = 1#
	window[window].yScaledPerPixel = 1#
'
	window[window].gc = gc										' system gc #
	window[window].sroot = sroot							' system root #
	window[window].stop = swindow							' system window #
	window[window].visual = visual						' system visual
	window[window].swindow = swindow					' system window #
	SetSwindowXref (swindow, window)          ' set system window to window cross-reference
	window[window].sparent = sparent					' system parent #
	window[window].sdisplay = sdisplay				' system display #
	window[window].eventMask = mask           ' XSelectInput() event mask
	window[window].visibilityRequest = -1     ' never requested
'
	XgrSetDrawingColor (window, #defaultDrawing)
'
	RETURN ($$FALSE)
'
'
' *****  Initialize  *****
'
SUB Initialize
	defaultWindow.kind = $$KindWindow
	defaultWindow.backgroundColor = #defaultBackground
	defaultWindow.drawingColor = #defaultDrawing
	defaultWindow.lowlightColor = #defaultLowlight
	defaultWindow.highlightColor = #defaultHighlight
	defaultWindow.dullColor = #defaultDull
	defaultWindow.accentColor = #defaultAccent
	defaultWindow.lowtextColor = #defaultLowtext
	defaultWindow.hightextColor = #defaultHightext
	defaultWindow.backColor = #defaultBackground
	defaultWindow.backBlue = b[3]
	defaultWindow.backGreen = g[3]
	defaultWindow.backRed = r[3]
	defaultWindow.drawColor = #defaultDrawing
	defaultWindow.x = 0
	defaultWindow.y = 0
	defaultWindow.width = 0
	defaultWindow.height = 0
	defaultWindow.minWidth = $$WindowMinimumWidth
	defaultWindow.minHeight = $$WindowMinimumHeight
	defaultWindow.maxWidth = 0xFFFF
	defaultWindow.maxHeight = 0xFFFF
	defaultWindow.gridBoxX1 = 0
	defaultWindow.gridBoxY1 = 0
	defaultWindow.gridBoxX2 = 3
	defaultWindow.gridBoxY2 = 3
	defaultWindow.gridBoxScaledX1 = 0#
	defaultWindow.gridBoxScaledY1 = 0#
	defaultWindow.gridBoxScaledX2 = 3#
	defaultWindow.gridBoxScaledY2 = 3#
	defaultWindow.xScaledPerPixel = 1#
	defaultWindow.yScaledPerPixel = 1#
	defaultWindow.xPixelsPerScaled = 1#
	defaultWindow.yPixelsPerScaled = 1#
'
	defaultWindow.sbackground = -1				' default background scolor = none
	defaultWindow.sforeground = -1				' default foreground scolor = none
	defaultWindow.sbackgroundDefault = -1 ' default background scolor = none
	defaultWindow.sforegroundDefault = -1 ' default foreground scolor = none
	defaultWindow.state = $$TRUE          ' window enable
	defaultWindow.visibility = $$WindowHidden
	defaultWindow.priorVisibility = -1    ' window never visible
	defaultWindow.visibilityRequest = -1  ' never requested
	entry = $$TRUE
END SUB
END FUNCTION
'
'
' #################################
' #####  XgrDestroyWindow ()  #####
' #################################
'
' error = XgrDestroyWindow (window)
'
FUNCTION  XgrDestroyWindow (window)
	SHARED  charMap[]
	SHARED  modalWindowUser
	SHARED  modalWindowSystem
	SHARED  WINDOW  window[]
	STATIC	WINDOW  zipwin
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDestroyWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrDestroyWindow() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	IF (window = modalWindowSystem) THEN XgrSetModalWindow (0)
	IF (window = modalWindowUser) THEN XgrSetModalWindow (0)
'
	gc = window[window].gc
	top = window[window].top
	stop = window[window].stop
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	processed = window[window].destroyProcessed
	destroyed = window[window].destroyed
	destroy = window[window].destroy
	timer = window[window].timer
	func = window[window].winFunc
'
	IF (window != top) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "XgrDestroyWindow() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	IF (processed OR destroyed OR destroy) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrDestroyWindow() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	IFZ swindow THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrDestroyWindow() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
' destroy in progress - destroy miscellaneous window resources
'
	func = window[window].winFunc				' get window function
	window[window].state = $$FALSE			' disable output to window
	window[window].destroy = $$TRUE			' destroy already started
	IF timer THEN XxxXstTimer ($$TimerKill, window, timer, 0, 0, 0)
'
' If ##BLOWBACK in progress, XxxXuiBlowback() will clear all GUI
' window information, so sending #WindowDestroyed is not needed.
'
	IFZ ##BLOWBACK THEN
		IF func THEN @func (window, #WindowDestroyed, func, 0, 0, 0, 0, 0)
	END IF
'
' flush events and message that might be headed for the destroyed window
'
	##WHOMASK = 0
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask
'
	IF ##BLOWBACK THEN XgrProcessMessages (-2)
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' destroy all top-level windows that are kids of this window
'
	FOR kid = UBOUND (window[]) TO 1 STEP -1      ' destroy kids in reverse order
		IF window[kid].window THEN									' kid is active
			IFZ window[kid].destroy THEN							' not in destroy
				IFZ window[kid].destroyed THEN					' not destroyed
					IF (window = window[kid].leader) THEN	' window is kids parent
						IF (kid != window) THEN							' kid != window
							XgrDestroyWindow (kid)						' destroy kid window
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT kid
'
' flush events and message that might be headed for the destroyed window
'
	##WHOMASK = 0
	DispatchEvents ($$TRUE, $$FALSE)

	##WHOMASK = whomask
'
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' destroy all parentless grids in this window
' these "top-level grids" will recursively destroy all kid grids
'
	FOR grid = 1 TO UBOUND (window[])
		IF window[grid].window THEN                                         ' grid is active
			IF ((window[grid].parent == 0) || (window[grid].type == 1)) THEN	' parentless or pixmap grid
				IFZ window[grid].destroy THEN                                   ' not in destroy
					IFZ window[grid].destroyed THEN                               ' not destroyed
						IF (window = window[grid].top) THEN                         ' grid is in window
							IF (grid != window) THEN                                  ' grid is not the window
								err = XgrDestroyGrid (grid)                             ' destroy this grid
								IF err THEN PRINT "XgrDestroyWindow(123)", grid, window
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT grid
'
' flush events and message that might be headed for the destroyed grids
'
	##WHOMASK = 0
	DispatchEvents ($$TRUE, $$FALSE)

	##WHOMASK = whomask
'
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' hide the window, force events to generate messages
'
	##WHOMASK = 0
	##LOCKOUT = 100035
	XUnmapWindow (sdisplay, swindow)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	DispatchEvents ($$TRUE, $$FALSE)
'
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' Destroy the window and graphics context, force events and messages
'
	##WHOMASK = 0
	##LOCKOUT = 100036
	XFreeGC (sdisplay, gc)
	window[window].gc = 0
	window[window].destroy = $$TRUE
	XDestroyWindow (sdisplay, swindow)  ' EventDestroyNotify() marks window available
	##LOCKOUT = lockout
	##WHOMASK = whomask
	DispatchEvents ($$TRUE, $$FALSE)
'
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' Check that EventDestroyNotify() did its job
'
	disaster = 0
	IF window[window].window            THEN disaster = disaster OR 0x10000
	IF window[window].swindow           THEN disaster = disaster OR 0x02000
	IFZ window[window].destroy          THEN disaster = disaster OR 0x00300
	IFZ window[window].destroyed        THEN disaster = disaster OR 0x00040
	IFZ window[window].destroyProcessed THEN disaster = disaster OR 0x00005
'
	IF disaster THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureExists
		IF ##XBDV THEN PRINT "XgrDestroyWindow() : window not destroyed : window #", window, HEXX$(disaster, 5)
		RETURN ($$TRUE)
	END IF
'
	ATTACH charMap[window,] TO temp[] : DIM temp[]							' free char map array
	window[window].kind = 0																			' not a window nor grid
	window[window].visibilityRequest = -1												' mark window available
END FUNCTION
'
'
' #################################
' #####  XgrDisplayWindow ()  #####
' #################################
'
' error = XgrDisplayWindow (window)
'
'  Make a window visible and active
'
' See: XgrShowWindow(), XgrHideWindow()
'
FUNCTION  XgrDisplayWindow (window)
	SHARED  WINDOW  window[]
	SHARED  focusWhenMapped
	STATIC  XClientMessageEvent sendEvent
	STATIC  lastWindow
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDisplayWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrDisplayWindow() : error : invalid window #"; window
		RETURN (-1)
	END IF
'
	top = window[window].top
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	IF (window != top) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "XgrDisplayWindow() : error : window is not a top level window #"; window
		RETURN ($$TRUE)
	END IF
'
' If visibilityRequest in progress wait up to 5 seconds to finish
'
	XstGetSystemTime (@start)
	DO
		visibilityRequest = window[window].visibilityRequest
		IF (visibilityRequest == -1) THEN EXIT DO
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		DispatchEvents ($$FALSE, $$TRUE)
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
'
	IF (visibilityRequest <> -1) THEN
'		IF window[window].destroy THEN RETURN
		PRINT "XgrDisplayWindow()visibilityRequest =", visibilityRequest, window
	END IF
'
' map window and all its kid grids
'
	visibility = window[window].visibility
	IF (visibility = $$WindowHidden) THEN
		'
		' Windows with a frame and windowType $$WindowTypeTopMost
		' should be displayed above all other windows. The _NET_WM_STATE_ABOVE
		' atom is removed each time a window is unmapped and
		' needs to be put back in each time the window is mapped.
		' Windows with $$WindowTypeNoFrame are handle with the "overrideRedirect" attribute
		'
		windowType = window[window].type
		IFZ (windowType AND $$WindowTypeNoFrame) THEN
			IF (windowType AND $$WindowTypeTopMost) THEN
				DIM stateData[0]
				stateData[0] = #XA_NET_WM_STATE_ABOVE
				XgrChangeProperty (window, #XA_NET_WM_STATE, #XA_ATOM, $$PropModeReplace, @stateData[])
			END IF
		END IF
'
		IF (visibility != $$WindowDisplayed) THEN
			window[window].visibilityRequest = $$WindowDisplayed
		END IF
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100037
	XMapRaised (sdisplay, swindow)
	IF (visibility = $$WindowDisplayed) THEN
		XSetInputFocus (sdisplay, swindow, $$RevertToParent, 0)
	ELSE
		focusWhenMapped = window
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
'	IF ##XBDV THEN PRINT "XgrDisplayWindow(93)", window, focusWhenMapped
'
END FUNCTION
'
'
' ####################################
' #####  XgrFullscreenWindow ()  #####
' ####################################
'
' error = XgrFullscreenWindow (wingrid)
'
FUNCTION  XgrFullscreenWindow (window)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	XClientMessageEvent event
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrFullscreenWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrFullscreenWindow() : error : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	window = window[window].top
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrFullscreenWindow() : error : invalid window #"; window,
		RETURN ($$TRUE)
	END IF
'
	display = window[window].display
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	visibility = window[window].visibility
'
	windowType = window[window].type
	IF (windowType AND $$WindowTypeNoFrame) THEN RETURN
'
' XClientMessageEvent
'
	event.type        = $$ClientMessage
	event.serial      = 0     ' # of last request processed by server
	event.sendEvent   = 0     ' true if this came from SendEvent request
	event.display     = display
	event.window      = swindow
	event.messageType = #XA_NET_WM_STATE
	event.format      = 32
	event.data[0]     = $$NET_WM_STATE_ADD
	event.data[1]     = #XA_NET_WM_STATE_FULLSCREEN
	event.data[2]     = 0
	event.data[3]     = 0
	event.data[4]     = 0
'
	rc = XxxXgrSendEvent (0, 0, $$StructureNotifyMask, &event)
'	IF ##XBDV THEN PRINT "XgrFullscreenWindow(63) testing: "; rc, window
'
END FUNCTION
'
'
' ##################################
' #####  XgrGetModalWindow ()  #####
' ##################################
'
' XgrGetModalWindow (@window)
'
FUNCTION  XgrGetModalWindow (window)
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
'
	IF ##WHOMASK THEN
		window = modalWindowUser
	ELSE
		window = modalWindowSystem
	END IF
'	PRINT "XgrGetModalWindow() : "; window
END FUNCTION
'
'
' ####################################
' #####  XgrGetWindowDisplay ()  #####
' ####################################
'
' error = XgrGetWindowDisplay (window, @display$)
'
FUNCTION  XgrGetWindowDisplay (window, display$)
	SHARED  WINDOW  window[]
	SHARED  display$[]
'
	display$ = ""
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowFunction() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (display$[])
	display = window[window].display
	IF (display <= upper) THEN display$ = display$[display]
END FUNCTION
'
'
' #####################################
' #####  XgrGetWindowFunction ()  #####
' #####################################
'
' error = XgrGetWindowFunction (window, @func)
'
FUNCTION  XgrGetWindowFunction (window, func)
	SHARED  WINDOW  window[]
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowFunction() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	func = window[window].winFunc
END FUNCTION
'
'
' #################################
' #####  XgrGetWindowIcon ()  #####
' #################################
'
' error = XgrGetWindowIcon (window, @icon)
'
' See:  XgrIconNameToNumber(), XgrIconNumberToName(), XgrSetWindowIcon()
'
FUNCTION  XgrGetWindowIcon (window, icon)
	SHARED  WINDOW  window[]
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowIcon() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	icon = window[window].icon
END FUNCTION
'
'
' #################################
' #####  XgrGetWindowGrid ()  #####
' #################################
'
' error = XgrGetWindowGrid (window, @grid)
'
' See: XgrGetGridWindow()
'
FUNCTION  XgrGetWindowGrid (window, grid)
	SHARED  WINDOW  window[]
'
	grid = 0
	IF InvalidWindow (window) THEN RETURN $$TRUE
'
' Normally the WindowGrid is number immediately above the window number,
' so start searching at window plus one to minimize search time
'
	FOR g = window + 1 TO UBOUND (window[])
		IF window[g].window THEN									' grid is active
			IF (window == window[g].parent) THEN		' if window is parent of g
				grid = g															' found window grid
				RETURN
			END IF
		END IF
	NEXT g
'
	FOR g = 1 TO UBOUND (window[])
		IF window[g].window THEN									' grid is active
			IF (window == window[g].parent) THEN		' if window is parent of g
				grid = g															' found window grid
				EXIT FOR
			END IF
		END IF
	NEXT g
END FUNCTION
'
'
' ############################################
' #####  XgrGetWindowPositionAndSize ()  #####
' ############################################
'
' error = XgrGetWindowPositionAndSize (window, @x, @y, @width, @height)
'
FUNCTION  XgrGetWindowPositionAndSize (window, x, y, width, height)
	SHARED  WINDOW  window[]
	AUTOX  XWindowAttributes  windowAttributes
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowPositionAndSize() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
' If configureRequest or visibilityRequest in progress wait up to 5 seconds to finish
'
	XstGetSystemTime (@start)
	DO
		configureRequest  = window[window].configureRequest
		visibilityRequest = window[window].visibilityRequest
		IF ((configureRequest != -1) && (visibilityRequest == -1)) THEN EXIT DO
		DispatchEvents ($$TRUE, $$TRUE)
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
	IF window[window].destroy THEN RETURN
	IF (configureRequest = -1)   THEN PRINT "XgrGetWindowPositionAndSize()configureRequest  =", configureRequest,  window
	IF (visibilityRequest <> -1) THEN PRINT "XgrGetWindowPositionAndSize()visibilityRequest =", visibilityRequest, window
'
	x = window[window].x
	y = window[window].y
	width = window[window].width
	height = window[window].height
	IFZ (width || height) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowPositionAndSize() : Invalid width or height", width, height
	END IF
END FUNCTION
'
'
' ##################################
' #####  XgrGetWindowState ()  #####
' ##################################
'
' error = XgrGetWindowState (window, @state)
'
' error = TRUE if the window number is invalid or is destroyed
'
' NOTE: If the window is in the process of changing state, such as from hidden to visible,
'       this function waits for up to 5 seconds for it to stablize before returning.
'
FUNCTION  XgrGetWindowState (window, state)
	SHARED  WINDOW  window[]
'
	state = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowState() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
' If visibilityRequest in progress wait up to 5 seconds to finish
'
	top = window[window].top
	XstGetSystemTime (@start)
	DO
		visibilityRequest = window[window].visibilityRequest
		IF (visibilityRequest == -1) THEN EXIT DO
		DispatchEvents ($$TRUE, $$TRUE)
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
	IF (visibilityRequest <> -1) THEN
		IF window[window].destroy THEN RETURN ($$TRUE)
		XgrGetWindowTitle (top, @title$)
		PRINT "XgrGetWindowState()visibilityRequest =", visibilityRequest, top, title$
	END IF
'
	state = window[top].visibility
END FUNCTION
'
'
' ##################################
' #####  XgrGetWindowTitle ()  #####
' ##################################
'
' error = XgrGetWindowTitle (window, @title$)
'
FUNCTION  XgrGetWindowTitle (window, title$)
	SHARED  WINDOW  window[]
	XTextProperty  text
	AUTOX  name
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetWindowTitle()lockout", lockout) : lockout = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowTitle() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	sdisplay = window[window].sdisplay
	swindow = window[window].swindow
'
	status = $$FALSE
	title$ = NULL$ (255)
	text.value = &title$
	text.encoding = #XA_WM_NAME
	text.format = 8
	text.nItems = LEN (title$)
'
	##WHOMASK = 0
	##LOCKOUT = 100038
'	XGetTextProperty (sdisplay, swindow, &text, #XA_WM_NAME)
	status = XFetchName (sdisplay, swindow, &name)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	PRINT "text.value    = "; HEX$ (text.value)
'	PRINT "text.encoding = "; HEX$ (text.encoding)
'	PRINT "text.format   = "; HEX$ (text.format)
'	PRINT "text.nItems   = "; HEX$ (text.nItems)
'
	IF status THEN
'		title$ = CSTRING$ (text.value)
		title$ = CSTRING$ (name)
		XFree (name)
	ELSE
		title$ = "NONE"
	END IF
'
END FUNCTION
'
'
' #######################################
' #####  XgrGetWindowVisibility ()  #####
' #######################################
'
' error = XgrGetWindowVisibility (window, @visibility)
'
FUNCTION  XgrGetWindowVisibility (window, visibility)
	SHARED  WINDOW  window[]
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowVisibility() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
' If visibilityRequest in progress wait up to 5 seconds to finish
'
	top = window[window].top
	XstGetSystemTime (@start)
	DO
		visibilityRequest = window[window].visibilityRequest
		IF (visibilityRequest == -1) THEN EXIT DO
		DispatchEvents ($$TRUE, $$TRUE)
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
	IF (visibilityRequest <> -1) THEN
		IF window[window].destroy THEN RETURN
		XgrGetWindowTitle (top, @title$)
		PRINT "XgrGetWindowVisibility()visibilityRequest =", visibilityRequest, top, title$
	END IF
'
	visibility = window[top].visibility
END FUNCTION
'
'
' ##############################
' #####  XgrHideWindow ()  #####
' ##############################
'
' error = XgrHideWindow (wingrid)
'
' See: XgrDisplayWindow(), XgrShowWindow()
'
FUNCTION  XgrHideWindow (window)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrHideWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrHideWindow() : error : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	window = window[window].top
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrHideWindow() : error : bad top level window #"; window
		RETURN ($$TRUE)
	END IF
'
	parent = window[window].parent
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' If visibilityRequest in progress wait up to 5 seconds to finish
'
	XstGetSystemTime (@start)
	DO
		visibilityRequest = window[window].visibilityRequest
		IF (visibilityRequest == -1) THEN EXIT DO
		DispatchEvents ($$TRUE, $$TRUE)
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
	IF (visibilityRequest <> -1) THEN
		XgrGetWindowTitle (window, @title$)
		PRINT "XgrHideWindow()visibilityRequest =", visibilityRequest, window, title$
	END IF
'
	##WHOMASK = 0
'
	visibility = window[window].visibility
	IF (visibility <> $$WindowHidden) THEN
		window[window].visibilityRequest = $$WindowHidden
	END IF
'
	##LOCKOUT = 100039
	XUnmapWindow (sdisplay, swindow)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ##################################
' #####  XgrMaximizeWindow ()  #####
' ##################################
'
' error = XgrMaximizeWindow (wingrid)
'
' See: MaximizeWindow
'
FUNCTION  XgrMaximizeWindow (window)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	XClientMessageEvent event
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrMaximizeWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrMaximizeWindow() : error : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	window = window[window].top
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrMaximizeWindow() : error : invalid window #"; window,
		RETURN ($$TRUE)
	END IF
'
	display = window[window].display
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	visibility = window[window].visibility
'
	windowType = window[window].type
	IF (windowType AND $$WindowTypeNoFrame) THEN RETURN
'
' XClientMessageEvent
'
	event.type        = $$ClientMessage
	event.serial      = 0     ' # of last request processed by server
	event.sendEvent   = 0     ' true if this came from SendEvent request
	event.display     = display
	event.window      = swindow
	event.messageType = #XA_NET_WM_STATE
	event.format      = 32
	event.data[0]     = $$NET_WM_STATE_ADD
	event.data[1]     = #XA_NET_WM_STATE_MAXIMIZED_HORZ
	event.data[2]     = #XA_NET_WM_STATE_MAXIMIZED_VERT
	event.data[3]     = 0
	event.data[4]     = 0
'
	rc = XxxXgrSendEvent (0, 0, $$StructureNotifyMask, &event)
'	IF ##XBDV THEN PRINT "XgrMaximizeWindow(43) testing: "; rc, window, $$NET_WM_STATE_ADD
'
END FUNCTION
'
'
' ##################################
' #####  XgrMinimizeWindow ()  #####
' ##################################
'
' error = XgrMinimizeWindow (wingrid)
'
' See: MinimizeWindow
'
FUNCTION  XgrMinimizeWindow (window)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrMinimizeWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrMinimizeWindow() : error : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	top = window[window].top
'
	IF (window != top) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "XgrMinimizeWindow() : error : window not a top-level window #"; window
		RETURN ($$TRUE)
	END IF
'
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	visibility = window[window].visibility
	window[window].visibilityRequest = $$WindowMinimized
	screen = display[display].screen
'
	##WHOMASK = 0
	##LOCKOUT = 100040
	XIconifyWindow (sdisplay, swindow, screen)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask
END FUNCTION
'
'
' ###############################
' #####  XgrPlaceWindow ()  #####
' ###############################
'
' altered = XgrPlaceWindow (windowType, @xDisp, @yDisp, @width, @height)
'
' Check that a window with supplied dimensions will fit within the
' work-area and alter the values, if needed, to make it fit.
'
' altered = $$TRUE if the values returned have been altered
'
FUNCTION  XgrPlaceWindow (windowType, xDisp, yDisp, width, height)
'
	XgrGetDisplaySize ("", @dispWidth, @dispHeight, @borderWidth, @titleHeight)
	XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
	XgrGetDisplayOffset (display$, @xOffset, @yOffset, 0, 0)
'
	IF (windowType AND $$WindowTypeNoFrame)THEN
		IF (xDisp < workAreaX) THEN xDisp = workAreaX : altered = $$TRUE
		IF (workAreaWidth < (xDisp + width)) THEN
			altered = $$TRUE
			xDisp = workAreaWidth - width
			IF (xDisp < workAreaX) THEN
				xDisp = workAreaX
				width = workAreaWidth
			END IF
		END IF
		'
		IF (yDisp < workAreaY) THEN yDisp = workAreaY : altered = $$TRUE
		IF (workAreaHeight < (yDisp + height)) THEN
			altered = $$TRUE
			yDisp = workAreaHeight - height
			IF (yDisp < workAreaY) THEN
				yDisp = workAreaY
				height = workAreaHeight
			END IF
		END IF
		'
	ELSE
		IF (xDisp < (xOffset + workAreaX)) THEN
			xDisp = xOffset + workAreaX
			altered = $$TRUE
		END IF
		IF (yDisp < (yOffset + titleHeight +workAreaY)) THEN
			yDisp = yOffset + titleHeight + workAreaY
			altered = $$TRUE
		END IF
		'
		IF ((workAreaWidth + workAreaX) < (xDisp + width + xOffset)) THEN
			altered = $$TRUE
			xDisp = workAreaWidth - xOffset - width
			IF (xDisp < (xOffset + workAreaX)) THEN
				xDisp = xOffset + workAreaX
				width = workAreaWidth - xOffset - xOffset
			END IF
		END IF
		IF ((workAreaHeight + workAreaY) < (yDisp + height + xOffset)) THEN
			altered = $$TRUE
			yDisp = workAreaY + workAreaHeight - xOffset - height
			IF (yDisp < (yOffset + titleHeight + workAreaY)) THEN
				yDisp = yOffset + titleHeight + workAreaY
				height = workAreaHeight - titleHeight - xOffset - yOffset
			END IF
		END IF
	END IF
'
	RETURN (altered)

END FUNCTION
'
'
' #################################
' #####  XgrRestoreWindow ()  #####
' #################################
'
' error = XgrRestoreWindow (wingrid)
'
' See: RestoreWindow
'
FUNCTION  XgrRestoreWindow (window)
	SHARED  WINDOW  window[]
	XClientMessageEvent event
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrRestoreWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrRestoreWindow() : error : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	windowType = window[window].type
	IF (windowType AND $$WindowTypeNoFrame) THEN RETURN
'
	display = window[window].display
	swindow = window[window].swindow
'	sdisplay = window[window].sdisplay
'
' XClientMessageEvent
'
	event.type        = $$ClientMessage
	event.serial      = 0     ' # of last request processed by server
	event.sendEvent   = 0     ' true if this came from SendEvent request
	event.display     = display
	event.window      = swindow
	event.messageType = #XA_NET_WM_STATE
	event.format      = 32
	event.data[0]     = $$NET_WM_STATE_REMOVE
	event.data[1]     = #XA_NET_WM_STATE_MAXIMIZED_HORZ
	event.data[2]     = #XA_NET_WM_STATE_MAXIMIZED_VERT
	event.data[3]     = 0
	event.data[4]     = 0
'
	rc = XxxXgrSendEvent (0, 0, $$StructureNotifyMask, &event)
'	IF ##XBDV THEN PRINT "XgrRestoreWindow(a) testing: "; rc, window, #XA_NET_WM_STATE_MAXIMIZED_VERT
'
	event.data[0]     = $$NET_WM_STATE_REMOVE
	event.data[1]     = #XA_NET_WM_STATE_FULLSCREEN
	event.data[2]     = 0
	event.data[3]     = 0
	event.data[4]     = 0
'
	rc = XxxXgrSendEvent (0, 0, $$StructureNotifyMask, &event)
'	IF ##XBDV THEN PRINT "XgrRestoreWindow(b) testing: "; rc, window, #XA_NET_WM_STATE_FULLSCREEN
'
	XgrDisplayWindow (window)    ' restore if minimized
'
END FUNCTION
'
'
' ##################################
' #####  XgrSetModalWindow ()  #####
' ##################################
'
' error = XgrSetModalWindow (window)
'
' replace current modal window with new modal window or zero (none)
'
FUNCTION  XgrSetModalWindow (window)
	SHARED  WINDOW  window[]
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetModalWindow()lockout", lockout) : lockout = 0
'
'	PRINT "XgrSetModalWindow().A : "; window
	IF (window < 0) THEN window = 0
'
	IF window THEN
		IF InvalidWinGrid (window) THEN
			IF ##XBDV THEN PRINT "XgrSetModalWindow() : invalid window #"; window
			RETURN ($$TRUE)
		END IF
'
		window = window[window].top		' only top level windows can be modal
'
		IF InvalidWindow (window) THEN
			IF ##XBDV THEN PRINT "XgrSetModalWindow() : invalid top window #"
			RETURN ($$TRUE)
		END IF
'
' window = 0 means cancel modal window
'
		enable = $$FALSE
		who = window[window].whomask
		IF (who ^^ whomask) THEN window = 0
	END IF
'
' replace current modal window with new modal window or zero = none
'
	IF whomask THEN
		modalWindowUser = window
	ELSE
		modalWindowSystem = window
	END IF
 'IF ##XBDV THEN PRINT "XgrSetModalWindow().Z : "; window
END FUNCTION
'
'
' #####################################
' #####  XgrSetWindowFunction ()  #####
' #####################################
'
' error = XgrSetWindowFunction (window, &function())
'
FUNCTION  XgrSetWindowFunction (window, func)
	SHARED  WINDOW  window[]
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrSetWindowFunction() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	window[window].winFunc = func
END FUNCTION
'
'
' #################################
' #####  XgrSetWindowIcon ()  #####
' #################################
'
' error = XgrSetWindowIcon (window, icon)
'
FUNCTION  XgrSetWindowIcon (window, icon)
	SHARED  WINDOW  window[]
	SHARED  sicon[]
	AUTOX  list
	XIconSize  ix
	XWMHints  hint
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetWindowIcon()lockout", lockout) : lockout = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrSetWindowIcon() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	sicon = 0
	IF icon THEN
		IF InvalidIcon (icon) THEN
			##ERROR = ($$ErrorObjectIcon << 8) OR $$ErrorNatureNonexistent
			IF ##XBDV THEN PRINT "XgrSetWindowIcon() : invalid icon #"; icon
			RETURN ($$TRUE)
		END IF
'
		sdisplay = window[window].sdisplay
		swindow = window[window].swindow
		sicon = sicon[icon]
	END IF
'	XstLog ("XgrSetWindowIcon().Y : " + HEX$(sdisplay,8) + " : " + HEX$(swindow,8) + " : " + HEX$(sicon,8) + " : " + HEX$(icon,8) + " <" + icon$[icon] + ">")
'
	hint.flags = $$HintIconPixmap
	hint.iconPixmap = sicon
'
	##WHOMASK = 0
	##LOCKOUT = 100041
	IF sicon THEN XSetWMHints (sdisplay, swindow, &hint)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'	XstLog (@"XgrSetWindowIcon().Z")
END FUNCTION
'
'
' #######################################
' #####  XgrSetWindowMaxMinSize ()  #####
' #######################################
'
' error = XgrSetWindowMaxMinSize (window)
'
FUNCTION  XgrSetWindowMaxMinSize (window)
	SHARED  WINDOW  window[]
	STATIC  XSizeHints normalSizeHints, userSizeHints
'
	IF InvalidWindow (window) THEN RETURN ($$TRUE)
'
' No winFunc indicates that this is not a GUI window
' so it will not handle window messages
' #GetSmallestSize and #GetMaxMinSize
'
	IFZ window[window].winFunc THEN RETURN
'
' If the window does not have a resizing frame,
' it should not be resized and therefore, the
' minimum and maximum sizes do not need to be calculated.
'
	wt = window[window].type
	IFZ (wt AND $$WindowTypeResizeFrame) THEN RETURN
'
	XgrGetWindowGrid (window, @grid)

	XgrSendMessage (grid, #GetSmallestSize, 0, 0, @smallW, @smallH, 0, 0)
	XgrSendMessage (grid, #GetMaxMinSize, @maxW, @maxH, @minW, @minH, 0, 0)
	IF (smallW > minW) THEN minW = smallW
	IF (smallH > minH) THEN minH = smallH
	IF (minW   > maxW) THEN minW = maxW
	IF (minH   > maxH) THEN minH = maxH

	update = $$FALSE
	IF (maxW && maxH) THEN
		IF (window[window].minWidth  != minW) THEN window[window].minWidth  = minW : update = $$TRUE
		IF (window[window].minHeight != minH) THEN window[window].minHeight = minH : update = $$TRUE
		IF (window[window].maxWidth  != maxW) THEN window[window].maxWidth  = maxW : update = $$TRUE
		IF (window[window].maxHeight != maxH) THEN window[window].maxHeight = maxH : update = $$TRUE
	END IF
	IF update THEN
		swindow = window[window].swindow
		sdisplay = window[window].sdisplay
		'
		whomask = ##WHOMASK
		lockout = ##LOCKOUT
		IF lockout THEN XxxLog2 (@"XgrSetWindowMaxMinSize()lockout", lockout) : lockout = 0
		##WHOMASK = 0
		##LOCKOUT = 100042
		XGetWMNormalHints (sdisplay, swindow, &normalSizeHints, &userSizeHints)
		normalSizeHints.minWidth = minW
		normalSizeHints.maxWidth = maxW
		normalSizeHints.minHeight = minH
		normalSizeHints.maxHeight = maxH
		rc = XSetWMNormalHints (sdisplay, swindow, &normalSizeHints)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
	RETURN
'
END FUNCTION
'
'
' ############################################
' #####  XgrSetWindowPositionAndSize ()  #####
' ############################################
'
' error = XgrSetWindowPositionAndSize (window, x, y, width, height)
'
FUNCTION  XgrSetWindowPositionAndSize (window, x, y, width, height)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	STATIC  XSizeHints normalSizeHints, userSizeHints
'
'	XxxLog10("XgrSetWindowPositionAndSize()",grid,window,0,x,y,width,height,0,0)'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetWindowPositionAndSize()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrSetWindowPositionAndSize() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	top = window[window].top
	display = window[window].display
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	borderWidth = window[window].borderWidth
	titleHeight = window[window].titleHeight
	wmXoffset   = window[window].wmXoffset
	wmYoffset   = window[window].wmYoffset
	IFZ wmXoffset THEN
		IF ##XBDV THEN PRINT "XgrSetWindowPositionAndSize(35):zero wm XY offset"
	END IF
'
	wt = window[window].type
	xx = window[window].x
	yy = window[window].y
	ww = window[window].width
	hh = window[window].height
'
	IF (x = -1) THEN x = xx
	IF (y = -1) THEN y = yy
	IF (width < 0) THEN width = ww
	IF (height < 0) THEN height = hh
'
	IFZ (wt AND $$WindowTypeNoFrame) THEN
		IF (width < $$WindowMinimumWidth) THEN width = $$WindowMinimumWidth
		IF (height < $$WindowMinimumHeight) THEN height = $$WindowMinimumHeight
	END IF
'
	displayWidth = display[display].width
	displayHeight = display[display].height
	maxWidth = displayWidth - borderWidth - borderWidth
	maxHeight = displayHeight - borderWidth - borderWidth - titleHeight
'
' prevent window from extending outside display aka root window
'
	IF (x < 0) THEN x = borderWidth
	IF (y < titleHeight) THEN y = titleHeight
	IF (width > maxWidth) THEN width = maxWidth
	IF (height > maxHeight) THEN height = maxHeight
	IF (displayWidth < (x + width + borderWidth)) THEN x = displayWidth - borderWidth - width
	IF (displayHeight < (y + height + borderWidth)) THEN y = displayHeight - borderWidth - height
'
	window[window].x = x
	window[window].y = y
	window[window].width = width
	window[window].height = height
	IFZ (width || height) THEN
		IF ##XBDV THEN PRINT "XgrSetWindowPositionAndSize() : Invalid width or height", width, height
	END IF
'
	IF (wt AND $$WindowTypeNoFrame) THEN
		moveX = x
		moveY = y
	ELSE
		IFZ (borderWidth || titleHeight) THEN
			moveX = x - wmXoffset
			moveY = y - #windowTitleHeight- wmYoffset
		ELSE
			moveX = x - wmXoffset
			moveY = y - titleHeight- wmYoffset
		END IF
	END IF
'
'
' If configureRequest or visibilityRequest in progress wait up to 5 seconds to finish
'
	XstGetSystemTime (@start)
	DO
		configureRequest  = window[window].configureRequest
		visibilityRequest = window[window].visibilityRequest
		IF ((configureRequest != -1) && (visibilityRequest == -1)) THEN EXIT DO
		DispatchEvents ($$TRUE, $$TRUE)
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
	IF window[window].destroy THEN RETURN
	IF window[window].destroyed THEN RETURN
	IF window[window].destroyProcessed THEN RETURN
	IF (configureRequest = -1)   THEN PRINT "XgrSetWindowPositionAndSize()configureRequest  =", configureRequest,  window
	IF (visibilityRequest <> -1) THEN PRINT "XgrSetWindowPositionAndSize()visibilityRequest =", visibilityRequest, window
'
	IFZ (wt AND $$WindowTypeResizeFrame) THEN
		##WHOMASK = 0
		##LOCKOUT = 100043
		XGetWMNormalHints (sdisplay, swindow, &normalSizeHints, &userSizeHints)
		minH = normalSizeHints.minHeight
		maxH = normalSizeHints.maxHeight
		normalSizeHints.minWidth = width
		normalSizeHints.maxWidth = width
		normalSizeHints.minHeight = height
		normalSizeHints.maxHeight = height
		XSetWMNormalHints (sdisplay, swindow, &normalSizeHints)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
	XgrSetWindowMaxMinSize (window)
'
	visibility = window[window].visibility
	IF (visibility <> $$WindowHidden) THEN           ' if window is visible
		IFZ (wt AND $$WindowTypeNoFrame) THEN
			window[window].configureRequest = $$TRUE     ' set request for EventConfigureNotify confirmation
		END IF
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100044
	XMoveResizeWindow (sdisplay, swindow, moveX, moveY, width, height)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ##################################
' #####  XgrSetWindowState ()  #####
' ##################################
'
' error = XgrSetWindowState (window, visibility)
'
FUNCTION  XgrSetWindowState (window, visibility)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrSetWindowState() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	return = $$FALSE
	window = window[window].top
'
	SELECT CASE visibility
		CASE $$WindowHidden			: return = XgrHideWindow (window)
		CASE $$WindowDisplayed	: return = XgrDisplayWindow (window)
		CASE $$WindowMinimized	: return = XgrMinimizeWindow (window)
		CASE $$WindowMaximized	: return = XgrMaximizeWindow (window)
		CASE ELSE								: ##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
															IF ##XBDV THEN PRINT "XgrSetWindowState() : invalid visibility argument"
															return = $$TRUE
	END SELECT
	RETURN (return)
END FUNCTION
'
'
' ##################################
' #####  XgrSetWindowTitle ()  #####
' ##################################
'
' error = XgrSetWindowTitle (window, title$)
'
FUNCTION  XgrSetWindowTitle (window, title$)
	SHARED  WINDOW  window[]
	SHARED  window$[]
'	XTextProperty  text
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetWindowTitle()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrGetWindowTitle() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	##WHOMASK = 0
	sdisplay = window[window].sdisplay
	swindow = window[window].swindow
	window$[window] = title$
	##WHOMASK = whomask
'
'	text.value = &title$
'	text.encoding = #XA_WM_NAME
'	text.format = 8
'	text.nItems = LEN (title$)
'
'	XStoreName() does not like a null title$ address
'
	IFZ title$ THEN
		title$ = " "
	END IF

	##WHOMASK = 0
	##LOCKOUT = 100045
'	XSetTextProperty (sdisplay, swindow, &text, #XA_WM_NAME)
	XStoreName (sdisplay, swindow, &title$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #######################################
' #####  XgrSetWindowVisibility ()  #####
' #######################################
'
' error = XgrSetWindowVisibility (window, visibility)
'
FUNCTION  XgrSetWindowVisibility (window, visibility)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrSetWindowVisibility() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	return = $$FALSE
	window = window[window].top
'
	SELECT CASE visibility
		CASE $$WindowHidden			: return = XgrHideWindow (window)
		CASE $$WindowDisplayed	: return = XgrDisplayWindow (window)
		CASE $$WindowMinimized	: return = XgrMinimizeWindow (window)
		CASE $$WindowMaximized	: return = XgrMaximizeWindow (window)
		CASE ELSE								: ##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
															IF ##XBDV THEN PRINT "XgrSetWindowVisibility() : invalid visibility argument"
															return = $$TRUE
	END SELECT
	RETURN (return)
END FUNCTION
'
'
' ##############################
' #####  XgrShowWindow ()  #####
' ##############################
'
' error = XgrShowWindow (window)
'
'  Make a window visible, but NOT active.
'  Some window managers and how they are configured may still make the window active.
'
' See: XgrDisplayWindow(), XgrHideWindow()
'
FUNCTION  XgrShowWindow (window)
	SHARED  WINDOW  window[]
	SHARED  doNotFocusWhenMapped
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrShowWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrShowWindow() : error : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	top = window[window].top
'
	IF (window != top) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "XgrShowWindow() : error : window not a top-level window #"; window
		RETURN ($$TRUE)
	END IF
'
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' If visibilityRequest in progress wait up to 5 seconds to finish
'
	XstGetSystemTime (@start)
	DO
		visibilityRequest = window[window].visibilityRequest
		IF (visibilityRequest == -1) THEN EXIT DO
		DispatchEvents ($$FALSE, $$TRUE)
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
	IF (visibilityRequest <> -1) THEN
		PRINT "XgrShowWindow()visibilityRequest =", visibilityRequest, window
	END IF
'
	visibility = window[window].visibility
	IF (visibility = $$WindowHidden) THEN                  'if window is hidden
		'
		' Windows with a frame and windowType $$WindowTypeTopMost
		' should be displayed above all other windows. The _NET_WM_STATE_ABOVE
		' atom is removed each time a window is unmapped and
		' needs to be put back in each time the window is mapped.
		' Windows with $$WindowTypeNoFrame are handle with the "overrideRedirect" attribute
		'
		windowType = window[window].type
		IFZ (windowType AND $$WindowTypeNoFrame) THEN
			IF (windowType AND $$WindowTypeTopMost) THEN
				DIM stateData[0]
				stateData[0] = #XA_NET_WM_STATE_ABOVE
				XgrChangeProperty (window, #XA_NET_WM_STATE, #XA_ATOM, $$PropModeReplace, @stateData[])
			END IF
		END IF
'
		window[window].visibilityRequest = $$WindowDisplayed
		doNotFocusWhenMapped = window[window].swindow
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100046
	XMapWindow (sdisplay, swindow)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ########################################
' #####  XgrConvertDisplayToGrid ()  #####
' ########################################
'
' error = XgrConvertDisplayToGrid (grid, xDisp, yDisp, @xGrid, @yGrid)
'
FUNCTION  XgrConvertDisplayToGrid (grid, xDisp, yDisp, xGrid, yGrid)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertDisplayToGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertDisplayToLocal (grid, xDisp, yDisp, @x, @y)
	XgrConvertLocalToGrid (grid, x, y, @xGrid, @yGrid)
END FUNCTION
'
'
' #########################################
' #####  XgrConvertDisplayToLocal ()  #####
' #########################################
'
' error = XgrConvertDisplayToLocal (grid, xDisp, yDisp, @x, @y)
'
' returns $$TRUE if x,y is outside grid
' computes x,y coords from xDisp,yDisp even if outside grid
'
FUNCTION  XgrConvertDisplayToLocal (grid, xDisp, yDisp, x, y)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertDisplayToLocal() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	width = window[window].width
	height = window[window].height
	display = window[window].display
	displayWidth = display[display].width
	displayHeight = display[display].height
'
' add all x,y window positions from this window back to top window
' to produce the xDisp, yDisp of the upper left corner of this window.
'
	dx = 0
	dy = 0
'
	DO
		dx = dx + window[window].x
		dy = dy + window[window].y
		window = window[window].parent
	LOOP WHILE window
'
	x = xDisp - dx													' x = xDisp in local coords
	y = yDisp - dy													' y = yDisp in local coords
END FUNCTION
'
'
' ##########################################
' #####  XgrConvertDisplayToScaled ()  #####
' ##########################################
'
' error = XgrConvertDisplayToScaled (grid, xDisp, yDisp, @x#, @y#)
'
FUNCTION  XgrConvertDisplayToScaled (grid, xDisp, yDisp, x#, y#)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertDisplayToScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertDisplayToLocal (grid, xDisp, yDisp, @x, @y)
	XgrConvertLocalToScaled (grid, x, y, @x#, @y#)
END FUNCTION
'
'
' ##########################################
' #####  XgrConvertDisplayToWindow ()  #####
' ##########################################
'
' error = XgrConvertDisplayToWindow (grid, xDisp, yDisp, @xWin, @yWin)
'
FUNCTION  XgrConvertDisplayToWindow (grid, xDisp, yDisp, xWin, yWin)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertDisplayToWindow() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = window[grid].top
	xWin = xDisp - window[window].x
	yWin = yDisp - window[window].y
END FUNCTION
'
'
' ########################################
' #####  XgrConvertGridToDisplay ()  #####
' ########################################
'
' error = XgrConvertGridToDisplay (grid, xGrid, yGrid, @xDisp, @yDisp)
'
FUNCTION  XgrConvertGridToDisplay (grid, xGrid, yGrid, xDisp, yDisp)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertGridToDisplay() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertGridToLocal (grid, xGrid, yGrid, @x, @y)
	XgrConvertLocalToDisplay (grid, x, y, @xDisp, @yDisp)
END FUNCTION
'
'
' ######################################
' #####  XgrConvertGridToLocal ()  #####
' ######################################
'
' error = XgrConvertGridToLocal (grid, xGrid, yGrid, @x, @y)
'
FUNCTION  XgrConvertGridToLocal (grid, xGrid, yGrid, x, y)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertGridToLocal() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1 = window[window].gridBoxX1
	y1 = window[window].gridBoxY1
	x2 = window[window].gridBoxX2
	y2 = window[window].gridBoxY2
'
	IF (x2 > x1) THEN
		x = xGrid - x1
	ELSE
		x = x1 - xGrid
	END IF
'
	IF (y2 > y1) THEN
		y = yGrid - y1
	ELSE
		y = y1 - yGrid
	END IF
END FUNCTION
'
'
' #######################################
' #####  XgrConvertGridToScaled ()  #####
' #######################################
'
' error = XgrConvertGridToScaled (grid, xGrid, yGrid, @x#, @y#)
'
FUNCTION  XgrConvertGridToScaled (grid, xGrid, yGrid, x#, y#)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertGridToScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertGridToLocal (grid, xGrid, yGrid, @x, @y)
	XgrConvertLocalToScaled (grid, x, y, @x#, @y#)
END FUNCTION
'
'
' #######################################
' #####  XgrConvertGridToWindow ()  #####
' #######################################
'
' error = XgrConvertGridToWindow (grid, xGrid, yGrid, @xWin, @yWin)
'
FUNCTION  XgrConvertGridToWindow (grid, xGrid, yGrid, xWin, yWin)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertGridToWindow() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertGridToLocal (grid, xGrid, yGrid, @x, @y)
	XgrConvertLocalToWindow (grid, x, y, @xWin, @yWin)
END FUNCTION
'
'
' #########################################
' #####  XgrConvertLocalToDisplay ()  #####
' #########################################
'
' error = XgrConvertLocalToDisplay (grid, x, y, @xDisp, @yDisp)
'
FUNCTION  XgrConvertLocalToDisplay (grid, x, y, xDisp, yDisp)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertLocalToDisplay() : invalid wingrid #"; grid, #cw
		RETURN ($$TRUE)
	END IF
'
	window = grid
	top = window[window].top
'
' add all x,y positions from this window back to the top window
' to compute the dx,dy of the display origin to this window origin.
'
	dx = 0
	dy = 0
'
	DO
		dx = dx + window[window].x
		dy = dy + window[window].y
		window = window[window].parent
	LOOP WHILE window
'
	xDisp = x + dx
	yDisp = y + dy
END FUNCTION
'
'
' ######################################
' #####  XgrConvertLocalToGrid ()  #####
' ######################################
'
' error = XgrConvertLocalToGrid (grid, x, y, @xGrid, @yGrid)
'
FUNCTION  XgrConvertLocalToGrid (grid, x, y, xGrid, yGrid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertLocalToGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1 = window[window].gridBoxX1
	y1 = window[window].gridBoxY1
	x2 = window[window].gridBoxX2
	y2 = window[window].gridBoxY2
'
	IF (x2 > x1) THEN
		xGrid = x1 + x
	ELSE
		xGrid = x1 - x
	END IF
'
	IF (y2 > y1) THEN
		yGrid = y1 + y
	ELSE
		yGrid = y1 - y
	END IF
END FUNCTION
'
'
' ########################################
' #####  XgrConvertLocalToScaled ()  #####
' ########################################
'
' error = XgrConvertLocalToScaled (grid, x, y, @x#, @y#)
'
FUNCTION  XgrConvertLocalToScaled (grid, x, y, x#, y#)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertLocalToScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1# = window[window].gridBoxScaledX1
	y1# = window[window].gridBoxScaledY1
	xm# = window[window].xScaledPerPixel
	ym# = window[window].yScaledPerPixel
'
	IFZ xm# THEN UpdateScaledCoordinates (window)
	IFZ ym# THEN UpdateScaledCoordinates (window)
'
	x# = x1# + (x * xm#)
	y# = y1# + (y * ym#)
END FUNCTION
'
'
' ########################################
' #####  XgrConvertLocalToWindow ()  #####
' ########################################
'
' error = XgrConvertLocalToWindow (grid, x, y, @xWin, @yWin)
'
FUNCTION  XgrConvertLocalToWindow (grid, x, y, xWin, yWin)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertLocalToWindow() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
' add all x,y positions from this window back to the top window
' to compute the dx,dy of the top window origin to this grid origin.
'
	dx = 0
	dy = 0
	window = grid
	top = window[window].top
'
	DO UNTIL (window = top)
		dx = dx + window[window].x
		dy = dy + window[window].y
		window = window[window].parent
	LOOP WHILE window
'
	xWin = x + dx
	yWin = y + dy
END FUNCTION
'
'
' ##########################################
' #####  XgrConvertScaledToDisplay ()  #####
' ##########################################
'
' error = XgrConvertScaledToDisplay (grid, x#, y#, @xDisp, @yDisp)
'
FUNCTION  XgrConvertScaledToDisplay (grid, x#, y#, xDisp, yDisp)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertScaledToDisplay() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertScaledToLocal (grid, x#, y#, @x, @y)
	XgrConvertLocalToDisplay (grid, x, y, @xDisp, @yDisp)
END FUNCTION
'
'
' #######################################
' #####  XgrConvertScaledToGrid ()  #####
' #######################################
'
' error = XgrConvertScaledToGrid (grid, x#, y#, @xGrid, @yGrid)
'
FUNCTION  XgrConvertScaledToGrid (grid, x#, y#, xGrid, yGrid)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertScaledToGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertScaledToLocal (grid, x#, y#, @x, @y)
	XgrConvertLocalToGrid (grid, x, y, @xGrid, @yGrid)
END FUNCTION
'
'
' ########################################
' #####  XgrConvertScaledToLocal ()  #####
' ########################################
'
' error = XgrConvertScaledToLocal (grid, x#, y#, @x, @y)
'
FUNCTION  XgrConvertScaledToLocal (grid, x#, y#, x, y)
	SHARED  WINDOW  window[]
	STATIC  entry
	STATIC  max#
	STATIC  min#
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertScaledToLocal() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ entry THEN
		entry = $$TRUE
		max# = 0x7FFFFFFF
'		min# = 0x80000001      '*cw* 220705-
		min# = -0x7FFFFFFF     '*cw* 220705+
	END IF
'
	window = grid
	update = $$FALSE
'
	x1# = window[window].gridBoxScaledX1
	y1# = window[window].gridBoxScaledY1
	xm# = window[window].xPixelsPerScaled
	ym# = window[window].yPixelsPerScaled
	mx# = window[window].xScaledPerPixel
	my# = window[window].yScaledPerPixel
'
	IFZ xm# THEN update = $$TRUE
	IFZ ym# THEN update = $$TRUE
	IFZ mx# THEN update = $$TRUE
	IFZ my# THEN update = $$TRUE
'
	IF update THEN
		UpdateScaledCoordinates (window)
		xm# = window[window].xPixelsPerScaled
		ym# = window[window].yPixelsPerScaled
	END IF
'
' to avoid math exceptions caused by too small or large values,
' compute floating point x#,y# and compare to min/max integers.
'
	xx# = (x# - x1#) * xm#		' local x coordinate
	yy# = (y# - y1#) * ym#		' local y coordinate
'
'	IF (xx# < min#) THEN xx# = 0x80000001		' xx# was too negative for SLONG  '*cw* 220705-
'	IF (yy# < min#) THEN yy# = 0x80000001		' yy# was too negative for SLONG  '*cw* 220705-
	IF (xx# < min#) THEN xx# = min#         ' xx# was too negative for SLONG  '*cw* 220705+
	IF (yy# < min#) THEN yy# = min#         ' yy# was too negative for SLONG  '*cw* 220705+
	IF (xx# > max#) THEN xx# = 0x7FFFFFFF		' xx# was too positive for SLONG
	IF (yy# > max#) THEN yy# = 0x7FFFFFFF		' yy# was too positive for SLONG
'
	x = xx#
	y = yy#
END FUNCTION
'
'
' #########################################
' #####  XgrConvertScaledToWindow ()  #####
' #########################################
'
' error = XgrConvertScaledToWindow (grid, x#, y#, @xWin, @yWin)
'
FUNCTION  XgrConvertScaledToWindow (grid, x#, y#, xWin, yWin)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertScaledToWindow() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertScaledToLocal (grid, x#, y#, @x, @y)
	XgrConvertLocalToWindow (grid, x, y, @xWin, @yWin)
END FUNCTION
'
'
' ##########################################
' #####  XgrConvertWindowToDisplay ()  #####
' ##########################################
'
' error = XgrConvertWindowToDisplay (grid, xWin, yWin, @xDisp, @yDisp)
'
FUNCTION  XgrConvertWindowToDisplay (grid, xWin, yWin, xDisp, yDisp)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertWindowToDisplay() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window = window[window].top
	xDisp = xWin + window[window].x
	yDisp = yWin + window[window].y
END FUNCTION
'
'
' #######################################
' #####  XgrConvertWindowToGrid ()  #####
' #######################################
'
' error = XgrConvertWindowToGrid (grid, xWin, yWin, @xGrid, @yGrid)
'
FUNCTION  XgrConvertWindowToGrid (grid, xWin, yWin, xGrid, yGrid)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertWindowToGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertWindowToLocal (grid, xWin, yWin, @x, @y)
	XgrConvertLocalToGrid (grid, x, y, @xGrid, @yGrid)
END FUNCTION
'
'
' ########################################
' #####  XgrConvertWindowToLocal ()  #####
' ########################################
'
' error = XgrConvertWindowToLocal (grid, xWin, yWin, @x, @y)
'
FUNCTION  XgrConvertWindowToLocal (grid, xWin, yWin, x, y)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertWindowToLocal() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
' add all x,y positions from this window back to the top window
' to compute the dx,dy of the top window origin to this grid origin.
'
	dx = 0
	dy = 0
	window = grid
	top = window[window].top
'
	DO UNTIL (window = top)
		dx = dx + window[window].x
		dy = dy + window[window].y
		window = window[window].parent
	LOOP WHILE window
'
	x = xWin - dx
	y = yWin - dy
END FUNCTION
'
'
' #########################################
' #####  XgrConvertWindowToScaled ()  #####
' #########################################
'
' error = XgrConvertWindowToScaled (grid, xWin, yWin, @x#, @y#)
'
FUNCTION  XgrConvertWindowToScaled (grid, xWin, yWin, x#, y#)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrConvertWindowToScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrConvertWindowToLocal (grid, xWin, yWin, @x, @y)
	XgrConvertLocalToScaled (grid, x, y, @x#, @y#)
END FUNCTION
'
'
' ##############################
' #####  XgrGetGridBox ()  #####
' ##############################
'
' error = XgrGetGridBox (grid, @x1Grid, @y1Grid, @x2Grid, @y2Grid)
'
FUNCTION  XgrGetGridBox (grid, x1Grid, y1Grid, x2Grid, y2Grid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBox() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1Grid = window[window].gridBoxX1
	y1Grid = window[window].gridBoxY1
	x2Grid = window[window].gridBoxX2
	y2Grid = window[window].gridBoxY2
END FUNCTION
'
'
' #####################################
' #####  XgrGetGridBoxDisplay ()  #####
' #####################################
'
' error = XgrGetGridBoxDisplay (grid, @x1Disp, @y1Disp, @x2Disp, @y2Disp)
'
FUNCTION  XgrGetGridBoxDisplay (grid, x1Disp, y1Disp, x2Disp, y2Disp)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBoxDisplay() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1 = 0
	y1 = 0
	x2 = window[window].width - 1
	y2 = window[window].height - 1
	XgrConvertLocalToDisplay (grid, x1, y1, @x1Disp, @y1Disp)
	XgrConvertLocalToDisplay (grid, x2, y2, @x2Disp, @y2Disp)
END FUNCTION
'
'
' ##################################
' #####  XgrGetGridBoxGrid ()  #####
' ##################################
'
' error = XgrGetGridBoxGrid (grid, @x1Grid, @y1Grid, @x2Grid, @y2Grid)
'
FUNCTION  XgrGetGridBoxGrid (grid, x1Grid, y1Grid, x2Grid, y2Grid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBoxGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1Grid = window[window].gridBoxX1
	y1Grid = window[window].gridBoxY1
	x2Grid = window[window].gridBoxX2
	y2Grid = window[window].gridBoxY2
END FUNCTION
'
'
' ###################################
' #####  XgrGetGridBoxLocal ()  #####
' ###################################
'
' error = XgrGetGridBoxLocal (grid, @x1, @y1, @x2, @y2)
'
FUNCTION  XgrGetGridBoxLocal (grid, x1, y1, x2, y2)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBoxLocal() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1 = 0
	y1 = 0
	x2 = window[window].width - 1
	y2 = window[window].height - 1
END FUNCTION
'
'
' ####################################
' #####  XgrGetGridBoxScaled ()  #####
' ####################################
'
' error = XgrGetGridBoxScaled (grid, @x1#, @y1#, @x2#, @y2#)
'
FUNCTION  XgrGetGridBoxScaled (grid, x1#, y1#, x2#, y2#)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBoxScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1# = window[window].gridBoxScaledX1
	y1# = window[window].gridBoxScaledY1
	x2# = window[window].gridBoxScaledX2
	y2# = window[window].gridBoxScaledY2
END FUNCTION
'
'
' ####################################
' #####  XgrGetGridBoxWindow ()  #####
' ####################################
'
' error = XgrGetGridBoxWindow (grid, @x1Win, @y1Win, @x2Win, @y2Win)
'
FUNCTION  XgrGetGridBoxWindow (grid, x1Win, y1Win, x2Win, y2Win)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBoxWindow() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1 = 0
	y1 = 0
	x2 = window[window].width - 1
	y2 = window[window].height - 1
	XgrConvertLocalToWindow (grid, x1, y1, @x1Win, @y1Win)
	XgrConvertLocalToWindow (grid, x2, y2, @x2Win, @y2Win)
END FUNCTION
'
'
' ######################################
' #####  XgrGetGridCoordinates ()  #####
' ######################################
'
' error = XgrGetGridCoordinates (grid, @x, @y, @x1, @y1, @x2, @y2)
'
FUNCTION  XgrGetGridCoordinates (grid, x, y, x1, y1, x2, y2)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridCoordinates() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x = window[window].x
	y = window[window].y
	x1 = 0
	y1 = 0
	x2 = window[window].width - 1
	y2 = window[window].height - 1
END FUNCTION
'
'
' #################################
' #####  XgrGetGridCoords ()  #####
' #################################
'
' error = XgrGetGridCoords (grid, @x, @y, @x1, @y1, @x2, @y2)
'
FUNCTION  XgrGetGridCoords (grid, x, y, x1, y1, x2, y2)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridCoordinates() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x = window[window].x
	y = window[window].y
	x1Grid = window[window].gridBoxX1
	y1Grid = window[window].gridBoxY1
	x2Grid = window[window].gridBoxX2
	y2Grid = window[window].gridBoxY2
END FUNCTION
'
'
' ##########################################
' #####  XgrGetGridPositionAndSize ()  #####
' ##########################################
'
' error = XgrGetGridPositionAndSize (grid, @x, @y, @width, @height)
'
FUNCTION  XgrGetGridPositionAndSize (grid, @x, @y, @width, @height)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridPositionAndSize() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x = window[window].x
	y = window[window].y
	width = window[window].width
	height = window[window].height
END FUNCTION
'
'
' ##############################
' #####  XgrSetGridBox ()  #####
' ##############################
'
' error = XgrSetGridBox (grid, x1Grid, y1Grid, x2Grid, y2Grid)
'
' Sets the (upper-left, lower-right) of the grid-box to the grid
' coordinates. It does not change the position or size of the grid,
' and if the values of x2Grid, y2Grid are inconsistent with grid width
' and height, they are adjusted to make them so.
'
FUNCTION  XgrSetGridBox (grid, x1Grid, y1Grid, x2Grid, y2Grid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridBox() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	width = window[window].width
	height = window[window].height
	newWidth = ABS(x2Grid-x1Grid) + 1
	newHeight = ABS(y2Grid-y1Grid) + 1
'
	IF (width != newWidth) THEN
		oldX1 = window[window].gridBoxX1
		oldX2 = window[window].gridBoxX2
		IF (oldX2 < oldX1) THEN
			x2Grid = x1Grid - width + 1			' x decreases rightward
		ELSE
			x2Grid = x1Grid + width - 1			' x increases rightward
		END IF
	END IF
'
	IF (height != newHeight) THEN
		oldY1 = window[window].gridBoxY1
		oldY2 = window[window].gridBoxY2
		IF (oldY2 < oldY1) THEN
			y2Grid = y1Grid - height + 1		' y decreases downward
		ELSE
			y2Grid = y1Grid + height - 1		' y increases downward
		END IF
	END IF
'
	window[window].gridBoxX1 = x1Grid
	window[window].gridBoxY1 = y1Grid
	window[window].gridBoxX2 = x2Grid
	window[window].gridBoxY2 = y2Grid
END FUNCTION
'
'
' ##################################
' #####  XgrSetGridBoxGrid ()  #####
' ##################################
'
' error = XgrSetGridBoxGrid (grid, x1Grid, y1Grid, x2Grid, y2Grid)
'
' Sets the (upper-left, lower-right) of the grid-box to the grid
' coordinates. It does not change the position or size of the grid,
' and if the values of x2Grid, y2Grid are inconsistent with grid width
' and height, they are adjusted to make them so.
'
FUNCTION  XgrSetGridBoxGrid (grid, x1Grid, y1Grid, x2Grid, y2Grid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridBoxGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	width = window[window].width
	height = window[window].height
	newWidth = ABS(x2Grid-x1Grid) + 1
	newHeight = ABS(y2Grid-y1Grid) + 1
'
	IF (width != newWidth) THEN
		oldX1 = window[window].gridBoxX1
		oldX2 = window[window].gridBoxX2
		IF (oldX2 < oldX1) THEN
			x2Grid = x1Grid - width + 1			' x decreases rightward
		ELSE
			x2Grid = x1Grid + width - 1			' x increases rightward
		END IF
	END IF
'
	IF (height != newHeight) THEN
		oldY1 = window[window].gridBoxY1
		oldY2 = window[window].gridBoxY2
		IF (oldY2 < oldY1) THEN
			y2Grid = y1Grid - height + 1		' y decreases downward
		ELSE
			y2Grid = y1Grid + height - 1		' y increases downward
		END IF
	END IF
'
	window[window].gridBoxX1 = x1Grid
	window[window].gridBoxY1 = y1Grid
	window[window].gridBoxX2 = x2Grid
	window[window].gridBoxY2 = y2Grid
END FUNCTION
'
'
' ####################################
' #####  XgrSetGridBoxScaled ()  #####
' ####################################
'
' error = XgrSetGridBoxScaled (grid, x1#, y1#, x2#, y2#)
'
' Sets the (upper-left, lower-right) of the grid-box
' to scaled coordinates  x1#, y1#, x2#, y2#.
' It does not change the position or size of the grid,
'
FUNCTION  XgrSetGridBoxScaled (grid, x1#, y1#, x2#, y2#)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridBoxScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
'
'	SELECT CASE x1#
'		CASE $$NNAN		:	x1# = 0#	: x2# = 1#
'		CASE $$PNAN		: x1# = 0#	: x2# = 1#
'		CASE $$NINF		: x1# = 0#	: x2# = 1#
'		CASE $$PINF		: x1# = 0#	: x2# = 1#
'	END SELECT
'
'	SELECT CASE y1#
'		CASE $$NNAN		:	y1# = 0#	: y2# = 1#
'		CASE $$PNAN		: y1# = 0#	: y2# = 1#
'		CASE $$NINF		: y1# = 0#	: y2# = 1#
'		CASE $$PINF		: y1# = 0#	: y2# = 1#
'	END SELECT
'
'	SELECT CASE x2#
'		CASE $$NNAN		:	x1# = 0#	: x2# = 1#
'		CASE $$PNAN		: x1# = 0#	: x2# = 1#
'		CASE $$NINF		: x1# = 0#	: x2# = 1#
'		CASE $$PINF		: x1# = 0#	: x2# = 1#
'	END SELECT
'
'	SELECT CASE y2#
'		CASE $$NNAN		:	y1# = 0#	: y2# = 1#
'		CASE $$PNAN		: y1# = 0#	: y2# = 1#
'		CASE $$NINF		: y1# = 0#	: y2# = 1#
'		CASE $$PINF		: y1# = 0#	: y2# = 1#
'	END SELECT
'
	IF (x1# = x2#) THEN													' avoid math exceptions
		x1# = window[window].gridBoxX1
		x2# = window[window].gridBoxX2
	END IF
	IF (x1# = x2#) THEN x1# = -1# : x2# = +1#
'
	IF (y1# = y2#) THEN													' avoid math exceptions
		y1# = window[window].gridBoxY1
		y2# = window[window].gridBoxY2
	END IF
	IF (y1# = y2#) THEN y1# = -1# : y2# = +1#
'
	window[window].gridBoxScaledX1 = x1#
	window[window].gridBoxScaledY1 = y1#
	window[window].gridBoxScaledX2 = x2#
	window[window].gridBoxScaledY2 = y2#
'
	window[window].xScaledPerPixel = 0#					' update when necessary
	window[window].yScaledPerPixel = 0#
	window[window].xPixelsPerScaled = 0#
	window[window].yPixelsPerScaled = 0#
END FUNCTION
'
'
' ######################################
' #####  XgrSetGridBoxScaledAt ()  #####
' ######################################
'
' error = XgrSetGridBoxScaledAt (grid, x1#, y1#, x2#, y2#, x1, y1, x2, y2)
'
FUNCTION  XgrSetGridBoxScaledAt (grid, x1#, y1#, x2#, y2#, x1, y1, x2, y2)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridBoxScaledAt() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrGetGridBox (grid, @xx1, @yy1, @xx2, @yy2)
'
	dx = x2 - x1
	dy = y2 - y1
'
	dx# = x2# - x1#
	dy# = y2# - y1#
'
	ddx = xx2 - xx1
	ddy = yy2 - yy1
'
	xx# = dx# / dx
	yy# = dy# / dy
'
	xx1# = x1# - (xx# * x1)		' scaled coord of left pixel
	yy1# = y1# - (yy# * y1)		' scaled coord of top pixel
'
	xx2# = xx1# + (xx# * ddx)	' scaled coord of right pixel
	yy2# = yy1# + (yy# * ddy)	' scaled coord of bottom pixel
'
	XgrSetGridBoxScaled (grid, xx1#, yy1#, xx2#, yy2#)
'
'	PRINT FORMAT$ ("###.#####  ", x1); FORMAT$ ("###.#####  ", y1); FORMAT$ ("###.#####  ", x2); FORMAT$ ("###.#####  ", y2)
'	PRINT FORMAT$ ("###.#####  ", x1#); FORMAT$ ("###.#####  ", y1#); FORMAT$ ("###.#####  ", x2#); FORMAT$ ("###.#####  ", y2#)
'	PRINT FORMAT$ ("###.#####  ", xx1#); FORMAT$ ("###.#####  ", yy1#); FORMAT$ ("###.#####  ", xx2#); FORMAT$ ("###.#####  ", yy2#)
END FUNCTION
'
'
' ##########################################
' #####  XgrSetGridPositionAndSize ()  #####
' ##########################################
'
' error = XgrSetGridPositionAndSize (grid, x, y, width, height)
'
FUNCTION  XgrSetGridPositionAndSize (grid, x, y, width, height)
	SHARED  WINDOW  window[]
	STATIC  WINDOW  winzip
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetGridPositionAndSize()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridPositionAndSize() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	top = window[window].top
	parent = window[window].parent
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	gridFunc = window[window].gridFunc
	gridType = window[window].type
'
	IF (window = top) THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "XgrSetGridPositionAndSize() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
' get current coordinates
'
	xx = window[window].x
	yy = window[window].y
	ww = window[window].width
	hh = window[window].height
	gridBoxX1 = window[window].gridBoxX1
	gridBoxY1 = window[window].gridBoxY1
	gridBoxX2 = window[window].gridBoxX2
	gridBoxY2 = window[window].gridBoxY2
'
	IF (gridType = 1) THEN x = 0 : y = 0 : xx = 0 : yy = 0
'
	IF (x = -1) THEN x = xx
	IF (y = -1) THEN y = yy
	IF (width <= 0) THEN width = ww
	IF (height <= 0) THEN height = hh
'
' see if position and/or size changed
'
	w = $$FALSE
	h = $$FALSE
	move = $$FALSE
'
	IF (x != xx) THEN move = $$TRUE
	IF (y != yy) THEN move = $$TRUE
	IF (width != ww) THEN w = $$TRUE
	IF (height != hh) THEN h = $$TRUE
'
' if same position and size don't move or resize window
'
	IFZ (move OR w OR h) THEN RETURN ($$FALSE)
'
' update grid position and size
'
	window[window].x = x
	window[window].y = y
	window[window].width = width
	window[window].height = height
'
	IF (move OR w OR h) THEN
		window[window].priorX = xx
		window[window].priorY = yy
		window[window].priorWidth = width
		window[window].priorHeight = height
		window[window].xScaledPerPixel = 0#			' invalidate
		window[window].yScaledPerPixel = 0#			' scaled coordinate
		window[window].xPixelsPerScaled = 0#		' multipliers
		window[window].yPixelsPerScaled = 0#		'
	END IF
'
' compute new grid box
' leave x1,y1 the same
' set x2,y2 with same direction (increasing left vs right / up vs down)
'
	IF (gridBoxX2 < gridBoxX1) THEN
		gridBoxX2 = gridBoxX1 - width + 1			' x coords decrease rightward
	ELSE
		gridBoxX2 = gridBoxX1 + width - 1			' x coords increase rightward
	END IF
'
	IF (gridBoxY2 < gridBoxY1) THEN
		gridBoxY2 = gridBoxY1 - height + 1		' y coords decrease downward
	ELSE
		gridBoxY2 = gridBoxY1 + height - 1		' y coords increase downward
	END IF
'
	window[window].gridBoxX1 = gridBoxX1
	window[window].gridBoxY1 = gridBoxY1
	window[window].gridBoxX2 = gridBoxX2
	window[window].gridBoxY2 = gridBoxY2
'
' cannot resize pixmaps, so create a new image grid of the new size
'
	image = 0
	IF (gridType = 1) THEN
		IFZ (w OR h) THEN RETURN ($$FALSE)			' image grid size unchanged
		XgrCreateGrid (@image, 1, 0, 0, width, height, top, parent, gridFunc)
		IF image THEN
			XgrDestroyGrid (grid)									' destroy old pixmap
			window[grid] = window[image]					' steal new grid slot
			window[grid].window = grid						' steal new grid number
			window[image] = winzip								' clear out image slot
		END IF
	ELSE
		##WHOMASK = 0
		##LOCKOUT = 100047
		XMoveResizeWindow (sdisplay, swindow, x, y, width, height)
		##LOCKOUT = lockout
		DispatchEvents ($$TRUE, $$FALSE)
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' ##############################
' #####  XgrCreateGrid ()  #####
' ##############################
'
' error = XgrCreateGrid (@grid, gridType, x, y, w, h, window, parent, gridFunc)
'
'	If gridType = 1, then this is an image grid
' If parent != 0, then this is a "subwindow" or "grid"
' If parent = 0, then it will be set equal to window
'
FUNCTION  XgrCreateGrid (grid, gridType, x, y, w, h, window, parent, gridFunc)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  sfontDefault
	SHARED  window$[]
	SHARED  noExpose
	SHARED  r[]
	SHARED  g[]
	SHARED  b[]
	STATIC  entry
	STATIC  WINDOW  defaultGrid
	XWindowAttributes  attributes
	XSetWindowAttributes  setAttributes
	XGCValues  gcvalues
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrCreateGrid()lockout", lockout) : lockout = 0
'
	IFZ entry THEN GOSUB Initialize
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrCreateGrid() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	state = $$TRUE
	IF (gridType < 0) THEN gridType = -gridType : state = $$FALSE
'
'	XgrGridTypeNumberToName (gridType, @gt$)
'	PRINT "XgrCreateGrid() : "; grid; gridType;; gt$; x; y; w; h; window; parent;; HEX$(gridFunc,8);;;;
'
' if gridType = 1, then this is an image grid
' if parent != 0, then this is a "subwindow" or "grid"
' if parent = 0, then this is the "window grid" that IS the window
'
	sdisplay = window[window].sdisplay
	display = window[window].display
	IF parent THEN
		IF (parent != window) THEN
			IF InvalidGrid (parent) THEN
				IF ##XBDV THEN PRINT "XgrCreateGrid() : invalid parent #"
				RETURN ($$TRUE)
			END IF
		END IF
	ELSE
		parent = window
	END IF
'
	SELECT CASE TRUE
		CASE gridType = #GridTypeImage	: GOSUB Image
		CASE parent											: GOSUB Grid
		CASE ELSE												:	PRINT "XgrCreateGrid() : disaster"
	END SELECT
	RETURN (return)
'
'
' *****  Image  *****
'
SUB Image
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrCreateGrid() : Image : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	top = window[window].top
	stop = window[window].stop
	display = window[window].display
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	root = display[display].root
	sroot = display[display].sroot
	class = display[display].class
	depth = display[display].depth
	sblack = display[display].black
	swhite = display[display].white
	visual = display[display].visual
	screen = display[display].screen
'
' if zero width or height then set width, height to parent width, height
'
	IF ((w <= 0) OR (h <= 0)) THEN
		IF (parent AND (parent != top)) THEN
			h = window[parent].height
			w = window[parent].width
		END IF
	END IF
'
'	a$ = "\ndepth = " + STRING$ (depth) + "\n"
'	write (1, &a$, LEN(a$))
'
'	addr = XListPixmapFormats (sdisplay, &count)
'	IF addr THEN
'		IF count THEN
'			FOR i = 1 TO count
'				d = XLONGAT (addr)	: addr = addr + 4
'				b = XLONGAT (addr)	: addr = addr + 4
'				s = XLONGAT (addr)	: addr = addr + 4
'				a$ = STRING$(i) + " " + STRING$(d) + " " + STRING$(b) + " " + STRING$(s) + "\n"
'				write (1, &a$, LEN(a$))
'			NEXT i
'		END IF
'	END IF
'
	IF (w <= 0) THEN w = 32         ' need valid width
	IF (h <= 0) THEN h = 32         ' need valid height
'
' create the memory image == pixmap
'
	##WHOMASK = 0
	##LOCKOUT = 100048
	simage = XCreatePixmap (sdisplay, stop, w, h, depth)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ simage THEN
		##ERROR = ($$ErrorObjectSystemRoutine << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrCreateGrid() : error : XCreatePixmap() failed"
		RETURN ($$TRUE)
	END IF
'
' assign graphics context, colors, font to image/pixmap
'
	##WHOMASK = 0
	GraphicsContext (@gc, $$Create, sdisplay, screen, simage, sfontDefault)
	##WHOMASK = whomask
'
' get a grid # and initialize values
'
	GetNewWindowNumber (@grid)
'
	##WHOMASK = 0
	window$[grid] = ""                              ' default grid name/title
	##WHOMASK = whomask
	window[grid] = defaultGrid                      ' default grid properties
'
	window[grid].window = grid                      ' native window / grid #
	window[grid].parent = parent                    ' native parent window #
	window[grid].kind = $$KindGrid                  ' $$KindGrid vs $$KindWindow
	window[grid].type = gridType                    ' grid type
	window[grid].top = top                          ' native top level window #
	window[grid].display = display                  ' native display #
	window[grid].gridFunc = gridFunc                ' grid function
	window[grid].whomask = whomask                  ' owner whomask
	window[grid].font = font                        ' native font # (default)
'
	window[grid].lowlightColor = #defaultLowlight
	window[grid].highlightColor = #defaultHighlight
	window[grid].dullColor = #defaultDull
	window[grid].accentColor = #defaultAccent
	window[grid].lowtextColor = #defaultLowtext
	window[grid].hightextColor = #defaultHightext
'
	window[grid].x = x                              ' requested
	window[grid].y = y                              ' requested
	window[grid].width = w                          ' requested
	window[grid].height = h                         ' requested
	window[grid].minWidth = $$WindowMinimumWidth    ' default
	window[grid].minHeight = $$WindowMinimumHeight  ' default
	window[grid].maxWidth = 0xFFFF                  ' default
	window[grid].maxHeight = 0xFFFF                 ' default
	window[grid].gridBoxX1 = 0                      ' default origin = 0,0
	window[grid].gridBoxY1 = 0                      ' default origin = 0,0
	window[grid].gridBoxX2 = w - 1                  ' from requested width
	window[grid].gridBoxY2 = h - 1                  ' from requested height
	window[grid].gridBoxScaledX1 = 0#
	window[grid].gridBoxScaledY1 = 0#
	window[grid].gridBoxScaledX2 = DOUBLE(w-1)
	window[grid].gridBoxScaledY2 = DOUBLE(h-1)
'
' swindow = simage = system pixmap #
'
	window[grid].gc = gc                            ' system gc #
	window[grid].stop = stop                        ' system top #
	window[grid].sroot = sroot                      ' system root #
	window[grid].visual = visual                    ' system visual
	window[grid].swindow = simage                   ' system window #
	window[grid].sparent = sparent                  ' system parent #
	window[grid].sdisplay = sdisplay                ' system display #
'
' initialize the background and drawing colors and clear to background color
'
	XgrSetBackgroundColor (grid, #defaultBackground)
	XgrSetDrawingColor (grid, #defaultDrawing)
	XgrClearGrid (grid, #defaultBackground)
	return = $$FALSE
END SUB
'
'
' *****  Grid  *****  this grid has a parent, so it's a kid grid
'
SUB Grid
'
	top = window[window].top
	stop = window[window].stop
	display = window[parent].display
	sparent = window[parent].swindow
	sdisplay = window[parent].sdisplay
'
	root = display[display].root
	sroot = display[display].sroot
	class = display[display].class
	depth = display[display].depth
	sblack = display[display].black
	swhite = display[display].white
	visual = display[display].visual
	screen = display[display].screen
'
' if zero width or height then set width, height to parent width, height
'
	IF ((w <= 0) OR (h <= 0)) THEN
		IF parent THEN
			h = window[parent].height
			w = window[parent].width
		ELSE
			h = window[top].height
			w = window[top].width
		END IF
	END IF
'
	IF (w <= 0) THEN w = 32         ' need valid width
	IF (h <= 0) THEN h = 32         ' need valid height

	mask = 0
	valuemask = 0
	mask = mask OR $$KeyPressMask
	mask = mask OR $$KeyReleaseMask
	mask = mask OR $$ButtonPressMask
	mask = mask OR $$ButtonReleaseMask
	mask = mask OR $$EnterWindowMask
	mask = mask OR $$LeaveWindowMask
	mask = mask OR $$ButtonMotionMask
	mask = mask OR $$ExposureMask
'	mask = mask OR $$VisibilityChangeMask
	mask = mask OR $$StructureNotifyMask				' !!!!!!
	mask = mask OR $$FocusChangeMask
	setAttributes.eventMask = mask
	valuemask = $$CWEventMask
'
'	PRINT x; y; w; h;;;; HEX$(sdisplay,8);; HEX$(sparent,8);; depth;; HEX$(visual,8);; HEX$(valuemask,8);; HEX$(&setAttributes)
'
' create the window
'
	##WHOMASK = 0
	##LOCKOUT = 100049
	swindow = XCreateWindow (sdisplay, sparent, x, y, w, h, 0, depth, $$InputOutput, visual, valuemask, &setAttributes)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ swindow THEN
		##ERROR = ($$ErrorObjectSystemRoutine << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrCreateGrid() : error : XCreateWindow() failed"
		RETURN ($$TRUE)
	END IF
'
' success - assign a native window number
'
	GetNewWindowNumber (@grid)
'
'	IF ##XBDV THEN
'		XgrGridTypeNumberToName (gridType, @gridType$)
'		PRINT "XgrCreateGrid() : "; grid;; HEX$(grid,8);; HEX$(swindow,8);; gridType;; gridType$;; parent;; window;;; HEX$(gridFunc,8)
'	END IF
'
' create font and gc (graphics context)
'
	##WHOMASK = 0
	IFZ sfontDefault THEN Font (@font, $$Create, display, @sfontDefault, @addrFont, 0, 0, 0, 0, "")
	GraphicsContext (@gc, $$Create, sdisplay, screen, swindow, sfontDefault)
	##WHOMASK = whomask
'
	##WHOMASK = 0
	window$[grid] = ""                              ' default grid name/title
	##WHOMASK = whomask
	window[grid] = defaultGrid                      ' default grid properties
'
	winFunc = window[parent].winFunc                ' inheret parent window function
	window[grid].window = grid                      ' native window / grid #
	window[grid].parent = parent                    ' native parent window #
	window[grid].kind = $$KindGrid                  ' $$KindGrid vs $$KindWindow
	window[grid].type = gridType                    ' grid type
	window[grid].top = top                          ' native top level window #
	window[grid].display = display                  ' native display #
	window[grid].gridFunc = gridFunc                ' grid function
	window[grid].winFunc = winFunc                  ' no window function
	window[grid].font = font                        ' native font # (default)
'
	window[grid].lowlightColor = #defaultLowlight
	window[grid].highlightColor = #defaultHighlight
	window[grid].dullColor = #defaultDull
	window[grid].accentColor = #defaultAccent
	window[grid].lowtextColor = #defaultLowtext
	window[grid].hightextColor = #defaultHightext
'
	window[grid].state = state                      ' grid enable / disable
'	window[grid].visibility = -1                    ' window never visible
	window[grid].visibility = $$WindowHidden
	window[grid].priorVisibility = -1               ' window never visible
	window[grid].whomask = whomask                  ' owner whomask
'
	window[grid].x = x                              ' requested
	window[grid].y = y                              ' requested
	window[grid].width = w                          ' requested
	window[grid].height = h                         ' requested
	window[grid].minWidth = $$WindowMinimumWidth    ' default
	window[grid].minHeight = $$WindowMinimumHeight  ' default
	window[grid].maxWidth = 0xFFFF                  ' default
	window[grid].maxHeight = 0xFFFF                 ' default
	window[grid].gridBoxX1 = 0                      ' default origin = 0,0
	window[grid].gridBoxY1 = 0                      ' default origin = 0,0
	window[grid].gridBoxX2 = w - 1                  ' from requested width
	window[grid].gridBoxY2 = h - 1                  ' from requested height
	window[grid].gridBoxScaledX1 = 0#
	window[grid].gridBoxScaledY1 = 0#
	window[grid].gridBoxScaledX2 = DOUBLE(w-1)
	window[grid].gridBoxScaledY2 = DOUBLE(h-1)
'
	window[grid].gc = gc                            ' system gc #
	window[grid].stop = stop                        ' system top #
	window[grid].sroot = sroot                      ' system root #
	window[grid].visual = visual                    ' system visual
	window[grid].swindow = swindow                  ' system window #
	SetSwindowXref (swindow, grid)                  ' set system window to window cross reference
	window[grid].sparent = sparent                  ' system parent #
	window[grid].sdisplay = sdisplay                ' system display #
	window[grid].eventMask = mask                   ' XSelectInput() event mask
'
' initialize the background and drawing colors
'
	XgrSetBackgroundColor (grid, #defaultBackground)
	XgrSetDrawingColor (grid, #defaultDrawing)
'
	noExpose = grid
	##WHOMASK = 0
	##LOCKOUT = 100050
	IF state THEN XMapWindow (sdisplay, swindow)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask
	noExpose = 0
'
	return = $$FALSE
END SUB
'
'
' *****  Initialize  *****  anything not specified is 0 = zero
'
SUB Initialize
	defaultGrid.kind = $$KindGrid
	defaultGrid.backgroundColor = #defaultBackground
	defaultGrid.drawingColor = #defaultDrawing
	defaultGrid.lowlightColor = #defaultLowlight
	defaultGrid.highlightColor = #defaultHighlight
	defaultGrid.dullColor = #defaultDull
	defaultGrid.accentColor = #defaultAccent
	defaultGrid.lowtextColor = #defaultLowtext
	defaultGrid.hightextColor = #defaultHightext
	defaultGrid.backColor = #defaultBackground
	defaultGrid.backBlue = b[3]
	defaultGrid.backGreen = g[3]
	defaultGrid.backRed = r[3]
	defaultGrid.drawColor = #defaultDrawing
	defaultGrid.drawBlue = b[0]
	defaultGrid.drawGreen = g[0]
	defaultGrid.drawRed = r[0]
	defaultGrid.x = 0
	defaultGrid.y = 0
	defaultGrid.width = $$WindowMinimumWidth
	defaultGrid.height = $$WindowMinimumHeight
	defaultGrid.minWidth = $$WindowMinimumWidth
	defaultGrid.minHeight = $$WindowMinimumHeight
	defaultGrid.maxWidth = 0xFFFF
	defaultGrid.maxHeight = 0xFFFF
	defaultGrid.gridBoxX1 = 0
	defaultGrid.gridBoxY1 = 0
	defaultGrid.gridBoxX2 = 3
	defaultGrid.gridBoxY2 = 3
	defaultGrid.gridBoxScaledX1 = 0#
	defaultGrid.gridBoxScaledY1 = 0#
	defaultGrid.gridBoxScaledX2 = 3#
	defaultGrid.gridBoxScaledY2 = 3#
	defaultGrid.xPixelsPerScaled = 1#
	defaultGrid.yPixelsPerScaled = 1#
	defaultGrid.xScaledPerPixel = 1#
	defaultGrid.yScaledPerPixel = 1#
'
	defaultGrid.sbackground = -1                    ' current background scolor = none
	defaultGrid.sforeground = -1                    ' current foreground scolor = none
	defaultGrid.sbackgroundDefault = -1             ' default background scolor = none
	defaultGrid.sforegroundDefault = -1             ' default foreground scolor = none
	defaultGrid.state = $$TRUE                      ' grid enable
	defaultGrid.visibility = $$WindowHidden
	defaultGrid.priorVisibility = -1                ' window never visible
	entry = $$TRUE
END SUB
END FUNCTION
'
'
' ###############################
' #####  XgrDestroyGrid ()  #####
' ###############################
'
' error = XgrDestroyGrid (grid)
'
FUNCTION  XgrDestroyGrid (wingrid)
	SHARED  textSelectionGrid
	SHARED  WINDOW  window[]
	STATIC	WINDOW  zipwin
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDestroyGrid()lockout", lockout) : lockout = 0
'
	grid = wingrid
	window = wingrid
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDestroyGrid(A) : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	gc = window[grid].gc
	top = window[grid].top
	stop = window[grid].stop
	swindow = window[grid].swindow
	sdisplay = window[grid].sdisplay
	processed = window[grid].destroyProcessed
	destroyed = window[grid].destroyed
	destroy = window[grid].destroy
	gridType = window[grid].type
	timer = window[grid].timer
	func = window[grid].winFunc
'
	IF (grid = top) THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalidKind
		IF ##XBDV THEN PRINT "XgrDestroyGrid(B) : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IF (processed OR destroyed OR destroy) THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrDestroyGrid(C) : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ swindow THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrDestroyGrid(D) : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
' flush any events and message that might be headed for the destroyed grid
'
	DispatchEvents ($$FALSE, $$FALSE)
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' destroy in progress - destroy miscellaneous grid resources
'
	window[grid].state = $$FALSE
	window[grid].destroy = $$TRUE
	IF timer THEN XxxXstTimer ($$TimerKill, grid, timer, 0, 0, 0)
	IF (grid = textSelectionGrid) THEN textSelectionGrid = 0
'
' destroy all kids of this grid - recursively kills all descendents
'
	FOR kid = 1 TO UBOUND (window[])
		IF window[kid].window THEN                                         ' kid is active
			IFZ window[kid].destroy THEN                                     ' not in destroy
				IFZ window[kid].destroyed THEN                                 ' not destroyed
					IF (grid = window[kid].parent) THEN                          ' grid is kid parent
						IF (kid != grid) THEN                                      ' kid is not the grid
							err = XgrDestroyGrid (kid)                               ' destroy kid
							IF err THEN PRINT "XgrDestroyGrid(78):error", grid, kid
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT kid
'
' process all resulting events and messages
'
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' XFreePixmap()    does not generate an event
' XDestroyWindow() generates an EventDestroyNotify()
'
	##WHOMASK = 0
	##LOCKOUT = 100051
	XFreeGC (sdisplay, gc)
	window[grid].gc = 0
	window[grid].destroy = $$TRUE
	IF (gridType = 1) THEN                ' pixmap
		XFreePixmap (sdisplay, swindow)
		window[grid].swindow = 0
		window[grid].window = 0             ' mark grid available
		window[grid].destroyed = $$TRUE
	ELSE
		XDestroyWindow (sdisplay, swindow)  ' EventDestroyNotify() marks grid available
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
	DispatchEvents ($$TRUE, $$FALSE)
'
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
END FUNCTION
'
'
' #################################
' #####  XgrGetGridBorder ()  #####
' #################################
'
' error = XgrGetGridBorder (grid, @border, @borderUp, @borderDown, 0)
'
' borderFlags is not implemented
'
' See: XgrSetGridBorder()
'
FUNCTION  XgrGetGridBorder (grid, @border, @borderUp, @borderDown, @borderFlags)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBorder() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	border = window[window].border
	borderUp = window[window].borderUp
	borderDown = window[window].borderDown
	borderFlags = 0
END FUNCTION
'
'
' #######################################
' #####  XgrGetGridBorderOffset ()  #####
' #######################################
'
' error = XgrGetGridBorderOffset (grid, @left, @top, @right, @bottom)
'
' See: XgrSetGridBorderOffset()
'
FUNCTION  XgrGetGridBorderOffset (grid, @left, @top, @right, @bottom)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBorderOffset() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	left = window[window].borderOffsetLeft
	top = window[window].borderOffsetTop
	right = window[window].borderOffsetRight
	bottom = window[window].borderOffsetBottom
END FUNCTION
'
'
' #################################
' #####  XgrGetGridBuffer ()  #####
' #################################
'
' error = XgrGetGridBuffer (grid, @buffer, @x, @y)
'
' See: XgrSetGridBuffer()
'
FUNCTION  XgrGetGridBuffer (grid, buffer, x, y)
	SHARED  WINDOW  window[]
'
	buffer = 0
	window = grid
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridBuffer() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	buffer = window[window].buffer
	x = window[window].bufferX
	y = window[window].bufferY
'
	IF buffer THEN
		IF InvalidGrid (buffer) THEN
			IF ##XBDV THEN PRINT "XgrGetGridBuffer() : invalid buffer grid #"
			RETURN ($$TRUE)
		END IF
'
		gt = window[buffer].type
		IF (gt != #GridTypeBuffer) THEN
			##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalidType
			IF ##XBDV THEN PRINT "XgrGetGridBuffer() : buffer grid type != #GridTypeImage"
			RETURN ($$TRUE)
		END IF
	END IF
END FUNCTION
'
'
' ############################################
' #####  XgrGetGridCharacterMapArray ()  #####
' ############################################
'
' error = XgrGetGridCharacterMapArray (grid, @map[])
'
' See: XgrSetGridCharacterMapArray()
'
FUNCTION  XgrGetGridCharacterMapArray (grid, map[])
	SHARED  charMap[]
'
	DIM map[]
'
' grid = 0 returns default character map array from grid # 0, so grid # 0 is valid
'
	IF grid THEN
		IF InvalidGrid (grid) THEN
			IF ##XBDV THEN PRINT "XgrGetGridCharacterMapArray() : invalid grid #"; grid
			RETURN ($$TRUE)
		END IF
	END IF
'
	u = UBOUND (charMap[])								' how big is char map array
	IF (u >= grid) THEN										' if big enough for this grid
		IF charMap[grid,] THEN							' if char map defined for this grid
			uu = UBOUND (charMap[grid,])			' what is last element
			DIM map[uu]												' create map array
			FOR i = 0 TO uu										' for all chars
				map[i] = charMap[grid,i]				' copy char
			NEXT i														' next
		END IF
	END IF
END FUNCTION
'
'
' ######################################
' #####  XgrGetGridDrawingMode ()  #####
' ######################################
'
' error = XgrGetGridDrawingMode (grid, @drawMode, @lineStyle, @lineWidth)
'
' See: XgrSetGridDrawingMode()
'
FUNCTION  XgrGetGridDrawingMode (grid, @drawMode, @lineStyle, @lineWidth)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridDrawingMode() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	drawMode = window[window].drawMode
	lineStyle = window[window].lineStyle
	lineWidth = window[window].lineWidth
END FUNCTION
'
'
' ###############################
' #####  XgrGetGridFont ()  #####
' ###############################
'
' error = XgrGetGridFont (grid, @font)
'
' See: XgrSetGridFont()
'
FUNCTION  XgrGetGridFont (grid, @font)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridFont() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	font = window[window].font
END FUNCTION
'
'
' ###################################
' #####  XgrGetGridFunction ()  #####
' ###################################
'
' error = XgrGetGridFunction (grid, @gridFunc)
'
FUNCTION  XgrGetGridFunction (grid, @gridFunc)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridFunction() : invalid grid #"; grid, ERROR$(ERROR(-1))
		RETURN ($$TRUE)
	END IF
'
	window = grid
	gridFunc = window[window].gridFunc
END FUNCTION
'
'
' #################################
' #####  XgrGetGridParent ()  #####
' #################################
'
' error = XgrGetGridParent (grid, @parent)
'
' See: XgrCreateGrid()
'
FUNCTION  XgrGetGridParent (grid, @parent)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridParent() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	parent = window[window].parent
END FUNCTION
'
'
' ################################
' #####  XgrGetGridState ()  #####
' ################################
'
' error = XgrGetGridState (grid, @state)
'
' state will be $$FALSE if grid is destroyed or disabled
' state will be $$TRUE  if grid exists and is enabled
'
FUNCTION  XgrGetGridState (grid, @state)
	SHARED  WINDOW  window[]
'
	state = 0
'
	IF InvalidGrid (grid) THEN
		upper = UBOUND (window[])
		IF ((grid <= 0) OR (grid > upper)) THEN RETURN ($$TRUE) ' out-of-bounds grid #
		IF ##XBDV THEN
			IFZ (window[grid].destroyed AND window[grid].destroy) THEN
				PRINT "XgrGetGridState() : invalid grid #"; grid, ERROR$(ERROR(-1))
			END IF
		END IF
		RETURN ($$TRUE)
	END IF
'
	IF window[grid].destroy THEN RETURN ($$TRUE)               ' grid destroyed
'
	window = grid
	state = window[window].state
END FUNCTION
'
'
'
' ##################################
' #####  XgrGetGridTimerID ()  #####
' ##################################
'
' error = XgrGetGridTimerID (grid, @timeOutID)
'
' See: XgrSetGridTimer()
'
FUNCTION  XgrGetGridTimerID (grid, @timeOutID)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridType() : invalid grid #"; grid
		timeOutID = 0
		RETURN ($$TRUE)
	END IF
'
	timeOutID = window[grid].timer
END FUNCTION
'
'
'
' ###############################
' #####  XgrGetGridType ()  #####
' ###############################
'
' error = XgrGetGridType (grid, @gridType)
'
' See: XgrSetGridType
'
FUNCTION  XgrGetGridType (grid, @gridType)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetGridType() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	gridType = window[window].type
END FUNCTION
'
'
' #################################
' #####  XgrGetGridWindow ()  #####
' #################################
'
' error = XgrGetGridWindow (wingrid, @window)
'
' See: XgrGetWindowGrid()
'
FUNCTION  XgrGetGridWindow (grid, @window)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (grid) THEN
		IFZ (window[grid].destroyed AND window[grid].destroy) THEN
			IF ##XBDV THEN PRINT "XgrGetGridWindow() : invalid grid #"; grid, ERROR$(ERROR(-1))
		END IF
		RETURN ($$TRUE)
	END IF
'
	window = window[grid].top
END FUNCTION
'
'
' ########################################
' #####  XgrGridTypeNameToNumber ()  #####
' ########################################
'
' XgrGridTypeNameToNumber (gridType$, @gridType)
'
' "Coordinate"   - 0
' "Image"        - 1
' "LastGridType" - highest grid type number
'  invalid grid type name - type -1
'
' See: XgrGridTypeNumberToName(), XgrRegisterGridType()
'
FUNCTION  XgrGridTypeNameToNumber (gridType$, @gridType)
	SHARED  lastGridType
	SHARED  gridType$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGridTypeNameToNumber()lockout", lockout) : lockout = 0
'
	IFZ gridType$[] THEN
		##WHOMASK = 0
		DIM gridType$[15]
		gridType$[0] = "Coordinate"
		gridType$[1] = "Image"
		##WHOMASK = whomask
	END IF
'
	IF (gridType$ = "LastGridType") THEN
		gridType = lastGridType
		RETURN ($$FALSE)
	END IF
'
	upper = UBOUND (gridType$[])
'
	FOR gridType = 0 TO upper
		IF gridType$[gridType] THEN
			IF (gridType$ = gridType$[gridType]) THEN EXIT FOR
		END IF
	NEXT gridType
'
	IF (gridType > upper) THEN gridType = -1
END FUNCTION
'
'
' ########################################
' #####  XgrGridTypeNumberToName ()  #####
' ########################################
'
' XgrGridTypeNumberToName (gridType, @gridType$)
'
' See: XgrGridTypeNameToNumber(), XgrRegisterGridType()
'
FUNCTION  XgrGridTypeNumberToName (gridType, @gridType$)
	SHARED  gridType$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGridTypeNumberToName()lockout", lockout) : lockout = 0
'
	IFZ gridType$[] THEN
		##WHOMASK = 0
		DIM gridType$[15]
		gridType$[0] = "Coordinate"
		gridType$[1] = "Image"
		##WHOMASK = whomask
	END IF
'
	gridType$ = ""
	upper = UBOUND (gridType$[])
	IF (gridType < 0) THEN RETURN ($$FALSE)
	IF (gridType > upper) THEN RETURN ($$FALSE)
	gridType$ = gridType$[gridType]
END FUNCTION
'
'
' ####################################
' #####  XgrRegisterGridType ()  #####
' ####################################
'
' XgrRegisterGridType (gridType$, @gridType)
'
' See: XgrGridTypeNameToNumber(), XgrGridTypeNumberToName()
'
FUNCTION  XgrRegisterGridType (gridType$, @gridType)
	SHARED  lastGridType
	SHARED  gridType$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrRegisterGridType()lockout", lockout) : lockout = 0
'
	IFZ gridType$[] THEN
		##WHOMASK = 0
		DIM gridType$[15]
		gridType$[0] = "Coordinate"
		gridType$[1] = "Image"
		##WHOMASK = whomask
		lastGridType = 1
	END IF
'
	slot = -1
	upper = UBOUND (gridType$[])
'
	IF (gridType$ = "LastGridType") THEN
		gridType = lastGridType
		RETURN ($$FALSE)
	END IF
'
	FOR gridType = 0 TO upper
		IFZ gridType$[gridType] THEN
			IF (slot = -1) THEN slot = gridType
		ELSE
			IF (gridType$ = gridType$[gridType]) THEN EXIT FOR
		END IF
	NEXT gridType
'
	IF (gridType > upper) THEN
		IF (slot < 0) THEN
			upper = upper + 16
			##WHOMASK = 0
			REDIM gridType$[upper]
			##WHOMASK = whomask
		ELSE
			gridType = slot
		END IF
		##WHOMASK = 0
		gridType$[gridType] = gridType$
		##WHOMASK = whomask
	END IF
'
	IF (gridType > lastGridType) THEN lastGridType = gridType
END FUNCTION
'
'
' #################################
' #####  XgrSetGridBorder ()  #####
' #################################
'
' error = XgrSetGridBorder (grid, border, borderUp, borderDown, 0)
'
' borderFlags is not implemented
'
' See: XgrGetGridBorder()
'
FUNCTION  XgrSetGridBorder (grid, border, borderUp, borderDown, borderFlags)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridBorder() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IF (border != -1) THEN window[window].border = border
	IF (borderUp != -1) THEN window[window].borderUp = borderUp
	IF (borderDown != -1) THEN window[window].borderDown = borderDown
END FUNCTION
'
'
' #######################################
' #####  XgrSetGridBorderOffset ()  #####
' #######################################
'
' error = XgrSetGridBorderOffset (grid, left, top, right, bottom)
'
' See: XgrGetGridBorderOffset()
'
FUNCTION  XgrSetGridBorderOffset (grid, left, top, right, bottom)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridBorderOffset() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].borderOffsetLeft = left
	window[window].borderOffsetTop = top
	window[window].borderOffsetRight = right
	window[window].borderOffsetBottom = bottom
END FUNCTION
'
'
' #################################
' #####  XgrSetGridBuffer ()  #####
' #################################
'
' error = XgrSetGridBuffer (grid, buffer, x, y)
'
' See: XgrGetGridBuffer()
'
FUNCTION  XgrSetGridBuffer (grid, buffer, x, y)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridBuffer() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IF buffer THEN
		IF InvalidGrid (buffer) THEN
			IF ##XBDV THEN PRINT "XgrSetGridBuffer() : invalid grid #"; grid
			RETURN ($$TRUE)
		END IF
'
		gt = window[buffer].type
		IF (gt != #GridTypeBuffer) THEN
			##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalidType
			IF ##XBDV THEN PRINT "XgrSetGridBuffer() : buffer grid type != #GridTypeImage"
			RETURN ($$TRUE)
		END IF
	END IF
'
	window = grid
	window[window].bufferX = x
	window[window].bufferY = y
	window[window].buffer = buffer
END FUNCTION
'
'
' ######################################
' #####  XgrSetGridDrawingMode ()  #####
' ######################################
'
' error = XgrSetGridDrawingMode (grid, drawMode, lineStyle, lineWidth)
'
' $$DrawModeSET
' $$DrawModeXOR
' $$DrawModeAND
' $$DrawModeOR
'
' $$LineStyleSolid
' $$LineStyleDash
' $$LineStyleDot
' $$LineStyleDashDot
' $$LineStyleDashDotDot
'
' lineWidth is in pixels. A line width of 0 (zero) is known in Linux as
'           a "thin" line one pixel wide and usually drawn faster and looks
'           better than a width of 1.
'
' lineMode or lineStyle of -1 means no change
'
' There can be strange drawing results if the program loses track of the
' drawing mode.  One solution might be to save the existing mode at the
' beginning of the program and restoring it at the end:
'
'   XgrGetGridDrawingMode (grid, @drawMode, @lineStyle, @lineWidth) 'save mode
'   XgrSetGridDrawingMode (grid, $$DrawModeSET, $$LineStyleDash, 4) 'new mode
'     ... draw dashed lines ...
'   XgrSetGridDrawingMode (grid, drawMode, lineStyle, lineWidth)  'restore mode
'
' See: XgrGetGridDrawingMode()
'
FUNCTION  XgrSetGridDrawingMode (grid, drawMode, lineStyle, lineWidth)
	SHARED  WINDOW  window[]
	STATIC  UBYTE  dash[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetGridDrawingMode()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridDrawingMode() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ dash[] THEN
		##WHOMASK = 0
		DIM dash[7]
		##WHOMASK = whomask
	END IF
'
	window = grid
	gc = window[window].gc
	sdisplay = window[window].sdisplay
'
' set drawing mode if changed and valid drawMode
'
	IF (drawMode != -1) THEN
		IF (drawMode != window[window].drawMode) THEN
			mode = -1
			SELECT CASE drawMode
				CASE $$DrawModeSET	: mode = $$GXCopy	: submode = $$ClipByChildren
				CASE $$DrawModeXOR	: mode = $$GXXor	: submode = $$IncludeInferiors
				CASE $$DrawModeAND	: mode = $$GXAnd	: submode = $$ClipByChildren
				CASE $$DrawModeOR		: mode = $$GXOr		: submode = $$ClipByChildren
			END SELECT
			IF (mode != -1) THEN
				##WHOMASK = 0
				##LOCKOUT = 100052
				XSetFunction (sdisplay, gc, mode)
				XSetSubwindowMode (sdisplay, gc, submode)
				##LOCKOUT = lockout
				##WHOMASK = whomask
				window[window].drawMode = drawMode
			END IF
		END IF
	END IF
'
' set lineStyle and lineWidth if changed and valid values
'
	change = $$FALSE						' change requires XSetLineAttributes()
'
	IF (lineStyle < 0) THEN lineStyle = window[window].lineStyle
	IF (lineStyle > $$LineStyleMax) THEN lineStyle = $$LineStyleSolid
	IF (lineStyle != window[window].lineStyle) THEN
		window[window].lineStyle = lineStyle
		change = $$TRUE
	END IF
'
	SELECT CASE lineStyle
		CASE $$LineStyleSolid				: slineStyle = $$XLineSolid
																	dash[0] = 255 : dash[1] = 0 : dash[2] = 255 : dash[3] = 0
																	n = 2
		CASE $$LineStyleDash				: slineStyle = $$XLineOnOffDash
																	dash[0] = 3 : dash[1] = 3 : dash[2] = 3 : dash[3] = 3
																	n = 2
		CASE $$LineStyleDot					: slineStyle = $$XLineOnOffDash
																	dash[0] = 1 : dash[1] = 3 : dash[2] = 1 : dash[3] = 3
																	n = 2
		CASE $$LineStyleDashDot			: slineStyle = $$XLineOnOffDash
																	dash[0] = 3 : dash[1] = 3 : dash[2] = 1 : dash[3] = 3
																	n = 4
		CASE $$LineStyleDashDotDot	: slineStyle = $$XLineOnOffDash
																	dash[0] = 3 : dash[1] = 3 : dash[2] = 1 : dash[3] = 2 : dash[4] = 1 : dash[5] = 2
																	n = 6
	END SELECT
'
	IF (lineStyle != $$LineStyleSolid) THEN
		##WHOMASK = 0
		##LOCKOUT = 100053
		XSetDashes (sdisplay, gc, 0, &dash[], n)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
	IF (lineWidth < 0) THEN lineWidth = 0
'
	IF (lineWidth != window[window].lineWidth) THEN
		window[window].lineWidth = lineWidth
		change = $$TRUE
	END IF
'
	IF change THEN
		##WHOMASK = 0
		##LOCKOUT = 100054
		XSetLineAttributes (sdisplay, gc, lineWidth, slineStyle, $$CapButt, $$JoinRound)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' ###############################
' #####  XgrSetGridFont ()  #####
' ###############################
'
' error = XgrSetGridFont (grid, font)
'
' See: XgrGetGridFont()
'
FUNCTION  XgrSetGridFont (grid, font)
	SHARED  WINDOW  window[]
	SHARED  FONT  font[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 ("XgrSetGridFont()lockout " + STR$(grid), lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridFont() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IF InvalidFont (font) THEN
		##ERROR = ($$ErrorObjectFont << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrSetGridFont() : invalid font #"
		RETURN ($$TRUE)
	END IF
'
	window = grid
	gc = window[window].gc
	sfont = font[font].sfont
	window[window].font = font
	sdisplay = window[window].sdisplay
'
	##WHOMASK = 0
	##LOCKOUT = 100055
	XSetFont (sdisplay, gc, sfont)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###################################
' #####  XgrSetGridFunction ()  #####
' ###################################
'
' error = XgrSetGridFunction (grid, &gridFunc())
'
' Replaces the grid function address that was set by XgrCreateGrid()
'
' CAUTION: Remember to put the "&" at the beginning and the "()"
' at the end of the function name, so that it is the address of a
' function and no the content or address of a variable.
'
' Use SetGridFunction message or XuiSetGridFunction() on GUI Designer
' windows so GUI and  Graphics programs have identical information.
'
' See: SetGridFunction, XgrGetGridFunction()
'
FUNCTION  XgrSetGridFunction (grid, gridFunc)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridFunction() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].gridFunc = gridFunc
END FUNCTION
'
'
' #################################
' #####  XgrSetGridParent ()  #####
' #################################
'
' unimplemented
'
' See: XgrGetGridParent(), XgrCreateGrid()
'
FUNCTION  XgrSetGridParent (grid, parent)
	PRINT "XgrSetGridParent() : unimplemented"
END FUNCTION
'
'
' ################################
' #####  XgrSetGridState ()  #####
' ################################
'
' error = XgrSetGridState (grid, state)
'
' Use of this function is not recomended
'
' See: XgrDisplayWindow(), XgrShowWindow(), XgrHideWindow()
'      XgrGetWindowState(), XgrGetWindowVisibility()
'
FUNCTION  XgrSetGridState (grid, state)
	SHARED  WINDOW  window[]
	SHARED  noExpose
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetGridState()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridState() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	old = window[window].state
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	window[window].state = state
'
	IF old THEN
		IFZ state THEN
			##WHOMASK = 0
			##LOCKOUT = 100056
			XUnmapWindow (sdisplay, swindow)		' from enable to disable
			##LOCKOUT = lockout
			DispatchEvents ($$TRUE, $$FALSE)
			##WHOMASK = whomask
		END IF
	ELSE
		IF state THEN
			noExpose = window
			##WHOMASK = 0
			##LOCKOUT = 100057
			XMapWindow (sdisplay, swindow)			' from disable to enable
			##LOCKOUT = lockout
			DispatchEvents ($$TRUE, $$FALSE)
			##WHOMASK = whomask
			noExpose = 0
		END IF
	END IF
END FUNCTION
'
'
' ################################
' #####  XgrSetGridTimer ()  #####
' ################################
'
' error = XgrSetGridTimer (grid, msec)
'
' msec = 0 will stop the timer
'
' See: XgrGetGridTimerID()
'
FUNCTION  XgrSetGridTimer (grid, msec)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridTimer() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	timer = window[grid].timer							' current timer #
	window[grid].timer = $$FALSE						' timer invalid
	IF timer THEN
		kerror = XxxXstTimer ($$TimerKill, grid, timer, 0, 0, 0)
		IF kerror THEN PRINT "XgrSetGridTimer()kerror", grid, timer, msec
	END IF
'
' install new grid timer
'
	IF (msec > 0) THEN
		error = XxxXstTimer ($$TimerStart, grid, @timer, 1, msec, &XxxXgrGridTimer())
		IF error THEN
			window[grid].timer = 0
			PRINT "XgrSetGridTimer()error", grid, msec
		ELSE
			window[grid].timer = timer
		END IF
	END IF
'
	RETURN (error)
END FUNCTION
'
'
' ###############################
' #####  XgrSetGridType ()  #####
' ###############################
'
' error = XgrSetGridType (grid, gridType)
'
' See: XgrGetGridType()
'
FUNCTION  XgrSetGridType (grid, gridType)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetGridType() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IF InvalidGridType (gridType) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrSetGridType() : invalid (unregistered) grid type"
		RETURN ($$TRUE)
	END IF
'
	nowType = window[window].type
'
	IF (gridType = #GridTypeImage) THEN
		IF (nowType != #GridTypeImage) THEN
			##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalidType
			IF ##XBDV THEN PRINT "XgrSetGridType() : attempt to change gridType to image grid"
			RETURN ($$TRUE)
		END IF
	ELSE
		IF (nowType = #GridTypeImage) THEN
			##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalidType
			IF ##XBDV THEN PRINT "XgrSetGridType() : attempt to change gridType from image grid"
			RETURN ($$TRUE)
		END IF
	END IF
'
	window = grid
	window[window].type = gridType
END FUNCTION
'
'
' ############################################
' #####  XgrSetGridCharacterMapArray ()  #####
' ############################################
'
' error = XgrSetGridCharacterMapArray (grid, @map[])
'
' See: XgrGetGridCharacterMapArray()
'
FUNCTION  XgrSetGridCharacterMapArray (grid, map[])
	SHARED  charMap[]
'
	whomask = ##WHOMASK
'
' grid = 0 sets default character map array, so grid # 0 is a valid grid #
'
	IF grid THEN
		IF InvalidGrid (grid) THEN
			IF ##XBDV THEN PRINT "XgrSetGridCharacterMapArray() : invalid grid #"; grid
			RETURN ($$TRUE)
		END IF
	END IF
'
	u = UBOUND (charMap[])								' how big is char map array
	IF (u < grid) THEN										' if not big enough for this grid
		u = (grid + 0xFF) OR 0xFF						' make new charMap[] upper bound higher
		##WHOMASK = 0												'
		DIM charMap[u,]											' increase charMap[] upper bound
		##WHOMASK = whomask									'
	END IF
'
	ATTACH charMap[grid,] TO temp[]				' remove existing map array
	DIM temp[]														' default = not char map array
'
	IF map[] THEN													' if defining a char map array
		u = UBOUND (map[])									' how many elements
		IF (u < 255) THEN u = 255						' at least 255
		##WHOMASK = 0												'
		DIM temp[u]													' create new char map array
		##WHOMASK = whomask									'
		FOR i = 0 TO u											' for all characters
			temp[i] = i												' default char is itself
		NEXT i															'
		u = UBOUND (map[])									' upper map array element
		FOR i = 0 TO u											' for all map array elements
			temp[i] = map[i]									' transfer char map char
		NEXT i															'
		ATTACH temp[] TO charMap[grid,]			' install new char map array
	END IF																'
END FUNCTION
'
'
' #############################
' #####  XgrClearGrid ()  #####
' #############################
'
' error = XgrClearGrid (grid, color)
'
' color values range from $$Black = 0 to $$White = 124 (see xgr.dec)
'
' If the color is -1 the grids background color will be used.
'
' See: XgrSetBackgroundColor(), XgrSetBackgroundRGB(), XgrSetColors(), XgrSetGridColors()
'
FUNCTION  XgrClearGrid (grid, color)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrClearGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrClearGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	width = window[window].width
	height = window[window].height
	buffer = window[window].buffer
	swindow = window[window].swindow
	display = window[window].display
	colormap = display[display].colormap
	sdisplay = display[display].sdisplay
	sbackground = window[window].sbackground
	sforeground = window[window].sforeground
	scolor = sbackground
	xcolor = color
'
	IF (color = $$DefaultColor) THEN color = window[window].backgroundColor
	ConvertColorToSystemColor (window, color, @scolor)
'
	IF buffer THEN
		bx1 = 0
		by1 = 0
		bwidth = window[buffer].width
		bheight = window[buffer].height
		sbuffer = window[buffer].swindow
	END IF
'
	IF (scolor = sforeground) THEN
		##WHOMASK = 0
		##LOCKOUT = 100058
		XFillRectangle (sdisplay, swindow, gc, 0, 0, width, height)
		IF sbuffer THEN XFillRectangle (sdisplay, sbuffer, gc, bx1, by1, bwidth, bheight)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	ELSE
		##WHOMASK = 0
		##LOCKOUT = 100059
		XSetForeground (sdisplay, gc, scolor)
		XFillRectangle (sdisplay, swindow, gc, 0, 0, width, height)
		IF sbuffer THEN XFillRectangle (sdisplay, sbuffer, gc, bx1, by1, bwidth, bheight)
		XSetForeground (sdisplay, gc, sforeground)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
END FUNCTION
'
'
' ###############################
' #####  XgrClearWindow ()  #####
' ###############################
'
' error = XgrClearWindow (window, color)
'
' color values range from $$Black = 0 to $$White = 124 (see xgr.dec)
'
' If the color is -1 the default background color will be used.
'
' See: XgrSetDefaultColors()
'
FUNCTION  XgrClearWindow (window, color)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrClearWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrClearWindow() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	grid = window
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	width = window[window].width
	height = window[window].height
	buffer = window[window].buffer
	swindow = window[window].swindow
	display = window[window].display
	colormap = display[display].colormap
	sdisplay = display[display].sdisplay
	sbackground = window[window].sbackground
	sforeground = window[window].sforeground
	scolor = sbackground
'
	IF (color = $$DefaultColor) THEN color = window[window].backgroundColor
	ConvertColorToSystemColor (grid, color, @scolor)
	window[window].sbackground = scolor
'
	IF buffer THEN
		bx1 = 0
		by1 = 0
		bwidth = window[buffer].width
		bheight = window[buffer].height
		sbuffer = window[buffer].swindow
	END IF
'
	IF (scolor = sforeground) THEN
		##WHOMASK = 0
		##LOCKOUT = 100060
		XFillRectangle (sdisplay, swindow, gc, 0, 0, width, height)
		IF sbuffer THEN XFillRectangle (sdisplay, sbuffer, gc, bx1, by1, bwidth, bheight)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	ELSE
		##WHOMASK = 0
		##LOCKOUT = 100061
		XSetForeground (sdisplay, gc, scolor)
		XFillRectangle (sdisplay, swindow, gc, 0, 0, width, height)
		IF sbuffer THEN XFillRectangle (sdisplay, sbuffer, gc, bx1, by1, bwidth, bheight)
		XSetForeground (sdisplay, gc, sforeground)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' ###########################
' #####  XgrDrawArc ()  #####
' ###########################
'
' startRadians# = startDegrees * $$DEGTORAD
' endRadians#   = endDegrees   * $$DEGTORAD
'
'	error = XgrDrawArc (grid, color, radius, startRadians#, endRadians#)
'
FUNCTION  XgrDrawArc (grid, color, r, startAngle#, endAngle#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawArc()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawArc() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	x = window[window].drawpointX				' drawpoint is center of curvature
	y = window[window].drawpointY				' ditto
	x1 = x - r
	y1 = y - r
	x2 = x + r
	y2 = y + r
'
	IF (x2 < x1) THEN SWAP x1, x2
	IF (y2 < y1) THEN SWAP y1, y2
	ww = x2 - x1
	hh = y2 - y1
'
	NormalAngle (@startAngle#)
	NormalAngle (@endAngle#)
'
	IF (endAngle# < startAngle#) THEN endAngle# = endAngle# + $$TWOPI
	deltaAngle# = endAngle# - startAngle#
'
	startAngle = startAngle# * $$RADTODEG * 64#
	deltaAngle = deltaAngle# * $$RADTODEG * 64#
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, @bx2, @by2)
		bwidth = bx2 - bx1 + 1
		bheight = by2 - by1 + 1
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100062
	XDrawArc (sdisplay, swindow, gc, x1, y1, ww, hh, startAngle, deltaAngle)
	IF sbuffer THEN XDrawArc (sdisplay, sbuffer, gc, bx1, by1, bwidth, bheight, startAngle, deltaAngle)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ###############################
' #####  XgrDrawArcGrid ()  #####
' ###############################
'
' startRadians# = startDegrees * $$DEGTORAD
' endRadians#   = endDegrees   * $$DEGTORAD
'
' error = XgrDrawArcGrid (grid, color, r, startRadians#, endRadians#)
'
FUNCTION  XgrDrawArcGrid (grid, color, r, startAngle#, endAngle#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawArcGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawArcGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	xGrid = window[window].drawpointGridX
	yGrid = window[window].drawpointGridY
'
	XgrConvertGridToLocal (window, xGrid, yGrid, @x, @y)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	window[window].drawpointX = x
	window[window].drawpointY = y
'
	return = XgrDrawArc (grid, color, r, startAngle#, endAngle#)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' #################################
' #####  XgrDrawArcScaled ()  #####
' #################################
'
' startRadians# = startDegrees * $$DEGTORAD
' endRadians#   = endDegrees   * $$DEGTORAD
'
' error = XgrDrawArcScaled (grid, color, r#, startRadians#, endRadians#)
'
FUNCTION  XgrDrawArcScaled (grid, color, r#, startAngle#, endAndge#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawArcScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawArcGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	x# = window[window].drawpointScaledX
	y# = window[window].drawpointScaledY
'
	XgrConvertScaledToLocal (window, x#, y#, @x, @y)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	window[window].drawpointX = x
	window[window].drawpointY = y
'
	return = XgrDrawArc (grid, color, r, startAngle#, endAngle#)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' ##############################
' #####  XgrDrawBorder ()  #####
' ##############################
'
' error = XgrDrawBorder (grid, border, back, lo, hi, x1, y1, x2, y2)
'
' grid         = target grid
' border       = border style from xgr.dec  *****  grid border styles  *****
' back, lo, hi = colors used to give visual effects as when a push button is pressed or released
' x1           = border frame left side position in pixels
' y1           = border frame top edge position in pixels
' x2           = border frame right side position in pixels
' y2           = border frame bottom edge position in pixels
'
FUNCTION  XgrDrawBorder (grid, border, back, lo, hi, x1, y1, x2, y2)
	SHARED  WINDOW  window[]
	SHARED  border$[]
	STATIC  points[]
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawBorder()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawBorder() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	upper = UBOUND (border$[])
	IFZ points[] THEN GOSUB Initialize
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
	lot = window[window].lowtextColor
	hit = window[window].hightextColor
	IF (lo = -1) THEN lo = window[window].lowlightColor
	IF (hi = -1) THEN hi = window[window].highlightColor
	IF (back = -1) THEN back = window[window].backgroundColor
	IF ((border < 0) OR (border > $$BorderUpper)) THEN border = window[window].border
'
	IF ((border < 0) OR (border > upper)) THEN
		func = border
		valid = $$FALSE
		IF ((func > ##CODE) AND (func < ##CODEZ)) THEN valid = $$TRUE
		IF ((func > ##UCODE) AND (func < ##UCODEZ)) THEN valid = $$TRUE
		IF valid THEN return = @func (window, border, back, lo, hi, x1, y1, x2, y2)
		window[window].drawpointX = xx
		window[window].drawpointY = yy
		RETURN (return)
	END IF
'
	return = $$FALSE
	IF (border == $$BorderNone) THEN RETURN return
	XgrGetGridDrawingMode (grid, @drawMode, @lineStyle, @lineWidth)   ' save drawing mode
	XgrSetGridDrawingMode (grid, $$DrawModeSET, $$LineStyleSolid, 0)  ' 0 for "thin line"
'
	SELECT CASE border
		CASE $$BorderFlat1																			: GOSUB Flat1
		CASE $$BorderFlat2																			: GOSUB Flat2
		CASE $$BorderFlat4																			: GOSUB Flat4
		CASE $$BorderHiLine1	: lo = hi													: GOSUB Raise1
		CASE $$BorderHiLine2	: lo = hi													: GOSUB Raise2
		CASE $$BorderHiLine4	: lo = hi													: GOSUB Raise4
		CASE $$BorderLoLine1	: hi = lo													: GOSUB Raise1
		CASE $$BorderLoLine2	: hi = lo													: GOSUB Raise2
		CASE $$BorderLoLine4	: hi = lo													: GOSUB Raise4
		CASE $$BorderLower1		: SWAP hi, lo											: GOSUB Raise1
		CASE $$BorderLower2		: SWAP hi, lo											: GOSUB Raise2
		CASE $$BorderLower4		: SWAP hi, lo											: GOSUB Raise4
		CASE $$BorderRaise1																			: GOSUB Raise1
		CASE $$BorderRaise2																			: GOSUB Raise2
		CASE $$BorderRaise4																			: GOSUB Raise4
		CASE $$BorderFrame																			: GOSUB Frame
		CASE $$BorderDrain		: SWAP hi, lo											: GOSUB Frame
		CASE $$BorderRidge																			: GOSUB Ridge
		CASE $$BorderValley																			: GOSUB Valley
		CASE $$BorderWide																				: GOSUB Wide
		CASE $$BorderWideResize																	: GOSUB WideResize
		CASE $$BorderWindow																			: GOSUB Window
		CASE $$BorderWindowResize																: GOSUB WindowResize
		CASE $$BorderRise2																			: GOSUB DrawBorderRise2
		CASE $$BorderSink2		: SWAP hi, lo		: SWAP hit, lot		: GOSUB DrawBorderRise2
	END SELECT
'
	XgrSetGridDrawingMode (grid, drawMode, lineStyle, lineWidth)  ' restore drawing mode
	window[window].drawpointX = xx                                ' restore drawpoint
	window[window].drawpointY = yy                                ' ditto
	RETURN (return)
'
'
' *****  Flat1  *****  Flat
'
SUB Flat1
	hi	= back
	lo	= back
	GOSUB DrawBorder1
END SUB
'
'
' *****  Flat2  *****  Flat2
'
SUB Flat2
	hi	= back
	lo	= back
	n		= 2
	GOSUB DrawBorderN
END SUB
'
'
' *****  Flat4  *****  Flat4
'
SUB Flat4
	hi	= back
	lo	= back
	n		= 4
	GOSUB DrawBorderN
END SUB
'
'
' *****  Raise1  *****  Up = 1
'
SUB Raise1
	GOSUB DrawBorder1
END SUB
'
'
' *****  Raise2  *****  Up = 2
'
SUB Raise2
	n		= 2
	GOSUB DrawBorderN
END SUB
'
'
' *****  Raise4  *****  Up = 4
'
SUB Raise4
	n		= 4
	GOSUB DrawBorderN
END SUB
'
'
' *****  Frame  *****  Up = 1, Flat = width-2, Down = 1  *****
'
SUB Frame
	GOSUB DrawBorder1												' draw up-slope outside
	xhi	= hi
	xlo	= lo
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= back															' flat
	lo	= back															' flat
	n		= 2																	' flat is 2 pixels wide
	GOSUB DrawBorderN												' draw flat
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= xlo																' reverse hi : lo
	lo	= xhi																' reverse hi : lo
	GOSUB DrawBorder1												' draw down-slope inside
END SUB
'
'
' *****  Ridge  *****  Looks simple, to draw is complex
'
SUB Ridge
	points[0] = x1 + 1	: points[1] = y2				' Line 0
	points[2] = x1 + 1	: points[3] = y1 + 1
	points[4] = x1 + 1	: points[5] = y1 + 1		' Line 1
	points[6] = x2			: points[7] = y1 + 1
	points[8] = x2			: points[9] = y1 + 1		' Line 2
	points[10] = x2			: points[11] = y2
	points[12] = x2			: points[13] = y2				' Line 3
	points[14] = x1 + 1	: points[15] = y2
	XgrDrawLines (window, lo, 0, 4, @points[])
	points[0] = x1			: points[1] = y2 - 1		' Line 0
	points[2] = x1			: points[3] = y1
	points[4] = x1			: points[5] = y1				' Line 1
	points[6] = x2 - 1	: points[7] = y1
	points[8] = x2 - 1	: points[9] = y1				' Line 2
	points[10] = x2 - 1	: points[11] = y2 - 1
	points[12] = x2 - 1	: points[13] = y2 - 1		' Line 3
	points[14] = x1			: points[15] = y2 - 1
	XgrDrawLines (window, hi, 0, 4, @points[])
END SUB
'
'
' *****  Valley  *****  Looks simple, to draw is complex
'
SUB Valley
	points[0] = x1			: points[1] = y2				' Line 0
	points[2] = x1			: points[3] = y1
	points[4] = x1			: points[5] = y1				' Line 1
	points[6] = x2			: points[7] = y1
	points[8] = x2 - 1	: points[9] = y1 + 2		' Line 2
	points[10] = x2 - 1	: points[11] = y2 - 1
	points[12] = x2 - 1	: points[13] = y2 - 1		' Line 3
	points[14] = x1 + 2	: points[15] = y2 - 1
	XgrDrawLines (window, lo, 0, 4, @points[])
	points[0] = x1 + 1	: points[1] = y2				' Line 0
	points[2] = x1 + 1	: points[3] = y1 + 1
	points[4] = x1 + 1	: points[5] = y1 + 1		' Line 1
	points[6] = x2			: points[7] = y1 + 1
	points[8] = x2			: points[9] = y1 + 1		' Line 2
	points[10] = x2			: points[11] = y2
	points[12] = x2			: points[13] = y2				' Line 3
	points[14] = x1 + 1	: points[15] = y2
	XgrDrawLines (window, hi, 0, 4, @points[])
END SUB
'
'
' *****  Wide  *****  up = 1, flat = 4, down = 1
'
SUB Wide
	GOSUB DrawBorder1												' draw up-slope outside
	xhi	= hi
	xlo	= lo
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= back															' flat
	lo	= back															' flat
	n		= 4																	' flat is 4 pixels wide
	GOSUB DrawBorderN												' draw flat
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= xlo																' reverse hi : lo
	lo	= xhi																' reverse hi : lo
	GOSUB DrawBorder1												' draw down-slope inside
END SUB
'
'
' *****  WideResize  *****  up = 1, flat = 4, down = 1, resize corner marks
'
SUB WideResize
	xx1 = x1 : yy1 = y1
	xx2 = x2 : yy2 = y2
	GOSUB Wide
'
' draw resize corner marks - 8 dark marks, then 8 light marks
'
	lo = xlo : hi = xhi
	x1 = xx1 : y1 = yy1
	x2 = xx2 : y2 = yy2
	points[0] = x1+25		: points[1] = y1+1
	points[2] = x1+25		: points[3] = y1+4
	points[4] = x2-26		: points[5] = y1+1
	points[6] = x2-26		: points[7] = y1+4
	points[8] = x2-4		: points[9] = y1+25
	points[10] = x2-1		: points[11] = y1+25
	points[12] = x2-4		: points[13] = y2-26
	points[14] = x2-1		: points[15] = y2-26
	points[16] = x2-26	: points[17] = y2-1
	points[18] = x2-26	: points[19] = y2-4
	points[20] = x1+25	: points[21] = y2-1
	points[22] = x1+25	: points[23] = y2-4
	points[24] = x1+1		: points[25] = y2-26
	points[26] = x1+4		: points[27] = y2-26
	points[28] = x1+1		: points[29] = y1+25
	points[30] = x1+4		: points[31] = y1+25
	XgrDrawLines (window, lo, 0, 8, @points[])
'
	points[0] = x1+26		: points[1] = y1+1
	points[2] = x1+26		: points[3] = y1+4
	points[4] = x2-25		: points[5] = y1+1
	points[6] = x2-25		: points[7] = y1+4
	points[8] = x2-4		: points[9] = y1+26
	points[10] = x2-1		: points[11] = y1+26
	points[12] = x2-4		: points[13] = y2-25
	points[14] = x2-1		: points[15] = y2-25
	points[16] = x2-25	: points[17] = y2-4
	points[18] = x2-25	: points[19] = y2-1
	points[20] = x1+26	: points[21] = y2-4
	points[22] = x1+26	: points[23] = y2-1
	points[24] = x1+1		: points[25] = y2-25
	points[26] = x1+4		: points[27] = y2-25
	points[28] = x1+1		: points[29] = y1+26
	points[30] = x1+4		: points[31] = y1+26
	XgrDrawLines (window, hi, 0, 8, @points[])
END SUB
'
'
' *****  WindowFrame  *****
'
SUB WindowFrame
	GOSUB DrawBorder1												' draw up-slope outside
	xhi	= hi
	xlo	= lo
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= back															' flat
	lo	= back															' flat
	n		= 2																	' flat is 2 pixels wide
	GOSUB DrawBorderN												' draw flat
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= xlo																' reverse hi : lo
	lo	= xhi																' reverse hi : lo
	GOSUB DrawBorder1												' draw down-slope inside
END SUB
'
'
' *****  WindowFrameResize  *****
'
SUB WindowFrameResize
	xx1 = x1 : yy1 = y1
	xx2 = x2 : yy2 = y2
	GOSUB WindowFrame
'
' draw resize corner marks - 8 dark marks, then 8 light marks
'
	lo = xlo : hi = xhi
	x1 = xx1 : y1 = yy1
	x2 = xx2 : y2 = yy2
'
	points[0] = x1+23		: points[1] = y1+0
	points[2] = x1+23		: points[3] = y1+3
	points[4] = x2-24		: points[5] = y1+0
	points[6] = x2-24		: points[7] = y1+3
	points[8] = x2-3		: points[9] = y1+23
	points[10] = x2-0		: points[11] = y1+23
	points[12] = x2-3		: points[13] = y2-24
	points[14] = x2-0		: points[15] = y2-24
	points[16] = x2-24	: points[17] = y2-0
	points[18] = x2-24	: points[19] = y2-3
	points[20] = x1+23	: points[21] = y2-0
	points[22] = x1+23	: points[23] = y2-3
	points[24] = x1+0		: points[25] = y2-24
	points[26] = x1+3		: points[27] = y2-24
	points[28] = x1+0		: points[29] = y1+23
	points[30] = x1+3		: points[31] = y1+23
	XgrDrawLines (grid, lo, 0, 8, @points[])
'
	points[0] = x1+24		: points[1] = y1+1
	points[2] = x1+24		: points[3] = y1+2
	points[4] = x2-23		: points[5] = y1+1
	points[6] = x2-23		: points[7] = y1+2
	points[8] = x2-3		: points[9] = y1+24
	points[10] = x2-0		: points[11] = y1+24
	points[12] = x2-3		: points[13] = y2-23
	points[14] = x2-0		: points[15] = y2-23
	points[16] = x2-23	: points[17] = y2-3
	points[18] = x2-23	: points[19] = y2-0
	points[20] = x1+24	: points[21] = y2-3
	points[22] = x1+24	: points[23] = y2-0
	points[24] = x1+0		: points[25] = y2-23
	points[26] = x1+3		: points[27] = y2-23
	points[28] = x1+0		: points[29] = y1+24
	points[30] = x1+3		: points[31] = y1+24
	XgrDrawLines (grid, hi, 0, 8, @points[])
END SUB
'
'
'
' *****  Window  *****
'
SUB Window
	xx1 = x1 : yy1 = y1
	xx2 = x2 : yy2 = y2
	GOSUB WindowFrame
'
' draw title bar - bright lines then dark lines
'
	lo = xlo : hi = xhi
	x1 = xx1 : y1 = yy1
	x2 = xx2 : y2 = yy2
'
	points[0] = x1+4		: points[1] = y1+23
	points[2] = x2-4		: points[3] = y1+23
	points[4] = x2-4		: points[5] = y1+23
	points[6] = x2-4		: points[7] = y1+4
	XgrDrawLines (grid, lo, 0, 2, @points[])
'
	points[0] = x1+4		: points[1] = y1+4
	points[2] = x2-4		: points[3] = y1+4
	points[4] = x1+4		: points[5] = y1+4
	points[6] = x1+4		: points[7] = y1+23
	XgrDrawLines (grid, hi, 0, 2, @points[])
END SUB
'
'
' *****  WindowResize  *****
'
SUB WindowResize
	xx1 = x1 : yy1 = y1
	xx2 = x2 : yy2 = y2
	GOSUB WindowFrameResize
'
' draw title bar - bright lines then dark lines
'
	lo = xlo : hi = xhi
	x1 = xx1 : y1 = yy1
	x2 = xx2 : y2 = yy2
'
	points[0] = x1+4		: points[1] = y1+23
	points[2] = x2-4		: points[3] = y1+23
	points[4] = x2-4		: points[5] = y1+23
	points[6] = x2-4		: points[7] = y1+4
	XgrDrawLines (grid, lo, 0, 2, @points[])
'
	points[0] = x1+4		: points[1] = y1+4
	points[2] = x2-4		: points[3] = y1+4
	points[4] = x1+4		: points[5] = y1+4
	points[6] = x1+4		: points[7] = y1+23
	XgrDrawLines (grid, hi, 0, 2, @points[])
END SUB
'
'
' an old version of this subroutine
'
' *****  WindowOld  *****  up = 2, flat = 4, down = 2
'
SUB WindowOld
	n		= 2																	' n = 2
	GOSUB DrawBorderN												' draw up-slope outside
	xhi	= hi																'
	xlo	= lo																'
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= back															' flat
	lo	= back															' flat
	n		= 4																	' flat is 4 pixels wide
	GOSUB DrawBorderN												' draw flat
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	INC x1 : INC y1 : DEC x2 : DEC y2				' move in 1 pixel
	hi	= xlo																' reverse hi : lo
	lo	= xhi																' reverse hi : lo
	n		= 2																	'
	GOSUB DrawBorderN												' draw down-slope inside
END SUB
'
' an old version of this subroutine
'
' *****  WindowResizeOld  *****  up = 2, flat = 4, down = 2, resize marks
'
SUB WindowResizeOld
	xx1 = x1 : yy1 = y1
	xx2 = x2 : yy2 = y2
	GOSUB Window
'
' draw resize corner marks - 8 dark marks, then 8 light marks
'
	lo = xlo : hi = xhi
	x1 = xx1 : y1 = yy1
	x2 = xx2 : y2 = yy2
	points[0] = x1+25		: points[1] = y1+2
	points[2] = x1+25		: points[3] = y1+5
	points[4] = x2-26		: points[5] = y1+2
	points[6] = x2-26		: points[7] = y1+5
	points[8] = x2-5		: points[9] = y1+25
	points[10] = x2-2		: points[11] = y1+25
	points[12] = x2-5		: points[13] = y2-26
	points[14] = x2-2		: points[15] = y2-26
	points[16] = x2-26	: points[17] = y2-2
	points[18] = x2-26	: points[19] = y2-5
	points[20] = x1+25	: points[21] = y2-2
	points[22] = x1+25	: points[23] = y2-5
	points[24] = x1+2		: points[25] = y2-26
	points[26] = x1+5		: points[27] = y2-26
	points[28] = x1+2		: points[29] = y1+25
	points[30] = x1+5		: points[31] = y1+25
	XgrDrawLines (window, lo, 0, 8, @points[])
'
	points[0] = x1+26		: points[1] = y1+2
	points[2] = x1+26		: points[3] = y1+5
	points[4] = x2-25		: points[5] = y1+2
	points[6] = x2-25		: points[7] = y1+5
	points[8] = x2-5		: points[9] = y1+26
	points[10] = x2-2		: points[11] = y1+26
	points[12] = x2-5		: points[13] = y2-25
	points[14] = x2-2		: points[15] = y2-25
	points[16] = x2-25	: points[17] = y2-5
	points[18] = x2-25	: points[19] = y2-2
	points[20] = x1+26	: points[21] = y2-5
	points[22] = x1+26	: points[23] = y2-2
	points[24] = x1+2		: points[25] = y2-25
	points[26] = x1+5		: points[27] = y2-25
	points[28] = x1+2		: points[29] = y1+26
	points[30] = x1+5		: points[31] = y1+26
	XgrDrawLines (window, hi, 0, 8, @points[])
END SUB
'
'
' *****  DrawBorder1  *****  1 pixel wide border
'
SUB DrawBorder1
	points[0] = x1	: points[1] = y1		' left-edge
	points[2] = x1	: points[3] = y2
	points[4] = x1	: points[5] = y1		' top-edge
	points[6] = x2	: points[7] = y1
	XgrDrawLines (window, hi, 0, 2, @points[])
	points[0] = x2	: points[1] = y1		' right-edge
	points[2] = x2	: points[3] = y2
	points[4] = x1	: points[5] = y2		' bottom-edge
	points[6] = x2	: points[7] = y2
	XgrDrawLines (window, lo, 0, 2, @points[])
END SUB
'
'
' *****  DrawBorderN  *****  n pixel wide border - max 4 pixels wide
'
SUB DrawBorderN
	j = 0
	FOR i = 0 TO n - 1
		points[j    ] = x1 + i	: points[j + 1] = y2 - i			' left
		points[j + 2] = x1 + i	: points[j + 3] = y1 + i
		points[j + 4] = x1 + i	: points[j + 5] = y1 + i			' upper
		points[j + 6] = x2 - i	: points[j + 7] = y1 + i
		j = j + 8
	NEXT i
	XgrDrawLines (window, hi, 0, (n << 1), @points[])
	j = 0
	FOR i = 0 TO n - 1
		points[j    ] = x1 + i	: points[j + 1] = y2 - i			' right
		points[j + 2] = x2 - i	: points[j + 3] = y2 - i
		points[j + 4] = x2 - i	: points[j + 5] = y2 - i			' lower
		points[j + 6] = x2 - i	: points[j + 7] = y1 + i
		j = j + 8
	NEXT i
	XgrDrawLines (window, lo, 0, (n << 1), @points[])
END SUB
'
'
' *****  DrawBorderRise2  *****  2 pixel wide border with 2 dark and 2 bright colors
'
SUB DrawBorderRise2
	points[0] = x1		: points[1] = y1		' left-edge
	points[2] = x1		: points[3] = y2
	points[4] = x1		: points[5] = y1		' top-edge
	points[6] = x2		: points[7] = y1
	XgrDrawLines (grid, hi, 0, 2, @points[])
	points[0] = x1+1	: points[1] = y1+1	' left-edge
	points[2] = x1+1	: points[3] = y2-2
	points[4] = x1+1	: points[5] = y1+1	' top-edge
	points[6] = x2-2	: points[7] = y1+1
	XgrDrawLines (grid, hit, 0, 2, @points[])
'
	points[0] = x2		: points[1] = y1			' right-edge
	points[2] = x2		: points[3] = y2
	points[4] = x1		: points[5] = y2			' bottom-edge
	points[6] = x2		: points[7] = y2
	XgrDrawLines (grid, lo, 0, 2, @points[])
	points[0] = x2-1	: points[1] = y1+1		' right-edge
	points[2] = x2-1	: points[3] = y2-2
	points[4] = x1+1	: points[5] = y2-1		' bottom-edge
	points[6] = x2-1	: points[7] = y2-1
	XgrDrawLines (grid, lot, 0, 2, @points[])
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	##WHOMASK = 0
	DIM points[31]
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ##################################
' #####  XgrDrawBorderGrid ()  #####
' ##################################
'
' error = XgrDrawBorderGrid (grid, border, back, lo, hi, x1Grid, y1Grid, x2Grid, y2Grid)
'
FUNCTION  XgrDrawBorderGrid (grid, border, back, lo, hi, x1Grid, y1Grid, x2Grid, y2Grid)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawBorderGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertGridToLocal (window, x1Grid, y1Grid, @x1, @y1)
	XgrConvertGridToLocal (window, x2Grid, y2Grid, @x2, @y2)
'
	return = XgrDrawBorder (window, border, back, lo, hi, x1, y1, x2, y2)
	RETURN (return)
END FUNCTION
'
'
' ####################################
' #####  XgrDrawBorderScaled ()  #####
' ####################################
'
' error = XgrDrawBorderScaled (grid, border, back, lo, hi, x1#, y1#, x2#, y2#)
'
FUNCTION  XgrDrawBorderScaled (grid, border, back, lo, hi, x1#, y1#, x2#, y2#)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawBorderScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertScaledToLocal (window, x1#, y1#, @x1, @y1)
	XgrConvertScaledToLocal (window, x2#, y2#, @x2, @y2)
'
	return = XgrDrawBorder (window, border, back, lo, hi, x1, y1, x2, y2)
	RETURN (return)
END FUNCTION
'
'
' ###########################
' #####  XgrDrawBox ()  #####
' ###########################
'
' error = XgrDrawBox (grid, color, x1, y1, x2, y2)
'
FUNCTION  XgrDrawBox (grid, color, x1, y1, x2, y2)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawBox()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawBox() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
'	*** SVG - check order on arguments, without changing values
'
	top = y1
	bottom = y2
	IF top > bottom THEN SWAP top, bottom
	left = x1
	right = x2
	IF right < left THEN SWAP left, right
'
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, left, top, right, bottom, @bx1, @by1, @bx2, @by2)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100063
	XDrawRectangle (sdisplay, swindow, gc, left, top, right-left, bottom-top)
	IF sbuffer THEN XDrawRectangle (sdisplay, sbuffer, gc, bx1, by1, bx2-bx1, by2-by1)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###############################
' #####  XgrDrawBoxGrid ()  #####
' ###############################
'
' error = XgrDrawBoxGrid (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
'
FUNCTION  XgrDrawBoxGrid (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawBoxGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawBoxGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertGridToLocal (window, x1Grid, y1Grid, @x1, @y1)
	XgrConvertGridToLocal (window, x2Grid, y2Grid, @x2, @y2)
'
	return = XgrDrawBox (window, color, x1, y1, x2, y2)
	RETURN (return)
END FUNCTION
'
'
' #################################
' #####  XgrDrawBoxScaled ()  #####
' #################################
'
' error = XgrDrawBoxScaled (grid, color, x1#, y1#, x2#, y2#)
'
FUNCTION  XgrDrawBoxScaled (grid, color, x1#, y1#, x2#, y2#)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawBoxScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawBoxGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertScaledToLocal (window, x1#, y1#, @x1, @y1)
	XgrConvertScaledToLocal (window, x2#, y2#, @x2, @y2)
'
	return = XgrDrawBox (window, color, x1, y1, x2, y2)
	RETURN (return)
END FUNCTION
'
'
' ##############################
' #####  XgrDrawCircle ()  #####
' ##############################
'
' error = XgrDrawCircle (grid, color, radius)
'
' The center of the circle will be at the current draw point.
'
' See: XgrSetDrawpoint()
'
FUNCTION  XgrDrawCircle (grid, color, r)
	' A circle is just an ellipse with equal X- and Y-radius.
	RETURN XgrDrawEllipse(grid, color, r, r)
END FUNCTION
'
'
' ##################################
' #####  XgrDrawCircleGrid ()  #####
' ##################################
'
' error = XgrDrawCircleGrid (grid, color, radius)
'
' The center of the circle will be at the current draw point for the grid.
'
' See: XgrSetDrawpointGrid()
'
FUNCTION  XgrDrawCircleGrid (grid, color, r)
	RETURN XgrDrawEllipseGrid(grid, color, r, r)
END FUNCTION
'
'
' ####################################
' #####  XgrDrawCircleScaled ()  #####
' ####################################
'
' error = XgrDrawCircleScaled (grid, color, radius#)
'
' The center of the circle will be at the current draw point scaled.
'
' See: XgrSetDrawpointScaled()
'
FUNCTION  XgrDrawCircleScaled (grid, color, r#)
	RETURN XgrDrawEllipseScaled(grid, color, r#, r#)
END FUNCTION
'
'
' ###############################
' #####  XgrDrawEllipse ()  #####
' ###############################
'
' error XgrDrawEllipse (grid, color, rx, ry)
'
'* Draw an ellipse.
' Note: The current drawing-point is used as the center of the ellipse.
'    grid			The grid
'    color		The color in which to draw
'    rx				The X-Radius
'    ry				The Y-Radius
'
' See: XgrSetDrawpoint()
'
FUNCTION  XgrDrawEllipse (grid, color, rx, ry)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawEllipse()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawEllipse() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	buffer = window[window].buffer
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	x = window[window].drawpointX			' drawpoint is center of curvature
	y = window[window].drawpointY			' ditto
	x1 = x - rx
	y1 = y - ry
	x2 = x + rx
	y2 = y + ry
'
	IF (x2 < x1) THEN SWAP x1, x2
	IF (y2 < y1) THEN SWAP y1, y2
	ww = x2 - x1
	hh = y2 - y1
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, 0, 0)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100064
	XDrawArc (sdisplay, swindow, gc, x1, y1, ww, hh, 0, 23040)
	IF sbuffer THEN XDrawArc (sdisplay, sbuffer, gc, bx1, by1, ww, hh, 0, 23040)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###################################
' #####  XgrDrawEllipseGrid ()  #####
' ###################################
'
' error = XgrDrawEllipseGrid (grid, color, rx, ry)
'
'* Draw an ellipse.
' Note: The current grid drawing-point is used as the center of the ellipse.
'    grid			The grid
'    color		The color in which to draw
'    rx				The X-Radius
'    ry				The Y-Radius
'
' See: XgrSetDrawpointGrid()
'
FUNCTION  XgrDrawEllipseGrid (grid, color, rx, ry)
'
	IF InvalidGrid (grid) THEN RETURN ($$TRUE)
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointGrid (grid, @xxGrid, @yyGrid)
	XgrConvertGridToLocal (grid, xxGrid, yyGrid, @x, @y)
	XgrSetDrawpoint (grid, x, y)
	XgrDrawEllipse (grid, color, rx, ry)
	XgrSetDrawpoint (grid, xx, yy)
END FUNCTION
'
'
' #####################################
' #####  XgrDrawEllipseScaled ()  #####
' #####################################
'
' error = XgrDrawEllipseScaled (grid, color, rx#, ry#)
'
'* Draw an ellipse.
' Note: The current scaled drawing-point is used as the center of the ellipse.
'    grid			The grid
'    color		The color in which to draw
'    rx				The X-Radius
'    ry				The Y-Radius
'
' See: XgrSetDrawpointScaled()
'
FUNCTION  XgrDrawEllipseScaled (grid, color, rx#, ry#)
'
	IF InvalidGrid (grid) THEN RETURN ($$TRUE)
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointScaled (grid, @xx#, @yy#)
	XgrConvertScaledToLocal (grid, xx#, yy#, @x, @y)
	XgrConvertScaledToLocal (grid, xx# + rx#, yy# + ry#, @xr, @yr)
	xr = ABS (xr - x)
	yr = ABS (yr - y)
'
	XgrSetDrawpoint (grid, x, y)
	XgrDrawEllipse (grid, color, xr, yr)
	XgrSetDrawpoint (grid, xx, yy)
END FUNCTION
'
'
' #############################
' #####  XgrDrawCurve ()  #####
' #############################
'
' XgrDrawCurve (grid, color, segments, x0, y0, x1, y1, x2, y2, x3, y3)
'
' This function draws a Cubic Bezier curve
'
' segments is the number of lines to be used to draw the curve.
' If segments = 0, this function will create a segments number.
'
' x0, y0 is the start of the curve
' x1, y1 is the first control point
' x2, y2 is the second control point
' x3, y3 is the finish of the curve
'
' The draw point is set to the finish of the curve
'
FUNCTION  XgrDrawCurve (grid, color, segments, x0, y0, x1, y1, x2, y2, x3, y3)
	SINGLE  t, segmentCount
	SINGLE  tt, ttt, u, uu, uuu
	SINGLE  xs, xs0, xs1, xs2, xs3
	SINGLE  ys, ys0, ys1, ys2, ys3

	xs0 = x0
	ys0 = y0
	xs1 = x1
	ys1 = y1
	xs2 = x2
	ys2 = y2
	xs3 = x3
	ys3 = y3

	IF segments THEN
		segmentCount = segments
	ELSE
		xMin = x0
		xMax = x0
		IF (x1 < xMin) THEN xMin = x1
		IF (x1 > xMax) THEN xMax = x1
		IF (x2 < xMin) THEN xMin = x2
		IF (x2 > xMax) THEN xMax = x2
		IF (x3 < xMin) THEN xMin = x3
		IF (x3 > xMax) THEN xMax = x3
		yMin = y0
		yMax = y0
		IF (y1 < yMin) THEN yMin = y1
		IF (y1 > yMax) THEN yMax = y1
		IF (y2 < yMin) THEN yMin = y2
		IF (y2 > yMax) THEN yMax = y2
		IF (y3 < yMin) THEN yMin = y3
		IF (y3 > yMax) THEN yMax = y3
		segmentCount = (xMax -xMin + yMax - yMin) / 2
	END IF
'
	linesUpper = (segmentCount * 2) -1
	DIM lines[linesUpper]
	linesCount = 0



	xOld = x0
	yOld = y0
'
	FOR i = 1 TO segmentCount-1
		t = i / segmentCount
		GOSUB CalculatBezierPoint
		lines[linesCount] = xs : INC linesCount
		lines[linesCount] = ys : INC linesCount
	NEXT i
'
	lines[linesCount] = x3 : INC linesCount
	lines[linesCount] = y3 : INC linesCount
	XgrSetDrawpoint (grid, x0, y0)
	XgrDrawLinesTo  (grid, color, 0, segmentCount, @lines[])
'
	RETURN
'-------------------------------------------------
'
'
' *****  CalculatBezierPoint  *****
'
SUB CalculatBezierPoint

	u = 1 - t
	tt = t * t
	uu = u * u
	uuu = uu * u
	ttt = tt * t

	xs = uuu * xs0
	ys = uuu * ys0

	xs = xs + (3 * uu * t * xs1)
	ys = ys + (3 * uu * t * ys1)

	xs = xs + (3 * u * tt * xs2)
	ys = ys + (3 * u * tt * ys2)

	xs = xs + (ttt * xs3)
	ys = ys + (ttt * ys3)

END SUB
'
END FUNCTION
'
'
' #################################
' #####  XgrDrawCurveGrid ()  #####
' #################################
'
' error = XgrDrawCurveGrid (grid, color, segments, x0g, y0g, x1g, y1g, x2g, y2g, x3g, y3g)
'
' See: XgrDrawCurve()
'
FUNCTION  XgrDrawCurveGrid (grid, color, segments, x0g, y0g, x1g, y1g, x2g, y2g, x3g, y3g)
'
	IF InvalidGrid (grid) THEN RETURN ($$TRUE)
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointGrid (grid, @xGrid, @yGrid)
	XgrConvertGridToLocal (grid, xGrid, yGrid, @x, @y)

	XgrConvertGridToLocal (grid, x0g, y0g, @x0, @y0)
	XgrConvertGridToLocal (grid, x1g, y1g, @x1, @y1)
	XgrConvertGridToLocal (grid, x2g, y2g, @x2, @y2)
	XgrConvertGridToLocal (grid, x3g, y3g, @x3, @y3)

	XgrSetDrawpoint (grid, x, y)
	XgrDrawCurve (grid, color, segments, x0, y0, x1, y1, x2, y2, x3, y3)
	XgrSetDrawpoint (grid, xx, yy)
	XgrSetDrawpointGrid (grid, x3g, y3g)

END FUNCTION
'
'
' ###################################
' #####  XgrDrawCurveScaled ()  #####
' ###################################
'
' error = XgrDrawCurveScaled (grid, color, segments, x0#, y0#, x1#, y1#, x2#, y2#, x3#, y3#)
'
' See: XgrDrawCurve()
'
FUNCTION  XgrDrawCurveScaled (grid, color, segments, x0#, y0#, x1#, y1#, x2#, y2#, x3#, y3#)
'
	IF InvalidGrid (grid) THEN RETURN ($$TRUE)
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointScaled (grid, @x#, @y#)
	XgrConvertScaledToLocal (grid, x#, y#, @x, @y)

	XgrConvertScaledToLocal (grid, x0#, y0#, @x0, @y0)
	XgrConvertScaledToLocal (grid, x1#, y1#, @x1, @y1)
	XgrConvertScaledToLocal (grid, x2#, y2#, @x2, @y2)
	XgrConvertScaledToLocal (grid, x3#, y3#, @x3, @y3)

	XgrSetDrawpoint (grid, x, y)
	XgrDrawCurve (grid, color, segments, x0, y0, x1, y1, x2, y2, x3, y3)
	XgrSetDrawpoint (grid, xx, yy)
	XgrSetDrawpointScaled (grid, x3#, y3#)

END FUNCTION
'
'
' ##################################
' #####  XgrDrawGridBorder ()  #####
' ##################################
'
' error = XgrDrawGridBorder (grid, border)
'
' See: XgrSetColors()
'
FUNCTION  XgrDrawGridBorder (grid, border)
	SHARED  WINDOW  window[]
	SHARED  border$[]
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawGridBorder() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	low = window[window].lowlightColor
	high = window[window].highlightColor
	back = window[window].backgroundColor
	IF (border = -1) THEN border = window[window].border
'
	x1 = 0
	y1 = 0
	x2 = window[window].width - 1
	y2 = window[window].height - 1
'
	upper = UBOUND (border$[])
	IF ((border >= 0) AND (border <= upper)) THEN
		return = XgrDrawBorder (window, border, back, low, high, x1, y1, x2, y2)
	ELSE
		func = border
		valid = $$FALSE
		IF ((func > ##CODE) AND (func < ##CODEZ)) THEN valid = $$TRUE
		IF ((func > ##UCODE) AND (func < ##UCODEZ)) THEN valid = $$TRUE
		IF valid THEN return = @func (window, border, back, low, high, x1, y1, x2, y2)
	END IF
	RETURN (return)
END FUNCTION
'
'
' ############################
' #####  XgrDrawLine ()  #####
' ############################
'
' error = XgrDrawLine (grid, color, x1, y1, x2, y2)
'
FUNCTION  XgrDrawLine (grid, color, x1, y1, x2, y2)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLine()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLine() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	window[window].drawpointX = x2
	window[window].drawpointY = y2
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, @bx2, @by2)
'		bwidth = bx2 - bx1 + 1
'		bheight = by2 - by1 + 1
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100065
	XDrawLine (sdisplay, swindow, gc, x1, y1, x2, y2)
	IF sbuffer THEN XDrawLine (sdisplay, sbuffer, gc, bx1, by1, bx2, by2)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ################################
' #####  XgrDrawLineGrid ()  #####
' ################################
'
' error = XgrDrawLineGrid (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
'
FUNCTION  XgrDrawLineGrid (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointGridX = x2Grid
	window[window].drawpointGridY = y2Grid
'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertGridToLocal (window, x1Grid, y1Grid, @x1, @y1)
	XgrConvertGridToLocal (window, x2Grid, y2Grid, @x2, @y2)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	window[window].drawpointX = x
	window[window].drawpointY = y
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' ##################################
' #####  XgrDrawLineScaled ()  #####
' ##################################
'
' error = XgrDrawLineScaled (grid, color, x1#, y1#, x2#, y2#)
'
FUNCTION  XgrDrawLineScaled (grid, color, x1#, y1#, x2#, y2#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointScaledX = x2#
	window[window].drawpointScaledY = y2#
'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertScaledToLocal (window, x1#, y1#, @x1, @y1)
	XgrConvertScaledToLocal (window, x2#, y2#, @x2, @y2)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	window[window].drawpointX = x
	window[window].drawpointY = y
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' ##############################
' #####  XgrDrawLineTo ()  #####
' ##############################
'
' error = XgrDrawLineTo (grid, color, x2, y2)
'
' Draws a line from the current draw point to x2, y2
' The current draw point is set to x2, y2
'
FUNCTION  XgrDrawLineTo (grid, color, x2, y2)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineTo()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineTo() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
'
	x1 = window[window].drawpointX
	y1 = window[window].drawpointY
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
	RETURN (return)
END FUNCTION
'
'
' ##################################
' #####  XgrDrawLineToGrid ()  #####
' ##################################
'
' error = XgrDrawLineToGrid (grid, color, x2Grid, y2Grid)
'
' Draws a line from the current draw point to x2Grid, y2Grid
' The current draw point is set to x2Grid, y2Grid
'
FUNCTION  XgrDrawLineToGrid (grid, color, x2Grid, y2Grid)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineToGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineToGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
'
	x1Grid = window[window].drawpointGridX
	y1Grid = window[window].drawpointGridY
	window[window].drawpointGridX = x2Grid
	window[window].drawpointGridY = y2Grid
'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertGridToLocal (window, x1Grid, y1Grid, @x1, @y1)
	XgrConvertGridToLocal (window, x2Grid, y2Grid, @x2, @y2)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' ####################################
' #####  XgrDrawLineToScaled ()  #####
' ####################################
'
' error = XgrDrawLineToScaled (grid, color, x2#, y2#)
'
' Draws a line from the current draw point to x2#, y2#
' The current draw point is set to x2#, y2#
'
FUNCTION  XgrDrawLineToScaled (grid, color, x2#, y2#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineToScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineToScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
'
	x1# = window[window].drawpointScaledX
	y1# = window[window].drawpointScaledY
	window[window].drawpointScaledX = x2#
	window[window].drawpointScaledY = y2#
'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	IF ##CW THEN PRINT "XgrDrawLineToScaled(35)", x1#, y1#
	XgrConvertScaledToLocal (window, x1#, y1#, @x1, @y1)
	IF ##CW THEN PRINT "XgrDrawLineToScaled(35)", x1, y1
	XgrConvertScaledToLocal (window, x2#, y2#, @x2, @y2)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' ###################################
' #####  XgrDrawLineToDelta ()  #####
' ###################################
'
' error = XgrDrawLineToDelta (grid, color, dx, dy)
'
' Draws a line from the current draw point to a new point
' moved by the amount of dx, dy.
'
FUNCTION  XgrDrawLineToDelta (grid, color, dx, dy)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineToDelta()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineToDelta() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
'
	x1 = window[window].drawpointX
	y1 = window[window].drawpointY
	x2 = x1 + dx
	y2 = y1 + dy
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
	RETURN (return)
END FUNCTION
'
'
' #######################################
' #####  XgrDrawLineToDeltaGrid ()  #####
' #######################################
'
' error = XgrDrawLineToDeltaGrid (grid, color, dxGrid, dyGrid)
'
' Draws a line from the current draw point to a new point
' moved by the amount of dxGrid, dyGrid.
'
FUNCTION  XgrDrawLineToDeltaGrid (grid, color, dxGrid, dyGrid)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineToDeltaGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineToDeltaGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
'
	x1Grid = window[window].drawpointGridX
	y1Grid = window[window].drawpointGridY
	x2Grid = x1Grid + dxGrid
	y2Grid = y1Grid + dyGrid
	window[window].drawpointGridX = x2Grid
	window[window].drawpointGridY = y2Grid
'
	XgrConvertGridToLocal (window, x1Grid, y1Grid, @x1, @y1)
	XgrConvertGridToLocal (window, x2Grid, y2Grid, @x2, @y2)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' #########################################
' #####  XgrDrawLineToDeltaScaled ()  #####
' #########################################
'
' error = XgrDrawLineToDeltaScaled (grid, color, dx#, dy#)
'
' Draws a line from the current draw point to a new point
' moved by the amount of dx#, dy#.
'
FUNCTION  XgrDrawLineToDeltaScaled (grid, color, dx#, dy#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLineToDeltaScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLineToDeltaScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
'
	x1# = window[window].drawpointScaledX
	y1# = window[window].drawpointScaledY
	x2# = x1# + dx#
	y2# = y1# + dy#
	window[window].drawpointScaledX = x2#
	window[window].drawpointScaledY = y2#
'
	XgrConvertScaledToLocal (window, x1#, y1#, @x1, @y1)
	XgrConvertScaledToLocal (window, x2#, y2#, @x2, @y2)
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
'
	return = XgrDrawLine (window, color, x1, y1, x2, y2)
'
	window[window].drawpointX = xx
	window[window].drawpointY = yy
	RETURN (return)
END FUNCTION
'
'
' #############################
' #####  XgrDrawLines ()  #####
' #############################
'
' error = XgrDrawLines (grid, color, start, count, @line[])
'
FUNCTION  XgrDrawLines (grid, color, start, count, line[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLines()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLines() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ line[] THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (line[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawLines() : invalid line[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of lines
'
	first = start << 2												' each line is 4 array elements
	upper = UBOUND (line[])										' upper bound of line[] array
	IF (first < 0) THEN first = 0							' < 0 means start at 0
	IF (count < 0) THEN count = upper					' < 0 means to upper bound
	IF (first > upper) THEN RETURN ($$FALSE)	' first is already beyond array
	past = first + (count << 2)								' past = requested last+1
	IF (past > upper) THEN past = upper + 1		' keep in bounds
	points = (past - first)										'
	count = points >> 2												' # of lines at 4 points per line
	points = count << 1												' points is now a multiple of 2
	elements = points << 1										' array elements is 4 * line count
	IFZ count THEN RETURN ($$FALSE)						' not enough elements in array
'
	n = 0
	slot = 0
	bslot = 0
	bcount = 0
	i = first
	addr = &line[]
'
	##WHOMASK = 0
	DIM segment[elements]							' array of SSHORT coords for X
	IF buffer DIM buffer[elements]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
	DO
		INC n
		SELECT CASE type
			CASE $$XLONG		: x1 = XLONGAT (addr, [i])		: INC i
												y1 = XLONGAT (addr, [i])		: INC i
												x2 = XLONGAT (addr, [i])		: INC i
												y2 = XLONGAT (addr, [i])		: INC i
			CASE $$SBYTE		: x1 = SBYTEAT (addr, [i])		: INC i
												y1 = SBYTEAT (addr, [i])		: INC i
												x2 = SBYTEAT (addr, [i])		: INC i
												y2 = SBYTEAT (addr, [i])		: INC i
			CASE $$UBYTE		: x1 = UBYTEAT (addr, [i])		: INC i
												y1 = UBYTEAT (addr, [i])		: INC i
												x2 = UBYTEAT (addr, [i])		: INC i
												y2 = UBYTEAT (addr, [i])		: INC i
			CASE $$SSHORT		: x1 = SSHORTAT (addr, [i])		: INC i
												y1 = SSHORTAT (addr, [i])		: INC i
												x2 = SSHORTAT (addr, [i])		: INC i
												y2 = SSHORTAT (addr, [i])		: INC i
			CASE $$USHORT		: x1 = USHORTAT (addr, [i])		: INC i
												y1 = USHORTAT (addr, [i])		: INC i
												x2 = USHORTAT (addr, [i])		: INC i
												y2 = USHORTAT (addr, [i])		: INC i
			CASE $$SLONG		: x1 = SLONGAT (addr, [i])		: INC i
												y1 = SLONGAT (addr, [i])		: INC i
												x2 = SLONGAT (addr, [i])		: INC i
												y2 = SLONGAT (addr, [i])		: INC i
			CASE $$ULONG		: x1 = ULONGAT (addr, [i])		: INC i
												y1 = ULONGAT (addr, [i])		: INC i
												x2 = ULONGAT (addr, [i])		: INC i
												y2 = ULONGAT (addr, [i])		: INC i
			CASE $$GIANT		: x1 = GIANTAT (addr, [i])		: INC i
												y1 = GIANTAT (addr, [i])		: INC i
												x2 = GIANTAT (addr, [i])		: INC i
												y2 = GIANTAT (addr, [i])		: INC i
			CASE $$SINGLE		: x1 = SINGLEAT (addr, [i])		: INC i
												y1 = SINGLEAT (addr, [i])		: INC i
												x2 = SINGLEAT (addr, [i])		: INC i
												y2 = SINGLEAT (addr, [i])		: INC i
			CASE $$DOUBLE		: x1 = DOUBLEAT (addr, [i])		: INC i
												y1 = DOUBLEAT (addr, [i])		: INC i
												x2 = DOUBLEAT (addr, [i])		: INC i
												y2 = DOUBLEAT (addr, [i])		: INC i
		END SELECT
		segment[slot] = x1	: INC slot
		segment[slot] = y1	: INC slot
		segment[slot] = x2	: INC slot
		segment[slot] = y2	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, @bx2, @by2)
			IFZ (overlap AND $$RegionOutsideBufferMask) THEN
				buffer[bslot] = bx1 : INC bslot
				buffer[bslot] = by1 : INC bslot
				buffer[bslot] = bx2 : INC bslot
				buffer[bslot] = by2 : INC bslot
			END IF
		END IF
'	LOOP UNTIL (n >= points)
	LOOP UNTIL (n >= count)
	bcount = bslot >> 2
'
' final endpoint is final drawpoint
'
	window[window].drawpointX = x2
	window[window].drawpointY = y2
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100066
	XDrawSegments (sdisplay, swindow, gc, &segment[], count)
	IF bslot THEN THEN XDrawSegments (sdisplay, sbuffer, gc, &buffer[], bcount)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
END FUNCTION
'
'
' #################################
' #####  XgrDrawLinesGrid ()  #####
' #################################
'
' error = XgrDrawLinesGrid (grid, color, first, count, @line[])
'
FUNCTION  XgrDrawLinesGrid (grid, color, first, count, line[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLinesGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLinesGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ line[] THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (line[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawLinesGrid() : invalid line[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of lines
'
	first = first << 2												' each line is 4 array elements
	upper = UBOUND (line[])										' upper bound of line[] array
	IF (first < 0) THEN first = 0							' < 0 means start at 0
	IF (count < 0) THEN count = upper					' < 0 means to upper bound
	IF (first > upper) THEN RETURN ($$FALSE)	' first is already beyond array
	past = first + (count << 2)								' past = requested last+1
	IF (past > upper) THEN past = upper + 1		' keep in bounds
	points = (past - first)										'
	count = points >> 2												' # of lines at 4 points per line
	points = count << 1												' points is now a multiple of 2
	elements = points << 1										' array elements is 4 * line count
	IFZ count THEN RETURN ($$FALSE)						' not enough elements in array
'
	n = 0
	slot = 0
	i = first
	addr = &line[]
'
	##WHOMASK = 0
	DIM segment[elements]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[elements]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
	DO
		INC n
		SELECT CASE type
			CASE $$XLONG		: x = XLONGAT (addr, [i])		: INC i
												y = XLONGAT (addr, [i])		: INC i
			CASE $$SBYTE		: x = SBYTEAT (addr, [i])		: INC i
												y = SBYTEAT (addr, [i])		: INC i
			CASE $$UBYTE		: x = UBYTEAT (addr, [i])		: INC i
												y = UBYTEAT (addr, [i])		: INC i
			CASE $$SSHORT		: x = SSHORTAT (addr, [i])	: INC i
												y = SSHORTAT (addr, [i])	: INC i
			CASE $$USHORT		: x = USHORTAT (addr, [i])	: INC i
												y = USHORTAT (addr, [i])	: INC i
			CASE $$SLONG		: x = SLONGAT (addr, [i])		: INC i
												y = SLONGAT (addr, [i])		: INC i
			CASE $$ULONG		: x = ULONGAT (addr, [i])		: INC i
												y = ULONGAT (addr, [i])		: INC i
			CASE $$GIANT		: x = GIANTAT (addr, [i])		: INC i
												y = GIANTAT (addr, [i])		: INC i
			CASE $$SINGLE		: x = SINGLEAT (addr, [i])	: INC i
												y = SINGLEAT (addr, [i])	: INC i
			CASE $$DOUBLE		: x = DOUBLEAT (addr, [i])	: INC i
												y = DOUBLEAT (addr, [i])	: INC i
		END SELECT
'
		XgrConvertGridToLocal (window, x, y, @xx, @yy)
		segment[slot] = xx	: INC slot
		segment[slot] = yy	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
	LOOP UNTIL (n >= points)
'
' final endpoint is final drawpoint
'
	window[window].drawpointGridX = x
	window[window].drawpointGridY = y
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100067
	XDrawSegments (sdisplay, swindow, gc, &segment[], count)
	IF sbuffer THEN XDrawSegments (sdisplay, sbuffer, gc, &buffer[], count)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###################################
' #####  XgrDrawLinesScaled ()  #####
' ###################################
'
' error = XgrDrawLinesScaled (grid, color, first, count, @line[])
'
FUNCTION  XgrDrawLinesScaled (grid, color, first, count, line[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLinesScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLinesScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ line[] THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (line[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawLinesGrid() : invalid line[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of lines
'
	first = first << 2												' each line is 4 array elements
	upper = UBOUND (line[])										' upper bound of line[] array
	IF (first < 0) THEN first = 0							' < 0 means start at 0
	IF (count < 0) THEN count = upper					' < 0 means to upper bound
	IF (first > upper) THEN RETURN ($$FALSE)	' first is already beyond array
	past = first + (count << 2)								' past = requested last+1
	IF (past > upper) THEN past = upper + 1		' keep in bounds
	points = (past - first)										'
	count = points >> 2												' # of lines at 4 points per line
	points = count << 1												' points is now a multiple of 2
	elements = points << 1										' array elements is 4 * line count
	IFZ count THEN RETURN ($$FALSE)						' not enough elements in array
'
	n = 0
	slot = 0
	i = first
	addr = &line[]
'
	##WHOMASK = 0
	DIM segment[elements]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[elements]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
	DO
		INC n
		SELECT CASE type
			CASE $$XLONG		: x# = XLONGAT (addr, [i])		: INC i
												y# = XLONGAT (addr, [i])		: INC i
			CASE $$SBYTE		: x# = SBYTEAT (addr, [i])		: INC i
												y# = SBYTEAT (addr, [i])		: INC i
			CASE $$UBYTE		: x# = UBYTEAT (addr, [i])		: INC i
												y# = UBYTEAT (addr, [i])		: INC i
			CASE $$SSHORT		: x# = SSHORTAT (addr, [i])		: INC i
												y# = SSHORTAT (addr, [i])		: INC i
			CASE $$USHORT		: x# = USHORTAT (addr, [i])		: INC i
												y# = USHORTAT (addr, [i])		: INC i
			CASE $$SLONG		: x# = SLONGAT (addr, [i])		: INC i
												y# = SLONGAT (addr, [i])		: INC i
			CASE $$ULONG		: x# = ULONGAT (addr, [i])		: INC i
												y# = ULONGAT (addr, [i])		: INC i
			CASE $$GIANT		: x# = GIANTAT (addr, [i])		: INC i
												y# = GIANTAT (addr, [i])		: INC i
			CASE $$SINGLE		: x# = SINGLEAT (addr, [i])		: INC i
												y# = SINGLEAT (addr, [i])		: INC i
			CASE $$DOUBLE		: x# = DOUBLEAT (addr, [i])		: INC i
												y# = DOUBLEAT (addr, [i])		: INC i
		END SELECT
'
		XgrConvertScaledToLocal (window, x#, y#, @xx, @yy)
		segment[slot] = xx	: INC slot
		segment[slot] = yy	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
	LOOP UNTIL (n >= points)
'
' final endpoint is final drawpoint
'
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100068
	XDrawSegments (sdisplay, swindow, gc, &segment[], count)
	IF sbuffer THEN XDrawSegments (sdisplay, sbuffer, gc, &buffer[], count)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###############################
' #####  XgrDrawLinesTo ()  #####
' ###############################
'
' error = XgrDrawLinesTo (grid, color, start, count, @line[])
'
'  start is the point number in line[] to start drawing ( 0 or less for the beginning of line[])
'  count is the number of lines to draw ( -1 means do to the end of line[])
'
FUNCTION  XgrDrawLinesTo (grid, color, start, count, line[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLinesTo()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLinesTo() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ line[] THEN RETURN ($$FALSE)
	IFZ count THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (line[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawLinesTo() : invalid line[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of lines
'
	IF (start >= 0) THEN
		i = start << 1
	ELSE
		i = 0
	END IF
	upper = UBOUND (line[])										' upper bound of line[] array
	IFZ upper THEN RETURN ($$FALSE)           ' need at least 2 entries to be a point
	IFZ (upper MOD 2) THEN DEC upper          ' must be even number of entries
	IF (i > upper) THEN RETURN ($$FALSE)	    ' first is already beyond array
'
	IF (count > 0) THEN
		IF (((start + count) << 1) < upper) THEN
			upperSlot = (count << 1) + 1
		ELSE
			upperSlot = (upper - i) + 2
		END IF
	ELSE
		upperSlot = (upper - i) + 2
	END IF
'
	slot = 0
	addr = &line[]
'
	##WHOMASK = 0
	DIM segment[upperSlot]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[upperSlot]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
' The first point for the first line is the current draw point
'
	x = window[window].drawpointX
	y = window[window].drawpointY
	segment[slot] = x	: INC slot
	segment[slot] = y	: INC slot
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
		buffer[slot-2] = bx
		buffer[slot-1] = by
	END IF

'
	DO
		SELECT CASE type
			CASE $$XLONG		: x = XLONGAT  (addr, [i])	: INC i
												y = XLONGAT  (addr, [i])	: INC i
			CASE $$SBYTE		: x = SBYTEAT  (addr, [i])	: INC i
												y = SBYTEAT  (addr, [i])	: INC i
			CASE $$UBYTE		: x = UBYTEAT  (addr, [i])	: INC i
												y = UBYTEAT  (addr, [i])	: INC i
			CASE $$SSHORT		: x = SSHORTAT (addr, [i])	: INC i
												y = SSHORTAT (addr, [i])	: INC i
			CASE $$USHORT		: x = USHORTAT (addr, [i])	: INC i
												y = USHORTAT (addr, [i])	: INC i
			CASE $$SLONG		: x = SLONGAT  (addr, [i])	: INC i
												y = SLONGAT  (addr, [i])	: INC i
			CASE $$ULONG		: x = ULONGAT  (addr, [i])	: INC i
												y = ULONGAT  (addr, [i])	: INC i
			CASE $$GIANT		: x = GIANTAT  (addr, [i])	: INC i
												y = GIANTAT  (addr, [i])	: INC i
			CASE $$SINGLE		: x = SINGLEAT (addr, [i])	: INC i
												y = SINGLEAT (addr, [i])	: INC i
			CASE $$DOUBLE		: x = DOUBLEAT (addr, [i])	: INC i
												y = DOUBLEAT (addr, [i])	: INC i
		END SELECT
		segment[slot] = x	: INC slot
		segment[slot] = y	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
	LOOP UNTIL (slot >= upperSlot)
	nSegments = (upperSlot >> 1) + 1
'
' final endpoint is final drawpoint
'
	window[window].drawpointX = x
	window[window].drawpointY = y
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100069
	XDrawLines (sdisplay, swindow, gc, &segment[], nSegments, 0)
	IF sbuffer THEN XDrawLines (sdisplay, sbuffer, gc, &buffer[], nSegments, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###################################
' #####  XgrDrawLinesToGrid ()  #####
' ###################################
'
' error = XgrDrawLinesToGrid (grid, color, start, count, @line[])
'
' See: XgrSetGridBoxGrid(), XgrSetDrawpointGrid()
'
FUNCTION  XgrDrawLinesToGrid (grid, color, start, count, line[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLinesToGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLinesToGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ line[] THEN RETURN ($$FALSE)
	IFZ count THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (line[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawLinesToGrid() : invalid line[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of lines
'
	IF (start >= 0) THEN
		i = start << 1
	ELSE
		i = 0
	END IF
	upper = UBOUND (line[])										' upper bound of line[] array
	IF (i > upper) THEN RETURN ($$FALSE)	    ' first is already beyond array
'
	IF (count > 0) THEN
		IF (((start + count) << 1) < upper) THEN
			upperSlot = (count << 1) + 1
		ELSE
			upperSlot = (upper - i) + 2
		END IF
	ELSE
		upperSlot = (upper - i) + 2
	END IF
'
	slot = 0
	addr = &line[]
'
	##WHOMASK = 0
	DIM segment[upperSlot]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[upperSlot]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
' The first point for the first line is the current draw point
'
	x = window[window].drawpointGridX
	y = window[window].drawpointGridY
		XgrConvertGridToLocal (window, x, y, @xx, @yy)
		segment[slot] = xx	: INC slot
		segment[slot] = yy	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
'
	DO
		SELECT CASE type
			CASE $$XLONG		: x = XLONGAT  (addr, [i])	: INC i
												y = XLONGAT  (addr, [i])	: INC i
			CASE $$SBYTE		: x = SBYTEAT  (addr, [i])	: INC i
												y = SBYTEAT  (addr, [i])	: INC i
			CASE $$UBYTE		: x = UBYTEAT  (addr, [i])	: INC i
												y = UBYTEAT  (addr, [i])	: INC i
			CASE $$SSHORT		: x = SSHORTAT (addr, [i])	: INC i
												y = SSHORTAT (addr, [i])	: INC i
			CASE $$USHORT		: x = USHORTAT (addr, [i])	: INC i
												y = USHORTAT (addr, [i])	: INC i
			CASE $$SLONG		: x = SLONGAT  (addr, [i])	: INC i
												y = SLONGAT  (addr, [i])	: INC i
			CASE $$ULONG		: x = ULONGAT  (addr, [i])	: INC i
												y = ULONGAT  (addr, [i])	: INC i
			CASE $$GIANT		: x = GIANTAT  (addr, [i])	: INC i
												y = GIANTAT  (addr, [i])	: INC i
			CASE $$SINGLE		: x = SINGLEAT (addr, [i])	: INC i
												y = SINGLEAT (addr, [i])	: INC i
			CASE $$DOUBLE		: x = DOUBLEAT (addr, [i])	: INC i
												y = DOUBLEAT (addr, [i])	: INC i
		END SELECT
'
		XgrConvertGridToLocal (window, x, y, @xx, @yy)
		segment[slot] = xx	: INC slot
		segment[slot] = yy	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
'	LOOP UNTIL (n >= points)         '---------------------------------------------
	LOOP UNTIL (slot >= upperSlot)
	nSegments = (upperSlot >> 1) + 1
'
' final endpoint is final drawpoint
'
	window[window].drawpointGridX = x
	window[window].drawpointGridY = y
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100070
	XDrawLines (sdisplay, swindow, gc, &segment[], nSegments, 0)
	IF sbuffer THEN XDrawLines (sdisplay, sbuffer, gc, &buffer[], nSegments, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #####################################
' #####  XgrDrawLinesToScaled ()  #####
' #####################################
'
' error = XgrDrawLinesToScaled (grid, color, start, count, @line[])
'
FUNCTION  XgrDrawLinesToScaled (grid, color, start, count, line[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawLinesToScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawLinesToScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ line[] THEN RETURN ($$FALSE)
	IFZ count THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (line[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawLinesToScaled() : invalid line[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of lines
'
	IF (start >= 0) THEN
		i = start << 1
	ELSE
		i = 0
	END IF
	upper = UBOUND (line[])										' upper bound of line[] array
	IF (i > upper) THEN RETURN ($$FALSE)	    ' first is already beyond array
'
	IF (count > 0) THEN
		IF (((start + count) << 1) < upper) THEN
			upperSlot = (count << 1) + 1
		ELSE
			upperSlot = (upper - i) + 2
		END IF
	ELSE
		upperSlot = (upper - i) + 2
	END IF
'
	slot = 0
	addr = &line[]
'
	##WHOMASK = 0
	DIM segment[upperSlot]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[upperSlot]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
' The first point for the first line is the current draw point
'
	x# = window[window].drawpointScaledX
	y# = window[window].drawpointScaledY
	XgrConvertScaledToLocal (window, x#, y#, @xx, @yy)
	segment[slot] = xx	: INC slot
	segment[slot] = yy	: INC slot
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
		buffer[slot-2] = bx
		buffer[slot-1] = by
	END IF
'
	DO
		SELECT CASE type
			CASE $$XLONG		: x# = XLONGAT (addr, [i])		: INC i
												y# = XLONGAT (addr, [i])		: INC i
			CASE $$SBYTE		: x# = SBYTEAT (addr, [i])		: INC i
												y# = SBYTEAT (addr, [i])		: INC i
			CASE $$UBYTE		: x# = UBYTEAT (addr, [i])		: INC i
												y# = UBYTEAT (addr, [i])		: INC i
			CASE $$SSHORT		: x# = SSHORTAT (addr, [i])		: INC i
												y# = SSHORTAT (addr, [i])		: INC i
			CASE $$USHORT		: x# = USHORTAT (addr, [i])		: INC i
												y# = USHORTAT (addr, [i])		: INC i
			CASE $$SLONG		: x# = SLONGAT (addr, [i])		: INC i
												y# = SLONGAT (addr, [i])		: INC i
			CASE $$ULONG		: x# = ULONGAT (addr, [i])		: INC i
												y# = ULONGAT (addr, [i])		: INC i
			CASE $$GIANT		: x# = GIANTAT (addr, [i])		: INC i
												y# = GIANTAT (addr, [i])		: INC i
			CASE $$SINGLE		: x# = SINGLEAT (addr, [i])		: INC i
												y# = SINGLEAT (addr, [i])		: INC i
			CASE $$DOUBLE		: x# = DOUBLEAT (addr, [i])		: INC i
												y# = DOUBLEAT (addr, [i])		: INC i
		END SELECT
'
		XgrConvertScaledToLocal (window, x#, y#, @xx, @yy)
		segment[slot] = xx	: INC slot
		segment[slot] = yy	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
	LOOP UNTIL (slot >= upperSlot)
	nSegments = (upperSlot >> 1) + 1
'
' final endpoint is final drawpoint
'
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100071
	XDrawLines (sdisplay, swindow, gc, &segment[], nSegments, 0)
	IF sbuffer THEN XDrawLines (sdisplay, sbuffer, gc, &buffer[], nSegments, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #############################
' #####  XgrDrawPoint ()  #####
' #############################
'
' error = XgrDrawPoint (grid, color, x, y)
'
FUNCTION  XgrDrawPoint (grid, color, x, y)
	SHARED  WINDOW  window[]
'
	STATIC window
	STATIC gc
	STATIC buffer
	STATIC swindow
	STATIC sdisplay
	STATIC colorOld
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawPoint()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawPoint() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	window[window].drawpointX = x
	window[window].drawpointY = y
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100072
	XDrawPoint (sdisplay, swindow, gc, x, y)
	IF sbuffer THEN XDrawPoint (sdisplay, sbuffer, gc, bx, by)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #################################
' #####  XgrDrawPointGrid ()  #####
' #################################
'
' error = XgrDrawPointGrid (grid, color, xGrid, yGrid)
'
FUNCTION  XgrDrawPointGrid (grid, color, xGrid, yGrid)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawPointGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawPointGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	window[window].drawpointGridX = xGrid
	window[window].drawpointGridY = yGrid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertGridToLocal (window, xGrid, yGrid, @x, @y)
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100073
	XDrawPoint (sdisplay, swindow, gc, x, y)
	IF sbuffer THEN XDrawPoint (sdisplay, sbuffer, gc, bx, by)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###################################
' #####  XgrDrawPointScaled ()  #####
' ###################################
'
' error = XgrDrawPointScaled (grid, color, x#, y#)
'
FUNCTION  XgrDrawPointScaled (grid, color, x#, y#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawPointScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawPointScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	XgrConvertScaledToLocal (window, x#, y#, @x, @y)
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100074
	XDrawPoint (sdisplay, swindow, gc, x, y)
	IF sbuffer THEN XDrawPoint (sdisplay, sbuffer, gc, bx, by)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ##############################
' #####  XgrDrawPoints ()  #####
' ##############################
'
' error = XgrDrawPoints (grid, color, first, count, @point[])
'
FUNCTION  XgrDrawPoints (grid, color, first, count, point[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawPoints()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawPoints() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ point[] THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (point[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawPoints() : invalid point[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of points
'
	first = first + first											' each point is 2 array elements
	upper = UBOUND (point[])									' upper bound of point[] array
	IF (first < 0) THEN first = 0							' < 0 means start at 0
	IF (count <= 0) THEN count = upper				' < 0 means to upper bound
	IF (first > upper) THEN RETURN ($$FALSE)	' first is already beyond array
	past = first + (count << 1)								' past = requested last+1
	IF (past > upper) THEN past = upper + 1		' keep in bounds
	items = (past - first)										' # of array elements
	count = items >> 1												' # of coords at 2 points per coord
	elements = count << 1											' array elements is 2 * point count
	IFZ count THEN RETURN ($$FALSE)						' not enough elements in array
'
	n = 0
	slot = 0
	i = first
	addr = &point[]
'
	##WHOMASK = 0
	DIM segment[elements]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[elements]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
	DO
		INC n
		SELECT CASE type
			CASE $$XLONG		: x = XLONGAT (addr, [i])		: INC i
												y = XLONGAT (addr, [i])		: INC i
			CASE $$SBYTE		: x = SBYTEAT (addr, [i])		: INC i
												y = SBYTEAT (addr, [i])		: INC i
			CASE $$UBYTE		: x = UBYTEAT (addr, [i])		: INC i
												y = UBYTEAT (addr, [i])		: INC i
			CASE $$SSHORT		: x = SSHORTAT (addr, [i])	: INC i
												y = SSHORTAT (addr, [i])	: INC i
			CASE $$USHORT		: x = USHORTAT (addr, [i])	: INC i
												y = USHORTAT (addr, [i])	: INC i
			CASE $$SLONG		: x = SLONGAT (addr, [i])		: INC i
												y = SLONGAT (addr, [i])		: INC i
			CASE $$ULONG		: x = ULONGAT (addr, [i])		: INC i
												y = ULONGAT (addr, [i])		: INC i
			CASE $$GIANT		: x = GIANTAT (addr, [i])		: INC i
												y = GIANTAT (addr, [i])		: INC i
			CASE $$SINGLE		: x = SINGLEAT (addr, [i])	: INC i
												y = SINGLEAT (addr, [i])	: INC i
			CASE $$DOUBLE		: x = DOUBLEAT (addr, [i])	: INC i
												y = DOUBLEAT (addr, [i])	: INC i
		END SELECT
		segment[slot] = x	: INC slot
		segment[slot] = y	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
	LOOP UNTIL (n >= count)
'
' final endpoint is final drawpoint
'
	window[window].drawpointX = x
	window[window].drawpointY = y
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100075
	XDrawPoints (sdisplay, swindow, gc, &segment[], count, 0)
	IF sbuffer THEN XDrawPoints (sdisplay, sbuffer, gc, &buffer[], count, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ##################################
' #####  XgrDrawPointsGrid ()  #####
' ##################################
'
' error = XgrDrawPointsGrid (grid, color, first, count, @point[])
'
FUNCTION  XgrDrawPointsGrid (grid, color, first, count, point[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawPointsGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawPointsGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ point[] THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (point[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawPointsGrid() : invalid point[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of points
'
	first = first + first											' each point is 2 array elements
	upper = UBOUND (point[])									' upper bound of point[] array
	IF (first < 0) THEN first = 0							' < 0 means start at 0
	IF (count <= 0) THEN count = upper				' < 0 means to upper bound
	IF (first > upper) THEN RETURN ($$FALSE)	' first is already beyond array
	past = first + (count << 1)								' past = requested last+1
	IF (past > upper) THEN past = upper + 1		' keep in bounds
	items = (past - first)										' # of array elements
	count = items >> 1												' # of coords at 2 points per coord
	elements = count << 1											' array elements is 2 * point count
	IFZ count THEN RETURN ($$FALSE)						' not enough elements in array
'
	n = 0
	slot = 0
	i = first
	addr = &point[]
'
	##WHOMASK = 0
	DIM segment[elements]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[elements]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
	DO
		INC n
		SELECT CASE type
			CASE $$XLONG		: x = XLONGAT (addr, [i])		: INC i
												y = XLONGAT (addr, [i])		: INC i
			CASE $$SBYTE		: x = SBYTEAT (addr, [i])		: INC i
												y = SBYTEAT (addr, [i])		: INC i
			CASE $$UBYTE		: x = UBYTEAT (addr, [i])		: INC i
												y = UBYTEAT (addr, [i])		: INC i
			CASE $$SSHORT		: x = SSHORTAT (addr, [i])	: INC i
												y = SSHORTAT (addr, [i])	: INC i
			CASE $$USHORT		: x = USHORTAT (addr, [i])	: INC i
												y = USHORTAT (addr, [i])	: INC i
			CASE $$SLONG		: x = SLONGAT (addr, [i])		: INC i
												y = SLONGAT (addr, [i])		: INC i
			CASE $$ULONG		: x = ULONGAT (addr, [i])		: INC i
												y = ULONGAT (addr, [i])		: INC i
			CASE $$GIANT		: x = GIANTAT (addr, [i])		: INC i
												y = GIANTAT (addr, [i])		: INC i
			CASE $$SINGLE		: x = SINGLEAT (addr, [i])	: INC i
												y = SINGLEAT (addr, [i])	: INC i
			CASE $$DOUBLE		: x = DOUBLEAT (addr, [i])	: INC i
												y = DOUBLEAT (addr, [i])	: INC i
		END SELECT
'
		XgrConvertGridToLocal (window, x, y, @xx, @yy)
		segment[slot] = xx	: INC slot
		segment[slot] = yy	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
	LOOP UNTIL (n >= count)
'
' final endpoint is final drawpoint
'
	window[window].drawpointGridX = x
	window[window].drawpointGridY = y
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100076
	XDrawPoints (sdisplay, swindow, gc, &segment[], count, 0)
	IF sbuffer THEN XDrawPoints (sdisplay, swindow, gc, &buffer[], count, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ####################################
' #####  XgrDrawPointsScaled ()  #####
' ####################################
'
' error = XgrDrawPointsScaled (grid, color, first, count, @point[])
'
FUNCTION  XgrDrawPointsScaled (grid, color, first, count, point[])
	SHARED  WINDOW  window[]
	SSHORT  segment[]
	SSHORT  buffer[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawPointsScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawPointsScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ point[] THEN RETURN ($$FALSE)
'
	window = grid
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
' make sure array argument is a supported type
'
	type = TYPE (point[])
	IF ((type < $$SBYTE) OR (type > $$DOUBLE)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrDrawPointsScaled() : invalid point[] array type"
		RETURN ($$TRUE)
	END IF
'
' create X style array of points
'
	first = first + first											' each point is 2 array elements
	upper = UBOUND (point[])									' upper bound of point[] array
	IF (first < 0) THEN first = 0							' < 0 means start at 0
	IF (count <= 0) THEN count = upper				' < 0 means to upper bound
	IF (first > upper) THEN RETURN ($$FALSE)	' first is already beyond array
	past = first + (count << 1)								' past = requested last+1
	IF (past > upper) THEN past = upper + 1		' keep in bounds
	items = (past - first)										' # of array elements
	count = items >> 1												' # of coords at 2 points per coord
	elements = count << 1											' array elements is 2 * point count
	IFZ count THEN RETURN ($$FALSE)						' not enough elements in array
'
	n = 0
	slot = 0
	i = first
	addr = &point[]
'
	##WHOMASK = 0
	DIM segment[elements]									' array of SSHORT coords for X
	IF buffer THEN DIM buffer[elements]		' array of SSHORT coords for X
	##WHOMASK = whomask
'
	DO
		INC n
		SELECT CASE type
			CASE $$XLONG		: x# = XLONGAT (addr, [i])		: INC i
												y# = XLONGAT (addr, [i])		: INC i
			CASE $$SBYTE		: x# = SBYTEAT (addr, [i])		: INC i
												y# = SBYTEAT (addr, [i])		: INC i
			CASE $$UBYTE		: x# = UBYTEAT (addr, [i])		: INC i
												y# = UBYTEAT (addr, [i])		: INC i
			CASE $$SSHORT		: x# = SSHORTAT (addr, [i])		: INC i
												y# = SSHORTAT (addr, [i])		: INC i
			CASE $$USHORT		: x# = USHORTAT (addr, [i])		: INC i
												y# = USHORTAT (addr, [i])		: INC i
			CASE $$SLONG		: x# = SLONGAT (addr, [i])		: INC i
												y# = SLONGAT (addr, [i])		: INC i
			CASE $$ULONG		: x# = ULONGAT (addr, [i])		: INC i
												y# = ULONGAT (addr, [i])		: INC i
			CASE $$GIANT		: x# = GIANTAT (addr, [i])		: INC i
												y# = GIANTAT (addr, [i])		: INC i
			CASE $$SINGLE		: x# = SINGLEAT (addr, [i])		: INC i
												y# = SINGLEAT (addr, [i])		: INC i
			CASE $$DOUBLE		: x# = DOUBLEAT (addr, [i])		: INC i
												y# = DOUBLEAT (addr, [i])		: INC i
		END SELECT
'
		XgrConvertScaledToLocal (window, x#, y#, @xx, @yy)
		segment[slot] = xx	: INC slot
		segment[slot] = yy	: INC slot
'
		IF buffer THEN
			LocalToBufferCoords (window, buffer, @sbuffer, @overlap, xx, yy, xx, yy, @bx, @by, 0, 0)
			buffer[slot-2] = bx
			buffer[slot-1] = by
		END IF
	LOOP UNTIL (n >= count)
'
' final endpoint is final drawpoint
'
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	##WHOMASK = 0
	##LOCKOUT = 100077
	XDrawPoints (sdisplay, swindow, gc, &segment[], count, 0)
	IF sbuffer THEN XDrawPoints (sdisplay, sbuffer, gc, &buffer[], count, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ############################
' #####  XgrDrawText ()  #####
' ############################
'
' error = XgrDrawText (grid, color, text$)
'
' The text$ strin is drawn on the grid starting at the draw point.
'
' This function uses the Grid Character Map Array
'
'	See: XgrSetGridCharacterMapArray(), XgrSetGridCharacterMapArray()
'
'
' Add code to draw multiple lines when newline characters in text$
' and update drawpoint accordingly.
'
FUNCTION  XgrDrawText (grid, color, text$)
	SHARED  WINDOW  window[]
	SHARED  FONT  font[]
	SHARED  charMap[]
	AUTOX  dir
	AUTOX  up
	AUTOX  down
	AUTOX  XCharStruct  char
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawText()lockout", lockout) : lockout = 0
'
	IFZ text$ THEN RETURN ($$FALSE)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawText() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	length = LEN (text$)
	upper = UBOUND (text$)
	gc = window[window].gc
	font = window[window].font
	sfont = font[font].sfont
	addrFont = font[font].addrFont
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	g = -1
	IF charMap[] THEN
		u = UBOUND (charMap[])
		IF (grid <= u) THEN
			IF charMap[0,] THEN g = 0
			IF charMap[grid,] THEN g = grid
'
			IF (g >= 0) THEN
				temp$ = NULL$ (length)
				FOR i = 0 TO length-1
					temp${i} = charMap[g,text${i}]				' map character
				NEXT i
				SWAP temp$, text$
			END IF
		END IF
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100078
	XTextExtents (addrFont, &text$, length, &dir, &up, &down, &char)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	x = window[window].drawpointX
	y = window[window].drawpointY + up
	window[window].drawpointX = x + char.width
	height = up + down
'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100079
	XDrawString (sdisplay, swindow, gc, x, y, &text$, length)
	IF sbuffer THEN XDrawString (sdisplay, sbuffer, gc, bx, by, &text$, length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (g >= 0) THEN
		SWAP text$, temp$
		temp$ = ""
	END IF
END FUNCTION
'
'
' ################################
' #####  XgrDrawTextGrid ()  #####
' ################################
'
' error = XgrDrawTextGrid (grid, color, text$)
'
FUNCTION  XgrDrawTextGrid (grid, color, text$)
	SHARED  WINDOW  window[]
	AUTOX  dir
	AUTOX  up
	AUTOX  down
	AUTOX  XCharStruct  char
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawTextGrid()lockout", lockout) : lockout = 0
'
	IFZ text$ THEN RETURN ($$FALSE)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawTextGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x = window[window].drawpointX
	y = window[window].drawpointY
	xGrid = window[window].drawpointGridX
	yGrid = window[window].drawpointGridY
'
	XgrConvertGridToLocal (window, xGrid, yGrid, @xx, @yy)
	window[window].drawpointX = xx
	window[window].drawpointY = yy
'
' draw the text in local coords
'
	return = XgrDrawText (window, color, @text$)
'
' update grid coordinate drawpoint and restore local drawpoint
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
	return = XgrConvertLocalToGrid (window, xx, yy, @xGrid, @yGrid)
	window[window].drawpointGridX = xGrid
	window[window].drawpointGridY = yGrid
	window[window].drawpointX = x
	window[window].drawpointY = y
	RETURN (return)
END FUNCTION
'
'
' ##################################
' #####  XgrDrawTextScaled ()  #####
' ##################################
'
' error = XgrDrawTextScaled (grid, color, text$)
'
FUNCTION  XgrDrawTextScaled (grid, color, text$)
	SHARED  WINDOW  window[]
	AUTOX  dir
	AUTOX  up
	AUTOX  down
	AUTOX  XCharStruct  char
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawTextScaled()lockout", lockout) : lockout = 0
'
	IFZ text$ THEN RETURN ($$FALSE)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawTextScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IF (grid == 547) THEN
		PRINT "XgrDrawTextScaled(28)", grid, text$
	END IF
'
	window = grid
	x = window[window].drawpointX
	y = window[window].drawpointY
	x# = window[window].drawpointScaledX
	y# = window[window].drawpointScaledY
'
	XgrConvertScaledToLocal (window, x#, y#, @xx, @yy)
	window[window].drawpointX = xx
	window[window].drawpointY = yy
'
' draw the text in local coords
'
	return = XgrDrawText (window, color, @text$)
'
' update scaled coordinate drawpoint and restore local drawpoint
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
	XgrConvertLocalToScaled (window, xx, yy, @x#, @y#)
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
	window[window].drawpointX = x
	window[window].drawpointY = y
	RETURN (return)
END FUNCTION
'
'
' ################################
' #####  XgrDrawTextFill ()  #####
' ################################
'
' error = XgrDrawTextFill (grid, color, text$)
'
FUNCTION  XgrDrawTextFill (grid, color, text$)
	SHARED  WINDOW  window[]
	SHARED  FONT  font[]
	SHARED  charMap[]
	AUTOX  dir
	AUTOX  up
	AUTOX  down
	AUTOX  XCharStruct  char
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawTextFill()lockout", lockout) : lockout = 0
'
	IFZ text$ THEN RETURN ($$FALSE)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawTextFill() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	IF (grid >= 546) && (grid <= 550)
		txt$ =  "XgrDrawTextFill(32) " + STR$(grid) + text$
		XstLog (txt$)
	END IF
'
	window = grid
	length = LEN (text$)
	gc = window[window].gc
	font = window[window].font
	sfont = font[font].sfont
	addrFont = font[font].addrFont
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	g = -1
	IF charMap[] THEN
		u = UBOUND (charMap[])
		IF (grid <= u) THEN
			IF charMap[0,] THEN g = 0
			IF charMap[grid,] THEN g = grid
'
			IF (g >= 0) THEN
				temp$ = NULL$ (length)
				FOR i = 0 TO length-1
					temp${i} = charMap[g,text${i}]				' map character
				NEXT i
				SWAP temp$, text$
			END IF
		END IF
	END IF
'
' the XQueryTextExtents() below doesn't work - can't figure out why
'
	##WHOMASK = 0
	##LOCKOUT = 100080
	XTextExtents (addrFont, &text$, length, &dir, &up, &down, &char)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	x = window[window].drawpointX
	y = window[window].drawpointY + up
	window[window].drawpointX = x + char.width
	height = up + down
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x, y, x, y, @bx, @by, 0, 0)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100081
	XDrawImageString (sdisplay, swindow, gc, x, y, &text$, length)
	IF sbuffer THEN XDrawImageString (sdisplay, sbuffer, gc, bx, by, &text$, length)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (g >= 0) THEN
		SWAP text$, temp$
		temp$ = ""
	END IF
'
END FUNCTION
'
'
' ####################################
' #####  XgrDrawTextFillGrid ()  #####
' ####################################
'
' error = XgrDrawTextFillGrid (grid, color, text$)
'
FUNCTION  XgrDrawTextFillGrid (grid, color, text$)
	SHARED  WINDOW  window[]
	AUTOX  dir
	AUTOX  up
	AUTOX  down
	AUTOX  XCharStruct  char
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawTextFillGrid()lockout", lockout) : lockout = 0
'
	IFZ text$ THEN RETURN ($$FALSE)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawTextFillGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x = window[window].drawpointX
	y = window[window].drawpointY
	xGrid = window[window].drawpointGridX
	yGrid = window[window].drawpointGridY
'
	XgrConvertGridToLocal (window, xGrid, yGrid, @xx, @yy)
	window[window].drawpointX = xx
	window[window].drawpointY = yy
'
' draw the text in local coords
'
	return = XgrDrawTextFill (window, color, @text$)
'
' update grid coordinate drawpoint and restore local drawpoint
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
	XgrConvertLocalToGrid (window, xx, yy, @xGrid, @yGrid)
	window[window].drawpointGridX = xGrid
	window[window].drawpointGridY = yGrid
	window[window].drawpointX = x
	window[window].drawpointY = y
	RETURN (return)
END FUNCTION
'
'
' ######################################
' #####  XgrDrawTextFillScaled ()  #####
' ######################################
'
' error = XgrDrawTextFillScaled (grid, color, text$)
'
FUNCTION  XgrDrawTextFillScaled (grid, color, text$)
	SHARED  WINDOW  window[]
	AUTOX  dir
	AUTOX  up
	AUTOX  down
	AUTOX  XCharStruct  char
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawTextFillScaled()lockout", lockout) : lockout = 0
'
	IFZ text$ THEN RETURN ($$FALSE)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrDrawTextScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x = window[window].drawpointX
	y = window[window].drawpointY
	x# = window[window].drawpointScaledX
	y# = window[window].drawpointScaledY
'
	XgrConvertScaledToLocal (window, x#, y#, @xx, @yy)
	window[window].drawpointX = xx
	window[window].drawpointY = yy
'
' draw the text in local coords
'
	return = XgrDrawTextFill (window, color, @text$)
'
' update scaled coordinate drawpoint and restore local drawpoint
'
	xx = window[window].drawpointX
	yy = window[window].drawpointY
	XgrConvertLocalToScaled (window, xx, yy, @x#, @y#)
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
	window[window].drawpointX = x
	window[window].drawpointY = y
	RETURN (return)
END FUNCTION
'
'
' ###########################
' #####  XgrFillBox ()  #####
' ###########################
'
' error = XgrFillBox (grid, color, x1, y1, x2, y2)
'
FUNCTION  XgrFillBox (grid, color, x1, y1, x2, y2)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrFillBox()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillBox() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, @bx2, @by2)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100082
	XFillRectangle (sdisplay, swindow, gc, x1, y1, x2-x1+1, y2-y1+1)
	IF sbuffer THEN XFillRectangle (sdisplay, sbuffer, gc, bx1, by1, bx2-bx1+1, by2-by1+1)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###############################
' #####  XgrFillBoxGrid ()  #####
' ###############################
'
' error = XgrFillBoxGrid (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
'
FUNCTION  XgrFillBoxGrid (grid, color, x1Grid, y1Grid, x2Grid, y2Grid)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrFillBoxGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillBoxGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	XgrConvertGridToLocal (window, x1Grid, y1Grid, @x1, @y1)
	XgrConvertGridToLocal (window, x2Grid, y2Grid, @x2, @y2)
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, @bx2, @by2)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100083
	XFillRectangle (sdisplay, swindow, gc, x1, y1, x2-x1+1, y2-y1+1)
	IF sbuffer THEN XFillRectangle (sdisplay, sbuffer, gc, bx1, by1, bx2-bx1+1, by2-by1+1)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #################################
' #####  XgrFillBoxScaled ()  #####
' #################################
'
' error = XgrFillBoxScaled (grid, color, x1#, y1#, x2#, y2#)
'
FUNCTION  XgrFillBoxScaled (grid, color, x1#, y1#, x2#, y2#)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrFillBoxScaled()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillBoxScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	buffer = window[window].buffer
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	XgrConvertScaledToLocal (window, x1#, y1#, @x1, @y1)
	XgrConvertScaledToLocal (window, x2#, y2#, @x2, @y2)
'
	IF (x1 > x2) THEN SWAP x1, x2
	IF (y1 > y2) THEN SWAP y1, y2
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, @bx2, @by2)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100084
	XFillRectangle (sdisplay, swindow, gc, x1, y1, x2-x1+1, y2-y1+1)
	IF sbuffer THEN XFillRectangle (sdisplay, sbuffer, gc, bx1, by1, bx2-bx1+1, by2-by1+1)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ##############################
' #####  XgrFillCircle ()  #####
' ##############################
'
' error = XgrFillCircle (grid, color, radius)
'
' Draw and fill a circle centered at the current draw point
'
FUNCTION  XgrFillCircle (grid, color, r)
'
' A circle is just an ellipse with equal X and Y radius.
'
	RETURN XgrFillEllipse(grid, color, r, r)
END FUNCTION
'
'
' ##################################
' #####  XgrFillCircleGrid ()  #####
' ##################################
'
' error = XgrFillCircleGrid (grid, color, r)
'
FUNCTION  XgrFillCircleGrid (grid, color, r)
	RETURN XgrFillEllipseGrid(grid, color, r, r)
END FUNCTION
'
'
' ####################################
' #####  XgrFillCircleScaled ()  #####
' ####################################
'
' error = XgrFillCircleScaled (grid, color, r#)
'
FUNCTION  XgrFillCircleScaled (grid, color, r#)
	RETURN XgrFillEllipseScaled(grid, color, r#, r#)
END FUNCTION
'
'
' ###############################
' #####  XgrFillEllipse ()  #####
' ###############################
'
' error = XgrFillEllipse (grid, color, rx, ry)
'
'* Fill an ellipse.
' Note: The current drawing-point is used as the center of the ellipse.
' @param grid			The grid.
' @param color		The color in which to draw
' @param rx				The X-Radius
' @param ry				The Y-Radius
'
FUNCTION  XgrFillEllipse (grid, color, rx, ry)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrFillEllipse()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillEllipse() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	buffer = window[window].buffer
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
	gc = window[window].gc
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
'
	x = window[window].drawpointX			' drawpoint is center of curvature
	y = window[window].drawpointY			' ditto
	x1 = x - rx
	y1 = y - ry
	x2 = x + rx
	y2 = y + ry
'
	IF (x2 < x1) THEN SWAP x1, x2
	IF (y2 < y1) THEN SWAP y1, y2
	ww = x2 - x1
	hh = y2 - y1
'
	SetDrawingColor (window, color)
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @bx1, @by1, 0, 0)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100085
	XFillArc (sdisplay, swindow, gc, x1, y1, ww, hh, 0, 23040)
	IF sbuffer THEN XFillArc (sdisplay, sbuffer, gc, bx1, by1, ww, hh, 0, 23040)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###################################
' #####  XgrFillEllipseGrid ()  #####
' ###################################
'
' error = XgrFillEllipseGrid (grid, color, rx, ry)
'
FUNCTION  XgrFillEllipseGrid (grid, color, rx, ry)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillEllipseGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointGrid (grid, @xxGrid, @yyGrid)
	XgrConvertGridToLocal (grid, xxGrid, yyGrid, @x, @y)
	XgrSetDrawpoint (grid, x, y)
	XgrFillEllipse (grid, color, rx, ry)
	XgrSetDrawpoint (grid, xx, yy)
END FUNCTION
'
'
' #####################################
' #####  XgrFillEllipseScaled ()  #####
' #####################################
'
' error = XgrFillEllipseScaled (grid, color, rx#, ry#)
'
FUNCTION  XgrFillEllipseScaled (grid, color, rx#, ry#)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillEllipseScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointScaled (grid, @xx#, @yy#)
	XgrConvertScaledToLocal (grid, xx#, yy#, @x, @y)
	XgrConvertScaledToLocal (grid, xx# + rx#, yy# + ry#, @xr, @yr)
	xr = ABS (xr - x)
	yr = ABS (yr - y)
'
	XgrSetDrawpoint (grid, x, y)
	XgrFillEllipse (grid, color, xr, yr)
	XgrSetDrawpoint (grid, xx, yy)
END FUNCTION
'
'
' ################################
' #####  XgrFillTriangle ()  #####
' ################################
'
' error = XgrFillTriangle (grid, color, style, direction, x1, y1, x2, y2)
'
'	direction:  $$TriangleUp
'             $$TriangleRight
'             $$TriangleDown
'             $$TriangleLeft
'
' style: Ignored (Triangles are always drawn $$LineStyleSolid)
'
FUNCTION  XgrFillTriangle (grid, color, style, direction, x1, y1, x2, y2)
	SHARED WINDOW window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillTriangle() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	way = direction AND 0x001E
	IFZ way THEN RETURN ($$FALSE)
'
	XgrGetGridBoxLocal (grid, @xx1, @yy1, @xx2, @yy2)
	w = xx2 - xx1 + 1
	h = yy2 - yy1 + 1
'
	IFZ (x1 OR y1 OR x2 OR y2) THEN
		x1 = 4
		y1 = 4
		x2 = w-5
		y2 = h-5
	END IF
'
	IF (x1 > x2) THEN SWAP x1, x2
	IF (y1 > y2) THEN SWAP y1, y2
'
	IF (x1 < 0) THEN x1 = 0
	IF (y1 < 0) THEN y1 = 0
	IF (x2 > (w-1)) THEN x2 = w-1
	IF (y2 > (h-1)) THEN y2 = h-1
	IF (x1 > x2) THEN SWAP x1, x2
	IF (y1 > y2) THEN SWAP y1, y2
'
	xx1 = x1 << 15
	xx2 = x2 << 15
	yy1 = y1 << 15
	yy2 = y2 << 15
	ddx = xx2 - xx1
	ddy = yy2 - yy1
	dx = x2 - x1
	dy = y2 - y1
'
	xxx = x1 + (dx >> 1)			' xxx = horizontal center of arrow
	yyy = y1 + (dy >> 1)			' yyy = vertical center of arrow
'
	xx = 0
	yy = 0
	dt = 0
	dh = ddy \ dx							' potential horizontal step size
	dv = ddx \ dy							' potential vertical step size
'
'	#####  v0.0433 : SVG : save current line style, set temporary style to $$LineStyleSolid
'
	lineStyle = window[grid].lineStyle
	window[grid].lineStyle = $$LineStyleSolid
'
'	#####
'
	SELECT CASE way
		CASE $$TriangleUp			: GOSUB TriangleUp
		CASE $$TriangleRight	: GOSUB TriangleRight
		CASE $$TriangleDown		: GOSUB TriangleDown
		CASE $$TriangleLeft		: GOSUB TriangleLeft
	END SELECT
'
'	#####  v0.0433 : SVG : restore original line style
'
	window[grid].lineStyle = lineStyle
'
'	#####
'
	RETURN
'
'
' *****  TriangleUp  *****
'
SUB TriangleUp
	FOR y = y1 TO y2
		xx1 = xxx - (dt >> 16)
		xx2 = xxx + (dt >> 16)
		XgrDrawLine (grid, color, xx1, y, xx2, y)
		dt = dt + dv
	NEXT y
END SUB
'
'
' *****  TriangleRight  *****
'
SUB TriangleRight
	FOR x = x2 TO x1 STEP -1
		yy1 = yyy - (dt >> 16)
		yy2 = yyy + (dt >> 16)
		XgrDrawLine (grid, color, x, yy1, x, yy2)
		dt = dt + dh
	NEXT x
END SUB
'
'
' *****  TriangleDown  *****
'
SUB TriangleDown
	FOR y = y2 TO y1 STEP -1
		xx1 = xxx - (dt >> 16)
		xx2 = xxx + (dt >> 16)
		XgrDrawLine (grid, color, xx1, y, xx2, y)
		dt = dt + dv
	NEXT y
END SUB
'
'
' *****  TriangleLeft  *****
'
SUB TriangleLeft
	FOR x = x1 TO x2
		yy1 = yyy - (dt >> 16)
		yy2 = yyy + (dt >> 16)
		XgrDrawLine (grid, color, x, yy1, x, yy2)
		dt = dt + dh
	NEXT x
END SUB
END FUNCTION
'
'
' ####################################
' #####  XgrFillTriangleGrid ()  #####
' ####################################
'
' error = XgrFillTriangleGrid (grid, color, style, direction, x1Grid, y1Grid, x2Grid, y2Grid)
'
FUNCTION  XgrFillTriangleGrid (grid, color, style, direction, x1Grid, y1Grid, x2Grid, y2Grid)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillTriangleGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointGrid (grid, @xxGrid, @yyGrid)
	XgrConvertGridToLocal (grid, xxGrid, yyGrid, @x, @y)
	XgrConvertGridToLocal (grid, x1Grid, y1Grid, @x1, @y1)
	XgrConvertGridToLocal (grid, x2Grid, y2Grid, @x2, @y2)
	XgrSetDrawpoint (grid, x, y)
	XgrFillTriangle (grid, color, style, direction, x1, y1, x2, y2)
	XgrSetDrawpoint (grid, xx, yy)
END FUNCTION
'
'
' ######################################
' #####  XgrFillTriangleScaled ()  #####
' ######################################
'
' error = XgrFillTriangleScaled (grid, color, style, direction, x1#, y1#, x2#, y2#)
'
FUNCTION  XgrFillTriangleScaled (grid, color, style, direction, x1#, y1#, x2#, y2#)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrFillTriangleScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	XgrGetDrawpoint (grid, @xx, @yy)
	XgrGetDrawpointScaled (grid, @xx#, @yy#)
	XgrConvertScaledToLocal (grid, xx#, yy#, @x, @y)
	XgrConvertScaledToLocal (grid, x1#, y1#, @x1, @y1)
	XgrConvertScaledToLocal (grid, x2#, y2#, @x2, @y2)
'
	way = direction
	IF (x1 > x2) THEN
		SWAP x1, x2
		SELECT CASE way
			CASE $$TriangleRight : way = $$TriangleLeft
			CASE $$TriangleLeft  : way = $$TriangleRight
		END SELECT
	END IF
'
	IF (y1 > y2) THEN
		SWAP y1, y2
		SELECT CASE way
			CASE $$TriangleUp   : way = $$TriangleDown
			CASE $$TriangleDown : way = $$TriangleUp
		END SELECT
	END IF
'
	XgrSetDrawpoint (grid, x, y)
'	XgrFillTriangle (grid, color, style, direction, x1, y1, x2, y2)
	XgrFillTriangle (grid, color, style, way, x1, y1, x2, y2)
	XgrSetDrawpoint (grid, xx, yy)
END FUNCTION
'
'
' ################################
' #####  XgrGetDrawpoint ()  #####
' ################################
'
' error = XgrGetDrawpoint (grid, @x, @y)
'
FUNCTION  XgrGetDrawpoint (grid, x, y)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetDrawpoint() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x = window[window].drawpointX
	y = window[window].drawpointY
END FUNCTION
'
'
' ####################################
' #####  XgrGetDrawpointGrid ()  #####
' ####################################
'
' error = XgrGetDrawpointGrid (grid, @xGrid, @yGrid)
'
FUNCTION  XgrGetDrawpointGrid (grid, xGrid, yGrid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetDrawpointGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	xGrid = window[window].drawpointGridX
	yGrid = window[window].drawpointGridY
END FUNCTION
'
'
' ######################################
' #####  XgrGetDrawpointScaled ()  #####
' ######################################
'
' error = XgrGetDrawpointScaled (grid, @x#, @y#)
'
FUNCTION  XgrGetDrawpointScaled (grid, x#, y#)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetDrawpointScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x# = window[window].drawpointScaledX
	y# = window[window].drawpointScaledY
END FUNCTION
'
'
' #############################
' #####  XgrGrabPoint ()  #####
' #############################
'
' error = XgrGrabPoint (grid, x, y, @r, @g, @b, @color)
'
FUNCTION  XgrGrabPoint (grid, x, y, r, g, b, color)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
	SHARED  flushTime
	XColor  sc
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGrabPoint()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGrabPoint() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	x1 = 0
	y1 = 0
	x2 = window[window].width - 1
	y2 = window[window].height - 1
'
	display = window[window].display
	swindow = window[window].swindow
	sdisplay = window[window].sdisplay
	colormap = display[display].colormap
'
	r = 0
	g = 0
	b = 0
	color = -1
'
	IF (x < x1) THEN RETURN
	IF (y < y1) THEN RETURN
	IF (x > x2) THEN RETURN
	IF (y > y2) THEN RETURN
'
	##WHOMASK = 0
	##LOCKOUT = 100086
	ximage = XGetImage (sdisplay, swindow, x, y, 1, 1, $$TRUE, $$ZPixmap)
	scolor = XGetPixel (ximage, 0, 0)
	sc.scolor = scolor
	XQueryColor (sdisplay, colormap, &sc)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	r = sc.r
	g = sc.g
	b = sc.b
	XgrConvertRGBToColor (r, g, b, @color)
'
END FUNCTION
'
'
' #################################
' #####  XgrGrabPointGrid ()  #####
' #################################
'
' error = XgrGrabPointGrid (grid, xGrid, yGrid, @r, @g, @b, @color)
'
FUNCTION  XgrGrabPointGrid (grid, xGrid, yGrid, @r, @g, @b, @color)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGrabPointGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	XgrConvertGridToLocal (window, xGrid, yGrid, @x, @y)
	XgrGrabPoint (window, x, y, @r, @g, @b, @color)
END FUNCTION
'
'
' ###################################
' #####  XgrGrabPointScaled ()  #####
' ###################################
'
' error = XgrGrabPointScaled (grid, x#, y#, @r, @g, @b, @color)
'
FUNCTION  XgrGrabPointScaled (grid, x#, y#, @r, @g, @b, @color)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGrabPointScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	XgrConvertScaledToLocal (window, x#, y#, @x, @y)
	XgrGrabPoint (window, x, y, @r, @g, @b, @color)
END FUNCTION
'
'
' #############################
' #####  XgrMoveDelta ()  #####
' #############################
'
' error = XgrMoveDelta (grid, dx, dy)
'
FUNCTION  XgrMoveDelta (grid, dx, dy)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrMoveDelta() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointX = window[window].drawpointX + dx
	window[window].drawpointY = window[window].drawpointY + dy
END FUNCTION
'
'
' #################################
' #####  XgrMoveDeltaGrid ()  #####
' #################################
'
' error = XgrMoveDeltaGrid (grid, dxGrid, dyGrid)
'
FUNCTION  XgrMoveDeltaGrid (grid, dxGrid, dyGrid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrMoveDeltaGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointGridX = window[window].drawpointGridX + dxGrid
	window[window].drawpointGridY = window[window].drawpointGridY + dyGrid
END FUNCTION
'
'
' ###################################
' #####  XgrMoveDeltaScaled ()  #####
' ###################################
'
' error = XgrMoveDeltaScaled (grid, dx#, dy#)
'
FUNCTION  XgrMoveDeltaScaled (grid, dx#, dy#)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrMoveDeltaScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointScaledX = window[window].drawpointScaledX + dx#
	window[window].drawpointScaledY = window[window].drawpointScaledY + dy#
END FUNCTION
'
'
' ##########################
' #####  XgrMoveTo ()  #####
' ##########################
'
' error = XgrMoveTo (grid, x, y)
'
FUNCTION  XgrMoveTo (grid, x, y)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrMoveTo() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointX = x
	window[window].drawpointY = y
END FUNCTION
'
'
' ##############################
' #####  XgrMoveToGrid ()  #####
' ##############################
'
' error = XgrMoveToGrid (grid, xGrid, yGrid)
'
FUNCTION  XgrMoveToGrid (grid, xGrid, yGrid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrMoveToGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointGridX = xGrid
	window[window].drawpointGridY = yGrid
END FUNCTION
'
'
' ################################
' #####  XgrMoveToScaled ()  #####
' ################################
'
' error = XgrMoveToScaled (grid, x#, y#)
'
FUNCTION  XgrMoveToScaled (grid, x#, y#)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrMoveToScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
END FUNCTION
'
'
' ################################
' #####  XgrRedrawWindow ()  #####
' ################################
'
' error = XgrRedrawWindow (window, action, x, y, width, height)
'
' Every grid within the window's coordinates will be redrawn
'
' action = TRUE  : send #RedrawGrid
' action = FALSE : add  #RedrawGrid to message queue
'       (everybody sets the action to $$TRUE)
'
FUNCTION  XgrRedrawWindow (window, action, x, y, width, height)
	SHARED  WINDOW  window[]
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrRedrawWindow() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	top = window[window].top
	IF (window != top) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrRedrawWindow() : not a top level window : invalid window #"; window; top
		RETURN ($$TRUE)
	END IF
'
' only redraw windows that are displayed
'
	SELECT CASE window[window].visibility
		CASE $$WindowDisplayed
		CASE $$WindowMaximized
		CASE ELSE								: RETURN ($$FALSE)
	END SELECT
'
' redraw whole window if width = 0 or height = 0
'
	IF ((width <= 0) OR (height <= 0)) THEN
		width  = window[window].width
		height = window[window].height
	END IF
'
' window visible - send/queue #RedrawGrid messages to all grids in xywh
'
	x1Win = x																			' rectangle left
	y1Win = y																			' rectangle top
	x2Win = x + width - 1													' rectangle right
	y2Win = y + height - 1												' rectangle bottom
'
	FOR w = 1 TO UBOUND (window[])
		IFZ window[w].window THEN DO NEXT							' grid must exist
		IF (window[w].top = w) THEN DO NEXT						' grids only, skip windows
		IF (window[w].kind != $$Grid) THEN DO NEXT		' grids only, skip images
		IF (window[w].parent != window) THEN DO NEXT	' grids with window parent
		IF (window[w].top != window) THEN DO NEXT			' grids in this window
		IFZ window[w].state THEN DO NEXT							' grid must be enabled
		RedrawGridAndKids (w, action, x, y, width, height)
	NEXT w
END FUNCTION
'
'
' ################################
' #####  XgrSetDrawpoint ()  #####
' ################################
'
' error = XgrSetDrawpoint (grid, x, y)
'
FUNCTION  XgrSetDrawpoint (grid, x, y)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetDrawpoint() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointX = x
	window[window].drawpointY = y
END FUNCTION
'
'
' ####################################
' #####  XgrSetDrawpointGrid ()  #####
' ####################################
'
' error = XgrSetDrawpointGrid (grid, xGrid, yGrid)
'
FUNCTION  XgrSetDrawpointGrid (grid, xGrid, yGrid)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetDrawpointGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointGridX = xGrid
	window[window].drawpointGridY = yGrid
END FUNCTION
'
'
' ######################################
' #####  XgrSetDrawpointScaled ()  #####
' ######################################
'
' error = XgrSetDrawpointScaled (grid, x#, y#)
'
FUNCTION  XgrSetDrawpointScaled (grid, x#, y#)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetDrawpointScaled() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	window[window].drawpointScaledX = x#
	window[window].drawpointScaledY = y#
END FUNCTION
'
'
' #############################
' #####  XgrCopyImage ()  #####
' #############################
'
' error = XgrCopyImage (dest, source)
'
FUNCTION  XgrCopyImage (dest, source)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrCopyImage()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (source) THEN
		IF ##XBDV THEN PRINT "XgrCopyImage() : invalid source grid #"; source
		RETURN ($$TRUE)
	END IF
'
	IF InvalidGrid (dest) THEN
		IF ##XBDV THEN PRINT "XgrCopyImage() : invalid destination grid #"; dest
		RETURN ($$TRUE)
	END IF
'
	IFZ window[dest].state THEN RETURN ($$FALSE)
	IFZ window[source].state THEN RETURN ($$FALSE)
'
	gc = window[dest].gc
	sdest = window[dest].swindow
	ssource = window[source].swindow
	sdisplay = window[dest].sdisplay
	buffer = window[dest].buffer
	IF (buffer = source) THEN buffer = 0
'
	dw = window[dest].width
	dh = window[dest].height
	sw = window[source].width
	sh = window[source].height
'
	width = sw
	height = sh
	IF (dw < sw) THEN width = dw
	IF (dh < sh) THEN height = dh
'
	IF buffer THEN
		LocalToBufferCoords (window, buffer, @sbuffer, @overlap, 0, 0, width-1, height-1, @bx1, @by1, @bx2, @by2)
		bwidth = bx2 - bx1 + 1
		bheight = by2 - by1 + 1
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100087
	XCopyArea (sdisplay, ssource, sdest, gc, 0, 0, width, height, 0, 0)
	IF sbuffer THEN XCopyArea (sdisplay, ssource, sbuffer, gc, bx1, by1, bwidth, bheight, 0, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #############################
' #####  XgrDrawImage ()  #####
' #############################
'
' error = XgrDrawImage (grid, imageGrid, startX, startY, endX, endY, destx, desty)
'
FUNCTION  XgrDrawImage (dest, source, sx1, sy1, sx2, sy2, dx1, dy1)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDrawImage()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (source) THEN
		IF ##XBDV THEN PRINT "XgrDrawImage() : invalid source grid #"; source
		RETURN ($$TRUE)
	END IF
'
	IF InvalidGrid (dest) THEN
		IF ##XBDV THEN PRINT "XgrDrawImage() : invalid destination grid #"; dest
		RETURN ($$TRUE)
	END IF
'
	IFZ WinGridDrawable (dest) THEN RETURN ($$FALSE)
	IFZ window[source].state THEN RETURN ($$FALSE)
'
	gc = window[dest].gc
	sdest = window[dest].swindow
	ssource = window[source].swindow
	sdisplay = window[dest].sdisplay
	buffer = window[dest].buffer
	IF (buffer = source) THEN buffer = 0
'
	dw = window[dest].width
	dh = window[dest].height
	sw = window[source].width
	sh = window[source].height
'
	IF (sx1 < 0) THEN sx1 = 0
	IF (sy1 < 0) THEN sy1 = 0
	IF (dx1 < 0) THEN dx1 = 0
	IF (dy1 < 0) THEN dy1 = 0
'
	IF (sx2 < 0) THEN sx2 = sw - 1
	IF (sy2 < 0) THEN sy2 = sh - 1
	IF (sx2 >= sw) THEN sx2 = sw - 1
	IF (sy2 >= sy) THEN sy2 = sh - 1
	sx2max = dw - dx1 + sx1 - 1
	sy2max = dh - dy1 + sy1 - 1
	IF (sx2 > sx2max) THEN sx2 = sx2max
	IF (sy2 > sy2max) THEN sy2 = sy2max
	IF (sx2 < sx1) THEN RETURN ($$FALSE)
	IF (sy2 < sy1) THEN RETURN ($$FALSE)
	width = sx2 - sx1 + 1
	height = sy2 - sy1 + 1
'
	IF buffer THEN
		dx2 = dx1 + sx2 - sx1
		dy2 = dy1 + sy2 - sy1
		LocalToBufferCoords (dest, buffer, @sbuffer, @overlap, dx1, dy1, dx2, dy2, @bsx1, @bsy1, @bsx2, @bsy2)
		bwidth = bsx2 - bsx1 + 1
		bheight = bsy2 - bsy1 + 1
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100088
	XCopyArea (sdisplay, ssource, sdest, gc, sx1, sy1, width, height, dx1, dy1)
	IF sbuffer THEN XCopyArea (sdisplay, ssource, sbuffer, gc, bsx1, bsy1, bwidth, bheight, bx1, by1)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'	IF ##WHOMASK THEN
'		PRINT "XgrDrawImage(B)", dest, buffer, sbuffer, overlap, dx1, dy1, dx2, dy2, bsx1, bsy1, bsx2, bsy2
'		PRINT "XgrDrawImage(C)", ssource, sbuffer, gc, bsx1, bsy1, bwidth, bheight, bx1, by1
'	END IF
'
END FUNCTION
'
'
' ############################
' #####  XgrGetImage ()  #####
' ############################
'
' error = XgrGetImage (grid, @image[])
'
'	Get image in DIB format array
'
'	In:				grid
'	Out:			image[]			DIB format
'
'	Return:		$$FALSE			no errors
'						$$TRUE			errors
'
'	Win32s does not support 32-bit DIB, so stick with 24-bit DIB for now.
'
'
'		DIB BITMAPFILEHEADER:  Offset 0 bytes
'			USHORT	.bfType							'BM'  (for bitmap)
'			ULONG		.bfSize							Total size of the file in bytes
'			USHORT	.res1								0
'			USHORT	.res2								0
'			ULONG		.bfOffBits					Offset to bitmapData from beginning of file (66)
'
'		DIB BITMAPINFO:        Offset 14 bytes
'			DIB BITMAPINFOHEADER:  Offset 14 bytes
'				ULONG		.biSize						Size of BitmapInfoHeader in bytes (40)
'				SLONG		.biWidth					Width of bitmap in pixels
'				SLONG		.biHeight					Height of bitmap in pixels
'				USHORT	.biPlanes					1
'				USHORT	.biBitCount				Color bits per pixel (32)
'				ULONG		.biCompression		Compression scheme (BI_BITFIELDS = 3)
'				ULONG		.biSizeImage			Size of bitmap bits in bytes (0--no compression)
'				SLONG		.biXPelsPerMeter	Horizontal resolution in pixels per meter
'				SLONG		.biYPelsPerMeter	Vertical resolution
'				ULONG		.biClrUsed				Number of colors used in image (0)
'				ULONG		.biClrImportant		Number of important colors in image (0)
'
'			DIB bmiColors:			Offset 54 bytes
'				ULONG		.redBits					0xFFC00000		10 bits
'				ULONG		.greenBits				0x003FF800		11 bits
'				ULONG		.blueBits					0x000007FF		11 bits
'
'		DIB bitmapData:					Offset 66 bytes
'			biBitCount		Interpretation	  (start with BOTTOM row of pixels, at left)
'				32:					32-bits per pixel (10-11-11 = 0RGB)
'
'			Each ROW is padded to a multiple of 4 bytes.
'
'
'		24-bit format mods to the above:
'			BITMAPINFOHEADER
'				.biBitCount			= 24
'				.biCompression	= $BI_RGB
'
'			DIB bmiColors:		UNUSED (0 bytes)
'
'			DIB bitmapData:		offset = 54 bytes
'				24 bits per pixel (8 bits each for RGB)
'				Each ROW is padded to a multiple of 4 bytes.
'
FUNCTION  XgrGetImage (grid, UBYTE image[])
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
	SHARED  flushTime
	STATIC  displayPrevious
	STATIC  XColor  cache[]
	STATIC  XColor  map[]
	UBYTE  dimage[]
	XColor  sc
'
	$BI_RGB       = 0					' 24-bit RGB
	$BI_BITFIELDS = 3					' 32-bit RGB
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetImage()lockout", lockout) : lockout = 0
'
	DIM image[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetImage() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	width = window[window].width					' image/grid width
	height = window[window].height				' image/grid height
	visual = window[window].visual				' visual (DirectColor, TrueColor, etc)
	swindow = window[window].swindow			' system image/grid #
	display = window[window].display			' native display #
	sdisplay = window[window].sdisplay		' system display #
	colormap = display[display].colormap	' system colormap
'
	IF (width <= 0) THEN RETURN ($$FALSE)
	IF (height <= 0) THEN RETURN ($$FALSE)
'
' compute size of DIB24 and create dimage[] array to hold it
'
'	dataOffset = 128			'???? why set to 128 if dataOffset for 24-bit is 54?
	dataOffset = 54
	widthbytes = ((width * 3) + 3) AND -4				' width of scan line in bytes
	size = dataOffset + (height * widthbytes)		' size of image file in bytes
	upper = size - 1
	DIM image[upper]
'
'	fill BITMAPFILEHEADER
'
	iAddr = &image[0]
'
	image[0] = 'B'															' DIB aka BMP signature
	image[1] = 'M'
	image[2] = size AND 0x00FF									' file size
	image[3] = (size >> 8) AND 0x00FF
	image[4] = (size >> 16) AND 0x00FF
	image[5] = (size >> 24) AND 0x00FF
	image[6] = 0
	image[7] = 0
	image[8] = 0
	image[9] = 0
	image[10] = dataOffset AND 0x00FF						' file offset of bitmap data
	image[11] = (dataOffset >> 8) AND 0x00FF
	image[12] = (dataOffset >> 16) AND 0x00FF
	image[13] = (dataOffset >> 24) AND 0x00FF
'
'	fill BITMAPINFOHEADER (first 6 members)
'
	info = 14
	image[info+0] = 40													' XLONG : BITMAPINFOHEADER size
	image[info+1] = 0
	image[info+2] = 0
	image[info+3] = 0
	image[info+4] = width AND 0x00FF						' XLONG : width in pixels
	image[info+5] = (width >> 8) AND 0x00FF
	image[info+6] = (width >> 16) AND 0x00FF
	image[info+7] = (width >> 24) AND 0x00FF
	image[info+8] = height AND 0x00FF						' XLONG : height in pixels
	image[info+9] = (height >> 8) AND 0x00FF
	image[info+10] = (height >> 16) AND 0x00FF
	image[info+11] = (height >> 24) AND 0x00FF
	image[info+12] = 1													' USHORT : # of planes
	image[info+13] = 0													'
	image[info+14] = 24													' USHORT : bits per pixel
	image[info+15] = 0													'
	image[info+16] = $BI_RGB										' XLONG : 24-bit RGB
	image[info+17] = 0													'
	image[info+18] = 0													'
	image[info+19] = 0													'
	image[info+20] = 0													' XLONG : sizeImage
	image[info+21] = 0													'
	image[info+22] = 0													'
	image[info+23] = 0													'
	image[info+24] = 0													' XLONG : xPPM
	image[info+25] = 0													'
	image[info+26] = 0													'
	image[info+27] = 0													'
	image[info+28] = 0													' XLONG : yPPM
	image[info+29] = 0													'
	image[info+30] = 0													'
	image[info+31] = 0													'
	image[info+32] = 0													' XLONG : clrUsed
	image[info+33] = 0													'
	image[info+34] = 0													'
	image[info+35] = 0													'
	image[info+36] = 0													' XLONG : clrImportant
	image[info+37] = 0													'
	image[info+38] = 0													'
	image[info+39] = 0													'
'
' note : the following are for 32-bit $$BI_BITFIELDS only,
' not for the current 24-bit RGB format
'
	cbit = info+40															' color bitmasks offset
	rbits = 0xFFC00000													' 10-bits - red
	gbits = 0x003FF800													' 11-bits - green
	bbits = 0x000007FF													' 11-bits - blue
'
'	image[cbit+0] = rbits AND 0x00FF
'	image[cbit+1] = (rbits >> 8) AND 0x00FF
'	image[cbit+2] = (rbits >> 16) AND 0x00FF
'	image[cbit+3] = (rbits >> 24) AND 0x00FF
'	image[cbit+4] = gbits AND 0x00FF
'	image[cbit+5] = (gbits >> 8) AND 0x00FF
'	image[cbit+6] = (gbits >> 16) AND 0x00FF
'	image[cbit+7] = (gbits >> 24) AND 0x00FF
'	image[cbit+8] = bbits AND 0x00FF
'	image[cbit+9] = (bbits >> 8) AND 0x00FF
'	image[cbit+10] = (bbits >> 16) AND 0x00FF
'	image[cbit+11] = (bbits >> 24) AND 0x00FF
'
	dataAddr = iAddr + dataOffset
	infoAddr = iAddr + 14
	data = dataOffset
'
	daddr = &image[]
	daddrImage = daddr + dataOffset
'
'
' *****  IMPORTANT NOTE  *****
'
' The next to last argument is called "plane_mask", and in an example in
' the "xlib programming manual" book, the constant "AllPlanes" is passed
' to indicate data from all bit planes should be returned.  That's great,
' and should work, but on Linux at least I wasted a whole frigging day
' trying to make this routine work until I figured I would try $$TRUE
' aka -1 aka 0xFFFFFFFF in the "plane_mask" argument.  Note that the
' xlib constant "AllPlanes" is 0x00000000, not -1.  Gimme a break someday!
'
	##WHOMASK = 0
	##LOCKOUT = 100089
'	a$ = "XGetImage().A\n"
'	write (1, &a$, LEN(a$))
	ximage = XGetImage (sdisplay, swindow, 0, 0, width, height, $$TRUE, $$ZPixmap)
'	a$ = "XGetImage().Z\n"
'	write (1, &a$, LEN(a$))
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	flushTime = eventTime
	XstGetSystemTime (@XSyncNowTime)
'
	IFZ ximage THEN
		##ERROR = ($$ErrorObjectSystemFunction << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrGetImage() : XGetImage() failed"
		DIM image[]
		RETURN ($$TRUE)
	END IF
'
	xwidth = XLONGAT (ximage, 0)
	xheight = XLONGAT (ximage, 4)
	xaddress = XLONGAT (ximage, 16)
	xdepth = XLONGAT (ximage, 36)
	xbytesperline = XLONGAT (ximage, 40)
	xbitsperpixel = XLONGAT (ximage, 44)
	xredmask = XLONGAT (ximage, 48)
	xgreenmask = XLONGAT (ximage, 52)
	xbluemask = XLONGAT (ximage, 56)
'
' look at the image header
'
'	test = $$TRUE
'	test = $$FALSE
'
'	IF test THEN GOSUB PrintImageHeader
'
' create a "pixel to rgb" cache to avoid excess XQueryColor() calls
'
	upper = 65535
	IFZ map[] THEN
		##WHOMASK = 0
		DIM map[upper]
		DIM cache[upper]
		##WHOMASK = whomask
	END IF
'
' keep previous entries if working on same display as last time
'
	IF (display != displayPrevious) THEN
		FOR i = 0 TO upper
			map[i].scolor = -1			' initialize to "empty/available" state
			cache[i].scolor = -1		' initialize to "empty/available" state
		NEXT i
		displayPrevious = display
	END IF
'
' see if we can read the memory more quickly if 8-bit pixels
'
	extra = $$FALSE
	quickie = $$FALSE
	IF xaddress THEN
		IF (xdepth = 8) THEN
			IF (xbitsperpixel = 8) THEN
				IF (xbytesperline >= xwidth) THEN
					extra = xbytesperline - xwidth
					IF (extra < 8) THEN quickie = $$TRUE
				END IF
			END IF
		END IF
	END IF
'
' get every pixel from image, convert into RGB, and put in DIB24
'
	xaddr = xaddress																		' addr of XWindows image
	data = dataOffset + (widthbytes * (height-1))				' array element of last scan line
	daddr = daddrImage + (widthbytes * (height-1))			' addr of last scan line in BMP array
'
	FOR y = 0 TO height-1
		scanlinedata = data
		scanlineaddr = daddr
		FOR x = 0 TO width-1
			IF quickie THEN
				scolor = UBYTEAT (xaddr)
				INC xaddr
			ELSE
				##WHOMASK = 0
				##LOCKOUT = 100090
				scolor = XGetPixel (ximage, x, y)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
'
			sc.scolor = scolor
'
' check for scolor in the map cache
'
			map = $$FALSE
			IF (scolor >= 0) THEN
				IF (scolor <= upper) THEN
					pixel = map[scolor].scolor
					IF (pixel != -1) THEN
						m = scolor
						map = $$TRUE
						sc = map[scolor]
					END IF
				END IF
			END IF
'
			IF (scolor >= 0) THEN
				IFZ map THEN
					cache = $$FALSE
					FOR c = 0 TO upper
						pixel = cache[c].scolor
						IF (pixel = -1) THEN EXIT FOR					' past all valid entries
						IF (pixel = scolor) THEN
							cache = $$TRUE
							sc = cache[c]
							EXIT FOR
						END IF
					NEXT c
				END IF
			END IF
'
			mm = 0 : IF map THEN mm = 1
			cc = c : IF cache THEN cc = 1
'
			IFZ (map OR cache) THEN
				##WHOMASK = 0
				##LOCKOUT = 100091
				rc = XQueryColor (sdisplay, colormap, &sc)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
'
			scolor = sc.scolor
'
' if scolor is not in map[] or cache[], put pixel scolor in map[] if it fits,
' otherwise if cache still has room, put pixel scolor in cache[]
'
			IFZ map THEN
				IF (scolor >= 0) THEN
					IF (scolor <= upper) THEN
						map[scolor] = sc
						map = $$TRUE
					END IF
				END IF
			END IF
'
			IFZ map THEN
				IFZ cache THEN
					IF (scolor >= 0) THEN
						IF (c <= upper) THEN cache[c] = sc
					END IF
				END IF
			END IF
'
' convert sc into 24-bit .BMP color - RGB = 8 bits each
'
			red = (sc.r >> 8) AND 0x00FF
			green = (sc.g >> 8) AND 0x00FF
			blue = (sc.b >> 8) AND 0x00FF
			image[data] = blue	: INC data
			image[data] = green	: INC data
			image[data] = red		: INC data
'
'			IF test THEN GOSUB PrintPixelInformation
'
		NEXT x
		IF quickie THEN xaddr = xaddr + extra
		daddr = scanlineaddr - widthbytes
		data = scanlinedata - widthbytes
	NEXT y
'
	##WHOMASK = 0
	##LOCKOUT = 100092
	XDestroyImage (ximage)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	RETURN ($$FALSE)
'
'
'
' *****  PrintImageHeader  *****
'
SUB PrintImageHeader
	xwidth = XLONGAT (ximage, 0)
	xheight = XLONGAT (ximage, 4)
	xoffset = XLONGAT (ximage, 8)
	xformat = XLONGAT (ximage, 12)
	xaddress = XLONGAT (ximage, 16)
	xbyteorder = XLONGAT (ximage, 20)
	xbitmapunit = XLONGAT (ximage, 24)
	xbitorder = XLONGAT (ximage, 28)
	xbitmappad = XLONGAT (ximage, 32)
	xdepth = XLONGAT (ximage, 36)
	xbytesperline = XLONGAT (ximage, 40)
	xbitsperpixel = XLONGAT (ximage, 44)
	xredmask = XLONGAT (ximage, 48)
	xgreenmask = XLONGAT (ximage, 52)
	xbluemask = XLONGAT (ximage, 56)
	xhooks = XLONGAT (ximage, 60)
	x0 = XLONGAT (ximage, 64)
	x1 = XLONGAT (ximage, 68)
	x2 = XLONGAT (ximage, 72)
	x3 = XLONGAT (ximage, 76)
	a$ = HEX$ (visual, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xwidth, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xheight, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xoffset, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xformat, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xaddress, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbyteorder, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitmapunit, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitorder, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitmappad, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xdepth, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbytesperline, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitsperpixel, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xredmask, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xgreenmask, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbluemask, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xhooks, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (x0, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (x1, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (x2, 8) + " "
	write (1, &a$, LEN(a$))
'
' print 16 scan lines of data
'
	IF xaddress THEN
		addr = xaddress
		FOR y = 0 TO 15
			FOR x = 0 TO xbytesperline
				byte = UBYTEAT (addr)
				a$ = HEX$ (byte, 2) + " "
				write (1, &a$, LEN(a$))
				INC addr
			NEXT x
			a$ = "\n"
			write (1, &a$, LEN(a$))
		NEXT y
	END IF
END SUB
'
'
' *****  PrintPixelInformation  *****
'
SUB PrintPixelInformation
	a$ = HEX$(y,4) + " " + HEX$(x,4) + " : " + HEX$(scolor,8) + " " + HEX$(dcolor, 8) + " : " + HEX$(red,8) + " " + HEX$(green,8) + " " + HEX$(blue,8) + " : " + HEX$(m,4) + " " + HEX$(c,4) + " : " + STRING$(mm) + " " + STRING$(cc) + "\n"
	write (1, &a$, LEN(a$))
END SUB
'
END FUNCTION
'
'
' ##############################
' #####  XgrGetImage32 ()  #####
' ##############################
'
' error = XgrGetImage32 (grid, @image[])
'
FUNCTION  XgrGetImage32 (grid, UBYTE image[])
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
	SHARED  flushTime
	STATIC  displayPrevious
	STATIC  XColor  cache[]
	STATIC  XColor  map[]
	UBYTE  dimage[]
	XColor  sc
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetImage32()lockout", lockout) : lockout = 0
'
	DIM image[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrGetImage32() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	width = window[window].width					' image/grid width
	height = window[window].height				' image/grid height
	visual = window[window].visual				' visual (DirectColor, TrueColor, etc)
	swindow = window[window].swindow			' system image/grid #
	display = window[window].display			' native display #
	sdisplay = window[window].sdisplay		' system display #
	colormap = display[display].colormap	' system colormap
'
	IF (width <= 0) THEN RETURN ($$FALSE)
	IF (height <= 0) THEN RETURN ($$FALSE)
'
' compute size of DIB32 and create dimage[] array to hold it
'
	dataOffset = 128
	widthbytes = width << 2
	dsize = dataOffset + (height * widthbytes)		' size of image[] array
	dupper = dsize - 1														' upper bound of image[] array
	DIM dimage[dupper]														' destination image[] in DIB32
'
' initialize destination image[] array header with DIB32 format info
'
	daddr = &dimage[]											' start addr of destination image[] array
	daddrImage = daddr + 256							' start addr of destination image data
	daddrPalette = daddr + 64							' start addr of destination color masks
'
	UBYTEAT (daddr, 0) = 'B'							' okay : DIB signature = "BM"
	UBYTEAT (daddr, 1) = 'M'							' okay : DIB signature = "BM"
	XLONGAT (daddr, 2) = dsize						' boom : # of bytes in dimage[]
	XLONGAT (daddr, 10) = 256							' boom : offset to image data
	XLONGAT (daddr, 14) = 50							' boom : # of bytes in info data (to color masks)
	XLONGAT (daddr, 18) = width						' boom : width of image in pixels
	XLONGAT (daddr, 22) = height					' boom : height of image in pixels
	USHORTAT (daddr, 26) = 1							' okay : # of planes == 1
	USHORTAT (daddr, 28) = 32							' okay : # of bits per pixel
	XLONGAT (daddr, 30) = 3								' boom : "compression" == BI_BITFIELDS
	XLONGAT (daddr, 34) = 0								' boom : 0 == image not compressed
	XLONGAT (daddr, 38) = 0								' boom : who knows ???
	XLONGAT (daddr, 42) = 0								' boom : who knows ???
	XLONGAT (daddr, 46) = 0								' boom : # of colors in palette == 0
	XLONGAT (daddr, 50) = 0								' boom : # of important colors == 0
'
	dredMask = 0xFFC00000									' 10 bits
	dgreenMask = 0x003FF800								' 11 bits
	dblueMask = 0x000007FF								' 11 bits
'
	XLONGAT (daddrPalette, 0) = dredMask
	XLONGAT (daddrPalette, 4) = dgreenMask
	XLONGAT (daddrPalette, 8) = dblueMask
'
' *****  IMPORTANT NOTE  *****
'
' The next to last argument is called "plane_mask", and in an example in
' the "xlib programming manual" book, the constant "AllPlanes" is passed
' to indicate data from all bit planes should be returned.  That's great,
' and should work, but on Linux at least I wasted a whole frigging day
' trying to make this routine work until I figured I would try $$TRUE
' aka -1 aka 0xFFFFFFFF in the "plane_mask" argument.  Note that the
' xlib constant "AllPlanes" is 0x00000000, not -1.  Gimme a break someday!
'
	##WHOMASK = 0
	##LOCKOUT = 100093
'	a$ = "XGetImage().A\n"
'	write (1, &a$, LEN(a$))
	ximage = XGetImage (sdisplay, swindow, 0, 0, width, height, $$TRUE, $$ZPixmap)
'	a$ = "XGetImage().Z\n"
'	write (1, &a$, LEN(a$))
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	flushTime = eventTime
	XstGetSystemTime (@XSyncNowTime)
'
	IFZ ximage THEN
		##ERROR = ($$ErrorObjectSystemFunction << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrGetImage32() : XGetImage() failed"
		RETURN ($$TRUE)
	END IF
'
	xwidth = XLONGAT (ximage, 0)
	xheight = XLONGAT (ximage, 4)
	xaddress = XLONGAT (ximage, 16)
	xdepth = XLONGAT (ximage, 36)
	xbytesperline = XLONGAT (ximage, 40)
	xbitsperpixel = XLONGAT (ximage, 44)
	xredmask = XLONGAT (ximage, 48)
	xgreenmask = XLONGAT (ximage, 52)
	xbluemask = XLONGAT (ximage, 56)
'
' look at the image header
'
'	test = $$TRUE
'	test = $$FALSE
'
'	IF test THEN GOSUB PrintImageHeader
'
' create a "pixel to rgb" cache to avoid excess XQueryColor() calls
'
	upper = 65535
	IFZ map[] THEN
		##WHOMASK = 0
		DIM map[upper]
		DIM cache[upper]
		##WHOMASK = whomask
	END IF
'
' keep previous entries if working on same display as last time
'
	IF (display != displayPrevious) THEN
		FOR i = 0 TO upper
			map[i].scolor = -1			' initialize to "empty/available" state
			cache[i].scolor = -1		' initialize to "empty/available" state
		NEXT i
		displayPrevious = display
	END IF
'
' see if we can read the memory more quickly if 8-bit pixels
'
	extra = $$FALSE
	quickie = $$FALSE
	IF xaddress THEN
		IF (xdepth = 8) THEN
			IF (xbitsperpixel = 8) THEN
				IF (xbytesperline >= xwidth) THEN
					extra = xbytesperline - xwidth
					IF (extra < 8) THEN quickie = $$TRUE
				END IF
			END IF
		END IF
	END IF
'
' get every pixel from image, convert into RGB, and put in DIB32
'
	xaddr = xaddress
	data = dataOffset + (widthbytes * (height-1))				' array element of last scan line
	daddr = daddrImage + (widthbytes * (height-1))			' addr of last scan line in BMP array
'
	FOR y = 0 TO height-1
		scanlinedata = data
		scanlineaddr = daddr
		FOR x = 0 TO width-1
			IF quickie THEN
				scolor = UBYTEAT (xaddr)
				INC xaddr
			ELSE
				##WHOMASK = 0
				##LOCKOUT = 100094
				scolor = XGetPixel (ximage, x, y)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
'
			sc.scolor = scolor
'
' check for scolor in the map cache
'
			map = $$FALSE
			IF (scolor >= 0) THEN
				IF (scolor <= upper) THEN
					pixel = map[scolor].scolor
					IF (pixel != -1) THEN
						m = scolor
						map = $$TRUE
						sc = map[scolor]
					END IF
				END IF
			END IF
'
			IF (scolor >= 0) THEN
				IFZ map THEN
					cache = $$FALSE
					FOR c = 0 TO upper
						pixel = cache[c].scolor
						IF (pixel = -1) THEN EXIT FOR					' past all valid entries
						IF (pixel = scolor) THEN
							cache = $$TRUE
							sc = cache[c]
							EXIT FOR
						END IF
					NEXT c
				END IF
			END IF
'
			mm = 0 : IF map THEN mm = 1
			cc = c : IF cache THEN cc = 1
'
			IFZ (map OR cache) THEN
				##WHOMASK = 0
				##LOCKOUT = 100095
				rc = XQueryColor (sdisplay, colormap, &sc)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
'
			scolor = sc.scolor
'
' if scolor is not in map[] or cache[], put pixel scolor in map[] if it fits,
' otherwise if cache still has room, put pixel scolor in cache[]
'
			IFZ map THEN
				IF (scolor >= 0) THEN
					IF (scolor <= upper) THEN
						map[scolor] = sc
						map = $$TRUE
					END IF
				END IF
			END IF
'
			IFZ map THEN
				IFZ cache THEN
					IF (scolor >= 0) THEN
						IF (c <= upper) THEN cache[c] = sc
					END IF
				END IF
			END IF
'
' convert sc into 32-bit .BMP color - RGB = 10,11,11 bits with R in most significant 10 bits
'
			red = (sc.r << 16) AND dredMask
			green = (sc.g << 6) AND dgreenMask
			blue = (sc.b >> 5) AND dblueMask
			dcolor = red OR green OR blue							' 10-11-11 rgb color
			XLONGAT (daddr) = dcolor
			daddr = daddr + 4
'
'			IF test THEN GOSUB PrintPixelInformation
'
		NEXT x
		IF quickie THEN xaddr = xaddr + extra
		daddr = scanlineaddr - widthbytes
		data = scanlinedata - widthbytes
	NEXT y
'
	##WHOMASK = 0
	##LOCKOUT = 100096
	XDestroyImage (ximage)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	SWAP image[], dimage[]
	RETURN ($$FALSE)
'
'
'
' *****  PrintImageHeader  *****
'
SUB PrintImageHeader
	xwidth = XLONGAT (ximage, 0)
	xheight = XLONGAT (ximage, 4)
	xoffset = XLONGAT (ximage, 8)
	xformat = XLONGAT (ximage, 12)
	xaddress = XLONGAT (ximage, 16)
	xbyteorder = XLONGAT (ximage, 20)
	xbitmapunit = XLONGAT (ximage, 24)
	xbitorder = XLONGAT (ximage, 28)
	xbitmappad = XLONGAT (ximage, 32)
	xdepth = XLONGAT (ximage, 36)
	xbytesperline = XLONGAT (ximage, 40)
	xbitsperpixel = XLONGAT (ximage, 44)
	xredmask = XLONGAT (ximage, 48)
	xgreenmask = XLONGAT (ximage, 52)
	xbluemask = XLONGAT (ximage, 56)
	xhooks = XLONGAT (ximage, 60)
	x0 = XLONGAT (ximage, 64)
	x1 = XLONGAT (ximage, 68)
	x2 = XLONGAT (ximage, 72)
	x3 = XLONGAT (ximage, 76)
	a$ = HEX$ (visual, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xwidth, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xheight, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xoffset, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xformat, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xaddress, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbyteorder, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitmapunit, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitorder, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitmappad, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xdepth, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbytesperline, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbitsperpixel, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xredmask, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xgreenmask, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xbluemask, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (xhooks, 8) + "\n"
	write (1, &a$, LEN(a$))
	a$ = HEX$ (x0, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (x1, 8) + " "
	write (1, &a$, LEN(a$))
	a$ = HEX$ (x2, 8) + " "
	write (1, &a$, LEN(a$))
'
' print 16 scan lines of data
'
	IF xaddress THEN
		addr = xaddress
		FOR y = 0 TO 15
			FOR x = 0 TO xbytesperline
				byte = UBYTEAT (addr)
				a$ = HEX$ (byte, 2) + " "
				write (1, &a$, LEN(a$))
				INC addr
			NEXT x
			a$ = "\n"
			write (1, &a$, LEN(a$))
		NEXT y
	END IF
END SUB
'
'
' *****  PrintPixelInformation  *****
'
SUB PrintPixelInformation
	a$ = HEX$(y,4) + " " + HEX$(x,4) + " : " + HEX$(scolor,8) + " " + HEX$(dcolor, 8) + " : " + HEX$(red,8) + " " + HEX$(green,8) + " " + HEX$(blue,8) + " : " + HEX$(m,4) + " " + HEX$(c,4) + " : " + STRING$(mm) + " " + STRING$(cc) + "\n"
	write (1, &a$, LEN(a$))
END SUB
'
END FUNCTION
'
'
' #####################################
' #####  XgrGetImageArrayInfo ()  #####
' #####################################
'
' error = XgrGetImageArrayInfo (@image[], @bitsPerPixel, @width, @height)
'
FUNCTION  XgrGetImageArrayInfo (UBYTE image[], bitsPerPixel, width, height)
'
	IFZ image[] THEN RETURN ($$TRUE)
	bytes = SIZE (image[])
	iAddr = &image[]
'
	IF (bytes < 32) THEN
		error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
		old = ERROR (error)
		IF ##XBDV THEN PRINT "XgrGetImageArrayInfo() : file too small "; bytes
		RETURN ($$TRUE)
	END IF
'
	byte0 = image[0]
	byte1 = image[1]
'
	IF ((byte0 != 'B') OR (byte1 != 'M')) THEN
		IF (byte0 == 'P') THEN                                                     ' might be a Linux PBM, PGM, PPM
			error = XgrGetImageArrayInfoPNM (@image[], @bitsPerPixel, @width, @height)
			RETURN (error)
		END IF
		error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
		old = ERROR (error)
		IF ##XBDV THEN PRINT "XgrGetImageArrayInfo() : invalid format \""; CHR$(byte0); CHR$(byte1);"\""
		RETURN ($$TRUE)
	END IF
'
	byte2 = image[2]
	byte3 = image[3]
	byte4 = image[4]
	byte5 = image[5]
	fileSize = (byte5 << 24) OR (byte4 << 16) OR (byte3 << 8) OR byte2
'
	byte14 = image[14]
	byte15 = image[15]
	byte16 = image[16]
	byte17 = image[17]
	headerSize = (byte17 << 24) OR (byte16 << 16) OR (byte15 << 8) OR byte14
'
	info = 14
'
	IF (headerSize = 12) THEN							' BITMAPCOREINFO
		w0 = image[info+4]
		w1 = image[info+5]
		h0 = image[info+6]
		h1 = image[info+7]
		b0 = image[info+10]
		b1 = image[info+11]
		width = (w1 << 8) OR w0
		height = (h1 << 8) OR h0
		bitsPerPixel = (b1 << 8) OR b0
	ELSE																	' BITMAPINFO
		w0 = image[info+4]
		w1 = image[info+5]
		w2 = image[info+6]
		w3 = image[info+7]
		h0 = image[info+8]
		h1 = image[info+9]
		h2 = image[info+10]
		h3 = image[info+11]
		b0 = image[info+14]
		b1 = image[info+15]
		width = (w3 << 24) OR (w2 << 16) OR (w1 << 8) OR w0
		height = (h3 << 24) OR (h2 << 16) OR (h1 << 8) OR h0
		bitsPerPixel = (b1 << 8) OR b0
	END IF
END FUNCTION
'
'
' ########################################
' #####  XgrGetImageArrayInfoPNM ()  ##### 151220-+
' ########################################
'
' error = XgrGetImageArrayInfoPNM (@image[], @bitsPerPixel, @width, @height)
'
' See: XgrGetImageArrayInfo()
'
FUNCTION  XgrGetImageArrayInfoPNM (UBYTE image[], bitsPerPixel, width, height)
'
	size = SIZE (image[])
'
	IF (size < 64) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrGetImageArrayInfoPNM() : input argument image[] too small"
		RETURN ($$TRUE)
	END IF
'
	GOSUB GetParameter : signature$ = parameter$
	GOSUB GetParameter : width$     = parameter$
	GOSUB GetParameter : height$    = parameter$
	'
	width   = ABS (XLONG (width$))
	height  = ABS (XLONG (height$))

	SELECT CASE signature$
		CASE "P1", "P4" : bitsPerPixel = 1 : RETURN    ' black and white
		CASE "P2", "P5" : bitsPerPixel = 8             ' grey scale
		CASE "P3", "P6" : bitsPerPixel = 8             ' color
		CASE ELSE
			error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
			old = ERROR (error)
			PRINT "XgrGetImageArrayInfoPNM(): Invalid Format", signature$
			RETURN ($$TRUE)
	END SELECT
	'
	GOSUB GetParameter : maxColor$  = parameter$
	maxColor = ABS (XLONG (maxColor$))
	IF ((maxColor < 1) || (maxColor > 65535)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidFormat
		IF ##XBDV THEN PRINT "XgrGetImageArrayInfoPNM() : Invalid max color", maxColor
		RETURN ($$TRUE)
	END IF
	IF (maxColor >= 256) THEN  bitsPerPixel = 16
	'
	RETURN
'------------------------------------------------------------------
'
' *****  GetParameter  *****
'
SUB GetParameter
	IF (index < 0) THEN index = 0
	comment = $$FALSE
	parameter$ = ""
	DO
		char = image[index]
		INC index
		SELECT CASE char
			CASE 0x0A : IFZ comment THEN EXIT SUB              ' new-line
									comment = $$FALSE
									parameter$ = ""
									DO LOOP
			CASE 0x20 : IFZ comment THEN EXIT SUB              ' space character
			CASE 0x23 : IFZ parameter$ THEN comment = $$TRUE   ' "#"
			CASE 0x09 : IFZ comment THEN EXIT SUB              ' tab character
			CASE 0x0B : IFZ comment THEN EXIT SUB              ' vertical-tab character
			CASE 0x0C : IFZ comment THEN EXIT SUB              ' form-feed character
			CASE 0x0D : IFZ comment THEN EXIT SUB              ' carriage-return character
		END SELECT
		'
		IF ((char >= 0x20) && (char < 0x7F)) THEN
			parameter$ = parameter$ + CHR$(char)
		ELSE
			EXIT DO
		END IF
	LOOP
	PRINT "XgrGetImageArrayInfoPNM(): Invalid character in header", HEXX$(char), index-1
END SUB
'
END FUNCTION
'
'
' #############################
' #####  XgrLoadImage ()  #####
' #############################
'
' error = XgrLoadFile (filename$, @file@@[])
'
' Load an entire filename$ file from disk into a UBYTE array @file@@[].
'
FUNCTION  XgrLoadFile (filename$, UBYTE file[])
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrLoadFile()lockout", lockout) : lockout = 0
'
	DIM file[]
'
	IFZ filename$ THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		RETURN ($$TRUE)
	END IF
'
	file$ = XstPathString$ (@filename$)
'
	ifile = OPEN (file$, $$RD)
'
	IF (ifile <= 0) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		RETURN ($$TRUE)
	END IF
'
	insize = LOF (ifile)
'
	upper = insize - 1			' upper bound of UBYTE file[]
	DIM file[upper]					' UBYTE file[] big enough for whole file
'
	READ [ifile], file[]		' read whole file into UBYTE file[]
	CLOSE (ifile)						' done with file on disk
'
END FUNCTION
'
'
' #############################
' #####  XgrLoadImage ()  #####
' #############################
'
' error = XgrLoadImage (filename$, @image[])
'
FUNCTION  XgrLoadImage (filename$, UBYTE image[])
	UBYTE  file[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrLoadImage()lockout", lockout) : lockout = 0
'
	DIM image[]
'
	IFZ filename$ THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrLoadImage() : invalid (blank) file$ argument"
		RETURN ($$TRUE)
	END IF
'
	file$ = XstPathString$ (@filename$)
'
	ifile = OPEN (file$, $$RD)
'
	IF (ifile <= 0) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrLoadImage() : invalid file$ argument", file$
		RETURN ($$TRUE)
	END IF
'
	insize = LOF (ifile)
	IF (insize <= 64) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureEmpty
		IF ##XBDV THEN PRINT "XgrLoadImage() : image file is empty or too small : "; file$
		RETURN ($$TRUE)
	END IF
'
	upper = insize - 1			' upper bound of UBYTE file[]
	DIM file[upper]					' UBYTE file[] big enough for whole DIB file
'
	READ [ifile], file[]		' read whole DIB file into UBYTE file[]
	CLOSE (ifile)						' done with DIB file on disk
'
	IF (file[0] == 'P') THEN
		IF (file[1] <= '6') THEN
			IF (file[1] >= '1') THEN
				SWAP file[], image[]
				RETURN
			END IF
		END IF
	END IF
'
	IF ((file[0] != 'B') OR (file[1] != 'M')) THEN
		##ERROR = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidSignature
		IF ##XBDV THEN PRINT "XgrLoadImage() : invalid DIB signature"
		RETURN ($$TRUE)
	END IF
'
' DIBToDIB32() converts 1,4,8,16,24,32 bits per pixel DIBs into the
' native standard DIB, which has 32 bits per pixel with red-green-blue
' fields having 10-11-11 bits (from MSb to LSb in XLONG).
'
'	IF ##CAPSLOCK THEN SWAP file[], image[] : RETURN
	SWAP file[], image[] : RETURN
	r = XxxDIBToDIB32 (@file[], @image[])
	RETURN (r)
END FUNCTION
'
'
' ###############################
' #####  XgrRefreshGrid ()  #####
' ###############################
'
FUNCTION  XgrRefreshGrid (grid)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrRefreshGrid()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrRefreshGrid() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	IFZ WindowEnabledVisible (grid) THEN RETURN ($$FALSE)
'
	image = window[window].buffer
'	IF ##XBDV THEN PRINT "XgrRefreshGrid() : "; grid, image
	IF (image <= 0) THEN RETURN ($$FALSE)			' no buffer grid is okay
'
	IF InvalidGrid (image) THEN
		IF ##XBDV THEN PRINT "XgrRefreshGrid() : invalid buffer grid #"
		RETURN ($$TRUE)
	END IF
'
	igt = window[image].type
	IF (igt != #GridTypeImage) THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalidType
		IF ##XBDV THEN PRINT "XgrRefreshGrid() : buffer grid != #GridTypeImage"
		RETURN ($$TRUE)
	END IF
'
' get offset of buffer on grid
'
	xbuf = window[window].bufferX
	ybuf = window[window].bufferY
'
	IFZ (xbuf OR ybuf) THEN
		return = XgrCopyImage (grid, image)
		RETURN (return)
	END IF
'
	sx1 = 0
	dx1 = 0
	IF (xbuf < 0) THEN sx1 = ABS(xbuf) ELSE dx1 = xbuf
	dx2 = window[window].width - 1
	IF (dx1 > dx2) THEN RETURN ($$FALSE)
	sx2 = window[image].width - 1
	sxmax = dx2 - dx1 + sx1 - xbuf
	IF (sxmax < sx2) THEN sx2 = sxmax
	IF (sx1 > sx2) THEN RETURN ($$FALSE)
'
	sy1 = 0
	dy1 = 0
	IF (ybuf < 0) THEN sy1 = ABS(ybuf) ELSE dy1 = ybuf
	dy2 = window[window].width - 1
	IF (dy1 > dy2) THEN RETURN ($$FALSE)
	sy2 = window[image].height - 1
	symax = dy2 - dy1 + sy1 - ybuf
	IF (symax < sy2) THEN sy2 = symax
	IF (sy1 > sy2) THEN RETURN ($$FALSE)

'
	return = XgrDrawImage (grid, image, sx1, sy1, sx2, sy2, dx1, dy1)
	RETURN (return)
'
END FUNCTION
'
'
' #############################
' #####  XgrSaveImage ()  #####
' #############################
'
FUNCTION  XgrSaveImage (file$, UBYTE image[])
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSaveImage()lockout", lockout) : lockout = 0
'
	IFZ file$ THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidName
		IF ##XBDV THEN PRINT "XgrSaveImage() : empty file$ string"
		RETURN ($$TRUE)
	END IF
'
	IFZ image[] THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrSaveImage() : image[] array is empty"
		RETURN ($$TRUE)
	END IF
'
	size = SIZE (image[])
'
	IF (size < 260) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrSaveImage() : input argument image[] too small"
		RETURN ($$TRUE)
	END IF
'
	byte0 = image[0]
	byte1 = image[1]
'
	IF ((byte0 == 'B') && (byte1 == 'M')) THEN
		byte2 = image[2]
		byte3 = image[3]
		byte4 = image[4]
		byte5 = image[5]
'
		bytes = (byte5 << 24) OR (byte4 << 16) OR (byte3 << 8) OR byte2
'
		IF (size < bytes) THEN
			error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
			old = ERROR (error)
			RETURN ($$TRUE)
		END IF
	ELSE
		IF (byte0 != 'P') THEN invalidFormat = $$TRUE
		IF (byte1 > '6')  THEN invalidFormat = $$TRUE
		IF (byte1 < '1')  THEN invalidFormat = $$TRUE
	END IF
'
	IF invalidFormat THEN
		error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	ofile = OPEN (file$, $$WRNEW)
'
	IF (ofile < 3) THEN
		error = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalid
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
'	IF ##XBDV THEN PRINT "XgrSaveImage(76)", file$
	byteWrite = XstBinWrite (ofile, &image[], size)
	CLOSE (ofile)
END FUNCTION
'
'
' ############################
' #####  XgrSetImage ()  #####
' ############################
'
FUNCTION  XgrSetImage (grid, UBYTE image[])
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
	SHARED  flushTime
	SHARED  tableR[], tableG[], tableB[]
	XColor  sc
'
	$BI_RGB       = 0					' 24-bit RGB
	$BI_BITFIELDS = 3					' 32-bit RGB
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetImage()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetImage() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	size = SIZE (image[])
'
	IF (size < 64) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrSetImage() : input argument image[] too small"
		RETURN ($$TRUE)
	END IF
'
	display = window[grid].display
	simage = window[grid].swindow       ' system pixmap #
	IFZ simage THEN RETURN ($$FALSE)		' no destination image
'
	signature0      = image[0]                             ' "B" (0x42) DIB aka BMP signature
	signature1      = image[1]                             ' "M" (0x4D)
	IF ((signature0 != 'B') OR (signature1 != 'M')) THEN
		IF (signature0 == 'P') THEN                          ' might be a Linux PBM, PGM, PPM
			error = XgrSetImagePNM (grid, @image[])
			RETURN (error)
		END IF
		error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
	'
	fileSize        = ULONGAT(&image[], 2)       ' bytes 2,3,4,5 = file size
	IF (size < fileSize) THEN
		error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
		IF ##XBDV THEN PRINT "XgrSetImage() : error : (size < fileSize) : "; size;; fileSize
		old = ERROR (error)
		RETURN ($$TRUE)
	END IF
	'
	reserved        = ULONGAT(&image[], 6)       ' bytes  6, 7, 8, 9 = zero
	dataOffset      = ULONGAT(&image[], 10)      ' bytes 10,11,12,13 = offset to bitmap area
	headerSize      = ULONGAT(&image[], 14)      ' bytes 14,15,16,17 = BITMAPINFOHEADER size
	'
	IF (headerSize == 12) THEN							' BITMAPCOREINFO
		biWidth         = USHORTAT(&image[], 18)     ' bytes 18,19 = image width
		biHeight        = USHORTAT(&image[], 20)     ' bytes 20,21 = image height
		planes          = USHORTAT(&image[], 22)     ' bytes 22,23 = number of planes (must be 1)
		bitsPerPixel    = USHORTAT(&image[], 24)     ' bytes 24,25 = bits per pixel
	ELSE
		biWidth         = SLONGAT(&image[], 18)      ' bytes 18,19,20,21 = image width
		biHeight        = SLONGAT(&image[], 22)      ' bytes 22,23,24,25 = image height
		planes          = USHORTAT(&image[], 26)     ' bytes 26,27       = number of planes
		bitsPerPixel    = USHORTAT(&image[], 28)     ' bytes 28,29       = bits per pixel
		'
		compression     = ULONGAT(&image[], 30)      ' bytes 30,31,32,33 = zero, no compression
		imageDataSize   = ULONGAT(&image[], 34)      ' bytes 34,35,36,37 = bytes of image data
		biXPelsPerMeter = SLONGAT(&image[], 38)      ' bytes 38,39,40,41 = horizontal dots per meter
		biYPelsPerMeter = SLONGAT(&image[], 42)      ' bytes 42,43,44,45 = vertical dots per meter
		biClrUsed       = ULONGAT(&image[], 46)      ' bytes 46,47,48,49 = number of colors in color table
		biClrImportant  = ULONGAT(&image[], 50)      ' bytes 50,51,52,53 = number of important colors
		'
		IF ((headerSize >= 52) || ((headerSize == 40) AND (compression == $BI_BITFIELDS))) THEN
			redBitmask       = ULONGAT(&image[], 54)   ' bytes 54,55,56,57
			greenBitmask     = ULONGAT(&image[], 58)   ' bytes 58,59,60,61
			blueBitmask      = ULONGAT(&image[], 62)   ' bytes 62,63,64,65
		END IF
		'
		IF (headerSize >= 56)
			alphaBitmask     = ULONGAT(&image[], 66)   ' bytes 66,67,68,69
		END IF
	END IF
'
	swidth  = ABS(biWidth)                ' DIB width is negative for reverse scan
	sheight = ABS(biHeight)               ' DIB height is negative for reverse scan
'
	dwidth = window[grid].width           ' pixmap width
	dheight = window[grid].height         ' pixmap height
'
	IF (dwidth <= 0) THEN RETURN ($$FALSE)
	IF (dheight <= 0) THEN RETURN ($$FALSE)
'
	gc = window[grid].gc                  ' system gc
	swindow = window[grid].swindow        ' system window # of pixmap
	sdisplay = window[grid].sdisplay      ' system display #
	colormap = display[display].colormap	' system colormap #
'
	IFZ tableR[] THEN GOSUB InitRGBTables ' need red, green and blue lookup tables
	'
	' If not an image type of grid and it is in the process of being
	' displayed or resized, wait for that to be completed first.
	'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
' get XImage - XWindows memory "image" for the existing pixmap
'
	##WHOMASK = 0
	##LOCKOUT = 100097
	ximage = XGetImage (sdisplay, simage, 0, 0, dwidth, dheight, $$AllPlanes, $$ZPixmap)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	flushTime = eventTime
	XstGetSystemTime (@XSyncNowTime)
'
	IFZ ximage THEN
		##ERROR = ($$ErrorObjectImage << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrSetImage() : XSetImage() failed"
		RETURN ($$TRUE)
	END IF
'
' transfer the DIB image to the pixmap
'
	data = dataOffset
	saddr = &image[] + dataOffset
'
	SELECT CASE bitsPerPixel
		CASE 24		: GOSUB DIB24
		CASE 32		: GOSUB DIB32
		CASE 16		: GOSUB DIB16
		CASE 8		: GOSUB DIB8
		CASE 4		: GOSUB DIB4
		CASE 2		: GOSUB DIB2
		CASE 1		: GOSUB DIB1
		CASE ELSE :	error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
								IF ##XBDV THEN PRINT "XgrSetImage() : invalid bitsPerPixel : "; bitsPerPixel
								old = ERROR (error)
								RETURN ($$TRUE)
	END SELECT
	'
	' put image into pixmap = image grid
	'
	##WHOMASK = 0
	##LOCKOUT = 100098
	XPutImage (sdisplay, simage, gc, ximage, 0, 0, 0, 0, dwidth, dheight)
	XDestroyImage (ximage)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask
'
RETURN
'
' -----------------------------------------------------------------------
'
' *****  DIB24  *****
'
SUB DIB24
'	IF ##XBDV THEN PRINT "XgrSetImage()-DIB24"
	XstGetSystemTime (@#dib24a)
	'
	rowSize = ((swidth * 3) + 3) AND -4                ' bytes of data for each row of pixels
	xStart = 0 : xEnd = swidth -1 : xStep = 1          ' normally left to right
	IF (dwidth < swidth) THEN xEnd = dwidth -1         ' destination narrower than source ?
	IF (biWidth < 0) THEN                              ' negative width for right to left
		SWAP xStart, xEnd
		xStep = -1
	END IF
	'
	yStart = sheight-1 : yEnd = 0 : yStep = -1         ' normally botton up
	IF (dheight < sheight) THEN yStart = dheight -1    ' destination smaller than source ?
	IF (biHeight < 0) THEN                             ' negative height for top down
		SWAP yStart, yEnd
		yStep = 1
	END IF
	'
	upperSheight = sheight - 1
	FOR y = yStart TO yEnd STEP yStep
		IF (yStep < 0) THEN
			data = (upperSheight - y) * rowSize + dataOffset
		ELSE
			data = y * rowSize + dataOffset
		END IF
		'
		##WHOMASK = 0
		##LOCKOUT = 100099
		'
		FOR x = xStart TO xEnd STEP xStep
			blue = image[data]  : INC data
			green = image[data] : INC data
			red = image[data] 	: INC data
			scolor = tableB[blue] OR tableG[green] OR tableR[red]
			XPutPixel (ximage, x, y, scolor)
		NEXT x
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
	'
	XstGetSystemTime (@#dib24b)
END SUB
'
' *****  DIB32  *****
'
SUB DIB32
'	IF ##XBDV THEN PRINT "XgrSetImage()-DIB32"
	XstGetSystemTime (@#dib32a)
	'
	' calculate the shift needed to position the color in bits 7-0
	'
	shiftRed   = HIGH1(redBitmask)   - 7
	shiftGreen = HIGH1(greenBitmask) - 7
	shiftBlue  = HIGH1(blueBitmask)  - 7
	'
	rowSize = swidth * 4                               ' bytes of data for each row of pixels
	xStart = 0 : xEnd = swidth -1 : xStep = 1          ' normally left to right
	IF (dwidth < swidth) THEN xEnd = dwidth -1         ' destination narrower than source ?
	IF (biWidth < 0) THEN                              ' negative width for right to left
		SWAP xStart, xEnd
		xStep = -1
	END IF
	'
	yStart = sheight-1 : yEnd = 0 : yStep = -1         ' normally botton up
	IF (dheight < sheight) THEN yStart = dheight -1    ' destination smaller than source ?
	IF (biHeight < 0) THEN                             ' negative height for top down
		SWAP yStart, yEnd
		yStep = 1
	END IF
	'
	upperSheight = sheight - 1
	FOR y = yStart TO yEnd STEP yStep
		IF (yStep < 0) THEN
			dataAddr = (upperSheight - y) * rowSize + saddr
		ELSE
			dataAddr = y * rowSize + saddr
		END IF
		'
		##WHOMASK = 0
		##LOCKOUT = 100100
		FOR x = xStart TO xEnd STEP xStep
			pixel = XLONGAT (dataAddr)              ' source data address
			dataAddr = dataAddr + 4                 ' 4 bytes per pixel
			'
			' ROTATER() is used because it will handle negative shift values
			' but AND 0xFF is needed to zero bits rotated to the top
			'
			red   =  ROTATER(pixel AND redBitmask, shiftRed) AND 0xFF
			green =  ROTATER(pixel AND greenBitmask, shiftGreen) AND 0xFF
			blue  =  ROTATER(pixel AND blueBitmask, shiftBlue) AND 0xFF
			scolor = tableB[blue] OR tableG[green] OR tableR[red]
			XPutPixel (ximage, x, y, scolor)
		NEXT x
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
	'
	XstGetSystemTime (@#dib32b)
END SUB
'
' *****  DIB16  *****
'
SUB DIB16
	XstGetSystemTime (@#dib16a)
	'
	' If headerSize does not include bitmask information
	' and no optional compression, set bitmask to 5.5.5
	' with one bit (15) unused.
	'
	IF ((headerSize == 40) AND (compression == $BI_RGB)) THEN
		redBitmask   = 0x7C00                 ' bits 14-10 red
		greenBitmask = 0x03E0                 ' bits  9-5  green
		blueBitmask  = 0x001F                 ' bits  4-0  blue
	END IF
	'
	' calculate the shift needed to position the color in bits 7-0
	'
	shiftRed   = HIGH1(redBitmask)   - 7
	shiftGreen = HIGH1(greenBitmask) - 7
	shiftBlue  = HIGH1(blueBitmask)  - 7
	'
'	rowSize = swidth * 4                               ' bytes of data for each row of pixels
	rowSize = ((swidth * 2) + 3) AND -4                ' bytes of data for each row of pixels
	xStart = 0 : xEnd = swidth -1 : xStep = 1          ' normally left to right
	IF (dwidth < swidth) THEN xEnd = dwidth -1         ' destination narrower than source ?
	IF (biWidth < 0) THEN                              ' negative width for right to left
		SWAP xStart, xEnd
		xStep = -1
	END IF
	'
	yStart = sheight-1 : yEnd = 0 : yStep = -1         ' normally botton up
	IF (dheight < sheight) THEN yStart = dheight -1    ' destination smaller than source ?
	IF (biHeight < 0) THEN                             ' negative height for top down
		SWAP yStart, yEnd
		yStep = 1
	END IF
	'
	upperSheight = sheight - 1
	FOR y = yStart TO yEnd STEP yStep
		IF (yStep < 0) THEN
			dataAddr = (upperSheight - y) * rowSize + saddr
		ELSE
			dataAddr = y * rowSize + saddr
		END IF
		'
		##WHOMASK = 0
		##LOCKOUT = 100101
		FOR x = xStart TO xEnd STEP xStep
			pixel = XLONGAT (dataAddr)              ' source data address
			dataAddr = dataAddr + 2                 ' 2 bytes per pixel
			'
			' ROTATER() is used because it will handle negative shift values
			' but AND 0xFF is needed to zero bits rotated to the top
			'
			red   =  ROTATER(pixel AND redBitmask, shiftRed) AND 0xFF
			green =  ROTATER(pixel AND greenBitmask, shiftGreen) AND 0xFF
			blue  =  ROTATER(pixel AND blueBitmask, shiftBlue) AND 0xFF
			scolor = tableB[blue] OR tableG[green] OR tableR[red]
			XPutPixel (ximage, x, y, scolor)
		NEXT x
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
	'
	XstGetSystemTime (@#dib16b)
END SUB
'
'
' *****  DIB8  *****
'
SUB DIB8
	XstGetSystemTime (@#dib8a)
	'
	' Assume 256 colors unless biClrUsed is less
	'
	upper = 255
	DIM scolorTable[upper]
	IF biClrUsed THEN upper = biClrUsed-1
	IF (upper > UBOUND (scolorTable[])) THEN upper = UBOUND (scolorTable[])
	'
	colorTableOffset = headerSize + 14
	FOR i = 0 TO upper
		color = ULONGAT(&image[colorTableOffset], [i])
		red   =  color AND 0xFF
		green = (color >> 8) AND 0xFF
		blue  = (color >> 16) AND 0xFF
		scolorTable[i] = tableB[blue] OR tableG[green] OR tableR[red]
	NEXT i
	'
	IF (biHeight < 0) THEN     ' bitimage height is negative for top down
		yStart = 0
		yEnd   = sheight - 1
		yStep  = 1
	ELSE
		yStart = sheight - 1
		yEnd   = 0
		yStep  = -1
	END IF
	'
	FOR y = yStart TO yEnd STEP yStep
		##WHOMASK = 0
		##LOCKOUT = 100102
		FOR x = 0 TO swidth - 1
			pixByte = image[data]
			INC data                             ' each byte has one pixel
			IF (y < dheight) THEN
				IF (x < dwidth) THEN
					scolor = scolorTable[pixByte]
					XPutPixel (ximage, x, y, scolor)
				END IF
			END IF
		NEXT x
		data = ((data - dataOffset) + 3 AND -4) + dataOffset
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
	XstGetSystemTime (@#dib8b)
END SUB
'
'
' *****  DIB4  *****
'
SUB DIB4
	XstGetSystemTime (@#dib4a)
	'
	' Assume 16 colors unless biClrUsed is less
	'
	upper = 15
	DIM scolorTable[upper]
	IF biClrUsed THEN upper = biClrUsed-1
	IF (upper > UBOUND (scolorTable[])) THEN upper = UBOUND (scolorTable[])
	'
	colorTableOffset = headerSize + 14
	FOR i = 0 TO upper
		color = ULONGAT(&image[colorTableOffset], [i])
		blue  =  color AND 0xFF
		green = (color >> 8) AND 0xFF
		red   = (color >> 16) AND 0xFF
		scolorTable[i] = tableB[blue] OR tableG[green] OR tableR[red]
	NEXT i
	'
	IF (biHeight < 0) THEN     ' bitimage height is negative for top down
		yStart = 0
		yEnd   = sheight - 1
		yStep  = 1
	ELSE
		yStart = sheight - 1
		yEnd   = 0
		yStep  = -1
	END IF
	'
	FOR y = yStart TO yEnd STEP yStep
		##WHOMASK = 0
		##LOCKOUT = 100103
		FOR x = 0 TO swidth - 1
			pixByte = image[data]
			INC data                                  ' each byte has two pixels
			IF (y < dheight) THEN
				'
				' first of two pixels per byte
				'
				IF (x < dwidth) THEN
					scolor = scolorTable[(pixByte >> 4) AND 0xF]
					XPutPixel (ximage, x, y, scolor)
				END IF
				'
				' second of two pixels per byte
				'
				INC x
				IF (x < dwidth) THEN
					scolor = scolorTable[pixByte AND 0xF]
					XPutPixel (ximage, x, y, scolor)
				END IF
			ELSE
				INC x   'skip second pixel for y greater then dheight
			END IF
		NEXT x
		data = ((data - dataOffset) + 3 AND -4) + dataOffset
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
	XstGetSystemTime (@#dib4b)
END SUB
'
'
' *****  DIB2  *****
'
SUB DIB2
	XstGetSystemTime (@#dib2a)
	'
	' Assume 4 colors unless biClrUsed is less
	'
	upper = 3
	DIM scolorTable[upper]
	IF biClrUsed THEN upper = biClrUsed-1
	IF (upper > UBOUND (scolorTable[])) THEN upper = UBOUND (scolorTable[])
	'
	colorTableOffset = headerSize + 14
	FOR i = 0 TO upper
		color = ULONGAT(&image[colorTableOffset], [i])
		blue  =  color AND 0xFF
		green = (color >> 8) AND 0xFF
		red   = (color >> 16) AND 0xFF
		scolorTable[i] = tableB[blue] OR tableG[green] OR tableR[red]
	NEXT i
	'
	IF (biHeight < 0) THEN     ' bitimage height is negative for top down
		yStart = 0
		yEnd   = sheight - 1
		yStep  = 1
	ELSE
		yStart = sheight - 1
		yEnd   = 0
		yStep  = -1
	END IF
	'
	FOR y = yStart TO yEnd STEP yStep
		##WHOMASK = 0
		##LOCKOUT = 100104
		FOR x = 0 TO swidth - 1
			pixByte = image[data]
			INC data                                  ' each byte has 4 pixels
			IF (y < dheight) THEN
				FOR bitnumber = 6 TO 0 STEP -2
					IF (x < dwidth) THEN
						scolor = scolorTable[(pixByte >> bitnumber) AND 3]
						XPutPixel (ximage, x, y, scolor)
					END IF
					INC x
				NEXT bitnumber
				DEC x
			END IF
		NEXT x
		data = ((data - dataOffset) + 3 AND -4) + dataOffset
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
	XstGetSystemTime (@#dib2b)
END SUB
'
'
' *****  DIB1  *****
'
SUB DIB1
	XstGetSystemTime (@#dib1a)
	'
	'  ?????????????????????? what if number of colors ???
	'
	colorTableOffset = headerSize + 14
	DIM scolorTable[1]
	FOR i = 0 TO 1
		color = ULONGAT(&image[colorTableOffset], [i])
		blue  =  color AND 0xFF
		green = (color >> 8) AND 0xFF
		red   = (color >> 16) AND 0xFF
		scolorTable[i] = tableB[blue] OR tableG[green] OR tableR[red]
	NEXT i
	'
	IF (biHeight < 0) THEN     ' bitimage height is negative for top down
		yStart = 0
		yEnd   = sheight - 1
		yStep  = 1
	ELSE
		yStart = sheight - 1
		yEnd   = 0
		yStep  = -1
	END IF
	'
	FOR y = yStart TO yEnd STEP yStep
		##WHOMASK = 0
		##LOCKOUT = 100105
		FOR x = 0 TO swidth - 1
			pixByte = image[data]
			INC data                                  ' each byte has 8 pixels
			IF (y < dheight) THEN
				FOR bitnumber = 7 TO 0 STEP -1
					IF (x < dwidth) THEN
						scolor = scolorTable[(pixByte >> bitnumber) AND 1]
						XPutPixel (ximage, x, y, scolor)
					END IF
					INC x
				NEXT bitnumber
				DEC x
			END IF
		NEXT x
		data = ((data - dataOffset) + 3 AND -4) + dataOffset
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
	XstGetSystemTime (@#dib1b)
END SUB
'
'
' Initialize red, green and blue lookup tables
'
SUB InitRGBTables
	##WHOMASK = O
	'
	DIM tableR[255]
	DIM tableG[255]
	DIM tableB[255]
	'
	FOR i = 0 TO 255
		'
		sc.r = i << 8
		sc.g = 0
		sc.b = 0
		sc.scolor = 0
		okay = XAllocColor (sdisplay, colormap, &sc)
		tableR[i] = sc.scolor
		'
		sc.r = 0
		sc.g = i << 8
		sc.b = 0
		sc.scolor = 0
		okay = XAllocColor (sdisplay, colormap, &sc)
		tableG[i] = sc.scolor
		'
		sc.r = 0
		sc.g = 0
		sc.b = i << 8
		sc.scolor = 0
		okay = XAllocColor (sdisplay, colormap, &sc)
		tableB[i] = sc.scolor
		'
	NEXT i
	##WHOMASK = whomask
END SUB
'
END FUNCTION
'
'
' ###############################
' #####  XgrSetImagePNM ()  #####
' ###############################
'
' error = XgrSetImagePNM (grid, @image[])
'
' pnm - portable anymap file format
' pbm - portable bitmap file format  P1,P4
' pgm - portable graymap file format P2,P5
' ppm - portable pixmap file format  P3,P6
'
' See: XgrSetImage(),
'
FUNCTION  XgrSetImagePNM (grid, UBYTE image[])
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
	SHARED  flushTime
	SHARED  tableR[], tableG[], tableB[]
	XColor  sc
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetImagePNM()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetImagePNM() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	size = SIZE (image[])
'
	IF (size < 64) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XgrSetImagePNM() : input argument image[] too small"
		RETURN ($$TRUE)
	END IF
'
	display = window[grid].display
	simage = window[grid].swindow       ' system pixmap #
	IFZ simage THEN RETURN ($$FALSE)		' no destination image
'
	GOSUB GetParameter : signature$ = parameter$
	GOSUB GetParameter : width$     = parameter$
	GOSUB GetParameter : height$    = parameter$
	'
	SELECT CASE signature$
		CASE "P6" : GOSUB GetParameter : maxColor$  = parameter$
		CASE "P3" : GOSUB GetParameter : maxColor$  = parameter$
		CASE "P5" : GOSUB GetParameter : maxColor$  = parameter$
		CASE "P2" : GOSUB GetParameter : maxColor$  = parameter$
		CASE "P4" : maxColor$ = "1"
		CASE "P1" : maxColor$ = "1"
		CASE ELSE
			error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
			old = ERROR (error)
			RETURN ($$TRUE)
	END SELECT
	'
	swidth   = ABS (XLONG (width$))
	sheight  = ABS (XLONG (height$))
	maxColor = ABS (XLONG (maxColor$))
	IF (maxColor >= 256) THEN color2bytes = $$TRUE
	'
	dwidth = window[grid].width           ' pixmap width
	dheight = window[grid].height         ' pixmap height

	gc = window[grid].gc                  ' system gc
	swindow = window[grid].swindow        ' system window # of pixmap
	sdisplay = window[grid].sdisplay      ' system display #
	colormap = display[display].colormap	' system colormap #

	IFZ tableR[] THEN GOSUB InitRGBTables
'
' If not an image type of grid and it is in the process of being
' displayed or resized, wait for that to be completed first.
'
	IFZ WinGridDrawable (grid) THEN RETURN ($$FALSE)
'
' get XImage - XWindows memory "image" for the existing pixmap
'
	##WHOMASK = 0
	##LOCKOUT = 100106
	ximage = XGetImage (sdisplay, simage, 0, 0, dwidth, dheight, $$AllPlanes, $$ZPixmap)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	flushTime = eventTime
	XstGetSystemTime (@XSyncNowTime)

	IFZ ximage THEN
		##ERROR = ($$ErrorObjectImage << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrSetImagePNM() : failed to get ximage"
		RETURN ($$TRUE)
	END IF
'
' transfer the image to the pixmap
'
'	saddr = &image[] + index
'
	SELECT CASE signature$
		CASE "P6" : GOSUB P6
		CASE "P3" : GOSUB P3
		CASE "P5" : GOSUB P5
		CASE "P2" : GOSUB P2
		CASE "P4" : GOSUB P4
		CASE "P1" : GOSUB P1
	END SELECT
'
' put image into pixmap = image grid
'
	##WHOMASK = 0
	##LOCKOUT = 100107
	XPutImage (sdisplay, simage, gc, ximage, 0, 0, 0, 0, dwidth, dheight)
	XDestroyImage (ximage)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	RETURN
'------------------------------------------------------------------
'
' *****  GetParameter  *****
'
SUB GetParameter
	IF (index < 0) THEN index = 0
	comment = $$FALSE
	parameter$ = ""
	DO WHILE (index < size)
		char = image[index]
		INC index
		SELECT CASE char
			CASE 0x0A : IFZ parameter$ THEN DO DO              ' new-line
									IFZ comment THEN EXIT SUB
									comment = $$FALSE
									parameter$ = ""
									DO LOOP
			CASE 0x20 : IFZ parameter$ THEN DO DO              ' space character
			            IFZ comment THEN EXIT SUB
			            '
			CASE 0x23 : IFZ parameter$ THEN comment = $$TRUE   ' "#"
			            '
			CASE 0x09 : IFZ parameter$ THEN DO DO              ' tab character
			            IFZ comment THEN EXIT SUB
			            '
			CASE 0x0B : IFZ parameter$ THEN DO DO              ' vertical-tab character
			            IFZ comment THEN EXIT SUB
			            '
			CASE 0x0C : IFZ parameter$ THEN DO DO              ' form-feed character
			            IFZ comment THEN EXIT SUB
			            '
			CASE 0x0D : IFZ parameter$ THEN DO DO              ' carriage-return character
			            IFZ comment THEN EXIT SUB
		END SELECT
		'
		IF ((char >= 0x20) && (char < 0x7F)) THEN
			parameter$ = parameter$ + CHR$(char)
		ELSE
			EXIT DO
		END IF
	LOOP
	IF (index >= size) THEN
		PRINT "XgrSetImagePNM(): Reached end-of-data", index, size
	ELSE
		PRINT "XgrSetImagePNM(179): Invalid character in header", HEXX$(char), index-1
	END IF
	EXIT FUNCTION (-1)
END SUB
'
'
' *****  P6  *****
'
SUB P6
	'
	sizeNeeded = swidth * sheight * 3
	IF color2bytes THEN sizeNeeded = sizeNeeded * 2
	sizeNeeded = sizeNeeded + index
	IF (sizeNeeded > size) THEN
		PRINT "XgrSetImagePNM()-P6 : image[] supplied is too small", size, sizeNeeded
		EXIT FUNCTION (-1)
	END IF
	'
	FOR y = 0 TO sheight - 1
		IF (y >= dheight) THEN EXIT FOR
		##WHOMASK = 0
		##LOCKOUT = 100108
		FOR x = 0 TO swidth - 1
			IF (x < dwidth) THEN
				red   = image[index] : INC index : IF color2bytes THEN INC index
				green = image[index] : INC index : IF color2bytes THEN INC index
				blue  = image[index] : INC index : IF color2bytes THEN INC index
				scolor = tableB[blue] OR tableG[green] OR tableR[red]
				XPutPixel (ximage, x, y, scolor)
			ELSE
				IF color2bytes THEN index = index + 6 ELSE index = index + 3
			END IF
		NEXT x
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
END SUB
'
'
' *****  P3  *****
'
SUB P3
	'
	FOR y = 0 TO sheight - 1
		IF (y >= dheight) THEN EXIT FOR
		'
		FOR x = 0 TO swidth - 1
			IF color2bytes THEN
				GOSUB GetParameter : red   = (XLONG(parameter$) >> 8) AND 0xFF
				GOSUB GetParameter : green = (XLONG(parameter$) >> 8) AND 0xFF
				GOSUB GetParameter : blue  = (XLONG(parameter$) >> 8) AND 0xFF
			ELSE
				GOSUB GetParameter : red   = XLONG(parameter$) AND 0xFF
				GOSUB GetParameter : green = XLONG(parameter$) AND 0xFF
				GOSUB GetParameter : blue  = XLONG(parameter$) AND 0xFF
			END IF
			IF (x < dwidth) THEN
				##WHOMASK = 0
				##LOCKOUT = 100109
				scolor = tableB[blue] OR tableG[green] OR tableR[red]
				XPutPixel (ximage, x, y, scolor)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
		NEXT x
		'
	NEXT y
END SUB
'
'
' *****  P5  ***** gray colors
'
SUB P5
'
	sizeNeeded = swidth * sheight
	IF color2bytes THEN sizeNeeded = sizeNeeded * 2
	sizeNeeded = sizeNeeded + index
	IF (sizeNeeded > size) THEN
		PRINT "XgrSetImagePNM()-P5 : image[] supplied is too small", size, sizeNeeded
		EXIT FUNCTION (-1)
	END IF
	'
	FOR y = 0 TO sheight - 1
		IF (y >= dheight) THEN EXIT FOR
		##WHOMASK = 0
		##LOCKOUT = 100110
		'
		FOR x = 0 TO swidth - 1
			IF (x < dwidth) THEN
				gray   = image[index] : INC index : IF color2bytes THEN INC index
				scolor = tableB[gray] OR tableG[gray] OR tableR[gray]
				XPutPixel (ximage, x, y, scolor)
			ELSE
				IF color2bytes THEN index = index + 2 ELSE INC index
			END IF
		NEXT x
		'
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
END SUB
'
'
' *****  P2  ***** gray colors
'
SUB P2
'
	FOR y = 0 TO sheight - 1
		IF (y >= dheight) THEN EXIT FOR
		'
		FOR x = 0 TO swidth - 1
			IF color2bytes THEN
				GOSUB GetParameter : gray = (XLONG(parameter$) >> 8) AND 0xFF
			ELSE
				GOSUB GetParameter : gray = XLONG(parameter$) AND 0xFF
			END IF
			IF (x < dwidth) THEN
				##WHOMASK = 0
				##LOCKOUT = 100111
				scolor = tableB[gray] OR tableG[gray] OR tableR[gray]
				XPutPixel (ximage, x, y, scolor)
				##LOCKOUT = lockout
				##WHOMASK = whomask
			END IF
		NEXT x
		'
	NEXT y
END SUB
'
'
' *****  P4  ***** black and white
'
SUB P4
'
	sizeNeeded = (swidth * sheight) / 8
	sizeNeeded = sizeNeeded + index
	IF (sizeNeeded > size) THEN
		PRINT "XgrSetImagePNM()-P4 : image[] supplied is too small", size, sizeNeeded
		EXIT FUNCTION (-1)
	END IF
	'
	' ximage is initialized to zero's and is therefore all black,
	' so all we need to do is write the white pixels.
	'
	ConvertColorToSystemColor (grid, $$White, @scolor)
	'
	FOR y = 0 TO sheight - 1
		IF (y >= dheight) THEN EXIT FOR
		##WHOMASK = 0
		##LOCKOUT = 100112
		'
		x = 0
		DO
			byte = image[index] XOR 0xFF    ' invert data so white is TRUE
			IF byte THEN                    ' check if some white pixels
				SELECT CASE ALL TRUE
					CASE byte AND 0x80 : XPutPixel (ximage, x, y, scolor)
					CASE byte AND 0x40 : XPutPixel (ximage, x+1, y, scolor)
					CASE byte AND 0x20 : XPutPixel (ximage, x+2, y, scolor)
					CASE byte AND 0x10 : XPutPixel (ximage, x+3, y, scolor)
					CASE byte AND 0x08 : XPutPixel (ximage, x+4, y, scolor)
					CASE byte AND 0x04 : XPutPixel (ximage, x+5, y, scolor)
					CASE byte AND 0x02 : XPutPixel (ximage, x+6, y, scolor)
					CASE byte AND 0x01 : XPutPixel (ximage, x+7, y, scolor)
				END SELECT
			END IF
			x = x + 8
			INC index
		LOOP WHILE (x < swidth)
		'
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
'
END SUB
'
'
' *****  P1  ***** black and white ASCII
'
SUB P1
'
	sizeNeeded = (swidth * sheight)
	sizeNeeded = sizeNeeded + index
	IF (sizeNeeded > size) THEN
		PRINT "XgrSetImagePNM()-P1 : image[] supplied is too small", size, sizeNeeded
		EXIT FUNCTION (-1)
	END IF
	'
	FOR y = 0 TO sheight - 1
		IF (y >= dheight) THEN EXIT FOR
		##WHOMASK = 0
		##LOCKOUT = 100113
		'
		FOR x = 0 TO swidth - 1
			char = image[index]
			INC index
			IF (index > size) THEN EXIT SUB
			SELECT CASE char
				CASE '0' : scolor = $$White
				CASE '1' : scolor = $$Black
				CASE ELSE : DO FOR
			END SELECT
			IF (x < dwidth) THEN
				XPutPixel (ximage, x, y, scolor)
			END IF
		NEXT x
		'
		##LOCKOUT = lockout
		##WHOMASK = whomask
	NEXT y
END SUB
'
'
' Initialize red, green and blue lookup tables
'
SUB InitRGBTables
	##WHOMASK = O
	'
	DIM tableR[255]
	DIM tableG[255]
	DIM tableB[255]
	'
	FOR i = 0 TO 255
		'
		sc.r = i << 8
		sc.g = 0
		sc.b = 0
		sc.scolor = 0
		okay = XAllocColor (sdisplay, colormap, &sc)
		tableR[i] = sc.scolor
		'
		sc.r = 0
		sc.g = i << 8
		sc.b = 0
		sc.scolor = 0
		okay = XAllocColor (sdisplay, colormap, &sc)
		tableG[i] = sc.scolor
		'
		sc.r = 0
		sc.g = 0
		sc.b = i << 8
		sc.scolor = 0
		okay = XAllocColor (sdisplay, colormap, &sc)
		tableB[i] = sc.scolor
		'
	NEXT i
	##WHOMASK = whomask
END SUB
'
END FUNCTION
'
'
' ################################
' #####  XgrGetMouseInfo ()  #####
' ################################
'
' XgrGetMouseInfo (@window, @grid, @x, @y, @state, @time)
'
FUNCTION  XgrGetMouseInfo (window, grid, x, y, state, time)
	SHARED  DISPLAY  display[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetMouseInfo()lockout", lockout) : lockout = 0
'
	grid = display[1].mouseGrid
	window = display[1].mouseWindow
	x = display[1].mouseX
	y = display[1].mouseY
	state = display[1].mouseState
	time = display[1].mouseTime + 1
'	PRINT "XgrGetMouseInfo(22)", HEXX$(x) , HEXX$(y)
END FUNCTION
'
'
' #####################################
' #####  XgrGetSelectedWindow ()  #####
' #####################################
'
' XgrGetSelectedWindow (@window)
'
FUNCTION  XgrGetSelectedWindow (window)
	SHARED  DISPLAY  display[]
'
	window = display[1].selectedWindow
END FUNCTION
'
'
' ########################################
' #####  XgrGetTextSelectionGrid ()  #####
' ########################################
'
FUNCTION  XgrGetTextSelectionGrid (@grid)
	SHARED  textSelectionGrid
'
	grid = textSelectionGrid
END FUNCTION
'
'
' #####################################
' #####  XgrSetSelectedWindow ()  #####
' #####################################
'
FUNCTION  XgrSetSelectedWindow (window)
	SHARED  WINDOW  window[]
	SHARED  focusWhenMapped
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrSetSelectedWindow()lockout", lockout) : lockout = 0
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XgrDisplayWindow() : error : invalid window #"; window
		RETURN (-1)
	END IF
'
	windowType = window[window].type
	noSelect = windowType AND $$WindowTypeNoSelect
	IF noSelect THEN
		IF ##XBDV THEN PRINT "XgrSetSelectedWindow(23)$$WindowTypeNoSelect", window
		RETURN (-1)
	END IF
'	PRINT "XgrSetSelectedWindow()", window, noSelect
'
' XSetInputFocus() only works when the window is visible (mapped).
'
	IF window[window].mapped THEN
		swindow = window[window].swindow
		sdisplay = window[window].sdisplay
		##WHOMASK = 0
		##LOCKOUT = 100114
		XSetInputFocus (sdisplay, swindow, $$RevertToParent, 0)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	ELSE
		focusWhenMapped = window
	END IF
'
	RETURN (return)

END FUNCTION
'
'
' ########################################
' #####  XgrSetTextSelectionGrid ()  #####
' ########################################
'
FUNCTION  XgrSetTextSelectionGrid (grid)
	SHARED  textSelectionGrid
	SHARED  WINDOW  window[]
'
	IF (grid == textSelectionGrid) THEN RETURN ($$FALSE)
'
	IF grid THEN
		IF InvalidGrid (grid) THEN
			IF ##XBDV THEN PRINT "XgrSetTextSelectionGrid() : invalid grid #"; grid
			RETURN ($$TRUE)
		END IF
	END IF
'
	IF grid THEN
		IF (grid != textSelectionGrid) THEN
			IF textSelectionGrid THEN
				IF window[grid].window THEN
					IFZ window[grid].destroy THEN
						IFZ window[grid].destroyed THEN
							IFZ window[grid].destroyProcessed THEN
								XgrAddMessage (textSelectionGrid, #LostTextSelection, 0, 0, 0, 0, 0, textSelectionGrid)
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	END IF
	textSelectionGrid = grid
END FUNCTION
'
'
' ##########################################
' #####  XgrUnsetTextSelectionGrid ()  #####
' ##########################################
'
FUNCTION  XgrUnsetTextSelectionGrid (grid)
	SHARED  textSelectionGrid
'
	IF grid THEN
		IF (grid == textSelectionGrid) THEN
			textSelectionGrid = 0
		END IF
	END IF
'
END FUNCTION
'
'
' ##############################
' #####  XgrAddMessage ()  #####
' ##############################
'
' error = XgrAddMessage (winGrid, #message, v0, v1, v2, v3, r0, r1)
'
' winGrid is the destination window or grid number
'
FUNCTION  XgrAddMessage (winGrid, message, v0, v1, v2, v3, r0, r1)
	SHARED  MESSAGE  message[]
	SHARED  MESSAGE  mess[]
	SHARED	WINDOW  window[]
	SHARED	userCount
	SHARED	sysCount
	SHARED  userOut
	SHARED	sysOut
	SHARED	userIn
	SHARED  sysIn
	SHARED  inQueue
	SHARED  uuuuu
	SHARED  inHold
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrAddMessage()lockout", lockout) : lockout = 0
'
	XgrGetMessageType (message, @messageType)
	SELECT CASE messageType
		CASE $$Window :
										IF InvalidWindow (winGrid) THEN RETURN $$TRUE
										IFZ window[winGrid].winFunc THEN RETURN $$FALSE
		CASE $$Grid :
										IF InvalidGrid (winGrid) THEN RETURN $$TRUE
										IFZ window[winGrid].gridFunc THEN RETURN $$FALSE
		CASE ELSE     : RETURN $$TRUE
	END SELECT
'
'
' If XgrAddMessage() previously received one or more message that it
' counldn't add to the message queue because a previous instance of a
' message queue manipulating function is in the process of updating
' the message queue variables, it added the message to the holding
' queue instead.  Move these messages in the holding queue to the
' message queue after adding this message to the message queue.
'
' If XgrAddMessage() is called while message queue variables are being
' updated (inQueue != 0), add message to synchronizing message queue.
'
	IF inQueue THEN XxxLog (@"XgrAddMessage() : inQueue")  '*cw* 110427 testing
	IF inQueue THEN
		GOSUB AddToHoldingQueue
		IF added THEN
			RETURN ($$FALSE)
		ELSE
			RETURN $$TRUE
		END IF
	END IF
	inQueue = $$TRUE
'
' programmer can add any message to queue - XgrProcessMessages() checks
'
' get "count,out,in" variables for winGrid owner - either user or system
'
	who = window[winGrid].whomask
	IF who THEN queue = 1 ELSE queue = 0
'
	upper = UBOUND (message[queue,])
'
' get local variables from appropriate queue variables
'
'
	IF queue THEN
		count = userCount
		out = userOut
		in = userIn
	ELSE
		count = sysCount
		out = sysOut
		in = sysIn
	END IF
'
' see if queue is full
'
	IF (count >= upper) THEN
		##ERROR = ($$ErrorObjectQueue << 8) AND $$ErrorNatureFull
		IF ##XBDV THEN
			PRINT "XgrAddMessage() : message queue full : message lost : ";
			IF queue THEN PRINT "user queue "; ELSE PRINT "system queue ";
			XgrMessageNumberToName (message, @message$)
			PRINT message, message$
		END IF
		inQueue = $$FALSE
		RETURN ($$TRUE)
	END IF
'
' put message in queue
'
	message[queue,in].wingrid = winGrid
	message[queue,in].message = message
	message[queue,in].v0 = v0
	message[queue,in].v1 = v1
	message[queue,in].v2 = v2
	message[queue,in].v3 = v3
	message[queue,in].r0 = r0
	message[queue,in].r1 = r1
'
' update appropriate queue variables
'
	window[winGrid].lastIn = in
	IF queue THEN
		INC userCount
		INC userIn
		IF (userIn > upper) THEN userIn = 0
		IF (userCount > upper) THEN PRINT "XgrAddMessage() : (userCount > upper)"
	ELSE
		INC sysCount
		INC sysIn
		IF (sysIn > upper) THEN sysIn = 0
		IF (sysCount > upper) THEN PRINT "XgrAddMessage() : (sysCount > upper)"
	END IF
'
	inQueue = $$FALSE
	IF inHold THEN GOSUB EmptyHoldingQueue
	RETURN ($$FALSE)
'
'
' *****  EmptyHoldingQueue  *****
'
SUB EmptyHoldingQueue
'	write (1, &"(empty", 6)
	GOSUB GetUnique											' unique = a unique value
	IF inHold THEN											' something in holding queue
		IFZ inQueue THEN									' not updating queue variables
			FOR m = 0 TO UBOUND (mess[])		' check all messages
				mess = mess[m].message				' check message
				IF (mess > 0) THEN						' not being processed
					mess[m].message = -unique		' mark as being processed
					check = mess[m].message			' sync check - still in sync?
					IF (check = -unique) THEN		' sync okay - add to queue
						DEC inHold								' one less in holding queue
						wg = mess[m].wingrid
						mm = mess
						a0 = mess[m].v0
						a1 = mess[m].v1
						a2 = mess[m].v2
						a3 = mess[m].v3
						a4 = mess[m].r0
						a5 = mess[m].r1
						mess[m].message = 0				' now available
						XgrAddMessage (wg, mm, a0, a1, a2, a3, a4, a5)
					END IF
				END IF
			NEXT m
		END IF
	END IF
'	write (1, &")", 1)
'	PRINT "XgrAddMessage(): EmptyHoldingQueue
END SUB
'
'
' *****  AddToHoldingQueue  *****
'
SUB AddToHoldingQueue
'
'	write (1, &"{add", 4)
	GOSUB GetUnique											' unique = a unique value
	added = $$FALSE											' message not yet added
	FOR m = 0 TO UBOUND (mess[])
		mess = mess[m].message						' slot available
		IFZ mess THEN
			mess[m].message = -unique				' reserve with -unique value
			check = mess[m].message					' sync check - still -unique?
			IF (check = -unique) THEN				' sync okay - add to mess
				mess[m].r1 = r1
				mess[m].r0 = r0
				mess[m].v3 = v3
				mess[m].v2 = v2
				mess[m].v1 = v1
				mess[m].v0 = v0
				mess[m].wingrid = winGrid
				mess[m].message = message			' valid message
				INC inHold										' now available
				INC added											' message added
				EXIT FOR
			END IF
		END IF
	NEXT m
END SUB
'
'
' *****  GetUnique  *****
'
SUB GetUnique
	DO
		u = uuuuu
		INC uuuuu
		unique = uuuuu - 1
	LOOP UNTIL (u = unique)										' unique is a unique value
	IF (uuuuu >= 0x7FFFFF00) THEN uuuuu = 1		' recycle unique counter
END SUB
END FUNCTION
'
'
' ##################################
' #####  XgrDeleteMessages ()  #####
' ##################################
'
FUNCTION  XgrDeleteMessages (count)
	SHARED  MESSAGE  message[]
	SHARED  userCount
	SHARED  sysCount
	SHARED  userOut
	SHARED  sysOut
	SHARED  inHold
	SHARED  inQueue
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrDeleteMessages()lockout", lockout) : lockout = 0
'
	queue = 0																				' 0 = sys
	IF whomask THEN queue = 1												' 1 = user
	IFZ count THEN RETURN ($$FALSE)									' remove none
	IF (count < -1) THEN RETURN ($$TRUE)						' bad argument
	IFZ message[] THEN RETURN ($$FALSE)							' no queues at all
	IFZ message[queue,] THEN RETURN ($$FALSE)				' no queue yet
'
	upper = UBOUND (message[queue,])
'
	IF inQueue THEN PRINT "XgrDeleteMessages() : inQueue"
	inQueue = $$TRUE
'
	DO WHILE count
		IFZ queue THEN
			IFZ sysCount THEN EXIT DO										' queue empty
			DEC sysCount
			INC sysOut
			IF (sysOut > upper) THEN sysOut = 0					' wrap around
		ELSE
			IFZ userCount THEN EXIT DO									' queue empty
			DEC userCount
			INC userOut
			IF (userOut > upper) THEN userOut = 0				' wrap around
		END IF
		DEC count
	LOOP
'
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
'
END FUNCTION
'
'
' ##########################
' #####  XgrGetCEO ()  #####
' ##########################
'
FUNCTION  XgrGetCEO (func)
	SHARED	userCEO
	SHARED	sysCEO
'
	IF ##WHOMASK THEN func = userCEO ELSE func = sysCEO
END FUNCTION
'
'
' ###############################
' #####  XgrGetMessages ()  #####
' ###############################
'
FUNCTION  XgrGetMessages (@count, MESSAGE m[])
	SHARED  MESSAGE  message[]
	SHARED  userCount
	SHARED  sysCount
	SHARED  userOut
	SHARED  sysOut
	SHARED  inHold
	SHARED  inQueue
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetMessages()lockout", lockout) : lockout = 0
'
	IF inQueue THEN PRINT "XgrGetMessages() : inQueue"
	inQueue = $$TRUE
'
	DIM m[]
'
	IF whomask THEN																' user count, out, queue
		count = userCount
		out = userOut
		queue = 1
	ELSE																					' system count, out, queue
		queue = 0
		out = sysOut
		count = sysCount
	END IF
'
	IF (count <= 0) THEN													' no messages
		inQueue = $$FALSE
		IF inHold THEN EmptyHoldingQueue ()
		RETURN ($$FALSE)
	END IF
'
	upper = UBOUND (message[queue,])							' message queue
	top = count - 1																' upper bound
	DIM m[top]																		' return array
'
	FOR i = 0 TO top
		m[i] = message[queue,out]
		IF (out = upper) THEN out = 0 ELSE INC out
	NEXT i
'
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
'
END FUNCTION
'
'
' ##################################
' #####  XgrGetMessageType ()  #####
' ##################################
'
' XgrGetMessageType (message, @messageType)
'
' # = messageType
' 0 = not defined
' 1 = $$Window
' 2 = $$Grid
'
FUNCTION  XgrGetMessageType (message, @messageType)
	SHARED  SBYTE messageType[]
'
	IF (message <= 0) THEN
		##ERROR = ($$ErrorObjectMessage << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "XgrGetMessageType() : invalid message # : (message <= 0) : "; message
		messageType = 0
		RETURN ($$TRUE)
	END IF
'
	IF (message > UBOUND(messageType[])) THEN
		##ERROR = ($$ErrorObjectMessage << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "XgrGetMessageType() : invalid message # : (message # too large) : "; message; upper
		messageType = 0
		RETURN ($$TRUE)
	END IF
'
	messageType = messageType[message]
'
END FUNCTION
'
'
' ###############################
' #####  XgrGetMonitors ()  #####
' ###############################
'
FUNCTION  XgrGetMonitors (grid, MESSAGE r1[])
	SHARED  MESSAGE  monitor[]
'
	DIM r1[]
	IF (grid < 0) THEN grid = 0
	IFZ monitor[] THEN RETURN ($$FALSE)
'
	IF grid THEN
		IF InvalidGrid (grid) THEN
			IF ##XBDV THEN PRINT "XgrGetMonitor() : invalid grid #"; grid
			RETURN ($$TRUE)
		END IF
	END IF
'
	upper = UBOUND (monitor[])
	DIM r1[upper]
	slot = -1
'
	FOR i = 0 TO upper
		IF monitor[i].wingrid THEN
			IF monitor[i].message THEN
				IF ((grid = 0) OR (grid = monitor[i].wingrid)) THEN
					INC slot
					r1[slot] = monitor[i]
				END IF
			END IF
		END IF
	NEXT i
'
	IF (slot < 0) THEN DIM r1[] ELSE REDIM r1[slot]
END FUNCTION
'
'
' ##############################
' #####  XgrJamMessage ()  #####
' ##############################
'
' XgrJamMessage (winGrid, message, v0, v1, v2, v3, r0, r1)
'
' Adds a message at the front of the queue, which makes it the next
' message accessed by XgrPeekMessages(), XgrProcessMessages, etc.
'
FUNCTION  XgrJamMessage (winGrid, message, v0, v1, v2, v3, r0, r1)
	SHARED  MESSAGE  message[]
	SHARED	WINDOW  window[]
	SHARED	userCount
	SHARED	sysCount
	SHARED  userOut
	SHARED	sysOut
	SHARED	userIn
	SHARED  sysIn
	SHARED  inHold
	SHARED  inQueue
	SHARED  uuuuu
	SHARED  MESSAGE  mess[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrJamMessage()lockout", lockout) : lockout = 0
'
	XgrGetMessageType (message, @messageType)
	SELECT CASE messageType
		CASE $$Window :
										IF InvalidWindow (winGrid) THEN RETURN $$TRUE
										IFZ window[winGrid].winFunc THEN RETURN $$FALSE
		CASE $$Grid :
										IF InvalidGrid (winGrid) THEN RETURN $$TRUE
										IFZ window[winGrid].gridFunc THEN RETURN $$FALSE
		CASE ELSE     : RETURN $$TRUE
	END SELECT

'
' get "count,out,in" variables for winGrid owner - either user or system
'
	who = window[winGrid].whomask
	IF who THEN queue = 1 ELSE queue = 0
'
	upper = UBOUND (message[queue,])
'
'
' get local variables from appropriate queue variables
'
'	IF inQueue THEN XxxLog (@"XgrJamMessage() : inQueue")
'	write (1, &"}", 1)
	IF inQueue THEN
		GOSUB AddToHoldingQueue
		IF added THEN
			RETURN ($$FALSE)
		ELSE
			RETURN $$TRUE
		END IF
	END IF
	inQueue = $$TRUE
'
	IF queue THEN
		count = userCount
		out = userOut
		in = userIn
	ELSE
		count = sysCount
		out = sysOut
		in = sysIn
	END IF
'
' see if queue is full
'
	IF (count >= upper) THEN
		##ERROR = ($$ErrorObjectQueue << 8) AND $$ErrorNatureFull
		IF ##XBDV THEN
			PRINT "XgrJamMessage() : message queue full : message lost :";
			IF queue THEN PRINT " user queue" ELSE PRINT " system queue"
		END IF
		inQueue = $$FALSE
		IF inHold THEN EmptyHoldingQueue ()
		RETURN ($$TRUE)
	END IF
'
' update appropriate queue variables
'
	IF queue THEN
		INC userCount
		DEC userOut
		IF (userOut < 0) THEN userOut = upper
		IF (userCount > upper) THEN PRINT "XgrJamMessage() : (userCount > upper)"
	ELSE
		INC sysCount
		DEC sysOut
		IF (sysOut < 0) THEN sysOut = upper
		IF (sysCount > upper) THEN PRINT "XgrJamMessage() : (sysCount > upper)"
	END IF
'
' update variables
'
	IF queue THEN
		count = userCount
		out = userOut
		in = userIn
	ELSE
		count = sysCount
		out = sysOut
		in = sysIn
	END IF
'
'
' jam message in queue (put in the output end)
'
	message[queue,out].wingrid = winGrid
	message[queue,out].message = message
	message[queue,out].v0 = v0
	message[queue,out].v1 = v1
	message[queue,out].v2 = v2
	message[queue,out].v3 = v3
	message[queue,out].r0 = r0
	message[queue,out].r1 = r1
'
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
	RETURN
'
'
'
' *****  AddToHoldingQueue  *****
'
SUB AddToHoldingQueue
'
'	write (1, &"{add", 4)
	GOSUB GetUnique												' unique = a unique value
	added = $$FALSE												' message not yet added
	FOR m = 0 TO UBOUND (mess[])
		mess = mess[m].message						' slot available
		IFZ mess THEN
			mess[m].message = -unique				' reserve with -unique value
			check = mess[m].message					' sync check - still -unique?
			IF (check = -unique) THEN				' sync okay - add to mess
				mess[m].r1 = r1
				mess[m].r0 = r0
				mess[m].v3 = v3
				mess[m].v2 = v2
				mess[m].v1 = v1
				mess[m].v0 = v0
				mess[m].wingrid = winGrid
				mess[m].message = message			' valid message
				INC inHold										' now available
				INC added											' message added
				EXIT FOR
			END IF
		END IF
	NEXT m
END SUB
'
'
' *****  GetUnique  *****
'
SUB GetUnique
	DO
		u = uuuuu
		INC uuuuu
		unique = uuuuu - 1
	LOOP UNTIL (u = unique)										' unique is a unique value
	IF (uuuuu >= 0x7FFFFF00) THEN uuuuu = 1		' recycle unique counter
END SUB
'
END FUNCTION
'
'
' ##############################
' #####  XgrMallocInfo ()  #####
' ##############################
'
'	XgrMallocInfo (@arena, @ordblks, @smblks, @hblks, @hblkhd, @usmblks, @fsmblks, @wordblks, @fordblks, @keepcost)
'
FUNCTION  XgrMallocInfo (arena, ordblks, smblks, hblks, hblkhd, usmblks, fsmblks, wordblks, fordblks, keepcost)
	MALLINFO  mallInfo
	STATIC    info, void

	info = 0
	void = 0

	info = mallinfo (&void)
	PRINT "XgrMallocInfo()", HEXX$(info)

	arena    = ULONGAT(info,[0])
	ordblks  = ULONGAT(info,[1])
	smblks   = ULONGAT(info,[2])
	hblks    = ULONGAT(info,[3])
	hblkhd   = ULONGAT(info,[4])
	usmblks  = ULONGAT(info,[5])
	fsmblks  = ULONGAT(info,[6])
	wordblks = ULONGAT(info,[7])
	fordblks = ULONGAT(info,[8])
	keepcost = ULONGAT(info,[9])

END FUNCTION
'
'
' #######################################
' #####  XgrMessageNameToNumber ()  #####
' #######################################
'
' XgrMessageNameToNumber (message$, @message)
'
' Input message name message$ is not altered
' Returns message = 0 if message$ is not valid
'
FUNCTION  XgrMessageNameToNumber (message$, message)
	SHARED  lastMessage
	SHARED  message$[]
'
	message = 0
	IFZ message$ THEN RETURN ($$FALSE)
	IFZ message$[] THEN RETURN ($$FALSE)
'
	IF (message$ = "LastMessage") THEN
		message = lastMessage
		RETURN ($$FALSE)
	END IF
'
	FOR i = 0 TO UBOUND (message$[])
		IF (message$ = message$[i]) THEN message = i : EXIT FOR
	NEXT i
END FUNCTION
'
'
' ################################
' #####  XgrMessageNames ()  #####
' ################################
'
FUNCTION  XgrMessageNames (count, mess$[])
	SHARED  message$[]
'
	count = 0
	IFZ message$[] THEN RETURN ($$FALSE)
	upper = UBOUND (message$[])
	count = upper + 1
	DIM mess$[upper]
'
	FOR i = 0 TO upper
		mess$[i] = message$[i]
	NEXT i
END FUNCTION
'
'
' #######################################
' #####  XgrMessageNumberToName ()  #####
' #######################################
'
' XgrMessageNumberToName (message, @message$)
'
FUNCTION  XgrMessageNumberToName (message, message$)
	SHARED  message$[]
'
	message$ = ""
	IFZ message THEN RETURN ($$FALSE)
	IFZ message$[] THEN RETURN ($$FALSE)
'
	IF (message < 0) THEN
		##ERROR = ($$ErrorObjectMessage << 8) OR $$ErrorNatureInvalidNumber
		IF ##XBDV THEN PRINT "XgrMessageNumberToName() : (message < 0)"
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (message$[])
	IF (message > upper) THEN RETURN ($$FALSE)
	message$ = message$[message]
END FUNCTION
'
'
' ###################################
' #####  XgrMessagesPending ()  #####
' ###################################
'
' XgrMessagesPending (@count)
'
' Returns a count of the number of messages in the message queue.
' The number is the user queue for a user program
' and the system queue for a system program.
'
FUNCTION  XgrMessagesPending (count)
	SHARED	userCount
	SHARED	sysCount
'
	IF ##WHOMASK THEN count = userCount ELSE count = sysCount
	IFZ count THEN
		DispatchEvents ($$TRUE, $$FALSE)
		IF ##WHOMASK THEN count = userCount ELSE count = sysCount
	END IF
END FUNCTION
'
'
' ###########################
' #####  XgrMonitor ()  #####
' ###########################
'
FUNCTION  XgrMonitor (grid, message, v0, v1, v2, v3, r0, r1)
	SHARED  MESSAGE  monitor[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrMonitor()lockout", lockout) : lockout = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrMonitor() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	SELECT CASE message
		CASE #MonitorContext		: error = $$FALSE
		CASE #MonitorHelp				: error = $$FALSE
		CASE #MonitorKeyboard		: error = $$FALSE
		CASE #MonitorMouse			: error = $$FALSE
		CASE ELSE								: error = $$TRUE
	END SELECT
'
	IF error THEN
		XgrMessageNumberToName (message, @message$)
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidMessage
		IF ##XBDV THEN PRINT "XgrMonitor() : invalid message argument : "; message$
		RETURN ($$TRUE)
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100115
	IFZ monitor[] THEN DIM monitor[15]		' first monitor request
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	return = $$FALSE											' no error
	upper = UBOUND (monitor[])						' last existing monitor slot
'
	SELECT CASE r1
		CASE $$FALSE	: GOSUB Remove
		CASE $$TRUE		: GOSUB Install
		CASE ELSE			: GOSUB Broken
	END SELECT
	RETURN (return)
'
' *****  Remove  *****
'
SUB Remove
	FOR i = 0 TO upper
		IF (grid = monitor[i].wingrid) THEN
			IF (message = monitor[i].message) THEN
				monitor[i].message = 0
				monitor[i].wingrid = 0
			END IF
		END IF
	NEXT i
END SUB
'
' *****  Install  *****
'
SUB Install
END SUB
'
' *****  Broken  *****
'
SUB Broken
	##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidCommand
	IF ##XBDV THEN PRINT "XgrMonitor() : invalid command in r1"
	return = $$TRUE
END SUB
END FUNCTION
'
'
' ###############################
' #####  XgrPeekMessage ()  #####
' ###############################
'
' XgrPeekMessage() returns the next message in the message queue in
' (wingrid,message,v0,v1,v2,v3) without removing it from the queue.
' If the message queue is empty, XgrPeekMessage() suspends the
' application until a message becomes available.
'
' If called by a user program, it waits for a message in the user queue.
'
FUNCTION  XgrPeekMessage (wingrid, message, v0, v1, v2, v3, r0, r1)
	SHARED  MESSAGE  message[]
	SHARED  userCount
	SHARED  sysCount
	SHARED  userOut
	SHARED  sysOut
	SHARED  userIn
	SHARED  sysIn
	SHARED  inHold
	SHARED  inQueue
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrPeekMessage()lockout", lockout) : lockout = 0
'
	wingrid = 0 : message = 0 : v0 = 0 : v1 = 0 : v2 = 0 : v3 = 0 : r0 = 0 : r1 = 0
'
	queue = 0
	IF whomask THEN queue = 1
'
	IFZ message[] THEN RETURN ($$TRUE)
	IFZ message[queue,] THEN RETURN ($$TRUE)
'
' wait for message in system or user queue to appear
'
	DO
		IF inQueue THEN PRINT "XgrPeekMessage().A : inQueue"
		inQueue = $$TRUE
		GOSUB UpdateVariables
		inQueue = $$FALSE
		IF inHold THEN EmptyHoldingQueue ()
		IF count THEN EXIT DO
		XxxXgrSysMessages ()
		DispatchEvents ($$TRUE, $$TRUE)
		IF (##SOFTBREAK && ##WHOMASK) THEN EXIT DO
	LOOP
'
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN ($$TRUE)
'
' get message arguments from queue
'
	inQueue = $$TRUE
	wingrid = message[queue,out].wingrid
	message = message[queue,out].message
	v0 = message[queue,out].v0
	v1 = message[queue,out].v1
	v2 = message[queue,out].v2
	v3 = message[queue,out].v3
	r0 = message[queue,out].r0
	r1 = message[queue,out].r1
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
'
	RETURN ($$FALSE)
'
'
' *****  UpdateVariables  *****
'
SUB UpdateVariables
	IF queue THEN
		count = userCount
		out = userOut
		in = userIn
	ELSE
		count = sysCount
		out = sysOut
		in = sysIn
	END IF
END SUB
END FUNCTION
'
'
' ###################################
' #####  XgrProcessMessages ()  #####
' ###################################
'
' XgrProcessMessages ($$ProcessAllOrNone)
'
'	$$ProcessOneOnly      =  1
'	$$ProcessOneOrNone    =  0
'	$$ProcessOneOrAll     = -1
'	$$ProcessAllOrNone    = -2
'
' An (argCount) of 1 or more will process exactly that
' number of messages and then immediately return. Also,
' it will not return until that number of messages are
' processed. If the number of messages in the message
' queue is less than argCount, this function blocks or
' sleeps until the requested number of messages are
' loaded in the queue and processed, and then returns.
'
' An argCount of -3 or less, it will process one
' message in the message queue and return, but if there
' are no message in the queue, it will sleep for up to
' absolute value in millicesonds or until a message is
' availble, process it, and then return.
'
' System messages are processed first.
' User messages are processed second.
' Mouse and keyboard messages are processed last.
'
' If a Modal window is active, all keyboard input
' is directed to the modal window and all mouse
' action outside the modal window is ignored.
'
FUNCTION  XgrProcessMessages (argCount)
	SHARED  DISPLAY  display[]
	SHARED	WINDOW  window[]
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
	SHARED  userCEO
	SHARED  sysCEO
	SHARED	userCount
	SHARED	sysCount
	SHARED  userOut
	SHARED	sysOut
	SHARED	userIn
	SHARED  sysIn
	SHARED  inHold
	SHARED  inQueue
	STATIC  motion
	SHARED	recurSys, recurUser
	MESSAGE m[]
	FUNCADDR  ceo (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
' If a modal window is set for the system/user who calls
' XgrProcessMessages(), all keyboard messages are sent to
' the modal window and all mouse messages outside the modal
' window are removed from the queue and discarded (ignored).
'
' XgrProcessMessages() has first chance to clear out the window
' or grid information in window[] after it processes a #Destroyed
' or #WindowDestroyed message.  This work can't be done in the
' EventDestroyNotify() function or before, because this function
' needs the grid function or window function address, and the
' function it calls might need other data.
'
' Are MonitorContext, MonitorHelp, MonitorKeyboard, MonitorMouse
' handled in this XgrProcessMessages() function, or in GuiDesigner ???
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrProcessMessages()lockout", lockout) : lockout = 0
	IF ##TIMERLOCKOUT THEN write (1, &"XgrProcessMessages()##TIMERLOCKOUT\n", 35)
'
	IF whomask THEN
		IF recurUser THEN
			IF (recurUser > 100)THEN
				raise ($$SIGSTKFLT)
				XxxLog2 (@"XgrProcessMessages():recurUser", recurUser)
			END IF
		END IF
		INC recurUser
	ELSE
		IF recurSys THEN
			recurMax = 100
			IF (recurSys > recurMax) THEN
				XxxLog2 (@"XgrProcessMessages():recurSys", recurSys)
			END IF
		END IF
		INC recurSys
	END IF
	##RECURUSER = recurUser
'
	IF whomask THEN GOSUB ProcessSystemMessages
'
' get "count,out,in" variables for window owner - either user or system
'
	queue = 0																				' system queue
	IF whomask THEN queue = 1												' user queue
'
' get local variables from appropriate queue variables
'
	GOSUB UpdateVariables
'
' if zero messages requested, return if there are none
'
	IFZ argCount THEN
		IFZ count THEN
			DispatchEvents ($$TRUE, $$FALSE)	' xlib events to sys/user queues
			GOSUB UpdateVariables
			IFZ count THEN
				UpdateMouse (whomask)				' generate #MouseMove if mouse moved
				GOSUB UpdateVariables
				IFZ count THEN
					GOTO leave
				END IF
			END IF
		END IF
		argCount = 1										' process 1 message, then return
	END IF
'
' need at least one open sdisplay
'
	sdisplay = 0
	upper = UBOUND (display[])
'
	FOR i = 0 TO upper
		sdisplay = display[i].sdisplay
		IF sdisplay THEN display = i : EXIT FOR
	NEXT i
'
	IFZ sdisplay THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrProcessMessages() : no open display"
		GOTO leave
	END IF
'
	upper = UBOUND (window[])
'
' flush event queue if not enough messages in queue to satisfy argCount request
'
	IF (argCount = -2) THEN
		DispatchEvents ($$TRUE, $$FALSE)
		GOSUB UpdateVariables
	END IF
'
	IF (argCount > 0) THEN
		IF (argCount > count) THEN
			DispatchEvents ($$TRUE, $$FALSE)
		END IF
	END IF
'
' process all pending system messages first
'
	IF whomask THEN GOSUB ProcessSystemMessages
'
' if messages are exhausted before count messages are processed,
' change event mask to enable mouse motion events.
'
	motion = 0
	removed = 0
	GOSUB UpdateVariables
'
	IFZ count THEN
		IF (argCount = -2) THEN GOTO leave
		IF (argCount < -2) THEN
			XxxXgrSleep (ABS (argCount))
			GOSUB UpdateVariables
			IFZ count THEN GOTO leave
			argCount = 1
		END IF
	ELSE
		IF (argCount < -2) THEN argCount = 1
	END IF
'
	DO
		window = queue
		DO UNTIL count											' wait for system/user message
			GOSUB UpdateVariables							' update count variable
			IFZ (count OR motion) THEN				' if no messages...
				GOSUB EnableMotion							' enable mouse motion events
			END IF
			DispatchEvents ($$TRUE, $$TRUE)   ' sync and wait for event
			IF whomask THEN										' if user program called
				IF sysCount THEN								' and system messages exist
					GOSUB ProcessSystemMessages		' process system messages first
				END IF
			END IF
			GOSUB UpdateVariables							' update count variable
		LOOP UNTIL (##SOFTBREAK && ##WHOMASK)							' signals make this func return
		IF (##SOFTBREAK && ##WHOMASK) THEN EXIT DO
'
		RemoveMessage (@window, @message, @v0, @v1, @v2, @v3, @r0, @r1)
'		XxxLog10 ("XgrProcessMessages(213)", cw, window, message, v0, v1, v2, v3, r0, r1)
		IF (message = #ExitMessageLoop) THEN EXIT DO
'
		invalid = $$FALSE
		destroy = $$FALSE
		destroyed = $$FALSE
		processed = $$FALSE
		IF (window < 0) THEN invalid = $$TRUE
		IF (window > upper) THEN invalid = $$TRUE
		IFZ invalid THEN
			IFZ window[window].window THEN invalid = $$TRUE
			IFZ window[window].swindow THEN invalid = $$TRUE
			IF window[window].destroy THEN destroy = $$TRUE
			IF window[window].destroyed THEN destroyed = $$TRUE
			IF window[window].destroyProcessed THEN processed = $$TRUE
		END IF
		IFZ invalid THEN
			top = window[window].top
			leader = window[window].leader
			who = window[top].whomask
			IF who THEN modal = modalWindowUser ELSE modal = modalWindowSystem
			IF modal THEN
'
' Also check for this being a sibling within a modal window,
' where this window's leader or parent is the modal window
'
				IF ((top != modal) && (leader != modal)) THEN
					SELECT CASE TRUE
						CASE MouseMessage (message)			' skip mouse messages not in modalWindow
									GOSUB UpdateVariables
									invalid = $$TRUE
'									PRINT "XgrProcessMessages() : modal.mouse.kill.message"
						CASE KeyboardMessage (message)
									window = modal						' send keyboard messages to modalWindow
'									PRINT "XgrProcessMessages() : modal.keyboard.redirect.message"
					END SELECT
				END IF
			END IF
		END IF
		IFZ invalid THEN
			abort = $$FALSE
			func = window[window].gridFunc
			IF (window = top) THEN func = window[window].winFunc
			IF ceo THEN
				@ceo (window, message, v0, v1, v2, v3, @abort, r1)
			END IF
			IF abort THEN
'				PRINT "XgrProcessMessages().abort : "; HEX$(who,8);; HEX$(window,8);; HEX$(top,8);; HEX$(modal,8);; HEX$(modalWindowSystem,8);; HEX$(modalWindowUser,8);; HEX$(func,8);; invalid;; abort;; message$
			ELSE
				IF func THEN
					@func (window, message, v0, v1, v2, v3, r0, r1)
				END IF
			END IF
		END IF
			SELECT CASE message
				CASE #Destroyed				: window[window].destroyProcessed = $$TRUE
				CASE #WindowDestroyed	: window[window].destroyProcessed = $$TRUE
			END SELECT
		INC removed
		GOSUB UpdateVariables
		IF whomask THEN GOSUB ProcessSystemMessages
		SELECT CASE argCount
			CASE -2		: IFZ count THEN
										DispatchEvents ($$TRUE, $$FALSE)			' squeeze harder
										GOSUB UpdateVariables
										IFZ count THEN EXIT DO								' all processed
									END IF
			CASE -1		: IFZ count THEN EXIT DO									' all processed
			CASE ELSE	: IF (removed >= argCount) THEN EXIT DO		' complete
		END SELECT
	LOOP
'
	IF motion THEN GOSUB DisableMotion
'
leave:
	IF whomask THEN
		DEC recurUser
	ELSE
		DEC recurSys
	END IF
	##RECURUSER = recurUser
	RETURN ($$FALSE)
'
' ------------------------------------------------------------------------------------
'
' *****  EnableMotion  *****
'
SUB EnableMotion
	IF motion THEN EXIT SUB												'
	FOR w = 1 TO UBOUND (window[])								' for all windows
		IF window[w].destroyProcessed THEN DO NEXT	'
		IF window[w].destroyed THEN DO NEXT					'
		IF window[w].destroy THEN DO NEXT						'
		IF window[w].window THEN										' window exists
			windowWhomask = window[w].whomask					' system/user
			IF windowWhomask THEN windowWhomask = 1		' user queue
			IFZ (queue XOR windowWhomask) THEN				' same whomask
				mask = window[w].eventMask							' mask w/o mouse motion
				IF mask THEN														' belt and suspenders
					IFZ (mask AND $$PointerMotionMask) THEN	' motion not enabled
						mask = mask OR $$PointerMotionMask		' enable mouse motion
						smouseWindow = window[w].swindow			'
						IF smouseWindow THEN								' belt, suspenders, more
							##WHOMASK = 0
							##LOCKOUT = 100116
							XSelectInput (sdisplay, smouseWindow, mask)		' enable motion
							##LOCKOUT = lockout
							##WHOMASK = whomask
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT w
	motion = $$TRUE
END SUB
'
'
' *****  DisableMotion  *****
'
SUB DisableMotion
	IFZ motion THEN EXIT SUB											' motion never enabled
	FOR w = 1 TO UBOUND (window[])								'
		IF window[w].destroyProcessed THEN DO NEXT	'
		IF window[w].destroyed THEN DO NEXT					'
		IF window[w].destroy THEN DO NEXT						'
		IF window[w].window THEN										'
			windowWhomask = window[w].whomask					'
			IF windowWhomask THEN windowWhomask = 1		' who queue
			IFZ (queue XOR windowWhomask) THEN				' same whomask
				mask = window[w].eventMask							' mask w/o mouse motion
				IF mask THEN														' belt and suspenders
					IF (mask AND $$PointerMotionMask) THEN		' motion enabled
						mask = mask AND NOT $$PointerMotionMask	' disable mouse motion
						smouseWindow = window[w].swindow
						IF smouseWindow THEN								' belt, suspenders, more
							##WHOMASK = 0
							##LOCKOUT = 100117
							XSelectInput (sdisplay, smouseWindow, mask)		' enable motion
							##LOCKOUT = lockout
							##WHOMASK = whomask
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT w
	motion = $$FALSE
END SUB
'
'
' *****  ProcessSystemMessages  *****
'
SUB ProcessSystemMessages
	DO WHILE sysCount
		##WHOMASK = $$FALSE										  ' system whomask
		XgrProcessMessages ($$ProcessOneOrNone)	' process system message
		##WHOMASK = whomask										  ' restore user whomask
	LOOP
END SUB
'
'
' *****  UpdateVariables  *****
'
SUB UpdateVariables
'
	IF inQueue THEN PRINT "XgrProcessMessages() : inQueue"
	inQueue = $$TRUE
	IF queue THEN
		ceo = userCEO
		count = userCount
		out = userOut
		in = userIn
	ELSE
		ceo = sysCEO
		count = sysCount
		out = sysOut
		in = sysIn
	END IF
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
END SUB

END FUNCTION
'
'
' ###################################
' #####  XgrRegisterMessage ()  #####
' ###################################
'
FUNCTION  XgrRegisterMessage (message$, message)
	SHARED  lastMessage
	SHARED  SBYTE messageType[]
	SHARED  message$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrRegisterMessage()lockout", lockout) : lockout = 0
'
	IFZ message$ THEN RETURN ($$FALSE)
	IFZ message$[] THEN GOSUB Initialize
'
	slot = 0
	upper = UBOUND (message$[])
'
	IF (message$ = "LastMessage") THEN
		message = lastMessage
		RETURN ($$FALSE)
	END IF
'
	FOR i = 1 TO upper
		IF message$[i] THEN
			IF (message$ = message$[i]) THEN
				message = i
				RETURN ($$FALSE)
			END IF
		ELSE
			IFZ slot THEN slot = i
		END IF
	NEXT i
'
' message not yet registered
'
	IFZ slot THEN
		slot = i
		upper = upper + 64
		##WHOMASK = 0
		REDIM message$[upper]
		REDIM messageType[upper]
		##WHOMASK = whomask
	END IF
'
	message = slot
	IF (message > lastMessage) THEN lastMessage = message
'
' register the message
'
	##WHOMASK = 0
	message$[message] = message$
	##WHOMASK = whomask
'
' register the message type
'
	messageType = $$Grid
	x = INSTR (message$, "Window")
	IF (x = 1) THEN messageType = $$Window
	messageType[message] = messageType
	RETURN ($$FALSE)
'
'
' *****  Initialize  *****
'
SUB Initialize
	##WHOMASK = 0
	lastMessage = 0
	upperMessage = 255
	DIM message$[upperMessage]
	DIM messageType[upperMessage]
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ###############################
' #####  XgrSendMessage ()  #####
' ###############################
'
FUNCTION  XgrSendMessage (wingrid, message, v0, v1, v2, v3, r0, r1)
	SHARED  WINDOW  window[]
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	IF InvalidWinGrid (wingrid) THEN
		error$ = ERROR$(ERROR(-1))
		IF ##XBDV THEN PRINT "XgrSendMessage() : invalid wingrid #"; wingrid, error$
		RETURN ($$TRUE)
	END IF
'
	window = wingrid
	top = window[window].top
	func = window[window].gridFunc
	IF (top = window) THEN func = window[window].winFunc
	IF func THEN @func (wingrid, message, @v0, @v1, @v2, @v3, @r0, @r1)
END FUNCTION
'
'
' #####################################
' #####  XgrSendStringMessage ()  #####
' #####################################
'
FUNCTION  XgrSendStringMessage (wingrid, message$, v0, v1, v2, v3, r0, r1)
	SHARED  WINDOW  window[]
	FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	IF InvalidWinGrid (wingrid) THEN
		IF ##XBDV THEN PRINT "XgrSendMessage() : invalid wingrid #"; wingrid
		RETURN ($$TRUE)
	END IF
'
	XgrMessageNameToNumber (@message$, @message)
	IFZ message THEN RETURN ($$TRUE)
'
	window = wingrid
	top = window[window].top
	func = window[window].gridFunc
	IF (top = window) THEN func = window[window].winFunc
	IF func THEN @func (wingrid, message, @v0, @v1, @v2, @v3, @r0, @r1)
END FUNCTION
'
'
' ##########################
' #####  XgrSetCEO ()  #####
' ##########################
'
FUNCTION  XgrSetCEO (func)
	SHARED	userCEO
	SHARED	sysCEO
'
	IF ##WHOMASK THEN
		userCEO = func
	ELSE
		sysCEO = func
	END IF
END FUNCTION
'
'
' #############################
' #####  XgrGetColors ()  #####
' #############################
'
FUNCTION  XgrGetColors (window, back, draw, low, high, dull, acc, lowtext, hightext)
	SHARED  WINDOW  window[]
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XgrGetColors() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	back = window[window].backgroundColor
	draw = window[window].drawingColor
	low = window[window].lowlightColor
	high = window[window].highlightColor
	dull = window[window].dullColor
	acc = window[window].accentColor
	lowtext = window[window].lowtextColor
	hightext = window[window].hightextColor
END FUNCTION
'
'
' ###############################
' #####  XgrGetGridClip ()  #####
' ###############################
'
FUNCTION  XgrGetGridClip (grid, @clip)
'	PRINT "XgrGetGridClip() : unimplemented"
END FUNCTION
'
'
' #####################################
' #####  XgrRegisterIconColor ()  #####
' #####################################
'
' this does not work, apparently because icons have to be bitmaps
' (1 bit depth pixmaps), though I can't find this stated anywhere.
'
FUNCTION  XgrRegisterIconColor (filename$, @icon)
	SHARED  WINDOW  window[]
	SHARED  icon$[]
	SHARED  icon[]
	SHARED  sicon[]
	UBYTE  ico[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrRegisterIconColor()lockout", lockout) : lockout = 0
'
	icon = 0
	IFZ filename$ THEN RETURN ($$FALSE)			' default icon
'
	icon$ = filename$
	u = UBOUND (icon$)
	FOR i = 0 TO u
		c = icon${i}
		IF (c = '\\') THEN icon${i} = '/'			' change "\" to "/"
	NEXT i
'
	IFZ icon$[] THEN
		##WHOMASK = 0
		DIM icon[15]
		DIM icon$[15]
		DIM sicon[15]
		##WHOMASK = whomask
	END IF
'
	slot = -1
	upper = UBOUND (icon$[])
	FOR icon = 1 TO upper
		IF icon$[icon] THEN
			IF (icon$ = icon$[icon]) THEN RETURN ($$FALSE)	' registered
		ELSE
			IF (slot < 0) THEN slot = icon
		END IF
	NEXT icon
'
' icon not yet registered - try to load from disk
'
	IF (slot < 0) THEN
		##WHOMASK = 0
		slot = icon
		upper = upper + 16
		REDIM icon[upper]
		REDIM icon$[upper]
		REDIM sicon[upper]
		##WHOMASK = whomask
	END IF
'
	FOR w = 1 TO UBOUND (window[])
		IF window[w].window THEN
			window = window[w].window
			swindow = window[w].swindow
			sdisplay = window[w].sdisplay
			display = window[w].display
			EXIT FOR
		END IF
	NEXT w
'
	IF ((swindow = 0) OR (sdisplay = 0)) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "XgrRegisterIcon() : some display and window must exist"
		RETURN ($$TRUE)
	END IF
'
	path$ = LCASE$(icon$)
'
	icon = 0
	dot = RINSTR (path$, ".")												' .extent ?
	IF dot THEN path$ = LEFT$ (path$, dot-1)				' remove .extent
	back = RINSTR (path$, "/")											' imbedded path ?
	IFZ back THEN path$ = "$XBDIR/images/" + path$			' default path
	ico$ = path$ + ".ico"
'
	error = XgrLoadImage (@ico$, @ico[])
'
	IF error THEN
		##ERROR = ($$ErrorObjectIcon << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "XgrRegisterIcon() : icon file not found"
		RETURN ($$TRUE)
	END IF
'
	XgrGetImageArrayInfo (@ico[], @depth, @width, @height)
	XgrCreateGrid (@image, #GridTypeImage, 0, 0, width, height, window, 0, 0)
	sicon = window[image].swindow
	XgrSetImage (image, @ico[])
'
	ico$ = RCLIP$ (ico$, 4)										' remove ".ico"
	back = RINSTR (ico$, $$PathSlash$)				' find last path slash
	IF back THEN ico$ = MID$ (ico$, back+1)		' ico$ = pure icon name
'
	icon = slot
	sicon[icon] = sicon				' swindow of icon image grid
	##WHOMASK = 0
	icon$[icon] = ico$				' icon name
	##WHOMASK = whomask
	icon[icon] = image				' native grid # of image grid
	#iconMax = icon						' new icon # upper bound
END FUNCTION
'
'
' #############################
' #####  XgrSetColors ()  #####
' #############################
'
' error = XgrSetColors (grid, back, draw, low, high, dull, acc, lowtext, hightext)
'
FUNCTION  XgrSetColors (grid, back, draw, low, high, dull, acc, lowtext, hightext)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "XgrSetDrawingRGB() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	window = grid
	xdraw = window[window].drawingColor
	xback = window[window].backgroundColor
'
	IF (back != -1) THEN XgrSetBackgroundColor (grid, back)
	IF (draw != -1) THEN XgrSetDrawingColor (grid, draw)
	IF (low != -1) THEN window[window].lowlightColor = low
	IF (high != -1) THEN window[window].highlightColor = high
	IF (dull != -1) THEN window[window].dullColor = dull
	IF (acc != -1) THEN window[window].accentColor = acc
	IF (lowtext != -1) THEN window[window].lowtextColor = lowtext
	IF (hightext != -1) THEN window[window].hightextColor = hightext
END FUNCTION
'
'
' ###############################
' #####  XgrSetGridClip ()  #####
' ###############################
'
FUNCTION  XgrSetGridClip (grid, clip)
'	PRINT "XgrSetGridClip() : unimplemented"
END FUNCTION
'
'
' ####################################
' #####  XgrGetSystemDisplay ()  #####
' ####################################
'
' sdisplay = XgrGetSystemDisplay()
'
' Retrieve the default 'X11 display pointer
'
FUNCTION  XgrGetSystemDisplay()
	SHARED DISPLAY	display[]

	RETURN display[1].sdisplay
END FUNCTION
'
'
' ###############################
' #####  XgrChangeProperty  #####
' ###############################
'
FUNCTION  XgrChangeProperty(wingrid, property, type, mode, data[])
	UBYTE byteData[]

	IFZ data[] THEN
		PRINT "XgrChangeProperty():Error : zero data"
		RETURN
	END IF
	udata = UBOUND(data[])
	DIM byteData[(udata*4)+3]
	FOR i = 0 TO udata
		dataEntry = data[i]
		IFZ dataEntry THEN
			PRINT "XgrChangeProperty():Error : zero data in entry", i
'			RETURN $$TRUE
		ELSE
			j = i*4
			byteData[j] = dataEntry
			byteData[j+1] = dataEntry >> 8
			byteData[j+2] = dataEntry >> 16
			byteData[j+3] = dataEntry >> 24
		END IF
	NEXT i

	elements = UBOUND(byteData[]) + 1
	format = 32
	rc = XxxXgrChangeProperty(wingrid, property, type, format, mode, @byteData[], elements)
	RETURN rc

END FUNCTION
'
'
' #######################################
' #####  XgrGetWindowPropertyXLONG  #####
' #######################################
'
FUNCTION  XgrGetWindowPropertyXLONG (wingrid, property, type, items, data[])

	off = 0
	IFZ items THEN items = 1          'set minimum to at least get something back
	rFormat = 32
'
	XxxXgrGetWindowProperty(wingrid, property, off, items, type, @rType, @rFormat, @rItems, @rAfter, @rData@@[])
'
	DIM data[]
	IF rData@@[] THEN
		urData = UBOUND(rData@@[])
		SELECT CASE rFormat
			CASE 8  : GOSUB ConvertBytes
			CASE 16 : GOSUB ConvertShort
			CASE 32 : GOSUB ConvertLong
		END SELECT
	END IF
'
	RETURN
'
'------------------------------------------
'
' *****  ConvertBytes  *****
'
SUB ConvertBytes

	udata = urData
	DIM data[udata]
	FOR i = 0 TO udata
		data[i] = UBYTEAT(&rData@@[], [i])
	NEXT i

END SUB
'
' *****  ConvertShort  *****
'
SUB ConvertShort

	udata = urData \ 2
	DIM data[udata]
	REDIM rData@@[(udata*2)+1]
	FOR i = 0 TO udata
		data[i] = USHORTAT(&rData@@[], [i])
	NEXT i

END SUB
'
' *****  ConvertLong  *****
'
' On 64-bit software 32-bit data is padded with zeros to 64-bits
'
'
SUB ConvertLong

'	udata = urData \ 4
'	DIM data[udata]
'	REDIM rData@@[(udata*4)+3]
'	FOR i = 0 TO udata
'		data[i] = ULONGAT(&rData@@[], [i])
'	NEXT i

	udata = urData \ 8
	DIM data[udata]
	FOR i = 0 TO udata
		data[i] = XLONGAT(&rData@@[], [i])
	NEXT i

END SUB

END FUNCTION
'
'
' ##############################
' #####  XxxXgrAlarmBlock  #####
' ##############################
'
FUNCTION  XxxXgrAlarmBlock ()

	whomask = ##WHOMASK
	lockout = ##LOCKOUT

	signal = $$SIGMASK_ALRM

	##WHOMASK = 0
	##LOCKOUT = 100118
	return = sigprocmask ($$SIG_BLOCK, &signal, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	RETURN return

END FUNCTION
'
'
' ################################
' #####  XxxXgrAlarmUnblock  #####
' ################################
'
FUNCTION  XxxXgrAlarmUnblock ()

	whomask = ##WHOMASK
	lockout = ##LOCKOUT

	signal = $$SIGMASK_ALRM

	##WHOMASK = 0
	##LOCKOUT = 100119
	return = sigprocmask ($$SIG_UNBLOCK, &signal, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	RETURN return

END FUNCTION
'
'
' ############################
' #####  XxxXgrAsignAtom #####
' ############################
'
' error = XxxXgrAsignAtom (atom$, @atom)
'
' assign new atom number for atom name if it does not exist
'
FUNCTION  XxxXgrAsignAtom (atom$, @atom)
	SHARED  DISPLAY  display[]
'
	atomTrim$ = TRIM$(atom$)
	IFZ atomTrim$ THEN
		PRINT "XxxXgrAsignAtom():Error, blank atom name"
		atom = 0
		RETURN ($$TRUE)
	END IF
'
	sdisplay = display[1].sdisplay	' default display
	IFZ sdisplay THEN
		PRINT "XxxXgrAsignAtom():XError: No open display"
		RETURN ($$TRUE)
	END IF
'
	onlyIfExists = 0                ' assign new atom number if it does not exist
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrAsignAtom()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100120
'
	##XERROR = 0
	atom = XInternAtom (sdisplay, &atomTrim$, onlyIfExists)
'
	##WHOMASK = whomask
	##LOCKOUT = lockout
	IF ##XERROR THEN
		PRINT "XxxXgrAsignAtom():XError", HEXX$(##XERROR, 6), atom$
		RETURN ($$TRUE)
	END IF
'
END FUNCTION
'
'
' ###################################
' #####  XxxXgrAtomNameToNumber #####
' ###################################
'
' error = XxxXgrAtomNameToNumber (atom$, @atom)
'
' Get atom number for existing atom name
' Returns an atom number of zero if atom name is not assigned
'
FUNCTION  XxxXgrAtomNameToNumber (atom$, @atom)
	SHARED  DISPLAY  display[]
'
	atomTrim$ = TRIM$(atom$)
	IFZ atomTrim$ THEN
		PRINT "XxxXgrAtomNameToNumber():Error, blank atom name"
		atom = 0
		RETURN ($$TRUE)
	END IF
'
	sdisplay = display[1].sdisplay	' default display
	onlyIfExists = 1                ' do not assign new atom number if it does not exist
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrAtomNameToNumber()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100121
	##XERROR = 0
'
	atom = XInternAtom (sdisplay, &atomTrim$, onlyIfExists)
'
	##WHOMASK = whomask
	##LOCKOUT = lockout
	IF ##XERROR THEN
		PRINT "XxxXgrAtomNameToNumber():XError", HEXX$(##XERROR, 6), atom$
		RETURN ($$TRUE)
	END IF
'
END FUNCTION
'
'
' ###################################
' #####  XxxXgrAtomNumberToName #####
' ###################################
'
' xerror = XxxXgrAtomNumberToName (atom, @atom$)
'
' xerror is error info set by EventError ()
'
FUNCTION  XxxXgrAtomNumberToName      (atom, @atom$)
	SHARED  DISPLAY  display[]
	AUTOX   addrCstring
'
	sdisplay = display[1].sdisplay			' default display
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrAtomNumberToName()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100122
	##XERROR = 0                               'clear errors set by EventError()
'
	addrCstring = XGetAtomName (sdisplay, atom)
'
	##WHOMASK = whomask
	##LOCKOUT = lockout
'
	atom$ = CSTRING$ (addrCstring)
	XFree (addrCstring)
'
END FUNCTION (##XERROR)
'
'
' ##################################
' #####  XxxXgrChangeProperty  #####
' ##################################
'
FUNCTION  XxxXgrChangeProperty(wingrid, property, type, format, mode, UBYTE data[], elements)
	SHARED  DISPLAY  display[]
	STATIC  sdisplay

	IFZ property THEN
		PRINT "XxxXgrChangeProperty():Error : zero property"
		RETURN
	END IF
	IFZ type THEN
		PRINT "XxxXgrChangeProperty():Error : zero type"
		RETURN
	END IF

	IFZ wingrid THEN
		swindow = display[1].sroot
	ELSE
		XgrGetGridWindow (wingrid, @window)
		XgrWindowToSystemWindow (window, @swindow)
	END IF
	IFZ swindow THEN
		PRINT "XxxXgrChangeProperty():Error:Null system window number"
		RETURN $$TRUE
	END IF

	sdisplay = display[1].sdisplay			' default display
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrChangeProperty()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100123
	rc = XChangeProperty (sdisplay, swindow, property, type, format, mode, &data[], elements)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	RETURN rc
'
END FUNCTION
'
'
' ######################################
' #####  XxxXgrGetWindowMapped ()  #####
' ######################################
'
' error = XxxXgrGetWindowMapped (window, @mapped)
'
FUNCTION  XxxXgrGetWindowMapped (window, mapped)
	SHARED  WINDOW  window[]

	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "XxxXgrGetWindowMapped() : invalid window #"; window
		RETURN ($$TRUE)
	END IF

END FUNCTION
'
'
' #####################################
' #####  XxxXgrGetWindowProperty  #####
' #####################################
'
FUNCTION  XxxXgrGetWindowProperty(wingrid, prop, off, longs, type, @rType, @rFormat, @rItems, @rAfter, UBYTE data[])
	SHARED DISPLAY  display[]
	STATIC xType
	STATIC xFormat
	STATIC xItems
	STATIC xAfter
	STATIC xData

	IFZ wingrid THEN
		swindow = display[1].sroot
	ELSE
		XgrGetGridWindow (wingrid, @window)
		XgrWindowToSystemWindow (window, @swindow)
	END IF
	IFZ swindow THEN
		PRINT "XxxXgrGetWindowProperty():Error:Null system window number"
		RETURN $$TRUE
	END IF
	IFZ prop THEN
		PRINT "XxxXgrGetWindowProperty():Error:Zero prop (property) field"
		RETURN $$TRUE
	END IF
	IFZ type THEN
		PRINT "XxxXgrGetWindowProperty():Error:Zero type field"
		RETURN $$TRUE
	END IF

	sdisplay = display[1].sdisplay			' default display

	data$ = ""
	del = 0					' don't delete, all the memory is released with XFree

	xType = 0
	xFormat = 0
	xItems = 0
	xAfter = 0
	xData = 0

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrGetWindowProperty()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100124
	error = XGetWindowProperty (sdisplay, swindow, prop, off, longs, del, type, &xType, &xFormat, &xItems, &xAfter, &xData)
'
	rType   = xType
	rFormat = xFormat
	rItems = xItems
	rBytes  = xItems
	SELECT CASE xFormat
		CASE 8  : rBytes = xItems
		CASE 16 : rBytes = xItems * 2
		CASE 32 : rBytes = xItems * 8  '32-bit data is padded with zeros to 64-bits
	END SELECT
	rAfter  = xAfter

	udata = rBytes - 1
	DIM data[udata]
	FOR i = 0 TO udata
		data[i] = UBYTEAT(xData, i)
	NEXT i
	XFree (xData)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	RETURN error
'
END FUNCTION
'
'
' ####################################
' #####  XxxXgrGetWMNormalHints  #####
' ####################################
'
FUNCTION  XxxXgrGetWMNormalHints (window, XSizeHints sizeHints)
	SHARED WINDOW window[]
	SHARED XSizeHints normalXSizeHints
	SHARED XSizeHints userXSizeHints

	whomask = ##WHOMASK
	lockout = ##LOCKOUT

	swindow  = window[window].swindow
	sdisplay = window[window].sdisplay

	##WHOMASK = 0
	##LOCKOUT = 100125
	XGetWMNormalHints (sdisplay, swindow, &normalXSizeHints, &userXSizeHints)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	sizeHints = normalXSizeHints
'	sizeHints = userXSizeHints

END FUNCTION
'
'
' ##################################
' #####  XxxXgrListProperties  #####
' ##################################
'
FUNCTION  XxxXgrListProperties(wingrid, atoms[])
	SHARED  DISPLAY  display[]

	IFZ wingrid THEN
		swindow = display[1].sroot
	ELSE
		XgrGetGridWindow (wingrid, @window)
		XgrWindowToSystemWindow (window, @swindow)
	END IF
	IFZ swindow THEN
		PRINT "XxxXgrListProperties():Error:Null system window number"
		RETURN
	END IF

	sdisplay = display[1].sdisplay			' default display
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrListProperties()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100126
	##XERROR = 0
	data = XListProperties (sdisplay, swindow, &num_prop_return)
	IF num_prop_return THEN
		uAtoms = num_prop_return -1
		DIM atoms[uAtoms]
		FOR i = 0 TO uAtoms
			atoms[i] = ULONGAT(data, [i])
		NEXT i
		XFree(data)
	ELSE
		DIM atoms[]
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
	IF ##XERROR THEN PRINT "XxxXgrListProperties():XError", HEXX$(##XERROR, 6), atom$
	RETURN num_prop_return
'
END FUNCTION
'
'
' #######################################
' #####  XxxXgrGetTransientForHint  #####
' #######################################
'
FUNCTION  XxxXgrGetTransientForHint(wingrid, @forwindow)
	SHARED  DISPLAY  display[]

	IFZ wingrid THEN
		swindow = display[1].sroot
	ELSE
		XgrGetGridWindow (wingrid, @window)
		XgrWindowToSystemWindow (window, @swindow)
	END IF
	IFZ swindow THEN
		PRINT "XxxXgrGetTransientForHint():Error:Null system window number for window", window
		RETURN
	END IF

	sdisplay = display[1].sdisplay			' default display
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrGetTransientForHint()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100127
	PRINT "XxxXgrGetTransientForHint()", HEXX$(sdisplay), HEXX$(swindow)
	data = XGetTransientForHint (sdisplay, swindow, &forswindow)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	sroot = display[1].sroot
	IF(forswindow == sroot) THEN
		forwindow = 0
	ELSE
		XgrSystemWindowToWindow (forswindow, @forwindow, @top)
	END IF

	PRINT "XxxXgrGetTransientForHint()",wingrid, swindow, forswindow, forwindow, top

	RETURN
'
END FUNCTION
'
'
' #######################################
' #####  XxxXgrSetTransientForHint  #####
' #######################################
'
FUNCTION  XxxXgrSetTransientForHint(wingrid, forwingrid)
	SHARED  DISPLAY  display[]

	IF InvalidWinGrid (wingrid) THEN PRINT "XxxXgrSetTransientForHint():Invalid window", wingrid : RETURN
'	IFZ wingrid THEN
'		swindow = display[1].sroot
'	ELSE
		XgrGetGridWindow (wingrid, @window)
		XgrWindowToSystemWindow (window, @swindow)
'	END IF
	IFZ swindow THEN
		PRINT "XxxXgrSetTransientForHint():Error:Null system window number for window", window
		RETURN
	END IF

	IFZ forwingrid THEN
		forswindow = display[1].sroot
	ELSE
		XgrGetGridWindow (forwingrid, @forwindow)
		XgrWindowToSystemWindow (forwindow, @forswindow)
	END IF
	IFZ forswindow THEN
		PRINT "XxxXgrSetTransientForHint():Error:Null transient_for system window number for window", forwindow
		RETURN
	END IF
'
	sdisplay = display[1].sdisplay			' default display
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrSetTransientForHint()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100128
'	PRINT "XxxXgrSetTransientForHint()", HEXX$(sdisplay), HEXX$(swindow), HEXX$(forswindow)
	data = XSetTransientForHint (sdisplay, swindow, forswindow)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	RETURN
'
END FUNCTION
'
'
' #################################
' #####  XxxXgrGetAllWindows  #####
' #################################
'
FUNCTION  XxxXgrGetAllWindows (WINDOW windowReturn[], DISPLAY displayReturn[], FONT fontReturn[])
	SHARED  WINDOW	window[]
	SHARED  DISPLAY	display[]
	SHARED  FONT	font[]

	IF windowReturn[] THEN
		uwindow = UBOUND(window[])
		REDIM windowReturn[uwindow]
		FOR i = 0 TO uwindow
			windowReturn[i] = window[i]
		NEXT i
	END IF

	IF displayReturn[]
		udisplay = UBOUND(display[])
		REDIM displayReturn[udisplay]
		FOR i = 0 TO udisplay
			displayReturn[i] = display[i]
		NEXT i
	END IF

	IF fontReturn[] THEN
		ufont = UBOUND(font[])
		REDIM fontReturn[ufont]
		FOR i = 0 TO ufont
			fontReturn[i] = font[i]
		NEXT i
	END IF

END FUNCTION
'
'
' ###############################
' #####  XxxXgrLowerWindow  #####
' ###############################
'
FUNCTION  XxxXgrLowerWindow (window)
	SHARED  DISPLAY  display[]

	XgrWindowToSystemWindow (window, @swindow)
	sdisplay = display[1].sdisplay			' default display
'
'	IF ##XBDV THEN PRINT "XxxXgrLowerWindow()", HEXX$(sdisplay), HEXX$(swindow)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrLowerWindow()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100129
	rc = XLowerWindow (sdisplay, swindow)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask

END FUNCTION
'
'
' ###############################
' #####  XxxXgrRaiseWindow  #####
' ###############################
'
FUNCTION  XxxXgrRaiseWindow (window)
	SHARED  DISPLAY  display[]

	XgrWindowToSystemWindow (window, @swindow)
	sdisplay = display[1].sdisplay			' default display
'
	PRINT "XxxXgrRaiseWindow()", HEXX$(sdisplay), HEXX$(swindow)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrRaiseWindow()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100130
	rc = XRaiseWindow (sdisplay, swindow)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask

END FUNCTION
'
'
' ##################################
' #####  XxxXgrRestackWindows  #####
' ##################################
'
FUNCTION  XxxXgrRestackWindows (@windows[])
	SHARED  WINDOW  window[]
	SHARED  nswindows
	UBYTE byteData[]

'	uwindows = UBOUND (windows[])
'	DIM swindows[uwindows + 10]
'	FOR i = 0 TO uwindows
'		window = windows[i]
'		IF InvalidWindow (window) THEN
'			PRINT "XxxXgrRestackWindow():Invalid window entry", window, i
'			RETURN ($$TRUE)
'		END IF
'		XgrWindowToSystemWindow (window, @swindow)
'		swindows[i] = swindow
'	NEXT i


	uwindows = UBOUND(windows[])
	DIM byteData[(udata*4)+3]
	FOR i = 0 TO uwindows
		window = windows[i]
		IF InvalidWinGrid (window) THEN
			PRINT "XxxXgrRestackWindow():Invalid window entry", window, i
			RETURN ($$TRUE)
		END IF
		XgrWindowToSystemWindow (window, @swindow)

		j = i*4
		byteData[j] = swindow
		byteData[j+1] = swindow >> 8
		byteData[j+2] = swindow >> 16
		byteData[j+3] = swindow >> 24
	NEXT i

'	sdisplay = display[1].sdisplay			' default display
	sdisplay = window[window].sdisplay
	nswindows = uwindows + 1
'
	sdiplayContent = XLONGAT (&sdisplay)
	PRINT "XxxXgrRestackWindow()", HEXX$(sdisplay), HEXX$(sdisplayContent), HEXX$(&byteData[]), HEXX$(&nswindows)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrRestackWindows()lockout", lockout) : lockout = 0
'
	XxxXgrAlarmBlock ()
	##WHOMASK = 0
	##LOCKOUT = 100131
'	rc = XRestackWindows (sdisplay, &byteData[], nswindows)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask

	XxxXgrAlarmUnblock ()

	RETURN rc

END FUNCTION
'
'
' #############################
' #####  XxxXgrSendEvent  #####
' #############################
'
FUNCTION  XxxXgrSendEvent (wingrid, propogate, eventMask, addrXEvent)
	SHARED  DISPLAY  display[]

	IFZ wingrid THEN
		swindow = display[1].sroot
	ELSE
		XgrGetGridWindow (wingrid, @window)
		XgrWindowToSystemWindow (window, @swindow)
	END IF

	sdisplay = display[1].sdisplay			' default display
'
'	PRINT "XxxXgrSendEvent()", HEXX$(sdisplay), HEXX$(swindow)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrSendEvent()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100132
	rc = XSendEvent (sdisplay, swindow, propogate, eventMask, addrXEvent)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask

	RETURN rc

END FUNCTION
'
' ###################################
' #####  XxxXgrConfigureWindow  #####
' ###################################
'
FUNCTION  XxxXgrConfigureWindow (wingrid, valueMask, XWindowChanges values)
	SHARED  DISPLAY  display[]
	STATIC  XWindowChanges valuesCopy

	IFZ wingrid THEN
		swindow = display[1].sroot
	ELSE
		XgrGetGridWindow (wingrid, @window)
		XgrWindowToSystemWindow (window, @swindow)
	END IF

	sdisplay = display[1].sdisplay			' default display
	valuesCopy = values
'
	IF ##XBDV THEN PRINT "XxxXgrConfigureWindow()", HEXX$(sdisplay), HEXX$(swindow)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrConfigureWindow()lockout", lockout) : lockout = 0
'
	##WHOMASK = 0
	##LOCKOUT = 100133
	rc = XConfigureWindow (sdisplay, swindow, valueMask, &valuesCopy)
	##LOCKOUT = lockout
	DispatchEvents ($$TRUE, $$FALSE)
	##WHOMASK = whomask

	RETURN rc

END FUNCTION
'
'
' #################################
' #####  XxxCheckMessages ()  #####
' #################################
'
' Process system messages
'
'	In binary mode, compiler emits a call to XxxCheckMessages() after every
'	DO, FOR, label:, and function entry - to process environment messages.
'	Look for EmitCheckMessageCall() or XxxCheckMessages() in compiler.
'
FUNCTION  XxxCheckMessages ()
	SHARED	sysCount
	SHARED  XSyncTime
	STATIC  xxxEntry
'
' Messages should not be processed when a function has set a LOCKOUT
' expecting it to prevent it from interruption before completion, such
' as the timer interrupt handler.
'
	IF ##LOCKOUT THEN RETURN
	IF ##TIMERLOCKOUT THEN RETURN   ' timer-interrupt being processed
'
	IF xxxEntry THEN RETURN         ' recursive entry not allowed
	xxxEntry = $$TRUE
	errno = xb_geterrno
	IF errno THEN
		a$ = "XxxCheckMessages()error " + STRING$(errno) + "\n"
		write (1, &a$, LEN(a$))
	END IF
'
	XstGetSystemTime (@XSyncNowTime)
	IF ((XSyncNowTime - XSyncTime) > 200) THEN
		DispatchEvents ($$TRUE, $$FALSE)
	END IF
'
	IF sysCount THEN
		whomask = ##WHOMASK
		##WHOMASK = $$FALSE
'		XgrProcessMessages (1)				      ' process one system message
		XgrProcessMessages (sysCount)
		##WHOMASK = whomask
	END IF
'
	xxxEntry = $$FALSE
'
END FUNCTION
'
'
' ##############################
' #####  XxxCheckStack ()  #####
' ##############################
'
' Check call-stack usage
'
'	In binary mode, compiler emits a call to XxxCheckStack() after every
'	function entry - to see if call-stack is almost used up.
' This assumes the stack is 8MB and causes a stack-fault signal when
' when there is some stack space remaining so the PDE can provide
' information for the cause of the stack usage.
'	Look for XxxCheckStack() in compiler.
'
FUNCTION  XxxCheckStack ()
	SHARED	sysCount
	SHARED  XSyncTime                     ' set in DispatchEvents
'
' Messages should not be processed when a function has set a LOCKOUT
' expecting it to prevent it from interruption before completion, such
' as the timer interrupt handler.
'
	IF ##TIMERLOCKOUT THEN RETURN   ' timer-interrupt being processed
	IF ##LOCKOUT THEN RETURN
'
	IF ##WHOMASK THEN
		XxxGetRbpRsp (@rbp, @rsp)
'		s$ = HEXX$(rbp) + " " + HEXX$(rsp) + " " + HEXX$(##STACK) + " " + HEXX$(##STACK0) + " " + HEXX$(##STACKX) + " " + HEXX$(##STACKZ)
'		s$ = HEXX$(rbp) + " " + HEXX$(rsp)
'		XstLog ("XxxCheckStack(31) " + s$)
'		IF ##CAPSLOCK THEN XxxLog ("XxxCheckStack(31) " + s$)
		IF (rsp < ##STACKZ - 0x7F8000) THEN
			raise ($$SIGSTKFLT)
		END IF
	ELSE
'		IF ##XBDV THEN PRINT "XxxCheckStack()##WHOMASK is zero"
	END IF
'
	EXIT FUNCTION
'
	errno = xb_geterrno
	IF errno THEN
		a$ = "XxxCheckStack()error " + STRING$(errno) + "\n"
		write (1, &a$, LEN(a$))
	END IF

	IF sysCount THEN
		whomask = ##WHOMASK
		##WHOMASK = $$FALSE
		XgrProcessMessages (sysCount)				      ' process system messages
		##WHOMASK = whomask
	ELSE
		XstGetSystemTime (@XSyncNowTime)
		IF ((XSyncNowTime - XSyncTime) > 200) THEN
			DispatchEvents ($$TRUE, $$FALSE)
		END IF
	END IF
'
END FUNCTION
'
'
' ##################################
' #####  XxxXgrSysMessages ()  #####
' ##################################
'
' Process all system messages
'
FUNCTION  XxxXgrSysMessages ()
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
	SHARED	sysCount
	STATIC  xxxEntry
'
	IF ##TIMERLOCKOUT THEN RETURN
'
' When a modal window is active, all messages
' are processed by XuiGetModalInfo()
'
	IF modalWindowSystem THEN RETURN
	IF modalWindowUser THEN RETURN
'
	IF xxxEntry THEN RETURN         ' recursive entry not allowed
	xxxEntry = $$TRUE
'
	whomask = ##WHOMASK
'
	IFZ sysCount THEN XxxDispatchEvents ($$TRUE, $$FALSE)  'sync periodically
'
' process all system messages
'
	DO WHILE sysCount
		##WHOMASK = $$FALSE
		XgrProcessMessages (sysCount)					          ' process all system message
		##WHOMASK = whomask
	LOOP
	xxxEntry = $$FALSE
'
END FUNCTION
'
'
' ##################################
' #####  XxxDispatchEvents ()  #####
' ##################################
'
' sync only every 200 msec or longer
' It seems that if there are too many XSync commands sent
' to XWindows when there are no events to sync, it causes:
' XIO: fatal IO error 0 (Success) on X server ":0.0"
'
FUNCTION  XxxDispatchEvents (sync, wait)
	SHARED  XSyncTime                     ' set in DispatchEvents
'
	IFZ sync THEN DispatchEvents (sync, wait)
	'
	XstGetSystemTime (@XSyncNowTime)
	IF ((XSyncNowTime - XSyncTime) > 200) THEN
		DispatchEvents (sync, wait)
	ELSE
		DispatchEvents ($$FALSE, wait)
	END IF
'
END FUNCTION
'
'
' ###############################
' #####  XxxXgrBlowback ()  #####
' ###############################
'
' Want to free all user graphics contexts and windows without
' processing associated messages that might call functions in
' the user program being killed that might be screwed up.
' ##WHOMASK = 0 prevents XgrProcessMessages() from processing
' user messages, even if user messages are in fact generated.
' After all user resources are destroyed, DispatchEvents()
' processes the xlib events and adds user messages to the
' user queue.  This function simply clears the queue.
'
FUNCTION  XxxXgrBlowback ()
	SHARED  WINDOW  window[]
	SHARED  charMap[]
	SHARED  userCount
	SHARED  userOut
	SHARED  userIn
	SHARED  userCEO
	SHARED  inHold
	SHARED  inQueue
	SHARED	recurSys, recurUser
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrBlowback()lockout", lockout) : lockout = 0
'
' start with an empty user message queue
'
	inQueue = $$TRUE
	userCount = 0
	userOut = 0
	userIn = 0
	userCEO = 0
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
'
	##WHOMASK = 0
'
'	write (1, &"XxxXgrBlowback().A\n", 19)
'
	FOR i = 1 TO UBOUND (window[])
		IF window[i].window THEN
			IF window[i].swindow THEN
				IF window[i].whomask THEN
					IF ((i == window[i].top) || (window[i].type == 1))  THEN
						gc = window[i].gc
						swindow = window[i].swindow
						sdisplay = window[i].sdisplay
						##WHOMASK = 0
						##LOCKOUT = 100134
						XFreeGC (sdisplay, gc)
						window[i].gc = 0
						IF (window[i].type == 1) THEN
							window[i].destroy = $$TRUE
							XFreePixmap (sdisplay, swindow)
							window[i].window = 0
							window[i].swindow = 0
							window[i].destroyed = $$TRUE
						ELSE
							window[i].destroy = $$TRUE
							XDestroyWindow (sdisplay, swindow)
						END IF
						##LOCKOUT = lockout
						DispatchEvents ($$TRUE, $$FALSE)
						##WHOMASK = whomask
					END IF
					ATTACH charMap[i,] TO temp[]				' ditch char map
				END IF
			END IF
		END IF
	NEXT i
'
' clear user message queue completely
'
	IF inHold THEN EmptyHoldingQueue ()
	inQueue = $$TRUE
	userCount = 0
	userOut = 0
	userIn = 0
	userCEO = 0
	inQueue = $$FALSE
'
	IF recurSys THEN
		text$ = "XxxXgrBlowback()recurSys " + STR$(recurSys) + STR$(recurUser)
		XxxLog (text$)
		recurSys  = 0
		recurUser = 0
	END IF
	##WHOMASK = whomask
	##LOCKOUT = lockout
'
'	write (1, &"XxxXgrBlowback().Z\n", 19)
END FUNCTION
'
'
' ###########################################
' #####  XxxXgrConsoleUpdateRequest ()  #####
' ###########################################
'
FUNCTION  XxxXgrConsoleUpdateRequest (consolePrinting)
	SHARED  consoleUpdateRequest
'
	consoleUpdateRequest = consolePrinting
'
END FUNCTION
'
'
' ################################
' #####  XxxXgrGridTimer ()  #####
' ################################
'
' XxxXgrGridTimer() is called by the standard library when
' any grid timer started by XgrSetGridTimer() expires.
' XxxXgrGridTimer() adds the appropriate #TimeOut message
' to the appropriate message queue.
'
FUNCTION  XxxXgrGridTimer (tgrid, timer, count, msec, time)
	SHARED  WINDOW  window[]
	AUTOX  FUNCADDR  func (XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG, XLONG)
'
	upper = UBOUND (window[])
	IF (tgrid && (tgrid <= upper)) THEN
		IF (window[tgrid].timer == timer) THEN
			IF count THEN
				IF ##CAPSLOCK THEN PRINT "XxxXgrGridTimer", count
			END IF
			window[tgrid].timer = 0
			XgrAddMessage (tgrid, #TimeOut, timer, count, msec, time, 0, tgrid)
		ELSE
			PRINT "XxxXgrGridTimer(): Error : tgrid, timer ", tgrid, timer, window[tgrid].timer
		END IF
	END IF
'
END FUNCTION
'
'
' ###########################
' #####  XxxXgrQuit ()  #####
' ###########################
'
FUNCTION  XxxXgrQuit ()
	SHARED  WINDOW  window[]
	SHARED  swindow[]
	SHARED  userCount
	SHARED  sysCount
	SHARED  userOut
	SHARED  sysOut
	SHARED  userIn
	SHARED  sysIn
	SHARED  sysCEO
	SHARED  userCEO
	SHARED  inHold
	SHARED  inQueue
	STATIC  WINDOW  zipwin
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrQuit()lockout", lockout) : lockout = 0
	alarmbusy = ##ALARMBUSY
	##ALARMBUSY	= $$TRUE
'
' start with empty message queues
'
	inQueue = $$TRUE
	userCount = 0
	sysCount = 0
	userOut = 0
	sysOut = 0
	userIn = 0
	sysIn = 0
	sysCEO = 0
	userCEO = 0
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
'
	##WHOMASK = 0
'
' It is important that the console file be closed
' before the console window is destroyed.
' Print commands will output to a terminal if
' XBasic was launched from a terminal.
'
	CLOSE ($$ALL)   ' close all files including the console
'
' Destroy all user and system windows
'
	FOR window = 1 TO UBOUND (window[])
		IF window[window].window THEN
			IF window[window].swindow THEN
				IFZ window[window].destroy THEN
					IFZ window[window].destroyed THEN
						IFZ window[window].destroyProcessed THEN
							IF (window[window].kind = $$KindWindow) THEN
								XgrDestroyWindow (window)
								window[window] = zipwin
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT window
'
' clear xlib event queue completely
'
	DispatchEvents ($$TRUE, $$TRUE)
'
' Check if any windows that do not appear to be destroyed
'
	IF ##XBDV THEN
		FOR i = 1 TO UBOUND (window[])
			IF window[i].window THEN
				window = window[i].window
				parent = window[i].parent
				leader = window[i].leader
				kind = window[i].kind
				type = window[i].type
				top = window[i].top
				PRINT "XxxXgrQuit():window not destroyed", window, parent, leader, kind, type, top
			END IF
		NEXT i
		'
		uSwindow = UBOUND(swindow[])
		FOR i = 0 TO uSwindow
			IF swindow[i] THEN
				PRINT "XxxXgrQuit():swindow not empty", i, swindow[i]
			END IF
		NEXT i
'		PRINT "XxxXgrQuit():UBOUND(swindow[])", uSwindow
	END IF
'
' clear message queues completely
'
	IF inHold THEN EmptyHoldingQueue ()
	inQueue = $$TRUE
	userCount = 0
	sysCount = 0
	userOut = 0
	sysOut = 0
	userIn = 0
	sysIn = 0
	sysCEO = 0
	userCEO = 0
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
'
	display = 1                                         ' default display is 1
	error = Display (@display, $$Close, @display$)			' no error if already open
'
	##ALARMBUSY	= alarmbusy
	##WHOMASK = whomask
	##LOCKOUT = lockout
END FUNCTION
'
'
' ###################################
' #####  XxxXgrResetUserMode()  #####
' ###################################
'
' Reset all user-mode variables to their default value.
' This is called when a user-program is started in the PDE.
'
FUNCTION  XxxXgrResetUserMode()
	SHARED userCEO
	userCEO = 0
END FUNCTION
'
'
' ####################################
' #####  XxxXgrSetHelpWindow ()  #####
' ####################################
'
FUNCTION  XxxXgrSetHelpWindow (window)
	SHARED	helpWindow
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "XxxXgrSetHelpWindow() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	helpWindow = window
END FUNCTION
'
'
' #############################
' #####  XxxXgrSetHuh ()  #####
' #############################
'
FUNCTION  XxxXgrSetHuh (duh)
	SHARED	huh
'
	huh = duh
END FUNCTION
'
'
' ############################
' #####  XxxXgrSleep ()  #####
' ############################
'
' sysCount = XxxXgrSleep (msec)
'
' Wait up to msec (maximum of 200 millisseconds)
' while looking for new events.
' This function is meant to be called only by XstSleep()
'
FUNCTION  XxxXgrSleep (msec)
	SHARED  FUNCADDR  ehelp[] (ANY)
	SHARED  FUNCADDR  event[] (ANY)
	SHARED  DISPLAY  display[]
	SHARED  maxConnect
	SHARED  connect[]
'	SHARED  eventTime
'	SHARED  flushTime
'	SHARED  userCount
	SHARED	sysCount
	SHARED  consoleUpdateRequest
	SHARED  XSyncTime
	SHARED  consoleUpdateTime
	AUTOX  conn[]
	AUTOX  UTIMEVAL  delay
	AUTOX  XAnyEvent  event
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxXgrSleep()lockout", lockout) : lockout = 0
	lockout = 0
'
	IF ##INEXIT THEN RETURN								' avoid trouble
	IF ##SOFTBREAK THEN RETURN						' break out first
'
	XstGetSystemTime (@nowTime)
'
	sdisplay = display[1].sdisplay				' default display
'
	IFZ sdisplay THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "DispatchEvents() : no display exists"
		RETURN ($$TRUE)
	END IF
'
' Check for events pending on entry
'
	DO
		##WHOMASK = 0
		##LOCKOUT = 100135
		pending = XPending (sdisplay)
		IF pending THEN
			event.type = $$TRUE													' mark event as invalid
			XNextEvent (sdisplay, &event)
		END IF
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IFZ pending THEN EXIT DO
		IF (event.type = $$TRUE) THEN EXIT DO				' no event received : signal broke out of XNextEvent()
		IF (event.type > $$LastEvent) THEN DO LOOP	' bad event type
		error = @event [event.type] (@event)				' call event function
'		IF ##XBDV THEN @ehelp [event.type] (@event)	' display debug help
	LOOP
'
' Send an XSync if 200 msec after the last one
'
	IF ((nowTime - XSyncTime) > 200) THEN
		XstGetSystemTime (@XSyncTime)
	END IF
'
	delay.tv_sec = 0										' 0 seconds +
	IF (msec > 200) THEN msec = 200
	delay.tv_usec = msec * 1000         ' 200ms = 200,000us delay
	u = maxConnect >> 5
	uc = UBOUND (conn[])
	uct = UBOUND (connect[])
	IF (uc != u) THEN
		uc = u
		##WHOMASK = 0
		DIM conn[u]
		##WHOMASK = whomask
	END IF
	FOR nn = 0 TO u
		conn[nn] = connect[nn]
	NEXT nn
	xb_seterrno(0)
	##WHOMASK = 0
	##LOCKOUT = 100137
	ready = select (maxConnect+1, &conn[], 0, &conn[], &delay)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
' Check for events pending after sync/wait
'
	DO
		##WHOMASK = 0
		##LOCKOUT = 100138
		pending = XPending (sdisplay)
		IF pending THEN
			event.type = $$TRUE													' mark event as invalid
			XNextEvent (sdisplay, &event)
		END IF
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IFZ pending THEN EXIT DO
		IF (event.type = $$TRUE) THEN EXIT DO				' no event received : signal broke out of XNextEvent()
		IF (event.type > $$LastEvent) THEN DO LOOP	' bad event type
		error = @event [event.type] (@event)				' call event function
'		IF ##XBDV THEN @ehelp [event.type] (@event)	' display debug help
	LOOP
'
' If text has been sent to the console in the
' last 200 millisecond update (redraw) the console
'
	IF consoleUpdateRequest THEN
		IF ##CONGRID THEN
			XstGetSystemTime (@nowTime)
			IF ((nowTime - consoleUpdateTime) >= 200) THEN
				consoleUpdateTime = nowTime
				XgrAddMessage (##CONGRID, #Update, 0, 0, 0, 0, 0, 0)
			END IF
		END IF
	END IF
'
	RETURN (sysCount)
'
END FUNCTION
'
'
' #####################################################
' #####  XxxXgrWindowToSystemDisplayAndWindow ()  #####
' #####################################################
'
FUNCTION  XxxXgrWindowToSystemDisplayAndWindow (window, @sdisplay, @swindow)
	SHARED  WINDOW  window[]
'
	IF (window < 0) THEN RETURN ($$TRUE)
	IF (window > UBOUND (window[])) THEN RETURN ($$TRUE)
'
	sdisplay = window[window].sdisplay
	swindow = window[window].swindow
END FUNCTION
'
'
' ##############################
' #####  XxxDIBToDIB24 ()  #####
' ##############################
'
' enter with valid 1,4,8,16,24,32 bit DIB in simage[]
' return 24-bit RGB DIB in dimage[]
'
' NOTE: this is FULL of misaligned access problems because microsoft
' buttheads defined STUPID wierd-size and misaligned DIB components.
'
FUNCTION  XxxDIBToDIB24 (UBYTE simage[], UBYTE dimage[])
	RGBQUAD  palette[]
'
	$BI_RGB       = 0					' 24-bit RGB
	$BI_BITFIELDS = 3					' 32-bit RGB
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxDIBToDIB24()lockout", lockout) : lockout = 0
'
	DIM dimage[]
'
	IFZ simage[] THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XxxDIBToDIB32() : input argument simage[] is empty"
		RETURN ($$TRUE)
	END IF
'
	addr = &simage[]
	size = SIZE (simage[])
'
	IF (size < 64) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XxxDIBToDIB32() : error : input argument simage[] too small : "; size
		RETURN ($$TRUE)
	END IF
'
	byte0 = simage[0]
	byte1 = simage[1]
'
	byte2 = simage[2]
	byte3 = simage[3]
	byte4 = simage[4]
	byte5 = simage[5]
'
	byte10 = simage[10]
	byte11 = simage[11]
	byte12 = simage[12]
	byte13 = simage[13]
'
	byte14 = simage[14]
	byte15 = simage[15]
	byte16 = simage[16]
	byte17 = simage[17]
'
	byte18 = simage[18]
	byte19 = simage[19]
	byte20 = simage[20]
	byte21 = simage[21]
'
	byte22 = simage[22]
	byte23 = simage[23]
	byte24 = simage[24]
	byte25 = simage[25]
'
	byte26 = simage[26]
	byte27 = simage[27]
'
	byte28 = simage[28]
	byte29 = simage[29]
'
	byte30 = simage[30]
	byte31 = simage[31]
'
	byte46 = simage[46]
	byte47 = simage[47]
	byte48 = simage[48]
	byte49 = simage[49]
'
	byte50 = simage[50]
	byte51 = simage[51]
	byte52 = simage[52]
	byte53 = simage[53]
'
	bfType = (byte1 << 8) OR byte0
	bfSize = (byte5 << 24) OR (byte4 << 16) OR (byte3 << 8) OR byte2
	offBits = (byte13 << 24) OR (byte12 << 16) OR (byte11 << 8) OR byte10
	biSize = (byte17 << 24) OR (byte16 << 16) OR (byte15 << 8) OR byte14
	width = (byte21 << 24) OR (byte20 << 16) OR (byte19 << 8) OR byte18
	height = (byte25 << 24) OR (byte24 << 16) OR (byte23 << 8) OR byte22
	bitCount = (byte29 << 8) OR byte28
	clrUsed = (byte49 << 24) OR (byte48 << 16) OR (byte47 << 8) OR byte46
	clrImportant = (byte53 << 24) OR (byte52 << 16) OR (byte51 << 8) OR byte50
'
	biWidth = width
	biHeight = height
	biBitCount = bitCount
	biClrUsed = clrUsed
	biClrImportant = clrImportant
'
	bitmapAddr = iAddr + offBits
	paletteAddr = iAddr + 14 + biSize
'
	addrImage = addr + offBits						' boom : image address
	addrPalette = addr + biSize + 14			' boom : palette address in 1,4,8 bits/pixel
'
' initialize palette entry to color array if bits/pixel = 1,4,8
'
'	PRINT "print palette contents : entry, blue, green, red"
'
	skip = $$FALSE
	SELECT CASE biBitCount
		CASE 1		: top = 1
		CASE 4		: top = 15
		CASE 8		: top = 255
		CASE ELSE	: skip = $$TRUE
	END SELECT
'
	IFZ skip THEN
		paddr = addrPalette
		DIM palette[top]
		FOR p = 0 TO top
			palette[p].blue = UBYTEAT (paddr)		: INC paddr
			palette[p].green = UBYTEAT (paddr)	: INC paddr
			palette[p].red = UBYTEAT (paddr)		: INC paddr
			palette[p].zero = 0									: INC paddr
'			PRINT HEX$(p); " : "; HEX$(palette[p].blue,2);; HEX$(palette[p].green,2);; HEX$(palette[p].red,2)
		NEXT p
	END IF
'
'	a$ = INLINE$ ("press enter to continue...")
'
' make sure width and height are positive (can be negative in BMP format)
'
	dataOffset = 128
	width = ABS (biWidth)
	height = ABS (biHeight)
'
' compute size and upper bound of destination DIB image array
'
	widthbytes = ((width * 3) + 3) AND -4
	dsize = dataOffset + (height * widthbytes)
	dupper = dsize - 1
'
' create destination image array
'
	DIM dimage[dupper]										' destination image[] in DIB32
'
'
' initialize destination image[] array
'
	dataOffset = 128
	daddr = &dimage[]											' start addr of destination image[] array
	daddrPalette = daddr + 54							' start addr of destination color masks
	daddrImage = daddr + dataOffset				' start addr of destination image data
'
' create 32-bit DIB header
'
	dimage[0] = 'B'															' DIB aka BMP signature
	dimage[1] = 'M'
	dimage[2] = dsize AND 0x00FF								' file size
	dimage[3] = (dsize >> 8) AND 0x00FF
	dimage[4] = (dsize >> 16) AND 0x00FF
	dimage[5] = (dsize >> 24) AND 0x00FF
	dimage[6] = 0
	dimage[7] = 0
	dimage[8] = 0
	dimage[9] = 0
	dimage[10] = dataOffset AND 0x00FF					' file offset of bitmap data
	dimage[11] = (dataOffset >> 8) AND 0x00FF
	dimage[12] = (dataOffset >> 16) AND 0x00FF
	dimage[13] = (dataOffset >> 24) AND 0x00FF
'
'	fill BITMAPINFOHEADER (first 6 members)
'
	info = 14
	dimage[info+0] = 40													' XLONG : BITMAPINFOHEADER size
	dimage[info+1] = 0
	dimage[info+2] = 0
	dimage[info+3] = 0
	dimage[info+4] = width AND 0x00FF						' XLONG : width in pixels
	dimage[info+5] = (width >> 8) AND 0x00FF
	dimage[info+6] = (width >> 16) AND 0x00FF
	dimage[info+7] = (width >> 24) AND 0x00FF
	dimage[info+8] = height AND 0x00FF						' XLONG : height in pixels
	dimage[info+9] = (height >> 8) AND 0x00FF
	dimage[info+10] = (height >> 16) AND 0x00FF
	dimage[info+11] = (height >> 24) AND 0x00FF
	dimage[info+12] = 1													' USHORT : # of planes
	dimage[info+13] = 0													'
	dimage[info+14] = 32												' USHORT : bits per pixel
	dimage[info+15] = 0													'
	dimage[info+16] = $BI_BITFIELDS							' XLONG : 32-bit bitfield RGB
	dimage[info+17] = 0													'
	dimage[info+18] = 0													'
	dimage[info+19] = 0													'
	dimage[info+20] = 0													' XLONG : size image
	dimage[info+21] = 0													'
	dimage[info+22] = 0													'
	dimage[info+23] = 0													'
	dimage[info+24] = 0													' XLONG : xPPM
	dimage[info+25] = 0													'
	dimage[info+26] = 0													'
	dimage[info+27] = 0													'
	dimage[info+28] = 0													' XLONG : yPPM
	dimage[info+29] = 0													'
	dimage[info+30] = 0													'
	dimage[info+31] = 0													'
	dimage[info+32] = 0													' XLONG : clrUsed
	dimage[info+33] = 0													'
	dimage[info+34] = 0													'
	dimage[info+35] = 0													'
	dimage[info+36] = 0													' XLONG : clrImportant
	dimage[info+37] = 0													'
	dimage[info+38] = 0													'
	dimage[info+39] = 0													'
'
' note : the following are for 32-bit $$BI_BITFIELDS only,
' not for standard/default Windows 24-bit RGB format
'
	cbit = info+40															' color bitmasks offset
	rbits = 0xFFC00000													' 10-bits - red
	gbits = 0x003FF800													' 11-bits - green
	bbits = 0x000007FF													' 11-bits - blue
'
	dimage[cbit+0] = rbits AND 0x00FF
	dimage[cbit+1] = (rbits >> 8) AND 0x00FF
	dimage[cbit+2] = (rbits >> 16) AND 0x00FF
	dimage[cbit+3] = (rbits >> 24) AND 0x00FF
	dimage[cbit+4] = gbits AND 0x00FF
	dimage[cbit+5] = (gbits >> 8) AND 0x00FF
	dimage[cbit+6] = (gbits >> 16) AND 0x00FF
	dimage[cbit+7] = (gbits >> 24) AND 0x00FF
	dimage[cbit+8] = bbits AND 0x00FF
	dimage[cbit+9] = (bbits >> 8) AND 0x00FF
	dimage[cbit+10] = (bbits >> 16) AND 0x00FF
	dimage[cbit+11] = (bbits >> 24) AND 0x00FF
'
'
'
	off = 0									' offset on sub-byte size pixels
	daddr = daddrImage			' address of destination image
	saddr = addrImage				' address of source image
	width = ABS (width)			' width without flip
	height = ABS (height)		' height without flip
'
	mask = $$FALSE
	SELECT CASE biBitCount
		CASE 16	: mask = $$TRUE
		CASE 32	: mask = $$TRUE
	END SELECT
'
	IF mask THEN
		pa = addrPalette
		p0 = UBYTEAT (pa)		: INC pa
		p1 = UBYTEAT (pa)		: INC pa
		p2 = UBYTEAT (pa)		: INC pa
		p3 = UBYTEAT (pa)		: INC pa
		p4 = UBYTEAT (pa)		: INC pa
		p5 = UBYTEAT (pa)		: INC pa
		p6 = UBYTEAT (pa)		: INC pa
		p7 = UBYTEAT (pa)		: INC pa
		p8 = UBYTEAT (pa)		: INC pa
		p9 = UBYTEAT (pa)		: INC pa
		p10 = UBYTEAT (pa)	: INC pa
		p11 = UBYTEAT (pa)	: INC pa
'
		redMask = (p3 << 24) OR (p2 << 16) OR (p1 << 8) OR p0
		greenMask = (p7 << 24) OR (p6 << 16) OR (p5 << 8) OR p4
		blueMask = (p11 << 24) OR (p10 << 16) OR (p9 << 8) OR p8
'
		redMaskLow = -1			' bit # of least significant mask bit = 1
		redMaskHigh = -1		' bit # of most significant mask bit = 1
		greenMaskLow = -1		' bit # of least significant mask bit = 1
		greenMaskHigh = -1	' bit # of most significant mask bit = 1
		blueMaskLow = -1		' bit # of least significant mask bit = 1
		blueMaskHigh = -1		' bit # of most significant mask bit = 1
'
' find width and position of mask field for each source field (rgb)
'
		FOR n = 0 TO 31
			IF (redMaskLow < 0) THEN
				IF ((redMask >> n) AND 0x0001) THEN redMaskLow = n
			END IF
			IF (redMaskLow >= 0) THEN
				IF ((redMask >> n) AND 0x0001) THEN redMaskHigh = n
			END IF
'
			IF (greenMaskLow < 0) THEN
				IF ((greenMask >> n) AND 0x0001) THEN greenMaskLow = n
			END IF
			IF (greenMaskLow >= 0) THEN
				IF ((greenMask >> n) AND 0x0001) THEN greenMaskHigh = n
			END IF
'
			IF (blueMaskLow < 0) THEN
				IF ((blueMask >> n) AND 0x0001) THEN blueMaskLow = n
			END IF
			IF (blueMaskLow >= 0) THEN
				IF ((blueMask >> n) AND 0x0001) THEN blueMaskHigh = n
			END IF
		NEXT n
'
		redBits = redMaskHigh - redMaskLow + 1
		greenBits = greenMaskHigh - greenMaskLow + 1
		blueBits = blueMaskHigh - blueMaskLow + 1
	END IF
'
	SELECT CASE biBitCount
		CASE 1	:	scanx = ((((width * 1) + 31) AND -32) >> 3)
		CASE 4	: scanx = ((((width * 4) + 31) AND -32) >> 3)
		CASE 8	: scanx = ((((width * 8) + 31) AND -32) >> 3)
		CASE 16	: scanx = ((((width * 16) + 31) AND -32) >> 3)
		CASE 24	: scanx = ((((width * 24) + 31) AND -32) >> 3)
		CASE 32	: scanx = ((((width * 32) + 31) AND -32) >> 3)
	END SELECT
'
	dy = scanx
	IF (biHeight > 0) THEN				' image is upside down - flip y
		dy = -scanx
		saddr = saddr + (scanx * (height-1))		' move to last scan line
	END IF
'
	FOR y = 0 TO height-1
		xaddr = saddr								' xaddr = saddr at start of scan line
		FOR x = 0 TO width-1
			SELECT CASE biBitCount
				CASE 1	: GOSUB Move1		: offset = offset + 1
				CASE 4	: GOSUB Move4		: offset = offset + 4
				CASE 8	: GOSUB Move8		: offset = offset + 8
				CASE 16	:	GOSUB Move16	: offset = offset + 16
				CASE 24	: GOSUB Move24	: offset = offset + 24
				CASE 32	: GOSUB Move32	: offset = offset + 32
			END SELECT
		NEXT x
		off = 0													' bit offset = 0
		saddr = xaddr + dy							' move to next/previous scan line
		daddr = (daddr + 3) AND -4			' next scan line at MOD 4 address
	NEXT y
'
'	a$ = INLINE$ ("press enter to continue...")
'
	DIM palette[]
	RETURN
'
'
' *****  Move1  *****
'
SUB Move1
	shift = 7 - off												' upper bits of byte first
	pixel = UBYTEAT (saddr)
	IF shift THEN pixel = pixel >> shift
	pixel = pixel AND 0x01
	off = off + 1
	IF (off = 8) THEN off = 0 : INC saddr
'
	red = palette[pixel].red
	green = palette[pixel].green
	blue = palette[pixel].blue
'
	UBYTEAT (daddr) = blue		: INC daddr
	UBYTEAT (daddr) = green		: INC daddr
	UBYTEAT (daddr) = red			: INC daddr
END SUB
'
'
' *****  Move4  *****
'
SUB Move4
	shift = 4 - off													' upper nybble of byte first
	pixel = UBYTEAT (saddr)
	IF shift THEN pixel = pixel >> shift
	pixel = pixel AND 0x0F
	off = off + 4
	IF (off = 8) THEN off = 0 : INC saddr
'
	blue = palette[pixel].blue
	green = palette[pixel].green
	red = palette[pixel].red
'
	UBYTEAT (daddr) = blue	: INC daddr
	UBYTEAT (daddr) = green	: INC daddr
	UBYTEAT (daddr) = red		: INC daddr
END SUB
'
'
' *****  Move8  *****
'
SUB Move8
	pixel = UBYTEAT (saddr)
	INC saddr
'
	red = palette[pixel].red
	green = palette[pixel].green
	blue = palette[pixel].blue
'
	UBYTEAT (daddr) = blue	: INC daddr
	UBYTEAT (daddr) = green	: INC daddr
	UBYTEAT (daddr) = red		: INC daddr
END SUB
'
'
' *****  Move16  *****
'
SUB Move16
	byte0 = UBYTEAT (saddr)	: INC saddr
	byte1 = UBYTEAT (saddr) : INC saddr
	pixel = (byte1 << 8) OR byte0
'
	red = (pixel AND redMask) >> redMaskLow
	green = (pixel AND greenMask) >> greenMaskLow
	blue = (pixel AND blueMask) >> blueMaskLow
'
	UBYTEAT (daddr) = blue	: INC daddr
	UBYTEAT (daddr) = green	: INC daddr
	UBYTEAT (daddr) = red		: INC daddr
END SUB
'
'
' *****  Move24  *****
'
SUB Move24
	blue = UBYTEAT (saddr)	: INC saddr
	green = UBYTEAT (saddr)	: INC saddr
	red = UBYTEAT (saddr)		: INC saddr
'
	UBYTEAT (daddr) = blue	: INC daddr
	UBYTEAT (daddr) = green	: INC daddr
	UBYTEAT (daddr) = red		: INC daddr
END SUB
'
'
' *****  Move32  *****
'
SUB Move32
	byte0 = UBYTEAT (saddr)	: INC saddr
	byte1 = UBYTEAT (saddr) : INC saddr
	byte2 = UBYTEAT (saddr)	: INC saddr
	byte3 = UBYTEAT (saddr) : INC saddr
	pixel = (byte3 << 24) OR (byte2 << 16) OR (byte1 << 8) OR byte0
'
	red = (pixel AND redMask) >> redMaskLow
	green = (pixel AND greenMask) >> greenMaskLow
	blue = (pixel AND blueMask) >> blueMaskLow
'
	UBYTEAT (daddr) = blue	: INC daddr
	UBYTEAT (daddr) = green	: INC daddr
	UBYTEAT (daddr) = red		: INC daddr
END SUB
END FUNCTION
'
'
' ##############################
' #####  XxxDIBToDIB32 ()  #####
' ##############################
'
' enter with valid 1,4,8,16,24,32 bit DIB in simage[]
' return 32-bit 10-11-11 RGB DIB in dimage[] (standard image[] array)
'
' NOTE: this is FULL of misaligned access problems because microsoft
' buttheads defined STUPID wierd-size and misaligned DIB components.
'
FUNCTION  XxxDIBToDIB32 (UBYTE simage[], UBYTE dimage[])
	RGBQUAD  palette[]
'
	$BI_RGB       = 0					' 24-bit RGB
	$BI_BITFIELDS = 3					' 32-bit RGB
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxDIBToDIB32()lockout", lockout) : lockout = 0
'
	DIM dimage[]
'
	IFZ simage[] THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XxxDIBToDIB32() : input argument simage[] is empty"
		RETURN ($$TRUE)
	END IF
'
	addr = &simage[]
	size = SIZE (simage[])
'
	IF (size < 64) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "XxxDIBToDIB32() : error : input argument simage[] too small : "; size
		RETURN ($$TRUE)
	END IF
'
	byte0 = simage[0]
	byte1 = simage[1]
'
	byte2 = simage[2]
	byte3 = simage[3]
	byte4 = simage[4]
	byte5 = simage[5]
'
	byte10 = simage[10]
	byte11 = simage[11]
	byte12 = simage[12]
	byte13 = simage[13]
'
	byte14 = simage[14]
	byte15 = simage[15]
	byte16 = simage[16]
	byte17 = simage[17]
'
	byte18 = simage[18]
	byte19 = simage[19]
	byte20 = simage[20]
	byte21 = simage[21]
'
	byte22 = simage[22]
	byte23 = simage[23]
	byte24 = simage[24]
	byte25 = simage[25]
'
	byte26 = simage[26]
	byte27 = simage[27]
'
	byte28 = simage[28]
	byte29 = simage[29]
'
	byte30 = simage[30]
	byte31 = simage[31]
'
	byte46 = simage[46]
	byte47 = simage[47]
	byte48 = simage[48]
	byte49 = simage[49]
'
	byte50 = simage[50]
	byte51 = simage[51]
	byte52 = simage[52]
	byte53 = simage[53]
'
	bfType = (byte1 << 8) OR byte0
	bfSize = (byte5 << 24) OR (byte4 << 16) OR (byte3 << 8) OR byte2
	offBits = (byte13 << 24) OR (byte12 << 16) OR (byte11 << 8) OR byte10
	biSize = (byte17 << 24) OR (byte16 << 16) OR (byte15 << 8) OR byte14
	width = (byte21 << 24) OR (byte20 << 16) OR (byte19 << 8) OR byte18
	height = (byte25 << 24) OR (byte24 << 16) OR (byte23 << 8) OR byte22
	bitCount = (byte29 << 8) OR byte28
	clrUsed = (byte49 << 24) OR (byte48 << 16) OR (byte47 << 8) OR byte46
	clrImportant = (byte53 << 24) OR (byte52 << 16) OR (byte51 << 8) OR byte50
'
	biWidth = width
	biHeight = height
	biBitCount = bitCount
	biClrUsed = clrUsed
	biClrImportant = clrImportant
'
	bitmapAddr = iAddr + offBits
	paletteAddr = iAddr + 14 + biSize
'
	addrImage = addr + offBits						' boom : image address
	addrPalette = addr + biSize + 14			' boom : palette address in 1,4,8 bits/pixel
'
' initialize palette entry to color array if bits/pixel = 1,4,8
'
'	PRINT "print palette contents : entry, blue, green, red"
'
	skip = $$FALSE
	SELECT CASE biBitCount
		CASE 1		: top = 1
		CASE 4		: top = 15
		CASE 8		: top = 255
		CASE ELSE	: skip = $$TRUE
	END SELECT
'
	IFZ skip THEN
		paddr = addrPalette
		DIM palette[top]
		FOR p = 0 TO top
			palette[p].blue = UBYTEAT (paddr)		: INC paddr
			palette[p].green = UBYTEAT (paddr)	: INC paddr
			palette[p].red = UBYTEAT (paddr)		: INC paddr
			palette[p].zero = 0									: INC paddr
'			PRINT HEX$(p); " : "; HEX$(palette[p].blue,2);; HEX$(palette[p].green,2);; HEX$(palette[p].red,2)
		NEXT p
	END IF
'
'	a$ = INLINE$ ("press enter to continue...")
'
' make sure width and height are positive (can be negative in BMP format)
'
	dataOffset = 128
	width = ABS (biWidth)
	height = ABS (biHeight)
'
' compute size and upper bound of destination DIB image array
'
	dsize = dataOffset + ((width * height) << 2)
	dupper = dsize - 1
'
' create destination image array
'
	DIM dimage[dupper]										' destination image[] in DIB32
'
'
' initialize destination image[] array
'
	dataOffset = 128
	daddr = &dimage[]											' start addr of destination image[] array
	daddrPalette = daddr + 54							' start addr of destination color masks
	daddrImage = daddr + dataOffset				' start addr of destination image data
'
' create 32-bit DIB header
'
	dimage[0] = 'B'															' DIB aka BMP signature
	dimage[1] = 'M'
	dimage[2] = dsize AND 0x00FF								' file size
	dimage[3] = (dsize >> 8) AND 0x00FF
	dimage[4] = (dsize >> 16) AND 0x00FF
	dimage[5] = (dsize >> 24) AND 0x00FF
	dimage[6] = 0
	dimage[7] = 0
	dimage[8] = 0
	dimage[9] = 0
	dimage[10] = dataOffset AND 0x00FF					' file offset of bitmap data
	dimage[11] = (dataOffset >> 8) AND 0x00FF
	dimage[12] = (dataOffset >> 16) AND 0x00FF
	dimage[13] = (dataOffset >> 24) AND 0x00FF
'
'	fill BITMAPINFOHEADER (first 6 members)
'
	info = 14
	dimage[info+0] = 40													' XLONG : BITMAPINFOHEADER size
	dimage[info+1] = 0
	dimage[info+2] = 0
	dimage[info+3] = 0
	dimage[info+4] = width AND 0x00FF						' XLONG : width in pixels
	dimage[info+5] = (width >> 8) AND 0x00FF
	dimage[info+6] = (width >> 16) AND 0x00FF
	dimage[info+7] = (width >> 24) AND 0x00FF
	dimage[info+8] = height AND 0x00FF					' XLONG : height in pixels
	dimage[info+9] = (height >> 8) AND 0x00FF
	dimage[info+10] = (height >> 16) AND 0x00FF
	dimage[info+11] = (height >> 24) AND 0x00FF
	dimage[info+12] = 1													' USHORT : # of planes
	dimage[info+13] = 0													'
	dimage[info+14] = 32												' USHORT : bits per pixel
	dimage[info+15] = 0													'
	dimage[info+16] = $BI_BITFIELDS							' XLONG : 32-bit bitfield RGB
	dimage[info+17] = 0													'
	dimage[info+18] = 0													'
	dimage[info+19] = 0													'
	dimage[info+20] = 0													' XLONG : size image
	dimage[info+21] = 0													'
	dimage[info+22] = 0													'
	dimage[info+23] = 0													'
	dimage[info+24] = 0													' XLONG : xPPM
	dimage[info+25] = 0													'
	dimage[info+26] = 0													'
	dimage[info+27] = 0													'
	dimage[info+28] = 0													' XLONG : yPPM
	dimage[info+29] = 0													'
	dimage[info+30] = 0													'
	dimage[info+31] = 0													'
	dimage[info+32] = 0													' XLONG : clrUsed
	dimage[info+33] = 0													'
	dimage[info+34] = 0													'
	dimage[info+35] = 0													'
	dimage[info+36] = 0													' XLONG : clrImportant
	dimage[info+37] = 0													'
	dimage[info+38] = 0													'
	dimage[info+39] = 0													'
'
' note : the following are for 32-bit $$BI_BITFIELDS only,
' not for standard/default Windows 24-bit RGB format
'
	cbit = info+40															' color bitmasks offset
	rbits = 0xFFC00000													' 10-bits - red
	gbits = 0x003FF800													' 11-bits - green
	bbits = 0x000007FF													' 11-bits - blue
'
	dimage[cbit+0] = rbits AND 0x00FF
	dimage[cbit+1] = (rbits >> 8) AND 0x00FF
	dimage[cbit+2] = (rbits >> 16) AND 0x00FF
	dimage[cbit+3] = (rbits >> 24) AND 0x00FF
	dimage[cbit+4] = gbits AND 0x00FF
	dimage[cbit+5] = (gbits >> 8) AND 0x00FF
	dimage[cbit+6] = (gbits >> 16) AND 0x00FF
	dimage[cbit+7] = (gbits >> 24) AND 0x00FF
	dimage[cbit+8] = bbits AND 0x00FF
	dimage[cbit+9] = (bbits >> 8) AND 0x00FF
	dimage[cbit+10] = (bbits >> 16) AND 0x00FF
	dimage[cbit+11] = (bbits >> 24) AND 0x00FF
'
'
'
	off = 0									' offset on sub-byte size pixels
	daddr = daddrImage			' address of destination image
	saddr = addrImage				' address of source image
	width = ABS (width)			' width without flip
	height = ABS (height)		' height without flip
'
	mask = $$FALSE
	SELECT CASE biBitCount
		CASE 16	: mask = $$TRUE
		CASE 32	: mask = $$TRUE
	END SELECT
'
	IF mask THEN
		pa = addrPalette
		p0 = UBYTEAT (pa)		: INC pa
		p1 = UBYTEAT (pa)		: INC pa
		p2 = UBYTEAT (pa)		: INC pa
		p3 = UBYTEAT (pa)		: INC pa
		p4 = UBYTEAT (pa)		: INC pa
		p5 = UBYTEAT (pa)		: INC pa
		p6 = UBYTEAT (pa)		: INC pa
		p7 = UBYTEAT (pa)		: INC pa
		p8 = UBYTEAT (pa)		: INC pa
		p9 = UBYTEAT (pa)		: INC pa
		p10 = UBYTEAT (pa)	: INC pa
		p11 = UBYTEAT (pa)	: INC pa
'
		redMask = (p3 << 24) OR (p2 << 16) OR (p1 << 8) OR p0
		greenMask = (p7 << 24) OR (p6 << 16) OR (p5 << 8) OR p4
		blueMask = (p11 << 24) OR (p10 << 16) OR (p9 << 8) OR p8
'
		redMaskLow = -1			' bit # of least significant mask bit = 1
		redMaskHigh = -1		' bit # of most significant mask bit = 1
		greenMaskLow = -1		' bit # of least significant mask bit = 1
		greenMaskHigh = -1	' bit # of most significant mask bit = 1
		blueMaskLow = -1		' bit # of least significant mask bit = 1
		blueMaskHigh = -1		' bit # of most significant mask bit = 1
'
' find width and position of mask field for each source field (rgb)
'
		FOR n = 0 TO 31
			IF (redMaskLow < 0) THEN
				IF ((redMask >> n) AND 0x0001) THEN redMaskLow = n
			END IF
			IF (redMaskLow >= 0) THEN
				IF ((redMask >> n) AND 0x0001) THEN redMaskHigh = n
			END IF
'
			IF (greenMaskLow < 0) THEN
				IF ((greenMask >> n) AND 0x0001) THEN greenMaskLow = n
			END IF
			IF (greenMaskLow >= 0) THEN
				IF ((greenMask >> n) AND 0x0001) THEN greenMaskHigh = n
			END IF
'
			IF (blueMaskLow < 0) THEN
				IF ((blueMask >> n) AND 0x0001) THEN blueMaskLow = n
			END IF
			IF (blueMaskLow >= 0) THEN
				IF ((blueMask >> n) AND 0x0001) THEN blueMaskHigh = n
			END IF
		NEXT n
'
		redBits = redMaskHigh - redMaskLow + 1
		greenBits = greenMaskHigh - greenMaskLow + 1
		blueBits = blueMaskHigh - blueMaskLow + 1
	END IF
'
	SELECT CASE biBitCount
		CASE 1	:	scanx = ((((width * 1) + 31) AND -32) >> 3)
		CASE 4	: scanx = ((((width * 4) + 31) AND -32) >> 3)
		CASE 8	: scanx = ((((width * 8) + 31) AND -32) >> 3)
		CASE 16	: scanx = ((((width * 16) + 31) AND -32) >> 3)
		CASE 24	: scanx = ((((width * 24) + 31) AND -32) >> 3)
		CASE 32	: scanx = ((((width * 32) + 31) AND -32) >> 3)
	END SELECT
'
	dy = scanx
	IF (biHeight > 0) THEN				' image is upside down - flip y
		dy = -scanx
		saddr = saddr + (scanx * (height-1))		' move to last scan line
	END IF
'
	FOR y = 0 TO height-1
		xaddr = saddr								' xaddr = saddr at start of scan line
		FOR x = 0 TO width-1
			SELECT CASE biBitCount
				CASE 1	: GOSUB Move1		: offset = offset + 1
				CASE 4	: GOSUB Move4		: offset = offset + 4
				CASE 8	: GOSUB Move8		: offset = offset + 8
				CASE 16	:	GOSUB Move16	: offset = offset + 16
				CASE 24	: GOSUB Move24	: offset = offset + 24
				CASE 32	: GOSUB Move32	: offset = offset + 32
			END SELECT
		NEXT x
		off = 0													' bit offset = 0
		saddr = xaddr + dy							' move to next/previous scan line
	NEXT y
'
'	a$ = INLINE$ ("press enter to continue...")
	DIM palette[]
	RETURN
'
'
' *****  Move1  *****
'
SUB Move1
	shift = 7 - off												' upper bits of byte first
	pixel = UBYTEAT (saddr)
	IF shift THEN pixel = pixel >> shift
	pixel = pixel AND 0x01
	off = off + 1
	IF (off = 8) THEN off = 0 : INC saddr
'
	red = palette[pixel].red
	green = palette[pixel].green
	blue = palette[pixel].blue
'
	rgb32 = 0
	rgb32 = rgb32 OR ((red << 24) AND 0xFFC00000)
	rgb32 = rgb32 OR ((green << 14) AND 0x003FF800)
	rgb32 = rgb32 OR ((blue << 3) AND 0x000007FF)
'
	XLONGAT (daddr) = rgb32
	daddr = daddr + 4
END SUB
'
'
' *****  Move4  *****
'
SUB Move4
	shift = 4 - off													' upper nybble of byte first
	pixel = UBYTEAT (saddr)
	IF shift THEN pixel = pixel >> shift
	pixel = pixel AND 0x0F
	off = off + 4
	IF (off = 8) THEN off = 0 : INC saddr
'
	blue = palette[pixel].blue
	green = palette[pixel].green
	red = palette[pixel].red
'
	rgb32 = 0
	rgb32 = rgb32 OR ((red << 24) AND 0xFFC00000)
	rgb32 = rgb32 OR ((green << 14) AND 0x003FF800)
	rgb32 = rgb32 OR ((blue << 3) AND 0x000007FF)
'
'	PRINT HEX$(rgb32,8); " : "; HEX$(red,2);; HEX$(green,2);; HEX$(blue,2)
'
	XLONGAT (daddr) = rgb32
	daddr = daddr + 4
END SUB
'
'
' *****  Move8  *****
'
SUB Move8
	pixel = UBYTEAT (saddr)
	INC saddr
'
	red = palette[pixel].red
	green = palette[pixel].green
	blue = palette[pixel].blue
'
	rgb32 = 0
	rgb32 = rgb32 OR ((red << 24) AND 0xFFC00000)
	rgb32 = rgb32 OR ((green << 14) AND 0x003FF800)
	rgb32 = rgb32 OR ((blue << 3) AND 0x000007FF)
'
	XLONGAT (daddr) = rgb32
	daddr = daddr + 4
END SUB
'
'
' *****  Move16  *****
'
SUB Move16
	byte0 = UBYTEAT (saddr)	: INC saddr
	byte1 = UBYTEAT (saddr) : INC saddr
	pixel = (byte1 << 8) OR byte0
'
	red = (pixel AND redMask) >> redMaskLow
	green = (pixel AND greenMask) >> greenMaskLow
	blue = (pixel AND blueMask) >> blueMaskLow
'
	rgb32 = 0
	rgb32 = rgb32 OR ((red << (32 - redBits)) AND 0xFFC00000)
	rgb32 = rgb32 OR ((green << (22 - greenBits)) AND 0x003FF800)
	rgb32 = rgb32 OR ((blue << (11 - blueBits)) AND 0x000007FF)
'
	XLONGAT (daddr) = rgb32
	daddr = daddr + 4
END SUB
'
'
' *****  Move24  *****
'
SUB Move24
	blue = UBYTEAT (saddr) : INC saddr
	green = UBYTEAT (saddr) : INC saddr
	red = UBYTEAT (saddr) : INC saddr
'
	rgb32 = 0
	rgb32 = rgb32 OR ((red << 24) AND 0xFFC00000)
	rgb32 = rgb32 OR ((green << 14) AND 0x003FF800)
	rgb32 = rgb32 OR ((blue << 3) AND 0x000007FF)
'
	XLONGAT (daddr) = rgb32
	daddr = daddr + 4
END SUB
'
'
' *****  Move32  *****
'
SUB Move32
	byte0 = UBYTEAT (saddr)	: INC saddr
	byte1 = UBYTEAT (saddr) : INC saddr
	byte2 = UBYTEAT (saddr)	: INC saddr
	byte3 = UBYTEAT (saddr) : INC saddr
	pixel = (byte3 << 24) OR (byte2 << 16) OR (byte1 << 8) OR byte0
'
	red = (pixel AND redMask) >> redMaskLow
	green = (pixel AND greenMask) >> greenMaskLow
	blue = (pixel AND blueMask) >> blueMaskLow
'
	rgb32 = 0
	rgb32 = rgb32 OR ((red << (32 - redBits)) AND 0xFFC00000)
	rgb32 = rgb32 OR ((green << (22 - greenBits)) AND 0x003FF800)
	rgb32 = rgb32 OR ((blue << (11 - blueBits)) AND 0x000007FF)
'
	XLONGAT (daddr) = rgb32
	daddr = daddr + 4
END SUB
END FUNCTION
'
'
' ##########################################
' #####  ConvertColorToSystemColor ()  #####
' ##########################################
'
FUNCTION  ConvertColorToSystemColor (window, color, @scolor)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  rgb[]
	AUTOX  XColor  sc
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"ConvertColorToSystemColor()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "ConvertColorToSystemColor() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	display = window[window].display
	sdisplay = window[window].sdisplay
	colormap = display[display].colormap
'
' color = 0 means standard color # 0 = $$Black
'
	IFZ color THEN
'		window[window].backRed = 0
'		window[window].backGreen = 0
'		window[window].backBlue = 0
'		window[window].backColor =16005 0
'		window[window].backgroundColor = 0
		scolor = display[display].color[0]
		RETURN ($$FALSE)
	END IF
'
' standard color # != 0 means color is standard color #
'
	c = color AND 0x000000FF
	IF (c > 124) THEN c = 124
'
	IF c THEN
		rgb = rgb[c]
'		window[window].backColor = c
'		window[window].backRed = (rgb AND 0xFF000000) >> 16
'		window[window].backGreen = (rgb AND 0x00FF0000) >> 8
'		window[window].backBlue = (rgb AND 0x0000FF00)
'		window[window].backgroundColor = c
		scolor = display[display].color[c]
		RETURN ($$FALSE)
	END IF
'
' color is in rgb field of rgbc color argument
'
	red = (color AND 0xFF000000) >> 16
	green = (color AND 0x00FF0000) >> 8
	blue = (color AND 0x0000FF00)
'
	r = red >> 8
	g = green >> 8
	b = blue >> 8
	c = 0
'
'	window[window].backRed = red
'	window[window].backGreen = green
'	window[window].backBlue = blue
'	window[window].backColor = 0
'	window[window].backgroundColor = (r << 24) + (g << 16) + (b << 8) + c
'
	sc.scolor = 0
	sc.r = red
	sc.g = green
	sc.b = blue
'
	##WHOMASK = 0
	##LOCKOUT = 100139
	okay = XAllocColor (sdisplay, colormap, &sc)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF okay THEN scolor = sc.scolor
END FUNCTION
'
'
' ########################################
' #####  ConvertRGBToSystemColor ()  #####
' ########################################
'
FUNCTION  ConvertRGBToSystemColor (window, red, green, blue, @scolor)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	AUTOX  XColor  sc
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"ConvertRGBToSystemColor()lockout", lockout) : lockout = 0
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "ConvertRGBToSystemColor() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	display = window[window].display
	sdisplay = window[window].sdisplay
	colormap = display[display].colormap
'
' color = 0 means standard color # 0 = $$Black
'
	IFZ (red OR green OR blue) THEN
'		window[window].backRed = 0
'		window[window].backGreen = 0
'		window[window].backBlue = 0
'		window[window].backColor = 0
'		window[window].backgroundColor = 0
		scolor = display[display].color[0]
		RETURN ($$FALSE)
	END IF
'
' allocate rgb color
'
	red = red AND 0x0000FFFF
	green = green AND 0x0000FFFF
	blue = blue AND 0x0000FFFF
	r = red >> 8
	g = green >> 8
	b = blue >> 8
	c = 0
'
'	window[window].backRed = red
'	window[window].backGreen = green
'	window[window].backBlue = blue
'	window[window].backColor = 0
'	window[window].backgroundColor = (r << 24) + (g << 16) + (b << 8) + c
'
	sc.scolor = 0
	sc.r = red
	sc.g = green
	sc.b = blue
'
	##WHOMASK = 0
	##LOCKOUT = 100140
	okay = XAllocColor (sdisplay, colormap, &sc)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF okay THEN scolor = sc.scolor
END FUNCTION
'
'
' ############################
' #####  CreateQueue ()  #####
' ############################
'
' if message[] is empty, create message[1,]
' if specified queue (0 or 1) is empty, attach message queue to message[queue,]
'
FUNCTION  CreateQueue (queue)
	SHARED  MESSAGE  message[]
	SHARED  userCount
	SHARED  sysCount
	SHARED  userOut
	SHARED  sysOut
	SHARED  userIn
	SHARED  sysIn
	SHARED  inHold
	SHARED  inQueue
	MESSAGE m[]
'
	PRINT "CreateQueue", queue
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"CreateQueue()lockout", lockout) : lockout = 0
'
	IF queue THEN queue = 1							' queue 0 = system : queue 1 = user
'
	##WHOMASK = 0
	IFZ message[] THEN DIM message[1,]	' create message queue array
	##WHOMASK = whomask
'
	IF message[queue,] THEN
		PRINT "CreateQueue() : error : specified queue already exists"
		RETURN ($$TRUE)
	END IF
'
' initialize the appropriate queue variables
'
	inQueue = $$TRUE
'
	IF queue THEN
		userCount = 0
		userOut = 0
		userIn = 0
	ELSE
		sysCount = 0
		sysOut = 0
		sysIn = 0
	END IF
'
' create a message array and attach to appropriate leg of message array
'
	##WHOMASK = 0
	DIM m[2047]
	ATTACH m[] TO message[queue,]
	##WHOMASK = whomask
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
END FUNCTION
'
'
' #####################################
' #####  DestroyUserResources ()  #####
' #####################################
'
FUNCTION  DestroyUserResources ()
	SHARED	MESSAGE  message[]
	SHARED  WINDOW  window[]
	SHARED  inHold
	SHARED	inQueue
	SHARED	userCount
	SHARED	userOut
	SHARED	userIn
	SHARED	userCEO
	STATIC  WINDOW  zipwin
'
	GOSUB ProcessEventsAndMessages
	FOR window = 1 TO UBOUND (window[])
		IF window[window].window THEN
			IF window[window].swindow THEN
				IF window[window].whomask THEN
					IFZ window[window].destroy THEN
						IFZ window[window].destroyed THEN
							IFZ window[window].destroyProcessed THEN
								IF (window[window].kind = $$KindWindow) THEN
									IF ##XBDV THEN PRINT "DestroyUserResources()window =", window
									XgrDestroyWindow (window)
									GOSUB ProcessEventsAndMessages
									window[window] = zipwin
								END IF
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	NEXT window
	GOSUB ProcessEventsAndMessages			' one last flush
'
' clear out user message queue
'
	inQueue = $$TRUE
	userCount = 0
	userOut = 0
	userIn = 0
	userCEO = 0
'
	IF message[1,] THEN
		FOR i = 0 TO UBOUND (message[1,])
			message[1,i].wingrid = 0
			message[1,i].message = 0
			message[1,i].v0 = 0
			message[1,i].v1 = 0
			message[1,i].v2 = 0
			message[1,i].v3 = 0
			message[1,i].r0 = 0
			message[1,i].r1 = 0
		NEXT i
	END IF
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
	RETURN
'
'
' *****  ProcessEventsAndMessages  *****
'
SUB ProcessEventsAndMessages
	DispatchEvents ($$TRUE, $$TRUE)            ' convert events into messages
	DO
		XgrProcessMessages ($$ProcessOneOrNone)  ' and process the messages
		XgrMessagesPending (@count)              ' until they're gone
	LOOP WHILE count
END SUB
END FUNCTION
'
'
' #####################
' #####  Display  #####
' #####################
'
' display 0 = invalid
' display 1 = default display (reserved slot)
'
' command = $$Open
' command = $$Close
'
FUNCTION  Display (display, command, display$)
	SHARED  DISPLAY  display[]
	SHARED	display$[]
	SHARED  maxConnect
	SHARED  connect[]
	SHARED  bitmask[]
	SHARED  r[]
	SHARED  g[]
	SHARED  b[]
	STATIC  default$
	STATIC  displayStatic$
	AUTOX  XWindowAttributes  rootAttributes
	AUTOX  XColor  sc
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"Display()lockout", lockout) : lockout = 0
'
	IFZ default$ THEN GOSUB Initialize
'
	SELECT CASE command
		CASE $$Open			: GOSUB Open
		CASE $$Close		: GOSUB Close
		CASE ELSE				: GOSUB ErrorInvalidArgument
	END SELECT
	##LOCKOUT = lockout
	##WHOMASK = whomask
	RETURN (return)
'
'
' *****  Open  *****
'
SUB Open
	slot = 0
	display = 0
	upper = UBOUND (display$[])
'
' see if display is already open
'
	IFZ display$ THEN
		display = 1
	ELSE
		IF (display$ = default$) THEN
			display = 1
		ELSE
			FOR display = 2 TO upper
				IF (display$ = display$[display]) THEN EXIT SUB		' display open
				IFZ slot THEN
					IFZ display$[display] THEN slot = display				' available slot
				END IF
			NEXT display
		END IF
	END IF
'
' make room in display$[] and display[] for new display
'
	IF (display > upper) THEN
		IF slot THEN
			display = slot															' take available slot
		ELSE
			##WHOMASK = 0
			upper = display
			REDIM display[upper]												' create new slot
			REDIM display$[upper]
			##WHOMASK = whomask
		END IF
	END IF
'
' if display is already open, return without error
'
	IF (display[display].status AND $$Open) THEN		' display already open
		return = $$FALSE
		EXIT SUB
	END IF
'
' open a new display, default or otherwise
'
	##WHOMASK = 0
	##LOCKOUT = 100141
	sdisplay = XOpenDisplay (&display$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ sdisplay THEN
		##ERROR = ($$ErrorObjectDevice << 8) OR $$ErrorNatureInvalidName
		IF ##XBDV THEN PRINT "Display() : Open : error : XOpenDisplay() failed", display$
		display = 1      ' default display number
		return = $$TRUE
		EXIT SUB
	END IF
'
' get info about display and root (most via info on root window)
'
	##WHOMASK = 0
	##LOCKOUT = 100142
	screen = XDefaultScreen (sdisplay)
	sroot = XRootWindow (sdisplay, screen)
	visual = XDefaultVisual (sdisplay, screen)
	connect = XConnectionNumber (sdisplay)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (connect > 0) THEN
		IF (connect > maxConnect) THEN maxConnect = connect
		upper = UBOUND (connect[])
		bit = connect AND 0x1F
		mask = bitmask[bit]
		word = connect >> 5
		IF (word > upper) THEN
			##WHOMASK = 0
			REDIM connect[word]
			##WHOMASK = whomask
		END IF
		connect[word] = connect[word] OR mask
	ELSE
		connect = 0
	END IF
'
'	a$ = "'" + STRING$(word) + ":" + STRING$(maxConnect) + "*" + STRING$(connect) + "." + HEX$(mask,8) + "'\n"
'	write (1, &a$, LEN(a$))
'
	##WHOMASK = 0
	##LOCKOUT = 100143
	status = XGetWindowAttributes (sdisplay, sroot, &rootAttributes)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ status THEN
		##ERROR = ($$ErrorObjectSystemRoutine << 8) OR $$ErrorNatureFailed
		IF ##XBDV THEN PRINT "Display() : Open : error : XGetWindowAttributes(sroot)"
		return = $$TRUE
		EXIT SUB
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100144
	black = XBlackPixel (sdisplay, screen)					' system black color #
	white = XWhitePixel (sdisplay, screen)					' system white color #
	colormap = XDefaultColormap (sdisplay, screen)	' the colormap
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF display$ THEN
		##WHOMASK = 0
		display$[display] = display$                		' save display name
		##WHOMASK = whomask
	END IF
'
	display[display].display = display
	display[display].sdisplay = sdisplay
	display[display].status = $$Open
	display[display].selectedWindow = 0
	display[display].x = rootAttributes.x
	display[display].y = rootAttributes.y
	display[display].width = rootAttributes.width
	display[display].height = rootAttributes.height
	display[display].depth = rootAttributes.depth
	display[display].class = rootAttributes.class
	display[display].borderWidth = 0
	display[display].titleHeight = 0
	display[display].mouseX = 0
	display[display].mouseY = 0
	display[display].mouseState = 0
	display[display].mouseTime = 0
	display[display].mouseGrid = 0
	display[display].mouseWindow = 0
	display[display].mouseMessage = 0
	display[display].mouseFocusGrid = 0
	display[display].screen = screen
	display[display].visual = visual
	display[display].sroot = sroot
	display[display].connect = connect
	display[display].bitGravity = rootAttributes.bitGravity
	display[display].winGravity = rootAttributes.winGravity
	display[display].backingStore = rootAttributes.backingStore
	display[display].backingPlanes = rootAttributes.backingPlanes
	display[display].backingPixel = rootAttributes.backingPixel
	display[display].saveUnder = rootAttributes.saveUnder
	display[display].mapInstalled = rootAttributes.mapInstalled
	display[display].mapState = rootAttributes.mapState
	display[display].allEventMasks = rootAttributes.allEventMasks
	display[display].yourEventMask = rootAttributes.yourEventMask
	display[display].doNotPropagateMask = rootAttributes.doNotPropagateMask
	display[display].overrideRedirect = rootAttributes.overrideRedirect
	display[display].defaultColormap = colormap
	display[display].colormap = colormap
	display[display].black = black
	display[display].white = white
	display[display].color[0] = black
	display[display].color[124] = white
'
' disaster colormap has 0 = $$Black and 1-124 = $$White
'
	FOR i = 1 TO 127
		display[display].color[i] = white		' in case colors don't assign right
	NEXT i
'
' establish standard colors 0 to 124 in colormap
'
	##WHOMASK = 0
	color = 0
	FOR r = 0 TO 4
		FOR g = 0 TO 4
			FOR b = 0 TO 4
				sc.r = r[r]
				sc.g = g[g]
				sc.b = b[b]
				##LOCKOUT = 100145
				okay = XAllocColor (sdisplay, colormap, &sc)
				##LOCKOUT = lockout
				display[display].color[color] = sc.scolor
				INC color
			NEXT b
		NEXT g
	NEXT r
'
	##WHOMASK = whomask
END SUB
'
'
' *****  Close  *****
'
SUB Close
	IF InvalidDisplay (display) THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "Display() : Close : error : invalid display #"
		return = $$TRUE
	END IF
'
' check for invalid display #
'
	error = $$FALSE
	upper = UBOUND (display[])
	IFZ display[] THEN error = $$TRUE
	IF (display < 0) THEN error = $$TRUE
	IF (display > upper) THEN error = $$TRUE
	IFZ (display[display].status AND $$Open) THEN error = $$TRUE
'
	IF error THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
		IF ##XBDV THEN PRINT "Display() : Close : error : invalid display #", display
		return = $$TRUE
		EXIT SUB
	END IF
'
	sdisplay = display[display].sdisplay
	connect = display[display].connect
	display[display].sdisplay = 0
	display[display].connect = 0
	display[display].status = 0
	##WHOMASK = 0
	display$[display] = ""
	##WHOMASK = whomask
'
	IF (connect > 0) THEN
		upper = UBOUND (connect[])
		bit = connect AND 0x1F
		mask = bitmask[bit]
		word = connect >> 5
		IF (word > upper) THEN
			upper = word
			##WHOMASK = 0
			REDIM connect[word]
			##WHOMASK = whomask
		END IF
		connect[word] = connect[word] AND NOT mask
		IF (connect >= maxConnect) THEN
			FOR wo = upper TO 0 STEP -1
				IF connect[wo] THEN maxConnect = (wo * 32) + 31
			NEXT wo
		END IF
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 100146
	XCloseDisplay (sdisplay)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END SUB
'
'
' *****  ErrorInvalidArgument  *****
'
SUB ErrorInvalidArgument
	##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument
	return = $$TRUE
END SUB
'
' *****  Initialize  *****
'
SUB Initialize
	DIM display[1]												' 0 invalid : 1 default
	##WHOMASK = 0
	##LOCKOUT = 100147
	default = XDisplayName (&zero)				' get default display name
	##LOCKOUT = lockout
	##WHOMASK = whomask
	default$ = CSTRING$ (default)					' make it a valid native string
	DIM display$[1]
	display$[1] = default$
END SUB
'
END FUNCTION
'
'
' ###############################
' #####  DispatchEvents ()  #####
' ###############################
'
' DispatchEvents (sync, wait)
'
' sync - TRUE means send XSync
' wait - TRUE means wait for up to 200msec for event
'
FUNCTION  DispatchEvents (sync, wait)
	SHARED  FUNCADDR  ehelp[] (ANY)
	SHARED  FUNCADDR  event[] (ANY)
	SHARED  DISPLAY  display[]
	SHARED  maxConnect
	SHARED  connect[]
	SHARED  consoleUpdateRequest
	SHARED  XSyncTime
	SHARED  consoleUpdateTime
	AUTOX  conn[]
	AUTOX  UTIMEVAL  delay
	AUTOX  XAnyEvent  event
'
	XxxGetRbpRsp (@rbp, @rsp)
	retAddr = XLONGAT(rbp + 8)
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"DispatchEvents()lockout", lockout) : lockout = 0
	lockout = 0
'
	IF ##INEXIT THEN RETURN								                 ' avoid trouble
	IF (##SOFTBREAK && ##WHOMASK) THEN RETURN              ' break out first
'
	sdisplay = display[1].sdisplay				' default display
'
	IFZ sdisplay THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "DispatchEvents() : no display exists"
		RETURN ($$TRUE)
	END IF
'
' Check for events pending on entry
'
	DO
		##WHOMASK = 0
		##LOCKOUT = 100148
		pending = XPending (sdisplay)
		IF pending THEN
			event.type = $$TRUE													' mark event as invalid
			XNextEvent (sdisplay, &event)
		END IF
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IFZ pending THEN EXIT DO
		IF (event.type = $$TRUE) THEN EXIT DO				' no event received : signal broke out of XNextEvent()
		IF (event.type > $$LastEvent) THEN DO LOOP	' bad event type
		error = @event[event.type] (@event)					' call event function
'		IF ##XBDV THEN @ehelp [event.type] (@event)	' display debug help
	LOOP
'
	IF sync THEN
		##WHOMASK = 0
		##LOCKOUT = 100149
		XSync (sdisplay, $$FALSE)
		##LOCKOUT = lockout
		##WHOMASK = whomask
		XstGetSystemTime (@XSyncTime)
	END IF
'
	IF wait THEN
		delay.tv_sec = 0										' 0 seconds +
		delay.tv_usec = 200000							' 200ms = 200,000us delay
		u = maxConnect >> 5
		uc = UBOUND (conn[])
		uct = UBOUND (connect[])
		IF (uc != u) THEN
			uc = u
			##WHOMASK = 0
			DIM conn[u]
			##WHOMASK = whomask
		END IF
		FOR nn = 0 TO u
			conn[nn] = connect[nn]
		NEXT nn
		xb_seterrno(0)
		##WHOMASK = 0
		##LOCKOUT = 100150
		ready = select (maxConnect+1, &conn[], 0, &conn[], &delay)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
' Check for events pending after sync/wait
'
	DO
		##WHOMASK = 0
		##LOCKOUT = 100151
		pending = XPending (sdisplay)
		IF pending THEN
			event.type = $$TRUE													' mark event as invalid
			XNextEvent (sdisplay, &event)
		END IF
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IFZ pending THEN EXIT DO
		IF (event.type = $$TRUE) THEN EXIT DO				' no event received : signal broke out of XNextEvent()
		IF (event.type > $$LastEvent) THEN DO LOOP	' bad event type
		error = @event[event.type] (@event)					' call event function
'		IF ##XBDV THEN @ehelp [event.type] (@event)	' display debug help
	LOOP
'
' If text has been sent to the console within the
' last 200 millisecond update (redraw) the console
'
	IF consoleUpdateRequest THEN
		IF ##CONGRID THEN
			XstGetSystemTime (@nowTime)
			IF ((nowTime - consoleUpdateTime) >= 200) THEN
				XgrAddMessage (##CONGRID, #Update, 0, 0, 0, 0, 0, 0)
				consoleUpdateTime = nowTime
			END IF
		END IF
	END IF
	RETURN
'
END FUNCTION
'
'
' ##################################
' #####  EmptyHoldingQueue ()  #####
' ##################################
'
' Functions that alter the message queues, set the inQueue flag word before making changes.
' If an asynchronous interrupt such as a timer alarm tries to add a message at that same instance,
' XgrAddMessage will put it in the holding queue and increment inHold so that the message queue will not be corrupted.
' When the changes are finished, the inQueue flag is cleared and checks inHold. If inHold is non-zero,
' it calls EmptyHoldingQueue() to transfer the message from the holding queue to the message queue.
'
FUNCTION  EmptyHoldingQueue ()
	SHARED MESSAGE mess[]
	SHARED inHold
	SHARED inQueue
	SHARED uuuuu
'
'	PRINT "EmptyHoldingQueue()", inHold
'
	GOSUB GetUnique											' unique = a unique value
	IF inHold THEN											' something in holding queue
		IFZ inQueue THEN									' not updating queue variables
			FOR m = 0 TO UBOUND (mess[])		' check all messages
				mess = mess[m].message				' check message
				IF (mess > 0) THEN						' not being processed
					mess[m].message = -unique		' mark as being processed
					check = mess[m].message			' sync check - still in sync?
					IF (check = -unique) THEN		' sync okay - add to queue
						DEC inHold								' one less in holding queue
						wg = mess[m].wingrid
						mm = mess
						a0 = mess[m].v0
						a1 = mess[m].v1
						a2 = mess[m].v2
						a3 = mess[m].v3
						a4 = mess[m].r0
						a5 = mess[m].r1
						mess[m].message = 0				' now available
						IFZ ##BLOWBACK THEN XgrAddMessage (wg, mm, a0, a1, a2, a3, a4, a5)
					END IF
				END IF
			NEXT m
		END IF
	END IF
'
RETURN
'
'
' *****  GetUnique  *****
'
SUB GetUnique
	DO
		u = uuuuu
		INC uuuuu
		unique = uuuuu - 1
	LOOP UNTIL (u = unique)										' unique is a unique value
	IF (uuuuu >= 0x7FFFFF00) THEN uuuuu = 1		' recycle unique counter
END SUB

END FUNCTION
'
'
' #####################
' #####  Font ()  #####
' #####################
'
' o  font      = native font #
' i  display   = native display #
' i  ufont$    = font name string = empty string for default font
'
FUNCTION  Font (font, command, display, sfont, addrFont, size, weight, italic, angle, ufont$)
	SHARED	DISPLAY  display[]
	SHARED  FONT  font[]
	SHARED  ufont$[]
	SHARED	font$[]
	STATIC	fixed$[]
	STATIC	sdefaultFont
	STATIC  sdefaultAddrFont
	XFontStruct  fontStruct
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"Font()lockout", lockout) : lockout = 0
'
	IFZ fixed$[] THEN GOSUB Initialize
'
	font = 0
	angle = 0
	IF InvalidDisplay (display) THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "Font() : error : display argument invalid"; display
		RETURN ($$TRUE)
	END IF
'
	sdisplay = display[display].sdisplay
'
	IFZ sdefaultFont THEN
		##WHOMASK = $$FALSE
		addrFont = $$FALSE
		hold$ = ufont$
		file$ = "$XBDIR" + $$PathSlash$ + "templates" + $$PathSlash$ + "font.xxx"
		XstLoadStringArray (@file$, @def$[])
		IF def$[] THEN
			u = UBOUND (def$[])
			FOR i = 0 TO u
				ufont$ = TRIM$(def$[i])
				IF ufont$ THEN
					IF (ufont${0} != ''') THEN
						addrFont = 0
						GOSUB Create
						IF addrFont THEN EXIT FOR
					END IF
				END IF
			NEXT i
			DIM def$[]
		END IF
		IF addrFont THEN
			sdefaultAddrFont = addrFont
			sdefaultFont = sfont
		ELSE
			upper = UBOUND (fixed$[])
			FOR i = 0 TO upper
				ufont$ = fixed$[i]
				addrFont = 0
				GOSUB Create
				IF addrFont THEN EXIT FOR
			NEXT i
		END IF
		##WHOMASK = whomask
		sdefaultAddrFont = addrFont
		sdefaultFont = sfont
		ufont$ = hold$
	END IF
'
	SELECT CASE command
		CASE $$Create			: GOSUB Create
		CASE $$Destroy		: GOSUB Destroy
		CASE $$DestroyAll	: GOSUB DestroyAll
		CASE ELSE					: PRINT "Font() : unknown command"
	END SELECT
	##WHOMASK = whomask
	##LOCKOUT = lockout
	RETURN (return)
'
'
' *****  Create  *****
'
SUB Create
'
'	XstLog ("Font().Create.A : " + ufont$ + " " + STRING$(font) + " " + STRING$(size) + " " + STRING$(weight) + " " + STRING$(italic) + " " + STRING$(angle) + " " + HEX$(sfont,8) + " " + HEX$(addrFont,8))
'
	font = 0
	IFZ ufont$ THEN
		IF sdefaultFont THEN
			sfont = sdefaultFont
			addrFont = sdefaultAddrFont				' default font
			return = $$FALSE
			EXIT SUB
		END IF
	END IF
'
'	XstLog ("Font().Create.B : " + ufont$ + " " + STRING$(font) + " " + STRING$(size) + " " + STRING$(weight) + " " + STRING$(italic) + " " + STRING$(angle) + " " + HEX$(sfont,8) + " " + HEX$(addrFont,8))
'
	FOR f = 0 TO UBOUND (ufont$[])
		IF (ufont$ = ufont$[f]) THEN
			font = f
			sfont = font[font].sfont
			addrFont = font[font].addrFont		' font already created
			return = $$FALSE
			EXIT SUB
		END IF
	NEXT f
'
'	XstLog ("Font().Create.C : " + ufont$ + " " + STRING$(font) + " " + STRING$(size) + " " + STRING$(weight) + " " + STRING$(italic) + " " + STRING$(angle) + " " + HEX$(sfont,8) + " " + HEX$(addrFont,8))
'
	addrFont = 0
	##WHOMASK = 0
	##LOCKOUT = 100152
	addrFont = XLoadQueryFont (sdisplay, &ufont$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	PRINT "Font(123) ", addrFont, ufont$
'	XstLog ("Font().Create.D : " + ufont$ + " " + STRING$(font) + " " + STRING$(size) + " " + STRING$(weight) + " " + STRING$(italic) + " " + STRING$(angle) + " " + HEX$(sfont,8) + " " + HEX$(addrFont,8))
'
	IFZ addrFont THEN
		##ERROR = ($$ErrorObjectFont << 8) OR $$ErrorNatureNonexistent
'		IF ##XBDV THEN PRINT "Font() : Create : XLoadQueryFont() failed : ", ufont$
		##WHOMASK = whomask
		return = $$TRUE
		EXIT SUB
	END IF
'
	upper = UBOUND (font[])
	FOR font = 0 TO upper
		IFZ font[font].count THEN EXIT FOR
	NEXT font
'
	IF (font > upper) THEN
		upper = upper + 8
		##WHOMASK = 0
		REDIM font[upper]
		REDIM font$[upper]
		REDIM ufont$[upper]
		##WHOMASK = whomask
	END IF
'
	##WHOMASK = 0
	font$[font] = ""											' font name
	ufont$[font] = ufont$									' unix font name
	##WHOMASK = whomask
'
	XLONGAT (&&fontStruct) = addrFont
'
	sfont = fontStruct.fid
	ascent = fontStruct.ascent
	descent = fontStruct.descent
'
	minWidth = fontStruct.minBoundsWidth
	minAscent = fontStruct.minBoundsAscent
	minDescent = fontStruct.minBoundsDescent
	maxWidth = fontStruct.maxBoundsWidth
	maxAscent = fontStruct.maxBoundsAscent
	maxDescent = fontStruct.maxBoundsDescent
'
'	PRINT "Font() : sfont, ascent, descent = ";
'	PRINT "Font() :"; HEX$(sfont), ascent, descent
'	PRINT "Font() : min width,ascent,descent"
'	PRINT "Font() :";  minWidth, minAscent, minDescent
'	PRINT "Font() : max width,ascent,descent"
'	PRINT "Font() :";  maxWidth, maxAscent, maxDescent
'
	font[font].font = font
	font[font].sfont = sfont
	font[font].addrFont = addrFont
	font[font].size = size
	font[font].weight = weight
	font[font].italic = italic
	font[font].angle = angle
	font[font].count = font[font].count + 1
	font[font].width = maxWidth
	font[font].height = ascent + descent
	font[font].ascent = ascent
	font[font].descent = descent
'	XstLog ("Font().Create.Z : " + ufont$ + " " + STRING$(font) + " " + STRING$(size) + " " + STRING$(weight) + " " + STRING$(italic) + " " + STRING$(angle) + " " + HEX$(sfont,8) + " " + HEX$(addrFont,8))
	return = $$FALSE
END SUB
'
'
' *****  Destroy  *****
'
SUB Destroy
	IF ##XBDV THEN PRINT "Font() : Destroy : unimplemented"
END SUB
'
'
' *****  DestroyAll  *****
'
SUB DestroyAll
	IF ##XBDV THEN PRINT "Font() : DestroyAll : unimplemented"
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	##WHOMASK = 0
	DIM font[7]
	DIM font$[7]
	DIM ufont$[7]
	DIM fixed$[7]
	fixed$[0] = "6x13"
	fixed$[1] = "7x13"
	fixed$[2] = "8x13"
	fixed$[3] = "9x15"
	fixed$[4] = "6x13bold"
	fixed$[5] = "7x13bold"
	fixed$[6] = "8x13bold"
	fixed$[7] = "9x15bold"
	##WHOMASK = whomask
END SUB
'
END FUNCTION
'
'
' ###################################
' #####  GetNewWindowNumber ()  #####
' ###################################
'
FUNCTION  GetNewWindowNumber (@wingrid)
	SHARED  WINDOW  window[]
	SHARED  window$[]
	SHARED  charMap[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"GetNewWindowNumber()lockout", lockout) : lockout = 0
'
	IFZ window[] THEN
		##WHOMASK = 0
		IF ##STANDALONE THEN
			DIM window[63]
			DIM window$[63]
			DIM charMap[63,]
		ELSE
			DIM window[575]
			DIM window$[575]
			DIM charMap[575,]
		END IF
		##WHOMASK = whomask
	END IF
'
	upper = UBOUND (window[])
'
	FOR wingrid = 1 TO upper
		IFZ window[wingrid].window THEN
			IFZ window[wingrid].swindow THEN EXIT FOR
		END IF
	NEXT wingrid
'
	IF (wingrid > upper) THEN
		##WHOMASK = 0
		upper = upper + 64
		REDIM window[upper]
		REDIM window$[upper]
		REDIM charMap[upper,]
		##WHOMASK = whomask
	END IF
'
END FUNCTION
'
'
' ################################
' #####  GraphicsContext ()  #####
' ################################
'
' o  gc        = system gc = graphics context (return value)
' i  command   = $$Create, $$Destroy
' i  sdisplay  = system display #
' i  swindow   = system window #
' i  sfont     = system font #
'
FUNCTION  GraphicsContext (gc, command, sdisplay, screen, swindow, sfont)
	XGCValues  gcvalues
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"GraphicsContext()lockout", lockout) : lockout = 0
'
	SELECT CASE command
		CASE $$Create		: GOSUB Create
		CASE ELSE				: IF ##XBDV THEN PRINT "GraphicsContext() : bad command"
	END SELECT
	RETURN (return)
'
'
' *****  Create  *****
'
SUB Create
	##WHOMASK = 0
	##LOCKOUT = 100153
	sblack = XBlackPixel (sdisplay, screen)
	swhite = XWhitePixel (sdisplay, screen)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
' The default of lineWidth = 0 screws up on SCO UNIX
' when the line goes out of grid/window.  ! STUPID !
' But when lineWidth = 1 the lines are ragged, have
' pixel gaps here and there, look generally rotten,
' and draw slower than hell.  !!!! Yell at SCO !!!!
'
	valuemask = 0
'	gcvalues.lineWidth = 1
	gcvalues.background = sblack
	gcvalues.foreground = swhite
	IF sfont THEN
		gcvalues.font = sfont
		valuemask = valuemask OR $$GCFont
	END IF
'	valuemask = valuemask OR $$GCLineWidth
	valuemask = valuemask OR $$GCBackground OR $$GCForeground
'
	##WHOMASK = 0
	##LOCKOUT = 100154
	gc = XCreateGC (sdisplay, swindow, valuemask, &gcvalues)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ##############################
' #####  InvalidCursor ()  #####
' ##############################
'
FUNCTION  InvalidCursor (cursor)
	SHARED  cursor$[]
	SHARED  cursor[]
'
	upper = UBOUND (cursor[])
	IF (cursor < 0) THEN RETURN ($$TRUE)					' bad cursor #
	IF (cursor > upper) THEN RETURN ($$TRUE)			' bad cursor #
	IF cursor THEN
		IFZ cursor$[cursor] THEN RETURN ($$TRUE)		' not registered
		IFZ cursor[cursor] THEN RETURN ($$TRUE)			' not registered
	END IF
END FUNCTION
'
'
' ###############################
' #####  InvalidDisplay ()  #####
' ###############################
'
FUNCTION  InvalidDisplay (display)
	SHARED  DISPLAY  display[]
'
	upper = UBOUND (display[])
'
	IF (display <= 0) THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureInvalidNumber
		IF ##XBDV THEN PRINT "InvalidDisplay() : (display <= 0)"
		RETURN ($$TRUE)
	END IF
'
	IF (display > upper) THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureInvalidNumber
		IF ##XBDV THEN PRINT "InvalidDisplay() : (display > upper)"
		RETURN ($$TRUE)
	END IF
'
	IFZ (display[display].status AND $$Open) THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureInvalidNumber
		IF ##XBDV THEN PRINT "InvalidDisplay() : (display not open)"
		RETURN ($$TRUE)
	END IF
END FUNCTION
'
'
' ############################
' #####  InvalidFont ()  #####
' ############################
'
FUNCTION  InvalidFont (font)
	SHARED  FONT  font[]
'
	upper = UBOUND (font[])
	IF ((font < 0) OR (font > upper)) THEN RETURN ($$TRUE)	' invalid font #
	IFZ (font[font].sfont) THEN RETURN ($$TRUE)							' not open
END FUNCTION
'
'
' ############################
' #####  InvalidGrid ()  #####
' ############################
'
FUNCTION  InvalidGrid (grid)
	SHARED  WINDOW  window[]
	STATIC	gridPrev
'
	IF (grid == gridPrev) THEN RETURN
'
	upper = UBOUND (window[])
	IF ((grid <= 0) OR (grid > upper)) THEN                            ' invalid grid #
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureLimitExceeded
		RETURN ($$TRUE)
	END IF
	IFZ window[grid].swindow THEN                                      ' not open
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		RETURN ($$TRUE)
	END IF
	IFZ window[grid].window THEN                                       ' not open
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		RETURN ($$TRUE)
	END IF
	IF (window[grid].kind != $$KindGrid) THEN                          ' not a grid kind
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureInvalidKind
		RETURN ($$TRUE)
	END IF
'
	gridPrev = grid
'
END FUNCTION
'
'
' ################################
' #####  InvalidGridType ()  #####
' ################################
'
FUNCTION  InvalidGridType (gridType)
	SHARED  gridType$[]
'
	upper = UBOUND (gridType$[])
	IF (gridType < 0) THEN RETURN ($$TRUE)
	IF (gridType > upper) THEN RETURN ($$TRUE)
	IFZ (gridType$[gridType]) THEN RETURN ($$TRUE)
END FUNCTION
'
'
' ############################
' #####  InvalidIcon ()  #####
' ############################
'
FUNCTION  InvalidIcon (icon)
	SHARED  sicon[]
	SHARED  icon$[]
	SHARED  icon[]
'
	upper = UBOUND (icon[])
	IF (icon < 0) THEN RETURN ($$TRUE)					' bad icon #
	IF (icon > upper) THEN RETURN ($$TRUE)			' bad icon #
	IF icon THEN
		IFZ sicon[icon] THEN RETURN ($$TRUE)			' not registered
		IFZ icon$[icon] THEN RETURN ($$TRUE)			' not registered
		IFZ icon[icon] THEN RETURN ($$TRUE)				' not registered
	END IF
END FUNCTION
'
'
' ##############################
' #####  InvalidWindow ()  #####
' ##############################
'
FUNCTION  InvalidWindow (window)
	SHARED  WINDOW  window[]
'
	upper = UBOUND (window[])
	IF ((window <= 0) OR (window > upper)) THEN                        ' invalid window/grid #
		error = ($$ErrorObjectWindow << 8) OR $$ErrorNatureLimitExceeded
		RETURN ($$TRUE)
	END IF
	IFZ window[window].swindow THEN                                    ' not open
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		RETURN ($$TRUE)
	END IF
	IFZ window[window].window THEN                                     ' not open
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		RETURN ($$TRUE)
	END IF
	IF (window[window].kind != $$KindWindow) THEN                      ' not a window kind
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureInvalidKind
		RETURN ($$TRUE)
	END IF
'
END FUNCTION
'
'
' ###############################
' #####  InvalidWinGrid ()  #####
' ###############################
'
' invalid = InvalidWinGrid (wingrid)
'
' invalid is returned TRUE if wingrid is
' neither a valid window nor a valid grid number
'
FUNCTION  InvalidWinGrid (wingrid)
	SHARED  WINDOW  window[]
'
	upper = UBOUND (window[])
	IF ((wingrid <= 0) OR (wingrid > upper)) THEN                       ' invalid window/grid #
		error = ($$ErrorObjectGrid << 8) OR $$ErrorNatureLimitExceeded
		RETURN ($$TRUE)
	END IF
	IFZ window[wingrid].window THEN                                     ' not open
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		RETURN ($$TRUE)
	END IF
'
END FUNCTION
'
'
' ################################
' #####  KeyboardMessage ()  #####
' ################################
'
FUNCTION  KeyboardMessage (message)
	SHARED  message$[]
'
	upper = UBOUND (message$[])
	IF (message <= 0) THEN
		##ERROR = ($$ErrorObjectMessage << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "KeyboardMessage() : invalid message # : message # < 0"
		RETURN ($$FALSE)		' DEFINITELY NOT A KEYBOARD MESSAGE
	END IF
'
	IF (message > upper) THEN
		##ERROR = ($$ErrorObjectMessage << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "KeyboardMessage() : invalid message # : message > upper"
		RETURN ($$FALSE)		' DEFINITELY NOT A KEYBOARD MESSAGE
	END IF
'
	SELECT CASE message
		CASE #WindowKeyDown	: RETURN ($$TRUE)
		CASE #WindowKeyUp		: RETURN ($$TRUE)
		CASE #KeyDown				: RETURN ($$TRUE)
		CASE #KeyUp					: RETURN ($$TRUE)
	END SELECT
END FUNCTION
'
'
' ####################
' #####  Log ()  #####
' ####################
'
FUNCTION  Log (message$, newline)
'
	#log = OPEN ("log.txt", $$WR)
'
	IF #log THEN
		end = LOF (#log)
		SEEK (#log, end)
		IFZ newline THEN
			PRINT [#log], message$
		ELSE
			PRINT [#log], "\n" + message$
		END IF
		CLOSE (#log)
	END IF
'
	IF #print THEN
		IFZ newline THEN
			PRINT message$
		ELSE
			PRINT "\n" + message$
		END IF
	END IF
END FUNCTION
'
'
' #############################
' #####  MouseMessage ()  #####
' #############################
'
FUNCTION  MouseMessage (message)
	SHARED  message$[]
'
	upper = UBOUND (message$[])
	IF (message <= 0) THEN
		##ERROR = ($$ErrorObjectMessage << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "MouseMessage() : invalid message # : message # < 0"
		RETURN ($$FALSE)		' DEFINITELY NOT A MOUSE MESSAGE
	END IF
'
	IF (message > upper) THEN
		##ERROR = ($$ErrorObjectMessage << 8) OR $$ErrorNatureInvalid
		IF ##XBDV THEN PRINT "MouseMessage() : invalid message # : message > upper", message, upper
		RETURN ($$FALSE)		' DEFINITELY NOT A MOUSE MESSAGE
	END IF
'
	SELECT CASE message
		CASE #WindowMouseDown		: RETURN ($$TRUE)		' mouse message
		CASE #WindowMouseDrag		: RETURN ($$TRUE)		' mouse message
		CASE #WindowMouseEnter	: RETURN ($$TRUE)		' mouse message
		CASE #WindowMouseMove		: RETURN ($$TRUE)		' mouse message
		CASE #WindowMouseUp			: RETURN ($$TRUE)		' mouse message
		CASE #MouseDown					: RETURN ($$TRUE)		' mouse message
		CASE #MouseDrag					: RETURN ($$TRUE)		' mouse message
		CASE #MouseEnter				: RETURN ($$TRUE)		' mouse message
		CASE #MouseMove					: RETURN ($$TRUE)		' mouse message
		CASE #MouseUp						: RETURN ($$TRUE)		' mouse message
	END SELECT
END FUNCTION
'
'
' ############################
' #####  NormalAngle ()  #####
' ############################
'
FUNCTION  NormalAngle (angle#)
'
	IFZ angle# THEN RETURN
'	SELECT CASE angle#
'		CASE $$NINF	: angle# = 0# : RETURN ($$TRUE)
'		CASE $$PINF	: angle# = 0# : RETURN ($$TRUE)
'		CASE $$NNAN	: angle# = 0# : RETURN ($$TRUE)
'		CASE $$PNAN	: angle# = 0# : RETURN ($$TRUE)
'	END SELECT
'
	IF ((angle# >= 0#) AND (angle# <= $$TWOPI)) THEN RETURN
'
	a# = ABS (angle#)
	IF (a# > $$TWOPI) THEN
		rev# = a# / $$TWOPI				' angle in units of $$TWOPI revolutions
		irev# = INT (rev#)				' integer # of $$TWOPI revolutions
		a# = rev# - irev#					' 0# <= a# < $$TWOPI
	END IF
'
	IF (angle# < 0#) THEN				' if original angle was negative
		a# = $$TWOPI - a#					' 0# <= a# < $$TWOPI
	END IF
'
	angle# = a#
END FUNCTION
'
'
' #####################################
' #####  NormalAnglePlusMinus ()  #####
' #####################################
'
FUNCTION  NormalAnglePlusMinus (angle#)
'
	IFZ angle# THEN RETURN
'	SELECT CASE angle#
'		CASE $$NINF	: angle# = 0# : RETURN ($$TRUE)
'		CASE $$PINF	: angle# = 0# : RETURN ($$TRUE)
'		CASE $$NNAN	: angle# = 0# : RETURN ($$TRUE)
'		CASE $$PNAN	: angle# = 0# : RETURN ($$TRUE)
'	END SELECT
'
	IF ((angle# >= -$$TWOPI) AND (angle# <= $$TWOPI)) THEN RETURN
'
	IF (angle < 0#) THEN a# = -angle# ELSE a# = angle#
'
	IF (a# > $$TWOPI) THEN
		rev# = a# / $$TWOPI				' angle in units of $$TWOPI revolutions
		irev# = INT (rev#)				' integer # of $$TWOPI revolutions
		a# = rev# - irev#					' 0# <= a# < $$TWOPI
	END IF
'
	IF (angle# < 0#) THEN angle# = -a# ELSE angle# = a#
END FUNCTION
'
'
' ##################################
' #####  RedrawGridAndKids ()  #####
' ##################################
'
' RedrawGridAndKids (grid, action, xWin, yWin, width, height)
'
' action = TRUE  : send #RedrawGrid
' action = FALSE : add  #RedrawGrid to message queue
'
FUNCTION  RedrawGridAndKids (grid, action, xWin, yWin, width, height)
	SHARED  WINDOW  window[]
'
	IF InvalidGrid (grid) THEN RETURN ($$TRUE)
'
	window = window[grid].top
	gridType = window[grid].type
	IFZ window[grid].state THEN RETURN ($$FALSE)
	IF (gridType = $$GridTypeImage) THEN RETURN ($$FALSE)
	IF InvalidWinGrid (window) THEN RETURN ($$TRUE)
'
	x1Win = xWin
	y1Win = yWin
	x2Win = xWin + width - 1
	y2Win = yWin + height - 1
	XgrGetGridBoxWindow (grid, @gx1, @gy1, @gx2, @gy2)
	gdx = gx2 - gx1
	gdy = gy2 - gy1
'
	exposed = $$TRUE
	IF ((width <= 0) OR (height <= 0)) THEN
		x1 = 0
		y1 = 0
		x2 = 0
		y2 = 0
		ww = 0
		hh = 0
	ELSE
		IF (x1Win > gx2) THEN exposed = $$FALSE
		IF (y1Win > gy2) THEN exposed = $$FALSE
		IF (x2Win < gx1) THEN exposed = $$FALSE
		IF (y2Win < gy1) THEN exposed = $$FALSE
		x1 = x1Win - gx1
		y1 = y1Win - gy1
		x2 = x2Win - gx1
		y2 = y2Win - gy1
		IF (x1 < 0) THEN x1 = 0
		IF (y1 < 0) THEN y1 = 0
		IF (x2 > gdx) THEN x2 = gdx
		IF (y2 > gdy) THEN y2 = gdy
		ww = x2 - x1 + 1
		hh = y2 - y1 + 1
	END IF
'
	IFZ exposed THEN RETURN ($$FALSE)
'
' send or queue a #RedrawGrid to the grid itself
'
	buffer = window[grid].buffer
	IF buffer THEN
		IF InvalidGrid (buffer) THEN THEN buffer = 0
	END IF
'
' if grid is buffered, refresh it and skip #RedrawGrid
'
	IF buffer THEN
'		PRINT "RedrawWindowAndKids() : call XgrRefreshGrid() : "; grid, buffer
		XgrRefreshGrid (grid)
	ELSE
		IFZ action THEN
			XgrAddMessage (grid, #RedrawGrid, x1, y1, ww, hh, 0, grid)
		ELSE
			XgrSendMessage (grid, #RedrawGrid, x1, y1, ww, hh, 0, grid)
		END IF
	END IF
'
' send or queue #RedrawGrid to its kids, and their kids, etc...
'
	FOR gg = 1 TO UBOUND (window[])
		g = window[gg].window
		IF g THEN
			IF (g = gg) THEN
				IF window[g].state THEN
					IF (grid = window[g].parent) THEN
						RedrawGridAndKids (g, action, xWin, yWin, width, height)
					END IF
				END IF
			END IF
		END IF
	NEXT gg
END FUNCTION
'
'
' ##############################
' #####  RemoveMessage ()  #####
' ##############################
'
' this internal function expects 0 or 1 in window to designate sys/user queue
'
FUNCTION  RemoveMessage (wingrid, message, v0, v1, v2, v3, r0, r1)
	SHARED  MESSAGE  message[]
	SHARED  userCEO
	SHARED  userCount
	SHARED  sysCEO
	SHARED  sysCount
	SHARED  userOut
	SHARED  sysOut
	SHARED  userIn
	SHARED  sysIn
	SHARED  inHold
	SHARED  inQueue
	SHARED  huh
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"RemoveMessage()lockout", lockout) : lockout = 0
'
	queue = wingrid
	IF queue THEN queue = 1
'
	IF inQueue THEN PRINT "RemoveMessage() : inQueue"
	inQueue = $$TRUE
	GOSUB UpdateVariables
'
	IF huh THEN
		kkk$ = STRING$(count)
		IF queue THEN XxxXstLog ("(*r"+kkk$) ELSE XxxXstLog ("(*R"+kkk$)
	END IF
'
	IFZ count THEN							' error : no messages
		wingrid = 0
		message = 0
		v0 = 0
		v1 = 0
		v2 = 0
		v3 = 0
		r0 = 0
		r1 = 0
		inQueue = $$FALSE
		IF inHold THEN EmptyHoldingQueue ()
		RETURN ($$TRUE)
	END IF
	upper = UBOUND (message[queue,])
'
' get message arguments from queue
'
	wingrid = message[queue,out].wingrid
	message = message[queue,out].message
	v0 = message[queue,out].v0
	v1 = message[queue,out].v1
	v2 = message[queue,out].v2
	v3 = message[queue,out].v3
	r0 = message[queue,out].r0
	r1 = message[queue,out].r1
'
' remove message from queue
'
	IFZ queue THEN
		INC sysOut
		DEC sysCount
		IF (sysOut > upper) THEN sysOut = 0					' wrap around
		IF huh THEN
			kkk$ = STRING$(sysCount)
			XxxXstLog ("-"+kkk$+"S*)")
		END IF
	ELSE
		INC userOut
		DEC userCount
		IF (userOut > upper) THEN userOut = 0				' wrap around
		IF huh THEN
			kkk$ = STRING$(userCount)
			XxxXstLog ("-"+kkk$+"U*)")
		END IF
	END IF
'
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
'
'	XgrMessageNumberToName (message, @message$)
'	PRINT " R["; wingrid;; message$; "]"
	RETURN ($$FALSE)
'
'
' *****  UpdateVariables  *****
'
SUB UpdateVariables
	IF queue THEN
		ceo = userCEO
		count = userCount
		out = userOut
		in = userIn
	ELSE
		ceo = sysCEO
		count = sysCount
		out = sysOut
		in = sysIn
	END IF
END SUB
END FUNCTION
'
'
' ################################
' #####  SetBackgroundColor  #####
' ################################
'
FUNCTION  SetBackgroundColor (window, color)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"SetBackgroundColor()lockout", lockout) : lockout = 0
'
	gc = window[window].gc
	sdisplay = window[window].sdisplay
	sbackground = window[window].sbackground
	sbackgroundDefault = window[window].sbackgroundDefault
'
	IF (color = -1) THEN
		scolor = window[window].sbackgroundDefault
	ELSE
		ConvertColorToSystemColor (window, color, @scolor)
	END IF
'
'	PRINT "SetBackgroundColor() : "; window, color, scolor, sbackground, sbackgroundDefault
'
	IF (scolor = -1) THEN RETURN
	IF (scolor = sbackground) THEN RETURN
	window[window].sbackground = scolor
'
	##WHOMASK = 0
	##LOCKOUT = 100155
	XSetBackground (sdisplay, gc, scolor)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ##############################
' #####  SetBackgroundRGB  #####
' ##############################
'
FUNCTION  SetBackgroundRGB (window, red, green, blue)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"SetBackgroundRGB()lockout", lockout) : lockout = 0
'
	gc = window[window].gc
	sdisplay = window[window].sdisplay
	sbackground = window[window].sbackground
	sbackgroundDefault = window[window].sbackgroundDefault
	ConvertRGBToSystemColor (window, red, green, blue, @scolor)
'
'	PRINT "SetBackgroundRGB() : "; window, red, green, blue, scolor, sbackground, sbackgroundDefault
'
	IF (scolor = -1) THEN RETURN
	IF (scolor = sbackground) THEN RETURN
	window[window].sbackground = scolor
'
	##WHOMASK = 0
	##LOCKOUT = 100156
	XSetBackground (sdisplay, gc, scolor)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' #############################
' #####  SetDrawingColor  #####
' #############################
'
FUNCTION  SetDrawingColor (window, color)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"SetDrawingColor()lockout", lockout) : lockout = 0
'
	gc = window[window].gc
	sdisplay = window[window].sdisplay
	sforeground = window[window].sforeground
	sforegroundDefault = window[window].sforegroundDefault
'
	IF (color = -1) THEN
		scolor = window[window].sforegroundDefault
	ELSE
		ConvertColorToSystemColor (window, color, @scolor)
	END IF
'
'	PRINT "SetDrawingColor() : "; window, color, scolor, sforeground, sforegroundDefault
'
	IF (scolor = -1) THEN RETURN
	IF (scolor = sforeground) THEN RETURN
	window[window].sforeground = scolor
'
	##WHOMASK = 0
	##LOCKOUT = 100157
	XSetForeground (sdisplay, gc, scolor)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###########################
' #####  SetDrawingRGB  #####
' ###########################
'
FUNCTION  SetDrawingRGB (window, red, green, blue)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"SetDrawingRGB()lockout", lockout) : lockout = 0
'
	gc = window[window].gc
	sdisplay = window[window].sdisplay
	sforeground = window[window].sforeground
	sforegroundDefault = window[window].sforegroundDefault
	ConvertRGBToSystemColor (window, red, green, blue, @scolor)
'
'	PRINT "SetDrawingRGB() : "; window, red, green blue, scolor, sforeground, sforegroundDefault
'
	IF (scolor = -1) THEN RETURN
	IF (scolor = sforeground) THEN RETURN
	window[window].sforeground = scolor
'
	##WHOMASK = 0
	##LOCKOUT = 100158
	XSetForeground (sdisplay, gc, scolor)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ###############################
' #####  SetSwindowXref ()  #####
' ###############################
'
' used by XgrSystemWindowToWindow()
'
FUNCTION  SetSwindowXref (swindow, window)
	SHARED  swindow[]
'
	IFZ swindow[] THEN
		whomask = ##WHOMASK
		##WHOMASK = 0
		DIM swindow[1279]
		##WHOMASK = whomask
	END IF
'
	swindex = swindow AND 0x1FFFFF
	uindex = UBOUND (swindow[])
	IF (swindex > uindex) THEN
		uindex = swindex OR 0x7F
		whomask = ##WHOMASK
		##WHOMASK = 0
		REDIM swindow[uindex]
		##WHOMASK = whomask
	END IF
'
	previousWindow = swindow[swindex]
	swindow[swindex] = window
	IF (previousWindow) THEN
		PRINT "SetSwindowXref():Error", HEXX$(swindow), HEXX$(window), HEXX$(previousWindow)
	END IF
'
END FUNCTION
'
'
' ###############################################
' #####  SystemButtonStateToButtonState ()  #####
' ###############################################
'
'	SystemButtonStateToButtonState (event.button, event.state, event.time, @state)
'
' 0-3 : button number that caused event
' 4-6 : # of clicks (1 to 4)								handled by calling function
'   7 : window has mouse focus (always 1)
'  16 : ShiftKey state       : 1 = down
'  17 : ControlKey state     : 1 = down
'  18 : AltKey state         : 1 = down
'  24 : mouse button 1 state : 1 = down
'  25 : mouse button 2 state : 1 = down
'  26 : mouse button 3 state : 1 = down
'  27 : mouse button 4 state : 1 = down
'  28 : mouse button 5 state : 1 = down
'
FUNCTION  SystemButtonStateToButtonState (button, system, time, state)
'
	state = button AND 0x0007			' 0-3 : 0 = none : 1 = button1 : 2 = button2 : ...
	state = state OR 0x0080				'   7 : window has mouse focus
	IF (system AND $$ShiftMask)   THEN state = state OR $$MouseShiftKey    ' 16 : Shift
	IF (system AND $$ControlMask) THEN state = state OR $$MouseControlKey  ' 17 : Ctrl
	IF (system AND $$Mod1Mask)    THEN state = state OR $$MouseAltKey      ' 18 : Alt
	IF (system AND $$Mod2Mask)    THEN state = state OR $$MouseMod2Key     ' 19 : ?
	IF (system AND $$Mod3Mask)    THEN state = state OR $$MouseMod3Key     ' 20 : ?
	IF (system AND $$Mod4Mask)    THEN state = state OR $$MouseMod4Key     ' 21 : ?
	IF (system AND $$Mod5Mask)    THEN state = state OR $$MouseMod5Key     ' 22 : ?
	IF (system AND $$Button1Mask) THEN state = state OR $$MouseButton1     ' 24 : Left
	IF (system AND $$Button2Mask) THEN state = state OR $$MouseButton2     ' 25 : Middle
	IF (system AND $$Button3Mask) THEN state = state OR $$MouseButton3     ' 26 : Right
	IF (system AND $$Button4Mask) THEN state = state OR $$MouseButton4     ' 27 : Other
	IF (system AND $$Button5Mask) THEN state = state OR $$MouseButton5     ' 28 : Other
END FUNCTION
'
'
' #########################################
' #####  SystemKeyStateToKeyState ()  #####
' #########################################
'
'	SystemKeyStateToKeyState (#WindowKeyDown, keysym, sstate, event.time, @state)
'	SystemKeyStateToKeyState (#WindowKeyUp, keysym, sstate, event.time, @state)
'
' 00-15 : character code of some kind (see bits 20-22)
'    16 : ShiftKey state
'    17 : ControlKey state
'    18 : AltKey state
'    19 : reserved (right AltKey - bit 18 = 1 if either AltKey is down)
' 20-21 : 0 = 8-bit vkey : 1 = 8-bit ASCII char : 2 = 16-bit UNICODE char
'    22 : reserved (right ShiftKey - bit 16 = 1 if either ShiftKey is down)
'    23 : reserved (right ControlKey - bit 17 = 1 if either ControlKey is down)
' 24-31 : 8-bit vkey (virtual keycode)
'
FUNCTION  SystemKeyStateToKeyState (message, keysym, sstate, time, state)
	SHARED  UBYTE virtualKey00[]
	SHARED  UBYTE virtualKeyFF[]
	SHARED  UBYTE asciiKey00[]
	SHARED  UBYTE asciiKeyFF[]
	SHARED  UBYTE altChar[]
	SHARED	UBYTE	altCharFF[]
	STATIC  mod
'
	keygroup = (keysym >> 8) AND 0x00FF
	keytype = $$KeyTypeVirtualKey
	key = keysym AND 0x00FF
	ascii = $$FALSE
	state = 0
	vkey = 0
'
	SELECT CASE keygroup
		CASE 0x00	:	char = asciiKey00[key]
								vkey = virtualKey00[key]
								IF (sstate AND ($$AltMask OR $$RightAltMask)) THEN
									char = altChar[char]
								ELSE
									IF char THEN keytype = $$KeyTypeAscii
									IF (sstate AND $$ControlMask) THEN
										SELECT CASE TRUE
											CASE ((char >= 'A') AND (char <= 'Z'))		: char = char - 'A' + 1
											CASE ((char >= 'a') AND (char <= 'z'))		: char = char - 'a' + 1
											CASE ((char >= 0x5B) AND (char <= 0x5F))	: char = char - 'A' + 1
											CASE ((char >= 0x7B) AND (char <= 0x7E))	: char = char - 'a' + 1
										END SELECT
									END IF
								END IF
		CASE 0xFF	:	char = asciiKeyFF[key]
								vkey = virtualKeyFF[key]
'								PRINT "char,vkey,sstate", HEXX$(char), HEXX$(vkey), HEXX$(sstate)
								IF (sstate AND ($$AltMask OR $$RightAltMask)) THEN
									char = altCharFF[key]
									vkey = char										' to handle Alt+Keypadn
								ELSE
									IF char THEN keytype = $$KeyTypeAscii ELSE char = vkey
								END IF
		CASE ELSE	: char = keysym AND 0x0000FFFF		' unicode or disaster
								IF char = $$XK_ISO_Left_Tab THEN           'Shift+Tab
									vkey = $$KeyTab
									char = $$KeyTab
									keytype = $$KeyTypeAscii
								ELSE
									vkey = 0
									IF char THEN keytype = $$KeyTypeUnicode
								END IF
	END SELECT
'
'
'	IF (sstate AND $$AltMask) THEN state = state OR $$AltBit
'	IF (sstate AND $$ShiftMask) THEN state = state OR $$ShiftBit
'	IF (sstate AND $$ControlMask) THEN state = state OR $$ControlBit
'	IF (sstate AND $$RightAltMask) THEN state = state OR $$RightAltBit
'	IF (sstate AND $$RightShiftMask) THEN state = state OR $$RightShiftBit
'	IF (sstate AND $$RightControlMask) THEN state = state OR $$RightControlBit
'
' the sstate bits were the states of the modifier keys BEFORE this event,
' so if this event is a modifier key going up or down, the sstate is wrong
' and must be fixed (because XBasic reports modifier states AFTER the event).
'
	IF (keytype = $$KeyTypeVirtualKey) THEN
		IFZ sstate THEN mod = 0
		SELECT CASE message
			CASE #WindowKeyDown
						SELECT CASE vkey
							CASE $$KeyAlt							: mod = mod OR $$AltBit								: ' state = state OR $$AltBit
							CASE $$KeyLeftAlt					: mod = mod OR $$AltBit								: ' state = state OR $$AltBit
							CASE $$KeyShift						: mod = mod OR $$ShiftBit							: ' state = state OR $$ShiftBit
							CASE $$KeyLeftShift				: mod = mod OR $$ShiftBit							: ' state = state OR $$ShiftBit
							CASE $$KeyControl					: mod = mod OR $$ControlBit						: ' state = state OR $$ControlBit
							CASE $$KeyLeftControl			: mod = mod OR $$ControlBit						: ' state = state OR $$ControlBit
							CASE $$KeyRightAlt				: mod = mod OR $$RightAltBit					: ' state = state OR mod OR $$AltBit
							CASE $$KeyRightShift			: mod = mod OR $$RightShiftBit				: ' state = state OR mod OR $$ShiftBit
							CASE $$KeyRightControl		: mod = mod OR $$RightControlBit			: ' state = state OR mod OR $$ControlBit
						END SELECT
			CASE #WindowKeyUp
						SELECT CASE vkey
							CASE $$KeyAlt							: mod = mod AND NOT $$AltBit					: ' IFZ (mod AND $$RightAltBit) THEN state = state AND NOT $$AltBit
							CASE $$KeyLeftAlt					: mod = mod AND NOT $$AltBit					: ' IFZ (sstate AND $$RightAltMask) THEN state = state AND NOT $$AltBit
							CASE $$KeyRightAlt				: mod = mod AND NOT $$RightAltBit			: ' state = state AND NOT $$RightAltBit : IFZ (sstate AND $$AltMask) THEN state = state AND NOT $$AltBit
							CASE $$KeyShift						: mod = mod AND NOT $$ShiftBit				: ' IFZ (sstate AND $$RightShiftMask) THEN state = state AND NOT $$ShiftBit
							CASE $$KeyLeftShift				: mod = mod AND NOT $$ShiftBit				: ' IFZ (sstate AND $$RightShiftMask) THEN state = state AND NOT $$ShiftBit
							CASE $$KeyRightShift			: mod = mod AND NOT $$RightShiftBit		: ' state = state AND NOT $$RightShiftBit : IFZ (sstate AND $$ShiftMask) THEN state = state AND NOT $$ShiftBit
							CASE $$KeyControl					: mod = mod AND NOT $$ControlBit			: ' IFZ (sstate AND $$RightControlMask) THEN state = state AND NOT $$ControlBit
							CASE $$KeyLeftControl			: mod = mod AND NOT $$ControlBit			: ' IFZ (sstate AND $$RightControlMask) THEN state = state AND NOT $$ControlBit
							CASE $$KeyRightControl		: mod = mod AND NOT $$RightControlBit	: ' state = state AND NOT $$RightControlBit : IFZ (sstate AND $$ControlMask) THEN state = state AND NOT $$ControlBit
						END SELECT
		END SELECT
	END IF
'
	state = char AND 0x0000FFFF
	state = state OR ((vkey AND 0x00FF) << 24)
	state = state OR ((keytype AND 0x0003) << 20)
	IF (mod AND $$AltBit) THEN state = state OR $$AltBit
	IF (mod AND $$ShiftBit) THEN state = state OR $$ShiftBit
	IF (mod AND $$ControlBit) THEN state = state OR $$ControlBit
	IF (mod AND $$RightAltBit) THEN state = state OR $$AltBit OR $$RightAltBit
	IF (mod AND $$RightShiftBit) THEN state = state OR $$ShiftBit OR $$RightShiftBit
	IF (mod AND $$RightControlBit) THEN state = state OR $$ControlBit OR $$RightControlBit
'
'	a$ = STRING$(keytype) + "." + HEX$(keysym,8) + " " + HEX$(sstate,8) + " " + HEX$(state,8) + ":" + HEX$(mod,8) + "\n"
'	write (1, &a$, LEN(a$))
END FUNCTION
'
'
' ############################
' #####  UpdateMouse ()  #####
' ############################
'
' generate a mouse message if the mouse moved in a system/user window
'
FUNCTION  UpdateMouse (who)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
	SHARED  flushTime
	SHARED  userCount
	SHARED  sysCount
	AUTOX  sroot
	AUTOX  schild
	AUTOX  rootX
	AUTOX  rootY
	AUTOX  winX
	AUTOX  winY
	AUTOX  status
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"UpdateMouse()lockout", lockout) : lockout = 0
'
' only update mouse if no events in the specified event queue
'
	IF who THEN
		IF userCount THEN RETURN ($$FALSE)		' user queue not empty
	ELSE
		IF sysCount THEN RETURN ($$FALSE)			' system queue not empty
	END IF
'
' should check all displays, but for now just check default display
'
	display = display[1].display
	IFZ display THEN RETURN ($$FALSE)		' default display not open
'
' get information about last mouse message put in queue
'
	mouseX = display[display].mouseX
	mouseY = display[display].mouseY
	mouseState = display[display].mouseState
	mouseTime = display[display].mouseTime
	mouseWindow = display[display].mouseWindow
	mouseGrid = display[display].mouseGrid
	mouseMessage = display[display].mouseMessage
'
' if one or more buttons are down, messages are generated automatically
'
	IF (mouseState AND $$MouseButtonMask) THEN RETURN ($$FALSE)
'
	grid = mouseGrid
	window = mouseGrid
	top = window[window].top
	swindow = window[window].swindow
	sdisplay = display[display].sdisplay
'
	destroy = window[window].destroy
	destroyed = window[window].destroyed
	processed = window[window].destroyProcessed	' grid no longer exists
	IF destroy THEN RETURN ($$FALSE)						' grid no longer exists
	IF destroyed THEN RETURN ($$FALSE)					' grid no longer exists
'
	IF (mouseGrid <= 0) THEN RETURN ($$FALSE)		' no mouse messages yet
	IFZ swindow THEN RETURN ($$FALSE)						' no mouse messages yet
'
' force any server events into event queue
'
	flushTime = eventTime
	XstGetSystemTime (@XSyncNowTime)
'
' only update mouse if no events in the specified event queue
'
	IF who THEN
		IF userCount THEN RETURN ($$FALSE)		' user queue not empty
	ELSE
		IF sysCount THEN RETURN ($$FALSE)			' system queue not empty
	END IF
'
' get mouse state - keys/buttons are unchanged since no events pending
'
	##WHOMASK = 0
	##LOCKOUT = 100160
	XQueryPointer (sdisplay, swindow, &sroot, &schild, &rootX, &rootY, &winX, &winY, &status)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
' if XQueryPointer() generated an event, don't generate a mouse message
'
	IF who THEN
		IF userCount THEN RETURN ($$FALSE)		' user queue not empty
	ELSE
		IF sysCount THEN RETURN ($$FALSE)			' system queue not empty
	END IF
'
	SystemButtonStateToButtonState (0, status, 0, @state)
'
	change = $$FALSE
	IF (mouseX != winX) THEN change = $$TRUE		' mouse x motion
	IF (mouseY != winY) THEN change = $$TRUE		' mouse y motion
	IFZ change THEN RETURN ($$FALSE)
'
	message = #WindowMouseMove
	v0 = winX
	v1 = winY
	v2 = mouseState
	v3 = mouseTime + 1
	r0 = 0
	r1 = mouseGrid
'
'	PRINT "UpdateMouse(114)", HEXX$(winX), HEXX$(winY), HEXX$(v0), HEXX$(v1)
	display[display].mouseX = v0
	display[display].mouseY = v1
	display[display].mouseState = v2
	display[display].mouseTime = v3
	display[display].mouseGrid = grid
	display[display].mouseWindow = top
	display[display].mouseMessage = message
'
	XgrAddMessage (top, message, v0, v1, v2, v3, r0, r1)
END FUNCTION
'
'
' ###################################
' #####  UpdateScaledCoords ()  #####
' ###################################
'
' Whenever a grid is resized the relationship between local coordinates
' and scaled coordinates changes, thus the multipliers that convert
' local coordinates into scaled coordinates and vice versa also change.
'
' Call UpdateScaledCoords() to update the conversion multipliers from
' the current width,height in pixels, and gridBoxScaled coordinates.
' Since drawing into most grids is not performed in scaled coordinates,
' it is more efficient to call UpdateScaledCoords() the first time a
' scaled coordinate draw or conversion is performed after a resize.
'
' Scaled multipliers of 0# are invalid and would cause divide by zero
' exceptions, so they are set to 0# during resizes to indicate their
' values have not yet been calculated.
'
FUNCTION  UpdateScaledCoordinates (grid)
	SHARED  WINDOW  window[]
'
	window = grid
	x1# = window[window].gridBoxScaledX1
	y1# = window[window].gridBoxScaledY1
	x2# = window[window].gridBoxScaledX2
	y2# = window[window].gridBoxScaledY2
'
	IF (x1# = x2#) THEN x1# = 0 : x2# = 1#			' avoid math exceptions
	IF (y1# = y2#) THEN y1# = 0 : y2# = 1#			' avoid math exceptions
	window[window].gridBoxScaledX1 = x1#
	window[window].gridBoxScaledY1 = y1#
	window[window].gridBoxScaledX2 = x2#
	window[window].gridBoxScaledY2 = y2#
'
	XgrGetGridPositionAndSize (grid, @x, @y, @width, @height)
'
	IFZ width THEN width = 1										' avoid math exceptions
	IFZ height THEN height = 1									' avoid math exceptions
	IF (width < 0) THEN width = -width
	IF (height < 0) THEN height = -height
'
	x1 = 0
	y1 = 0
	x2 = width - 1
	y2 = height - 1
	IF (x2 = 0) THEN x2 = 1											' avoid math exceptions
	IF (y2 = 0) THEN y2 = 1											' avoid math exceptions
'
	mx# = (x2# - x1#) / DOUBLE (x2)
	my# = (y2# - y1#) / DOUBLE (y2)
	window[window].xScaledPerPixel = mx#
	window[window].yScaledPerPixel = my#
	window[window].xPixelsPerScaled = 1# / mx#
	window[window].yPixelsPerScaled = 1# / my#
'
END FUNCTION
'
'
' ##################################
' #####  WindowEnabledVisible  #####
' ##################################
'
' visiblility = WindowEnabledVisible (wingrid)
'
' visiblility is zero if not enabled or not visible
'
' Calling program should have checked that wingrid is valid
'
FUNCTION  WindowEnabledVisible (wingrid)
	SHARED  WINDOW window[]

	IFZ window[wingrid].state THEN RETURN $$FALSE
	top = window[wingrid].top
'
' If configureRequest or visibilityRequest in progress
' wait up to 5 seconds for the request to finish
'
	XstGetSystemTime (@start)
	DO
		configureRequest  = window[top].configureRequest
		visibilityRequest = window[top].visibilityRequest
		IF ((configureRequest != -1) && (visibilityRequest == -1)) THEN EXIT DO
		DispatchEvents ($$FALSE, $$TRUE)
		IF ##WHOMASK THEN
			XxxXgrSysMessages ()
			IF ##SOFTBREAK THEN RETURN ($$TRUE)
		END IF
		XstGetSystemTime (@time)
		IF ((time - start) > 5000) THEN EXIT DO
	LOOP
	IF window[wingrid].destroy THEN RETURN ($$FALSE)
	IF window[top].destroy THEN RETURN ($$FALSE)
	IF (configureRequest = -1) THEN
		window[top].configureRequest = 0
		PRINT "WindowEnabledVisible()configureRequest  = -1", wingrid, top
	END IF
	IF (visibilityRequest <> -1) THEN
		window[top].visibilityRequest = -1
		PRINT "WindowEnabledVisible()visibilityRequest =", visibilityRequest, wingrid, top
	END IF
	visibility = window[top].visibility
'
	RETURN (visibility)

END FUNCTION
'
'
' ################################
' #####  WinGridDrawable ()  #####
' ################################
'
' drawable = WinGridDrawable (wingrid)
'
' drawable = visibility of the window if it is visible
' drawable = $$TRUE if the window is not visible but is drawable
'            because it has a buffer grid or is a buffer grid
'
' If the window is in the middle of being displayed or resized,
' this function waits a resonable amount of time for that
' process to finish before returning.
'
' Calling program should have checked that wingrid is valid
'
FUNCTION  WinGridDrawable (wingrid)
	SHARED  WINDOW window[]
'
	visibility = WindowEnabledVisible (wingrid)
	IF (visibility) THEN RETURN (visibility)
'
	IF (window[wingrid].buffer) THEN RETURN ($$TRUE)
	IF (window[wingrid].type == #GridTypeBuffer) THEN RETURN ($$TRUE)
'
	RETURN ($$FALSE)
'
END FUNCTION
'
'
' ####################################
' #####  LocalToBufferCoords ()  #####
' ####################################
'
' Compute the two local buffer grid coordinates bx1,by1:bx2,by2
' that correspond to the two local grid coordinates x1,y1:x2,y2.
' Confirm the buffer grid argument is the grid number of the
' buffer grid attached to grid.
'
' Return the system window number of the buffer grid, as well as
' an overlap variable that tells where the x1,y1:x2,y2 line or
' box extends beyond the boundaries of the grid and buffer grid,
' plus where the grid extends beyond the buffer grid and where
' the buffer grid extends beyond the grid.  The overlap variable
' also tells where the region is totally outside the grid and
' buffer grid, as well as when the grid and buffer grid do not
' overlap each other (a pretty sad situation for buffer grids).
'
' The bufferX and bufferY variables are the values assigned to
' grid by XgrSetGridBuffer (grid, buffer, bufferX, bufferY).
' Note that bufferX and bufferY are distances from origin of
' the grid to the buffer grid, so they are positive when the
' buffer grid is to the right and below the grid 0,0 origin.
'
' This function is called by many drawing routines that draw
' to a grid in local grid coordinates, then draw again to the
' potentially offset buffer grid in local buffer coordinates.
'
FUNCTION  LocalToBufferCoords (grid, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @xx1, @yy1, @xx2, @yy2)
	SHARED  WINDOW  window[]
'
	xx1 = 0
	yy1 = 0
	xx2 = 0
	yy2 = 0
	sbuffer = 0
	overlap = 0
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "LocalToBufferCoords() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	IF InvalidGrid (buffer) THEN
		IF ##XBDV THEN PRINT "LocalToBufferCoords() : invalid buffer grid #"; buffer
		RETURN ($$TRUE)
	END IF
'
	window = grid
	check = window[grid].buffer
	bufferX = window[grid].bufferX
	bufferY = window[grid].bufferY
	sbuffer = window[buffer].swindow
'
	IF (sbuffer <= 0) THEN RETURN ($$FALSE)
	IF (buffer != check) THEN RETURN ($$FALSE)
'
' local coords of grid
'
	gx1 = 0
	gy1 = 0
	gx2 = window[grid].width - 1
	gy2 = window[grid].height - 1
'
' local coords of buffer
'
	bx1 = 0
	by1 = 0
	bx2 = window[buffer].width - 1
	by2 = window[buffer].height - 1
'
' grid local coordinates of buffer grid
'
	bgx1 = bx1 + bufferX
	bgy1 = by1 + bufferY
	bgx2 = bx2 + bufferX
	bgy2 = by2 + bufferY
'
' buffer local coordinates at x1,y1:x2,y2 grid local coordinates
'
	xx1 = x1 - bufferX
	yy1 = y1 - bufferY
	xx2 = x2 - bufferX
	yy2 = y2 - bufferY
'
' sort buffer local coordinates of region so (lx1 < lx2) and (ly1 < ly2)
'
	IF (xx1 <= xx2) THEN lx1 = xx1 : lx2 = xx2 ELSE lx1 = xx2 : lx2 = xx1
	IF (yy1 <= yy2) THEN ly1 = yy1 : ly2 = yy2 ELSE ly1 = yy2 : ly2 = yy1
'
' sort grid local coordinates of region so (ax1 < ax2) and (ay1 < ay2)
'
	IF (x1 <= x2) THEN ax1 = x1 : ax2 = x2 ELSE ax1 = x2 : ax2 = x1
	IF (y1 <= y2) THEN ay1 = y1 : ay2 = y2 ELSE ay1 = y2 : ay2 = y1
'
' note where region extends beyond the buffer grid
'
	IF (lx1 < bx1) THEN overlap = overlap OR $$RegionExceedsBufferLeft
	IF (ly1 < by1) THEN overlap = overlap OR $$RegionExceedsBufferTop
	IF (lx2 > bx2) THEN overlap = overlap OR $$RegionExceedsBufferRight
	IF (ly2 > by2) THEN overlap = overlap OR $$RegionExceedsBufferBottom
'
' note where region extends beyond the grid
'
	IF (ax1 < gx1) THEN overlap = overlap OR $$RegionExceedsGridLeft
	IF (ay1 < gy1) THEN overlap = overlap OR $$RegionExceedsGridTop
	IF (ax2 > gx2) THEN overlap = overlap OR $$RegionExceedsGridRight
	IF (ay2 > gy2) THEN overlap = overlap OR $$RegionExceedsGridBottom
'
' note where buffer grid extends outside the grid
'
	IF (gx1 > bgx1) THEN overlap = overlap OR $$BufferExceedsGridLeft
	IF (gy1 > bgy1) THEN overlap = overlap OR $$BufferExceedsGridTop
	IF (gx2 < bgx2) THEN overlap = overlap OR $$BufferExceedsGridRight
	IF (gy2 < bgy2) THEN overlap = overlap OR $$BufferExceedsGridBottom
'
' note where grid extends outside the buffer grid
'
	IF (gx1 < bgx1) THEN overlap = overlap OR $$GridExceedsBufferLeft
	IF (gy1 < bgy1) THEN overlap = overlap OR $$GridExceedsBufferTop
	IF (gx2 > bgx2) THEN overlap = overlap OR $$GridExceedsBufferRight
	IF (gy2 > bgy2) THEN overlap = overlap OR $$GridExceedsBufferBottom
'
' note where region is totally outside buffer grid
'
	IF (bx1 > lx2) THEN overlap = overlap OR $$RegionOutsideBufferLeft
	IF (by1 > ly2) THEN overlap = overlap OR $$RegionOutsideBufferTop
	IF (bx2 < lx1) THEN overlap = overlap OR $$RegionOutsideBufferRight
	IF (by2 < ly2) THEN overlap = overlap OR $$RegionOutsideBufferBottom
'
' note where region is totally outside grid
'
	IF (gx1 > ax2) THEN overlap = overlap OR $$RegionOutsideGridLeft
	IF (gy1 > ay2) THEN overlap = overlap OR $$RegionOutsideGridTop
	IF (gx2 < ax1) THEN overlap = overlap OR $$RegionOutsideGridRight
	IF (gy2 < ay1) THEN overlap = overlap OR $$RegionOutsdieGridBottom
'
' note where buffer grid is totally outside grid
'
	IF (gx1 > bgx2) THEN overlap = overlap OR $$BufferOutsideGridLeft
	IF (gy1 > bgy2) THEN overlap = overlap OR $$BufferOutsideGridTop
	IF (gx2 < bgx1) THEN overlap = overlap OR $$BufferOutsideGridRight
	IF (gy2 < bgy1) THEN overlap = overlap OR $$BufferOutsideGridBottom
'
' note where grid is totally outside buffer grid
'
	IF (bgx1 > gx2) THEN overlap = overlap OR $$GridOutsideBufferLeft
	IF (bgy1 > gy2) THEN overlap = overlap OR $$GridOutsideBufferTop
	IF (bgx2 < gx1) THEN overlap = overlap OR $$GridOutsideBufferRight
	IF (bgy2 < gy1) THEN overlap = overlap OR $$GridOutsideBufferBottom
'
END FUNCTION
'
'
' **************************************************
' *****  Event  EventFunction  EventStructure  *****
' **************************************************
'
' ButtonPress         EventButtonPress()          XButtonEvent
' ButtonRelease       EventButtonRelease()        XButtonEvent
' CirculateNotify     EventCirculateNotify()      XCirculateEvent
' CirculateRequest    EventCirculateRequest()     XCirculateRequestEvent
' ClientMessage       EventClientMessage()        XClientMessageEvent
' ColormapNotify      EventColormapNotify()       XColormapEvent
' ConfigureNotify     EventConfigureNotify()      XConfigureEvent
' ConfigureRequest    EventConfigureRequest()     XConfigureRequestEvent
' CreateNotify        EventCreateNotify()         XCreateWindowEvent
' DestroyNotify       EventDestroyNotify()        XDestroyWindowEvent
' EnterNotify         EventEnterNotify()          XCrossingEvent
' Error               EventError()                XErrorEvent
' Expose              EventExpose()               XExposeEvent
' FocusIn             EventFocusIn()              XFocusChangeEvent
' FocusOut            EventFocusOut()             XFocusChangeEvent
' GraphicsExpose      EventGraphicsExpose()       XGraphicsExposeEvent
' GravityNotify       EventGravityNotify()        XGravityEvent
' KeyPress            EventKeyPress()             XKeyEvent
' KeyRelease          EventKeyRelease()           XKeyEvent
' KeymapNotify        EventKeymapNotify()         XKeymapEvent
' LeaveNotify         EventLeaveNotify()          XCrossingEvent
' MapNotify           EventMapNotify()            XMapEvent
' MapRequest          EventMapRequest()           XMapRequestEvent
' MappingNotify       EventMappingNotify()        XMappingEvent
' MotionNotify        EventMotionNotify()         XMotionEvent
' NoExpose            EventNoExpose()             XNoExposeEvent
' PropertyNotify      EventPropertyNotify()       XPropertyEvent
' ReparentNotify      EventReparentNotify()       XReparentEvent
' ResizeRequest       EventResizeRequest()        XResizeRequestEvent
' SelectionClear      EventSelectionClear()       XSelectionClearEvent
' SelectionNotify     EventSelectionNotify()      XSelectionEvent
' SelectionRequest    EventSelectionRequest()     XSelectionRequestEvent
' UnmapNotify         EventUnmapNotify()          XUnmapEvent
' VisibilityNotify    EventVisibilityNotify()     XVisibilityEvent
'
'
'
' #################################
' #####  EventButtonPress ()  #####
' #################################
'
FUNCTION  EventButtonPress (XButtonEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
	SHARED  eventTime
	SHARED  flushTime
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventButtonPress()lockout", lockout) : lockout = 0
'
	IF (event.button > 5) THEN RETURN   ' Ignor button numbers 6 or higher
'
	eventTime = event.time
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventButtonPress():Null window for system window", HEXX$(swindow)
'
	grid = window
	window = top
	IFZ window THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventButtonPress() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	IFZ grid THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventButtonPress() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	stop = window[window].stop
	display = window[window].display
	sdisplay = window[window].sdisplay
'
	time = event.time
	button = event.button
	clickTime = window[grid].clickTime
	clickCount = window[grid].clickCount
	clickButton = window[grid].clickButton
'
	SystemButtonStateToButtonState (event.button, event.state, event.time, @state)
'
' event.state contains the button state BEFORE this ButtonPress event,
' so the pressed button must be set manually.
'
	SELECT CASE event.button
		CASE $$Button1	: state = state OR $$MouseButton1
		CASE $$Button2	: state = state OR $$MouseButton2
		CASE $$Button3	: state = state OR $$MouseButton3
		CASE $$Button4	: state = state OR $$MouseButton4
		CASE $$Button5	: state = state OR $$MouseButton5
	END SELECT
'
	count = 1
	IF (button = clickButton) THEN
		delta = time - clickTime
		IF (delta > 120) THEN
			IF (delta < 375) THEN
				count = clickCount + 1
				IF (count > 4) THEN count = 4
			END IF
		ELSE
			' delta < 100 msec prabably dirty contacts or defective microswitch
			IF ##XBDV THEN PRINT "EventButtonPress()delta, button", delta, event.button
		END IF
	END IF
'
	state = state OR (count << 4)
	window[grid].clickTime = time
	window[grid].clickCount = count
	IF (button <= 3) THEN
		window[grid].clickButton = button
	ELSE
		window[grid].clickButton = 0
	END IF
'
' always remember last mouse event added to queue
'
	message = #WindowMouseDown
	display[display].mouseX = v0
	display[display].mouseY = v1
	display[display].mouseState = v2
	display[display].mouseTime = v3
	display[display].mouseGrid = grid
	display[display].mouseWindow = window
	display[display].mouseMessage = message
	display[display].mouseFocusGrid = grid
'
' If window != current selected window then make it so.
' XSetInputFocus() generates FocusOut and FocusIn events.
' FocusOut and FocusIn generate #Deselected and #Selected messages.
'
	who = window[window].whomask
	IF who THEN modal = modalWindowUser ELSE modal = modalWindowSystem
	selectedWindow = display[display].selectedWindow
	suppress = $$FALSE
'
' Also check for this being a sibling within a modal window,
' where this window's leader or parent will equal the modal window
'
	IF modal THEN
		IF (top != modal) THEN
			IF (window[window].leader != modal) THEN
				top = modal
				suppress = $$TRUE
				stop = window[modal].swindow
			END IF
		END IF
	END IF
'
'
' add #WindowMouseDown message to message queue
'
	IFZ suppress THEN
		IF (event.button == $$Button4) OR (event.button == $$Button5) THEN
			' MouseWheel is usually mapped to button4 and 5 on Linux (button4 is
			' up, button5 is down).
			' Add 'ZAxisMapping 4 5' to the 'Pointer' section in your XF86Config
			' to enable it.
			message = #WindowMouseWheel
			v0 = event.x
			v1 = event.y
			v2 = state
			v3 = 0
			IF event.button == $$Button5 THEN
				v3 = NOT v3
			END IF
			r0 = 0
			r1 = grid
		ELSE
			message = #WindowMouseDown
			v0 = event.x
			v1 = event.y
			v2 = state
			v3 = event.time
			r0 = 0
			r1 = grid
		END IF
		XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
	END IF
'
END FUNCTION
'
'
' ###################################
' #####  EventButtonRelease ()  #####
' ###################################
'
FUNCTION  EventButtonRelease (XButtonEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
'
	eventTime = event.time
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventButtonRelease():Null window for system window", HEXX$(swindow)
	grid = window
	window = top
'
	IFZ window THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventButtonRelease() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	IFZ grid THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventButtonRelease() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	top = window[window].top
	stop = window[window].stop
	display = window[window].display
	sdisplay = window[window].sdisplay
'
	SystemButtonStateToButtonState (event.button, event.state, event.time, @state)
'
' event.state contains the button state BEFORE this ButtonRelease event,
' so the released button must be cleared manually.
'
	SELECT CASE event.button
		CASE $$Button1	: state = state AND NOT $$MouseButton1
		CASE $$Button2	: state = state AND NOT $$MouseButton2
		CASE $$Button3	: state = state AND NOT $$MouseButton3
		CASE $$Button4	: state = state AND NOT $$MouseButton4
		CASE $$Button5	: state = state AND NOT $$MouseButton5
	END SELECT
'
	message = #WindowMouseUp
	v0 = event.x
	v1 = event.y
	v2 = state
	v3 = event.time
	r0 = 0
	r1 = grid
'
' always remember last mouse event added to queue
'
	display[display].mouseX = v0
	display[display].mouseY = v1
	display[display].mouseState = v2
	display[display].mouseTime = v3
	display[display].mouseGrid = grid
	display[display].mouseWindow = window
	display[display].mouseMessage = message
	display[display].mouseFocusGrid = grid
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)

	IF ##XBDV THEN
		IF (event.button < 4) THEN
			clickTime = window[grid].clickTime
			delta = v3 - clickTime
			IF (delta < 30) THEN PRINT "EventButtonRelease(72)", event.button, delta
		END IF
	END IF

END FUNCTION
'
'
' #####################################
' #####  EventCirculateNotify ()  #####
' #####################################
'
FUNCTION  EventCirculateNotify (XCirculateEvent event)
'
	IF ##XBDV THEN PRINT "EventCirculateNotify() : no action or message"
END FUNCTION
'
'
' ######################################
' #####  EventCirculateRequest ()  #####
' ######################################
'
FUNCTION  EventCirculateRequest (XCirculateRequestEvent event)
'
	PRINT "EventCirculateRequest() : no action or message"
	IF ##XBDV THEN PRINT "EventCirculateRequest() : no action or message"
END FUNCTION
'
'
' ###################################
' #####  EventClientMessage ()  #####
' ###################################
'
FUNCTION  EventClientMessage (XClientMessageEvent event)
	SHARED  WINDOW  window[]
'
	swindow = event.window								' should be valid system window #
	message = event.data[1]								' should be #XA_WM_DELETE_WINDOW
	messageType = event.messageType				' should be #XA_WM_PROTOCOLS
'
	XgrSystemWindowToWindow (swindow, @window, @top)
'
	IF InvalidWinGrid (window) THEN
		PRINT "EventClientMessage():Invalid window for system window", HEXX$(window), HEXX$(swindow)
		RETURN ($$TRUE)
	END IF
'
'	PRINT "EventClientMessage() : "; event.type, messageType, message
'	PrintClientMessage (event)
'
	SELECT CASE message
		CASE #XA_WM_TAKE_FOCUS		:	 ' not requested
		CASE #XA_WM_SAVE_YOURSELF	:	 ' not requested
		CASE #XA_WM_DELETE_WINDOW	: message = #WindowClose
'																PrintClientMessage (event)
																IF (window > 0) THEN
																	IF (window = top) THEN
																		IF window[window].destroy THEN message = #WindowDestroyed
																		IF window[window].destroyed THEN message = #WindowDestroyed
																		IF window[window].destroyProcessed THEN message = #windowDestroyed
																		XgrAddMessage (window, message, 0, 0, 0, 0, 0, window)
'																		PRINT "EventClientMessage() : WM_DELETE_WINDOW : "; window;; HEX$(swindow,8);;
'																		IF (message = #WindowClose) THEN PRINT "#WindowClose" ELSE PRINT "#WindowDestroyed"
																	END IF
																END IF
	END SELECT
END FUNCTION
'
'
' ####################################
' #####  EventColormapNotify ()  #####
' ####################################
'
FUNCTION  EventColormapNotify (XColormapEvent event)
'
	IF ##XBDV THEN PRINT "EventColormapNotify() : no action or message"
END FUNCTION
'
'
' #####################################
' #####  EventConfigureNotify ()  #####
' #####################################
'
FUNCTION  EventConfigureNotify (XConfigureEvent event)
	SHARED	WINDOW  window[]
	SHARED  MESSAGE  message[]
	SHARED	userCount
	SHARED	sysCount
	SHARED  userOut
	SHARED	sysOut
	SHARED	userIn
	SHARED  sysIn
	SHARED  inQueue
	AUTOX  rootX,  rootY,  schild
'
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventConfigureNotify():Null window for system window", HEXX$(swindow)
'
	IFZ window THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventConfigureNotify() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
'	IF ##XBDV THEN PrintConfigureNotify (event)
'
	kind = window[window].kind
	sroot = window[window].sroot
	mapped = window[window].mapped
	sparent = window[window].sparent
	sdisplay = window[window].sdisplay
	borderWidth = window[window].borderWidth
	titleHeight = window[window].titleHeight
'
' must ignore when unmapped ::: later: why ???
'
	window[window].configureRequest = $$FALSE  ' confirm configuration event
	IFZ mapped THEN RETURN
'
	IF (window != top) THEN RETURN		' windows only
'
' Find top-level window coordinates on the display aka root window.
' The x,y coordinates supplied in this event are total lies because
' the window manager creates artificial parents to implement the
' window resize frame.  XGeometry() and all other functions return
' bogus values.  Only XTranslateCoordinates() works.
'
'	XTranslateCoordinates (sdisplay, swindow, sroot, 0, 0, &rootX, &rootY, &schild)
'
' get x,y,width,height from this event plus XTranslateCoordinates()
'
' If the event.sendEvent is set, the x and y are valid and much faster.
' (usually when window is being moved)
'
' If the event.sendEvent is not set, use the XTranslateCoordinates to get
' the x and y (usually when the window is being resized)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	DO
		IF event.sendEvent THEN
			x = event.x
			y = event.y
		ELSE
			##WHOMASK = 0
			##LOCKOUT = 100164
			XTranslateCoordinates (sdisplay, swindow, sroot, 0, 0, &rootX, &rootY, &schild)
			##LOCKOUT = lockout
			##WHOMASK = whomask
			x = rootX								' window xDisp
			y = rootY								' window yDisp
		END IF
'
' look for another later EventConfigureNotify message for this same window
'
		more = 0
		##WHOMASK = 0
		##LOCKOUT = 100165
		more = XCheckTypedWindowEvent (sdisplay, swindow, event.type, &event)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	LOOP WHILE more
'
	width = event.width       ' width of window
	height = event.height     ' height of window
'
' get previous x, y, width, height
'
	xx = window[window].x
	yy = window[window].y
	ww = window[window].width
	hh = window[window].height
'
'	XxxLog ("EventConfigureNotify() " + STR$(xx) + STR$(x) + STR$(yy) + STR$(y) + STR$(ww) + STR$(width) + STR$(hh) + STR$(height))
'
' set new x, y, width, height
'
	window[window].x = x
	window[window].y = y
	window[window].width = width
	window[window].height = height
'
' see if window was moved and/or resized
'
	move = $$FALSE
	resize = $$FALSE
	IF (xx != x) THEN move = $$TRUE
	IF (yy != y) THEN move = $$TRUE
	IF (ww != width) THEN resize = $$TRUE
	IF (hh != height) THEN resize = $$TRUE
'
' if window moved, note previous position
'
	IF move THEN
		window[window].priorX = xx
		window[window].priorY = yy
	END IF
'
' if window resized, note previous size and update grid/scaled coords
'
	IF resize THEN
		window[window].priorWidth = ww					'
		window[window].priorHeight = hh					'
		window[window].xScaledPerPixel = 0#			' invalidate
		window[window].yScaledPerPixel = 0#			' scaled coordinate
		window[window].xPixelsPerScaled = 0#		' multipliers
		window[window].yPixelsPerScaled = 0#		'
'
		gridBoxX1 = window[window].gridBoxX1		' current
		gridBoxY1 = window[window].gridBoxY1		' grid box
		gridBoxX2 = window[window].gridBoxX2		' coords
		gridBoxY2 = window[window].gridBoxY2		'
'
		IF (gridBoxX2 < gridBoxX1) THEN
			gridBoxX2 = gridBoxX1 - width + 1			' x coords decrease rightward
		ELSE
			gridBoxX2 = gridBoxX1 + width - 1			' x coords increase rightward
		END IF
'
		IF (gridBoxY2 < gridBoxY1) THEN
			gridBoxY2 = gridBoxY1 - height + 1		' y coords decrease downward
		ELSE
			gridBoxY2 = gridBoxY1 + height - 1		' y coords increase downward
		END IF
'
		window[window].gridBoxX1 = gridBoxX1
		window[window].gridBoxY1 = gridBoxY1
		window[window].gridBoxX2 = gridBoxX2
		window[window].gridBoxY2 = gridBoxY2
	END IF
'
	IF (move OR resize) THEN
		message = #WindowResized
		v0 = x
		v1 = y
		v2 = width
		v3 = height
		r0 = 0
		r1 = window
'
'
		who = window[window].whomask
		IF who THEN queue = 1 ELSE queue = 0
		IF queue THEN
			count = userCount
			out = userOut
			in = userIn
		ELSE
			count = sysCount
			out = sysOut
			in = sysIn
		END IF
		IF count THEN
			lastIn = window[window].lastIn  'last message for this window
			IF (lastIn <= out) THEN
				GOSUB AddMessage
				RETURN
			END IF
			IF (lastIn >= in) THEN
				GOSUB AddMessage
				RETURN
			END IF
			in = lastIn
'
' If the last message added for this window is also #WindowResized
' and is still in the message queue, then replace it with
' this message instead of adding another message.
'
			SELECT CASE TRUE
				CASE message[queue,in].wingrid != window  : GOSUB AddMessage
				CASE message[queue,in].message != message : GOSUB AddMessage
				CASE message[queue,in].r0      != r0      : GOSUB AddMessage
				CASE message[queue,in].r1      != r1      : GOSUB AddMessage
				CASE inQueue                              : GOSUB AddMessage
				CASE ELSE :
						inQueue = $$TRUE
						message[queue,in].v0 = v0
						message[queue,in].v1 = v1
						message[queue,in].v2 = v2
						message[queue,in].v3 = v3
						inQueue = $$FALSE
			END SELECT
		ELSE
			XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
		END IF
	END IF
'
	RETURN
'
'
' *****  AddMessage  *****
'
SUB AddMessage
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
END SUB
'
'
' ****  DoXCheck  ****    '*cw* 230107
'
SUB DoXCheck
	more = XCheckTypedWindowEvent (sdisplay, swindow, event.type, &event)
END SUB
'
END FUNCTION
'
'
' ######################################
' #####  EventConfigureRequest ()  #####
' ######################################
'
FUNCTION  EventConfigureRequest (XConfigureRequestEvent event)
'
	IF ##XBDV THEN PRINT "EventConfigureRequest() : no action or message"
END FUNCTION
'
'
' ##################################
' #####  EventCreateNotify ()  #####
' ##################################
'
'	If $$SubstructureNotifyMask is set in XgrCreateWindow()
' an EventCreateNotify() is generated when children are created
' with XgrCreateGrid().
'
' Not used at this time.
'
FUNCTION  EventCreateNotify (XCreateWindowEvent event)
	SHARED  WINDOW  window[]
'
	RETURN ($$FALSE)
'
'	swindow = event.window
	swindow = event.parent
	XxxLog2 (@"EventCreateNotify()", swindow)
'	IF ##XBDV THEN PRINT "EventCreateNotify(14)", event.window, event.parent
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventCreateNotify():Null window for system window", HEXX$(swindow)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventCreateNotify() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
'	IF ##XBDV THEN PRINT "EventCreateNotify(30)", swindow, window, window[window].kind, $$KindWindow
	IF (window[window].kind != $$KindWindow) THEN RETURN	' for windows only
'	IF (window[top].kind != $$KindWindow) THEN RETURN	' for windows only
'
	x = event.x
	y = event.y
	width = event.width
	height = event.height
	sparent = event.parent
	sdisplay = event.display
	borderWidth = event.borderWidth
'
'	IF ##XBDV THEN PRINT "EventCreateNotify(42)", x, y, width, height, borderWidth
	RETURN
'
	message = #WindowCreated
	v0 = x
	v1 = y
	v2 = width
	v3 = height
	r0 = 0
	r1 = window
'
	IF (sparent = window[window].sroot) THEN
		parent = 0
	ELSE
		XgrSystemWindowToWindow (sparent, @parent, @ptop)
	END IF
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'
	window[window].x = v0
	window[window].y = v1
	window[window].width = v2
	window[window].height = v3
'
	IF (sparent != window[window].sparent) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureUnexpected
		IF ##XBDV THEN PRINT "EventCreateNotify() : unexpected sparent #"
	END IF
'
	IF (parent != window[window].parent) THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureUnexpected
		IF ##XBDV THEN PRINT "EventCreateNotify() : unexpected parent #"
	END IF
'
	IF (sdisplay != window[window].sdisplay) THEN
		##ERROR = ($$ErrorObjectDisplay << 8) OR $$ErrorNatureUnexpected
		IF ##XBDV THEN PRINT "EventCreateNotify() : unexpected sdisplay #"
	END IF
END FUNCTION
'
'
' ###################################
' #####  EventDestroyNotify ()  #####
' ###################################
'
' As of 95 Feb 08, GraphicsDesigner does not add #Destroyed messages
' for grids, only #WindowDestroyed messages for windows.  This is not
' good design, but the Windows version of GraphicsDesigner works this
' way, and GuiDesigner works the Windows way.  To change this will
' require changes to both versions of GraphicsDesigner and GuiDesigner.
'
' The current method works because the only time grids are destroyed
' is when a user program calls XgrDestroyGrid() and when a window is
' destroyed by user action or a user program calls XgrDestroyWindow().
'
FUNCTION  EventDestroyNotify (XDestroyWindowEvent event)
	SHARED  textSelectionGrid
	SHARED  WINDOW  window[]
	STATIC  WINDOW  zipwin
	SHARED swindow[]
'
' If the $$SubstructureNotifyMask is set, there will be cases when event.event is not the same as event.window
' To prevent processing the same window twice, handle events only when they are equal
'
	sevent = event.event
	swindow = event.window
	IF (sevent <> swindow) THEN
		XgrSystemWindowToWindow (sevent, @ewindow, @etop)
		XgrSystemWindowToWindow (swindow, @window, @top)
	END IF
	IF (sevent <> swindow) THEN RETURN ($$FALSE)
'
	XgrSystemWindowToWindow (swindow, @window, @top)
	upper = UBOUND (window[])
'
'	a$ = "EventDestroyNotify().A : " + STRING$(window) + " : " + HEX$(swindow,8) + " : " + HEX$(sevent,8) + "\n"
'	write (1, &a$, LEN(a$))
'
	IF InvalidWinGrid (window) THEN
		IF ((window <= 0) OR (window > upper)) THEN
			##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
			IF ##XBDV THEN PRINT "EventDestroyNotify() : invalid window #"; window
			RETURN ($$TRUE)
		END IF
		IF window[window].destroyProcessed THEN
			##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
			IF ##XBDV THEN PRINT "EventDestroyNotify() : window already destroyed and processed : invalid window #"; window
			RETURN ($$TRUE)
		END IF
		IF window[window].destroyed THEN
			##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
			IF ##XBDV THEN PRINT "EventDestroyNotify() : window already destroyed : invalid window #"; window
			RETURN ($$TRUE)
		END IF
	END IF
'
	IFZ window[window].destroy THEN
		IFZ window[top].destroy THEN
			IF ##XBDV THEN
				PRINT"EventDestroyNotify(66) .destroy not set in window nor top", window, top
			END IF
		END IF
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventDestroyNotify()lockout", lockout) : lockout = 0
'
	IF (window = textSelectionGrid) THEN textSelectionGrid = 0
'
	buffer = window[window].buffer
	IF buffer THEN
'		XxxLog2 ("EventDestroyNotify(75)buffer", buffer)
		IF (window[buffer].type = 1) THEN
			bufferSdisplay = window[buffer].sdisplay
			bufferSwindow = window[buffer].swindow
			bufferGc = window[buffer].gc
			##WHOMASK = 0
			##LOCKOUT = 100166
			IF bufferGc THEN
				XFreeGC (bufferSdisplay, bufferGc)
				window[buffer].gc = 0
			END IF
			IF bufferSwindow THEN
				window[buffer].destroy = $$TRUE
				XFreePixmap (bufferSdisplay, bufferSwindow)
				window[buffer].swindow = 0
			END IF
			##LOCKOUT = lockout
			##WHOMASK = whomask
			window[buffer].window = 0
			window[buffer].destroyed = $$TRUE
			window[window].buffer = 0
		END IF
	END IF
'
	sdisplay = window[window].sdisplay
	gc = window[window].gc
'
	IF (gc && sdisplay) THEN
		##WHOMASK = 0
		##LOCKOUT = 100167
		XFreeGC (sdisplay, gc)
		window[window].gc = 0
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
' Event handling functions normally add appropriate messages
' to the message queue.  If this function did so, it would add
' a #Destroyed message for grids and a #WindowDestroyed for
' windows.  This function does not add any messages to the
' message queue at this time for two reasons.  First, grids
' currently receive #Destroy messages from GuiDesigner when
' it processes a #WindowDestroyed message.  Second, the way
' GuiDesigner works now, it has to receive #WindowDestroyed
' before the window is actually destroyed, to prevent calls
' to functions that attempt to manipulate grids that have
' already been destroyed.  Just in case a window does get
' destroyed without XgrDestroyWindow() being called, this
' function does add #WindowDestroyed message if it finds
' window[window].destroy is $$FALSE.
'
	destroy = window[window].destroy
'
' This is the only place that sets destroyed and clears swindow, therefore, it is
' a reliable indication that the window manager has destroyed the system window
' and it is safe for GetNewWindowNumber() to reuse this window number
'
	window[window].destroyed = $$TRUE
	swindex = swindow AND 0x1FFFFF
	IF (swindex <= UBOUND(swindow[])) THEN
		IFZ window[window].swindow THEN PRINT "EventDestroyNotify() .swindow already zeroed", window
		IFZ swindow[swindex] THEN PRINT "EventDestroyNotify() swindow[swindex] already zeroed", swindex
		swindow[swindex] = 0
		window[window].swindow = 0
	END IF
	IFZ window[window].window THEN PRINT "EventDestroyNotify() .window already zeroed", window
	window[window].window  = 0

	func = window[window].winFunc
	IF (window = top) THEN
		IFZ destroy THEN
			XgrAddMessage (window, #WindowDestroyed, func, 0, 0, 0, 0, window)
		ELSE
			window[window].destroyProcessed = -7
		END IF
	ELSE
'		XgrAddMessage (window, #Destroyed, func, 0, 0, 0, 0, window)
	END IF
'
END FUNCTION
'
'
' #################################
' #####  EventEnterNotify ()  #####
' #################################
'
FUNCTION  EventEnterNotify (XCrossingEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
	STATIC  lastEnterGrid
'
	eventTime = event.time
	subwindow = event.subwindow
	IF subwindow THEN RETURN									' skip parents
'
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventEntryNotify():Null window for system window", HEXX$(swindow)
	grid = window
	window = top
'
' #WindowMouseEnter message should be sent only when entering a grid
'
	IF (grid == window) THEN RETURN ($$FALSE)
'
' The window manager generates EventLeaveNotify and EventEnterNotify
' when mouse button one is pressed. These are not nesessary, unless
' entering a different window, as when a PullDown window is hidden.
'
	IF (event.state AND $$Button1MotionMask) THEN
		IF (grid == lastEnterGrid) THEN RETURN
	END IF
	lastEnterGrid = grid
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "EventEnterNotify() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "EventEnterNotify() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	stop = window[window].stop
	display = window[window].display
	sdisplay = window[window].sdisplay
'
	SystemButtonStateToButtonState (0, event.state, event.time, @state)
'
	message = #WindowMouseEnter
	v0 = event.x
	v1 = event.y
	v2 = state
	v3 = event.time
	r0 = 0
	r1 = grid
'
' always remember last mouse event added to queue
'
	display[display].mouseX = v0
	display[display].mouseY = v1
	display[display].mouseState = v2
	display[display].mouseTime = v3
	display[display].mouseGrid = grid
	display[display].mouseWindow = window
	display[display].mouseMessage = message
	display[display].mouseFocusGrid = grid
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'
'	IF ##XBDV THEN PRINT "EventEnterNotify()", grid, window, HEXX$(event.state), HEXX$(event.focus), HEXX$(event.sameScreen), HEXX$(event.detail), HEXX$(event.mode)
END FUNCTION
'
'
' ###########################
' #####  EventError ()  #####
' ###########################
'
' Check Xproto.h for Request Codes
'
CFUNCTION  EventError (dpy, XErrorEvent event)
	AUTOX  error$
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventError()lockout", lockout)
'
	##WHOMASK = 0
	##LOCKOUT = 100168
'
	##XERROR = (event.requestCode << 16) OR (event.errorCode << 8) OR (event.minorCode)
'
	sdisplay = event.display
	serror = event.errorCode
'
	error$ = NULL$ (1023)
	XGetErrorText (sdisplay, serror, &error$, 1023)
	error$ = CSIZE$ (error$)
'
	a$ = "System error of failed request : " + error$ + "\n"
	b$ = "Failure code of failed request : " + STRING$(event.errorCode) + "\n"
	c$ = "Major opcode of failed request : " + STRING$(event.requestCode) + "\n"
	d$ = "Minor opcode of failed request : " + STRING$(event.minorCode) + "\n"
	e$ = "Resource ID for failed request : " + HEX$(event.resourceid) + "\n"
	f$ = "Serial number : failed request : " + STRING$(event.serial) + "\n\n"
'
	write (1, &a$, LEN(a$))
	write (1, &b$, LEN(b$))
	write (1, &c$, LEN(c$))
	write (1, &d$, LEN(d$))
	write (1, &e$, LEN(e$))
	write (1, &f$, LEN(f$))
'
	##LOCKOUT = lockout
	##WHOMASK = whomask
'	PRINT "xgr.x:EventError()\n"; a$; b$; c$; d$; e$; f$; HEXX$(serror), error$
'
END FUNCTION
'
'
' ############################
' #####  EventExpose ()  #####
' ############################
'
FUNCTION  EventExpose (XExposeEvent event)
	SHARED  WINDOW  window[]
	SHARED	noExpose
'
	SHARED  MESSAGE  message[]
	SHARED	userCount
	SHARED	sysCount
	SHARED  userOut
	SHARED	sysOut
	SHARED	userIn
	SHARED  sysIn
	SHARED  inQueue
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventExpose()lockout", lockout) : lockout = 0
'
	swindow = event.window
	sdisplay = event.display
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventExpose():Null window for system window", HEXX$(swindow)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventExpose() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	IF (window = noExpose) THEN RETURN ($$FALSE)		' suppress #RedrawGrid
'
	x1 = event.x
	y1 = event.y
	x2 = x1 + event.width - 1
	y2 = y1 + event.height - 1
'
' process all consecutive expose messages
' combine all consecutive expose messages to same window into one message
'
	DO
		xx1 = event.x
		yy1 = event.y
		xx2 = xx1 + event.width - 1
		yy2 = yy1 + event.height - 1
		count = event.count
'
		IF (xx1 < x1) THEN x1 = xx1
		IF (yy1 < y1) THEN y1 = yy1
		IF (xx2 > x2) THEN x2 = xx2
		IF (yy2 > y2) THEN y2 = yy2
'
		more = 0
		IF count THEN
			##WHOMASK = 0
			##LOCKOUT = 100169
			more = XCheckTypedWindowEvent (sdisplay, swindow, event.type, &event)
			##LOCKOUT = lockout
			##WHOMASK = whomask
		END IF
	LOOP WHILE more
'
' prepare #WindowRedraw or #RedrawGrid message
'
	message = #WindowRedraw
	IF (window != top) THEN message = #RedrawGrid
	v0 = x1
	v1 = y1
	v2 = x2 - x1 + 1
	v3 = y2 - y1 + 1
	r0 = 0
	r1 = window
'
	grid = window
	buffer = window[grid].buffer
	IF buffer THEN
		IF InvalidGrid (buffer) THEN buffer = 0
	END IF
	IF buffer THEN
		GOSUB RefreshGrid
	ELSE
		'
		' If the last message loaded for this window was the same and has not been
		' processed, just add to the redraw area instead of adding another message
		'
		who = window[window].whomask
		IF who THEN queue = 1 ELSE queue = 0
		IF queue THEN
			count = userCount
			out = userOut
			in = userIn
		ELSE
			count = sysCount
			out = sysOut
			in = sysIn
		END IF
		IF count THEN
			lastIn = window[window].lastIn
			IF (lastIn <= out) THEN
				GOSUB AddMessage
				RETURN
			END IF
			IF (lastIn >= in) THEN
				GOSUB AddMessage
				RETURN
			END IF
			in = lastIn

			SELECT CASE TRUE
				CASE message[queue,in].wingrid != window  : GOSUB AddMessage
				CASE message[queue,in].message != message : GOSUB AddMessage
				CASE message[queue,in].r0      != r0      : GOSUB AddMessage
				CASE message[queue,in].r1      != r1      : GOSUB AddMessage
				CASE inQueue                              : GOSUB AddMessage
				CASE ELSE :
						inQueue = $$TRUE
						xx1 = message[queue,in].v0
						yy1 = message[queue,in].v1
						xx2 = message[queue,in].v2 + xx1 - 1
						yy2 = message[queue,in].v3 + yy1 - 1
						IF (xx1 < x1) THEN x1 = xx1
						IF (yy1 < y1) THEN y1 = yy1
						IF (xx2 > x2) THEN x2 = xx2
						IF (yy2 > y2) THEN y2 = yy2
						v0 = x1
						v1 = y1
						v2 = x2 - x1 + 1
						v3 = y2 - y1 + 1
						message[queue,in].v0 = v0
						message[queue,in].v1 = v1
						message[queue,in].v2 = v2
						message[queue,in].v3 = v3
						inQueue = $$FALSE
			END SELECT
		ELSE
			XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
		END IF
	END IF
'
	RETURN
'
'
' *****  AddMessage  *****
'
SUB AddMessage
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
END SUB
'
'
' *****  RefreshGrid  *****
'
SUB RefreshGrid
	gc = window[window].gc
	sbuffer = window[buffer].swindow
	Xindent = window[buffer].bufferX
	Yindent = window[buffer].bufferY
	sx2max  = window[buffer].width -1
	sy2max  = window[buffer].height -1
	sx1 = x1 - Xindent
	sy1 = y1 - Yindent
	sx2 = x2 - Xindent
	sy2 = y2 - Yindent
	IF (sx1 < 0) THEN sx1 = 0
	IF (sy1 < 0) THEN sy1 = 0
	IF (sx2 > sx2max) THEN sx2 = sx2max
	IF (sy2 > sy2max) THEN sy2 = sy2max
	width = sx2 - sx1 + 1
	height = sy2 - sy1 + 1
	dx1 = sx1 + Xindent
	dy1 = sy1 + Yindent
	##WHOMASK = 0
	##LOCKOUT = 100170
	XCopyArea (sdisplay, sbuffer, swindow, gc, sx1, sy1, width, height, dx1, dy1)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END SUB
'
END FUNCTION
'
'
' #############################
' #####  EventFocusIn ()  #####
' #############################
'
' if a modal window is active and a FocusIn event to another window
' in the application occurs, a #Selected message is sent to the new
' focus window, but XSetInputFocus() is called to restore input focus
' to the modal window.
'
FUNCTION  EventFocusIn (XFocusChangeEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
	SHARED  eventTime
	SHARED  flushTime
	SHARED  XSyncTime
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventFocusIn()lockout", lockout) : lockout = 0
'
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventFocusIn():Null window for system window", HEXX$(swindow)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventFocusIn() : invalid window #"; window, top
		RETURN ($$TRUE)
	END IF
'
	IF (window != top) THEN
		IF InvalidWinGrid (top) THEN
			IF ##XBDV THEN PRINT "EventFocusIn() : invalid top window #"; window, top
			RETURN ($$TRUE)
		END IF
	END IF
'
	window = top
	display = window[window].display
	sdisplay = window[window].sdisplay
	selectedWindow = display[display].selectedWindow
	display[display].selectedWindow = window
'
	windowType = window[window].type
	noSelect = windowType AND $$WindowTypeNoSelect
	IF noSelect THEN
		IF ##XBDV THEN PRINT "EventFocusIn(50)WindowTypeNoSelect is selected", window
		RETURN
	END IF
'	IF ##XBDV THEN PRINT "EventFocusIn()", window, HEXX$(noSelect)

'
'	Linux is not the same as Windows, but the idea is to send the message and let Xui sort it out.
'	IF (window = selectedWindow) THEN RETURN
'
	suppress = $$FALSE
	who = window[window].whomask
	IF who THEN modal = modalWindowUser ELSE modal =  modalWindowSystem
'	PRINT "EventFocusIn().A : "; HEX$(who,8);; HEX$(window,8);; HEX$(modal,8);; HEX$(modalWindowSystem,8);; HEX$(modalWindowUser,8);; suppress
'
'  XSetInputFocus causes system errors if the window is not mapped
'
	IF modal THEN
		IF (window != modal) THEN
			suppress = $$TRUE
			IF window[modal].mapped THEN
				oldwin = window
				window = modal
				swindow = window[window].swindow
				sdisplay = window[window].sdisplay
				##WHOMASK = 0
				##LOCKOUT = 100171
				XSetInputFocus (sdisplay, swindow, $$RevertToParent, 0)
				##LOCKOUT = 100172
				XSync (sdisplay, $$FALSE)
				##LOCKOUT = 100173
				XBell (sdisplay, 0)
				##LOCKOUT = lockout
				##WHOMASK = whomask
				flushTime = eventTime
				XstGetSystemTime (@XSyncNowTime)
				XstGetSystemTime (@XSyncTime)
'				PRINT "EventFocusIn().B : "; HEX$(who,8);; HEX$(window,8);; HEX$(modal,8);; HEX$(modalWindowSystem,8);; HEX$(modalWindowUser,8);; suppress
'				PRINT "EventFocusIn().B : "; HEX$(who,8);; oldwin;; window;; modal;; modalWindowSystem;; modalWindowUser;; suppress
			END IF
		END IF
	END IF
'
' select the window
'
	IFZ suppress THEN
		message = #WindowSelected
		v0 = 0
		v1 = 0
		v2 = 0
		v3 = 0
		r0 = 0
		r1 = window
		XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'		PRINT "EventFocusIn().C : "; HEX$(who,8);; HEX$(window,8);; HEX$(modal,8);; HEX$(modalWindowSystem,8);; HEX$(modalWindowUser,8);; suppress
	END IF
'
END FUNCTION
'
'
' ##############################
' #####  EventFocusOut ()  #####
' ##############################
'
' modal window can be deselected and loose keyboard focus
' if a window in another application is selected.
'
FUNCTION  EventFocusOut (XFocusChangeEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
'
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventFocusOut():Null window for system window", HEXX$(swindow)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventFocusOut() : invalid window #"; window, top
		RETURN ($$TRUE)
	END IF
'
	IF (window != top) THEN
		IF InvalidWinGrid (top) THEN
			IF ##XBDV THEN PRINT "EventFocusOut() : invalid top window #"; window, top
			RETURN ($$TRUE)
		END IF
	END IF
'
	window = top
	display = window[window].display
	display[display].selectedWindow = 0
'
	windowType = window[window].type
	noSelect = windowType AND $$WindowTypeNoSelect
	IF noSelect THEN
		IF ##XBDV THEN PRINT "EventFocusout(39)WindowTypeNoSelect ", window
		RETURN
	END IF
'
	who = window[window].whomask
	IF who THEN modal = modalWindowUser ELSE modal = modalWindowSystem
'
	message = #WindowDeselected
	v0 = 0
	v1 = 0
	v2 = 0
	v3 = 0
	r0 = 0
	r1 = window
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'
'	PRINT "EventFocusOut().A : "; HEX$(who,8);; HEX$(window,8);; HEX$(modal,8);; HEX$(modalWindowSystem,8);; HEX$(modalWindowUser,8);; suppress
'
' to try to prevent loss of focus is to try to prevent
' other applications from being able to get keystrokes.
'
'	IF modal THEN
'		IF (window != modal) THEN
'			window = modal
'			swindow = window[window].swindow
'			sdisplay = window[window].sdisplay
'			##WHOMASK = 0
'			##LOCKOUT = $$TRUE
'			XSetInputFocus (sdisplay, swindow, $$RevertToParent, 0)
'			XSync (sdisplay, $$FALSE)
'			XBell (sdisplay, 0)
'			##LOCKOUT = $$FALSE
'			##WHOMASK = whomask
'			flushTime = eventTime
'		END IF
'	END IF
END FUNCTION
'
'
' ####################################
' #####  EventGraphicsExpose ()  #####
' ####################################
'
FUNCTION  EventGraphicsExpose (XGraphicsExposeEvent event)
'
	IF ##XBDV THEN PRINT "EventGraphicsExpose() : no action or message"
END FUNCTION
'
'
' ###################################
' #####  EventGravityNotify ()  #####
' ###################################
'
FUNCTION  EventGravityNotify (XGravityEvent event)
'
	IF ##XBDV THEN PRINT "EventGravityNotify() : no action or message"
END FUNCTION
'
'
' ##############################
' #####  EventKeyPress ()  #####
' ##############################
'
FUNCTION  EventKeyPress (XKeyEvent event)
	SHARED  WINDOW  window[]
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
	SHARED  eventTime
	SHARED	userCEO
	STATIC  keysym
	STATIC  buffer
'
'	PRINT "EventKeyPress(*) "
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventKeyPress()lockout", lockout) : lockout = 0
'
	eventTime = event.time
	sstate = event.state
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventKeyPress():Null window for system window", HEXX$(swindow)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventKeyPress() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	window = top
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventKeyPress() : invalid top window #"
		RETURN ($$TRUE)
	END IF
'
	who = window[window].whomask
	IF who THEN modal = modalWindowUser ELSE modal = modalWindowSystem
'
	IF modal THEN window = modal
'
	##WHOMASK = 0
	##LOCKOUT = 100174
	buffer$ = NULL$ (63)
	XLookupString (&event, &buffer, 63, &keysym, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ keysym THEN
		PRINT "EventKeyPress(0) state, keycode", HEXX$(event.state), HEXX$(event.keycode)
		RETURN ($$FALSE)
	END IF
'
	SystemKeyStateToKeyState (#WindowKeyDown, keysym, sstate, event.time, @state)
'
'
' If a program appears to be hung and mouse control buttons are
' not accessible, but key events are being processed,
' the program can be stopped by pressing the F4 key.
'
	vkey = state{$$VirtualKey}
'
	IF ##STANDALONE THEN
		IF (vkey == $$KeyF4) THEN QUIT (0)
	END IF
'
'
' If a user program has keyboard focus, it is usually handy for debugging,
' to have the Function keys able to step, pause, continue etc. the program
' using the F1 to F12 keys unless the user program has set userCEO in which
' case the user program has full control.
'
	IF who THEN
		IFZ modal THEN
			IFZ userCEO THEN
				IF (vkey >= $$KeyF1) && (vkey <= $$KeyF12) THEN
					XstGetConsoleGrid (@conGrid)
					IF conGrid THEN XgrGetGridWindow (conGrid, @window)
				END IF
			END IF
		END IF
	END IF
'
'
'	PRINT "EventKeyPress() sstate, keycode, keysym, state", HEXX$(event.state), HEXX$(event.keycode), HEXX$(keysym), HEXX$(state)
	message = #WindowKeyDown
	v0 = event.x
	v1 = event.y
	v2 = state
	v3 = event.time
	r0 = 0
	r1 = window
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'
'	EXIT FUNCTION    'comment out this line to drop through to debugging code
'
' For debugging purposes, set ##CAPSLOCK to state of the Num Lock key
' Xgr() checks Environment variable XBASICDEVELOPER="yes" to set ##XBDV to 0x12345678
'
	IF (##XBDV <> 0x12345678) THEN EXIT FUNCTION
'
'	PRINT HEXX$(keysym), HEXX$(sstate)
'
'
' This uses Num Lock key instead of Caps Lock
'
	IF (keysym == 0xFF7F) THEN
		IF (sstate == 0x10) THEN
			##CAPSLOCK = $$FALSE
			XstLog ("##CAPSLOCK OFF")
		ELSE
			##CAPSLOCK = 0x12345678
			XstLog ("##CAPSLOCK ON")
		END IF
		PRINT "##CAPSLOCK =", HEXX$(##CAPSLOCK)
	END IF
'
END FUNCTION
'
'
' ################################
' #####  EventKeyRelease ()  #####
' ################################
'
FUNCTION  EventKeyRelease (XKeyEvent event)
	SHARED  WINDOW  window[]
	SHARED  modalWindowSystem
	SHARED  modalWindowUser
	SHARED  eventTime
	AUTOX  keysym
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventKeyRelease()lockout", lockout) : lockout = 0
'
	eventTime = event.time
	sstate = event.state
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventKeyRelease():Null window for system window", HEXX$(swindow)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventKeyRelease() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	window = top
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventKeyRelease() : invalid top window #"
		RETURN ($$TRUE)
	END IF
'
	who = window[window].whomask
	IF who THEN modal = modalWindowUser ELSE modal = modalWindowSystem
'
	IF modal THEN window = modal
'
	##WHOMASK = 0
	##LOCKOUT = 100175
	buffer$ = NULL$ (63)
	XLookupString (&event, &buffer, 63, &keysym, 0)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ keysym THEN RETURN ($$FALSE)			' unrecognized keystroke
'
	SystemKeyStateToKeyState (#WindowKeyUp, keysym, sstate, event.time, @state)
'

	IF who THEN
		IFZ modal THEN
			vkey = state{$$VirtualKey}
			IF (vkey >= $$KeyF1) && (vkey <= $$KeyF12) THEN
				XstGetConsoleGrid (@conGrid)
				XgrGetGridWindow (conGrid, @window)
			END IF
		END IF
	END IF


'
	message = #WindowKeyUp
	v0 = event.x
	v1 = event.y
	v2 = state
	v3 = event.time
	r0 = 0
	r1 = window
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'
END FUNCTION
'
'
' ##################################
' #####  EventKeymapNotify ()  #####
' ##################################
'
FUNCTION  EventKeymapNotify (XKeymapEvent event)
'
	IF ##XBDV THEN PRINT "EventKeymapNotify() : no action or message"
END FUNCTION
'
'
' #################################
' #####  EventLeaveNotify ()  #####
' #################################
'
FUNCTION  EventLeaveNotify (XCrossingEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  eventTime
'
' The window manager generates EventLeaveNotify and EventEnterNotify when
' when mouse button one is pressed. These are not nesessary.
'
	IF (event.state AND $$Button1MotionMask) THEN RETURN
'
	eventTime = event.time
	subwindow = event.subwindow
	IF subwindow THEN RETURN									' skip parents
'
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventLeaveNotify():Null window for system window", HEXX$(swindow)
	grid = window
	window = top
'
	IF InvalidWindow (window) THEN
		IF ##XBDV THEN PRINT "EventLeaveNotify() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
' #WindowMouseExit message should be sent only when leaving a grid
'
	IF (grid == window) THEN RETURN ($$FALSE)
'
	IF InvalidGrid (grid) THEN
		IF ##XBDV THEN PRINT "EventLeaveNotify() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	stop = window[window].stop
	display = window[window].display
	sdisplay = window[window].sdisplay
'
	SystemButtonStateToButtonState (0, event.state, event.time, @state)
'
	message = #WindowMouseExit
	v0 = event.x
	v1 = event.y
	v2 = state
	v3 = event.time
	r0 = 0
	r1 = grid
'
' always remember last mouse event added to queue
'
	display[display].mouseX = v0
	display[display].mouseY = v1
	display[display].mouseState = v2
	display[display].mouseTime = v3
	display[display].mouseGrid = grid
	display[display].mouseWindow = window
	display[display].mouseMessage = message
	display[display].mouseFocusGrid = grid
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'	IF ##XBDV THEN PRINT "EventLeaveNotify()", grid, window, HEXX$(event.state), HEXX$(event.focus), HEXX$(event.sameScreen), HEXX$(event.detail), HEXX$(event.mode)
END FUNCTION
'
'
' ###############################
' #####  EventMapNotify ()  #####
' ###############################
'
FUNCTION  EventMapNotify (XMapEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  focusWhenMapped
	SHARED  doNotFocusWhenMapped
	SHARED  wmXoffset
	SHARED  wmYoffset
	AUTOX  ro, xo, yo, wo, ho, bo, do
	AUTOX  ri, xi, yi, wi, hi, bi, di
	STATIC sdisplay
	STATIC sFocusWindow, revertTo
	AUTOX  XWindowAttributes  winAttributes
'
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventMapNotify():Null window for system window", HEXX$(swindow)
'
	IF (window != top) THEN RETURN ($$FALSE)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventMapNotify() : invalid window #"; window
		RETURN ($$TRUE)
	END IF
'
	request = window[window].visibilityRequest
	window[window].visibilityRequest = -1
	window[window].mapped = $$TRUE
	message = #WindowDisplayed
	state = $$WindowDisplayed
'
	IF (request = $$WindowMaximized) THEN
		message = #WindowMaximized
		state = $$WindowMaximized
	END IF
'
	window[window].visibility = state
'
	v0 = 0
	v1 = 0
	v2 = 0
	v3 = 0
	r0 = 0
	r1 = window
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'
'
' The following code used to be in EventReparentNotify(), but the
' information returned by XGetGeometry() was not always accurate.
' The EventMapNotify() arrives later after the information has been updated.
'
	overrideRedirect = event.overrideRedirect
	display = window[window].display
	sroot = window[window].sroot									' system root window #
	windowType = window[window].type
	noSelect = windowType AND $$WindowTypeNoSelect
	sparent = window[window].sparent
	sroot = window[window].sroot
	sdisplay = event.display
'
	IF ##XBDV THEN
		wdpy = window[window].sdisplay
		IF (wdpy <> sdisplay) THEN XxxLog2 (@"EventMapNotify", wdpy)
	END IF
'
	IF (sroot = sparent) THEN
		IFF overrideRedirect THEN
			IF ##XBDV THEN PRINT "EventMapNotify():sroot = sparent", HEX$(sroot), HEX$(sparent), overrideRedirect
		END IF
	END IF
'
' Some window managers, such as KDE, create a parent window plus a parent of the parent (grampa) window
' and the information we need is in the parent and grampa windows
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	##WHOMASK = 0
	##LOCKOUT = 100176
	IF (sroot != sparent) THEN
		XQueryTree (sdisplay, sparent, &treeRoot, &sgrampa, &childArray, &count)
		IF (sgrampa == sroot) THEN                'gdm
			swinInner = swindow
			swinOutter = sparent
		ELSE                                      'kde
			swinInner = sparent
			swinOutter = sgrampa
		END IF
		rc1 = XGetGeometry (sdisplay, swinInner, &ri, &xi, &yi, &wi, &hi, &bi, &di)
		rc2 = XGetGeometry (sdisplay, swinOutter, &ro, &xo, &yo, &wo, &ho, &bo, &do)
	END IF
'
		XGetInputFocus (sdisplay, &sFocusWindow, &revertTo)
'
	IF (swindow == doNotFocusWhenMapped) THEN
		selectedWindow = display[1].selectedWindow
		IF selectedWindow THEN
			sSelectedWindow = window[selectedWindow].swindow
			XSetInputFocus (sdisplay, sSelectedWindow, $$RevertToParent, 0)
		END IF
		doNotFocusWhenMapped = 0
	END IF
'
	IF ( window == focusWhenMapped) THEN
		IFF (windowType AND $$WindowTypeNoSelect) THEN
			IF (swindow != sFocusWindow) THEN
				XSetInputFocus (sdisplay, swindow, $$RevertToParent, 0)
			END IF
		END IF
		focusWhenMapped = 0
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF noSelect THEN
		IF (swindow == sFocusWindow) THEN
			IF ##XBDV THEN PRINT "EventMapNotify()WindowTypeNoSelect is selected", window
		END IF
	END IF
'
' The following code modified the new window managers
' which have a large transparent border for resizing.
' But the offset for the x seems to be the opaque portion
' of the border. The y offset is different again.
'
	oldbw = window[window].borderWidth
	oldth = window[window].titleHeight
	oldx  = window[window].x
	oldy  = window[window].y
	oldw  = window[window].width
	oldh  = window[window].height
	oldXoffset = window[window].wmXoffset
	oldYoffset = window[window].wmYoffset
'
' If it is a fixed sized window, there is no transparent resizing border
'
	IF (window[window].type AND $$WindowTypeFixedSize) THEN
		xtest = wo - wi -  oldXoffset - oldXoffset
		IF (xtest AND ##XBDV) THEN
			PRINT "EventMapNotify(144)", HEXX$(window[window].type), xtest, wo, wi, oldXoffset, oldXoffset
		END IF
		ytest = ho - hi - oldth - oldXoffset - oldYoffset
		IF (xtest AND ##XBDV) THEN
			PRINT "EventMapNotify(148)", HEXX$(window[window].type), ytest, ho, hi, oldth, oldXoffset, oldYoffset
		END IF
		RETURN
	END IF
'
	newbw = (wo - wi) / 2
	newth = (ho - hi) - (wo - wi)
	newx  = xo + newbw
	newy  = yo + newbw + newth
	newXoffset = newx - (oldx - oldXoffset)
	newYoffset = (newy - newth) - ((oldy - oldth) - oldYoffset)
'
	SELECT CASE TRUE
		CASE newbw < 1
		CASE newbw > 15
		CASE newth < 1
		CASE newth > 40
		CASE newXoffset < 0
		CASE newXoffset > 15
		CASE newYoffset < 0
		CASE newx <= 0
		CASE newYoffset > 15
		CASE oldbw != newbw           : z = 1 : GOSUB Update
		CASE oldth != newth           : z = 2 : GOSUB Update
		CASE oldXoffset != newXoffset : z = 3 : GOSUB Update
		CASE oldYoffset != newYoffset : z = 4 : GOSUB Update
		CASE oldx != newx             : z = 5 : GOSUB Update
		CASE oldy != newy             : z = 6 : GOSUB Update
		CASE oldw != wi               : z = 7 : GOSUB Update
		CASE oldh != hi               : z = 8 : GOSUB Update
	END SELECT
'
'	RETURN
'
'----------------------------------------------------------------------------
'
'
' *****  Update  *****
'
SUB Update
	window[window].borderWidth   = newbw
	window[window].titleHeight   = newth
	window[window].x             = newx
	window[window].y             = newy
	window[window].wmXoffset     = newXoffset
	window[window].wmYoffset     = newYoffset
	window[window].width         = wi
	window[window].height        = hi
	#windowBorderWidth           = newbw
	#windowTitleHeight           = newth
	display[display].borderWidth = newbw
	display[display].titleHeight = newth
	display[display].wmXoffset   = newXoffset
	display[display].wmYoffset   = newYoffset
'	XgrSetWindowPositionAndSize (window, newx, newy, wi, hi)
'	XgrSetWindowPositionAndSize (window, newx, newy, oldw, oldh)
	XgrSetWindowPositionAndSize (window, oldx, oldy, oldw, oldh)
	IF ##XBDV THEN
		PRINT "EventMapNotify(281)Update", z, window, oldx, newx, oldy, newy, oldw, wi, oldh, hi
		PRINT "EventMapNotify(282)Update old-bw,th,x,y,xs,ys", oldbw, oldth, oldx, oldy, oldXoffset, oldYoffset
		PRINT "EventMapNotify(283)Update new-bw,th,x,y,xs,ys", newbw, newth, newx, newy, newXoffset, newYoffset
		PRINT "EventMapNotify(284)Update", sdisplay, swindow, ri, xi, yi, wi, hi, bi, di, x, y
		PRINT "EventMapNotify(285)Update", sroot, sgrampa, sparent, ro, xo, yo, wo, ho, bo, do
	END IF
END SUB
'
END FUNCTION
'
'
' ################################
' #####  EventMapRequest ()  #####
' ################################
'
FUNCTION  EventMapRequest (XMapRequestEvent event)
'
	IF ##XBDV THEN PRINT "EventMapRequest() : no action or message"
END FUNCTION
'
'
' ###################################
' #####  EventMappingNotify ()  #####
' ###################################
'
FUNCTION  EventMappingNotify (XMappingEvent event)
'
	IF ##XBDV THEN PRINT "EventMappingNotify() : no action or message"
END FUNCTION
'
'
' ##################################
' #####  EventMotionNotify ()  #####
' ##################################
'
' generate #WindowMouseMove or #WindowMouseDrag only if window owner queue is empty
'
FUNCTION  EventMotionNotify (XMotionEvent event)
	SHARED  DISPLAY  display[]
	SHARED  WINDOW  window[]
	SHARED  MESSAGE  message[]
	SHARED  eventTime
	SHARED  userCount
	SHARED  sysCount
	SHARED  userOut
	SHARED  sysOut
	SHARED  userIn
	SHARED  sysIn
	SHARED  inHold
	SHARED  inQueue
'
	eventTime = event.time
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @grid, @window) THEN RETURN ($$FALSE)
'
	IFZ window THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventMotionNotify() : invalid window #"; window, HEXX$(swindow)
		RETURN ($$TRUE)
	END IF
'
	IFZ grid THEN
		##ERROR = ($$ErrorObjectGrid << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventMotionNotify() : invalid grid #"; grid
		RETURN ($$TRUE)
	END IF
'
	stop = window[window].stop
	display = window[window].display
	sdisplay = window[window].sdisplay
'
	mouseX = display[display].mouseX
	mouseY = display[display].mouseY
	mouseState = display[display].mouseState
	mouseTime = display[display].mouseTime
'
'
' look for another later EventMotionNotify message for this same window
'
	DO
		more = 0
		##WHOMASK = 0
		##LOCKOUT = 100177
		more = XCheckTypedWindowEvent (sdisplay, swindow, event.type, &event)
		##LOCKOUT = lockout
		##WHOMASK = whomask
	LOOP WHILE more
	eventTime = event.time
'
	SystemButtonStateToButtonState (0, event.state, event.time, @state)
'	PRINT "EventMotionNotify() : "; HEX$(event.state,8);; HEX$(state,8);;
'
	change = $$FALSE
	eventButtons = state AND $$MouseButtonMask
	mouseButtons = mouseState AND $$MouseButtonMask
	IF (mouseX != event.x) THEN change = $$TRUE
	IF (mouseY != event.y) THEN change = $$TRUE
	IF (mouseButtons != eventButtons) THEN change = $$TRUE
'
'	PRINT HEX$(eventButtons,8);; HEX$(mouseButtons,8)
'
	IFZ change THEN
'		PRINT "EventMotionNotify() : no change"
		RETURN ($$FALSE)
	END IF
'
	queue = 0																		' system queue
	IF window[window].whomask THEN queue = 1		' user queue
	GOSUB UpdateVariables												' queue state
'
	IF count THEN																' queue not empty
		IFZ eventButtons THEN											' no buttons down
'			x = message[queue,out].r1
'			g = message[queue,out].wingrid
'			mess = message[queue,out].message
'			XgrMessageNumberToName (mess, @mess$)
'			PRINT "EventMotionNotify() : trash motion event because queue is not empty : "; queue;; count;; out;; in;; g;; mess$;; x
			RETURN ($$FALSE)
		END IF
	END IF
'
	message = #WindowMouseMove
	IF eventButtons THEN message = #WindowMouseDrag
'
	v0 = event.x
	v1 = event.y
	v2 = state
	v3 = event.time
	r0 = 0
	r1 = grid
'
' remember last mouse event added to queue
'
	display[display].mouseX = v0
	display[display].mouseY = v1
	display[display].mouseState = v2
	display[display].mouseTime = v3
	display[display].mouseGrid = grid
	display[display].mouseWindow = window
	display[display].mouseMessage = message
	display[display].mouseFocusGrid = grid
'
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
	RETURN ($$FALSE)
'
'
' *****  UpdateVariables  *****
'
SUB UpdateVariables
	IF inQueue THEN PRINT "EventMotionNotify() : inQueue"
	inQueue = $$TRUE
	IF queue THEN
		count = userCount
		out = userOut
		in = userIn
	ELSE
		count = sysCount
		out = sysOut
		in = sysIn
	END IF
	inQueue = $$FALSE
	IF inHold THEN EmptyHoldingQueue ()
END SUB
'
'
' ****  DoXCheck  ****    '*cw* 230107
'
SUB DoXCheck
	more = XCheckTypedWindowEvent (sdisplay, swindow, event.type, &event)
END SUB
'
END FUNCTION
'
'
' ##############################
' #####  EventNoExpose ()  #####
' ##############################
'
FUNCTION  EventNoExpose (XNoExposeEvent event)
'
'	IF ##XBDV THEN PRINT "EventNoExpose() : no action or message"
'
END FUNCTION
'
'
' ####################################
' #####  EventPropertyNotify ()  #####
' ####################################
'
FUNCTION  EventPropertyNotify (XPropertyEvent event)
'
'	IF ##XBDV THEN PRINT "EventPropertyNotify() : no action or message"
END FUNCTION
'
'
' ####################################
' #####  EventReparentNotify ()  #####
' ####################################
'
FUNCTION  EventReparentNotify (XReparentEvent event)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventReparentNotify()lockout", lockout) : lockout = 0
'
	swindow = event.window
	sparent = event.parent
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)  ' window being destroyed?
'
	IFZ window THEN
		##ERROR = ($$ErrorObjectWindow << 8) OR $$ErrorNatureNonexistent
		IF ##XBDV THEN PRINT "EventReparentNotify() : invalid window"
		RETURN ($$TRUE)
	END IF
'
	window[window].sparent = sparent		' new system parent #
'
END FUNCTION
'
'
' ###################################
' #####  EventResizeRequest ()  #####
' ###################################
'
FUNCTION  EventResizeRequest (XResizeRequestEvent event)
'
	IF ##XBDV THEN PRINT "EventResizeRequest() : no action or message"
END FUNCTION
'
'
' ####################################
' #####  EventSelectionClear ()  #####
' ####################################
'
FUNCTION  EventSelectionClear (XSelectionClearEvent event)
	SHARED  eventTime
'
	eventTime = event.time
'	IF ##XBDV THEN PRINT "EventSelectionClear() : no action or message"
END FUNCTION
'
'
' #####################################
' #####  EventSelectionNotify ()  #####
' #####################################
'
FUNCTION  EventSelectionNotify (XSelectionEvent event)
	SHARED  eventTime
	SHARED  XSelectionEvent  selectionNotify
'
	eventTime = event.time
	selectionNotify = event
'
'	PRINT "EventSelectionNotify()"
'	PRINT "#sdisplayEternal  = "; HEX$(#sdisplayEternal,8)
'	PRINT "#swindowEternal   = "; HEX$(#swindowEternal,8)
'	PRINT "event.type        = "; HEX$(event.type,8);;			HEX$($$SelectionNotify,8)
'	PRINT "event.serial      = "; HEX$(event.serial,8)
'	PRINT "event.sendEvent   = "; HEX$(event.sendEvent,8)
'	PRINT "event.display     = "; HEX$(event.display,8)
'	PRINT "event.requestor   = "; HEX$(event.requestor,8)
'	PRINT "event.selection   = "; HEX$(event.selection,8)
'	PRINT "event.target      = "; HEX$(event.target,8)
'	PRINT "event.property    = "; HEX$(event.property,8)
'	PRINT "event.time        = "; HEX$(event.time,8)
END FUNCTION
'
'
' ######################################
' #####  EventSelectionRequest ()  #####
' ######################################
'
FUNCTION  EventSelectionRequest (XSelectionRequestEvent event)
	SHARED  UBYTE  clipData[]
	SHARED  clipText$[]
	SHARED	clipType[]
	SHARED  eventTime
	XSelectionEvent  notify
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"EventSelectionRequest()lockout", lockout) : lockout = 0
'
	IFZ clipType[] THEN
		##WHOMASK = 0
		##LOCKOUT = 100178
		DIM clipType[7]
		DIM clipText$[7]
		DIM clipData[7,]
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
		FOR i = 0 TO 7
			clipType[i] = $$ClipboardTypeNone				' no contents
		NEXT i
	END IF
'
'	PRINT "EventSelectionRequest() : "; HEX$(event.display,8);; HEX$(event.owner,8);; HEX$(event.requestor,8);; HEX$(event.selection,8);; HEX$(event.target,8);; HEX$(event.property,8)
'
	eventTime = event.time
	selection = event.selection				' should be #XA_PRIMARY/#XA_CLIPBOARD
	swindow = event.requestor
	sdisplay = event.display
	target = event.target							' type of data wanted : #XA_DIB, #XA_STRING, #XA_PIXMAP
'
	IFZ clipType[] THEN RETURN				' no clipboards defined
	clipType = clipType[0]						' does interapplication clipboard have text and/or data ?
	IFZ clipType THEN RETURN					' clipboard has no text and no data
'
	SELECT CASE target
		CASE #XA_DIB			: GOSUB dib						' DIB aka "device independent bitmap" image
		CASE #XA_STRING		: GOSUB text					' text string
		CASE ELSE					: GOSUB unsupported		' unsupported type
	END SELECT
	RETURN
'
SUB dib
	notify.type = $$SelectionNotify			' event type = SelectionNotify
	notify.serial = event.serial				' from incoming SelectionRequest event
	notify.sendEvent = 1								' gonna XSendEvent() this event to requestor
	notify.display = event.display			' return display of requestor SelectionRequest event
	notify.requestor = event.requestor	' return requestor from requestor SelectionRequest event
	notify.selection = event.selection	' return selection from requestor SelectionRequest event
	notify.target = event.target				' return target type from requestor SelectionRequest event
	notify.property = $$FALSE						' unsupported type - cannot supply data as requested type
	notify.time = eventTime							' return event time from requestor SelectionRequest event
'
	##WHOMASK = 0
	##LOCKOUT = 100179
	XSendEvent (sdisplay, swindow, 1, 0, &notify)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END SUB
'
SUB text
	notify.type = $$SelectionNotify			' event type = SelectionNotify
	notify.serial = event.serial				' from incoming SelectionRequest event
	notify.sendEvent = 1								' gonna XSendEvent() this event to requestor
	notify.display = event.display			' return display of requestor SelectionRequest event
	notify.requestor = event.requestor	' return requestor from requestor SelectionRequest event
	notify.selection = event.selection	' return selection from requestor SelectionRequest event
	notify.target = event.target				' return target type from requestor SelectionRequest event
	notify.property = event.property		' return target property from requestor SelectRequest event
	notify.time = event.time						' return event time from requestor SelectionRequest event
'
	sdisplay = event.display
	swindow = event.requestor
	property = event.property
	format = 8
	mode = $$PropModeReplace
	text = &clipText$[0]
	length = LEN(clipText$[0])
'
	##WHOMASK = 0
	##LOCKOUT = 100180
	a = XChangeProperty (sdisplay, swindow, property, #XA_STRING, format, mode, text, length)
	b = XSendEvent (sdisplay, swindow, 0, 0, &notify)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	PRINT "EventSelectionRequest()"
'	PRINT "#sdisplayEternal  = "; HEX$(#sdisplayEternal,8)
'	PRINT "#swindowEternal   = "; HEX$(#swindowEternal,8)
'	PRINT "event.type        = "; HEX$(event.type,8);;				HEX$(notify.type,8);;		HEX$($$SelectionRequest,8)
'	PRINT "event.serial      = "; HEX$(event.serial,8);;			HEX$(notify.serial,8)
'	PRINT "event.sendEvent   = "; HEX$(event.sendEvent,8);;		HEX$(notify.sendEvent,8)
'	PRINT "event.display     = "; HEX$(event.display,8);;			HEX$(notify.display,8)
'	PRINT "event.owner       = "; HEX$(event.owner,8)
'	PRINT "event.requestor   = "; HEX$(event.requestor,8);;		HEX$(notify.requestor,8)
'	PRINT "event.selection   = "; HEX$(event.selection,8);;		HEX$(notify.selection,8)
'	PRINT "event.target      = "; HEX$(event.target,8);;			HEX$(notify.target,8)
'	PRINT "event.property    = "; HEX$(event.property,8);;		HEX$(notify.property,8)
'	PRINT "event.time        = "; HEX$(event.time,8);;				HEX$(notify.time,8)
'	PRINT "sdisplay          = "; HEX$(sdisplay,8);; 					"XChangeProperty ( arg 1 )
'	PRINT "swindow           = "; HEX$(swindow,8);;						"XChangeProperty ( arg 2 )
'	PRINT "#XA_PRIMARY       = "; HEX$(#XA_PRIMARY,8);;				"XChangeProperty ( arg 3 )
'	PRINT "#XA_CLIPBOARD     = "; HEX$(#XA_CLIPBOARD,8);;			"XChangeProperty ( arg 3 )
'	PRINT "#XA_STRING        = "; HEX$(#XA_STRING,8);;				"XChangeProperty ( arg 4 )
'	PRINT "format            = "; HEX$(format,8);;						"XChangeProperty ( arg 5 )
'	PRINT "mode              = "; HEX$(mode,8);;							"XChangeProperty ( arg 6 )
'	PRINT "data aka &text$   = "; HEX$(text,8);;							"XChangeProperty ( arg 7 )
'	PRINT "elements          = "; HEX$(length,8);;						"XChangeProperty ( arg 8 )
'	PRINT "EventSelectionRequest() : "; HEX$(sdisplay,8);; HEX$(#swindowEternal,8);; HEX$(swindow,8);; #XA_STRING;; 8;; mode;; HEX$(&text$,8);; length;; a;; b
'	PRINT "("; CSTRING$ (text); ")"
'	addr = XGetAtomName (sdisplay, event.property)
'	atom$ = CSTRING$ (addr)
'	PRINT ":"; atom$; ":"
'	XFree (addr)
END SUB
'
SUB unsupported
	notify.type = $$SelectionNotify			' event type = SelectionNotify
	notify.serial = event.serial				' from incoming SelectionRequest event
	notify.sendEvent = 1								' gonna XSendEvent() this event to requestor
	notify.display = event.display			' return display of requestor SelectionRequest event
	notify.requestor = event.requestor	' return requestor from requestor SelectionRequest event
	notify.selection = event.selection	' return selection from requestor SelectionRequest event
	notify.target = event.target				' return target type from requestor SelectionRequest event
	notify.property = $$FALSE						' unsupported type - cannot supply data as requested type
	notify.time = event.time						' return event time from requestor SelectionRequest event
'
	##WHOMASK = 0
	##LOCKOUT = 100181
	XSendEvent (sdisplay, swindow, 1, 0, &notify)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END SUB
'
END FUNCTION
'
'
' #################################
' #####  EventUnmapNotify ()  #####
' #################################
'
FUNCTION  EventUnmapNotify (XUnmapEvent event)
	SHARED  WINDOW  window[]
'
	swindow = event.window
	IF XgrSystemWindowToWindow (swindow, @window, @top) THEN RETURN ($$FALSE)
	IFZ window THEN PRINT "EventUnmapNotify():Null window for system window", HEXX$(swindow)
'
	IF InvalidWinGrid (window) THEN
		IF ##XBDV THEN PRINT "EventUnmapNotify() : invalid window #"; window;;; HEX$(swindow)
		RETURN ($$TRUE)
	END IF
'
	IF (window != top) THEN RETURN							' for windows, not grids
'
	request = window[window].visibilityRequest
	window[window].visibilityRequest = -1
	window[window].mapped = $$FALSE
	message = #WindowHidden
	state = $$WindowHidden
'
	IF (request = $$WindowMinimized) THEN
		message = #WindowMinimized
		state = $$WindowMinimized
	END IF
'
	state = $$WindowHidden							' !!!!!!!
	message = #WindowHidden							' !!!!!!!
'
	window[window].visibility = state
'
' send message to windows, not grids
'
	v0 = 0
	v1 = 0
	v2 = 0
	v3 = 0
	r0 = 0
	r1 = window
	XgrAddMessage (window, message, v0, v1, v2, v3, r0, r1)
'
END FUNCTION
'
'
' ######################################
' #####  EventVisibilityNotify ()  #####
' ######################################
'
FUNCTION  EventVisibilityNotify (XVisibilityEvent event)
'
'	IF ##XBDV THEN PRINT "EventVisibilityNotify() : no action or message"
'	IF ##XBDV THEN PrintVisibilityNotify (event)
END FUNCTION
'
'
' ###################################
' #####  PrintWindowAttributes  #####
' ###################################
'
FUNCTION  PrintWindowAttributes (XWindowAttributes attr)
'
	PRINT " PrintWindowAttributes()"
	PRINT "    .x      .y           = "; HEX$(attr.x, 8);; HEX$ (attr.y, 8)
	PRINT "    .width  .height      = "; HEX$(attr.width,8);; HEX$(attr.height,8)
	PRINT "    .borderWidth         = "; HEX$(attr.borderWidth, 8)
	PRINT "    .depth               = "; HEX$(attr.depth,  8)
	PRINT "    .visual              = "; HEX$(attr.visual, 8)
	PRINT "    .root                = "; HEX$(attr.root, 8)
	PRINT "    .class               = "; HEX$(attr.class, 8)
	PRINT "    .bitGravity          = "; HEX$(attr.bitGravity, 8)
	PRINT "    .winGravity          = "; HEX$(attr.winGravity, 8)
	PRINT "    .backingStore        = "; HEX$(attr.backingStore, 8)
	PRINT "    .backingPlanes       = "; HEX$(attr.backingPlanes, 8)
	PRINT "    .backingPixel        = "; HEX$(attr.backingPixel, 8)
	PRINT "    .saveUnder           = "; HEX$(attr.saveUnder, 8)
	PRINT "    .colormap            = "; HEX$(attr.colormap, 8)
	PRINT "    .mapInstalled        = "; HEX$(attr.mapInstalled, 8)
	PRINT "    .mapState            = "; HEX$(attr.mapState, 8)
	PRINT "    .allEventMasks       = "; HEX$(attr.allEventMasks, 8)
	PRINT "    .yourEventMask       = "; HEX$(attr.yourEventMask, 8)
	PRINT "    .doNotPropagateMask  = "; HEX$(attr.doNotPropagateMask, 8)
	PRINT "    .overrideRedirect    = "; HEX$(attr.overrideRedirect, 8)
	PRINT "    .screen              = "; HEX$(attr.screen, 8)
	PRINT
END FUNCTION
'
'
' #################################
' #####  PrintButtonPress ()  #####
' #################################
'
FUNCTION  PrintButtonPress (XButtonEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.root);; HEX$(event.subwindow);; event.x; event.y;; HEX$(event.state);; HEX$(event.button)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".root                = "; HEX$ (event.root, 8)
	PRINT ".subwindow           = "; HEX$ (event.subwindow, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
	PRINT ".button              = "; HEX$ (event.button, 8)
	PRINT ".sameScreen          = "; HEX$ (event.sameScreen, 8)
END SUB
END FUNCTION
'
'
' ###################################
' #####  PrintButtonRelease ()  #####
' ###################################
'
FUNCTION  PrintButtonRelease (XButtonEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.root);; HEX$(event.subwindow);; event.x; event.y;; HEX$(event.state);; HEX$(event.button)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".root                = "; HEX$ (event.root, 8)
	PRINT ".subwindow           = "; HEX$ (event.subwindow, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
	PRINT ".button              = "; HEX$ (event.button, 8)
	PRINT ".sameScreen          = "; HEX$ (event.sameScreen, 8)
END SUB
END FUNCTION
'
'
' #####################################
' #####  PrintCirculateNotify ()  #####
' #####################################
'
FUNCTION  PrintCirculateNotify (XCirculateEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.event);; HEX$(event.window);; HEX$(event.place)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".event               = "; HEX$ (event.event, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".place               = "; HEX$ (event.place, 8)
END SUB
END FUNCTION
'
'
' ######################################
' #####  PrintCirculateRequest ()  #####
' ######################################
'
FUNCTION  PrintCirculateRequest (XCirculateRequestEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.parent);; HEX$(event.window);; HEX$(event.place)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".parent              = "; HEX$ (event.parent, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".place               = "; HEX$ (event.place, 8)
END SUB
END FUNCTION
'
'
' ###################################
' #####  PrintClientMessage ()  #####
' ###################################
'
FUNCTION  PrintClientMessage (XClientMessageEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.messageType);; HEX$(event.format);; HEX$(event.data[0]);; HEX$(event.data[1]);; HEX$(event.data[2]);; HEX$(event.data[3]);; HEX$(event.data[4])
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; "$$ClientMessage"
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".messageType         = "; HEX$ (event.messageType, 8)
	PRINT ".format              = "; HEX$ (event.format, 8)
	PRINT ".data[0]             = "; HEX$ (event.data[0], 8)
	PRINT ".data[1]             = "; HEX$ (event.data[1], 8)
	PRINT ".data[2]             = "; HEX$ (event.data[2], 8)
	PRINT ".data[3]             = "; HEX$ (event.data[3], 8)
	PRINT ".data[4]             = "; HEX$ (event.data[4], 8)
END SUB
END FUNCTION
'
'
' ####################################
' #####  PrintColormapNotify ()  #####
' ####################################
'
FUNCTION  PrintColormapNotify (XColormapEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.colormap);; HEX$(event.new);; HEX$(event.state)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".colormap            = "; HEX$ (event.colormap, 8)
	PRINT ".new                 = "; HEX$ (event.new, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
END SUB
END FUNCTION
'
'
' #####################################
' #####  PrintConfigureNotify ()  #####
' #####################################
'
FUNCTION  PrintConfigureNotify (XConfigureEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.event);; HEX$(event.window);; HEX$(event.x);; HEX$(event.y);; HEX$(event.width);; HEX$(event.height);; HEX$(event.borderWidth);; HEX$(event.above);; HEX$(event.overrideRedirect)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".event               = "; HEX$ (event.event, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".width               = "; HEX$ (event.width, 8)
	PRINT ".height              = "; HEX$ (event.height, 8)
	PRINT ".borderWidth         = "; HEX$ (event.borderWidth, 8)
	PRINT ".above               = "; HEX$ (event.above, 8)
	PRINT ".overrideRedirect    = "; HEX$ (event.overrideRedirect, 8)
END SUB
END FUNCTION
'
'
' ######################################
' #####  PrintConfigureRequest ()  #####
' ######################################
'
FUNCTION  PrintConfigureRequest (XConfigureRequestEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.parent);; HEX$(event.window);; HEX$(event.x);; HEX$(event.y);; HEX$(event.width);; HEX$(event.height);; HEX$(event.borderWidth);; HEX$(event.above);; HEX$(event.detail);; HEX$(event.valuemask)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".parent              = "; HEX$ (event.parent, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".width               = "; HEX$ (event.width, 8)
	PRINT ".height              = "; HEX$ (event.height, 8)
	PRINT ".borderWidth         = "; HEX$ (event.borderWidth, 8)
	PRINT ".above               = "; HEX$ (event.above, 8)
	PRINT ".detail              = "; HEX$ (event.detail, 8)
	PRINT ".valuemask           = "; HEX$ (event.valuemask, 8)
END SUB
END FUNCTION
'
'
' ##################################
' #####  PrintCreateNotify ()  #####
' ##################################
'
FUNCTION  PrintCreateNotify (XCreateWindowEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.parent);; HEX$(event.window);; HEX$(event.x);; HEX$(event.y);; HEX$(event.width);; HEX$(event.height);; HEX$(event.borderWidth);; HEX$(event.overrideRedirect)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".parent              = "; HEX$ (event.parent, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".width               = "; HEX$ (event.width, 8)
	PRINT ".height              = "; HEX$ (event.height, 8)
	PRINT ".borderWidth         = "; HEX$ (event.borderWidth, 8)
	PRINT ".overrideRedirect    = "; HEX$ (event.overrideRedirect, 8)
END SUB
END FUNCTION
'
'
' ###################################
' #####  PrintDestroyNotify ()  #####
' ###################################
'
FUNCTION  PrintDestroyNotify (XDestroyWindowEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.event);; HEX$(event.window)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".event               = "; HEX$ (event.event, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
END SUB
END FUNCTION
'
'
' #################################
' #####  PrintEnterNotify ()  #####
' #################################
'
FUNCTION  PrintEnterNotify (XCrossingEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.root);; HEX$(event.subwindow);; HEX$(event.time);;  HEX$(event.x);; HEX$(event.y);; HEX$(event.xRoot);; HEX$(event.yRoot);; HEX$(event.mode);; HEX$(event.detail);; HEX$(event.focus);; HEX$(event.state)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".root                = "; HEX$ (event.root, 8)
	PRINT ".subwindow           = "; HEX$ (event.subwindow, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".xRoot               = "; HEX$ (event.xRoot, 8)
	PRINT ".yRoot               = "; HEX$ (event.yRoot, 8)
	PRINT ".mode                = "; HEX$ (event.mode, 8)
	PRINT ".detail              = "; HEX$ (event.detail, 8)
	PRINT ".focus               = "; HEX$ (event.focus, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
END SUB
END FUNCTION
'
'
' ############################
' #####  PrintErrorX ()  #####
' ############################
'
FUNCTION  PrintErrorX (XErrorEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; HEX$(event.resourceid);; HEX$(event.errorCode);; HEX$(event.requestCode);; HEX$(event.minorCode)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".resourceid          = "; HEX$ (event.resourceid, 8)
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".errorCode           = "; HEX$ (event.errorCode, 8)
	PRINT ".requestCode         = "; HEX$ (event.requestCode, 8)
	PRINT ".minorCode           = "; HEX$ (event.minorCode, 8)
END SUB
END FUNCTION
'
'
' ############################
' #####  PrintExpose ()  #####
' ############################
'
FUNCTION  PrintExpose (XExposeEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.x);; HEX$(event.y);; HEX$(event.width);; HEX$(event.height);; HEX$(event.count)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".width               = "; HEX$ (event.width, 8)
	PRINT ".height              = "; HEX$ (event.height, 8)
	PRINT ".count               = "; HEX$ (event.count, 8)
END SUB
END FUNCTION
'
'
' #############################
' #####  PrintFocusIn ()  #####
' #############################
'
FUNCTION  PrintFocusIn (XFocusChangeEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.mode);; HEX$(event.detail)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".mode                = "; HEX$ (event.mode, 8)
	PRINT ".detail              = "; HEX$ (event.detail, 8)
END SUB
END FUNCTION
'
'
' ##############################
' #####  PrintFocusOut ()  #####
' ##############################
'
FUNCTION  PrintFocusOut (XFocusChangeEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.mode);; HEX$(event.detail)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".mode                = "; HEX$ (event.mode, 8)
	PRINT ".detail              = "; HEX$ (event.detail, 8)
END SUB
END FUNCTION
'
'
' ####################################
' #####  PrintGraphicsExpose ()  #####
' ####################################
'
FUNCTION  PrintGraphicsExpose (XGraphicsExposeEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.drawable);; HEX$(event.x);; HEX$(event.y);; HEX$(event.width);; HEX$(event.height);; HEX$(event.count);; HEX$(event.majorCode);; HEX$(event.minorCode)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".drawable            = "; HEX$ (event.drawable, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".width               = "; HEX$ (event.width, 8)
	PRINT ".height              = "; HEX$ (event.height, 8)
	PRINT ".count               = "; HEX$ (event.count, 8)
	PRINT ".majorCode           = "; HEX$ (event.majorCode, 8)
	PRINT ".minorCode           = "; HEX$ (event.minorCode, 8)
END SUB
END FUNCTION
'
'
' ###################################
' #####  PrintGravityNotify ()  #####
' ###################################
'
FUNCTION  PrintGravityNotify (XGravityEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.event);; HEX$(event.window);; HEX$(event.x);; HEX$(event.y)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".event               = "; HEX$ (event.event, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
END SUB
END FUNCTION
'
'
' ##############################
' #####  PrintKeyPress ()  #####
' ##############################
'
FUNCTION  PrintKeyPress (XKeyEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.root);; HEX$(event.subwindow);; HEX$(event.time);; HEX$(event.x);; HEX$(event.y);; HEX$(event.state);; HEX$(event.keycode)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".xRoot               = "; HEX$ (event.xRoot, 8)
	PRINT ".yRoot               = "; HEX$ (event.yRoot, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
	PRINT ".keycode             = "; HEX$ (event.keycode, 8)
	PRINT ".sameScreen          = "; HEX$ (event.sameScreen, 8)
END SUB
END FUNCTION
'
'
' ################################
' #####  PrintKeyRelease ()  #####
' ################################
'
FUNCTION  PrintKeyRelease (XKeyEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.root);; HEX$(event.subwindow);; HEX$(event.time);; HEX$(event.x);; HEX$(event.y);; HEX$(event.state);; HEX$(event.keycode)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".xRoot               = "; HEX$ (event.xRoot, 8)
	PRINT ".yRoot               = "; HEX$ (event.yRoot, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
	PRINT ".keycode             = "; HEX$ (event.keycode, 8)
	PRINT ".sameScreen          = "; HEX$ (event.sameScreen, 8)
END SUB
END FUNCTION
'
'
' ##################################
' #####  PrintKeymapNotify ()  #####
' ##################################
'
FUNCTION  PrintKeymapNotify (XKeymapEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window)  ';; HEX$(event.x);; HEX$(event.y);; HEX$(event.width);; HEX$(event.height);; HEX$(event.count)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
'	PRINT ".x                   = "; HEX$ (event.x, 8)
'	PRINT ".y                   = "; HEX$ (event.y, 8)
'	PRINT ".width               = "; HEX$ (event.width, 8)
'	PRINT ".height              = "; HEX$ (event.height, 8)
'	PRINT ".count               = "; HEX$ (event.count, 8)
END SUB
END FUNCTION
'
'
' #################################
' #####  PrintLeaveNotify ()  #####
' #################################
'
FUNCTION  PrintLeaveNotify (XCrossingEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.root);; HEX$(event.subwindow);; HEX$(event.time);;  HEX$(event.x);; HEX$(event.y);; HEX$(event.xRoot);; HEX$(event.yRoot);; HEX$(event.mode);; HEX$(event.detail);; HEX$(event.focus);; HEX$(event.state)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".root                = "; HEX$ (event.root, 8)
	PRINT ".subwindow           = "; HEX$ (event.subwindow, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".xRoot               = "; HEX$ (event.xRoot, 8)
	PRINT ".yRoot               = "; HEX$ (event.yRoot, 8)
	PRINT ".mode                = "; HEX$ (event.mode, 8)
	PRINT ".detail              = "; HEX$ (event.detail, 8)
	PRINT ".focus               = "; HEX$ (event.focus, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
END SUB
END FUNCTION
'
'
' ###############################
' #####  PrintMapNotify ()  #####
' ###############################
'
FUNCTION  PrintMapNotify (XMapEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.event);; HEX$(event.window);; HEX$(event.overrideRedirect)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".event               = "; HEX$ (event.event, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".overrideRedirect    = "; HEX$ (event.overrideRedirect, 8)
END SUB
END FUNCTION
'
'
' ################################
' #####  PrintMapRequest ()  #####
' ################################
'
FUNCTION  PrintMapRequest (XMapRequestEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.parent);; HEX$(event.window)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".parent              = "; HEX$ (event.parent, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
END SUB
END FUNCTION
'
'
' ###################################
' #####  PrintMappingNotify ()  #####
' ###################################
'
FUNCTION  PrintMappingNotify (XMappingEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.request);; HEX$(event.firstKeycode);; HEX$(event.count)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".request             = "; HEX$ (event.request, 8)
	PRINT ".firstKeycode        = "; HEX$ (event.firstKeycode, 8)
	PRINT ".count               = "; HEX$ (event.count, 8)
END SUB
END FUNCTION
'
'
' ##################################
' #####  PrintMotionNotify ()  #####
' ##################################
'
FUNCTION  PrintMotionNotify (XMotionEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.root);; HEX$(event.subwindow);; HEX$(event.time);; HEX$(event.xRoot);; HEX$(event.yRoot);; HEX$(event.state);; HEX$(event.isHint)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".root                = "; HEX$ (event.root, 8)
	PRINT ".subwindow           = "; HEX$ (event.subwindow, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
	PRINT ".xRoot               = "; HEX$ (event.xRoot, 8)
	PRINT ".yRoot               = "; HEX$ (event.yRoot, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
	PRINT ".isHint              = "; HEX$ (event.isHint, 8)
	PRINT ".sameScreen          = "; HEX$ (event.sameScreen, 8)
END SUB
END FUNCTION
'
'
' ##############################
' #####  PrintNoExpose ()  #####
' ##############################
'
FUNCTION  PrintNoExpose (XNoExposeEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.drawable);; HEX$(event.majorOpcode);; HEX$(event.minorOpcode)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".drawable            = "; HEX$ (event.drawable, 8)
	PRINT ".majorOpcode         = "; HEX$ (event.majorOpcode, 8)
	PRINT ".minorOpcode         = "; HEX$ (event.minorOpcode, 8)
END SUB
END FUNCTION
'
'
' ####################################
' #####  PrintPropertyNotify ()  #####
' ####################################
'
FUNCTION  PrintPropertyNotify (XPropertyEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.atom);; HEX$(event.time);; HEX$(event.state)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".atom                = "; HEX$ (event.atom, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
END SUB
END FUNCTION
'
'
' ####################################
' #####  PrintReparentNotify ()  #####
' ####################################
'
FUNCTION  PrintReparentNotify (XReparentEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.event);; HEX$(event.window);; HEX$(event.parent);; HEX$(event.x);; HEX$(event.y);; HEX$(overrideRedirect)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".event               = "; HEX$ (event.event, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".parent              = "; HEX$ (event.parent, 8)
	PRINT ".x                   = "; HEX$ (event.x, 8)
	PRINT ".y                   = "; HEX$ (event.y, 8)
	PRINT ".overrideRedirect    = "; HEX$ (event.overrideRedirect, 8)
END SUB
END FUNCTION
'
'
' ###################################
' #####  PrintResizeRequest ()  #####
' ###################################
'
FUNCTION  PrintResizeRequest (XResizeRequestEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.width);; HEX$(event.height)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".width               = "; HEX$ (event.width, 8)
	PRINT ".height              = "; HEX$ (event.height, 8)
END SUB
END FUNCTION
'
'
' ####################################
' #####  PrintSelectionClear ()  #####
' ####################################
'
FUNCTION  PrintSelectionClear (XSelectionClearEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.atom);; HEX$(event.time)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".atom                = "; HEX$ (event.atom, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
END SUB
END FUNCTION
'
'
' #####################################
' #####  PrintSelectionNotify ()  #####
' #####################################
'
FUNCTION  PrintSelectionNotify (XSelectionEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.requestor);; HEX$(event.selection);; HEX$(event.target);; HEX$(event.property);; HEX$(event.time)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".requestor           = "; HEX$ (event.requestor, 8)
	PRINT ".selection           = "; HEX$ (event.selection, 8)
	PRINT ".target              = "; HEX$ (event.target, 8)
	PRINT ".property            = "; HEX$ (event.property, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
END SUB
END FUNCTION
'
'
' ######################################
' #####  PrintSelectionRequest ()  #####
' ######################################
'
FUNCTION  PrintSelectionRequest (XSelectionRequestEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.owner);; HEX$(event.requestor);; HEX$(event.selection);; HEX$(event.target);; HEX$(event.property);; HEX$(event.time)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".requestor           = "; HEX$ (event.requestor, 8)
	PRINT ".selection           = "; HEX$ (event.selection, 8)
	PRINT ".target              = "; HEX$ (event.target, 8)
	PRINT ".property            = "; HEX$ (event.property, 8)
	PRINT ".time                = "; HEX$ (event.time, 8)
END SUB
END FUNCTION
'
'
' #################################
' #####  PrintUnmapNotify ()  #####
' #################################
'
FUNCTION  PrintUnmapNotify (XUnmapEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.event);; HEX$(event.window);; HEX$(event.fromConfigure)
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".event               = "; HEX$ (event.event, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".fromConfigure       = "; HEX$ (event.fromConfigure, 8)
END SUB
END FUNCTION
'
'
' #####################################
' #####  PrintVisibilityEvent ()  #####
' #####################################
'
FUNCTION  PrintVisibilityNotify (XVisibilityEvent event)
	SHARED	event$[]
'
	SELECT CASE TRUE
		CASE (##XBDV OR $$DebugBrief)		: GOSUB Brief
		CASE (##XBDV OR $$DebugWordy)		: GOSUB Wordy
		CASE ##XBDV	                    : GOSUB Wordy
	END SELECT
	RETURN
'
SUB Brief
	swindow = event.window
	XgrSystemWindowToWindow (swindow, @window, @top)
	PRINT event$[event.type]; event.type; event.sendEvent;; HEX$(event.window);; HEX$(event.state);; window;;top
END SUB
'
SUB Wordy
	PRINT ".type                = "; HEX$ (event.type, 8);; event$[event.type]
	PRINT ".serial              = "; HEX$ (event.serial, 8)
	PRINT ".sendEvent           = "; HEX$ (event.sendEvent, 8)
	PRINT ".display             = "; HEX$ (event.display, 8)
	PRINT ".window              = "; HEX$ (event.window, 8)
	PRINT ".state               = "; HEX$ (event.state, 8)
END SUB
END FUNCTION
'
'
' ######################
' #####  JunkHeap  #####
' ######################
'
FUNCTION  JunkHeap ()
	SHARED  DISPLAY  display[]
	XColor  sc
'
'
' given display[], display, and colormap, the following routine displays
' all 256 colors in an 8-bit colormap.
'
	sdisplay = display[display].sdisplay
'
	FOR i = 0 TO 255
		sc.scolor = i
		XQueryColor (sdisplay, colormap, &sc)
		PRINT HEX$(i,2);; HEX$(sc.r,4);; HEX$(sc.g,4);; HEX$(sc.b,4)
		IF ((i AND 0x0F) = 0x0F) THEN a$ = INLINE$ ("press enter for 16 more")
	NEXT i
END FUNCTION
'
'
' ##############################
' #####  DefaultFontNames  #####
' ##############################
'
' DefaultFontNames (@count, @fontName$[])
'
FUNCTION  DefaultFontNames (count, fontName$[])
	SHARED  DISPLAY  display[]
	AUTOX  fonts
'
	count = 0
	DIM fontName$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"DefaultFontNames()lockout", lockout) : lockout = 0
'
	sdisplay = display[1].sdisplay			' default display
	filter$ = "-*-*-*-*-*-*-*-*-*-*-c-*-*-*"
'
	##WHOMASK = 0
	##LOCKOUT = 100182
	addrFontList = XListFonts (sdisplay, &filter$, 4096, &fonts)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ fonts THEN RETURN ($$FALSE)						' no fonts
	IFZ addrFontList THEN RETURN ($$FALSE)		' no fonts
'
	f = 0
	count = 0
	upper = fonts-1
	addr = addrFontList
'
	##WHOMASK = $$FALSE
	DIM fontName$[upper]
'
	DO
		INC f
		font = XLONGAT (addr)						' font = address of font name
		font$ = CSTRING$ (font)					' font$ = font name
		addr = addr + 8									' addr = address of next font name
		IF font$ THEN
			pos = 0
			FOR i = 1 TO 7
				pos = INSTR (font$, "-", pos+1)
				IFZ pos THEN EXIT FOR
			NEXT i
			IF pos THEN
				size = XLONG(MID$(font$,pos+1))
				IF ((size > 6) AND (size < 25)) THEN
					fontName$[count] = font$
					INC count
				END IF
			END IF
		END IF
	LOOP UNTIL (f >= fonts)
'
	top = count - 1
	IF (top != upper) THEN REDIM fontName$[top]
	##WHOMASK = whomask
'
	##WHOMASK = 0
	##LOCKOUT = 100183
	XFreeFontNames (addrFontList)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ####################################
' #####  XgrXcwCreateFontSet ()  #####
' ####################################
'
' sfontset = XgrXcwCreateFontSet (@fontSet, fontSetNames$, @missing$[], @def$)
' XFreeStringList(missing)
'
' Xlib default fonts directories:
' /usr/lib/X11/fonts/misc            Several fixed-width fonts, the cursor font
' /usr/lib/X11/fonts/75dpi           Fixed- and variable-width fonts, 75 dots per inch
' /usr/lib/X11/fonts/100dpi          Fixed- and variable-width fonts, 100 dots per inch
'
' /etc/X11/fonts/...
'
FUNCTION  XgrXcwCreateFontSet (fontSet, fontSetNames$, missing$[], def$)
	SHARED  DISPLAY  display[]
	SHARED  fontsets[]
	SHARED  fontsets$[]

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrXcwCreateFontSet() ", lockout)

	fontLocal$ = fontSetNames$
	ufs = UBOUND(fontsets[])
	fontSet = -1
	FOR i = 0 TO ufs
		IF (fontLocal$ == fontsets$[i]) THEN
			fontSet = i
			sfontset = fontsets[i]
			RETURN sfontset
		END IF
	NEXT i

	whomask = ##WHOMASK
	##WHOMASK = 0

	sdisplay = display[1].sdisplay	' default display
	##LOCKOUT = 100184
	sfontset = XCreateFontSet (sdisplay, &fontLocal$, &missing, &nmissing, &def)
	##LOCKOUT = lockout

	found = $$FALSE
	IF sfontset THEN
		ufs = UBOUND(fontsets[])
		FOR i = 0 TO ufs
			IF (sfontset == fontsets[i]) THEN
				fontSet = i
				found = $$TRUE
				PRINT "XgrXcwCreateFontSet(46):duplicate", i, HEXX$(sfontset)
			END IF
		NEXT i
	END IF
		'
	IFZ found THEN
		FOR i = 0 TO ufs
			IFZ fontsets[i] THEN              ' free font number
				fontsets[i] = sfontset
				fontsets$[i] = fontLocal$
				fontSet = i
				found = $$TRUE
				EXIT FOR
			END IF
		NEXT i
	END IF

	IFZ found THEN
		IF sfontset THEN
			ufs = UBOUND(fontsets[])
			INC ufs
			REDIM fontsets[ufs]
			REDIM fontsets$[ufs]
			fontsets[ufs] = sfontset
			fontsets$[ufs] = fontLocal$
			fontSet = ufs
		END IF
	END IF

	IF nmissing THEN
		uMissing = nmissing-1
		DIM missing$[uMissing]
		FOR i = 0 TO uMissing
			s$ = CSTRING$(ULONGAT(missing, [i]))
			missing$[i] = s$
		NEXT i
		'
		rc = XFreeStringList (missing)
	END IF

	IF def THEN
		DIM def[80]
		FOR i = 0 TO 80
			defChar = UBYTEAT(def, i)
			def[i] = defChar
			IFZ defChar THEN EXIT FOR
		NEXT i
	END IF

	##WHOMASK = whomask

	RETURN sfontset

END FUNCTION
'
'
' ########################################
' #####  XgrXcwGetFontsOfFontSet ()  #####
' ########################################
'
' numberOfFonts = XgrGetFontsOfFontSet (fontSet, @xfstructList[], @fontList$[])
'
FUNCTION  XgrXcwGetFontsOfFontSet (fontSet, XFontStruct xfstructList[], fontList$[])
	SHARED  fontsets[]
	SHARED  fontsets$[]
	XFontStruct xfstruct

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrGetFontsOfFontSet() ", lockout)

	whomask = ##WHOMASK
	##WHOMASK = 0
	DIM xfstructList[]
	DIM fontList$[]
	##WHOMASK = whomask

	IF (fontSet > UBOUND(fontsets[])) THEN RETURN (0)
	sfontset = fontsets[font]
	IFZ sfontset THEN RETURN (0)

	##WHOMASK = 0
	num = XFontsOfFontSet (sfontset, &list, &listString)
	##WHOMASK = whomask

	IFZ num THEN RETURN (0)

	uList = num -1
	DIM fontList$[uList]
	DIM xfstructList[uList]
	FOR i = 0 TO uList
		s$ = CSTRING$(ULONGAT(listString, [i]))
		fontList$[i] = s$
		addrFontStruct = ULONGAT(list, [i])
		XLONGAT(&&xfstruct) = addrFontStruct
		xfstructList[i] = xfstruct
	NEXT i

	RETURN (num)

END FUNCTION
'
'
' ######################################
' #####  XgrXcwSetDrawingColor ()  #####
' ######################################
'
FUNCTION  XgrXcwSetDrawingColor (window, color)
	SHARED  WINDOW  window[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"SetDrawingColor() ", lockout)
'
	gc = window[window].gc
	sdisplay = window[window].sdisplay
	sforeground = window[window].sforeground
	sforegroundDefault = window[window].sforegroundDefault
'
	IF (color = -1) THEN
		scolor = window[window].sforegroundDefault
	ELSE
		ConvertColorToSystemColor (window, color, @scolor)
	END IF
'
'	PRINT "SetDrawingColor() : "; window, color, scolor, sforeground, sforegroundDefault
'
	IF (scolor = -1) THEN RETURN
	IF (scolor = sforeground) THEN RETURN
	window[window].sforeground = scolor
'
	##WHOMASK = 0
	##LOCKOUT = 100185
	XSetForeground (sdisplay, gc, scolor)
	##LOCKOUT = lockout
	##WHOMASK = whomask

END FUNCTION
'
'
' ###############################
' #####  XgrXcwUtf8ToWc ()  #####
' ###############################
'
' error = XgrUtf8ToWc (@utf8$, @wchar[])
'
FUNCTION  XgrXcwUtf8ToWc (utf8$, ULONG wchar[])

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrUtf8ToWc() ", lockout)

	IFZ utf8$ THEN
		DIM wchar[]
		RETURN -1
	END IF
	upperUtf8 = UBOUND(utf8$)
	DIM wchar[upperUtf8]
	j = -1
	FOR i = 0 TO upperUtf8
		byte = utf8${i}
		IF (byte < 0x80) THEN
			IF (byte == 0x09) THEN byte = 0x20
			INC j
			wchar[j] = byte
		ELSE
			SELECT CASE TRUE
				CASE byte < 0xC0 : PRINT "XgrUtf8ToWc(1a) Invalid Unicode Character", utf8$, HEXX$(byte), i
														error = -1
				CASE byte < 0xE0 : GOSUB TwoBytes
				CASE byte < 0xF0 : GOSUB ThreeBytes
				CASE byte < 0xF8 : GOSUB FourBytes
				CASE byte < 0xFC : GOSUB FiveBytes
				CASE byte < 0xFE : GOSUB SixBytes
			END SELECT
			INC j
			wchar[j] = wc
		END IF
		IF error THEN EXIT FOR
	NEXT i
	REDIM wchar[j]
	RETURN (error)
'
' *****  TwoBytes  *****
'
SUB TwoBytes
	wc = (byte AND 0x1F) << 6
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR (byte AND 0x3F)
	ELSE
		PRINT "XgrUtf8ToWc(2a)TwoBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
END SUB
'
' *****  ThreeBytes  *****
'
SUB ThreeBytes
	wc = (byte AND 0x0F) << 12
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 6)
	ELSE
		PRINT "XgrUtf8ToWc(3a)ThreeBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR (byte AND 0x3F)
	ELSE
		PRINT "XgrUtf8ToWc(3b)ThreeBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF

END SUB
'
' *****  FourBytes  *****
'
SUB FourBytes
	wc = (byte AND 0x07) << 18
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 12)
	ELSE
		PRINT "XgrUtf8ToWc(4a)FourBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 6)
	ELSE
		PRINT "XgrUtf8ToWc(4b)FourBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR (byte AND 0x3F)
	ELSE
		PRINT "XgrUtf8ToWc(4c)FourBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
END SUB
'
' *****  FiveBytes  *****
'
SUB FiveBytes
	wc = (byte AND 0x03) << 24
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 18)
	ELSE
		PRINT "XgrUtf8ToWc(5a)FiveBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 12)
	ELSE
		PRINT "XgrUtf8ToWc(5b)FiveBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 6)
	ELSE
		PRINT "XgrUtf8ToWc(5c)FiveBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR (byte AND 0x3F)
	ELSE
		PRINT "XgrUtf8ToWc(5d)FiveBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
END SUB
'
' *****  SixBytes  *****
'
SUB SixBytes
	wc = (byte AND 0x01) << 30
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 24)
	ELSE
		PRINT "XgrUtf8ToWc(6a)SixBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 18)
	ELSE
		PRINT "XgrUtf8ToWc(6b)SixBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 12)
	ELSE
		PRINT "XgrUtf8ToWc(6c)SixBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR ((byte AND 0x3F) << 6)
	ELSE
		PRINT "XgrUtf8ToWc(6d)SixBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
	INC i
	byte = utf8${i}
	IF ((byte AND 0xC0) == 0x80) THEN
		wc = wc OR (byte AND 0x3F)
	ELSE
		PRINT "XgrUtf8ToWc(6e)SixBytes", HEXX$(wc), HEXX$(byte), i
		error = -1
	END IF
END SUB

END FUNCTION
'
'
' ##################################
' #####  XgrXwcTextExtents ()  #####
' ##################################
'
FUNCTION  XgrXwcTextExtents (sfontset, wchar[], XRectangle rectInk, XRectangle rectOverall)
	XRectangle rectInkLocal
	XRectangle rectOverallLocal

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrXwcTextExtents() ", lockout)

	IF wchar[] THEN
		numChars = UBOUND(wchar[]) + 1
		##WHOMASK = 0
		##LOCKOUT = 100186
		width = XwcTextExtents (sfontset, &wchar[], numChars, &rectInkLocal, &rectOverallLocal)
		##LOCKOUT = lockout
		##WHOMASK = whomask
		rectInk = rectInkLocal
		rectOverall = rectOverallLocal
	END IF
	RETURN width

END FUNCTION
'
'
' ##################################
' #####  XgrXcwInvalidGrid ()  #####
' ##################################
'
FUNCTION  XgrXcwInvalidGrid (grid)

	RETURN InvalidGrid (grid)

END FUNCTION
'
'
' ######################################
' #####  XgrXcwWinGridDrawable ()  #####
' ######################################
'
FUNCTION  XgrXcwWinGridDrawable (winGrid)

	RETURN WinGridDrawable (winGrid)

END FUNCTION
'
'
' ##########################################
' #####  XgrXcwLocalToBufferCoords ()  #####
' ##########################################
'
FUNCTION  XgrXcwLocalToBufferCoords (grid, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @xx1, @yy1, @xx2, @yy2)

	RETURN LocalToBufferCoords (grid, buffer, @sbuffer, @overlap, x1, y1, x2, y2, @xx1, @yy1, @xx2, @yy2)

END FUNCTION
'
'
' ##################################
' #####  XgrXmbTextExtents ()  #####
' ##################################
'
FUNCTION  XgrXmbTextExtents (sfontset, mbString$, XRectangle rectInk, XRectangle rectOverall)
	XRectangle rectInkLocal
	XRectangle rectOverallLocal

	IFZ mbString$ THEN RETURN (0)
	IFZ sfontset THEN RETURN (0)

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrXmbTextExtents() ", lockout)

	IF mbString$ THEN
		numBytes = UBOUND(mbString$) + 1
		##WHOMASK = 0
		##LOCKOUT = 100187
		width = XmbTextExtents (sfontset, &mbString$, numBytes, &rectInkLocal, &rectOverallLocal)
		##LOCKOUT = lockout
		##WHOMASK = whomask
		rectInk = rectInkLocal
		rectOverall = rectOverallLocal
	END IF
	RETURN width

END FUNCTION
'
'
' ###############################
' #####  XgrXcwGetUfont ()  #####
' ###############################
'
' FONT fontInfo
' errorUpper = XgrXcwGetUfont (font, @fontName$, @ufont$, @fontInfo)
'
FUNCTION  XgrXcwGetUfont (font, fontName$, ufont$, FONT fontInfo)
	SHARED  FONT  font[]
	SHARED  ufont$[]
	SHARED  font$[]

	fontName$ = ""
	ufont$ = ""
	upper = UBOUND(ufont$[])
	IF (font > upper) THEN RETURN upper

	fontName$ = font$[font]
	ufont$ = ufont$[font]
	fontInfo = font[font]
	RETURN

END FUNCTION
'
'
' #####################################
' #####  XgrXcwGetOneFontName ()  #####
' #####################################
'
' XgrXcwGetOneFontName (count, @fontName$)
'
' XgrGetFontNames() returns the names of all typefaces
' from which fonts can be created by XgrCreateFont().
'
' count = -2 : list all typeface names
' count = -3 : list everything with detail information
'
' An X-Window font name is a string with 14 fields separated by "-"
'
' "-f-t-w-s-w-?-p-t-h-v-s-a-c-#"
'   | | | | | | | | | | | | | |
'   foundry - Adobe, Bitstream, etc
'     typeface - courier, helvetica, etc
'       weight - thin, normal, medium, demibold, bold, heavy, etc
'         slant - roman (normal), italic, oblique, ri (reverse italic), ro (reverse oblique), ot (other)
'           width - normal, condensed, semicondensed, narrow, doublewidth
'             ? - style ??? (informal, roman, serif, sansserif) ???
'               pixels -
'                 tenpoints - 10 * point size (point = 1/72 inch)
'                   hdpi - horizontal resolution in dots per inch
'                     vdpi - vertical resolution in dots per inch
'                       spacing - m = monospace : p = proportional : c = character cell
'                         average width in 1/10 pixels
'                           character set ("iso8859")
'                             character set extension # ("1")
'
FUNCTION  XgrXcwGetOneFontName (@count, @fontName$)
	SHARED  DISPLAY  display[]
	AUTOX  fonts
'
'	filter$ = "-*-*-*-*-*-*-0-0-*-*-*-0-*-*"
'
	filter$ = "-*-" + fontName$ + "-*-*-*-*-0-0-75-75-*-0-iso8859-1"
'
'
	count = 0
	DIM fontName$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrXcwGetOneFontName()lockout", lockout) : lockout = 0
'
	sdisplay = display[1].sdisplay			' default display

	##WHOMASK = 0
	##LOCKOUT = 100188
	addrFontList = XListFonts (sdisplay, &filter$, 1, &fonts)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ fonts THEN RETURN ($$FALSE)						' no fonts
	IFZ addrFontList THEN RETURN ($$FALSE)		' no fonts
'
	addr = addrFontList
	font = XLONGAT (addr)
	fontName$ = CSTRING$ (font)

	##WHOMASK = 0
	##LOCKOUT = 100189
	XFreeFontNames (addrFontList)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	RETURN (1)
'
' ------------------------------------------------------------------
'
	f = 0
	count = 0
	upper = fonts
	addr = addrFontList
	DIM fontName$[upper]
	DIM field$[15]
	INC count
'
	DO
		INC f
		font = XLONGAT (addr)						' font = address of font name
		font$ = CSTRING$ (font)					' font$ = font name
		addr = addr + 8									' addr = address of next font name
		IF font$ THEN
			IF everything THEN
				offset = 1
				IF (font${0} = '-') THEN
					FOR i = 1 TO 14
						next = INSTR (font$, "-", offset+1)
						field$[i] = MID$ (font$, offset+1, next-offset-1)
						offset = next
					NEXT i
					IF ((LEFT$(field$[13],3) = "iso") AND (field$[14] != "1")) THEN DO LOOP
						IF detail THEN
							fontName$[count] = font$
						ELSE
							fontName$ = field$[2]
							FOR i = 1 TO count
								IF (fontName$ = fontName$[i]) THEN DO LOOP
							NEXT i
							fontName$[count] = fontName$
						END IF
						INC count
				END IF
			ELSE
				offset = 1
'				a$ = font$ + "\n"
'				write (1, &a$, LEN(a$))
				IF (font${0} = '-') THEN
					FOR i = 1 TO 14
						next = INSTR (font$, "-", offset+1)
						field$[i] = MID$ (font$, offset+1, next-offset-1)
						offset = next
					NEXT i
					IF (field$[7] = "0") THEN
						IF (field$[8] = "0") THEN
							IF (field$[11] != "c") THEN
								IF (field$[12] = "0") THEN
									fontName$ = field$[2]
									FOR i = 1 TO count
										IF (fontName$ = fontName$[i]) THEN DO LOOP
									NEXT i
'									a$ = field$[2] + "\n" + font$ + "\n"
'									write (1, &a$, LEN(a$))
									fontName$[count] = fontName$
									INC count
								END IF
							END IF
						END IF
					END IF
				END IF
			END IF
		END IF
	LOOP UNTIL (f >= fonts)
'
	top = count - 1
	IF (top != upper) THEN REDIM fontName$[top]
	flags = $$SortIncreasing OR $$SortAlphaNumeric OR $$SortCaseSensitive
	XstQuickSort (@fontName$[], @orderArray[], 0, top, flags)
'
	##WHOMASK = 0
	##LOCKOUT = 100190
	XFreeFontNames (addrFontList)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ##################################
' #####  XgrXcwFreeFontSet ()  #####
' ##################################
'
' error = XgrXcwFreeFontSet (font)
'
FUNCTION  XgrXcwFreeFontSet (fontSet)
	SHARED  DISPLAY  display[]
	SHARED  fontsets[]
	SHARED  fontsets$[]

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XgrXcwFreeFontSet() ", lockout)

	IF (fontSet <= 0) THEN RETURN ($$TRUE)          ' Don't free the default fontset
	ufs = UBOUND(fontsets[])
	IF (fontSet > ufs) THEN RETURN ($$TRUE)         ' out-of-bounds
	IFZ fontsets[fontSet] THEN RETURN ($$TRUE)      ' not assigned

	sfontset = fontsets[fontSet]
	sdisplay = display[1].sdisplay	' default display
	##WHOMASK = 0
	##LOCKOUT = 100191
	XFreeFontSet (sdisplay, sfontset)
	##LOCKOUT = lockout
	fontsets[fontSet] = 0
	fontsets$[fontSet] = ""
	##WHOMASK = whomask

	RETURN ($$FALSE)

END FUNCTION
'
'
' ################################
' #####  XgrXcwSetLocale$ ()  #####
' ################################
'
FUNCTION  XgrXcwSetLocale$ (category, locale$)
	STATIC value$

	whomask = ##WHOMASK
	##WHOMASK = 0
	rc = setlocale (category, &locale$)
	##WHOMASK = whomask

	rc$ = CSTRING$(rc)
	RETURN rc$
'
' -----------------------------------------------
'
'	rc$ = CSTRING$(rc)
'
'
'
'	XstGetEnvironmentVariable ("LC_CTYPE", @lc_ctype$)
'	XstGetEnvironmentVariable ("LANG", @lang$)
'
'	value$ = ""
'	rc = setlocale (0, &value$)
'	rc$ = CSTRING$(rc)
'	IF (rc$ == lang$) THEN RETURN
'	XstGetEnvironmentVariable ("LANG", @value$)
'	whomask = ##WHOMASK
'	##WHOMASK = 0
'	rc = setlocale (0, &value$)
'	##WHOMASK = whomask
'	rc$ = CSTRING$(rc)
'	IF (rc$ != value$) THEN
'		PRINT "XgrXcwSetLocale() : Error", HEXX$(rc), rc$, value$
'	END IF
'	XstSetEnvironmentVariable ("LC_CTYPE", @value$)
'	RETURN rc
'
END FUNCTION
END PROGRAM

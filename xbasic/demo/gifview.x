'
' ####################
' #####  PROLOG  #####
' ####################
'
' This is an XBasic program with functions to convert
' GIF 89a format images into BMP format and vice versa.
' This program handles the basics and you can learn the
' GIF format and see what's going on by taking the comment
' off the "print = $$TRUE" line near the beginning of the
' conversion functions.
'
' This program handles 24-bit and 32-bit varieties of the
' BMP format, but not run-length encoded and maybe others.
'
' XBasic is a comprehensive 32-bit compiler + IDE + GuiDesigner.
' See http://www.maxreason.com/software/xbasic/xbasic.html for
' information and download.
'
' This program was based on "gif0083.x".
'
PROGRAM	"gifview"
VERSION	"0.0083"
'
IMPORT	"xst"
IMPORT	"xgr"
IMPORT	"xui"
'
TYPE GifHeader												' REQUIRED
	STRING*3 .signature
	STRING*3 .version
END TYPE
'
TYPE GifLogicalScreenDescriptor				' REQUIRED
	UBYTE    .widthLSB
	UBYTE    .widthMSB
	UBYTE    .heightLSB
	UBYTE    .heightMSB
	UBYTE    .bitfields
	UBYTE    .backgroundColorIndex
	UBYTE    .pixelAspectRatio
END TYPE
'
TYPE GifColorTableEntry								' global/local color tables are optional
	UBYTE    .r													' red
	UBYTE    .g													' green
	UBYTE    .b													' blue
END TYPE
'
TYPE GifDataBlockSize									' required if image has any data blocks
	UBYTE    .blockSize									' 0x00 blockSize means end of data
END TYPE
'
TYPE GifImageDescriptor								' required for images
	UBYTE    .imageSeparator
	UBYTE    .imageLeftPositionLSB
	UBYTE    .imageLeftPositionMSB
	UBYTE    .imageTopPositionLSB
	UBYTE    .imageTopPositionMSB
	UBYTE    .imageWidthLSB
	UBYTE    .imageWidthMSB
	UBYTE    .imageHeightLSB
	UBYTE    .imageHeightMSB
	UBYTE    .bitfields
END TYPE
'
TYPE GifTableBasedImageDataHeader			' required before 1st image block
	UBYTE    .minimumCodeSize
END TYPE
'
TYPE GifGraphicControlExtension				' OPTIONAL
	UBYTE    .extensionIntroducer
	UBYTE    .graphicControlLabel
	UBYTE    .blockSize
	UBYTE    .bitfields
	UBYTE    .delayTimeLSB
	UBYTE    .delayTImeMSB
	UBYTE    .transparentColorIndex
	UBYTE    .blockTerminator
END TYPE
'
TYPE GifCommentExtensionHeader				' OPTIONAL
	UBYTE    .extensionIntroducer
	UBYTE    .commentLabel
END TYPE
'
TYPE GifPlainTextExtensionHeader			' OPTIONAL
	UBYTE    .extensionIntroducer
	UBYTE    .plainTextLabel
	UBYTE    .blockSize
	UBYTE    .textGridLeftPositionLSB
	UBYTE    .textGridLeftPositionMSB
	UBYTE    .textGridWidthLSB
	UBYTE    .textGridWidthMSB
	UBYTE    .textGridHeightLSB
	UBYTE    .textGridHeightMSB
	UBYTE    .characterCellWidth
	UBYTE    .characterCellHeight
	UBYTE    .textForegroundColorIndex
	UBYTE    .textBackgroundColorIndex
END TYPE
'
TYPE GifApplicationExtensionHeader		' OPTIONAL
	UBYTE    .extensionIntroducer
	UBYTE    .extensionLabel
	UBYTE    .blockSize
	UBYTE    .applicationIdentifier0
	UBYTE    .applicationIdentifier1
	UBYTE    .applicationIdentifier2
	UBYTE    .applicationIdentifier3
	UBYTE    .applicationIdentifier4
	UBYTE    .applicationIdentifier5
	UBYTE    .applicationIdentifier6
	UBYTE    .applicationIdentifier7
	UBYTE    .applicationAuthenticationCode0
	UBYTE    .applicationAuthenticationCode1
	UBYTE    .applicationAuthenticationCode2
END TYPE
'
TYPE GifTrailer												' REQUIRED
	UBYTE    .gifTrailer
END TYPE
'
' ***********************
' *****  FUNCTIONS  *****
' ***********************
'
EXPORT
DECLARE FUNCTION  Gif              ()
DECLARE FUNCTION  ConvertGIFToBMP  (UBYTE gif[], UBYTE bmp[])
DECLARE FUNCTION  ConvertBMPToGIF  (UBYTE bmp[], UBYTE gif[])
END EXPORT
'
	$$BI_RGB        = 0
	$$BI_BITFIELDS  = 3
'
'
' ####################
' #####  Gif ()  #####
' ####################
'
FUNCTION  Gif ()
	UBYTE  gif[]
	UBYTE  gix[]
	UBYTE  bmp[]
	UBYTE  bmx[]
	UBYTE  bmp0[]
	UBYTE  bmp1[]
'
'
'	RETURN		' enable this line to disable the following tests
'
' get array of *.gif filenames
'
'	print = $$TRUE
	path$ = "/xb/xxx/"
	XstGetFiles (path$ + "*.gif", @giffile$[])		' GIF images
	XstGetFiles (path$ + "*.bmp", @bmpfile$[])		' BMP images
	ubmpfile = UBOUND (bmpfile$[])
	ugiffile = UBOUND (giffile$[])
	IF print THEN PRINT ubmpfile, ugiffile
	count = 0
	grid = 0
'
'
' display BMP images in path$
'
	IF 0 THEN
	FOR i = 0 TO ubmpfile							' for all BMP files
		ifile$ = path$ + bmpfile$[i]		' BMP path/filename
		ifile = OPEN (ifile$, $$RD)			' open BMP file
		IF (ifile < 3) THEN DO NEXT			' did not open
		ofile$ = STRING$ (i) + ".gif"		' say what?
		IF print THEN PRINT i, ifile$, ofile$
		error = ERROR (0)								' reset error
		IF error THEN DO NEXT						' but skip this file
'
		bytes = LOF (ifile)							' size of BMP file in bytes
		upper = bytes - 1								' upper element in array of UBYTEs
		DIM bmp[upper]									' create UBYTE array for BMP image
'
		READ [ifile], bmp[]							' read the whole BMP file
		CLOSE (ifile)										' close the BMP file
'
		error = ERROR (0)								' error in READ ???
		IF error THEN DO NEXT						' READ did not work
		IFZ bmp[] THEN DO NEXT					' no BMP image ???
'
		ConvertBMPToGIF (@bmp[], @gif[])	' convert BMP image to GIF image
		IFZ gif[] THEN DO NEXT						' if no GIF image then error
'
		DIM bmx[]													' empty bmx[]
		ConvertGIFToBMP (@gif[], @bmx[])	' convert GIF back to BMP image
		IFZ bmx[] THEN DO NEXT						' didn't work
'
		ofile = OPEN (ofile$, $$WRNEW)	' create file to hold GIF image
		IF (ofile < 3) THEN RETURN			' open error
		error = ERROR (0)								' error ???
'
		WRITE [ofile], gif[]						' save GIF image in file
		CLOSE (ofile)										' close output GIF file
'
		GOSUB DisplayImage							' display in window
		DIM bmp[]												' done with image
		DIM gif[]												' done with image
	NEXT i
	END IF
'
'
' display GIF images in path$
'
	FOR i = 0 TO ugiffile							' for all GIF files
		ifile$ = path$ + giffile$[i]		' GIF path/filename
		ifile = OPEN (ifile$, $$RD)			' open GIF file
		IF (ifile < 3) THEN DO NEXT			' did not open
		ofile$ = STRING$(i) + ".bmp"		' say what?
		IF print THEN PRINT i, ifile$, ofile$
		error = ERROR (0)								' reset error
		IF error THEN DO NEXT						' but skip this file
'
		bytes = LOF (ifile)							' size of GIF file in bytes
		upper = bytes - 1								' upper element in array of UBYTEs
		DIM gif[upper]									' create UBYTE array for GIF image
'
		READ [ifile], gif[]							' read the whole GIF file
		CLOSE (ifile)										' close the GIF file
'
		error = ERROR (0)								' error in READ ???
		IF error THEN DO NEXT						' READ did not work
		IFZ gif[] THEN DO NEXT					' no GIF image ???
'
		ConvertGIFToBMP (@gif[], @bmp[])	' convert GIF image to BMP image
		IFZ bmp[] THEN DO NEXT						' if no BMP image then error
'
'		DIM gix[]													' empty gix[]
'		ConvertBMPToGIF (@bmp[], @gix[])	' convert back to GIF
'		IFZ gix[] THEN DO NEXT						' didn't work
'
		ofile = OPEN (ofile$, $$WRNEW)	' create file to hold BMP image
		IF (ofile < 3) THEN RETURN			' open error
		error = ERROR (0)								' error ???
'
		WRITE [ofile], bmp[]						' save BMP image in file
		CLOSE (ofile)										' close output BMP file
'
		GOSUB DisplayImage							' display in window
		DIM bmp[]												' done with image
		DIM gif[]												' done with image
	NEXT i
	RETURN
'
'
' ******************************
' *****  SUB DisplayImage  *****
' ******************************
'
SUB DisplayImage
	IFZ error THEN
		XgrGetDisplaySize ("", @displayWidth, @displayHeight, @windowBorderWidth, @windowTitleHeight)
		XgrGetImageArrayInfo (@bmp[], @bbp, @width, @height)
		x = (displayWidth - width) >> 1
		y = (displayHeight - height) >> 1
		IF (x < windowBorderWidth) THEN x = windowBorderWidth
		IF (y < (windowTitleHeight+windowBorderWidth)) THEN y = windowBorderWidth+windowTitleHeight
		PRINT RJUST$(STRING$(bytes),6); " : "; RJUST$(STRING$(width),4); ","; RJUST$(STRING$(height),4); " : "; ifile$
		IF grid THEN
			XuiSendStringMessage (grid, @"DestroyWindow", 0, 0, 0, 0, 0, 0)
			grid = 0
		END IF
		IF grid THEN
			XuiSendStringMessage (grid, @"ResizeWindow", x, y, width, height, 0, 0)
		ELSE
			XuiCreateWindow (@grid, @"XuiLabel", x, y, width, height, $$WindowTypeNoFrame, "")
			XuiSendStringMessage (grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)
			XgrClearGrid (grid, $$LightRed)
		END IF
		XgrSetImage (grid, @bmp[])
		DIM bmp[]
	END IF
	XstSleep (250)
	IF grid THEN
		XuiSendStringMessage (grid, @"DestroyWindow", 0, 0, 0, 0, 0, 0)
		grid = 0
	END IF
END SUB
END FUNCTION
'
'
' ################################
' #####  ConvertGIFToBMP ()  #####
' ################################
'
FUNCTION  ConvertGIFToBMP (UBYTE gif[], UBYTE bmp[])
	SHARED  GifColorTableEntry  colorTable[]
	AUTO  USHORT  bitmask[]
	AUTO  GifHeader  gifHeader
	AUTO  GifLogicalScreenDescriptor  gifLogicalScreenDescriptor
	AUTO  GifImageDescriptor  gifImageDescriptor
	AUTO  UBYTE  raw[]
	AUTO  code$[]
'
	DIM bmp[]
	IFZ gif[] THEN RETURN
	ugif = UBOUND (gif[])
	IF (ugif < 32) THEN RETURN
'
	GOSUB Initialize
'
	gifaddr = &gif[]
	error = $$FALSE
'	print = $$TRUE
'
	IFZ error THEN
		GOSUB GetGifHeader
		IF print THEN GOSUB PrintGifHeader
	END IF
'
	IFZ error THEN
		GOSUB GetGifLogicalScreenDescriptor
		IF print THEN GOSUB PrintGifLogicalScreenDescriptor
	END IF
'
	IFZ error THEN
		IF colorTableFlag THEN
			IF colorsInColorTable THEN
				GOSUB GetGifColorTable
				IF print THEN GOSUB PrintGifColorTable
			END IF
		END IF
	END IF
'
	IFZ error THEN
		GOSUB GetGifImageDescriptor
		IF print THEN GOSUB PrintGifImageDescriptor
		IF (imageSeparator != 0x2C) THEN error = $$TRUE
	END IF
'
	IFZ error THEN
		IF colorTableFlag THEN
			IF colorsInColorTable THEN
				GOSUB GetGifColorTable
				IF print THEN GOSUB PrintGifColorTable
			END IF
		END IF
	END IF
'
	dataOffset = 128
	bmpheight = imageHeight
	bmpwidth = (imageWidth + 3) AND -4		' room for mod 4 pixel width
	bmpline = bmpwidth * 3
	bmpsize = dataOffset + (bmpheight * bmpline)
	pixels = imageWidth * imageHeight
	uraw = UBOUND (gif[])
	ubmp = bmpsize - 1
'
	IF error THEN RETURN
'
	raw = 0
	DIM raw[uraw]
	DIM bmp[ubmp]
	rawaddr = &raw[]
	DIM code$[4095]
	GOSUB FillBitmapHeader
'
'	GOSUB CreateTestWindow
'
	IFZ error THEN
		IF colorTableFlag THEN
			IF colorsInColorTable THEN
				GOSUB GetGifColorTable
				IF print THEN GOSUB PrintGifColorTable
			END IF
		END IF
	END IF
'
	IFZ error THEN
		GOSUB GetGifMinimumCodeSize
		IF print THEN GOSUB PrintGifMinimumCodeSize
	END IF
'
'		PRINT HEX$ (addr,8)
'		PRINT HEX$ (daddr,8); RJUST$(STRING$(daddr-addr),6)
'		PRINT HEX$ (bmpaddr,8); RJUST$(STRING$(bmpaddr-addr),6)
'		PRINT HEX$ (uaddr,8); RJUST$(STRING$(uaddr-addr),6)
'
	IFZ error THEN
		GOSUB GetGifImage
		GOSUB DrawGifImage
	END IF
'
'	PRINT HEX$ (addr,8)
'	PRINT HEX$ (daddr,8); RJUST$(STRING$(daddr-addr),6)
'	PRINT HEX$ (bmpaddr,8); RJUST$(STRING$(bmpaddr-addr),6)
'	PRINT HEX$ (uaddr,8); RJUST$(STRING$(uaddr-addr),6)
'
	RETURN
'
'
'
' *****  FillBitmapHeader  *****
'
SUB FillBitmapHeader
	addr = &bmp[]												' header
	uaddr = addr + ubmp									' upper
	daddr = addr + dataOffset						' fixed
	bmpaddr = addr + dataOffset					' moves
'
	UBYTEAT (addr, 0) = 'B'							' signature
	UBYTEAT (addr, 1) = 'M'							' signature
	XLONGAT (addr, 2) = bmpsize					' bytes in array
	XLONGAT (addr, 10) = dataOffset			' from beginning of array
'
	iaddr = addr + 14										' info header address
	XLONGAT (iaddr, 0) = 40							' bytes in this sub-header
	XLONGAT (iaddr, 4) = bmpwidth				' in pixels
	XLONGAT (iaddr, 8) = bmpheight			' in pixels
	USHORTAT (iaddr, 12) = 1						' 1 image plane
	USHORTAT (iaddr, 14) = 24						' bits per pixel
	XLONGAT (iaddr, 16) = $$BI_RGB			' 24-bit indicator
'
	caddr = iaddr + 40									' color header address
'	XLONGAT (caddr, 0) = 0xFFC00000			' 32-bit color only
'	XLONGAT (caddr, 4) = 0x003FF800			' 32-bit color only
'	XLONGAT (caddr, 8) = 0x000007FF			' 32-bit color only
END SUB
'
SUB CreateTestWindow
	width = imageWidth
	height = imageHeight
	XgrGetDisplaySize ("", @displayWidth, @displayHeight, @windowBorderWidth, @windowTitleHeight)
	x = (displayWidth - width) >> 1
	y = (displayHeight - height) >> 1
	IF (x < windowBorderWidth) THEN x = windowBorderWidth
	IF (y < (windowTitleHeight+windowBorderWidth)) THEN y = windowBorderWidth+windowTitleHeight
	XuiCreateWindow (@grid, @"XuiLabel", 700, 23, width, height, 0, "")
	XuiSendStringMessage (grid, @"DisplayWindow", 0, 0, 0, 0, 0, 0)
	XgrProcessMessages (-2)
	XgrClearGrid (grid, $$DarkGrey)
END SUB
'
SUB GetGifHeader
	XstCopyMemory (gifaddr, &gifHeader, 6)
	gifaddr = gifaddr + 6
END SUB
'
SUB PrintGifHeader
	PRINT
	PRINT "GifHeader.signature                             = "; RJUST$("\"" + gifHeader.signature + "\"", 8); " : must be \"GIF\""
	PRINT "GifHeader.version                               = "; RJUST$("\"" + gifHeader.version + "\"", 8); " : must be \"89a\""
END SUB
'
SUB GetGifLogicalScreenDescriptor
	XstCopyMemory (gifaddr, &gifLogicalScreenDescriptor, 7)
	gifaddr = gifaddr + 7
'
	screenWidth = (gifLogicalScreenDescriptor.widthMSB << 8) OR gifLogicalScreenDescriptor.widthLSB
	screenHeight = (gifLogicalScreenDescriptor.heightMSB << 8) OR gifLogicalScreenDescriptor.heightLSB
	backgroundColorIndex = gifLogicalScreenDescriptor.backgroundColorIndex
	pixelAspectRatio = gifLogicalScreenDescriptor.pixelAspectRatio
'
	bitfields = gifLogicalScreenDescriptor.bitfields
	colorTableFlag = (bitfields AND 0x80) >> 7
	colorResolution = (bitfields AND 0x70) >> 4
	sortFlag = (bitfields AND 0x08) >> 3
	sizeOfColorTable = bitfields AND 0x07
	colorsInColorTable = 0x01 << (sizeOfColorTable + 1)
	bytesInColorTable = 3 * colorsInColorTable
END SUB
'
SUB PrintGifLogicalScreenDescriptor
	PRINT
	PRINT "GifLogicalScreenDescriptor.width                = "; RJUST$(HEX$(gifLogicalScreenDescriptor.widthLSB OR (gifLogicalScreenDescriptor.widthMSB << 8),4),8); " : image width in pixels"
	PRINT "GifLogicalScreenDescriptor.height               = "; RJUST$(HEX$(gifLogicalScreenDescriptor.heightLSB OR (gifLogicalScreenDescriptor.heightMSB << 8),4),8); " : image height in pixels"
	PRINT "GifLogicalScreenDescriptor.bitfields            = "; BIN$(gifLogicalScreenDescriptor.bitfields,8); " : 1,3,1,3 bit fields ...)"
	PRINT "   .bitfields.globalColorTableFlag              = "; BIN$(colorTableFlag,1); "        = "; : IF (colorTableFlag) THEN PRINT "TRUE" ELSE PRINT "FALSE"
	PRINT "   .bitfields.colorResolution                   =  "; BIN$(colorResolution,3); "     = "; STRING$(colorResolution+1); " bits per primary color"
	PRINT "   .bitfields.sortFlag                          =     "; BIN$(sortFlag, 1); "    = "; IF sortFlag THEN PRINT "TRUE" ELSE PRINT "FALSE"
	PRINT "   .bitfields.sizeOfGlobalColorTable            =      "; BIN$(sizeOfColorTable, 3); " = "; STRING$(bytesInColorTable); " bytes in global color table"
	PRINT "              colorsInColorTable                =          : "; STRING$(colorsInColorTable)
	PRINT "              bytesInColorTable                 =          : "; STRING$(bytesInColorTable)
	PRINT "GifLogicalScreenDescriptor.backgroundColorIndex = "; RJUST$(HEX$(gifLogicalScreenDescriptor.backgroundColorIndex,2),8)
	PRINT "GifLogicalScreenDescriptor.pixelAspectRatio     = "; RJUST$(HEX$(gifLogicalScreenDescriptor.pixelAspectRatio,2),8)
END SUB
'
SUB GetGifColorTable
	upper = colorsInColorTable - 1
	DIM colorTable[upper]
'
	FOR i = 0 TO upper
		XstCopyMemory (gifaddr, &colorTable[i], 3)
		gifaddr = gifaddr + 3
	NEXT i
END SUB
'
SUB PrintGifColorTable
	upper = UBOUND (colorTable[])
'
	PRINT
	FOR i = 0 TO upper
		r = colorTable[i].r
		g = colorTable[i].g
		b = colorTable[i].b
'		PRINT "color "; HEX$(i,4); " : RGB = "; HEX$(r,2); "."; HEX$(g,2); "."; HEX$(b,2)
	NEXT i
END SUB
'
SUB GetGifImageDescriptor
	XstCopyMemory (gifaddr, &gifImageDescriptor, 10)
	gifaddr = gifaddr + 10
'
	imageSeparator = gifImageDescriptor.imageSeparator
	imageLeftPosition = gifImageDescriptor.imageLeftPositionLSB OR (gifImageDescriptor.imageLeftPositionMSB << 8)
	imageTopPosition = gifImageDescriptor.imageTopPositionLSB OR (gifImageDescriptor.imageTopPositionMSB << 8)
	imageWidth = gifImageDescriptor.imageWidthLSB OR (gifImageDescriptor.imageWidthMSB << 8)
	imageHeight = gifImageDescriptor.imageHeightLSB OR (gifImageDescriptor.imageHeightMSB << 8)
	bitfields = gifImageDescriptor.bitfields
'
	colorTableFlag = (bitfields AND 0x80) >> 7
	interlaceFlag = (bitfields AND 0x40) >> 6
	sortFlag = (bitfields AND 0x20) >> 5
	reserved = (bitfields AND 0x18) >> 3
	sizeOfColorTable = bitfields AND 0x07
	colorsInColorTable = 0x01 << (sizeOfColorTable + 1)
	bytesInColorTable = 3 * colorsInColorTable
END SUB
'
SUB PrintGifImageDescriptor
	PRINT
	PRINT "GifImageDescriptor.imageSeparator               = "; RJUST$(HEX$(imageSeparator,2),8); " : must be 2C"
	PRINT "GifImageDescriptor.imageLeftPosition            = "; RJUST$(HEX$(imageLeftPosition,4),8); " = "; STRING$(imageLeftPosition)
	PRINT "GifImageDescriptor.imageTopPosition             = "; RJUST$(HEX$(imageTopPosition,4),8); " = "; STRING$(imageTopPosition)
	PRINT "GifImageDescriptor.imageWidth                   = "; RJUST$(HEX$(imageWidth,4),8); " = "; STRING$(imageWidth)
	PRINT "GifImageDescriptor.imageHeight                  = "; RJUST$(HEX$(imageHeight,4),8); " = "; STRING$(imageHeight)
	PRINT "GifImageDescriptor.bitfields                    = "; BIN$(bitfields,8)
	PRINT "   .bitfields.colorTableFlag                    = "; BIN$(colorTableFlag,1)
	PRINT "   .bitfields.interlaceFlag                     =  "; BIN$(interlaceFlag,1)
	PRINT "   .bitfields.sortFlag                          =   "; BIN$(sortFlag,1)
	PRINT "   .bitfields.reserved                          =    "; BIN$(reserved,2)
	PRINT "   .bitfields.sizeOfColorTable                  =      "; BIN$(sizeOfColorTable,3)
	PRINT "              colorsInColorTable                =          : "; STRING$(colorsInColorTable)
	PRINT "              bytesInColorTable                 =          : "; STRING$(bytesInColorTable)
END SUB
'
SUB GetGifMinimumCodeSize
	minimumCodeSize = UBYTEAT (gifaddr)
	gifaddr = gifaddr + 1
END SUB
'
SUB PrintGifMinimumCodeSize
	PRINT
	PRINT "GifMinimumCodeSize                              = "; RJUST$(HEX$(minimumCodeSize,2),8)
END SUB
'
SUB GetGifImage
	DO
		blockSize = UBYTEAT (gifaddr)
		gifaddr = gifaddr + 1
'
		IF blockSize THEN
			XstCopyMemory (gifaddr, rawaddr, blockSize)
			gifaddr = gifaddr + blockSize
			rawaddr = rawaddr + blockSize
			raw = raw + blockSize
		END IF
	LOOP WHILE blockSize
END SUB
'
SUB DrawGifImage
	pass = 0
	offbit = 0
	offbyte = 0
	bits = minimumCodeSize + 1
	clearCode = 1 << minimumCodeSize
	terminateCode = clearCode + 1
	maximumValue = clearCode - 1
	widthCode = clearCode << 1
'
	FOR i = 0 TO clearCode-1
		code$[i] = CHR$(i)
	NEXT i
'
	x = 0
	y = 0
'
	char$ = ""
	slot = 130
	done = $$FALSE
'
	GOSUB GetNewCode
	IF (new != clearCode) THEN STOP
	GOSUB ClearCode
'
	DO
		GOSUB GetNewCode
		terminate = $$FALSE
		IF ((offbyte + 3) >= uraw) THEN EXIT SUB
		SELECT CASE TRUE
			CASE (new = clearCode)			: GOSUB ClearCode
			CASE (new = terminateCode)	: IF print THEN PRINT "terminateCode"
																		EXIT DO
			CASE ELSE										:	string$ = code$[new]
																		IFZ string$ THEN string$ = code$[old] + char$
																		GOSUB DrawString
																		IFZ terminate THEN
																			char$ = CHR$(string${0})
																			IF (slot > UBOUND(code$[])) THEN EXIT SUB
																			code$[slot] = code$[old] + char$
																			old = new
																			INC slot
																			IF (slot >= widthCode) THEN
																				IF print THEN PRINT HEX$(offbyte,8); " tableFull : bits = "; RJUST$(STRING$(bits),2); " to "; RJUST$(STRING$(bits+1),2); " : slot = "; RJUST$(STRING$(slot-1),2); " to "; RJUST$(STRING$(slot),2)
																				IF (bits < 12) THEN
																					widthCode = widthCode << 1
																					INC bits
																				END IF
																			END IF
																		END IF
		END SELECT
	LOOP UNTIL terminate
END SUB
'
SUB GetNewCode
	offbyte = offbit >> 3
	bitaddr = offbit AND 0x07
	IF ((offbyte + 3) >= uraw) THEN EXIT SUB
	new = raw[offbyte] OR (raw[offbyte+1] << 8) OR (raw[offbyte+2] << 16 OR raw[offbyte+3] << 24)
	new = new >> bitaddr
	new = new AND bitmask[bits]
	offbit = offbit + bits
	IF (offbyte >= uraw) THEN STOP
END SUB
'
SUB ClearCode
	oldbits = bits
	slot = terminateCode + 1
	REDIM code$[clearCode-1]
	bits = minimumCodeSize + 1
	widthCode = clearCode << 1
	REDIM code$[4095]
	IF print THEN PRINT HEX$(offbyte,8); " clearCode : bits = "; RJUST$(STRING$(oldbits),2); " to "; RJUST$(STRING$(bits),2); " : slot = "; RJUST$(STRING$(slot),2)
	GOSUB GetNewCode
	string$ = code$[new]
	GOSUB DrawString
'	char$ = CHR$(string${0})																	' old
	IF string$ THEN	char$ = CHR$(string${0}) ELSE char$ = ""	' new
	old = new
END SUB
'
SUB DrawString
	u = UBOUND (string$)
'
	FOR n = 0 TO u
		pixel = string${n}
		r = colorTable[pixel].r
		g = colorTable[pixel].g
		b = colorTable[pixel].b
'
' try to color adjust does not work as desired
'
'		IF (b < 0x80) THEN b = b + b >> 2
'		IF (g < 0x80) THEN g = g + g >> 2
'		IF (r < 0x80) THEN r = r + r >> 2
'
		color = (r << 24) OR (g << 16) OR (b << 8)
'
		IF bmp[] THEN
			IFZ x THEN
				bmpy = bmpheight - y - 1					' y in bitmap - inverted
				bmp0 = daddr + (bmpy * bmpline)		' address of 1st pixel on line
				bmpaddr = bmp0
'
' added to catch disasterous error - fixed in v0.0082
'
				xlasty = y
				xlastbmpline = bmpline
				IF ((bmpaddr < daddr) OR (bmpaddr > uaddr)) THEN
					IF print THEN PRINT HEX$(bmpaddr,8);; HEX$(daddr,8);; HEX$(uaddr,8);; HEX$(bmp0,8);; bmpy;; bmpheight;; bmpline;; xlastbmpline;; xlasty;; imageWidth;; imageHeight
					terminate = $$TRUE
					EXIT SUB
				END IF
			END IF
'
'
'
			UBYTEAT (bmpaddr) = b	: INC bmpaddr
			UBYTEAT (bmpaddr) = g	: INC bmpaddr
			UBYTEAT (bmpaddr) = r	: INC bmpaddr
'
' the following makes no difference
'
'			XgrConvertRGBToColor (r << 8 OR r, g << 8 OR g, b << 8 OR b, @kolor)
'			XgrConvertColorToRGB (kolor, @red, @green, @blue)
'			UBYTEAT (bmpaddr) = blue >> 8		: INC bmpaddr
'			UBYTEAT (bmpaddr) = green >> 8	: INC bmpaddr
'			UBYTEAT (bmpaddr) = red >> 8		: INC bmpaddr
'
		END IF
'
'		IF grid THEN XgrDrawPoint (grid, color, x, y)
'		IF image THEN XgrDrawPoint (image, color, x, y)
'
		INC x
		IF (x >= imageWidth) THEN
			x = 0
			IFZ interlaceFlag THEN
				y = y + 1
			ELSE
				SELECT CASE pass
					CASE 0		: y = y + 8
					CASE 1		: y = y + 8
					CASE 2		: y = y + 4
					CASE 3		: y = y + 2
					CASE ELSE	: STOP
				END SELECT
			END IF
		END IF
'
		IF (y >= imageHeight) THEN
			INC pass
			IFZ interlaceFlag THEN
				y = y + 1
			ELSE
				SELECT CASE pass
					CASE 1		: y = 4
					CASE 2		: y = 2
					CASE 3		: y = 1
					CASE ELSE	: INC y			' past end of image
				END SELECT
				IF (y >= imageHeight) THEN
					IF print THEN PRINT HEX$(bmpaddr,8);; HEX$(daddr,8);; HEX$(bmp0,8);; bmpy;; bmpheight;; bmpline;; xlastbmpline;; xlasty;; imageWidth;; imageHeight
					terminate = $$TRUE
					EXIT FOR
				END IF
			END IF
		END IF
	NEXT n
'	XgrProcessMessages (-2)
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	DIM bitmask[31]
	bitmask[ 0] = 0x00000000
	bitmask[ 1] = 0x00000001
	bitmask[ 2] = 0x00000003
	bitmask[ 3] = 0x00000007
	bitmask[ 4] = 0x0000000F
	bitmask[ 5] = 0x0000001F
	bitmask[ 6] = 0x0000003F
	bitmask[ 7] = 0x0000007F
	bitmask[ 8] = 0x000000FF
	bitmask[ 9] = 0x000001FF
	bitmask[10] = 0x000003FF
	bitmask[11] = 0x000007FF
	bitmask[12] = 0x00000FFF
	bitmask[13] = 0x00001FFF
	bitmask[14] = 0x00003FFF
	bitmask[15] = 0x00007FFF
	bitmask[16] = 0x0000FFFF
	bitmask[17] = 0x0001FFFF
	bitmask[18] = 0x0003FFFF
	bitmask[19] = 0x0007FFFF
	bitmask[20] = 0x000FFFFF
	bitmask[21] = 0x001FFFFF
	bitmask[22] = 0x003FFFFF
	bitmask[23] = 0x007FFFFF
	bitmask[24] = 0x00FFFFFF
	bitmask[25] = 0x01FFFFFF
	bitmask[26] = 0x03FFFFFF
	bitmask[27] = 0x07FFFFFF
	bitmask[28] = 0x0FFFFFFF
	bitmask[29] = 0x1FFFFFFF
	bitmask[30] = 0x3FFFFFFF
	bitmask[31] = 0x7FFFFFFF
END SUB
END FUNCTION
'
'
' ################################
' #####  ConvertBMPToGIF ()  #####
' ################################
'
FUNCTION  ConvertBMPToGIF (UBYTE bmp[], UBYTE gif[])
	SHARED  GifColorTableEntry  colorTable[]
	AUTO  USHORT  bitmask[]
	AUTO  GifHeader  gifHeader
	AUTO  GifLogicalScreenDescriptor  gifLogicalScreenDescriptor
	AUTO  GifImageDescriptor  gifImageDescriptor
	AUTO  USHORT  h[]
	AUTO  USHORT  hx[]
	AUTO  USHORT  hash[]
	AUTO  UBYTE  gdata[]
	AUTO  code$[]
'
	DIM gif[]
	IFZ bmp[] THEN RETURN
	ubmp = UBOUND (bmp[])
	IF (ubmp < 64) THEN RETURN
'
	GOSUB Initialize
'
	bmpaddr = &bmp[]
	error = $$FALSE
'	print = $$TRUE
'
	haddr = bmpaddr											' header address
'
' get 'BM' signature
'
	hoff = 0
	h0 = UBYTEAT (haddr, 0)
	h1 = UBYTEAT (haddr, 1)
	h0 = bmp[hoff+0]
	h1 = bmp[hoff+1]
'
	IF ((h0 != 'B') OR (h1 != 'M')) THEN
		error = ($$ErrorObjectImage << 8) OR $$ErrorNatureInvalidFormat
		old = ERROR (error)
		DIM gif[]
		RETURN ($$TRUE)
	END IF
'
	IF print THEN PRINT " signature      =       "; CHR$(h0); CHR$(h1)
'
' get bitmap file size in bytes
'
	h2 = UBYTEAT (haddr, 2)
	h3 = UBYTEAT (haddr, 3)
	h4 = UBYTEAT (haddr, 4)
	h5 = UBYTEAT (haddr, 5)
	h2 = bmp[hoff+2]
	h3 = bmp[hoff+3]
	h4 = bmp[hoff+4]
	h5 = bmp[hoff+5]
'
	bmpsize = (h5 << 24) OR (h4 << 16) OR (h3 << 8) OR h2
	IF print THEN PRINT " BMP file size  = "; RJUST$(STRING$(bmpsize),8)
'
' get offset from beginning of file to beginning of data
'
	h10 = UBYTEAT (haddr, 10)
	h11 = UBYTEAT (haddr, 11)
	h12 = UBYTEAT (haddr, 12)
	h13 = UBYTEAT (haddr, 13)
	h10 = bmp[hoff+10]
	h11 = bmp[hoff+11]
	h12 = bmp[hoff+12]
	h13 = bmp[hoff+13]
'
	dataOffset = (h13 << 24) OR (h12 << 16) OR (h11 << 8) OR h10
	IF print THEN PRINT " data offset    = "; RJUST$(STRING$(dataOffset),8)
'
' get info header size
'
	ioff = 14
	iaddr = haddr + 14
	i0 = UBYTEAT (iaddr, 0)
	i1 = UBYTEAT (iaddr, 1)
	i2 = UBYTEAT (iaddr, 2)
	i3 = UBYTEAT (iaddr, 3)
	i0 = bmp[ioff+0]
	i1 = bmp[ioff+1]
	i2 = bmp[ioff+2]
	i3 = bmp[ioff+3]
'
	infoBytes = (i3 << 24) OR (i2 << 16) OR (i1 << 8) OR i0
	IF print THEN PRINT " info bytes     = "; RJUST$(STRING$(infoBytes),8)
'
	i4 = UBYTEAT (iaddr, 4)
	i5 = UBYTEAT (iaddr, 5)
	i6 = UBYTEAT (iaddr, 6)
	i7 = UBYTEAT (iaddr, 7)
	i4 = bmp[ioff+4]
	i5 = bmp[ioff+5]
	i6 = bmp[ioff+6]
	i7 = bmp[ioff+7]
'
	width = (i7 << 24) OR (i6 << 16) OR (i5 << 8) OR i4
	IF print THEN PRINT " image width    = "; RJUST$(STRING$(width),8)
'
	i8 = UBYTEAT (iaddr, 8)
	i9 = UBYTEAT (iaddr, 9)
	i10 = UBYTEAT (iaddr, 10)
	i11 = UBYTEAT (iaddr, 11)
	i8 = bmp[ioff+8]
	i9 = bmp[ioff+9]
	i10 = bmp[ioff+10]
	i11 = bmp[ioff+11]
'
	height = (i11 << 24) OR (i10 << 16) OR (i9 << 8) OR i8
	IF print THEN PRINT " image height   = "; RJUST$(STRING$(height),8)
'
	i12 = UBYTEAT (iaddr, 12)
	i13 = UBYTEAT (iaddr, 13)
	i14 = UBYTEAT (iaddr, 14)
	i15 = UBYTEAT (iaddr, 15)
	i12 = bmp[ioff+12]
	i13 = bmp[ioff+13]
	i14 = bmp[ioff+14]
	i15 = bmp[ioff+15]
'
	im$ = ""
	planes = (i13 << 8) OR i12
	bitsPerPixel = (i15 << 8) OR i14
	IF (bitsPerPixel < 24) THEN im$ = " not supported"
	IF print THEN PRINT " planes         = "; RJUST$(STRING$(planes),8)
	IF print THEN PRINT " bits per pixel = "; RJUST$(STRING$(bitsPerPixel),8); im$
'
	i16 = UBYTEAT (iaddr, 16)
	i17 = UBYTEAT (iaddr, 17)
	i18 = UBYTEAT (iaddr, 18)
	i19 = UBYTEAT (iaddr, 19)
	i16 = bmp[ioff+16]
	i17 = bmp[ioff+17]
	i18 = bmp[ioff+18]
	i19 = bmp[ioff+19]
'
	imageMode = (i19 << 24) OR (i18 << 16) OR (i17 << 8) OR i16
	IF print THEN
		SELECT CASE imageMode
			CASE 0	: im$ = "BI_RGB"
			CASE 1	: im$ = "BI_RLE8 = run-length encoded : not supported"
			CASE 2	: im$ = "BI_RLE4 = run-length encoded : not supported"
			CASE 3	: im$ = "BI_BITFIELDS"
			CASE 4	: im$ = "not recognized"
		END SELECT
		PRINT " image mode     = "; HEX$(imageMode,8); " = "; im$
	END IF
'
	coff = ioff + infoBytes
	caddr = iaddr + infoBytes
	c0 = UBYTEAT (caddr, 0)
	c1 = UBYTEAT (caddr, 1)
	c2 = UBYTEAT (caddr, 2)
	c3 = UBYTEAT (caddr, 3)
	c0 = bmp[coff+0]
	c1 = bmp[coff+1]
	c2 = bmp[coff+2]
	c3 = bmp[coff+3]
'
	rbits = (c3 << 24) OR (c2 << 16) OR (c1 << 8) OR c0
	IF print THEN PRINT " R bits         = "; HEX$(rbits,8)
'
	c4 = UBYTEAT (caddr, 4)
	c5 = UBYTEAT (caddr, 5)
	c6 = UBYTEAT (caddr, 6)
	c7 = UBYTEAT (caddr, 7)
	c4 = bmp[coff+4]
	c5 = bmp[coff+5]
	c6 = bmp[coff+6]
	c7 = bmp[coff+7]
'
'	gbits = (c3 << 24) OR (c2 << 16) OR (c1 << 8) OR c0
	gbits = (c7 << 24) OR (c6 << 16) OR (c5 << 8) OR c4
	IF print THEN PRINT " G bits         = "; HEX$(gbits,8)
'
	c8 = UBYTEAT (caddr, 8)
	c9 = UBYTEAT (caddr, 9)
	c10 = UBYTEAT (caddr, 10)
	c11 = UBYTEAT (caddr, 11)
	c8 = bmp[coff+8]
	c9 = bmp[coff+9]
	c10 = bmp[coff+10]
	c11 = bmp[coff+11]
'
'	bbits = (c3 << 24) OR (c2 << 16) OR (c1 << 8) OR c0
	bbits = (c11 << 24) OR (c10 << 16) OR (c9 << 8) OR c8
	IF print THEN PRINT " B bits         = "; HEX$(bbits,8)
'
	IF (width <= 0) THEN RETURN ($$TRUE)
	IF (height <= 0) THEN RETURN ($$TRUE)
	IF (bitsPerPixel <= 0) THEN RETURN ($$TRUE)
	IF (bitsPerPixel < 24) THEN RETURN ($$TRUE)
'
	DIM gif[ubmp+4095]
	ugif = ubmp+4095
	gaddr = &gif[]
'
' gif header - signature and version
'
	UBYTEAT (gaddr, 0) = 'G'												' GIF signature
	UBYTEAT (gaddr, 1) = 'I'
	UBYTEAT (gaddr, 2) = 'F'
	UBYTEAT (gaddr, 3) = '8'												' GIF version
	UBYTEAT (gaddr, 4) = '9'
	UBYTEAT (gaddr, 5) = 'a'
'
' gif logical screen descriptor
'
	UBYTEAT (gaddr, 6) = width AND 0x00FF						' width LSB
	UBYTEAT (gaddr, 7) = (width >> 8) AND 0x00FF		' width MSB
	UBYTEAT (gaddr, 8) = height AND 0x00FF					' height LSB
	UBYTEAT (gaddr, 9) = (height >> 8) AND 0x00FF		' height MSB
'
	UBYTEAT (gaddr,10) = 0xF6				' 0x80 mask			' 1 = colorTableFlag
																	' 0x70 mask			' 7 = colorResolution
																	' 0x08 mask			' 0 = sortFlag
																	' 0x07 mask			' 6 = sizeOfColorTable
	UBYTEAT (gaddr,11) = 0x00												' backgroundColorIndex
	UBYTEAT (gaddr,12) = 0x00												' pixelAspectRatio
'
'
'
' *****  gif color palette  *****  first add standard 125 colors
'
	nextpalette = 0
	caddr = gaddr + 13
	palette = gaddr + 13
'
'	FOR color = 0 TO 124
'		XgrConvertColorToRGB (color, @r, @g, @b)
'		UBYTEAT (caddr) = (r >> 8) AND 0x00FF	: INC caddr
'		UBYTEAT (caddr) = (g >> 8) AND 0x00FF	: INC caddr
'		UBYTEAT (caddr) = (b >> 8) AND 0x00FF	: INC caddr
'	NEXT color
'
'
' *****  gif color palette  ***** - undefined colors to fill 128 colors
'
'	FOR color = 125 TO 127
'		UBYTEAT (caddr) = 0x00	: INC caddr
'		UBYTEAT (caddr) = 0x00	: INC caddr
'		UBYTEAT (caddr) = 0x00	: INC caddr
'	NEXT color
'
'
' *****  TEMPORARY FOR DEBUGGING  -  ORIGINAL PALETTE  *****
'
'	xaddr = palette
'	FOR color = 0 TO 127
'		UBYTEAT (xaddr) = colorTable[color].r	: INC xaddr
'		UBYTEAT (xaddr) = colorTable[color].g	: INC xaddr
'		UBYTEAT (xaddr) = colorTable[color].b	: INC xaddr
'	NEXT color
'
' *****  gif image descriptor  *****
'
	addr = palette + 128 + 128 + 128											' 128 RGBs
	UBYTEAT (addr) = 0x2C											: INC addr	' image separator
	UBYTEAT (addr) = 0x00											: INC addr	' image left LSB
	UBYTEAT (addr) = 0x00											: INC addr	' image left MSB
	UBYTEAT (addr) = 0x00											: INC addr	' image top LSB
	UBYTEAT (addr) = 0x00											: INC addr	' image top MSB
	UBYTEAT (addr) = width AND 0x00FF					: INC addr	' width LSB
	UBYTEAT (addr) = (width >> 8) AND 0x00FF	: INC addr	' width MSB
	UBYTEAT (addr) = height AND 0x00FF				: INC addr	' height LSB
	UBYTEAT (addr) = (height >> 8) AND 0x00FF	: INC addr	' height MSB
	UBYTEAT (addr) = 0x46											: INC addr	' bitfields
																						' 0x80 mask	' colorTableFlag
																						' 0x40 mask	' interlaceFlag
																						' 0x20 mask	' sortFlag
																						' 0x18 mask	' reserved
																						' 0x07 mask	' sizeOfColorTable
'
' *****  gif image data  *****
'
' interlace	: pass 1 = every 8th scan line starting at 0
'						: pass 2 = every 8th scan line starting at 4
'						: pass 3 = every 4th scan line starting at 2
'						: pass 4 = every 2nd scan line starting at 1
'
' 1st byte of data is bits in starting color table codes - 0x00 to 0x7F
'
	UBYTEAT (addr) = 0x07					: INC addr		' minimumCodeSize
'
' addressing in gif image is bitwise because the index elements
' put in the image grow/vary between 8,9,10,11,12 bits wide.
'
	xoffbyte = addr - gaddr	' byte offset in gif[]
	xoffbit = offbyte << 3	' bit offset in gif[]
'
' *****  initialize index code array  *****
'
	DIM code$[4095]					' maximum 12-bit index
'
	FOR i = 0 TO 127
		code$[i] = CHR$(i)		' indices 0 to 127 mean the values themselves
	NEXT i
'
	clearCode = 128					' clear code$[] code
	terminateCode = 129			' terminate image code
	slot = 130							' first available index
'
	DIM gdata[ugif]					' collect data in gdata[]
	offbyte = 0							' start at beginning
	offbit = 0							'	ditto
'
'
' read image data from BMP image and put in GIF image data area
'
	xmod = ((width * 3) + 3) AND -4						' bytes per BMP scan line
	ibase = haddr + dataOffset								' address of bmp image
	bsize = xmod * height											' bytes in BMP image
	zbase = ibase + bsize											' address after bmp image
	addr = zbase - xmod												' top scan line
	pixelbytes = 3														' 3 bytes per pixel
	past = 0x0100															' past 8-bit indexes
	pass = 1																	' pass 1 - begin the show
	yinc = 8																	' pass 1 - 8 line interlace
	done = 0																	' not done image conversion
	bits = 8																	' start with 8-bit indices
	y = 0																			' pass 1 - start at the top
	x = 0																			' start at left edge
'
' startup code to reduce overhead in normal loops
'
	string = 0x80															' initial clearCode
	GOSUB OutputCode													' put in data stream
	IF print THEN PRINT HEX$(addr,8), x, y, done
'
	GOSUB GetNextIndex												' next pixel color table index
	string$ = CHR$ (index)										' 1st index character
	string = index														' string code
	INC x																			' 2nd pixel
'
	DO
'		old = string														' may need old code
'		old$ = string$													' may need old string
		GOSUB GetNextIndex											' next pixel color table index
		index$ = CHR$ (index)										' next index character
'		IF (index > 127) THEN STOP							' idiot check - remove
'		IF (index < 0) THEN STOP								' idiot check - remove
		string$ = string$ + index$							' possible next string$
'
		found = 0																' string not found yet
		uhash = UBOUND (string$)								' initial hash value
		hash = hx[uhash AND 0x00FF]
'
		FOR i = 0 TO uhash
			hash = hash + hx[string${i}]
		NEXT i
		hash = hash AND 0x00000FFF
'
		IF hash[hash,] THEN
			FOR i = 0 TO UBOUND(hash[hash,])
				s = hash[hash,i]
				IFZ s THEN EXIT FOR
				IF (string$ = code$[s]) THEN
					string = s
					found = s
					EXIT FOR
				END IF
			NEXT i
		END IF
'
'		FOR i = 130 TO slot-1										' for all code strings
'			IF (string$ = code$[i]) THEN					' string already in table?
'				string = i													' string code in table
'				found = i														'
'				EXIT FOR														'
'			END IF																'
'		NEXT i																	'
'
		IFZ found THEN
			GOSUB OutputStringCode								' output string code
			string$ = index$											' new string is index
			string = index												' ditto
		END IF
'
		INC x																		' next horizontal pixel
		IF (x >= width) THEN										' time for new scan line
			SELECT CASE pass
				CASE	1		: y = y + 8
				CASE	2		: y = y + 8
				CASE	3		: y = y + 4
				CASE	4		: y = y + 2
				CASE ELSE	: STOP
			END SELECT
			x = 0
			IF (y >= height) THEN
				SELECT CASE pass
					CASE 1		: y = 4
					CASE 2		: y = 2
					CASE 3		: y = 1
					CASE 4		: done = $$TRUE
					CASE ELSE	: STOP
				END SELECT
				INC pass
			END IF
			addr = zbase - (xmod * (y+1))					' address of bmp scan line
			ooooo = offbit >> 3
			IF print THEN PRINT HEX$(addr,8), HEX$(ooooo, 8), RJUST$(STRING$(ooooo),4), x, y, done
		END IF
	LOOP UNTIL done
'
	GOSUB OutputCode
'
	index = terminateCode
	GOSUB OutputCode
'
	index = 0x3B
	GOSUB OutputCode
'
' transfer GIF image-data into GIF image
'
	offbit = offbit + 32
	offbyte = offbit >> 3
'
	offgif = xoffbyte
	offdata = 0
'
	DO
		IF (offbyte >= 255) THEN
			offbyte = offbyte - 255
			length = 255
		ELSE
			length = offbyte
			offbyte = 0
		END IF
'
		gif[offgif] = length	: INC offgif
'
		FOR i = 0 TO length-1
			gif[offgif] = gdata[offdata]	: INC offgif : INC offdata
		NEXT i
	LOOP WHILE offbyte
'
	REDIM gif[offgif-1]
'
	RETURN ($$FALSE)
'
'
'
' *****  GetNextIndex  *****
'
SUB GetNextIndex
	b = UBYTEAT (addr)	: INC addr						' blue byte
	g = UBYTEAT (addr)	: INC addr						' green byte
	r = UBYTEAT (addr)	: INC addr						' red byte
'
	error = 0x7FFFFFFF
'
	c = palette
	FOR p = 0 TO nextpalette-1								' for all palette colors
		rr = UBYTEAT (c)	: INC c								' palette red
		gg = UBYTEAT (c)	: INC c								' palette green
		bb = UBYTEAT (c)	: INC c								' palette blue
'
		cerror = ABS(r-rr)+ABS(g-gg)+ABS(b-bb)	' color error
'
		IFZ cerror THEN
			error = 0
			index = p
			EXIT FOR
		END IF

		i = b + g + r														' pixel intensity
		ii = rr + gg + bb												' palette intensity
		ierror = ABS(i-ii)											' intensity error
		terror = cerror + ierror								' total error is sum
'
		IF (terror < error) THEN								'
			error = terror												' new smallest error
			index = p															' new palette index
		END IF
	NEXT p
'
' if no perfect color match, add new color to palette if room
'
	IF error THEN
		IF (nextpalette < 128) THEN
			UBYTEAT (caddr) = r : INC caddr
			UBYTEAT (caddr) = g : INC caddr
			UBYTEAT (caddr) = b : INC caddr
			index = nextpalette
			INC nextpalette
		END IF
	END IF
END SUB
'
'
' *****  OutputStringCode  *****
'
SUB OutputStringCode
	IF (slot > past) THEN
		past = past << 1
		INC bits
	END IF
'
	GOSUB OutputCode
'
	IF (slot = 4095) THEN
		IF print THEN PRINT "table full - issue a clear code : "; STRING$(bits);; STRING$(slot);; STRING$(y);; STRING$(x)
		temp = string
		string = clearCode
		GOSUB OutputCode
		DIM hash[]
		DIM hash[4095,]
		REDIM code$[127]
		REDIM code$[4095]
		past = 0x0100
		slot = 130
		bits = 8
	ELSE
		GOSUB AddStringToHashTable
		code$[slot] = string$
		INC slot
	END IF
END SUB
'
SUB AddStringToHashTable
	uhash = UBOUND (string$)								' initial hash value
	hash = hx[uhash AND 0x00FF]
	FOR off = 0 TO uhash
		hash = hash + hx[string${off}]
	NEXT off
	hash = hash AND 0x00000FFF
'
	IFZ hash[hash,] THEN
		DIM h[7]
		empty = 0
		h[empty] = slot
		ATTACH h[] TO hash[hash,]
	ELSE
		empty = -1
		ATTACH hash[hash,] TO h[]
		FOR e = 0 TO UBOUND (h[])
			IFZ h[e] THEN
				empty = e
				EXIT FOR
			END IF
		NEXT e
		IF (empty < 0) THEN
			u = UBOUND (h[])
			empty = u + 1
			REDIM h[u+8]
			h[empty] = slot
		ELSE
			h[empty] = slot
		END IF
		ATTACH h[] TO hash[hash,]
	END IF
'	PRINT hash, empty, u
END SUB
'
SUB OutputCode
	offbyte = offbit >> 3
	bitaddr = offbit AND 0x07
'
	old0 = gdata[offbyte]
	old1 = gdata[offbyte+1]
	old2 = gdata[offbyte+2]
'
	new0 = (string << bitaddr) AND 0x000000FF
	new1 = (string >> (8-bitaddr)) AND 0x000000FF
	new2 = (string >> (16-bitaddr)) AND 0x000000FF
'
	IF (old0 AND new0) THEN STOP			' algorithm error
	IF (old1 AND new1) THEN STOP			' algorithm error
	IF (old2 AND new2) THEN STOP			' algorithm error
'
	offbit = offbit + bits
	gdata[offbyte] = old0 OR new0
	gdata[offbyte+1] = old1 OR new1
	gdata[offbyte+2] = old2 OR new2
END SUB
'
'
' *****  Initialize  *****
'
SUB Initialize
	DIM hx[255]
	DIM hash[4095,]
	DIM bitmask[31]
	bitmask[ 0] = 0x00000000
	bitmask[ 1] = 0x00000001
	bitmask[ 2] = 0x00000003
	bitmask[ 3] = 0x00000007
	bitmask[ 4] = 0x0000000F
	bitmask[ 5] = 0x0000001F
	bitmask[ 6] = 0x0000003F
	bitmask[ 7] = 0x0000007F
	bitmask[ 8] = 0x000000FF
	bitmask[ 9] = 0x000001FF
	bitmask[10] = 0x000003FF
	bitmask[11] = 0x000007FF
	bitmask[12] = 0x00000FFF
	bitmask[13] = 0x00001FFF
	bitmask[14] = 0x00003FFF
	bitmask[15] = 0x00007FFF
	bitmask[16] = 0x0000FFFF
	bitmask[17] = 0x0001FFFF
	bitmask[18] = 0x0003FFFF
	bitmask[19] = 0x0007FFFF
	bitmask[20] = 0x000FFFFF
	bitmask[21] = 0x001FFFFF
	bitmask[22] = 0x003FFFFF
	bitmask[23] = 0x007FFFFF
	bitmask[24] = 0x00FFFFFF
	bitmask[25] = 0x01FFFFFF
	bitmask[26] = 0x03FFFFFF
	bitmask[27] = 0x07FFFFFF
	bitmask[28] = 0x0FFFFFFF
	bitmask[29] = 0x1FFFFFFF
	bitmask[30] = 0x3FFFFFFF
	bitmask[31] = 0x7FFFFFFF
'
	hx[  0] = 0xF3C9:	hx[ 64] = 0x811D:	hx[128] = 0x199C:	hx[192] = 0xD0C8
	hx[  1] = 0xE034:	hx[ 65] = 0xC6E3:	hx[129] = 0x1299:	hx[193] = 0x3C07
	hx[  2] = 0xB37C:	hx[ 66] = 0xCA5D:	hx[130] = 0xA314:	hx[194] = 0xDDCA
	hx[  3] = 0x4E31:	hx[ 67] = 0x5AF2:	hx[131] = 0xEF45:	hx[195] = 0xB2C1
	hx[  4] = 0xC0DE:	hx[ 68] = 0xB2F3:	hx[132] = 0xEFC3:	hx[196] = 0x6A7C
	hx[  5] = 0x2487:	hx[ 69] = 0xCF28:	hx[133] = 0x8A2D:	hx[197] = 0x5E02
	hx[  6] = 0x98E2:	hx[ 70] = 0x4714:	hx[134] = 0x2553:	hx[198] = 0x4C8B
	hx[  7] = 0x557C:	hx[ 71] = 0x32B0:	hx[135] = 0x8CA6:	hx[199] = 0x6652
	hx[  8] = 0xA6CB:	hx[ 72] = 0x9A76:	hx[136] = 0x60B8:	hx[200] = 0x3C50
	hx[  9] = 0x410D:	hx[ 73] = 0xB2A4:	hx[137] = 0x2192:	hx[201] = 0x02B8
	hx[ 10] = 0x7767:	hx[ 74] = 0xDE9B:	hx[138] = 0xA15C:	hx[202] = 0x7B70
	hx[ 11] = 0x3861:	hx[ 75] = 0xE0E1:	hx[139] = 0xA527:	hx[203] = 0x118F
	hx[ 12] = 0x5517:	hx[ 76] = 0xA7C3:	hx[140] = 0x1FAC:	hx[204] = 0xEF65
	hx[ 13] = 0x0918:	hx[ 77] = 0x0E48:	hx[141] = 0xC554:	hx[205] = 0x3D6E
	hx[ 14] = 0xF3AF:	hx[ 78] = 0xFABE:	hx[142] = 0x5ECB:	hx[206] = 0xCAB2
	hx[ 15] = 0x2EAB:	hx[ 79] = 0xE351:	hx[143] = 0x7941:	hx[207] = 0x23F0
	hx[ 16] = 0x210D:	hx[ 80] = 0x4419:	hx[144] = 0x3EA2:	hx[208] = 0x927F
	hx[ 17] = 0xDF19:	hx[ 81] = 0x5AB4:	hx[145] = 0xE73D:	hx[209] = 0x1F12
	hx[ 18] = 0x2F0B:	hx[ 82] = 0xDDF9:	hx[146] = 0xDE62:	hx[210] = 0xEDCE
	hx[ 19] = 0x269A:	hx[ 83] = 0x513E:	hx[147] = 0x9FFA:	hx[211] = 0x0D52
	hx[ 20] = 0xE171:	hx[ 84] = 0x1BDF:	hx[148] = 0x0CE8:	hx[212] = 0x69B5
	hx[ 21] = 0x8D07:	hx[ 85] = 0xA0BC:	hx[149] = 0x8683:	hx[213] = 0x9DC4
	hx[ 22] = 0x0AF1:	hx[ 86] = 0xC2E5:	hx[150] = 0x481C:	hx[214] = 0x910F
	hx[ 23] = 0x4627:	hx[ 87] = 0x5917:	hx[151] = 0x80E4:	hx[215] = 0xEE6D
	hx[ 24] = 0x7C4B:	hx[ 88] = 0x0448:	hx[152] = 0xC43E:	hx[216] = 0xA0E7
	hx[ 25] = 0xA59A:	hx[ 89] = 0xE110:	hx[153] = 0x7830:	hx[217] = 0xF2ED
	hx[ 26] = 0x561F:	hx[ 90] = 0xA4C8:	hx[154] = 0x3952:	hx[218] = 0x6EA2
	hx[ 27] = 0x1F90:	hx[ 91] = 0x5BC6:	hx[155] = 0x2BBA:	hx[219] = 0xFEFC
	hx[ 28] = 0x9407:	hx[ 92] = 0x1250:	hx[156] = 0x476D:	hx[220] = 0x0A20
	hx[ 29] = 0xAAAA:	hx[ 93] = 0x3D09:	hx[157] = 0xF307:	hx[221] = 0xA568
	hx[ 30] = 0x404B:	hx[ 94] = 0xD230:	hx[158] = 0x5A6A:	hx[222] = 0xB90E
	hx[ 31] = 0xCCB2:	hx[ 95] = 0x19F1:	hx[159] = 0x232A:	hx[223] = 0xFA26
	hx[ 32] = 0xB6B8:	hx[ 96] = 0x28D0:	hx[160] = 0x36DA:	hx[224] = 0xFB8E
	hx[ 33] = 0x93E5:	hx[ 97] = 0x0FD7:	hx[161] = 0x1448:	hx[225] = 0x3091
	hx[ 34] = 0xCD83:	hx[ 98] = 0x79BD:	hx[162] = 0x016A:	hx[226] = 0x56A1
	hx[ 35] = 0x8392:	hx[ 99] = 0xE856:	hx[163] = 0xF0CC:	hx[227] = 0x184A
	hx[ 36] = 0x951B:	hx[100] = 0xDDDE:	hx[164] = 0x5328:	hx[228] = 0xDEC0
	hx[ 37] = 0x983F:	hx[101] = 0xBD28:	hx[165] = 0x8B83:	hx[229] = 0xC39F
	hx[ 38] = 0x1BB3:	hx[102] = 0xD9F7:	hx[166] = 0x1566:	hx[230] = 0xBED3
	hx[ 39] = 0x40A7:	hx[103] = 0xCBB9:	hx[167] = 0xB0D3:	hx[231] = 0x51F5
	hx[ 40] = 0x5D7E:	hx[104] = 0x9B85:	hx[168] = 0xCE2F:	hx[232] = 0xC0E9
	hx[ 41] = 0x65A1:	hx[105] = 0x82DC:	hx[169] = 0x30FA:	hx[233] = 0x617B
	hx[ 42] = 0x8576:	hx[106] = 0x67B0:	hx[170] = 0x49C6:	hx[234] = 0xF6E9
	hx[ 43] = 0xAC39:	hx[107] = 0x8720:	hx[171] = 0x94D9:	hx[235] = 0x9775
	hx[ 44] = 0xFE04:	hx[108] = 0x0CDF:	hx[172] = 0xE69B:	hx[236] = 0xD5A5
	hx[ 45] = 0x6C6F:	hx[109] = 0xA884:	hx[173] = 0x7B2C:	hx[237] = 0xF7D3
	hx[ 46] = 0x838F:	hx[110] = 0x238D:	hx[174] = 0x340B:	hx[238] = 0x2BD5
	hx[ 47] = 0xDA44:	hx[111] = 0xACED:	hx[175] = 0x2E46:	hx[239] = 0xBB3D
	hx[ 48] = 0x7B93:	hx[112] = 0x773B:	hx[176] = 0xFD83:	hx[240] = 0x1483
	hx[ 49] = 0x851E:	hx[113] = 0x84F1:	hx[177] = 0xB1A9:	hx[241] = 0x5906
	hx[ 50] = 0xD23F:	hx[114] = 0xB1A6:	hx[178] = 0x6F78:	hx[242] = 0x6D25
	hx[ 51] = 0x1F47:	hx[115] = 0x049F:	hx[179] = 0xF3FE:	hx[243] = 0x0BEE
	hx[ 52] = 0x7C74:	hx[116] = 0x8B30:	hx[180] = 0x387B:	hx[244] = 0xE76B
	hx[ 53] = 0xBF9D:	hx[117] = 0xB545:	hx[181] = 0xCCC2:	hx[245] = 0x6751
	hx[ 54] = 0x7646:	hx[118] = 0x48EC:	hx[182] = 0x762C:	hx[246] = 0x2A06
	hx[ 55] = 0xC9FF:	hx[119] = 0xF885:	hx[183] = 0x603E:	hx[247] = 0x49E3
	hx[ 56] = 0x7944:	hx[120] = 0x3985:	hx[184] = 0x02F9:	hx[248] = 0x9854
	hx[ 57] = 0x953D:	hx[121] = 0x3D6A:	hx[185] = 0x3F51:	hx[249] = 0x11F4
	hx[ 58] = 0xE666:	hx[122] = 0x6871:	hx[186] = 0x6C2E:	hx[250] = 0xA655
	hx[ 59] = 0xB2DA:	hx[123] = 0x2F08:	hx[187] = 0x0777:	hx[251] = 0x742F
	hx[ 60] = 0x743C:	hx[124] = 0x94DE:	hx[188] = 0xE456:	hx[252] = 0x8C19
	hx[ 61] = 0xDB99:	hx[125] = 0x4CA5:	hx[189] = 0x7AA0:	hx[253] = 0xB74A
	hx[ 62] = 0x48BB:	hx[126] = 0xD5EA:	hx[190] = 0x0766:	hx[254] = 0xD219
	hx[ 63] = 0xF794:	hx[127] = 0xAD4C:	hx[191] = 0x4882:	hx[255] = 0x63DD
END SUB
END FUNCTION
END PROGRAM

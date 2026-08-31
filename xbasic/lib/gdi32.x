'
' ####################
' #####  PROLOG  #####
' ####################
'
' This program implements part of the gdi32 portion of the
' Microsoft Windows Win32 API for UNIX programs.
'
' Ideally portable programs should not call UNIX, X-Windows,
' or Windows functions directly.  Some programs that do call
' UNIX, XWindows, or Windows functions are still portable,
' however, because of cross-platform compatibility libraries
' like this one.  These libraries work in a simple manner.
'
' When a program running on Windows/WindowsNT calls a Windows
' API function, the Windows API function is directly invoked.
' When the same program running on UNIX calls a Windows API
' function, the Windows API function does not exist, but a
' function in this library with the same name does, and is
' thus invoked in the same manner as the Windows function.
' The substitute function in this library tries to perform
' the same service as the Windows API function, and in most
' cases there is little or no difference.
'
' The cross-platform compatibility libraries do not contain
' every Windows API function, and not every included function
' performs the exact same action or returns the same result.
' Some cross-platform compatibility functions exist, but do
' nothing at all (except perhaps return an error indication),
' though their inclusion does make it possible to at least
' run programs that call them.
'
' This library is FAR from complete at this time, but updates
' are expected on a regular basis.  Please give us feedback.
'
PROGRAM "gdi32"
VERSION "0.0000"
'
IMPORT  "clib"
IMPORT  "xwin"
'
EXPORT
DECLARE FUNCTION  Arc                        (hdc, left, top, right, bottom, x1, y1, x2, y2)
DECLARE FUNCTION  BitBlt                     (hdc, x, y, w, h, hdcImage, xSrc, ySrc, mode)
DECLARE FUNCTION  CreateCompatibleBitmap     (hdc, width, height)
DECLARE FUNCTION  CreateCompatibleDC         (hdc)
DECLARE FUNCTION  CreateFontIndirectA        (logFontAddr)
DECLARE FUNCTION  CreateRectRgn              (left, top, right, bottom)
DECLARE FUNCTION  CreateSolidBrush           (color)
DECLARE FUNCTION  CreatePen                  (style, width, color)
DECLARE FUNCTION  DeleteDC                   (hdc)
DECLARE FUNCTION  DeleteObject               (object)
DECLARE FUNCTION  Ellipse                    (hdc, left, top, right, bottom)
DECLARE FUNCTION  EnumFontFamiliesA          (hdc, fontNameAddr, callbackProc, lParam)
DECLARE FUNCTION  GdiFlush                   ()
DECLARE FUNCTION  GdiSetBatchLimit           (limit)
DECLARE FUNCTION  GetCurrentObject           (hdc, objType)
DECLARE FUNCTION  GetDeviceCaps              (hdc, index)
DECLARE FUNCTION  GetDIBits                  (hdc, hBitmap, startScan, scanLines, dataAddr, infoAddr, usage)
DECLARE FUNCTION  GetMapMode                 (hdc)
DECLARE FUNCTION  GetPixel                   (hdc, x, y)
DECLARE FUNCTION  GetStockObject             (object)
DECLARE FUNCTION  GetTextExtentPointA        (hdc, textAddr, lenText, stringSize)
DECLARE FUNCTION  GetTextMetricsA            (hdc, textMetric)
DECLARE FUNCTION  GetViewportExtEx           (hdc, buffAddr)
DECLARE FUNCTION  GetWindowExtEx             (hdc, buffAddr)
DECLARE FUNCTION  Polyline                   (hdc, pointsAddr, numPoints)
DECLARE FUNCTION  PolyPolyline               (hdc, pointsAddr, polyPointsAddr, numPoints)
DECLARE FUNCTION  Rectangle                  (hdc, x, y, w, h)
DECLARE FUNCTION  SelectClipRgn              (hdc, hrgn)
DECLARE FUNCTION  SelectObject               (hdc, object)
DECLARE FUNCTION  SetBkColor                 (hdc, color)
DECLARE FUNCTION  SetBkMode                  (hdc, nMode)
DECLARE FUNCTION  SetDIBits                  (hdc, hBitmap, startScan, scanLines, DIBdata, bitmapInfo, usage)
DECLARE FUNCTION  SetDIBitsToDevice          (hdc, xDest, yDest, width, height, xSrc, ySrc, startScan, scanLines, DIBdata, bitmapInfo, usage)
DECLARE FUNCTION  SetMapMode                 (hdc, mapMode)
DECLARE FUNCTION  SetROP2                    (hdc, nDrawMode)
DECLARE FUNCTION  SetStretchBltMode          (hdc, mode)
DECLARE FUNCTION  SetTextColor               (hdc, pixel)
DECLARE FUNCTION  SetViewportExtEx           (hdc, xExt, yExt, buffAddr)
DECLARE FUNCTION  SetWindowExtEx             (hdc, xExt, yExt, buffAddr)
DECLARE FUNCTION  StretchBlt                 (hdc, x, y, w, h, hdcImage, xSrc, ySrc, wSrc, hSrc, mode)
DECLARE FUNCTION  TextOutA                   (hdc, x, y, textAddr, lenText)
END EXPORT
'
'
' ####################
' #####  Arc ()  #####
' ####################
'
FUNCTION  Arc (hdc, left, top, right, bottom, x1, y1, x2, y2)
'
' PRINT "gdi32 : Arc ()"
'
END FUNCTION
'
'
' #######################
' #####  BitBlt ()  #####
' #######################
'
FUNCTION  BitBlt (hdc, x, y, w, h, hdcImage, xSrc, ySrc, mode)
'
' PRINT "gdi32 : BitBlt ()"
'
END FUNCTION
'
'
' #######################################
' #####  CreateCompatibleBitmap ()  #####
' #######################################
'
FUNCTION  CreateCompatibleBitmap (hdc, width, height)
'
' PRINT "gdi32 : CreateCompatibleBitmap ()"
'
END FUNCTION
'
'
' ###################################
' #####  CreateCompatibleDC ()  #####
' ###################################
'
FUNCTION  CreateCompatibleDC (hdc)
'
' PRINT "gdi32 : CreateCompatibleDC ()"
'
END FUNCTION
'
'
' ####################################
' #####  CreateFontIndirectA ()  #####
' ####################################
'
FUNCTION  CreateFontIndirectA (logFontAddr)
'
' PRINT "gdi32 : CreateFontIndirectA ()"
'
END FUNCTION
'
'
' ##############################
' #####  CreateRectRgn ()  #####
' ##############################
'
FUNCTION  CreateRectRgn (left, top, right, bottom)
'
' PRINT "gdi32 : CreateRectRgn ()"
'
END FUNCTION
'
'
' #################################
' #####  CreateSolidBrush ()  #####
' #################################
'
FUNCTION  CreateSolidBrush (color)
'
' PRINT "gdi32 : CreateSolidBrush ()"
'
END FUNCTION
'
'
' ##########################
' #####  CreatePen ()  #####
' ##########################
'
FUNCTION  CreatePen (style, width, color)
'
' PRINT "gdi32 : CreatePen ()"
'
END FUNCTION
'
'
' #########################
' #####  DeleteDC ()  #####
' #########################
'
FUNCTION  DeleteDC (hdc)
'
' PRINT "gdi32 : DeleteDC ()"
'
END FUNCTION
'
'
' #############################
' #####  DeleteObject ()  #####
' #############################
'
FUNCTION  DeleteObject (object)
'
' PRINT "gdi32 : DeleteObject ()"
'
END FUNCTION
'
'
' ########################
' #####  Ellipse ()  #####
' ########################
'
FUNCTION  Ellipse (hdc, left, top, right, bottom)
'
' PRINT "gdi32 : Ellipse ()"
'
END FUNCTION
'
'
' ##################################
' #####  EnumFontFamiliesA ()  #####
' ##################################
'
FUNCTION  EnumFontFamiliesA (hdc, fontNameAddr, callbackProc, lParam)
'
' PRINT "gdi32 : EnumFontFamiliesA ()"
'
END FUNCTION
'
'
'
' #########################
' #####  GdiFlush ()  #####
' #########################
'
FUNCTION  GdiFlush ()
'
' PRINT "gdi32 : GdiFlush ()
'
END FUNCTION
'
'
' #################################
' #####  GdiSetBatchLimit ()  #####
' #################################
'
FUNCTION  GdiSetBatchLimit (limit)
'
' PRINT "gdi32 : GdiSetBatchLimit ()"
'
END FUNCTION
'
'
' #################################
' #####  GetCurrentObject ()  #####
' #################################
'
FUNCTION  GetCurrentObject (hdc, objType)
'
' PRINT "gdi32 : GetCurrentObject ()"
'
END FUNCTION
'
'
' ##############################
' #####  GetDeviceCaps ()  #####
' ##############################
'
FUNCTION  GetDeviceCaps (hdc, index)
'
' PRINT "gdi32 : GetDeviceCaps ()"
'
END FUNCTION
'
'
' ##########################
' #####  GetDIBits ()  #####
' ##########################
'
FUNCTION  GetDIBits (hdc, hBitmap, startScan, scanLines, dataAddr, infoAddr, usage)
'
' PRINT "gdi32 : GetDIBits ()"
'
END FUNCTION
'
'
' ###########################
' #####  GetMapMode ()  #####
' ###########################
'
FUNCTION  GetMapMode (hdc)
'
' PRINT "gdi32 : GetMapMode ()"
'
END FUNCTION
'
'
' #########################
' #####  GetPixel ()  #####
' #########################
'
FUNCTION  GetPixel (hdc, x, y)
'
' PRINT "gdi32 : GetPixel ()"
'
END FUNCTION
'
'
' ###############################
' #####  GetStockObject ()  #####
' ###############################
'
FUNCTION  GetStockObject (object)
'
' PRINT "gdi32 : GetStockObject ()"
'
END FUNCTION
'
'
' ####################################
' #####  GetTextExtentPointA ()  #####
' ####################################
'
FUNCTION  GetTextExtentPointA (hdc, textAddr, lenText, stringSize)
'
' PRINT "gdi32 : GetTextExtentPointA ()"
'
END FUNCTION
'
'
' ################################
' #####  GetTextMetricsA ()  #####
' ################################
'
FUNCTION  GetTextMetricsA (hdc, textMetric)
'
' PRINT "gdi32 : GetTextMetricsA ()"
'
END FUNCTION
'
'
' #################################
' #####  GetViewportExtEx ()  #####
' #################################
'
FUNCTION  GetViewportExtEx (hdc, buffAddr)
'
' PRINT "gdi32 : GetViewportExtEx ()"
'
END FUNCTION
'
'
' ###############################
' #####  GetWindowExtEx ()  #####
' ###############################
'
FUNCTION  GetWindowExtEx (hdc, buffAddr)
'
' PRINT "gdi32 : GetWindowExtEx ()"
'
END FUNCTION
'
'
' #########################
' #####  Polyline ()  #####
' #########################
'
FUNCTION  Polyline (hdc, pointsAddr, numPoints)
'
' PRINT "gdi32 : Polyline ()"
'
END FUNCTION
'
'
' #############################
' #####  PolyPolyline ()  #####
' #############################
'
FUNCTION  PolyPolyline (hdc, pointsAddr, polyPointsAddr, numPoints)
'
' PRINT "gdi32 : PolyPolyline ()"
'
END FUNCTION
'
'
' ##########################
' #####  Rectangle ()  #####
' ##########################
'
FUNCTION  Rectangle (hdc, x, y, w, h)
'
' PRINT "gdi32 : Rectangle ()"
'
END FUNCTION
'
'
' ##############################
' #####  SelectClipRgn ()  #####
' ##############################
'
FUNCTION  SelectClipRgn (hdc, hrgn)
'
' PRINT "gdi32 : SelectClipRgn ()"
'
END FUNCTION
'
'
' #############################
' #####  SelectObject ()  #####
' #############################
'
FUNCTION  SelectObject (hdc, object)
'
' PRINT "gdi32 : SelectObject ()"
'
END FUNCTION
'
'
' ###########################
' #####  SetBkColor ()  #####
' ###########################
'
FUNCTION  SetBkColor (hdc, color)
'
' PRINT "gdi32 : SetBkColor ()"
'
END FUNCTION
'
'
' ##########################
' #####  SetBkMode ()  #####
' ##########################
'
FUNCTION  SetBkMode (hdc, nMode)
'
' PRINT "gdi32 : SetBkMode ()"
'
END FUNCTION
'
'
' ##########################
' #####  SetDIBits ()  #####
' ##########################
'
FUNCTION  SetDIBits (hdc, hBitmap, startScan, scanLines, DIBdata, bitmapInfo, usage)
'
' PRINT "gdi32 : SetDIBits ()"
'
END FUNCTION
'
'
' ##################################
' #####  SetDIBitsToDevice ()  #####
' ##################################
'
FUNCTION  SetDIBitsToDevice (hdc, xDest, yDest, width, height, xSrc, ySrc, startScan, scanLines, DIBdata, bitmapInfo, usage)
'
' PRINT "gdi32 : SetDIBitsToDevice ()"
'
END FUNCTION
'
'
' ###########################
' #####  SetMapMode ()  #####
' ###########################
'
FUNCTION  SetMapMode (hdc, mapMode)
'
' PRINT "gdi32 : SetMapMode ()"
'
END FUNCTION
'
'
' ########################
' #####  SetROP2 ()  #####
' ########################
'
FUNCTION  SetROP2 (hdc, nDrawMode)
'
' PRINT "gdi32 : SetROP2 ()"
'
END FUNCTION
'
'
' ##################################
' #####  SetStretchBltMode ()  #####
' ##################################
'
FUNCTION  SetStretchBltMode (hdc, mode)
'
' PRINT "gdi32 : SetStretchBltMode ()"
'
END FUNCTION
'
'
' #############################
' #####  SetTextColor ()  #####
' #############################
'
FUNCTION  SetTextColor (hdc, pixel)
'
' PRINT "gdi32 : SetTextColor ()"
'
END FUNCTION
'
'
' #################################
' #####  SetViewportExtEx ()  #####
' #################################
'
FUNCTION  SetViewportExtEx (hdc, xExt, yExt, buffAddr)
'
' PRINT "gdi32 : SetViewportExtEx ()"
'
END FUNCTION
'
'
' ###############################
' #####  SetWindowExtEx ()  #####
' ###############################
'
FUNCTION  SetWindowExtEx (hdc, xExt, yExt, buffAddr)
'
' PRINT "gdi32 : SetWindowExtEx ()"
'
END FUNCTION
'
'
' ###########################
' #####  StretchBlt ()  #####
' ###########################
'
FUNCTION  StretchBlt (hdc, x, y, w, h, hdcImage, xSrc, ySrc, wSrc, hSrc, mode)
'
' PRINT "gdi32 : StretchBlt ()"
'
END FUNCTION
'
'
' #########################
' #####  TextOutA ()  #####
' #########################
'
FUNCTION  TextOutA (hdc, x, y, textAddr, lenText)
'
' PRINT "gdi32 : TextOutA ()"
'
END FUNCTION
END PROGRAM

'
'
' ####################  Max Reason
' #####  PROLOG  #####  copyright 1988-2000
' ####################  Linux XBasic standard function library
'
' subject to LGPL license - see COPYING_LIB
'
' maxreason@maxreason.com
'
' for Linux XBasic
'
'
PROGRAM "xst"
VERSION "6.4.5"
'
IMPORT  "xma"
IMPORT  "xgr"
IMPORT  "xui"
IMPORT  "clib"
IMPORT  "xlib"
IMPORT  "kernel32"
IMPORT	"xut"
'
EXPORT
'
' **********************************************
' *****  Standard Library Composite Types  *****
' **********************************************
'
'TYPE FILEINFO
'	XLONG        .attributes
'	XLONG        .createTimeLow
'	XLONG        .createTimeHigh
'	XLONG        .accessTimeLow
'	XLONG        .accessTimeHigh
'	XLONG        .modifyTimeLow
'	XLONG        .modifyTimeHigh
'	XLONG        .sizeHigh
'	XLONG        .sizeLow
'	XLONG        .res0
'	XLONG        .res1
'	STRING*260   .name
'	STRING*14    .alternateName
'END TYPE
'
TYPE FILEINFO
	XLONG        .attributes
	GIANT        .createTime
	GIANT        .accessTime
	GIANT        .modifyTime
	GIANT        .size
'	XLONG        .res0
'	XLONG        .res1
	STRING*260   .name
	STRING*14    .alternateName
END TYPE
'
TYPE MEMORYMAP
	XLONG        .code0
	XLONG        .code
	XLONG        .codex
	XLONG        .codez
	XLONG        .data0
	XLONG        .data
	XLONG        .datax
	XLONG        .dataz
	XLONG        .bss0
	XLONG        .bss
	XLONG        .bssx
	XLONG        .bssz
	XLONG        .dyno0
	XLONG        .dyno
	XLONG        .dynox
	XLONG        .dynoz
	XLONG        .ucode0
	XLONG        .ucode
	XLONG        .ucodex
	XLONG        .ucodez
	XLONG        .stack0
	XLONG        .stack
	XLONG        .stackx
	XLONG        .stackz
END TYPE
'
TYPE SAVELOADARRAYHDR
	STRING*4	.magic
	ULONG			.typeFlags
END TYPE
END EXPORT
'
TYPE TASK
	XLONG        .count      ' iterations remaining to call task
	XLONG        .msec       ' millisecond interval of this task
	XLONG        .taskFunc   ' address of function being called
	XLONG        .timer      ' number of timer doing the interval timing
	XLONG        .whomask    ' whomask of task owner
	XLONG        .engaged    ' set when taskFunc called, cleared when it returns
	XLONG        .request    ' set when task timer jams TimeOut message
	XLONG        .skips      ' count of requests not sent because previous one not done
END TYPE
'
TYPE TIMER
	XLONG        .tgrid      ' grid number if called by a XgrSetGridTimer()
	XLONG        .timer      ' timer #
	XLONG        .count      ' desired number of timeouts
	XLONG        .func       ' function to call whenever this timer expires
	XLONG        .msec       ' millisecond interval of this timer
	XLONG        .sec        ' expected expire time seconds (from ftime())
	XLONG        .usec       ' expected expire time microseconds (ditto)
	XLONG        .active     ' system interval timer is currently counting this timer
	XLONG        .whomask    ' whomask of timer owner
END TYPE
'
TYPE FILE
	STRING*112   .fileName
	SLONG        .fileHandle   '*cw* 230112-+
	SLONG        .whomask      '*cw* 230112-+
	SLONG        .consoleGrid  '*cw* 230112-+
	SLONG        .entries      '*cw* 230112-+
END TYPE
'
TYPE LOCK
	XLONG        .file
	XLONG        .sfile
	GIANT        .offset
	GIANT        .length
	GIANT        .end
END TYPE
'
TYPE USTAT64
	SSHORT     .st_dev
	USHORT     .st_ino
	USHORT     .st_mode
	SSHORT     .st_nlink
	USHORT     .st_uid
	USHORT     .st_gid
	SSHORT     .st_rdev
	USHORT     .st_pad
	GIANT      .st_size
	GIANT      .st_atime
	GIANT      .st_mtime
	GIANT      .st_ctime
END TYPE
'
TYPE USTAT64_old
	USHORT     .st_dev
	USHORT     .st_pad1
	ULONG      .st_ino
	USHORT     .st_mode
	USHORT     .st_nlink
	USHORT     .st_uid
	USHORT     .st_gid
	USHORT     .st_rdev
	USHORT     .st_pad
	GIANT      .st_size
	ULONG      .st_blksize
	ULONG      .st_blocks
	ULONG      .st_atime
	ULONG      .st_unused1
	ULONG      .st_mtime
	ULONG      .st_unused2
	ULONG      .st_ctime
	ULONG      .st_unused3
	ULONG      .st_unused4
	ULONG      .st_unused5
END TYPE
'
EXPORT
'
'
'  ****************************************
'  *****  Standard Library Functions  *****
'  ****************************************
'
'  system functions
'
DECLARE FUNCTION  Xst                            ()
DECLARE FUNCTION  XstVersion$                    ()
DECLARE FUNCTION  XstCauseException              (exception)
DECLARE FUNCTION  XstCloseLibrary                (handle)
DECLARE FUNCTION  XstDateAndTimeToFileTime       (year, month, day, weekDay, hour, minute, second, nanos, @filetime$$)
DECLARE FUNCTION  XstErrorNameToNumber           (error$, @errNumber)
DECLARE FUNCTION  XstErrorNumberToName           (error, @error$)
DECLARE FUNCTION  XstExceptionNumberToName       (exception, @exception$)
DECLARE FUNCTION  XstExceptionToSystemException  (exception, @sysException)
DECLARE FUNCTION  XstFileTimeToDateAndTime       (filetime$$, @year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
DECLARE FUNCTION  XstFileTimeToLocalDateAndTime  (filetime$$, @year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
DECLARE FUNCTION  XstFileToSystemFile            (fileNumber, @systemFileNumber)
DECLARE FUNCTION  XstGetApplicationEnvironment   (@standalone, @reserved)
DECLARE FUNCTION  XstGetCommandLine              (@commandline$)
DECLARE FUNCTION  XstGetCommandLineArguments     (@argc, @argv$[])
DECLARE FUNCTION  XstGetConsoleGrid              (@grid)
DECLARE FUNCTION  XstGetCPUName                  (@cpu$)
DECLARE FUNCTION  XstGetDateAndTime              (@year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
DECLARE FUNCTION  XstGetLocalDateAndTime         (@year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
DECLARE FUNCTION  XstGetEndian                   (@endian$$)
DECLARE FUNCTION  XstGetEndianName               (@endian$)
DECLARE FUNCTION  XstGetEnvironmentVariable      (@name$, @value$)
DECLARE FUNCTION  XstGetEnvironmentVariables     (@count, @envp$[])
DECLARE FUNCTION  XstGetException                (@exception)
DECLARE FUNCTION  XstGetExceptionFunction        (@function)
DECLARE FUNCTION  XstGetImplementation           (@name$)
DECLARE FUNCTION  XstGetLibraryAddress           (handle, funcname$)
DECLARE FUNCTION  XstGetMemoryMap                (MEMORYMAP @memorymap)
DECLARE FUNCTION  XstGetNewline                  (@save, @paste)
DECLARE FUNCTION  XstGetOSName                   (@name$)
DECLARE FUNCTION  XstGetOSVersion                (@major, @minor)
DECLARE FUNCTION  XstGetOSVersionName            (@name$)
DECLARE FUNCTION  XstGetPrintTab                 (@pixels)
DECLARE FUNCTION  XstGetProgramName              (@program$)
DECLARE FUNCTION  XstGetSystemError              (@sysError)
DECLARE FUNCTION  XstGetSystemTime               (@msec)
DECLARE FUNCTION  XstGetTaskInfo                 (taskNum, @count, @msec, @func, @timer, @skips)
DECLARE FUNCTION  XstKillTask                    (taskNum)
DECLARE FUNCTION  XstKillTimer                   (timer)
DECLARE FUNCTION  XstLog                         (text$)
DECLARE FUNCTION  XstOpenLibrary                 (name$)
DECLARE FUNCTION  XstSetCommandLineArguments     (argc, @argv$[])
DECLARE FUNCTION  XstSetDateAndTime              (year, month, day, weekDay, hour, minute, second, nanos)
DECLARE FUNCTION  XstSetEnvironmentVariable      (@name$, @value$)
DECLARE FUNCTION  XstSetException                (exception)
DECLARE FUNCTION  XstSetExceptionFunction        (function)
DECLARE FUNCTION  XstSetNewline                  (save, paste)
DECLARE FUNCTION  XstSetPrintTab                 (pixels)
DECLARE FUNCTION  XstSetProgramName              (@program$)
DECLARE FUNCTION  XstSetSystemError              (sysError)
DECLARE FUNCTION  XstSleep                       (milliSec)
DECLARE FUNCTION  XstStartTask                   (taskNum, count, msec, func)
DECLARE FUNCTION  XstStartTimer                  (timer, count, msec, func)
'
DECLARE FUNCTION  XstSystemErrorToError          (sysError, @error)
DECLARE FUNCTION  XstSystemErrorNumberToName     (sysError, @sysError$)
DECLARE FUNCTION  XstSystemExceptionNumberToName (sysException, @sysException$)
DECLARE FUNCTION  XstSystemExceptionToException  (sysException, @exception)
'
' console functions
'
DECLARE FUNCTION  XstClearConsole                ()
DECLARE FUNCTION  XstCreateConsole               (xDisp, yDisp, width, height)
DECLARE FUNCTION  XstDisplayConsole              ()
DECLARE FUNCTION  XstGetConsoleFont              (size, weight, italic, angle, font$)
DECLARE FUNCTION  XstGetConsolePositionAndSize   (xDisp, yDisp, width, height)
DECLARE FUNCTION  XstGetConsoleStyleAndColors    (style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi)
DECLARE FUNCTION  XstHideConsole                 ()
DECLARE FUNCTION  XstInKey$                      ()
DECLARE FUNCTION  XstSetConsoleFont              (size, weight, italic, angle, font$)
DECLARE FUNCTION  XstSetConsoleStyleAndColors    (style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi)
DECLARE FUNCTION  XstShowConsole                 ()
DECLARE FUNCTION  XstWaitKey$                    ()
'
'  file functions
'
DECLARE FUNCTION  XstBinRead                     (fileNumber, bufferAddr, maxBytes)
DECLARE FUNCTION  XstBinWrite                    (fileNumber, bufferAddr, numBytes)
DECLARE FUNCTION  XstChangeDirectory             (directory$)
DECLARE FUNCTION  XstCopyDirectory               (source$, dest$)
DECLARE FUNCTION  XstCopyFile                    (source$, dest$)
DECLARE FUNCTION  XstDecomposePathname           (pathname$, @path$, @parent$, @fileName$, @file$, @extent$)
DECLARE FUNCTION  XstDeleteFile                  (file$)
DECLARE FUNCTION  XstFindFile                    (file$, @path$[], @path$, @attr)
DECLARE FUNCTION  XstFindFiles                   (basepath$, filter$, recurse, @file$[])
DECLARE FUNCTION  XstFileSelect                  (windowTitle$, @fileName$)
DECLARE FUNCTION  XstFileSelectGetInfo           (@path$, @filter$, @xDisp, @yDisp, @width, @height)
DECLARE FUNCTION  XstFileSelectOpen              (mode, @fileName$, @fileNumber)
DECLARE FUNCTION  XstFileSelectSetInfo           (path$, filter$, xDisp, yDisp, width, height)
DECLARE FUNCTION  XstGetCurrentDirectory         (@directory$)
DECLARE FUNCTION  XstGetDrives                   (@count, @drive$[], @driveType[], @driveType$[])
DECLARE FUNCTION  XstGetExecutionPathArray       (@path$[])
DECLARE FUNCTION  XstGetFileAttributes           (file$, @attributes)
DECLARE FUNCTION  XstGetFiles                    (filter$, @file$[])
DECLARE FUNCTION  XstGetFilesAndAttributes       (filter$, attributeFilter, @file$[], FILEINFO @attrInfo[])
DECLARE FUNCTION  XstGetPathComponents           (file$, @path$, @drive$, @dir$, @fileName$, @attributes)
DECLARE FUNCTION  XstGuessFilename               (old$, @new$, @guess$, @attributes)
DECLARE FUNCTION  XstLoadString                  (file$, @text$)
DECLARE FUNCTION  XstLoadStringArray             (file$, @text$[])
DECLARE FUNCTION  XstLockFileSection             (fileNumber, mode, offset$$, length$$)
DECLARE FUNCTION  XstMakeDirectory               (directory$)
DECLARE FUNCTION  XstPathString$                 (path$)
DECLARE FUNCTION  XstPathToAbsolutePath          (ipath$, @opath$)
DECLARE FUNCTION  XstReadString                  (ifile, @string$)
DECLARE FUNCTION  XstRenameFile                  (old$, new$)
DECLARE FUNCTION  XstSaveString                  (file$, text$)
DECLARE FUNCTION  XstSaveStringArray             (file$, text$[])
DECLARE FUNCTION  XstSaveStringArrayCRLF         (file$, text$[])
DECLARE FUNCTION  XstSetCurrentDirectory         (directory$)
DECLARE FUNCTION  XstSymbolicPathToPath$         (symbolicPath$)
DECLARE FUNCTION  XstUnlockFileSection           (fileNumber, mode, offset$$, length$$)
DECLARE FUNCTION  XstWindowSizePercent           (@xPercent, @yPercent, @wPercent, @hPercent, windowType)
DECLARE FUNCTION  XstWriteString                 (ofile, @string$)
'
' preference file functions
'
INTERNAL FUNCTION  XstIsPrefValid                (pfile)
INTERNAL FUNCTION  XstGetPrefKeyLine             (pfile, key$, @line, @sectionFound, @keyFound)
INTERNAL FUNCTION  XstPrefAddLine                (pfile, line, text$)
INTERNAL FUNCTION  XstPrefDeleteLine             (pfile, line)
DECLARE FUNCTION  XstOpenPref                    (file$)
DECLARE FUNCTION  XstGetPrefFile                 (pfile, @file$)
DECLARE FUNCTION  XstSavePref                    (pfile)
DECLARE FUNCTION  XstDiscardPref                 (pfile)
DECLARE FUNCTION  XstClosePref                   (pfile)
DECLARE FUNCTION  XstDeletePrefKey               (pfile, key$)
DECLARE FUNCTION  XstDeletePrefSection           (pfile, section$)
DECLARE FUNCTION  XstSetPrefSection              (pfile, section$)
DECLARE FUNCTION  XstGetPrefSection              (pfile, @section$)
DECLARE FUNCTION  XstSetPrefSTRING							 (pfile, key$, value$)
DECLARE FUNCTION  XstSetPrefXLONG								 (pfile, key$, value)
DECLARE FUNCTION  XstGetPrefSTRING               (pfile, key$, default$, @value$)
DECLARE FUNCTION  XstGetPrefXLONG                (pfile, key$, default, @value)
'
' Saving and loading arrays
'
DECLARE FUNCTION  XstLoadArray                   (file$, ANY[])
INTERNAL FUNCTION  XstLoadArrayData              (ifile, chunk, ANY[])
INTERNAL FUNCTION  XstLoadArrayLength            (ifile, @length)
DECLARE FUNCTION  XstSaveArray                   (file$, ANY[])
INTERNAL FUNCTION  XstSaveArrayData              (ofile, ANY[])
INTERNAL FUNCTION  XstSaveArrayLength            (ofile, length)
'
' random number functions
'
DECLARE FUNCTION  ULONG  XstRandom               ()
DECLARE FUNCTION  ULONG  XstRandomCreateSeed     ()
DECLARE FUNCTION         XstRandomRange          (n1, n2)
DECLARE FUNCTION         XstRandomSeed           (ULONG seed)
DECLARE FUNCTION  DOUBLE XstRandomUniform        ()
'
'  string and string array functions
'
DECLARE FUNCTION  XstBackArrayToBinArray         (backArray$[], @binArray$[])
DECLARE FUNCTION  XstBackStringToBinString$      (backString$)
DECLARE FUNCTION  XstBinArrayToBackArray         (binArray$[], @backArray$[])
DECLARE FUNCTION  XstBinStringToBackString$      (binString$)
DECLARE FUNCTION  XstBinStringToBackStringNL$    (binString$)
DECLARE FUNCTION  XstBinStringToBackStringThese$ (binString$, these[])
DECLARE FUNCTION  XstCompareArray                (ANY[], ANY[], @result)
DECLARE FUNCTION  XstCopyArray                   (ANY[], ANY[])
DECLARE FUNCTION  XstCopyMemory                  (sourceAddr, destAddr, bytes)
DECLARE FUNCTION  XstDeleteLines                 (array$[], start, count)
DECLARE FUNCTION  XstFindArray                   (mode, text$[], find$, line, pos, match)
DECLARE FUNCTION  XstIsDataDimension             (ANY[])
DECLARE FUNCTION  XstMergeStrings$               (string$, add$, start, replace)
DECLARE FUNCTION  XstMultiStringToStringArray    (s$, @s$[])
DECLARE FUNCTION  XstNextCField$                 (sourceAddr, @index, @done)
DECLARE FUNCTION  XstNextCLine$                  (sourceAddr, @index, @done)
DECLARE FUNCTION  XstNextField$                  (source$, @index, @done)
DECLARE FUNCTION  XstNextItem$                   (source$, @index, @term, @done)
DECLARE FUNCTION  XstNextLine$                   (source$, @index, @done)
DECLARE FUNCTION  XstReplaceArray                (mode, text$[], find$, replace$, line, pos, match)
DECLARE FUNCTION  XstReplaceLines                (d$[], s$[], firstD, countD, firstS, countS)
DECLARE FUNCTION  XstStringArraySectionToString  (text$[], @copy$, x1, y1, x2, y2, term)
DECLARE FUNCTION  XstStringArraySectionToStringArray (text$[], @copy$[], x1, y1, x2, y2)
DECLARE FUNCTION  XstStringArrayToString         (s$[], @s$)
DECLARE FUNCTION  XstStringArrayToStringCRLF     (s$[], @s$)
DECLARE FUNCTION  XstStringToStringArray         (s$, @s$[])
DECLARE FUNCTION  XstLTRIM                       (@string$, array[])
DECLARE FUNCTION  XstRTRIM                       (@string$, array[])
DECLARE FUNCTION  XstTRIM                        (@string$, array[])
DECLARE FUNCTION  XstParse$                      (source$, delimiter$, n)
DECLARE FUNCTION  XstParseStringToStringArray    (source$, delimiter$, @s$[])
DECLARE FUNCTION  XstParseWhitespace$            (string$, wordNumber)
DECLARE FUNCTION  XstParseWhitespaceToArray      (string$, @word$[])
DECLARE FUNCTION  XstTally                       (source$, find$)
'
EXTERNAL FUNCTION  XstFindMemoryMatch            (addrMemoryStart, addrMemoryPast, addrMatchString, minMatchLength, maxMatchLength)
EXTERNAL FUNCTION  XstStringToNumber             (s$, startOff, @afterOff, @rtype, @value$$)
'
'  sorting functions
'
DECLARE FUNCTION  XstCompareStrings              (addrString1, op, addrString2, flags)
DECLARE FUNCTION  XstMatchWild                   (searchMe$, searchFor$, start, matchCase)
DECLARE FUNCTION  XstQuickSort                   (ANY x[], n[], low, high, flags)
'
DECLARE FUNCTION	XstAbend											 (errorMessage$)
DECLARE FUNCTION  XstAlert                       (message$)
DECLARE FUNCTION  XstGetProgramFileName$         ()
DECLARE FUNCTION  XstGetHomePath$                ()
'
DECLARE  FUNCTION  Xio                ()
'
END EXPORT
'
' functions the PDE calls
'
DECLARE FUNCTION  XxxXstBlowback                 ()
DECLARE FUNCTION  XxxXstFreeLibrary              (libname$, handle)
DECLARE FUNCTION  XxxXstLoadLibrary              (libname$)
DECLARE FUNCTION  XxxXstTimer                    (command, tgrid, timer, count, msec, func)
DECLARE FUNCTION  XxxXstLog                      (text$)
'
' internal functions
'
INTERNAL FUNCTION  InitProgram                   ()
INTERNAL FUNCTION  XstQuickSort_XLONG            (x[], n[], low, high, flags)
INTERNAL FUNCTION  XstQuickSort_GIANT            (x$$[], n[], low, high, flags)
INTERNAL FUNCTION  XstQuickSort_DOUBLE           (x#[], n[], low, high, flags)
INTERNAL FUNCTION  XstQuickSort_STRING           (x$[], n[], low, high, flags)
INTERNAL FUNCTION  XstQuickSort_STRING_nocase    (x$[], n[], low, high, flags)
INTERNAL FUNCTION  XstQuickSort_NumericSTRING    (x$[], n[], low, high, flags)
INTERNAL FUNCTION  XxxXstTaskController          (window, message, v0, v1, v2, v3, r0, r1)
INTERNAL FUNCTION  XxxXstTaskTimer               (tgrid, timer, @count, @msec, time)
'
DECLARE FUNCTION  XxxLog                         (text$)
DECLARE FUNCTION  XxxLog2                        (text$, int)
DECLARE FUNCTION  XxxLog10                       (logMessage$, window, grid, message, v0, v1, v2, v3, r0, r1)
'EXPORT
INTERNAL FUNCTION  XxxAccess          (fileName$, mode)
DECLARE  FUNCTION  XxxClose           (fileNumber)
DECLARE  FUNCTION  XxxCloseAllUser    ()
DECLARE  FUNCTION  XxxEof             (fileNumber)
DECLARE  FUNCTION  XxxInfile$         (fileNumber)
DECLARE  FUNCTION  XxxInline$         (prompt$)
DECLARE  FUNCTION  XxxLof             (fileNumber)
DECLARE  FUNCTION  XxxOpen            (file$, openMode)
DECLARE  FUNCTION  XxxPof             (fileNumber)
DECLARE  FUNCTION  XxxQuit            (status)
DECLARE  FUNCTION  XxxReadFile        (fileNumber, buffer, bytes, bytesRead, overlapped)
DECLARE  FUNCTION  XxxSeek            (fileNumber, position)
DECLARE  FUNCTION  XxxShell           (command$)
DECLARE  FUNCTION  XxxStdio           (stdin, stdout, stderr)
DECLARE  FUNCTION  XxxWriteFile       (fileNumber, addrBuffer, bytes, addrBytesWritten, overlapped)
DECLARE  FUNCTION  XxxFormat$         (format$, argType, arg$$)
DECLARE  FUNCTION  XstIoctl           (fileNumber, command, dataAddress)
DECLARE  FUNCTION  XstMmap            (startAddress, bytes, prot, mapflags, fileNumber, offset)
'END EXPORT
'
INTERNAL FUNCTION  DeltaTimeZone      (@delta)
INTERNAL FUNCTION  InitGui            ()
INTERNAL FUNCTION  InvalidFileNumber  (fileNumber)
INTERNAL FUNCTION  ValidFormat        (format$, offset)
INTERNAL FUNCTION  ValidFmt           (format$, offset)
'
' xlib function in Windows version
'
INTERNAL FUNCTION  XxxTerminate       ()
INTERNAL FUNCTION  XxxGuessFilename   (old$, new$, @guess$, @attributes)
INTERNAL FUNCTION  XxxPathString$     (path$)
DECLARE FUNCTION  XxxLogNoNL                         (text$)
DECLARE FUNCTION  XstLogRegs          (reg1, reg2, reg3, reg4, reg5, reg6, reg7)
'
' GraphicsDesigner functions
'
EXTERNAL FUNCTION  XxxXgrSysMessages      ()
EXTERNAL FUNCTION  XxxXgrQuit             ()
EXTERNAL FUNCTION  XxxXgrSleep            (msec)
'
' Xit functions
'
EXTERNAL FUNCTION  XitSoftBreak             ()
EXTERNAL FUNCTION  XxxSetBlowback           ()
EXTERNAL FUNCTION  XxxXitExit               (status)
EXTERNAL FUNCTION  XxxXitGetUserProgramName (@file$)
'
' compiler functions
'
EXTERNAL FUNCTION  XxxGetImplementation  (name$)   'xlib.s
EXTERNAL CFUNCTION xb_geterrno		       ()
EXTERNAL CFUNCTION xb_seterrno		       (value)
EXTERNAL CFUNCTION xb_lstat              (addrFile, addrUstat)      'in xbiface.c and clib.dec
EXTERNAL CFUNCTION xb_readdir            (idir, addrDirent)
EXTERNAL CFUNCTION xb_getpfn             (addrFile, size)
EXTERNAL CFUNCTION xb_gethomepath        (addrPath, size)
EXTERNAL ##TRACEOFF
'
EXPORT
'
'
' ****************************************
' *****  Standard Library Constants  *****
' ****************************************
'
' Line Separator argument in XstStringArraySectionToString()
'
	$$NOTERM              =  0        ' no line terminator
	$$LF                  =  1        ' \n
	$$NL                  =  1        ' \n
	$$CRLF                =  2        ' \r\n
'
' for XstGetNewline() and XstSetNewline()
'
	$$NewlineLF           =  1
	$$NewlineNL           =  1
	$$NewlineCRLF         =  2
	$$NewlineDefault      =  1
	$$Newline$            = "\n"
'
' path slash characters (different for DOS/Windows vs UNIX)
'
' $$PathSlash$          = "\\"          ' Windows
' $$PathSlash           = '\\'          ' Windows
	$$PathSlash$          = "/"           ' UNIX
	$$PathSlash           = '/'           ' UNIX
'
' Drive types returned by XstGetDrives (@count, @drive$[], @driveType[], @driveType$[])
'
	$$DriveTypeUnknown    =  0            ' "Unknown"
	$$DriveTypeDamaged    =  1            ' "Damaged"
	$$DriveTypeRemovable  =  2            ' "Removable"
	$$DriveTypeFixed      =  3            ' "Fixed"
	$$DriveTypeRemote     =  4            ' "Remote"
	$$DriveTypeCDROM      =  5            ' "CDROM"
	$$DriveTypeRamDisk    =  6            ' "RamDisk"
'
'  File Attributes returned by XstGetFileAttributes (file$, @attributes)
'
	$$FileNonexistent      = 0x0000
	$$FileNotFound         = 0x0000
	$$FileReadOnly         = 0x0001
	$$FileHidden           = 0x0002
	$$FileSystem           = 0x0004
	$$FileDirectory        = 0x0010
	$$FileArchive          = 0x0020        ' Only used in Microsoft
	$$FileLink             = 0x0040
	$$FileNormal           = 0x0080        ' no other bits should be set
	$$FileTemporary        = 0x0100
	$$FileAtomicWrite      = 0x0200
	$$FileExecutable       = 0x1000
	$$FileNormalOrReadOnly = 0x0081        ' $$FileNormal OR $$FileReadOnly
'
' mode in XstFindArray()
'
	$$FindForward         = 0x00
	$$FindReverse         = 0x01
	$$FindDirection       = 0x01
	$$FindCaseSensitive   = 0x00
	$$FindCaseInsensitive = 0x02
	$$FindCaseSensitivity = 0x02
	$$FindWordSensitive   = 0x04     ' match whole word
	$$FindWordInsensitive = 0x00     ' match any part of word
	$$FindWordSensitivity = 0x04
'
' ****************************
' *****  Sort Constants  *****  OR these flags together
' ****************************
'
	$$SortIncreasing      = 0x00      ' "a to z"
	$$SortDecreasing      = 0x01      ' "z to a"
	$$SortCaseSensitive   = 0x00      ' "A" < "a"
	$$SortCaseInsensitive = 0x02      ' "A" = "a"
	$$SortAlphabetic      = 0x00      ' "a3b" > "a11c"
	$$SortAlphaNumeric    = 0x04      ' "a3b" < "a11c"
'
' for XstCompareStrings()
'
	$$EQ                  = 0x02
	$$NE                  = 0x03
	$$LT                  = 0x04
	$$LE                  = 0x05
	$$GE                  = 0x06
	$$GT                  = 0x07
'
'
' ********************************
' *****  File I/O Constants  *****  (see OPEN() intrinsic)
' ********************************
'
	$$RD                  = 0x0000    '
	$$WR                  = 0x0001    '
	$$RW                  = 0x0002    '
	$$WRNEW               = 0x0003    '
	$$RWNEW               = 0x0004    '
	$$NOSHARE             = 0x0000    ' share file for none
	$$RDSHARE             = 0x0010    ' share file for read
	$$WRSHARE             = 0x0020    ' share file for write
	$$RWSHARE             = 0x0030    ' share file for read & write
	$$NONBLOCK            = 0x0800    ' open file in non-blocking mode (FIFO TTY)
	$$ALL                 = -1        ' CLOSE ($$ALL)
'
'
' ********************************
' *****  Language Constants  *****  I/O, Kinds, DataTypes, Scope, etc...
' ********************************
'
	$$ZERO                =  0
	$$ONE                 =  1
	$$ENDIAN              =  0
	$$STDIN               =  0
	$$STDOUT              =  1
	$$STDERR              =  2
	$$VOID                =  1
	$$SBYTE               =  2
	$$UBYTE               =  3
	$$SSHORT              =  4
	$$USHORT              =  5
	$$SLONG               =  6
	$$ULONG               =  7
	$$XLONG               =  8
	$$GOADDR              =  9
	$$SUBADDR             = 10
	$$FUNCADDR            = 11
	$$GIANT               = 12
	$$SINGLE              = 13
	$$DOUBLE              = 14
	$$ARRAY               = 16
	$$ANY                 = 16
	$$ETC                 = 17
	$$VARARG              = 18
	$$STRING              = 19
	$$COMPOSITE           = 31
	$$SCOMPLEX            = 32
	$$DCOMPLEX            = 33
	$$AUTO                =  0
	$$AUTOX               =  1
	$$STATIC              =  2
	$$SHARED              =  3
	$$EXTERNAL            =  4
	$$ARGUMENT            =  7
'
'
' ************************************
' *****  SaveLoadArry Constants  *****
' ************************************
'
	$$SaveLoadArrayData		= 1
	$$SaveLoadArrayNode		= 2
	$$SaveLoadArraySkip		= 3
	$$SaveLoadArrayEOF		= 4
'
'
' **************************************
' *****  XstCompareArry Constants  *****
' **************************************
'
	$$CompareArrayEqual				= 0
	$$CompareArrayNotEqual  	= -1
	$$CompareArrayNotSameSize	= -2
	$$CompareArrayNotSameType	= -3
	$$CompareArrayNotSameNode	=	-4
'
'
' **********************************
' *****  Native Error Numbers  *****
' **********************************
'
' "Native Error Numbers" are USHORT values composed of two parts:
'    1. ErrorObject in upper byte - object associated with error
'    2. ErrorNature in lower byte - nature of action or error
'
	$$ErrorObjectNone                =  0    ' or unknown
	$$ErrorObjectData                =  1
	$$ErrorObjectDisk                =  2
	$$ErrorObjectFile                =  3
	$$ErrorObjectFont                =  4
	$$ErrorObjectGrid                =  5
	$$ErrorObjectIcon                =  6
	$$ErrorObjectName                =  7
	$$ErrorObjectNode                =  8
	$$ErrorObjectPipe                =  9
	$$ErrorObjectUser                = 10
	$$ErrorObjectArray               = 11
	$$ErrorObjectImage               = 12
	$$ErrorObjectMedia               = 13
	$$ErrorObjectQueue               = 14
	$$ErrorObjectStack               = 15
	$$ErrorObjectTimer               = 16
	$$ErrorObjectBuffer              = 17
	$$ErrorObjectCursor              = 18
	$$ErrorObjectDevice              = 19
	$$ErrorObjectDriver              = 20
	$$ErrorObjectMemory              = 21
	$$ErrorObjectSocket              = 22
	$$ErrorObjectString              = 23
	$$ErrorObjectSystem              = 24
	$$ErrorObjectThread              = 25
	$$ErrorObjectWindow              = 26
	$$ErrorObjectCommand             = 27
	$$ErrorObjectDisplay             = 28
	$$ErrorObjectLibrary             = 29
	$$ErrorObjectMessage             = 30
	$$ErrorObjectNetwork             = 31
	$$ErrorObjectPrinter             = 32
	$$ErrorObjectProcess             = 33
	$$ErrorObjectProgram             = 34
	$$ErrorObjectArgument            = 35
	$$ErrorObjectComputer            = 36
	$$ErrorObjectFunction            = 37
	$$ErrorObjectIdentity            = 38
	$$ErrorObjectPassword            = 39
	$$ErrorObjectClipboard           = 40
	$$ErrorObjectDirectory           = 41
	$$ErrorObjectSemaphore           = 42
	$$ErrorObjectStatement           = 43
	$$ErrorObjectSystemRoutine       = 44
	$$ErrorObjectSystemFunction      = 45
	$$ErrorObjectSystemResource      = 46
	$$ErrorObjectOperatingSystem     = 47
	$$ErrorObjectIntegerLogicUnit    = 48
	$$ErrorObjectFloatingPointUnit   = 49
	$$ErrorObjectSymbolicLink        = 50
'
	$$ErrorNatureNone                =  0
	$$ErrorNatureBusy                =  1
	$$ErrorNatureFull                =  2
	$$ErrorNatureError               =  3
	$$ErrorNatureEmpty               =  4
	$$ErrorNatureReset               =  5
	$$ErrorNatureExists              =  6
	$$ErrorNatureFailed              =  7
	$$ErrorNatureHalted              =  8
	$$ErrorNatureExpired             =  9
	$$ErrorNatureInvalid             = 10
	$$ErrorNatureMissing             = 11
	$$ErrorNatureTimeout             = 12
	$$ErrorNatureTooMany             = 13
	$$ErrorNatureUnknown             = 14
	$$ErrorNatureBreakKey            = 15
	$$ErrorNatureDeadlock            = 16
	$$ErrorNatureDisabled            = 17
	$$ErrorNatureNotEmpty            = 18
	$$ErrorNatureObsolete            = 19
	$$ErrorNatureOverflow            = 20
	$$ErrorNatureTooLarge            = 21
	$$ErrorNatureTooSmall            = 22
	$$ErrorNatureAbandoned           = 23
	$$ErrorNatureAvailable           = 24
	$$ErrorNatureDuplicate           = 25
	$$ErrorNatureExhausted           = 26
	$$ErrorNaturePrivilege           = 27
	$$ErrorNatureUndefined           = 28
	$$ErrorNatureUnderflow           = 29
	$$ErrorNatureAllocation          = 30
	$$ErrorNatureBreakpoint          = 31
	$$ErrorNatureContention          = 32
	$$ErrorNaturePermission          = 33
	$$ErrorNatureTerminated          = 34
	$$ErrorNatureUndeclared          = 35
	$$ErrorNatureUnexpected          = 36
	$$ErrorNatureWouldBlock          = 37
	$$ErrorNatureInterrupted         = 38
	$$ErrorNatureMalfunction         = 39
	$$ErrorNatureNonexistent         = 40
	$$ErrorNatureUnavailable         = 41
	$$ErrorNatureUnspecified         = 42
	$$ErrorNatureDisconnected        = 43
	$$ErrorNatureDivideByZero        = 44
	$$ErrorNatureIncompatible        = 45
	$$ErrorNatureNotConnected        = 46
	$$ErrorNatureLimitExceeded       = 47
	$$ErrorNatureNotInitialized      = 48
	$$ErrorNatureHigherDimension     = 49
	$$ErrorNatureLowestDimension     = 50
	$$ErrorNatureCannotInitialize    = 51
	$$ErrorNatureInitializeFailed    = 52
	$$ErrorNatureAlreadyInitialized  = 53
	$$ErrorNatureInvalidAccess       = 54
	$$ErrorNatureInvalidAddress      = 55
	$$ErrorNatureInvalidAlignment    = 56
	$$ErrorNatureInvalidArgument     = 57
	$$ErrorNatureInvalidCheck        = 58
	$$ErrorNatureInvalidCoordinates  = 59
	$$ErrorNatureInvalidCommand      = 60
	$$ErrorNatureInvalidData         = 61
	$$ErrorNatureInvalidDimension    = 62
	$$ErrorNatureInvalidEntry        = 63
	$$ErrorNatureInvalidFormat       = 64
	$$ErrorNatureInvalidKind         = 65
	$$ErrorNatureInvalidIdentity     = 66
	$$ErrorNatureInvalidInstruction  = 67
	$$ErrorNatureInvalidLocation     = 68
	$$ErrorNatureInvalidMessage      = 69
	$$ErrorNatureInvalidName         = 70
	$$ErrorNatureInvalidNode         = 71
	$$ErrorNatureInvalidNumber       = 72
	$$ErrorNatureInvalidOperand      = 73
	$$ErrorNatureInvalidOperation    = 74
	$$ErrorNatureInvalidReply        = 75
	$$ErrorNatureInvalidRequest      = 76
	$$ErrorNatureInvalidResult       = 77
	$$ErrorNatureInvalidSelection    = 78
	$$ErrorNatureInvalidSignature    = 79
	$$ErrorNatureInvalidSize         = 80
	$$ErrorNatureInvalidType         = 81
	$$ErrorNatureInvalidValue        = 82
	$$ErrorNatureInvalidVersion      = 83
	$$ErrorNatureInvalidDistribution = 84
'
' ****************************************
' *****  Native Exception Constants  *****
' ****************************************
'
	$$ExceptionNone                 =  0
	$$ExceptionSegmentViolation     =  1
	$$ExceptionOutOfBounds          =  2
	$$ExceptionBreakpoint           =  3
	$$ExceptionBreakKey             =  4
	$$ExceptionAlignment            =  5
	$$ExceptionDenormal             =  6
	$$ExceptionDivideByZero         =  7
	$$ExceptionInvalidOperation     =  8
	$$ExceptionOverflow             =  9
	$$ExceptionStackCheck           = 10
	$$ExceptionUnderflow            = 11
	$$ExceptionInvalidInstruction   = 12
	$$ExceptionPrivilege            = 13
	$$ExceptionStackOverflow        = 14
	$$ExceptionReserved             = 15
	$$ExceptionTimer                = 16
	$$ExceptionUnknown              = 17
	$$ExceptionUpper                = 31
'
	$$ExceptionTerminate            =  0    ' native
	$$ExceptionContinue             = -1    ' native
'
' to log or print debug information OR these bits into ##DEBUG
'
	$$DebugNone                     = 0x00000000
	$$DebugToConsole                = 0x00000001
	$$DebugToWindow                 = 0x00000002
	$$DebugToFile                   = 0x00000004
	$$DebugTimer                    = 0x00000008
	$$DebugSignal                   = 0x00000010
	$$DebugXstSleep                 = 0x00000020
	$$DebugDispatchEvents           = 0x00000040
	$$DebugXgrProcessMessages       = 0x00000080
'
' timer command argument to XxxXstTimer()
'
	$$TimerStart                    = 1
	$$TimerExpire                   = 2
	$$TimerKill                     = 3
'
' XstStartTask() maximum task number
'
	$$maxTask = 15
'
END EXPORT
'
'
' ####################
' #####  Xst ()  #####
' ####################
'
' Xst ()
'
' The Xst function initializes the standard library.
'
FUNCTION  Xst ()
	STATIC  entry
'
' include sockets functions
'
	a = &accept()
	a = &bind()
	a = &close()
	a = &connect()
	a = &getpeername()
	a = &getsockname()
	a = &getsockopt()
	a = &htonl()
	a = &htons()
	a = &inet_addr()
	a = &inet_ntoa()
	a = &ioctl()
	a = &listen()
	a = &ntohl()
	a = &ntohs()
	a = &recv()
	a = &recvfrom()
	a = &send()
	a = &sendto()
	a = &setsockopt()
	a = &shutdown()
	a = &socket()
'
	a = &gethostbyaddr()
	a = &gethostbyname()
	a = &gethostname()
	a = &getservbyname()
	a = &getservbyport()
	a = &getprotobyname()
	a = &getprotobynumber()
'
' include miscellaneous functions
'
	a = &time()
	a = &ftime()
	a = &gmtime()
	a = &mktime()
	a = &localtime()
	a = &gettimeofday()
'
	XxxGetImplementation (@name$)
	name$ = LCASE$ (name$)
'
	IF INSTR (name$, "linux") THEN
		#O_ACCMODE  = $$LIN_O_ACCMODE
		#O_RDONLY   = $$LIN_O_RDONLY
		#O_WRONLY   = $$LIN_O_WRONLY
		#O_RDWR     = $$LIN_O_RDWR
		#O_CREAT    = $$LIN_O_CREAT
		#O_EXCL     = $$LIN_O_EXCL
		#O_NOCTTY   = $$LIN_O_NOCTTY
		#O_TRUNC    = $$LIN_O_TRUNC
		#O_APPEND   = $$LIN_O_APPEND
		#O_NONBLOCK = $$LIN_O_NONBLOCK
		#O_NDELAY   = $$LIN_O_NDELAY
		#O_SYNC     = $$LIN_O_SYNC
	ELSE
		#O_ACCMODE  = $$SCO_O_ACCMODE
		#O_RDONLY   = $$SCO_O_RDONLY
		#O_WRONLY   = $$SCO_O_WRONLY
		#O_RDWR     = $$SCO_O_RDWR
		#O_CREAT    = $$SCO_O_CREAT
		#O_EXCL     = $$SCO_O_EXCL
		#O_NOCTTY   = $$SCO_O_NOCTTY
		#O_TRUNC    = $$SCO_O_TRUNC
		#O_APPEND   = $$SCO_O_APPEND
		#O_NONBLOCK = $$SCO_O_NONBLOCK
		#O_NDELAY   = $$SCO_O_NDELAY
		#O_SYNC     = $$SCO_O_SYNC
	END IF
'
	IF entry THEN RETURN
	entry = $$TRUE
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "Linux XBasic standard function library"
	a$ = "maxreason@maxreason.com"
	a$ = ""
'
' initialize key variables and arrays
'
	InitProgram ()
'
'	XstLog ("Xio().A")
' Xio removed becuase the GUI shouldn't be initialized yet!
'	Xio ()
'	XstLog ("Xio().Z")
'	XstGetFiles (@xbdir$, @file$[])
'	XstLog ("Xst().Z")
	XstGetEnvironmentVariable ("XBDIR", @xbdir$)
	IFZ xbdir$ THEN
		XstSetEnvironmentVariable ("XBDIR", "/usr/xb64")
	END IF
'	XstGetEnvironmentVariable ("XBDIR", @xbdir$)
'	PRINT "Xst(110):XBDIR =", xbdir$
END FUNCTION
'
'
' ############################
' #####  XstVersion$ ()  #####
' ############################
'
' version$ = XstVersion$ ()
'
' Return a string containing the standard function library version
'
FUNCTION  XstVersion$ ()
'
	version$ = VERSION$ (0)
	RETURN (version$)
END FUNCTION
'
'
' ##################################
' #####  XstCauseException ()  #####
' ##################################
'
' XstCauseException (exception)
'
' Cause the specified exception.  exception is the native
' exception number, not the system exception number.
'
' See: XstGetException(), XstGetExceptionFunction()
'
FUNCTION  XstCauseException (exception)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300001
	pid = getpid ()
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	XstExceptionToSystemException (exception, @sysException)
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300002
	kill (pid, sysException)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ################################
' #####  XstCloseLibrary ()  #####
' ################################
'
' error = XstCloseLibrary (handle)
'
' See:  XstOpenLibrary()
'
FUNCTION  XstCloseLibrary (handle)
	return = FreeLibrary (handle)
	RETURN (return)
END FUNCTION
'
'
' #########################################
' #####  XstDateAndTimeToFileTime ()  #####
' #########################################
'
' XstDateAndTimeToFileTime (year, month, day, weekDay, hour, minute, second, nanos, @filetime$$)
'
' See: XstFileTimeToDateAndTime()
'
FUNCTION  XstDateAndTimeToFileTime (year, month, day, weekDay, hour, minute, second, nanos, @filetime$$)
	UTM  tm
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstDateAndTimeToFileTime()lockout", lockout)
'
	tm.tm_year = year - 1900
	tm.tm_mon = month - 1
	tm.tm_mday = day
	tm.tm_hour = hour
	tm.tm_min = minute
	tm.tm_sec = second
'
	##WHOMASK = 0
	##LOCKOUT = 300003
	time = mktime (&tm)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	DeltaTimeZone (@delta)													' GMT vs local time
'
	filetime$$ = time + delta												' time relative to 1970 Jan 1 at 00:00:00
	filetime$$ = filetime$$ * 10000000$$						' convert to 100ns units
	filetime$$ = filetime$$ + (nanos \ 100$$)				' add nanoseconds converted to 100ns units
	filetime$$ = filetime$$ + 116444736000000000$$	' time relative to 1601 Jan 1 at 00:00:00.000
	filetime$$ = filetime$$ + delta$$								' corre
END FUNCTION
'
'
' #####################################
' #####  XstErrorNameToNumber ()  #####
' #####################################
'
' error = XstErrorNameToNumber (error$, @error)
'
' Convert the one or two part error name in error$ into an error number.
' See xst.dec for $$ErrorObject and $$ErrorNature constants.
'
' See: ERROR()
'      ERROR$()
'      XstErrorNumberToName()
'      XstSystemErrorNumberToName()
'      XstSystemErrorToError()
'
FUNCTION  XstErrorNameToNumber (err$, error)
	SHARED	errorObject$[]
	SHARED	errorNature$[]
'
	error = 0
	error$ = TRIM$ (err$)
	return = $$TRUE															' error name not found
'
	DO WHILE error$
		space = INCHR (error$, " \t")
		IFZ space THEN
			e$ = error$
		ELSE
			e$ = TRIM$(LEFT$(error$, space))
			error$ = TRIM$(MID$(error$, space+1))
		END IF
		upper = UBOUND (errorObject$[])
		FOR i = 1 TO upper
			IF (e$ = errorObject$[i]) THEN
				error = error OR (i << 8)							' error object name found
				return = $$FALSE
				EXIT FOR															' only one error object
			END IF
		NEXT i
		upper = UBOUND (errorNature$[])
		FOR i = 1 TO upper
			IF (e$ = errorNature$[i]) THEN
				error = error OR i										' error nature name found
				return = $$FALSE
				EXIT FOR															' only one error nature
			END IF
		NEXT i
	LOOP
END FUNCTION
'
'
' #####################################
' #####  XstErrorNumberToName ()  #####
' #####################################
'
' XstErrorNumberToName (error, @error$)
'
' Convert the one or two part error number into an error$ name.
'
'
' See: ERROR()
'      ERROR$()
'      XstErrorNameToNumber()
'      XstSystemErrorNumberToName()
'      XstSystemErrorToError()
'
FUNCTION  XstErrorNumberToName (error, error$)
	SHARED	errorObject$[]
	SHARED	errorNature$[]
'
	nature = error AND 0x00FF
	object = (error >> 8) AND 0x00FF
	upperObject = UBOUND (errorObject$[])
	upperNature = UBOUND (errorNature$[])
'
	error$ = ""
	SELECT CASE TRUE
		CASE (object < 0) 					: error$ = "Unknown Negative Object Number"
		CASE (nature < 0)						: error$ = "Unknown Negative Nature Number"
		CASE (object > upperObject)	: error$ = "$$ErrorObject too large"
		CASE (nature > upperNature)	: error$ = "$$ErrorNature too large"
	END SELECT
'
	IF error$ THEN RETURN
	object$ = errorObject$[object]
	nature$ = errorNature$[nature]
	IFZ (object OR nature) THEN error$ = "NoError" : RETURN
'
	IF object$ THEN
		IF nature$ THEN
			error$ = object$ + " " + nature$
		ELSE
			error$ = object$
		END IF
	ELSE
		IF nature THEN
			error$ = nature$
		ELSE
			error$ = "UnknownError"
		END IF
	END IF
END FUNCTION
'
'
' #########################################
' #####  XstExceptionNumberToName ()  #####
' #########################################
'
' error = XstExceptionNumberToName (exception, @exception$)
'
' Convert a native exception number into a native exception$ name.
'
' See: XstExceptionToSystemException()
'      XstSystemExceptionNumberToName()
'      XstSystemExceptionToException()
'      XstSetException()
'      XstSetExceptionFunction()
'
FUNCTION  XstExceptionNumberToName (exception, exception$)
	SHARED	exception$[]
'
	exception$ = ""
	upper = UBOUND (exception$[])
	IF (exception < 0) THEN RETURN ($$TRUE)
	IF (exception > upper) THEN RETURN ($$TRUE)
	exception$ = exception$[exception]
END FUNCTION
'
'
' ##############################################
' #####  XstExceptionToSystemException ()  #####
' ##############################################
'
' XstExceptionToSystemException (exception, @sysException)
'
' Convert a native exception number to its system exception number
'
'
' See: XstExceptionNumberToName()
'      XstSystemExceptionNumberToName()
'      XstSystemExceptionToException()
'      XstSetException()
'      XstSetExceptionFunction()
'
FUNCTION  XstExceptionToSystemException (exception, sysException)
'
	SELECT CASE exception
		CASE $$ExceptionSegmentViolation					: sysException = $$SIGSEGV
		CASE $$ExceptionOutOfBounds								: sysException = $$SIGBUS
		CASE $$ExceptionBreakpoint								: sysException = $$SIGTRAP
		CASE $$ExceptionBreakKey									: sysException = $$SIGINT
		CASE $$ExceptionAlignment									: sysException = $$SIGBUS
		CASE $$ExceptionDenormal									: sysException = $$SIGFPE
		CASE $$ExceptionDivideByZero							: sysException = $$SIGFPE
		CASE $$ExceptionInvalidOperation					: sysException = $$SIGFPE
		CASE $$ExceptionOverflow									: sysException = $$SIGFPE
		CASE $$ExceptionStackCheck								: sysException = $$SIGSEGV
		CASE $$ExceptionUnderflow									: sysException = $$SIGFPE
		CASE $$ExceptionInvalidInstruction				: sysException = $$SIGILL
		CASE $$ExceptionDivideByZero							: sysException = $$SIGFPE
		CASE $$ExceptionOverflow									: sysException = $$SIGFPE
		CASE $$ExceptionPrivilege									: sysException = $$SIGSEGV
		CASE $$ExceptionStackOverflow							: sysException = $$SIGSEGV
		CASE ELSE																	: sysException = $$SIGSEGV
	END SELECT
END FUNCTION
'
'
' #########################################
' #####  XstFileTimeToDateAndTime ()  #####
' #########################################
'
' XstFileTimeToDateAndTime (filetime$$, @year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
'
' See: XstDateAndTimeToFileTime()
'
FUNCTION  XstFileTimeToDateAndTime (filetime$$, year, month, day, weekDay, hour, minute, second, nanos)
	UTM  time
	AUTOX  secs
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstFileTimeToDateAndTime()lockout", lockout)
'
	year = 0
	month = 0
	day = 0
	weekDay = 0
	hour = 0
	minute = 0
	second = 0
	nanos = 0
'
	time$$ = filetime$$ - 116444736000000000$$		' from 1601 relative to 1970 relative
	IF (time$$ < 0) THEN time$$ = filetime$$			' filetime$$ must have been 1970 relative
	secs$$ = time$$ \ 10000000$$									' seconds since 1970 Jan 1 at 00:00:00.0000000
	temp$$ = secs$$ * 10000000$$									'
	frac$$ = time$$ - temp$$											' fractions of seconds in 100ns units
	secs = secs$$																	' seconds since 1970 Jan 1 at 00:00:00.000
'
	##WHOMASK = 0
	##LOCKOUT = 300004
	time = gmtime (&secs)													' convert seconds to year/month/day/hour/min/sec
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	year = time.tm_year + 1900
	month = time.tm_mon + 1
	day = time.tm_mday
	weekDay = time.tm_wday
	hour = time.tm_hour
	minute = time.tm_min
	second = time.tm_sec
	nanos = frac$$ * 100$$												' nanoseconds remainder
END FUNCTION
'
'
' ##############################################
' #####  XstFileTimeToLocalDateAndTime ()  #####
' ##############################################
'
' XstFileTimeToLocalDateAndTime (filetime$$, @year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
'
' See: XstDateAndTimeToFileTime()
'
FUNCTION  XstFileTimeToLocalDateAndTime (filetime$$, year, month, day, weekDay, hour, minute, second, nanos)
	UTM  time
	AUTOX  secs
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstFileTimeToLocalDateAndTime()lockout", lockout)
'
	year = 0
	month = 0
	day = 0
	weekDay = 0
	hour = 0
	minute = 0
	second = 0
	nanos = 0
'
	time$$ = filetime$$ - 116444736000000000$$		' from 1601 relative to 1970 relative
	IF (time$$ < 0) THEN time$$ = filetime$$			' filetime$$ must have been 1970 relative
	secs$$ = time$$ \ 10000000$$									' seconds since 1970 Jan 1 at 00:00:00.0000000
	temp$$ = secs$$ * 10000000$$									'
	frac$$ = time$$ - temp$$											' fractions of seconds in 100ns units
	secs = secs$$																	' seconds since 1970 Jan 1 at 00:00:00.000
'
	##WHOMASK = 0
	##LOCKOUT = 300005
	time = localtime (&secs)											' convert seconds to year/month/day/hour/min/sec
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	year = time.tm_year + 1900
	month = time.tm_mon + 1
	day = time.tm_mday
	weekDay = time.tm_wday
	hour = time.tm_hour
	minute = time.tm_min
	second = time.tm_sec
	nanos = frac$$ * 100$$												' nanoseconds remainder
END FUNCTION
'
'
' ####################################
' #####  XstFileToSystemFile ()  #####
' ####################################
'
' XstFileToSystemFile (fileNumber, @systemFilenumber)
'
' Convert a native fileNumber returned by OPEN() into the systemFilenumber
' - the file number or handle the operating system uses to refer to the file.
' This makes it possible to call operating system functions directly to get
' information about the file.
'
FUNCTION  XstFileToSystemFile (fileNumber, systemFileNumber)
	SHARED  FILE  fileInfo[]
'
	systemFileNumber = 0
	IF fileInfo[] THEN
		upper = UBOUND (fileInfo[])
		IF (fileNumber <= upper) THEN
			fileHandle = fileInfo[fileNumber].fileHandle
			IF fileHandle THEN systemFileNumber = fileHandle
		END IF
	END IF
END FUNCTION
'
'
' #############################################
' #####  XstGetApplicationEnvironment ()  #####
' #############################################
'
' XstGetApplicationEnvironment (@standalone, @reserved)
'
' Return a standalone variable to tell whether the program
' is currently running as a standalone executable as opposed
' to in the program developement environment.
'
FUNCTION  XstGetApplicationEnvironment (@standalone, @reserved)
'
	standalone = ##STANDALONE
	reserved = $$FALSE
END FUNCTION
'
'
' ##################################
' #####  XstGetCommandLine ()  #####
' ##################################
'
' XstGetCommandLine (@line$)
'
' See: XstGetCommandLineArguments(), XstSetCommandLineArguments()
'
FUNCTION  XstGetCommandLine (@line$)
'
	line$ = ""
	XstGetCommandLineArguments (@argc, @argv$[])
'
	IF (argc <= 0) THEN RETURN
	FOR i = 0 TO argc-1
		line$ = line$ + argv$[i] + " "
	NEXT i
	line$ = TRIM$(line$)
END FUNCTION
'
'
' ###########################################
' #####  XstGetCommandLineArguments ()  #####
' ###########################################
'
' XstGetCommandLineArguments (@argCount, @argv$[])
'
' Return the number of command line arguments in argCount,
' and the command line argument strings in argv$[].
' argCount should never be 0 or less, since the name
' of the program is the first argument, unless
' XstSetCommandLineArguments() has changed them.
'
' Call XstGetCommandLineArguments() with (argCount < 0)
' to get the original argCount and argv$[] in the event
' they have been changed by XstSetCommandLineArguments().
'
' See: XstGetCommandLine(), XstSetCommandLineArguments()
'
FUNCTION  XstGetCommandLineArguments (argc, argv$[])
	SHARED  setargv$[]
	SHARED  setargc
	SHARED  setarg
	STATIC  entry
'
	whomask = ##WHOMASK
'
	IFZ entry THEN GOSUB Initialize
	entry = $$TRUE
	DIM argv$[]
	inc = argc
	argc = 0
'
	IF (inc < 0) THEN												' return original command line arguments
		upper = UBOUND (##ARGV$[])
		argc = upper + 1
		IF argc THEN
			DIM argv$[upper]
			FOR i = 0 TO upper
				argv$[i] = ##ARGV$[i]
			NEXT i
		END IF
	ELSE
		argc = setargc
		upper = UBOUND (setargv$[])
		ucount = upper + 1
		IF (argc > ucount) THEN argc = ucount
		IF argc THEN
			DIM argv$[upper]
			FOR i = 0 TO upper
				argv$[i] = setargv$[i]
			NEXT i
		END IF
	END IF
	RETURN ($$FALSE)
'
'
' *****  Initialize  *****
'
SUB Initialize
	DIM setargv$[]
	setarg = $$TRUE
	setargc = ##ARGC
	upper = UBOUND (##ARGV$[])
	ucount = upper + 1
	IF (setargc > ucount) THEN setargc = ucount
	IF (setargc <= 0) THEN EXIT SUB
'
'	upper$ = STRING$(upper) + " : " + STRING$(setargc) + "\n"
'	write (1, &upper$, LEN(upper$))
'
	##WHOMASK = 0
	DIM setargv$[upper]
	FOR i = 0 TO upper
		setargv$[i] = ##ARGV$[i]
	NEXT i
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ##################################
' #####  XstGetConsoleGrid ()  #####
' ##################################
'
' XstGetConsoleGrid (@grid)
'
' Return the grid number of the console grid. A grid value
' of zero will be returned if there is no console window.
' GuiPrograms usually do not input or display information
' with the console window, so XBasic does not create a console
' for a standalone program. To have a console in a standalone,
' requires XstDisplayConsole() or use XstCreateConsole() to
' create a console at a specific location and size followed by
' XstDisplayConsole() to make it visible.
'
' XstCreateConsole() help information lists commands
' for setting the Console font, color and style.
'
' See: XstClearConsole(), XstCreateConsole(), XstDisplayConsole(),
'      XstHideConsole, XstShowConsole()
'
FUNCTION  XstGetConsoleGrid (grid)
	grid = ##CONGRID
END FUNCTION
'
'
' ##############################
' #####  XstGetCPUName ()  #####
' ##############################
'
' XstGetCPUName (@name$)
'
' Return the generic name of the central processor unit in name$.
'
FUNCTION  XstGetCPUName (name$)
	name$ = "80386"
END FUNCTION
'
'
' ##################################
' #####  XstGetDateAndTime ()  #####
' ##################################
'
' XstGetDateAndTime (@year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
'
' Get the UTC/GMT date and time. This date and time is equal in all
' timezones.
'
' @year			The year (0000 .. 9999)
' @month		The month (1 .. 12)
' @day			The day of the month (1 .. 31)
' @weekDay	The day of the week (sunday=0 .. saturday=6)
' @hour			The hour (00 .. 23)
' @minute		The minute (00 .. 59)
' @second		The second (00 .. 59)
' @nanos		The nanoseconds (0 .. 999999999)
'
' See: XstGetLocalDateAndTime(), XstSetDateAndTime()
'
FUNCTION  XstGetDateAndTime (year, month, day, weekDay, hour, minute, second, nanos)
	UTIMEZONE  tz
	UTIMEVAL  tv
	UTM  time
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstGetDateAndTime()lockout", lockout)
	##WHOMASK = 0
	##LOCKOUT = 300006
	gettimeofday (&tv, &tz)
	time = gmtime (&tv.tv_sec)
	##WHOMASK = whomask
	##LOCKOUT = lockout
'
	year		= time.tm_year + 1900
	month		= time.tm_mon + 1
	day			= time.tm_mday
	weekDay	= time.tm_wday
	hour		= time.tm_hour
	minute	= time.tm_min
	second	= time.tm_sec
	nanos		= tv.tv_usec * 1000
END FUNCTION
'
'
' #######################################
' #####  XstGetLocalDateAndTime ()  #####
' #######################################
'
' XstGetLocalDateAndTime (@year, @month, @day, @weekDay, @hour, @minute, @second, @nanos)
'
' This retrieves the date and time in the local timezone.
'
' @year			The year (0000 .. 9999)
' @month		The month (1 .. 12)
' @day			The day of the month (1 .. 31)
' @weekDay	The day of the week (sunday=0 .. saturday=6)
' @hour			The hour (00 .. 23)
' @minute		The minute (00 .. 59)
' @second		The second (00 .. 59)
' @nanos		The nanoseconds (0 .. 999999999)
'
' See: XstGetDateAndTime, XstSetDateAndTime()
'
FUNCTION  XstGetLocalDateAndTime (year, month, day, weekDay, hour, minute, second, nanos)
	UTIMEZONE  tz
	UTIMEVAL  tv
	UTM  time
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstGetLocalDateAndTime()lockout", lockout)
	##WHOMASK = 0
	##LOCKOUT = 300007
	gettimeofday (&tv, &tz)
	time = localtime (&tv.tv_sec)
	##WHOMASK = whomask
	##LOCKOUT = lockout
'
	year		= time.tm_year + 1900
	month		= time.tm_mon + 1
	day			= time.tm_mday
	weekDay	= time.tm_wday
	hour		= time.tm_hour
	minute	= time.tm_min
	second	= time.tm_sec
	nanos		= tv.tv_usec * 1000
END FUNCTION
'
'
' #############################
' #####  XstGetEndian ()  #####
' #############################
'
' XstGetEndian (@endian$$)
'
' Return a 64-bit endian descriptor that contains the following 8 bytes:
' 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07 in the lowest to
' highest addresses of endian$$.  The value of endian$$ is therefore
' 0x0706050403020100 on little endian systems, and 0x0001020304050607
' on pure big endian systems.
'
' See: XstGetEndianName()
'
FUNCTION  XstGetEndian (endian$$)
	AUTOX		temp$$
'
	addr = &temp$$
	UBYTEAT (addr,0) = 0x00
	UBYTEAT (addr,1) = 0x01
	UBYTEAT (addr,2) = 0x02
	UBYTEAT (addr,3) = 0x03
	UBYTEAT (addr,4) = 0x04
	UBYTEAT (addr,5) = 0x05
	UBYTEAT (addr,6) = 0x06
	UBYTEAT (addr,7) = 0x07
	endian$$ = temp$$
END FUNCTION
'
'
' #################################
' #####  XstGetEndianName ()  #####
' #################################
'
' XstGetEndianName (@endian$)
'
' Return "LittleEndian" or "BigEndian" in endian$.
'
' See: XstGetEndian()
'
FUNCTION  XstGetEndianName (name$)
	name$ = "LittleEndian"
END FUNCTION
'
'
' ##########################################
' #####  XstGetEnvironmentVariable ()  #####
' ##########################################
'
' XstGetEnvironmentVariable (name$, @value$)
'
' Get the string value$ of the environment variable with called name$.
' For example, XstGetEnvironmentVariable ("PATH", @path$).
'
' See: XstGetEnvironmentVariables()
'      XstGetExecutionPathArray()
'      XstSetEnvironmentVariable()
'
FUNCTION  XstGetEnvironmentVariable (name$, value$)
	SHARED  envp$[]
	STATIC  entry
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ entry THEN
		IFZ envp$[] THEN XstGetEnvironmentVariables (@count, @var$[])
		entry = $$TRUE
		DIM var$[]
	END IF
'
	value$ = ""
	found = $$FALSE
	IFZ name$ THEN RETURN
	ename$ = TRIM$ (name$)
	upper = UBOUND (envp$[])
	FOR i = 0 TO upper
		envp$ = envp$[i]
		equal = INSTR (envp$, "=")
		IF equal THEN
			vname$ = TRIM$(LEFT$(envp$,equal-1))
			IF (ename$ = vname$) THEN
				value$ = MID$(envp$,equal+1)
				found = $$TRUE
				EXIT FOR
			END IF
		END IF
	NEXT i
'
	IFZ found THEN
		##WHOMASK = $$FALSE
		##LOCKOUT = 300008
		addr = getenv (&ename$)
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IF addr THEN value$ = CSTRING$ (addr)
	END IF
END FUNCTION
'
'
' ###########################################
' #####  XstGetEnvironmentVariables ()  #####
' ###########################################
'
' XstGetEnvironmentVariables (@count, @envp$[])
'
' Return the number of environment variable strings in count, and the environment
' variable strings in envp$[].  The strings contain both the name of the
' environment variable and its value, separated by an "=", as in
' PATH=/usr/local/bin:/usr/local/sbin:/sbin:/usr/sbin:/bin:/usr/bin:/usr/bin/X11
'
' See: XstGetEnvironmentVariable()
'      XstGetExecutionPathArray()
'      XstSetEnvironmentVariable()
'
FUNCTION  XstGetEnvironmentVariables (count, var$[])
	SHARED  envp,  envp$[]
	STATIC  entry
'
	IFZ entry THEN GOSUB Initialize
	entry = $$TRUE
'
	upper = UBOUND (envp$[])
	count = upper + 1
	DIM var$[upper]
'
	FOR i = 0 TO upper
		var$[i] = envp$[i]
	NEXT i
	RETURN
'
'
' *****  Initialize  *****
'
SUB Initialize
	whomask = ##WHOMASK
	DIM envp$[]
	envp = 0
'
	IFZ ##ENVP$[] THEN RETURN
	upper = UBOUND (##ENVP$[])
	IF (upper < 0) THEN RETURN
	envp = upper + 1
'
	##WHOMASK = 0
	DIM envp$[upper]
	FOR i = 0 TO upper
		envp$[i] = ##ENVP$[i]
	NEXT i
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ################################
' #####  XstGetException ()  #####
' ################################
'
' XstGetException (@exception)
'
' Return the native exception number of the most recent exception.
'
' See: XstCauseException(), XstGetExceptionFunction(), XstSetException()
'
FUNCTION  XstGetException (exception)
	exception = ##EXCEPTION
END FUNCTION
'
'
' ########################################
' #####  XstGetExceptionFunction ()  #####
' ########################################
'
' XstGetExceptionFunction (@functionAddress)
'
' Get the address of the current exception function in functionAddress.
' When an exception occurs in a standalone program, the exception
' function established by XstSetExceptionFunction() is executed.
'
' See: XstCauseException(), XstGetException(), XstSetExceptionFunction()
'
FUNCTION  XstGetExceptionFunction (function)
	SHARED	exceptionFunction
'
	function = exceptionFunction
END FUNCTION
'
'
' #####################################
' #####  XstGetImplementation ()  #####
' #####################################
'
' XstGetImplementation (@name$)
'
' The implementation is "unix elf linux"
'
' See: XstGetOSName()
'
FUNCTION  XstGetImplementation (name$)
'
	XxxGetImplementation (@name$)
'
END FUNCTION
'
'
' #####################################
' #####  XstGetLibraryAddress ()  #####
' #####################################
'
' address = XstGetLibraryAddress (handle, funcname$)
'
' See: XstOpenLibrary()
'
FUNCTION  XstGetLibraryAddress (handle, funcname$)
	addr = GetProcAddress (handle, &funcname$)
	RETURN (addr)
END FUNCTION
'
'
' ################################
' #####  XstGetMemoryMap ()  #####
' ################################
'
' MEMORYMAP memorymap
' XstGetMemoryMap (@memorymap)
'
FUNCTION  XstGetMemoryMap (MEMORYMAP memorymap)
'
	memorymap.code0 = ##CODE0
	memorymap.code = ##CODE
	memorymap.codex = ##CODEX
	memorymap.codez = ##CODEZ
	memorymap.data0 = ##DATA0
	memorymap.data = ##DATA
	memorymap.datax = ##DATAX
	memorymap.dataz = ##DATAZ
	memorymap.bss0 = ##BSS0
	memorymap.bss = ##BSS
	memorymap.bssx = ##BSSX
	memorymap.bssz = ##BSSZ
	memorymap.dyno0 = ##DYNO0
	memorymap.dyno = ##DYNO
	memorymap.dynox = ##DYNOX
	memorymap.dynoz = ##DYNOZ
	memorymap.ucode0 = ##UCODE0
	memorymap.ucode = ##UCODE
	memorymap.ucodex = ##UCODEX
	memorymap.ucodez = ##UCODEZ
	memorymap.stack0 = ##STACK0
	memorymap.stack = ##STACK
	memorymap.stackx = ##STACKX
	memorymap.stackz = ##STACKZ
END FUNCTION
'
'
' ##############################
' #####  XstGetNewline ()  #####
' ##############################
'
' XstGetNewline (@save, @paste)
'
' Retrieve the newline character values
'
' See: XstSetNewline()
'
FUNCTION  XstGetNewline (save, paste)
	SHARED	sysSaveNewline,  sysPasteNewline
	SHARED	userSaveNewline,  userPasteNewline
'
	IF ##WHOMASK THEN
		save = userSaveNewline
		paste = userPasteNewline
	ELSE
		save = sysSaveNewline
		paste = sysPasteNewline
	END IF
'
	IFZ save THEN save = $$NewlineDefault
	IFZ paste THEN paste = $$NewlineDefault
END FUNCTION
'
'
' #############################
' #####  XstGetOSName ()  #####
' #############################
'
' XstGetOSName (@name$)
'
' Return the operating system name in name$.  Examples include
' "Windows", "WindowsNT", "UNIX", "OS2", "linux unix".
'
' See: XstGetImplementation(), XstGetVersion()
'
FUNCTION  XstGetOSName (name$)
'
	SELECT CASE ##XBSystem
		CASE $$XBSysLinux:
			name$ = "linux unix"
		CASE ELSE:
			name$ = "unix"
	END SELECT
'
END FUNCTION
'
'
' ################################
' #####  XstGetOSVersion ()  #####
' ################################
'
' XstGetOSVersion (@major, @minor)
'
' Return the major and minor portions of the operating system version.
' The major and minor part are the integer and fractional portions of
' the complete version number, so version 3.10 of the Windows operating
' system, major = 0x0003 and minor = 0x000A.
'
' See: XstGetOSVersionName()
'
FUNCTION  XstGetOSVersion (major, minor)
'
	version = 0x0400
	major = version{8,8}
	minor = version{8,0}
END FUNCTION
'
'
' ####################################
' #####  XstGetOSVersionName ()  #####
' ####################################
'
' XstGetOSVersionName (@version$)
'
' Return the operating system version number string "major.minor"
'
' See: XstGetOSVersion()
'
FUNCTION  XstGetOSVersionName (name$)
'
	version = 0x0400
	majorVersion = version{8,8}
	minorVersion = version{8,0}
	name$ = STRING$ (majorVersion) + "." + STRING$ (minorVersion)
END FUNCTION
'
'
' ###############################
' #####  XstGetPrintTab ()  #####
' ###############################
'
' XstGetPrintTab (@pixels)
'
' Return the number of pixels between tab positions in the console.
'
' See: XstSetPrintTab (pixels)
'
FUNCTION  XstGetPrintTab (pixels)
'
	pixels = ##TABSAT
END FUNCTION
'
'
' ##################################
' #####  XstGetProgramName ()  #####
' ##################################
'
' XstGetProgramName (@prog$)
'
' See: XstGetProgramFileName$(), PROGRAM$()
'
FUNCTION  XstGetProgramName (@prog$)
	SHARED  userProgram$
	SHARED  sysProgram$
'
	prog$ = ""
	whomask = ##WHOMASK
'
	IF whomask THEN
		prog$ = userProgram$
	ELSE
		prog$ = sysProgram$
	END IF
END FUNCTION
'
'
' ##################################
' #####  XstGetSystemError ()  #####
' ##################################
'
' XstGetSystemError (@sysError)
'
' Return the most recent operating system sysError number.
'
' See: XstSetSystemError()
'
FUNCTION  XstGetSystemError (error)
	error = xb_geterrno()
END FUNCTION
'
'
' ##############################
' #####  XstGetSystemTime  #####
' ##############################
'
' XstGetSystemTime (@msec)
'
' Return the value of the free running time in msec.
'
FUNCTION  XstGetSystemTime (msec)
	SHARED  UTIMEB  startTime
	AUTOX  UTIMEB  nowTime
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstGetSystemTime()lockout", lockout)
'
' get zero reference time for free-running millisecond time
'
	IFZ startTime.time THEN
		##WHOMASK = 0
		##LOCKOUT = 300009
		ftime (&startTime)
		##WHOMASK = whomask
		##LOCKOUT = lockout
	END IF
'
' get current time
'
	##WHOMASK = 0
	##LOCKOUT = 300010
	ftime (&nowTime)
	##WHOMASK = whomask
	##LOCKOUT = lockout
'
' msec = system time = nowTime - startTime
'
	ssec = startTime.time						' start time - seconds
	smsec = startTime.millitm				' start time - milliseconds
'
	nsec = nowTime.time							' current time - seconds
	nmsec = nowTime.millitm					' current time - milliseconds
'
	sec = nsec - ssec								' delta = current - start (sec)
	msec = nmsec - smsec						' delta = current - start (msec)
'
	IF (sec < 0) THEN sec = 0 : msec = 0
	IF (msec < 0) THEN msec = msec + 1000 : sec = sec - 1
	IF (msec < 0) THEN msec = msec + 1000 : sec = sec - 1
	msec = (sec * 1000) + msec
END FUNCTION
'
'
' ###############################
' #####  XstGetTaskInfo ()  #####
' ###############################
'
' assigned = XstGetTaskInfo (taskNum, @count, @msec, @funcAddress, @timer, @skips)
'
' assigned --- is returned $$TRUE if taskNum is assigned, $$FALSE if unassaigned.
'
' skips --- is the number of times that the task was not run because, at the time
' of a timer interrupt to run the task again, the task was still running or has
' not started from the previous request.
'
' See: XstStartTask(), XstKillTask()
'
FUNCTION  XstGetTaskInfo (taskNum, @count, @msec, @func, @timer, @skips)
	SHARED TASK task[]
'
	count   = 0
	msec    = 0
	func    = 0
	timer   = 0
'	engaged = 0
	skips   = 0
	IF (taskNum > UBOUND(task[])) THEN RETURN ($$FALSE)
'
	func    = task[taskNum].taskFunc   ' address of function being called
	IFZ func THEN RETURN ($$FALSE)     ' zero func means unassaigned task number
'
	count   = task[taskNum].count      ' iterations remaining to call task
	msec    = task[taskNum].msec       ' millisecond interval of this task
	timer   = task[taskNum].timer      ' number of timer doing the interval timing
'	request = task[taskNum].request    ' TRUE if TimeOut message loaded in messaage queue
'	engaged = task[taskNum].engaged    ' TRUE from when task function is called until it returns
	skips   = task[taskNum].skips      ' count of times request failed
	RETURN ($$TRUE)
'
END FUNCTION
'
'
' ############################
' #####  XstKillTask ()  #####
' ############################
'
' error = XstKillTask (taskNum)
' error = XstKillTask ($$ALL)
'
' error is returned TRUE if a specified task number
'       was not assigned or failed to be stopped.
'
' error is always returned FALSE if $$ALL is specified,
'       whether any tasks were stopped or not.
'
FUNCTION  XstKillTask (taskNum)
	SHARED TASK task[]
'
	IF (taskNum == -1) THEN
		GOSUB KillAllTasks
		RETURN ($$FALSE)
	ELSE
		IF (taskNum < 1) THEN RETURN ($$TRUE)
		IF (taskNum > UBOUND(task[])) THEN RETURN ($$TRUE)
		GOSUB KillOneTask
		RETURN (rc)
	END IF
	RETURN
'
' *****  KillAllTasks  *****
'
SUB KillAllTasks
	FOR taskNum = 1 TO UBOUND(task[])
		GOSUB KillOneTask
	NEXT taskNum
END SUB
'
'
' *****  KillOneTask  *****
'
SUB KillOneTask
'
	IF ##WHOMASK THEN
		IFZ task[taskNum].whomask THEN
			rc = $$TRUE
		 EXIT SUB  ' user may only kill user assigned task
		END IF
	END IF
'
	timer = task[taskNum].timer
	tgrid = NOT taskNum
	IF timer THEN XxxXstTimer ($$TimerKill, tgrid, timer, 0, 0, 0)
	task[taskNum].taskFunc = 0
	task[taskNum].timer    = 0
	task[taskNum].msec     = 0
	task[taskNum].count    = 0
	task[taskNum].whomask  = 0
	task[taskNum].engaged  = 0
	task[taskNum].request  = 0
END SUB
'
END FUNCTION
'
'
' #############################
' #####  XstKillTimer ()  #####
' #############################
'
' error = XstKillTimer (timer)
'
' timer = timer ID returned by XstStartTimer()
'
' error = $$FALSE success
' error = $$TRUE  failure
'
FUNCTION  XstKillTimer (timer)
'
	return = XxxXstTimer ($$TimerKill, 0, timer, 0, 0, 0)
'
	RETURN (return)
END FUNCTION
'
'
' #######################
' #####  XstLog ()  #####
' #######################
'
' XstLog (text$)
'
' Writes the Process ID, date and time plus text$ to the file named "x.log"
'
FUNCTION  XstLog (text$)
	STATIC  name$
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	errorOld = ERROR(0)
	##WHOMASK = $$FALSE
'
	##LOCKOUT = 300011
	pid = getpid ()
	##LOCKOUT = lockout
'
	pid$ = " p" + RIGHT$("000"+STRING$(pid),4)
	XstGetLocalDateAndTime (@year, @month, @day, 0, @hour, @min, @sec, @nanos)
	stamp$ = RIGHT$("000" + STRING$(year),4) + RIGHT$("0" + STRING$(month),2) + RIGHT$("0" + STRING$(day),2) + ":" + RIGHT$("0" + STRING$(hour),2) + RIGHT$("0" + STRING$(min),2) + RIGHT$("0" + STRING$(sec),2) + "." + RIGHT$("000" + STRING$(nanos\1000000),3) + pid$ + " : "
'
	IFZ name$ THEN
		XstGetCurrentDirectory (@name$)
		name$ = name$ + $$PathSlash$ + "x.log"
		ofile = OPEN (name$, $$WRNEW)
	ELSE
		ofile = OPEN (name$, $$WR)
	END IF
'
	IF (ofile >= 3) THEN
		length = LOF (ofile)
		SEEK (ofile, length)
		PRINT [ofile], stamp$ + text$
		CLOSE (ofile)
	END IF
	errorNew = ERROR(errorOld)
	##WHOMASK = whomask

END FUNCTION
'
'
' ###############################
' #####  XstOpenLibrary ()  #####
' ###############################
'
' handle = XstOpenLibrary (name$)
'
' This function will only open Dynamic Libraries.
'
' See: XstCloseLibrary(), XstGetLibraryAddress()
'
FUNCTION  XstOpenLibrary (name$)
	handle = LoadLibraryA (&name$)
	IFZ handle THEN PRINT "XstOpenLibrary()Error", name$
	RETURN (handle)
END FUNCTION
'
'
' ###########################################
' #####  XstSetCommandLineArguments ()  #####
' ###########################################
'
' XstSetCommandLineArguments (argCount, @argv$[])
'
' Set the number of command line arguments to argCount,
' and the command line argument strings to argv$[].
' argCount should never be less than 0.
'
' See: XstGetCommandLine(), XstGetCommandLineArguments()
'
FUNCTION  XstSetCommandLineArguments (argc, @argv$[])
	SHARED  setarg
	SHARED  setargc
	SHARED  setargv$[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstSetCommandLineArguments()lockout", lockout)
'
	upper = UBOUND (argv$[])
	ucount = upper + 1
	setarg = $$TRUE
	setargc = argc
	DIM setargv$[]
'
	IF (setargc > ucount) THEN setargc = ucount
'
	IF argv$[] THEN
		##WHOMASK = $$FALSE
		DIM setargv$[upper]
		FOR i = 0 TO upper
			setargv$[i] = argv$[i]
		NEXT i
		##WHOMASK = whomask
	END IF
END FUNCTION
'
'
' ##################################
' #####  XstSetDateAndTime ()  #####
' ##################################
'
' error = XstSetDateAndTime (year, month, day, weekDay, hour, min, sec, msec)
'
' Set the current system date and time.  This function may fail if the
' user running the task does not have supervisor or administrator priority.
'
' See: XstGetDateAndTime(), XstGetLocalDateAndTime()
'
FUNCTION  XstSetDateAndTime (year, month, day, weekDay, hour, minute, second, nanos)
	STATIC	UTM  time
	AUTOX  unixtime
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	time.tm_year	= year
	time.tm_mon		= month - 1
	time.tm_mday	= day
	time.tm_wday	= weekDay
	time.tm_hour	= hour
	time.tm_min		= minute
	time.tm_sec		= second
'
	DeltaTimeZone (@delta)
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300012
	unixtime = mktime (&time) + delta
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (unixtime < 0) THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstSetDateAndTime(A):error", error
		##ERROR = error : ##WHERE = 30460040
		RETURN (error)
	END IF
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300013
'	error = stime (&unixtime)          '*cw* 220822-
	error = clock_settime (&unixtime)  '*cw* 220822+
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstSetDateAndTime(B):error", error
		##ERROR = error : ##WHERE = 30460053
	END IF
	RETURN (error)
END FUNCTION
'
'
' ##########################################
' #####  XstSetEnvironmentVariable ()  #####
' ##########################################
'
' XstSetEnvironmentVariable (@name$, @value$)
'
' Set environment variable name$ to value$.  For example,
' XstSetEnvironmentVariable (@"XBASIC", @"usr/xb").
'
' See: XstGetEnvironmentVariable(), XstGetEnvironmentVariables()
'
FUNCTION  XstSetEnvironmentVariable (name$, value$)
	SHARED  envp$[]
'
	whomask = ##WHOMASK
'
	IFZ entry THEN
		IFZ envp$[] THEN XstGetEnvironmentVariables (@count, @var$[])
		entry = $$TRUE
		DIM var$[]
	END IF
'
	slot = -1
	found = $$FALSE
	##WHOMASK = $$FALSE
	ename$ = TRIM$ (name$)						' environment variable name
	envp$ = ename$ + "=" + value$			' environment variable name=value
	upper = UBOUND (envp$[])					' upper environment variable
	##WHOMASK = whomask
	lockout = ##LOCKOUT
'
	FOR i = 0 TO upper
		slot$ = envp$[i]
		IF (slot < 0) THEN
			IFZ slot$ THEN slot = i
		END IF
		equal = INSTR (slot$, "=")
		IF equal THEN
			vname$ = TRIM$(LEFT$(slot$,equal-1))
			IF (ename$ = vname$) THEN
				##WHOMASK = $$FALSE
				envp$[i] = envp$
				##WHOMASK = whomask
				addr = &envp$[i]
				found = $$TRUE
				EXIT FOR
			END IF
		END IF
	NEXT i
'
	IFZ found THEN
		IF (slot < 0) THEN
			upper = upper + 1
			##WHOMASK = $$FALSE
			REDIM envp$[upper]
			##WHOMASK = whomask
			slot = upper
		END IF
		envp$[slot] = ""
		##WHOMASK = $$FALSE
		envp$[slot] = envp$
		addr = &envp$[slot]
		##WHOMASK = whomask
	END IF
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300014
	error = putenv (addr)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END FUNCTION
'
'
' ################################
' #####  XstSetException ()  #####
' ################################
'
' XstSetException (exception)
'
'
' See: XstExceptionNumberToName()
'      XstExceptionToSystemException()
'      XstSystemExceptionNumberToName()
'      XstSystemExceptionToException()
'      XstSetExceptionFunction()
'
FUNCTION  XstSetException (exception)
'
	##EXCEPTION = exception
END FUNCTION
'
'
' ########################################
' #####  XstSetExceptionFunction ()  #####
' ########################################
'
' XstSetExceptionFunction (functionAddress)
'
' Set the exception function to functionAddress.  When exceptions
' occur in standalone programs, the exception function is executed.
' The exception function must take zero arguments.
'
'
' See: XstExceptionNumberToName()
'      XstExceptionToSystemException()
'      XstSystemExceptionNumberToName()
'      XstSystemExceptionToException()
'      XstSetException()
'
FUNCTION  XstSetExceptionFunction (function)
	SHARED	exceptionFunction
'
	exceptionFunction = function
END FUNCTION
'
'
' ##############################
' #####  XstSetNewline ()  #####
' ##############################
'
' XstSetNewline (save, paste)
'
' Valid values for save and paste are:
'  $$NewlineLF
'  $$NewlineNL
'  $$NewlineCRLF
'  $$NewlineDefault
'
' See: XstGetNewLine()
'
FUNCTION  XstSetNewline (save, paste)
	SHARED	sysSaveNewline,  sysPasteNewline
	SHARED	userSaveNewline,  userPasteNewline
'
	IF ##WHOMASK THEN
		SELECT CASE save
			CASE 0		: userSaveNewline = $$NewlineDefault
			CASE 1, 2	: userSaveNewline = save
		END SELECT
		SELECT CASE paste
			CASE 0		: userPasteNewline = $$NewlineDefault
			CASE 1, 2	: userPasteNewline = paste
		END SELECT
	ELSE
		SELECT CASE save
			CASE 0		: sysSaveNewline = $$NewlineDefault
			CASE 1, 2	: sysSaveNewline = save
		END SELECT
		SELECT CASE paste
			CASE 0		: sysPasteNewline = $$NewlineDefault
			CASE 1, 2	: sysPasteNewline = paste
		END SELECT
	END IF
END FUNCTION
'
'
' ###############################
' #####  XstSetPrintTab ()  #####
' ###############################
'
' XstSetPrintTab (pixels)
'
' Set the number of pixels between tab positions in the console.
'
' See: XstGetPrintTab (pixels)
'
FUNCTION  XstSetPrintTab (pixels)
	IF (pixels < 0) THEN pixels = 0
	##TABSAT = pixels
END FUNCTION
'
'
' ##################################
' #####  XstSetProgramName ()  #####
' ##################################
'
' XstSetProgramName (prog$)
'
' See: XstGetProgramName()
'
FUNCTION  XstSetProgramName (@prog$)
	SHARED  userProgram$
	SHARED  sysProgram$
'
	whomask = ##WHOMASK
	##WHOMASK = $$FALSE
'
	IF whomask THEN
		userProgram$ = prog$
	ELSE
		sysProgram$ = prog$
	END IF
	##WHOMASK = whomask
END FUNCTION
'
'
' ##################################
' #####  XstSetSystemError ()  #####
' ##################################
'
' XstSetSystemError (error)
'
' Set the current operating system error number.
'
' See: XstGetSystemError(), XstSystemErrorToError()
'
FUNCTION  XstSetSystemError (sysError)
	xb_seterrno(sysError)
END FUNCTION
'
'
' #########################
' #####  XstSleep ()  #####
' #########################
'
' XstSleep (msec)
'
' Suspend program execution for msec milliseconds.  While a
' program sleeps, other programs get an opportunity to run.
'
FUNCTION  XstSleep (ms)
'
' This function has been changed to call XxxXgrSleep() which in turn
' uses the "select" function to do the waiting and will return early
' if a system event is available or timer interrupt has occurred.
'
	SHARED  sleepSystem
	SHARED  sleepUser
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstSleep()lockout", lockout)
'
	delta = ms
	XstGetSystemTime (@start)
	IF (delta <= 0) THEN RETURN ($$FALSE)
'
	SELECT CASE whomask
		CASE 0		: GOSUB SleepSystem
		CASE ELSE	: GOSUB SleepUser
	END SELECT
	##WHOMASK = whomask
	RETURN
'
' *****  SleepSystem  *****
'
SUB SleepSystem
	IFZ sleepSystem THEN
		DO WHILE (delta > 0)
			IF (delta > 200) THEN delta = 200
			sleepSystem = $$TRUE
			'
			IF sleepSystem THEN
				rc = XxxXgrSleep (delta)            ' returns early if there is an event
			END IF
			'
			IF rc THEN sleepSystem = $$FALSE
			XstGetSystemTime (@time)
			delta = ms - (time - start)
		LOOP WHILE sleepSystem
	END IF
	sleepSystem = $$FALSE
END SUB
'
' sleep user, process system events/messages every .200 seconds
'
' *****  SleepUser  *****
'
SUB SleepUser
	IFZ sleepUser THEN
		DO
			IF ##SOFTBREAK THEN EXIT DO        ' process break keystrokes
			'
			IF (delta > 200) THEN delta = 200
			sleepUser = $$TRUE
			'
			IF sleepUser THEN
				sysQueueCount = XxxXgrSleep (delta)        ' returns early if there is an event
				IF sysQueueCount THEN
					XxxXgrSysMessages ()
				END IF
			END IF
			'
			XstGetSystemTime (@time)
			delta = ms - (time - start)
		LOOP WHILE (delta > 0)
	END IF
	sleepUser = $$FALSE
END SUB
END FUNCTION
'
'
' #############################
' #####  XstStartTask ()  #####
' #############################
'
' error = XstStartTask (@taskNum, count, msec, &function())
'
' XstStartTask will assign a standard XBasic function to be called
' repeatedly for a specified number of times, or forever, at a
' specified time interval.
'
' error is return TRUE  and taskNum = 0, if a task failed to be assigned.
' error is return FALSE and taskNum = 1 to 15, if a task is assigned successfully.
'
' count is the number of times the task is to be repeated.
'       Set count to -1 to repeat forever.
'
' msec is the time in milliseconds that the task is to be repeated.
'
' &function() is the address of the XBasic FUNCTION that will be
' called with no arguments.  A function can only be assigned once.
' Starting the same function address again will modify the count
' and msec of the existing taskNum for that task address.
'
' Task functions should run quickly and return to the caller after
' a small time duration. They should not contain wait loops that
' could cause the program to block. A task function should never call
' XgrProcessMessages() because the amount of time to process messages
' is unpredictable, and it will appear to the task manager that the
' task is engaged all the time that it is processing messages.
'
' ---------------------------- NOTE -----------------------------------------------
'
' XstStartTask() requires the user program to do XgrProcessMessages () for the
' task to be processed. This will be in most XBasic GUI programs as follows:
''
'' convenience function message loop
''
'  DO
'    XgrProcessMessages ($$ProcessOneOnly)
'    DO WHILE XuiGetNextCallback (@grid, @message$, @v0, @v1, @v2, @v3, @kid, @r1$)
'      GOSUB Callback
'    LOOP
'  LOOP UNTIL terminateProgram
'
' ---------------------------------------------------------------------------------
'
' See: XgrProcessMessages(), XstKillTask(), XstGetTaskInfo()
'
FUNCTION  XstStartTask (taskNum, count, msec, func)
	SHARED TASK task[]
	SHARED systemTaskGrid
	SHARED systemTaskWindow
	SHARED userTaskGrid
	SHARED userTaskWindow
'
	whomask = ##WHOMASK
	taskNum = 0
'
	IF whomask THEN
		taskGrid = userTaskGrid
		taskWindow = userTaskWindow
	ELSE
		taskGrid = systemTaskGrid
		taskWindow = systemTaskWindow
	END IF
'
	IF taskGrid THEN
		error = XgrGetWindowState (taskWindow, @state)
		IFZ error THEN
			error = XgrGetGridState (taskGrid, @state)
		END IF
	ELSE
		error = $$TRUE
	END IF
	IF error THEN GOSUB CreateTaskWindow
'
' The following idea is fron XuiSetCallback()
'
' A common error is to forget trailing "()" on function name, which
' sets the function address to some bad variable in data memory.
' To prevent this, we make sure the address is not in data memory.
'
	badaddr = $$FALSE
	IF ((func >= ##STACK0) AND (func < ##STACKZ)) THEN badaddr = $$TRUE
	IF ((func >= ##DATA0)  AND (func < ##DATAZ))  THEN badaddr = $$TRUE
	IF ((func >= ##DYNO0)  AND (func < ##DYNOZ))  THEN badaddr = $$TRUE
	IF ((func >= ##BSS0)   AND (func < ##BSSZ))   THEN badaddr = $$TRUE
'
	SELECT CASE TRUE
		CASE taskWindow == 0              : error$ = "taskWindow not available"
		CASE badaddr == $$TRUE            : error$ = "Invalid function address =" + HEXX$(func)
		CASE count == 0                   : error$ = "no count value =" + STR$(count)
		CASE count < -1                   : error$ = "invalid negative count value =" + STR$(count)
		CASE msec <= 0                    : error$ = "Invalid time value, msec =" + STR$(msec)
	END SELECT
	IF error$ THEN
		PRINT "XstStartTask():"; error$
		taskNum = 0
		RETURN $$TRUE
	END IF
'
	IFZ task[] THEN
		##WHOMASK = 0
		DIM task[$$maxTask]
		##WHOMASK = whomask
	END IF
'
	FOR i = 1 TO $$maxTask
		IF (task[i].taskFunc == func) THEN              ' existing task ?
			IF (task[i].whomask != whomask) THEN DO NEXT  ' but different user ?
			task[i].count = count                         ' new count
			task[i].msec  = msec                          ' new time interval
			task[i].request = $$FALSE
			task[i].skips = 0
			taskNum = i
			RETURN ($$FALSE)
		END IF
	NEXT i
'
	FOR i = 1 TO $$maxTask
		IFZ task[i].taskFunc THEN
			taskNum = i
			task[i].count = count
			task[i].msec = msec
			task[i].engaged = $$FALSE
			task[i].request = $$FALSE
			task[i].skips = 0
			task[i].whomask = whomask
			tgrid = NOT taskNum
'
			IF (count == -1) THEN
				tcount = 0x7FFFFFFF
			ELSE
				tcount = count
			END IF
			return = XxxXstTimer ($$TimerStart, tgrid, @timer, tcount, msec, &XxxXstTaskTimer())
			IF (return || (timer == 0)) THEN
				PRINT "XstStartTask() Failed to start timer for task", i, HEXX$(func)
				taskNum = 0
				RETURN ($$TRUE)
			END IF
			task[i].timer = timer
			task[i].taskFunc = func
			taskNum = i
			RETURN ($$FALSE)
		END IF
	NEXT i
	PRINT "XstStartTask() Failed : No task register available", count, msec, HEXX$(func)
'
	taskNum = 0
	RETURN ($$TRUE)
'
'--------------------------------------------------------------
'
' *****  CreateTaskWindow  *****
'
'
SUB CreateTaskWindow
'
		w = $$WindowMinimumWidth
		h = $$WindowMinimumHeight
		XgrCreateWindow (@taskWindow, 0, 0, 0, w, h, 0, "")
		XgrCreateGrid   (@taskGrid, 0, x, y, w, h, taskWindow, 0, &XxxXstTaskController())
'
		IF ##WHOMASK THEN
			userTaskGrid = taskGrid
			userTaskWindow = taskWindow
		ELSE
			systemTaskGrid = taskGrid
			systemTaskWindow = taskWindow
		END IF
'
END SUB
'
END FUNCTION
'
'
' ##############################
' #####  XstStartTimer ()  #####
' ##############################
'
' XstStartTimer (@timer, count, msec, &function())
'
' Create a timer, set its cycle count, set its msec countdown time,
' set its four argument timeout function() address, and start the timer.
'
' returns timer number in "timer"
' timer numbers <= 0 are not valid
'
' Each time the timer times out, XstStartTimer() calls:
'
' @function (timer, @count, msec, time)
'
' function() can kill the timer in the following ways:
'    return -1
'    set count = 0
'    set count = -1
'
' function() must accept four XLONG arguments, and can change
' count to change the number of timeout cycles remaining.
'
' IMPORTANT NOTE:
' &function() should NOT do functions that cause dynamic memory allocation.
' That means that function() should never do any STRING$ functions or alter
' STRING$ type variables. Arrays should not be a string type and only be of
' scope SHARED or EXTERNAL and be dimentioned (DIM or REDIM) in another
' function before the XstStartTimer() function is called.
' If a memory allocation is in progress at the instant a timer interrupt
' occurs, and function() does a memory allocation on top of it, a memory
' allocation error can result or memory be corrupted.
'
' Consider using XstStartTask() which does not have these restrictions.
'
' See: XgrSetGridTimer(), XstStartTask()
'
FUNCTION  XstStartTimer (timer, count, msec, func)
'
	return = XxxXstTimer ($$TimerStart, 0, @timer, count, msec, func)
'
	RETURN (return)
END FUNCTION
'
'
' ######################################
' #####  XstSystemErrorToError ()  #####
' ######################################
'
' XstSystemErrorToError (sysError, @error)
'
' Convert an operating system error number to a native error number.
'
'
' See: ERROR()
'      ERROR$()
'      XstErrorNameToNumber()
'      XstErrorNumberToName()
'      XstSystemErrorNumberToName()
'
FUNCTION  XstSystemErrorToError (sysError, error)
'
	upper = UBOUND (#OSTOXERROR[])
	error = ($$ErrorObjectSystem << 8) OR $$ErrorNatureError
	IF ((sysError < 0) OR (sysError > upper)) THEN RETURN
	error = #OSTOXERROR[sysError]
'	PRINT "XstSystemErrorToError()", error
END FUNCTION
'
'
' ###########################################
' #####  XstSystemErrorNumberToName ()  #####
' ###########################################
'
' XstSystemErrorNumberToName (sysError, @sysError$)
'
' Convert a system error number into an error$ name string.
'
'
' See: ERROR()
'      ERROR$()
'      XstErrorNameToNumber()
'      XstErrorNumberToName()
'      XstSystemErrorToError()
'
FUNCTION  XstSystemErrorNumberToName (sysError, sysError$)
'
	upper = UBOUND (#OSERROR$[])
	IF ((sysError < 0) OR (sysError > upper)) THEN sysError$ = "Unknown System Error Number" : RETURN
	sysError$ = #OSERROR$[sysError]
END FUNCTION
'
'
' ###############################################
' #####  XstSystemExceptionNumberToName ()  #####
' ###############################################
'
' XstSystemExceptionNumberToName (sysException, @sysException$)
'
' Convert an operating system exception number into a string name.
'
'
' See: XstExceptionNumberToName()
'      XstExceptionToSystemException()
'      XstSystemExceptionToException()
'      XstSetException()
'      XstSetExceptionFunction()
'
FUNCTION  XstSystemExceptionNumberToName (exception, exception$)
	SHARED	sysException$[]
'
	upper = UBOUND (sysException$[])
	IF ((exception < 0) OR (exception > upper)) THEN
		exception$ = "Unknown System Exception Number"
		RETURN
	END IF
	exception$ = sysException$[exception]
END FUNCTION
'
'
' ##############################################
' #####  XstSystemExceptionToException ()  #####
' ##############################################
'
' XstSystemExceptionToException (sysException, @exception)
'
' Convert an operating system exception into a native exception.
'
'
' See: XstExceptionNumberToName()
'      XstExceptionToSystemException()
'      XstSystemExceptionNumberToName()
'      XstSetException()
'      XstSetExceptionFunction()
'
FUNCTION  XstSystemExceptionToException (signal, exception)
'
	SELECT CASE signal
		CASE $$SIGNONE			: exception = $$ExceptionNone								' no problem
		CASE $$SIGHUP				: exception = $$ExceptionUnknown						' hangup or death of controlling process
		CASE $$SIGINT				: exception = $$ExceptionBreakKey						' interrupt keystroke  (^backspace or ^delete)
		CASE $$SIGQUIT			: exception = $$ExceptionBreakKey						' quit keystroke (if defined and enabled)
		CASE $$SIGILL				: exception = $$ExceptionInvalidInstruction	' invalid instruction
		CASE $$SIGTRAP			: exception = $$ExceptionBreakpoint					' trap / breakpoint
		CASE $$SIGABRT			: exception = $$ExceptionBreakKey						' abort keystroke
		CASE $$SIGIOT				: exception = $$ExceptionBreakKey						' IOT instruction
		CASE $$SIGBUS				: exception = $$ExceptionAlignment					' bus error  (Misaligned or Protection Error)
		CASE $$SIGFPE				: exception = $$ExceptionInvalidOperation		' floating point trap
		CASE $$SIGKILL			: exception = $$ExceptionUnknown						' kill this process
		CASE $$SIGUSR1			: exception = $$ExceptionUnknown						' unknown #1
		CASE $$SIGSEGV			: exception = $$ExceptionSegmentViolation		' segment violation
		CASE $$SIGUSR2			: exception = $$ExceptionUnknown						' unknown #2
		CASE $$SIGPIPE			: exception = $$ExceptionInvalidOperation		' write on pipe with noone on other end
		CASE $$SIGALRM			: exception = $$ExceptionTimer							' alarm clock interrupt
		CASE $$SIGTERM			: exception = $$ExceptionUnknown						' termination of process by software
		CASE $$SIGSTKFLT		: exception = $$ExceptionStackOverflow			' new
		CASE $$SIGCHLD			: exception = $$ExceptionUnknown						' child process terminated or stopped
		CASE $$SIGCONT			: exception = $$ExceptionUnknown						' continue stopped process
		CASE $$SIGSTOP			: exception = $$ExceptionUnknown						' sendable stop signal not from tty
		CASE $$SIGTSTP			: exception = $$ExceptionUnknown						' stop signal from tty
		CASE $$SIGTTIN			: exception = $$ExceptionUnknown						' to readers pgrp upon background tty read
		CASE $$SIGTTOU			: exception = $$ExceptionUnknown						' same for output if tp->t_local&TOSTOP
		CASE $$SIGURG				: exception = $$ExceptionUnknown						' new
		CASE $$SIGXCPU			: exception = $$ExceptionUnknown						' new
		CASE $$SIGXFSZ			: exception = $$ExceptionUnknown						' new
		CASE $$SIGVTALRM		: exception = $$ExceptionTimer							' virtual timer alarm
		CASE $$SIGPROF			: exception = $$ExceptionUnknown						' profile alarm
		CASE $$SIGWINCH			: exception = $$ExceptionUnknown						' window configuration change
		CASE $$SIGIO				: exception = $$ExceptionUnknown						' new
		CASE $$SIGPOLL			: exception = $$ExceptionUnknown						' pollable event occured
		CASE $$SIGPWR				: exception = $$ExceptionUnknown						' power failure
		CASE $$SIGUNUSED		: exception = $$ExceptionUnknown						' new
		CASE $$SIGRTMIN			: exception = $$ExceptionUnknown						' new
		CASE $$SIGMAX				: exception = $$ExceptionUnknown						' highest signal number
		CASE ELSE						: exception = $$ExceptionUnknown						' ??? who knows ???
	END SELECT
END FUNCTION
'
'
' ################################
' #####  XstClearConsole ()  #####
' ################################
'
' XstClearConsole ()
'
' Erases all the text that is displayed on the console window.
'
' The console can be cleared manually by clicking on "Run" from the main menu,
' and selecting "Erase Output"
'
' See: XstCreateConsole(), XstDisplayConsole(), XstHideConsole, XstShowConsole()
'
FUNCTION  XstClearConsole ()
'
	XstGetConsoleGrid (@grid)
	IF (grid <= 0) THEN RETURN
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	text$ = ""
	DIM text$[]
	XuiSendMessage (grid, #SetTextArray, 0, 0, 0, 0, 0, @text$[])
	XuiSendMessage (grid, #SetTextString, 0, 0, 0, 0, 0, @text$)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, 0, 0)
	##WHOMASK = whomask
END FUNCTION
'
'
' #################################
' #####  XstCreateConsole ()  #####
' #################################
'
' XstCreateConsole (xDisp, yDisp, width, height)
'
' Create the console window at a specific location
' and size for a standalone program. If there is
' an existing console, or running in the PDE where
' there is always a cosole window, the console is
' repositioned and resized. This is so you can see
' what it will look like in a standalone program.
'
' If both the width and height are zero it will
' attempt to create a console that will display
' 25 lines of text with 80 characters per line.
'
' The console window will not be be visible when
' it is created. It needs to be made visible with
' XstDisplayConsole() or XstShowConsole().
'
' To change the style of the scroll bars and colors
' of the console, use XstSetConsoleStyleAndColors()
'
' Example code:
'
'    xDisp = 90     ' almost to the far right of the workarea
'    yDisp = 50     ' half way down the workarea
'    width = 50     ' half the width of the workarea
'    height = 75    ' 3/4 of the height of the workarea
'    windowType = $$WindowTypeNormal
'    style = 7      ' 7 is the maximum style number
'    font$ = "9x15bold"
'    '
'    XstWindowSizePercent (@xDisp, @yDisp, @width, @height, windowType)
'    XstCreateConsole (xDisp, yDisp, width, height)
'    XstSetConsoleStyleAndColors (style, $$White, $$Blue, $$Yellow, $$Red, -1, -1)
'    XstSetConsoleFont (size, weight, italic, angle, font$)
'    XstShowConsole ()
'
'    See the demo program "aconsole.x" for an actual example
'    of customizing the console window.
'
'
' See: XstClearConsole(), XstDisplayConsole(), XstGetConsoleFont(),
'      XstGetConsoleGrid(), XstGetConsoleStyleAndColors,
'      XstGetConsolePositionAndSize(), XstHideConsole(),
'      XstSetConsoleFont(), XstSetConsoleStyleAndColors,
'      XstShowConsole(), INLINE$(), PRINT
'
FUNCTION  XstCreateConsole (xDisp, yDisp, width, height)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
'
' If the size for the console is not specified, calculate the size needed
' for the text area to show 25 lines of text with 80 characters per line,
' using the system default font (0), and style 2 scrollbars.
'
	IFZ (width || height) THEN
		width = 578 : height = 341
		eighty$ = CHR$('W', 80)
		XgrGetTextImageSize (0, @eighty$, @w, @h, @ww, @hh, @g, @f)
		ww = ww + 16 + 2                                            ' style 2 scrollbar is 16 pixels, cursor is 2
		IF (ww > width) THEN width = ww                             ' minimum width for 80 characters
		IF ((hh*25)+16 > height) THEN height = (hh * 25) + 16       ' minimum height for 25 lines and scrollbar
	END IF
'
' If the console window exists, change it to the new size
'
	XstGetConsoleGrid (@grid)
	IF grid THEN
		XuiSendMessage (grid , #ResizeWindow, xDisp, yDisp, width, height, 0, 0)
		##WHOMASK = whomask
		RETURN
	END IF
'
	XuiConsole (@consoleGrid, #CreateWindow, xDisp, yDisp, width, height, 0, "")
	XuiSendMessage (consoleGrid, #SetStyle, 2, 0, 0, 0, 0, 0)
	XuiSendMessage (consoleGrid, #SetColor, 19, -1, -1, -1, 2, 0)
	XuiSendMessage (consoleGrid, #SetColor, 19, -1, -1, -1, 3, 0)
	XuiSendMessage (consoleGrid, #SetWindowTitle, 0, 0, 0, 0, 0, @"Console")
	XuiSendMessage (consoleGrid, #SetGridName, 0, 0, 0, 0, 0, @"consoleGrid")
	XuiSendMessage (consoleGrid, #SetHelpString, -1, 0, 0, 0, -1, @"pde.hlp:Console")
	XuiSendMessage (consoleGrid, #SetGridProperties, -1, 0, 0, 0, 0, 0)
'
	##CONGRID = consoleGrid
'
	confile = XxxOpen ("CON:", $$RD)			' Enable Read
'
	XxxXgrSysMessages ()                  ' process system messages
'
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ##################################
' #####  XstDisplayConsole ()  #####
' ##################################
'
' error = XstDisplayConsole ()
'
' Make the existing console window visible if it is hidden.
' If there is no console window in a standalone program,
' create one at the default size and location and make it visible.
'
' See: XstCreateConsole(), XstGetConsoleGrid(), XstHideConsole(), XstShowConsole()
'
FUNCTION  XstDisplayConsole ()
'
	XstGetConsoleGrid (@grid)
'
' If there is no console create one now
'
	IF (grid <= 0) THEN
		XstCreateConsole (0, 0, 0, 0)
		XstGetConsoleGrid (@grid)
		IFZ grid THEN RETURN (-1)        ' still no console ?
	END IF
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	XuiSendMessage (grid, #DisplayWindow, 0, 0, 0, 0, 0, 0)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ##################################
' #####  XstGetConsoleFont ()  #####
' ##################################
'
' XstGetConsoleFont (@size, @weight, @italic, @angle, @font$)
'
' See: GetFont, XstCreateConsole(), XstDisplayConsole(),
'      XstGetConsoleGrid(), XstSetConsoleFont(), XstShowConsole(),
'
FUNCTION  XstGetConsoleFont (size, weight, italic, angle, font$)
'
	XstGetConsoleGrid (@grid)
	IF (grid <= 0) THEN RETURN ($$TRUE)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	XuiSendMessage (grid, #GetFont, @size, @weight, @italic, @angle, 0, @font$)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' #############################################
' #####  XstGetConsolePositionAndSize ()  #####
' #############################################
'
' XstGetConsolePositionAndSize (@xDisp, @yDisp, @width, @height)
'
' See: XstCreateConsole(), XstGetConsoleFont(), XstGetConsoleStyleAndColors()
'
FUNCTION  XstGetConsolePositionAndSize (xDisp, yDisp, width, height)
'
	XstGetConsoleGrid (@grid)
	IF (grid <= 0) THEN RETURN ($$TRUE)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	XuiSendMessage (grid, #GetWindowSize, @xDisp, @yDisp, @width, @height, 0, 0)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ############################################
' #####  XstGetConsoleStyleAndColors ()  #####
' ############################################
'
' XstGetConsoleStyleAndColors (@style, @textBack, @textDraw, @scrollBack, @scrollDraw, @scrollLo, @scrollHi)
'
' Returns the current style of the console and current
' colors of the horizontal scrollbar for the console.
' It is assumed the vertical scrollbar is the same colors.
'
' See: XstCreateConsole(), XstGetConsoleFont(),
'      XstGetConsolePositionAndSize(),
'      XstSetConsoleStyleAndColors()
'
FUNCTION  XstGetConsoleStyleAndColors (style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi)
'
	whomask = ##WHOMASK
'
	XstGetConsoleGrid (@grid)
	IFZ grid THEN RETURN $$TRUE
'
	##WHOMASK = 0
	XuiSendMessage (grid, #GetStyle, @style, 0, 0, 0, 0, 0)
	XuiSendMessage (grid, #GetColor, @textBack, @textDraw, -1, -1, 1, 0)
	XuiSendMessage (grid, #GetColor, @scrollBack, @scrollDraw, @scrollLo, @scrollHi, 2, 0)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ###############################
' #####  XstHideConsole ()  #####
' ###############################
'
' XstHideConsole ()
'
' Make a visible console window hidden.
'
' See: XstCreateConsole(), XstDisplayConsole(),
'      XstGetConsoleGrid(), XstShowConsole()
'
FUNCTION  XstHideConsole ()
'
	XstGetConsoleGrid (@grid)
	IF (grid <= 0) THEN RETURN
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	XuiSendMessage (grid, #HideWindow, 0, 0, 0, 0, 0, 0)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ##########################
' #####  XstInKey$ ()  #####
' ##########################
'
' char$ = XstInKey$ ()
'
' Return one string character from the console input buffer,
' without echoing it to the screen.  An empty string value
' will be returned immediately if the buffer is empty.
'
'
' See: XstWaitKey$() if you want to wait for a character
'
FUNCTION  XstInKey$ ()
'
	character$ = ""
	XstGetConsoleGrid (@grid)
	IFZ grid THEN RETURN character$
	XuiSetKeyboardFocus (grid, #SetKeyboardFocus, grid, 0, 0, 0, 0, 0)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	XuiSendStringMessage (grid, "GrabTextString", 0, 0, 0, 0, 0, @text$)
	IF text$ THEN
		character$ = LEFT$(text$)
		text$ = LCLIP$(text$)
		XuiSendStringMessage (grid, "PokeTextString", 0, 0, 0, 0, 0, @text$)
	END IF
	##WHOMASK = whomask
'
	RETURN character$
'
END FUNCTION
'
'
' ##################################
' #####  XstSetConsoleFont ()  #####
' ##################################
'
' XstSetConsoleFont (size, weight, italic, angle, font$)
'
' Some Linux commands that can be helpful are:
'      xlsfonts - lists available fonts
'      xfontsel - interactive tool for selecting fonts
'      xfd      - to display characters for a font
'
' See: SetFont, XgrCreateFont(), XstCreateConsole(),
'      XstDisplayConsole(), XstGetConsoleFont(),
'      XstSetConsoleStyleAndColors(), XstShowConsole()
'
FUNCTION  XstSetConsoleFont (size, weight, italic, angle, font$)
'
	XstGetConsoleGrid (@grid)
	IF (grid <= 0) THEN RETURN ($$TRUE)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	XuiSendMessage (grid, #SetFont, size, weight, italic, angle, 0, font$)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, 0, 0)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ############################################
' #####  XstSetConsoleStyleAndColors ()  #####
' ############################################
'
' XstSetConsoleStyleAndColors (style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi)
'
' Changes the current style of the console scrollbars,
' the text backgound and text colors and colors of
' the scrollbars for the console.
'
' style - (0 to 7) set size and looks of the scrollbars
' textBack - text area background color
' textDraw - text character drawing color
' scrollBack - scrollbars background color
' scrollDraw - scrollbars arrows color
' scrollLo   - scrollbars lo border color
' scrollHi   - scrollbars hi border color
'
' See: XstCreateConsole(), XstGetConsoleStyleAndColors,
'      XstSetConsoleFont()
'
FUNCTION  XstSetConsoleStyleAndColors (style, textBack, textDraw, scrollBack, scrollDraw, scrollLo, scrollHi)
'
	whomask = ##WHOMASK
'
	XstGetConsoleGrid (@grid)
	IFZ grid THEN RETURN $$TRUE
'
	##WHOMASK = 0
	XuiSendMessage (grid, #SetStyle, style, 0, 0, 0, 0, 0)
	XuiSendMessage (grid, #SetColor, textBack, textDraw, scrollLo, scrollHi, 1, 0)
	XuiSendMessage (grid, #SetColor, scrollBack, scrollDraw, scrollLo, scrollHi, 2, 0)
	XuiSendMessage (grid, #SetColor, scrollBack, scrollDraw, scrollLo, scrollHi, 3, 0)
	XuiSendMessage (grid, #Redraw, 0, 0, 0, 0, 0, 0)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ###############################
' #####  XstShowConsole ()  #####
' ###############################
'
' XstShowConsole ()
'
' Make the existing console window visible if it is hidden.
' If a console window does not exist, no action is taken.
'
' See: XstCreateConsole(), XstDisplayConsole(),
'      XstGetConsoleGrid(), XstHideConsole()
'
FUNCTION  XstShowConsole ()
'
	XstGetConsoleGrid (@grid)
	IF (grid <= 0) THEN RETURN
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	XuiSendMessage (grid, #ShowWindow, 0, 0, 0, 0, 0, 0)
	##WHOMASK = whomask
'
END FUNCTION
'
'
' ############################
' #####  XstWaitKey$ ()  #####
' ############################
'
' char$ = XstWaitKey$ ()
'
' Return one string character from the console input buffer,
' without echoing it to the screen.  If the buffer is empty,
' wait until a character is available before returning.
'
' See: XstInKey$() to return immediately if the buffer is empty.
'
FUNCTION  XstWaitKey$ ()
'
	DO
		character$ = XstInKey$ ()
		IF character$ THEN EXIT DO
		XstSleep (50)
	LOOP
	RETURN character$
'
END FUNCTION
'
'
' ###########################
' #####  XstBinRead ()  #####
' ###########################
'
' bytesRead = XstBinRead (fileNumber, address, maxBytes)
'
' Read binary data from diskfile into memory.
'
'  bytesRead    = number of bytes read into memory
'  fileNumber   = file number returned by OPEN()
'  address      = memory address to read file data into
'  maxBytes     = maximum number of bytes to read
'
' XstBinRead() reads up to maxBytes into memory at address from fileNumber,
' starting at the current value of the file pointer.
'
' If fewer than maxBytes exist between the current file pointer and the end
' of file, all remaining bytes are read in.  The number of bytes read into
' memory is returned in bytesRead unless an error occurs, in which case
' bytesRead contains -1 and ##XERROR contains the runtime error number.
'
' An error is returned if a disk access error occurs, fileNumber is not open
' for reading, or the file pointer is at or beyond the end of file.
' $$ErrorNatureWouldBlock errors are not considered errors by this function
' and are ignored.
'
' The READ statement is more efficient, safer, and usually more appropriate
' than XstBinRead().  READ never reads too much data, thereby writing
' outside the target variable.  XstBinRead() will attempt to read any
' quantity of data into any address.  Therefore, it can write data outside
' the appropriate area, which almost always leads to fatal memory faults
' that crash the program and the development environment.
'
' READ only works with variables, strings, and arrays that are part of the
' language, however.  When C library functions supply an address to receive
' data, XstBinRead() is an appropriate choice.
'
FUNCTION  XstBinRead (fileNumber, bufferAddr, maxBytes)
	AUTOX bytesRead
'
	error = XxxReadFile (fileNumber, bufferAddr, maxBytes, &bytesRead, 0)
	IFZ error THEN RETURN (bytesRead)
'
' Something that would block if file opened as non-blocking is not really an error
'   (this code may change in future)
'
	XstSystemErrorToError (xb_geterrno(), @error)
	old = ERROR (error)
	nature = error AND 0x00FF
	IF (nature == $$ErrorNatureWouldBlock) THEN RETURN (bytesRead)
'
	PRINT "XstBinWrite()error", error
	XstErrorNumberToName (error, @error$)
	IF ##XBDV THEN PRINT "XstBinWrite()error", error$, okay
'
	RETURN ($$TRUE)
END FUNCTION
'
'
' ############################
' #####  XstBinWrite ()  #####
' ############################
'
' bytesWritten = XstBinWrite (fileNumber, address, writeBytes)
'
' Write binary data to diskfile or device from memory.
'
'  bytesWritten = -1 if an error occurred
'  fileNumber   = file number returned by OPEN()
'  address      = memory address to get data from
'  writeBytes   = number of bytes to write to file
'
' XstBinWrite() writes writeBytes from memory at address to fileNumber,
' starting at the current value of the file pointer.
'
' The number of bytes written is returned in error unless an error occurred,
' in which case -1 is returned and ##ERROR contains the runtime error number.
'
' If the number of bytes written is zero, or less than writeBytes, it may be
' because the device has not finished processing the preceding command. Just
' wait awhile and try again. This should only occur if the device has beened
' opened with the $$NONBLOCK option. Checking the latest ERROR() should indicate
' an error value of 9509 (hexx 0x2525) "Function WouldBlock".
'
' An error is returned if a disk access error occurs,
' or fileNumber is not open for writing.
'
' The WRITE statement is more efficient and usually more appropriate than
' XstBinWrite().  WRITE only works with variables, strings, and arrays
' that are part of the language, however.  When C library functions supply
' an address of data to be saved, XstBinWrite() is an appropriate choice.
'
FUNCTION  XstBinWrite (fileNumber, bufferAddr, numBytes)
	AUTOX  bytesWritten
	IF ((fileNumber < 1) || (fileNumber == 2)) THEN RETURN -1
'
	okay = XxxWriteFile (fileNumber, bufferAddr, numBytes, &bytesWritten, 0)
	IF okay THEN RETURN (bytesWritten)
'
	XstSystemErrorToError (xb_geterrno(), @error)
	old = ERROR (error)
	nature = error AND 0x00FF
	IFZ error THEN RETURN (bytesWritten)
	IF (nature == $$ErrorNatureWouldBlock) THEN RETURN (bytesWritten)
	IF (nature == $$ErrorNatureInterrupted) THEN RETURN (bytesWritten)
'	PRINT "XstBinWrite()error", error
	IF ##XBDV THEN
		XstErrorNumberToName (error, @error$)
		PRINT "XstBinWrite(52)error", HEXX$(error), error$, okay, bytesWritten, writeBytes
	END IF
	RETURN ($$TRUE)
END FUNCTION
'
'
' ###################################
' #####  XstChangeDirectory ()  #####
' ###################################
'
' error = XstChangeDirectory (directory$)
'
' Change the default or working directory to directory$.
'
' newDirectory$: may be absolute /dir1/dir2/dir3
'                    or relative dir1/dir2
'
' return  : $$TRUE   error (##ERROR set)
'           $$FALSE  no error
'
' See: XstGetCurrentDirectory(), XstSetCurrentDirectory()
'
FUNCTION  XstChangeDirectory (newDirectory$)
'
	IFZ newDirectory$ THEN RETURN ($$FALSE)
	dir$ = XstPathString$ (@newDirectory$)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstChangeDirectory()lockout", lockout)
'
	##WHOMASK = 0
	##LOCKOUT = 300015
	error = chdir (&dir$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstChangeDirectory():error", error
		##ERROR = error : ##WHERE = 30750037
		RETURN ($$TRUE)
	END IF
END FUNCTION
'
'
' #################################
' #####  XstCopyDirectory ()  #####
' #################################
'
' error = XstCopyDirectory (source$, dest$)
'
' Copy all the files, sub-directories and files
' in the sub-directories from the source$
' directory to the dest$ directory.
' The dest$ directory must exist, though the
' sub-directories will be created as needed.
' Existing files with the same name will be replaced.
'
' See: XstCopyFile(), XstMakeDirectory()
'
FUNCTION  XstCopyDirectory (source$, dest$)
	FILEINFO  info[]
'
	IFZ dest$ THEN
		error = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ source$ THEN
		error = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (source$ = dest$) THEN
		error = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	d$ = XstPathString$ (@dest$)
	s$ = XstPathString$ (@source$)
	IF (d${UBOUND(d$)} = $$PathSlash) THEN d$ = RCLIP$ (d$, 1)		' remove trailing /
	IF (s${UBOUND(s$)} = $$PathSlash) THEN s$ = RCLIP$ (s$, 1)		' remove trailing /
'
	XstGetFileAttributes (@s$, @sattr)
	IFZ (sattr AND $$FileDirectory) THEN
		error = (($$ErrorObjectDirectory << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	XstGetFileAttributes (@d$, @dattr)
	IFZ (dattr AND $$FileDirectory) THEN
		error = (($$ErrorObjectDirectory << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
' create all subdirectories
'
	error = 0
	DIM file$[]
	attr = $$TRUE
'	attr = $$FileDirectory
	ss$ = s$ + $$PathSlash$ + "*"
	XstGetFilesAndAttributes (@ss$, attr, @file$[], @info[])
'
' create destination subdirectories
'
	IF file$[] THEN
		upper = UBOUND (file$[])
		FOR i = 0 TO upper
			IF ##USERABORT THEN EXIT FOR
			file$ = file$[i]
			IF file$ THEN
				IF (file$ != ".") THEN
					IF (file$ != "..") THEN
						sattr = info[i].attributes
						IF (sattr AND $$FileDirectory) THEN
							dd$ = d$ + $$PathSlash$ + file$
							XstGetFileAttributes (@dd$, @dattr)
							IFZ dattr THEN
								XstMakeDirectory (@dd$)
							ELSE
								IFZ (dattr AND $$FileDirectory) THEN
									error = (($$ErrorObjectDirectory << 8) OR $$ErrorNatureContention)
								END IF
							END IF
						END IF
					END IF
				END IF
			END IF
		NEXT i
	END IF
'
' copy all files in source directory into destination directory
'
	IF file$[] THEN
		upper = UBOUND (file$[])
		FOR i = 0 TO upper
			IF ##USERABORT THEN EXIT FOR
			file$ = file$[i]
			IF file$ THEN
				IF (file$ != ".") THEN
					IF (file$ != "..") THEN
						sattr = info[i].attributes
						IF sattr THEN
							IFZ (sattr AND $$FileDirectory) THEN
								dd$ = d$ + $$PathSlash$ + file$
								XstGetFileAttributes (@dd$, @dattr)
								IF (dattr AND $$FileDirectory) THEN
									error = (($$ErrorObjectDirectory << 8) OR $$ErrorNatureContention)
								ELSE
									ss$ = s$ + $$PathSlash$ + file$
									XstCopyFile (@ss$, @dd$)
								END IF
							END IF
						END IF
					END IF
				END IF
			END IF
		NEXT i
	END IF
'
' recurse into subdirectories
'
	IF file$[] THEN
		FOR i = 0 TO upper
			IF ##USERABORT THEN EXIT FOR
			file$ = file$[i]
			IF file$ THEN
				IF (file$ != ".") THEN
					IF (file$ != "..") THEN
						sattr = info[i].attributes
						IF (sattr AND $$FileDirectory) THEN
							dd$ = d$ + $$PathSlash$ + file$
							XstGetFileAttributes (@dd$, @dattr)
							IF (dattr AND $$FileDirectory) THEN
								ss$ = s$ + $$PathSlash$ + file$
								dd$ = d$ + $$PathSlash$ + file$
								XstCopyDirectory (@ss$, @dd$)
							END IF
						END IF
					END IF
				END IF
			END IF
		NEXT i
	END IF
'
	IF error THEN e = ERROR (error)
	RETURN (error)
END FUNCTION
'
'
' ############################
' #####  XstCopyFile ()  #####
' ############################
'
' error = XstCopyFile (sourceFile$, newFile$)
'
' Create a new file called newFile$ and copy the contents
' of the existing sourceFile$ into newFile$.
'
' See: XstCopyDirectory(), XstMakeDirectory()
'
FUNCTION  XstCopyFile (source$, dest$)
'
	IFZ dest$ THEN
		error = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IFZ source$ THEN
		error = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	IF (source$ = dest$) THEN
		error = (($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument)
		error = ERROR (error)
		RETURN ($$TRUE)
	END IF
'
	s$ = XstPathString$ (@source$)
	d$ = XstPathString$ (@dest$)
'
	fail = XstLoadString (@s$, @string$)
	IFZ fail THEN
		XstSaveString (@d$, @string$)
	END IF
	error = ERROR (-1)
	XxxXgrSysMessages ()
	RETURN (error)
END FUNCTION
'
'
' #####################################
' #####  XstDecomposePathname ()  #####
' #####################################
'
' XstDecomposePathname (pathname$, @path$, @parent$, @fileName$, @file$, @extent$)
'
' Get the components of a pathname$.  The path$, parent$, and fileName$,
' file$ and extent$ of the specified pathname$ are returned.
'
' See: XstGetPathComponents()
'
FUNCTION  XstDecomposePathname (pathname$, path$, parent$, fileName$, file$, extent$)
'
	path$ = ""
	file$ = ""
	extent$ = ""
	parent$ = ""
	fileName$ = ""
	name$ = TRIM$ (pathname$)
	dot = RINSTR (name$, ".")
	slash = RINSTR (name$, $$PathSlash$)
	IF slash THEN preslash = RINSTR (name$, $$PathSlash$, slash-1)
	IF (dot < slash) THEN dot = 0
'
	fileName$ = MID$ (name$, slash+1)							' fileName = "name.ext"
	IFZ dot THEN
		file$ = fileName$														' file = fileName (fileName has no extent)
	ELSE
		file$ = MID$ (name$, slash+1, dot-slash-1)	' file = "name" (without extent)
		extent$ = MID$ (name$, dot)									' extent = ".ext"
	END IF
'
	IF slash THEN
		path$ = LEFT$ (name$, slash-1)							' path = full pathname to left of "/file.ext"
		IF preslash THEN
			parent$ = MID$ (name$, preslash+1, slash-preslash-1)
		ELSE
			parent$ = LEFT$ (name$, slash-1)
		END IF
	END IF
END FUNCTION
'
'
' ##############################
' #####  XstDeleteFile ()  #####
' ##############################
'
' error = XstDeleteFile (file$)
'
' Delete the specified file$.
'
FUNCTION  XstDeleteFile (file$)
'
	IFZ file$ THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument : ##WHERE = 30790014
		RETURN ($$TRUE)
	END IF
'
	f$ = XstPathString$ (@file$)
	XstGetFileAttributes (@f$, @attributes)
'
	IFZ attributes THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent : ##WHERE = 30790022
		RETURN ($$TRUE)
	END IF
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstDeleteFile()lockout", lockout)
	whomask = ##WHOMASK
'
	error = 0
	SELECT CASE TRUE
		CASE (attributes AND $$FileDirectory)
					##WHOMASK = 0
					##LOCKOUT = 300016
					error = rmdir (&f$)
					##LOCKOUT = lockout
					##WHOMASK = whomask
					IF error THEN GOSUB Error
		CASE ELSE
					##WHOMASK = 0
					##LOCKOUT = 300017
					error = unlink (&f$)
					##LOCKOUT = lockout
					##WHOMASK = whomask
					IF error THEN GOSUB Error
	END SELECT
	RETURN (error)
'
'	*****  Error  *****
'
SUB Error
	XstSystemErrorToError (xb_geterrno(), @error)
	##ERROR = error : ##WHERE = 30790053
	return = error
END SUB
END FUNCTION
'
'
' ############################
' #####  XstFindFile ()  #####
' ############################
'
' XstFindFile (file$, @path$[], @path$, @attr)
'
' XstFindFile() looks for the specified file$
' in the subdirectories specified in path$[].
'
' If file$ starts with a path slash, then it
' is assumed to be an absolute path and none
' of the path$[] subdirectories are checked.
'
' IF file$ starts with a .. (parent directory)
' or ./ (current directory), then the path is
' assumed to be relative to the parent directory
' or current directory.
'
' Otherwise the path is determined from the
' search path$[] array.
'
' The purpose of this function is to find a
' file that might be in more than one place.
' This function searches for the file in the
' subdirectories in the order specified in
' path$[].
'
' If the file is found, path$ is returned
' with the complete path, including the
' fileName, and attr contains the file
' attributes.  Note that this function
' does not find directories of the given
' file$ name - it looks for regular files.
'
FUNCTION  XstFindFile (file$, path$[], path$, attr)
'
	a = attr
	attr = 0
	path$ = ""
	error = ERROR(0)
	IFZ file$ THEN RETURN
	upper = UBOUND (path$[])
	XstGetCurrentDirectory (@dir$)
'
	ifile$ = file$
	uno = ifile${0}
	dos = ifile${1}
	tres = ifile${2}
	udir = UBOUND (dir$)
	ufile = UBOUND (file$)
	IF (uno == '\\') THEN uno = '/'
	IF (dos == '\\') THEN dos = '/'
	IF (tres == '\\') THEN tres = '/'
	IF ((dir${udir} != '/') AND (dir${udir} != '\\')) THEN dir$ = dir$ + $$PathSlash$ : INC udir
'
	SELECT CASE TRUE
		CASE ((uno = '.') AND (dos = '.'))
					IF ((ufile < 4) OR (tres != '/')) THEN file$ = "" : path$ = "" : attr = 0 : RETURN
					file$ = MID$ (file$, 4)
					DO
						DEC udir
						dir$ = RCLIP$(dir$,1)
						IF ((dir${udir} == '/') OR (dir${udir} = '\\')) THEN EXIT DO
					LOOP UNTIL (udir < 0)
					path$ = dir$																	' path = parent directory
					IF (udir < 3) THEN
						file$ = ""																	' file = none
					ELSE
						file$ = path$ + MID$(ifile$,4)							' file = file in parent directory
					END IF
		CASE ((uno = '.') AND (dos = '/'))
					ifile$ = dir$ + MID$ (ifile$, 3)
	END SELECT
'
	IF (ifile${0} == $$PathSlash) THEN
		ifile$ = XstPathString$ (@ifile$)
'		a$ = "0.<" + file$ + "> <" + ifile$ + "> <" + path$ + ">\n"
'		write (1, &a$, LEN(a$))
		GOSUB FindAbsolute
'		a$ = "1.<" + file$ + "> <" + ifile$ + "> <" + path$ + ">\n"
'		write (1, &a$, LEN(a$))
	ELSE
		ifile$ = $$PathSlash$ + ifile$			' prevent XstPathString$() from taking ifile$ as a
		ifile$ = XstPathString$ (@ifile$)		' relative path and prepending the current directory
		ifile$ = MID$ (ifile$, 2)						' now remove the fake leading path slash
'		a$ = "2.<" + file$ + "> <" + ifile$ + "> <" + path$ + ">\n"
'		write (1, &a$, LEN(a$))
		GOSUB FindRelative
'		a$ = "3.<" + file$ + "> <" + ifile$ + "> <" + path$ + ">\n"
'		write (1, &a$, LEN(a$))
	END IF
	RETURN
'
' *****  FindAbsolute  *****
'
SUB FindAbsolute
	XstGetFileAttributes (@ifile$, @attr)
	IFZ attr THEN
		path$ = ""
		attr = 0
	ELSE
		IF (attr AND $$FileDirectory) THEN
			IF (a AND $$FileDirectory) THEN
				path$ = ifile$
			ELSE
				path$ = ""
			END IF
		ELSE
			path$ = ifile$
		END IF
	END IF
END SUB
'
' *****  FindRelative  *****
'
SUB FindRelative
	fslash = 0
	XstGetCurrentDirectory (@dir$)
	IF (ifile${0} = $$PathSlash) THEN fslash = 1
'
	FOR i = 0 TO upper
		path$ = path$[i]
		IFZ path$ THEN path$ = dir$
		path$ = XstPathString$ (@path$)
		IFZ path$ THEN path$ = dir$
		upath = UBOUND (path$)
		pslash = 0
		IF (path${upath} = $$PathSlash) THEN pslash = 1
		slash = fslash + pslash
		SELECT CASE slash
			CASE 0	:	path$ = path$ + $$PathSlash$ + ifile$
			CASE 1	: path$ = path$ + ifile$
			CASE 2	: path$ = path$ + MID$ (ifile$, 2)
		END SELECT
		XstGetFileAttributes (@path$, @attr)
'		a$ = a$ + LJUST$(" <" + path$ + ">  ", 32) + " : " + HEX$(attr,8) + "\n"
'		write (1, &a$, LEN(a$))
'		PRINT LJUST$(" <" + path$ + ">  ", 32); HEX$(attr,8)
		IF attr THEN
			IF (attr AND $$FileDirectory) THEN
				IF (a AND $$FileDirectory) THEN EXIT FOR		' found directory
			ELSE
				IFZ a THEN EXIT FOR													' found file
				IF (a AND attr) THEN EXIT FOR								' found file
				IF (a AND $$FileNormal) THEN EXIT FOR				' found file
			END IF
		END IF
		path$ = ""
		attr = 0
	NEXT i
	error = ERROR(0)
	IF attr THEN
		IF path$ THEN
			IF (path${0} != $$PathSlash) THEN
				XstPathToAbsolutePath (@path$, @absolute$)
				path$ = absolute$
			END IF
		END IF
	END IF
END SUB
END FUNCTION
'
'
' #############################
' #####  XstFindFiles ()  #####
' #############################
'
' XstFindFiles (basepath$, filter$, recurse, @file$[])
'
' basepath$ = directory to begin search
' filter$   = file name filter e.g. "myprog.x", "*.x", "a*.x", or "*.00?"
'             a "*" skips over zero or more characters
'             a "?" skips over one single character
' recurse   = $$TRUE for search to include the sub directories
' @file$[]  = matching file names are appended to @file$[]
'
' When 'recurse = $$TRUE' the list of files returned
' does not include files via symbolic links.
'
' See: XstFindFile(), XstGetFiles()
'
FUNCTION  XstFindFiles (basepath$, filter$, recurse, file$[])
	FILEINFO  fileAttrInfo[]
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstFindFiles()lockout", lockout)
	whomask = ##WHOMASK
'
	IF ##USERABORT THEN
		recurse = $$FALSE
		RETURN
	END IF
	path$ = basepath$
	IF (recurse != 0x55555555) THEN path$ = XstSymbolicPathToPath$ (path$)
	IFZ path$ THEN RETURN XstGetCurrentDirectory (@path$)
'
	XstGetFileAttributes (@path$, @attribute)
	IFZ (attribute AND $$FileDirectory) THEN RETURN
'
	DIM new$[]
	ufile = UBOUND (file$[])
	pathend$ = RIGHT$ (path$, 1)
	attributeFilter = NOT $$FileDirectory
	IF ((pathend$ != "/") AND (pathend$ != "\\")) THEN path$ = path$ + "/"
'
	XstGetFilesAndAttributes (path$ + filter$, attributeFilter, @new$[], @fileAttrInfo[])
	ifile = ufile + 1
'
' append names of matching files to end of file$[]
'
	IF new$[] THEN
		upper = UBOUND (new$[])
		DIM order[upper]
		XstQuickSort (@new$[], @order[], 0, upper, $$SortIncreasing)
		ufile = ufile + upper + 1
		REDIM file$[ufile]
		FOR i = 0 TO upper
			IFZ (fileAttrInfo[order[i]].attributes AND $$FileDirectory) THEN
				IF new$[i] THEN file$[ifile] = path$ + new$[i] : INC ifile
			END IF
		NEXT i
		DIM new$[]
		DIM order[]
	END IF
'
	DEC ifile
	ufile = ifile
	REDIM file$[ufile]
	IFZ recurse THEN RETURN
'
' recurse down directories
'
	dirfilter$ = path$ + "*"
	attributeFilter = $$FileDirectory
	XstGetFilesAndAttributes (@dirfilter$, attributeFilter, @dir$[], @fileAttrInfo[])
'
	IFZ dir$[] THEN RETURN									' no sub-directories to search
'
' sort array of directories to recurse
'
	upper = UBOUND (dir$[])
	DIM order[upper]
	XstQuickSort (@dir$[], @order[], 0, upper, $$SortIncreasing)
'
	FOR i = 0 TO upper
		dir$ = path$ + dir$[i]
		XstFindFiles (@dir$, @filter$, 0x55555555, @file$[])
		XxxXgrSysMessages ()
	NEXT i
'
END FUNCTION
'
' ###########################
' #####  XstFileSelect  #####
' ###########################
'
' XstFileSelect (windowTitle$, @file$)
'
' Display an XuiFile GUI window for selecting a file name.
' The window position, directory, and highlighted file will
' be the same as the last time it was displayed, or
' in the position specified by XstFileSelectSetInfo()
'
' The filter field will be that set with XstFileSelectSetInfo()
'
' In : windowTitle$ = string to display at top of GUI window
' Out: file$ = name of the file selected
'
' See: XstFileSelectSetInfo(), XstFileSelectGetInfo,
'      CLOSE(), OPEN(), EOF(), POF(), LOF(), SEEK()
'
FUNCTION  XstFileSelect (windowTitle$, @fileName$)
	STATIC grid
	SHARED xstFilePath$
	SHARED xstFileFilter$
	SHARED filterActive$
	SHARED xstFileX
	SHARED xstFileY
	SHARED xstFileW
	SHARED xstFileH
	SHARED xstFilename$
'
	XstWindowSizePercent (@xstFileX, @xstFileY, @xstFileW, @xstFileH, 0)
'
	IF grid THEN XuiGetGridTypeName (grid, #GetGridTypeName, @gridType, 0, 0, 0, 0, @gridType$)
'
	IF (gridType$ == "XuiFile") THEN
		XuiSendMessage (grid, #ResizeWindow, xstFileX, xstFileY, xstFileW, xstFileH, 0, 0)
	ELSE
		windowType = $$WindowTypeNormal OR $$WindowTypeTopMost
		XuiCreateWindow (@grid, @"XuiFile", xstFileX, xstFileY, xstFileW, xstFileH, windowType, "")
		XuiSendMessage ( grid, #SetWindowTitle, 0, 0, 0, 0, 0, @"XstFileSelect")
		XuiSendMessage ( grid, #SetGridName, 0, 0, 0, 0, 0, @"fileSelect")
		XuiSendMessage ( grid, #SetGridName, $$PreKidKid, 0, 0, 0, 0, @"fileSelect_")
		XuiSendMessage ( grid, #SetGridProperties, -1, 0, 0, 0, 0, 0)
	END IF
'
	IFZ windowTitle$ THEN windowTitle$ = "XstFileSelect"
	XuiSendMessage ( grid, #SetWindowTitle, 0, 0, 0, 0, 0, windowTitle$)
'
	IF xstFileFilter$ THEN
		XstStringToStringArray(xstFileFilter$, @filterArray$[])
		XuiSendMessage ( grid, #SetTextArray, 0, 0, 0, 0, $$FileFilterDropBox, @filterArray$[])
	END IF
	IF filterActive$ THEN
		XuiSendMessage ( grid, #SetTextString, 0, 0, 0, 0, $$FileFilterDropBox, filterActive$)
	END IF
	'
	'A #SetTextString to XuiFile kid 0 actually puts the string in the fileNameText box (kid 2)
	' positions the cursor and does an update
	IF xstFilename$ THEN
		XuiSendMessage ( grid, #SetTextString, 0, 0, 0, 0, 0, xstFilename$)
	ELSE
		XuiSendMessage ( grid, #SetTextString, 0, 0, 0, 0, 0, xstFilePath$)
	END IF
'
	XuiSendMessage ( grid, #GetModalInfo, @v0, 0, 0, 0, 0, 0)
	IF ##USERABORT THEN
'		IF ##XBDV THEN PRINT "XstFileSelect(68):##USERABORT", v0
		v0 = 0
		RETURN
	END IF
'
' Get the window position and size, fileName and filter so that the next time
' this function is called the window will be displayed the same.
'
	XuiSendMessage (grid, #GetWindowSize, @xstFileX, @xstFileY, @xstFileW, @xstFileH, 0, 0)
	XuiSendMessage (grid, #GetTextString, 0, 0, 0, 0, $$FileTextLine, @fileName$)
	XstGetPathComponents(fileName$, @path$, @drive$, @dir$, @file$, 0)
	XuiSendMessage ( grid, #GetTextArray, 0, 0, 0, 0, $$FileFilterDropBox, @filterArray$[])
	XstStringArrayToString(@filterArray$[], @filter$)
'
	XuiSendMessage ( grid, #GetTextString, 0, 0, 0, 0, $$FileFilterDropBox, @activeFilter$)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	xstFilePath$ = path$
	xstFileFilter$ = filter$
	xstFilename$ = fileName$
	filterActive$ = activeFilter$
	##WHOMASK = whomask
'
	SELECT CASE v0
		CASE -1,0   :	fileName$ = ""  'cancel, PDE Kill
		'
		CASE 2,6,7	:							    'fileNameText, fileBox, Enter button
		'
		CASE ELSE		:	fileName$ = ""
									PRINT "XstFileSelect() : unknown response ="; v0
	END SELECT
'
	XxxXgrSysMessages ()
'
	RETURN
'
END FUNCTION
'
' ##################################
' #####  XstFileSelectGetInfo  #####
' ##################################
'
' XstFileSelectGetInfo (@path$, @filter$, @xDisp, @yDisp, @width, @height)
'
' Returns information about the XuiFile GUI window the last time
' it was displayed or set with XstFileSelectSetInfo() function.
' This information is used by XstFileSelect() and XstFileSelectOpen()
'
FUNCTION  XstFileSelectGetInfo (@path$, @filter$, @xDisp, @yDisp, @width, @height)
'
	SHARED xstFilePath$
	SHARED xstFileFilter$
	SHARED xstFileX
	SHARED xstFileY
	SHARED xstFileW
	SHARED xstFileH
'
	path$ = xstFilePath$
	filter$ = xstFileFilter$
	xDisp = xstFileX
	yDisp = xstFileY
	width = xstFileW
	height = xstFileH
END FUNCTION
'
'
' ##################################
' #####  XstFileSelectOpen ()  #####
' ##################################
'
' XstFileSelectOpen (mode, @file$, @fileNumber)
'
' Display an XuiFile GUI window for selecting a file name
' and then open the file in the specified mode.  The
' window position, directory, and highlighted file will
' be the same as the last time it was displayed, or
' in the position specified by XstFileSelectSetInfo()
'
' The filter field will be that set with XstFileSelectSetInfo()
'
'  In: mode constants:
'    $$RD, $$WR, $$RW, $$WRNEW, $$RWNEW, $$RDSHARE, $$WRSHARE, $$RWSHARE
'  Out: file$ = name of the file selected
'       fileNumber >= 3 if file$ successfully opened
'
' See: XstFileSelectSetInfo(), XstFileSelectGetInfo,
'      CLOSE(), OPEN(), EOF(), POF(), LOF(), SEEK()
'
FUNCTION  XstFileSelectOpen (mode, @fileName$, @fileNumber)
'
	SELECT CASE mode
		CASE $$RD       : windowTitle$ = "Open file for reading only."
		CASE $$WR       : windowTitle$ = "Open file for writing only"
		CASE $$RW       : windowTitle$ = "Open file for reading and writing"
		CASE $$WRNEW    : windowTitle$ = "Open new file for writing only"
		CASE $$RWNEW    : windowTitle$ = "Open new file for reading and writing"
		CASE $$RDSHARE  : windowTitle$ = "Open file for reading only"
		CASE $$WRSHARE  : windowTitle$ = "Open existing file for writing only"
		CASE $$RWSHARE  : windowTitle$ = "Open existing file for reading and writing"
		CASE ELSE
							PRINT "Unknown file mode"
							fileName$ = ""
							fileNumber = -1
							RETURN
	END SELECT
'
	DO
		XstFileSelect (windowTitle$, @fileName$)
		IFZ fileName$ THEN EXIT DO
			fileNumber = OPEN(fileName$, mode)
			IF (fileNumber >= 3) THEN EXIT DO
			XstGetPathComponents (fileName$, @path$, @drive$, @dir$, @file$, 0)
						error = ##ERROR
			XstErrorNumberToName (error, @error$)
			message$ = "[XstFileSelectOpen Error]\n" + path$ + "\n" + file$ + "\n" + error$
			IFF XuiMessageRetry (message$, @repy$) THEN
				fileName$ = ""
				EXIT DO
			END IF
	LOOP
'
	XxxXgrSysMessages ()
'
END FUNCTION
'
' ##################################
' #####  XstFileSelectSetInfo  #####
' ##################################
'
' XstFileSelectSetInfo (path$, filter$, xDisp, yDisp, width, height)
'
' Set information for the XuiFile GUI window to be used by
' the functions XuiFileSelect() and XuiFileSelectOpen()
'
'   path$   is the absolute directory path to be displayed in
'           the directory box and may include the file name.
'
'   filter$ is a character string that is converted to a
'           string array and set into the filter drop box
'           e.g. filter$ = "*.x, *.win\n *.txt\n *"
'
'   By default XBasic does not display hidden files, hidden directory
'   or symbolic links. They can be displayed if the first chacter of
'   the filter string is a "." period or dot.
'   ".*"    will diplay all hidden files
'   ".*, *" will display all hidden and normal files
'   ".,"    will display all files including symbolic links
'
'   xDisp, yDisp, width, height are be percentages of the workarea if
'                               they all have a value of 100 or less.
'                               See: XstWindowSizePercent()
'
FUNCTION  XstFileSelectSetInfo (path$, filter$, xDisp, yDisp, width, height)
'
	SHARED xstFilePath$
	SHARED xstFilename$
	SHARED xstFileFilter$
	SHARED filterActive$
	SHARED xstFileX
	SHARED xstFileY
	SHARED xstFileW
	SHARED xstFileH
'
	XstWindowSizePercent (@xDisp, @yDisp, @width, @height, 0)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
'
	IF path$ THEN
		xstFilePath$ = path$
		XstGetPathComponents(xstFilename$, @componentsPath$, @drive$, @dir$, @file$, @attributes)
		IF (componentsPath$ <> path$) THEN xstFilename$ = ""
	END IF
'
	IF filter$ THEN
		xstFileFilter$ = filter$
		filterActive$ = ""
	END IF
	IFF (xDisp == -1) THEN xstFileX = xDisp
	IFF (yDisp == -1) THEN xstFileY = yDisp
	IFF (width == -1) THEN xstFileW = width
	IFF (height == -1) THEN xstFileH = height
'
	##WHOMASK = whomask
END FUNCTION
'
'
' #######################################
' #####  XstGetCurrentDirectory ()  #####
' #######################################
'
' error = XstGetCurrentDirectory (@directory$)
'
' Get the current default aka working directory name in directory$.
'
' See: XstChangeDirectory(), XstSetCurrentDirectory()
'
FUNCTION  XstGetCurrentDirectory (current$)
	AUTOX dir$
'
	current$ = ""
	dir$ = NULL$ (511)
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstGetCurrentDirectory()lockout", lockout)
	whomask = ##WHOMASK
'
	##WHOMASK = 0
	##LOCKOUT = 300018
	okay = getcwd (&dir$, 512)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ okay THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstGetCurrentDirectory():error", error
		##ERROR = error : ##WHERE = 30860032
		RETURN ($$TRUE)
	END IF
'
	dir$ = TRIM$(CSTRING$(&dir$))
	lenDir = LEN (dir$)													' only "/" ends with "/"
'
	IF (lenDir > 1) THEN
		IF (dir${lenDir - 1} = $$PathSlash) THEN dir$ = RCLIP$ (dir$, 1)
	END IF
'
	current$ = dir$
END FUNCTION
'
'
' #############################
' #####  XstGetDrives ()  #####
' #############################
'
' error = XstGetDrives (@count, @drive$[], @type[], @type$[])
'
' Note that LINUX/UNIX systems present drives as directories,
' so drives are invisible.
'
FUNCTION  XstGetDrives (count, drive$[], driveType[], driveType$[])
	STATIC	driveTypes$[]
'
	count = 0
	DIM drive$[]
	DIM driveType[]
	DIM driveType$[]
	RETURN
'
' WindowsNT code follows
'
'	whomask = ##WHOMASK
'	lockout = ##LOCKOUT
'	##LOCKOUT = $$TRUE
'	IFZ driveTypes$[] THEN GOSUB Initialize
'
'	count = 0
'	DIM drive$[63]
'	DIM driveType[63]
'	DIM driveType$[63]
'
'	buffer$ = NULL$(255)
'	##WHOMASK = 0
'	GetLogicalDriveStringsA (255, &buffer$)
'	##WHOMASK = whomask
'
'	i = 0
'	n = 0
'	DO
'		drive$ = ""
'		GOSUB GetDriveName
'		IFZ drive$ THEN EXIT DO
'		drive$[count] = drive$
'		##WHOMASK = 0
'		dt = GetDriveTypeA (&drive$)
'		##WHOMASK = whomask
'		driveType$[count] = driveTypes$[dt]
'		driveType[count] = dt
'		upper = count
'		INC count
'	LOOP WHILE (count < 63)
'
'	REDIM drive$[upper]
'	REDIM driveType[upper]
'	REDIM driveType$[upper]
'	##LOCKOUT = lockout
'	RETURN
'
'
' *****  GetDriveName  *****
'
'SUB GetDriveName
'	drive = 0
'	drive$ = NULL$(255)
'	DO WHILE (i <= 255)
'		c = buffer${i}
'		INC i
'		IFZ c THEN EXIT DO
'		drive${drive} = c
'		INC drive
'	LOOP
'	IFZ drive THEN drive$ = "" ELSE drive$ = LEFT$(drive$,drive)
'END SUB
'
'
' *****  Initialize  *****
'
'SUB Initialize
'	##WHOMASK = 0
'	DIM driveTypes$[ 15]
'	driveTypes$[ $$DriveTypeUnknown ]			= "Unknown"
'	driveTypes$[ $$DriveTypeDamaged ]			= "Rootless"
'	driveTypes$[ $$DriveTypeRemovable ]		= "RemovableMedia"
'	driveTypes$[ $$DriveTypeFixed ]				= "FixedMedia"
'	driveTypes$[ $$DriveTypeRemote ]			= "Remote"
'	driveTypes$[ $$DriveTypeCDROM ]				= "CDROM"
'	driveTypes$[ $$DriveTypeRamDisk ]			= "RamDisk"
'	##WHOMASK = whomask
'END SUB
END FUNCTION
'
'
' ######################################
' #####  XstGetExecutionPathArray  #####
' ######################################
'
' XstGetExecutionPathArray (@path$[])
'
' Reads the system environmental variable "PATH", "path", or "Path" string
' and parses each component into an entry of the path$[] array.
'
FUNCTION  XstGetExecutionPathArray (@path$[])
'
	DIM path$[]
	XstGetEnvironmentVariable (@"PATH", @path$)
	IFZ path$ THEN
		XstGetEnvironmentVariable (@"path", @path$)
		IFZ path$ THEN
			XstGetEnvironmentVariable (@"Path", @path$)
		END IF
	END IF
	IFZ path$ THEN RETURN
'
' count number of elements (separated by colons)
'
	colon = 0
	upper = UBOUND (path$)
	FOR i = 0 TO upper
		IF ((path${i} = ':') OR (path${i} = ';')) THEN
			INC colon
			top = i
		END IF
	NEXT i
'
	k = 1
	last = 0
	IF (top = upper) THEN DEC colon
	DIM path$[colon]
'
	FOR i = 0 TO colon
		IF path$ THEN
			k = INCHR (path$, ":;", k)
			IFZ k THEN
				path$[i] = MID$ (path$, last+1)
			ELSE
				path$[i] = MID$ (path$, last+1, k-last-1)
				last = k
				INC k
			END IF
		END IF
	NEXT i
END FUNCTION
'
'
' #####################################
' #####  XstGetFileAttributes ()  #####
' #####################################
'
' readable = XstGetFileAttributes (file$, @attributes)
'
' Get the file attributes of the specified file$.
' The standard library defines file attribute constants - see xst.dec.
'
' readable will have the $$FileNormal and $$FileReadOnly attribute flags
' indicating that the file can be opened in the reading only mode.
' So code such as the following can be used:
'
' IF XstGetFileAttributes (file$, 0) THEN
'   ifile = OPEN(file$, $$RD)
' END IF
'
' See: XstGetFilesAndAttributes()
'
FUNCTION  XstGetFileAttributes (file$, attributes)
	USTAT64  ustat
	SLONG    error
'
	attributes = 0
	IFZ file$ THEN RETURN
	f$ = XstPathString$ (@file$)
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstGetFileAttributes()lockout", lockout)
	whomask = ##WHOMASK
'
	##WHOMASK = 0
	##LOCKOUT = 300019
	error = xb_stat (&f$, &ustat)       'in xbiface.c and clib.dec
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (error == -1) THEN								' file not found
		attributes = 0
		xb_seterrno(0)
		RETURN
	END IF
'
	stat = ustat.st_mode
	uid  = ustat.st_uid
	gid  = ustat.st_gid
'
'	IF ##CAPSLOCK THEN PRINT "XstGetFileAttributes() stat =", HEXX$(stat), OCTO$(stat), file$
'
	IFZ (stat AND $$U_MODE_WRITE) THEN attributes = attributes OR $$FileReadOnly
'
	SELECT CASE (stat AND $$U_MODE_MASK)
		CASE $$U_MODE_NORMAL  : SELECT CASE FALSE
															CASE XxxAccess (f$, $$R_OK OR $$W_OK) : attributes = attributes OR $$FileNormal
															CASE XxxAccess (f$, $$R_OK)           : attributes = attributes OR $$FileReadOnly
															CASE XxxAccess (f$, $$F_OK)           : attributes = attributes OR $$FileHidden
														END SELECT
														IFZ XxxAccess (f$, $$X_OK) THEN attributes = attributes OR $$FileExecutable

		CASE $$U_MODE_CHAR, $$U_MODE_BLOCK, $$U_MODE_IFIFO :
													IF (stat AND ($$U_MODE_READ OR $$U_MODE_EXECUTE)) THEN
														attributes = attributes OR $$FileNormal
														IFZ (stat AND $$U_MODE_WRITE) THEN attributes = attributes OR $$FileReadOnly
														IF (stat AND $$U_MODE_EXECUTE) THEN attributes = attributes OR $$FileExecutable
													 END IF
		CASE $$U_MODE_DIR    : attributes = attributes OR $$FileDirectory
		CASE $$U_MODE_LINK   : attributes = attributes OR $$FileLink
	END SELECT
'	IF ##CAPSLOCK THEN PRINT "XstGetFileAttributes() attributes =", HEXX$(attributes), file$
'
'	log$ = HEX$(attributes,8) + " : " + HEX$(stat,8) + " : " + HEX$($$U_MODE_DIR,8) + " " + HEX$($$U_MODE_NORMAL,8)
' log$ = log$ + " " + HEX$($$U_MODE_EXECUTE,8) + " " + HEX$($$U_MODE_READ,8) + " " + HEX$($$U_MODE_WRITE,8) + " " + f$
'	XstLog (@log$)
'
	slash = RINSTR (f$, $$PathSlash$)
	IF slash THEN
		IF (MID$(f$, slash+1, 1) = ".") THEN
			attributes = attributes OR $$FileHidden
		END IF
	END IF
'
	RETURN (attributes AND ($$FileNormal OR $$FileReadOnly))
END FUNCTION
'
'
' ############################
' #####  XstGetFiles ()  #####
' ############################
'
' maxLength = XstGetFiles (filter$, @file$[])
'
' Get the array of file names in file$[] that corresponds
' to the fileName filter$ string.  filter$ can contain drive,
' path, and fileName with "*" and "?" wildcard characters.
'
' See: XstFindFile(), XstFindFiles(), XstGetFilesAndAttributes()
'
FUNCTION  XstGetFiles (ff$, file$[])
	UDIRENT	dirent
'
	DIM file$[]
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstGetFiles()lockout", lockout)
'
	filter$ = XstPathString$ (@ff$)
	IFZ filter$ THEN RETURN ($$FALSE)
	IF (filter$ = "*") THEN filter$ = $$PathSlash$
'
	upper = UBOUND (filter$)
	IF (upper >= 1) THEN
		y = filter${upper-1}
		z = filter${upper}
		IF (z = '*') THEN
			IF (y = $$PathSlash) THEN filter$ = RCLIP$ (filter$, 1)
		END IF
	END IF
'
	IFZ filter$ THEN filter$ = $$PathSlash$
	XstGetFileAttributes (@filter$, @attributes)	' Is filter$ a valid directory?
'
	IF (attributes AND $$FileDirectory) THEN
		path$ = filter$
		filter$ = ""
	ELSE
		IF attributes THEN													' Is this a specific file?
			DIM file$[0]
			slash = RINSTR (filter$, $$PathSlash$)
			IFZ slash THEN file$ = filter$ ELSE file$ = MID$ (filter$, slash+1)
			file$[0] = file$
			RETURN (LEN(filter$))
		END IF
'
		path$ = ""
		slash = RINSTR (filter$, $$PathSlash$)
		IF slash THEN
			path$		= LEFT$(filter$, slash-1)
			filter$ = MID$ (filter$, slash+1)
			XstGetFileAttributes (@path$, @attributes)		' path better exist
			IFZ attributes THEN RETURN ($$TRUE)						' path doesn't exist
			IFZ (attributes AND $$FileDirectory) THEN RETURN ($$FALSE)
		ELSE
			path$ = "."
		END IF
	END IF
'
	GOSUB CleanFilter
'
'	a$ = "open() : path$ = \"" + path$ + "\"\n"
'	write (1, &a$, LEN(a$))
'
	apath = &path$
	##LOCKOUT = 300020
	##WHOMASK = 0
	idir = opendir (apath)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	a$ = "opendir() : idir.errno = " + STRING$(idir) + "." + STRING$(xb_geterrno) + "\n"
'	write (1, &a$, LEN(a$))
'
	IF (idir <= 0) THEN RETURN ($$TRUE)
'
	ifile = -1
	ufiles = 255
	maxLength = 0
	DIM file$[ufiles]
	buffer$ = NULL$ (4095)
	baddr = &buffer$
'
	DO
		##WHOMASK = 0
		##LOCKOUT = 300021
		ret = xb_readdir(idir, &dirent)
		##LOCKOUT = lockout
		##WHOMASK = whomask
'
		IFZ ret > 0 THEN EXIT DO
		ino = dirent.d_ino
		off = dirent.d_off
		len = dirent.d_reclen
		file$ = dirent.d_name
'
'		log$ = HEX$(&dirent,8) + " : " + HEX$(ino,8) + " " + HEX$(off,8) + " " + HEX$(len,4) + " " + HEX$(pad,2) + " <" + file$ + ">"
'		XstLog (@log$)
		file$ = XstPathString$ (@file$)
		IF file$ THEN
			IF ((file$ != ".") AND (file$ != "..")) THEN
				GOSUB FilterFile
'				a$ = "ffw " + file$ + ":" + path$ + " "
'				write (1, &a$, LEN(a$))
				IF file$ THEN
					upath = UBOUND (path$)
					SELECT CASE TRUE
						CASE (path$ = ".")								: statFile$ = file$
						CASE (path${upath} = $$PathSlash)	: statFile$ = path$ + file$
						CASE ELSE													: statFile$ = path$ + $$PathSlash$ + file$
					END SELECT
					XstGetFileAttributes (@statFile$, @attributes)
					IF (attributes AND $$FileDirectory) THEN
						statFile$ = statFile$ + $$PathSlash$
						file$ = file$ + $$PathSlash$
					END IF
					INC ifile
					IF (ifile > ufiles) THEN
						ufiles = ufiles + 256
						REDIM file$[ufiles]
					END IF
					file$[ifile] = file$
					lenFile = LEN (file$)
'						a$ = "ffx " + file$ + " \n"
'						write (1, &a$, LEN(a$))
'						file$[ifile] = statFile$
'						lenFile = LEN (statFile$)
					IF (lenFile > maxLength) THEN maxLength = lenFile
				END IF
			END IF
		END IF
'
		offset = offset + len
	LOOP
'
	##WHOMASK = 0
	##LOCKOUT = 300022
	closedir (idir)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'	a$ = "ffy " + STRING$(ifile) + ":" + STRING$(ufiles) + "\n"
'	write (1, &a$, LEN(a$))
	IF (ifile != ufiles) THEN REDIM file$[ifile]
'	IF ifile THEN XstQuickSort (@file$[], @null[], 0, ifile, $$SortIncreasing)
'	a$ = "ffz " + STRING$(UBOUND(file$[])) + "\n"
'	write (1, &a$, LEN(a$))
	RETURN (maxLength)
'
'
' *****  CleanFilter  *****  Clean up:	**	*?	\\	TO	*	*	\
'
SUB CleanFilter
	filter$ = LCASE$(filter$)                                   ' for case insensitive
	DO
		dbl = INSTR (filter$, "*?")
		IF dbl THEN
			filter$ = STUFF$(filter$, "?*", dbl, 2)                ' change *? to ?*
		END IF
	LOOP WHILE dbl
	DO
		dbl = INSTR (filter$, "**")
		IF dbl THEN
			filter$ = LEFT$(filter$, dbl) + MID$(filter$, dbl + 2)
		END IF
	LOOP WHILE dbl
	DO
		dbl = INSTR (filter$, "*?")
		IF dbl THEN
			filter$ = LEFT$(filter$, dbl) + MID$(filter$, dbl + 2)
		END IF
	LOOP WHILE dbl
	DO
		dbl = INSTR (filter$, $$PathSlash$ + $$PathSlash$)
		IF dbl THEN
			filter$ = LEFT$(filter$, dbl) + MID$(filter$, dbl + 2)
		END IF
	LOOP WHILE dbl
END SUB
'
' *****  FilterFile  *****
'
SUB FilterFile
	IFZ file$ THEN EXIT SUB
	IFZ filter$ THEN EXIT SUB
	IF (filter$ = "*") THEN EXIT SUB
'
	fileLCase$ = LCASE$(file$)                                   ' for case insensitive
	uFilter = UBOUND(filter$)
	uFile = UBOUND(fileLCase$)
	i = 0
	j = 0
	DO UNTIL (i > uFilter)
		fchar = filter${i}
		SELECT CASE fchar
			CASE '?':                                     ' ? matches one character
						IF (j > uFile) THEN
							file$ = ""
							EXIT SUB
						END IF
			CASE '*'
						IF (i = uFilter) THEN EXIT SUB          ' Trailing * matches all
						INC i
						fchar = filter${i}                      ' Note:  NOT *?
						match = 0
						FOR k = j TO uFile
							IF (fileLCase${k} == fchar) THEN
								match = k + 1
								EXIT FOR
							END IF
						NEXT k
						IFZ match THEN file$ = "" : EXIT SUB     'fail
						j = k
						matchi = i
			CASE ELSE
						IF (j <= uFile) THEN
							cchar = fileLCase${j}
							IF (cchar == fchar) THEN EXIT SELECT
						END IF
						IF match THEN
							j = match
							i = matchi - 1
							DO LOOP
						ELSE
							file$ = ""                             'fail
							EXIT SUB
						END IF
		END SELECT
		INC j
		INC i
	LOOP
	IF (j <= uFile) THEN file$ = ""
END SUB
'
' *****  error  *****
'
error:
	##LOCKOUT = lockout
	##WHOMASK = whomask
	XstSystemErrorToError (xb_geterrno(), @error)
'	IF ##XBDV THEN PRINT "XstGetFiles():error", error
	##ERROR = error : ##WHERE = 30900245
	RETURN ($$TRUE)
END FUNCTION
'
'
' #########################################
' #####  XstGetFilesAndAttributes ()  #####
' #########################################
'
' FILEINFO info[]
' maxLen = XstGetFilesAndAttributes (filter$, attrfilter, @file$[], @info[])
'
' Get an array of fileNames in file$[] and file information in info[]
' for the files specified by the drive/path/fileName in filter$ and the
' file attributes in attrfilter.  The info[] array is type FILEINFO,
' as defined in "xst.dec".  The number of characters in the longest
' fileName is returned in maxLen.
'
' See: XstGetFileAndAttributes()
'
FUNCTION  XstGetFilesAndAttributes (ff$, attributesFilter, file$[], FILEINFO attrInfo[])
	USTAT64  ustat
'
	DIM attrInfo[]
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstGetFilesAndAttributes()lockout", lockout)
	whomask = ##WHOMASK
'
	filter$ = XstPathString$ (@ff$)
'	a$ = "gfa0 " + ff$ + " : " + filter$ + "\n"
'	write (1, &a$, LEN(a$))
	result = XstGetFiles (filter$, @file$[])
'	a$ = "gfa1 " + STRING$(UBOUND(file$[])) + "\n"
'	write (1, &a$, LEN(a$))
	XstGetPathComponents (filter$, @path$, @drive$, @dir$, @fileName$, @attr)
'	a$ = "gfa2 " + filter$ + " : " + drive$ + " : " + dir$ + " : " + fileName$ + " : " + HEX$(attr,8) + "\n"
'	write (1, &a$, LEN(a$))
	IFZ file$[] THEN RETURN (result)
'
	ufile = UBOUND (file$[])
	DIM attrInfo[ufile]
'
	entry = 0
	FOR i = 0 TO ufile
		file$ = file$[i]
		IF file$ THEN
			u = UBOUND (file$)
			c = file${u}																		' last character in fileName
			IF u THEN																				' don't nullify "/" root directory
				IF (c == $$PathSlash) THEN										' last character is /
					file$ = RCLIP$(file$)												' remove / suffix
					file$[i] = file$
				END IF
			END IF
		END IF
		f$ = drive$ + dir$ + file$
		XstGetFileAttributes (@f$, @attributes)
'
'		a$ = "gfa3 " + f$ + " : " + HEX$(attributes,8) + " : " + HEX$(attributesFilter,8) + "\n"
'		write (1, &a$, LEN(a$))
'
		IF (attributes AND attributesFilter) THEN
			file$[entry] = ""
			file$[entry] = file$
			attrInfo[entry].attributes = attributes
'
			##LOCKOUT = 300023
			##WHOMASK = 0
'			stat = xb_stat (&f$, &ustat)
			stat = xb_lstat (&f$, &ustat)    'in xbiface.c and clib.dec
			##WHOMASK = whomask
			##LOCKOUT = lockout
'
			IF (error == -1) THEN
				xb_seterrno(0)
				DO NEXT
			END IF
'
			ctime$$ = ustat.st_ctime				' create time in seconds since 1970 Jan 1 at 00:00:00.000
			mtime$$ = ustat.st_mtime				' create time in seconds since 1970 Jan 1 at 00:00:00.000
			atime$$ = ustat.st_atime				' create time in seconds since 1970 Jan 1 at 00:00:00.000
'
			ctime$$ = ctime$$ * 10000000		' create time in 100 nanosecond units
			mtime$$ = mtime$$ * 10000000		' modify time in 100 nanosecond units
			atime$$ = atime$$ * 10000000		' access time in 100 nanosecond units
'
' do the following if FILEINFO time units are relative to "1601" instead of "1970"
' add difference between "1601 Jan 1" and "1970 Jan 1" in 100 nanosecond units
'
			ctime$$ = ctime$$ + 116444736000000000$$	' create time since 1601 Jan 1 at 00:00:00.000
			mtime$$ = mtime$$ + 116444736000000000$$	' modify time since 1601 Jan 1 at 00:00:00.000
			atime$$ = atime$$ + 116444736000000000$$	' access time since 1601 Jan 1 at 00:00:00.000
'
			f$ = file$
			length = LEN (f$)
			slash = RINSTR (f$, $$PathSlash$, length-1)
			IF slash THEN f$ = MID$ (f$, slash+1)
'
			attrInfo[entry].size       = ustat.st_size
			attrInfo[entry].createTime = ctime$$
			attrInfo[entry].modifyTime = mtime$$
			attrInfo[entry].accessTime = atime$$
			attrInfo[entry].alternateName = f$
			attrInfo[entry].name = file$
'
'			a$ = "gfa4 " + f$ + " : " + file$ + " : " + STRING$(newerustat.st_size) + "\n"
'			write (1, &a$, LEN(a$))
			INC entry
		END IF
		XxxCheckMessages ()
		IF ##USERABORT THEN EXIT FOR
	NEXT i
	DEC entry
	REDIM file$[entry]
	REDIM attrInfo[entry]
'	a$ = "gfa5 " + STRING$(entry) + "\n"
'	write (1, &a$, LEN(a$))
RETURN (result)
'
END FUNCTION
'
'
' #####################################
' #####  XstGetPathComponents ()  #####
' #####################################
'
' XstGetPathComponents (file$, @path$, @drive$, @dir$, @fileName$, @attributes)
'
' Get the components of a file$.  The path$, dir$, and fileName$,
' and attributes of the specified file are returned.
' path$ = drive$ + dir$
'
' Linux does not have a drive$, and is here only to have
' the function be the same as XBasic for Microsoft Windows.
'
' See: XstDecomposePathname()
'
FUNCTION  XstGetPathComponents (file$, path$, drive$, dir$, fileName$, attributes)
'
	dir$ = ""
	work$ = ""
	path$ = ""
	drive$ = ""
	fileName$ = ""
	attributes = 0
	file = $$FALSE
'
	dir$ = XstPathString$ (@file$)
	XstGetCurrentDirectory (@current$)
	' TODO: Is this 'right'? Shouldn't the dir$ of "" be ""?
	IFZ dir$ THEN dir$ = current$
'
	slash = RINSTR (dir$, $$PathSlash$)
	length = LEN (dir$)
'
' get drive$ from file$ or current$
' leave work$ without drive$
' drive$ = "" on unix
'
' replace windows code with UNIX code
'
'	IF colon THEN
'		drive$ = LEFT$ (dir$, colon)
'		dir$ = MID$ (dir$, colon+1)
'		IFZ dir$ THEN dir$ = $$PathSlash$
'		IF (dir${0} != $$PathSlash) THEN dir$ = $$PathSlash$ + dir$
'	ELSE
'		colon = INSTR (current$, ":")
'		IF colon THEN drive$ = LEFT$ (current$, colon)
'		IFZ dir$ THEN dir$ = $$PathSlash$
'		IF (dir${0} != $$PathSlash) THEN dir$ = cpath$ + $$PathSlash$ + dir$
'	END IF
'
' UNIX replacement code
'
' Relative paths should not get a leading /, absolute paths already have
' a leading / so the following code must is removed:
'	IFZ dir$ THEN dir$ = $$PathSlash$
'	IF (dir${0} != $$PathSlash) THEN dir$ = cpath$ + $$PathSlash$ + dir$
'
	upper = UBOUND (dir$)												'
	path$ = drive$ + dir$												'
	XstGetFileAttributes (@path$, @attributes)	' valid directory?
	IF (dir${upper} != $$PathSlash) THEN				' trailing \ means directory
		IF (attributes AND $$FileDirectory) THEN
			path$ = path$ + $$PathSlash$
			dir$ = dir$ + $$PathSlash$
		ELSE
			slash = RINSTR (dir$, $$PathSlash$)			' find last \
			fileName$ = MID$ (dir$, slash+1)				' get fileName$
			dir$ = LEFT$ (dir$, slash)							' get dir$
			path$ = drive$ + dir$										' path$ w/o fileName$
		END IF
	END IF
END FUNCTION
'
'
' #################################
' #####  XstGuessFilename ()  #####
' #################################
'
' XstGuessFilename (@old$, @new$, @guess$, @attributes)
'
' if new name contains drive and/or root path slash,
' the new name is the full path or path\fileName, so
' ignore the old name.
'
' this function will return $$FileNormal if the file
' does not exist, but the path is valid so that the
' specified file could be created, as is often the
' case for files to be saved (they don't yet exist).
'
' if the return value of attributes is zero, the
' file name is invalid for both read and write.
'
FUNCTION  XstGuessFilename (old$, new$, guess$, attributes)
'
	test$ = ""
	guess$ = ""
	o$ = XstPathString$ (@old$)
	n$ = XstPathString$ (@new$)
'
	IFZ n$ THEN n$ = o$
	IFZ n$ THEN XstGetCurrentDirectory (@n$)
'
	SELECT CASE TRUE
		CASE (n${0} = $$PathSlash)	:	guess$ = n$		' leading \
'		CASE (n${1} = ':')					: guess$ = n$		' leading d: (Windows)
	END SELECT
'
	IFZ guess$ THEN
		IFZ o$ THEN XstGetCurrentDirectory (@o$)
		XstGetFileAttributes (@o$, @attributes)
		SELECT CASE TRUE
			CASE (attributes AND $$FileDirectory)
						path$ = o$
			CASE (attributes = 0)
						XstGetCurrentDirectory (@path$)
			CASE ELSE
						XstGetPathComponents (@o$, @path$, @drive$, @dir$, @file$, @attributes)
		END SELECT
		upath = UBOUND (path$)
		IF (path${upath} != $$PathSlash) THEN path$ = path$ + $$PathSlash$
		guess$ = path$ + n$
	END IF
'
	XstGetFileAttributes (@guess$, @attributes)
'
	IFZ attributes THEN
		XstGetPathComponents (@guess$, @path$, @dr$, @di$, @fi$, @at)
		XstGetFileAttributes (@path$, @att)
		IF (att AND $$FileDirectory) THEN attributes = $$FileNormal
	END IF
END FUNCTION
'
'
' ##############################
' #####  XstLoadString ()  #####
' ##############################
'
' error = XstLoadString (@file$, @string$)
'
' Load the contents of file$ into a string$.
' The length of string$ is the same as the number of bytes in file$.
' string$ can contain any combination of ascii and/or binary bytes.
'
' See: XstSaveString()
'
FUNCTION  XstLoadString (file$, text$)
'
	text$ = ""
	##ERROR = $$FALSE
	f$ = XstPathString$ (@file$)
'
	XstGetFileAttributes (@f$, @attributes)					' Does file exist?
	IFZ attributes THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent : ##WHERE = 30940023
		IF ##XBDV THEN PRINT "XstLoadString(24)", file$
		RETURN ($$TRUE)
	END IF
'
	IF (attributes AND $$FileDirectory) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidName : ##WHERE = 30940028
		RETURN ($$TRUE)
	END IF
'
	ifile = OPEN (f$, $$RD)
	IF (ifile < 0) THEN RETURN ($$TRUE)									' ##ERROR set
	fileSize = LOF(ifile)
	IF fileSize THEN
		text$ = NULL$(fileSize)
		READ [ifile], text$
	END IF
	CLOSE (ifile)
END FUNCTION
'
'
' ###################################
' #####  XstLoadStringArray ()  #####
' ###################################
'
' error = XstLoadStringArray (file$, @string$[])
'
' Load the contents of file$ into string array string$[].
' The contents of file$ are broken into separate "lines" by any
' of the following newline byte sequences - "\r\n", "\n\r", "\n".
'
' The newline bytes are not put into string$[].
' If the last characters in file$ are a newline byte sequence,
' the last element of string$[] is an empty string aka "".
'
' See: XstSaveStringArray(), XstSaveStringArrayCRLF()
'
FUNCTION  XstLoadStringArray (file$, text$[])
'
	DIM text$[]
	f$ = XstPathString$ (@file$)
	error = XstLoadString (@f$, @text$)
	IF error THEN RETURN (error)
	XstStringToStringArray (@text$, @text$[])
END FUNCTION
'
'
' ###################################
' #####  XstLockFileSection ()  #####
' ###################################
'
' error = XstLockFileSection (fileNumber, mode, offset$$, length$$)
'
' Note: offset$$ and length$$ are 64-bit signed GIANT integers
'
' See: XstUnlockFileSection()
'
FUNCTION  XstLockFileSection (file, mode, offset$$, length$$)
	SHARED  LOCK  fileLock[]
	SHARED  FILE  fileInfo[]
	AUTOX  UFLOCK  flock
	AUTOX  LOCK  lock[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstLockFileSection()lockout", lockout) : lockout = 0
'
	IF (file <= 2) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalid : ##WHERE = 30960022
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (fileInfo[])
	IF (file > upper) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalid : ##WHERE = 30960028
		RETURN ($$TRUE)
	END IF
'
	IF (offset$$ < 0) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 30960033
		RETURN ($$TRUE)
	END IF
'
	IF (length$$ < 0) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 30960038
		RETURN ($$TRUE)
	END IF
'
' remove the following two tests when UNIX supports 64-bit file pointers
'
	IF (offset$$ > 0x7FFFFFFF) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 30960045
		RETURN ($$TRUE)
	END IF
'
	IF (length$$ > 0x7FFFFFFF) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 30960050
		RETURN ($$TRUE)
	END IF
'
	sfile = fileInfo[file].fileHandle
'
	IF (sfile <= 0) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalid : ##WHERE = 30960057
		RETURN ($$TRUE)
	END IF
'
	IFZ fileLock[] THEN
		##WHOMASK = 0
		upper = (file + 16) OR 0x000F
		DIM fileLock[upper,]
		##WHOMASK = whomask
	END IF
'
	upper = UBOUND (fileLock[])
	IF (upper < file) THEN
		##WHOMASK = 0
		upper = (file + 16) OR 0x000F
		REDIM fileLock[upper,]
		##WHOMASK = whomask
	END IF
'
	IFZ fileLock[file,] THEN
		##WHOMASK = 0
		DIM lock[3]
		ATTACH lock[] TO fileLock[file,]
		##WHOMASK = whomask
	END IF
'
	slot = -1
	overlap = $$FALSE
	begin$$ = offset$$
	end$$ = offset$$ + length$$ - 1$$
	IFZ length$$ THEN end$$ = 0x7FFFFFFF					' UNIX
'	IFZ length$$ THEN end$$ = 0x7FFFFFFFFFFFFFFF	' Win32
	upper = UBOUND (fileLock[file,])
'
	FOR i = 0 TO upper
		IFZ fileLock[file,i].file THEN
			IF (slot < 0) THEN slot = i
		ELSE
			first$$ = fileLock[file,i].offset
			final$$ = first$$ + fileLock[file,i].length - 1$$
			IF (final$$ < first$$) THEN final$$ = 0x7FFFFFFF					' UNIX
'			IF (final$$ < first$$) THEN final$$ = 0x7FFFFFFFFFFFFFFF	' Win32
			IF ((begin$$ <= final$$) AND (end$$ >= first$$)) THEN INC overlap
		END IF
	NEXT i
'
' if the new section overlaps an existing section, that's an error
'
	IF overlap THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidRequest : ##WHERE = 30960106
		RETURN ($$TRUE)
	END IF
'
' lock the new section
'
	offsetLow = GLOW (begin$$)
	offsetHigh = GHIGH (begin$$)
	lengthLow = GLOW (end$$ - begin$$ + 1)
	lengthHigh = GHIGH (end$$ - begin$$ + 1)
'
' remove the following tests when UNIX supports 64-bit file pointers
'
	error = $$FALSE
	IF offsetHigh THEN error = $$TRUE
	IF lengthHigh THEN error = $$TRUE
	IF (offsetLow < 0) THEN error = $$TRUE
	IF (lengthLow < 0) THEN error = $$TRUE
	IF (offsetLow > 0x7FFFFFFF) THEN error = $$TRUE
	IF (lengthLow > 0x7FFFFFFF) THEN error = $$TRUE
'
	IF error THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidRequest : ##WHERE = 30960128
		RETURN ($$TRUE)
	END IF
'
' tell UNIX to lock the file
'
	flock.l_type = $$F_WRLCK				' request exclusive lock ???
	flock.l_whence = $$SEEK_SET			' offset from start of file
	flock.l_start = offsetLow				' first byte to lock
	flock.l_len = lengthLow					' # of bytes to lock
	flock.l_sysid = 0								' not required for F_SETLK
	flock.l_pid = 0									' not required for F_SETLK
'
	##WHOMASK = 0
	##LOCKOUT = 300024
	error = fcntl (sfile, $$F_SETLK, &flock)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstLockFileSection():error", error
		##ERROR = error : ##WHERE = 30960150
		RETURN ($$TRUE)
	END IF
'
	IF (slot < 0) THEN
		##WHOMASK = 0
		slot = upper + 1
		upper = upper + 4
		ATTACH fileLock[file,] TO lock[]
		REDIM lock[upper]
		ATTACH lock[] TO fileLock[file,]
		##WHOMASK = whomask
	END IF
'
' log the newly locked section
'
	fileLock[file,slot].file = file
	fileLock[file,slot].sfile = sfile
	fileLock[file,slot].offset = offset$$
	fileLock[file,slot].length = length$$
	fileLock[file,slot].end = end$$
END FUNCTION
'
'
' #################################
' #####  XstMakeDirectory ()  #####
' #################################
'
' error = XstMakeDirectory (@directory$)
'
'  When error returns TRUE, more information can be obtained with:
'  IF error THEN
'    errorNumber = ERROR(0)
'    errorString$ = ERROR$(errorNumber)
'    PRINT errorString$
'  END IF
'
FUNCTION  XstMakeDirectory (directory$)
'
	IFZ directory$ THEN
		##ERROR = ($$ErrorObjectDirectory << 8) OR $$ErrorNatureInvalidName : ##WHERE = 30970019
		RETURN ($$TRUE)
	END IF
'
	dir$ = XstPathString$ (@directory$)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstMakeDirectory()lockout", lockout)
'
	##WHOMASK = 0
	##LOCKOUT = 300025
	error = mkdir (&dir$, 0x1FF)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstMakeDirectory():error", error
		##ERROR = error : ##WHERE = 30970038
		RETURN ($$TRUE)
	END IF
END FUNCTION
'
'
' ###############################
' #####  XstPathString$ ()  #####
' ###############################
'
' path$ = XstPathString$ (path$)
'
'	file$ = XstPathString$ ("$HOME/.xb64rc")
'
' Converts a path string with win32 style separators '\\' to Linux/UNIX
' style '/' pathslash separators.  It also trims leading and trailing
' spaces, quotation, '<', '>', and '|' characters from the path string.
' And it converts environment path variables to it's equivalent string.
'
FUNCTION  XstPathString$ (path$)
	SHARED  UBYTE  charsetFilename[]
	SHARED  UBYTE  charsetFilenameFirstLast[]
'
	IFZ charsetFilename[] THEN GOSUB Initialize
'
	IFZ path$ THEN RETURN ("")
'
	upper = UBOUND (path$)
	name$ = NULL$ (upper+1)
'
	first = 0
	DO UNTIL charsetFilenameFirstLast[path${first}]
		INC first
	LOOP UNTIL (first > upper)
'
	IF (first > upper) THEN RETURN ("")
'
	final = first + 1
	IF (first < upper) THEN
		DO WHILE charsetFilename[path${final}]
			INC final
		LOOP UNTIL (final > upper)
	END IF
'
	DO WHILE (final > first)
		DEC final
	LOOP UNTIL charsetFilenameFirstLast[path${final}]
'
	length = final - first + 1
	p$ = NULL$ (length)
'
	FOR i = 0 TO length-1
		p${i} = charsetFilename[path${first}]
		INC first
	NEXT i
'
	term$ = $$PathSlash$ + "$"
	total = LEN (p$)
	offset = 0
	DO
		first = INSTR (p$, "$", offset+1)								' $NAME or $(NAME) form
		IFZ first THEN EXIT DO
		IF (p${first} = '(') THEN												' $(NAME) form probably
			after = INSTR (p$, ")", first+2)							' find ) name terminator
			IFZ after THEN EXIT DO												' $( without ) - ignore
			offset = after																' move past $NAME
			variable$ = MID$ (p$, first+2, after-first-2)	' environment variable
			IFZ variable$ THEN DO LOOP										' ignore $()
		ELSE																						' $NAME form
			after = INCHR (p$, term$, first+1)						' find / or $ to terminate name
			IFZ after THEN after = LEN (p$) + 1					' $NAME past end of string
			offset = after																' move past $NAME
			variable$ = MID$ (p$, first+1, after-first-1)	' environment variable
			IFZ variable$ THEN DO LOOP										' ignore $/
			DEC after
		END IF
		XstGetEnvironmentVariable (@variable$, @value$)
		IFZ value$ THEN DO LOOP
		a$ = LEFT$ (p$, first-1)
		c$ = MID$ (p$, after+1)
		p$ = a$ + value$ + c$
		total = LEN (p$)
		offset = LEN (a$) + LEN (value$)
	LOOP WHILE (offset < total)
'
' process "/./" (nop)
'
	nop$ = $$PathSlash$ + "." + $$PathSlash$
	DO
		nop = INSTR (p$, nop$)
		IF nop THEN p$ = LEFT$(p$,nop) + MID$(p$,nop+3)		' "/./" to "/"
	LOOP WHILE nop
'
' process "/../" (parent)
'
	parent$ = $$PathSlash$ + ".." + $$PathSlash$
	DO
		parent = INSTR (p$, parent$)
		IF parent THEN
			IF (parent = 1) THEN
				p$ = MID$ (p$, 4)																	' path starts "/../"  - change to "/"
			ELSE
				slash = RINSTR (p$, $$PathSlash$, parent-1)				' find / before "/../"
				p$ = LEFT$ (p$, slash) + MID$ (p$, parent + 4)		' remove parent directory
			END IF
		END IF
	LOOP WHILE parent
'
' convert multiple path-slashes (//) to single path-slashes (/)
'
	DO
		dslash = INSTR (p$, $$PathSlash$ + $$PathSlash$)
		IF dslash THEN
			p$ = LEFT$(p$, dslash) + MID$(p$, dslash + 2)
		END IF
	LOOP WHILE dslash
'
'	a$ = "<" + path$ + "> <" + p$ + ">\n"
'	write (1, &a$, LEN(a$))
'
	RETURN (p$)
'
'
' *****  Initialize  *****
'
SUB Initialize
	whomask = ##WHOMASK
	##WHOMASK = $$FALSE
'
	DIM charsetFilename[255]
	DIM charsetFilenameFirstLast[255]
'
	FOR i = 0x20 TO 0x7F
		charsetFilename[i] = i
		charsetFilenameFirstLast[i] = i
	NEXT i
'
'	charsetFilename['/'] = charsetFilename['\\']		' windows
	charsetFilename['\\'] = charsetFilename['/']		' unix
	charsetFilename['`'] = 0
	charsetFilename['!'] = 0
	charsetFilename['"'] = 0
	charsetFilename['<'] = 0
	charsetFilename['>'] = 0
'	charsetFilename[':'] = 0
	charsetFilename['|'] = 0
'	charsetFilenameFirstLast['/'] = '\\'	' path separator character (windows)
	charsetFilenameFirstLast['\\'] = '/'	' path separator character (unix)
	charsetFilenameFirstLast[' '] = 0			' no leading/trailing spaces
	charsetFilenameFirstLast['`'] = 0			' no leading/trailing "`"
	charsetFilenameFirstLast['!'] = 0			' no leading/trailing "!"
	charsetFilenameFirstLast['"'] = 0			' no leading/trailing """
	charsetFilenameFirstLast['<'] = 0			' no leading/trailing "<"
	charsetFilenameFirstLast['>'] = 0			' no leading/trailing ">"
'	charsetFilenameFirstLast[':'] = 0			' no leading/trailing ":"
	charsetFilenameFirstLast['|'] = 0			' no leading/trailing "|"
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ######################################
' #####  XstPathToAbsolutePath ()  #####
' ######################################
'
' XstPathToAbsolutePath (ipath$, @opath$)
'
FUNCTION  XstPathToAbsolutePath (ipath$, opath$)
'
	opath$ = ""
	opath$ = XstPathString$ (@ipath$)
'
' if relative path, prepend working directory
'
	IFZ opath$ THEN
		XstGetCurrentDirectory (@opath$)
	ELSE
		IF (opath${0} = '.') THEN
			IF (opath${1} = $$PathSlash) THEN opath$ = MID$(opath$, 3)
		END IF
		IF (opath${0} != $$PathSlash) THEN
			XstGetCurrentDirectory (@dir$)
			opath$ = dir$ + $$PathSlash$ + opath$
		END IF
	END IF
END FUNCTION
'
'
' ##############################
' #####  XstReadString ()  #####
' ##############################
'
' error = XstReadString (ifile, @string$)
'
' The XstReadString function reads a string written
' to a disk file by XstWriteString(). It first reads
' the string length header into a ULONG variable and
' sizes the string variable based on that length.
' If the file length is equal to the length of the
' variable plus the number of bytes of string data,
' it reads string data into the string.
'
' See: XstWriteString()
'
FUNCTION  XstReadString (ifile, string$)
	AUTOX ULONG  bytesRead
	AUTOX ULONG  bytes
	AUTOX ULONG  lof
'
	string$ = ""
	size = SIZE (bytes)
	error = XxxReadFile (ifile, &bytes, size, &bytesRead, 0)
	IF (bytesRead != size) THEN RETURN ($$TRUE)
	IF error THEN RETURN ($$TRUE)
'
' If the length-of-file is not the same as bytes + size
' then it has not been written by XstWriteString()
'
	lof = LOF(ifile)
	IF (lof != (bytes + size)) THEN RETURN ($$TRUE)
'
	IF bytes THEN
		bytesRead = 0
		string$ = NULL$ (bytes)
		error = XxxReadFile (ifile, &string$, bytes, &bytesRead, 0)
		IF (bytesRead != bytes) THEN RETURN ($$TRUE)
		IF error THEN RETURN ($$TRUE)
	END IF
'
	RETURN ($$FALSE)
END FUNCTION
'
'
' ##############################
' #####  XstRenameFile ()  #####
' ##############################
'
' error = XstRenameFile (oldName$, newName$)
'
' The XstRenameFile function will rename (move)
' either a file or a directory (including all
' its children) either in the same directory or
' across directories. The one caveat is that the
' XstRenameFile function will fail on directory moves
' when the destination is on a different volume..
'
FUNCTION  XstRenameFile (o$, n$)
'
	IFZ o$ THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidName : ##WHERE = 31010019
		RETURN ($$TRUE)
	END IF
'
	IFZ n$ THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidName : ##WHERE = 31010024
		RETURN ($$TRUE)
	END IF
'
	old$ = XstPathString$ (@o$)
	new$ = XstPathString$ (@n$)
	IF (old$ = new$) THEN RETURN ($$FALSE)
'
	XstGetFileAttributes (@old$, @attributes)			' Does file exist?
	IFZ attributes THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent : ##WHERE = 31010034
		RETURN ($$TRUE)
	END IF
'
	XstGetFileAttributes (@new$, @attributes)			' Does file exist?
	IF attributes THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureExists : ##WHERE = 31010040
		RETURN ($$TRUE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstRenameFile()lockout", lockout)
'
	##WHOMASK = 0
	##LOCKOUT = 300026
	error = rename (&old$, &new$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstRenameFile():error", error
		##ERROR = error : ##WHERE = 31010057
		RETURN ($$TRUE)
	END IF
END FUNCTION
'
'
' ##############################
' #####  XstSaveString ()  #####
' ##############################
'
' error = XstSaveString (file$, text$)
'
' ##ERROR is set if there is a failure
'
' See: XstLoadString()
'
FUNCTION  XstSaveString (file$, text$)
'
	##ERROR = $$FALSE
	f$ = XstPathString$ (@file$)
	ofile = OPEN (f$, $$WRNEW)
	IF (ofile < 0) THEN RETURN ($$TRUE)		' ##ERROR also set
	IF text$ THEN WRITE [ofile], text$
	CLOSE (ofile)
END FUNCTION
'
'
' ###################################
' #####  XstSaveStringArray ()  #####
' ###################################
'
' error = XstSaveStringArray (file$, @text$[])
'
' ##ERROR is set if there is a failure
'
' See: XstLoadStringArray(), XstSaveStringArrayCRLF()
'
FUNCTION  XstSaveStringArray (file$, text$[])
'
	##ERROR = $$FALSE
	f$ = XstPathString$ (@file$)
'
	ofile = OPEN (f$, $$WRNEW)
	IF (ofile < 0) THEN RETURN ($$TRUE)  ' ##ERROR is also set
	IF text$[] THEN
		XstStringArrayToString (@text$[], @text$)
		IF text$ THEN WRITE [ofile], text$
	END IF
	CLOSE (ofile)
END FUNCTION
'
'
' #######################################
' #####  XstSaveStringArrayCRLF ()  #####
' #######################################
'
' error = XstSaveStringArrayCRLF (file$, @text$[])
'
' ##ERROR is set if there is a failure
'
' It appends CRLF ("\r\n")  to each line in
' the string array before the file is saved.
'
' See: XstLoadStringArray(), XstSaveStringArray()
'
FUNCTION  XstSaveStringArrayCRLF (file$, text$[])
'
	##ERROR = $$FALSE
	f$ = XstPathString$ (@file$)
'
	ofile = OPEN (f$, $$WRNEW)
	IF (ofile < 0) THEN RETURN ($$TRUE)  ' ##ERROR also set
	IF text$[] THEN
		XstStringArrayToStringCRLF (@text$[], @text$)
		IF text$ THEN WRITE [ofile], text$
	END IF
	CLOSE (ofile)
END FUNCTION
'
'
' #######################################
' #####  XstSetCurrentDirectory ()  #####
' #######################################
'
' error = XstSetCurrentDirectory (@directory$)
'
' See: XstChangeDirectory(), XstGetCurrentDirectory()
'
FUNCTION  XstSetCurrentDirectory (newDirectory$)
'
	IFZ newDirectory$ THEN RETURN ($$FALSE)						' No change
	dir$ = XstPathString$ (@newDirectory$)
'
'	XstLog ("XstSetCurrentDirectory().A : " + dir$)
	XstGetCurrentDirectory (@pwd$)
'	XstLog ("XstSetCurrentDirectory().B : " + pwd$)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstSetCurrentDirectory()lockout", lockout)
'
	##WHOMASK = 0
	##LOCKOUT = 300027
	error = chdir (&dir$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	XstGetCurrentDirectory (@cur$)
'	XstLog ("XstSetCurrentDirectory().C : " + dir$ + " : " + STRING$(error) + " : " + STRING$(xb_geterrno))
'	XstLog ("XstSetCurrentDirectory().D : " + pwd$)
'	XstLog ("XstSetCurrentDirectory().E : " + cur$)
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstSetCurrentDirectory():error", error, newDirectory$
		##ERROR = error : ##WHERE = 31050038
		RETURN ($$TRUE)
	END IF
END FUNCTION
'
'
' ########################################
' #####  XstSymboloicPathToPath$ ()  #####
' ########################################
'
' path$ = XstSymbolicPathToPath$ (symbolicPath$)
'
' Converts environmental variables and symbolic links to path.
' Path parts "/../" are not interpreted by this function, but
' when passed through to the Linux system may still give the
' propper result, but not guaranteed.
'
FUNCTION  XstSymbolicPathToPath$ (symbolicPath$)
	STATIC  lkbuffer$
	STATIC  lkbuffersize
	STATIC  lkpath$
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstSymbolicPathToPath$()lockout", lockout)
	whomask = ##WHOMASK
'
	##WHOMASK = 0
	##LOCKOUT = 300028
'
	newpath$ = symbolicPath$
	IFZ lkbuffersize THEN lkbuffersize = 512
	DO
		XstParseStringToStringArray (newpath$, $$PathSlash$, @s$[])
		doAgain = $$FALSE
		FOR i = 0 TO UBOUND (s$[])
			s$ = s$[i]
			IF (LEFT$(s$) == "$") THEN
				sc$ = LCLIP$(s$)
				XstGetEnvironmentVariable (sc$, @s$)
				IF s$ THEN doAgain = $$TRUE
			END IF
			IFZ i THEN
				newpath$ = s$
			ELSE
				newpath$ = newpath$ + $$PathSlash$ + s$
			END IF
			lkbuffer$ = NULL$(lkbuffersize)
			rc = readlink (&newpath$, &lkbuffer$, lkbuffersize)
			IF (rc > 0) THEN
				IF (rc < lkbuffersize) THEN
					lkpath$ = LEFT$(lkbuffer$, rc)
					lkbuffer$ = ""
					IF (LEFT$(lkpath$) == $$PathSlash$) THEN
						newpath$ = lkpath$
					ELSE
						newpath$ = newpath$ + $$PathSlash$ + lkpath$
					END IF
					lkpath$ = ""
				ELSE
					lkbuffersize = rc + 100
					lkbuffer$ = NULL$(lkbuffersize)
					rc = readlink (&newpath$, &lkbuffer$, lkbuffersize)
					IF (rc > 0) THEN
						lkpath$ = LEFT$(lkbuffer$, rc)
						lkbuffer$ = ""
						IF (LEFT$(lkpath$) == $$PathSlash$) THEN
							newpath$ = lkpath$
						ELSE
							newpath$ = newpath$ + $$PathSlash$ + lkpath$
						END IF
						lkpath$ = ""
					END IF
				END IF
			END IF
		NEXT i
	LOOP WHILE doAgain
	##LOCKOUT = lockout
	##WHOMASK = whomask
	path$ = newpath$
	newpath$ = ""
'
RETURN path$
'
END FUNCTION
'
'
' #####################################
' #####  XstUnlockFileSection ()  #####
' #####################################
'
' error = XstUnlockFileSection (fileNumber, 0, offset$$, length$$)
'
' Note: offset$$ and length$$ are 64-bit signed GIANT integers
'
' See: XstLockFileSection()
'
FUNCTION  XstUnlockFileSection (file, mode, offset$$, length$$)
	SHARED  LOCK  fileLock[]
	SHARED  FILE  fileInfo[]
	AUTOX  UFLOCK  flock
	AUTOX  LOCK  lock[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XstLockFileSection()lockout", lockout) : lockout = 0
'
	IF (file <= 2) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalid : ##WHERE = 31070022
		RETURN ($$TRUE)
	END IF
'
	upper = UBOUND (fileInfo[])
	IF (file > upper) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent : ##WHERE = 31070028
		RETURN ($$TRUE)
	END IF
'
	IF (offset$$ < 0) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 31070033
		RETURN ($$TRUE)
	END IF
'
	IF (length$$ < 0) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 31070038
		RETURN ($$TRUE)
	END IF
'
' remove the following two tests when UNIX supports 64-bit file pointers
'
	IF (offset$$ > 0x7FFFFFFF) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 31070045
		RETURN ($$TRUE)
	END IF
'
	IF (length$$ > 0x7FFFFFFF) THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidValue : ##WHERE = 31070050
		RETURN ($$TRUE)
	END IF
'
	sfile = fileInfo[file].fileHandle
'
	IF (sfile <= 0) THEN
		##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureNonexistent : ##WHERE = 31070057
		RETURN ($$TRUE)
	END IF
'
	IFZ fileLock[] THEN
		##WHOMASK = 0
		upper = (file + 16) OR 0x000F
		DIM fileLock[upper,]
		##WHOMASK = whomask
	END IF
'
	upper = UBOUND (fileLock[])
	IF (upper < file) THEN
		##WHOMASK = 0
		upper = (file + 16) OR 0x000F
		REDIM fileLock[upper,]
		##WHOMASK = whomask
	END IF
'
	IFZ fileLock[file,] THEN
		##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument : ##WHERE = 31070077
		RETURN ($$TRUE)
	END IF
'
	slot = -1
	begin$$ = offset$$
	end$$ = offset$$ + length$$ - 1$$
	IFZ length$$ THEN end$$ = 0x7FFFFFFF						' UNIX
'	IFZ length$$ THEN end$$ = 0x7FFFFFFFFFFFFFFF		' Win32
	upper = UBOUND (fileLock[file,])
'
	found = $$FALSE
	FOR i = 0 TO upper
		IF fileLock[file,i].file THEN
			IF fileLock[file,i].sfile THEN
				IF (offset$$ = fileLock[file,i].offset) THEN
					IF (length$$ = fileLock[file,i].length) THEN
						found = $$TRUE
						EXIT FOR
					END IF
				END IF
			END IF
		END IF
	NEXT i
'
' if specified section not found in lock list
'
	IFZ found THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidRequest : ##WHERE = 31070105
		RETURN ($$TRUE)
	END IF
'
' found the specified locked section - unlock it
'
	begin$$ = offset$$
	end$$ = fileLock[file,i].end
	offsetLow = GLOW (begin$$)
	offsetHigh = GHIGH (begin$$)
	lengthLow = GLOW (end$$ - begin$$ + 1)
	lengthHigh = GHIGH (end$$ - begin$$ + 1)
'
' remove the following tests when UNIX supports 64-bit file pointers
'
	error = $$FALSE
	IF offsetHigh THEN error = $$TRUE
	IF lengthHigh THEN error = $$TRUE
	IF (offsetLow < 0) THEN error = $$TRUE
	IF (lengthLow < 0) THEN error = $$TRUE
	IF (offsetLow > 0x7FFFFFFF) THEN error = $$TRUE
	IF (lengthLow > 0x7FFFFFFF) THEN error = $$TRUE
'
	IF error THEN
		##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidRequest : ##WHERE = 31070129
		RETURN ($$TRUE)
	END IF
'
' tell UNIX to unlock the file
'
	flock.l_type = $$F_UNLCK				' unlock the file section
	flock.l_whence = $$SEEK_SET			' offset from start of file
	flock.l_start = offsetLow				' first byte to lock
	flock.l_len = lengthLow					' # of bytes to lock
	flock.l_sysid = 0								' not required for F_SETLK
	flock.l_pid = 0									' not required for F_SETLK
'
	##WHOMASK = 0
	##LOCKOUT = 300029
	error = fcntl (sfile, $$F_SETLK, &flock)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XstUnlockFileSection():error", error
		##ERROR = error : ##WHERE = 31070151
		RETURN ($$TRUE)
	END IF
'
	fileLock[file,i].file = 0
	fileLock[file,i].sfile = 0
	fileLock[file,i].offset = 0
	fileLock[file,i].length = 0
	fileLock[file,i].end = 0
END FUNCTION
'
'
' #####################################
' #####  XstWindowSizePercent ()  #####
' #####################################
'
' XstWindowSizePercent (@xPercent, @yPercent, @wPercent, @hPercent, windowType)
'
' Given displacement and size values as percentages (0 to 100) of the screen
' workarea, this function will return the values in pixels.
'
' If any percent input value is more than 100 or less than zero, return unchanged.
' If all four percent input values are zero, calculate as if they were all 50%
'
' The $$WindowTypeNoFrame bit is checked in the "windowType" field to see
' if the border width and title height should be used in the calculation.
'
FUNCTION  XstWindowSizePercent (@xPercent, @yPercent, @wPercent, @hPercent, windowType)
'
	IF ((xPercent > 100) || (yPercent > 100) || (wPercent > 100) || (hPercent > 100)) THEN RETURN
	IF ((xPercent < 0) || (yPercent < 0) || (wPercent < 0) || (hPercent < 0)) THEN RETURN
'
' If all four percent input values are zero, calculate with default values, 50, 50, 50, 50
'
	IFZ (xPercent || yPercent || wPercent || hPercent) THEN
		xPercent = 50 : yPercent = 50 : wPercent = 50 : hPercent = 50
	END IF
'
	XgrGetWorkArea (@workAreaX, @workAreaY, @workAreaWidth, @workAreaHeight)
	IF (windowType AND $$WindowTypeNoFrame) THEN
		winBordWidth = 0
		winTitleHeight = 0
		frameMinWidth = 1
		frameMinHeight = 1
	ELSE
		XgrGetDisplaySize ("", @disWidth, @disHeight, @winBordWidth, @winTitleHeight)
		frameMinWidth  = $$WindowMinimumWidth  + winBordWidth + winBordWidth
		frameMinHeight = $$WindowMinimumHeight + winBordWidth + winBordWidth + winTitleHeight
	END IF
'
	frameWidth = workAreaWidth * wPercent \ 100
	IF (frameWidth < frameMinWidth) THEN frameWidth = frameMinWidth
	xPercent = ((workAreaWidth - frameWidth) * xPercent \ 100) + winBordWidth + workAreaX
	wPercent = frameWidth - winBordWidth - winBordWidth
'
	frameHeight = workAreaHeight * hPercent \ 100
	IF (frameHeight < frameMinHeight) THEN frameHeight = frameMinHeight
	yPercent = ((workAreaHeight - frameHeight) * yPercent \ 100) + winBordWidth + winTitleHeight + workAreaY
	hPercent =  frameHeight - winBordWidth - winBordWidth - winTitleHeight
'
END FUNCTION
'
'
' ###############################
' #####  XstWriteString ()  #####
' ###############################
'
' XstWriteString (ofile, string$)
'
' The XstWriteString function writes a string to a disk file.
' It first writes a ULONG header variable containing the
' string length, then writes the string data. A string
' written to a file can be read by using XstReadString().
'
' See: XstReadString()
'
FUNCTION  XstWriteString (ofile, @string$)
	AUTOX ULONG  bytesWritten
	AUTOX ULONG  bytes
'
	size = SIZE (bytes)
	bytes = LEN (string$)
	error = XxxWriteFile (ofile, &bytes, size, &bytesWritten, 0)
	IF (bytesWritten != size) THEN RETURN ($$TRUE)
	IF error THEN RETURN ($$TRUE)
'
	IF bytes THEN
		size = bytes
		error = XxxWriteFile (ofile, &string$, size, &bytesWritten, 0)
		IF (bytesWritten != size) THEN RETURN ($$TRUE)
		IF error THEN RETURN ($$TRUE)
	END IF
'
	RETURN ($$FALSE)
END FUNCTION
'
'
' ###############################
' #####  XstIsPrefValid ()  #####
' ###############################
'
' valid = XstIsPrefValid (pfile)
'
' valid = $$TRUE if pfile is valid and not in use
'
FUNCTION  XstIsPrefValid (pfile)
	SHARED prefFile$[]
	SHARED prefInUse[]
	SHARED prefWhomask[]
'
	IFZ prefFile$[] THEN RETURN $$FALSE
	pindex = pfile - 1
	ubound = UBOUND (prefFile$[])
	IF (pindex < 0) || (pindex > ubound) THEN RETURN $$FALSE
	IFF prefInUse[pindex] THEN RETURN $$FALSE
	IFF (prefWhomask[pindex] == ##WHOMASK) THEN RETURN $$FALSE
	RETURN $$TRUE
END FUNCTION
'
'
' ##################################
' #####  XstGetPrefKeyLine ()  #####
' ##################################
'
' found = XstGetPrefKeyLine (pfile, key$, @line, @sectionFound, @keyFound)
'
FUNCTION  XstGetPrefKeyLine (pfile, key$, @line, @sectionFound, @keyFound)
	SHARED prefData$[]
	SHARED prefSection$[]
'
	pindex = pfile - 1
	ubound = UBOUND (prefData$[pindex,])
	sectionFound = $$FALSE
	keyFound = $$FALSE
	IF prefSection$[pindex] THEN
		FOR i = 0 TO ubound
			IF INSTRI (prefData$[pindex, i], prefSection$[pindex]) = 1 THEN
				sectionFound = $$TRUE
				sectionStart = i + 1
				EXIT FOR
			END IF
		NEXT i
		IF sectionFound THEN
			line = -1
			FOR i = sectionStart TO ubound
				IF LEFT$(prefData$[pindex, i], 1) = "[" THEN
					line = i
					EXIT FOR
				END IF
				IF INSTRI (prefData$[pindex, i], key$) = 1 THEN
					line = i
					keyFound = $$TRUE
					EXIT FOR
				END IF
			NEXT i
			IF line < 0 THEN line = ubound + 1
		ELSE
			line = ubound + 1
		END IF
	ELSE ' No section defind
		sectionFound = $$TRUE
		line = -1
		FOR i = 0 TO ubound
			IF LEFT$(prefData$[pindex, i], 1) = "[" THEN
				line = i
				EXIT FOR
			END IF
			IF INSTRI (prefData$[pindex, i], key$) = 1 THEN
				line = i
				keyFound = $$TRUE
				EXIT FOR
			END IF
		NEXT i
		IF line < 0 THEN line = ubound + 1
	END IF
	IF sectionFound && keyFound THEN RETURN $$TRUE
	RETURN $$FALSE
END FUNCTION
'
'
' ###############################
' #####  XstPrefAddLine ()  #####
' ###############################
'
' XstPrefAddLine (pfile, line, text$)
'
FUNCTION  XstPrefAddLine (pfile, line, text$)
	SHARED prefChanged[]
	SHARED prefData$[]
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	pindex = pfile - 1
	ATTACH prefData$[pindex,] TO ini$[]
	ubound = UBOUND (ini$[]) + 1
	REDIM ini$[ubound]
	IF line < 0 THEN line = 0
	IF line >= ubound THEN
		ini$[ubound] = text$
	ELSE
		FOR i = ubound TO line + 1 STEP -1
			ini$[i] = ini$[i - 1]
		NEXT i
		ini$[line] = text$
	END IF
	ATTACH ini$[] TO prefData$[pindex,]
	prefChanged[pindex] = $$TRUE
	##WHOMASK = whomask
	RETURN $$FALSE
END FUNCTION
'
'
' ##################################
' #####  XstPrefDeleteLine ()  #####
' ##################################
'
' XstPrefDeleteLine (pfile, line)
'
FUNCTION  XstPrefDeleteLine (pfile, line)
	SHARED prefChanged[]
	SHARED prefData$[]
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	pindex = pfile - 1
	ATTACH prefData$[pindex,] TO ini$[]
	ubound = UBOUND (ini$[])
	IF line < 0 THEN line = 0
	IF line <= ubound THEN
		FOR i = line TO ubound - 1
			ini$[i] = ini$[i + 1]
		NEXT i
		IF ubound > 0 THEN
			REDIM ini$[ubound - 1]
		ELSE
			DIM ini$[]
		END IF
	END IF
	ATTACH ini$[] TO prefData$[pindex,]
	prefChanged[pindex] = $$TRUE
	##WHOMASK = whomask
	RETURN $$FALSE
END FUNCTION
'
'
' ############################
' #####  XstOpenPref ()  #####
' ############################
'
' pfile = XstOpenPref (file$)
'
' XstOpenPref() creates a data array that is referenced by the
' pfile number section$ names and key$ names.
'
' If the file$ exists, it is copied into the data array.
'
' The Pref data array can be read and modified and saved.
'
' Here is a alphabetical list of the functions that process "Pref" files.
'
'	error = XstClosePref (pfile)
'	error = XstDeletePrefKey (pfile, key$)
'	error = XstDeletePrefSection (pfile, section$)
'	error = XstDiscardPref (pfile)
'	error = XstGetPrefFile (pfile, @file$)
'	error = XstGetPrefSection (pfile, @section$)
'	error = XstGetPrefSTRING (pfile, key$, default$, @value$)
'	error = XstGetPrefXLONG (pfile, key$, default, @value)
'	pfile = XstOpenPref (file$)
'	error = XstSavePref (pfile)
'	error = XstSetPrefSection (pfile, section$)
'	error = XstSetPrefSTRING (pfile, key$, value$)
'	error = XstSetPrefXLONG (pfile, key$, value)
'
' See: demo file apref.x
'
FUNCTION  XstOpenPref (file$)
	SHARED prefFile$[], prefInUse[], prefChanged[], prefData$[]
	SHARED prefSection$[]
	SHARED prefWhomask[]
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	IFZ prefFile$[] THEN GOSUB Init
	ubound = UBOUND (prefFile$[])
	FOR i = 0 TO ubound
		IFF prefInUse[i] THEN
			freeSlot = i
			freeFound = $$TRUE
			EXIT FOR
		END IF
	NEXT i
	IFF freeFound THEN GOSUB AddSlot
	IF freeFound THEN
		prefFile$[freeSlot] = file$
		prefWhomask[freeSlot] = whomask
		prefInUse[freeSlot] = $$TRUE
		prefSection$[freeSlot] = ""
		error = $$TRUE
		IF XstGetFileAttributes (file$, @attributes) THEN
			error = XstLoadStringArray (file$, @ini$[])
		END IF
		lastUsedLine = UBOUND (ini$[])
		DO WHILE lastUsedLine >= 0
			IF TRIM$(ini$[lastUsedLine]) THEN EXIT DO
			DEC lastUsedLine
		LOOP
		IF lastUsedLine >= 0 THEN
			REDIM ini$[lastUsedLine]
		ELSE
			DIM ini$[]
		END IF
		prefChanged[freeSlot] = error
		ATTACH ini$[] TO prefData$[freeSlot,]
	ELSE
		freeSlot = -1
	END IF
	##WHOMASK = whomask
	RETURN freeSlot + 1
'
SUB Init
	DIM prefFile$[3]
	DIM prefInUse[3]
	DIM prefChanged[3]
	DIM prefData$[3,]
	DIM prefSection$[3]
	DIM prefWhomask[3]
END SUB
'
SUB AddSlot
	ubound = UBOUND (prefFile$[])
	freeSlot = ubound + 1
	freeFound = $$TRUE
	ubound = ubound + 4
	REDIM prefFile$[ubound]
	REDIM prefInUse[ubound]
	REDIM prefChanged[ubound]
	REDIM prefData$[ubound,]
	REDIM prefSection$[ubound]
	REDIM prefWhomask[ubound]
END SUB
END FUNCTION
'
'
' ###############################
' #####  XstGetPrefFile ()  #####
' ###############################
'
' error = XstGetPrefFile (pfile, @file$)
'
' Returns the file$ name used when the pfile was opened with XstOpenPref()
' file$ will be blank "" if pfile number is invalid.
'
FUNCTION  XstGetPrefFile (pfile, @file$)
	SHARED prefFile$[]
'
	file$ = ""
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	file$ = prefFile$[pfile-1]
	RETURN 0
END FUNCTION
'
'
' ############################
' #####  XstSavePref ()  #####
' ############################
'
' error = XstSavePref (pfile)
'
' The current pref data is written to the file name used in XstOpenPref().
' error is returned $$TRUE if there is a failure saving the file or if pfile is invalid.
'
FUNCTION  XstSavePref (pfile)
	SHARED prefChanged[]
	SHARED prefData$[]
	SHARED prefFile$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	whomask = ##WHOMASK
	##WHOMASK = 0
	pindex = pfile - 1
	ATTACH prefData$[pindex,] TO ini$[]
	error = XstSaveStringArray (prefFile$[pindex], @ini$[])
	ATTACH ini$[] TO prefData$[pindex,]
	IFZ error THEN
		prefChanged[pindex] = $$FALSE
	END IF
	##WHOMASK = whomask
	RETURN error
END FUNCTION
'
'
' ###############################
' #####  XstDiscardPref ()  #####
' ###############################
'
' error = XstDiscardPref (pfile)
'
' The entire Pref data array is deleted and closed without being saved.
' The file$ used for XstOpenPref() is not overwritten.
'
FUNCTION  XstDiscardPref (pfile)
	SHARED prefData$[]
	SHARED prefFile$[]
	SHARED prefInUse[]
	SHARED prefSection$[]
	SHARED prefWhomask[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	whomask = ##WHOMASK
	##WHOMASK = 0
	pindex = pfile - 1
	ATTACH prefData$[pindex,] TO ini$[]
	DIM ini$[]
	prefFile$[pindex] = ""
	prefWhomask[pindex] = 0
	prefInUse[pindex] = $$FALSE
	prefSection$[pindex] = ""
	##WHOMASK = whomask
	RETURN $$FALSE
END FUNCTION
'
'
' #############################
' #####  XstClosePref ()  #####
' #############################
'
' error = XstClosePref (@pfile)
'
' If changes have been made to pfile,
' it will be saved before it is closed.
'
FUNCTION  XstClosePref (pfile)
	SHARED prefChanged[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	IF prefChanged[pfile-1] THEN error = XstSavePref (pfile)
	IFZ error THEN
		XstDiscardPref (pfile)
	END IF
	RETURN error
END FUNCTION
'
'
' #################################
' #####  XstDeletePrefKey ()  #####
' #################################
'
' error = XstDeletePrefKey (pfile, key$)
'
' Deletes a single key$ within the current selected section$
'
FUNCTION  XstDeletePrefKey (pfile, key$)
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	IF XstGetPrefKeyLine (pfile, key$, @line, @sectionFound, @keyFound) THEN
		XstPrefDeleteLine (pfile, line)
	END IF
	RETURN 0
END FUNCTION
'
'
' #####################################
' #####  XstDeletePrefSection ()  #####
' #####################################
'
' error = XstDeletePrefSection (pfile, section$)
'
' Deletes the pfile section$ and all the keys within that section$
'
FUNCTION  XstDeletePrefSection (pfile, section$)
	SHARED prefChanged[]
	SHARED prefData$[]
	SHARED prefSection$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	pindex = pfile - 1
	whomask = ##WHOMASK
	##WHOMASK = 0
	ATTACH prefData$[pindex,] TO ini$[]
	ubound = UBOUND (ini$[])
	IFZ section$ THEN
		IF ubound >= 0 THEN
			sectionEnd = -1
			FOR i = 0 TO ubound
				IF LEFT$ (ini$[i], 1) = "[" THEN
					sectionEnd = i
					EXIT FOR
				END IF
			NEXT i
			IF sectionEnd THEN
				IF sectionEnd < 0 THEN
					sectionEnd = ubound + 1
					newUbound = -1
				ELSE
					newUbound = ubound - sectionEnd
				END IF
				i2 = 0
				FOR i = sectionEnd TO ubound
					ini$[i2] = ini$[i]
					INC i2
				NEXT i
				IF newUbound >= 0 THEN
					REDIM ini$[newUbound]
				ELSE
					DIM ini$[]
				END IF
				prefChanged[pindex] = $$TRUE
			END IF
		END IF
	ELSE
		section$ = "[" + section$ + "]"
		FOR i = 0 TO ubound
			IF INSTRI (ini$[i], section$) = 1 THEN
				sectionStart = i
				sectionEnd = -1
				FOR i2 = sectionStart + 1 TO ubound
					IF LEFT$(ini$[i2]) = "[" THEN
						sectionEnd = i2
						EXIT FOR
					END IF
				NEXT i2
				IF sectionEnd < 0 THEN sectionEnd = ubound + 1
				newUbound = ubound - (sectionEnd - sectionStart)
'				PRINT "XstDeletePrefSection sectionStart: ";sectionStart;"  sectionEnd: ";sectionEnd
				FOR i2 = sectionEnd TO ubound
					ini$[sectionStart] = ini$[i2]
					INC sectionStart
				NEXT i2
				IF newUbound >= 0 THEN
					REDIM ini$[newUbound]
				ELSE
					DIM ini$[]
				END IF
				IF INSTRI (prefSection$[pindex], section$) = 1 THEN prefSection$[pindex] = ""
				prefChanged[pindex] = $$TRUE
				EXIT FOR
			END IF
		NEXT i
	END IF
	ATTACH ini$[] TO prefData$[pindex,]
	##WHOMASK = whomask
	RETURN 0
END FUNCTION
'
'
' ##################################
' #####  XstSetPrefSection ()  #####
' ##################################
'
' error = XstSetPrefSection (pfile, section$)
'
' Sets the section$ name to be the current active section.
' A blank or empty section$ name is valid.
' The active pref section is used by:
'	    XstGetPrefSTRING ()
'	    XstGetPrefXLONG ()
'	    XstSetPrefSTRING ()
'	    XstSetPrefXLONG ()
'
FUNCTION  XstSetPrefSection (pfile, section$)
	SHARED prefSection$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	whomask = ##WHOMASK
	##WHOMASK = 0
	pindex = pfile - 1
	IF section$ THEN
		prefSection$[pindex] = "[" + section$ + "]"
		IFZ XstGetPrefKeyLine (pfile, "", @line, @sectionFound, @keyFound) THEN
			IFZ sectionFound THEN
				XstPrefAddLine (pfile, line, prefSection$[pindex])
			END IF
		END IF
	ELSE
		prefSection$[pindex] = ""
	END IF
	##WHOMASK = whomask
	RETURN $$FALSE
END FUNCTION
'
'
' ##################################
' #####  XstGetPrefSection ()  #####
' ##################################
'
' error = XstGetPrefSection (pfile, @section$)
'
' Returns the section$ name of the current active section.
' A blank or empty section$ name is valid.
'
FUNCTION  XstGetPrefSection (pfile, @section$)
	SHARED prefSection$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	section$ = prefSection$[pfile-1]
	IF section$ THEN section$ = MID$( section$, 2, LEN(section$) - 2)
	RETURN $$FALSE
END FUNCTION
'
'
' #################################
' #####  XstSetPrefString ()  #####
' #################################
'
' error = XstSetPrefSTRING (pfile, key$, value$)
'
' Replaces the STRING value$ for the key$ name within the current section name of pfile.
' If the key$ name does not exist, it is created and the new value$ is put in that key$.
'
FUNCTION  XstSetPrefSTRING (pfile, key$, value$)
	SHARED prefChanged[]
	SHARED prefData$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	whomask = ##WHOMASK
	##WHOMASK = 0
	IF XstGetPrefKeyLine (pfile, key$, @line, @sectionFound, @keyFound) THEN
		prefData$[pfile-1, line] = key$ + "=" + value$
		prefChanged[pfile-1] = $$TRUE
	ELSE
		XstPrefAddLine (pfile, line, key$ + "=" + value$)
	END IF
'	PRINT "XstSetPrefString line: ";line
	##WHOMASK = whomask
	RETURN $$FALSE
END FUNCTION
'
'
' ################################
' #####  XstSetPrefXLONG ()  #####
' ################################
'
' error = XstSetPrefXLONG (pfile, key$, value)
'
' Replaces the XLONG value for the key$ name within the current section name of pfile.
' If the key$ name does not exist, it is created and the new value is put in that key$.
'
FUNCTION  XstSetPrefXLONG (pfile, key$, value)
	SHARED prefChanged[]
	SHARED prefData$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	whomask = ##WHOMASK
	##WHOMASK = 0
	IF XstGetPrefKeyLine (pfile, key$, @line, @sectionFound, @keyFound) THEN
		prefData$[pfile-1, line] = key$ + "=" + STRING$(value)
		prefChanged[pfile-1] = $$TRUE
	ELSE
		XstPrefAddLine (pfile, line, key$ + "=" + STRING$(value))
	END IF
	##WHOMASK = whomask
	RETURN 0
END FUNCTION
'
'
' #################################
' #####  XstGetPrefString ()  #####
' #################################
'
' error = XstGetPrefSTRING (pfile, key$, default$, @value$)
'
' Returns the STRING value$ for the key$ name within the current section name of pfile.
' If the key$ name does not exist, the STRING in default$ is copied to value$.
'
FUNCTION  XstGetPrefSTRING (pfile, key$, default$, @value$)
	SHARED prefData$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	IF XstGetPrefKeyLine (pfile, key$, @line, @sectionFound, @keyFound) THEN
		IF keyFound THEN
			valPos = INSTR (prefData$[pfile-1, line], "=", LEN(key$) + 1) + 1
			value$ = MID$ (prefData$[pfile-1, line], valPos)
		END IF
	END IF
	IF keyFound THEN
		RETURN 0
	END IF
	value$ = default$
	RETURN -1
END FUNCTION
'
'
' ################################
' #####  XstGetPrefXLONG ()  #####
' ################################
'
' error = XstGetPrefXLONG (pfile, key$, default, @value)
'
' Returns the XLONG value for the key$ name within the current section name of pfile.
' If the key$ name does not exist, the value in default is copied to value.
'
FUNCTION  XstGetPrefXLONG (pfile, key$, default, @value)
	SHARED prefData$[]
'
	IFF XstIsPrefValid (pfile) THEN RETURN -1
	IF XstGetPrefKeyLine (pfile, key$, @line, @sectionFound, @keyFound) THEN
		IF keyFound THEN
			valPos = INSTR (prefData$[pfile-1, line], "=", LEN(key$) + 1) + 1
			value = XLONG (MID$ (prefData$[pfile-1, line], valPos))
		END IF
	END IF
	IF keyFound THEN
		RETURN 0
	END IF
	value = default
	RETURN -1
END FUNCTION
'
'
' #############################
' #####  XstLoadArray ()  #####
' #############################
'
' error = XstLoadArray (file$, @array[])
'
' Read a special XBasic file format into an XBasic array[]
' The file has a header magic ID = "XBAR"
' The array[] must have been written with XstSaveArray()
'
' See: XstSaveArray()
'
FUNCTION  XstLoadArray (file$, array[])
	SAVELOADARRAYHDR hdr
	UBYTE bt
'
	DIM array[]
	ifile = OPEN(file$, $$RD)
	IF ifile < 3 THEN RETURN $$TRUE
	error = XxxReadFile (ifile, &hdr, SIZE(hdr), &bytesRead, 0)
	IF error || (bytesRead != SIZE(hdr)) THEN GOTO fileError
	IF hdr.magic != "XBAR" THEN GOTO fileError
	error = XxxReadFile (ifile, &bt, SIZE(bt), &bytesRead, 0)
	IF error || (bytesRead != SIZE(bt)) THEN GOTO fileError
	chunkType = bt
	error = XstLoadArrayData (ifile, chunkType, @array[])
	IF error THEN GOTO fileError
	error = XxxReadFile (ifile, &bt, SIZE(bt), &bytesRead, 0)
	IF error || (bytesRead != SIZE(bt)) || (bt != $$SaveLoadArrayEOF) THEN GOTO fileError
	GOTO fileOk
'
fileError:
	IFZ error THEN error = $$TRUE
	DIM array[]
fileOk:
	CLOSE(ifile)
	RETURN error
END FUNCTION
'
'
' #################################
' #####  XstLoadArrayData ()  #####
' #################################
'
' This function is used by XstLoadArray()
'
FUNCTION  XstLoadArrayData (ifile, chunk, array[])
	UBYTE bt, tempb[]
'
	SELECT CASE chunk
		CASE $$SaveLoadArrayData: GOSUB loadData
		CASE $$SaveLoadArrayNode: GOSUB loadNode
'		CASE $$SaveLoadArrayEOF:  RETURN $$FALSE
		CASE ELSE: RETURN $$TRUE
	END SELECT
'
	RETURN $$FALSE
'
' *****  loadData  *****
'
SUB loadData
	error = XxxReadFile (ifile, &bt, SIZE(bt), &bytesRead, 0)
	IF error || (bytesRead != SIZE(bt)) THEN RETURN $$TRUE
	type = bt
	IF XstLoadArrayLength (ifile, @elementCount) THEN RETURN $$TRUE
	IF type = $$STRING THEN
		DIM temp$[elementCount - 1]
		FOR i = 0 TO elementCount - 1
			IF XstLoadArrayLength (ifile, @len) THEN RETURN $$TRUE
			temp$[i] = SPACE$(len)
			IF len THEN
				error = XxxReadFile (ifile, &temp$[i], len, &bytesRead, 0)
				IF error || (bytesRead != len) THEN
					RETURN $$TRUE
				END IF
			END IF
		NEXT i
		ATTACH temp$[] TO array[]
	ELSE
		IF XstLoadArrayLength (ifile, @elementSize) THEN RETURN $$TRUE		' get size of one element
		IF (elementSize = 0) || (elementSize > 65535) THEN RETURN $$TRUE
		IF XstLoadArrayLength (ifile, @fileDataSize) THEN RETURN $$TRUE		' get total size of data
		calculatedSize = elementCount * elementSize
		IF calculatedSize != fileDataSize THEN RETURN $$TRUE
		DIM tempb[fileDataSize]
		error = XxxReadFile (ifile, &tempb[], fileDataSize, &bytesRead, 0)
		IF error || (bytesRead != fileDataSize) THEN RETURN $$TRUE
		ATTACH tempb[] TO array[]
		addr = &array[]
		header3 = XLONGAT(addr, -8) AND 0xFF000000
		header3 = header3 OR MAKE(type, 8, 16) OR MAKE(elementSize, 16, 0)
		XLONGAT(addr, -8) = header3				' set real type of array and element size
		XLONGAT(addr, -16) = elementCount	' set real upper bound
	END IF
END SUB
'
' *****  loadNode  *****
'
SUB loadNode
	IF XstLoadArrayLength (ifile, @elementCount) THEN RETURN $$TRUE
	DIM array[elementCount - 1,]
	FOR i = 0 TO elementCount - 1
		error = XxxReadFile (ifile, &bt, SIZE(bt), &bytesRead, 0)
		IF error || (bytesRead != SIZE(bt)) THEN RETURN $$TRUE
		chunkType = bt
		SELECT CASE chunkType
			CASE $$SaveLoadArrayData:
				IF XstLoadArrayData (ifile, chunkType, @temp[]) THEN RETURN $$TRUE
				ATTACH temp[] TO array[i,]
				'
			CASE $$SaveLoadArrayNode:
				IF XstLoadArrayData (ifile, chunkType, @temp[]) THEN RETURN $$TRUE
				ATTACH temp[] TO array[i,]
				'
			CASE $$SaveLoadArraySkip:
				IF XstLoadArrayLength (ifile, @skipCount) THEN RETURN $$TRUE
				IF (i + skipCount) > elementCount THEN RETURN $$TRUE
				i = i + skipCount - 1
				'
			CASE ELSE: RETURN $$TRUE
		END SELECT
	NEXT i
END SUB
END FUNCTION
'
'
' ###################################
' #####  XstLoadArrayLength ()  #####
' ###################################
'
' This function is used by XstLoadArrayData()
'
FUNCTION  XstLoadArrayLength (ifile, length)
	UBYTE lenRd
'
	maxShift = (SIZE(length) * 8) - 1
	length = 0
	shift = 0
	DO
		error = XxxReadFile (ifile, &lenRd, 1, &byteRead, 0)
		IF error || (byteRead != 1) THEN RETURN $$TRUE
		length = length OR ((lenRd AND 127) << shift)
		IF lenRd AND 128 THEN EXIT DO
		shift = shift + 7
		IF shift > maxShift THEN RETURN $$TRUE
	LOOP
	RETURN $$FALSE
END FUNCTION
'
'
' #############################
' #####  XstSaveArray ()  #####
' #############################
'
' error = XstSaveArray (file$, @array[])
'
' Save an XBasic array in a special XBasic file format.
' The file has a header magic ID = "XBAR"
' The array[] can be restored with XstLoadArray()
'
' See: XstLoadArray()
'
FUNCTION  XstSaveArray (file$, array[])
	SAVELOADARRAYHDR hdr
	UBYTE bt
'
	ofile = OPEN (file$, $$WRNEW)
	IF ofile < 3 THEN RETURN $$TRUE
	hdr.magic = "XBAR"
	error = XxxWriteFile (ofile, &hdr, SIZE(hdr), &bytesWriten, 0)
	IF error || (bytesWriten != SIZE(hdr)) THEN GOTO fileError
	error = XstSaveArrayData (ofile, @array[])
	IFZ error THEN
		bt = $$SaveLoadArrayEOF
		error = XxxWriteFile (ofile, &bt, SIZE(bt), &bytesWriten, 0)
		IF error || (bytesWriten != SIZE(bt)) THEN GOTO fileError
	ELSE
		GOTO fileError
	END IF
	GOTO fileOk
'
fileError:
	IFZ error THEN error = $$TRUE
fileOk:
	CLOSE (ofile)
	RETURN error
END FUNCTION
'
'
' #################################
' #####  XstSaveArrayData ()  #####
' #################################
'
' This function is used by XstSaveArray()
'
FUNCTION  XstSaveArrayData (ofile, array[])
	UBYTE bt
'
	upper = UBOUND (array[])
	IF upper < 0 THEN RETURN ($$FALSE)																			' empty array
'
	addr = &array[]
	header02 = XLONGAT(addr, -16)
	header03 = XLONGAT(addr, -8)
	IFZ (header03 AND 0x20000000) THEN																			' lowest dimension
		bt = $$SaveLoadArrayData
		error = XxxWriteFile (ofile, &bt, SIZE(bt), &bytesWriten, 0)					' write chunk type
		IF error || (bytesWriten != SIZE(bt)) THEN RETURN $$TRUE
		type = header03{8,16}																									' get type of array
		bt = type
		error = XxxWriteFile (ofile, &bt, SIZE(bt), &bytesWriten, 0)					' write type
		IF error || (bytesWriten != SIZE(bt)) THEN RETURN $$TRUE
		IF XstSaveArrayLength (ofile, upper + 1) THEN RETURN $$TRUE						' write element count
		IF type == $$STRING THEN																							' if string array
			ATTACH array[] TO array$[]																					' string array
			FOR i = 0 TO upper
				len = LEN(array$[i])
				IF XstSaveArrayLength (ofile, len) THEN														' write string length
					ATTACH array$[] TO array[]
					RETURN $$TRUE
				END IF
				IF len THEN
					error = XxxWriteFile (ofile, &array$[i], len, &bytesWriten, 0)	' write string data
					IF error || (bytesWriten != len) THEN
						ATTACH array$[] TO array[]
						RETURN $$TRUE
					END IF
				END IF
			NEXT i
			ATTACH array$[] TO array[]																					' restore data
		ELSE																																	' no string array
			IF XstSaveArrayLength (ofile, header03{16,0}) THEN RETURN $$TRUE		' write element size
			size = SIZE(array[])
			IF XstSaveArrayLength (ofile, size) THEN RETURN $$TRUE							' write data size
			error = XxxWriteFile (ofile, &array[], size, &bytesWriten, 0)				' write data
			IF error || (bytesWriten != size) THEN RETURN $$TRUE
		END IF
	ELSE																																		' higher dimension (not lowest)
		skipCount = 0
		bt = $$SaveLoadArrayNode
		error = XxxWriteFile (ofile, &bt, SIZE(bt), &bytesWriten, 0)					' write type
		IF error || (bytesWriten != SIZE(bt)) THEN RETURN $$TRUE
		IF XstSaveArrayLength (ofile, upper + 1) THEN RETURN $$TRUE						' write node count
		FOR i = 0 TO upper																										' for all nodes
			IFZ array[i,] THEN
				INC skipCount																											' skip empty nodes
			ELSE
				IF skipCount THEN
					bt = $$SaveLoadArraySkip
					error = XxxWriteFile (ofile, &bt, SIZE(bt), &bytesWriten, 0)
					IF error || (bytesWriten != SIZE(bt)) THEN RETURN $$TRUE
					IF XstSaveArrayLength (ofile, skipCount) THEN RETURN $$TRUE
					skipCount = 0
				END IF
				ATTACH array[i,] TO temp[]																				' get this node
				error = XstSaveArrayData (ofile, @temp[])													' save this array
				ATTACH temp[] TO array[i,]																				' restore array
				IF error THEN RETURN $$TRUE
			END IF
		NEXT i
		IF skipCount THEN
			bt = $$SaveLoadArraySkip
			error = XxxWriteFile (ofile, &bt, SIZE(bt), &bytesWriten, 0)
			IF error || (bytesWriten != SIZE(bt)) THEN RETURN $$TRUE
			IF XstSaveArrayLength (ofile, skipCount) THEN RETURN $$TRUE
			skipCount = 0
		END IF
	END IF
	RETURN ($$FALSE)
END FUNCTION
'
'
' ###################################
' #####  XstSaveArrayLength ()  #####
' ###################################
'
' This function is used by XstSaveArrayData()
'
FUNCTION  XstSaveArrayLength (ofile, length)
	UBYTE lenWrt
'
	DO
		lenWrt = length AND 127
		length = length >> 7
		IFZ length THEN
			lenWrt = lenWrt OR 128
			error = XxxWriteFile (ofile, &lenWrt, 1, &bytesWriten, 0)
			IF error || (bytesWriten != 1) THEN RETURN $$TRUE
			EXIT DO
		END IF
		error = XxxWriteFile (ofile, &lenWrt, 1, &bytesWriten, 0)
		IF error || (bytesWriten != 1) THEN RETURN $$TRUE
	LOOP
	RETURN $$FALSE
END FUNCTION
'
'
' ##########################
' #####  XstRandom ()  #####
' ##########################
'
' ULONG result
' result = XstRandom ()
'
'   The KISS generator, (Keep It Simple Stupid), is
'   designed to combine the two multiply-with-carry
'   generators in MWC with the 3-shift register SHR3 and
'   the congruential generator CONG, using addition and
'   exclusive-or. Period about 2^123.
'   It is one of my favorite generators.
'   George Marsaglia
'
' See: XstRandomCreateSeed(), XstRandomRange(), XstRandomSeed(), XstRandomUniform()
'
FUNCTION  ULONG XstRandom ()
'
	SHARED ULONG seed_kiss1, seed_kiss2, seed_kiss3, seed_kiss4
	GIANT a
	STATIC GIANT jcong_cong
	STATIC ULONG z_mwc, w_mwc, mwc, jsr_shr3
	ULONG z_new, w_new
	STATIC init
'
	$M         = 4294967296						 '2^32
'
	IFZ init THEN GOSUB Initialize
'
	GOSUB Cong
	GOSUB Mwc
	GOSUB Shr3
'
	RETURN ULONG(((mwc ^ jcong_cong) + jsr_shr3) MOD $M)
'
' ***** Cong *****
SUB Cong
	jcong_cong = (69069 * jcong_cong + 1234567) MOD $M
END SUB
'
' ***** Mwc *****
SUB Mwc
	z_mwc = 36969 * (z_mwc & 65535) + (z_mwc >> 16)
	z_new = z_mwc << 16
	w_mwc = 18000 * (w_mwc & 65535) + (w_mwc >> 16)
	w_new = w_mwc & 65535
	mwc =  z_new + w_new
END SUB
'
' ***** Shr3 *****
SUB Shr3
	jsr_shr3 = jsr_shr3 ^ (jsr_shr3 << 17)
	jsr_shr3 = jsr_shr3 ^ (jsr_shr3 >> 13)
	jsr_shr3 = jsr_shr3 ^ (jsr_shr3 << 5)
END SUB
'
' ***** Initialize *****
SUB Initialize
'
	init = $$TRUE
'
	jcong_cong = seed_kiss1
	z_mwc      = seed_kiss2
	w_mwc      = seed_kiss3
	jsr_shr3   = seed_kiss4
'
	SELECT CASE ALL FALSE
		CASE jcong_cong : jcong_cong = XstRandomCreateSeed ()
		CASE z_mwc 			: GOSUB Cong
											z_mwc = jcong_cong
		CASE w_mwc 			: GOSUB Cong
											w_mwc = jcong_cong
		CASE jsr_shr3 	: GOSUB Cong
											jsr_shr3 = jcong_cong
	END SELECT
END SUB
'
END FUNCTION
'
'
' ####################################
' #####  XstRandomCreateSeed ()  #####
' ####################################
'
' ULONG seed
' seed = XstRandomCreateSeed ()
'
'   XstRandomCreateSeed () is used to generate a random ULONG integer seed.
'   Created by Vic Drastik (source: xbrandom.x)
'
' See: XstRandom(), XstRandomRange(), XstRandomSeed(), XstRandomUniform()
'
FUNCTION  ULONG XstRandomCreateSeed ()
'
	XLONG year, month, day, hour, minute, second, nsec
	GIANT centis
'
	$M         = 4294967296						 '2^32
'
' get the current time in centiseconds since year 0
'
	XstGetDateAndTime (@year, @month, @day, @weekDay, @hour, @minute, @second, @nsec)
	centis = (nsec\10000000)+100*(second+60*(minute+60*(hour+24*(day+31*(month+12*GIANT(year))))))
'
	RETURN ULONG(1 + ULONG(centis MOD $M-1))
'
END FUNCTION
'
'
' ##############################
' #####  XstRandomRange () #####
' ##############################
'
' result = XstRandomRange (n1, n2)
'
'   result is random XLONG number in range n1 to n2 inclusive.
'   note: n2 - n1 must be LESS than 4,294,967,295
'
' See: XstRandom(), XstRandomCreateSeed(), XstRandomSeed(), XstRandomUniform()
'
FUNCTION  XstRandomRange (n1, n2)
	IF n1 = n2 THEN RETURN n1
	IF n1 > n2 THEN SWAP n1, n2
	RETURN n1 + (XstRandom() MOD ULONG(n2 - n1 + 1))
END FUNCTION
'
'
' ##############################
' #####  XstRandomSeed ()  #####
' ##############################
'
' ULONG seed
' XstRandomSeed (ULONG seed)
'
'   Provide seed(s) for XstRandom function.
'   If seed is zero, then a seed is created using
'   XstRandomCreateSeed and it's value is returned.
'
' See: XstRandom(), XstRandomCreateSeed(), XstRandomRange(), XstRandomUniform()
'
FUNCTION  XstRandomSeed (ULONG seed)
'
	SHARED ULONG seed_kiss1, seed_kiss2, seed_kiss3, seed_kiss4
	STATIC GIANT jcong_cong
'
	$M         = 4294967296						 '2^32
'
	seed_kiss1 = seed
	jcong_cong = seed_kiss1
'
	SELECT CASE ALL FALSE
		CASE seed_kiss1 : seed_kiss1 = XstRandomCreateSeed ()
											seed = seed_kiss1
											jcong_cong = seed_kiss1
		CASE seed_kiss2 : GOSUB Cong
											seed_kiss2 = jcong_cong
		CASE seed_kiss3 : GOSUB Cong
											seed_kiss3 = jcong_cong
		CASE seed_kiss4 : GOSUB Cong
											seed_kiss4 = jcong_cong
	END SELECT
	RETURN
'
' ***** Cong *****
SUB Cong
	jcong_cong = (69069 * jcong_cong + 1234567) MOD $M
END SUB
'
END FUNCTION
'
'
' #################################
' #####  XstRandomUniform ()  #####
' #################################
'
' DOUBLE number
' number = XstRandomUniform ()
'
'   XstRandomUniform returns a uniform random number, 0 < rn < 1.
'
' See: XstRandom(), XstRandomCreateSeed(), XstRandomRange(), XstRandomSeed()
'
FUNCTION  DOUBLE XstRandomUniform ()
'
	$UNIDIV = 0d3DF0000000100000				'1/(2^32-1)
	RETURN XstRandom() * $UNIDIV
END FUNCTION
'
' #######################################
' #####  XstBackArrayToBinArray ()  #####
' #######################################
'
' XstBackArrayToBinArray (@back$[], @bin$[])
'
' Make a duplicate of back$[] in bin$[] with all backslash characters
' converted into their binary equivalents.  For example,
' every occurance of two character sequence "\t" in back$[]
' into a single 0x09 "tab" character in bin$[].
'
' See: XstBinArrayToBackArray()
'
FUNCTION  XstBackArrayToBinArray (backArray$[], binArray$[])
'
	upper = UBOUND (backArray$[])
	IF (UBOUND (binArray$[]) != upper) THEN
		REDIM binArray$[upper]
	END IF
	FOR i = 0 TO upper
		binArray$[i] = XstBackStringToBinString$ (backArray$[i])
	NEXT i
'
END FUNCTION
'
'
' ##########################################
' #####  XstBackStringToBinString$ ()  #####
' ##########################################
'
' bin$ = XstBackStringToBinString$ (@back$)
'
' Convert string with XBasic backslash characters into a string with
' appropriate unprintable binary bytes (0x00 - 0x1F and 0x80 - 0xFF).
'
' NOTE:  \" becomes 0x22
' NOTE:  \\ becomes 0x5C
' NOTE:  \a \b \t \n \v \f \r become 0x07 0x08 0x09 0x0A 0x0B 0x0C 0x0D
' NOTE:  \0 - \9 become 0x00 - 0x09  (Decimal)
' NOTE:  \A - \F become 0x0A - 0x0F  (Hex extension)  (note: upper case only)
' NOTE:  \G - \V become 0x10 - 0x1F  (Vex extension)  (note: upper case only)
' NOTE:  \Z becomes 0xFF
' NOTE:  This function will process \xHH (hexidecimal) format.
' NOTE:  This function will not process \oOOO (octal) format.
'
FUNCTION  XstBackStringToBinString$ (rawString$)
	SHARED UBYTE  charsetBackslash[]
	SHARED UBYTE  charsetHexLowerToUpper[]
'
	IFZ charsetBackslash[] THEN InitProgram ()
	IFZ rawString$ THEN RETURN ("")
	IFZ (INSTR(rawString$, "\\")) THEN RETURN (rawString$)
'
	lenRawString = LEN (rawString$)
	newString$ = NULL$ (lenRawString)							' length of newString <= rawString
	lastChar = lenRawString - 1
	j = 0
	FOR i = 0 TO lastChar
		rawChar = rawString${i}
		IF (rawChar = '\\') THEN										' backslash character
			IF (i = lastChar) THEN GOTO LastCharacter	' \ is last character
			INC i
			rawChar = rawString${i}
			SELECT CASE rawChar
			CASE 'x'																	' \xHH form
				IF (i = lastChar) THEN EXIT SELECT			' \x -> x
				INC i
				rawHex1 = rawString${i}
				theHex1 = charsetHexLowerToUpper[rawHex1]
				IF theHex1 THEN													' \xHH  (1st H is valid hex)
					IF (i = lastChar) THEN
						rawChar = XLONG ("0x0" + CHR$(theHex1))
						EXIT SELECT
					END IF
					INC i
					rawHex2 = rawString${i}
					theHex2 = charsetHexLowerToUpper[rawHex2]
					IF theHex2 THEN												' \xHH  (2nd H is valid hex)
						rawChar = XLONG ("0x" + CHR$(theHex1) + CHR$(theHex2))
					ELSE																	' \xHH  (2nd H is invalid hex)
						DEC i
						rawChar = XLONG ("0x0" + CHR$(theHex1))
					END IF
				ELSE																		' \xHH  (1st H is invalid hex)
					DEC i
				END IF
			CASE ELSE																	' \something besides \xHH form
				rawChar = charsetBackslash[rawChar]			' \\   \"   \etc   handled here
			END SELECT
		END IF																			' end of \backslash forms
		newString${j} = rawChar
		INC j
	NEXT i
	RETURN (LEFT$ (newString$, j))
'
LastCharacter:
	newString${j} = rawChar
	INC j
	RETURN (LEFT$ (newString$, j))
END FUNCTION
'
'
' #######################################
' #####  XstBinArrayToBackArray ()  #####
' #######################################
'
' XstBinArrayToBackArray (@bin$[], @back$[])
'
' Make a duplicate of bin$[] in back$[] with all 0x00-0x1F and 0x80-0xFF
' characters converted to backslash character equivalents.
' For example, convert every one byte 0x09 "tab" character in bin$[]
' to the two character backslash character sequence "\t" in back$[].
'
' See: XstBackArrayToBinArray()
'
FUNCTION  XstBinArrayToBackArray (binArray$[], backArray$[])
'
	upper = UBOUND (binArray$[])
	IF (UBOUND (backArray$[]) != upper) THEN
		REDIM backArray$[upper]
	END IF
	FOR i = 0 TO upper
		backArray$[i] = XstBinStringToBackString$ (binArray$[i])
	NEXT i
'
END FUNCTION
'
'
' ##########################################
' #####  XstBinStringToBackString$ ()  #####
' ##########################################
'
' back$ = XstBinStringToBackString$ (bin$)
'
' Convert string with unprintable bytes (0x00 - 0x1F and 0x80 - 0xFF)
' into a string with all unprintable bytes converted into C compatible
' backslash sequences that should be interpretable by C compilers and
' a majority of assemblers that accept C style literal strings.
'
' NOTE:  0x22 converted to \"
' NOTE:  0x5C converted to \\
' NOTE:  0x00 - 0x06 converted to \xHH form
' NOTE:  0x07 - 0x0D converted to \a  \b  \t  \n  \v  \f  \r
' NOTE:  0x0E - 0x1F converted to \xHH form
' NOTE:  0x7F - 0xFF converted to \xHH form
'
'	NOTE:  newlines are also converted
'
FUNCTION  XstBinStringToBackString$ (rawString$)
	SHARED UBYTE  charsetNormalChar[]
	SHARED UBYTE  charsetBackslashChar[]
'
	IFZ charsetNormalChar[] THEN InitProgram ()
	IFZ rawString$ THEN RETURN ("")
'
	lenRawString = LEN (rawString$)
	lastRawChar = lenRawString - 1
	lastNewChar = lenRawString + 256
	newString$ = NULL$ (lastNewChar)		' newString may be longer than raw
	DEC lastNewChar
	j = 0
'
	FOR i = 0 TO lastRawChar
		rawChar = rawString${i}
		rawByte = charsetNormalChar[rawChar]
		SELECT CASE TRUE
			CASE rawByte		: newByte = rawByte
												GOSUB AddNewByte
			CASE ELSE				: GOSUB Backslash
		END SELECT
	NEXT i
	RETURN (LEFT$ (newString$, j))
'
'
' *****  Backslash  *****
'
SUB Backslash
	rawByte = charsetBackslashChar[rawChar]
	IF rawByte THEN
		newByte = '\\'														' \? format
		GOSUB AddNewByte
		newByte = rawByte
		GOSUB AddNewByte
	ELSE
		newByte = '\\'														' \xHH format
		GOSUB AddNewByte
		newByte = 'x'
		GOSUB AddNewByte
		HH$ = HEX$(rawChar, 2)
		newByte = HH${0}
		GOSUB AddNewByte
		newByte = HH${1}
		GOSUB AddNewByte
	END IF
END SUB
'
'
' *****  AddNewByte  *****
'
SUB AddNewByte
	newString${j} = newByte
	INC j
	IF (j > lastNewChar) THEN
		newString$ = newString$ + NULL$ (256)
		lastNewChar = lastNewChar + 256
	END IF
END SUB
END FUNCTION
'
'
' ############################################
' #####  XstBinStringToBackStringNL$ ()  #####
' ############################################
'
' backNL$ = XstBinStringToBackStringNL (@bin$)
'
'	Like XstBinStringToBackString$() except do not
'	convert newlines (don't convert 10 to \n).
'
FUNCTION  XstBinStringToBackStringNL$ (rawString$)
	SHARED UBYTE  charsetNormalChar[]
	SHARED UBYTE  charsetBackslashChar[]
'
	IFZ charsetNormalChar[] THEN InitProgram ()
	IFZ rawString$ THEN RETURN ("")
'
	lenRawString = LEN (rawString$)
	lastRawChar = lenRawString - 1
	lastNewChar = lenRawString + 256
	newString$ = NULL$ (lastNewChar)					' newString may be longer than raw
	DEC lastNewChar
	j = 0
'
	FOR i = 0 TO lastRawChar
		rawChar = rawString${i}
		rawByte = charsetNormalChar[rawChar]
		SELECT CASE TRUE
			CASE rawByte				: newByte = rawByte
														GOSUB AddNewByte
			CASE (rawChar = 10)	: newByte = rawChar
														GOSUB AddNewByte
			CASE ELSE						: GOSUB Backslash
		END SELECT
	NEXT i
	RETURN (LEFT$ (newString$, j))
'
'
' *****  Backslash  *****
'
SUB Backslash
	rawByte = charsetBackslashChar[rawChar]
	IF rawByte THEN
		newByte = '\\'														' \? format
		GOSUB AddNewByte
		newByte = rawByte
		GOSUB AddNewByte
	ELSE
		newByte = '\\'														' \xHH format
		GOSUB AddNewByte
		newByte = 'x'
		GOSUB AddNewByte
		HH$ = HEX$(rawChar, 2)
		newByte = HH${0}
		GOSUB AddNewByte
		newByte = HH${1}
		GOSUB AddNewByte
	END IF
END SUB
'
'
' *****  AddNewByte  *****
'
SUB AddNewByte
	newString${j} = newByte
	INC j
	IF (j > lastNewChar) THEN
		newString$ = newString$ + NULL$ (256)
		lastNewChar = lastNewChar + 256
	END IF
END SUB
END FUNCTION
'
'
' ###############################################
' #####  XstBinStringToBackStringThese$ ()  #####
' ###############################################
'
' back$ = XstBinStringToBackStringThese$ (bin$, @these[])
'
FUNCTION  XstBinStringToBackStringThese$ (rawString$, these[])
	SHARED  UBYTE  charsetNormalChar[]
	SHARED  UBYTE  charsetBackslashChar[]
'
	IFZ charsetNormalChar[] THEN InitProgram ()
	IFZ rawString$ THEN RETURN ("")
'
	uthese = UBOUND (these[])
	lenRawString = LEN (rawString$)
	lastRawChar = lenRawString - 1
	lastNewChar = lenRawString + 256
	newString$ = NULL$ (lastNewChar)		' newString may be longer than raw
	DEC lastNewChar
	j = 0
'
	FOR i = 0 TO lastRawChar
		convert = $$FALSE
		rawChar = rawString${i}
		rawByte = charsetNormalChar[rawChar]
		IF (rawByte == 0) THEN convert = $$TRUE
		IF (rawChar <= uthese) THEN convert = these[rawChar]
		SELECT CASE TRUE
			CASE convert		: GOSUB Backslash
			CASE ELSE				: newByte = rawChar
												GOSUB AddNewByte
		END SELECT
	NEXT i
	RETURN (LEFT$(newString$,j))
'
'
' *****  Backslash  *****
'
SUB Backslash
	rawByte = charsetBackslashChar[rawChar]
	IF rawByte THEN
		newByte = '\\'														' \? format
		GOSUB AddNewByte
		newByte = rawByte
		GOSUB AddNewByte
	ELSE
		newByte = '\\'														' \xHH format
		GOSUB AddNewByte
		newByte = 'x'
		GOSUB AddNewByte
		HH$ = HEX$(rawChar, 2)
		newByte = HH${0}
		GOSUB AddNewByte
		newByte = HH${1}
		GOSUB AddNewByte
	END IF
END SUB
'
'
' *****  AddNewByte  *****
'
SUB AddNewByte
	newString${j} = newByte
	INC j
	IF (j > lastNewChar) THEN
		newString$ = newString$ + NULL$ (256)
		lastNewChar = lastNewChar + 256
	END IF
END SUB
END FUNCTION
'
'
' ################################
' #####  XstCompareArray ()  #####
' ################################
'
' result = 0
' error = XstCompareArray (@array1[], @array2[], @result)
'
' result should be set to zero, (0), before calling XstCompareArray().
'
'	If error = $$CompareArrayEqual, result = 0 indicating the arrays are equal.
'	If error = $$CompareArrayNotEqual, result will be the number of mismatches.
'
'	If error = $$CompareArrayNotSameSize, $$CompareArrayNotSameType, or
'	$$CompareArrayNotSameNode, result will be the number of mismatches
' found be fore the error was encountered.
'
FUNCTION  XstCompareArray (array1[], array2[], result)
	STRING temp1$[], temp2$[]
'
	error = 0
	type1 = TYPE(array1[])
	type2 = TYPE(array2[])
'	PRINT "XstCompareArray types: ";type1,type2
	upper1 = UBOUND(array1[])
	upper2 = UBOUND(array2[])
'	PRINT "XstCompareArray uppers : ";upper1,upper2
	IF (upper1 < 0) && (upper2 < 0) THEN RETURN 0									' Empty array
	IF upper1 != upper2 THEN RETURN $$CompareArrayNotSameSize			' Not same size
	a1addr = &array1[]
	a2addr = &array2[]
	a1header03 = XLONGAT(a1addr, -8)
	a2header03 = XLONGAT(a2addr, -8)
	IF (a1header03 ^ a2header03) & 0x20000000 THEN RETURN $$CompareArrayNotSameNode	' Not same node type
	IFZ (a1header03 & 0x20000000) THEN
		IF type1 != type2 THEN RETURN $$CompareArrayNotSameType				' Not the same type
		IF type1 = $$STRING THEN
			ATTACH array1[] TO temp1$[]
			ATTACH array2[] TO temp2$[]
			FOR i = 0 TO upper1
				IF temp1$[i] != temp2$[i] THEN INC result
			NEXT i
			ATTACH temp1$[] TO array1[]
			ATTACH temp2$[] TO array2[]
		ELSE
'			PRINT "XstCompareArray sizes: ";SIZE(array1[]), SIZE(array2[])
			dataSize = a1header03{16,0}
			SELECT CASE dataSize
				CASE 1
					FOR i = 0 TO upper1
						IF UBYTEAT(a1addr, [i]) != UBYTEAT(a2addr, [i]) THEN INC result
					NEXT i
'
				CASE 2
					FOR i = 0 TO upper1
						IF USHORTAT(a1addr, [i]) != USHORTAT(a2addr, [i]) THEN INC result
					NEXT i
'
				CASE 4
					FOR i = 0 TO upper1
						IF ULONGAT(a1addr, [i]) != ULONGAT(a2addr, [i]) THEN INC result
					NEXT i
'
				CASE 8
					FOR i = 0 TO upper1
						IF GIANTAT(a1addr, [i]) != GIANTAT(a2addr, [i]) THEN INC result
					NEXT i
'
				CASE ELSE
					FOR i = 0 TO upper1
						addr1 = a1addr + dataSize * i
						addr2 = a2addr + dataSize * i
						FOR i2 = 0 TO dataSize - 1
							IF UBYTEAT(addr1, [i2]) != UBYTEAT(addr2, [i2]) THEN
								INC result
								EXIT FOR
							END IF
						NEXT i2
					NEXT i
			END SELECT
		END IF
	ELSE
		upper1 = UBOUND(array1[])
		upper2 = UBOUND(array2[])
		IF upper1 != upper2 THEN RETURN $$CompareArrayNotSameSize
		FOR i = 0 TO upper1
			upper1b = UBOUND(array1[])
			upper2b = UBOUND(array2[])
			IF upper1b != upper2b THEN RETURN $$CompareArrayNotSameSize
			IF upper1b >= 0 THEN
				ATTACH array1[i,] TO temp1[]
				ATTACH array2[i,] TO temp2[]
				error = XstCompareArray (@temp1[], @temp2[], @result)
				ATTACH temp1[] TO array1[i,]
				ATTACH temp2[] TO array2[i,]
				IF error && (error != $$CompareArrayNotEqual) THEN RETURN error
			END IF
		NEXT i
	END IF
	IF error THEN RETURN error
	IF result THEN RETURN $$CompareArrayNotEqual
	RETURN $$CompareArrayEqual
END FUNCTION
'
'
' #############################
' #####  XstCopyArray ()  #####
' #############################
'
' XstCopyArray (@array[], @copy[])
'
' Return a copy of simple numeric type or string array[] in copy[].
' XstCopyArray() cannot copy composite arrays, which includes SCOMPLEX
' and DCOMPLEX arrays, as well as all user-defined and composite type
' arrays.  Make sure copy[] is the same type as array[].
'
FUNCTION  XstCopyArray (sss[], ddd[])
	UBYTE  temp[]
'
	DIM ddd[]																			' empty copy = default
	IFZ sss[] THEN RETURN ($$FALSE)								' empty source and copy
'
	saddr = &sss[]																' address of source array
	header02 = XLONGAT (saddr, -16)								' source header word 2
	header03 = XLONGAT (saddr, -8)								' source header word 3
'
	IFZ (header03 AND 0x20000000) THEN						' lowest dimension
		IF (TYPE(sss[]) == $$STRING) THEN						' if string array
			ATTACH sss[] TO sss$[]										' string array
			upper = UBOUND (sss$[])										' upper bound
			DIM ddd$[upper]														' copy array
			FOR i = 0 TO upper												'
				ddd$[i] = sss$[i]												' copy data
			NEXT i																		'
			ATTACH sss$[] TO sss[]										' store copy
			ATTACH ddd$[] TO ddd[]										' replace source
		ELSE																				'
			bytes = SIZE (sss[])											' bytes in source
			DIM temp[bytes-1]													' temporary array
			daddr = &temp[]																' destination address
			XstCopyMemory (saddr-16, daddr-16, bytes+16)	' copy the data
			ATTACH temp[] TO ddd[]												' store copy
		END IF
	ELSE																					' higher dimension (not lowest)
		upper = UBOUND (sss[])											' upper bound of this dimension
		DIM ddd[upper,]															' dimension array of nodes
		FOR i = 0 TO upper													' for all nodes
			ATTACH sss[i,] TO ttt0[]									' get this node
			XstCopyArray (@ttt0[], @ttt1[])						' copy this array
			ATTACH ttt0[] TO sss[i,]									' replace source
			ATTACH ttt1[] TO ddd[i,]									' store copy
		NEXT i
	END IF
	RETURN ($$FALSE)
END FUNCTION
'
'
' ##############################
' #####  XstCopyMemory ()  #####
' ##############################
'
' XstCopyMemory (saddress, daddress, copybytes)
'
' Copy the number of bytes in copybytes,
' from the source starting address saddress
' to the destination starting address daddress.
' The source and destination memory areas can overlap.
'
FUNCTION  XstCopyMemory (saddress, daddress, copybytes)
'
	IF (copybytes <= 0) THEN RETURN ($$TRUE)
	IFZ daddress THEN RETURN ($$TRUE)
	IFZ saddress THEN RETURN ($$TRUE)
'
	daddr = daddress
	saddr = saddress
	bytes = copybytes
'
	dpast = daddr + bytes
	spast = saddr + bytes
'
' memory blocks that overlap must be copied from the proper end
'
	direction = +1
	IF (saddr < daddr) THEN
		IF (daddr < spast) THEN
			direction = -1
		END IF
	END IF
'
	align = daddr OR saddr
'
	IF (direction = -1) THEN
		SELECT CASE FALSE
			CASE (align AND 0x0007)		: size = 8 : step = -8	: GOSUB Down8
			CASE (align AND 0x0003)		: size = 4 : step = -4	: GOSUB Down4
			CASE (align AND 0x0001)		: size = 2 : step = -2	: GOSUB Down2
			CASE ELSE									: size = 1 : step = -1	: GOSUB Down1
		END SELECT
	ELSE
		SELECT CASE FALSE
			CASE (align AND 0x0007)		: size = 8 : step = +8	: GOSUB Up8
			CASE (align AND 0x0003)		: size = 4 : step = +4	: GOSUB Up4
			CASE (align AND 0x0001)		: size = 2 : step = +2	: GOSUB Up2
			CASE ELSE									: size = 1 : step = +1	: GOSUB Up1
		END SELECT
	END IF
'
	RETURN
'
'
' *****  Down8  *****
'
SUB Down8
	mod = bytes AND 0x0007
	count = bytes >> 3
'
	IF mod THEN
		daddr = dpast - 1
		saddr = spast - 1
		DO
			UBYTEAT (daddr) = UBYTEAT (saddr)
			DEC daddr
			DEC saddr
			DEC bytes
			DEC mod
		LOOP WHILE mod
	END IF
'
	IF count THEN
		FOR i = 0 TO count-1
			XLONGAT (daddr) = XLONGAT (saddr)
			daddr = daddr - 8
			saddr = saddr - 8
			bytes = bytes - 8
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Down8 : error : (final bytes != 0) : "; bytes
END SUB
'
'
' *****  Down4  *****
'
SUB Down4
	mod = bytes AND 0x0003
	count = bytes >> 2
'
	IF mod THEN
		daddr = dpast - 1
		saddr = spast - 1
		DO
			UBYTEAT (daddr) = UBYTEAT (saddr)
			DEC daddr
			DEC saddr
			DEC bytes
			DEC mod
		LOOP WHILE mod
	END IF
'
	IF count THEN
		FOR i = 0 TO count-1
			ULONGAT (daddr) = ULONGAT (saddr)
			daddr = daddr - 4
			saddr = saddr - 4
			bytes = bytes - 4
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Down4 : error : (final bytes != 0) : "; bytes
END SUB
'
'
' *****  Down2  *****
'
SUB Down2
	mod = bytes AND 0x0001
	count = bytes >> 1
'
	IF mod THEN
		daddr = dpast - 1
		saddr = spast - 1
		DO
			UBYTEAT (daddr) = UBYTEAT (saddr)
			DEC daddr
			DEC saddr
			DEC bytes
			DEC mod
		LOOP WHILE mod
	END IF
'
	IF count THEN
		FOR i = 0 TO count-1
			USHORTAT (daddr) = USHORTAT (saddr)
			daddr = daddr - 2
			saddr = saddr - 2
			bytes = bytes - 2
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Down2 : error : (final bytes != 0) : "; bytes
END SUB
'
'
' *****  Down1  *****
'
SUB Down1
	IF bytes THEN
		FOR i = 0 TO bytes-1
			UBYTEAT (daddr) = UBYTEAT (saddr)
			DEC daddr
			DEC saddr
			DEC bytes
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Down1 : error : (final bytes != 0) : "; bytes
END SUB
'
'
' *****  Up8  *****
'
SUB Up8
	mod = bytes AND 0x0007
	count = bytes >> 3
'
	IF count THEN
		FOR i = 0 TO count-1
			XLONGAT (daddr) = XLONGAT (saddr)
			daddr = daddr + 8
			saddr = saddr + 8
			bytes = bytes - 8
		NEXT i
	END IF
'
	IF bytes THEN
		FOR i = 0 TO bytes-1
			UBYTEAT (daddr) = UBYTEAT (saddr)
			INC daddr
			INC saddr
			DEC bytes
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Up8 : error : (final bytes != 0) : "; bytes
END SUB
'
'
' *****  Up4  *****
'
SUB Up4
	mod = bytes AND 0x0003
	count = bytes >> 2
'
	IF count THEN
		FOR i = 0 TO count-1
			ULONGAT (daddr) = ULONGAT (saddr)
			daddr = daddr + 4
			saddr = saddr + 4
			bytes = bytes - 4
		NEXT i
	END IF
'
	IF bytes THEN
		FOR i = 0 TO bytes-1
			UBYTEAT (daddr) = UBYTEAT (saddr)
			INC daddr
			INC saddr
			DEC bytes
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Up4 : error : (final bytes != 0) : "; bytes
END SUB
'
'
' *****  Up2  *****
'
SUB Up2
	mod = bytes AND 0x0001
	count = bytes >> 1
'
	IF count THEN
		FOR i = 0 TO count-1
			USHORTAT (daddr) = USHORTAT (saddr)
			daddr = daddr + 2
			saddr = saddr + 2
			bytes = bytes - 2
		NEXT i
	END IF
'
	IF bytes THEN
		FOR i = 0 TO bytes-1
			UBYTEAT (daddr) = UBYTEAT (saddr)
			INC daddr
			INC saddr
			DEC bytes
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Up2 : error : (final bytes != 0) : "; bytes
END SUB
'
'
' *****  Up1  *****
'
SUB Up1
	IF bytes THEN
		FOR i = 0 TO bytes-1
			UBYTEAT (daddr) = UBYTEAT (saddr)
			INC daddr
			INC saddr
			DEC bytes
		NEXT i
	END IF
'
	IF bytes THEN PRINT "XstCopyBytes() : Up1 : error : (final bytes != 0) : "; bytes
END SUB
END FUNCTION
'
'
' ###############################
' #####  XstDeleteLines ()  #####
' ###############################
'
' error = XstDeleteLines (@text$[], first, count)
'
' Delete count lines from string array text$[] starting at line first.
'
' See: XstReplaceLines()
'
FUNCTION  XstDeleteLines (array$[], start, count)
'
	IFZ array$[] THEN RETURN $$TRUE
	IF (count < 1) THEN RETURN $$TRUE
	IF (start < 0) THEN RETURN $$TRUE
	upper = UBOUND(array$[])
	IF (start > upper) THEN RETURN $$TRUE
'
	IF (start + count) > upper THEN
		count = upper - start + 1
		REDIM array$[start-1]
		RETURN
	END IF
	delta = count - 1
'
	FOR i = start TO (start + delta)
		array$[i] = ""
	NEXT i
'
	FOR i = start TO (upper - count)
		ATTACH array$[i+count] TO array$[i]
	NEXT i
'
	upper = upper - count
	REDIM array$[upper]
'
END FUNCTION
'
'
' #############################
' #####  XstFindArray ()  #####
' #############################
'
' XstFindArray (mode, @text$[], @find$, @line, @pos, @match)
'
' XstFindArray() looks for a find$ string within text array text$[] starting at
' line, pos.  text$[0] is line 0 and the first character on each line is pos 0.
'
' If mode is $$FindReverse then pos=-1 means search from last character of line.
'
' If an XstFindArray() finds an occurance of find$ in text$[] given the
' instructions in the mode argument, match is assigned a non-zero value
' and line, pos are assigned the line and character position of the
' first character of the string in text$[] that matched find$.
'
' XstFindArray() does not alter text$[] or find$.
'
' mode=0 tells XstFindArray() to do a forward, case-sensitive find.
' To control the find, OR together mode constants from xst.dec :
'
'  $$FindForward
'  $$FindReverse
'  $$FindDirection
'  $$FindCaseSensitive
'  $$FindCaseInsensitive
'  $$FindCaseSensitivity
'  $$FindWordSensitive
'  $$FindWordInsensitive
'  $$FindWordSensitivity
'
FUNCTION  XstFindArray (mode, text$[], find$, line, pos, match)
	SHARED  UBYTE  charsetWithinWord[]
	AUTO  firstLine$,  lenFirstLine
'
	IFZ charsetWithinWord[] THEN InitProgram()
	IFZ text$[] THEN RETURN
	IFZ find$ THEN RETURN
'
	match = 0															' match = $$FALSE
	mode = mode AND 0x7										' isolate mode field
	uText = UBOUND(text$[])								' lines of text to check
'
	IF ((mode AND $$FindCaseSensitivity) = $$FindCaseSensitive) THEN findCase = $$TRUE
	IF ((mode AND $$FindWordSensitivity) == $$FindWordSensitive) THEN findWord = $$TRUE
'
	IF ((mode AND $$FindDirection) = $$FindForward) THEN
		IF (line < 0) THEN line = -1 : pos = -1 : RETURN
		IF (line > uText) THEN RETURN
		IF (pos < 0) THEN pos = 0
		findForward = $$TRUE
	ELSE
		IF ((line > uText) OR (line < 0)) THEN
			line = uText
			pos = LEN(text$[uText])
		ELSE
			IF (pos < 0) THEN pos = LEN(text$[line])
		END IF
		findForward = $$FALSE
	END IF
	lenLine = LEN(text$[line])
	IF (pos > lenLine) THEN pos = lenLine
'
	IF findCase THEN
		XstStringToStringArray (@find$, @find$[])
	ELSE
		XstStringToStringArray (LCASE$(find$), @find$[])
	END IF
	uFind = UBOUND(find$[])
	IF (uFind > uText) THEN RETURN
'
	IF (uFind = 0) THEN
		IF findForward THEN GOSUB OneLineForward ELSE GOSUB OneLineReverse
	ELSE
		GOSUB MultiLine
	END IF
	RETURN
'
'
' *****  OneLineForward  *****
'
SUB OneLineForward
	i = pos + 1														' intrinsics count from 1
	ufs = UBOUND(find$)
'
	FOR l = line TO uText
		IF findCase THEN
			found = INSTR (text$[l], find$, i)
		ELSE
			found = INSTRI (text$[l], find$, i)
		END IF
		IF found THEN
			IF findWord THEN
				IF (found > 1) THEN
					IF (charsetWithinWord[text$[l]{found-2}]) THEN
						i = found + 1
						DO FOR
					END IF
				END IF
				IF ((found + ufs) < LEN(text$[l])) THEN
					IF (charsetWithinWord[text$[l]{found+ufs}]) THEN
						i = found + 1
						DO FOR
					END IF
				END IF
			END IF
			EXIT FOR
		END IF
		i = 1
	NEXT l
'
	IF found THEN
		match = $$TRUE
		pos = found-1
		line = l
	END IF
END SUB
'
'
' *****  OneLineReverse  *****
'
SUB OneLineReverse
	i = pos + 1														' intrinsics count from 1
	ufs = UBOUND(find$)
'
	FOR l = line TO 0 STEP -1
		IF findCase THEN
			found = RINSTR (text$[l], find$, i)
		ELSE
			found = RINSTRI (text$[l], find$, i)
		END IF
		IF found THEN
			IF findWord THEN
				IF (found > 1) THEN
					IF (charsetWithinWord[text$[l]{found-2}]) THEN
						i = found - 1
						DO FOR
					END IF
				END IF
				IF ((found + ufs) < LEN(text$[l])) THEN
					IF (charsetWithinWord[text$[l]{found+ufs}]) THEN
						IF (found > 1) THEN
							i = found - 1
							DO FOR
						ELSE
							i = -1
							DO NEXT
						END IF
					END IF
				END IF
			END IF
			EXIT FOR
		END IF
		i = -1
	NEXT l
'
	IF found THEN
		match = $$TRUE
		pos = found-1
		line = l
	END IF
END SUB
'
'
' *****  MultiLine  *****
'
SUB MultiLine
'
	fLen = LEN(find$[0])
	fuLen = LEN(find$[uFind])
'
	IF findForward THEN
		from = line
		to = uText - uFind
		step = 1
	ELSE
		from = line - uFind
		to = 0
		step = -1
	END IF
'
	IF findCase THEN
		FOR l = from TO to STEP step
			IF (RIGHT$(text$[l], fLen) == find$[0]) THEN
				IF (LEFT$(text$[l+uFind], fuLen) == find$[uFind]) THEN
					FOR m = 1 TO uFind-1
						IF (text$[m+l] != find$[m]) THEN DO NEXT 2
					NEXT m
					wordChrPos = UBOUND(text$[l]) - fLen
					IF findWord THEN
						IF (wordChrPos >= 0) THEN
							IF (charsetWithinWord[text$[l]{wordChrPos}]) THEN DO NEXT
						END IF
						IF (fuLen <= UBOUND(text$[l+uFind])) THEN
							IF (charsetWithinWord[text$[l+uFind]{fuLen}]) THEN DO NEXT
						END IF
					END IF
					line = l
					pos = wordChrPos + 1
					match = $$TRUE
					EXIT FOR
				END IF
			END IF
		NEXT l
	ELSE
		FOR l = from TO to STEP step
			IF (LCASE$(RIGHT$(text$[l], fLen)) == find$[0]) THEN
				IF (LCASE$(LEFT$(text$[l+uFind], fuLen)) == find$[uFind]) THEN
					FOR m = 1 TO uFind-1
						IF (LCASE$(text$[m+l]) != find$[m]) THEN DO NEXT 2
					NEXT m
					wordChrPos = UBOUND(text$[l]) - fLen
					IF findWord THEN
						IF (wordChrPos >= 0) THEN
							IF (charsetWithinWord[text$[l]{wordChrPos}]) THEN DO NEXT
						END IF
						IF (fuLen <= UBOUND(text$[l+uFind])) THEN
							IF (charsetWithinWord[text$[l+uFind]{fuLen}]) THEN DO NEXT
						END IF
					END IF
					line = l
					pos = wordChrPos + 1
					match = $$TRUE
					EXIT FOR
				END IF
			END IF
		NEXT l
	END IF
END SUB
'
END FUNCTION
'
'
' ################################
' #####  XstIsDataDimension  #####
' ################################
'
' isdata = XstIsDataDimension (@array[])
'
FUNCTION  XstIsDataDimension (array[])
'
	IFZ array[] THEN RETURN $$FALSE
	RETURN (!(UBYTEAT(&array[], -5) AND 0x20))
END FUNCTION
'
'
' #################################
' #####  XstMergeStrings$ ()  #####
' #################################
'
' return$ = XstMergeStrings$ (string$, add$, start, replace)
'
' string$ - the character string being merged with
' add$    - the string being merged or added
' start   - character position to insert add$
' replace - the number of characters to be replaced or deleted
'
FUNCTION  XstMergeStrings$ (string$, add$, start, replace)
'
	RETURN (MID$(string$,1,start-1) + add$ + MID$(string$,start+replace))
END FUNCTION
'
'
' ############################################
' #####  XstMultiStringToStringArray ()  #####
' ############################################
'
' XstMultiStringToStringArray (@string$, @array$[])
'
' XstMultiStringToStringArray() converts a string$ into a string array$[] by
' breaking the string into separate strings at each occurance of an \r character.
' Note that the line separator character is not the \n aka newline character,
' and that the lines in array$[] may therefore contain \n characters.
'  \r characters are discarded.
'
FUNCTION  XstMultiStringToStringArray (s$, s$[])
'
	DIM s$[]
	IFZ s$ THEN RETURN
'
	lenString = LEN (s$)
	uString = (lenString >> 5) OR 7								' guess 32 chars/line
	DIM s$[uString]
'
	line			= 0
	firstChar	= 0
	DO
		cr = INSTR (s$, "\r", firstChar + 1)		' next return char
		nl = INSTR (s$, "\n", firstChar + 1)		' next newline char
		IF cr THEN															' found \r
			IF nl THEN														' found \n
				IF (nl < cr) THEN
					cr = nl														' \n before \r
				ELSE
					IF (nl > (cr+1)) THEN nl = cr			' \n in later line
				END IF
			ELSE
				nl = cr															' \r without \n
			END IF
		ELSE
			IF nl THEN cr = nl										' \n without \r
		END IF
		IFZ (cr OR nl) THEN											' no \r or \n = last line
			cr = lenString + 1										' fake \r after string
			nl = lenString + 1										' fake \n after string
			GOSUB AddLine													' add rest of string
			EXIT DO
		END IF
		GOSUB AddLine
		IF (firstChar >= lenString) THEN EXIT DO
	LOOP
	IF (s${lenString - 1} != '\r') THEN DEC line
	IF (line != uString) THEN REDIM s$[line]
	RETURN ($$FALSE)
'
'
'	Add next s$ line to array--don't include "\r"
'		firstChar	= offset (from 0) of first character on this line
'		cr				= index (from 1) of return (CR)
'   nl				= index (from 1) of newline (NL = LF)
'
SUB AddLine
	chars = cr - firstChar - 1			' up to first newline char (\r or \n)
	IF chars THEN
		line$ = NULL$ (chars)
		FOR i = 0 TO chars - 1
			line${i} = s${firstChar + i}
		NEXT i
		ATTACH line$ TO s$[line]
	END IF
	firstChar = nl									' to \r or \n  (last char in newline)
	INC line
	IF (line > uString) THEN
		uString = (uString + (uString >> 1)) OR 7
		REDIM s$[uString]
	END IF
END SUB
END FUNCTION
'
'
' ###############################
' #####  XstNextCField$ ()  #####
' ###############################
'
' string$ = XstNextCField$ (address, @index, @done)
'
' Return the next text element from a C string.
'
'  string$ = next text element from C string
'  address = memory address of C string
'  index   = character position in C string  ( 1st byte = 1 )
'  done    = end of C string reached
'
' XstNextCField$() returns the next text element in the string at address,
' starting at character position index.  index is advanced to the separator
' that terminates the text element.  Text elements are separated by bounding
' characters, which are characters with a value <= 0x20 (space, tab, newline,
' return, and all control characters) and characters with a value >= 0x7F
' (all special characters).
'
' All bounding characters are skipped.  Then valid text characters are
' collected in string$ until a bounding character is found or the end of
' the string is reached, which is the first null character in the string.
'
' index and done are normally passed by reference because useful information
' is returned in these variables.  index is returned with the position of the
' character after the text element, and done is returned with a non-zero value
' if index entered with a value greater than the length of the string at address.
'
' If index and done are passed by reference, XstNextCField$() can be called
' repeatedly to read successive text elements from the string at address.
'
' If index <= 0 is passed to XstNextCField(), it is set to 1.
'
FUNCTION  XstNextCField$ (sourceAddr, index, done)
'
	done = $$FALSE
	IF (index < 1) THEN index = 1
	startOffset = index - 1
'
	char = UBYTEAT (sourceAddr, startOffset)
	IFZ char THEN done = $$TRUE : RETURN ("")
'
'	Find start of next field
'
	offset = startOffset
	DO WHILE ((char <= ' ') OR (char >= 0x7F))
		INC offset
		char = UBYTEAT (sourceAddr, offset)
		IFZ char THEN															' No fields left
			index = offset + 1
			done = $$TRUE
			RETURN ("")
		END IF
	LOOP
'
'	Find end of this field
'
	startOffset = offset
	DO
		INC offset
		char = UBYTEAT (sourceAddr, offset)
	LOOP WHILE ((char > ' ') AND (char < 0x7F))
'
'	Make the string
'
	length = offset - startOffset
	nextWord$ = NULL$ (length)
	dest = 0
	FOR i = startOffset TO offset - 1			' don't include the terminator
		nextWord${dest} = UBYTEAT(sourceAddr, i)
		INC dest
	NEXT i
	index = offset + 1										' index = INDEX of terminator
	RETURN (nextWord$)
END FUNCTION
'
'
' ##############################
' #####  XstNextCLine$ ()  #####
' ##############################
'
' string$ = XstNextCLine$ (address, @index, @done)
'
'	XstNextCLine$() is for strings not having the XBasic header
'		(typically, C strings imbedded in structures, etc)
'								= BIG TROUBLE if index is beyond terminating NULL
'
'	sourceAddr	= text address to search (source is not altered)
'	index				= index at which to begin search (1 = first character)
'										(if index < 1, starts at 1)
'
'	return next line from sourceAddr
'		doesn't return terminating \n or \r\n or \0
'								"" if done
'	index		= index after terminating \n \r\n or \0
'
'	done		= TRUE if 1st character = NULL
'
'	NOTE:  index counts from 1, offset counts from 0
'
FUNCTION  XstNextCLine$ (sourceAddr, index, done)
'
	done = $$FALSE
	IF (index < 1) THEN index = 1
	startOffset = index - 1
'
	char = UBYTEAT (sourceAddr, startOffset)
	IFZ char THEN done = $$TRUE : RETURN ("")
'
	offset = startOffset										' find the terminator
	DO WHILE (char > 0) AND (char != '\n')
		INC offset
		char = UBYTEAT (sourceAddr, offset)
	LOOP
'
	length = offset - startOffset						' make the string
	IFZ length THEN
		line$ = ""
	ELSE
		endOffset = offset - 1
		cc = UBYTEAT (sourceAddr, endOffset)
		IF (cc = '\r') THEN
			DEC length
			DEC endOffset
		END IF
		IFZ length THEN
			line$ = ""
		ELSE
			line$ = NULL$ (length)
			FOR i = startOffset TO endOffset		' don't include the terminator
				line${i - startOffset} = UBYTEAT(sourceAddr, i)
			NEXT i
		END IF
	END IF
'
	INC offset															' bump offset past terminator
	index = offset + 1
	next = UBYTEAT (sourceAddr, offset)			' byte after terminator
	IFZ next THEN done = $$TRUE							' null after terminator
	RETURN (line$)
END FUNCTION
'
'
' ##############################
' #####  XstNextField$ ()  #####
' ##############################
'
' string$ = XstNextField$ (@source$, @index, @done)
'
' Return the next text element from a string.
'
'  string$  = next text element from string
'  source$  = string to extract text element from
'  index    = character position in source$
'  done     = end of string reached
'
' XstNextField$() returns the next text element from source$, starting at
' character position index.  index is advanced to the separator that terminates
' the text element.  Text elements are separated by bounding characters, which
' are characters with a value <= 0x20 (space, tab, newline, return, and all
' control characters) and characters with a value >= 0x7F (all special characters).
'
' All bounding characters are skipped.  Then valid text characters are collected in
' string$ until a bounding character is found or the end of the string is reached.
'
' index and done are normally passed by reference because useful information is
' returned in these variables.  index is returned with the position of the
' character after the text element, and done is returned with a non-zero value
' if index entered with a value greater than the length of source$.
'
' If index and done are passed by reference, XstNextField$() can be called
' repeatedly to read successive text elements from source$.
'
' If index <= 0 is passed to XstNextField(), it is set to 1.
'
' source$ is not modified by XstNextField$(), so it can be passed by reference
' for optimal speed.
'
' See: XstParseWhitespace$()
'
FUNCTION  XstNextField$ (source$, index, done)
'
	done = $$FALSE
	IF (index < 1) THEN index = 1
'
	length = LEN (source$)
	IF (index > length) THEN done = $$TRUE : RETURN ("")
'
'	Find start of next field
'
	offset = index - 1
	DO WHILE (offset < length)
		char = source${offset}
		IF ((char > ' ') AND (char < 0x7F)) THEN EXIT DO
		INC offset
	LOOP
'
	IF (offset >= length) THEN
		index = length + 1
		done = $$TRUE
		RETURN ("")
	END IF
'
'	Find end of this field
'
	INC offset																' bump offset past first OK char
	start = offset														' start = INDEX of first character
	DO WHILE (offset < length)
		char = source${offset}
		IF (char <= ' ')  THEN EXIT DO
		IF (char >= 0x7F) THEN EXIT DO
		INC offset
	LOOP
'
	index = offset + 1												' index = INDEX of terminator
	RETURN (MID$ (source$, start, index-start))
END FUNCTION
'
'
' #############################
' #####  XstNextItem$ ()  #####
' #############################
'
' string$ = XstNextItem$(source$, @index, @term, @done)
'
' The XstNextItem$ function returns the next text element
' from a delimited string. XstNextItem$ can be used on a
' comma delimited string. Spaces are not altered.
'
' XstNextItem$ returns the next text element from source$,
' starting at character position index. index is advanced
' to the separator that terminates the text element.
' Text elements are separated by bounding characters, which are a
' value <= 0x1F ( tab, newline, return, and all control characters),
' characters with a value >= 0x7F (all special characters),
' plus the comma , newline, and tab characters.
'
' All bounding characters are skipped. Then valid text characters
' are collected in string$ until a bounding character is found or
' the end of the string is reached.
'
' "index" and "done" are normally passed by reference because useful
' information is returned in these variables. index is returned
' with the position of the character after the text element,
' and done is returned with a non-zero value if index entered
' with a value greater than the length of source$.
'
' If "index" and "done" are passed by reference, XstNextItem$ can be
' called repeatedly to read successive text elements from source$.
'
' If (index <= 0) is passed to XstNextItem, it is set to 1 .
'
' "source$" is not modified by XstNextItem$ , so it can be passed
' by reference for optimal speed.
'
'
'  source$ - A delimited string
'  index   - The character position within source$
'  term    - The terminating character (tab- \t, newline- \n, comma - ,)
'            or 0 if end of line reached with no terminator
'  done    - done is $$TRUE if the end of the string was reached
'
' See: XstParseWhitespace$()
'
FUNCTION  XstNextItem$ (source$, index, term, done)
	STATIC  UBYTE  char[]
	STATIC  UBYTE  term[]
'
	IFZ char[] THEN GOSUB Initialize
'
	done = $$FALSE
	IF (index < 1) THEN index = 1
'
	length = LEN (source$)
	IF (index > length) THEN done = $$TRUE : RETURN ("")
'
' find next separator / terminator
'
	final = 0							' index of last valid character
	first = 0							' index of first valid character
	offset = index - 1		' ditto
'
	DO WHILE (offset < length)
		char = source${offset}
		INC offset
		IF char[char] THEN
			final = offset
			IFZ first THEN first = offset
		END IF
	LOOP UNTIL term[char]
'
	term = char
	IF (offset >= length) THEN
		offset = length + 1
		term = $$FALSE
		done = $$TRUE
	END IF
'
	index = offset + 1
	IFZ first THEN RETURN ("")
	RETURN (MID$(source$, first, final-first+1))
'
'
' *****  Initialize  *****
'
SUB Initialize
	whomask = ##WHOMASK
	##WHOMASK = $$FALSE
'
	DIM char[255]					' array of valid characters
	DIM term[255]					' array of terminator characters
'
	FOR i = 0 TO 255
		char[i] = i					' start with all bytes valid characters
	NEXT i
'
	FOR i = 0x00 TO 0x1F
		char[i] = 0					' 0x00 to 0x1F are not valid characters
	NEXT i
'
	FOR i = 0x80 TO 0xFF
		char[i] = 0					' 0x80 to 0xFF are not valid characters
	NEXT i
'
	char[','] = 0					' comma is a separator
	char['\n'] = 0				' newline is a separator
	char['\t'] = 0				' tab is a separator
'
	term[','] = ','				' comma is a separator
	term['\n'] = '\n'			' newline is a separator
	term['\t'] = '\t'			' tab is a separator
'
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' #############################
' #####  XstNextLine$ ()  #####
' #############################
'
' string$ = XstNextLine$ (@source$, @index, @done)
'
' Return the next newline terminated string from a string.
'
'  source$ = string to extract the next line from
'  index   = character position in C string  ( 1st byte = 1 )
'  done    = end of C string reached
'
' XstNextLine$() returns the next string$ from source$ that starts at index and
' ends with the next newline character or end of string, whichever comes first.
'
' string$ is returned without a terminating character.  index and done are
' normally passed by reference because useful information is returned in these
' variables.  index is moved past the newline or end of string.  done is returned
' with a non-zero value if index is greater than the length of source$.
'
' If index and done are passed by reference, XstNextLine$() can be
' called repeatedly to read successive lines from source$.
'
' If index <= 0 is passed to XstNextLine$(), it is set to 1.
'
' source$ is not modified by XstNextLine$(), so it can be
' passed by reference for optimal speed.
'
FUNCTION  XstNextLine$ (source$, index, done)
'
	done = $$FALSE
	IF (index < 1) THEN index = 1
'
	length = LEN(source$)
	IF (index > length) THEN done = $$TRUE : RETURN ("")
'
	newLine = INSTR (source$, "\n", index)
	IFZ newLine THEN newLine = length + 1							' no \n remaining
	chars = newLine - index
	IF (newLine > 1) THEN
		IF (source${newLine - 2} = '\r') THEN
			IF chars THEN DEC chars
		END IF
	END IF
'
	line$ = MID$ (source$, index, chars)
	index = newLine + 1
	RETURN (line$)
END FUNCTION
'
'
' ################################
' #####  XstReplaceArray ()  #####
' ################################
'
' XstReplaceArray (mode, @text$[], @find$, @replace$, @line, @pos, @match)
'
' XstReplaceArray() looks for a find$ string within text array text$[] starting
' at line, pos. text$[0] is line 0 and the first character on each line is pos 0.
'
' If an XstReplaceArray() finds an occurance of find$ in text$[] given the
' instructions in the mode argument, match is assigned a non-zero value and
' line, pos are assigned the line and character position of the first character
' of the string in text$[] that matched find$, and the matched string in text$[]
' is replaced by replace$.
'
' XstReplaceArray() does not alter text$[], find$, or replace$.
'
' mode=0 tells XstReplaceArray() to find forward, case-sensitive.
' To control the find, OR together mode constants from xst.dec :
'
'  $$FindForward
'  $$FindReverse
'  $$FindDirection
'  $$FindCaseSensitive
'  $$FindCaseInsensitive
'  $$FindCaseSensitivity
'  $$FindWordSensitive
'  $$FindWordInsensitive
'  $$FindWordSensitivity
'
FUNCTION  XstReplaceArray (mode, text$[], find$, replace$, line, pos, match)
	IFZ text$[] THEN RETURN
	IFZ find$ THEN RETURN
'
	match = $$FALSE
	mode = mode AND 0x07
	XstFindArray (mode, @text$[], @find$, @line, @pos, @match)
	IFZ match THEN RETURN
'
	XstStringToStringArray (@find$, @find$[])
	uFind = UBOUND (find$[])
	uText = UBOUND (text$[])
	uReplace = -1																					' empty (default)
'
	IF replace$ THEN
		XstStringToStringArray (@replace$, @replace$[])
		uReplace = UBOUND (replace$[])
	END IF
'
	IFZ uFind THEN
		IF (uReplace <= 0) THEN GOSUB OneLineOneLine ELSE GOSUB OneLineMultiLine
	ELSE
		IF (uReplace <= 0) THEN GOSUB MultiLineOneLine ELSE GOSUB MultiLineMultiLine
	END IF
	RETURN
'
'
' ****  OneLineOneLine  *****
'
SUB OneLineOneLine
	text$ = text$[line]
	lenFind = LEN(find$)
	text$[line] = LEFT$(text$,pos) + replace$ + MID$(text$, pos+1+lenFind)
END SUB
'
'
' ****  OneLineMultiLine  *****  replace part or all of one line with more than one line
'
SUB OneLineMultiLine
	text$ = text$[line]												' first line of text
	lenFind = LEN(find$)											' length of find string
	before$ = LEFT$(text$,pos)								' before replaced string
	after$ = MID$(text$,pos+1+lenFind)				' after replaced string
	replacea$ = replace$[0]										' first replace line
	replacez$ = replace$[uReplace]						' last replace line
	replace$[0] = before$ + replacea$					' fix first replace string
	replace$[uReplace] = replacez$ + after$		' fix last replace string
	XstReplaceLines (@text$[], @replace$[], line, 1, 0, uReplace+1)
END SUB
'
'
' *****  MultiLineOneLine  *****  replace part or all of more than one line with one line
'
SUB MultiLineOneLine
	text$ = text$[line]
	before$ = LEFT$(text$,pos)
	after = LEN(find$[uFind])
	after$ = text$[line+uFind]
	text$[line] = before$ + replace$ + MID$(after$, after+1)
	text$[line+1] = ""
	FOR i = line+1 TO uText-uFind
		SWAP text$[i], text$[i+uFind]
	NEXT i
	REDIM text$[i-uFind]
END SUB
'
'
' *****  MultiLineMultiLine  *****
'
SUB MultiLineMultiLine
	text$ = text$[line]
	before$ = LEFT$(text$,pos)
	text$[line] = before$ + replace$[0]
	text$ = text$[line+uFind]
	after = LEN(find$[uFind])
	after$ = MID$(text$[line+uFind], after+1)
	text$[line+uFind] = replace$[uReplace] + after$
	XstReplaceLines (@text$[], @replace$[], line+1, uFind-1, 1, uReplace-1)
END SUB
END FUNCTION
'
'
' ################################
' #####  XstReplaceLines ()  #####
' ################################
'
' error = XstReplaceLines (@d$[], @s$[], firstD, countD, firstS, countS)
'
' Replaces countD lines in d$[] with countS lines of s$[].
' The range of lines in d$[] to replace begins at firstD,
' while the range of lines in s$[] to substitute start at firstS.
' If countD or countS is -1, then all the lines from firstD or
' firstS to the end of the array will be replaced.
'
' If countD < 0, then the lines from firstD to end are replaced.
' firstD > UBOUND(d$[]) then the lines are appended to d$[]
'
' If firstD, countD, firstS and countS are passed by reference,
' the actual values used, are returned to the calling function.
'
' See: XstDeleteLines()
'
FUNCTION  XstReplaceLines (d$[], s$[], firstD, countD, firstS, countS)
'
	IF (&s$[] == &d$[]) THEN  ' source and destination must not be the same array
		countD = 0
		countS = 0
		RETURN -1
	END IF
	upperS = UBOUND(s$[])
	upperD = UBOUND(d$[])
	IF (firstS < 0) THEN firstS = 0
	IF (firstD < 0) THEN firstD = 0
	IF (firstS > upperS) THEN countS = 0
	IF (firstD > (upperD + 1)) THEN firstD = upperD + 1
	IF (countS < 0) THEN countS = upperS - firstS + 1
	IF (countD < 0) THEN countD = upperD - firstD + 1
	finalS = firstS + countS - 1
	finalD = firstD + countD - 1
	IF (finalS > upperS) THEN finalS = upperS
'
	finalTmp = finalS - firstS
	DIM tmp$[finalTmp]
	FOR s = 0 TO finalTmp
		tmp$[s] = s$[s+firstS]
	NEXT s
'
	IF d$[] THEN
		IF (finalD <= upperD) THEN
			delta = countS - countD
			SELECT CASE TRUE
				CASE (delta < 0)
							upperD = upperD + delta
							FOR d = firstD + countS TO upperD
								SWAP d$[d], d$[d-delta]
							NEXT d
							REDIM d$[upperD]
				CASE (delta > 0)
							oldUpperD = upperD
							upperD = upperD + delta
							REDIM d$[upperD]
							FOR d = oldUpperD TO (firstD + countD) STEP -1
								SWAP d$[d+delta], d$[d]
							NEXT d
			END SELECT
		ELSE
			REDIM d$[finalD]
		END IF
		'
		FOR s = 0 TO finalTmp
			SWAP d$[firstD+s], tmp$[s]
		NEXT s
	ELSE
		SWAP tmp$[], d$[]
	END IF
'
END FUNCTION
'
'
' ##############################################
' #####  XstStringArraySectionToString ()  #####
' ##############################################
'
' XstStringArraySectionToString (@text$[], @copy$, x1, y1, x2, y2, term)
'
' Copy a section of text from a source string array to a destination string.
'  text$[] source string array
'  copy$   returned string section
'  x1      starting character position
'  y1      starting line in array
'  x2      ending  character position
'  y2      ending line in array
'  term    termination character for each line:
'          0 = none, 1 = '\n', 2 = '\r'
'
' The first position in a line is 1.   ??????????????
' The first line of a text array is 0.
' The last character of a line LEN(line).
' The last line of a text$[] is UBOUND(text$[])
'  terminating character is NOT added to the end of the last line.
'
FUNCTION  XstStringArraySectionToString (text$[], copy$, x1, y1, x2, y2, n)
'
	copy$ = ""
	IFZ text$[] THEN RETURN
	upper = UBOUND(text$[])
'
	SELECT CASE ALL TRUE
		CASE (x1 < 0)								: x1 = 0
		CASE (y1 < 0)								: y1 = 0
		CASE (x2 < 0)								: x2 = 0
		CASE (y2 < 0)								: y2 = 0
		CASE (y2 < y1)							: SWAP x1, x2 : SWAP y1, y2					' x1,y1 comes 1st
		CASE (y2 = y1)							: IF (x2 < x1) THEN SWAP x2, x1			' x1,y1 comes 1st
		CASE (y1 > upper)						: y1 = upper : x1 = LEN(text$[y1])	' x1,y1 at end
		CASE (y2 > upper)						: y2 = upper : x2 = LEN(text$[y2])	' x2,y2 at end
		CASE (x1 > LEN(text$[y1]))	: x1 = LEN(text$[y1])								' x1 at line end
		CASE (x2 > LEN(text$[y2]))	: x2 = LEN(text$[y2])								' x2 at line end
	END SELECT
'
	IF (y2 = y1) THEN								' All on one line
		IF (x2 <= x1) THEN
			copy$ = ""
		ELSE
			copy$ = MID$(text$[y1], x1+1, x2-x1)
			END IF
		RETURN
	END IF
'
	firstLength = LEN(text$[y1])		' length of 1st string
	finalLength = LEN(text$[y2])		' length of last string
'
	bytes = firstLength - x1 + n      ' segment length of first segment + newline
	bytes = bytes + x2 + n            ' segment length of final segment + newline
'
	FOR i = y1+1 TO y2-1								' for all but first and final lines
		bytes = bytes + LEN(text$[i]) + n	' add string length + newline length
	NEXT i
'
	bytes = (bytes + 15) AND -16		' round up to mod 16
	copy$ = NULL$ (bytes)						' copy$ is now final result size
	IF (LEN(copy$) != bytes) THEN RETURN $$TRUE
'
	o = 0														' offset into copy$
		addr = &text$[y1]								' address of 1st byte in 1st string
		FOR x = x1 TO firstLength-1			'
			copy${o} = UBYTEAT(addr,x)		' copy byte from first string to copy$
			INC o													' offset to next byte in copy$
		NEXT x
	IF n THEN GOSUB AppendNewline		' append newline character
'
	FOR y = y1+1 TO y2-1						' FOR second string TO next to last string
		addr = &text$[y]							' address of 1st byte in string to copy$
		FOR x = 0 TO UBOUND(text$[y])	' FOR first to last character in text$[y]
			copy${o} = UBYTEAT(addr,x)	' copy byte from text$[y]{x} to copy${o}
			INC o												' next offset in copy$
		NEXT x												' next byte to copy
		IF n THEN GOSUB AppendNewline	' append newline
	NEXT y													' next line
'
	addr = &text$[y2]								' address of final string
	FOR x = 0 TO x2-1								' FOR first byte TO last byte in final string
		copy${o} = UBYTEAT(addr,x)		' copy byte from text$[y2]{x} to copy${o}
		INC o
	NEXT x
'
	headAddr = &copy$ - 16					' address of copy$ header
	XLONGAT(headAddr) = o           ' set length of copy$ exactly
	RETURN
'
' *****  AppendNewline  *****
'
SUB AppendNewline
	SELECT CASE n
		CASE 0		: ' nothing between lines - concatenate lines w/o separator
		CASE 1		: copy${o} = '\n'	: INC o
		CASE 2		: copy${o} = '\r' : INC o : copy${o} = '\n' : INC o
		CASE ELSE	: copy${o} = '\n' : INC o
	END SELECT
END SUB
'
END FUNCTION
'
'
' ###################################################
' #####  XstStringArraySectionToStringArray ()  #####
' ###################################################
'
' XstStringArraySectionToStringArray (@text$[], @copy$[], x1, y1, x2, y2)
'
' Copy a section of text from a source string array to a destination string array.
'  text$[] source string array
'  copy$   returned string section
'  x1      starting character position
'  y1      starting line in array
'  x2      ending  character position
'  y2      ending line in array
'
FUNCTION  XstStringArraySectionToStringArray (text$[], copy$[], x1, y1, x2, y2)
'
	IF copy$[] THEN DIM copy$[]
	IFZ text$[] THEN RETURN
	upper = UBOUND(text$[])
'
	SELECT CASE ALL TRUE
		CASE (x1 < 0)								: x1 = 0
		CASE (y1 < 0)								: y1 = 0
		CASE (x2 < 0)								: x2 = 0
		CASE (y2 < 0)								: y2 = 0
		CASE (y2 < y1)							: SWAP x1, x2 : SWAP y1, y2					' x1,y1 comes 1st
		CASE (y2 = y1)							: IF (x2 < x1) THEN SWAP x2, x1			' x1,y1 comes 1st
		CASE (y1 > upper)						: y1 = upper : x1 = LEN(text$[y1])	' x1,y1 at end
		CASE (y2 > upper)						: y2 = upper : x2 = LEN(text$[y2])	' x2,y2 at end
		CASE (x1 > LEN(text$[y1]))	: x1 = LEN(text$[y1])								' x1 at line end
		CASE (x2 > LEN(text$[y2]))	: x2 = LEN(text$[y2])								' x2 at line end
	END SELECT
'
	ucopy = y2 - y1								' upper bound of copy$[]
	IFZ ucopy THEN								' only one line
		DIM copy$[0]
		IF (x2 <= x1) THEN
			copy$[0] = ""
		ELSE
			copy$[0] = MID$(text$[y1], x1+1, x2-x1)
		END IF
		RETURN
	END IF
'
	copy = 0
	DIM copy$[ucopy]											' result array
	copy$[0] = MID$(text$[y1], x1+1)			' first string is segment
	FOR y = y1+1 TO y2-1									' for all but first and final lines
		INC copy														' next copy$[] element
		copy$[copy] = text$[y]							' copy$[] line = text$[] line
	NEXT y																'
	copy$[ucopy] = LEFT$(text$[y2],x2)		' final string is segment
END FUNCTION
'
'
' #######################################
' #####  XstStringArrayToString ()  #####
' #######################################
'
' XstStringArrayToString (@text$[], @text$)
'
' Copy a string array to a string.  Each line from the source string array
' is appended with a '\n' before it is put into the destination string.
'
FUNCTION  XstStringArrayToString (s$[], s$)
'
	s$ = ""
	IFZ s$[] THEN RETURN
'
'	Faster to precompute required s$ length than REDIM on occasion
'
	lastLine = UBOUND(s$[])
	IFZ lastLine THEN						' Separate case for simpler logic below
		s$ = s$[0]
		RETURN
	END IF
'
	totalChars = 0
	FOR i = 0 TO lastLine - 1
		totalChars = totalChars + LEN(s$[i]) + 1				' chars + \n
	NEXT i
'
	IF s$[lastLine] THEN
		totalChars = totalChars + LEN(s$[lastLine])
	END IF
'
	s$ = NULL$ (totalChars)
	index = 0
'
	FOR i = 0 TO lastLine
		SWAP s$[i], a$
		chars = LEN (a$)
		IF chars THEN
			FOR j = 0 TO chars - 1
				s${index} = a${j}
				INC index
			NEXT j
		END IF
		IF (i < lastLine) THEN
			s${index} = '\n'
			INC index
		END IF
		SWAP a$, s$[i]
	NEXT i
END FUNCTION
'
'
' ###########################################
' #####  XstStringArrayToStringCRLF ()  #####
' ###########################################
'
' XstStringArrayToStringCRLF (@text$[], @text$)
'
' Copy a string array to a string.  Each line from the source string array
' is appended with a '\r\n' before it is put into the destination string.
'
FUNCTION  XstStringArrayToStringCRLF (s$[], s$)
'
	s$ = ""
	IFZ s$[] THEN RETURN
'
'	Faster to precompute length than REDIM on occasion
'
	lastLine = UBOUND(s$[])
	IFZ lastLine THEN						' Separate case for simpler logic below
		s$ = s$[0] + "\r\n"
		RETURN
	END IF
'
	totalChars = 0
	FOR i = 0 TO lastLine - 1
		totalChars = totalChars + LEN(s$[i]) + 2				' chars + \r\n
	NEXT i
'
	IF s$[lastLine] THEN
		totalChars = totalChars + LEN(s$[lastLine])
	END IF
'
	s$ = NULL$ (totalChars)
	index = 0
	FOR i = 0 TO lastLine
		SWAP s$[i], a$
		chars = LEN (a$)
		IF chars THEN
			FOR j = 0 TO chars - 1
				s${index} = a${j}
				INC index
			NEXT j
		END IF
		IF (i < lastLine) THEN
			s${index} = '\r'
			INC index
			s${index} = '\n'
			INC index
		END IF
		SWAP a$, s$[i]
	NEXT i
END FUNCTION
'
'
' #######################################
' #####  XstStringToStringArray ()  #####
' #######################################
'
' XstStringToStringArray (@text$, @text$[])
'
FUNCTION  XstStringToStringArray (s$, s$[])
'
	DIM s$[]
	IFZ s$ THEN RETURN
'
	lenString = LEN(s$)
	uString = (lenString >> 5) OR 7								' guess 32 chars/line
	DIM s$[uString]
	firstChar	= 0
	line = 0
'
	DO
		nl = INSTR (s$, "\n", firstChar + 1)
		IFZ nl THEN																	' last line
			nl = lenString + 1
			GOSUB AddLine
			EXIT DO
		END IF
		GOSUB AddLine
		IF (firstChar >= lenString) THEN EXIT DO
	LOOP
'
	IF (s${lenString-1} != '\n') THEN DEC line
	IF (line != uString) THEN REDIM s$[line]
	RETURN ($$FALSE)
'
'	Add next s$ line to array--don't include newLine (or CR)
'		firstChar	= offset (from 0) of first character on this line
'		nl				= index (from 1) of newLine (LF)
'
SUB AddLine
	chars = nl - firstChar - 1
	IF (nl > 1) THEN
		IF (s${nl - 2} = '\r') THEN DEC chars				' skip CR
	END IF
	IF chars THEN
		line$ = NULL$(chars)
		FOR i = 0 TO chars - 1
			line${i} = s${firstChar + i}
		NEXT i
		ATTACH line$ TO s$[line]
	END IF
	firstChar = nl
	INC line
	IF (line > uString) THEN
		uString = (uString + (uString >> 1)) OR 7
		REDIM s$[uString]
	END IF
END SUB
END FUNCTION
'
'
' #########################
' #####  XstLTRIM ()  #####
' #########################
'
' error = XstLTRIM (@string$, @array[])
'
' Trim characters from the left end of a string as specified in the array[].
'
' string$ - character string supplied untrimmed and returned trimmed
' array[] - array indexed by the character number, with a zero value
'           for each character that is to be trimmed.
'
' See: LTRIM$(), demo program "atrim.x"
'
FUNCTION  XstLTRIM (@string$, array[])
'
	IFZ string$ THEN RETURN
'
	IFZ array[] THEN
		string$ = LTRIM$ (string$)		' default
	ELSE
		type = TYPE (array[])
		upper = UBOUND (array[])
		IF (upper < 255) THEN RETURN -1
		IF ((type != $$SLONG) AND (type != $$ULONG) AND (type != $$XLONG)) THEN RETURN -1
'
		upper = UBOUND (string$)
		first = -1
'
		FOR i = 0 TO upper
			IF array[string${i}] THEN first = i : EXIT FOR
		NEXT i
'
		SELECT CASE TRUE
			CASE (first < 0)	: string$ = ""
			CASE (first > 0)	: string$ = MID$ (string$, first+1)
		END SELECT
	END IF
END FUNCTION
'
'
' #########################
' #####  XstRTRIM ()  #####
' #########################
'
' error = XstRTRIM (@string$, @array[])
'
' Trim characters from the right end of a string as specified in the array[].
'
' string$ - character string supplied untrimmed and returned trimmed
' array[] - array indexed by the character number, with a zero value
'           for each character that is to be trimmed.
'
' See: RTRIM$(), demo program "atrim.x"
'
FUNCTION  XstRTRIM (@string$, array[])
'
	IFZ string$ THEN RETURN
'
	IFZ array[] THEN
		string$ = RTRIM$ (string$)							' default
	ELSE
		type = TYPE (array[])
		upper = UBOUND (array[])
		IF (upper < 255) THEN RETURN -1
		IF ((type != $$SLONG) AND (type != $$ULONG) AND (type != $$XLONG)) THEN RETURN -1
'
		upper = UBOUND (string$)
		final = -1
'
		FOR i = 0 TO upper
			n = upper - i
			IF array[string${n}] THEN final = i : EXIT FOR
		NEXT i
'
		SELECT CASE TRUE
			CASE (final < 0)	: string$ = ""
			CASE (final > 0)	: string$ = LEFT$ (string$, upper-final+1)
		END SELECT
	END IF
END FUNCTION
'
'
' ########################
' #####  XstTRIM ()  #####
' ########################
'
' error = XstTRIM (@string$, @array[])
'
' Trim characters from the both ends of a string as specified in the array[].
'
' string$ - character string supplied untrimmed and returned trimmed
' array[] - array indexed by the character number, with a zero value
'           for each character that is to be trimmed.
'
' See: TRIM$(), demo program "atrim.x"
'
FUNCTION  XstTRIM (@string$, array[])
'
	IFZ string$ THEN RETURN
'
	IFZ array[] THEN
		string$ = TRIM$ (string$)		' default
	ELSE
		type = TYPE (array[])
		upper = UBOUND (array[])
		IF (upper < 255) THEN RETURN -1
		IF ((type != $$SLONG) AND (type != $$ULONG) AND (type != $$XLONG)) THEN RETURN -1
'
		upper = UBOUND (string$)
		first = -1
		final = -1
'
		FOR i = 0 TO upper
			IF array[string${i}] THEN first = i : EXIT FOR
		NEXT i
'
		IF (first < 0) THEN			' trim all characters
			string$ = ""
			RETURN
		END IF
'
		FOR i = 0 TO upper
			n = upper - i
			IF array[string${n}] THEN final = i : EXIT FOR
		NEXT i
'
		IF (final < 0) THEN			' trim all characters
			string$ = ""
			RETURN
		END IF
'
		IFZ first THEN
			IF final THEN
				string$ = LEFT$ (string$, upper-final+1)
			END IF
		ELSE
			IFZ final THEN
				string$ = MID$ (string$, first+1)
			ELSE
				string$ = MID$ (string$, first+1, upper-final-first+1)
			END IF
		END IF
	END IF
END FUNCTION
'
'
' ##########################
' #####  XstParse$ ()  #####
' ##########################
'
' string$ = XstParse$ (source$, delimiter$, n)
'
' PURPOSE	: Parse$ returns the nth string in source$
'             separated with delimiter$.
' 					If a string is not found, the function
'             returns empty string "".
' 					The default delimiter is a space character.
' 					The delimiter character(s) are removed.
' IN			: source$, delimiter$, n
' OUT			: nth string in source$
' USE			: nthString$ = XstParse$ (myString$, ",", 4)
'
' See: XstParseStringToStringArray()
'      XstParseWhitespace()
'
FUNCTION  XstParse$ (source$, delimiter$, n)
'
	IFZ delimiter$ THEN delimiter$ = " "			' default delimiter is space " "
	IFZ n THEN n = 1
'
	c = XstTally (source$, delimiter$) 				' count number of delimiters
'
	IF (c == 0) THEN
		IF (n == 1) THEN
			RETURN source$
		ELSE
			RETURN ""
		END IF
	END IF
'
	IF n > c+1 THEN RETURN ""
'
	y = LEN (delimiter$)
	start = 0
	FOR i = 1 TO n
		x = INSTR (source$, delimiter$, start)
		start = x + y
		IF i = n-1 THEN begin = x
		IF i = n THEN end = x
	NEXT i
'
	IF n = 1 THEN
		s = 1
		length = end - begin - 1
	ELSE
		s = begin + y
		length = end - begin - y
	END IF
'
	RETURN MID$ (source$, s, length)
'
END FUNCTION
'
'
' ############################################
' #####  XstParseStringToStringArray ()  #####
' ############################################
'
' error = XstParseStringToStringArray (@source$, @delimiter$, @s$[])
'
' PURPOSE	: Parses a string and splits it into a string array
'						based on the specified delimiter. The default delimiter
'						is a space character. The delimiter string is not included
'						in s$[].
' IN			: source$, delimiter$
' OUT			: s$[]
' RETURN	: 0 on success, -1 on failure
'
' See: XstParseWhitespaceToArray()
'
FUNCTION  XstParseStringToStringArray (source$, delimiter$, @s$[])
'
	DIM s$[]
	IFZ source$ THEN RETURN ($$TRUE)
	IFZ delimiter$ THEN delimiter$ = " "
'
	lenSource = LEN(source$)
	count = XstTally (source$, delimiter$)
'
	IF count <= 0 THEN
		DIM s$[0]
		s$[0] = source$
		RETURN ($$TRUE)
	END IF
'
	DIM s$[count-1]
'
	start = 1
	l = LEN (delimiter$)
	x = 1
	i = 0
	DO WHILE x <> 0
		x = INSTR (source$, delimiter$, start)
		IF x > 0 THEN
			s$[i] = MID$(source$, start, x-start)
			INC i
			start = x + l
		END IF
	LOOP
'
' If the source$ does not finish with the delimiter string,
' add a line to the string array and put the remainder of
' the source$ in it.
'
	IF (start < lenSource) THEN
		REDIM s$[i]
		s$[i] = MID$(source$, start, lenSource-start+1)
	END IF
'
	RETURN ($$FALSE)
'
END FUNCTION
'
'
' ####################################
' #####  XstParseWhitespace$ ()  #####
' ####################################
'
' word$ = XstParseWhitespace$ (string$, wordNumber)
'
' All characters between pairs of double-quotes are kept in place
' as part of the word, including the double-quotes.
' Words start at the end of white-space, and end at the start of white-space,
' outside of double-quotes.
' Leading and trailing white-space is not part of the word.
'
' The first wordNumber is 1. If set to 0 word 1 will be returned.
'
' See: XstNextField$(), XstNextItem$()
'
FUNCTION  XstParseWhitespace$ (string$, wordNumber)
	SHARED UBYTE  charsetNotWhiteSpace[]
'
	IFZ charsetNotWhiteSpace[] THEN InitProgram()
	line$ = TRIM$(string$)
'
	IFZ line$ THEN RETURN ("")
	IFZ wordNumber THEN wordNumber = 1
	wordCount = 0
	inQuote = $$FALSE
	inWord  = $$FALSE
	inSpace = $$TRUE
	word$ = ""
	line$ = line$ + CHR$(32)  ' add dummy space at end of line
	uLine = UBOUND(line$)
'
	FOR i = 0 TO uLine
		chr = line${i}
		SELECT CASE charsetNotWhiteSpace[chr]
			CASE  0   : SELECT CASE TRUE                    ' white-space
										CASE inSpace  : DO NEXT
										CASE inQuote  : DO NEXT
										CASE inWord   : inSpace = $$TRUE
																		inWord  = $$FALSE
																		spaceStart = i
																		IF (wordCount >= wordNumber) THEN EXIT FOR
									END SELECT
'
			CASE 34   : SELECT CASE TRUE                    ' double-quote
										CASE inQuote  : inQuote = $$FALSE
																		inSpace = $$FALSE
																		inWord  = $$TRUE
										CASE inSpace  : inQuote = $$TRUE
																		inSpace = $$FALSE
																		inWord  = $$TRUE
																		wordStart = i
																		spaceStart = uLine
																		INC wordCount
										CASE inWord   : inQuote = $$TRUE
									END SELECT
'
			CASE ELSE : IF inSpace THEN
										inWord = $$TRUE
										inSpace = $$FALSE
										wordStart = i
										spaceStart = uLine
										INC wordCount
									END IF
		END SELECT
	NEXT i
	IF (wordCount == wordNumber) THEN
		word$ = MID$(line$, wordStart+1, spaceStart-wordStart)
	ELSE
		word$ = ""
	END IF
'
	RETURN word$
'
END FUNCTION
'
'
' ##########################################
' #####  XstParseWhitespaceToArray ()  #####
' ##########################################
'
' uWord = XstParseWhitespaceToArray (string$, @word$[])
'
' uWord is the upper bounds of word$[] array, UBOUND(word$[])
'
' All characters between pairs of double-quotes are kept in place
' as part of the word, including the double-quotes.
' Words start at the end of white-space, and end at the start of white-space,
' outside of double-quotes.
' Leading and trailing white-space is not part of the word.
'
FUNCTION  XstParseWhitespaceToArray (string$, word$[])
	SHARED UBYTE  charsetNotWhiteSpace[]
'
	IFZ charsetNotWhiteSpace[] THEN InitProgram()
	line$ = TRIM$(string$)
'
	IFZ line$ THEN
		DIM word$[]
		RETURN (-1)
	END IF
'
	count = XstTally (line$, CHR$(32))            ' count the spaces
	count = count + XstTally (line$, CHR$(09))    ' add the tabs
	IFZ count THEN count = 64
	DIM word$[count]
	wordCount = -1
	inQuote = $$FALSE
	inWord  = $$FALSE
	inSpace = $$TRUE
	word$ = ""
	line$ = line$ + CHR$(32)  ' add dummy space at end of line
'
	uLine = UBOUND(line$)
'
	FOR i = 0 TO uLine
		chr = line${i}
		SELECT CASE charsetNotWhiteSpace[chr]
			CASE  0   : SELECT CASE TRUE                    ' white-space
										CASE inSpace  : DO NEXT
										CASE inQuote  : DO NEXT
										CASE inWord   : inSpace = $$TRUE
																		inWord  = $$FALSE
																		spaceStart = i
																		IF (wordCount > count) THEN
																			count = count + 64
																			REDIM word$[count]
																		END IF
																		word$[wordCount] = MID$(line$, wordStart+1, spaceStart-wordStart)
									END SELECT
'
			CASE 34   : SELECT CASE TRUE                    ' double-quote
										CASE inQuote  : inQuote = $$FALSE
																		inSpace = $$FALSE
																		inWord  = $$TRUE
										CASE inSpace  : inQuote = $$TRUE
																		inSpace = $$FALSE
																		inWord  = $$TRUE
																		wordStart = i
																		spaceStart = uLine
																		INC wordCount
										CASE inWord   : inQuote = $$TRUE
									END SELECT
'
			CASE ELSE : IF inSpace THEN
										inWord = $$TRUE
										inSpace = $$FALSE
										wordStart = i
										spaceStart = uLine
										INC wordCount
									END IF
		END SELECT
	NEXT i
'
	IF (wordCount < count) THEN
		REDIM word$[wordCount]
	END IF
'
	RETURN (wordCount)
'
END FUNCTION
'
'
' #########################
' #####  XstTally ()  #####
' #########################
'
' count = XstTally (source$, find$)
'
' PURPOSE	: Tally () returns a count of all find$ in source$.
' IN			: find$, source$. Default find$ is space character.
' RETURN	: count on success, -1 on failure
'
FUNCTION  XstTally (source$, find$)
'
	IFZ source$ THEN RETURN -1
	IFZ find$ THEN find$ = " "
	count = 0
	start = 0
'
	l = LEN (find$)
	x = 1
	DO WHILE x <> 0
		x = INSTR (source$, find$, start)
		IF x > 0 THEN
			start = x + l
			INC count
		ENDIF
	LOOP
	RETURN count
'
END FUNCTION
'
'
' ##################################
' #####  XstCompareStrings ()  #####
' ##################################
'
' result = XstCompareStrings (addrString1, op, addrString2, flags)
'
'  addrString1 = address of first string to compare
'  op          = test operator; $$ZERO, $$EQ, $$NE, $$LT, $$LE, $$GE, $$GT
'  addrString2 = address of second string to compare
'  flags       = type of comparison; $$SortCaseInsensitive, $$SortAlphaNumeric
'
'  result = $$TRUE               if an error occurred, see ERROR()
'  result = $$FALSE              if comparison failed
'  result = $$EQ, $$LT or $$GT ; the actual successful result
'
FUNCTION  XstCompareStrings (addrString1, op, addrString2, flags)
	SHARED  UBYTE  caseless[]
	SHARED  UBYTE  numeric[]
	AUTOX  a$
	AUTOX  b$
'
	IFZ caseless[] THEN GOSUB Initialize
	IFZ numeric[] THEN GOSUB Initialize
'
' check for bad operation
'
	SELECT CASE op
		CASE $$ZERO, $$EQ, $$NE, $$LT, $$LE, $$GE, $$GT
		CASE ELSE	: ##ERROR = ($$ErrorObjectFunction << 8) OR $$ErrorNatureInvalidArgument : ##WHERE = 31740031
								RETURN ($$TRUE)
	END SELECT
'
	XLONGAT (&&a$) = addrString1
	XLONGAT (&&b$) = addrString2
'
' result
'   -1 means a < b
'    0 means a = b
'   +1 means a > b
'
	done = 0
	result = 0
	IFZ a$ THEN
		IFZ b$ THEN
			result = 0
			done = 1
		ELSE
			result = -1
			done = 1
		END IF
	ELSE
		IFZ b$ THEN
			result = +1
			done = 1
		END IF
	END IF
'
' if both a$ and b$ have contents then more work is required
'
	IFZ done THEN
		at = TYPE (a$)
		bt = TYPE (b$)
		IF (at != $$STRING) THEN
			##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidType : ##WHERE = 31740066
			RETURN ($$TRUE)
		END IF
		IF (bt != $$STRING) THEN
			##ERROR = ($$ErrorObjectArgument << 8) OR $$ErrorNatureInvalidType : ##WHERE = 31740070
			RETURN ($$TRUE)
		END IF
'
		aa = addrString1		' address of a$
		bb = addrString2		' address of b$
		ta = UBOUND (a$)		' high offset of a$
		tb = UBOUND (b$)		' high offset of b$
		ua = aa + ta				' high address of a$
		ub = bb + tb				' high address of b$
'
		a = 0
		b = 0
		oa = 0
		ob = 0
		DEC aa
		DEC bb
		DO WHILE ((aa < ua) AND (bb < ub))
			INC aa																	' address of next byte in a$
			INC bb																	' address of next byte in b$
			a = UBYTEAT(aa)													' a = next byte from a$
			b = UBYTEAT(bb)													' b = next byte from b$
			IF (flags AND $$SortAlphaNumeric) THEN	' numeric sensitive
				IF numeric[a] THEN										' a$ byte is numeric
					IF numeric[b] THEN									' b$ byte is numeric
						asig = 0													' 1st significant digit in a$
						bsig = 0													' 1st significant digit in b$
						adig = 0													' significant digits in a$
						bdig = 0													' significant digits in b$
						DO WHILE (aa <= ua)								'
							IFZ numeric[a] THEN EXIT DO			' not a numeric digit
							IFZ adig THEN										' significant digits
								IF (a != '0') THEN						' significant digit
									asig = aa										' first significant digit in a$
									INC adig										' first significant digit
								END IF												'
							ELSE														'
								INC adig											' another significant digit
							END IF													'
							INC aa													' next address
							a = UBYTEAT(aa)									' next byte
						LOOP															'
						aaa = a														' byte after numeric digits
						DO WHILE (bb <= ub)								'
							IFZ numeric[b] THEN EXIT DO			' not a numeric digit
							IFZ bdig THEN										' significant digits
								IF (b != '0') THEN						' significant digit
									bsig = bb										' first significant digit in b$
									INC bdig										' first significant digit
								END IF												'
							ELSE														'
								INC bdig											' another significant digit
							END IF													'
							INC bb													' next address
							b = UBYTEAT(bb)									' next byte
						LOOP															'
						bbb = b														' byte after numeric digits
						IF (adig != bdig) THEN						' # of significant digits not equal
							a = adig												' a to compare (trick)
							b = bdig												' b to compare (trick)
							EXIT DO													' done loop
						END IF														' values are equal
						FOR ndig = 1 TO adig							' for all significant digits
							a = UBYTEAT(asig)								' digit in a$
							b = UBYTEAT(bsig)								' digit in b$
							IF (a != b) THEN EXIT DO				' a$ digit != b$ digit
							INC asig												' address of next digit in a$
							INC bsig												' address of next digit in b$
						NEXT ndig
						a = aaa														' numeric values ARE equal,
						b = bbb														' so compare following bytes
					END IF
				END IF
			END IF																	'
			IF (flags AND $$SortCaseInsensitive) THEN
				a = caseless[a]												' a = upper case a byte
				b = caseless[b]												' b = upper case b byte
			END IF																	'
		LOOP WHILE (a == b)												' loop until a != b
'
' a$ != b$ or checked all characters in a$ or b$
'
		IF (a == b) THEN													' shorter string is less
			a = ta
			b = tb
		END IF
'
		SELECT CASE TRUE
			CASE (a < b)	:	result = -1 : done = 1		' a < b
			CASE (a > b)	: result = +1 : done = 1		' a > b
			CASE ELSE			: result =  0 : done = 1		' a = b
		END SELECT
	END IF
'
	XLONGAT (&&a$) = 0	' don't free string1 !!!
	XLONGAT (&&b$) = 0	' don't free string2 !!!
'
' return TRUE/FALSE depending on requested comparison op
'
	SELECT CASE TRUE
		CASE (result < 0)
					SELECT CASE op
						CASE $$ZERO		: return = $$LT
						CASE $$LT			: return = $$LT
						CASE $$LE			: return = $$LT
						CASE $$NE			: return = $$LT
						CASE $$EQ			: return = $$FALSE
						CASE $$GE			: return = $$FALSE
						CASE $$GT			: return = $$FALSE
					END SELECT
		CASE (result = 0)
					SELECT CASE op
						CASE $$ZERO		: return = $$EQ
						CASE $$LT			: return = $$FALSE
						CASE $$LE			: return = $$EQ
						CASE $$NE			: return = $$FALSE
						CASE $$EQ			: return = $$EQ
						CASE $$GE			: return = $$EQ
						CASE $$GT			: return = $$FALSE
					END SELECT
		CASE (result > 0)
					SELECT CASE op
						CASE $$ZERO		: return = $$GT
						CASE $$LT			: return = $$FALSE
						CASE $$LE			: return = $$FALSE
						CASE $$NE			: return = $$GT
						CASE $$EQ			: return = $$FALSE
						CASE $$GE			: return = $$GT
						CASE $$GT			: return = $$GT
					END SELECT
	END SELECT
	RETURN (return)
'
'
' *****  Initialize  *****
'
SUB Initialize
	DIM caseless[255]
	DIM numeric[255]
	FOR i = 0 TO 255
		caseless[i] = i
	NEXT i
	FOR i = 'a' TO 'z'
		caseless[i] = i-32		' "a" to "z" become "A" to "Z"
	NEXT i
	FOR i = '0' TO '9'
		numeric[i] = 'i'			' TRUE for all ascii numbers
	NEXT i
END SUB
END FUNCTION
'
'
' #############################
' #####  XstMatchWild ()  #####
' #############################
'
' matchPos = XstMatchWild (searchMe$, searchFor$, start, matchCase)
'
' Search searchMe$ for a match of searchFor$
'
' searchFor$ can have wildcard characters "*" and "?"
'            "**" and "*?" are changed to "*"
'
' matchCase = $$TRUE for a case sensitive search
'

' matchPos  = position of the first chacter of a match
'             or zero if no match was found.
'
FUNCTION  XstMatchWild (searchMe$, searchFor$, start, matchCase)
'
	IF matchCase THEN
		filter$ = searchFor$
		text$ = searchMe$
	ELSE
		filter$ = LCASE$(searchFor$)
		text$ = LCASE$(searchMe$)
	END IF
'
'
' Clean up filter$:	**	*?	\\	TO	*	*	\
'
	IF (LEFT$(filter$) != "*") THEN filter$ = "*" + filter$
	IF (RIGHT$(filter$) != "*") THEN filter$ = filter$ + "*"
	DO
		dstar = INSTR (filter$, "**")
		IF dstar THEN
			filter$ = LEFT$(filter$, dstar) + MID$(filter$, dstar + 2)
		END IF
		qstar = INSTR (filter$, "*?")
		IF qstar THEN
			filter$ = LEFT$(filter$, qstar) + MID$(filter$, qstar + 2)
		END IF
		dslash = INSTR (filter$, $$PathSlash$ + $$PathSlash$)
		IF dslash THEN
			filter$ = LEFT$(filter$, dslash) + MID$(filter$, dslash + 2)
		END IF
	LOOP UNTIL ((dstar + qstar + dslash) = 0)
'
' Now do the matching
'
	IFZ text$ THEN RETURN ($$FALSE)
	IFZ filter$ THEN RETURN ($$FALSE)
	IF (filter$ = "*") THEN RETURN (1)
'
	lenFilter = LEN(filter$)
	lenText = LEN(text$)
	matchPos = 0
	posFltr = 1
	posText = start
	IF (posText < 1) THEN posText = 1
	IF (posText > lenText) THEN RETURN ($$FALSE)
	DO UNTIL ((posFltr > lenFilter) OR (posText > lenText))
		fchar = filter${posFltr - 1}
		SELECT CASE fchar
			CASE '?':                                                      ' ? matches all
			CASE '*'
						IF (posFltr = lenFilter) THEN RETURN (matchPos)          ' Trailing * matches all
						INC posFltr
						fchar = filter${posFltr - 1}                             ' Note:  NOT *?
						match = INSTR(text$, CHR$(fchar), posText)
						IFZ match THEN RETURN ($$FALSE)
						posText = match
						IFZ matchPos THEN matchPos = match
						matchi = posFltr
			CASE ELSE
						cchar = text${posText - 1}
						IF (cchar == fchar) THEN
							IFZ matchPos THEN matchPos = posText
						ELSE
							IF match THEN
								posText = match + 1
								posFltr = matchi - 1
								matchPos = 0
								DO LOOP
							ELSE
								RETURN ($$FALSE)
							END IF
						END IF
		END SELECT
		INC posText
		INC posFltr
	LOOP
'
	IF (posText <= lenText) THEN matchPos = 0
	IF (posFltr < lenFilter) THEN matchPos = 0
	IF (posFltr == lenFilter) THEN
		IF (filter${posFltr - 1} != '*') THEN
			matchPos = 0
		END IF
	END IF
'
	RETURN (matchPos)
'
END FUNCTION
'
'
' #############################
' #####  XstQuickSort ()  #####
' #############################
'
' DIM n[1]  ' must exist (not empty) to be filled by XstQuickSort()
' error = XstQuickSort (@a[], @n[], low, high, mode)
'
' Input:
'   a[]   = 1D array of ANY simple type to be sorted
'   n[]   = array for sort indices (optional)
'             DIM n[] (empty) no indices returned
'             DIM n[1] (non-empty) indices are returned
'   low   = first index to sort (first line of a[] is 0)
'   high  = last index to sort  (last line of a[] is UBOUND(a[])
'   mode  = OR the appropriate mode constants together:
'              $$SortIncreasing    vs $$SortDecreasing
'              $$SortAlphabetic    vs $$SortAlphaNumeric
'              $$SortCaseSensitive vs $$SortCaseInsensitive
'
' Output:
'   a[]   = sorted data
'   n[]   = corresponding indices
'                   (if requested--n[1] = new index of old a[])
'
' Return:
'   $$TRUE  = error (##ERROR set)
'   $$FALSE = no error
'
' n[] is optional.  If it exists, it is redimensioned to match
'   a[] and filled with indices 0 TO UBOUND(a[]).
'   This array then tracks the sort of a[].
'   It is used as a secondary sort (increasing only) so that equal values of
'   a[] end up sorted by original index.
' If n[] is NULL, the indices are not tracked = a faster sort.
'
' To generate indices: DIM n[1]  (just make it non-NULL)
'                                (it returns with dimension of a[])
' To skip indices:     DIM n[]
'
FUNCTION  XstQuickSort (a[], n[], low, high, mode)
'
	IFZ a[] THEN RETURN ($$TRUE)
	IF (low < 0) THEN RETURN ($$TRUE)
	uA = UBOUND (a[])
	IF (high > uA) THEN RETURN ($$TRUE)
'
	theType = TYPE (a[])
	SELECT CASE theType
		CASE $$SBYTE, $$UBYTE, $$SSHORT, $$USHORT, $$SLONG, $$ULONG, $$XLONG
		CASE $$GIANT, $$SINGLE, $$DOUBLE, $$STRING
		CASE ELSE
					##ERROR = ($$ErrorObjectArray << 8) OR $$ErrorNatureInvalidType : ##WHERE = 31760051
					RETURN ($$TRUE)
	END SELECT
'
	IF n[] THEN
		DIM n[uA]
		FOR i = 0 TO uA
			n[i] = i
		NEXT i
	END IF
	IF high <= low THEN RETURN
'
	SELECT CASE theType
		CASE $$SLONG, $$XLONG
					XstQuickSort_XLONG (@a[], @n[], low, high, mode)
		CASE $$STRING
'					ATTACH a[] TO a$[]
'					XstQuickSort_STRING (@a$[], @n[], low, high, mode)
'					ATTACH a$[] TO a[]
'
' #####  v6.0010 : the following is taken from Window XBasic
'
					ATTACH a[] TO a$[]
					IFZ (mode AND $$SortAlphaNumeric) THEN
						IFZ (mode AND $$SortCaseInsensitive) THEN
							XstQuickSort_STRING (@a$[], @n[], low, high, mode)
						ELSE
							XstQuickSort_STRING_nocase (@a$[], @n[], low, high, mode)
						END IF
					ELSE
						XstQuickSort_NumericSTRING (@a$[], @n[], low, high, mode)
					END IF
					ATTACH a$[] TO a[]
		CASE $$SBYTE
					ATTACH a[] TO a@[]
					DIM a[uA]																				' convert to XLONG array
					FOR i = low TO high
						a[i] = a@[i]
					NEXT i
					XstQuickSort_XLONG (@a[], @n[], low, high, mode)
					FOR i = low TO high
						a@[i] = a[i]
					NEXT i
					DIM a[]
					ATTACH a@[] TO a[]
		CASE $$UBYTE
					ATTACH a[] TO a@@[]
					DIM a[uA]																				' convert to XLONG array
					FOR i = low TO high
						a[i] = a@@[i]
					NEXT i
					XstQuickSort_XLONG (@a[], @n[], low, high, mode)
					FOR i = low TO high
						a@@[i] = a[i]
					NEXT i
					DIM a[]
					ATTACH a@@[] TO a[]
		CASE $$SSHORT
					ATTACH a[] TO a%[]
					DIM a[uA]																				' convert to XLONG array
					FOR i = low TO high
						a[i] = a%[i]
					NEXT i
					XstQuickSort_XLONG (@a[], @n[], low, high, mode)
					FOR i = low TO high
						a%[i] = a[i]
					NEXT i
					DIM a[]
					ATTACH a%[] TO a[]
		CASE $$USHORT
					ATTACH a[] TO a%%[]
					DIM a[uA]																				' convert to XLONG array
					FOR i = low TO high
						a[i] = a%%[i]
					NEXT i
					XstQuickSort_XLONG (@a[], @n[], low, high, mode)
					FOR i = low TO high
						a%%[i] = a[i]
					NEXT i
					DIM a[]
					ATTACH a%%[] TO a[]
		CASE $$ULONG
					ATTACH a[] TO a&&[]
					DIM a$$[uA]
					FOR i = low TO high
						a$$[i] = a&&[i]
					NEXT i
					XstQuickSort_GIANT (@a$$[], @n[], low, high, mode)
					FOR i = low TO high
						a&&[i] = a$$[i]
					NEXT i
					ATTACH a&&[] TO a[]
		CASE $$GIANT
					ATTACH a[] TO a$$[]
					XstQuickSort_GIANT (@a$$[], @n[], low, high, mode)
					ATTACH a$$[] TO a[]
		CASE $$SINGLE
					ATTACH a[] TO a![]
					DIM a#[uA]
					FOR i = low TO high
						a#[i] = a![i]
					NEXT i
					XstQuickSort_DOUBLE (@a#[], @n[], low, high, mode)
					FOR i = low TO high
						a![i] = a#[i]
					NEXT i
					ATTACH a![] TO a[]
		CASE $$DOUBLE
					ATTACH a[] TO a#[]
					XstQuickSort_DOUBLE (@a#[], @n[], low, high, mode)
					ATTACH a#[] TO a[]
	END SELECT
END FUNCTION
'
' #########################
' #####  XstAbend ()  #####
' #########################
'
' XstAbend (errorMessage$)
'
' Stop XBasic with an error message
' Note: The runtime environment may not
' yet be initialized, so don't rely on it.
' errorMessage$	This message is printed.
'
FUNCTION  XstAbend (errorMessage$)
	PRINT "Fatal Error: "; errorMessage$
	##LOCKOUT = $$FALSE                        ' no lockout in XstAbend
	exit (0)
END FUNCTION
'
' #########################
' #####  XstAlert ()  #####
' #########################
'
' XstAlert (message$)
'
' Show a message
' Note: The runtime environment may not yet
' be initialized, so don't rely on it.
' message$	This message is printed.
'
FUNCTION  XstAlert (message$)
	' Sorry, no fancy popup available on linux
	PRINT message$
END FUNCTION
'
' #######################################
' #####  XstGetProgramFileName$ ()  #####
' #######################################
'
' file$ = XstGetProgramFileName$ ()
'
' Retrieve the full path and fileName of the executable
' return the full path and fileName of the executable.
'
' See: XstGetProgramName()
'
FUNCTION  XstGetProgramFileName$ ()
'
	XstGetApplicationEnvironment (@standalone, @reserved)
'
	IF (standalone || (##WHOMASK == 0)) THEN
		file$ = NULL$(256)
		ret = xb_getpfn(&file$, 256)
		file$ = LEFT$(file$, ret)
	ELSE
		XxxXitGetUserProgramName (@file$)
	END IF
	RETURN (file$)
END FUNCTION
'
' ################################
' #####  XstGetHomePath$ ()  #####
' ################################
'
' path$ = XstGetHomePath$ ()
'
' Retrieve the full path of the
' home-directory of the current user.
'
FUNCTION  XstGetHomePath$ ()
	path$ = NULL$(256)
	ret = xb_gethomepath(&path$, 256)
	IF ret < 0 THEN
		XstSystemErrorToError(xb_geterrno(), @error)
'		PRINT "XxxPathString$():error", error
		##ERROR = error : ##WHERE = 31800017
		RETURN ""
	END IF
	path$ = LEFT$(path$, ret)
	RETURN path$
'
END FUNCTION
'
'
' ####################
' #####  Xio ()  #####
' ####################
'
FUNCTION  Xio ()
	STATIC  entry
'
	IF entry THEN RETURN
	entry = $$TRUE
'
'	XstLog ("Xio().Xgr()")
	Xgr ()										' GUI version
'	XstLog ("Xio().Xui()")
	Xui ()										' GUI version
'	XstLog ("Xio().InitGui()")
	InitGui ()								' GUI version
'	XstLog ("Xio().Z")
END FUNCTION
'
'
' ###############################
' #####  XxxXstBlowback ()  #####
' ###############################
'
FUNCTION  XxxXstBlowback ()
	SHARED  TIMER  timer[]
	SHARED  TASK   task[]
	SHARED  userProgram$
	SHARED  userTaskGrid
	SHARED  userTaskWindow
	SHARED  prefWhomask[]
'
	userProgram$ = ""
'
	FOR i = 0 TO UBOUND (task[])
		IF task[i].taskFunc THEN
			IF task[i].whomask THEN
				XstKillTask (i)
			END IF
		END IF
	NEXT i
'
	FOR i = 0 TO UBOUND (timer[])
		IF timer[i].timer THEN
			IF timer[i].whomask THEN
				tgrid = timer[i].tgrid
				XxxXstTimer ($$TimerKill, tgrid, i, 0, 0, 0)
			END IF
		END IF
	NEXT i
'
	FOR i = 0 TO UBOUND (prefWhomask[])
		IF prefWhomask[i] THEN
			##WHOMASK = prefWhomask[i]
			XstDiscardPref (i+1)
			##WHOMASK = 0
		END IF
	NEXT i
'
	userTaskGrid = 0
	userTaskWindow = 0
END FUNCTION
'
'
' ##################################
' #####  XxxXstFreeLibrary ()  #####
' ##################################
'
FUNCTION  XxxXstFreeLibrary (lib$, handle)
'	SHARED  libraryName$[]
'	SHARED  libraryHandle[]
'
' not yet implemented on UNIX  -  need ELF for true DLLs
'
'	IFZ libraryName$[] THEN RETURN
'	upper = UBOUND (libraryName$[])
'
'	FOR i = 0 TO upper
'		name$ = libraryName$[i]
'		hand = libraryHandle[i]
'		free = $$FALSE
'		IF name$ THEN
'			IF hand THEN
'				SELECT CASE TRUE
'					CASE (handle = -1)		:	free = $$TRUE
'					CASE (handle = hand)	:	free = $$TRUE
'					CASE (lib$ = name$)		:	free = $$TRUE
'				END SELECT
'			END IF
'		END IF
'		IF free THEN
'			FreeLibrary (hand)
'			libraryName$[i] = ""
'			libraryHandle[i] = 0
'		END IF
'	NEXT i
END FUNCTION
'
'
' ##################################
' #####  XxxXstLoadLibrary ()  #####
' ##################################
'
FUNCTION  XxxXstLoadLibrary (lib$)
'	SHARED  libraryName$[]
'	SHARED  libraryHandle[]
'
' not yet implemented on UNIX  -  need ELF for true DLLs
'
'	whomask = ##WHOMASK
'	IFZ lib$ THEN RETURN
'
'	upper = UBOUND (lib$)
'	IF (lib${upper} = '"') THEN lib$ = RCLIP$ (lib$,1)
'	IF (lib${0} = '"') THEN lib$ = LCLIP$ (lib$,1)
'
'	IFZ libraryName$[] THEN GOSUB Initialize
'	upper = UBOUND (libraryName$[])
'	handle = 0
'	slot = -1
'
'	FOR i = 0 TO upper
'		name$ = libraryName$[i]
'		hand = libraryHandle[i]
'		IF (slot < 0) THEN
'			IFZ name$ THEN slot = i : hand = 0
'			IFZ hand THEN slot = i : name$ = ""
'		END IF
'		IFZ handle THEN
'			IF name$ THEN
'				IF hand THEN
'					IF (lib$ = name$) THEN handle = hand
'				END IF
'			END IF
'		END IF
'	NEXT i
'
'	IF handle THEN RETURN (handle)
'
'	handle = LoadLibraryA (&lib$)		' returns 0 when fails
'
'	IF handle THEN
'		IF (slot < 0) THEN
'			##WHOMASK = 0
'			slot = upper + 1
'			upper = upper + 16
'			REDIM libraryName$[upper]
'			REDIM libraryHandle[upper]
'			##WHOMASK = whomask
'		END IF
'		##WHOMASK = 0
'		libraryName$[slot] = lib$
'		libraryHandle[slot] = handle
'		##WHOMASK = whomask
'	END IF
'
'	RETURN (handle)
'
'
' *****  Initialize  *****
'
SUB Initialize
'	##WHOMASK = 0
'	DIM libraryName$[15]
'	DIM libraryHandle[15]
'	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ############################
' #####  XxxXstTimer ()  #####
' ############################
'
' routine is complicated by the fact that two different
' ways of keeping time: UITIMERVAL is a timer interval,
' and UTIMEB is time since 00:00:00 on 1 Jan 1970.
'
' commands	:	$$TimerStart	: XstStartTimer()
'							$$TimerExpire	: PDE received alarm signal (interrupt)
'							$$TimerKill		: XstKillTimer()
'
FUNCTION  XxxXstTimer (command, tgrid, timer, count, msec, func)
	SHARED  sleepUser
	SHARED  sleepSystem
	SHARED  UTIMEB  startTime
	STATIC  UITIMERVAL  itimer
	STATIC  UITIMERVAL  otimer
	SHARED  TIMER  timer[]
	STATIC  TIMER  ztimer
	STATIC  unique
	STATIC  inTimer
	STATIC  timerExpire
	STATIC  UTIMEB  nowTime
	AUTOX  FUNCADDR  tcall (XLONG, XLONG, XLONG, XLONG, XLONG) ' tcall when tgrid is non-zero
	AUTOX  FUNCADDR  call (XLONG, XLONG, XLONG, XLONG)         ' call when tgrid is zero XstStartTimer()
'
' It is important that the declarations for variables in this function does not cause dynamic memory
' allocation on entry and that a $$TimerExpire command is processed completely without doing dynamic
' memory allocation. This can be achieved by making sure all arrays[] are STATIC or SHARED and that
' arrays[] are DIM or REDIM only when a $$TimerStart or $$TimerKill is processed.
' If another XBasic function is allocating memory at the instant a timer interrupt occurres, and the
' process of handling the interrupt does another memory allocation on top of it, an error can result.
'
'
' inTimer is TRUE when a command is in progress. If a timer interrupt sends a $$TimerExpire command
' when a command is already in progress, it will just increment timerExpire and return.
' After inTimer is set to FALSE, timerExpire is checked and if it is set, do a $$TimerExpire command.
'
'		XxxLog10 ("XxxXstTimer(AAA)", 0, ##CONGRID, 0, command, tgrid, timer, count, msec, func)
'
'	IF ##INMEM THEN
'		XstLog ("XxxXstTimer(45)")
'	END IF
	IF inTimer THEN
		IF (command == $$TimerExpire) THEN
			IF (timerExpire < 0) THEN timerExpire = 0
			INC timerExpire
			RETURN
		ELSE
			'
			' $$TimerStart and $$TimerKill are not allowed while another command is in progress.
			' Do not print message if command is from the console grid so that it does not print endlessly.
			'
			IF (tgrid <> ##CONGRID) THEN
				IF (inTimer == $$TimerExpire) THEN
					SELECT CASE command
						CASE $$TimerStart:PRINT "XxxXstTimer():Error:TimerStart while expire in progress",inTimer,command,tgrid,timer,count,msec,HEXX$(func)
						CASE $$TimerKill :PRINT "XxxXstTimer():Error:TimerKill while expire in progress",inTimer,command,tgrid,timer,count,msec,HEXX$(func), HEXX$(call)
						CASE ELSE        :PRINT "XxxXstTimer():Error:Timer command while other in progress",inTimer,command,tgrid,timer,count,msec,HEXX$(func)
					END SELECT
				ELSE
					PRINT "XxxXstTimer():Error:Timer command while other in progress",inTimer,command,tgrid,timer,count,msec,HEXX$(func)
				END IF
			END IF
			IF (command == $$TimerStart) THEN timer = 0
			RETURN ($$TRUE)
		END IF
	END IF
	inTimer = command
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN
		IF ##XBDV THEN XxxLog2 ("XxxXstTimer()lockout", lockout)
	END IF
'
	log = ##DEBUG OR $$DebugTimer
'
' initialize timer array if necessary
'
	IFZ timer[] THEN
		##WHOMASK = 0
		DIM timer[15]
		##WHOMASK = whomask
	END IF
	upper = UBOUND (timer[])					' upper bound of timer[]
'
' get zero reference time for free-running millisecond system timer
'
	IFZ startTime.time THEN
		##WHOMASK = 0
		##LOCKOUT = 300030
		ftime (&startTime)
		##WHOMASK = whomask
		##LOCKOUT = lockout
	END IF
'
' get current time
'
	##WHOMASK = 0
	##LOCKOUT = 300031
	ftime (&nowTime)
	##WHOMASK = whomask
	##LOCKOUT = lockout
'
' "nsec" and "nusec" are the current system time from ftime()
'
	nsec = nowTime.time								' current time - seconds
	nusec = nowTime.millitm * 1000		' current time - microseconds
'
	IF (nsec < 0) THEN nsec = nsec + 0x7FFFFFFF
	IF (nusec < 0) THEN nusec = 0
	IF (nusec > 999999) THEN
		nsec = nsec + 1
		nusec = 0
	END IF
'
' process the command
'
	SELECT CASE command
		CASE $$TimerExpire	: GOSUB TimerExpire
		CASE $$TimerStart		: GOSUB TimerStart
		CASE $$TimerKill		: GOSUB TimerKill
		CASE ELSE						: PRINT "XxxXstTimer() : error : unknown command : "; command
	END SELECT
'
	inTimer = $$FALSE  ' indicate finished processing command
'
' If a timer interrupt has occurred while processing a timer command, timerExpire will
' be incremented. If so, do the $$TimerExpire command now.
' The timerExpire count should never get greater than one.
'
	IF timerExpire THEN
		DEC timerExpire
		lockout = ##LOCKOUT
		##LOCKOUT = $$FALSE          '##LOCKOUT false while ##TIMERLOCOUT true
		##TIMERLOCKOUT = $$TRUE
		XxxXstTimer ($$TimerExpire, 0, 0, 0, 0, 0)
		##TIMERLOCKOUT = $$FALSE
		##LOCKOUT = lockout
'		PRINT "\nXxxXstTimer():Detected a timerExpire:command =", command
'		IF timerExpire THEN PRINT "XxxXstTimer():More than one timerExpire =", timerExpire
	END IF
'
'	IF (command == $$TimerExpire) THEN
'		#tOut = atimer
'	ELSE
'		XxxLog10 ("XxxXstTimer(ZZZ)", atimer, ##CONGRID, 0, command, tgrid, timer, timer[0].tgrid, timer[1].tgrid, timer[2].tgrid)
'		#tOut = 0
'	END IF
'
	RETURN (return)
' -----------------------------------------------------------------------------------------------
'
'
' *****  TimerStart  *****
'
SUB TimerStart
	IFZ func THEN return = $$TRUE : EXIT SUB				' invalid func argument
	IFZ count THEN return = $$TRUE : EXIT SUB				' invalid count argument
	IF (msec <= 0) THEN return = $$TRUE : EXIT SUB	' invalid interval argument
'
' unix needs the interval in two pieces:
'  sec  : integer number of seconds
'  usec : additional microseconds
'
	sec = msec \ 1000									' integer seconds until expire
	isec = sec * 1000									' 1000 * integer seconds until expire
	usec = (msec - isec) * 1000				' additional microseconds until expire
'
' compute sec/usec of desired timeout and add new timer to timer[]
'
	GOSUB AddTimer										' add new timer to timer[]
	IF return THEN EXIT SUB						' error in AddTimer
	GOSUB StartSoonestTimer						' start soonest timer
'	PRINT "XxxXstTimer() : TimerStart.Z : "; timer;; count;; msec;; HEX$(func,8);; atimer;; active
END SUB
'
'
' *****  StartSoonestTimer  *****
'
SUB StartSoonestTimer
	##WHOMASK = 0
	##LOCKOUT = 300032
	getitimer ($$ITIMER_REAL, &otimer)		' get current timer value
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
' find out which timer is active and which has soonest requested timeout
'
	active = $$FALSE									' active timer #
	osec = otimer.it_value.tv_sec			' timout in seconds
	ousec = otimer.it_value.tv_usec		' timout in microseconds
	GOSUB GetSoonestTimer							' atimer = timer with soonest timeout
'
' atimer should never be zero since we just added a timer
'
	IFZ atimer THEN
		return = $$FALSE
		EXIT SUB
	END IF
'
' done if system interval timer is already running the soonest timer
'
	IF (atimer = active) THEN					' soonest = active
		IFZ timer[atimer].active THEN
			PRINT "XxxXstTimer() : StartSoonestTimer : error : (atimer = active : .active = 0)"
			return = $$TRUE
			EXIT SUB
		END IF
		return = $$FALSE
		EXIT SUB
	END IF
'
' system interval timer should be running the active timer
'
	IF active THEN
		IFZ (osec OR ousec) THEN	' error : system timer should be running
			PRINT "XxxXstTimer() : StartSoonestTimer : error ::: (active with no system timer)"
		END IF
	ELSE
		IF (osec OR ousec) THEN		' error : system timer should not be running
			PRINT "XxxXstTimer() : StartSoonestTimer : error ::: (system timer with no active)"
		END IF
	END IF
'
' old active timer is no longer the active timer - new one is sooner
'
	timer[active].active = $$FALSE		' old active timer no longer active
'
' program system interval timer with new timeout interval
'
	xsec = asec - nsec								' new interval - seconds
	xusec = ausec - nusec							' new interval - microseconds
'
	IF (xusec < 0) THEN								' adjust for microseconds borrow
		xusec = xusec + 1000000					'   add a million microseconds
		xsec = xsec - 1									'   and subtract one second
	END IF
'
' don't program system timer with less than one millisecond
'
	SELECT CASE TRUE
		CASE (xsec < 0)		: xsec = 0 : xusec = 1000
		CASE (xsec = 0)		: IF (xusec < 1000) THEN xusec = 1000
	END SELECT
'
' xsec,xusec is now at least 1000 usec = 1ms
'
	itimer.it_interval.tv_sec = 0			' no reload - must handle manually
	itimer.it_interval.tv_usec = 0		' no reload - must handle manually
	itimer.it_value.tv_sec = xsec			' integer seconds until expire
	itimer.it_value.tv_usec = xusec		' additional microseconds
	timer[atimer].active = atimer			' new active timer
'
' start the new interval timer - don't really need old value back
'
	##WHOMASK = 0
	##LOCKOUT = 300033
	error = setitimer ($$ITIMER_REAL, &itimer, &otimer)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
		XstErrorNumberToName (error, @error$)
		PRINT "XxxXstTimer() : StartSoonestTimer : error : (setitimer() error) : "; xb_geterrno();; error;; error$
		return = $$TRUE
	ELSE
		return = $$FALSE
	END IF
END SUB
'
'
' *****  TimerExpire  *****
'
SUB TimerExpire
	active = $$FALSE									' active timer #
	GOSUB GetSoonestTimer							' atimer = timer with soonest timeout
	IF return THEN EXIT SUB						' error in GetSoonestTimer
'
' should never have timer alarm if no timer is active
'
	IFZ active THEN
		IF XBDV THEN PRINT "XxxXstTimer() : error : ($$TimerExpire without active timer) : "; active
		return = $$TRUE
		EXIT SUB
	END IF
'
' should be no way the active timer isn't the timer to expire soonest
'
	IF (active != atimer) THEN
		PRINT "XxxXstTimer() : error : ($$TimerExpire with active != atimer) : "; active;; atimer
		return = $$TRUE
		EXIT SUB
	END IF
'
' active timer expired - update timer and call timer callback function
'
	timer = active
	GOSUB TimerExpired
END SUB
'
'
' *****  TimerExpired  *****
'
' active timer expired
' decrement timer count
' kill timer if count = 0
' start next soonest timer
' call timer callback function
'
SUB TimerExpired
	tmsec = nowTime.millitm - startTime.millitm
	tsec = nowTime.time - startTime.time
'
	IF (tmsec < 0) THEN
		tmsec = tmsec + 1000
		tsec = tsec - 1
	END IF
'
	IF (tsec < 0) THEN
		tmsec = 1
		tsec = 0
	END IF
'
' set up timer callback arguments
'
	time = (tsec * 1000) + tmsec						' millisecond time
	count = timer[timer].count - 1					' one less timeout
	msec = timer[timer].msec								' programmed delay
	func = timer[timer].func								' callback function
	who = timer[timer].whomask							'
	tgrid = timer[timer].tgrid							' timing grid number if XgrSetGridTimer()
'
' terminate any system/user XstSleep() in progress
'
	IFZ who THEN sleepSystem = $$FALSE ELSE sleepUser = $$FALSE
'
'	call the expired timer callback function - !!!!! timer whomask !!!!!
'
	IFZ (func) THEN
		count = 0
	ELSE
		uuu = timer[timer].timer
		##WHOMASK = who
		IF tgrid THEN
			tcall = func
			kill = @tcall (tgrid, timer, @count, @msec, time)   ' allow msec to be altered
		ELSE
			##LOCKOUT = 300034
			call = func
			kill = @call (timer, @count, msec, time)
		END IF
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
' (count <= 0) : kill expired timer
' (count > 0) : update expired timer with new count and next expire time
'
	IF (uuu = timer[timer].timer) THEN	' timer not killed by called func
		IF (kill == -1) THEN count = 0
		IF (count <= 0) THEN
'			write (1, &"D", 1)
			timer[timer] = ztimer							' kill timer
		ELSE
			sec = msec \ 1000									' integer seconds of interval
			isec = sec * 1000									' 1000 * integer seconds of interval
			usec = (msec - isec) * 1000				' additional microseconds of interval
'
			xsec = sec + timer[timer].sec     ' time to expire next - seconds
			xusec = usec + timer[timer].usec  ' time to expire next - microseconds
'
			IF (xusec >= 1000000) THEN				' 1 million microseconds = 1 second
				xusec = xusec - 1000000					' subtract 1 million microseconds
				xsec = xsec + 1									' and add 1 second
			END IF
'
			timer[timer].count = count				' decremented or updated count
			timer[timer].sec = xsec						' time to expire next - seconds
			timer[timer].usec = xusec					' time to expire next - microseconds
			timer[timer].active = $$FALSE			' no longer active - find another
		END IF
	END IF
'
' start soonest timer
'
	GOSUB StartSoonestTimer
END SUB
'
'
' *****  TimerKill  *****
'
SUB TimerKill
'	PRINT "XxxXstTimer().A : TimerKill : "; timer
	IF (timer <= 0) THEN
		PRINT "XxxXstTimer() : TimerKill : error : invalid timer : (timer <= 0) : "; timer
		return = $$TRUE
		EXIT SUB
	END IF
'
	IF (timer > upper) THEN
		PRINT "XxxXstTimer() : TimerKill : error : invalid timer : (timer > upper) : "; timer
		return = $$TRUE
		EXIT SUB
	END IF
'
'
	IFZ timer[timer].active THEN		' done if timer is not active timer
		timer[timer] = ztimer						' kill the timer
		return = $$FALSE
		EXIT SUB
	END IF
'
	IF (timer[timer].tgrid <> tgrid) THEN PRINT "XxxXstTimer():TimerKill tgrid mismatch", tgrid, timer[timer].tgrid
'
' cancel the system interval timer if timer was the active timer
'
	timer[timer] = ztimer							' kill the timer
	itimer.it_interval.tv_sec = 0			' no reload - must handle manually
	itimer.it_interval.tv_usec = 0		' no reload - must handle manually
	itimer.it_value.tv_sec = 0				' integer seconds until expire
	itimer.it_value.tv_usec = 0				' additional microseconds
'
' cancel the system interval timer
'
	##WHOMASK = 0
	##LOCKOUT = 300035
	error = setitimer ($$ITIMER_REAL, &itimer, &otimer)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF error THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		XstErrorNumberToName (error, @error$)
		PRINT "XxxXstTimer() : TimerKill : error : (setitimer() error) : "; xb_geterrno();; error;; error$
		return = $$TRUE
	ELSE
		return = $$FALSE
	END IF
'
' next timer to start is the soonest timer
'
	GOSUB GetSoonestTimer
'	PRINT "XxxXstTimer().Z : TimerKill : "; timer
END SUB
'
'
' *****  AddTimer  *****  enter with expire interval in "sec", "usec"
'
SUB AddTimer
	FOR timer = 1 TO upper
		IFZ timer[timer].timer THEN EXIT FOR
	NEXT timer
'
	IF (timer > upper) THEN
		##WHOMASK = 0
		##LOCKOUT = 300036
		upper = upper + 16
		REDIM timer[upper]
		##LOCKOUT = lockout
		##WHOMASK = whomask
	END IF
'
	xusec = nusec + usec							' expire time - microseconds
	xsec = nsec + sec									' expire time - seconds
	IF (xusec > 1000000) THEN					' 1 million microseconds = 1 second
		xusec = xusec - 1000000					' remove 1 million microseconds
		xsec = xsec + 1									' add 1 second
	END IF
'
' set the new interval timer info
'
	INC unique
	timer[timer].tgrid = tgrid        ' timing grid if from XgrSetGridTimer()
	timer[timer].timer = unique				' enables timer
	timer[timer].count = count				' # of timeouts desired
	timer[timer].func = func					' timer callback function
	timer[timer].msec = msec					' timer interval in milliseconds
	timer[timer].sec = xsec						' ftime() expire time seconds
	timer[timer].usec = xusec					' ftime() expire time microseconds
	timer[timer].active = $$FALSE			' not yet the running timer
	timer[timer].whomask = whomask		' whomask of timer owner
END SUB
'
'
' *****  GetSoonestTimer  *****  !!! DO NOT CHANGE VARIABLE "timer" !!!
'
SUB GetSoonestTimer
	asec = 0
	ausec = 0
	atimer = 0
	active = $$FALSE
	FOR qtimer = 1 TO upper
		IF timer[qtimer].timer THEN
			IF timer[qtimer].active THEN active = qtimer
			qusec = timer[qtimer].usec
			qsec = timer[qtimer].sec
			IF (qsec OR qusec) THEN
				IFZ atimer THEN													' soonest
					asec = qsec
					ausec = qusec
					atimer = qtimer
				ELSE
					SELECT CASE TRUE
						CASE (qsec < asec)									' new soonest
									asec = qsec
									ausec = qusec
									atimer = qtimer
						CASE (qsec = asec)									' maybe new soonest
									SELECT CASE TRUE
										CASE (qusec < ausec)				' new soonest
													atimer = qtimer
													ausec = qusec
													asec = qsec
										CASE (qusec = ausec)				' tie - choose active
													IF (active != atimer) THEN
														atimer = qtimer
														ausec = qusec
														asec = qsec
													END IF
									END SELECT
					END SELECT
				END IF
			END IF
		END IF
	NEXT qtimer
END SUB
'
END FUNCTION
'
'
' ##########################
' #####  XxxXstLog ()  #####
' ##########################
'
FUNCTION  XxxXstLog (text$)
'
	IFZ ##XBDV THEN RETURN ($$FALSE)    '*cw-xbdv* for testing
	IFZ text$  THEN RETURN ($$FALSE)
'
'	bytes = LEN (text$)
'	write (1, &text$, bytes)						' print text$ on UNIX console
'
	XstLog (text$)                      '*cw-xbdv* for testing
'
END FUNCTION
'
'
' ############################
' #####  InitProgram ()  #####
' ############################
'
FUNCTION  InitProgram ()
	SHARED UBYTE  charsetBackslash[]
	SHARED UBYTE  charsetBackslashChar[]
	SHARED UBYTE  charsetHexLowerToUpper[]
	SHARED UBYTE  charsetNormalChar[]
	SHARED UBYTE  charsetNotWhiteSpace[]
	SHARED UBYTE  charsetUpperToLower[]
	SHARED UBYTE  charsetWithinWord[]
	SHARED	exception$[]
	SHARED	sysException$[]
	SHARED	errorObject$[]
	SHARED	errorNature$[]
	SHARED  sysSaveNewline
	SHARED  sysPasteNewline
	SHARED  userSaveNewline
	SHARED  userPasteNewline
'
	whomask = ##WHOMASK
	##WHOMASK = $$FALSE
'
	DIM charsetBackslash[255]
	DIM charsetBackslashChar[255]
	DIM charsetHexLowerToUpper[255]
	DIM charsetNormalChar[255]
	DIM charsetNotWhiteSpace[255]
	DIM charsetUpperToLower[255]
	DIM charsetWithinWord[255]
	DIM exception$[31]
	DIM sysException$[63]
	DIM errorObject$[255]
	DIM errorNature$[255]
	DIM #OSERROR$[$$ERROR_LAST_OS_ERROR]
	DIM #OSTOXERROR[$$ERROR_LAST_OS_ERROR]
'
	sysSaveNewline = $$NewlineDefault
	sysPasteNewline = $$NewlineDefault
	userSaveNewline = $$NewlineDefault
	userPasteNewline = $$NewlineDefault
'
	XstGetEnvironmentVariables (@count, @var$[])	' initialize envp, envp$[]
	XstGetOSName (@os$)
	linux = INSTRI (os$, "linux")
	unix = INSTRI (os$, "unix")
'
'
' ********************************  \a  \b  \d  \f  \n  \r  \v  \\  \"  \z
' *****  charsetBackslash[]  *****  \0 - \V
' ********************************  (others unchanged)
'
' Convert character following a \ into the proper binary value
' For all characters without special binary values, return the character
'
	offset = 10 - 'A'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):		charsetBackslash[i] = i - '0'
			CASE ((i >= 'A') AND (i <= 'V')):		charsetBackslash[i] = i + offset
			CASE ELSE:													charsetBackslash[i] = i
		END SELECT
	NEXT i
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE '\\':	charsetBackslash[i] = 0x5C		' backslash
			CASE '"':		charsetBackslash[i] = 0x22		' double-quote
			CASE 'a':		charsetBackslash[i] = 0x07		' alarm (bell)
			CASE 'b':		charsetBackslash[i] = 0x08		' backspace
			CASE 'd':		charsetBackslash[i] = 0x7F		' delete
			CASE 'e':		charsetBackslash[i] = 0x1B		' escape
			CASE 'f':		charsetBackslash[i] = 0x0C		' form-feed
			CASE 'n':		charsetBackslash[i] = 0x0A		' newline
			CASE 'r':		charsetBackslash[i] = 0x0D		' return
			CASE 't':		charsetBackslash[i] = 0x09		' tab
			CASE 'v':		charsetBackslash[i] = 0x0B		' vertical-tab
			CASE 'z':		charsetBackslash[i] = 0xFF		' finale  (highest UBYTE)
		END SELECT
	NEXT i
'
'
' ************************************  \a  \b  \d  \e  \f  \n  \r  \t  \v
' *****  charsetBackslashChar[]  *****  \\  \"
' ************************************
'
' Return printable character intended to follow \ backslash character
' Return bytes that are normal, printable, non-backslash characters
'
	FOR i = 0 TO 255
		SELECT CASE i
			CASE 0x5C:	charsetBackslashChar[i] = '\\'	' backslash
			CASE 0x22:	charsetBackslashChar[i] = '"'		' double-quote
			CASE 0x07:	charsetBackslashChar[i] = 'a'		' alarm (bell)
			CASE 0x08:	charsetBackslashChar[i] = 'b'		' backspace
			CASE 0x7F:	charsetBackslashChar[i] = 'd'		' delete
			CASE 0x1B:	charsetBackslashChar[i] = 'e'		' escape
			CASE 0x0C:	charsetBackslashChar[i] = 'f'		' form-feed
			CASE 0x0A:	charsetBackslashChar[i] = 'n'		' newline
			CASE 0x0D:	charsetBackslashChar[i] = 'r'		' return
			CASE 0x09:	charsetBackslashChar[i] = 't'		' tab
			CASE 0x0B:	charsetBackslashChar[i] = 'v'		' vertical-tab
			CASE ELSE:	charsetBackslashChar[i] = 0			' not a backslash char
		END SELECT
	NEXT i
'
'
' **************************************  0-9
' *****  charsetHexLowerToUpper[]  *****  a-f  ==>>  A-F  (others 0)
' **************************************  A-F
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= '0') AND (i <= '9')):		charsetHexLowerToUpper[i] = i
			CASE ((i >= 'A') AND (i <= 'F')):		charsetHexLowerToUpper[i] = i
			CASE ((i >= 'a') AND (i <= 'f')):		charsetHexLowerToUpper[i] = i - 32
			CASE ELSE:													charsetHexLowerToUpper[i] = 0
		END SELECT
	NEXT i
'
'
' *********************************  0x00 - 0x1F  ===>>  0
' *****  charsetNormalChar[]  *****  0x7F - 0xFF  ===>>  0  (others unchanged)
' *********************************   \  and  "   ===>>  0
'
' Normal printable characters = the character, all others = 0
' NOTE:  tab, newline, etc... not considered normal printable characters
' NOTE:  backslash not considered normal printable character (need \\)
' NOTE:  double-quote not considered normal printable character (need \")
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <= 0x1F)	:	charsetNormalChar[i] = 0		' control characters
			CASE (i == 0x22)	:	charsetNormalChar[i] = 0		' " = double-quote character
			CASE (i == 0x5C)	: charsetNormalChar[i] = 0		' \ = backslash character
			CASE (i >= 0x7F)	:	charsetNormalChar[i] = i		' non-English characters
			CASE ELSE					: charsetNormalChar[i] = i		' all English characters
		END SELECT
	NEXT i
'
' For United States and Canadian English, make non-English characters backslash
'
	XstGetEnvironmentVariable ("LANG", @value$)
	value$ = LEFT$(value$,5)
	IF ((value$ == "en_US") || (value$ == "en_CA")) THEN
		FOR i = 128 TO 255
			charsetNormalChar[i] = 0   ' non-English characters backslash
		NEXT i
	END IF
'
'
' ************************************
' *****  charsetNotWhiteSpace[]  *****
' ************************************
'
' WhiteSpace characters = 0
' NOTE: tab, newline, and control characters considered WhiteSpace characters
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE (i <= 0x1F)	:	charsetNotWhiteSpace[i] = 0		' control characters
			CASE (i <= 0x20)	:	charsetNotWhiteSpace[i] = 0		' space character
			CASE (i >= 0x7F)	:	charsetNotWhiteSpace[i] = i		' non-English characters
			CASE ELSE					: charsetNotWhiteSpace[i] = i		' all English characters
		END SELECT
	NEXT i
'
'
' ***********************************
' *****  charsetUpperToLower[]  *****  A-Z  ==>>  a-z  (others unchanged)
' ***********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetUpperToLower[i] = i + 32
			CASE ELSE:                          charsetUpperToLower[i] = i
		END SELECT
	NEXT i
'
'
' *********************************
' *****  charsetWithinWord[]  *****
' *********************************
'
	FOR i = 0 TO 255
		SELECT CASE TRUE
			CASE ((i >= 'A') AND (i <= 'Z')):   charsetWithinWord[i] = $$TRUE
			CASE ((i >= 'a') AND (i <= 'z')):   charsetWithinWord[i] = $$TRUE
			CASE ((i >= '0') AND (i <= '9')):   charsetWithinWord[i] = $$TRUE
			CASE (i == '$') : charsetWithinWord[i] = $$TRUE
			CASE (i == '#') : charsetWithinWord[i] = $$TRUE
			CASE (i == '_') : charsetWithinWord[i] = $$TRUE
			CASE ELSE:                          charsetWithinWord[i] = $$FALSE
		END SELECT
	NEXT i
'
'
' ***********************************************
' *****  Initialize Native Exception Names  *****
' ***********************************************
'
	exception$ [ $$ExceptionNone                   ] = "$$ExceptionNone"
	exception$ [ $$ExceptionSegmentViolation       ] = "$$ExceptionSegmentViolation"
	exception$ [ $$ExceptionOutOfBounds            ] = "$$ExceptionOutOfBounds"
	exception$ [ $$ExceptionBreakpoint             ] = "$$ExceptionBreakpoint"
	exception$ [ $$ExceptionBreakKey               ] = "$$ExceptionBreakKey"
	exception$ [ $$ExceptionAlignment              ] = "$$ExceptionAlignment"
	exception$ [ $$ExceptionDenormal               ] = "$$ExceptionDenormal"
	exception$ [ $$ExceptionDivideByZero           ] = "$$ExceptionDivideByZero"
	exception$ [ $$ExceptionInvalidOperation       ] = "$$ExceptionInvalidOperation"
	exception$ [ $$ExceptionOverflow               ] = "$$ExceptionOverflow"
	exception$ [ $$ExceptionStackCheck             ] = "$$ExceptionStackCheck"
	exception$ [ $$ExceptionUnderflow              ] = "$$ExceptionUnderflow"
	exception$ [ $$ExceptionInvalidInstruction     ] = "$$ExceptionInvalidInstrunction"
	exception$ [ $$ExceptionPrivilege              ] = "$$ExceptionPrivilege"
	exception$ [ $$ExceptionStackOverflow          ] = "$$ExceptionStackOverflow"
	exception$ [ $$ExceptionReserved               ] = "$$ExceptionReserved"
	exception$ [ $$ExceptionTimer                  ] = "$$ExceptionTimer"
	exception$ [ $$ExceptionUnknown                ] = "$$ExceptionUnknown"
	exception$ [ $$ExceptionUpper                  ] = "$$ExceptionUpper"
'
' ***********************************************
' *****  Initialize System Exception Names  *****
' ***********************************************
'
	sysException$ [ $$SIGNONE    ] = "$$SIGNONE"    '  0
	sysException$ [ $$SIGHUP     ] = "$$SIGHUP"     '  1
	sysException$ [ $$SIGINT     ] = "$$SIGINT"     '  2
	sysException$ [ $$SIGQUIT    ] = "$$SIGQUIT"    '  3
	sysException$ [ $$SIGILL     ] = "$$SIGILL"     '  4
	sysException$ [ $$SIGTRAP    ] = "$$SIGTRAP"    '  5
	sysException$ [ $$SIGABRT    ] = "$$SIGABRT"    '  6
	sysException$ [ $$SIGIOT     ] = "$$SIGIOT"     '  6
	sysException$ [ $$SIGBUS     ] = "$$SIGBUS"     '  7
	sysException$ [ $$SIGFPE     ] = "$$SIGFPE"     '  8
	sysException$ [ $$SIGKILL    ] = "$$SIGKILL"    '  9
	sysException$ [ $$SIGUSR1    ] = "$$SIGUSR1"    ' 10
	sysException$ [ $$SIGSEGV    ] = "$$SIGSEGV"    ' 11
	sysException$ [ $$SIGUSR2    ] = "$$SIGUSR2"    ' 12
	sysException$ [ $$SIGPIPE    ] = "$$SIGPIPE"    ' 13
	sysException$ [ $$SIGALRM    ] = "$$SIGALRM"    ' 14
	sysException$ [ $$SIGTERM    ] = "$$SIGTERM"    ' 15
	sysException$ [ $$SIGSTKFLT  ] = "$$SIGSTKFLT"  ' 16
	sysException$ [ $$SIGCHLD    ] = "$$SIGCHLD"    ' 17
	sysException$ [ $$SIGCONT    ] = "$$SIGCONT"    ' 18
	sysException$ [ $$SIGSTOP    ] = "$$SIGSTOP"    ' 19
	sysException$ [ $$SIGTSTP    ] = "$$SIGTSTP"    ' 20
	sysException$ [ $$SIGTTIN    ] = "$$SIGTTIN"    ' 21
	sysException$ [ $$SIGTTOU    ] = "$$SIGTTOU"    ' 22
	sysException$ [ $$SIGURG     ] = "$$SIGURG"     ' 23
	sysException$ [ $$SIGXCPU    ] = "$$SIGXCPU"    ' 24
	sysException$ [ $$SIGXFSZ    ] = "$$SIGXFSZ"    ' 25
	sysException$ [ $$SIGVTALRM  ] = "$$SIGVTALRM"  ' 26
	sysException$ [ $$SIGPROF    ] = "$$SIGPROF"    ' 27
	sysException$ [ $$SIGWINCH   ] = "$$SIGWINCH"   ' 28
	sysException$ [ $$SIGPOLL    ] = "$$SIGPOLL"    ' 29
	sysException$ [ $$SIGPWR     ] = "$$SIGPWR"     ' 30
	sysException$ [ $$SIGUNUSED  ] = "$$SIGUNUSED"  ' 31
	sysException$ [ $$SIGMAX     ] = "$$SIGMAX"     ' 31
	sysException$ [ $$SIGRTMIN   ] = "$$SIGRTMIN"   ' 32
'
' *******************************************
' *****  Initialize Native Error Names  *****
' *******************************************
'
	errorObject$[ $$ErrorObjectNone                ] = ""                   '  0
	errorObject$[ $$ErrorObjectData                ] = "Data"               '  1
	errorObject$[ $$ErrorObjectDisk                ] = "Disk"               '  2
	errorObject$[ $$ErrorObjectFile                ] = "File"               '  3
	errorObject$[ $$ErrorObjectFont                ] = "Font"               '  4
	errorObject$[ $$ErrorObjectGrid                ] = "Grid"               '  5
	errorObject$[ $$ErrorObjectIcon                ] = "Icon"               '  6
	errorObject$[ $$ErrorObjectName                ] = "Name"               '  7
	errorObject$[ $$ErrorObjectNode                ] = "Node"               '  8
	errorObject$[ $$ErrorObjectPipe                ] = "Pipe"               '  9
	errorObject$[ $$ErrorObjectUser                ] = "User"               ' 10
	errorObject$[ $$ErrorObjectArray               ] = "Array"              ' 11
	errorObject$[ $$ErrorObjectImage               ] = "Image"              ' 12
	errorObject$[ $$ErrorObjectMedia               ] = "Media"              ' 13
	errorObject$[ $$ErrorObjectQueue               ] = "Queue"              ' 14
	errorObject$[ $$ErrorObjectStack               ] = "Stack"              ' 15
	errorObject$[ $$ErrorObjectTimer               ] = "Timer"              ' 16
	errorObject$[ $$ErrorObjectBuffer              ] = "Buffer"             ' 17
	errorObject$[ $$ErrorObjectCursor              ] = "Cursor"             ' 18
	errorObject$[ $$ErrorObjectDevice              ] = "Device"             ' 19
	errorObject$[ $$ErrorObjectDriver              ] = "Driver"             ' 20
	errorObject$[ $$ErrorObjectMemory              ] = "Memory"             ' 21
	errorObject$[ $$ErrorObjectSocket              ] = "Socket"             ' 22
	errorObject$[ $$ErrorObjectString              ] = "String"             ' 23
	errorObject$[ $$ErrorObjectSystem              ] = "System"             ' 24
	errorObject$[ $$ErrorObjectThread              ] = "Thread"             ' 25
	errorObject$[ $$ErrorObjectWindow              ] = "Window"             ' 26
	errorObject$[ $$ErrorObjectCommand             ] = "Command"            ' 27
	errorObject$[ $$ErrorObjectDisplay             ] = "Display"            ' 28
	errorObject$[ $$ErrorObjectLibrary             ] = "Library"            ' 29
	errorObject$[ $$ErrorObjectMessage             ] = "Message"            ' 30
	errorObject$[ $$ErrorObjectNetwork             ] = "Network"            ' 31
	errorObject$[ $$ErrorObjectPrinter             ] = "Printer"            ' 32
	errorObject$[ $$ErrorObjectProcess             ] = "Process"            ' 33
	errorObject$[ $$ErrorObjectProgram             ] = "Program"            ' 34
	errorObject$[ $$ErrorObjectArgument            ] = "Argument"           ' 35
	errorObject$[ $$ErrorObjectComputer            ] = "Computer"           ' 36
	errorObject$[ $$ErrorObjectFunction            ] = "Function"           ' 37
	errorObject$[ $$ErrorObjectIdentity            ] = "Identity"           ' 38
	errorObject$[ $$ErrorObjectPassword            ] = "Password"           ' 39
	errorObject$[ $$ErrorObjectClipboard           ] = "Clipboard"          ' 40
	errorObject$[ $$ErrorObjectDirectory           ] = "Directory"          ' 41
	errorObject$[ $$ErrorObjectSemaphore           ] = "Semaphore"          ' 42
	errorObject$[ $$ErrorObjectStatement           ] = "Statement"          ' 43
	errorObject$[ $$ErrorObjectSystemRoutine       ] = "SystemRoutine"      ' 44
	errorObject$[ $$ErrorObjectSystemFunction      ] = "SystemFunction"     ' 45
	errorObject$[ $$ErrorObjectSystemResource      ] = "SystemResource"     ' 46
	errorObject$[ $$ErrorObjectOperatingSystem     ] = "OperatingSystem"    ' 47
	errorObject$[ $$ErrorObjectIntegerLogicUnit    ] = "IntegerLogicUnit"   ' 48
	errorObject$[ $$ErrorObjectFloatingPointUnit   ] = "FloatingPointUnit"  ' 49
	errorObject$[ $$ErrorObjectSymbolicLink        ] = "SymbolicLink"       ' 50
'
	errorNature$[ $$ErrorNatureNone                ] = ""                   '  0
	errorNature$[ $$ErrorNatureBusy                ] = "Busy"               '  1
	errorNature$[ $$ErrorNatureFull                ] = "Full"               '  2
	errorNature$[ $$ErrorNatureError               ] = "Error"              '  3
	errorNature$[ $$ErrorNatureEmpty               ] = "Empty"              '  4
	errorNature$[ $$ErrorNatureReset               ] = "Reset"              '  5
	errorNature$[ $$ErrorNatureExists              ] = "Exists"             '  6
	errorNature$[ $$ErrorNatureFailed              ] = "Failed"             '  7
	errorNature$[ $$ErrorNatureHalted              ] = "Halted"             '  8
	errorNature$[ $$ErrorNatureExpired             ] = "Expired"            '  9
	errorNature$[ $$ErrorNatureInvalid             ] = "Invalid"            ' 10
	errorNature$[ $$ErrorNatureMissing             ] = "Missing"            ' 11
	errorNature$[ $$ErrorNatureTimeout             ] = "Timeout"            ' 12
	errorNature$[ $$ErrorNatureTooMany             ] = "TooMany"            ' 13
	errorNature$[ $$ErrorNatureUnknown             ] = "Unknown"            ' 14
	errorNature$[ $$ErrorNatureBreakKey            ] = "BreakKey"           ' 15
	errorNature$[ $$ErrorNatureDeadlock            ] = "Deadlock"           ' 16
	errorNature$[ $$ErrorNatureDisabled            ] = "Disabled"           ' 17
	errorNature$[ $$ErrorNatureNotEmpty            ] = "NotEmpty"           ' 18
	errorNature$[ $$ErrorNatureObsolete            ] = "Obsolete"           ' 19
	errorNature$[ $$ErrorNatureOverflow            ] = "Overflow"           ' 20
	errorNature$[ $$ErrorNatureTooLarge            ] = "TooLarge"           ' 21
	errorNature$[ $$ErrorNatureTooSmall            ] = "TooSmall"           ' 22
	errorNature$[ $$ErrorNatureAbandoned           ] = "Abandoned"          ' 23
	errorNature$[ $$ErrorNatureAvailable           ] = "Available"          ' 24
	errorNature$[ $$ErrorNatureDuplicate           ] = "Duplicate"          ' 25
	errorNature$[ $$ErrorNatureExhausted           ] = "Exhausted"          ' 26
	errorNature$[ $$ErrorNaturePrivilege           ] = "Privilege"          ' 27
	errorNature$[ $$ErrorNatureUndefined           ] = "Undefined"          ' 28
	errorNature$[ $$ErrorNatureUnderflow           ] = "Underflow"          ' 29
	errorNature$[ $$ErrorNatureAllocation          ] = "Allocation"         ' 30
	errorNature$[ $$ErrorNatureBreakpoint          ] = "Breakpoint"         ' 31
	errorNature$[ $$ErrorNatureContention          ] = "Contention"         ' 32
	errorNature$[ $$ErrorNaturePermission          ] = "Permission"         ' 33
	errorNature$[ $$ErrorNatureTerminated          ] = "Terminated"         ' 34
	errorNature$[ $$ErrorNatureUndeclared          ] = "Undeclared"         ' 35
	errorNature$[ $$ErrorNatureUnexpected          ] = "Unexpected"         ' 36
	errorNature$[ $$ErrorNatureWouldBlock          ] = "WouldBlock"         ' 37
	errorNature$[ $$ErrorNatureInterrupted         ] = "Interrupted"        ' 38
	errorNature$[ $$ErrorNatureMalfunction         ] = "Malfunction"        ' 39
	errorNature$[ $$ErrorNatureNonexistent         ] = "Nonexistent"        ' 40
	errorNature$[ $$ErrorNatureUnavailable         ] = "Unavailable"        ' 41
	errorNature$[ $$ErrorNatureUnspecified         ] = "Unspecified"        ' 42
	errorNature$[ $$ErrorNatureDisconnected        ] = "Disconnected"       ' 43
	errorNature$[ $$ErrorNatureDivideByZero        ] = "DivideByZero"       ' 44
	errorNature$[ $$ErrorNatureIncompatible        ] = "Incompatible"       ' 45
	errorNature$[ $$ErrorNatureNotConnected        ] = "NotConnected"       ' 46
	errorNature$[ $$ErrorNatureLimitExceeded       ] = "LimitExceeded"      ' 47
	errorNature$[ $$ErrorNatureNotInitialized      ] = "NotInitialized"     ' 48
	errorNature$[ $$ErrorNatureHigherDimension     ] = "HigherDimension"    ' 49
	errorNature$[ $$ErrorNatureLowestDimension     ] = "LowestDimension"    ' 50
	errorNature$[ $$ErrorNatureCannotInitialize    ] = "CannotInitialize"   ' 51
	errorNature$[ $$ErrorNatureInitializeFailed    ] = "InitializeFailed"   ' 52
	errorNature$[ $$ErrorNatureAlreadyInitialized  ] = "AlreadyInitialized" ' 53
	errorNature$[ $$ErrorNatureInvalidAccess       ] = "InvalidAccess"      ' 54
	errorNature$[ $$ErrorNatureInvalidAddress      ] = "InvalidAddress"     ' 55
	errorNature$[ $$ErrorNatureInvalidAlignment    ] = "InvalidAlignment"   ' 56
	errorNature$[ $$ErrorNatureInvalidArgument     ] = "InvalidArgument"    ' 57
	errorNature$[ $$ErrorNatureInvalidCheck        ] = "InvalidCheck"       ' 58
	errorNature$[ $$ErrorNatureInvalidCoordinates  ] = "InvalidCoordinates" ' 59
	errorNature$[ $$ErrorNatureInvalidCommand      ] = "InvalidCommand"     ' 60
	errorNature$[ $$ErrorNatureInvalidData         ] = "InvalidData"        ' 61
	errorNature$[ $$ErrorNatureInvalidDimension    ] = "InvalidDimension"   ' 62
	errorNature$[ $$ErrorNatureInvalidEntry        ] = "InvalidEntry"       ' 63
	errorNature$[ $$ErrorNatureInvalidFormat       ] = "InvalidFormat"      ' 64
	errorNature$[ $$ErrorNatureInvalidKind         ] = "InvalidKind"        ' 65
	errorNature$[ $$ErrorNatureInvalidIdentity     ] = "InvalidIdentity"    ' 66
	errorNature$[ $$ErrorNatureInvalidInstruction  ] = "InvalidInstruction" ' 67
	errorNature$[ $$ErrorNatureInvalidLocation     ] = "InvalidLocation"    ' 68
	errorNature$[ $$ErrorNatureInvalidMessage      ] = "InvalidMessage"     ' 69
	errorNature$[ $$ErrorNatureInvalidName         ] = "InvalidName"        ' 70
	errorNature$[ $$ErrorNatureInvalidNode         ] = "InvalidNode"        ' 71
	errorNature$[ $$ErrorNatureInvalidNumber       ] = "InvalidNumber"      ' 72
	errorNature$[ $$ErrorNatureInvalidOperand      ] = "InvalidOperand"     ' 73
	errorNature$[ $$ErrorNatureInvalidOperation    ] = "InvalidOperation"   ' 74
	errorNature$[ $$ErrorNatureInvalidReply        ] = "InvalidReply"       ' 75
	errorNature$[ $$ErrorNatureInvalidRequest      ] = "InvalidRequest"     ' 76
	errorNature$[ $$ErrorNatureInvalidResult       ] = "InvalidResult"      ' 77
	errorNature$[ $$ErrorNatureInvalidSelection    ] = "InvalidSelection"   ' 78
	errorNature$[ $$ErrorNatureInvalidSignature    ] = "InvalidSignature"   ' 79
	errorNature$[ $$ErrorNatureInvalidSize         ] = "InvalidSize"        ' 80
	errorNature$[ $$ErrorNatureInvalidType         ] = "InvalidType"        ' 81
	errorNature$[ $$ErrorNatureInvalidValue        ] = "InvalidValue"       ' 82
	errorNature$[ $$ErrorNatureInvalidVersion      ] = "InvalidVersion"     ' 83
'
' *******************************************
' *****  Initialize System Error Names  *****
' *******************************************
'
'	error constant                    error string         SCO  Linux (if different)
'
	SELECT CASE TRUE
		CASE linux		: GOSUB InitializeLinuxErrorStrings
										GOSUB InitializeLinuxErrnoToErrorArray
		CASE unix			: GOSUB InitializeUnixErrorStrings
										GOSUB InitializeUnixErrnoToErrorArray
		CASE ELSE			: GOSUB InitializeUnixErrorStrings
										GOSUB InitializeUnixErrnoToErrorArray
	END SELECT
'
	##WHOMASK = whomask
	RETURN ($$FALSE)
'
'
'
'
' *****  Initialize Linux errno strings  *****
'
SUB InitializeLinuxErrorStrings
	#OSERROR$[ $$EPERM           ] = "EPERM"             '   1
	#OSERROR$[ $$ENOENT          ] = "ENOENT"            '   2
	#OSERROR$[ $$ESRCH           ] = "ESRCH"             '   3
	#OSERROR$[ $$EINTR           ] = "EINTR"             '   4
	#OSERROR$[ $$EIO             ] = "EIO"               '   5
	#OSERROR$[ $$ENXIO           ] = "ENXIO"             '   6
	#OSERROR$[ $$E2BIG           ] = "E2BIG"             '   7
	#OSERROR$[ $$ENOEXEC         ] = "ENOEXEC"           '   8
	#OSERROR$[ $$EBADF           ] = "EBADF"             '   9
	#OSERROR$[ $$ECHILD          ] = "ECHILD"            '  10
	#OSERROR$[ $$EAGAIN          ] = "EAGAIN"            '  11
	#OSERROR$[ $$ENOMEM          ] = "ENOMEM"            '  12
	#OSERROR$[ $$EACCES          ] = "EACCES"            '  13
	#OSERROR$[ $$EFAULT          ] = "EFAULT"            '  14
	#OSERROR$[ $$ENOTBLK         ] = "ENOTBLK"           '  15
	#OSERROR$[ $$EBUSY           ] = "EBUSY"             '  16
	#OSERROR$[ $$EEXIST          ] = "EEXIST"            '  17
	#OSERROR$[ $$EXDEV           ] = "EXDEV"             '  18
	#OSERROR$[ $$ENODEV          ] = "ENODEV"            '  19
	#OSERROR$[ $$ENOTDIR         ] = "ENOTDIR"           '  20
	#OSERROR$[ $$EISDIR          ] = "EISDIR"            '  21
	#OSERROR$[ $$EINVAL          ] = "EINVAL"            '  22
	#OSERROR$[ $$ENFILE          ] = "ENFILE"            '  23
	#OSERROR$[ $$EMFILE          ] = "EMFILE"            '  24
	#OSERROR$[ $$ENOTTY          ] = "ENOTTY"            '  25
	#OSERROR$[ $$ETXTBSY         ] = "ETXTBSY"           '  26
	#OSERROR$[ $$EFBIG           ] = "EFBIG"             '  27
	#OSERROR$[ $$ENOSPC          ] = "ENOSPC"            '  28
	#OSERROR$[ $$ESPIPE          ] = "ESPIPE"            '  29
	#OSERROR$[ $$EROFS           ] = "EROFS"             '  30
	#OSERROR$[ $$EMLINK          ] = "EMLINK"            '  31
	#OSERROR$[ $$EPIPE           ] = "EPIPE"             '  32
	#OSERROR$[ $$EDOM            ] = "EDOM"              '  33
	#OSERROR$[ $$ERANGE          ] = "ERANGE"            '  34
	#OSERROR$[ $$EDEADLK         ] = "EDEADLK"           '  35
	#OSERROR$[ $$ENAMETOOLONG    ] = "ENAMETOOLONG"      '  36
	#OSERROR$[ $$ENOLCK          ] = "ENOLCK"            '  37
	#OSERROR$[ $$ENOSYS          ] = "ENOSYS"            '  38
	#OSERROR$[ $$ENOTEMPTY       ] = "ENOTEMPTY"         '  39
	#OSERROR$[ $$ELOOP           ] = "ELOOP"             '  40
	#OSERROR$[ $$EWOULDBLOCK     ] = "EWOULDBLOCK"       '  41 (new Linux uses $$EAGAIN 11)
	#OSERROR$[ $$ENOMSG          ] = "ENOMSG"            '  42
	#OSERROR$[ $$EIDRM           ] = "EIDRM"             '  43
	#OSERROR$[ $$ECHRNG          ] = "ECHRNG"            '  44
	#OSERROR$[ $$EL2NSYNC        ] = "EL2NSYNC"          '  45
	#OSERROR$[ $$EL3HLT          ] = "EL3HLT"            '  46
	#OSERROR$[ $$EL3RST          ] = "EL3RST"            '  47
	#OSERROR$[ $$ELNRNG          ] = "ELNRNG"            '  48
	#OSERROR$[ $$EUNATCH         ] = "EUNATCH"           '  49
	#OSERROR$[ $$ENOCSI          ] = "ENOCSI"            '  50
	#OSERROR$[ $$EL2HLT          ] = "EL2HLT"            '  51
	#OSERROR$[ $$EBADE           ] = "EBADE"             '  52
	#OSERROR$[ $$EBADR           ] = "EBADR"             '  53
	#OSERROR$[ $$EXFULL          ] = "EXFULL"            '  54
	#OSERROR$[ $$ENOANO          ] = "ENOANO"            '  55
	#OSERROR$[ $$EBADRQC         ] = "EBADRQC"           '  56
	#OSERROR$[ $$EBADSLT         ] = "EBADSLT"           '  57
	#OSERROR$[ $$EDEADLOCK       ] = "EDEADLOCK"         '  58 (new Linux uses $$EDEADLK = 35)
	#OSERROR$[ $$EBFONT          ] = "EBFONT"            '  59
	#OSERROR$[ $$ENOSTR          ] = "ENOSTR"            '  60
	#OSERROR$[ $$ENODATA         ] = "ENODATA"           '  61
	#OSERROR$[ $$ETIME           ] = "ETIME"             '  62
	#OSERROR$[ $$ENOSR           ] = "ENOSR"             '  63
	#OSERROR$[ $$ENONET          ] = "ENONET"            '  64
	#OSERROR$[ $$ENOPKG          ] = "ENOPKG"            '  65
	#OSERROR$[ $$EREMOTE         ] = "EREMOTE"           '  66
	#OSERROR$[ $$ENOLINK         ] = "ENOLINK"           '  67
	#OSERROR$[ $$EADV            ] = "EADV"              '  68
	#OSERROR$[ $$ESRMNT          ] = "ESRMNT"            '  69
	#OSERROR$[ $$ECOMM           ] = "ECOMM"             '  70
	#OSERROR$[ $$EPROTO          ] = "EPROTO"            '  71
	#OSERROR$[ $$EMULTIHOP       ] = "EMULTIHOP"         '  72
	#OSERROR$[ $$EDOTDOT         ] = "EDOTDOT"           '  73
	#OSERROR$[ $$EBADMSG         ] = "EBADMSG"           '  74
	#OSERROR$[ $$EOVERFLOW       ] = "EOVERFLOW"         '  75
	#OSERROR$[ $$ENOTUNIQ        ] = "ENOTUNIQ"          '  76
	#OSERROR$[ $$EBADFD          ] = "EBADFD"            '  77
	#OSERROR$[ $$EREMCHG         ] = "EREMCHG"           '  78
	#OSERROR$[ $$ELIBACC         ] = "ELIBACC"           '  79
	#OSERROR$[ $$ELIBBAD         ] = "ELIBBAD"           '  80
	#OSERROR$[ $$ELIBSCN         ] = "ELIBSCN"           '  81
	#OSERROR$[ $$ELIBMAX         ] = "ELIBMAX"           '  82
	#OSERROR$[ $$ELIBEXEC        ] = "ELIBEXEC"          '  83
	#OSERROR$[ $$EILSEQ          ] = "EILSEQ"            '  84
	#OSERROR$[ $$ERESTART        ] = "ERESTART"          '  85 linux only ?
	#OSERROR$[ $$ESTRPIPE        ] = "ESTRPIPE"          '  86 linux only ?
	#OSERROR$[ $$EUSERS          ] = "EUSERS"            '  87 linux only ?
	#OSERROR$[ $$ENOTSOCK        ] = "ENOTSOCK"          '  88
	#OSERROR$[ $$EDESTADDRREQ    ] = "EDESTADDRREQ"      '  89
	#OSERROR$[ $$EMSGSIZE        ] = "EMSGSIZE"          '  90
	#OSERROR$[ $$EPROTOTYPE      ] = "EPROTOTYPE"        '  91
	#OSERROR$[ $$ENOPROTOOPT     ] = "ENOPROTOOPT"       '  92
	#OSERROR$[ $$EPROTONOSUPPORT ] = "EPROTONOSUPPORT"   '  93
	#OSERROR$[ $$ESOCKTNOSUPPORT ] = "ESOCKTNOSUPPORT"   '  94
	#OSERROR$[ $$EOPNOTSUPP      ] = "EOPNOTSUPP"        '  95
	#OSERROR$[ $$EPFNOSUPPORT    ] = "EPFNOSUPPORT"      '  96
	#OSERROR$[ $$EAFNOSUPPORT    ] = "EAFNOSUPPORT"      '  97
	#OSERROR$[ $$EADDRINUSE      ] = "EADDRINUSE"        '  98
	#OSERROR$[ $$EADDRNOTAVAIL   ] = "EADDRNOTAVAIL"     '  99
	#OSERROR$[ $$ENETDOWN        ] = "ENETDOWN"          ' 100
	#OSERROR$[ $$ENETUNREACH     ] = "ENETUNREACH"       ' 101
	#OSERROR$[ $$ENETRESET       ] = "ENETRESET"         ' 102
	#OSERROR$[ $$ECONNABORTED    ] = "ECONNABORTED"      ' 103
	#OSERROR$[ $$ECONNRESET      ] = "ECONNRESET"        ' 104
	#OSERROR$[ $$ENOBUFS         ] = "ENOBUFS"           ' 105
	#OSERROR$[ $$EISCONN         ] = "EISCONN"           ' 106
	#OSERROR$[ $$ENOTCONN        ] = "ENOTCONN"          ' 107
	#OSERROR$[ $$ESHUTDOWN       ] = "ESHUTDOWN"         ' 108
	#OSERROR$[ $$ETOOMANYREFS    ] = "ETOOMANYREFS"      ' 109
	#OSERROR$[ $$ETIMEDOUT       ] = "ETIMEDOUT"         ' 110
	#OSERROR$[ $$ECONNREFUSED    ] = "ECONNREFUSED"      ' 111
	#OSERROR$[ $$EHOSTDOWN       ] = "EHOSTDOWN"         ' 112
	#OSERROR$[ $$EHOSTUNREACH    ] = "EHOSTUNREACH"      ' 113
	#OSERROR$[ $$EALREADY        ] = "EALREADY"          ' 114
	#OSERROR$[ $$EINPROGRESS     ] = "EINPROGRESS"       ' 115
	#OSERROR$[ $$ESTALE          ] = "ESTALE"            ' 116
	#OSERROR$[ $$EUCLEAN         ] = "EUCLEAN"           ' 117 linux only ?
	#OSERROR$[ $$ENOTNAM         ] = "ENOTNAM"           ' 118 linux only ?
	#OSERROR$[ $$ENAVAIL         ] = "ENAVAIL"           ' 119 linux only ?
	#OSERROR$[ $$EISNAM          ] = "EISNAM"            ' 120 linux only ?
	#OSERROR$[ $$EREMOTEIO       ] = "EREMOTEIO"         ' 121 linux only ?
	#OSERROR$[ $$EDQUOT          ] = "EDQUOT"            ' 122 linux only ?
	#OSERROR$[ $$ENOMEDIUM       ] = "ENOMEDIUM"         ' 123
	#OSERROR$[ $$EMEDIUMTYPE     ] = "EMEDIUMTYPE"       ' 124
	#OSERROR$[ $$ECANCELED       ] = "ECANCELED"         ' 125
	#OSERROR$[ $$ENOKEY          ] = "ENOKEY"            ' 126
	#OSERROR$[ $$EKEYEXPIRED     ] = "EKEYEXPIRED"       ' 127
	#OSERROR$[ $$EKEYREVOKED     ] = "EKEYREVOKED"       ' 128
	#OSERROR$[ $$EKEYREJECTED    ] = "EKEYREJECTED"      ' 129
	#OSERROR$[ $$EOWNERDEAD      ] = "EOWNERDEAD"        ' 130
	#OSERROR$[ $$ENOTRECOVERABLE ] = "ENOTRECOVERABLE"   ' 131
	#OSERROR$[ $$ERFKILL         ] = "ERFKILL"           ' 132
'
'	#OSERROR$[ $$ELBIN           ] = "ELBIN"             ' SCO unix only ?
'	#OSERROR$[ $$EIORESID        ] = "EIORESID"          ' SCO unix only ?
END SUB
'
'
' *****  Initialize SCO Unix errno strings  *****
'
SUB InitializeUnixErrorStrings
	#OSERROR$[ $$EPERM           ] = "EPERM"             '   1
	#OSERROR$[ $$ENOENT          ] = "ENOENT"            '   2
	#OSERROR$[ $$ESRCH           ] = "ESRCH"             '   3
	#OSERROR$[ $$EINTR           ] = "EINTR"             '   4
	#OSERROR$[ $$EIO             ] = "EIO"               '   5
	#OSERROR$[ $$ENXIO           ] = "ENXIO"             '   6
	#OSERROR$[ $$E2BIG           ] = "E2BIG"             '   7
	#OSERROR$[ $$ENOEXEC         ] = "ENOEXEC"           '   8
	#OSERROR$[ $$EBADF           ] = "EBADF"             '   9
	#OSERROR$[ $$ECHILD          ] = "ECHILD"            '  10
	#OSERROR$[ $$EAGAIN          ] = "EAGAIN"            '  11
	#OSERROR$[ $$ENOMEM          ] = "ENOMEM"            '  12
	#OSERROR$[ $$EACCES          ] = "EACCES"            '  13
	#OSERROR$[ $$EFAULT          ] = "EFAULT"            '  14
	#OSERROR$[ $$ENOTBLK         ] = "ENOTBLK"           '  15
	#OSERROR$[ $$EBUSY           ] = "EBUSY"             '  16
	#OSERROR$[ $$EEXIST          ] = "EEXIST"            '  17
	#OSERROR$[ $$EXDEV           ] = "EXDEV"             '  18
	#OSERROR$[ $$ENODEV          ] = "ENODEV"            '  19
	#OSERROR$[ $$ENOTDIR         ] = "ENOTDIR"           '  20
	#OSERROR$[ $$EISDIR          ] = "EISDIR"            '  21
	#OSERROR$[ $$EINVAL          ] = "EINVAL"            '  22
	#OSERROR$[ $$ENFILE          ] = "ENFILE"            '  23
	#OSERROR$[ $$EMFILE          ] = "EMFILE"            '  24
	#OSERROR$[ $$ENOTTY          ] = "ENOTTY"            '  25
	#OSERROR$[ $$ETXTBSY         ] = "ETXTBSY"           '  26
	#OSERROR$[ $$EFBIG           ] = "EFBIG"             '  27
	#OSERROR$[ $$ENOSPC          ] = "ENOSPC"            '  28
	#OSERROR$[ $$ESPIPE          ] = "ESPIPE"            '  29
	#OSERROR$[ $$EROFS           ] = "EROFS"             '  30
	#OSERROR$[ $$EMLINK          ] = "EMLINK"            '  31
	#OSERROR$[ $$EPIPE           ] = "EPIPE"             '  32
	#OSERROR$[ $$EDOM            ] = "EDOM"              '  33
	#OSERROR$[ $$ERANGE          ] = "ERANGE"            '  34
	#OSERROR$[ $$ENOMSG          ] = "ENOMSG"            '  35
	#OSERROR$[ $$EIDRM           ] = "EIDRM"             '  36
	#OSERROR$[ $$ECHRNG          ] = "ECHRNG"            '  37
	#OSERROR$[ $$EL2NSYNC        ] = "EL2NSYNC"          '  38
	#OSERROR$[ $$EL3HLT          ] = "EL3HLT"            '  39
	#OSERROR$[ $$EL3RST          ] = "EL3RST"            '  40
	#OSERROR$[ $$ELNRNG          ] = "ELNRNG"            '  41
	#OSERROR$[ $$EUNATCH         ] = "EUNATCH"           '  42
	#OSERROR$[ $$ENOCSI          ] = "ENOCSI"            '  43
	#OSERROR$[ $$EL2HLT          ] = "EL2HLT"            '  44
	#OSERROR$[ $$EDEADLK         ] = "EDEADLK"           '  45
	#OSERROR$[ $$ENOLCK          ] = "ENOLCK"            '  46
	#OSERROR$[ $$EBADE           ] = "EBADE"             '  50
	#OSERROR$[ $$EBADR           ] = "EBADR"             '  51
	#OSERROR$[ $$EXFULL          ] = "EXFULL"            '  52
	#OSERROR$[ $$ENOANO          ] = "ENOANO"            '  53
	#OSERROR$[ $$EBADRQC         ] = "EBADRQC"           '  54
	#OSERROR$[ $$EBADSLT         ] = "EBADSLT"           '  55
	#OSERROR$[ $$EDEADLK         ] = "EDEADLK"           '  56
	#OSERROR$[ $$EBFONT          ] = "EBFONT"            '  57
	#OSERROR$[ $$ENOSTR          ] = "ENOSTR"            '  60
	#OSERROR$[ $$ENODATA         ] = "ENODATA"           '  61
	#OSERROR$[ $$ETIME           ] = "ETIME"             '  62
	#OSERROR$[ $$ENOSR           ] = "ENOSR"             '  63
	#OSERROR$[ $$ENONET          ] = "ENONET"            '  64
	#OSERROR$[ $$ENOPKG          ] = "ENOPKG"            '  65
	#OSERROR$[ $$EREMOTE         ] = "EREMOTE"           '  66
	#OSERROR$[ $$ENOLINK         ] = "ENOLINK"           '  67
	#OSERROR$[ $$EADV            ] = "EADV"              '  68
	#OSERROR$[ $$ESRMNT          ] = "ESRMNT"            '  69
	#OSERROR$[ $$ECOMM           ] = "ECOMM"             '  70
	#OSERROR$[ $$EPROTO          ] = "EPROTO"            '  71
	#OSERROR$[ $$EMULTIHOP       ] = "EMULTIHOP"         '  74
	#OSERROR$[ $$ELBIN           ] = "ELBIN"             '  75
	#OSERROR$[ $$EDOTDOT         ] = "EDOTDOT"           '  76
	#OSERROR$[ $$EBADMSG         ] = "EBADMSG"           '  77
	#OSERROR$[ $$ENAMETOOLONG    ] = "ENAMETOOLONG"      '  78
	#OSERROR$[ $$EOVERFLOW       ] = "EOVERFLOW"         '  79
	#OSERROR$[ $$ENOTUNIQ        ] = "ENOTUNIQ"          '  80
	#OSERROR$[ $$EBADFD          ] = "EBADFD"            '  81
	#OSERROR$[ $$EREMCHG         ] = "EREMCHG"           '  82
	#OSERROR$[ $$ELIBACC         ] = "ELIBACC"           '  83
	#OSERROR$[ $$ELIBBAD         ] = "ELIBBAD"           '  84
	#OSERROR$[ $$ELIBSCN         ] = "ELIBSCN"           '  85
	#OSERROR$[ $$ELIBMAX         ] = "ELIBMAX"           '  86
	#OSERROR$[ $$ELIBEXEC        ] = "ELIBEXEC"          '  87
	#OSERROR$[ $$EILSEQ          ] = "EILSEQ"            '  88
	#OSERROR$[ $$ENOSYS          ] = "ENOSYS"            '  89
	#OSERROR$[ $$ETCPERR         ] = "ETCPERR"           '  90
	#OSERROR$[ $$EWOULDBLOCK     ] = "EWOULDBLOCK"       '  90
	#OSERROR$[ $$EINPROGRESS     ] = "EINPROGRESS"       '  91
	#OSERROR$[ $$EALREADY        ] = "EALREADY"          '  92
	#OSERROR$[ $$ENOTSOCK        ] = "ENOTSOCK"          '  93
	#OSERROR$[ $$EDESTADDRREQ    ] = "EDESTADDRREQ"      '  94
	#OSERROR$[ $$EMSGSIZE        ] = "EMSGSIZE"          '  95
	#OSERROR$[ $$EPROTOTYPE      ] = "EPROTOTYPE"        '  96
	#OSERROR$[ $$EPROTONOSUPPORT ] = "EPROTONOSUPPORT"   '  97
	#OSERROR$[ $$ESOCKTNOSUPPORT ] = "ESOCKTNOSUPPORT"   '  98
	#OSERROR$[ $$EOPNOTSUPP      ] = "EOPNOTSUPP"        '  99
	#OSERROR$[ $$EPFNOSUPPORT    ] = "EPFNOSUPPORT"      ' 100
	#OSERROR$[ $$EAFNOSUPPORT    ] = "EAFNOSUPPORT"      ' 101
	#OSERROR$[ $$EADDRINUSE      ] = "EADDRINUSE"        ' 102
	#OSERROR$[ $$EADDRNOTAVAIL   ] = "EADDRNOTAVAIL"     ' 103
	#OSERROR$[ $$ENETDOWN        ] = "ENETDOWN"          ' 104
	#OSERROR$[ $$ENETUNREACH     ] = "ENETUNREACH"       ' 105
	#OSERROR$[ $$ENETRESET       ] = "ENETRESET"         ' 105
	#OSERROR$[ $$ECONNABORTED    ] = "ECONNABORTED"      ' 107
	#OSERROR$[ $$ECONNRESET      ] = "ECONNRESET"        ' 108
	#OSERROR$[ $$ENOBUFS         ] = "ENOBUFS"           ' 109
	#OSERROR$[ $$EISCONN         ] = "EISCONN"           ' 110
	#OSERROR$[ $$ENOTCONN        ] = "ENOTCONN"          ' 111
	#OSERROR$[ $$ESHUTDOWN       ] = "ESHUTDOWN"         ' 112
	#OSERROR$[ $$ETOOMANYREFS    ] = "ETOOMANYREFS"      ' 113
	#OSERROR$[ $$ETIMEDOUT       ] = "ETIMEDOUT"         ' 114
	#OSERROR$[ $$ECONNREFUSED    ] = "ECONNREFUSED"      ' 115
	#OSERROR$[ $$EHOSTDOWN       ] = "EHOSTDOWN"         ' 116
	#OSERROR$[ $$EHOSTUNREACH    ] = "EHOSTUNREACH"      ' 117
	#OSERROR$[ $$ENOPROTOOPT     ] = "ENOPROTOOPT"       ' 118
	#OSERROR$[ $$ENOTEMPTY       ] = "ENOTEMPTY"         ' 145
	#OSERROR$[ $$ELOOP           ] = "ELOOP"             ' 150
	#OSERROR$[ $$ESTALE          ] = "ESTALE"            ' 151
	#OSERROR$[ $$EIORESID        ] = "EIORESID"          ' 500
END SUB
'
'
' nativeErrorNumber = #OSTOXERROR[operatingSystemErrorNumber]
'
' converts all operating system error numbers to native error numbers
' nativeErrorNumber = (($$ErrorObjectSystem << 8) OR $$ErrorNatureError)
'   means there's no native error number for this system error number,
'   so you'll have to settle for the system error number.
'
' need a separate subroutine for Linux vs SCO because their errno sets are different
'
'
' *****  InitializeLinuxErrnoToErrorArray  *****
'
SUB InitializeLinuxErrnoToErrorArray
	upper = UBOUND (#OSTOXERROR[])
	FOR i = 0 TO upper
		#OSTOXERROR[i] = ($$ErrorObjectSystem << 8) OR $$ErrorNatureError
	NEXT i
'
	#OSTOXERROR[ $$EPERM           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNaturePermission
	#OSTOXERROR[ $$ENOENT          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$ESRCH           ] = ($$ErrorObjectProcess         << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$EINTR           ] = ($$ErrorObjectSystemRoutine   << 8) OR $$ErrorNatureInterrupted
	#OSTOXERROR[ $$EIO             ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENXIO           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureMissing
	#OSTOXERROR[ $$E2BIG           ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureLimitExceeded
	#OSTOXERROR[ $$ENOEXEC         ] = ($$ErrorObjectCommand         << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$EBADF           ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureInvalidIdentity
	#OSTOXERROR[ $$ECHILD          ] = ($$ErrorObjectProcess         << 8) OR $$ErrorNatureNonexistent
'	#OSTOXERROR[ $$EAGAIN          ] = ($$ErrorObjectProcess         << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$EAGAIN          ] = ($$ErrorObjectFunction        << 8) OR $$ErrorNatureWouldBlock
	#OSTOXERROR[ $$ENOMEM          ] = ($$ErrorObjectMemory          << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$EACCES          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNaturePermission
	#OSTOXERROR[ $$EFAULT          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureInvalidAddress
	#OSTOXERROR[ $$ENOTBLK         ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureIncompatible
	#OSTOXERROR[ $$EBUSY           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureBusy
	#OSTOXERROR[ $$EEXIST          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureExists
	#OSTOXERROR[ $$EXDEV           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureContention
	#OSTOXERROR[ $$ENODEV          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$ENOTDIR         ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$EISDIR          ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureExists
	#OSTOXERROR[ $$EINVAL          ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalid
	#OSTOXERROR[ $$ENFILE          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureLimitExceeded
	#OSTOXERROR[ $$EMFILE          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureTooMany
	#OSTOXERROR[ $$ENOTTY          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureIncompatible
	#OSTOXERROR[ $$ETXTBSY         ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureContention
	#OSTOXERROR[ $$EFBIG           ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureTooLarge
	#OSTOXERROR[ $$ENOSPC          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$ESPIPE          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureInvalidOperation
	#OSTOXERROR[ $$EROFS           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureInvalidOperation
	#OSTOXERROR[ $$EMLINK          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureTooMany
	#OSTOXERROR[ $$EPIPE           ] = ($$ErrorObjectPipe            << 8) OR $$ErrorNatureTerminated
	#OSTOXERROR[ $$EDOM            ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$ERANGE          ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EDEADLK         ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureDeadlock
	#OSTOXERROR[ $$ENAMETOOLONG    ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureInvalidName
	#OSTOXERROR[ $$ENOLCK          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENOSYS          ] = ($$ErrorObjectSystemRoutine   << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$ENOTEMPTY       ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureNotEmpty
	#OSTOXERROR[ $$ELOOP           ] = ($$ErrorObjectSymbolicLink    << 8) OR $$ErrorNatureLimitExceeded
	#OSTOXERROR[ $$EWOULDBLOCK     ] = ($$ErrorObjectFunction        << 8) OR $$ErrorNatureWouldBlock
	#OSTOXERROR[ $$ENOMSG          ] = ($$ErrorObjectMessage         << 8) OR $$ErrorNatureMissing
	#OSTOXERROR[ $$EIDRM           ] = ($$ErrorObjectMessage         << 8) OR $$ErrorNatureInvalidIdentity
	#OSTOXERROR[ $$ECHRNG          ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EL2NSYNC        ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureMalfunction
	#OSTOXERROR[ $$EL3HLT          ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureHalted
	#OSTOXERROR[ $$EL3RST          ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureReset
	#OSTOXERROR[ $$ELNRNG          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EUNATCH         ] = ($$ErrorObjectDriver          << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENOCSI          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$EL2HLT          ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureHalted
	#OSTOXERROR[ $$EBADE           ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EBADR           ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EXFULL          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$ENOANO          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureOverflow
	#OSTOXERROR[ $$EBADRQC         ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EBADSLT         ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EDEADLK         ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureDeadlock
	#OSTOXERROR[ $$EBFONT          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ENOSTR          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureInvalidType
	#OSTOXERROR[ $$ENODATA         ] = ($$ErrorObjectData            << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ETIME           ] = ($$ErrorObjectTimer           << 8) OR $$ErrorNatureTimeout
	#OSTOXERROR[ $$ENOSR           ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$ENONET          ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENOPKG          ] = ($$ErrorObjectProgram         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$EREMOTE         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENOLINK         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EADV            ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ESRMNT          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ECOMM           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPROTO          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EMULTIHOP       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EDOTDOT         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EBADMSG         ] = ($$ErrorObjectMessage         << 8) OR $$ErrorNatureInvalid
	#OSTOXERROR[ $$EOVERFLOW       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOTUNIQ        ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureInvalidIdentity
	#OSTOXERROR[ $$EBADFD          ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$EREMCHG         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ELIBACC         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ELIBBAD         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ELIBSCN         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ELIBMAX         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureTooMany
	#OSTOXERROR[ $$ELIBEXEC        ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureInvalidAccess
	#OSTOXERROR[ $$EILSEQ          ] = ($$ErrorObjectData            << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ERESTART        ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOTSOCK        ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureUndefined
	#OSTOXERROR[ $$EDESTADDRREQ    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EMSGSIZE        ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPROTOTYPE      ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOPROTOOPT     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPROTONOSUPPORT ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ESOCKTNOSUPPORT ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EOPNOTSUPP      ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPFNOSUPPORT    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EAFNOSUPPORT    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EADDRINUSE      ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureContention
	#OSTOXERROR[ $$EADDRNOTAVAIL   ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureInvalidAddress
	#OSTOXERROR[ $$ENETDOWN        ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENETUNREACH     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENETRESET       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ECONNABORTED    ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureDisconnected
	#OSTOXERROR[ $$ECONNRESET      ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureReset
	#OSTOXERROR[ $$ENOBUFS         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EISCONN         ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureInvalidRequest
	#OSTOXERROR[ $$ENOTCONN        ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureNotConnected
	#OSTOXERROR[ $$ESHUTDOWN       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ETOOMANYREFS    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ETIMEDOUT       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureTimeout
	#OSTOXERROR[ $$ECONNREFUSED    ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureNotConnected
	#OSTOXERROR[ $$EHOSTDOWN       ] = ($$ErrorObjectSystem          << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$EHOSTUNREACH    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureUnknown
	#OSTOXERROR[ $$EALREADY        ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EINPROGRESS     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ESTALE          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EUCLEAN         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOTNAM         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENAVAIL         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EISNAM          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EREMOTEIO       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EDQUOT          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
'
' SCO unix constants not defined or redefined in Linux
'
'	#OSTOXERROR[ $$ELBIN           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
'	#OSTOXERROR[ $$ETCPERR         ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureError
'	#OSTOXERROR[ $$ENOPROTOOPT     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
'	#OSTOXERROR[ $$EIORESID        ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
END SUB
'
'
' *****  InitializeUnixErrnoToErrorArray  *****
'
SUB InitializeUnixErrnoToErrorArray
	upper = UBOUND (#OSTOXERROR[])
	FOR i = 0 TO upper
		#OSTOXERROR[i] = ($$ErrorObjectSystem << 8) OR $$ErrorNatureError
	NEXT i
'
	#OSTOXERROR[ $$EPERM           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNaturePermission
	#OSTOXERROR[ $$ENOENT          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$ESRCH           ] = ($$ErrorObjectProcess         << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$EINTR           ] = ($$ErrorObjectSystemRoutine   << 8) OR $$ErrorNatureInterrupted
	#OSTOXERROR[ $$EIO             ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENXIO           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureMissing
	#OSTOXERROR[ $$E2BIG           ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureLimitExceeded
	#OSTOXERROR[ $$ENOEXEC         ] = ($$ErrorObjectCommand         << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$EBADF           ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureInvalidIdentity
	#OSTOXERROR[ $$ECHILD          ] = ($$ErrorObjectProcess         << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$EAGAIN          ] = ($$ErrorObjectProcess         << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$ENOMEM          ] = ($$ErrorObjectMemory          << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$EACCES          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNaturePermission
	#OSTOXERROR[ $$EFAULT          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureInvalidAddress
	#OSTOXERROR[ $$ENOTBLK         ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureIncompatible
	#OSTOXERROR[ $$EBUSY           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureBusy
	#OSTOXERROR[ $$EEXIST          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureExists
	#OSTOXERROR[ $$EXDEV           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureContention
	#OSTOXERROR[ $$ENODEV          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$ENOTDIR         ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$EISDIR          ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureExists
	#OSTOXERROR[ $$EINVAL          ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalid
	#OSTOXERROR[ $$ENFILE          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureLimitExceeded
	#OSTOXERROR[ $$EMFILE          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureTooMany
	#OSTOXERROR[ $$ENOTTY          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureIncompatible
	#OSTOXERROR[ $$ETXTBSY         ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureContention
	#OSTOXERROR[ $$EFBIG           ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureTooLarge
	#OSTOXERROR[ $$ENOSPC          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$ESPIPE          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureInvalidOperation
	#OSTOXERROR[ $$EROFS           ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureInvalidOperation
	#OSTOXERROR[ $$EMLINK          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureTooMany
	#OSTOXERROR[ $$EPIPE           ] = ($$ErrorObjectPipe            << 8) OR $$ErrorNatureTerminated
	#OSTOXERROR[ $$EDOM            ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$ERANGE          ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$ENOMSG          ] = ($$ErrorObjectMessage         << 8) OR $$ErrorNatureMissing
	#OSTOXERROR[ $$EIDRM           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ECHRNG          ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EL2NSYNC        ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureMalfunction
	#OSTOXERROR[ $$EL3HLT          ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureHalted
	#OSTOXERROR[ $$EL3RST          ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureReset
	#OSTOXERROR[ $$ELNRNG          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EUNATCH         ] = ($$ErrorObjectDriver          << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENOCSI          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$EL2HLT          ] = ($$ErrorObjectOperatingSystem << 8) OR $$ErrorNatureHalted
	#OSTOXERROR[ $$EDEADLK         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOLCK          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$EBADE           ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EBADR           ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EXFULL          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$ENOANO          ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureOverflow
	#OSTOXERROR[ $$EBADRQC         ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EBADSLT         ] = ($$ErrorObjectArgument        << 8) OR $$ErrorNatureInvalidValue
	#OSTOXERROR[ $$EDEADLK         ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureDeadlock
	#OSTOXERROR[ $$EBFONT          ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ENOSTR          ] = ($$ErrorObjectDevice          << 8) OR $$ErrorNatureInvalidType
	#OSTOXERROR[ $$ENODATA         ] = ($$ErrorObjectData            << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ETIME           ] = ($$ErrorObjectTimer           << 8) OR $$ErrorNatureTimeout
	#OSTOXERROR[ $$ENOSR           ] = ($$ErrorObjectSystemResource  << 8) OR $$ErrorNatureExhausted
	#OSTOXERROR[ $$ENONET          ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENOPKG          ] = ($$ErrorObjectProgram         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$EREMOTE         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENOLINK         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EADV            ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ESRMNT          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ECOMM           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPROTO          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EMULTIHOP       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
'	#OSTOXERROR[ $$ELBIN           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EDOTDOT         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EBADMSG         ] = ($$ErrorObjectMessage         << 8) OR $$ErrorNatureInvalid
	#OSTOXERROR[ $$ENAMETOOLONG    ] = ($$ErrorObjectFile            << 8) OR $$ErrorNatureInvalidName
	#OSTOXERROR[ $$EOVERFLOW       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOTUNIQ        ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureInvalidIdentity
	#OSTOXERROR[ $$EBADFD          ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$EREMCHG         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ELIBACC         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ELIBBAD         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ELIBSCN         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ELIBMAX         ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureTooMany
	#OSTOXERROR[ $$ELIBEXEC        ] = ($$ErrorObjectLibrary         << 8) OR $$ErrorNatureInvalidAccess
	#OSTOXERROR[ $$EILSEQ          ] = ($$ErrorObjectData            << 8) OR $$ErrorNatureInvalidFormat
	#OSTOXERROR[ $$ENOSYS          ] = ($$ErrorObjectSystemRoutine   << 8) OR $$ErrorNatureNonexistent
	#OSTOXERROR[ $$ETCPERR         ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EWOULDBLOCK     ] = ($$ErrorObjectFunction        << 8) OR $$ErrorNatureWouldBlock
	#OSTOXERROR[ $$EINPROGRESS     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EALREADY        ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOTSOCK        ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureUndefined
	#OSTOXERROR[ $$EDESTADDRREQ    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EMSGSIZE        ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPROTOTYPE      ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOPROTOOPT     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPROTONOSUPPORT ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ESOCKTNOSUPPORT ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EOPNOTSUPP      ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EPFNOSUPPORT    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EAFNOSUPPORT    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EADDRINUSE      ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureContention
	#OSTOXERROR[ $$EADDRNOTAVAIL   ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureInvalidAddress
	#OSTOXERROR[ $$ENETDOWN        ] = ($$ErrorObjectNetwork         << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$ENETUNREACH     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENETRESET       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ECONNABORTED    ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureDisconnected
	#OSTOXERROR[ $$ECONNRESET      ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureReset
	#OSTOXERROR[ $$ENOBUFS         ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EISCONN         ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureInvalidRequest
	#OSTOXERROR[ $$ENOTCONN        ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureNotConnected
	#OSTOXERROR[ $$ESHUTDOWN       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ETOOMANYREFS    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ETIMEDOUT       ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureTimeout
	#OSTOXERROR[ $$ECONNREFUSED    ] = ($$ErrorObjectSocket          << 8) OR $$ErrorNatureNotConnected
	#OSTOXERROR[ $$EHOSTDOWN       ] = ($$ErrorObjectSystem          << 8) OR $$ErrorNatureUnavailable
	#OSTOXERROR[ $$EHOSTUNREACH    ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureUnknown
	#OSTOXERROR[ $$ENOPROTOOPT     ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ENOTEMPTY       ] = ($$ErrorObjectDirectory       << 8) OR $$ErrorNatureNotEmpty
	#OSTOXERROR[ $$ELOOP           ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$ESTALE          ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
	#OSTOXERROR[ $$EIORESID        ] = ($$ErrorObjectNone            << 8) OR $$ErrorNatureError
END SUB
END FUNCTION
'
'
' ###################################
' #####  XstQuickSort_XLONG ()  #####
' ###################################
'
'	XstQuickSort() has guaranteed all arguments are valid.
'
'	Input:
'		a[]		= 1D array of XLONG data to be sorted
'		n[]		= corresponding index array (optional)
'		low		= first index to sort
'		high	= last index to sort
'		order	= Increasing (0) or Decreasing (1)
'
'	Output:
'		a[]		= intermediate sorted data
'		n[]		= intermediate sorted indices (optional)
'
'	Return:
'		none
'
FUNCTION  XstQuickSort_XLONG (a[], n[], low, high, order)
	IF (low >= high) THEN RETURN								' less than two elements
'
	IF (order = $$SortDecreasing) THEN
		IF ((high - low) = 1) THEN								' two element left
			IF (a[low] > a[high]) THEN RETURN				' a[] correct order
			IF (a[low] < a[high]) THEN
				SWAP a[low], a[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a[low], a[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a[high], a[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
'
		partition = a[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE (i < j) AND (a[i] >= partition)
					INC i
				LOOP
				DO WHILE (j > i) AND (a[j] <= partition)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (a[i] < partition) THEN EXIT DO
					IF (a[i] = partition) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (a[j] > partition) THEN EXIT DO
					IF (a[j] = partition) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a[i], a[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
'
	ELSE
		IF ((high - low) = 1) THEN								' two element left
			IF (a[low] < a[high]) THEN RETURN				' a[] correct order
			IF (a[low] > a[high]) THEN
				SWAP a[low], a[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a[low], a[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a[high], a[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
'
		partition = a[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE (i < j) AND (a[i] <= partition)
					INC i
				LOOP
				DO WHILE (j > i) AND (a[j] >= partition)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (a[i] > partition) THEN EXIT DO
					IF (a[i] = partition) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (a[j] < partition) THEN EXIT DO
					IF (a[j] = partition) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a[i], a[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	END IF
'
	SWAP a[i], a[high]
	IF n[] THEN SWAP n[i], n[high]
'
	IF i > low + 1 THEN XstQuickSort_XLONG (@a[], @n[], low, i-1, order)
	IF i < high - 1 THEN XstQuickSort_XLONG (@a[], @n[], i+1, high, order)
END FUNCTION
'
'
' ###################################
' #####  XstQuickSort_GIANT ()  #####
' ###################################
'
'	XstQuickSort() has guaranteed all arguments are valid.
'
'	Input:
'		a$$[]	= 1D array of GIANT data to be sorted
'		n[]		= corresponding index array (optional)
'		low		= first index to sort
'		high	= last index to sort
'		order	= Increasing (0) or Decreasing (1)
'
'	Output:
'		a$$[]	= intermediate sorted data
'		n[]		= intermediate sorted indices (if requested)
'
'	Return:
'		none
'
FUNCTION  XstQuickSort_GIANT (a$$[], n[], low, high, order)
	IF (low >= high) THEN RETURN								' less than two elements
'
	IF (order = $$SortDecreasing) THEN
		IF ((high - low) = 1) THEN								' two element left
			IF (a$$[low] > a$$[high]) THEN RETURN		' a$$[] correct order
			IF (a$$[low] < a$$[high]) THEN
				SWAP a$$[low], a$$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$$[low], a$$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$$[high], a$$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
'
		partition$$ = a$$[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE (i < j) AND (a$$[i] >= partition$$)
					INC i
				LOOP
				DO WHILE (j > i) AND (a$$[j] <= partition$$)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (a$$[i] < partition$$) THEN EXIT DO
					IF (a$$[i] = partition$$) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (a$$[j] > partition$$) THEN EXIT DO
					IF (a$$[j] = partition$$) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$$[i], a$$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
'
	ELSE
'
		IF ((high - low) = 1) THEN								' two element left
			IF (a$$[low] < a$$[high]) THEN RETURN		' a$$[] correct order
			IF (a$$[low] > a$$[high]) THEN
				SWAP a$$[low], a$$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$$[low], a$$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$$[high], a$$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
'
		partition$$ = a$$[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE (i < j) AND (a$$[i] <= partition$$)
					INC i
				LOOP
				DO WHILE (j > i) AND (a$$[j] >= partition$$)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (a$$[i] > partition$$) THEN EXIT DO
					IF (a$$[i] = partition$$) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (a$$[j] < partition$$) THEN EXIT DO
					IF (a$$[j] = partition$$) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$$[i], a$$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	END IF
'
	SWAP a$$[i], a$$[high]
	IF n[] THEN SWAP n[i], n[high]
'
	IF i > low + 1 THEN XstQuickSort_GIANT (@a$$[], @n[], low, i-1, order)
	IF i < high - 1 THEN XstQuickSort_GIANT (@a$$[], @n[], i+1, high, order)
END FUNCTION
'
'
' ####################################
' #####  XstQuickSort_DOUBLE ()  #####
' ####################################
'
'	XstQuickSort() has guaranteed all arguments are valid.
'
'	Input:
'		a#[]	= 1D array of DOUBLE data to be sorted
'		n[]		= corresponding index array (optional)
'		low		= first index to sort
'		high	= last index to sort
'		order	= Increasing (0) or Decreasing (1)
'
'	Output:
'		a#[]	= intermediate sorted data
'		n[]		= intermediate sorted indices (if requested)
'
'	Return:
'		none
'
FUNCTION  XstQuickSort_DOUBLE (a#[], n[], low, high, order)
	IF (low >= high) THEN RETURN								' less than two elements
'
	IF (order = $$SortDecreasing) THEN
		IF ((high - low) = 1) THEN								' two element left
			IF (a#[low] > a#[high]) THEN RETURN			' a#[] correct order
			IF (a#[low] < a#[high]) THEN
				SWAP a#[low], a#[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a#[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a#[low], a#[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a#[high], a#[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
'
		partition# = a#[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE (i < j) AND (a#[i] >= partition#)
					INC i
				LOOP
				DO WHILE (j > i) AND (a#[j] <= partition#)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (a#[i] < partition#) THEN EXIT DO
					IF (a#[i] = partition#) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (a#[j] > partition#) THEN EXIT DO
					IF (a#[j] = partition#) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a#[i], a#[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
'
	ELSE
'
		IF ((high - low) = 1) THEN								' two element left
			IF (a#[low] < a#[high]) THEN RETURN			' a#[] correct order
			IF (a#[low] > a#[high]) THEN
				SWAP a#[low], a#[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a#[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a#[low], a#[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a#[high], a#[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
'
		partition# = a#[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE (i < j) AND (a#[i] <= partition#)
					INC i
				LOOP
				DO WHILE (j > i) AND (a#[j] >= partition#)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (a#[i] > partition#) THEN EXIT DO
					IF (a#[i] = partition#) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (a#[j] < partition#) THEN EXIT DO
					IF (a#[j] = partition#) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a#[i], a#[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	END IF
'
	SWAP a#[i], a#[high]
	IF n[] THEN SWAP n[i], n[high]
'
	IF i > low + 1 THEN XstQuickSort_DOUBLE (@a#[], @n[], low, i-1, order)
	IF i < high - 1 THEN XstQuickSort_DOUBLE (@a#[], @n[], i+1, high, order)
END FUNCTION
'
'
' ####################################
' #####  XstQuickSort_STRING ()  #####
' ####################################
'
'	XstQuickSort() has guaranteed all arguments are valid.
'
'	Input:
'		a$[]	= 1D array of STRING data to be sorted
'		n[]		= corresponding index array (optional)
'		low		= first index to sort
'		high	= last index to sort
'		order	= Increasing (0) or Decreasing (1)
'
'	Output:
'		a$[]	= intermediate sorted data
'		n[]		= intermediate sorted indices (if requested)
'
'	Return:
'		none
'
FUNCTION  XstQuickSort_STRING (a$[], n[], low, high, order)
'
	IF (low >= high) THEN RETURN								' less than two elements
'
	IF (order AND $$SortDecreasing) THEN				' "z" to "A"
		IF ((high - low) = 1) THEN								' two element left
'			IF (a$[low] > a$[high]) THEN RETURN			' a$[] correct order
			IF XstCompareStrings (&a$[low], $$GT, &a$[high], order) THEN RETURN			' a$[] correct order
'			IF (a$[low] < a$[high]) THEN
			IF XstCompareStrings (&a$[low], $$LT, &a$[high], order) THEN
				SWAP a$[low], a$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$[low], a$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$[high], a$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
		partition$ = a$[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
'				DO WHILE ((i < j) AND (a$[i] >= partition$))
				DO WHILE ((i < j) AND XstCompareStrings (&a$[i], $$GE, &partition$, order))
					INC i
				LOOP
'				DO WHILE ((j > i) AND (a$[j] <= partition$))
				DO WHILE ((j > i) AND XstCompareStrings (&a$[j], $$LE, &partition$, order))
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
'					IF (a$[i] < partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[i], $$LT, &partition$, order) THEN EXIT DO
'					IF (a$[i] = partition$) THEN
					IF XstCompareStrings (&a$[i], $$EQ, &partition$, order) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
'					IF (a$[j] > partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[j], $$GT, &partition$, order) THEN EXIT DO
'					IF (a$[j] = partition$) THEN
					IF XstCompareStrings (&a$[j], $$EQ, &partition$, order) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$[i], a$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	ELSE
		IF ((high - low) = 1) THEN								' two element left
'			IF (a$[low] < a$[high]) THEN RETURN			' a$[] correct order
			IF XstCompareStrings (&a$[low], $$LT, &a$[high], order) THEN RETURN			' a$[] correct order
'			IF (a$[low] > a$[high]) THEN
			IF XstCompareStrings (&a$[low], $$GT, &a$[high], order) THEN
				SWAP a$[low], a$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$[low], a$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$[high], a$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
		partition$ = a$[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
'				DO WHILE (i < j) AND (a$[i] <= partition$)
				DO WHILE (i < j) AND XstCompareStrings (&a$[i], $$LE, &partition$, order)
					INC i
				LOOP
'				DO WHILE (j > i) AND (a$[j] >= partition$)
				DO WHILE (j > i) AND XstCompareStrings (&a$[j], $$GE, &partition$, order)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
'					IF (a$[i] > partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[i], $$GT, &partition$, order) THEN EXIT DO
'					IF (a$[i] = partition$) THEN
					IF XstCompareStrings (&a$[i], $$EQ, &partition$, order) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
'					IF (a$[j] < partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[j], $$LT, &partition$, order) THEN EXIT DO
'					IF (a$[j] = partition$) THEN
					IF XstCompareStrings (&a$[j], $$EQ, &partition$, order) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$[i], a$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	END IF
'
	SWAP a$[i], a$[high]
	IF n[] THEN SWAP n[i], n[high]
'
	IF i > low + 1 THEN XstQuickSort_STRING (@a$[], @n[], low, i-1, order)
	IF i < high - 1 THEN XstQuickSort_STRING (@a$[], @n[], i+1, high, order)
END FUNCTION
'
'
' ###########################################
' #####  XstQuickSort_STRING_nocase ()  #####
' ###########################################
'
'	XstQuickSort() has guaranteed all arguments are valid.
'
'	Input:
'		a$[]	= 1D array of STRING data to be sorted
'		n[]		= corresponding index array (optional)
'		low		= first index to sort
'		high	= last index to sort
'		order	= Increasing (0) or Decreasing (1)
'
'	Output:
'		a$[]	= intermediate sorted data
'		n[]		= intermediate sorted indices (if requested)
'
'	Return:
'		none
'
FUNCTION  XstQuickSort_STRING_nocase (a$[], n[], low, high, order)
'
	IF (low >= high) THEN RETURN								' less than two elements
'
	IF (order AND $$SortDecreasing) THEN				' "z" to "A"
		IF ((high - low) = 1) THEN								' two element left
			IF (UCASE$(a$[low]) > UCASE$(a$[high])) THEN RETURN			' a$[] correct order
			IF (UCASE$(a$[low]) < UCASE$(a$[high])) THEN
				SWAP a$[low], a$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$[low], a$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$[high], a$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
		IF n[] THEN nPartition = n[high]
		partition$ = UCASE$(a$[high])
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE ((i < j) AND (UCASE$(a$[i]) >= partition$))
					INC i
				LOOP
				DO WHILE ((j > i) AND (UCASE$(a$[j]) <= partition$))
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (UCASE$(a$[i]) < partition$) THEN EXIT DO
					IF (UCASE$(a$[i]) == partition$) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (UCASE$(a$[j]) > partition$) THEN EXIT DO
					IF (UCASE$(a$[j]) == partition$) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$[i], a$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	ELSE
		IF ((high - low) = 1) THEN								' two element left
			IF (UCASE$(a$[low]) < UCASE$(a$[high])) THEN RETURN			' a$[] correct order
			IF (UCASE$(a$[low]) > UCASE$(a$[high])) THEN
				SWAP a$[low], a$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$[low], a$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$[high], a$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
		IF n[] THEN nPartition = n[high]
		partition$ = UCASE$(a$[high])
		i = low: j = high
		DO
			IFZ n[] THEN
				DO WHILE (i < j) AND (UCASE$(a$[i]) <= partition$)
					INC i
				LOOP
				DO WHILE (j > i) AND (UCASE$(a$[j]) >= partition$)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
					IF (UCASE$(a$[i]) > partition$) THEN EXIT DO
					IF (UCASE$(a$[i]) == partition$) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
					IF (UCASE$(a$[j]) < partition$) THEN EXIT DO
					IF (UCASE$(a$[j]) == partition$) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$[i], a$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	END IF
'
	SWAP a$[i], a$[high]
	IF n[] THEN SWAP n[i], n[high]
'
	IF i > low + 1 THEN XstQuickSort_STRING_nocase (@a$[], @n[], low, i-1, order)
	IF i < high - 1 THEN XstQuickSort_STRING_nocase (@a$[], @n[], i+1, high, order)
END FUNCTION
'
'
' ###########################################
' #####  XstQuickSort_NumericSTRING ()  #####
' ###########################################
'
'	XstQuickSort() has guaranteed all arguments are valid.
'
'	Input:
'		a$[]	= 1D array of STRING data to be sorted
'		n[]		= corresponding index array (optional)
'		low		= first index to sort
'		high	= last index to sort
'		order	= Increasing (0) or Decreasing (1)
'
'	Output:
'		a$[]	= intermediate sorted data
'		n[]		= intermediate sorted indices (if requested)
'
'	Return:
'		none
'
FUNCTION  XstQuickSort_NumericSTRING (a$[], n[], low, high, order)
'
	IF (low >= high) THEN RETURN								' less than two elements
'
	IF (order AND $$SortDecreasing) THEN				' "z" to "A"
		IF ((high - low) = 1) THEN								' two element left
'			IF (a$[low] > a$[high]) THEN RETURN			' a$[] correct order
			IF XstCompareStrings (&a$[low], $$GT, &a$[high], order) THEN RETURN			' a$[] correct order
'			IF (a$[low] < a$[high]) THEN
			IF XstCompareStrings (&a$[low], $$LT, &a$[high], order) THEN
				SWAP a$[low], a$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$[low], a$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$[high], a$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
		partition$ = a$[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
'				DO WHILE ((i < j) AND (a$[i] >= partition$))
				DO WHILE ((i < j) AND XstCompareStrings (&a$[i], $$GE, &partition$, order))
					INC i
				LOOP
'				DO WHILE ((j > i) AND (a$[j] <= partition$))
				DO WHILE ((j > i) AND XstCompareStrings (&a$[j], $$LE, &partition$, order))
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
'					IF (a$[i] < partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[i], $$LT, &partition$, order) THEN EXIT DO
'					IF (a$[i] = partition$) THEN
					IF XstCompareStrings (&a$[i], $$EQ, &partition$, order) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
'					IF (a$[j] > partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[j], $$GT, &partition$, order) THEN EXIT DO
'					IF (a$[j] = partition$) THEN
					IF XstCompareStrings (&a$[j], $$EQ, &partition$, order) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$[i], a$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	ELSE
		IF ((high - low) = 1) THEN								' two element left
'			IF (a$[low] < a$[high]) THEN RETURN			' a$[] correct order
			IF XstCompareStrings (&a$[low], $$LT, &a$[high], order) THEN RETURN			' a$[] correct order
'			IF (a$[low] > a$[high]) THEN
			IF XstCompareStrings (&a$[low], $$GT, &a$[high], order) THEN
				SWAP a$[low], a$[high]
				IF n[] THEN SWAP n[low], n[high]
			ELSE
				IFZ n[] THEN RETURN										' a$[] equal:  use n[]
				IF (n[low] > n[high]) THEN						' n[] sort $$SortIncreasing
					SWAP a$[low], a$[high]
					SWAP n[low], n[high]
				END IF
			END IF
			RETURN
		END IF
		midPoint = (high + low) >> 1
		SWAP a$[high], a$[midPoint]
		IF n[] THEN SWAP n[high], n[midPoint]
		partition$ = a$[high]
		IF n[] THEN nPartition = n[high]
		i = low: j = high
		DO
			IFZ n[] THEN
'				DO WHILE (i < j) AND (a$[i] <= partition$)
				DO WHILE (i < j) AND XstCompareStrings (&a$[i], $$LE, &partition$, order)
					INC i
				LOOP
'				DO WHILE (j > i) AND (a$[j] >= partition$)
				DO WHILE (j > i) AND XstCompareStrings (&a$[j], $$GE, &partition$, order)
					DEC j
				LOOP
			ELSE
				DO WHILE (i < j)
'					IF (a$[i] > partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[i], $$GT, &partition$, order) THEN EXIT DO
'					IF (a$[i] = partition$) THEN
					IF XstCompareStrings (&a$[i], $$EQ, &partition$, order) THEN
						IF (n[i] > nPartition) THEN EXIT DO
					END IF
					INC i
				LOOP
				DO WHILE (j > i)
'					IF (a$[j] < partition$) THEN EXIT DO
					IF XstCompareStrings (&a$[j], $$LT, &partition$, order) THEN EXIT DO
'					IF (a$[j] = partition$) THEN
					IF XstCompareStrings (&a$[j], $$EQ, &partition$, order) THEN
						IF (n[j] < nPartition) THEN EXIT DO
					END IF
					DEC j
				LOOP
			END IF
			IF (i < j) THEN
				SWAP a$[i], a$[j]
				IF n[] THEN SWAP n[i], n[j]
			END IF
		LOOP WHILE (i < j)
	END IF
'
	SWAP a$[i], a$[high]
	IF n[] THEN SWAP n[i], n[high]
'
	IF i > low + 1 THEN XstQuickSort_NumericSTRING (@a$[], @n[], low, i-1, order)
	IF i < high + 1 THEN XstQuickSort_NumericSTRING (@a$[], @n[], i+1, high, order)
END FUNCTION
'
'
' #####################################
' #####  XxxXstTaskController ()  #####
' #####################################
'
FUNCTION  XxxXstTaskController (grid, message, timer, count, msec, time, r0, taskNum)
	SHARED TASK task[]
	SHARED systemTaskGrid
	SHARED userTaskGrid
	AUTOX  FUNCADDR  call ()
'
	IF (message != #TimeOut) THEN
		IF ##XBDV THEN PRINT "XxxXstTaskController()", grid, message, timer, count, msec, time, r0, taskNum
		RETURN
	END IF
'
	IF ##WHOMASK THEN
		taskGrid = userTaskGrid
	ELSE
		taskGrid = systemTaskGrid
	END IF
'
	maxTask = UBOUND (task[])
'
	SELECT CASE TRUE
		CASE grid != taskGrid                    : error$ = "Invalid grid"
		CASE taskNum > maxTask                   : error$ = "Out-of-bounds taskNum"
		CASE task[taskNum].count == 0            : XstKillTask (taskNum) : RETURN
		CASE task[taskNum].timer != timer        : error$ = "task[].timer != timer"
		CASE task[taskNum].taskFunc == 0         : error$ = "no taskFunc"
		CASE task[taskNum].whomask != ##WHOMASK  : error$ = "wrong whomask"
	END SELECT
	IF error$ THEN
		PRINT "XxxXstTaskController()", error$, taskNum, timer, task[taskNum].timer
		XstKillTask (taskNum)
		RETURN
	END IF
'
	task[taskNum].request = $$FALSE     ' request has been received
'
	IFZ ##STANDALONE THEN
		IF task[taskNum].whomask THEN     ' user task
			IFZ ##USERRUNNING  THEN RETURN  ' user not running
		END IF
	END IF
'
	IFZ task[taskNum].engaged THEN
		task[taskNum].engaged = $$TRUE
		count = task[taskNum].count
		IF count THEN
			IF (count != -1) THEN DEC count        ' decrement count if not running forever
		END IF
		task[taskNum].count = count
		call = task[taskNum].taskFunc
		whomask = ##WHOMASK
		##WHOMASK = task[taskNum].whomask
		kill = @call ()                          ' actually call the task
		##WHOMASK = whomask
		task[taskNum].engaged = $$FALSE
		IFZ count THEN kill = $$TRUE
		IF kill THEN XstKillTask (taskNum)
	END IF
'
	RETURN
'
END FUNCTION
'
'
' ################################
' #####  XxxXstTaskTimer ()  #####
' ################################
'
FUNCTION  XxxXstTaskTimer (tgrid, timer, @count, msec, time)
	SHARED TASK task[]
	SHARED systemTaskGrid
	SHARED userTaskGrid
'
	IF ##BLOWBACK THEN RETURN
	taskNum = NOT tgrid
	maxTask = UBOUND (task[])
'
	SELECT CASE TRUE
		CASE taskNum < 1                  : kill = $$TRUE
		CASE taskNum > maxTask            : kill = $$TRUE
		CASE task[taskNum].timer != timer : kill = $$TRUE
		CASE task[taskNum].taskFunc == 0  : kill = $$TRUE
		CASE task[taskNum].count == 0     : kill = $$TRUE
	END SELECT
'
	IF task[taskNum].whomask THEN
		taskGrid = userTaskGrid
	ELSE
		taskGrid = systemTaskGrid
	END IF
'
	IFZ taskGrid THEN kill = $$TRUE
'
	IF kill THEN
		count = 0
		RETURN (-1)
	END IF
'
	IF task[taskNum].request THEN taskError = 0xBAD2
	IF task[taskNum].engaged THEN taskError = 0xBAD1
'
	IF taskError THEN
		IF ##BLOWBACK THEN RETURN
		count = task[taskNum].count
		msec  = task[taskNum].msec
		whomask = ##WHOMASK
		IFF (whomask && ##SIGNALACTIVE) THEN
			##WHOMASK = 0
			XgrGetModalWindow (@##mw)
			IFZ ##mw THEN
				INC task[taskNum].skips
			END IF
			##WHOMASK = whomask
		END IF
		IF (count == -1) THEN count = 0x7FFFFFFF      ' forever ?
		RETURN                                        ' Don't start task again if already active
	END IF
'
' If in PDE mode, do not run a user task if the user program is not running
'
	IFZ ##STANDALONE THEN
		IF task[taskNum].whomask THEN     ' user task
			IFZ ##USERRUNNING  THEN         ' user not running
				count = 0
				RETURN (-1)
			END IF
			IF  ##SIGNALACTIVE THEN RETURN  ' user paused
		END IF
	END IF
'
	whomask = ##WHOMASK
	##WHOMASK = task[taskNum].whomask
	error = XgrJamMessage (taskGrid, #TimeOut, timer, count, msec, time, 0, taskNum)
	##WHOMASK = whomask
	IFZ error THEN
		task[taskNum].request = $$TRUE
	ELSE
		INC task[taskNum].skips
	END IF
	count = task[taskNum].count
	msec  = task[taskNum].msec
	IF (count == -1) THEN count = 0x7FFFFFFF                                       ' forever ?
'
END FUNCTION
'
'
' #######################
' #####  XxxLog ()  #####
' #######################
'
FUNCTION  XxxLog (text$)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IF ##TIMERLOCKOUT THEN RETURN ($$FALSE)
	IFZ ##XBDV THEN RETURN ($$FALSE)
	IFZ text$  THEN RETURN ($$FALSE)
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300037
	write (1, &text$, LEN(text$))
	IF (RIGHT$(text$) != "\n") THEN
		write (1, &"\n", 1)
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	XstLog (text$)
'
END FUNCTION
'
'
' ########################
' #####  XxxLog2 ()  #####
' ########################
'
FUNCTION  XxxLog2 (text$, int)
	STATIC count
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	traceOff = ##TRACEOFF
'
	IF (count > 99) THEN RETURN
	INC count
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300038
	write (1, &text$, LEN(text$))
	text2$ = " " + STR$(int)
'	text2$ = " " + HEXX$(int)
	write (1, &text2$, LEN(text2$))
	IF (RIGHT$(text$) != "\n") THEN
		write (1, &"\n", 1)
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	XstLog (text$)
'
END FUNCTION
'
' ######################
' #####  XxxLog10  #####
' ######################
'
' This is to assist in generating log messages for debugging purposes.
'
' Logs are only generated when the environment variable "XBASICDEVELOPER=yes"
' and the "Caps Lock" key is operated. The message is converted to its
' massage name string, and if the message is #Callback, the meassage number
' in r1 is also shown as a message string.
'
' If the grid is not equal to the console grid, a sequence number and the
' message is also printed on the console window.
'
FUNCTION  XxxLog10 (logMessage$, window, grid, message, v0, v1, v2, v3, r0, r1)
	STATIC prtSeqNum
'
	IFZ ##XBDV THEN RETURN  ' XxxLog10 only works for XBasic developer
'
'	PRINT "XxxLog10(21)", ##CAPSLOCK
	IF (##CAPSLOCK <> 0x12345678) THEN RETURN
	IFZ logMessage$ THEN logMessage$ = "XxxLog10"
	log$ = logMessage$+" "+HEX$(window)+" "+HEX$(grid)
	IF message THEN
		IFF XgrMessageNumberToName (message, @messageName$) THEN
			log$ = log$+" "+ messageName$
		ELSE
			log$ = log$+" - "
		END IF
	END IF
	log$ = log$+" "+HEX$(v0)+" "+HEX$(v1)+" "+HEX$(v2)+" "+HEX$(v3)+" "+HEX$(r0)+" "+HEX$(r1)
	IF (message == #Callback) THEN
		XgrMessageNumberToName (r1, @messageName$)
		IF messageName$ THEN log$ = log$+" r1 = "+ messageName$
	END IF
	XstLog(log$)      ' XxxLog10 now writes log file with XstLog
'	XxxLog(log$)      ' XxxLog10 now writes
'	IF GetKeyState($$KeyControl) THEN
		INC prtSeqNum
		IF (message == #TimeOut) THEN RETURN
		IF (grid == ##CONGRID) THEN RETURN    'Try to prevent endless loop
		PRINT prtSeqNum, " - ", log$
'	END IF
'
END FUNCTION
'
'
' ##########################
' #####  XxxAccess ()  #####
' ##########################
'
' fail = XxxAccess (fileName$, mode)
'
' values for mode:
'	$$R_OK - test for read permission
'	$$W_OK - test for write permission
'	$$X_OK - test for execute permission
'	$$F_OK - test for existence
'
' fail will be TRUE if any of the tests is not successful
'
FUNCTION  XxxAccess (fileName$, mode)

	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	##WHOMASK = 0
	##LOCKOUT = 300039
	fail = access (&fileName$, mode)
	##LOCKOUT = lockout
	##WHOMASK = whomask

	RETURN fail

END FUNCTION
'
'
' #########################
' #####  XxxClose ()  #####
' #########################
'
FUNCTION  XxxClose (fileNumber)
	SHARED	FILE  fileInfo[]
	SHARED  LOCK  fileLock[]
'
	IFZ fileInfo[] THEN
		IF (fileNumber != -1) THEN GOTO eeeBadFileNumber
		RETURN ($$FALSE)
	END IF
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxClose()lockout", lockout)
'
	err = $$FALSE
	##ERROR = $$FALSE
	uFile = UBOUND(fileInfo[])
	IF (fileNumber = $$ALL) THEN
		IFZ ##WHOMASK THEN
			firstNumber = 1    ' system may close console
			##CONGRID = 0
		ELSE
			firstNumber = 3
		END IF
		FOR fileNumber = firstNumber TO uFile
			fileHandle = fileInfo[fileNumber].fileHandle
			IFZ fileHandle THEN DO NEXT
			IF ##WHOMASK THEN
				IFZ fileInfo[fileNumber].whomask THEN DO NEXT
			END IF
			GOSUB CloseFileHandle
		NEXT fileNumber
		fileNumber = $$ALL
	ELSE
		IF InvalidFileNumber (fileNumber) THEN RETURN ($$FALSE)
		fileHandle = fileInfo[fileNumber].fileHandle
		GOSUB CloseFileHandle
	END IF
	RETURN (err)
'
SUB CloseFileHandle
	consoleGrid = fileInfo[fileNumber].consoleGrid
	IFZ consoleGrid THEN
		IF fileLock[] THEN
			IF (file <= UBOUND (fileLock[]))
				IF fileLock[file,] THEN
					FOR i = 0 TO UBOUND (fileLock[file,])
						IF fileLock[file,i].file THEN
							IF fileLock[file,i].sfile THEN
								offset$$ = fileLock[file,i].offset
								length$$ = fileLock[file,i].length
								XstUnlockFileSection (file, 0, offset$$, length$$)
							END IF
						END IF
					NEXT i
				END IF
			END IF
		END IF
		##WHOMASK = 0
		##LOCKOUT = 300040
		a = close (fileHandle)
		##WHOMASK = whomask
		##LOCKOUT = lockout
		IF a THEN
			GOSUB CloseError
		ELSE
			fileInfo[fileNumber].fileName			= ""
			fileInfo[fileNumber].fileHandle		= 0
			fileInfo[fileNumber].whomask			= 0
			fileInfo[fileNumber].consoleGrid	= 0
			fileInfo[fileNumber].entries			= 0
		END IF
	ELSE
		DEC fileInfo[fileNumber].entries
		IF (fileInfo[fileNumber].entries > 0) THEN EXIT SUB
		EXIT SUB                                                   'Destroying console not allowed at this time
		##WHOMASK = 0
		XuiSendMessage (consoleGrid, #Destroy, 0, 0, 0, 0, 0, 0)
		##WHOMASK = whomask
		fileInfo[fileNumber].fileName			= ""
		fileInfo[fileNumber].fileHandle		= 0
		fileInfo[fileNumber].whomask			= 0
		fileInfo[fileNumber].consoleGrid	= 0
		fileInfo[fileNumber].entries			= 0
	END IF
END SUB
'
SUB CloseError
	XstSystemErrorToError (xb_geterrno(), @error)
	##ERROR = error : ##WHERE = 31970091
'	PRINT "XxxClose(A)error", error
	err = $$TRUE
END SUB
'
eeeBadFileNumber:
	error = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument
	##ERROR = error : ##WHERE = 31970098
'	PRINT "XxxClose(B)error", error
	RETURN ($$TRUE)
END FUNCTION
'
'
' ################################
' #####  XxxCloseAllUser ()  #####
' ################################
'
FUNCTION  XxxCloseAllUser ()
	SHARED	FILE	fileInfo[]
'
	IFZ fileInfo[] THEN RETURN ($$FALSE)			' No files open
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxCloseAllUser()lockout", lockout)
'
	err = $$FALSE
	uFiles = UBOUND(fileInfo[])
	FOR fileNumber = 3 TO uFiles
		fileHandle = fileInfo[fileNumber].fileHandle
		IFZ fileHandle THEN DO NEXT
		IF fileInfo[fileNumber].whomask THEN GOSUB CloseFileHandle
	NEXT fileNumber
	RETURN (err)
'
SUB CloseFileHandle
	consoleGrid = fileInfo[fileNumber].consoleGrid
	IFZ consoleGrid THEN
		##WHOMASK = 0
		##LOCKOUT = 300041
		a = close (fileHandle)
		##WHOMASK = whomask
		##LOCKOUT = lockout
		IF a THEN
			GOSUB CloseError
		ELSE
			fileInfo[fileNumber].fileName			= ""
			fileInfo[fileNumber].fileHandle		= 0
			fileInfo[fileNumber].whomask			= 0
			fileInfo[fileNumber].consoleGrid	= 0
			fileInfo[fileNumber].entries			= 0
		END IF
	ELSE
		DEC fileInfo[fileNumber].entries
		IF (fileInfo[fileNumber].entries > 0) THEN EXIT SUB
		XuiSendMessage (consoleGrid, #Destroy, 0, 0, 0, 0, 0, 0)
		fileInfo[fileNumber].fileName			= ""
		fileInfo[fileNumber].fileHandle		= 0
		fileInfo[fileNumber].whomask			= 0
		fileInfo[fileNumber].consoleGrid	= 0
		fileInfo[fileNumber].entries			= 0
	END IF
END SUB
'
SUB CloseError
	XstSystemErrorToError (xb_geterrno(), @error)
'	PRINT "XxxCloseAllUser()error", error
	##ERROR = error : ##WHERE = 31980057
	err = $$TRUE
END SUB
END FUNCTION
'
'
' #######################
' #####  XxxEof ()  #####
' #######################
'
FUNCTION  XxxEof (fileNumber)
	SHARED  FILE  fileInfo[]
'
	IF InvalidFileNumber (fileNumber) THEN RETURN ($$TRUE)	' invalid file
	fileHandle = fileInfo[fileNumber].fileHandle
	IF (fileHandle = -1) THEN RETURN ($$TRUE)								' console file
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxEof()lockout", lockout)
	whomask = ##WHOMASK
	##LOCKOUT = 300042
	##WHOMASK = 0
'
	xb_seterrno($$FALSE)
	##WHOMASK = 0
	##LOCKOUT = 300043
	c = lseek (fileHandle, 0, $$SEEK_CUR)			' get file position
	##WHOMASK = whomask
	##LOCKOUT = lockout
	IF (c < 0) THEN GOTO SeekError
	IF (c >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
'
	##WHOMASK = 0
	##LOCKOUT = 300044
	s = lseek (fileHandle, 0, $$SEEK_END)			' get size of file
	##WHOMASK = whomask
	##LOCKOUT = lockout
	IF (s < 0) THEN GOTO SeekError
	IF (s >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
'
	##WHOMASK = 0
	##LOCKOUT = 300045
	a = lseek (fileHandle, c, $$SEEK_SET)			' restore file pointer
	##WHOMASK = whomask
	##LOCKOUT = lockout
	IF (a < 0) THEN GOTO SeekError
	IF (a >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
'
	IF (c >= s) THEN RETURN ($$TRUE)
	RETURN ($$FALSE)
'
'	error
'
SeekError:
	XstSystemErrorToError (xb_geterrno(), @error)
'	PRINT "XxxEof():error", error
	##ERROR = error : ##WHERE = 31990050
	RETURN ($$TRUE)
END FUNCTION
'
'
' ###########################
' #####  XxxInfile$ ()  #####
' ###########################
'
FUNCTION  XxxInfile$ (fileNumber)
	SHARED  FILE  fileInfo[]
	SHARED  bufferFile0$       '*cw* 110617 testing see XxxWriteFile()
'
	IF InvalidFileNumber(fileNumber) THEN
		IFZ fileNumber THEN
			text$ = bufferFile0$
			bufferFile0$ = ""
			RETURN (text$)
		END IF
		IF (fileNumber != 1) THEN RETURN ("")
		IFZ fileInfo[] THEN RETURN ("")
		IFZ fileInfo[1].fileHandle THEN RETURN ("")		' not initialized
	END IF
	fileHandle = fileInfo[fileNumber].fileHandle
	IF (fileHandle = -1) THEN												' XuiConsole
		consoleGrid = fileInfo[fileNumber].consoleGrid
		XuiSendMessage (consoleGrid, #Inline, 0, 0, 0, 0, 0, @text$)
		XxxXgrSysMessages ()
		RETURN (text$)
	END IF
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxInfile$()lockout", lockout)
	whomask = ##WHOMASK
'
	##WHOMASK = 0
	##LOCKOUT = 300046
	p = lseek (fileHandle, 0, $$SEEK_CUR)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IF (p < 0) THEN GOTO SeekError
	IF (p >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
	a$			= NULL$ (530)
	bufAddr	= &a$
	length	= 0
	nl			= 0
'
	DO
		##WHOMASK = 0
		##LOCKOUT = 300047
		a = read (fileHandle, bufAddr, 86)  ' read up to 86 bytes
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IF (a < 0) THEN GOTO ReadError
		IFZ (a OR length) THEN GOTO ReadError
'
		nl = INSTR(a$, "\n", length + 1)	' \n in last segment?
		IF nl THEN
			length = nl - 1
			a${length} = 0									' put null terminator over <nl>
			IF length THEN
				cr = a${length-1}							' Check for <cr> before <nl>.  Why?
				IF (cr = 13) THEN							' Because WindowsNT sends <cr> + <nl>
					DEC length
					a${length} = 0							' put null terminator over <cr>
				END IF
			END IF
			EXIT DO
		END IF
'
		length = length + a
		bytesLeft = LEN (a$) - length
		IF (bytesLeft < 87) THEN a$ = a$ + NULL$ (530)
		bufAddr	= &a$ + length											' bufAddr = next input address
'
' Check for end-of-file without "\n"
'
		IFZ a THEN
			##WHOMASK = 0
			##LOCKOUT = 300048
			end = lseek (fileHandle, 0, $$SEEK_END)			' get size of file
			##LOCKOUT = lockout
			##WHOMASK = whomask
'
			IF ((p + length) >= end) THEN EXIT DO
		END IF
	LOOP
'
' n = number of characters including newline <nl>
'
	IFZ length THEN
		a$ = ""
	ELSE
		aAddr = &a$
		XLONGAT (aAddr, -16)			= length				' put length in header
		UBYTEAT (aAddr, length)	= 0							' put null byte over <nl>
	END IF
'
	IF nl THEN
		p = p + nl															' put file pointer after <nl>
	ELSE
		p = p + length													' put file pointer after last char
	END IF
'
	##WHOMASK = 0
	##LOCKOUT = 300049
	a = lseek (fileHandle, p, $$SEEK_SET)
	##WHOMASK = whomask
	##LOCKOUT = lockout
	IF (a < 0) THEN GOTO SeekError
	IF (a >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
	RETURN (a$)
'
'	Error
'
SeekError:
	XstSystemErrorToError (xb_geterrno(), @error)
'	PRINT "XxxInfile$(A):error", error
	##ERROR = error : ##WHERE = 32000115
	RETURN
'
ReadError:
	IF (a = 0) THEN
		##WHOMASK = 0
		##LOCKOUT = 300050
		s = lseek (fileHandle, 0, $$SEEK_END)			' get size of file
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IF (s < 0) THEN GOTO SeekError
		IF (s >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
'
		##WHOMASK = 0
		##LOCKOUT = 300051
		a = lseek (fileHandle, p, $$SEEK_END)			' restore file pointer
		##LOCKOUT = lockout
		##WHOMASK = whomask
		IF (a < 0) THEN GOTO SeekError
		IF (a >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
'
		IF (p >= s) THEN
			##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureExhausted : ##WHERE = 32000135
		ELSE
			##ERROR = $$ErrorNatureTerminated : ##WHERE = 32000137
		END IF
	ELSE
		XstSystemErrorToError (xb_geterrno(), @error)
		IF ##XBDV THEN PRINT "XxxInfile$(B):error", error
		##ERROR = error : ##WHERE = 32000142
	END IF
	RETURN
END FUNCTION
'
'
' ###########################
' #####  XxxInline$ ()  #####
' ###########################
'
FUNCTION  XxxInline$ (prompt$)
	SHARED	FILE	fileInfo[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxInline$()lockout", lockout)
'
	fileHandle = fileInfo[1].fileHandle
	consoleGrid = fileInfo[1].consoleGrid
	IFZ consoleGrid THEN GOTO console     'no console grid, try UNIX stdin
'
	##WHOMASK = 0
	text$ = prompt$                                               ' !!! don't free prompt$ !!!
	XuiSendMessage (consoleGrid, #Inline, 0, 0, 0, 0, 0, @text$)
	##WHOMASK = whomask
	line$ = text$
	XxxXgrSysMessages ()
	RETURN (line$)
'
' *****  get input from UNIX stdin  *****
'
console:
	PRINT prompt$;
	a$ = NULL$ (260)
	bufAddr = &a$
	length = 0
'
	DO
		##WHOMASK = 0
		##LOCKOUT = 300052
		a = read ($$STDIN, bufAddr, 256)
		##WHOMASK = whomask
		##LOCKOUT = lockout
'
		IF (a < 0) THEN
			XstSystemErrorToError (xb_geterrno(), @error)
'			PRINT "XxxInline$(A):error", error
			##ERROR = error : ##WHERE = 32010044
			RETURN
		END IF
'
		IFZ a THEN EXIT DO
		aAddr = &a$
		length = length + (a - 1)		' don't include \n
		lastChar = UBYTEAT (aAddr, length)
		IF (lastChar = '\n') THEN
			UBYTEAT (aAddr, length)	= 0					' null terminator on top of \n
			prevChar = UBYTEAT (aAddr, length-1)
			IF (prevChar = 13) THEN
				DEC length
				UBYTEAT (aAddr, length) = 0				' null terminator over \r
			END IF
			XLONGAT (aAddr, -16) = length					' length into header
			a$ = LEFT$ (a$, length)								' trim to fit
			RETURN (a$)
		ELSE
			INC length														' keep last character
			a$ = a$ + NULL$ (260)
			bufAddr	= &a$ + length
		END IF
	LOOP
'
'	error
'
	IFZ a THEN
		##ERROR = (($$ErrorObjectFile << 8) OR $$ErrorNatureExhausted) : ##WHERE = 32010072
		RETURN
	END IF
'
	IF xb_geterrno() THEN
		XstSystemErrorToError (xb_geterrno(), @error)
'		PRINT "XxxInline$(B):error", error
		##ERROR = error : ##WHERE = 32010079
	END IF
END FUNCTION
'
'
' #######################
' #####  XxxLof ()  #####
' #######################
'
FUNCTION  XxxLof (fileNumber)
	SHARED	FILE	fileInfo[]
'
	IF InvalidFileNumber (fileNumber) THEN RETURN (-1)
	fileHandle = fileInfo[fileNumber].fileHandle
	IF (fileHandle = -1) THEN RETURN (-1)						' console Grid
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxLof()lockout", lockout)
	whomask = ##WHOMASK
	##LOCKOUT = 300053
	##WHOMASK = 0
'
	c = lseek (fileHandle, 0, $$SEEK_CUR)					' get file pointer
	IF (c < 0) THEN GOTO SeekError
	IF (c >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
	s = lseek (fileHandle, 0, $$SEEK_END)					' get file size
	IF (s < 0) THEN GOTO SeekError
	IF (s >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
	a = lseek (fileHandle, c, $$SEEK_SET)					' restore file pointer
	IF (a < 0) THEN GOTO SeekError
	IF (a >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
	##WHOMASK = whomask
	##LOCKOUT = lockout
	RETURN (s)
'
'	Error
'
SeekError:
	##LOCKOUT = lockout
	##WHOMASK = whomask
	XstSystemErrorToError (xb_geterrno(), @error)
'	PRINT "XxxLof():error", error
	##ERROR = error : ##WHERE = 32020037
	RETURN ($$TRUE)
END FUNCTION
'
'
' ########################
' #####  XxxOpen ()  #####
' ########################
'
FUNCTION  XxxOpen (file$, mode)
	SHARED	FILE  fileInfo[]
	SLONG   fileHandle             '*cw* 230111+
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxOpen()lockout", lockout)
'
	IFZ fileInfo[] THEN
		##WHOMASK = 0
		DIM fileInfo[15]
		##WHOMASK = whomask
	END IF
'
	IF (RIGHT$(file$, 9) = "tpush.hlp") THEN
		PRINT "XxxOpen(22)", file$
	END IF
'
	okay = $$TRUE
'	consoleGrid = 0
'	hideConsole = 0
	f$ = TRIM$ (file$)
'
	IF (LEFT$(f$,4) = "CON:") THEN
		GOSUB OpenConsole
	 ELSE
		f$ = XstPathString$ (@f$)
		GOSUB OpenFile
	END IF
'
' okay means no error
'
	IF okay THEN
		IF (f$ = "CON:") THEN
			fileNumber = 1
			consoleGrid = ##CONGRID
		ELSE
			uFile = UBOUND(fileInfo[])
			FOR fileNumber = 3 TO uFile
				IFZ fileInfo[fileNumber].fileHandle THEN EXIT FOR		' Find an open slot
			NEXT fileNumber
			IF (fileNumber > uFile) THEN													' No room
				uFile = (uFile << 1) OR 3
				##WHOMASK = 0
				REDIM fileInfo[uFile]
				##WHOMASK = whomask
			END IF
		END IF
		fileInfo[fileNumber].fileName			= f$
		fileInfo[fileNumber].fileHandle		= fileHandle
		fileInfo[fileNumber].whomask			= whomask
		fileInfo[fileNumber].consoleGrid	= consoleGrid
		fileInfo[fileNumber].entries			= 1
		RETURN (fileNumber)
	END IF
'
'	error
'
	XstSystemErrorToError (xb_geterrno(), @error)
	IF ##XBDV THEN PRINT "XxxOpen():error", error, file$, mode, okay
	##ERROR = error : ##WHERE = 32030062
	RETURN ($$TRUE)
'
'
' *****  OpenConsole  *****
'
SUB OpenConsole
	IF fileInfo[] THEN
		FOR fileNumber = 1 TO UBOUND(fileInfo[])
			IFZ fileInfo[fileNumber].fileHandle THEN DO NEXT
			IF (f$ = TRIM$(fileInfo[fileNumber].fileName)) THEN
				INC fileInfo[fileNumber].entries
				RETURN (fileNumber)
			END IF
		NEXT fileNumber
	END IF
	fileHandle = -1
END SUB
'
'
' *****  OpenFile  *****
'
SUB OpenFile
'	dir = INSTR (f$, "\\")
'	DO WHILE dir
'		f${dir-1} = '/'								' convert \ into /
'		dir	= INSTR (f$, "\\")
'	LOOP
'
	f$ = XstSymbolicPathToPath$ (f$)  'convert symbolic links
'
	perms = 0
	unixMode = #O_RDONLY
	SELECT CASE (mode AND 0x0007)
		CASE $$RD			: unixMode	= #O_RDONLY
		CASE $$WR			: unixMode	= #O_WRONLY
		CASE $$RW			: unixMode	= #O_RDWR
		CASE $$WRNEW	: unixMode	= #O_WRONLY | #O_CREAT | #O_TRUNC
										umask			= umask (0o666)									' get umask
										nmask			= umask (umask)									' restore umask
										xmask			= umask{9,0} AND 0o666					' ignore x bit
										perms			= 0o666 AND (NOT xmask)
		CASE $$RWNEW	: unixMode	= #O_RDWR | #O_CREAT | #O_TRUNC
										umask			= umask (0o666)									' get umask
										nmask			= umask (umask)									' restore umask
										xmask			= umask{9,0} AND 0o666					' ignore x bit
										perms			= 0o666 AND (NOT xmask)
	END SELECT
'
	IF (mode AND $$NONBLOCK) THEN
		unixMode = unixMode OR #O_NONBLOCK
	END IF
'
'	IFZ (INSTR(f$, "x.log")) THEN XstLog (@f$)
'
	xb_seterrno($$FALSE)             ' clear EINTR set by interrupt
	##WHOMASK = 0
	##LOCKOUT = 300054
	fileHandle = open (&f$, unixMode, perms)
	##WHOMASK = whomask
	##LOCKOUT = lockout
	IF (fileHandle = -1) THEN okay = $$FALSE
'	PRINT "xst.x:XxxOpen()", fileHandle, f$, HEXX$(unixMode), HEXX$(perms), file$
'	PRINT HEX$(mode,4), HEX$(unixMode,8), OCT$(umask,4);; OCT$(nmask,4);; OCT$(xmask,4);; OCT$(perms,4), fileHandle, xb_geterrno()
END SUB
END FUNCTION
'
'
' #######################
' #####  XxxPof ()  #####
' #######################
'
FUNCTION  XxxPof (fileNumber)
	SHARED  FILE  fileInfo[]
'
	IF InvalidFileNumber (fileNumber) THEN RETURN (-1)
	fileHandle = fileInfo[fileNumber].fileHandle
	IF (fileHandle = -1) THEN RETURN (-1)					' console
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxPof()lockout", lockout)
	whomask = ##WHOMASK
	##LOCKOUT = 300055
	##WHOMASK = 0
'
	a = lseek (fileHandle, 0, $$SEEK_CUR)
	IF (a < 0) THEN GOTO SeekError
	IF (a >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
	##WHOMASK = whomask
	##LOCKOUT = lockout
	RETURN (a)
'
'	Error
'
SeekError:
	##LOCKOUT = lockout
	##WHOMASK = whomask
	XstSystemErrorToError (xb_geterrno(), @error)
'	PRINT "XxxPof():error", error
	##ERROR = error : ##WHERE = 32040033
	RETURN ($$TRUE)
END FUNCTION
'
'
' ########################
' #####  XxxQuit ()  #####
' ########################
'
FUNCTION  XxxQuit (status)
'
	whomask = ##WHOMASK
	##WHOMASK = 0
'
	IFZ ##STANDALONE THEN
		IF ##USERRUNNING THEN
			'
			' User is running in PDE
			' breakpoints are set on all user program lines
			' the breakpoint interrupt goes to XxxXitMain()
			' which calls XitBlowback()
			'
			XxxSetBlowback ()     ' user running in PDE
			##WHOMASK = whomask
			RETURN
		END IF
	END IF
'
	##BLOWBACK = $$TRUE
	XxxXgrQuit ()
	XxxTerminate ()      ' in xst.x
	XxxXitExit (status)
	##BLOWBACK = $$FALSE
END FUNCTION
'
'
' ############################
' #####  XxxReadFile ()  #####
' ############################
'
' error = XxxReadFile (fileNumber, buffer, bytes, bytesRead, overlapped)
'
FUNCTION  XxxReadFile (fileNumber, buffer, bytes, bytesRead, overlapped)
	SHARED  FILE  fileInfo[]
'
'	IF ##CAPSLOCK THEN
'		pid = getpid()
'		PRINT "XxxReadFile()", fileNumber, buffer, bytes, bytesRead, overlapped, pid
'	END IF
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxReadFile()lockout", lockout)
'
	IF (bytes <= 0) THEN RETURN ($$TRUE)
	IF (fileNumber < 0) THEN RETURN ($$FALSE)
	IF (fileNumber > 2) THEN
		IF InvalidFileNumber (fileNumber) THEN RETURN ($$FALSE)
		IFZ fileInfo[] THEN RETURN ($$FALSE)
		fileHandle = fileInfo[fileNumber].fileHandle
		IF (fileHandle = -1) THEN GOSUB ReadConsole ELSE GOSUB ReadFile
		IF (result > 0) THEN
			XLONGAT(bytesRead) = result
			result = $$FALSE
		ELSE
			XLONGAT(bytesRead) = 0
			result = $$TRUE
		END IF
		RETURN (result)
	ELSE
		##WHOMASK = 0
		read$ = INLINE$ ("")
		##WHOMASK = whomask
		upper = UBOUND (read$)
		IF (upper > bytes) THEN upper = bytes
		IF (upper >= 0) THEN
			FOR i = 0 TO upper
				UBYTEAT (buffer, i) = read${i}
			NEXT i
			UBYTEAT (buffer, i) = 0
		END IF
		RETURN ($$TRUE)
	END IF
'
'
' *****  ReadConsole  *****
'
SUB ReadConsole
	IFZ fileInfo[1].fileHandle THEN RETURN ($$FALSE)	' not initialized
	FOR i = 0 TO bytes - 1
		UBYTEAT(buffer,i) = 0
	NEXT i
	consoleGrid = fileInfo[fileNumber].consoleGrid
	XuiSendMessage (consoleGrid, #GetTextString, 0, 0, 0, 0, 0, @text$)
	lenText = LEN (text$)
	IFZ lenText THEN RETURN ($$FALSE)
	lastChar = MIN(bytes, lenText)
	FOR i = 0 TO lastChar - 1
		UBYTEAT(buffer,i) = text${i}
	NEXT i
	IF (lastChar < lenText) THEN
		text$ = MID$(text$, lastChar + 1)
	ELSE
		text$ = ""
	END IF
	XuiSendMessage (consoleGrid, #SetTextString, 0, 0, 0, 0, 0, @text$)
	result = $$FALSE
END SUB
'
'
' *****  ReadFile  *****
'
SUB ReadFile
	##WHOMASK = 0
	##LOCKOUT = 300056
	result = read (fileHandle, buffer, bytes)
	##LOCKOUT = lockout
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' ########################
' #####  XxxSeek ()  #####
' ########################
'
FUNCTION  XxxSeek (fileNumber, position)
	SHARED  FILE  fileInfo[]
'
	IF InvalidFileNumber (fileNumber) THEN RETURN (-1)
	fileHandle = fileInfo[fileNumber].fileHandle
	IF (fileHandle = -1) THEN RETURN (-1)					' console
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxSeek()lockout", lockout)
	whomask = ##WHOMASK
'
	##WHOMASK = 0
	##LOCKOUT = 300057
	a = lseek (fileHandle, position, $$SEEK_SET)
	##WHOMASK = whomask
	##LOCKOUT = lockout
'
	IF (a < 0) THEN GOTO SeekError
	IF (a >= 0x7FFFFFFFFFFFFFFF) THEN GOTO SeekError
	RETURN (a)
'
'	Error
'
SeekError:
	XstSystemErrorToError (xb_geterrno(), @error)
'	PRINT "XxxSeek():error", error
	##ERROR = error : ##WHERE = 32070032
	RETURN ($$TRUE)
END FUNCTION
'
'
' #########################
' #####  XxxShell ()  #####
' #########################
'
FUNCTION  XxxShell (command$)
'
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"XxxShell()lockout", lockout)
	whomask = ##WHOMASK
	##LOCKOUT = 300058
	##WHOMASK = 0
'
	c$ = TRIM$(command$)
	IFZ c$ THEN RETURN
	xb_seterrno($$FALSE)
'
' A colon ":" means run the command in background and
' not to wait for the command to complete before returning.
' In Linux this is done with an ampersand "&" at the end of the command.
'
	waitTillProcessCompleted = $$TRUE
	IF (c${0} = ':') THEN
		waitTillProcessCompleted = $$FALSE
		c$ = TRIM$(MID$(c$, 2))
		IFZ c$ THEN RETURN
		IF (RIGHT$(c$) != "&") THEN  ' a linux savy person may have "&" already
			c$ = c$ + " &"
		END IF
	END IF
'
	status = system (&c$)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	exitCode = (status >> 8) AND 0xFF
'
	IF ##XBDV THEN
		IF exitCode THEN
			PRINT "XxxShell():status, exitcode", HEXX$(status),  exitCode
		END IF
	END IF
'
	IF xb_geterrno() THEN
		XstSystemErrorToError (xb_geterrno(), @error)
		old = ERROR (error)
		nature = error AND 0x00FF
		IF (nature != $$ErrorNatureWouldBlock) THEN
			IF (nature != $$ErrorNatureInterrupted) THEN
				IF ##XBDV THEN PRINT "XxxShell():error", HEXX$(error), ERROR$(error)
				##ERROR = error : ##WHERE = 32080051
				RETURN ($$TRUE)
			END IF
		END IF
	END IF
'
	RETURN (exitCode)
END FUNCTION
'
'
' #########################
' #####  XxxStdio ()  #####
' #########################
'
FUNCTION  XxxStdio (in, out, err)
	in  = 0
	out = 1
	err = 2
END FUNCTION
'
'
' #############################
' #####  XxxWriteFile ()  #####
' #############################
'
FUNCTION  XxxWriteFile (fileNumber, addrBuffer, bytes, addrBytesWritten, overlapped)
	SHARED  FILE  fileInfo[]
	SHARED  bufferFile0$       '*cw* 110617 testing see XxxInfile$()
'
' Note: addrBuffer and addrBytesWritten must be addresses because this function is
'       called by xlib.s which conforms to the "C" standard of pass-by-address.
'       Therefore all functions must the same variables by-address.
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IFZ fileNumber THEN
		GOSUB WriteBuffer
		RETURN $$FALSE
	END IF
'
	IF (fileNumber < 0) THEN RETURN ($$FALSE)
	IF (fileNumber > 2) THEN
		IFZ bytes THEN RETURN ($$TRUE)
		IF InvalidFileNumber (fileNumber) THEN
			IF (fileNumber != 1) THEN RETURN ($$FALSE)
			IFZ fileInfo[] THEN RETURN ($$FALSE)
			IFZ fileInfo[1].fileHandle THEN RETURN ($$FALSE)	' not initialized
		END IF
	ELSE
		IFZ ##CONGRID THEN                        ' no GUI console
			##WHOMASK = 0
			##LOCKOUT = 300059
			result = write (1, addrBuffer, bytes)   ' write to unix console
			##LOCKOUT = lockout
			##WHOMASK = whomask
			IF (result >= 0) THEN                   'success
				XLONGAT(addrBytesWritten) = result
				result = $$FALSE
			ELSE                                    'fail
				XLONGAT(addrBytesWritten) = 0
				result = $$TRUE
			END IF
			RETURN (result)
		END IF
	END IF
'
	fileHandle = fileInfo[fileNumber].fileHandle
	IF (fileHandle = -1) THEN GOSUB WriteConsole ELSE GOSUB WriteFile
	RETURN (result)
'
'
' *****  WriteConsole  *****  enable when GUI console is operational
'
SUB WriteConsole
	consoleGrid = fileInfo[fileNumber].consoleGrid
	IF (fileNumber = 1) THEN ##WHOMASK = 0
	text$ = NULL$(bytes)
	FOR i = 0 TO bytes - 1
		text${i} = UBYTEAT(addrBuffer, i)
	NEXT i
	XuiSendMessage (consoleGrid, #Print, 0, 0, 0, 0, 0, @text$)
	XLONGAT(addrBytesWritten) = bytes
	IF (fileNumber = 1) THEN ##WHOMASK = whomask
	XxxXgrSysMessages ()
	result = $$FALSE
END SUB
'
'
' *****  WriteFile  *****
'
SUB WriteFile
	##WHOMASK = 0
	##LOCKOUT = 300060
	result = write (fileHandle, addrBuffer, bytes)
'
	IF (result >= 0) THEN               'success
		XLONGAT(addrBytesWritten) = result
		result = $$FALSE
	ELSE                                'fail
		XLONGAT(addrBytesWritten) = 0
		result = $$TRUE
	END IF
	##LOCKOUT = lockout
	##WHOMASK = whomask
END SUB
'
'
' *****  WriteBuffer  *****
'
SUB WriteBuffer
	##WHOMASK = 0
	bufferFile0$ = NULL$(bytes)
	FOR i = 0 TO bytes - 1
		bufferFile0${i} = UBYTEAT(addrBuffer, i)
	NEXT i
	##WHOMASK = whomask
	XLONGAT(addrBytesWritten) = bytes
	result = $$FALSE
END SUB
'
END FUNCTION
'
'
' ###########################
' #####  XxxFormat$ ()  #####
' ###########################
'
FUNCTION  XxxFormat$ (format$, argType, arg$$)
	STATIC	UBYTE  fmtLevel[]
	STATIC	UBYTE  fmtBegin[]
'
'	PRINT format$, argType, arg$$

	IFZ fmtLevel[] THEN GOSUB Initialize
	IFZ format$ THEN RETURN 										' empty format string
'
	IF (argType = $$STRING) THEN
		arg$ = CSTRING$(XLONG(arg$$))
	END IF
'
	fmtStrPtr = 1
	lenFmtStr = LEN (format$)
	GOSUB StringString													'	top StringString call
	IFZ fmtStrPtr THEN RETURN (resultString$)
'
' initialize argument counters, flags, etc.
'
	argH	= 0
	argL	= 0
	arg&&	= 0
	lenArg = 0
	negArg = 0
	argStr$	= ""
	argDPLoc = 0
	numShift = 0
	argExpIx = 0
	argExpVal = 0
	argMSDOrder	= 0
'
' initialize format counters, flags, etc.
'
	fmtChar = 0
	lastChar = 0
	nextChar = 0
	levelNow = 0
	levelNext = 0
	nPlaces = 0
	preDec = 0
	postDec = 0
	expCtr = 0
	hasDec = 0
	commaFlag = 0
	padFlag = 0
	dollarSign$ = ""
	leadSign$ = ""
	trailSign$ = ""
	errSign$ = ""
'
' Format argument and add it to the result loop
'
	DO
		lastChar = fmtChar
		fmtChar = format${fmtStrPtr-1}
'
		IFZ ((fmtChar = '#') AND ((lastChar = ',') OR (lastChar = '.') OR (lastChar = '#'))) THEN
				levelNow  = fmtLevel[fmtChar]
		END IF
'
		IF (fmtStrPtr = lenFmtStr) THEN							' check for end of fmt string
			nextChar = 'A'														'   set bogus next char
		ELSE
			nextChar  = format${fmtStrPtr}					'   get real next char
		END IF
'
		IF ((nextChar = '#') AND ((fmtChar = ',') OR (fmtChar = '.') OR (fmtChar = '#'))) THEN
			levelNext = levelNow
		ELSE
			levelNext = fmtLevel[nextChar]
		END IF
'
' Unformatted string "format"
'
		IF (fmtChar = '&') THEN
			IF (argType != $$STRING) THEN
				PRINT "Numeric data with '&'"
				GOTO eeeQuitFormat
			END IF
			resultString$ = resultString$ + arg$
			INC fmtStrPtr
			EXIT DO
		END IF
		INC nPlaces
'
		SELECT CASE fmtChar
			CASE '$': dollarSign$ = "$"
			CASE ',':	commaFlag = $$TRUE
								INC preDec
			CASE '*': padFlag = '*'
								INC preDec
			CASE '0': padFlag = '0'
								INC preDec
			CASE '.': hasDec = 1
			CASE '#': IF hasDec THEN
									INC postDec
								ELSE
									INC preDec
								END IF
			CASE '-': INC preDec						' sign can only be leading here.
			CASE '+', '('
								IFZ leadSign$ THEN
									leadSign$ = CHR$ (fmtChar)
								ELSE
									PRINT "Leading"; leadSign$; "excludes"; CHR$ (fmtChar)
									GOTO eeeQuitFormat
								END IF
		END SELECT
'
' case < or | or >:		all we needed to do is count them
' End of char fmt:		add to resultString$, and exit loop
'
		IF (((fmtChar = '<') OR (fmtChar = '|') OR (fmtChar = '>')) AND (nextChar != fmtChar)) THEN
			IF (argType != $$STRING) THEN
				PRINT "Can't print a number with a string format."
				GOTO eeeQuitFormat
			END IF
			SELECT CASE fmtChar
				CASE '<': resultString$ = resultString$ + LJUST$(arg$, nPlaces)
				CASE '|': resultString$ = resultString$ + CJUST$(arg$, nPlaces)
				CASE '>': resultString$ = resultString$ + RJUST$(arg$, nPlaces)
			END SELECT
			INC fmtStrPtr
			EXIT DO
		END IF
'
' SPECIAL TRAILING NUMERIC FMT INFO
'
' get exponent: !! new nextChar$ if legit exponent !!
'
		IF (nextChar = '^') THEN
			DO																				' count ^s
				INC expCtr
				IF (format${fmtStrPtr + expCtr} != '^') THEN EXIT DO
			LOOP UNTIL (expCtr = 5)
'
			IF (expCtr >= 4) THEN											' legitimate exponent
				nPlaces    = nPlaces    + expCtr
				fmtStrPtr  = fmtStrPtr  + expCtr
				nextChar   = format${fmtStrPtr}					' to look for trailing +, -, )
			ELSE
				expCtr = 0															' reset if not valid exponent
			END IF
		END IF
'
' look for trailing + or - in nextChar here. add flags
'
		IF (((nextChar = '-') OR (nextChar = '+')) AND (leadSign$ = "")) THEN
			trailSign$ = CHR$ (nextChar)
'
' incr ptrs: trailing sign picked up (but don't leave loop yet).
'
			levelNext = 0
			INC nPlaces
			INC fmtStrPtr
		END IF
'
' get closing parenthesis; legit only if opening parenthesis has been set.
'
		IF ((nextChar = ')') AND (leadSign$ = "(")) THEN
			trailSign$ = CHR$ (nextChar)
			INC nPlaces
			INC fmtStrPtr
		END IF
'
' a second '.' means the beginning of a new fmt.
'
		IF (hasDec AND (nextChar = '.')) THEN levelNext = 0
'
' End of num fmt: validate fmt, add to resultString$ and exit loop.
'
		IF (levelNext < levelNow) THEN
			IFZ (preDec + postDec) THEN
				PRINT "No printable digits"
				GOTO eeeQuitFormat
			END IF
'
' missing close parenthesis: treat open paren as fixed.
'
			IF ((leadSign$ = "(") AND (trailSign$ != ")")) THEN
				resultString$ = resultString$ + "("
				leadSign$ = ""
				DEC nPlaces
			END IF
'
' Get argument
'
			IF (argType = $$STRING) THEN GOTO eeeQuitFormat
'			SELECT CASE argType
'				CASE $$DOUBLE	: argStr$ = STR$ (DOUBLE(arg$$))
'				CASE $$SINGLE	: argStr$ = STR$ (SINGLE(arg$$))
'				CASE $$GIANT	: argStr$ = STR$ (arg$$)
'				CASE $$ULONG	: argStr$ = STR$ (ULONG(arg$$))
'				CASE ELSE			: argStr$ = STR$ (SLONG(arg$$))
'			END SELECT

			SELECT CASE argType
				CASE $$DOUBLE	: GIANTAT(&arg#) = arg$$  : argStr$ = STR$ (arg#)
				CASE $$SINGLE	: ULONGAT(&arg!) = arg$$  : argStr$ = STR$ (arg!)
				CASE $$GIANT	: argStr$ = STR$ (arg$$)
				CASE $$XLONG	: argStr$ = STR$ (arg$$)
				CASE $$ULONG	: ULONGAT(&arg&&) = arg$$ : argStr$ = STR$ (arg&&)
				CASE ELSE			: SLONGAT(&arg&) = arg$$  : argStr$ = STR$ (arg&)
			END SELECT

'
' decompose argument string: sign, exponent, length and DP location
'
' get sign: the 1st column of argStr$ will always be '-' or ' '.
'
			negArg = argStr${0}
			argStr$ = MID$(argStr$, 2)
'
' remove any exponent from argStr$. argExpVal is its numeric value.
'
			argExpIx = INCHR(argStr$, "de")
			argExpVal = 0
			IF (argExpIx > 0) THEN
				argExpVal = XLONG (MID$(argStr$, argExpIx + 1))
				argStr$ = LEFT$ (argStr$, argExpIx - 1)
			END IF
'
' length of argument string after sign, exponent and DP are removed
'
			lenArg = LEN (argStr$)
'
' get argument decimal point location. Remove it from argStr and
'		deincrement lenArg if needed.
'
			argDPLoc = INSTR (argStr$, ".")
			IFZ argDPLoc THEN
				argDPLoc = lenArg + 1
			ELSE
				argStr$ = LEFT$(argStr$, argDPLoc -1) + MID$(argStr$, argDPLoc +1)
				DEC lenArg
			END IF
'
' Remove leading '0'.
'
			k = 0
			DO WHILE argStr${k} = '0'
				DEC argExpVal
				INC k
			LOOP
			argStr$ = MID$(argStr$, k+1)
			lenArg = lenArg - k
'
' argMSDOrder, if pos, is the exponent of the most significant digit.
'		if neg, it is one less than the exponent.
'
			argMSDOrder = argDPLoc - 1 + argExpVal
'
' numShift is the power of 10 difference between the MSD of the format
'		and the MSD of the argument
'
			numShift = preDec - argMSDOrder
'
' put numeric argument string and format together
'
			IFZ expCtr THEN											' formats without an exponent
				IF (numShift > 0) THEN
					argStr$ = CHR$ ('0', numShift) + argStr$
					lenArg = lenArg + numShift
				END IF
				GOSUB Rounder
'
' restore DP and add commas
'
				IF hasDec THEN
					IF (preDec > argMSDOrder) THEN
						argStr$ = LEFT$(argStr$, preDec) + "." + MID$(argStr$, preDec +1)
						comIx = preDec
					ELSE
						argStr$ = LEFT$(argStr$, argMSDOrder) + "." + MID$(argStr$, argMSDOrder +1)
						comIx = argMSDOrder
					END IF
				END IF
'
				IF (commaFlag AND (argMSDOrder > 3)) THEN
					comIx = preDec
					GOSUB AddCommas
				END IF
'
' strip off any leading 0s before DP
'
				IF ((argMSDOrder < preDec) AND (preDec > 0)) THEN
					IF (argMSDOrder <= 1) THEN
						argStr$ = MID$(argStr$, preDec)
					ELSE
						argStr$ = MID$(argStr$, preDec - argMSDOrder + 1)
					END IF
				END IF
'
' if not enough digits in format then set mess up formatting flag
'
				IF (LEN(argStr$) > (preDec + postDec + hasDec)) THEN errSign$ = "%"
			ELSE										' formats with exponent
				GOSUB Rounder					' round off significant digits
'
' restore DP
'
				IF hasDec THEN argStr$ = LEFT$(argStr$, preDec) + "." + MID$(argStr$, preDec +1)
'
' get exponent in usable form
'
				expString$ = STR$ (numShift * -1)
				IF (expString${0} = ' ') THEN expString${0} = '+'
				expLen = LEN (expString$)
				DEC expCtr
'
				SELECT CASE TRUE
					CASE (expLen < expCtr)
								expString$ = LEFT$ (expString$, 1) + CHR$ ('0', expCtr - expLen) + MID$ (expString$, 2)
					CASE (expLen > expCtr)
								errSign$ = "%"
				END SELECT
				argStr$ = argStr$ + "E" + expString$
			END IF
'
' take care of leading and trailing sign stuff
'
			IF (negArg = '-') THEN
				SELECT CASE TRUE
					CASE (leadSign$ = "") AND (trailSign$ = ""):	leadSign$  = "-"
					CASE (leadSign$ = "+"):												leadSign$  = "-"
					CASE (trailSign$ = "+"):											trailSign$ = "-"
				END SELECT
			ELSE
				SELECT CASE TRUE
					CASE (leadSign$ = "(") AND (trailSign$ = ")")
								leadSign$ = " "
								trailSign$ = " "
					CASE trailSign$ = "-"
								trailSign$ = " "
				END SELECT
			END IF
'
' add signs and padding as necessary
'
			argStr$ = leadSign$ + dollarSign$ + argStr$ + trailSign$
			padLen  = nPlaces - LEN(argStr$)
			IF (padLen > 0) THEN
				IF padFlag THEN
					argStr$ = CHR$ (padFlag, padLen) + argStr$
				ELSE
					argStr$ = CHR$ (' ', padLen) + argStr$
				END IF
			END IF
			resultString$ = resultString$ + errSign$ + argStr$
			INC fmtStrPtr
			EXIT DO
		END IF
		INC fmtStrPtr							' incremented when looping through fmt chars
	LOOP
	GOSUB StringString					' get trailing constant string, if any
'
' reset fmt string ptrs to cycle through again as necessary
'
	IF ((fmtStrPtr = 0) AND (argIx < nArg-1)) THEN
		fmtStrPtr = 1
		GOSUB StringString
	END IF
	RETURN (resultString$)
'
'
' *****  Initialize  *****
'
SUB Initialize
	whomask = ##WHOMASK
	##WHOMASK = $$FALSE
	DIM fmtLevel[255]		' initialize format character priority level arrays
	DIM fmtBegin[255]
'
' All format characters are listed in fmtLevel.
' The fmtBegin array is used to determine the legitimacy of formats
' that cannot stand alone. These formats require a sequence of characters
' to establish their legitimacy.
' The lower the format level value, the higher the priority, so the
' characters not given a priority level here default to fmtlevel[] = 0,
' and therefore the highest priority. The lowest priority = 255.
'
	fmtLevel['&'] =  20
	fmtLevel['<'] =  30
	fmtLevel['|'] =  30
	fmtLevel['>'] =  30
	fmtLevel['+'] =  40:	fmtBegin['+'] =  40
	fmtLevel['-'] =  40:	fmtBegin['-'] =  40
	fmtLevel['('] =  40:	fmtBegin['('] =  40
	fmtLevel['*'] =  50:	fmtBegin['*'] =  50
	fmtLevel['0'] =  30:	fmtBegin['0'] =  30
	fmtLevel['$'] =  60:	fmtBegin['$'] =  60
	fmtLevel['#'] =  70
	fmtLevel[','] =  80:	fmtBegin[','] =  80
	fmtLevel['.'] =  90:	fmtBegin['.'] =  90
'
'	fmtLevel['^'] =   0		' When these two are format characters, they will be
'	fmtLevel[')'] =   0		' picked up by checking nextChar (just like trailing
'													' signs).
	##WHOMASK = whomask
END SUB
'
' *****  StringString  *****
'
SUB StringString
	DO
		fmtThisPtr = fmtStrPtr - 1
		q = format${fmtThisPtr}
		qq = fmtBegin[q]
		qqq = fmtLevel[q]
		IFZ q THEN EXIT DO
		r = format${fmtStrPtr}
		SELECT CASE TRUE
			CASE (q = '_')	: INC fmtStrPtr: q = r
			CASE qq					: IF ValidFormat (format$, fmtThisPtr) THEN EXIT DO
			CASE qqq				: EXIT DO
		END SELECT
		resultString$ = resultString$ + CHR$ (q)
		INC fmtStrPtr
	LOOP
	IF (fmtStrPtr > lenFmtStr) THEN fmtStrPtr = 0
END SUB
'
' *****  AddCommas  *****
'
SUB AddCommas
	DO WHILE comIx > (preDec - argMSDOrder + 3)
		comIx = comIx - 3
		argStr$ = LEFT$(argStr$, comIx) + "," + MID$(argStr$, comIx+1)
		INC lenArg
	LOOP
END SUB
'
' *****  Rounder  *****
'
SUB Rounder
	IF ((expCtr = 0) AND (numShift < 0)) THEN		' no fmt exp & int(arg) > int(fmt)
		fmtDigCtr = argMSDOrder + postDec
	ELSE
		fmtDigCtr = preDec + postDec
	END IF
'
	IF (lenArg > fmtDigCtr) THEN
		rndDig  = argStr${fmtDigCtr}
		argStr$ = LEFT$(argStr$, fmtDigCtr)
'
		IF (rndDig >= '5') THEN
			stopIt = $$FALSE
			DO UNTIL stopIt OR (fmtDigCtr = 0)		' DO WHILE (fmtDigCtr) in using9.x
				DEC fmtDigCtr
				lastDig = argStr${fmtDigCtr}
				INC lastDig
				IF (lastDig = 0x3a) THEN
					lastDig = '0'											' 9 -> 0: keep rounding
				ELSE
					stopIt = $$TRUE										' no more rounding
				END IF
				argStr${fmtDigCtr} = lastDig
			LOOP																	' LOOP UNTIL (stopIt) in using9.x
'
			IF (stopIt AND (fmtDigCtr < numShift) AND (expCtr == 0)) THEN		' added significant digit
				INC argMSDOrder
				DEC numShift
			END IF
'
			IF !stopIt THEN																' ran out of format digits
				IFZ expCtr THEN
					argStr$ = "1" + argStr$
				ELSE
					argStr${0} = '1'
				END IF
				INC argMSDOrder
				DEC numShift
			END IF
		END IF																					' rndDig >= '5'
	ELSE																							' lenArg <= fmtDigCtr
		argStr$ = argStr$ + CHR$ ('0', fmtDigCtr - lenArg)
	END IF
END SUB
'
eeeQuitFormat:
	##ERROR = $$ErrorNatureInvalidArgument : ##WHERE = 32110479
	RETURN (resultString$)
END FUNCTION
'
'
' #########################
' #####  XstIoctl ()  #####
' #########################
'
' rc = XstIoctl (fileNumber, command, &data)
'
FUNCTION  XstIoctl (fileNumber, command, dataAddress)
	SHARED  FILE  fileInfo[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IF (fileNumber < 0) THEN RETURN 100  '$$TRUE
	IF (fileNumber < 3) THEN
		fileHandle = fileNumber
	ELSE
		IF InvalidFileNumber (fileNumber) THEN RETURN 101  '$$TRUE
		fileHandle = fileInfo[fileNumber].fileHandle
	END IF
	PRINT "XstIoctl():fileHandle", fileNumber, fileHandle

	##WHOMASK = $$FALSE
	##LOCKOUT = 300061
	rc = ioctl (fileHandle, command, dataAddress)
	##LOCKOUT = lockout
	##WHOMASK = whomask
	IFZ rc THEN RETURN (rc)
'
	XstSystemErrorToError (xb_geterrno(), @error)
	nature = error AND 0x00FF
	IF (nature == $$ErrorNatureWouldBlock) THEN RETURN (rc)
	XstErrorNumberToName (error, @error$)
'	IF ##CAPSLOCK THEN PRINT "XstIoctl():error", error, error$
	PRINT "XstIoctl():error", error, error$, fileHandle, rc
	##ERROR = error : ##WHERE = 32120037
	RETURN ($$TRUE)
'
END FUNCTION
'
'
' ########################
' #####  XstMmap ()  #####
' ########################
'
' rc = XstMmap (&start, bytes, prot, mapflags, fileNumber, offset)
'
FUNCTION  XstMmap (startAddress, bytes, prot, mapflags, fileNumber, offset)
	SHARED  FILE  fileInfo[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ fileNumber THEN RETURN 100  '$$TRUE
	IF InvalidFileNumber (fileNumber) THEN RETURN 101  '$$TRUE
	fileHandle = fileInfo[fileNumber].fileHandle
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300062
	rc = mmap (&start, bytes, prot, mapflags, fileHandle, offset)
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ rc THEN RETURN (rc)
'
	XstSystemErrorToError (xb_geterrno(), @error)
	nature = error AND 0x00FF
	IF (nature == $$ErrorNatureWouldBlock) THEN RETURN (rc)
	XstErrorNumberToName (error, @error$)
'	IF ##CAPSLOCK THEN PRINT "XstMmap():error", error, error$
	##ERROR = error : ##WHERE = 32130032
	RETURN ($$TRUE)
'
END FUNCTION
'
'
' ##############################
' #####  DeltaTimeZone ()  #####
' ##############################
'
FUNCTION  DeltaTimeZone (delta)
	UTIMEB  timeb
	UTM  ltime, gtime
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
	IF lockout THEN XxxLog2 (@"DeltaTimeZone()lockout", lockout)
'
	##WHOMASK = 0
	##LOCKOUT = 300063
	ftime (&timeb)
	gtime = gmtime (&timeb.time)
	ltime = localtime (&timeb.time)
	ggtime = mktime (&gtime)
	lltime = mktime (&ltime)
	delta = lltime - ggtime
	##WHOMASK = whomask
	##LOCKOUT = lockout
END FUNCTION
'
'
' ########################
' #####  InitGui ()  #####
' ########################
'
' InitGui() initializes cursor, icon, message, and display variables.
' Programs can reference these variables, but must never change them.
'
FUNCTION  InitGui ()
'
' ***************************************
' *****  Register Standard Cursors  *****
' ***************************************
'
	XgrRegisterCursor (@"arrow",			@#defaultCursor)
	XgrRegisterCursor (@"arrow",			@#cursorDefault)
	XgrRegisterCursor (@"arrow",			@#cursorArrow)
	XgrRegisterCursor (@"arrow",			@#cursorArrowNW)
	XgrRegisterCursor (@"n",					@#cursorArrowN)
	XgrRegisterCursor (@"ns",					@#cursorArrowsNS)
	XgrRegisterCursor (@"we",					@#cursorArrowsWE)
	XgrRegisterCursor (@"nwse",				@#cursorArrowsNWSE)
	XgrRegisterCursor (@"nesw",				@#cursorArrowsNESW)
	XgrRegisterCursor (@"all",				@#cursorArrowsAll)
	XgrRegisterCursor (@"crosshair",	@#cursorCrosshair)
	XgrRegisterCursor (@"plus",				@#cursorPlus)
	XgrRegisterCursor (@"wait",				@#cursorHourglass)
	XgrRegisterCursor (@"insert",			@#cursorInsert)
	XgrRegisterCursor (@"no",					@#cursorNo)
'
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
'	XgrRegisterIcon (@"window",				@#iconWindow)					' custom
'
'
' ******************************
' *****  Register Messages *****  Create message numbers for message names
' ******************************
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
	XgrRegisterMessage (@"Deselected",									@#Deselected)
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
	XgrRegisterMessage (@"GetTextFlag",									@#GetTextFlag) 'Add by technicorn
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
	XgrRegisterMessage (@"SetTextFlag",									@#SetTextFlag) 'Add by technicorn
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
	XgrGetDisplaySize ("", @#displayWidth, @#displayHeight, @#windowBorderWidth, @#windowTitleHeight)
END FUNCTION
'
'
' ##################################
' #####  InvalidFileNumber ()  #####
' ##################################
'
'	Test for valid file number
'
'	In:				fileNumber		File Number
'	Out:			none--arg unchanged
'	Return:		$$TRUE				valid
'						$$FALSE				invalid  (sets ##ERROR)
'
'	Must be entry WHOMASK
'
FUNCTION  InvalidFileNumber (fileNumber)
	SHARED  FILE  fileInfo[]
'
	IFZ fileInfo[] THEN GOTO eeeBadFileNumber
	uFile = UBOUND(fileInfo[])
	IF (fileNumber > uFile) THEN GOTO eeeBadFileNumber
	IF (fileNumber < 1) THEN GOTO eeeBadFileNumber
	fileHandle = fileInfo[fileNumber].fileHandle
	IFZ fileHandle THEN GOTO eeeBadFileNumber
	IF ##WHOMASK THEN												' User can only Close her own files
		IF (fileNumber > 2) THEN
			IFZ fileInfo[fileNumber].whomask THEN GOTO eeeBadFileNumber
		END IF
	END IF
	RETURN ($$FALSE)
'
eeeBadFileNumber:
	##ERROR = ($$ErrorObjectFile << 8) OR $$ErrorNatureInvalidArgument : ##WHERE = 32160033
	RETURN ($$TRUE)
END FUNCTION
'
'
' ############################
' #####  ValidFormat ()  #####
' ############################
'
FUNCTION  ValidFormat (format$, validPtr)
	STATIC	UBYTE  fmtSeq[]
'
	IFZ fmtSeq[] THEN GOSUB Initialize
	IFZ format$ THEN RETURN ($$FALSE)
	valid = $$FALSE
'
' format is invalid if not part of ascending value sequence
' (else) format is valid if the next format character can become a digit
'
	DO
		now = format${validPtr}
		nxt = format${validPtr+1}
		IF (fmtSeq[now] >= fmtSeq[nxt]) THEN valid = $$FALSE : EXIT DO
		IF ((nxt = '*') OR (nxt = '#') OR (nxt = ',')) THEN valid = $$TRUE : EXIT DO
		INC validPtr
	LOOP
	RETURN (valid)
'
' *****  Initialize  *****
'
SUB Initialize
	whomask = ##WHOMASK
	##WHOMASK = $$FALSE
	DIM fmtSeq[255]
	fmtSeq['0'] =  30
	fmtSeq['+'] =  40
	fmtSeq['-'] =  40
	fmtSeq['('] =  40
	fmtSeq['*'] =  50
	fmtSeq['$'] =  60
	fmtSeq[','] =  80
	fmtSeq['.'] =  90
	fmtSeq['#'] = 100
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' #########################
' #####  ValidFmt ()  #####
' #########################
'
FUNCTION  ValidFmt (fmtString$, validPtr)
	STATIC UBYTE fmtSeq[]
'
	IFZ fmtSeq[] THEN GOSUB InitStatic
'
	DO
		now = fmtString${validPtr}
		nxt = fmtString${validPtr+1}
'
' format is invalid if not part of ascending value sequence
'
		IF (fmtSeq[now] >= fmtSeq[nxt]) THEN fmt = 0 : EXIT DO
'
' (else) format is valid if the next format character can become a digit
'
		IF ((nxt = '*') OR (nxt = '#') OR (nxt = ',')) THEN fmt = 1 : EXIT DO
		INC validPtr
	LOOP
	RETURN fmt
'
' *****************************
' *****  SUB  InitStatic  *****
' *****************************
'
SUB InitStatic
	whomask = ##WHOMASK
	##WHOMASK = $$FALSE
	DIM fmtSeq[255]
	fmtSeq['+'] =  40
	fmtSeq['-'] =  40
	fmtSeq['('] =  40
	fmtSeq['*'] =  50
	fmtSeq['$'] =  60
	fmtSeq[','] =  80
	fmtSeq['.'] =  90
	fmtSeq['#'] = 100
	##WHOMASK = whomask
END SUB
END FUNCTION
'
'
' #############################
' #####  XxxTerminate ()  #####
' #############################
'
FUNCTION  XxxTerminate ()
'
' see xlib.s in Windows version
'
END FUNCTION
'
'
' #################################
' #####  XxxGuessFilename ()  #####  prior to Aug 30, 1995
' #################################
'
' if new name contains drive and/or root path slash,
' the new name is the full path or path\fileName, so
' ignore the old name.
'
' this function will return $$FileNormal if the file
' does not exist, but the path is valid so that the
' specified file could be created, as is often the
' case for files to be saved (they don't yet exist).
'
' if the return value of attributes is zero, the
' file name is invalid for both read and write.
'
FUNCTION  XxxGuessFilename (old$, new$, guess$, attributes)
'
	guess$ = ""
	IFZ new$ THEN
		guess$ = old$
	ELSE
		newLength = LEN(new$)
		test$ = XstPathString$ (new$)
		SELECT CASE TRUE
			CASE (test${0} = $$PathSlash)	:	guess$ = test$		' leading \
			CASE (test${1} = ':')					: guess$ = test$		' leading d:
		END SELECT
	END IF
'
	IFZ guess$ THEN
		IFZ old$ THEN XstGetCurrentDirectory (@old$)
		XstGetFileAttributes (@old$, @attributes)
		SELECT CASE TRUE
			CASE (attributes AND $$FileDirectory)
						path$ = old$
			CASE (attributes = 0)
						XstGetCurrentDirectory (@path$)
			CASE ELSE
						XstGetPathComponents (@old$, @path$, @drive$, @dir$, @file$, @attributes)
		END SELECT
		upath = UBOUND(path$)
		IF (path${upath} != $$PathSlash) THEN path$ = path$ + $$PathSlash$
		guess$ = path$ + test$
	END IF
	XstGetFileAttributes (@guess$, @attributes)
	IFZ attributes THEN
		XstGetPathComponents (@guess$, @path$, @dr$, @di$, @fi$, @at)
		XstGetFileAttributes (@path$, @att)
		IF (att AND $$FileDirectory) THEN attributes = $$FileNormal
	END IF
END FUNCTION
'
'
' ###############################
' #####  XxxPathString$ ()  #####  prior to Aug 30, 1995
' ###############################
'
FUNCTION  XxxPathString$ (path$)
'
	o = '\\'
	n = $$PathSlash
	IF (n = '\\') THEN o = '/'
'
	IFZ path$ THEN RETURN
	upper = UBOUND (path$)
	p$ = path$
'
	FOR i = 0 TO upper
		IF (p${i} = o) THEN p${i} = n
	NEXT i
	RETURN (p$)
END FUNCTION
'
'
' #######################
' #####  XxxLog ()  #####
' #######################
'
FUNCTION  XxxLogNoNL (text$)
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IF ##TIMERLOCKOUT THEN RETURN ($$FALSE)
	IFZ ##XBDV THEN RETURN ($$FALSE)
	IFZ text$  THEN RETURN ($$FALSE)
'
	##WHOMASK = $$FALSE
	##LOCKOUT = 300064
	write (1, &text$, LEN(text$))
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
'	XstLog (text$)
'
END FUNCTION
'
'
' ###########################
' #####  XstLogRegs ()  #####
' ###########################
'
FUNCTION  XstLogRegs (reg1, reg2, reg3, reg4, reg5, reg6, reg7)

	text$ = text$ + " " + HEXX$(reg1)
	text$ = text$ + " " + HEXX$(reg2)
	text$ = text$ + " " + HEXX$(reg3)
	text$ = text$ + " " + HEXX$(reg4)
	text$ = text$ + " " + HEXX$(reg5)
	text$ = text$ + " " + HEXX$(reg6)
	text$ = text$ + " " + HEXX$(reg7)
	XstLog ("regs " + text$)

END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "kernel32"
VERSION "0.0001"
'
IMPORT  "clib"
IMPORT  "xwin"
IMPORT  "elf32"
'
' This program implements part of the kernel32 portion of the
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
'
TYPE DLL
	XLONG				.handle
	XLONG				.count
	STRING*56		.name
END TYPE
'
'
' #######################################
' #####  Win32 API COMPOSITE TYPES  #####
' #######################################
'
EXPORT
TYPE DCB
  XLONG   .DCBlength
  XLONG   .BaudRate
  XLONG   .fModes
  SSHORT  .wReserved
  SSHORT  .XonLim
  SSHORT  .XoffLim
  SBYTE   .ByteSize
  SBYTE   .Parity
  SBYTE   .StopBits
  UBYTE   .XonChar
  UBYTE   .XoffChar
  UBYTE   .ErrorChar
  UBYTE   .EofChar
  UBYTE   .EvtChar
END TYPE
'
TYPE FILETIME
  XLONG   .dwLowDateTime
  XLONG   .dwHighDateTime
END TYPE
'
TYPE SYSTEMTIME
  USHORT  .year
  USHORT  .month
  USHORT  .weekDay
  USHORT  .day
  USHORT  .hour
  USHORT  .minute
  USHORT  .second
  USHORT  .msec
END TYPE
'
DECLARE FUNCTION  Kernel32 ()
DECLARE FUNCTION  Beep (hertz, msec)
DECLARE FUNCTION  CloseHandle (handle)
DECLARE FUNCTION  CopyFileA (sourceNameAddr, destNameAddr, failIfExists)
DECLARE FUNCTION  CreateDirectoryA (dirNameAddr, security)
DECLARE FUNCTION  CreateFileA (addrFilename, mode, azero, bzero, attr, type, czero)
DECLARE FUNCTION  CreateProcessA (addrImageName, addrCommandLine, azero, bzero, czero, create, dzero, ezero, addrStartupInfo, addrProcessInfo)
DECLARE FUNCTION  DeleteFileA (fileNameAddr)
DECLARE FUNCTION  ExitProcess (exitCode)
DECLARE FUNCTION  FileTimeToSystemTime (addrSystemTime, addrFileTime)
DECLARE FUNCTION  FindClose (findHandle)
DECLARE FUNCTION  FindFirstFileA (fileNameAddr, bufferAddr)
DECLARE FUNCTION  FindNextFileA (findHandle, bufferAddr)
DECLARE FUNCTION  FreeConsole ()
DECLARE FUNCTION  FreeLibrary (handle)
DECLARE FUNCTION  GetCommState (handleDevice, addrControlBlock)
DECLARE FUNCTION  GetCurrentDirectoryA (bufferSize, dirNameAddr)
DECLARE FUNCTION  GetDriveTypeA (driveNameAddr)
DECLARE FUNCTION  GetExitCodeProcess (hProcess, addrStatus)
DECLARE FUNCTION  GetFileAttributesA (fileNameAddr)
DECLARE FUNCTION  GetFileSize (fileHandle, highAddr)
DECLARE FUNCTION  GetFileTime (fileHandle, addrCreate, addrAccess, addrModify)
DECLARE FUNCTION  GetFileType (fileHandle)
DECLARE FUNCTION  GetFullPathNameA (fileNameAddr, fileNameSize, pathNameAddr, pathNameSize)
DECLARE FUNCTION  GetLastError ()
DECLARE FUNCTION  GetLocalTime (addrSystemTime)
DECLARE FUNCTION  GetLogicalDrives ()
DECLARE FUNCTION  GetLogicalDriveStringsA (bufferSize, bufferAddr)
DECLARE FUNCTION  GetModuleHandleA (nameAddr)
DECLARE FUNCTION  GetPrivateProfileStringA (sectionAddr, keyAddr, defaultAddr, bufferAddr, bufferBytes, filenameAddr)
DECLARE FUNCTION  GetProcAddress (hinst, funcNameAddr)
DECLARE FUNCTION  GetStdHandle (stdDevice)
DECLARE FUNCTION  GetSystemDirectoryA (pathAddr, pathSize)
DECLARE FUNCTION  GetSystemInfo (infoAddr)
DECLARE FUNCTION  GetSystemTime (addrSystemTime)
DECLARE FUNCTION  GetTickCount ()
DECLARE FUNCTION  GetVersion ()
DECLARE FUNCTION  GetWindowsDirectoryA (pathAddr, pathSize)
DECLARE FUNCTION  GlobalAlloc (memType, byteSize)
DECLARE FUNCTION  GlobalLock (handle)
DECLARE FUNCTION  GlobalSize (handle)
DECLARE FUNCTION  GlobalUnlock (handle)
DECLARE FUNCTION  LoadLibraryA (fileNameAddr)
DECLARE FUNCTION  LoadResource (resourceModuleHandle, resourceHandle)
DECLARE FUNCTION  MoveFileA (oldFileAddr, newFileAddr)
DECLARE FUNCTION  OpenProcess (access, inherit, process)
DECLARE FUNCTION  RaiseException (exception, flags, argCount, argArray)
DECLARE FUNCTION  ReadFile (fileHandle, addrBuffer, readBytes, addrBytesRead, addrOverlapStruc)
DECLARE FUNCTION  RemoveDirectoryA (dirNameAddr)
DECLARE FUNCTION  SetCommState (handleDevice, addrControlBlock)
DECLARE FUNCTION  SetCurrentDirectoryA (dirNameAddr)
DECLARE FUNCTION  SetFileAttributesA (fileNameAddr, attributes)
DECLARE FUNCTION  SetFilePointer (fileHandle, moveBytes, addrMoveByteHigh, moveMethod)
DECLARE FUNCTION  SetFileTime (fileHandle, addrCreate, addrAccess, addrModify)
DECLARE FUNCTION  SetLastError (error)
DECLARE FUNCTION  SetLocalTime (addrSystemTime)
DECLARE FUNCTION  SetSystemTime (addrSystemTime)
DECLARE FUNCTION  Sleep (milliseconds)
DECLARE FUNCTION  SystemTimeToFileTime (addrSystemTime, addrFileTime)
DECLARE FUNCTION  VirtualAlloc (addr, size, type, protect)
DECLARE FUNCTION  VirtualFree (addr, size, type)
DECLARE FUNCTION  VirtualProtect (addr, size, newProtect, oldProtectBuffer)
DECLARE FUNCTION  WriteFile (fileHandle, addrBuffer, writeBytes, addrBytesWritten, addrOverlapStruc)
DECLARE FUNCTION  WritePrivateProfileStringA (sectionAddr, keyAddr, addStringAddr, filenameAddr)
END EXPORT
'
'
' #########################
' #####  Kernel32 ()  #####
' #########################
'
FUNCTION  Kernel32 ()
'
' PRINT "Kernel32() : Initialize"
'
END FUNCTION
'
'
' #####################
' #####  Beep ()  #####
' #####################
'
FUNCTION  Beep (hertz, msec)
	AUTOX  XKeyboardState  keyState
	AUTOX  XKeyboardControl  keyControl
'
	zero = 0
	addrDisplay = XDisplayName (&zero)
	display$ = CSTRING$ (addrDisplay)
	sdisplay = XOpenDisplay (&display$)
	XGetKeyboardControl (sdisplay, &keyState)
'
	keyControl.bellPitch = hertz
	keyControl.bellDuration = msec
	mask = $$KBBellPitch OR $$KBBellDuration
	XChangeKeyboardControl (sdisplay, mask, &keyControl)
	XBell (sdisplay, 0)
	keyControl.bellPitch = -1
	keyControl.bellDuration = -1
	XChangeKeyboardControl (sdisplay, mask, &keyControl)
END FUNCTION
'
'
' ############################
' #####  CloseHandle ()  #####
' ############################
'
FUNCTION  CloseHandle (handle)
'
'	PRINT "Kernel32 : CloseHandle()"
'
END FUNCTION
'
'
' ##########################
' #####  CopyFileA ()  #####
' ##########################
'
FUNCTION  CopyFileA (sourceNameAddr, destNameAddr, failIfExists)
'
'	PRINT "Kernel32 : CopyFileA"
'
END FUNCTION
'
'
' #################################
' #####  CreateDirectoryA ()  #####
' #################################
'
FUNCTION  CreateDirectoryA (dirNameAddr, security)
'
'	PRINT "Kernel32 : CreateDirectoryA()"
'
END FUNCTION
'
'
' ############################
' #####  CreateFileA ()  #####
' ############################
'
FUNCTION  CreateFileA (addrFilename, mode, azero, bzero, attr, type, czero)
'
'	PRINT "Kernel32 : CreateFileA()"
'
END FUNCTION
'
'
' ###############################
' #####  CreateProcessA ()  #####
' ###############################
'
FUNCTION  CreateProcessA (addrImageName, addrCommandLine, azero, bzero, czero, create, dzero, ezero, addrStartupInfo, addrProcessInfo)
'
'	PRINT "Kernel32 : CreateProcessA()"
'
END FUNCTION
'
'
' ############################
' #####  DeleteFileA ()  #####
' ############################
'
FUNCTION  DeleteFileA (fileNameAddr)
'
'	PRINT "Kernel32 : DeleteFileA()"
'
END FUNCTION
'
'
' ############################
' #####  ExitProcess ()  #####
' ############################
'
FUNCTION  ExitProcess (exitCode)
'
'	PRINT "Kernel32 : ExitProcess()"
'
END FUNCTION
'
'
' #####################################
' #####  FileTimeToSystemTime ()  #####
' #####################################
'
FUNCTION  FileTimeToSystemTime (addrSystemTime, addrFileTime)
'
'	PRINT "Kernel32 : FileTimeToSystemTime()"
'
END FUNCTION
'
'
' ##########################
' #####  FindClose ()  #####
' ##########################
'
FUNCTION  FindClose (findHandle)
'
'	PRINT "Kernel32 : FindClose()"
'
END FUNCTION
'
'
' ###############################
' #####  FindFirstFileA ()  #####
' ###############################
'
FUNCTION  FindFirstFileA (fileNameAddr, bufferAddr)
'
'	PRINT "Kernel32 : FindFirstFileA()"
'
END FUNCTION
'
'
' ##############################
' #####  FindNextFileA ()  #####
' ##############################
'
FUNCTION  FindNextFileA (findHandle, bufferAddr)
'
'	PRINT "Kernel32 : FindNextFileA()"
'
END FUNCTION
'
'
' ############################
' #####  FreeConsole ()  #####
' ############################
'
FUNCTION  FreeConsole ()
'
'	PRINT "Kernel32 : FreeConsole()"
'
END FUNCTION
'
'
' ############################
' #####  FreeLibrary ()  #####
' ############################
'
FUNCTION  FreeLibrary (handle)
	SHARED  DLL  library[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	IFZ handle THEN RETURN ($$TRUE)
'
	slot = -1
	upper = UBOUND (library[])
'	PRINT "FreeLibrary().A : "; HEX$(handle,8);; slot;; upper
'
	FOR i = 0 TO upper
		IF (handle = library[i].handle) THEN
			name$ = TRIM$ (library[i].name)										' name empty for system
'			PRINT "FreeLibrary().B : <"; name$; ">";; HEX$(handle,8);; slot;; upper;; library[i].count
			DEC library[i].count
			IFZ name$ THEN
				IFZ library[i].count THEN INC library[i].count
			END IF
			IF (library[i].count > 0) THEN
'				PRINT "FreeLibrary().D : <"; name$; ">";; HEX$(handle,8);; slot;; upper;; library[i].count
				RETURN ($$FALSE)																' more opens than closes
			END IF
			slot = i
'			PRINT "FreeLibrary().E : <"; name$; ">";; HEX$(handle,8);; slot;; upper;; library[i].count
			EXIT FOR
		END IF
	NEXT i
'
	IF (slot = -1) THEN RETURN ($$TRUE)
'
	IF name$ THEN
		##WHOMASK = 0
		##LOCKOUT = $$TRUE
		error = dlclose (handle)
		##WHOMASK = whomask
		##LOCKOUT = lockout
'
'		PRINT "FreeLibrary().Z : dlclose() : "; HEX$(handle,8);; "<"; name$; ">";; error;; i;; upper
'
		library[slot].handle = 0
		library[slot].count = 0
		library[slot].name = ""
	END IF
'	PRINT "FreeLibrary().Z : "; HEX$(handle,8);; "<"; name$; ">";; error;; i;; upper
	RETURN ($$FALSE)
END FUNCTION
'
'
' #############################
' #####  GetCommState ()  #####
' #############################
'
FUNCTION  GetCommState (handleDevice, addrControlBlock)
'
'	PRINT "Kernel32 : GetCommState()"
'
END FUNCTION
'
'
' #####################################
' #####  GetCurrentDirectoryA ()  #####
' #####################################
'
FUNCTION  GetCurrentDirectoryA (bufferSize, dirNameAddr)
'
'	PRINT "Kernel32 : GetCurrentDirectoryA()"
'
END FUNCTION
'
'
' ##############################
' #####  GetDriveTypeA ()  #####
' ##############################
'
FUNCTION  GetDriveTypeA (driveNameAddr)
'
'	PRINT "Kernel32 : GetDriveTypeA()"
'
END FUNCTION
'
'
' ###################################
' #####  GetExitCodeProcess ()  #####
' ###################################
'
FUNCTION  GetExitCodeProcess (hProcess, addrStatus)
'
'	PRINT "Kernel32 : GetExitCodeProcess()"
'
END FUNCTION
'
'
' ###################################
' #####  GetFileAttributesA ()  #####
' ###################################
'
FUNCTION  GetFileAttributesA (fileNameAddr)
'
'	PRINT "Kernel32 : GetFileAttributesA()"
'
END FUNCTION
'
'
' ############################
' #####  GetFileSize ()  #####
' ############################
'
FUNCTION  GetFileSize (fileHandle, highAddr)
'
'	PRINT "Kernel32 : GetFileSize()"
'
END FUNCTION
'
'
' ############################
' #####  GetFileTime ()  #####
' ############################
'
FUNCTION  GetFileTime (fileHandle, addrCreate, addrAccess, addrModify)
'
'	PRINT "Kernel32 : GetFileTime()"
'
END FUNCTION
'
'
' ############################
' #####  GetFileType ()  #####
' ############################
'
FUNCTION  GetFileType (fileHandle)
'
'	PRINT "Kernel32 : GetFileType()"
'
END FUNCTION
'
'
' #################################
' #####  GetFullPathNameA ()  #####
' #################################
'
FUNCTION  GetFullPathNameA (fileNameAddr, fileNameSize, pathNameAddr, pathNameSize)
'
'	PRINT "Kernel32 : GetFullPathNameA()"
'
END FUNCTION
'
'
' #############################
' #####  GetLastError ()  #####
' #############################
'
FUNCTION  GetLastError ()
'
'	PRINT "Kernel32 : GetLastError()"
'
END FUNCTION
'
'
' #############################
' #####  GetLocalTime ()  #####
' #############################
'
FUNCTION  GetLocalTime (addrSystemTime)
'
'	PRINT "Kernel32 : GetLocalTime()"
'
END FUNCTION
'
'
' #################################
' #####  GetLogicalDrives ()  #####
' #################################
'
FUNCTION  GetLogicalDrives ()
'
'	PRINT "Kernel32 : GetLogicalDrives()"
'
END FUNCTION
'
'
' ########################################
' #####  GetLogicalDriveStringsA ()  #####
' ########################################
'
FUNCTION  GetLogicalDriveStringsA (bufferSize, bufferAddr)
'
'	PRINT "Kernel32 : GetLogicalDriveStringsA()"
'
END FUNCTION
'
'
' #################################
' #####  GetModuleHandleA ()  #####
' #################################
'
FUNCTION  GetModuleHandleA (nameAddr)
'
'	PRINT "Kernel32 : GetModuleHandleA()"
'
END FUNCTION
'
'
' #########################################
' #####  GetPrivateProfileStringA ()  #####
' #########################################
'
FUNCTION  GetPrivateProfileStringA (sectionAddr, keyAddr, defaultAddr, bufferAddr, bufferBytes, filenameAddr)
'
'	PRINT "Kernel32 : GetPrivateProfileStringA()"
'
END FUNCTION
'
'
' ###############################
' #####  GetProcAddress ()  #####
' ###############################
'
FUNCTION  GetProcAddress (handle, funcNameAddr)
	SHARED  DLL  library[]
'
'	upper = UBOUND (library[])
'	FOR i = 0 TO upper
'		IF (handle = library[i].handle) THEN EXIT FOR
'	NEXT i
'
	IFZ handle THEN RETURN (0)
'
	addr = dlsym (handle, funcNameAddr)
	RETURN (addr)
END FUNCTION
'
'
' #############################
' #####  GetStdHandle ()  #####
' #############################
'
FUNCTION  GetStdHandle (stdDevice)
'
'	PRINT "Kernel32 : GetStdHandle()"
'
END FUNCTION
'
'
' ####################################
' #####  GetSystemDirectoryA ()  #####
' ####################################
'
FUNCTION  GetSystemDirectoryA (pathAddr, pathSize)
'
'	PRINT "Kernel32 : GetSystemDirectoryA()"
'
END FUNCTION
'
'
' ##############################
' #####  GetSystemInfo ()  #####
' ##############################
'
FUNCTION  GetSystemInfo (infoAddr)
'
'	PRINT "Kernel32 : GetSystemInfo()"
'
END FUNCTION
'
'
' #############################
' #####  GetSysteTime ()  #####
' #############################
'
FUNCTION  GetSystemTime (addrSystemTime)
'
'	PRINT "Kernel32 : GetSystemTime()"
'
END FUNCTION
'
'
' #############################
' #####  GetTickCount ()  #####
' #############################
'
FUNCTION  GetTickCount ()
'
'	PRINT "Kernel32 : GetTickCount()"
'
END FUNCTION
'
'
' ###########################
' #####  GetVersion ()  #####
' ###########################
'
FUNCTION  GetVersion ()
'
'	PRINT "Kernel32 : GetVersion()"
'
END FUNCTION
'
'
' #####################################
' #####  GetWindowsDirectoryA ()  #####
' #####################################
'
FUNCTION  GetWindowsDirectoryA (pathAddr, pathSize)
'
'	PRINT "Kernel32 : GetWindowsDirectoryA()"
'
END FUNCTION
'
'
' ############################
' #####  GlobalAlloc ()  #####
' ############################
'
FUNCTION  GlobalAlloc (memType, byteSize)
'
'	PRINT "Kernel32 : GlobalAlloc()"
'
END FUNCTION
'
'
' ###########################
' #####  GlobalLock ()  #####
' ###########################
'
FUNCTION  GlobalLock (handle)
'
'	PRINT "Kernel32 : GlobalLock()"
'
END FUNCTION
'
'
' ###########################
' #####  GlobalSize ()  #####
' ###########################
'
FUNCTION  GlobalSize (handle)
'
'	PRINT "Kernel32 : GlobalSize()"
'
END FUNCTION
'
'
' #############################
' #####  GlobalUnlock ()  #####
' #############################
'
FUNCTION  GlobalUnlock (handle)
'
'	PRINT "Kernel32 : GlobalUnlock()"
'
END FUNCTION
'
'
' #############################
' #####  LoadLibraryA ()  #####
' #############################
'
FUNCTION  LoadLibraryA (fileNameAddr)
	SHARED  DLL  library[]
'
	whomask = ##WHOMASK
	lockout = ##LOCKOUT
'
	name$ = TRIM$(CSTRING$(fileNameAddr))
	upper = UBOUND (library[])
'
'	PRINT "kernel32.x - LoadLibraryA().A : <"; name$; ">";; upper
'
	FOR i = 0 TO upper
		lib$ = TRIM$(library[i].name)
		IF (lib$ = name$) THEN								' library already open
			INC library[i].count								' increment library open count
'			PRINT "LoadLibraryA().B : <"; name$; ">";; HEX$(library[i].handle,8);; library[i].count;; upper
			RETURN (library[i].handle)					' return already allocated handle
		END IF
	NEXT i
'
	IF ((LEFT$(name$,3) == "lib") || INSTR(name$, ".so")) THEN
		soname$ = name$
	ELSE
		soname$ = "lib" + name$ + ".so"
	END IF
'
	SELECT CASE TRUE
		CASE RIGHT$(name$,2) == ".a" : soname$ = name$  'static is invalid
		CASE LEFT$(name$,3) == "lib" : soname$ = name$
		CASE INSTR(name$, ".so")     : soname$ = name$
		CASE ELSE                    : soname$ = "lib" + name$ + ".so"
	END SELECT
'
' The "c" library is a special beast. This is a temporary fix
' for testing and will be changed in the future.
'
	IF (soname$ == "libc.so") THEN soname$ = "libc.so.6"
'
	##WHOMASK = 0
	##LOCKOUT = $$TRUE
	handle = dlopen (&soname$, 2)        ' 2 is RD_NOW flag
	##LOCKOUT = lockout
	##WHOMASK = whomask
'
	IFZ handle THEN
		PRINT "kernel32.x - LoadLibraryA().C : dlopen() failed : <"; name$; "> <"; lib$; ">";; upper
		error$ = CSTRING$(dlerror())
		PRINT "<" soname$ "> "error$
		RETURN ($$FALSE)
	END IF
'
	FOR i = 0 TO upper
		IF (handle = library[i].handle) THEN			' library already open
			INC library[i].count										' increment open count
'			PRINT "kernel32.x - LoadLibraryA().D : dlopen() : <"; name$; "> already open : "; HEX$(handle,8);; library[i].count;; i;; upper
			##WHOMASK = 0
			##LOCKOUT = $$TRUE
			dlclose (handle)
			##LOCKOUT = lockout
			##WHOMASK = whomask
			RETURN (handle)
		END IF
	NEXT i
'
	slot = -1
	FOR i = 0 TO upper
		IFZ library[i].handle THEN
			slot = i
			EXIT FOR
		END IF
	NEXT i
'
	IF (slot < 0) THEN
		slot = upper + 1
		upper = upper + 16
		##WHOMASK = 0
		REDIM library[upper]
		##WHOMASK = whomask
	END IF
'
	library[slot].name = name$
	library[slot].handle = handle
	library[slot].count = 1
'	PRINT "kernel32.x - LoadLibraryA().Z : <"; name$; ">";; HEX$(handle,8);; slot;; library[slot].count
	RETURN (handle)
END FUNCTION
'
'
' #############################
' #####  LoadResource ()  #####
' #############################
'
FUNCTION  LoadResource (resourceModuleHandle, resourceHandle)
'
'	PRINT "Kernel32 : LoadResource()"
'
END FUNCTION
'
'
' ##########################
' #####  MoveFileA ()  #####
' ##########################
'
FUNCTION  MoveFileA (oldFileAddr, newFileAddr)
'
'	PRINT "Kernel32 : MoveFileA()"
'
END FUNCTION
'
'
' ############################
' #####  OpenProcess ()  #####
' ############################
'
FUNCTION  OpenProcess (access, inherit, process)
'
'	PRINT "Kernel32 : OpenProcess()"
'
END FUNCTION
'
'
' ###############################
' #####  RaiseException ()  #####
' ###############################
'
FUNCTION  RaiseException (exception, flags, argCount, argArray)
'
'	PRINT "Kernel32 : RaiseException()"
'
END FUNCTION
'
'
' #########################
' #####  ReadFile ()  #####
' #########################
'
FUNCTION  ReadFile (fileHandle, addrBuffer, readBytes, addrBytesRead, addrOverlapStruc)
'
'	PRINT "Kernel32 : ReadFile()"
'
END FUNCTION
'
'
' #################################
' #####  RemoveDirectoryA ()  #####
' #################################
'
FUNCTION  RemoveDirectoryA (dirNameAddr)
'
'	PRINT "Kernel32 : RemoveDirectoryA()"
'
END FUNCTION
'
'
' #############################
' #####  SetCommState ()  #####
' #############################
'
FUNCTION  SetCommState (handleDevice, addrControlBlock)
'
'	PRINT "Kernel32 : SetCommState()"
'
END FUNCTION
'
'
' #####################################
' #####  SetCurrentDirectoryA ()  #####
' #####################################
'
FUNCTION  SetCurrentDirectoryA (dirNameAddr)
'
'	PRINT "Kernel32 : SetCurrentDirectoryA()"
'
END FUNCTION
'
'
' ###################################
' #####  SetFileAttributesA ()  #####
' ###################################
'
FUNCTION  SetFileAttributesA (fileNameAddr, attributes)
'
'	PRINT "Kernel32 : SetFileAttributesA()"
'
END FUNCTION
'
'
' ###############################
' #####  SetFilePointer ()  #####
' ###############################
'
FUNCTION  SetFilePointer (fileHandle, moveBytes, addrMoveByteHigh, moveMethod)
'
'	PRINT "Kernel32 : SetFilePointer()"
'
END FUNCTION
'
'
' ############################
' #####  SetFileTime ()  #####
' ############################
'
FUNCTION  SetFileTime (fileHandle, addrCreate, addrAccess, addrModify)
'
'	PRINT "Kernel32 : SetFileTime()"
'
END FUNCTION
'
'
' #############################
' #####  SetLastError ()  #####
' #############################
'
FUNCTION  SetLastError (error)
'
'	PRINT "Kernel32 : SetLastError()"
'
END FUNCTION
'
'
' #############################
' #####  SetLocalTime ()  #####
' #############################
'
FUNCTION  SetLocalTime (addrSystemTime)
'
'	PRINT "Kernel32 : SetLocalTime()"
'
END FUNCTION
'
'
' ##############################
' #####  SetSystemTime ()  #####
' ##############################
'
FUNCTION  SetSystemTime (addrSystemTime)
'
'	PRINT "Kernel32 : SetSystemTime()"
'
END FUNCTION
'
'
' ######################
' #####  Sleep ()  #####
' ######################
'
FUNCTION  Sleep (milliseconds)
'
'	PRINT "Kernel32 : Sleep()"
'
END FUNCTION
'
'
' #####################################
' #####  SystemTimeToFileTime ()  #####
' #####################################
'
FUNCTION  SystemTimeToFileTime (addrSystemTime, addrFileTime)
'
'	PRINT "Kernel32 : SystemTimeToFileTime()"
'
END FUNCTION
'
'
' #############################
' #####  VirtualAlloc ()  #####
' #############################
'
FUNCTION  VirtualAlloc (addr, size, type, protect)
'
'	PRINT "Kernel32 : VirtualAlloc()"
'
END FUNCTION
'
'
' ############################
' #####  VirtualFree ()  #####
' ############################
'
FUNCTION  VirtualFree (addr, size, type)
'
'	PRINT "Kernel32 : VirtualFree()"
'
END FUNCTION
'
'
' ###############################
' #####  VirtualProtect ()  #####
' ###############################
'
FUNCTION  VirtualProtect (addr, size, newProtect, oldProtectBuffer)
'
'	PRINT "Kernel32 : VirtualProtect()"
'
END FUNCTION
'
'
' ##########################
' #####  WriteFile ()  #####
' ##########################
'
FUNCTION  WriteFile (fileHandle, addrBuffer, writeBytes, addrBytesWritten, addrOverlapStruc)
'
'	PRINT "Kernel32 : WriteFile()"
'
END FUNCTION
'
'
' ###########################################
' #####  WritePrivateProfileStringA ()  #####
' ###########################################
'
FUNCTION  WritePrivateProfileStringA (sectionAddr, keyAddr, addStringAddr, filenameAddr)
'
'	PRINT "Kernel32 : WritePrivateProfileStringA()
'
END FUNCTION
END PROGRAM

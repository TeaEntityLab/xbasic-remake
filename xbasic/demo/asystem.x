'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"asystem"
VERSION	"0.0005"
'
IMPORT "xst"
IMPORT "xgr"
IMPORT "xui"
IMPORT "xcm"
IMPORT "xma"
'
DECLARE FUNCTION  Entry ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	xcm$ = XcmVersion$ ()
	xma$ = XmaVersion$ ()
	xst$ = XstVersion$ ()
	xgr$ = XgrVersion$ ()
	xui$ = XuiVersion$ ()
	XstGetCommandLineArguments (@argc, @argv$[])
	XstGetDateAndTime (@year, @month, @day, @weekDay, @hour, @minute, @second, @nsec)
	XstGetEndian (@endian$$)
	XstGetEndianName (@endian$)
	XstGetEnvironmentVariables (@envp, @envp$[])
	XstGetImplementation (@implementation$)
	XstGetCPUName (@cpu$)
	XstGetOSName (@osName$)
	XstGetOSVersion (@major, @minor)
	XstGetOSVersionName (@osVersion$)
	XstGetCurrentDirectory (@directory$)
	XstGetDrives (@drives, @drive$[], @driveType[], @driveType$[])
'
	w = 19
	PRINT
	PRINT RJUST$("argc = ", w); "'"; STRING$(argc); "'"
	FOR i = 0 TO argc-1 : PRINT RJUST$("argv$[" + STRING$(i) + "] = ", w); "'"; argv$[i]; "'" : NEXT i
	PRINT RJUST$("date/time = ", w); "'"; STRING$(year); "'y  '"; STRING$(month); "'m  '"; STRING$(day); "'d  '"; STRING$(weekDay); "'w  '"; STRING$(hour); "'h  '"; STRING$(minute); "'m  '"; STRING$(second); "'s  '"; RJUST$(STRING$(nsec),9); "'ns"
	PRINT RJUST$("XcmVersion$ = ", w); "'"; xcm$; "'"
	PRINT RJUST$("XmaVersion$ = ", w); "'"; xma$; "'"
	PRINT RJUST$("XstVersion$ = ", w); "'"; xst$; "'"
	PRINT RJUST$("XgrVersion$ = ", w); "'"; xgr$; "'"
	PRINT RJUST$("XuiVersion$ = ", w); "'"; xui$; "'"
	PRINT RJUST$("envpCount = ", w); "'"; STRING$(envp); "'"
	FOR i = 0 TO envp-1 : PRINT RJUST$("envp$[" + STRING$(i) + "] = ", w); "'"; envp$[i]; "'" : NEXT i
	PRINT RJUST$("cpu = ", w); "'"; cpu$; "'"
	PRINT RJUST$("endian = ", w); "'"; HEXX$(endian$$,16); "'"
	PRINT RJUST$("endian$ = ", w); "'"; endian$; "'"
	PRINT RJUST$("os$ = ", w); "'"; osName$; "'"
	PRINT RJUST$("implementation$ = ", w); "'"; implementation$; "'"
	PRINT RJUST$("version = ", w); "'"; STRING$(major); "' ... '"; STRING$(minor); "'"
	PRINT RJUST$("version$ = ", w); "'"; osVersion$; "'"
	PRINT RJUST$("directory$ = ", w); "'"; directory$; "'"
	PRINT RJUST$("drives = ", w); "'"; STRING$(drives); "'"
	FOR i = 0 TO drives-1 : PRINT RJUST$("drive$[" + STRING$(i) + "] = ", w); "'"; drive$[i]; "'  '"; STRING$(driveType[i]); "'  '"; driveType$[i]; "'" : NEXT i
END FUNCTION
END PROGRAM

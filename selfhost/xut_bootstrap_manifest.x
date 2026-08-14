VERSION "0.0001"
$$XBSysLinux = 1
$$XBSysWin32 = 2
FUNCTION PlatformName$
IF $$XBSysLinux THEN
RETURN "linux"
END IF
RETURN "unknown"
END FUNCTION
FUNCTION Main
DIM utilityName$
DIM utilityVersion#
utilityName$ = "xut"
utilityVersion# = 0.0001
##XBSystem = $$XBSysLinux
PRINT utilityName$
PRINT utilityVersion#
PRINT $$XBSysLinux
PRINT $$XBSysWin32
PRINT ##XBSystem
IF $$XBSysLinux THEN
PRINT "linux"
END IF
IF ##XBSystem = $$XBSysLinux THEN
PRINT "match"
PRINT $$XBSysLinux + $$XBSysWin32
PRINT PlatformName()
END IF
END FUNCTION

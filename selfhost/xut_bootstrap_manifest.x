VERSION "0.0001"
$$XBSysLinux = 1
$$XBSysWin32 = 2
FUNCTION Main
DIM utilityName$
DIM utilityVersion#
utilityName$ = "xut"
utilityVersion# = 0.0001
PRINT utilityName$
PRINT utilityVersion#
PRINT $$XBSysLinux
PRINT $$XBSysWin32
END FUNCTION

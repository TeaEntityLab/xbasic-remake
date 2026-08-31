'
'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"atask"
VERSION	"0.0003"  ' 2012 September 8
'
	IMPORT	"xst"
	IMPORT	"xgr"
	IMPORT	"xui"
'

DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  TaskOne ()
DECLARE FUNCTION  TaskTwo ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
	SHARED msecStart
	SHARED terminateProgram
'
	XstDisplayConsole ()  ' make console if stand-alone
	XstClearConsole ()
'
	count = 14
	msec  = 1000
	XstGetSystemTime (@msecStart)
	rc = XstStartTask (@task1, count, msec, &TaskOne())
'
	count = -1
	msec  = 1000
	XstGetSystemTime (@msecStart)
	rc = XstStartTask (@task2, count, msec, &TaskTwo())
'
	PRINT
	PRINT " assigned   taskNum count msec  &func()   timer skips "
	assigned = XstGetTaskInfo (task1, @count, @msec, @func, @timer, @skips)
	PRINT  HEXX$(assigned);;;;;task1;;;;;;count;;msec;;HEXX$(func);;;timer;;;;;skips
	assigned = XstGetTaskInfo (task2, @count, @msec, @func, @timer, @skips)
	PRINT  HEXX$(assigned);;;;;task2;;;;;;;count;;msec;;HEXX$(func);;;timer;;;;;skips
	PRINT
	IFZ assigned THEN RETURN
'
'
' convenience function message loop
'
	DO
		XgrProcessMessages ($$ProcessOneOnly)
		DO WHILE XuiGetNextCallback (@grid, @message$, @v0, @v1, @v2, @v3, @kid, @r1$)
'			GOSUB Callback
		LOOP
	LOOP UNTIL terminateProgram

	XstGetSystemTime (@msec)
	PRINT "finished", msec - msecStart
	s$ = INLINE$ ("Press Enter to Exit ==>")
'
END FUNCTION
'
'
' ########################
' #####  TaskOne ()  #####
' ########################
'
FUNCTION  TaskOne ()
	SHARED msecStart
'
	XstGetSystemTime (@msec)
	duration = msec - msecStart
	PRINT "      TaskOne()   ", duration;
	IF (duration >= 2000 && duration < 3000) THEN
		PRINT " - - - - change count=5, msec=1500"
		XstStartTask (@taskNum, 5, 1500, &TaskOne())
'
		assigned = XstGetTaskInfo (taskNum, @count, @msec, @func, @timer, @skips)
'
		PRINT " assigned   taskNum count msec  &func()   timer skips "
		PRINT  HEXX$(assigned);;;;;taskNum;;;;;;count;;msec;;HEXX$(func);;;timer;;;;;skips
	END IF
	IF (duration >= 7000) THEN
		PRINT " - - - - kill TaskOne() with \'RETURN ($$TRUE)\'"
		RETURN ($$TRUE)
	END IF
	PRINT
'
END FUNCTION
'
'
' ########################
' #####  TaskTwo ()  #####
' ########################
'
FUNCTION  TaskTwo ()
	SHARED msecStart
	SHARED terminateProgram
'
	XstGetSystemTime (@msec)
	duration = msec - msecStart
	PRINT "        TaskTwo()        ", duration
'
	IF (duration > 15000) THEN
		PRINT "duration more than 15 seconds, set terminateProgram to $$TRUE"
		terminateProgram = $$TRUE
	END IF
'
END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM "atimer"
VERSION "0.0006"  ' 2011 May 13
'
TYPE ATIMER
	XLONG .timer
	XLONG .count
	XLONG .msec
	XLONG .time
END TYPE
'
IMPORT "xst"
'
DECLARE  FUNCTION  Entry ()
INTERNAL FUNCTION  Timer (timer, count, msec, time)
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
' This function tells XstStartTimer() to:
'   Create and start a timer.
'   Return timer number in timer1.
'   Tell timer1 to cycle 10 times.
'   Set timer1 interval to 1000 milliseconds.
'   Call Timer() whenever timer1 times out.
'
'   Create and start another timer.
'   Return timer number in timer2.
'   Tell timer2 to cycle 3 times.
'   Set timer2 interval to 2500 milliseconds.
'   Call Timer() whenever timer2 times out.
'
' *************************************
' *****  Timers Are Asynchronous  *****
' *************************************
'
' Note that timeouts can occur at any machine instruction
' boundary in your program.  In other words, timeouts can
' interrupt your program at any point, including part way
' between lines in your program, and call the function you
' specified in XstStartTimer().  This function can thus
' encounter variables, or sets of related variables, in
' invalid or partially updated state if they are modified
' elsewhere in your program.  Timeout functions in many
' programs simply increment a timeout variable that is
' examined periodically by your program, and acted on and
' decremented when found to be non-zero.
'
' Note that GraphicsDesigner timers and timeouts do not
' have these considerations, since your program has to
' call XgrProcessMessage(), XgrPeekMessage(), or another
' GraphicsDesigner function to respond to timeout messages.
'
FUNCTION  Entry ()
	SHARED ATIMER atimer[]
	SHARED index
'
	XstDisplayConsole ()
'
	DIM atimer[12]
	index = 0
	XstClearConsole ()
	PRINT HEXX$(&Timer())

	PRINT "*********************************************"
	PRINT "*****  Read the comments in the source  *****"
	PRINT "*****  code for this program carefully  *****"
	PRINT "*********************************************"
	PRINT
	PRINT "*****  start atimer.x program  *****"
	PRINT "*****  waiting for 10 seconds  *****"
	XstStartTimer (@timer1, 10, 1000, &Timer())
	XstStartTimer (@timer2, 3, 2500, &Timer())
	XstGetSystemTime (@atime)
	whomask = ##WHOMASK
	XstSleep (10000)
	XstGetSystemTime (@ztime)
'
	PRINT
	PRINT " timer count  msec   time"
	FOR i = 0 TO index-1
		atimer$ = RJUST$(STRING$(atimer[i].timer),5)
		atimer$ = atimer$ + RJUST$(STRING$(atimer[i].count),6)
		atimer$ = atimer$ + RJUST$(STRING$(atimer[i].msec),8)
		atimer$ = atimer$ + RJUST$(STRING$(atimer[i].time),10)
		PRINT atimer$
	NEXT i
	PRINT
'
	PRINT "actual sleep time = "; ztime-atime; " ms"
	PRINT "*****  done atimer.x program  *****"
	PRINT
	s$ = INLINE$ ("Press Enter to Exit ==>")
END FUNCTION
'
'
' ######################
' #####  Timer ()  #####
' ######################
'
' This function can change count to add or subtract remaining timeouts.
' Entry() told XstStartTimer() to call this function upon timeouts.
' This function is called whenever either timer times out.
' This function can return -1 to kill the timer.
' This function can set count to zero to kill the timer.
' XBasic-6.3.3 does not allow XstKillTimer() or XstStartTimer()
' while a timer interrupt is being handled.
'
' This function should not do anything that require allocating
' dynamic memory, because, if another XBasic function is in the middle
' of allocating memory at the instant a timer interrupt occurs and also
' tries to allocate memory an error will eventually result.
' A timer interrupt function should never do a PRINT, DIM, REDIM
' And never do any manipulation of string variables or string arrays.
' These are variables that end with the dollar sign (ie. a$ and b$[])
'
' In this example, atimer[] is an array, but not a string array.
' Its scope is SHARED so memory is not allocated when this function
' is called, and it is dimensioned in the ENTRY() function.
'
FUNCTION  Timer (timer, count, msec, time)
	SHARED ATIMER atimer[]
	SHARED index
'
	utimer = UBOUND(atimer[])
	IF (index <= utimer) THEN
		atimer[index].timer = timer
		atimer[index].count = count
		atimer[index].msec = msec
		atimer[index].time = time
		INC index
	END IF

	IF (count = 8) THEN count = 5										' reduce count to 5
	IF (count = 3) THEN RETURN (-1)									' one way to kill timer
	IF (count = 1) THEN count = 0										' kill timer early
END FUNCTION
END PROGRAM

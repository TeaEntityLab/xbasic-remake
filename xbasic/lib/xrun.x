'
'
'  ####################  Max Reason
'  #####  PROLOG  #####  copyright 1988-2000
'  ####################  Linux XBasic executable support
'
' subject to LGPL license - see COPYING_LIB
'
' maxreason@maxreason.com
'
' for Linux XBasic
'
'
PROGRAM	"xrun"
VERSION	"6.4.5"
'
IMPORT	"xst"
IMPORT	"xin"
IMPORT	"xma"
IMPORT	"xcm"
IMPORT	"xgr"
IMPORT	"xui"
IMPORT	"clib"
IMPORT	"kernel32"
IMPORT	"xut"
'
'
DECLARE FUNCTION  XxxXit                    (argc, argv, envp)
'DECLARE CFUNCTION  XxxXitMain               (sigNumber)        '*cw* 210618-
DECLARE CFUNCTION  XxxXitMain               (sigNumber, ptregs) '*cw* 210618+
DECLARE CFUNCTION  XxxXitSigAlrm            (signal)
INTERNAL FUNCTION  EstablishSignals         ()
INTERNAL FUNCTION  InitProgram              ()
'
' These empty functions need to be in here because they're
' called by xst.x and/or xui.x
'
DECLARE FUNCTION  XitGetDECLARE            (func$, declare$)		' called by xui.x
DECLARE FUNCTION  XitGetDisplayedFunction  (func$)							' called by xui.x
DECLARE FUNCTION  XitGetFunction           (func$, text$[])			' called by xui.x
DECLARE FUNCTION  XitQueryFunction         (func$, exists)			' called by xui.x
DECLARE FUNCTION  XitSetDECLARE            (func$, declare$)		' called by xui.x
DECLARE FUNCTION  XitSetDisplayedFunction  (func$)							' called by xui.x
DECLARE FUNCTION  XitSetFunction           (func$, text$[])			' called by xui.x
DECLARE FUNCTION  XitSoftBreak             ()										' called by xui.x
DECLARE FUNCTION  XxxGetLabelGivenAddress  (address, label$[])	' called by xui.x
DECLARE FUNCTION  XxxXitGetUserProgramName (file$)							' called by xui.x
DECLARE FUNCTION  XxxSetBlowback           ()										' called by xst.x
DECLARE FUNCTION  XxxXitExit               (status)							' called by xst.x
DECLARE FUNCTION  XxxXitSetStatusInline    (set)                ' called by XuiConsole
'
EXTERNAL FUNCTION  XxxStartApplication      ()									' in application
EXTERNAL FUNCTION  XxxSetExceptions         (exception, osexception)	' in xlib.s
EXTERNAL FUNCTION	 Xio											()
EXTERNAL FUNCTION  XxxXstTimer              (command, tgrid, timer, count, msec, func)
EXTERNAL FUNCTION  XxxGetRbpRsp             (@rbp, @rsp)
'
'
'
' timer command arguments to XxxXstTimer()
'
'	$$TimerStart					= 1        '*cw*
'	$$TimerExpire					= 2        '*cw*
'	$$TimerKill						= 3        '*cw*
'
'
' #######################
' #####  XxxXit ()  #####  Entry Function
' #######################
'
FUNCTION  XxxXit (argc, argv, envp)
	STATIC  firstEntry
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "Linux XBasic executable support"
	a$ = "maxreason@maxreason.com"
	a$ = ""
'
	IFZ firstEntry THEN
		firstEntry = $$TRUE
		' Note: Linux is currently the only OS supported by this source.
		##XBSystem = $$XBSysLinux
		InitProgram ()
		EstablishSignals ()                                                 '*cw* 090625
		Xst ()
		XutInit ()
		Xio	()
'		Xin ()                                                              '*cw* 160812-
		Xma ()
		Xcm ()
		Xgr ()
		Xui ()
	END IF
'
'	error = XxxXitMain (0)     '*cw* 210618-
	error = XxxXitMain (0, 0)  '*cw* 210618+
	RETURN (error)
END FUNCTION
'
'
' ########################
' #####  XxxXitMain  #####  Called on program startup and all signals
' ########################
'
'CFUNCTION  XxxXitMain (sigNumber)         '*cw* 210618-
CFUNCTION  XxxXitMain (sigNumber, ptregs)  '*cw* 210618+
	FUNCADDR	func()
	ULONG     ##STACKX
'
' *****  start program  *****
'
	IFZ sigNumber THEN
'		EstablishSignals ()                              '*cw* 090625 moved to XxxXit()
		error = XxxStartApplication ()
		RETURN (error)
	END IF
'
' *****  Process Exception  *****
'
	IF ##INEXIT THEN exit (0)
'
	lockout = ##LOCKOUT                                                            '*cw* 150725+
	##LOCKOUT = 0                                                                  '*cw* 150725+
'
	IF ##XBDV THEN
		XxxGetRbpRsp (@rbp, @rsp)
		sxip = XLONGAT (rbp, [17])
		frames$ = "\n" + HEXX$(sxip,8) + "\n"
		DO WHILE (rbp < ##STACKX)
			funcAddress = XLONGAT(rbp,8)                    ' return address in calling function
			frames$ = frames$ + HEXX$(funcAddress,16) + "\n"
			rbp = XLONGAT(rbp)                              ' calling rbp address = [rbp]
		LOOP
	END IF


	XstSystemExceptionToException (sigNumber, @exception)
	SELECT CASE exception
		CASE $$ExceptionTimer
			XxxXstTimer ($$TimerExpire, 0, 0, 0, 0, 0)
			RETURN ($$FALSE)
	END SELECT
	XstExceptionNumberToName (exception, @exception$)
	XstGetExceptionFunction (@response)
	XxxSetExceptions (exception, sigNumber)
	XstGetCommandLine (@line$)                                                      '*cw* 150725+
	log$ = "\n" + line$ + "\n"                                                      '*cw* 150725+
	log$ = + log$ + " xrun.x - XxxXitMain() : \nexception$, exception, response = "
	log$ = log$ +  exception$ + " " + STRING$(exception) + " " + HEXX$(response,8)
	IF lockout THEN                                                                 '*cw* 150725+
		log$ = log$ + "\nLOCKOUT = " + STR$(lockout)                                  '*cw* 150725+
	END IF
	log$ = log$ + frames$                                                           '*cw* 130924+
	XstLog (@log$)
'
	IF ##INEXIT THEN exit(0)
'
	DO
		SELECT CASE response
			CASE $$ExceptionContinue	: RETURN ($$FALSE)
'			CASE $$ExceptionTerminate	: RETURN ($$TRUE)                                 '*cw* 130924-
			CASE $$ExceptionTerminate	: exit(0)                                         '*cw* 130924+
			CASE ELSE									: func = response
																	response = @func()
		END SELECT
	LOOP
END FUNCTION
'
'
'  ###########################
'  #####  XxxXitSigAlrm  #####   '*cw* 090422
'  ###########################
'
CFUNCTION  XxxXitSigAlrm (signal)
'
	IF ##TIMERLOCKOUT THEN RETURN                                             '*cw* 110522
	lockout      = ##LOCKOUT

	lockout = ##LOCKOUT                                                       '*cw* 110525
	##LOCKOUT = 0                                                             '*cw* 110525
	##TIMERLOCKOUT = $$TRUE                                                   '*cw* 110525
	XxxXstTimer ($$TimerExpire, 0, 0, 0, 0, 0)
	##TIMERLOCKOUT = $$FALSE                                                  '*cw* 110525
	##LOCKOUT = lockout                                                       '*cw* 110525
'
END FUNCTION
'
'
' #################################
' #####  EstablishSignals ()  ##### copied from xit.x
' #################################
'
' based on UNIX debug version
'
FUNCTION  EstablishSignals ()
	USIGACTION	sig
'
'	PRINT "EstablishSignals() : Enter"
	mask = 0x00000000
	mask = mask OR $$SIGMASK_HUP '*cw* 090314
'	mask = mask OR $$SIGMASK_INT
'	mask = mask OR $$SIGMASK_QUIT
	mask = mask OR $$SIGMASK_ILL			' later comment this one out !!!
	mask = mask OR $$SIGMASK_TRAP			' mask $$SIGILL out now because
'	mask = mask OR $$SIGMASK_ABRT			' $$SIGILL is occuring right after
	mask = mask OR $$SIGMASK_IOT			' entry into the XxxXitMain()
	mask = mask OR $$SIGMASK_BUS
'	mask = mask OR $$SIGMASK_FPE			' screws up the frame information.
	mask = mask OR $$SIGMASK_KILL '*cw* 090314
	mask = mask OR $$SIGMASK_USR1
	mask = mask OR $$SIGMASK_SEGV
	mask = mask OR $$SIGMASK_USR2
	mask = mask OR $$SIGMASK_PIPE
'	mask = mask OR $$SIGMASK_ALRM     'do not mask SIGALRM on breakpoint trap  *cw* 090312
	mask = mask OR $$SIGMASK_TERM '*cw* 090314
	mask = mask OR $$SIGMASK_STKFLT
	mask = mask OR $$SIGMASK_CHLD
	mask = mask OR $$SIGMASK_CONT
	mask = mask OR $$SIGMASK_STOP
	mask = mask OR $$SIGMASK_TSTP
	mask = mask OR $$SIGMASK_TTIN
	mask = mask OR $$SIGMASK_TTOU
	mask = mask OR $$SIGMASK_URG
	mask = mask OR $$SIGMASK_XCPU
	mask = mask OR $$SIGMASK_XFSZ
	mask = mask OR $$SIGMASK_VTALRM
	mask = mask OR $$SIGMASK_WINCH
	mask = mask OR $$SIGMASK_IO
	mask = mask OR $$SIGMASK_POLL
	mask = mask OR $$SIGMASK_PWR
	mask = mask OR $$SIGMASK_UNUSED
	mask = mask OR $$SIGMASK_MAX
'
	sig.sa_handler = &XxxXitMain()	' signal catching function
	sig.sa_mask = mask							' block all signals upon signal catch
	sig.sa_flags = 0								' nothing special
'
	e = xb_sigaction ($$SIGTRAP, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGTRAP"     'do not mask SIGALRM on breakpoint trap  *cw* 090312
	mask = mask OR $$SIGMASK_ALRM                                                   'mask SIGALRM on remaining signals       *cw* 090312
'
	e = xb_sigaction ($$SIGINT, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGINT"
	e = xb_sigaction ($$SIGQUIT, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGQUIT"
	e = xb_sigaction ($$SIGILL, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGILL"
'	e = xb_sigaction ($$SIGTRAP, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGTRAP"     'see above *cw* 090312
	e = xb_sigaction ($$SIGABRT, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGABRT"
	e = xb_sigaction ($$SIGFPE, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGFPE"
	e = xb_sigaction ($$SIGBUS, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGBUS"
	e = xb_sigaction ($$SIGSEGV, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGSEGV"
'	e = xb_sigaction ($$SIGSYS, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGSYS"
'	e = xb_sigaction ($$SIGALRM, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGALRM"     '*cw* 090312
	e = xb_sigaction ($$SIGTERM, &sig, 0)		: IF (e < 0) THEN PRINT "$$SIGTERM"
	e = xb_sigaction ($$SIGVTALRM, &sig, 0) : IF (e < 0) THEN PRINT "$$SIGVTALRM"

	sig.sa_handler = &XxxXitSigAlrm()                                               '*cw* 090312
	e = xb_sigaction ($$SIGALRM, &sig, 0) : IF (e < 0) THEN PRINT "$$SIGALRM"       '*cw* 090312

'	PRINT "EstablishSignals() : Leave"
END FUNCTION
'
'
' #########################
' #####  InitProgram  #####
' #########################
'
FUNCTION  InitProgram ()
'
END FUNCTION
'
'
' ##############################
' #####  XitGetDECLARE ()  #####
' ##############################
'
FUNCTION  XitGetDECLARE (func$, declare$)
'
' This function in xit.x is called by xui.x
'
END FUNCTION
'
'
' ########################################
' #####  XitGetDisplayedFunction ()  #####
' ########################################
'
FUNCTION  XitGetDisplayedFunction (func$)
'
' This function in xit.x is called by xui.x
'
END FUNCTION
'
'
' ###############################
' #####  XitGetFunction ()  #####
' ###############################
'
FUNCTION  XitGetFunction (func$, text$[])
'
' This function in xit.x is called by xui.x
'
END FUNCTION
'
'
' #################################
' #####  XitQueryFunction ()  #####
' #################################
'
FUNCTION  XitQueryFunction (func$, exists)
'
' This function in xit.x is called by xui.x
'
END FUNCTION
'
'
' ##############################
' #####  XitSetDECLARE ()  #####
' ##############################
'
FUNCTION  XitSetDECLARE (func$, declare$)
'
' This function in xit.x is called by xui.x
'
END FUNCTION
'
'
' ########################################
' #####  XitSetDisplayedFunction ()  #####
' ########################################
'
FUNCTION  XitSetDisplayedFunction (func$)
'
' This function in xit.x is called by xui.x
'
END FUNCTION
'
'
' ###############################
' #####  XitSetFunction ()  #####
' ###############################
'
FUNCTION  XitSetFunction (func$, text$[])
'
' This function in xit.x is called by xui.x
'
END FUNCTION
'
'
' #############################
' #####  XitSoftBreak ()  #####
' #############################
'
FUNCTION  XitSoftBreak ()
'
	pid = getpid ()
	kill (pid, $$ExceptionBreakKey)
END FUNCTION
'
'
' ########################################
' #####  XxxGetLabelGivenAddress ()  #####
' ########################################
'
FUNCTION  XxxGetLabelGivenAddress (address, label$[])
'
' This function in xcol.x/xcow.x is called by xui.x
'
END FUNCTION
'
'
' #########################################
' #####  XxxXitGetUserProgramName ()  #####
' #########################################
'
FUNCTION  XxxXitGetUserProgramName (file$)
'
	XstGetCommandLineArguments (@argc, @argv$[])
	IF argc THEN
		IF argv$[] THEN
			IF argv$[0] THEN
				file$ = argv$[0]
			END IF
		END IF
	END IF
END FUNCTION
'
'
' ###############################
' #####  XxxSetBlowback ()  #####
' ###############################
'
FUNCTION  XxxSetBlowback ()
'
' This function in xit.x is called by xst.x
'
END FUNCTION
'
'
' ###########################
' #####  XxxXitExit ()  #####  This function in xit.x is called by xst.x
' ###########################
'
FUNCTION  XxxXitExit (status)
'
	##INEXIT = $$TRUE
	exit (status)
END FUNCTION
'
'
' ######################################
' #####  XxxXitSetStatusInline ()  #####  '*cw* 091230
' ######################################
'
FUNCTION  XxxXitSetStatusInline (set)
'
' This function in xit.x is called by XuiConsole
'

END FUNCTION
END PROGRAM

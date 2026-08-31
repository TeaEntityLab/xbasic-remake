'
'
' ####################  Max Reason
' #####  PROLOG  #####  copyright 1988-2000
' ####################  XBasic mathematics function library
'
' subject to LGPL license - see COPYING_LIB
'
' maxreason@maxreason.com
'
' for Windows XBasic
' for Linux XBasic
'
PROGRAM	"xma"
VERSION	"6.4.5"
'
IMPORT	"xst"
'
'
EXPORT
'
' ###########################
' #####  xma functions  #####
' ###########################
'
' Angles are always in RADIANS
'
DECLARE  FUNCTION  Xma             ()
DECLARE  FUNCTION  XmaVersion$     ()
DECLARE  FUNCTION  DOUBLE  ACOS    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ACOSH   (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ACOT    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ACOTH   (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ACSC    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ACSCH   (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ASEC    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ASECH   (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ASIN    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ASINH   (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  ATAN    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  ATANH   (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  COS     (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  COSH    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  COT     (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  COTH    (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  CSC     (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  CSCH    (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  EXP     (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  LOG     (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  EXP2    (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  EXP10   (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  LOG10   (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  POWER   (DOUBLE x, DOUBLE y)
DECLARE  FUNCTION  DOUBLE  SEC     (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  SECH    (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  SIN     (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  SINH    (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  SQRT    (DOUBLE x)
EXTERNAL  FUNCTION  DOUBLE  TAN     (DOUBLE x)
DECLARE  FUNCTION  DOUBLE  TANH    (DOUBLE x)
'
END EXPORT
'
INTERNAL FUNCTION  DOUBLE  Asin0   (DOUBLE x)
'INTERNAL FUNCTION  DOUBLE  Atan0   (DOUBLE x)
'INTERNAL FUNCTION  DOUBLE  Exp0    (DOUBLE x)
INTERNAL FUNCTION  DOUBLE  Expmo   (DOUBLE x)
INTERNAL FUNCTION  DOUBLE  Log0    (DOUBLE x)
'
' for xma:
'
'INTERNAL FUNCTION  DOUBLE  Clog   (DOUBLE x)
'INTERNAL FUNCTION  DOUBLE  Clog0  (DOUBLE x)
'
'EXTERNAL FUNCTION  XxxFCLEX ()
'EXTERNAL FUNCTION  XxxFINIT ()
EXTERNAL FUNCTION  XxxFSTCW ()
EXTERNAL FUNCTION  XxxFSTSW ()
'
EXTERNAL FUNCTION  DOUBLE  XxxF2XM1   (x#)
EXTERNAL FUNCTION  DOUBLE  XxxFABS    (x#)
EXTERNAL FUNCTION  DOUBLE  XxxFCHS    (x#)
EXTERNAL FUNCTION  DOUBLE  XxxFCOS    (x#)
EXTERNAL FUNCTION  DOUBLE  XxxFLDZ    ()
EXTERNAL FUNCTION  DOUBLE  XxxFLD1    ()
EXTERNAL FUNCTION  DOUBLE  XxxFLDPI   ()
EXTERNAL FUNCTION  DOUBLE  XxxFLDL2E  ()
EXTERNAL FUNCTION  DOUBLE  XxxFLDL2T  ()
EXTERNAL FUNCTION  DOUBLE  XxxFLDLG2  ()
EXTERNAL FUNCTION  DOUBLE  XxxFLDLN2  ()
EXTERNAL FUNCTION  DOUBLE  XxxFPATAN  (x#, @y#)
EXTERNAL FUNCTION  DOUBLE  XxxFPREM   (x#, @y#)
EXTERNAL FUNCTION  DOUBLE  XxxFPREM1  (x#, @y#)
EXTERNAL FUNCTION  DOUBLE  XxxFPTAN   (x#, @y#)
EXTERNAL FUNCTION  DOUBLE  XxxFRNDINT (x#)
EXTERNAL FUNCTION  DOUBLE  XxxFSCALE  (x#, y#)
EXTERNAL FUNCTION  DOUBLE  XxxFSIN    (x#)
EXTERNAL FUNCTION  DOUBLE  XxxFSINCOS (x#, @y#)
EXTERNAL FUNCTION  DOUBLE  XxxFSQRT   (x#)
EXTERNAL FUNCTION  DOUBLE  XxxFXTRACT (x#, @y#)
EXTERNAL FUNCTION  DOUBLE  XxxFYL2X   (x#, @y#)
EXTERNAL FUNCTION  DOUBLE  XxxFYL2XP1 (x#, @y#)
'
EXPORT
'
' ###########################
' #####  xma constants  #####
' ###########################
'
	$$NNAN			=	0dFFFFFFFFFFFFFFFF
	$$PNAN			= 0d7FFFFFFFFFFFFFFF
	$$NINF			= 0dFFF0000000000000
	$$PINF			= 0d7FF0000000000000
	$$RADIANS		= 1
	$$DEGREES		= 2
	$$DEGTORAD	= 0d3F91DF46A2529D39
	$$RADTODEG	= 0d404CA5DC1A63C1F8
	$$PI				= 0d400921FB54442D18
	$$TWOPI			= 0d401921FB54442D18
	$$PI3DIV2		= 0d4012D97C7F3321D2
	$$PIDIV2		= 0d3FF921FB54442D18
	$$PIDIV4		= 0d3FE921FB54442D18
	$$INVPI			= 0d3FD45F306DC9C883
	$$SQRT2			= 0d3FF6A09E667F3BCD
	$$SQRT2DIV2	= 0d3FE6A09E667F3BCD
	$$INVSQRT2	= 0d3FE6A09E667F3BCD
	$$E					= 0d4005BF0A8B145769
	$$LOG2E			= 0d3FF71547652B82FE
	$$LOG210		= 0d400A934F0979A371
	$$LOGE2			= 0d3FE62E42FEFA39EF
	$$LOGE10		= 0d40026BB1BBB55516
	$$LOGESQRT2	= 0d3FD62E42FEFA39EF
	$$LOG102		= 0d3FD34413509F79FF
	$$LOG10E		= 0d3FDBCB7B1526E50E
	$$PIDIV8		= 0d3FD921FB54442D18
	$$PI3DIV8		= 0d3FF2D97C7F3321D2
END EXPORT
'
'
' ####################
' #####  Xma ()  #####
' ####################
'
FUNCTION  Xma ()
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "XBasic mathematics function library"
	a$ = "maxreason@maxreason.com"
	a$ = ""
'
'
' the following doesn't work unless the answer is less than 2
' because the stupid f2xm1 opcode only works if -1 <= x <= +1.
'
'	FOR x# = .01# TO 2# STEP .125#
'		asw = XxxFSTSW ()
'		acw = XxxFSTCW ()
'		a# = EXP (x#)
'		i# = XxxFETOX (x#)
'		zsw = XxxFSTSW ()
'		PRINT FORMAT$("###.###########",x#);;; FORMAT$("###.###########",a#);; FORMAT$("###.###########",i#);; HEX$(asw>>11,1);; HEX$(zsw>>11,1);; HEX$(acw,4)
'	NEXT x#
'	PRINT
'
' the following doesn't work unless the answer is less than 2
' because the stupid f2xm1 opcode only works if -1 <= x <= +1.
'
'
'	FOR x# = .01# TO 2# STEP .125#
'		asw = XxxFSTSW ()
'		b# = 10# ** x#
'		j# = XxxFTENTOX (x#)
'		zsw = XxxFSTSW ()
'		PRINT FORMAT$("###.###########",x#);;; FORMAT$("###.###########",b#);; FORMAT$("###.###########",j#);; HEX$(asw>>11,1);; HEX$(zsw>>11,1)
'	NEXT x#
'	PRINT
'
' the following doesn't work unless the answer is less than 2
' because the stupid f2xm1 opcode only works if -1 <= x <= +1.
'
'
'	FOR x# = .1# TO 2.0001# STEP .02978#
'		asw = XxxFSTSW ()
'		c# = x# ** x#
'		k# = XxxFYTOX (x#, x#)
'		c$$ = GIANTAT (&c#)
'		x$$ = GIANTAT (&x#)
'		k$$ = GIANTAT (&k#)
'		zsw = XxxFSTSW ()
'		PRINT FORMAT$("###.###########",x#);;; FORMAT$("###.###########",c#);; FORMAT$("###.###########",k#);; HEX$(x$$,16);; HEX$(c$$,16);; HEX$(k$$,16);;; HEX$(asw>>11,1);; HEX$(zsw>>11,1)
'	NEXT x#
'	PRINT
'	RETURN
'
'
' test math library against pentium instructions
'
' test constants
'
'	GOSUB TestFLDZ
'	GOSUB TestFLD1
'	GOSUB TestFLDPI
'	GOSUB TestFLDL2E
'	GOSUB TestFLDL2T
'	GOSUB TestFLDLG2
'	GOSUB TestFLDLN2
'
' test functions
'
'	GOSUB TestF2XM1
'	GOSUB TestFABS
'	GOSUB TestFCHS
'	GOSUB TestFCOS
'	GOSUB TestFPATAN
'	GOSUB TestFPREM
'	GOSUB TestFPREM1
'	GOSUB TestFPTAN
'	GOSUB TestFRNDINT
'	GOSUB TestFSCALE
'	GOSUB TestFSIN
'	GOSUB TestFSINCOS
'	GOSUB TestFSQRT
'	GOSUB TestFXTRACT
'	GOSUB TestFYL2X
'	GOSUB TestFYL2XP1
'
'
'
	RETURN
'
'
'
' *****  test subroutines  *****
'
' 0# vs XxxFLDZ
'
'SUB TestFLDZ
'	a# = 0#
'	b# = XxxFLDZ ()
'	a$$ = GIANTAT(&a#)
'	b$$ = GIANTAT(&b#)
'	PRINT HEX$(a$$,16);; HEX$(b$$,16)
'END SUB
'
' 1# vs XxxFLD1
'
'SUB TestFLD1
'	a# = 1#
'	b# = XxxFLD1 ()
'	a$$ = GIANTAT(&a#)
'	b$$ = GIANTAT(&b#)
'	PRINT HEX$(a$$,16);; HEX$(b$$,16)
'END SUB
'
' $$PI vs XxxFLDPI
'
'SUB TestFLDPI
'	a# = $$PI
'	b# = XxxFLDPI ()
'	a$$ = GIANTAT(&a#)
'	b$$ = GIANTAT(&b#)
'	PRINT HEX$(a$$,16);; HEX$(b$$,16)
'END SUB
'
' $$LOG2E vs XxxFLDL2E
'
'SUB TestFLDL2E
'	a# = $$LOG2E
'	b# = XxxFLDL2E ()
'	a$$ = GIANTAT(&a#)
'	b$$ = GIANTAT(&b#)
'	PRINT HEX$(a$$,16);; HEX$(b$$,16)
'END SUB
'
' $$LOG210 vs XxxFLDL2T
'
'SUB TestFLDL2T
'	a# = $$LOG210
'	b# = XxxFLDL2T ()
'	a$$ = GIANTAT(&a#)
'	b$$ = GIANTAT(&b#)
'	PRINT HEX$(a$$,16);; HEX$(b$$,16)
'END SUB
'
' $$LOG102 vs XxxFLDLG2
'
'SUB TestFLDLG2
'	a# = $$LOG102
'	b# = XxxFLDLG2 ()
'	a$$ = GIANTAT(&a#)
'	b$$ = GIANTAT(&b#)
'	PRINT HEX$(a$$,16);; HEX$(b$$,16)
'END SUB
'
' $$LOGE2 vs XxxFLDLN2
'
'SUB TestFLDLN2
'	a# = $$LOGE2
'	b# = XxxFLDLN2 ()
'	a$$ = GIANTAT(&a#)
'	b$$ = GIANTAT(&b#)
'	PRINT HEX$(a$$,16);; HEX$(b$$,16)
'END SUB
'
' (2# ** x# - 1#) vs XxxF2XM1
'
'SUB TestF2XM1
'	FOR i# = -1# TO +1# STEP 1# / 64#
'		x# = 2# ** i# - 1#
'		y# = XxxF2XM1 (i#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' ABS() vs XxxFABS
'
'SUB TestFABS
'	FOR i# = -$$TWOPI TO $$TWOPI STEP $$TWOPI / 64#
'		x# = ABS (i#)
'		y# = XxxFABS (i#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#/$$PIDIV2);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' - vs XxxFCHS
'
'SUB TestFCHS
'	FOR i# = -$$TWOPI TO $$TWOPI STEP $$TWOPI / 64#
'		x# = -i#
'		y# = XxxFCHS (i#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#/$$PIDIV2);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' COS() vs XxxFCOS
'
'SUB TestFCOS
'	FOR i# = 0 TO $$TWOPI * 2# STEP $$TWOPI / 64#
'		x# = COS (i#)
'		y# = XxxFCOS (i#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#/$$PIDIV2);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' ATAN() vs XxxFPATAN
'
'SUB TestFPATAN
'	FOR i# = 0# TO $$TWOPI * 2# STEP $$TWOPI / 64#
'		x# = ATAN (i#)
'		y# = XxxFPATAN (i#, 1#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#/$$PIDIV2);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' XxxFPREM
'
'SUB TestFPREM
'	FOR i# = 10# TO 14# STEP .5#
'		FOR j# = -2# TO 2# STEP .35#
'			x# = XxxFPREM (i#, j#)
'			y# = XxxFPREM1 (i#, j#)
'			PRINT FORMAT$ ("##.####", i#);; FORMAT$ ("##.####", j#);; FORMAT$ ("##.####", x#);; FORMAT$ ("##.####", y#)
'		NEXT j#
'	NEXT i#
'END SUB
'
' XxxFPREM1
'
'SUB TestFPREM1
'	FOR i# = 10# TO 14# STEP .5#
'		FOR j# = -2# TO 2# STEP .35#
'			x# = XxxFPREM1 (i#, j#)
'			y# = XxxFPREM (i#, j#)
'			PRINT FORMAT$ ("##.####", i#);; FORMAT$ ("##.####", j#);; FORMAT$ ("##.####", x#);; FORMAT$ ("##.####", y#)
'		NEXT j#
'	NEXT i#
'END SUB
'
' TAN() vs XxxFPTAN
'
'SUB TestFPTAN
'	FOR i# = 0 TO $$TWOPI * 2# STEP $$TWOPI / 64#
'		x# = TAN (i#)
'		k# = XxxFPTAN (i#, @j#)
'		y# = k# / j#
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#/$$PIDIV2);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' INT() and FIX() vs XxxFRNDINT
'
'SUB TestFRNDINT
'	FOR i# = -2# TO +2# STEP .25#
'		x# = INT (i#)
'		y# = FIX (i#)
'		z# = XxxFRNDINT (i#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		z$$ = GIANTAT (&z#)
'		PRINT FORMAT$ ("##.####", i#);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(z$$,16);; HEX$(z$$-y$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#);; FORMAT$ ("##.##################", z#)
'		PRINT FORMAT$ ("##.####", i#);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#);; FORMAT$ ("##.##################", z#)
'	NEXT i#
'END SUB
'
' (2# ** i * j#) vs XxxFSCALE
'
'SUB TestFSCALE
'	FOR i# = -2# TO 2# STEP .25#
'		FOR j# = -2# TO 2# STEP .25#
'			x# = 2# ** DOUBLE(FIX(i#)) * j#
'			y# = XxxFSCALE (i#, j#)
'			i$$ = GIANTAT (&i#)
'			x$$ = GIANTAT (&x#)
'			y$$ = GIANTAT (&y#)
'			PRINT FORMAT$ ("##.####", i#);; FORMAT$ ("##.####", j#);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'		NEXT j#
'	NEXT i#
'END SUB
'
' SIN() vs XxxFSIN
'
'SUB TestFSIN
'	FOR i# = 0 TO $$TWOPI * 2# STEP $$TWOPI / 64#
'		x# = SIN (i#)
'		y# = XxxFSIN (i#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#/$$PIDIV2);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' SIN() and COS() vs XxxFSINCOS
'
'SUB TestFSINCOS
'	FOR i# = 0 TO $$TWOPI * 2# STEP $$TWOPI / 64#
'		x# = SIN (i#)
'		xx# = COS (i#)
'		y# = XxxFSINCOS (i#, @z#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		xx$$ = GIANTAT (&xx#)
'		y$$ = GIANTAT (&y#)
'		z$$ = GIANTAT (&z#)
'		PRINT FORMAT$ ("##.####", i#/$$PIDIV2);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(xx$$,16);; HEX$(y$$,16);; HEX$(z$$,16);; HEX$(y$$-x$$,16);; HEX$(z$$-xx$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' SQRT() vs XxxFSQRT
'
'SUB TestFSQRT
'	FOR i# = 0 TO $$TWOPI * 2# STEP $$TWOPI / 64#
'		x# = SQRT (i#)
'		y# = XxxFSQRT (i#)
'		i$$ = GIANTAT (&i#)
'		x$$ = GIANTAT (&x#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#);; HEX$(i$$,16);; HEX$(x$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", x#);; FORMAT$ ("##.##################", y#)
'	NEXT i#
'END SUB
'
' XxxFXTRACT
'
'SUB TestFXTRACT
'	FOR i# = .25# TO 2# STEP 1# / 64#
'		y# = XxxFXTRACT (i#, @j#)
'		i$$ = GIANTAT (&i#)
'		j$$ = GIANTAT (&j#)
'		y$$ = GIANTAT (&y#)
'		PRINT FORMAT$ ("##.####", i#);; HEX$(i$$,16);; HEX$(j$$,16);; HEX$(y$$,16);; FORMAT$ ("##.##################", y#);; FORMAT$ ("##.##################", j#)
'	NEXT i#
'END SUB
'
' XxxFYL2X
'
'SUB TestFYL2X
'	FOR i# = 1# TO 2# STEP .25#
'		FOR j# = 1# TO 2# STEP .25#
'			y# = XxxFYL2X (i#, j#)
'			i$$ = GIANTAT (&i#)
'			j$$ = GIANTAT (&j#)
'			y$$ = GIANTAT (&y#)
'			z$$ = GIANTAT (&z#)
'			PRINT FORMAT$ ("##.####", i#);; FORMAT$ ("##.####", j#);; HEX$(i$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", y#)
'		NEXT j#
'	NEXT i#
'END SUB
'
' XxxFYL2XP1
'
'SUB TestFYL2XP1
'	FOR i# = 1# TO 2# STEP .25#
'		FOR j# = 1# TO 2# STEP .25#
'			y# = XxxFYL2XP1 (i#, j#)
'			i$$ = GIANTAT (&i#)
'			j$$ = GIANTAT (&j#)
'			y$$ = GIANTAT (&y#)
'			z$$ = GIANTAT (&z#)
'			PRINT FORMAT$ ("##.####", i#);; FORMAT$ ("##.####", j#);; HEX$(i$$,16);; HEX$(y$$,16);; HEX$(y$$-x$$,16);; FORMAT$ ("##.##################", y#)
'		NEXT j#
'	NEXT i#
'END SUB
'END FUNCTION
END FUNCTION
'
'
'  ############################
'  #####  XmaVersion$ ()  #####
'  ############################
'
FUNCTION  XmaVersion$ ()
	version$ = VERSION$ (0)
	RETURN (version$)
END FUNCTION
'
'
' #####################
' #####  ACOS ()  #####  arc-cosine
' #####################
'
FUNCTION DOUBLE ACOS (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	SELECT CASE TRUE
		CASE (v < -1#)			: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
		CASE (v > 1#)				: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
		CASE (v = -1#)			: RETURN ($$PI)
		CASE (v =  0#)			: RETURN ($$PIDIV2)
		CASE (v =  1#)			: RETURN (0#)
		CASE ELSE						: RETURN ($$PIDIV2 - ASIN(v))
	END SELECT
END FUNCTION
'
'
' ######################
' #####  ACOSH ()  #####  hyperbolic arc-cosine
' ######################
'
FUNCTION DOUBLE ACOSH (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
  SELECT CASE TRUE
	  CASE (v < 1#)			: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
    CASE (v > 1d20)		: RETURN (LOG(2#*v))
		CASE ELSE					: RETURN (LOG(v + SQRT(v*v - 1#)))
  END SELECT
END FUNCTION
'
'
' #####################
' #####  ACOT ()  #####  arc-cotangent
' #####################
'
FUNCTION DOUBLE ACOT (DOUBLE v) DOUBLE
  IF (v > 1#) THEN RETURN (ATAN(1#/v))
 	RETURN ($$PIDIV2 - ATAN(v))
END FUNCTION
'
'
' ######################
' #####  ACOTH ()  #####  hyperbolic arc-cotangent
' ######################
'
FUNCTION DOUBLE ACOTH (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	SELECT CASE TRUE
		CASE (ABS(v) > 1#)	: RETURN (ATANH(1#/v))
		CASE ELSE				: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
	END SELECT
END FUNCTION
'
'
' #####################
' #####  ACSC ()  #####  arc-cosecant
' #####################
'
FUNCTION DOUBLE ACSC (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
  SELECT CASE TRUE
		CASE (ABS(v) < 1#)	: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
		CASE ELSE:					: RETURN (ASIN(1#/v))
  END SELECT
END FUNCTION
'
'
' ######################
' #####  ACSCH ()  #####  hyperbolic arc-cosecant
' ######################
'
FUNCTION DOUBLE ACSCH (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	SELECT CASE TRUE
		CASE (v = 0#)	: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
		CASE ELSE			: RETURN (ASINH(1#/v))
	END SELECT
END FUNCTION
'
'
' #####################
' #####  ASEC ()  #####  arc-secant
' #####################
'
FUNCTION DOUBLE ASEC (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	IF (ABS(v) < 1#) THEN ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
	RETURN ($$PIDIV2 - ASIN(1#/v))
END FUNCTION
'
'
' ######################
' #####  ASECH ()  #####  hyperbolic arc-secant
' ######################
'
FUNCTION DOUBLE ASECH (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	SELECT CASE TRUE
		CASE (v <= 0#)		: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
		CASE (v > 1#)			: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
		CASE ELSE					: RETURN (ACOSH(1#/v))
	END SELECT
END FUNCTION
'
'
' #####################
' #####  ASIN ()  #####  arc-sine
' #####################
'
'   Returns values between -PI/2 and +PI/2 inclusive
'
FUNCTION DOUBLE ASIN (DOUBLE a) DOUBLE
	XLONG	##ERROR
'
	SELECT CASE TRUE
		CASE (ABS(a) > 1#)		: ##ERROR = $$ErrorNatureInvalidArgument: RETURN ($$PNAN)
		CASE (ABS(a) < 1d-5)		: RETURN (a*(1#+a*a/6#))
		CASE (a > 0#)		: theSign = +1#
		CASE ELSE				: theSign = -1# : a = -a
	END SELECT
'
	IF (a <= $$INVSQRT2) THEN									' a <= sin(45)
		aa = a * a
		x = a * Asin0 (aa)
	ELSE
		aa = (.5# - (a * .5#))                  ' aa = COS(ASIN(a/2))**2
		a = SQRT (aa)
		x = $$PIDIV2 - (2# * a * Asin0 (aa))		' x = 90 - 2 arcsin(a)
	END IF
	RETURN (x * theSign)
END FUNCTION
'
'
' ######################
' #####  ASINH ()  #####  hyperbolic arc-sine
' ######################
'
FUNCTION DOUBLE ASINH (DOUBLE v) DOUBLE
'
  x = ABS(v)
  SELECT CASE TRUE
    CASE (v == 0#)    : RETURN 0#
    CASE (x < 1d-4#)  : RETURN (v * (1# - v * v /6#))
    CASE (x > 1d8#)   : RETURN (SIGN(v) * LOG(2# * x + 0.5# / x))
    CASE ELSE         : RETURN (SIGN(v) * LOG(x + SQRT(x * x + 1#)))
  END SELECT
END FUNCTION
'
'
' #####################
' #####  ATAN ()  #####  arc-tangent
' #####################
'
'   Hart #5034
'
'FUNCTION DOUBLE ATAN (DOUBLE v) DOUBLE
'	STATIC first, w1, x1 , y1, w2, x2, y2, w3, x3, y3, w4, x4, y4
'
' FPU routine
'
'	RETURN (XxxFPATAN(v,1#))
'
' hand coded routine
'
'	IFZ first THEN GOSUB InitVars
'
' Handle sign of value and result
'
'	SELECT CASE TRUE
'		CASE (v > 0#)	: theSign = +1#
'		CASE (v = 0#)	: RETURN (0#)
'		CASE ELSE			: theSign = -1# : v = -v
'	END SELECT
'
' Different routines for different sub-quadrants
'
'	SELECT CASE TRUE
'		CASE (v < .19891236737965800691#)		: RETURN (Atan0(v) * theSign)		' <  tan(pi/16)
'		CASE (v < .66817863791929892000#)		: w = w1: x = x1: y = y1				' <  tan(3pi/16)
'		CASE (v < .14966057626654890176d1)	: w = w2: x = x2: y = y2				' <  tan(5pi/16)
'		CASE (v < .50273394921258481045d1)	: w = w3: x = x3: y = y3				' <  tan(7pi/16)
'		CASE ELSE														: w = w4:	x = x4: y = y4				' <= tan(8pi/16)
'	END SELECT
'
'	t = x - (y / (x + v))
'	RETURN ((Atan0(t) + w) * theSign)
'
'
' *****  Initialize some variables  *****
'
'SUB InitVars
'	j#	= TAN ($$PIDIV8)							' *****  22.50 degrees  *****
'	w1	= $$PIDIV8
'	x1	= 1 / j#
'	y1	= 1 + (1 / (j# * j#))
'
'	w2	= $$PIDIV4										' *****  45.00 degrees  *****
'	x2	= 1#
'	y2	= 2#
'
'	j#	= TAN ($$PI3DIV8)							' *****  67.50 degrees  *****
'	w3	= $$PI3DIV8
'	x3	= 1 / j#
'	y3	= 1 + (1 / (j# * j#))
'
'	w4 	= $$PIDIV2										' *****  90.00 degrees  *****
'	x4	= 0
'	y4	= 1
'	first = $$TRUE
'END SUB
'END FUNCTION
'
'
' ######################
' #####  ATANH ()  #####  hyperbolic arc-tangent
' ######################
'
FUNCTION DOUBLE ATANH (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	SELECT CASE TRUE
		CASE (ABS(v) < 1d-5)		: RETURN (v*(1#+v*v/3#))
    CASE (ABS(v) < 1#)      : RETURN (LOG((1# + v) / (1# - v)) * 0.5#)
		CASE ELSE								: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
	END SELECT
END FUNCTION
'
'
' ####################
' #####  COS ()  #####  cosine
' ####################
'
'   Hart #3823
'
'FUNCTION DOUBLE COS (DOUBLE a) DOUBLE
'
' FPU routine
'
'	RETURN (XxxFCOS(a))
'
' hand coded routine
'
'	IF (a < -$$TWOPI) THEN					' more negative than -360 degrees
'		r# = a / $$TWOPI							' r# = angle / 360 degrees
'		i# = FIX (r#)									' i# = integer part of r#
'		j# = (r# - i#)								' j# = 0 to 1 (units of $$TWOPI)
'		j# = j# + 1#									' j# = ditto
'		a = j# * $$TWOPI							' a  = 0 to -$$TWOPI
'	END IF
'	IF (a < 0) THEN a = a + $$TWOPI	' a  = 0 to $$TWOPI = 0 to 360 degrees
'
'	IF (a > $$TWOPI) THEN						' more positive than +360 degrees
'		r# = a / $$TWOPI							' r# = angle / 360 degrees
'		i# = FIX (r#)									' i# = integer part of r#
'		a = (r# - i#)									' a  = 0 to 1 (units of $$TWOPI)
'		a = a * $$TWOPI								' a  = 0 to $$TWOPI
'	END IF
'
'	fold into 0-90 with appropriate sign
'
'	SELECT CASE TRUE
'		CASE (a <= $$PIDIV2)	: theSign = +1#
'		CASE (a <= $$PI)			: theSign = -1#	: a = $$PI - a
'		CASE (a <= $$PI3DIV2)	: theSign = -1#	: a = a - $$PI
'		CASE ELSE							: theSign = +1#	: a = $$TWOPI - a
'	END SELECT
'
'	IF (a > $$PIDIV4) THEN
'		x = SIN ($$PIDIV2 - a)						' sin if a > 45
'	ELSE
'	  a = a / $$PIDIV4
'	  aa = a * a
'	  x = aa * -.38577620372d-12 + .11500497024263d-9
'		x = x * aa - .2461136382637005d-7
'	  x = x * aa + .359086044588581953d-5
'	  x = x * aa - .32599188692668755044d-3
'	  x = x * aa + .1585434424381541089754d-1
'	  x = x * aa - .30842513753404245242414
'	  x = x * aa + .99999999999999999996415
'	END IF
'	RETURN (x * theSign)
'END FUNCTION
'
'
' #####################
' #####  COSH ()  #####  hyperbolic cosine
' #####################
'
FUNCTION DOUBLE COSH (DOUBLE v) DOUBLE
'
	SELECT CASE TRUE
		CASE (v = 0#)			: RETURN (1#)
		CASE (v >= 19#)		: RETURN (EXP(v) * 0.5#)
		CASE (v <= -19#)	: RETURN (EXP(-v) * 0.5#)
		CASE ELSE					: RETURN ((EXP(v) + EXP(-v)) * 0.5#)
	END SELECT
END FUNCTION
'
'
' ####################
' #####  COT ()  #####  cotangent
' ####################
'
'   Hart #4287 inverted
'
FUNCTION DOUBLE COT (DOUBLE a) DOUBLE
'
' FPU routine
'
	k# = XxxFPTAN (a, @j#)
	RETURN (j# / k#)
'
' hand coded routine
'
'	fold into 0 - 360
'
'	DO WHILE (a < 0#)
'		a = a + $$TWOPI
'	LOOP
'	DO WHILE (a >= $$TWOPI)
'		a = a - $$TWOPI
'	LOOP
'
'	fold into 0-90 with appropriate sign
'
'	SELECT CASE TRUE
'		CASE (a <= $$PIDIV2)	: theSign = +1#
'		CASE (a <= $$PI)			: theSign = -1# :	a = $$PI - a
'		CASE (a <= $$PI3DIV2)	: theSign = +1# :	a = a - $$PI
'		CASE ELSE							: theSign = -1# :	a = $$TWOPI - a
'	END SELECT
'
'	IF (a = 0#) THEN RETURN ($$PINF)
'
'	a = a / $$PIDIV4
'	aa = a * a
'	x = aa * .1751083054422421995601107123d-1 - .279527948722905226792457575d2
'	x = x * aa + .6171941889092866899718078509d4
'	x = x * aa - .3498924461690337314553322577d6
'	x = x * aa + .413160917052212537541564775d7
'	y = aa - .4976002053470988434868766867d3				' was aa * 1# - 497.xxxxx
'	y = y * aa + .5497880219885277215781502314d5
'	y = y * aa - .1527149650334576959585193088d7
'	y = y * aa + .5260528179299214050832459853d7
'	RETURN (y / (a * x)) * theSign
END FUNCTION
'
'
' #####################
' #####  COTH ()  #####  hyperbolic cotangent
' #####################
'
FUNCTION DOUBLE COTH (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	SELECT CASE TRUE
		CASE (v = 0#)					: ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
    CASE (ABS(v) < 1d-4)	: RETURN (1#/v+v/3#)
		CASE (v >= 19#)				: RETURN (1#)
		CASE (v <= -19#)			: RETURN (-1#)
		CASE ELSE							: RETURN ((EXP(v)+EXP(-v))/(EXP(v)-EXP(-v)))
	END SELECT
END FUNCTION
'
'
' ####################
' #####  CSC ()  #####  cosecant
' ####################
'
'   1 / SIN()
'
FUNCTION DOUBLE CSC (DOUBLE a)
'
	x# = SIN(a)
	IFZ x# THEN
		RETURN ($$PINF)
	ELSE
		RETURN (1# / x#)
	END IF
END FUNCTION
'
'
' #####################
' #####  CSCH ()  #####  hyperbolic cosecant
' #####################
'
FUNCTION DOUBLE CSCH (DOUBLE v) DOUBLE
	XLONG	##ERROR
'
	IFZ v THEN ##ERROR = $$ErrorNatureInvalidArgument : RETURN ($$PNAN)
	RETURN (1# / SINH(v))
END FUNCTION
'
'
' ####################
' #####  EXP ()  #####  base e "anti-log" (e to the x)
' ####################
'
'FUNCTION  DOUBLE  EXP (DOUBLE x) DOUBLE
'	SLONG i, j, k, exp
'	XLONG	##ERROR
'
' FPU routine
'
'	IFZ x THEN RETURN (1#)
'
'	IF (x < 0) THEN
'		neg = $$TRUE
'		x = -x
'	ELSE
'		neg = $$FALSE
'	END IF
'	y		= x * $$LOG2E						' y  = x * log2(e)
'	i		= FIX (y)								' i  = INT (y)
'	i#	= i											' i# = INTpart of y
'	z		= y - i#								' z  = FRACpart of y
'	IF (z <= .5#) THEN
'		r = Exp0 (z)
'	ELSE
'		r = Exp0 (z - .5#)
'		r = r * $$SQRT2
'	END IF
'	j		= DHIGH (r)
'	k		= DLOW (r)
'	exp	= j {11, 20}
'	exp = exp - 1023 + i
'	exp = exp + 1023
'
'	IF (exp < 0) THEN
'		##ERROR = $$ErrorNatureOverflow
'		IF neg THEN
'			RETURN ($$PINF)
'		ELSE
'			RETURN (0#)
'		END IF
'	END IF
'	IF (exp > 2047)
'		##ERROR = $$ErrorNatureOverflow
'		IF neg THEN
'			RETURN (0#)
'		ELSE
'			RETURN ($$PINF)
'		END IF
'	END IF
'
'	j = j AND 0x800FFFFF
'	j = j OR (exp << 20)
'	r = DMAKE (j, k)
'	IF neg THEN
'		RETURN (1/r)
'	ELSE
'		RETURN (r)
'	END IF
'END FUNCTION
'
'
' ####################
' #####  LOG ()  #####  base e logorithm (natural log)
' ####################
'
FUNCTION DOUBLE LOG (DOUBLE v) DOUBLE
	SLONG  upper,  lower,  exp,  exp0,  exp1,  exp2
	XLONG  ##ERROR
'
	K1 = DMAKE (0xBF2BD010, 0x5C610CA9)
	K2 = SMAKE (0x3F318000)
'
	SELECT CASE TRUE
		CASE (v < 0#)	: ##ERROR = $$ErrorNatureInvalidArgument: RETURN ($$PNAN)
		CASE (v = 0#)	: RETURN ($$NINF)
		CASE (v = 1#)	: RETURN (0#)
	END SELECT
'
	upper	= DHIGH (v)
	lower	= DLOW (v)
	exp		= upper {11, 20}
	exp0	= upper AND 0x800FFFFF
	exp1	= exp0 OR 0x3FE00000
	exp2	= exp - 1022
	frac	= DMAKE (exp1, lower)						' frac is between 1/2 and 1
	IF (frac >= $$INVSQRT2) THEN					' frac must be between 1/sqrt2 and sqrt2
		z = (frac - 1#) / (frac + 1#)				' it is!
	ELSE
		DEC exp2														' nope: dec the exponent, transfer to frac
		z = (frac - .5#) / (frac + .5#)			' mult frac by 2 (clever...)
	END IF
	zp = z * Log0 (z)
	j = ((exp2 * K1) + zp) + (exp2 * K2)
'	j = exp2 * $$LOGE2 + zp
	RETURN (j)
END FUNCTION
'
'
' ######################
' #####  EXP10 ()  #####  base 10 "anti-log" (10 to the x)
' ######################
'
'FUNCTION DOUBLE EXP10 (DOUBLE v) DOUBLE
'	RETURN (POWER(10#,v))
'END FUNCTION
'
'
' ######################
' #####  LOG10 ()  #####  base 10 logorithm
' ######################
'
FUNCTION DOUBLE LOG10 (DOUBLE v) DOUBLE
	RETURN (LOG (v) * $$LOG10E)
END FUNCTION
'
'
' ######################
' #####  POWER ()  #####  power (x to the y)
' ######################
'
'FUNCTION DOUBLE POWER (DOUBLE x, DOUBLE y) DOUBLE
'	XLONG  ##ERROR
'
'	SELECT CASE TRUE
'		CASE (y = 1#)											: RETURN (x)
'		CASE ((x = 0#) AND (y <= 0#))			: ##ERROR = $$ErrorNatureInvalidArgument : RETURN (0#)
'		CASE (x = 0#)											: RETURN (0#)
'		CASE (y = 0#)											: RETURN (1#)
'		CASE ((x < 0#) AND (FIX(y) != y))	: ##ERROR = $$ErrorNatureInvalidArgument : RETURN (0#)
'		CASE ELSE													: RETURN (EXP(y * LOG(x)))
'	END SELECT
'END FUNCTION
'
'
' ####################
' #####  SEC ()  #####  secant
' ####################
'
'  1 / COS()
'
FUNCTION DOUBLE SEC (DOUBLE a) DOUBLE
'
	x = COS(a)
	IFZ x THEN
		RETURN ($$PINF)
	ELSE
  	RETURN (1# / x)
	END IF
END FUNCTION
'
'
' #####################
' #####  SECH ()  #####  hyperbolic secant
' #####################
'
FUNCTION DOUBLE SECH (DOUBLE v) DOUBLE
	RETURN (1# / COSH(v))
END FUNCTION
'
'
' ####################
' #####  SIN ()  #####  sine
' ####################
'
' Hart #3043
'
'FUNCTION DOUBLE SIN (DOUBLE a) DOUBLE
'
' FPU routine
'
'	RETURN (XxxFSIN(a))
'
' hand coded routine
'
'	IF (a < -$$TWOPI) THEN					' more negative than -360 degrees
'		r# = a / $$TWOPI							' r# = angle / 360 degrees
'		i# = FIX (r#)									' i# = integer part of r#
'		j# = (r# - i#)								' j# = 0 to 1 (units of $$TWOPI)
'		j# = j# + 1#									' j# = ditto
'		a = j# * $$TWOPI							' a  = 0 to -$$TWOPI
'	END IF
'	IF (a < 0) THEN a = a + $$TWOPI	' a  = 0 to $$TWOPI = 0 to 360 degrees
'
'	IF (a > $$TWOPI) THEN						' more positive than +360 degrees
'		r# = a / $$TWOPI							' r# = angle / 360 degrees
'		i# = FIX (r#)									' i# = integer part of r#
'		a = (r# - i#)									' a  = 0 to 1 (units of $$TWOPI)
'		a = a * $$TWOPI								' a  = 0 to $$TWOPI
'	END IF
'
'	fold into 0 - 90 with appropriate sign
'
'	SELECT CASE TRUE
'		CASE (a <= $$PIDIV2):		theSign = +1#
'		CASE (a <= $$PI):				theSign = +1#:	a = $$PI - a
'		CASE (a <= $$PI3DIV2):	theSign = -1#:	a = a - $$PI
'		CASE ELSE:							theSign = -1#:	a = $$TWOPI - a
'	END SELECT
'
'	IF (a > $$PIDIV4) THEN
'		x = COS ($$PIDIV2 - a)									' cos if a > 45
'	ELSE
'	  a = a / $$PIDIV4
'	  aa = a * a
'		x = aa * .6877100349d-11 - .1757149292755d-8
'		x = x * aa + .313361621661904d-6
'		x = x * aa - .36576204158455695d-4
'		x = x * aa + .2490394570188736117d-2
'		x = x * aa - .80745512188280530192d-1
'		x = x * aa + .785398163397448307014#
'		x = x * a
'	END IF
'	RETURN (x * theSign)
'END FUNCTION
'
'
' #####################
' #####  SINH ()  #####  hyperbolic sine
' #####################
'
FUNCTION DOUBLE SINH (DOUBLE v) DOUBLE
'  >>>  may need add'l stuff for exp(v) ~= exp(-v)
	SELECT CASE TRUE
		CASE (v = 0#)			: RETURN (0#)
		CASE (v >= 19#)   : RETURN (EXP(v) * 0.5#)
		CASE (v <= -19#)	: RETURN (EXP(-v) * -0.5#)
		CASE (v > .3#)		: RETURN ((EXP(v) - EXP(-v)) * 0.5#)
		CASE (v < -.3#)		: RETURN ((EXP(v) - EXP(-v)) * 0.5#)
		CASE ELSE					: dx = Expmo(v)
												RETURN (0.5# * dx*(1# + 1# / (dx + 1)))
	END SELECT
END FUNCTION
'
'
' #####################
' #####  SQRT ()  #####  square root
' #####################
'
'  Newton-Raphson Iteration
'
'FUNCTION DOUBLE SQRT (DOUBLE v) DOUBLE
'	XLONG i, j, exp, exp0, exp1, exp2, xfrac, too
'	STATIC XLONG sqrt_table_odd[]
'	STATIC XLONG sqrt_table_even[]
'	XLONG  ##ERROR,  ##WHOMASK
'
'	IFZ v THEN RETURN (0#)
'	IF (v < 0#) THEN ##ERROR = $$ErrorNatureInvalidArgument : RETURN (0#)
'
' FPU routine
'
'	RETURN (XxxFSQRT(v))
'
' hand coded routine
'
'	IFZ sqrt_table_odd[] THEN GOSUB FillEstimateArrays
'
'	exp0 = DHIGH(v)
'	exp1 = exp0{11, 20}
'	exp2 = exp1 - 1022
'	xfrac = exp0{8, 12}
'	IF (xfrac < 0) THEN PRINT "SQRT(): Error: (xfrac < 0)  "; xfrac : RETURN (0#)
'	IF (xfrac > 255) THEN PRINT "SQRT(): Error: (xfrac > 255)  "; xfrac : RETURN (0#)
'	IFZ exp2{1, 0} THEN
'		exp = (exp2 >>> 1) + 1022
'		exp = MAKE (exp, 20)
'		too = sqrt_table_even[xfrac]
'		exp = exp + too
'		e		= DMAKE (exp, 0)
'	ELSE
'		exp = (exp2 >>> 1) + 1023
'		exp = MAKE (exp, 20)
'		too = sqrt_table_odd[xfrac]
'		exp = exp + too
'		e		= DMAKE (exp, 0)
'	END IF
'	PRINT v; TAB (22); HEX$(DHIGH(v), 8);; HEX$(DLOW(v), 8); TAB (40); e; TAB (62); HEX$(DHIGH(e), 8);; HEX$(DLOW(e), 8)
'	FOR i = 0 TO 15
'		t = .5# * ((v / e) + e)
''		PRINT e; TAB (22); HEX$(DHIGH(e), 8);; HEX$(DLOW(e), 8); TAB (40); t; TAB (62); HEX$(DHIGH(t), 8);; HEX$(DLOW(t), 8)
'		IF (e = t) THEN EXIT FOR
'		e = t
'	NEXT i
'	RETURN (e)
'
' fill arrays that give starting estimate of sqrt(x) where exponent is odd/even
'
'SUB FillEstimateArrays
'	hold = ##WHOMASK
'	##WHOMASK = 0
'	DIM sqrt_table_odd[255]
'	DIM sqrt_table_even[255]
'	##WHOMASK = hold
'	sqrt_table_odd[0x00] 	= 0x00000000
'	sqrt_table_odd[0x01] 	= 0x000007FE
'	sqrt_table_odd[0x02] 	= 0x00000FF8
'	sqrt_table_odd[0x03] 	= 0x000017EE
'	sqrt_table_odd[0x04] 	= 0x00001FE0
'	sqrt_table_odd[0x05] 	= 0x000027CE
'	sqrt_table_odd[0x06] 	= 0x00002FB8
'	sqrt_table_odd[0x07] 	= 0x0000379F
'	sqrt_table_odd[0x08] 	= 0x00003F81
'	sqrt_table_odd[0x09] 	= 0x00004760
'	sqrt_table_odd[0x0A] 	= 0x00004F3B
'	sqrt_table_odd[0x0B] 	= 0x00005713
'	sqrt_table_odd[0x0C] 	= 0x00005EE6
'	sqrt_table_odd[0x0D] 	= 0x000066B6
'	sqrt_table_odd[0x0E] 	= 0x00006E82
'	sqrt_table_odd[0x0F] 	= 0x0000764A
'	sqrt_table_odd[0x10] 	= 0x00007E0F
'	sqrt_table_odd[0x11] 	= 0x000085D0
'	sqrt_table_odd[0x12] 	= 0x00008D8D
'	sqrt_table_odd[0x13] 	= 0x00009547
'	sqrt_table_odd[0x14] 	= 0x00009CFD
'	sqrt_table_odd[0x15] 	= 0x0000A4B0
'	sqrt_table_odd[0x16] 	= 0x0000AC5F
'	sqrt_table_odd[0x17] 	= 0x0000B40B
'	sqrt_table_odd[0x18] 	= 0x0000BBB3
'	sqrt_table_odd[0x19] 	= 0x0000C357
'	sqrt_table_odd[0x1A] 	= 0x0000CAF8
'	sqrt_table_odd[0x1B] 	= 0x0000D296
'	sqrt_table_odd[0x1C] 	= 0x0000DA30
'	sqrt_table_odd[0x1D] 	= 0x0000E1C7
'	sqrt_table_odd[0x1E] 	= 0x0000E95A
'	sqrt_table_odd[0x1F] 	= 0x0000F0EA
'	sqrt_table_odd[0x20] 	= 0x0000F876
'	sqrt_table_odd[0x21] 	= 0x00010000
'	sqrt_table_odd[0x22] 	= 0x00010785
'	sqrt_table_odd[0x23] 	= 0x00010F08
'	sqrt_table_odd[0x24] 	= 0x00011687
'	sqrt_table_odd[0x25] 	= 0x00011E03
'	sqrt_table_odd[0x26] 	= 0x0001257C
'	sqrt_table_odd[0x27] 	= 0x00012CF1
'	sqrt_table_odd[0x28] 	= 0x00013463
'	sqrt_table_odd[0x29] 	= 0x00013BD2
'	sqrt_table_odd[0x2A] 	= 0x0001433E
'	sqrt_table_odd[0x2B] 	= 0x00014AA7
'	sqrt_table_odd[0x2C] 	= 0x0001520C
'	sqrt_table_odd[0x2D] 	= 0x0001596F
'	sqrt_table_odd[0x2E] 	= 0x000160CE
'	sqrt_table_odd[0x2F] 	= 0x0001682A
'	sqrt_table_odd[0x30] 	= 0x00016F83
'	sqrt_table_odd[0x31] 	= 0x000176D9
'	sqrt_table_odd[0x32] 	= 0x00017E2B
'	sqrt_table_odd[0x33] 	= 0x0001857B
'	sqrt_table_odd[0x34] 	= 0x00018CC8
'	sqrt_table_odd[0x35] 	= 0x00019411
'	sqrt_table_odd[0x36] 	= 0x00019B58
'	sqrt_table_odd[0x37] 	= 0x0001A29B
'	sqrt_table_odd[0x38] 	= 0x0001A9DC
'	sqrt_table_odd[0x39] 	= 0x0001B11A
'	sqrt_table_odd[0x3A] 	= 0x0001B854
'	sqrt_table_odd[0x3B] 	= 0x0001BF8C
'	sqrt_table_odd[0x3C] 	= 0x0001C6C1
'	sqrt_table_odd[0x3D] 	= 0x0001CDF3
'	sqrt_table_odd[0x3E] 	= 0x0001D522
'	sqrt_table_odd[0x3F] 	= 0x0001DC4E
'	sqrt_table_odd[0x40] 	= 0x0001E377
'	sqrt_table_odd[0x41] 	= 0x0001EA9D
'	sqrt_table_odd[0x42] 	= 0x0001F1C1
'	sqrt_table_odd[0x43] 	= 0x0001F8E2
'	sqrt_table_odd[0x44] 	= 0x00020000
'	sqrt_table_odd[0x45] 	= 0x0002071B
'	sqrt_table_odd[0x46] 	= 0x00020E33
'	sqrt_table_odd[0x47] 	= 0x00021548
'	sqrt_table_odd[0x48] 	= 0x00021C5B
'	sqrt_table_odd[0x49] 	= 0x0002236B
'	sqrt_table_odd[0x4A] 	= 0x00022A78
'	sqrt_table_odd[0x4B] 	= 0x00023183
'	sqrt_table_odd[0x4C] 	= 0x0002388A
'	sqrt_table_odd[0x4D] 	= 0x00023F8F
'	sqrt_table_odd[0x4E] 	= 0x00024692
'	sqrt_table_odd[0x4F] 	= 0x00024D91
'	sqrt_table_odd[0x50] 	= 0x0002548E
'	sqrt_table_odd[0x51] 	= 0x00025B89
'	sqrt_table_odd[0x52] 	= 0x00026280
'	sqrt_table_odd[0x53] 	= 0x00026975
'	sqrt_table_odd[0x54] 	= 0x00027068
'	sqrt_table_odd[0x55] 	= 0x00027757
'	sqrt_table_odd[0x56] 	= 0x00027E45
'	sqrt_table_odd[0x57] 	= 0x0002852F
'	sqrt_table_odd[0x58] 	= 0x00028C17
'	sqrt_table_odd[0x59] 	= 0x000292FD
'	sqrt_table_odd[0x5A] 	= 0x000299E0
'	sqrt_table_odd[0x5B] 	= 0x0002A0C0
'	sqrt_table_odd[0x5C] 	= 0x0002A79E
'	sqrt_table_odd[0x5D] 	= 0x0002AE79
'	sqrt_table_odd[0x5E] 	= 0x0002B552
'	sqrt_table_odd[0x5F] 	= 0x0002BC28
'	sqrt_table_odd[0x60] 	= 0x0002C2FC
'	sqrt_table_odd[0x61] 	= 0x0002C9CD
'	sqrt_table_odd[0x62] 	= 0x0002D09C
'	sqrt_table_odd[0x63] 	= 0x0002D768
'	sqrt_table_odd[0x64] 	= 0x0002DE32
'	sqrt_table_odd[0x65] 	= 0x0002E4FA
'	sqrt_table_odd[0x66] 	= 0x0002EBBF
'	sqrt_table_odd[0x67] 	= 0x0002F281
'	sqrt_table_odd[0x68] 	= 0x0002F942
'	sqrt_table_odd[0x69] 	= 0x00030000
'	sqrt_table_odd[0x6A] 	= 0x000306BB
'	sqrt_table_odd[0x6B] 	= 0x00030D74
'	sqrt_table_odd[0x6C] 	= 0x0003142B
'	sqrt_table_odd[0x6D] 	= 0x00031ADF
'	sqrt_table_odd[0x6E] 	= 0x00032191
'	sqrt_table_odd[0x6F] 	= 0x00032841
'	sqrt_table_odd[0x70] 	= 0x00032EEE
'	sqrt_table_odd[0x71] 	= 0x00033599
'	sqrt_table_odd[0x72] 	= 0x00033C42
'	sqrt_table_odd[0x73] 	= 0x000342E8
'	sqrt_table_odd[0x74] 	= 0x0003498C
'	sqrt_table_odd[0x75] 	= 0x0003502E
'	sqrt_table_odd[0x76] 	= 0x000356CD
'	sqrt_table_odd[0x77] 	= 0x00035D6B
'	sqrt_table_odd[0x78] 	= 0x00036406
'	sqrt_table_odd[0x79] 	= 0x00036A9E
'	sqrt_table_odd[0x7A] 	= 0x00037135
'	sqrt_table_odd[0x7B] 	= 0x000377C9
'	sqrt_table_odd[0x7C] 	= 0x00037E5B
'	sqrt_table_odd[0x7D] 	= 0x000384EB
'	sqrt_table_odd[0x7E] 	= 0x00038B79
'	sqrt_table_odd[0x7F] 	= 0x00039204
'	sqrt_table_odd[0x80] 	= 0x0003988E
'	sqrt_table_odd[0x81] 	= 0x00039F15
'	sqrt_table_odd[0x82] 	= 0x0003A59A
'	sqrt_table_odd[0x83] 	= 0x0003AC1C
'	sqrt_table_odd[0x84] 	= 0x0003B29D
'	sqrt_table_odd[0x85] 	= 0x0003B91B
'	sqrt_table_odd[0x86] 	= 0x0003BF98
'	sqrt_table_odd[0x87] 	= 0x0003C612
'	sqrt_table_odd[0x88] 	= 0x0003CC8A
'	sqrt_table_odd[0x89] 	= 0x0003D300
'	sqrt_table_odd[0x8A] 	= 0x0003D974
'	sqrt_table_odd[0x8B] 	= 0x0003DFE6
'	sqrt_table_odd[0x8C] 	= 0x0003E655
'	sqrt_table_odd[0x8D] 	= 0x0003ECC3
'	sqrt_table_odd[0x8E] 	= 0x0003F32F
'	sqrt_table_odd[0x8F] 	= 0x0003F998
'	sqrt_table_odd[0x90] 	= 0x00040000
'	sqrt_table_odd[0x91] 	= 0x00040665
'	sqrt_table_odd[0x92] 	= 0x00040CC8
'	sqrt_table_odd[0x93] 	= 0x0004132A
'	sqrt_table_odd[0x94] 	= 0x00041989
'	sqrt_table_odd[0x95] 	= 0x00041FE6
'	sqrt_table_odd[0x96] 	= 0x00042641
'	sqrt_table_odd[0x97] 	= 0x00042C9B
'	sqrt_table_odd[0x98] 	= 0x000432F2
'	sqrt_table_odd[0x99] 	= 0x00043947
'	sqrt_table_odd[0x9A] 	= 0x00043F9A
'	sqrt_table_odd[0x9B] 	= 0x000445EC
'	sqrt_table_odd[0x9C] 	= 0x00044C3B
'	sqrt_table_odd[0x9D] 	= 0x00045288
'	sqrt_table_odd[0x9E] 	= 0x000458D4
'	sqrt_table_odd[0x9F] 	= 0x00045F1D
'	sqrt_table_odd[0xA0] 	= 0x00046565
'	sqrt_table_odd[0xA1] 	= 0x00046BAA
'	sqrt_table_odd[0xA2] 	= 0x000471EE
'	sqrt_table_odd[0xA3] 	= 0x00047830
'	sqrt_table_odd[0xA4] 	= 0x00047E70
'	sqrt_table_odd[0xA5] 	= 0x000484AE
'	sqrt_table_odd[0xA6] 	= 0x00048AEA
'	sqrt_table_odd[0xA7] 	= 0x00049124
'	sqrt_table_odd[0xA8] 	= 0x0004975C
'	sqrt_table_odd[0xA9] 	= 0x00049D93
'	sqrt_table_odd[0xAA] 	= 0x0004A3C7
'	sqrt_table_odd[0xAB] 	= 0x0004A9FA
'	sqrt_table_odd[0xAC] 	= 0x0004B02B
'	sqrt_table_odd[0xAD] 	= 0x0004B65A
'	sqrt_table_odd[0xAE] 	= 0x0004BC87
'	sqrt_table_odd[0xAF] 	= 0x0004C2B2
'	sqrt_table_odd[0xB0] 	= 0x0004C8DC
'	sqrt_table_odd[0xB1] 	= 0x0004CF03
'	sqrt_table_odd[0xB2] 	= 0x0004D529
'	sqrt_table_odd[0xB3] 	= 0x0004DB4D
'	sqrt_table_odd[0xB4] 	= 0x0004E16F
'	sqrt_table_odd[0xB5] 	= 0x0004E790
'	sqrt_table_odd[0xB6] 	= 0x0004EDAE
'	sqrt_table_odd[0xB7] 	= 0x0004F3CB
'	sqrt_table_odd[0xB8] 	= 0x0004F9E6
'	sqrt_table_odd[0xB9] 	= 0x00050000
'	sqrt_table_odd[0xBA] 	= 0x00050617
'	sqrt_table_odd[0xBB] 	= 0x00050C2D
'	sqrt_table_odd[0xBC] 	= 0x00051241
'	sqrt_table_odd[0xBD] 	= 0x00051853
'	sqrt_table_odd[0xBE] 	= 0x00051E63
'	sqrt_table_odd[0xBF] 	= 0x00052472
'	sqrt_table_odd[0xC0] 	= 0x00052A7F
'	sqrt_table_odd[0xC1] 	= 0x0005308A
'	sqrt_table_odd[0xC2] 	= 0x00053694
'	sqrt_table_odd[0xC3] 	= 0x00053C9C
'	sqrt_table_odd[0xC4] 	= 0x000542A2
'	sqrt_table_odd[0xC5] 	= 0x000548A6
'	sqrt_table_odd[0xC6] 	= 0x00054EA9
'	sqrt_table_odd[0xC7] 	= 0x000554AA
'	sqrt_table_odd[0xC8] 	= 0x00055AAA
'	sqrt_table_odd[0xC9] 	= 0x000560A7
'	sqrt_table_odd[0xCA] 	= 0x000566A3
'	sqrt_table_odd[0xCB] 	= 0x00056C9D
'	sqrt_table_odd[0xCC] 	= 0x00057296
'	sqrt_table_odd[0xCD] 	= 0x0005788D
'	sqrt_table_odd[0xCE] 	= 0x00057E82
'	sqrt_table_odd[0xCF] 	= 0x00058476
'	sqrt_table_odd[0xD0] 	= 0x00058A68
'	sqrt_table_odd[0xD1] 	= 0x00059059
'	sqrt_table_odd[0xD2] 	= 0x00059647
'	sqrt_table_odd[0xD3] 	= 0x00059C34
'	sqrt_table_odd[0xD4] 	= 0x0005A220
'	sqrt_table_odd[0xD5] 	= 0x0005A80A
'	sqrt_table_odd[0xD6] 	= 0x0005ADF2
'	sqrt_table_odd[0xD7] 	= 0x0005B3D9
'	sqrt_table_odd[0xD8] 	= 0x0005B9BE
'	sqrt_table_odd[0xD9] 	= 0x0005BFA1
'	sqrt_table_odd[0xDA] 	= 0x0005C583
'	sqrt_table_odd[0xDB] 	= 0x0005CB64
'	sqrt_table_odd[0xDC] 	= 0x0005D142
'	sqrt_table_odd[0xDD] 	= 0x0005D71F
'	sqrt_table_odd[0xDE] 	= 0x0005DCFB
'	sqrt_table_odd[0xDF] 	= 0x0005E2D5
'	sqrt_table_odd[0xE0] 	= 0x0005E8AD
'	sqrt_table_odd[0xE1] 	= 0x0005EE84
'	sqrt_table_odd[0xE2] 	= 0x0005F45A
'	sqrt_table_odd[0xE3] 	= 0x0005FA2D
'	sqrt_table_odd[0xE4] 	= 0x00060000
'	sqrt_table_odd[0xE5] 	= 0x000605D0
'	sqrt_table_odd[0xE6] 	= 0x00060B9F
'	sqrt_table_odd[0xE7] 	= 0x0006116D
'	sqrt_table_odd[0xE8] 	= 0x00061739
'	sqrt_table_odd[0xE9] 	= 0x00061D04
'	sqrt_table_odd[0xEA] 	= 0x000622CD
'	sqrt_table_odd[0xEB] 	= 0x00062894
'	sqrt_table_odd[0xEC] 	= 0x00062E5A
'	sqrt_table_odd[0xED] 	= 0x0006341F
'	sqrt_table_odd[0xEE] 	= 0x000639E2
'	sqrt_table_odd[0xEF] 	= 0x00063FA3
'	sqrt_table_odd[0xF0] 	= 0x00064564
'	sqrt_table_odd[0xF1] 	= 0x00064B22
'	sqrt_table_odd[0xF2] 	= 0x000650DF
'	sqrt_table_odd[0xF3] 	= 0x0006569B
'	sqrt_table_odd[0xF4] 	= 0x00065C55
'	sqrt_table_odd[0xF5] 	= 0x0006620E
'	sqrt_table_odd[0xF6] 	= 0x000667C5
'	sqrt_table_odd[0xF7] 	= 0x00066D7B
'	sqrt_table_odd[0xF8] 	= 0x0006732F
'	sqrt_table_odd[0xF9] 	= 0x000678E2
'	sqrt_table_odd[0xFA] 	= 0x00067E93
'	sqrt_table_odd[0xFB] 	= 0x00068443
'	sqrt_table_odd[0xFC] 	= 0x000689F2
'	sqrt_table_odd[0xFD] 	= 0x00068F9F
'	sqrt_table_odd[0xFE] 	= 0x0006954B
'	sqrt_table_odd[0xFF] 	= 0x00069AF5
'	sqrt_table_even[0x00] 	= 0x0006A09E
'	sqrt_table_even[0x01] 	= 0x0006ABEB
'	sqrt_table_even[0x02] 	= 0x0006B733
'	sqrt_table_even[0x03] 	= 0x0006C276
'	sqrt_table_even[0x04] 	= 0x0006CDB2
'	sqrt_table_even[0x05] 	= 0x0006D8E9
'	sqrt_table_even[0x06] 	= 0x0006E41B
'	sqrt_table_even[0x07] 	= 0x0006EF47
'	sqrt_table_even[0x08] 	= 0x0006FA6E
'	sqrt_table_even[0x09] 	= 0x00070590
'	sqrt_table_even[0x0A] 	= 0x000710AC
'	sqrt_table_even[0x0B] 	= 0x00071BC2
'	sqrt_table_even[0x0C] 	= 0x000726D4
'	sqrt_table_even[0x0D] 	= 0x000731E0
'	sqrt_table_even[0x0E] 	= 0x00073CE7
'	sqrt_table_even[0x0F] 	= 0x000747E8
'	sqrt_table_even[0x10] 	= 0x000752E5
'	sqrt_table_even[0x11] 	= 0x00075DDC
'	sqrt_table_even[0x12] 	= 0x000768CE
'	sqrt_table_even[0x13] 	= 0x000773BB
'	sqrt_table_even[0x14] 	= 0x00077EA3
'	sqrt_table_even[0x15] 	= 0x00078986
'	sqrt_table_even[0x16] 	= 0x00079464
'	sqrt_table_even[0x17] 	= 0x00079F3C
'	sqrt_table_even[0x18] 	= 0x0007AA10
'	sqrt_table_even[0x19] 	= 0x0007B4DF
'	sqrt_table_even[0x1A] 	= 0x0007BFA9
'	sqrt_table_even[0x1B] 	= 0x0007CA6E
'	sqrt_table_even[0x1C] 	= 0x0007D52F
'	sqrt_table_even[0x1D] 	= 0x0007DFEA
'	sqrt_table_even[0x1E] 	= 0x0007EAA1
'	sqrt_table_even[0x1F] 	= 0x0007F552
'	sqrt_table_even[0x20] 	= 0x00080000
'	sqrt_table_even[0x21] 	= 0x00080AA8
'	sqrt_table_even[0x22] 	= 0x0008154B
'	sqrt_table_even[0x23] 	= 0x00081FEA
'	sqrt_table_even[0x24] 	= 0x00082A85
'	sqrt_table_even[0x25] 	= 0x0008351A
'	sqrt_table_even[0x26] 	= 0x00083FAB
'	sqrt_table_even[0x27] 	= 0x00084A37
'	sqrt_table_even[0x28] 	= 0x000854BF
'	sqrt_table_even[0x29] 	= 0x00085F42
'	sqrt_table_even[0x2A] 	= 0x000869C1
'	sqrt_table_even[0x2B] 	= 0x0008743B
'	sqrt_table_even[0x2C] 	= 0x00087EB1
'	sqrt_table_even[0x2D] 	= 0x00088922
'	sqrt_table_even[0x2E] 	= 0x0008938F
'	sqrt_table_even[0x2F] 	= 0x00089DF8
'	sqrt_table_even[0x30] 	= 0x0008A85C
'	sqrt_table_even[0x31] 	= 0x0008B2BB
'	sqrt_table_even[0x32] 	= 0x0008BD17
'	sqrt_table_even[0x33] 	= 0x0008C76E
'	sqrt_table_even[0x34] 	= 0x0008D1C0
'	sqrt_table_even[0x35] 	= 0x0008DC0F
'	sqrt_table_even[0x36] 	= 0x0008E659
'	sqrt_table_even[0x37] 	= 0x0008F09F
'	sqrt_table_even[0x38] 	= 0x0008FAE0
'	sqrt_table_even[0x39] 	= 0x0009051E
'	sqrt_table_even[0x3A] 	= 0x00090F57
'	sqrt_table_even[0x3B] 	= 0x0009198C
'	sqrt_table_even[0x3C] 	= 0x000923BD
'	sqrt_table_even[0x3D] 	= 0x00092DEA
'	sqrt_table_even[0x3E] 	= 0x00093813
'	sqrt_table_even[0x3F] 	= 0x00094237
'	sqrt_table_even[0x40] 	= 0x00094C58
'	sqrt_table_even[0x41] 	= 0x00095674
'	sqrt_table_even[0x42] 	= 0x0009608D
'	sqrt_table_even[0x43] 	= 0x00096AA1
'	sqrt_table_even[0x44] 	= 0x000974B2
'	sqrt_table_even[0x45] 	= 0x00097EBE
'	sqrt_table_even[0x46] 	= 0x000988C7
'	sqrt_table_even[0x47] 	= 0x000992CB
'	sqrt_table_even[0x48] 	= 0x00099CCC
'	sqrt_table_even[0x49] 	= 0x0009A6C9
'	sqrt_table_even[0x4A] 	= 0x0009B0C2
'	sqrt_table_even[0x4B] 	= 0x0009BAB7
'	sqrt_table_even[0x4C] 	= 0x0009C4A8
'	sqrt_table_even[0x4D] 	= 0x0009CE95
'	sqrt_table_even[0x4E] 	= 0x0009D87F
'	sqrt_table_even[0x4F] 	= 0x0009E265
'	sqrt_table_even[0x50] 	= 0x0009EC47
'	sqrt_table_even[0x51] 	= 0x0009F625
'	sqrt_table_even[0x52] 	= 0x000A0000
'	sqrt_table_even[0x53] 	= 0x000A09D6
'	sqrt_table_even[0x54] 	= 0x000A13A9
'	sqrt_table_even[0x55] 	= 0x000A1D79
'	sqrt_table_even[0x56] 	= 0x000A2744
'	sqrt_table_even[0x57] 	= 0x000A310C
'	sqrt_table_even[0x58] 	= 0x000A3AD1
'	sqrt_table_even[0x59] 	= 0x000A4491
'	sqrt_table_even[0x5A] 	= 0x000A4E4E
'	sqrt_table_even[0x5B] 	= 0x000A5808
'	sqrt_table_even[0x5C] 	= 0x000A61BE
'	sqrt_table_even[0x5D] 	= 0x000A6B70
'	sqrt_table_even[0x5E] 	= 0x000A751F
'	sqrt_table_even[0x5F] 	= 0x000A7ECA
'	sqrt_table_even[0x60] 	= 0x000A8872
'	sqrt_table_even[0x61] 	= 0x000A9216
'	sqrt_table_even[0x62] 	= 0x000A9BB7
'	sqrt_table_even[0x63] 	= 0x000AA554
'	sqrt_table_even[0x64] 	= 0x000AAEEE
'	sqrt_table_even[0x65] 	= 0x000AB884
'	sqrt_table_even[0x66] 	= 0x000AC217
'	sqrt_table_even[0x67] 	= 0x000ACBA7
'	sqrt_table_even[0x68] 	= 0x000AD533
'	sqrt_table_even[0x69] 	= 0x000ADEBC
'	sqrt_table_even[0x6A] 	= 0x000AE841
'	sqrt_table_even[0x6B] 	= 0x000AF1C3
'	sqrt_table_even[0x6C] 	= 0x000AFB41
'	sqrt_table_even[0x6D] 	= 0x000B04BD
'	sqrt_table_even[0x6E] 	= 0x000B0E35
'	sqrt_table_even[0x6F] 	= 0x000B17A9
'	sqrt_table_even[0x70] 	= 0x000B211B
'	sqrt_table_even[0x71] 	= 0x000B2A89
'	sqrt_table_even[0x72] 	= 0x000B33F3
'	sqrt_table_even[0x73] 	= 0x000B3D5B
'	sqrt_table_even[0x74] 	= 0x000B46BF
'	sqrt_table_even[0x75] 	= 0x000B5020
'	sqrt_table_even[0x76] 	= 0x000B597E
'	sqrt_table_even[0x77] 	= 0x000B62D9
'	sqrt_table_even[0x78] 	= 0x000B6C30
'	sqrt_table_even[0x79] 	= 0x000B7584
'	sqrt_table_even[0x7A] 	= 0x000B7ED6
'	sqrt_table_even[0x7B] 	= 0x000B8824
'	sqrt_table_even[0x7C] 	= 0x000B916E
'	sqrt_table_even[0x7D] 	= 0x000B9AB6
'	sqrt_table_even[0x7E] 	= 0x000BA3FB
'	sqrt_table_even[0x7F] 	= 0x000BAD3C
'	sqrt_table_even[0x80] 	= 0x000BB67A
'	sqrt_table_even[0x81] 	= 0x000BBFB6
'	sqrt_table_even[0x82] 	= 0x000BC8EE
'	sqrt_table_even[0x83] 	= 0x000BD223
'	sqrt_table_even[0x84] 	= 0x000BDB55
'	sqrt_table_even[0x85] 	= 0x000BE484
'	sqrt_table_even[0x86] 	= 0x000BEDB0
'	sqrt_table_even[0x87] 	= 0x000BF6D9
'	sqrt_table_even[0x88] 	= 0x000C0000
'	sqrt_table_even[0x89] 	= 0x000C0923
'	sqrt_table_even[0x8A] 	= 0x000C1243
'	sqrt_table_even[0x8B] 	= 0x000C1B60
'	sqrt_table_even[0x8C] 	= 0x000C247A
'	sqrt_table_even[0x8D] 	= 0x000C2D91
'	sqrt_table_even[0x8E] 	= 0x000C36A6
'	sqrt_table_even[0x8F] 	= 0x000C3FB7
'	sqrt_table_even[0x90] 	= 0x000C48C6
'	sqrt_table_even[0x91] 	= 0x000C51D1
'	sqrt_table_even[0x92] 	= 0x000C5ADA
'	sqrt_table_even[0x93] 	= 0x000C63E0
'	sqrt_table_even[0x94] 	= 0x000C6CE3
'	sqrt_table_even[0x95] 	= 0x000C75E3
'	sqrt_table_even[0x96] 	= 0x000C7EE0
'	sqrt_table_even[0x97] 	= 0x000C87DA
'	sqrt_table_even[0x98] 	= 0x000C90D2
'	sqrt_table_even[0x99] 	= 0x000C99C7
'	sqrt_table_even[0x9A] 	= 0x000CA2B9
'	sqrt_table_even[0x9B] 	= 0x000CABA8
'	sqrt_table_even[0x9C] 	= 0x000CB495
'	sqrt_table_even[0x9D] 	= 0x000CBD7E
'	sqrt_table_even[0x9E] 	= 0x000CC665
'	sqrt_table_even[0x9F] 	= 0x000CCF49
'	sqrt_table_even[0xA0] 	= 0x000CD82B
'	sqrt_table_even[0xA1] 	= 0x000CE109
'	sqrt_table_even[0xA2] 	= 0x000CE9E5
'	sqrt_table_even[0xA3] 	= 0x000CF2BF
'	sqrt_table_even[0xA4] 	= 0x000CFB95
'	sqrt_table_even[0xA5] 	= 0x000D0469
'	sqrt_table_even[0xA6] 	= 0x000D0D3A
'	sqrt_table_even[0xA7] 	= 0x000D1609
'	sqrt_table_even[0xA8] 	= 0x000D1ED5
'	sqrt_table_even[0xA9] 	= 0x000D279E
'	sqrt_table_even[0xAA] 	= 0x000D3064
'	sqrt_table_even[0xAB] 	= 0x000D3928
'	sqrt_table_even[0xAC] 	= 0x000D41EA
'	sqrt_table_even[0xAD] 	= 0x000D4AA8
'	sqrt_table_even[0xAE] 	= 0x000D5364
'	sqrt_table_even[0xAF] 	= 0x000D5C1E
'	sqrt_table_even[0xB0] 	= 0x000D64D5
'	sqrt_table_even[0xB1] 	= 0x000D6D89
'	sqrt_table_even[0xB2] 	= 0x000D763B
'	sqrt_table_even[0xB3] 	= 0x000D7EEA
'	sqrt_table_even[0xB4] 	= 0x000D8796
'	sqrt_table_even[0xB5] 	= 0x000D9040
'	sqrt_table_even[0xB6] 	= 0x000D98E8
'	sqrt_table_even[0xB7] 	= 0x000DA18D
'	sqrt_table_even[0xB8] 	= 0x000DAA2F
'	sqrt_table_even[0xB9] 	= 0x000DB2CF
'	sqrt_table_even[0xBA] 	= 0x000DBB6D
'	sqrt_table_even[0xBB] 	= 0x000DC408
'	sqrt_table_even[0xBC] 	= 0x000DCCA0
'	sqrt_table_even[0xBD] 	= 0x000DD536
'	sqrt_table_even[0xBE] 	= 0x000DDDCA
'	sqrt_table_even[0xBF] 	= 0x000DE65B
'	sqrt_table_even[0xC0] 	= 0x000DEEEA
'	sqrt_table_even[0xC1] 	= 0x000DF776
'	sqrt_table_even[0xC2] 	= 0x000E0000
'	sqrt_table_even[0xC3] 	= 0x000E0887
'	sqrt_table_even[0xC4] 	= 0x000E110C
'	sqrt_table_even[0xC5] 	= 0x000E198E
'	sqrt_table_even[0xC6] 	= 0x000E220E
'	sqrt_table_even[0xC7] 	= 0x000E2A8C
'	sqrt_table_even[0xC8] 	= 0x000E3307
'	sqrt_table_even[0xC9] 	= 0x000E3B80
'	sqrt_table_even[0xCA] 	= 0x000E43F7
'	sqrt_table_even[0xCB] 	= 0x000E4C6B
'	sqrt_table_even[0xCC] 	= 0x000E54DD
'	sqrt_table_even[0xCD] 	= 0x000E5D4C
'	sqrt_table_even[0xCE] 	= 0x000E65B9
'	sqrt_table_even[0xCF] 	= 0x000E6E24
'	sqrt_table_even[0xD0] 	= 0x000E768D
'	sqrt_table_even[0xD1] 	= 0x000E7EF3
'	sqrt_table_even[0xD2] 	= 0x000E8757
'	sqrt_table_even[0xD3] 	= 0x000E8FB8
'	sqrt_table_even[0xD4] 	= 0x000E9818
'	sqrt_table_even[0xD5] 	= 0x000EA075
'	sqrt_table_even[0xD6] 	= 0x000EA8CF
'	sqrt_table_even[0xD7] 	= 0x000EB128
'	sqrt_table_even[0xD8] 	= 0x000EB97E
'	sqrt_table_even[0xD9] 	= 0x000EC1D2
'	sqrt_table_even[0xDA] 	= 0x000ECA23
'	sqrt_table_even[0xDB] 	= 0x000ED273
'	sqrt_table_even[0xDC] 	= 0x000EDAC0
'	sqrt_table_even[0xDD] 	= 0x000EE30B
'	sqrt_table_even[0xDE] 	= 0x000EEB53
'	sqrt_table_even[0xDF] 	= 0x000EF39A
'	sqrt_table_even[0xE0] 	= 0x000EFBDE
'	sqrt_table_even[0xE1] 	= 0x000F0420
'	sqrt_table_even[0xE2] 	= 0x000F0C60
'	sqrt_table_even[0xE3] 	= 0x000F149E
'	sqrt_table_even[0xE4] 	= 0x000F1CD9
'	sqrt_table_even[0xE5] 	= 0x000F2513
'	sqrt_table_even[0xE6] 	= 0x000F2D4A
'	sqrt_table_even[0xE7] 	= 0x000F357F
'	sqrt_table_even[0xE8] 	= 0x000F3DB2
'	sqrt_table_even[0xE9] 	= 0x000F45E2
'	sqrt_table_even[0xEA] 	= 0x000F4E11
'	sqrt_table_even[0xEB] 	= 0x000F563D
'	sqrt_table_even[0xEC] 	= 0x000F5E67
'	sqrt_table_even[0xED] 	= 0x000F6690
'	sqrt_table_even[0xEE] 	= 0x000F6EB6
'	sqrt_table_even[0xEF] 	= 0x000F76DA
'	sqrt_table_even[0xF0] 	= 0x000F7EFB
'	sqrt_table_even[0xF1] 	= 0x000F871B
'	sqrt_table_even[0xF2] 	= 0x000F8F39
'	sqrt_table_even[0xF3] 	= 0x000F9754
'	sqrt_table_even[0xF4] 	= 0x000F9F6E
'	sqrt_table_even[0xF5] 	= 0x000FA785
'	sqrt_table_even[0xF6] 	= 0x000FAF9B
'	sqrt_table_even[0xF7] 	= 0x000FB7AE
'	sqrt_table_even[0xF8] 	= 0x000FBFBF
'	sqrt_table_even[0xF9] 	= 0x000FC7CE
'	sqrt_table_even[0xFA] 	= 0x000FCFDB
'	sqrt_table_even[0xFB] 	= 0x000FD7E6
'	sqrt_table_even[0xFC] 	= 0x000FDFEF
'	sqrt_table_even[0xFD] 	= 0x000FE7F6
'	sqrt_table_even[0xFE] 	= 0x000FEFFB
'	sqrt_table_even[0xFF] 	= 0x000FF7FE
'END SUB
'END FUNCTION
'
'
' ####################
' #####  TAN ()  #####  tangent
' ####################
'
'  Hart #4287
'
'FUNCTION DOUBLE TAN (DOUBLE a) DOUBLE
'
' FPU routine
'
'	k# = XxxFPTAN (a, @j#)
'	RETURN (k# / j#)
'
' hand coded routine
'
'	fold into 0 - 360
'
'	DO WHILE (a < 0#)
'		a = a + $$TWOPI
'	LOOP
'
'	DO WHILE (a >= $$TWOPI)
'		a = a - $$TWOPI
'	LOOP
'
'	fold into 0-90 with appropriate sign
'
'	SELECT CASE TRUE
'		CASE (a <= $$PIDIV2)	: theSign = +1#
'		CASE (a <= $$PI)			: theSign = -1#	: a = $$PI - a
'		CASE (a <= $$PI3DIV2)	: theSign = +1#	: a = a - $$PI
'		CASE ELSE							: theSign = -1#	: a = $$TWOPI - a
'	END SELECT
'
'	IF (a = $$PIDIV2) THEN RETURN ($$PINF)
'
'	a = a / $$PIDIV4
'	aa = a * a
'	x = aa * .1751083054422421995601107123d-1 - .279527948722905226792457575d2
'	x = x * aa + .6171941889092866899718078509d4
'	x = x * aa - .3498924461690337314553322577d6
'	x = x * aa + .413160917052212537541564775d7
'	y = aa - .4976002053470988434868766867d3				' was aa * 1# - 497.xxxxx
'	y = y * aa + .5497880219885277215781502314d5
'	y = y * aa - .1527149650334576959585193088d7
'	y = y * aa + .5260528179299214050832459853d7
'	RETURN (((a * x) / y) * theSign)
'END FUNCTION
'
'
' #####################
' #####  TANH ()  #####  hyperbolic tangent
' #####################
'
FUNCTION DOUBLE TANH (DOUBLE v) DOUBLE
'
'	 >>>  may have problems similar to XmaSinh ???  <<<
'
	SELECT CASE TRUE
		CASE (v = 0#)				:										RETURN (0#)
		CASE (v >= 19#)			:										RETURN (1#)
		CASE (v <= -19#)		:										RETURN (-1#)
		CASE (ABS(v) > .1#)	: ev = EXP(v+v)		: RETURN ((ev - 1#) / (ev + 1#))
		CASE ELSE						: xv = Expmo(v+v)	: RETURN (xv / (2# + xv))
	END SELECT
END FUNCTION
'
'
' ######################
' #####  Asin0 ()  #####  Hart #4731  :  INTERNAL FUNCTION  :  returns RADIANS
' ######################
'
FUNCTION DOUBLE Asin0 (DOUBLE aa) DOUBLE
'
	x = aa * .28887940520319958009# - .1532823762188072258146d2#
	x = x * aa + .15627431676469845164879d3#
	x = x * aa - .61608581811333824880753d3#
	x = x * aa + .1131354445141400374754542d4#
	x = x * aa - .975678343527571443444814d3#
	x = x * aa + .31952141659008684896086d3#
	y = aa - .282183566472129245114d2#
	y = y * aa + .22430629957413222990564d3#
	y = y * aa - .76632677210477257595839d3#
	y = y * aa + .1278878991056988003191528d4#
	y = y * aa - .1028931912959252211748113d4#
	y = y * aa + .319521416590086848208615d3#
	RETURN (x / y)
END FUNCTION
'
'
' ######################
' #####  Atan0 ()  #####  Hart #5034 : after scaling. called from XmaAtan
' ######################
'
' ***  replaced  ***
'
'		INTERNAL FUNCTION--returns RADIANS
'
'FUNCTION DOUBLE Atan0 (DOUBLE t) DOUBLE
'  tt = t * t
'  x = tt * .2070905893536336532# + .48914801854996690693d1
'  x = x * tt + .16006919587592563754615d2
'  x = x * tt + .125696450645933755049118d2
'
'  y = tt + .91098182645306962582d1							' was tt * .1d1 + .91xxxx
'  y = y * tt + .20196801275790307967877d2
'  y = y * tt + .125696450645933755237905d2
'  RETURN ((t * x) / y)
'END FUNCTION
'
'
' #####################
' #####  Exp0 ()  #####  Hart #1324
' #####################
'
' ***  replaced  ***
'
'FUNCTION DOUBLE Exp0 (DOUBLE v) DOUBLE
'	vv = v * v
'	x = vv * .606133079074800425748489607d2 + .3028561978211645920624269927d5
'	x = x * vv + .2080283036505962712855955242d7
'	y = vv + .1749220769510571455899141717d4
'	y = y * vv + .3277095471932811805340200719d6
'	y = y * vv + .6002428040825173665336946908d7
'	z = (((2# * (v * x)) / (y - (v * x))) + 1#)
'	RETURN (z)
'
'
'	Hart #1067		(original Exp0)
'	vv = v * v
'	x = vv * .23093347753750233624d-1 + .20202065651286927227886d2
'	x = x * vv + .1513906799054338915894328d4
'	y = vv + .233184211427481623790295d3
'	y = y * vv + .4368211662727558498496814d4
'	z = (y + (v * x)) / (y - (v * x))
'
'
'	Hart #1069		(original Exp1)
'	vv = v * v
'	x = vv * .6061485330061080841615584556d2 + .3028697169744036299076048876d5
'	x = x * vv + .2080384346694663001443843411d7
'	y = vv + .1749287689093076403844945335d4
'	y = y * vv + .3277251518082914423057964422d6
'	y = y * vv + .6002720360238832528230907598d7
'	z = (y + (v * x)) / (y - (v * x))
'END FUNCTION
'
'
' ######################
' #####  Expmo ()  #####  Hart #1802
' ######################
'
' EXP(v) - 1, for small v (presumably)
'
FUNCTION DOUBLE Expmo (DOUBLE v) DOUBLE
	vv = v * v
	x = vv * .3333206802628149222225154d-1 + .1400022777377555304975874306d2
	x = x * vv + .5040127554054843027460596926d3
	y = vv + .1120025814484651564577585494d3
	y = y * vv + .1008025510810968605492139581d4
	z = (2# * v * x) / (y - (v * x))
	RETURN (z)
END FUNCTION
'
'
' #####################
' #####  Log0 ()  #####  Hart #2705
' #####################
'
FUNCTION DOUBLE Log0 (DOUBLE v) DOUBLE
  vv = v * v
	x = vv * .4210873712179797145# - .96376909336868659324d1
	x = x * vv + .30957292821537650062264d2
	x = x * vv - .240139179559210509868484d2
	y = vv - .89111090279378312337d1
	y = y * vv + .19480966070088973051623d2
	y = y * vv - .120069589779605254717525d2
	z = x / y
	RETURN (z)
'
'
'	Hart #2665  (original Log0)
'
'	vv	= v * v
'	x		= vv * .16948212488d0 + .1811136267967d0
'	x		= x * vv + .22223823332791d0
'	x		= x * vv + .2857140915904889d0
'	x		= x * vv + .400000001206045365d0
'	x		= x * vv + .6666666666633660894d0
'	x		= x * vv + .200000000000000261007d1
'
'
' #####################
' #####  Clog ()  #####
' #####################
'
' ***  replaced  ***
'
'FUNCTION DOUBLE Clog (DOUBLE v) DOUBLE
'	SLONG upper, lower, exp, exp0, exp1
'	AUTOX SLONG cexp
'	XLONG  ##ERROR
'
'	K1 = DMAKE (0xBF2BD010, 0x5C610CA9)
'	K2 = SMAKE (0x3F318000)
'
'	SELECT CASE TRUE
'		CASE (v <= 0#)	: ##ERROR = $$ErrorNatureInvalidArgument : RETURN (0#)
'		CASE (v  = 1#)	: RETURN (0#)
'	END SELECT
'
'	upper	= DHIGH (v)
'	lower	= DLOW (v)
'	exp		= upper {11, 20}
'	exp0	= upper AND 0x800FFFFF
'	exp1	= exp0 OR 0x3FE00000
'	exp2	= exp - 1022
'	frac	= DMAKE (exp1, lower)						' frac is between 1/2 and 1
'
'	fric  = frexp(v, &cexp)
'	PRINT "frac, exp2 = ";; HEX$(DHIGH(frac), 8);; HEX$(DLOW(frac), 8);;; exp2
'	PRINT "fric, cexp = ";; HEX$(DHIGH(fric), 8);; HEX$(DLOW(fric), 8);;; cexp
'
'	IF (frac >= $$INVSQRT2) THEN					' frac must be between 1/sqrt2 and sqrt2
'		z = (frac - 1#) / (frac + 1#)				' it is!
'	ELSE
'		DEC exp2														' nope: dec the exponent, transfer to frac
'		z = (frac - .5#) / (frac + .5#)			' mult frac by 2 (clever...)
'	END IF
'	zp = Clog0 (z)
'	PRINT "Clog:  exp2 * ln2, zp = "; exp2 * $$LOGE2;; zp
'	j = ((exp2 * K1) + zp) + (exp2 * K2)
'	j = exp2 * $$LOGE2 + zp
'	RETURN (j)
'END FUNCTION
'
'
' ######################
' #####  Clog0 ()  #####
' ######################
'
' ***  replaced  ***
'
'FUNCTION DOUBLE Clog0 (DOUBLE x) DOUBLE
'
'	N1 = DMAKE (0xBFE94415, 0xB356BD28)
'	N2 = DMAKE (0x4030624A, 0x2016AFED)
'	N3 = DMAKE (0xC05007FF, 0x12B3B59B)
'	D1 = DMAKE (0x3FF00000, 0x00000000)
'	D2 = DMAKE (0xC041D580, 0x4B67CE0E)
'	D3 = DMAKE (0x40738083, 0xFA15267E)
'	D4 = DMAKE (0xC0880BFE, 0x9C0D9077)
'
'	v		= 2# * x
'	vv	= v * v
'	vvv = v * vv
'	x		= (((vv * N1 + N2) * vv) + N3) * vvv
'	y   = (((((vv * D1) + D2) * vv) + D3) * vv) + D4
'	z   = (x / y) + v
'	RETURN (z)
'END FUNCTION
END FUNCTION
END PROGRAM

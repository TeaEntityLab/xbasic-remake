'
'
' ####################  Max Reason
' #####  PROLOG  #####  copyright 1988-2000
' ####################  XBasic complex number function library
'
' subject to LGPL license - see COPYING_LIB
'
' MaxReason@MaxReason.com
'
' for Windows XBasic
' for Linux XBasic
'
'
PROGRAM	"xcm"
VERSION	"0.0007"
'
IMPORT	"xst"
IMPORT	"xma"
'
EXPORT
'
' *******************************
' *****  declare functions  *****
' *******************************
'
DECLARE FUNCTION Xcm                   ()
DECLARE FUNCTION XcmVersion$           ()
'
' DCOMPLEX functions  (.R and .I components are DOUBLE precision)
'
DECLARE FUNCTION DOUBLE    DCABS       (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCACOS      (DCOMPLEX z)
DECLARE FUNCTION DOUBLE    DCARG       (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCASIN      (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCATAN      (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCCONJ      (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCCOS       (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCCOSH      (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCEXP       (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCLOG       (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCLOG10     (DCOMPLEX z)
DECLARE FUNCTION DOUBLE    DCNORM      (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCPOLAR     (DOUBLE mag, DOUBLE angle)
DECLARE FUNCTION DCOMPLEX  DCPOWERCC   (DCOMPLEX z, DCOMPLEX n)
DECLARE FUNCTION DCOMPLEX  DCPOWERCR   (DCOMPLEX z, DOUBLE   n)
DECLARE FUNCTION DCOMPLEX  DCPOWERRC   (DOUBLE   z, DCOMPLEX n)
DECLARE FUNCTION DCOMPLEX  DCRMUL      (DCOMPLEX x, DOUBLE y)
DECLARE FUNCTION DCOMPLEX  DCSIN       (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCSINH      (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCSQRT      (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCTAN       (DCOMPLEX z)
DECLARE FUNCTION DCOMPLEX  DCTANH      (DCOMPLEX z)
'
' SCOMPLEX functions  (.R and .I components are SINGLE precision)
'
DECLARE FUNCTION SINGLE    SCABS       (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCACOS      (SCOMPLEX z)
DECLARE FUNCTION SINGLE    SCARG       (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCASIN      (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCATAN      (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCCONJ      (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCCOS       (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCCOSH      (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCEXP       (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCLOG       (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCLOG10     (SCOMPLEX z)
DECLARE FUNCTION SINGLE    SCNORM      (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCPOLAR     (SINGLE mag, SINGLE angle)
DECLARE FUNCTION SCOMPLEX  SCPOWERCC   (SCOMPLEX z, SCOMPLEX n)
DECLARE FUNCTION SCOMPLEX  SCPOWERCR   (SCOMPLEX z, SINGLE   n)
DECLARE FUNCTION SCOMPLEX  SCPOWERRC   (SINGLE   z, SCOMPLEX n)
DECLARE FUNCTION SCOMPLEX  SCRMUL      (SCOMPLEX x, SINGLE y)
DECLARE FUNCTION SCOMPLEX  SCSIN       (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCSINH      (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCSQRT      (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCTAN       (SCOMPLEX z)
DECLARE FUNCTION SCOMPLEX  SCTANH      (SCOMPLEX z)
'
END EXPORT
'
INTERNAL FUNCTION DOUBLE  XdcGetAlpha    (DCOMPLEX z)      ' called by DCASIN & DCACOS
INTERNAL FUNCTION DOUBLE  XdcGetBeta     (DCOMPLEX z)      ' ditto
INTERNAL FUNCTION SINGLE  XscGetAlpha    (SCOMPLEX z)      ' called by SCASIN & SCACOS
INTERNAL FUNCTION SINGLE  XscGetBeta     (SCOMPLEX z)      ' ditto
INTERNAL FUNCTION DOUBLE  Atan2          (DOUBLE y, DOUBLE x)
'
'
' ####################
' #####  Xcm ()  #####
' ####################
'
FUNCTION  Xcm () DOUBLE
	XLONG i, j, ofile
	DCOMPLEX z, zneg, zexp
	DCOMPLEX polar
	DCOMPLEX conj, sq1, sq2, sq3
	DCOMPLEX expx, expxi, emeix, epeix, log1, log10x
	DCOMPLEX sinr, cosr, tanr, asinx, acosx, atanx
	DCOMPLEX sinhx, coshx, tanhx
	DCOMPLEX powCC, powCR, powRC
'
	RETURN
'
	a$ = "Max Reason"
	a$ = "copyright 1988-2000"
	a$ = "XBasic complex number function library"
	a$ = "MaxReason@MaxReason.com"
	a$ = ""
'
' Comment out the following line to route output to file ofile$
'
	ofile = $$STDOUT
	IF (ofile != $$STDOUT) THEN
		ofile$ = "complex.out"
 		ofile = OPEN (ofile$, $$WRNEW)
	  IF (ofile <= 0) THEN PRINT [$$STDERR], "cannot open ofile"
	END IF
'
	DO
	  a$ = INLINE$ ("Input base real value      ===>> ")
		IFZ a$ THEN EXIT FUNCTION
		b$ = INLINE$ ("Input base imaginary value ===>> ")
		z.R = DOUBLE (a$)
		z.I = DOUBLE (b$)
'
' Uncomment the following 4 lines when testing DCPOWERDC, DCPOWERCR or DCPOWERRC
'
	  a$ = INLINE$ ("Input exp real value       ===>> ")
		b$ = INLINE$ ("Input exp imaginary value  ===>> ")
		zexp.R = DOUBLE (a$)
		zexp.I = DOUBLE (b$)

		zneg.R = -z.R
		zneg.I = -z.I

		norm   = DCNORM(z)
		aabs		 = DCABS(z)
		arg    = DCARG(z)
		polar  = DCPOLAR(aabs, arg)
		conj	 = DCCONJ(z)
		sq1		 = DCSQRT(z)
		log10x = DCLOG10(z)
		log1   = DCLOG(z)
		expx   = DCEXP(z)
		expxi  = DCEXP(zneg)
		emeix  = expx - expxi
		epeix  = expx + expxi
		sinr	 = DCSIN(z)
		cosr   = DCCOS(z)
		tanr   = DCTAN(z)
		asinx	 = DCASIN(sinr)
		acosx  = DCACOS(cosr)
		atanx  = DCATAN(tanr)
		asinx	 = DCASIN(z)
		acosx  = DCACOS(z)
		atanx  = DCATAN(z)
		sinhx  = DCSINH(z)
		coshx  = DCCOSH(z)
		tanhx  = DCTANH(z)

		powCC  = DCPOWERCC(z, zexp)
		powCR  = DCPOWERCR(z, zexp.R)
		powRC  = DCPOWERRC(z.R, zexp)

		PRINT [ofile], "abs      = "; aabs,  TAB(36); HEX$(DHIGH(aabs), 8);;  HEX$(DLOW(aabs), 8)
		PRINT [ofile], "arg      = "; arg,   TAB(36); HEX$(DHIGH(arg), 8);;   HEX$(DLOW(arg), 8)
		PRINT [ofile], "norm     = "; norm,  TAB(36); HEX$(DHIGH(norm), 8);;  HEX$(DLOW(norm), 8)
		PRINT [ofile], "polar.R  = "; polar.R,  TAB(36); HEX$(DHIGH(polar.R), 8);;  HEX$(DLOW(polar.R), 8)
		PRINT [ofile], "polar.I  = "; polar.I,  TAB(36); HEX$(DHIGH(polar.I), 8);;  HEX$(DLOW(polar.I), 8)
		PRINT [ofile], "conj.R   = "; conj.R,  TAB(36); HEX$(DHIGH(conj.R), 8);;  HEX$(DLOW(conj.R), 8)
		PRINT [ofile], "conj.I   = "; conj.I,  TAB(36); HEX$(DHIGH(conj.I), 8);;  HEX$(DLOW(conj.I), 8)
		PRINT [ofile], "sq1.R    = "; sq1.R,  TAB(36); HEX$(DHIGH(sq1.R), 8);;  HEX$(DLOW(sq1.R), 8)
		PRINT [ofile], "sq1.I    = "; sq1.I,  TAB(36); HEX$(DHIGH(sq1.I), 8);;  HEX$(DLOW(sq1.I), 8)
		PRINT [ofile], "log1.R   = "; log1.R,  TAB(36); HEX$(DHIGH(log1.R), 8);;  HEX$(DLOW(log1.R), 8)
		PRINT [ofile], "log1.I   = "; log1.I,  TAB(36); HEX$(DHIGH(log1.I), 8);;  HEX$(DLOW(log1.I), 8)
		PRINT [ofile], "log10x.R = "; log10x.R,  TAB(36); HEX$(DHIGH(log10x.R), 8);;  HEX$(DLOW(log10x.R), 8)
		PRINT [ofile], "log10x.I = "; log10x.I,  TAB(36); HEX$(DHIGH(log10x.I), 8);;  HEX$(DLOW(log10x.I), 8)
		PRINT [ofile], "expx.R   = "; expx.R,  TAB(36); HEX$(DHIGH(expx.R), 8);;  HEX$(DLOW(expx.R), 8)
		PRINT [ofile], "expx.I   = "; expx.I,  TAB(36); HEX$(DHIGH(expx.I), 8);;  HEX$(DLOW(expx.I), 8)
		PRINT [ofile], "expxi.R  = "; expxi.R,  TAB(36); HEX$(DHIGH(expxi.R), 8);;  HEX$(DLOW(expxi.R), 8)
		PRINT [ofile], "expxi.I  = "; expxi.I,  TAB(36); HEX$(DHIGH(expxi.I), 8);;  HEX$(DLOW(expxi.I), 8)
		PRINT [ofile], "emeix.R  = "; emeix.R,  TAB(36); HEX$(DHIGH(emeix.R), 8);;  HEX$(DLOW(emeix.R), 8)
		PRINT [ofile], "emeix.I  = "; emeix.I,  TAB(36); HEX$(DHIGH(emeix.I), 8);;  HEX$(DLOW(emeix.I), 8)
		PRINT [ofile], "epeix.R  = "; epeix.R,  TAB(36); HEX$(DHIGH(epeix.R), 8);;  HEX$(DLOW(epeix.R), 8)
		PRINT [ofile], "epeix.I  = "; epeix.I,  TAB(36); HEX$(DHIGH(epeix.I), 8);;  HEX$(DLOW(epeix.I), 8)
		PRINT [ofile], "sinr.R   = "; sinr.R,  TAB(36); HEX$(DHIGH(sinr.R), 8);;  HEX$(DLOW(sinr.R), 8)
		PRINT [ofile], "sinr.I   = "; sinr.I,  TAB(36); HEX$(DHIGH(sinr.I), 8);;  HEX$(DLOW(sinr.I), 8)
		PRINT [ofile], "cosr.R   = "; cosr.R,  TAB(36); HEX$(DHIGH(cosr.R), 8);;  HEX$(DLOW(cosr.R), 8)
		PRINT [ofile], "cosr.I   = "; cosr.I,  TAB(36); HEX$(DHIGH(cosr.I), 8);;  HEX$(DLOW(cosr.I), 8)
		PRINT [ofile], "tanr.R   = "; tanr.R,  TAB(36); HEX$(DHIGH(tanr.R), 8);;  HEX$(DLOW(tanr.R), 8)
		PRINT [ofile], "tanr.I   = "; tanr.I,  TAB(36); HEX$(DHIGH(tanr.I), 8);;  HEX$(DLOW(tanr.I), 8)
		PRINT [ofile], "asin.R   = "; asinx.R, TAB(36); HEX$(DHIGH(asinx.R), 8);; HEX$(DLOW(asinx.R), 8)
		PRINT [ofile], "asin.I   = "; asinx.I, TAB(36); HEX$(DHIGH(asinx.I), 8);; HEX$(DLOW(asinx.I), 8)
		PRINT [ofile], "acos.R   = "; acosx.R, TAB(36); HEX$(DHIGH(acosx.R), 8);; HEX$(DLOW(acosx.R), 8)
		PRINT [ofile], "acos.I   = "; acosx.I, TAB(36); HEX$(DHIGH(acosx.I), 8);; HEX$(DLOW(acosx.I), 8)
		PRINT [ofile], "atan.R   = "; atanx.R, TAB(36); HEX$(DHIGH(atanx.R), 8);; HEX$(DLOW(atanx.R), 8)
		PRINT [ofile], "atan.I   = "; atanx.I, TAB(36); HEX$(DHIGH(atanx.I), 8);; HEX$(DLOW(atanx.I), 8)
		PRINT [ofile], "sinhx.R  = "; sinhx.R,  TAB(36); HEX$(DHIGH(sinhx.R), 8);;  HEX$(DLOW(sinhx.R), 8)
		PRINT [ofile], "sinhx.I  = "; sinhx.I,  TAB(36); HEX$(DHIGH(sinhx.I), 8);;  HEX$(DLOW(sinhx.I), 8)
		PRINT [ofile], "coshx.R  = "; coshx.R,  TAB(36); HEX$(DHIGH(coshx.R), 8);;  HEX$(DLOW(coshx.R), 8)
		PRINT [ofile], "coshx.I  = "; coshx.I,  TAB(36); HEX$(DHIGH(coshx.I), 8);;  HEX$(DLOW(coshx.I), 8)
		PRINT [ofile], "tanhx.R  = "; tanhx.R,  TAB(36); HEX$(DHIGH(tanhx.R), 8);;  HEX$(DLOW(tanhx.R), 8)
		PRINT [ofile], "tanhx.I  = "; tanhx.I,  TAB(36); HEX$(DHIGH(tanhx.I), 8);;  HEX$(DLOW(tanhx.I), 8)

		PRINT [ofile], "powCC.R  = "; powCC.R, TAB(36); HEX$(DHIGH(powCC.R), 8);; HEX$(DLOW(powCC.R), 8)
		PRINT [ofile], "powCC.I  = "; powCC.I, TAB(36); HEX$(DHIGH(powCC.I), 8);; HEX$(DLOW(powCC.I), 8)
		PRINT [ofile], "powCR.R  = "; powCR.R,  TAB(36); HEX$(DHIGH(powCR.R), 8);;  HEX$(DLOW(powCR.R), 8)
		PRINT [ofile], "powCR.I  = "; powCR.I,  TAB(36); HEX$(DHIGH(powCR.I), 8);;  HEX$(DLOW(powCR.I), 8)
		PRINT [ofile], "powRC.R  = "; powRC.R,  TAB(36); HEX$(DHIGH(powRC.R), 8);;  HEX$(DLOW(powRC.R), 8)
		PRINT [ofile], "powRC.I  = "; powRC.I,  TAB(36); HEX$(DHIGH(powRC.I), 8);;  HEX$(DLOW(powRC.I), 8)
	LOOP
  IF (ofile != $$STDOUT) THEN CLOSE (ofile)
END FUNCTION
'
'
'  ############################
'  #####  XcmVersion$ ()  #####
'  ############################
'
FUNCTION  XcmVersion$ ()
	version$ = VERSION$ (0)
	RETURN (version$)
END FUNCTION
'
'
' ######################
' #####  DCABS ()  #####
' ######################
'
' this version uses the Numerical Recipes method
'
FUNCTION DOUBLE DCABS (DCOMPLEX z) DOUBLE
'
	x = ABS(z.R)
	y = ABS(z.I)
'
	SELECT CASE TRUE
		CASE (x = 0#):	RETURN y
		CASE (y = 0#):	RETURN x
		CASE (x > y):		tmp = y / x : RETURN (x * SQRT(1#+(tmp*tmp)))
		CASE ELSE:			tmp = x / y : RETURN (y * SQRT(1#+(tmp*tmp)))
	END SELECT
END FUNCTION
'
'
' #######################
' #####  DCACOS ()  #####
' #######################
'
' from Handbook of Mathematical Functions
'
FUNCTION DCOMPLEX DCACOS (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	alpha = XdcGetAlpha(z)
	beta  = XdcGetBeta (z)
	ans.R = ACOS(beta)
	ans.I = -alpha
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  DCARG ()  #####
' ######################
'
' returns radians
'
FUNCTION DOUBLE DCARG (DCOMPLEX z) DOUBLE
'	IF (z.I = 0) & (z.R = 0) THEN RETURN (0#)    '*cw* 140427-
	IF (z.I = 0) & (z.R = 0) THEN RETURN ()      '*cw* 140427+
	RETURN (Atan2(z.I, z.R))
END FUNCTION
'
'
' #######################
' #####  DCASIN ()  #####
' #######################
'
' from Handbook of Math Functions
'
FUNCTION DCOMPLEX DCASIN (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	alpha = XdcGetAlpha(z)
	beta  = XdcGetBeta (z)

	ans.R = ASIN(beta)
	ans.I = alpha
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCATAN ()  #####
' #######################
'
FUNCTION DCOMPLEX DCATAN (DCOMPLEX z) DOUBLE
	DCOMPLEX	ans
	XLONG	 ##ERROR
'
'	z*z may not = -1"
'
'	IF ((z.R = 0#) & (z.I = 1#)) THEN ##ERROR = $$ErrorNatureInvalidArgument: RETURN (0#)  '*cw* 140427-
	IF ((z.R = 0#) & (z.I = 1#)) THEN ##ERROR = $$ErrorNatureInvalidArgument: RETURN ()    '*cw* 140427+
'
	xsq = z.R * z.R
	ysq = z.I * z.I
	yincsq = z.I + 1#
	yincsq = yincsq * yincsq
	ydecsq = z.I - 1#
	ydecsq = ydecsq * ydecsq
	ans.R = ATAN((z.R * 2#) / (1# - xsq - ysq)) * 0.5#
	ans.I = LOG((xsq + yincsq) / (xsq + ydecsq)) * 0.25#
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCCONJ ()  #####
' #######################
'
FUNCTION DCOMPLEX DCCONJ (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans.R =  z.R
	ans.I = -z.I
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  DCCOS ()  #####
' ######################
'
FUNCTION DCOMPLEX DCCOS (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans.R =  COS(z.R) * COSH(z.I)
	ans.I = -SIN(z.R) * SINH(z.I)
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCCOSH ()  #####
' #######################
'
FUNCTION DCOMPLEX DCCOSH (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans.R = COSH(z.R) * COS(z.I)
	ans.I = SINH(z.R) * SIN(z.I)
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  DCEXP ()  #####
' ######################
'
FUNCTION DCOMPLEX DCEXP (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans.R = EXP(z.R) * COS(z.I)
	ans.I = EXP(z.R) * SIN(z.I)
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  DCLOG ()  #####
' ######################
'
FUNCTION DCOMPLEX DCLOG (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans.R = LOG(DCNORM(z)) * 0.5#
	ans.I = Atan2(z.I, z.R)
	RETURN (ans)
END FUNCTION
'
'
' ########################
' #####  DCLOG10 ()  #####
' ########################
'
FUNCTION DCOMPLEX DCLOG10 (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans = DCLOG(z)
	ans.R = ans.R * $$LOG10E
	ans.I = ans.I * $$LOG10E
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCNORM ()  #####
' #######################
'
FUNCTION DOUBLE DCNORM (DCOMPLEX z) DOUBLE
'
	RETURN ((z.R * z.R) + (z.I * z.I))
END FUNCTION
'
'
' ########################
' #####  DCPOLAR ()  #####
' ########################
'
FUNCTION DCOMPLEX DCPOLAR (DOUBLE mag, DOUBLE angle) DOUBLE
	DCOMPLEX ans
'
	ans.R = mag * COS(angle)
	ans.I = mag * SIN(angle)
	RETURN (ans)
END FUNCTION
'
'
' ##########################
' #####  DCPOWERCC ()  #####
' ##########################
'
FUNCTION DCOMPLEX DCPOWERCC (DCOMPLEX z, DCOMPLEX n) DOUBLE
	DCOMPLEX ans
'
	ans = DCEXP( n * DCLOG(z) )
	RETURN (ans)
END FUNCTION
'
'
' ##########################
' #####  DCPOWERCR ()  #####
' ##########################
'
FUNCTION DCOMPLEX DCPOWERCR (DCOMPLEX z, DOUBLE n) DOUBLE
	DCOMPLEX ans
'
	ans = DCEXP( DCRMUL(DCLOG(z), n) )
	RETURN (ans)
END FUNCTION
'
'
' ##########################
' #####  DCPOWERRC ()  #####
' ##########################
'
FUNCTION DCOMPLEX DCPOWERRC (DOUBLE z, DCOMPLEX n) DOUBLE
	DCOMPLEX ans
'
	ans = DCEXP( DCRMUL(n, LOG(z)) )
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCRMUL ()  #####
' #######################
'
FUNCTION DCOMPLEX DCRMUL (DCOMPLEX x, DOUBLE y) DOUBLE
	DCOMPLEX ans
'
	ans.R = x.R * y
	ans.I = x.I * y
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  DCSIN ()  #####
' ######################
'
FUNCTION DCOMPLEX DCSIN (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans.R = SIN(z.R) * COSH(z.I)
	ans.I = COS(z.R) * SINH(z.I)
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCSINH ()  #####
' #######################
'
FUNCTION DCOMPLEX DCSINH (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	ans.R = SINH(z.R) * COS(z.I)
	ans.I = COSH(z.R) * SIN(z.I)
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCSQRT ()  #####
' #######################
'
'  Math Handbook
'
FUNCTION DCOMPLEX DCSQRT (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	zabs	= DCABS(z)
	ans.R	= SQRT( (zabs + z.R) * 0.5#)
	ans.I	= SQRT( (zabs - z.R) * 0.5#) * SIGN(z.I)
	RETURN (ans)
'
'	*****************************************
'	*****  DCSQRT2:  numeric recipes:  *****
'	*****************************************
'
'	IF (z.R = 0#) & (z.I = 0#) THEN ans.R = 0# : ans.I = 0# : RETURN (ans)
'	x = ABS(z.R)
'	y = ABS(z.I)
'	IF (x >= y) THEN
'		r = y/x
'		w = SQRT(x) * SQRT(0.5# * (1# + SQRT(1# + (r*r))))
'	ELSE
'		r = x/y
'		w = SQRT(y) * SQRT(0.5# * (r  + SQRT(1# + (r*r))))
'	END IF
'	IF z.R >= 0 THEN
'		ans.R = w
'		ans.I = z.I / (2# * w)
'	ELSE
'		IF z.I >= 0 THEN ans.I = w ELSE ans.I = -w
'		ans.R = z.I / (2# * ans.I)
'	END IF
'	RETURN (ans)
'
'	****************************************
'	*****  DCSQRT3:  Turbo C++ method  *****
'	****************************************
'
'	sqrtzabs = SQRT(DCABS(z))
'	hargz = DCARG(z) / 2#
'	ans.R = sqrtzabs * COS(hargz)
'	ans.I = sqrtzabs * SIN(hargz)
'	RETURN (ans)
'
END FUNCTION
'
'
' ######################
' #####  DCTAN ()  #####
' ######################
'
FUNCTION DCOMPLEX DCTAN (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	denom = 1# / (COS(2# * z.R) + COSH(2# * z.I))
	ans.R = SIN (2# * z.R) * denom
	ans.I = SINH (2# * z.I) * denom
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  DCTANH ()  #####
' #######################
'
FUNCTION DCOMPLEX DCTANH (DCOMPLEX z) DOUBLE
	DCOMPLEX ans
'
	denom = 1# / (COSH(2# * z.R) + COS(2# * z.I))
	ans.R = SINH(2# * z.R) * denom
	ans.I = SIN (2# * z.I) * denom
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  SCABS ()  #####
' ######################
'
'  This version uses the Numerical Recipes method
'
FUNCTION SINGLE SCABS (SCOMPLEX z) SINGLE
'
	x = ABS(z.R)
	y = ABS(z.I)
'
	SELECT CASE TRUE
		CASE (x = 0#):	RETURN y
		CASE (y = 0#):	RETURN x
		CASE (x > y):		tmp = y / x : RETURN (x * SQRT(1#+(tmp*tmp)))
		CASE ELSE:			tmp = x / y : RETURN (y * SQRT(1#+(tmp*tmp)))
	END SELECT
END FUNCTION
'
'
' #######################
' #####  SCACOS ()  #####
' #######################
'
' from Handbook of Mathematical Functions
'
FUNCTION SCOMPLEX SCACOS (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	alpha = XscGetAlpha(z)
	beta  = XscGetBeta (z)
	ans.R = ACOS(beta)
	ans.I = -alpha
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  SCARG ()  #####
' ######################
'
' returns radians
'
FUNCTION SINGLE SCARG (SCOMPLEX z) SINGLE
'
'	IF (z.I = 0) & (z.R = 0) THEN RETURN (0#)  '*cw* 140427-
	IF (z.I = 0) & (z.R = 0) THEN RETURN ()    '*cw* 140427+
	RETURN (Atan2(z.I, z.R))
END FUNCTION
'
'
' #######################
' #####  SCASIN ()  #####
' #######################
'
' from Handbook of Math Functions
'
FUNCTION SCOMPLEX SCASIN (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	alpha = XscGetAlpha(z)
	beta  = XscGetBeta (z)
	ans.R = ASIN(beta)
	ans.I = alpha
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCATAN ()  #####
' #######################
'
FUNCTION SCOMPLEX SCATAN (SCOMPLEX z) SINGLE
	SCOMPLEX	ans
	XLONG	 ##ERROR
'
'	z*z may not = -1"
'
	IF ((z.R = 0#) & (z.I = 1#)) THEN
		##ERROR = $$ErrorNatureInvalidArgument
'		RETURN (0#)                                '*cw* 140427-
		RETURN ()                                  '*cw* 140427+
	END IF
'
	xsq = z.R * z.R
	ysq = z.I * z.I
'
	yincsq = z.I + 1#
	yincsq = yincsq * yincsq
'
	ydecsq = z.I - 1#
	ydecsq = ydecsq * ydecsq
'
	ans.R = ATAN((z.R * 2#) / (1# - xsq - ysq)) * 0.5#
	ans.I = LOG((xsq + yincsq) / (xsq + ydecsq)) * 0.25#
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCCONJ ()  #####
' #######################
'
FUNCTION SCOMPLEX SCCONJ (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans.R = 	z.R
	ans.I = - z.I
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  SCCOS ()  #####
' ######################
'
FUNCTION SCOMPLEX SCCOS (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans.R =  COS(z.R) * COSH(z.I)
	ans.I = -SIN(z.R) * SINH(z.I)
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCCOSH ()  #####
' #######################
'
FUNCTION SCOMPLEX SCCOSH (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans.R = COSH(z.R) * COS(z.I)
	ans.I = SINH(z.R) * SIN(z.I)
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  SCEXP ()  #####
' ######################
'
FUNCTION SCOMPLEX SCEXP (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans.R = EXP(z.R) * COS(z.I)
	ans.I = EXP(z.R) * SIN(z.I)
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  SCLOG ()  #####
' ######################
'
FUNCTION SCOMPLEX SCLOG (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans.R = LOG(SCNORM(z)) * 0.5#
	ans.I = Atan2(z.I, z.R)
	RETURN (ans)
END FUNCTION
'
'
' ########################
' #####  SCLOG10 ()  #####
' ########################
'
FUNCTION SCOMPLEX SCLOG10 (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans = SCLOG(z)
	ans.R = ans.R * $$LOG10E
	ans.I = ans.I * $$LOG10E
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCNORM ()  #####
' #######################
'
FUNCTION SINGLE SCNORM (SCOMPLEX z) SINGLE
	RETURN ((z.R * z.R) + (z.I * z.I))
END FUNCTION
'
'
' ########################
' #####  SCPOLAR ()  #####
' ########################
'
FUNCTION SCOMPLEX SCPOLAR (SINGLE mag, SINGLE angle) SINGLE
	SCOMPLEX ans
'
	ans.R = mag * COS(angle)
	ans.I = mag * SIN(angle)
	RETURN (ans)
END FUNCTION
'
'
' ##########################
' #####  SCPOWERCC ()  #####
' ##########################
'
FUNCTION SCOMPLEX SCPOWERCC (SCOMPLEX z, SCOMPLEX n) SINGLE
	SCOMPLEX ans
'
	ans = SCEXP( n * SCLOG(z) )
	RETURN (ans)
END FUNCTION
'
'
' ##########################
' #####  SCPOWERCR ()  #####
' ##########################
'
FUNCTION SCOMPLEX SCPOWERCR (SCOMPLEX z, SINGLE n) SINGLE
	SCOMPLEX ans
'
	ans = SCEXP( SCRMUL(SCLOG(z), n) )
	RETURN (ans)
END FUNCTION
'
'
' ##########################
' #####  SCPOWERRC ()  #####
' ##########################
'
FUNCTION SCOMPLEX SCPOWERRC (SINGLE z, SCOMPLEX n) SINGLE
	SCOMPLEX ans
'
	ans = SCEXP( SCRMUL(n, LOG(z)) )
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCRMUL ()  #####
' #######################
'
FUNCTION SCOMPLEX SCRMUL (SCOMPLEX x, SINGLE y) SINGLE
	SCOMPLEX ans
'
	ans.R = x.R * y
	ans.I = x.I * y
	RETURN (ans)
END FUNCTION
'
'
' ######################
' #####  SCSIN ()  #####
' ######################
'
FUNCTION SCOMPLEX SCSIN (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans.R = SIN(z.R) * COSH(z.I)
	ans.I = COS(z.R) * SINH(z.I)
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCSINH ()  #####
' #######################
'
FUNCTION SCOMPLEX SCSINH (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	ans.R = SINH(z.R) * COS(z.I)
	ans.I = COSH(z.R) * SIN(z.I)
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCSQRT ()  #####  Math Handbook
' #######################
'
FUNCTION SCOMPLEX SCSQRT (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	zabs	= SCABS(z)
	ans.R	= SQRT( (zabs + z.R) * 0.5#)
	ans.I	= SQRT( (zabs - z.R) * 0.5#) * SIGN(z.I)
	RETURN (ans)
'
'	*****************************************
'	*****  XSqrt2:  numeric recipes:  *****
'	*****************************************
'
'	IF (z.R = 0#) & (z.I = 0#) THEN ans.R = 0# : ans.I = 0# : RETURN (ans)
'	x = ABS(z.R)
'	y = ABS(z.I)
'	IF (x >= y) THEN
'		r = y/x
'		w = SQRT(x) * SQRT(0.5# * (1# + SQRT(1# + (r*r))))
'	ELSE
'		r = x/y
'		w = SQRT(y) * SQRT(0.5# * (r  + SQRT(1# + (r*r))))
'	END IF
'	IF z.R >= 0 THEN
'		ans.R = w
'		ans.I = z.I / (2# * w)
'	ELSE
'		IF z.I >= 0 THEN ans.I = w ELSE ans.I = -w
'		ans.R = z.I / (2# * ans.I)
'	END IF
'	RETURN (ans)
'
'	****************************************
'	*****  SCSQRT3:  Turbo C++ method  *****
'	****************************************
'
'	sqrtzabs = SQRT(SCABS(z))
'	hargz = SCARG(z) / 2#
'	ans.R = sqrtzabs * COS (hargz)
'	ans.I = sqrtzabs * SIN (hargz)
'	RETURN (ans)
'
END FUNCTION
'
'
' ######################
' #####  SCTAN ()  #####
' ######################
'
FUNCTION SCOMPLEX SCTAN (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	denom = 1# / (COS(2# * z.R) + COSH(2# * z.I))
	ans.R = SIN (2# * z.R) * denom
	ans.I = SINH(2# * z.I) * denom
	RETURN (ans)
END FUNCTION
'
'
' #######################
' #####  SCTANH ()  #####
' #######################
'
FUNCTION SCOMPLEX SCTANH (SCOMPLEX z) SINGLE
	SCOMPLEX ans
'
	denom = 1# / (COSH(2# * z.R) + COS(2# * z.I))
	ans.R = SINH(2# * z.R) * denom
	ans.I = SIN (2# * z.I) * denom
	RETURN (ans)
END FUNCTION
'
'
' ############################  From Handbook of Mathematical Functions
' #####  XdcGetAlpha ()  #####  Called by XAsin and DCACOS
' ############################
'
'	returns the complete imaginary term, to be specific
'
FUNCTION DOUBLE XdcGetAlpha (DCOMPLEX z) DOUBLE
	ysq = z.I * z.I
	xincsq = z.R + 1#
	xincsq = xincsq * xincsq
	xdecsq = z.R - 1#
	xdecsq = xdecsq * xdecsq
	alpha = (SQRT( xincsq + ysq ) + SQRT( xdecsq + ysq ) ) * 0.5#
	RETURN ( LOG(alpha + SQRT((alpha*alpha) - 1#)) )
END FUNCTION
'
'
' ###########################
' #####  XdcGetBeta ()  #####
' ###########################
'
FUNCTION DOUBLE XdcGetBeta (DCOMPLEX z) DOUBLE
	ysq = z.I * z.I
	xincsq = z.R + 1#
	xincsq = xincsq * xincsq
	xdecsq = z.R - 1#
	xdecsq = xdecsq * xdecsq
	beta = (SQRT( xincsq + ysq ) - SQRT( xdecsq + ysq ) ) * 0.5#
	RETURN (beta)
END FUNCTION
'
'
' ############################  From Handbook of Mathematical Functions
' #####  XscGetAlpha ()  #####  Called by SCASIN and XAcos
' ############################
'
'	returns the complete imaginary term, to be specific
'
FUNCTION SINGLE XscGetAlpha (SCOMPLEX z) SINGLE
	ysq = z.I * z.I
	xincsq = z.R + 1#
	xincsq = xincsq * xincsq
	xdecsq = z.R - 1#
	xdecsq = xdecsq * xdecsq
	alpha = (SQRT( xincsq + ysq ) + SQRT( xdecsq + ysq ) ) * 0.5#
	RETURN ( LOG(alpha + SQRT((alpha*alpha) - 1#)) )
END FUNCTION
'
'
' ###########################
' #####  XscGetBeta ()  #####
' ###########################
'
FUNCTION SINGLE XscGetBeta (SCOMPLEX z) SINGLE
	ysq = z.I * z.I
	xincsq = z.R + 1#
	xincsq = xincsq * xincsq
	xdecsq = z.R - 1#
	xdecsq = xdecsq * xdecsq
	beta = (SQRT( xincsq + ysq ) - SQRT( xdecsq + ysq ) ) * 0.5#
	RETURN (beta)
END FUNCTION
'
'
' ######################
' #####  Atan2 ()  #####
' ######################
'
FUNCTION DOUBLE Atan2 (DOUBLE y, DOUBLE x) DOUBLE
	XLONG	 ##ERROR
'
	IF ((x = 0) & (y = 0)) THEN ##ERROR = $$ErrorNatureInvalidArgument : RETURN(0#)
	IF ((y = 0) & (x < 0)) THEN RETURN ($$PI)
'
	xsign = SIGN(x)
	ysign = SIGN(y)

	x = ABS(x)
	y = ABS(y)

	IF (x >= y) THEN
		s = (y/x)
	ELSE
		s = (x/y)
		inv = 1
	END IF

	res = ATAN(s)
	IF inv THEN res = $$PIDIV2 - res            ' atan(y/x) = pi/2 - atan(x/y)
	IF (xsign = -1#) THEN res = $$PI - res
	RETURN (ysign * res)
END FUNCTION
END PROGRAM

'
' ####################
' #####  PROLOG  #####
' ####################
'
PROGRAM	"nuke"
VERSION	"0.0001"
'
IMPORT  "xst"
IMPORT  "xcm"
IMPORT  "xma"
IMPORT  "xin"
IMPORT  "xgr"
IMPORT  "xui"
'
DECLARE FUNCTION  Entry ()
DECLARE FUNCTION  MemoryMap (@mem$)
EXTERNAL FUNCTION  XxxGetFrameAddr ()
'
'
' ######################
' #####  Entry ()  #####
' ######################
'
FUNCTION  Entry ()
'
	PRINT
	PRINT "########################################"
	PRINT HEX$(##START,8); " = &WinMain() = application base"
	PRINT HEX$(##MAIN,8); " = &XxxMain() = libraries base"
	PRINT HEX$(&Xst(),8); " = &Xst()"
	PRINT HEX$(&Xin(),8); " = &Xin()"
	PRINT HEX$(&Xma(),8); " = &Xma()"
	PRINT HEX$(&Xcm(),8); " = &Xcm()"
	PRINT HEX$(&Xgr(),8); " = &Xgr()"
	PRINT HEX$(&Xui(),8); " = &Xui()"
	PRINT
'
	MemoryMap (@memory$)
	PRINT memory$
'
	PRINT "######################################################"
	PRINT
END FUNCTION
'
'
' ##########################
' #####  MemoryMap ()  #####
' ##########################
'
FUNCTION  MemoryMap (@memory$)
'
	##STACK = XxxGetFrameAddr()
	##STACK0 = ##STACK AND 0xFFFFFFFFFFFFF000
'
	m1$ = "SECTION   PAGE BASE       LOW ADDR        HIGH ADDR       NEXT PAGE\n"
	m2$ = "  CODE    " + HEX$(##CODE0, 12)  + "    " + HEX$(##CODE, 12)  + "    " + HEX$(##CODEX, 12)  + "    " + HEX$(##CODEZ, 12) + "\n"
	m3$ = "   BSS    " + HEX$(##BSS0, 12)   + "    " + HEX$(##BSS, 12)   + "    " + HEX$(##BSSX, 12)   + "    " + HEX$(##BSSZ, 12)   + "\n"
	m4$ = "  DATA    " + HEX$(##DATA0, 12)  + "    " + HEX$(##DATA, 12)  + "    " + HEX$(##DATAX, 12)  + "    " + HEX$(##DATAZ, 12) + "\n"
	m5$ = "  DYNO    " + HEX$(##DYNO0, 12)  + "    " + HEX$(##DYNO, 12)  + "    " + HEX$(##DYNOX, 12)  + "    " + HEX$(##DYNOZ, 12) + "\n"
	m6$ = " UCODE    " + HEX$(##UCODE0, 12) + "    " + HEX$(##UCODE, 12) + "    " + HEX$(##UCODEX, 12) + "    " + HEX$(##UCODEZ, 12) + "\n"
	m7$ = " STACK    " + HEX$(##STACK0, 12) + "    " + HEX$(##STACK, 12) + "    " + HEX$(##STACKX, 12) + "    " + HEX$(##STACKZ, 12)
	memory$ = m1$ + m2$ + m3$ + m4$ + m5$ + m6$ + m7$
END FUNCTION
END PROGRAM

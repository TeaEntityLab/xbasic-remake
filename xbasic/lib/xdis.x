'
'
' ####################  Max Reason
' #####  PROLOG  #####  Copyright 1988-2000
' ####################  Windows XBasic i486+ disassembler function library
' ####################  Linux XBasic disassembler function library
'
' subject to GPL license - see COPYING
'
' MaxReason@MaxReason.com
'
' for Windows XBasic
' for Linux XBasic
'
PROGRAM	"xdis"
VERSION	"6.4.5"
'
IMPORT "xut"
IMPORT "xst"
'
TYPE D86REGOP				' one of a set of opcodes corresponding to REG field of MOD-REG-RM byte
	SUBADDR .action		' subroutine to call
	XLONG 	.param		' parameter for subroutine
	XLONG		.opsiz		' if non-zero, overrides pre-existing opsiz in ParseRegopNo11
END TYPE						' D86REGOPs are stored in groups of 8 in the regop[] array
										' 1st dimension distinguishes the set of D86REGOPs; second dimension
										' is read by ParseRegop from index in reg field of MOD-REG-RM byte
										' mnemonics for indexes into the first dimension are local constants
										' in Decode86$() with names that start "$RO_"

TYPE D86BYTE				' what to do in response to a given instruction byte
	SUBADDR	.action		' subroutine to call
	XLONG 	.param		' parameter for subroutine
	XLONG 	.param2		' another parameter for subroutine
	XLONG 	.flags		' miscellaneous actions to perform before calling subroutine
END TYPE
'
'
'
DECLARE FUNCTION  Xdis              ()
DECLARE FUNCTION  XxxDisassemble64$	(pbyte, useLabel)
'
INTERNAL FUNCTION  GetAddrLabel64$	(branchAddr)
'
' functions in compiler
'
EXTERNAL FUNCTION  XxxGetLabelGivenAddress   (addr, @labels$[])
EXTERNAL FUNCTION  XxxGetFuncNumGivenAddress (addr)
EXTERNAL FUNCTION  XxxPassFunctionArrays     (mode, @funcSymbol$[], @funcToken[], @funcScope[])
EXTERNAL FUNCTION  XxxGetFunctionVariables   (funcNumber, @kinds[], @varTok[], @varSymbol$[], @varReg[], @varAddr[])
'
	$$XGET					 =  0				' xnt constants
	$$XSET					 =  1
	$$KIND_VARIABLES = 0x01
	$$KIND_ARRAYS    = 0x02
'
'
' #####################
' #####  Xdis ()  #####
' #####################
'
'
FUNCTION  Xdis ()
'
	a$ = "Max Reason"
	a$ = "Copyright 1988-2000"
	a$ = "Windows XBasic i486+ disassembler function library"
	a$ = "Linux XBasic disassembler function library"
	a$ = ""
'
END FUNCTION
'
'
' ##################################
' #####  XxxDisassemble64$ ()  #####
' ##################################
'
'
'	Disassemble 486 instruction
'
'	In:				addr				address of opcode to disassemble
'						useLabel		replace branch offsets with actual compiler label
'
'	Out:			addr				address of first byte of next instruction
'
'	Return:		opcode + disassembled instruction
'
'	Discussion:
'		Assumes addr is valid
'		Later:
'			- integrate useLabel to replace branch offsets with actual label
'
FUNCTION  XxxDisassemble64$ (pbyte, useLabel)
	STATIC D86BYTE d86[]									' tables of byte-decodings
	STATIC D86REGOP regop[]
	STATIC opcode$[]											' table of opcode mnemonics
	STATIC special$[]											' table of special instruction strings
	STATIC reg8$[]
	STATIC reg16$[]
	STATIC reg32$[]												' register mnemonics
	STATIC reg64$[]												' register mnemonics
	STATIC scaleFactor$[]									' mnemonics for scale-factor bit fields
	STATIC sreg$[]												' special registers
	STATIC segreg$[]											' segment registers
	STRING result$		' text of decoded instruction so far
	STRING opcode$		' opcode mnemonic
	STRING accum$			' accumulator mnemonic
	STRING operand$		' operand mnemonic
	STRING offset$		' hexadecimal representation of address offset
	STRING disp$			' hexadecimal representation of jump displacement
	STRING imm$				' hexadecimal representation of immediate operand
	XLONG imm					' immediate operand (negative if sign bit set)
	XLONG offset			' address offset
	XLONG disp				' jump displacement
	STRING bytes$			' string containing hexadecimal representation of bytes in instruction
	XLONG done				' $$TRUE if no more bytes left in current instruction
	UBYTE curByte			' current byte being decoded
	UBYTE opcodeByte	' current opcode byte being decoded
	XLONG curTable		' index into 1st dimension of d86[]; i.e. current decoding table
	XLONG opsiz				' operand size of current instruction: 8, 16, 32 or 64
	XLONG param				' param element of current D86BYTE
	XLONG param2			' param2 element of current D86BYTE
	XLONG mode				' field from MOD-REG-RM byte
	XLONG reg					' field from MOD-REG-RM byte
	XLONG rm					' field from MOD-REG-RM byte
	STRING scalef$		' field from S-I-B byte
	STRING indexreg$	' field from S-I-B byte
	STRING basereg$		' field from S-I-B byte
	XLONG noPtr				' don't put in "word ptr" or "byte ptr" in EffectiveAddress
	XLONG i, n, n0, n1, n2, n3
'
' values for curTable: indexes into 1st dim of d86[]
'
	$START	= 0
	$D0F		= 1
	$DD8		= 2				' $DD8 through $DDF *must be* 2 through 9
	$DD9		= 3
	$DDA		= 4
	$DDB		= 5
	$DDC		= 6
	$DDD		= 7
	$DDE		= 8
	$DDF		= 9
'
' bit fields in addressing-mode bytes
'
	$MODE		= BITFIELD(2, 6)
	$REG		= BITFIELD(3, 3)
	$RM			= BITFIELD(3, 0)
	$SCALEF	= BITFIELD(2, 6)
	$INDEX	= BITFIELD(3, 3)
	$BASE		= BITFIELD(3, 0)
'
' flags in "flags" element of D86BYTE
'
	$SIZE8	= BITFIELD(1, 0)		'TRUE if instruction has eight-bit operands
	$EA			= BITFIELD(1, 1)		'TRUE if need to call EffectiveAddress before
															' calling action routine
	$INDRT	= BITFIELD(1, 2)		'TRUE if indirect call or jmp
'
' indexes into register-mnemonic arrays
'
	$EAX = 0:		$ECX = 1:		$EDX = 2:		$EBX = 3
	$ESP = 4:		$EBP = 5:		$ESI = 6:		$EDI = 7

	$AX = 0:		$CX = 1:		$DX = 2:		$BX = 3
	$SP = 4:		$BP = 5:		$SI = 6:		$DI = 7

	$AL = 0:		$CL = 1:		$DL = 2:		$BL = 3
	$AH = 0:		$CH = 1:		$DH = 2:		$BH = 3
'
' indexes into opcode$[]
'
	$AAA = 0:				$AAD = 1:				$AAM = 2:				$AAS = 3
	$ADC = 4:				$ADD = 5:				$AND = 6:				$ARPL = 7
	$BOUND = 8:			$BSF = 9:				$BSR = 10:			$BSWAP = 11
	$BT = 12:				$BTC = 13:			$BTR = 14:			$BTS = 15
	$CALL = 16:			$CBW = 17:			$CDQ = 18:			$CLC = 19
	$CLD = 20:			$CLI = 21:			$CLTS = 22:			$CMC = 23
	$CMP = 24:			$CMPSB = 25:		$CMPXCHG = 26:	$CWD = 27
	$CWDE = 28:			$DAA = 29:			$DAS = 30:			$DEC = 31
	$DIV = 32:			$ENTER = 33:		$HLT = 34:			$IDIV = 35
	$IMUL = 36:			$IN = 37:				$INC = 38:			$INSB = 39
	$INT = 40:			$INTO = 41:			$INVD = 42:			$INVLPG = 43
	$IRET = 44:			$JO = 45:				$JNO = 46:			$JB = 47
	$JAE = 48:			$JZ = 49:				$JNZ = 50:			$JBE = 51
	$JA = 52:				$JS = 53:				$JNS = 54:			$JP = 55
	$JNP = 56:			$JL = 57:				$JGE = 58:			$JLE = 59
	$JG = 60:				$JMP = 61:			$LAHF = 62:			$LAR = 63
	$LEA = 64:			$LEAVE = 65:		$LGDT = 66:			$LIDT = 67
	$LGS = 68:			$LSS = 69:			$LFS = 70:			$LDS = 71
	$LES = 72:			$LLDT = 73:			$LMSW = 74:			$LOCK = 75
	$LODSB = 76:		$LOOP = 77:			$LOOPZ = 78:		$LOOPNZ = 79
	$LSL = 80:			$LTR = 81:			$MOV = 82:			$MOVSB = 83
	$MOVSX = 84:		$MOVZX = 85:		$MUL = 86:			$NEG = 87
	$NOP = 88:			$NOT = 89:			$OR = 90:				$OUT = 91
	$OUTSB = 92:		$POP = 93:			$POPA = 94:			$POPAD = 95
	$POPF = 96:			$POPFD = 97:		$PUSH = 98:			$PUSHA = 99
	$PUSHAD = 100:	$PUSHF = 101:		$PUSHFD = 102:	$RCL = 103
	$RCR = 104:			$ROL = 105:			$ROR = 106:			$REP = 107
	$REPZ = 108:		$REPNZ = 109:		$RETF = 110:		$RETN = 111
	$SAHF = 112:		$SLL = 113:			$SAR = 114:			$SLR = 115
	$SBB = 116:			$SCASB = 117:		$SETO = 118:		$SETNO = 119
	$SETB = 120:		$SETAE = 121:		$SETZ = 122:		$SETNZ = 123
	$SETBE = 124:		$SETA = 125:		$SETS = 126:		$SETNS = 127
	$SETP = 128:		$SETNP = 129:		$SETL = 130:		$SETGE = 131
	$SETLE = 132:		$SETG = 133:		$SGDT = 134:		$SIDT = 135
	$SHLD = 136:		$SHRD = 137:		$SLDT = 138:		$SMSW = 139
	$STC = 140:			$STD = 141:			$STI = 142:			$STOSB = 143
	$STR = 144:			$SUB = 145:			$TEST = 146:		$VERR = 147
	$VERW = 148:		$FWAIT = 149:		$WBINVD = 150:	$XADD = 151
	$XCHG = 152:		$XLATB = 153:		$XOR = 154:			$INSD = 155
	$INSW = 156:		$MOVSD = 157:		$MOVSW = 158:		$STOSD = 159
	$STOSW = 160:		$LODSD = 161:		$LODSW = 162:		$SCASD = 163
	$SCASW = 164:		$OUTSD = 165:		$OUTSW = 166:		$CMPSD = 167
	$CMPSW = 168:		$CSCOLON = 169: $DSCOLON = 170: $ESCOLON = 171
	$SSCOLON = 172: $FSCOLON = 173: $GSCOLON = 174: $ADRSIZ = 175
	$JCXZ = 176:		$JECXZ = 177:		$UNK = 178:			$CALLF = 179
	$JMPF = 180:		$F2XM1 = 181:		$FABS = 182:		$FADD = 183
	$FADDP = 184:		$FBLD = 185:		$FBSTP = 186:		$FCHS = 187
	$FNCLEX = 188:	$FCOM = 189:		$FCOMP = 190
	$FCOMPP = 192:	$FCOS = 193:		$FDECSTP = 194:	$FDIV = 195
	$FDIVP = 196:		$FDIVR = 197:		$FDIVRP = 198:	$FFREE = 199
	$FIADD = 200:		$FICOM = 201:		$FICOMP = 202:	$FIDIV = 203
	$FIDIVR = 204:	$FILD = 205:		$FIMUL = 206:		$FINCSTP = 207
	$FNINIT = 208:	$FIST = 209:		$FISTP = 210:		$FISUB = 211
	$FISUBR = 212:	$FLD = 213:			$FLDCW = 214:		$FLDENV = 215
	$FLDLG2 = 216:	$FLDLN2 = 217:	$FLDL2E = 218:	$FLDL2T = 219
	$FLDPI = 220:		$FLDZ = 221:		$FLD1 = 222:		$FMUL = 223
	$FMULP = 224:		$FNOP = 225:		$FPATAN = 226:	$FPREM = 227
	$FPREM1 = 228:	$FPTAN = 229:		$FRNDINT = 230:	$FRSTOR = 231
	$FNSAVE = 232:	$FSCALE = 233:	$FSETPM = 234:	$FSIN = 235
	$FSINCOS = 236:	$FSQRT = 237:		$FST = 238:			$FNSTCW = 239
	$FNSTENV = 240:	$FSTP = 241:		$FNSTSW = 242:	$FNSTSWAX = 243
	$FSUB = 244:		$FSUBP = 245:		$FSUBR = 246:		$FSUBRP = 247
	$FTST = 248:		$FUCOM = 249:		$FUCOMP = 250:	$FUCOMPP = 251
	$FXAM = 252:		$FXCH = 253:		$FXTRACT = 254:	$FYL2X = 255
	$FYL2XP1 = 256: $MOVABS = 257
	$OPMAX = 257
'
' indexes into special$[]
'
	$PUSHCS = 0:		$PUSHDS = 1:		$PUSHES = 2:		$PUSHSS = 3
	$PUSHFS = 4:		$PUSHGS = 5:										$POPDS = 7
	$POPES = 8:			$POPSS = 9:			$POPFS = 10:		$POPGS = 11
'
' constants for groups of D86REGOPs: each is an index into the 1st
' dimension of regop[]
'
	$RO_TWID8 = 0:		$RO_TWID1 = 1:		$RO_TWIDCL = 2
	$RO_ARITH = 3:		$RO_ARITH8 = 4		$RO_INCDEC1 = 5
	$RO_MUL = 6:			$RO_BT = 7:				$RO_INCDEC2 = 8
	$RO_SLDT = 9:			$RO_SGDT = 10:		$RO_FADD32 = 11
	$RO_FLD32 = 12:		$RO_FIADD32 = 13:	$RO_FILD32 = 14
	$RO_FADD64 = 15:	$RO_FLD64 = 16:		$RO_FIADD16 = 17
	$RO_FILD16 = 18
	$RO_MAX = 18
'
' constants for groups of special registers (1st dimension in sreg$[])
'
	$SR_CR = 0:				$SR_DR = 1:				$SR_TR = 2
	$SR_MAX = 2
'
' ---------------------------------------------------------------------
'
	whomask = ##WHOMASK
	##WHOMASK = 0
	IFZ regop[] THEN GOSUB Init
	IFZ pbyte THEN RETURN
	curTable = $START
	opsiz = 32
	DO UNTIL done
		GOSUB GetByte
		opcodeByte = curByte
		param = d86[curTable, opcodeByte].param
		param2 = d86[curTable, opcodeByte].param2
		IF (d86[curTable, opcodeByte].flags{$SIZE8}) THEN opsiz = 8
		indirect = (d86[curTable, opcodeByte].flags{$INDRT})
		IF (d86[curTable, opcodeByte].flags{$EA}) THEN GOSUB EffectiveAddress
		GOSUB @d86[curTable, opcodeByte].action
	LOOP
	##WHOMASK = whomask
	bytes$ = bytes$ + " "   ' at least one space and end of bytes$
	minbytes = 26
	IF (LEN(bytes$) < minbytes) THEN
		bytes$ = bytes$ + CHR$(32, minbytes - LEN(bytes$))
	END IF
	IF comment$ THEN
		IF (LEN(result$) < minbytes) THEN
			result$ = result$ + CHR$(32, minbytes - LEN(result$))
		END IF
	END IF
	RETURN bytes$ + result$ + comment$
'
' Set the 64-bit prefix flags
'
SUB SetRexW
	rexW = $$TRUE  'operand Width
	opsiz = 64
END SUB
'
SUB SetRex
	SELECT CASE ALL TRUE
		CASE curByte AND 8 : rexW = $$TRUE  'operand Width
		CASE curByte AND 4 : rexR = 8
		CASE curByte AND 2 : rexX = $$TRUE
		CASE curByte AND 1 : rexB = 8
	END SELECT
	opsiz = 64
END SUB
'
' Set the first part of result$ to the opcode
' plus spaces for a length of 8 bytes
'
SUB OpcodeParam
	result$ = opcode$[param]
	minbytes = 8
	IF (LEN(result$) < minbytes) THEN
		result$ = result$ + CHR$(32, minbytes - LEN(result$))
	END IF
END SUB
'
' Set the first part of result$ to the opcode plus q,l,w or b
' Set done = $$TRUE
'
SUB OpcodeParamDone
	SELECT CASE param
		CASE $CALL
		CASE $FLD, $FSTP :
							SELECT CASE opsiz
								CASE 64:	sizeChr$ = "l"  'DOUBLE
								CASE 32:	sizeChr$ = "s"  'SINGLE
							END SELECT
		CASE ELSE
							SELECT CASE opsiz
								CASE 64:	sizeChr$ = "q"
								CASE 32:	sizeChr$ = "l"
								CASE 16:	sizeChr$ = "w"
								CASE 8:		sizeChr$ = "b"
							END SELECT
	END SELECT
	result$ = opcode$[param]
	IF (RIGHT$(result$) <> sizeChr$) THEN
		result$ = result$ + sizeChr$
	END IF
	minbytes = 8
	IF (LEN(result$) < minbytes) THEN
		result$ = result$ + CHR$(32, minbytes - LEN(result$))
	END IF
	done = $$TRUE
END SUB
'
' various utility SUBs: SUBs called by action routines and by each other
'
SUB Disp8						'reads 8-bit jump displacement at pbyte+1, sets disp$
	GOSUB GetByte
	disp = curByte{{8, 0}}
	IF useLabel THEN
		disp$ = GetAddrLabel64$ (pbyte + disp)
	ELSE
		disp$ = HEXX$(pbyte+ disp, 8)
	END IF
END SUB
'
SUB Disp32					'reads 32-bit jump displacement at pbyte+1 through pbyte +4, sets disp$
	GOSUB GetByte
	n0 = curByte
	GOSUB GetByte
	n1 = curByte
	GOSUB GetByte
	n2 = curByte
	GOSUB GetByte
	n3 = curByte
	disp = ((n3 << 24) OR (n2 << 16) OR (n1 << 8) OR n0){{32, 0}}
	IF useLabel THEN
		disp$ = GetAddrLabel64$ (pbyte + disp)
	ELSE
		disp$ = HEXX$(pbyte+ disp, 8)
	END IF
END SUB
'
SUB EffectiveAddress	'sets ea$ to address string in byte(s) at pbyte+1
	GOSUB GetByte
	mode = curByte{$MODE}
	reg = curByte{$REG}
	rm = curByte{$RM}
	SELECT CASE mode
		CASE 0b00:
				SELECT CASE rm
					CASE 0b100:		GOSUB ReadSib
					CASE 0b101:		RIPrel = 1 : GOSUB Offset32  '*cw* 230315-+
					CASE ELSE:		basereg$ = reg64$[rm]
				END SELECT
				GOTO MakeBrackets
		CASE 0b01:
				IF (rm = 0b100) THEN
					GOSUB ReadSib
				ELSE
					basereg$ = reg64$[rexB+rm]
				END IF
				GOSUB Offset8
				GOTO MakeBrackets
		CASE 0b10:
				IF (rm = 0b100) THEN
					GOSUB ReadSib
				ELSE
					basereg$ = reg64$[rexB+rm]
				END IF
				GOSUB Offset32
				GOTO MakeBrackets
		CASE 0b11:
				SELECT CASE opsiz
					CASE 8:		ea$ = reg8$[rm]
					CASE 16:	ea$ = reg16$[rm]
					CASE 32:	ea$ = reg64$[rexB+rm]
										opsiz = 64
					CASE 64:	ea$ = reg64$[rexB+rm]
				END SELECT
				EXIT SUB
	END SELECT
'
MakeBrackets:
	IF basereg$ THEN ea$ = basereg$
	IF indexreg$ THEN
		IF ea$ THEN ea$ = ea$ + ","
		ea$ = ea$ + indexreg$
		IF scalef$ THEN ea$ = ea$ + scalef$
	END IF
	IF ea$ THEN
		ea$ = "(" + ea$ + ")"
	END IF
	IF offset$ THEN
		IF ea$ THEN
			IF offset < 0 THEN
				ea$ = "-" + offset$ + ea$
			ELSE
				ea$ = offset$ + ea$
			END IF
		ELSE
			IF offset < 0 THEN
				ea$ = "-" + offset$
			ELSE
				ea$ = offset$
			END IF
		END IF
	END IF
END SUB
'
SUB GetByte		'sets curByte to next byte; other housekeeping, as well
	curByte = UBYTEAT(pbyte)
	bytes$ = bytes$ + HEX$(curByte, 2)
	INC pbyte
END SUB

SUB Offset8						'reads 8-bit offset at pbyte+1, sets offset$
	GOSUB GetByte
	offset = curByte{{8, 0}}
	offset$ = STRING$(ABS(offset){8, 0})
	GOSUB GetVarSymbol                                '*cw* 230315+
END SUB
'
SUB Offset32					'reads 32-bit offset at pbyte+1 through pbyte +4, sets offset$
	GOSUB GetByte
	n0 = curByte
	GOSUB GetByte
	n1 = curByte
	GOSUB GetByte
	n2 = curByte
	GOSUB GetByte
	n3 = curByte
	offset = (n3 << 24) OR (n2 << 16) OR (n1 << 8) OR n0
	offset = EXTS(offset, 32, 0)  ' extend 32-bit offset to 64-bits
	IF RIPrel THEN                                    '*cw* 230315+
		offset = offset + pbyte                         '*cw* 230315+
		offset$ = HEXX$(ABS(offset))                    '*cw* 230315+
		opsiz = 64                                      '*cw* 230315+
	ELSE                                              '*cw* 230315+
		offset$ = STRING$(ABS(offset))                  '*cw* 230315+
	END IF                                            '*cw* 230315+
	GOSUB GetVarSymbol                                '*cw* 230315+
END SUB
'
SUB PeekByte				'looks ahead one byte: sets curByte to next byte
	curByte = UBYTEAT(pbyte)
END SUB

SUB ReadImm					'reads 8, 16, or 32 bits into imm and imm$, according to opsiz
	SELECT CASE opsiz
		CASE 8:		GOSUB ReadImm8
		CASE 16:	GOSUB ReadImm16
		CASE 32:	GOSUB ReadImm32
		CASE 64:	IF ((opcodeByte AND 0xF8) == 0xB8) THEN  '0xB8 to 0xBF
								GOSUB ReadImm64
							ELSE
								GOSUB ReadImm32
							END IF
	END SELECT
END SUB
'
SUB ReadImm8				'reads a one-byte immediate operand into imm and imm$
	GOSUB GetByte
	imm = curByte{{8, 0}}
	IF (imm < 0) THEN
		imm$ = "$-" + HEXX$(ABS(imm), 2)
	ELSE
		imm$ = HEXX$(imm, 2)
	END IF
END SUB
'
SUB ReadImm16				'reads a two-byte immediate operand into imm and imm$
	GOSUB GetByte
	n0 = curByte
	GOSUB GetByte
	n1 = curByte
	imm = ((n1 << 8) OR n0){{16, 0}}
	IF (imm < 0) THEN
		imm$ = "$-" + HEXX$(ABS(imm), 4)
	ELSE
		imm$ = "$" + HEXX$(imm)
	END IF
END SUB
'
SUB ReadImm32				'reads a four-byte immediate operand into imm and imm$
	GOSUB GetByte
	n0 = curByte
	GOSUB GetByte
	n1 = curByte
	GOSUB GetByte
	n2 = curByte
	GOSUB GetByte
	n3 = curByte
	imm = ((n3 << 24) OR (n2 << 16) OR (n1 << 8) OR n0){{32,0}}
'
	IF (imm < 0) THEN
			imm$ = "$-" + HEXX$(ABS(imm))
	ELSE
		imm$ = "$" + HEXX$(imm)
	END IF

END SUB
'
SUB ReadImm64       'reads an 8-byte immediate operand into and imm$
	GOSUB GetByte
	n0 = curByte
	GOSUB GetByte
	n1 = curByte
	GOSUB GetByte
	n2 = curByte
	GOSUB GetByte
	n3 = curByte
	GOSUB GetByte
	n4 = curByte
	GOSUB GetByte
	n5 = curByte
	GOSUB GetByte
	n6 = curByte
	GOSUB GetByte
	n7 = curByte
	immhi = ((n7 << 24) OR (n6 << 16) OR (n5 << 9) OR n4)
	immlo = ((n3 << 24) OR (n2 << 16) OR (n1 << 8) OR n0)
	IF ((immhi < 0) AND (immhi AND 0x7FFFFFFF)) THEN
		imm$ = "-"
	END IF
		imm$ = imm$ + HEXX$(immhi, 8)
		imm$ = imm$ + HEX$(immlo)
END SUB

'
SUB ReadSib					'reads next byte, and interprets it as a S-I-B byte,
										' parsing it into scalef$, basereg$, and indexreg$
										'assumes that mode, reg, and rm have already been set
										'reads 32-bit offset and sets offset$ if perverse case of
										' base register is EBP and mod field from MOD-REG-RM byte
										' is 0b00
	GOSUB GetByte
	IF (curByte{$INDEX} <> 0b100) THEN
		indexreg$ = reg64$[curByte{$INDEX}]
		scalef$ = scaleFactor$[curByte{$SCALEF}]
	END IF
	IF (mode = 0b00) AND (curByte{$BASE} = $EBP) THEN
		GOSUB Offset32
	ELSE
		basereg$ = reg64$[curByte{$BASE}]
	END IF
END SUB
'
SUB RegString				'sets reg$ to string representing reg field of MOD-REG-RM byte
										' (assumed already read in), according to opsiz
	SELECT CASE opsiz
		CASE 8:		reg$ = reg8$[reg]
		CASE 16:	reg$ = reg16$[reg]
		CASE 32:	reg$ = reg32$[reg]
		CASE 64:	reg$ = reg64$[rexR+reg]
	END SELECT
END SUB
'
' action SUBs: each action SUB corresponds to one or more x86 instructions or
' instruction bytes
'
SUB AccumEa			'instruction with accumulator destination and immediate source
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB OpcodeParamDone
	result$ = result$ + ea$
END SUB
'
SUB AccumImm		'instruction with accumulator destination and immediate source
								'param = index into opcode$[]
	GOSUB ReadImm
	reg = $EAX
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + reg$ + "," + imm$
END SUB
'
SUB AccumImm8		'instruction with accumulator destination and 8-bit immediate source
								'param = index into opcode$[]
	GOSUB ReadImm8
	reg = $EAX
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + reg$ + "," + imm$
END SUB
'
SUB AccumOffset	'instruction with accumulator destination and direct-address source
								'param = index into opcode$[]
	GOSUB Offset32
	reg = $EAX
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + reg$ + ",[" + offset$ + "]"
END SUB
'
SUB Branch8			'instruction with 8-bit branch offset
								'param = index into opcode$[]
	GOSUB Disp8
	GOSUB OpcodeParam
	result$ = result$ + disp$
	done = $$TRUE
END SUB
'
SUB Branch32		'instruction with 32-bit branch offset
	GOSUB Disp32
	GOSUB OpcodeParam
	result$ = result$ + disp$
	done = $$TRUE
END SUB
'
SUB EaImm				'instruction with effective address and immediate operand, long form
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB ReadImm
	GOSUB OpcodeParamDone
	result$ = result$ + imm$ + "," + ea$
END SUB
'
SUB EaImm8			'instruction with effective address and immediate operand, short form
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB ReadImm8
	GOSUB OpcodeParamDone
	result$ = result$ + ea$ + "," + imm$
END SUB
'
SUB EaTwid1			'bit-twiddling instruction with shift count of 1
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB OpcodeParamDone
	result$ = result$ + ea$ + ",1"
END SUB
'
SUB EaTwidCL		'bit-twiddling instruction with shift count in CL
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB OpcodeParamDone
	result$ = result$ + ea$ + ",cl"
END SUB
'
SUB FarAddr			'instructions that branch to an immediate far address
								'param = index into opcode$[]
	GOSUB ReadImm32
	i$ = imm$
	GOSUB ReadImm16
	GOSUB OpcodeParamDone
	result$ = result$ + imm$ + ":" + i$
END SUB
'
SUB FromReg			'instructions with a MOD-REG-RM byte, and with source in reg field
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + reg$ + "," + ea$
END SUB
'
SUB FromSreg		'instructions with normal-register destination and special-register source
								'special-register encoding is in bits 3..5; normal-register code in 0..2
								'param = index into opcode$[]
								'param2 = 1st dimension of sreg$[], i.e. type of special register
	GOSUB GetByte
	GOSUB OpcodeParamDone
	result$ = result$ + reg32$[curByte{3, 0}] + "," + sreg$[param2, curByte{3, 3}]
END SUB
'
SUB FromSTi			'instructions with operands "st,st(i)"
								'param = index into opcode$[]
	GOSUB OpcodeParam
	result$ = result$ + "%st(" + STRING(curByte{3, 0}) + ")"
	done = $$TRUE
END SUB
'
SUB Fwait       '
								'check for
								'9B DF E0 for "fstsw  ax"
								'9B DD .. for "fstsw  mem16" is not handled yet
	IF (UBYTEAT(pbyte) == 0xDF) THEN
		IF (UBYTEAT(pbyte+1) == 0xE0) THEN
			GOSUB GetByte
			GOSUB GetByte
			result$ = "fstsw   ax"
			done = $$TRUE
			EXIT SUB
		END IF
	END IF
	               ' 9B DB E3 for "finit"
	IF (UBYTEAT(pbyte) == 0xDB) THEN
		IF (UBYTEAT(pbyte+1) == 0xE3) THEN
			GOSUB GetByte
			GOSUB GetByte
			result$ = "finit"
			done = $$TRUE
			EXIT SUB
		END IF
	END IF
	GOSUB OpcodeParam
	done = $$TRUE
END SUB
'
SUB Imm8Accum		'instruction with 8-bit immediate "destination" and accumulator source
	GOSUB ReadImm8
	reg = $EAX
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + imm$ + "," + reg$
END SUB
'
SUB Jcxz			'JCXZ and JECXZ
	GOSUB Disp8
	IF (opsiz = 8) THEN
		result$ = opcode$[$JCXZ]
		minbytes = 8
		IF (LEN(result$) < minbytes) THEN
			result$ = result$ + CHR$(32, minbytes - LEN(result$))
		END IF
		result$ = result$ + disp$
	ELSE
		result$ = opcode$[$JECXZ]
		minbytes = 8
		IF (LEN(result$) < minbytes) THEN
			result$ = result$ + CHR$(32, minbytes - LEN(result$))
		END IF
		result$ = result$ + disp$
	END IF
	done = $$TRUE
END SUB
'
SUB JustImm8	'instructions with an immediate 8 bits and nothing else
							'param = index into opcode$[]
	GOSUB ReadImm8
	opsiz = 64                 'destintion is 64 bits
	GOSUB OpcodeParamDone
	result$ = result$ + imm$
END SUB
'
SUB JustImm		'instructions with an immediate operand and nothing else
							'param = index into opcode$[]
	GOSUB ReadImm
	opsiz = 64                 'destintion is 64 bits
	GOSUB OpcodeParamDone
	result$ = result$ + imm$
END SUB
'
SUB JustSTi			'instructions with ST(i) operand only
								'param = index into opcode$[]
	GOSUB OpcodeParam
	result$ = result$ + "%st(" + STRING(curByte{3, 0}) + ")"
	done = $$TRUE
END SUB
'
SUB NoReg			'reg field in MOD-REG-RM is ignored
							'param = index into opcode$[]
							'EffectiveAddress assumed called
	IF indirect THEN
		opsiz = 64
	END IF
	GOSUB OpcodeParamDone
	result$ = result$ + ea$
END SUB
'
SUB NoRegIndr	' add "*" if indirect
	IF indirect THEN
		ea$ = "*" + ea$
	END IF
	GOSUB NoReg
END SUB

SUB OffsetAccum	'instruction with accumulator destination and direct-address source
								'param = index into opcode$[]
	GOSUB Offset32
	reg = $EAX
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + "\t[" + offset$ + "]," + reg$
END SUB

SUB Opsiz			'the dreaded OPSIZ: byte (0x66)
	'OPSIZ: changes the operand size of the following instruction from 32-bit to 16-bit
	opsiz = 16
END SUB

SUB ParseRegop			'reads effective address in which reg field is part of opcode,
										'and calls appropriate SUB to decode rest of instruction
										'param = index into regop[]
										'EffectiveAddress assumed called
	n = param
	param = regop[n, reg].param
	GOSUB @regop[n, reg].action
	done = $$TRUE
END SUB

SUB ParseRegopNo11		'reads effective address in which reg field is part of opcode
											' unless mode = 0b11, in which case d86[] subroutine is called
											' instead
											'param = index into regop[]
											'EffectiveAddress assumed NOT called
	firstByte = curByte
	GOSUB PeekByte
	IF (curByte{$MODE} = 0b11) THEN
		GOSUB GetByte
		param = d86[firstByte - 0xD6, curByte].param
		GOSUB @d86[firstByte - 0xD6, curByte].action
	ELSE
		IF (regop[param, curByte{$REG}].opsiz) THEN
			opsiz = regop[param, curByte{$REG}].opsiz
		END IF
		GOSUB EffectiveAddress
		n = param
		param = regop[n, reg].param
		GOSUB @regop[n, reg].action
	END IF
	done = $$TRUE
END SUB

SUB Reg3			'one-operand instructions with register number in lowest three bits
							'param = index into opcode$[]
	SELECT CASE opsiz
		CASE 8:		operand$ = reg8$[curByte AND 0b111]
		CASE 16:	operand$ = reg16$[curByte AND 0b111]
		CASE 32:	operand$ = reg64$[rexR+curByte AND 0b111]
							opsiz    = 64
		CASE 64:	operand$ = reg64$[rexR+curByte AND 0b111]
	END SELECT
	GOSUB OpcodeParamDone
	result$ = result$ + operand$
END SUB

SUB Reg3Imm		'register number in lowest three bits of opcode, plus immediate operand
							'param = index into opcode$[]
	reg = curByte AND 0b111
	GOSUB RegString
	GOSUB ReadImm
	GOSUB OpcodeParamDone
	result$ = result$ + imm$ + "," + reg$
END SUB

SUB Simple		'a no-operand instruction
							'param = index into opcode$[]
	GOSUB OpcodeParam
	done = $$TRUE
END SUB

SUB Simple_wd		'a one-byte no-operand instruction with different mnemonics depending
								'on whether it was preceded by an OPSIZ: byte
								'param = index into opcode$[] for OPSIZ: not present
								'param2 = index into opcode$[] for OPSIZ: present
	IF opsiz >= 32 THEN
		GOSUB OpcodeParamDone
	ELSE
		result$ = opcode$[param2]
	END IF
	done = $$TRUE
END SUB

SUB Special			'an instruction whose mnemonic is in the special$[] array
								'param = index into special$[]
	result$ = special$[param]
	done = $$TRUE
END SUB

SUB SwitchTable	'switch to new table in d86[] to decode next byte
	SELECT CASE curByte
		CASE 0x0F:	curTable = $D0F
		CASE 0xD8:	curTable = $DD8
		CASE 0xD9:	curTable = $DD9
		CASE 0xDA:	curTable = $DDA
		CASE 0xDB:	curTable = $DDB
		CASE 0xDC:	curTable = $DDC
		CASE 0xDD:	curTable = $DDD
		CASE 0xDE:	curTable = $DDE
		CASE 0xDF:	curTable = $DDF
	END SELECT
END SUB

SUB ThreeOpCL		'instructions with three operands: ea, reg, and CL
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + ea$ + "," + reg$ + ",cl"
END SUB

SUB ThreeOpImm8	'instructions with three operands: ea, reg, and 8-bit immediate
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB ReadImm8
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + imm$ + "," + ea$ + "," + reg$
END SUB

SUB ToReg				'instructions with a mod-reg-rm byte, and with destination in reg field
								'param = index into opcode$[]
								'EffectiveAddress assumed called
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + ea$ + "," + reg$
END SUB

SUB ToRegNoptr	'same as ToReg, but no "word ptr" or "byte ptr" is allowed
								'param = index into opcode$[]
								'EffectiveAddress assumed NOT called
	noPtr = $$TRUE
	GOSUB EffectiveAddress
	GOSUB RegString
	GOSUB OpcodeParamDone
	result$ = result$ + ea$ + "," + reg$
END SUB

SUB ToSreg			'instructions with special-register destination and normal-register source
								'special-register encoding is in bits 3..5; normal-register code in 0..2
								'param = index into opcode$[]
								'param2 = 1st dimension of sreg$[], i.e. type of special register
	GOSUB GetByte
	GOSUB OpcodeParamDone
	result$ = result$ + sreg$[param2, curByte{3, 3}] + "," + reg32$[curByte{3, 0}]
END SUB

SUB ToSTi				'instructions with operands "st(i),st"
								'param = index into opcode$[]
	GOSUB OpcodeParam
	result$ = result$ + "%st,%st(" + STRING(curByte{3, 0}) + ")"
	done = $$TRUE
END SUB

SUB Weird				'instructions that fit into no common pattern
	SELECT CASE curByte
		CASE 0x63:		opsiz = 16: GOSUB EffectiveAddress
									result$ = "movslq  " + ea$ + "," + reg64$[reg]
		CASE 0x69:		GOSUB EffectiveAddress
									GOSUB RegString
									GOSUB ReadImm
									result$ = "imulq   " + imm$ + "," + ea$ + "," + reg$
		CASE 0x8C:		opsiz = 16: GOSUB EffectiveAddress
									result$ = "mov     " + ea$ + "," + segreg$[reg]
		CASE 0x8E:		opsiz = 16: GOSUB EffectiveAddress
									result$ = "mov     " + segreg$[reg] + "," + ea$
		CASE 0xC2:		GOSUB ReadImm16
									result$ = "ret     " + imm$
		CASE 0xC8:		GOSUB ReadImm16
									i1$ = imm$
									GOSUB ReadImm8
									result$ = "enter   " + i1$ + "," + imm$
		CASE 0xCA:		GOSUB ReadImm16
									result$ = "retf    " + imm$
		CASE 0xCC:		result$ = "int     3"
		CASE 0xCD:		GOSUB ReadImm8
									result$ = "int	" + imm$
		CASE 0xEC:		result$ = "in	al,dx"
		CASE 0xED:		IF (opsiz = 32) THEN result$ = "in	eax,dx" ELSE result$ = "in	ax,dx"
		CASE 0xEE:		result$ = "out	dx,al"
		CASE 0xEF:		IF (opsiz = 32) THEN result$ = "out	dx,eax" ELSE result$ = "out	dx,ax"
	END SELECT
	done = $$TRUE
END SUB

SUB Weird0F				'weird instructions whose first byte is 0F
	SELECT CASE curByte
		CASE 0xB6:		oldOpsiz = opsiz
									opsiz = 8: GOSUB EffectiveAddress
									opsiz = oldOpsiz: GOSUB RegString
									IF rexW THEN
										result$ = "movzbq  " + reg$ + "," + ea$
									ELSE
										result$ = "movzbl  " + reg$ + "," + ea$
									END IF
		CASE 0xB7:		oldOpsiz = opsiz
									opsiz = 16: GOSUB EffectiveAddress
									opsiz = oldOpsiz: GOSUB RegString
									IF rexW THEN
										result$ = "movzwq  " + reg$ + "," + ea$
									ELSE
										result$ = "movzwl  " + reg$ + "," + ea$
									END IF
		CASE 0xBE:		oldOpsiz = opsiz
									opsiz = 8: GOSUB EffectiveAddress
									opsiz = oldOpsiz: GOSUB RegString
									IF rexW THEN
										result$ = "movsbq  " + reg$ + "," + ea$
									ELSE
										result$ = "movsbl  " + reg$ + "," + ea$
									END IF
		CASE 0xBF:		oldOpsiz = opsiz
									opsiz = 16: GOSUB EffectiveAddress
									opsiz = oldOpsiz: GOSUB RegString
									IF rexW THEN
										result$ = "movswq  " + reg$ + "," + ea$
									ELSE
										result$ = "movswl  " + reg$ + "," + ea$
									END IF
	END SELECT
	done = $$TRUE
END SUB

SUB XchgEAX		'XCHG accum32,reg32  --  preceding OPSIZ: changes register sizes
	IF opsiz = 32 THEN
		accum$ = reg32$[$EAX]
		operand$ = reg32$[curByte AND 0b111]
	ELSE
		accum$ = reg16$[$AX]
		operand$ = reg16$[curByte AND 0b111]
	END IF
	result$ = opcode$[$XCHG] + "\t" + accum$ + "," + operand$
	done = $$TRUE
END SUB
'
'
' *****  GetVarSymbol  *****
'
SUB GetVarSymbol
	comment$ = ""
	funcNum = XxxGetFuncNumGivenAddress (pbyte)
'	PRINT "XxxDisassemble64$(986)", funcNum
	IF (funcNum < 0) THEN
		EXIT SUB
	END IF
'	DIM kinds[1]
'	kinds[0] = $$KIND_VARIABLES
'	kinds[1] = $$KIND_ARRAYS
	numVars = XxxGetFunctionVariables (funcNum, @kinds[], @varTok[], @varSymbol$[], @varReg[], @varAddr[])
	FOR i = 0 TO UBOUND(varAddr[])
		IF (offset = varAddr[i]) THEN
			comment$ = " ### " + varSymbol$[i]
			EXIT SUB
		END IF
	NEXT i
END SUB
'
'
' *****  initialization  *****
'
SUB Init
	DIM d86[11, 256]
	DIM regop[$RO_MAX, 8]
	DIM opcode$[$OPMAX]
	DIM special$[20]
	DIM reg8$[8]
	DIM reg16$[8]
	DIM reg32$[8]
	DIM reg64$[16]
	DIM scaleFactor$[4]
	DIM sreg$[$SR_MAX, 8]
	DIM segreg$[8]

	'register names

	reg8$[0] = "%al": reg8$[1] = "%cl"
	reg8$[2] = "%dl": reg8$[3] = "%bl"
	reg8$[4] = "%ah": reg8$[5] = "%ch"
	reg8$[6] = "%dh": reg8$[7] = "%bh"

	reg16$[0] = "%ax": reg16$[1] = "%cx"
	reg16$[2] = "%dx": reg16$[3] = "%bx"
	reg16$[4] = "%sp": reg16$[5] = "%bp"
	reg16$[6] = "%si": reg16$[7] = "%di"

	reg32$[0] = "%eax": reg32$[1] = "%ecx"
	reg32$[2] = "%edx": reg32$[3] = "%ebx"
	reg32$[4] = "%esp": reg32$[5] = "%ebp"
	reg32$[6] = "%esi": reg32$[7] = "%edi"

	reg64$[0]  = "%rax" : reg64$[1]  = "%rcx"
	reg64$[2]  = "%rdx" : reg64$[3]  = "%rbx"
	reg64$[4]  = "%rsp" : reg64$[5]  = "%rbp"
	reg64$[6]  = "%rsi" : reg64$[7]  = "%rdi"
	reg64$[8]  = "%r8"  : reg64$[9]  = "%r9"
	reg64$[10] = "%r10" : reg64$[11] = "%r11"
	reg64$[12] = "%r12" : reg64$[13] = "%r13"
	reg64$[14] = "%r14" : reg64$[15] = "%r15"


	'special-register names

	FOR i = 0 TO 7
		sreg$[$SR_CR, i] = "%CR" + STRING(i)
		sreg$[$SR_DR, i] = "%DR" + STRING(i)
		sreg$[$SR_TR, i] = "%TR" + STRING(i)
	NEXT i

	'segment registers

	segreg$[0] = "%es":		segreg$[1] = "%cs":		segreg$[2] = "%ss"
	segreg$[3] = "%ds":		segreg$[4] = "%fs":		segreg$[5] = "%gs"
	segreg$[6] = "??":		segreg$[7] = "??"

	'scale factors    scaleFactor[n] = 2^n

	scaleFactor$[0] = ""
	scaleFactor$[1] = ",2"
	scaleFactor$[2] = ",4"
	scaleFactor$[3] = ",8"

	'initialize all opcodes to illegal instructions

	FOR i = 0 TO $DDF
		FOR j = 0 TO 0xFF
			d86[i, j].action = SUBADDRESS(Simple)
			d86[i, j].param = $UNK
		NEXT j
	NEXT i

	FOR i = 0 TO $RO_MAX			'start all regops off as illegal opcodes
		FOR j = 0 TO 7
			regop[i, j].action = SUBADDR(NoReg)
			regop[i, j].param = $UNK
		NEXT j
	NEXT i

	'not yet categorized

	d86[$START, 0x88].action = SUBADDRESS(FromReg)
	d86[$START, 0x88].param = $MOV
	d86[$START, 0x88].flags = 0b11
	d86[$START, 0x89].action = SUBADDRESS(FromReg)
	d86[$START, 0x89].param = $MOV
	d86[$START, 0x89].flags = 0b10

	d86[$START, 0x84].action = SUBADDRESS(FromReg)
	d86[$START, 0x84].param = $TEST
	d86[$START, 0x84].flags = 0b11
	d86[$START, 0x85].action = SUBADDRESS(FromReg)
	d86[$START, 0x85].param = $TEST
	d86[$START, 0x85].flags = 0b10

	d86[$START, 0x86].action = SUBADDRESS(FromReg)
	d86[$START, 0x86].param = $XCHG
	d86[$START, 0x86].flags = 0b11
	d86[$START, 0x87].action = SUBADDRESS(FromReg)
	d86[$START, 0x87].param = $XCHG
	d86[$START, 0x87].flags = 0b10

	d86[$START, 0x8A].action = SUBADDRESS(ToReg)
	d86[$START, 0x8A].param = $MOV
	d86[$START, 0x8A].flags = 0b11
	d86[$START, 0x8B].action = SUBADDRESS(ToReg)
	d86[$START, 0x8B].param = $MOV
	d86[$START, 0x8B].flags = 0b10

	d86[$START, 0xA0].action = SUBADDRESS(AccumOffset)
	d86[$START, 0xA0].param = $MOV
	d86[$START, 0xA0].flags = 0b01
	d86[$START, 0xA1].action = SUBADDRESS(AccumOffset)
	d86[$START, 0xA1].param = $MOV
	d86[$START, 0xA1].flags = 0b00

	d86[$START, 0xA2].action = SUBADDRESS(OffsetAccum)
	d86[$START, 0xA2].param = $MOV
	d86[$START, 0xA2].flags = 0b01
	d86[$START, 0xA3].action = SUBADDRESS(OffsetAccum)
	d86[$START, 0xA3].param = $MOV
	d86[$START, 0xA3].flags = 0b00

	d86[$START, 0xC6].action = SUBADDRESS(EaImm)
	d86[$START, 0xC6].param = $MOV
	d86[$START, 0xC6].flags = 0b11
	d86[$START, 0xC7].action = SUBADDRESS(EaImm)
	d86[$START, 0xC7].param = $MOV
	d86[$START, 0xC7].flags = 0b10

	'single-byte instructions with no operands

	d86[$START, 0x26].action = SUBADDRESS(Simple)
	d86[$START, 0x26].param = $ESCOLON
	d86[$START, 0x27].action = SUBADDRESS(Simple)
	d86[$START, 0x27].param = $DAA
	d86[$START, 0x2E].action = SUBADDRESS(Simple)
	d86[$START, 0x2E].param = $CSCOLON
	d86[$START, 0x2F].action = SUBADDRESS(Simple)
	d86[$START, 0x2F].param = $DAS
	d86[$START, 0x36].action = SUBADDRESS(Simple)
	d86[$START, 0x36].param = $SSCOLON
	d86[$START, 0x37].action = SUBADDRESS(Simple)
	d86[$START, 0x37].param = $AAA
	d86[$START, 0x3E].action = SUBADDRESS(Simple)
	d86[$START, 0x3E].param = $DSCOLON
	d86[$START, 0x3F].action = SUBADDRESS(Simple)
	d86[$START, 0x3F].param = $AAS
	d86[$START, 0x64].action = SUBADDRESS(Simple)
	d86[$START, 0x64].param = $FSCOLON
	d86[$START, 0x65].action = SUBADDRESS(Simple)
	d86[$START, 0x65].param = $GSCOLON
	d86[$START, 0x67].action = SUBADDRESS(SetRexW)
	d86[$START, 0x67].param = 0
	d86[$START, 0x6C].action = SUBADDRESS(Simple)
	d86[$START, 0x6C].param = $INSB
	d86[$START, 0x6E].action = SUBADDRESS(Simple)
	d86[$START, 0x6E].param = $OUTSB
	d86[$START, 0x90].action = SUBADDRESS(Simple)
	d86[$START, 0x90].param = $NOP
	d86[$START, 0x9B].action = SUBADDRESS(Fwait)
	d86[$START, 0x9B].param = $FWAIT
	d86[$START, 0x9E].action = SUBADDRESS(Simple)
	d86[$START, 0x9E].param = $SAHF
	d86[$START, 0x9F].action = SUBADDRESS(Simple)
	d86[$START, 0x9F].param = $LAHF
	d86[$START, 0xA4].action = SUBADDRESS(Simple)
	d86[$START, 0xA4].param = $MOVSB
	d86[$START, 0xA6].action = SUBADDRESS(Simple)
	d86[$START, 0xA6].param = $CMPSB
	d86[$START, 0xAA].action = SUBADDRESS(Simple)
	d86[$START, 0xAA].param = $STOSB
	d86[$START, 0xAC].action = SUBADDRESS(Simple)
	d86[$START, 0xAC].param = $LODSB
	d86[$START, 0xAE].action = SUBADDRESS(Simple)
	d86[$START, 0xAE].param = $SCASB
	d86[$START, 0xC3].action = SUBADDRESS(Simple)
	d86[$START, 0xC3].param = $RETN
	d86[$START, 0xC9].action = SUBADDRESS(Simple)
	d86[$START, 0xC9].param = $LEAVE
	d86[$START, 0xCB].action = SUBADDRESS(Simple)
	d86[$START, 0xCB].param = $RETF
	d86[$START, 0xCE].action = SUBADDRESS(Simple)
	d86[$START, 0xCE].param = $INTO
	d86[$START, 0xCF].action = SUBADDRESS(Simple)
	d86[$START, 0xCF].param = $IRET
	d86[$START, 0xD4].action = SUBADDRESS(Simple)
	d86[$START, 0xD4].param = $AAM
	d86[$START, 0xD5].action = SUBADDRESS(Simple)
	d86[$START, 0xD5].param = $AAD
	d86[$START, 0xD7].action = SUBADDRESS(Simple)
	d86[$START, 0xD7].param = $XLATB
	d86[$START, 0xF0].action = SUBADDRESS(Simple)
	d86[$START, 0xF0].param = $LOCK
	d86[$START, 0xF2].action = SUBADDRESS(Simple)
	d86[$START, 0xF2].param = $REPNZ
	d86[$START, 0xF3].action = SUBADDRESS(Simple)
	d86[$START, 0xF3].param = $REP
	d86[$START, 0xF4].action = SUBADDRESS(Simple)
	d86[$START, 0xF4].param = $HLT
	d86[$START, 0xF5].action = SUBADDRESS(Simple)
	d86[$START, 0xF5].param = $CMC
	d86[$START, 0xF8].action = SUBADDRESS(Simple)
	d86[$START, 0xF8].param = $CLC
	d86[$START, 0xF9].action = SUBADDRESS(Simple)
	d86[$START, 0xF9].param = $STC
	d86[$START, 0xFA].action = SUBADDRESS(Simple)
	d86[$START, 0xFA].param = $CLI
	d86[$START, 0xFB].action = SUBADDRESS(Simple)
	d86[$START, 0xFB].param = $STI
	d86[$START, 0xFC].action = SUBADDRESS(Simple)
	d86[$START, 0xFC].param = $CLD
	d86[$START, 0xFD].action = SUBADDRESS(Simple)
	d86[$START, 0xFD].param = $STD

	'single-byte instructions with no operands, but with different mnemonics depending
	'on whether they're preceded by an OPSIZ: byte (0x66) or not

	d86[$START, 0x60].action = SUBADDRESS(Simple_wd)
	d86[$START, 0x60].param = $PUSHAD
	d86[$START, 0x60].param2 = $PUSHA
	d86[$START, 0x61].action = SUBADDRESS(Simple_wd)
	d86[$START, 0x61].param = $POPAD
	d86[$START, 0x61].param2 = $POPA
	d86[$START, 0x6D].action = SUBADDRESS(Simple_wd)
	d86[$START, 0x6D].param = $INSD
	d86[$START, 0x6D].param2 = $INSW
	d86[$START, 0x6F].action = SUBADDRESS(Simple_wd)
	d86[$START, 0x6F].param = $OUTSD
	d86[$START, 0x6F].param2 = $OUTSW
	d86[$START, 0x98].action = SUBADDRESS(Simple_wd)
	d86[$START, 0x98].param = $CWDE
	d86[$START, 0x98].param2 = $CBW
	d86[$START, 0x99].action = SUBADDRESS(Simple)
	d86[$START, 0x99].param = $CDQ
	d86[$START, 0x99].param2 = $CWD
	d86[$START, 0x9C].action = SUBADDRESS(Simple_wd)
	d86[$START, 0x9C].param = $PUSHFD
	d86[$START, 0x9C].param2 = $PUSHF
	d86[$START, 0x9D].action = SUBADDRESS(Simple_wd)
	d86[$START, 0x9D].param = $POPFD
	d86[$START, 0x9D].param2 = $POPF
	d86[$START, 0xA5].action = SUBADDRESS(Simple_wd)
	d86[$START, 0xA5].param = $MOVSD
	d86[$START, 0xA5].param2 = $MOVSW
	d86[$START, 0xA7].action = SUBADDRESS(Simple_wd)
	d86[$START, 0xA7].param = $CMPSD
	d86[$START, 0xA7].param2 = $CMPSW
	d86[$START, 0xAB].action = SUBADDRESS(Simple_wd)
	d86[$START, 0xAB].param = $STOSD
	d86[$START, 0xAB].param2 = $STOSW
	d86[$START, 0xAD].action = SUBADDRESS(Simple_wd)
	d86[$START, 0xAD].param = $LODSW
	d86[$START, 0xAD].param2 = $LODSD
	d86[$START, 0xAF].action = SUBADDRESS(Simple_wd)
	d86[$START, 0xAF].param = $SCASD
	d86[$START, 0xAF].param2 = $SCASW

	'instructions with register number in lowest three bits

	FOR i = 0x40 TO 0x4F
		d86[$START, i].action = SUBADDRESS(SetRex)
		d86[$START, i].param = 0
	NEXT i
	d86[$START, 0x48].action = SUBADDRESS(SetRexW)

	FOR i = 0x50 TO 0x57
		d86[$START, i].action = SUBADDRESS(Reg3)
		d86[$START, i].param = $PUSH
	NEXT i

	FOR i = 0x58 TO 0x5F
		d86[$START, i].action = SUBADDRESS(Reg3)
		d86[$START, i].param = $POP
	NEXT i

	FOR i = 0xC8 TO 0xCF
		d86[$D0F, i].action = SUBADDRESS(Reg3)
		d86[$D0F, i].param = $BSWAP
	NEXT i

	FOR i = 0x91 TO 0x97
		d86[$START, i].action = SUBADDRESS(XchgEAX)
	NEXT i

	'instructions with register number in lowest three bits plus immediate operand

	FOR i = 0xB0 TO 0xB7
		d86[$START, i].action = SUBADDRESS(Reg3Imm)
		d86[$START, i].param = $MOV
		d86[$START, i].flags = 0b01
	NEXT i

	FOR i = 0xB8 TO 0xBF
		d86[$START, i].action = SUBADDRESS(Reg3Imm)
		d86[$START, i].param = $MOVABS
	NEXT i

	'arithmetic instructions with ea destination and reg source

	d86[$START, 0x00].action = SUBADDRESS(FromReg)
	d86[$START, 0x00].param = $ADD
	d86[$START, 0x00].flags = 0b11
	d86[$START, 0x01].action = SUBADDRESS(FromReg)
	d86[$START, 0x01].param = $ADD
	d86[$START, 0x01].flags = 0b10
	d86[$START, 0x08].action = SUBADDRESS(FromReg)
	d86[$START, 0x08].param = $OR
	d86[$START, 0x08].flags = 0b11
	d86[$START, 0x09].action = SUBADDRESS(FromReg)
	d86[$START, 0x09].param = $OR
	d86[$START, 0x09].flags = 0b10
	d86[$START, 0x10].action = SUBADDRESS(FromReg)
	d86[$START, 0x10].param = $ADC
	d86[$START, 0x10].flags = 0b11
	d86[$START, 0x11].action = SUBADDRESS(FromReg)
	d86[$START, 0x11].param = $ADC
	d86[$START, 0x11].flags = 0b10
	d86[$START, 0x18].action = SUBADDRESS(FromReg)
	d86[$START, 0x18].param = $SBB
	d86[$START, 0x18].flags = 0b11
	d86[$START, 0x19].action = SUBADDRESS(FromReg)
	d86[$START, 0x19].param = $SBB
	d86[$START, 0x19].flags = 0b10
	d86[$START, 0x20].action = SUBADDRESS(FromReg)
	d86[$START, 0x20].param = $AND
	d86[$START, 0x20].flags = 0b11
	d86[$START, 0x21].action = SUBADDRESS(FromReg)
	d86[$START, 0x21].param = $AND
	d86[$START, 0x21].flags = 0b10
	d86[$START, 0x28].action = SUBADDRESS(FromReg)
	d86[$START, 0x28].param = $SUB
	d86[$START, 0x28].flags = 0b11
	d86[$START, 0x29].action = SUBADDRESS(FromReg)
	d86[$START, 0x29].param = $SUB
	d86[$START, 0x29].flags = 0b10
	d86[$START, 0x30].action = SUBADDRESS(FromReg)
	d86[$START, 0x30].param = $XOR
	d86[$START, 0x30].flags = 0b11
	d86[$START, 0x31].action = SUBADDRESS(FromReg)
	d86[$START, 0x31].param = $XOR
	d86[$START, 0x31].flags = 0b10
	d86[$START, 0x38].action = SUBADDRESS(FromReg)
	d86[$START, 0x38].param = $CMP
	d86[$START, 0x38].flags = 0b11
	d86[$START, 0x39].action = SUBADDRESS(FromReg)
	d86[$START, 0x39].param = $CMP
	d86[$START, 0x39].flags = 0b10

	d86[$D0F, 0xA6].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xA6].param = $CMPXCHG
	d86[$D0F, 0xA6].flags = 0b11
	d86[$D0F, 0xA7].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xA7].param = $CMPXCHG
	d86[$D0F, 0xA7].flags = 0b10
	d86[$D0F, 0xC0].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xC0].param = $XADD
	d86[$D0F, 0xC0].flags = 0b11
	d86[$D0F, 0xC1].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xC1].param = $XADD
	d86[$D0F, 0xC1].flags = 0b10

	'arithmetic instructions with reg destination and ea source

	d86[$START, 0x02].action = SUBADDRESS(ToReg)
	d86[$START, 0x02].param = $ADD
	d86[$START, 0x02].flags = 0b11
	d86[$START, 0x03].action = SUBADDRESS(ToReg)
	d86[$START, 0x03].param = $ADD
	d86[$START, 0x03].flags = 0b10
	d86[$START, 0x0A].action = SUBADDRESS(ToReg)
	d86[$START, 0x0A].param = $OR
	d86[$START, 0x0A].flags = 0b11
	d86[$START, 0x0B].action = SUBADDRESS(ToReg)
	d86[$START, 0x0B].param = $OR
	d86[$START, 0x0B].flags = 0b10
	d86[$START, 0x12].action = SUBADDRESS(ToReg)
	d86[$START, 0x12].param = $ADC
	d86[$START, 0x12].flags = 0b11
	d86[$START, 0x13].action = SUBADDRESS(ToReg)
	d86[$START, 0x13].param = $ADC
	d86[$START, 0x13].flags = 0b10
	d86[$START, 0x1A].action = SUBADDRESS(ToReg)
	d86[$START, 0x1A].param = $SBB
	d86[$START, 0x1A].flags = 0b11
	d86[$START, 0x1B].action = SUBADDRESS(ToReg)
	d86[$START, 0x1B].param = $SBB
	d86[$START, 0x1B].flags = 0b10
	d86[$START, 0x22].action = SUBADDRESS(ToReg)
	d86[$START, 0x22].param = $AND
	d86[$START, 0x22].flags = 0b11
	d86[$START, 0x23].action = SUBADDRESS(ToReg)
	d86[$START, 0x23].param = $AND
	d86[$START, 0x23].flags = 0b10
	d86[$START, 0x2A].action = SUBADDRESS(ToReg)
	d86[$START, 0x2A].param = $SUB
	d86[$START, 0x2A].flags = 0b11
	d86[$START, 0x2B].action = SUBADDRESS(ToReg)
	d86[$START, 0x2B].param = $SUB
	d86[$START, 0x2B].flags = 0b10
	d86[$START, 0x32].action = SUBADDRESS(ToReg)
	d86[$START, 0x32].param = $XOR
	d86[$START, 0x32].flags = 0b11
	d86[$START, 0x33].action = SUBADDRESS(ToReg)
	d86[$START, 0x33].param = $XOR
	d86[$START, 0x33].flags = 0b10
	d86[$START, 0x3A].action = SUBADDRESS(ToReg)
	d86[$START, 0x3A].param = $CMP
	d86[$START, 0x3A].flags = 0b11
	d86[$START, 0x3B].action = SUBADDRESS(ToReg)
	d86[$START, 0x3B].param = $CMP
	d86[$START, 0x3B].flags = 0b10
	d86[$START, 0x62].action = SUBADDRESS(ToReg)
	d86[$START, 0x62].param = $BOUND
	d86[$START, 0x62].flags = 0b10
	d86[$D0F, 0xAF].action = SUBADDRESS(ToReg)
	d86[$D0F, 0xAF].param = $IMUL
	d86[$D0F, 0xAF].flags = 0b10

	'arithmetic instructions with accumulator destination and immediate source

	d86[$START, 0x04].action = SUBADDRESS(AccumImm)
	d86[$START, 0x04].param = $ADD
	d86[$START, 0x04].flags = 0b01
	d86[$START, 0x05].action = SUBADDRESS(AccumImm)
	d86[$START, 0x05].param = $ADD
	d86[$START, 0x05].flags = 0b00
	d86[$START, 0x0C].action = SUBADDRESS(AccumImm)
	d86[$START, 0x0C].param = $OR
	d86[$START, 0x0C].flags = 0b01
	d86[$START, 0x0D].action = SUBADDRESS(AccumImm)
	d86[$START, 0x0D].param = $OR
	d86[$START, 0x0D].flags = 0b00
	d86[$START, 0x14].action = SUBADDRESS(AccumImm)
	d86[$START, 0x14].param = $ADC
	d86[$START, 0x14].flags = 0b01
	d86[$START, 0x15].action = SUBADDRESS(AccumImm)
	d86[$START, 0x15].param = $ADC
	d86[$START, 0x15].flags = 0b00
	d86[$START, 0x1C].action = SUBADDRESS(AccumImm)
	d86[$START, 0x1C].param = $SBB
	d86[$START, 0x1C].flags = 0b01
	d86[$START, 0x1D].action = SUBADDRESS(AccumImm)
	d86[$START, 0x1D].param = $SBB
	d86[$START, 0x1D].flags = 0b00
	d86[$START, 0x24].action = SUBADDRESS(AccumImm)
	d86[$START, 0x24].param = $AND
	d86[$START, 0x24].flags = 0b01
	d86[$START, 0x25].action = SUBADDRESS(AccumImm)
	d86[$START, 0x25].param = $AND
	d86[$START, 0x25].flags = 0b00
	d86[$START, 0x2C].action = SUBADDRESS(AccumImm)
	d86[$START, 0x2C].param = $SUB
	d86[$START, 0x2C].flags = 0b01
	d86[$START, 0x2D].action = SUBADDRESS(AccumImm)
	d86[$START, 0x2D].param = $SUB
	d86[$START, 0x2D].flags = 0b00
	d86[$START, 0x34].action = SUBADDRESS(AccumImm)
	d86[$START, 0x34].param = $XOR
	d86[$START, 0x34].flags = 0b01
	d86[$START, 0x35].action = SUBADDRESS(AccumImm)
	d86[$START, 0x35].param = $XOR
	d86[$START, 0x35].flags = 0b00
	d86[$START, 0x3C].action = SUBADDRESS(AccumImm)
	d86[$START, 0x3C].param = $CMP
	d86[$START, 0x3C].flags = 0b01
	d86[$START, 0x3D].action = SUBADDRESS(AccumImm)
	d86[$START, 0x3D].param = $CMP
	d86[$START, 0x3D].flags = 0b00
	d86[$START, 0xA8].action = SUBADDRESS(AccumImm)
	d86[$START, 0xA8].param = $TEST
	d86[$START, 0xA8].flags = 0b01
	d86[$START, 0xA9].action = SUBADDRESS(AccumImm)
	d86[$START, 0xA9].param = $TEST
	d86[$START, 0xA9].flags = 0b00

	'first bytes of multi-byte opcodes

	d86[$START, 0x0F].action = SUBADDRESS(SwitchTable)
	FOR i = 0xD8 TO 0xDF
		d86[$START, i].action = SUBADDRESS(ParseRegopNo11)
	NEXT i
	d86[$START, 0xD8].param = $RO_FADD32
	d86[$START, 0xD9].param = $RO_FLD32
	d86[$START, 0xDA].param = $RO_FIADD32
	d86[$START, 0xDB].param = $RO_FILD32
	d86[$START, 0xDC].param = $RO_FADD64
	d86[$START, 0xDD].param = $RO_FLD64
	d86[$START, 0xDE].param = $RO_FIADD16
	d86[$START, 0xDF].param = $RO_FILD16

	'bytes followed by a MOD-REG-RM byte with part of the opcode in the reg field

	d86[$START, 0x80].action = SUBADDRESS(ParseRegop)
	d86[$START, 0x80].param = $RO_ARITH
	d86[$START, 0x80].flags = 0b11
	d86[$START, 0x81].action = SUBADDRESS(ParseRegop)
	d86[$START, 0x81].param = $RO_ARITH
	d86[$START, 0x81].flags = 0b10
	d86[$START, 0x83].action = SUBADDRESS(ParseRegop)
	d86[$START, 0x83].param = $RO_ARITH8
	d86[$START, 0x83].flags = 0b10
	d86[$START, 0xC0].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xC0].param = $RO_TWID8
	d86[$START, 0xC0].flags = 0b11
	d86[$START, 0xC1].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xC1].param = $RO_TWID8
	d86[$START, 0xC1].flags = 0b10
	d86[$START, 0xD0].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xD0].param = $RO_TWID1
	d86[$START, 0xD0].flags = 0b11
	d86[$START, 0xD1].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xD1].param = $RO_TWID1
	d86[$START, 0xD1].flags = 0b10
	d86[$START, 0xD2].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xD2].param = $RO_TWIDCL
	d86[$START, 0xD2].flags = 0b11
	d86[$START, 0xD3].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xD3].param = $RO_TWIDCL
	d86[$START, 0xD3].flags = 0b10
	d86[$START, 0xF6].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xF6].param = $RO_MUL
	d86[$START, 0xF6].flags = 0b11
	d86[$START, 0xF7].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xF7].param = $RO_MUL
	d86[$START, 0xF7].flags = 0b10
	d86[$START, 0xFE].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xFE].param = $RO_INCDEC1
	d86[$START, 0xFE].flags = 0b11
	d86[$START, 0xFF].action = SUBADDRESS(ParseRegop)
	d86[$START, 0xFF].param = $RO_INCDEC2
	d86[$START, 0xFF].flags = 0b110
	d86[$D0F, 0x00].action = SUBADDRESS(ParseRegop)
	d86[$D0F, 0x00].param = $RO_SLDT
	d86[$D0F, 0x00].flags = 0b10
	d86[$D0F, 0x01].action = SUBADDRESS(ParseRegop)
	d86[$D0F, 0x01].param = $RO_SGDT
	d86[$D0F, 0x01].flags = 0b10

	'system-programming instructions

	d86[$D0F, 0x06].action = SUBADDRESS(Simple)
	d86[$D0F, 0x06].param = $CLTS
	d86[$D0F, 0x08].action = SUBADDRESS(Simple)
	d86[$D0F, 0x08].param = $INVD
	d86[$D0F, 0x09].action = SUBADDRESS(Simple)
	d86[$D0F, 0x09].param = $WBINVD
	d86[$D0F, 0x10].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x10].param = $INVLPG
	d86[$D0F, 0x10].flags = 0b10
	d86[$D0F, 0x02].action = SUBADDRESS(ToReg)
	d86[$D0F, 0x02].param = $LAR
	d86[$D0F, 0x02].flags = 0b10
	d86[$D0F, 0x03].action = SUBADDRESS(ToReg)
	d86[$D0F, 0x03].param = $LSL
	d86[$D0F, 0x03].flags = 0b10
	d86[$D0F, 0x20].action = SUBADDRESS(ToSreg)
	d86[$D0F, 0x20].param = $MOV
	d86[$D0F, 0x20].param2 = $SR_CR
	d86[$D0F, 0x21].action = SUBADDRESS(ToSreg)
	d86[$D0F, 0x21].param = $MOV
	d86[$D0F, 0x21].param2 = $SR_DR
	d86[$D0F, 0x22].action = SUBADDRESS(FromSreg)
	d86[$D0F, 0x22].param = $MOV
	d86[$D0F, 0x22].param2 = $SR_CR
	d86[$D0F, 0x23].action = SUBADDRESS(FromSreg)
	d86[$D0F, 0x23].param = $MOV
	d86[$D0F, 0x23].param2 = $SR_DR
	d86[$D0F, 0x24].action = SUBADDRESS(ToSreg)
	d86[$D0F, 0x24].param = $MOV
	d86[$D0F, 0x24].param2 = $SR_TR
	d86[$D0F, 0x26].action = SUBADDRESS(FromSreg)
	d86[$D0F, 0x26].param = $MOV
	d86[$D0F, 0x26].param2 = $SR_TR

	'SETcc instructions

	d86[$D0F, 0x90].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x90].param = $SETO
	d86[$D0F, 0x90].flags = 0b11
	d86[$D0F, 0x91].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x91].param = $SETNO
	d86[$D0F, 0x91].flags = 0b11
	d86[$D0F, 0x92].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x92].param = $SETB
	d86[$D0F, 0x92].flags = 0b11
	d86[$D0F, 0x93].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x93].param = $SETAE
	d86[$D0F, 0x93].flags = 0b11
	d86[$D0F, 0x94].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x94].param = $SETZ
	d86[$D0F, 0x94].flags = 0b11
	d86[$D0F, 0x95].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x95].param = $SETNZ
	d86[$D0F, 0x95].flags = 0b11
	d86[$D0F, 0x96].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x96].param = $SETBE
	d86[$D0F, 0x96].flags = 0b11
	d86[$D0F, 0x97].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x97].param = $SETA
	d86[$D0F, 0x97].flags = 0b11
	d86[$D0F, 0x98].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x98].param = $SETS
	d86[$D0F, 0x98].flags = 0b11
	d86[$D0F, 0x99].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x99].param = $SETNS
	d86[$D0F, 0x99].flags = 0b11
	d86[$D0F, 0x9A].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x9A].param = $SETP
	d86[$D0F, 0x9A].flags = 0b11
	d86[$D0F, 0x9B].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x9B].param = $SETNP
	d86[$D0F, 0x9B].flags = 0b11
	d86[$D0F, 0x9C].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x9C].param = $SETL
	d86[$D0F, 0x9C].flags = 0b11
	d86[$D0F, 0x9D].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x9D].param = $SETGE
	d86[$D0F, 0x9D].flags = 0b11
	d86[$D0F, 0x9E].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x9E].param = $SETLE
	d86[$D0F, 0x9E].flags = 0b11
	d86[$D0F, 0x9F].action = SUBADDRESS(NoReg)
	d86[$D0F, 0x9F].param = $SETG
	d86[$D0F, 0x9F].flags = 0b11

	'32-bit conditional jumps

	d86[$D0F, 0x80].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x80].param = $JO
	d86[$D0F, 0x81].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x81].param = $JNO
	d86[$D0F, 0x82].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x82].param = $JB
	d86[$D0F, 0x83].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x83].param = $JAE
	d86[$D0F, 0x84].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x84].param = $JZ
	d86[$D0F, 0x85].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x85].param = $JNZ
	d86[$D0F, 0x86].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x86].param = $JBE
	d86[$D0F, 0x87].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x87].param = $JA
	d86[$D0F, 0x88].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x88].param = $JS
	d86[$D0F, 0x89].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x89].param = $JNS
	d86[$D0F, 0x8A].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x8A].param = $JP
	d86[$D0F, 0x8B].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x8B].param = $JNP
	d86[$D0F, 0x8C].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x8C].param = $JL
	d86[$D0F, 0x8D].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x8D].param = $JGE
	d86[$D0F, 0x8E].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x8E].param = $JLE
	d86[$D0F, 0x8F].action = SUBADDRESS(Branch32)
	d86[$D0F, 0x8F].param = $JG

	'8-bit conditional jumps

	d86[$START, 0x70].action = SUBADDRESS(Branch8)
	d86[$START, 0x70].param = $JO
	d86[$START, 0x71].action = SUBADDRESS(Branch8)
	d86[$START, 0x71].param = $JNO
	d86[$START, 0x72].action = SUBADDRESS(Branch8)
	d86[$START, 0x72].param = $JB
	d86[$START, 0x73].action = SUBADDRESS(Branch8)
	d86[$START, 0x73].param = $JAE
	d86[$START, 0x74].action = SUBADDRESS(Branch8)
	d86[$START, 0x74].param = $JZ
	d86[$START, 0x75].action = SUBADDRESS(Branch8)
	d86[$START, 0x75].param = $JNZ
	d86[$START, 0x76].action = SUBADDRESS(Branch8)
	d86[$START, 0x76].param = $JBE
	d86[$START, 0x77].action = SUBADDRESS(Branch8)
	d86[$START, 0x77].param = $JA
	d86[$START, 0x78].action = SUBADDRESS(Branch8)
	d86[$START, 0x78].param = $JS
	d86[$START, 0x79].action = SUBADDRESS(Branch8)
	d86[$START, 0x79].param = $JNS
	d86[$START, 0x7A].action = SUBADDRESS(Branch8)
	d86[$START, 0x7A].param = $JP
	d86[$START, 0x7B].action = SUBADDRESS(Branch8)
	d86[$START, 0x7B].param = $JNP
	d86[$START, 0x7C].action = SUBADDRESS(Branch8)
	d86[$START, 0x7C].param = $JL
	d86[$START, 0x7D].action = SUBADDRESS(Branch8)
	d86[$START, 0x7D].param = $JGE
	d86[$START, 0x7E].action = SUBADDRESS(Branch8)
	d86[$START, 0x7E].param = $JLE
	d86[$START, 0x7F].action = SUBADDRESS(Branch8)
	d86[$START, 0x7F].param = $JG
	d86[$START, 0xE0].action = SUBADDRESS(Branch8)
	d86[$START, 0xE0].param = $LOOPNZ
	d86[$START, 0xE1].action = SUBADDRESS(Branch8)
	d86[$START, 0xE1].param = $LOOPZ
	d86[$START, 0xE2].action = SUBADDRESS(Branch8)
	d86[$START, 0xE2].param = $LOOP

	'unconditional relative branches

	d86[$START, 0xEB].action = SUBADDRESS(Branch8)
	d86[$START, 0xEB].param = $JMP
	d86[$START, 0xE9].action = SUBADDRESS(Branch32)
	d86[$START, 0xE9].param = $JMP
	d86[$START, 0xE8].action = SUBADDRESS(Branch32)
	d86[$START, 0xE8].param = $CALL

	'bit-test instructions

	d86[$D0F, 0xA3].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xA3].param = $BT
	d86[$D0F, 0xA3].flags = 0b10
	d86[$D0F, 0xAB].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xAB].param = $BTS
	d86[$D0F, 0xAB].flags = 0b10
	d86[$D0F, 0xB3].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xB3].param = $BTR
	d86[$D0F, 0xB3].flags = 0b10
	d86[$D0F, 0xBB].action = SUBADDRESS(FromReg)
	d86[$D0F, 0xBB].param = $BTC
	d86[$D0F, 0xBB].flags = 0b10
	d86[$D0F, 0xBA].action = SUBADDRESS(ParseRegop)
	d86[$D0F, 0xBA].param = $RO_BT
	d86[$D0F, 0xBA].flags = 0b10

	d86[$D0F, 0xBC].action = SUBADDRESS(ToReg)
	d86[$D0F, 0xBC].param = $BSF
	d86[$D0F, 0xBC].flags = 0b10
	d86[$D0F, 0xBD].action = SUBADDRESS(ToReg)
	d86[$D0F, 0xBD].param = $BSR
	d86[$D0F, 0xBD].flags = 0b10

	'PUSHes

	d86[$START, 0x06].action = SUBADDRESS(Special)
	d86[$START, 0x06].param = $PUSHES
	d86[$START, 0x0E].action = SUBADDRESS(Special)
	d86[$START, 0x0E].param = $PUSHCS
	d86[$START, 0x16].action = SUBADDRESS(Special)
	d86[$START, 0x16].param = $PUSHSS
	d86[$START, 0x1E].action = SUBADDRESS(Special)
	d86[$START, 0x1E].param = $PUSHDS
	d86[$D0F, 0xA0].action = SUBADDRESS(Special)
	d86[$D0F, 0xA0].param = $PUSHFS
	d86[$D0F, 0xA8].action = SUBADDRESS(Special)
	d86[$D0F, 0xA8].param = $PUSHGS
	d86[$START, 0x68].action = SUBADDRESS(JustImm)
	d86[$START, 0x68].param = $PUSH
	d86[$START, 0x68].flags = 0b00
	d86[$START, 0x6A].action = SUBADDRESS(JustImm8)
	d86[$START, 0x6A].param = $PUSH
	d86[$START, 0x6A].flags = 0b00

	'POPs

	d86[$START, 0x07].action = SUBADDRESS(Special)
	d86[$START, 0x07].param = $POPES
	d86[$START, 0x17].action = SUBADDRESS(Special)
	d86[$START, 0x17].param = $POPSS
	d86[$START, 0x1F].action = SUBADDRESS(Special)
	d86[$START, 0x1F].param = $POPDS
	d86[$D0F, 0xA1].action = SUBADDRESS(Special)
	d86[$D0F, 0xA1].param = $POPFS
	d86[$D0F, 0xA9].action = SUBADDRESS(Special)
	d86[$D0F, 0xA9].param = $POPGS
	d86[$START, 0x8F].action = SUBADDRESS(NoReg)
	d86[$START, 0x8F].param = $POP
	d86[$START, 0x8F].flags = 0b10

	'Lxx instructions

	d86[$START, 0x8D].action = SUBADDRESS(ToRegNoptr)
	d86[$START, 0x8D].param = $LEA
	d86[$START, 0xC4].action = SUBADDRESS(ToRegNoptr)
	d86[$START, 0xC4].param = $LES
	d86[$START, 0xC5].action = SUBADDRESS(ToRegNoptr)
	d86[$START, 0xC5].param = $LDS
	d86[$D0F, 0xB2].action = SUBADDRESS(ToRegNoptr)
	d86[$D0F, 0xB2].param = $LSS
	d86[$D0F, 0xB4].action = SUBADDRESS(ToRegNoptr)
	d86[$D0F, 0xB4].param = $LFS
	d86[$D0F, 0xB5].action = SUBADDRESS(ToRegNoptr)
	d86[$D0F, 0xB5].param = $LGS

	'INs and OUTs

	d86[$START, 0xE4].action = SUBADDRESS(AccumImm8)
	d86[$START, 0xE4].param = $IN
	d86[$START, 0xE4].flags = 0b01
	d86[$START, 0xE5].action = SUBADDRESS(AccumImm8)
	d86[$START, 0xE5].param = $IN
	d86[$START, 0xE5].flags = 0b00
	d86[$START, 0xE6].action = SUBADDRESS(Imm8Accum)
	d86[$START, 0xE6].param = $OUT
	d86[$START, 0xE6].flags = 0b01
	d86[$START, 0xE7].action = SUBADDRESS(Imm8Accum)
	d86[$START, 0xE7].param = $OUT
	d86[$START, 0xE7].flags = 0b00

	'long branches

	d86[$START, 0xEA].action = SUBADDRESS(FarAddr)
	d86[$START, 0xEA].param = $JMPF
	d86[$START, 0x9A].action = SUBADDRESS(FarAddr)
	d86[$START, 0x9A].param = $CALLF

	'three-operand instructions

	d86[$START, 0x69].action = SUBADDRESS(Weird)
	d86[$START, 0x6B].action = SUBADDRESS(ThreeOpImm8)
	d86[$START, 0x6B].param = $IMUL
	d86[$START, 0x6B].flags = 0b10
	d86[$D0F, 0xA4].action = SUBADDRESS(ThreeOpImm8)
	d86[$D0F, 0xA4].param = $SHLD
	d86[$D0F, 0xA4].flags = 0b10
	d86[$D0F, 0xA5].action = SUBADDRESS(ThreeOpCL)
	d86[$D0F, 0xA5].param = $SHLD
	d86[$D0F, 0xA5].flags = 0b10
	d86[$D0F, 0xAC].action = SUBADDRESS(ThreeOpImm8)
	d86[$D0F, 0xAC].param = $SHRD
	d86[$D0F, 0xAC].flags = 0b10
	d86[$D0F, 0xAD].action = SUBADDRESS(ThreeOpCL)
	d86[$D0F, 0xAD].param = $SHRD
	d86[$D0F, 0xAD].flags = 0b10

	'floating-point instructions with no effective address

	FOR i = 0xC0 TO 0xFF
		d86[$DD8, i].action = SUBADDRESS(FromSTi)
		d86[$DD9, i].action = SUBADDRESS(JustSTi)
		d86[$DDC, i].action = SUBADDRESS(ToSTi)
		d86[$DDD, i].action = SUBADDRESS(JustSTi)
		d86[$DDE, i].action = SUBADDRESS(ToSTi)
		SELECT CASE TRUE
			CASE (i >= 0xC0) AND (i <= 0xC7):
							d86[$DD8, i].param = $FADD
							d86[$DD9, i].param = $FLD
							d86[$DDC, i].param = $FADD
							d86[$DDD, i].param = $FFREE
							d86[$DDE, i].param = $FADDP
			CASE (i >= 0xC8) AND (i <= 0xCF):
							d86[$DD8, i].param = $FMUL
							d86[$DD9, i].param = $FXCH
							d86[$DDC, i].param = $FMUL
							d86[$DDE, i].param = $FMULP
			CASE (i >= 0xD0) AND (i <= 0xD7):
							d86[$DD8, i].param = $FCOM
							d86[$DDD, i].param = $FST
			CASE (i >= 0xD8) AND (i <= 0xDF):
							d86[$DD8, i].param = $FCOMP
							d86[$DDD, i].param = $FSTP
			CASE (i >= 0xE0) AND (i <= 0xE7):
							d86[$DD8, i].param = $FSUB
							d86[$DDC, i].param = $FSUBR
							d86[$DDD, i].param = $FUCOM
							d86[$DDE, i].param = $FSUBRP
			CASE (i >= 0xE8) AND (i <= 0xEF):
							d86[$DD8, i].param = $FSUBR
							d86[$DDC, i].param = $FSUB
							d86[$DDD, i].param = $FUCOMP
							d86[$DDE, i].param = $FSUBP
			CASE (i >= 0xF0) AND (i <= 0xF7):
							d86[$DD8, i].param = $FDIV
							d86[$DDC, i].param = $FDIVR
							d86[$DDE, i].param = $FDIVRP
			CASE (i >= 0xF8) AND (i <= 0xFF):
							d86[$DD8, i].param = $FDIVR
							d86[$DDC, i].param = $FDIV
							d86[$DDE, i].param = $FDIVP
		END SELECT
	NEXT i

	'floating-point instructions with effective address

	FOR i = 0 TO 7
		regop[$RO_FADD32, i].opsiz = 32
	NEXT i
	regop[$RO_FADD32, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 0].param = $FADD
	regop[$RO_FADD32, 1].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 1].param = $FMUL
	regop[$RO_FADD32, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 2].param = $FCOM
	regop[$RO_FADD32, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 3].param = $FCOMP
	regop[$RO_FADD32, 4].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 4].param = $FSUB
	regop[$RO_FADD32, 5].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 5].param = $FSUBR
	regop[$RO_FADD32, 6].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 6].param = $FDIV
	regop[$RO_FADD32, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FADD32, 7].param = $FDIVR

	FOR i = 0 TO 7
		regop[$RO_FLD32, i].opsiz = 32
	NEXT i
	regop[$RO_FLD32, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FLD32, 0].param = $FLD
	regop[$RO_FLD32, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FLD32, 2].param = $FST
	regop[$RO_FLD32, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FLD32, 3].param = $FSTP
	regop[$RO_FLD32, 4].action = SUBADDRESS(NoReg)
	regop[$RO_FLD32, 4].param = $FLDENV
	regop[$RO_FLD32, 5].action = SUBADDRESS(NoReg)
	regop[$RO_FLD32, 5].param = $FLDCW
	regop[$RO_FLD32, 5].opsiz = 16
	regop[$RO_FLD32, 6].action = SUBADDRESS(NoReg)
	regop[$RO_FLD32, 6].param = $FNSTENV
	regop[$RO_FLD32, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FLD32, 7].param = $FNSTCW
	regop[$RO_FLD32, 7].opsiz = 16

	FOR i = 0 TO 7
		regop[$RO_FIADD32, i].opsiz = 32
	NEXT i
	regop[$RO_FIADD32, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 0].param = $FIADD
	regop[$RO_FIADD32, 1].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 1].param = $FIMUL
	regop[$RO_FIADD32, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 2].param = $FICOM
	regop[$RO_FIADD32, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 3].param = $FICOMP
	regop[$RO_FIADD32, 4].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 4].param = $FISUB
	regop[$RO_FIADD32, 5].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 5].param = $FISUBR
	regop[$RO_FIADD32, 6].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 6].param = $FIDIV
	regop[$RO_FIADD32, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD32, 7].param = $FIDIVR

	FOR i = 0 TO 7
		regop[$RO_FILD32, i].opsiz = 32
	NEXT i
	regop[$RO_FILD32, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FILD32, 0].param = $FILD
	regop[$RO_FILD32, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FILD32, 2].param = $FIST
	regop[$RO_FILD32, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FILD32, 3].param = $FISTP
	regop[$RO_FILD32, 5].action = SUBADDRESS(NoReg)
	regop[$RO_FILD32, 5].param = $FLD			'real80!
	regop[$RO_FILD32, 5].opsiz = 80
	regop[$RO_FILD32, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FILD32, 7].param = $FSTP		'real80!
	regop[$RO_FILD32, 7].opsiz = 80

	FOR i = 0 TO 7
		regop[$RO_FADD64, i].opsiz = 64
	NEXT i
	regop[$RO_FADD64, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 0].param = $FADD
	regop[$RO_FADD64, 1].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 1].param = $FMUL
	regop[$RO_FADD64, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 2].param = $FCOM
	regop[$RO_FADD64, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 3].param = $FCOMP
	regop[$RO_FADD64, 4].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 4].param = $FSUB
	regop[$RO_FADD64, 5].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 5].param = $FSUBR
	regop[$RO_FADD64, 6].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 6].param = $FDIV
	regop[$RO_FADD64, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FADD64, 7].param = $FDIVR

	FOR i = 0 TO 7
		regop[$RO_FLD64, i].opsiz = 64
	NEXT i
	regop[$RO_FLD64, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FLD64, 0].param = $FLD
	regop[$RO_FLD64, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FLD64, 2].param = $FST
	regop[$RO_FLD64, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FLD64, 3].param = $FSTP
	regop[$RO_FLD64, 4].action = SUBADDRESS(NoReg)
	regop[$RO_FLD64, 4].param = $FRSTOR		'Ea
	regop[$RO_FLD64, 4].opsiz = 32
	regop[$RO_FLD64, 6].action = SUBADDRESS(NoReg)
	regop[$RO_FLD64, 6].param = $FNSAVE		'Ea
	regop[$RO_FLD64, 6].opsiz = 32
	regop[$RO_FLD64, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FLD64, 7].param = $FNSTSW		'Ew
	regop[$RO_FLD64, 7].opsiz = 16

	FOR i = 0 TO 7
		regop[$RO_FIADD16, i].opsiz = 16
	NEXT i
	regop[$RO_FIADD16, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 0].param = $FIADD
	regop[$RO_FIADD16, 1].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 1].param = $FIMUL
	regop[$RO_FIADD16, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 2].param = $FICOM
	regop[$RO_FIADD16, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 3].param = $FICOMP
	regop[$RO_FIADD16, 4].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 4].param = $FISUB
	regop[$RO_FIADD16, 5].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 5].param = $FISUBR
	regop[$RO_FIADD16, 6].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 6].param = $FIDIV
	regop[$RO_FIADD16, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FIADD16, 7].param = $FIDIVR

	regop[$RO_FILD16, 0].action = SUBADDRESS(NoReg)
	regop[$RO_FILD16, 0].param = $FILD
	regop[$RO_FILD16, 0].opsiz = 16
	regop[$RO_FILD16, 2].action = SUBADDRESS(NoReg)
	regop[$RO_FILD16, 2].param = $FIST
	regop[$RO_FILD16, 2].opsiz = 16
	regop[$RO_FILD16, 3].action = SUBADDRESS(NoReg)
	regop[$RO_FILD16, 3].param = $FISTP
	regop[$RO_FILD16, 3].opsiz = 16
	regop[$RO_FILD16, 4].action = SUBADDRESS(NoReg)
	regop[$RO_FILD16, 4].param = $FBLD	'bcd80!
	regop[$RO_FILD16, 4].opsiz = 80
	regop[$RO_FILD16, 5].action = SUBADDRESS(NoReg)
	regop[$RO_FILD16, 5].param = $FILD	'int64!
	regop[$RO_FILD16, 5].opsiz = 64
	regop[$RO_FILD16, 6].action = SUBADDRESS(NoReg)
	regop[$RO_FILD16, 6].param = $FBSTP	'bcd80!
	regop[$RO_FILD16, 6].opsiz = 80
	regop[$RO_FILD16, 7].action = SUBADDRESS(NoReg)
	regop[$RO_FILD16, 7].param = $FISTP	'int64!
	regop[$RO_FILD16, 7].opsiz = 64

	'floating-point instructions with no operands

	d86[$DD9, 0xD0].action = SUBADDRESS(Simple)
	d86[$DD9, 0xD0].param = $FNOP
	d86[$DD9, 0xE0].action = SUBADDRESS(Simple)
	d86[$DD9, 0xE0].param = $FCHS
	d86[$DD9, 0xE1].action = SUBADDRESS(Simple)
	d86[$DD9, 0xE1].param = $FABS
	d86[$DD9, 0xE4].action = SUBADDRESS(Simple)
	d86[$DD9, 0xE4].param = $FTST
	d86[$DD9, 0xE5].action = SUBADDRESS(Simple)
	d86[$DD9, 0xE5].param = $FXAM
	d86[$DD9, 0xE8].action = SUBADDRESS(Simple)
	d86[$DD9, 0xE8].param = $FLD1
	d86[$DD9, 0xE9].action = SUBADDRESS(Simple)
	d86[$DD9, 0xE9].param = $FLDL2T
	d86[$DD9, 0xEA].action = SUBADDRESS(Simple)
	d86[$DD9, 0xEA].param = $FLDL2E
	d86[$DD9, 0xEB].action = SUBADDRESS(Simple)
	d86[$DD9, 0xEB].param = $FLDPI
	d86[$DD9, 0xEC].action = SUBADDRESS(Simple)
	d86[$DD9, 0xEC].param = $FLDLG2
	d86[$DD9, 0xED].action = SUBADDRESS(Simple)
	d86[$DD9, 0xED].param = $FLDLN2
	d86[$DD9, 0xEE].action = SUBADDRESS(Simple)
	d86[$DD9, 0xEE].param = $FLDZ
	d86[$DD9, 0xF0].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF0].param = $F2XM1
	d86[$DD9, 0xF1].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF1].param = $FYL2X
	d86[$DD9, 0xF2].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF2].param = $FPTAN
	d86[$DD9, 0xF3].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF3].param = $FPATAN
	d86[$DD9, 0xF4].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF4].param = $FXTRACT
	d86[$DD9, 0xF5].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF5].param = $FPREM1
	d86[$DD9, 0xF6].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF6].param = $FDECSTP
	d86[$DD9, 0xF7].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF7].param = $FINCSTP
	d86[$DD9, 0xF8].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF8].param = $FPREM
	d86[$DD9, 0xF9].action = SUBADDRESS(Simple)
	d86[$DD9, 0xF9].param = $FYL2XP1
	d86[$DD9, 0xFA].action = SUBADDRESS(Simple)
	d86[$DD9, 0xFA].param = $FSQRT
	d86[$DD9, 0xFB].action = SUBADDRESS(Simple)
	d86[$DD9, 0xFB].param = $FSINCOS
	d86[$DD9, 0xFC].action = SUBADDRESS(Simple)
	d86[$DD9, 0xFC].param = $FRNDINT
	d86[$DD9, 0xFD].action = SUBADDRESS(Simple)
	d86[$DD9, 0xFD].param = $FSCALE
	d86[$DD9, 0xFE].action = SUBADDRESS(Simple)
	d86[$DD9, 0xFE].param = $FSIN
	d86[$DD9, 0xFF].action = SUBADDRESS(Simple)
	d86[$DD9, 0xFF].param = $FCOS
	d86[$DDA, 0xE9].action = SUBADDRESS(Simple)
	d86[$DDA, 0xE9].param = $FUCOMPP
	d86[$DDB, 0xE2].action = SUBADDRESS(Simple)
	d86[$DDB, 0xE2].param = $FNCLEX
	d86[$DDB, 0xE3].action = SUBADDRESS(Simple)
	d86[$DDB, 0xE3].param = $FNINIT
	d86[$DDE, 0xD9].action = SUBADDRESS(Simple)
	d86[$DDE, 0xD9].param = $FCOMPP
	d86[$DDF, 0xE0].action = SUBADDRESS(Simple)
	d86[$DDF, 0xE0].param = $FNSTSWAX

	'totally weird instructions

	d86[$START, 0x63].action = SUBADDRESS(Weird)
	d86[$START, 0x66].action = SUBADDRESS(Opsiz)
	d86[$START, 0x8C].action = SUBADDRESS(Weird)
	d86[$START, 0x8E].action = SUBADDRESS(Weird)
	d86[$START, 0xC2].action = SUBADDRESS(Weird)
	d86[$START, 0xC8].action = SUBADDRESS(Weird)
	d86[$START, 0xCA].action = SUBADDRESS(Weird)
	d86[$START, 0xCC].action = SUBADDRESS(Weird)
	d86[$START, 0xCD].action = SUBADDRESS(Weird)
	d86[$START, 0xEC].action = SUBADDRESS(Weird)
	d86[$START, 0xED].action = SUBADDRESS(Weird)
	d86[$START, 0xEE].action = SUBADDRESS(Weird)
	d86[$START, 0xEF].action = SUBADDRESS(Weird)
	d86[$START, 0xE3].action = SUBADDRESS(Jcxz)
	d86[$D0F, 0xB6].action = SUBADDRESS(Weird0F)
	d86[$D0F, 0xB7].action = SUBADDRESS(Weird0F)
	d86[$D0F, 0xBE].action = SUBADDRESS(Weird0F)
	d86[$D0F, 0xBF].action = SUBADDRESS(Weird0F)

	'groups of instructions with opcodes specified in the reg field of a MOD-REG-RM byte

	regop[$RO_ARITH, 0].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 0].param = $ADD
	regop[$RO_ARITH, 1].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 1].param = $OR
	regop[$RO_ARITH, 2].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 2].param = $ADC
	regop[$RO_ARITH, 3].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 3].param = $SBB
	regop[$RO_ARITH, 4].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 4].param = $AND
	regop[$RO_ARITH, 5].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 5].param = $SUB
	regop[$RO_ARITH, 6].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 6].param = $XOR
	regop[$RO_ARITH, 7].action = SUBADDRESS(EaImm)
	regop[$RO_ARITH, 7].param = $CMP
	regop[$RO_ARITH8, 0].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 0].param = $ADD
	regop[$RO_ARITH8, 1].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 1].param = $OR
	regop[$RO_ARITH8, 2].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 2].param = $ADC
	regop[$RO_ARITH8, 3].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 3].param = $SBB
	regop[$RO_ARITH8, 4].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 4].param = $AND
	regop[$RO_ARITH8, 5].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 5].param = $SUB
	regop[$RO_ARITH8, 6].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 6].param = $XOR
	regop[$RO_ARITH8, 7].action = SUBADDRESS(EaImm8)
	regop[$RO_ARITH8, 7].param = $CMP
	regop[$RO_TWID8, 0].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 0].param = $ROL
	regop[$RO_TWID8, 1].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 1].param = $ROR
	regop[$RO_TWID8, 2].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 2].param = $RCL
	regop[$RO_TWID8, 3].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 3].param = $RCR
	regop[$RO_TWID8, 4].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 4].param = $SLL
	regop[$RO_TWID8, 5].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 5].param = $SLR
	regop[$RO_TWID8, 6].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 6].param = $UNK
	regop[$RO_TWID8, 7].action = SUBADDRESS(EaImm8)
	regop[$RO_TWID8, 7].param = $SAR
	regop[$RO_TWID1, 0].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 0].param = $ROL
	regop[$RO_TWID1, 1].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 1].param = $ROR
	regop[$RO_TWID1, 2].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 2].param = $RCL
	regop[$RO_TWID1, 3].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 3].param = $RCR
	regop[$RO_TWID1, 4].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 4].param = $SLL
	regop[$RO_TWID1, 5].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 5].param = $SLR
	regop[$RO_TWID1, 6].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 6].param = $UNK
	regop[$RO_TWID1, 7].action = SUBADDRESS(EaTwid1)
	regop[$RO_TWID1, 7].param = $SAR
	regop[$RO_TWIDCL, 0].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 0].param = $ROL
	regop[$RO_TWIDCL, 1].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 1].param = $ROR
	regop[$RO_TWIDCL, 2].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 2].param = $RCL
	regop[$RO_TWIDCL, 3].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 3].param = $RCR
	regop[$RO_TWIDCL, 4].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 4].param = $SLL
	regop[$RO_TWIDCL, 5].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 5].param = $SLR
	regop[$RO_TWIDCL, 6].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 6].param = $UNK
	regop[$RO_TWIDCL, 7].action = SUBADDRESS(EaTwidCL)
	regop[$RO_TWIDCL, 7].param = $SAR
	regop[$RO_BT, 4].action = SUBADDRESS(EaImm8)
	regop[$RO_BT, 4].param = $BT
	regop[$RO_BT, 5].action = SUBADDRESS(EaImm8)
	regop[$RO_BT, 5].param = $BTS
	regop[$RO_BT, 6].action = SUBADDRESS(EaImm8)
	regop[$RO_BT, 6].param = $BTR
	regop[$RO_BT, 7].action = SUBADDRESS(EaImm8)
	regop[$RO_BT, 7].param = $BTC
	regop[$RO_SLDT, 0].action = SUBADDRESS(NoReg)
	regop[$RO_SLDT, 0].param = $SLDT
	regop[$RO_SLDT, 1].action = SUBADDRESS(NoReg)
	regop[$RO_SLDT, 1].param = $STR
	regop[$RO_SLDT, 2].action = SUBADDRESS(NoReg)
	regop[$RO_SLDT, 2].param = $LLDT
	regop[$RO_SLDT, 3].action = SUBADDRESS(NoReg)
	regop[$RO_SLDT, 3].param = $LTR
	regop[$RO_SLDT, 4].action = SUBADDRESS(NoReg)
	regop[$RO_SLDT, 4].param = $VERR
	regop[$RO_SLDT, 5].action = SUBADDRESS(NoReg)
	regop[$RO_SLDT, 5].param = $VERW
	regop[$RO_SGDT, 0].action = SUBADDRESS(NoReg)
	regop[$RO_SGDT, 0].param = $SGDT
	regop[$RO_SGDT, 1].action = SUBADDRESS(NoReg)
	regop[$RO_SGDT, 1].param = $SIDT
	regop[$RO_SGDT, 2].action = SUBADDRESS(NoReg)
	regop[$RO_SGDT, 2].param = $LGDT
	regop[$RO_SGDT, 3].action = SUBADDRESS(NoReg)
	regop[$RO_SGDT, 3].param = $LIDT
	regop[$RO_SGDT, 4].action = SUBADDRESS(NoReg)
	regop[$RO_SGDT, 4].param = $SMSW
	regop[$RO_SGDT, 6].action = SUBADDRESS(NoReg)
	regop[$RO_SGDT, 6].param = $LMSW
	regop[$RO_MUL, 0].action = SUBADDRESS(EaImm)
	regop[$RO_MUL, 0].param = $TEST
	regop[$RO_MUL, 2].action = SUBADDRESS(NoReg)
	regop[$RO_MUL, 2].param = $NOT
	regop[$RO_MUL, 3].action = SUBADDRESS(NoReg)
	regop[$RO_MUL, 3].param = $NEG
	regop[$RO_MUL, 4].action = SUBADDRESS(AccumEa)
	regop[$RO_MUL, 4].param = $MUL
	regop[$RO_MUL, 5].action = SUBADDRESS(AccumEa)
	regop[$RO_MUL, 5].param = $IMUL
	regop[$RO_MUL, 6].action = SUBADDRESS(AccumEa)
	regop[$RO_MUL, 6].param = $DIV
	regop[$RO_MUL, 7].action = SUBADDRESS(AccumEa)
	regop[$RO_MUL, 7].param = $IDIV
	regop[$RO_INCDEC1, 0].action = SUBADDRESS(NoReg)
	regop[$RO_INCDEC1, 0].param = $INC
	regop[$RO_INCDEC1, 1].action = SUBADDRESS(NoReg)
	regop[$RO_INCDEC1, 1].param = $DEC
	regop[$RO_INCDEC2, 0].action = SUBADDRESS(NoReg)
	regop[$RO_INCDEC2, 0].param = $INC
	regop[$RO_INCDEC2, 1].action = SUBADDRESS(NoReg)
	regop[$RO_INCDEC2, 1].param = $DEC
	regop[$RO_INCDEC2, 2].action = SUBADDRESS(NoRegIndr)
	regop[$RO_INCDEC2, 2].param = $CALL
	regop[$RO_INCDEC2, 3].action = SUBADDRESS(NoReg)
	regop[$RO_INCDEC2, 3].param = $CALLF
	regop[$RO_INCDEC2, 4].action = SUBADDRESS(NoRegIndr)
	regop[$RO_INCDEC2, 4].param = $JMP
	regop[$RO_INCDEC2, 5].action = SUBADDRESS(NoReg)
	regop[$RO_INCDEC2, 5].param = $JMPF
	regop[$RO_INCDEC2, 6].action = SUBADDRESS(NoReg)
	regop[$RO_INCDEC2, 6].param = $PUSH
	regop[$RO_INCDEC2, 6].opsiz = 64

	'opcode mnemonics

	opcode$[$AAA] = "aaa":			opcode$[$AAD] = "aad"
	opcode$[$AAM] = "aam":			opcode$[$AAS] = "aas"
	opcode$[$ADC] = "adc":			opcode$[$ADD] = "add"
	opcode$[$AND] = "and":			opcode$[$ARPL] = "arpl"
	opcode$[$BOUND] = "bound":	opcode$[$BSF] = "bsf"
	opcode$[$BSR] = "bsr":			opcode$[$BSWAP] = "bswap"
	opcode$[$BT] = "bt":				opcode$[$BTC] = "btc"
	opcode$[$BTR] = "btr":			opcode$[$BTS] = "bts"
	opcode$[$CALL] = "call":		opcode$[$CBW] = "cbw"
	opcode$[$CDQ] = "cqto":			opcode$[$CLC] = "clc"
	opcode$[$CLD] = "cld"				opcode$[$CALLF] = "callf"
	opcode$[$CLI] = "cli":			opcode$[$CLTS] = "clts"
	opcode$[$CMC] = "cmc":			opcode$[$CMP] = "cmp"
	opcode$[$CMPSB] = "cmpsb":	opcode$[$CMPXCHG] = "cmpxchg"
	opcode$[$CWD] = "cwd":			opcode$[$CWDE] = "cwde"
	opcode$[$DAA] = "daa":			opcode$[$DAS] = "das"
	opcode$[$DEC] = "dec":			opcode$[$DIV] = "div"
	opcode$[$ENTER] = "enter":	opcode$[$HLT] = "hlt"
	opcode$[$IDIV] = "idiv":		opcode$[$IMUL] = "imul"
	opcode$[$IN] = "in":				opcode$[$INSB] = "insb"
	opcode$[$INT] = "int":			opcode$[$INTO] = "into"
	opcode$[$INVD] = "invd":		opcode$[$INVLPG] = "invlpg"
	opcode$[$IRET] = "iret":		opcode$[$JO] = "jo"
	opcode$[$JNO] = "jno":			opcode$[$JB] = "jb"
	opcode$[$JAE] = "jae":			opcode$[$JZ] = "jz"
	opcode$[$JNZ] = "jnz":			opcode$[$JA] = "ja"
	opcode$[$JBE] = "jbe":			opcode$[$JS] = "js"
	opcode$[$JNS] = "jns":			opcode$[$JP] = "jp"
	opcode$[$JNP] = "jnp"				opcode$[$JMPF] = "jmpf"
	opcode$[$JL] = "jl":				opcode$[$JGE] = "jge"
	opcode$[$JLE] = "jle":			opcode$[$JG] = "jg"
	opcode$[$JMP] = "jmp":			opcode$[$LAHF] = "lahf"
	opcode$[$LAR] = "lar":			opcode$[$LEA] = "lea"
	opcode$[$LEAVE] = "leave":	opcode$[$LGDT] = "lgdt"
	opcode$[$LIDT] = "lidt":		opcode$[$LGS] = "lgs"
	opcode$[$LSS] = "lss"
	opcode$[$LFS] = "lfs":			opcode$[$LDS] = "lds"
	opcode$[$LES] = "les":			opcode$[$LLDT] = "lldt"
	opcode$[$LMSW] = "lmsw":		opcode$[$LOCK] = "lock"
	opcode$[$LODSB] = "lodsb":	opcode$[$LOOP] = "loop"
	opcode$[$LOOPZ] = "loopz":	opcode$[$LOOPNZ] = "loopnz"
	opcode$[$LSL] = "lsl":			opcode$[$LTR] = "ltr"
	opcode$[$MOV] = "mov":			opcode$[$MOVSB] = "movsb"
	opcode$[$MOVSX] = "movsx":	opcode$[$MOVZX] = "movzx"
	opcode$[$MUL] = "mul":			opcode$[$NEG] = "neg"
	opcode$[$NOP] = "nop":			opcode$[$NOT] = "not"
	opcode$[$OR] = "or":				opcode$[$OUT] = "out"
	opcode$[$OUTSB] = "outs":		opcode$[$POP] = "pop"
	opcode$[$POPA] = "popa":		opcode$[$POPAD] = "popad"
	opcode$[$POPF] = "popf":		opcode$[$POPFD] = "popfd"
	opcode$[$PUSH] = "push":		opcode$[$PUSHA] = "pusha"
	opcode$[$PUSHAD] = "pushad": opcode$[$PUSHAD] = "pushad"
	opcode$[$PUSHF] = "pushf":	opcode$[$PUSHFD] = "pushfd"
	opcode$[$RCL] = "rcl":			opcode$[$RCR] = "rcr"
	opcode$[$ROL] = "rol":			opcode$[$ROR] = "ror"
	opcode$[$REP] = "rep":			opcode$[$REPZ] = "repz"
	opcode$[$REPNZ] = "repnz":	opcode$[$RETN] = "ret"
	opcode$[$SAHF] = "sahf":		opcode$[$SLL] = "shl"        ' "sll"
	opcode$[$SAR] = "sar":			opcode$[$SLR] = "shr"        ' "slr"
	opcode$[$SBB] = "sbb":			opcode$[$SCASB] = "scasb"
	opcode$[$SETO] = "seto":		opcode$[$SETNO] = "setno"
	opcode$[$SETB] = "setb":		opcode$[$SETAE] = "setae"
	opcode$[$SETZ] = "setz":		opcode$[$SETNZ] = "setnz"
	opcode$[$SETBE] = "setbe":	opcode$[$SETA] = "seta"
	opcode$[$SETS] = "sets":		opcode$[$SETNS] = "setns"
	opcode$[$SETP] = "setp":		opcode$[$SETNP] = "setnp"
	opcode$[$SETL] = "setl":		opcode$[$SETGE] = "setge"
	opcode$[$SETLE] = "setle":	opcode$[$SETG] = "setg"
	opcode$[$RETF] = "retf":		opcode$[$SGDT] = "sgdt"
	opcode$[$SIDT] = "sidt":		opcode$[$SHLD] = "shld"
	opcode$[$SHRD] = "shrd":		opcode$[$SLDT] = "sldt"
	opcode$[$SMSW] = "smsw":		opcode$[$STC] = "stc"
	opcode$[$STD] = "std":			opcode$[$STI] = "sti"
	opcode$[$STOSB] = "stosb":	opcode$[$STR] = "str"
	opcode$[$SUB] = "sub":			opcode$[$TEST] = "test"
	opcode$[$VERR] = "verr":		opcode$[$VERW] = "verw"
	opcode$[$FWAIT] = "fwait":	opcode$[$WBINVD] = "wbinvd"
	opcode$[$XADD] = "xadd":		opcode$[$XCHG] = "xchgq"
	opcode$[$XLATB] = "xlatb":	opcode$[$XOR] = "xor"
	opcode$[$INC] = "inc":			opcode$[$INSD] = "insd"
	opcode$[$INSW] = "insw":		opcode$[$MOVSD] = "movsd"
	opcode$[$MOVSW] = "movsw":	opcode$[$STOSD] = "stos"
	opcode$[$STOSW] = "stos":	opcode$[$LODSD] = "lodsd"
	opcode$[$LODSW] = "lodsw":	opcode$[$SCASD] = "scasd"
	opcode$[$SCASW] = "scasw":	opcode$[$OUTSD] = "outsd"
	opcode$[$OUTSW] = "outsw":	opcode$[$CMPSD] = "cmpsd"
	opcode$[$CMPSW] = "cmpsw":	opcode$[$CSCOLON] = "cs:"
	opcode$[$DSCOLON] = "ds:":	opcode$[$ESCOLON] = "es:"
	opcode$[$SSCOLON] = "ss:":	opcode$[$FSCOLON] = "ss:"
	opcode$[$GSCOLON] = "gs:":	opcode$[$ADRSIZ] = "adrsiz:"
	opcode$[$JCXZ] = "jcxz":		opcode$[$JECXZ] = "jecxz"
	opcode$[$UNK] = "???"
	opcode$[$F2XM1] = "f2xm1":	opcode$[$FABS] = "fabs"
	opcode$[$FADD] = "fadd":		opcode$[$FADDP] = "faddp"
	opcode$[$FBLD] = "fbld":		opcode$[$FBSTP] = "fbstp"
	opcode$[$FCHS] = "fchs":		opcode$[$FNCLEX] = "fnclex"
	opcode$[$FCOM] = "fcom":		opcode$[$FCOMP] = "fcomp"
	opcode$[$FCOMPP] = "fcompp": opcode$[$FCOS] = "fcos"
	opcode$[$FDECSTP] = "fdecstp": opcode$[$FDIV] = "fdiv"
	opcode$[$FDIVP] = "fdivp":	opcode$[$FDIVR] = "fdivr"
	opcode$[$FDIVRP] = "fdivrp": opcode$[$FFREE] = "ffree"
	opcode$[$FIADD] = "fiadd":	opcode$[$FICOM] = "ficom"
	opcode$[$FICOMP] = "ficomp": opcode$[$FIDIV] = "fidiv"
	opcode$[$FIDIVR] = "fidivr": opcode$[$FILD] = "fild"
	opcode$[$FIMUL] = "fimul":	opcode$[$FINCSTP] = "fincstp"
	opcode$[$FNINIT] = "fninit": opcode$[$FIST] = "fist"
	opcode$[$FISTP] = "fistp":	opcode$[$FISUB] = "fisub"
	opcode$[$FISUBR] = "fisubr": opcode$[$FLD] = "fld"
	opcode$[$FLDCW] = "fldcw":	opcode$[$FLDENV] = "fldenv"
	opcode$[$FLDLG2] = "fldlg2": opcode$[$FLDLN2] = "fldln2"
	opcode$[$FLDL2E] = "fldl2e": opcode$[$FLDL2T] = "fldl2t"
	opcode$[$FLDPI] = "fldpi":	opcode$[$FLDZ] = "fldz"
	opcode$[$FLD1] = "fld1":		opcode$[$FMUL] = "fmul"
	opcode$[$FMULP] = "fmulp":	opcode$[$FNOP] = "fnop"
	opcode$[$FPATAN] = "fpatan": opcode$[$FPATAN] = "fpatan"
	opcode$[$FPREM] = "fprem":	opcode$[$FPREM1] = "fprem1"
	opcode$[$FPTAN] = "fptan":	opcode$[$FRNDINT] = "frndint"
	opcode$[$FRSTOR] = "frstor": opcode$[$FNSAVE] = "fnsave"
	opcode$[$FSCALE] = "fscale": opcode$[$FSETPM] = "fsetpm"
	opcode$[$FSIN] = "fsin":		opcode$[$FSINCOS] = "fsincos"
	opcode$[$FSQRT] = "fsqrt":	opcode$[$FST] = "fst"
	opcode$[$FNSTCW] = "fnstcw": opcode$[$FNSTENV] = "fnstenv"
	opcode$[$FSTP] = "fstp":		opcode$[$FNSTSW] = "fnstsw"
	opcode$[$FNSTSWAX] = "fnstsw	ax"
	opcode$[$FSUB] = "fsub":		opcode$[$FSUBP] = "fsubp"
	opcode$[$FSUBR] = "fsubr":		opcode$[$FSUBRP] = "fsubrp"
	opcode$[$FTST] = "ftst":		opcode$[$FUCOM] = "fucom"
	opcode$[$FUCOMP] = "fucomp": opcode$[$FUCOMPP] = "fucompp"
	opcode$[$FXAM] = "fxam":		opcode$[$FXCH] = "fxch"
	opcode$[$FXTRACT] = "fxtract": opcode$[$FYL2X] = "fyl2x"
	opcode$[$FYL2XP1] = "fyl2xp1": opcode$[$F2XM1] = "f2xm1"
	opcode$[$MOVABS] = "movabs"

	'strings for special (ugly) instructions

	special$[$PUSHCS] = "push	cs":			special$[$PUSHDS] = "push	ds"
	special$[$PUSHES] = "push	es":			special$[$PUSHSS] = "push	ss"
	special$[$PUSHFS] = "push	fs":			special$[$PUSHGS] = "push gs"
																			special$[$POPDS] = "pop	ds"
	special$[$POPES] = "pop	es":				special$[$POPSS] = "pop	ss"
	special$[$POPFS] = "pop	fs":				special$[$POPGS] = "pop gs"
END SUB
END FUNCTION
'
'
' ###############################
' #####  GetAddrLabel64 ()  #####
' ###############################
'
'	Return label for this address, prefer function name if function address
'
'	In:				branchAddr
'	Out:			none				arg unchanged
'	Return:		label$
'
FUNCTION  GetAddrLabel64$ (branchAddr)
	EXTERNAL /xxx/  maxFuncNumber
'	TOKEN    funcToken[]                             '*cw* 191023- ?????
'
	label = XxxGetLabelGivenAddress (branchAddr, @labels$[])
	IFZ label THEN RETURN (HEXX$(branchAddr,8))
'
'	FOR i = 0 TO UBOUND(labels$[])  '*cw* 230308+-
'		PRINT i, labels$[i]           '*cw* 230308+-
'	NEXT i                          '*cw* 230308+-

	label$ = labels$[0]											' default is first label
	XxxPassFunctionArrays ($$XGET, @funcSymbol$[], @funcToken[], @funcScope[])
	funcNumber = 1													' skip PROLOG
	DO UNTIL (funcNumber > maxFuncNumber)
		IFZ funcSymbol$[funcNumber] THEN INC funcNumber:  DO DO
'		IF ##XBOS=$$XBSysLinux
			funcName$ = funcSymbol$[funcNumber]
'		ELSE
'			funcName$ = "_" + funcSymbol$[funcNumber]
'		END IF
		j = 0
		DO WHILE (j < label)
			IF (funcName$ = labels$[j]) THEN
				label$ = funcName$
				EXIT DO 2
			END IF
			INC j
		LOOP
		INC funcNumber
	LOOP
	XxxPassFunctionArrays ($$XSET, @funcSymbol$[], @funcToken[], @funcScope[])
	RETURN (label$)
END FUNCTION
END PROGRAM
